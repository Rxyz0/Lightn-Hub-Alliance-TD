-- =================================================================
-- LIGHT HUB v3.5
-- Tab: Main | Gacha | Endless | AFK | Settings
-- =================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local VERSION = "3.5"
local GUI_NAME = "LightHub"
local FILE_NAME = "LightHub_Settings.json"
local SAVE_FILES = { FILE_NAME, "LightnHub_Settings.json", "RexHub_Settings.json" }

local WIN_W, WIN_H = 480, 320
local HEADER_H, SIDEBAR_W = 34, 108

-- Place ID dari log SPY: lobby dan match
local LOBBY_PLACE, MATCH_PLACE = 99703116573266, 117654154793149
-- Auto Skip mengirim SkipWaveVote(wave + offset) dan (wave + offset + 1)
local SKIP_WAVE_OFFSET = 0

-- Warna: abu-abu dan hitam saja
local C = {
    white = Color3.fromRGB(255, 255, 255),
    text = Color3.fromRGB(232, 232, 234),
    muted = Color3.fromRGB(130, 130, 136),
    dim = Color3.fromRGB(84, 84, 90),
    ink = Color3.fromRGB(12, 12, 13),
    line = Color3.fromRGB(54, 54, 58),
    control = Color3.fromRGB(20, 20, 22),
    controlLine = Color3.fromRGB(70, 70, 75),
    hover = Color3.fromRGB(48, 48, 52),
    warn = Color3.fromRGB(255, 184, 64),
}

-- =================================================================
-- Pilihan dropdown / segmen
-- value Crate & Potion = ID asli dari game (dari log remote)
-- =================================================================
local DELAY_OPTIONS = {
    { label = "1s", value = 1 },
    { label = "0.5s", value = 0.5 },
    { label = "0.2s", value = 0.2 },
    { label = "0.1s", value = 0.1 },
}
-- Nama map dari log JoinQueue("Endless", 1) dan JoinQueue("ToiletBunker", 1)
local MAP_OPTIONS = {
    { label = "Endless", value = "Endless" },
    { label = "Crazy (Toilet Bunker)", value = "ToiletBunker" },
}
local PLAYER_OPTIONS = {
    { label = "1", value = 1 },
    { label = "2", value = 2 },
    { label = "3", value = 3 },
    { label = "4", value = 4 },
}
local SPEED_OPTIONS = {
    { label = "1.5x", value = 1.5 },
    { label = "2x", value = 2 },
    { label = "2.5x", value = 2.5 },
}
-- Summon 1 / 10 / 25 (25 ditambah di update terbaru game)
local SUMMON_OPTIONS = {
    { label = "1", value = 1 },
    { label = "10", value = 10 },
    { label = "25", value = 25 },
}
local CRATE_AMOUNT_OPTIONS = {
    { label = "1", value = 1 },
    { label = "3", value = 3 },
    { label = "6", value = 6 },
}
local CRATE_OPTIONS = {
    { label = "Party Crate", value = "PartyCrate" },
    { label = "Free Scientist Crate", value = "Free" },
    { label = "Scientist Crate", value = "ScientistCrate" },
    { label = "10m Crate", value = "10MCrate" },
    { label = "Fish Crate", value = "FishCrate" },
}
-- Lucky Block bukan crate: remote OpenLuckyBlock, event LuckyBlockOpening
-- Tingkat I dan III terlihat di log; II diasumsikan dari pola nama
local LUCKY_OPTIONS = {
    { label = "Lucky Block I", value = "LuckyBlockI" },
    { label = "Lucky Block II", value = "LuckyBlockII" },
    { label = "Lucky Block III", value = "LuckyBlockIII" },
}
local POTION_OPTIONS = {
    { label = "Luck Potion", value = "Luck" },
    { label = "Coin Potion", value = "Money" },
    { label = "XP Potion", value = "XP" },
    { label = "Summon Discount", value = "SummonDiscount" },
}

-- =================================================================
-- State
-- =================================================================
local settings = {
    antiAfk = true,
    showTimer = true,
    cheapestFirst = true,
    upgradeDelay = 0.5,
    claimEnabled = false,
    skipAnim = false,
    fluidBg = true,
    rerun = false,
}

local FLAG_DEFAULTS = {
    autoPlay = false, playMap = "", playPlayers = 1,
    autoSpeed = false, speedValue = 1.5,
    autoReplay = false,
    autoLobby = false,
    autoSkip = false,
    autoSummon = false, summonAmount = 1,
    autoSpin = false,
    autoCrate = false, crateAmount = 1, crateType = "",
    autoLucky = false, luckyAmount = 1, luckyType = "",
    autoPotion = false, potionType = "",
}
-- Fitur yang menghabiskan koin/item: selalu mati saat script dijalankan
local SPEND_KEYS = { "autoSummon", "autoSpin", "autoCrate", "autoLucky", "autoPotion" }
-- Nama lama (v2.5) -> ID game
local MIGRATE = {
    ["Party Crate"] = "PartyCrate", ["Free Scientist Crate"] = "Free",
    ["Scientist Crate"] = "ScientistCrate", ["10m Crate"] = "10MCrate",
    ["Fish Crate"] = "FishCrate", ["Lucky Potion"] = "Luck", ["Coin Potion"] = "Money",
}

local flags = {}
for k, v in pairs(FLAG_DEFAULTS) do flags[k] = v end

local run = { claim = false, upgrade = false }
local conns = {}

-- =================================================================
-- Helpers
-- =================================================================
local function notify(sub, txt, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Light • " .. sub,
            Text = txt,
            Duration = dur or 3,
        })
    end)
end

local function make(class, props, par)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = par
    return obj
end

local function grad(frame, top, bottom, rot)
    return make("UIGradient", {
        Color = ColorSequence.new(top, bottom),
        Rotation = rot or 90,
    }, frame)
end

local function tween(obj, t, goal)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

local function nextOrder(par)
    local n = (par:GetAttribute("_n") or 0) + 1
    par:SetAttribute("_n", n)
    return n
end

local function getStat(name)
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    local v = ls and ls:FindFirstChild(name)
    return v and v.Value or 0
end

-- =================================================================
-- Auto save
-- =================================================================
local canFile = (writefile and readfile and isfile) and true or false

local function saveSettings()
    if not canFile then return end
    local data = {
        antiAfk = settings.antiAfk,
        showTimer = settings.showTimer,
        cheapestFirst = settings.cheapestFirst,
        upgradeDelay = settings.upgradeDelay,
        claimEnabled = settings.claimEnabled,
        skipAnim = settings.skipAnim,
        fluidBg = settings.fluidBg,
        rerun = settings.rerun,
        flags = flags,
    }
    pcall(function()
        writefile(FILE_NAME, HttpService:JSONEncode(data))
    end)
end

local function setFlag(key, value)
    flags[key] = value
    saveSettings()
end

local function readSaved()
    for _, name in ipairs(SAVE_FILES) do
        local ok, raw = pcall(function()
            if isfile(name) then return readfile(name) end
        end)
        if ok and raw then return raw end
    end
end

local function inOptions(list, v)
    for _, o in ipairs(list) do
        if o.value == v then return true end
    end
    return false
end

local function loadSettings()
    if not canFile then return end
    local raw = readSaved()
    if not raw then return end

    local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or type(data) ~= "table" then return end

    if type(data.antiAfk) == "boolean" then settings.antiAfk = data.antiAfk end
    if type(data.showTimer) == "boolean" then settings.showTimer = data.showTimer end
    if type(data.cheapestFirst) == "boolean" then settings.cheapestFirst = data.cheapestFirst end
    if type(data.claimEnabled) == "boolean" then settings.claimEnabled = data.claimEnabled end
    if type(data.skipAnim) == "boolean" then settings.skipAnim = data.skipAnim end
    -- v3.3: tiga toggle animasi lama digabung jadi satu
    if data.skipCrateAnim == true or data.skipSummonAnim == true or data.skipSpinAnim == true then
        settings.skipAnim = true
    end
    if type(data.fluidBg) == "boolean" then settings.fluidBg = data.fluidBg end
    if type(data.rerun) == "boolean" then settings.rerun = data.rerun end
    if type(data.upgradeDelay) == "number" then
        for _, opt in ipairs(DELAY_OPTIONS) do
            if math.abs(opt.value - data.upgradeDelay) < 0.0001 then
                settings.upgradeDelay = opt.value
            end
        end
    end
    if type(data.flags) == "table" then
        for k, default in pairs(FLAG_DEFAULTS) do
            local v = data.flags[k]
            if type(v) == "string" and MIGRATE[v] then v = MIGRATE[v] end
            if type(v) == type(default) then flags[k] = v end
        end
    end
    -- Buang nilai lama yang sudah tidak ada di pilihan sekarang
    if not inOptions(SUMMON_OPTIONS, flags.summonAmount) then flags.summonAmount = 1 end
    if not inOptions(CRATE_AMOUNT_OPTIONS, flags.crateAmount) then flags.crateAmount = 1 end
    if flags.crateType ~= "" and not inOptions(CRATE_OPTIONS, flags.crateType) then flags.crateType = "" end
    if not inOptions(CRATE_AMOUNT_OPTIONS, flags.luckyAmount) then flags.luckyAmount = 1 end
    if flags.luckyType ~= "" and not inOptions(LUCKY_OPTIONS, flags.luckyType) then flags.luckyType = "" end
    if flags.potionType ~= "" and not inOptions(POTION_OPTIONS, flags.potionType) then flags.potionType = "" end
    if not inOptions(SPEED_OPTIONS, flags.speedValue) then flags.speedValue = 1.5 end
    if not inOptions(MAP_OPTIONS, flags.playMap) then flags.playMap = "" end
    if not inOptions(PLAYER_OPTIONS, flags.playPlayers) then flags.playPlayers = 1 end
    for _, k in ipairs(SPEND_KEYS) do flags[k] = false end
end

loadSettings()

-- =================================================================
-- Bersihkan instance lama
-- =================================================================
local env = (getgenv and getgenv()) or _G

for _, key in ipairs({ "RexHubCleanup", "LightnHubCleanup", "LightHubCleanup" }) do
    if env[key] then pcall(env[key]) end
end
if env.AFKHubConn then
    pcall(function() env.AFKHubConn:Disconnect() end)
end

local function getParent()
    local ok, result = pcall(function() return gethui and gethui() end)
    if ok and result then return result end
    if pcall(function() return CoreGui.Name end) then return CoreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local parent = getParent()

for _, p in ipairs({ parent, CoreGui }) do
    for _, name in ipairs({ GUI_NAME, "LightnHub", "RexHub", "AFKHub", "ATD_AutoClaim_V7", "ATD_AutoClaim_V6", "MinimalAFK_Gradient" }) do
        pcall(function()
            local old = p:FindFirstChild(name)
            if old then old:Destroy() end
        end)
    end
end

-- =================================================================
-- Anti-AFK
-- =================================================================
local idledConn = LocalPlayer.Idled:Connect(function()
    if not settings.antiAfk then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)
env.AFKHubConn = idledConn

-- =================================================================
-- Remote (dicari saat dipakai, tidak menahan startup)
-- =================================================================
local function RF(name)
    local folder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
    return folder and folder:FindFirstChild(name)
end

local function RE(name)
    local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    return folder and folder:FindFirstChild(name)
end

local function invoke(name, ...)
    local remote = RF(name)
    if not remote then return false, "remote tidak ada: " .. name end
    local args = table.pack(...)
    return pcall(function()
        return remote:InvokeServer(table.unpack(args, 1, args.n))
    end)
end

-- Server dianggap menerima kalau tidak error dan tidak membalas false
local function accepted(ok, res)
    if not ok or res == false then return false end
    if type(res) == "table" and (res.Success == false or res.success == false) then
        return false
    end
    return true
end

-- GuiObject benar-benar tampil: dirinya, semua ancestor, dan ScreenGui-nya.
-- GUI Light Hub sendiri diabaikan (ada teks "Auto Replay", "Wave", dll).
local function isShown(d)
    local gui = d:FindFirstAncestorOfClass("ScreenGui")
    if gui and (not gui.Enabled or gui.Name == GUI_NAME) then return false end
    local p = d.Parent
    while p and not p:IsA("LayerCollector") do
        if p:IsA("GuiObject") and not p.Visible then return false end
        p = p.Parent
    end
    return d.Visible
end

local function bindEvent(name, fn)
    task.spawn(function()
        local folder = ReplicatedStorage:WaitForChild("RemoteEvents", 20)
        local ev = folder and folder:WaitForChild(name, 20)
        if ev and ev:IsA("RemoteEvent") then
            table.insert(conns, ev.OnClientEvent:Connect(fn))
        end
    end)
end

-- =================================================================
-- Window
-- =================================================================
local ScreenGui = make("ScreenGui", {
    Name = GUI_NAME,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 50,
}, parent)

local MainFrame = make("Frame", {
    Size = UDim2.new(0, WIN_W, 0, WIN_H),
    Position = UDim2.new(0.5, -WIN_W / 2, 0, 24),
    BackgroundColor3 = Color3.fromRGB(10, 10, 11),
    BorderSizePixel = 0,
    Active = true,
    ClipsDescendants = true,
}, ScreenGui)
make("UIStroke", { Color = C.line, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, MainFrame)

-- Latar bergerak pelan seperti tinta abu-abu/putih diaduk di air:
-- dua lapisan gradient berputar dan bergeser dengan arah/kecepatan berbeda.
local function fluidLayer(colors, alphas)
    local layer = make("Frame", {
        Size = UDim2.new(1.5, 0, 1.5, 0),
        Position = UDim2.new(-0.25, 0, -0.25, 0),
        BackgroundColor3 = C.white,
        BorderSizePixel = 0,
    }, MainFrame)
    local g = make("UIGradient", {
        Color = ColorSequence.new(colors),
        Transparency = NumberSequence.new(alphas),
    }, layer)
    return layer, g
end

local fluid = { t = 0, acc = 0 }
fluid.layerA, fluid.gradA = fluidLayer({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(205, 205, 209)),
    ColorSequenceKeypoint.new(0.35, Color3.fromRGB(70, 70, 74)),
    ColorSequenceKeypoint.new(0.65, Color3.fromRGB(150, 150, 155)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 33)),
}, {
    NumberSequenceKeypoint.new(0, 0.82),
    NumberSequenceKeypoint.new(0.3, 0.55),
    NumberSequenceKeypoint.new(0.55, 0.88),
    NumberSequenceKeypoint.new(0.8, 0.6),
    NumberSequenceKeypoint.new(1, 0.84),
})
fluid.layerB, fluid.gradB = fluidLayer({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 44)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(215, 215, 219)),
    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(90, 90, 95)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(185, 185, 190)),
}, {
    NumberSequenceKeypoint.new(0, 0.9),
    NumberSequenceKeypoint.new(0.4, 0.66),
    NumberSequenceKeypoint.new(0.7, 0.9),
    NumberSequenceKeypoint.new(1, 0.7),
})

local function applyFluid()
    fluid.layerA.Visible = settings.fluidBg
    fluid.layerB.Visible = settings.fluidBg
end
applyFluid()

table.insert(conns, RunService.Heartbeat:Connect(function(dt)
    if not settings.fluidBg then return end
    fluid.acc = fluid.acc + dt
    if fluid.acc < 0.04 then return end -- ~25 fps cukup untuk gerakan lambat
    fluid.t = fluid.t + fluid.acc
    fluid.acc = 0
    local t = fluid.t
    fluid.gradA.Rotation = (t * 4) % 360
    fluid.gradA.Offset = Vector2.new(math.sin(t * 0.21) * 0.12, math.cos(t * 0.17) * 0.12)
    fluid.gradB.Rotation = (120 - t * 3) % 360
    fluid.gradB.Offset = Vector2.new(math.cos(t * 0.13) * 0.12, math.sin(t * 0.19) * 0.12)
end))

-- Loop latar belakang yang berhenti otomatis saat GUI dihancurkan
local function runLoop(fn)
    task.spawn(function()
        while ScreenGui.Parent do
            local ok, w = pcall(fn)
            if not ok then
                warn("[Light] " .. tostring(w))
                w = 2
            end
            task.wait(type(w) == "number" and w or 0.5)
        end
    end)
end

-- Header
local Header = make("Frame", {
    Size = UDim2.new(1, 0, 0, HEADER_H),
    BackgroundColor3 = C.white,
    BackgroundTransparency = 0.18,
    BorderSizePixel = 0,
}, MainFrame)
grad(Header, Color3.fromRGB(22, 22, 24), Color3.fromRGB(8, 8, 9))
make("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
}, Header)

make("TextLabel", {
    Size = UDim2.new(0, 160, 1, 0),
    Position = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1,
    RichText = true,
    Text = 'LIGHT  <font size="10" color="rgb(130,130,136)">v' .. VERSION .. "</font>",
    TextColor3 = C.white,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

local TimerLabel = make("TextLabel", {
    Size = UDim2.new(0, 76, 1, 0),
    Position = UDim2.new(1, -150, 0, 0),
    BackgroundTransparency = 1,
    Text = "00:00:00",
    TextColor3 = C.muted,
    TextSize = 11,
    Font = Enum.Font.RobotoMono,
    TextXAlignment = Enum.TextXAlignment.Right,
}, Header)

local function applyTimerVisibility()
    TimerLabel.Visible = settings.showTimer
end
applyTimerVisibility()

local function iconButton(xOff)
    local btn = make("TextButton", {
        Size = UDim2.new(0, 34, 1, -1),
        Position = UDim2.new(1, xOff, 0, 0),
        BackgroundColor3 = C.hover,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, Header)
    btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0.3 end)
    btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 1 end)
    return btn
end

local function iconBar(par, w, h, rot)
    return make("Frame", {
        Size = UDim2.new(0, w, 0, h),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Rotation = rot or 0,
        BackgroundColor3 = C.text,
        BorderSizePixel = 0,
    }, par)
end

local MinimizeBtn = iconButton(-68)
local MinLine = iconBar(MinimizeBtn, 10, 2)
local MinBox = make("Frame", {
    Size = UDim2.new(0, 10, 0, 10),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
}, MinimizeBtn)
make("UIStroke", { Color = C.text, Thickness = 1.5 }, MinBox)

local CloseBtn = iconButton(-34)
iconBar(CloseBtn, 13, 2, 45)
iconBar(CloseBtn, 13, 2, -45)

-- Body: sidebar kiri + halaman kanan
local Body = make("Frame", {
    Size = UDim2.new(1, 0, 1, -HEADER_H),
    Position = UDim2.new(0, 0, 0, HEADER_H),
    BackgroundTransparency = 1,
}, MainFrame)

local Sidebar = make("Frame", {
    Size = UDim2.new(0, SIDEBAR_W, 1, 0),
    BackgroundColor3 = C.white,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
}, Body)
grad(Sidebar, Color3.fromRGB(16, 16, 17), Color3.fromRGB(9, 9, 10))
make("Frame", {
    Size = UDim2.new(0, 1, 1, 0),
    Position = UDim2.new(1, -1, 0, 0),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
}, Sidebar)

local PageHolder = make("Frame", {
    Size = UDim2.new(1, -SIDEBAR_W, 1, 0),
    Position = UDim2.new(0, SIDEBAR_W, 0, 0),
    BackgroundTransparency = 1,
}, Body)

-- Drag lewat header (mouse & sentuh)
local drag = { on = false }

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        drag.on = true
        drag.start = input.Position
        drag.pos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                drag.on = false
            end
        end)
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        drag.input = input
    end
end)

table.insert(conns, UserInputService.InputChanged:Connect(function(input)
    if input == drag.input and drag.on then
        local d = input.Position - drag.start
        MainFrame.Position = UDim2.new(
            drag.pos.X.Scale, drag.pos.X.Offset + d.X,
            drag.pos.Y.Scale, drag.pos.Y.Offset + d.Y
        )
    end
end))

-- =================================================================
-- Dropdown: daftar muncul di bawah tombol, panah berputar saat terbuka
-- =================================================================
local Overlay = make("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 50,
}, MainFrame)

local Catcher = make("TextButton", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 1,
}, Overlay)

local ListFrame = make("Frame", {
    BackgroundColor3 = C.control,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 2,
}, Overlay)
make("UIStroke", { Color = C.controlLine, Thickness = 1 }, ListFrame)

local openChev = nil

local function closeOverlay()
    Overlay.Visible = false
    ListFrame.Visible = false
    if openChev then
        tween(openChev, 0.12, { Rotation = 0 })
        openChev = nil
    end
end

Catcher.MouseButton1Click:Connect(closeOverlay)

local function openList(anchor, options, current, onPick, chev)
    closeOverlay()
    for _, c in ipairs(ListFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    local itemH = 26
    local h = #options * itemH + 4
    local w = math.max(anchor.AbsoluteSize.X, 120)
    local mainPos, mainSize = MainFrame.AbsolutePosition, MainFrame.AbsoluteSize
    local aPos = anchor.AbsolutePosition

    local x = math.clamp(aPos.X - mainPos.X, 4, math.max(4, mainSize.X - w - 4))
    local below = aPos.Y - mainPos.Y + anchor.AbsoluteSize.Y + 2
    local above = aPos.Y - mainPos.Y - h - 2

    -- Utamakan ke bawah; kalau tidak muat baru ke atas
    local y
    if below + h <= mainSize.Y - 4 then
        y = below
    elseif above >= HEADER_H then
        y = above
    else
        y = math.max(HEADER_H, mainSize.Y - h - 4)
    end

    for i, o in ipairs(options) do
        local selected = (o.value == current)
        local b = make("TextButton", {
            Size = UDim2.new(1, -4, 0, itemH),
            Position = UDim2.new(0, 2, 0, 2 + (i - 1) * itemH),
            BackgroundColor3 = C.hover,
            BackgroundTransparency = selected and 0 or 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 3,
        }, ListFrame)
        make("TextLabel", {
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = o.label,
            TextColor3 = selected and C.white or C.muted,
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 4,
        }, b)
        if selected then
            make("Frame", {
                Size = UDim2.new(0, 2, 1, 0),
                BackgroundColor3 = C.white,
                BorderSizePixel = 0,
                ZIndex = 4,
            }, b)
        end
        b.MouseEnter:Connect(function()
            if not selected then b.BackgroundTransparency = 0.5 end
        end)
        b.MouseLeave:Connect(function()
            if not selected then b.BackgroundTransparency = 1 end
        end)
        b.MouseButton1Click:Connect(function()
            closeOverlay()
            onPick(o.value)
        end)
    end

    ListFrame.Size = UDim2.new(0, w, 0, h)
    ListFrame.Position = UDim2.new(0, x, 0, y)
    Overlay.Visible = true
    ListFrame.Visible = true
    if chev then
        openChev = chev
        tween(chev, 0.12, { Rotation = 180 })
    end
end

-- =================================================================
-- Komponen UI (sudut tegas, tanpa rounding)
-- =================================================================
local function createCard(par, height)
    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = C.white,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(par),
    }, par)
    grad(card, Color3.fromRGB(36, 36, 39), Color3.fromRGB(24, 24, 26))
    return card
end

local function styleControl(obj)
    make("UIStroke", {
        Color = C.controlLine,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, obj)
end

-- Panah "v" dari dua garis; Rotation 180 = "^"
local function createChevron(par, xOff)
    local holder = make("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, xOff or -8, 0.5, 0),
        BackgroundTransparency = 1,
    }, par)
    for _, rot in ipairs({ 45, -45 }) do
        make("Frame", {
            Size = UDim2.new(0, 7, 0, 2),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, rot == 45 and -2 or 2, 0.5, 0),
            Rotation = rot,
            BackgroundColor3 = C.muted,
            BorderSizePixel = 0,
        }, holder)
    end
    return holder
end

-- Kolom info (caption kecil + angka monospace)
local function createCells(container, defs, top, pad)
    local total = 0
    for _, d in ipairs(defs) do total = total + (d.weight or 1) end

    local acc, cells = 0, {}
    for i, d in ipairs(defs) do
        local w = (d.weight or 1) / total
        local x = (i == 1) and (pad or 0) or 10
        local cell = make("Frame", {
            Size = UDim2.new(w, 0, 1, 0),
            Position = UDim2.new(acc, 0, 0, 0),
            BackgroundTransparency = 1,
        }, container)

        make("TextLabel", {
            Size = UDim2.new(1, -x - 4, 0, 12),
            Position = UDim2.new(0, x, 0, top),
            BackgroundTransparency = 1,
            Text = d.caption,
            TextColor3 = C.muted,
            TextSize = 9,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, cell)

        local valueLabel = make("TextLabel", {
            Size = UDim2.new(1, -x - 4, 0, 20),
            Position = UDim2.new(0, x, 0, top + 13),
            BackgroundTransparency = 1,
            Text = d.value or "",
            TextColor3 = C.text,
            TextSize = 14,
            Font = Enum.Font.RobotoMono,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, cell)

        if i > 1 then
            make("Frame", {
                Size = UDim2.new(0, 1, 0, 28),
                Position = UDim2.new(acc, 0, 0, top + 4),
                BackgroundColor3 = C.line,
                BorderSizePixel = 0,
            }, container)
        end

        cells[i] = { frame = cell, value = valueLabel }
        acc = acc + w
    end
    return cells
end

-- Kartu fitur: judul + toggle persegi (opsional) + body (opsional)
local function createFeature(par, title, opts)
    opts = opts or {}
    local bodyH = opts.bodyHeight or 0
    local card = createCard(par, 34 + (bodyH > 0 and (bodyH + 10) or 0))

    local titleLabel = make("TextLabel", {
        Size = UDim2.new(0, 150, 0, 34),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = C.text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)

    local api = { card = card }

    if bodyH > 0 then
        api.body = make("Frame", {
            Size = UDim2.new(1, -24, 0, bodyH),
            Position = UDim2.new(0, 12, 0, 34),
            BackgroundTransparency = 1,
        }, card)
    end

    if opts.noToggle then
        titleLabel.Size = UDim2.new(1, -24, 0, 34)
        api.get = function() return false end
        api.set = function() end
        api.setLocked = function() end
        api.setNote = function() end
        return api
    end

    local note = make("TextLabel", {
        Size = UDim2.new(0, 190, 0, 34),
        Position = UDim2.new(1, -244, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.muted,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)

    local track = make("Frame", {
        Size = UDim2.new(0, 34, 0, 16),
        Position = UDim2.new(1, -48, 0, 9),
        BackgroundColor3 = Color3.fromRGB(34, 34, 37),
        BorderSizePixel = 0,
    }, card)
    local trackStroke = make("UIStroke", {
        Color = C.controlLine,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, track)

    local POS_ON = UDim2.new(1, -13, 0.5, -5)
    local POS_OFF = UDim2.new(0, 3, 0.5, -5)

    local knob = make("Frame", {
        Size = UDim2.new(0, 10, 0, 10),
        Position = POS_OFF,
        BackgroundColor3 = C.muted,
        BorderSizePixel = 0,
    }, track)

    local hit = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 2,
    }, card)

    local state = opts.initial and true or false
    local locked, hint = false, nil

    local function render(animate)
        local tc, kc
        if locked then
            tc, kc = Color3.fromRGB(28, 28, 30), Color3.fromRGB(64, 64, 68)
        elseif state then
            tc, kc = Color3.fromRGB(232, 232, 234), Color3.fromRGB(14, 14, 15)
        else
            tc, kc = Color3.fromRGB(34, 34, 37), C.muted
        end
        local kp = state and POS_ON or POS_OFF
        local sc = (state and not locked) and tc or C.controlLine

        titleLabel.TextColor3 = locked and C.dim or C.text
        titleLabel.Text = (locked and hint) and (title .. "  (" .. hint .. ")") or title

        if animate then
            tween(track, 0.12, { BackgroundColor3 = tc })
            tween(trackStroke, 0.12, { Color = sc })
            tween(knob, 0.12, { BackgroundColor3 = kc, Position = kp })
        else
            track.BackgroundColor3 = tc
            trackStroke.Color = sc
            knob.BackgroundColor3 = kc
            knob.Position = kp
        end
    end

    hit.MouseButton1Click:Connect(function()
        if locked then return end
        state = not state
        render(true)
        if opts.onToggle then opts.onToggle(state) end
    end)

    render(false)

    function api.get() return state end
    function api.set(v)
        state = v and true or false
        render(true)
    end
    function api.setLocked(v, h)
        locked = v
        hint = h
        render(true)
    end
    function api.setNote(t, color)
        t = t or ""
        if note.Text ~= t then note.Text = t end
        note.TextColor3 = color or C.muted
    end
    return api
end

-- Pilihan segmen (mis. 1.5x | 2x)
local function createSegmented(par, props, options, initial, onChange)
    local frame = make("Frame", {
        BackgroundColor3 = C.control,
        BorderSizePixel = 0,
    }, par)
    for k, v in pairs(props) do frame[k] = v end
    styleControl(frame)

    local current = initial
    local buttons = {}
    local n = #options

    local function refresh()
        for _, b in ipairs(buttons) do
            local sel = (b.value == current)
            b.button.BackgroundTransparency = sel and 0 or 1
            b.label.TextColor3 = sel and C.ink or C.muted
        end
    end

    for i, o in ipairs(options) do
        local b = make("TextButton", {
            Size = UDim2.new(1 / n, -2, 1, -4),
            Position = UDim2.new((i - 1) / n, 2, 0, 2),
            BackgroundColor3 = Color3.fromRGB(226, 226, 228),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
        }, frame)
        local label = make("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = o.label,
            TextColor3 = C.muted,
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
        }, b)
        table.insert(buttons, { button = b, label = label, value = o.value })
        b.MouseButton1Click:Connect(function()
            current = o.value
            refresh()
            if onChange then onChange(current) end
        end)
    end

    refresh()
    return {
        get = function() return current end,
        set = function(v) current = v; refresh() end,
    }
end

-- Dropdown asli: panah ke bawah, daftar terbuka ke bawah
local function createSelect(par, props, cfg)
    local options, current = cfg.options, cfg.initial

    local btn = make("TextButton", {
        BackgroundColor3 = C.control,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, par)
    for k, v in pairs(props) do btn[k] = v end
    styleControl(btn)

    local lbl = make("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 9, 0, 0),
        BackgroundTransparency = 1,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, btn)
    local chev = createChevron(btn, -9)

    local function refresh()
        local text
        for _, o in ipairs(options) do
            if o.value == current then text = o.label break end
        end
        if text then
            lbl.Text = (cfg.prefix or "") .. text
            lbl.TextColor3 = C.text
        else
            lbl.Text = cfg.placeholder or "Select"
            lbl.TextColor3 = C.muted
        end
    end

    btn.MouseButton1Click:Connect(function()
        openList(btn, options, current, function(v)
            current = v
            refresh()
            if cfg.onChange then cfg.onChange(v) end
        end, chev)
    end)

    refresh()
    return {
        get = function() return current end,
        set = function(v) current = v; refresh() end,
    }
end

-- Tombol pil persegi (toggle kecil dengan teks)
local function createPill(par, props, text, initial, onChange)
    local state = initial and true or false

    local btn = make("TextButton", {
        BackgroundColor3 = C.control,
        BorderSizePixel = 0,
        Text = text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
    }, par)
    for k, v in pairs(props) do btn[k] = v end
    styleControl(btn)

    local function refresh()
        btn.BackgroundColor3 = state and Color3.fromRGB(226, 226, 228) or C.control
        btn.TextColor3 = state and C.ink or C.muted
    end

    btn.MouseButton1Click:Connect(function()
        state = not state
        refresh()
        if onChange then onChange(state) end
    end)

    refresh()
    return {
        get = function() return state end,
        set = function(v) state = v and true or false; refresh() end,
    }
end

-- Kartu fitur dengan state tersimpan; soon=true menandai belum ada fungsi
local function visualFeature(par, title, key, bodyHeight, build, soon)
    local f = createFeature(par, title, {
        initial = flags[key],
        bodyHeight = bodyHeight,
        onToggle = function(v) setFlag(key, v) end,
    })
    if build and f.body then build(f.body) end
    if soon then f.setNote("SOON", C.dim) end
    return f
end

-- =================================================================
-- Halaman + sidebar
-- =================================================================
local tabs = {}
local TAB_ORDER = { "Main", "Gacha", "Endless", "AFK", "Settings" }

local function selectTab(name)
    closeOverlay()
    for n, t in pairs(tabs) do
        local on = (n == name)
        t.page.Visible = on
        t.label.TextColor3 = on and C.white or C.muted
        t.item.BackgroundTransparency = on and 0 or 1
        t.bar.Visible = on
    end
end

for i, name in ipairs(TAB_ORDER) do
    local item = make("TextButton", {
        Size = UDim2.new(1, -1, 0, 30),
        Position = UDim2.new(0, 0, 0, 8 + (i - 1) * 32),
        BackgroundColor3 = C.white,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, Sidebar)
    grad(item, Color3.fromRGB(54, 54, 58), Color3.fromRGB(30, 30, 33), 0)

    local bar = make("Frame", {
        Size = UDim2.new(0, 2, 1, 0),
        BackgroundColor3 = C.white,
        BorderSizePixel = 0,
        Visible = false,
    }, item)
    local label = make("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = C.muted,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, item)

    local page = make("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Color3.fromRGB(120, 120, 126),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
    }, PageHolder)
    make("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
    }, page)

    tabs[name] = { item = item, bar = bar, label = label, page = page }
    item.MouseButton1Click:Connect(function() selectTab(name) end)
end

-- =================================================================
-- Statistik (Wave x/y, Units, Sell, Upgrade)
-- =================================================================
local statLabels = {}
local stats = { sells = 0, upgrades = 0 }
local waveNow = { cur = nil, max = nil } -- diisi oleh tracking wave

-- =================================================================
-- Main: Play, Speed, Skip, Replay, Lobby
-- Remote dari SPY:
--   JoinQueue(map, jumlah)  SetGameSpeed(kecepatan)  SkipWaveVote(wave)
--   ReplayVote()            ReplicatedStorage.ReturnToLobby()
-- =================================================================
do
    local page = tabs["Main"].page
    local inLobby = (game.PlaceId == LOBBY_PLACE)
    local inMatch = (game.PlaceId == MATCH_PLACE)

    local statCard = createCard(page, 50)
    local cells = createCells(statCard, {
        { caption = "WAVE", value = "-", weight = 1.35 },
        { caption = "UNITS", value = "-", weight = 1 },
        { caption = "SELL", value = "0", weight = 1 },
        { caption = "UPGRADE", value = "0", weight = 1.1 },
    }, 7, 12)
    statLabels.wave = cells[1].value
    statLabels.units = cells[2].value
    statLabels.sells = cells[3].value
    statLabels.upgrades = cells[4].value

    -- Remote Knit (versi paket bisa berubah, jadi dicari lewat nama)
    local function knitRF(service, name)
        local pk = ReplicatedStorage:FindFirstChild("Packages")
        local idx = pk and pk:FindFirstChild("_Index")
        if not idx then return nil end
        for _, pkg in ipairs(idx:GetChildren()) do
            if string.find(pkg.Name, "sleitnick_knit", 1, true) then
                local k = pkg:FindFirstChild("knit")
                local svc = k and k:FindFirstChild("Services")
                local s = svc and svc:FindFirstChild(service)
                local rf = s and s:FindFirstChild("RF")
                local r = rf and rf:FindFirstChild(name)
                if r then return r end
            end
        end
        return nil
    end

    -- ---------------- Auto Play (hanya di lobby) ----------------
    local fPlay = visualFeature(page, "Auto Play", "autoPlay", 28, function(body)
        createSelect(body, {
            Size = UDim2.new(0.62, -4, 1, 0),
        }, {
            options = MAP_OPTIONS,
            initial = flags.playMap,
            placeholder = "Select map",
            onChange = function(v) setFlag("playMap", v) end,
        })
        createSelect(body, {
            Size = UDim2.new(0.38, -4, 1, 0),
            Position = UDim2.new(0.62, 4, 0, 0),
        }, {
            options = PLAYER_OPTIONS,
            initial = flags.playPlayers,
            prefix = "Players ",
            onChange = function(v) setFlag("playPlayers", v) end,
        })
    end)

    local lastJoin = 0
    runLoop(function()
        if not flags.autoPlay then
            fPlay.setNote("")
            lastJoin = 0
            return 0.5
        end
        if not inLobby then
            fPlay.setNote("Only works in the lobby", C.muted)
            return 2
        end
        if flags.playMap == "" then
            fPlay.setNote("Pick a map first", C.warn)
            return 1
        end
        local remote = knitRF("MatchmakingService", "JoinQueue")
        if not remote then
            fPlay.setNote("Loading matchmaking...", C.warn)
            return 1
        end
        -- Kalau teleport belum terjadi, coba lagi setelah 25 detik
        if os.clock() - lastJoin < 25 then
            fPlay.setNote("Joining match...", C.text)
            return 1
        end
        lastJoin = os.clock()
        local ok, res = pcall(function()
            return remote:InvokeServer(flags.playMap, flags.playPlayers)
        end)
        if ok and res ~= false then
            fPlay.setNote("Joining match...", C.text)
        else
            fPlay.setNote("Couldn't join the queue", C.warn)
            lastJoin = os.clock() - 20
        end
        return 1
    end)

    -- ---------------- Auto Speed (hanya di match) ----------------
    local fSpeed
    local function sendSpeed()
        local ev = RE("SetGameSpeed")
        if not ev then return false end
        return pcall(function() ev:FireServer(flags.speedValue) end)
    end

    fSpeed = visualFeature(page, "Auto Speed", "autoSpeed", 28, function(body)
        createSegmented(body, {
            Size = UDim2.new(0, 165, 1, 0),
        }, SPEED_OPTIONS, flags.speedValue, function(v)
            setFlag("speedValue", v)
            if flags.autoSpeed then sendSpeed() end
        end)
    end)

    -- Dikirim ulang tiap 4 detik supaya kecepatan tetap setelah ronde baru
    runLoop(function()
        if not flags.autoSpeed then
            fSpeed.setNote("")
            return 0.5
        end
        if not RE("SetGameSpeed") then
            fSpeed.setNote("Only works in a match", C.muted)
            return 1.5
        end
        if sendSpeed() then
            fSpeed.setNote("Speed " .. tostring(flags.speedValue) .. "x", C.text)
        else
            fSpeed.setNote("Couldn't change speed", C.warn)
        end
        return 4
    end)

    -- ---------------- Auto Skip Wave ----------------
    -- Log: SkipWaveVote(1) lalu SkipWaveVote(2). Belum pasti apakah angkanya
    -- wave yang tampil di HUD atau wave berikutnya, jadi keduanya dikirim
    -- (yang tidak cocok diabaikan server). Atur SKIP_WAVE_OFFSET kalau perlu.
    local fSkip = visualFeature(page, "Auto Skip Wave", "autoSkip", 0)

    local lastSkipped = nil
    runLoop(function()
        if not flags.autoSkip then
            fSkip.setNote("")
            lastSkipped = nil
            return 0.5
        end
        local ev = RE("SkipWaveVote")
        if not ev then
            fSkip.setNote("Only works in a match", C.muted)
            return 1.5
        end
        local w = waveNow.cur
        if not w then
            fSkip.setNote("Reading wave number...", C.warn)
            return 1
        end
        if w == lastSkipped then
            fSkip.setNote("Voted to skip wave " .. w, C.text)
            return 1
        end
        task.wait(1.2) -- beri waktu tombol skip muncul
        if not flags.autoSkip then return 0.5 end
        w = waveNow.cur or w
        lastSkipped = w
        for _, n in ipairs({ w + SKIP_WAVE_OFFSET, w + SKIP_WAVE_OFFSET + 1 }) do
            if n >= 1 then
                pcall(function() ev:FireServer(n) end)
                task.wait(0.15)
            end
        end
        fSkip.setNote("Voted to skip wave " .. w, C.text)
        return 1
    end)

    -- ---------------- Auto Replay / Auto Lobby (layar akhir match) ----------------
    -- Dianggap akhir match kalau tombol/teks "Replay" DAN "Lobby" sama-sama tampil.
    -- Aksi dikirim sekali per layar akhir (vote bisa saja toggle). Replay dan
    -- Lobby saling mematikan supaya tidak bentrok.
    local fReplay, fLobby

    fReplay = createFeature(page, "Auto Replay", {
        initial = flags.autoReplay,
        onToggle = function(v)
            setFlag("autoReplay", v)
            if v and flags.autoLobby then
                setFlag("autoLobby", false)
                fLobby.set(false)
            end
        end,
    })
    fLobby = createFeature(page, "Auto Lobby", {
        initial = flags.autoLobby,
        onToggle = function(v)
            setFlag("autoLobby", v)
            if v and flags.autoReplay then
                setFlag("autoReplay", false)
                fReplay.set(false)
            end
        end,
    })

    local function scanEndScreen()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then return false end
        local hasR, hasL = false, false
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("GuiObject") and (d:IsA("TextButton") or d:IsA("TextLabel") or d:IsA("ImageButton")) then
                local txt = (d:IsA("ImageButton") and "") or string.lower(d.Text)
                local nm = string.lower(d.Name)
                local r = string.find(txt, "replay", 1, true) or string.find(nm, "replay", 1, true)
                local l = string.find(txt, "lobby", 1, true) or string.find(nm, "lobby", 1, true)
                if (r or l) and isShown(d) then
                    if r then hasR = true end
                    if l then hasL = true end
                    if hasR and hasL then return true end
                end
            end
        end
        return false
    end

    local acted = false
    runLoop(function()
        local wantLobby = flags.autoLobby
        local wantReplay = flags.autoReplay and not wantLobby
        if not (wantLobby or wantReplay) then
            fReplay.setNote("")
            fLobby.setNote("")
            acted = false
            return 0.5
        end
        local f = wantLobby and fLobby or fReplay
        local other = wantLobby and fReplay or fLobby
        other.setNote("")

        if not inMatch then
            f.setNote("Only works in a match", C.muted)
            return 2
        end
        if not scanEndScreen() then
            acted = false
            f.setNote("Waiting for the match to end", C.muted)
            return 1.5
        end
        if acted then
            f.setNote(wantLobby and "Returning to lobby..." or "Replay vote sent", C.text)
            return 1.5
        end

        task.wait(0.8) -- beri waktu tombol aktif
        local ev = wantLobby and ReplicatedStorage:FindFirstChild("ReturnToLobby") or RE("ReplayVote")
        if not ev then
            f.setNote("Remote not found", C.warn)
            return 2
        end
        local ok = pcall(function() ev:FireServer() end)
        acted = ok
        if ok then
            f.setNote(wantLobby and "Returning to lobby..." or "Replay vote sent", C.text)
        else
            f.setNote("Couldn't send the vote", C.warn)
        end
        return 1.5
    end)
end

-- =================================================================
-- Gacha: Summon, Spin, Crate, Lucky Block, Potion
-- Argumen SummonUnits, OpenCrate, SpinWheel sudah dicocokkan dengan SPY.
-- Pesan status memakai bahasa biasa; fitur berhenti mengirim remote
-- saat stok / koin / tiket tidak cukup.
-- =================================================================
local counts, summonPrices, tickets = nil, nil, nil
local boost = { inv = {}, rem = {}, at = nil }
local BOOST_FIELD = {
    Money = "MoneyTimeRemaining", XP = "XPTimeRemaining",
    Luck = "LuckTimeRemaining", SummonDiscount = "SummonDiscountTimeRemaining",
}

local function stopFeature(f, key, why)
    setFlag(key, false)
    f.set(false)
    f.setNote("Stopped", C.muted)
    notify("Stopped", why, 5)
end

local function onBoost(t)
    if type(t) ~= "table" then return end
    if type(t.Inventory) == "table" then boost.inv = t.Inventory end
    for k, field in pairs(BOOST_FIELD) do
        if type(t[field]) == "number" then boost.rem[k] = t[field] end
    end
    boost.at = os.clock()
end

bindEvent("CratesUpdated", function(t)
    if type(t) == "table" then counts = t end
end)
bindEvent("SummonStateUpdated", function(t)
    if type(t) == "table" and type(t.Prices) == "table" then summonPrices = t.Prices end
end)
bindEvent("BoostStateUpdated", onBoost)
-- UpdateCurrency dikirim sebagai (nama, jumlah), mis. "Tickets", 68
bindEvent("UpdateCurrency", function(name, amount)
    if name == "Tickets" and type(amount) == "number" then tickets = amount end
end)

-- State awal (kalau game menyediakan)
task.spawn(function()
    local ok, res = invoke("GetBoostState")
    if ok then onBoost(res) end
    local ok2, res2 = invoke("GetCrateState")
    if ok2 and type(res2) == "table" and not counts then
        counts = type(res2.Crates) == "table" and res2.Crates or res2
    end
end)

local function fmtTime(s)
    s = math.max(0, math.floor(s))
    return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

do
    local page = tabs["Gacha"].page

    -- Auto Summon
    local fSummon = visualFeature(page, "Auto Summon", "autoSummon", 28, function(body)
        createSegmented(body, {
            Size = UDim2.new(0, 150, 1, 0),
        }, SUMMON_OPTIONS, flags.summonAmount, function(v)
            setFlag("summonAmount", v)
        end)
    end)

    local summonFails = 0
    runLoop(function()
        if not flags.autoSummon then
            fSummon.setNote("")
            summonFails = 0
            return 0.4
        end
        if LocalPlayer:GetAttribute("_ExclusiveCrateOpening") then
            fSummon.setNote("Waiting for animation", C.warn)
            return 1
        end
        local amount = flags.summonAmount
        local price = summonPrices and (summonPrices[amount] or summonPrices[tostring(amount)])
        if type(price) == "number" and getStat("Coins") < price then
            fSummon.setNote("Not enough coins", C.warn)
            return 1.5
        end
        local ok, res = invoke("SummonUnits", amount)
        if accepted(ok, res) then
            summonFails = 0
            fSummon.setNote("Summoning...", C.text)
        else
            summonFails = summonFails + 1
            fSummon.setNote("Server refused (" .. summonFails .. "/8)", C.warn)
            if summonFails >= 8 then
                summonFails = 0
                stopFeature(fSummon, "autoSummon", "Auto Summon stopped: the server kept refusing the request.")
            end
        end
        return amount >= 10 and 1.2 or 0.6
    end)

    -- Auto Spin
    local fSpin = visualFeature(page, "Auto Spin", "autoSpin", 0)

    runLoop(function()
        if not flags.autoSpin then
            fSpin.setNote("")
            return 0.4
        end
        -- Dari log: 1 spin memakai 1 Ticket dan animasinya sekitar 7 detik
        if tickets and tickets <= 0 then
            fSpin.setNote("Not enough tickets", C.warn)
            return 3
        end
        local ok, res = invoke("SpinWheel")
        if accepted(ok, res) then
            fSpin.setNote("Spinning...", C.text)
            return settings.skipAnim and 1.5 or 7
        end
        fSpin.setNote("Spin isn't ready yet", C.warn)
        return 6
    end)
end

do
    local page = tabs["Gacha"].page

    -- Cek stok crate / lucky block dari CratesUpdated.
    -- Mengembalikan jumlah yang boleh dibuka, atau nil + pesan.
    -- Item yang tidak ada di daftar stok dianggap kosong.
    local noDataSince = nil
    local function stockCheck(id, want, noun)
        if not counts then
            noDataSince = noDataSince or os.clock()
            if os.clock() - noDataSince < 6 then
                return nil, "Loading " .. noun .. " data..."
            end
            return want, nil, true -- data tidak pernah datang: coba saja
        end
        noDataSince = nil
        local have = counts[id]
        if type(have) ~= "number" or have <= 0 then
            return nil, "You don't have this " .. noun
        end
        if have < want then
            return nil, "Not enough " .. noun .. "s (" .. have .. "/" .. want .. ")"
        end
        return want
    end

    -- Auto Open Crate (jumlah + jenis)
    local fCrate = visualFeature(page, "Auto Open Crate", "autoCrate", 28, function(body)
        createSegmented(body, {
            Size = UDim2.new(0, 96, 1, 0),
        }, CRATE_AMOUNT_OPTIONS, flags.crateAmount, function(v)
            setFlag("crateAmount", v)
        end)
        createSelect(body, {
            Size = UDim2.new(1, -104, 1, 0),
            Position = UDim2.new(0, 104, 0, 0),
        }, {
            options = CRATE_OPTIONS,
            initial = flags.crateType,
            placeholder = "Select crate",
            onChange = function(v) setFlag("crateType", v) end,
        })
    end)

    local crateFails = 0
    runLoop(function()
        if not flags.autoCrate then
            fCrate.setNote("")
            crateFails = 0
            return 0.4
        end
        local id = flags.crateType
        if id == "" then
            fCrate.setNote("Pick a crate first", C.warn)
            return 1
        end
        if LocalPlayer:GetAttribute("_ExclusiveCrateOpening") then
            fCrate.setNote("Waiting for animation", C.warn)
            return 1
        end
        local amount, why, blind = stockCheck(id, flags.crateAmount, "crate")
        if not amount then
            fCrate.setNote(why, C.muted)
            return 1.5
        end
        local ok, res = invoke("OpenCrate", id, amount)
        if accepted(ok, res) then
            crateFails = 0
            fCrate.setNote("Opening crates...", C.text)
        else
            crateFails = crateFails + 1
            local limit = blind and 3 or 8
            fCrate.setNote("Server refused (" .. crateFails .. "/" .. limit .. ")", C.warn)
            if crateFails >= limit then
                crateFails = 0
                stopFeature(fCrate, "autoCrate", blind
                    and "Auto Open Crate stopped: you probably don't have this crate."
                    or "Auto Open Crate stopped: the server kept refusing the request.")
            end
        end
        return 1.5
    end)

    -- Auto Open Lucky Block (bukan crate; remote OpenLuckyBlock)
    local fLucky = visualFeature(page, "Auto Open Lucky Block", "autoLucky", 28, function(body)
        createSegmented(body, {
            Size = UDim2.new(0, 96, 1, 0),
        }, CRATE_AMOUNT_OPTIONS, flags.luckyAmount, function(v)
            setFlag("luckyAmount", v)
        end)
        createSelect(body, {
            Size = UDim2.new(1, -104, 1, 0),
            Position = UDim2.new(0, 104, 0, 0),
        }, {
            options = LUCKY_OPTIONS,
            initial = flags.luckyType,
            placeholder = "Select block",
            onChange = function(v) setFlag("luckyType", v) end,
        })
    end)

    local luckyFails = 0
    runLoop(function()
        if not flags.autoLucky then
            fLucky.setNote("")
            luckyFails = 0
            return 0.4
        end
        local id = flags.luckyType
        if id == "" then
            fLucky.setNote("Pick a block first", C.warn)
            return 1
        end
        if LocalPlayer:GetAttribute("_ExclusiveCrateOpening") then
            fLucky.setNote("Waiting for animation", C.warn)
            return 1
        end
        local amount, why, blind = stockCheck(id, flags.luckyAmount, "block")
        if not amount then
            fLucky.setNote(why, C.muted)
            return 1.5
        end
        local ok, res = invoke("OpenLuckyBlock", id, amount)
        if accepted(ok, res) then
            luckyFails = 0
            fLucky.setNote("Opening blocks...", C.text)
        else
            luckyFails = luckyFails + 1
            local limit = blind and 3 or 8
            fLucky.setNote("Server refused (" .. luckyFails .. "/" .. limit .. ")", C.warn)
            if luckyFails >= limit then
                luckyFails = 0
                stopFeature(fLucky, "autoLucky", blind
                    and "Auto Open Lucky Block stopped: you probably don't have this block."
                    or "Auto Open Lucky Block stopped: the server kept refusing the request.")
            end
        end
        return 1.5
    end)

    -- Auto Use Potion: potion bisa di-stack, dipakai terus sampai stok habis
    local fPotion = visualFeature(page, "Auto Use Potion", "autoPotion", 28, function(body)
        createSelect(body, {
            Size = UDim2.new(1, 0, 1, 0),
        }, {
            options = POTION_OPTIONS,
            initial = flags.potionType,
            placeholder = "Select potion",
            onChange = function(v) setFlag("potionType", v) end,
        })
    end)

    local POTION_INTERVAL = 0.3
    local potionFails = 0
    runLoop(function()
        if not flags.autoPotion then
            fPotion.setNote("")
            potionFails = 0
            return 0.5
        end
        local key = flags.potionType
        if key == "" then
            fPotion.setNote("Pick a potion first", C.warn)
            return 1
        end
        if not boost.at then
            fPotion.setNote("Loading potion data...", C.warn)
            return 1
        end
        local have = boost.inv[key] or 0
        if have <= 0 then
            fPotion.setNote("You don't have this potion", C.muted)
            return 2
        end
        local ok, res = invoke("UseBoost", key)
        if accepted(ok, res) then
            potionFails = 0
            local left = (boost.rem[key] or 0) - (os.clock() - boost.at)
            fPotion.setNote("Active " .. fmtTime(left) .. " (" .. math.max(0, have - 1) .. " left)", C.text)
            return POTION_INTERVAL
        end
        potionFails = potionFails + 1
        fPotion.setNote("Server refused (" .. potionFails .. "/8)", C.warn)
        if potionFails >= 8 then
            potionFails = 0
            stopFeature(fPotion, "autoPotion", "Auto Use Potion stopped: the server refused it. You may have hit the stack limit.")
        end
        return 1
    end)
end

-- =================================================================
-- Endless: Auto Upgrade (remote dicari saat match berjalan)
-- =================================================================
do
    local page = tabs["Endless"].page
    local upg
    upg = createFeature(page, "Auto Upgrade", {
        bodyHeight = 28,
        onToggle = function(v)
            run.upgrade = v
            if not v then upg.setNote("") end
        end,
    })

    createSelect(upg.body, {
        Size = UDim2.new(0, 120, 1, 0),
    }, {
        options = DELAY_OPTIONS,
        initial = settings.upgradeDelay,
        prefix = "Delay ",
        onChange = function(v)
            settings.upgradeDelay = v
            saveSettings()
        end,
    })

    createPill(upg.body, {
        Size = UDim2.new(1, -128, 1, 0),
        Position = UDim2.new(0, 128, 0, 0),
    }, "Cheapest first", settings.cheapestFirst, function(v)
        settings.cheapestFirst = v
        saveSettings()
    end)

    local failures, blocked = {}, {}

    local function getMyTowers()
        local list = {}
        local folder = workspace:FindFirstChild("Towers")
        if folder then
            for _, t in ipairs(folder:GetChildren()) do
                if t:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
                    table.insert(list, t)
                end
            end
        end
        return list
    end

    local function signature(t)
        return tostring(t:GetAttribute("Level")) .. ":" .. tostring(t:GetAttribute("UpgradePrice"))
    end

    -- Mengembalikan tower target, atau nil + alasan ("MAX" / "WAIT")
    local function pickTarget(towers, cash)
        local candidates = {}
        for _, t in ipairs(towers) do
            local price = t:GetAttribute("UpgradePrice")
            if type(price) == "number" and price > 0 then
                local b = blocked[t]
                local isBlocked = b and b.sig == signature(t) and (tick() - b.time) < 30
                if not isBlocked then
                    table.insert(candidates, { tower = t, price = price })
                end
            end
        end

        if #candidates == 0 then return nil, "MAX" end
        if settings.cheapestFirst then
            table.sort(candidates, function(a, b) return a.price < b.price end)
        end

        local first = candidates[1]
        if cash >= first.price then return first.tower end
        return nil, "WAIT"
    end

    runLoop(function()
        if not run.upgrade then return 0.3 end

        local remote = RF("UpgradeTower")
        if not remote then
            upg.setNote("Only works in a match", C.muted)
            return 1
        end

        local towers = getMyTowers()
        if #towers == 0 then
            upg.setNote("No towers placed", C.muted)
            return 1
        end

        local target, reason = pickTarget(towers, getStat("Cash"))
        if target then
            upg.setNote("Upgrading...", C.text)
            local sig = signature(target)
            local ok, res = pcall(function() return remote:InvokeServer(target) end)

            if ok and res == true then
                failures[target] = nil
            else
                local f = failures[target]
                if not f or f.sig ~= sig then f = { sig = sig, count = 0 } end
                f.count = f.count + 1
                failures[target] = f
                if f.count >= 3 then
                    blocked[target] = { sig = sig, time = tick() }
                    failures[target] = nil
                end
            end
            return settings.upgradeDelay
        elseif reason == "MAX" then
            upg.setNote("All towers maxed", C.muted)
            return 1
        end
        upg.setNote("Not enough cash", C.warn)
        return math.max(0.1, math.min(settings.upgradeDelay, 0.5))
    end)
end

-- =================================================================
-- AFK: Auto Claim Gift + Anti AFK
-- =================================================================
do
    local page = tabs["AFK"].page
    local GIFT_COUNT = 9
    local claimedCount = 0
    local applyClaimState

    local feature = createFeature(page, "Auto Claim Gift", {
        bodyHeight = 38,
        onToggle = function(v) applyClaimState(v, true) end,
    })

    local cells = createCells(feature.body, {
        { caption = "ID", value = "-----", weight = 1.15 },
        { caption = "GIFT", value = "0/9", weight = 0.9 },
        { caption = "STATUS", value = "Idle", weight = 1 },
    }, 0, 0)
    local IdValueLabel = cells[1].value
    local GiftValueLabel = cells[2].value
    local StatusValue = cells[3].value

    local function setStatus(text, color)
        StatusValue.Text = text
        StatusValue.TextColor3 = color
    end
    setStatus("Idle", C.muted)

    -- Jumlah bit yang menyala di bitmask PlaytimeGiftClaimed
    local function popcount(mask)
        local n = 0
        for i = 0, GIFT_COUNT - 1 do
            if math.floor(mask / (2 ^ i)) % 2 == 1 then n = n + 1 end
        end
        return n
    end

    -- ID periode SELALU dari game. Tidak pernah ditebak atau ditambah sendiri.
    local function readGameDay()
        local d = LocalPlayer:GetAttribute("PlaytimeGiftDay")
        if type(d) == "number" and d > 0 then
            local loaded = LocalPlayer:GetAttribute("PlayerDataLoaded")
            if loaded == nil or loaded == true then
                return d
            end
        end
        return nil
    end

    applyClaimState = function(v, fromUser)
        run.claim = v
        if v then
            setStatus("Claiming", C.text)
        else
            setStatus("Idle", C.muted)
        end
        if fromUser then
            settings.claimEnabled = v
            saveSettings()
        end
    end

    -- Toggle terkunci sampai data ID dari game tersedia
    local lastLocked, lastShownId = nil, nil
    local function refreshLock()
        local id = readGameDay()
        if id ~= lastShownId then
            lastShownId = id
            IdValueLabel.Text = id and tostring(id) or "-----"
        end

        local locked = (id == nil) and not run.claim
        if locked ~= lastLocked then
            lastLocked = locked
            if locked then
                feature.setLocked(true)
                feature.setNote("Waiting for game data", C.warn)
            else
                feature.setLocked(false)
                feature.setNote("")
            end
        end
    end
    refreshLock()

    local wantAutoStart = settings.claimEnabled
    local lastValidDay, staleMask, backoff = nil, nil, 5

    -- Progress dari game; boleh lebih tinggi dari hitungan lokal, tidak boleh lebih rendah
    local function syncFromGame()
        local mask = LocalPlayer:GetAttribute("PlaytimeGiftClaimed")
        if type(mask) ~= "number" then return end
        if staleMask ~= nil then
            if mask == staleMask then return end
            staleMask = nil
        end
        claimedCount = math.max(claimedCount, popcount(mask))
    end

    runLoop(function()
        refreshLock()
        local day = readGameDay()
        local remote = RF("ClaimPlaytimeGift")

        if wantAutoStart and day and not run.claim then
            wantAutoStart = false
            feature.set(true)
            applyClaimState(true, false)
        end

        -- ID baru dari game: reset progress, beri waktu data baru masuk
        if day and day ~= lastValidDay then
            local changed = (lastValidDay ~= nil)
            lastValidDay = day
            backoff = 5
            if changed then
                claimedCount = 0
                local mask = LocalPlayer:GetAttribute("PlaytimeGiftClaimed")
                if type(mask) == "number" and popcount(mask) >= GIFT_COUNT then
                    staleMask = mask
                end
                task.wait(2)
                day = readGameDay()
            end
        end

        syncFromGame()
        GiftValueLabel.Text = tostring(claimedCount) .. "/" .. GIFT_COUNT

        if not run.claim then return 1 end
        if not day then
            setStatus("Loading", C.warn)
            return 1
        end
        if not remote then
            setStatus("Unavailable", C.muted)
            return 2
        end
        if claimedCount >= GIFT_COUNT then
            setStatus("All claimed", C.muted)
            return 1
        end

        local startIdx = claimedCount + 1
        local hasMask = type(LocalPlayer:GetAttribute("PlaytimeGiftClaimed")) == "number"
        local lastIdx = hasMask and startIdx or GIFT_COUNT
        local claimedAny = false

        setStatus("Claiming", C.text)
        for giftIndex = startIdx, lastIdx do
            if not run.claim or not ScreenGui.Parent then break end
            -- Pastikan ID masih sama tepat sebelum klaim
            if readGameDay() ~= day then break end

            local ok, res = pcall(function()
                return remote:InvokeServer(giftIndex, day)
            end)
            if ok and res == true then
                claimedCount = giftIndex
                claimedAny = true
                notify("Reward Claimed", "Claimed Gift #" .. giftIndex .. " for ID " .. tostring(day), 2)
            end
            if giftIndex < lastIdx then task.wait(0.5) end
        end
        GiftValueLabel.Text = tostring(claimedCount) .. "/" .. GIFT_COUNT

        if claimedAny then
            backoff = 5
            return 1.5
        end
        if run.claim and claimedCount < GIFT_COUNT and readGameDay() == day then
            -- Gift berikutnya belum terbuka: tunggu, bangun lebih awal kalau ID berganti
            setStatus("Waiting", C.warn)
            for _ = 1, backoff do
                if not run.claim or not ScreenGui.Parent then break end
                if readGameDay() ~= day then break end
                task.wait(1)
            end
            backoff = math.min(backoff + 5, 15)
        end
        return 0.5
    end)

    createFeature(page, "Anti AFK", {
        initial = settings.antiAfk,
        onToggle = function(v)
            settings.antiAfk = v
            saveSettings()
        end,
    })
end

-- =================================================================
-- Skip animation: mematikan handler animasi bawaan game di sisi client
-- (crate/lucky block lewat CrateOpening & LuckyBlockOpening, mythic summon
-- lewat MythicSummoned). Handler dikembalikan saat dimatikan atau GUI ditutup.
-- =================================================================
local ANIM_EVENTS = {
    crate = { "CrateOpening", "LuckyBlockOpening" },
    summon = { "MythicSummoned" },
}
local skipDisabled = {}

local function applySkip(group, on)
    if not getconnections then return false end
    skipDisabled[group] = skipDisabled[group] or {}
    local store = skipDisabled[group]

    if on then
        local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not folder then return false end
        for _, name in ipairs(ANIM_EVENTS[group]) do
            local ev = folder:FindFirstChild(name)
            if ev and ev:IsA("RemoteEvent") then
                pcall(function()
                    for _, c in ipairs(getconnections(ev.OnClientEvent)) do
                        if not store[c] then
                            c:Disable()
                            store[c] = true
                        end
                    end
                end)
            end
        end
    else
        for c in pairs(store) do
            pcall(function() c:Enable() end)
            store[c] = nil
        end
    end
    return true
end

-- Pasang ulang berkala supaya handler baru yang dibuat game ikut dimatikan
runLoop(function()
    if settings.skipAnim then
        applySkip("crate", true)
        applySkip("summon", true)
    end
    return 3
end)

-- Re-run otomatis setelah teleport (butuh script disimpan sebagai LightHub.lua
-- di folder workspace executor dan dukungan queue_on_teleport)
local RERUN_FILE = "LightHub.lua"

local function queueRerun()
    local q = queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)
    if not q then return false, "Your executor doesn't support queue_on_teleport." end
    if not (isfile and isfile(RERUN_FILE)) then
        return false, "Save this script as " .. RERUN_FILE .. " in your executor's workspace folder first."
    end
    pcall(q, 'loadstring(readfile("' .. RERUN_FILE .. '"))()')
    return true
end

-- =================================================================
-- Settings
-- =================================================================
do
    local page = tabs["Settings"].page

    createFeature(page, "Show timer", {
        initial = settings.showTimer,
        onToggle = function(v)
            settings.showTimer = v
            applyTimerVisibility()
            saveSettings()
        end,
    })

    -- Satu tombol untuk semua animasi: crate, lucky block, summon, spin
    local fSkipAnim
    fSkipAnim = createFeature(page, "Skip Animations", {
        initial = settings.skipAnim,
        onToggle = function(v)
            settings.skipAnim = v
            saveSettings()
            if getconnections then
                applySkip("crate", v)
                applySkip("summon", v)
            elseif v then
                notify("Skip Animations", "Your executor can't hide crate/summon animations. Only the spin delay gets shorter.", 5)
            end
        end,
    })
    if not getconnections then fSkipAnim.setNote("Spin only", C.muted) end

    createFeature(page, "Animated background", {
        initial = settings.fluidBg,
        onToggle = function(v)
            settings.fluidBg = v
            applyFluid()
            saveSettings()
        end,
    })

    local fRerun
    fRerun = createFeature(page, "Re-run after teleport", {
        initial = settings.rerun,
        onToggle = function(v)
            if v then
                local ok, why = queueRerun()
                if not ok then
                    fRerun.set(false)
                    notify("Re-run", why, 6)
                    return
                end
            end
            settings.rerun = v
            saveSettings()
        end,
    })

    local info = createFeature(page, "Account", { noToggle = true, bodyHeight = 38 })
    createCells(info.body, {
        { caption = "USERNAME", value = LocalPlayer.Name, weight = 1.3 },
        { caption = "DISPLAY", value = LocalPlayer.DisplayName, weight = 1.3 },
        { caption = "VERSION", value = "v" .. VERSION, weight = 0.8 },
    }, 0, 0)
end

-- =================================================================
-- Tracking statistik (units, sell, upgrade, wave)
-- =================================================================
local towerConns = {}

do
    local watched, towerLevels = {}, {}
    local pendingSells, sellScheduled = 0, false
    local hookedFolder = nil

    local function isMine(t)
        return t:GetAttribute("OwnerUserId") == LocalPlayer.UserId
    end

    -- Sell = tower milikmu yang hilang. Kalau 3+ hilang bersamaan
    -- (misal match selesai), tidak dihitung sebagai sell.
    local function registerSell()
        pendingSells = pendingSells + 1
        if sellScheduled then return end
        sellScheduled = true
        task.delay(0.4, function()
            if pendingSells < 3 then
                stats.sells = stats.sells + pendingSells
            end
            pendingSells = 0
            sellScheduled = false
        end)
    end

    local function watchTower(t)
        if watched[t] then return end
        watched[t] = true
        towerLevels[t] = t:GetAttribute("Level")

        towerConns[t] = t:GetAttributeChangedSignal("Level"):Connect(function()
            local new = t:GetAttribute("Level")
            local old = towerLevels[t]
            towerLevels[t] = new
            if type(new) == "number" and type(old) == "number" and new > old and isMine(t) then
                stats.upgrades = stats.upgrades + (new - old)
            end
        end)
    end

    local function unwatchTower(t)
        if towerConns[t] then
            towerConns[t]:Disconnect()
            towerConns[t] = nil
        end
        watched[t] = nil
        towerLevels[t] = nil
    end

    local function hookFolder(folder)
        for _, t in ipairs(folder:GetChildren()) do
            watchTower(t)
        end
        table.insert(conns, folder.ChildAdded:Connect(function(t)
            task.defer(watchTower, t)
        end))
        table.insert(conns, folder.ChildRemoved:Connect(function(t)
            if isMine(t) then registerSell() end
            unwatchTower(t)
        end))
    end

    -- ---------------- Wave sekarang / wave akhir (mis. 8/60) ----------------
    -- Sumber 1: teks HUD yang benar-benar tampil (ancestor ikut dicek).
    -- Sumber 2: Attribute / Value bernama "wave" di workspace / ReplicatedStorage.
    local WAVE_BAD = { "best", "record", "highest", "weekly", "reward", "cooldown" }
    local WAVE_END_HINTS = { "max", "total", "final", "end", "last", "limit", "goal", "target", "required" }

    local function hasAny(l, list)
        for _, w in ipairs(list) do
            if string.find(l, w, 1, true) then return true end
        end
        return false
    end

    local function isWaveName(name)
        local l = string.lower(tostring(name))
        return string.find(l, "wave", 1, true) and not hasAny(l, WAVE_BAD) and not hasAny(l, WAVE_END_HINTS)
    end

    local function isWaveEndName(name)
        local l = string.lower(tostring(name))
        return string.find(l, "wave", 1, true) and hasAny(l, WAVE_END_HINTS) and not hasAny(l, WAVE_BAD)
    end

    local function stripTags(s)
        return (string.gsub(s, "<[^>]+>", ""))
    end

    -- "Wave 8/60", "WAVE: 8 / 60", "8/60 Wave", "Wave 8"
    local function parseWave(text)
        text = string.gsub(stripTags(text), "%s+", " ")
        local c, m = string.match(text, "[Ww][Aa][Vv][Ee]%s*:?%s*(%d+)%s*/%s*(%d+)")
        if c then return tonumber(c), tonumber(m) end
        c, m = string.match(text, "(%d+)%s*/%s*(%d+)%s*[Ww][Aa][Vv][Ee]")
        if c then return tonumber(c), tonumber(m) end
        c = string.match(text, "^%s*[Ww][Aa][Vv][Ee]%s*:?%s*(%d+)%s*$")
        if c then return tonumber(c), nil end
        return nil, nil
    end

    -- Label bernama "Wave" yang isinya hanya "8/60"
    local function parseRatio(text)
        local c, m = string.match(stripTags(text), "^%s*(%d+)%s*/%s*(%d+)%s*$")
        if c then return tonumber(c), tonumber(m) end
        return nil, nil
    end

    local waveLabel, lastScan = nil, 0
    local attrGetters, lastAttrScan = nil, 0

    local function labelWave(d)
        local c, m = parseWave(d.Text)
        if not c and string.find(string.lower(d.Name), "wave", 1, true) then
            c, m = parseRatio(d.Text)
        end
        return c, m
    end

    local function badLabel(d)
        local low = string.lower(d.Name .. " " .. d.Text)
        return hasAny(low, WAVE_BAD)
    end

    local function scanAttrGetters()
        local curG, endG
        local function consider(name, getter)
            if not curG and isWaveName(name) then
                curG = getter
            elseif not endG and isWaveEndName(name) then
                endG = getter
            end
        end
        for _, holder in ipairs({ workspace, ReplicatedStorage }) do
            for name, val in pairs(holder:GetAttributes()) do
                if type(val) == "number" then
                    consider(name, function() return holder:GetAttribute(name) end)
                end
            end
        end
        for _, pool in ipairs({ ReplicatedStorage:GetDescendants(), workspace:GetChildren() }) do
            for _, inst in ipairs(pool) do
                if inst:IsA("IntValue") or inst:IsA("NumberValue") then
                    consider(inst.Name, function() return inst.Value end)
                end
            end
        end
        if curG then return { cur = curG, max = endG } end
        return nil
    end

    local function readWave()
        local c0, m0
        -- 1) Label yang sudah ditemukan: dipakai selama masih tampil dan terbaca
        if waveLabel then
            if waveLabel.Parent and isShown(waveLabel) then
                c0, m0 = labelWave(waveLabel)
                if c0 and m0 then return c0, m0 end
            end
            if not c0 then waveLabel = nil end
        end

        -- 2) Cari label HUD (tiap 2 detik); utamakan yang punya angka sekarang dan akhir
        if tick() - lastScan > 2 then
            lastScan = tick()
            local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if pg then
                local fallback
                for _, d in ipairs(pg:GetDescendants()) do
                    if (d:IsA("TextLabel") or d:IsA("TextButton")) and isShown(d) and not badLabel(d) then
                        local c, m = labelWave(d)
                        if c and m and c <= m then
                            waveLabel = d
                            return c, m
                        elseif c and not fallback then
                            fallback = d
                        end
                    end
                end
                if fallback and not waveLabel then waveLabel = fallback end
            end
        end
        if waveLabel and not c0 then
            c0, m0 = labelWave(waveLabel)
        end
        if c0 then return c0, m0 end

        -- 3) Attribute / Value
        if not attrGetters and tick() - lastAttrScan > 10 then
            lastAttrScan = tick()
            attrGetters = scanAttrGetters()
        end
        if attrGetters then
            local ok, c = pcall(attrGetters.cur)
            if ok and type(c) == "number" then
                local m = nil
                if attrGetters.max then
                    local ok2, mm = pcall(attrGetters.max)
                    if ok2 and type(mm) == "number" then m = mm end
                end
                return c, m
            end
            attrGetters = nil
        end
        return nil, nil
    end

    local lastMax = nil

    runLoop(function()
        local folder = workspace:FindFirstChild("Towers")
        if folder and folder ~= hookedFolder then
            hookedFolder = folder
            hookFolder(folder)
        end

        -- Wave: sekarang/akhir. Wave akhir diingat kalau sempat terbaca.
        local ok, cur, max = pcall(readWave)
        if ok and type(cur) == "number" then
            if type(max) == "number" and max > 0 then
                lastMax = max
            else
                max = lastMax
            end
            waveNow.cur, waveNow.max = cur, max
            statLabels.wave.Text = max and (tostring(cur) .. "/" .. tostring(max)) or tostring(cur)
        else
            waveNow.cur, waveNow.max = nil, nil
            lastMax = nil
            statLabels.wave.Text = "-"
        end

        -- Units
        local pu = LocalPlayer:FindFirstChild("PlacedUnits")
        local maxU = LocalPlayer:GetAttribute("MaxPlacedUnits")
        local unitsText = pu and tostring(pu.Value) or "-"
        if pu and type(maxU) == "number" then
            unitsText = unitsText .. "/" .. tostring(maxU)
        end
        statLabels.units.Text = unitsText

        statLabels.sells.Text = tostring(stats.sells)
        statLabels.upgrades.Text = tostring(stats.upgrades)
        return 0.5
    end)
end

-- =================================================================
-- Timer, tombol header, cleanup
-- =================================================================
local startTime = os.clock()

runLoop(function()
    local elapsed = math.floor(os.clock() - startTime)
    TimerLabel.Text = string.format("%02d:%02d:%02d",
        math.floor(elapsed / 3600),
        math.floor((elapsed % 3600) / 60),
        elapsed % 60)
    return 1
end)

local function cleanup()
    run.claim = false
    run.upgrade = false
    pcall(function() applySkip("crate", false) end)
    pcall(function() applySkip("summon", false) end)
    pcall(function() idledConn:Disconnect() end)
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    for _, c in pairs(towerConns) do pcall(function() c:Disconnect() end) end
    pcall(function() ScreenGui:Destroy() end)
    if env.AFKHubConn == idledConn then env.AFKHubConn = nil end
    env.LightHubCleanup = nil
end
env.LightHubCleanup = cleanup

local minimized = false

MinimizeBtn.MouseButton1Click:Connect(function()
    closeOverlay()
    minimized = not minimized
    Body.Visible = not minimized
    MinLine.Visible = not minimized
    MinBox.Visible = minimized
    tween(MainFrame, 0.15, { Size = UDim2.new(0, WIN_W, 0, minimized and HEADER_H or WIN_H) })
end)

CloseBtn.MouseButton1Click:Connect(function()
    notify("Terminated", "Light closed. All features stopped.", 2)
    cleanup()
end)

if settings.rerun then pcall(queueRerun) end
selectTab("Main")
notify("Loaded", "Welcome, " .. LocalPlayer.DisplayName, 3)
