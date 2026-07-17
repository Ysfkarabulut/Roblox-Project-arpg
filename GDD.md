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

Tek **Damage** statı; Physical/Magical ayrımı yok. DoT / statü → Potency + Resist kanalı.

---

## 5. Loadout & Equipment Slots

### Slotlar

```
        [ Head ]
[ Main Hand ]  [ Off-hand / Knot ]
        [ Chest ]
[ Gloves ]     [ Boots ]
```

| Slot | İçerik |
|------|--------|
| **Main Hand** | 1H veya 2H silah |
| **Off-hand** | 1H build: Shield, Focus (*TBD*), veya 1H silah / Wand / Scepter |
| **Weapon Knot** | 2H STR veya Staff — pasif (§7) |
| **Head / Chest / Gloves / Boots** | Zırh, stat, affix |

### Eşya tasarım ilkesi

- **Tank:** yüksek Defence, düşük Resist — *manuel item tablosu*
- **Büyücü:** düşük Defence, yüksek Resist — *manuel*
- **Stat requirement:** `Requires STR 40` vb. — build commitment
- *Rarity / tier sistemi — TBD*

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
| 1H Sword | STR | **Bleed** on-hit |
| 1H Axe | STR | Rakip **guard/parry** yaparken ekstra **Stamina** damage |
| 1H Mace | STR | **Defence Shred** — Defence’in bir kısmını ignore |
| Wand | INT | +Status Potency |
| Scepter | INT | +Buff Potency; solo damage wand ile staff arası |
| Bow | DEX | +Crit Chance |
| Crossbow | DEX | +Crit Damage; düşük hız, vuruş arası reload **anim** (mekanik değil) |
| 2H Sword | STR | Bleed (güçlü) |
| 2H Axe | STR | Anti-guard stamina (artmış) |
| 2H Mace | STR | Defence Shred (yüksek) |
| Staff | INT | +Status Potency++; light attack = **projectile** |

INT silahları: light attack projectile.  
*Yeni silah tipleri (Rapier vb.) — şimdilik yok.*

---

## 7. Off-hand & Weapon Knot

### Shield (yalnızca off-hand)

**Guard** = sağ tık. **Parry yok.** Stability stat **yok**.

| Tip | Drain/s | Guard slow | Chip* |
|-----|---------|------------|-------|
| **Buckler** | 0.5 | 10% | blocklanan hasarın **%60**’ı alınır |
| **Kite** | 1.0 | 20% | **%40** |
| **Tower** | 1.5 | 30% | **%30** |

\*Guard sırasında chip + vuruş başına stamina maliyeti. Stamina 0: pasif drain → **Slow 50%** (%10 dolunca kalkar); vuruşla biterse → **Stagger 0.5s**.

İleride farklar affix ile de verilebilir; tip = bu üçlü taban.

### Off-hand weapon

| Tür | Light attack | Pasif / perk | Aktif skill |
|-----|--------------|--------------|-------------|
| **1H STR / Dagger** | Dual anim, **çift vuruş**; on-hit ×2 | Off-hand **%50** | Yalnızca **main hand** |
| **Wand / Scepter** | Yok (stat stick) | Eşya bonusları | Kullanılamaz |
| Aktifli 1H | Takılabilir | %50 | Off-hand aktif **kapalı** |

*Dual hit damage çarpanı — playtest (eski taslak ×0.65).*

### Weapon Knot

| Kural | Değer |
|-------|--------|
| Kullanım | **2H STR**, **Staff** |
| Bow / Crossbow | Knot **yok** (*slot TBD*) |
| Etki | Genelde **pasif** |

Örnek knot pasifleri: disarm direnci, stagger direnci, +Status Potency (staff). *Tam roster — TBD.*

### Focus (off-hand)

**Askıda.** Build çeşitliliği için mekanik değiştirici; STR build’de bile kullanılabilir olacak. *Detay — TBD.*

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
3. Defence → DR% → Mace shred  
4. Guard chip + stamina  
5. On-hit statü / kimya  
6. Resist vs Potency  

---

## 9. Chemistry & Synergies

### Katman 1 — Reaksiyonlar (kilit)

`Wet` hub. Tüketim kuralı anti-loop. Tam tablo → **`CHEMISTRY_ENGINE.md`**.

| Reaksiyon | Sonuç |
|-----------|--------|
| Wet + Ignite | Steam — ikisi iptal |
| Wet + Shock | Chain lightning (15r) |
| Wet + Windy | Chilled |
| Wet + Poisoned | Contagion spread (10r) |

DoT yığını: 2+ DoT aktif → ×2 tick.

Element matchup ±15% yalnızca **doğrudan hasar** (opsiyonel toggle).

### Katman 2 — Sinerjiler (*açık*)

Element tabanlı loadout bonusları (ör. 3× Fire) — **reaksiyonları güçlendirmez**; oyuna özgü pasif mekanikler.

*Örnek liste, değerler, UI — TBD.*

### Status & Potency

- **Status Potency** (INT, wand/staff): Ignite DPS, Shock süresi vb.
- **Resist** (INT, gear): aynı etkilerin azaltılması
- **Buff Potency** (base + INT, scepter): heal / buff

Staff yeteneği: ana hasar → Defence; bıraktığı Ignite → Resist/Potency kanalı.

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
| Kimya | 4 Wet reaksiyon |
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
| **Sinerji** | 3× element loadout bonusu — reaksiyondan ayrı katman |
| **Weapon Knot** | 2H STR / Staff pasif off-slot |
| **Focus** | Off-hand mekanik değiştirici (*TBD*) |
| **TTK** | Time to kill; orta, skill ile uzar |

---

## 16. Open Questions (Backlog)

*Açık kalan her şey burada kalır; GDD gövdesi kilitlendikçe buraya sadece yeni sorular eklenir.*

### Ürün & world

- [ ] Oyun adı
- [ ] Lore / setting
- [ ] Açık dünya scope ve timeline

### Combat & gear

- [ ] Focus off-hand — tam mekanik seti
- [ ] Bow / Crossbow off-slot (knot yok; quiver?)
- [ ] Dual wield per-hit damage çarpanı (final)
- [ ] Element matchup PvP’de açık mı?
- [ ] Yetenek crit alır mı?
- [ ] Guard hasar pipeline (DR önce mi chip önce mi — final sıra)

### Sinerji & kimya

- [ ] 3× element sinerji listesi ve değerler
- [ ] Çapraz sinerji (2 Fire + 1 Wind vb.)
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
