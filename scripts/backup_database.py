"""Backup do MySQL com mysqldump, executado dentro do container do Docker Compose.

Uso:  python scripts/backup_database.py
Gera: backups/armario_AAAAMMDD_HHMMSS.sql (a pasta backups/ é ignorada pelo Git)

Restauração (PowerShell): veja a seção "Backup e restauração" do README.
"""

import subprocess
import sys
from datetime import datetime
from pathlib import Path

from armario_tablets.config import get_settings

CONTAINER = "armario_tablets_db"
BACKUP_DIR = Path(__file__).resolve().parent.parent / "backups"


def main() -> int:
    settings = get_settings()
    BACKUP_DIR.mkdir(exist_ok=True)
    target = BACKUP_DIR / f"armario_{datetime.now():%Y%m%d_%H%M%S}.sql"
    command = [
        "docker",
        "exec",
        CONTAINER,
        "mysqldump",
        "--user",
        settings.mysql_user,
        "--password=" + settings.mysql_password.get_secret_value(),
        settings.mysql_db,
    ]
    with target.open("wb") as output:
        result = subprocess.run(command, stdout=output, stderr=subprocess.PIPE, check=False)
    if result.returncode != 0:
        target.unlink(missing_ok=True)
        print("Falha no backup:", result.stderr.decode(errors="replace"), file=sys.stderr)
        return 1
    print(f"Backup criado em {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
