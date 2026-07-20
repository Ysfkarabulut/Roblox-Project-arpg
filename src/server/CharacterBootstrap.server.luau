--[[
	Force R15 humanoid when possible. Custom races later → MorphService.
	Studio: Game Settings → Avatar → R15 (kalıcı).
]]

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

pcall(function()
	-- Some Studio builds expose this; ignore if missing
	(StarterPlayer :: any).GameSettingsAvatar = Enum.GameAvatarType.R15
end)

local function onCharacter(char: Model)
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if hum then
		-- Already R15 in modern experiences; attribute for tooling
		char:SetAttribute("Rig", "R15")
	end
end

local function hook(player: Player)
	player:SetAttribute("AvatarRig", "R15")
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end
end

Players.PlayerAdded:Connect(hook)
for _, p in Players:GetPlayers() do
	hook(p)
end

print("[CharacterBootstrap] R15 default (set Studio Avatar = R15)")
