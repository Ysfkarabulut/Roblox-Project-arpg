# Weapon Active Archetypes

> **Amaç:** Silah ailelerine göre aktif yetenek **türlerini** tanımlamak. Blade/item üretirken bu arketiplerden kombinasyon seçilir.  
> **Katalog id:** `WeaponActiveDefs.luau` · combat params: `AbilityRuntime.luau`  
> **Durum:** Tasarım kilidi (v1 kodda henüz hepsi yok). Scepter bölümü kullanıcı tarafından tamamlanacak.

---

## Ortak terimler

| Terim | Anlam |
|-------|--------|
| **Hasar bandı** | Düşük / Orta / Yüksek — weapon base × `damagePct` ile ölçeklenir |
| **Menzil** | Yakın (~10 stud) · Orta (~15–20) · Uzun (~25+) |
| **Gem element** | On-hit veya alan etkisi gem elementinden; status potency ölçekler |
| **Şekil** | Single · Cone · Line · Radial (avatar merkez) · Rect (ön kare) · Zone (süreli alan) |

### v1 katalogta mevcut (kısmi eşleşme)

| Arketip özeti | Mevcut id | Not |
|---------------|-----------|-----|
| Melee ST yakın | `strike_weaponactive` | Rare: `strike_r_weaponactive` |
| Cone orta AoE | `cone_weaponactive` | Rare: `cone_r_weaponactive` |
| Dash + ST | `dash_weaponactive` | ~15 stud dash |
| 2H ground slam | `slam_r_weaponactive` | Radial’a yakın; 2H rare |
| Ranged ST bolt | `bolt_weaponactive` | Wand/bow tek hedef |
| Self buff/heal | `heal_*`, `hot_*`, `fortify_*`, `frenzy_*` | Scepter support bandı |

---

## Melee (1H + 2H: sword, axe, mace, dagger, greatblade, greataxe, greathammer)

| # | Tür | Hasar | Şekil / menzil | Davranış | Örnek flavor | Önerilen id (taslak) | v1 |
|---|-----|-------|----------------|----------|--------------|----------------------|-----|
| M1 | **Single thrust** | Yüksek | Single · yakın | Tek hedef, kısa menzil, güçlü tek vuruş | Thrust, Cleave | `strike_weaponactive` | ✓ |
| M2 | **Cone sweep** | Orta | Cone · orta menzil | Ön koni, birden fazla hedef | Sweep, Whirlwind | `cone_weaponactive` | ✓ |
| M3 | **Radial burst** | Orta | Radial · avatar merkez ~**20 stud** | Karakter etrafında daire AoE | Shockwave, Ground Slam | `radial_weaponactive` | — |
| M4 | **Dash strike** | Yüksek | Dash ~**15 stud** + single | İleri atılıp tek hedefe yüksek hasar | Lunge, Charge | `dash_weaponactive` | ✓ |
| M5 | **Multi-hit combo** | Orta | Single · yakın · **çok vuruş** | Hedef süre boyunca **hareketsiz** (root/stun); ardışık hit | Flurry, Execution | `flurry_weaponactive` | — |

**Notlar**
- M3 ile `slam_r_weaponactive` (2H rare zemin vuruşu) aynı aile; 1H için daha kısa CD / düşük % olabilir.
- M5 root süresi = animasyon süresi; interrupt edilebilir mi ayrı karar.
- Tüm melee aktiflerde gem status on-hit veya alan sonu proc (tasarım kararı).

---

## Bow / Crossbow

| # | Tür | Hasar | Şekil / menzil | Davranış | Örnek flavor | Önerilen id (taslak) | v1 |
|---|-----|-------|----------------|----------|--------------|----------------------|-----|
| B1 | **Arrow rain zone** | Orta | Uzun menzil · yuvarlak alan · **süreli DoT** | Hedef bölgeye ok yağmuru; alanda kalan hasar almaya devam eder | Rain of Arrows | `arrow_rain_weaponactive` | — |
| B2 | **Multi-shot cone** | Orta | Cone · orta menzil · **3–5 ok** | Her ok kendi hasarını uygular; yakından çok isabet = toplam yüksek | Triple Shot, Volley | `multishot_weaponactive` | — |
| B3 | **Piercing line** | Yüksek | Line · orta menzil | Düz çizgide delip geçen ok; isabet eden herkese hasar | Piercing Arrow | `pierce_weaponactive` | — |
| B4 | **Snipe** | Yüksek | Single · **uzun menzil** | Hedef seçimi; **uzun cast** animasyonu sonra tek yüksek hasar atışı | Snipe Shot | `snipe_weaponactive` | — |
| B5 | **Strafe shot** | Düşük | Single · orta menzil | Cast sırasında **hareket serbest**; düşük hasar, düşük CD / sürekli kullanım | Strafe Shot | `strafe_weaponactive` | — |
| B6 | **Jump shot** | Orta | Radial · **hedef nokta** (ayak altı) | İsabet noktasında patlama + gem element; karakter **geriye zıplar** | Jump Shot, Blast Arrow | `jump_shot_weaponactive` | — |

**Notlar**
- B1 zone süresi ve tick aralığı `AbilityRuntime`’da `zoneDuration` + `zoneDps`.
- B4 cast interrupt: dodge / hit ile iptal edilebilir (PvP için önemli).
- B5 ammo/stamina drain ile sınırlanabilir; spam önleme tasarım kararı.
- Crossbow aynı arketipleri kullanır; animasyon / reload farkı aile perk’i.

---

## Wand / Staff

| # | Tür | Hasar | Şekil / menzil | Davranış | Örnek flavor | Önerilen id (taslak) | v1 |
|---|-----|-------|----------------|----------|--------------|----------------------|-----|
| W1 | **Sustained zone** | Orta | Geniş yuvarlak · **süreli tick** | Blizzard gibi alanda sürekli hasar (DoT zone) | Blizzard, Storm | `zone_weaponactive` | — |
| W2 | **Meteor + splash** | Yüksek | Single hedef + **splash** | Ana hedefe yüksek hasar; çevrede az hasar + gem **status** | Meteor Strike | `meteor_weaponactive` | — |
| W3 | **Channeled spray** | Düşük | Cone · kanal | Flamethrower gibi açık kaldığı sürece sürekli düşük hasar | Flame Spray, Arc Spray | `spray_weaponactive` | — |
| W4 | **Frontal rectangle** | Orta | Rect · karakterden öne kare | Önündeki geniş dikdörtgen alanı etkiler | Wall of Fire, Beam Sweep | `rect_weaponactive` | — |

**Notlar**
- W1 ≈ Bow B1; fark: büyü zone’u genelde daha geniş, wand kısa menzil / staff uzun.
- W3 kanal: stamina veya max süre cap; hareket hızı düşürülebilir.
- W4 rect derinlik × genişlik `AbilityRuntime`’da ayrı parametre.
- Mevcut `bolt_weaponactive` / `cone_weaponactive` basit v1 karşılıkları; W2–W4 henüz yok.

---

## Scepter (support / buff bandı)

> **TODO:** Kullanıcı bugün scepter arketip özetlerini ekleyecek.  
> Mevcut v1 support aktifler (Buff Potency ölçekli): `heal_weaponactive`, `hot_weaponactive`, `fortify_weaponactive`, `frenzy_weaponactive`.

| # | Tür | Hasar | Şekil / menzil | Davranış | Örnek flavor | Önerilen id (taslak) | v1 |
|---|-----|-------|----------------|----------|--------------|----------------------|-----|
| S? | *(bekleniyor)* | | | | | | |

**Ayrım:** Scepter ailesi INT + **Buff Potency**; wand/staff **Status Potency** + hasar odaklı. Support arketipler `usesGemElement = false` veya ally-target buff olarak ayrı tutulabilir.

---

## Procedural üretim (ileride)

Blade rare/common atarken örnek kural:

```
1H Common  → 1 aktif (aile havuzundan 1 arketip)
1H Rare    → 1 aktif + 1 pasif
2H Common  → 2 aktif (farklı arketip tercih)
2H Rare    → 2 aktif + 1 pasif (veya 1 aktif + 2 pasif)
```

**Havuz eşlemesi (taslak)**

| Aile | Arketip havuzu |
|------|----------------|
| Melee (1H/2H) | M1–M5 |
| Bow / Crossbow | B1–B6 |
| Wand / Staff | W1–W4 |
| Scepter | S? + mevcut heal/hot/fortify/frenzy |

Flavor isim blade `abilities[].name` alanında; mekanik id stabil kalır (`*_weaponactive`).

---

## İlgili dosyalar

- `src/shared/Config/WeaponActiveDefs.luau` — katalog
- `src/shared/Config/AbilityRuntime.luau` — shape, damagePct, range, zone params
- `ROBLOX_MODULAR_GEAR_NOTES.md` — ability id convention
- `GDD.md` §7 — silah aileleri ve LA farkları

*Son güncelleme: melee / bow / crossbow / wand / staff arketipleri kayıtlı; scepter bekleniyor.*
