from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ProfessorOut(BaseModel):
    """Não devolve o badge_uid: o UID não deve circular além do necessário."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    registration: str
    active: bool
    created_at: datetime
