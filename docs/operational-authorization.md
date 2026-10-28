# Revisão incremental de autenticação e autorização

Data: 2026-10-28. Baseline: `23578bc` em main; mudanças adicionais examinadas:
`4119b65` (PR #3) e `4e9946e` (PR #4). Esta revisão não certifica segurança de produção.

## Fatos verificados

| Rota | Proteção observada | Risco / evolução |
|---|---|---|
| POST /admin/login | Senha configurada, token assinado e expiração | Limitação de tentativas e revogação ainda precisam de análise |
| GET /admin/session | Validação de Bearer administrativo | Não protege automaticamente outras rotas |
| POST /hardware/events | X-Hardware-Key no PR #3, integrado em main | Chave compartilhada não assegura frescor, vínculo por dispositivo ou proteção completa contra replay |
| GET /professors/by-badge/{uid} | Consulta por UID, cadastro ativo | Identificação pública na rede; UID clonável e presente em URL |
| POST /checkout-requests | Validação de cadastro e regras de negócio | UID não autentica solicitante; operação pode destravar armário |
| GET /history | Filtros e paginação; sem sessão exigida | Dados de terceiros acessíveis; professor_id fornecido não é autorização |
| POST /returns/reconcile | Em main aceita inventário manual; PR #4 exige admin para listas | Sem lista lê leitor; ainda falta vínculo autenticado à sessão |
| GET /tablets e /tablets/available | Sem sessão exigida | Exposição de inventário; revisar necessidade por perfil |
| GET /health | Checagem de banco | Manter resposta mínima; não divulgar detalhes internos |

Evidências: `src/armario_tablets/api/routes/*.py`, schemas de professor/tablet,
`frontend_flutter/lib/services/system_api.dart`, `app_controller.dart` e páginas
home/history/agenda/returns. As páginas Flutter consultam histórico e inventário
sem sessão de professor; bloquear todas as rotas com Bearer administrativo quebraria esse uso.
CORS restringe navegadores; não autentica clientes HTTP.

## Melhoria implementada separadamente — SEC-001

[PR #4](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/4):
listas `present_tags`, inclusive vazias, exigem sessão administrativa antes da
construção de serviços. Campo omitido/null usa o leitor do servidor, preservando
o contrato Flutter. Não concede confiança ao UID nem autentica professores.
O PR foi integrado por ação externa na branch de hardware, não diretamente em main.
Confirmar propagação para main antes de declarar a proteção disponível nessa branch.

Critérios BDD cobertos: dado token ausente/forjado/esquema inválido e lista manual,
quando a API recebe conciliação, então retorna 401 sem acessar serviços; dado
campo omitido/null, então o serviço recebe None para ler o inventário; dado login
administrativo válido, então a conciliação manual segue o fluxo completo existente.

## Próximos incrementos propostos

1. **CI-001 — concorrência MySQL:** reproduzir deadlock 1213 e corrigir ordem de
   locks/transações antes de automatizar repetições. Dadas duas solicitações
   simultâneas, apenas uma vence e a outra recebe erro de domínio, sem deadlock
   não tratado nem repetição de comandos físicos. Exigir integração MySQL real.
2. **SEC-002 — autenticação de professores:** definir com o Product Owner a prova
   de identidade (por exemplo, provedor institucional ou segundo fator) e migração
   do terminal. UID isolado nunca emite sessão confiável. Testar negação de UID
   copiado e continuidade de identificação, retirada e devolução Flutter. A escolha
   do mecanismo ainda é proposta, não decisão aprovada.
3. **SEC-003 — escopo por identidade:** após SEC-002, limitar histórico e conciliação
   ao professor da sessão autenticada; acesso global administrativo explícito.
   Dado professor A autenticado, trocar professor_id/session_id de B não deve
   expor dados nem alterar estado; verificar antes de serviços/efeitos físicos.

Além desses itens: analisar replay/frescor de eventos, credenciais por controlador,
auditoria de overrides administrativos, rate limiting e exposição do Streamlit.
Nenhuma dessas proteções adicionais é declarada implementada.
