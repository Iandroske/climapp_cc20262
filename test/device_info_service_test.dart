import 'package:climapp_cc20262/src/services/device_info_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DeviceInfoService - Validação de Código de País (RegExp)', () {
    late DeviceInfoService service;

    setUp(() {
      service = DeviceInfoService();
    });

    test('Deve validar corretamente códigos de país válidos (2 letras maiúsculas)', () {
      expect(service.isValidCountryCode('BR'), isTrue);
      expect(service.isValidCountryCode('US'), isTrue);
      expect(service.isValidCountryCode('PT'), isTrue);
      expect(service.isValidCountryCode('AR'), isTrue);
      expect(service.isValidCountryCode('es'), isTrue); // Sanitiza para maiúscula
    });

    test('Deve rejeitar códigos de país inválidos', () {
      expect(service.isValidCountryCode('BRA'), isFalse);
      expect(service.isValidCountryCode('12'), isFalse);
      expect(service.isValidCountryCode(''), isFalse);
      expect(service.isValidCountryCode('Deu Ruim'), isFalse);
      expect(service.isValidCountryCode('B1'), isFalse);
      expect(service.isValidCountryCode(null), isFalse);
    });

    test('getFlagEmoji deve retornar emoji correto para códigos válidos e 🌍 para inválidos', () {
      expect(service.getFlagEmoji('BR'), equals('🇧🇷'));
      expect(service.getFlagEmoji('US'), equals('🇺🇸'));
      expect(service.getFlagEmoji('Deu Ruim'), equals('🌍'));
      expect(service.getFlagEmoji(''), equals('🌍'));
    });

    test('getDeviceCountry deve retornar do cache se existir', () async {
      SharedPreferences.setMockInitialValues({
        DeviceInfoService.countryCacheKey: 'PT',
      });
      final prefs = await SharedPreferences.getInstance();

      final country = await service.getDeviceCountry(prefs: prefs);

      expect(country, equals('PT'));
    });
  });
}
