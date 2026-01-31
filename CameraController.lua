-- CameraController.lua (StarterPlayer > StarterPlayerScripts)
-- Intro (Logo) -> Profesyonel Kamera İnişi -> Countdown -> Oyun Başlangıcı

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

-- AYARLAR
local OYUN_ISMI = "AXOLOTL'S DEV"
local INTRO_SURESI = 2.5 
local CAMERA_START_HEIGHT = 40
local CAMERA_ANIMATION_DURATION = 2.5

-- 1. INTRO GUI OLUŞTURMA FONKSİYONU
local function PlayIntroSequence(onComplete)
	-- Eski intro varsa temizle
	if playerGui:FindFirstChild("IntroGui") then
		playerGui.IntroGui:Destroy()
	end

	local introGui = Instance.new("ScreenGui")
	introGui.Name = "IntroGui"
	introGui.IgnoreGuiInset = true 
	introGui.DisplayOrder = 1000 
	introGui.Parent = playerGui

	-- Beyaz Arka Plan
	local bgFrame = Instance.new("Frame")
	bgFrame.Name = "Background"
	bgFrame.Size = UDim2.new(1, 0, 1, 0)
	bgFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	bgFrame.BorderSizePixel = 0
	bgFrame.Parent = introGui

	-- Logo
	local logoText = Instance.new("TextLabel")
	logoText.Name = "Logo"
	logoText.Text = OYUN_ISMI
	logoText.Size = UDim2.new(0, 600, 0, 100)
	logoText.Position = UDim2.new(0.5, -300, 0.5, -50)
	logoText.BackgroundTransparency = 1
	logoText.Font = Enum.Font.GothamBlack
	logoText.TextColor3 = Color3.new(0, 0, 0)
	logoText.TextSize = 70
	logoText.TextTransparency = 1
	logoText.Parent = bgFrame

	-- Hız Çizgisi
	local speedLine = Instance.new("Frame")
	speedLine.Name = "Line"
	speedLine.BackgroundColor3 = Color3.new(0, 0, 0)
	speedLine.BorderSizePixel = 0
	speedLine.Size = UDim2.new(0, 0, 0, 5)
	speedLine.Position = UDim2.new(0.5, 0, 0.5, 40)
	speedLine.AnchorPoint = Vector2.new(0.5, 0)
	speedLine.Parent = bgFrame

	-- -- ANİMASYONLAR -- --
	logoText.Position = UDim2.new(0.5, -300, 0.5, -20)

	local textTween = TweenService:Create(logoText, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		Position = UDim2.new(0.5, -300, 0.5, -50)
	})
	textTween:Play()

	local lineTween = TweenService:Create(speedLine, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 400, 0, 5)
	})
	task.wait(0.2)
	lineTween:Play()

	task.wait(INTRO_SURESI)

	-- Çıkış Efekti
	local fadeOutInfo = TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)

	TweenService:Create(bgFrame, fadeOutInfo, {BackgroundTransparency = 1}):Play()
	TweenService:Create(logoText, fadeOutInfo, {TextTransparency = 1}):Play()
	TweenService:Create(speedLine, fadeOutInfo, {BackgroundTransparency = 1}):Play()

	wait(0.5)

	if onComplete then onComplete() end

	wait(1)
	if introGui then introGui:Destroy() end
end


-- 2. KAMERA İNİŞİ VE COUNTDOWN
local function StartCameraSequence(character)
	local rootPart = character:WaitForChild("HumanoidRootPart") 
	local humanoid = character:WaitForChild("Humanoid")

	camera.CameraType = Enum.CameraType.Scriptable

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	local blur = Instance.new("BlurEffect")
	blur.Size = 20
	blur.Parent = Lighting

	local startCFrame = rootPart.CFrame * CFrame.new(0, CAMERA_START_HEIGHT, 5) * CFrame.Angles(math.rad(-85), 0, math.rad(5))
	camera.CFrame = startCFrame
	camera.FieldOfView = 110

	local targetCFrame = rootPart.CFrame * CFrame.new(0, 1.5, 0)
	local targetFOV = 70

	local camTweenInfo = TweenInfo.new(CAMERA_ANIMATION_DURATION, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

	local camPosTween = TweenService:Create(camera, camTweenInfo, {CFrame = targetCFrame})
	local camFovTween = TweenService:Create(camera, camTweenInfo, {FieldOfView = targetFOV})
	local blurTween = TweenService:Create(blur, camTweenInfo, {Size = 0})

	camPosTween:Play()
	camFovTween:Play()
	blurTween:Play()

	local countdownGui = Instance.new("ScreenGui")
	countdownGui.Name = "CountdownGui"
	countdownGui.Parent = playerGui

	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(1,0,1,0)
	countLabel.BackgroundTransparency = 1
	countLabel.Font = Enum.Font.GothamBlack
	countLabel.TextSize = 0
	countLabel.TextColor3 = Color3.new(1,1,1)
	countLabel.TextStrokeTransparency = 0.5
	countLabel.Rotation = -15
	countLabel.Parent = countdownGui

	camPosTween.Completed:Connect(function()
		blur:Destroy()

		local function popText(text, color)
			countLabel.Text = text
			countLabel.TextColor3 = color
			countLabel.TextSize = 180
			countLabel.Rotation = math.random(-10, 10)

			local t1 = TweenService:Create(countLabel, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 120, Rotation = 0})
			t1:Play()
		end

		popText("3", Color3.fromRGB(255, 255, 255))
		task.wait(0.8)
		popText("2", Color3.fromRGB(255, 255, 255))
		task.wait(0.8)
		popText("1", Color3.fromRGB(255, 255, 255))
		task.wait(0.8)
		popText("GO!", Color3.fromRGB(255, 255, 255))
		task.wait(0.5)

		countdownGui:Destroy()

		camera.CameraType = Enum.CameraType.Custom
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50

		local gameStartedEvent = ReplicatedStorage:FindFirstChild("GameStarted")
		if gameStartedEvent then gameStartedEvent:FireServer() end
	end)
end


-- 3. EVENTLER

-- A) Level Başlangıcı (Intro + Kamera + Countdown)
local startLevelEvent = ReplicatedStorage:WaitForChild("StartLevelEvent")
startLevelEvent.OnClientEvent:Connect(function(levelIndex)
	local character = player.Character or player.CharacterAdded:Wait()
	PlayIntroSequence(function()
		StartCameraSequence(character)
	end)
end)

-- B) Lobiye Dönüş
local returnToLobbyEvent = ReplicatedStorage:WaitForChild("ReturnToLobbyEvent")
returnToLobbyEvent.OnClientEvent:Connect(function()
	print("🎬 Lobiye dönüş introsu oynatılıyor...")
	PlayIntroSequence(function()
		camera.CameraType = Enum.CameraType.Custom
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	end)
end)

-- C) Oyun İlk Giriş (HIZLANDIRILDI)
task.spawn(function()
	-- PlayerGui'nin hazır olmasını bekle
	player:WaitForChild("PlayerGui")

	-- İntroyu HEMEN başlat (Karakteri bekleme, sadece UI görünsün)
	PlayIntroSequence(function()
		-- Intro bittikten sonra kamerayı kilitle
		camera.CameraType = Enum.CameraType.Custom
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	end)
end)