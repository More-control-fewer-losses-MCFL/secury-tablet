# Estado da engenharia — Secury Tablet

Atualizado em 2026-11-05 (America/Sao_Paulo). Estado: em revisão.
Branch atual: feat/SEC-007-integration-review, baseada em
feat/terminal-rfid-authorization (árvore compatível com feat/docker-full-stack).
Commits funcionais examinados: 0138744 (locks), f3ffee8 (autorização),
581b8dc (navegação da autorização do terminal). Main observada: 14002e6;
base desta entrega: 8fb19a9 (árvore compatível com 76e32a4).
Versão VERSION: 1.2.0; metadados Python/FastAPI ainda indicam 0.1.0 (débito conhecido).

## Atualização SEC-007 — 2026-11-05

Totem `/totem`, central `/alerts` e indicadores administrativos integrados às
alterações locais existentes, preservadas na branch de revisão. SEC-004 já tinha
proteção backend por perfil; a separação visual e a restrição do inventário
completo foram conciliadas sem reaplicar o pacote antigo.

ZIP encontrado em Downloads (não havia `imports/`), extraído fora do projeto.
LEIA-ME, HANDOFF e aplicador revisados. `apply_incremento.py --check` retornou 2:
contexto de `main.py` diferente devido ao registro de rotas já integrado e
formatado. Integração revisada manualmente; não foi usado `--apply`.

API delega ao serviço e repositório de monitoramento; schemas separados.
Eventos históricos omitem `details`; `DOOR_OPENED` isolado não gera alerta.
Sem migração, acesso a dados reais ou acionamento de hardware.

Validação: 88 testes unitários aprovados; Ruff `check src tests`, formatação dos
9 Python alterados e `git diff --check` aprovados. Flutter 3.47.8 em Docker:
analyze sem problemas, 10 testes e build Web aprovados; versão final dos testes Flutter validada. Um aviso preexistente Starlette/httpx permanece.
MySQL não executado: TEST_DATABASE_URL ausente e fixtures usam DROP/TRUNCATE,
vedados nesta solicitação. Jornada manual e CI remoto pendentes.

PR deve usar `feat/terminal-rfid-authorization` (8fb19a9) como base: main remota
observada em 14002e6 ainda não inclui essa dependência. Sem merge automático.
Estado: em revisão; publicação do PR em preparação. Notion não alterado.

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

Implementação: commit a4373f4 (feat(sec007)).
