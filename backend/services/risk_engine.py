import re
import logging
from urllib.parse import urlparse
from typing import Dict, Any, List, Tuple

logger = logging.getLogger("securebubble.risk_engine")


class RiskEngine:
    """
    SecureBubble Risk Engine.

    Evaluates threat signals from VirusTotal, Google Web Risk, Comparison Engine,
    and URL structural heuristics to generate a deterministic 0–100 Risk Score.

    Risk Bands (AGENTS.md & Section 11):
    - 0–30: SAFE
    - 31–60: SUSPICIOUS
    - 61–89: HIGH RISK
    - 90–100: CRITICAL

    Non-negotiable Rules:
    - Scoring is 100% deterministic and rule-based. No LLM decides verdicts.
    - Domain suffix matching is label-boundary aware (matches 'login.example.com', rejects 'example.com.evil.com').
    """

    def extract_domain(self, url: str) -> str:
        """
        Extracts clean hostname/domain from URL safely.
        """
        raw = url.strip()
        if not raw.startswith(("http://", "https://", "ftp://")):
            raw = "http://" + raw
        try:
            parsed = urlparse(raw)
            hostname = parsed.hostname or ""
            return hostname.lower()
        except Exception:
            return ""

    def matches_domain_suffix(self, hostname: str, target_domain: str) -> bool:
        """
        Label-boundary aware domain suffix matching (AGENTS.md Rule 9).
        Matches 'example.com', 'www.example.com', 'login.example.com'.
        Rejects 'example.com.evil.com'.
        """
        host = hostname.lower()
        target = target_domain.lower()
        return host == target or host.endswith("." + target)

    def calculate_risk(
        self,
        url: str,
        vt_result: Dict[str, Any],
        google_result: Dict[str, Any],
        comparison_result: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Calculates deterministic risk score 0–100, classification band, confidence, and explainable signal list.
        """
        signals: List[str] = []
        score = 0
        domain = self.extract_domain(url)
        lower_url = url.lower()

        # 1. Provider Threat Signals
        vt_class = vt_result.get("classification", "unknown")
        vt_malicious = vt_result.get("malicious", 0)
        vt_suspicious = vt_result.get("suspicious", 0)

        if vt_malicious > 0:
            added = 55 + min(vt_malicious * 10, 35)
            score += added
            signals.append(f"Flagged as malicious by VirusTotal ({vt_malicious} security vendors).")
        elif vt_suspicious > 0:
            score += 25
            signals.append(f"Flagged as suspicious by VirusTotal ({vt_suspicious} security vendors).")

        google_class = google_result.get("classification", "unknown")
        threat_types = google_result.get("threat_types", [])

        if any(t in threat_types for t in ["SOCIAL_ENGINEERING", "MALWARE"]):
            score += 65
            signals.append(f"Google Web Risk flagged threat category: {', '.join(threat_types)}.")
        elif "UNWANTED_SOFTWARE" in threat_types:
            score += 35
            signals.append("Google Web Risk flagged unwanted software.")

        # 2. Comparison Engine Signals
        comp_status = comparison_result.get("status", "INSUFFICIENT_DATA")

        if comp_status == "BOTH_DANGEROUS":
            score = max(score, 90)
            signals.append("Both VirusTotal & Google Web Risk confirm high-risk threat status.")
        elif comp_status in ["VT_SAFE_GOOGLE_DANGEROUS", "VT_DANGEROUS_GOOGLE_SAFE"]:
            score = max(score, 65)
            signals.append("Provider disagreement: One scanner flagged threat while the second returned clean.")

        # 3. Local URL Structural & Heuristic Signals
        # Ephemeral Tunnels
        tunnel_domains = ["trycloudflare.com", "ngrok-free.app", "ngrok.io", "loca.lt", "serveo.net"]
        for tunnel in tunnel_domains:
            if self.matches_domain_suffix(domain, tunnel):
                score += 85
                signals.append(f"Link routes through ephemeral phishing tunnel domain ({tunnel}).")
                break

        # High-Risk TLDs
        suspicious_tlds = [".xyz", ".top", ".tk", ".ml", ".click", ".zip", ".gq", ".work", ".icu"]
        for tld in suspicious_tlds:
            if domain.endswith(tld):
                score += 30
                signals.append(f"Registered under high-risk top-level domain ({tld}).")
                break

        # Raw IP Address URLs
        if re.search(r"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$", domain):
            score += 45
            signals.append("Raw IPv4 address host used instead of legitimate domain name.")

        # IDN Homograph / Punycode
        if domain.startswith("xn--"):
            score += 40
            signals.append("Punycode / IDN homograph domain detected (possible internationalized character spoofing).")

        # Brand Impersonation Triggers
        brand_keywords = ["paypal", "paypa1", "g00gle", "swiggy-auth", "sbi-verify", "hdfc-bank"]
        matched_brands = [b for b in brand_keywords if b in lower_url and not self.matches_domain_suffix(domain, f"{b}.com")]
        if matched_brands:
            score += 35
            signals.append(f"Brand impersonation pattern detected: {', '.join(matched_brands)}.")

        # Embedded Auth User Credentials in URL
        if "@" in lower_url:
            score += 35
            signals.append("Embedded credentials ('@') in URL structure.")

        # 4. Score Normalization & Confidence Rating
        score = min(max(score, 0), 100)

        vt_status = vt_result.get("status")
        google_status = google_result.get("status")

        if vt_status == "completed" and google_status == "completed":
            confidence = "high"
        elif vt_status == "completed" or google_status == "completed":
            confidence = "medium"
        else:
            confidence = "low"

        # 5. Risk Band Classification
        if score >= 90:
            classification = "CRITICAL"
            reason = "Critical threat detected. Link poses immediate phishing or malware hazard."
        elif score >= 61:
            classification = "HIGH RISK"
            reason = "High risk detected. Significant malicious indicators or provider disagreement."
        elif score >= 31:
            classification = "SUSPICIOUS"
            reason = "Suspicious domain structure or provider warnings detected. Exercise caution."
        else:
            score = max(score, 5)
            classification = "SAFE"
            reason = "No significant threat indicators returned by security providers or heuristic rules."
            if not signals:
                signals.append("Domain reputation clean with zero malicious indicators.")

        return {
            "risk_score": score,
            "classification": classification,
            "confidence": confidence,
            "reason": reason,
            "contributing_signals": signals,
            "domain": domain
        }
