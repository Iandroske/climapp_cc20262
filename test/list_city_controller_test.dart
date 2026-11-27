import 'package:climapp_cc20262/src/controller/list_city_controller.dart';
import 'package:climapp_cc20262/src/core/exceptions/app_exception.dart';
import 'package:climapp_cc20262/src/core/result.dart';
import 'package:climapp_cc20262/src/database/database_helper.dart';
import 'package:climapp_cc20262/src/models/forecast_model.dart';
import 'package:climapp_cc20262/src/models/weather_forecast.dart';
import 'package:climapp_cc20262/src/models/weather_forecast_model.dart';
import 'package:climapp_cc20262/src/repositories/local_weather_repository.dart';
import 'package:climapp_cc20262/src/services/device_info_service.dart';
import 'package:climapp_cc20262/src/services/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeWeatherServiceSuccess extends WeatherService {
  final List<WeatherForecastModel> models;
  FakeWeatherServiceSuccess(this.models);

  @override
  Future<Result<List<WeatherForecastModel>>> getWeatherForecast(
    List<String> listCitySearch,
  ) async {
    return Success(models);
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

class FakeDeviceInfoService extends DeviceInfoService {
  @override
  Future<String> getDeviceCountry({dynamic prefs}) async => 'BR';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ListCityController Offline & Online Flow Tests', () {
    late Database db;
    late DatabaseHelper dbHelper;
    late LocalWeatherRepository repository;

    final mockCity1 = WeatherForecastModel(
      temp: 28,
      date: '30/03',
      time: '12:00',
      conditionCode: '28',
      description: 'Sol com algumas nuvens',
      currently: 'dia',
      city: 'Aracaju',
      imgId: '28',
      humidity: 65,
      cloudiness: 15.0,
      rain: 0.0,
      windSpeedy: '10 km/h',
      windDirection: 180,
      windCardinal: 'S',
      sunrise: '05:30',
      sunset: '17:30',
      moonPhase: 'full',
      conditionSlug: 'cloud',
      cityName: 'Aracaju',
      timezone: '-03:00',
      forecast: [
        ForecastModel(
          date: '30/03',
          weekday: 'Seg',
          max: 29,
          min: 24,
          humidity: 65,
          cloudiness: 15.0,
          rain: 0.0,
          rainProbability: 0,
          windSpeedy: '10 km/h',
          sunrise: '05:30',
          sunset: '17:30',
          moonPhase: 'full',
          description: 'Sol com nuvens',
          condition: 'cloud',
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

    test('loadCities online deve carregar cidades da API, definir isOfflineData=false e persistir no SQLite', () async {
      final controller = ListCityController(
        deviceInfoService: FakeDeviceInfoService(),
        weatherService: FakeWeatherServiceSuccess([mockCity1]),
        localWeatherRepository: repository,
      );

      await controller.loadCities();

      expect(controller.isLoading, isFalse);
      expect(controller.isOfflineData, isFalse);
      expect(controller.allCities.length, equals(1));
      expect(controller.allCities.first.cityName, equals('Aracaju'));

      // Aguarda persitência em background
      await Future.delayed(const Duration(milliseconds: 100));

      final savedCitiesResult = await repository.getAllSavedCities();
      expect(savedCitiesResult.isSuccess, isTrue);
      expect(savedCitiesResult.dataOrNull?.length, equals(1));
    });

    test('loadCities offline deve recuperar cidades do SQLite e definir isOfflineData=true', () async {
      // Pré-carrega uma cidade no banco SQLite
      final cityIdResult = await repository.saveCity('Curitiba', 'PR');
      final cityId = cityIdResult.dataOrNull!;

      await repository.saveForecasts(
        cityId: cityId,
        forecasts: [
          const WeatherForecast(
            cityId: 1,
            data: 'Seg',
            tempMax: 20,
            tempMin: 12,
            condicao: 'Nublado',
            iconUrl: 'cloudy',
          ),
        ],
      );

      final controller = ListCityController(
        deviceInfoService: FakeDeviceInfoService(),
        weatherService: FakeWeatherServiceFailure(),
        localWeatherRepository: repository,
      );

      await controller.loadCities();

      expect(controller.isLoading, isFalse);
      expect(controller.isOfflineData, isTrue);
      expect(controller.errorMessage, isEmpty);
      expect(controller.allCities.length, equals(1));
      expect(controller.allCities.first.cityName, equals('Curitiba'));
    });

    test('loadCities offline com banco SQLite vazio deve exibir mensagem de erro amigável', () async {
      final controller = ListCityController(
        deviceInfoService: FakeDeviceInfoService(),
        weatherService: FakeWeatherServiceFailure(),
        localWeatherRepository: repository,
      );

      await controller.loadCities();

      expect(controller.isLoading, isFalse);
      expect(controller.isOfflineData, isFalse);
      expect(controller.errorMessage, contains('Sem conexão'));
      expect(controller.allCities, isEmpty);
    });

    test('filterCities deve filtrar cidades pelo nome', () async {
      final controller = ListCityController(
        deviceInfoService: FakeDeviceInfoService(),
        weatherService: FakeWeatherServiceSuccess([mockCity1]),
        localWeatherRepository: repository,
      );

      await controller.loadCities();

      controller.filterCities('Ara');
      expect(controller.filteredCities.length, equals(1));

      controller.filterCities('XYZ');
      expect(controller.filteredCities, isEmpty);
    });
  });
}
