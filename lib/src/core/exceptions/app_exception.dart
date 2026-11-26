/// Classe abstrata base para todas as exceções customizadas da aplicação.
/// Mapeia erros de rede, API e sistema em mensagens amigáveis prontas para a UI.
sealed class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppException &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => Object.hash(message, code);
}

/// Exceção lançada quando não há conexão de rede disponível.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Sem conexão com a internet. Verifique sua rede.',
  ]) : super(code: 'NETWORK_ERROR');
}

/// Exceção lançada quando uma requisição excede o tempo limite estabelecido.
class TimeoutNetworkException extends AppException {
  const TimeoutNetworkException([
    super.message = 'Tempo limite esgotado. Verifique sua conexão e tente novamente.',
  ]) : super(code: 'TIMEOUT_ERROR');
}

/// Exceção genérica para respostas de erro HTTP da API.
class ApiException extends AppException {
  final int? statusCode;

  const ApiException(
    super.message, {
    this.statusCode,
    super.code = 'API_ERROR',
  });
}

/// Exceção para recursos ou cidades não encontradas na API.
class NotFoundException extends ApiException {
  const NotFoundException([
    super.message = 'Cidade não encontrada ou chave de API inválida.',
  ]) : super(statusCode: 404, code: 'NOT_FOUND');
}

/// Exceção lançada durante falhas de persistência ou consulta no banco de dados SQLite local.
class DatabaseAppException extends AppException {
  const DatabaseAppException([
    super.message = 'Erro ao acessar o banco de dados local. Tente novamente.',
  ]) : super(code: 'DATABASE_ERROR');
}

/// Exceção para erros não mapeados ou falhas inesperadas.
class UnknownException extends AppException {
  const UnknownException([
    super.message = 'Ocorreu um erro inesperado. Tente novamente mais tarde.',
  ]) : super(code: 'UNKNOWN_ERROR');
}
