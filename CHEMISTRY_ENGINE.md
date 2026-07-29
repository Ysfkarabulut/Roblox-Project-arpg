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
| Main **Staff** | **2** (2H INT) |
| Main **Bow / Crossbow** | **2** (teknik 2H sınıf) |
| Off — 1H / Shield / Focus (tag varsa) | 1 |
| Off — **Weapon Knot** (tagsiz) | 0 |
| Off — **Quiver** (tagsiz) | 0 |
| Chest (tag varsa) | 1 |
| Neutral tag | 0 |

**Loadout:**
- **2H melee / Staff** → off = Knot (tagsiz)
- **Bow / Crossbow** → off = Quiver (tagsiz); sinerji = **main (×2) + chest (×1)**
- **1H melee** → off = Shield / 1H / Focus / Wand (tag kuralları itema göre)

### 3.2 Sinerji bandı seçimi

| Band | Koşul |
|------|-------|
| **Pure x3** | Tek non-Neutral element; toplam ağırlık **3** |
| **Duality** (x2+x1) | İki element; ağırlık **2 + 1** |
| **Harmony** (x1+x1+x1) | Üç farklı non-Neutral; ağırlık **1+1+1** — **yalnızca Main ×1** (1H) ile mümkün |
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

### 3.5 Harmony — x1+x1+x1

+15 flat Status Potency.

**Mantık (kilit):** Harmony = Main **×1** + Off **×1** + Chest **×1**, üç farklı non-Neutral element. Main ağırlığı **×2** olan hiçbir silah (tüm **2H melee**, **Staff**, **Bow**, **Crossbow**) bu banda **giremez** — matematiksel olarak 2+1+1 ≠ 1+1+1. Knot / Quiver tagsiz (×0) olduğu için 2H loadout’ta zaten üçüncü ×1 slot yok.

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
- Aynı frame'de bir hedefe yalnızca **bir** zincir status. R2 ve R8 aynı Wet için yarışırsa **FIFO** — hangi status Wet çiftini önce tamamladıysa o zincir tetiklenir.

### 5.3 Wild Fire AoE (R9)

- Ana hedefte Windy + Ignite tüketilir → **WildFire** DoT.
- Her **1s** tick: **8** stud yarıçap; çevredeki düşmanlara **yalnızca tick hasarı** (WildFire status yazılmaz).
- Çevre hasarı: Resist uygulanır; matchup ve DR **yok**.

### 5.4 Batch-frame reaksiyon çözümü (kilit v4 — C yöntemi)

**Öncelik tablosu yok.** Eşleşen iki status varsa önceliğe bakmaksızın reaksiyon tetiklenir. Takım oyunu koordinasyona dayanır.

#### Temel kural

Aynı sunucu tick'inde (heartbeat / frame) bir hedefe gelen **tüm yeni status'ler** bir **batch** olarak toplanır ve tick sonunda topluca çözülür.

#### Akış

```
OnTickEnd(target)
  1. Bu tick'te hedefe eklenen tüm yeni status'leri BATCH listesine al
  2. BATCH + hedefteki MEVCUT status'ler → tüm olası çiftleri bul
  3. Bulunan HER geçerli çift için:
     a. İki girdi silinir (batch'ten veya mevcut listeden)
     b. Reaksiyon hasarı / VFX anında
     c. Süreli çıktı varsa hedefe yazılır (Chilled, WildFire, Shock, …)
  4. Çift oluşturmayan status'ler hedefte kalır
```

**Aynı tick'te birden fazla reaksiyon:** Mümkün — paylaşılan girdi yoksa. Paylaşılan girdi varsa **FIFO** tek çift seçer.

**Çift seçimi (aynı status birden fazla adayla eşleşirse):** **FIFO** — aynı tick içinde `ApplyStatus` **uygulama sırası** (sunucu kayıt sırası). İlk gelen status, mevcut havuzla eşleşebildiği **ilk geçerli reaksiyonu** tetikler; paylaşılan girdi tüketilir. **R1–R10 tablo ID'si tiebreak için kullanılmaz.**

#### Örnekler

**Örnek 1:** Hedefte Wet. Bu tick'te Ignite gelir:
- Wet+Ignite → **Vaporize** · ikisi silinir

**Örnek 2 (FIFO — sıra kritik):** Hedefte Wet. Aynı tick'te Ignite + Shock gelir:
- Sıra **Ignite → Shock:** Wet+Ignite = **Vaporize**; Shock çiftsiz kalır
- Sıra **Shock → Ignite:** Wet+Shock = **Chain Shock**; Ignite çiftsiz kalır

**Örnek 3 (takım koordinasyonu):** Hedefte hiçbir şey yok. Oyuncu A: Wet, Oyuncu B: Ignite **aynı tick'te** uygular:
- Batch FIFO sırasına göre Wet+Ignite → **Vaporize** — koordinasyon ödüllendirilir

**Örnek 4 (bağımsız çiftler):** Hedefte Bleed. Aynı tick'te Ignite + Poisoned:
- Bleed+Ignite = **Cauterize**; Poisoned çiftsiz kalır *(veya sıraya göre Bleed+Poisoned = Blight, Ignite kalır)* — FIFO

**Örnek 5 (koordinasyon — farklı tick):** A: Wet (tick N), B: Shock (tick N+1), C: Ignite (tick N+1):
- Tick N: Wet kalır
- Tick N+1: batch FIFO sırası hangi status önce geldiyse o Wet ile eşleşir

#### Thaw özel kuralı

Thaw aktifken hedefe **Ignite uygulanamaz** (affix, Pure x3, yetenek). Ignite gelmeden önce kontrol edilir.

#### Zincir reaksiyonlar (R2, R8)

Alan zinciri tetiklenince her etkilenen hedef için **ayrı** `ApplyStatus` (kendi §5.4 sırası). Bkz. §5.2.

---

## 6. v1 dışı reaksiyon adayları (brainstorm)

- Rock + Bleed → **Shatter** (savunma kırma)
- Lightning + Poisoned → **Neurotoxin** (stamina drain)
- *Yeni öneriler backlog'da kalır — `GDD.md` §16 · evde polish `README` §3*

---

## 7. UI — reaksiyon ipuçları (Gear inspect, 2026-07)

Oyuncuya kimya **öğretici** katman (tam simülasyon değil):

| UI | Dosya | İçerik |
|----|-------|--------|
| Stats panel | `GearUI` | SYNERGY band + 4 satır reaction primer |
| Item hover/detail | `ItemTooltip` + `InspectHints` | Build synergy (`derived`) · element reaction list · 5 satır primer |
| Ability hover | `AbilityTooltip` | Status uygulayan skill → ilgili `ReactionTable` çiftleri |

Primer metni `ReactionTable.List` ile senkron. FIFO kuralı tooltip’te belirtilir.

*Yeni reaksiyon çifti eklendiğinde `ReactionTable` + bu UI otomatik genişler; VFX/ikon polish evde backlog.*

---

*Son güncelleme: 2026-07 — §7 inspect UI; reaksiyon §5.4 (v6); batch + FIFO.*
