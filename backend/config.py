import os
from functools import lru_cache
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Central Configuration for SecureBubble AI Backend Services & Threat Intelligence Engine.
    All secrets MUST be provided via environment variables or a local gitignored .env file.
    No hardcoded API keys or secret credentials allowed in repository source files.
    """

    # Core Application Info
    APP_NAME: str = "SecureBubble AI — Threat Intelligence Platform"
    APP_VERSION: str = "3.0.0"
    ENVIRONMENT: str = "development"
    DEBUG: bool = False
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # Security Provider Credentials (Server-Side Only - NEVER expose to APK)
    VIRUSTOTAL_API_KEY: str = ""
    GOOGLE_WEB_RISK_API_KEY: str = ""

    # Technitium DNS Server Configuration (Local Server 15.5 Integration)
    TECHNITIUM_SERVER_URL: str = "http://127.0.0.1:5380"
    TECHNITIUM_API_TOKEN: str = ""
    TECHNITIUM_ADMIN_USER: str = "admin"
    TECHNITIUM_ADMIN_PASSWORD: str = ""
    TECHNITIUM_AUTO_BLOCK_THRESHOLD: int = 85
    TECHNITIUM_TIMEOUT_SECONDS: float = 5.0

    # Database Persistence
    DATABASE_URL: str = "sqlite:///./securebubble.db"

    # Authentication & Authorization (Admin Portal Server-Side Security)
    JWT_SECRET: str = "securebubble-threat-engine-jwt-secret-key-replace-in-prod"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours
    ADMIN_ROLE_CLAIM_NAME: str = "role"
    ADMIN_DEFAULT_EMAIL: str = "admin@gmail.com"

    # Scanner & Provider Operational Rules
    PROVIDER_TIMEOUT_SECONDS: float = 4.0
    SCAN_CACHE_TTL_SECONDS: int = 300  # 5 minutes scan cache TTL
    CORS_ORIGINS: List[str] = ["*"]

    model_config = SettingsConfigDict(
        env_file=(
            os.path.join(os.path.dirname(__file__), ".env"),
            ".env",
        ),
        env_file_encoding="utf-8",
        extra="ignore"
    )


_settings_instance: Optional[Settings] = None


def get_settings() -> Settings:
    """
    Returns a singleton instance of Settings.
    """
    global _settings_instance
    if _settings_instance is None:
        _settings_instance = Settings()
    return _settings_instance


def update_settings(updates: dict) -> Settings:
    """
    Dynamically updates Settings fields from Admin Portal configuration form.
    """
    settings = get_settings()
    for key, val in updates.items():
        if hasattr(settings, key) and val is not None:
            # Type casting if necessary
            curr_val = getattr(settings, key)
            if isinstance(curr_val, int) and not isinstance(val, bool):
                try:
                    val = int(val)
                except ValueError:
                    continue
            elif isinstance(curr_val, float):
                try:
                    val = float(val)
                except ValueError:
                    continue
            elif isinstance(curr_val, bool):
                val = str(val).lower() in ["true", "1", "yes"]

            setattr(settings, key, val)
            logger.info(f"Configuration setting updated: {key}")
    return settings
