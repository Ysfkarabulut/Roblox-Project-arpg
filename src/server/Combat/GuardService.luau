--[[
	Guard — shield equipped + hold. Chip / stamina / break.
]]

local Players = game:GetService("Players")
local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local ShieldDefs = require(game.ReplicatedStorage.Shared.Config.ShieldDefs)
local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
local StaminaService = require(script.Parent.StaminaService)
local StatusService = require(script.Parent.StatusService)

local GuardService = {}

local guarding: { [number]: boolean } = {}

function GuardService.GetShieldDef(userId: number)
	local loadout = LoadoutService.Get(userId)
	local uuid = loadout.off
	if not uuid then
		return nil
	end
	local inst = InventoryService.Find(userId, uuid)
	if not inst then
		return nil
	end
	local def = ItemDefs.Get(inst.defId)
	if not def or def.kind ~= "Shield" then
		return nil
	end
	return ShieldDefs.Get(inst.defId)
end

function GuardService.SetGuarding(player: Player, on: boolean): boolean
	local userId = player.UserId
	if on then
		local shield = GuardService.GetShieldDef(userId)
		if not shield then
			guarding[userId] = false
			return false
		end
		guarding[userId] = true
		if player.Character then
			StatusService.Apply(player.Character, "Guard", nil, {
				sourceUserId = userId,
				params = { chipPct = shield.chipPct, slow = shield.guardSlow },
				silentBatch = true,
			})
		end
		return true
	end
	guarding[userId] = false
	if player.Character then
		StatusService.Remove(player.Character, "Guard")
	end
	return true
end

function GuardService.IsGuarding(userId: number): boolean
	return guarding[userId] == true
end

function GuardService.Tick(player: Player, dt: number)
	local userId = player.UserId
	if not guarding[userId] then
		return
	end
	local shield = GuardService.GetShieldDef(userId)
	if not shield then
		GuardService.SetGuarding(player, false)
		return
	end
	StaminaService.Drain(userId, shield.drainPerSec * dt)
	if StaminaService.Get(userId) <= 0 then
		GuardService.SetGuarding(player, false)
		if player.Character then
			StatusService.Apply(player.Character, "Slow", 3, {
				sourceUserId = userId,
				params = { slowPct = 50 },
				silentBatch = true,
			})
		end
	end
end

function GuardService.TryBlock(
	defenderUserId: number,
	defenderChar: Model,
	attackerPos: Vector3,
	afterDr: number,
	axeMult: number?
): (boolean, number, number, boolean)
	if not GuardService.IsGuarding(defenderUserId) then
		return false, 0, 0, false
	end
	local hrp = defenderChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false, 0, 0, false
	end
	local toAtk = attackerPos - hrp.Position
	local flat = Vector3.new(toAtk.X, 0, toAtk.Z)
	if flat.Magnitude < 0.1 then
		return false, 0, 0, false
	end
	if hrp.CFrame.LookVector:Dot(flat.Unit) < 0 then
		return false, 0, 0, false
	end

	local shield = GuardService.GetShieldDef(defenderUserId)
	if not shield then
		return false, 0, 0, false
	end

	local chip = afterDr * shield.chipPct
	local stamCost = math.max(CombatConfig.GuardHitStamMin, afterDr * CombatConfig.GuardHitStamFactor)
	stamCost *= (axeMult or 1)
	StaminaService.Drain(defenderUserId, stamCost)
	local broke = StaminaService.Get(defenderUserId) <= 0
	if broke then
		local plr = Players:GetPlayerByUserId(defenderUserId)
		if plr then
			GuardService.SetGuarding(plr, false)
		end
		StatusService.Apply(defenderChar, "Stun", CombatConfig.GuardBreakStunSec, {
			silentBatch = true,
		})
	end
	return true, chip, stamCost, broke
end

function GuardService.Clear(userId: number)
	guarding[userId] = false
end

return GuardService
