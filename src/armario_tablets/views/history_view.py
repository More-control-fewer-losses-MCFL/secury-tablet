import streamlit as st

from armario_tablets.utils.datetime_utils import format_local
from armario_tablets.views.common import friendly_error, services_scope
from armario_tablets.views.theme import SESSION_STATUS, page_header, render_sidebar_profile

PAGE_SIZE = 20
STATUSES = ["Todos", "PENDING", "UNLOCKED", "OPEN", "DIVERGENT", "COMPLETED", "CANCELLED", "FAILED"]


def render() -> None:
    render_sidebar_profile()
    page_header("Histórico", "Retiradas anteriores.")
    filter_col, page_col, _ = st.columns([2, 1, 3])
    status = filter_col.selectbox("Situação", STATUSES)
    page_number = page_col.number_input("Página", min_value=1, value=1, step=1)

    try:
        with services_scope() as services:
            page = services.history.page(
                status=None if status == "Todos" else status,
                limit=PAGE_SIZE,
                offset=(int(page_number) - 1) * PAGE_SIZE,
            )
    except Exception as error:
        st.error(friendly_error(error))
        return

    pages = max(1, -(-page.total // PAGE_SIZE))
    st.caption(f"{page.total} registro(s) — página {int(page_number)} de {pages}")
    st.dataframe(
        [
            {
                "Solicitação": r.session_id,
                "Professor": r.professor_name,
                "Solicitados": r.requested_quantity,
                "Retirados": r.taken_quantity,
                "Pendentes": r.pending_quantity,
                "Finalidade": r.purpose,
                "Turma": r.class_name or "-",
                "Situação": SESSION_STATUS.get(r.status, (r.status,))[0],
                "Início": format_local(r.started_at),
                "Fim": format_local(r.completed_at),
            }
            for r in page.rows
        ],
        hide_index=True,
        width="stretch",
    )
