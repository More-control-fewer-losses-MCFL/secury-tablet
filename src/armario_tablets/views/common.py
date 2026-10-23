"""Ponte entre as páginas Streamlit e os serviços (sem SQL e sem regra de negócio)."""

from collections.abc import Iterator
from contextlib import contextmanager

import streamlit as st

from armario_tablets.config import get_settings
from armario_tablets.database.session import session_scope
from armario_tablets.exceptions import AppError
from armario_tablets.integrations import get_hardware
from armario_tablets.services.factory import Services, build_services
from armario_tablets.utils.logging_config import setup_logging

_logging_ready = False


@contextmanager
def services_scope() -> Iterator[Services]:
    """Uma sessão de banco por renderização de página."""
    global _logging_ready
    settings = get_settings()
    if not _logging_ready:
        setup_logging(settings.log_level)
        _logging_ready = True
    with session_scope() as db:
        yield build_services(db, get_hardware(), settings)


def friendly_error(error: Exception) -> str:
    """Mensagem para o usuário; erros inesperados não vazam detalhes técnicos."""
    if isinstance(error, AppError):
        return str(error)
    return "Erro inesperado. Veja o log do servidor."


def record_database_status(connected: bool) -> None:
    """Atualiza o status visível e redesenha a barra superior se ele mudou."""
    previous = st.session_state.get("database_connected")
    st.session_state["database_connected"] = connected
    if previous is not connected:
        st.rerun()
