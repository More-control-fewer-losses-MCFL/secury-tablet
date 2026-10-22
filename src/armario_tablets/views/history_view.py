"""View Histórico — operações anteriores com filtros, paginação e CSV."""

from __future__ import annotations

import csv
import io
from datetime import UTC, datetime, time, timedelta
from zoneinfo import ZoneInfo

import streamlit as st

from armario_tablets.config import get_settings
from armario_tablets.views.common import (
    friendly_error,
    record_database_status,
    services_scope,
)
from armario_tablets.views.components import history_table_data
from armario_tablets.views.theme import (
    page_header,
    render_sidebar_status,
)

PAGE_SIZE = 20
LOCAL_TZ = ZoneInfo("America/Sao_Paulo")
STATUSES = [
    "Todos",
    "PENDING",
    "UNLOCKED",
    "OPEN",
    "DIVERGENT",
    "COMPLETED",
    "CANCELLED",
    "FAILED",
]


def render() -> None:
    settings = get_settings()
    simulated = settings.hardware_simulated
    render_sidebar_status(simulated=simulated, api_ok=st.session_state.get("database_connected"))

    page_header(
        "Histórico",
        "Retiradas e devoluções anteriores com filtros, paginação e exportação.",
    )

    # ── Filtros ──────────────────────────────────────────────────────
    col_status, col_page, col_refresh, _ = st.columns([2, 1, 1, 2])
    status = col_status.selectbox("Situação", STATUSES)
    page_number = col_page.number_input("Página", min_value=1, value=1, step=1)
    col_refresh.button("🔄 Atualizar", width="stretch")

    with st.expander("Filtros de professor e data"):
        col_professor, col_since, col_until = st.columns(3)
        try:
            with services_scope() as services:
                professors = services.professors.list_all()
        except Exception as err:
            st.error(friendly_error(err))
            record_database_status(False)
            return

        professor_options = {
            "Todos": None,
            **{
                f"{professor.name} · {professor.registration}": professor.id
                for professor in professors
            },
        }
        selected_professor = col_professor.selectbox(
            "Professor", list(professor_options), key="history_professor_filter"
        )
        since_date = col_since.date_input("De", value=None, key="history_since_filter")
        until_date = col_until.date_input("Até", value=None, key="history_until_filter")

    since = (
        datetime.combine(since_date, time.min, tzinfo=LOCAL_TZ).astimezone(UTC)
        if since_date
        else None
    )
    until = (
        datetime.combine(until_date + timedelta(days=1), time.min, tzinfo=LOCAL_TZ).astimezone(UTC)
        if until_date
        else None
    )
    if since and until and since >= until:
        st.warning("A data inicial deve ser anterior ou igual à data final.")
        return

    # ── Dados ────────────────────────────────────────────────────────
    try:
        with services_scope() as services:
            page = services.history.page(
                professor_id=professor_options[selected_professor],
                status=None if status == "Todos" else status,
                since=since,
                until=until,
                limit=PAGE_SIZE,
                offset=(int(page_number) - 1) * PAGE_SIZE,
            )
        record_database_status(True)
    except Exception as err:
        st.error(friendly_error(err))
        record_database_status(False)
        return

    total_pages = max(1, -(-page.total // PAGE_SIZE))

    # ── Info de paginação ────────────────────────────────────────────
    st.markdown(
        '<div class="sc-card"><div class="sc-card-header">'
        f"<h3>📋 {page.total} registro(s) — página {int(page_number)} de {total_pages}</h3>"
        "</div></div>",
        unsafe_allow_html=True,
    )

    # ── Tabela ───────────────────────────────────────────────────────
    data = history_table_data(page.rows)
    if data:
        st.dataframe(data, hide_index=True, width="stretch")
    else:
        st.info("Nenhum registro encontrado com os filtros selecionados.")

    # ── Exportação CSV ───────────────────────────────────────────────
    if data:
        st.markdown("<br>", unsafe_allow_html=True)
        csv_data = _to_csv(data)
        st.download_button(
            label="📥 Exportar CSV",
            data=csv_data,
            file_name="historico_tablets.csv",
            mime="text/csv",
            width="content",
        )


def _to_csv(rows: list[dict]) -> str:
    """Converte lista de dicts em string CSV."""
    if not rows:
        return ""
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=rows[0].keys())
    writer.writeheader()
    writer.writerows(rows)
    return output.getvalue()
