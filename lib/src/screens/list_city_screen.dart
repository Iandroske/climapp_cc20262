import 'package:climapp_cc20262/src/controller/list_city_controller.dart';
import 'package:climapp_cc20262/src/screens/map_screen.dart';
import 'package:climapp_cc20262/src/screens/weather_city_screen.dart';
import 'package:climapp_cc20262/src/services/device_info_service.dart';
import 'package:climapp_cc20262/src/services/weather_service.dart';
import 'package:climapp_cc20262/src/widgets/city_tile_widget.dart';
import 'package:climapp_cc20262/src/widgets/offline_error_widget.dart';
import 'package:flutter/material.dart';

class ListCityScreen extends StatefulWidget {
  const ListCityScreen({super.key});

  @override
  State<ListCityScreen> createState() => _ListCityScreenState();
}

class _ListCityScreenState extends State<ListCityScreen> {
  final TextEditingController textController = TextEditingController();
  late final ListCityController controller;

  @override
  void initState() {
    super.initState();
    controller = ListCityController(
      deviceInfoService: DeviceInfoService(),
      weatherService: WeatherService(),
    );
    controller.loadCities();
  }

  @override
  void dispose() {
    textController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapScreen()),
          );
        },
        backgroundColor: const Color(0xFF7693FF),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.map_rounded),
        label: const Text('Ver Mapa', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFF00457D), Color(0xFF05051F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 15,
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 25),
              TextField(
                style: const TextStyle(color: Colors.white),
                controller: textController,
                onChanged: controller.filterCities,
                decoration: const InputDecoration(
                  fillColor: Color(0x15FFFFFF),
                  filled: true,
                  hintText: 'Digite uma cidade',
                  hintStyle: TextStyle(color: Colors.white),
                  suffixIcon: Icon(Icons.search, color: Colors.white),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: _buildStateContent(controller),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent(ListCityController controller) {
    if (controller.isLoading) {
      return const Center(
        key: ValueKey('loading_state'),
        child: CircularProgressIndicator(color: Color(0xFF7693FF)),
      );
    }

    if (controller.errorMessage.isNotEmpty) {
      return OfflineErrorWidget(
        key: const ValueKey('error_state'),
        errorMessage: controller.errorMessage,
        onRetry: controller.loadCities,
      );
    }

    if (controller.filteredCities.isEmpty) {
      return const Center(
        key: ValueKey('empty_state'),
        child: Text(
          'Nenhuma cidade encontrada.',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return Column(
      key: const ValueKey('success_state'),
      children: [
        if (controller.isOfflineData) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amberAccent),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                Icon(Icons.cloud_off_rounded, color: Colors.amberAccent, size: 20),
                Text(
                  'Exibindo cidades do cache local (Offline)',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: ListView.builder(
            itemCount: controller.filteredCities.length,
            itemBuilder: (context, index) {
              final city = controller.filteredCities[index];
              return CityTileWidget(
                cityName: city.cityName,
                icon: city.conditionSlug,
                temperature: city.temp,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WeatherCityScreen(
                        weatherForecastModel: city,
                        cityName: city.cityName,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
