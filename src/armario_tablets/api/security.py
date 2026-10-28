"""Credencial exclusiva do controlador; nunca deve ser incluída no Flutter Web."""

import hmac

from fastapi import Depends, HTTPException, Security
from fastapi.security import APIKeyHeader

from armario_tablets.config import Settings, get_settings

hardware_key = APIKeyHeader(name="X-Hardware-Key", auto_error=False)


def require_hardware_key(
    supplied: str | None = Security(hardware_key),
    settings: Settings = Depends(get_settings),
) -> None:
    configured = settings.hardware_api_key
    expected = configured.get_secret_value().encode("utf-8") if configured else b""
    if len(expected) < 32:
        raise HTTPException(
            status_code=503,
            detail="Controlador não configurado. Defina HARDWARE_API_KEY com ao menos 32 bytes.",
        )
    if supplied is None or not hmac.compare_digest(supplied.encode("utf-8"), expected):
        raise HTTPException(status_code=401, detail="Credencial do controlador inválida.")
