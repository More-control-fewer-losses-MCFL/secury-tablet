"""Componentes de dados — transformam objetos do domínio em dicts para renderização.

Nenhum HTML é gerado aqui; este módulo apenas formata dados para que
as funções de ``theme.py`` possam renderizá-los.
"""

from __future__ import annotations

from armario_tablets.utils.datetime_utils import format_local
from armario_tablets.utils.validators import mask_uid
from armario_tablets.views.theme import SESSION_STATUS, TABLET_STATUS

# ── Métricas do dashboard ────────────────────────────────────────────────


def build_dashboard_metrics(
    data: dict | None,
    professors_count: int | None,
) -> list[dict]:
    """Converte dados de ``services.history.dashboard()`` em lista de métricas.

    Retorna dicts prontos para ``render_metric_cards()``.
    """
    if data is None or professors_count is None:
        return [
            {"icon": icon, "title": title, "value": "N/D", "color": color}
            for icon, title, color in (
                ("📱", "Tablets cadastrados", "#0B58B5"),
                ("✅", "Disponíveis", "#4CAF50"),
                ("📤", "Emprestados", "#FF9800"),
                ("👥", "Professores", "#2196F3"),
                ("🔓", "Retirados hoje", "#2478D4"),
                ("📥", "Devolvidos hoje", "#009688"),
            )
        ]

    tablets_by_status = data.get("tablets_by_status", {})
    total = sum(tablets_by_status.values())
    available = data.get("available", tablets_by_status.get("AVAILABLE", 0))
    checked_out = tablets_by_status.get("CHECKED_OUT", 0)

    return [
        {
            "icon": "📱",
            "title": "Tablets cadastrados",
            "value": total,
            "color": "#0B58B5",
        },
        {
            "icon": "✅",
            "title": "Disponíveis",
            "value": available,
            "color": "#4CAF50",
        },
        {
            "icon": "📤",
            "title": "Emprestados",
            "value": checked_out,
            "color": "#FF9800",
        },
        {
            "icon": "👥",
            "title": "Professores",
            "value": professors_count,
            "color": "#2196F3",
        },
        {
            "icon": "📋",
            "title": "Retirados hoje",
            "value": data.get("withdrawn_today", 0),
            "color": "#2478D4",
        },
        {
            "icon": "📥",
            "title": "Devolvidos hoje",
            "value": data.get("returned_today", 0),
            "color": "#009688",
        },
    ]


# ── Movimentações recentes ───────────────────────────────────────────────

_EVENT_TYPE_MAP = {
    "COMPLETED": "Devolução",
    "OPEN": "Retirada",
    "DIVERGENT": "Alerta",
    "PENDING": "Identificação",
    "UNLOCKED": "Identificação",
    "CANCELLED": "Erro",
    "FAILED": "Erro",
}


def format_movements_for_display(sessions) -> list[dict]:
    """Converte linhas de histórico em dicts para ``render_movements_table()``."""
    movements: list[dict] = []
    for row in sessions:
        status_label = SESSION_STATUS.get(row.status, (row.status,))[0]
        event_type = _EVENT_TYPE_MAP.get(row.status, "Identificação")
        movements.append(
            {
                "time": format_local(row.started_at) if row.started_at else "—",
                "professor": row.professor_name,
                "badge_id": "",  # mascarado quando disponível
                "event_type": event_type,
                "tablet": f"{row.taken_quantity} tablet(s)" if row.taken_quantity else "—",
                "status": status_label,
            }
        )
    return movements


# ── Notificações ─────────────────────────────────────────────────────────


def format_notifications(
    divergences: list,
    api_ok: bool | None,
    simulated: bool,
) -> list[dict]:
    """Cria lista de notificações a partir do estado real do sistema."""
    notifs: list[dict] = []

    if api_ok is False:
        notifs.append(
            {
                "type": "error",
                "message": "Falha na comunicação com o banco de dados local.",
                "time": "agora",
            }
        )

    for div in divergences:
        notifs.append(
            {
                "type": "warning",
                "message": (
                    f"Devolução pendente — solicitação #{div.session_id} ({div.professor_name})"
                ),
                "time": format_local(div.started_at) if div.started_at else "",
            }
        )

    if simulated:
        notifs.append(
            {
                "type": "info",
                "message": (
                    "Hardware em modo simulado. Leitores RFID e fechadura não estão conectados."
                ),
                "time": "",
            }
        )

    if not notifs:
        notifs.append(
            {
                "type": "success",
                "message": "Sistema operando normalmente.",
                "time": "",
            }
        )

    return notifs


# ── Tabela de professores ────────────────────────────────────────────────


def professor_table_data(professors) -> list[dict]:
    """Converte objetos Professor em dicts para ``st.dataframe``."""
    return [
        {
            "Nome": p.name,
            "Matrícula": p.registration,
            "Crachá RFID": mask_uid(p.badge_uid),
            "Ativo": "✅ Sim" if p.active else "❌ Não",
            "Cadastrado em": format_local(p.created_at),
        }
        for p in professors
    ]


# ── Tabela de tablets ────────────────────────────────────────────────────


def tablet_table_data(tablets) -> list[dict]:
    """Converte objetos Tablet em dicts para ``st.dataframe``."""
    return [
        {
            "Patrimônio": t.asset_code,
            "Situação": TABLET_STATUS.get(t.status, (t.status,))[0],
            "Etiqueta RFID": "✅ Sim" if t.rfid_tag_uid else "❌ Não",
            "Atualizado em": format_local(t.updated_at),
        }
        for t in tablets
    ]


# ── Tabela de histórico ─────────────────────────────────────────────────


def history_table_data(rows) -> list[dict]:
    """Converte linhas de histórico em dicts para ``st.dataframe``."""
    return [
        {
            "Solicitação": r.session_id,
            "Professor": r.professor_name,
            "Solicitados": r.requested_quantity,
            "Retirados": r.taken_quantity,
            "Pendentes": r.pending_quantity,
            "Finalidade": r.purpose,
            "Turma": r.class_name or "—",
            "Situação": SESSION_STATUS.get(r.status, (r.status,))[0],
            "Início": format_local(r.started_at),
            "Fim": format_local(r.completed_at) if r.completed_at else "—",
        }
        for r in rows
    ]
