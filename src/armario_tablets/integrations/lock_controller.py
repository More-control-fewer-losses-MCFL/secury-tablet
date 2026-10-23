from abc import ABC, abstractmethod


class LockController(ABC):
    """Fechadura do armário.

    Enviar o comando NÃO é o mesmo que a fechadura ter destravado: quem usa esta
    interface deve consultar `is_unlocked` (sensor/retorno do controlador).
    """

    @abstractmethod
    def send_unlock(self, cabinet_code: str) -> None:
        """Envia o comando de destravar. Levanta LockError se o envio falhar."""

    @abstractmethod
    def send_lock(self, cabinet_code: str) -> None:
        """Envia o comando de travar."""

    @abstractmethod
    def is_unlocked(self, cabinet_code: str) -> bool:
        """Estado confirmado pelo sensor/controlador."""
