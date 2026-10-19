from sqlalchemy import select
from sqlalchemy.orm import Session

from armario_tablets.models import Cabinet


class CabinetRepository:
    def __init__(self, db: Session) -> None:
        self._db = db

    def get(self, cabinet_id: int) -> Cabinet | None:
        return self._db.get(Cabinet, cabinet_id)

    def get_by_code(self, code: str) -> Cabinet | None:
        return self._db.scalar(select(Cabinet).where(Cabinet.code == code))

    def get_by_code_for_update(self, code: str) -> Cabinet | None:
        """Trava a linha do armário até o fim da transação (serializa pedidos simultâneos).

        No SQLite (testes unitários) o FOR UPDATE é ignorado.
        """
        return self._db.scalar(select(Cabinet).where(Cabinet.code == code).with_for_update())

    def add(self, cabinet: Cabinet) -> Cabinet:
        self._db.add(cabinet)
        self._db.flush()
        return cabinet
