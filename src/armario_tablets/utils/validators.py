"""Validação e normalização de UIDs (crachá e etiqueta RFID dos tablets)."""

import re

from armario_tablets.exceptions import InvalidUidError

_UID_PATTERN = re.compile(r"^[0-9A-F]{4,32}$")


def normalize_uid(value: str) -> str:
    """Remove espaços/':'/'-' e deixa em maiúsculas. Aceita 4 a 32 dígitos hexadecimais."""
    cleaned = re.sub(r"[\s:\-]", "", value or "").upper()
    if not _UID_PATTERN.fullmatch(cleaned):
        raise InvalidUidError("UID inválido: use de 4 a 32 caracteres hexadecimais.")
    return cleaned


def mask_uid(value: str) -> str:
    """Máscara para logs: nunca grave o UID completo."""
    return f"***{value[-4:]}" if value and len(value) > 4 else "***"
