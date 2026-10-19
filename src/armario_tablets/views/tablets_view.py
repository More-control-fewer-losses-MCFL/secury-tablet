import streamlit as st

from armario_tablets.utils.datetime_utils import format_local
from armario_tablets.views.common import friendly_error, services_scope


def render() -> None:
    st.title("Tablets")
    status = st.selectbox("Situação", ["Todas", "AVAILABLE", "CHECKED_OUT", "MAINTENANCE"])
    try:
        with services_scope() as services:
            tablets = services.tablets.list_all(None if status == "Todas" else status)
    except Exception as error:
        st.error(friendly_error(error))
        return
    st.dataframe(
        [
            {
                "Patrimônio": t.asset_code,
                "Situação": t.status,
                "Etiqueta RFID": "sim" if t.rfid_tag_uid else "não",
                "Atualizado em": format_local(t.updated_at),
            }
            for t in tablets
        ],
        hide_index=True,
        width="stretch",
    )
