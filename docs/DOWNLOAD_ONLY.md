# Sürücü ve Uygulama Hazırlığı / Driver and App Downloads

Bu katmanın amacı **paketleri indirmek, doğrulamak ve kurulumu ayrı tutmak**. Böylece hangi driver veya uygulamanın sistem davranışını değiştirdiğini kontrollü test edebilirim.

The purpose of this layer is to **download and verify packages while keeping installation separate**, so driver and application changes can be tested independently.

## Türkçe

### İndirme akışı

- Driver paketleri resmî vendor kaynaklarından, Visual C++ All-in-One arşivi TechPowerUp'tan indiriliyor.
- Paketler `Downloads/`, log ve receipt'ler `Logs/` altında; sürücü harfine bağlı değiller.
- Doğrudan HTTPS transferlerinde `curl.exe`, retry ve sunucu desteklediğinde resume kullanılıyor. Doğrulanmış dosyalar uygun koşullarda tekrar indirilmiyor.
- WinGet geçici olarak `wininet` backend'iyle çalışıyor. Normal çıkışta eski ayarlar geri yükleniyor; kesinti ihtimali için yedek tutuluyor. A/B karşılaştırması için `-WinGetDownloader Default` kullanılabilir.
- SHA-256, Authenticode ve gerektiğinde vendor hash / catalog doğrulaması yapılıyor. `FAILED` durumundaki paket hazır değil.
- Driver ve app downloader'ları **kurulum yapmıyor**. NVIDIA Control Panel'in ayrı CMD'si ise Store üzerinden kurulum yapıyor.

### Driver'lar

`.drivers\Download_Gaming_Drivers.cmd`, güncel **B850-I / 9800X3D / RTX 3080 (PCI DEV_220A)** sistemine uygun paketleri hazırlıyor.

Sonuç: `Downloads\Drivers\DRIVER_MANUAL_INSTALL_ORDER.csv`.

Önerilen manuel sıra:

1. AMD chipset
2. Intel I226-V LAN
3. Realtek UCM — eşleşen ACPI device varsa
4. AMD iGPU — ayrı bir iGPU-driver baseline'ı test edilecekse
5. NVIDIA WHQL — graphics-only
6. ZOWIE XL2566X+ WHQL monitor INF
7. NVIDIA driver kurulumu ve reboot sonrasında `Downloads\Drivers\Install_NVIDIA_Control_Panel.cmd`

ASUS paketlerinin SHA-256'sı resmî kayıtla karşılaştırılıyor; AMD/NVIDIA EXE'lerinde publisher signature, monitör arşivinde sabit SHA-256 ve catalog doğrulanıyor. AMD Adrenalin EXE'si doğrudan driver-only INF değildir; iGPU için gerçek hardware ID/INF eşleşmesini kontrol ederim.

Temiz Windows'ta I226-V internet bağlantısı henüz yoksa önceden hazırlanmış güvenilir LAN INF ile bağlantı kurulabilir.

### Uygulamalar

`Download_PostFormat_Apps.cmd` şu paketleri hazırlıyor: Chrome, AutoHotkey, Steam, FACEIT Anti-Cheat, Spotify, TeamSpeak 3.6.2, Logitech Onboard Memory Manager, DirectX web installer ve Visual C++ All-in-One.

- **Visual C++:** TechPowerUp'tan güncel All-in-One ZIP; sayfadaki SHA-256 ile kontrol. Arşivi çıkarıp `install_all.bat` dosyasını manuel çalıştırırım.
- **DirectX:** Microsoft `dxwebsetup.exe`; kurulum sırasında internet gerekiyor.
- **TeamSpeak 3.6.2:** Sabit SHA-256 ile doğrulama; optional Overwolf bileşeni kurulumda seçilmiyor.
- **Logitech OMM:** Publisher signature kontrolü.
- **NVIDIA Control Panel:** NVIDIA driver kurulumundan ve reboot'tan sonra ayrı CMD ile Microsoft Store'dan kuruluyor.
- **Wootility:** Browser üzerinden. **ExitLag:** İsteğe bağlı manuel indirme.

WinGet paket klasörleri yeni indirme öncesi temizleniyor; eski dosya güncel sürüm gibi gösterilmiyor. Bir paketin başarısız olması sonraki paketleri engellemiyor.

Sonuç: `Downloads\Apps\APP_MANUAL_INSTALL_ORDER.csv`. Bu dosya **indirme ve doğrulama durumunu** gösterir, kurulu uygulama listesini değil.

### Karşılaştırma

Driver kurulumu veya büyük download sırasında benchmark yapmam. Aynı CS2 map/server/client koşullarında frametime spike'larını, alt-tab/focus değişimlerini, Event Viewer driver reset kayıtlarını ve latency sonuçlarını karşılaştırırım.

## English

### Download workflow

Driver packages come from official vendors; the Visual C++ All-in-One ZIP comes from TechPowerUp. Downloads are stored under `Downloads/` and reports under `Logs/`, relative to the active SSD Setup folder.

Direct HTTPS transfers prefer `curl.exe` with retries, resume where supported, and verified-file reuse. WinGet temporarily selects `wininet`; the previous settings are restored on normal exit, with a backup for interruptions. `-WinGetDownloader Default` uses the existing backend for comparison.

Packages are checked using SHA-256, Authenticode signatures, vendor hashes and catalogs as applicable. `FAILED` means not ready. **Download scripts do not install software**; the separate NVIDIA Control Panel CMD is an installation tool.

### Drivers

Run `.drivers\Download_Gaming_Drivers.cmd` for the B850-I / 9800X3D / RTX 3080 (PCI DEV_220A) configuration. Review `Downloads\Drivers\DRIVER_MANUAL_INSTALL_ORDER.csv`.

Manual order: **AMD chipset → Intel I226-V → Realtek UCM (matching ACPI device) → optional, separately tested AMD iGPU driver → NVIDIA WHQL graphics-only → ZOWIE monitor INF → NVIDIA Control Panel after reboot**.

ASUS downloads use vendor SHA-256 records; AMD/NVIDIA EXEs require valid publisher signatures; the monitor package uses a pinned SHA-256 and catalog check. AMD Adrenalin EXE is not a ready-to-install driver-only INF. If Windows lacks an Ethernet driver after installation, bootstrap I226-V with a previously verified LAN INF.

### Applications

Run `Download_PostFormat_Apps.cmd` for Chrome, AutoHotkey, Steam, FACEIT Anti-Cheat, Spotify, TeamSpeak 3.6.2, Logitech OMM, DirectX and Visual C++.

- **Visual C++:** TechPowerUp All-in-One ZIP verified against its published SHA-256; extract and run `install_all.bat` manually.
- **DirectX:** Microsoft `dxwebsetup.exe`; installation needs internet.
- **TeamSpeak:** Pinned SHA-256; skip optional Overwolf.
- **Logitech OMM:** Publisher signature check.
- **NVIDIA Control Panel:** Separate CMD installs from Microsoft Store after the NVIDIA driver and reboot.
- **Wootility:** Browser-based. **ExitLag:** Optional manual download.

WinGet refreshes package folders so old files are not treated as current. A failed package does not prevent later downloads. Review `Downloads\Apps\APP_MANUAL_INSTALL_ORDER.csv` for **download and verification status**, not installation state.

### Comparison

Keep installation separate from benchmarks. Compare the same CS2 map/server/client conditions, including frametime spikes, focus changes, driver resets and latency.
