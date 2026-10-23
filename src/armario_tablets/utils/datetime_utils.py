"""Datas: tudo é gravado em UTC e convertido só na hora de exibir."""

from datetime import UTC, datetime
from zoneinfo import ZoneInfo

LOCAL_TZ = ZoneInfo("America/Sao_Paulo")


def utcnow() -> datetime:
    return datetime.now(UTC)


def ensure_utc(value: datetime) -> datetime:
    """Garante datetime com fuso UTC (alguns bancos devolvem datas sem fuso)."""
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)


def to_local(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    return ensure_utc(value).astimezone(LOCAL_TZ)


def format_local(value: datetime | None) -> str:
    local = to_local(value)
    return local.strftime("%d/%m/%Y %H:%M:%S") if local else "-"
