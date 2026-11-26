#include <Arduino.h>
#include <SPI.h>
#include <MFRC522.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <sys/time.h>

#include "config.local.h"

constexpr uint8_t PINO_SCK = 18;
constexpr uint8_t PINO_MISO = 19;
constexpr uint8_t PINO_MOSI = 23;
constexpr uint8_t PINO_CS = 5;
constexpr uint8_t PINO_RST = 27;

MFRC522 leitor(PINO_CS, PINO_RST);
bool relogioAjustado = false;

void enviarUID(const String& uid) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[Wi-Fi] Sem conexao. Aproxime a tag quando a rede voltar.");
    return;
  }

  if (!relogioAjustado) {
    Serial.println("[Hora] Ajuste do relogio pendente. Envio cancelado.");
    return;
  }

  WiFiClientSecure cliente;
  cliente.useBuiltinCACertBundle();

  HTTPClient http;
  http.setConnectTimeout(10000);
  http.setTimeout(15000);
  http.setFollowRedirects(HTTPC_STRICT_FOLLOW_REDIRECTS);

  const String url = String(URL_APPS_SCRIPT) + "?uid=" + uid;

  if (!http.begin(cliente, url)) {
    Serial.println("[HTTP] Falha ao iniciar a chamada.");
    return;
  }

  Serial.println("[Planilha] Enviando leitura.");

  const int codigo = http.GET();
  Serial.printf("[HTTP] Codigo: %d\n", codigo);

  if (codigo > 0) {
    String resposta = http.getString();
    resposta.trim();
    if (codigo == HTTP_CODE_OK && resposta == String("ok:") + uid + ":Registrado") {
      Serial.println("[Apps Script] Leitura registrada.");
    } else {
      Serial.println("[Apps Script] Registro nao confirmado.");
    }
  } else {
    Serial.println(HTTPClient::errorToString(codigo));

    char detalhe[160] = {};
    const int erroTLS = cliente.lastError(detalhe, sizeof(detalhe));

    if (erroTLS != 0) {
      Serial.printf("[TLS] %d: %s\n", erroTLS, detalhe);
    }
  }

  http.end();
}

void setup() {
  Serial.begin(115200);
  delay(500);

  SPI.begin(PINO_SCK, PINO_MISO, PINO_MOSI, PINO_CS);
  leitor.PCD_Init();
  delay(4);

  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.begin(WIFI_NOME, WIFI_SENHA);

  Serial.print("[Wi-Fi] Conectando");
  const unsigned long inicio = millis();

  while (WiFi.status() != WL_CONNECTED && millis() - inicio < 20000) {
    Serial.print(".");
    delay(500);
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("[Wi-Fi] IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("[Wi-Fi] Falha na conexao inicial.");
  }

  // Horário manual para o diagnóstico de bancada.
  struct timeval agora = {};
  agora.tv_sec = HORA_TESTE;
  relogioAjustado = settimeofday(&agora, nullptr) == 0;

  if (relogioAjustado) {
    Serial.println("[Hora] Relogio ajustado manualmente.");
  } else {
    Serial.println("[Hora] Falha ao ajustar o relogio.");
  }

  Serial.println("[RFID] Aproxime uma tag.");
}

void loop() {
  if (!leitor.PICC_IsNewCardPresent() || !leitor.PICC_ReadCardSerial()) {
    return;
  }

  String uid;
  uid.reserve(leitor.uid.size * 2);

  for (byte i = 0; i < leitor.uid.size; i++) {
    const byte valor = leitor.uid.uidByte[i];
    if (valor < 0x10) {
      uid += '0';
    }
    uid += String(valor, HEX);
  }

  uid.toUpperCase();
  leitor.PICC_HaltA();

  Serial.println("[RFID] Tag detectada.");
  enviarUID(uid);
}