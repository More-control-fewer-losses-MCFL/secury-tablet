"""View Dashboard — métricas, gráfico de uso, ocupação dos tablets."""

from __future__ import annotations

import streamlit as st

from armario_tablets.config import get_settings
from armario_tablets.utils.datetime_utils import format_local
from armario_tablets.views.common import (
    friendly_error,
    record_database_status,
    services_scope,
)
from armario_tablets.views.components import build_dashboard_metrics
from armario_tablets.views.theme import (
    page_header,
    render_metric_cards,
    render_sidebar_status,
    render_simulation_warning,
    render_usage_chart,
    tablet_grid,
)


def render() -> None:
    settings = get_settings()
    simulated = settings.hardware_simulated

    page_header(
        "Dashboard",
        "Visão geral de tablets, retiradas, devoluções e disponibilidade.",
    )

    if simulated:
        render_simulation_warning()

    # ── Dados ────────────────────────────────────────────────────────
    try:
        with services_scope() as services:
            data = services.history.dashboard()
            all_tablets = services.tablets.list_all()
            professors_count = len(services.professors.list_all())
    except Exception as err:
        st.error(friendly_error(err))
        record_database_status(False)
        render_sidebar_status(simulated=simulated, api_ok=False)
        return

    record_database_status(True)
    render_sidebar_status(simulated=simulated, api_ok=True)

    # ── Métricas ─────────────────────────────────────────────────────
    metrics = build_dashboard_metrics(data, professors_count)
    render_metric_cards(metrics)

    # ── Layout: ocupação + gráfico uso ───────────────────────────────
    col_grid, col_chart = st.columns([3, 1])

    with col_grid:
        st.markdown(
            '<div class="sc-card"><div class="sc-card-header">'
            "<h3>📱 Ocupação dos Tablets</h3></div></div>",
            unsafe_allow_html=True,
        )
        tablet_grid((t.asset_code, t.status) for t in all_tablets)

    with col_chart:
        tbs = data.get("tablets_by_status", {})
        render_usage_chart(
            total=sum(tbs.values()),
            available=tbs.get("AVAILABLE", 0),
            checked_out=tbs.get("CHECKED_OUT", 0),
            maintenance=tbs.get("MAINTENANCE", 0),
        )

    # ── Divergências ─────────────────────────────────────────────────
    st.markdown("<br>", unsafe_allow_html=True)
    st.markdown(
        '<div class="sc-card"><div class="sc-card-header">'
        "<h3>⚠️ Divergências e Pendências</h3></div></div>",
        unsafe_allow_html=True,
    )

    divergences = data.get("divergences", [])
    if not divergences:
        st.success("Nenhuma divergência em aberto no momento.", icon=":material/check_circle:")
    else:
        st.dataframe(
            [
                {
                    "Solicitação": r.session_id,
                    "Professor": r.professor_name,
                    "Retirados": r.taken_quantity,
                    "Pendentes": r.pending_quantity,
                    "Início": format_local(r.started_at),
                }
                for r in divergences
            ],
            hide_index=True,
            width="stretch",
        )
