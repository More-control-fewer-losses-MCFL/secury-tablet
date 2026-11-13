import time

from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session

from armario_tablets.api.deps import get_db, get_services
from armario_tablets.api.operational_auth import (
    Principal,
    require_admin,
    require_principal,
    sign_claims,
)
from armario_tablets.api.routes.admin import _token_secret
from armario_tablets.config import Settings, get_settings
from armario_tablets.models import Professor
from armario_tablets.schemas.professor_auth_schema import (
    ProfessorCredentialsIn,
    ProfessorCredentialsOut,
    ProfessorLoginIn,
)
from armario_tablets.schemas.professor_schema import ProfessorOut
from armario_tablets.services.factory import Services

router = APIRouter(tags=["acesso de professor"])


@router.post("/auth/professor/login")
def login_professor(
    body: ProfessorLoginIn,
    response: Response,
    settings: Settings = Depends(get_settings),
    services: Services = Depends(get_services),
) -> dict:
    _token_secret(settings)
    professor, credential = services.professor_auth.authenticate(
        body.username, body.password.get_secret_value()
    )
    ttl = settings.professor_session_ttl_minutes * 60
    response.headers["Cache-Control"] = "no-store"
    return {
        "access_token": sign_claims(
            {
                "role": "professor",
                "sub": professor.id,
                "auth": "password",
                "revision": credential.revision,
                "exp": int(time.time()) + ttl,
            },
            settings,
        ),
        "token_type": "bearer",
        "expires_in": ttl,
        "professor": ProfessorOut.model_validate(professor).model_dump(mode="json"),
    }


@router.get("/auth/professor/session")
def professor_session(
    response: Response,
    principal: Principal = Depends(require_principal),
    db: Session = Depends(get_db),
) -> dict:
    if principal.role != "professor":
        raise HTTPException(403, "Sessão de professor necessária.")
    response.headers["Cache-Control"] = "no-store"
    return {
        "role": "professor",
        "professor": ProfessorOut.model_validate(
            db.get(Professor, principal.professor_id)
        ).model_dump(mode="json"),
    }


@router.post("/admin/professors/{professor_id}/credentials", response_model=ProfessorCredentialsOut)
def set_professor_credentials(
    professor_id: int,
    body: ProfessorCredentialsIn,
    principal: Principal = Depends(require_admin),
    services: Services = Depends(get_services),
) -> ProfessorCredentialsOut:
    credential = services.professor_auth.set_credentials(
        professor_id, body.username, body.password.get_secret_value()
    )
    return ProfessorCredentialsOut(
        professor_id=credential.professor_id, username=credential.username
    )
