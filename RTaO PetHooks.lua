-- RTaO: Pet Detector & Webhook (No Server Needed) 🐾

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local requestFunc = http_request or request or (syn and syn.request)

-- ✅ ฟังก์ชันถอด Base64 (ไม่ใช้ HttpService)
local function base64Decode(data)
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
		if x == '=' then return '' end
		local r, f = '', (b:find(x) - 1)
		for i = 6, 1, -1 do
			r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
		end
		return r
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if #x ~= 8 then return '' end
		local c = 0
		for i = 1, 8 do
			c = c + (x:sub(i,i) == '1' and 2 ^ (8 - i) or 0)
		end
		return string.char(c)
	end))
end

-- ✅ ใส่ Webhook URL แบบ Base64
local encodedWebhook = "aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTM5MjY5ODY1MTA2NzAyNzU5Ny9fdlRXSjVZZjdxZW52OTlnTlZON1RySkVfbmc1WE85TndEYUJnS1U1ZmdRWW0tQ21ZN0pPdjctMWtFMGlPTzdGWTlTaw=="
local webhookUrl = base64Decode(encodedWebhook)

-- 🔔 แจ้งเตือนว่าระบบทำงานแล้ว
pcall(function()
	game.StarterGui:SetCore("SendNotification", {
		Title = "RTaO Webhook",
		Text = "ระบบเช็คสัตว์เลี้ยงเปิดใช้งาน ✅",
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

-- 📡 ดักสัตว์เลี้ยงใหม่ที่เพิ่มเข้ามา
petEggData.ChildAdded:Connect(function(pet)
	local petName = pet.Name
	local weight = pet:GetAttribute("Weight") or "?"
	local level = pet:GetAttribute("Level") or "?"

	print("🎉 ได้สัตว์เลี้ยงใหม่:", petName, "| Weight:", weight, "| Level:", level)

	-- สร้าง Embed สำหรับ Discord
	local embed = {
		username = "RTaO Hooks | discord.gg/rtaors",
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

	local body = HttpService:JSONEncode(embed)

	local success, err = pcall(function()
		requestFunc({
			Url = webhookUrl,
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = body
		})
	end)

	if success then
		print("✅ ส่ง Webhook สำเร็จ:", petName)
	else
		warn("❌ ส่ง Webhook ไม่สำเร็จ:", err)
	end
end)
