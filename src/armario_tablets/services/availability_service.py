from armario_tablets.repositories.tablet_repository import TabletRepository
from armario_tablets.schemas.tablet_schema import AvailabilityOut, TabletOut


class AvailabilityService:
    def __init__(self, tablets: TabletRepository) -> None:
        self._tablets = tablets

    def available_count(self) -> int:
        return self._tablets.count_available()

    def snapshot(self) -> AvailabilityOut:
        available = self._tablets.list_available()
        total = sum(self._tablets.count_by_status().values())
        return AvailabilityOut(
            available=len(available),
            total=total,
            tablets=[TabletOut.from_model(tablet) for tablet in available],
        )
