# Handoff Codex → ChatGPT

## A. Identificação

Data: 2026-11-05 (America/Sao_Paulo). Estado: em revisão.
Branch atual: feat/SEC-007-integration-review, criada sobre
feat/terminal-rfid-authorization (árvore compatível com feat/docker-full-stack).
Commits: 0138744 (CI-001), f3ffee8 (SEC-002/003), 581b8dc (navegação de enrollment).
Issues não criadas; IDs locais preservados. PRs:
[#6](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/6) para main,
[#7](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/7) sobre #6.
Docker: [PR #8](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/8)
sobre #7, commit inicial 2746808. Codex não executou merges.
Objetivo: corrigir concorrência, proteger operações preservando RFID-only e entregar
execução local em Docker; hardware será montado em sala. Senha de teste mantida.

## B. Desenvolvimento realizado

- CI-001: CheckoutRepository adquire armário antes da sessão em caminhos mutantes;
  professor carregado separadamente. Removida inversão causadora do deadlock 1213.
- SEC-002/003: novo operational_auth.py, rotas terminal/RFID e modelo/migração 0003
  terminal_authorizations. Cookie Strict/HttpOnly de 8h revogável no MySQL, Bearer
  professor de 10min vinculado ao terminal; cadastro ativo revalidado em cada acesso.
- Rotas de histórico, retirada, devolução, cadastro e tablets protegidas; professor
  opera em seu nome e concilia próprias sessões; present_tags manual exige admin.
- Flutter usa cookies no navegador, Bearer em memória, expiração e opção de admin
  para autorizar terminal e retornar ao RFID sem abrir painel administrativo.
- Dockerfiles API/Flutter/Nginx, .dockerignore e Compose com migrações/healthchecks;
  script start_local.ps1 preserva .env, gera configuração se ausente e seed é opt-in.
- Nginx encaminha /api na mesma origem, limita login e omite logs com UIDs.
  API não publica porta no host e usa UID 10001. Segredos fora das imagens.
- README, docs/docker.md, docs/hardware-sala.md, PROJECT_STATUS e ADR 0001 atualizados.
  Contratos físicos documentados, sem implementar protocolo de equipamento desconhecido.

## C. Validação

Python do .venv: pytest tests/unit -q (78 aprovados), pytest tests/integration -q
com URL segura explícita (25 aprovados, incluindo 20 cenários concorrentes).
Ruff check e format --check aprovados nos Python alterados.
Flutter analyze sem problemas, flutter test: 6 aprovados; build Web Linux no Docker.
Compose config --quiet e up -d --build --wait aprovados; migração 0003 exit 0.
MySQL, API e Web saudáveis; nginx -t aprovado; UID da API verificado como 10001.
Smoke real via Nginx: interface, health, Swagger/OpenAPI, admin, terminal, RFID,
recusa de operações cruzadas/manual e revogação aprovados. Sem criar retirada demo.
API reiniciada e recuperada com banco disponível. Backup local restaurado em
secury_restore_1793198766_test: 4 professores/10 tablets; banco demo intacto.
CI #6 run 40706716082 e primeira revisão #7 run 40708316632 passaram; conferir
revisões posteriores e job Docker. Testes físicos e HTTPS não executados.
Aviso Starlette/httpx permanece. Não alegar homologação de produção.

## D. Segurança e qualidade

PO respondeu **apenas o RFID** à escolha de autenticação. Decisão explícita no
ADR 0001: terminal supervisionado, não autenticação forte do portador. UID copiado
ainda funciona no terminal autorizado. Cadastro/ownership são verificados no servidor.
Terminal e professor não substituem token admin; hardware usa chave separada.
Sem migração destrutiva nem reset de dados. Nova tabela só controla revogação.
.env e senha de teste preservados; nenhuma credencial real publicada.
Nenhum leitor/fechadura física acionado. Proteção ampliada contra replay depende
protocolo futuro. Stack limitada ao loopback; HTTPS e cookie Secure fora dele.
Serviços legados sem as novas proteções foram encerrados em 8000/8501/8502 após
validar Docker em 8080. Clone aninhado preservado, nunca adicionado ao Git.
Regressão de contrato intencional: clientes operacionais precisam Bearer; leitor
HTTP precisa X-Hardware-Key; professores usam RFID após autorização do terminal.

## E. Estado da tarefa

Em revisão. Implementação local validada no escopo simulado. Sem merge pelo Codex,
sem publicação em produção e sem sincronização do Notion. Funcionalidades de
cadastro/edição/agenda além da API existente não foram incluídas implicitamente.

## F. Próximo trabalho recomendado

1. Revisar a cadeia #6 → #7 → Docker, conferir CI e ajustar bases após merges humanos.
2. Levantar equipamentos/protocolo em sala e implementar adaptadores com os critérios
   de hardware-sala.md; testar sensor, falhas, energia, inventário e duplicação.
3. Fechar requisitos da primeira versão (cadastros/agenda/relatórios) e, se houver
   acesso pela rede, planejar HTTPS e revisar ameaças do modo RFID-only.

## G. Mensagem pronta para o ChatGPT

Secury Tablet agora tem correção de locks MySQL, autorização por terminal e dono,
e stack Docker local com Flutter/Nginx, API, migrações e MySQL persistente. Mantido
RFID sem senha por escolha do PO; não afirmar autenticação forte de crachá. Senha
local de teste preservada. Validação: 78 unitários, 25 integrações MySQL, 6 Flutter,
análise e build Web; smoke Docker com login/escopo/revogação e backup restaurado.
Revisar PRs #6/#7 e entrega Docker, PROJECT_STATUS, ADR 0001 e guia físico. Hardware
continua simulado e será construído em sala. Notion ainda não foi atualizado.

## H. Ciclo SEC-007 — 2026-11-05

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
Commits: a4373f4 (implementação), c029d8c (evidências iniciais), 9310114
(rascunho e bloqueio inicial, agora resolvido para push/API Git local).
Descrição: [SEC-007_PR_DRAFT.md](../SEC-007_PR_DRAFT.md).

Próximos três itens:
1. Conferir CI do PR #9 e revisar a base após integrar as dependências.
2. Executar aceite visual manual professor/admin sem alterar dados reais.
3. Homologar hardware e configurar HTTPS antes de acesso pela rede.

## I. Revisão SEC-004 — 2026-11-12

Branch `feat/SEC-004-separate-role-access`, base main 1d87ba0. Mudanças anteriores
SEC-007 já integradas por outra ação pelo PR #10; não executar merge automático.
Acesso professor `/#/login`; admin `/#/admin/login`. Formulários separados por
rota, redirecionamento de professor autenticado ao tentar login administrativo,
menu professor sem agenda não implementada. Retirada/devolução/histórico próprio
mantidos. Disponibilidade da API omite detalhes de patrimônio para professor,
sem sequer carregar esses registros; admin mantém detalhes. Mesma resposta JSON
com tablets vazio para professor. Autorização no backend permanece obrigatória.

90 testes Python, Ruff e format dos 3 Python alterados aprovados. Flutter analyze,
11 testes e build Web aprovados em Docker. Aviso Starlette/httpx preexistente.
Sem migração ou escrita em dados reais, segredos preservados. Hardware simulado.
MySQL local e aceite visual manual não executados nesta revisão; CI remoto pendente; PR [#11](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/11)
publicado em rascunho, commit funcional 505490a. Stack local atualizada em 8081,
API/web saudáveis, smoke HTTP e acesso administrativo aprovados; MySQL existente em 3307; preservar ScadaBR em 8080. Notion não alterado.

Próximos três itens: conferir CI/PR; validar visualmente os dois perfis; homologar
terminal e HTTPS antes de uso fora da máquina. Estado em revisão.

Entradas locais: professor http://localhost:8081/#/login; administrador http://localhost:8081/#/admin/login.

## J. Cadastro Google Sheets — 2026-11-12

Branch feat/google-sheets-professor-sync, base 393abd4 (PR #11 pendente em main).
Fonte confirmada pelo usuário: aba de cadastro, não campo Status de Leituras_RFID.
Professores!A1:D exige registration,name,badge_uid,active. Importação por Bearer
admin em POST /admin/professors/sync-google-sheets e botão Professores/Sincronizar.
Adapter somente leitura, serviço transacional e repositório, sem nova migração.
Google não entra no login: professor precisa de cadastro MySQL ativo e terminal
autorizado. Sincronizar após mudar cadastro; active FALSE bloqueia próximas ações.
Ausência de linha não exclui nem desativa; IDs/histórico preservados, conflitos
não transferem crachás e anulam o lote. Tokens Google nunca seguem para Flutter.

109 unitários Python, Ruff e format, Flutter Analyze, 12 testes e build Web
aprovados. OAuth refresh e leitura Google com credenciais do ZIP: ambos HTTP 200.
Credenciais privadas fora do Git; .env preservado. Fonte sem aba Professores;
tentativa de criar só cabeçalhos via conector recusada com 403, sem mudança.
Nenhum professor real importado. Arquivo de cabeçalho e guia em
[google-sheets-professors.md](../google-sheets-professors.md).
Runtime local atualizado em 8081: interface/API 200, importação anônima 401.
Credencial privada montada somente no backend. Sem migrações; CI, MySQL local e aceite real
pendentes. Notion não alterado. Sem merge automático ou hardware físico.

Próximos três itens: proprietário criar/preencher Professores; sincronizar como
admin e validar jornada controlada; conferir PR/CI e dependência SEC-004.

Integração Google Sheets: commit 66cf422; PR [#12](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/12) em rascunho sobre a branch do PR #11. Credenciais privadas não versionadas; aba e CI pendentes, sem merge.

## K. Interface Flutter — 2026-11-12

Branch feat/frontend-clarity-accessibility sobre 827b326, dependente do PR #12.
Tema com tipografia/espaçamento/contraste consistentes; componentes se adaptam a
texto ampliado. Login móvel começa pelo formulário e mantém orientação de RFID;
menu por finalidade/perfil, atalhos móveis e drawer funcional. Conta professor
não oferece Configurações; notificação admin abre alertas. Dashboard tem métricas
reais e histórico recente; formulários/cartões de retirada, devolução, totem e
consulta fluem em tela estreita. A lista de patrimônio omitida do professor não
é confundida com estoque vazio. Handlers/API/permissões/diálogos preservados.

17 testes Flutter aprovados; Analyze sem problemas, build Web concluído com SDK
3.47.8 em Docker. Novos cenários em 360/1440px e texto1,5x; contraste >=4.5 para
rótulos/status; cancelamentos não enviam POST de negócio. Três prévias renderizadas
inspecionadas (dados fictícios; imagens temporárias fora do Git). Ilustração
LockerIllustration e ícones Material reutilizados; nenhuma dependência adicionada.
Sem alteração de Python/schema, escrita em dados reais ou hardware físico.
CI e avaliação com leitor de tela/teclado reais pendentes; estado em revisão.
Runtime local atualizado em 8081, sem reiniciar API/MySQL. Página, health e bootstrap HTTP 200. Guia frontend-ux.md.
Notion não alterado. PR a publicar, sem merge automático.

Próximos três itens: conferir PR/CI e dependências; aceite assistivo manual;
proprietário preencher a aba de cadastro e validar jornada real controlada.

Revisão visual: commit a07204f; PR [#13](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/13) em rascunho sobre feat/google-sheets-professor-sync (dependência PR #12). Runtime local atualizado; CI remoto e aceite assistivo manual pendentes. Sem merge.
