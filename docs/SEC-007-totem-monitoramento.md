# SEC-007 — Totem, indicadores e histórico de alertas

## Escopo da entrega

Base: `feat/docker-full-stack` no commit `76e32a4` + SEC-004 (segregação de perfis). Não copiar o Flask, SQLite, reconhecimento facial, senha padrão nem endpoints públicos do projeto de referência.

- **Totem do professor:** `/totem` exige sessão autenticada de professor vinculada a terminal RFID autorizado. Exibe quantidade disponível e botões grandes para iniciar retirada, devolução e consultar histórico. Não abre porta diretamente.
- **Monitoramento administrativo:** `GET /admin/overview` devolve contadores do banco (tablets, solicitações e alertas históricos) e `GET /admin/alerts` lista eventos críticos com limite de 50. Dependem do token administrativo emitido por `/admin/login`.
- **Central de alertas Flutter:** `/alerts`, somente administrador; mostra registros existentes de erros de leitor/fechadura, retiradas excedentes e devoluções divergentes. Não exibe payload bruto ou UID RFID.
- **Sem mudança de schema:** as informações vêm da tabela `events` já persistida; não é necessária nova migração Alembic.

## Limites e segurança

1. **Evento registrado não significa alarme ativo.** Não há mecanismo de reconhecer/resolver incidentes nesta versão.
2. **Abertura de porta não é automaticamente invasão.** Detectar abertura não autorizada exige regra correlacionada com estado autorizado/sensor e validação física; não foi implementado.
3. **Não há Telegram, QR nem reconhecimento facial.** Esses recursos exigem decisão de produto, segurança e privacidade.
4. **RFID não prova identidade criptograficamente.** O terminal só funciona após autorização do administrador e a sessão do professor expira.
5. **Exposição móvel fora de localhost** exige HTTPS e configuração de cookies/credenciais, CORS e rede. Não publicar o backend automaticamente.
6. **Dependência SEC-004:** telas por perfil, guarda do roteador, inventário completo do admin; sem isso o dashboard original do professor pode consultar dados administrativos.

## Critérios BDD

- Dado um administrador autenticado, quando consultar `/admin/overview`, então os contadores refletem o MySQL e a API omite `details` do evento.
- Dado um professor autenticado, quando tentar `/admin/alerts` ou `/admin/overview`, então recebe HTTP 401.
- Dado o evento `DOOR_OPENED` isolado, quando consultar alertas, então ele não é classificado automaticamente como anomalia.
- Dada uma falha da fechadura, quando registrada como `LOCK_ERROR`, então aparece no histórico de eventos críticos sem dados RFID sensíveis.
- Dado um professor autenticado via terminal autorizado, quando abrir `/totem`, então encontra ações de retirada, devolução e histórico em tela responsiva.

## Testes

- `.\.venv\Scripts\python.exe -m pytest tests/unit/test_admin_monitoring.py -q`
- `.\.venv\Scripts\python.exe -m pytest tests/unit -q`
- `.\.venv\Scripts\python.exe -m ruff check src tests`
- `cd frontend_flutter && flutter analyze && flutter test && flutter build web`
- Antes de executar integrações MySQL, confirmar **banco isolado de testes**.

## Aceite e PR

Codex deve revisar o diff, validar em ambiente real, capturar saídas dos testes e preparar Pull Request sem merge automático. **Não considerar feature pronta antes do CI e teste de jornada no Flutter.**

## Reconciliação com o projeto

Implementação revisada em `feat/SEC-007-integration-review`, preservando mudanças
locais SEC-004/007. O aplicador --check aborta em main.py já registrado/formatado;
não forçar --apply. ZIP disponível em Downloads, extração em TEMP.

- `schemas/monitoring_schema.py`: contratos de resposta sem payload bruto.
- `repositories/monitoring_repository.py`: agrupamentos e consultas SQLAlchemy.
- `services/monitoring_service.py`: classificação e composição dos indicadores.
- `api/routes/monitoring.py`: autorização administrativa e limite HTTP de 1 a 50.

Ordem dos alertas: recebimento mais recente, desempate por ID decrescente.
Dashboard retorna até 5 alertas; central retorna 30 por padrão, no máximo 50.
Contadores globais: inventário por estado, sessões OPEN/DIVERGENT separadas e
PENDING+UNLOCKED em curso, reutilizando os estados existentes do domínio.

Validação desta revisão: 88 testes Python; Ruff aprovado. Flutter analyze,
10 testes e build Web aprovados no Docker com SDK 3.47.8; navegação final validada. Integração MySQL não executada por ausência de URL
segura e proibição de comandos destrutivos. CI e jornada manual ainda pendentes.

Implementação: commit a4373f4 (feat(sec007)).
