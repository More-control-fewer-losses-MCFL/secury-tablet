# Estado da engenharia — Secury Tablet

## Integração autorizada em main — 2026-11-13

Pedido explícito do usuário: “de merge na main”. Integração funcional concluída.

- PR [#14](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/14) integrado em `main` por
  [c7a8d3d](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/commit/c7a8d3ded48576b3e029e06df750e413ee0c3297):
  acesso institucional, logotipo SENAI e portais professor/admin.
- PR [#15](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/15) teve base alterada da branch do #14 para `main`
  e foi integrado por [0138c06](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/commit/0138c069661c33b341f29a30215b1922556f1852):
  credencial individual de professor e migração Alembic 0004.
- Heads conferidos antes dos merges: e08b5b1 e 42307ea. Jobs unit, mysql, flutter
  e docker aprovados em ambos: [CI #14](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/actions/runs/43495926122),
  [CI #15](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/actions/runs/43517103551).
- Merges explícitos com SHA esperado; sem habilitar auto-merge ou ignorar proteções.
  Árvore final de `main` conferida igual à do head validado 42307ea.

Main funcional desta integração: `0138c069661c33b341f29a30215b1922556f1852`.
Registro documental separado, sem alteração funcional. CI pós-merge acompanhado em
[Actions da main](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/actions?query=branch%3Amain); o resultado final deve ser
conferido no head vigente, distinguindo-o do CI dos PRs e de execuções intermediárias.
Validação local anterior: 130 unitários, 28 integrações em MySQL isolado, 24 Flutter,
análise/build Web e Ruff aprovados; não reexecutados neste merge sem mudança de código.

Clone local sincronizado por fast-forward; `.env`, segredos, dados e serviços
preservados. Nenhum deploy, custo, importação ou comando de hardware executado.
Conta professor.demo continua somente na demonstração local isolada; não está
embutida no repositório nem será criada automaticamente ao hospedar. Notion não alterado.
Aceite assistivo, homologação física e preparo do Render continuam pendentes.

Próximos três itens:
1. Preparar a configuração do Render para frontend, API e MySQL persistente.
2. Aplicar Alembic 0004 e criar credenciais no banco hospedado quando o deploy for autorizado.
3. Concluir aceite de teclado/leitor de tela e validação física no escopo apropriado.

## Histórico anterior ao merge dos PRs #14 e #15

## Professor por usuário e senha — 2026-11-13

Estado: em revisão. Branch `feat/professor-password-login`, base e08b5b1,
dependente do PR #14 (`feat/professional-access-screen`), main remota 8716f5c.
Pedido explícito do usuário autoriza senha individual; ADR 0002 complementa RFID.
Login verde de professor, credencial gerenciada pelo admin, sessão assinada revogável
por redefinição e sem requisito de cookie do terminal no modo senha. RFID preservado.
MySQL/Alembic 0004 adiciona tabela opcional de credenciais scrypt; nenhum segredo no
Flutter ou no Git. Retirada deriva o cadastro da sessão; perfis/ownership mantidos.

130 unitários Python e 28 integrações MySQL aprovados; Ruff check/format e diff aprovados.
MySQL novo/isolado, bancos secury_professor_auth_test e secury_professor_demo_test,
credenciais exclusivas. Migração, FK, unicidade, reset e persistência validados.
Flutter 3.47.8: análise sem problemas, 24 testes e build Web aprovados; tela real em
1440px/390px conferida. Casos cobrem sessão, erros, escopo, ausência de UID e admin.
Smoke real via prévia: login/sessão 200, senha inválida 401, admin/inventário negados.
Conta `professor.demo`, Professora Ana (demo)/DEMO-001 criada só no runtime isolado.
Senha gerada em arquivo privado no perfil do usuário, fora do workspace/Git/logs.
Prévia 8082 usa API isolada; banco/API anteriores preservados, `.env` não alterado.
Sem retirada real ou hardware físico; sem produção, merge ou atualização do Notion.
Aviso Starlette/httpx preexistente. CI e aceite assistivo pendentes; PR referenciado abaixo.
Guia/BDD: docs/professor-password-login.md. Decisão: docs/adr/0002-professor-password-login.md.

Próximos três itens:
1. Revisar PR dependente de #14 e conferir CI do head publicado.
2. Confirmar aceite do login/cadastro de credencial em ambos os perfis e teclado.
3. Planejar integração das migrações/HTTPS conforme ambiente, sem homologação física implícita.


## Portais personalizados por perfil — 2026-11-13

Estado: em revisão. SEC-004/SEC-007, branch `feat/professional-access-screen`,
continuação do PR [#14](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/14) para `main` (8716f5c confirmado no remoto).
Interface autenticada personalizada por perfil: professor em verde e administrador
em azul SENAI (#075DA8). Referência verde #3A9988; cabeçalho #2C8375 e ações #17695D
preservam contraste com branco. Estados de aviso/erro mantêm significado próprio.
Desktop usa menu superior com ícones; celular/texto ampliado mantém drawer e atalhos
inferiores do professor. Boas-vindas mostram nome/perfil/matrícula reais, resumo da
API e atalhos permitidos. Cartões claros organizam disponibilidade, movimentos,
patrimônio e ocorrências existentes; não cria notícias, agenda ou dados fictícios no app.
Logotipo SENAI padrão preservado. Autenticação, API, regras e permissões não alteradas.

Validação: Flutter 3.47.8, analyze sem problemas, 20 testes aprovados e build Web
release concluído. Cobertura: portais desktop 1440px dos dois perfis, navegação por
rota/permissão, mobile 360px/texto 1,5x, fluxos administrativos e contraste >=4,5:1.
Quatro prévias adicionais de professor/admin em desktop/celular com dados fictícios
foram renderizadas e conferidas; arquivos temporários fora do Git.
A validação revelou uma falha de layout ao recriar ThemeData por navegação;
temas agora são reutilizados por perfil. Os cenários móveis passaram após a correção,
sem suprimir assertions nem aplicar retries para encobrir a falha.
Prévia local http://localhost:8082 atualizada; página e API health HTTP 200.
`git diff --check` aprovado. Python/MySQL não reexecutados: mudança somente Flutter.
CI remoto do novo head e aceite assistivo manual pendentes. Sem merge ou produção.
Hardware simulado, `.env`/dados reais preservados; Notion não alterado.

Próximos três itens:
1. Conferir CI do PR #14 no head publicado e revisar para main.
2. Realizar aceite manual de teclado/leitor de tela e confirmar as cores por perfil.
3. Validar jornada real controlada de cadastro/terminal, mantendo hardware simulado.


## Padronização da marca SENAI — 2026-11-13

Estado: em revisão. Continuação de SEC-004 na branch `feat/professional-access-screen`,
PR [#14](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/14) em rascunho para `main` (base remota 8716f5c confirmada).
Substituição de todas as marcas visuais SENAI do Flutter pelo logotipo branco
da referência: painel de acesso desktop, login móvel e menu lateral/drawer dos
perfis professor e administrador. `BrandMark` usa um único WebP local original do
AVA SENAI/SC, com proporção preservada, descrição semântica e fundo azul em área clara.
Removido o escudo com texto genérico da marca. Nenhum login/permissão foi alterado.
Fonte e SHA-256 registrados em `frontend_flutter/assets/branding/README.md`.

Validação desta troca: analyze sem problemas, 17 testes Flutter existentes aprovados,
build Web release e `git diff --check` aprovados. Capturas Chrome desktop 1440px e
celular 390px conferidas; testes abrangem 360px/texto 1,5x e menus por perfil.
Prévia http://localhost:8082 atualizada; imagem empacotada responde HTTP 200.
Sem novo teste para imagem estática, nova dependência ou chamada de rede para a marca.
Python/MySQL não reexecutados nesta troca estática; sem backend/schema alterado.
CI remoto/aceite assistivo manual pendentes. Sem merge, produção ou hardware físico.
Notion não alterado; `.env` e dados reais preservados.

Próximos três itens:
1. Conferir CI do head atualizado no PR #14.
2. Revisar marca e navegação assistiva em desktop/celular.
3. Validar jornada de crachá com cadastro/terminal autorizado no ambiente de testes.


## Tela de acesso institucional — 2026-11-13

Estado: em revisão. Branch `feat/professional-access-screen`, base `main`
`8716f5c557dcf6902c73d45cc3b79d18efcd22e7`, confirmada no remoto nesta sessão.
Clone selecionado: raiz do workspace; clone aninhado não encontrado nesta sessão.
SEC-004: acesso com cadastro administrativo em destaque, painel azul/branco inspirado
na referência e área “Passe o crachá” para o fluxo de professor. Sem acesso Google.
Backend, sessão assinada, autorização do terminal e perfis preservados.
Detalhes/BDD: [frontend-ux.md](frontend-ux.md).
Validação local: Flutter 3.47.8/Dart 3.13.7 em Docker, analyze sem problemas,
17 testes Flutter aprovados e build Web release concluído. 109 testes unitários
Python aprovados com `.venv/Scripts/python.exe`; aviso Starlette/httpx preexistente.
`git diff --check` aprovado. Sem Python alterado: Ruff não se aplica ao diff.
Integração MySQL não executada nesta alteração de interface.
Capturas desktop/crachá em 1440px e celular real em 390px conferidas no Chrome
headless com perfil isolado; testes cobrem 360px/texto 1,5x e fluxos em 1440px.
Prévia local separada em http://localhost:8082; página/healthz e API health HTTP 200.
Build e capturas temporários fora do Git. Não houve login com credenciais reais.
Aceite assistivo manual e CI remoto pendentes: estado em revisão.
Implementação: [7172693](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/commit/71726938c2fd4685e9f5e728941ac041cd291ee8);
PR [#14](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/14) em rascunho para `main`, sem dependências pendentes. CI a conferir. Sem deploy em produção ou merge.
Sem alteração de banco, `.env`, credenciais reais ou hardware. Notion não alterado.

Próximos três itens:
1. Conferir CI e revisar PR para main, sem merge automático.
2. Realizar aceite assistivo manual de teclado/leitor de tela.
3. Validar jornada de cadastro/crachá em terminal autorizado; hardware segue simulado.


## Histórico anterior à revisão de acesso

Atualizado em 2026-11-12 (America/Sao_Paulo). Estado: em revisão.
Branch atual: feat/SEC-007-integration-review, baseada em
feat/terminal-rfid-authorization (árvore compatível com feat/docker-full-stack).
Commits funcionais examinados: 0138744 (locks), f3ffee8 (autorização),
581b8dc (navegação da autorização do terminal). Main observada: 14002e6;
base desta entrega: 8fb19a9 (árvore compatível com 76e32a4).
Versão VERSION: 1.2.0; metadados Python/FastAPI ainda indicam 0.1.0 (débito conhecido).

## Preparação de integração em main — 2026-11-12

O usuário autorizou explicitamente o merge para main. Cadeia revisada: PR #11
(perfis), #12 (cadastro Sheets) e #13 (interface). Não ativar auto-merge do GitHub;
executar merges explícitos somente depois de conferir checks e SHAs remotos.

Falha remota investigada nos três PRs: canal stable resolveu Flutter 3.50.0 e
analyze recusou os imports Material depreciados. Python e MySQL aprovados.
CI agora fixa Flutter 3.47.8, alinhado ao Docker e à validação local; não houve
supressão de avisos nem retry sem investigar. Correção publicada nas dependências.
Os novos checks precisam ser conferidos antes da integração de cada PR.

Esta seção registra a preparação; a confirmação do merge e do CI pós-merge deve
ser verificada no GitHub. Continuam pendentes a aba Professores no Google e o
aceite assistivo/manual. Não houve importação de dados reais ou mudança de hardware.

## Revisão da interface Flutter — 2026-11-12

Branch `feat/frontend-clarity-accessibility`, base 827b326 (integração Sheets/PR #12).
Tema e componentes consistentes; login prioriza formulário no celular; menu por
perfil agrupado, drawer corrigido e atalhos inferiores do professor; painel com
métricas reais; totem, retirada/devolução e consulta de professor responsivos.
Corrige estado vazio indevido da retirada quando available > 0 e tablets vazio.
Preserva rotas, confirmação de operações, sincronização e autorização backend.
Ilustração nativa reutilizada, ícones explicativos, contraste e áreas de toque
reforçados. Sem nova dependência, alteração de banco ou hardware físico.

Flutter Analyze sem problemas; 17 testes aprovados, incluindo navegação em
360/1440px com texto1,5x e contraste; Build Web concluído. Três prévias com dados
fictícios inspecionadas. Validação assistiva manual/CI pendentes: em revisão.
Guia em frontend-ux.md. Interface local atualizada em 8081; página, health e bootstrap HTTP 200. PR a publicar.

## Integração de cadastro Google Sheets — 2026-11-12

Branch feat/google-sheets-professor-sync, dependente da revisão SEC-004 do PR #11.
Importação manual administrativa da aba Professores, sem usar leituras RFID como
permissão. Atualiza cadastro MySQL por matrícula, preservando ID/histórico;
validação estrita, idempotência e rollback de todo o lote em caso de conflito.
Botão de sincronização na área administrativa; credenciais apenas no servidor.

109 testes Python, Ruff, Flutter Analyze, 12 testes Flutter e build Web aprovados.
Credenciais fornecidas validaram OAuth/read com HTTP 200. Criação da aba vazia foi
recusada com 403; o proprietário precisa criar Professores e preencher os dados.
Nenhum cadastro real importado. Sem migração; MySQL local desta revisão, CI e
aceite real pendentes. Estado em revisão. Guia em google-sheets-professors.md.

## Revisão SEC-004 — 2026-11-12

Branch `feat/SEC-004-separate-role-access`, base `origin/main` em 1d87ba0
(SEC-007 já integrado por outra ação no PR #10). Logins Flutter separados por
rota: professor `/#/login`, administrador `/#/admin/login`. Professor acessa
apenas início pessoal, totem, retirada, devolução e próprio histórico; agenda
sem agendamento real não é mais exposta nesse perfil. API de disponibilidade
omite detalhes individuais do patrimônio para professor e mantém-os para admin.

90 unitários Python aprovados; Ruff/formatação dos 3 Python alterados e diff
aprovados. Flutter analyze, 11 testes e build Web aprovados em Docker. Sem novas
migrações ou alteração de dados reais; hardware simulado. Integração MySQL local,
CI remoto e aceite visual manual pendentes nesta revisão. Estado em revisão.
Documentação em role-access-mobile.md; PR [#11](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/11) em rascunho, sem merge automático.
Runtime local atualizado em localhost:8081, API/web saudáveis; smoke HTTP e acesso administrativo aprovados. Commit funcional 505490a.

## Atualização SEC-007 — 2026-11-05

Branch `feat/SEC-007-integration-review`, PR em rascunho
[#9](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/9),
base `feat/terminal-rfid-authorization` (8fb19a9); main observada em 14002e6.
Totem, central de alertas e dashboard implementados, conciliando SEC-004 e
preservando alterações locais. Rotas, serviços, repositórios e schemas separados.
Professor bloqueado no monitoramento e no inventário completo. Sem schema novo.

Pacote encontrado em Downloads, extraído fora do projeto. --check retornou 2
por contexto main.py já integrado/formatado; reconciliação manual, sem --apply.

Validação concluída: 88 unitários Python, Ruff src/tests, formatação dos 9 Python
alterados, diff --check; Flutter 3.47.8 em Docker com analyze, 10 testes e build Web.
Oito cenários adicionais de monitoramento executados em MySQL 8.4 novo e isolado:
migrações até 0003 aprovadas, autenticação/contagem/ordenação/redação/limites
aprovados. Usados dados fictícios e rollback por cenário, sem DROP/TRUNCATE.
Contêiner sec007-review-5f708f3d parado e preservado, sem tocar bancos existentes.
A suíte completa de integração local não foi executada; CI cobre sua configuração.
Aviso preexistente Starlette/httpx permanece.

Push concluído pela autenticação Git local. Conector GitHub continua com 403
para escrita; PR aberto via API com a credencial Git em memória, sem exposição.
CI Quality iniciado no PR; resultado final a conferir. Jornada visual manual e
homologação física pendentes. Hardware continua simulado; sem deploy ou merge.
Estado: em revisão. Notion não alterado.

## Arquitetura e escopo

Monólito modular Python 3.12/FastAPI, SQLAlchemy 2, MySQL 8.4 e Alembic;
Flutter Web 3.47.8/Dart 3.13.7; Streamlit adicional preservado no código.
Hardware continua simulado. Equipamentos e protocolo real serão definidos em sala.
Não houve homologação física nem exposição pública.

## Entregas atuais

| Item | Resultado | Revisão |
|---|---|---|
| CI-001 | Ordem de locks armário antes de sessão; sem repetir comandos físicos | PR #6, commit 0138744 |
| SEC-002/003 | Terminal autorizado pelo admin, RFID sem senha, sessão curta e ownership | PR #7, commits f3ffee8/581b8dc |
| DOCKER-001 | Flutter/Nginx + API + migrações + MySQL persistente; início por script | PR #8, commit inicial 2746808 |

PRs: [#6](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/6),
[#7](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/7),
[#8](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/8).
São mudanças empilhadas: main → #6 → #7 → Docker. Nenhum merge executado pelo Codex.
O PR #4 antigo foi integrado apenas na branch de hardware; #7 implementa a proteção
do inventário manual na cadeia atual de entrega, junto do controle por proprietário.

## Evidências

- 78 testes unitários Python aprovados; Ruff check/format dos Python alterados aprovado.
- 25 integrações locais MySQL aprovadas, incluindo 20 cenários concorrentes.
  Somente armario_tablets_test foi limpo; banco demo preservado.
- Flutter analyze sem problemas; 6 testes Flutter aprovados; build Web Linux no Docker concluído.
- Docker Compose config válido, migração 0003 concluída e db/api/web saudáveis.
- HTTP /, /healthz, /api/health, /api/docs e /api/openapi.json respondendo 200.
- Smoke: login admin, autorização de terminal, RFID sem senha, acesso ao próprio
  histórico, bloqueio de retirada por outro professor e inventário manual,
  revogação e recusa da sessão revogada aprovados.
- API como UID 10001, nginx -t aprovado, API recuperada após restart.
- Backup anterior à migração restaurado no schema descartável
  secury_restore_1793198766_test: 4 professores e 10 tablets conferidos.
- Inventário demo de 10 tablets preservado; nenhuma retirada criada pelo smoke test.
- CI de #6 (40706716082) e primeira revisão de #7 (40708316632) aprovado.
  Revisões posteriores e job Docker devem ter seus resultados remotos conferidos.

## Uso local

[Aplicação](http://localhost:8080), [Swagger](http://localhost:8080/api/docs).
Na raiz: `.\scripts\start_local.ps1`; `-Demo` somente se desejar dados falsos.
.env existente e senha de teste preservados por solicitação do PO.
No login admin marcar **Autorizar este terminal e voltar ao RFID**, autenticar e
então usar crachá de professor (demo DE000001). Admin usa ADMIN_PASSWORD do .env.
Serviços anteriores 8000/8501/8502 encerrados após a stack ficar disponível.
Pasta não rastreada secury-tablet/ preservada, fora de todos os commits/contextos.

## Limites e próximos itens

RFID-only foi escolha explícita do PO. UID copiado pode personificar alguém no
terminal autorizado: não há autenticação forte do portador (ADR 0001).
Autorização do terminal é revogável; cookie e Bearer roubados são risco até revogação
ou expiração. HTTPS e cookie Secure necessários fora do loopback; não configurados.
Proteção completa contra replay e credenciais por dispositivo dependem do protocolo
real. Streamlit não faz parte da stack protegida e não deve ser exposto paralelamente.
Cadastros/edição de professores, agenda futura e integrações externas continuam
limitados ao que a API já oferece; não foram declarados completos neste ciclo.
Aviso de depreciação Starlette/httpx permanece na suíte Python.

Prioridades: revisar/integrar a cadeia de PRs com CI aprovado; homologar adaptadores
e equipamentos em sala conforme hardware-sala.md; validar requisitos restantes da
primeira versão e proteção HTTPS para eventual acesso em rede.
Notion não alterado. Evidência e instruções em coordination/CODEX_HANDOFF.md.

Integração Google Sheets: commit 66cf422; PR [#12](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/12) em rascunho sobre a branch do PR #11. Credenciais privadas não versionadas; aba e CI pendentes, sem merge.

Revisão visual: commit a07204f; PR [#13](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/13) em rascunho sobre feat/google-sheets-professor-sync (dependência PR #12). Runtime local atualizado; CI remoto e aceite assistivo manual pendentes. Sem merge.

Commit da marca: [3d28117](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/commit/3d2811745842232e48321b2c2713e73253db4725), incluído no PR [#14](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/14).

Commit dos portais: [5328625](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/commit/5328625785cdc134468f532cb563f4f7c7f82ab8), PR [#14](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/14) para main.

Implementação: [c9e3c01](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/commit/c9e3c0136cb19a032df153b3b60839846b5e9ada); PR [#15](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/15) em rascunho para feat/professional-access-screen. Sem merge; CI a conferir.
