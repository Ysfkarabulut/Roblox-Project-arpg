--[[
	Sync combat nameplate data to model attributes (client CombatNameplate reads).
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local NameplateConfig = require(game.ReplicatedStorage.Shared.Config.NameplateConfig)
local StatusQuery = require(game.ReplicatedStorage.Shared.Combat.StatusQuery)
local StatusService = require(script.Parent.StatusService)
local DummyService = require(script.Parent.DummyService)

local NameplateService = {}

local function bossEntityService()
	return require(script.Parent.Parent.Boss.BossEntityService)
end

local tracked: { [Instance]: boolean } = {}
local acc = 0

local function resolveKind(entity: Instance): string?
	local kind = entity:GetAttribute("NameplateKind")
	if typeof(kind) == "string" and kind ~= "" then
		return kind
	end
	if entity:GetAttribute("IsBoss") then
		return "Boss"
	end
	if entity:GetAttribute("IsBossAdd") then
		return "BossAdd"
	end
	if entity:GetAttribute("IsPvpOpponent") then
		return "Pvp"
	end
	if entity:GetAttribute("IsCombatDummy") then
		return "Training"
	end
	local plr = Players:GetPlayerFromCharacter(entity)
	if plr then
		if plr:GetAttribute("PvpTeam") then
			return "Pvp"
		end
		return "Player"
	end
	return nil
end

local function resolveHp(entity: Instance): (number, number)
	local kind = resolveKind(entity)
	if kind == "Training" and entity.Name == "TrainingDummy" then
		local hp, maxHp = DummyService.GetHp()
		return hp, maxHp
	end
	if kind == "Boss" and entity:GetAttribute("IsBoss") then
		return bossEntityService().GetHp()
	end
	local hum = entity:FindFirstChildOfClass("Humanoid")
	if hum then
		return hum.Health, hum.MaxHealth
	end
	return 0, 1
end

local function encodeStatuses(entity: Instance): string
	local entries = {}
	for _, s in StatusService.GetList(entity) do
		local vis = NameplateConfig.StatusVisual(s.id)
		local remaining = nil
		if s.expiresAt then
			remaining = math.max(0, s.expiresAt - os.clock())
		end
		table.insert(entries, {
			id = s.id,
			label = vis.label,
			remaining = remaining,
			r = math.floor(vis.color.R * 255 + 0.5),
			g = math.floor(vis.color.G * 255 + 0.5),
			b = math.floor(vis.color.B * 255 + 0.5),
			debuff = vis.debuff,
			abbrev = vis.abbrev,
		})
	end
	table.sort(entries, function(a, b)
		if a.debuff ~= b.debuff then
			return a.debuff
		end
		return (a.remaining or 999) < (b.remaining or 999)
	end)
	while #entries > NameplateConfig.MaxStatusSlots do
		table.remove(entries)
	end
	local ok, json = pcall(function()
		return HttpService:JSONEncode(entries)
	end)
	return if ok then json else "[]"
end

function NameplateService.Track(entity: Instance)
	if entity and entity:IsA("Model") then
		tracked[entity] = true
	end
end

function NameplateService.Untrack(entity: Instance)
	tracked[entity] = nil
end

function NameplateService.Setup(
	entity: Model,
	kind: NameplateConfig.NameplateKind,
	name: string,
	opts: { phase: number? }?
)
	entity:SetAttribute("NameplateKind", kind)
	entity:SetAttribute("NameplateName", name)
	if opts and opts.phase then
		entity:SetAttribute("NameplatePhase", opts.phase)
	end
	local hum = entity:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	NameplateService.Track(entity)
	NameplateService.Sync(entity)
end

function NameplateService.SetupPlayerCharacter(plr: Player, char: Model)
	local name = plr.DisplayName
	if name == "" then
		name = plr.Name
	end
	local kind: NameplateConfig.NameplateKind = if plr:GetAttribute("PvpTeam") then "Pvp" else "Player"
	NameplateService.Setup(char, kind, name)
end

function NameplateService.Sync(entity: Instance)
	if not entity or not entity.Parent then
		return
	end
	local kind = resolveKind(entity)
	if not kind then
		return
	end
	if not entity:GetAttribute("NameplateKind") or entity:GetAttribute("NameplateKind") ~= kind then
		entity:SetAttribute("NameplateKind", kind)
	end
	local hp, maxHp = resolveHp(entity)
	entity:SetAttribute("NameplateHp", math.floor(hp + 0.5))
	entity:SetAttribute("NameplateMaxHp", math.max(1, math.floor(maxHp + 0.5)))
	entity:SetAttribute("NameplateStatuses", encodeStatuses(entity))
	local moveEntries: { StatusQuery.StatusEntry } = {}
	for _, s in StatusService.GetList(entity) do
		table.insert(moveEntries, { id = s.id, params = s.params })
	end
	entity:SetAttribute("MoveSpeedMult", StatusQuery.GetMoveSpeedMult(moveEntries))
	if kind == "Boss" then
		entity:SetAttribute("NameplatePhase", bossEntityService().GetPhase())
	end
	NameplateService.Track(entity)
end

function NameplateService.SyncAll()
	for entity in tracked do
		if entity.Parent then
			NameplateService.Sync(entity)
		else
			tracked[entity] = nil
		end
	end
end

function NameplateService.Tick(dt: number)
	acc += dt
	if acc < 0.2 then
		return
	end
	acc = 0
	NameplateService.SyncAll()
end

return NameplateService
