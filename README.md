# Espor Sistemi Optimizasyonu / Esports System Optimization

[Türkçe](#türkçe) · [English](#english)

---

## Türkçe

Bu repo, **CS2'de rekabetçi performansımı geliştirmek için kendi bilgisayar sistemimde yürüttüğüm optimizasyon çalışmalarını** içeriyor. Amacım yalnızca daha yüksek FPS almak değil; input latency'yi azaltırken frametime ve input timing tutarlılığını geliştirmek; bunun one-tap, spray, counter-strafe ve micro-correction üzerindeki etkisini gerçek maçta doğrulamak.

BIOS, hardware, Windows, driver, CS2, input, display ve network katmanlarını birlikte değerlendiriyorum. Her tweak'i mevcut baseline'a karşı test ediyor; **tekrarlanabilir performans kazancını ve stabiliteyi** esas alıyorum.

Donanım upgrade'lerinde aktif baseline'ı yeni sisteme göre güncelleyeceğim. Önceki sistemlerin ayarları ve test kayıtları arşivde kalacak.

**Güncel sistem:** Ryzen 7 9800X3D · ASUS ROG STRIX B850-I · RTX 3080 12 GB · ZOWIE XL2566X+ (400 Hz)

**Önceki sistem:** Core i9-13900KF · Gigabyte Z690 Tachyon — BIOS export'ları arşivde

### Depodaki araçlar

- **Sürücüler:** `.drivers/Download_Gaming_Drivers.cmd` — uygun paketleri indirir ve doğrular; kurmaz.
- **Uygulamalar:** `Download_PostFormat_Apps.cmd` — uygulama paketlerini indirir ve doğrular; kurmaz.
- **Windows ve CS2:** `Run_CS2_Gaming_Scripts.cmd` — Windows, device, network ve security baseline'ını uygular.
- **Oyun yapılandırması:** `Game/autoexec.cfg` — CS2 ayarlarım.

Download ve doğrulama raporları `Downloads/` altında. Driver ve uygulama kurulumlarını manuel tamamlıyorum.

**Ayrı işlem:** `00_Fresh_Install_W11_Pro.cmd`, **D:** sürücüsünü formatlayan Windows image deployment aracıdır; optimizasyon launcher'ı değildir.

**Belgeler:** [Amaç ve yaklaşım](docs/OPTIMIZATION_GOALS.md) · [Sistem](docs/SYSTEM.md) · [Referans ayarlar](docs/REFERENCE_STATE.md) · [İndirme ve kurulum](docs/DOWNLOAD_ONLY.md) · [Doğrulama durumu](docs/VALIDATION.md)

---

## English

This repository contains the **optimization work I do on my own PC to improve competitive performance in CS2**. The goal is lower input latency, consistent frametimes and input timing, and improvements that carry over to one-taps, sprays, counter-strafing and micro-corrections in actual matches—not just higher FPS.

I treat BIOS, hardware, Windows, drivers, game settings, input devices, display, and networking as parts of the same system. I test changes against the current baseline and keep **repeatable gains without sacrificing stability or consistency**.

Hardware upgrades lead to a new active baseline. Previous settings and test records stay archived.

**Current system:** Ryzen 7 9800X3D · ASUS ROG STRIX B850-I · RTX 3080 12 GB · ZOWIE XL2566X+ (400 Hz)

**Previous system:** Core i9-13900KF · Gigabyte Z690 Tachyon — archived BIOS exports

### Repository tools

- **Drivers:** `.drivers/Download_Gaming_Drivers.cmd` — downloads and verifies matching packages; does not install them.
- **Applications:** `Download_PostFormat_Apps.cmd` — downloads and verifies application packages; does not install them.
- **Windows and CS2:** `Run_CS2_Gaming_Scripts.cmd` — applies Windows, device, network, and security baseline settings.
- **Game configuration:** `Game/autoexec.cfg` — my CS2 settings.

Download and verification reports are under `Downloads/`. I install drivers and applications manually.

**Separate operation:** `00_Fresh_Install_W11_Pro.cmd` formats the **D:** drive for Windows image deployment; it is not an optimization launcher.

**Documentation:** [Goals and approach](docs/OPTIMIZATION_GOALS.md) · [System](docs/SYSTEM.md) · [Reference settings](docs/REFERENCE_STATE.md) · [Downloads and installation](docs/DOWNLOAD_ONLY.md) · [Validation status](docs/VALIDATION.md)
