-- TimeSlowModule.lua
-- Oyun dünyasındaki zamanı yavaşlatma sistemi

local TimeSlowModule = {}

-- Varsayılan değerler
local DEFAULT_GRAVITY = 196.2
local DEFAULT_WALKSPEED = 16

-- Aktif yavaşlatma oranı
local currentTimeScale = 1.0
local activeNPCs = {}
local activeProjectiles = {}

-- Zamanı yavaşlat (timeScale: 0.1 = %10 hız, 1.0 = normal hız)
function TimeSlowModule.SetTimeScale(timeScale)
	timeScale = math.clamp(timeScale, 0.01, 1.0)
	currentTimeScale = timeScale

	-- Yerçekimini ayarla
	workspace.Gravity = DEFAULT_GRAVITY * timeScale

	-- Tüm kayıtlı NPC'lerin hızını ayarla
	for npc, originalSpeed in pairs(activeNPCs) do
		if npc and npc:FindFirstChildOfClass("Humanoid") then
			npc:FindFirstChildOfClass("Humanoid").WalkSpeed = originalSpeed * timeScale
		end
	end

	-- Aktif projectile'ları yavaşlat
	for projectile, originalVelocity in pairs(activeProjectiles) do
		if projectile and projectile:IsA("BasePart") then
			local bodyVelocity = projectile:FindFirstChildOfClass("BodyVelocity")
			if bodyVelocity then
				bodyVelocity.Velocity = originalVelocity * timeScale
			end
		end
	end
end

-- NPC'yi sisteme kaydet
function TimeSlowModule.RegisterNPC(npc)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Orijinal hızı sakla
		activeNPCs[npc] = humanoid.WalkSpeed

		-- Şu anki time scale'e göre ayarla
		humanoid.WalkSpeed = humanoid.WalkSpeed * currentTimeScale
	end
end

-- NPC'yi sistemden çıkar
function TimeSlowModule.UnregisterNPC(npc)
	activeNPCs[npc] = nil
end

-- Projectile (mermi, ok vb.) kaydet
function TimeSlowModule.RegisterProjectile(projectile, velocity)
	if projectile:IsA("BasePart") then
		activeProjectiles[projectile] = velocity

		local bodyVelocity = projectile:FindFirstChildOfClass("BodyVelocity")
		if bodyVelocity then
			bodyVelocity.Velocity = velocity * currentTimeScale
		end
	end
end

-- Normal zamana dön
function TimeSlowModule.ResetTime()
	TimeSlowModule.SetTimeScale(1.0)
end

-- Mevcut time scale'i al
function TimeSlowModule.GetTimeScale()
	return currentTimeScale
end

-- Yavaşlatılmış saniye hesapla (UI timer için)
function TimeSlowModule.GetSlowedTime(realSeconds)
	return realSeconds / currentTimeScale
end

return TimeSlowModule
