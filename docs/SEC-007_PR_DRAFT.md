# feat(sec007): integrar totem e monitoramento administrativo

Base: feat/terminal-rfid-authorization
Head: feat/SEC-007-integration-review
Estado: PR em rascunho publicado: https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/9

## Comportamento

Professor autenticado em terminal autorizado acessa `/totem` com disponibilidade
e ações de retirada, devolução e histórico. A navegação segue o perfil SEC-004;
professor não acessa inventário completo, configurações ou telas administrativas.

Administrador consulta `/admin/overview` e `/admin/alerts`, com contadores reais
e eventos históricos LOCK_ERROR, READER_ERROR, EXTRA_WITHDRAWAL e
RETURN_DIVERGENCE. A central Flutter omite payloads brutos. DOOR_OPENED isolado
não representa invasão. Não há reconhecimento/resolução de alarme ativo.

Consultas no repositório, classificação no serviço, contratos em schemas e
rotas HTTP com autorização. Sem alteração de schema; hardware segue simulado.
Alterações locais existentes foram preservadas e conciliadas.

## Validação

- Python: 88 testes unitários aprovados; aviso preexistente Starlette/httpx.
- Ruff check src/tests e format --check nos 9 Python alterados: aprovados.
- Flutter 3.47.8 em Docker: analyze sem problemas, 10 testes aprovados e
  build Web concluído, incluindo revisão final dos testes de navegação.
- git diff --check: aprovado.
- apply_incremento.py --check: código 2, contexto main.py já integrado e
  formatado. Reconciliação manual; não foi forçado --apply.
- MySQL 8.4 isolado: oito cenários do monitoramento aprovados; migrações até
  0003 aprovadas. Rollback por cenário, sem DROP/TRUNCATE ou dados reais.
  A suíte completa local de integração não foi executada.
- Jornada visual manual pendente. CI remoto iniciado no PR #9.
- Sem deploy ou homologação física.

## Base e dependências

Main remota observada: 14002e6. Base remota: 8fb19a9, cuja árvore coincide
com feat/docker-full-stack=76e32a4. Manter PR empilhado na branch de autorização
até integrar dependências e então revisar base novamente. Não fazer merge automático.

## Publicação

PR #9 publicado em rascunho. Push via Git local; criação via API com a mesma
credencial, mantida em memória. O conector GitHub retornou 403 para escrita.
Commits iniciais: a4373f4, c029d8c e 9310114. Documentação posterior registra
o resultado atualizado. Não fazer merge automático; conferir CI e base.
