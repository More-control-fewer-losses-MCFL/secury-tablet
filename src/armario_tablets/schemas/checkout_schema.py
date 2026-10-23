from datetime import datetime

from pydantic import BaseModel, Field, field_validator

from armario_tablets.utils.validators import normalize_uid


class CheckoutRequestIn(BaseModel):
    badge_uid: str
    quantity: int = Field(gt=0, le=50)
    purpose: str = Field(min_length=3, max_length=200)
    class_name: str | None = Field(default=None, max_length=100)

    @field_validator("badge_uid")
    @classmethod
    def _normalize_badge(cls, value: str) -> str:
        return normalize_uid(value)


class CheckoutItemOut(BaseModel):
    asset_code: str
    status: str
    checked_out_at: datetime
    returned_at: datetime | None


class CheckoutOut(BaseModel):
    session_id: int
    status: str
    professor_name: str
    requested_quantity: int
    taken_quantity: int
    pending_quantity: int
    items: list[CheckoutItemOut]
    duplicate_event: bool = False
    divergence: str | None = None


class ReconcileIn(BaseModel):
    session_id: int
    event_id: str = Field(min_length=8, max_length=64)
    # Se vier vazio, o serviço lê o inventário do leitor configurado.
    present_tags: list[str] | None = None

    @field_validator("present_tags")
    @classmethod
    def _normalize_tags(cls, value: list[str] | None) -> list[str] | None:
        return None if value is None else [normalize_uid(tag) for tag in value]


class HistoryRow(BaseModel):
    session_id: int
    professor_name: str
    registration: str
    requested_quantity: int
    taken_quantity: int
    pending_quantity: int
    purpose: str
    class_name: str | None
    status: str
    started_at: datetime
    completed_at: datetime | None


class HistoryPage(BaseModel):
    total: int
    limit: int
    offset: int
    rows: list[HistoryRow]
