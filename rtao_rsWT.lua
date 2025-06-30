--[[
    @author depso (depthso)
    @description Grow a Garden stock bot script
    รองรับมือถือ / Roblox ปกติ
]]

type table = {
	[any]: any
}

_G.Configuration = {
	["Enabled"] = true,
	["Webhook"] = "https://discord.com/api/webhooks/1277264390210453526/uln2Y6QlG5wN6dPVscdN8hAaBv37WuRXNYTCNANS8dWg4uRHTiNSegcsJxaUdV6Fng69", -- ใส่ webhook ของคุณ
	["Weather Reporting"] = true,
	["Anti-AFK"] = true,
	["Auto-Reconnect"] = true,
	["Rendering Enabled"] = false,

	["AlertLayouts"] = {
		["Weather"] = {
			EmbedColor = Color3.fromRGB(42, 109, 255),
		},
		["SeedsAndGears"] = {
			EmbedColor = Color3.fromRGB(56, 238, 23),
			Layout = {
				["ROOT/SeedStock/Stocks"] = "🌱 SEEDS STOCK",
				["ROOT/GearStock/Stocks"] = "🛠️ GEAR STOCK"
			}
		},
		["EventShop"] = {
			EmbedColor = Color3.fromRGB(212, 42, 255),
			Layout = {
				["ROOT/EventShopStock/Stocks"] = "🎁 EVENT STOCK"
			}
		},
		["Eggs"] = {
			EmbedColor = Color3.fromRGB(251, 255, 14),
			Layout = {
				["ROOT/PetEggStock/Stocks"] = "🥚 EGG STOCK"
			}
		},
		["CosmeticStock"] = {
			EmbedColor = Color3.fromRGB(255, 106, 42),
			Layout = {
				["ROOT/CosmeticStock/ItemStocks"] = "🎨 COSMETIC ITEMS STOCK"
			}
		}
	}
}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = cloneref(game:GetService("VirtualUser"))
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")

--// Remotes
local DataStream = ReplicatedStorage.GameEvents.DataStream
local WeatherEventStarted = ReplicatedStorage.GameEvents.WeatherEventStarted

local LocalPlayer = Players.LocalPlayer

local function GetConfigValue(Key: string)
	return _G.Configuration[Key]
end

RunService:Set3dRenderingEnabled(GetConfigValue("Rendering Enabled"))

if _G.StockBot then return end
_G.StockBot = true

local function ConvertColor3(Color: Color3): number
	return tonumber(Color:ToHex(), 16)
end

local function GetDataPacket(Data, Target: string)
	for _, Packet in Data do
		if Packet[1] == Target then
			return Packet[2]
		end
	end
end

local function GetLayout(Type: string)
	return _G.Configuration.AlertLayouts[Type]
end

-- ✅ เวอร์ชันที่ใช้ PostAsync สำหรับมือถือ
local function WebhookSend(Type: string, Fields: table)
	local Enabled = GetConfigValue("Enabled")
	local Webhook = GetConfigValue("Webhook")

	if not Enabled or not Webhook then return end

	local Layout = GetLayout(Type)
	if not Layout then return end

	local Color = ConvertColor3(Layout.EmbedColor)
	local TimeStamp = DateTime.now():ToIsoDate()

	local Body = {
		embeds = {{
			color = Color,
			fields = Fields,
			footer = { text = "BY RTaO_Rs" },
			timestamp = TimeStamp
		}}
	}

	local success, err = pcall(function()
		HttpService:PostAsync(Webhook, HttpService:JSONEncode(Body), Enum.HttpContentType.ApplicationJson)
	end)

	if not success then
		warn("[Webhook Error]", err)
	end
end

local function MakeStockString(Stock: table): string
	local s = ""
	for Name, Data in Stock do
		local Amount = Data.Stock
		local EggName = Data.EggName
		Name = EggName or Name
		s ..= `{Name} **x{Amount}**\n`
	end
	return s
end

local function ProcessPacket(Data, Type: string, Layout)
	local Fields = {}
	if not Layout.Layout then return end

	for Packet, Title in Layout.Layout do
		local Stock = GetDataPacket(Data, Packet)
		if not Stock then return end

		table.insert(Fields, {
			name = Title,
			value = MakeStockString(Stock),
			inline = true
		})
	end

	WebhookSend(Type, Fields)
end

DataStream.OnClientEvent:Connect(function(Type: string, Profile: string, Data: table)
	if Type ~= "UpdateData" or not Profile:find(LocalPlayer.Name) then return end

	for Name, Layout in _G.Configuration.AlertLayouts do
		ProcessPacket(Data, Name, Layout)
	end
end)

WeatherEventStarted.OnClientEvent:Connect(function(Event: string, Length: number)
	if not GetConfigValue("Weather Reporting") then return end

	local ServerTime = math.round(workspace:GetServerTimeNow())
	local EndUnix = ServerTime + Length

	WebhookSend("Weather", {{
		name = "🏔️ WEATHER",
		value = `{Event}\nEnds:<t:{EndUnix}:R>`,
		inline = true
	}})
end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
	if not GetConfigValue("Anti-AFK") then return end
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

-- Auto Reconnect (ลบ queue_on_teleport)
GuiService.ErrorMessageChanged:Connect(function()
	if not GetConfigValue("Auto-Reconnect") then return end

	local IsSingle = #Players:GetPlayers() <= 1
	local PlaceId = game.PlaceId
	local JobId = game.JobId

	if IsSingle then
		TeleportService:Teleport(PlaceId, LocalPlayer)
	else
		TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
	end
end)
