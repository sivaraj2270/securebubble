import logging
from typing import Dict, Any, Optional, List
from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel

from backend.services.technitium_dns_service import (
    TechnitiumDnsService,
    validate_and_normalize_domain,
    is_subdomain_match
)

logger = logging.getLogger("securebubble.routes.dns")

router = APIRouter(prefix="/api/v1/dns", tags=["SecureBubble App DNS Protection"])

technitium_service = TechnitiumDnsService()


class DomainRequest(BaseModel):
    domain: str
    reason: Optional[str] = "Blocked by SecureBubble AI User"


class DomainAllowRequest(BaseModel):
    domain: str


class DnsToggleRequest(BaseModel):
    enabled: bool


@router.get("/toggle")
async def get_public_dns_toggle_state():
    return {
        "dns_enabled": technitium_service.is_enabled
    }


@router.post("/toggle")
async def toggle_public_dns_server(req: DnsToggleRequest):
    new_state = technitium_service.set_enabled(req.enabled)
    return {
        "success": True,
        "dns_enabled": new_state,
        "message": f"DNS Server Protection has been turned {'ON' if new_state else 'OFF'}."
    }


@router.get("/status")

async def get_dns_status():
    """
    Public Health & Status Check for Technitium DNS Integration.
    Returns status without leaking internal passwords or API tokens.
    """
    server_info = await technitium_service.get_server_status()
    raw_status = server_info.get("status", "OFFLINE")

    if raw_status in ["ONLINE", "active"]:
        return {
            "status": "active",
            "server": "Technitium",
            "version": server_info.get("version", "15.5"),
            "uptime": server_info.get("uptime", "N/A"),
            "total_queries": server_info.get("total_queries", 0),
            "total_blocked": server_info.get("total_blocked", 0),
            "total_allowed": server_info.get("total_allowed", 0),
            "latency_ms": server_info.get("latency_ms", 0.0)
        }
    else:
        return {
            "status": "unavailable",
            "server": "Technitium",
            "error": server_info.get("error", "DNS server unreachable")
        }


@router.get("/check")
async def check_domain_status(domain: str = Query(..., description="Target domain to check")):
    """
    Checks whether a domain is ALLOWED, BLOCKED, or UNKNOWN in Technitium DNS.
    Validates and normalizes domain input first.
    """
    is_valid, clean_domain, err_msg = validate_and_normalize_domain(domain)
    if not is_valid:
        raise HTTPException(status_code=400, detail=err_msg or "Invalid domain format.")

    resolve_result = await technitium_service.resolve_dns(clean_domain)
    
    if resolve_result.get("status") == "success":
        is_blocked = resolve_result.get("is_blocked", False)
        return {
            "success": True,
            "domain": clean_domain,
            "status": "BLOCKED" if is_blocked else "ALLOWED",
            "is_blocked": is_blocked,
            "message": f"Domain {clean_domain} is {'BLOCKED' if is_blocked else 'ALLOWED'} by Technitium DNS."
        }
    else:
        return {
            "success": False,
            "domain": clean_domain,
            "status": "UNKNOWN",
            "is_blocked": False,
            "error": {
                "code": "TECHNITIUM_UNAVAILABLE",
                "message": resolve_result.get("message", "Unable to query Technitium DNS status.")
            }
        }


@router.post("/block")
async def block_domain_endpoint(req: DomainRequest):
    """
    Adds a domain to Technitium DNS blocklist.
    """
    is_valid, clean_domain, err_msg = validate_and_normalize_domain(req.domain)
    if not is_valid:
        raise HTTPException(status_code=400, detail=err_msg or "Invalid domain format.")

    result = await technitium_service.block_domain(clean_domain, reason=req.reason or "Blocked by SecureBubble AI")
    if result.get("status") == "success":
        return {
            "success": True,
            "data": result
        }
    else:
        return {
            "success": False,
            "error": {
                "code": "BLOCK_FAILED",
                "message": result.get("message", "Failed to block domain.")
            }
        }


@router.delete("/block/{domain:path}")
async def unblock_domain_endpoint(domain: str):
    """
    Removes a domain from Technitium DNS blocklist.
    """
    is_valid, clean_domain, err_msg = validate_and_normalize_domain(domain)
    if not is_valid:
        raise HTTPException(status_code=400, detail=err_msg or "Invalid domain format.")

    result = await technitium_service.unblock_domain(clean_domain)
    if result.get("status") == "success":
        return {
            "success": True,
            "data": result
        }
    else:
        return {
            "success": False,
            "error": {
                "code": "UNBLOCK_FAILED",
                "message": result.get("message", "Failed to unblock domain.")
            }
        }


@router.post("/allow")
async def allow_domain_endpoint(req: DomainAllowRequest):
    """
    Adds a domain to Technitium DNS allowlist.
    """
    is_valid, clean_domain, err_msg = validate_and_normalize_domain(req.domain)
    if not is_valid:
        raise HTTPException(status_code=400, detail=err_msg or "Invalid domain format.")

    result = await technitium_service.allow_domain(clean_domain)
    if result.get("status") == "success":
        return {
            "success": True,
            "data": result
        }
    else:
        return {
            "success": False,
            "error": {
                "code": "ALLOW_FAILED",
                "message": result.get("message", "Failed to allow domain.")
            }
        }


@router.delete("/allow/{domain:path}")
async def remove_allowed_domain_endpoint(domain: str):
    """
    Removes a domain from Technitium DNS allowlist.
    """
    is_valid, clean_domain, err_msg = validate_and_normalize_domain(domain)
    if not is_valid:
        raise HTTPException(status_code=400, detail=err_msg or "Invalid domain format.")

    result = await technitium_service.remove_allowed_domain(clean_domain)
    if result.get("status") == "success":
        return {
            "success": True,
            "data": result
        }
    else:
        return {
            "success": False,
            "error": {
                "code": "REMOVE_ALLOW_FAILED",
                "message": result.get("message", "Failed to remove domain from allowlist.")
            }
        }


@router.get("/blocked")
async def get_blocked_domains():
    """
    Returns actual list of blocked domains from Technitium DNS.
    """
    blocked_list = await technitium_service.get_blocked_domains()
    return {
        "success": True,
        "count": len(blocked_list),
        "blocked_domains": blocked_list
    }


@router.get("/allowed")
async def get_allowed_domains():
    """
    Returns actual list of allowed domains from Technitium DNS.
    """
    allowed_list = await technitium_service.get_allowed_domains()
    return {
        "success": True,
        "count": len(allowed_list),
        "allowed_domains": allowed_list
    }


@router.get("/statistics")
async def get_dns_statistics():
    """
    Returns actual Technitium DNS query statistics.
    """
    server_info = await technitium_service.get_server_status()
    raw_status = server_info.get("status", "OFFLINE")

    if raw_status in ["ONLINE", "active"]:
        return {
            "success": True,
            "data": {
                "totalQueries": server_info.get("total_queries", 0),
                "blockedQueries": server_info.get("total_blocked", 0),
                "allowedQueries": server_info.get("total_allowed", 0),
                "server": "Technitium DNS Server 15.5",
                "uptime": server_info.get("uptime", "N/A"),
                "latency_ms": server_info.get("latency_ms", 0.0)
            }
        }
    else:
        return {
            "success": False,
            "error": {
                "code": "TECHNITIUM_UNAVAILABLE",
                "message": "Technitium DNS server is unavailable."
            }
        }


@router.get("/logs")
async def get_dns_logs(limit: int = Query(50, le=200)):
    """
    Returns actual DNS query activity logs from Technitium.
    """
    logs = await technitium_service.get_query_logs(limit=limit)
    return {
        "success": True,
        "total_returned": len(logs),
        "logs": logs
    }


@router.get("/resolve")
async def resolve_domain_dns(
    domain: str = Query(..., description="Domain name to resolve"),
    record_type: str = Query("A", description="DNS Record Type (A, AAAA, MX, TXT)")
):
    """
    Tests local DNS resolution via Technitium DNS Server.
    """
    is_valid, clean_domain, err_msg = validate_and_normalize_domain(domain)
    if not is_valid:
        raise HTTPException(status_code=400, detail=err_msg or "Invalid domain format.")

    return await technitium_service.resolve_dns(clean_domain, record_type=record_type)
