
#include <SPI.h>
#include <MFRC522.h>

// Pinos do RFID
#define SS_PIN 15
#define RST_PIN 13

// Criação do objeto RFID
MFRC522 rfid(SS_PIN, RST_PIN);

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println();
  Serial.println("================================");
  Serial.println("       TESTE DO RFID");
  Serial.println("================================");

  // Inicializa comunicação SPI
  SPI.begin(18, 19, 23, 15);

  Serial.println("SPI inicializada!");

  // Inicializa leitor RFID
  rfid.PCD_Init();
  delay(100);

  Serial.println("Testando estabilidade da comunicacao...");

  for (int i = 0; i < 10; i++) {
    byte versao = rfid.PCD_ReadRegister(rfid.VersionReg);

    Serial.print("Leitura ");
    Serial.print(i + 1);
    Serial.print(": 0x");
    Serial.println(versao, HEX);

    delay(500);
  }

  Serial.println("Leitor inicializado!");

  // Verifica versão do módulo
  byte versao = rfid.PCD_ReadRegister(rfid.VersionReg);

  Serial.print("Versao do RC522: 0x");
  Serial.println(versao, HEX);

  if (versao == 0x91 || versao == 0x92) {
    Serial.println("RC522 reconhecido!");
  } else {
    Serial.println("ATENCAO: versao inesperada!");
  }

  // Testa o registrador de controle da antena
  Serial.println();
  Serial.println("Verificando antena RFID...");

  byte txControl = rfid.PCD_ReadRegister(rfid.TxControlReg);

  Serial.print("TxControl: 0x");
  Serial.println(txControl, HEX);

  if ((txControl & 0x03) == 0x03) {
    Serial.println("Antena ativada!");
  } else {
    Serial.println("Antena desativada!");
  }

  Serial.println();
  Serial.println("Aproxime uma tag RFID...");
}

void loop() {

  // Verifica se existe um novo cartao
  if (!rfid.PICC_IsNewCardPresent()) {
    return;
  }

  // Tenta ler o cartao
  if (!rfid.PICC_ReadCardSerial()) {
    return;
  }

  Serial.println("TAG DETECTADA!");

  // Finaliza leitura
  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();

  delay(1000);
}
