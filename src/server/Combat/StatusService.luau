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
	seq: number,
}

local byEntity: { [Instance]: { StatusInstance } } = {}
local batchNew: { [Instance]: { StatusInstance } } = {}
local seqCounter = 0

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
			table.remove(list, i)
		end
	end
end

function StatusService.Apply(
	entity: Instance,
	statusId: string,
	duration: number?,
	opts: { sourceUserId: number?, params: { [string]: any }?, dps: number?, silentBatch: boolean? }?
)
	opts = opts or {}
	local list = byEntity[entity]
	if not list then
		list = {}
		byEntity[entity] = list
	end

	for _, s in list do
		if s.id == statusId then
			if duration and duration > 0 then
				s.expiresAt = now() + duration
			else
				s.expiresAt = nil
			end
			if opts.params then
				s.params = opts.params
			end
			if opts.dps then
				s.dps = opts.dps
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
			return s
		end
	end

	local inst: StatusInstance = {
		id = statusId,
		expiresAt = if duration and duration > 0 then now() + duration else nil,
		sourceUserId = opts.sourceUserId,
		params = opts.params,
		dps = opts.dps,
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
	byEntity[entity] = nil
	batchNew[entity] = nil
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
				table.remove(list, i)
			elseif s.dps and s.dps > 0 then
				dealFn(entity, s.dps, s.id, s.sourceUserId)
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
