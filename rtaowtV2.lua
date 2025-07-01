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
 ["ROOT/SeedStock/Stocks"] = "aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTM4ODc5OTkyODI5NzU4NjcwOS9PZjl1NmQxTWRtS1Z2ZVJPY0YySmFkcUNmVlBZWjhVWWZJb1hPbHhtOE1DdG5OTFlNMnhLckpOd2tQb0RTR0VTVWJnNQ==",
 ["ROOT/PetEggStock/Stocks"] = "aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTM4ODgwMDU3MDA4ODg4MjIwNy9TcC1iS2c4SXJBLXRmNDhCZ2VrRlJEdkJoRzZFdW5xcVhSWGdvT1ZMX2t3Zl9OTnJGRXpjOFAwZmE2UjdqWHFZdkp6eA==",
 ["ROOT/GearStock/Stocks"] = "aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTM4ODgwMDQwNDcxMTUzODgwOS91eHdZMVgtWTNCQ1dwNElwNGlOWGYtejJTWTFCRU1BaEQ3R0Y2WXBGX25XUk1QU1dkLVJ1dHA0UW1ueWtNYXFtVHJoTA==",
 ["ROOT/CosmeticStock/ItemStocks"] = "aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTM4ODgwMTAyMTM3OTM1MDU0MC9mUzhfeFJCRmE5ckl6WGV2M3N4OXgwbjhScWRoZkx2RVp0em9rM0JnZGV6MU5nT1NkSkZ3NWZrMlJ4TFV2Y2s1WVhxNQ==",
 ["ROOT/EventShopStock/Stocks"] = "aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTM4ODgwMDgxNjY3NjIxMjc1Ny9ZY0Z0YTBJaTIwcXdKV0tFZEJPbldXMTFacFhESHR5SGxHUVpmQ0ZFX0YwU0VvVUVWLVFFVGFjTzNsV3BEUklhWm1GSg==",
 ["__WEATHER__"] = "aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTM4OTI2NDA2MDgwMDgzMTU0OS9MbkEzdktvOGstNkpRb0ZOcWRRbXA0bDVfSUlQdWNpMC1kdUtQU0RhMm0xM2ZsWW96REJVNWdEVERrSDI3cTNSaVoyUw=="
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
  s ..= (`{display} x{data.Stock}
`)
 end
 return s
end

-- Send Webhook (Single Embed) รองรับ fields
local function SendSingleEmbed(title, bodyText, color, encodedWebhook, imageUrl, fields)
 if not _G.Enabled or not requestFunc or not encodedWebhook or (bodyText == "" and (not fields or #fields == 0)) then return end
 local webhookUrl = base64Decode(encodedWebhook)

 local embed = {
  title = title,
  color = color,
  timestamp = DateTime.now():ToIsoDate(),
  footer = { text = "RTaO Stock Tracker" }
 }

 if imageUrl then
  embed.image = { url = imageUrl }
 end

 if fields then
  embed.fields = fields
 else
  embed.description = bodyText
 end

 local body = { embeds = { embed } }

 local success, result = pcall(function()
  return requestFunc({
   Url = webhookUrl,
   Method = "POST",
   Headers = { ["Content-Type"] = "application/json" },
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

-- ⛅ Weather Event Listener (แก้ไขให้ส่ง fields แทน description)
WeatherEventStarted.OnClientEvent:Connect(function(eventName, duration)
    local webhook = encodedWebhooks["__WEATHER__"]
    if not webhook then return end

    local endTime = math.round(workspace:GetServerTimeNow()) + duration
    local playerCount = #Players:GetPlayers()
    local maxPlayers = Players.MaxPlayers

    local teleportScript = ("game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, "%s", Players.LocalPlayer)"):format(game.JobId)

    local fields = {
        {
            name = "🕒 Ends",
            value = "<t:" .. endTime .. ":R>",
            inline = true
        },
        {
            name = "Players",
            value = playerCount .. "/" .. maxPlayers,
            inline = true
        },
        {
            name = "📜 Teleport Back",
            value = "```lua
" .. teleportScript .. "
```",
            inline = false
        }
    }

    SendSingleEmbed("🌦️ WEATHER EVENT - " .. eventName, "", 255, webhook, defaultImage, fields)
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
