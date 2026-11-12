# Cadastro de professores por Google Sheets

Estado em revisão. Integração manual pelo administrador; MySQL continua principal.
Não usa `Leituras_RFID` como autorização, não emite token Google para o navegador,
não autentica administrador pela planilha e não comanda hardware.

## Planilha e contrato

Criar a aba `Professores`, com A1:D1 exatamente:

| registration | name | badge_uid | active |
|---|---|---|---|

Não há dados fictícios importados. Modelo de cabeçalho em
[templates/professores_google_sheets.csv](templates/professores_google_sheets.csv).

- registration: matrícula única, texto de 1 a 30 caracteres; preservar zeros iniciais.
- name: nome, texto de 1 a 120 caracteres.
- badge_uid: texto hexadecimal de 4 a 32 caracteres após normalização; único.
  Espaços, hífens e dois-pontos são removidos; letras convertidas em maiúsculas.
- active: booleano TRUE/FALSE ou texto TRUE/FALSE; nenhum valor implícito.

Usar texto simples nas colunas A:C. Não incluir senha, token, chave ou papel admin.
Linha completamente vazia é ignorada; linha incompleta rejeita o lote inteiro.
Cabeçalho incompatível, duplicidade de matrícula/UID e limite excedido rejeitam
antes de escrever no MySQL. Padrão máximo: 1000 linhas de dados; consulta limitada,
com linha sentinela para detectar excesso sem truncar silenciosamente.

## Operação

1. Preencher e conferir os cadastros na planilha, com editores restritos.
2. Entrar como administrador e abrir Professores → Sincronizar professores.
3. Confirmar a sincronização; conferir contadores criados/atualizados/inalterados.
4. Autorizar o terminal pelo login administrativo.
5. Professor apresenta o RFID no terminal e entra com as permissões de professor.

Endpoint: `POST /admin/professors/sync-google-sheets`, Bearer administrativo.
Resposta: `{"created":0,"updated":0,"unchanged":0}`. Professor e visitante recebem
401 antes de construir os serviços da importação. Falta de configuração/Google
indisponível retorna 503; dados inválidos 422; conflito com cadastro local 409.
As respostas não expõem UIDs, linhas completas ou credenciais Google.

A matrícula é a chave estável; atualizações preservam ID e relações de empréstimo.
Crachá de outro cadastro nunca é transferido silenciosamente. Conflito cancela
TODAS as alterações. Repetir a mesma planilha não duplica cadastros.
`active=FALSE` desativa após sincronizar e invalida o uso da sessão existente no
próximo acesso protegido. `active=TRUE` pode reativar cadastro pela ação do admin.
Remover uma linha NÃO apaga/desativa automaticamente: usar FALSE explicitamente.
O login consulta o MySQL, sem Google na rota crítica; mudanças na planilha só
valem após sincronização. Uma falha do Google preserva o último cadastro local.
RFID continua identificador clonável em terminal autorizado, não autenticação forte.

## Configuração privada

Variáveis documentadas em `.env.example`:

```dotenv
GOOGLE_SHEETS_ENABLED=true
GOOGLE_SHEETS_SPREADSHEET_ID=ID_DA_PLANILHA
GOOGLE_SHEETS_PROFESSORS_TAB=Professores
GOOGLE_SHEETS_MAX_PROFESSORS=1000
```

Servidor nativo: `GOOGLE_SHEETS_TOKEN_FILE` aponta para o token OAuth privado.
Docker: `GOOGLE_SHEETS_TOKEN_HOST_FILE` aponta para o caminho absoluto no host;
acrescentar `-f docker/google-sheets.override.yml` ao Compose. Esse override monta
o arquivo somente no backend, em modo somente leitura. Não funciona sem arquivo.
A configuração da integração é opcional e vem desativada por padrão.

O arquivo é compatível com token.json do pacote fornecido: refresh_token,
client_id, client_secret e scopes. É aceito exclusivamente o escopo
`https://www.googleapis.com/auth/spreadsheets.readonly`. O cliente usa destinos
Google fixos, timeout e não segue redirecionamentos. Renova o acesso a cada
sincronização; não grava novos tokens nem inicia consentimento no servidor.
Revogação/expiração do refresh token exige renovar a autorização fora do backend.
Não ampliar escopo para corrigir falta de permissão de edição: a integração lê.

Credenciais reais foram guardadas fora do repositório em pasta privada do usuário.
.gitignore e .dockerignore protegem secrets/, token.json e credentials.json;
não copiar o ZIP para contexto de build nem publicar arquivos de credenciais.

## Evidência desta revisão — 2026-11-12

- 109 testes unitários Python aprovados, incluindo 19 cenários novos.
- Ruff src/tests e formatação dos Python alterados aprovados.
- Flutter Analyze, 12 testes Flutter e Build Web aprovados em Docker.
- Credenciais do ZIP: OAuth refresh 200 e leitura de metadados Google 200.
- Aba Professores ainda ausente. Tentativa de adicionar SOMENTE cabeçalhos foi
  recusada pelo conector Google com 403; nenhuma aba/célula foi criada.
- Nenhum cadastro real foi importado; ensaios usam somente dados fictícios.
- Integração MySQL desta revisão, aceite de professor real e CI remoto pendentes.
- Sem nova migração, merge, publicação externa ou acionamento físico.

Próximos itens: proprietário criar a aba; preencher e sincronizar cadastros;
validar jornada real controlada e CI, preservando terminais autorizados.

Referências do protocolo: [leitura de intervalos](https://developers.google.com/workspace/sheets/api/reference/rest/v4/spreadsheets.values/get)
e [OAuth offline](https://developers.google.com/identity/protocols/oauth2/web-server#offline).

Runtime local atualizado em http://localhost:8081: interface e API respondem 200; sincronização anônima retorna 401. Arquivo privado montado somente no backend, integração configurada sem importar dados reais.

Implementação: commit 66cf422. PR [#12](https://github.com/More-control-fewer-losses-MCFL/secury-tablet/pull/12) em rascunho, base feat/SEC-004-separate-role-access (PR #11). CI remoto e aba real ainda pendentes; sem merge.
