from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr


class AdminLoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    expires_in_minutes: int


class AdminUserProfile(BaseModel):
    id: str
    email: str
    role: str
    is_active: bool
    created_at: str
    last_login: Optional[str] = None


class JWTClaim(BaseModel):
    sub: str
    role: str
    exp: int
