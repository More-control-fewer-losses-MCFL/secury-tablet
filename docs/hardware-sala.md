# Integração e homologação do hardware em sala

Estado: planejada; nenhum equipamento real conectado ou homologado neste ciclo.
O software executa com HARDWARE_SIMULATED=true. O Docker mantém esse valor fixo.

## Informações a levantar em sala

Registrar modelo do leitor de crachá, protocolo do leitor de inventário individual,
modelo/tensão da fechadura, sensor de porta/fechadura, controlador, alimentação e
rede. Leitor USB que digita UID não autentica a origem nem impede clonagem.
Não assumir que a confirmação do comando significa confirmação física.

## Contratos que já existem

- `integrations/lock_controller.py`: send_unlock, send_lock, is_unlocked.
- `integrations/tablet_reader.py`: read_present_tags devolve etiquetas presentes.
- `integrations/badge_reader.py`: leitura do identificador do crachá.
- POST /api/hardware/events (Docker) exige X-Hardware-Key exclusivo do controlador.
  Nunca colocar essa chave no Flutter; não usar a senha administrativa.

Eventos aceitos incluem DOOR_OPENED, DOOR_CLOSED, INVENTORY_AFTER_CHECKOUT,
INVENTORY_AFTER_RETURN, LOCK_ERROR e READER_ERROR. Usar event_id único (8 a 64
caracteres), cabinet_code cadastrado, occurred_at com fuso horário e session_id
para inventário. Em details enviar present_tags com todas as etiquetas presentes.
Repetir uma transmissão usa o mesmo event_id, nunca gerar outro ID para o retry.
Consultar schema e exemplos em docs/api.md e Swagger. O transporte do comando ao
controlador real ainda exige adaptador; o endpoint de eventos não o implementa.

## Critérios de aceitação físicos

1. Solicitar N tablets reserva a vez, mas não marca N retirados automaticamente.
2. Sem retorno do sensor, desbloqueio falha com timeout e registra ocorrência.
3. Confirmação com inventário registra cada tablet ausente, inclusive retirada parcial/excesso.
4. Reenviar mesmo evento não duplica itens, histórico ou retirada.
5. Devolver parte mantém pendências; nova leitura pode completar a devolução.
6. Falha do leitor, porta aberta, perda de rede e queda de energia não inventam confirmação.
7. Dois pedidos simultâneos não concedem duas retiradas ativas do mesmo tablet.
8. Após reiniciar backend/controlador, conferir reconciliação e rastreabilidade.
9. Chave ausente/incorreta e professor sem terminal autorizado não alteram estado.

Registrar evidências, firmware, versões, resultados e responsável no handoff.
Até esses testes passarem, declarar modo simulado. Credenciais por dispositivo,
frescor de eventos e proteção ampliada contra replay exigem revisão ao escolher
protocolo e equipamento; autenticação por chave compartilhada não resolve tudo.
