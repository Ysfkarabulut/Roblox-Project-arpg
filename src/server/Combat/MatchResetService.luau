--[[
	Post-match player reset — HP, stamina, status (MODES.md §3.5).
]]

local Players = game:GetService("Players")

local StatusService = require(script.Parent.StatusService)
local StaminaService = require(script.Parent.StaminaService)
local StatService = require(script.Parent.StatService)
local ComboTracker = require(script.Parent.ComboTracker)
local CrossbowReloadService = require(script.Parent.CrossbowReloadService)
local GuardService = require(script.Parent.GuardService)
local DodgeService = require(script.Parent.DodgeService)
local ParryService = require(script.Parent.ParryService)
local AbilityService = require(script.Parent.AbilityService)
local LightAttackService = require(script.Parent.LightAttackService)

local MatchResetService = {}

function MatchResetService.ResetPlayer(plr: Player)
	local char = plr.Character
	local userId = plr.UserId
	ComboTracker.Clear(userId)
	CrossbowReloadService.Clear(userId)
	GuardService.Clear(userId)
	DodgeService.Clear(userId)
	ParryService.Clear(userId)
	AbilityService.Clear(userId)
	LightAttackService.Clear(userId)

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
