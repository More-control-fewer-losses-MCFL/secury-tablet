# Escopo do projeto

Controle da retirada e devolução de tablets de um armário por professores identificados com crachá RFID.

## O que o MVP faz

1. Identifica o professor pelo UID do crachá e valida se o cadastro está ativo.
2. Mostra os tablets disponíveis (no armário **e** com etiqueta RFID cadastrada).
3. Recebe quantidade, finalidade de uso e turma/disciplina (opcional).
4. Valida disponibilidade e autorização **antes** de destravar o armário.
5. Só considera um tablet retirado quando a leitura do inventário confirma a identidade individual dele.
6. Registra professor, solicitação, tablets, datas/horários e eventos.
7. Na devolução compara esperados × detectados; ausentes ficam **pendentes** e geram **divergência**.
8. Dashboard, disponibilidade, histórico paginado e divergências.
9. Funciona 100% em **modo simulado** (sem hardware).

## Fora do escopo (por enquanto)

- Adaptadores de hardware real (leitor de crachá, leitor de etiquetas dos tablets, fechadura).
- Autenticação de usuários administrativos nas telas e na API (use somente em rede local protegida).
- Cadastro/edição de professores e tablets pela interface (hoje via seed/SQL).
- Consumo de eventos via MQTT (a API HTTP já é idempotente; um consumidor MQTT pode chamar o mesmo serviço).

## O que é simulado e o que depende de validar o hardware

| Parte | Situação |
|---|---|
| Leitor de crachá | Simulado (`SimulatedBadgeReader`). Na tela, o UID é digitado. |
| Leitor de inventário dos tablets | Simulado. Na tela, você escolhe quais tablets "saíram/voltaram". |
| Fechadura | Simulada (`SimulatedLockController`), com chaves para simular falha e falta de confirmação. |
| Modelo/protocolo dos leitores e da fechadura | **Não definidos.** Nenhum suporte foi inventado. |
| Tempo de leitura, colisão de etiquetas, leitura parcial em campo | **A validar** com o hardware escolhido. |
| MicroPython no controlador | Só se leitores/drivers escolhidos forem compatíveis; **não confirmado**. |

Com `HARDWARE_SIMULATED=false` o sistema se recusa a iniciar o hardware (levanta `NotImplementedError`), para que ninguém acione uma fechadura real por engano.
