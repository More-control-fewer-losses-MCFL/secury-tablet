from __future__ import annotations

from datetime import datetime
from enum import StrEnum
from typing import TYPE_CHECKING

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, String, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from armario_tablets.database.base import Base
from armario_tablets.models.tablet import Tablet
from armario_tablets.utils.datetime_utils import utcnow

if TYPE_CHECKING:
    from armario_tablets.models.checkout_session import CheckoutSession


class ItemStatus(StrEnum):
    ACTIVE = "ACTIVE"  # tablet está fora do armário
    RETURNED = "RETURNED"


class CheckoutItem(Base):
    __tablename__ = "checkout_items"
    __table_args__ = (
        CheckConstraint("status IN ('ACTIVE', 'RETURNED')", name="status_valid"),
        Index("ix_checkout_items_session_id", "session_id"),
        # Garante no banco: um tablet nunca tem duas retiradas ativas ao mesmo tempo.
        Index(
            "uq_checkout_items_active_tablet",
            "tablet_id",
            unique=True,
            postgresql_where=text("status = 'ACTIVE'"),
            sqlite_where=text("status = 'ACTIVE'"),
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    session_id: Mapped[int] = mapped_column(ForeignKey("checkout_sessions.id"))
    tablet_id: Mapped[int] = mapped_column(ForeignKey("tablets.id"))
    checked_out_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    returned_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    status: Mapped[str] = mapped_column(String(10), default=ItemStatus.ACTIVE)

    session: Mapped[CheckoutSession] = relationship(back_populates="items")
    tablet: Mapped[Tablet] = relationship()
