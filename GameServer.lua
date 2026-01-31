-- GameServer.lua (ServerScriptService içinde normal Script olarak)
-- Ana oyun mantığı ve player yönetimi

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Modülleri yükle
local LevelManager = require(ServerScriptService:WaitForChild("LevelManager"))

-- RemoteEvent'leri oluştur (eğer yoksa)
local function CreateRemoteEvent(name)
	local existingEvent = ReplicatedStorage:FindFirstChild(name)
	if existingEvent then
		return existingEvent
	end

	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = name
	remoteEvent.Parent = ReplicatedStorage
	return remoteEvent
end

-- Gerekli event'leri oluştur
CreateRemoteEvent("StartLevelEvent")
CreateRemoteEvent("UpdateTimer")
CreateRemoteEvent("EndLevelEvent")
CreateRemoteEvent("NPCSaved")

-- Level başlatma eventi (UI'dan gelecek)
local startLevelRemote = CreateRemoteEvent("RequestStartLevel")
startLevelRemote.OnServerEvent:Connect(function(player, levelIndex)
	print("🎮 Player", player.Name, "level başlatıyor:", levelIndex)
	LevelManager.StartLevel(player, levelIndex)
end)

-- Player katıldığında
Players.PlayerAdded:Connect(function(player)
	print("👋 Player katıldı:", player.Name)

	player.CharacterAdded:Connect(function(character)
		print("🚶 Karakter spawn oldu:", player.Name)

		-- Artık otomatik level başlatmıyoruz
		-- Player lobby'deki portallara basacak
		print("🏛️ Player lobby'de, portal seçebilir")
	end)
end)

-- Player ayrıldığında temizlik
Players.PlayerRemoving:Connect(function(player)
	print("👋 Player ayrıldı:", player.Name)
	-- Level'ı temizle
	LevelManager.EndLevel(player, false)
end)

print("✅ GameServer başlatıldı!")
print("⚙️ Sistem hazır, oyuncular bekleniyor...")