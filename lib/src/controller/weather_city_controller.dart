import 'dart:async';
import 'package:climapp_cc20262/src/core/result.dart';
import 'package:climapp_cc20262/src/models/forecast_model.dart';
import 'package:climapp_cc20262/src/models/weather_forecast.dart';
import 'package:climapp_cc20262/src/models/weather_forecast_model.dart';
import 'package:climapp_cc20262/src/repositories/local_weather_repository.dart';
import 'package:climapp_cc20262/src/services/weather_service.dart';
import 'package:flutter/material.dart';

class WeatherCityController extends ChangeNotifier {
  final WeatherService weatherService;
  final LocalWeatherRepository localWeatherRepository;

  WeatherCityController({
    required this.weatherService,
    required this.localWeatherRepository,
  });

  WeatherForecastModel? weatherModel;
  bool isLoading = true;
  bool isOfflineData = false;
  String errorMessage = '';

  /// Carrega a previsão do tempo de uma cidade.
  /// Tenta buscar da API primeiro. Em caso de sucesso, atualiza a UI e salva no SQLite em background.
  /// Se a API falhar (ex: sem internet), tenta carregar do banco local via [localWeatherRepository].
  Future<void> loadWeather({required int cityId, required String cityName}) async {
    isLoading = true;
    errorMessage = '';
    isOfflineData = false;
    notifyListeners();

    // 1. Tentar buscar da API remota primeiro
    final apiResult = await weatherService.getWeatherForecast([cityName]);

    switch (apiResult) {
      case Success(data: final models):
        if (models.isNotEmpty) {
          weatherModel = models.first;
          isOfflineData = false;
          errorMessage = '';
          isLoading = false;
          notifyListeners();

          // Salva no banco de dados local em background (sem travar a UI)
          unawaited(_saveToLocalDatabase(cityId: cityId, model: models.first));
          return;
        } else {
          await _loadFromLocalDatabase(cityId: cityId, cityName: cityName);
        }

      case Failure():
        // 2. Se a API falhou (offline), busca do banco de dados local
        await _loadFromLocalDatabase(cityId: cityId, cityName: cityName);
    }

    isLoading = false;
    notifyListeners();
  }

  /// Salva as previsões retornadas da API no SQLite
  Future<void> _saveToLocalDatabase({
    required int cityId,
    required WeatherForecastModel model,
  }) async {
    final forecastsToSave = model.forecast.map((item) {
      return WeatherForecast(
        cityId: cityId,
        data: item.date,
        tempMax: item.max,
        tempMin: item.min,
        condicao: item.description,
        iconUrl: item.condition,
      );
    }).toList();

    await localWeatherRepository.saveForecasts(
      cityId: cityId,
      forecasts: forecastsToSave,
    );
  }

  /// Tenta restaurar as previsões salvas no SQLite para exibição offline
  Future<void> _loadFromLocalDatabase({
    required int cityId,
    required String cityName,
  }) async {
    final localResult = await localWeatherRepository.getForecastsByCityId(cityId);

    switch (localResult) {
      case Success(data: final forecasts):
        if (forecasts.isNotEmpty) {
          isOfflineData = true;
          errorMessage = '';

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
          weatherModel = WeatherForecastModel(
            temp: ((first.tempMax + first.tempMin) / 2).round(),
            date: first.data,
            time: 'Offline',
            conditionCode: '28',
            description: '${first.condicao} (Offline)',
            currently: 'dia',
            city: cityName,
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
            cityName: cityName,
            timezone: '',
            forecast: forecastModels,
          );
        } else {
          errorMessage = 'Sem conexão com a internet e sem dados salvos offline.';
        }

      case Failure(exception: final exception):
        errorMessage = exception.message;
    }
  }
}
