import uuid

import streamlit as st

from armario_tablets.models import ItemStatus
from armario_tablets.views.common import friendly_error, services_scope


def render() -> None:
    st.title("Devolução")
    with services_scope() as services:
        pending = services.returns.pending_returns()
        in_cabinet = services.tablets.list_available()

    if not pending:
        st.success("Nenhuma devolução pendente.")
        return

    labels = {
        f"#{p.session_id} — {p.professor_name} ({p.pending_quantity} pendente(s))": p
        for p in pending
    }
    chosen = labels[st.selectbox("Solicitação", list(labels))]
    expected = [i.asset_code for i in chosen.items if i.status == ItemStatus.ACTIVE]
    st.write("Tablets esperados:", ", ".join(expected))
    if chosen.divergence:
        st.warning(chosen.divergence)

    st.caption("Simulação: marque os tablets que foram colocados de volta no armário.")
    returned = st.multiselect("Tablets devolvidos", expected)

    if st.button("Ler inventário e conciliar (simulado)"):
        with services_scope() as services:
            codes = {t.asset_code: t.rfid_tag_uid for t in services.tablets.list_all()}
        present = {t.rfid_tag_uid for t in in_cabinet} | {codes[c] for c in returned}
        try:
            with services_scope() as services:
                result = services.returns.reconcile(
                    chosen.session_id, uuid.uuid4().hex, present, source="simulation"
                )
        except Exception as error:
            st.error(friendly_error(error))
            return
        if result.pending_quantity:
            st.warning(result.divergence)
        else:
            st.success("Todos os tablets foram devolvidos.")
