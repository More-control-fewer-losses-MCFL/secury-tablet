"""Hardware simulado: padrão para desenvolvimento e demonstração.

Nada aqui aciona fechadura ou leitor reais.
"""

from dataclasses import dataclass

from armario_tablets.config import Settings
from armario_tablets.exceptions import LockError, ReaderError
from armario_tablets.integrations.badge_reader import BadgeReader
from armario_tablets.integrations.lock_controller import LockController
from armario_tablets.integrations.tablet_reader import TabletReader


class SimulatedBadgeReader(BadgeReader):
    def __init__(self, uid: str | None = None) -> None:
        self.uid = uid
        self.fail = False

    def read_badge_uid(self) -> str | None:
        if self.fail:
            raise ReaderError("Falha simulada no leitor de crachá.")
        return self.uid


class SimulatedTabletReader(TabletReader):
    def __init__(self, present_tags: set[str] | None = None) -> None:
        self.present_tags: set[str] = set(present_tags or ())
        self.fail = False

    def read_present_tags(self, cabinet_code: str) -> set[str]:
        if self.fail:
            raise ReaderError("Falha simulada no leitor de tablets.")
        return set(self.present_tags)


class SimulatedLockController(LockController):
    """Fechadura de mentira, com chaves para simular erro e falta de confirmação."""

    def __init__(self) -> None:
        self._unlocked: dict[str, bool] = {}
        self.fail_on_send = False  # o comando nem chega à fechadura
        self.never_confirms = False  # o comando é enviado, mas o sensor não confirma

    def send_unlock(self, cabinet_code: str) -> None:
        if self.fail_on_send:
            raise LockError("Falha simulada ao enviar comando para a fechadura.")
        if not self.never_confirms:
            self._unlocked[cabinet_code] = True

    def send_lock(self, cabinet_code: str) -> None:
        self._unlocked[cabinet_code] = False

    def is_unlocked(self, cabinet_code: str) -> bool:
        return self._unlocked.get(cabinet_code, False)


@dataclass
class Hardware:
    badge_reader: BadgeReader
    tablet_reader: TabletReader
    lock_controller: LockController


def build_simulated_hardware() -> Hardware:
    return Hardware(SimulatedBadgeReader(), SimulatedTabletReader(), SimulatedLockController())


def build_hardware(settings: Settings) -> Hardware:
    """Só o modo simulado existe por enquanto.

    O hardware real depende de confirmar modelo dos leitores/fechadura e protocolo.
    """
    if settings.hardware_simulated:
        return build_simulated_hardware()
    raise NotImplementedError(
        "Hardware real ainda não implementado: valide modelo e protocolo dos leitores "
        "e da fechadura antes de criar o adaptador. Mantenha HARDWARE_SIMULATED=true."
    )
