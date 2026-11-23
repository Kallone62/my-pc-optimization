# Espor Sistemi Optimizasyonu / Esports System Optimization

[Türkçe](#türkçe) · [English](#english)

---

## Türkçe

Bu repo, **CS2'de rekabetçi performansımı geliştirmek için kendi bilgisayar sistemimde yürüttüğüm optimizasyon çalışmalarını** içeriyor. Amacım yalnızca daha yüksek FPS almak değil; input lag'i azaltırken frametime tutarlılığını, girişlerin oyuna yansımasını ve gerçek maçtaki shot, spray ve hareket zamanlamasını birlikte iyileştirmek.

BIOS, donanım, Windows, sürücüler, oyun ayarları, giriş cihazları, monitör ve ağ yapılandırmasını aynı sistemin parçaları olarak ele alıyorum. Ayarları rastgele yükseltmek veya her tweak'i iyileştirme kabul etmek yerine, değişiklikleri mevcut yapılandırmaya karşı değerlendirip **tekrarlanabilir ve kararlı kazanımları** korumayı hedefliyorum.

Bu çalışma tek bir donanımda bitmiyor. Sistemimi yükselttiğimde aktif yapılandırmayı yeni donanıma göre yeniden oluşturacağım; önceki sistemlerimin ayarları ve kayıtları ise arşivde kalacak.

**Güncel sistem:** Ryzen 7 9800X3D · ASUS ROG STRIX B850-I · RTX 3080 12 GB · ZOWIE XL2566X+ (400 Hz)

**Önceki sistem:** Core i9-13900KF · Gigabyte Z690 Tachyon — eski BIOS kayıtları arşivde

### Depodaki araçlar

- **Sürücüler:** `.drivers/Download_Gaming_Drivers.cmd` — uygun paketleri indirir ve doğrular; kurmaz.
- **Uygulamalar:** `Download_PostFormat_Apps.cmd` — uygulama paketlerini indirir ve doğrular; kurmaz.
- **Windows ve CS2:** `Run_CS2_Gaming_Scripts.cmd` — sistem ayarlarını gerçekten değiştirir. Etkileri incelenmeden çalıştırılmamalıdır.
- **Oyun yapılandırması:** `Game/autoexec.cfg` — CS2 ayarlarım.

İndirilen paketlerin sonuçları `Downloads/` altındaki raporlarda tutulur. Kurulumlar manuel tamamlanır. Bu dosyalar mevcut sistemim için hazırlandığından başka bir bilgisayara doğrudan uygulanmamalıdır.

**Önemli:** `00_Fresh_Install_W11_Pro.cmd` sabit **D:** sürücüsünü biçimlendirebilir. Normal optimizasyon amacıyla çalıştırılmamalıdır. Bazı Windows scriptleri güvenlik ve güncelleme politikalarını değiştirir. Depodaki ayarların tamamı gerçek maç performansı açısından doğrulanmış kabul edilmemelidir.

**Belgeler:** [Sistem](docs/SYSTEM.md) · [Referans ayarlar](docs/REFERENCE_STATE.md) · [İndirme ve kurulum](docs/DOWNLOAD_ONLY.md) · [Doğrulama durumu](docs/VALIDATION.md)

---

## English

This repository contains the **optimization work I do on my own PC to improve competitive performance in CS2**. My goal is not simply to maximize FPS. I want lower input latency, more consistent frametimes, more responsive inputs, and reliable shot, spray, and movement timing in actual matches.

I treat BIOS, hardware, Windows, drivers, game settings, input devices, display, and networking as parts of the same system. Rather than assuming that more aggressive settings or generic tweaks are better, I compare changes against the current baseline and aim to keep **repeatable improvements without sacrificing stability or consistency**.

This is an ongoing project, not a configuration tied permanently to one hardware platform. When I upgrade my PC, the active configuration will be adapted to the new hardware, while previous configurations and records remain archived.

**Current system:** Ryzen 7 9800X3D · ASUS ROG STRIX B850-I · RTX 3080 12 GB · ZOWIE XL2566X+ (400 Hz)

**Previous system:** Core i9-13900KF · Gigabyte Z690 Tachyon — legacy BIOS records archived

### Repository tools

- **Drivers:** `.drivers/Download_Gaming_Drivers.cmd` — downloads and verifies matching packages; does not install them.
- **Applications:** `Download_PostFormat_Apps.cmd` — downloads and verifies application packages; does not install them.
- **Windows and CS2:** `Run_CS2_Gaming_Scripts.cmd` — makes actual system changes. Review its effects before running it.
- **Game configuration:** `Game/autoexec.cfg` — my CS2 settings.

Download results are recorded under `Downloads/`; installation is manual. These files are designed for my current hardware and should not be applied blindly to other PCs.

**Important:** `00_Fresh_Install_W11_Pro.cmd` may format the fixed **D:** drive. Do not run it for routine optimization. Some Windows scripts alter security and update policies. Not every configuration in this repository has been validated for real-match performance.

**Documentation:** [System](docs/SYSTEM.md) · [Reference settings](docs/REFERENCE_STATE.md) · [Downloads and installation](docs/DOWNLOAD_ONLY.md) · [Validation status](docs/VALIDATION.md)
