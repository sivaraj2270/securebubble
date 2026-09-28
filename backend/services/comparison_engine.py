import logging
from typing import Dict, Any

logger = logging.getLogger("securebubble.comparison_engine")


class ComparisonEngine:
    """
    SecureBubble Comparison Engine.

    Evaluates threat reputation outputs from VirusTotal API v3 and Google Web Risk API.
    Determines provider agreement/conflict states without relying on naive majority voting.

    Possible Comparison States (AGENTS.md & Section 7):
    - BOTH_SAFE
    - BOTH_DANGEROUS
    - BOTH_SUSPICIOUS
    - VT_SAFE_GOOGLE_DANGEROUS
    - VT_DANGEROUS_GOOGLE_SAFE
    - VT_SUSPICIOUS_GOOGLE_SAFE
    - VT_SAFE_GOOGLE_SUSPICIOUS
    - INSUFFICIENT_DATA
    - PROVIDER_ERROR
    """

    def compare_results(
        self,
        vt_result: Dict[str, Any],
        google_result: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Compares VirusTotal and Google Web Risk results and outputs a normalized comparison summary.
        """
        vt_status = vt_result.get("status", "unknown")
        google_status = google_result.get("status", "unknown")

        vt_class = vt_result.get("classification", "unknown")
        google_class = google_result.get("classification", "unknown")

        # 1. Evaluate Provider Failure / Timeout / Unconfigured States
        vt_failed = vt_status in ["error", "timeout", "not_configured"]
        google_failed = google_status in ["error", "timeout", "not_configured"]

        if vt_failed and google_failed:
            return {
                "agreement": False,
                "status": "PROVIDER_ERROR",
                "summary": "Both VirusTotal and Google Web Risk providers are currently unavailable or unconfigured.",
                "provider_details": {
                    "virustotal_classification": vt_class,
                    "google_web_risk_classification": google_class,
                    "virustotal_status": vt_status,
                    "google_web_risk_status": google_status
                }
            }

        if vt_failed or google_failed:
            available_provider = "Google Web Risk" if vt_failed else "VirusTotal"
            available_class = google_class if vt_failed else vt_class
            return {
                "agreement": False,
                "status": "INSUFFICIENT_DATA",
                "summary": f"Partial threat data. Only {available_provider} responded ({available_class.upper()}). Second provider unavailable.",
                "provider_details": {
                    "virustotal_classification": vt_class,
                    "google_web_risk_classification": google_class,
                    "virustotal_status": vt_status,
                    "google_web_risk_status": google_status
                }
            }

        # 2. Treat 'not_found' on VirusTotal as unflagged/clean signal if total_engines == 0
        if vt_status == "not_found":
            vt_class = "safe"

        # 3. Both Completed — Compare Classifications
        if vt_class == "safe" and google_class == "safe":
            agreement = True
            state = "BOTH_SAFE"
            summary = "Both security providers (VirusTotal & Google Web Risk) returned clean results with zero malicious indicators."

        elif vt_class == "dangerous" and google_class == "dangerous":
            agreement = True
            state = "BOTH_DANGEROUS"
            summary = "Both security providers identified high-risk threat indicators (Malicious / Phishing / Social Engineering)."

        elif vt_class == "suspicious" and google_class == "suspicious":
            agreement = True
            state = "BOTH_SUSPICIOUS"
            summary = "Both security providers flagged suspicious indicators on the target URL."

        elif vt_class == "safe" and google_class == "dangerous":
            agreement = False
            state = "VT_SAFE_GOOGLE_DANGEROUS"
            summary = "Conflict detected: VirusTotal returned clean, but Google Web Risk flagged the URL as Social Engineering / Malware."

        elif vt_class == "dangerous" and google_class == "safe":
            agreement = False
            state = "VT_DANGEROUS_GOOGLE_SAFE"
            summary = "Conflict detected: VirusTotal flagged malicious security vendors, while Google Web Risk returned no threat match."

        elif vt_class == "suspicious" and google_class == "safe":
            agreement = False
            state = "VT_SUSPICIOUS_GOOGLE_SAFE"
            summary = "Conflict detected: VirusTotal flagged suspicious vendors, while Google Web Risk returned no threat match."

        elif vt_class == "safe" and google_class == "suspicious":
            agreement = False
            state = "VT_SAFE_GOOGLE_SUSPICIOUS"
            summary = "Conflict detected: VirusTotal returned clean, while Google Web Risk flagged unwanted software."

        else:
            agreement = False
            state = "INSUFFICIENT_DATA"
            summary = f"Provider disagreement or ambiguous signals (VirusTotal: {vt_class}, Google Web Risk: {google_class})."

        return {
            "agreement": agreement,
            "status": state,
            "summary": summary,
            "provider_details": {
                "virustotal_classification": vt_class,
                "google_web_risk_classification": google_class,
                "virustotal_status": vt_status,
                "google_web_risk_status": google_status
            }
        }
