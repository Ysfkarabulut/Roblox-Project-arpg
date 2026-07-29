# Blade Asset Prompts (Meshy AI)

Roblox modular weapon **blade module** — handle ve pommel ayrı; **integral guard/collar blade mesh’inde** (grip gizlenir, guard görünür).

| Alan | Değer |
|------|--------|
| Araç | [Meshy AI](https://www.meshy.ai) — **Image to 3D** öncelikli · Text to 3D yedek |
| Meshy ayarı | **Model Type → Low Poly** · Pose **None** |
| Görsel hedef | Chunky low-poly mobil MMO · el boyalı fairytale fantasy · okunaklı siluet |
| Prompt prefix | Chunky MMO fairytale blok (aşağıda) — AI prompt kutularında tam metin |
| Roblox hedef | `ReplicatedStorage/WeaponMeshes/<meshKey>` |
| Pivot | Tang/socket ucu — **guard’ın altında**, handle birleşim noktası |

**Silhouet (tier):** Common = sade · Rare = ornate accent · Exotic = belirgin farklı form · Boss = boss tema

**ST vs AoE görsel ayrımı** — sadece **Dagger** ve **1H/2H Sword** (keskin siluet okunur). **Axe, Mace, Wand, Staff, Scepter** (ve aynı mantıktaki 2H axe/mace) için ST/AoE **görsel kodlama yapma** — oyuncu ST/AoE’yi siluetten okumaz; item’lar birbirinden farklı, tier farkı net olsun yeter.

---

## Görsel ayrım politikası

| Aile | ST vs AoE siluet | Odak |
|------|------------------|------|
| Dagger, Sword (1H/2H) | **Evet** — ince thrust vs geniş sweep/cleave (prompt tuzakları geçerli) | Combat okuması + tier |
| Axe, Mace (1H/2H) | **Hayır** | 4 common/rare **farklı tasarım** + exotic/boss; tier sade → ornate → tema |
| Wand, Staff, Scepter, Bow, Crossbow | **Hayır** | Cap/head/prod **form çeşitliliği** + tier |

**Pratik:**
- Axe/Mace (1H/2H): hatchet vs timber gibi **iki common görünüm** — hangisi ST hangisi AoE **önemsiz**.
- Wand/Staff/Scepter/Bow/Crossbow: her item **farklı cap/head/prod**; tier = sade → ornate → exotic/boss tema.
- Bu ailelerde prompt’tan çıkar: `ST`, `AoE`, `broader than`, `cone sweep`, `single-target`, `spread magic wider`, `volley fan`, `silhouette AoE/ST`.
- **meshKey:** ST ve AoE aynı meshKey paylaşabilir — çeşitlilik tier/item için.

**Tier texture notu:** Meshy’den nötr/geo çıkar → final renk **hand-painted texture** (Aseprite/Photoshop) ile. Element rengi oyunda **gem orb** — blade’i nötr steel/crystal tut.

---

## Prompt şablonu (tüm blade promptları bu yapıda)

**Blade modülü = gövde + integral guard/collar + tang** (grip/kabza yok — handle gizli tutar).

**Metal blade / sword / dagger / crossbow prod:**

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, [PARÇA + SİLUET + TEMA], [TIER ACCENT], [INTEGRAL GUARD — aileye uygun], flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

**Integral guard türleri (aile):**

| Aile | Guard tipi |
|------|------------|
| Dagger | Küçük quillon / swept quillon (minimal → ornate) |
| 1H/2H Sword | Crossguard (soldier → great crossguard) |
| Axe / greataxe | Socket collar band (haft gözü) |
| Mace / hammer | Socket flange collar |
| Wand / staff / scepter | Arcane socket ring / holy crook collar |
| Bow limbs | Center limb socket bridge (grip gap) |
| Crossbow prod | Stock mounting bracket |

**Wand / staff / scepter cap** — socket collar + `flat socket stub below collar`

**Bow limbs** — `integral center socket bridge` + `open center gap flat mount` (crossguard yok)

**Tier accent kelimeleri:**
- Common → `plain warm steel-gray minimal detail chunky readable silhouette`
- Rare → `rare ornate gold-steel filigree hints light engraved accent lines`
- Exotic → `exotic distinct silhouette subtle soft emissive rune grooves not neon`
- Boss · The Eye → `void purple eye-crack accents sinister arcane boss theme`
- Boss · The Breaker → `rusted seismic fracture accents industrial war boss theme`

**Image to 3D kısa metin:**

```
AQ3D style low poly chunky cartoon modular part only, no handle, white untextured model
```

### Dagger AoE — görsel tuzak (fan ≠ balta başı)

`fan-shaped` / `fan cleave` yazınca AI **yarım daire balta başı** çizer (üstten bakış). Common AoE dagger = **yan profilde uzun hançer**; sadece kesim kenarı geniş/kavisli.

| Yanlış (çıkan) | Doğru (hedef) |
|----------------|---------------|
| Semicircle / axe head / fan disc | Elongated vertical dagger blade |
| Genişlik > uzunluk | Uzunluk ≈ 2.5–3× genişlik |
| İki uçta simetrik nokta | Tek keskin uç + tang dipte |

2D concept’te mutlaka: `orthographic SIDE view vertical orientation` + `NOT axe head NOT semicircular fan disc`.

### 1H Sword AoE — görsel tuzak (**sadece Common** `b_sword_aoe`)

**Rare `b_sword_aoe_r` Rendblade için cleaver/slab doğru** — aşağıdaki tuzak common’a uygulanır, rare’a değil.

`wide cleaver` / `cleaver sword` yazınca AI **kısa stubby butcher cleaver** çizer. Common AoE = **uzun** one-handed sword (Longblade ile aynı boy); sadece belly ve cutting edge **biraz** geniş — broadsword / falchion.

| Yanlış (common’da çıkan) | Doğru (common hedef) |
|--------------------------|----------------------|
| Meat cleaver / butcher blade / kısa slab | Arming sword / broadsword / falchion |
| Genişlik ≥ uzunluk, stubby | Uzunluk ≈ 3–4× genişlik (Longblade ile aynı boy) |
| Dikdörtgen cleaver slab | Klasik kılıç taper, belirgin point |

**ST vs AoE common:** Longblade = düz thrust; Wide Cleaver = aynı uzunluk, hafif geniş belly. Common prompt’ta `cleaver` **kullanma**.

2D concept: `same length as longblade` + `NOT cleaver NOT butcher NOT short stubby`.

### 1H Sword AoE — Rare hedef (`b_sword_aoe_r` Rendblade)

Slab cleaver **istenen** — görsel referans: geniş slab profil, dişli rend cutting edge, ortada altın filigree panel, chunky notched guard. Common’dan **kısa/geniş** olabilir; rare tier read.

| Common Wide Cleaver | Rare Rendblade |
|---------------------|----------------|
| Uzun broadsword / falchion | Wide slab cleaver |
| Sade steel, minimal | Gold filigree, battle wear |
| Düz / hafif geniş kenar | Jagged saw-tooth rend notches |


---

## Meshy Agent (Beta) — kopyala-yapıştır brief

Workspace → Agent (`meshy.ai/workspace?sidebar=agent`).

### Oturum açılışı

```
Project context — read carefully before generating anything:

I'm building a Roblox ARPG with MODULAR weapons assembled from:
- HANDLE (8 types) — I model myself, do NOT generate
- BLADE / HEAD / LIMB module — YOUR task
- POMMEL / STRING — separate, do NOT generate

CRITICAL: Output blade/head **module** with integral guard or socket collar included — NOT a complete weapon.
NO grip, NO handle shaft, NO pommel, NO stock, NO bow string, NO hands.

Art style for ALL assets:
AQ3D Adventure Quest 3D look — low poly chunky cartoon fantasy MMO, hand-painted cel shading feel, whimsical fairytale mood, warm steel highlights, readable silhouettes, mobile-friendly. NOT grim dark, NOT realistic, NOT painterly concept art.

Technical:
- Orthographic side-view 2D concepts first, white background
- Integral guard/collar at blade base, flat tang/socket **below** guard (two rivet holes)
- Poly budget: low poly under ~2000 tris
- Neutral steel / crystal (element color = separate gem in-game)

Workflow:
1. Generate 4 side-view 2D concepts — blade module with guard, no grip
2. I pick one — lock style for the set
3. Convert to 3D low-poly white model
4. If full handle/grip appears — fix 2D and retry Image to 3D

Confirm you understand.
```

### Kabza eklediğinde

```
Wrong — complete weapon with handle grip.
AQ3D style blade module with integral guard ONLY. Flat tang below guard. Regenerate without grip shaft.
```

```
Modular kit replacement part — not a finished weapon. Edit 2D to crop handle, Image to 3D again.
```

---

## Meshy tam silah üretiyorsa

Meshy “sword / dagger / staff” görünce bitmiş silah tamamlar. `no handle` çoğu zaman yetmez.

1. **2D concept** (orthographic side, blade-only, prompt şablonundaki stil bloğu)
2. **Image to 3D** + kısa metin: `AQ3D style modular part only, no handle, low poly`
3. Son çare: Blender’da grip shaft sil (guard blade’de kalır)

| Kaçın | Kullan |
|-------|--------|
| sword, dagger, wand, staff, bow, weapon | detached blade piece, axe head, crystal cap, bow limb pair, crossbow prod |
| complete, full, realistic, grim dark | modular attachment, incomplete, detached, tang stub |

---

## Meshy → Roblox workflow

1. 2D concept (aşağıdaki prompt) veya Text to 3D
2. Export GLB/FBX → `ReplicatedStorage/WeaponMeshes/<meshKey>`
3. PrimaryPart = Handle, pivot **tang dibinde** (guard’ın altı)
4. Hand-painted texture pass (512²) — chunky fairytale hissi burada
5. Aynı `meshKey` → tek model, varyant siluet farkı meshKey_Rare ile

---

## Dagger — meshKey: `Dagger_Blade` / `Dagger_Blade_Rare`

### `b_dagger_st` — Piercing Shiv (Common · ST)
**meshKey:** `Dagger_Blade`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, short narrow metal thrust blade piece single sharp stab point minimal assassin shiv, plain warm steel-gray minimal detail chunky readable silhouette ST single-target, integral tiny minimal dagger quillon nub at blade base above tang no crossbar assassin shiv included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_dagger_aoe` — Fan Blade (Common · AoE)
**meshKey:** `Dagger_Blade`

**2D concept (Gemini/ChatGPT — önce bunu):**

```
orthographic SIDE view vertical orientation, AQ3D Adventure Quest 3D style low poly chunky cartoon fantasy MMO, hand-painted cel soft warm highlights whimsical fairytale NOT grim NOT realistic,
elongated one-handed DAGGER blade module only, tall vertical blade length about three times width,
widened belly and curved cutting edge for sweep attacks broader than thrust dagger but still clearly a dagger NOT an axe,
looks like wide cleaver-dagger or kukri shiv side profile NOT hatchet head NOT semicircular fan disc NOT circular axe head,
plain warm steel-gray minimal detail, integral small curved quillon guard at blade base above tang,
flat narrow tang plate below guard two rivet holes, NO grip NO handle shaft NO pommel white background isolated game asset
```

**Meshy Text to 3D:**

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view vertical orientation, modular RPG attachment part detached incomplete, NOT a complete weapon, elongated one-handed dagger metal blade piece tall vertical profile length three times width widened belly curved cutting edge for sweeps broader than thrust dagger AoE cleave silhouette, NOT axe head NOT hatchet head NOT semicircular fan disc NOT circular blade, wide cleaver-dagger kukri shiv proportions plain warm steel-gray minimal detail chunky readable silhouette, integral small curved quillon guard at blade base above tang fits cleaver-dagger sweep included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_dagger_st_r` — Assassin's Needle (Rare · ST)
**meshKey:** `Dagger_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, elegant thin needle rapier metal blade piece sharp thrust profile assassin duelist, rare ornate gold-steel filigree hints light engraved accent lines ST precision stab silhouette, integral elegant swept quillon guard delicate duelist needle rapier style included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_dagger_aoe_r` — Whirling Edge (Rare · AoE)
**meshKey:** `Dagger_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view vertical orientation, modular RPG attachment part detached incomplete, NOT a complete weapon, elongated rare dagger metal blade piece tall vertical length three times width serrated multi-edge whirling sweep wider than needle blade AoE spin slash, NOT axe head NOT semicircular fan disc NOT hatchet head, rare ornate gold-steel filigree hints light engraved accent lines, integral swept curved quillons guard whirling spin slash dagger style included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_exotic_hookfang` — Hookfang (Exotic)
**meshKey:** `Dagger_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, exotic Hookfang metal blade piece hooked fang tooth near tip predatory curved silhouette clearly different from standard daggers agile crit-killer, exotic distinct silhouette subtle soft emissive rune grooves not neon, integral hooked fang-shaped quillon guard predatory crit-killer motif included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_exotic_needleswarm` — Needleswarm (Exotic)
**meshKey:** `Dagger_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, exotic Needleswarm metal blade piece cluster of needle spikes fan spread swarm of small points distinct from Hookfang fast striker, exotic distinct silhouette subtle soft emissive rune grooves not neon, integral split needle-prong quillon cluster guard swarm striker motif included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_boss_gaze_shiv` — Gaze Shiv (Boss · The Eye)
**meshKey:** `Dagger_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, boss Gaze Shiv obsidian void-touched metal blade piece eye motif sinister assassin shiv, void purple eye-crack accents sinister arcane boss theme The Eye, integral void-eye shaped sinister quillon guard boss assassin shiv included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

---

## 1H Sword — meshKey: `Sword1H_Blade` / `Sword1H_Blade_Rare`

### `b_sword_st` — Longblade (Common · ST)
**meshKey:** `Sword1H_Blade`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, standard one-handed long metal blade piece straight thrust profile soldier longblade, plain warm steel-gray minimal detail chunky readable silhouette ST measured strike, integral straight soldier crossguard at blade base above tang included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_sword_aoe` — Wide Cleaver (Common · AoE)
**meshKey:** `Sword1H_Blade`

**Oyun adı “Wide Cleaver” — prompt’ta `cleaver` YAZMA** (AI butcher cleaver çizer). Hedef: broadsword / falchion, Longblade ile **aynı uzunluk**.

**2D concept (Gemini/ChatGPT — önce bunu):**

```
orthographic SIDE view horizontal orientation, AQ3D Adventure Quest 3D style low poly chunky cartoon fantasy MMO, hand-painted cel soft warm highlights whimsical fairytale NOT grim NOT realistic,
one-handed SWORD blade module only, arming sword broadsword falchion silhouette,
SAME long blade length as soldier longblade about three to four times width NOT short stubby,
slightly wider belly and broader cutting edge than straight longblade for cone sweep attacks,
tapers to sharp sword point classic sword profile,
NOT cleaver NOT butcher cleaver NOT meat cleaver NOT hatchet NOT axe head NOT rectangular slab NOT width greater than length,
plain warm steel-gray minimal detail chunky readable silhouette AoE slash sweep,
integral straight soldier crossguard at blade base above tang same family as longblade slightly beefier,
flat narrow tang plate below guard two rivet holes, NO grip NO handle shaft NO pommel white background isolated game asset
```

**Meshy Text to 3D / Image to 3D:**

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view horizontal orientation, modular RPG attachment part detached incomplete, NOT a complete weapon, one-handed broadsword falchion metal blade piece same long length as soldier longblade three to four times width slightly wider belly broader cutting edge for cone sweeps than straight longblade, NOT cleaver NOT butcher cleaver NOT meat cleaver NOT hatchet NOT rectangular slab NOT short stubby, plain warm steel-gray minimal detail chunky readable silhouette AoE slash sweep, integral straight soldier crossguard at blade base above tang slightly beefier than longblade included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_sword_st_r` — Court Rapier (Rare · ST)
**meshKey:** `Sword1H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, refined court rapier metal blade piece thin precise thrust duelist profile, rare ornate gold-steel filigree hints light engraved accent lines ST thrust silhouette, integral ornate swept quillons small dish guard court rapier style included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_sword_aoe_r` — Rendblade (Rare · AoE)
**meshKey:** `Sword1H_Blade_Rare`

**Hedef siluet:** geniş slab cleaver + dişli rend kenar + altın filigree — common AoE’den farklı tier.

**2D concept (Gemini/ChatGPT — kilitle):**

```
orthographic SIDE view horizontal orientation, AQ3D Adventure Quest 3D style low poly chunky cartoon fantasy MMO, hand-painted cel soft warm highlights whimsical fairytale NOT grim NOT realistic,
rare Rendblade metal blade module only, wide slab cleaver sword silhouette broad heavy cutting profile,
jagged saw-tooth rend notches along cutting edge multiple teeth aggressive slash,
rare ornate gold filigree scrollwork panel recessed in center of blade face battle-worn scratches,
weathered warm steel-gray chunky readable silhouette AoE rend slash,
integral aggressive notched chunky crossguard rend cleaver style above tang,
flat tang plate below guard two rivet holes, NO grip NO handle shaft NO pommel white background isolated game asset
```

**Meshy Text to 3D / Image to 3D:**

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view horizontal orientation, modular RPG attachment part detached incomplete, NOT a complete weapon, rare Rendblade wide slab cleaver metal blade piece jagged saw-tooth rend notches along cutting edge broad heavy slash profile, rare ornate gold-steel filigree scrollwork panel center of blade battle-worn scratches, chunky readable silhouette AoE rend slash, integral aggressive notched chunky crossguard rend cleaver style included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_exotic_riptusk` — Riptusk (Exotic)
**meshKey:** `Sword1H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, exotic Riptusk metal blade piece wave and tusk motifs along edge water-warrior finisher distinct from court rapier, exotic distinct silhouette subtle soft emissive rune grooves not neon, integral wave-tusk themed crossguard water-warrior finisher included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_boss_iron_skewer` — Iron Skewer (Boss · The Breaker)
**meshKey:** `Sword1H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, boss Iron Skewer heavy thrust metal blade piece brutal skewer point siege steel, rusted seismic fracture accents industrial war boss theme The Breaker, integral rusted brutal industrial crossguard siege skewer boss included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

---

## 1H Axe — meshKey: `Axe1H_Blade` / `Axe1H_Blade_Rare`

**Not:** ST/AoE görsel kodlama yok — 4 blade farklı tasarım, tier okuması yeter.

### `b_axe_st` — Hatchet Head (Common · ST)
**meshKey:** `Axe1H_Blade`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, small one-handed hatchet axe head metal piece sharp wedge chop profile, plain warm steel-gray minimal detail chunky readable silhouette, integral reinforced metal socket collar band at axe eye haft mount included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_axe_aoe` — Timber Axe (Common · AoE)
**meshKey:** `Axe1H_Blade`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, timber lumberjack axe head metal piece broad curved blade distinct from hatchet wedge, plain warm steel-gray minimal detail chunky readable silhouette, integral socket collar band timber axe mount included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_axe_st_r` — Warbreaker Head (Rare · ST)
**meshKey:** `Axe1H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, heavy warbreaker axe head metal piece brutal wedge reinforcement plates, rare ornate gold-steel filigree hints light engraved accent lines, integral reinforced socket collar with rare plate accents included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_axe_aoe_r` — Splinter Axe (Rare · AoE)
**meshKey:** `Axe1H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, splintered wide axe head metal piece chipped brutal edges slab cleaver motif, rare ornate gold-steel filigree hints light engraved accent lines, integral chipped socket collar splinter axe mount included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_exotic_skullcracker` — Skullcracker (Exotic)
**meshKey:** `Axe1H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, exotic Skullcracker hybrid axe-mace head metal piece skull motif guard-breaking mass distinct from warbreaker, exotic distinct silhouette subtle soft emissive rune grooves not neon brutal warrior, integral skull-plate socket collar brutal hybrid axe-mace mount included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

---

## 1H Mace — meshKey: `Mace1H_Blade` / `Mace1H_Blade_Rare`

**Not:** ST/AoE görsel kodlama yok — farklı head tasarımları + tier yeter.

### `b_mace_st` — Flanged Head (Common · ST)
**meshKey:** `Mace1H_Blade`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, flanged one-handed mace head metal piece compact tank breaker simple steel flanges, plain warm steel-gray minimal detail chunky readable silhouette, integral reinforced socket flange collar at haft mount included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_mace_aoe` — Sweep Mace (Common · AoE)
**meshKey:** `Mace1H_Blade`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, crescent disc sweep mace head metal piece round arc profile distinct from flanged head, plain warm steel-gray minimal detail chunky readable silhouette, integral socket flange collar sweep mace mount included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_mace_st_r` — Skullcrusher Head (Rare · ST)
**meshKey:** `Mace1H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, heavy skullcrusher flanged mace head metal piece spikes reinforced steel devastating crush motif, rare ornate gold-steel filigree hints light engraved accent lines, integral spiked reinforced socket collar included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_mace_aoe_r` — Shock Maul (Rare · AoE)
**meshKey:** `Mace1H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, shock maul head metal piece ridged shock lines subtle energy crack grooves, rare ornate gold-steel filigree hints light engraved accent lines, integral shock-ridge socket flange collar included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_exotic_bulwark_maul` — Bulwark Maul (Exotic)
**meshKey:** `Mace_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, exotic Bulwark Maul head metal piece fortress plate segments wall-like bulk tank fortify aesthetic distinct from shock maul, exotic distinct silhouette subtle soft emissive rune grooves not neon heavy defensive, integral fortress-plate socket flange collar tank bulwark mount included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

---

## Wand — meshKey: `Wand_Blade` / `Wand_Blade_Rare`

**Not:** ST/AoE görsel kodlama yok — her cap farklı şekil; tier = sade → ornate → exotic tema.

### `b_wand_st` — Crystal Wand (Common · ST)
**meshKey:** `Wand_Blade`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, wand crystal cap ornament only NO wand stick NO shaft, small single faceted crystal orb cap simple arcane gem focus tip, plain warm steel-gray minimal detail chunky readable silhouette, integral small arcane metal socket ring collar holding crystal cap included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

### `b_wand_aoe` — Arc Wand (Common · AoE)
**meshKey:** `Wand_Blade`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, wand crystal cap ornament only NO wand stick NO shaft, forked twin-prong crystal cap angular arcane gem shape distinct from single orb wand, plain warm steel-gray minimal detail chunky readable silhouette, integral forked twin-prong arcane socket ring collar included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

### `b_wand_st_r` — Archon Spindle (Rare · ST)
**meshKey:** `Wand_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, wand crystal cap ornament only NO wand stick NO shaft, elegant archon spindle crystal cap ornate potency rings refined mage focus, rare ornate gold-steel filigree hints light engraved accent lines, integral ornate archon socket ring collar with potency ring accents included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

### `b_wand_aoe_r` — Nova Wand (Rare · AoE)
**meshKey:** `Wand_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, wand crystal cap ornament only NO wand stick NO shaft, nova starburst crystal cluster cap radiant arcane burst motif ornate mage head, rare ornate gold-steel filigree hints light engraved accent lines, integral nova starburst socket ring collar included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

### `b_exotic_stormlash` — Stormlash (Exotic)
**meshKey:** `Wand_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, wand crystal cap ornament only NO wand stick NO shaft, exotic Stormlash twin-prong lightning crystal fork storm mage motif distinct from nova wand, exotic distinct silhouette subtle soft emissive rune grooves not neon, integral twin-prong lightning socket fork collar included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

### `b_exotic_arcane_lance` — Arcane Lance (Exotic)
**meshKey:** `Wand_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, wand crystal cap ornament only NO wand stick NO shaft, exotic Arcane Lance long piercing crystal spike cap lance-like arcane guard-piercing mage motif, exotic distinct silhouette subtle soft emissive rune grooves not neon, integral elongated lance socket ring collar included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

---

## Scepter — meshKey: `Scepter_Blade` / `Scepter_Blade_Rare`

**Not:** ST/AoE görsel kodlama yok — crook/cap varyantları + tier yeter.

### `b_scepter_st` — Focus Scepter (Common · ST)
**meshKey:** `Scepter_Blade`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, scepter crook cap ornament only NO staff pole NO shaft, simple gentle cleric crook curve self-heal support motif plain steel look, plain warm steel-gray minimal detail chunky readable silhouette, integral simple cleric socket collar crook mount included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

### `b_scepter_aoe` — Radiant Crook (Common · AoE)
**meshKey:** `Scepter_Blade`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, scepter crook cap ornament only NO staff pole NO shaft, radiant sun crook cap soft holy blessing motif gentle curved branches distinct from focus crook, plain warm steel-gray minimal detail chunky readable silhouette, integral radiant blessing socket collar included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

### `b_scepter_st_r` — High Scepter (Rare · ST)
**meshKey:** `Scepter_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, scepter crook cap ornament only NO staff pole NO shaft, ornate high priest crook cap fortify aura holy support regal curves, rare ornate gold-steel filigree hints light engraved accent lines, integral ornate high-priest gold socket collar included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

### `b_scepter_aoe_r` — Haze Scepter (Rare · AoE)
**meshKey:** `Scepter_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, scepter crook cap ornament only NO staff pole NO shaft, haze mist crook cap smoky branch curves arcane support motif soft cloudy accents, rare ornate gold-steel filigree hints light engraved accent lines, integral haze mist socket collar spread-branch crook mount included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

### `b_exotic_sanctum` — Sanctum Scepter (Exotic)
**meshKey:** `Scepter_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, scepter crook cap ornament only NO staff pole NO shaft, exotic Sanctum Scepter relic crook sanctuary shield motif holy fortress support renew fortify fantasy, exotic distinct silhouette subtle soft emissive rune grooves not neon, integral sanctuary shield socket collar relic fortress crook mount included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

---

## 2H Sword — meshKey: `Sword2H_Blade` / `Sword2H_Blade_Rare`

### `b_greatblade_st` — Iron Greatblade (Common · ST)
**meshKey:** `Sword2H_Blade`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, large two-handed greatblade metal piece heavy straight thrust profile iron soldier steel, plain warm steel-gray minimal detail chunky readable silhouette ST measured strike, integral large two-handed straight crossguard soldier greatblade base included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_greatblade_aoe` — Tempest Blade (Common · AoE)
**meshKey:** `Sword2H_Blade`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, wide tempest greatblade metal piece sweeping cleaves broader edge than iron greatblade storm-sweep silhouette, plain warm steel-gray minimal detail chunky readable silhouette AoE sweep, integral wide storm-swept great crossguard tempest cleave base included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_greatblade_st_r` — Tyrant Blade (Rare · ST)
**meshKey:** `Sword2H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, tyrant greatblade metal piece regal sharp profile rare ornate edge duelist-killer ST silhouette, rare ornate gold-steel filigree hints light engraved accent lines, integral regal ornate great crossguard tyrant duelist-killer base included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_greatblade_aoe_r` — Earthshaker Blade (Rare · AoE)
**meshKey:** `Sword2H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, earthshaker greatblade metal piece quake chips wide slam-ready edge ground impact AoE silhouette, rare ornate gold-steel filigree hints light engraved accent lines, integral quake-chipped wide great crossguard earthshaker slam base included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_exotic_skyreaver` — Skyreaver (Exotic)
**meshKey:** `Sword2H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, exotic Skyreaver greatblade metal piece sky wind etchings heroic knight silhouette distinct from tyrant blade, exotic distinct silhouette subtle soft emissive rune grooves not neon hyper-armor fantasy, integral winged heroic great crossguard sky wind knight base included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_boss_rust_greatblade` — Rust Greatblade (Boss · The Breaker)
**meshKey:** `Sword2H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, boss Rust Greatblade heavy greatblade metal piece rusted seismic cracks brutal breaker war theme, rusted seismic fracture accents industrial war boss theme The Breaker, integral rusted seismic brutal great crossguard breaker boss base included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

---

## 2H Axe — meshKey: `Axe2H_Blade` / `Axe2H_Blade_Rare`

**Not:** ST/AoE görsel kodlama yok — farklı axe head + tier yeter.

### `b_greataxe_st` — Greataxe Head (Common · ST)
**meshKey:** `Axe2H_Blade`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, massive two-handed greataxe head metal piece classic heavy wedge war steel, plain warm steel-gray minimal detail chunky readable silhouette, integral heavy greataxe socket collar band haft mount included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_greataxe_aoe` — Cleaving Axe (Common · AoE)
**meshKey:** `Axe2H_Blade`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, cleaving greataxe head metal piece double-bit notched blade profile distinct from classic greataxe wedge, plain warm steel-gray minimal detail chunky readable silhouette, integral cleaving greataxe socket collar band included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_greataxe_st_r` — Soulreaver Head (Rare · ST)
**meshKey:** `Axe2H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, soulreaver heavy greataxe head metal piece dark rare steel soul-hunter edge brutal chop motif, rare ornate gold-steel filigree hints light engraved accent lines, integral dark soul-hunter reinforced socket collar included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_greataxe_aoe_r` — Faultline Axe (Rare · AoE)
**meshKey:** `Axe2H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, faultline greataxe head metal piece split ground-crack motif seismic fracture accents, rare ornate gold-steel filigree hints light engraved accent lines, integral faultline cracked socket collar included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_boss_rust_cleaver` — Rust Cleaver (Boss · The Breaker)
**meshKey:** `Axe2H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, boss Rust Cleaver massive greataxe head metal piece rust corruption seismic damage brutal cleaver motif, rusted seismic fracture accents industrial war boss theme The Breaker, integral massive rust corrosion socket collar included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

---

## 2H Mace — meshKey: `Mace2H_Blade` / `Mace2H_Blade_Rare`

**Not:** ST/AoE görsel kodlama yok (1H mace ile aynı politika).

### `b_greathammer_st` — War Hammer Head (Common · ST)
**meshKey:** `Mace2H_Blade`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, square two-handed war hammer head metal piece blocky smash profile simple steel, plain warm steel-gray minimal detail chunky readable silhouette, integral square war hammer socket flange collar haft mount included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_greathammer_aoe` — Quake Hammer (Common · AoE)
**meshKey:** `Mace2H_Blade`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, quake disc hammer head metal piece ring grooves shock-wave motif distinct from square war hammer, plain warm steel-gray minimal detail chunky readable silhouette, integral quake-disc socket flange collar included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_greathammer_st_r` — Thronebreaker Head (Rare · ST)
**meshKey:** `Mace2H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, thronebreaker spiked hammer head metal piece reinforced fortress plates crushing motif, rare ornate gold-steel filigree hints light engraved accent lines, integral thronebreaker spiked socket collar included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_greathammer_aoe_r` — Cataclysm Maul (Rare · AoE)
**meshKey:** `Mace2H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, cataclysm disaster maul head metal piece layered impact plates chaotic disaster motif, rare ornate gold-steel filigree hints light engraved accent lines, integral cataclysm layered socket flange collar included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_boss_seismic_maul` — Seismic Maul (Boss · The Breaker)
**meshKey:** `Mace2H_Blade_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete weapon, boss Seismic Maul maul head metal piece rust iron shock fracture lines earthquake tank weapon motif, rusted seismic fracture accents industrial war boss theme The Breaker, integral rust shock-fracture socket flange collar included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

---

## Staff head — meshKey: `Staff_Head` / `Staff_Head_Rare`

**Not:** ST/AoE görsel kodlama yok — head motif çeşitliliği + tier yeter.

### `b_staff_st` — Crystal Head (Common · ST)
**meshKey:** `Staff_Head`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, staff top crystal ornament only NO wooden pole NO shaft, large single crystal orb cap empowered arcane gem focus, plain warm steel-gray minimal detail chunky readable silhouette, integral simple arcane socket collar ring holding crystal orb included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

### `b_staff_aoe` — Storm Head (Common · AoE)
**meshKey:** `Staff_Head`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, staff top crystal ornament only NO wooden pole NO shaft, storm cloud crystal cluster cap lightning storm magic motif distinct from single orb head, plain warm steel-gray minimal detail chunky readable silhouette, integral storm cluster socket collar included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

### `b_staff_st_r` — Voidheart Head (Rare · ST)
**meshKey:** `Staff_Head_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, staff top crystal ornament only NO wooden pole NO shaft, voidheart dark crystal core cap rare potency mage accents deep void gem, rare ornate gold-steel filigree hints light engraved accent lines, integral voidheart dark socket collar ring included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

### `b_staff_aoe_r` — Cataclysm Head (Rare · AoE)
**meshKey:** `Staff_Head_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, staff top crystal ornament only NO wooden pole NO shaft, cataclysm multi-crystal burst head chaotic arcane disaster motif ornate mage cap, rare ornate gold-steel filigree hints light engraved accent lines, integral cataclysm multi-crystal socket collar included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

### `b_exotic_null_staff` — Null Staff (Exotic)
**meshKey:** `Staff_Head_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, staff top crystal ornament only NO wooden pole NO shaft, exotic Null Staff void sphere head null-magic hollow core distinct from voidheart dark gem, exotic distinct silhouette subtle soft emissive rune grooves not neon, integral void sphere hollow socket collar included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

### `b_boss_void_staff` — Void Gaze Staff (Boss · The Eye)
**meshKey:** `Staff_Head_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, staff top crystal ornament only NO wooden pole NO shaft, boss Void Gaze Staff head void eye crystal tentacle hints gaze motif sinister arcane boss cap, void purple eye-crack accents sinister arcane boss theme The Eye, integral void eye sinister socket collar included as part of cap module, flat socket stub below collar with two rivet holes, NO grip NO handle shaft NO pole NO stick NO stock, single isolated part white background game-ready
```

---

## Bow limbs — meshKey: `Bow_Limbs` / `Bow_Limbs_Rare`

**Not:** ST/AoE görsel kodlama yok — limb çifti form çeşitliliği + tier yeter.

### `b_bow_st` — Hunter Limbs (Common · ST)
**meshKey:** `Bow_Limbs`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, bow limb pair module only open center NO grip NO string, simple hunter bow limbs practical ranger clean Y-curve limbs, plain warm steel-gray minimal detail chunky readable silhouette, integral center limb socket bridge pads at open grip gap included as part of limb module, NOT complete bow NO grip riser NO string NO hand, open center gap flat socket bridge mount, single isolated part white background game-ready
```

### `b_bow_aoe` — Scatter Limbs (Common · AoE)
**meshKey:** `Bow_Limbs`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, bow limb pair module only open center NO grip NO string, scatter limbs decorative multi-notch limb profile angular branches distinct from hunter Y-curve, plain warm steel-gray minimal detail chunky readable silhouette, integral scatter-limb socket bridge at center gap included as part of limb module, NOT complete bow NO grip riser NO string NO hand, open center gap flat socket bridge mount, single isolated part white background game-ready
```

### `b_bow_st_r` — Windcaller Limbs (Rare · ST)
**meshKey:** `Bow_Limbs_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, bow limb pair module only open center NO grip NO string, sleek windcaller rare limbs crit ranger focused shot subtle wind groove accents, rare ornate gold-steel filigree hints light engraved accent lines, integral sleek windcaller socket bridge wind groove limb mount included as part of limb module, NOT complete bow NO grip riser NO string NO hand, open center gap flat socket bridge mount, single isolated part white background game-ready
```

### `b_bow_aoe_r` — Gale Limbs (Rare · AoE)
**meshKey:** `Bow_Limbs_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, bow limb pair module only open center NO grip NO string, gale storm limbs spread branch curves storm archer motif ornate limb pair, rare ornate gold-steel filigree hints light engraved accent lines, integral gale storm socket bridge included as part of limb module, NOT complete bow NO grip riser NO string NO hand, open center gap flat socket bridge mount, single isolated part white background game-ready
```

### `b_exotic_windstring` — Windstring (Exotic)
**meshKey:** `Bow_Limbs_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, bow limb pair module only open center NO grip NO string, exotic Windstring elegant limbs pierce-through wind string path distinct gale exotic precision ranger fantasy, exotic distinct silhouette subtle soft emissive rune grooves not neon, integral elegant pierce wind socket bridge included as part of limb module, NOT complete bow NO grip riser NO string NO hand, open center gap flat socket bridge mount, single isolated part white background game-ready
```

### `b_boss_gale_limbs` — Gale Limbs (Boss · The Eye)
**meshKey:** `Bow_Limbs_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, bow limb pair module only open center NO grip NO string, boss Gale Limbs wind void storm limbs eye boss motif accents powerful ranged boss limb pair, void purple eye-crack accents sinister arcane boss theme The Eye, integral void storm eye socket bridge included as part of limb module, NOT complete bow NO grip riser NO string NO hand, open center gap flat socket bridge mount, single isolated part white background game-ready
```

---

## Crossbow head — meshKey: `Crossbow_Head` / `Crossbow_Head_Rare`

**Not:** ST/AoE görsel kodlama yok — prod mekanizma çeşitliliği + tier yeter.

### `b_crossbow_st` — Arbalest Head (Common · ST)
**meshKey:** `Crossbow_Head`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete crossbow, crossbow prod mechanism front assembly only NO stock NO handle, arbalest prod and bolt mechanism heavy siege steel simple steel, plain warm steel-gray minimal detail chunky readable silhouette, integral stock mounting bracket socket at prod base included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_crossbow_aoe` — Shard Head (Common · AoE)
**meshKey:** `Crossbow_Head`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete crossbow, crossbow prod mechanism front assembly only NO stock NO handle, shard scatter crossbow head multi-bolt rack spread prod motif distinct from arbalest, plain warm steel-gray minimal detail chunky readable silhouette, integral spread-bolt mounting bracket shard prod base included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_crossbow_st_r` — Siege Head (Rare · ST)
**meshKey:** `Crossbow_Head_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete crossbow, crossbow prod mechanism front assembly only NO stock NO handle, siege arbalest head reinforced prod crit siege steel plate accents, rare ornate gold-steel filigree hints light engraved accent lines, integral reinforced siege mounting bracket crit arbalest prod plates included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_crossbow_aoe_r` — Bombard Head (Rare · AoE)
**meshKey:** `Crossbow_Head_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete crossbow, crossbow prod mechanism front assembly only NO stock NO handle, bombard multi-bolt rack head volley prod motif ornate siege mechanism, rare ornate gold-steel filigree hints light engraved accent lines, integral bombard multi-rack mounting bracket included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_exotic_iron_bolt` — Iron Bolt (Exotic)
**meshKey:** `Crossbow_Head_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete crossbow, crossbow prod mechanism front assembly only NO stock NO handle, exotic Iron Bolt industrial bolt rack reload mechanism hints distinct siege exotic prod, exotic distinct silhouette subtle soft emissive rune grooves not neon, integral industrial reload mounting bracket iron bolt rack prod included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

### `b_boss_ocular_bolt` — Ocular Bolt Head (Boss · The Eye)
**meshKey:** `Crossbow_Head_Rare`

```
AQ3D Adventure Quest 3D style, low poly chunky cartoon fantasy MMO game asset, hand-painted cel look soft warm highlights, whimsical fairytale mood NOT grim dark NOT realistic NOT concept art painterly, orthographic side view, modular RPG attachment part detached incomplete, NOT a complete crossbow, crossbow prod mechanism front assembly only NO stock NO handle, boss Ocular Bolt head eye-scope sight void steel prod piercing line shot boss motif, void purple eye-crack accents sinister arcane boss theme The Eye, integral void eye-scope mounting bracket ocular prod boss base included as part of blade module, flat tang plate below guard with two rivet holes, NO grip NO handle shaft NO pommel NO stock, single isolated part white background game-ready
```

---

## meshKey özet (batch modelleme)

| meshKey | Item sayısı |
|---------|-------------|
| `Dagger_Blade` | 2 |
| `Dagger_Blade_Rare` | 5 |
| `Sword1H_Blade` | 2 |
| `Sword1H_Blade_Rare` | 4 |
| `Axe1H_Blade` | 2 |
| `Axe1H_Blade_Rare` | 3 |
| `Mace1H_Blade` | 2 |
| `Mace1H_Blade_Rare` | 2 |
| `Mace_Blade_Rare` | 1 (Bulwark Maul exotic) |
| `Wand_Blade` | 2 |
| `Wand_Blade_Rare` | 4 |
| `Scepter_Blade` | 2 |
| `Scepter_Blade_Rare` | 3 |
| `Sword2H_Blade` | 2 |
| `Sword2H_Blade_Rare` | 4 |
| `Axe2H_Blade` | 2 |
| `Axe2H_Blade_Rare` | 4 |
| `Mace2H_Blade` | 2 |
| `Mace2H_Blade_Rare` | 2 |
| `Staff_Head` | 2 |
| `Staff_Head_Rare` | 3 |
| `Staff2H_Blade_Rare` | 1 (boss void staff) |
| `Bow_Limbs` | 2 |
| `Bow_Limbs_Rare` | 4 |
| `Crossbow_Head` | 2 |
| `Crossbow_Head_Rare` | 4 |

**Toplam blade item:** 68

---

*Kaynak: `BladeDefs.luau`, `ExoticContent.luau`, `BossContent.luau` · Meshy AI · Son güncelleme: 2026-07*
