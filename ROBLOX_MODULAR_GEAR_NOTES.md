# Roblox Modular Gear Notes

Moduler ekipman tasarim kilidi.

## Ability ID convention

| Suffix | Catalog | Ornek |
|--------|---------|-------|
| `*_weaponpassive` | `PassiveDefs.luau` | `keen_weaponpassive` |
| `*_weaponactive` | `WeaponActiveDefs.luau` | `strike_weaponactive` |
| `*_armorpassive` | `ArmorAbilityDefs.luau` | (TBD) |
| `*_armoractive` | `ArmorAbilityDefs.luau` | (TBD) |

- **Catalog id** = mekanik (`strike_weaponactive`)
- **Item `name`** = flavor ("Measured Thrust")
- Combat params: `AbilityRuntime.luau` (weapon actives); armor runtime TBD

Blade atama:
```lua
abilities = {
  "strike_r_weaponactive",
  "keen_weaponpassive",
}
```

Generic gem-element actives: `strike_weaponactive`, `bolt_weaponactive`, `cone_weaponactive`, `dash_weaponactive`, `burst_weaponactive`, `*_r_weaponactive` tier.

## Global Weapon Passives (v1)

| ID | Etki |
|----|------|
| `status_weaponpassive` | LA L1/L2: %15 gem status, L3 garantili |
| `keen_weaponpassive` | Crit +5% |
| `potency_weaponpassive` | Status Potency +12 |
| `direct_weaponpassive` | Direct damage x1.03 |

## Rarity - blade

| Rarity | 1H | 2H |
|--------|----|----|
| Common | 1A veya 1P | 2A / 2P / 1A+1P |
| Rare | 1A+1P | 2A+1P veya 1A+2P |

## Katalog durumu

- **BladeDefs**: 48 blade (12 aile x ST/AOE x Common/Rare)
- **ArmorMatrix**: bos (yeniden tasarlanacak)

### Blade matrisi (48)

| Aile | Handle | Parca adi | ST Common | AOE Common | ST Rare | AOE Rare |
|------|--------|-----------|-----------|------------|---------|----------|
| Dagger | 1H_Sword | Blade | `b_dagger_st` | `b_dagger_aoe` | `b_dagger_st_r` | `b_dagger_aoe_r` |
| Sword | 1H_Sword | Blade | `b_sword_st` | `b_sword_aoe` | `b_sword_st_r` | `b_sword_aoe_r` |
| Axe | 1H_AxeMace | Blade | `b_axe_st` | `b_axe_aoe` | `b_axe_st_r` | `b_axe_aoe_r` |
| Mace | 1H_AxeMace | Blade | `b_mace_st` | `b_mace_aoe` | `b_mace_st_r` | `b_mace_aoe_r` |
| Wand | 1H_WandScepter | Blade | `b_wand_st` | `b_wand_aoe` | `b_wand_st_r` | `b_wand_aoe_r` |
| Scepter | 1H_WandScepter | Blade | `b_scepter_st` | `b_scepter_aoe` | `b_scepter_st_r` | `b_scepter_aoe_r` |
| Greatblade | 2H_Sword | Blade | `b_greatblade_st` | `b_greatblade_aoe` | `b_greatblade_st_r` | `b_greatblade_aoe_r` |
| Greataxe | 2H_AxeMace | Blade | `b_greataxe_st` | `b_greataxe_aoe` | `b_greataxe_st_r` | `b_greataxe_aoe_r` |
| Greathammer | 2H_AxeMace | Blade | `b_greathammer_st` | `b_greathammer_aoe` | `b_greathammer_st_r` | `b_greathammer_aoe_r` |
| Staff | 2H_Staff | Head | `b_staff_st` | `b_staff_aoe` | `b_staff_st_r` | `b_staff_aoe_r` |
| Bow | 2H_Bow | Limbs | `b_bow_st` | `b_bow_aoe` | `b_bow_st_r` | `b_bow_aoe_r` |
| Crossbow | 2H_Crossbow | Head | `b_crossbow_st` | `b_crossbow_aoe` | `b_crossbow_st_r` | `b_crossbow_aoe_r` |

Yetenek formu:
- **ST**: melee `strike`/`dash`, ranged `bolt` · rare: `*_r` tier
- **AOE**: `cone` · rare 2H: `cone_r` + `slam_r` (2A+1P)
- **1H Rare**: 1A + 1P · **2H Rare**: 2A+1P veya 1A+2P

Kod: `PassiveDefs.luau`, `WeaponActiveDefs.luau`, `ArmorAbilityDefs.luau`, `BladeDefs.luau`, `AbilityRuntime.luau`
