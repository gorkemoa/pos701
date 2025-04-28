# POS701 Flutter Mobil Uygulaması

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

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

## 📂 Klasör Yapısı

Proje, ölçeklenebilir ve bakımı kolay bir kod tabanı sağlamak için Clean Architecture prensiplerine uygun bir klasör yapısı benimsemeyi hedefler:

```
lib/
|-- core/             # Uygulama geneli çekirdek modüller (API istemcisi, tema, sabitler vb.)
|-- features/         # Uygulama özellikleri (modüller)
|   |-- auth/
|   |-- products/
|   |-- sales/
|   |-- ...
|-- main.dart         # Uygulama giriş noktası
```

*Her özellik (feature) kendi içinde `data`, `domain`, ve `presentation` katmanlarını barındıracaktır.*

## 🤝 Katkıda Bulunma

Katkılarınız projeyi daha iyi hale getirmemize yardımcı olur! Lütfen katkıda bulunma yönergeleri için `CONTRIBUTING.md` (oluşturulacak) dosyasına göz atın.

1.  Projeyi Fork'layın
2.  Kendi Feature Branch'inizi oluşturun (`git checkout -b feature/AmazingFeature`)
3.  Değişikliklerinizi Commit'leyin (`git commit -m 'Add some AmazingFeature'`)
4.  Branch'inizi Push'layın (`git push origin feature/AmazingFeature`)
5.  Bir Pull Request açın

## 📄 Lisans

Bu proje MIT Lisansı altında lisanslanmıştır - detaylar için [LICENSE](LICENSE) (oluşturulacak) dosyasına bakın.
