"""Contracts for explicit administrative professor imports."""

from pydantic import BaseModel, Field, StrictBool, field_validator

from armario_tablets.utils.validators import normalize_uid


class ProfessorImport(BaseModel):
    registration: str = Field(min_length=1, max_length=30)
    name: str = Field(min_length=1, max_length=120)
    badge_uid: str = Field(min_length=4, max_length=32)
    active: StrictBool

    @field_validator("registration", "name", mode="before")
    @classmethod
    def strip_text(cls, value):
        return value.strip() if isinstance(value, str) else value

    @field_validator("badge_uid", mode="before")
    @classmethod
    def normalize_badge(cls, value):
        if not isinstance(value, str):
            raise ValueError("UID must be stored as text")
        return normalize_uid(value)


class ProfessorSyncResult(BaseModel):
    created: int = 0
    updated: int = 0
    unchanged: int = 0
