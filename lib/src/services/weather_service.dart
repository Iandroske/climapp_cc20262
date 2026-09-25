import 'dart:convert';

import 'package:climapp_cc20262/src/enums/enviroments_enum.dart';
import 'package:climapp_cc20262/src/models/weather_forecast_model.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  Future<List<WeatherForecastModel>> getWeatherForecast(
      List<String> listCitySearch,
      ) async {
    final enumEnv = EnviromentEnum.constants;
    print('CHAVE USADA NA REQUISIÇÃO: ${enumEnv.API_KEY}');
    final List<WeatherForecastModel> listCity = [];

    for (var city in listCitySearch) {
      final response = await http.get(
        Uri.parse(
          '${enumEnv.API_BASE_URL}?key=${enumEnv.API_KEY}&city_name=$city',
        ),
      );

      // CORREÇÃO 1: Usar && em vez de || ()
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);

        // CORREÇÃO 2: Verificar se a API retornou um erro (ex: chave inválida)
        if (jsonResponse['results'] == null) {
          print('ERRO DA API PARA $city: ${response.body}');
          throw Exception('Cidade não encontrada ou chave de API inválida.');
        }

        final jsonDecoded = jsonResponse['results'];
        final model = WeatherForecastModel.fromJson(jsonDecoded);
        listCity.add(model);
      } else {
        throw Exception('Erro ao carregar dados: ${response.statusCode}');
      }
    }
    return listCity;
  }
}