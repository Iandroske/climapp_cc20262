import 'package:climapp_cc20262/src/controller/weather_city_controller.dart';
import 'package:climapp_cc20262/src/core/exceptions/app_exception.dart';
import 'package:climapp_cc20262/src/core/result.dart';
import 'package:climapp_cc20262/src/database/database_helper.dart';
import 'package:climapp_cc20262/src/models/forecast_model.dart';
import 'package:climapp_cc20262/src/models/weather_forecast.dart';
import 'package:climapp_cc20262/src/models/weather_forecast_model.dart';
import 'package:climapp_cc20262/src/repositories/local_weather_repository.dart';
import 'package:climapp_cc20262/src/services/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeWeatherServiceSuccess extends WeatherService {
  final WeatherForecastModel model;
  FakeWeatherServiceSuccess(this.model);

  @override
  Future<Result<List<WeatherForecastModel>>> getWeatherForecast(
    List<String> listCitySearch,
  ) async {
    return Success([model]);
  }
}

class FakeWeatherServiceFailure extends WeatherService {
  @override
  Future<Result<List<WeatherForecastModel>>> getWeatherForecast(
    List<String> listCitySearch,
  ) async {
    return const Failure(NetworkException('Sem conexão com a internet.'));
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WeatherCityController Tests', () {
    late Database db;
    late DatabaseHelper dbHelper;
    late LocalWeatherRepository repository;

    final mockModel = WeatherForecastModel(
      temp: 29,
      date: '2026-03-30',
      time: '12:00',
      conditionCode: '28',
      description: 'Tempo limpo',
      currently: 'dia',
      city: 'Aracaju',
      imgId: '28',
      humidity: 70,
      cloudiness: 10.0,
      rain: 0.0,
      windSpeedy: '12 km/h',
      windDirection: 180,
      windCardinal: 'S',
      sunrise: '05:30',
      sunset: '17:30',
      moonPhase: 'full',
      conditionSlug: 'clear_day',
      cityName: 'Aracaju',
      timezone: '-03:00',
      forecast: [
        ForecastModel(
          date: '30/03',
          weekday: 'Seg',
          max: 30,
          min: 24,
          humidity: 70,
          cloudiness: 10.0,
          rain: 0.0,
          rainProbability: 0,
          windSpeedy: '12 km/h',
          sunrise: '05:30',
          sunset: '17:30',
          moonPhase: 'full',
          description: 'Ensolarado',
          condition: 'clear_day',
        ),
      ],
    );

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 2,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE cities (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              state TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE forecasts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              city_id INTEGER NOT NULL,
              data TEXT NOT NULL,
              temp_max INTEGER NOT NULL,
              temp_min INTEGER NOT NULL,
              condicao TEXT NOT NULL,
              icon_url TEXT NOT NULL,
              FOREIGN KEY (city_id) REFERENCES cities (id) ON DELETE CASCADE
            )
          ''');
        },
      );
      dbHelper = DatabaseHelper.withDatabase(db);
      repository = LocalWeatherRepository(databaseHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('loadWeather com sucesso da API deve exibir dados online e salvar no SQLite em background', () async {
      final controller = WeatherCityController(
        weatherService: FakeWeatherServiceSuccess(mockModel),
        localWeatherRepository: repository,
      );

      final cityId = await dbHelper.insertCity('Aracaju', 'SE');

      await controller.loadWeather(cityId: cityId, cityName: 'Aracaju');

      expect(controller.isLoading, isFalse);
      expect(controller.isOfflineData, isFalse);
      expect(controller.weatherModel?.cityName, equals('Aracaju'));

      // Aguarda persistência em background
      await Future.delayed(const Duration(milliseconds: 100));

      final localResult = await repository.getForecastsByCityId(cityId);
      expect(localResult.isSuccess, isTrue);
      expect(localResult.dataOrNull?.length, equals(1));
    });

    test('loadWeather com falha da API deve recorrer ao banco local e ativar isOfflineData', () async {
      final cityId = await dbHelper.insertCity('Salvador', 'BA');

      // Pré-carrega previsão no banco de dados local
      await repository.saveForecasts(
        cityId: cityId,
        forecasts: [
          const WeatherForecast(
            cityId: 1,
            data: 'Seg (30/03)',
            tempMax: 31,
            tempMin: 25,
            condicao: 'Sol com nuvens',
            iconUrl: 'cloudy',
          ),
        ],
      );

      final controller = WeatherCityController(
        weatherService: FakeWeatherServiceFailure(),
        localWeatherRepository: repository,
      );

      await controller.loadWeather(cityId: cityId, cityName: 'Salvador');

      expect(controller.isLoading, isFalse);
      expect(controller.isOfflineData, isTrue);
      expect(controller.errorMessage, isEmpty);
      expect(controller.weatherModel?.cityName, equals('Salvador'));
    });

    test('loadWeather com falha da API e banco local vazio deve exibir mensagem de erro amigável', () async {
      final controller = WeatherCityController(
        weatherService: FakeWeatherServiceFailure(),
        localWeatherRepository: repository,
      );

      await controller.loadWeather(cityId: 99, cityName: 'Desconhecida');

      expect(controller.isLoading, isFalse);
      expect(controller.isOfflineData, isFalse);
      expect(controller.errorMessage, contains('Sem conexão'));
    });
  });
}
