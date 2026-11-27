import 'package:climapp_cc20262/src/controller/weather_city_controller.dart';
import 'package:climapp_cc20262/src/enums/enviroments_enum.dart';
import 'package:climapp_cc20262/src/models/weather_forecast_model.dart';
import 'package:climapp_cc20262/src/repositories/local_weather_repository.dart';
import 'package:climapp_cc20262/src/services/weather_service.dart';
import 'package:climapp_cc20262/src/widgets/custom_weather_svg.dart';
import 'package:climapp_cc20262/src/widgets/offline_error_widget.dart';
import 'package:flutter/material.dart';

class WeatherCityScreen extends StatefulWidget {
  final WeatherForecastModel? weatherForecastModel;
  final int cityId;
  final String cityName;

  const WeatherCityScreen({
    this.weatherForecastModel,
    this.cityId = 1,
    this.cityName = '',
    super.key,
  });

  @override
  State<WeatherCityScreen> createState() => _WeatherCityScreenState();
}

class _WeatherCityScreenState extends State<WeatherCityScreen> {
  final EnviromentEnum envEnum = EnviromentEnum.constants;
  final CarouselController _carouselController = CarouselController();
  late final WeatherCityController controller;

  String get targetCityName =>
      widget.weatherForecastModel?.cityName ??
      (widget.cityName.isNotEmpty ? widget.cityName : 'Cidade');

  @override
  void initState() {
    super.initState();
    controller = WeatherCityController(
      weatherService: WeatherService(),
      localWeatherRepository: LocalWeatherRepository(),
    );

    if (widget.weatherForecastModel != null) {
      controller.weatherModel = widget.weatherForecastModel;
      controller.isLoading = false;
    } else {
      controller.loadWeather(cityId: widget.cityId, cityName: targetCityName);
    }
  }

  @override
  void dispose() {
    _carouselController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF05051F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00457D),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          targetCityName,
          style: const TextStyle(color: Colors.white, fontSize: 24),
        ),
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
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _buildStateContent(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent() {
    if (controller.isLoading) {
      return const Center(
        key: ValueKey('weather_loading'),
        child: CircularProgressIndicator(color: Color(0xFF7693FF)),
      );
    }

    if (controller.errorMessage.isNotEmpty) {
      return OfflineErrorWidget(
        key: const ValueKey('weather_error'),
        errorMessage: controller.errorMessage,
        onRetry: () => controller.loadWeather(
          cityId: widget.cityId,
          cityName: targetCityName,
        ),
      );
    }

    final model = controller.weatherModel;
    if (model == null) {
      return const Center(
        key: ValueKey('weather_empty'),
        child: Text(
          'Nenhum dado de clima disponível.',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return SingleChildScrollView(
      key: const ValueKey('weather_success'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.isOfflineData) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    'Exibindo dados do cache local (Offline)',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF4463D5),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Column(
              children: [
                Text(
                  'Hoje: ${model.date}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                CustomWeatherSvg(
                  imageUrl: '${envEnum.imageUrl}${model.conditionSlug}.svg',
                  height: 80,
                  placeholder: const Icon(Icons.wb_sunny, size: 60, color: Colors.amber),
                ),
                Text(
                  '${model.temp}°',
                  style: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  model.description,
                  style: const TextStyle(fontSize: 20, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(
                      Icons.thermostat,
                      color: Colors.redAccent,
                      size: 33,
                    ),
                    const Text(
                      "Min/Max:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 21,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "${model.forecast.isNotEmpty ? model.forecast[0].min : model.temp}°/${model.forecast.isNotEmpty ? model.forecast[0].max : model.temp}°",
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 21, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (model.forecast.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: CarouselView(
                controller: _carouselController,
                itemExtent: 200,
                shrinkExtent: 200,
                children: List<Widget>.generate(
                  model.forecast.length,
                  (int index) => Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF05051F).withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          model.forecast[index].weekday,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '(${model.forecast[index].date})',
                          style: const TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Image.network(
                            "${envEnum.moonPhaseUrl}${model.forecast[index].moonPhase}.png",
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.nights_stay,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        Text(
                          '${model.forecast[index].min}/${model.forecast[index].max}°',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
