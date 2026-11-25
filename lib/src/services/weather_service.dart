import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:climapp_cc20262/src/core/exceptions/app_exception.dart';
import 'package:climapp_cc20262/src/core/result.dart';
import 'package:climapp_cc20262/src/enums/enviroments_enum.dart';
import 'package:climapp_cc20262/src/models/weather_forecast_model.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  final http.Client _httpClient;

  WeatherService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Future<Result<List<WeatherForecastModel>>> getWeatherForecast(
    List<String> listCitySearch,
  ) async {
    final enumEnv = EnviromentEnum.constants;
    final List<WeatherForecastModel> listCity = [];

    try {
      for (final city in listCitySearch) {
        final url = '${enumEnv.apiBaseUrl}?key=${enumEnv.apiKey}&city_name=$city';

        final response = await _httpClient.get(Uri.parse(url)).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw const TimeoutNetworkException();
          },
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final jsonResponse = jsonDecode(response.body);

          if (jsonResponse['results'] == null) {
            return const Failure(
              NotFoundException('Cidade não encontrada ou chave de API inválida.'),
            );
          }

          final jsonDecoded = jsonResponse['results'];
          final model = WeatherForecastModel.fromJson(jsonDecoded);
          listCity.add(model);
        } else if (response.statusCode == 404) {
          return const Failure(NotFoundException());
        } else {
          return Failure(
            ApiException(
              'Erro ao carregar dados do servidor (Código ${response.statusCode}).',
              statusCode: response.statusCode,
            ),
          );
        }
      }

      return Success(listCity);
    } on TimeoutNetworkException catch (e) {
      return Failure(e);
    } on SocketException {
      return const Failure(NetworkException());
    } on http.ClientException {
      return const Failure(NetworkException());
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(UnknownException('Erro ao processar dados de clima: $e'));
    }
  }
}
