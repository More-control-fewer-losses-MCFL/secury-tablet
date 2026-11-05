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
| Agenda baseada no histórico | Somente própria | Global |
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
