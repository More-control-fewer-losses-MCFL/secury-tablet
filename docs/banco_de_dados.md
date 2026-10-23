# Banco de dados (PostgreSQL)

PostgreSQL é a **fonte de verdade**. Nada de CSV como banco principal. O schema é criado **somente** pelas migrações do Alembic (`alembic upgrade head`); a aplicação nunca chama `create_all()`.

## Tabelas

| Tabela | Colunas principais |
|---|---|
| `professors` | `id`, `name`, `registration` (único), `badge_uid` (único), `active`, `created_at` |
| `tablets` | `id`, `asset_code` (único), `rfid_tag_uid` (único, pode ser nulo), `status`, `created_at`, `updated_at` |
| `cabinets` | `id`, `code` (único), `door_state`, `lock_state` |
| `checkout_sessions` | `id`, `professor_id`→, `cabinet_id`→, `requested_quantity` (>0), `purpose`, `class_name`, `status`, `started_at`, `completed_at` |
| `checkout_items` | `id`, `session_id`→, `tablet_id`→, `checked_out_at`, `returned_at`, `status` |
| `events` | `id`, `event_id` (único, idempotência), `cabinet_id`→, `session_id`→ (opcional), `type`, `source`, `occurred_at`, `received_at`, `details` (**JSONB**) |

Constraints: PK/FK/UNIQUE/NOT NULL em tudo que preserva integridade e `CHECK` para os valores válidos de `status`. Datas são `timestamptz` (UTC); a conversão para America/Sao_Paulo é só na exibição.

## Índices (poucos, de propósito)

| Índice | Para quê |
|---|---|
| `professors.badge_uid` (único) | identificar o crachá |
| `tablets.asset_code`, `tablets.rfid_tag_uid` (únicos) | localizar tablet / etiqueta |
| `ix_tablets_status` | contar/listar disponíveis |
| `ix_checkout_sessions_status`, `_started_at`, `_professor_id` | dashboard, histórico e filtros |
| `ix_checkout_items_session_id` | itens de uma solicitação |
| `uq_checkout_items_active_tablet` (parcial) | **impede duas retiradas ativas do mesmo tablet** |
| `events.event_id` (único), `ix_events_occurred_at`, `ix_events_session_id` | idempotência e linha do tempo |

Índice acelera leitura, mas **custa escrita** (cada INSERT/UPDATE atualiza o índice) e espaço. Por isso não há índice em colunas que ninguém consulta. Só crie um novo depois de medir.

## Consultas de exemplo

Disponibilidade (a mesma regra usada pelo sistema):

```sql
SELECT id, asset_code
FROM tablets
WHERE status = 'AVAILABLE' AND rfid_tag_uid IS NOT NULL
ORDER BY asset_code;
```

Histórico paginado, com filtro no banco, sem N+1 (uma consulta só, com agregação):

```sql
SELECT s.id, p.name, s.requested_quantity,
       count(i.id) AS retirados,
       count(i.id) FILTER (WHERE i.status = 'ACTIVE') AS pendentes,
       s.status, s.started_at
FROM checkout_sessions s
JOIN professors p ON p.id = s.professor_id
LEFT JOIN checkout_items i ON i.session_id = s.id
WHERE s.status = 'DIVERGENT'
GROUP BY s.id, p.name
ORDER BY s.started_at DESC
LIMIT 20 OFFSET 0;
```

## Investigar consulta lenta com `EXPLAIN ANALYZE`

Não prometemos velocidade sem medir. Para investigar:

```powershell
docker exec -it armario_tablets_db psql -U armario -d armario_tablets
```

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM tablets WHERE status = 'AVAILABLE';
```

Veja: `Seq Scan` × `Index Scan`, tempo real (`actual time`), linhas estimadas × reais (`rows=`) e `Buffers`. Se as estimativas estiverem muito erradas, rode `ANALYZE;`. Com poucas centenas de linhas o PostgreSQL pode preferir `Seq Scan` mesmo havendo índice — isso é normal. Só adicione índice se a medição mostrar ganho em dados realistas.
