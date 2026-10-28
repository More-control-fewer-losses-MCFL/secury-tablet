# Testes

```powershell
pytest tests/unit -q                 # rápido, SQLite em memória, sem Docker
pytest tests/integration -q          # MySQL 8.4 real (veja abaixo)
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

Usam **MySQL 8.4 de verdade, em um banco SEPARADO**. Defina `TEST_DATABASE_URL`:

```powershell
docker exec -it armario_tablets_db mysql -u root -p -e "CREATE DATABASE armario_tablets_test"
$env:TEST_DATABASE_URL = "mysql+pymysql://USUARIO_TESTE:SENHA_TESTE@127.0.0.1:3306/armario_tablets_test"
pytest tests/integration -q
```

Crie um usuário exclusivo para testes e conceda acesso somente a esse banco.
Codifique caracteres especiais da senha na URL (percent-encoding).

> **Atenção:** a fixture **apaga as tabelas da aplicação** do banco de teste e as recria pelas migrações do Alembic (isso também testa a migração). Nunca aponte para o banco de desenvolvimento ou de produção. Os dados são sempre falsos.

Cobrem: dois pedidos simultâneos nunca vencem juntos; o mesmo evento chegando em paralelo gera uma única retirada; unicidade de itens ativos; `details` realmente em JSON; índices esperados existem; histórico no MySQL.

## Verificações automáticas

O workflow `.github/workflows/quality.yml` executa testes unitários Python,
integração MySQL 8.4 em banco isolado e análise/testes/build Web do Flutter em
pull requests e pushes para `main`/`develop`. Consulte o resultado de cada job
antes de integrar uma alteração.

Os testes de integração recusam `TEST_DATABASE_URL` com backend diferente de
MySQL ou banco sem sufixo `_test`, antes de executar comandos destrutivos.
Use sempre uma instância descartável com credenciais exclusivas de teste.
