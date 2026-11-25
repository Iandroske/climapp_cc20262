import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceInfoService {
  static const MethodChannel _channel = MethodChannel(
    'br.dev.yago.climapp/device',
  );

  /// Chave de cache local no SharedPreferences
  static const String countryCacheKey = 'cached_device_country';

  /// Expressão regular para validação do código do país (duas letras maiúsculas ISO 3166-1 alpha-2)
  static final RegExp countryCodeRegExp = RegExp(r'^[A-Z]{2}$');

  /// Valida se uma string é um código de país válido
  bool isValidCountryCode(String? code) {
    if (code == null || code.trim().isEmpty) return false;
    return countryCodeRegExp.hasMatch(code.trim().toUpperCase());
  }

  /// Retorna o código do país do dispositivo.
  /// Prioriza o cache local (SharedPreferences). Caso não exista cache válido,
  /// consulta o MethodChannel nativo e armazena o resultado em cache.
  Future<String> getDeviceCountry({SharedPreferences? prefs}) async {
    try {
      final preferences = prefs ?? await SharedPreferences.getInstance();

      // 1. Verificar se existe no cache local
      final String? cachedCountry = preferences.getString(countryCacheKey);
      if (cachedCountry != null && isValidCountryCode(cachedCountry)) {
        return cachedCountry;
      }

      // 2. Se não estiver em cache, chama o MethodChannel nativo
      String countryCode;
      try {
        final String? nativeCountry = await _channel.invokeMethod<String>(
          'getDeviceCountry',
        );
        countryCode = nativeCountry ?? getCountryCode();
      } on PlatformException {
        countryCode = getCountryCode();
      }

      // Final sanitization
      countryCode = countryCode.trim().toUpperCase();

      if (!isValidCountryCode(countryCode)) {
        countryCode = getCountryCode();
      }

      // 3. Salvar no cache local para chamadas futuras
      await preferences.setString(countryCacheKey, countryCode);
      return countryCode;
    } catch (_) {
      return getCountryCode();
    }
  }

  /// Extrai a sigla do país a partir da locale do sistema (ex: pt_BR -> BR)
  String getCountryCode() {
    try {
      final String locale = Platform.localeName;
      if (locale.contains('_')) {
        final String code = locale.split('_').last.toUpperCase();
        if (isValidCountryCode(code)) return code;
      } else if (locale.contains('-')) {
        final String code = locale.split('-').last.toUpperCase();
        if (isValidCountryCode(code)) return code;
      }
      return 'BR';
    } catch (e) {
      return 'BR';
    }
  }

  /// Converte a sigla de 2 letras do país para o emoji da bandeira correspondente
  String getFlagEmoji(String countryCode) {
    final cleanCode = countryCode.trim().toUpperCase();
    if (!isValidCountryCode(cleanCode)) return '🌍';

    final int firstLetter = cleanCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = cleanCode.codeUnitAt(1) - 0x41 + 0x1F1E6;

    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }
}
