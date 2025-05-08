import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pos701/utils/app_logger.dart';
import 'package:pos701/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:pos701/constants/app_constants.dart';

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
    
    // Topic aboneliği debug kodu
    await debugTopics();
    
    // Topic abonelik durumunu kontrol et
    await checkTopicSubscription();
    
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
          // Token'ı backend'e kaydet
          _sendTokenToBackend(token);
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
          // Token'ı backend'e kaydet
          _sendTokenToBackend(token);
        },
        onError: (error) {
          _logger.e('Token yenileme dinleme hatası: $error');
        },
      );
    } catch (e) {
      _logger.e('Token yenileme dinleyicisi ayarlanamadı: $e');
    }
  }

  /// FCM token'ını backend'e gönder
  Future<void> _sendTokenToBackend(String token) async {
    _logger.d('FCM token backend\'e gönderiliyor...');
    try {
      // API servisi üzerinden token gönderme
      // NOT: Burada gerçek API çağrısı eklenecek
      final bool success = await _sendTokenToApi(token);
      
      if (success) {
        _logger.i('FCM token başarıyla backend\'e gönderildi');
      } else {
        _logger.w('FCM token backend\'e gönderilemedi');
      }
    } catch (e) {
      _logger.e('FCM token backend\'e gönderilirken hata: $e');
    }
  }
  
  /// FCM token'ını API'ye gönder
  Future<bool> _sendTokenToApi(String token) async {
    try {
      // Kullanıcı giriş yapmışsa API'ye token'ı gönder
      // Bu kısım gerçek API entegrasyonuna göre düzenlenmelidir
      
      // Örnek API çağrısı (gerçekte SharedPreferences'tan alınabilir)
      final String? userId = await _getUserId();
      
      if (userId == null || userId.isEmpty) {
        _logger.w('Kullanıcı ID\'si bulunamadığı için token gönderilemedi');
        return false;
      }
      
      // API istekleri için ApiService sınıfı kullanılabilir
      // final ApiService apiService = ApiService();
      // final response = await apiService.sendFcmToken(userId, token);
      // return response.success;
      
      // Şimdilik başarılı kabul ediyoruz
      return true;
    } catch (e) {
      _logger.e('Token API\'ye gönderilirken hata: $e');
      return false;
    }
  }
  
  /// Kullanıcı ID'sini al (Bu metot projeye özgü olarak uyarlanmalıdır)
  Future<String?> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // AppConstants.userIdKey kullanarak önce int olarak kayıtlı userId'yi kontrol et
      final int? userIdInt = prefs.getInt(AppConstants.userIdKey);
      if (userIdInt != null) {
        _logger.d('Kullanıcı ID (int): $userIdInt');
        return userIdInt.toString();
      }
      
      // AppConstants.userIdKey kullanarak string olarak kayıtlı userId'yi kontrol et
      final String? userIdStr = prefs.getString(AppConstants.userIdKey);
      if (userIdStr != null && userIdStr.isNotEmpty) {
        _logger.d('Kullanıcı ID (string): $userIdStr');
        return userIdStr;
      }
      
      _logger.w('SharedPreferences\'ta kullanıcı ID\'si bulunamadı');
      return null;
    } catch (e) {
      _logger.e('Kullanıcı ID\'si alınırken hata: $e');
      return null;
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

  /// Kullanıcının kendi ID'sine göre topic'e abone olmasını sağlar
  Future<void> subscribeToUserTopic(String userId) async {
    if (userId.isEmpty) {
      _logger.e('Kullanıcı ID boş, topic aboneliği yapılamadı');
      return;
    }

    try {
      _logger.d('$userId ID\'li kullanıcı için topic aboneliği başlatılıyor');
      await _messaging.subscribeToTopic(userId);
      _logger.i('$userId ID\'li kullanıcı için topic aboneliği başarıyla tamamlandı');
    } catch (e) {
      _logger.e('Topic aboneliği sırasında hata: $e');
      rethrow;
    }
  }

  /// Kullanıcının topic aboneliğini kaldırır
  Future<void> unsubscribeFromUserTopic(String userId) async {
    if (userId.isEmpty) {
      _logger.e('Kullanıcı ID boş, topic aboneliği kaldırılamadı');
      return;
    }

    try {
      _logger.d('$userId ID\'li kullanıcı için topic aboneliği kaldırılıyor');
      await _messaging.unsubscribeFromTopic(userId);
      _logger.i('$userId ID\'li kullanıcı için topic aboneliği başarıyla kaldırıldı');
    } catch (e) {
      _logger.e('Topic aboneliğini kaldırma sırasında hata: $e');
      rethrow;
    }
  }

  /// Servis kapatıldığında kaynakları temizle
  void dispose() {
    _onMessageOpenedAppController.close();
    _logger.i('Firebase Messaging servisi kapatıldı');
  }

  // Mevcut topic aboneliklerini kontrol etmek için kod ekleyin
  Future<void> checkTopicSubscription() async {
    try {
      final userId = await _getUserId(); 
      if (userId == null || userId.isEmpty) {
        _logger.w('Topic aboneliği kontrol edilemiyor: Kullanıcı ID bulunamadı');
        return;
      }
      
      _logger.i('Topic "$userId" için abonelik kontrol ediliyor...');
      
      // FCM token bilgisini loglayın
      final token = await FirebaseMessaging.instance.getToken();
      _logger.i('Mevcut FCM Token: $token');
      
      // iOS cihazlar için APNs token bilgisini de loglayalım
      if (Platform.isIOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        _logger.i('APNs Token: $apnsToken');
      }
    } catch (e) {
      _logger.e('Topic aboneliği kontrol edilirken hata: $e');
    }
  }

  /// Kullanıcı ID'sine göre bildirim göndermek için örnek bir Postman JSON formatı yazdırır
  void printSamplePostmanJson(String? userId) {
    if (userId == null || userId.isEmpty) {
      _logger.w('Örnek Postman JSON formatı yazdırılamadı: Kullanıcı ID bulunamadı');
      return;
    }

    final sampleJson = '''
{
  "message": {
    "topic": "$userId",
    "notification": {
      "title": "Sipariş Hazır!",
      "body": "Siparişiniz hazırlanmıştır."
    },
    "data": {
      "type": "order_ready",
      "id": "$userId",
      "order_id": "12345"
    },
    "android": {
      "priority": "high"
    },
    "apns": {
      "headers": {
        "apns-priority": "10"
      },
      "payload": {
        "aps": {
          "sound": "default"
        }
      }
    }
  }
}''';

    _logger.i('$userId için örnek Postman JSON formatı:\n$sampleJson');
  }

  // Topic aboneliği debug kodu
  Future<void> debugTopics() async {
    try {
      // Mevcut token'ı log'la
      final token = await _messaging.getToken();
      _logger.i('Mevcut FCM Token: $token');
      
      // Kullanıcı ID'sini SharedPreferences'tan al
      final String? userId = await _getUserId();
      
      if (userId != null && userId.isNotEmpty) {
        // Kullanıcının kendi ID'sine göre topic'e abone ol
        await _messaging.subscribeToTopic(userId);
        _logger.i('Topic "$userId" aboneliği yapıldı');
        
        // APNs token bilgisini log'la (iOS için)
        if (Platform.isIOS) {
          final apnsToken = await _messaging.getAPNSToken();
          _logger.i('APNs Token: $apnsToken');
        }
        
        // Örnek Postman JSON formatını yazdır
        printSamplePostmanJson(userId);
      } else {
        _logger.w('Kullanıcı ID\'si bulunamadı, otomatik topic aboneliği yapılamadı');
      }
    } catch (e) {
      _logger.e('Topic debug hatası: $e');
    }
  }
} 