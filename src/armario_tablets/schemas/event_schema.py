from datetime import datetime
from enum import StrEnum
from typing import Any

from pydantic import BaseModel, Field


class EventType(StrEnum):
    # Vindos do hardware
    DOOR_OPENED = "DOOR_OPENED"
    DOOR_CLOSED = "DOOR_CLOSED"
    INVENTORY_AFTER_CHECKOUT = "INVENTORY_AFTER_CHECKOUT"
    INVENTORY_AFTER_RETURN = "INVENTORY_AFTER_RETURN"
    LOCK_ERROR = "LOCK_ERROR"
    READER_ERROR = "READER_ERROR"
    # Gerados pelo sistema
    CHECKOUT_REQUESTED = "CHECKOUT_REQUESTED"
    UNLOCK_CONFIRMED = "UNLOCK_CONFIRMED"
    CHECKOUT_CONFIRMED = "CHECKOUT_CONFIRMED"
    CHECKOUT_CANCELLED = "CHECKOUT_CANCELLED"
    PARTIAL_WITHDRAWAL = "PARTIAL_WITHDRAWAL"
    EXTRA_WITHDRAWAL = "EXTRA_WITHDRAWAL"
    RETURN_RECONCILED = "RETURN_RECONCILED"
    RETURN_DIVERGENCE = "RETURN_DIVERGENCE"
    SESSION_EXPIRED = "SESSION_EXPIRED"


HARDWARE_EVENT_TYPES = (
    EventType.DOOR_OPENED,
    EventType.DOOR_CLOSED,
    EventType.INVENTORY_AFTER_CHECKOUT,
    EventType.INVENTORY_AFTER_RETURN,
    EventType.LOCK_ERROR,
    EventType.READER_ERROR,
)


class HardwareEventIn(BaseModel):
    event_id: str = Field(min_length=8, max_length=64)
    cabinet_code: str = Field(max_length=20)
    type: EventType
    occurred_at: datetime
    session_id: int | None = None
    # Para eventos de inventário: {"present_tags": ["A1B2C3D4", ...]}
    details: dict[str, Any] = Field(default_factory=dict)


class EventOut(BaseModel):
    event_id: str
    type: str
    duplicate: bool = False
    session_id: int | None = None
    session_status: str | None = None
