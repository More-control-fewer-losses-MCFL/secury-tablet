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

## Integração Railway: Nginx configurado na inicialização — 2026-11-19

Estado: **pronto para validação no Railway**. PRs
[#17](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/17) e
[#18](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/18)
integrados em main por autorização explícita em 2026-11-19. Código funcional
`ab979ce`; os dois PRs tiveram unit/mysql/flutter/docker aprovados.
CI pós-merge em acompanhamento. Não foi alterada diretamente a configuração
Railway nem confirmado deploy; automações existentes podem ser acionadas pelo Git.
A referência privada e o domínio público ainda precisam de validação real.
Histórico, commits e próximos itens em `docs/PROJECT_STATUS.md` e handoff.

### Diagnóstico com evidências e limites

- O código anterior fixa `api:8000`, `resolver 127.0.0.11` e `ipv6=off`.
  É uma configuração dependente do Docker Compose. Não é evidência suficiente
  para atribuir a ela o timeout específico da implantação sem DNS/logs reais.
- Em consulta pública sem autenticação, o endereço informado respondeu 404
  `Application not found` em aproximadamente 0,4 s para `/`, `/healthz` e
  `/api/health`. Essa consulta não atingiu a aplicação Nginx esperada. Conferir
  domínio associado, implantação ativa e target port no painel antes de atribuir
  o erro a uma API lenta. Não foi reproduzida demora de 12 s nesse endereço.
- Projeto `glistening-communication`, ambiente `production`, backend
  `security-tablet`, frontend `security-tablet-frontend`, portas 8000/80:
  **informados pelo usuário**, sem confirmação por API/painel Railway.
  Não substituir por `secury-tablet` nem adivinhar o hostname privado.
- O conector Railway foi localizado, mas a conexão não foi confirmada.
  DNS privado real, valor resolvido de `RAILWAY_PRIVATE_DOMAIN`, logs e bind do
  Uvicorn na plataforma permanecem pendentes. Domínios internos só resolvem na rede
  privada do mesmo projeto/ambiente, durante runtime.
- A rede Railway pode ter A/AAAA ou somente AAAA em ambientes legados. O backend
  atual escuta IPv4 (`0.0.0.0:8000`). Se a inspeção real comprovar somente AAAA,
  validar o bind IPv6 antes de autorizar mudança de comando; não reconstruir a API
  por suposição.

### Fluxo e arquivos

`Navegador → HTTPS público → Flutter/Nginx → DNS/rede privada → FastAPI → MySQL`.

O bundle continua compilado com `--dart-define=API_BASE_URL=/api`. Nenhum domínio
privado ou segredo é incorporado ao Flutter. Não há CORS permissivo nem uso do
domínio público da API como alternativa ao proxy.

- `docker/nginx.conf` é o template copiado para
  `/etc/nginx/templates/default.conf.template`.
- `docker/web.Dockerfile` preserva Nginx oficial e seu entrypoint. Os defaults são
  `API_UPSTREAM_HOST=api`, `API_UPSTREAM_PORT=8000` e
  `NGINX_ENTRYPOINT_LOCAL_RESOLVERS=1`.
- O script oficial `15-local-resolvers.envsh` coleta os nameservers de
  `/etc/resolv.conf`, incluindo IPv6. O novo
  `docker/19-validate-upstream.envsh` valida host DNS e porta 1–65535, exige
  resolver disponível e fixa o filtro de substituição antes do script oficial 20.
- O filtro ancorado permite somente `API_UPSTREAM_HOST`,
  `API_UPSTREAM_PORT` e `NGINX_LOCAL_RESOLVERS`. Variáveis Nginx como
  `$host`, `$scheme`, `$uri`, `$request_uri` e `$binary_remote_addr`
  continuam pertencendo ao Nginx, mesmo com variáveis de ambiente homônimas.
- `.gitattributes` garante LF também para os scripts `*.envsh`.
- O resolver reconsulta a cada 10 s; IPv6 permanece habilitado. Limites de
  resolução/conexão são 3 s; leitura continua 30 s e Flutter continua 12 s.
  Não há retry automático de operações no Flutter.
- As três rotas especiais mantêm os mesmos rate limits. Cada handler remove
  `/api` com `rewrite ... break` e usa `proxy_pass` sem URI explícita:
  preserva método, argumentos, corpo, Authorization, Cookie e Set-Cookie.
- Headers comuns ficam no server, sem sobrescrita parcial nos locations.
  Host e porta originais são preservados; `X-Forwarded-Proto` aceita somente
  `http`/`https` da borda e usa o esquema local como fallback.
  A confiança nos headers pressupõe uma borda controlada: não usar essa
  informação, isoladamente, como autenticação.
- Backend, `--root-path /api`, contratos HTTP, autenticação, schema e regras
  de empréstimo/devolução não foram alterados.

### Configuração manual exata no Railway, após autorização

No serviço **security-tablet-frontend**, projeto/ambiente acima:

```text
API_UPSTREAM_HOST=${{security-tablet.RAILWAY_PRIVATE_DOMAIN}}
API_UPSTREAM_PORT=8000
PORT=80
```

A sintaxe `${{...}}` é uma referência no editor de variáveis do Railway,
não um comando shell. Confirmar que ela resolve para o valor real da variável
do backend; não preencher um hostname adivinhado. O Nginx escuta na porta **80**:
associar o domínio público ao **target port 80**. `PORT` não altera a diretiva
listen do template; não usar outra porta sem atualizar essa configuração.

O Dockerfile do frontend deve ser `docker/web.Dockerfile`, com contexto na raiz.
Apenas esse serviço precisa receber a imagem corrigida. Manter os dois serviços
no mesmo projeto e ambiente, sem necessidade de domínio público no backend.

No backend, conferir `SESSION_COOKIE_SECURE=true` em HTTPS e a configuração
existente de sessões. Uvicorn normalmente confia nos headers de proxy somente de
loopback; verificar `FORWARDED_ALLOW_IPS` para os proxies realmente confiáveis.
Não aplicar `*` indiscriminadamente a um backend público. O teste isolado usa
`*` somente porque a API não tem porta pública e todos os peers são fixtures.

Se o DNS real for exclusivamente AAAA e o bind IPv4 for confirmado como causa,
uma mudança autorizada de Start Command pode usar `--host ::`, preservando
`--port 8000 --root-path /api --no-access-log`. Validar o healthcheck e as
famílias efetivamente atendidas; não aplicar essa alteração sem a evidência.

### Testes locais e comandos reproduzíveis

Imagem frontend construída com o Dockerfile real, sem rebuild da API:

```powershell
docker build -f docker/web.Dockerfile -t secury-web-runtime:review .
$env:WEB_PROXY_TEST_IMAGE = 'secury-web-runtime:review'
.\.venv\Scripts\python.exe -m pytest tests/docker/test_web_proxy.py -q
.\.venv\Scripts\python.exe -m pytest tests/unit -q
.\.venv\Scripts\python.exe -m ruff check tests/docker
.\.venv\Scripts\python.exe -m ruff format --check tests/docker
git diff --check
docker compose config --quiet
```

Para a stack real descartável, reutilizar uma imagem API equivalente ao código
atual; nesta máquina `secury-professor-login-api:review` foi comparada com os
84 arquivos Python locais, sem diferenças. A fixture aceita `API_TEST_IMAGE`
e usa `secury-tablet-api:local` como default em outras máquinas.

```powershell
$env:API_TEST_IMAGE = 'secury-professor-login-api:review'
$env:PROXY_STACK_PROJECT = 'secury-proxy-review-20261119'
docker compose --env-file NUL -p $env:PROXY_STACK_PROJECT -f tests/docker/compose.proxy-test.yml up -d --wait --wait-timeout 180
.\.venv\Scripts\python.exe -m pytest tests/docker/test_full_stack.py -q -s
# Somente a stack descartável acima; não usar este comando no projeto real.
docker compose --env-file NUL -p $env:PROXY_STACK_PROJECT -f tests/docker/compose.proxy-test.yml down
```

Os comandos Flutter abaixo foram executados em cópia isolada do projeto,
com Flutter 3.47.8 na imagem local de validação, após `flutter pub get --offline`:

```sh
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --release --no-pub --dart-define=API_BASE_URL=/api
```

A inspeção do Nginx na stack usou `docker compose ... exec -T web nginx -t`,
`nginx -T` e `cat /etc/resolv.conf`. Os 20 testes de proxy foram executados
como 18 cenários iniciais mais os testes específicos de deadline e nameserver IPv6.
A fixture IPv6 prova configuração válida, não disponibilidade de um resolver
Railway real. O teste com upstream IPv6-only verificou comunicação HTTP real.

A stack usa MySQL em tmpfs, `secury_proxy_test`, credenciais fictícias exclusivas
e `HARDWARE_SIMULATED=true`. A suíte de integração existente roda num segundo
banco `secury_integration_test`. Não acessa os dados ou serviços existentes.

Resultados confirmados:

| Validação | Resultado |
| --- | --- |
| Build `docker/web.Dockerfile` | Aprovado; Flutter continua `/api` |
| Nginx `-t` e inspeção `-T` | Aprovados; configuração gerada, variáveis preservadas |
| Proxy isolado | 20 cenários aprovados, incluindo deadline de 12 s e nameserver IPv6 |
| Stack Compose real | 5 cenários aprovados |
| Python unitário | 130 aprovados; aviso Starlette/httpx preexistente |
| MySQL isolado | 28 aprovados |
| Flutter 3.47.8 | Analyze sem apontamentos, 44 testes e build Web release aprovados |
| Ruff e diff | Aprovados nos arquivos alterados |
| Railway privado/deploy | Não executados; conexão não confirmada |

O teste de lentidão expirou no consumidor em 12 s; nenhum limite foi aumentado.
As fixtures verificam host/porta de runtime (inclusive alias de teste terminado
em `.railway.internal`), IPv6-only, troca de endereço DNS sem reiniciar Nginx,
DNS ausente, backend desligado, repasse de 401/403/404/502/503/504, payload/query,
cookies/headers e rate limits. Um alias Docker com esse sufixo é uma simulação,
não comprovação do DNS real Railway. Backend desligado pode gerar 502 (recusa TCP)
ou 504 (timeout ao conectar a endereço em cache); essa diferença foi observada e
a asserção aceita as duas causas, com resposta antes do limite do cliente.
Banco real de teste desligado produziu 503; `/healthz` continuou respondendo.

### Publicação e validação na plataforma, ainda pendentes

1. Conferir no painel o domínio público informado, sua associação ao frontend,
   deployment ativo e target 80. Resolver primeiro o 404 da borda.
2. No container frontend, ler `/etc/resolv.conf`, conferir a referência resolvida
   e testar `getent hosts "$API_UPSTREAM_HOST"`. Não tentar resolver domínio
   privado pelo navegador ou durante build.
3. Executar `nginx -t` e inspecionar `nginx -T`, sem copiar credenciais.
   Testar internamente:
   `wget -T 5 -S -O - "http://$API_UPSTREAM_HOST:$API_UPSTREAM_PORT/health"`.
   Comparar com `wget -T 5 -S -O - http://127.0.0.1/api/health`.
4. Se resolver e não conectar, conferir porta/bind IPv4/IPv6, ambiente e processo
   backend. Se receber 503, investigar banco/logs da API; se o frontend não tiver
   `/healthz`, investigar domínio, target port ou inicialização do Nginx.
5. PRs #17/#18 já foram integrados em main com autorização. Conferir a CI
   pós-merge do head vigente e o commit usado pelo serviço antes da publicação.
   A proteção do TXT em `.dockerignore` está integrada. Não incluir `.env`
   ou credenciais em commits futuros. Mudanças diretas/deploy no Railway
   continuam exigindo autorização explícita.
6. Após deploy autorizado somente do frontend, validar HTTPS `/`, `/healthz`
   e `/api/health` com status/tempo; depois testar contas exclusivas de teste,
   login dos dois perfis, sessões, rejeições, cookie seguro e redirects HTTPS.
   Não acionar hardware nem provocar rate limit em contas reais.
7. Rotacionar as credenciais demonstrativas anteriormente expostas antes de
   qualquer uso com dados reais. Não transportar as credenciais das fixtures
   para o Railway.

Reversão: registrar imagem/deployment e variáveis anteriores antes da publicação.
Se a nova configuração falhar, reverter apenas o deployment frontend e suas
variáveis para o snapshot anterior; não reverter schema nem apagar volumes.
Uma versão antiga com upstream Compose pode continuar sem funcionar no Railway;
rollback restaura o estado anterior, não comprova disponibilidade da API.

Referências primárias: [rede privada Railway](https://docs.railway.com/networking/private-networking/how-it-works),
[resolver oficial](https://github.com/nginx/docker-nginx/blob/master/entrypoint/15-local-resolvers.envsh),
[templates oficiais](https://github.com/nginx/docker-nginx/blob/master/entrypoint/20-envsubst-on-templates.sh),
[proxy e herança de headers](https://nginx.org/en/docs/http/ngx_http_proxy_module.html),
[proxy headers Uvicorn](https://www.uvicorn.org/settings/#http).
