# Combat Stat Sheet — Kilit v1

> Third-person action, gear-based build, no class.  
> Kimya motoru: `CHEMISTRY_ENGINE.md`  
> Armour stat **yok** — yalnızca **Defence** (sayı) ve tooltip **DR%**.

---

## 1. Level & Primary Stats

| Kural | Değer |
|-------|--------|
| Primary statlar | **STR**, **DEX**, **VIT**, **INT** |
| Level başına | **+4** point (dağıtılır) |
| Class | Yok |

### Primary → Secondary (kaynak)

| Primary | Beslediği secondary | Verilmez |
|---------|---------------------|----------|
| **STR** | Crit Damage; STR silah Damage scaling | — |
| **DEX** | Attack Speed, Crit Chance; DEX silah scaling | — |
| **VIT** | HP, Stamina (max), Stamina regen; **az** Defence; **az** Resist | — |
| **INT** | Status Potency; **az** Buff Potency (herkeste); INT silah scaling | — |

**Defence & Resist ana kaynağı:** ekipman (`+Defence`, `+Resist`, stat requirement). VIT küçük katkı (Defence: `VIT × k_vit_def`; Resist: `VIT × k_vit_res` — playtest).

**Ekipman denge:** Tank yüksek Defence / düşük Resist; büyücü düşük Defence / yüksek Resist — **manuel item tablosu**. VIT her ikisine az verir; asıl fark zırh seçiminden gelir.

---

## 2. Secondary Stats

| # | Stat | Açıklama |
|---|------|----------|
| 1 | **Damage** | Light attack + hasar veren yetenekler (türetilmiş önizleme) |
| 2 | **Attack Speed** | Light attack sıklığı |
| 3 | **Stamina** | **Yalnız** Guard / Parry / Dodge / Sprint — yetenek **stam harcamaz** |
| 4 | **HP** | Can |
| 5 | **Defence** | Ham stat; tooltip’te DR% |
| 6 | **Resist** | Ham stat; tooltip’te etki % |
| 7 | **Status Potency** | Debuff / DoT **süresini** uzatır (hasar değil) |
| 8 | **Crit Chance** | Light attack crit ihtimali |
| 9 | **Crit Damage** | Crit çarpanı |
| 10 | **Buff Potency** | Heal / buff miktarı ve süresi |

---

## 3. Damage

Tek hasar hattı (Physical / Magical ayrımı yok).

```
Hit Damage = Weapon Base
           × (1 + ScalingStat × k_dmg)
           × (1 + Gear Damage%)
           × Crit multiplier (if crit)

ScalingStat = STR | DEX | INT  (silah pure scaling)
```

| Scaling | Silahlar |
|---------|----------|
| STR | 1H/2H Sword, Axe, Mace |
| DEX | Dagger, Bow, Crossbow |
| INT | Wand, Staff, Scepter |

**DoT / statü tick:** Damage hattından ayrı → Status Potency + base kimya tablosu.

---

## 4. Defence & DR (kilit)

```
Defence = base + (VIT × k_vit_def) + Σ gear_Defence

DR% = min( Defence × 0.1 + flat_DR%_from_gear , CAP )
effective_DR% = DR% × (1 - defence_shred%)    // Mace ailesi vb.

damage_taken = raw_damage × (1 - effective_DR% / 100)
```

| Sabit | Değer |
|-------|--------|
| **1 Defence** | **+0.1% DR** (`k_dr = 0.1`) |
| **CAP (PvP)** | **70%** |
| **CAP (PvE)** | **75%** (isteğe bağlı mod) |

### UI

| Stat | Ana satır | Tooltip |
|------|-----------|---------|
| Defence | `Defence: 340` | `Damage Reduction: 34%` |

### Örnek tablo (`flat_DR% = 0`)

| Defence | DR% |
|---------|-----|
| 100 | 10% |
| 200 | 20% |
| 340 | 34% |
| 500 | 50% |
| 700 | 70% (cap) |

**Mace — Defence Shred:** `effective_DR% = DR% × (1 - shred%)` — 1H %25, 2H %40 (placeholder).

---

## 5. Resist

```
Resist = base_resist + (VIT × k_vit_res) + Σ gear_Resist

effect% = Resist / (Resist + C_res)

applied_effect = raw_effect × (1 - effect%)
```

**Etki:** DoT hasarı ve burst azaltma; CC / slow / setup **süresi** kısaltma. Aynı `effect%` hem süre hem hasara uygulanır.

```
resist_effect% = Resist / (Resist + C_res)
final_duration = base × (1 + potency × k_pot_duration) × (1 - resist_effect%)
final_damage   = base_damage × (1 - resist_effect%)
```

| Sabit | Değer |
|-------|--------|
| `k_vit_res` | **0.25** / VIT |
| `C_res` | **165** |
| `base_resist` | **0** |

### UI

| Stat | Ana satır | Tooltip |
|------|-----------|---------|
| Resist | `Resist: 120` | `Effect Reduction: 42%` (+ hangi etkiler) |

---

## 6. Crit & Attack Speed

```
Attack Speed Mult = min( Weapon Tier Mult × (1 + DEX × k_dex_as + gear%), AS_CAP )

Crit Chance% = min( base_crit + DEX × k_dex_crit + gear, CRIT_CHANCE_CAP )

Crit Damage% = min( base_crit_dmg + STR × k_str_crit_dmg + gear, CRIT_DMG_CAP )
crit_multiplier = Crit Damage% / 100
```

| Sabit | Değer |
|-------|--------|
| `k_dex_as` | **0.0035** / DEX (~+35% hız @ 100 DEX) |
| `AS_CAP` | **1.45** (tier üstü çarpan tavanı) |
| `base_crit` | **5%** |
| `k_dex_crit` | **0.12** / DEX (yüzde puanı) |
| `CRIT_CHANCE_CAP` | **60%** |
| `base_crit_dmg` | **150%** (1.5×) |
| `k_str_crit_dmg` | **0.4** / STR (yüzde puanı) |
| `CRIT_DMG_CAP` | **250%** |

| Silah perk | Bonus |
|------------|--------|
| Bow | +Crit Chance |
| Crossbow | +Crit Damage |

---

## 7. Status Potency & Buff Potency

```
Status_Potency = INT × k_int_potency + gear + wand/staff perk + Harmony (+15)
Buff_Potency   = base_buff_potency + INT × k_int_buff + gear + scepter perk

-- Süre (DoT dahil):
status_duration = base_duration × (1 + Status_Potency × k_pot_duration) × (1 - resist_duration)

-- Hasar (DoT DPS, burst, reaksiyon hasarı):
ignite_dps  = (IGNITE_BASE + gear_ignite_dps) × (1 - resist_damage)
poison_dps  = (POISON_BASE + gear_poison_dps) × (1 - resist_damage)
bleed_dps   = (BLEED_BASE  + gear_bleed_dps)  × (1 - resist_damage)
burst_damage = burst_base × (1 - resist_damage)

-- Heal / buff:
heal_amount   = base_heal × (1 + Buff_Potency × k_buff_heal)
buff_duration = base_buff_dur × (1 + Buff_Potency × k_buff_duration)
```

| Sabit | Değer |
|-------|--------|
| `k_int_potency` | **0.8** / INT |
| `k_pot_duration` | **0.004** (Potency 60 → +24% süre) |
| `IGNITE_BASE` | **7** DPS · **3s** |
| `POISON_BASE` | **3** DPS · **5s** |
| `BLEED_BASE` | **4** DPS · **8s** |
| `base_buff_potency` | **8** (her karakter) |
| `k_int_buff` | **0.5** / INT |
| `k_buff_heal` | **0.01** |
| `k_buff_duration` | **0.008** |

Tam süreler ve reaksiyon sabitleri → **`STATUS_SYSTEM.md` §4**.

| Silah | Perk |
|-------|------|
| Wand | +Status Potency |
| Staff | +Status Potency (yüksek) |
| Scepter | +Buff Potency |

---

## 8. Silahlar (pure scaling + perk)

### Attack Speed tier

| Tier | Mult | Silahlar |
|------|------|----------|
| S | 0.70 | 2H Mace, Crossbow |
| A | 0.85 | 1H Mace, **2H Axe** |
| B | 1.00 | **1H Axe**, 2H Sword, **Staff** |
| C | 1.15 | 1H Sword, Bow |
| D | 1.30 | Dagger, Wand |
| E | 1.10 | Scepter |

### Roster & perk

| Silah | Scale | Perk | Light attack |
|-------|-------|------|--------------|
| Dagger | DEX | Backstab (arkadan bonus hasar) | Melee combo |
| 1H Sword | STR | **Measured Strike** (L3 +%35 hasar — kılıç ailesi) | Melee combo |
| 1H Axe | STR | Rakip guard/parry → hedef ekstra Stamina damage | Melee combo |
| 1H Mace | STR | Defence Shred | Melee combo |
| **Wand** | INT | +Status Potency | **1H** projectile combo; kısa menzil |
| **Scepter** | INT | +Buff Potency | **1H** **cone** combo; wand'dan kısa menzil, düşük hasar |
| Bow | DEX | +Crit Chance | Ranged combo |
| Crossbow | DEX | +Crit Damage; **L3 sonrası reload anim** | Ranged combo |
| 2H Sword | STR | Measured Strike (L3 +%40 hasar) | Melee combo |
| 2H Axe | STR | Anti-guard stamina (artmış) | Melee combo |
| 2H Mace | STR | Defence Shred (yüksek) | Melee combo |
| **Staff** | INT | +Status Potency++ | **2H** projectile combo; uzun menzil, yüksek hasar |

**INT main-hand profilleri (kilit):**

| Silah | El | Weapon base (tier 1) | LA menzil | LA tipi |
|-------|-----|----------------------|-----------|---------|
| **Wand** | 1H | 28–32 | **~22** stud | Tek projectile |
| **Staff** | 2H | 44–48 | **~30** stud | Tek projectile |
| **Scepter** | 1H | 26–30 | **~16** stud | **Cone ~45°** (çoklu hedef LA; max **3** hedef) |

Sinerji ağırlığı: Staff main = **×2** (2H); Wand / Scepter main = **×1** (1H). **Harmony** (1+1+1) yalnızca Main **×1** ile; tüm **×2 main** (2H / Staff / Bow / Crossbow) matematiksel olarak **imkânsız**.

**Cone on-hit (kilit):** Scepter (ve benzeri AoE LA) her hedefe ayrı hasar instance. On-hit affix / Pure x3 **hedef başına bir kez** (max 3). Crit **hedef başına ayrı roll**.

---

## 9. Off-hand & Loadout (özet)

Tam slot / yetenek kuralları → **`GDD.md` §5**.

### Shield (Guard — sağ tık)

Stability **yok**.

| Tip | Drain/s | Guard slow | Chip (blocklanan hasarın alınan kısmı) |
|-----|---------|------------|------------------------------------------|
| Buckler | 0.5 | 10% | 60% |
| Kite | 1.0 | 20% | 40% |
| Tower | 1.5 | 30% | 30% |

Guard genel: vuruşta ek stamina maliyeti; açıkken regen yok. Stamina 0 → guard break → `GDD.md` §8 (pasif drain: Slow 50%; vuruş: **Stun 0.75s** — ekstra hasar debuff **yok**).

### Off-hand 1H (dual wield — STR/DEX)

| Kural | Değer |
|-------|--------|
| Light attack | Çift vuruş; on-hit main tam · off **%50** proc |
| Pasif / perk | Off-hand **%50** |
| Aktif | Kullanılabilir; etki **%50** |

Dual damage çarpanı: Main **×1.0** · Off **×0.65** (`§11b`).

**Denge hedefi (kilit):** Dual wield DPS bandı **2H ile eşit / ±1 isabet**; **1H + Shield** ve **1H + Focus**'tan **belirgin şekilde yüksek** burst DPS. Savunma loadout'ları (kalkan, utility) DPS karşılığında hayatta kalma ve kontrol satın alır.

### Off-hand Wand / Scepter (INT dual)

| Kural | Değer |
|-------|--------|
| Light attack | **Yok** |
| Pasif / perk | Off-hand **%50** |
| Aktif | Kullanılabilir; hasar / heal / buff / status **%50**; INT scale |

### Weapon Knot / Quiver / Focus

Knot / Quiver: tagsiz pasif veya stat. Focus: utility; **%50 kuralına girmez**. §7 GDD.

---

## 10. Stamina & Savunma aksiyonları

### Dodge

- Yönlü sıçrama + kısa i-frame; flat stamina cost.
- Bitince: dodge yok; **kısa recovery (~0.2–0.3s)**.
- Stamina bitince ek ceza yok.

### Sprint

- Basılı tutunca drain; bitince sprint kesilir.

### Parry

| Loadout | Parry | Fail maliyeti |
|---------|-------|----------------|
| 1H band (1H / dual / focus / wand…) | ✅ | Max stamina **%50** |
| 2H band (2H / Staff / Bow / Crossbow) | ✅ | Max stamina **%75** |
| Shield | ❌ (Guard) | — |

- Stance: pasif drain yok; **%20 slow**; regen yok.
- Perfect window **0.28s** → düşman **Stun 1s**; hasar 0; on-hit yok.
- Fail (perfect değil) → maliyet + parry kapanır; hasar normal.
- Stance sırasında stamina 0 → sen **Stun 1s**.

---

## 11. Hasar pipeline (kilit v1)

Tek referans. `GDD.md` §8 · `STATUS_SYSTEM.md` §6.4 bu sırayı kullanır.

**Bölüm sırası (okuma):** §11.1 Direct → §11.2 Crit → §11.3 Stance → §11.4 Guard → §11.5 DoT → §11.6 Combo → §11.7 Yetenek → §11.8 DirectBonus/Backstab → §11.9 Environmental → §11.10 Execute → §11b Dual.

### 11.1 Direct damage (light attack, yetenek patlaması)

```
1. Crit roll                    — §11.2 (uygunsa)
2. raw_base                     — §11.7 (LA veya yetenek %)
3. raw_after_perks              = raw_base
                                  × ComboStep (§11.6 — L2/L3 global bonus)
                                  × FamilyPerk (§11.6 — L3; Measured Strike yalnız kılıç)
                                  × Backstab (§11.8, Dagger arka 180°)
                                  × DirectBonusMult (§11.8 — Unbound, Rock Pure, ileride ek bonuslar)
4. after_matchup                = raw_after_perks × ElementMatchup(main → chest)
5. after_dr                     = after_matchup × (1 - effective_DR% / 100)
6. Defensive stance             — §11.3 (Dodge → Parry → Guard)
7. HP / chip                    — guard: yalnızca chip (§11.4); aksi halde after_dr → HP
8. On-hit status                — §11.4 (guard block’ta YOK)
9. ReactionResolver             — `CHEMISTRY_ENGINE.md` §5.4
```

**Matchup uygulanmaz:** DoT tick, reaksiyon burst, guard chip, heal, **Environmental**, **Execute**.

**Guard açısı:** Saldıran → savunan ön **180°** yayı. Arkadan gelen direct hasar guard’tan geçmez (tam `after_dr` + on-hit **evet**).

### 11.7 Yetenek hasarı (kilit)

Yetenekler **weapon base** üzerinden ölçeklenir; tasarım **ability_pct** ile (ör. **140%** = `1.4`, **300%** = `3.0`).

```
ability_raw_base = WeaponBase × ability_pct × (1 + Scaling × k_dmg) × (1 + gear%) × crit_mult
```

- `WeaponBase` = **main-hand** silahın base damage’i (off-hand Wand/Scepter aktifleri main INT silahına bağlanır).
- `ability_pct` → `AbilityDefs` tablosu (ör. Staff Firebolt `1.4`, ulti `3.0`).
- Adım 3–9: light attack ile **aynı pipeline** (ComboStep + aile L3 perk'leri yalnızca LA'da; backstab yetenekte dagger + arka açı ise evet).

### 11.8 Direct bonus çarpanları & Backstab (kilit)

**DirectBonusMult** — çarpımsal yığın; ileride yeni % direct bonuslar buraya eklenir:

| Kaynak | Koşul | Çarpan |
|--------|-------|--------|
| **Unbound** (Pure Neutral) | Sinerji bandı aktif | **×1.05** |
| **Rock Pure x3** (Seismic) | Hedefte **Slow** aktif | **×1.05** |
| *(ileride)* | Affix / rün / sezon | tabloya satır ekle |

```
DirectBonusMult = Π (aktif bonus çarpanları)    -- örn. Unbound + Rock vs Slow = ×1.05 × 1.05
```

**Dagger — Backstab:**

| Kural | Değer |
|-------|--------|
| Açı | Savunanın **ön 180°** dışı = **arka 180°** (yan gradyan **yok**) |
| Çarpan | `k_backstab` = **×1.30** (playtest) |
| Pipeline | `raw_after_perks` içinde, **matchup öncesi** |

**Measured Strike** (kılıç ailesi — L3 aile perk'i): 1H **×1.35** · 2H **×1.40** — `FamilyPerk` çarpanı; global L3 ComboStep ile **çarpılır**. Sayaç **silah başına global** (hedef başına değil). Guard block sayılır; combo window kaçırılırsa sıfırlanır — **matchup öncesi** `raw_after_perks` içinde.

### 11.6 Light attack & 3 vuruşluk combo (kilit v3)

**Tüm silahlar** (melee + ranged + INT) aynı combo iskeletini kullanır: **L1 → L2 → L3 (finisher)**.

| Kural | Değer |
|-------|--------|
| Combo zinciri | **L1 → L2 → L3** — global sayaç (**silah / yük başına**, hedef başına değil) |
| Sayaç ilerletir | **Isabetli** LA **veya** ön 180° **guard block** (chip dahil) |
| Sayaç ilerletmez | Miss / whiff |
| Combo window | Önceki vuruş bitiminden **0.6s** — kaçırırsan **L1'e döner** |
| Hit recovery | `0.15 / AttackSpeedMult` sn (aşağıda) |
| Poise / hyperarmor | MVP'de **yok** |

```
AttackSpeedMult = min(tier_mult × (1 + DEX × k_dex_as), AS_CAP)
hit_recovery    = 0.15 / AttackSpeedMult
-- örn. tier C (1.15), DEX 0 → ~0.130s; DEX 100 → ~1.35× → ~0.096s
```

#### Global combo bonusları (tüm silahlar)

| Adım | Direct hasar | Game feel |
|------|--------------|-----------|
| **L1** | ×1.00 | Normal anim |
| **L2** | ×**1.05** | Hafif hit-stop (~50ms) — playtest |
| **L3** | ×**1.10** | Tok anim + hit-stop **~100ms** + **camera shake** |

`ComboStep` çarpanı pipeline adım 3'te uygulanır. Guard chip, `after_dr` üzerinden olduğu için L2/L3 bonusları chip'i de büyütür — **bilinçli** (ritim ödülü).

Aile perk'leri (Measured Strike vb.) **ayrı `FamilyPerk` çarpanı** olarak yalnızca L3'te eklenir.

#### Hareket hızı (combo sırasında — kilit)

| Adım | Move speed | Not |
|------|------------|-----|
| **L1** | **%90** | Hafif yavaşlama |
| **L2** | **%75** | |
| **L3** windup | **%50** | **Anim root motion** step/lunge; ekstra velocity **yok** (çift hız / buz pateni yok) |

`StatusQuery.GetMoveSpeedMult` combo adımına göre okunur. Step displacement yalnızca animasyon root motion'dan gelir.

#### Silah ailesi — L3 finisher & anim (örnekler)

| Aile | L3 anim / davranış | L3 aile perk'i (FamilyPerk) |
|------|---------------------|-----------------------------|
| **1H / 2H Sword** | Tok slash | **Measured Strike** ×1.35 / ×1.40 |
| **Bow** | Kısa **geriye sıçrama** + havada **düz atış** | **Focused Shot** ×1.25 + delme (1 hedef) |
| **Staff** (2H) | Yüksek güçlü bolt | **Empowered Bolt** ×1.30; bu isabette on-hit Potency **+15%** |
| **Wand** (1H) | Hızlı bolt | **Arc Bolt** ×1.20 |
| **Scepter** (1H) | Geniş **cone** sweep | **Radiant Sweep** ×1.25; cone açısı L3'te **+15°** |
| **Crossbow** | Ağır cıvata | **Heavy Bolt** ×**1.40** → ardından **reload anim** (~**1.2s**, LA kilit) |
| **Dagger / Axe / Mace** | Aile anim | Global L3 bonus yeterli; **Backstab** / anti-guard / shred ayrı perk |

**Crossbow reload:** Yalnızca **L3 tamamlandıktan sonra** zorunlu reload; L1–L2 arası reload **yok**. Combo window kaçırılırsa sayaç L1'e döner, reload tetiklenmez. L3 toplam direct çarpan = ×1.10 × ×1.40 = **×1.54**.

#### Menzil özeti

| Tip | Menzil / hitbox |
|-----|-----------------|
| Melee | ~**6** stud hitbox |
| Bow | ~**28** stud projectile |
| Crossbow | ~**26** stud projectile |
| Staff | ~**30** stud projectile |
| Wand | ~**22** stud projectile |
| Scepter | ~**16** stud cone **~45°** · max **3** hedef |

**Hit stop:** L3 isabetinde saldıran + hedef ~100ms freeze; L2 opsiyonel ~50ms.

### 11.9 Environmental hasar (kilit — tek çatı)

Gaz, boss aura, Monolith aura vb. **aynı kanal**: `kind = Environmental`.

| Kural | Değer |
|-------|--------|
| DR / matchup / crit | **Yok** |
| Resist | **Yok** (çevre / boss hazard) |
| Uygulama | `EnvironmentDamageService` → `DamageService` |
| Örnek | PvP gaz DPS, Monolith aura DPS, Wild Fire çevre tick |

```
environmental_tick = flat_dps × dt    -- veya zone tanımından
```

### 11.10 Execute (kilit)

Tek atışlık ölüm mekanikleri — DR / Resist / guard **yok**; hedef **anında ölür**.

| Örnek | Kaynak |
|-------|--------|
| Monolith düşüş alanı | The Eye P2 |
| Gaze LOS fail | The Eye P2 cast sonu |
| *(ileride)* | Boss telegraph “wipe” |

```lua
-- DamageService: kind == "Execute" → defender.HP = 0; return
```

**Environmental ≠ Execute:** Environmental süreli DPS; Execute tek frame wipe.

### 11.2 Crit kuralları (kilit)

| Kaynak | Crit? | Not |
|--------|-------|-----|
| Light attack | Evet | DEX chance · STR damage |
| Direct damage yeteneği | Evet | Tek patlama; crit bir kez |
| Multi-hit yetenek | **İlk hasar instance** | Sonraki tick/hit crit almaz |
| DoT uygulama / tick | Hayır | |
| Reaksiyon burst (Vaporize vb.) | Hayır | Kalan DoT'tan türetilir |
| Heal / buff | Hayır | Buff Potency kullanır |
| Guard chip | Hayır | `after_dr` üzerinden sabit % |

### 11.3 Defensive stance sırası

Aynı vuruşta yalnızca **bir** savunma kazanır (öncelik sırası):

| # | Stance | Sonuç |
|---|--------|--------|
| 1 | **Dodge** (i-frame aktif) | Hasar **0**; stamina maliyeti; on-hit yok |
| 2 | **Parry** (perfect pencere) | Hasar **0**; saldıran **Stun 1s**; on-hit yok |
| 3 | **Guard** (ön 180°, shield) | Chip + stamina; **on-hit yok**; §11.4 |
| — | Yok | `after_dr` → HP; on-hit **evet** |

Dodge / perfect parry: hasar **0**, on-hit **yok**. Parry fail: normal chip/HP akışı.

### 11.4 Guard — chip, on-hit & stamina (kilit)

Tüm chip hesapları **`after_dr`** (matchup + DR sonrası) üzerinden:

```
chip_damage    = after_dr × shield_chip%        // Kite 40%, Tower 30%, Buckler 60%
stamina_hit    = max(8, after_dr × 0.12)        // Axe perk: ×1.25
stamina_passive = shield_drain_per_sec × dt      // Kite 1.0/s, Buckler 0.5/s, Tower 1.5/s
```

- Chip → HP (DR tekrar uygulanmaz). Chip, `after_dr` üzerinden → ComboStep / FamilyPerk chip'i de etkiler (**bilinçli**).
- Guard block (ön 180°): on-hit affix / Pure x3 **uygulanmaz**; yalnızca chip.
- Arkadan vuruş: guard geçersiz; tam `after_dr` + on-hit.
- Guard açıkken stamina regen **yok**.
- Stamina **0** → guard break → **Stun 0.75s** — ekstra hasar debuff **yok** (`GDD.md` §8).
- Guard block combo sayacını **ilerletir** (§11.6).

### 11.5 DoT / reaksiyon hasarı (ayrı kanal)

```
dot_tick = (dot_base + affix_dps) × (1 - resist_effect%)     // DR yok, matchup yok, crit yok
burst    = burst_base × (1 - resist_effect%)               // Vaporize, Cauterize burst vb.
```

Süre: Potency (saldıran) → Resist (hedef) — `STATUS_SYSTEM.md` §1.3.

---

## 11b. Dual wield hasar (post-MVP tasarım — çarpan kilit v3)

Her light attack = **2 ayrı hitbox** (main + off) ama hasar pipeline'da **tek DR paketi**. Combo sayacı **tek** (L1→L2→L3); çift vuruş aynı combo adımını ilerletir.

```
combined_raw = (main_formula × 1.0) + (off_formula × 0.65)
after_dr     = combined_raw × (1 - DR%)          // DR tek sefer uygulanır
```

- Attack Speed: **main** silah tier'ı geçerli.
- Light attack anim süresi: tek 1H swing'e göre **~×1.25** (çift vuruş).
- **On-hit affix (kilit):** Main = **tam roll**. Off-hand = **ayrı roll**, affix proc şansının **%50'si** (garanti on-hit ise off **%50** uygulama şansı). Status uygulama hızı 2H bandına yaklaşır; çift affix spam engellenir.
- Off-hand base farklı olabilir (ayrı Weapon Base).
- **Denge hedefi:** TTK bandı **2H ile eşit / ±1 isabet**; **1H + Shield** ve **1H + Focus**'tan **~%25–35** yüksek burst DPS.
- **Neden tek DR?** İki ayrı DR uygulaması dual wield'ı yüksek zırhlı hedeflere karşı orantısız cezalandırır.

---

## 12. k katsayıları (kilit v1)

### 12.1 Level ekonomisi

| Sabit | Değer |
|-------|--------|
| Başlangıç (Lv1) | STR/DEX/VIT/INT **10** each |
| Max level | **50** |
| Point / level | **+4** |
| Toplam dağıtılabilir (Lv50) | **196** point |

### 12.2 Hasar

| Sabit | Değer | Not |
|-------|--------|-----|
| `k_dmg` | **0.012** / stat | Orta TTK; +80 stat ≈ **+96%** hasar |

```
Damage mult = 1 + ScalingStat × 0.012
```

### 12.3 VIT — dayanıklılık

| Sabit | Değer | Not |
|-------|--------|-----|
| `base_hp` | **120** | Orta TTK — erken ölüm az |
| `k_vit_hp` | **10** / VIT | VIT 80 → **920** HP from stat |
| `base_stam` | **100** | |
| `k_vit_stam` | **2** / VIT | VIT 70 → **240** max stamina |
| `k_vit_def` | **0.25** / VIT | VIT 40 → **+10 Defence** (1% DR) |
| `k_vit_res` | **0.25** / VIT | VIT 70 → **+17.5 Resist** (~10% effect) |
| `stam_regen_combat` | **8** / s | guard/parry dışında |
| `k_vit_regen` | **0.08** / VIT / s | VIT 70 → **+5.6** regen |

```
HP       = base_hp + VIT × 10 + gear    -- base_hp = 120
Stamina  = base_stam + VIT × 2 + gear
Defence += VIT × 0.25   (küçük; ana kaynak gear)
```

### 12.4 Savunma (özet)

| Sabit | Değer |
|-------|--------|
| `k_dr` | **0.1** (% DR per Defence) |
| `CAP` PvP | **70%** |
| `CAP` PvE | **75%** |
| Mace shred 1H / 2H | **25%** / **40%** |

### 12.5 Resist

| Sabit | Değer |
|-------|--------|
| `k_vit_res` | **0.25** / VIT |
| `C_res` | **165** |
| `base_resist` | **0** |

*Resist çoğunluğu ekipmandan gelir; VIT küçük katkı sağlar (VIT 70 → +17.5 Resist).*

| Resist | effect% |
|--------|---------|
| 60 | 27% |
| 120 | 42% |
| 180 | 52% |

### 12.6 Crit & hız

Bkz. §6 tablosu (`k_dex_as` 0.0035, `k_dex_crit` 0.12, `k_str_crit_dmg` 0.4, cap 60% / 250%).

### 12.7 Potency

Bkz. §7 tablosu.

### 12.8 Stamina aksiyon maliyetleri (placeholder)

**Kural:** Aktif yetenekler stamina **harcamaz** (yalnız CD).

| Aksiyon | Maliyet |
|---------|---------|
| Dodge | **18** flat + recovery 0.25s |
| Sprint | **12** / s |
| Guard vuruş | `max(8, after_dr × 0.12)` stamina (`§11.4`) |
| Axe vs guard | vuruş maliyeti × **1.25** |
| Aktif yetenek | **0** stam |

### 12.9 Örnek build — Lv50 (gear hariç)

| Build | Dağılım | Öne çıkan |
|-------|---------|-----------|
| **2H Mace** | STR 100, VIT 70, DEX 20, INT 6 | HP 920, Stam 240, dmg ×1.75 |
| **Bow** | DEX 100, STR 20, VIT 50, INT 26 | Crit 17%, AS ×1.35×tier |
| **Staff** | INT 90, VIT 40, DEX 30, STR 36 | Potency 72, +3.6 ignite DPS; Resist from VIT+gear |
| **Sword+shield** | STR 70, VIT 90, DEX 30, INT 16 | HP 1120, +22 Defence from VIT |

*Gear ile tank ~300–500 Defence (30–50% DR); mage robe ~40 Def + 80 Resist.*

### 12.10 Silah base damage (gear tier 1 placeholder)

| Tier | Weapon Base (ör.) |
|------|-------------------|
| Dagger / Wand / Scepter | 26–32 |
| 1H Sword / Bow | 38–42 |
| 1H Axe / **Staff** (2H) | 44–48 |
| 1H Mace / 2H Sword | 48–52 |
| 2H Mace / Crossbow | 55–62 |

### 12.10b Zırh Def / Res oranı (tier 1 — silah bandına göre)

Referans: orta 1H Sword base **~40**. Tank chest ≈ **2×** bu değer.

| Slot | Defence (tank eğilim) | Resist (tank) | Not |
|------|------------------------|---------------|-----|
| **Chest** | **80** (~2.0× W) | **20** | Ana dayanıklılık |
| **Head** | **16** (~0.4× W) | **5** | |
| **Feets** | **14** (~0.35× W) | **10** | |
| **Hands** | **5** (~0.12× W) | **8** | Düşük Def; utility / Resist biraz daha |

*Mage seti tersine çevrilir (düşük Def, yüksek Res). Sayılar playtest ile kaydırılır; oran iskeleti sabit kalır.*

### 12.11 TTK hedefi (kilit v2)

**Hedef:** Orta TTK — **dümdüz combo spam** ile orta gear’da **~10–12 isabet** (3–4 full combo). Guard / dodge / parry ile pratik maç **doğal uzar**.

**Neden 10–12?** Daha tok vuruş hissi; 3 swing mini-combo + L3 finisher ritmi; sıkıcı clickfest riski düşer.

| Profil | Beklenen süre (1v1, orta gear) |
|--------|--------------------------------|
| Spam vs spam (savunma yok) | **8–12 sn** |
| Ortalama vs ortalama | **15–25 sn** |
| İyi vs iyi | **25–40+ sn** |
| Burst (crit + kimya) | Kısa pencerede **%35–50 HP** — comeback mümkün |

**TTK knob’ları (öncelik):**
1. ase_hp / k_vit_hp — genel süre  
2. k_dmg / weapon base — burst  
3. DR CAP — tank tavanı  
4. Stamina maliyetleri — skill ifadesi (uzatır)

**Kilit profil:** ase_hp 120, k_dmg 0.012, k_dr 0.1, cap %70.

**Orta gear tanımı (TTK referansı):** Lv **30**, VIT **60**, tier-1 kılıç (base **40**) + tier-1 chest (**+80 Defence**). Toplam Defence ≈ **295** → DR **29.5%**. HP ≈ **720**.

| Profil | Raw/hit (STR 70) | Efektif/hit (DR 29.5%) | Hit to kill (720 HP) |
|--------|------------------|------------------------|----------------------|
| Orta DPS | ~77 | ~54 | **~13** |
| Yüksek DPS (STR 90, +gear%) | ~96 | ~68 | **~11** |
| Burst pencere (kimya + crit) | — | ~300–360 HP | **2–3** exchange |

*Hedef bandı **10–12 orta gear hit** — 3–4 full combo; guard/dodge ile pratik TTK 15–25 sn.*

---

| Sistem | MVP | Later |
|--------|-----|-------|
| 4 primary + sheet formülleri | ✅ | — |
| Defence 0.1%/def + cap | ✅ | — |
| Sword / Axe / Staff / Bow + Kite shield | ✅ | 3 shield tipi |
| Kimya (10 reaksiyon + status) | ✅ | Sinerji setleri |
| Dodge + Guard + Parry | ✅ | Perfect window 0.28s · fail %50/75 |
| Dual wield | — | ✅ |
| Knot | — | ✅ |
| Focus | — | ✅ |
| 2v2 / 3v3 | — | ✅ |

---

*Son güncelleme: 2026-07 — combo v3, FIFO batch, k_dmg 0.012 hizası, dual off-proc %50, Staff tier B, axe ×1.25, Crossbow L3 ×1.40 / reload 1.2s, cone max 3.*
