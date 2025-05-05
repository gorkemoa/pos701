import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pos701/viewmodels/notification_viewmodel.dart';
import 'package:pos701/utils/app_logger.dart';
import 'package:intl/intl.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AppLogger logger = AppLogger();
    logger.d('Bildirimler sayfası açıldı');
    
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
              // Test bildirimi ekle
              Provider.of<NotificationViewModel>(context, listen: false).addTestNotification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Test bildirimi eklendi')),
              );
            },
            tooltip: 'Test bildirimi ekle',
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
                        
                        return Dismissible(
                          key: Key('${notification.title}_${notification.receivedAt.millisecondsSinceEpoch}'),
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
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.notifications, color: Colors.white),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('FCM token yenilendi')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Kopyala',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: token));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('FCM token kopyalandı')),
                        );
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
                'Veri İçeriği:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(notification.data.toString()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
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
} 