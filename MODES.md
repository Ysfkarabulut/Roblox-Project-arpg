# Game Modes — PvP Arenalar, Ranked & PvE

> **Ana belge:** `GDD.md` §3 · §11 · §12  
> **Combat:** `COMBAT_STAT_SHEET.md` · **Status:** `STATUS_SYSTEM.md`

---

## 1. Üretim sırası (kilit yön)

MVP **en son** — önce mekanikler ve tam içerik.

| Faz | Odak | Çıktı |
|-----|------|--------|
| **F1 — Mekanik çekirdek** | Combat, status, kimya, stat sheet | Kod + tüm silah/off-hand davranışları |
| **F2 — İçerik** | Silah roster, eşya tabloları, boss roster, affix havuzu | Oynanabilir build çeşitliliği |
| **F3 — Modlar** | 1v1 / 2v2 / 3v3 arena + ranked; PvE boss | Tüm queue'lar çalışır |
| **F4 — Meta** | XP, loot, ekonomi, tutorial, progression | Tam döngü |
| **F5 — Playtest slice** | `MVP_CONTENT.md` tam test seti, denge pass | Dış playtest / soft launch |

---

## 2. Mod haritası (hedef ürün)

```
                    ┌─── LOBBY ───┐
                    │  Loadout    │
                    │  Stat       │
                    └──────┬──────┘
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
      ┌─────────┐    ┌─────────┐    ┌─────────┐
      │   PvP   │    │   PvE   │    │ (ileride)│
      │ Arenalar│    │  Boss   │    │ Dungeon │
      └────┬────┘    └────┬────┘    └─────────┘
           │              │
    1v1 / 2v2 / 3v3   1–3 kişi co-op
    Casual + Ranked   (Dungeon: Faz 2)
```

| Ana mod | Alt mod | Takım | Casual | Ranked |
|---------|---------|-------|--------|--------|
| **PvP — Duel** | 1v1 Arena | 1 vs 1 | ✅ | ✅ |
| **PvP — Skirmish** | 2v2 Arena | 2 vs 2 | ✅ | ✅ |
| **PvP — Clash** | 3v3 Arena | 3 vs 3 | ✅ | ✅ |
| **PvE — Boss** | Boss Fight | 1 / 2 / 3 co-op | ✅ | — * |
| **PvE — Dungeon** | *(ileride)* | 1–3 | — | — |

\* Boss için ranked / leaderboard ayrı tasarlanabilir (speedrun, score) — `§6` backlog.

---

## 3. PvP — Arena bracket’leri

Her bracket **ayrı arena** haritası ve **ayrı matchmaking kuyruğu**. Casual ile Ranked **aynı arena geometrisi**, farklı queue + kurallar.

### 3.1 Bracket özeti

| Bracket | Kod | Oyuncu | Arena adı (çalışma) | Rol vurgusu |
|---------|-----|--------|----------------------|-------------|
| **1v1** | `pvp_1v1` | 2 | **Duel Pit** | Birebir skill, stamina, kimya okuma |
| **2v2** | `pvp_2v2` | 4 | **Skirmish Yard** | Peel, focus fire, setup + burst |
| **3v3** | `pvp_3v3` | 6 | **Clash Ring** | Front / back line, AoE kimya, team combo |

### 3.2 Arena tasarım ilkeleri (kilit çerçeve)

| Bracket | Boyut (greybox) | Spawn | Not |
|---------|-----------------|-------|-----|
| **1v1** | ~**40×40** stud | Karşılıklı, **25** stud | Duvarlı; ranged ve melee dengeli |
| **2v2** | ~**55×45** stud | Takımlar karşılıklı 2 spawn noktası | Orta cover; chain reaksiyon menzili (12 stud) anlamlı |
| **3v3** | ~**65×55** stud | 3 spawn / takım | Biraz daha geniş; teamfight alanı |

- Tüm arena'larda: **sınırsız duvar**, düşme yok (MVP greybox kuralı)
- Countdown: **3s** → combat
- Friendly fire: **kapalı**

### 3.3 PvP maç akışı

1. Queue (casual veya ranked bracket seçimi)
2. Loadout kilidi (maç öncesi son **10s** *TBD*)
3. Arena yükleme + spawn
4. Countdown **3s**
5. Combat — win condition `§3.5`
6. Sonuç ekranı → lobby (ranked: MMR güncelleme)

### 3.4 Casual (unranked)

| Kural | Değer |
|-------|--------|
| Amaç | Pratik, build dene, kimya öğren |
| MMR | **Yok** |
| Eşleşme | Hız öncelikli; skill bandı gevşek (*TBD*) |
| Ödül | Düşük XP; Gacha Box düşüş şansı (`GDD.md` §10) |
| Maç süresi | **120s** sonra gaz fazı; maks **150s** (`§3.5`) |

### 3.5 PvP win condition (bracket ortak — kilit)

| Kural | Değer |
|-------|--------|
| Format | Tek round **elimination** |
| **1v1** | Rakip HP → **0** |
| **2v2** | Karşı takımın **tüm** üyeleri HP → **0** |
| **3v3** | Karşı takımın **tüm** üyeleri HP → **0** |
| Respawn | **Yok** — ölen oyuncu maçı izler (spectate) |
| Maç sonrası | Lobby'de full HP / stamina / status temizle |

#### Ölüm sırası (tiebreak — kilit)

Eş zamanlı ölüm nadir; çözüm: **ilk ölen kaybeder**.

| Durum | Kazanan |
|-------|---------|
| **1v1** — ikisi de aynı frame ölür | Daha **önce** ölen kaybeder; rakip kazanır |
| **2v2 / 3v3** — bir takım tamamen öldü | Karşı takım kazanır |
| **2v2 / 3v3** — her iki takım aynı anda wipe | **İlk ölen oyuncunun** takımı kaybeder |

*Sunucu `death_timestamp` (ms) tutar; aynı ms → spawn index / player id tiebreak (*implement detayı*).*

#### Gaz fazı (Casual vs Ranked — kilit)

Maç süresi dolunca arena **gaz** ile dolar. Gaz **anında öldürmez**; pozisyon baskısı yaratır.

| | **Casual** | **Ranked** |
|--|-----------|-----------|
| Normal combat | 0–**120s** | 0–**180s** |
| Gaz shrink | 120–**140s** (20s) | 180–**200s** (20s) |
| Gas DPS | 140–**150s** | 200–**230s** |
| **Maks süre** | **150s** | **230s** |
| Hasar tipi | Çevre hasarı; DR / matchup **yok** | Aynı |

```
Casual:  0s ──── 120s ── 140s ── 150s (hard cap)
Ranked:  0s ──── 180s ── 200s ── 230s (hard cap)
         │Combat│shrink│gas DPS│
                └─20s─┘
```

**Neden farklı?** Casual daha kısa → Roblox kitlesi ve mobil oyuncular için hızlı döngü. Ranked daha uzun → skill ifadesi ve strateji.

**Hard cap sonuç (kilit):** Hayatta kalan kazanır. Kimse kalmadıysa → **ilk ölen kaybeder** kuralı (`§3.5`).

*Gaz DPS ve shrink hızı → **kod + in-game playtest** (F1 combat / F3 arena). Tasarım hedefi yukarıda; sayılar implement sonrası ayarlanır.*

### 3.6 Ranked (bracket başına — kilit çerçeve)

Her bracket **kendi ranked ladder'ı** — 1v1 MMR, 2v2 MMR, 3v3 MMR **birbirinden bağımsız**.

| Kural | Değer |
|-------|--------|
| Queue | `pvp_1v1_ranked` · `pvp_2v2_ranked` · `pvp_3v3_ranked` |
| Rating | Bracket başına **MMR** + görünür **tier** (fantezi isimler — aşağıda) |
| Eşleşme | MMR bandı + genişleyen arama süresi (*formül TBD*) |
| Sezon | Periyodik reset — süre **TBD** (ör. 8–12 hafta) |
| Win / loss | Maç sonucu MMR günceller — **kazanma/kaybetme puanı TBD** |
| Win condition | Casual ile **aynı** (`§3.5` — gaz dahil) |
| Party | **2v2 / 3v3:** solo da queue'a girebilir. Öncelik **premade vs premade**. Timeout sonrası sınırlı filler (`§5b`). **Full premade**, karşıda **tamamı solo** takım ile **eşleşmez**. |

#### Tier isimlendirme (kilit)

Bronze / Platinum **yok** — arena temalı ladder.

| Sıra | Tier |
|------|------|
| 1 | **Rookie** |
| 2 | **Contender** |
| 3 | **Veteran** |
| 4 | **Champion** |
| 5 | **Gladiator** |

*Ara bölümler (ör. Rookie II, III) ve **MMR eşikleri** playtest sonrası. Win/loss puan delta'sı henüz belirlenmedi.*

#### Sezon ödülleri (kilit yön)

Sezon boyunca bracket MMR'si belirli **eşiklere** ulaşan oyunculara ödül — **kozmetik** veya **title (unvan)**.

| Ödül tipi | Örnek |
|-----------|--------|
| **Title** | "Duel Pit Veteran", "Clash Ring Ascendant" |
| **Kozmetik** | Arena intro efekti, kill banner, lobby rozeti |
| **Kural** | Ödül **sezon sonunda** kilitleme; stat gücü **yok** |

*Eşik MMR değerleri ve tier tablosu playtest sonrası — çerçeve: her bracket ayrı ödül track'i.*

**UI:** Lobby'de mod seçimi → bracket (1v1 / 2v2 / 3v3) → **Casual** | **Ranked** toggle.

---

## 4. PvE — Faz 1: Boss Fight (ilk içerik)

Dungeon **yok** — her encounter **tek boss'luk**, phase'lerle gelişen mekaniklere sahip **ayrı arena / oda**. İleride dungeon katmanı eklenecek (`§5`).

### 4.1 Yapı (kilit)

| Öğe | Açıklama |
|-----|----------|
| **Encounter** | **Tek boss** — phase phase **yeni mekanikler** eklenir / evrilir |
| **Arena** | Boss başına özel alan (platform, tehlike bölgeleri, cover) |
| **Party** | **1**, **2** veya **3** oyuncu (queue veya davet) |
| **Wave** | Bazı boss'larda phase öncesi add wave (*boss başına tasarım*) |
| **Win** | Boss HP → **0** (tüm phase'ler) |
| **Lose** | Tüm oyuncular HP → **0** |
| **Retry** | Boss odasından çıkış → lobby / yeniden queue |

### 4.2 Boss tasarım çerçevesi

| Konu | Yön |
|------|-----|
| Phase | Min **2** — her phase **farklı mekanik seti** (yeni saldırı, arena değişimi, element pivot) |
| Örnek pivot | Fire immune → Water build teşvik; phase 2'de alan gazı, phase 3'te enrage pattern |
| Roller | Tank (guard/shred), setup (Wet/DoT), burst (reaksiyon), heal (*item TBD*) |
| HP ölçeği | **Katılımcı sayısına göre artar** — `§4.2b` |
| Enrage | Soft timer opsiyonel — *boss başına* |
| Loot | Gacha Box + **boss-exclusive** drop (`GDD.md` §10) |
| Tekrar | Sınırsız farm (*günlük lock TBD*) |

#### 4.2b Party HP scale (kilit çerçeve)

Boss **base HP** solo için tanımlanır; party büyüdükçe **ölçeklenir** (daha fazla oyuncu = daha fazla toplam HP).

| Party | HP çarpanı (taslak) |
|-------|---------------------|
| **1** (solo) | **×1.0** |
| **2** (duo) | **×1.75** |
| **3** (trio) | **×2.50** |

*Formül playtest ile ayarlanır; hedef: solo zor ama mümkün, trio rahat değil — mekanik okuma şart.*

*Boss damage scale: varsayılan **sabit** (party size boss hasarını artırmaz); zorluk HP ile.*

### 4.3 Boss queue

| Queue | Party | Matchmaking |
|-------|-------|-------------|
| `pve_boss_solo` | 1 | Tek oyuncu → instance |
| `pve_boss_duo` | 2 | Duo queue veya invite |
| `pve_boss_trio` | 3 | Trio queue veya invite |

*Aynı boss, farklı party size = farklı HP / damage scale tablosu.*

### 4.4 Boss roster

| ID | Boss adı | Element | Phase | Wave? | Not |
|----|----------|---------|-------|-------|-----|
| `boss_01` | **The Eye** | Neutral | **3** | Hayır | İlk implement — `§4.6` |
| `boss_02` | **The Breaker** | Steel | **3** | Hayır | Mobil melee — `§4.7` |
| `boss_03` | *TBD* | | | | |

### 4.6 Boss spec — The Eye (`boss_01`)

> **Element:** Neutral · **Konum:** Arena tam merkezi, **sabit** (hareket etmez)  
> **Görsel:** Devasa göz · **İlk implement boss**

#### Genel

| Öğe | Değer |
|-----|--------|
| Arena | Dairesel / kapalı platform; boss ortada |
| Element pivot | Yok (Neutral) — mekanik okuma odaklı |
| Phase geçişi | **%70** HP → Phase 2 · **%30** HP → Phase 3 |
| **Hedef süre** | Ortalama **~3 dakika** (180s) — party size ve skill'e göre sapma normal |

#### Süre & denge (kilit hedef — sayılar kod sonrası)

| Öğe | Yön |
|-----|-----|
| **Ortalama kill süresi** | **~180s** (iyi-orta party; solo daha uzun kabul edilir) |
| **HP tuning** | Solo base HP + party scale (`§4.2b`); DPS çıktısına göre phase geçişleri ~**60s / 70s / 50s** bandı hedeflenir |
| **Hasar sayıları** | Işın, Monolith aura, Tentacle stack — **implement + playtest** (F2/F3) |
| **Ölüm mekanikleri** | Monolith düşüşü / Gaze = anında ölüm — süreyi **kısaltmaz**, skill check |

*Sahte stat tablosu yazılmaz; ilk greybox'ta placeholder HP, playtest log'larıyla ~3 dk'ya çekilir.*

---

#### Ortak — Rotating Beam (tüm phase'ler)

Süre **arena başlar başlamaz** işler; ilk ışın **10. saniyede** tetiklenir.

| Kural | Değer |
|-------|--------|
| Döngü | Işın **5s** sürer → **10s** bekleme → sonraki ışın |
| Işın 1 | Boss'u ortadan kesen **tek çizgi** — arena boyunca |
| Işın 2+ | Her kullanımda **+1 çizgi** eklenir |
| Işın 2 şekli | **"+"** — iki dik çizgi, arena boyunca |
| Işın 3–4 (P2+) | **"+"** ve **"×"** üst üste — toplam **4 çizgi** (maks) |
| Hareket | Işın(lar) boss merkez etrafında **5s** boyunca **döner** |
| Oyuncu | Işından kaçınmak için boss etrafında **orantılı hareket** (beam ile birlikte dönme hissi) |
| Hasar | Işında kalırsan **yüksek** hasar (*sayı playtest*) |
| Cast pause | Boss **4s Monolith Gaze** cast'inde (`P2`) ışınlar **oluşmaz** |

```
Zaman:  0s ──10s── beam ──15s── wait ──25s── beam(+) ── ...
        │        │ 5s rot │ 10s   │
```

---

#### Phase 1 — %100 → %70

Yalnızca **Rotating Beam** (1 → 2 çizgiye kadar büyür).

---

#### Phase 2 — %70 → %30

**Rotating Beam** devam (maks **4 çizgi**) + **Monolith** dizisi.

##### Monolith saldırısı (15s)

| Adım | Detay |
|------|--------|
| Süre | **15s** boyunca her **3s**'de bir → toplam **5** Monolith |
| Telegraf | Düşüş noktasında **kırmızı alan** → **1s** sonra taş iner |
| İsabet | Alanda kalan → **anında ölüm** |
| Kısıt | Arena **en dış kenarına** veya **boss üstüne** düşemez |
| Yere inince | Monolith etrafında **aura** — yakında duranlar **sabit DPS/s** |

##### Monolith Gaze (15s dizisi bitince)

| Adım | Detay |
|------|--------|
| Cast | Boss **4s** cast |
| Kural | Oyuncu ile boss arasında **Monolith** (LOS block) olmalı |
| Sonuç | Arada Monolith **olmayan** oyuncular → **anında ölüm** |
| Işın | Cast süresince yeni ışın **yok** |

*Strateji: 5 Monolith'i cover / aura yönetimi için kullan; Gaze'de saklan.*

---

#### Phase 3 — %30 → %0

**Rotating Beam** (maks 4) + **Monolith** döngüsü devam + **Tentacle**.

##### Tentacle

| Kural | Değer |
|-------|--------|
| Spawn | Her **15s**'de **1** Tentacle |
| Hedef | Kendisine **en uzak** oyuncu |
| Görsel | Oyuncuya **bağlı ışın** (tether) — sürekli hasar |
| Can | **Düşük** — hızlı focus ile öldürülebilir |
| Tehdit | Öldürülmezse verdiği hasar **her saniye katlanır** (stack / çarpan) |
| Öncelik | Uzak oyuncu kitleme — pozisyon ve focus fire |

---

#### Roller (The Eye)

| Rol | Neden |
|-----|--------|
| **Mobility** | Dönen ışın + Monolith telegraf |
| **Positioning** | Gaze'de Monolith arkası |
| **Focus / DPS** | Tentacle ve phase süresi baskısı |
| **Tank** | Aura ve beam chip — guard sınırlı fayda (anında ölüm mekanikleri) |

*Kimya zorunlu değil; Neutral boss — mekanik mastery testi.*

---

#### Loot (çerçeve)

- Gacha Box (şansla) + **The Eye-exclusive** drop havuzu (*item isimleri içerik fazında*)

### 4.7 Boss spec — The Breaker (`boss_02`)

> **Element:** Steel · **Konum:** Arena içinde **mobil** — aggro hedefini kovalar  
> **Görsel:** Ağır zırhlı dövüşçü / golem-breaker (greybox)  
> **Cleave yok** — melee DPS sürekli arkaya geçmek zorunda değil.

#### Genel

| Öğe | Değer |
|-----|--------|
| Arena | Eye ile aynı dairesel platform (~80 stud) |
| Phase geçişi | **%70** HP → Phase 2 · **%30** HP → Phase 3 |
| Hedef süre | ~**180s** |
| Hareket | Aggro hedefine yürür; tank melee bandında tutulur |

#### Phase 1 — %100 → %70

**Pursuit + Aggro Strike** (Eye Iris Pulse karşılığı — tank mekaniği)

| Kural | Değer |
|-------|--------|
| Pursuit | Boss aggro hedefine sürekli yürür (party max sprint’inden yavaş) |
| Aggro Strike | Yalnızca **threat lideri**; LA ritmi: **1.35s** telegraf → vuruş |
| Vuruş aralığı | **5s** (hit → hit); ilk döngü **~3.65s** sonra başlar |
| Hasar | Orta burst; guard / parry / dodge / fortify geçerli |
| Menzil | Aggro hedefi boss’a yakın değilse boss yaklaşır; pulse **mesafe iptal etmez** (uzak aggro = `far` ceza opsiyonel) |

**Rust Mark** (P1 ikinci mekanik — herkes)

| Kural | Değer |
|-------|--------|
| Sıklık | ~**12s** döngü (Pursuit ile çakışmayacak şekilde kodda fazlama) |
| Hedef | Party’den **rastgele 1** oyuncu (tank ağırlığı düşük — çoğunlukla DPS/healer) |
| Telegraf | Ayak altında kırmızı daire · **1.2s** |
| Sonuç | Dairede kalırsan orta hasar; hareket et — **boss yönü / arka cephe şart değil** |

*Tank: aggro strike soak. Melee/ranged: Rust Mark’tan kaç. Kimse sürekli flank zorunluluğu yok.*

#### Phase 2 — %70 → %30

**Pursuit + Aggro Strike** devam (vuruş aralığı **4s**).

**Shoulder Charge**

| Kural | Değer |
|-------|--------|
| Sıklık | ~**18s** |
| Hedef | Party’de **en uzak** oyuncu |
| Telegraf | **1.5s** çizgi / işaret |
| Sonuç | Düz charge; yol üstü orta hasar; guard chip azaltır |

#### Phase 3 — %30 → %0

**Pursuit + Aggro Strike** devam (vuruş aralığı **3s**).

**Cataclysm Slam** (caster-merkezli — herkes)

| Kural | Değer |
|-------|--------|
| Sıklık | ~**16s** |
| Davranış | Boss **durur**, merkezde geniş daire telegrafı |
| Alan | Boss **HumanoidRootPart** merkezli · ~**26 stud** yarıçap (tune) |
| Telegraf | **2.75s** (walk + guard slow + ~0.4s reaksiyon ile çıkılabilir; bkz. not) |
| Sonuç | Alanda kalanlar yüksek hasar; **tank dahil herkes** dışarı çıkar |
| Not | Tank-only slam yok; melee DPS flank zorunluluğu yok — **radial kaçış** |

#### Roller (The Breaker)

| Rol | Neden |
|-----|--------|
| **Tank** | Aggro + Pursuit soak; Aggro Strike guard; Cataclysm’den kaç |
| **Melee DPS** | Rust Mark + Cataclysm kaçışı; boss’a yakın DPS — cleave yok |
| **Ranged** | Rust Mark, Shoulder Charge, Cataclysm |

#### Loot (çerçeve)

- Gacha Box + **The Breaker-exclusive** drop havuzu (*Steel boss blades — içerik fazında*)

### 4.5 PvE maç akışı

1. Boss + party size seç
2. Loadout kilidi
3. Boss odası yükleme (kısa giriş koridoru opsiyonel)
4. Intro / countdown
5. Combat (phase geçişleri)
6. Win → loot ekranı → lobby · Lose → retry / lobby

---

## 5. PvE — Faz 2: Dungeon (ileride — çerçeve)

> **Durum:** Tasarım yönü kilit; implement **boss fazından sonra**.

| Öğe | Hedef |
|-----|--------|
| Yapı | Bağlı odalar veya linear koridor + odalar |
| İçerik | Trash mob + mini encounter + **son odada boss** |
| Party | 1–3 (boss ile aynı) |
| Süre | Run başına **15–25 dk** hedef (*TBD*) |
| Loot | Run sonu chest + boss drop |
| Tekrar | Key / stamina sistemi *TBD* |

**Boss Fight'tan fark:** Dungeon = yol + kaynak yönetimi + trash; Boss Fight = doğrudan encounter testi ve farm.

**Paylaşılan sistemler:** Aynı combat, status, kimya, loadout, party scale kuralları.

---

## 5b. Party, queue & place topology (kilit)

### Party

| Kural | Değer |
|-------|--------|
| Max size | **3** |
| Queue yetkisi | Yalnızca **parti lideri** queue başlatır / iptal eder |
| Üye | Lider queue'dayken **Ready** olmalı; ayrılırsa queue iptal |
| Davet | Lobby'de invite / join |

### Queue eşleşme (PvP — kilit)

| Bracket | Queue'a kim girer | Öncelik (hemen) | Filler (timeout sonrası) | Yasak |
|---------|-------------------|-----------------|---------------------------|-------|
| **1v1** | Solo | Solo vs solo | — | — |
| **2v2** | Solo **veya** parti 2 | **P2 vs P2** | **S+S vs S+S** | **P2 vs S+S** |
| **3v3** | Solo, parti 2 veya 3 | **P3 vs P3** | **(P2+S) vs (P2+S)** | **P3 vs S+S+S**; S+S+S takım kurulmaz |

| Sabit | Değer |
|-------|--------|
| `FillerTimeoutSec` | **45** (`QueueConfig`) |

**Amaç:** Premade iletişim avantajı korunur; uzun beklemeyi solo/filler ile yumuşatmak. Full stack asla “üç rastgele solo”ya düşmez.

Casual ve Ranked **aynı** eşleşme kuralları (MMR bandı ayrı katman).

### Place ayrımı (loading screen)

| Place | Rol |
|-------|-----|
| **Lobby** | Loadout, stat, parti, mod seçimi, queue |
| **PvP arenas** | Bracket başına ayrı place (`pvp_1v1`, `pvp_2v2`, `pvp_3v3`) — Teleport + loading |
| **Boss arenas** | Boss başına ayrı place (`pve_boss_*`) — Teleport + loading |

Maç bitince → sonuç → **Lobby**'ye teleport.

---

## 6. Lobby UX (mod seçimi)

```
[ LOADOUT ]  [ STATS ]  [ (SHOP) ]

── PvP ──────────────────────────────
  Duel (1v1)      [ Casual ]  [ Ranked ]
  Skirmish (2v2)  [ Casual ]  [ Ranked ]
  Clash (3v3)     [ Casual ]  [ Ranked ]

── PvE ──────────────────────────────
  Boss Fight      [ Solo ]  [ Duo ]  [ Trio ]
  Dungeon         (yakında)

[ QUEUE ]  veya  [ PARTY INVITE ]
```

---

## 7. Açık konular (mod backlog)

- [x] Gaz zaman çizelgesi: **180s + 20s shrink + ~30s DPS** → max **230s** (`§3.5`)
- [x] Ranked tier isimleri: **Rookie → Gladiator** (`§3.6`)
- [x] İlk boss: **The Eye** + **~3 dk** hedef süre (`§4.6`)
- [x] 2v2/3v3 solo queue + premade öncelik + sınırlı filler (`§5b`)
- [ ] Gaz DPS — **kod sonrası** playtest (`§3.5`)
- [ ] Ranked MMR eşikleri, win/loss puan delta
- [ ] Sezon MMR eşik tablosu (ödül tier'ları)
- [ ] The Eye hasar / HP — **kod sonrası** playtest (`§4.6`)
- [ ] Dungeon key / stamina ekonomisi
- [ ] Spectate kamera (ölünce 2v2/3v3)

---

*Son güncelleme: 2026-07 — solo 2v2/3v3; filler timeout; premade ≠ all-solo.*
