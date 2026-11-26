/// Modelo de dados referente à previsão do tempo dos próximos dias.
class WeatherForecast {
  final int? id;
  final int cityId;
  final String data;
  final int tempMax;
  final int tempMin;
  final String condicao;
  final String iconUrl;

  const WeatherForecast({
    this.id,
    required this.cityId,
    required this.data,
    required this.tempMax,
    required this.tempMin,
    required this.condicao,
    required this.iconUrl,
  });

  /// Converte o objeto [WeatherForecast] em um Map para inserção no SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'city_id': cityId,
      'data': data,
      'temp_max': tempMax,
      'temp_min': tempMin,
      'condicao': condicao,
      'icon_url': iconUrl,
    };
  }

  /// Cria uma instância de [WeatherForecast] a partir de um Map do SQLite.
  factory WeatherForecast.fromMap(Map<String, dynamic> map) {
    return WeatherForecast(
      id: map['id'] as int?,
      cityId: map['city_id'] as int,
      data: map['data'] as String,
      tempMax: map['temp_max'] as int,
      tempMin: map['temp_min'] as int,
      condicao: map['condicao'] as String,
      iconUrl: map['icon_url'] as String,
    );
  }

  WeatherForecast copyWith({
    int? id,
    int? cityId,
    String? data,
    int? tempMax,
    int? tempMin,
    String? condicao,
    String? iconUrl,
  }) {
    return WeatherForecast(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      data: data ?? this.data,
      tempMax: tempMax ?? this.tempMax,
      tempMin: tempMin ?? this.tempMin,
      condicao: condicao ?? this.condicao,
      iconUrl: iconUrl ?? this.iconUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherForecast &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          cityId == other.cityId &&
          data == other.data &&
          tempMax == other.tempMax &&
          tempMin == other.tempMin &&
          condicao == other.condicao &&
          iconUrl == other.iconUrl;

  @override
  int get hashCode => Object.hash(id, cityId, data, tempMax, tempMin, condicao, iconUrl);

  @override
  String toString() {
    return 'WeatherForecast(id: $id, cityId: $cityId, data: $data, tempMax: $tempMax, tempMin: $tempMin, condicao: $condicao, iconUrl: $iconUrl)';
  }
}
