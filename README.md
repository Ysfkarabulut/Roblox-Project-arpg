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
| **PvP / PvE modları, ranked** | Çerçeve kilit (`MODES.md`) |
| İçerik (silah, boss, eşya) | Dolduruluyor |
| Progression, loot, ekonomi | Açık (`GDD.md` §16) |
| Playtest slice (eski MVP) | **En son faz** (`GDD.md` §14) |
| Roblox implementasyonu | Henüz başlamadı |

---

## Üretim sırası

1. **Mekanikler** — combat, status, kimya  
2. **İçerik** — silahlar, eşyalar, boss'lar  
3. **Modlar** — 1v1 / 2v2 / 3v3 arena + ranked; PvE boss  
4. **Meta** — XP, loot, tutorial  
5. **Playtest slice** — dış test (`MVP_CONTENT.md`)

---

## Belgeler

| Dosya | İçerik |
|-------|--------|
| [`GDD.md`](GDD.md) | Ana tasarım — vision, loadout, combat, glossary |
| [`MODES.md`](MODES.md) | PvP arena bracket'leri, ranked, PvE boss → dungeon |
| [`COMBAT_STAT_SHEET.md`](COMBAT_STAT_SHEET.md) | Statlar, hasar pipeline, guard/dodge |
| [`STATUS_SYSTEM.md`](STATUS_SYSTEM.md) | Status kataloğu, ApplyStatus |
| [`CHEMISTRY_ENGINE.md`](CHEMISTRY_ENGINE.md) | Element, sinerji, reaksiyonlar |
| [`MVP_CONTENT.md`](MVP_CONTENT.md) | Playtest slice şablonu (son faz) |

**Okuma sırası:** `GDD.md` → `MODES.md` → `COMBAT_STAT_SHEET.md` → `STATUS_SYSTEM.md` → `CHEMISTRY_ENGINE.md`

---

## Modlar (özet)

### PvP — 3 arena, her biri Casual + Ranked

| Bracket | Arena | Ranked ladder |
|---------|-------|---------------|
| 1v1 | Duel Pit | Ayrı MMR |
| 2v2 | Skirmish Yard | Ayrı MMR |
| 3v3 | Clash Ring | Ayrı MMR |

### PvE

| Faz | İçerik |
|-----|--------|
| **Şimdi** | Boss Fight — phase boss, 1 / 2 / 3 co-op |
| **İleride** | Dungeon — odalar, trash, boss |

---

## Açık konular

`GDD.md` §16 · `MODES.md` §7 — öne çıkanlar:

- Boss roster, eşya tabloları, XP/loot
- Ranked MMR, sezon, tier
- PvP timeout kuralı
- Dungeon ekonomisi

---

## İlişkili projeler

**CannonClash** ayrı repodadır (lane autobattler). Kimya motoru konsept olarak taşınabilir.

---

*Son güncelleme: 2026-07*
