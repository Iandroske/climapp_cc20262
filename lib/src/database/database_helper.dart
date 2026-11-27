import 'dart:async';
import 'package:climapp_cc20262/src/core/exceptions/app_exception.dart';
import 'package:climapp_cc20262/src/models/weather_forecast.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _dbName = 'climapp.db';

  /// Versão incrementada para 3 (garante chave UNIQUE em cities)
  static const int _dbVersion = 3;

  /// Retorna a instância do banco de dados, inicializando-a se necessário
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Construtor customizado para injeção de dependências ou testes unitários
  DatabaseHelper.withDatabase(Database db) {
    _database = db;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Habilita chaves estrangeiras no SQLite
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Criação inicial das tabelas com constraint UNIQUE em name
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
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
  }

  /// Migração do banco de dados ao incrementar a versão para 3
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS forecasts (
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
    }

    if (oldVersion < 3) {
      // Deleta cidades duplicadas mantendo apenas o registro de menor ID
      await db.execute(
        'DELETE FROM cities WHERE id NOT IN (SELECT MIN(id) FROM cities GROUP BY name)',
      );
      // Cria o índice único sem conflitos
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_cities_name ON cities(name);',
      );
    }
  }

  /// Insere uma cidade no banco de dados local evitando duplicidades.
  /// Usa [ConflictAlgorithm.ignore] e retorna o ID da cidade (existente ou nova).
  Future<int> insertCity(String name, String? state) async {
    try {
      final db = await database;

      await db.insert(
        'cities',
        {'name': name, 'state': state},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      final List<Map<String, dynamic>> maps = await db.query(
        'cities',
        columns: ['id'],
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return maps.first['id'] as int;
      }

      throw const DatabaseAppException('Erro ao obter o ID da cidade inserida.');
    } on DatabaseException catch (e) {
      throw DatabaseAppException('Erro ao salvar cidade no banco local: ${e.toString()}');
    } catch (e) {
      throw const DatabaseAppException('Erro inesperado ao salvar cidade no banco local.');
    }
  }

  /// Busca todas as cidades salvas sem duplicatas no banco de dados local
  Future<List<Map<String, dynamic>>> getAllCities() async {
    try {
      final db = await database;
      return await db.query(
        'cities',
        groupBy: 'name',
        orderBy: 'name ASC',
      );
    } on DatabaseException catch (e) {
      throw DatabaseAppException('Erro ao consultar cidades no banco local: ${e.toString()}');
    } catch (e) {
      throw const DatabaseAppException('Erro inesperado ao consultar cidades no banco local.');
    }
  }

  /// Insere uma previsão ([WeatherForecast]) no banco de dados local.
  Future<int> insertForecast(WeatherForecast forecast) async {
    try {
      final db = await database;
      final id = await db.insert(
        'forecasts',
        forecast.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } on DatabaseException catch (e) {
      throw DatabaseAppException('Erro ao salvar previsão no banco de dados: ${e.toString()}');
    } catch (e) {
      throw const DatabaseAppException('Erro inesperado ao salvar previsão no banco de dados.');
    }
  }

  /// Busca as previsões associadas a um [cityId].
  Future<List<WeatherForecast>> getForecastsByCityId(int cityId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'forecasts',
        where: 'city_id = ?',
        whereArgs: [cityId],
        orderBy: 'id ASC',
      );

      return maps.map((map) => WeatherForecast.fromMap(map)).toList();
    } on DatabaseException catch (e) {
      throw DatabaseAppException('Erro ao consultar previsões no banco local: ${e.toString()}');
    } catch (e) {
      throw const DatabaseAppException('Erro inesperado ao consultar previsões no banco local.');
    }
  }

  /// Remove previsões antigas/existentes referentes a uma determinada cidade ([cityId]).
  Future<int> deleteOldForecasts(int cityId) async {
    try {
      final db = await database;
      return await db.delete(
        'forecasts',
        where: 'city_id = ?',
        whereArgs: [cityId],
      );
    } on DatabaseException catch (e) {
      throw DatabaseAppException('Erro ao remover previsões antigas: ${e.toString()}');
    } catch (e) {
      throw const DatabaseAppException('Erro inesperado ao remover previsões antigas.');
    }
  }

  /// Encerra a conexão com o banco de dados e reseta a instância
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
