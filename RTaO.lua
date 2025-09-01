local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- Config
local pastebinRaw = "https://link-center.net/1373842/rYdVBJJjfRdz"
local getKeyLink = "https://link-center.net/1373842/rYdVBJJjfRdz"
local backupKey = "RTao-DEV-FREEKEY-01"
local keyFileName = "RTaOKeyData.json"
local expireTimeInSeconds = 60 * 60 * 12 -- 12 jam

-- Fungsi cek key
local function checkKey(input)
    local s,r = pcall(function()
        return game:HttpGet(pastebinRaw)
    end)
    return s and (r == input or input == backupKey)
end

-- Cek apakah key tersimpan & valid
local function isKeySaved()
    if isfile and readfile and isfile(keyFileName) then
        local content = readfile(keyFileName)
        local success, data = pcall(function()
            return HttpService:JSONDecode(content)
        end)
        if success and data and data.key and data.timestamp then
            local timePassed = os.time() - data.timestamp
            local pasteKey = game:HttpGet(pastebinRaw)
            return timePassed <= expireTimeInSeconds and (data.key == pasteKey or data.key == backupKey)
        end
    end
    return false
end

-- Simpan key + timestamp
local function saveKey(key)
    if writefile then
        local data = {key = key, timestamp = os.time()}
        local success, encoded = pcall(function()
            return HttpService:JSONEncode(data)
        end)
        if success then pcall(function() writefile(keyFileName, encoded) end) end
    end
end

-- Dapatkan sisa waktu key
local function getTimeLeft()
    if isfile(keyFileName) then
        local content = readfile(keyFileName)
        local success, data = pcall(function()
            return HttpService:JSONDecode(content)
        end)
        if success and data and data.timestamp then
            local remaining = expireTimeInSeconds - (os.time() - data.timestamp)
            if remaining > 0 then
                local hours = math.floor(remaining / 3600)
                local mins = math.floor((remaining % 3600) / 60)
                return hours.."h "..mins.."m left"
            end
        end
    end
    return "Expired"
end

-- Lewati GUI kalau key sudah valid
if isKeySaved() then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/rtaodev/Loader/main/Script.lua", true))()
    return
end

-- GUI Setup (Minimal)
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "RTaOKeySystem"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 360, 0, 200)
Frame.Position = UDim2.new(0.5, -180, 0.5, -100)
Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
Frame.BackgroundTransparency = 0.2
Frame.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1,0,0,30)
Title.Position = UDim2.new(0,0,0,5)
Title.BackgroundTransparency = 1
Title.Text = "RTaO DEV KEY SYSTEM"
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(255,50,50)
Title.TextSize = 20

local TextBox = Instance.new("TextBox", Frame)
TextBox.PlaceholderText = "Enter Key"
TextBox.Size = UDim2.new(1,-40,0,30)
TextBox.Position = UDim2.new(0,20,0,50)
TextBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
TextBox.TextColor3 = Color3.fromRGB(255,255,255)
TextBox.ClearTextOnFocus = true
TextBox.Font = Enum.Font.Code
TextBox.TextSize = 16
TextBox.Text = ""

if syn and syn.clipboard and syn.clipboard ~= "" then
    TextBox.Text = syn.clipboard
end

local Status = Instance.new("TextLabel", Frame)
Status.Size = UDim2.new(1,-40,0,20)
Status.Position = UDim2.new(0,20,0,90)
Status.Text = "Please enter the key."
Status.TextColor3 = Color3.fromRGB(255,255,255)
Status.Font = Enum.Font.Gotham
Status.TextSize = 14
Status.BackgroundTransparency = 1

-- Validate Button (sekarang di kanan, hijau)
local ValidateButton = Instance.new("TextButton")
ValidateButton.Name = "ValidateButton"
ValidateButton.Parent = Frame
ValidateButton.Text = "ENTER"
ValidateButton.Size = UDim2.new(0.48, -5, 0, 30)
ValidateButton.Position = UDim2.new(0.5, 5, 0, 120) -- posisi di kanan
ValidateButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- hijau
ValidateButton.TextColor3 = Color3.fromRGB(0, 0, 0) -- hitam
ValidateButton.Font = Enum.Font.GothamBold
ValidateButton.TextSize = 16
ValidateButton.AutoButtonColor = true

-- Get Key Button (sekarang di kiri, kuning)
local GetKeyButton = Instance.new("TextButton")
GetKeyButton.Name = "GetKeyButton"
GetKeyButton.Parent = Frame
GetKeyButton.Text = "GET KEY"
GetKeyButton.Size = UDim2.new(0.48, -5, 0, 30)
GetKeyButton.Position = UDim2.new(0.02, 0, 0, 120) -- posisi di kiri
GetKeyButton.BackgroundColor3 = Color3.fromRGB(255, 255, 0) -- kuning
GetKeyButton.TextColor3 = Color3.fromRGB(0, 0, 0) -- hitam
GetKeyButton.Font = Enum.Font.GothamBold
GetKeyButton.TextSize = 16
GetKeyButton.AutoButtonColor = true

local CloseButton = Instance.new("TextButton", Frame)
CloseButton.Size = UDim2.new(0,25,0,25)
CloseButton.Position = UDim2.new(1,-30,0,5)
CloseButton.BackgroundColor3 = Color3.fromRGB(255,0,0)
CloseButton.TextColor3 = Color3.fromRGB(255,255,255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 16
CloseButton.Text = "X"

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Drag GUI (PC + Android)
local dragging, dragInput, dragStart, startPos
local function makeDraggable(frame)
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end
makeDraggable(Frame)

-- GET KEY button
GetKeyButton.MouseButton1Click:Connect(function()
    setclipboard(getKeyLink)
    Status.Text = "✅ Link copied! Paste it in browser to get your key."
end)

-- Validasi key
local failedAttempts = 0
local function validate(inputKey)
    Status.Text = "Checking..."
    if checkKey(inputKey) then
        saveKey(inputKey)
        Status.Text = "✅ Key Valid! ("..getTimeLeft()..") Opening GUI..."
        wait(1)
        ScreenGui:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/rtaodev/Loader/main/Script.lua", true))()
    else
        failedAttempts += 1
        Status.Text = "❌ Invalid Key! Try again..."
        if failedAttempts >= 3 then
            Status.Text = "⛔ Too many attempts! Wait 5 seconds..."
            wait(5)
            failedAttempts = 0
        end
    end
end

-- Tombol ENTER GUI
ValidateButton.MouseButton1Click:Connect(function()
    validate(TextBox.Text)
end)

-- Enter / Done di keyboard (PC + Android)
TextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        validate(TextBox.Text)
    end
end)
