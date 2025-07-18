import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pos701/utils/app_logger.dart';

/// Yerel bildirimleri yönetmek için servis
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final AppLogger _logger = AppLogger();
  
  /// Kanal ID'leri
  static const String _channelId = 'pos701_notification_channel';
  static const String _channelIdHigh = 'pos701_notification_channel_high';
  
  /// Bildirim tipleri
  static const String typeInfo = 'info';
  static const String typeSuccess = 'success';
  static const String typeWarning = 'warning';
  static const String typeError = 'error';
  static const String typeOrder = 'order';
  static const String typeOrderReady = 'order_ready';
  
  // Singleton pattern
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  
  factory LocalNotificationService() => _instance;
  
  LocalNotificationService._internal();
  
  /// Servisi başlat
  Future<void> initialize() async {
    _logger.d('Yerel bildirim servisi başlatılıyor...');
    
    // Android için başlatma ayarları
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS için başlatma ayarları
    const DarwinInitializationSettings iOSSettings = 
        DarwinInitializationSettings();
    
    // Genel ayarlar
    const InitializationSettings initializationSettings = 
        InitializationSettings(
          android: androidSettings,
          iOS: iOSSettings,
        );
    
    // Servisi başlat
    await _notificationsPlugin.initialize(initializationSettings);
    
    // Android bildirim kanallarını oluştur
    await _createNotificationChannels();
    
    _logger.i('Yerel bildirim servisi başlatıldı');
  }
  
  /// Android bildirim kanallarını oluştur
  Future<void> _createNotificationChannels() async {
    _logger.d('Bildirim kanalları oluşturuluyor...');
    
    // Normal öncelikli bildirimler için kanal
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      'POS701 Bildirimleri',
      description: 'POS701 uygulaması bildirimleri',
      importance: Importance.defaultImportance,
    );
    
    // Yüksek öncelikli bildirimler için kanal (siparişler, kritik uyarılar vb.)
    const AndroidNotificationChannel channelHigh = AndroidNotificationChannel(
      _channelIdHigh,
      'POS701 Önemli Bildirimleri',
      description: 'Sipariş ve önemli uyarılar için bildirimler',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );
    
    // Kanalları kaydet
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channelHigh);
    
    _logger.i('Bildirim kanalları oluşturuldu');
  }
  
  /// Bildirim göster
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String type = typeInfo,
    int id = 0,
  }) async {
    _logger.d('Yerel bildirim gösteriliyor: $title');
    
    try {
      // Bildirim tipine göre kanal ve simge seç
      String channelId = _channelId;
      
      // Önem derecesini belirle
      if (type == typeOrder || type == typeOrderReady || type == typeError) {
        channelId = _channelIdHigh;
      }
      
      // Payload hazırla
      final String payload = data != null ? json.encode(data) : '{}';
      
      // Android ayarları
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == _channelId ? 'POS701 Bildirimleri' : 'POS701 Önemli Bildirimleri',
        channelDescription: 'POS701 uygulaması bildirimleri',
        importance: channelId == _channelId ? Importance.defaultImportance : Importance.high,
        priority: channelId == _channelId ? Priority.defaultPriority : Priority.high,
        enableVibration: true,
      );
      
      // Genel bildirimleri detayları (sadece Android)
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      // Bildirimi göster
      await _notificationsPlugin.show(
        id, // Bildirim ID'si
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
      _logger.i('Yerel bildirim başarıyla gösterildi');
    } catch (e) {
      _logger.e('Yerel bildirim gösterilemedi: $e');
    }
  }
  
  /// Tüm bildirimleri temizle
  Future<void> cancelAllNotifications() async {
    _logger.d('Tüm bildirimler temizleniyor...');
    await _notificationsPlugin.cancelAll();
    _logger.i('Tüm bildirimler temizlendi');
  }
  
  /// Belirli bir bildirimi temizle
  Future<void> cancelNotification(int id) async {
    _logger.d('$id ID\'li bildirim temizleniyor...');
    await _notificationsPlugin.cancel(id);
    _logger.i('$id ID\'li bildirim temizlendi');
  }
} 