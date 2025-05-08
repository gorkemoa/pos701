import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pos701/viewmodels/notification_viewmodel.dart';
import 'package:pos701/utils/app_logger.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({Key? key}) : super(key: key);

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final AppLogger _logger = AppLogger();
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _logger.d('Bildirimler sayfası açıldı');
    _initializeLocalNotifications();
  }

  /// Yerel bildirimleri başlat
  Future<void> _initializeLocalNotifications() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // Android ayarları
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS ayarları
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // Başlatma ayarları
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    // Bildirimleri başlat
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _logger.d('Bildirime tıklandı: ${response.payload}');
      }
    );
    
    _logger.d('Yerel bildirimler başlatıldı');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              _showConfirmationDialog(context);
            },
            tooltip: 'Tüm bildirimleri temizle',
          ),
          IconButton(
            icon: const Icon(Icons.add_alert),
            onPressed: () {
              // Test bildirimi gönder
              _sendTestNotification();
            },
            tooltip: 'Test bildirimi gönder',
          ),
        ],
      ),
      body: Column(
        children: [
          // FCM Token Card
          _buildFcmTokenCard(context),
          // Bildirimler Listesi
          Expanded(
            child: Consumer<NotificationViewModel>(
              builder: (context, notificationViewModel, child) {
                switch (notificationViewModel.state) {
                  case NotificationState.initial:
                  case NotificationState.loading:
                    return const Center(child: CircularProgressIndicator());
                    
                  case NotificationState.error:
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Hata: ${notificationViewModel.errorMessage}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                    
                  case NotificationState.success:
                    final notifications = notificationViewModel.notifications;
                    
                    if (notifications.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Henüz bildirim bulunmuyor',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
                        final formattedDate = dateFormat.format(notification.receivedAt);
                        
                        // Bildirimin tipine göre ikon seçimi
                        IconData notificationIcon = Icons.notifications;
                        Color iconColor = Colors.blue;
                        
                        final type = notification.data['type'] ?? '';
                        if (type == 'order_ready') {
                          notificationIcon = Icons.restaurant;
                          iconColor = Colors.orange;
                        } else if (type == 'food_ready') {
                          notificationIcon = Icons.fastfood;
                          iconColor = Colors.green;
                        }
                        
                        return Dismissible(
                          key: Key('${notification.data['id']}_${notification.receivedAt.millisecondsSinceEpoch}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) {
                            // Bildirimi sil
                            Provider.of<NotificationViewModel>(context, listen: false)
                                .removeNotification(index);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bildirim silindi')),
                            );
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: iconColor,
                              child: Icon(notificationIcon, color: Colors.white),
                            ),
                            title: Text(
                              notification.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notification.body),
                                const SizedBox(height: 4),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              _showNotificationDetails(context, notification);
                            },
                          ),
                        );
                      },
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// FCM Token kartını oluştur
  Widget _buildFcmTokenCard(BuildContext context) {
    return Consumer<NotificationViewModel>(
      builder: (context, viewModel, _) {
        final token = viewModel.fcmToken ?? 'Token yükleniyor...';
        
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.vpn_key, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'FCM Token',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Yenile',
                      onPressed: () async {
                        await viewModel.fetchFcmToken();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('FCM token yenilendi')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Kopyala',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: token));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('FCM token kopyalandı')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const Divider(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    token,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bu token cihazınıza özel tanımlayıcıdır. Bildirim göndermek için kullanılır.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bildirim detaylarını gösteren dialog
  void _showNotificationDetails(BuildContext context, NotificationData notification) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm:ss');
    final formattedDate = dateFormat.format(notification.receivedAt);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification.body),
              const SizedBox(height: 16),
              const Text(
                'Alınma Zamanı:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(formattedDate),
              const SizedBox(height: 16),
              const Text(
                'Bildirim Verileri:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  notification.data.toString(),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
          TextButton(
            onPressed: () {
              // Yerel bir bildirim olarak göster
              _showLocalNotification(notification);
              Navigator.of(context).pop();
            },
            child: const Text('Yeniden Göster'),
          ),
        ],
      ),
    );
  }
  
  /// Yerel bildirim göster
  Future<void> _showLocalNotification(NotificationData notification) async {
    try {
      // Bildirim tipine göre ikon ve kanal ID seçimi
      String channelId = 'high_importance_channel';
      String channelName = 'Yüksek Öncelikli Bildirimler';
      String channelDescription = 'Bu kanal yüksek öncelikli bildirimleri gösterir';
      
      final type = notification.data['type'] ?? '';
      if (type == 'order_ready' || type.contains('order')) {
        channelId = 'order_channel';
        channelName = 'Sipariş Bildirimleri';
        channelDescription = 'Sipariş bildirimleri kanalı';
      }
      
      // Android için bildirim detayları
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );
      
      // iOS için bildirim detayları
      const DarwinNotificationDetails iOSPlatformChannelSpecifics = 
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      // Bildirim detayları
      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      
      // Bildirim ID'si - bildirimin benzersiz olması için
      final int notificationId = notification.receivedAt.millisecondsSinceEpoch.remainder(100000);
      
      // Bildirim göster
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        notification.title,
        notification.body,
        platformChannelSpecifics,
        payload: json.encode(notification.data),
      );
      
      _logger.d('Yerel bildirim gösterildi: ID=$notificationId, Başlık=${notification.title}');
      
      // Kullanıcıya geri bildirim ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bildirim gönderildi')),
        );
      }
    } catch (e) {
      _logger.e('Yerel bildirim gösterilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bildirim gösterilirken hata: $e')),
        );
      }
    }
  }

  /// Tüm bildirimleri temizleme onay dialogu
  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirimleri Temizle'),
        content: const Text(
          'Tüm bildirimleri temizlemek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<NotificationViewModel>(context, listen: false).clearNotifications();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tüm bildirimler temizlendi')),
              );
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  /// Test bildirimi gönderme
  Future<void> _sendTestNotification() async {
    try {
      _logger.d('Test bildirimi gönderiliyor...');
      
      // NotificationViewModel'i al
      final notificationViewModel = Provider.of<NotificationViewModel>(context, listen: false);
      
      // FCM token'ı almaya çalışalım
      String? fcmToken = notificationViewModel.fcmToken;
      if (fcmToken == null || fcmToken.isEmpty) {
        await notificationViewModel.fetchFcmToken();
        fcmToken = notificationViewModel.fcmToken;
        
        if (fcmToken == null || fcmToken.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('FCM token alınamadı. Bildirim gönderilemez.')),
            );
          }
          return;
        }
      }
      
      // Test bildirimi için veri oluştur
      final testNotification = NotificationData(
        title: 'Test Bildirimi',
        body: 'Bu bir test bildirimidir. ${DateTime.now().toString()}',
        data: {
          'type': 'test_notification',
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'created_at': DateTime.now().toString()
        },
        receivedAt: DateTime.now(),
      );
      
      // 1. Önce yerel bildirim göster
      await _showLocalNotification(testNotification);
      
      // 2. NotificationViewModel'e ekleme yapalım
      notificationViewModel.addNotification(testNotification);
      
      // 3. Kullanıcıya FCM API test dialog'unu gösterelim
      _showFcmTestDialog(fcmToken!);
    } catch (e) {
      _logger.e('Test bildirimi gönderilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test bildirimi gönderilirken hata: $e')),
        );
      }
    }
  }
  
  /// FCM Test Dialog'unu göster
  void _showFcmTestDialog(String token) {
    // FCM HTTP API üzerinden bildirim göndermek için gerekli auth token
    final TextEditingController authTokenController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('FCM HTTP API Test'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FCM HTTP v1 API üzerinden bildirim göndermek için bir Firebase servis hesabı yetkilendirme token\'ı gereklidir.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              const Text(
                'Alıcı Token:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  token,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Auth Token (Bearer):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: authTokenController,
                decoration: const InputDecoration(
                  hintText: 'OAuth 2.0 token veya servis hesabı token\'ı',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              const Text(
                'Not: Yetkilendirme token\'ı, Firebase Admin SDK OAuth 2.0 yetkilendirme veya Firebase servis hesabı üzerinden alınabilir.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Auth token kontrolü
              final authToken = authTokenController.text.trim();
              if (authToken.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auth token boş olamaz')),
                );
                return;
              }
              
              // Dialog'u kapat
              Navigator.of(context).pop();
              
              // Bildirim gönderme işlemini başlat
              await _sendRealFcmNotification(token, authToken);
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }
  
  /// Gerçek FCM HTTP API bildirimi gönder
  Future<void> _sendRealFcmNotification(String token, String authToken) async {
    try {
      _logger.d('FCM HTTP API bildirimi gönderiliyor...');
      
      // Yükleniyor göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bildirim gönderiliyor...')),
        );
      }
      
      // NotificationViewModel'i al
      final notificationViewModel = Provider.of<NotificationViewModel>(context, listen: false);
      
      // Bildirim içeriği
      final title = 'FCM HTTP API Testi';
      final body = 'Bu bildirim FCM HTTP v1 API üzerinden gönderildi. ${DateTime.now().toString()}';
      final data = {
        'type': 'http_api_test',
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'sender': 'notifications_view',
        'timestamp': DateTime.now().toString()
      };
      
      // FCM HTTP API bildirimi gönder
      final success = await notificationViewModel.sendFcmNotification(
        token: token,
        title: title,
        body: body,
        data: data,
        authToken: authToken,
      );
      
      // Sonucu göster
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('FCM HTTP API bildirimi başarıyla gönderildi'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('FCM HTTP API bildirimi gönderilemedi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('FCM HTTP API bildirimi gönderilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('FCM HTTP API bildirimi gönderilirken hata: $e')),
        );
      }
    }
  }
} 