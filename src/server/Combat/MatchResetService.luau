--[[
	Post-match player reset — HP, stamina, status (MODES.md §3.5).
]]

local Players = game:GetService("Players")

local StatusService = require(script.Parent.StatusService)
local StaminaService = require(script.Parent.StaminaService)
local StatService = require(script.Parent.StatService)

local MatchResetService = {}

function MatchResetService.ResetPlayer(plr: Player)
	local char = plr.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		local derived = StatService.Derived(plr.UserId)
		hum.MaxHealth = derived.hp
		hum.Health = derived.hp
	end
	StatusService.ClearEntity(char)
	StaminaService.Set(plr.UserId, StaminaService.Max(plr.UserId))
	plr:SetAttribute("CombatLocked", nil)
	plr:SetAttribute("Spectating", nil)
end

function MatchResetService.ResetPlayers(players: { Player })
	for _, plr in players do
		MatchResetService.ResetPlayer(plr)
	end
end

function MatchResetService.ResetUserIds(userIds: { number })
	for _, userId in userIds do
		local plr = Players:GetPlayerByUserId(userId)
		if plr then
			MatchResetService.ResetPlayer(plr)
		end
	end
end

return MatchResetService
