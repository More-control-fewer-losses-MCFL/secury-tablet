"""Importar todos os modelos aqui garante que o Alembic e o SQLAlchemy os conheçam."""

from armario_tablets.models.cabinet import Cabinet, DoorState, LockState
from armario_tablets.models.checkout_item import CheckoutItem, ItemStatus
from armario_tablets.models.checkout_session import (
    HOLDING_STATUSES,
    IN_FLIGHT_STATUSES,
    CheckoutSession,
    SessionStatus,
)
from armario_tablets.models.event import Event
from armario_tablets.models.professor import Professor
from armario_tablets.models.tablet import Tablet, TabletStatus
from armario_tablets.models.terminal_authorization import TerminalAuthorization

__all__ = [
    "HOLDING_STATUSES",
    "IN_FLIGHT_STATUSES",
    "Cabinet",
    "CheckoutItem",
    "CheckoutSession",
    "DoorState",
    "Event",
    "ItemStatus",
    "LockState",
    "Professor",
    "SessionStatus",
    "Tablet",
    "TabletStatus",
    "TerminalAuthorization",
]
