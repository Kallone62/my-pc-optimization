# CS2 PC Optimization

Bu depo, **belirli bir bilgisayar için hazırlanmış Windows 11 ve Counter-Strike 2 kurulum/optimizasyon dosyalarını** içerir. Her bilgisayarda performans artışı sağlayan genel bir tweak paketi değildir.

**Hedef sistem:** Ryzen 7 9800X3D · ASUS ROG STRIX B850-I · NVIDIA RTX 3080 12 GB · BenQ ZOWIE XL2566X+ (400 Hz).

## Nasıl kullanılır?

1. **Dosyaları edin:** Depoyu **Code → Download ZIP** ile indir ve klasör yapısını bozmadan çıkar. Gizli `.drivers` ve `.scripts` klasörlerini koru.
2. **Sürücüler:** `.drivers\Download_Gaming_Drivers.cmd` dosyasını çalıştır. Paketler `Downloads\Drivers` içine **indirilir ve doğrulanır; otomatik kurulmaz**. `DRIVER_MANUAL_INSTALL_ORDER.csv` raporunu inceleyerek uygun paketleri manuel kur ve gerektiğinde yeniden başlat.
3. **Uygulamalar:** `Download_PostFormat_Apps.cmd` dosyasını çalıştır. `Downloads\Apps\APP_MANUAL_INSTALL_ORDER.csv` raporunu kontrol edip uygulamaları manuel kur. Visual C++ All-in-One arşivini çıkarıp gerekirse içindeki `install_all.bat` dosyasını yönetici olarak çalıştır. DirectX web yükleyicisi kurulum sırasında internet ister.
4. **NVIDIA Denetim Masası:** NVIDIA ekran sürücüsünü kurup yeniden başlattıktan sonra `Downloads\Drivers\Install_NVIDIA_Control_Panel.cmd` dosyasını çalıştır.
5. **CS2 ayarları:** `Game\autoexec.cfg` dosyasını oyunun uygun yapılandırma klasörüne kendin yerleştir.

`Run_CS2_Gaming_Scripts.cmd` **isteğe bağlıdır**. Windows, aygıt, ağ ve güvenlik ayarlarını değiştirir; yalnızca etkilerini inceledikten sonra çalıştır.

## Önemli uyarılar

- **`00_Fresh_Install_W11_Pro.cmd`, sabit `D:` hedefini biçimlendirebilir.** Normal optimizasyon amacıyla çalıştırma.
- Windows/CS2 politika scriptleri Defender korumalarını ve otomatik güncellemeleri etkileyebilir. Bunların rekabetçi performansa net katkısı doğrulanmış değildir.
- Paketin indirilmesi ve SHA-256/imza doğrulaması, Windows'a başarıyla kurulduğu anlamına gelmez. Güncel sürümün gerçek Windows ortamında uçtan uca doğrulaması tamamlanmış kabul edilmemelidir.
- Eski Z690 BIOS kayıtlarını mevcut B850-I platformuna uygulama.

## Ayrıntılı belgeler

[Donanım](docs/SYSTEM.md) · [CS2 referans ayarları](docs/REFERENCE_STATE.md) · [Kurulum ayrıntıları](docs/DOWNLOAD_ONLY.md) · [Doğrulama durumu](docs/VALIDATION.md)

Bu README kullanıcılar içindir. Geliştirme notları ve teknik ayrıntılar `docs/` klasöründe tutulur.
