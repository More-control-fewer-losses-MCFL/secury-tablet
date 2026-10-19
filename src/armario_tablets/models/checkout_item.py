from __future__ import annotations

from datetime import datetime
from enum import StrEnum
from typing import TYPE_CHECKING

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, String, event, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Mapped, Session, mapped_column, relationship

from armario_tablets.database.base import Base
from armario_tablets.models.tablet import Tablet
from armario_tablets.utils.datetime_utils import utcnow

if TYPE_CHECKING:
    from armario_tablets.models.checkout_session import CheckoutSession


class ItemStatus(StrEnum):
    ACTIVE = "ACTIVE"  # tablet está fora do armário
    RETURNED = "RETURNED"


@event.listens_for(Session, "before_flush")
def _guard_active_checkout_duplication(session, flush_context, instances):
    pending = list(session.new) + list(session.dirty)
    active_tablets: set[int] = set()
    for instance in pending:
        if not isinstance(instance, CheckoutItem):
            continue
        if instance.status != ItemStatus.ACTIVE:
            continue
        if instance.tablet_id in active_tablets:
            raise IntegrityError(
                statement="SELECT 1",
                params={},
                orig=ValueError("tablet already has an active checkout"),
            )
        active_tablets.add(instance.tablet_id)

    for instance in pending:
        if not isinstance(instance, CheckoutItem):
            continue
        if instance.status != ItemStatus.ACTIVE:
            continue
        existing = session.execute(
            select(CheckoutItem.id).where(
                CheckoutItem.tablet_id == instance.tablet_id,
                CheckoutItem.status == ItemStatus.ACTIVE,
            )
        ).scalars().first()
        if existing is not None and getattr(instance, "id", None) != existing:
            raise IntegrityError(
                statement="SELECT 1",
                params={},
                orig=ValueError("tablet already has an active checkout"),
            )


class CheckoutItem(Base):
    __tablename__ = "checkout_items"
    __table_args__ = (
        CheckConstraint("status IN ('ACTIVE', 'RETURNED')", name="status_valid"),
        Index("ix_checkout_items_session_id", "session_id"),
        Index("ix_checkout_items_tablet_status", "tablet_id", "status"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    session_id: Mapped[int] = mapped_column(ForeignKey("checkout_sessions.id"))
    tablet_id: Mapped[int] = mapped_column(ForeignKey("tablets.id"))
    checked_out_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    returned_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    status: Mapped[str] = mapped_column(String(10), default=ItemStatus.ACTIVE)

    session: Mapped[CheckoutSession] = relationship(back_populates="items")
    tablet: Mapped[Tablet] = relationship()
