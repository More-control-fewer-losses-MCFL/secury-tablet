import base64
import hashlib
import hmac
import json
import time

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel, Field, SecretStr

from armario_tablets.config import Settings, get_settings

router = APIRouter(prefix="/admin", tags=["administração"])


class AdminLoginIn(BaseModel):
    username: str = Field(min_length=1, max_length=80)
    password: SecretStr = Field(max_length=256)


def _token_secret(settings: Settings) -> bytes:
    password = settings.admin_password
    secret = settings.admin_token_secret
    if (
        password is None
        or len(password.get_secret_value()) < 12
        or secret is None
        or len(secret.get_secret_value().encode("utf-8")) < 32
    ):
        raise HTTPException(
            status_code=503,
            detail=(
                "Acesso administrativo não configurado. Defina ADMIN_PASSWORD "
                "(mínimo de 12 caracteres) e ADMIN_TOKEN_SECRET (mínimo de 32 bytes)."
            ),
        )
    return secret.get_secret_value().encode("utf-8")


def _encode_token(username: str, settings: Settings, secret: bytes) -> str:
    payload = {
        "sub": username,
        "role": "admin",
        "exp": int(time.time()) + settings.admin_session_ttl_minutes * 60,
    }
    encoded = base64.urlsafe_b64encode(
        json.dumps(payload, separators=(",", ":")).encode("utf-8")
    ).rstrip(b"=")
    signature = hmac.new(secret, encoded, hashlib.sha256).digest()
    encoded_signature = base64.urlsafe_b64encode(signature).rstrip(b"=")
    return f"{encoded.decode('ascii')}.{encoded_signature.decode('ascii')}"


def _valid_token(token: str, settings: Settings, secret: bytes) -> str | None:
    try:
        if len(token) > 4096:
            return None
        encoded, signature_part = token.split(".")
        signature = base64.b64decode(
            signature_part + "=" * (-len(signature_part) % 4),
            altchars=b"-_",
            validate=True,
        )
        expected = hmac.new(secret, encoded.encode("ascii"), hashlib.sha256).digest()
        if not hmac.compare_digest(signature, expected):
            return None
        payload_bytes = base64.b64decode(
            encoded + "=" * (-len(encoded) % 4), altchars=b"-_", validate=True
        )
        payload = json.loads(payload_bytes)
        if (
            not isinstance(payload, dict)
            or payload.get("role") != "admin"
            or not isinstance(payload.get("sub"), str)
            or payload["sub"] != settings.admin_username
            or not isinstance(payload.get("exp"), int)
            or payload["exp"] <= int(time.time())
        ):
            return None
        return payload["sub"]
    except (ValueError, UnicodeError):
        return None


@router.post("/login")
def login(body: AdminLoginIn, settings: Settings = Depends(get_settings)) -> dict[str, str | int]:
    secret = _token_secret(settings)
    expected_username = settings.admin_username.encode("utf-8")
    submitted_username = body.username.encode("utf-8")
    expected_password = settings.admin_password.get_secret_value().encode("utf-8")
    submitted_password = body.password.get_secret_value().encode("utf-8")
    username_matches = hmac.compare_digest(submitted_username, expected_username)
    password_matches = hmac.compare_digest(submitted_password, expected_password)
    if not (username_matches and password_matches):
        raise HTTPException(status_code=401, detail="Usuário ou senha administrativa inválidos.")

    return {
        "access_token": _encode_token(settings.admin_username, settings, secret),
        "token_type": "bearer",
        "expires_in": settings.admin_session_ttl_minutes * 60,
        "username": settings.admin_username,
    }


@router.get("/session")
def get_admin_session(
    authorization: str | None = Header(default=None),
    settings: Settings = Depends(get_settings),
) -> dict[str, str]:
    secret = _token_secret(settings)
    scheme, _, token = (authorization or "").partition(" ")
    username = _valid_token(token, settings, secret) if scheme.lower() == "bearer" else None
    if username is None:
        raise HTTPException(
            status_code=401,
            detail="Sessão administrativa inválida ou expirada.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return {"username": username, "role": "admin"}
