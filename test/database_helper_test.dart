import 'package:climapp_cc20262/src/database/database_helper.dart';
import 'package:climapp_cc20262/src/models/weather_forecast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WeatherForecast Model & DatabaseHelper Tests', () {
    late Database db;
    late DatabaseHelper dbHelper;

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
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('Mapeamento toMap e fromMap do WeatherForecast', () {
      const forecast = WeatherForecast(
        id: 1,
        cityId: 10,
        data: '2026-03-30',
        tempMax: 30,
        tempMin: 22,
        condicao: 'Ensolarado',
        iconUrl: 'sun',
      );

      final map = forecast.toMap();
      final fromMap = WeatherForecast.fromMap(map);

      expect(fromMap, equals(forecast));
    });

    test('insertForecast e getForecastsByCityId devem funcionar corretamente', () async {
      final cityId = await dbHelper.insertCity('Aracaju', 'SE');

      final forecast1 = WeatherForecast(
        cityId: cityId,
        data: 'Seg',
        tempMax: 29,
        tempMin: 23,
        condicao: 'Sol',
        iconUrl: 'clear_day',
      );

      final forecast2 = WeatherForecast(
        cityId: cityId,
        data: 'Ter',
        tempMax: 31,
        tempMin: 24,
        condicao: 'Chuva',
        iconUrl: 'rain',
      );

      await dbHelper.insertForecast(forecast1);
      await dbHelper.insertForecast(forecast2);

      final forecasts = await dbHelper.getForecastsByCityId(cityId);

      expect(forecasts.length, equals(2));
      expect(forecasts[0].condicao, equals('Sol'));
      expect(forecasts[1].condicao, equals('Chuva'));
    });

    test('deleteOldForecasts deve remover previsões da cidade especificada', () async {
      final cityId = await dbHelper.insertCity('Salvador', 'BA');

      final forecast = WeatherForecast(
        cityId: cityId,
        data: 'Qua',
        tempMax: 28,
        tempMin: 22,
        condicao: 'Nuvens',
        iconUrl: 'cloud',
      );

      await dbHelper.insertForecast(forecast);

      var list = await dbHelper.getForecastsByCityId(cityId);
      expect(list.length, equals(1));

      final deletedRows = await dbHelper.deleteOldForecasts(cityId);
      expect(deletedRows, equals(1));

      list = await dbHelper.getForecastsByCityId(cityId);
      expect(list, isEmpty);
    });
  });
}
