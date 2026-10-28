import secrets
import time

from fastapi import APIRouter, Depends, Response
from pydantic import BaseModel, field_validator
from sqlalchemy.orm import Session

from armario_tablets.api.deps import get_db, get_services
from armario_tablets.api.operational_auth import TERMINAL_COOKIE, require_terminal, sign_claims
from armario_tablets.api.routes.admin import get_admin_session
from armario_tablets.config import Settings, get_settings
from armario_tablets.database.session import unit_of_work
from armario_tablets.models import TerminalAuthorization
from armario_tablets.schemas.professor_schema import ProfessorOut
from armario_tablets.services.factory import Services
from armario_tablets.utils.validators import normalize_uid

router = APIRouter(tags=["terminal"])


class RfidLoginIn(BaseModel):
    badge_uid: str

    @field_validator("badge_uid")
    @classmethod
    def normalize(cls, value: str) -> str:
        return normalize_uid(value)


@router.post("/terminal/authorize", dependencies=[Depends(get_admin_session)])
def authorize_terminal(
    response: Response, settings: Settings = Depends(get_settings), db: Session = Depends(get_db)
) -> dict:
    ttl = settings.terminal_session_ttl_minutes * 60
    terminal_id = secrets.token_urlsafe(24)
    with unit_of_work(db):
        db.add(TerminalAuthorization(id=terminal_id))
    token = sign_claims(
        {"role": "terminal", "sub": terminal_id, "exp": int(time.time()) + ttl},
        settings,
    )
    response.set_cookie(
        TERMINAL_COOKIE,
        token,
        max_age=ttl,
        httponly=True,
        secure=settings.session_cookie_secure,
        samesite="strict",
        path="/",
    )
    return {"authorized": True, "expires_in": ttl}


@router.post("/terminal/revoke", dependencies=[Depends(get_admin_session)])
def revoke_terminal(
    response: Response, terminal: dict = Depends(require_terminal), db: Session = Depends(get_db)
) -> dict:
    with unit_of_work(db):
        record = db.get(TerminalAuthorization, terminal["sub"])
        if record is not None:
            db.delete(record)
    response.delete_cookie(TERMINAL_COOKIE, path="/", samesite="strict")
    return {"authorized": False}


@router.post("/auth/rfid")
def rfid_login(
    body: RfidLoginIn,
    terminal: dict = Depends(require_terminal),
    settings: Settings = Depends(get_settings),
    services: Services = Depends(get_services),
) -> dict:
    professor = services.badges.identify(body.badge_uid)
    expires = min(int(time.time()) + settings.professor_session_ttl_minutes * 60, terminal["exp"])
    return {
        "access_token": sign_claims(
            {"role": "professor", "sub": professor.id, "terminal": terminal["sub"], "exp": expires},
            settings,
        ),
        "token_type": "bearer",
        "expires_in": max(0, expires - int(time.time())),
        "professor": ProfessorOut.model_validate(professor).model_dump(mode="json"),
    }
