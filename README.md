# Action RPG Project (tasarım aşaması)

Third-person action, gear-based build, no class. CannonClash'ten **bağımsız** proje.

| | |
|--|--|
| **Platform** | Roblox (hedef) |
| **Oyuncu dili** | English (UI / items / abilities) |
| **Tasarım** | Türkçe doküman + chat |
| **Tema** | Low poly |
| **Durum** | Combat alpha · **modüler silah sistemi (WeaponFrame)** |
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
| İçerik (silah, boss, exotic, eşya) | **Exotic 18 + matrix** (`GDD.md` §6.1) · boss devam |
| Progression, loot, ekonomi | Çerçeve kilit (`GDD.md` §10); sayılar TBD |
| Playtest slice (eski MVP) | **En son faz** (`GDD.md` §14) |
| **Roblox implementasyonu** | Combat alpha · modüler silah · **18 Exotic** · inspect tooltip |

### Kod (Rojo)

```
src/shared/Config/   ItemDefs, ExoticContent, ExoticPerkDefs, Handle/Blade/Pommel/GemDefs
src/shared/UI/       ItemTooltip, AbilityTooltip, InspectHints
src/shared/Combat/   WeaponResolver, CombatKind, DamagePipeline
src/server/Combat/   LA, abilities, dodge/guard/parry, damage pipeline
src/server/Inventory/ InventoryService, LoadoutService, WeaponAssemblyService
src/server/Hotbar/    HotbarService (sourceUuid binds)
src/server/Lobby/    PartyService, QueueService, MatchTeleport
src/client/Lobby/    LobbyClient stub
src/client/Inventory/ GearUI + HotbarUI (Q E R 1 2 3, sürükle-bırak)
```

`rojo serve` / Studio sync ile bağla. PlaceId'leri `PlaceConfig.luau` içine yaz.  
**Lobby:** `default.project.json` · **Arena places:** `places/pvp_1v1.project.json` (ve 2v2/3v3)  
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
| [`GDD.md`](GDD.md) | Ana tasarım — vision, loadout, combat, **§6.1 Exotic**, **§17 kod günlüğü** |
| [`MODES.md`](MODES.md) | PvP arena bracket'leri, ranked, PvE boss → dungeon |
| [`COMBAT_STAT_SHEET.md`](COMBAT_STAT_SHEET.md) | Statlar, hasar pipeline, guard/dodge |
| [`STATUS_SYSTEM.md`](STATUS_SYSTEM.md) | Status kataloğu, ApplyStatus |
| [`CHEMISTRY_ENGINE.md`](CHEMISTRY_ENGINE.md) | Element, sinerji, reaksiyonlar |
| [`COMBAT_ARCHITECTURE.md`](COMBAT_ARCHITECTURE.md) | Roblox modül planı, pipeline kod eşlemesi |
| [`ROBLOX_MODULAR_GEAR_NOTES.md`](ROBLOX_MODULAR_GEAR_NOTES.md) | Modüler parça, loot tier, Exotic catalog ref |
| [`docs/BLADE_ASSET_PROMPTS.md`](docs/BLADE_ASSET_PROMPTS.md) | Meshy AI blade prompt’ları (68 item, copy-paste) |
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

## Evde polish backlog (Studio — şimdilik ertelendi)

**2) Anim / VFX polish (GPO tarzı tempo)**  
- LA combo recovery senkronu (`CombatAnim`, client recovery lock)  
- Hitstop / hit flash (`CombatFx`, `CombatVfx`)  
- Ability cast wind-up ve recovery anim eşlemesi  
- Dual wield off-hand LA görsel ayrımı (opsiyonel)

**3) Yeni reaksiyonlar (AO esintili ama farklı)**  
- 1–2 yeni status çifti (`ReactionTable` + `STATUS_SYSTEM`)  
- Synergy band UI netliği (Pure / Duality / Harmony ipuçları)  
- Reaksiyon çıktıları için kısa VFX / status ikon split

---

## İlişkili projeler

**CannonClash** ayrı repodadır (lane autobattler). Kimya motoru konsept olarak taşınabilir.

---

*Son güncelleme: 2026-07*
