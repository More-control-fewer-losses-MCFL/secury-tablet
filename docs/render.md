# Publicação manual no Render

Estado: preparação na branch `deploy/render`. A publicação da branch no GitHub
não cria recursos Render nem publica dados. Hardware permanece simulado; Streamlit e seed de
demonstração não fazem parte desta implantação.

## Arquitetura e planos propostos

O [Blueprint](../render.yaml) define três serviços Docker na região `virginia`:

| Serviço | Plano | Função |
| --- | --- | --- |
| `secury-tablet-web` | `0.5c-512mb` | Web público: Nginx, Flutter e proxy `/api` |
| `secury-tablet-api` | `0.5c-512mb` | FastAPI privado; Alembic no pre-deploy |
| `secury-tablet-mysql` | `1c-2g` | MySQL 8.4 privado; disco de 10 GB em `/var/lib/mysql` |

São tamanhos iniciais a conferir com métricas. A região não pode ser trocada depois
da criação do serviço. O MySQL é autogerenciado: a equipe mantém versão, patches,
capacidade, monitoração, backups e restauração. O disco só pertence à instância do
MySQL e impede deploy sem interrupção; não o monte na API ou no Web. A imagem
[mysql.Dockerfile](../docker/mysql.Dockerfile) não cria banco `_test` nem carrega demo.
As dependências Python de execução e teste estão fixadas em
[`requirements.lock`](../requirements.lock) e
[`requirements-dev.lock`](../requirements-dev.lock); o backend de build
`setuptools` também está fixado. Atualizar os locks deliberadamente e repetir
builds/testes antes de um deploy manual.

O Flutter é compilado com `API_BASE_URL=/api`. O navegador usa o mesmo domínio HTTPS
do Web; Nginx remove o prefixo `/api` e encaminha ao endereço privado da API obtido
do Blueprint. `API_UPSTREAM` contém apenas host e porta; a API declara `PORT=8000`
para o endereço interno corresponder à porta em que escuta. `PUBLIC_SCHEME=https`
encaminha o esquema externo correto mesmo com TLS terminado no Render. O Nginx
mantém limites de login/RFID usando `CF-Connecting-IP` quando
`TRUST_CF_CONNECTING_IP=true` no Render; no Compose local usa o IP da conexão.
O Render informa que o Cloudflare sobrescreve esse cabeçalho, enquanto o
primeiro endereço em `X-Forwarded-For` pode ser falsificado pelo cliente.
O Nginx encaminha à API somente o IP já selecionado em `X-Forwarded-For`
e `X-Real-IP`. Não publique a API privada diretamente para contornar os limites.

O cookie do terminal usa `HttpOnly`, `SameSite=Strict` e `Secure` com
`SESSION_COOKIE_SECURE=true`; a revogação envia a exclusão com os mesmos atributos.
O logout administrativo no Flutter descarta o bearer token do navegador; como o
token é assinado e sem lista de revogação, ele ainda seria válido até expirar se
alguém já possuísse uma cópia. A autorização do terminal persiste até revogação ou
expiração, independentemente do logout administrativo.

## Variáveis por serviço

O YAML contém nomes, valores não secretos e referências entre serviços. Não copie
o `.env` local para o Render nem coloque segredos no Flutter ou em `render.yaml`.

| Serviço | Variáveis |
| --- | --- |
| Web | `PORT` (exemplo `10000`), `API_UPSTREAM` (referência interna), `PUBLIC_SCHEME` (`https`), `TRUST_CF_CONNECTING_IP` (`true`) |
| API | `PORT` (`8000`), `MYSQL_HOST` (referência interna), `MYSQL_PORT` (`3306`), `MYSQL_DATABASE` (exemplo fictício `tablets_prod`), `MYSQL_USER` (exemplo `tablets_app`), `MYSQL_PASSWORD` (referência ao MySQL), `ADMIN_USERNAME`, `ADMIN_PASSWORD`, `ADMIN_TOKEN_SECRET`, `HARDWARE_API_KEY`, `HARDWARE_SIMULATED`, `SESSION_COOKIE_SECURE`, `CORS_ALLOWED_ORIGINS`, `GOOGLE_SHEETS_ENABLED`, `CABINET_CODE` |
| MySQL | `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD` |

`ADMIN_PASSWORD` é solicitado no primeiro sync (`sync: false`), com pelo menos 12
caracteres. `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `ADMIN_TOKEN_SECRET` e
`HARDWARE_API_KEY` são gerados pelo Render; a API referencia a senha do MySQL sem
duplicá-la no arquivo. Não reutilize a senha administrativa como chave do hardware.
O administrador inicial é configurado por `ADMIN_USERNAME`/`ADMIN_PASSWORD`; não há
usuário administrativo a semear no banco. `CORS_ALLOWED_ORIGINS` fica vazio porque
o Flutter usa `/api` na mesma origem. `TEST_DATABASE_URL` é apenas para testes.

Google Sheets permanece desligado. Se for habilitado, `GOOGLE_SHEETS_TOKEN_FILE`
deve apontar para um Secret File do Render em `/etc/secrets/`; conferir permissões
de leitura pelo usuário não privilegiado da API antes disso. O token não usa disco
persistente da aplicação.

## Preparação e primeiro sync no painel

1. Revisar o diff, CI, custo e configuração do [Blueprint](../render.yaml). A
   branch `deploy/render` precisa existir no remoto antes do primeiro sync.
   O workflow de qualidade roda no push dessa branch, sem acionar o
   Render. Escolher a região antes da criação; os três serviços precisam ficar
   no mesmo workspace e região.
2. No painel Render, criar o Blueprint apontando para `render.yaml` e para a branch
   `deploy/render`. Conferir os três serviços, planos e disco no preview. Informar
   `ADMIN_PASSWORD` no campo privado; não usar dados do `.env` local sem decisão
   explícita sobre separação de ambientes. O primeiro sync cria recursos pagos e
   dispara deploys: executá-lo somente após aprovação.
3. Na página **Settings do Blueprint**, ajustar **Auto Sync = No**. Em cada serviço,
   conferir **Auto-Deploy = Off**. O YAML declara `autoDeployTrigger: "off"` nos
   três serviços, mas Auto Sync do Blueprint é outro controle e precisa ser
   desligado no painel. Para alterações futuras do YAML, usar **Manual Sync** após
   revisão; para código, **Manual Deploy** do commit revisado.
4. Esperar o MySQL ficar pronto. O primeiro sync pode iniciar builds em paralelo;
   se o pre-deploy da API falhar por banco ainda indisponível, verificar a causa e
   fazer Manual Deploy da API depois de o MySQL aceitar conexões. Não limpar o
   disco. Publicar o Web manualmente depois da API. Confirmar `alembic current`
   em `head` antes de aceitar tráfego.
5. Verificar HTTPS, `/healthz` (Web), `/api/health` (banco `ok`), `/api/docs`, login admin, emissão e
   revogação do cookie de terminal, logout do Flutter, negação 401 sem sessão e
   limites 429 por cliente em ambiente controlado. Confirmar que o proxy
   recebe `CF-Connecting-IP`; se ausente, os clientes podem compartilhar o
   mesmo limite. Conferir `Secure`, `HttpOnly` e `SameSite=Strict` no navegador.
   Não usar hardware real nem seed de demo.

Render não executa o `docker-compose.yml` no Blueprint. O serviço MySQL de
produção não monta `docker/init/01-init-test-db.sh`. `MYSQL_ROOT_PASSWORD` serve
somente à inicialização/manutenção do MySQL; mudar a variável depois de criado o
volume não altera automaticamente as credenciais gravadas nele.

## Migrações, backup e recuperação

O pre-deploy da API executa `python -m alembic upgrade head` em instância separada.
Antes de **cada** deploy manual posterior da API que inclua migração:

1. Produzir um dump consistente no Shell do serviço MySQL:
   `secury-mysql-backup backup /tmp/armario_PRE_DEPLOY.sql`. O utilitário usa a
   conta MySQL da aplicação, `--single-transaction` e `--quick`; não mostra senhas.
   Durante operações críticas, parar escritas ou validar que todas as tabelas de
   negócio são InnoDB. O dump pode conter dados pessoais e deve ser privado.
2. Copiar o arquivo para armazenamento **fora do serviço e do disco MySQL** antes
   de iniciar o deploy. Para uma cópia manual, usar o endereço SSH do serviço no
   painel e SCP/SFTP, conforme a [orientação do Render](https://render.com/docs/disks#transferring-files),
   para trazer o dump a uma máquina segura e então enviá-lo ao destino externo
   escolhido. Confirmar tamanho/hash, retenção e possibilidade de recuperação.
   O diretório `/tmp` é efêmero. A escolha do armazenamento externo,
   credenciais, agendamento e política de retenção ainda está **pendente**.
3. Restaurar uma cópia em outro MySQL 8.4 descartável, em banco já criado, vazio,
   com nome terminado em `_test` e credenciais exclusivas:
   `secury-mysql-backup restore-test /tmp/armario_PRE_DEPLOY.sql armario_restore_test`.
   O comando recusa bancos sem esse sufixo, origem igual ao destino e destino com
   tabelas. Conferir tabelas, `alembic_version` e uma leitura representativa.
4. Só então iniciar o deploy manual da API. Se o pre-deploy falhar, registrar o
   erro e inspecionar o estado do esquema antes de repetir ou reverter o código.
   DDL do MySQL não é transacional; uma migração pode deixar alterações parciais.
   Não usar `docker compose down -v`, apagar disco ou restaurar snapshot de disco
   como método de recuperação de banco. Recuperação exige dump validado e plano de
   indisponibilidade; preservar o banco afetado para investigação.

O [script antigo](../scripts/backup_database.py) é apenas local: depende do nome
`armario_tablets_db` e grava em `backups/`. O utilitário novo foi preparado e
testado localmente em MySQL isolado. **Backup externo ainda não foi validado**:
faltam testar envio, recuperação e restauração de um arquivo vindo do destino
escolhido. Isso impede considerar a publicação com dados importantes pronta.

## Estimativa mensal e custos variáveis

Preços oficiais consultados em 19/11/2026 na
[página de preços do Render](https://render.com/pricing):

| Item | Cálculo | Estimativa USD/mês |
| --- | ---: | ---: |
| Web `0.5c-512mb` | 1 × US$ 7 | US$ 7,00 |
| API `0.5c-512mb` | 1 × US$ 7 | US$ 7,00 |
| MySQL `1c-2g` | 1 × US$ 25 | US$ 25,00 |
| Disco MySQL 10 GB | 10 × US$ 0,25/GB | US$ 2,50 |
| **Base dos três serviços** | | **US$ 41,50/mês** |

Não inclui **armazenamento externo de backups**, transferência, eventual job de
backup, excedentes de banda/minutos de build, domínios extras, impostos ou plano
de workspace pago. São custos variáveis ou dependentes da escolha do fornecedor.
Os serviços são cobrados proporcionalmente ao tempo de uso; verificar os preços e
o preview do Blueprint novamente antes do primeiro sync. A capacidade MySQL de
2 GB e o disco de 10 GB precisam ser validados com métricas reais. O disco pode
ser aumentado, mas não reduzido depois.

Fontes de operação: [Blueprint e Auto Sync](https://render.com/docs/infrastructure-as-code),
[especificação do Blueprint](https://render.com/docs/blueprint-spec),
[pre-deploy](https://render.com/docs/deploys),
[MySQL no Render](https://render.com/docs/deploy-mysql),
[limites de disco e snapshots](https://render.com/docs/disks),
[segredos Docker](https://render.com/docs/docker-secrets),
[IP real e cabeçalho confiável no Render](https://render.com/articles/host-pocketbase-on-render).
