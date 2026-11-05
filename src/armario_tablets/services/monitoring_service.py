"""Historical alert classification and monitoring summaries."""

from typing import Literal

from armario_tablets.models import Event
from armario_tablets.models.checkout_session import IN_FLIGHT_STATUSES, SessionStatus
from armario_tablets.models.tablet import TabletStatus
from armario_tablets.repositories.monitoring_repository import MonitoringRepository
from armario_tablets.schemas.event_schema import EventType
from armario_tablets.schemas.monitoring_schema import (
    AdminOverview,
    AlertRecord,
    InventorySummary,
    SessionsSummary,
)

# Não há semântica de alarme para DOOR_OPENED isoladamente: uma porta aberta pode
# ser uma operação autorizada. Detectar abertura indevida requer contexto físico.
ALERT_TITLES: dict[str, str] = {
    EventType.LOCK_ERROR: "Falha na fechadura",
    EventType.READER_ERROR: "Falha no leitor RFID",
    EventType.EXTRA_WITHDRAWAL: "Retirada acima da quantidade autorizada",
    EventType.RETURN_DIVERGENCE: "Divergência na devolução",
}

ALERT_SEVERITIES: dict[str, Literal["high", "warning"]] = {
    EventType.LOCK_ERROR: "high",
    EventType.READER_ERROR: "high",
    EventType.EXTRA_WITHDRAWAL: "high",
    EventType.RETURN_DIVERGENCE: "warning",
}


def _alert_record(event: Event) -> AlertRecord:
    return AlertRecord(
        event_id=event.event_id,
        type=event.type,
        title=ALERT_TITLES[event.type],
        severity=ALERT_SEVERITIES[event.type],
        occurred_at=event.occurred_at,
        session_id=event.session_id,
    )


class MonitoringService:
    def __init__(self, repository: MonitoringRepository):
        self.repository = repository

    def list_alerts(self, limit: int) -> list[AlertRecord]:
        return [
            _alert_record(event)
            for event in self.repository.list_alerts(tuple(ALERT_TITLES), limit)
        ]

    def overview(self) -> AdminOverview:
        tablet_counts = self.repository.tablet_counts()
        session_counts = self.repository.session_counts()
        return AdminOverview(
            inventory=InventorySummary(
                total=sum(tablet_counts.values()),
                available=tablet_counts.get(TabletStatus.AVAILABLE, 0),
                checked_out=tablet_counts.get(TabletStatus.CHECKED_OUT, 0),
                maintenance=tablet_counts.get(TabletStatus.MAINTENANCE, 0),
            ),
            sessions=SessionsSummary(
                open=session_counts.get(SessionStatus.OPEN, 0),
                divergent=session_counts.get(SessionStatus.DIVERGENT, 0),
                in_flight=sum(session_counts.get(state, 0) for state in IN_FLIGHT_STATUSES),
            ),
            alert_events_total=self.repository.count_alerts(tuple(ALERT_TITLES)),
            recent_alerts=self.list_alerts(5),
        )
