# Tablet de Segurança — guia de acesso Flutter Web

Este guia explica como preparar e abrir o cliente Flutter Web deste repositório
no Windows, entrar como administrador ou identificar um professor por RFID e
resolver problemas comuns.

O Flutter é uma interface web separada da interface Streamlit. Ambos podem
usar a mesma API e o mesmo banco, mas o Flutter usa a porta `8502` e o
Streamlit usa, por padrão, a porta `8501`.

## O que instalar

- Windows 10/11 e PowerShell.
- Python 3.12 ou superior.
- Flutter SDK compatível com a versão Dart exigida em `pubspec.yaml`.
- Google Chrome (para `flutter run -d chrome`).
- Docker Desktop, se o MySQL do projeto ainda não estiver em execução.

Confirme as ferramentas:

```powershell
py --version
flutter --version
docker --version
```

## Preparação inicial

Execute os comandos a partir da pasta raiz do repositório.

### 1. Preparar o ambiente Python

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -e ".[dev]"
```

Se o PowerShell bloquear a ativação do ambiente, habilite scripts locais para
seu usuário e tente novamente:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\.venv\Scripts\Activate.ps1
```

### 2. Criar ou conferir o `.env`

Se ainda não houver `.env`, crie-o a partir do exemplo:

```powershell
Copy-Item .env.example .env
notepad .env
```

Se o `.env` já existir, **não o substitua**: ele pode conter as credenciais
locais do banco e do administrador. Abra-o diretamente:

```powershell
notepad .env
```

Configure as senhas do MySQL e do administrador. O bloco de administração
deve ter este formato:

```dotenv
ADMIN_USERNAME=admin
ADMIN_PASSWORD=coloque_uma_senha_forte_aqui
ADMIN_TOKEN_SECRET=coloque_a_chave_aleatoria_gerada_aqui
ADMIN_SESSION_TTL_MINUTES=480
```

Requisitos:

- `ADMIN_USERNAME`: nome usado no campo de usuário; o exemplo configura `admin`.
- `ADMIN_PASSWORD`: senha escolhida por você, com no mínimo 12 caracteres.
- `ADMIN_TOKEN_SECRET`: chave aleatória com pelo menos 32 bytes. Não reutilize a
  senha administrativa como chave.
- `ADMIN_SESSION_TTL_MINUTES`: duração da sessão em minutos, de `1` a `1440`;
  o padrão é `480` minutos (8 horas).

Gere valores aleatórios no PowerShell. Copie cada resultado para o campo
correspondente no `.env`; não coloque estes comandos nem os segredos no README:

```powershell
python -c "import secrets; print(secrets.token_urlsafe(18))"
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

O primeiro comando pode gerar uma senha forte; o segundo, a chave de sessão.
Depois de salvar o `.env`, mantenha-o privado. O arquivo está no `.gitignore` e
nunca deve ser enviado ao Git, compartilhado em capturas de tela ou colocado
em mensagens.

O arquivo `.env.example` documenta as variáveis disponíveis. Não copie valores
de exemplo como `troque_esta_senha` para um ambiente real.

### 3. Iniciar o MySQL

Com o Docker Desktop aberto:

```powershell
docker compose up -d
docker compose ps
```

Espere o serviço `db` ficar saudável (`healthy`). O MySQL é exposto somente na
máquina local, na porta `3306` por padrão.

### 4. Criar o esquema do banco

Na primeira instalação, execute as migrações:

```powershell
alembic upgrade head
```

Opcionalmente, para preencher uma base local de demonstração com dados de
teste:

```powershell
python scripts/seed_demo.py
```

O seed cria dados de demonstração. Os crachás listados no README da raiz só
funcionam se esse seed tiver sido executado e os dados correspondentes
estiverem no banco. Não execute novamente em um banco com dados que queira
preservar sem antes conferir o que o script faz.

## Iniciar a aplicação

São necessários dois terminais PowerShell, ambos abertos na pasta raiz do
repositório.

### Terminal 1 — iniciar a API

Ative o ambiente virtual e inicie a API:

```powershell
.\.venv\Scripts\Activate.ps1
uvicorn armario_tablets.api.main:app --host 127.0.0.1 --port 8000
```

Mantenha este terminal aberto. Confirme em outro terminal ou no navegador:

- Saúde da API e do banco: <http://127.0.0.1:8000/health>
- Documentação interativa: <http://127.0.0.1:8000/docs>

Uma resposta saudável é semelhante a:

```json
{"status":"ok","database":"ok"}
```

### Terminal 2 — iniciar o Flutter Web

```powershell
Set-Location frontend_flutter
flutter pub get
flutter run -d chrome --web-port 8502 `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Mantenha este terminal aberto enquanto usa o app. Abra:

<http://localhost:8502>

O argumento `API_BASE_URL` indica o endereço da API. Se a API estiver em outro
endereço, altere-o no comando. A origem do navegador também precisa estar
permitida em `CORS_ALLOWED_ORIGINS` no `.env` da API. Por padrão, o projeto
permite as origens locais configuradas para as portas `8080` e `8502`.

> Não tente usar a porta `8080` se outro serviço, como o Tomcat, já estiver
> ocupando-a. Use `8502` ou escolha outra porta livre e adicione as origens
> exatas `localhost` e `127.0.0.1` dessa porta a `CORS_ALLOWED_ORIGINS`.
> Reinicie a API após mudar o `.env`.

## Entrar como administrador

1. Abra <http://localhost:8502>.
2. Na tela inicial, clique em **Entrar como administrador**. Esse link fica
   abaixo do título “Identificação por RFID”.
3. No formulário **Acesso administrativo**, o campo **Usuário** já vem
   preenchido com `admin`, se essa for a configuração em `ADMIN_USERNAME`.
4. Digite no campo **Senha de administrador** o valor atual de `ADMIN_PASSWORD`
   salvo no `.env`.
5. Clique em **Entrar como administrador**.

Não informe a senha no campo de leitura do crachá RFID. Se a página estiver
mostrando “Leitura do crachá”, ainda está no modo RFID; clique primeiro no link
de acesso administrativo.

A sessão é assinada pela API, mantida em memória no navegador e expira após o
tempo configurado em `ADMIN_SESSION_TTL_MINUTES`. Ao fechar/recarregar a página
ou sair da conta, pode ser necessário entrar novamente.

### Se as credenciais administrativas foram configuradas agora

1. Confira que as três variáveis `ADMIN_USERNAME`, `ADMIN_PASSWORD` e
   `ADMIN_TOKEN_SECRET` estão preenchidas no `.env` da raiz.
2. Pare a API com `Ctrl+C` no Terminal 1.
3. Inicie-a novamente com o comando acima para ela ler a configuração.
4. Recarregue o Flutter no navegador e tente entrar de novo.

O usuário é `admin` apenas se `ADMIN_USERNAME=admin` estiver configurado. A
senha não tem um valor padrão publicado: use a senha que está no `.env` local.
Se ela foi perdida, gere uma nova, atualize `ADMIN_PASSWORD` no `.env`, reinicie
a API e use a nova senha. Nunca cole o conteúdo do `.env` em issues ou chats.

## Entrar por RFID

1. Na tela de login, selecione **Voltar ao acesso por RFID**, se necessário.
2. Aproxime o crachá de um leitor RFID USB configurado como teclado, ou digite
   o UID manualmente.
3. O UID deve ter de 4 a 32 caracteres hexadecimais (`0–9`, `A–F`).
4. Pressione `Enter` ou clique em **Validar crachá**.

O cadastro precisa existir e estar ativo no banco. Para a base de demonstração,
consulte os UID de teste descritos no README da raiz do repositório. O leitor
USB em modo teclado apenas digita o UID; o navegador não consegue confirmar
se um leitor físico está conectado.

## Streamlit e Flutter

Este repositório tem duas interfaces:

- **Flutter Web:** <http://localhost:8502>, iniciada com os passos deste guia.
- **Streamlit:** <http://localhost:8501>, iniciada separadamente com:

  ```powershell
  Set-Location <pasta-raiz-do-repositorio>
  .\.venv\Scripts\Activate.ps1
  streamlit run app/streamlit_app.py
  ```

As credenciais `ADMIN_USERNAME`/`ADMIN_PASSWORD` descritas neste documento
servem para a opção de acesso administrativo do Flutter. Não presuma que elas
criam uma conta administrativa ou protegem automaticamente a interface
Streamlit.

## Encerrar os serviços

- No terminal do Flutter, pressione `q` para encerrar a execução ou `Ctrl+C`.
- No terminal da API, pressione `Ctrl+C`.
- Para parar o MySQL sem apagar os dados:

  ```powershell
  docker compose stop
  ```

Os dados do banco ficam em um volume do Docker. **Não use `docker compose down
-v` se quiser preservá-los**, porque a opção `-v` remove o volume.

## Problemas comuns

### Não aparece onde digitar usuário e senha

Na tela de RFID, clique em **Entrar como administrador**. O formulário de
usuário/senha só aparece depois de selecionar esse modo. Se o link não estiver
visível, role a página para baixo ou recarregue o app em `http://localhost:8502`.

### A senha é rejeitada

- Confirme que usou a senha de `ADMIN_PASSWORD`, não um UID RFID.
- Confira o usuário configurado em `ADMIN_USERNAME`.
- Verifique se a senha tem ao menos 12 caracteres.
- Se alterou o `.env`, reinicie a API.
- Se perdeu a senha, gere outra e atualize o `.env`; não há recuperação pela
  tela.

### O servidor retorna HTTP 503 ao entrar

O acesso administrativo não está configurado ou os valores não atendem aos
requisitos. Confira `ADMIN_PASSWORD` (mínimo de 12 caracteres) e
`ADMIN_TOKEN_SECRET` (mínimo de 32 bytes), salve o `.env` e reinicie a API.

### A API aparece desconectada ou não abre

- Confirme que o Terminal 1 continua executando o Uvicorn.
- Abra <http://127.0.0.1:8000/health> e verifique a conexão do banco.
- Confirme `API_BASE_URL` no comando Flutter.
- Inicie o MySQL (`docker compose up -d`) e aguarde o estado `healthy`.

### Aparece um erro de CORS

O endereço usado no navegador precisa estar explicitamente em
`CORS_ALLOWED_ORIGINS`. Inclua a origem completa, por exemplo
`http://localhost:8502`, salve o `.env` e reinicie a API. Não configure curingas
em produção.

### A porta 8502 ou 8000 já está em uso

Encerre apenas o programa que você identificou como dono da porta ou escolha
uma porta livre. Ao trocar a porta Flutter, ajuste a origem correspondente em
`CORS_ALLOWED_ORIGINS`; ao trocar a porta da API, atualize
`API_BASE_URL` no comando Flutter.

### O crachá não é aceito

Confirme o formato hexadecimal e que o professor associado ao UID existe e
está ativo no banco. Um UID RFID não substitui a senha administrativa.

## Segurança e limites atuais

- Nunca publique o `.env`, a senha administrativa, a chave de sessão ou valores
  reais de RFID.
- O UID de um crachá não é um segredo confiável: pode ser copiado ou clonado.
- O login administrativo emite uma sessão assinada para o cliente Flutter. As
  demais rotas operacionais que já existiam na API ainda não exigem essa sessão.
  Portanto, não exponha a API em uma rede não confiável nem trate o login atual
  como autorização completa de produção.
- Em produção, além de HTTPS e gestão segura dos segredos, implemente
  autenticação e autorização em todas as rotas que exigirem proteção.
- As operações de retirada e devolução dependem das respostas reais da API e do
  hardware configurado; o Flutter não cria confirmação fictícia.
- O backend atual não oferece autenticação segura para professores, listagem e
  edição de professores, agenda futura ou integração Google Sheets. A agenda
  usa o histórico disponível na API.

## Testes e compilação do Flutter

Na pasta `frontend_flutter`:

```powershell
flutter analyze
flutter test --reporter expanded
flutter build web
```

Os testes usam respostas simuladas isoladas no ambiente de teste. A execução
normal do app consulta a API configurada.
