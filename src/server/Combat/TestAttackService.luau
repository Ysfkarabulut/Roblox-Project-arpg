--[[
	Minimal light-attack vs lobby dummy (pre-DamagePipeline).
]]

local CombatConfig = require(game.ReplicatedStorage.Shared.Config.CombatConfig)
local ItemDefs = require(game.ReplicatedStorage.Shared.Config.ItemDefs)
local StatService = require(script.Parent.StatService)
local DummyService = require(script.Parent.DummyService)
local LoadoutService = require(script.Parent.Parent.Inventory.LoadoutService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)

local TestAttackService = {}

local lastSwing: { [number]: number } = {}

local function scalingStat(userId: number, scaling: string?): number
	local s = StatService.Get(userId)
	if scaling == "DEX" then
		return s.DEX
	elseif scaling == "INT" then
		return s.INT
	end
	return s.STR
end

function TestAttackService.LightAttack(player: Player): { ok: boolean, damage: number?, remaining: number?, dead: boolean?, reason: string? }
	local userId = player.UserId
	local now = os.clock()
	local prev = lastSwing[userId] or 0
	if now - prev < CombatConfig.MeleeCooldownSec then
		return { ok = false, reason = "Cooldown" }
	end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local dummyPos = DummyService.GetPosition()
	if not hrp or not dummyPos then
		return { ok = false, reason = "NoTarget" }
	end

	local dist = (hrp.Position - dummyPos).Magnitude
	if dist > CombatConfig.MeleeRange then
		return { ok = false, reason = "OutOfRange" }
	end

	local hp, _ = DummyService.GetHp()
	if hp <= 0 then
		return { ok = false, reason = "DummyDead" }
	end

	lastSwing[userId] = now

	local weaponBase = CombatConfig.DefaultWeaponBase
	local scaling: string? = "STR"
	local loadout = LoadoutService.Get(userId)
	local mainUuid = loadout.main
	if mainUuid then
		local inst = InventoryService.Find(userId, mainUuid)
		local def = inst and ItemDefs.Get(inst.defId)
		if def then
			weaponBase = def.baseDamage or weaponBase
			scaling = def.scaling or scaling
		end
	end

	local scale = scalingStat(userId, scaling)
	local raw = weaponBase * (1 + scale * CombatConfig.KDmg)
	-- Dummy has no Defence in lobby stub
	local damage = math.max(1, math.floor(raw + 0.5))

	local dealt, dead = DummyService.ApplyDamage(damage)
	local remaining = select(1, DummyService.GetHp())
	return {
		ok = true,
		damage = dealt,
		remaining = remaining,
		dead = dead,
	}
end

function TestAttackService.Clear(userId: number)
	lastSwing[userId] = nil
end

return TestAttackService
