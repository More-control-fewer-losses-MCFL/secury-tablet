from collections.abc import Collection

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from armario_tablets.models import Tablet, TabletStatus


class TabletRepository:
    def __init__(self, db: Session) -> None:
        self._db = db

    def list_all(self, status: str | None = None) -> list[Tablet]:
        query = select(Tablet).order_by(Tablet.asset_code)
        if status:
            query = query.where(Tablet.status == status)
        return list(self._db.scalars(query))

    def list_available(self) -> list[Tablet]:
        """Disponível = no armário E com etiqueta RFID (sem etiqueta não dá para confirmar)."""
        query = (
            select(Tablet)
            .where(Tablet.status == TabletStatus.AVAILABLE, Tablet.rfid_tag_uid.is_not(None))
            .order_by(Tablet.asset_code)
        )
        return list(self._db.scalars(query))

    def count_available(self) -> int:
        query = (
            select(func.count())
            .select_from(Tablet)
            .where(Tablet.status == TabletStatus.AVAILABLE, Tablet.rfid_tag_uid.is_not(None))
        )
        return self._db.scalar(query) or 0

    def count_by_status(self) -> dict[str, int]:
        rows = self._db.execute(select(Tablet.status, func.count()).group_by(Tablet.status))
        return {status: total for status, total in rows}

    def list_available_for_update(self) -> list[Tablet]:
        """Disponíveis, com a linha travada durante a transação."""
        query = (
            select(Tablet)
            .where(Tablet.status == TabletStatus.AVAILABLE, Tablet.rfid_tag_uid.is_not(None))
            .order_by(Tablet.asset_code)
            .with_for_update()
        )
        return list(self._db.scalars(query))

    def get_by_tags(self, tags: Collection[str]) -> list[Tablet]:
        if not tags:
            return []
        return list(self._db.scalars(select(Tablet).where(Tablet.rfid_tag_uid.in_(tags))))

    def get_by_asset_code(self, asset_code: str) -> Tablet | None:
        return self._db.scalar(select(Tablet).where(Tablet.asset_code == asset_code))

    def add(self, tablet: Tablet) -> Tablet:
        self._db.add(tablet)
        self._db.flush()
        return tablet
