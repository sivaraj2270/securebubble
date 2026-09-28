import os
import time
import hmac
import hashlib
import logging
from datetime import datetime, timezone, timedelta
from typing import Dict, Any, Optional

import jwt
from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from backend.config import get_settings
from backend.models.admin import AdminLoginRequest, TokenResponse, AdminUserProfile, JWTClaim

logger = logging.getLogger("securebubble.routes.auth")

router = APIRouter(prefix="/api/v1/auth/admin", tags=["Admin Authentication & Authorization"])

security_scheme = HTTPBearer()

# Default administrative credentials configured for SecureBubble AI
DEFAULT_ADMIN_EMAIL = "admin@gmail.com"
DEFAULT_ADMIN_PASSWORD = "tree1010234"


def hash_password(password: str, salt: bytes = b"securebubble_admin_salt_2026") -> str:
    """
    PBKDF2-HMAC-SHA256 password hashing.
    """
    pwd_bytes = password.encode("utf-8")
    key = hashlib.pbkdf2_hmac("sha256", pwd_bytes, salt, 100000)
    return key.hex()


def verify_password(plain_password: str, hashed_password: str, salt: bytes = b"securebubble_admin_salt_2026") -> bool:
    """
    Constant-time password comparison.
    """
    calculated_hash = hash_password(plain_password, salt)
    return hmac.compare_digest(calculated_hash, hashed_password)


DEFAULT_ADMIN_HASH = hash_password(DEFAULT_ADMIN_PASSWORD)


def create_jwt_token(email: str, role: str) -> str:
    """
    Creates a signed JWT access token containing server-assigned role claim.
    """
    settings = get_settings()
    now = datetime.now(timezone.utc)
    expire = now + timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)

    payload = {
        "sub": email,
        "role": role,
        "iat": int(now.timestamp()),
        "exp": int(expire.timestamp())
    }

    token = jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
    return token


def verify_admin_role(credentials: HTTPAuthorizationCredentials = Depends(security_scheme)) -> Dict[str, Any]:
    """
    Server-Side Authorization Dependency.

    Verifies that the incoming JWT token:
    1. Is valid and signed with server JWT_SECRET.
    2. Has not expired.
    3. Contains server-assigned claim 'role' == 'admin'.

    Client-supplied flags are NEVER trusted.
    """
    settings = get_settings()
    token = credentials.credentials

    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET,
            algorithms=[settings.JWT_ALGORITHM]
        )
        email: str = payload.get("sub")
        role: str = payload.get("role")

        if not email or not role:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload claims."
            )

        if role != "admin":
            logger.warning(f"Forbidden access attempt by non-admin user: {email} (role={role})")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied. Administrative privilege required."
            )

        return payload

    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Admin authentication token has expired. Please log in again."
        )
    except jwt.PyJWTError as e:
        logger.error(f"JWT Verification failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate admin authentication credentials."
        )


@router.post("/login", response_model=TokenResponse)
async def admin_login(req: AdminLoginRequest):
    """
    Admin Portal Login Endpoint.
    Verifies credentials server-side and issues a signed JWT containing 'role': 'admin'.
    """
    settings = get_settings()
    admin_email = settings.ADMIN_DEFAULT_EMAIL or DEFAULT_ADMIN_EMAIL

    if req.email.strip().lower() != admin_email.lower():
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid administrative email or password."
        )

    if not verify_password(req.password, DEFAULT_ADMIN_HASH):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid administrative email or password."
        )

    access_token = create_jwt_token(email=admin_email, role="admin")

    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        role="admin",
        expires_in_minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES
    )


@router.get("/me", response_model=AdminUserProfile)
async def get_current_admin(claims: Dict[str, Any] = Depends(verify_admin_role)):
    """
    Returns authenticated admin profile. Protected by verify_admin_role server-side check.
    """
    return AdminUserProfile(
        id="admin-001",
        email=claims.get("sub", DEFAULT_ADMIN_EMAIL),
        role=claims.get("role", "admin"),
        is_active=True,
        created_at="2026-09-17T00:00:00Z",
        last_login=datetime.now(timezone.utc).isoformat()
    )
