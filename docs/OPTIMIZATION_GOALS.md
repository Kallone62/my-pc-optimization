# Rekabetçi CS2 Performansı: Amaç ve Yaklaşım / Competitive CS2 Performance: Goals and Approach

[Türkçe](#türkçe) · [English](#english)

---

## Türkçe

### Asıl hedefim

Bu projede bilgisayarımı yalnızca yüksek FPS üreten bir makineye dönüştürmeye çalışmıyorum. **Amacım, CS2'de verdiğim kararların ve mouse ve klavye inputlarımın oyuna mümkün olduğunca hızlı, doğru ve tutarlı yansıdığı bir sistem oluşturmak.** Bunun gerçek karşılığı, kritik anlarda one-tap, spray, counter-strafe ve micro-correction hareketlerini sistemin değişken davranışına takılmadan uygulayabilmek.

Bunun için input cihazı → Windows → game engine → render → display zincirini; ağ üzerinden sunucuya iletilen eylemleri ise ayrı ama ilişkili bir zincir olarak inceliyorum. BIOS, CPU, bellek, GPU, sürücüler, USB, fare, klavye, monitör ve ağ ayarları tek başına değil, **birbirleriyle nasıl çalıştıklarına göre** değerlendirilmeli.

### Neden yalnızca FPS yeterli değil?

Ortalama FPS sistemin ne kadar hızlı kare üretebildiğini gösterir; fakat **bir inputun ne zaman işlendiğini, yeni frame'in ne zaman ekrana geldiğini veya zamanlamanın ne kadar değişken olduğunu tek başına açıklamaz**. Aynı ortalamaya sahip iki yapılandırmadan biri arada frametime veya latency spike'ları üretebilir. Rekabetçi oyunda önemli olan yalnızca tipik kare değil, kritik anda oluşan frametime spike'ı ve geciken inputtur.

Örneğin bir ayar ortalama FPS'yi 500'den 560'a yükseltirken nadir frametime sıçramalarını büyütüyorsa, sayısal artışa rağmen spray veya counter-strafe zamanlaması daha düzensiz hâle gelebilir. Bu sayılar temsili; **daha yüksek ortalama FPS, otomatik olarak daha iyi bir sonuç demek değil.** Input latency, frametime varyansı, tail latency ve stabilite birlikte değerlendirilmeli.

### “Mermi gitmiyor” derken neyi kastediyorum?

Dar anlamda, nişangâh rakibin üzerindeyken isabet etmiş gibi görünen bir atışın server tarafında hit registration / damage olarak onaylanmaması. Daha geniş anlamda ise nişan, ateş etme, durma, yön değiştirme ve spray inputlarımın **niyet ettiğim zamanlama veya konumdan sapmış gibi hissettirmesi**.

Bu his tek başına ağ ya da donanım hatasının kanıtı değil. Gerçek nişan hatası, hareket hâlinde ateş etme, weapon spread, display latency, frametime spike'ları, packet loss veya client–server timing farkları birbirine benzeyen sonuçlar üretebilir. **Ekranda gördüğüm frame, server'ın aynı anda aynı durumu gördüğünü kanıtlamaz.** Önce hangi halkayı ölçtüğümü ayırmam gerekiyor.

### Somut örnekler

**1. One-tap ve micro-correction:** Rakibi gördüğüm anda fare hareketini tamamlayıp ateş ediyorum. Input processing veya ekrandaki visual feedback değişken gecikiyorsa micro-correction'ın geri bildirimi de değişken gelir. Burada yalnızca FPS'yi değil, tekrarlanan aynı senaryoda frametime dağılımını ve mümkünse end-to-end input-to-photon latency'yi karşılaştırırım. Daha hızlı ama daha düzensiz bir sonuç yeterli değil.

**2. Counter-strafe ve spray:** Bir yönde hareket ederken ters yöne basıp durduğum ve ateş ettiğim anın tutarlı olması gerekiyor. Klavyenin actuation / Rapid Trigger ayarını daha agresif yapmak otomatik olarak daha iyi değil; istenmeyen inputlar veya timing varyansı artabilir. Aynı hareket–ateş rutiniyle önceki ve yeni ayarı karşılaştırır, isabet veya hissi birkaç pozisyona dayanarak kesinleştirmem.

**3. Polling rate ve USB yükü:** Farenin polling rate'ini 2000 Hz'den 8000 Hz'e yükseltmek teoride input report interval'ını kısaltabilir. Ama işlemci, USB ve oyun yükü altında daha fazla dalgalanma yaratıyorsa gerçek avantaj kaybolabilir. Karar, “8000 daha büyük” mantığıyla değil; aynı koşullarda input latency, frametime tail değerleri ve stabiliteyle verilir.

**4. BIOS, bellek ve CPU ayarları:** Daha agresif bellek zamanlaması veya CPU politikası benchmark'ta kazanç gösterebilir. Buna karşılık oyun sırasında microstutter, kararsız clock davranışı veya açılışlar arasında tutarsızlık ortaya çıkıyorsa bu ayarı tutmam. Ölçüm, kararlılık ve yeniden başlatma sonrası tekrarlanabilirlik birlikte geçerli olmalı.

**5. Ağ ve FACEIT:** Daha düşük ping her zaman daha iyi hit registration anlamına gelmez. Packet loss, jitter ve server-side koşullar farklı bir tablo oluşturabilir. Yerel bir aim veya frametime testindeki kazanımı online oyunda aynen var saymam; yerel sonuçları FACEIT/gerçek maç gözlemlerinden ayırırım. Yerel olarak hızlanmak, sunucuya ait belirsizlikleri ortadan kaldırmaz.

### Bir ayarı nasıl değerlendiriyorum?

Önce **mevcut baseline'ı** kaydederim. Ardından değişiklik için şu soruları yanıtlarım: Hangi sorunu hedefliyorum? Nasıl fayda sağlaması bekleniyor? Aynı koşullarda neyle karşılaştıracağım? **Hangi sonucu görürsem değişikliği tutacağım?** Bu kabul koşulunu sonucu görmeden belirlerim.

Mümkün olduğunda tek değişkeni değiştirir, karşılaştırılabilir koşullarda tekrar ederim. Fark küçük veya öznel ise blind A/B ve eski ayara rollback kullanırım. Yerel testler hızlı ön eleme sağlar; gerekli durumlarda sonucu birden fazla oturumda, yeniden başlatma sonrasında ve gerçek maçta da kontrol ederim. Tek iyi benchmark, birkaç kill veya bir akşamlık iyi his başarı kanıtı değil.

Bir katmandaki kazanç başka bir katmandaki tutarlılığı bozuyorsa bütün zincirin sonucu önemlidir. **Net ve tekrarlanabilir fayda yoksa ayar aktif baseline'a girmez.** Doğrulanan değişiklikleri gerekçesi, test koşulları ve rollback bilgisiyle saklarım.

### Bu deponun amacı ve sürekliliği

Bu depo, herkese uygulanacak evrensel bir tweak listesi değil; kendi sistemim için **ölçülerek geliştirilen, gerektiğinde geri alınabilen ve yeniden kurulabilen** bir optimizasyon baseline'ının kaydı. Şu an aktif platformum Ryzen 7 9800X3D / ASUS B850-I. Önceki i9-13900KF / Z690 Tachyon kayıtları arşivde duruyor. Gelecekte donanım yükselttiğimde eski sonuçları kendi koşullarıyla koruyup yeni sistemi yeniden değerlendireceğim.

**Başarı ölçütüm:** Daha yüksek bir benchmark skoru değil; başlangıç baseline'ına kıyasla daha hızlı, daha tutarlı ve kararlı olduğu gösterilen, gerçek CS2 oynanışına katkısı sınanmış bir sistem.

İlgili kayıtlar: [Güncel sistem](SYSTEM.md) · [Referans ayarlar](REFERENCE_STATE.md) · [Doğrulama durumu](VALIDATION.md).

---

## English

### What I'm trying to achieve

I'm not simply trying to build a PC that produces the highest FPS. **I want my decisions and physical inputs in CS2 to translate into in-game actions and visual feedback as quickly, accurately, and consistently as possible.** In practice, that means being able to execute shots, sprays, counter-strafes, and small aim corrections without unpredictable system behavior getting in the way.

I examine the local path from input devices through Windows and the game to the display, while treating network communication and server confirmation as a separate but related path. BIOS, CPU, memory, GPU, drivers, USB, mouse, keyboard, display, and networking matter **as an interacting system**, not as isolated settings.

### Why FPS alone is not the goal

Average FPS describes throughput, but it does not by itself tell me when an input was processed, when the next image appeared, or how much these timings vary. Two configurations with the same average can behave differently during rare slow frames. In competition, those outliers can matter more than the typical frame.

For example, a setting could raise average FPS from 500 to 560 while making occasional frametime spikes worse. Those numbers are illustrative, not measurements from my PC. **Higher average FPS is not automatically a better operating point.** I look at input latency, frametime variation, bad-tail behavior, and stability together.

### What I mean by “my shots aren't registering”

In the narrow sense, I mean a shot that looks like a hit on the client but is not confirmed as damage by the server. More broadly, I mean aiming, firing, stopping, changing direction, or spraying **feeling out of sync with the position or timing I intended**.

That feeling does not prove a networking or hardware fault. Aim errors, movement inaccuracy, weapon spread, local display latency, frametime spikes, packet loss, and client–server timing can produce similar symptoms. **A frame rendered on my screen does not prove the server observed that same state at the same moment.** I need to isolate the part of the chain I'm actually testing.

### Examples from competitive play

**1. One-taps and micro-corrections:** I finish a small mouse correction and fire. If input processing or visual feedback varies from moment to moment, correcting my aim can feel inconsistent. I compare repeated scenarios using frametime distributions and, where measurable, end-to-end input-to-display latency—not just average FPS.

**2. Counter-strafing and spraying:** Stopping, reversing movement, and firing require predictable timing. More aggressive keyboard actuation or rapid-trigger settings can introduce accidental inputs as well as potential benefits. I compare a consistent movement-and-firing routine and avoid conclusions based on a few successful duels.

**3. Polling rate and USB load:** Moving a mouse from 2000 Hz to 8000 Hz can shorten the nominal report interval, but additional CPU/USB overhead or worse frametime tails may erase the benefit. The larger number does not decide the outcome; measured latency and consistency do.

**4. BIOS, memory, and CPU settings:** Tighter memory timings or a more aggressive CPU policy may improve a synthetic result while introducing stutter or instability during CS2. I keep a change only when its benefit and stability remain repeatable, including after reboots.

**5. Networking and FACEIT:** A lower ping does not guarantee better hit confirmation. Jitter, packet loss, and server-side conditions may matter. I separate local aim/frametime tests from online matches and verify whether a local improvement carries over instead of assuming that it does.

### How I evaluate changes

I start with a recorded **baseline**. For each candidate change, I define the problem, the expected mechanism, a comparable test, and the **result required to keep it**—before seeing the outcome.

Where possible, I change one variable at a time and repeat under comparable conditions. For subtle or subjective differences, I use blind A/B comparisons and return to the previous setting. Local tests are useful for screening; relevant changes also need repeated sessions, reboot checks, and real-match verification. One benchmark result or a few good rounds are not enough.

If a gain in one layer harms consistency elsewhere, the whole system matters. **A setting only becomes part of the active baseline when its net benefit is repeatable.** I keep the reason, conditions, and rollback information alongside accepted changes.

### What this repository represents

This is not a universal tweak list. It's a record of a **measured, reversible, and reproducible configuration** for my own esports system. My active platform is currently Ryzen 7 9800X3D / ASUS B850-I; my previous i9-13900KF / Z690 Tachyon configuration remains archived. Hardware upgrades will lead to a new active baseline, while older results stay attached to the conditions under which they were obtained.

**Success means** a system shown to be faster, more consistent, and stable against its starting point, with any claimed contribution to real CS2 play actually tested—not just a higher benchmark score.

Related records: [Current system](SYSTEM.md) · [Reference settings](REFERENCE_STATE.md) · [Validation status](VALIDATION.md).
