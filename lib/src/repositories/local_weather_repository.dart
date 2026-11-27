import 'package:climapp_cc20262/src/core/exceptions/app_exception.dart';
import 'package:climapp_cc20262/src/core/result.dart';
import 'package:climapp_cc20262/src/database/database_helper.dart';
import 'package:climapp_cc20262/src/models/forecast_model.dart';
import 'package:climapp_cc20262/src/models/weather_forecast.dart';
import 'package:climapp_cc20262/src/models/weather_forecast_model.dart';

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

  /// Busca todas as cidades salvas no SQLite, reconstruindo a lista de [WeatherForecastModel].
  Future<Result<List<WeatherForecastModel>>> getAllSavedCities() async {
    try {
      final cityMaps = await _databaseHelper.getAllCities();
      final List<WeatherForecastModel> resultList = [];

      for (final map in cityMaps) {
        final cityId = map['id'] as int;
        final name = map['name'] as String;

        final forecasts = await _databaseHelper.getForecastsByCityId(cityId);

        if (forecasts.isNotEmpty) {
          final forecastModels = forecasts.map((item) {
            return ForecastModel(
              date: item.data,
              weekday: item.data,
              max: item.tempMax,
              min: item.tempMin,
              humidity: 0,
              cloudiness: 0.0,
              rain: 0.0,
              rainProbability: 0,
              windSpeedy: '',
              sunrise: '',
              sunset: '',
              moonPhase: 'full',
              description: item.condicao,
              condition: item.iconUrl,
            );
          }).toList();

          final first = forecasts.first;
          final model = WeatherForecastModel(
            temp: ((first.tempMax + first.tempMin) / 2).round(),
            date: first.data,
            time: 'Offline',
            conditionCode: '28',
            description: '${first.condicao} (Offline)',
            currently: 'dia',
            city: name,
            imgId: '28',
            humidity: 0,
            cloudiness: 0.0,
            rain: 0.0,
            windSpeedy: '',
            windDirection: 0,
            windCardinal: '',
            sunrise: '',
            sunset: '',
            moonPhase: 'full',
            conditionSlug: first.iconUrl,
            cityName: name,
            timezone: '',
            forecast: forecastModels,
          );
          resultList.add(model);
        } else {
          final fallbackModel = WeatherForecastModel(
            temp: 25,
            date: 'Hoje',
            time: 'Offline',
            conditionCode: '28',
            description: 'Dados Locais (Sem Previsão)',
            currently: 'dia',
            city: name,
            imgId: '28',
            humidity: 0,
            cloudiness: 0.0,
            rain: 0.0,
            windSpeedy: '',
            windDirection: 0,
            windCardinal: '',
            sunrise: '',
            sunset: '',
            moonPhase: 'full',
            conditionSlug: 'cloud',
            cityName: name,
            timezone: '',
            forecast: [],
          );
          resultList.add(fallbackModel);
        }
      }

      return Success(resultList);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(DatabaseAppException('Erro ao consultar cidades salvas: $e'));
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
