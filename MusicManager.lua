-- MusicManager.lua (StarterPlayer > StarterPlayerScripts - LocalScript)
-- Oyunun farklı bölümleri için müzik kontrolü

local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

--[[
    MÜZİK ASSET ID'LERİ:
    
    Bu bölümü kendi müzik ID'lerinle değiştir!
    
    Müzik bulmak için:
    1. Roblox Toolbox → Audio sekmesi
    2. "background music", "ambient music" ara
    3. Beğendiğin müziği seç
    4. Asset ID'yi kopyala (örnek: 1234567890)
    5. Aşağıya yapıştır
]]

local MUSIC_IDS = {
	Lobby = 1838657604,      -- Sakin, bekleyiş müziği (değiştir!)
	Loading = 1839029344,    -- Kısa, heyecanlı müzik (değiştir!)
	Level = 1838661730,      -- Yoğun, aksiyonlu müzik (değiştir!)
}

-- Müzik ayarları
local VOLUME = 0.3 -- Ses seviyesi (0.0 - 1.0)
local FADE_TIME = 1 -- Müzik geçiş süresi (saniye)

-- Aktif müzik
local currentMusic = nil
local currentMusicType = nil

-- Müzik oluştur
local function CreateMusic(musicId, musicName)
	local music = Instance.new("Sound")
	music.Name = musicName
	music.SoundId = "rbxassetid://" .. musicId
	music.Volume = 0 -- Başlangıçta sessiz (fade in için)
	music.Looped = true
	music.Parent = SoundService

	return music
end

-- Müziği fade in/out ile değiştir
local function PlayMusic(musicType)
	-- Eğer aynı müzik çalıyorsa değiştirme
	if currentMusicType == musicType and currentMusic and currentMusic.IsPlaying then
		return
	end

	print("🎵 Müzik değiştiriliyor:", musicType)

	-- Eski müziği fade out
	if currentMusic then
		local fadeOutTween = game:GetService("TweenService"):Create(
			currentMusic,
			TweenInfo.new(FADE_TIME),
			{Volume = 0}
		)
		fadeOutTween:Play()
		fadeOutTween.Completed:Connect(function()
			currentMusic:Stop()
			currentMusic:Destroy()
		end)
	end

	-- Yeni müziği oluştur ve fade in
	local musicId = MUSIC_IDS[musicType]
	if not musicId then
		warn("⚠️ Müzik ID bulunamadı:", musicType)
		return
	end

	currentMusic = CreateMusic(musicId, musicType .. "Music")
	currentMusicType = musicType
	currentMusic:Play()

	local fadeInTween = game:GetService("TweenService"):Create(
		currentMusic,
		TweenInfo.new(FADE_TIME),
		{Volume = VOLUME}
	)
	fadeInTween:Play()
end

-- Müziği durdur
local function StopMusic()
	if currentMusic then
		local fadeOutTween = game:GetService("TweenService"):Create(
			currentMusic,
			TweenInfo.new(FADE_TIME),
			{Volume = 0}
		)
		fadeOutTween:Play()
		fadeOutTween.Completed:Connect(function()
			currentMusic:Stop()
			currentMusic:Destroy()
			currentMusic = nil
			currentMusicType = nil
		end)
	end
end

-- Loading screen müziği
local showLoadingEvent = ReplicatedStorage:WaitForChild("ShowLoadingScreen")
showLoadingEvent.OnClientEvent:Connect(function(show, text)
	if show then
		PlayMusic("Loading")
	else
		-- Loading bitince lobby veya level müziğine geç
		-- Bu, level/lobby kontrolü ile belirlenir
	end
end)

-- Level başlangıcı - Level müziği
local startLevelEvent = ReplicatedStorage:WaitForChild("StartLevelEvent")
startLevelEvent.OnClientEvent:Connect(function(levelIndex)
	PlayMusic("Level")
end)

-- Level bitişi - Lobby müziği
local endLevelEvent = ReplicatedStorage:WaitForChild("EndLevelEvent")
endLevelEvent.OnClientEvent:Connect(function(success, levelIndex)
	wait(3) -- Sonuç ekranı biraz gösterilsin
	PlayMusic("Lobby")
end)

-- Karakter spawn olduğunda (ilk giriş veya respawn)
player.CharacterAdded:Connect(function(character)
	-- Karakterin nerede spawn olduğunu kontrol et
	wait(1) -- Karakter tam yüklensin

	local rootPart = character:WaitForChild("HumanoidRootPart")
	local position = rootPart.Position

	-- Lobby'de mi kontrol et (basit mesafe kontrolü)
	local lobby = workspace:FindFirstChild("Lobby")
	if lobby then
		local lobbySpawn = lobby:FindFirstChild("SpawnLocation")
		if lobbySpawn then
			local distance = (position - lobbySpawn.Position).Magnitude
			if distance < 100 then -- 100 stud içindeyse lobby
				PlayMusic("Lobby")
				return
			end
		end
	end

	-- Varsayılan: Lobby müziği
	PlayMusic("Lobby")
end)

-- İlk spawn (oyun başlangıcı)
if player.Character then
	wait(2) -- Loading screen kapansın
	PlayMusic("Lobby")
end

print("✅ Music Manager yüklendi")
print("💡 Müzik ID'lerini değiştirmeyi unutma!")