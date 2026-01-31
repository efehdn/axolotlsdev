-- NPCSaveSystem.lua
-- NPC'leri kurtarma ve highlight sistemi

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RagdollModule = require(ReplicatedStorage:WaitForChild("RagdollModule"))

local NPCSaveSystem = {}

-- NPC türleri
NPCSaveSystem.NPCTypes = {
	TARGET = "Target", -- Yeşil - Kurtarılacak
	THREAT = "Threat"  -- Kırmızı - Tehlike
}

-- Kurtarılan NPC'leri takip et
local savedNPCs = {}
local threatNPCs = {}

-- NPC'yi hazırla (highlight ve proximity prompt ekle)
function NPCSaveSystem.SetupNPC(npc, npcType)
	if not npc:FindFirstChild("HumanoidRootPart") then
		warn("NPC'de HumanoidRootPart bulunamadı!")
		return
	end

	local humanoidRootPart = npc.HumanoidRootPart

	-- Highlight ekle
	local highlight = Instance.new("Highlight")
	highlight.Name = "NPCHighlight"
	highlight.Adornee = npc
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0

	if npcType == NPCSaveSystem.NPCTypes.TARGET then
		-- Yeşil highlight (kurtarılacak)
		highlight.FillColor = Color3.fromRGB(0, 255, 0)
		highlight.OutlineColor = Color3.fromRGB(0, 200, 0)

		-- ProximityPrompt ekle
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "SavePrompt"
		prompt.ActionText = "Kurtar"
		prompt.ObjectText = "NPC"
		prompt.MaxActivationDistance = 8
		prompt.HoldDuration = 0.2
		prompt.RequiresLineOfSight = false
		prompt.Parent = humanoidRootPart

		-- E tuşuna basıldığında
		prompt.Triggered:Connect(function(player)
			NPCSaveSystem.SaveNPC(npc, player)
		end)

	elseif npcType == NPCSaveSystem.NPCTypes.THREAT then
		-- Kırmızı highlight (tehlike)
		highlight.FillColor = Color3.fromRGB(255, 0, 0)
		highlight.OutlineColor = Color3.fromRGB(200, 0, 0)

		table.insert(threatNPCs, npc)
	end

	highlight.Parent = npc

	-- NPC'ye tag ekle
	npc:SetAttribute("NPCType", npcType)
end

-- NPC'yi kurtar (ragdoll ile it + player animasyonu)
function NPCSaveSystem.SaveNPC(npc, player)
	if savedNPCs[npc] then
		return -- Zaten kurtarılmış
	end

	-- Kurtarıldı olarak işaretle
	savedNPCs[npc] = true

	-- ProximityPrompt'u kaldır
	local prompt = npc.HumanoidRootPart:FindFirstChild("SavePrompt")
	if prompt then
		prompt.Enabled = false
	end

	-- Highlight'ı değiştir (mavi = kurtarılmış)
	local highlight = npc:FindFirstChild("NPCHighlight")
	if highlight then
		highlight.FillColor = Color3.fromRGB(0, 150, 255)
		highlight.OutlineColor = Color3.fromRGB(0, 100, 200)
	end

	-- Player'ın karakterinin konumunu al
	local playerChar = player.Character
	if not playerChar then return end

	-- PLAYER İTME ANİMASYONU OYNAT
	local humanoid = playerChar:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Client'a animasyon oynama sinyali gönder
		local playPushAnimEvent = ReplicatedStorage:FindFirstChild("PlayPushAnimation")
		if playPushAnimEvent then
			playPushAnimEvent:FireClient(player)
		end
	end

	-- NPC'yi player'dan uzağa doğru it (YUKARI + İLERİ)
	local playerPos = playerChar.HumanoidRootPart.Position
	local npcPos = npc.HumanoidRootPart.Position

	-- Yatay yön (X ve Z düzleminde)
	local horizontalDirection = Vector3.new(
		npcPos.X - playerPos.X,
		0,  -- Y'yi sıfırla
		npcPos.Z - playerPos.Z
	).Unit

	-- YUKARI + İLERİ yön (45 derece yukarı açı)
	local pushDirection = (horizontalDirection + Vector3.new(0, 1, 0)).Unit

	-- Ragdoll ile fırlat
	-- Kuvvet artırıldı: 30 → 50 (daha güçlü itme)
	RagdollModule.PushNPC(npc, pushDirection, 50)

	-- 3 saniye sonra ragdoll'u kapat
	task.delay(3, function()
		if npc and npc.Parent then
			RagdollModule.DisableRagdoll(npc)
		end
	end)

	-- Event fire et (level sistem için)
	local npcSavedEvent = ReplicatedStorage:FindFirstChild("NPCSaved")
	if npcSavedEvent then
		npcSavedEvent:FireAllClients(npc)
	end
end

-- Tüm NPC'leri temizle (level bitişinde)
function NPCSaveSystem.ClearAll()
	savedNPCs = {}
	threatNPCs = {}
end

-- Kurtarılan NPC sayısını al
function NPCSaveSystem.GetSavedCount()
	local count = 0
	for _ in pairs(savedNPCs) do
		count = count + 1
	end
	return count
end

-- Toplam hedef NPC sayısını al
function NPCSaveSystem.GetTotalTargets()
	local count = 0
	for _, npc in ipairs(workspace:GetDescendants()) do
		if npc:IsA("Model") and npc:GetAttribute("NPCType") == NPCSaveSystem.NPCTypes.TARGET then
			count = count + 1
		end
	end
	return count
end

-- Level tamamlandı mı kontrol et
function NPCSaveSystem.IsLevelComplete()
	return NPCSaveSystem.GetSavedCount() >= NPCSaveSystem.GetTotalTargets()
end

return NPCSaveSystem