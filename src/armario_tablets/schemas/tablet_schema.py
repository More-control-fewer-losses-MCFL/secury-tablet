from datetime import datetime

from pydantic import BaseModel, ConfigDict


class TabletOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    asset_code: str
    has_rfid_tag: bool
    status: str
    updated_at: datetime

    @classmethod
    def from_model(cls, tablet) -> "TabletOut":
        return cls(
            id=tablet.id,
            asset_code=tablet.asset_code,
            has_rfid_tag=tablet.rfid_tag_uid is not None,
            status=tablet.status,
            updated_at=tablet.updated_at,
        )


class AvailabilityOut(BaseModel):
    available: int
    total: int
    tablets: list[TabletOut]
