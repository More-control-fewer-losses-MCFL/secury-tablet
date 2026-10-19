# Armário Inteligente de Tablets

Sistema para controlar a **retirada e a devolução de tablets** de um armário por professores identificados com **crachá RFID**.

- Interface web local: **Streamlit**
- API local: **FastAPI** (recebe eventos do controlador/leitor)
- Banco: **MySQL 8.4** (Docker) · ORM: **SQLAlchemy 2** · Migrações: **Alembic**
- Tudo em **Python**. Começa em **modo simulado**: não precisa de leitor nem de fechadura.

> **Importante:** neste momento **todo o hardware é simulado**. Nenhuma fechadura real é acionada. Veja [docs/escopo_projeto.md](docs/escopo_projeto.md) para saber o que ainda precisa ser validado.

## O que você precisa ter instalado (Windows)

- Python 3.12 ou mais novo
- Docker Desktop (ligado)
- PowerShell

## Passo a passo (PowerShell)

Abra o PowerShell na pasta do projeto.

### 1. Criar o ambiente Python

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -e ".[dev]"
```

> Se o PowerShell bloquear o script de ativação, rode uma vez:
> `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

### 2. Criar o arquivo `.env` e trocar a senha

```powershell
Copy-Item .env.example .env
notepad .env
```

Troque `MYSQL_PASSWORD` por uma senha sua. **Nunca envie o `.env` para o Git** (já está no `.gitignore`).

### 3. Subir o MySQL

```powershell
docker compose up -d
docker compose ps          # a coluna STATUS deve mostrar "healthy"
```

### 4. Criar as tabelas e os dados de demonstração

```powershell
alembic upgrade head
python scripts/seed_demo.py
```

O seed cria **dados falsos**: 1 armário, 4 professores e 10 tablets. Crachás de teste: `DE000001`, `DE000002`, `DE000003` (ativos) e `DE000900` (inativo).

### 5. Iniciar a API (um terminal)

```powershell
uvicorn armario_tablets.api.main:app --host 127.0.0.1 --port 8000
```

Abra <http://127.0.0.1:8000/docs> para testar os endpoints.

### 6. Iniciar a interface (outro terminal)

```powershell
.\.venv\Scripts\Activate.ps1
streamlit run app/streamlit_app.py
```

Abra <http://localhost:8501>.

### Como usar a demonstração

1. **Solicitar Tablets**: digite `DE000001`, quantidade e finalidade → "Validar e destravar".
2. Na área de simulação, escolha **quais tablets saíram de fato** e clique em "Fechar porta e ler inventário". Só então os tablets viram "emprestados".
3. **Devolução**: marque os tablets devolvidos. Se faltar algum, ele fica **pendente** e aparece como **divergência** no Dashboard.
4. **Histórico**: veja todas as solicitações (paginado).

## Comandos do dia a dia

```powershell
docker compose up -d                     # subir o banco
docker compose stop                      # parar (os dados ficam guardados no volume)
docker compose ps                        # ver a saúde do banco
docker exec armario_tablets_db mysqladmin ping -u armario -p"$env:MYSQL_PASSWORD" --silent   # teste de saúde
docker compose down                      # remove o container (o volume e os dados continuam)
# docker compose down -v                 # CUIDADO: apaga também os dados
```

## Backup e restauração

Backup (cria `backups\armario_AAAAMMDD_HHMMSS.sql`; a pasta é ignorada pelo Git):

```powershell
python scripts/backup_database.py
```

Restauração (troque o nome do arquivo):

```powershell
docker cp backups\armario_20261015_120000.sql armario_tablets_db:/tmp/restore.sql
docker exec -i armario_tablets_db mysql -u armario -p"$env:MYSQL_PASSWORD" armario_tablets < /tmp/restore.sql
```

> Se mudou `MYSQL_USER`/`MYSQL_DATABASE` no `.env`, use os mesmos valores nos comandos acima.

## Testes e qualidade

```powershell
pytest tests/unit -q          # rápido, não precisa de Docker
ruff check .
ruff format --check .
```

Testes de integração (MySQL real, em banco **separado**; apagam o schema do banco de teste):

```powershell
docker exec -i armario_tablets_db mysql -uroot -p"$env:MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE armario_tablets_test;"
$env:TEST_DATABASE_URL = "mysql+pymysql://armario:$($env:MYSQL_PASSWORD)@127.0.0.1:3306/armario_tablets_test"
pytest tests/integration -q
```

## Regras importantes do sistema

- A **quantidade pedida nunca é a quantidade retirada**: só contam os tablets cuja etiqueta RFID individual foi confirmada pela leitura do inventário.
- Retirada e devolução usam **transações**; dois pedidos ao mesmo tempo não conseguem pegar o mesmo tablet.
- Eventos repetidos (mesmo `event_id`) **não** geram uma segunda retirada.
- Comando enviado à fechadura **não** é confirmação: o sistema espera o sensor, com timeout, e registra erro.
- O **UID do crachá não é uma credencial segura** (pode ser clonado). Use apenas em rede local protegida e veja [docs/arquitetura.md](docs/arquitetura.md).

## Estrutura

```
app/                páginas Streamlit (finas)
src/armario_tablets/
  api/              endpoints FastAPI
  models/           tabelas (SQLAlchemy)
  schemas/          contratos de entrada/saída (Pydantic)
  repositories/     consultas e gravações
  services/         regras de negócio
  views/            telas (chamam services)
  integrations/     leitores/fechadura (interfaces + simulados)
  utils/            funções auxiliares
migrations/         migrações Alembic
scripts/            seed de demonstração e backup
tests/              unit/ e integration/
docs/               escopo, arquitetura, banco, API, testes
```

## Documentação

[Escopo](docs/escopo_projeto.md) · [Arquitetura](docs/arquitetura.md) · [Banco de dados](docs/banco_de_dados.md) · [API](docs/api.md) · [Testes](docs/testes.md)
