--[[
	Hitstun, endlag locks, juggle limit, hyper armor, CC immunity.
]]

local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local StatusQuery = require(game.ReplicatedStorage.Shared.Combat.StatusQuery)
local PressureTypes = require(game.ReplicatedStorage.Shared.Combat.PressureTypes)
local StatusService = require(script.Parent.StatusService)

local CombatPressureService = {}

type JuggleState = {
	count: number,
	lastSwingAt: number,
}

local actionLockUntil: { [number]: number } = {}
local juggleByPair: { [string]: JuggleState } = {}
local swingCounted: { [string]: boolean } = {}

local function now(): number
	return os.clock()
end

local function statusEntries(entity: Instance): { StatusQuery.StatusEntry }
	local out: { StatusQuery.StatusEntry } = {}
	for _, s in StatusService.GetList(entity) do
		table.insert(out, { id = s.id, params = s.params })
	end
	return out
end

local function pairKey(attackerUserId: number, victim: Instance): string
	return `{attackerUserId}_{tostring(victim)}`
end

local function swingKey(attackerUserId: number, victim: Instance, groupId: string): string
	return `{attackerUserId}_{tostring(victim)}_{groupId}`
end

function CombatPressureService.CanAttackEntity(entity: Instance?): boolean
	if not entity then
		return false
	end
	return StatusQuery.CanAttack(statusEntries(entity))
end

function CombatPressureService.CanMoveEntity(entity: Instance?): boolean
	if not entity then
		return false
	end
	return StatusQuery.CanMove(statusEntries(entity))
end

function CombatPressureService.HasHyperArmor(entity: Instance?): boolean
	if not entity then
		return false
	end
	return StatusQuery.HasHyperArmor(statusEntries(entity))
end

function CombatPressureService.HasCcImmunity(entity: Instance?): boolean
	if not entity then
		return false
	end
	return StatusQuery.HasCcImmunity(statusEntries(entity))
end

function CombatPressureService.IsActionLocked(userId: number): boolean
	return now() < (actionLockUntil[userId] or 0)
end

function CombatPressureService.LockActions(userId: number, sec: number)
	if sec <= 0 then
		return
	end
	local untilAt = now() + sec
	actionLockUntil[userId] = math.max(actionLockUntil[userId] or 0, untilAt)
end

function CombatPressureService.ClearUser(userId: number)
	actionLockUntil[userId] = nil
	for key in juggleByPair do
		if string.find(key, tostring(userId) .. "_", 1, true) == 1 then
			juggleByPair[key] = nil
		end
	end
end

function CombatPressureService.ResetForPlayer(userId: number)
	CombatPressureService.ClearUser(userId)
	local uid = tostring(userId)
	for key in juggleByPair do
		if string.find(key, uid .. "_", 1, true) == 1 or string.find(key, "_" .. uid, 1, true) then
			juggleByPair[key] = nil
		end
	end
	for key in swingCounted do
		if string.find(key, uid, 1, true) then
			swingCounted[key] = nil
		end
	end
end

function CombatPressureService.ApplyHyperArmor(entity: Instance, duration: number, sourceUserId: number?)
	if not entity or duration <= 0 then
		return
	end
	StatusService.Apply(entity, "HyperArmor", duration, {
		sourceUserId = sourceUserId,
		silentBatch = true,
	})
end

function CombatPressureService.GrantCcImmunity(entity: Instance, duration: number, reason: string?)
	if not entity or duration <= 0 then
		return
	end
	StatusService.Apply(entity, "CcImmunity", duration, {
		silentBatch = true,
		params = { reason = reason or "cc" },
	})
end

function CombatPressureService.OnHardCcEnded(entity: Instance)
	CombatPressureService.GrantCcImmunity(entity, CombatConfig.CcImmunityAfterHardCcSec, "hard_cc")
end

local function grantJuggleBreak(entity: Instance)
	CombatPressureService.GrantCcImmunity(entity, CombatConfig.CcImmunityAfterJuggleBreakSec, "juggle")
	CombatPressureService.ApplyHyperArmor(entity, CombatConfig.CcImmunityAfterJuggleBreakSec * 0.85)
	StatusService.Apply(entity, "JuggleBreak", CombatConfig.CcImmunityAfterJuggleBreakSec, {
		silentBatch = true,
	})
end

function CombatPressureService.TryApplyStatus(
	entity: Instance,
	statusId: string,
	duration: number?,
	opts: { sourceUserId: number?, params: { [string]: any }?, dps: number?, hps: number?, silentBatch: boolean? }?
): boolean
	opts = opts or {}
	if PressureTypes.IsInterruptCc(statusId) or statusId == "Root" then
		if CombatPressureService.HasCcImmunity(entity) or CombatPressureService.HasHyperArmor(entity) then
			return false
		end
	end
	StatusService.Apply(entity, statusId, duration, opts)
	return true
end

local function hitstunDuration(attackKind: string?, comboStep: number?): number
	if attackKind == "Ability" then
		return CombatConfig.AbilityHitstunSec or 0.12
	end
	local step = math.clamp(comboStep or 1, 1, 3)
	return (CombatConfig.HitstunSec or {})[step] or 0.1
end

function CombatPressureService.ApplyHitConsequences(
	attackerUserId: number,
	victim: Instance,
	opts: {
		dealt: number,
		blocked: boolean?,
		comboStep: number?,
		attackKind: string?,
		pressureGroupId: string?,
	}
)
	if opts.dealt <= 0 or opts.blocked then
		return
	end
	if CombatPressureService.HasCcImmunity(victim) or CombatPressureService.HasHyperArmor(victim) then
		return
	end

	local t = now()
	local pair = pairKey(attackerUserId, victim)
	local jState = juggleByPair[pair]
	if not jState or (t - jState.lastSwingAt) > (CombatConfig.JuggleResetGapSec or 1) then
		jState = { count = 0, lastSwingAt = t }
	end

	local groupId = opts.pressureGroupId or `{attackerUserId}_{math.floor(t * 1000)}`
	local sKey = swingKey(attackerUserId, victim, groupId)
	local countSwing = swingCounted[sKey] ~= true
	if countSwing then
		swingCounted[sKey] = true
		task.delay(0.2, function()
			swingCounted[sKey] = nil
		end)
		jState.count += 1
		jState.lastSwingAt = t
		juggleByPair[pair] = jState
	end

	if jState.count > (CombatConfig.JuggleHitLimit or 5) then
		grantJuggleBreak(victim)
		juggleByPair[pair] = { count = 0, lastSwingAt = t }
		return
	end

	local dur = hitstunDuration(opts.attackKind, opts.comboStep)
	if dur <= 0 then
		return
	end
	StatusService.Apply(victim, "Hitstun", dur, {
		sourceUserId = attackerUserId,
		params = { slowPct = CombatConfig.HitstunMoveSlowPct or 40 },
		silentBatch = true,
	})
end

function CombatPressureService.L3EndlagBonus(): number
	return CombatConfig.ComboL3EndlagSec or 0
end

function CombatPressureService.AbilityRecoverySec(): number
	return CombatConfig.AbilityCastRecoverySec or 0
end

return CombatPressureService
