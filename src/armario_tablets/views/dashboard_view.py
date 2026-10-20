import streamlit as st

from armario_tablets.utils.datetime_utils import format_local
from armario_tablets.views.common import friendly_error, services_scope
from armario_tablets.views.theme import (
    page_header,
    render_agenda_grid,
    render_sidebar_profile,
    tablet_grid,
)

STATUS_LABELS = {
    "AVAILABLE": "Disponível",
    "CHECKED_OUT": "Emprestado",
    "MAINTENANCE": "Manutenção",
}


def render() -> None:
    page_header(
        "Agenda do Armário",
        "Visão semanal de retiradas, ocupação e disponibilidade dos tablets.",
        chip="Semana Ativa",
    )
    try:
        with services_scope() as services:
            data = services.history.dashboard()
            all_tablets = services.tablets.list_all()
    except Exception as error:
        st.error(friendly_error(error))
        return

    # Renderiza o perfil lateral idêntico à imagem de referência
    render_sidebar_profile(
        available=data["available"],
        in_use=data["open_sessions"],
        divergences=len(data["divergences"]),
    )

    total = sum(data["tablets_by_status"].values())
    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Disponíveis", data["available"])
    col2.metric("Total no Armário", total)
    col3.metric("Em Uso na Aula", data["open_sessions"])
    col4.metric("Divergências", len(data["divergences"]))

    st.write("")

    # Grade da Agenda Semanal idêntica à imagem de referência
    render_agenda_grid(all_tablets)

    st.write("")
    st.subheader("Ocupação dos Tablets no Armário")
    tablet_grid([(t.asset_code, t.status) for t in all_tablets])

    st.write("")
    st.subheader("Divergências e Pendências")
    if not data["divergences"]:
        st.success("Nenhuma divergência em aberto no momento.", icon=":material/check_circle:")
        return
    st.dataframe(
        [
            {
                "Solicitação": r.session_id,
                "Professor": r.professor_name,
                "Retirados": r.taken_quantity,
                "Pendentes": r.pending_quantity,
                "Início": format_local(r.started_at),
            }
            for r in data["divergences"]
        ],
        hide_index=True,
        width="stretch",
    )
