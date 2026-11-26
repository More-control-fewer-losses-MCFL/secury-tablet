const CONFIG = {
  ABA_LOGS: "Logs",
  ABA_LEGADA: "Leituras_RFID",
  FUSO_HORARIO: "America/Sao_Paulo",
  FORMATO_DATA: "dd/MM/yyyy HH:mm:ss",
  TERMINAL_PADRAO: "Carrinho_Tablets"
};

const ABAS = [
  { nome: "Tablets", cabecalhos: ["asset_code", "rfid_tag_uid"], texto: "A:B" },
  {
    nome: "Professores",
    cabecalhos: ["registration", "name", "badge_uid", "active"],
    texto: "A:C"
  },
  {
    nome: CONFIG.ABA_LOGS,
    cabecalhos: ["Data/Hora", "UID", "Terminal", "Status"],
    texto: "B:B"
  }
];

// Cria o menu da planilha
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu("Sistema RFID")
    .addItem("Configurar planilha", "configurarPlanilha")
    .addToUi();
}

// Prepara as abas e reaproveita o histórico do protótipo.
function configurarPlanilha() {
  const planilha = SpreadsheetApp.getActiveSpreadsheet();
  const bloqueio = LockService.getScriptLock();
  bloqueio.waitLock(10000);
  try {
    const legado = planilha.getSheetByName(CONFIG.ABA_LEGADA);
    if (legado && planilha.getSheetByName(CONFIG.ABA_LOGS)) {
      throw new Error("As abas Logs e Leituras_RFID coexistem. Confira os históricos antes de prosseguir.");
    }

    const estrutura = ABAS.map(({ nome, cabecalhos, texto }) => ({
      nome,
      cabecalhos,
      texto,
      aba: nome === CONFIG.ABA_LOGS && legado ? legado : planilha.getSheetByName(nome)
    }));
    for (const { nome, cabecalhos, aba } of estrutura) {
      if (aba && aba.getLastRow() > 0) {
        const atual = aba.getRange(1, 1, 1, cabecalhos.length).getDisplayValues()[0];
        const compativel = cabecalhos.every(
          (campo, indice) => atual[indice].trim().toLowerCase() === campo.toLowerCase()
        );
        if (!compativel) {
          throw new Error("Confira o cabeçalho da aba " + nome + ".");
        }
      }
    }

    if (legado) {
      legado.setName(CONFIG.ABA_LOGS);
    }
    for (const { nome, cabecalhos, texto, aba: existente } of estrutura) {
      const aba = existente || planilha.insertSheet(nome);
      const faixa = aba.getRange(1, 1, 1, cabecalhos.length);
      if (aba.getLastRow() === 0) {
        faixa.setValues([cabecalhos]);
      }
      faixa.setFontWeight("bold");
      aba.setFrozenRows(1);
      aba.setColumnWidths(1, cabecalhos.length, 180);
      aba.getRange(texto).setNumberFormat("@");
    }
    SpreadsheetApp.flush();
  } finally {
    bloqueio.releaseLock();
  }
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

    const agora = Utilities.formatDate(
      new Date(),
      CONFIG.FUSO_HORARIO,
      CONFIG.FORMATO_DATA
    );

    const bloqueio = LockService.getScriptLock();

    bloqueio.waitLock(10000);

    try {
      const aba = planilha.getSheetByName(CONFIG.ABA_LOGS)
        || planilha.getSheetByName(CONFIG.ABA_LEGADA);
      if (!aba) {
        return responder("erro:Planilha nao configurada");
      }
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
