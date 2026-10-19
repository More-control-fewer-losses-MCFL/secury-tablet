# Testes

```powershell
pytest tests/unit -q                 # rápido, SQLite em memória, sem Docker
pytest tests/integration -q          # PostgreSQL real (veja abaixo)
pytest -q                            # tudo (integração é pulada sem TEST_DATABASE_URL)
ruff check .; ruff format --check .
```

## Unitários (`tests/unit`)

SQLite em memória + hardware simulado. Cobrem:

- professor ativo, inativo e crachá desconhecido;
- solicitação maior que a disponibilidade;
- retirada com leitura parcial, com excesso e sem retirada;
- devolução completa, incompleta e conciliada depois;
- tablet já emprestado (não é oferecido de novo; índice único bloqueia item ativo duplicado);
- evento repetido (idempotência) em retirada, devolução, portas e HTTP;
- erro de fechadura (envio falhou / sem confirmação física) e de leitor;
- reserva vencida, armário ocupado, paginação do histórico e todos os endpoints.

## Integração (`tests/integration`)

Usam **PostgreSQL de verdade, em um banco SEPARADO**. Defina `TEST_DATABASE_URL`:

```powershell
docker exec armario_tablets_db psql -U armario -d postgres -c "CREATE DATABASE armario_tablets_test"
$env:TEST_DATABASE_URL = "postgresql+psycopg://armario:SUA_SENHA@127.0.0.1:5432/armario_tablets_test"
pytest tests/integration -q
```

> **Atenção:** a fixture **apaga todo o schema `public`** do banco de teste e o recria pelas migrações do Alembic (isso também testa a migração). Nunca aponte para o banco de desenvolvimento ou de produção. Os dados são sempre falsos.

Cobrem: dois pedidos simultâneos nunca vencem juntos; o mesmo evento chegando em paralelo gera uma única retirada; índice único parcial; `details` realmente em JSONB; índices esperados existem; histórico no PostgreSQL.
