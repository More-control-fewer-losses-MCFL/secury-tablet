"""View Configurações — informações do sistema e variáveis de ambiente."""

from __future__ import annotations

import streamlit as st

from armario_tablets.config import get_settings
from armario_tablets.views.common import (
    friendly_error,
    record_database_status,
    services_scope,
)
from armario_tablets.views.theme import (
    page_header,
    render_sidebar_status,
)


def render() -> None:
    settings = get_settings()
    simulated = settings.hardware_simulated
    render_sidebar_status(simulated=simulated, api_ok=st.session_state.get("database_connected"))

    page_header(
        "Configurações",
        "Informações do sistema, status das integrações e variáveis de ambiente.",
    )

    # ── Status do Sistema ────────────────────────────────────────────
    st.markdown(
        '<div class="sc-card"><div class="sc-card-header">'
        "<h3>🔧 Status do Sistema</h3></div></div>",
        unsafe_allow_html=True,
    )

    col1, col2 = st.columns(2)

    with col1:
        st.subheader("Banco de Dados")
        try:
            with services_scope() as services:
                # Tenta uma operação simples para verificar a conexão
                services.professors.list_all()
            st.success("✅ Conexão com o banco de dados ativa.", icon=":material/check_circle:")
            record_database_status(True)
        except Exception as err:
            st.error(f"❌ Falha na conexão: {friendly_error(err)}")
            record_database_status(False)

    with col2:
        st.subheader("Hardware")
        if simulated:
            st.warning(
                "⚠️ Modo simulado ativo. Leitores RFID e fechaduras não estão conectados.",
                icon=":material/warning:",
            )
        else:
            st.info(
                "Hardware real configurado, porém nenhum adaptador de hardware real "
                "foi implementado neste momento.",
                icon=":material/info:",
            )

    # ── Configurações Atuais ─────────────────────────────────────────
    st.divider()
    st.markdown(
        '<div class="sc-card"><div class="sc-card-header">'
        "<h3>⚙️ Configurações Atuais</h3></div></div>",
        unsafe_allow_html=True,
    )

    config_data = {
        "Código do Armário": settings.cabinet_code,
        "Hardware Simulado": "✅ Sim" if simulated else "❌ Não",
        "Timeout da Fechadura (s)": settings.lock_confirm_timeout_seconds,
        "TTL de Reserva (min)": settings.reservation_ttl_minutes,
        "Nível de Log": settings.log_level,
        "Host do Banco": settings.mysql_host,
        "Porta do Banco": settings.mysql_port,
        "Nome do Banco": settings.mysql_database,
        "Usuário do Banco": settings.mysql_user,
    }

    st.dataframe(
        [{"Configuração": k, "Valor": str(v)} for k, v in config_data.items()],
        hide_index=True,
        width="stretch",
    )

    st.caption(
        "ℹ️ As configurações são definidas por variáveis de ambiente "
        "ou pelo arquivo `.env`. Alterações requerem reinício da aplicação."
    )
    st.info(
        "A interface usa o banco MySQL local. Não há integração com Google Sheets configurada "
        "neste projeto; os estados RFID e de fechadura permanecem simulados. "
        "Se o banco foi preenchido por `scripts/seed_demo.py`, os cadastros são dados fictícios "
        "de demonstração."
    )

    # ── Sobre ────────────────────────────────────────────────────────
    st.divider()
    st.markdown(
        '<div class="sc-card"><div class="sc-card-header"><h3>ℹ️ Sobre o Sistema</h3></div></div>',
        unsafe_allow_html=True,
    )
    st.markdown(
        """
        **Tablet de Segurança** — Sistema de gerenciamento de tablets para
        instituições de ensino.

        - **Tecnologias:** Python, Streamlit, FastAPI, SQLAlchemy, MySQL
        - **Autenticação:** Crachá RFID
        - **Hardware:** Abstração com interfaces (simulação disponível)

        O sistema permite a retirada e devolução controlada de tablets
        por professores identificados via crachá RFID em um armário inteligente.
        """
    )
