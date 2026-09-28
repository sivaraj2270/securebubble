import logging
from typing import Dict, Any, List, Optional
import httpx
from backend.config import get_settings

logger = logging.getLogger("securebubble.google_web_risk")


class GoogleWebRiskService:
    """
    Server-side Google Web Risk Lookup API Threat Reputation Service.

    Threat Types Audited:
    - MALWARE
    - SOCIAL_ENGINEERING
    - UNWANTED_SOFTWARE

    Security & Non-negotiable Rules (AGENTS.md):
    - Credentials loaded strictly from backend settings (GOOGLE_WEB_RISK_API_KEY).
    - API errors, network timeouts, or missing API keys result in classification 'unknown' — NEVER 'safe'.
    - Provider outputs are NEVER fabricated or guessed.
    """

    def __init__(self):
        self.settings = get_settings()
        self.threat_types = ["MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE"]

    async def scan_url(self, url: str) -> Dict[str, Any]:
        """
        Queries Google Web Risk Lookup API for threat indicators associated with the given URI.

        Returns a normalized dict matching Section 6 specification:
        {
            "status": "completed" | "error" | "timeout" | "not_configured",
            "threat_types": List[str],
            "expire_time": Optional[str],
            "classification": "safe" | "suspicious" | "dangerous" | "unknown",
            "error_detail": Optional[str],
            "raw_response": dict
        }
        """
        api_key = self.settings.GOOGLE_WEB_RISK_API_KEY.strip()

        if not api_key or api_key == "YOUR_GOOGLE_WEB_RISK_API_KEY_HERE":
            logger.warning("Google Web Risk API Key is missing. Returning not_configured status.")
            return {
                "status": "not_configured",
                "threat_types": [],
                "expire_time": None,
                "classification": "unknown",
                "error_detail": "Google Web Risk API key is not configured on the server.",
                "raw_response": {}
            }

        endpoint = "https://webrisk.googleapis.com/v1/uris:search"
        params = [("key", api_key), ("uri", url.strip())]
        for tt in self.threat_types:
            params.append(("threatTypes", tt))

        timeout = self.settings.PROVIDER_TIMEOUT_SECONDS

        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.get(endpoint, params=params)

                if response.status_code == 200:
                    data = response.json()
                    threat_data = data.get("threat", {})
                    detected_types = threat_data.get("threatTypes", [])
                    expire_time = threat_data.get("expireTime")

                    if any(t in detected_types for t in ["SOCIAL_ENGINEERING", "MALWARE"]):
                        classification = "dangerous"
                    elif "UNWANTED_SOFTWARE" in detected_types:
                        classification = "suspicious"
                    elif len(detected_types) == 0:
                        classification = "safe"
                    else:
                        classification = "unknown"

                    return {
                        "status": "completed",
                        "threat_types": detected_types,
                        "expire_time": expire_time,
                        "classification": classification,
                        "error_detail": None,
                        "raw_response": data
                    }

                elif response.status_code == 400:
                    logger.error(f"Google Web Risk returned HTTP 400 Bad Request for URI: {url}")
                    return {
                        "status": "error",
                        "threat_types": [],
                        "expire_time": None,
                        "classification": "unknown",
                        "error_detail": "Invalid URL request format sent to Google Web Risk API.",
                        "raw_response": {}
                    }

                elif response.status_code == 403:
                    logger.error("Google Web Risk API authorization error (HTTP 403).")
                    return {
                        "status": "error",
                        "threat_types": [],
                        "expire_time": None,
                        "classification": "unknown",
                        "error_detail": "Google Web Risk API key invalid or API disabled in GCP console.",
                        "raw_response": {}
                    }

                else:
                    error_msg = f"Google Web Risk API returned HTTP {response.status_code}"
                    logger.error(error_msg)
                    return {
                        "status": "error",
                        "threat_types": [],
                        "expire_time": None,
                        "classification": "unknown",
                        "error_detail": error_msg,
                        "raw_response": {}
                    }

        except httpx.TimeoutException:
            logger.warning(f"Google Web Risk request timed out after {timeout} seconds for URL: {url}")
            return {
                "status": "timeout",
                "threat_types": [],
                "expire_time": None,
                "classification": "unknown",
                "error_detail": f"Request timed out after {timeout} seconds.",
                "raw_response": {}
            }
        except Exception as e:
            logger.exception(f"Unexpected error querying Google Web Risk for URL: {url}")
            return {
                "status": "error",
                "threat_types": [],
                "expire_time": None,
                "classification": "unknown",
                "error_detail": str(e),
                "raw_response": {}
            }
