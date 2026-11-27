import 'dart:async';
import 'package:climapp_cc20262/src/controller/map_screen_controller.dart';
import 'package:climapp_cc20262/src/services/compass_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

class MockCompassEvent implements CompassEvent {
  @override
  final double? heading;
  @override
  final double? headingForCameraMode;
  @override
  final double? accuracy;

  MockCompassEvent(this.heading, {this.headingForCameraMode, this.accuracy});
}

class FakeMapController implements MapController {
  double lastRotation = 0.0;

  @override
  bool rotate(double degree, {String? id}) {
    lastRotation = degree;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CompassService & MapScreenController Tests', () {
    test('headingStream deve emitir e sanitizar valores em graus (0 a 360)', () async {
      final controller = StreamController<CompassEvent>();
      final service = CompassService(compassEvents: controller.stream);

      final events = <double>[];
      final subscription = service.headingStream.listen(events.add);

      controller.add(MockCompassEvent(180.0));
      controller.add(MockCompassEvent(-45.0)); // Deve sanitizar para 315.0
      controller.add(MockCompassEvent(400.0)); // Deve sanitizar para 40.0
      await controller.close();

      await subscription.cancel();

      expect(events, equals([180.0, 315.0, 40.0]));
    });

    test('headingStream deve tratar erros de MissingPluginException e PlatformException sem quebrar', () async {
      final controller = StreamController<CompassEvent>();
      final service = CompassService(compassEvents: controller.stream);

      final events = <double>[];
      final subscription = service.headingStream.listen(events.add);

      controller.addError(MissingPluginException('Bússola não disponível'));
      controller.add(MockCompassEvent(90.0));
      await controller.close();

      await subscription.cancel();

      expect(events, equals([90.0]));
    });

    test('MapScreenController deve atualizar heading, alternar auto-rotate e cancelar inscrição no dispose', () async {
      final streamController = StreamController<CompassEvent>();
      final service = CompassService(compassEvents: streamController.stream);
      final mapScreenController = MapScreenController(compassService: service);
      final fakeMapController = FakeMapController();

      expect(mapScreenController.isAutoRotateEnabled, isTrue);

      mapScreenController.initCompass(fakeMapController);

      streamController.add(MockCompassEvent(270.0));
      await Future.delayed(Duration.zero);

      expect(mapScreenController.currentHeading, equals(270.0));

      mapScreenController.toggleAutoRotate(fakeMapController);
      expect(mapScreenController.isAutoRotateEnabled, isFalse);

      mapScreenController.dispose();
      await streamController.close();
    });
  });
}
