-- 🌱 RTaO Stock + Weather Bot (Base64 Webhook)
-- Version: 1.3 รวม Weather แจ้งเตือน

_G.Enabled = true

-- Base64 Decoder (ไม่ใช้ syn)
local function base64Decode(data)
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
		if (x == '=') then return '' end
		local r, f = '', (b:find(x) - 1)
		for i = 6, 1, -1 do
			r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
		end
		return r
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if (#x ~= 8) then return '' end
		local c = 0
		for i = 1, 8 do
			c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0)
		end
		return string.char(c)
	end))
end

-- Webhook Table (Base64)
local encodedWebhooks = {
	["ROOT/SeedStock/Stocks"] = "BASE64_ENCODED_WEBHOOK_1",
	["ROOT/PetEggStock/Stocks"] = "BASE64_ENCODED_WEBHOOK_2",
	["ROOT/GearStock/Stocks"] = "BASE64_ENCODED_WEBHOOK_3",
	["ROOT/CosmeticStock/ItemStocks"] = "BASE64_ENCODED_WEBHOOK_4",
	["ROOT/EventShopStock/Stocks"] = "BASE64_ENCODED_WEBHOOK_5",
	["__WEATHER__"] = "BASE64_ENCODED_WEBHOOK_WEATHER"
}

-- Embed Layout
_G.Layout = {
	["ROOT/SeedStock/Stocks"] = { title = "🌱 SEEDS STOCK", color = 65280 },
	["ROOT/PetEggStock/Stocks"] = { title = "🥚 EGG STOCK", color = 16776960 },
	["ROOT/GearStock/Stocks"] = { title = "🛠️ GEAR STOCK", color = 16753920 },
	["ROOT/CosmeticStock/ItemStocks"] = { title = "🎨 COSMETIC STOCK", color = 16737792 },
	["ROOT/EventShopStock/Stocks"] = { title = "🎁 EVENT STOCK", color = 10027263 }
}

-- 🔧 Settings
local defaultImage = "https://cdn.discordapp.com/attachments/1217027368825262144/1388582267881914568/1717516914963.png"

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Remotes
local DataStream = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("DataStream")
local WeatherEventStarted = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("WeatherEventStarted")

-- Request Fallback
local requestFunc = http_request or request or (syn and syn.request)
if not requestFunc then
	warn("❌ Executor นี้ไม่รองรับ HTTP Request")
	return
end

-- Convert Stock Table to String
local function GetStockString(stock)
	local s = ""
	for name, data in pairs(stock) do
		local display = data.EggName or name
		s ..= (`{display} x{data.Stock}\n`)
	end
	return s
end

-- Send Webhook (Single Embed)
local function SendSingleEmbed(title, bodyText, color, encodedWebhook, imageUrl)
	if not _G.Enabled or not requestFunc or not encodedWebhook or bodyText == "" then return end
	local webhookUrl = base64Decode(encodedWebhook)

	local embed = {
		title = title,
		description = bodyText,
		color = color,
		timestamp = DateTime.now():ToIsoDate(),
		footer = { text = "RTaO Stock Tracker" }
	}

	if imageUrl then
		embed.image = { url = imageUrl }
	end

	local body = { embeds = { embed } }

	local success, result = pcall(function()
		return requestFunc({
			Url = webhookUrl,
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = HttpService:JSONEncode(body)
		})
	end)

	if success then
		print("[✅] ส่ง Webhook:", title)
	else
		warn("[❌] ไม่สามารถส่ง Webhook:", title)
	end
end

-- หา Stock จาก Packet
local function GetPacket(data, key)
	for _, packet in ipairs(data) do
		if packet[1] == key then
			return packet[2]
		end
	end
end

-- 📥 Stock Update Event
DataStream.OnClientEvent:Connect(function(eventType, profile, data)
	if eventType ~= "UpdateData" or not profile:find(LocalPlayer.Name) then return end

	for path, layout in pairs(_G.Layout) do
		local stockData = GetPacket(data, path)
		if stockData then
			local stockStr = GetStockString(stockData)
			local encodedWebhook = encodedWebhooks[path]
			SendSingleEmbed(layout.title, stockStr, layout.color, encodedWebhook, defaultImage)
		end
	end
end)

-- ⛅ Weather Event Listener
WeatherEventStarted.OnClientEvent:Connect(function(eventName, duration)
 local webhook = encodedWebhooks["__WEATHER__"]
 if not webhook then return end

 local endTime = math.round(workspace:GetServerTimeNow()) + duration
 local playerCount = #Players:GetPlayers()
 local maxPlayers = Players.MaxPlayers
 local jobId = game.JobId
 local teleportScript = `game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, "{jobId}", Players.LocalPlayer)`

 local desc = table.concat({
  `☁️ {eventName}`,
  `🕒 Ends: <t:{endTime}:R>`,
  "",
  "Players:",
  `{playerCount}/{maxPlayers}`,
  "",
  "Jobid:",
  jobId,
  "",
  "📜 Teleport Back:",
  teleportScript
 }, "\n")

 SendSingleEmbed("🌦️ WEATHER EVENT", desc, 255, webhook, defaultImage)
end)

-- UI Success Notification (optional)
pcall(function()
	game.StarterGui:SetCore("SendNotification", {
		Title = "RTaO Webhook",
		Text = "Stock + Weather Tracker Loaded",
		Duration = 3,
		Icon = "rbxassetid://70576862346242"
	})
end)
