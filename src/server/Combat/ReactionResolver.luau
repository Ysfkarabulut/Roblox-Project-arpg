--[[
	Batch-frame FIFO reaction resolution — CHEMISTRY §5.4
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ReactionTable = require(game.ReplicatedStorage.Shared.Config.ReactionTable)
local StatusService = require(script.Parent.StatusService)
local CombatPressureService = require(script.Parent.CombatPressureService)

local ReactionResolver = {}

local dealBurst: ((entity: Instance, amount: number, reactionId: string, sourceUserId: number?) -> ())?
local onReactionFx: ((entity: Instance, reactionId: string) -> ())?

function ReactionResolver.Bind(deps: {
	dealBurst: (entity: Instance, amount: number, reactionId: string, sourceUserId: number?) -> (),
	onFx: ((entity: Instance, reactionId: string) -> ())?,
})
	dealBurst = deps.dealBurst
	onReactionFx = deps.onFx
end

local function remainingDpsProxy(entity: Instance, statusId: string): number
	local s = StatusService.Get(entity, statusId)
	if s and s.dps then
		return s.dps
	end
	-- defaults
	if statusId == "Ignite" then
		return 7
	elseif statusId == "Bleed" then
		return 4
	elseif statusId == "Poisoned" then
		return 3
	end
	return 5
end

local function chainNearby(originEntity: Instance, applyStatus: string, sourceUserId: number?)
	local originPart = (originEntity :: Model).PrimaryPart
		or originEntity:FindFirstChild("HumanoidRootPart")
	if not originPart or not originPart:IsA("BasePart") then
		return
	end
	local origin = originPart.Position
	local count = 0
	local function try(model: Model)
		if model == originEntity or count >= 6 then
			return
		end
		local pp = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
		if not pp or not pp:IsA("BasePart") then
			return
		end
		if (pp.Position - origin).Magnitude > 12 then
			return
		end
		if StatusService.Has(model, "Wet") then
			StatusService.Remove(model, "Wet")
			local dur = if applyStatus == "Shock" then 0.5 else 5
			local dps = if applyStatus == "Poisoned" then 3 else nil
			CombatPressureService.TryApplyStatus(model, applyStatus, dur, {
				sourceUserId = sourceUserId,
				dps = dps,
				silentBatch = true,
			})
			count += 1
		end
	end
	local dummy = Workspace:FindFirstChild("TrainingDummy")
	if dummy and dummy:IsA("Model") then
		try(dummy)
	end
	for _, plr in Players:GetPlayers() do
		if plr.Character then
			try(plr.Character)
		end
	end
end

local function resolveOutputDuration(entity: Instance, def: any): number?
	if def.outputDurationFrom == "maxInputs" then
		return math.max(StatusService.RemainingSeconds(entity, def.a), StatusService.RemainingSeconds(entity, def.b))
	end
	if def.outputDurationFrom == "minInputs" then
		local a = StatusService.RemainingSeconds(entity, def.a)
		local b = StatusService.RemainingSeconds(entity, def.b)
		if a <= 0 and b <= 0 then
			return 0
		end
		if a <= 0 then
			return b
		end
		if b <= 0 then
			return a
		end
		return math.min(a, b)
	end
	return def.outputDuration
end

function ReactionResolver.ResolveEntity(entity: Instance)
	local batch = StatusService.TakeBatch(entity)
	if #batch == 0 then
		return
	end
	-- Sort batch by seq (FIFO)
	table.sort(batch, function(a, b)
		return a.seq < b.seq
	end)

	local consumed: { [string]: boolean } = {}

	for _, incoming in batch do
		if consumed[incoming.id] then
			continue
		end
		-- Find first reaction with existing pool (not consumed)
		local pool = StatusService.GetList(entity)
		local matched = false
		for _, existing in pool do
			if existing.id == incoming.id then
				continue
			end
			if consumed[existing.id] then
				continue
			end
			local def = ReactionTable.FindPair(incoming.id, existing.id)
			if def then
				-- Consume both
				local remBurst = 0
				if def.burstFrom then
					remBurst = StatusService.RemainingDamage(entity, def.burstFrom)
					if remBurst <= 0 then
						remBurst = remainingDpsProxy(entity, def.burstFrom) * 2
					end
					remBurst *= (def.burstFactor or 1)
				end
				local outDps = nil
				if def.outputDpsFactor then
					local base = remainingDpsProxy(entity, "Ignite")
					if def.id == "Blight" or def.id == "CausticBurn" then
						base = remainingDpsProxy(entity, def.a) + remainingDpsProxy(entity, def.b)
						base = math.max(base / 2, 4)
					elseif def.id == "WildFire" then
						base = remainingDpsProxy(entity, "Ignite") * 1.5
					elseif def.id == "Cauterize" then
						base = remainingDpsProxy(entity, "Ignite")
					end
					outDps = base * (if def.id == "WildFire" then 1 else def.outputDpsFactor)
					if def.id == "WildFire" then
						outDps = base -- already ×1.5
					end
				end

				local outDur = if def.outputStatus then resolveOutputDuration(entity, def) else nil
				if outDur and outDur <= 0 then
					outDur = def.outputDuration or 0.1
				end

				StatusService.Remove(entity, def.a)
				StatusService.Remove(entity, def.b)
				consumed[def.a] = true
				consumed[def.b] = true

				local src = incoming.sourceUserId or existing.sourceUserId
				if def.kind == "Burst" or def.kind == "Hybrid" then
					if dealBurst and remBurst > 0 then
						dealBurst(entity, remBurst, def.id, src)
					end
				end
				if def.outputStatus and outDur then
					CombatPressureService.TryApplyStatus(entity, def.outputStatus, outDur, {
						sourceUserId = src,
						dps = outDps,
						params = def.outputParams,
						silentBatch = true,
					})
				end
				if def.kind == "Chain" and def.chain then
					chainNearby(entity, def.chain, src)
					if def.chain == "Shock" then
						CombatPressureService.TryApplyStatus(entity, "Shock", 0.5, { sourceUserId = src, silentBatch = true })
					elseif def.chain == "Poisoned" then
						StatusService.Apply(entity, "Poisoned", 5, { sourceUserId = src, dps = 3, silentBatch = true })
					end
				end
				if onReactionFx then
					onReactionFx(entity, def.id)
				end
				matched = true
				break
			end
		end
		if matched then
			-- continue FIFO with next incoming
		end
	end
end

function ReactionResolver.ResolveAllPending()
	for _, entity in StatusService.EntitiesWithBatch() do
		ReactionResolver.ResolveEntity(entity)
	end
end

return ReactionResolver
