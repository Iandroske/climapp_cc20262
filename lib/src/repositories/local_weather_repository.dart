import 'package:climapp_cc20262/src/core/exceptions/app_exception.dart';
import 'package:climapp_cc20262/src/core/result.dart';
import 'package:climapp_cc20262/src/database/database_helper.dart';
import 'package:climapp_cc20262/src/models/weather_forecast.dart';

/// Repositório local responsável pela persistência e recuperação de previsões do tempo no SQLite.
/// Encapsula o [DatabaseHelper] e converte todas as exceções em um objeto [Result<T>].
class LocalWeatherRepository {
  final DatabaseHelper _databaseHelper;

  LocalWeatherRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  /// Salva uma lista de previsões para determinada cidade.
  /// Se [clearExisting] for `true`, remove as previsões anteriores da mesma cidade.
  Future<Result<List<WeatherForecast>>> saveForecasts({
    required int cityId,
    required List<WeatherForecast> forecasts,
    bool clearExisting = true,
  }) async {
    try {
      if (clearExisting) {
        await _databaseHelper.deleteOldForecasts(cityId);
      }

      final List<WeatherForecast> savedForecasts = [];
      for (final forecast in forecasts) {
        final id = await _databaseHelper.insertForecast(forecast);
        savedForecasts.add(forecast.copyWith(id: id));
      }

      return Success(savedForecasts);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(DatabaseAppException('Erro ao salvar previsões locais: $e'));
    }
  }

  /// Busca a lista de previsões locais de uma cidade pelo [cityId].
  Future<Result<List<WeatherForecast>>> getForecastsByCityId(int cityId) async {
    try {
      final forecasts = await _databaseHelper.getForecastsByCityId(cityId);
      return Success(forecasts);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(DatabaseAppException('Erro ao consultar previsões locais: $e'));
    }
  }

  /// Remove as previsões locais salvas referentes ao [cityId].
  Future<Result<int>> deleteOldForecasts(int cityId) async {
    try {
      final deletedCount = await _databaseHelper.deleteOldForecasts(cityId);
      return Success(deletedCount);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(DatabaseAppException('Erro ao remover previsões locais: $e'));
    }
  }

  /// Salva uma cidade no banco local e retorna seu ID gerado.
  Future<Result<int>> saveCity(String name, String? state) async {
    try {
      final cityId = await _databaseHelper.insertCity(name, state);
      return Success(cityId);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(DatabaseAppException('Erro ao salvar cidade localmente: $e'));
    }
  }
}
