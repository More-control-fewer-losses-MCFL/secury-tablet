"""Engine único por processo, fábrica de sessões e controle de transação."""

from collections.abc import Iterator
from contextlib import contextmanager
from functools import lru_cache

from sqlalchemy import Engine, create_engine
from sqlalchemy.orm import Session, sessionmaker

from armario_tablets.config import get_settings


@lru_cache
def get_engine() -> Engine:
    """Um único Engine por processo (ele já gerencia o pool de conexões)."""
    url = get_settings().sqlalchemy_url
    driver = url.drivername if hasattr(url, "drivername") else str(url)
    kwargs = {
        "pool_pre_ping": True,
        "pool_size": 5,
        "max_overflow": 5,
    }
    if "mysql" in driver or "postgres" in driver:
        kwargs["isolation_level"] = "READ COMMITTED"
    return create_engine(url, **kwargs)


@lru_cache
def get_session_factory() -> sessionmaker[Session]:
    return sessionmaker(bind=get_engine(), expire_on_commit=False)


@contextmanager
def session_scope() -> Iterator[Session]:
    """Abre uma sessão e a fecha no final. Quem chama decide quando fazer commit."""
    db = get_session_factory()()
    try:
        yield db
    finally:
        db.close()


@contextmanager
def unit_of_work(db: Session) -> Iterator[Session]:
    """Transação de negócio: commit se tudo der certo, rollback se der erro."""
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
