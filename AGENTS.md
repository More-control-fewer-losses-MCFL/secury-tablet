# Secury Tablet — instruções de engenharia

## Objetivo e arquitetura

Gerenciar retiradas/devoluções individuais de tablets, divergências e auditoria.
Preservar o monólito modular: Python 3.12+, FastAPI, SQLAlchemy 2, MySQL 8.4,
Alembic, Flutter e interface adicional Streamlit. Não duplicar regras de negócio
nas interfaces. Hardware permanece simulado até homologação física explícita.

Diretórios: `src/armario_tablets/api` (HTTP), `services` (negócio),
`repositories` (persistência), `models`, `schemas`, `integrations` (hardware);
`frontend_flutter`, `app` (Streamlit), `migrations`, `tests/unit`,
`tests/integration`, `docs`, `.github/workflows`.

## Regras invariantes

- Quantidade solicitada não equivale à quantidade retirada; confirmar inventário individual.
- Comando de fechadura não equivale à confirmação do sensor.
- Eventos duplicados não duplicam movimentações; tablet não tem dois empréstimos ativos.
- Devolução parcial mantém pendências e divergências; preservar rastreabilidade.
- UID RFID identifica cadastro, mas não comprova identidade nem autoriza operações.

## Procedimento e Git

1. Ler este arquivo; verificar branch, status, diff e instruções locais antes de editar.
2. Preservar alterações de terceiros e a pasta não rastreada `secury-tablet/`.
   Há dois clones aninhados: confirmar qual contém a branch solicitada.
3. Definir uma tarefa pequena, critérios de aceitação e teste que cubra o risco.
4. Implementar a menor mudança adequada, respeitando as camadas e o Ruff existente.
5. Usar `.venv/Scripts/python.exe` no Windows. Executar validações disponíveis.
6. Atualizar documentação, `docs/PROJECT_STATUS.md` e
   `docs/coordination/CODEX_HANDOFF.md`; registrar limitações sem inventar resultados.
7. Usar branches e commits semânticos; adicionar arquivos explicitamente.
   Não usar `git add .` ou incluir clones, segredos e arquivos gerados.
8. Abrir/atualizar PR; conferir base e dependências. Não fazer merge automático.
   Confirmar estado remoto, pois outros colaboradores podem integrar PRs durante a sessão.

Não implantar, assumir custos, fazer alterações destrutivas ou alterar arquitetura
substancialmente sem autorização. MySQL permanece principal; schema via Alembic.

## Segurança

Exigir autorização no backend; controles visuais Flutter não são proteção da API.
Separar credenciais administrativas e do controlador; nenhum segredo no Flutter Web.
Não emitir sessão confiável a partir apenas de UID RFID. Validar vínculo entre
principal autenticado e recurso antes de efeitos físicos ou alterações persistentes.
Não registrar senhas, tokens, chaves ou UIDs reais. Não publicar `.env`.
Testes destrutivos apenas em MySQL isolado com nome terminado em `_test` e
credenciais exclusivas; nunca apontar para banco de desenvolvimento/produção.
Simulação não constitui homologação física; não acionar hardware real implicitamente.

## Validação

```powershell
.\.venv\Scripts\python.exe -m pytest tests/unit -q
.\.venv\Scripts\python.exe -m pytest tests/integration -q
.\.venv\Scripts\python.exe -m ruff check <arquivos-python-alterados>
.\.venv\Scripts\python.exe -m ruff format --check <arquivos-python-alterados>
git diff --check
# Em frontend_flutter, quando o SDK estiver disponível:
flutter analyze
flutter test
flutter build web
```

Integração requer `TEST_DATABASE_URL` segura; conferir destino antes de executar.
Verificar CI e distinguir aprovação de PR, execução pós-merge e testes locais.
Não ocultar falhas intermitentes com retries sem investigar a causa.

## Organização e conclusão

Scrumban leve: um trabalho de implementação por vez; priorizar valor, risco e dependências.
Usar IDs existentes; criar IDs estáveis somente quando não houver equivalentes.
Ready: problema, escopo, dependências e critérios BDD definidos.
Done: implementação revisável, critérios atendidos, testes relevantes aprovados,
limitações e riscos registrados, documentação/handoff atualizados e PR referenciado.
Se houver validação pendente ou falha de CI, declarar estado em revisão, sem conclusão plena.

GitHub é a evidência técnica; Notion é planejamento. O outro ChatGPT não vê arquivos
locais. Preparar resumo com links, commits, resultados e três próximos itens.
Não declarar Notion atualizado sem operação confirmada. Não enviar mensagens a
terceiros sem autorização. ADRs em `docs/adr/` para decisões relevantes, distinguindo
propostas de decisões aprovadas e evitando duplicar documentos existentes.
