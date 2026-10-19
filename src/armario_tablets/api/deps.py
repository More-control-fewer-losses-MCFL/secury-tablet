"""Dependências do FastAPI: sessão do banco e serviços montados."""

from collections.abc import Iterator

from fastapi import Depends
from sqlalchemy.orm import Session

from armario_tablets.config import Settings, get_settings
from armario_tablets.database.session import session_scope
from armario_tablets.integrations import get_hardware
from armario_tablets.services.factory import Services, build_services


def get_db() -> Iterator[Session]:
    with session_scope() as db:
        yield db


def get_services(
    db: Session = Depends(get_db), settings: Settings = Depends(get_settings)
) -> Services:
    return build_services(db, get_hardware(), settings)
