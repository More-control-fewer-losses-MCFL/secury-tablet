from abc import ABC, abstractmethod


class TabletReader(ABC):
    """Leitor do inventário: quais etiquetas RFID de tablets estão dentro do armário."""

    @abstractmethod
    def read_present_tags(self, cabinet_code: str) -> set[str]:
        """Devolve os UIDs das etiquetas detectadas. Levanta ReaderError se falhar."""
