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

local function isAllowedPlace()
	return ALLOWED_PLACES[game.PlaceId] == true
end

if not isAllowedPlace() then
	warn("[ResidenceHorror] PlaceId " .. tostring(game.PlaceId) .. " not in list — script still runs")
end

local MUTANT_NAMES = {
	"GhostChild", "GhostChild2", "Pine", "LowPine", "Intruder",
	"WeirdDad", "Winterhorn", "Mutant", "Dad",
}

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
	ESP = false,
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
}

local function getChar()
	return LP.Character
end

local function getHum()
	local c = getChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function findVal(path)
	local c = getChar()
	if not c then return end
	local cur = c
	for _, part in ipairs(path) do
		cur = cur:FindFirstChild(part)
		if not cur then return end
	end
	if cur:IsA("NumberValue") or cur:IsA("IntValue") then
		return cur
	end
	return nil
end

local function isPlayerChar(m)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character == m then return true end
	end
	return false
end

local function isMutant(name)
pcall(function() local g=(getgenv and getgenv() or _G) if g.__unfly_check then g.__unfly_check() end end)
	local n = string.lower(tostring(name or ""))
	for _, mn in ipairs(MUTANT_NAMES) do
		if string.find(n, string.lower(mn), 1, true) then return true end
	end
	return false
end

local COLD_KEYS = { "cold", "temp", "temperature", "freeze", "warmth", "heat", "frost", "chill" }
local COLD_PATHS = {
	{ "Cold" },
	{ "Temperature" },
	{ "Temp" },
	{ "Warmth" },
	{ "Freeze" },
	{ "Stats", "Cold" },
	{ "Stats", "Temperature" },
	{ "Status", "Cold" },
	{ "Status", "Temperature" },
	{ "Values", "Cold" },
	{ "Values", "Temperature" },
	{ "Survival", "Cold" },
	{ "Survival", "Temperature" },
}

local function findColdValues()
	local found = {}
	for _, path in ipairs(COLD_PATHS) do
		local v = findVal(path)
		if v then found[#found + 1] = v end
	end
	local c = getChar()
	if not c then return found end
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("NumberValue") or d:IsA("IntValue") then
			local n = string.lower(d.Name)
			for _, k in ipairs(COLD_KEYS) do
				if string.find(n, k, 1, true) then
					local already = false
					for _, x in ipairs(found) do
						if x == d then already = true break end
					end
					if not already then found[#found + 1] = d end
					break
				end
			end
		end
	end
	return found
end

local function protectCold()
	for _, v in ipairs(findColdValues()) do
		pcall(function()
			local n = string.lower(v.Name)
			if string.find(n, "cold", 1, true) or string.find(n, "freeze", 1, true) or string.find(n, "frost", 1, true) or string.find(n, "chill", 1, true) then
				if v.Value > 0 then v.Value = 0 end
			elseif string.find(n, "warm", 1, true) then
				if v.Value < 100 then v.Value = 100 end
			else
				if v.Value < 50 then
					v.Value = math.max(v.Value, 70)
				elseif v.Value > 80 and v.Value < 200 then
					v.Value = math.min(v.Value, 20)
				end
			end
		end)
	end
end

local patchedRemotes = {}

local function scanAntiCheatRemotes()
	local n = 0
	for _, obj in ipairs(game:GetDescendants()) do
		if obj:IsA("RemoteEvent") then
			n = n + 1
		end
	end
	return n
end

local function safeHost()
	local ok2, r = pcall(function()
		if gethui then return gethui() end
		return game:GetService("CoreGui")
	end)
	return (ok2 and r) or LP:WaitForChild("PlayerGui")
end

local ROOT_FOLDER = nil
local function ensureRoot()
	if ROOT_FOLDER and ROOT_FOLDER.Parent then return ROOT_FOLDER end
	local host = safeHost()
	local old = host:FindFirstChild("_hm")
	if old then old:Destroy() end
	ROOT_FOLDER = Instance.new("Folder")
	ROOT_FOLDER.Name = "_hm"
	ROOT_FOLDER.Parent = host
	return ROOT_FOLDER
end
pcall(function() local g=(getgenv and getgenv() or _G) if g.__unfly_check then g.__unfly_check() end end)

local espFolder, espMap = nil, {}

local function getEspFolder()
	if espFolder and espFolder.Parent then return espFolder end
	local root = ensureRoot()
	local old = root:FindFirstChild("esp")
	if old then old:Destroy() end
	local f = Instance.new("Folder")
	f.Name = "esp"
	f.Parent = root
	espFolder = f
	return f
end

local function clearESP()
	for _, d in pairs(espMap) do
		pcall(function() if d.hl then d.hl:Destroy() end end)
		pcall(function() if d.sg then d.sg:Destroy() end end)
	end
	espMap = {}
	if espFolder then pcall(function() espFolder:ClearAllChildren() end) end
end

local function addESP(model)
	if espMap[model] or not model or not model.Parent then return end
	local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
	if not head then return end
	local cont = getEspFolder()

	local hl = Instance.new("Highlight")
	hl.Adornee = model
	hl.FillColor = Color3.fromRGB(255, 40, 40)
	hl.OutlineColor = Color3.fromRGB(255, 120, 120)
	hl.FillTransparency = 0.55
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = cont

	local sg = Instance.new("ScreenGui")
	sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false
	sg.Name = "e"
	sg.Parent = cont

	local bb = Instance.new("BillboardGui")
	bb.Adornee = head
	bb.Size = UDim2.fromOffset(130, 40)
	bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.AlwaysOnTop = true
	bb.Parent = sg

	local bg = Instance.new("Frame", bb)
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(24, 0, 0)
	bg.BackgroundTransparency = 0.45
	bg.BorderSizePixel = 0
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 5)

	local lbl = Instance.new("TextLabel", bb)
	lbl.Size = UDim2.new(1, 0, 0.6, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = model.Name
	lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
	lbl.TextStrokeTransparency = 0.3
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 12

	local dlbl = Instance.new("TextLabel", bb)
	dlbl.Size = UDim2.new(1, 0, 0.4, 0)
	dlbl.Position = UDim2.fromScale(0, 0.6)
	dlbl.BackgroundTransparency = 1
	dlbl.TextColor3 = Color3.fromRGB(255, 200, 200)
	dlbl.Font = Enum.Font.Gotham
	dlbl.TextSize = 10

	espMap[model] = { hl = hl, sg = sg, dlbl = dlbl }
end

local function refreshESP()
	if not State.ESP then clearESP() return end
	getEspFolder()
	local c = getChar()
	local myHRP = c and c:FindFirstChild("HumanoidRootPart")
	local seen = {}
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("Model") and not isPlayerChar(d) and isMutant(d.Name) then
			if d:FindFirstChildOfClass("Humanoid") then
				seen[d] = true
				addESP(d)
				local data = espMap[d]
				if data and data.dlbl and myHRP then
					local hrp = d:FindFirstChild("HumanoidRootPart")
					if hrp then
						data.dlbl.Text = math.floor((myHRP.Position - hrp.Position).Magnitude) .. " studs"
					end
				end
			end
		end
	end
	for model, data in pairs(espMap) do
		if not seen[model] or not model.Parent then
			pcall(function() if data.hl then data.hl:Destroy() end end)
			pcall(function() if data.sg then data.sg:Destroy() end end)
			espMap[model] = nil
		end
	end
end

local auraHL = nil
local function setAura(on)
	State.Aura = on
	if auraHL then pcall(function() auraHL:Destroy() end) auraHL = nil end
	if not on then return end
	local c = getChar()
	if not c then return end
	local hl = Instance.new("Highlight")
	hl.Adornee = c
	hl.FillColor = Color3.fromRGB(80, 180, 255)
	hl.OutlineColor = Color3.fromRGB(180, 230, 255)
	hl.FillTransparency = 0.65
	hl.OutlineTransparency = 0.1
	hl.Parent = ensureRoot()
	auraHL = hl
end

local chinaHatPart = nil
local chinaHatConn = nil
local ChinaHatColor = Color3.fromRGB(255, 105, 180)
local ChinaHatScale = Vector3.new(1.7, 1.1, 1.7)
local CHINA_HAT_MESH = "rbxassetid://1033714"

local function hatHost()
	local folder = Workspace:FindFirstChild("_rh_fx")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "_rh_fx"
		folder.Parent = Workspace
	end
	return folder
end

local function destroyChinaHat()
	if chinaHatConn then
		pcall(function() chinaHatConn:Disconnect() end)
		chinaHatConn = nil
	end
	pcall(function() local g=(getgenv and getgenv() or _G) if g.__unfly_check then g.__unfly_check() end end)
	if chinaHatPart then
		pcall(function() chinaHatPart:Destroy() end)
		chinaHatPart = nil
	end
	local host = Workspace:FindFirstChild("_rh_fx")
	if host then
		for _, ch in ipairs(host:GetChildren()) do
			if ch.Name == "HubChinaHat" then
				pcall(function() ch:Destroy() end)
			end
		end
	end
end

local function createChinaHat(character)
	destroyChinaHat()
	if not State.ChinaHat then return end
	character = character or getChar()
	if not character then return end
	local head = character:FindFirstChild("Head")
	if not head then return end

	local Cone = Instance.new("Part")
	Cone.Name = "HubChinaHat"
	Cone.Size = Vector3.new(1, 1, 1)
	Cone.Material = Enum.Material.Neon
	Cone.Transparency = 0.2
	Cone.Anchored = true
	Cone.CanCollide = false
	Cone.CanQuery = false
	Cone.CanTouch = false
	Cone.Massless = true
	Cone.CastShadow = false
	Cone.Color = ChinaHatColor

	local Mesh = Instance.new("SpecialMesh")
	Mesh.MeshType = Enum.MeshType.FileMesh
	Mesh.MeshId = CHINA_HAT_MESH
	Mesh.Scale = ChinaHatScale
	Mesh.Parent = Cone

	local Light = Instance.new("PointLight")
	Light.Color = ChinaHatColor
	Light.Brightness = 1.2
	Light.Range = 8
	Light.Parent = Cone

	Cone.Parent = hatHost()
	chinaHatPart = Cone

	chinaHatConn = RunService.RenderStepped:Connect(function()
		if not State.ChinaHat or not chinaHatPart or not chinaHatPart.Parent then return end
		local c = getChar()
		local h = c and c:FindFirstChild("Head")
		if not h then
			chinaHatPart.Parent = nil
			return
		end
		if not chinaHatPart.Parent then
			chinaHatPart.Parent = hatHost()
		end
		pcall(function()
			chinaHatPart.CFrame = h.CFrame * CFrame.new(0, 0.9, 0)
		end)
	end)
end

local defaultFOV = 70
pcall(function()
	if Workspace.CurrentCamera then defaultFOV = Workspace.CurrentCamera.FieldOfView end
end)

local function applyFOV()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	cam.FieldOfView = State.FOV and State.FOVValue or defaultFOV
end

local lightingSaved = nil
local localLightPart = nil
local localLightConn = nil

local function saveLighting()
	if lightingSaved then return end
	lightingSaved = {
		Brightness = Lighting.Brightness,
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		FogEnd = Lighting.FogEnd,
		FogStart = Lighting.FogStart,
		ClockTime = Lighting.ClockTime,
		GlobalShadows = Lighting.GlobalShadows,
	}
end

local function restoreLighting()
	if not lightingSaved then return end
	pcall(function()
		Lighting.Brightness = lightingSaved.Brightness
		Lighting.Ambient = lightingSaved.Ambient
		Lighting.OutdoorAmbient = lightingSaved.OutdoorAmbient
		Lighting.FogEnd = lightingSaved.FogEnd
		Lighting.FogStart = lightingSaved.FogStart
		Lighting.ClockTime = lightingSaved.ClockTime
		Lighting.GlobalShadows = lightingSaved.GlobalShadows
	end)
	lightingSaved = nil
end

local function applyFullbright()
	if not State.Fullbright then
		restoreLighting()
		return
	end
	saveLighting()
	pcall(function()
		Lighting.Brightness = 3
		Lighting.Ambient = Color3.fromRGB(180, 180, 180)
		Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
		Lighting.FogEnd = 1e6
		Lighting.FogStart = 1e6
		Lighting.GlobalShadows = false
		if Lighting.ClockTime < 6 or Lighting.ClockTime > 18 then
			Lighting.ClockTime = 14
		end
	end)
end

local function destroyLocalLight()
	if localLightConn then
		pcall(function() localLightConn:Disconnect() end)
		localLightConn = nil
	end
	pcall(function() local g=(getgenv and getgenv() or _G) if g.__unfly_check then g.__unfly_check() end end)
	if localLightPart then
		pcall(function() localLightPart:Destroy() end)
		localLightPart = nil
	end
	local host = Workspace:FindFirstChild("_rh_fx")
	if host then
		for _, ch in ipairs(host:GetChildren()) do
			if ch.Name == "LocalLight" then pcall(function() ch:Destroy() end) end
		end
	end
end

local function createLocalLight()
	destroyLocalLight()
	if not State.LocalLight then return end
	local host = Workspace:FindFirstChild("_rh_fx")
	if not host then
		host = Instance.new("Folder")
		host.Name = "_rh_fx"
		host.Parent = Workspace
	end
	local part = Instance.new("Part")
	part.Name = "LocalLight"
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.Parent = host
	local light = Instance.new("PointLight")
	light.Brightness = State.LightBright
	light.Range = 60
	light.Shadows = false
	light.Color = Color3.fromRGB(255, 250, 240)
	light.Parent = part
	localLightPart = part
	localLightConn = RunService.RenderStepped:Connect(function()
		if not State.LocalLight or not localLightPart then return end
		local cam = Workspace.CurrentCamera
		local c = getChar()
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		local pos = (hrp and hrp.Position) or (cam and cam.CFrame.Position)
		if pos then
			pcall(function()
				localLightPart.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
				local pl = localLightPart:FindFirstChildOfClass("PointLight")
				if pl then pl.Brightness = State.LightBright end
			end)
		end
	end)
end

local keysDown = {}
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		keysDown[input.KeyCode] = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		keysDown[input.KeyCode] = nil
	end
end)

local flyAccum = 0
local function flyStep(dt)
	if not State.Fly then return end
	local c = getChar()
	if not c then return end
	local hrp = c:FindFirstChild("HumanoidRootPart")
	local hum = c:FindFirstChildOfClass("Humanoid")
	if not hrp then return end

	local cam = Workspace.CurrentCamera
	if not cam then return end

	local look = cam.CFrame.LookVector
	local right = cam.CFrame.RightVector
	local move = Vector3.zero
	if keysDown[Enum.KeyCode.W] then move = move + look end
	if keysDown[Enum.KeyCode.S] then move = move - look end
	if keysDown[Enum.KeyCode.A] then move = move - right end
	if keysDown[Enum.KeyCode.D] then move = move + right end
	if keysDown[Enum.KeyCode.Space] or keysDown[Enum.KeyCode.E] then move = move + Vector3.yAxis end
	if keysDown[Enum.KeyCode.LeftControl] or keysDown[Enum.KeyCode.Q] then move = move - Vector3.yAxis end

	pcall(function()
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end)

	if move.Magnitude < 0.05 then return end
	move = move.Unit

	local maxStep = State.SafeMode and 6 or 10
	local step = math.clamp(State.FlySpeed * dt, 0.4, maxStep)
	local target = hrp.Position + move * step
	pcall(function()
		hrp.CFrame = CFrame.new(target) * CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
	end)

	if hum then
		pcall(function()

			flyAccum = flyAccum + dt
			if flyAccum > 0.4 then
				flyAccum = 0
				hum.PlatformStand = false
			end
		end)
	end
end

local freecamConn = nil
local freecamSaved = nil

local function stopFreeCam()
	State.FreeCam = false
	if freecamConn then freecamConn:Disconnect() freecamConn = nil end
	local cam = Workspace.CurrentCamera
	if cam and freecamSaved then
		pcall(function()
			cam.CameraType = freecamSaved.Type
			cam.CameraSubject = freecamSaved.Subject
			cam.FieldOfView = freecamSaved.FOV
		end)
	end
	freecamSaved = nil
end

local function startFreeCam()
	stopFreeCam()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	freecamSaved = {
		Type = cam.CameraType,
		Subject = cam.CameraSubject,
		FOV = cam.FieldOfView,
	}
	State.FreeCam = true

	pcall(function() cam.CameraType = Enum.CameraType.Scriptable end)

	local yaw, pitch = 0, 0
	local cf = cam.CFrame
	yaw = math.atan2(-cf.LookVector.X, -cf.LookVector.Z)
	pitch = math.asin(math.clamp(cf.LookVector.Y, -1, 1))

	freecamConn = RunService.RenderStepped:Connect(function(dt)
		if not State.FreeCam then return end
		local cam2 = Workspace.CurrentCamera
		if not cam2 then return end

		local delta = UserInputService:GetMouseDelta()
		yaw = yaw - delta.X * 0.004
		pitch = math.clamp(pitch - delta.Y * 0.004, -1.4, 1.4)

		local rot = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
		local look = rot.LookVector
		local right = rot.RightVector
		local move = Vector3.zero
		if keysDown[Enum.KeyCode.W] then move = move + look end
		if keysDown[Enum.KeyCode.S] then move = move - look end
		if keysDown[Enum.KeyCode.A] then move = move - right end
		if keysDown[Enum.KeyCode.D] then move = move + right end
		if keysDown[Enum.KeyCode.Space] or keysDown[Enum.KeyCode.E] then move = move + Vector3.yAxis end
		if keysDown[Enum.KeyCode.LeftControl] or keysDown[Enum.KeyCode.Q] then move = move - Vector3.yAxis end

		local pos = cam2.CFrame.Position
		if move.Magnitude > 0 then
			pos = pos + move.Unit * State.FreeCamSpeed * dt
		end
		pcall(function() local g=(getgenv and getgenv() or _G) if g.__unfly_check then g.__unfly_check() end end)
		cam2.CFrame = CFrame.new(pos) * rot
		if State.FOV then
			cam2.FieldOfView = State.FOVValue
		end
	end)
end

local jumpConn = nil
local function setInfJump(on)
	State.InfJump = on
	if jumpConn then jumpConn:Disconnect() jumpConn = nil end
	if not on then return end
	jumpConn = UserInputService.JumpRequest:Connect(function()
		if not State.InfJump then return end
		local hum = getHum()
		if not hum then return end
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
	end)
end

local espAcc = 0

RunService.Heartbeat:Connect(function(dt)
	pcall(function() local m=(getgenv and getgenv() or _G).__unfly_mark if m then m("loop") end end)
	local c = getChar()
	if not c then return end
	local hum = c:FindFirstChildOfClass("Humanoid")

	if (tick() * 3) % 1 < 0.4 then
		if State.InfStamina then
			local stam = findVal({ "Sprint", "Stam" })
			if stam then pcall(function() if stam.Value < 4 then stam.Value = 5 end end) end
			local od = findVal({ "Sprint", "Overdrive" })
			if od and od.Value ~= 0 then pcall(function() od.Value = 0 end) end
		end
		if State.InfBreath then
			local breath = findVal({ "Breath" })
			if breath then pcall(function() if breath.Value < 15 then breath.Value = 20 end end) end
		end
		if State.InfCold then
			protectCold()
		end
	end

	if State.Speed and not State.SafeMode then
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if hrp and hum and hum.MoveDirection.Magnitude > 0.15 then
			local boost = math.clamp((State.SpeedValue - 16) * 0.03, 0, 1.4)
			if boost > 0 and (tick() * 8) % 1 < 0.5 then
				pcall(function()
					hrp.CFrame = hrp.CFrame + hum.MoveDirection * boost
				end)
			end
		end
	elseif State.Speed and State.SafeMode then

	end

	if State.JumpPower and hum then

	end

	if State.Noclip and (tick() * 4) % 1 < 0.35 then
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if hrp then pcall(function() hrp.CanCollide = false end) end
		for _, p in ipairs(c:GetChildren()) do
			if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
		end
	end

	if State.FOV and not State.FreeCam then pcall(applyFOV) end
	if State.Fullbright and (tick() * 2) % 1 < 0.3 then
		pcall(applyFullbright)
	end

	if State.Fly then
		flyStep(dt)

		if (tick() * 5) % 1 < 0.25 then
			for _, part in ipairs(c:GetChildren()) do
				if part:IsA("BasePart") then
					pcall(function() part.CanCollide = false end)
				end
			end
		end
	end

	espAcc = espAcc + dt
	if State.ESP and espAcc >= 1.25 then
		espAcc = 0
		pcall(refreshESP)
	end
end)

LP.CharacterAdded:Connect(function()
pcall(function() local g=(getgenv and getgenv() or _G) if g.__unfly_check then g.__unfly_check() end end)
	task.wait(0.6)
	destroyChinaHat()
	if auraHL then pcall(function() auraHL:Destroy() end) auraHL = nil end
	if State.Fly then
		State.Fly = false
	end
	if State.FreeCam then
		stopFreeCam()
	end
	if State.ChinaHat then createChinaHat(getChar()) end
	if State.Aura then setAura(true) end
	if State.InfJump then setInfJump(true) end
	if State.ESP then task.defer(refreshESP) end
end)


local UI_URL = "https://raw.githubusercontent.com/RyzenEngineRb/QnAmeAplKnanKsbWRgs/refs/heads/main/UiLib.lua"
local function fetchUiLib()
	local ok, src = pcall(function()
		return game:HttpGet(UI_URL)
	end)
	if ok and type(src) == "string" and #src > 100 then
		return src
	end
	if isfile and readfile and isfile("UiLib.lua") then
		local ok2, src2 = pcall(readfile, "UiLib.lua")
		if ok2 and type(src2) == "string" and #src2 > 100 then
			return src2
		end
	end
	error("[ResidenceHorror] UiLib not found")
end

local okLib, Library = pcall(function()
	return loadstring(fetchUiLib())()
end)
if not okLib or type(Library) ~= "table" then
	warn("[ResidenceHorror] UiLib load failed: " .. tostring(Library))
	return
end

local Window = Library:CreateWindow({
	Name = "Residence Horror",
	Tagline = "v5 — Unfly",
	Role = "User",
	Logo = "",
	Discord = "",
	Telegram = "https://t.me/KvantTon",
	LockBranding = false,
	ToggleKey = Enum.KeyCode.RightShift,
})

local PlayerTab = Window:AddTab({ Name = "Player", Icon = "person" })
local VisualTab = Window:AddTab({ Name = "Visual", Icon = "eye" })
local DebugTab = Window:AddTab({ Name = "Debug", Icon = "code" })

PlayerTab:AddBanner({ Title = "Welcome to", Highlight = "Residence Horror", Subtitle = "Survival + movement" })

local secS = PlayerTab:AddSection({ Name = "Survival", Icon = "shield", Position = "left" })
local secP = PlayerTab:AddSection({ Name = "Movement", Icon = "bolt", Position = "right" })

secS:AddToggle({
	Name = "Infinite Stamina",
	Icon = "bolt",
	Default = false,
	Callback = function(v) State.InfStamina = v == true end,
})
secS:AddToggle({
	Name = "Infinite Oxygen",
	Icon = "droplet",
	Default = false,
	Callback = function(v) State.InfBreath = v == true end,
})
secS:AddToggle({
	Name = "Cold Protect",
	Icon = "shield",
	Default = false,
	Callback = function(v) State.InfCold = v == true end,
})
secS:AddButton({
	Name = "Scan Cold Values",
	ButtonText = "Scan",
	Callback = function()
		local list = findColdValues()
		local names = {}
		for _, v in ipairs(list) do
			names[#names + 1] = v:GetFullName() .. " = " .. tostring(v.Value)
		end
		pcall(function() local m=(getgenv and getgenv() or _G).__unfly_mark if m then m("ui") m("feature") end end)
Library:Notify({
			Title = "Cold Protect",
			Content = (#names > 0) and table.concat(names, "\n") or "No cold/temp values found",
			Duration = 5,
		})
	end,
})

secP:AddToggle({
	Name = "Noclip",
	Icon = "person",
	Default = false,
	Callback = function(v)
		State.Noclip = v == true
		if not State.Noclip then
			local c = getChar()
			if not c then return end
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
					pcall(function() p.CanCollide = true end)
				end
			end
		end
	end,
})
secP:AddToggle({
	Name = "Infinite Jump",
	Icon = "person",
	Default = false,
	Callback = function(v) setInfJump(v == true) end,
})
secP:AddToggle({
	Name = "Speed Boost (no WS)",
	Icon = "bolt",
	Default = false,
	Callback = function(v)
		State.Speed = v == true
	end,
})
secP:AddSlider({
	Name = "Speed Strength",
	Icon = "bolt",
	Min = 16,
	Max = 40,
	Default = 24,
	Callback = function(v) State.SpeedValue = tonumber(v) or 24 end,
})
secP:AddToggle({
	Name = "Safe Mode",
	Icon = "shield",
	Default = true,
	Callback = function(v)
		State.SafeMode = v == true
	end,
})
secP:AddToggle({
	Name = "Fly",
	Icon = "bolt",
	Default = false,
	Callback = function(v)
		State.Fly = v == true
		flyAccum = 0
		if not State.Fly then
			local c = getChar()
			local hrp = c and c:FindFirstChild("HumanoidRootPart")
			if hrp then
				pcall(function()
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero
				end)
			end
		end
	end,
})
secP:AddSlider({
	Name = "Fly Speed",
	Icon = "bolt",
	Min = 30,
	Max = 200,
	Default = 80,
	Callback = function(v) State.FlySpeed = tonumber(v) or 80 end,
})

local secV = VisualTab:AddSection({ Name = "ESP", Icon = "eye", Position = "left" })
local secA = VisualTab:AddSection({ Name = "Self", Icon = "star", Position = "right" })
local secC = VisualTab:AddSection({ Name = "Camera", Icon = "image", Position = "left" })

secV:AddToggle({
	Name = "Mutant ESP",
	Icon = "eye",
	Default = false,
	Callback = function(v)
		State.ESP = v == true
		if State.ESP then refreshESP() else clearESP() end
	end,
})
secA:AddToggle({
	Name = "China Hat",
	Icon = "star",
	Default = false,
	Callback = function(v)
		State.ChinaHat = v == true
		if State.ChinaHat then createChinaHat(getChar()) else destroyChinaHat() end
	end,
})
secA:AddColorPicker({
	Name = "Hat Color",
	Icon = "palette",
	Default = Color3.fromRGB(255, 105, 180),
	Callback = function(c)
		if typeof(c) == "Color3" then
			ChinaHatColor = c
			if chinaHatPart and chinaHatPart.Parent then
				chinaHatPart.Color = c
				local light = chinaHatPart:FindFirstChildOfClass("PointLight")
				if light then light.Color = c end
			end
		end
	end,
})
secA:AddToggle({
	Name = "Aura",
	Icon = "star",
	Default = false,
	Callback = function(v) setAura(v == true) end,
})
secC:AddToggle({
	Name = "Custom FOV",
	Icon = "eye",
	Default = false,
	Callback = function(v)
		State.FOV = v == true
		if not State.FOV then
			local cam = Workspace.CurrentCamera
			if cam and not State.FreeCam then cam.FieldOfView = defaultFOV end
		else
			applyFOV()
		end
	end,
})
secC:AddSlider({
	Name = "FOV Value",
	Icon = "eye",
	Min = 50,
	Max = 120,
	Default = 70,
	Callback = function(v)
		State.FOVValue = tonumber(v) or 70
		if State.FOV then applyFOV() end
	end,
})
secC:AddToggle({
	Name = "Free Camera",
	Icon = "eye",
	Default = false,
	Callback = function(v)
		if v then startFreeCam() else stopFreeCam() end
	end,
})
secC:AddSlider({
	Name = "FreeCam Speed",
	Icon = "bolt",
	Min = 20,
	Max = 150,
	Default = 60,
	Callback = function(v) State.FreeCamSpeed = tonumber(v) or 60 end,
})
secC:AddToggle({
	Name = "Fullbright",
	Icon = "sun",
	Default = false,
	Callback = function(v)
		State.Fullbright = v == true
		if State.Fullbright then applyFullbright() else restoreLighting() end
	end,
})
secC:AddToggle({
	Name = "Local Light",
	Icon = "sun",
	Default = false,
	Callback = function(v)
		State.LocalLight = v == true
		if State.LocalLight then createLocalLight() else destroyLocalLight() end
	end,
})
secC:AddSlider({
	Name = "Light Brightness",
	Icon = "sun",
	Min = 0.5,
	Max = 5,
	Default = 2,
	Increment = 0.1,
	Callback = function(v)
		State.LightBright = tonumber(v) or 2
	end,
})

local secD = DebugTab:AddSection({ Name = "Anti Cheat", Icon = "shield", Position = "left" })
secD:AddButton({
	Name = "Check Spoof",
	ButtonText = "Check",
	Callback = function()
		Library:Notify({
			Title = "Spoof",
			Content = "Metatable spoof disabled (AC detect)",
			Duration = 3,
		})
	end,
})
secD:AddButton({
	Name = "Scan AC Remotes",
	ButtonText = "Scan",
	Callback = function()
		local n = scanAntiCheatRemotes()
		Library:Notify({
			Title = "AC Remotes",
			Content = "Found remotes: " .. tostring(n) .. " (no patch)",
			Duration = 3,
		})
	end,
})
secD:AddButton({
	Name = "Show WalkSpeed",
	ButtonText = "Show",
	Callback = function()
		local hum = getHum()
		local ws = hum and tostring(hum.WalkSpeed) or "?"
		Library:Notify({
			Title = "WalkSpeed",
			Content = "Client WS (read-only): " .. ws .. " — script does not set it",
			Duration = 3,
		})
	end,
})

Library:Notify({
	Title = "Residence Horror",
	Content = "Place " .. tostring(game.PlaceId) .. (isAllowedPlace() and " (Residence OK)" or "") .. " | RightShift",
	Duration = 4,
})
print("[ResidenceHorror] PlaceId=" .. tostring(game.PlaceId) .. " UnflyUi — RightShift")
