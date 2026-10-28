# Estado da engenharia — Secury Tablet

Última atualização: 2026-10-28 (America/Sao_Paulo).
Branch deste relatório: `docs/operational-authorization-review`.
Base examinada: `23578bc` (main remoto); alterações analisadas: `4119b65` e `4e9946e`.
Versão: `VERSION` = 1.2.0; metadados Python e FastAPI ainda indicam 0.1.0.

## Implementado e observado

Monólito Python/FastAPI, SQLAlchemy, MySQL 8.4, Alembic, Flutter, Streamlit e
integrações simuladas confirmados no repositório. Retirada, confirmação por
inventário, devolução parcial, idempotência, erros e histórico cobertos pela suíte.
Não há evidência de homologação física neste ciclo.

- [PR #3](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/3),
  commit `4119b65`: hardware autenticado, proteção do banco de testes e CI.
  Integrado em main por outra ação durante a sessão.
- [PR #4](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/4),
  commit `4e9946e`: autorização administrativa para inventário manual.
  Integrado por outra ação em `fix/hardware-auth-and-ci`; propagação a main pendente
  na última verificação. Codex não executou merge de nenhum PR.

## Validação e problemas conhecidos

Local: 56 testes passaram no PR #3; 64 passaram no PR #4. Seis testes MySQL
pulados localmente: sem TEST_DATABASE_URL e daemon Docker indisponível. Flutter
SDK não localizado; analyze/test/build não executados localmente. Ruff check e
format passaram em todos os Python alterados de cada implementação; diff --check passou.
Aviso Starlette/httpx de depreciação permanece.

CI dos PRs: jobs unit, mysql e flutter aprovados:
[execução #3](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/actions/runs/40695940352),
[execução #4](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/actions/runs/40696297689).
Após merge de #3, [main falhou](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/actions/runs/40696330653):
MySQL com 1 falha e 5 aprovações; unit e Flutter aprovados. Deadlock 1213 no teste
`test_two_simultaneous_requests_never_both_succeed`, autoflush de UPDATE cabinets
em `_unlock_and_confirm`. Causa raiz ainda não isolada. Não considerar CI estável.

## Riscos e trabalho atual

Rotas operacionais ainda sem autenticação segura de professores e escopo por dono;
UID RFID é identificador clonável. Histórico expõe terceiros na rede confiável.
Autenticação de hardware não resolve replay completo. Hardware real e Streamlit
não foram homologados nesta revisão. Nenhum segredo nem migração foi alterado.

Entrega documental: commit inicial `dcfaa49`, [PR #5](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/5) aberto para main.

Atual entrega documental cria instruções de agentes, análise de rotas e handoff.
Estado: em revisão; não afirmar conclusão de segurança ou validação física.
A pasta não rastreada `secury-tablet/` permanece preservada e fora dos commits.

Próximos itens: CI-001 (deadlock), SEC-002 (prova de identidade e migração Flutter),
SEC-003 (autorização por identidade), conforme [revisão](operational-authorization.md).
Confirmar também entrega de SEC-001 em main antes de fechar o item.

## Atualização CI-001 — 2026-10-28

Correção proposta em fix/mysql-lock-order: ordem consistente armário antes da sessão,
sem repetir efeitos físicos. 56 unitários e 25 integrações locais MySQL passaram
(incluindo 20 cenários de concorrência). Em revisão; CI remoto ainda precisa validar.
Flutter 3.47.8/Dart 3.13.7 agora instalado localmente; análise, dois testes e build
Web passaram no ciclo de instalação. Demo disponível nas portas 8000/8501/8502.

## SEC-002/SEC-003 — terminal supervisionado

PO escolheu somente RFID. Nova branch feat/terminal-rfid-authorization protege o
terminal com cookie HttpOnly revogável, sessões de professor curtas e escopo de
histórico/retirada/devolução. UID continua copiável; não alegar autenticação forte
do portador. Migração 0003 cria apenas terminal_authorizations. A decisão está em
ADR 0001; fluxo Flutter preserva RFID, com autorização prévia pelo administrador.

Validação SEC-002/003: 78 testes unitários, 25 integrações MySQL, análise Flutter
sem problemas e 5 testes Flutter aprovados. Ruff dos Python alterados aprovado.
Estado: em revisão, sem homologação física.
