from pydantic import BaseModel, Field


class RfidReading(BaseModel):
    data_hora: str | None = Field(default=None, alias="data/hora")
    uid: str | None = None
    terminal: str | None = None
    status: str | None = None


class RfidReadings(BaseModel):
    leituras: list[RfidReading]
