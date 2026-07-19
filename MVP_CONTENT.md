# MVP Content — Tam Test Seti Spec

> **Amaç:** Tek bir loadout ile MVP'deki **tüm reaksiyonları** ve **tüm combat mekaniklerini** test edebilmek.  
> **Sen dolduracaksın:** Aşağıdaki şablonlara kendi item isimlerini / sayılarını yaz.  
> **Referans:** `GDD.md` §14 · `CHEMISTRY_ENGINE.md` · `COMBAT_STAT_SHEET.md` §11

Oyuncu seviyesi MVP testi: **Lv30** (126 dağıtılabilir stat point).

---

## 1. Mekanik kapsam checklist

Test setin şunların **hepsini** tetikleyebilmeli:

### Combat çekirdeği

| # | Mekanik | Nasıl test edilir | ✓ |
|---|---------|-------------------|---|
| M1 | Light attack (melee) | Main silah düz vuruş | [ ] |
| M2 | Light attack (projectile) | Staff veya Bow LA | [ ] |
| M3 | Dodge + i-frame | Dodge input | [ ] |
| M4 | Guard + chip | Shield + sağ tık | [ ] |
| M5 | Guard break (pasif drain) | Guard açık stamina 0 → Slow 50% | [ ] |
| M6 | Guard break (vuruş) | Axe vs guard → Stun 0.5s | [ ] |
| M7 | Stamina drain / regen | Sprint, guard, dodge | [ ] |
| M8 | Crit | DEX/STR build veya bow | [ ] |
| M9 | Element matchup | Farklı element silah vs chest | [ ] |
| M10 | Measured Strike | 3. light attack bonus (sword) | [ ] |
| M11 | Aktif yetenek | En az 1 silah aktifi | [ ] |
| M12 | On-hit affix | Hand veya silah affix | [ ] |
| M13 | Defence / DR | Chest + shield | [ ] |
| M14 | Resist / Potency | INT veya gear Resist | [ ] |

### Silah aileleri (MVP roster)

| Silah | Test edilmeli | ✓ |
|-------|---------------|---|
| 1H Sword | Measured Strike | [ ] |
| 1H Axe | Anti-guard stamina | [ ] |
| Staff | Projectile + Firebolt | [ ] |
| Bow | Ranged + crit | [ ] |

---

## 2. Reaksiyon kapsam matrisi (10/10)

Her reaksiyon için setinde **hangi slot/ yetenek** status vereceğini planla.

| ID | Reaksiyon | Girdi A | Girdi B | Setinde kaynak A | Setinde kaynak B | ✓ |
|----|-----------|---------|---------|------------------|------------------|---|
| R1 | Vaporize | Wet | Ignite | | | [ ] |
| R2 | Chain Shock | Wet | Shock | | (+ menzilde 2. Wet hedef) | [ ] |
| R3 | Chilled | Wet | Windy | | | [ ] |
| R4 | Thaw | Chilled | Ignite | *(R3 sonrası)* | | [ ] |
| R5 | Cauterize | Bleed | Ignite | | | [ ] |
| R6 | Blight | Bleed | Poisoned | | | [ ] |
| R7 | Grounded | Windy | Slow | | | [ ] |
| R8 | Contamination | Wet | Poisoned | | (+ menzilde Wet) | [ ] |
| R9 | Wild Fire | Windy | Ignite | | | [ ] |
| R10 | Caustic Burn | Ignite | Poisoned | | | [ ] |

**Gerekli status havuzu (affix / yetenek ile sağlanmalı):**

| Status | Element referans | Setinde nerede? |
|--------|------------------|-----------------|
| Wet | Water | |
| Ignite | Fire | |
| Shock | Lightning | |
| Windy | Wind | |
| Poisoned | Poison | |
| Bleed | Steel | |
| Slow | Rock | |

**İpucu — tek set ile tüm reaksiyonlar:**  
6 slot + 1–2 aktif yetenek ile tüm status'leri sığdırmak zor. Pratik çözüm:

1. **Hand + main** farklı on-hit affix (ör. Wet + Ignite)
2. **Aktif yetenekler** eksik elementleri tamamlar (Shock, Poison, Slow…)
3. **Training dummy** veya **ikinci test bot** menzilde Wet tutar (R2, R8 zinciri)
4. **Sıralı test:** Önce R1–R3, sonra Bleed affix takıp R5–R6, vb.

---

## 3. Tam test seti — şablon (sen doldur)

### 3.1 Loadout özeti

| Alan | Değer |
|------|--------|
| Set adı | *TBD* |
| Ana rol | *ör. hybrid setup mage* |
| Main silah | |
| Off-hand | |
| Sinerji bandı (opsiyonel) | *Pure / Harmony / Duality / —* |

### 3.2 Slot tablosu

| Slot | Item adı | Element tag | Base stats | Affix / aktif / pasif |
|------|----------|-------------|------------|------------------------|
| **Main** | | | Weapon base: | Aktif: · Pasif: · On hit: |
| **Off** | | | Defence: | |
| **Chest** | | | Defence: · Resist: | |
| **Hand** | | | | On hit: |
| **Helmet** | | | | Aktif/Pasif: |
| **Feet** | | | | Pasif: |

### 3.3 Stat dağılımı (Lv30)

| STR | DEX | VIT | INT | Toplam |
|-----|-----|-----|-----|--------|
| | | | | **126** |

### 3.4 Yetenek listesi

| Kaynak | Yetenek adı | CD | Etki | Verdiği status |
|--------|-------------|-----|------|----------------|
| Main aktif | | | | |
| Off aktif | | | | |
| Helmet | | | | |

### 3.5 On-hit uygulama sırası (reaksiyon sırası için)

Aynı vuruşta birden fazla status gelirse **bu sıra** geçerli (`CHEMISTRY_ENGINE.md` §5.4):

| Sıra | Kaynak | Status |
|------|--------|--------|
| 1 | | |
| 2 | | |
| 3 | | |

*Örnek: önce Hand Wet, sonra silah Ignite → Vaporize; ardından Shock yeteneği → Shock kalır.*

---

## 4. Test senaryoları (oyunda doğrula)

| # | Senaryo | Adımlar | Beklenen sonuç | ✓ |
|---|---------|---------|----------------|---|
| T1 | Vaporize | Wet uygula → Ignite uygula | R1 burst; Wet+Ignite yok | [ ] |
| T2 | Sıralı çoklu | Wet → Ignite → Shock (3 ayrı ApplyStatus) | Vaporize, sonra Shock kalır | [ ] |
| T3 | Wet öncelik | Hedefte Wet+Bleed → Ignite | Vaporize (Wet eski); Bleed kalır | [ ] |
| T4 | Cauterize | Bleed → Ignite | R5; Bleed+Ignite yok | [ ] |
| T5 | Chilled → Thaw | Wet+Windy → Chilled; sonra Ignite | R3, sonra R4 Thaw penceresi | [ ] |
| T6 | Chain Shock | 2 hedef Wet; birine Shock | R2; menzil 12 stud | [ ] |
| T7 | Guard chip | Bow/axe vs Kite guard | Chip after_dr; stamina düşer | [ ] |
| T8 | Dodge i-frame | Dodge + gelen vuruş | 0 hasar | [ ] |
| T9 | Measured Strike | 3 light sword | 3. hit +35% | [ ] |
| T10 | Matchup | Fire silah vs Water chest | ×0.85 hasar | [ ] |

---

## 5. Referans — placeholder itemlar (opsiyonel başlangıç)

Kendi setini yazana kadar geçici referans. **Senin tam setin bunların yerini alacak.**

<details>
<summary>Eski tier-1 örnekleri (genişlet)</summary>

| ID | İsim | Not |
|----|------|-----|
| `w_sword_1h` | Iron Longsword | Steel, Measured Strike |
| `w_axe_1h` | Hand Axe | Fire, anti-guard |
| `w_staff` | Ember Staff | Firebolt + Ignite |
| `w_bow` | Hunter Bow | Wind, crit |
| `o_kite` | Kite Shield | +120 Def |
| `a_hands_cloth` | Cloth Wraps | On hit Wet 3s |

</details>

---

## 6. MVP kapsam dışı (bilinçli)

- Parry, dual wield (kod), Quiver, Knot, Focus
- Loot / craft — lobby sabit loadout
- PvP timeout sonucu — **TBD** (`GDD.md` §16)
- Pure x3 sinerji perk testi — set element tag'leri ile opsiyonel

---

*Son güncelleme: 2026-07 — tam test seti şablonu; reaksiyon §5.4 uygulama sırası.*
