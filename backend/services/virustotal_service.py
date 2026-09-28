import base64
import logging
from typing import Dict, Any, Optional
import httpx
from backend.config import get_settings

logger = logging.getLogger("securebubble.virustotal")


class VirusTotalService:
    """
    Server-side VirusTotal API v3 Threat Reputation Service.

    Security & Non-negotiable Rules (AGENTS.md):
    - Credentials loaded strictly from backend settings (VIRUSTOTAL_API_KEY).
    - API errors, network timeouts, or missing API keys result in classification 'unknown' — NEVER 'safe'.
    - Provider outputs are NEVER fabricated or guessed.
    """

    def __init__(self):
        self.settings = get_settings()

    def _encode_url_identifier(self, url: str) -> str:
        """
        Encodes a URL into VirusTotal v3 URL ID format (Base64 URL-safe, stripped of trailing '=').
        """
        raw_bytes = url.strip().encode("utf-8")
        encoded = base64.urlsafe_b64encode(raw_bytes).decode("utf-8")
        return encoded.rstrip("=")

    async def scan_url(self, url: str) -> Dict[str, Any]:
        """
        Queries VirusTotal API v3 for the reputation of a given URL.

        Returns a normalized dict matching Section 6 specification:
        {
            "status": "completed" | "error" | "timeout" | "not_configured" | "not_found",
            "malicious": int,
            "suspicious": int,
            "harmless": int,
            "undetected": int,
            "total_engines": int,
            "classification": "safe" | "suspicious" | "dangerous" | "unknown",
            "error_detail": Optional[str],
            "raw_stats": dict
        }
        """
        api_key = self.settings.VIRUSTOTAL_API_KEY.strip()

        if not api_key:
            logger.warning("VirusTotal API Key is missing. Returning not_configured status.")
            return {
                "status": "not_configured",
                "malicious": 0,
                "suspicious": 0,
                "harmless": 0,
                "undetected": 0,
                "total_engines": 0,
                "classification": "unknown",
                "error_detail": "VirusTotal API key is not configured on the server.",
                "raw_stats": {}
            }

        url_id = self._encode_url_identifier(url)
        endpoint = f"https://www.virustotal.com/api/v3/urls/{url_id}"
        headers = {"x-apikey": api_key, "Accept": "application/json"}
        timeout = self.settings.PROVIDER_TIMEOUT_SECONDS

        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.get(endpoint, headers=headers)

                if response.status_code == 200:
                    data = response.json()
                    attributes = data.get("data", {}).get("attributes", {})
                    stats = attributes.get("last_analysis_stats", {})

                    malicious = int(stats.get("malicious", 0))
                    suspicious = int(stats.get("suspicious", 0))
                    harmless = int(stats.get("harmless", 0))
                    undetected = int(stats.get("undetected", 0))
                    total = malicious + suspicious + harmless + undetected

                    if malicious > 0:
                        classification = "dangerous"
                    elif suspicious > 1:
                        classification = "suspicious"
                    elif total > 0 and (malicious == 0 and suspicious <= 1):
                        classification = "safe"
                    else:
                        classification = "unknown"

                    return {
                        "status": "completed",
                        "malicious": malicious,
                        "suspicious": suspicious,
                        "harmless": harmless,
                        "undetected": undetected,
                        "total_engines": total,
                        "classification": classification,
                        "error_detail": None,
                        "raw_stats": stats
                    }

                elif response.status_code == 404:
                    return {
                        "status": "not_found",
                        "malicious": 0,
                        "suspicious": 0,
                        "harmless": 0,
                        "undetected": 0,
                        "total_engines": 0,
                        "classification": "unknown",
                        "error_detail": "URL not found in VirusTotal database.",
                        "raw_stats": {}
                    }

                elif response.status_code == 429:
                    logger.error("VirusTotal API rate limit exceeded (429).")
                    return {
                        "status": "error",
                        "malicious": 0,
                        "suspicious": 0,
                        "harmless": 0,
                        "undetected": 0,
                        "total_engines": 0,
                        "classification": "unknown",
                        "error_detail": "VirusTotal rate limit exceeded.",
                        "raw_stats": {}
                    }

                else:
                    error_msg = f"VirusTotal returned HTTP {response.status_code}"
                    logger.error(error_msg)
                    return {
                        "status": "error",
                        "malicious": 0,
                        "suspicious": 0,
                        "harmless": 0,
                        "undetected": 0,
                        "total_engines": 0,
                        "classification": "unknown",
                        "error_detail": error_msg,
                        "raw_stats": {}
                    }

        except httpx.TimeoutException:
            logger.warning(f"VirusTotal request timed out after {timeout} seconds for URL: {url}")
            return {
                "status": "timeout",
                "malicious": 0,
                "suspicious": 0,
                "harmless": 0,
                "undetected": 0,
                "total_engines": 0,
                "classification": "unknown",
                "error_detail": f"Request timed out after {timeout} seconds.",
                "raw_stats": {}
            }
        except Exception as e:
            logger.exception(f"Unexpected error querying VirusTotal for URL: {url}")
            return {
                "status": "error",
                "malicious": 0,
                "suspicious": 0,
                "harmless": 0,
                "undetected": 0,
                "total_engines": 0,
                "classification": "unknown",
                "error_detail": str(e),
                "raw_stats": {}
            }
