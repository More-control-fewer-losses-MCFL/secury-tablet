"""Identidade visual do app (CSS global e componentes HTML inspirados na Agenda SaaS).

Só aparência: nenhuma regra de negócio e nenhum acesso a serviços aqui.
Paleta inspirada na agenda de referência: barra roxa em degradê, fundo cinza claro,
sidebar rica com avatar, cards brancos e blocos coloridos por situação na grade semanal.
"""

from collections.abc import Iterable
from html import escape
from pathlib import Path

import streamlit as st

PURPLE = "#7e48b8"
PURPLE_DARK = "#8737b2"
PURPLE_SOFT = "#7661bc"
LAVENDER = "#cfacfe"
BLUE = "#086eb9"
GREEN = "#018323"
RED = "#ff5b42"
PINK = "#fddfeb"

# situação -> (rótulo, cor do bloco, cor do texto)
TABLET_STATUS = {
    "AVAILABLE": ("Disponível", GREEN, "#ffffff"),
    "CHECKED_OUT": ("Emprestado", RED, "#ffffff"),
    "MAINTENANCE": ("Manutenção", LAVENDER, "#3b1f66"),
}

SESSION_STATUS = {
    "PENDING": ("Pendente",),
    "UNLOCKED": ("Destravado",),
    "OPEN": ("Em uso",),
    "DIVERGENT": ("Divergente",),
    "COMPLETED": ("Concluída",),
    "CANCELLED": ("Cancelada",),
    "FAILED": ("Falhou",),
}

_CSS_FILE = Path(__file__).with_name("theme.css")


def apply_theme() -> None:
    """Injeta o CSS global, topbar e botão flutuante de chat."""
    css = _CSS_FILE.read_text(encoding="utf-8")
    st.markdown(f"<style>{css}</style>", unsafe_allow_html=True)
    render_topbar()
    render_floating_chat()


def render_topbar() -> None:
    """Barra superior roxa com logotipo, ícones e badges idênticos à imagem de referência."""
    st.markdown(
        """
        <div class="sc-topbar-custom">
            <div class="sc-topbar-left">
                <div class="sc-topbar-logo">
                    <span>〰️</span>
                    <span>SecurityTablet</span>
                </div>
                <div class="sc-topbar-icons">
                    <div class="sc-topbar-icon-btn">
                        <span>🔍</span>
                    </div>
                    <div class="sc-topbar-icon-btn">
                        <span>🩺</span>
                        <span class="sc-topbar-badge-red">10</span>
                    </div>
                    <div class="sc-topbar-icon-btn">
                        <span>❤️</span>
                        <span class="sc-topbar-badge-red">1</span>
                    </div>
                    <div class="sc-topbar-icon-btn">
                        <span>📁</span>
                        <span class="sc-topbar-badge-red">4</span>
                    </div>
                    <div class="sc-topbar-icon-btn">
                        <span>👥</span>
                        <span class="sc-topbar-badge-red">0</span>
                    </div>
                </div>
            </div>
            <div class="sc-topbar-icons">
                <div class="sc-topbar-icon-btn" style="background: rgba(255,255,255,0.22);">
                    <span>ARM-01 • Online</span>
                </div>
                <div class="sc-topbar-icon-btn">
                    <span>🔔</span>
                    <span class="sc-topbar-badge-red">1</span>
                </div>
                <div class="sc-topbar-icon-btn">
                    <span>⚙️</span>
                </div>
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def render_floating_chat() -> None:
    """Botão flutuante roxo com ícone de mensagem no canto da tela."""
    st.markdown(
        """
        <div class="sc-floating-chat" title="Suporte do Armário">
            💬
        </div>
        """,
        unsafe_allow_html=True,
    )


def render_sidebar_profile(available: int = 10, in_use: int = 0, divergences: int = 0) -> None:
    """Card de operador na barra lateral com foto circular, botões azuis e métricas compactas."""
    with st.sidebar:
        st.markdown(
            f"""
            <div class="sc-side-profile">
                <img src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80" 
                     class="sc-side-avatar" alt="Operador" />
                <div class="sc-side-name">Marcio Hernandez</div>
                <div class="sc-side-sub">Coordenação SENAI • ARM-01</div>
                
                <a class="sc-side-btn" href="#">Lista de Espera</a>
                <a class="sc-side-btn" href="#">Observações</a>
                <a class="sc-side-btn" href="#">Relatório de Uso</a>
                
                <div class="sc-side-stats">
                    <div class="sc-side-stat-box">
                        <div class="sc-side-stat-val">{available}</div>
                        <div class="sc-side-stat-lbl">Disponíveis</div>
                    </div>
                    <div class="sc-side-stat-box">
                        <div class="sc-side-stat-val" style="color: #086eb9;">{in_use}</div>
                        <div class="sc-side-stat-lbl">Em Uso</div>
                    </div>
                    <div class="sc-side-stat-box">
                        <div class="sc-side-stat-val" style="color: #018323;">4</div>
                        <div class="sc-side-stat-lbl">Professores</div>
                    </div>
                    <div class="sc-side-stat-box">
                        <div class="sc-side-stat-val" style="color: #ff5b42;">{divergences}</div>
                        <div class="sc-side-stat-lbl">Divergências</div>
                    </div>
                </div>
            </div>

            <div class="sc-queue-header">
                <span>Sala de espera</span>
                <span style="font-size: 0.75rem; color: #7e48b8; cursor: pointer;">Ver todos</span>
            </div>

            <div class="sc-queue-item">
                <div class="sc-queue-avatar" style="background: #e91e63;">AB</div>
                <div class="sc-queue-info">
                    <div class="sc-queue-name">Ana Maria Silva</div>
                    <div class="sc-queue-time">🕒 09:30 • TAB-001</div>
                </div>
                <div class="sc-queue-badge sc-queue-badge-blue">Em aula</div>
            </div>

            <div class="sc-queue-item">
                <div class="sc-queue-avatar" style="background: #2e7d32;">BC</div>
                <div class="sc-queue-info">
                    <div class="sc-queue-name">Bruno Costa</div>
                    <div class="sc-queue-time">🕒 10:15 • TAB-002</div>
                </div>
                <div class="sc-queue-badge sc-queue-badge-green">Liberado</div>
            </div>

            <div class="sc-queue-item">
                <div class="sc-queue-avatar" style="background: #7b1fa2;">CD</div>
                <div class="sc-queue-info">
                    <div class="sc-queue-name">Carla Dias</div>
                    <div class="sc-queue-time">🕒 11:00 • TAB-003</div>
                </div>
                <div class="sc-queue-badge sc-queue-badge-red">Pendente</div>
            </div>
            """,
            unsafe_allow_html=True,
        )


def page_header(title: str, subtitle: str | None = None, chip: str | None = None) -> None:
    """Cabeçalho da página (substitui st.title)."""
    sub = f"<p>{escape(subtitle)}</p>" if subtitle else ""
    tag = f'<span class="sc-chip">{escape(chip)}</span>' if chip else ""
    st.markdown(
        f'<div class="sc-header"><div><h2>{escape(title)}</h2>{sub}</div>{tag}</div>',
        unsafe_allow_html=True,
    )


def render_agenda_grid(tablets: list[dict]) -> None:
    """Renderiza a Grade de Agenda Semanal com blocos coloridos idêntica à imagem de referência."""
    st.markdown(
        """
        <div class="sc-agenda-toolbar">
            <div class="sc-agenda-toolbar-left">
                <button class="sc-agenda-btn-pill">Hoje</button>
                <button class="sc-agenda-btn-pill" style="color: #555;">Semana ▾</button>
            </div>
            <div class="sc-agenda-date-nav">
                <span>◀</span>
                <span>Semana • 2 - 8 de Outubro, 2026</span>
                <span>▶</span>
            </div>
            <div class="sc-agenda-toolbar-right">
                <button class="sc-agenda-btn-pill">🔍</button>
                <button class="sc-agenda-btn-new">+ Nova Retirada</button>
                <button class="sc-agenda-btn-pill" style="color: #555;">Configurar</button>
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    # Monta a tabela de grade semanal com blocos coloridos preenchidos
    st.markdown(
        """
        <table class="sc-agenda-table">
            <thead>
                <tr>
                    <th style="width: 70px;">Horário</th>
                    <th>SEG 2/1</th>
                    <th>TER 3/1</th>
                    <th>QUA 4/1</th>
                    <th>QUI 5/1</th>
                    <th>SEX 6/1</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td class="sc-agenda-time-col">08:00</td>
                    <td>
                        <div class="sc-event-block ev-green">
                            <b>DISPONÍVEL • TAB-001</b>
                            <span>CD - Ana Maria da Silva</span>
                            <span>08:00 - 09:30 • No Armário</span>
                        </div>
                    </td>
                    <td>
                        <div class="sc-event-block ev-red">
                            <b>PARTICULAR • 08:00 - 09:30</b>
                            <span>CD - Gabriela dos Santos</span>
                            <span>TAB-004 • Em aula</span>
                        </div>
                    </td>
                    <td>
                        <div class="sc-event-block ev-red">
                            <b>MANUTENÇÃO • 08:00 - 09:30</b>
                            <span>CD - Claudine Freitas</span>
                        </div>
                    </td>
                    <td></td>
                    <td>
                        <div class="sc-event-block ev-pink">
                            <b>AULA • 08:00 - 09:30</b>
                            <span>CD - Kelly Ferreira</span>
                        </div>
                    </td>
                </tr>
                <tr>
                    <td class="sc-agenda-time-col">09:30</td>
                    <td>
                        <div class="sc-event-block ev-pink">
                            <b>CENTRAL NACIONAL • 09:30</b>
                            <span>RE - Ana Paula dos Santos</span>
                        </div>
                    </td>
                    <td>
                        <div class="sc-event-block ev-blue">
                            <b>EM USO • 09:30 - 10:30</b>
                            <span>PA - Evandro Martins</span>
                            <span>TAB-002 • Robótica 9A</span>
                        </div>
                    </td>
                    <td>
                        <div class="sc-event-block ev-pink">
                            <b>DISPENSADA • 09:30 - 10:30</b>
                            <span>RE - Vanda Mendonça</span>
                        </div>
                    </td>
                    <td>
                        <div class="sc-event-block ev-red">
                            <b>DIVERGÊNCIA • 09:30 - 10:30</b>
                            <span>CD - Gustavo Schneider</span>
                            <span>TAB-005 • Pendente</span>
                        </div>
                    </td>
                    <td>
                        <div class="sc-event-block ev-red">
                            <b>PARTICULAR • 09:45 - 10:45</b>
                            <span>CD - Leticia Oliveira</span>
                        </div>
                    </td>
                </tr>
                <tr>
                    <td class="sc-agenda-time-col">11:00</td>
                    <td>
                        <div class="sc-event-block ev-blue">
                            <b>EM USO • 10:00 - 11:30</b>
                            <span>PA - Bruno da Silva</span>
                            <span>TAB-003 • Sala Multimídia</span>
                        </div>
                    </td>
                    <td>
                        <div class="sc-event-block ev-red">
                            <b>RESERVA • 10:30 - 11:30</b>
                            <span>CD - Bruna</span>
                        </div>
                    </td>
                    <td>
                        <div class="sc-event-block ev-pink">
                            <b>PARTICULAR • 11:00 - 11:45</b>
                            <span>PA - Andréia Pacheco</span>
                        </div>
                    </td>
                    <td>
                        <div class="sc-event-block ev-blue">
                            <b>EM USO • 10:30 - 11:30</b>
                            <span>PA - Gabriela dos Anjos</span>
                            <span>TAB-006 • Mecânica</span>
                        </div>
                    </td>
                    <td>
                        <div class="sc-event-block ev-pink">
                            <b>CENTRAL • 11:00 - 11:45</b>
                            <span>PA - Ana Paula dos Santos</span>
                        </div>
                    </td>
                </tr>
                <tr>
                    <td class="sc-agenda-time-col">12:00</td>
                    <td>
                        <div class="sc-event-block ev-red">
                            <b>RETIRADA • 11:30 - 12:30</b>
                            <span>CD - Antonio Pacheco</span>
                        </div>
                        <div class="sc-event-block ev-pink">
                            <b>RESERVA • 12:00 - 12:30</b>
                            <span>CD - Carolina dos Reis</span>
                        </div>
                    </td>
                    <td>
                        <div class="sc-event-block ev-green">
                            <b>DISPONÍVEL • TAB-007</b>
                            <span>08:00 às 18:00 • Armário 01</span>
                        </div>
                    </td>
                    <td>
                        <div class="sc-event-block ev-red">
                            <b>PARTICULAR • 12:00 - 12:30</b>
                            <span>CD - Maria Andrade</span>
                        </div>
                    </td>
                    <td>
                        <div class="sc-event-block ev-purple">
                            <b>AGENDADO • 11:30 - 12:30</b>
                            <span>CD - Fernando Bahe</span>
                        </div>
                    </td>
                    <td>
                        <div class="sc-event-block ev-red">
                            <b>PARTICULAR • 11:45 - 12:45</b>
                            <span>CD - Jandira Ferreira</span>
                        </div>
                    </td>
                </tr>
            </tbody>
        </table>
        """,
        unsafe_allow_html=True,
    )


def tablet_grid(tablets: Iterable[tuple[str, str]]) -> None:
    """Grade de blocos coloridos; cada item é (código do patrimônio, situação)."""
    tiles = []
    for code, status in tablets:
        label, bg, fg = TABLET_STATUS.get(status, (status, "#e6e6ee", "#2b2b3a"))
        tiles.append(
            f'<div class="sc-tile" style="background:{bg};color:{fg}">'
            f"<b>{escape(code)}</b><span>{escape(label)}</span></div>"
        )
    if not tiles:
        st.caption("Nenhum tablet para mostrar.")
        return
    legend = "".join(
        f'<span><i style="background:{bg}"></i>{label}</span>'
        for label, bg, _ in TABLET_STATUS.values()
    )
    st.markdown(
        f'<div class="sc-legend">{legend}</div><div class="sc-grid">{"".join(tiles)}</div>',
        unsafe_allow_html=True,
    )
