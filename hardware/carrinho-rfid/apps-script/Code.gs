const CONFIG = {
  NOME_ABA: "Leituras_RFID",
  FUSO_HORARIO: "America/Sao_Paulo",
  FORMATO_DATA: "dd/MM/yyyy HH:mm:ss",
  TERMINAL_PADRAO: "Carrinho_Tablets"
};

// Cria o menu da planilha
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu("Sistema RFID")
    .addItem("Configurar planilha", "configurarPlanilha")
    .addToUi();
}

// Cria a aba e os cabeçalhos
function configurarPlanilha() {
  const planilha = SpreadsheetApp.getActiveSpreadsheet();

  let aba = planilha.getSheetByName(CONFIG.NOME_ABA);

  if (!aba) {
    aba = planilha.insertSheet(CONFIG.NOME_ABA);
  }

  const cabecalhos = [
    "Data/Hora",
    "UID",
    "Terminal",
    "Status"
  ];

  aba.getRange(1, 1, 1, cabecalhos.length)
    .setValues([cabecalhos]);

  aba.getRange(1, 1, 1, cabecalhos.length)
    .setFontWeight("bold");

  aba.setFrozenRows(1);
  aba.setColumnWidths(1, 4, 180);
  aba.getRange("B:B").setNumberFormat("@");

  Logger.log("Planilha configurada com sucesso!");
}

// Recebe os dados do ESP32
function doGet(e) {
  try {
    const parametros = e && e.parameter
      ? e.parameter
      : {};

    const uid = String(parametros.uid || "")
      .trim()
      .toUpperCase();

    const terminal = String(
      parametros.terminal || CONFIG.TERMINAL_PADRAO
    ).trim();

    if (!/^[0-9A-F]{1,32}$/.test(uid)) {
      return responder("erro:UID invalido");
    }

    const planilha = SpreadsheetApp.getActiveSpreadsheet();

    const aba = planilha.getSheetByName(CONFIG.NOME_ABA);

    if (!aba) {
      return responder("erro:Planilha nao configurada");
    }

    const agora = Utilities.formatDate(
      new Date(),
      CONFIG.FUSO_HORARIO,
      CONFIG.FORMATO_DATA
    );

    const bloqueio = LockService.getScriptLock();

    bloqueio.waitLock(10000);

    try {
      aba.appendRow([
        agora,
        uid,
        terminal,
        "RECEBIDO"
      ]);

      SpreadsheetApp.flush();
    } finally {
      bloqueio.releaseLock();
    }

    return responder("ok:" + uid + ":Registrado");

  } catch (erro) {
    Logger.log("Erro: " + erro.message);

    return responder("erro:Falha no registro");
  }
}

// Retorna a resposta ao ESP32
function responder(mensagem) {
  return ContentService
    .createTextOutput(mensagem)
    .setMimeType(ContentService.MimeType.TEXT);
}
