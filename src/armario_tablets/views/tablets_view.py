import streamlit as st

from armario_tablets.utils.datetime_utils import format_local
from armario_tablets.views.common import friendly_error, services_scope
from armario_tablets.views.theme import (
    TABLET_STATUS,
    page_header,
    render_sidebar_profile,
    tablet_grid,
)


def render() -> None:
    render_sidebar_profile()
    page_header("Tablets", "Patrimônio e situação de cada tablet do armário.")
    status_col, _ = st.columns([1, 3])
    status = status_col.selectbox("Situação", ["Todas", "AVAILABLE", "CHECKED_OUT", "MAINTENANCE"])
    try:
        with services_scope() as services:
            tablets = services.tablets.list_all(None if status == "Todas" else status)
    except Exception as error:
        st.error(friendly_error(error))
        return
    tablet_grid((t.asset_code, t.status) for t in tablets)
    st.write("")
    st.dataframe(
        [
            {
                "Patrimônio": t.asset_code,
                "Situação": TABLET_STATUS.get(t.status, (t.status,))[0],
                "Etiqueta RFID": "sim" if t.rfid_tag_uid else "não",
                "Atualizado em": format_local(t.updated_at),
            }
            for t in tablets
        ],
        hide_index=True,
        width="stretch",
    )
