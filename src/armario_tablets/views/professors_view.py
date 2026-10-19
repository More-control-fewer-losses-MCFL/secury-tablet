import streamlit as st

from armario_tablets.utils.datetime_utils import format_local
from armario_tablets.utils.validators import mask_uid
from armario_tablets.views.common import friendly_error, services_scope


def render() -> None:
    st.title("Professores")
    st.caption("O UID do crachá aparece mascarado de propósito.")
    try:
        with services_scope() as services:
            professors = services.professors.list_all()
    except Exception as error:
        st.error(friendly_error(error))
        return
    st.dataframe(
        [
            {
                "Nome": p.name,
                "Matrícula": p.registration,
                "Crachá": mask_uid(p.badge_uid),
                "Ativo": "sim" if p.active else "não",
                "Cadastrado em": format_local(p.created_at),
            }
            for p in professors
        ],
        hide_index=True,
        width="stretch",
    )
