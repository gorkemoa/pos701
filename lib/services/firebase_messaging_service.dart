import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pos701/utils/app_logger.dart';
import 'package:pos701/main.dart';
import 'package:pos701/firebase_options.dart';

/// Arka planda mesaj alındığında çalışacak fonksiyon
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Arka planda çalıştığımız için Firebase'in başlatıldığından emin olalım
  await ensureFirebaseInitialized();
  final logger = AppLogger();
  logger.i('Arka planda mesaj alındı: ${message.messageId}');
}

/// Firebase bildirimlerini yönetecek servis sınıfı
class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AppLogger _logger = AppLogger();
  
  // Bildirim tıklandığında geri çağırım
  final StreamController<RemoteMessage> _onMessageOpenedAppController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessageOpenedApp => _onMessageOpenedAppController.stream;
  
  // Bildirim kanalı ID'si
  static const String _channelId = 'pos701_notification_channel';
  static const String _channelName = 'POS701 Bildirimleri';
  static const String _channelDescription = 'POS701 bildirim kanalı';

  /// Firebase mesajlaşma servisini başlat
  Future<void> initialize() async {
    _logger.i('Firebase Messaging servisi başlatılıyor...');
    
    // Firebase'in başlatıldığından emin ol
    if (!await ensureFirebaseInitialized()) {
      _logger.e('Firebase başlatılamadı, mesajlaşma servisi başlatılamıyor');
      throw Exception('Firebase başlatılamadı');
    }
    
    // Arka plan mesaj işleyicisini ayarla
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // İzinleri iste
    await _requestPermissions();
    
    // Bildirim kanallarını yapılandır
    await _setupNotificationChannels();
    
    // Ön planda mesaj işleyicilerini ayarla
    _setupForegroundHandlers();
    
    // Token alma ve güncelleme dinleyicilerini ayarla
    _setupTokenHandlers();
    
    _logger.i('Firebase Messaging servisi başlatıldı');
  }

  /// Bildirim izinlerini iste
  Future<void> _requestPermissions() async {
    _logger.d('Bildirim izinleri isteniyor...');
    
    if (Platform.isIOS) {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      _logger.d('iOS bildirim izin durumu: ${settings.authorizationStatus}');
    } else if (Platform.isAndroid) {
      // Android için yerel bildirim izinleri
      // flutter_local_notifications 9.0.0 sürümünden sonra istenmiyor
      // veya AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission() metodu kullanılabilir
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        _logger.d('Android bildirim izinleri istendi');
      }
    }
  }

  /// Bildirim kanallarını yapılandır
  Future<void> _setupNotificationChannels() async {
    _logger.d('Yerel bildirim kanalları yapılandırılıyor...');
    
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    // Android için bildirim kanalını oluştur
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      _logger.d('Android bildirim kanalı oluşturuldu');
    }

    // Yerel bildirimleri başlat
    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _logger.d('Yerel bildirim tıklandı: ${response.payload}');
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = json.decode(response.payload!);
            final RemoteMessage message = RemoteMessage(
              data: data,
              notification: RemoteNotification(
                title: data['title'],
                body: data['body'],
              ),
            );
            _onMessageOpenedAppController.add(message);
          } catch (e) {
            _logger.e('Bildirim verisi ayrıştırılamadı: $e');
          }
        }
      },
    );
  }

  /// Ön planda mesaj işleyicilerini ayarla
  void _setupForegroundHandlers() {
    _logger.d('Ön plan mesaj işleyicileri ayarlanıyor...');
    
    // Uygulama ön plandayken mesaj alındığında
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.i('Ön planda mesaj alındı: ${message.messageId}');
      
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Bildirim varsa ve Android ise yerel bildirim göster
      if (notification != null && android != null && Platform.isAndroid) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: json.encode(message.data),
        );
        _logger.d('Yerel bildirim gösterildi');
      }
      
      // iOS için de notification göster
      if (notification != null && Platform.isIOS) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: json.encode(message.data),
        );
      }
    });

    // Uygulama arka plandayken mesaja tıklandığında
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.i('Arka planda bildirime tıklandı: ${message.messageId}');
      _onMessageOpenedAppController.add(message);
    });
    
    // Uygulama kapalıyken mesaja tıklanarak açıldığında
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _logger.i('Uygulama, bildirime tıklanarak açıldı: ${message.messageId}');
        _onMessageOpenedAppController.add(message);
      }
    });
  }

  /// Token alma ve güncelleme dinleyicilerini ayarla
  void _setupTokenHandlers() {
    _logger.d('Token işleyicileri ayarlanıyor...');
    
    // Firebase'in düzgün başlatıldığından emin ol
    ensureFirebaseInitialized().then((bool initialized) {
      if (!initialized) {
        _logger.e('Firebase başlatılmadığı için token işlemleri yapılamıyor');
        return;
      }
      
      // Güvenli token alma işlemi
      _getTokenSafely();
      
      // Token güncellendiğinde dinleyici
      _setupTokenRefreshListener();
    }).catchError((error) {
      _logger.e('Firebase başlatma kontrolü sırasında hata: $error');
    });
  }
  
  /// Güvenli token alma işlemi
  void _getTokenSafely() {
    try {
      _messaging.getToken().then((String? token) {
        if (token != null) {
          _logger.i('FCM Token alındı: $token');
          // Bu token'ı backend'e kaydetme işlemi burada yapılabilir
        } else {
          _logger.w('FCM Token null olarak alındı');
        }
      }).catchError((error) {
        _logger.e('FCM Token alınamadı: $error');
      });
    } catch (e) {
      _logger.e('Token alma sırasında beklenmeyen hata: $e');
    }
  }
  
  /// Token yenileme dinleyicisini ayarla
  void _setupTokenRefreshListener() {
    try {
      _messaging.onTokenRefresh.listen(
        (String token) {
          _logger.i('FCM Token güncellendi: $token');
          // Bu token'ı backend'e güncelleme işlemi burada yapılabilir
        },
        onError: (error) {
          _logger.e('FCM Token güncelleme dinleyicisi hatası: $error');
        },
      );
    } catch (e) {
      _logger.e('Token yenileme dinleyicisi ayarlanırken hata: $e');
    }
  }

  /// Belirli bir konuya abone ol
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    _logger.i('$topic konusuna abone olundu');
  }

  /// Belirli bir konudan abonelikten çık
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    _logger.i('$topic konusundan abonelikten çıkıldı');
  }

  /// Servis kapatıldığında kaynakları temizle
  void dispose() {
    _onMessageOpenedAppController.close();
    _logger.i('Firebase Messaging servisi kapatıldı');
  }
} 