import 'package:climapp_cc20262/src/controller/list_city_controller.dart';
import 'package:climapp_cc20262/src/models/weather_forecast_model.dart';
import 'package:climapp_cc20262/src/screens/weather_city_screen.dart';
import 'package:climapp_cc20262/src/screens/welcome_screen.dart';
import 'package:climapp_cc20262/src/services/device_info_service.dart';
import 'package:climapp_cc20262/src/services/notification_service.dart';
import 'package:climapp_cc20262/src/services/weather_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint("Erro ao inicializar Firebase no background: $e");
  }
  debugPrint("Background Handler ID: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint("Erro ao inicializar Firebase App: $e");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final notificationService = NotificationService();
  try {
    await notificationService.initialize();
  } catch (e) {
    debugPrint("Erro ao inicializar NotificationService: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return MultiProvider(
      providers: [
        Provider<WeatherService>(create: (_) => WeatherService()),
        Provider<DeviceInfoService>(create: (_) => DeviceInfoService()),
        ChangeNotifierProvider(
          create: (context) => ListCityController(
            weatherService: context.read<WeatherService>(),
            deviceInfoService: context.read<DeviceInfoService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Climapp',
        debugShowCheckedModeBanner: false,
        navigatorKey: notificationService.navigatorKey,
        scaffoldMessengerKey: notificationService.scaffoldMessengerKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          textTheme: GoogleFonts.montserratTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        onGenerateRoute: (settings) {
          if (settings.name == '/weather') {
            final args = settings.arguments;
            if (args is WeatherForecastModel) {
              return MaterialPageRoute(
                builder: (_) => WeatherCityScreen(weatherForecastModel: args),
              );
            } else if (args is String) {
              final fallbackModel = WeatherForecastModel(
                temp: 26,
                date: 'Hoje',
                time: '12:00',
                conditionCode: '28',
                description: 'Carregando dados...',
                currently: 'dia',
                city: args,
                imgId: '28',
                humidity: 60,
                cloudiness: 20.0,
                rain: 0.0,
                windSpeedy: '10 km/h',
                windDirection: 180,
                windCardinal: 'S',
                sunrise: '06:00',
                sunset: '18:00',
                moonPhase: 'full',
                conditionSlug: 'cloud',
                cityName: args,
                timezone: '-03:00',
                forecast: [],
              );
              return MaterialPageRoute(
                builder: (_) => WeatherCityScreen(weatherForecastModel: fallbackModel),
              );
            }
          }
          return null;
        },
        home: const WelcomeScreen(),
      ),
    );
  }
}
