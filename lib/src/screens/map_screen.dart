import 'dart:math' as math;
import 'package:climapp_cc20262/src/controller/map_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  final LatLng? initialPosition;

  const MapScreen({
    this.initialPosition,
    super.key,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  late final MapScreenController _controller;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _controller = MapScreenController();
    _controller.initCompass(_mapController);

    if (widget.initialPosition != null) {
      _controller.userPosition = widget.initialPosition!;
      _controller.isLoadingLocation = false;
    } else {
      _controller.fetchUserLocation();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05051F),
      appBar: AppBar(
        title: const Text('Mapa Interativo de Clima', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00457D),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoadingLocation) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16,
                children: [
                  CircularProgressIndicator(color: Color(0xFF7693FF)),
                  Text(
                    'Obtendo localização GPS...',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final targetCenter = _controller.userPosition;

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: targetCenter,
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'br.dev.yago.climapp',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: targetCenter,
                        width: 50,
                        height: 50,
                        child: Transform.rotate(
                          angle: _controller.isAutoRotateEnabled
                              ? _controller.currentHeading * (math.pi / 180)
                              : 0.0,
                          child: const Icon(
                            Icons.navigation_rounded,
                            color: Colors.blueAccent,
                            size: 42,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_controller.locationErrorMessage != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Material(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.redAccent.withValues(alpha: 0.9),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        _controller.locationErrorMessage!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 24,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => _controller.toggleAutoRotate(_mapController),
                  backgroundColor: const Color(0xFF7693FF),
                  foregroundColor: Colors.black,
                  icon: Icon(
                    _controller.isAutoRotateEnabled
                        ? Icons.explore
                        : Icons.explore_off,
                  ),
                  label: Text(
                    _controller.isAutoRotateEnabled
                        ? 'Seta Bússola (${_controller.currentHeading.toStringAsFixed(0)}°)'
                        : 'Seta Fixa',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
