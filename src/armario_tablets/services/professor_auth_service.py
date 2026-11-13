import secrets

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from armario_tablets.database.session import unit_of_work
from armario_tablets.exceptions import (
    ProfessorCredentialsConflictError,
    ProfessorLoginInvalidError,
    ProfessorNotFoundError,
)
from armario_tablets.models import Professor, ProfessorCredential
from armario_tablets.repositories.professor_credential_repository import (
    ProfessorCredentialRepository,
)
from armario_tablets.repositories.professor_repository import ProfessorRepository
from armario_tablets.utils.datetime_utils import utcnow
from armario_tablets.utils.passwords import DUMMY_PASSWORD_HASH, hash_password, verify_password
from armario_tablets.utils.validators import normalize_username


class ProfessorAuthService:
    def __init__(self, db: Session, professors: ProfessorRepository) -> None:
        self._db = db
        self._professors = professors
        self._credentials = ProfessorCredentialRepository(db)

    def authenticate(self, username: str, password: str) -> tuple[Professor, ProfessorCredential]:
        username = normalize_username(username)
        credential = self._credentials.get_by_username(username)
        matches = verify_password(
            password, credential.password_hash if credential else DUMMY_PASSWORD_HASH
        )
        professor = self._professors.get_by_id(credential.professor_id) if credential else None
        if credential is None or not matches or professor is None or not professor.active:
            raise ProfessorLoginInvalidError("Usuário ou senha inválidos.")
        return professor, credential

    def set_credentials(
        self, professor_id: int, username: str, password: str
    ) -> ProfessorCredential:
        username = normalize_username(username)
        encoded = hash_password(password)
        try:
            with unit_of_work(self._db):
                if self._professors.get_by_id(professor_id, lock=True) is None:
                    raise ProfessorNotFoundError("Professor não encontrado.")
                current = self._credentials.get_by_professor(professor_id, lock=True)
                revision = secrets.token_urlsafe(24)
                if current is None:
                    current = ProfessorCredential(
                        professor_id=professor_id,
                        username=username,
                        password_hash=encoded,
                        revision=revision,
                    )
                    self._credentials.add(current)
                else:
                    current.username = username
                    current.password_hash = encoded
                    current.revision = revision
                    current.updated_at = utcnow()
                    self._db.flush()
            return current
        except IntegrityError:
            raise ProfessorCredentialsConflictError(
                "Esse usuário já está vinculado a outro professor."
            ) from None
