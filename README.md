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
- **Windows ve CS2:** `Run_CS2_Gaming_Scripts.cmd` — Windows, device, network ve security baseline'ını uygular.
- **Oyun yapılandırması:** `Game/autoexec.cfg` — CS2 ayarlarım.

İndirme ve doğrulama sonuçları `Downloads/` altındaki raporlarda kayıtlı. Driver ve uygulama kurulumlarını bu sonuçlara göre manuel tamamlıyorum.

**Not:** `00_Fresh_Install_W11_Pro.cmd`, **D:** sürücüsünü formatlayan ayrı bir Windows image kurulum aracıdır; optimizasyon launcher'ı değildir.

**Belgeler:** [Amaç ve yaklaşım](docs/OPTIMIZATION_GOALS.md) · [Sistem](docs/SYSTEM.md) · [Referans ayarlar](docs/REFERENCE_STATE.md) · [İndirme ve kurulum](docs/DOWNLOAD_ONLY.md) · [Doğrulama durumu](docs/VALIDATION.md)

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
- **Windows and CS2:** `Run_CS2_Gaming_Scripts.cmd` — applies Windows, device, network, and security baseline settings.
- **Game configuration:** `Game/autoexec.cfg` — my CS2 settings.

Download and verification results are recorded under `Downloads/`. I use these reports to complete driver and application installation manually.

**Note:** `00_Fresh_Install_W11_Pro.cmd` is a separate Windows image deployment tool that formats the fixed **D:** drive; it is not an optimization launcher.

**Documentation:** [Goals and approach](docs/OPTIMIZATION_GOALS.md) · [System](docs/SYSTEM.md) · [Reference settings](docs/REFERENCE_STATE.md) · [Downloads and installation](docs/DOWNLOAD_ONLY.md) · [Validation status](docs/VALIDATION.md)
