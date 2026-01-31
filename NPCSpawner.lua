-- NPCSpawner.lua (ModuleScript - ReplicatedStorage'a ekle)
-- Gerçek RIG/DUMMY kullanarak NPC oluşturma ve yönetme sistemi

local NPCSpawner = {}

-- NPC template'leri sakla (performans için)
local targetTemplate = nil  -- Dost NPC (yeşil)
local threatTemplate = nil  -- Düşman NPC (kırmızı)

--[[
	KURULUM:
	
	ReplicatedStorage/
	├── TargetNPCs/ (Klasör) - DOST NPC modelleri buraya
	│   ├── Model1 (R6 Character)
	│   └── Model2 (R6 Character)
	└── ThreatNPCs/ (Klasör) - DÜŞMAN NPC modelleri buraya
	    ├── Enemy1 (R6 Character)
	    └── Enemy2 (R6 Character)
]]

-- NPC template'lerini yükle
function NPCSpawner.LoadTemplate()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	-- DOST NPC Template'i yükle (TargetNPCs klasöründen)
	local targetFolder = ReplicatedStorage:FindFirstChild("TargetNPCs")
	if targetFolder then
		local templates = targetFolder:GetChildren()
		if #templates > 0 then
			-- İlk modeli template olarak kullan (birden fazla varsa random da seçebilirsin)
			targetTemplate = templates[1]
			print("✅ Target NPC Template yüklendi:", targetTemplate.Name)
		else
			warn("⚠️ TargetNPCs klasörü boş!")
		end
	else
		warn("⚠️ ReplicatedStorage'da 'TargetNPCs' klasörü bulunamadı!")
		warn("💡 ReplicatedStorage'a 'TargetNPCs' isimli klasör oluştur ve içine NPC modellerini koy")
	end

	-- DÜŞMAN NPC Template'i yükle (ThreatNPCs klasöründen)
	local threatFolder = ReplicatedStorage:FindFirstChild("ThreatNPCs")
	if threatFolder then
		local templates = threatFolder:GetChildren()
		if #templates > 0 then
			threatTemplate = templates[1]
			print("✅ Threat NPC Template yüklendi:", threatTemplate.Name)
		else
			warn("⚠️ ThreatNPCs klasörü boş!")
		end
	else
		warn("⚠️ ReplicatedStorage'da 'ThreatNPCs' klasörü bulunamadı!")
		warn("💡 ReplicatedStorage'a 'ThreatNPCs' isimli klasör oluştur ve içine NPC modellerini koy")
	end

	-- Eğer hiçbiri yoksa fallback
	if not targetTemplate and not threatTemplate then
		warn("⚠️ Hiçbir template bulunamadı! Varsayılan NPC oluşturuluyor...")
		local basicNPC = NPCSpawner.CreateBasicNPC()
		basicNPC.Name = "BasicNPC"
		targetTemplate = basicNPC
		threatTemplate = basicNPC
	end
end

-- Basit NPC oluştur (template yoksa)
function NPCSpawner.CreateBasicNPC()
	local npc = Instance.new("Model")
	npc.Name = "BasicNPC"

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = npc

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.Parent = npc

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.BrickColor = BrickColor.new("Bright blue")
	torso.Parent = npc

	local rootJoint = Instance.new("Motor6D")
	rootJoint.Name = "Root Joint"
	rootJoint.Part0 = rootPart
	rootJoint.Part1 = torso
	rootJoint.Parent = rootPart

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.BrickColor = BrickColor.new("Bright yellow")
	head.Parent = npc

	local neck = Instance.new("Motor6D")
	neck.Name = "Neck"
	neck.Part0 = torso
	neck.Part1 = head
	neck.C0 = CFrame.new(0, 1, 0)
	neck.C1 = CFrame.new(0, -0.5, 0)
	neck.Parent = torso

	npc.PrimaryPart = rootPart
	return npc
end

-- Yeni NPC oluştur (template'den clone)
function NPCSpawner.CreateNPC(npcType)
	-- NPC tipine göre doğru template'i seç
	local template = nil

	if npcType == "Target" then
		template = targetTemplate
	elseif npcType == "Threat" then
		template = threatTemplate
	end

	-- Eğer template yoksa fallback
	if not template then
		warn("⚠️ Template bulunamadı, varsayılan NPC oluşturuluyor")
		template = NPCSpawner.CreateBasicNPC()
	end

	-- Template'i klonla
	local npc = template:Clone()

	-- Humanoid ayarları
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayDistance = 0
		humanoid.NameDisplayDistance = 0
		humanoid.Health = 100
		humanoid.MaxHealth = 100
		humanoid.WalkSpeed = 0 
		humanoid.JumpPower = 0
		humanoid.PlatformStand = false
	end

	-- Tüm part'ları ayarla
	for _, part in ipairs(npc:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
			part.Anchored = false
			part.CollisionGroup = "NPCs"
		end
	end

	-- HumanoidRootPart özel ayarlar
	local rootPart = npc:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.CanCollide = false
	end

	return npc
end

-- NPC'yi belirli bir yere spawn et (YÖN KONTROLÜ EKLENDI)
function NPCSpawner.SpawnNPC(spawnPart, npcType)
	-- spawnPart artık Part objesi (position ve orientation içeriyor)
	local position = spawnPart.Position
	local orientation = spawnPart.Orientation -- Spawn Part'ın baktığı yön

	local npc = NPCSpawner.CreateNPC(npcType)

	-- Pozisyonu yukarı kaldır (zemine gömülme engellemek için)
	local safePosition = position + Vector3.new(0, 4, 0)

	-- YÖN KONTROLÜ: Spawn Part'ın Orientation'ını kullan
	local rotationCFrame = CFrame.Angles(0, math.rad(orientation.Y), 0)

	-- NPC'yi yerleştir (pozisyon + yön)
	npc:PivotTo(CFrame.new(safePosition) * rotationCFrame)

	-- NPC tipini attribute olarak kaydet
	npc:SetAttribute("NPCType", npcType)
	npc.Name = npcType .. "_NPC"

	return npc
end

-- Karaktere kıyafet/aksesuar ekle
function NPCSpawner.AddClothing(npc, clothingAssetIds)
	if not npc or not npc:IsA("Model") then return end

	if clothingAssetIds.Shirt then
		local shirt = Instance.new("Shirt")
		shirt.ShirtTemplate = "rbxassetid://" .. clothingAssetIds.Shirt
		shirt.Parent = npc
	end

	if clothingAssetIds.Pants then
		local pants = Instance.new("Pants")
		pants.PantsTemplate = "rbxassetid://" .. clothingAssetIds.Pants
		pants.Parent = npc
	end
end

-- NPC'nin rengini değiştir
function NPCSpawner.SetNPCColor(npc, color)
	for _, part in ipairs(npc:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.BrickColor = BrickColor.new(color)
		end
	end
end

return NPCSpawner