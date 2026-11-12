"""Exceções de negócio. A API converte cada uma em um status HTTP."""


class AppError(Exception):
    """Base de todos os erros esperados da aplicação."""


class ProfessorNotFoundError(AppError):
    """Crachá não cadastrado."""


class ProfessorInactiveError(AppError):
    """Cadastro do professor está inativo."""


class InsufficientAvailabilityError(AppError):
    """Mais tablets solicitados do que disponíveis."""


class CabinetNotFoundError(AppError):
    """Armário não cadastrado."""


class CabinetBusyError(AppError):
    """Já existe uma retirada em andamento neste armário."""


class SessionNotFoundError(AppError):
    """Solicitação não encontrada."""


class InvalidSessionStateError(AppError):
    """Operação não permitida no estado atual da solicitação."""


class LockError(AppError):
    """Fechadura não confirmou o comando (erro ou timeout)."""


class ReaderError(AppError):
    """Leitor de crachá/tablets falhou."""


class InvalidUidError(AppError):
    """UID com formato inválido."""


class ProfessorSourceUnavailableError(AppError):
    """The configured read-only professor source is unavailable."""


class ProfessorImportInvalidError(AppError):
    """Invalid or ambiguous professor data; nothing is imported."""


class ProfessorImportConflictError(AppError):
    """An imported badge belongs to another local professor."""
