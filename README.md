# 📡 Signal - Keystroke Audio Feedback for macOS

Signal, macOS için geliştirilmiş, klavye vuruşlarınıza gerçek zamanlı ve düşük gecikmeli (low-latency) sesli geri bildirim sağlayan yerel (native) bir menü çubuğu uygulamasıdır. Yazım deneyiminizi daha mekanik, nostaljik veya fütüristik hale getirmek için tasarlanmıştır.

![Signal UI](https://img.shields.io/badge/UX-Native_macOS-blue?style=for-the-badge)
![Swift](https://img.shields.io/badge/Language-Swift-orange?style=for-the-badge)
![Latency](https://img.shields.io/badge/Latency-%3C5ms-green?style=for-the-badge)

## 🚀 Özellikler

- **Gerçek Zamanlı Ses Sentezi:** Ses dosyalarını oynatmak yerine, sesleri anlık olarak (On-the-fly) sentezler. Bu sayede işlemci yükü minimuma indirilir ve gecikme hissi (delay) tamamen ortadan kaldırılır.
- **Üç Farklı Ses Profili:**
  - **Mekanik:** Modern mekanik klavye (M-Switch) hissiyatı.
  - **Typewriter:** Klasik vintage daktilo çınlaması.
  - **Sci-Fi:** Gelecekten gelen terminal sesleri ve lazer efektleri.
- **Native Arayüz:** Apple'ın kendi tasarımıyla (Control Center stili) tam uyumlu, şeffaf ve minimalist SwiftUI arayüzü.
- **Menü Çubuğu Yönetimi:** Arka planda sessizce çalışır, menü çubuğundaki ikonu üzerinden anlık ayar yapılmasına olanak tanır.

## 🛠️ Teknik Altyapı

- **Dil:** Swift 5.10+
- **Frameworkler:** SwiftUI, AppKit, AVFoundation (AVAudioEngine)
- **Sistem Dinleyici:** `CGEventTap` (Accessibility API) kullanılarak sistem geneli düşük seviyeli klavye dinleme.
- **Mimari:** Sıfır kütüphane bağımlılığı (Zero-dependency), tamamen yerel Apple API'ları.

## ⚙️ Kurulum ve Derleme

Uygulamayı yerelinizde derlemek için terminale şu komutu yazmanız yeterlidir:

```bash
chmod +x build.sh
./build.sh
```

Derleme bittikten sonra `Signal.app` dosyasını çalıştırabilirsiniz:

```bash
open Signal.app
```

## 🔐 Önemli: Erişim İzinleri

macOS'un güvenlik protokolleri gereği, uygulamamızın tüm sistem genelindeki klavye vuruşlarını algılayabilmesi için **Erişilebilirlik (Accessibility)** izni alması gerekmektedir.

1. **Sistem Ayarları** -> **Gizlilik ve Güvenlik** -> **Erişilebilirlik** yolunu izleyin.
2. `+` simgesine tıklayarak derlediğiniz `Signal.app` dosyasını listeye ekleyin ve aktifleştirin.
3. Uygulamayı kapatıp tekrar açtığınızda sesler aktif olacaktır.

## 📂 Dosya Yapısı

- `Source/Core`: Klavye dinleme ve ses sentezleme motorları.
- `Source/UI`: SwiftUI tabanlı native arayüz dosyaları.
- `SignalApp.swift`: Uygulama yaşam döngüsü ve menü bar yönetimi.
- `build.sh`: Uygulamayı `.app` paketine çeviren derleme scripti.

---
*Geliştiren: [unitybtw](https://github.com/unitybtw)*
