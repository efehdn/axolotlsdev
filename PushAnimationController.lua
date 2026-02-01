-- PushAnimationController.lua (StarterPlayer > StarterPlayerScripts - LocalScript)
-- Player'ın NPC'yi iterken oynayacağı animasyon

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

--[[
	İTME ANİMASYONU EKLEME:
	
	1. Roblox Studio → Avatar → Animation Editor
	2. Bir itme animasyonu oluştur (eller öne doğru, vücut hafif öne eğilmiş)
	3. Animasyonu yayınla (Publish to Roblox)
	4. Asset ID'yi kopyala
	5. Aşağıdaki PUSH_ANIMATION_ID'ye yapıştır
	
	VEYA Marketplace'den hazır animasyon:
	- Toolbox → Animations → "push animation" ara
	- Beğendiğin animasyonu seç
	- Asset ID'sini al
]]

-- ANİMASYON AYARLARI
local PUSH_ANIMATION_ID = "rbxassetid://71345108336102" -- BURAYA ANİMASYON ID'Sİ EKLE (0 = yok)
local ANIMATION_SPEED = 1 -- Animasyon hızı (1.0 = normal, 1.5 = %50 daha hızlı)

-- Animasyon instance'ı
local pushAnimation = nil
local pushAnimTrack = nil

-- Karakter hazır olduğunda animasyonu yükle
local function SetupAnimation(character)
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	-- Eğer animasyon ID yoksa (0 ise) basit bir varsayılan hareket yap
	if PUSH_ANIMATION_ID == "rbxassetid://0" then
		print("⚠️ İtme animasyonu ayarlanmamış (ID = 0)")
		return
	end

	-- Animasyonu oluştur ve yükle
	pushAnimation = Instance.new("Animation")
	pushAnimation.AnimationId = PUSH_ANIMATION_ID

	pushAnimTrack = animator:LoadAnimation(pushAnimation)
	pushAnimTrack.Priority = Enum.AnimationPriority.Action -- Yüksek öncelik

	print("✅ İtme animasyonu yüklendi")
end

-- Animasyonu oynat
local function PlayPushAnimation()
	if pushAnimTrack then
		-- Animasyonu oynat
		pushAnimTrack:Play()
		pushAnimTrack:AdjustSpeed(ANIMATION_SPEED)

		print("🎬 İtme animasyonu oynatılıyor")
	else
		-- Animasyon yoksa basit bir varsayılan hareket
		-- Karakteri hafifçe öne eğ
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local rootPart = character:FindFirstChild("HumanoidRootPart")

			if humanoid and rootPart then
				-- Basit bir "itme" hareketi simülasyonu
				-- Karakteri kısa süreliğine öne doğru hareket ettir
				local originalCFrame = rootPart.CFrame

				-- Öne doğru küçük bir hareket
				rootPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -0.5)

				-- 0.2 saniye sonra eski haline dön
				task.delay(0.2, function()
					if rootPart and rootPart.Parent then
						rootPart.CFrame = originalCFrame
					end
				end)

				print("🎬 Varsayılan itme hareketi (animasyon yok)")
			end
		end
	end
end

-- Server'dan animasyon oynatma sinyali
local playPushAnimEvent = ReplicatedStorage:FindFirstChild("PlayPushAnimation")
if not playPushAnimEvent then
	playPushAnimEvent = Instance.new("RemoteEvent")
	playPushAnimEvent.Name = "PlayPushAnimation"
	playPushAnimEvent.Parent = ReplicatedStorage
end

playPushAnimEvent.OnClientEvent:Connect(function()
	PlayPushAnimation()
end)

-- Karakter spawn olduğunda animasyonu hazırla
player.CharacterAdded:Connect(function(character)
	wait(0.5) -- Humanoid ve Animator yüklensin
	SetupAnimation(character)
end)

-- İlk karakterde setup
if player.Character then
	SetupAnimation(player.Character)
end

print("✅ Push Animation Controller yüklendi")
print("💡 Animasyon ID:", PUSH_ANIMATION_ID)
if PUSH_ANIMATION_ID == "rbxassetid://0" then
	print("⚠️ Animasyon eklemek için PUSH_ANIMATION_ID'yi düzenle")
end
