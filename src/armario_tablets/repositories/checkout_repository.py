from datetime import datetime

from sqlalchemy import case, func, select
from sqlalchemy.orm import Session, joinedload, selectinload

from armario_tablets.models import (
    HOLDING_STATUSES,
    IN_FLIGHT_STATUSES,
    Cabinet,
    CheckoutItem,
    CheckoutSession,
    ItemStatus,
    Professor,
)


class CheckoutRepository:
    def __init__(self, db: Session) -> None:
        self._db = db

    def add_session(self, checkout: CheckoutSession) -> CheckoutSession:
        self._db.add(checkout)
        self._db.flush()
        return checkout

    def add_item(self, item: CheckoutItem) -> CheckoutItem:
        self._db.add(item)
        self._db.flush()
        return item

    def get_session(self, session_id: int, for_update: bool = False) -> CheckoutSession | None:
        if for_update:
            # Every mutating path takes cabinet -> session locks. Otherwise a new
            # request holding the cabinet can deadlock with unlock confirmation.
            cabinet_id = self._db.scalar(
                select(CheckoutSession.cabinet_id).where(CheckoutSession.id == session_id)
            )
            if cabinet_id is None:
                return None
            self._db.scalar(select(Cabinet).where(Cabinet.id == cabinet_id).with_for_update())
        query = (
            select(CheckoutSession)
            .where(CheckoutSession.id == session_id)
            .options(selectinload(CheckoutSession.professor))
        )
        if for_update:
            query = query.with_for_update(of=CheckoutSession)
        return self._db.scalar(query)

    def get_session_with_items(self, session_id: int) -> CheckoutSession | None:
        """Sessão + professor + itens + tablets numa leva só (evita consultas N+1)."""
        query = (
            select(CheckoutSession)
            .where(CheckoutSession.id == session_id)
            .options(
                joinedload(CheckoutSession.professor),
                selectinload(CheckoutSession.items).joinedload(CheckoutItem.tablet),
            )
        )
        return self._db.scalar(query)

    def find_in_flight(self, cabinet_id: int, for_update: bool = False) -> list[CheckoutSession]:
        query = select(CheckoutSession).where(
            CheckoutSession.cabinet_id == cabinet_id,
            CheckoutSession.status.in_(IN_FLIGHT_STATUSES),
        )
        if for_update:
            query = query.with_for_update()
        return list(self._db.scalars(query))

    def list_active_items(self, session_id: int) -> list[CheckoutItem]:
        query = (
            select(CheckoutItem)
            .where(CheckoutItem.session_id == session_id, CheckoutItem.status == ItemStatus.ACTIVE)
            .options(joinedload(CheckoutItem.tablet))
        )
        return list(self._db.scalars(query))

    def list_holding_sessions(self) -> list[CheckoutSession]:
        """Sessões com tablets ainda fora do armário (para a tela de devolução)."""
        query = (
            select(CheckoutSession)
            .where(CheckoutSession.status.in_(HOLDING_STATUSES))
            .options(joinedload(CheckoutSession.professor))
            .order_by(CheckoutSession.started_at)
        )
        return list(self._db.scalars(query))

    def count_by_status(self) -> dict[str, int]:
        rows = self._db.execute(
            select(CheckoutSession.status, func.count()).group_by(CheckoutSession.status)
        )
        return {status: total for status, total in rows}

    def count_item_movements(self, since: datetime, until: datetime) -> dict[str, int]:
        withdrawn = self._db.scalar(
            select(func.count(CheckoutItem.id)).where(
                CheckoutItem.checked_out_at >= since,
                CheckoutItem.checked_out_at < until,
            )
        )
        returned = self._db.scalar(
            select(func.count(CheckoutItem.id)).where(
                CheckoutItem.returned_at >= since,
                CheckoutItem.returned_at < until,
            )
        )
        return {"withdrawn": withdrawn or 0, "returned": returned or 0}

    def history(
        self,
        *,
        professor_id: int | None = None,
        status: str | None = None,
        since: datetime | None = None,
        until: datetime | None = None,
        limit: int = 20,
        offset: int = 0,
    ) -> tuple[list[tuple], int]:
        """Histórico paginado, com filtros no banco e só as colunas necessárias.

        Cada linha: (id, professor, matrícula, quantidade solicitada, retirados,
        pendentes, finalidade, turma, status, iniciada_em, concluída_em).
        """
        filters = []
        if professor_id is not None:
            filters.append(CheckoutSession.professor_id == professor_id)
        if status:
            filters.append(CheckoutSession.status == status)
        if since:
            filters.append(CheckoutSession.started_at >= since)
        if until:
            filters.append(CheckoutSession.started_at < until)

        taken = func.count(CheckoutItem.id)
        pending = func.coalesce(
            func.sum(case((CheckoutItem.status == ItemStatus.ACTIVE, 1), else_=0)),
            0,
        )
        query = (
            select(
                CheckoutSession.id,
                Professor.name,
                Professor.registration,
                CheckoutSession.requested_quantity,
                taken,
                pending,
                CheckoutSession.purpose,
                CheckoutSession.class_name,
                CheckoutSession.status,
                CheckoutSession.started_at,
                CheckoutSession.completed_at,
            )
            .join(Professor, Professor.id == CheckoutSession.professor_id)
            .outerjoin(CheckoutItem, CheckoutItem.session_id == CheckoutSession.id)
            .where(*filters)
            .group_by(CheckoutSession.id, Professor.name, Professor.registration)
            .order_by(CheckoutSession.started_at.desc(), CheckoutSession.id.desc())
            .limit(limit)
            .offset(offset)
        )
        count_query = select(func.count()).select_from(CheckoutSession).where(*filters)
        rows = [tuple(row) for row in self._db.execute(query)]
        total = self._db.scalar(count_query) or 0
        return rows, total
