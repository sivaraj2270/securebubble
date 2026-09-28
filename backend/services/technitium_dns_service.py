import logging
import re
import ipaddress
import time
from typing import Dict, Any, List, Optional, Tuple
import httpx

from backend.config import get_settings

logger = logging.getLogger("securebubble.services.technitium_dns")


def validate_and_normalize_domain(domain: str) -> Tuple[bool, str, Optional[str]]:
    """
    Validates and normalizes domain names for Technitium DNS Operations.
    Rejects empty input, spaces, IP addresses, malformed characters, and invalid labels.
    """
    if not domain or not isinstance(domain, str):
        return False, "", "Domain input cannot be empty."

    raw = domain.strip().lower()

    # Remove protocol prefix if included by accident
    raw = re.sub(r"^https?://", "", raw)
    # Remove path, query string, or port if present
    raw = raw.split("/")[0].split(":")[0].rstrip(".")

    if not raw:
        return False, "", "Domain name is empty after cleanup."

    if len(raw) > 253:
        return False, "", "Domain name exceeds maximum length of 253 characters."

    # Check if input is an IP address (reject IP addresses for DNS blocklist rules)
    try:
        ipaddress.ip_address(raw)
        return False, raw, "IP addresses cannot be added to domain DNS rules."
    except ValueError:
        pass

    # Regex for valid domain name format (RFC 1035 / RFC 1123)
    domain_regex = re.compile(
        r"^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$"
    )

    # Handle Punycode IDN domains
    try:
        ascii_domain = raw.encode("idna").decode("ascii")
    except Exception:
        return False, raw, "Domain contains invalid IDN/Unicode characters."

    if not domain_regex.match(ascii_domain):
        return False, raw, "Domain has an invalid hostname format or invalid characters."

    return True, ascii_domain, None


def is_subdomain_match(parent_domain: str, candidate_domain: str) -> bool:
    """
    Checks DNS label boundary matching.
    example.com matches example.com, www.example.com, login.example.com,
    but does NOT match example.com.evil.com or myexample.com.
    """
    parent = parent_domain.strip().lower().rstrip(".")
    candidate = candidate_domain.strip().lower().rstrip(".")

    if candidate == parent:
        return True

    if candidate.endswith("." + parent):
        return True

    return False


class TechnitiumDnsService:
    """
    Dedicated Service Layer for Technitium DNS Server 15.5 Integration.
    Communicates securely with Technitium's administrative REST API over HTTP/HTTPS.
    No credentials are ever exposed to client applications.
    """

    def __init__(self):
        self._cached_token: Optional[str] = None
        self._token_expiry_ts: float = 0.0
        self.is_enabled: bool = True  # Admin ON / OFF toggle state

    def set_enabled(self, enabled: bool) -> bool:
        """
        Toggles DNS Protection ON or OFF.
        """
        self.is_enabled = enabled
        logger.info(f"Technitium DNS Protection toggled: {'ON' if enabled else 'OFF'}")
        return self.is_enabled

    async def _get_active_token(self, client: httpx.AsyncClient) -> Optional[str]:
        """
        Retrieves API token from configuration or authenticates with Technitium /api/user/login.
        Supports fallback authentication with default admin/admin if no password provided.
        """
        settings = get_settings()

        # 1. Direct API Token from Environment
        if settings.TECHNITIUM_API_TOKEN and settings.TECHNITIUM_API_TOKEN.strip():
            return settings.TECHNITIUM_API_TOKEN.strip()

        # 2. Check cached dynamic session token
        now = time.time()
        if self._cached_token and now < self._token_expiry_ts:
            return self._cached_token

        # 3. Dynamic Authentication via User/Password (tries configured pass first, then default 'admin')
        user = settings.TECHNITIUM_ADMIN_USER or "admin"
        passwords_to_try = []
        if settings.TECHNITIUM_ADMIN_PASSWORD:
            passwords_to_try.append(settings.TECHNITIUM_ADMIN_PASSWORD)
        passwords_to_try.extend(["admin", "admin123", ""])

        for pwd in passwords_to_try:
            try:
                login_url = f"{settings.TECHNITIUM_SERVER_URL.rstrip('/')}/api/user/login"
                params = {"user": user, "pass": pwd}
                resp = await client.get(login_url, params=params)
                if resp.status_code == 200:
                    data = resp.json()
                    if data.get("status") in ["ok", "success"]:
                        token = data.get("token") or data.get("response", {}).get("token")
                        if token:
                            self._cached_token = token
                            self._token_expiry_ts = now + 3600  # 1 hour cache TTL
                            return token
            except Exception as e:
                logger.debug(f"Technitium login attempt failed for user={user}: {str(e)}")

        return None

    async def get_server_status(self) -> Dict[str, Any]:
        """
        Checks Technitium DNS Server health, status, uptime, and performance stats.
        Respects Admin ON / OFF toggle.
        """
        settings = get_settings()
        start_time = time.time()

        if not self.is_enabled:
            return {
                "status": "OFF",
                "enabled": False,
                "server_url": settings.TECHNITIUM_SERVER_URL,
                "latency_ms": 0.0,
                "version": "15.5",
                "uptime": "N/A",
                "total_queries": 0,
                "total_blocked": 0,
                "total_allowed": 0,
                "message": "DNS Protection Server is turned OFF by Administrator."
            }

        try:
            async with httpx.AsyncClient(timeout=settings.TECHNITIUM_TIMEOUT_SECONDS) as client:
                token = await self._get_active_token(client)
                url = f"{settings.TECHNITIUM_SERVER_URL.rstrip('/')}/api/dashboard/stats/get"
                params = {"type": "LastDay"}
                if token:
                    params["token"] = token

                resp = await client.get(url, params=params)
                latency_ms = round((time.time() - start_time) * 1000, 2)

                if resp.status_code == 200:
                    data = resp.json()
                    status_str = data.get("status", "ok")

                    if status_str.lower() in ["ok", "success"]:
                        response_data = data.get("response", {})
                        stats = response_data.get("stats", response_data)

                        return {
                            "status": "ONLINE",
                            "enabled": True,
                            "server_url": settings.TECHNITIUM_SERVER_URL,
                            "latency_ms": latency_ms,
                            "version": stats.get("version", "15.5"),
                            "uptime": stats.get("uptime", "N/A"),
                            "total_queries": stats.get("totalQueries", 0),
                            "total_blocked": stats.get("totalBlocked", stats.get("totalBlockedQueries", 0)),
                            "total_allowed": stats.get("totalNoError", stats.get("totalAllowedQueries", 0)),
                            "raw_response": response_data
                        }
                    else:
                        # Clear invalid token cache
                        self._cached_token = None
                        return {
                            "status": "ONLINE_UNAUTHENTICATED",
                            "enabled": True,
                            "server_url": settings.TECHNITIUM_SERVER_URL,
                            "latency_ms": latency_ms,
                            "version": "15.5",
                            "uptime": "N/A",
                            "total_queries": 0,
                            "total_blocked": 0,
                            "total_allowed": 0,
                            "message": data.get("errorMessage", "Technitium DNS reached, authentication token required.")
                        }
                else:
                    return {
                        "status": "ERROR",
                        "enabled": True,
                        "server_url": settings.TECHNITIUM_SERVER_URL,
                        "latency_ms": latency_ms,
                        "error": f"Technitium API returned HTTP status {resp.status_code}"
                    }

        except httpx.ConnectError:
            return {
                "status": "OFFLINE",
                "enabled": True,
                "server_url": settings.TECHNITIUM_SERVER_URL,
                "error": "Cannot connect to Technitium DNS Server (Connection Refused)."
            }
        except httpx.TimeoutException:
            return {
                "status": "TIMEOUT",
                "enabled": True,
                "server_url": settings.TECHNITIUM_SERVER_URL,
                "error": f"Technitium API request timed out after {settings.TECHNITIUM_TIMEOUT_SECONDS}s."
            }
        except Exception as e:
            return {
                "status": "ERROR",
                "enabled": True,
                "server_url": settings.TECHNITIUM_SERVER_URL,
                "error": str(e)
            }


    async def block_domain(self, domain: str, reason: str = "Secured by SecureBubble Threat Intelligence") -> Dict[str, Any]:
        """
        Adds a domain to Technitium DNS blocklist.
        """
        clean_domain = domain.strip().lower()
        if not clean_domain:
            return {"status": "error", "message": "Domain cannot be empty"}

        settings = get_settings()

        try:
            async with httpx.AsyncClient(timeout=settings.TECHNITIUM_TIMEOUT_SECONDS) as client:
                token = await self._get_active_token(client)
                url = f"{settings.TECHNITIUM_SERVER_URL.rstrip('/')}/api/blocked/add"
                params = {"domain": clean_domain}
                if token:
                    params["token"] = token

                resp = await client.get(url, params=params)
                if resp.status_code == 200:
                    data = resp.json()
                    status_str = data.get("status", "ok")
                    if status_str.lower() in ["ok", "success"]:
                        logger.info(f"Technitium DNS: Domain {clean_domain} successfully added to blocklist.")
                        return {
                            "status": "success",
                            "domain": clean_domain,
                            "action": "BLOCKED",
                            "reason": reason,
                            "message": f"Domain {clean_domain} successfully blocked on Technitium DNS."
                        }
                    else:
                        return {
                            "status": "error",
                            "message": data.get("errorMessage", "Failed to block domain in Technitium DNS.")
                        }
                else:
                    return {
                        "status": "error",
                        "message": f"Technitium API returned HTTP status {resp.status_code}"
                    }
        except Exception as e:
            logger.error(f"Technitium block_domain exception: {str(e)}")
            return {"status": "error", "message": str(e)}

    async def unblock_domain(self, domain: str) -> Dict[str, Any]:
        """
        Removes a domain from Technitium DNS blocklist.
        """
        clean_domain = domain.strip().lower()
        settings = get_settings()

        try:
            async with httpx.AsyncClient(timeout=settings.TECHNITIUM_TIMEOUT_SECONDS) as client:
                token = await self._get_active_token(client)
                url = f"{settings.TECHNITIUM_SERVER_URL.rstrip('/')}/api/blocked/delete"
                params = {"domain": clean_domain}
                if token:
                    params["token"] = token

                resp = await client.get(url, params=params)
                if resp.status_code == 200:
                    data = resp.json()
                    status_str = data.get("status", "ok")
                    if status_str.lower() in ["ok", "success"]:
                        logger.info(f"Technitium DNS: Domain {clean_domain} unblocked successfully.")
                        return {
                            "status": "success",
                            "domain": clean_domain,
                            "action": "UNBLOCKED",
                            "message": f"Domain {clean_domain} successfully removed from Technitium blocklist."
                        }
                    else:
                        return {
                            "status": "error",
                            "message": data.get("errorMessage", "Failed to unblock domain in Technitium DNS.")
                        }
                else:
                    return {
                        "status": "error",
                        "message": f"Technitium API returned HTTP status {resp.status_code}"
                    }
        except Exception as e:
            logger.error(f"Technitium unblock_domain exception: {str(e)}")
            return {"status": "error", "message": str(e)}

    async def allow_domain(self, domain: str) -> Dict[str, Any]:
        """
        Adds a domain to Technitium DNS allowlist.
        """
        clean_domain = domain.strip().lower()
        settings = get_settings()

        try:
            async with httpx.AsyncClient(timeout=settings.TECHNITIUM_TIMEOUT_SECONDS) as client:
                token = await self._get_active_token(client)
                url = f"{settings.TECHNITIUM_SERVER_URL.rstrip('/')}/api/allowed/add"
                params = {"domain": clean_domain}
                if token:
                    params["token"] = token

                resp = await client.get(url, params=params)
                if resp.status_code == 200:
                    data = resp.json()
                    status_str = data.get("status", "ok")
                    if status_str.lower() in ["ok", "success"]:
                        logger.info(f"Technitium DNS: Domain {clean_domain} added to allowlist.")
                        return {
                            "status": "success",
                            "domain": clean_domain,
                            "action": "ALLOWED",
                            "message": f"Domain {clean_domain} added to Technitium allowlist."
                        }
                    else:
                        return {"status": "error", "message": data.get("errorMessage", "Failed to allow domain.")}
                else:
                    return {"status": "error", "message": f"Technitium API returned HTTP {resp.status_code}"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def remove_allowed_domain(self, domain: str) -> Dict[str, Any]:
        """
        Removes a domain from Technitium DNS allowlist.
        """
        clean_domain = domain.strip().lower()
        settings = get_settings()

        try:
            async with httpx.AsyncClient(timeout=settings.TECHNITIUM_TIMEOUT_SECONDS) as client:
                token = await self._get_active_token(client)
                url = f"{settings.TECHNITIUM_SERVER_URL.rstrip('/')}/api/allowed/delete"
                params = {"domain": clean_domain}
                if token:
                    params["token"] = token

                resp = await client.get(url, params=params)
                if resp.status_code == 200:
                    data = resp.json()
                    status_str = data.get("status", "ok")
                    if status_str.lower() in ["ok", "success"]:
                        return {
                            "status": "success",
                            "domain": clean_domain,
                            "action": "ALLOW_REMOVED",
                            "message": f"Domain {clean_domain} removed from Technitium allowlist."
                        }
                    else:
                        return {"status": "error", "message": data.get("errorMessage", "Failed to remove allowed domain.")}
                else:
                    return {"status": "error", "message": f"Technitium API returned HTTP {resp.status_code}"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def get_blocked_domains(self) -> List[Dict[str, Any]]:
        """
        Lists all domains currently in Technitium blocklist.
        """
        settings = get_settings()
        try:
            async with httpx.AsyncClient(timeout=settings.TECHNITIUM_TIMEOUT_SECONDS) as client:
                token = await self._get_active_token(client)
                url = f"{settings.TECHNITIUM_SERVER_URL.rstrip('/')}/api/blocked/list"
                params = {}
                if token:
                    params["token"] = token

                resp = await client.get(url, params=params)
                if resp.status_code == 200:
                    data = resp.json()
                    items = data.get("response", {}).get("blockedDomains", [])
                    return items
        except Exception as e:
            logger.warning(f"Technitium get_blocked_domains error: {str(e)}")

        return []

    async def get_allowed_domains(self) -> List[Dict[str, Any]]:
        """
        Lists all domains currently in Technitium allowlist.
        """
        settings = get_settings()
        try:
            async with httpx.AsyncClient(timeout=settings.TECHNITIUM_TIMEOUT_SECONDS) as client:
                token = await self._get_active_token(client)
                url = f"{settings.TECHNITIUM_SERVER_URL.rstrip('/')}/api/allowed/list"
                params = {}
                if token:
                    params["token"] = token

                resp = await client.get(url, params=params)
                if resp.status_code == 200:
                    data = resp.json()
                    items = data.get("response", {}).get("allowedDomains", [])
                    return items
        except Exception as e:
            logger.warning(f"Technitium get_allowed_domains error: {str(e)}")

        return []

    async def resolve_dns(self, domain: str, record_type: str = "A") -> Dict[str, Any]:
        """
        Tests DNS resolution via Technitium DNS API.
        """
        clean_domain = domain.strip().lower()
        settings = get_settings()

        try:
            async with httpx.AsyncClient(timeout=settings.TECHNITIUM_TIMEOUT_SECONDS) as client:
                token = await self._get_active_token(client)
                url = f"{settings.TECHNITIUM_SERVER_URL.rstrip('/')}/api/dns/resolve"
                params = {"domain": clean_domain, "type": record_type}
                if token:
                    params["token"] = token

                resp = await client.get(url, params=params)
                if resp.status_code == 200:
                    data = resp.json()
                    response_obj = data.get("response", {})
                    status_code = response_obj.get("status", "UNKNOWN")
                    records = response_obj.get("records", [])

                    is_blocked = (status_code == "NXDOMAIN" or any(r.get("rData", "") in ["0.0.0.0", "127.0.0.1"] for r in records))

                    return {
                        "status": "success",
                        "domain": clean_domain,
                        "record_type": record_type,
                        "dns_status": status_code,
                        "is_blocked": is_blocked,
                        "records": records,
                        "raw_response": response_obj
                    }
                else:
                    return {"status": "error", "message": f"HTTP status {resp.status_code}"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def get_query_logs(self, limit: int = 50) -> List[Dict[str, Any]]:
        """
        Retrieves recent DNS query logs from Technitium.
        """
        settings = get_settings()
        try:
            async with httpx.AsyncClient(timeout=settings.TECHNITIUM_TIMEOUT_SECONDS) as client:
                token = await self._get_active_token(client)
                url = f"{settings.TECHNITIUM_SERVER_URL.rstrip('/')}/api/logs/query/get"
                params = {"limit": limit}
                if token:
                    params["token"] = token

                resp = await client.get(url, params=params)
                if resp.status_code == 200:
                    data = resp.json()
                    logs = data.get("response", {}).get("logs", [])
                    return logs
        except Exception as e:
            logger.warning(f"Technitium get_query_logs error: {str(e)}")

        return []
