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
| Ödül | Düşük / yok (*economy TBD*) |
| Timeout | **120s** — sonuç **TBD** (`GDD.md` §16) |

### 3.5 PvP win condition (bracket ortak — kilit çerçeve)

| Kural | Değer |
|-------|--------|
| Format | Tek round **elimination** |
| **1v1** | Rakip HP → **0** |
| **2v2** | Karşı takımın **tüm** üyeleri HP → **0** |
| **3v3** | Karşı takımın **tüm** üyeleri HP → **0** |
| Respawn | **Yok** — ölen oyuncu maçı izler (spectate) |
| Süre limiti | **120s** — timeout sonucu **TBD** |
| Maç sonrası | Lobby'de full HP / stamina / status temizle |

*2v2 / 3v3'te son hayatta kalan takım kazanır; eş zamanlı ölüm → **TBD** (draw / sudden death).*

### 3.6 Ranked (bracket başına)

Her bracket **kendi ranked ladder'ı** — 1v1 MMR, 2v2 MMR, 3v3 MMR **birbirinden bağımsız**.

| Kural | Değer |
|-------|--------|
| Queue | `pvp_1v1_ranked` · `pvp_2v2_ranked` · `pvp_3v3_ranked` |
| Rating | Bracket başına **MMR** (veya görünür tier + gizli MMR — *TBD*) |
| Eşleşme | MMR bandı + genişleyen arama süresi (*TBD*) |
| Sezon | Periyodik reset — süre **TBD** |
| Ödül | Sezon sonu kozmetik / unvan (*economy TBD*) |
| Party | 2v2 / 3v3 ranked: **premade** veya solo queue *TBD* |
| Win condition | Casual ile **aynı** (`§3.5`) |

**UI:** Lobby'de mod seçimi → bracket (1v1 / 2v2 / 3v3) → **Casual** | **Ranked** toggle.

---

## 4. PvE — Faz 1: Boss Fight (ilk içerik)

Dungeon **yok** — yalnızca **boss odası** encounter'ları. İleride dungeon katmanı eklenecek (`§5`).

### 4.1 Yapı (kilit)

| Öğe | Açıklama |
|-----|----------|
| **Encounter** | Tek boss, **phase** tabanlı |
| **Party** | **1**, **2** veya **3** oyuncu (queue veya davet) |
| **Wave** | Bazı boss'larda phase öncesi add wave (*boss başına tasarım*) |
| **Win** | Boss HP → **0** (tüm phase'ler) |
| **Lose** | Tüm oyuncular HP → **0** |
| **Retry** | Boss odasından çıkış → lobby / yeniden queue |

### 4.2 Boss tasarım çerçevesi

| Konu | Yön |
|------|-----|
| Phase | Min **2** — mekanik / element pivot (ör. Fire immune → Water build teşvik) |
| Roller | Tank (guard/shred), setup (Wet/DoT), burst (reaksiyon), heal (*item TBD*) |
| HP ölçeği | Party size ile scale — formül **TBD** |
| Enrage | Soft timer opsiyonel — *boss başına* |
| Loot | Boss kill → drop table (*economy TBD*) |
| Tekrar | Günlük / haftalık lock *TBD* |

### 4.3 Boss queue

| Queue | Party | Matchmaking |
|-------|-------|-------------|
| `pve_boss_solo` | 1 | Tek oyuncu → instance |
| `pve_boss_duo` | 2 | Duo queue veya invite |
| `pve_boss_trio` | 3 | Trio queue veya invite |

*Aynı boss, farklı party size = farklı HP / damage scale tablosu.*

### 4.4 Boss roster (şablon — doldurulacak)

| ID | Boss adı | Element tema | Phase sayısı | Wave? | Not |
|----|----------|--------------|--------------|-------|-----|
| `boss_01` | *TBD* | | | | İlk implement boss |
| `boss_02` | *TBD* | | | | |
| `boss_03` | *TBD* | | | | |

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

- [ ] PvP timeout sonucu (120s)
- [ ] 2v2 / 3v3 eş zamanlı ölüm tiebreak
- [ ] Ranked tier isimleri, MMR formülü, sezon süresi
- [ ] 2v2 / 3v3 solo queue vs premade only ranked
- [ ] Boss HP / damage party scale formülü
- [ ] Boss ranked / leaderboard (speedrun, score) — evet/hayır
- [ ] İlk 3 boss konsepti + phase listesi
- [ ] Dungeon key / stamina ekonomisi
- [ ] Spectate kamera (ölünce 2v2/3v3)

---

*Son güncelleme: 2026-07 — PvP 3 bracket + ranked; PvE boss önce, dungeon sonra.*
