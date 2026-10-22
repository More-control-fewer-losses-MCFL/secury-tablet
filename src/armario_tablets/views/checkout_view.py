"""View Solicitar Tablets — fluxo de retirada com simulação RFID."""

from __future__ import annotations

import uuid

import streamlit as st

from armario_tablets.config import get_settings
from armario_tablets.models import SessionStatus
from armario_tablets.views.common import (
    friendly_error,
    record_database_status,
    services_scope,
)
from armario_tablets.views.theme import (
    page_header,
    render_sidebar_status,
    render_simulation_warning,
)


def render() -> None:
    settings = get_settings()
    simulated = settings.hardware_simulated

    render_sidebar_status(simulated=simulated, api_ok=st.session_state.get("database_connected"))
    page_header(
        "Solicitar Tablets",
        "Valide o crachá RFID do professor e registre a retirada de tablets.",
        chip="Simulação" if simulated else None,
    )

    if simulated:
        render_simulation_warning()
        st.info(
            "**Modo simulado:** nenhuma fechadura real é acionada. "
            "Crachás de teste disponíveis: `DE000001`, `DE000002`, `DE000003` (ativos) "
            "e `DE000900` (inativo).",
            icon=":material/info:",
        )

    _render_request_form(settings)

    session_id = st.session_state.get("checkout_session_id")
    if session_id:
        _render_simulation(session_id)


def _render_request_form(settings) -> None:
    """Formulário de solicitação de retirada."""
    # Mostrar disponibilidade atual
    try:
        with services_scope() as services:
            available = services.availability.available_count()
        record_database_status(True)
    except Exception as err:
        st.error(friendly_error(err))
        record_database_status(False)
        return

    st.metric("Tablets disponíveis agora", available)

    st.markdown(
        '<div class="sc-card"><div class="sc-card-header">'
        "<h3>🔓 Identificação e Retirada</h3></div></div>",
        unsafe_allow_html=True,
    )

    with st.form("checkout_form", clear_on_submit=False):
        st.caption(
            "⚠️ Este campo simula a leitura de um crachá RFID. "
            "Em produção, o UID será capturado automaticamente pelo leitor."
        )
        badge_uid = st.text_input(
            "UID do crachá (simulação da leitura RFID)",
            placeholder="Ex: DE000001",
        )
        quantity = st.number_input(
            "Quantidade de tablets",
            min_value=1,
            max_value=50,
            value=1,
            step=1,
        )
        purpose = st.text_input(
            "Finalidade de uso",
            placeholder="Ex: Aula de programação",
        )
        class_name = st.text_input(
            "Turma / disciplina (opcional)",
            placeholder="Ex: Turma A — Informática",
        )
        submitted = st.form_submit_button(
            "Validar e destravar armário",
            type="primary",
            width="stretch",
        )

    if not submitted:
        return

    if not badge_uid or not badge_uid.strip():
        st.warning("Informe o UID do crachá para continuar.")
        return

    if not purpose or not purpose.strip():
        st.warning("Informe a finalidade de uso.")
        return

    try:
        with services_scope() as services:
            result = services.checkout.request_checkout(
                badge_uid.strip(),
                int(quantity),
                purpose.strip(),
                class_name.strip() or None,
                settings.cabinet_code,
            )
    except Exception as err:
        st.error(friendly_error(err))
        return

    st.session_state["checkout_session_id"] = result.session_id
    st.session_state["last_rfid_read"] = badge_uid.strip()
    st.success(
        f"✅ Armário destravado para **{result.professor_name}**. "
        f"Solicitação **#{result.session_id}**."
    )


def _render_simulation(session_id: int) -> None:
    """Simula a leitura de inventário após fechamento da porta."""
    st.divider()
    st.markdown(
        f'<div class="sc-card"><div class="sc-card-header">'
        f"<h3>🗄️ Simulação do armário — solicitação #{session_id}</h3></div></div>",
        unsafe_allow_html=True,
    )
    st.caption(
        "⚠️ Esta etapa simula o que o controlador do armário faria: "
        "detectar quais tablets foram retirados após o fechamento da porta."
    )

    try:
        with services_scope() as services:
            current = services.checkout.get_result(session_id)
            available = services.tablets.list_available()
    except Exception as err:
        st.error(friendly_error(err))
        return

    if current.status != SessionStatus.UNLOCKED:
        st.write(f"Situação: **{current.status}** — retirados: {current.taken_quantity}.")
        if current.items:
            for item in current.items:
                st.write(f"- {item.asset_code}")
        if st.button("Nova solicitação"):
            st.session_state.pop("checkout_session_id", None)
            st.rerun()
        return

    st.write(
        f"Tablets solicitados: **{current.requested_quantity}**. "
        "Selecione quais foram fisicamente retirados."
    )
    options = {t.asset_code: t.rfid_tag_uid for t in available}
    removed = st.multiselect("Tablets retirados do armário (simulação)", list(options))

    if st.button("Fechar porta e ler inventário (simulado)", type="primary"):
        present = {tag for code, tag in options.items() if code not in removed}
        try:
            with services_scope() as services:
                result = services.checkout.confirm_checkout(
                    session_id,
                    uuid.uuid4().hex,
                    present,
                    source="simulation",
                )
        except Exception as err:
            st.error(friendly_error(err))
            return

        st.success(f"✅ Retirada registrada: **{result.taken_quantity}** tablet(s).")
        if result.divergence:
            st.warning(result.divergence)
