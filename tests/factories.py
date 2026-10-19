"""Dados falsos usados pelos testes (nada real)."""

from sqlalchemy.orm import Session

from armario_tablets.models import Cabinet, DoorState, LockState, Professor, Tablet

CABINET_CODE = "ARM-TEST"
ACTIVE_BADGE = "DE000001"
OTHER_ACTIVE_BADGE = "DE000002"
INACTIVE_BADGE = "DE000900"


def tag_for(number: int) -> str:
    return f"AA{number:06d}"


def seed_basic(db: Session, tablets: int = 5) -> None:
    db.add(Cabinet(code=CABINET_CODE, door_state=DoorState.CLOSED, lock_state=LockState.LOCKED))
    db.add(Professor(name="Ana Teste", registration="T-1", badge_uid=ACTIVE_BADGE, active=True))
    db.add(Professor(name="Bruno Teste", registration="T-2", badge_uid=OTHER_ACTIVE_BADGE))
    db.add(
        Professor(name="Inativo Teste", registration="T-9", badge_uid=INACTIVE_BADGE, active=False)
    )
    for number in range(1, tablets + 1):
        db.add(Tablet(asset_code=f"TAB-{number:03d}", rfid_tag_uid=tag_for(number)))
    db.commit()


def all_tags(tablets: int = 5) -> set[str]:
    return {tag_for(n) for n in range(1, tablets + 1)}
