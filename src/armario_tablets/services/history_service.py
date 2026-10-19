from datetime import datetime

from armario_tablets.models import SessionStatus
from armario_tablets.repositories.checkout_repository import CheckoutRepository
from armario_tablets.repositories.tablet_repository import TabletRepository
from armario_tablets.schemas.checkout_schema import HistoryPage, HistoryRow


class HistoryService:
    """Consultas de leitura: histórico paginado e números do dashboard."""

    MAX_PAGE_SIZE = 100

    def __init__(self, checkouts: CheckoutRepository, tablets: TabletRepository) -> None:
        self._checkouts = checkouts
        self._tablets = tablets

    def page(
        self,
        *,
        professor_id: int | None = None,
        status: str | None = None,
        since: datetime | None = None,
        until: datetime | None = None,
        limit: int = 20,
        offset: int = 0,
    ) -> HistoryPage:
        limit = max(1, min(limit, self.MAX_PAGE_SIZE))
        offset = max(0, offset)
        rows, total = self._checkouts.history(
            professor_id=professor_id,
            status=status,
            since=since,
            until=until,
            limit=limit,
            offset=offset,
        )
        return HistoryPage(
            total=total,
            limit=limit,
            offset=offset,
            rows=[
                HistoryRow(
                    session_id=r[0],
                    professor_name=r[1],
                    registration=r[2],
                    requested_quantity=r[3],
                    taken_quantity=r[4],
                    pending_quantity=r[5],
                    purpose=r[6],
                    class_name=r[7],
                    status=r[8],
                    started_at=r[9],
                    completed_at=r[10],
                )
                for r in rows
            ],
        )

    def dashboard(self) -> dict:
        tablets_by_status = self._tablets.count_by_status()
        sessions_by_status = self._checkouts.count_by_status()
        divergent = self.page(status=SessionStatus.DIVERGENT, limit=self.MAX_PAGE_SIZE)
        return {
            "available": self._tablets.count_available(),
            "tablets_by_status": tablets_by_status,
            "sessions_by_status": sessions_by_status,
            "open_sessions": sessions_by_status.get(SessionStatus.OPEN, 0),
            "divergences": divergent.rows,
        }
