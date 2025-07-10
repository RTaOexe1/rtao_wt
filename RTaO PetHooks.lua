-- RTaO Webhook: New Pet Detected (From PetEggData) 🐾
-- ใช้ Executor ที่รองรับ http_request (เช่น Synapse, KRNL)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local requestFunc = http_request or request or (syn and syn.request)

-- 👇 ใส่ Webhook ของคุณแบบ Base64
local encodedWebhook = "aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTI3NzI2NDM5MDIxMDQ1MzUyNi91bG4yWTZRbEc1d05uZFBWc2NkTjhoQWFWMzdXdVJYTllUQ05BTlM4ZFdnNHVIVGlOU2VnY3NKeGFVZFY2Rm5nNjk="
local webhookUrl = HttpService:Base64Decode(encodedWebhook)

-- 🔔 แจ้งเตือนเมื่อสคริปต์เริ่ม
pcall(function()
	game.StarterGui:SetCore("SendNotification", {
		Title = "RTaO Webhook",
		Text = "ระบบตรวจจับ Pet เปิดใช้งาน ✅",
		Duration = 2.5
	})
end)

-- ✅ รอ Folder PetEggData
local dataFolder = LocalPlayer:WaitForChild("Data", 10)
local petEggData = dataFolder and dataFolder:WaitForChild("PetEggData", 10)
if not petEggData then
	warn("❌ ไม่พบ PetEggData")
	return
end

-- 📡 เมื่อมีสัตว์เลี้ยงใหม่ถูกเพิ่ม
petEggData.ChildAdded:Connect(function(pet)
	local petName = pet.Name
	local weight = pet:GetAttribute("Weight") or "?"
	local level = pet:GetAttribute("Level") or "?"

	print("🎉 ได้ Pet ใหม่:", petName, "| Weight:", weight, "| Level:", level)

	-- 📤 สร้าง Embed
	local embed = {
		username = "BONK HUB | discord.gg/bonkhub",
		embeds = {{
			title = "🎉 New Pet Acquired!",
			description = "You have received a new pet!",
			color = 32768,
			fields = {
				{ name = "🐾 Pet Name:", value = "**" .. petName .. "**", inline = false },
				{ name = "⚖️ Weight / Level:", value = "[" .. tostring(weight) .. " KG] [Level " .. tostring(level) .. "]", inline = false },
				{ name = "👤 Player:", value = "|| " .. LocalPlayer.Name .. " ||", inline = false }
			},
			thumbnail = {
				url = "https://cdn.discordapp.com/attachments/1258228428881137677/1388887632227752026/image.png"
			},
			timestamp = DateTime.now():ToIsoDate()
		}}
	}

	local success, err = pcall(function()
		requestFunc({
			Url = webhookUrl,
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = HttpService:JSONEncode(embed)
		})
	end)

	if success then
		print("✅ ส่ง Webhook แล้ว:", petName)
	else
		warn("❌ ส่ง Webhook ล้มเหลว:", err)
	end
end)
