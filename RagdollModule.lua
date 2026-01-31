-- RagdollModule.lua
-- R6 karakterler için çalışan ragdoll sistemi

local RagdollModule = {}

-- Motor6D'leri saklamak için tablo
local savedMotors = {}

-- R6 Motor6D isimleri ve parent-child ilişkileri
local R6_MOTORS = {
	{Name = "Neck", Part0 = "Torso", Part1 = "Head"},
	{Name = "Left Shoulder", Part0 = "Torso", Part1 = "Left Arm"},
	{Name = "Right Shoulder", Part0 = "Torso", Part1 = "Right Arm"},
	{Name = "Left Hip", Part0 = "Torso", Part1 = "Left Leg"},
	{Name = "Right Hip", Part0 = "Torso", Part1 = "Right Leg"}
}

-- Ragdoll aktif et
function RagdollModule.EnableRagdoll(character)
	if not character or not character:FindFirstChild("Torso") then
		warn("Character veya Torso bulunamadı!")
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Karakteri "öldür" ama sağlığı koru
		humanoid.PlatformStand = true
		humanoid.AutoRotate = false
	end

	-- Motor6D'leri sakla ve BallSocketConstraint ile değiştir
	savedMotors[character] = {}

	for _, motorData in ipairs(R6_MOTORS) do
		local part0 = character:FindFirstChild(motorData.Part0)
		local part1 = character:FindFirstChild(motorData.Part1)

		if part0 and part1 then
			-- Motor6D'yi bul
			local motor = part0:FindFirstChild(motorData.Name)

			if motor and motor:IsA("Motor6D") then
				-- Motor bilgilerini sakla
				table.insert(savedMotors[character], {
					Motor = motor,
					Parent = motor.Parent,
					Part0 = motor.Part0,
					Part1 = motor.Part1,
					C0 = motor.C0,
					C1 = motor.C1
				})

				-- Attachment'lar oluştur
				local att0 = Instance.new("Attachment")
				att0.Name = motorData.Name .. "Att0"
				att0.CFrame = motor.C0
				att0.Parent = part0

				local att1 = Instance.new("Attachment")
				att1.Name = motorData.Name .. "Att1"
				att1.CFrame = motor.C1
				att1.Parent = part1

				-- BallSocketConstraint oluştur
				local ballSocket = Instance.new("BallSocketConstraint")
				ballSocket.Name = motorData.Name .. "BallSocket"
				ballSocket.Attachment0 = att0
				ballSocket.Attachment1 = att1
				ballSocket.LimitsEnabled = true
				ballSocket.TwistLimitsEnabled = true
				ballSocket.UpperAngle = 45 -- Hareket sınırları
				ballSocket.TwistUpperAngle = 45
				ballSocket.TwistLowerAngle = -45
				ballSocket.Parent = part0

				-- Motor6D'yi devre dışı bırak (silme, geri almak için)
				motor.Enabled = false
			end
		end
	end

	-- Vücudu aktif hale getir
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide = true
		end
	end
end

-- Ragdoll'u kapat ve normal harekete dön
function RagdollModule.DisableRagdoll(character)
	if not character or not savedMotors[character] then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
	end

	-- BallSocketConstraint'leri ve Attachment'ları temizle
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("BallSocketConstraint") or 
					(child:IsA("Attachment") and string.find(child.Name, "Att")) then
					child:Destroy()
				end
			end

			if part.Name ~= "HumanoidRootPart" then
				part.CanCollide = false
			end
		end
	end

	-- Motor6D'leri geri yükle
	for _, motorInfo in ipairs(savedMotors[character]) do
		if motorInfo.Motor then
			motorInfo.Motor.Enabled = true
		end
	end

	savedMotors[character] = nil
end

-- NPC'yi belirli bir yöne doğru ragdoll ile fırlat
function RagdollModule.PushNPC(character, direction, force)
	force = force or 50

	RagdollModule.EnableRagdoll(character)

	-- Torso'ya kuvvet uygula
	local torso = character:FindFirstChild("Torso")
	if torso then
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bodyVelocity.Velocity = direction.Unit * force
		bodyVelocity.Parent = torso

		-- 0.5 saniye sonra BodyVelocity'yi kaldır
		task.delay(0.5, function()
			if bodyVelocity and bodyVelocity.Parent then
				bodyVelocity:Destroy()
			end
		end)
	end
end

return RagdollModule