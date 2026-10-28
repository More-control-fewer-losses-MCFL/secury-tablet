# Handoff Codex → ChatGPT

## A. Identificação

- Data: 2026-10-28 (America/Sao_Paulo).
- Branch documental: docs/operational-authorization-review, base 23578bc.
- Commits implementados: 4119b65 (hardware/CI), 4e9946e (inventário manual).
- Issues: não criadas; IDs locais SEC-001, CI-001, SEC-002 e SEC-003.
- PRs: [#3](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/3),
  [#4](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/4).
- Objetivo: revisar trabalho local, publicar correções pequenas e registrar baseline confiável.

## B. Desenvolvimento realizado

PR #3 cria security.py, database_safety.py, testes de credenciais/banco e quality.yml;
altera eventos/configuração, fixtures, testes API, .env.example e documentação.
Corrigidos imports/formatação Ruff e instruções de testes ainda em PostgreSQL.
PR #4 altera returns.py e teste de fluxo API, cria test_return_authorization.py e
documenta autorização de present_tags. Reutiliza sessão administrativa existente;
listas vazias também exigem autorização. Omitido/null mantém leitura do servidor.
Entrega documental cria AGENTS.md, PROJECT_STATUS.md, este handoff e revisão de rotas.
Não há decisão arquitetural nova aprovada; docs/arquitetura.md permanece referência.
Diretório docs/adr é reservado a decisões futuras, sem ADR artificial neste ciclo.

## C. Validação

Usado Python do .venv do clone pai (o clone aninhado estava limpo em main).
Comando: `.venv/Scripts/python.exe -m pytest -q`: 56 aprovados no #3, 64 no #4;
6 integrações puladas em ambas. Ruff check e format --check nos arquivos Python
alterados aprovados; git diff --check aprovado. Nenhum teste unitário reprovado
na validação final das implementações. Sem banco local seguro configurado,
Docker sem daemon e Flutter ausente: integração/analyze/test/build locais não executados.

CI de #3 (40695940352) e #4 (40696297689): unit/mysql/flutter aprovados.
Main pós-merge (40696330653): unit/flutter aprovados; mysql 1 falha, 5 aprovados.
Deadlock 1213 ao atualizar cabinets.lock_state no teste de concorrência. Não houve
retry para esconder a falha. Hardware físico não testado. Aviso Starlette/httpx permanece.

## D. Segurança e qualidade

Chave de hardware separada do administrador; rejeições não chegam aos serviços.
Inventário informado por cliente exige admin no #4; fluxo professor sem lista preservado.
Não criado login por UID; falta autenticação segura e autorização por propriedade.
Nenhuma migração ou banco de produção alterado; proteção _test antes de DDL de testes.
Não há validação contra replay completo ou homologação física.
Regressões a observar: consumidores HTTP que enviavam present_tags agora precisam
Bearer administrativo; testar migração de professores antes de restringir outras rotas.

## E. Estado da tarefa

Em revisão. #3 foi integrado por ação externa em main; #4 foi integrado por ação
externa na branch de hardware, não confirmado em main. Codex não executou merges.
CI pós-merge falhou, impedindo declaração de baseline totalmente validada.
Documentação Notion não foi modificada nem declarada sincronizada.

## F. Próximo trabalho recomendado

1. CI-001: reproduzir e corrigir deadlock; protege consistência e confiabilidade do CI.
2. SEC-002: decidir autenticação segura de professores e migração Flutter com PO;
   evita confiar em UID clonado e quebrar o fluxo atual.
3. SEC-003: vincular histórico/retornos à identidade validada; evita acesso cruzado.

Confirmar propagação do #4 para main antes de considerar SEC-001 entregue.

## G. Mensagem pronta para o ChatGPT

Revisar PRs #3 e #4 e os documentos PROJECT_STATUS.md e
operational-authorization.md. Foram publicados hardware autenticado/CI e proteção
administrativa do inventário manual, mantendo contrato do Flutter. Os 64 testes
locais da melhoria passaram; CI dos PRs passou em Python/MySQL/Flutter, mas main
pós-merge revelou deadlock 1213 (run 40696330653). Priorizar CI-001, depois mecanismo
seguro de identidade de professores e escopo por usuário. UID não é credencial.
#4 foi integrado na branch de hardware, então confirmar propagação a main.
Atualizar Notion somente mediante solicitação do usuário e operação confirmada.
