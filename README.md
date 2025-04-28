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
