-- LobbySystem.lua (ServerScriptService - Script olarak)
-- Lobby'deki level portlarını yönetir

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LevelManager = require(ServerScriptService:WaitForChild("LevelManager"))

print("🏛️ Lobby Sistemi başlatılıyor...")

-- Lobby klasörünü kontrol et
local lobby = workspace:WaitForChild("Lobby", 10)
if not lobby then
	warn("⚠️ Workspace'de 'Lobby' klasörü bulunamadı!")
	return
end

-- Level portalları klasörünü bul veya oluştur
local levelPortals = lobby:FindFirstChild("LevelPortals")
if not levelPortals then
	warn("⚠️ Lobby'de 'LevelPortals' klasörü bulunamadı!")
	return
end

print("✅ Lobby klasörü bulundu")

-- Her portal için ProximityPrompt ekle
local function SetupLevelPortal(portal, levelIndex)
	local mainPart = portal
	if portal:IsA("Model") then
		mainPart = portal.PrimaryPart or portal:FindFirstChildWhichIsA("BasePart")
	end

	if not mainPart or not mainPart:IsA("BasePart") then
		warn("⚠️ Portal için BasePart bulunamadı:", portal.Name)
		return
	end

	local oldPrompt = mainPart:FindFirstChild("LevelPrompt")
	if oldPrompt then oldPrompt:Destroy() end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LevelPrompt"
	prompt.ActionText = "Gir"
	prompt.ObjectText = "Level " .. levelIndex
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0.5
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.Parent = mainPart

	-- E tuşuna basıldığında
	prompt.Triggered:Connect(function(player)
		print("🚪 Player", player.Name, "Level", levelIndex, "portalına girdi")

		-- GECİKME KALDIRILDI: Hemen leveli başlat
		LevelManager.StartLevel(player, levelIndex)
	end)

	print("✅ Portal hazır:", portal.Name, "- Level", levelIndex)
end

-- Tüm portalları tara ve setup et
local function InitializePortals()
	for _, portal in ipairs(levelPortals:GetChildren()) do
		local levelIndex = portal:GetAttribute("LevelIndex")

		if not levelIndex then
			local levelNum = string.match(portal.Name, "%d+")
			levelIndex = tonumber(levelNum)
		end

		if levelIndex then
			SetupLevelPortal(portal, levelIndex)
		else
			warn("⚠️ Portal için LevelIndex bulunamadı:", portal.Name)
		end
	end
end

InitializePortals()

levelPortals.ChildAdded:Connect(function(portal)
	wait(0.1)
	local levelIndex = portal:GetAttribute("LevelIndex") or tonumber(string.match(portal.Name, "%d+"))
	if levelIndex then
		SetupLevelPortal(portal, levelIndex)
	end
end)

print("🎮 Lobby Sistemi aktif!")
