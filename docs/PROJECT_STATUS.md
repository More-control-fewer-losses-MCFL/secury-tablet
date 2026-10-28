# Estado da engenharia — Secury Tablet

Atualizado em 2026-10-28 (America/Sao_Paulo). Estado: em revisão.
Branch atual: feat/docker-full-stack, baseada em feat/terminal-rfid-authorization.
Commits funcionais examinados: 0138744 (locks), f3ffee8 (autorização),
581b8dc (navegação da autorização do terminal). Base main analisada: c7d8175.
Versão VERSION: 1.2.0; metadados Python/FastAPI ainda indicam 0.1.0 (débito conhecido).

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
| DOCKER-001 | Flutter/Nginx + API + migrações + MySQL persistente; início por script | Branch atual; PR separado |

PRs: [#6](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/6),
[#7](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/7).
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
