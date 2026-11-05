"""Contratos de leitura do monitoramento administrativo."""

from datetime import datetime
from typing import Literal

from pydantic import BaseModel


class AlertRecord(BaseModel):
    event_id: str
    type: str
    title: str
    severity: Literal["high", "warning"]
    occurred_at: datetime
    session_id: int | None


class InventorySummary(BaseModel):
    total: int
    available: int
    checked_out: int
    maintenance: int


class SessionsSummary(BaseModel):
    open: int
    divergent: int
    in_flight: int


class AdminOverview(BaseModel):
    inventory: InventorySummary
    sessions: SessionsSummary
    alert_events_total: int
    recent_alerts: list[AlertRecord]
