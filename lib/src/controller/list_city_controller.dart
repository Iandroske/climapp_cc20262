import 'dart:async';
import 'package:climapp_cc20262/src/core/result.dart';
import 'package:climapp_cc20262/src/models/weather_forecast.dart';
import 'package:climapp_cc20262/src/models/weather_forecast_model.dart';
import 'package:climapp_cc20262/src/repositories/local_weather_repository.dart';
import 'package:climapp_cc20262/src/services/device_info_service.dart';
import 'package:climapp_cc20262/src/services/weather_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ListCityController extends ChangeNotifier {
  ListCityController({
    required this.deviceInfoService,
    required this.weatherService,
    LocalWeatherRepository? localWeatherRepository,
  }) : localWeatherRepository =
            localWeatherRepository ?? LocalWeatherRepository() {
    _listenToConnectivity();
  }

  final WeatherService weatherService;
  final DeviceInfoService deviceInfoService;
  final LocalWeatherRepository localWeatherRepository;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  String _deviceCountry = '';
  String get deviceCountry => _deviceCountry;

  List<WeatherForecastModel> allCities = [];
  List<WeatherForecastModel> filteredCities = [];
  bool isLoading = true;
  bool isOfflineData = false;
  String errorMessage = '';

  final listCitySearch = [
    'Aracaju,SE',
    'Itabaiana,SE',
    'Salvador,BA',
    'Curitiba,PR',
  ];

  void _listenToConnectivity() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none)) {
        if (allCities.isEmpty) {
          _loadSavedCitiesFromLocalDatabase();
        }
      } else {
        loadCities();
      }
    });
  }

  Future<void> loadCities() async {
    isLoading = true;
    errorMessage = '';
    isOfflineData = false;
    notifyListeners();

    _deviceCountry = await deviceInfoService.getDeviceCountry();

    final result = await weatherService.getWeatherForecast(listCitySearch);

    switch (result) {
      case Success(data: final cities):
        allCities = cities;
        filteredCities = List.from(allCities);
        isOfflineData = false;
        errorMessage = '';
        isLoading = false;
        notifyListeners();

        // Salvar as cidades pesquisadas e previsões no banco SQLite em background
        unawaited(_saveCitiesToLocalDatabase(cities));
        return;

      case Failure():
        // Se a requisição remota falhou (ex: sem internet), tenta carregar do banco local
        await _loadSavedCitiesFromLocalDatabase();
    }

    isLoading = false;
    notifyListeners();
  }

  /// Salva a lista de cidades e previsões obtidas da API no SQLite local
  Future<void> _saveCitiesToLocalDatabase(
    List<WeatherForecastModel> cities,
  ) async {
    for (final cityModel in cities) {
      final cityIdResult = await localWeatherRepository.saveCity(
        cityModel.cityName,
        cityModel.cityName.contains(',')
            ? cityModel.cityName.split(',').last.trim()
            : null,
      );

      if (cityIdResult.isSuccess) {
        final cityId = cityIdResult.dataOrNull!;
        final forecastsToSave = cityModel.forecast.map((item) {
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
    }
  }

  /// Tenta carregar as cidades persistidas do SQLite local quando offline
  Future<void> _loadSavedCitiesFromLocalDatabase() async {
    final localResult = await localWeatherRepository.getAllSavedCities();

    switch (localResult) {
      case Success(data: final savedCities):
        if (savedCities.isNotEmpty) {
          allCities = savedCities;
          filteredCities = List.from(allCities);
          isOfflineData = true;
          errorMessage = '';
        } else {
          errorMessage =
              'Sem conexão com a internet e nenhuma cidade salva em cache local.';
          allCities = [];
          filteredCities = [];
        }

      case Failure(exception: final exception):
        errorMessage = exception.message;
        allCities = [];
        filteredCities = [];
    }

    isLoading = false;
    notifyListeners();
  }

  void filterCities(String query) {
    if (query.isEmpty) {
      filteredCities = List.from(allCities);
    } else {
      filteredCities = allCities
          .where(
            (city) =>
                city.cityName.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    super.dispose();
  }
}
