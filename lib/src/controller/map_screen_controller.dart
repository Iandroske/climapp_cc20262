import 'dart:async';
import 'package:climapp_cc20262/src/services/compass_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapScreenController extends ChangeNotifier {
  final CompassService compassService;

  MapScreenController({CompassService? compassService})
      : compassService = compassService ?? CompassService();

  StreamSubscription<double>? _compassSubscription;

  double currentHeading = 0.0;
  bool isAutoRotateEnabled = true;

  bool isLoadingLocation = true;
  LatLng userPosition = const LatLng(-10.9472, -37.0731); // Localização padrão (Aracaju, SE)
  String? locationErrorMessage;

  /// Obtém a localização GPS atual do dispositivo
  Future<void> fetchUserLocation() async {
    isLoadingLocation = true;
    locationErrorMessage = null;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationErrorMessage = 'O serviço de localização GPS está desativado.';
        isLoadingLocation = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationErrorMessage = 'Permissão de localização negada pelo usuário.';
          isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        locationErrorMessage =
            'A permissão de localização foi negada permanentemente nas configurações.';
        isLoadingLocation = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      userPosition = LatLng(position.latitude, position.longitude);
      isLoadingLocation = false;
      locationErrorMessage = null;
      notifyListeners();
    } catch (e) {
      locationErrorMessage = 'Erro ao obter localização: ${e.toString()}';
      isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// Inicializa a escuta do sensor de bússola para rotacionar o marcador do usuário
  void initCompass([MapController? mapController]) {
    _compassSubscription?.cancel();
    _compassSubscription = compassService.headingStream.listen(
      (double heading) {
        currentHeading = heading;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Erro ao ler dados da bússola: $error');
      },
    );
  }

  /// Alterna entre ativar e desativar a rotação automática do marcador do usuário
  void toggleAutoRotate([MapController? mapController]) {
    isAutoRotateEnabled = !isAutoRotateEnabled;
    notifyListeners();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
    super.dispose();
  }
}
