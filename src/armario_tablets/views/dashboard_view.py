import streamlit as st

from armario_tablets.utils.datetime_utils import format_local
from armario_tablets.views.common import friendly_error, services_scope

STATUS_LABELS = {
    "AVAILABLE": "Disponível",
    "CHECKED_OUT": "Emprestado",
    "MAINTENANCE": "Manutenção",
}


def render() -> None:
    st.title("Dashboard")
    try:
        with services_scope() as services:
            data = services.history.dashboard()
    except Exception as error:
        st.error(friendly_error(error))
        return

    total = sum(data["tablets_by_status"].values())
    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Disponíveis", data["available"])
    col2.metric("Total de tablets", total)
    col3.metric("Retiradas em uso", data["open_sessions"])
    col4.metric("Divergências", len(data["divergences"]))

    st.subheader("Tablets por situação")
    st.bar_chart(
        {STATUS_LABELS.get(k, k): v for k, v in data["tablets_by_status"].items()},
        horizontal=True,
    )

    st.subheader("Divergências em aberto")
    if not data["divergences"]:
        st.success("Nenhuma divergência.")
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
