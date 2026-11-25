import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // Instância singleton para acesso global
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Chaves globais para permitir navegação e exibição de banners sem BuildContext
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Timer? _bannerTimer;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;

  Future<void> initialize() async {
    // 1. Solicitar permissões (Obrigatório para iOS e Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Permissão concedida pelo usuário.');

      // 2. Obter o FCM Token na inicialização
      String? token = await _fcm.getToken();
      debugPrint('====================================');
      debugPrint('FCM TOKEN DO DISPOSITIVO: $token');
      debugPrint('====================================');

      // Escuta caso o token seja renovado pelo Firebase (salvando assinatura para evitar leak)
      _tokenSubscription?.cancel();
      _tokenSubscription = _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token atualizado: $newToken');
      });

      // 3. Configurar os listeners de eventos
      _setupMessageHandlers();
    } else {
      debugPrint('Permissão negada ou não configurada.');
    }
  }

  void _setupMessageHandlers() {
    // Cenário 1: Foreground (App aberto na tela) -> Exibe MaterialBanner interativo
    _onMessageSubscription?.cancel();
    _onMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Mensagem recebida em Foreground: ${message.notification?.title}');

      final notification = message.notification;
      if (notification != null) {
        showForegroundBanner(
          title: notification.title ?? 'Notificação de Clima',
          body: notification.body ?? '',
          data: message.data,
        );
      }
    });

    // Cenário 2: Background (App minimizado e usuário clica na notificação)
    _onMessageOpenedAppSubscription?.cancel();
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Toque na notificação (Background): ${message.data}');
      _handleDeepLink(message.data);
    });

    // Cenário 3: Terminated (App fechado e aberto pelo clique na notificação)
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App inicializado a partir de notificação: ${message.data}');
        _handleDeepLink(message.data);
      }
    });
  }

  /// Exibe um MaterialBanner interativo na tela quando uma notificação chega em Foreground.
  /// Se o usuário clicar no banner, navega para a tela de detalhes.
  /// O timer de auto-dismiss é cancelado antes de criar um novo ou quando destruído.
  void showForegroundBanner({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    final messengerState = scaffoldMessengerKey.currentState;

    // Cancela qualquer timer ativo de banner anterior para evitar memory leak
    clearBannerTimer();

    final banner = MaterialBanner(
      elevation: 4,
      backgroundColor: const Color(0xFF00457D),
      leading: const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 36),
      content: InkWell(
        onTap: () => _onBannerTapped(data),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _onBannerTapped(data),
          child: const Text(
            'VER',
            style: TextStyle(
              color: Color(0xFF7693FF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: dismissBanner,
        ),
      ],
    );

    messengerState?.hideCurrentMaterialBanner();
    messengerState?.showMaterialBanner(banner);

    // Configura o timer para esconder o banner após 5 segundos
    _bannerTimer = Timer(const Duration(seconds: 5), () {
      dismissBanner();
    });
  }

  void _onBannerTapped(Map<String, dynamic>? data) {
    dismissBanner();
    _handleDeepLink(data);
  }

  /// Esconde o MaterialBanner atual e cancela o timer associado
  void dismissBanner() {
    clearBannerTimer();
    scaffoldMessengerKey.currentState?.hideCurrentMaterialBanner();
  }

  /// Cancela e limpa explicitamente o Timer do banner
  void clearBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = null;
  }

  /// Manipula a navegação para a tela de detalhes da cidade utilizando o navigatorKey global
  void _handleDeepLink(Map<String, dynamic>? data) {
    if (data == null) return;

    final navState = navigatorKey.currentState;
    if (navState == null) return;

    final city = data['city'] ?? data['cityName'];
    if (city != null) {
      navState.pushNamed('/weather', arguments: city);
    }
  }

  /// Libera recursos e cancela todos os Timers e Subscriptions
  void dispose() {
    clearBannerTimer();
    _tokenSubscription?.cancel();
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _tokenSubscription = null;
    _onMessageSubscription = null;
    _onMessageOpenedAppSubscription = null;
  }
}
