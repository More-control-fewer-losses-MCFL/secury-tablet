"""Cria dados FALSOS para demonstração (armário, professores e tablets).

Todos os UIDs abaixo são inventados e começam com "DE" / "AA" só para ficarem
fáceis de reconhecer. Nunca coloque UIDs de crachás reais neste arquivo.

Uso:  python scripts/seed_demo.py
"""

from armario_tablets.config import get_settings
from armario_tablets.database.session import session_scope, unit_of_work
from armario_tablets.models import Cabinet, DoorState, LockState, Professor, Tablet
from armario_tablets.repositories.cabinet_repository import CabinetRepository
from armario_tablets.repositories.professor_repository import ProfessorRepository
from armario_tablets.repositories.tablet_repository import TabletRepository

DEMO_PROFESSORS = [
    ("Professora Ana (demo)", "DEMO-001", "DE000001", True),
    ("Professor Bruno (demo)", "DEMO-002", "DE000002", True),
    ("Professora Carla (demo)", "DEMO-003", "DE000003", True),
    ("Professor Inativo (demo)", "DEMO-900", "DE000900", False),
]
TABLET_COUNT = 10


def seed() -> dict[str, int]:
    created = {"cabinets": 0, "professors": 0, "tablets": 0}
    code = get_settings().cabinet_code
    with session_scope() as db, unit_of_work(db):
        cabinets = CabinetRepository(db)
        if cabinets.get_by_code(code) is None:
            cabinets.add(
                Cabinet(code=code, door_state=DoorState.CLOSED, lock_state=LockState.LOCKED)
            )
            created["cabinets"] += 1

        professors = ProfessorRepository(db)
        for name, registration, badge_uid, active in DEMO_PROFESSORS:
            if professors.get_by_badge(badge_uid) is None:
                professors.add(
                    Professor(
                        name=name, registration=registration, badge_uid=badge_uid, active=active
                    )
                )
                created["professors"] += 1

        tablets = TabletRepository(db)
        for number in range(1, TABLET_COUNT + 1):
            asset_code = f"TAB-{number:03d}"
            if tablets.get_by_asset_code(asset_code) is None:
                tablets.add(Tablet(asset_code=asset_code, rfid_tag_uid=f"AA{number:06d}"))
                created["tablets"] += 1
    return created


if __name__ == "__main__":
    result = seed()
    print(f"Dados de demonstração criados: {result}")
    print("Crachás de teste: DE000001, DE000002, DE000003 (ativos) e DE000900 (inativo).")
