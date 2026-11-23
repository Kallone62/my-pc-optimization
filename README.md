# Espor Sistemi Optimizasyonu / Esports System Optimization

[Türkçe](#türkçe) · [English](#english)

---

## Türkçe

CS2 odaklı **kişisel espor sistemi optimizasyonu** arşivim. Mevcut ve önceki sistemlerimin ayarlarını saklar, donanım yükselttikçe aktif yapılandırmayı güncellerim.

**Güncel sistem:** AMD Ryzen 7 9800X3D · ASUS ROG STRIX B850-I · NVIDIA RTX 3080 12 GB · ZOWIE XL2566X+ (400 Hz).

**Önceki sistem:** Intel Core i9-13900KF · Gigabyte Z690 Tachyon (arşiv).

### Başlangıç

1. Depoyu ZIP olarak indirip klasör yapısını koruyarak çıkar.
2. Sürücüler için `.drivers/Download_Gaming_Drivers.cmd`, uygulamalar için `Download_PostFormat_Apps.cmd` dosyasını çalıştır.
3. `Downloads/` klasöründeki sonuçları kontrol et ve gereken kurulumları manuel tamamla. **İndirme scriptleri yazılımları otomatik kurmaz.**
4. İstersen `Game/autoexec.cfg` dosyasını CS2'ye uygula. Windows ayarlarını değiştiren `Run_CS2_Gaming_Scripts.cmd` dosyasını yalnızca etkilerini anladıktan sonra çalıştır.

**Dikkat:** `00_Fresh_Install_W11_Pro.cmd`, **D: sürücüsünü biçimlendirebilir.** Normal kurulum veya optimizasyon için çalıştırma. Bazı sistem scriptleri Windows güvenlik ve güncelleme ayarlarını değiştirebilir. Bu ayarların her bilgisayarda performans kazancı sağlayacağı garanti edilmez.

**Belgeler:** [Sistem](docs/SYSTEM.md) · [CS2 referansı](docs/REFERENCE_STATE.md) · [Kurulum ayrıntıları](docs/DOWNLOAD_ONLY.md) · [Doğrulama durumu](docs/VALIDATION.md)

---

## English

My personal archive of **CS2-focused esports system optimization**. It preserves configurations for both current and previous systems while the active setup evolves with hardware upgrades.

**Current system:** AMD Ryzen 7 9800X3D · ASUS ROG STRIX B850-I · NVIDIA RTX 3080 12 GB · ZOWIE XL2566X+ (400 Hz).

**Previous system:** Intel Core i9-13900KF · Gigabyte Z690 Tachyon (archived).

### Getting started

1. Download the repository as a ZIP and extract it without changing its folder structure.
2. Run `.drivers/Download_Gaming_Drivers.cmd` for drivers and `Download_PostFormat_Apps.cmd` for applications.
3. Check the results under `Downloads/` and complete the necessary installations manually. **The download scripts do not install software automatically.**
4. Optionally apply `Game/autoexec.cfg` to CS2. Run `Run_CS2_Gaming_Scripts.cmd` only after reviewing the Windows settings it changes.

**Warning:** `00_Fresh_Install_W11_Pro.cmd` **may format the D: drive.** Do not run it for normal setup or optimization. Some system scripts may alter Windows security and update settings. Performance improvements are not guaranteed on other hardware.

**Documentation:** [System](docs/SYSTEM.md) · [CS2 reference](docs/REFERENCE_STATE.md) · [Installation details](docs/DOWNLOAD_ONLY.md) · [Validation status](docs/VALIDATION.md)
