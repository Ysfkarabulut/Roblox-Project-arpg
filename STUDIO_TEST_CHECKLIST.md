# Studio Test Checklist

Akşam evde Roblox Studio’da sırayla işaretle. Her madde: **Pass / Fail / N/A** + kısa not.

---

## A. Kurulum

- [ ] Rojo sync / `rojo serve` → Studio connect
- [ ] Play (F5) — Output’ta hata yok: `[InventoryBootstrap]`, `[CombatBootstrap]`, `[DevBootstrap]`
- [ ] Gear UI açılıyor (inventory tuşu)
- [ ] Training Dummy spawn (yaklaşık `8, 3, -12`)

---

## B. Modüler silah — montaj

- [ ] Starter’da `weapon_frame` + handle + pommel + gem parçaları var
- [ ] Handle → Blade → Pommel frame’e takılıyor (GearUI install)
- [ ] Yanlış handle tipine blade takılamıyor (ör. bow limbs → 1H sword handle)
- [ ] Bow/Crossbow → **String** pommel; melee → **Pommel**
- [ ] Gem socket: frame seçili + gem tıkla → element değişiyor (`resolvedMain.element`)
- [ ] Yeni gem takınca **eski gem yok oluyor** (replace)
- [ ] **Break Gem** unsocket → gem envanterden kayboluyor, silah Neutral
- [ ] `DevRemotes.GrantPremium:FireServer(3)` → **Safe (1)** unsocket → gem bag’e dönüyor
- [ ] Parça çıkarma (− / sağ tık) çalışıyor
- [ ] `+ New Frame` yeni boş frame oluşturuyor
- [ ] Composite görsel: handle + blade + pommel + gem orb (main slot)

---

## C. Loadout & hotbar

- [ ] İlk girişte complete frame **main**’e auto-equip
- [ ] Steel zırh seti (head/chest/hands/feets) auto-equip
- [ ] Off-hand: shield / quiver / knot takılabiliyor
- [ ] Hotbar’a aktif yetenekler geliyor (Q E R 1 2 3)
- [ ] Silah değişince hotbar prune + yeniden doldurma mantıklı
- [ ] Stance attribute güncelleniyor (dual / 2H / bow vb.)

---

## D. Light attack (LA)

- [ ] LA L1 → L2 → L3 combo (whiff combo ilerletmez)
- [ ] Dagger backstab bonus (arkadan)
- [ ] Wand/Staff projectile menzil
- [ ] Scepter cone LA
- [ ] Bow/Crossbow ranged LA
- [ ] Gem element: L3 garantili status / `status_weaponpassive` L1-L2 %15 proc
- [ ] **Pure x3:** Main+Off+Chest aynı element → **her LA isabetinde** imza status (L1/L2/L3)
- [ ] Pure Fire → Ignite süre +15% (dummy status label)
- [ ] Pure Water → Wet + **8 stud** yakın hedeflere splash
- [ ] Pure Lightning → Shock +0.15s
- [ ] Pure Rock → Slow + hedef +5% direct taken (Fortify benzeri `damageTakenMult`)
- [ ] Pure olmayan loadout → eski L3 / %15 proc davranışı korunur
- [ ] `potency_weaponpassive` → status süresi/DPS artışı (dummy status label)
- [ ] Dual wield off-hand %50 proc (1H + 1H off)

---

## E. Aktif yetenekler — damage formları

Her formu en az bir blade ile dene (DevTools `GrantItem`):

| ID | Test |
|----|------|
| `strike_weaponactive` | Melee single, gem status |
| `bolt_weaponactive` | Ranged single |
| `cone_weaponactive` | Cone AoE |
| `dash_weaponactive` | Dash strike |
| `slam_r_weaponactive` | 2H rare AoE ground |
| `helm_pulse_armoractive` | Sonraki 2 LA head element |
| `hand_touch_armoractive` | Hands active, armor element damage |

- [ ] Cooldown UI / tekrar cast engeli
- [ ] Ability gem element status (strike/bolt/cone)

---

## F. Buff / heal yetenekleri (yeni)

DevTools ile blade’e manuel atama veya **scepter** blade monte et:

| ID | Blade (scepter) | Beklenen |
|----|-----------------|----------|
| `heal_weaponactive` | `b_scepter_st` | Anlık heal · Buff Potency ölçekli |
| `hot_weaponactive` | `b_scepter_aoe` | HoT (Regen status) · potency süre |
| `fortify_weaponactive` | `b_scepter_st_r` | Fortify · −10% direct taken |
| `frenzy_weaponactive` | `b_scepter_aoe_r` | Frenzy · +8% damage dealt |
| `burst_weaponactive` | (manuel) | Kısa Fortify (legacy) |

- [ ] INT arttıkça heal miktarı artıyor
- [ ] `buff_weaponpassive` (scepter rare) → Buff Potency stat panelde görünüyor
- [ ] `stone_focus_armorpassive` (Rock head) → Fortify +0.5s
- [ ] `fortifyaura_armorpassive` (Water chest `a_chest_water`) → Fortify cast’te yakın ally zayıf Fortify

---

## G. Zırh pasifleri

| ID | Slot | Test |
|----|------|------|
| `carapace_armorpassive` | Chest (non-Neutral, non-Water) | Direct HP yiyince %10 attacker status |
| `fortifyaura_armorpassive` | Chest Water | Fortify cast → ally 8 stud içi zayıf Fortify |
| `unbound_hide_armorpassive` | Chest Neutral | −3% direct taken |
| `dodge_step_armorpassive` | Feets (element) | Dodge başında 4 stud AoE status |
| `quiet_step_armorpassive` | Feets Neutral | Dodge stamina −8% |
| `stone_focus_armorpassive` | Head Rock | Fortify +0.5s |

---

## H. Savunma sistemleri

- [ ] Dodge: i-frame, stamina cost, recovery
- [ ] Guard (shield): chip damage, block
- [ ] Parry (no shield): perfect = 0 dmg, fail = stamina drain
- [ ] Fortify damage reduction hissediliyor

---

## I. Blade katalogu (spot check)

48 blade — her aileden 1’er örnek:

- [ ] 1H: dagger ST (`b_dagger_st`), sword AOE rare, axe, mace, wand, scepter
- [ ] 2H: greatblade, greataxe, greathammer, staff, bow, crossbow
- [ ] Rare 1H = 1A+1P · Rare 2H = 3 yetenek

---

## J. Zırh matrix (spot check)

- [ ] `a_chest_steel`, `a_head_fire`, `a_hands_water`, `a_feets_wind` equip
- [ ] Tank band (Rock/Steel/Neutral) vs Mage band (Fire/Water…) def/res farkı
- [ ] 32 parça ItemDefs’te yüklü (`ItemDefs.All()` count)

---

## K. Legacy & dev araçları

- [ ] `w_sword_1h` grant → legacy convert → weapon_frame
- [ ] Convert sonrası loadout main slot bozulmuyor
- [ ] DevTools stat edit → derived panel güncelleniyor
- [ ] Dummy reset / HP ayarı

---

## M. Loot simülasyonu (Faz 1)

```lua
-- PvE boss win
game.ReplicatedStorage.DevRemotes.SimulateMatchResult:FireServer({
  mode = "PvE", won = true, bossId = "eye"
})

-- PvP win
game.ReplicatedStorage.DevRemotes.SimulateMatchResult:FireServer({
  mode = "PvP", won = true
})

-- Loss (no loot)
game.ReplicatedStorage.DevRemotes.SimulateMatchResult:FireServer({
  mode = "PvE", won = false, bossId = "eye"
})
```

- [ ] PvE win → **LootResult modal** (Gacha/Boss satırları + XP)
- [ ] Loss → DEFEAT modal, envanter değişmez
- [ ] Gacha ödülü GearUI envanterde görünür
- [ ] Boss blade Gacha'dan çıkmaz (sadece boss roll)
- [ ] ×10 simülasyon — boss ~%8, gacha ~%50 (PvE) hissi

---

## N. Persistence (Faz 2)

- [ ] Output: `[PlayerProfile] Persistence ready`
- [ ] Loot kazan → Stop → Play → item bag'de duruyor
- [ ] Loadout / hotbar / stats / premium rejoin sonrası korunuyor

---

## O. Loot sonuç UI (Faz 3)

- [ ] Output: `[LootBootstrap] Loot remotes ready`
- [ ] F8 → **PvE Boss Win** → VICTORY modal açılır
- [ ] Modal: XP satırı, Gacha/Boss drop ikonları (varsa)
- [ ] Kazanılmayan roll → "No bonus drops this time."
- [ ] **Loss** → DEFEAT modal, ödül yok
- [ ] Continue / overlay tık / Enter → modal kapanır
- [ ] Ödül sonrası GearUI envanterde görünür

```lua
game.ReplicatedStorage.DevRemotes.SimulateMatchResult:FireServer({
  mode = "PvE", won = true, bossId = "eye"
})
```

---

## P. XP progression (Faz 4)

- [ ] Maç kazanınca XP gerçekten işleniyor (sadece metin değil)
- [ ] PvE win → +120 XP · PvP win → +80 XP
- [ ] GearUI Stats panelinde XP bar (`XP 40 / 100` gibi)
- [ ] Yeterli XP → level up → **+4 unspent** stat points (otomatik stat artışı yok)
- [ ] LootResult modal: `+120 XP · LEVEL UP → 31`
- [ ] Stop → Play → level + XP korunuyor (DataStore)

```lua
-- Hızlı test: birkaç PvE win simüle et
for _ = 1, 5 do
  game.ReplicatedStorage.DevRemotes.SimulateMatchResult:FireServer({
    mode = "PvE", won = true, bossId = "eye"
  })
  task.wait(0.5)
end
```

---

- [ ] Level up → GearUI **+4 stat pts** · **+** ile STR/DEX/VIT/INT dağıt
- [ ] Stop → Play → unspent points korunuyor

---

## R. Stat allocation (Faz 5)

- [ ] Level up sonrası GearUI: `N stat points to spend`
- [ ] **+** butonu → stat artar, unspent azalır
- [ ] Persistence (rejoin) korunuyor

---

## S. Lobby UI

- [ ] **J** → Lobby panel açılır
- [ ] Lider: isim kutusu + **Invite** → karşı tarafa popup
- [ ] Davet **Accept** / **Decline**
- [ ] Party listesi · Ready toggle · Leave
- [ ] Lider: üye satırında **★** (lider devri) · **×** (kick)
- [ ] Parti üyelerinin nameplate’i cyan/gold (◆ / ★)
- [ ] Queue butonları (PvE boss solo/duo/trio, PvP 1v1)
- [ ] `_G.Lobby.InviteByName("PlayerName")` hâlâ çalışır

---

## T. PvP practice arena

- [ ] F8 → **PvP Practice** → arena `(200, 0, 0)` · solo dummy
- [ ] Opponent dummy'ye hasar · öldür → PvP VICTORY + loot
- [ ] Ölürsen → DEFEAT · **Retry** → tekrar arena
- [ ] `_G.Lobby.Queue("pvp_1v1_casual")` (solo → practice opponent)

---

## U. WoW-style PvP arenas (ayrı place)

**Kurulum:** Creator'da 3 arena place oluştur → `PlaceConfig.luau` PlaceIds doldur.

| Place | Rojo project | Bracket |
|-------|--------------|---------|
| Duel Pit | `places/pvp_1v1.project.json` | 1v1 |
| Skirmish Yard | `places/pvp_2v2.project.json` | 2v2 |
| Clash Ring | `places/pvp_3v3.project.json` | 3v3 |

**Studio (tek place test):** PlaceIds = 0 → lobby'de offset arena (1v1 @ 200, 2v2 @ 400, 3v3 @ 600)

- [ ] Output: `[ArenaBootstrap]` (arena place) veya `[PvpMatch]` (studio stub)
- [ ] Queue 1v1 → 2 oyuncu → karşılıklı spawn · **3…2…1 FIGHT**
- [ ] Friendly fire kapalı · rakip ölünce VICTORY
- [ ] 120s sonra shrink + gas (team match)
- [ ] Maç sonu loot modal → lobby spawn / lobby place teleport
- [ ] Arena: duvar + 4 pillar placeholder görünür

```bash
rojo serve places/pvp_1v1.project.json
```

---

## Q. Boss Arena — The Eye

- [ ] Output: `[BossBootstrap] Boss remotes ready`
- [ ] F8 → **Start Eye Boss** → arena spawn (0, 5, -120)
- [ ] Placeholder göz modeli · boss HP bar (üst HUD)
- [ ] LA / ability boss'a hasar veriyor
- [ ] ~10s sonra rotating beam hasarı
- [ ] %70 HP → Phase 2 (Monolith + Gaze)
- [ ] %30 HP → Phase 3 (Tentacle)
- [ ] Boss öldür → VICTORY loot modal
- [ ] Wipe → DEFEAT · **Retry** butonu · lobby spawn'a dönüş

```lua
-- Queue yolu
_G.Lobby.Queue("pve_boss_solo")

-- veya F8 → Start Eye Boss
```

---

## L. Bilinen eksikler (Fail beklenir — bug değil)

- [ ] ~~Crossbow reload~~ → v1 (L3 sonrası 1.2s)
- [ ] ~~Boss silahlar~~ → v1 The Eye roster
- [ ] ~~Rare zırh~~ → Thornplate + Stormgrasp
- [ ] Match teleport (gerçek place / multi-place) — **PvP arena places v1**
- [ ] ~~Boss fight (The Eye)~~ → v1 greybox
- [ ] ~~Lobby UI~~ → J panel
- [ ] ~~PvP practice stub~~ → solo opponent
- [ ] ~~Stat allocation~~ → Faz 5
- [ ] ~~Premium currency kalıcı kayıt~~ → Faz 2 DataStore
- [ ] Robux shop
- [ ] Gerçek mesh asset’leri

---

## Hızlı DevTools komutları

```lua
-- Premium (safe unsocket test)
game.ReplicatedStorage.DevRemotes.GrantPremium:FireServer(5)

-- MVP loadout (steel set + sword parçaları)
game.ReplicatedStorage.DevRemotes.GrantMvpLoadout:FireServer()

-- Pure x3 test: aynı element gem + off + chest tak, LA → her vuruş status

-- Parça grant
game.ReplicatedStorage.DevRemotes.GrantItem:FireServer("a_chest_thornplate", 1)
-- Loot sim (Faz 1)
game.ReplicatedStorage.DevRemotes.SimulateMatchResult:FireServer({ mode = "PvE", won = true, bossId = "eye" })
-- Boss / PvP (Studio)
game.ReplicatedStorage.BossRemotes.StartBossDev:FireServer({ bossId = "eye" })
game.ReplicatedStorage.PvpRemotes.StartPvpDev:FireServer()
-- Lobby queue
_G.Lobby.Queue("pve_boss_solo")
_G.Lobby.Queue("pvp_1v1_casual")
```

---

*Son güncelleme: Combat nameplate sistemi (Boss / PvP / Training).*

---

## AA. Combat nameplates

### Training (lobby dummy)

- [ ] Training Dummy üstünde **WoW tarzı** nameplate: isim + HP bar
- [ ] HP bar içinde **%** ve **sayı** (`98% (720/720)`)
- [ ] LA status → üst satırda **ikon + kalan sn + isim** (Wet, Ignite vb.)
- [ ] Süre geri sayımı ~0.2s güncellenir
- [ ] Roblox default health bar **görünmez**

### PvP hedefler

- [ ] Arena maçında **düşman** oyuncuda nameplate (takım arkadaşında yok)
- [ ] Practice `Arena Opponent` botunda nameplate + HP + status
- [ ] HP bar sarı dolgu + beyaz çerçeve + **% içerde** (referans görsel)
- [ ] Debuff ikonları kırmızı, buff yeşil kenarlık
- [ ] Kendi karakterinde nameplate yok

### Boss

- [ ] Boss (`The Eye`) — büyük nameplate, **Phase** etiketi (`P1`/`P2`)
- [ ] Boss HP: **% + mutlak** (`45% (45000/100000)`)
- [ ] Tentacle add — küçük `BossAdd` nameplate
- [ ] Boss üstü status ikonları (Wet/Ignite test)
- [ ] Ekran `BossHud` hâlâ çalışır (nameplate ek katman)

---

## V. F1 — Synergy & combat polish

### GearUI — synergy band

- [ ] Stats paneli **SYNERGY** başlığı görünür
- [ ] Band adı + renk: `Pure (Fire)` / `Duality (Fire · Water)` / `Harmony` / `Unbound` / `None`
- [ ] Perk satırı: örn. `Guaranteed Ignite · +15% duration` (Pure Fire)
- [ ] Loadout değişince (gem / off / chest) band anında güncellenir

### Pure x3 on-hit (CHEMISTRY_ENGINE §3.4)

- [ ] Pure x3 loadout → LA her vuruşta imza status (off-hand LA hariç)
- [ ] Pure Water → birincil hedef Wet + 8 stud içindeki diğer hedefler Wet
- [ ] Pure Wind → Windy süre +20% · slow %33 (`slowPct` params)
- [ ] Pure Poison → Poisoned +1 DPS
- [ ] Pure Steel → Bleed +1s
- [ ] Helm Pulse farklı elemente çevirirse o vuruş Pure perk almaz

### Diğer F1

- [ ] Duality → +5% Defence / +5% Resist (derived panel)
- [ ] Harmony → +15 Status Potency
- [ ] Unbound (Neutral ×3) → +5% direct · +10% def · +12% resist
- [ ] CC diminishing: aynı kaynak Stun spam → süre yarıya iner
- [ ] Off-hand ability damage ×0.5
- [ ] Maç sonu HP + stamina + status temizlenir

---

## W. F3 — Ranked & spectate

- [ ] `pvp_1v1_ranked` queue → maç sonu **MMR delta** loot modalda
- [ ] Ranked gas: 180s combat · 200s shrink · 230s cap
- [ ] 2v2/3v3 ölünce spectate kamera (ally öncelik)
- [ ] Queue sırasında loadout kilitli (equip engeli)

---

## X. F4 — Meta (tutorial / shop / upgrade)

- [ ] Tutorial hint (sağ üst) · **I** / **J** adımları
- [ ] **B** → Shop panel · premium harcama
- [ ] GearUI → **WeaponBlade** seç → **Upgrade** butonu görünür
- [ ] Upgrade: premium düşer · blade `+level` artar · detail’de `Upgrade: +N`
- [ ] Equipped frame DMG artar (blade upgrade → `WeaponResolver` +%3/level)
- [ ] MAX level (5) → buton gri · `MAX` metni
- [ ] Frame / handle / pommel / gem → Upgrade butonu **görünmez**
- [ ] `MetaRemotes.UpgradeItem` — sunucu doğrulama (sadece blade)
- [ ] Profile schema **v4**: `pvpMmr`, `tutorialFlags`

---

## Y. F5 — MVP test set

- [ ] F8 veya `GrantMvpLoadout` → steel set + sword parçaları
- [ ] `MVP_CONTENT.md` reaction matrisi dolduruldu (referans)
- [ ] Full checklist A→X tek playtest pass

---

## Z. Dungeon stub (post-boss)

- [ ] `DungeonRunService` — 3 greybox oda + boss handoff
- [ ] *(Canlı queue henüz yok — dev hook only)*

---

## Place projeleri (Rojo)

| Place | Project |
|-------|---------|
| Lobby | `default.project.json` veya `places/lobby.project.json` |
| Duel Pit | `places/pvp_1v1.project.json` |
| Skirmish | `places/pvp_2v2.project.json` |
| Clash Ring | `places/pvp_3v3.project.json` |
| The Eye | `places/pve_boss_eye.project.json` |

`PlaceConfig.luau` → Creator PlaceId'leri doldur.
