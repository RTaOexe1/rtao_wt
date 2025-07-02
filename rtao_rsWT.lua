subO Stock + Weather Bot (Base64 Webhook)
-- Version: 1.5 รวม Weather Effects แบบละเอียด ครบทุกสถานะ

_G.Enabled = true

-- Base64 Decoder
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

-- Webhooks
local encodedWebhooks = {
	["__WEATHER__"] = "aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTM4OTI2NDA2MDgwMDgzMTU0OS9MbkEzdktvOGstNkpRb0ZOcWRRbXA0bDVfSUlQdWNpMC1kdUtQU0RhMm0xM2ZsWW96REJVNWdEVERrSDI3cTNSaVoyUw=="
}

-- Settings
local defaultImage = "https://cdn.discordapp.com/attachments/1217027368825262144/1388582267881914568/1717516914963.png"

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Remotes
local WeatherEventStarted = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("WeatherEventStarted")

-- HTTP Request
local requestFunc = http_request or request or (syn and syn.request)
if not requestFunc then
	warn("❌ Executor นี้ไม่รองรับ HTTP Request")
	return
end

-- Effects Table
local weatherEffects = {
	["Rain"] = {
		emoji = "🌧️", 
		effects = {
			"Increases crop growth speed by 50%.",
			"50% chance to apply the Wet mutation.",
			"Can combine with Chilled to create Frozen."
		}
	},
	["Thunderstorm"] = {
		emoji = "🌩️", 
		effects = {
			"Increases growth speed by 50%.",
			"50% chance to apply Wet.",
			"Lightning strikes can apply Shocked mutation."
		}
	},
	["Frost"] = {
		emoji = "☃️",
		effects = {
			"Increases growth speed by 50%.",
			"Chance to apply Chilled.",
			"Combines with Wet to create Frozen.",
			"Triggers shivering animation + sound."
		}
	},
	["Night"] = {
		emoji = "🌜",
		effects = {
			"Gives crops a glowing purple hue.",
			"Chance to apply Moonlit.",
			"6 crops become Moonlit per night."
		}
	},
	["Blood Moon"] = {
		emoji = "🎑",
		effects = {
			"Gives crops a glowing red hue.",
			"Chance to apply Bloodlit."
		}
	},
	["Meteor Shower"] = {
		emoji = "🌠",
		effects = {
			"Meteors fall from the sky.",
			"Crops hit by meteors gain Celestial mutation."
		}
	},
	["Windy"] = {
		emoji = "🍃",
		effects = {
			"Crops have a chance to become Windstruck during the event.",
			"Slight crescent wind effect visible on crops."
		}
	},
	["Gale"] = {
		emoji = "🌪️",
		effects = {
			"Much higher chance for Windstruck crops.",
			"Players blown by strong wind currents."
		}
	},
	["Tornado"] = {
		emoji = "🌪️",
		effects = {
			"Gives crops the Twisted mutation."
		}
	},
	["Aurora Borealis"] = {
		emoji = "🌆",
		effects = {
			"Gives the Aurora mutation.",
			"Increases growth speed by 50%."
		}
	},
	["Tropical Rain"] = {
		emoji = "☔️",
		effects = {
			"Gives +50% Grow Speed, & crops the Drenched mutation."
		}
	},
	["Drought"] = {
		emoji = "🌵",
		effects = {
			"May possibly give Wiltproof mutation, details unavailable."
		}
	},
	["Bee Swarm"] = {
		emoji = "🐝",
		effects = {
			"Spawns bees that generate Pollinated Mutations or exchange for Honey.",
			"Lasts 10 minutes."
		}
	},
	["Working Bee Swarm"] = {
		emoji = "🐝",
		effects = {
			"Spawns bees that generate Pollinated Mutations with x10 Speed Craft.",
			"Higher Pollinated fruit chance.",
			"Lasts 10 minutes."
		}
	},
	["Mega Harvest"] = {
		emoji = "⛏️",
		effects = {
			"Grants 2x Harvest Points and growth speed."
		}
	},
	["Sun God"] = {
		emoji = "🌞",
		effects = {
			"Applies Dawnbound mutation to sunflowers near Sun God.",
			"Speeds up growth of Sunflower."
		}
	},
	["Heat Wave"] = {
		emoji = "🌅",
		effects = {
			"Applies the Sundried mutation to crops."
		}
	}
}

-- Send Webhook
local function SendWeatherEmbed(eventName, duration)
	local data = weatherEffects[eventName] or { emoji = "❓", effects = {"No effect information."} }
	local webhook = encodedWebhooks["__WEATHER__"]
	if not webhook then return end

	local endTime = math.round(workspace:GetServerTimeNow()) + duration
	local playerCount = #Players:GetPlayers()
	local maxPlayers = Players.MaxPlayers

	local desc = table.concat({
		"🕒 Ends: <t:" .. endTime .. ":R>",
		"",
		"Players:",
		playerCount .. "/" .. maxPlayers,
		"",
		"📈 Effects:",
		"• " .. table.concat(data.effects, "\n• ")
	}, "\n")

	local embed = {
		title = "🌦️ WEATHER EVENT\n" .. data.emoji .. " " .. eventName,
		description = desc,
		color = 255,
		timestamp = DateTime.now():ToIsoDate(),
		footer = { text = "RTaO Weather Tracker" },
		image = { url = defaultImage }
	}

	requestFunc({
		Url = base64Decode(webhook),
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = HttpService:JSONEncode({ embeds = { embed } })
	})
end

-- Event Trigger
WeatherEventStarted.OnClientEvent:Connect(function(eventName, duration)
	SendWeatherEmbed(eventName, duration)
end)

-- Optional UI
pcall(function()
	game.StarterGui:SetCore("SendNotification", {
		Title = "RTaO Webhook",
		Text = "RTaO Dev Weather Tracker Loaded ✅",
		Duration = 3,
		Icon = "rbxassetid://70576862346242"
	})
end)
