import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';

/// Serviço responsável por escutar e disponibilizar os dados do sensor de bússola.
class CompassService {
  final Stream<CompassEvent>? _compassEvents;

  CompassService({Stream<CompassEvent>? compassEvents})
      : _compassEvents = compassEvents ?? FlutterCompass.events;

  /// Retorna um [Stream<double>] com a direção (heading) em graus (0 a 360°).
  /// Trata exceções como [MissingPluginException] e [PlatformException] em dispositivos
  /// sem sensor magnético.
  Stream<double> get headingStream {
    final events = _compassEvents;
    if (events == null) {
      return const Stream<double>.empty();
    }

    return events
        .handleError((error) {
          if (error is PlatformException || error is MissingPluginException) {
            debugPrint('Bússola ou sensor indisponível no dispositivo: $error');
          }
        })
        .where((event) => event.heading != null)
        .map((event) {
          double heading = event.heading!;
          if (heading < 0) heading += 360;
          return heading % 360;
        });
  }
}
