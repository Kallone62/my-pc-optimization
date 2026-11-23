# Aktif BIOS Baseline / Current BIOS Baseline

**ASUS ROG STRIX B850-I · Ryzen 7 9800X3D**

## Türkçe

Bu klasör güncel sistemimin BIOS baseline'ı için ayrıldı. **Kayıt ve doğrulama henüz tamamlanmadı.** Z690 Tachyon export'ları `../../legacy/Z690-Tachyon/` altında arşivli; buradaki ayarların doğrudan kaynağı değiller.

Baseline eklendiğinde şu değerleri, gerçekten kullandığım BIOS sürümüyle birlikte kaydedeceğim:

- BIOS sürümü / AGESA
- EXPO veya manuel RAM timing'leri; UCLK / MCLK / FCLK ilişkisi
- Kullanılan SoC ve memory-controller voltajları
- PBO, Curve Optimizer ve boost ayarları
- CPPC, preferred-core ve power management
- FACEIT için gerekli virtualization / IOMMU / Secure Boot / TPM durumu
- Onboard device enable/disable durumu
- PCIe / ReBAR / storage ayarları
- Test tekrarlanabilirliği için fan/pump profili

Değerleri **bu anakart ve bu BIOS sürümü** üzerinde kontrol edip Windows/CS2 baseline'ıyla karşılaştırdıktan sonra aktif kayıt hâline getireceğim.

## English

This folder is reserved for the current BIOS baseline; **capture and validation are pending**. Previous Z690 exports are archived separately and are not a source of direct settings for this board.

The capture will include the BIOS version/AGESA, memory clocks and timings, actual voltages, PBO/Curve Optimizer, CPPC and power policy, FACEIT-related security/virtualization, onboard devices, PCIe/ReBAR/storage and fan/pump settings listed above. Values will only become active after verification on this exact board/BIOS and comparison against the current Windows/CS2 baseline.
