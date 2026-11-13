import pytest
from sqlalchemy import inspect, select, text

from armario_tablets.exceptions import ProfessorCredentialsConflictError, ProfessorLoginInvalidError
from armario_tablets.models import Professor, ProfessorCredential
from armario_tablets.repositories.professor_repository import ProfessorRepository
from armario_tablets.services.professor_auth_service import ProfessorAuthService
from tests.factories import ACTIVE_BADGE, OTHER_ACTIVE_BADGE, seed_basic

PASSWORD = "fictional-mysql-professor-password"


def test_alembic_creates_unique_credentials_and_foreign_key(mysql_engine):
    inspector = inspect(mysql_engine)
    assert "professor_credentials" in inspector.get_table_names()
    assert any(
        item["column_names"] == ["username"]
        for item in inspector.get_unique_constraints("professor_credentials")
    )
    assert inspector.get_foreign_keys("professor_credentials")[0]["referred_table"] == "professors"
    with mysql_engine.connect() as conn:
        assert conn.scalar(text("SELECT version_num FROM alembic_version")) == "0004"


def test_credentials_persist_and_reset_across_connections(session_factory):
    with session_factory() as db:
        seed_basic(db)
        professor = db.scalar(select(Professor).where(Professor.badge_uid == ACTIVE_BADGE))
        professor_id = professor.id
        auth = ProfessorAuthService(db, ProfessorRepository(db))
        original = auth.set_credentials(professor_id, "Teacher.Ana", PASSWORD).revision
    with session_factory() as db:
        auth = ProfessorAuthService(db, ProfessorRepository(db))
        assert auth.authenticate("teacher.ana", PASSWORD)[0].id == professor_id
        updated = auth.set_credentials(
            professor_id, "teacher.ana", "another-mysql-professor-password"
        )
        assert updated.revision != original
    with session_factory() as db:
        auth = ProfessorAuthService(db, ProfessorRepository(db))
        with pytest.raises(ProfessorLoginInvalidError):
            auth.authenticate("teacher.ana", PASSWORD)
        assert (
            auth.authenticate("teacher.ana", "another-mysql-professor-password")[0].id
            == professor_id
        )
        assert db.get(ProfessorCredential, professor_id).password_hash.startswith("scrypt$")


def test_mysql_username_conflict_does_not_transfer_ownership(session_factory):
    with session_factory() as db:
        seed_basic(db)
        first = db.scalar(select(Professor.id).where(Professor.badge_uid == ACTIVE_BADGE))
        other = db.scalar(select(Professor.id).where(Professor.badge_uid == OTHER_ACTIVE_BADGE))
        auth = ProfessorAuthService(db, ProfessorRepository(db))
        auth.set_credentials(first, "teacher.ana", PASSWORD)
        with pytest.raises(ProfessorCredentialsConflictError):
            auth.set_credentials(other, "TEACHER.ANA", PASSWORD)
        assert db.get(ProfessorCredential, other) is None
        assert auth.authenticate("teacher.ana", PASSWORD)[0].id == first
