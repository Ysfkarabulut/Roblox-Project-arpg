# Action RPG Project (tasarım aşaması)

Third-person action, gear-based build, no class. CannonClash'ten **bağımsız** proje.

| | |
|--|--|
| **Platform** | Roblox (hedef) |
| **Tema** | Low poly |
| **Durum** | Combat çekirdeği kilitlendi — **kod yok** |
| **Repo** | [github.com/Ysfkarabulut/Roblox-Project-arpg](https://github.com/Ysfkarabulut/Roblox-Project-arpg) |

---

## Durum özeti

| Alan | Durum |
|------|--------|
| Vision, loop, loadout, combat | Kilitli (`GDD.md`) |
| Stat / formül tablosu | Kilitli v1 (`COMBAT_STAT_SHEET.md`) |
| Status kataloğu, Potency, ApplyStatus | Kilitli v1 (`STATUS_SYSTEM.md`) |
| Element matchup, sinerji, reaksiyonlar | Kilitli (`CHEMISTRY_ENGINE.md`) |
| Progression, loot, ekonomi, tutorial | Açık (`GDD.md` §16) |
| Roblox implementasyonu | Henüz başlamadı |

---

## Belgeler

| Dosya | İçerik |
|-------|--------|
| [`GDD.md`](GDD.md) | Ana tasarım belgesi — vision, loadout, silahlar, off-hand, combat, MVP, glossary |
| [`COMBAT_STAT_SHEET.md`](COMBAT_STAT_SHEET.md) | Primary/secondary statlar, hasar pipeline, guard/dodge/stamina formülleri |
| [`STATUS_SYSTEM.md`](STATUS_SYSTEM.md) | Status kataloğu (Root dahil), Potency/Resist, ApplyStatus pipeline |
| [`CHEMISTRY_ENGINE.md`](CHEMISTRY_ENGINE.md) | Element matchup, sinerji bantları, 10 reaksiyon özeti |

**Okuma sırası:** `GDD.md` → `COMBAT_STAT_SHEET.md` → `STATUS_SYSTEM.md` → `CHEMISTRY_ENGINE.md`

---

## Kilitli tasarım özeti

### Combat

- 4 primary stat: **STR, DEX, VIT, INT** — class yok
- Light attack, dodge (+ recovery), guard (shield), parry (MVP sonrası)
- Defence ekipmandan; DR% = Defence × 0.1 (cap ile)

### Loadout & off-hand

| Ana el | Off-hand |
|--------|----------|
| **1H melee** | Shield / 1H silah (dual) / **Focus** / Wand·Scepter |
| **2H melee / Staff** | **Weapon Knot** (tagsiz, pasif/stat) |
| **Bow / Crossbow** | **Quiver** (tagsiz, pasif/stat) |

- **Focus:** utility off-hand; 1 aktif veya 1 pasif; sinerji tag var; dual %50 kuralına girmez
- **Wand / Scepter (off):** INT dual; düz vuruş yok; pasif/perk/aktif **%50**
- **1H dual (STR/DEX):** çift vuruş; off-hand pasif/perk/aktif **%50**

### Kimya & sinerji

**Sinerji kaynağı:** Main + Off + Chest element ağırlığı

| Band | Koşul | Özet etki |
|------|-------|-----------|
| **Pure ×3** | Tek element, ağırlık 3 | On-hit imza status + element perk |
| **Harmony** | ×1+×1+×1 (yalnızca 1H melee) | +15 flat Status Potency |
| **Duality** | ×2+×1 | +5% Defence, +5% Resist |
| **Unbound** | 3× Neutral | +5% direct, +10% Defence, +12% Resist |

**Reaksiyonlar (v1, 10 adet):** R1 Vaporize · R2 Chain Shock · R3 Chilled · R4 Thaw · R5 Cauterize · R6 Blight · R7 Grounded · R8 Contamination · R9 Wild Fire · R10 Caustic Burn

Detay: `GDD.md` §9 · `STATUS_SYSTEM.md` · `CHEMISTRY_ENGINE.md` §4

---

## MVP kapsamı

İlk oynanabilir hedef (`GDD.md` §14):

- Basit lobby → 1v1 PvP
- 1H Sword, 1H Axe, Staff, Bow + Kite Shield
- Light attack, dodge, guard
- 10 reaksiyon + status kataloğu
- Birkaç manuel tier-1 item

MVP sonrası: parry, dual wield, 3 shield tipi, Knot, Focus, kalan silahlar, boss phase, 2v2/3v3.

---

## Açık konular (backlog)

`GDD.md` §16 — öne çıkanlar:

- Oyun adı, lore
- XP, loot, craft, ekonomi
- Tutorial, ranked, monetization
- Dual wield hasar çarpanı (playtest)
- Roblox repo / place yapısı

---

## İlişkili projeler

**CannonClash** ayrı repodadır (lane autobattler). Kimya motoru konsept olarak taşınabilir; lane / cannon / birim meta bu projede yoktur.

---

*Son güncelleme: 2026-07*
