import 'package:climapp_cc20262/src/core/exceptions/app_exception.dart';
import 'package:climapp_cc20262/src/core/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result Pattern & AppException', () {
    test('Success deve identificar isSuccess como true e retornar dados', () {
      const Result<String> result = Success('Salvador,BA');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, equals('Salvador,BA'));
      expect(result.exceptionOrNull, isNull);
    });

    test('Failure deve identificar isFailure como true e retornar exceção', () {
      const Result<String> result = Failure(NetworkException());

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.exceptionOrNull, isA<NetworkException>());
      expect(result.exceptionOrNull?.message, contains('Sem conexão'));
    });

    test('fold deve disparar o callback correto para Success e Failure', () {
      const Result<int> successResult = Success(42);
      const Result<int> failureResult = Failure(TimeoutNetworkException());

      final successVal = successResult.fold(
        onSuccess: (data) => data * 2,
        onFailure: (ex) => -1,
      );

      final failureVal = failureResult.fold(
        onSuccess: (data) => data * 2,
        onFailure: (ex) => -1,
      );

      expect(successVal, equals(84));
      expect(failureVal, equals(-1));
    });

    test('getOrElse deve retornar dados no Success e fallback no Failure', () {
      const Result<String> success = Success('Aracaju,SE');
      const Result<String> failure = Failure(NotFoundException());

      expect(success.getOrElse('Default'), equals('Aracaju,SE'));
      expect(failure.getOrElse('Default'), equals('Default'));
    });
  });
}
