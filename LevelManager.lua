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
		TimeLimit = 20, -- Süreyi biraz artırdım test için
		TimeScale = 0.15,
		SpawnLocation = CFrame.new(596.372, 4.608, -583.243)
	},
	{
		Name = "Level 2",
		TimeLimit = 15,
		TimeScale = 0.15,
		SpawnLocation = CFrame.new(349, 40, 1)
	},
	{
		Name = "Level 3",
		TimeLimit = 15,
		TimeScale = 0.15,
		SpawnLocation = CFrame.new(349, 40, 61)
	}
}

local activeLevels = {}

-- Level başlat
function LevelManager.StartLevel(player, levelIndex)
	local level = LevelManager.Levels[levelIndex]
	if not level then return end

	local character = player.Character
	if not character then return end

	if activeLevels[player] then
		LevelManager.EndLevel(player, false)
	end

	activeLevels[player] = {
		levelIndex = levelIndex,
		timeRemaining = level.TimeLimit,
		startTime = tick(),
		isCompleting = false -- Yeni kontrol: Level zaten bitiyor mu?
	}

	if character.PrimaryPart then
		character:SetPrimaryPartCFrame(level.SpawnLocation)
	end

	local startLevelEvent = ReplicatedStorage:FindFirstChild("StartLevelEvent")
	if startLevelEvent then
		startLevelEvent:FireClient(player, levelIndex)
	end

	LevelManager.ActivateManualNPCs(levelIndex)

	wait(5) -- Kamera animasyonu süresi

	LevelManager.DisableHighlights()
	TimeSlowModule.SetTimeScale(level.TimeScale)
	LevelManager.StartTimer(player, level)
end

function LevelManager.DisableHighlights()
	for _, npc in ipairs(workspace:GetDescendants()) do
		if npc:IsA("Model") and (npc.Name:match("^Target") or npc.Name:match("^Threat")) then
			local highlight = npc:FindFirstChild("NPCHighlight")
			if highlight then highlight:Destroy() end
		end
	end
end

function LevelManager.ActivateManualNPCs(levelIndex)
	-- (Bu fonksiyonun içi orijinaliyle aynı, değişiklik yok)
	-- Kısaltmak için burayı aynen koruduğunu varsayıyorum
	-- ...

	local levelAreas = workspace:FindFirstChild("LevelAreas")
	local currentLevelArea = levelAreas and levelAreas:FindFirstChild("Level" .. levelIndex)

	if currentLevelArea then
		for _, object in ipairs(currentLevelArea:GetDescendants()) do
			if object:IsA("Model") and object:FindFirstChild("Humanoid") then
				local npcType = nil
				if object.Name:match("^Target") then npcType = NPCSaveSystem.NPCTypes.TARGET
				elseif object.Name:match("^Threat") then npcType = NPCSaveSystem.NPCTypes.THREAT end

				if npcType then
					NPCSaveSystem.SetupNPC(object, npcType)
					TimeSlowModule.RegisterNPC(object)
					local humanoid = object:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid.WalkSpeed = 0
						humanoid.JumpPower = 0
					end
				end
			end
		end
	end
end

-- Timer başlat
function LevelManager.StartTimer(player, level)
	local levelData = activeLevels[player]
	if not levelData then return end

	local updateTimerEvent = ReplicatedStorage:FindFirstChild("UpdateTimer")

	levelData.gameLoop = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
		if not activeLevels[player] then return end

		-- Eğer level zaten bitiş sürecindeyse (isCompleting) timer'ı durdurma ama işlem yapma
		if levelData.isCompleting then return end

		levelData.timeRemaining = levelData.timeRemaining - deltaTime

		if updateTimerEvent then
			updateTimerEvent:FireClient(player, levelData.timeRemaining)
		end

		if levelData.timeRemaining <= 0 then
			LevelManager.EndLevel(player, false) -- Süre bitti, kaybettin
		end

		if NPCSaveSystem.IsLevelComplete() then
			-- DÜZELTME: Anında bitirme!
			-- Oyuncu NPC'nin uçtuğunu görsün diye beklemeye alıyoruz.
			levelData.isCompleting = true -- Flag koyduk, tekrar tekrar tetiklenmesin

			print("✅ Tüm NPC'ler kurtarıldı! Bitiş sekansı başlıyor...")

			-- 2.5 saniye bekle (Ragdoll uçuşunu izle)
			task.delay(2.5, function()
				-- Hala oyundaysa bitir
				if activeLevels[player] then
					LevelManager.EndLevel(player, true)
				end
			end)
		end
	end)
end

-- Level'ı bitir
function LevelManager.EndLevel(player, success)
	local levelData = activeLevels[player]
	if not levelData then return end

	if levelData.gameLoop then levelData.gameLoop:Disconnect() end

	TimeSlowModule.ResetTime()
	NPCSaveSystem.ClearAll()
	LevelManager.ResetNPCs(levelData.levelIndex)

	local endLevelEvent = ReplicatedStorage:FindFirstChild("EndLevelEvent")
	if endLevelEvent then
		endLevelEvent:FireClient(player, success, levelData.levelIndex)
	end

	local currentLevelIndex = levelData.levelIndex
	activeLevels[player] = nil

	if success then
		task.wait(3)
		local returnEvent = ReplicatedStorage:FindFirstChild("ReturnToLobbyEvent")
		if returnEvent then returnEvent:FireClient(player) end

		task.wait(1.5)

		local character = player.Character
		if character and character.PrimaryPart then
			local lobby = workspace:FindFirstChild("Lobby")
			local spawnLocation = lobby and lobby:FindFirstChild("SpawnLocation")
			local targetCFrame = spawnLocation and (spawnLocation.CFrame + Vector3.new(0, 3, 0)) or CFrame.new(0, 5, -50)
			character:SetPrimaryPartCFrame(targetCFrame)
		end
	else
		task.wait(3)
		LevelManager.StartLevel(player, currentLevelIndex)
	end
end

-- NPC Reset Fonksiyonu (Aynı kalıyor)
function LevelManager.ResetNPCs(levelIndex)
	local levelAreas = workspace:FindFirstChild("LevelAreas")
	if not levelAreas then return end
	local currentLevelArea = levelAreas:FindFirstChild("Level" .. levelIndex)
	if not currentLevelArea then return end

	for _, npc in ipairs(currentLevelArea:GetDescendants()) do
		if npc:IsA("Model") and (npc.Name:match("^Target") or npc.Name:match("^Threat")) then
			local RagdollModule = require(ReplicatedStorage:WaitForChild("RagdollModule"))
			RagdollModule.DisableRagdoll(npc)

			local highlight = npc:FindFirstChild("NPCHighlight")
			if highlight then highlight:Destroy() end

			local rootPart = npc:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local prompt = rootPart:FindFirstChild("SavePrompt")
				if prompt then prompt:Destroy() end
			end
		end
	end
end

return LevelManager
