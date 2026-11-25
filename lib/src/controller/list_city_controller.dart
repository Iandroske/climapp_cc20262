import 'dart:async';
import 'package:climapp_cc20262/src/core/result.dart';
import 'package:climapp_cc20262/src/models/weather_forecast_model.dart';
import 'package:climapp_cc20262/src/services/device_info_service.dart';
import 'package:climapp_cc20262/src/services/weather_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ListCityController extends ChangeNotifier {
  ListCityController({
    required this.deviceInfoService,
    required this.weatherService,
  }) {
    _listenToConnectivity();
  }

  final WeatherService weatherService;
  final DeviceInfoService deviceInfoService;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  String _deviceCountry = '';
  String get deviceCountry => _deviceCountry;

  List<WeatherForecastModel> allCities = [];
  List<WeatherForecastModel> filteredCities = [];
  bool isLoading = true;
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
        errorMessage = 'Sem conexão com a internet. Verifique sua rede.';
        isLoading = false;
        allCities = [];
        filteredCities = [];
        notifyListeners();
      } else {
        loadCities();
      }
    });
  }

  Future<void> loadCities() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    _deviceCountry = await deviceInfoService.getDeviceCountry();

    final result = await weatherService.getWeatherForecast(listCitySearch);

    switch (result) {
      case Success(data: final cities):
        allCities = cities;
        filteredCities = List.from(allCities);
        errorMessage = '';
        debugPrint('====================================');
        debugPrint('Este é o país do celular: $_deviceCountry');
        debugPrint('====================================');

      case Failure(exception: final exception):
        errorMessage = exception.message;
        allCities = [];
        filteredCities = [];
        debugPrint('Erro ao carregar cidades: ${exception.message} (Código: ${exception.code})');
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
            (city) => city.cityName.toLowerCase().contains(query.toLowerCase()),
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
