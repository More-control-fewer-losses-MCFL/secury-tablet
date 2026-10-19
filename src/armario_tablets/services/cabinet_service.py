import logging
import time
from collections.abc import Callable

from armario_tablets.exceptions import CabinetNotFoundError, LockError
from armario_tablets.integrations.lock_controller import LockController
from armario_tablets.models import Cabinet, DoorState, LockState
from armario_tablets.repositories.cabinet_repository import CabinetRepository

logger = logging.getLogger(__name__)


class CabinetService:
    def __init__(
        self,
        cabinets: CabinetRepository,
        lock: LockController,
        confirm_timeout_seconds: float = 5.0,
        poll_interval_seconds: float = 0.1,
        sleep: Callable[[float], None] = time.sleep,
    ) -> None:
        self._cabinets = cabinets
        self._lock = lock
        self._timeout = confirm_timeout_seconds
        self._poll = poll_interval_seconds
        self._sleep = sleep

    def get_by_code(self, code: str, for_update: bool = False) -> Cabinet:
        cabinet = (
            self._cabinets.get_by_code_for_update(code)
            if for_update
            else self._cabinets.get_by_code(code)
        )
        if cabinet is None:
            raise CabinetNotFoundError(f"Armário '{code}' não cadastrado.")
        return cabinet

    def get_by_id(self, cabinet_id: int) -> Cabinet:
        cabinet = self._cabinets.get(cabinet_id)
        if cabinet is None:
            raise CabinetNotFoundError("Armário não encontrado.")
        return cabinet

    def unlock_with_confirmation(self, cabinet_code: str) -> None:
        """Envia o comando e ESPERA o retorno do sensor/controlador.

        Comando enviado não é fechadura destravada: sem confirmação dentro do
        timeout levanta LockError.
        """
        self._lock.send_unlock(cabinet_code)
        deadline = time.monotonic() + self._timeout
        while time.monotonic() < deadline:
            if self._lock.is_unlocked(cabinet_code):
                return
            self._sleep(self._poll)
        if self._lock.is_unlocked(cabinet_code):
            return
        raise LockError("A fechadura não confirmou o destravamento a tempo.")

    def relock(self, cabinet_code: str) -> None:
        try:
            self._lock.send_lock(cabinet_code)
        except LockError:
            logger.error("Falha ao travar o armário %s", cabinet_code)

    @staticmethod
    def set_states(cabinet: Cabinet, door: DoorState | None = None, lock: LockState | None = None):
        if door is not None:
            cabinet.door_state = door
        if lock is not None:
            cabinet.lock_state = lock
