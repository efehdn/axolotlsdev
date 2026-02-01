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
		prompt.HoldDuration = 0.1 -- Daha hızlı tepki için düşürdüm
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
	npc:SetAttribute("NPCType", npcType)
end

-- NPC'yi kurtar (ragdoll ile it + player animasyonu)
function NPCSaveSystem.SaveNPC(npc, player)
	if savedNPCs[npc] then return end

	-- Kurtarıldı olarak işaretle
	savedNPCs[npc] = true

	-- Prompt'u kapat
	local prompt = npc.HumanoidRootPart:FindFirstChild("SavePrompt")
	if prompt then prompt.Enabled = false end

	-- Highlight'ı değiştir (mavi)
	local highlight = npc:FindFirstChild("NPCHighlight")
	if highlight then
		highlight.FillColor = Color3.fromRGB(0, 150, 255)
		highlight.OutlineColor = Color3.fromRGB(0, 100, 200)
	end

	-- Player animasyonu için sinyal gönder
	local playPushAnimEvent = ReplicatedStorage:FindFirstChild("PlayPushAnimation")
	if playPushAnimEvent then
		playPushAnimEvent:FireClient(player)
	end

	-- [[ FİZİK DÜZELTMESİ ]] --
	local npcRoot = npc:FindFirstChild("HumanoidRootPart")
	if npcRoot then
		-- NPC'nin fizik kontrolünü oyuncuya ver (Anlık tepki için şart!)
		npcRoot:SetNetworkOwner(player)

		-- NPC'yi hafifçe yerden kes (sürtünmeyi engellemek için)
		npcRoot.CFrame = npcRoot.CFrame + Vector3.new(0, 1, 0)
	end

	-- İtme Yönünü Hesapla
	local playerChar = player.Character
	if playerChar and playerChar:FindFirstChild("HumanoidRootPart") then
		local playerPos = playerChar.HumanoidRootPart.Position
		local npcPos = npc.HumanoidRootPart.Position

		local direction = (npcPos - playerPos).Unit 
		-- Yukarı doğru ekstra kuvvet ekle ki güzel uçsun
		local pushDirection = (direction + Vector3.new(0, 0.5, 0)).Unit

		-- İtme gücü
		RagdollModule.PushNPC(npc, pushDirection, 80) -- Gücü 80'e çıkardım
	end

	-- Event fire et (Timer UI güncellemesi için)
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

-- Diğer fonksiyonlar aynen kalabilir...
function NPCSaveSystem.GetSavedCount()
	local count = 0
	for _ in pairs(savedNPCs) do count = count + 1 end
	return count
end

function NPCSaveSystem.GetTotalTargets()
	local count = 0
	for _, npc in ipairs(workspace:GetDescendants()) do
		if npc:IsA("Model") and npc:GetAttribute("NPCType") == NPCSaveSystem.NPCTypes.TARGET then
			count = count + 1
		end
	end
	return count
end

function NPCSaveSystem.IsLevelComplete()
	return NPCSaveSystem.GetSavedCount() >= NPCSaveSystem.GetTotalTargets()
end

return NPCSaveSystem	
