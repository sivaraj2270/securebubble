import uuid
import time
import asyncio
import logging
from datetime import datetime, timezone
from typing import Dict, Any, Optional, List, Tuple
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, HttpUrl

from backend.config import get_settings
from backend.services.virustotal_service import VirusTotalService
from backend.services.google_web_risk_service import GoogleWebRiskService
from backend.services.comparison_engine import ComparisonEngine
from backend.services.risk_engine import RiskEngine
from backend.services.technitium_dns_service import TechnitiumDnsService

logger = logging.getLogger("securebubble.routes.scan")

router = APIRouter(prefix="/api/v1/scan", tags=["Dual URL Verification Scanner"])

# Services Singletons
vt_service = VirusTotalService()
google_service = GoogleWebRiskService()
comparison_engine = ComparisonEngine()
risk_engine = RiskEngine()
technitium_service = TechnitiumDnsService()

# Simple In-Memory Cache for Scan Deduplication (URL -> (timestamp, scan_result))
_scan_cache: Dict[str, Tuple[float, Dict[str, Any]]] = {}
_scan_store: Dict[str, Dict[str, Any]] = {}


class UrlScanRequest(BaseModel):
    url: str


class ScanResponse(BaseModel):
    scan_id: str
    url: str
    domain: str
    timestamp: str
    virustotal: Dict[str, Any]
    google_web_risk: Dict[str, Any]
    comparison: Dict[str, Any]
    securebubble: Dict[str, Any]


@router.post("/url", response_model=ScanResponse)
async def scan_url_endpoint(req: UrlScanRequest):
    """
    Dual URL Threat Verification Endpoint.
    
    1. Concurrently queries VirusTotal API v3 & Google Web Risk Lookup API.
    2. Runs SecureBubble Comparison Engine to evaluate provider agreement/conflicts.
    3. Calculates deterministic 0–100 Risk Score in SecureBubble Risk Engine.
    4. Triggers automatic Technitium DNS blocking if risk score exceeds auto-block threshold.
    5. Returns normalized result to mobile security popup.
    """
    raw_url = req.url.strip()
    if not raw_url:
        raise HTTPException(status_code=400, detail="Target URL cannot be empty.")

    settings = get_settings()
    now_ts = time.time()

    # Deduplication Cache Check
    if raw_url in _scan_cache:
        cached_ts, cached_result = _scan_cache[raw_url]
        if now_ts - cached_ts < settings.SCAN_CACHE_TTL_SECONDS:
            logger.info(f"Returning cached scan result for URL: {raw_url}")
            return cached_result

    domain = risk_engine.extract_domain(raw_url)
    scan_id = str(uuid.uuid4())
    iso_timestamp = datetime.now(timezone.utc).isoformat()

    # 1. Concurrent Execution of VirusTotal and Google Web Risk
    vt_task = asyncio.create_task(vt_service.scan_url(raw_url))
    google_task = asyncio.create_task(google_service.scan_url(raw_url))

    vt_result, google_result = await asyncio.gather(vt_task, google_task)

    # 2. Compare Provider Threat Classifications
    comparison = comparison_engine.compare_results(vt_result, google_result)

    # 3. Calculate Final SecureBubble Risk Score
    sb_risk = risk_engine.calculate_risk(raw_url, vt_result, google_result, comparison)
    final_score = sb_risk.get("risk_score", 0)

    # 4. Automatic Technitium DNS Block Integration for High Risk Threats
    technitium_blocked = False
    if domain and final_score >= settings.TECHNITIUM_AUTO_BLOCK_THRESHOLD:
        try:
            block_reason = f"Auto-blocked by SecureBubble AI (Risk Score: {final_score}/100)"
            asyncio.create_task(technitium_service.block_domain(domain, reason=block_reason))
            technitium_blocked = True
            logger.info(f"High risk threat ({final_score}/100) triggered Technitium DNS auto-block for domain: {domain}")
        except Exception as e:
            logger.warning(f"Technitium auto-block trigger failed for {domain}: {str(e)}")

    # 5. Construct Section 6 Normalized Result Format
    normalized_response = {
        "scan_id": scan_id,
        "url": raw_url,
        "domain": domain,
        "timestamp": iso_timestamp,
        "virustotal": {
            "status": vt_result.get("status"),
            "malicious": vt_result.get("malicious", 0),
            "suspicious": vt_result.get("suspicious", 0),
            "harmless": vt_result.get("harmless", 0),
            "undetected": vt_result.get("undetected", 0),
            "total_engines": vt_result.get("total_engines", 0),
            "classification": vt_result.get("classification")
        },
        "google_web_risk": {
            "status": google_result.get("status"),
            "threat_types": google_result.get("threat_types", []),
            "classification": google_result.get("classification")
        },
        "comparison": {
            "agreement": comparison.get("agreement"),
            "status": comparison.get("status"),
            "summary": comparison.get("summary")
        },
        "securebubble": {
            "risk_score": final_score,
            "classification": sb_risk.get("classification"),
            "confidence": sb_risk.get("confidence"),
            "reason": sb_risk.get("reason"),
            "contributing_signals": sb_risk.get("contributing_signals", []),
            "technitium_auto_blocked": technitium_blocked
        }
    }

    # Store in deduplication cache & scan history store
    _scan_cache[raw_url] = (now_ts, normalized_response)
    _scan_store[scan_id] = normalized_response

    return normalized_response


@router.get("/{scan_id}", response_model=ScanResponse)
async def get_scan_by_id(scan_id: str):
    """
    Retrieves a past scan result by scan_id.
    """
    if scan_id not in _scan_store:
        raise HTTPException(status_code=404, detail="Scan result not found.")
    return _scan_store[scan_id]
