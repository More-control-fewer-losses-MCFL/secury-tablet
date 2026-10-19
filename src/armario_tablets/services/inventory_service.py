from armario_tablets.integrations.tablet_reader import TabletReader
from armario_tablets.models import Tablet
from armario_tablets.repositories.tablet_repository import TabletRepository


class InventoryService:
    """Interpreta a leitura do inventário (quais etiquetas estão no armário)."""

    def __init__(self, tablets: TabletRepository, reader: TabletReader) -> None:
        self._tablets = tablets
        self._reader = reader

    def read_present_tags(self, cabinet_code: str) -> set[str]:
        """Lê o inventário no leitor. Levanta ReaderError se o leitor falhar."""
        return self._reader.read_present_tags(cabinet_code)

    def detect_withdrawn(self, present_tags: set[str]) -> list[Tablet]:
        """Tablets que estavam disponíveis e cuja etiqueta NÃO foi mais detectada.

        Só a identidade individual confirma uma retirada; a quantidade pedida
        nunca é usada aqui. As linhas ficam travadas até o fim da transação.
        """
        available = self._tablets.list_available_for_update()
        return [t for t in available if t.rfid_tag_uid not in present_tags]
