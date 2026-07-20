--[[
	Parry — shield dışında her loadout. RMB hold.
	Perfect window → 0 dmg, attacker Stun 1s, on-hit yok.
	Fail → max stam × 50% (1H band) / 75% (2H band), parry kapanır.
]]

local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
local StaminaService = require(script.Parent.StaminaService)
local StatusService = require(script.Parent.StatusService)
local GuardService = require(script.Parent.GuardService)

local ParryService = {}

type State = {
	active: boolean,
	startedAt: number,
}

local byUser: { [number]: State } = {}

local TWO_H_KINDS = {
	Weapon2H = true,
	Staff = true,
	Bow = true,
	Crossbow = true,
}

local function ensure(userId: number): State
	if not byUser[userId] then
		byUser[userId] = { active = false, startedAt = 0 }
	end
	return byUser[userId]
end

function ParryService.CanParry(userId: number): boolean
	-- Shield = guard only, no parry
	if GuardService.GetShieldDef(userId) then
		return false
	end
	local loadout = LoadoutService.Get(userId)
	if not loadout.main then
		return false
	end
	local inst = InventoryService.Find(userId, loadout.main)
	local def = inst and ItemDefs.Get(inst.defId)
	return def ~= nil
end

function ParryService.FailCostFraction(userId: number): number
	local loadout = LoadoutService.Get(userId)
	if loadout.main then
		local inst = InventoryService.Find(userId, loadout.main)
		local def = inst and ItemDefs.Get(inst.defId)
		if def and TWO_H_KINDS[def.kind] then
			return CombatConfig.ParryFailCost2H
		end
	end
	return CombatConfig.ParryFailCost1H
end

function ParryService.IsParrying(userId: number): boolean
	return ensure(userId).active
end

function ParryService.IsPerfect(userId: number): boolean
	local s = ensure(userId)
	if not s.active then
		return false
	end
	return (os.clock() - s.startedAt) <= CombatConfig.ParryPerfectWindowSec
end

function ParryService.SetParrying(player: Player, on: boolean): boolean
	local userId = player.UserId
	if on then
		if not ParryService.CanParry(userId) then
			ensure(userId).active = false
			return false
		end
		-- Guard ile çakışmasın
		if GuardService.IsGuarding(userId) then
			GuardService.SetGuarding(player, false)
		end
		local s = ensure(userId)
		s.active = true
		s.startedAt = os.clock()
		if player.Character then
			StatusService.Apply(player.Character, "Parry", nil, {
				sourceUserId = userId,
				params = {
					perfectUntil = s.startedAt + CombatConfig.ParryPerfectWindowSec,
					slowPct = CombatConfig.ParryStanceSlowPct,
				},
				silentBatch = true,
			})
		end
		return true
	end
	ensure(userId).active = false
	if player.Character then
		StatusService.Remove(player.Character, "Parry")
	end
	return true
end

function ParryService.Close(player: Player)
	ParryService.SetParrying(player, false)
end

--- Returns: handled, perfect, failCost
function ParryService.TryParry(
	defenderUserId: number,
	defenderChar: Model,
	attackerPlayer: Player?,
	attackerPos: Vector3
): (boolean, boolean, number)
	if not ParryService.IsParrying(defenderUserId) then
		return false, false, 0
	end

	local hrp = defenderChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false, false, 0
	end
	local toAtk = attackerPos - hrp.Position
	local flat = Vector3.new(toAtk.X, 0, toAtk.Z)
	if flat.Magnitude < 0.1 then
		return false, false, 0
	end
	-- Front 180°
	if hrp.CFrame.LookVector:Dot(flat.Unit) < 0 then
		return false, false, 0
	end

	local perfect = ParryService.IsPerfect(defenderUserId)
	local defPlr = game:GetService("Players"):GetPlayerByUserId(defenderUserId)

	if perfect then
		if attackerPlayer and attackerPlayer.Character then
			StatusService.Apply(attackerPlayer.Character, "Stun", CombatConfig.ParryStunSec, {
				sourceUserId = defenderUserId,
				silentBatch = true,
			})
		end
		-- Stay in parry stance after perfect (can re-window on release/repress; keep active)
		if defPlr and defPlr.Character then
			-- Refresh status label only
			StatusService.Apply(defPlr.Character, "Parry", nil, {
				sourceUserId = defenderUserId,
				silentBatch = true,
			})
		end
		-- Restart perfect window after successful perfect (generous proto)
		local s = ensure(defenderUserId)
		s.startedAt = os.clock()
		return true, true, 0
	end

	-- Fail
	local frac = ParryService.FailCostFraction(defenderUserId)
	local cost = StaminaService.Max(defenderUserId) * frac
	StaminaService.Drain(defenderUserId, cost)
	if defPlr then
		ParryService.Close(defPlr)
	end
	return true, false, cost
end

function ParryService.Tick(player: Player, _dt: number)
	local userId = player.UserId
	if not ParryService.IsParrying(userId) then
		return
	end
	if not ParryService.CanParry(userId) then
		ParryService.Close(player)
		return
	end
	-- Stance: no passive drain; if stam already 0 → self Stun
	if StaminaService.Get(userId) <= 0 then
		ParryService.Close(player)
		if player.Character then
			StatusService.Apply(player.Character, "Stun", CombatConfig.ParryEmptyStamStunSec, {
				sourceUserId = userId,
				silentBatch = true,
			})
		end
	end
end

function ParryService.Clear(userId: number)
	byUser[userId] = nil
end

return ParryService
