-- FirstPersonCamera.lua (StarterPlayer > StarterPlayerScripts - LocalScript)
-- First Person görünüm - Kafa, saç ve görüşü engelleyen aksesuarlar gizlenir, vücut görünür

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Kamera ayarları
local CAMERA_OFFSET = Vector3.new(0, 0.3, 0) -- Yükseltildi: Gövdeyle çakışmayı önler
local HEAD_TRANSPARENCY = 1 -- Kafa tamamen görünmez

local function updateBodyVisibility(character)
	if not character then return end

	local head = character:FindFirstChild("Head")

	-- 1. Parçaları (Body Parts) Kontrol Et
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			if part == head then
				-- Kafayı gizle
				part.LocalTransparencyModifier = HEAD_TRANSPARENCY

				-- Yüz (Face) decal'ini gizle
				local face = part:FindFirstChild("face")
				if face and face:IsA("Decal") then
					face.Transparency = 1
				end
			elseif part.Name ~= "HumanoidRootPart" and part.Parent == character then
				-- Gövde, Kollar, Bacaklar -> GÖRÜNÜR
				part.LocalTransparencyModifier = 0
			end
		end
	end

	-- 2. Aksesuarları (Hair, Hat, Neck, etc.) Kontrol Et
	for _, accessory in ipairs(character:GetChildren()) do
		if accessory:IsA("Accessory") then
			local handle = accessory:FindFirstChild("Handle")
			if handle then
				-- Aksesuarın türüne veya ismine göre karar ver
				local accType = accessory.AccessoryType

				local shouldHide = false

				-- Görüşü engelleyebilecek aksesuar tiplerini buraya ekliyoruz
				if accType == Enum.AccessoryType.Hair or 
					accType == Enum.AccessoryType.Hat or 
					accType == Enum.AccessoryType.Face or
					accType == Enum.AccessoryType.Neck or -- Boyun aksesuarları (Atkı, Kolye vb.)
					accType == Enum.AccessoryType.Shoulder or -- Bazen omuzluklar da girebilir
					accType == Enum.AccessoryType.Eyebrow or
					accType == Enum.AccessoryType.Eyelash then
					shouldHide = true
				end

				-- Yedek kontrol: Handle içindeki attachment isminde kilit kelimeler geçiyor mu?
				local attachment = handle:FindFirstChildOfClass("Attachment")
				if attachment then
					local attName = attachment.Name
					if string.find(attName, "Hair") or 
						string.find(attName, "Hat") or 
						string.find(attName, "Face") or 
						string.find(attName, "Neck") or -- NeckAttachment kontrolü
						string.find(attName, "Mouth") then
						shouldHide = true
					end
				end

				if shouldHide then
					handle.LocalTransparencyModifier = 1 -- GİZLE (Görüşü kapatmasın)
				else
					handle.LocalTransparencyModifier = 0 -- GÖSTER (Sırt çantası, kanat, bel silahı vb.)
				end
			end
		end
	end
end

-- Her karede (frame) çalışır
RunService.RenderStepped:Connect(function()
	local character = player.Character
	if character and player.CameraMode == Enum.CameraMode.LockFirstPerson then
		updateBodyVisibility(character)

		-- Kamera offset ayarı (Kafanın biraz yukarısında tut)
		if camera.CFrame and character:FindFirstChild("Head") then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.CameraOffset = CAMERA_OFFSET
			end
		end
	end
end)

-- Karakter yüklendiğinde ayarları yap
local function onCharacterAdded(character)
	character:WaitForChild("HumanoidRootPart")
	character:WaitForChild("Head")

	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 0.5

	-- Offset'i hemen uygula
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.CameraOffset = CAMERA_OFFSET
end

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
	onCharacterAdded(player.Character)
end