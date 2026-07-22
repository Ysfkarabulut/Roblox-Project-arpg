--[[
	Maps weapon animPrefix / family visuals → ReplicatedStorage.WeaponMeshes model names.
	Meshes = Studio AI / procedural models (preserved via project.json ignoreUnknown).
]]

local WeaponMeshConfig = {}

WeaponMeshConfig.ByAnimPrefix = {
	Sword1H = "Sword1H",
	Sword = "Sword1H",
	Sword2H = "Sword2H",
	Axe1H = "Axe1H",
	Axe = "Axe1H",
	Axe2H = "Axe2H",
	Mace1H = "Mace1H",
	Mace = "Mace1H",
	Mace2H = "Mace2H",
	Dagger = "Dagger",
	Wand = "Wand",
	Scepter = "Scepter",
	Staff = "Staff",
	Bow = "Bow",
	Crossbow = "Crossbow",
}

WeaponMeshConfig.ByDefId = {
	o_kite = "Shield_Kite",
	o_buckler = "Shield_Round",
	o_tower = "Shield_Tower",
	o_round = "Shield_Round",
	o_spiked = "Shield_Round",
}

--[[
	Per-mesh visual tweaks (applied on attach).
	targetSize: scale so longest extent ≈ this many studs (preferred over raw scale)
	scale: fallback multiplier if targetSize missing
	forceTip / gripExtra / holdFrac / gripOffset: grip pipeline
]]
WeaponMeshConfig.Visual = {
	Sword1H = { targetSize = 3.4 },
	Sword2H = { targetSize = 4.6 },
	Axe1H = { targetSize = 3.6, gripExtra = CFrame.Angles(math.rad(90), 0, 0) },
	Axe2H = { targetSize = 4.8, gripExtra = CFrame.Angles(math.rad(90), 0, 0) },
	Mace1H = { targetSize = 3.5, gripExtra = CFrame.Angles(math.rad(90), 0, 0) },
	Mace2H = { targetSize = 4.6, gripExtra = CFrame.Angles(math.rad(90), 0, 0) },
	Dagger = { targetSize = 2.4 },
	Wand = { targetSize = 2.8, holdFrac = 0.4 },
	Scepter = { targetSize = 3.2, holdFrac = 0.4 },
	-- Staff mesh is tiny (~2); hold near mid-shaft, tip toward crystal (+X in handle space)
	Staff = {
		targetSize = 5.2,
		forceTip = Vector3.new(1, 0, 0),
		holdFrac = 0.38,
		gripOffset = CFrame.new(0, 0.05, 0),
	},
	Bow = {
		targetSize = 4.0, -- 5.5 reached the ground when arm hangs; keep readable but in-hand
		-- Limb long = handle +Y → world up; Y180 = string toward body
		gripOrient = CFrame.Angles(math.rad(90), math.rad(180), 0),
		centerOn = "limb",
		centerMode = "surface",
		nestle = 0.45,
	},
	-- Crossbow ~2.6 authored; stock along -Z
	Crossbow = {
		targetSize = 4.8,
		forceTip = Vector3.new(0, 0, -1),
		-- Sağa 90° (Y+)
		gripExtra = CFrame.Angles(0, math.rad(90), 0),
		holdFrac = 0.42,
		gripOffset = CFrame.new(0, 0.08, 0),
	},
}

WeaponMeshConfig.ShieldVisual = {
	-- straps/inside toward body, face outward (+Z of left grip)
	grip = CFrame.new(0, -0.08, 0.42) * CFrame.Angles(0, math.rad(-90), 0) * CFrame.Angles(math.rad(180), 0, 0),
	scale = 1.05,
}

WeaponMeshConfig.Alternates = {
	Shield = { "Shield_Kite", "Shield_Round", "Shield_Tower" },
}

function WeaponMeshConfig.ResolveName(animPrefix: string?, defId: string?): string?
	if defId then
		local byDef = WeaponMeshConfig.ByDefId[defId]
		if byDef then
			return byDef
		end
	end
	if animPrefix then
		return WeaponMeshConfig.ByAnimPrefix[animPrefix]
	end
	return nil
end

function WeaponMeshConfig.ResolveShield(defId: string?): string?
	if defId and WeaponMeshConfig.ByDefId[defId] then
		return WeaponMeshConfig.ByDefId[defId]
	end
	return "Shield_Kite"
end

function WeaponMeshConfig.GetVisual(animPrefix: string?): {
	scale: number?,
	targetSize: number?,
	gripExtra: CFrame?,
	gripOrient: CFrame?,
	holdFrac: number?,
	gripOffset: CFrame?,
	forceTip: Vector3?,
	centerOn: string?,
	centerMode: string?,
	nestle: number?,
}
	if not animPrefix then
		return {}
	end
	return WeaponMeshConfig.Visual[animPrefix] or WeaponMeshConfig.Visual[WeaponMeshConfig.ByAnimPrefix[animPrefix] or ""] or {}
end

function WeaponMeshConfig.GetFolder(): Folder?
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("WeaponMeshes")
	if folder and folder:IsA("Folder") then
		return folder
	end
	return nil
end

function WeaponMeshConfig.GetTemplate(animPrefix: string?, defId: string?): Model?
	local name = WeaponMeshConfig.ResolveName(animPrefix, defId)
	if not name then
		return nil
	end
	local folder = WeaponMeshConfig.GetFolder()
	if not folder then
		return nil
	end
	local template = folder:FindFirstChild(name)
	if template and template:IsA("Model") then
		return template
	end
	local prim = folder:FindFirstChild("_Primary")
	if prim then
		local sv = prim:FindFirstChild(animPrefix or "")
		if sv and sv:IsA("StringValue") then
			local t2 = folder:FindFirstChild(sv.Value)
			if t2 and t2:IsA("Model") then
				return t2
			end
		end
	end
	return nil
end

function WeaponMeshConfig.GetShieldTemplate(defId: string?): Model?
	local name = WeaponMeshConfig.ResolveShield(defId)
	local folder = WeaponMeshConfig.GetFolder()
	if not folder then
		return nil
	end
	local template = folder:FindFirstChild(name)
	if template and template:IsA("Model") then
		return template
	end
	return nil
end

return WeaponMeshConfig
