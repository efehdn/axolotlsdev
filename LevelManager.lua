-- LevelManager.lua (ServerScriptService)
-- Manuel olarak yerleştirilmiş NPC'leri aktifleştirme sistemi

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local TimeSlowModule = require(ReplicatedStorage:WaitForChild("TimeSlowModule"))
local NPCSaveSystem = require(ReplicatedStorage:WaitForChild("NPCSaveSystem"))

local LevelManager = {}

-- Level ayarları
LevelManager.Levels = {
	{
		Name = "Level 1",
		TimeLimit = 13,
		TimeScale = 0.15,
		SpawnLocation = CFrame.new(596.372, 4.608, -583.243)
	},
	{
		Name = "Level 2",
		TimeLimit = 13,
		TimeScale = 0.15,
		SpawnLocation = CFrame.new(349, 40, 1)
	},
	{
		Name = "Level 3",
		TimeLimit = 13,
		TimeScale = 0.15,
		SpawnLocation = CFrame.new(349, 40, 61)
	}
}

-- Aktif level durumu
local activeLevels = {}

--[[
	MANUEL NPC SİSTEMİ - WORKSPACE YAPISI:
	
	Workspace/
	└── LevelAreas/
	    ├── Level1/
	    │   ├── Platform (Senin yaptığın model)
	    │   ├── TargetNPC1 (Model - Yeşil, kurtarılacak)
	    │   ├── TargetNPC2 (Model - Yeşil, kurtarılacak)
	    │   ├── ThreatNPC1 (Model - Kırmızı, tehlike)
	    │   ├── ThreatNPC2 (Model - Kırmızı, tehlike)
	    │   └── ThreatNPC3 (Model - Kırmızı, tehlike)
	    │
	    ├── Level2/
	    │   ├── Platform
	    │   ├── TargetNPC1
	    │   └── ...
	    │
	    └── Level3/
	        └── ...
	
	NPC İSİMLENDİRME KURALI:
	- Kurtarılacak NPC: İsmi "Target" ile başlamalı (TargetNPC1, Target_Civilian vb.)
	- Tehlike NPC: İsmi "Threat" ile başlamalı (ThreatNPC1, Threat_Enemy vb.)
]]

-- Level başlat
function LevelManager.StartLevel(player, levelIndex)
	local level = LevelManager.Levels[levelIndex]
	if not level then
		warn("Level bulunamadı:", levelIndex)
		return
	end

	local character = player.Character
	if not character then return end

	-- Önceki level'ı temizle
	if activeLevels[player] then
		LevelManager.EndLevel(player, false)
	end

	activeLevels[player] = {
		levelIndex = levelIndex,
		timeRemaining = level.TimeLimit,
		startTime = tick()
	}

	print("🎮 Level", levelIndex, "başlatılıyor - Player:", player.Name)

	-- Player'ı level'a ışınla
	if character.PrimaryPart then
		character:SetPrimaryPartCFrame(level.SpawnLocation)
	end

	-- Intro ve Kamera animasyonunu başlat
	local startLevelEvent = ReplicatedStorage:FindFirstChild("StartLevelEvent")
	if startLevelEvent then
		startLevelEvent:FireClient(player, levelIndex)
	end

	-- Manuel NPC'leri aktifleştir
	LevelManager.ActivateManualNPCs(levelIndex)

	-- Kamera animasyonu süresi kadar bekle (5 saniye)
	wait(5)

	-- Highlight'ları kapat
	LevelManager.DisableHighlights()

	-- Zaman yavaşlatmayı aktif et
	TimeSlowModule.SetTimeScale(level.TimeScale)

	-- Timer başlat
	LevelManager.StartTimer(player, level)
end

-- Highlight'ları kapat
function LevelManager.DisableHighlights()
	for _, npc in ipairs(workspace:GetDescendants()) do
		if npc:IsA("Model") and (npc.Name:match("^Target") or npc.Name:match("^Threat")) then
			local highlight = npc:FindFirstChild("NPCHighlight")
			if highlight then 
				highlight:Destroy() 
			end
		end
	end
end

-- Manuel olarak yerleştirilmiş NPC'leri aktifleştir
function LevelManager.ActivateManualNPCs(levelIndex)
	print("🎭 Manuel NPC'ler aktifleştiriliyor - Level:", levelIndex)

	local levelAreas = workspace:FindFirstChild("LevelAreas")
	if not levelAreas then
		warn("⚠️ LevelAreas klasörü bulunamadı!")
		return
	end

	local currentLevelArea = levelAreas:FindFirstChild("Level" .. levelIndex)
	if not currentLevelArea then
		warn("⚠️ Level" .. levelIndex .. " klasörü bulunamadı!")
		return
	end

	-- NPC sayaçları
	local targetCount = 0
	local threatCount = 0

	-- Level klasöründeki TÜM modelleri tara
	for _, object in ipairs(currentLevelArea:GetDescendants()) do
		if object:IsA("Model") and object:FindFirstChild("Humanoid") then

			-- NPC tipini isimden belirle
			local npcType = nil

			if object.Name:match("^Target") then
				-- İsmi "Target" ile başlıyorsa → Kurtarılacak NPC
				npcType = NPCSaveSystem.NPCTypes.TARGET
				targetCount = targetCount + 1

			elseif object.Name:match("^Threat") then
				-- İsmi "Threat" ile başlıyorsa → Tehlike NPC
				npcType = NPCSaveSystem.NPCTypes.THREAT
				threatCount = threatCount + 1
			end

			-- NPC tipine göre setup et
			if npcType then
				-- NPC'yi sisteme kaydet
				NPCSaveSystem.SetupNPC(object, npcType)
				TimeSlowModule.RegisterNPC(object)

				-- NPC'nin Humanoid'ini ayarla (hareket etmesin)
				local humanoid = object:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = 0
					humanoid.JumpPower = 0
				end

				print("✅ NPC aktifleştirildi:", object.Name, "- Tip:", npcType)
			end
		end
	end

	print("📊 Toplam NPC:", "Target=" .. targetCount, "Threat=" .. threatCount)

	-- Eğer hiç NPC bulunamadıysa uyar
	if targetCount == 0 then
		warn("⚠️ Hiç Target NPC bulunamadı! Level" .. levelIndex .. " klasöründe 'Target' ile başlayan NPC ekle")
	end
end

-- Timer başlat
function LevelManager.StartTimer(player, level)
	local levelData = activeLevels[player]
	if not levelData then return end

	local updateTimerEvent = ReplicatedStorage:FindFirstChild("UpdateTimer")

	levelData.gameLoop = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
		if not activeLevels[player] then return end

		-- GERÇEK ZAMAN KULLAN (yavaşlatılmış değil)
		levelData.timeRemaining = levelData.timeRemaining - deltaTime

		if updateTimerEvent then
			updateTimerEvent:FireClient(player, levelData.timeRemaining)
		end

		if levelData.timeRemaining <= 0 then
			LevelManager.EndLevel(player, false) -- BAŞARISIZ
		end

		if NPCSaveSystem.IsLevelComplete() then
			LevelManager.EndLevel(player, true) -- BAŞARILI
		end
	end)
end

-- Level'ı bitir
function LevelManager.EndLevel(player, success)
	local levelData = activeLevels[player]
	if not levelData then return end

	print("🏁 Level bitiyor - Player:", player.Name, "Başarı:", success)

	-- Timer durdur
	if levelData.gameLoop then 
		levelData.gameLoop:Disconnect() 
	end

	-- Zaman normale
	TimeSlowModule.ResetTime()

	-- NPC'leri temizle (highlight'lar, prompt'lar vb.)
	NPCSaveSystem.ClearAll()

	-- NPC'leri SIFIRLA (konumlarını sıfırlamak için)
	LevelManager.ResetNPCs(levelData.levelIndex)

	-- Sonuç ekranı göster
	local endLevelEvent = ReplicatedStorage:FindFirstChild("EndLevelEvent")
	if endLevelEvent then
		endLevelEvent:FireClient(player, success, levelData.levelIndex)
	end

	local currentLevelIndex = levelData.levelIndex
	activeLevels[player] = nil

	-- Karar Mekanizması
	if success then
		-- BAŞARILI: Lobiye gönder
		print("✅ Level başarılı, lobiye dönülüyor...")
		task.wait(3)

		-- Lobiye dönüş introsu
		local returnEvent = ReplicatedStorage:FindFirstChild("ReturnToLobbyEvent")
		if returnEvent then 
			returnEvent:FireClient(player) 
		end

		task.wait(1.5)

		-- Lobiye ışınla
		local character = player.Character
		if character and character.PrimaryPart then
			local lobby = workspace:FindFirstChild("Lobby")
			local spawnLocation = lobby and lobby:FindFirstChild("SpawnLocation")
			local targetCFrame = spawnLocation and (spawnLocation.CFrame + Vector3.new(0, 3, 0)) or CFrame.new(0, 5, -50)
			character:SetPrimaryPartCFrame(targetCFrame)
		end

	else
		-- BAŞARISIZ: Level'i yeniden başlat
		print("❌ Level başarısız, yeniden başlatılıyor...")
		task.wait(3)
		LevelManager.StartLevel(player, currentLevelIndex)
	end
end

-- NPC'leri sıfırla (ragdoll'dan kurtarılmış NPCs'leri eski haline getir)
function LevelManager.ResetNPCs(levelIndex)
	local levelAreas = workspace:FindFirstChild("LevelAreas")
	if not levelAreas then return end

	local currentLevelArea = levelAreas:FindFirstChild("Level" .. levelIndex)
	if not currentLevelArea then return end

	-- Tüm NPC'leri tara ve sıfırla
	for _, npc in ipairs(currentLevelArea:GetDescendants()) do
		if npc:IsA("Model") and (npc.Name:match("^Target") or npc.Name:match("^Threat")) then

			-- Ragdoll'u kapat
			local RagdollModule = require(ReplicatedStorage:WaitForChild("RagdollModule"))
			RagdollModule.DisableRagdoll(npc)

			-- Highlight'ları temizle
			local highlight = npc:FindFirstChild("NPCHighlight")
			if highlight then
				highlight:Destroy()
			end

			-- ProximityPrompt'ları temizle
			local rootPart = npc:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local prompt = rootPart:FindFirstChild("SavePrompt")
				if prompt then
					prompt:Destroy()
				end
			end

			-- NOT: Pozisyonlarını SIFIRLAMIYORUZ çünkü manuel olarak yerleştirdin
			-- Eğer ragdoll sonrası eski konumlarına dönmesini istersen:
			-- npc:SetAttribute("OriginalCFrame", npc:GetPrimaryPartCFrame()) -- İlk spawn'da
			-- npc:SetPrimaryPartCFrame(npc:GetAttribute("OriginalCFrame")) -- Reset'te
		end
	end

	print("🔄 NPC'ler sıfırlandı - Level:", levelIndex)
end

return LevelManager