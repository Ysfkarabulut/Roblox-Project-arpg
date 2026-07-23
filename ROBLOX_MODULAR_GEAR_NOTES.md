# Roblox Modular Gear Notes

Moduler ekipman tasarim kilidi.

## Ability ID convention

| Suffix | Catalog | Ornek |
|--------|---------|-------|
| `*_weaponpassive` | `PassiveDefs.luau` | `keen_weaponpassive` |
| `*_weaponactive` | `WeaponActiveDefs.luau` | `strike_weaponactive` |
| `*_armorpassive` | `ArmorAbilityDefs.luau` | `carapace_armorpassive` |
| `*_armoractive` | `ArmorAbilityDefs.luau` | `hand_touch_armoractive` |

- **Catalog id** = mekanik (`strike_weaponactive`)
- **Item `name`** = flavor ("Measured Thrust")
- Combat params: `AbilityRuntime.luau` (weapon + armor actives)

## Armor (v1)

- **ArmorMatrix**: 32 pieces (8 element � Head/Chest/Hands/Feets)
- **Playtest set**: Steel tank � `a_head_steel`, `a_chest_steel`, `a_hands_steel`, `a_feets_steel` (auto-granted + equipped)
- Tank band (Rock/Steel/Neutral): high Def � Mage band: high Res

| Slot | Ability |
|------|---------|
| Chest | `carapace_armorpassive` (Neutral: `unbound_hide` · Water: `fortifyaura`) |
| Head | `helm_pulse_armoractive` (Rock: `stone_focus`) |
| Hands | `hand_touch_armoractive` |
| Feets | `dodge_step_armorpassive` (Neutral: `quiet_step`) |

Blade atama:
```lua
abilities = {
  "strike_r_weaponactive",
  "keen_weaponpassive",
}
```

Generic gem-element actives: `strike_weaponactive`, `bolt_weaponactive`, `cone_weaponactive`, `dash_weaponactive`, `burst_weaponactive`, `*_r_weaponactive` tier.

Buff / support actives (Buff Potency ölçekli): `heal_weaponactive`, `hot_weaponactive`, `fortify_weaponactive`, `frenzy_weaponactive`. Scepter ailesine atanmış; wand hasar odaklı kalır.

Aktif yetenek **arketip matrisi** (procedural üretim için): `WEAPON_ACTIVE_ARCHETYPES.md`

## Global Weapon Passives (v1)

| ID | Etki |
|----|------|
| `status_weaponpassive` | LA L1/L2: %15 gem status, L3 garantili |
| `keen_weaponpassive` | Crit +5% |
| `potency_weaponpassive` | Status Potency +12 |
| `direct_weaponpassive` | Direct damage x1.03 |
| `buff_weaponpassive` | Buff Potency +10 |

## Rarity - blade

| Rarity | 1H | 2H |
|--------|----|----|
| Common | 1A veya 1P | 2A / 2P / 1A+1P |
| Rare | 1A+1P | 2A+1P veya 1A+2P |

## Gem socket rules

- Element comes from the socketed **gem** on the handle.
- **Break unsocket** (default): gem is **destroyed**; frame becomes Neutral.
- **Safe unsocket**: spend **premium currency** (`CurrencyService.GemPreserveUnsocketCost`, default 1) — gem returns to bag.
- **Socket replace**: installing a new gem over an occupied socket **destroys** the old gem (same as break unsocket).
- Studio dev: `DevRemotes.GrantPremium` to test safe unsocket.

## Loot (Faz 1 — Studio sim)

Kaynak: `LootTables.luau` · `MatchResultService.luau` (server/Loot)

| Kaynak | Gacha şans | Boss-exclusive |
|--------|------------|----------------|
| PvP win | 40% | — |
| PvE boss win (Eye) | 50% | 8% |

**Gacha havuzu:** Common handle/pommel/gem (55%) · Rare blade (30%) · Rare armor (10%) · Bonus gem (5%). Common 48-blade catalog **dahil değil**. BossExclusive **asla** Gacha'da yok.

Dev: `DevRemotes.SimulateMatchResult:FireServer({ mode = "PvE", won = true, bossId = "eye" })`

## Persistence (Faz 2)

- **DataStore:** `ARPG_PlayerProfile_v1`
- **Kayıt:** inventory, loadout, hotbar, stats, premium
- **Autosave:** 120s · leave + BindToClose
- **Bootstrap:** `00_ProfileBootstrap.server.luau` (diğer scriptlerden önce)

## Loot UI (Faz 3)

- **Remote:** `LootRemotes.LootResult` (server → client)
- **Bridge:** `MatchResultBridge.FinishMatch(player, { mode, won, bossId? })`
- **Client:** `LootResultUI` — zafer/yenilgi modal, Gacha + boss drop + XP
- **Dev:** F8 → Match sim butonları veya `SimulateMatchResult`

```lua
-- Boss / arena script (server)
local MatchResultBridge = require(Server.Loot.MatchResultBridge)
MatchResultBridge.FinishMatch(player, { mode = "PvE", won = true, bossId = "eye" })
```

## XP Progression (Faz 4)

- **Config:** `XpConfig.luau` — level cap 50, eğri `100 + (level-1)*40` XP/level
- **Kaynak:** PvE win +120 XP · PvP win +80 XP (`LootTables.XpForResult`)
- **Level up:** **+4 unspent** stat points (`StatConfig.PointsPerLevel`); GearUI **+** ile dağıt
- **Persistence:** profil `xp` + `unspentStatPoints` (schema v3)
- **UI:** LootResult modal level-up satırı · GearUI XP bar

```lua
local StatService = require(Server.Combat.StatService)
StatService.GrantXp(userId, 120)
```

## Boss Encounter — The Eye

- **Config:** `BossEncounterConfig.luau` (MODES.md §4.6)
- **Start (Studio):** F8 → **Start Eye Boss** · `_G.Lobby.Queue("pve_boss_solo")` · **J** Lobby UI
- **Win/Lose:** `MatchResultBridge` → loot + XP modal · DEFEAT → **Retry**
- **Mekanikler:** Rotating Beam · Monolith + Gaze (P2) · Tentacle (P3)

## Stat allocation (Faz 5)

- Level up → **+4 unspent** stat points (`StatConfig.PointsPerLevel`)
- GearUI Stats panel: **+** butonları · `InventoryRemotes.AllocateStat`
- Persistence: `unspentStatPoints` + `pvpMmr` (profile schema **v4**)

## Lobby UI

- **Toggle:** `J` · `LobbyRemotes.GetLobbyState` / `LobbyUpdated`
- Party ready/leave · queue list (PvE boss + PvP)

## PvP practice (Studio stub)

- Arena `(200/400/600, 5, 0)` by bracket · solo vs `PvpOpponent` dummy
- F8 → **PvP Practice** · `_G.Lobby.Queue("pvp_1v1_casual")`
- Win → `MatchResultBridge` PvP loot roll

## Production phases (kod durumu)

| Faz | Durum | Öne çıkan |
|-----|--------|-----------|
| **F1** Mekanik | v1 | SynergyService, CC diminishing, off-hand ability 50%, MatchReset |
| **F2** İçerik | v1 | 48 blade, 32 armor, Eye boss, MVP grant dev |
| **F3** Modlar | v1 | WoW arenas, ranked MMR, spectate, PvE LFG merge, boss place |
| **F4** Meta | v1 stub | Tutorial, Shop (B), Upgrade, persistence v4 |
| **F5** Playtest | checklist | `STUDIO_TEST_CHECKLIST` V–Y |
| **Dungeon** | greybox stub | `DungeonRunService` 3 room → boss |

## Synergy (F1)

- `SynergyService.luau` + `SynergyConfig.luau` — Pure/Duality/Harmony/Unbound
- `StatService.Derived` → `synergyBand`, def/resist/direct bonuses

## Ranked (F3)

- `RankedService` + `RankedConfig` — MMR per bracket, tiers Rookie→Gladiator
- Profile `pvpMmr` · loot modal MMR satırı

## Meta (F4)

- **Tutorial:** `TutorialUI` · **Shop:** `B` key · **Upgrade:** `UpgradeService` (+3% dmg/level, premium)
- Remotes: `MetaRemotes/*`

## WoW-style PvP arenas (ayrı place)

- **Places:** `places/pvp_1v1.project.json` (Duel Pit) · `pvp_2v2` (Skirmish Yard) · `pvp_3v3` (Clash Ring) · `pve_boss_eye`
- **Config:** `PvpArenaConfig.luau` — floor size, pillars, gates, gas phase
- **Builder:** `PvpArenaBuilder.luau` — placeholder parts (swap meshes later)
- **Flow:** Lobby queue → `MatchTeleport` → arena place `ArenaMatchCoordinator` → team wipe → loot → lobby teleport
- **Studio:** `rojo serve places/pvp_1v1.project.json` + `PlaceConfig` PlaceIds = 0 uses offset arenas in lobby place

## Dungeon (stub)

- `DungeonRunService` — placeholder trash rooms → `BossEncounterService`

- **BladeDefs**: 48 blade (12 aile x ST/AOE x Common/Rare)
- **BossContent**: 3 boss blade (The Eye) — `BossExclusive`, starter'da yok
- **RareArmorDefs**: Thornplate chest, Stormgrasp hands
- **ArmorMatrix**: 32 pieces (8 element x 4 slot); playtest = Steel set

### Blade matrisi (48)

| Aile | Handle | Parca adi | ST Common | AOE Common | ST Rare | AOE Rare |
|------|--------|-----------|-----------|------------|---------|----------|
| Dagger | 1H_Sword | Blade | `b_dagger_st` | `b_dagger_aoe` | `b_dagger_st_r` | `b_dagger_aoe_r` |
| Sword | 1H_Sword | Blade | `b_sword_st` | `b_sword_aoe` | `b_sword_st_r` | `b_sword_aoe_r` |
| Axe | 1H_AxeMace | Blade | `b_axe_st` | `b_axe_aoe` | `b_axe_st_r` | `b_axe_aoe_r` |
| Mace | 1H_AxeMace | Blade | `b_mace_st` | `b_mace_aoe` | `b_mace_st_r` | `b_mace_aoe_r` |
| Wand | 1H_WandScepter | Blade | `b_wand_st` | `b_wand_aoe` | `b_wand_st_r` | `b_wand_aoe_r` |
| Scepter | 1H_WandScepter | Blade | `b_scepter_st` | `b_scepter_aoe` | `b_scepter_st_r` | `b_scepter_aoe_r` |
| Greatblade | 2H_Sword | Blade | `b_greatblade_st` | `b_greatblade_aoe` | `b_greatblade_st_r` | `b_greatblade_aoe_r` |
| Greataxe | 2H_AxeMace | Blade | `b_greataxe_st` | `b_greataxe_aoe` | `b_greataxe_st_r` | `b_greataxe_aoe_r` |
| Greathammer | 2H_AxeMace | Blade | `b_greathammer_st` | `b_greathammer_aoe` | `b_greathammer_st_r` | `b_greathammer_aoe_r` |
| Staff | 2H_Staff | Head | `b_staff_st` | `b_staff_aoe` | `b_staff_st_r` | `b_staff_aoe_r` |
| Bow | 2H_Bow | Limbs | `b_bow_st` | `b_bow_aoe` | `b_bow_st_r` | `b_bow_aoe_r` |
| Crossbow | 2H_Crossbow | Head | `b_crossbow_st` | `b_crossbow_aoe` | `b_crossbow_st_r` | `b_crossbow_aoe_r` |

Yetenek formu:
- **ST**: melee `strike`/`dash`, ranged `bolt` � rare: `*_r` tier
- **AOE**: `cone` � rare 2H: `cone_r` + `slam_r` (2A+1P)
- **1H Rare**: 1A + 1P � **2H Rare**: 2A+1P veya 1A+2P

Kod: `PassiveDefs.luau`, `WeaponActiveDefs.luau`, `ArmorAbilityDefs.luau`, `BladeDefs.luau`, `AbilityRuntime.luau`
