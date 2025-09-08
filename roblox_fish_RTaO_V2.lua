local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Create GUI Window (mobile-friendly size, no tab dropdown, slightly transparent)
local Window = WindUI:CreateWindow({
    Title = "RTaO Dev - Fish It",
    Icon = "rbxassetid://80647723335499",
    IconThemed = true,
    Author = "VERSION: BETA",
    Folder = "RTaO Dev",
    Size = UDim2.new(0, 380, 0, 260), -- ✅ Lebih kecil biar pas di Android
    Theme = "Dark" -- Bisa ganti "Light" kalau silau
})

-- Info Tab
local InfoTab = Window:Tab({ Title = "Info", Icon = "info" })

InfoTab:Paragraph({
    Title = "Welcome to RTaO Script",
    Desc = "Version Game: Fish it.",
    Image = "rbxassetid://121989361864413",
    ImageSize = 30,
    Thumbnail = "rbxassetid://115270950864592",
    ThumbnailSize = 170
})

InfoTab:Button({
    Title = "Join Our Discord",
    Desc = "Click to copy our Discord invite link.",
    Callback = function()
        setclipboard("https://discord.gg/EH23mXVqce")
        WindUI:Notify({
            Title = "Discord",
            Content = "Discord invite link copied to clipboard!",
            Duration = 5
        })
    end
})

-- Auto Farm Tab
local AutofarmTab = Window:Tab({ 
    Title = "Auto Farm", 
    Icon = "fish"
})

-- Toggle Fishing Radar
AutofarmTab:Toggle({
    Title = "Fishing Radar",
    Desc = "Bypass Fishing Radar",
    Default = false,
    Callback = function(state)
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Lighting = game:GetService("Lighting")

        local Replion = require(ReplicatedStorage.Packages.Replion)
        local Net = require(ReplicatedStorage.Packages.Net)
        local SPR = require(ReplicatedStorage.Packages.spr)
        local Soundbook = require(ReplicatedStorage.Shared.Soundbook)
        local ClientTime = require(ReplicatedStorage.Controllers.ClientTimeController)
        local TextNotification = require(ReplicatedStorage.Controllers.TextNotificationController)

        local UpdateFishingRadar = Net:RemoteFunction("UpdateFishingRadar")

        local function SetRadar(enable)
            local clientData = Replion.Client:GetReplion("Data")
            if not clientData then return end

            if clientData:Get("RegionsVisible") ~= enable then
                if UpdateFishingRadar:InvokeServer(enable) then
                    Soundbook.Sounds.RadarToggle:Play().PlaybackSpeed = 1 + math.random() * 0.3

                    -- Adjust lighting when enabling
                    if enable then
                        local ccEffect = Lighting:FindFirstChildWhichIsA("ColorCorrectionEffect")
                        if ccEffect then
                            SPR.stop(ccEffect)
                            local lightingProfile = ClientTime:_getLightingProfile()
                            local targetSettings = (lightingProfile and lightingProfile.ColorCorrection) or {}
                            targetSettings.Brightness = targetSettings.Brightness or 0.04
                            targetSettings.TintColor = targetSettings.TintColor or Color3.fromRGB(255, 255, 255)

                            ccEffect.TintColor = Color3.fromRGB(42, 226, 118)
                            ccEffect.Brightness = 0.4
                            SPR.target(ccEffect, 1, 1, targetSettings)
                        end

                        SPR.stop(Lighting)
                        Lighting.ExposureCompensation = 1
                        SPR.target(Lighting, 1, 2, {ExposureCompensation = 0})
                    end

                    -- Notification
                    TextNotification:DeliverNotification({
                        Type = "Text",
                        Text = "Radar: "..(enable and "Enabled" or "Disabled"),
                        TextColor = enable and {R = 9, G = 255, B = 0} or {R = 255, G = 0, B = 0}
                    })
                end
            end
        end

        -- Toggle ON/OFF
        if state then
            SetRadar(true)
        else
            SetRadar(false)
        end
    end
})

-- Paragraph with description
AutofarmTab:Paragraph({
    Title = "Auto Farm",
})

-- ===== Animasi Setup =====
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Buat animator (kalau belum ada)
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

-- List animasi
local animations = {
    idle = "rbxassetid://96586569072385", -- idle pegang pancing
    cast = "rbxassetid://180435571",      -- lempar kail
    wait = "rbxassetid://92624107165273", -- nunggu tarik ikan
    reel = "rbxassetid://134965425664034" -- narik kail/ikan
}

-- Fungsi untuk load animasi
local function loadAnim(id)
    local anim = Instance.new("Animation")
    anim.AnimationId = id
    return animator:LoadAnimation(anim)
end

-- Load semua animasi
local animTracks = {
    idle = loadAnim(animations.idle),
    cast = loadAnim(animations.cast),
    wait = loadAnim(animations.wait),
    reel = loadAnim(animations.reel)
}

-- ===== Auto Fish Setup =====
-- Default delay variables
local delayTime = 1.6 -- default delay
local minSafeDelay = 1.5 -- minimum safe delay to prevent Auto Fish errors
local delayInputValue = tostring(delayTime)

-- Auto Fish Toggle
local autoFishEnabled = false
AutofarmTab:Toggle({
    Title = "Auto Fish",
    Desc = "Automatically fish and instant fishing",
    Value = false,
    Callback = function(state)
        autoFishEnabled = state
        if state then
            WindUI:Notify({
                Title = "Auto Fish",
                Content = "Enabled",
                Duration = 3
            })
            
            task.spawn(function()
                while autoFishEnabled do
                    local success, err = pcall(function()
                        local ReplicatedStorage = game:GetService("ReplicatedStorage")
                        local EquipRod = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipToolFromHotbar"]
                        local StartMinigame = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/RequestFishingMinigameStarted"]
                        local ChargeRod = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/ChargeFishingRod"]
                        
                        -- Hentikan semua animasi sebelum memulai siklus baru
                        for _, track in pairs(animTracks) do
                            track:Stop()
                        end
                        
                        -- Tahap 1: Animasi idle + Equip rod
                        animTracks.idle:Play()
                        EquipRod:FireServer(1)
                        task.wait(0.2)
                        
                        -- Tahap 2: Animasi cast + Start minigame
                        animTracks.idle:Stop()
                        animTracks.cast:Play()
                        StartMinigame:InvokeServer(-0.7499996423721313, 1)
                        task.wait(0.2)
                        
                        -- Tahap 3: Animasi wait (sesuaikan durasi jika perlu)
                        animTracks.cast:Stop()
                        animTracks.wait:Play()
                        task.wait(0.5) -- Durasi singkat untuk animasi wait
                        
                        -- Tahap 4: Animasi reel + Charge rod
                        animTracks.wait:Stop()
                        animTracks.reel:Play()
                        ChargeRod:InvokeServer(workspace:GetServerTimeNow())
                        task.wait(0.2)
                        
                        -- Pastikan minigame selesai
                        StartMinigame:InvokeServer(-0.7499996423721313, 1)
                        task.wait(0.2)
                        
                        -- Biarkan animasi reel selesai sebelum siklus berikutnya
                        task.wait(1.5) -- Waktu tambahan untuk menyelesaikan animasi reel
                    end)
                    
                    if not success then
                        warn("Auto Fish error:", err)
                    end
                    
                    -- Gunakan delay aman
                    local appliedDelay = math.max(delayTime, minSafeDelay)
                    task.wait(appliedDelay)
                end
            end)
        else
            -- Hentikan semua animasi saat Auto Fish dimatikan
            for _, track in pairs(animTracks) do
                track:Stop()
            end
            
            WindUI:Notify({
                Title = "Auto Fish",
                Content = "Disabled",
                Duration = 3
            })
        end
    end
})

-- ===== Services =====
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local camera = Workspace.CurrentCamera

-- ===== Remote =====
local REEquipToolFromHotbar = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipToolFromHotbar"]
local REFishingCompleted = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/FishingCompleted"]

-- ===== Auto Fishing v2 (Hold Screen) =====
local autoHoldEnabled = false
AutofarmTab:Toggle({
    Title = "Auto Fishing v2",
    Value = false,
    Callback = function(state)
        autoHoldEnabled = state

        if state then
            WindUI:Notify({
                Title = "Auto Fishing v2",
                Content = "Enabled",
                Duration = 3
            })

            task.spawn(function()
                local holdDuration = 0.4
                local loopDelay = 0.2

                while autoHoldEnabled do
                    pcall(function()
                        -- Equip rod slot 1
                        REEquipToolFromHotbar:FireServer(1)

                        -- Klik pojok kiri bawah
                        local clickX = 5
                        local clickY = camera.ViewportSize.Y - 5
                        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
                        task.wait(holdDuration)
                        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
                    end)

                    task.wait(loopDelay)
                    RunService.Heartbeat:Wait()
                end
            end)
        else
            WindUI:Notify({
                Title = "Auto Fishing v2",
                Content = "Disabled",
                Duration = 3
            })
        end
    end
})

-- ===== Auto Instant Fish =====
local autoInstantFishEnabled = false
AutofarmTab:Toggle({
    Title = "Auto Instant Fish",
    Desc = "Automatically completes fishing instantly",
    Value = false,
    Callback = function(state)
        autoInstantFishEnabled = state

        if state then
            WindUI:Notify({
                Title = "Auto Instant Fish",
                Content = "Enabled",
                Duration = 3
            })

            task.spawn(function()
                while autoInstantFishEnabled do
                    pcall(function()
                        REFishingCompleted:FireServer()
                    end)
                    task.wait(0.1)
                end
            end)
        else
            WindUI:Notify({
                Title = "Auto Instant Fish",
                Content = "Disabled",
                Duration = 3
            })
        end
    end
})

-- ===== Delay TextBox + Button =====
AutofarmTab:Input({
    Title = "Auto Fish Delay",
    Placeholder = "Enter delay (0.1–4 seconds)",
    Callback = function(text)
        delayInputValue = text
    end
})

AutofarmTab:Button({
    Title = "Apply Delay",
    Desc = "Apply the entered delay value",
    Callback = function()
        local value = tonumber(delayInputValue)
        if value and value >= 0.1 and value <= 4 then
            delayTime = value
            WindUI:Notify({
                Title = "Auto Fish Delay",
                Content = "Delay set to "..string.format("%.1f s", delayTime).." (min safe: "..minSafeDelay.." s)",
                Duration = 2
            })
        else
            WindUI:Notify({
                Title = "Auto Fish Delay",
                Content = "Invalid input! Must be between 0.1–4 seconds",
                Duration = 2
            })
        end
    end
})

-- ===== Auto Sell Button =====
local sellAllButton = AutofarmTab:Button({
    Title = "Sell All Fish",
    Desc = "Click to sell all your items instantly",
    Callback = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local RFSellAllItems = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/SellAllItems"]

        pcall(function()
            RFSellAllItems:InvokeServer()
        end)

        WindUI:Notify({
            Title = "Auto Sell",
            Content = "All items sold!",
            Duration = 3
        })
    end
})

AutofarmTab:Paragraph({
    Title = "Anti Kicked From Server",
})

local antiKickToggle = AutofarmTab:Toggle({
    Title = "Anti Kick",
    Value = false,
    Callback = function(state)
        local player = game.Players.LocalPlayer

        if state then
            -- Ambil karakter & HumanoidRootPart
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")
            local initialPos = hrp.Position
            local initialCFrame = hrp.CFrame -- simpan orientasi awal

            -- Anti-AFK VirtualUser
            _G.AntiKickConnection = player.Idled:Connect(function()
                local vu = game:GetService("VirtualUser")
                vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)

            -- Auto Jump + pergerakan horizontal random
            _G.AutoJumpEnabled = true
            spawn(function()
                while _G.AutoJumpEnabled do
                    task.wait(5) -- interval 5 detik
                    local char = player.Character
                    if not char then break end
                    local humanoid = char:FindFirstChild("Humanoid")
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if humanoid and humanoid.Health > 0 then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                    if hrp then
                        -- Pergerakan horizontal acak
                        local offsetX = math.random(-2,2)/10 -- ±0.2 studs
                        local offsetZ = math.random(-2,2)/10
                        local newPos = hrp.Position + Vector3.new(offsetX, 0, offsetZ)
                        hrp.CFrame = CFrame.lookAt(newPos, newPos + initialCFrame.LookVector)

                        task.wait(0.1)

                        -- Kembali ke posisi awal tetap menghadap depan
                        local currentY = hrp.Position.Y
                        hrp.CFrame = CFrame.lookAt(initialPos + Vector3.new(0, currentY - initialPos.Y, 0), 
                                                   initialPos + Vector3.new(0, currentY - initialPos.Y, 0) + initialCFrame.LookVector)
                    end
                end
            end)

            WindUI:Notify({
                Title = "Anti-Kick + Auto Jump",
                Content = "Enabled: Anti-Kick active with random horizontal movements",
                Duration = 3
            })
        else
            -- Matikan loop & disconnect Idled
            if _G.AntiKickConnection then
                _G.AntiKickConnection:Disconnect()
                _G.AntiKickConnection = nil
            end
            _G.AutoJumpEnabled = false

            WindUI:Notify({
                Title = "Anti-Kick + Auto Jump",
                Content = "Disabled",
                Duration = 3
            })
        end
    end
})

local AutoFarmTab = Window:Tab({
	Title = "Auto Farm V2",
	Icon = "leaf"
})

-------------------------------------------
----- =======[ AUTO FARM TAB ]
-------------------------------------------


local floatPlatform = nil

local function floatingPlat(enabled)
	if Notifs.floatBlockNotif then
		Notifs.floatBlockNotif = false
		return
	end
	if enabled then
			local charFolder = workspace:WaitForChild("Characters", 5)
			local char = charFolder:FindFirstChild(LocalPlayer.Name)
			if not char then return end

			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			floatPlatform = Instance.new("Part")
			floatPlatform.Anchored = true
			floatPlatform.Size = Vector3.new(10, 1, 10)
			floatPlatform.Transparency = 1
			floatPlatform.CanCollide = true
			floatPlatform.Name = "FloatPlatform"
			floatPlatform.Parent = workspace

			task.spawn(function()
				while floatPlatform and floatPlatform.Parent do
					pcall(function()
						floatPlatform.Position = hrp.Position - Vector3.new(0, 3.5, 0)
					end)
					task.wait(0.1)
				end
			end)

			NotifySuccess("Float Enabled", "This feature has been successfully activated!")
		else
			if floatPlatform then
				floatPlatform:Destroy()
				floatPlatform = nil
			end
			NotifyWarning("Float Disabled", "Feature disabled")
		end
end

  
  
local workspace = game:GetService("Workspace")  
  
local knownEvents = {}

local eventCodes = {
	["1"] = "Ghost Shark Hunt",
	["2"] = "Shark Hunt",
	["3"] = "Worm Hunt",
	["4"] = "Black Hole",
	["5"] = "Meteor Rain",
	["6"] = "Ghost Worm",
	["7"] = "Shocked"
}

local function teleportTo(position)
	local char = workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(position + Vector3.new(0, 20, 0))
		end
	end
end

local function updateKnownEvents()
	knownEvents = {}

	local props = workspace:FindFirstChild("Props")
	if props then
		for _, child in ipairs(props:GetChildren()) do
			if child:IsA("Model") and child.PrimaryPart then
				knownEvents[child.Name:lower()] = child
			end
		end
	end
end

local function monitorEvents()
	local props = workspace:FindFirstChild("Props")
	if not props then
		workspace.ChildAdded:Connect(function(child)
			if child.Name == "Props" then
				task.wait(0.3)
				monitorEvents()
			end
		end)
		return
	end

	props.ChildAdded:Connect(function()
		task.wait(0.3)
		updateKnownEvents()
	end)

	props.ChildRemoved:Connect(function()
		task.wait(0.3)
		updateKnownEvents()
	end)

	updateKnownEvents()
end

monitorEvents()

local autoTPEvent = false
local savedCFrame = nil
local monitoringTP = false
local alreadyTeleported = false
local teleportTime = nil
local eventTarget = nil

local function saveOriginalPosition()
	local char = workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)
	if char and char:FindFirstChild("HumanoidRootPart") then
		savedCFrame = char.HumanoidRootPart.CFrame
	end
end

local function returnToOriginalPosition()
	if savedCFrame then
		local char = workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)
		if char and char:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.CFrame = savedCFrame
		end
	end
end

local function isEventStillActive(name)
	updateKnownEvents()
	return knownEvents[name:lower()] ~= nil
end

local function monitorAutoTP()
	if monitoringTP then return end
	monitoringTP = true

	while true do
		if autoTPEvent then
			if not alreadyTeleported then
				updateKnownEvents()
				for _, eventModel in pairs(knownEvents) do
					saveOriginalPosition()
					teleportTo(eventModel:GetPivot().Position)
					if typeof(floatingPlat) == "function" then
						floatingPlat(true)
					end
					alreadyTeleported = true
					teleportTime = tick()
					eventTarget = eventModel.Name
					NotifyError("Event Farm", "Teleported to: " .. eventTarget)
					break
				end
			else
				if teleportTime and (tick() - teleportTime >= 900) then
					returnToOriginalPosition()
					if typeof(floatingPlat) == "function" then
						floatingPlat(false)
					end
					alreadyTeleported = false
					teleportTime = nil
					eventTarget = nil
					NotifyInfo("Event Timeout", "Returned after 15 minutes.")
				elseif eventTarget and not isEventStillActive(eventTarget) then
					returnToOriginalPosition()
					if typeof(floatingPlat) == "function" then
						floatingPlat(false)
					end
					alreadyTeleported = false
					teleportTime = nil
					NotifyInfo("Event Ended", "Returned to start position.")
				end
			end
		else
			if alreadyTeleported then
				returnToOriginalPosition()
				if typeof(floatingPlat) == "function" then
					floatingPlat(false)
				end
				alreadyTeleported = false
				teleportTime = nil
				eventTarget = nil
			end
		end

		task.wait(1)
	end
end

task.spawn(monitorAutoTP)

local selectedIsland = "09"
local isAutoFarmRunning = false

local islandCodes = {
    ["01"] = "Crater Islands",
    ["02"] = "Tropical Grove",
    ["03"] = "Vulcano",
    ["04"] = "Coral Reefs",
    ["05"] = "Winter",
    ["06"] = "Machine",
    ["07"] = "Treasure Room",
    ["08"] = "Sisyphus Statue",
    ["09"] = "Fisherman Island"
}

local farmLocations = {
    ["Crater Islands"] = {
    	CFrame.new(1066.1864, 57.2025681, 5045.5542, -0.682534158, 1.00865822e-08, 0.730853677, -5.8900711e-09, 1, -1.93017531e-08, -0.730853677, -1.74788859e-08, -0.682534158),
    	CFrame.new(1057.28992, 33.0884132, 5133.79883, 0.833871782, 5.44149223e-08, 0.551958203, -6.58184218e-09, 1, -8.86416984e-08, -0.551958203, 7.02829084e-08, 0.833871782),
    	CFrame.new(988.954712, 42.8254471, 5088.71289, -0.849417388, -9.89310394e-08, 0.527721584, -5.96115086e-08, 1, 9.15179328e-08, -0.527721584, 4.62786431e-08, -0.849417388),
    	CFrame.new(1006.70685, 17.2302666, 5092.14844, -0.989664078, 5.6538525e-09, -0.143405005, 9.14879283e-09, 1, -2.3711717e-08, 0.143405005, -2.47786183e-08, -0.989664078),
    	CFrame.new(1025.02356, 2.77259707, 5011.47021, -0.974474192, -6.87871804e-08, 0.224499553, -4.47472104e-08, 1, 1.12170284e-07, -0.224499553, 9.92613209e-08, -0.974474192),
    	CFrame.new(1071.14551, 3.528404, 5038.00293, -0.532300115, 3.38677708e-08, 0.84655571, 6.69992914e-08, 1, 2.12149165e-09, -0.84655571, 5.7847906e-08, -0.532300115),
    	CFrame.new(1022.55457, 16.6277809, 5066.28223, 0.721996129, 0, -0.691897094, 0, 1, 0, 0.691897094, 0, 0.721996129),
    },
    ["Tropical Grove"] = {
    	CFrame.new(-2165.05469, 2.77070165, 3639.87451, -0.589090407, -3.61497356e-08, -0.808067143, -3.20645626e-08, 1, -2.13606164e-08, 0.808067143, 1.3326984e-08, -0.589090407)
    },
    ["Vulcano"] = {
    	CFrame.new(-701.447937, 48.1446075, 93.1546631, -0.0770962164, 1.34335654e-08, -0.997023642, 9.84464776e-09, 1, 1.27124169e-08, 0.997023642, -8.83526763e-09, -0.0770962164),
    	CFrame.new(-654.994934, 57.2567711, 75.098526, -0.540957272, 2.58946509e-09, -0.841050088, -7.58775585e-08, 1, 5.18827363e-08, 0.841050088, 9.1883166e-08, -0.540957272),
    },
    ["Coral Reefs"] = {
    	CFrame.new(-3118.39624, 2.42531538, 2135.26392, 0.92336154, -1.0069185e-07, -0.383931547, 8.0607947e-08, 1, -6.84016968e-08, 0.383931547, 3.22115596e-08, 0.92336154),
    },
    ["Winter"] = {
    	CFrame.new(2036.15308, 6.54998732, 3381.88916, 0.943401575, 4.71338666e-08, -0.331652641, -3.28136842e-08, 1, 4.87781051e-08, 0.331652641, -3.51345975e-08, 0.943401575),
    },
    ["Machine"] = {
    	CFrame.new(-1459.3772, 14.7103214, 1831.5188, 0.777951121, 2.52131862e-08, -0.628324807, -5.24126378e-08, 1, -2.47663063e-08, 0.628324807, 5.21991339e-08, 0.777951121)
    },
    ["Treasure Room"] = {
    	CFrame.new(-3625.0708, -279.074219, -1594.57605, 0.918176472, -3.97606392e-09, -0.396171629, -1.12946204e-08, 1, -3.62128851e-08, 0.396171629, 3.77244298e-08, 0.918176472),
    	CFrame.new(-3600.72632, -276.06427, -1640.79663, -0.696130812, -6.0491181e-09, 0.717914939, -1.09490363e-08, 1, -2.19084972e-09, -0.717914939, -9.38559541e-09, -0.696130812),
    	CFrame.new(-3548.52222, -269.309845, -1659.26685, 0.0472991578, -4.08685423e-08, 0.998880744, -7.68598838e-08, 1, 4.45538149e-08, -0.998880744, -7.88812216e-08, 0.0472991578),
    	CFrame.new(-3581.84155, -279.09021, -1696.15637, -0.999634147, -0.000535600528, -0.0270430837, -0.000448358158, 0.999994695, -0.00323198596, 0.0270446707, -0.00321867829, -0.99962908),
    	CFrame.new(-3601.34302, -282.790955, -1629.37036, -0.526346684, 0.00143659476, 0.850268841, -0.000266355521, 0.999998271, -0.00185445137, -0.850269973, -0.00120255165, -0.526345372)
    },
    ["Sisyphus Statue"] = {
    	CFrame.new(-3777.43433, -135.074417, -975.198975, -0.284491211, -1.02338751e-08, -0.958678663, 6.38407585e-08, 1, -2.96199456e-08, 0.958678663, -6.96293867e-08, -0.284491211),
    	CFrame.new(-3697.77124, -135.074417, -886.946411, 0.979794085, -9.24526766e-09, 0.200008959, 1.35701708e-08, 1, -2.02526174e-08, -0.200008959, 2.25575487e-08, 0.979794085),
    	CFrame.new(-3764.021, -135.074417, -903.742493, 0.785813689, -3.05788426e-08, -0.618463278, -4.87374336e-08, 1, -1.11368585e-07, 0.618463278, 1.17657272e-07, 0.785813689)
    },
    ["Fisherman Island"] = {
    	CFrame.new(-75.2439423, 3.24433279, 3103.45093, -0.996514142, -3.14880424e-08, -0.0834242329, -3.84156422e-08, 1, 8.14354024e-08, 0.0834242329, 8.43563228e-08, -0.996514142),
    	CFrame.new(-162.285294, 3.26205397, 2954.47412, -0.74356699, -1.93168272e-08, -0.668661416, 1.03873425e-08, 1, -4.04397653e-08, 0.668661416, -3.70152904e-08, -0.74356699),
    	CFrame.new(-69.8645096, 3.2620542, 2866.48096, 0.342575252, 8.79649331e-09, 0.939490378, 4.78986739e-10, 1, -9.53770485e-09, -0.939490378, 3.71738529e-09, 0.342575252),
    	CFrame.new(247.130951, 2.47001815, 3001.72412, -0.724809051, -8.27166033e-08, -0.688949764, -8.16509669e-08, 1, -3.41610367e-08, 0.688949764, 3.14931867e-08, -0.724809051)
    }
}

local function startAutoFarmLoop()
    NotifySuccess("Auto Farm Enabled", "Fishing started on island: " .. selectedIsland)

    while isAutoFarmRunning do  
        local islandSpots = farmLocations[selectedIsland]  
        if type(islandSpots) == "table" and #islandSpots > 0 then  
            location = islandSpots[math.random(1, #islandSpots)]  
        else  
            location = islandSpots  
        end  

        if not location then  
            NotifyError("Invalid Island", "Selected island name not found.")  
            return  
        end  

        local char = workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)  
        local hrp = char and char:FindFirstChild("HumanoidRootPart")  
        if not hrp then  
            NotifyError("Teleport Failed", "HumanoidRootPart not found.")  
            return  
        end  

        hrp.CFrame = location  
        task.wait(1.5)  

        StartAutoFish()
        
        while isAutoFarmRunning do
            if not isAutoFarmRunning then  
                StopAutoFish()  
                NotifyWarning("Auto Farm Stopped", "Auto Farm manually disabled. Auto Fish stopped.")  
                break  
            end  
            task.wait(0.5)
        end
    end
end      

local nameList = {}
local islandNamesToCode = {}

for code, name in pairs(islandCodes) do
    table.insert(nameList, name)
    islandNamesToCode[name] = code
end

table.sort(nameList)

local CodeIsland = AutoFarmTab:Dropdown({
    Title = "Farm Island",
    Values = nameList,
    Value = nameList[9],
    Callback = function(selectedName)
        local code = islandNamesToCode[selectedName]
        local islandName = islandCodes[code]
        if islandName and farmLocations[islandName] then
            selectedIsland = islandName
            NotifySuccess("Island Selected", "Farming location set to " .. islandName)
        else
            NotifyError("Invalid Selection", "The island name is not recognized.")
        end
    end
})

myConfig:Register("IslCode", CodeIsland)

local AutoFarm = AutoFarmTab:Toggle({
	Title = "Start Auto Farm",
	Callback = function(state)
		isAutoFarmRunning = state
		if state then
			startAutoFarmLoop()
		else
			StopAutoFish()
		end
	end
})

myConfig:Register("AutoFarmStart", AutoFarm)

AutoFarmTab:Toggle({
	Title = "Auto Farm Event",
	Desc = "!! DO WITH YOUR OWN RISK !!",
	Value = false,
	Callback = function(state)
		autoTPEvent = state
		if autoTPEvent then
			monitorAutoTP()
		else
			if alreadyTeleported then
				returnToOriginalPosition()
				if typeof(floatingPlat) == "function" then
					floatingPlat(false)
				end
				alreadyTeleported = false
			end
		end
	end
})

local changestatsTab = Window:Tab({ 
    Title = "Change Rod Stats", 
    Icon = "file-text" 
})

-- ===== Paragraph =====
changestatsTab:Paragraph({
    Title="Rod Modifier",
    Desc="Select a Rod to apply max stats."
})

local rodDisplayOrder = {
    "Luck Rod",
    "Carbon Rod",
    "Grass Rod",
    "Demascus Rod",
    "Ice Rod",
    "Lucky Rod",
    "Midnight Rod",
    "Steampunk Rod",
    "Chrome Rod",
    "Astral Rod",
    "Ares Rod",
    "Angler Rod"
}

-- Mapping display name ke modul asli (dengan !!!)
local rodKeyMap = {
    ["Luck Rod"] = "!!! Luck Rod",
    ["Carbon Rod"] = "!!! Carbon Rod",
    ["Grass Rod"] = "!!! Grass Rod",
    ["Demascus Rod"] = "!!! Demascus Rod",
    ["Ice Rod"] = "!!! Ice Rod",
    ["Lucky Rod"] = "!!! Lucky Rod",
    ["Midnight Rod"] = "!!! Midnight Rod",
    ["Steampunk Rod"] = "!!! Steampunk Rod",
    ["Chrome Rod"] = "!!! Chrome Rod",
    ["Astral Rod"] = "!!! Astral Rod",
    ["Ares Rod"] = "!!! Ares Rod",
    ["Angler Rod"] = "!!! Angler Rod"
}

-- Selected default
local selectedRod = rodDisplayOrder[1]

-- ===== Dropdown =====
changestatsTab:Dropdown({
    Title = "Select Rod",
    Values = rodDisplayOrder,
    Value = selectedRod,
    Callback = function(value)
        selectedRod = value
        WindUI:Notify({
            Title = "Rod Selected",
            Content = value,
            Duration = 3
        })
    end
})

-- ===== Tombol Apply Max Stats =====
changestatsTab:Button({
    Title = "Apply Max Stats",
    Callback = function()
        local moduleName = rodKeyMap[selectedRod] -- modul asli dengan !!!
        if moduleName then
            local success, err = pcall(function()
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local rodModule = ReplicatedStorage.Items:FindFirstChild(moduleName)
                
                if rodModule and rodModule:IsA("ModuleScript") then
                    local rodData = require(rodModule)
                    
                    rodData.VisualClickPowerPercent = 0.99999999999999
                    rodData.ClickPower = 99999999999999
                    rodData.Resilience = 99999999999999
                    rodData.Windup = NumberRange.new(1,10.99999999999999)
                    rodData.MaxWeight = 99999999999999

                    if rodData.RollData then
                        rodData.RollData.BaseLuck = 99999999999999
                        if rodData.RollData.Frequency then
                            rodData.RollData.Frequency.Golden = 1
                            rodData.RollData.Frequency.Rainbow = 2
                        end
                    end
                else
                    warn("Module "..moduleName.." tidak ditemukan!")
                end
            end)

            if success then
                WindUI:Notify({
                    Title = "Rod Modifier",
                    Content = selectedRod.." max stats applied!",
                    Duration = 3
                })
            else
                WindUI:Notify({
                    Title = "Rod Modifier Error",
                    Content = tostring(err),
                    Duration = 5
                })
            end
        end
    end
})

-- Teleport Tab
local TpTab = Window:Tab({  
    Title = "Teleport",  
    Icon = "map-pin"
})

-- Daftar lokasi teleport
local teleportLocations = {
    {Title = "Kohana Lava", Position = Vector3.new(-593.32, 59.0, 130.82)},
    {Title = "Esotoric Island", Position = Vector3.new(2024.490, 27.397, 1391.620)},
    {Title = "Ice Island", Position = Vector3.new(1766.46, 19.16, 3086.23)},
    {Title = "Kohana", Position = Vector3.new(-630.300, 16.035, 597.480)},
    {Title = "Lost Isle", Position = Vector3.new(-3660.070, 5.426, -1053.020)},
    {Title = "Stingray Shores", Position = Vector3.new(45.280, 28.000, 2987.110)},
    {Title = "Tropical Grove", Position = Vector3.new(-2092.897, 6.268, 3693.929)},
    {Title = "Weather Machine", Position = Vector3.new(-1495.250, 6.500, 1889.920)},
    {Title = "Coral Reefs", Position = Vector3.new(-2949.359, 63.250, 2213.966)},
    {Title = "Crater Island", Position = Vector3.new(1012.045, 22.676, 5080.221)},
    {Title = "Teleport To Enchant", Position = Vector3.new(3236.120, -1302.855, 1399.491)}
}

-- Buat list nama untuk dropdown
local locationNames = {}
for _, loc in ipairs(teleportLocations) do
    table.insert(locationNames, loc.Title)
end

-- Default selected location
local selectedLocation = locationNames[1]

-- Paragraph
TpTab:Paragraph({
    Title = "Teleport To Island",
    Desc = "Select a location and press Teleport."
})

-- Dropdown Teleport
local teleportDropdown = TpTab:Dropdown({
    Title = "Select Location",
    Values = locationNames,
    Value = selectedLocation,
    Callback = function(value)
        selectedLocation = value
        WindUI:Notify({Title="Location Selected", Content=value, Duration=3})
    end
})

-- Tombol Teleport
TpTab:Button({
    Title = "Teleport To Island",
    Icon = "rbxassetid://85151307796718",
    Callback = function()
        if selectedLocation then
            local loc
            for _, l in ipairs(teleportLocations) do
                if l.Title == selectedLocation then
                    loc = l
                    break
                end
            end

            if loc then
                local player = game.Players.LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                local hrp = character:WaitForChild("HumanoidRootPart")
                hrp.CFrame = CFrame.new(loc.Position)
                WindUI:Notify({Title="Teleported", Content="Teleported to "..loc.Title, Duration=3})
            end
        end
    end
})

-- Paragraph
TpTab:Paragraph({
    Title = "Teleport To EVENT",
    Desc = "TELEPORT TO EVENT."
})
--Teleport Event 
local eventsList = { "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", "Ghost Worm", "Meteor Rain" }

TpTab:Dropdown({
    Title = "Teleport Event",
    Values = eventsList,
    Value = "Shark Hunt",
    Callback = function(option)
        local props = workspace:FindFirstChild("Props")
        if props and props:FindFirstChild(option) and props[option]:FindFirstChild("Fishing Boat") then
            local fishingBoat = props[option]["Fishing Boat"]
            local boatCFrame = fishingBoat:GetPivot()
            local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = boatCFrame + Vector3.new(0, 15, 0)
                WindUI:Notify({
                	Title = "Event Available!",
                	Content = "Teleported To " .. option,
                	Icon = "circle-check",
                	Duration = 3
                })
            end
        else
            WindUI:Notify({
                Title = "Event Not Found",
                Text = option .. " Not Found!",
                Icon = "ban",
                Duration = 3
            })
        end
    end
})


-- Toggle Diving Gear ON/OFF
TpTab:Toggle({
    Title = "Diving Gear",
    Desc = "Using diving gear without buying it",
    Default = false,
    Callback = function(state)
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Replion = require(ReplicatedStorage.Packages.Replion)
        local Net = require(ReplicatedStorage.Packages.Net)
        local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
        local Soundbook = require(ReplicatedStorage.Shared.Soundbook)
        local NotificationController = require(ReplicatedStorage.Controllers.TextNotificationController)

        local DivingGear = ItemUtility:GetItemData("Diving Gear")
        if not DivingGear then return end

        local ReplionData = Replion.Client:GetReplion("Data")

        if state then
            -- ON
            if ReplionData:Get("EquippedOxygenTankId") ~= DivingGear.Data.Id then
                local EquipFunc = Net:RemoteFunction("EquipOxygenTank")
                local success = EquipFunc:InvokeServer(DivingGear.Data.Id)
                if success then
                    Soundbook.Sounds.DivingToggle:Play().PlaybackSpeed = 1 + math.random() * 0.3
                    NotificationController:DeliverNotification({
                        Type = "Text",
                        Text = "Diving Gear: On",
                        TextColor = {R = 9, G = 255, B = 0}
                    })
                end
            end
        else
            -- OFF
            if ReplionData:Get("EquippedOxygenTankId") == DivingGear.Data.Id then
                local UnequipFunc = Net:RemoteFunction("UnequipOxygenTank")
                local success = UnequipFunc:InvokeServer()
                if success then
                    Soundbook.Sounds.DivingToggle:Play().PlaybackSpeed = 1 + math.random() * 0.3
                    NotificationController:DeliverNotification({
                        Type = "Text",
                        Text = "Diving Gear: Off",
                        TextColor = {R = 255, G = 0, B = 0}
                    })
                end
            end
        end
    end
})

TpTab:Paragraph({
    Title = "Teleport To Other Player",
    Desc = "Select Name Player And Press Teleport"
})

-- Teleport to Player Tab
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local selectedPlayer = nil
local playerDropdown = nil -- reference dropdown

-- Fungsi refresh dropdown
local function refreshPlayerDropdown()
    -- Hapus dropdown lama jika ada
    if playerDropdown then
        playerDropdown:Remove()
    end

    -- Buat daftar player baru
    local playerNames = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(playerNames, plr.Name)
        end
    end

    -- Default selected player
    if #playerNames > 0 then
        if not table.find(playerNames, selectedPlayer) then
            selectedPlayer = playerNames[1]
        end
    else
        selectedPlayer = nil
    end

    -- Buat dropdown baru
    playerDropdown = TpTab:Dropdown({
        Title = "Select Player",
        Values = playerNames,
        Value = selectedPlayer,
        Callback = function(value)
            selectedPlayer = value
            WindUI:Notify({Title="Player Selected", Content=value, Duration=3})
        end
    })
end

-- Buat dropdown pertama kali sebelum tombol
refreshPlayerDropdown()

-- Tombol Teleport di bawah dropdown
TpTab:Button({
    Title = "Telepor To Other Player",
    Callback = function()
        if selectedPlayer then
            local targetPlayer = Players:FindFirstChild(selectedPlayer)
            local myChar = LocalPlayer.Character
            local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local targetChar = targetPlayer and targetPlayer.Character
            local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

            if hrp and targetHRP then
                hrp.CFrame = targetHRP.CFrame + Vector3.new(0,5,0)
                WindUI:Notify({Title="Teleported", Content="Teleported to "..selectedPlayer, Duration=3})
            end
        end
    end
})

-- Loop refresh dropdown tiap detik (tombol tetap di bawah)
spawn(function()
    while true do
        wait(1)
        refreshPlayerDropdown()
    end
end)

TpTab:Paragraph({
    Title = "Saved & Load, Location",
    Desc = "Saved Potition And Load Potition"
})

local npcFolder = game:GetService("ReplicatedStorage"):WaitForChild("NPC")

local npcList = {}
for _, npc in pairs(npcFolder:GetChildren()) do
	if npc:IsA("Model") then
		local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
		if hrp then
			table.insert(npcList, npc.Name)
		end
	end
end

-- ===== Load Config =====
local savedConfig
if Window.ConfigManager then
    savedConfig = Window.ConfigManager:CreateConfig("RTaO Dev"):Load()
end

-- ===== Default Values =====
local defaultTheme = (savedConfig and savedConfig.Theme) or WindUI:GetCurrentTheme()
local defaultTransparency = (savedConfig and savedConfig.TransparentMode ~= nil) and savedConfig.TransparentMode or true

-- ===== Saved Position =====
local savedPosition
if savedConfig and savedConfig.SavedPosition then
    local pos = savedConfig.SavedPosition
    if pos.X and pos.Y and pos.Z then
        savedPosition = Vector3.new(pos.X, pos.Y, pos.Z)
    end
end

-- Tombol Save Position
TpTab:Button({
    Title = "Save Position",
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        savedPosition = hrp.Position

        -- Simpan ke Config
        if Window.ConfigManager then
            local config = Window.ConfigManager:CreateConfig("RTaO Dev")
            config:Set("SavedPosition", {X = savedPosition.X, Y = savedPosition.Y, Z = savedPosition.Z})
            config:Save()
        end

        WindUI:Notify({Title="Position Saved", Content=tostring(savedPosition), Duration=3})
    end
})

-- Tombol Load Saved Position (hanya jalan kalau ditekan)
TpTab:Button({
    Title = "Load Saved Position",
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")

        if savedPosition then
            hrp.CFrame = CFrame.new(savedPosition)
            WindUI:Notify({Title="Loaded Saved Position", Content=tostring(savedPosition), Duration=3})
        else
            WindUI:Notify({Title="Info", Content="No saved position found, please save first.", Duration=3})
        end
    end
})

-- Paragraph
TpTab:Paragraph({
    Title = "Teleport To NPC",
    Desc = "TELEPORT TO N0C."
})

TpTab:Dropdown({
	Title = "NPC",
	Desc = "Select NPC to Teleport",
	Values = npcList,
	Value = nil,
	Callback = function(selectedName)
		local npc = npcFolder:FindFirstChild(selectedName)
		if npc and npc:IsA("Model") then
			local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
			if hrp then
				local charFolder = workspace:FindFirstChild("Characters", 5)
				local char = charFolder and charFolder:FindFirstChild(LocalPlayer.Name)
				if not char then return end
				local myHRP = char:FindFirstChild("HumanoidRootPart")
				if myHRP then
					myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
					NotifySuccess("Teleported!", "You are now near: " .. selectedName)
				end
			end
		end
	end
})

-- Spawn Boat Tab
local SpawnBoatTab = Window:Tab({  
    Title = "Spawn Boat",  
    Icon = "ship"
})

-- Boat Types
local boatTypes = {
    {Title = "Small Boat", Id = 1},
    {Title = "Kayak", Id = 2},
    {Title = "Jetski", Id = 3},
    {Title = "Highfield", Id = 4},
    {Title = "Speed Boat", Id = 5},
    {Title = "Fishing Boat", Id = 6},
    {Title = "Mini Yacht", Id = 14},
    {Title = "Hyper Boat", Id = 7},
    {Title = "Frozen Boat", Id = 11},
    {Title = "Cruiser Boat", Id = 13}
}

-- Buat list nama untuk dropdown
local boatNames = {}
for _, boat in ipairs(boatTypes) do
    table.insert(boatNames, boat.Title)
end

-- Default selected boat
local selectedBoat = boatNames[1]

-- Paragraph
SpawnBoatTab:Paragraph({
    Title = "Set All Boat Speed 1000",
})

-- Toggle
SpawnBoatTab:Toggle({
    Title = "Super Speed Boats",
    Default = false,
    Callback = function(state)
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local BoatsModule = require(ReplicatedStorage.Shared.BoatsHandlingData)

        -- Simpan Speed asli untuk restore
        if not BoatsModule._OriginalSpeed then
            BoatsModule._OriginalSpeed = {}
            for boatName, boatData in pairs(BoatsModule) do
                BoatsModule._OriginalSpeed[boatName] = boatData.Speed
            end
        end

        if state then
            -- ON: Set semua boat Speed = 1000
            for _, boatData in pairs(BoatsModule) do
                boatData.Speed = 1000
            end
        else
            -- OFF: Restore Speed asli
            for boatName, boatData in pairs(BoatsModule) do
                if BoatsModule._OriginalSpeed[boatName] then
                    boatData.Speed = BoatsModule._OriginalSpeed[boatName]
                end
            end
        end
    end
})

-- Paragraph
SpawnBoatTab:Paragraph({
    Title = "Spawn Boats",
    Desc = "Select a boat from dropdown and press Spawn."
})

-- Dropdown Boat
SpawnBoatTab:Dropdown({
    Title = "Select Boat",
    Values = boatNames,
    Value = selectedBoat,
    Callback = function(value)
        selectedBoat = value
        WindUI:Notify({Title="Boat Selected", Content=value, Duration=3})
    end
})

-- Tombol Spawn
SpawnBoatTab:Button({
    Title = "Spawn Boat",
    Icon = "ship",
    Callback = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local RFSpawnBoat = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/SpawnBoat"]
        if RFSpawnBoat then
            -- Cari ID boat yang sesuai nama
            local boatId
            for _, boat in ipairs(boatTypes) do
                if boat.Title == selectedBoat then
                    boatId = boat.Id
                    break
                end
            end

            if boatId then
                local success, err = pcall(function()
                    RFSpawnBoat:InvokeServer(boatId)
                end)
                if success then
                    WindUI:Notify({Title="Boat Spawned", Content=selectedBoat, Duration=3})
                else
                    WindUI:Notify({Title="Spawn Error", Content=tostring(err), Duration=5})
                end
            else
                WindUI:Notify({Title="Spawn Error", Content="Boat ID not found!", Duration=5})
            end
        end
    end
})

-- Buy Rod Tab
local BuyRodTab = Window:Tab({  
    Title = "Shop",  
    Icon = "shopping-cart"
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RFPurchaseFishingRod = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/PurchaseFishingRod"]
local RFPurchaseBait = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/PurchaseBait"]
local RFPurchaseWeatherEvent = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/PurchaseWeatherEvent"]
local RFPurchaseBoat = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/PurchaseBoat"]

-- ===== Rod Data =====
local rods = {
    ["Luck Rod"] = 79,
    ["Carbon Rod"] = 76,
    ["Grass Rod"] = 85,
    ["Demascus Rod"] = 77,
    ["Ice Rod"] = 78,
    ["Lucky Rod"] = 4,
    ["Midnight Rod"] = 80,
    ["Steampunk Rod"] = 6,
    ["Chrome Rod"] = 7,
    ["Astral Rod"] = 5,
    ["Ares Rod"] = 126,
    ["Angler Rod"] = 168
}

-- Dropdown display names (nama + harga)
local rodNames = {
    "Luck Rod (350 Coins)", "Carbon Rod (900 Coins)", "Grass Rod (1.5k Coins)", "Demascus Rod (3k Coins)",
    "Ice Rod (5k Coins)", "Lucky Rod (15k Coins)", "Midnight Rod (50k Coins)", "Steampunk Rod (215k Coins)",
    "Chrome Rod (437k Coins)", "Astral Rod (1M Coins)", "Ares Rod (3M Coins)", "Angler Rod ($8M Coins)"
}

-- Mapping dari display name ke key asli
local rodKeyMap = {
    ["Luck Rod (350 Coins)"]="Luck Rod",
    ["Carbon Rod (900 Coins)"]="Carbon Rod",
    ["Grass Rod (1.5k Coins)"]="Grass Rod",
    ["Demascus Rod (3k Coins)"]="Demascus Rod",
    ["Ice Rod (5k Coins)"]="Ice Rod",
    ["Lucky Rod (15k Coins)"]="Lucky Rod",
    ["Midnight Rod (50k Coins)"]="Midnight Rod",
    ["Steampunk Rod (215k Coins)"]="Steampunk Rod",
    ["Chrome Rod (437k Coins)"]="Chrome Rod",
    ["Astral Rod (1M Coins)"]="Astral Rod",
    ["Ares Rod (3M Coins)"]="Ares Rod",
    ["Angler Rod (8M Coins)"]="Angler Rod"
}

local selectedRod = rodNames[1]

-- ===== Dropdown =====
BuyRodTab:Dropdown({
    Title = "Select Rod",
    Values = rodNames,
    Value = selectedRod,
    Callback = function(value)
        selectedRod = value
        WindUI:Notify({Title="Rod Selected", Content=value, Duration=3})
    end
})

-- ===== Tombol Buy Rod =====
BuyRodTab:Button({
    Title="Buy Rod",
    Callback=function()
        local key = rodKeyMap[selectedRod] -- ambil key asli
        if key and rods[key] then
            local success, err = pcall(function()
                RFPurchaseFishingRod:InvokeServer(rods[key])
            end)
            if success then
                WindUI:Notify({Title="Rod Purchase", Content="Purchased "..selectedRod, Duration=3})
            else
                WindUI:Notify({Title="Rod Purchase Error", Content=tostring(err), Duration=5})
            end
        end
    end
})

-- ===== Bait Data =====
local baits = {
    ["TopWater Bait"] = 10,
    ["Lucky Bait"] = 2,
    ["Midnight Bait"] = 3,
    ["Chroma Bait"] = 6,
    ["Dark Mater Bait"] = 8,
    ["Corrupt Bait"] = 15,
    ["Aether Bait"] = 16
}

-- Dropdown display names (nama + harga + "Coins")
local baitNames = {
    "TopWater Bait (100 Coins)",
    "Lucky Bait (1k Coins)",
    "Midnight Bait (3k Coins)",
    "Chroma Bait (290k Coins)",
    "Dark Mater Bait (630k Coins)",
    "Corrupt Bait (1.15M Coins)",
    "Aether Bait (3.7M Coins)"
}

-- Mapping display name -> key asli
local baitKeyMap = {
    ["TopWater Bait (100 Coins)"] = "TopWater Bait",
    ["Lucky Bait (1k Coins)"] = "Lucky Bait",
    ["Midnight Bait (3k Coins)"] = "Midnight Bait",
    ["Chroma Bait (290k Coins)"] = "Chroma Bait",
    ["Dark Mater Bait (630k Coins)"] = "Dark Mater Bait",
    ["Corrupt Bait (1.15M Coins)"] = "Corrupt Bait",
    ["Aether Bait (3.7M Coins)"] = "Aether Bait"
}

local selectedBait = baitNames[1]

-- ===== Paragraph =====
BuyRodTab:Paragraph({
    Title = "Buy Bait",
    Desc = "Select a bait to purchase."
})

-- ===== Dropdown =====
BuyRodTab:Dropdown({
    Title="Select Bait",
    Values=baitNames,
    Value=selectedBait,
    Callback=function(value)
        selectedBait = value
        WindUI:Notify({
            Title="Bait Selected",
            Content=value,
            Duration=3
        })
    end
})

-- ===== Tombol Buy Bait =====
BuyRodTab:Button({
    Title="Buy Bait",
    Callback=function()
        local key = baitKeyMap[selectedBait] -- ambil key asli
        if key and baits[key] then
            local amount = baits[key]
            local success, err = pcall(function()
                RFPurchaseBait:InvokeServer(amount)
            end)
            if success then
                WindUI:Notify({
                    Title="Bait Purchase",
                    Content="Purchased "..selectedBait.." x"..amount,
                    Duration=3
                })
            else
                WindUI:Notify({
                    Title="Bait Purchase Error",
                    Content=tostring(err),
                    Duration=5
                })
            end
        end
    end
})

-- ===== Weather Data =====
local weathers = {
    ["Wind"] = 10000,
    ["Snow"] = 15000,
    ["Cloudy"] = 20000,
    ["Storm"] = 35000,
    ["Radiant"] = 50000,
    ["Shark Hunt"] = 300000
}

-- Dropdown display names
local weatherNames = {
    "Wind (10k Coins)", "Snow (15k Coins)", "Cloudy (20k Coins)", "Storm (35k Coins)",
    "Radiant (50k Coins)", "Shark Hunt (300k Coins)"
}

-- Mapping display name -> key asli
local weatherKeyMap = {
    ["Wind (10k Coins)"] = "Wind",
    ["Snow (15k Coins)"] = "Snow",
    ["Cloudy (20k Coins)"] = "Cloudy",
    ["Storm (35k Coins)"] = "Storm",
    ["Radiant (50k Coins)"] = "Radiant",
    ["Shark Hunt (300k Coins)"] = "Shark Hunt"
}

-- Selected weathers (multi-select)
local selectedWeathers = {weatherNames[1]} -- default

-- ===== Paragraph =====
BuyRodTab:Paragraph({
    Title="Buy Weather",
    Desc="Select weather(s) to purchase automatically."
})

-- ===== Multi-Select Dropdown =====
local weatherDropdown = BuyRodTab:Dropdown({
    Title="Select Weather(s)",
    Values=weatherNames,
    Multi=true, -- multi-select
    Value=selectedWeathers,
    Callback=function(values)
        selectedWeathers = values -- update selection
        WindUI:Notify({
            Title="Weather Selected",
            Content="Selected "..#values.." weather(s)",
            Duration=2
        })
    end
})

-- ===== Toggle Auto Buy =====
local autoBuyEnabled = false
local buyDelay = 0.5 -- delay antar pembelian

local function startAutoBuy()
    task.spawn(function()
        while autoBuyEnabled do
            for _, displayName in ipairs(selectedWeathers) do
                local key = weatherKeyMap[displayName]
                if key and weathers[key] then
                    local success, err = pcall(function()
                        RFPurchaseWeatherEvent:InvokeServer(key)
                    end)
                    if success then
                        WindUI:Notify({
                            Title="Auto Buy",
                            Content="Purchased "..displayName,
                            Duration=1
                        })
                    else
                        warn("Error buying weather:", err)
                    end
                    task.wait(buyDelay)
                end
            end
            task.wait(0.1) -- loop kecil supaya bisa break saat toggle dimatikan
        end
    end)
end

BuyRodTab:Toggle({
    Title = "Auto Buy Weather",
    Desc = "Automatically purchase selected weather(s).",
    Value = false,
    Callback = function(state)
        autoBuyEnabled = state
        if state then
            WindUI:Notify({
                Title = "Auto Buy",
                Content = "Enabled",
                Duration = 2
            })
            startAutoBuy()
        else
            WindUI:Notify({
                Title = "Auto Buy",
                Content = "Disabled",
                Duration = 2
            })
        end
    end
})

-- Urutan boat
local boatOrder = {
    "Small Boat",
    "Kayak",
    "Jetski",
    "Highfield",
    "Speed Boat",
    "Fishing Boat",
    "Mini Yacht",
    "Hyper Boat",
    "Frozen Boat",
    "Cruiser Boat"
}

-- Data boat
local boats = {
    ["Small Boat"] = {Id = 1, Price = 300},
    ["Kayak"] = {Id = 2, Price = 1100},
    ["Jetski"] = {Id = 3, Price = 7500},
    ["Highfield"] = {Id = 4, Price = 25000},
    ["Speed Boat"] = {Id = 5, Price = 70000},
    ["Fishing Boat"] = {Id = 6, Price = 180000},
    ["Mini Yacht"] = {Id = 14, Price = 1200000},
    ["Hyper Boat"] = {Id = 7, Price = 999000},
    ["Frozen Boat"] = {Id = 11, Price = 0},
    ["Cruiser Boat"] = {Id = 13, Price = 0}
}

-- Buat display names sesuai urutan
local boatNames = {}
for _, name in ipairs(boatOrder) do
    local data = boats[name]
    local priceStr
    if data.Price >= 1000000 then
        priceStr = string.format("%.2fM Coins", data.Price/1000000)
    elseif data.Price >= 1000 then
        priceStr = string.format("%.0fk Coins", data.Price/1000)
    else
        priceStr = data.Price.." Coins"
    end
    table.insert(boatNames, name.." ("..priceStr..")")
end

-- Buat keyMap sesuai urutan
local boatKeyMap = {}
for _, displayName in ipairs(boatNames) do
    local nameOnly = displayName:match("^(.-) %(") -- ambil nama sebelum tanda '('
    boatKeyMap[displayName] = nameOnly
end

-- Selected default
local selectedBoat = boatNames[1]

-- ===== Paragraph =====
BuyRodTab:Paragraph({
    Title="Buy Boat",
    Desc="Select a Boat to purchase."
})

-- ===== Dropdown =====
BuyRodTab:Dropdown({
    Title = "Select Boat",
    Values = boatNames,
    Value = selectedBoat,
    Callback = function(value)
        selectedBoat = value
        WindUI:Notify({
            Title = "Boat Selected",
            Content = value,
            Duration = 3
        })
    end
})

-- ===== Tombol Buy Boat =====
BuyRodTab:Button({
    Title = "Buy Boat",
    Callback = function()
        local key = boatKeyMap[selectedBoat]
        if key and boats[key] then
            local success, err = pcall(function()
                RFPurchaseBoat:InvokeServer(boats[key].Id)
            end)
            if success then
                WindUI:Notify({
                    Title = "Boat Purchase",
                    Content = "Purchased "..selectedBoat,
                    Duration = 3
                })
            else
                WindUI:Notify({
                    Title = "Boat Purchase Error",
                    Content = tostring(err),
                    Duration = 5
                })
            end
        end
    end
})

local karakterTab = Window:Tab({  
    Title = "User",  
    Icon = "user-plus"
})

karakterTab:Paragraph({
    Title = "Change Ability Your Character",
})

-- ===== Speed Hack Slider =====
karakterTab:Slider({
    Title = "Speed Hack",
    Value = {
        Min = 18,
        Max = 200,
        Default = 18
    },
    Callback = function(value)
        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = value
        end
        WindUI:Notify({
            Title = "Speed Hack",
            Content = "WalkSpeed set to "..value,
            Duration = 2
        })
    end
})

karakterTab:Button({
    Title = "Reset SpeedHack",
    Desc = "Return to normal speed",
    Callback = function()
        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 18
        end
        WindUI:Notify({
            Title = "SpeedHack Reset",
            Content = "WalkSpeed dikembalikan ke normal (18)",
            Duration = 2
        })
    end
})

local infinityJumpToggle = karakterTab:Toggle({
    Title = "Infinity Jump",
    Value = false,
    Callback = function(state)
        _G.InfinityJumpEnabled = state
        local UserInputService = game:GetService("UserInputService")
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer

        -- Disconnect existing connections
        if _G.InfinityJumpConnection then
            _G.InfinityJumpConnection:Disconnect()
            _G.InfinityJumpConnection = nil
        end

        if state then
            local function tryJump()
                local char = player.Character or player.CharacterAdded:Wait()
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end

            -- PC keyboard (Space)
            _G.InfinityJumpConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
                    tryJump()
                elseif input.UserInputType == Enum.UserInputType.Touch then
                    tryJump()
                end
            end)

            -- Android / Touch hold
            UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
                if _G.InfinityJumpEnabled then
                    tryJump()
                end
            end)
        end
    end
})

-- ===== Noclip Toggle =====
local noclipEnabled = false
karakterTab:Toggle({
    Title = "Noclip",
    Desc = "Can go through objects",
    Value = false,
    Callback = function(state)
        noclipEnabled = state
        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()

        if state then
            _G.NoclipConnection = game:GetService("RunService").RenderStepped:Connect(function()
                if char then
                    for _, part in ipairs(char:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
            WindUI:Notify({Title="Noclip", Content="Enabled", Duration=2})
        else
            if _G.NoclipConnection then
                _G.NoclipConnection:Disconnect()
                _G.NoclipConnection = nil
            end
            if char then
                for _, part in ipairs(char:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            WindUI:Notify({Title="Noclip", Content="Disabled", Duration=2})
        end
    end
})


local walkOnWaterEnabled = false
local floatHeight = 3
local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")

-- Simpan reference BodyPosition & connection
local bp, floatConnection

local function setupFloat()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    -- BodyPosition untuk mengatur posisi Y
    bp = Instance.new("BodyPosition")
    bp.MaxForce = Vector3.new(0, math.huge, 0)
    bp.D = 15
    bp.P = 2000
    bp.Position = hrp.Position
    bp.Parent = hrp

    -- Loop RenderStepped untuk update posisi
    floatConnection = runService.RenderStepped:Connect(function(delta)
        if walkOnWaterEnabled and hrp and hrp.Parent then
            local ray = Ray.new(hrp.Position, Vector3.new(0, -50, 0))
            local part, pos = workspace:FindPartOnRay(ray, char)
            if part and (part.Material == Enum.Material.Water or part.Name:lower():find("lava")) then
                bp.Position = Vector3.new(hrp.Position.X, pos.Y + floatHeight, hrp.Position.Z)
            else
                -- Kalau bukan air/lava, biarkan jatuh normal
                bp.Position = hrp.Position
            end
        end
    end)
end

-- Toggle di karakterTab
karakterTab:Toggle({
    Title = "Fly Little",
    Desc = "Raise your character a little and make your character float",
    Value = false,
    Callback = function(state)
        walkOnWaterEnabled = state
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")

        if state then
            setupFloat()
            WindUI:Notify({Title="Walk On Water", Content="Enabled", Duration=2})
        else
            if floatConnection then
                floatConnection:Disconnect()
                floatConnection = nil
            end
            if bp then
                bp:Destroy()
                bp = nil
            end
            WindUI:Notify({Title="Walk On Water", Content="Disabled", Duration=2})
        end
    end
})

karakterTab:Paragraph({
    Title = "Visual / ESP",
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Folder untuk ESP
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "PlayerESP"
ESPFolder.Parent = CoreGui

local playerESPEnabled = false

-- Fungsi membuat ESP (hanya dipanggil saat toggle ON)
local function CreatePlayerESP(player)
    if player == LocalPlayer or ESPFolder:FindFirstChild(player.Name) then return end
    local character = player.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end

    local container = Instance.new("Folder")
    container.Name = player.Name
    container.Parent = ESPFolder

    -- Highlight biru
    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(0, 170, 255) -- BIRU
    highlight.OutlineTransparency = 0
    highlight.Parent = container

    -- NameTag
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameTag"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 100, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = container

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1) -- Putih
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Parent = billboard
end

-- Hapus semua ESP
local function ClearESP()
    ESPFolder:ClearAllChildren()
end

-- Mulai ESP loop
local connection
local function StartESP()
    if connection then return end
    connection = RunService.Heartbeat:Connect(function()
        if playerESPEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    if not ESPFolder:FindFirstChild(player.Name) then
                        CreatePlayerESP(player)
                    end
                end
            end
        else
            ClearESP()
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end)
end

-- Toggle GUI
karakterTab:Toggle({
    Title = "Player ESP",
    Desc = "Show ESP for Other Players with Blue Outline and White NameTag",
    Value = false,
    Callback = function(state)
        playerESPEnabled = state
        if state then
            StartESP()
        else
            ClearESP()
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end
})

-- Hapus ESP saat pemain keluar
Players.PlayerRemoving:Connect(function(player)
    local esp = ESPFolder:FindFirstChild(player.Name)
    if esp then esp:Destroy() end
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Folder untuk ESP
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "PlayerESP"
ESPFolder.Parent = CoreGui

local playerESPEnabled = false
local hue = 0

-- Fungsi membuat ESP
local function CreatePlayerESP(player)
    if player == LocalPlayer or ESPFolder:FindFirstChild(player.Name) then return end
    local character = player.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end

    local container = Instance.new("Folder")
    container.Name = player.Name
    container.Parent = ESPFolder

    -- Highlight rainbow
    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromHSV(hue/360, 1, 1)
    highlight.OutlineTransparency = 0
    highlight.Parent = container

    -- NameTag
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameTag"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 100, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = container

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Parent = billboard
end

-- Update warna ESP (rainbow)
local function UpdateESPColors()
    hue = (hue + 5) % 360
    for _, container in pairs(ESPFolder:GetChildren()) do
        local highlight = container:FindFirstChildWhichIsA("Highlight")
        if highlight then
            highlight.OutlineColor = Color3.fromHSV(hue/360, 1, 1)
        end
    end
end

-- Hapus semua ESP
local function ClearESP()
    ESPFolder:ClearAllChildren()
end

-- Mulai ESP loop
local connection
local function StartESP()
    if connection then return end
    connection = RunService.Heartbeat:Connect(function()
        if playerESPEnabled then
            UpdateESPColors()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    if not ESPFolder:FindFirstChild(player.Name) then
                        CreatePlayerESP(player)
                    end
                end
            end
        else
            ClearESP()
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end)
end

-- Toggle GUI
karakterTab:Toggle({
    Title = "Player ESP",
    Desc = "Show ESP for Other Players with Rainbow Outline and White NameTag",
    Value = false,
    Callback = function(state)
        playerESPEnabled = state
        if state then
            StartESP()
        else
            ClearESP()
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end
})

-- Hapus ESP saat pemain keluar
Players.PlayerRemoving:Connect(function(player)
    local esp = ESPFolder:FindFirstChild(player.Name)
    if esp then esp:Destroy() end
end)

karakterTab:Paragraph({
    Title = "Trade",
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteFunction langsung
local RFInitiateTrade = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/InitiateTrade"]

local selectedPlayer = nil
local playerDropdown = nil

-- Refresh dropdown player
local function refreshPlayerDropdown()
    if playerDropdown then
        playerDropdown:Remove()
    end

    local playerNames = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(playerNames, plr.Name)
        end
    end

    selectedPlayer = #playerNames > 0 and playerNames[1] or nil

    playerDropdown = karakterTab:Dropdown({
        Title = "Select Player",
        Values = playerNames,
        Value = selectedPlayer,
        Callback = function(value)
            selectedPlayer = value
            WindUI:Notify({Title="Player Selected", Content=value, Duration=3})
        end
    })
end

refreshPlayerDropdown()

-- Tombol trade langsung
karakterTab:Button({
    Title = "Give Item",
    Callback = function()
        if not selectedPlayer then
            WindUI:Notify({Title="Error", Content="Tidak ada player yang dipilih!", Duration=3})
            return
        end

        local targetPlayer = Players:FindFirstChild(selectedPlayer)
        if not targetPlayer then
            WindUI:Notify({Title="Error", Content="Player tidak ditemukan!", Duration=3})
            return
        end

        -- Invoke remote langsung
        local success, err = pcall(function()
            -- Ganti UUID item sesuai kebutuhanmu
            RFInitiateTrade:InvokeServer(targetPlayer.UserId, "36a63fb5-df50-4d51-9b05-9d226ccd3ce7")
        end)

        if success then
            WindUI:Notify({Title="Success", Content="Trade request dikirim ke "..selectedPlayer, Duration=3})
        else
            WindUI:Notify({Title="Error", Content="Trade gagal: "..tostring(err), Duration=3})
        end
    end
})

-- Loop refresh dropdown tiap detik
spawn(function()
    while true do
        wait(1)
        refreshPlayerDropdown()
    end
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteFunction
local RFAwaitTradeResponse = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/AwaitTradeResponse"]

-- Toggle state
local autoAcceptEnabled = false

-- Toggle di GUI
karakterTab:Toggle({
    Title = "Auto Accept Trade",
    Callback = function(state)
        autoAcceptEnabled = state
        WindUI:Notify({Title="Auto Accept", Content=state and "ON" or "OFF", Duration=3})
    end
})

-- Hook Auto Accept Trade
RFAwaitTradeResponse.OnClientInvoke = newcclosure(function(itemData, fromPlayer, serverTime)
    if autoAcceptEnabled then
        -- Terima trade otomatis
        return true
    else
        -- Normal behavior (tidak auto accept)
        return false
    end
end)

karakterTab:Paragraph({
    Title = "Auto Sell Fish",
    Desc = "Comming Soon",
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RFSellItem = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/SellItem"]

-- UUID item
local itemUUID = "aad4dfaf-3144-4202-8dea-d7f7c7a9f33a"

-- Toggle
local autoSell = false
karakterTab:Toggle({
    Title = "Auto Sell Toggle",
    Value = false,
    Callback = function(val)
        autoSell = val
        WindUI:Notify({Title="Auto Sell", Content="Status: "..tostring(val), Duration=3})
    end
})

-- Loop auto sell
spawn(function()
    while true do
        wait(1)
        if autoSell then
            pcall(function()
                RFSellItem:InvokeServer(itemUUID)
            end)
        end
    end
end)

-- Settings Tab
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- Paragraph Info
SettingsTab:Paragraph({
    Title = "Interface",
    Desc = "Customize your GUI appearance."
})

-- Ambil semua theme yang tersedia
local themes = {}
for themeName,_ in pairs(WindUI:GetThemes()) do
    table.insert(themes, themeName)
end
table.sort(themes)

-- Load saved config (jika ada)
local savedConfig
if Window.ConfigManager then
    savedConfig = Window.ConfigManager:CreateConfig("RTaO Dev"):Load()
end

-- Tentukan default values
local defaultTheme = (savedConfig and savedConfig.Theme) or WindUI:GetCurrentTheme()
local defaultTransparency = (savedConfig and savedConfig.TransparentMode ~= nil) and savedConfig.TransparentMode or true

-- Theme Dropdown
local themeDropdown = SettingsTab:Dropdown({
    Title = "Select Theme",
    Values = themes,
    Value = defaultTheme,
    Callback = function(theme)
        WindUI:SetTheme(theme)
        WindUI:Notify({
            Title = "Theme Applied",
            Content = theme,
            Icon = "palette",
            Duration = 2
        })

        -- Auto-save theme
        if Window.ConfigManager then
            local config = Window.ConfigManager:CreateConfig("RTaO Dev")
            config:Set("Theme", theme)
            config:Set("TransparentMode", Window.TransparencyEnabled) -- simpan transparency juga
            config:Save()
        end
    end
})

-- Toggle Transparency
local transparentToggle = SettingsTab:Toggle({
    Title = "Transparency",
    Desc = "Makes the interface slightly transparent.",
    Value = defaultTransparency,
    Callback = function(state)
        Window:ToggleTransparency(state)
        WindUI.TransparencyValue = state and 0.1 or 1
        WindUI:Notify({
            Title = "Transparency",
            Content = state and "Transparency ON" or "Transparency OFF",
            Duration = 2
        })

        -- Auto-save transparency
        if Window.ConfigManager then
            local config = Window.ConfigManager:CreateConfig("RTaO Dev")
            config:Set("Theme", WindUI:GetCurrentTheme()) -- simpan theme juga
            config:Set("TransparentMode", state)
            config:Save()
        end
    end
})

-- Apply default values saat GUI load
WindUI:SetTheme(defaultTheme)
Window:ToggleTransparency(defaultTransparency)
WindUI.TransparencyValue = defaultTransparency and 0.1 or 1

SettingsTab:Keybind({
    Title = "Toggle UI",
    Desc = "Press a key to open/close the UI",
    Value = "G", -- gunakan string nama key
    Callback = function(keyName)
        Window:SetToggleKey(Enum.KeyCode[keyName]) -- konversi ke Enum
        --print("Keybind set to:", keyName)
    end
})

-- Optional: paragraph untuk info
SettingsTab:Paragraph({
    Title = "Configuration",
    Desc = "Theme and Transparency are auto-saved and auto-loaded."
})

local configName = ""

SettingsTab:Input({
    Title = "Config Name",
    Placeholder = "Enter config name",
    Callback = function(text)
        configName = text
    end
})

local filesDropdown
local function listConfigFiles()
    local files = {}
    local path = "WindUI/" .. Window.Folder .. "/config"
    if not isfolder(path) then
        makefolder(path)
    end
    for _, file in ipairs(listfiles(path)) do
        local name = file:match("([^/]+)%.json$")
        if name then table.insert(files, name) end
    end
    return files
end

filesDropdown = SettingsTab:Dropdown({
    Title = "Select Config",
    Values = listConfigFiles(),
    Multi = false,
    AllowNone = true,
    Callback = function(selection)
        configName = selection
    end
})

SettingsTab:Button({
    Title = "Refresh List",
    Callback = function()
        filesDropdown:Refresh(listConfigFiles())
    end
})

SettingsTab:Button({
    Title = "Save Config",
    Desc = "Save current theme and transparency",
    Callback = function()
        if configName ~= "" then
            local config = Window.ConfigManager:CreateConfig(configName)
            config:Register("Theme", themeDropdown)
            config:Register("Transparency", transparentToggle)
            config:Save()
            WindUI:Notify({
                Title = "Config Saved",
                Content = configName,
                Duration = 3
            })
        end
    end
})

SettingsTab:Button({
    Title = "Load Config",
    Desc = "Load saved configuration",
    Callback = function()
        if configName ~= "" then
            local config = Window.ConfigManager:CreateConfig(configName)
            local data = config:Load()
            if data then
                if data.Theme and table.find(themes, data.Theme) then
                    themeDropdown:Select(data.Theme)
                    WindUI:SetTheme(data.Theme)
                end
                if data.Transparency ~= nil then
                    transparentToggle:Set(data.Transparency)
                    Window:ToggleTransparency(data.Transparency)
                    WindUI.TransparencyValue = data.Transparency and 0.1 or 1
                end
                WindUI:Notify({
                    Title = "Config Loaded",
                    Content = configName,
                    Duration = 3
                })
            else
                WindUI:Notify({
                    Title = "Config Error",
                    Content = "Config file not found",
                    Duration = 3
                })
            end
        end
    end
})

-- Select first tab on GUI open
Window:SelectTab(1)
