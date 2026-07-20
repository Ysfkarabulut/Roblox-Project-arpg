# Action RPG Project (tasarım aşaması)

Third-person action, gear-based build, no class. CannonClash'ten **bağımsız** proje.

| | |
|--|--|
| **Platform** | Roblox (hedef) |
| **Oyuncu dili** | English (UI / items / abilities) |
| **Tasarım** | Türkçe doküman + chat |
| **Tema** | Low poly |
| **Durum** | Combat tasarımı kilit · **lobby kod iskeleti başladı** |
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
| Progression, loot, ekonomi | Çerçeve kilit (`GDD.md` §10); sayılar TBD |
| Playtest slice (eski MVP) | **En son faz** (`GDD.md` §14) |
| Roblox implementasyonu | Lobby kabuğu (`src/`) · combat henüz yok |

### Kod (Rojo)

```
src/shared/Config/   PlaceConfig, QueueConfig, ItemDefs, LoadoutSlots
src/server/Lobby/    PartyService, QueueService, MatchTeleport
src/server/Inventory/ InventoryService (UUID), LoadoutService
src/client/Lobby/    LobbyClient stub
src/client/Inventory/ GearUI + HotbarUI (Q E R 1 2 3, sürükle-bırak)
```

`rojo serve` / Studio sync ile bağla. PlaceId'leri `PlaceConfig.luau` içine yaz.  
**UI:** `I` Inventory · `L` Loadout · `H` Active havuzu — hotbar her zaman altta.


---

## Üretim sırası

1. **Lobby kabuğu** — parti, queue, place teleport *(başladı)*  
2. **Mekanikler** — combat, status, kimya  
3. **İçerik** — silahlar, eşyalar, boss'lar  
4. **Modlar** — arena place'leri + ranked MMR  
5. **Meta** — XP, loot, tutorial  
6. **Playtest slice** — dış test (`MVP_CONTENT.md`)

---

## Belgeler

| Dosya | İçerik |
|-------|--------|
| [`GDD.md`](GDD.md) | Ana tasarım — vision, loadout, combat, glossary |
| [`MODES.md`](MODES.md) | PvP arena bracket'leri, ranked, PvE boss → dungeon |
| [`COMBAT_STAT_SHEET.md`](COMBAT_STAT_SHEET.md) | Statlar, hasar pipeline, guard/dodge |
| [`STATUS_SYSTEM.md`](STATUS_SYSTEM.md) | Status kataloğu, ApplyStatus |
| [`CHEMISTRY_ENGINE.md`](CHEMISTRY_ENGINE.md) | Element, sinerji, reaksiyonlar |
| [`COMBAT_ARCHITECTURE.md`](COMBAT_ARCHITECTURE.md) | Roblox modül planı, pipeline kod eşlemesi, tutarsızlık listesi |
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

- Gaz DPS (30s ölüm hedefi), ranked MMR/puan delta
- The Eye hasar sayıları, boss_02/03
- + basma malzeme ve başarı oranları
- Tutorial, 2v2/3v3 premade kuralı

---

## İlişkili projeler

**CannonClash** ayrı repodadır (lane autobattler). Kimya motoru konsept olarak taşınabilir.

---

*Son güncelleme: 2026-07*
