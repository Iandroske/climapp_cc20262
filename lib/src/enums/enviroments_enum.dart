enum EnviromentEnum {
  constants(
    apiBaseUrl: 'https://api.hgbrasil.com/weather',
    apiKey: String.fromEnvironment('API_KEY'),
    imageUrl: 'https://assets.hgbrasil.com/weather/icons/conditions/',
    moonPhaseUrl: 'https://assets.hgbrasil.com/weather/icons/moon/',
  );

  final String apiBaseUrl;
  final String apiKey;
  final String imageUrl;
  final String moonPhaseUrl;

  const EnviromentEnum({
    required this.apiBaseUrl,
    required this.apiKey,
    required this.imageUrl,
    required this.moonPhaseUrl,
  });
}
