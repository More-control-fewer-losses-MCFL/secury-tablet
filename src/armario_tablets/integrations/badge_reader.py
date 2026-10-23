from abc import ABC, abstractmethod


class BadgeReader(ABC):
    """Leitor de crachá RFID. Implementação real só após confirmar modelo e protocolo."""

    @abstractmethod
    def read_badge_uid(self) -> str | None:
        """Devolve o UID lido, ou None se nenhum crachá foi apresentado.

        Levanta ReaderError se o leitor falhar.
        """
