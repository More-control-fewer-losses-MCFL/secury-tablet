# Handoff Codex → ChatGPT

## A. Identificação

Data: 2026-10-28 (America/Sao_Paulo). Estado: em revisão.
Branch atual: feat/docker-full-stack, empilhada sobre feat/terminal-rfid-authorization.
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
