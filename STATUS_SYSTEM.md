# Status System — Etki Kataloğu & Uygulama Spec

> **Amaç:** Buff, debuff, DoT, CC ve bazı combat mekaniklerini (Guard, Parry, Dodge) tek **Status** katmanında toplamak. Yeni etki veya reaksiyon eklemek = katalog satırı + (gerekirse) handler.
>
> **Reaksiyonlar:** `CHEMISTRY_ENGINE.md` — `ApplyStatus` içinde `ReactionResolver`.
>
> **Son güncelleme:** 2026-07 — katalog v1 + reaksiyon türevleri.

---

## 1. Tasarım ilkeleri

### 1.1 Tek kayıt (Status Registry)

Oyuncu ve düşman üzerindeki her şey aynı yapıda tutulur:

```
StatusInstance {
  id          -- "Ignite", "Guard", "Stun", ...
  expiresAt   -- server timestamp; stance'lerde kısa pencere veya "input bırakılana kadar"
  source      -- kim uyguladı (playerId, abilityId, "Self", "Reaction", ...)
  stacks      -- çoğu etkide 1; DoT DPS override için opsiyonel
  params      -- runtime (ör. Guard shield tipi, Parry perfect window)
}
```

**Kural:** Combat kodu doğrudan `if parrying` yazmak yerine `StatusQuery` kullanır (`CanMove`, `CanAttack`, `DamageMultiplier`, `IsInvulnerable`).

### 1.2 Dört kategori

| Kategori | Kimde | Resist? | Potency? | Örnek |
|----------|-------|---------|----------|--------|
| **Debuff** | Düşman | Evet | Süre (Potency saldıran) | Wet, Ignite, Shock |
| **Buff** | Kendi / ally | Hayır* | Buff Potency | Frenzied |
| **Stance** | Kendi (input) | Hayır | Hayır | Guard, Parry, Dodge |
| **Setup** | Düşman | Evet | Süre | Wet (tek başına etkisiz) |

\*Ally buff'larda hedefin Resist'i değil, uygulayanın Buff Potency'si geçerli.

### 1.3 Status Potency vs DoT hasarı (kilit)

| Etki tipi | Status Potency ne yapar? | Hasar / güç nereden? |
|-----------|--------------------------|----------------------|
| **DoT** (Ignite, Poisoned, Bleed) | **Süreyi** uzatır | **Eşya affix** (`+Ignite DPS`, `+Poison DPS`, …) + base tablo |
| **CC / slow** (Shock, Windy, Slow, Stun) | **Süreyi** uzatır (taban süre × potency) | Sabit tablo; Shock tabanı 0.5s |
| **Setup** (Wet) | **Süreyi** uzatır | — |
| **Buff** (Frenzied) | — | Buff Potency (süre / güç) |
| **Stance** | — | — |

**Resist (hedef — kilit):** Uygulanan **süreyi** ve varsa **hasarı** (DoT DPS, burst, reaksiyon hasarı) azaltır. Önce Potency, sonra Resist.

```
final_duration = base_duration × (1 + attacker_potency × k_pot_duration) × (1 - resist_effect%)
dot_dps        = (dot_base + sum(item_affixes)) × (1 - resist_effect%)
burst_damage   = burst_base × (1 - resist_effect%)

resist_effect% = Resist / (Resist + C_res)    -- COMBAT_STAT_SHEET §5
```

---

## 2. Element → Status (on-hit **affix ile**)

Element tag: **matchup** = Main Hand → hedef Chest · **sinerji ağırlığı** = Main Hand + **Off Hand** + Chest.

**Matchup uygulanmaz:** DoT tick, reaksiyon hasarı, guard chip.

| Kaynak | Örnek affix |
|--------|-------------|
| Silah (main/off) | `On hit: Ignite 3s` |
| **Hand** (eldiven) | `On hit: Wet 5s` |
| Yetenek | Skill script |
| Reaksiyon | `CHEMISTRY_ENGINE.md` |

**Varsayılan element→status eşlemesi yok** — Fire silahı otomatik Ignite vermez. **İstisna:** Pure x3 sinerji → main-hand düz vuruş on-hit (`CHEMISTRY_ENGINE.md` §3.4). Tasarım referans tablosu (affix yazarken):

| Element | Tipik status | Affix süre (referans) |
|---------|--------------|------------------------|
| Water | Wet | 5s |
| Fire | Ignite | 3s · 7 DPS |
| Lightning | Shock | 0.5s |
| Wind | Windy | 3s · %30 slow |
| Poison | Poisoned | 5s · 3 DPS |
| Steel | Bleed | 8s · 4 DPS |
| Rock | Slow | 3s · %50 slow |
| Neutral | — | — |

*Lightning = Electric (isim birleştirilecek).*

---

## 3. Status kataloğu (v1 — kilit liste)

### 3.1 Debuff & setup

| ID | Kaynak | Etki | Hareket | Saldırı | Not |
|----|--------|------|---------|---------|-----|
| **Wet** | Affix / yetenek / alan | Yok (setup) | 100% | Evet | Reaksiyon hub |
| **Ignite** | Affix `On hit: Ignite` | DoT | 100% | Evet | §4.2 |
| **Shock** | Affix `On hit: Shock` | Hard CC | 0% | Hayır | 0.5s |
| **Windy** | Affix | Slow **%30** | 70% | Evet | |
| **Poisoned** | Affix | DoT | 100% | Evet | §4.2 |
| **Bleed** | Affix | DoT | 100% | Evet | §4.2 |
| **Slow** | Affix / guard break | Slow **%50** | 50% | Evet | Guard break aynı ID |
| **Stun** | Parry perfect, yetenek, boss | Hard CC | 0% | Hayır | Süre kaynağa göre değişir (ör. parry → 1s) |
| **Root** | Yetenek, Focus tarzı eşya, trap | **Root** — hareket yok | **0%** | **Evet** | Saldırı / yetenek açık; Shock/Stun değil |

### 3.1b Reaksiyon türevleri (v1)

| ID | Kaynak | Etki | Hareket | Saldırı | Not |
|----|--------|------|---------|---------|-----|
| **Chilled** | Wet + Windy → R3 | Hard CC (donma) | 0% | Hayır | `CHEMISTRY_ENGINE.md` R3 |
| **Thaw** | Chilled + Ignite → R4 | Ignite **immunity** | 100% | Evet | Kısa süre; Fire on-hit Ignite yazılmaz |
| **Blight** | Bleed + Poisoned → R6 | DoT (birleşik ×2) | 100% | Evet | Süre = **uzun** kalan girdi DoT |
| **CausticBurn** | Ignite + Poisoned → R10 | DoT (birleşik ×2) | 100% | Evet | Süre = **kısa** kalan girdi DoT |
| **Cauterize** | Bleed + Ignite → R5 | Burst + DoT | 100% | Evet | Bleed ×0.75 anlık; Ignite → Cauterize DoT |
| **Grounded** | Windy + Slow → R7 | Slow **%80** | 20% | Evet | Süre = max(windy, slow) |
| **WildFire** | Windy + Ignite → R9 | DoT ×**1.5** + **AoE** tick | 100% | Evet | Çevreye **yalnızca hasar**; WildFire yazılmaz |

**Anlık / zincir:** Vaporize, **Chain Shock** (→ Shock), **Contamination** (→ Poisoned).  
**Hibrit:** **Cauterize** — kısmi bleed burst + Cauterize DoT (Ignite tüketilir).

**Shock vs Stun vs Root:** Shock/Stun/Chilled → hareket **ve** saldırı kapalı. **Root** → yalnızca hareket **0%**; saldırı ve yetenek açık. Aynı anda birden fazla CC: **en kısıtlayıcı** kazanır (Stun > Root > Slow) — *playtest*.

### 3.2 Buff

| ID | Kaynak | Etki | Süre |
|----|--------|------|------|
| **Frenzied** | Eşya / yetenek | +%20 Attack Speed, Move Speed, Damage | Eşyeye göre; Buff Potency süreyi uzatır |

### 3.3 Stance (self — combat mekaniği)

Bunlar da Status'tur; düşman Resist'inden geçmez. Detaylar `GDD.md` §7–8.

| ID | Tetik | Etki | Bitiş |
|----|-------|------|-------|
| **Guard** | Shield + sağ tık basılı | Önden gelen hasarın bir kısmı yok sayılır (chip); shield tipine göre drain / slow | Tuş bırakılınca veya stamina break |
| **Parry** | 1H off-hand + sağ tık (stance) | Kısa pencere; gelen hasar **Perfect Parry** ile sıfırlanır → saldıran **Stun** | Fail / süre / stamina 0 |
| **Dodge** | Dodge input | İlk karelerde **tam dokunulmazlık** (i-frame) | Animasyon / süre sonu |

**Guard** chip, drain ve slow değerleri shield tipinden `params` ile gelir — status motoru sadece `HasGuard` ve chip pipeline'ını bilir.

**Parry** perfect anında: `RemoveIncomingDamage` + `ApplyStatus(attacker, "Stun", 1.0)`.

**Dodge:** Hasar pipeline'ında `if HasStatus("Dodge") and dodge.iframesActive then damage = 0`.

---

## 4. Temel stat tablosu (v1 — kilit)

### 4.1 Global

| Sabit | Değer | Not |
|-------|--------|-----|
| `tick_interval` | **1.0s** | Tüm DoT'lar |
| `k_pot_duration` | **0.004** | Potency 60 → +24% süre |
| `C_res` | **165** | Resist eğrisi → `COMBAT_STAT_SHEET.md` |
| DoT vs Defence | **DR uygulanmaz** | Yalnızca Resist hasarı kısaltır |
| Yenileme | Süre **refresh** | Aynı DoT stack yok; DPS affix toplamı |

**DoT rolü (tek uygulama, 0 resist) — v1 kilit:**

| DoT | Rol | Süre | DPS | Toplam | Okunabilirlik |
|-----|-----|------|-----|--------|----------------|
| **Ignite** | **Kısa / hızlı** — en kısa sürede hasar | **3s** | **7** | **21** | Ateş hemen yakıyor; cleanse yoksa acı ama pencere kısa |
| **Poison** | **Dengeli** — orta süre, orta toplam | **5s** | **3** | **15** | Setup + Contamination; tek başına muted |
| **Bleed** | **Uzun / ölümcül** — **en yüksek toplam**, en uzun teslim | **8s** | **4** | **32** | DPS orta; **ignore = en kötü sonuç** — önlem bilinçli |

*Referans HP ~900; tek uygulama ≈ %1.7–3.6. Kimya + reaksiyon (Blight, Caustic, Wild Fire) asıl ölçek.*

**Tasarım kuralı:** `total = duration × dps` — Bleed en uzun **ve** en yüksek toplam; Ignite en yüksek DPS / en kısa süre; Poison ortada.

---

### 4.2 On-hit status (element)

| Status | Süre | Etki | Move | Attack |
|--------|------|------|------|--------|
| **Wet** | **5s** | Setup (hasar yok) | 100% | Evet |
| **Ignite** | **3s** | **7** DPS | 100% | Evet |
| **Poisoned** | **5s** | **3** DPS | 100% | Evet |
| **Bleed** | **8s** | **4** DPS | 100% | Evet |
| **Shock** | **0.5s** | Hard CC | 0% | Hayır |
| **Windy** | **3s** | **%30** slow | 70% | Evet |
| **Slow** | **3s** | **%50** slow | 50% | Evet |

**Guard break (mechanic):** Stamina pasif drain ile biterse → **Slow 50%**, süre **3s** veya %10 stamina dolana kadar (hangisi önce — GDD §7).

---

### 4.3 Reaksiyon türevleri

| Status | Süre | Etki |
|--------|------|------|
| **Chilled** | **1.5s** | Hard CC (donma) |
| **Thaw** | **2s** | Ignite uygulanamaz |
| **Cauterize** | Ignite kalan süre | DoT = Ignite kalan toplam hasar (1s tick); **Ignite/Bleed tag yok** |
| **Grounded** | `max(windy_rem, slow_rem)` | **%80** slow |
| **WildFire** | Ignite kalan süre | DPS = `ignite_dps × 1.5`; AoE **8** stud/tick, çevreye **hasar only** |
| **Blight** | `max(bleed_rem, poison_rem)` | Toplam kalan hasar ×2 → DoT |
| **CausticBurn** | `min(ignite_rem, poison_rem)` | Toplam kalan hasar ×2 → DoT |

**Kalan hasar (reaksiyon öncesi):**

```
remaining_dot_damage = floor(remaining_seconds / tick_interval) × current_dps × tick_interval
-- son kısmi saniye tick'e dahil değil (1s grid)
```

---

### 4.4 Anlık reaksiyon hasarları

| Reaksiyon | Formül (0 resist) |
|-----------|-------------------|
| **Vaporize** | `ignite_remaining_damage × 1.25` (Wet+Ignite tüketilir; Ignite DoT yok) |
| **Cauterize** | `bleed_remaining × 0.75` burst; **Cauterize** DoT = Ignite kalan hasar + süre (Ignite/Bleed tüketilir) |
| **Chain Shock** | Menzil **12** stud; max **6** hedef; her birine Shock **0.5s** |
| **Contamination** | Aynı menzil/max; her birine Poisoned **5s** (3 DPS) |

---

### 4.5 Combat & buff (stance hariç)

| Status | Süre | Etki | Kaynak |
|--------|------|------|--------|
| **Stun** (parry perfect) | **1.0s** | Hard CC | Parry |
| **Stun** (guard break) | **0.5s** | Hard CC | Stamina 0 + vuruş |
| **Frenzied** | **6s** (eşya base) | +**%20** AS, MS, Damage | Eşya; Buff Potency süre |
| **Dodge** (i-frame) | **0.25s** | Invulnerable | Dodge input |
| **Parry** (pencere) | **0.35s** | Perfect negate | Sağ tık stance |

---

### 4.6 Örnek — Potency & Resist

Staff build: Potency **72**, hedef Resist **80**:

```
potency_mult   = 1 + 72 × 0.004 = 1.288
resist_effect% = 80 / (80 + 165) = 32.7%

Ignite süre  = 3 × 1.288 × (1 - 0.327) = 2.59s
Ignite DPS   = 7 × (1 - 0.327) = 4.71
Toplam ≈ 3 tick × 4.71 ≈ 14 hasar (gear affix hariç)
```

---

## 5. DoT kuralları (özet)

- `tick_interval = 1.0s` — §4.1
- Base DPS: Ignite **7** / 3s, Poison **3** / 5s, Bleed **4** / 8s
- Çoklu DoT etkileşimi yalnızca **reaksiyonlar** ile (Blight, Caustic Burn, vb.)

---

## 6. Uygulama yöntemi (oyuna ekleme)

### 6.1 Tek giriş noktası

Tüm status kaynakları aynı API'den geçer:

```lua
-- StatusService.ApplyStatus(target, statusId, context)

context = {
  duration      = number | nil,      -- nil = katalog default
  source        = Player | NPC | "Reaction" | "Self",
  element       = string | nil,      -- on-hit izleme
  applyPotency  = boolean,           -- default true (debuff); stance'te false
  params        = { ... },           -- Guard shieldType, Parry windowEnd, ...
}
```

**Akış:**

```
ApplyStatus(target, id, ctx)
  1. StatusDef = Registry[id]     -- yoksa error / log
  2. if def.immunityTags and target immune → return
  3. if def.category == Debuff → duration = CalcDuration(ctx, attacker Potency, target Resist)
  4. if def.category == Stance → skip Resist; params from combat action
  5. REACTION_HOOK → `CHEMISTRY_ENGINE.md` ReactionResolver
  6. Merge instance (refresh süre / replace stance)
  7. OnApplied hooks (VFX, UI icon, stat recompute)
  8. Publish replication event (client icon)
```

### 6.2 Kaynak tipleri (SourceType)

| SourceType | Ne zaman | Örnek |
|------------|----------|--------|
| `ElementOnHit` | Silah/eldiven affix `On hit: …` | Affix ile Ignite |
| `Ability` | Yetenek script'i | Boss ground slam → Stun |
| `Item` | Proc / kullanım | Frenzied flask |
| `CombatAction` | Guard / Parry / Dodge | Self stance |
| `Reaction` | İki status birleşimi | Vaporize, Blight, … |
| `Environment` | Alan, hazard | Su havuzu → Wet |

Yeni kaynak eklemek = yeni çağrı yeri; **registry değişmez** (aynı `Ignite`).

### 6.3 StatusDef şeması (data-driven)

Her status için tek satır (ModuleScript / JSON):

```lua
["Ignite"] = {
  category     = "Debuff",
  tags         = { "DoT", "Fire" },
  defaultDuration = 3,
  potencyScalesDuration = true,
  potencyScalesDamage   = false,  -- kilit: false
  blocksMove   = false,
  blocksAttack = false,
  onTick       = "DoT_Ignite",
  icon         = "rbxassetid://...",
},
["Guard"] = {
  category     = "Stance",
  tags         = { "Defensive" },
  potencyScalesDuration = false,
  blocksMove   = false,
  blocksAttack = false,
  onDamage     = "Guard_ChipPipeline",
},
```

**Yeni status eklemek:**

1. `StatusRegistry`'ye Def ekle  
2. Gerekirse `onTick` / `onDamage` handler (çoğu generic: DoT, Slow, Stun)  
3. UI ikon + lokalizasyon  
4. Reaksiyon matrisine satır *(reaksiyon aşamasında)*  

### 6.4 Sorgu API (combat entegrasyonu)

```lua
StatusQuery.CanMove(entity) -> boolean
StatusQuery.CanAttack(entity) -> boolean
StatusQuery.GetMoveSpeedMult(entity) -> number   -- tek status kendi çarpanını verir; Windy+Slow vb. üst üste kurallar → reaksiyon spec
StatusQuery.IsInvulnerable(entity) -> boolean    -- Dodge i-frame
StatusQuery.HasStance(entity, "Guard") -> boolean
StatusQuery.GetActiveDebuffs(entity) -> { id, remaining }
```

Hasar pipeline sırası (`GDD.md`): Crit → Raw → DR → **Guard/Parry/Dodge** → on-hit status → Resist.

### 6.5 Tick döngüsü

```
Her sunucu tick (veya 0.1s):
  for entity, statuses in ActiveStatuses do
    for status in statuses do
      if status.onTick and tick due → apply DoT damage
      if now >= status.expiresAt → remove + OnExpired
    end
  end
```

Stance'ler: `expiresAt` anim bitişi veya her frame input kontrolü (Guard basılı mı).

---

## 7. UI & okunabilirlik

- Düşman üstü: aktif **debuff** ikonları + kalan süre (Wet, Ignite, …).
- Kendi UI: stance göstergesi (Guard stamina), buff (Frenzied).
- Stance'ler (Dodge i-frame) kısa olduğu için ikon opsiyonel; VFX öncelikli.

---

## 8. Bilinçli dışarıda bırakılanlar (şimdilik)

| Konu | Nerede |
|------|--------|
| Sinerji (agirlik / combo) | `CHEMISTRY_ENGINE.md` §3 |
| Element ±15% matchup | `CHEMISTRY_ENGINE.md` §2.3–2.4 (Silah + Chest) |
| v1 dışı reaksiyon adayları | `CHEMISTRY_ENGINE.md` §5.4 |

---

## 9. Açık playtest maddeleri

- [ ] Shock + Stun overlap (uzun kalan kazanır?)
- [ ] WildFire AoE **8** stud / Chain **12** stud menzil hissi
- [ ] Guard break Slow: 3s sabit mi, stamina %10 mu önce

*Temel süre/DPS v1 kilit — §4.*

---

## 10. Dosya ilişkileri

| Belge | İçerik |
|-------|--------|
| **STATUS_SYSTEM.md** (bu dosya) | Katalog + ApplyStatus + Potency kuralları |
| `GDD.md` §7–8 | Guard / Parry / Dodge sayısal detay |
| `COMBAT_STAT_SHEET.md` §5–7 | Potency / Resist formülleri |
| `CHEMISTRY_ENGINE.md` | Element matchup + **reaksiyonlar** (sonra) |
