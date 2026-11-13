from armario_tablets.repositories.tablet_repository import TabletRepository
from armario_tablets.schemas.tablet_schema import AvailabilityOut, TabletOut


class AvailabilityService:
    def __init__(self, tablets: TabletRepository) -> None:
        self._tablets = tablets

    def available_count(self) -> int:
        return self._tablets.count_available()

    def snapshot(self, *, include_tablets: bool = True) -> AvailabilityOut:
        available = self._tablets.list_available() if include_tablets else []
        total = sum(self._tablets.count_by_status().values())
        return AvailabilityOut(
            available=len(available) if include_tablets else self.available_count(),
            total=total,
            tablets=[TabletOut.from_model(tablet) for tablet in available],
        )
