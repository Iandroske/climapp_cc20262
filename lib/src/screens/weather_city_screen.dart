import 'package:climapp_cc20262/src/enums/enviroments_enum.dart';
import 'package:climapp_cc20262/src/models/weather_forecast_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WeatherCityScreen extends StatefulWidget {
  const WeatherCityScreen({required this.weatherForecastModel, super.key});

  final WeatherForecastModel weatherForecastModel;

  @override
  State<WeatherCityScreen> createState() => _WeatherCityScreenState();
}

class _WeatherCityScreenState extends State<WeatherCityScreen> {
  final EnviromentEnum envEnum = EnviromentEnum.constants;
  final CarouselController _controller = CarouselController();

  @override
  void dispose() {
    _controller.dispose();
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
          widget.weatherForecastModel.cityName,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF4463D5),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Hoje: ${widget.weatherForecastModel.date}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    SvgPicture.network(
                      '${envEnum.imageUrl}${widget.weatherForecastModel.conditionSlug}.svg',
                      height: 80,
                    ),
                    Text(
                      '${widget.weatherForecastModel.temp}°',
                      style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      widget.weatherForecastModel.description,
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
                            "${widget.weatherForecastModel.forecast.isNotEmpty ? widget.weatherForecastModel.forecast[0].min : widget.weatherForecastModel.temp}°/${widget.weatherForecastModel.forecast.isNotEmpty ? widget.weatherForecastModel.forecast[0].max : widget.weatherForecastModel.temp}°",
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
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: CarouselView(
                  controller: _controller,
                  itemExtent: 200,
                  shrinkExtent: 200,
                  children: List<Widget>.generate(
                    widget.weatherForecastModel.forecast.length,
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
                            widget.weatherForecastModel.forecast[index].weekday,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '(${widget.weatherForecastModel.forecast[index].date})',
                            style: const TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Image.network(
                              "${envEnum.moonPhaseUrl}${widget.weatherForecastModel.forecast[index].moonPhase}.png",
                              errorBuilder: (_, _, _) => const Icon(Icons.nights_stay, color: Colors.amber),
                            ),
                          ),
                          Text(
                            '${widget.weatherForecastModel.forecast[index].min}/${widget.weatherForecastModel.forecast[index].max}°',
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
        ),
      ),
    );
  }
}
