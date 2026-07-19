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
| **STR** | Crit Damage; STR silah Damage scaling | Defence |
| **DEX** | Attack Speed, Crit Chance; DEX silah scaling | — |
| **VIT** | HP, Stamina (max), Stamina regen; **az** Defence | — |
| **INT** | Resist, Status Potency; **az** Buff Potency (herkeste); INT silah scaling | — |

**Defence ana kaynağı:** ekipman (`+Defence`, stat requirement). VIT küçük katkı (`VIT × k_vit_def` — playtest).

**Ekipman denge:** Tank yüksek Defence / düşük Resist; büyücü düşük Defence / yüksek Resist — **manuel item tablosu**.

---

## 2. Secondary Stats

| # | Stat | Açıklama |
|---|------|----------|
| 1 | **Damage** | Light attack + hasar veren yetenekler (türetilmiş önizleme) |
| 2 | **Attack Speed** | Light attack sıklığı |
| 3 | **Stamina** | Guard / Parry / Dodge / Sprint havuzu |
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
Resist = base_resist + (INT × k_int_res) + Σ gear_Resist

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
| `k_int_res` | **1.25** / INT |
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
| B | 1.00 | **1H Axe**, 2H Sword |
| C | 1.15 | 1H Sword, Bow, Staff |
| D | 1.30 | Dagger, Wand |
| E | 1.10 | Scepter |

### Roster & perk

| Silah | Scale | Perk |
|-------|-------|------|
| Dagger | DEX | Backstab (arkadan bonus hasar) |
| 1H Sword | STR | **Measured Strike** (hedef başına 3. hit +%35; guard sayılır; ~1s timeout) |
| 1H Axe | STR | Rakip guard/parry → hedef ekstra Stamina damage |
| 1H Mace | STR | Defence Shred |
| Wand | INT | +Status Potency |
| Scepter | INT | +Buff Potency |
| Bow | DEX | +Crit Chance |
| Crossbow | DEX | +Crit Damage; vuruş arası reload anim |
| 2H Sword | STR | Measured Strike (hedef başına 3. hit +%40; guard sayılır; ~1s timeout) |
| 2H Axe | STR | Anti-guard stamina (artmış) |
| 2H Mace | STR | Defence Shred (yüksek) |
| Staff | INT | +Status Potency++; projectile light attack |

**INT silahlar:** light attack = projectile.

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

Guard genel: vuruşta ek stamina maliyeti; açıkken regen yok. Stamina 0 → guard break → `GDD.md` §8 (pasif drain: Slow 50%; vuruş: Stun 0.5s).

### Off-hand 1H (dual wield — STR/DEX)

| Kural | Değer |
|-------|--------|
| Light attack | Çift vuruş; on-hit affix ×2 |
| Pasif / perk | Off-hand **%50** |
| Aktif | Kullanılabilir; etki **%50** |

Dual damage çarpanı: Main **×1.0** · Off **×0.65** — güçlü başlangıç; playtest ile düşürülebilir (`§11b`).

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
| 1H + 1H off (STR/DEX) | ✅ | Max stamina **%50** |
| 2H STR | ✅ | Max stamina **%75** |
| Shield | ❌ | — |

- Stance: pasif drain yok; **%20 slow**; regen yok.
- Perfect parry → düşman **Stun 1s**.
- Fail (perfect değil) → maliyet + parry kapanır.
- Stance sırasında stamina 0 → sen **Stun 1s**.

---

## 11. Hasar pipeline (kilit v1)

Tek referans. `GDD.md` §8 · `STATUS_SYSTEM.md` §6.4 bu sırayı kullanır.

### 11.1 Direct damage (light attack, yetenek patlaması)

```
1. Crit roll          — §11.2 (uygunsa)
2. raw                = WeaponBase × (1 + Scaling × k_dmg) × (1 + gear%) × crit_mult
3. after_matchup      = raw × ElementMatchup(attacker.main → defender.chest)   // ±15%
4. after_dr           = after_matchup × (1 - effective_DR% / 100)              // shred dahil
5. Defensive stance   — §11.3 (sırayla: Dodge → Parry → Guard)
6. HP                 — stance geçilmediyse after_dr doğrudan HP'ye
7. On-hit status      — isabet bağlandıysa (dodge/perfect parry hariç) → ApplyStatus
8. ReactionResolver   — `CHEMISTRY_ENGINE.md` §5
```

**Matchup uygulanmaz:** DoT tick, reaksiyon burst, guard chip, heal.

**Guard açısı:** Saldıran → savunan ön **180°** yayı. Arkadan gelen direct hasar guard'tan geçmez (tam `after_dr`).

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
| 3 | **Guard** (ön 180°, shield) | Chip + stamina; §11.4 |
| — | Yok | `after_dr` → HP |

Parry fail veya guard: normal chip/HP akışı.

### 11.4 Guard — chip & stamina (kilit)

Tüm hesaplar **`after_dr`** (matchup + DR sonrası) üzerinden:

```
chip_damage    = after_dr × shield_chip%        // Kite 40%, Tower 30%, Buckler 60%
stamina_hit    = max(8, after_dr × 0.12)        // Axe perk: ×1.5
stamina_passive = shield_drain_per_sec × dt      // Kite 1.0/s, Buckler 0.5/s, Tower 1.5/s
```

- Chip → HP (DR tekrar uygulanmaz).
- Guard açıkken stamina regen **yok**.
- Stamina **0** → guard kapanır + guard break → `GDD.md` §8 · `STATUS_SYSTEM.md` §3.1.

### 11.5 DoT / reaksiyon hasarı (ayrı kanal)

```
dot_tick = (dot_base + affix_dps) × (1 - resist_effect%)     // DR yok, matchup yok, crit yok
burst    = burst_base × (1 - resist_effect%)               // Vaporize, Cauterize burst vb.
```

Süre: Potency (saldıran) → Resist (hedef) — `STATUS_SYSTEM.md` §1.3.

### 11.6 Light attack (MVP)

| Kural | Değer |
|-------|--------|
| Combo zinciri | **Yok** — tekrarlayan tek swing |
| Hit recovery | **0.15s** (weapon Attack Speed tier ile ölçeklenir) |
| Poise / hyperarmor | MVP'de **yok** |
| Menzil | Silah tipine göre hitbox (melee ~6 stud, bow projectile, staff projectile) |

---

## 11b. Dual wield hasar (post-MVP tasarım — çarpan kilit)

Her light attack swing = **2 ayrı hitbox** (main + off):

```
main_hit = main_formula × 1.0
off_hit  = off_formula  × 0.65
```

- Attack Speed: **main** silah tier'ı geçerli.
- On-hit affix: hit başına ayrı roll (2 proc şansı).
- Off-hand base farklı olabilir (ayrı Weapon Base).

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
| `k_dmg` | **0.0075** / stat | Orta TTK; +80 stat ≈ **+60%** hasar |

```
Damage mult = 1 + ScalingStat × 0.0075
```

### 12.3 VIT — dayanıklılık

| Sabit | Değer | Not |
|-------|--------|-----|
| `base_hp` | **120** | Orta TTK — erken ölüm az |
| `k_vit_hp` | **10** / VIT | VIT 80 → **920** HP from stat |
| `base_stam` | **100** | |
| `k_vit_stam` | **2** / VIT | VIT 70 → **240** max stamina |
| `k_vit_def` | **0.25** / VIT | VIT 40 → **+10 Defence** (1% DR) |
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
| `k_int_res` | **1.25** / INT |
| `C_res` | **165** |
| `base_resist` | **0** |

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

| Aksiyon | Maliyet |
|---------|---------|
| Dodge | **18** flat + recovery 0.25s |
| Sprint | **12** / s |
| Guard vuruş | `max(8, after_dr × 0.12)` stamina (`§11.4`) |
| Axe vs guard | vuruş maliyeti × **1.5** |

### 12.9 Örnek build — Lv50 (gear hariç)

| Build | Dağılım | Öne çıkan |
|-------|---------|-----------|
| **2H Mace** | STR 100, VIT 70, DEX 20, INT 6 | HP 920, Stam 240, dmg ×1.75 |
| **Bow** | DEX 100, STR 20, VIT 50, INT 26 | Crit 17%, AS ×1.35×tier |
| **Staff** | INT 90, VIT 40, DEX 30, STR 36 | Potency 72, +3.6 ignite DPS |
| **Sword+shield** | STR 70, VIT 90, DEX 30, INT 16 | HP 1120, +22 Defence from VIT |

*Gear ile tank ~300–500 Defence (30–50% DR); mage robe ~40 Def + 80 Resist.*

### 12.10 Silah base damage (gear tier 1 placeholder)

| Tier | Weapon Base (ör.) |
|------|-------------------|
| Dagger / Wand | 28–32 |
| 1H Sword / Bow | 38–42 |
| 1H Axe / Staff | 44–48 |
| 1H Mace / 2H Sword | 48–52 |
| 2H Mace / Crossbow | 55–62 |

### 12.11 TTK hedefi (kilit)

**Hedef:** Orta TTK — ortalama oyuncuda **~14–18 isabet** (orta gear, orta VIT). İyi kombo/guard ile maç **doğal uzar** — tasarım onayı (2026-07).  
**İyi oyuncu:** Guard / dodge / parry / pozisyon → daha az isabet → TTK **doğal uzar** (HP şişirmeden).

| Profil | Beklenen süre (1v1, orta gear) |
|--------|--------------------------------|
| Ortalama vs ortalama | **12–18 sn** aktif combat |
| İyi vs iyi | **20–35+ sn** |
| Burst (crit + kimya) | Kısa pencerede **%30–40 HP** — comeback mümkün |

**TTK knob’ları (öncelik):**
1. `base_hp` / `k_vit_hp` — genel süre  
2. `k_dmg` / weapon base — burst  
3. DR `CAP` — tank tavanı  
4. Stamina maliyetleri — skill ifadesi (uzatır)

**Kilit profil:** `base_hp 120`, `k_dmg 0.0075`, `k_dr 0.1`, cap %70.

**Orta gear tanımı (TTK referansı):** Lv **30**, VIT **60**, tier-1 kılıç (base **40**) + tier-1 chest (**+80 Defence**). Toplam Defence ≈ **295** → DR **29.5%**. HP ≈ **720**.

| Profil | Raw/hit (STR 70) | Efektif/hit (DR 29.5%) | Hit to kill (720 HP) |
|--------|------------------|------------------------|----------------------|
| Orta DPS | ~58 | ~41 | **~18** |
| Yüksek DPS (STR 90, +gear%) | ~72 | ~51 | **~14** |
| Burst pencere (kimya + crit) | — | ~250–290 HP | **2–3** exchange |

*Hedef bandı **14–18 orta gear hit** — guard/dodge ile pratik TTK 12–25 sn. Saf stat örneği (gear yok):*
```
~64 raw/hit → HP 720 (VIT 60) ≈ 11 hit (DR yok)
%35 DR → efektif ~17 hit
```

---

| Sistem | MVP | Later |
|--------|-----|-------|
| 4 primary + sheet formülleri | ✅ | — |
| Defence 0.1%/def + cap | ✅ | — |
| Sword / Axe / Staff / Bow + Kite shield | ✅ | 3 shield tipi |
| Kimya (10 reaksiyon + status) | ✅ | Sinerji setleri |
| Dodge + Guard | ✅ | Parry perfect |
| Dual wield | — | ✅ |
| Knot | — | ✅ |
| Focus | — | ✅ |
| 2v2 / 3v3 | — | ✅ |

---

*Son güncelleme: 2026-07 — hasar pipeline v1, crit kuralları, dual ×0.65 off-hand, guard chip `after_dr`.*
