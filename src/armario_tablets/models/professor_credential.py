from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from armario_tablets.database.base import Base
from armario_tablets.utils.datetime_utils import utcnow


class ProfessorCredential(Base):
    __tablename__ = "professor_credentials"

    professor_id: Mapped[int] = mapped_column(
        ForeignKey("professors.id", ondelete="CASCADE"), primary_key=True
    )
    username: Mapped[str] = mapped_column(String(80), unique=True)
    password_hash: Mapped[str] = mapped_column(String(256))
    revision: Mapped[str] = mapped_column(String(64))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )
