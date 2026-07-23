--[[
	Status store + tick batch for ReactionResolver FIFO.
]]

local StatusService = {}

export type StatusInstance = {
	id: string,
	expiresAt: number?,
	sourceUserId: number?,
	params: { [string]: any }?,
	dps: number?,
	hps: number?, -- heal per second (HoT)
	seq: number,
}

local byEntity: { [Instance]: { StatusInstance } } = {}
local batchNew: { [Instance]: { StatusInstance } } = {}
local seqCounter = 0
local ccApplyCount: { [string]: number } = {}

local function syncNameplate(entity: Instance)
	local ok, svc = pcall(function()
		return require(script.Parent.NameplateService)
	end)
	if ok and svc then
		svc.Sync(entity)
	end
end

local HARD_CC = { Shock = true, Stun = true, Chilled = true, Knockback = true }

local onExpireCb: ((Instance, string) -> ())? = nil

function StatusService.SetOnExpire(callback: (Instance, string) -> ())
	onExpireCb = callback
end

local function notifyExpired(entity: Instance, statusId: string)
	if onExpireCb then
		onExpireCb(entity, statusId)
	end
end

local function diminishKey(entity: Instance, statusId: string, sourceUserId: number?): string
	return `{tostring(entity)}_{statusId}_{sourceUserId or 0}`
end

local function applyCcDiminishing(statusId: string, duration: number?, sourceUserId: number?, entity: Instance): number?
	if not duration or duration <= 0 or not HARD_CC[statusId] or not sourceUserId then
		return duration
	end
	local key = diminishKey(entity, statusId, sourceUserId)
	local n = (ccApplyCount[key] or 0) + 1
	ccApplyCount[key] = n
	return duration * (0.5 ^ (n - 1))
end

local function clearCcDiminishing(entity: Instance, statusId: string, sourceUserId: number?)
	local key = diminishKey(entity, statusId, sourceUserId)
	ccApplyCount[key] = nil
end

local function now(): number
	return os.clock()
end

local function nextSeq(): number
	seqCounter += 1
	return seqCounter
end

function StatusService.GetList(entity: Instance): { StatusInstance }
	local list = byEntity[entity]
	if not list then
		return {}
	end
	local out = {}
	local t = now()
	for _, s in list do
		if s.expiresAt == nil or s.expiresAt > t then
			table.insert(out, s)
		end
	end
	return out
end

function StatusService.Has(entity: Instance, statusId: string): boolean
	for _, s in StatusService.GetList(entity) do
		if s.id == statusId then
			return true
		end
	end
	return false
end

function StatusService.Get(entity: Instance, statusId: string): StatusInstance?
	for _, s in StatusService.GetList(entity) do
		if s.id == statusId then
			return s
		end
	end
	return nil
end

function StatusService.RemainingSeconds(entity: Instance, statusId: string): number
	local s = StatusService.Get(entity, statusId)
	if not s or not s.expiresAt then
		return 0
	end
	return math.max(0, s.expiresAt - now())
end

function StatusService.RemainingDamage(entity: Instance, statusId: string): number
	local s = StatusService.Get(entity, statusId)
	if not s or not s.dps or not s.expiresAt then
		return 0
	end
	local rem = math.max(0, s.expiresAt - now())
	return s.dps * rem
end

function StatusService.Remove(entity: Instance, statusId: string, sourceUserId: number?)
	local list = byEntity[entity]
	if not list then
		return
	end
	for i = #list, 1, -1 do
		local s = list[i]
		if s.id == statusId and (sourceUserId == nil or s.sourceUserId == sourceUserId) then
			if sourceUserId then
				clearCcDiminishing(entity, statusId, sourceUserId)
			end
			if HARD_CC[statusId] then
				notifyExpired(entity, statusId)
			end
			table.remove(list, i)
		end
	end
	syncNameplate(entity)
end

function StatusService.Apply(
	entity: Instance,
	statusId: string,
	duration: number?,
	opts: { sourceUserId: number?, params: { [string]: any }?, dps: number?, hps: number?, silentBatch: boolean? }?
)
	opts = opts or {}
	local adjustedDuration = applyCcDiminishing(statusId, duration, opts.sourceUserId, entity)
	local list = byEntity[entity]
	if not list then
		list = {}
		byEntity[entity] = list
	end

	for _, s in list do
		if s.id == statusId then
			if adjustedDuration and adjustedDuration > 0 then
				s.expiresAt = now() + adjustedDuration
			else
				s.expiresAt = nil
			end
			if opts.params then
				s.params = opts.params
			end
			if opts.dps then
				s.dps = opts.dps
			end
			if opts.hps then
				s.hps = opts.hps
			end
			s.sourceUserId = opts.sourceUserId or s.sourceUserId
			s.seq = nextSeq()
			if not opts.silentBatch then
				local b = batchNew[entity]
				if not b then
					b = {}
					batchNew[entity] = b
				end
				table.insert(b, s)
			end
			syncNameplate(entity)
			return s
		end
	end

	local inst: StatusInstance = {
		id = statusId,
		expiresAt = if adjustedDuration and adjustedDuration > 0 then now() + adjustedDuration else nil,
		sourceUserId = opts.sourceUserId,
		params = opts.params,
		dps = opts.dps,
		hps = opts.hps,
		seq = nextSeq(),
	}
	table.insert(list, inst)
	if not opts.silentBatch then
		local b = batchNew[entity]
		if not b then
			b = {}
			batchNew[entity] = b
		end
		table.insert(b, inst)
	end
	syncNameplate(entity)
	return inst
end

function StatusService.TakeBatch(entity: Instance): { StatusInstance }
	local b = batchNew[entity]
	batchNew[entity] = nil
	return b or {}
end

function StatusService.EntitiesWithBatch(): { Instance }
	local out = {}
	for e in batchNew do
		table.insert(out, e)
	end
	return out
end

function StatusService.ClearEntity(entity: Instance)
	local list = byEntity[entity]
	if list then
		for _, s in list do
			if s.sourceUserId then
				clearCcDiminishing(entity, s.id, s.sourceUserId)
			end
		end
	end
	byEntity[entity] = nil
	batchNew[entity] = nil
	syncNameplate(entity)
end

function StatusService.TickDoTs(dealFn: (entity: Instance, amount: number, statusId: string, sourceUserId: number?) -> ())
	local t = now()
	for entity, list in byEntity do
		if not entity.Parent then
			byEntity[entity] = nil
			continue
		end
		for i = #list, 1, -1 do
			local s = list[i]
			if s.expiresAt and s.expiresAt <= t then
				if HARD_CC[s.id] then
					notifyExpired(entity, s.id)
				end
				table.remove(list, i)
			elseif s.dps and s.dps > 0 then
				dealFn(entity, s.dps, s.id, s.sourceUserId)
			end
		end
	end
end

function StatusService.TickHoTs(healFn: (entity: Instance, amount: number, statusId: string, sourceUserId: number?) -> ())
	local t = now()
	for entity, list in byEntity do
		if not entity.Parent then
			continue
		end
		for i = #list, 1, -1 do
			local s = list[i]
			if s.expiresAt and s.expiresAt <= t then
				continue
			elseif s.hps and s.hps > 0 then
				healFn(entity, s.hps, s.id, s.sourceUserId)
			end
		end
	end
end

function StatusService.FormatShort(entity: Instance): string
	local parts = {}
	for _, s in StatusService.GetList(entity) do
		table.insert(parts, s.id)
	end
	if #parts == 0 then
		return ""
	end
	return table.concat(parts, " · ")
end

return StatusService
