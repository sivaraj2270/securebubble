import time
import logging
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
from fastapi import APIRouter, HTTPException, Depends, Query, status
from pydantic import BaseModel

from backend.routes.auth import verify_admin_role
from backend.services.technitium_dns_service import TechnitiumDnsService
from backend.services.risk_engine import RiskEngine

logger = logging.getLogger("securebubble.routes.admin_dns")

router = APIRouter(prefix="/api/v1/admin/dns", tags=["Admin Technitium DNS Management"])

technitium_service = TechnitiumDnsService()
risk_engine = RiskEngine()

# In-Memory Audit Event Log for Technitium Actions
_dns_audit_logs: List[Dict[str, Any]] = []


class AdminBlockDomainRequest(BaseModel):
    domain: str
    reason: Optional[str] = "Blocked by SecureBubble Administrator"


class AdminAllowDomainRequest(BaseModel):
    domain: str


class AdminDnsToggleRequest(BaseModel):
    enabled: bool


def log_dns_audit_event(action: str, target: str, admin_email: str, details: str = ""):
    event = {
        "event_id": f"dns-audit-{int(time.time() * 1000)}",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "admin_id": admin_email,
        "action": action,
        "target": target,
        "details": details
    }
    _dns_audit_logs.append(event)
    logger.info(f"DNS AUDIT EVENT [{action}]: Target={target}, Admin={admin_email}")


@router.get("/toggle")
async def get_admin_dns_toggle_state(claims: Dict[str, Any] = Depends(verify_admin_role)):
    """
    Returns current Admin DNS Protection Server ON / OFF toggle state.
    """
    return {
        "status": "success",
        "dns_enabled": technitium_service.is_enabled
    }


@router.post("/toggle")
async def toggle_admin_dns_server(
    req: AdminDnsToggleRequest,
    claims: Dict[str, Any] = Depends(verify_admin_role)
):
    """
    Toggles Technitium DNS Server Protection ON or OFF (Admin Only).
    """
    admin_email = claims.get("sub", "admin")
    new_state = technitium_service.set_enabled(req.enabled)

    log_dns_audit_event(
        action="TECHNITIUM_DNS_TOGGLED",
        target="DNS_SERVER",
        admin_email=admin_email,
        details=f"DNS Server toggled to {'ON' if new_state else 'OFF'}"
    )

    return {
        "status": "success",
        "dns_enabled": new_state,
        "message": f"DNS Server Protection has been turned {'ON' if new_state else 'OFF'}."
    }


@router.get("/status")

async def get_admin_dns_status(claims: Dict[str, Any] = Depends(verify_admin_role)):
    """
    Detailed Technitium DNS Server status & performance metrics for Admin Dashboard.
    Guarded server-side by verify_admin_role.
    """
    server_info = await technitium_service.get_server_status()
    return {
        "admin_user": claims.get("sub"),
        "technitium_status": server_info
    }


@router.get("/blocked")
async def get_admin_blocked_domains(claims: Dict[str, Any] = Depends(verify_admin_role)):
    """
    Lists all blocked domains in Technitium DNS.
    """
    blocked_list = await technitium_service.get_blocked_domains()
    return {
        "count": len(blocked_list),
        "blocked_domains": blocked_list
    }


@router.post("/block")
async def block_domain_admin(
    req: AdminBlockDomainRequest,
    claims: Dict[str, Any] = Depends(verify_admin_role)
):
    """
    Adds a domain to Technitium DNS blocklist (Admin Only).
    """
    clean_domain = risk_engine.extract_domain(req.domain)
    if not clean_domain:
        raise HTTPException(status_code=400, detail="Invalid domain format.")

    admin_email = claims.get("sub", "admin")
    result = await technitium_service.block_domain(clean_domain, reason=req.reason)

    if result.get("status") == "success":
        log_dns_audit_event(
            action="TECHNITIUM_DOMAIN_BLOCKED",
            target=clean_domain,
            admin_email=admin_email,
            details=req.reason
        )

    return result


@router.delete("/unblock/{domain}")
async def unblock_domain_admin(
    domain: str,
    claims: Dict[str, Any] = Depends(verify_admin_role)
):
    """
    Removes a domain from Technitium DNS blocklist (Admin Only).
    """
    clean_domain = risk_engine.extract_domain(domain)
    if not clean_domain:
        raise HTTPException(status_code=400, detail="Invalid domain format.")

    admin_email = claims.get("sub", "admin")
    result = await technitium_service.unblock_domain(clean_domain)

    if result.get("status") == "success":
        log_dns_audit_event(
            action="TECHNITIUM_DOMAIN_UNBLOCKED",
            target=clean_domain,
            admin_email=admin_email
        )

    return result


@router.get("/allowed")
async def get_admin_allowed_domains(claims: Dict[str, Any] = Depends(verify_admin_role)):
    """
    Lists all allowed domains in Technitium DNS.
    """
    allowed_list = await technitium_service.get_allowed_domains()
    return {
        "count": len(allowed_list),
        "allowed_domains": allowed_list
    }


@router.post("/allow")
async def allow_domain_admin(
    req: AdminAllowDomainRequest,
    claims: Dict[str, Any] = Depends(verify_admin_role)
):
    """
    Adds a domain to Technitium DNS allowlist (Admin Only).
    """
    clean_domain = risk_engine.extract_domain(req.domain)
    if not clean_domain:
        raise HTTPException(status_code=400, detail="Invalid domain format.")

    admin_email = claims.get("sub", "admin")
    result = await technitium_service.allow_domain(clean_domain)

    if result.get("status") == "success":
        log_dns_audit_event(
            action="TECHNITIUM_DOMAIN_ALLOWED",
            target=clean_domain,
            admin_email=admin_email
        )

    return result


@router.delete("/allow/{domain}")
async def remove_allowed_domain_admin(
    domain: str,
    claims: Dict[str, Any] = Depends(verify_admin_role)
):
    """
    Removes a domain from Technitium DNS allowlist (Admin Only).
    """
    clean_domain = risk_engine.extract_domain(domain)
    if not clean_domain:
        raise HTTPException(status_code=400, detail="Invalid domain format.")

    admin_email = claims.get("sub", "admin")
    result = await technitium_service.remove_allowed_domain(clean_domain)

    if result.get("status") == "success":
        log_dns_audit_event(
            action="TECHNITIUM_ALLOW_REMOVED",
            target=clean_domain,
            admin_email=admin_email
        )

    return result


@router.get("/logs")
async def get_admin_dns_logs(
    limit: int = Query(50, le=200),
    claims: Dict[str, Any] = Depends(verify_admin_role)
):
    """
    Retrieves Technitium DNS query logs for Admin audit inspection.
    """
    logs = await technitium_service.get_query_logs(limit=limit)
    return {
        "total_returned": len(logs),
        "logs": logs
    }


@router.get("/audit-trail")
async def get_admin_dns_audit_trail(claims: Dict[str, Any] = Depends(verify_admin_role)):
    """
    Retrieves audit logs of administrator actions on Technitium DNS.
    """
    return {
        "total_audit_events": len(_dns_audit_logs),
        "audit_logs": list(reversed(_dns_audit_logs))
    }
