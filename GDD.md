# Game Design Document

| | |
|--|--|
| **Çalışma adı** | TBD |
| **Tema** | Low poly |
| **Kamera** | Third-person action |
| **Platform** | Roblox (hedef) |
| **Durum** | Tasarım — kod yok |
| **İlişkili belgeler** | `COMBAT_STAT_SHEET.md`, `CHEMISTRY_ENGINE.md` |

> CannonClash ile **bağımsız** proje. Kimya motoru konsept olarak taşınabilir; lane / cannon / birim meta bu GDD kapsamında değildir.

---

## İçindekiler

1. [Vision & Pillars](#1-vision--pillars)
2. [Core Loop](#2-core-loop)
3. [Lobby & Modes](#3-lobby--modes)
4. [Character & Stats](#4-character--stats)
5. [Loadout & Equipment Slots](#5-loadout--equipment-slots)
6. [Weapons](#6-weapons)
7. [Off-hand & Weapon Knot](#7-off-hand--weapon-knot)
8. [Combat Systems](#8-combat-systems)
9. [Chemistry & Synergies](#9-chemistry--synergies)
10. [Equipment & Progression](#10-equipment--progression)
11. [PvE — Boss Design](#11-pve--boss-design)
12. [PvP & Teams](#12-pvp--teams)
13. [UI / UX](#13-ui--ux)
14. [MVP Scope](#14-mvp-scope)
15. [Glossary](#15-glossary)
16. [Open Questions (Backlog)](#16-open-questions-backlog)

---

## 1. Vision & Pillars

### Elevator pitch

Class’sız bir **third-person action** oyunu: gücün **silah, zırh ve element kimyasından** gelir. Lobby’den **PvP** veya **boss PvE** maçına girersin; build’in loadout’tur, sınıfın değil.

### Tasarım sütunları

| Sütun | Açıklama |
|-------|----------|
| **Gear is identity** | Rol seçmezsin; ne taktığın seni tanımlar (kılıç+kalkan, staff, dual parry vb.) |
| **Readable chemistry** | Wet hub reaksiyonları — setup görünür, patlama okunaklı |
| **Skill expression** | Orta TTK; guard / dodge / (ileride parry) ile iyi oyuncu maçı uzatır |
| **Fair scaling** | Defence ekipmandan; agresif stat eğrisi yok (1 Def = 0.1% DR) |
| **Low poly clarity** | Okunaklı silüet, statü ikonları, net VFX |

### Hedef his

- **Ortalama oyuncu:** loadout dene, kimya keşfet, orta süreli düellolar.
- **İyi oyuncu:** stamina oyunu, pozisyon, element combo — ödül = daha az yenen vuruş.
- **Takım (ileride):** setup + burst rolleri (Wet → Shock, shred tank vb.).

### Bilinçli olarak olmayanlar (şimdilik)

- Class tree / skill tree
- Pay-to-win stat satışı
- Lane rush / otomatik birim spawn
- Açık dünya (ileride opsiyon)

---

## 2. Core Loop

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   LOBBY     │────▶│    MATCH     │────▶│   RESULT    │
│ loadout     │     │ PvP / PvE    │     │ rewards TBD │
│ stat spend  │     │ combat       │     └──────┬──────┘
└─────────────┘     └──────────────┘            │
       ▲                                        │
       └────────────────────────────────────────┘
```

| Aşama | Oyuncu ne yapar |
|-------|------------------|
| **Lobby** | Loadout düzenle, stat dağıt, eşya seç, mod seç |
| **Match** | Third-person combat, yetenek + light attack, kimya |
| **Result** | *TBD — XP, loot, rating, currency* |
| **Meta** | *TBD — yeni eşya, level, craft* |

Ödül ve uzun vadeli progression **açık** — combat çekirdeği önce kilitlendi.

---

## 3. Lobby & Modes

### Lobby

- Matchmaking kuyruğu
- Loadout ekranı (slotlar §5)
- Stat dağıtımı (level point)
- *Mağaza / kozmetik — TBD*
- *Tutorial — TBD*

### Modlar (hedef)

| Mod | Takım | Durum |
|-----|-------|--------|
| **PvP** | 1v1, 2v2, 3v3 | Hedef; MVP’de 1v1 |
| **PvE Boss** | 1v1, 2v2, 3v3 (co-op) | Hedef; wave + phase boss |
| **Açık dünya** | — | İleride opsiyon |

### Maç akışı (taslak)

1. Loadout kilidi / hazır
2. Arena veya boss odası yükleme
3. Countdown → combat
4. Win condition: *PvP — HP/round TBD; PvE — boss HP*
5. Sonuç ekranı → lobby

---

## 4. Character & Stats

### Class yok

Karakterin **intrinsic yeteneği yok**. Sadece:
- Level (stat point)
- Takılı eşya (pasif + aktif)
- Silah scaling (STR / DEX / INT)

### Primary statlar

| Stat | Rol |
|------|-----|
| **STR** | STR silah hasarı, Crit Damage |
| **DEX** | DEX silah hasarı, Attack Speed, Crit Chance |
| **VIT** | HP, Stamina, az Defence |
| **INT** | INT silah hasarı, Resist, Status Potency, az Buff Potency (herkeste) |

| Kural | Değer |
|-------|--------|
| Level başına | **+4** point |
| Başlangıç | **10** / stat (Lv1) |
| Max level | **50** (*netleştirilebilir*) |

**STR Defence vermez.** Defence ana kaynağı **ekipman**.

### Secondary statlar (10)

Damage (türetilmiş), Attack Speed, Stamina, HP, Defence, Resist, Status Potency, Crit Chance, Crit Damage, Buff Potency.

Tam formüller ve `k` katsayıları → **`COMBAT_STAT_SHEET.md`**.

### TTK profili (kilit)

- **Orta TTK:** ~10–14 isabet (orta gear)
- **İyi vs iyi:** 20–35+ sn (dodge / guard)
- Knob’lar: `base_hp 120`, `k_dmg 0.0075`, DR cap %70 PvP

### Hasar hattı (özet)

Tek **Damage** statı. **Matchup** (±15%): silah element → chest element; yalnızca direct + skill burst (`CHEMISTRY_ENGINE.md`). DoT / reaksiyon ayrı kanal → Potency + Resist.

---

## 5. Loadout & Equipment Slots (kilit)

### Slotlar

```
        [ Helmet ]
[ Main Hand ]  [ Off Hand ]
        [ Chest ]
[ Hand ]       [ Feet ]
```

| Slot (UI) | Kod adı | İçerik |
|-----------|---------|--------|
| **Main Hand** | `main` | **1H** veya **2H** silah |
| **Off Hand** | `off` | **1H silah**, **Shield**, **Quiver**, **Weapon Knot**, **Focus**, **Wand/Scepter** |
| **Helmet** | `head` | Kafa zırhı / baş ekipmanı |
| **Chest** | `chest` | Göğüs zırhı |
| **Hand** | `hands` | Eldiven |
| **Feet** | `feet` | Bot |

**2H melee:** Main = 2H silah · Off = **Weapon Knot** (tagsiz v1).  
**Ranged:** Main = **Bow** veya **Crossbow** (sinerjide **×2** — 2H ile aynı) · Off = **Quiver** (tagsiz; Knot gibi pasif/stat).  
**1H melee:** Main = 1H · Off = Shield / 1H (dual) / **Focus** / Wand-Scepter.

### Yetenek slotları (kilit)

Her eşya tipinin taşıyabileceği yetenek sayısı ve türü:

| Kaynak | Aktif | Pasif | Not |
|--------|-------|-------|-----|
| **2H silah** | 2 slot | — | Her slot **aktif** veya **pasif** yetenek olabilir (toplam 2) |
| **1H silah (main)** | 1 | 0–1 | En az **1 aktif**; bazı silahlarda yalnızca 1 aktif, pasif yok |
| **Off — Quiver** | — | 1 veya stat | Bow / Crossbow off; **1 pasif** *veya* **stat boost** (Knot ile aynı; **element tag yok**) |
| **Off — Shield / Focus** | 1 veya | 1 veya | **1 aktif** *veya* **1 pasif** (ikisi birden değil) |
| **Off — Wand / Scepter** | 1 veya | 1 veya | **INT off-hand dual** — düz vuruş yok; aktif/pasif/perk **%50** (§7) |
| **Off — Weapon Knot** | — | 1 veya stat | **1 pasif** yetenek *veya* yalnızca **stat boost** |
| **Off — 1H silah** | Main ile aynı kurallar | | Dual wield: off-hand perk/pasif **%50**; **aktif yetenek kullanılabilir** |
| **Helmet** | 0–1 | 0–1 | Genelde **hasar** veya **dayanıklılık** temalı aktif/pasif |
| **Chest** | 0–1 | 0–1 | **Dayanıklılık** (Defence, DR, guard, HP vb.) |
| **Hand** | 0–1 | 0–1 | **Hasar** (crit, dot affix, on-hit proc vb.) |
| **Feet** | 0–1 | 0–1 | **Hız**, dodge, parry, jump, guard mekaniği |

**Kaldırılan kural:** ~~Off-hand aktif yetenek kullanılamaz~~ — artık **kullanılabilir** (loadout derinliği).

### Eşya tasarım ilkesi

- **Tank:** yüksek Defence, düşük Resist — *manuel item tablosu*
- **Büyücü:** düşük Defence, yüksek Resist — *manuel*
- **Stat requirement:** `Requires STR 40` vb.
- *Rarity / tier — TBD*

### Element tag (kilit)

Element **tag** iki katmanda kullanılır:

| Katman | Slotlar | Durum |
|--------|---------|--------|
| **Matchup** | Main Hand → hedef Chest | Kilit — `CHEMISTRY_ENGINE.md` §2 |
| **Sinerji** | **Main Hand + Off Hand + Chest** | Çerçeve + Pure x3 perk kilit — `CHEMISTRY_ENGINE.md` §3 |

**Sinerji özeti:**
- **Main 1H** = 1 · **Main 2H / Bow / Crossbow** = 2 · **Off** (tagli: 1H / Shield / Focus / Wand / Scepter) = 1 · **Knot / Quiver** = 0
- **2H veya Bow/Crossbow + Chest** → sinerji **main (×2) + chest (×1)**; off Knot/Quiver sayılmaz
- **Duality** → +5% Defence · +5% Resist (`CHEMISTRY_ENGINE.md` §3.3)
- Reaksiyonları doğrudan güçlendirmez

**On-hit status:** Hand/silah affix — değişmedi.

---

## 6. Weapons

### Pure scaling (kilit)

| Primary | Silahlar |
|---------|----------|
| **STR** | 1H/2H Sword, Axe, Mace |
| **DEX** | Dagger, Bow, Crossbow |
| **INT** | Wand, Staff, Scepter |

```
Hit Damage = Weapon Base × (1 + ScalingStat × 0.0075) × gear × crit
```

### Attack speed tier

| Tier | Mult | Silahlar |
|------|------|----------|
| S (0.70) | Yavaş | 2H Mace, Crossbow |
| A (0.85) | | 1H Mace, 2H Axe |
| B (1.00) | | 1H Axe, 2H Sword |
| C (1.15) | | 1H Sword, Bow, Staff |
| D (1.30) | | Dagger, Wand |
| E (1.10) | | Scepter |

### Roster & aile perk’leri (kilit)

| Silah | Scale | Perk |
|-------|-------|------|
| Dagger | DEX | **Backstab** — arkadan bonus hasar |
| 1H Sword | STR | **Measured Strike** — her **3. light attack** +**%35** hasar |
| 1H Axe | STR | Rakip **guard/parry** yaparken ekstra **Stamina** damage |
| 1H Mace | STR | **Defence Shred** — Defence’in bir kısmını ignore |
| Wand | INT | +Status Potency |
| Scepter | INT | +Buff Potency; solo damage wand ile staff arası |
| Bow | DEX | +Crit Chance |
| Crossbow | DEX | +Crit Damage; düşük hız, vuruş arası reload **anim** (mekanik değil) |
| 2H Sword | STR | **Measured Strike** — 3. vuruş +**%40** hasar |
| 2H Axe | STR | Anti-guard stamina (artmış) |
| 2H Mace | STR | Defence Shred (yüksek) |
| Staff | INT | +Status Potency++; light attack = **projectile** |
| **Exotic** | *değişken* | **Sabit aile perk’i yok** — tamamen item/yetenek tasarımı |

**Exotic:** Özel mekanikli silahlar (ör. garip cadence, unique active). Aile perk zorunluluğu yok; denge tek tek item.

INT silahları: light attack projectile.

### Measured Strike (Sword ailesi — kilit)

- Sayaç: **hedef başına** ayrı `light attack` zinciri.
- Sayaç sayan vuruşlar: **isabetli** light attack **ve guard'a takılan** vuruşlar (chip dahil).
- **Sayılmaz:** miss / whiff.
- Son sayılan vuruştan sonra **~1s** içinde yeni sayılan vuruş yoksa o hedefteki sayaç **sıfırlanır** (combo kırıldı).
- Her **3. sayılan** vuruş bonus hasar (1H **%35**, 2H **%40** — değerler playtest).
- Cleave değil — tüm melee zaten çoklu hedef vurabilir; sword farkı **hedefe özel combo ritmi**.
- Statü uygulamaz; element on-hit yalnızca item affix ile (§5).

*Rapier vb. standart aileler — ihtiyaç halinde; **Exotic** özel silahlar için.*

---

## 7. Off-hand detayları

> Slot ve yetenek kuralları → **§5**. Bu bölüm combat davranışı.

### Shield

**Guard** = sağ tık. **Parry yok.** Stability stat **yok**.

| Tip | Drain/s | Guard slow | Chip* |
|-----|---------|------------|-------|
| **Buckler** | 0.5 | 10% | blocklanan hasarın **%60**’ı alınır |
| **Kite** | 1.0 | 20% | **%40** |
| **Tower** | 1.5 | 30% | **%30** |

\*Guard sırasında chip + vuruş başına stamina maliyeti. Stamina 0: pasif drain → **Slow 50%** (%10 dolunca kalkar); vuruşla biterse → **Stagger 0.5s**.

İleride farklar affix ile de verilebilir; tip = bu üçlü taban.

### Off-hand dual wield (1H silah — STR/DEX)

| Kural | Değer |
|-------|--------|
| Light attack | Dual anim, **çift vuruş**; on-hit proc ×2 (affix varsa) |
| Pasif / perk | Off-hand **%50** etki |
| Aktif yetenek | **Kullanılabilir** (main + off ayrı CD); hasar / heal / buff gücü **%50** |

*Dual hit damage çarpanı — playtest (×0.65 taslak).*

### Off-hand Wand / Scepter (INT dual)

**1H melee main** + off Wand veya Scepter — fiziksel dual wield’in **INT karşılığı**. Bow, Crossbow, 2H off’unda **takılmaz**.

| Kural | Değer |
|-------|--------|
| **Düz vuruş** | **Yok** (off slotta projectile yok) |
| **Pasif / silah perk** | Off-hand **%50** (+Status Potency, +Buff Potency vb.) |
| **Aktif yetenek** | **Kullanılabilir** (ayrı CD); hasar, DoT, heal, buff, status gücü / süresi **%50** |
| **Scaling** | Yetenekler **INT** ile scale eder; off-hand çarpanı **×0.5** uygulanır |
| Element tag | **Var** — sinerji (×1) |

Main-hand Wand/Staff (2H projectile vb.) ile karıştırma: off-hand item **ayrı slot**; tam güç yalnızca main INT silahında.

*Focus (utility) bu %50 kuralına **girmez** — silah değil.*

### Weapon Knot

**2H STR** ve **Staff** build’de Off Hand slotunda. **1 pasif** veya stat boost (§5).

### Quiver

**Bow** / **Crossbow** off-slot. **Weapon Knot ile aynı çerçeve** — yalnızca ranged için.

| Kural | Değer |
|-------|--------|
| Yetenek | **1 pasif** *veya* yalnızca **stat boost** |
| Element tag | **Yok** (v1) — sinerjiye girmez |
| Sinerji | Main Bow/Crossbow **×2** + Chest **×1** (2H melee ile aynı mantık) |

Shield / 1H / Focus / Wand takılamaz.

### Focus (off-hand utility)

**Yalnızca 1H melee** off-slot. Bow, Crossbow, 2H **takılamaz**. Main-hand **düz vuruş yok** — combat ana silahtan.

| Kural | Değer |
|-------|--------|
| Yetenek | **1 aktif** *veya* **1 pasif** |
| Element tag | **Var** — sinerji (×1) |
| Dual wield | **Değil** — off 1H silah %50 kuralına **girmez** |

#### Ne tür eşyalar?

Focus, **silah ailesi değil** — off-hand’e takılan, fantezisi serbest **utility** parçaları. Ortak özellik: tek güçlü kimlik, tek ana etki (aktif *veya* pasif). Item başına isim ve sayılar serbest; aşağıdaki **tarzlar** tasarım dilini tanımlar.

| Tarz | Aktif / pasif | Oyuncu fantezisi | Tasarım notu |
|------|----------------|------------------|--------------|
| **Tüketilebilir / ritüel** | Aktif | “Kullanınca kendime (veya yakına) güçlü kısa etki” | Tek tuş, kısa anim, **CD** ile sınırlı; doğrudan hasar şart değil — **buff**, heal, cleanse, geçici stat. Buff Potency süreyi uzatır. |
| **Tek hedef kontrol** | Aktif | “Isabet edince rakibin pozisyonunu bozarım” | Çekme, itme, kısa **Slow** / **Root** tek hedefte. Menzil ve CD ile denge; boss bağışıklıkları item tier’da tanımlanır. |
| **Alan kontrol** | Aktif | “Bölgeyi kilitleyip alan sahibi olurum” | Yer hedefli veya fırlatılan **AoE**; çoğunlukla **Root** (hareket 0%, saldırı açık) veya güçlü Slow. PvP’de süre/CD kritik. |
| **Pasif takı / totem** | Pasif | “Sürekli küçük ama build’i tanımlayan bonus” | Flat veya scaling stat (**Status Potency**, Buff Potency, stamina, CD reduction). Harmony / affix ile stack kuralları gear tablosunda. |
| *(genişleme)* | İkisi | Savunma, setup, summon | Barrier, kısa on-hit status (affix ile çakışmamasına dikkat), decoy — v1 sonrası |

Yeni CC → `STATUS_SYSTEM.md` (ör. **Root**: hareket yok, saldırı serbest).

#### Focus vs diğer off eşyalar

| Off | Düz vuruş | Aktif / pasif | Sinerji tag | Rol |
|-----|-----------|---------------|-------------|-----|
| **Shield** | Guard | Var | Var | Savunma |
| **1H silah** | Dual chain | Var (%50 pasif perk) | Var | Hasar |
| **Focus** | Yok | Var | Var | Genel utility — tarzlar yukarıda |
| **Wand / Scepter** | Yok | Var (**%50**) | Var | INT dual — §7 |
| **Knot / Quiver** | Yok | Pasif / stat | Yok | 2H / ranged pasif |

*Wand/Scepter off detay → yukarıdaki **Off-hand Wand / Scepter** bölümü; Focus ayrı.*

---

## 8. Combat Systems

### Stamina

Guard / Parry / Dodge / Sprint havuzu. VIT ana kaynak. Combat regen: guard ve parry stance açıkken **yok**.

Placeholder maliyetler → `COMBAT_STAT_SHEET.md` §12.8.

### Dodge (kilit)

- Yönlü sıçrama + kısa **i-frame**
- Flat stamina cost
- Bitince: dodge yok + **kısa recovery (~0.25s)**
- Stamina bitince ek ceza yok

### Sprint (kilit)

- Basılı tutunca drain, hızlı koşu anim (*silah tipine göre*)
- Stamina bitince sprint kesilir

### Guard (kilit)

- Yalnızca **shield**
- Shield tipine göre drain, slow, chip (§7)
- Açıkken %30 slow **yerine** shield tipi slow değerleri

### Parry (kilit — MVP sonrası implement)

| Loadout | Fail maliyeti |
|---------|----------------|
| 1H + 1H off (STR/DEX) | Max stamina **%50** |
| 2H STR | Max stamina **%75** |
| Shield | Parry **yok** |

- Stance: %20 slow, regen yok, pasif drain yok
- **Perfect parry** → düşman **Stun 1s**
- Fail → maliyet, parry kapanır
- Stance sırasında stamina 0 → sen **Stun 1s**

### Hasar çözüm sırası

1. Crit roll  
2. Raw Damage  
3. **Element matchup** (weapon → target chest; direct / skill burst only)  
4. Defence → DR% → Mace shred  
5. Guard chip + stamina  
6. On-hit status (affix / ability)  
7. Resist vs Potency  

---

## 9. Chemistry & Synergies

> **Status:** `STATUS_SYSTEM.md` · **Reaksiyonlar (10, kilit):** `CHEMISTRY_ENGINE.md` §3

### Global reaksiyon kuralları

- Uygulama **sırası yok** (`Wet+Ignite` = `Ignite+Wet`)
- Reaksiyonda **iki girdi silinir**; süreli çıktı kalır
- **Potency** → süre · **Resist** → süre + hasar

| # | Girdi | Sonuç |
|---|-------|--------|
| R1 | Wet + Ignite | **Vaporize** — burst; Ignite DoT yok |
| R2 | Wet + Shock | **Chain Shock** — menzildeki tüm Wet → Shock |
| R3 | Wet + Windy | **Chilled** — donma |
| R4 | Chilled + Ignite | **Thaw** — Ignite uygulanamaz penceresi |
| R5 | Bleed + Ignite | **Cauterize** — Bleed ×0.75 burst; Ignite → Cauterize DoT (Ignite kalmaz) |
| R6 | Bleed + Poisoned | **Blight** — kalan hasar ×2 DoT |
| R7 | Windy + Slow | **Grounded** — %80 slow |
| R8 | Wet + Poisoned | **Contamination** — menzildeki Wet → Poisoned |
| R9 | Windy + Ignite | **Wild Fire** — Ignite DoT ×1.5, AoE tick (çevre: hasar only) |
| R10 | Ignite + Poisoned | **Caustic Burn** — kalan hasar ×2 DoT; süre = **kısa** kalan |

*Eski Wet hub tablosu kaldırıldı — yukarıdaki liste geçerli.*

### Status & Potency (kilit)

- **Status Potency:** debuff / setup / CC / DoT **süresini** uzatır
- **Resist:** **süre** ve **hasar** (DoT, burst, reaksiyon) azaltır
- **DoT DPS tabanı:** eşya affix — Potency DPS'e girmez
- **Temel süre / DPS / menzil:** `STATUS_SYSTEM.md` §4

### Katman 2 — Sinerjiler (çerçeve kilit)

Tam spec → **`CHEMISTRY_ENGINE.md` §3**.

| Kombinasyon | Yön |
|-------------|-----|
| **Pure x3** (3× aynı element) | Main-hand düz vuruş on-hit + element perk — §3.5 |
| **Harmony** (x1+x1+x1, 1H) | +15 flat Status Potency |
| **Unbound** (Pure Neutral) | +5% direct · +10% Defence · +12% Resist — §3.7 |
| **Duality** (x2+x1) | Agirlik 2+1 · **+5% Defence · +5% Resist** — `CHEMISTRY_ENGINE.md` §3.3 |

**Water (pure x3):** silahlar kilitli → ikinci element **Hand / Helmet** (veya takım).

Reaksiyonları **doğrudan güçlendirmez**.

---

## 10. Equipment & Progression

### Kilit ilkeler

- Defence / Resist **manuel** item tasarımı
- Stat requirement ile erken birikim engeli
- *Loot kaynağı, craft, drop tablosu — TBD*
- *Level cap, XP eğrisi — TBD*
- *Inventory, stash — TBD*
- *Monetization — TBD (kozmetik odaklı hedef)*

---

## 11. PvE — Boss Design

### Hedef yapı (kilit yön)

- **Tek boss**, **phase**’ler (farklı mekanikler)
- **Wave**’ler (bazı boss’larda)
- 1v1 / 2v2 / 3v3 co-op

### Tasarım notları

- Phase geçişinde element pivot (Fire immune → Water build vb.)
- Mace shred / axe guard break tank rollere anlamlı
- *Boss roster, HP scale, enrage — TBD*

---

## 12. PvP & Teams

### Format

| | MVP | Hedef |
|--|-----|--------|
| 1v1 | ✅ | ✅ |
| 2v2 | — | ✅ |
| 3v3 | — | ✅ |

### Rol çeşitliliği (class olmadan)

| Rol | Loadout örneği |
|-----|----------------|
| Front / guard | Sword + Kite/Tower |
| Anti-tank | Axe, Mace |
| Setup | Water / Wet on gear, staff |
| Burst | Shock, Poison spread |
| Ranged | Bow, Crossbow |

*Round win, tiebreak, ranked — TBD.*

---

## 13. UI / UX

### Stat gösterimi (kilit)

| Stat | Ana satır | Tooltip |
|------|-----------|---------|
| **Defence** | Sayı (`Defence: 340`) | DR% (`Damage Reduction: 34%`) |
| **Resist** | Sayı (`Resist: 120`) | Etki % (`Effect Reduction: 42%`) |

### Combat okunaklılığı

- Aktif statü ikonları hedef üstünde (*CannonClash StatusIconService benzeri*)
- Reaksiyon VFX (Steam, Chain, Freeze, Spread)
- Guard stamina bar görünür; chip / guard break farklı feedback (*detay TBD*)

### Tema

Low poly, flat UI hedefi. *Asset pipeline — TBD.*

---

## 14. MVP Scope

**Amaç:** “Stat + silah + guard/dodge + kimya çalışıyor mu?” — kod öncesi GDD tamamlandıktan sonra implement.

### MVP’de

| Sistem | Kapsam |
|--------|--------|
| Lobby | Basit queue → 1v1 |
| Stats | 4 primary + sheet `k` v1 |
| Silahlar | 1H Sword, 1H Axe, Staff, Bow |
| Off-hand | **Kite Shield** (tek tip) |
| Combat | Light attack, dodge + recovery, guard |
| Kimya | 10 reaksiyon + status katalog |
| Ekipman | Birkaç manuel tier-1 item |
| UI | Defence / Resist tooltip kuralı |

### MVP sonrası (tasarım hazır)

Parry, dual wield, 3 shield tipi, Knot, Focus, kalan silahlar, 2v2/3v3, tam boss phase, sinerji setleri.

---

## 15. Glossary

| Terim | Tanım |
|-------|--------|
| **Primary stat** | STR, DEX, VIT, INT — level point ile artar |
| **Secondary stat** | Combat’ta okunan türetilmiş değerler (Damage, DR, vb.) |
| **Pure scaling** | Silah yalnızca bir primary’den Damage alır |
| **Damage** | Tek hasar hattı; light attack + yetenek patlaması |
| **Defence** | Ham stat; 1 point = 0.1% DR (cap’e kadar) |
| **DR%** | Damage Reduction; tooltip’te gösterilir |
| **Resist** | DoT ve CC sürelerini azaltan stat |
| **Status Potency** | Kendi uyguladığın statüleri güçlendirir |
| **Buff Potency** | Heal ve buff gücü / süresi |
| **Chip** | Guard sırasında yine de alınan hasar payı |
| **Defence Shred** | Mace perk — hedef DR%’nin bir kısmını ignore |
| **Wet hub** | Wet + X reaksiyonlarının merkezi etiket |
| **Sinerji** | Main + Off + Chest ağırlık — `CHEMISTRY_ENGINE.md` §3 |
| **Weapon Knot** | 2H STR / Staff off; pasif/stat; tagsiz |
| **Quiver** | Bow / Crossbow off; pasif/stat; tagsiz; main sinerji **×2** |
| **Focus** | 1H melee off; utility tarzları §7; 1 aktif veya 1 pasif |
| **Wand / Scepter (off)** | INT dual; düz vuruş yok; aktif/pasif/perk **%50** |
| **TTK** | Time to kill; orta, skill ile uzar |

---

## 16. Open Questions (Backlog)

*Açık kalan her şey burada kalır; GDD gövdesi kilitlendikçe buraya sadece yeni sorular eklenir.*

### Ürün & world

- [ ] Oyun adı
- [ ] Lore / setting
- [ ] Açık dünya scope ve timeline

### Combat & gear

- [x] Focus — tarz çerçevesi (§7)
- [x] Wand/Scepter off — INT dual; %50 aktif/pasif/perk
- [x] Bow / Crossbow off-slot → **Quiver** (§7)
- [ ] Dual wield per-hit damage çarpanı (final)
- [x] Element matchup — Silah→Chest, direct+burst only (`CHEMISTRY_ENGINE.md` §2)
- [ ] Yetenek crit alır mı?
- [ ] Guard hasar pipeline (DR önce mi chip önce mi — final sıra)

### Sinerji & kimya

- [x] Reaksiyon matrisi v1 (10 reaksiyon) → `CHEMISTRY_ENGINE.md`
- [x] Sinerji çerçevesi (main+off+chest) → `CHEMISTRY_ENGINE.md` §3
- [x] Pure x3 perk listesi → `CHEMISTRY_ENGINE.md` §3.5
- [x] Harmony (x1+x1+x1) → §3.6
- [x] Unbound (Pure Neutral) → §3.7
- [x] Duality (x2+x1) → `CHEMISTRY_ENGINE.md` §3.3
- [ ] Yeni reaksiyonlar (CHEMISTRY_ENGINE §7 brainstorm)

### Progression & live

- [ ] XP, loot, craft, economy
- [ ] Monetization (kozmetik / pass — TBD)
- [ ] Tutorial akışı
- [ ] Ranked / casual ayrımı

### Tech & production

- [ ] Roblox repo / place yapısı
- [ ] Animasyon scope (dual wield, sprint per weapon)
- [ ] Netcode / hit detection modeli

---

## Belge geçmişi

| Tarih | Not |
|-------|-----|
| 2026-07 | İlk GDD — tasarım sohbeti kilitleri; kod yok |

**Teknik detay:** Sayısal combat → `COMBAT_STAT_SHEET.md` | Kimya modülü → `CHEMISTRY_ENGINE.md`
