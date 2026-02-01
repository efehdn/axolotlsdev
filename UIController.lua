-- UIController.lua (StarterPlayer > StarterPlayerScripts)
-- Timer UI ve Level sonuç ekranları

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI oluştur
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Timer Frame (üstte ortada)
local timerFrame = Instance.new("Frame")
timerFrame.Name = "TimerFrame"
timerFrame.Size = UDim2.new(0, 200, 0, 60)
timerFrame.Position = UDim2.new(0.5, -100, 0, 20)
timerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
timerFrame.BackgroundTransparency = 0.3
timerFrame.BorderSizePixel = 0
timerFrame.Visible = false
timerFrame.Parent = screenGui

-- Timer corner
local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(0, 12)
timerCorner.Parent = timerFrame

-- Timer Text
local timerText = Instance.new("TextLabel")
timerText.Name = "TimerText"
timerText.Size = UDim2.new(1, 0, 1, 0)
timerText.BackgroundTransparency = 1
timerText.Font = Enum.Font.GothamBold
timerText.TextSize = 32
timerText.TextColor3 = Color3.fromRGB(255, 255, 255)
timerText.Text = "30.0"
timerText.Parent = timerFrame

-- NPC Counter (sol üstte)
local npcFrame = Instance.new("Frame")
npcFrame.Name = "NPCFrame"
npcFrame.Size = UDim2.new(0, 180, 0, 50)
npcFrame.Position = UDim2.new(0, 20, 0, 20)
npcFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
npcFrame.BackgroundTransparency = 0.3
npcFrame.BorderSizePixel = 0
npcFrame.Visible = false
npcFrame.Parent = screenGui

local npcCorner = Instance.new("UICorner")
npcCorner.CornerRadius = UDim.new(0, 12)
npcCorner.Parent = npcFrame

local npcText = Instance.new("TextLabel")
npcText.Name = "NPCText"
npcText.Size = UDim2.new(1, 0, 1, 0)
npcText.BackgroundTransparency = 1
npcText.Font = Enum.Font.Gotham
npcText.TextSize = 20
npcText.TextColor3 = Color3.fromRGB(255, 255, 255)
npcText.Text = "Saved: 0/2"
npcText.Parent = npcFrame

-- Result Screen (level bitişi)
local resultFrame = Instance.new("Frame")
resultFrame.Name = "ResultFrame"
resultFrame.Size = UDim2.new(0, 400, 0, 300)
resultFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
resultFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
resultFrame.BackgroundTransparency = 0.1
resultFrame.BorderSizePixel = 0
resultFrame.Visible = false
resultFrame.Parent = screenGui

local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 20)
resultCorner.Parent = resultFrame

local resultTitle = Instance.new("TextLabel")
resultTitle.Name = "ResultTitle"
resultTitle.Size = UDim2.new(1, 0, 0, 80)
resultTitle.BackgroundTransparency = 1
resultTitle.Font = Enum.Font.GothamBold
resultTitle.TextSize = 48
resultTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
resultTitle.Text = "LEVEL COMPLETE!"
resultTitle.Parent = resultFrame

local resultSubtitle = Instance.new("TextLabel")
resultSubtitle.Name = "ResultSubtitle"
resultSubtitle.Size = UDim2.new(1, 0, 0, 60)
resultSubtitle.Position = UDim2.new(0, 0, 0, 80)
resultSubtitle.BackgroundTransparency = 1
resultSubtitle.Font = Enum.Font.Gotham
resultSubtitle.TextSize = 24
resultSubtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
resultSubtitle.Text = "All NPCs saved successfully"
resultSubtitle.Parent = resultFrame

-- Timer güncelleme eventi
local updateTimerEvent = ReplicatedStorage:WaitForChild("UpdateTimer")
updateTimerEvent.OnClientEvent:Connect(function(timeRemaining)
	timerFrame.Visible = true
	npcFrame.Visible = true

	-- Timer'ı güncelle (SANİYE:MİLİSANİYE formatında)
	local seconds = math.floor(timeRemaining)
	local milliseconds = math.floor((timeRemaining - seconds) * 100)
	timerText.Text = string.format("%d:%02d", seconds, milliseconds)

	-- Kalan süre azaldıkça renk değiştir
	if timeRemaining <= 5 then
		timerText.TextColor3 = Color3.fromRGB(255, 50, 50) -- Kırmızı
		-- Yanıp sönme efekti
		if timeRemaining % 1 < 0.5 then
			timerFrame.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
		else
			timerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		end
	elseif timeRemaining <= 10 then
		timerText.TextColor3 = Color3.fromRGB(255, 200, 50) -- Turuncu
	else
		timerText.TextColor3 = Color3.fromRGB(255, 255, 255) -- Beyaz
		timerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	end
end)

-- NPC kurtarma eventi
local npcSavedEvent = ReplicatedStorage:WaitForChild("NPCSaved")
npcSavedEvent.OnClientEvent:Connect(function(npc)
	-- NPC sayacını güncelle (basit bir yöntem)
	local saved = 0
	local total = 0

	for _, npc in ipairs(workspace:GetChildren()) do
		if npc.Name == "NPC" and npc:GetAttribute("NPCType") == "Target" then
			total = total + 1
			local highlight = npc:FindFirstChild("NPCHighlight")
			if highlight and highlight.FillColor == Color3.fromRGB(0, 150, 255) then
				saved = saved + 1
			end
		end
	end

	npcText.Text = string.format("Saved: %d/%d", saved, total)
end)

-- Level bitiş eventi
local endLevelEvent = ReplicatedStorage:WaitForChild("EndLevelEvent")
endLevelEvent.OnClientEvent:Connect(function(success, levelIndex)
	-- Timer'ı gizle
	timerFrame.Visible = false
	npcFrame.Visible = false

	-- Sonuç ekranını göster
	resultFrame.Visible = true

	if success then
		resultTitle.Text = "LEVEL COMPLETE!"
		resultTitle.TextColor3 = Color3.fromRGB(100, 255, 100)
		resultSubtitle.Text = "All NPCs saved successfully!"
	else
		resultTitle.Text = "LEVEL FAILED"
		resultTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
		resultSubtitle.Text = "Time ran out..."
	end

	-- Fade in animasyonu
	resultFrame.BackgroundTransparency = 1
	local tween = TweenService:Create(resultFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0.1})
	tween:Play()

	-- 4 saniye sonra gizle
	task.wait(4)
	resultFrame.Visible = false
end)
