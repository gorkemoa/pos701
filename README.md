# POS701 Flutter Mobil Uygulaması

POS701 projesinin Flutter ile geliştirilmiş mobil istemcisidir. Bu uygulama, satış noktası (POS) işlemlerini mobil cihazlar üzerinden yönetmeyi hedefler.

## ✨ Temel Özellikler (Planlanan)

*   Ürün Yönetimi
*   Satış İşlemleri
*   Müşteri Takibi
*   Raporlama
*   Stok Yönetimi

## 🚀 Başlarken

Bu bölüm, projeyi yerel makinenizde kurup çalıştırmanıza yardımcı olacaktır.

### Ön Gereksinimler

*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (Belirtilen sürüm veya üzeri)
*   [Dart SDK](https://dart.dev/get-dart)
*   Bir IDE (VS Code, Android Studio, IntelliJ IDEA vb.)
*   Gerekli Flutter eklentileri (IDE'nize göre değişir)

### Kurulum

1.  Depoyu klonlayın:
    ```bash
    git clone https://github.com/Office701-Flutter-Apps/pos701-flutter-mobile.git
    cd pos701-flutter-mobile
    ```
2.  Bağımlılıkları yükleyin:
    ```bash
    flutter pub get
    ```

### Çalıştırma

Uygulamayı bir emülatörde veya fiziksel bir cihazda çalıştırmak için:

```bash
flutter run
```

## 🛠️ Kullanılan Teknolojiler

*   **Framework:** [Flutter](https://flutter.dev/)
*   **Dil:** [Dart](https://dart.dev/)
*   **State Management:** [Riverpod](https://riverpod.dev/) (Planlanan)
*   **Routing:** [AutoRoute](https://pub.dev/packages/auto_route) (Planlanan)
*   **Dependency Injection:** [GetIt](https://pub.dev/packages/get_it) (Planlanan)
*   **Immutable States:** [Freezed](https://pub.dev/packages/freezed) (Planlanan)

## 📂 Klasör Yapısı (Mevcut Durum)

Projenin mevcut klasör yapısı aşağıdaki gibidir:

```
lib/
|-- constants/      # Uygulama sabitleri
|-- models/         # Veri modelleri (entities)
|-- services/       # API servisleri, yerel depolama vb.
|-- viewmodels/     # İş mantığı ve durum yönetimi (controllers/providers)
|-- views/          # Kullanıcı arayüzü ekranları (pages/screens)
|-- widgets/        # Tekrar kullanılabilir UI bileşenleri
|-- utils/          # Yardımcı fonksiyonlar ve sınıflar
|-- main.dart       # Uygulama giriş noktası
```

*Not: Proje geliştikçe Clean Architecture prensiplerine daha yakın bir yapıya geçiş hedeflenmektedir.*

## 🤝 Katkıda Bulunma

Bu özel (private) bir depodur. Katkıda bulunmak isteyen ekip üyeleri, standart iş akışını (branch oluşturma, pull request açma vb.) takip etmelidir.

## Firebase Push Bildirimleri Kurulumu

Firebase push bildirimlerini kullanabilmek için aşağıdaki adımları tamamlamanız gerekmektedir:

### 1. Firebase Konsol Kurulumu

1. [Firebase Console](https://console.firebase.google.com/) adresine gidin ve Google hesabınızla giriş yapın
2. "Proje Ekle" seçeneğini tıklayın ve yeni bir proje oluşturun
3. Projenize bir ad verin (örn. "POS701") ve oluşturmayı tamamlayın
4. Proje panelinizde, Android uygulamanızı eklemek için Android simgesini seçin
5. Paket adını girin: `com.example.pos701` (veya kendi paket adınızı)
6. (İsteğe bağlı) SHA-1 parmak izini ekleyin (kimlik doğrulama kullanıyorsanız gerekli)
7. "Uygulamayı Kaydet" butonuna tıklayın

### 2. Yapılandırma Dosyalarının İndirilmesi ve Eklenmesi

1. `google-services.json` dosyasını indirin
2. İndirilen `google-services.json` dosyasını `android/app/` dizinine yerleştirin
3. iOS için, `GoogleService-Info.plist` dosyasını indirin ve XCode kullanarak projenize ekleyin
4. iOS için XCode projesini açmak için `ios` dizinine gidip `open Runner.xcworkspace` komutunu çalıştırın

### 3. Android Manifest Ayarları

`android/app/src/main/AndroidManifest.xml` dosyasında, `<application>` etiketinin içine aşağıdaki servisi ve meta verisini ekleyin:

```xml
<service
    android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingBackgroundService"
    android:exported="false"
    android:permission="android.permission.BIND_JOB_SERVICE" />
    
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="pos701_notification_channel" />
    
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/ic_launcher" />
```

### 4. Test Bildirimi Gönderme

1. Firebase Konsolu'na gidin > Cloud Messaging > Create your first campaign
2. "Notification" kampanya türünü seçin
3. Kampanya ayrıntılarını girin (başlık, mesaj vb.)
4. Hedef kitleyi "Android" olarak seçin
5. Gönder veya zamanla

### 5. Özel Konular ile Çalışma

Özel bildirim konuları için, uygulama içinde konuya abone olun:

```dart
// Belirli bir konuya abone ol
notificationViewModel.subscribeToTopic('yeni_siparis');

// Belirli bir konudan aboneliği kaldır
notificationViewModel.unsubscribeFromTopic('yeni_siparis');
```

Firebase Console veya API kullanarak bu konulara mesaj gönderebilirsiniz:

```json
{
  "to": "/topics/yeni_siparis",
  "notification": {
    "title": "Yeni Sipariş",
    "body": "Yeni bir sipariş alındı!"
  },
  "data": {
    "type": "order",
    "order_id": "12345"
  }
}
```

## Önemli Notlar

- Uygulama ilk kez çalıştırıldığında kullanıcıdan bildirim izni istenecektir.
- Android 13+ için bildirim izinleri açıkça istenmektedir.
- Arka plan bildirimleri için, kullanıcının bildirimlere izin vermesi gerekmektedir.
- Farklı konulara abone olarak çeşitli bildirim türlerini yönetebilirsiniz.
