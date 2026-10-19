# API HTTP

Documentação interativa (Swagger): `http://127.0.0.1:8000/docs`. Rode apenas em rede local protegida: **não há autenticação**.

| Método | Rota | Descrição | Sucesso |
|---|---|---|---|
| GET | `/health` | Verifica API e banco | 200 (503 se o banco cair) |
| GET | `/tablets/available` | Tablets disponíveis + contagem | 200 |
| GET | `/tablets?status=` | Todos os tablets (filtro opcional) | 200 |
| GET | `/professors/by-badge/{badge_uid}` | Identifica professor (não devolve o UID) | 200 |
| POST | `/checkout-requests` | Valida, cria a solicitação e destrava (após confirmação da fechadura) | 201 |
| POST | `/returns/reconcile` | Concilia a devolução tablet a tablet | 200 |
| POST | `/hardware/events` | Recebe eventos do controlador (idempotente) | 200 |
| GET | `/history` | Histórico paginado (`status`, `professor_id`, `since`, `until`, `limit`≤100, `offset`) | 200 |

## Erros

Corpo: `{"code": "NomeDoErro", "detail": "mensagem"}`.

| Status | Quando |
|---|---|
| 403 | `ProfessorInactiveError` — cadastro inativo |
| 404 | `ProfessorNotFoundError`, `SessionNotFoundError`, `CabinetNotFoundError` |
| 409 | `InsufficientAvailabilityError`, `CabinetBusyError`, `InvalidSessionStateError` |
| 422 | Corpo inválido ou UID mal formatado (hexadecimal, 4–32 caracteres) |
| 502 | `LockError` (fechadura não confirmou), `ReaderError` (leitor falhou) |

## Exemplos (PowerShell)

```powershell
$body = @{ badge_uid = "DE000001"; quantity = 2; purpose = "Aula de robótica"; class_name = "9A" } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri http://127.0.0.1:8000/checkout-requests -ContentType "application/json" -Body $body
```

Evento de inventário após a retirada (o controlador informa as etiquetas **presentes**):

```json
{
  "event_id": "7f3c2a10-aaaa-bbbb-cccc-000000000001",
  "cabinet_code": "ARM-01",
  "type": "INVENTORY_AFTER_CHECKOUT",
  "occurred_at": "2026-10-15T15:30:00Z",
  "session_id": 1,
  "details": { "present_tags": ["AA000003", "AA000004", "AA000005"] }
}
```

Reenviar o mesmo `event_id` retorna `"duplicate": true` e **não** cria nova retirada.

Tipos de evento aceitos do hardware: `DOOR_OPENED`, `DOOR_CLOSED`, `INVENTORY_AFTER_CHECKOUT`, `INVENTORY_AFTER_RETURN`, `LOCK_ERROR`, `READER_ERROR`. Um `LOCK_ERROR`/`READER_ERROR` com `session_id` encerra a solicitação em andamento como `FAILED`.

> O UID do crachá na URL de `/professors/by-badge/` pode aparecer em logs de proxies/servidores. Em uso real, prefira consultar por POST ou manter essa rota apenas em `127.0.0.1`. O sistema em si não grava o UID completo nos logs.
