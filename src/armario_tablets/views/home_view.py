"""View Início — banner, indicadores, movimentações recentes e avisos."""

from __future__ import annotations

import streamlit as st

from armario_tablets.config import get_settings
from armario_tablets.utils.validators import mask_uid
from armario_tablets.views.common import (
    friendly_error,
    record_database_status,
    services_scope,
)
from armario_tablets.views.components import (
    build_dashboard_metrics,
    format_movements_for_display,
    format_notifications,
)
from armario_tablets.views.theme import (
    render_banner,
    render_metric_cards,
    render_movements_table,
    render_notifications_panel,
    render_quick_actions,
    render_sidebar_status,
    render_simulation_warning,
)


def render() -> None:
    settings = get_settings()
    simulated = settings.hardware_simulated

    # ── Carregar dados ───────────────────────────────────────────────
    api_ok: bool | None = None
    data: dict = {}
    professors_count = 0
    recent_sessions = []
    professors = []
    matching_tablets = []
    search_query = st.session_state.get("global_search", "").strip().casefold()

    try:
        with services_scope() as services:
            data = services.history.dashboard()
            professors = services.professors.list_all()
            professors_count = len(professors)
            page = services.history.page(limit=8, offset=0)
            recent_sessions = page.rows
            if search_query:
                matching_tablets = [
                    tablet
                    for tablet in services.tablets.list_all()
                    if search_query in tablet.asset_code.casefold()
                ]
        api_ok = True
    except Exception as err:
        api_ok = False
        st.error(friendly_error(err))

    record_database_status(api_ok)
    st.session_state["rfid_connected"] = None  # simulado

    # ── Sidebar ──────────────────────────────────────────────────────
    render_sidebar_status(
        simulated=simulated,
        api_ok=api_ok,
    )

    # ── Aviso de simulação ───────────────────────────────────────────
    if simulated:
        render_simulation_warning()

    # ── Banner principal ─────────────────────────────────────────────
    cabinet_status = None
    if api_ok and simulated:
        try:
            with services_scope() as services:
                cabinet = services.cabinets.get_by_code(settings.cabinet_code)
                cabinet_status = {
                    "door_state": cabinet.door_state,
                    "lock_state": cabinet.lock_state,
                }
        except Exception as err:
            st.warning(f"Estado do armário indisponível: {friendly_error(err)}")

    render_banner(
        title="Bem-vindo ao\nTablet de Segurança",
        subtitle=(
            "Gerencie a retirada e a devolução de tablets por professores identificados por RFID"
        ),
        cabinet_status=cabinet_status,
        last_rfid=(
            mask_uid(st.session_state["last_rfid_read"])
            if st.session_state.get("last_rfid_read")
            else None
        ),
        hardware_simulated=simulated,
        data_connected=api_ok,
    )

    # ── Cards de indicadores ─────────────────────────────────────────
    render_metric_cards(
        build_dashboard_metrics(data if api_ok else None, professors_count if api_ok else None)
    )

    if search_query:
        matching_professors = [
            professor
            for professor in professors
            if any(
                search_query in value.casefold()
                for value in (professor.name, professor.registration, professor.badge_uid)
            )
        ]
        st.subheader("Resultados da busca")
        if not api_ok:
            st.info("A busca está indisponível enquanto o banco local estiver desconectado.")
        elif matching_professors:
            st.dataframe(
                [
                    {
                        "Professor": professor.name,
                        "Matrícula": professor.registration,
                        "Crachá RFID": mask_uid(professor.badge_uid),
                        "Situação": "Ativo" if professor.active else "Inativo",
                    }
                    for professor in matching_professors
                ],
                hide_index=True,
                width="stretch",
            )
        if api_ok and matching_tablets:
            st.dataframe(
                [
                    {"Patrimônio": tablet.asset_code, "Situação": tablet.status}
                    for tablet in matching_tablets
                ],
                hide_index=True,
                width="stretch",
            )
        if api_ok and not matching_professors and not matching_tablets:
            st.info("Nenhum professor, crachá ou patrimônio corresponde à busca.")

    # ── Movimentações + Avisos lado a lado ───────────────────────────
    col_left, col_right = st.columns([3, 1])

    with col_left:
        if api_ok:
            movements = format_movements_for_display(recent_sessions)
            render_movements_table(movements)
        else:
            st.warning("Movimentações indisponíveis: não foi possível consultar o banco local.")

    with col_right:
        divergences = data.get("divergences", []) if api_ok else []
        notifications = format_notifications(divergences, api_ok, simulated)
        st.session_state["notification_count"] = sum(
            1 for n in notifications if n["type"] in ("error", "warning")
        )
        render_notifications_panel(notifications)

    # ── Ações rápidas ────────────────────────────────────────────────
    st.markdown("<br>", unsafe_allow_html=True)
    render_quick_actions(
        [
            {
                "icon": "🔓",
                "title": "Registrar Retirada",
                "description": "Leitura RFID do professor e liberação do armário.",
                "href": "/Solicitar_Tablets",
            },
            {
                "icon": "📥",
                "title": "Registrar Devolução",
                "description": "Leitura RFID do crachá e conferência dos tablets.",
                "href": "/Devolucao",
            },
            {
                "icon": "📱",
                "title": "Consultar Tablets",
                "description": "Verificar disponibilidade e situação dos tablets.",
                "href": "/Tablets",
            },
            {
                "icon": "📊",
                "title": "Gerar Relatório",
                "description": "Exportar movimentações e histórico.",
                "href": "/Historico",
            },
        ]
    )
