import 'exceptions/app_exception.dart';

/// Sealed class que representa o resultado de uma operação assíncrona.
/// Pode ser [Success] contendo os dados de tipo [T] ou [Failure] contendo uma [AppException].
sealed class Result<T> {
  const Result();

  /// Retorna `true` se o resultado for [Success].
  bool get isSuccess => this is Success<T>;

  /// Retorna `true` se o resultado for [Failure].
  bool get isFailure => this is Failure<T>;

  /// Retorna os dados se for [Success], ou `null` se for [Failure].
  T? get dataOrNull => switch (this) {
        Success(:final data) => data,
        Failure() => null,
      };

  /// Retorna a exceção se for [Failure], ou `null` se for [Success].
  AppException? get exceptionOrNull => switch (this) {
        Success() => null,
        Failure(:final exception) => exception,
      };

  /// Executa [onSuccess] se for [Success] ou [onFailure] se for [Failure].
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(AppException exception) onFailure,
  }) {
    return switch (this) {
      Success(:final data) => onSuccess(data),
      Failure(:final exception) => onFailure(exception),
    };
  }

  /// Retorna os dados se for [Success], ou o valor padrão [fallback] se for [Failure].
  T getOrElse(T fallback) {
    return switch (this) {
      Success(:final data) => data,
      Failure() => fallback,
    };
  }
}

/// Estado de sucesso contendo os dados do tipo [T].
final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Estado de falha contendo uma [AppException].
final class Failure<T> extends Result<T> {
  final AppException exception;

  const Failure(this.exception);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          exception == other.exception;

  @override
  int get hashCode => exception.hashCode;
}
