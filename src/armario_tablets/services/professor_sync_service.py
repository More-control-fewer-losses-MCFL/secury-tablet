"""Atomic explicit imports, preserving identity and loan history."""

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from armario_tablets.database.session import unit_of_work
from armario_tablets.exceptions import ProfessorImportConflictError
from armario_tablets.models import Professor
from armario_tablets.repositories.professor_repository import ProfessorRepository
from armario_tablets.schemas.professor_sync_schema import ProfessorImport, ProfessorSyncResult


class ProfessorSyncService:
    def __init__(self, db: Session, professors: ProfessorRepository):
        self.db = db
        self.professors = professors

    def sync(self, records: list[ProfessorImport]) -> ProfessorSyncResult:
        result = ProfessorSyncResult()
        try:
            with unit_of_work(self.db):
                for record in records:
                    professor = self.professors.get_by_registration(record.registration)
                    badge_owner = self.professors.get_by_badge(record.badge_uid)
                    if badge_owner is not None and (
                        professor is None or badge_owner.id != professor.id
                    ):
                        raise ProfessorImportConflictError(
                            "Cracha ja vinculado a outro cadastro; importacao cancelada."
                        )
                    if professor is None:
                        self.professors.add(Professor(**record.model_dump()))
                        result.created += 1
                    elif (professor.name, professor.badge_uid, professor.active) == (
                        record.name,
                        record.badge_uid,
                        record.active,
                    ):
                        result.unchanged += 1
                    else:
                        professor.name = record.name
                        professor.badge_uid = record.badge_uid
                        professor.active = record.active
                        result.updated += 1
        except IntegrityError:
            raise ProfessorImportConflictError(
                "Conflito de cadastro; nenhuma alteracao foi salva."
            ) from None
        return result
