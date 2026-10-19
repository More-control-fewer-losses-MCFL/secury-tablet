import uuid

import streamlit as st

from armario_tablets.config import get_settings
from armario_tablets.models import SessionStatus
from armario_tablets.views.common import friendly_error, services_scope


def render() -> None:
    st.title("Solicitar tablets")
    st.info(
        "Modo simulado: nenhuma fechadura real é acionada. Crachás de teste: "
        "DE000001, DE000002, DE000003 (ativos) e DE000900 (inativo)."
    )
    _render_request_form()
    session_id = st.session_state.get("checkout_session_id")
    if session_id:
        _render_simulation(session_id)


def _render_request_form() -> None:
    with services_scope() as services:
        available = services.availability.available_count()
    st.metric("Tablets disponíveis agora", available)

    with st.form("checkout_form"):
        badge_uid = st.text_input("UID do crachá (simula a leitura do cartão)")
        quantity = st.number_input("Quantidade", min_value=1, max_value=50, value=1, step=1)
        purpose = st.text_input("Finalidade de uso")
        class_name = st.text_input("Turma / disciplina (opcional)")
        submitted = st.form_submit_button("Validar e destravar armário")

    if not submitted:
        return
    try:
        with services_scope() as services:
            result = services.checkout.request_checkout(
                badge_uid,
                int(quantity),
                purpose.strip(),
                class_name.strip() or None,
                get_settings().cabinet_code,
            )
    except Exception as error:
        st.error(friendly_error(error))
        return
    st.session_state["checkout_session_id"] = result.session_id
    st.success(
        f"Armário destravado para {result.professor_name}. Solicitação #{result.session_id}."
    )


def _render_simulation(session_id: int) -> None:
    """Simula o que o controlador faria: porta fechada + leitura do inventário."""
    st.divider()
    st.subheader(f"Simulação do armário — solicitação #{session_id}")
    with services_scope() as services:
        current = services.checkout.get_result(session_id)
        available = services.tablets.list_available()

    if current.status != SessionStatus.UNLOCKED:
        st.write(f"Situação: **{current.status}** — retirados: {current.taken_quantity}.")
        for item in current.items:
            st.write(f"- {item.asset_code}")
        return

    st.write(
        f"Solicitados: **{current.requested_quantity}**. Escolha quais tablets saíram de fato."
    )
    options = {t.asset_code: t.rfid_tag_uid for t in available}
    removed = st.multiselect("Tablets retirados do armário", list(options))
    if st.button("Fechar porta e ler inventário (simulado)"):
        present = {tag for code, tag in options.items() if code not in removed}
        try:
            with services_scope() as services:
                result = services.checkout.confirm_checkout(
                    session_id, uuid.uuid4().hex, present, source="simulation"
                )
        except Exception as error:
            st.error(friendly_error(error))
            return
        st.success(f"Retirada registrada: {result.taken_quantity} tablet(s).")
        if result.divergence:
            st.warning(result.divergence)
