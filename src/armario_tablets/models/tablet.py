from datetime import datetime
from enum import StrEnum

from sqlalchemy import CheckConstraint, DateTime, Index, String
from sqlalchemy.orm import Mapped, mapped_column

from armario_tablets.database.base import Base
from armario_tablets.utils.datetime_utils import utcnow


class TabletStatus(StrEnum):
    AVAILABLE = "AVAILABLE"
    CHECKED_OUT = "CHECKED_OUT"
    MAINTENANCE = "MAINTENANCE"


class Tablet(Base):
    __tablename__ = "tablets"
    __table_args__ = (
        CheckConstraint(
            "status IN ('AVAILABLE', 'CHECKED_OUT', 'MAINTENANCE')", name="status_valid"
        ),
        Index("ix_tablets_status", "status"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    asset_code: Mapped[str] = mapped_column(String(40), unique=True)
    # Etiqueta RFID individual. Pode ser nula se o tablet ainda não foi etiquetado.
    rfid_tag_uid: Mapped[str | None] = mapped_column(String(32), unique=True)
    status: Mapped[str] = mapped_column(String(20), default=TabletStatus.AVAILABLE)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )
