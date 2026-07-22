--[[
	Force classic R15 blocky avatar for all players.
	Game is designed around default blocky proportions (not player packages).

	IMPORTANT: Avoid Humanoid:ApplyDescription on a live character with AnimationConstraints —
	it can leave attachments/constraints in a collapsed pose. Prefer LoadCharacterAppearance=false
	+ CreateHumanoidModelFromDescription replacement when needed.
]]

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

pcall(function()
	(StarterPlayer :: any).GameSettingsAvatar = Enum.GameAvatarType.R15
end)

pcall(function()
	StarterPlayer.LoadCharacterAppearance = false
end)

local function blockyDescription(): HumanoidDescription
	local d = Instance.new("HumanoidDescription")
	d.HeightScale = 1
	d.WidthScale = 1
	d.DepthScale = 1
	d.HeadScale = 1
	d.BodyTypeScale = 0
	d.ProportionScale = 0
	local skin = Color3.fromRGB(163, 162, 165)
	d.HeadColor = skin
	d.TorsoColor = skin
	d.LeftArmColor = skin
	d.RightArmColor = skin
	d.LeftLegColor = skin
	d.RightLegColor = skin
	return d
end

local function stripCosmetics(char: Model)
	for _, child in char:GetChildren() do
		if
			child:IsA("Accessory")
			or child:IsA("Shirt")
			or child:IsA("Pants")
			or child:IsA("ShirtGraphic")
			or child:IsA("CharacterMesh")
			or child:IsA("Clothing")
		then
			child:Destroy()
		end
	end
	for _, d in char:GetDescendants() do
		if d:IsA("WrapLayer") then
			d:Destroy()
		end
	end
end

local function ensureFace(char: Model)
	local head = char:FindFirstChild("Head")
	if head and not head:FindFirstChildOfClass("Decal") then
		local face = Instance.new("Decal")
		face.Name = "face"
		face.Face = Enum.NormalId.Front
		face.Texture = "rbxasset://textures/face.png"
		face.Parent = head
	end
end

local function applyBlocky(player: Player, char: Model)
	-- Soft path: appearance already off → just strip + tag (keeps healthy AC rest pose)
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if not hum then
		return
	end
	hum.RigType = Enum.HumanoidRigType.R15
	stripCosmetics(char)
	ensureFace(char)
	char:SetAttribute("Rig", "R15")
	char:SetAttribute("AvatarStyle", "Blocky")

	-- If packages somehow remain (layered body), rebuild from a clean blocky model once.
	local hasPackage = char:FindFirstChildOfClass("Accessory") ~= nil
		or char:FindFirstChildWhichIsA("WrapLayer", true) ~= nil
	if hasPackage then
		local desc = blockyDescription()
		local ok, model = pcall(function()
			return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		end)
		if ok and model then
			model.Name = player.Name
			model:PivotTo(char:GetPivot())
			player.Character = model
			model.Parent = workspace
			stripCosmetics(model)
			ensureFace(model)
			model:SetAttribute("Rig", "R15")
			model:SetAttribute("AvatarStyle", "Blocky")
		end
	end
end

local function hook(player: Player)
	player:SetAttribute("AvatarRig", "R15")
	player:SetAttribute("AvatarStyle", "Blocky")
	player.CharacterAdded:Connect(function(char)
		task.defer(function()
			if player.Character == char then
				applyBlocky(player, char)
			end
		end)
	end)
	if player.Character then
		applyBlocky(player, player.Character)
	end
end

Players.PlayerAdded:Connect(hook)
for _, p in Players:GetPlayers() do
	hook(p)
end

print("[CharacterBootstrap] R15 blocky (no live ApplyDescription)")
