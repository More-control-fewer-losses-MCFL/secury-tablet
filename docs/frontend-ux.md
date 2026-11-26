# Experiência do frontend Flutter

Revisão de interface dos fluxos SEC-004/SEC-007 e cadastro Google Sheets.
Estado em revisão. Sem alteração de regras de negócio, autenticação ou schema.

## Organização visual

- Azul SENAI para administração e verde para professor; superfícies claras e bordas suaves.
- Tipografia padrão do Material/SDK, sem pacote de fontes adicional.
- Escala consistente de títulos, textos, espaçamentos e raios de cartão.
- Contraste reforçado nas cores de sucesso, aviso, erro e texto secundário.
- Cartões com altura natural: acomodam quebra de linha e texto ampliado.
- Títulos de seção empilham ações em espaço estreito; ações primárias têm rótulo.

## Navegação e perfis

Desktop: menu superior com ícones e ações permitidas para o perfil.
Celular ou texto ampliado: drawer com grupos Acompanhar/Gerenciar/Consultar/Sistema que abre por referência ao Scaffold correto; professor também
conta com atalhos inferiores Início/Retirar/Devolver/Histórico. O totem permanece
no menu completo. Não há item selecionado artificialmente quando a rota não
pertence aos atalhos inferiores. O drawer fecha antes de navegar, sem pop da
rota principal em desktop. Estado de conexão tem botão com tooltip e área ampla.

Conta do professor não oferece Configurações. Alerta do administrador abre a
central correta. Guardas do roteador e autorização backend foram preservados.
Sair volta ao login do perfil; nenhuma sessão ou credencial foi incorporada ao UI.

## Fluxos principais

- Login: formulário vem primeiro no celular, sem um banner alto antes dos campos;
  senha tem mostrar/ocultar e preenchimento assistido. Instruções de terminal
  ficam próximas da ação; a explicação completa do RFID continua disponível.
- Professor: saldo disponível em destaque, retirada/devolução fáceis de localizar,
  histórico próprio legível e instruções sobre solicitação/conferência/confirmação.
- Totem: ações com ícones, descrição e altura mínima, adaptadas a largura/texto.
- Retirada: disponibilidade e formulário agrupados, botão principal amplo e
  contadores corretos quando a API omite os detalhes de patrimônio do professor.
  `tablets: []` não significa falta de estoque quando `available > 0`.
- Devolução: cada solicitação tem cartão, contadores e ação próprios. Confirmação
  e pendências permanecem no backend; não apresentar comando como confirmação.
- Administrador: métricas reais, destaque para ocorrências e devoluções,
  movimentações recentes (sem chamá-las de futuras), atalhos de gestão.
- Professores: consulta individual primeiro; sincronização da planilha em seção
  separada e secundária, com confirmação existente preservada.

## Ilustrações, acessibilidade e desempenho

Reutiliza LockerIllustration/BrandMark e ícones Material. A ilustração do armário
fica em área própria com descrição semântica, acompanhando o fluxo operacional;
no celular, orientações compactas substituem o painel alto. Não há imagens de
rede nem nova biblioteca de assets. Desfoque: a regra anterior ("sem efeitos de
desfoque pesados") foi substituída pelo uso limitado de vidro descrito em
[Redesign visual e glassmorphism](#redesign-visual-e-glassmorphism--2026-11-26).

Títulos semânticos, mensagens de erro anunciáveis, rótulos além das cores,
controles do tema com área mínima de 48px e teste de contraste >=4.5:1 nos textos
de status sobre seus fundos. Não limita a escala de texto do sistema.
A presença de ícones não substitui rótulos de operação. Verificação com leitor
de tela real e navegação assistiva manual continuam pendentes.

## Aceitação e evidências

Cenários automatizados: login em 360px com texto 1,5x; drawer do professor;
Retirar/Devolver pela navegação inferior; saldo com patrimônio omitido; diálogo
de devolução cancelado; painel/alertas/consulta/sincronização administrativa em
360px e 1440px com texto ampliado. Cancelar não envia POST de negócio.

Flutter Analyze sem problemas, 17 testes aprovados e Build Web concluído em
Docker com Flutter 3.47.8. Três prévias renderizadas (login móvel, professor móvel
e administrador desktop) foram inspecionadas com dados fictícios e fonte do SDK. Screenshots temporários usam dados fictícios,
não são adicionados ao Git. Nenhum teste real de hardware, importação de cadastro
ou alteração em banco foi executado por esta revisão de interface.

Revisão visual: commit a07204f; PR [#13](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/13) em rascunho sobre feat/google-sheets-professor-sync (dependência PR #12). Runtime local atualizado; CI remoto e aceite assistivo manual pendentes. Sem merge.

## Tela de acesso institucional — 2026-11-13

Escopo SEC-004: aplicar a referência visual de acesso, com painel azul institucional
ocupando metade do desktop, grafismos nativos e formulário branco centralizado.
Entrada inicial em `/#/admin/login` com usuário/senha do cadastro administrativo
existente e área clicável “Passe o crachá” para `/#/login`, destinada a professores.
O celular mostra marca compacta e formulário, sem painel institucional alto.
Não há autenticação Google nem autocadastro/senha de professor implementados.
Cadastro e recuperação de senha são orientados à administração, sem links fictícios.
RFID continua usando o serviço existente e exige terminal autorizado/cadastro ativo.
A autorização do terminal fica em “Configurar acesso por crachá”, com a credencial
administrativa e retorno ao RFID sem manter sessão de administrador.

Critérios BDD:

- Dado visitante, ao abrir o app, vê usuário/senha, “Acessar” e “Passe o crachá”.
- Dado cadastro administrativo válido, ao acessar, a API confirma a sessão antes do painel.
- Ao selecionar “Passe o crachá”, abre o leitor; Enter ou “Validar crachá” usa a API.
- Dado terminal sem autorização ou crachá inválido, o erro mantém o visitante no acesso.
- Ao autorizar terminal com credenciais administrativas, volta ao leitor sem sessão admin.
- Em 360px com texto 1,5x e desktop, campos e troca de acesso continuam utilizáveis.

Validação local: Flutter 3.47.8/Dart 3.13.7 em Docker, analyze sem problemas,
17 testes Flutter aprovados e build Web release concluído. 109 testes unitários
Python aprovados com `.venv/Scripts/python.exe`; aviso Starlette/httpx preexistente.
`git diff --check` aprovado. Sem Python alterado: Ruff não se aplica ao diff.
Integração MySQL não executada nesta alteração de interface.
Capturas desktop/crachá em 1440px e celular real em 390px conferidas no Chrome
headless com perfil isolado; testes cobrem 360px/texto 1,5x e fluxos em 1440px.
Prévia local separada em http://localhost:8082; página/healthz e API health HTTP 200.
Build e capturas temporários fora do Git. Não houve login com credenciais reais.
Aceite assistivo manual e CI remoto pendentes: estado em revisão.

Implementação: [7172693](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/commit/71726938c2fd4685e9f5e728941ac041cd291ee8); PR [#14](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/14) em rascunho para `main`. CI remoto pendente, sem merge.

## Marca SENAI padronizada — 2026-11-13

`BrandMark` agora exibe o logotipo branco do AVA SENAI/SC, correspondente à
referência fornecida, em lugar do escudo acompanhado de texto comum.
O mesmo asset local atende login desktop/móvel e menu lateral/drawer de ambos os
perfis; fundos claros recebem uma base azul. Mantém proporção e rótulo semântico SENAI.
Arquivo original e proveniência: `frontend_flutter/assets/branding/README.md`.

BDD: dado qualquer tela com a marca SENAI, ao exibir o cabeçalho/menu,
usa o mesmo logotipo sem distorção; em área branca, o símbolo branco permanece
legível sobre azul; o carregamento da marca não exige rede.

Analyze sem problemas, 17 testes existentes e build Web release aprovados com
Flutter 3.47.8. Capturas em 1440px e 390px conferidas; prévia 8082 atualizada.
CI do PR #14 e aceite assistivo manual pendentes. Sem alterações de autenticação.

Commit da marca: [3d28117](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/commit/3d2811745842232e48321b2c2713e73253db4725), incluído no PR [#14](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/14).

## Portais personalizados por perfil — 2026-11-13

Professor: verde próximo à referência, cabeçalho #2C8375, ações #17695D e superfícies
suaves. Administração: azul SENAI #075DA8. O tom mais escuro nas áreas com texto
branco mantém contraste mínimo de 4,5:1. Avisos, erros e sucessos conservam sua semântica.

Menu superior no desktop, drawer e atalhos do professor no celular/texto ampliado.
O cabeçalho PortalWelcome reutilizável mostra identidade real, matrícula do professor,
resumo da API e atalhos do perfil. Mantém os painéis de disponibilidade, movimentos,
patrimônio e ocorrências. Nenhuma notícia, horário ou foto de pessoa foi inventada.
A marca SENAI usa o mesmo asset local. Login institucional e autorização permanecem.

Temas por perfil são instâncias estáveis entre rotas; recriá-los em cada build causava
notificação de tema durante navegação e assertions de layout nos formulários móveis.
Cache corrigiu a causa, verificada nos mesmos cenários, sem supressão/retry cego.

BDD:
- Dado professor autenticado, ao abrir o início, vê verde, seu nome/matrícula e ações próprias.
- Dado administrador autenticado, vê azul SENAI, patrimônio e ações administrativas.
- Ao navegar pelos atalhos superiores, mantém tema e permissões do perfil.
- Em 360px com texto 1,5x, mantém campos, menus e operações utilizáveis sem overflow.
- Dados dos painéis continuam vindo da API; alerta visual não confirma sensor físico.

Analyze sem problemas; 20 testes Flutter, contraste, quatro prévias com fixtures e
build Web release aprovados. Prévia 8082 atualizada; CI e aceite assistivo pendentes.

Commit dos portais: [5328625](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/commit/5328625785cdc134468f532cb563f4f7c7f82ab8), PR [#14](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/14) para main.

## Acesso individual de professor — 2026-11-13

Formulário verde `/#/professor/login`, com usuário/senha, mostrar/ocultar, autofill e Enter para acessar. Crachá e administração permanecem opções distintas. A API confirma identidade antes do portal; senha é limpa ao entrar. Administração configura credenciais no cadastro consultado, com diálogo próprio e sem ecoar senha. Saída retorna ao login correspondente; retirada por senha não exige UID. 24 testes Flutter, análise e build aprovados; evidências completas em [professor-password-login.md](professor-password-login.md).

## Formulários, foco e mensagens de erro — 2026-11-19

SEC-004, branch `fix/SEC-004-form-focus-feedback`. Estado: em revisão.
Pedido: corrigir perda de foco no login do professor e melhorar clareza e apresentação.

O teste de regressão reproduziu a falha original em Flutter 3.47.8:
o campo Senha perdia foco após arrastar a página com teclado móvel aberto.
A causa identificada é `ScrollViewKeyboardDismissBehavior.onDrag`.
Login e shell agora usam `manual`; os nós de foco pertencem ao estado da tela.
Tab/clique em outro controle continuam permitidos, sem prender o usuário no campo.

Usuário avança para Senha pelo teclado; senha/crachá enviam somente por Enter
ou botão. Campos obrigatórios recebem indicação local e foco no primeiro erro.
Mostrar/ocultar senha preserva edição. Durante envio, campos ficam somente leitura,
o botão informa a atividade e novos envios são bloqueados.

O acesso mantém cores SENAI/professor, painel institucional, cartão de formulário
com bordas e sombra discretas, dimensões responsivas e conexão verificável.
Os avisos combinam título, descrição e orientação, sem depender apenas da cor.
Categorias distinguem dados inválidos, autenticação, permissão, recurso ausente,
conflito, limite de tentativas, servidor, rede, timeout e resposta inválida.
Detalhes brutos do servidor/HTML/listas de validação não são mostrados.
Falhas de transporte não repetem operações automaticamente; orientar conferência
do estado antes de nova tentativa de operação com efeito persistente.

BDD:
- Dado professor digitando, quando saúde da API atualiza ou a página rola,
  então foco e texto permanecem e não há POST antes da confirmação.
- Dado formulário vazio, ao confirmar, vê os campos obrigatórios sem chamada de login.
- Dada senha oculta com seleção, ao mostrar/ocultar, mantém texto, seleção e foco.
- Dado envio pendente, dois Enters enviam uma única requisição.
- Dado erro de acesso, permanece no formulário com instruções para corrigir.
- Dado erro HTTP/proxy/rede, recebe mensagem classificada sem payload sensível.
- Em celular e texto ampliado, controles e avisos permanecem utilizáveis.

Referências: [W3C WAI: notificações em formulários](https://www.w3.org/WAI/tutorials/forms/notifications/)
e [Flutter: comportamento de dispensa do teclado](https://api.flutter.dev/flutter/widgets/ScrollViewKeyboardDismissBehavior.html).
Validação final, PR e limites são registrados no estado do projeto e no handoff.
Sem mudança de regra de negócio, API, autenticação, schema ou hardware.

Evidência desta revisão: 44 testes Flutter, analyze e build Web release aprovados;
Chrome isolado confirmou teclado/envio/erro 401 e prévias desktop/celular.
Aceite assistivo com leitor de tela real e CI remoto continuam pendentes.
PR [#17](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/17) em rascunho para main, sem dependências pendentes e sem merge.

## Integração em main — 2026-11-19

PR #17 integrado por `32b9994` e PR #18 por `ab979ce`, com autorização explícita.
Checks unit/mysql/flutter/docker aprovados nos heads dos dois PRs; árvore funcional
da main conferida igual ao head #18 validado. CI pós-merge em acompanhamento.
O merge não confirma configuração ou funcionamento no Railway. Ver estado/handoff
e `docs/docker.md` para evidências, configuração e limitações.

## Redesign visual e glassmorphism — 2026-11-26

Estado: em revisão. Branch `feat/ui-redesign-glass`, criada a partir de `main`
(9b665fd). Somente camada visual do Flutter: sem mudança de API, AppController,
rotas, guardas, autenticação, textos de erro funcionais, backend, banco ou Streamlit.
Nenhuma dependência nova no `pubspec.yaml`; somente assets locais existentes.

Diagnóstico de partida: sem sistema visual. Eram 27 cores literais em 4 arquivos,
10 raios, 18 espaçamentos e 14 tamanhos de fonte fora do tema; cartões todos
iguais; quadrados coloridos de ícone repetidos; ícones filled e outlined
misturados (49/75); menu desktop em abas de largura igual; formulário de login
solto no branco.

### Tokens (`lib/core/theme/app_theme.dart`)

- `AppSpacing` 4/8/12/16/24/32/48; `AppRadius` 8 (controles), 12 (cartões),
  20 (painéis de destaque e diálogos); `AppShadows` com dois níveis suaves;
  `AppMotion` 150/200/250 ms; `AppGlass` com os parâmetros do vidro.
- Neutros frios, `borderStrong` para contornos e separadores sobre vidro,
  gradientes de perfil (`backdropFor`) e cores semânticas inalteradas.
- Tipografia do SDK pelo `textTheme`: títulos com tracking negativo, `labelSmall`
  como sobrelinha única em caixa alta e `AppTheme.tabularFigures` em números.

### GlassSurface e regras de uso

`lib/core/widgets/glass_surface.dart`: `RepaintBoundary` + `ClipRRect` +
`BackdropFilter`, preenchimento translúcido, borda de 1px com gradiente vertical
(mais clara no topo), brilho sutil no topo e sombra suave. Duas variantes
(`GlassTone`), revisadas na v2 (seção abaixo):

- **Escuro** (`GlassTone.dark`, texto branco): painel do login, lista de
  benefícios do painel institucional e cartão "Visão do armário"/"Seu
  atendimento" da faixa do início.
- **Claro** (`GlassTone.light`, texto escuro): barra superior (desktop e celular).
- Não usado em tabelas, listas e formulários longos, cartões de métrica e
  páginas operacionais, que seguem opacos.
- No máximo 2 `BackdropFilter` por tela: login largo = painel + benefícios
  (estreito = só o painel); início = barra + cartão de visão; demais páginas =
  barra. `GlassButton` não usa `BackdropFilter`. Coberto por teste.
  No celular, as homes não exibem o cartão de visão (repetia os números abaixo).
- Fallback sem blur quando `blur: false`, quando o sistema pede menos animação
  (`disableAnimations`) ou alto contraste: claro vira branco 0,97; escuro vira o
  tom mais escuro do perfil a 0,94 (`fallbackColor`).
- Totem: ações em `GlassSurface(blur: false)`; a página do totem não usa
  `BackdropFilter`.
- A barra do shell mantém o viewport abaixo dela (foco, `ensureVisible` e toques
  corretos) e usa `Clip.none` para o conteúdo rolado continuar visível sob o vidro.
- `StatusPill` e `InlineNotice` têm fundo opaco e cores de texto explícitas para
  não herdar o fundo nem o tema branco do vidro escuro.

### Glassmorphism visível (v2) — 2026-11-26

Branch `feat/ui-glass-v2`, a partir de `main` f86cd4d (PR #21 já integrado).
Somente camada visual; sem dependência nova, sem mudança de rotas, API,
autenticação, modelos, backend ou Streamlit.

Diagnóstico: com vidro branco a 0,90 o painel parecia um cartão branco comum; o
fundo do login era um gradiente de um tom com brilhos brancos de 8% (nada para o
blur mostrar); botões e barra eram chapados. A opacidade alta existia só para
passar o contraste de texto escuro. Solução: vidro escuro com texto branco sobre
fundo com manchas de cor, e vidro claro só na barra.

Parâmetros (`AppGlass`, `AppBackdrop` em `lib/core/theme/app_theme.dart`):

| Item | Valor |
| --- | --- |
| Sigma do blur | 18 |
| Vidro escuro | véu navy `#061A33` a 0,42 + tint branco 0,12; borda branca 0,26 (topo 0,55); brilho de topo 0,06 |
| Vidro claro (barra) | branco 0,68; borda inferior navy 0,10; sombra suave |
| Fallback | claro 0,97 branco; escuro 0,94 do tom do perfil |
| Campos sobre vidro escuro | véu 0,20 + branco 0,04 (foco 0,08); borda branca 0,30; foco 2px em azul-claro/verde-água; erro `#FFE9E6` |
| Botão secundário | véu 0,20 + branco 0,10 (hover 0,16); borda branca 0,30 (hover 0,48) |
| Pílula do menu ativo | branco 0,85, borda do perfil 0,22, sombra suave |
| Manchas do login (pico) | admin: ciano 0,26, violeta 0,32, azul-claro 0,25; professor: verde-água 0,28, verde-mar 0,26, azul-laguna 0,25 |
| Manchas da faixa do início | 0,14–0,20 sobre `backdropFor` |
| Fundo da página (shell) | gradiente claro do perfil + manchas 0,08–0,16 |
| Entrada do login | fade + 16px de deslocamento, 360 ms; desligada com `disableAnimations` |

Por que um véu escuro sob o tint branco: o tint de 0,10–0,16 sozinho não mantém
4,5:1 para texto branco quando uma mancha clara está no pico atrás do vidro (o
cálculo dava ~3,2:1). O véu escurece o fundo e o tint dá o fosco.

As manchas são gradientes radiais (`GlassBackdrop`,
`lib/core/widgets/glass_backdrop.dart`), sem filtro, em camada própria. O pico
das manchas é limitado pelo contraste do texto branco direto sobre o fundo; por
isso o login usa gradientes mais escuros (`AppBackdrop.loginStopsFor`) que a
faixa do início. Os arcos decorativos do login foram removidos: mesmo a 4%
derrubavam o texto secundário do painel institucional abaixo de 4,5:1.

`GlassButton` (`lib/core/widgets/glass_button.dart`): variantes primary
(gradiente do perfil, brilho no topo, sombra colorida), secondary (vidro) e
ghost; hover sobe 1px e reforça sombra/borda, pressionado escala 0,98, foco com
contorno branco de 2px fora do botão, desabilitado a 50%, loading com indicador
e texto. Área mínima 48px. Menos animação: transições instantâneas, sem
elevação/escala. Alto contraste: preenchimento opaco, sem gradiente e borda
branca de 2px. Usado no login (Acessar = primary; Entrar como professor, Passe o
crachá e Entrar com usuário e senha = secondary; Acesso administrativo = ghost)
e nos atalhos da faixa do início. O atalho "Passe o crachá" perdeu a linha
auxiliar "Acesso para professores pelo leitor." ao virar botão.

### Ícones, cartões e navegação

- Ícones Material outlined em todo o app; filled apenas no item ativo da
  navegação (menu superior, drawer e navegação inferior), padrão Material 3.
- Variações de cartão: destaque (faixa de perfil e vidro), métrica (`MetricCard`:
  número tabular grande, rótulo discreto e ponto semântico, sem quadrado de
  ícone), lista (divisores) e ação (cartões com botão próprio, hover/foco).
  `SectionCard` aceita faixa superior de atenção; o significado sempre aparece
  também em texto. `HintNote` reúne notas estáticas no fim das páginas.
- Shell: barra clara em vidro, itens com largura natural, avatar com iniciais,
  drawer claro com grupos. Homes: faixa compacta e métricas como foco; admin
  prioriza ocorrências e pendências; professor prioriza saldo e Retirar/Devolver.
- Erros de formulário em retirada, devolução e professores passaram de texto
  vermelho solto para `InlineNotice`, com o mesmo texto e anúncio acessível.

### Contraste e acessibilidade

`test/theme_contrast_test.dart` (v2) calcula >=4,5:1 no pior caso: todas as
manchas de um fundo sobrepostas no pico sobre o tom mais claro do gradiente.
Cobre texto institucional sobre o fundo do login; texto, erro e rótulos sobre o
vidro escuro (com brilho de topo), campos em repouso/foco e botões em
repouso/hover; fallback sem blur; texto e atalhos da faixa do início; cartão de
visão; botão primário com brilho; barra clara sobre a página e sobre a faixa
rolada por baixo (`mutedStrong` substitui `muted` na barra); pílula do menu; e
texto da página sobre o fundo tingido. Contorno de foco: 3:1 (não textual).
`test/glass_surface_test.dart` cobre as duas variantes, fallback (`blur: false`,
menos animação, alto contraste), `RepaintBoundary`/`ClipRRect`, status opaco e
o limite de `BackdropFilter` no login (admin, professor, crachá; 1440 e 390px)
e no início (admin e professor). `test/glass_button_test.dart` cobre 48px,
ausência de blur, gradiente por perfil, hover, pressionado, foco por teclado,
desabilitado, loading, alto contraste e menos animação.
Áreas de toque de 48px, foco visível, `Semantics` existentes e escala de texto
livre foram mantidos; os cartões do totem preservam semântica de botão.

### Validação e evidências

Flutter 3.47.8 em Docker (imagem local `secury-tablet-flutter-test`):
`dart format` sem pendências, `flutter analyze` sem problemas, 51 testes
aprovados (44 na linha de base de `main` + 7 novos) e `flutter build web
--release` concluído; `git diff --check` aprovado. Sem Python alterado: pytest e
Ruff não se aplicam a este diff e não foram reexecutados.

Capturas antes/depois em 1440px e 390px (login, shell, homes, retirada,
devolução, histórico e totem) feitas no Chrome headless com perfil isolado e
servidor simulado local com dados fictícios do `seed_demo.py`, sem API real,
banco ou credencial real. Ficam fora do Git. CI remoto ainda não observado.

v2: Flutter 3.47.8 em Docker, `dart format` sem pendências, `flutter analyze`
sem problemas, build Web release concluído e 85 testes aprovados (inclui os novos de vidro, botão, contraste
e limite de blur). Prévias com o fixture `createResponsiveApi` e fontes do SDK
(login admin, login professor, login admin 390px, início admin parado e rolado,
início professor) geradas por um teste temporário fora do repositório; ficam
fora do Git.

### Pendências

- v2: manchas contidas pelo pior caso de contraste; para cores mais vivas é
  preciso escurecer mais o gradiente ou posicionar texto longe das manchas.
- v2: blur e manchas não medidos em hardware modesto nem em navegador real
  (prévias renderizadas pelo `flutter_tester`).
- Diálogo de credenciais do professor não redesenhado (só ajuste de espaçamento).
- `LockerIllustration` mantém cores próprias, fora dos tokens.
- Tablets, professores, agenda, configurações e alertas validados por análise e
  testes, sem captura de tela.
- Verificação com leitor de tela real e navegação assistiva manual.
- Desempenho do blur em hardware modesto não medido (totem já sem blur).

## Atalhos da faixa de boas-vindas do professor — 2026-11-26

Decisão aprovada na revisão visual (branch `feat/ui-redesign-glass`): no perfil
professor, a faixa `PortalWelcome` mantém apenas o atalho "Consultar histórico".
"Iniciar retirada" e "Registrar devolução" saíram da faixa porque já existem no
cartão de foco da home (Retirar/Devolver tablets) e na navegação inferior do
celular; repeti-los competia com a ação principal. O perfil administrativo
mantém seus três atalhos. Rotas, permissões e textos dos fluxos não mudaram.
