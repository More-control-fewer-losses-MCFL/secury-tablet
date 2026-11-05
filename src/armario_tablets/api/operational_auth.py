"""RFID identifies a teacher only inside an administrator-authorized terminal.

This is terminal trust, not cryptographic proof of the badge holder's identity.
"""

import base64
import hashlib
import hmac
import json
import time
from dataclasses import dataclass

from fastapi import Cookie, Depends, Header, HTTPException
from sqlalchemy.orm import Session

from armario_tablets.api.deps import get_db
from armario_tablets.api.routes.admin import _token_secret, _valid_token
from armario_tablets.config import Settings, get_settings
from armario_tablets.models import Professor, TerminalAuthorization

TERMINAL_COOKIE = "secury_terminal"


def sign_claims(claims: dict, settings: Settings) -> str:
    encoded = base64.urlsafe_b64encode(json.dumps(claims).encode()).rstrip(b"=")
    signature = hmac.new(_token_secret(settings), encoded, hashlib.sha256).digest()
    return encoded.decode() + "." + base64.urlsafe_b64encode(signature).rstrip(b"=").decode()


def read_claims(token: str | None, role: str, settings: Settings) -> dict:
    try:
        if not token or len(token) > 4096:
            raise ValueError
        encoded, signature = token.split(".")
        actual = base64.b64decode(
            signature + "=" * (-len(signature) % 4), altchars=b"-_", validate=True
        )
        expected = hmac.new(
            _token_secret(settings), encoded.encode("ascii"), hashlib.sha256
        ).digest()
        if not hmac.compare_digest(actual, expected):
            raise ValueError
        claims = json.loads(
            base64.b64decode(encoded + "=" * (-len(encoded) % 4), altchars=b"-_", validate=True)
        )
        if (
            not isinstance(claims, dict)
            or claims.get("role") != role
            or type(claims.get("exp")) is not int
            or claims["exp"] <= time.time()
        ):
            raise ValueError
        return claims
    except (ValueError, UnicodeError):
        raise HTTPException(
            401, "Sessão inválida ou expirada.", headers={"WWW-Authenticate": "Bearer"}
        ) from None


def validate_terminal(token: str | None, settings: Settings, db: Session) -> dict:
    if not token:
        raise HTTPException(401, "Terminal não autorizado. Solicite autorização ao administrador.")
    claims = read_claims(token, "terminal", settings)
    if (
        not isinstance(claims.get("sub"), str)
        or not claims["sub"]
        or db.get(TerminalAuthorization, claims["sub"]) is None
    ):
        raise HTTPException(401, "Terminal não autorizado ou revogado.")
    return claims


def require_terminal(
    terminal: str | None = Cookie(default=None, alias=TERMINAL_COOKIE),
    settings: Settings = Depends(get_settings),
    db: Session = Depends(get_db),
) -> dict:
    return validate_terminal(terminal, settings, db)


@dataclass(frozen=True)
class Principal:
    role: str
    professor_id: int | None = None
    badge_uid: str | None = None


def require_principal(
    authorization: str | None = Header(default=None),
    terminal: str | None = Cookie(default=None, alias=TERMINAL_COOKIE),
    settings: Settings = Depends(get_settings),
    db: Session = Depends(get_db),
) -> Principal:
    scheme, _, token = (authorization or "").partition(" ")
    if scheme.lower() != "bearer":
        raise HTTPException(401, "Sessão necessária.", headers={"WWW-Authenticate": "Bearer"})
    if _valid_token(token, settings, _token_secret(settings)):
        return Principal("admin")
    claims = read_claims(token, "professor", settings)
    terminal_claims = validate_terminal(terminal, settings, db)
    if claims.get("terminal") != terminal_claims.get("sub"):
        raise HTTPException(401, "Sessão vinculada a outro terminal.")
    professor_id = claims.get("sub")
    if type(professor_id) is not int:
        raise HTTPException(401, "Sessão inválida.")
    professor = db.get(Professor, professor_id)
    if professor is None or not professor.active:
        raise HTTPException(403, "Cadastro indisponível.")
    return Principal("professor", professor.id, professor.badge_uid)


def require_admin(principal: Principal = Depends(require_principal)) -> Principal:
    if principal.role != "admin":
        raise HTTPException(403, "Operação exclusiva da administração.")
    return principal
