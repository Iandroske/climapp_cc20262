import 'package:climapp_cc20262/src/core/exceptions/app_exception.dart';
import 'package:climapp_cc20262/src/database/database_helper.dart';
import 'package:climapp_cc20262/src/models/weather_forecast.dart';
import 'package:climapp_cc20262/src/repositories/local_weather_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LocalWeatherRepository Tests', () {
    late Database db;
    late DatabaseHelper dbHelper;
    late LocalWeatherRepository repository;

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

    test('saveCity e saveForecasts devem retornar Success com os dados persistidos', () async {
      final cityResult = await repository.saveCity('Curitiba', 'PR');
      expect(cityResult.isSuccess, isTrue);
      final cityId = cityResult.dataOrNull!;

      final forecasts = [
        WeatherForecast(
          cityId: cityId,
          data: '2026-03-30',
          tempMax: 22,
          tempMin: 14,
          condicao: 'Nublado',
          iconUrl: 'cloudy',
        ),
      ];

      final saveResult = await repository.saveForecasts(
        cityId: cityId,
        forecasts: forecasts,
      );

      expect(saveResult.isSuccess, isTrue);
      expect(saveResult.dataOrNull?.length, equals(1));
    });

    test('getForecastsByCityId deve retornar Success contendo a lista de previsões', () async {
      final cityResult = await repository.saveCity('Itabaiana', 'SE');
      final cityId = cityResult.dataOrNull!;

      final forecasts = [
        WeatherForecast(
          cityId: cityId,
          data: 'Segunda',
          tempMax: 32,
          tempMin: 24,
          condicao: 'Ensolarado',
          iconUrl: 'clear_day',
        ),
      ];

      await repository.saveForecasts(cityId: cityId, forecasts: forecasts);

      final getResult = await repository.getForecastsByCityId(cityId);

      expect(getResult.isSuccess, isTrue);
      final list = getResult.dataOrNull!;
      expect(list.length, equals(1));
      expect(list.first.condicao, equals('Ensolarado'));
    });

    test('deleteOldForecasts deve remover registros e retornar Success(quantidade)', () async {
      final cityResult = await repository.saveCity('Aracaju', 'SE');
      final cityId = cityResult.dataOrNull!;

      final forecasts = [
        WeatherForecast(
          cityId: cityId,
          data: 'Terça',
          tempMax: 30,
          tempMin: 25,
          condicao: 'Chuva',
          iconUrl: 'rain',
        ),
      ];

      await repository.saveForecasts(cityId: cityId, forecasts: forecasts);

      final deleteResult = await repository.deleteOldForecasts(cityId);

      expect(deleteResult.isSuccess, isTrue);
      expect(deleteResult.dataOrNull, equals(1));

      final emptyResult = await repository.getForecastsByCityId(cityId);
      expect(emptyResult.dataOrNull, isEmpty);
    });

    test('Erro no banco de dados deve ser capturado e retornado como Failure(DatabaseAppException)', () async {
      await db.close();

      final result = await repository.getForecastsByCityId(999);

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<DatabaseAppException>());
    });
  });
}
