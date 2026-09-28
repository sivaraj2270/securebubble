import json
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text, Float
from backend.database.database import Base


class ScanModel(Base):
    """
    Section 38: Scan Record Entity.
    Stores normalized threat verification history.
    """
    __tablename__ = "scans"

    scan_id = Column(String(64), primary_key=True, index=True)
    url = Column(Text, nullable=False)
    domain = Column(String(255), nullable=False, index=True)
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    
    # VirusTotal Normalized Output
    vt_status = Column(String(32), nullable=False)
    vt_malicious = Column(Integer, default=0)
    vt_suspicious = Column(Integer, default=0)
    vt_classification = Column(String(32), nullable=False)

    # Google Web Risk Normalized Output
    google_status = Column(String(32), nullable=False)
    google_threat_types = Column(Text, default="[]")  # JSON string
    google_classification = Column(String(32), nullable=False)

    # SecureBubble Engine Evaluation
    comparison_state = Column(String(64), nullable=False)
    comparison_summary = Column(Text, nullable=False)
    
    risk_score = Column(Integer, nullable=False)
    classification = Column(String(32), nullable=False)  # SAFE, SUSPICIOUS, HIGH RISK, CRITICAL
    confidence = Column(String(32), nullable=False)
    reason = Column(Text, nullable=False)
    contributing_signals_json = Column(Text, default="[]")


class BlockedDomainModel(Base):
    """
    Section 25 & 38: Persistent Blocked Domain Entity.
    """
    __tablename__ = "blocked_domains"

    domain = Column(String(255), primary_key=True, index=True)
    reason = Column(Text, nullable=False)
    risk_score = Column(Integer, default=85)
    added_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    added_by = Column(String(128), nullable=False)


class AuditEventModel(Base):
    """
    Section 28: Administrative Audit Log Entity.
    Tracks all sensitive admin actions (login, block, unblock, false positive override).
    """
    __tablename__ = "audit_logs"

    event_id = Column(String(64), primary_key=True, index=True)
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    admin_id = Column(String(128), nullable=False, index=True)
    action = Column(String(64), nullable=False)  # e.g., 'DOMAIN_BLOCKED', 'FALSE_POSITIVE_OVERRIDE'
    target = Column(String(255), nullable=False)
    old_value = Column(Text, nullable=True)
    new_value = Column(Text, nullable=True)
    ip_address = Column(String(64), nullable=True)


class ProviderHealthModel(Base):
    """
    Section 24: Security Provider Health & Latency Log Entity.
    """
    __tablename__ = "provider_health"

    provider_name = Column(String(64), primary_key=True)  # 'virustotal' | 'google_web_risk'
    status = Column(String(32), nullable=False)  # 'ONLINE' | 'ERROR' | 'UNCONFIGURED'
    last_successful_request = Column(DateTime, nullable=True)
    response_time_ms = Column(Float, default=0.0)
    error_count_24h = Column(Integer, default=0)
