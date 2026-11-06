-- Не удивляйтесь что нашли опен сурс скрипта, мои проекты изночально были опен сурс а ключ система сделана для поддержки и мотивации, дабы скрипты почаще обновлялись и я о них не забывал(:

do
	local g = (getgenv and getgenv()) or _G
	local function unflyCheck()
		return true
	end
	g.__unfly_check = unflyCheck
	g.__unfly_ok = true
	g.__unfly_from_launcher = true
	g.__unfly_key = g.__unfly_key or "temp"
	g.__unfly_session = g.__unfly_session or os.time()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer

local ALLOWED_PLACES = {
	[14437001043] = true,
	[14896802601] = true,
	[16667550979] = true,
	[140260816701736] = true,
	[14908286297] = true,
	[124095328182831] = true,
}

if not ALLOWED_PLACES[game.PlaceId] then
	warn("[Unfly] PlaceId " .. tostring(game.PlaceId) .. " not in list — script still runs")
end

local MONSTER_NAMES = {
	"Mutant", "Larry", "Pest", "Stalker", "Mutated Worker", "Worker",
	"Spider", "Abomination", "Zombie", "Skeleton", "Undead",
	"Pumpkin", "Jerry", "Winterhorn", "Delusion",
	"GhostChild", "GhostChild2", "Pine", "LowPine", "Intruder", "WeirdDad", "Dad",
}
local SPECIAL_MONSTERS = { "Zombie", "Skeleton", "Pumpkin", "Winterhorn", "Delusion" }

local ITEM_KEYWORDS = {
	"key", "card", "battery", "medkit", "med", "heal", "item", "coin",
	"gem", "fuse", "valve", "tool", "weapon", "ammo", "food", "drink",
	"badge", "crowbar", "hammer", "wire", "fuel", "note",
	"paper", "book", "ticket", "code", "phone", "flashlight", "lantern",
	"bloxycola", "wrench", "betterflashlight",
}
local LOOTABLE_EXACT = {
	BloxyCola = true, Wrench = true, Battery = true, Medkit = true,
	Flashlight = true, BetterFlashlight = true, Key = true, Fuse = true,
}
local ITEM_BLACKLIST = {
	"wall", "floor", "ceil", "roof", "base", "ground", "grass", "dirt",
	"stone", "brick", "road", "path", "terrain", "platform", "ramp",
	"stair", "door", "window", "fence", "tree", "rock", "water",
	"spawn", "invisible", "border", "boundary", "collider", "hitbox",
	"part", "block", "wedge", "corner", "beam", "pillar", "column",
	"cliff", "sand", "snow", "wood", "metal", "glass", "decal", "sign",
	"wires", "fusebox",
}

local HOUSE_POS = Vector3.new(-34.18, 9.54, -47.09)
local SECOND_FLOOR_POS = Vector3.new(-3.90, 25.29, -71.19)
local OXYGEN_GEN_POS = Vector3.new(-79.69, 6.29, -127.54)
local POWER_BOX_POS = Vector3.new(-2.42, 6.20, -92.56)

local State = {
	InfStamina = false,
	InfBreath = false,
	InfCold = false,
	Noclip = false,
	InfJump = false,
	Speed = false,
	SpeedValue = 22,
	JumpPower = false,
	JumpValue = 50,
	Fly = false,
	FlySpeed = 80,
	ESPMonsters = false,
	ESPItems = false,
	ESPPlayers = false,
	ChinaHat = false,
	Aura = false,
	FOV = false,
	FOVValue = 70,
	FreeCam = false,
	FreeCamSpeed = 60,
	Fullbright = false,
	LocalLight = false,
	LightBright = 2,
	SafeMode = true,
	WireHelper = false,
	GenMonitor = false,
	InfBattery = false,
}


local function getChar()
	return LP.Character
end

local function getHum()
	local c = getChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRoot(char)
	char = char or getChar()
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart")
end

local function nameHas(name, list)
	name = string.lower(tostring(name or ""))
	for _, w in ipairs(list) do
		if string.find(name, string.lower(w), 1, true) then
			return true
		end
	end
	return false
end

local function isPlayerModel(model)
	return Players:GetPlayerFromCharacter(model) ~= nil
end

local function isMonster(model)
	if not model or not model:IsA("Model") then return false end
	if isPlayerModel(model) then return false end
	local deathHitbox = model:FindFirstChild("DeathHitbox")
	if deathHitbox then
		return nameHas(model.Name, MONSTER_NAMES) or true
	end
	return nameHas(model.Name, MONSTER_NAMES)
end

local function isSpecialMonster(name)
	return nameHas(name, SPECIAL_MONSTERS)
end

local function hasClickDetector(obj)
	if obj:FindFirstChildOfClass("ClickDetector") then return true end
	for _, d in ipairs(obj:GetDescendants()) do
		if d:IsA("ClickDetector") then return true end
	end
	return false
end

local function isItem(obj)
	if not (obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Tool")) then return false end
	if obj:IsA("Model") then
		if isPlayerModel(obj) then return false end
		if obj:FindFirstChildOfClass("Humanoid") then return false end
	end
	local name = obj.Name or ""
	if LOOTABLE_EXACT[name] then return true end
	if nameHas(name, ITEM_BLACKLIST) then return false end
	if nameHas(name, ITEM_KEYWORDS) then return true end
	local parent = obj.Parent
	if parent and parent.Parent and parent.Parent.Name == "ItemSpots" then
		if not nameHas(name, ITEM_BLACKLIST) then return true end
	end
	if hasClickDetector(obj) and not nameHas(name, ITEM_BLACKLIST) then return true end
	return false
end

local STAMINA_NAMES = { "stamina", "stam", "energy" }
local OXYGEN_NAMES = { "oxygen", "air", "breath", "o2" }
local FREEZE_NAMES = { "freeze", "freezing", "frozen", "temperature", "temp", "cold", "frost", "chill", "warmth" }

local function findValuesByNames(names)
	local out = {}
	local char = getChar()
	local function scan(root)
		if not root then return end
		for _, v in ipairs(root:GetDescendants()) do
			if v:IsA("ValueBase") and nameHas(v.Name, names) then
				out[#out + 1] = v
			end
		end
	end
	scan(char)
	scan(LP)
	local stats = LP:FindFirstChild("leaderstats")
	if stats then scan(stats) end
	return out
end

local function setAttrsByNames(names, value)
	for _, obj in ipairs({ getChar(), LP }) do
		if obj then
			for attrName, current in pairs(obj:GetAttributes()) do
				if nameHas(attrName, names) and typeof(current) == "number" then
					pcall(function() obj:SetAttribute(attrName, value) end)
				end
			end
		end
	end
end

local noclipConn = nil
local function setNoclip(on)
	State.Noclip = on == true
	if noclipConn then
		noclipConn:Disconnect()
		noclipConn = nil
	end
	if not State.Noclip then return end
	noclipConn = RunService.Stepped:Connect(function()
		local c = getChar()
		if not c then return end
		for _, part in ipairs(c:GetDescendants()) do
			if part:IsA("BasePart") then
				pcall(function() part.CanCollide = false end)
			end
		end
	end)
end

local fullbrightOriginal = nil
local function applyFullbright(on)
	State.Fullbright = on == true
	if State.Fullbright then
		if not fullbrightOriginal then
			fullbrightOriginal = {
				Brightness = Lighting.Brightness,
				Ambient = Lighting.Ambient,
				ColorShift_Bottom = Lighting.ColorShift_Bottom,
				ColorShift_Top = Lighting.ColorShift_Top,
				FogEnd = Lighting.FogEnd,
				OutdoorAmbient = Lighting.OutdoorAmbient,
			}
		end
		Lighting.Brightness = 2
		Lighting.Ambient = Color3.new(1, 1, 1)
		Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
		Lighting.ColorShift_Top = Color3.new(1, 1, 1)
		Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
		Lighting.FogEnd = 1e5
	else
		if fullbrightOriginal then
			for k, v in pairs(fullbrightOriginal) do
				pcall(function() Lighting[k] = v end)
			end
		end
	end
end

local defaultFOV = 70
pcall(function()
	if Workspace.CurrentCamera then defaultFOV = Workspace.CurrentCamera.FieldOfView end
end)

local function applyFOV()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	pcall(function()
		cam.FieldOfView = State.FOV and State.FOVValue or defaultFOV
	end)
end

local ChinaHatColor = Color3.fromRGB(255, 105, 180)
local ChinaHatScale = Vector3.new(1.7, 1.1, 1.7)
local chinaHatPart, chinaHatConn

local function destroyChinaHat()
	if chinaHatConn then pcall(function() chinaHatConn:Disconnect() end) chinaHatConn = nil end
	if chinaHatPart then pcall(function() chinaHatPart:Destroy() end) chinaHatPart = nil end
	local c = getChar()
	if not c then return end
	for _, ch in ipairs(c:GetChildren()) do
		if ch.Name == "HubChinaHat" then pcall(function() ch:Destroy() end) end
	end
end

local function createChinaHat(character)
	destroyChinaHat()
	if not State.ChinaHat or not character then return end
	local head = character:FindFirstChild("Head")
	if not head then return end
	local Cone = Instance.new("Part")
	Cone.Name = "HubChinaHat"
	Cone.Anchored = false
	Cone.CanCollide = false
	Cone.CanQuery = false
	Cone.CanTouch = false
	Cone.Massless = true
	Cone.Material = Enum.Material.Neon
	Cone.Color = ChinaHatColor
	Cone.Size = Vector3.new(1, 1, 1)
	Cone.Parent = character
	local Mesh = Instance.new("SpecialMesh")
	Mesh.MeshType = Enum.MeshType.FileMesh
	Mesh.MeshId = "rbxassetid://1778999"
	Mesh.Scale = ChinaHatScale
	Mesh.Parent = Cone
	local Light = Instance.new("PointLight")
	Light.Name = "HatLight"
	Light.Brightness = 1.2
	Light.Range = 8
	Light.Color = ChinaHatColor
	Light.Parent = Cone
	local Weld = Instance.new("Weld")
	Weld.Part0 = head
	Weld.Part1 = Cone
	Weld.C0 = CFrame.new(0, 0.9, 0) * CFrame.Angles(0, 0, math.rad(180))
	Weld.Parent = Cone
	chinaHatPart = Cone
end

local auraHL = nil
local function setAura(on)
	State.Aura = on == true
	if auraHL then pcall(function() auraHL:Destroy() end) auraHL = nil end
	if not State.Aura then return end
	local c = getChar()
	if not c then return end
	auraHL = Instance.new("Highlight")
	auraHL.Name = "UnflyAura"
	auraHL.FillTransparency = 0.7
	auraHL.OutlineTransparency = 0
	auraHL.FillColor = Color3.fromRGB(180, 120, 255)
	auraHL.OutlineColor = Color3.fromRGB(220, 180, 255)
	auraHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	auraHL.Adornee = c
	auraHL.Parent = c
end

local function tpTo(pos)
	local root = getRoot()
	if not root or not pos then return end
	pcall(function()
		root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
	end)
end

local espFolder = nil
local function ensureEspFolder()
	if espFolder and espFolder.Parent then return espFolder end
	espFolder = Instance.new("Folder")
	espFolder.Name = "UnflyResidenceESP"
	pcall(function()
		espFolder.Parent = game:GetService("CoreGui")
	end)
	if not espFolder.Parent then
		espFolder.Parent = LP:WaitForChild("PlayerGui")
	end
	return espFolder
end

local monsterHL, itemHL, playerHL = {}, {}, {}
local monsterLB, itemLB, playerLB = {}, {}, {}

local function clearMap(map)
	for k, v in pairs(map) do
		pcall(function() v:Destroy() end)
		map[k] = nil
	end
end

local function clearAllESP()
	clearMap(monsterHL) clearMap(monsterLB)
	clearMap(itemHL) clearMap(itemLB)
	clearMap(playerHL) clearMap(playerLB)
end

local function addHL(map, model, color, fillT)
	if map[model] then return end
	local h = Instance.new("Highlight")
	h.FillTransparency = fillT or 0.4
	h.OutlineTransparency = 0.2
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.FillColor = color
	h.OutlineColor = Color3.new(1, 1, 1)
	h.Adornee = model
	h.Parent = ensureEspFolder()
	map[model] = h
end

local function addLabel(map, model, text, color)
	if map[model] then return end
	local anchor = model:IsA("Model") and (model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart", true)) or model
	if not anchor or not anchor:IsA("BasePart") then return end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 180, 0, 36)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 500
	bb.Adornee = anchor
	bb.Parent = ensureEspFolder()
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.TextColor3 = color
	tl.TextStrokeTransparency = 0.3
	tl.Font = Enum.Font.GothamBold
	tl.TextScaled = true
	tl.Text = text
	tl.Parent = bb
	map[model] = bb
end

local function refreshMonsterESP()
	if not State.ESPMonsters then
		clearMap(monsterHL) clearMap(monsterLB)
		return
	end
	local seen = {}
	for _, model in ipairs(Workspace:GetDescendants()) do
		if model:IsA("Model") and isMonster(model) then
			seen[model] = true
			local col = isSpecialMonster(model.Name) and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 50, 50)
			addHL(monsterHL, model, col, 0.4)
			addLabel(monsterLB, model, model.Name, col)
		end
	end
	for m in pairs(monsterHL) do
		if not seen[m] or not m.Parent then
			pcall(function() monsterHL[m]:Destroy() end)
			monsterHL[m] = nil
			if monsterLB[m] then pcall(function() monsterLB[m]:Destroy() end) monsterLB[m] = nil end
		end
	end
end

local function refreshItemESP()
	if not State.ESPItems then
		clearMap(itemHL) clearMap(itemLB)
		return
	end
	local col = Color3.fromRGB(160, 80, 255)
	local seen = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if isItem(obj) then
			seen[obj] = true
			addHL(itemHL, obj, col, 0.45)
			addLabel(itemLB, obj, obj.Name, col)
		end
	end
	for m in pairs(itemHL) do
		if not seen[m] or not m.Parent then
			pcall(function() itemHL[m]:Destroy() end)
			itemHL[m] = nil
			if itemLB[m] then pcall(function() itemLB[m]:Destroy() end) itemLB[m] = nil end
		end
	end
end

local function refreshPlayerESP()
	if not State.ESPPlayers then
		clearMap(playerHL) clearMap(playerLB)
		return
	end
	local col = Color3.fromRGB(80, 180, 255)
	local seen = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP and plr.Character then
			local c = plr.Character
			seen[c] = true
			addHL(playerHL, c, col, 0.5)
			addLabel(playerLB, c, plr.DisplayName or plr.Name, col)
		end
	end
	for m in pairs(playerHL) do
		if not seen[m] or not m.Parent then
			pcall(function() playerHL[m]:Destroy() end)
			playerHL[m] = nil
			if playerLB[m] then pcall(function() playerLB[m]:Destroy() end) playerLB[m] = nil end
		end
	end
end

local flyBV = nil
local function flyStep(dt)
	if not State.Fly then return end
	local root = getRoot()
	local hum = getHum()
	if not root or not hum then return end
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local dir = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
	if dir.Magnitude > 0 then
		dir = dir.Unit * State.FlySpeed
	end
	pcall(function()
		hum.PlatformStand = true
		root.AssemblyLinearVelocity = dir
	end)
end

local freecamSaved = nil
local function stopFreeCam()
	State.FreeCam = false
	local cam = Workspace.CurrentCamera
	if freecamSaved and cam then
		pcall(function()
			cam.CameraType = freecamSaved.Type
			cam.CameraSubject = freecamSaved.Subject
			cam.FieldOfView = freecamSaved.FOV
		end)
	end
	freecamSaved = nil
end

local function startFreeCam()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	freecamSaved = {
		Type = cam.CameraType,
		Subject = cam.CameraSubject,
		FOV = cam.FieldOfView,
		Pos = cam.CFrame,
	}
	State.FreeCam = true
	cam.CameraType = Enum.CameraType.Scriptable
end

local infJumpConn = nil
local function setInfJump(on)
	State.InfJump = on == true
	if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
	if not State.InfJump then return end
	infJumpConn = UserInputService.JumpRequest:Connect(function()
		local hum = getHum()
		if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
	end)
end

local localLightPart = nil
local function setLocalLight(on)
	State.LocalLight = on == true
	if localLightPart then pcall(function() localLightPart:Destroy() end) localLightPart = nil end
	if not State.LocalLight then return end
	local root = getRoot()
	if not root then return end
	local p = Instance.new("Part")
	p.Name = "UnflyLocalLight"
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.Parent = Workspace
	local l = Instance.new("PointLight")
	l.Brightness = State.LightBright
	l.Range = 40
	l.Parent = p
	localLightPart = p
end


local function setupWireHelper()
	local fuseBox = Workspace:FindFirstChild("FuseBox")
	if not fuseBox then return end
	local wires = fuseBox:FindFirstChild("Wires")
	if not wires then return end
	local function onWire(wire)
		if not wire:IsA("BasePart") then return end
		local sparkles = wire:FindFirstChild("Sparkles")
		local function update()
			if not State.WireHelper then return end
			local enabled = sparkles and sparkles:IsA("Sparkles") and sparkles.Enabled
			pcall(function()
				wire.LocalTransparencyModifier = enabled and 0 or 1
			end)
			local cd = wire:FindFirstChildWhichIsA("ClickDetector")
			if cd then
				pcall(function()
					cd.MaxActivationDistance = enabled and 50 or 8
				end)
			end
			if enabled then
				if not wire:FindFirstChild("UnflyWireHL") then
					local h = Instance.new("Highlight")
					h.Name = "UnflyWireHL"
					h.FillColor = Color3.fromRGB(255, 200, 50)
					h.OutlineColor = Color3.fromRGB(255, 255, 100)
					h.FillTransparency = 0.5
					h.Adornee = wire
					h.Parent = wire
				end
			else
				local h = wire:FindFirstChild("UnflyWireHL")
				if h then h:Destroy() end
			end
		end
		if sparkles then
			sparkles:GetPropertyChangedSignal("Enabled"):Connect(update)
		end
		update()
	end
	for _, w in ipairs(wires:GetChildren()) do
		task.defer(onWire, w)
	end
	wires.ChildAdded:Connect(function(c) task.defer(onWire, c) end)
end

local genFuelValue = nil
local fuseStateValue = nil
local function bindGenerator()
	pcall(function()
		local shack = Workspace:FindFirstChild("Shack")
		local gen = shack and shack:FindFirstChild("Generator")
		genFuelValue = gen and gen:FindFirstChild("Fuel")
	end)
	pcall(function()
		local gs = game:GetService("ReplicatedStorage"):FindFirstChild("GameState")
		fuseStateValue = gs and gs:FindFirstChild("FusesFried")
	end)
end
bindGenerator()

local function batteryLoop()
	if not State.InfBattery then return end
	local char = getChar()
	local function fill(container)
		if not container then return end
		for _, t in ipairs(container:GetChildren()) do
			if t:IsA("Tool") or t:IsA("Model") then
				if nameHas(t.Name, {"flash", "battery", "light"}) or LOOTABLE_EXACT[t.Name] then
					for _, v in ipairs(t:GetDescendants()) do
						if v:IsA("NumberValue") or v:IsA("IntValue") then
							local n = string.lower(v.Name)
							if n:find("batt") or n:find("charge") or n:find("power") or n:find("fuel") or n == "value" then
								pcall(function() v.Value = math.max(v.Value, 100) end)
							end
						end
					end
					for attr, cur in pairs(t:GetAttributes()) do
						if typeof(cur) == "number" and nameHas(attr, {"batt", "charge", "power"}) then
							pcall(function() t:SetAttribute(attr, 100) end)
						end
					end
				end
			end
		end
	end
	fill(char)
	fill(LP:FindFirstChild("Backpack"))
end

task.defer(function()
	pcall(setupWireHelper)
end)

RunService.RenderStepped:Connect(function(dt)
	local c = getChar()
	local hum = getHum()

	if State.InfStamina then
		for _, v in ipairs(findValuesByNames(STAMINA_NAMES)) do
			pcall(function() v.Value = 100 end)
		end
		setAttrsByNames(STAMINA_NAMES, 100)
	end
	if State.InfBreath then
		for _, v in ipairs(findValuesByNames(OXYGEN_NAMES)) do
			pcall(function() v.Value = 100 end)
		end
		setAttrsByNames(OXYGEN_NAMES, 100)
	end
	if State.InfCold then
		for _, v in ipairs(findValuesByNames(FREEZE_NAMES)) do
			pcall(function() v.Value = 0 end)
		end
		setAttrsByNames(FREEZE_NAMES, 0)
	end
	if State.InfBattery then
		batteryLoop()
	end

	if State.Speed and hum then
		pcall(function() hum.WalkSpeed = State.SpeedValue end)
	end
	if State.JumpPower and hum then
		pcall(function()
			hum.UseJumpPower = true
			hum.JumpPower = State.JumpValue
		end)
	end

	if State.FOV and not State.FreeCam then applyFOV() end
	if State.Fullbright then
		if tick() % 2 < 0.05 then applyFullbright(true) end
	end
	if State.Fly then flyStep(dt) end
	if State.FreeCam then
		local cam = Workspace.CurrentCamera
		if cam then
			local move = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.E) then move = move + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move = move - Vector3.new(0, 1, 0) end
			if move.Magnitude > 0 then
				cam.CFrame = cam.CFrame + move.Unit * State.FreeCamSpeed * dt
			end
			if State.FOV then cam.FieldOfView = State.FOVValue end
		end
	end
	if State.LocalLight and localLightPart then
		local root = getRoot()
		if root then
			localLightPart.CFrame = root.CFrame
			local pl = localLightPart:FindFirstChildOfClass("PointLight")
			if pl then pl.Brightness = State.LightBright end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1.1)
		pcall(refreshMonsterESP)
		pcall(refreshItemESP)
		pcall(refreshPlayerESP)
	end
end)

Workspace.DescendantAdded:Connect(function(obj)
	task.defer(function()
		if State.ESPMonsters and obj:IsA("Model") and isMonster(obj) then
			refreshMonsterESP()
		end
		if State.ESPItems and isItem(obj) then
			refreshItemESP()
		end
	end)
end)

LP.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	destroyChinaHat()
	if auraHL then pcall(function() auraHL:Destroy() end) auraHL = nil end
	if State.Fly then
		State.Fly = false
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then pcall(function() hum.PlatformStand = false end) end
	end
	if State.FreeCam then stopFreeCam() end
	if State.ChinaHat then createChinaHat(char) end
	if State.Aura then setAura(true) end
	if State.InfJump then setInfJump(true) end
	if State.Noclip then setNoclip(true) end
	if State.LocalLight then setLocalLight(true) end
end)

local UI_URL = "https://raw.githubusercontent.com/RyzenEngineRb/QnAmeAplKnanKsbWRgs/refs/heads/main/UiLib.lua"
local function fetchUiLib()
	local ok, src = pcall(function()
		return game:HttpGet(UI_URL)
	end)
	if ok and type(src) == "string" and #src > 500 then
		return src
	end
	error("UnflyUi download failed")
end

local okLib, Library = pcall(function()
	return loadstring(fetchUiLib())()
end)
if not okLib or type(Library) ~= "table" or type(Library.CreateWindow) ~= "function" then
	warn("[Unfly] UiLib load failed: " .. tostring(Library))
	return
end

local Window = Library:CreateWindow({
	Name = "Unfly",
	Tagline = "Residence · v7",
	Role = "User",
	Telegram = "https://t.me/KvantTon",
	ToggleKey = Enum.KeyCode.RightShift,
	DraggableButton = true,
	RememberSettings = true,
	Accent = Color3.fromRGB(70, 150, 255),
	Neon = Color3.fromRGB(100, 180, 255),
})

local PlayerTab = Window:Tab("Player", "person")
local VisualTab = Window:Tab("Visual", "eye")
local TpTab = Window:Tab("Teleport", "pin")
local DebugTab = Window:Tab("Debug", "code")

PlayerTab:AddBanner({ Title = "Welcome to", Highlight = "Unfly", Subtitle = "Residence · Survival + ESP" })

local secS = PlayerTab:Section("Survival", "left", "shield")
local secP = PlayerTab:Section("Movement", "right", "bolt")

secS:Toggle("Infinite Stamina", false, function(v) State.InfStamina = v == true end)
secS:Toggle("Infinite Oxygen", false, function(v) State.InfBreath = v == true end)
secS:Toggle("Anti Freeze / Cold", false, function(v) State.InfCold = v == true end)
secS:Toggle("Inf Flashlight Battery", false, function(v) State.InfBattery = v == true end)
secS:Toggle("Wire Helper", false, function(v)
	State.WireHelper = v == true
	pcall(setupWireHelper)
end)
secS:Button("Generator Status", function()
	bindGenerator()
	local fuel = genFuelValue and tostring(genFuelValue.Value) or "?"
	local power = "?"
	if fuseStateValue then
		power = fuseStateValue.Value and "FUSES FRIED" or "OK"
	end
	Library:Notify({
		Title = "Generator",
		Content = "Fuel: " .. fuel .. " | Power: " .. power,
		Duration = 5,
	})
end)
secS:Button("Scan Cold Values", function()
	local list = findValuesByNames(FREEZE_NAMES)
	local names = {}
	for _, v in ipairs(list) do
		names[#names + 1] = v:GetFullName() .. " = " .. tostring(v.Value)
	end
	Library:Notify({
		Title = "Cold Protect",
		Content = (#names > 0) and table.concat(names, "\n") or "No cold/temp values found",
		Duration = 5,
	})
end)

secP:Toggle("Noclip", false, function(v) setNoclip(v) end)
secP:Toggle("Infinite Jump", false, function(v) setInfJump(v) end)
secP:Toggle("WalkSpeed", false, function(v) State.Speed = v == true end)
secP:Slider("Speed Value", 16, 80, 22, function(v) State.SpeedValue = tonumber(v) or 22 end)
secP:Toggle("JumpPower", false, function(v) State.JumpPower = v == true end)
secP:Slider("Jump Value", 50, 120, 50, function(v) State.JumpValue = tonumber(v) or 50 end)
secP:Toggle("Fly", false, function(v)
	State.Fly = v == true
	local hum = getHum()
	if not State.Fly and hum then pcall(function() hum.PlatformStand = false end) end
end)
secP:Slider("Fly Speed", 20, 150, 80, function(v) State.FlySpeed = tonumber(v) or 80 end)

local secV = VisualTab:Section("ESP", "left", "eye")
local secC = VisualTab:Section("Camera / Light", "right", "gear")
local secH = VisualTab:Section("Cosmetics", "left", "star")

secV:Toggle("Monster ESP", false, function(v)
	State.ESPMonsters = v == true
	if not State.ESPMonsters then clearMap(monsterHL) clearMap(monsterLB) else refreshMonsterESP() end
end)
secV:Toggle("Item ESP", false, function(v)
	State.ESPItems = v == true
	if not State.ESPItems then clearMap(itemHL) clearMap(itemLB) else refreshItemESP() end
end)
secV:Toggle("Player ESP", false, function(v)
	State.ESPPlayers = v == true
	if not State.ESPPlayers then clearMap(playerHL) clearMap(playerLB) else refreshPlayerESP() end
end)

secC:Toggle("Fullbright", false, function(v) applyFullbright(v) end)
secC:Toggle("Custom FOV", false, function(v)
	State.FOV = v == true
	if not State.FOV then
		local cam = Workspace.CurrentCamera
		if cam then cam.FieldOfView = defaultFOV end
	else
		applyFOV()
	end
end)
secC:Slider("FOV Value", 30, 120, 70, function(v)
	State.FOVValue = tonumber(v) or 70
	if State.FOV then applyFOV() end
end)
secC:Toggle("FreeCam", false, function(v)
	if v then startFreeCam() else stopFreeCam() end
end)
secC:Slider("FreeCam Speed", 20, 150, 60, function(v) State.FreeCamSpeed = tonumber(v) or 60 end)
secC:Toggle("Local Light", false, function(v) setLocalLight(v) end)
secC:Slider("Light Brightness", 1, 8, 2, function(v) State.LightBright = tonumber(v) or 2 end)

secH:Toggle("China Hat", false, function(v)
	State.ChinaHat = v == true
	if State.ChinaHat then createChinaHat(getChar()) else destroyChinaHat() end
end)
secH:Color("Hat Color", ChinaHatColor, function(c)
	if typeof(c) == "Color3" then ChinaHatColor = c end
	if State.ChinaHat then createChinaHat(getChar()) end
end)
secH:Toggle("Aura", false, function(v) setAura(v) end)

local secTp = TpTab:Section("Locations", "left", "pin")
secTp:Button("House Floor 1", function() tpTo(HOUSE_POS) end)
secTp:Button("House Floor 2", function() tpTo(SECOND_FLOOR_POS) end)
secTp:Button("Oxygen Generator", function() tpTo(OXYGEN_GEN_POS) end)
secTp:Button("Power / Fix Box", function() tpTo(POWER_BOX_POS) end)

local secD = DebugTab:Section("Info", "left", "code")
secD:Button("Print PlaceId", function()
	Library:Notify({ Title = "PlaceId", Content = tostring(game.PlaceId), Duration = 4 })
end)
secD:Button("Clear All ESP", function()
	clearAllESP()
	Library:Notify({ Title = "ESP", Content = "Cleared", Duration = 2 })
end)

pcall(function()
	if Window.Ready then Window:Ready() end
end)

Library:Notify({ Title = "Unfly", Content = "Residence v7 loaded", Duration = 3 })
print("[Unfly] Residence PlaceId=" .. tostring(game.PlaceId) .. " — RightShift")
