from datetime import datetime
from enum import StrEnum

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from armario_tablets.database.base import Base
from armario_tablets.models.checkout_item import CheckoutItem
from armario_tablets.models.professor import Professor
from armario_tablets.utils.datetime_utils import utcnow


class SessionStatus(StrEnum):
    PENDING = "PENDING"  # validada; aguardando confirmação da fechadura
    UNLOCKED = "UNLOCKED"  # fechadura confirmou; aguardando leitura do inventário
    OPEN = "OPEN"  # tablets retirados e em uso
    DIVERGENT = "DIVERGENT"  # devolução incompleta: há itens pendentes
    COMPLETED = "COMPLETED"  # tudo devolvido
    CANCELLED = "CANCELLED"  # nada foi retirado ou a reserva expirou
    FAILED = "FAILED"  # erro de fechadura/leitor


# Sessões que "ocupam" o armário (uma porta só: uma retirada por vez).
IN_FLIGHT_STATUSES = (SessionStatus.PENDING, SessionStatus.UNLOCKED)
# Sessões com tablets ainda fora do armário.
HOLDING_STATUSES = (SessionStatus.OPEN, SessionStatus.DIVERGENT)


class CheckoutSession(Base):
    __tablename__ = "checkout_sessions"
    __table_args__ = (
        CheckConstraint(
            "status IN ('PENDING','UNLOCKED','OPEN','DIVERGENT','COMPLETED','CANCELLED','FAILED')",
            name="status_valid",
        ),
        CheckConstraint("requested_quantity > 0", name="quantity_positive"),
        Index("ix_checkout_sessions_status", "status"),
        Index("ix_checkout_sessions_started_at", "started_at"),
        Index("ix_checkout_sessions_professor_id", "professor_id"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    professor_id: Mapped[int] = mapped_column(ForeignKey("professors.id"))
    cabinet_id: Mapped[int] = mapped_column(ForeignKey("cabinets.id"))
    requested_quantity: Mapped[int] = mapped_column(Integer)
    purpose: Mapped[str] = mapped_column(String(200))
    class_name: Mapped[str | None] = mapped_column(String(100))  # turma/disciplina (opcional)
    status: Mapped[str] = mapped_column(String(20), default=SessionStatus.PENDING)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    professor: Mapped[Professor] = relationship()
    items: Mapped[list[CheckoutItem]] = relationship(back_populates="session")
