from pydantic import BaseModel, Field, SecretStr, field_validator

from armario_tablets.utils.validators import normalize_username


class ProfessorLoginIn(BaseModel):
    username: str = Field(min_length=3, max_length=80)
    password: SecretStr = Field(min_length=1, max_length=256)

    @field_validator("username")
    @classmethod
    def normalize(cls, value: str) -> str:
        return normalize_username(value)


class ProfessorCredentialsIn(ProfessorLoginIn):
    password: SecretStr = Field(min_length=12, max_length=256)


class ProfessorCredentialsOut(BaseModel):
    professor_id: int
    username: str
