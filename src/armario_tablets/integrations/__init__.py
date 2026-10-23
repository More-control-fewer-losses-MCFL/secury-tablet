from functools import lru_cache

from armario_tablets.config import get_settings
from armario_tablets.integrations.simulated_hardware import Hardware, build_hardware


@lru_cache
def get_hardware() -> Hardware:
    """Hardware único por processo (simulado por padrão)."""
    return build_hardware(get_settings())
