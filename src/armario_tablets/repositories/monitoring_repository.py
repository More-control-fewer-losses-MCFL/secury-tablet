"""Read-only administrative monitoring queries."""

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from armario_tablets.models import CheckoutSession, Event, Tablet


class MonitoringRepository:
    def __init__(self, db: Session):
        self.db = db

    def tablet_counts(self) -> dict[str, int]:
        return dict(
            self.db.execute(
                select(Tablet.status, func.count(Tablet.id)).group_by(Tablet.status)
            ).all()
        )

    def session_counts(self) -> dict[str, int]:
        return dict(
            self.db.execute(
                select(CheckoutSession.status, func.count(CheckoutSession.id)).group_by(
                    CheckoutSession.status
                )
            ).all()
        )

    def count_alerts(self, types: tuple[str, ...]) -> int:
        return self.db.scalar(select(func.count(Event.id)).where(Event.type.in_(types))) or 0

    def list_alerts(self, types: tuple[str, ...], limit: int) -> list[Event]:
        return list(
            self.db.scalars(
                select(Event)
                .where(Event.type.in_(types))
                .order_by(Event.received_at.desc(), Event.id.desc())
                .limit(limit)
            )
        )
