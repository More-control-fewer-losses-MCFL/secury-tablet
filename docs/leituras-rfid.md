# Leituras RFID do carrinho

O ESP32 lê a etiqueta pelo RC522. O Apps Script grava o evento na aba
`Logs`. O backend do Secury Tablet consulta a aba pelo Google Sheets
e exibe as últimas dez leituras em **Início → Leituras RFID do carrinho**,
no portal administrativo. A consulta é manual e a planilha mantém o histórico
bruto. Retiradas, devoluções, cadastro e permissões seguem os fluxos do sistema.

## Abas da planilha

| Aba | Colunas | Uso |
| --- | --- | --- |
| `Tablets` | `asset_code`, `rfid_tag_uid` | Cadastro de patrimônio e etiqueta na planilha |
| `Professores` | `registration`, `name`, `badge_uid`, `active` | Fonte para a sincronização administrativa existente |
| `Logs` | `Data/Hora`, `UID`, `Terminal`, `Status` | Registros recebidos do ESP32 |

Preencha os cadastros nas respectivas abas. Passar uma tag acrescenta uma linha
em `Logs`. O inventário de tablets continua gerenciado no MySQL pelo sistema.

Para migrar, publique uma nova versão do Apps Script na implantação existente
e execute `configurarPlanilha` no editor. A função renomeia `Leituras_RFID` para
`Logs` preservando as linhas e cria as abas que estiverem faltando. Se já
existirem as duas abas de histórico ou um cabeçalho incompatível, a função
interrompe a configuração para permitir a revisão dos dados.
Depois da migração, ajuste `RFID_SHEETS_TAB=Logs` no `.env` e reaplique o Compose.

## Ativar a consulta

1. Confirme que as colunas A:D da aba têm os cabeçalhos `Data/Hora`, `UID`,
   `Terminal` e `Status`, nessa ordem. Mantenha a coluna de UID como texto
   simples para preservar zeros à esquerda.
2. Na raiz do Secury Tablet, preencha o `.env` local.

   ```dotenv
   RFID_SHEETS_ENABLED=true
   RFID_SHEETS_SPREADSHEET_ID=ID_DA_PLANILHA
   RFID_SHEETS_TAB=Logs
   ```

   Em uma planilha que ainda usa a aba antiga, mantenha
   `RFID_SHEETS_TAB=Leituras_RFID` até fazer a migração.

3. No servidor nativo, configure `RFID_SHEETS_TOKEN_FILE` com o caminho privado
   do `token.json` gerado pelo protótipo. O token deve conter `client_id`,
   `client_secret`, `refresh_token` e apenas o escopo
   `https://www.googleapis.com/auth/spreadsheets.readonly`. A conta do token
   precisa ter acesso à planilha. Se for necessário renovar o consentimento,
   gere o token em uma máquina com navegador, fora do servidor.
4. Em Docker, configure `RFID_SHEETS_TOKEN_HOST_FILE` com o caminho absoluto
   de um token legível pelo usuário da API no contêiner. O arquivo é montado
   em modo somente leitura.

   ```powershell
   docker compose -f docker-compose.yml -f docker/rfid-sheets.override.yml up -d
   ```

5. Entre como administrador, abra **Início** e clique em **Consultar**.

As variáveis são específicas para o carrinho. A integração de
[cadastro de professores](google-sheets-professors.md) usa sua própria configuração.
O ID da planilha fica entre `/d/` e a próxima barra na URL do Google Sheets.

## Endpoint administrativo

`GET /admin/rfid/leituras?limite=10` exige o Bearer de `POST /admin/login`.
Pelo Nginx, use o prefixo `/api`. O limite é de 1 a 100 e o padrão é 10.
As linhas preenchidas são devolvidas da última para a primeira, preservando
o formato de data e hora da planilha. Células de fim de linha ausentes saem
como `null`. Uma aba vazia ou contendo apenas cabeçalho retorna `{"leituras":[]}`.

Exemplo com dados fictícios.

```json
{
  "leituras": [{
    "data/hora": "19/11/2026 16:40:17",
    "uid": "0012AABB",
    "terminal": "Carrinho_Tablets",
    "status": "RECEBIDO"
  }]
}
```

| HTTP | Resultado |
| --- | --- |
| 401 | Sessão administrativa inválida ou ausente |
| 422 | Limite fora do intervalo ou em formato inválido |
| 502 | O Google Sheets ou a aba não pôde ser lido |
| 503 | Consulta RFID desativada ou com configuração incompleta |

A API lê o intervalo A1:D para localizar as últimas linhas preenchidas. O limite
se aplica à resposta. Avalie o tempo de consulta à medida que o histórico crescer.

## Firmware e Apps Script

O código está em [hardware/carrinho-rfid](../hardware/carrinho-rfid). Se já existe
uma implantação em uso, mantenha a URL atual na configuração privada do firmware.
Para montar uma bancada nova, use uma planilha de teste.

1. Em **Extensões → Apps Script**, cole o conteúdo de
   [Code.gs](../hardware/carrinho-rfid/apps-script/Code.gs). Execute
   `configurarPlanilha` e publique o script como aplicativo da Web conforme
   as permissões da conta. Copie a URL da implantação que termina em `/exec`.
2. Na Arduino IDE, selecione **ESP32 Dev Module**, instale a biblioteca MFRC522
   e abra [carrinho_rfid.ino](../hardware/carrinho-rfid/esp32/carrinho_rfid/carrinho_rfid.ino).
   O sketch usa `useBuiltinCACertBundle()` do Arduino-ESP32 3.3.12.
3. Na pasta do sketch, copie `config.example.h` para `config.local.h`.
   Preencha o Wi-Fi de 2,4 GHz e a URL `/exec`. Gere o horário Unix de bancada
   antes de gravar com `[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()`.
   Se já existir um `config.local.h`, acrescente os dois parâmetros do servo
   do exemplo ao arquivo existente. O relógio manual é provisório.
4. Ligue o RC522 ao ESP32. Abra o Monitor Serial a 115200 baud, aproxime uma
   tag de teste e confira a mensagem de confirmação e a linha no painel.
   O sketch [diagnostico_rc522.ino](../hardware/carrinho-rfid/esp32/diagnostico_rc522/diagnostico_rc522.ino)
   verifica o leitor sem enviar dados.

| RC522 | ESP32 |
| --- | --- |
| 3.3V | 3V3 |
| GND | GND |
| SDA/SS | GPIO 5 |
| SCK | GPIO 18 |
| MISO | GPIO 19 |
| MOSI | GPIO 23 |
| RST | GPIO 27 |
| IRQ | Livre |

## Servo da porta

- Ligue o sinal do servo ao **GPIO 13**. Use uma fonte adequada ao modelo do
  servo e compartilhe o GND da fonte com o ESP32.
- Com o braço fora do mecanismo da porta, ajuste `SERVO_ABERTO_US` e
  `SERVO_FECHADO_US` no `config.local.h` para as duas posições. Os pulsos
  do exemplo são pontos de partida para bancada.
- No Monitor Serial a 115200 baud, envie `a` para abrir e `f` para fechar.
  O PWM começa no primeiro comando. Confira visualmente cada posição antes de
  conectar o braço à porta.

O comando Serial é de bancada. A mensagem indica o envio do PWM. A posição
física precisa ser conferida no equipamento. O painel segue com hardware simulado.

O Apps Script mantém o protocolo de bancada do firmware. Uma requisição
aceita pelo script registra uma leitura na planilha. Use o painel para conferência
das leituras e o histórico do Secury Tablet para auditoria das movimentações.
