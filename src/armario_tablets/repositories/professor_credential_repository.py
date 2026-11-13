from sqlalchemy import select
from sqlalchemy.orm import Session

from armario_tablets.models import ProfessorCredential


class ProfessorCredentialRepository:
    def __init__(self, db: Session) -> None:
        self._db = db

    def get_by_username(self, username: str) -> ProfessorCredential | None:
        return self._db.scalar(
            select(ProfessorCredential).where(ProfessorCredential.username == username)
        )

    def get_by_professor(
        self, professor_id: int, *, lock: bool = False
    ) -> ProfessorCredential | None:
        return self._db.get(
            ProfessorCredential, professor_id, with_for_update=lock, populate_existing=lock
        )

    def add(self, credential: ProfessorCredential) -> None:
        self._db.add(credential)
        self._db.flush()
