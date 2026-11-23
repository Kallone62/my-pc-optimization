# Referans Ayarlar / Reference State

## Türkçe

Aktif **CS2, input ve display baseline'ımın** kayıtlı değerlerini burada tutuyorum. Bunlar testlerde karşılaştırdığım başlangıç değerleri.

### CS2

| Ayar | Baseline |
| --- | --- |
| Resolution | **1280×960**, 4:3 stretched |
| Sensitivity | **0.475** |
| Zoom sensitivity ratio | **0.9** |
| `fps_max` | **0** |
| VSync | Off |
| NVIDIA G-SYNC | Off (kayıtlı oyun durumu) |
| NVIDIA Reflex | Off (kayıtlı oyun durumu) |

### Crosshair

Aktif CS2 kaynağı `Game/autoexec.cfg`. Crosshair, Eylül 2026 sonrasındaki pixel değişkenlerini kullanıyor:

```cfg
cl_crosshair_drawoutline "0"
cl_crosshair_recoil "false"
cl_crosshair_t "false"
cl_crosshairdot "false"
cl_crosshairstyle "4"
cl_crosshair_length "2"
cl_crosshair_gap "0"
cl_crosshair_thickness "2"
cl_crosshaircolor_r "0"
cl_crosshaircolor_g "255"
cl_crosshaircolor_b "0"
cl_crosshaircolor_a "255"
cl_crosshair_screen_height "960"
```

KovaaK V1 profili aktif autoexec ile eşleştirildi.

### Windows desktop mouse

1600 DPI için kayıtlı baseline:

- `MouseSensitivity=4`
- `MouseSpeed=0`
- `MouseThreshold1=0`
- `MouseThreshold2=0`

Desktop pointer speed aynı; Windows mouse acceleration / EPP kapalı.

### Mouse, keyboard ve display

- **Logitech G PRO X Superlight 2 DEX:** 1600 DPI, 2000 Hz, LOD High
- **Wooting 80HE:** genel actuation 0.5 mm; Ctrl/Shift 0.3 mm; WASD 0.1 mm; Rapid Trigger (WASD/Ctrl) 0.1 mm
- **ZOWIE XL2566X+:** fullscreen CS2, 1280×960, 400 Hz

Kaynak screenshot'lar arşivde; burada yeniden uygulanabilir ayar değerleri var.

## English

This file records my active **CS2, input and display baseline** for comparisons. The CS2 values, pixel crosshair commands, mouse and keyboard settings, and 400 Hz display state are listed above.

`Game/autoexec.cfg` is the authoritative CS2 configuration; the KovaaK V1 profile is synchronized to it. The desktop mouse values preserve the configured pointer speed while disabling the Windows acceleration/EPP path. Original setup screenshots remain in the source archive.
