# Doğrulama Durumu / Validation Status

## Türkçe

Bu belgede **kod/paket kontrolü** ile **gerçek Windows ve CS2 testlerini** ayrı tutuyorum.

### Kod ve release kontrolleri

- Driver downloader: `.drivers/Download-Gaming-Drivers.ps1`
- App downloader: `.scripts/Download-PostFormat-Apps.ps1`
- Ortak transfer katmanı: `.scripts/Download-Transport.ps1`
- CMD launcher'lar ve release manifest'i bu yolları kullanıyor.
- Release workflow gerekli dosyaları ve nested ZIP bütünlüğünü kontrol ediyor. `00_Fresh_Install_W11_Pro.cmd` release paketine alınmıyor.

### Henüz tamamlanmamış testler

- Windows PowerShell 5.1 syntax ve gerçek execution
- Güncel vendor URL'leri, download, SHA-256 / signature ve INF–hardware ID eşleşmesi
- Reboot sonrası driver, NIC, USB ve security state
- CS2/FACEIT üzerinde input latency, frametime tail ve shot/spray tutarlılığı için A/B karşılaştırmaları

**Kod kontrolüyle performans kazanımı ilan etmiyorum.** Windows ve gerçek maç doğrulaması ayrı.

### Arşiv

Ekim 2026 tarihli `FINAL_AUDIT.txt` ve `FINAL_README.txt`, eski unattended installer sürümünün kayıtları. Git history'de duruyor.

## English

I separate **static code and package checks** from **Windows runtime and real-match validation**.

The release workflow checks required files, nested ZIP integrity and the intended release scope; it excludes the destructive imaging launcher. Windows PowerShell 5.1 execution, current vendor downloads and signatures, driver binding, post-reboot device state, and CS2/FACEIT input/frametime tests remain to be verified.

Static inspection alone is not a performance result. The October 2026 `FINAL_AUDIT.txt` and `FINAL_README.txt` are historical records of the previous unattended installer.
