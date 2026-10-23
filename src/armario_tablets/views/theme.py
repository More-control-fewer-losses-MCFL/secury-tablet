"""Tema visual e componentes de renderização HTML do Tablet de Segurança.

Todas as funções que geram HTML estão aqui.  As *views* apenas chamam
estas funções passando dados já processados.  Nenhum import de serviço
ou modelo é feito — o módulo é puramente de apresentação.
"""

from __future__ import annotations

import html as html_lib
from pathlib import Path

import streamlit as st

# ── Cores ────────────────────────────────────────────────────────────────
PRIMARY = "#0B58B5"
PRIMARY_DARK = "#073B83"
PRIMARY_LIGHT = "#2478D4"
ACCENT = "#45B8F4"
SUCCESS = "#4CAF50"
WARNING = "#FF9800"
DANGER = "#F44336"
INFO = "#2196F3"

# ── Mapeamentos de status ────────────────────────────────────────────────
# (label_pt, bg_color, text_color)
TABLET_STATUS: dict[str, tuple[str, str, str]] = {
    "AVAILABLE": ("Disponível", "#E8F5E9", "#2E7D32"),
    "CHECKED_OUT": ("Emprestado", "#FFF3E0", "#E65100"),
    "MAINTENANCE": ("Manutenção", "#ECEFF1", "#546E6F"),
}

# (label_pt,)
SESSION_STATUS: dict[str, tuple[str]] = {
    "PENDING": ("Pendente",),
    "UNLOCKED": ("Destravado",),
    "OPEN": ("Em andamento",),
    "DIVERGENT": ("Divergente",),
    "COMPLETED": ("Concluído",),
    "CANCELLED": ("Cancelado",),
    "FAILED": ("Falhou",),
}

# Badge CSS class por tipo de evento
_EVENT_BADGE: dict[str, str] = {
    "Retirada": "sc-badge-primary",
    "Devolução": "sc-badge-success",
    "Identificação": "sc-badge-info",
    "Erro": "sc-badge-danger",
    "Alerta": "sc-badge-warning",
}

_STATUS_BADGE: dict[str, str] = {
    "Concluído": "sc-badge-success",
    "Pendente": "sc-badge-warning",
    "Falha": "sc-badge-danger",
    "Falhou": "sc-badge-danger",
    "Em andamento": "sc-badge-info",
    "Divergente": "sc-badge-warning",
    "Destravado": "sc-badge-info",
    "Cancelado": "sc-badge-neutral",
}


# ── Tema ─────────────────────────────────────────────────────────────────


def apply_theme() -> None:
    """Injeta o CSS personalizado e renderiza a barra superior."""
    css_path = Path(__file__).parent / "theme.css"
    css = css_path.read_text(encoding="utf-8")
    st.markdown(f"<style>{css}</style>", unsafe_allow_html=True)
    _render_topbar()


def _render_topbar() -> None:
    """Barra superior com busca interativa e estado real da fonte de dados."""
    data_status = st.session_state.get("database_connected")
    rfid_status = st.session_state.get("rfid_connected")
    notif_count = st.session_state.get("notification_count", 0)

    if data_status is True:
        data_html = '<span class="sc-topbar-pill"><span class="dot green"></span>Banco</span>'
    elif data_status is False:
        data_html = '<span class="sc-topbar-pill"><span class="dot red"></span>Banco</span>'
    else:
        data_html = '<span class="sc-topbar-pill"><span class="dot gray"></span>Banco N/D</span>'

    if rfid_status is True:
        rfid_html = '<span class="sc-topbar-pill"><span class="dot green"></span>RFID</span>'
    elif rfid_status is False:
        rfid_html = '<span class="sc-topbar-pill"><span class="dot red"></span>RFID</span>'
    else:
        rfid_html = (
            '<span class="sc-topbar-pill"><span class="dot yellow"></span>RFID simulado</span>'
        )

    badge_html = f'<span class="sc-topbar-badge">{notif_count}</span>' if notif_count else ""
    with st.container(key="sc-topbar-container"):
        brand, search, status = st.columns([2, 4, 3], vertical_alignment="center")
        brand.markdown(
            '<div class="sc-topbar-brand"><span class="brand-icon">🛡️</span>'
            "Tablet de Segurança</div>",
            unsafe_allow_html=True,
        )
        search.text_input(
            "Busca global",
            key="global_search",
            placeholder="Buscar professor, ID RFID ou patrimônio",
            label_visibility="collapsed",
        )
        status.markdown(
            f'<div class="sc-topbar-right">{data_html}{rfid_html}'
            f'<a class="sc-topbar-icon" href="/Historico" aria-label="Notificações">'
            f"🔔{badge_html}</a>"
            '<a class="sc-topbar-icon" href="/Configuracoes" aria-label="Configurações">⚙️</a>'
            "</div>",
            unsafe_allow_html=True,
        )


# ── Sidebar ──────────────────────────────────────────────────────────────


def render_sidebar_status(
    *,
    simulated: bool = True,
    api_ok: bool | None = None,
    last_update: str = "",
) -> None:
    """Card de status no rodapé do sidebar."""
    sim_label = "Simulado" if simulated else "Não configurado"
    sim_dot = "yellow" if simulated else "gray"

    if api_ok is True:
        data_label, data_dot = "Conectado", "green"
    elif api_ok is False:
        data_label, data_dot = "Desconectado", "red"
    else:
        data_label, data_dot = "Não verificado", "gray"

    ts = html_lib.escape(last_update or "—")
    html = (
        '<div class="sc-sidebar-status">'
        '<div class="status-title">Status do Sistema</div>'
        f'<div class="status-row"><span class="dot" style="background:{_dot_color(sim_dot)}">'
        f"</span>Hardware: {sim_label}</div>"
        f'<div class="status-row"><span class="dot" style="background:{_dot_color(data_dot)}">'
        f"</span>Banco local: {data_label}</div>"
        '<div class="status-row" style="font-size:0.72rem;opacity:0.6;margin-top:4px;">'
        f"Atualizado: {ts}</div></div>"
    )
    with st.sidebar:
        st.html(html)


def _dot_color(name: str) -> str:
    return {"green": SUCCESS, "red": DANGER, "yellow": WARNING, "gray": "#9E9E9E"}.get(
        name, "#9E9E9E"
    )


# ── Page Header ──────────────────────────────────────────────────────────


def page_header(title: str, subtitle: str = "", chip: str | None = None) -> None:
    """Cabeçalho de página com título, subtítulo e chip opcional."""
    chip_html = f'<span class="sc-chip">{html_lib.escape(chip)}</span>' if chip else ""
    sub_html = f"<p>{html_lib.escape(subtitle)}</p>" if subtitle else ""
    st.html(
        f'<div class="sc-page-header"><h1>{html_lib.escape(title)} {chip_html}</h1>{sub_html}</div>'
    )


# ── Banner ───────────────────────────────────────────────────────────────


def render_banner(
    title: str = "Bem-vindo ao\nTablet de Segurança",
    subtitle: str = (
        "Gerencie a retirada e a devolução de tablets por professores identificados por RFID"
    ),
    cabinet_status: dict | None = None,
    last_rfid: str | None = None,
    hardware_simulated: bool = True,
    data_connected: bool | None = None,
) -> None:
    """Banner principal com o estado real dos dados e do armário."""
    title_html = "<br>".join(html_lib.escape(line) for line in title.splitlines())
    data_dot = (
        "green" if data_connected is True else "red" if data_connected is False else "gray"
    )
    data_label = (
        "Conectados"
        if data_connected is True
        else "Indisponíveis"
        if data_connected is False
        else "Não verificados"
    )
    data_row = (
        f'<div class="cab-row"><span class="dot" style="background:{_dot_color(data_dot)}">'
        f"</span>Dados locais: {data_label}</div>"
    )

    if cabinet_status and hardware_simulated:
        door_state = cabinet_status.get("door_state", "UNKNOWN")
        lock_state = cabinet_status.get("lock_state", "UNKNOWN")
        door_labels = {"CLOSED": "Fechada", "OPEN": "Aberta"}
        lock_labels = {"LOCKED": "Travada", "UNLOCKED": "Destravada"}
        door_label = door_labels.get(door_state, "Indisponível")
        lock_label = lock_labels.get(lock_state, "Indisponível")
        door_dot = "green" if door_state == "CLOSED" else "red" if door_state == "OPEN" else "gray"
        lock_dot = (
            "green" if lock_state == "LOCKED" else "red" if lock_state == "UNLOCKED" else "gray"
        )
        cab_rows = (
            f"{data_row}"
            f'<div class="cab-row"><span class="dot" style="background:{_dot_color(door_dot)}">'
            f"</span>Porta simulada: {door_label}</div>"
            f'<div class="cab-row"><span class="dot" style="background:{_dot_color(lock_dot)}">'
            f"</span>Fechadura simulada: {lock_label}</div>"
            f'<div class="cab-row"><span class="dot" style="background:{WARNING}">'
            "</span>Leitor RFID: Simulado</div>"
        )
    else:
        cab_rows = (
            f"{data_row}"
            '<div class="cab-row"><span class="dot" style="background:#9E9E9E"></span>'
            "Estado do armário: N/D</div>"
            '<div class="cab-row"><span class="dot" style="background:#9E9E9E"></span>'
            "Hardware RFID: não configurado</div>"
        )

    rfid_info = (
        f"Última leitura simulada: {html_lib.escape(last_rfid)}"
        if last_rfid
        else "Nenhuma leitura RFID nesta sessão"
    )

    html = f"""
    <div class="sc-banner">
        <div class="sc-banner-left">
            <span class="greeting">Olá,</span>
            <h2>{title_html}</h2>
            <span class="subtitle">{html_lib.escape(subtitle)}</span>
        </div>
        <div class="sc-banner-right">
            <div class="sc-banner-illustration">🗄️</div>
            <div class="sc-cabinet-card">
                <div class="cab-title">Status do Armário</div>
                {cab_rows}
                <div class="cab-rfid">{rfid_info}</div>
            </div>
        </div>
    </div>
    """
    st.html(html)


# ── Metric Cards ─────────────────────────────────────────────────────────


def render_metric_cards(metrics: list[dict]) -> None:
    """Linha de cards de indicadores.

    Cada dict: ``{icon, title, value, color, change?}``
    """
    cards_html = ""
    for m in metrics:
        color = m.get("color", PRIMARY)
        # cor de fundo suave para o ícone
        r, g, b = int(color[1:3], 16), int(color[3:5], 16), int(color[5:7], 16)
        bg = f"rgba({r},{g},{b},0.10)"

        change_html = ""
        if change := m.get("change"):
            cls = "up" if change.startswith("+") else "down"
            arrow = "↑" if cls == "up" else "↓"
            change_html = (
                f'<div class="sc-metric-change {cls}">{arrow} {html_lib.escape(str(change))}</div>'
            )

        cards_html += f"""
        <div class="sc-metric-card" style="--metric-color:{color};--metric-bg:{bg}">
            <div class="sc-metric-icon" style="background:{bg}">
                {html_lib.escape(str(m["icon"]))}
            </div>
            <div class="sc-metric-content">
                <div class="sc-metric-title">{html_lib.escape(str(m["title"]))}</div>
                <div class="sc-metric-value">{html_lib.escape(str(m["value"]))}</div>
                {change_html}
            </div>
        </div>
        """
    st.html(f'<div class="sc-metrics-row">{cards_html}</div>')


# ── Movements Table ──────────────────────────────────────────────────────


def render_movements_table(movements: list[dict], title: str = "Últimas movimentações") -> None:
    """Tabela estilizada de movimentações recentes.

    Cada dict: ``{time, professor, badge_id, event_type, tablet, status}``
    """
    if not movements:
        st.html(
            '<div class="sc-card"><div class="sc-empty">'
            '<div class="empty-icon">📋</div>Nenhuma movimentação registrada</div></div>'
        )
        return

    rows_html = ""
    for m in movements:
        evt_cls = _EVENT_BADGE.get(m.get("event_type", ""), "sc-badge-neutral")
        sts_cls = _STATUS_BADGE.get(m.get("status", ""), "sc-badge-neutral")
        rows_html += f"""
        <tr>
            <td>{html_lib.escape(str(m.get("time", "")))}</td>
            <td><span class="sc-badge {evt_cls}">{
            html_lib.escape(str(m.get("event_type", "")))
        }</span></td>
            <td>{html_lib.escape(str(m.get("professor", "")))}</td>
            <td>{html_lib.escape(str(m.get("badge_id", "—")))}</td>
            <td>{html_lib.escape(str(m.get("tablet", "—")))}</td>
            <td><span class="sc-badge {sts_cls}">{
            html_lib.escape(str(m.get("status", "")))
        }</span></td>
        </tr>"""

    html = f"""
    <div class="sc-card">
        <div class="sc-card-header">
            <h3>📋 {html_lib.escape(title)}</h3>
        </div>
        <table class="sc-movements-table">
            <thead>
                <tr>
                    <th>Horário</th>
                    <th>Evento</th>
                    <th>Professor</th>
                    <th>ID / matrícula</th>
                    <th>Tablet</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>{rows_html}</tbody>
        </table>
    </div>
    """
    st.html(html)


# ── Notifications Panel ──────────────────────────────────────────────────


def render_notifications_panel(notifications: list[dict]) -> None:
    """Painel de avisos e notificações.

    Cada dict: ``{type, message, time}`` — *type* ∈ success/warning/error/info
    """
    if not notifications:
        items_html = '<div class="sc-empty">Nenhum aviso no momento</div>'
    else:
        items_html = ""
        for n in notifications:
            notif_type = n.get("type", "info")
            if notif_type not in {"success", "warning", "error", "info"}:
                notif_type = "info"
            items_html += f"""
            <div class="sc-notif-item">
                <span class="sc-notif-dot {notif_type}"></span>
                <span class="sc-notif-text">{html_lib.escape(str(n["message"]))}</span>
                <span class="sc-notif-time">{html_lib.escape(str(n.get("time", "")))}</span>
            </div>"""

    html = f"""
    <div class="sc-card">
        <div class="sc-card-header">
            <h3>🔔 Avisos e Notificações</h3>
        </div>
        {items_html}
    </div>
    """
    st.html(html)


# ── Quick Actions ────────────────────────────────────────────────────────


def render_quick_actions(actions: list[dict]) -> None:
    """Cards de ações rápidas.

    Cada dict: ``{icon, title, description}``
    """
    cards_html = ""
    for a in actions:
        href = a.get("href", "")
        if href not in {"/Solicitar_Tablets", "/Devolucao", "/Tablets", "/Historico"}:
            continue
        cards_html += f"""
        <a class="sc-action-card" href="{href}">
            <span class="action-icon">{a["icon"]}</span>
            <div class="action-title">{html_lib.escape(a["title"])}</div>
            <div class="action-desc">{html_lib.escape(a["description"])}</div>
        </a>"""
    st.html(f'<div class="sc-quick-actions">{cards_html}</div>')


# ── Usage Chart (CSS-only donut) ─────────────────────────────────────────


def render_usage_chart(
    total: int,
    available: int,
    checked_out: int,
    maintenance: int,
) -> None:
    """Card de uso dos tablets com gráfico de rosca via CSS conic-gradient."""
    if total == 0:
        pct_avail = pct_out = pct_maint = 0
    else:
        pct_out = round(checked_out / total * 100, 1)
        pct_maint = round(maintenance / total * 100, 1)
        pct_avail = round(100 - pct_out - pct_maint, 1)

    # Ângulos para conic-gradient
    a1 = pct_out
    a2 = a1 + pct_avail

    gradient = f"conic-gradient({PRIMARY} 0% {a1}%, {SUCCESS} {a1}% {a2}%, #B0BEC5 {a2}% 100%)"
    mask = "radial-gradient(farthest-side, transparent calc(100% - 22px), #fff calc(100% - 21px))"
    donut = (
        f'<div class="sc-donut" style="background:{gradient};'
        f'-webkit-mask:{mask};mask:{mask};"></div>'
    )

    html = f"""
    <div class="sc-card sc-usage-card">
        <div class="sc-card-header">
            <h3>📊 Uso dos Tablets</h3>
        </div>
        <div class="sc-donut-container">
            {donut}
            <div class="sc-donut-center">
                <span class="sc-donut-number">{total}</span>
                <span class="sc-donut-label">Tablets</span>
            </div>
        </div>
        <div class="sc-usage-legend">
            <div class="sc-legend-item">
                <span class="legend-left"><span class="legend-dot" style="background:{PRIMARY}">
                </span>Em uso</span>
                <span>{checked_out}</span>
                <span class="legend-pct">{pct_out}%</span>
            </div>
            <div class="sc-legend-item">
                <span class="legend-left"><span class="legend-dot" style="background:{SUCCESS}">
                </span>Disponíveis</span>
                <span>{available}</span>
                <span class="legend-pct">{pct_avail}%</span>
            </div>
            <div class="sc-legend-item">
                <span class="legend-left"><span class="legend-dot" style="background:#B0BEC5">
                </span>Manutenção</span>
                <span>{maintenance}</span>
                <span class="legend-pct">{pct_maint}%</span>
            </div>
        </div>
    </div>
    """
    st.html(html)


# ── Tablet Grid ──────────────────────────────────────────────────────────


def tablet_grid(tablets) -> None:
    """Grade de tiles coloridos para cada tablet.

    *tablets* — iterável de ``(asset_code, status)``
    """
    tiles_list = list(tablets)
    if not tiles_list:
        st.html(
            '<div class="sc-card"><div class="sc-empty">'
            '<div class="empty-icon">📱</div>Nenhum tablet cadastrado</div></div>'
        )
        return

    tiles_html = ""
    for code, status in tiles_list:
        label, bg, fg = TABLET_STATUS.get(status, (status, "#ECEFF1", "#546E6F"))
        tiles_html += (
            f'<div class="sc-tile" style="background:{bg};color:{fg}">'
            f'<div class="tile-code">{html_lib.escape(str(code))}</div>'
            f'<div class="tile-status">{html_lib.escape(str(label))}</div>'
            f"</div>"
        )

    legend_html = ""
    for _status, (lbl, bg, fg) in TABLET_STATUS.items():
        legend_html += (
            f'<div class="sc-grid-legend-item">'
            f'<span class="swatch" style="background:{bg};border:1px solid {fg}"></span>{lbl}</div>'
        )

    st.html(
        f'<div class="sc-tablet-grid">{tiles_html}</div>'
        f'<div class="sc-grid-legend">{legend_html}</div>'
    )


# ── Simulation Warning ──────────────────────────────────────────────────


def render_simulation_warning() -> None:
    """Banner de aviso de modo simulado."""
    st.html(
        '<div class="sc-sim-banner">'
        '<span class="sim-icon">⚠️</span>'
        "<span>Modo Simulado — Leitores RFID e fechadura estão em modo simulado. "
        "Nenhum hardware real está conectado.</span>"
        "</div>"
    )


# ── Utilitário: badge inline ────────────────────────────────────────────


def status_badge(text: str, variant: str = "neutral") -> str:
    """Retorna HTML de badge (não renderiza — use dentro de outro componente)."""
    cls = f"sc-badge-{variant}" if variant != "neutral" else "sc-badge-neutral"
    return f'<span class="sc-badge {cls}">{html_lib.escape(text)}</span>'
