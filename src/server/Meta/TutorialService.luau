--[[
	Tutorial progress (server authoritative).
]]

local TutorialConfig = require(game.ReplicatedStorage.Shared.Config.TutorialConfig)

local TutorialService = {}

local flagsByUser: { [number]: { [string]: boolean } } = {}

function TutorialService.Ensure(userId: number)
	if not flagsByUser[userId] then
		flagsByUser[userId] = {}
	end
end

function TutorialService.Import(userId: number, flags: { [string]: boolean }?)
	TutorialService.Ensure(userId)
	if typeof(flags) ~= "table" then
		return
	end
	for key, val in flags do
		if typeof(key) == "string" and val == true then
			flagsByUser[userId][key] = true
		end
	end
end

function TutorialService.Export(userId: number): { [string]: boolean }
	TutorialService.Ensure(userId)
	return table.clone(flagsByUser[userId])
end

function TutorialService.IsDone(userId: number, step: string): boolean
	TutorialService.Ensure(userId)
	return flagsByUser[userId][step] == true
end

function TutorialService.Complete(userId: number, step: string): boolean
	if not table.find(TutorialConfig.Steps, step) then
		return false
	end
	TutorialService.Ensure(userId)
	flagsByUser[userId][step] = true
	return true
end

function TutorialService.NextStep(userId: number): string?
	for _, step in TutorialConfig.Steps do
		if not TutorialService.IsDone(userId, step) then
			return step
		end
	end
	return nil
end

function TutorialService.Clear(userId: number)
	flagsByUser[userId] = nil
end

return TutorialService
