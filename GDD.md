# Game Design Document

| | |
|--|--|
| **Çalışma adı** | TBD |
| **Tema** | Low poly |
| **Kamera** | Third-person action |
| **Platform** | Roblox (hedef) |
| **Oyuncu dili** | **English** (UI, item names, abilities — oyun içi tamamen EN) |
| **Tasarım dili** | Türkçe (bu GDD / chat — geliştirme) |
| **Durum** | Tasarım + lobby/inventory kod iskeleti |
| **İlişkili belgeler** | `COMBAT_STAT_SHEET.md`, `CHEMISTRY_ENGINE.md`, `MODES.md` |

> CannonClash ile **bağımsız** proje. Kimya motoru konsept olarak taşınabilir; lane / cannon / birim meta bu GDD kapsamında değildir.
>
> **Dil:** Tasarımı Türkçe konuşuruz; oyuncuya giden her metin **İngilizce** (`ItemDefs` isimleri, UI, yetenek adları).

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
11. [PvE — Boss & Dungeon](#11-pve--boss--dungeon)
12. [PvP & Teams](#12-pvp--teams)
13. [UI / UX](#13-ui--ux)
14. [Playtest Slice (son faz)](#14-playtest-slice-son-faz--ertelendi)
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
| **Skill expression** | Orta TTK; guard / dodge / parry ile iyi oyuncu maçı uzatır |
| **Fair scaling** | Defence ekipmandan; agresif stat eğrisi yok (1 Def = 0.1% DR) |
| **Low poly clarity** | Okunaklı silüet, statü ikonları, net VFX |

### Hedef his

- **Ortalama oyuncu:** loadout dene, kimya keşfet, orta süreli düellolar.
- **İyi oyuncu:** stamina oyunu, pozisyon, element combo — ödül = daha az yenen vuruş.
- **Takım:** 2v2 / 3v3'te setup + burst, front line (`MODES.md` §3)

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
| **Result** | Ödül, loot, ranked MMR (PvP), boss drop (PvE) — *detay TBD* |
| **Meta** | *TBD — yeni eşya, level, craft* |

Ödül ve uzun vadeli progression **açık** — combat çekirdeği önce kilitlendi.

---

## 3. Lobby & Modes

> Tam spec: **`MODES.md`** (arena bracket'leri, ranked, PvE fazları, üretim sırası)

### Lobby

- Loadout ekranı (slotlar §5) · stat dağıtımı
- Mod seçimi: **PvP** (1v1 / 2v2 / 3v3 × Casual / Ranked) · **PvE Boss** (solo / duo / trio)
- Matchmaking / party invite
- *Mağaza / kozmetik — TBD* · *Tutorial — TBD*

### Mod özeti (kilit yön)

| Ana mod | İçerik | Durum |
|---------|--------|--------|
| **PvP — 1v1 Arena** | Duel Pit · Casual + **Ranked** | Hedef |
| **PvP — 2v2 Arena** | Skirmish Yard · Casual + **Ranked** | Hedef |
| **PvP — 3v3 Arena** | Clash Ring · Casual + **Ranked** | Hedef |
| **PvE — Boss Fight** | Phase boss · 1 / 2 / 3 co-op | **İlk PvE içeriği** |
| **PvE — Dungeon** | Odalar + trash + boss | **İleride** (`MODES.md` §5) |
| **Açık dünya** | — | İleride opsiyon |

Her PvP bracket'in **kendi ranked ladder'ı** vardır (MMR birbirinden bağımsız).

### Maç akışı (özet)

1. Mod + queue seç → loadout kilidi
2. Arena veya boss odası
3. Countdown → combat
4. Win: PvP → karşı takım/oyuncu elenir (`MODES.md` §3.5) · PvE → boss HP 0
5. Sonuç → lobby (ranked: MMR güncelle)

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
| **VIT** | HP, Stamina, az Defence, az Resist |
| **INT** | INT silah hasarı, Status Potency, az Buff Potency (herkeste) |

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

- **Orta TTK:** ~**10–12** isabet (orta gear, 3–4 full combo) — iyi oyuncu dodge/guard ile uzatır
- **İyi vs iyi:** 25–40+ sn (dodge / guard / parry)
- Knob’lar: `base_hp 120`, `k_dmg 0.012`, DR cap %70 PvP — tek kaynak: `COMBAT_STAT_SHEET.md` §12

### Hasar hattı (özet)

Tek **Damage** statı. **Matchup** (±15%): silah element → chest element; yalnızca direct + skill burst (`CHEMISTRY_ENGINE.md`). DoT / reaksiyon ayrı kanal → Potency + Resist.

---

## 5. Loadout & Equipment Slots (kilit)

### Slotlar

```
        [ Head ]
[ Main Hand ]  [ Off Hand ]
        [ Chest ]
[ Hand ]       [ Feets ]
```

| Slot (UI) | Kod adı | İçerik |
|-----------|---------|--------|
| **Main Hand** | `main` | **1H** veya **2H** silah |
| **Off Hand** | `off` | **1H silah**, **Shield**, **Quiver**, **Weapon Knot**, **Focus**, **Wand/Scepter** |
| **Head** | `head` | Kafa zırhı / baş ekipmanı |
| **Chest** | `chest` | Göğüs zırhı |
| **Hand** | `hands` | Eldiven |
| **Feets** | `feets` | Bot |

**2H melee:** Main = 2H silah · Off = **Weapon Knot** (tagsiz v1).  
**Ranged:** Main = **Bow** veya **Crossbow** (sinerjide **×2** — 2H ile aynı) · Off = **Quiver** (tagsiz; Knot gibi pasif/stat).  
**1H melee:** Main = 1H · Off = Shield / 1H (dual) / **Focus** / Wand-Scepter.

### Yetenek slotları (kilit)

Her eşya **en fazla** aşağıdaki tavanlara uyar. Boss / exclusive drop’larda A+P birlikte olabilir; **aktif sayısı tavanı asla aşılmaz**.

| Kaynak | Max Active | Max Passive | Toplam yetenek slotu | Not |
|--------|------------|------------|----------------------|-----|
| **1H silah** (main veya off) | **1** | **1** | **1 veya 2** | **2 Active asla yok.** Normal loot sıkça yalnız 1A *veya* yalnız 1P; boss drop’ta **1A+1P** olabilir |
| **2H / Staff / Bow / Crossbow** | **2** | **2** | **2** (normal) | Dağılım: 2A · 2P · 1A+1P. **3 Active asla yok.** *Nadir / boss:* **2A+1P** (3 slot) olabilir — elde edilmesi zor |
| **Off — Quiver / Knot** | 0 | 1 veya stat | 1 | Tagsiz |
| **Off — Shield / Focus** | 1 | 1 | **1** (A *veya* P, ikisi birden değil) |
| **Head / Chest / Hand / Feets** | 0–1 | 0–1 | 0–2 | |

**Hotbar (kilit):** Loadout’taki **Active** sayısı **0–6** (Q E R 1 2 3).  
- **Max 6** Active — tavan.  
- **Min 0** Active — zorunlu yetenek yok; tamamen pasif + light attack build geçerli.  
Item / loot tablosu 6 Active’i aşacak kombinasyon üretmez.

**Nadir silah (boss / exclusive):** Normal loot tavanının üstünde A+P kombinasyonu olabilir (ör. 1H **1 Active + 1 Passive**, 2H **2 Active + 1 Passive**). Hâlâ: 1H’de max **1** Active · 2H’de max **2** Active · loadout toplam Active ≤ **6**.

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
- **Main 1H** = 1 · **Main 2H / Staff / Bow / Crossbow** = 2 · **Off** (tagli: 1H / Shield / Focus / Wand / Scepter) = 1 · **Knot / Quiver** = 0
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
Hit Damage = Weapon Base × (1 + ScalingStat × 0.012) × gear × crit
```

### Attack speed tier

| Tier | Mult | Silahlar |
|------|------|----------|
| S (0.70) | Yavaş | 2H Mace, Crossbow |
| A (0.85) | | 1H Mace, 2H Axe |
| B (1.00) | | 1H Axe, 2H Sword, **Staff** |
| C (1.15) | | 1H Sword, Bow |
| D (1.30) | | Dagger, Wand |
| E (1.10) | | Scepter |

### Roster & aile perk’leri (kilit)

| Silah | Scale | Perk | Light attack |
|-------|-------|------|--------------|
| Dagger | DEX | **Backstab** — arkadan bonus hasar | 3 vuruş combo |
| 1H Sword | STR | **Measured Strike** — L3 **×1.35** (kılıç ailesi) | 3 vuruş combo |
| 1H Axe | STR | Rakip **guard/parry** yaparken ekstra **Stamina** damage | 3 vuruş combo |
| 1H Mace | STR | **Defence Shred** | 3 vuruş combo |
| **Wand** | INT | +Status Potency | **1H** projectile combo; **kısa menzil** |
| **Scepter** | INT | +Buff Potency | **1H** **cone** combo; wand'dan **daha kısa menzil**, **daha düşük hasar** |
| Bow | DEX | +Crit Chance | 3 vuruş combo |
| Crossbow | DEX | +Crit Damage; **L3 sonrası reload anim** | 3 vuruş combo |
| 2H Sword | STR | **Measured Strike** — L3 **×1.40** | 3 vuruş combo |
| 2H Axe | STR | Anti-guard stamina (artmış) | 3 vuruş combo |
| 2H Mace | STR | Defence Shred (yüksek) | 3 vuruş combo |
| **Staff** | INT | +Status Potency++; **2H** projectile | **Uzun menzil**, **yüksek hasar** combo |
| **Exotic** | *değişken* | **Sabit aile perk’i yok** | Item tasarımına göre |

**Exotic:** Özel mekanikli silahlar. Aile perk zorunluluğu yok.

### INT silah profilleri (main-hand — kilit)

| Silah | El | Base (tier 1) | Menzil | LA tipi |
|-------|-----|---------------|--------|---------|
| **Wand** | 1H | 28–32 | ~**22** stud | Tek projectile |
| **Staff** | 2H | 44–48 | ~**30** stud | Tek projectile |
| **Scepter** | 1H | 26–30 | ~**16** stud | **Cone ~45°** · max **3** hedef · on-hit hedef başına 1× |

Sinerji: Staff main **×2**; Wand / Scepter main **×1**. **Harmony** yalnızca Main **×1** (1H) + Off ×1 + Chest ×1 — tüm **×2 main** (2H / Staff / Bow / Crossbow) ile kurulamaz.

### Measured Strike (yalnızca kılıç ailesi — kilit)

- **L3 aile perk'i** — global combo bonuslarına **ek** çarpan (1H **×1.35**, 2H **×1.40**).
- Sayaç: silah başına **global** combo zinciri (§8 / `COMBAT_STAT_SHEET.md` §11.6); **hedef başına değil**.
- İlerletir: isabetli LA **ve** guard block (chip); miss sayılmaz.
- Combo window **0.6s** kaçırılırsa L1'e döner.
- Statü uygulamaz; element on-hit yalnızca item affix ile (§5).

---

## 7. Off-hand detayları

> Slot ve yetenek kuralları → **§5**. Bu bölüm combat davranışı.

### Shield

**Guard** = sağ tık (yalnızca Shield). Shield'da **Parry yok**. Stability stat **yok**.

| Tip | Drain/s | Guard slow | Chip* |
|-----|---------|------------|-------|
| **Buckler** | 0.5 | 10% | blocklanan hasarın **%60**’ı alınır |
| **Kite** | 1.0 | 20% | **%40** |
| **Tower** | 1.5 | 30% | **%30** |

\*Guard sırasında chip + vuruş başına stamina maliyeti. Guard break → §8.

İleride farklar affix ile de verilebilir; tip = bu üçlü taban.

### Off-hand dual wield (1H silah — STR/DEX)

| Kural | Değer |
|-------|--------|
| Light attack | Dual anim, **çift vuruş**; on-hit: main tam · off **%50** proc (`COMBAT_STAT_SHEET.md` §11b) |
| Pasif / perk | Off-hand **%50** etki |
| Aktif yetenek | **Kullanılabilir** (main + off ayrı CD); hasar / heal / buff gücü **%50** |

*Dual hit damage çarpanı — kilit:* Main **×1.0** · Off **×0.65** (`COMBAT_STAT_SHEET.md` §11b).

**Denge hedefi:** Dual wield DPS **≈ 2H** (±1 isabet); **1H + Shield / Focus**'tan belirgin şekilde yüksek burst. Çift vuruş anim **~×1.25** süre. On-hit: main tam · off **%50** proc.

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

Yeni CC → `STATUS_SYSTEM.md` (ör. **Root**, **Knockback**).

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

### Stamina (kilit)

**Yalnızca hareket + koruma:** Dodge · Sprint · Guard (drain / vuruş maliyeti) · Parry fail / stance cezaları.

| Harcar | Harcamaz |
|--------|----------|
| Dodge, Sprint, Guard, Parry (fail / 0 stam cezası) | **Aktif yetenekler**, light attack, heal/buff yetenekleri |

Yetenekler **CD** ile sınırlanır; stamina **yok**. VIT ana kaynak. Combat regen: guard ve parry stance açıkken **yok**.

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

- Yalnızca **shield**; ön **180°** yayı (`COMBAT_STAT_SHEET.md` §11.4)
- Shield tipine göre drain, slow, chip
- Chip ve stamina maliyeti **`after_dr`** üzerinden (matchup + DR sonrası)
- **Guard block:** tam vuruş bloklanır; HP'ye yalnızca chip; **on-hit affix uygulanmaz**

#### Guard break (kilit)

| Tetik | Sonuç |
|-------|--------|
| Pasif drain → stamina **0** | Guard kapanır · **Slow 50%** · süre: **3s** *veya* stamina ≥ **%10** max (hangisi önce) |
| Vuruş → stamina **0** | Guard kapanır · **Stun 0.75s** — ekstra hasar debuff **yok** |

#### Guard break vs Parry (kilit)

| | **Guard break** (kalkan) | **Perfect parry** (1H/2H, kalkan yok) |
|--|--------------------------|----------------------------------------|
| Tetik | Guard açıkken stamina **0** (vuruş) | Parry penceresinde isabet |
| Savunan | **Stun 0.75s** | Hasar **0**; saldıran **Stun 1s** |
| Ek ceza | **Yok** (+incoming% kaldırıldı) | Fail parry → stamina maliyeti; **+incoming% yok** |
| On-hit affix | Guard block'ta zaten yok | Perfect: on-hit **yok** |

Parry, guard break'in tersi bir **aktif savunma ödülü** — ceza debuff'u değil, saldıranı cezalandırır.

### Light attack & 3 vuruşluk combo (MVP — kilit v3)

**Tüm silahlar:** L1 → L2 → **L3 (finisher)** · combo window **0.6s** · kaçırırsan L1.

**Global bonus (direct):** L1 ×1.00 · L2 ×**1.05** · L3 ×**1.10** + hit-stop / camera shake.

**Hareket (combo):** L1 **%90** MS · L2 **%75** · L3 windup **%50** + anim root motion step (ekstra velocity yok).

**Aile L3 örnekleri:**
- **Bow:** geriye sıçrama + havada düz atış · **Focused Shot** ×1.25
- **Staff (2H):** güçlü bolt · **Empowered Bolt** ×1.30
- **Wand (1H):** hızlı bolt · **Arc Bolt** ×1.20 · kısa menzil
- **Scepter (1H):** cone sweep · **Radiant Sweep** ×1.25 · max 3 hedef · on-hit hedef başına 1×
- **Crossbow:** **Heavy Bolt** ×1.40 → zorunlu **reload ~1.2s** (yalnız L3 sonrası)
- **Kılıç:** **Measured Strike** ×1.35 / ×1.40 (global L3'e ek)

Tam tablo → `COMBAT_STAT_SHEET.md` §11.6.

- Sayaç: isabet **veya** guard block ilerletir; miss hayır
- Hit recovery: `0.15 / AttackSpeedMult` (`COMBAT_STAT_SHEET.md` §11.6)
- Poise / hyperarmor MVP'de yok

### Healing (MVP — kilit)

| Kural | Değer |
|-------|--------|
| Combat HP regen | **Yok** |
| Lobby / maç arası | **Full HP + stamina** restore |
| Yetenek heal | `base_heal × (1 + Buff_Potency × k_buff_heal)` — overheal yok |
| MVP kaynak | Staff aktif yeteneği (`MVP_CONTENT.md`) |

### Parry (kilit — alpha)

| Loadout | Fail maliyeti |
|---------|----------------|
| 1H band (1H, dual, focus, wand…) | Max stamina **%50** |
| 2H band (2H / Staff / Bow / Crossbow) | Max stamina **%75** |
| Shield | Parry **yok** (Guard) |

- Stance: %20 slow, regen yok, pasif drain yok
- **Perfect parry** → düşman **Stun 1s**; hasar 0; on-hit yok
- Fail → maliyet, parry kapanır; hasar normal akar
- Stance sırasında stamina 0 → sen **Stun 1s**

### Hasar çözüm sırası

Tam pipeline → **`COMBAT_STAT_SHEET.md` §11** (kilit v1).

Özet: Crit → Raw → Perks (ComboStep L2/L3 + FamilyPerk L3 / Backstab / DirectBonus) → Matchup → DR → Dodge/Parry/Guard → HP/chip → On-hit (guard block’ta yok) → Reaksiyon (batch-frame, FIFO).

---

## 9. Chemistry & Synergies

> **Status:** `STATUS_SYSTEM.md` · **Reaksiyonlar (10, kilit):** `CHEMISTRY_ENGINE.md` §3

### Global reaksiyon kuralları

- Status hedefe **yazılır**; aynı sunucu tick'inin **sonunda** batch çözülür (`CHEMISTRY_ENGINE.md` §5.4) — `ApplyStatus` anında reaksiyon yok
- İki girdi **silinir**; reaksiyonun süreli çıktısı varsa **o** kalır (Vaporize gibi anlık burst'lerde kalıntı yok)
- Öncelik tablosu **yok** — aynı tick çakışmasında **FIFO** (`ApplyStatus` sırası)
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
| **Harmony** (x1+x1+x1) | +15 flat Status Potency — yalnızca Main **×1**; tüm **×2 main** (2H / Staff / Bow / Crossbow) **dışarıda** |
| **Unbound** (Pure Neutral) | +5% direct · +10% Defence · +12% Resist — §3.7 |
| **Duality** (x2+x1) | Agirlik 2+1 · **+5% Defence · +5% Resist** — `CHEMISTRY_ENGINE.md` §3.3 |

**Water (pure x3):** silahlar kilitli → ikinci element **Hand / Head** (veya takım).

Reaksiyonları **doğrudan güçlendirmez**.

---

## 10. Equipment & Progression

### Kilit ilkeler

- Defence / Resist **manuel** item tasarımı
- Stat requirement ile erken birikim engeli
- **Trade sistemi** — oyuncular arası eşya takası (**kilit yön**)
- **Craft yok** (v1) — ileride değerlendirilmez; özelleştirme **+ basma / rün** ile
- İçerik roster (silah × element, zırh setleri, Focus, off-hand) → **en son** tasarlanacak (`§14`)

### XP (kilit yön)

| Kaynak | XP |
|--------|-----|
| **PvP** | Maç sonucu (win > loss; ranked bonus *TBD*) |
| **PvE Boss** | Boss kill + phase bonus (*miktar TBD*) |
| **Level cap / eğri** | *TBD* — playtest |

### Loot (kilit yön)

#### PvP

| Öğe | Kural |
|-----|--------|
| **Gacha Box** | **Win** sonrası **şansla** düşer (her win garanti değil) |
| Kutu içi | Rastgele ekipman / malzeme havuzu |
| Kaynak | Casual + Ranked |

#### PvE Boss

| Öğe | Kural |
|-----|--------|
| **Gacha Box** | Boss kill sonrası şansla (PvP ile benzer kutu tipi veya PvE kutusu *TBD*) |
| **Boss-exclusive** | Yalnızca **ilgili boss**tan düşer; Gacha Box'tan **çıkmaz** |
| Rarity | Exclusive drop'lar genelde **yüksek rarity** |
| Farm | Tekrarlanabilir; düşük şans |

```
PvP win ──şans──▶ Gacha Box ──▶ random item

PvE kill ──şans──▶ Gacha Box
         └──şans──▶ Boss-exclusive item (bu boss only, yüksek rarity)
```

### Rarity

- Tier sistemi eklenecek (*Common → … → Legendary* — tablo **TBD**)
- Boss-exclusive ve yüksek + seviyeleri **nadir** tutulur

### + Basma & özelleştirme (kilit yön — craft değil)

Ekipmanı güçlendirme; **uzun vadeli grind** hedefi.

| Kural | Değer |
|-------|--------|
| **Ana stat** | + basıldıkça yalnızca ana stat artar — silah: **Damage**; zırh: **Defence / Resist** |
| **Affix / perk** | + ile **büyümez** (aktif, pasif, on-hit sabit) |
| **Socket** | Belirli + basma yöntemlerinde **şansla** itema socket açılır |
| **Rün** | Socket'e takılır — hafif stat boost veya küçük mekanik |
| **Bonus affix** | Bazı + yöntemlerinde rastgele **prefix** affix eklenebilir |
| Zorluk | Başarı oranı / maliyet **düşük** — uzun süreli oyun gerekir |

*Malzeme adları, + cap, başarı % — içerik fazında (`F2`).*

### Trade

- Oyuncular eşya takası yapabilir
- Boss-exclusive ve yüksek + itemlar ekonominin değerli katmanı
- Exploit önleme (alt hesap, RMT) — *kurallar TBD*

### Monetization (çerçeve + adaylar)

**Prensip:** Pay-to-win **yok** — stat satışı olmaz. Ranked ödülleri de kozmetik.

| Aday | Uygunluk |
|------|----------|
| **Kozmetik** (skin, VFX, intro, kill banner) | ✅ Ana gelir kanalı |
| **Battle Pass** (sezon, kozmetik track) | ✅ Ranked sezonu ile uyumlu |
| **Gacha Box satışı** | ⚠️ Yalnızca kozmetik kutu veya trade-bound malzeme; **stat kutusu satılmaz** |
| **+ malzemesi** | ⚠️ Satılabilir ama pay-to-win riski — fiyat/limit sıkı veya sadece farm |
| **Stash / karakter slotu** | ✅ QoL |
| **Title / rozet** | ✅ Kozmetik; ranked zaten veriyor |

*Detaylı fiyatlandırma ve Roblox policy uyumu — ileride.*

### Inventory

- Stash, loadout, trade envanteri — *UI spec TBD*

---

## 11. PvE — Boss & Dungeon

> Boss spec + queue: **`MODES.md` §4** · Dungeon yol haritası: **`MODES.md` §5**

### Faz 1 — Boss Fight (ilk PvE — kilit yön)

- **Yalnızca boss encounter** — dungeon yok
- **1 / 2 / 3** oyuncu co-op queue
- Tek boss, **phase**'ler; bazı boss'larda önce **wave**
- Win: boss HP → 0 · Lose: party wipe
- Phase geçişinde element pivot (Fire immune → Water build vb.)
- Mace shred / axe guard break tank rollere anlamlı
- Boss roster, HP scale, enrage → `MODES.md` §4.4 · ilk boss **The Eye** → `§4.6`

### Faz 2 — Dungeon (ileride)

- Bağlı odalar, trash mob, run sonu boss
- Aynı party boyutu (1–3), aynı combat sistemi
- Detay: `MODES.md` §5

---


## 12. PvP & Teams

> Arena bracket'leri, ranked, win condition: **`MODES.md` §3**

### Bracket'ler (kilit)

| Bracket | Arena | Casual | Ranked |
|---------|-------|--------|--------|
| **1v1** | Duel Pit | ✅ | ✅ |
| **2v2** | Skirmish Yard | ✅ | ✅ |
| **3v3** | Clash Ring | ✅ | ✅ |

Ranked: bracket başına **ayrı MMR** — 1v1 rating'i 3v3'ü etkilemez.

### Win condition

`MODES.md` §3.5 — elimination, respawn yok. **180s** sonra gaz (20s shrink + ~30s DPS, max **230s**); ilk ölen kaybeder.

### Takım rol çeşitliliği (class olmadan)

| Rol | Loadout örneği |
|-----|----------------|
| Front / guard | Sword + Kite/Tower |
| Anti-tank | Axe, Mace |
| Setup | Water / Wet on gear, staff |
| Burst | Shock, Poison spread |
| Ranged | Bow, Crossbow |

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

### Hotbar & yetenek bağlama (kilit)

**Pasifler hotbar’a girmez** — loadout’ta takılıysa otomatik aktiftir.

**Aktifler:** Loadout tamamlanınca (veya değişince) Loadout UI altındaki **yetenek havuzunda** listelenir:

```
[ikon]  Yetenek Adı
        kısa description
```

Oyuncu ikonu **basılı tutup** hotbar slot’una **sürükler** (drag-drop). Aynı yetenek birden fazla slota bağlanamaz; slot değiştirmek = sürükle veya slot’tan kaldır.

| Hotbar slot | Tuş |
|-------------|-----|
| 1 | **Q** |
| 2 | **E** |
| 3 | **R** |
| 4 | **1** |
| 5 | **2** |
| 6 | **3** |

**Neden 6?** Loadout’tan teorik max aktif = **6**. **Min = 0** — hotbar boş / hiç Active yokken yalnızca LA + pasiflerle oynanabilir.

| Kural | Değer |
|-------|--------|
| Active sayısı | **0–6** (min yok, max 6) |
| Boş slot | Tuş basınca no-op |
| CD | Slot ikonunda overlay |
| Bind kaydı | Karakter / loadout ile kalıcı (*DataStore — sonra*) |
| Combat | Hotbar’daki aktifler + pasifler (otomatik); Active zorunlu değil |

---

## 14. Playtest Slice (son faz — ertelendi)

**MVP en son** yapılacak. Önce F1–F4 (`MODES.md` §1): mekanikler → içerik → modlar → meta.

Playtest slice = tüm sistemler bir arada dış test. Şablon: `MVP_CONTENT.md` (tam test seti + checklist).

| Öncelik | Ne |
|---------|-----|
| Şimdi | Mekanik + içerik + mod tasarımı |
| Sonra | Kod: combat → boss → 3 PvP bracket + ranked |
| En son | Playtest slice, denge pass, soft launch |

*Eski “yalnızca 1v1 MVP” kapsamı kaldırıldı — hedef ürün modları `MODES.md`.*

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
| **Thorn** | Chest takılıyken süresiz self status — Direct reflect (chip yok, zincir yok) |
| **Chip** | Guard sırasında yine de alınan hasar payı |
| **Defence Shred** | Mace perk — hedef DR%’nin bir kısmını ignore |
| **Wet hub** | Wet + X reaksiyonlarının merkezi etiket |
| **Sinerji** | Main + Off + Chest ağırlık — `CHEMISTRY_ENGINE.md` §3 |
| **Weapon Knot** | 2H STR / Staff off; pasif/stat; tagsiz |
| **Quiver** | Bow / Crossbow off; pasif/stat; tagsiz; main sinerji **×2** |
| **Focus** | 1H melee off; utility tarzları §7; 1 aktif veya 1 pasif |
| **Wand / Scepter (off)** | INT dual; düz vuruş yok; aktif/pasif/perk **%50** |
| **Ranked** | Bracket başına ayrı MMR + sezon kozmetik/title — `MODES.md` §3.6 |
| **Gacha Box** | PvP/PvE loot kutusu; şansla düşer |
| **Boss-exclusive** | Yalnızca ilgili boss drop; Gacha'da yok |
| **+ Basma** | Ekipman güçlendirme; ana stat + socket/rün |
| **Trade** | Oyuncular arası eşya takası |
| **Boss Fight** | İlk PvE; phase boss, 1–3 co-op; ilk boss: **The Eye** |
| **Dungeon** | İleride PvE; odalar + trash + boss |
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
- [x] Dual wield per-hit damage çarpanı → Main ×1.0 · Off ×0.65; on-hit off **%50** proc (`COMBAT_STAT_SHEET.md` §11b)
- [x] TTK / `k_dmg` → **10–12** isabet · `k_dmg 0.012` (`COMBAT_STAT_SHEET.md` §12)
- [x] Reaksiyon çözümü → tick sonu batch + FIFO (`CHEMISTRY_ENGINE.md` §5.4)
- [x] Staff AS tier → **B (1.00)** · Crossbow L3 ×1.40 / reload 1.2s · Axe guard stamina ×1.25
- [x] Element matchup — Silah→Chest, direct+burst only (`CHEMISTRY_ENGINE.md` §2)
- [x] Yetenek crit → direct burst evet, DoT/heal/reaksiyon hayır (`COMBAT_STAT_SHEET.md` §11.2)
- [x] Guard hasar pipeline → `after_dr` chip + stance sırası (`COMBAT_STAT_SHEET.md` §11)
- [x] Direct bonus pipeline (Unbound, Rock Pure) → `COMBAT_STAT_SHEET` §11.8
- [x] Yetenek hasarı = WeaponBase × ability_pct → §11.7
- [x] Guard block on-hit yok → §11.4
- [x] CC diminishing (aynı kaynak) → `STATUS_SYSTEM` §3.1d
- [x] Environmental + Execute hasar türleri → §11.9–11.10
- [ ] `AbilityDefs` tablosu (Firebolt 140%, vb.)
- [ ] `k_backstab` playtest

### Sinerji & kimya

- [x] Reaksiyon matrisi v1 (10 reaksiyon) → `CHEMISTRY_ENGINE.md`
- [x] Sinerji çerçevesi (main+off+chest) → `CHEMISTRY_ENGINE.md` §3
- [x] Pure x3 perk listesi → `CHEMISTRY_ENGINE.md` §3.5
- [x] Harmony (x1+x1+x1) → §3.6
- [x] Unbound (Pure Neutral) → §3.7
- [x] Duality (x2+x1) → `CHEMISTRY_ENGINE.md` §3.3
- [ ] Yeni reaksiyonlar (`CHEMISTRY_ENGINE.md` §6 brainstorm)

### Modlar & ranked

- [x] PvP 1v1 / 2v2 / 3v3 arena + casual/ranked çerçevesi → `MODES.md` §3
- [x] PvE boss önce, dungeon sonra → `MODES.md` §4–5
- [x] PvP **230s** gaz cap (180+20+30) → `MODES.md` §3.5
- [x] Ranked tier isimleri kilit → `MODES.md` §3.6
- [ ] Ranked MMR eşikleri, win/loss puan delta
- [ ] Gaz DPS / The Eye sayıları — kod sonrası playtest
- [ ] Dungeon ekonomi (key / stamina)

### Progression & live

- [x] XP kaynağı — PvP + PvE (`§10`)
- [x] Loot çerçevesi — Gacha Box + boss-exclusive (`§10`)
- [x] Trade sistemi — evet (`§10`)
- [x] Craft yok; + basma / rün / socket (`§10`)
- [ ] Level cap, XP eğrisi, Gacha drop %
- [ ] Rarity tablosu
- [ ] + basma malzeme, cap, başarı oranı
- [ ] Monetization detay (fiyat, pass yapısı)
- [ ] Tutorial akışı

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
