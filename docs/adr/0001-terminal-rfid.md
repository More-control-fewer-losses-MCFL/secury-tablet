# ADR 0001 — RFID em terminal autorizado

Data: 2026-10-28. Estado: aceita para o modo supervisionado de sala.

Contexto: o Product Owner pediu explicitamente acesso de professores apenas por
RFID, recusando senha individual. O UID é copiável; não pode ser chamado de
credencial criptográfica. Não adicionar senha nem identidade institucional implicitamente.

Decisão: administrador autoriza o navegador por cookie HttpOnly, Strict e expirável,
com registro revogável no MySQL. O UID identifica o professor somente nesse terminal.
Emitir sessão curta, vinculada ao terminal, e verificar escopo e cadastro ativo no
backend. Administrador e controlador permanecem domínios separados.

Alternativas consideradas: UID aberto na rede (recusada), RFID + senha individual
(não escolhida pelo PO), provedor institucional (fora do escopo atual).

Consequências: preserva leitura simples para professores; requer preparação inicial
do terminal por admin. Não impede impersonação com crachá clonado no terminal
supervisionado. Login visual não concede autorização; backend aplica ownership.
Implantação fora do loopback requer HTTPS e revisão do modelo de ameaça.
