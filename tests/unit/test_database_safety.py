import pytest

from tests.database_safety import validate_test_database_url


@pytest.mark.parametrize("database", ["armario_tablets", "mysql", "", "production"])
def test_rejects_non_test_database(database):
    with pytest.raises(ValueError, match="sufixo _test"):
        validate_test_database_url(f"mysql+pymysql://user:password@localhost/{database}")


def test_accepts_dedicated_mysql_database():
    url = "mysql+pymysql://user:password@localhost/armario_tablets_test"
    assert validate_test_database_url(url) == url


def test_rejects_other_database_backends():
    with pytest.raises(ValueError):
        validate_test_database_url("postgresql://localhost/armario_tablets_test")
