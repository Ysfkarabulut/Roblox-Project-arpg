--[[
	Local hit-stop on L3 connect — brief anim freeze + camera punch.
]]

local Players = game:GetService("Players")

local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local VfxConfig = require(game.ReplicatedStorage.Shared.Config.VfxConfig)
local CombatAnim = require(script.Parent.CombatAnim)
local CombatVfx = require(script.Parent.CombatVfx)

local CombatHitStop = {}

local function pickHit(hits: any): any?
	if typeof(hits) ~= "table" then
		return nil
	end
	local best: any = nil
	for _, h in hits do
		if typeof(h) ~= "table" then
			continue
		end
		local dealt = (h.dealt or 0) + (if h.blocked then h.chip or 0 else 0)
		if dealt <= 0 then
			continue
		end
		if not best or dealt > ((best.dealt or 0) + (if best.blocked then best.chip or 0 else 0)) then
			best = h
		end
	end
	return best
end

function CombatHitStop.ResolveDuration(fx: any, hit: any?): number
	local step = math.clamp(fx.comboStep or 1, 1, 3)
	local base = CombatConfig.ComboHitStopSec[step] or 0
	if base <= 0 then
		return 0
	end
	local famMult = 1
	if typeof(fx.family) == "string" and CombatConfig.ComboHitStopFamilyMult[fx.family] then
		famMult = CombatConfig.ComboHitStopFamilyMult[fx.family]
	end
	local critBonus = if hit and hit.crit then (CombatConfig.ComboHitStopCritBonus or 0) else 0
	return math.clamp((base + critBonus) * famMult, 0.02, 0.11)
end

function CombatHitStop.CameraIntensity(fx: any, hit: any?): number
	local ctx = VfxConfig.BuildContext(fx)
	local kick = ctx.stepScale.cameraKick or 0
	if hit and hit.crit then
		kick *= 1.35
	end
	if hit and hit.blocked then
		kick *= 0.65
	end
	return kick
end

--- L3 (or configured step) connect — returns true if hit-stop applied
function CombatHitStop.TryOnFx(userId: number, fx: any, hits: any): boolean
	if userId ~= Players.LocalPlayer.UserId then
		return false
	end
	if typeof(fx) ~= "table" then
		return false
	end
	local step = math.clamp(fx.comboStep or 1, 1, 3)
	if (CombatConfig.ComboHitStopSec[step] or 0) <= 0 then
		return false
	end
	local hit = pickHit(hits)
	if not hit then
		return false
	end
	local dur = CombatHitStop.ResolveDuration(fx, hit)
	if dur <= 0 then
		return false
	end
	CombatAnim.ApplyHitStop(dur)
	local kick = CombatHitStop.CameraIntensity(fx, hit)
	if kick > 0 then
		CombatVfx.CameraKick(kick)
	end
	return true
end

return CombatHitStop
