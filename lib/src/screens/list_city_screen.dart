import 'package:climapp_cc20262/src/controller/list_city_controller.dart';
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

    return ListView.builder(
      key: const ValueKey('success_state'),
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
                ),
              ),
            );
          },
        );
      },
    );
  }
}
