# Arquitetura

```
Streamlit (app/pages) ──► views ──┐
                                  ├──► services ──► repositories ──► PostgreSQL
FastAPI (api/routes) ─────────────┘        │
                                           └──► integrations (leitores / fechadura)
```

| Camada | Pasta | Responsabilidade |
|---|---|---|
| Entradas | `app/`, `src/.../api/` | Páginas Streamlit finas e endpoints FastAPI. Sem regra de negócio. |
| Views | `views/` | Desenham as telas chamando serviços. Sem SQL. |
| Serviços | `services/` | Regras de negócio, transações, orquestram repositórios e hardware. |
| Repositórios | `repositories/` | Consultas e persistência. |
| Modelos | `models/` | Entidades SQLAlchemy. |
| Schemas | `schemas/` | Contratos Pydantic de entrada e saída. |
| Integrações | `integrations/` | Interfaces (`BadgeReader`, `TabletReader`, `LockController`) + implementação simulada. |

`services/factory.py` monta todos os serviços; é usado pela API, pelo Streamlit e pelos testes (injeção de dependências simples, sem framework).

## Fluxo de retirada

1. `POST /checkout-requests` → `CheckoutService.request_checkout`
   - **Transação 1**: identifica o professor, trava a linha do armário (`SELECT ... FOR UPDATE`), cancela reservas vencidas, recusa se já há retirada em andamento (`CabinetBusyError`) ou se `quantidade > disponíveis`, cria a solicitação `PENDING`.
   - **Fora da transação**: envia o comando de destravar e **espera o sensor confirmar** (timeout configurável). Sem confirmação → solicitação `FAILED`, evento `LOCK_ERROR`, erro 502.
   - **Transação 2**: solicitação `UNLOCKED`.
2. O controlador envia `INVENTORY_AFTER_CHECKOUT` (`POST /hardware/events`) com as etiquetas presentes.
3. `confirm_checkout`: tablets `AVAILABLE` cuja etiqueta **não** está mais presente viram `CHECKED_OUT` e ganham um `CheckoutItem`. A quantidade pedida **nunca** vira quantidade retirada:
   - menos que o pedido → evento `PARTIAL_WITHDRAWAL`;
   - mais que o pedido → evento `EXTRA_WITHDRAWAL`;
   - nenhum → solicitação `CANCELLED`.

## Fluxo de devolução

`POST /returns/reconcile` (ou evento `INVENTORY_AFTER_RETURN`) → `ReturnService.reconcile`: cada item ativo cuja etiqueta aparece é devolvido; os demais seguem pendentes. Sobrou pendente → `DIVERGENT` + evento `RETURN_DIVERGENCE`. Tudo devolvido → `COMPLETED`. Pode ser repetida (com outro `event_id`) até fechar.

## Estados da solicitação

`PENDING → UNLOCKED → OPEN → (DIVERGENT) → COMPLETED`, com saídas para `CANCELLED` e `FAILED`.

## Garantias de consistência

- **Concorrência**: a linha do armário é travada na criação da solicitação; dois pedidos simultâneos são atendidos um por vez (testado no PostgreSQL).
- **Um tablet, uma retirada ativa**: índice único parcial `uq_checkout_items_active_tablet` (`WHERE status = 'ACTIVE'`).
- **Idempotência**: `events.event_id` é único. Um evento repetido é detectado (com a sessão travada) e devolve o resultado atual com `duplicate_event=true`, sem nova retirada.
- **Transações**: toda operação que muda sessão + itens + tablets usa `unit_of_work` (commit ou rollback inteiro).
- **Comando ≠ confirmação**: `LockController.send_unlock` só envia; `is_unlocked` é o retorno do sensor.

## Segurança

- O **UID do crachá sozinho não é credencial criptograficamente segura**: pode ser lido e clonado. Ele só identifica. Para ambientes sensíveis, considere crachás com autenticação (ex.: cartões com chave/desafio), segundo fator (PIN) ou câmera.
- A API não tem autenticação: rode apenas em `127.0.0.1`/rede local protegida.
- Logs não gravam UIDs completos (`mask_uid`); as telas e a API não devolvem o `badge_uid`.
- Credenciais só vêm do `.env`; PostgreSQL exposto apenas em `127.0.0.1`.
