"""Monta os serviços já ligados entre si. Usado pela API, pelo Streamlit, scripts e testes."""

from dataclasses import dataclass

from sqlalchemy.orm import Session

from armario_tablets.config import Settings
from armario_tablets.integrations.simulated_hardware import Hardware
from armario_tablets.repositories.cabinet_repository import CabinetRepository
from armario_tablets.repositories.checkout_repository import CheckoutRepository
from armario_tablets.repositories.event_repository import EventRepository
from armario_tablets.repositories.professor_repository import ProfessorRepository
from armario_tablets.repositories.tablet_repository import TabletRepository
from armario_tablets.services.availability_service import AvailabilityService
from armario_tablets.services.badge_service import BadgeService
from armario_tablets.services.cabinet_service import CabinetService
from armario_tablets.services.checkout_service import CheckoutService
from armario_tablets.services.event_service import HardwareEventService
from armario_tablets.services.history_service import HistoryService
from armario_tablets.services.inventory_service import InventoryService
from armario_tablets.services.return_service import ReturnService


@dataclass
class Services:
    badges: BadgeService
    availability: AvailabilityService
    checkout: CheckoutService
    returns: ReturnService
    events: HardwareEventService
    history: HistoryService
    inventory: InventoryService
    cabinets: CabinetService
    professors: ProfessorRepository
    tablets: TabletRepository


def build_services(
    db: Session,
    hardware: Hardware,
    settings: Settings,
    *,
    poll_interval_seconds: float = 0.1,
) -> Services:
    professors = ProfessorRepository(db)
    tablets = TabletRepository(db)
    cabinet_repo = CabinetRepository(db)
    checkouts = CheckoutRepository(db)
    events = EventRepository(db)

    badges = BadgeService(professors)
    cabinets = CabinetService(
        cabinet_repo,
        hardware.lock_controller,
        settings.lock_confirm_timeout_seconds,
        poll_interval_seconds,
    )
    inventory = InventoryService(tablets, hardware.tablet_reader)
    checkout = CheckoutService(
        db,
        badges,
        cabinets,
        checkouts,
        tablets,
        events,
        inventory,
        settings.reservation_ttl_minutes,
    )
    returns = ReturnService(db, cabinets, checkouts, tablets, events, inventory)
    return Services(
        badges=badges,
        availability=AvailabilityService(tablets),
        checkout=checkout,
        returns=returns,
        events=HardwareEventService(db, cabinets, checkouts, events, checkout, returns),
        history=HistoryService(checkouts, tablets),
        inventory=inventory,
        cabinets=cabinets,
        professors=professors,
        tablets=tablets,
    )
