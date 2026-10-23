from sqlalchemy import select
from sqlalchemy.orm import Session

from armario_tablets.models import Professor


class ProfessorRepository:
    def __init__(self, db: Session) -> None:
        self._db = db

    def get_by_badge(self, badge_uid: str) -> Professor | None:
        return self._db.scalar(select(Professor).where(Professor.badge_uid == badge_uid))

    def list_all(self) -> list[Professor]:
        return list(self._db.scalars(select(Professor).order_by(Professor.name)))

    def add(self, professor: Professor) -> Professor:
        self._db.add(professor)
        self._db.flush()
        return professor
