from datetime import datetime

from sqlalchemy import DateTime, String
from sqlalchemy.orm import Mapped, mapped_column

from armario_tablets.database.base import Base
from armario_tablets.utils.datetime_utils import utcnow


class TerminalAuthorization(Base):
    __tablename__ = "terminal_authorizations"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
