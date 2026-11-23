# CS2 PC Optimization

[Türkçe](#türkçe) · [English](#english)

---

## Türkçe

Bu depo, **kendi bilgisayar sistemimin Windows 11 ve Counter-Strike 2 kurulum ve optimizasyon yapılandırmalarını** saklar. Sistemimi yükselttikçe güncel ayarları yeni donanıma göre düzenler, önceki sistemlerin yapılandırmalarını ise arşivde korurum.

**Güncel sistem:** AMD Ryzen 7 9800X3D · ASUS ROG STRIX B850-I · NVIDIA RTX 3080 12 GB · ZOWIE XL2566X+ (400 Hz).

### Başlangıç

1. Depoyu ZIP olarak indirip klasör yapısını koruyarak çıkar.
2. Sürücüler için `.drivers/Download_Gaming_Drivers.cmd`, uygulamalar için `Download_PostFormat_Apps.cmd` dosyasını çalıştır.
3. `Downloads/` klasöründeki sonuçları kontrol et ve gereken kurulumları manuel tamamla. **İndirme scriptleri yazılımları otomatik kurmaz.**
4. İstersen `Game/autoexec.cfg` dosyasını CS2'ye uygula. Windows ayarlarını değiştiren `Run_CS2_Gaming_Scripts.cmd` dosyasını yalnızca etkilerini anladıktan sonra çalıştır.

**Dikkat:** `00_Fresh_Install_W11_Pro.cmd`, **D: sürücüsünü biçimlendirebilir.** Normal kurulum veya optimizasyon için çalıştırma. Bazı sistem scriptleri Windows güvenlik ve güncelleme ayarlarını değiştirebilir. Bu ayarların her bilgisayarda performans kazancı sağlayacağı garanti edilmez.

**Belgeler:** [Sistem](docs/SYSTEM.md) · [CS2 referansı](docs/REFERENCE_STATE.md) · [Kurulum ayrıntıları](docs/DOWNLOAD_ONLY.md) · [Doğrulama durumu](docs/VALIDATION.md)

---

## English

This repository stores the **Windows 11 and Counter-Strike 2 setup and optimization configurations for my personal PC**. As I upgrade my hardware, I adapt the active configuration to the new system and preserve previous configurations as an archive.

**Current system:** AMD Ryzen 7 9800X3D · ASUS ROG STRIX B850-I · NVIDIA RTX 3080 12 GB · ZOWIE XL2566X+ (400 Hz).

### Getting started

1. Download the repository as a ZIP and extract it without changing its folder structure.
2. Run `.drivers/Download_Gaming_Drivers.cmd` for drivers and `Download_PostFormat_Apps.cmd` for applications.
3. Check the results under `Downloads/` and complete the necessary installations manually. **The download scripts do not install software automatically.**
4. Optionally apply `Game/autoexec.cfg` to CS2. Run `Run_CS2_Gaming_Scripts.cmd` only after reviewing the Windows settings it changes.

**Warning:** `00_Fresh_Install_W11_Pro.cmd` **may format the D: drive.** Do not run it for normal setup or optimization. Some system scripts may alter Windows security and update settings. Performance improvements are not guaranteed on other hardware.

**Documentation:** [System](docs/SYSTEM.md) · [CS2 reference](docs/REFERENCE_STATE.md) · [Installation details](docs/DOWNLOAD_ONLY.md) · [Validation status](docs/VALIDATION.md)
