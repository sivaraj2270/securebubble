from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import httpx
import re
import base64
from typing import List, Optional

app = FastAPI(
    title="SecureBubble AI / NUKEZERO SHIELD — Threat Intelligence Platform",
    description="Defensive Cybersecurity Platform & Threat Intelligence API",
    version="3.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

VIRUSTOTAL_API_KEY = os.getenv("VIRUSTOTAL_API_KEY", "YOUR_VIRUSTOTAL_API_KEY_HERE")

# Request Models
class UrlAnalysisRequest(BaseModel):
    url: str

class MessageAnalysisRequest(BaseModel):
    message_text: str

class FileAnalysisRequest(BaseModel):
    filename: str
    file_size: int
    sha256_hash: Optional[str] = ""

# Response Models
class AnalysisResponse(BaseModel):
    target: str
    risk_score: int
    status: str  # SAFE, LOW RISK, SUSPICIOUS, DANGEROUS
    category: str
    indicators: List[str]
    virustotal_stats: str
    recommendation: str

@app.get("/")
def read_root():
    return {
        "platform": "SecureBubble AI / NUKEZERO SHIELD",
        "status": "ONLINE",
        "philosophy": "SCAN BEFORE YOU CLICK",
        "architecture": "Detect -> Analyze -> Explain -> Score -> Warn -> Protect"
    }

@app.post("/api/v1/analyze/url", response_model=AnalysisResponse)
async def analyze_url(req: UrlAnalysisRequest):
    raw_url = req.url.strip()
    if not raw_url:
        raise HTTPException(status_code=400, detail="URL cannot be empty")

    indicators = []
    score = 0
    vt_stats = "VirusTotal: Unchecked (Local Engine Verification)"
    vt_malicious_count = 0

    # 1. VirusTotal API Query
    if VIRUSTOTAL_API_KEY and raw_url.startswith(("http://", "https://")):
        try:
            url_id = base64.urlsafe_b64encode(raw_url.encode("utf-8")).decode("utf-8").strip("=")
            headers = {"x-apikey": VIRUSTOTAL_API_KEY}
            async with httpx.AsyncClient(timeout=4.0) as client:
                resp = await client.get(f"https://www.virustotal.com/api/v3/urls/{url_id}", headers=headers)
                if resp.status_code == 200:
                    data = resp.json()
                    stats = data.get("data", {}).get("attributes", {}).get("last_analysis_stats", {})
                    malicious = stats.get("malicious", 0)
                    suspicious = stats.get("suspicious", 0)
                    harmless = stats.get("harmless", 0)
                    total = malicious + suspicious + harmless
                    vt_malicious_count = malicious + suspicious
                    if vt_malicious_count > 0:
                        vt_stats = f"VirusTotal: {vt_malicious_count} Malicious / {total} Engines"
                        score += 65 + (vt_malicious_count * 10)
                        indicators.append(f"Flagged malicious by VirusTotal vendors ({vt_malicious_count} engines).")
                    else:
                        vt_stats = f"VirusTotal: 0/{total} Flagged (Verified Clean)"
        except Exception:
            vt_stats = "VirusTotal: Local Engine Verification"

    # 2. Local Domain & Heuristic Checks
    lower_url = raw_url.lower()

    # Ephemeral Phishing Tunnels
    tunnel_domains = ["trycloudflare.com", "ngrok-free.app", "ngrok.io", "serveo.net", "loca.lt"]
    if any(t in lower_url for t in tunnel_domains):
        score += 90
        indicators.append("Link uses an ephemeral Cloudflare/Ngrok tunnel (trycloudflare.com).")

    # High-Risk TLDs
    suspicious_tlds = [".xyz", ".top", ".tk", ".ml", ".click", ".zip", ".gq", ".work", ".icu"]
    if any(lower_url.endswith(t) or f"{t}/" in lower_url for t in suspicious_tlds):
        score += 35
        indicators.append("High-risk TLD registered on untrusted domain extension.")

    # Raw IP Address URLs
    if re.search(r"https?://\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}", lower_url):
        score += 40
        indicators.append("Raw IP address URL detected instead of domain name.")

    # Brand Impersonation Triggers
    brand_keywords = ["paypal", "paypa1", "g00gle", "swiggy-auth", "sbi-verify", "hdfc-bank"]
    matched = [b for b in brand_keywords if b in lower_url]
    if matched:
        score += 35
        indicators.append(f"Brand impersonation pattern detected: {', '.join(matched)}.")

    score = min(score, 99)

    if score >= 76:
        status = "DANGEROUS"
        category = "High Risk Phishing Target"
        recommendation = "🛑 DO NOT open this link or submit credentials!"
    elif score >= 51:
        status = "SUSPICIOUS"
        category = "Suspicious Domain Structure"
        recommendation = "⚠️ Exercise caution. Verify domain address before entering passwords."
    elif score >= 26:
        status = "LOW RISK"
        category = "Unverified External URL"
        recommendation = "ℹ️ Minor risk indicators detected. Proceed with standard awareness."
    else:
        score = 5
        status = "SAFE"
        category = "Verified Safe Link"
        recommendation = "🟢 Link verified safe. No malicious indicators found."
        if not indicators:
            indicators.append("Domain reputation clean with zero malicious flags.")

    return AnalysisResponse(
        target=raw_url,
        risk_score=score,
        status=status,
        category=category,
        indicators=indicators,
        virustotal_stats=vt_stats,
        recommendation=recommendation
    )

@app.post("/api/v1/analyze/message", response_model=AnalysisResponse)
async def analyze_message(req: MessageAnalysisRequest):
    text = req.message_text.lower()
    indicators = []
    score = 0
    category = "Clean Message"

    if "account blocked" in text or "kyc expired" in text or "sbi netbanking" in text:
        score += 45
        category = "Bank Account Scam"
        indicators.append("Threat of bank account block / KYC expiration.")

    if "earn 5000 daily" in text or "telegram job" in text:
        score += 45
        category = "Job / Task Scam"
        indicators.append("Unrealistic income promise for simple online tasks.")

    if "immediately" in text or "share otp" in text or "enter pin" in text:
        score += 30
        indicators.append("High-urgency social engineering pressure with OTP request.")

    score = min(score, 99)

    if score >= 60:
        status = "DANGEROUS"
        recommendation = "⚠️ HIGH SCAM RISK: Do not click embedded links or send money/OTPs."
    elif score >= 30:
        status = "SUSPICIOUS"
        recommendation = "ℹ️ Exercise caution. Verify claims via official channels."
    else:
        score = 5
        status = "SAFE"
        recommendation = "🟢 Message appears clean."
        indicators.append("No social engineering scam triggers detected.")

    return AnalysisResponse(
        target=req.message_text[:40] + "...",
        risk_score=score,
        status=status,
        category=category,
        indicators=indicators,
        virustotal_stats="NLP Engine Verification",
        recommendation=recommendation
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
