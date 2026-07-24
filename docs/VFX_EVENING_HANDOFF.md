# VFX Pack — Akşam Handoff

Bu dosya akşam VFX çalışması için hazırlanmıştır. Chat’e bu dosyayı veya özetini yapıştırman yeterli; baştan anlatmana gerek yok.

## Amaç

Marketplace’ten alınan VFX paketindeki şablonları `ReplicatedStorage` altına koyup, oyundaki **combat yetenekleri** ve **boss mekanikleri** ile eşlemek. Kod tarafı `VfxAssets` + `VfxConfig` + `CombatVfx` / `BossVfx` üzerinden klonlar ve renk/ölçek ayarlar.

## Studio klasör yapısı (zorunlu isimler)

```
ReplicatedStorage/
  CombatVfxAssets/          ← VfxConfig.AssetRootName
    Particles/
      SparkBurst            ← ParticleEmitter şablonu
      SmokePuff
      HealMotes
      BeamStreak            ← (opsiyonel, boss beam)
    Meshes/
      SlashImpact           ← MeshPart veya Model
      BoltStreak
      ReactionBurst
      GroundCrack           ← (önerilen, Cataclysm slam)
      DustRing              ← (önerilen, slam / charge)
    Reactions/
      Vaporize              ← Model (element reaksiyonları)
      ChainShock
      ...
    Boss/                   ← YENİ — boss telegraph / hit (akşam doldur)
      IrisFocus
      AggroStrike
      RustMark
      ShoulderCharge
      CataclysmSlam
      BeamLine
      MonolithDrop
```

**Kural:** Marketplace’ten kopyaladığın instance’ların **Roblox Explorer’daki adı** yukarıdaki path ile birebir eşleşmeli. Kod `FindFirstChild` ile arar; yoksa procedural fallback (basit Part/Particle) kullanılır.

## Marketplace paketinden ne seçmeli?

| Kullanım | Pack’ten tipik asset | Hedef path |
|----------|----------------------|------------|
| LA / slash hit | Impact flash, slash arc | `Meshes/SlashImpact` |
| Projectile / bolt | Streak, projectile trail | `Meshes/BoltStreak` |
| Heal / buff | Soft motes, upward particles | `Particles/HealMotes` |
| Smoke / dodge | Smoke puff | `Particles/SmokePuff` |
| Boss focus (Iris / Aggro strike) | Tight burst, eye glow | `Boss/IrisFocus` veya `Boss/AggroStrike` |
| Rust Mark | Rust pool, orange drip | `Boss/RustMark` |
| Shoulder Charge | Dust trail, speed lines | `Boss/ShoulderCharge` |
| Cataclysm Slam | Ground crack + shockwave ring | `Boss/CataclysmSlam` veya `Meshes/GroundCrack` + `Meshes/DustRing` |
| Eye beam | Laser / line beam | `Boss/BeamLine` |
| Monolith | Rock fall dust | `Boss/MonolithDrop` |

Paketteki isimler farklıysa **Explorer’da yeniden adlandır** — kod path’e bakar, pack iç adına değil.

## Element renklendirme

Kod otomatik tint uygular:

- Kaynak: `AnimConfig.ElementColor` (Fire, Water, Steel, …)
- `CombatVfx` clone sonrası `ParticleEmitter.Color`, `Light.Color`, mesh `Color3` lerp

Boss **Neutral / Steel** için `Steel` veya `Neutral` paleti kullanılır; pack beyaz/neutral texture ise iyi sonuç verir.

## Boss telegraph → kod eşlemesi

| Server `BossSync` kind | Client dosya | Akşam asset |
|------------------------|--------------|-------------|
| `IrisPulse` | `BossVfx.client.luau` | `Boss/IrisFocus` |
| `AggroStrike` | aynı | `Boss/AggroStrike` |
| `RustMark` | aynı | `Boss/RustMark` |
| `ShoulderCharge` | aynı | `Boss/ShoulderCharge` |
| `CataclysmSlam` | aynı | `Boss/CataclysmSlam` |
| `Beam` | aynı | `Boss/BeamLine` |
| `MonolithTelegraph` | aynı | `Boss/MonolithDrop` |

Akşam asset’leri koyduktan sonra chat’te yaz: **“VFX handoff — klasör hazır”** + varsa pack adı. Agent `BossVfx` / `VfxConfig` hook’larını bağlar.

## Combat yetenek hook’ları (mevcut)

`VfxConfig.AssetHooks` (değiştirme gerekirse agent yapar):

| Hook key | Path |
|----------|------|
| `SlashImpact` | `Meshes/SlashImpact` |
| `BoltStreak` | `Meshes/BoltStreak` |
| `ReactionBurst` | `Meshes/ReactionBurst` |
| `ParticleSpark` | `Particles/SparkBurst` |
| `ParticleSmoke` | `Particles/SmokePuff` |
| `ParticleHeal` | `Particles/HealMotes` |

## ParticleEmitter şablon kuralları

1. Şablon `ParticleEmitter` olarak klasörde dursun (Model içindeyse en dış emitter’ı kopyala veya tek emitter bırak).
2. İsteğe bağlı attribute: `EmitCount` (number) — tek seferde kaç particle.
3. Kod clone’da `Rate = 0`, `:Emit(n)` kullanır.

## Test checklist (akşam sonu)

- [ ] `CombatVfxAssets` Studio’da görünüyor
- [ ] LA vurunca `SlashImpact` spawn (yoksa procedural halka)
- [ ] Eye boss: beam + iris telegraph
- [ ] Breaker boss: charge çizgisi + cataclysm daire
- [ ] Performans: her emit `Debris` ile temizleniyor (kodda var)

## Bilinen sınırlar

- Marketplace asset’lerini **kod içinden düzenleyemeyiz**; Studio’da kopyala → `CombatVfxAssets` altına yapıştır.
- Çok ağır pack’lerde rate/emit sayısını `VfxConfig` tuning ile düşürürüz.
- Boss model animasyonları bu dosyanın kapsamı dışında (`CombatAnimDefs` / Mixamo ayrı akış).

## Hızlı komutlar (playtest)

```lua
-- Eye
_G.StartBossEncounter("eye", { game.Players.LocalPlayer.UserId }, 1)

-- Breaker
_G.StartBossEncounter("breaker", { game.Players.LocalPlayer.UserId }, 1)
```

F8 Dev panel: **Start Eye Boss** / **Start Breaker**

---

*Son kod durumu: The Breaker implement edildi (placeholder part model). VFX hâlâ procedural Part fallback — pack sonrası hook bağlanacak.*
