# Execução local completa com Docker

Requisitos: Docker Desktop ativo com containers Linux, Git e espaço para o build
inicial do SDK Flutter. Python e Flutter no host não são necessários.

Na raiz correta (`C:\Users\Schneider\Documents\secury-tablet`), execute:

```powershell
.\scripts\start_local.ps1
# Somente se desejar criar dados falsos de demonstração:
.\scripts\start_local.ps1 -Demo
```

O script cria `.env` com segredos aleatórios apenas se o arquivo não existir.
Se já existir, preserva integralmente seu conteúdo. Preencha ADMIN_PASSWORD,
ADMIN_TOKEN_SECRET, HARDWARE_API_KEY e senhas MySQL se faltarem. Nunca versionar
.env. A senha de teste existente foi preservada a pedido do PO.

Com `.env` configurado, o comando equivalente é:

```powershell
docker compose up -d --build
```

Abra **http://localhost:8080**. API/Swagger: **http://localhost:8080/api/docs**.
A primeira compilação baixa Flutter 3.47.8 oficial com SHA-256 verificado; builds
seguintes reutilizam cache. O build é Linux/amd64; ARM não foi validado.
`WEB_PORT` altera a porta local. O endereço é limitado ao loopback por padrão.

## Componentes e inicialização

- MySQL 8.4 mantém o volume existente `armario_mysql_data` e porta 3306 em loopback.
- `migrate` executa Alembic e precisa terminar com sucesso antes de iniciar a API.
- API Python executa como usuário sem privilégios e não publica porta no host.
- Nginx serve Flutter compilado e encaminha `/api` para API; mesma origem para cookies.
- Hardware permanece explicitamente simulado; Streamlit não é incluído nesta stack.
- `seed` é opt-in, idempotente e separado; não há carga automática de dados falsos.

Administrador: usuário ADMIN_USERNAME (padrão admin), senha ADMIN_PASSWORD no .env.
Para professores: entrar no modo admin, marcar **Autorizar este terminal e voltar
ao RFID**, autenticar e então usar apenas o crachá. Na demo: DE000001/2/3 ativos.
Cookies de terminal duram 8h e sessões de professor 10min por padrão. Revogação
administrativa: POST /api/terminal/revoke. UID não prova identidade do portador.

## Operação e dados

```powershell
docker compose ps
docker compose logs --tail 100 api web migrate
docker compose stop
# Reiniciar toda a stack após alterar o código:
docker compose up -d --build
```

Não usar `down -v`: remove dados persistentes. Backup antes de migrações e
atualizações. Este ciclo fez backup local antes de migrar e conferiu uma restauração em banco descartável; o diretório backups
está fora do contexto Docker e do Git. Backup atual: `python scripts/backup_database.py`
(quando Python local disponível). Sem Python, usar mysqldump dentro do container
com credenciais privadas. Exercitar restauração somente em banco descartável.

Nginx limita tentativas de login admin e leitura RFID; responde 429 ao excesso.
Não expor a API interna diretamente para contornar esses limites. Logs de acesso
HTTP da API e das rotas proxy estão desativados para evitar UIDs em URLs.

Esta configuração é local. Para acesso de outros equipamentos em sala, definir
rede, HTTPS/certificados e provisionamento seguro antes de alterar binds.
Com HTTPS ativar SESSION_COOKIE_SECURE=true e manter nomes de host consistentes.
Montagem, protocolo físico e homologação ficam em [hardware-sala.md](hardware-sala.md).
