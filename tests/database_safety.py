"""Validação obrigatória antes de executar DDL destrutiva nos testes."""

from sqlalchemy.engine import make_url


def validate_test_database_url(value: str) -> str:
    url = make_url(value)
    if url.get_backend_name() != "mysql" or not (url.database or "").endswith("_test"):
        raise ValueError("TEST_DATABASE_URL deve usar MySQL e um banco com sufixo _test.")
    return value
