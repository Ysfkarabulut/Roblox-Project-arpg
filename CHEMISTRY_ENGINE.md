# Chemistry Engine — Element, Matchup, Sinerji & Reaksiyon

> **Status:** `STATUS_SYSTEM.md` · **Sinerji perkleri:** kilit (2026-07)

---

## 1. Global

Reaksiyonlar: sıra yok, iki girdi tüketilir. Potency süre, Resist süre+hasar.

**Tüketim kuralı:** Reaksiyon tetiklenince **her iki girdi status hedeften silinir** (zincir reaksiyonlar hariç — aşağıda). Süreli çıktı kalır.

---

## 2. Element sistemi

### 2.3 Matchup hasarı (kilit)

| Rol | Slot |
|-----|------|
| Saldırı | Main Hand |
| Savunma | Chest |

Taban: güçlü **×1.15** · zayıf **×0.85** · nötr **×1.0**.

### 2.4 Matchup tablosu

| Saldırı | Güçlü (+15%) | Zayıf (-15%) |
|---------|--------------|--------------|
| Fire | Steel, Poison | Water, Rock |
| Water | Fire | Lightning |
| Lightning | Water | Wind, Rock |
| Wind | Lightning | Rock |
| Poison | Water | Fire, Steel |
| Rock | Fire, Wind | Steel |
| Steel | Rock | Fire, Poison |
| Neutral | — | — |

---

## 3. Sinerji sistemi (kilit)

### 3.1 Element ağırlığı (Main + Off + Chest)

| Slot | Sinerji ağırlığı |
|------|------------------|
| Main 1H | 1 |
| Main 2H | 2 |
| Main **Bow / Crossbow** | **2** (teknik 2H sınıf) |
| Off — 1H / Shield / Focus (tag varsa) | 1 |
| Off — **Weapon Knot** (tagsiz) | 0 |
| Off — **Quiver** (tagsiz) | 0 |
| Chest (tag varsa) | 1 |
| Neutral tag | 0 |

**Loadout:**
- **2H melee** → off = Knot (tagsiz)
- **Bow / Crossbow** → off = Quiver (tagsiz); sinerji = **main (×2) + chest (×1)**
- **1H melee** → off = Shield / 1H / Focus / Wand (tag kuralları itema göre)

### 3.2 Sinerji bandı seçimi

| Band | Koşul |
|------|-------|
| **Pure x3** | Tek non-Neutral element; toplam ağırlık **3** |
| **Duality** (x2+x1) | İki element; ağırlık **2 + 1** |
| **Harmony** (x1+x1+x1) | Üç farklı non-Neutral; **1+1+1** (yalnızca **1H melee**) |
| **Unbound** | Main + Off + Chest = hepsi Neutral tag |
| *(perk yok)* | Diğer karışımlar (ör. ×2 + Neutral chest) |

### 3.3 Duality — x2+x1

İki element, ağırlık **2 + 1**: **Defence +5%** · **Resist +5%**.

Örnek: 2H Fire + Water chest + Knot · **Bow Fire + Water chest + Quiver** · 1H Fire + Water off + Water chest.

### 3.4 Pure x3 — element perkleri

Main-hand düz vuruş on-hit imza status + element ek perk.

| Element | Perk | On-hit | Ek |
|---------|------|--------|-----|
| Fire | Scorch | Ignite | süre +15% |
| Water | Cascade | AoE Wet splash 8 stud | Wet 5s |
| Lightning | Conduct | Shock | +0.15s |
| Wind | Gale | Windy | süre +20%; MS +3% |
| Poison | Venom | Poisoned | +1 DPS |
| Rock | Seismic | Slow | süre +15%; Slow hedef +5% direct |
| Steel | Wound | Bleed | +1s |
| Neutral | Unbound | Pure x3 yok | §3.6 |

### 3.5 Harmony — x1+x1+x1 (1H melee)

+15 flat Status Potency.

### 3.6 Unbound — Pure Neutral

+5% direct · +10% Defence · +12% Resist.

---

## 4. Reaksiyonlar (10)

R1 Vaporize · R2 Chain Shock · R3 Chilled · R4 Thaw · R5 Cauterize · R6 Blight · R7 Grounded · R8 Contamination · R9 Wild Fire · R10 Caustic Burn.

Detay sayılar: `STATUS_SYSTEM.md` §4 · özet: `GDD.md` §9.

---

## 5. Reaksiyon tüketim & zincir (kilit v1)

### 5.1 Çift girdi — hedef üzerinde

| ID | Girdiler (tüketilir) | Çıktı | Zincir |
|----|----------------------|-------|--------|
| **R1** Vaporize | Wet + Ignite | Anlık burst | — |
| **R2** Chain Shock | Wet + Shock (kaynak hedef) | Kaynak: Shock 0.5s | §5.2 |
| **R3** Chilled | Wet + Windy | Chilled 1.5s | — |
| **R4** Thaw | Chilled + Ignite | Thaw 2s | — |
| **R5** Cauterize | Bleed + Ignite | Burst + Cauterize DoT | — |
| **R6** Blight | Bleed + Poisoned | Blight DoT | — |
| **R7** Grounded | Windy + Slow | Grounded | — |
| **R8** Contamination | Wet + Poisoned (kaynak) | Kaynak: Poisoned 5s | §5.2 |
| **R9** Wild Fire | Windy + Ignite | WildFire DoT + AoE | §5.3 |
| **R10** Caustic Burn | Ignite + Poisoned | CausticBurn DoT | — |

### 5.2 Alan zinciri (R2, R8)

Tetikleyen hedefte **her iki girdi silinir**. Sonra:

| Reaksiyon | Menzil | Max hedef | Etki |
|-----------|--------|-----------|------|
| **Chain Shock** | **12** stud | **6** | Her **Wet** hedefte: Wet **silinir** → **Shock 0.5s** |
| **Contamination** | **12** stud | **6** | Her **Wet** hedefte: Wet **silinir** → **Poisoned 5s** (3 DPS) |

- Kaynak hedef zincire dahil (zaten Wet tüketildi).
- Potency/Resist: zincirlenen status **orijinal saldırganın** Potency'si ile hesaplanır.
- Aynı frame'de bir hedefe yalnızca **bir** zincir status (önce Shock mu Poison mu — hangi reaksiyon tetiklendiyse o).

### 5.3 Wild Fire AoE (R9)

- Ana hedefte Windy + Ignite tüketilir → **WildFire** DoT.
- Her **1s** tick: **8** stud yarıçap; çevredeki düşmanlara **yalnızca tick hasarı** (WildFire status yazılmaz).
- Çevre hasarı: Resist uygulanır; matchup ve DR **yok**.

### 5.4 Anlık reaksiyon çözümü (kilit v3)

**Öncelik tablosu yok.** Status geldikçe, o anda oluşabilecek **ilk geçerli çift** reaksiyona dönüşür; girdiler silinir; reaksiyonun kalıcı etkisi varsa o kalır.

#### Akış

```
ApplyStatus(target, newStatus)
  1. newStatus hedef listesine eklenir (uygulama sırası kaydı)
  2. ReactionResolver: newStatus ile hedefteki MEVCUT status'leri
     uygulama sırasına göre (eskiden yeniye) tara
  3. İlk geçerli çift bulunursa:
     a. İki girdi silinir
     b. Reaksiyon hasarı / VFX anında
     c. Süreli çıktı varsa hedefe yazılır (Chilled, WildFire, Shock, …)
  4. Başka çift yoksa veya newStatus tüketildiyse biter
  5. newStatus tüketilmediyse (çift oluşmadıysa) hedefte kalır
```

**Aynı vuruşta birden fazla status:** Her biri ayrı `ApplyStatus` — sırayla işlenir. Önce gelen çift önce patlar.

**Örnek:** Hedefte Wet. Sırayla Ignite, sonra Shock uygulanır:
1. Ignite → Wet+Ignite → **Vaporize** (ikisi silinir)
2. Shock → çift yok → **Shock** kalır

**Örnek:** Hedefte Wet + Bleed (önce Wet). Ignite gelir:
1. Wet+Ignite eşleşir (Bleed'den önce) → **Vaporize** · Bleed kalır

**Örnek:** Hedefte yalnızca Bleed. Ignite gelir → **Cauterize**.

#### Çoklu aday (nadir)

Aynı `ApplyStatus` anında birden fazla mevcut status ile çift mümkünse → hedefteki **en eski** status ile eşleş (uygulama sırası).

#### Thaw özel kuralı

Thaw aktifken hedefe **Ignite uygulanamaz** (affix, Pure x3, yetenek). Ignite gelmeden önce kontrol edilir.

#### Zincir reaksiyonlar (R2, R8)

Alan zinciri tetiklenince her etkilenen hedef için **ayrı** `ApplyStatus` (kendi §5.4 sırası). Bkz. §5.2.

---

## 6. v1 dışı reaksiyon adayları (brainstorm)

- Rock + Bleed → **Shatter** (savunma kırma)
- Lightning + Poisoned → **Neurotoxin** (stamina drain)
- *Yeni öneriler backlog'da kalır — `GDD.md` §16*

---

*Son güncelleme: 2026-07 — anlık reaksiyon §5.4 (v3); öncelik tablosu kaldırıldı.*
