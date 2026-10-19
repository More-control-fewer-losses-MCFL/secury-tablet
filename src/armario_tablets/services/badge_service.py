import logging

from armario_tablets.exceptions import ProfessorInactiveError, ProfessorNotFoundError
from armario_tablets.models import Professor
from armario_tablets.repositories.professor_repository import ProfessorRepository
from armario_tablets.utils.validators import mask_uid, normalize_uid

logger = logging.getLogger(__name__)


class BadgeService:
    """Identifica o professor pelo UID do crachá.

    Atenção: o UID sozinho não é uma credencial criptograficamente segura
    (pode ser clonado). Aqui ele só identifica; veja docs/arquitetura.md.
    """

    def __init__(self, professors: ProfessorRepository) -> None:
        self._professors = professors

    def identify(self, badge_uid: str) -> Professor:
        uid = normalize_uid(badge_uid)
        professor = self._professors.get_by_badge(uid)
        if professor is None:
            logger.warning("Crachá não cadastrado (%s)", mask_uid(uid))
            raise ProfessorNotFoundError("Crachá não cadastrado.")
        if not professor.active:
            logger.warning("Cadastro inativo (professor id=%s)", professor.id)
            raise ProfessorInactiveError("Cadastro do professor está inativo.")
        return professor
