--[[
	Runtime rules for Exotic items — keyed by catalog def id.
	Tooltip `familyPerk` strings should match these behaviors.
]]

local ExoticPerkDefs = {}

export type BladePerk = {
	laProcChance: number?, -- LA L1/L2 gem status roll (no passive required)
	potencyBonusFlat: number?,
	slamFortifySec: number?, -- after slam_r_weaponactive hits
	renewFortifySec: number?, -- after renew_weaponactive
	coneGuardBreak: boolean?, -- cone_weaponactive forces guard break
	pierceIgnoresGuard: boolean?, -- pierce_bolt_weaponactive
	laL3ExtraTargets: number?, -- bow L3 pierce extra
	laL3HyperArmorBonusSec: number?,
	statusDoubleOnCrit: boolean?, -- weapon actives with status
	burstRefreshesPierce: boolean?, -- crossbow burst_weaponactive
}

export type ArmorPerk = {
	lifewaveOverhealHot: boolean?,
	chargerRootOnHit: boolean?,
	dodgePhantomTrailSec: number?,
}

export type FocusPerk = {
	smokeGrappleCdReset: boolean?,
}

local BLADE: { [string]: BladePerk } = {
	b_exotic_hookfang = {}, -- backstab via Dagger family + abilities
	b_exotic_stormlash = { potencyBonusFlat = 6 },
	b_exotic_bulwark_maul = { slamFortifySec = 2.5 },
	b_exotic_riptusk = {}, -- L3 status is global LA rule
	b_exotic_needleswarm = { laProcChance = 0.15 },
	b_exotic_arcane_lance = { pierceIgnoresGuard = true },
	b_exotic_sanctum = { renewFortifySec = 2 },
	b_exotic_skullcracker = { coneGuardBreak = true },
	b_exotic_skyreaver = { laL3HyperArmorBonusSec = 0.35 },
	b_exotic_null_staff = { statusDoubleOnCrit = true },
	b_exotic_windstring = { laL3ExtraTargets = 1 },
	b_exotic_iron_bolt = { burstRefreshesPierce = true },
}

local ARMOR: { [string]: ArmorPerk } = {
	a_exotic_mirrorplate = {}, -- thorn + carapace passives
	a_exotic_voidgrasp = {}, -- touch + stormgrasp
	a_exotic_phantom_hood = { dodgePhantomTrailSec = 0.45 },
	a_exotic_lifeweaver_crown = { lifewaveOverhealHot = true },
	a_exotic_quakehold_boots = { chargerRootOnHit = true },
	a_exotic_warden_plate = {}, -- bulwark + fortify aura passives
}

local FOCUS: { [string]: FocusPerk } = {
	o_exotic_shadow_kit = { smokeGrappleCdReset = true },
	o_exotic_war_totem = {}, -- war sigil passive
}

function ExoticPerkDefs.GetBladePerk(bladeDefId: string?): BladePerk?
	if not bladeDefId then
		return nil
	end
	return BLADE[bladeDefId]
end

function ExoticPerkDefs.GetArmorPerk(armorDefId: string?): ArmorPerk?
	if not armorDefId then
		return nil
	end
	return ARMOR[armorDefId]
end

function ExoticPerkDefs.GetFocusPerk(focusDefId: string?): FocusPerk?
	if not focusDefId then
		return nil
	end
	return FOCUS[focusDefId]
end

function ExoticPerkDefs.IsExoticDefId(defId: string?): boolean
	if not defId then
		return false
	end
	return BLADE[defId] ~= nil or ARMOR[defId] ~= nil or FOCUS[defId] ~= nil
end

return ExoticPerkDefs
