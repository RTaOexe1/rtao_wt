-- 🌟 RTaO Egg Hatch Webhook Tracker
-- LocalScript สำหรับผู้เล่น / ใช้ผ่าน Executor

_G.Enabled = true

-- Base64 Decode (สำหรับซ่อนลิงก์ Webhook)
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

-- 🌐 Webhook URL (Base64 encoded) → เปลี่ยนของคุณตรงนี้
local encodedWebhook = "aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTI3NzI2NDM5MDIxMDQ1MzUyNi91bG4yWTZRbEc1d05uZFBWc2NkTjhoQWFWMzdXdVJYTllUQ05BTlM4ZFdnNHVIVGlOU2VnY3NKeGFVZFY2Rm5nNjk="

-- ✅ บริการที่ใช้
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local requestFunc = http_request or request or (syn and syn.request)

-- ❌ ถ้า executor ไม่รองรับ
if not requestFunc then
	warn("❌ Executor นี้ไม่รองรับ http_request")
	return
end

-- 🔔 แจ้งว่าระบบเริ่มทำงาน
pcall(function()
	game.StarterGui:SetCore("SendNotification", {
		Title = "RTaO Webhook",
		Text = "ระบบเช็คสัตว์เลี้ยงจากไข่เริ่มทำงาน ✅",
		Duration = 2.5,
		Icon = "rbxassetid://70576862346242"
	})
end)

-- 📡 รับ Event การเปิดไข่
local EggHatched = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("EggHatched")

EggHatched.OnClientEvent:Connect(function(petName, petWeight, petAge)
	if not _G.Enabled then return end

	local webhookUrl = base64Decode(encodedWebhook)
	local currentTime = os.date("วันนี้ เวลา %H:%M")

	-- 🎯 Embed รูปแบบเหมือนตัวอย่าง Discord
	local embed = {
		username = "RTaO HOOKS | discord.gg/EH23mXVqce",
		avatar_url = "https://cdn.discordapp.com/icons/1258228428881137677/a_f0fef019de2d728a70b7d4d57517b3e4.webp",
		embeds = {{
			title = "🎉 New Pet Acquired!",
			description = "You have received a new pet!",
			color = 32768, -- เขียว
			fields = {
				{
					name = "🐾 Pet Name:",
					value = "**" .. petName .. "**\n[" .. petWeight .. " KG] [Age " .. petAge .. "]",
					inline = false
				},
				{
					name = "👤 Player:",
					value = "|| " .. LocalPlayer.Name .. " || • RTaO HUB | " .. currentTime,
					inline = false
				}
			},
			thumbnail = {
				url = "https://cdn.discordapp.com/attachments/1258228428881137677/1388887632227752026/image.png"
			}
		}}
	}

	local body = HttpService:JSONEncode(embed)

	local success, err = pcall(function()
		requestFunc({
			Url = webhookUrl,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = body
		})
	end)

	if success then
		print("✅ ส่ง Webhook สำเร็จ: " .. petName)
	else
		warn("❌ ส่ง Webhook ล้มเหลว:", err)
	end
end)
