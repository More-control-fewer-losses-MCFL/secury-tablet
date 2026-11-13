# SEC-004 — Perfis de acesso e interface móvel (proposta implementada)

**Base de implementação:** `feat/docker-full-stack` (commit `76e32a4`).
**Status:** alterações locais preparadas para PR, sem merge/homologação física.

## Objetivo e regra de negócio

O mesmo frontend Flutter Web será utilizado em desktop e celular, mas terá
**dois perfis distintos** com navegação específica. As permissões reais são
validadas pela API; esconder menus não constitui segurança.

| Operação | Professor | Administrador |
|---|---|---|
| Início | Resumo pessoal | Dashboard global |
| Consulta de disponibilidade | Sim | Sim |
| Retirada por crachá | Própria sessão RFID | Somente API; fluxo administrativo futuro |
| Devolução | Somente própria solicitação | Qualquer solicitação |
| Histórico | Somente o próprio | Global |
| Agenda baseada no histórico | Não disponível no perfil | Global |
| Lista completa de patrimônio | Não | Sim |
| Consulta de outros professores | Não | Sim |
| Configurações | Não | Sim |
| Autorizar terminal RFID | Não | Sim, credencial administrativa |

## Segurança

- Professor: necessita de terminal autorizado previamente pelo administrador;
  apresenta UID RFID e recebe token de duração curta, vinculado ao terminal.
- Administrador: acesso por usuário/senha configurados no servidor.
- Backend bloqueia leitura do inventário completo para professores (HTTP 403);
  a consulta `/tablets/available` continua autorizada.
- Rotas Flutter filtram menu e redirecionam tentativas de navegação impróprias.
- Cookies HttpOnly de terminal devem ser verificados no browser; não armazenar
  segredo administrativo ou `HARDWARE_API_KEY` no aplicativo.
- UID RFID pode ser copiado: **não é uma autenticação forte** do portador.
- Segurança para acesso remoto exige HTTPS, configuração do cookie `Secure`,
  gestão de dispositivos confiáveis e testes específicos. O Docker existente é
  **somente loopback/local** (`localhost:8080`).

## Mobile

A navegação em largura estreita é por drawer e botões compactos, sem campo de
pesquisa sempre aberto; a área de professor possui atalhos com `Wrap` adaptável.
O escopo é **Flutter Web responsivo**: não há APK/iOS/PWA publicado neste PR.
O acesso por celular na rede escolar depende de infraestrutura e HTTPS, e o
leitor/fechadura permanece simulado até homologação física.

## Testes de aceitação

1. Professor acessa `/home`, retirada, devolução e próprio histórico.
2. Professor em `/teachers`, `/tablets` ou `/settings` volta para `/home`.
3. Professor não consegue `GET /tablets` na API (403), mas pode consultar
   `/tablets/available` (200).
4. Administrador vê patrimônio, professores, configurações e histórico global.
5. Visitante não autenticado é enviado ao login.
6. `pytest tests/unit -q`, `flutter analyze`, `flutter test` e build Web devem
   passar antes de merge. **Não foram executados neste pacote.**

## Limitações deliberadas

Não adiciona login por senha para professor, funções para vários administradores,
integração NFC nativa, push notifications ou conectividade pública. Isso precisa
ser planejado como requisitos independentes com segurança apropriada.

## Revisão SEC-004 — 2026-11-12

Entradas Flutter separadas: `/#/login` para professor e `/#/admin/login` para
administrador. A tela de professor contém apenas leitura RFID; a administrativa
contém usuário/senha e autorização do terminal. O link de troca abre outra rota,
sem mudar o papel da sessão; professor autenticado não abre o login administrativo.
Após autorizar terminal, administrador volta ao login do professor sem manter
uma sessão administrativa ativa. Identificação RFID continua exigindo terminal
previamente autorizado; não se trata de prova forte da identidade do portador.

Professor: início pessoal, totem, solicitar retirada, devolver e histórico próprio.
Agenda saiu desse perfil porque não há agendamento real implementado. Administrador
mantém painel, alertas, patrimônio, professores, relatórios e configurações.

`GET /tablets/available`: professor recebe contadores `available` e `total` com
`tablets: []`; a consulta não carrega os registros individuais. Administrador
mantém os detalhes. `GET /tablets` permanece exclusivo do admin (403 para professor).
Histórico e devoluções continuam limitados ao proprietário no backend.
A forma da resposta de disponibilidade foi preservada para compatibilidade.

BDD: dado professor autenticado, disponibilidade não expõe patrimônio; dado admin,
os detalhes permanecem; dado visitante, cada URL mostra somente seu formulário;
dado professor navegando para telas administrativas ou agenda, volta ao início.

Validação local: 90 unitários Python, Ruff e formatação dos 3 Python alterados;
Flutter analyze sem problemas, 11 testes e build Web aprovados em Docker.
Sem migração nova, mudança de senha, escrita em dados reais ou hardware físico.
Integração MySQL local não executada nesta revisão; CI remoto e aceite visual
manual ainda pendentes. Estado em revisão; PR [#11](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/11) em rascunho, sem merge automático.

Disponível localmente: professor http://localhost:8081/#/login e administrador http://localhost:8081/#/admin/login. API e web saudáveis após atualização; verificação HTTP aprovada.
