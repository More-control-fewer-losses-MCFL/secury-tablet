enum ApiErrorKind {
  validation,
  authentication,
  authorization,
  notFound,
  conflict,
  rateLimit,
  server,
  network,
  timeout,
  invalidResponse,
  unknown,
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.kind});

  final String message;
  final int? statusCode;
  final ApiErrorKind? kind;

  ApiErrorKind get category =>
      kind ??
      switch (statusCode) {
        400 || 422 => ApiErrorKind.validation,
        401 => ApiErrorKind.authentication,
        403 => ApiErrorKind.authorization,
        404 => ApiErrorKind.notFound,
        409 => ApiErrorKind.conflict,
        429 => ApiErrorKind.rateLimit,
        final int status when status >= 500 => ApiErrorKind.server,
        _ => ApiErrorKind.unknown,
      };

  String get title => switch (category) {
    ApiErrorKind.validation => 'Revise os dados',
    ApiErrorKind.authentication => 'Acesso não confirmado',
    ApiErrorKind.authorization => 'Acesso não permitido',
    ApiErrorKind.notFound => 'Registro não encontrado',
    ApiErrorKind.conflict => 'Operação não concluída',
    ApiErrorKind.rateLimit => 'Muitas tentativas',
    ApiErrorKind.server => 'Sistema temporariamente indisponível',
    ApiErrorKind.network => 'Falha de conexão',
    ApiErrorKind.timeout => 'Tempo de resposta excedido',
    ApiErrorKind.invalidResponse => 'Resposta não reconhecida',
    ApiErrorKind.unknown => 'Não foi possível concluir',
  };

  String get recoveryHint => switch (category) {
    ApiErrorKind.validation =>
      'Confira os campos indicados e confirme novamente.',
    ApiErrorKind.authentication =>
      'Confira seu usuário e senha. Se precisar, procure a administração.',
    ApiErrorKind.authorization =>
      'Solicite ajuda à administração para verificar seu acesso.',
    ApiErrorKind.notFound =>
      'Atualize a consulta ou confira o registro selecionado.',
    ApiErrorKind.conflict =>
      'Atualize os dados e confira a situação antes de tentar novamente.',
    ApiErrorKind.rateLimit => 'Aguarde um pouco antes de tentar novamente.',
    ApiErrorKind.network || ApiErrorKind.timeout => 'Verifique sua conexão. Se enviou uma operação, confira o histórico antes de repeti-la.',
    ApiErrorKind.server || ApiErrorKind.invalidResponse => 'Tente consultar o estado do sistema mais tarde. Se enviou uma operação, confira o histórico antes de repeti-la.',
    ApiErrorKind.unknown =>
      'Tente novamente. Se o problema continuar, procure a administração.',
  };

  factory ApiException.fromResponse(
    int status,
    Object? body, {
    bool login = false,
    bool rfid = false,
  }) {
    final data = body is Map<String, dynamic>
        ? body
        : const <String, dynamic>{};
    // Only curated descriptions are rendered; never echo payloads or server details.
    const businessMessages = {
      'ProfessorNotFoundError': 'Professor não cadastrado.',
      'ProfessorInactiveError': 'O cadastro do professor está inativo.',
      'ProfessorLoginInvalidError': 'Usuário ou senha inválidos.',
      'ProfessorCredentialsConflictError':
          'Este usuário já está vinculado a outro professor.',
      'InsufficientAvailabilityError':
          'A quantidade solicitada excede os tablets disponíveis.',
      'CabinetBusyError': 'Há uma operação em andamento neste armário.',
      'CabinetNotFoundError': 'Armário não encontrado.',
      'SessionNotFoundError': 'Solicitação não encontrada.',
      'InvalidSessionStateError':
          'A solicitação não permite esta operação no estado atual.',
      'InvalidUidError': 'A leitura do crachá tem um formato inválido.',
      'LockError': 'A fechadura não confirmou o comando. A operação precisa ser conferida.',
      'ReaderError': 'Não foi possível confirmar a leitura do inventário.',
      'ProfessorSourceUnavailableError':
          'A fonte de cadastro dos professores está indisponível.',
      'ProfessorImportInvalidError':
          'A planilha contém dados inválidos ou ambíguos.',
      'ProfessorImportConflictError':
          'A importação conflita com cadastros existentes.',
    };
    // Authentication through RFID requires a separately authorized terminal.
    const terminalMessages = {
      'Terminal não autorizado. Solicite autorização ao administrador.',
      'Terminal não autorizado ou revogado.',
      'Sessão vinculada a outro terminal.',
    };
    final code = data['code'];
    if (code is String && businessMessages.containsKey(code)) {
      return ApiException(businessMessages[code]!, statusCode: status);
    }
    if (status == 401 && (rfid || terminalMessages.contains(data['detail']))) {
      return ApiException(
        'Este terminal não está autorizado para acesso por crachá.',
        statusCode: status,
        kind: ApiErrorKind.authorization,
      );
    }
    if (status == 400 || status == 422) {
      const fields = {
        'username': 'Usuário',
        'password': 'Senha',
        'badge_uid': 'Leitura do crachá',
        'quantity': 'Quantidade',
        'purpose': 'Finalidade',
        'class_name': 'Turma',
        'since': 'Data inicial',
        'until': 'Data final',
      };
      final labels = <String>{};
      final details = data['detail'];
      if (details is List) {
        for (final detail in details) {
          if (detail is Map && detail['loc'] is List) {
            for (final part in detail['loc'] as List) {
              final label = fields[part];
              if (label != null) labels.add(label);
            }
          }
        }
      }
      return ApiException(
        labels.isEmpty
            ? 'Há dados inválidos na solicitação.'
            : 'Confira os campos: ${labels.join(', ')}.',
        statusCode: status,
      );
    }
    final message = switch (status) {
      401 =>
        login
            ? 'Usuário ou senha inválidos.'
            : 'Sua sessão não é válida. Entre novamente.',
      403 => 'Seu perfil não tem permissão para esta operação.',
      404 => 'O registro solicitado não foi encontrado.',
      409 => 'Os dados mudaram ou há uma operação em andamento.',
      429 => 'O limite de tentativas foi atingido.',
      >= 500 => 'Não foi possível concluir a comunicação com o sistema.',
      _ => 'Não foi possível concluir a solicitação.',
    };
    return ApiException(message, statusCode: status);
  }

  @override
  String toString() => message;
}
