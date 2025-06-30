-- SETTINGS
local WEBHOOK_URL = "https://discord.com/api/webhooks/1277264390210453526/uln2Y6QlG5wN6dPVscdN8hAaBv37WuRXNYTCNANS8dWg4uRHTiNSegcsJxaUdV6Fng69" -- ใส่ URL Webhook ของคุณตรงนี้

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- REMOTES
local DataStream = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("DataStream")
local WeatherEventStarted = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("WeatherEventStarted")

-- CONFIG
local Layouts = {
	["SeedsAndGears"] = {
		Color = Color3.fromRGB(56, 238, 23),
		Layout = {
			["ROOT/SeedStock/Stocks"] = "🌱 SEEDS STOCK",
			["ROOT/GearStock/Stocks"] = "🛠️ GEAR STOCK"
		}
	},
	["Eggs"] = {
		Color = Color3.fromRGB(251, 255, 14),
		Layout = {
			["ROOT/PetEggStock/Stocks"] = "🥚 EGG STOCK"
		}
	},
	["CosmeticStock"] = {
		Color = Color3.fromRGB(255, 106, 42),
		Layout = {
			["ROOT/CosmeticStock/ItemStocks"] = "🎨 COSMETIC ITEMS STOCK"
		}
	},
	["Weather"] = {
		Color = Color3.fromRGB(42, 109, 255)
	}
}

-- UTILS
local function ToHex(Color)
	return tonumber(Color:ToHex(), 16)
end

local function GetDataPacket(Data, Target)
	for _, Packet in Data do
		if Packet[1] == Target then
			return Packet[2]
		end
	end
end

local function MakeStockString(Stock)
	if typeof(Stock) ~= "table" then
		return "⚠️ No data\n"
	end

	local str = ""
	for name, data in Stock do
		local amount = data.Stock or 0
		local eggName = data.EggName
		name = eggName or name or "Unknown"
		str ..= `{name} **x{amount}**\n`
	end
	return str
end

local function SendWebhook(layoutType, fields)
	local layout = Layouts[layoutType]
	if not layout then return end

	local embed = {
		color = ToHex(layout.Color),
		fields = fields,
		footer = { text = "BY RTaO_Rs" },
		timestamp = DateTime.now():ToIsoDate()
	}

	local body = HttpService:JSONEncode({ embeds = { embed } })
	
	task.spawn(function()
		pcall(function()
			request({
				Url = WEBHOOK_URL,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = body
			})
		end)
	end)
end

local function HandleStockUpdate(Data)
	for type, layout in Layouts do
		if not layout.Layout then continue end

		local fields = {}

		for packetPath, title in layout.Layout do
			local stock = GetDataPacket(Data, packetPath)
			if not stock then continue end

			local stockString = MakeStockString(stock)
			table.insert(fields, {
				name = title,
				value = stockString,
				inline = true
			})
		end

		if #fields > 0 then
			SendWebhook(type, fields)
		end
	end
end

-- HOOKS
DataStream.OnClientEvent:Connect(function(eventType, profile, data)
	if eventType == "UpdateData" and profile:find(LocalPlayer.Name) then
		HandleStockUpdate(data)
	end
end)

WeatherEventStarted.OnClientEvent:Connect(function(eventName, duration)
	local endTime = math.round(workspace:GetServerTimeNow()) + duration

	SendWebhook("Weather", {
		{
			name = "🏔️ WEATHER",
			value = `{eventName}\nEnds: <t:{endTime}:R>`,
			inline = true
		}
	})
end)
