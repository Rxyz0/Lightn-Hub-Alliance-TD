-- =================================================================
-- LIGHTN HUB v4.1
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

local VERSION = "4.1"
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
local MODE_OPTIONS = {
    { label = "Easy", value = "Easy" },
    { label = "Medium", value = "Medium" },
    { label = "Hard", value = "Hard" },
    { label = "Insane", value = "Insane" },
    { label = "Crazy", value = "Crazy" },
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
    macroSelected = "", macroRecord = false, macroPlay = false,
    autoSpeed = false, speedValue = 1.5,
    autoMode = false, modeValue = "",
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
            Title = "Lightn Hub • " .. sub,
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
    if flags.modeValue ~= "" and not inOptions(MODE_OPTIONS, flags.modeValue) then flags.modeValue = "" end
    if flags.macroSelected ~= "" and not (isfile and isfile("LightHub_Macro_" .. flags.macroSelected .. ".json")) then
        flags.macroSelected = ""
    end
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

-- Gradient papan (kartu, header, sidebar, tab) berayun pelan; tiap papan
-- punya fase dan kecepatan sendiri sehingga tidak selaras dengan teks judul.
local movers = {}
local function swing(frame, lo, hi, base, amp, speed, phase)
    local g = make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, lo),
            ColorSequenceKeypoint.new(0.5, hi),
            ColorSequenceKeypoint.new(1, lo),
        }),
        Rotation = base,
    }, frame)
    movers[#movers + 1] = { g = g, base = base, amp = amp, speed = speed, phase = phase or 0 }
    return g
end

-- Warna teks judul: pita abu-abu ke putih yang mengalir pelan ke kanan
local function titleSeq(t)
    local kps = {}
    local n = 6
    for i = 0, n do
        local x = i / n
        local v = 0.5 + 0.5 * math.sin((x * 1.3 - t * 0.12) * math.pi * 2)
        local g = math.floor(125 + 130 * v)
        kps[#kps + 1] = ColorSequenceKeypoint.new(x, Color3.fromRGB(g, g, g))
    end
    return ColorSequence.new(kps)
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
    if fluid.acc < 0.06 then return end -- ~16 fps cukup untuk gerakan lambat
    fluid.t = fluid.t + fluid.acc
    fluid.acc = 0
    local t = fluid.t
    fluid.gradA.Rotation = (t * 4) % 360
    fluid.gradA.Offset = Vector2.new(math.sin(t * 0.21) * 0.12, math.cos(t * 0.17) * 0.12)
    fluid.gradB.Rotation = (120 - t * 3) % 360
    fluid.gradB.Offset = Vector2.new(math.cos(t * 0.13) * 0.12, math.sin(t * 0.19) * 0.12)
    for _, m in ipairs(movers) do
        m.g.Rotation = m.base + math.sin(t * m.speed + m.phase) * m.amp
    end
    if fluid.titleGrad then fluid.titleGrad.Color = titleSeq(t) end
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
swing(Header, Color3.fromRGB(8, 8, 9), Color3.fromRGB(26, 26, 30), 0, 25, 0.16, 0.5)
make("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
}, Header)

local TitleRow = make("Frame", {
    Size = UDim2.new(0, 220, 1, 0),
    Position = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1,
}, Header)
make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 7),
}, TitleRow)
local TitleLabel = make("TextLabel", {
    Size = UDim2.new(0, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Text = "LIGHTN HUB",
    TextColor3 = C.white,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    LayoutOrder = 1,
}, TitleRow)
fluid.titleGrad = make("UIGradient", { Color = titleSeq(0) }, TitleLabel)
local VersionLabel = make("TextLabel", {
    Size = UDim2.new(0, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Text = "v" .. VERSION,
    TextColor3 = C.muted,
    TextSize = 10,
    Font = Enum.Font.GothamMedium,
    LayoutOrder = 2,
}, TitleRow)

local TimerLabel = make("TextLabel", {
    Size = UDim2.new(0, 84, 1, 0),
    Position = UDim2.new(1, -158, 0, 0),
    BackgroundTransparency = 1,
    Text = "00:00:00",
    TextColor3 = C.white,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Right,
}, Header)

local ui = { minimized = false }

local function applyTimerVisibility()
    -- Saat diperkecil, timer selalu tampil
    TimerLabel.Visible = settings.showTimer or ui.minimized
end
applyTimerVisibility()

-- Wave sekarang, hanya tampil saat window diperkecil
local MiniWave = make("Frame", {
    Size = UDim2.new(0, 76, 1, -1),
    Position = UDim2.new(0, 106, 0, 0),
    BackgroundTransparency = 1,
    Visible = false,
}, Header)
make("Frame", {
    Size = UDim2.new(0, 1, 0, 20),
    Position = UDim2.new(0, -8, 0.5, -10),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
}, MiniWave)
make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 10),
    Position = UDim2.new(0, 0, 0, 4),
    BackgroundTransparency = 1,
    Text = "WAVE",
    TextColor3 = C.muted,
    TextSize = 8,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, MiniWave)
local MiniWaveValue = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.new(0, 0, 0, 12),
    BackgroundTransparency = 1,
    Text = "-",
    TextColor3 = C.white,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, MiniWave)

-- Bar progres wave di tepi bawah, hanya saat diperkecil
local MiniBarTrack = make("Frame", {
    Size = UDim2.new(1, 0, 0, 2),
    Position = UDim2.new(0, 0, 1, -3),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
    Visible = false,
}, Header)
local MiniBarFill = make("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = C.white,
    BorderSizePixel = 0,
}, MiniBarTrack)

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
local CloseBars = { iconBar(CloseBtn, 13, 2, 45), iconBar(CloseBtn, 13, 2, -45) }

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
swing(Sidebar, Color3.fromRGB(9, 9, 10), Color3.fromRGB(24, 24, 27), 90, 30, 0.14, 2.1)
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

-- Daftar panjang bisa di-scroll dan punya tombol Close
local ListScroll = make("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Color3.fromRGB(120, 120, 126),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 3,
}, ListFrame)

local CloseRow = make("TextButton", {
    Size = UDim2.new(1, -4, 0, 22),
    BackgroundColor3 = C.hover,
    BackgroundTransparency = 0.4,
    BorderSizePixel = 0,
    Text = "Close  x",
    TextColor3 = C.muted,
    TextSize = 10,
    Font = Enum.Font.GothamMedium,
    AutoButtonColor = false,
    Visible = false,
    ZIndex = 3,
}, ListFrame)
CloseRow.MouseButton1Click:Connect(closeOverlay)

local MAX_VISIBLE = 6

local function openList(anchor, options, current, onPick, chev)
    closeOverlay()
    for _, c in ipairs(ListScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    local itemH = 26
    local shown = math.min(#options, MAX_VISIBLE)
    local long = #options > MAX_VISIBLE
    local h = shown * itemH + 4 + (long and 24 or 0)
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

    ListScroll.Size = UDim2.new(1, 0, 0, shown * itemH + 4)
    ListScroll.CanvasSize = UDim2.new(0, 0, 0, #options * itemH + 4)
    ListScroll.CanvasPosition = Vector2.new(0, 0)
    CloseRow.Visible = long
    CloseRow.Position = UDim2.new(0, 2, 0, shown * itemH + 6)

    for i, o in ipairs(options) do
        local selected = (o.value == current)
        local b = make("TextButton", {
            Size = UDim2.new(1, long and -8 or -4, 0, itemH),
            Position = UDim2.new(0, 2, 0, 2 + (i - 1) * itemH),
            BackgroundColor3 = C.hover,
            BackgroundTransparency = selected and 0 or 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 4,
        }, ListScroll)
        make("TextLabel", {
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = o.label,
            TextColor3 = selected and C.white or C.muted,
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5,
        }, b)
        if selected then
            make("Frame", {
                Size = UDim2.new(0, 2, 1, 0),
                BackgroundColor3 = C.white,
                BorderSizePixel = 0,
                ZIndex = 5,
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
    swing(card, Color3.fromRGB(24, 24, 27), Color3.fromRGB(46, 46, 50), 90, 38, 0.18 + (#movers % 4) * 0.035, #movers * 1.7)
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
        if cfg.getOptions then
            if current and current ~= "" then text = tostring(current) end
        else
            for _, o in ipairs(options) do
                if o.value == current then text = o.label break end
            end
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
        if cfg.getOptions then
            options = cfg.getOptions()
            if #options == 0 then
                notify("Select", cfg.emptyMsg or "Nothing to select yet.", 3)
                return
            end
        end
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

-- Tombol biasa
local function createButton(par, props, text, onClick)
    local btn = make("TextButton", {
        BackgroundColor3 = C.control,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
    }, par)
    for k, v in pairs(props) do btn[k] = v end
    styleControl(btn)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.hover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.control end)
    btn.MouseButton1Click:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(96, 96, 102)
        tween(btn, 0.25, { BackgroundColor3 = C.control })
        if onClick then onClick() end
    end)
    return btn
end

-- Kotak input teks (multiline untuk JSON)
local function createInput(par, props, placeholder, multiline)
    local box = make("TextBox", {
        BackgroundColor3 = C.control,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = C.dim,
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        ClearTextOnFocus = false,
        MultiLine = multiline and true or false,
        TextWrapped = multiline and true or false,
        ClipsDescendants = true,
    }, par)
    for k, v in pairs(props) do box[k] = v end
    styleControl(box)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, multiline and 6 or 0),
    }, box)
    return box
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
local TAB_ORDER = { "Main", "Gacha", "Inventory", "Fishing", "Endless", "Macro", "AFK", "Settings" }

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
    swing(item, Color3.fromRGB(32, 32, 36), Color3.fromRGB(62, 62, 67), 0, 30, 0.22, i * 1.3)

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
-- Remote fishing: ReplicatedStorage.Fishing.Remotes.<nama>
-- =================================================================
local function fishRemote(name)
    local root = ReplicatedStorage:FindFirstChild("Fishing")
    local remotes = root and root:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild(name)
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

    -- ---------------- Auto Select Mode (voting mode, hanya di match) ----------------
    -- ReplicatedStorage.ModeVote.Vote:FireServer("Crazy"). Dikirim sekali
    -- tiap remote muncul atau pilihan berubah.
    local fMode = visualFeature(page, "Auto Select Mode", "autoMode", 28, function(body)
        createSelect(body, {
            Size = UDim2.new(1, 0, 1, 0),
        }, {
            options = MODE_OPTIONS,
            initial = flags.modeValue,
            placeholder = "Select mode",
            onChange = function(v) setFlag("modeValue", v) end,
        })
    end)

    local votedMode = nil
    runLoop(function()
        if not flags.autoMode then
            fMode.setNote("")
            votedMode = nil
            return 0.5
        end
        if not inMatch then
            fMode.setNote("Only works in a match", C.muted)
            votedMode = nil
            return 2
        end
        local mode = flags.modeValue
        if mode == "" then
            fMode.setNote("Pick a mode first", C.warn)
            return 1
        end
        local folder = ReplicatedStorage:FindFirstChild("ModeVote")
        local ev = folder and folder:FindFirstChild("Vote")
        if not ev then
            fMode.setNote("Waiting for mode voting", C.muted)
            votedMode = nil
            return 1.5
        end
        if votedMode == mode then
            fMode.setNote("Voted " .. mode, C.text)
            return 1.5
        end
        task.wait(0.8) -- beri waktu UI voting siap
        if not flags.autoMode or flags.modeValue ~= mode then return 0.5 end
        local ok = pcall(function() ev:FireServer(mode) end)
        if ok then
            votedMode = mode
            fMode.setNote("Voted " .. mode, C.text)
        else
            fMode.setNote("Couldn't send the vote", C.warn)
        end
        return 1.5
    end)

    -- ---------------- Auto Skip Wave ----------------
    -- 1) Kalau tombol Skip tampil di layar, diklik lewat game sendiri, jadi
    --    argumen SkipWaveVote selalu benar dan tidak perlu membaca nomor wave.
    -- 2) Kalau tombol tidak ketemu: SkipWaveVote(wave) dan (wave+1) langsung.
    -- 3) Kalau wave tidak terbaca: menebak urutan 1, 2, 3, ...
    local fSkip = visualFeature(page, "Auto Skip Wave", "autoSkip", 0)

    local function findSkipButton()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then return nil end
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("GuiButton") and isShown(d) then
                local txt = d:IsA("TextButton") and d.Text or ""
                if txt == "" then
                    local tl = d:FindFirstChildWhichIsA("TextLabel", true)
                    if tl then txt = tl.Text end
                end
                local low = string.lower(txt .. " " .. d.Name)
                if string.find(low, "skip", 1, true)
                    and not string.find(low, "anim", 1, true)
                    and not string.find(low, "tutorial", 1, true)
                    and not string.find(low, "cutscene", 1, true) then
                    return d
                end
            end
        end
        return nil
    end

    local function pressButton(btn)
        local fired = false
        if getconnections then
            for _, sig in ipairs({ btn.MouseButton1Click, btn.Activated }) do
                local ok, list = pcall(getconnections, sig)
                if ok and list then
                    for _, c in ipairs(list) do
                        pcall(function() c:Fire() end)
                        fired = true
                    end
                end
                if fired then break end
            end
        end
        if not fired and firesignal then
            fired = pcall(firesignal, btn.MouseButton1Click)
        end
        return fired
    end

    local skipState = { pressed = false, lastWave = nil, lastFire = 0, fires = 0, blind = 0 }
    runLoop(function()
        if not flags.autoSkip then
            fSkip.setNote("")
            skipState.pressed, skipState.lastWave = false, nil
            skipState.fires, skipState.blind = 0, 0
            return 0.5
        end
        local ev = RE("SkipWaveVote")
        if not ev then
            fSkip.setNote("Only works in a match", C.muted)
            return 1.5
        end

        local btn = findSkipButton()
        if btn then
            if skipState.pressed then
                fSkip.setNote("Skip vote sent", C.text)
                return 1
            end
            if pressButton(btn) then
                skipState.pressed = true
                fSkip.setNote("Skip vote sent", C.text)
                return 1
            end
        else
            skipState.pressed = false
        end

        local now = os.clock()
        local w = waveNow.cur
        if w then
            if w ~= skipState.lastWave then
                skipState.lastWave = w
                skipState.fires = 0
                skipState.lastFire = 0
            end
            if skipState.fires >= 2 or now - skipState.lastFire < 5 then
                fSkip.setNote("Voted to skip wave " .. w, C.text)
                return 1
            end
            skipState.fires = skipState.fires + 1
            skipState.lastFire = now
            task.wait(1.2) -- beri waktu tombol skip muncul
            for _, n in ipairs({ w + SKIP_WAVE_OFFSET, w + SKIP_WAVE_OFFSET + 1 }) do
                if n >= 1 then
                    pcall(function() ev:FireServer(n) end)
                    task.wait(0.15)
                end
            end
            fSkip.setNote("Voted to skip wave " .. w, C.text)
            return 1
        end

        if now - skipState.lastFire >= 6 then
            skipState.lastFire = now
            skipState.blind = skipState.blind + 1
            pcall(function() ev:FireServer(skipState.blind) end)
        end
        fSkip.setNote("Can't read the wave, guessing", C.warn)
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
    local fPotion = visualFeature(tabs["Inventory"].page, "Auto Use Potion", "autoPotion", 28, function(body)
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
-- Inventory: Fish Inventory (dropdown) + Sell
-- =================================================================
do
    local page = tabs["Inventory"].page

    -- Fish Inventory: dropdown minimalis, jumlah per JENIS (bukan kg) supaya ringan.
    -- Klik jenis ikan -> isi jumlah -> Sell. Data dari Players.<kamu>.FishingData.Fish
    local fishOpen, selectedFish, selling = false, nil, false
    local fishList, fishSig = {}, nil

    local fishCard = createCard(page, 34)
    fishCard.ClipsDescendants = true
    local fishHead = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, fishCard)
    make("TextLabel", {
        Size = UDim2.new(0, 110, 0, 34),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "Fish Inventory",
        TextColor3 = C.text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, fishHead)
    local fishTotal = make("TextLabel", {
        Size = UDim2.new(1, -158, 0, 34),
        Position = UDim2.new(0, 124, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.muted,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, fishHead)
    local fishArrow = createChevron(fishHead, -14)

    local fishRows = make("Frame", {
        Size = UDim2.new(1, -24, 0, 24),
        Position = UDim2.new(0, 12, 0, 34),
        BackgroundTransparency = 1,
        Visible = false,
    }, fishCard)

    -- Panel jual: nama ikan terpilih, jumlah, Sell, All
    local sellPanel = make("Frame", {
        Size = UDim2.new(1, -24, 0, 30),
        BackgroundTransparency = 1,
        Visible = false,
    }, fishCard)
    local sellName = make("TextLabel", {
        Size = UDim2.new(1, -176, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.white,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, sellPanel)
    local qtyBox = createInput(sellPanel, {
        Size = UDim2.new(0, 60, 0, 26),
        Position = UDim2.new(1, -168, 0, 2),
        TextXAlignment = Enum.TextXAlignment.Center,
        Font = Enum.Font.RobotoMono,
    }, "qty")

    -- Cari bobot ikan kalau game menyimpannya (attribute / child / folder FishingData)
    local function fishWeight(v, fd)
        for k, val in pairs(v:GetAttributes()) do
            if type(val) == "number" and string.find(string.lower(k), "weight", 1, true) then return val end
        end
        for _, c in ipairs(v:GetChildren()) do
            if c:IsA("ValueBase") and string.find(string.lower(c.Name), "weight", 1, true)
                and type(c.Value) == "number" then
                return c.Value
            end
        end
        if fd then
            for _, c in ipairs(fd:GetChildren()) do
                if string.find(string.lower(c.Name), "weight", 1, true) then
                    local w = c:FindFirstChild(v.Name)
                    if w and w:IsA("ValueBase") and type(w.Value) == "number" then return w.Value end
                    local a = c:GetAttribute(v.Name)
                    if type(a) == "number" then return a end
                end
            end
        end
        return nil
    end

    local function sellFish(wantAll)
        if selling or not selectedFish then return end
        local name = selectedFish
        local fd = LocalPlayer:FindFirstChild("FishingData")
        local folder = fd and fd:FindFirstChild("Fish")
        local v = folder and folder:FindFirstChild(name)
        if not v or v.Value <= 0 then
            notify("Sell Fish", "No " .. name .. " left.", 2)
            return
        end
        local fn = fishRemote("FishingFunction")
        if not fn then
            notify("Sell Fish", "Fishing remote not found.", 3)
            return
        end
        local amount = wantAll and v.Value or math.floor(tonumber(qtyBox.Text) or 1)
        amount = math.clamp(amount, 1, v.Value)
        selling = true
        task.spawn(function()
            local args = { Fish = name, Amount = amount }
            local w = fishWeight(v, fd)
            if w then args.Weight = w end
            local ok, res = pcall(function() return fn:InvokeServer("SellFish", args) end)
            if accepted(ok, res) then
                notify("Fish Sold", "Sold " .. amount .. "x " .. name, 2)
            else
                notify("Sell failed", "Server refused the sale of " .. name .. ". Use 'Log fish data' in Fishing and send the output.", 4)
            end
            selling = false
        end)
    end

    createButton(sellPanel, {
        Size = UDim2.new(0, 48, 0, 26),
        Position = UDim2.new(1, -104, 0, 2),
    }, "Sell", function() sellFish(false) end)
    createButton(sellPanel, {
        Size = UDim2.new(0, 48, 0, 26),
        Position = UDim2.new(1, -52, 0, 2),
    }, "All", function() sellFish(true) end)

    local function layoutFish()
        fishArrow.Rotation = fishOpen and 180 or 0
        fishRows.Visible = fishOpen
        sellPanel.Visible = fishOpen and selectedFish ~= nil
        if not fishOpen then
            fishCard.Size = UDim2.new(1, 0, 0, 34)
            return
        end
        local rowsH = math.max(1, #fishList) * 24
        fishRows.Size = UDim2.new(1, -24, 0, rowsH)
        sellPanel.Position = UDim2.new(0, 12, 0, 34 + rowsH + 6)
        fishCard.Size = UDim2.new(1, 0, 0, 34 + rowsH + (selectedFish and 38 or 4) + 6)
    end

    local function rebuildFish()
        for _, c in ipairs(fishRows:GetChildren()) do c:Destroy() end
        if #fishList == 0 then
            make("TextLabel", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                Text = "No fish yet",
                TextColor3 = C.dim,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, fishRows)
        end
        for i, f in ipairs(fishList) do
            if i > 60 then break end
            local sel = (f.n == selectedFish)
            local row = make("TextButton", {
                Size = UDim2.new(1, 0, 0, 22),
                Position = UDim2.new(0, 0, 0, (i - 1) * 24),
                BackgroundColor3 = sel and C.hover or C.control,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
            }, fishRows)
            styleControl(row)
            make("TextLabel", {
                Size = UDim2.new(0.7, -8, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text = f.n,
                TextColor3 = sel and C.white or C.text,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, row)
            make("TextLabel", {
                Size = UDim2.new(0.3, -8, 1, 0),
                Position = UDim2.new(0.7, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = tostring(f.c),
                TextColor3 = C.muted,
                TextSize = 11,
                Font = Enum.Font.RobotoMono,
                TextXAlignment = Enum.TextXAlignment.Right,
            }, row)
            row.MouseButton1Click:Connect(function()
                selectedFish = f.n
                sellName.Text = f.n
                qtyBox.PlaceholderText = "1-" .. f.c
                rebuildFish()
                layoutFish()
            end)
        end
    end

    fishHead.MouseButton1Click:Connect(function()
        fishOpen = not fishOpen
        layoutFish()
    end)

    runLoop(function()
        local fd = LocalPlayer:FindFirstChild("FishingData")
        local folder = fd and fd:FindFirstChild("Fish")
        local list, total = {}, 0
        if folder then
            for _, v in ipairs(folder:GetChildren()) do
                if (v:IsA("IntValue") or v:IsA("NumberValue")) and v.Value > 0 then
                    list[#list + 1] = { n = v.Name, c = v.Value }
                    total = total + v.Value
                end
            end
        end
        table.sort(list, function(a, b)
            if a.c ~= b.c then return a.c > b.c end
            return a.n < b.n
        end)

        local parts = {}
        for _, f in ipairs(list) do parts[#parts + 1] = f.n .. "=" .. f.c end
        local sig = table.concat(parts, "|")
        if sig == fishSig then return 2 end
        fishSig = sig

        fishList = list
        fishTotal.Text = folder and (#list .. " types  |  " .. total .. " total") or "No fishing data"
        if selectedFish then
            local still = false
            for _, f in ipairs(list) do
                if f.n == selectedFish then still = true; qtyBox.PlaceholderText = "1-" .. f.c end
            end
            if not still then selectedFish = nil end
        end
        rebuildFish()
        layoutFish()
        return 2
    end)
end

-- =================================================================
-- Fishing: Auto Fishing + Craft Fishing Island
--   Urutan dari log: Cast{Position} -> LuckHold/LuckRelease{ClickTime}
--   -> Hit{Index 1..10, ClickTime} (sekitar 1 detik per Hit)
-- =================================================================
do
    local page = tabs["Fishing"].page
    local GuiService = game:GetService("GuiService")
    local FISH_FILE = "LightHub_Fish.json"

    -- Jeda antar langkah (detik). Ubah di sini kalau game menolak / terlalu lambat.
    local TIMING = {
        castToLuck = 3,    -- setelah Cast sampai LuckHold
        luckHold = 0.09,   -- jarak LuckHold -> LuckRelease
        luckToHit = 3,     -- setelah LuckRelease sampai Hit pertama
        hitGap = 0.9,      -- jarak antar Hit
        hits = 10,         -- jumlah Hit per tangkapan
        endWait = 1.5,     -- jeda sebelum Cast berikutnya
    }

    -- ---------------- Spot lemparan (disimpan di file kalau executor mendukung) ----------------
    local spot = nil
    if canFile then
        pcall(function()
            if isfile(FISH_FILE) then
                local d = HttpService:JSONDecode(readfile(FISH_FILE))
                if type(d) == "table" and type(d.x) == "number" and type(d.y) == "number" and type(d.z) == "number" then
                    spot = Vector3.new(d.x, d.y, d.z)
                end
            end
        end)
    end
    local function saveSpot()
        if canFile and spot then
            pcall(function()
                writefile(FISH_FILE, HttpService:JSONEncode({ x = spot.X, y = spot.Y, z = spot.Z }))
            end)
        end
    end

    -- ---------------- Auto Fishing ----------------
    local fishing = false
    local feat
    feat = createFeature(page, "Auto Fishing", {
        bodyHeight = 62,
        onToggle = function(v)
            fishing = v
            if not v then feat.setNote("", C.muted) end
        end,
    })

    local spotLabel = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.muted,
        TextSize = 10,
        Font = Enum.Font.RobotoMono,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, feat.body)
    local function setSpotText()
        spotLabel.Text = spot
            and string.format("Spot  %.1f, %.1f, %.1f", spot.X, spot.Y, spot.Z)
            or "Spot  not set"
    end
    setSpotText()

    local picking = false
    createButton(feat.body, {
        Size = UDim2.new(0, 96, 0, 28),
        Position = UDim2.new(0, 0, 0, 2),
    }, "Set spot", function()
        picking = true
        notify("Set spot", "Tap the water where the line should land.", 5)
    end)
    createButton(feat.body, {
        Size = UDim2.new(0, 110, 0, 28),
        Position = UDim2.new(0, 102, 0, 2),
    }, "My position", function()
        local ch = LocalPlayer.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if hrp then
            spot = hrp.Position
            saveSpot()
            setSpotText()
        end
    end)

    table.insert(conns, UserInputService.InputBegan:Connect(function(input, processed)
        if not picking or processed then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
        picking = false
        local cam = workspace.CurrentCamera
        if not cam then return end
        local pos2
        if t == Enum.UserInputType.Touch then
            local inset = GuiService:GetGuiInset()
            pos2 = Vector2.new(input.Position.X, input.Position.Y) + inset
        else
            pos2 = UserInputService:GetMouseLocation()
        end
        local ray = cam:ViewportPointToRay(pos2.X, pos2.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { LocalPlayer.Character }
        params.IgnoreWater = false
        local hit = workspace:Raycast(ray.Origin, ray.Direction * 1500, params)
        if hit then
            spot = hit.Position
            saveSpot()
            setSpotText()
            notify("Set spot", "Spot saved.", 2)
        else
            notify("Set spot", "Couldn't read that spot. Try again.", 3)
        end
    end))

    local function alive() return fishing and ScreenGui.Parent ~= nil end
    local function nap(t)
        local untilT = os.clock() + t
        while os.clock() < untilT do
            if not alive() then return false end
            task.wait(0.1)
        end
        return alive()
    end

    local function cycle(ev)
        feat.setNote("Casting", C.text)
        ev:FireServer("Cast", { Position = spot })
        if not nap(TIMING.castToLuck) then return end
        feat.setNote("Luck", C.text)
        ev:FireServer("LuckHold", { ClickTime = workspace:GetServerTimeNow() })
        if not nap(TIMING.luckHold) then return end
        ev:FireServer("LuckRelease", { ClickTime = workspace:GetServerTimeNow() })
        if not nap(TIMING.luckToHit) then return end
        for i = 1, TIMING.hits do
            feat.setNote("Reeling " .. i .. "/" .. TIMING.hits, C.text)
            ev:FireServer("Hit", { Index = i, ClickTime = workspace:GetServerTimeNow() })
            if not nap(TIMING.hitGap) then return end
        end
        feat.setNote("Caught", C.text)
        nap(TIMING.endWait)
    end

    task.spawn(function()
        while ScreenGui.Parent do
            if fishing then
                local ev = fishRemote("FishingEvent")
                if not spot then
                    feat.setNote("Set a spot first", C.warn)
                    task.wait(1)
                elseif not ev then
                    feat.setNote("Fishing remote not found", C.warn)
                    task.wait(2)
                else
                    local ok, err = pcall(cycle, ev)
                    if not ok then
                        warn("[Light] fishing: " .. tostring(err))
                        task.wait(1)
                    end
                end
            else
                task.wait(0.5)
            end
        end
    end)

    -- ---------------- Craft Fishing Island ----------------
    local RECIPES = {
        { id = 1, name = "Poseidon Cameraman" },
        { id = 2, name = "Fish Crate" },
    }

    -- Coba baca bahan resep dari ModuleScript resep milik game (kalau ada)
    local function recipeText(id)
        local root = ReplicatedStorage:FindFirstChild("Fishing")
        if not root then return nil end
        for _, m in ipairs(root:GetDescendants()) do
            if m:IsA("ModuleScript") and string.find(string.lower(m.Name), "recipe", 1, true) then
                local ok, data = pcall(require, m)
                if ok and type(data) == "table" then
                    local rec = data[id]
                    if rec == nil and type(data.Recipes) == "table" then rec = data.Recipes[id] end
                    if type(rec) == "table" then
                        local parts = {}
                        local function walk(t, depth)
                            for k, v in pairs(t) do
                                if #parts >= 6 then return end
                                if type(v) == "number" and type(k) == "string" then
                                    parts[#parts + 1] = k .. " x" .. v
                                elseif type(v) == "table" and depth < 2 then
                                    walk(v, depth + 1)
                                end
                            end
                        end
                        walk(rec, 0)
                        if #parts > 0 then return table.concat(parts, ", ") end
                    end
                end
            end
        end
        return nil
    end

    local craftCard = createCard(page, 34 + #RECIPES * 46 + 8)
    make("TextLabel", {
        Size = UDim2.new(1, -24, 0, 34),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "Craft Fishing Island",
        TextColor3 = C.text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, craftCard)

    local crafting = false
    for i, r in ipairs(RECIPES) do
        local y = 34 + (i - 1) * 46
        make("TextLabel", {
            Size = UDim2.new(1, -160, 0, 18),
            Position = UDim2.new(0, 12, 0, y + 4),
            BackgroundTransparency = 1,
            Text = r.name,
            TextColor3 = C.white,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, craftCard)
        local need = make("TextLabel", {
            Size = UDim2.new(1, -160, 0, 14),
            Position = UDim2.new(0, 12, 0, y + 23),
            BackgroundTransparency = 1,
            Text = "Recipe " .. r.id,
            TextColor3 = C.muted,
            TextSize = 10,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, craftCard)
        task.spawn(function()
            local t = recipeText(r.id)
            if t then need.Text = t end
        end)

        local qty = createInput(craftCard, {
            Size = UDim2.new(0, 48, 0, 28),
            Position = UDim2.new(1, -136, 0, y + 8),
            Text = "1",
            TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.RobotoMono,
        }, "1")
        createButton(craftCard, {
            Size = UDim2.new(0, 70, 0, 28),
            Position = UDim2.new(1, -82, 0, y + 8),
        }, "Craft", function()
            if crafting then return end
            local fn = fishRemote("FishingFunction")
            if not fn then
                notify("Craft", "Fishing remote not found.", 3)
                return
            end
            local n = math.clamp(math.floor(tonumber(qty.Text) or 1), 1, 99)
            crafting = true
            task.spawn(function()
                local done = 0
                for _ = 1, n do
                    if not ScreenGui.Parent then break end
                    local ok, res = pcall(function()
                        return fn:InvokeServer("Craft", { Recipe = r.id })
                    end)
                    if not accepted(ok, res) then break end
                    done = done + 1
                    if done < n then task.wait(0.3) end
                end
                if done == n then
                    notify("Crafted", n .. "x " .. r.name, 2)
                elseif done > 0 then
                    notify("Craft stopped", done .. "/" .. n .. " " .. r.name .. " (missing materials?)", 3)
                else
                    notify("Craft failed", r.name .. ": missing materials or refused.", 3)
                end
                crafting = false
            end)
        end)
    end

    -- ---------------- Log data (untuk debug / melengkapi resep dan jual ikan) ----------------
    local function dump(inst, depth, out)
        if #out > 120 then return end
        local line = string.rep("  ", depth) .. inst.Name .. " [" .. inst.ClassName .. "]"
        if inst:IsA("ValueBase") then line = line .. " = " .. tostring(inst.Value) end
        for k, v in pairs(inst:GetAttributes()) do line = line .. " @" .. k .. "=" .. tostring(v) end
        out[#out + 1] = line
        if depth < 3 then
            for _, c in ipairs(inst:GetChildren()) do dump(c, depth + 1, out) end
        end
    end
    local function dumpTable(t, depth, out)
        if #out > 120 or depth > 3 then return end
        for k, v in pairs(t) do
            out[#out + 1] = string.rep("  ", depth) .. tostring(k) .. " = " .. (type(v) == "table" and "{...}" or tostring(v))
            if type(v) == "table" then dumpTable(v, depth + 1, out) end
        end
    end

    createButton(page, { Size = UDim2.new(1, 0, 0, 28) }, "Log fish data (console)", function()
        local out = {}
        local fd = LocalPlayer:FindFirstChild("FishingData")
        if fd then dump(fd, 0, out) else out[#out + 1] = "FishingData not found" end
        local root = ReplicatedStorage:FindFirstChild("Fishing")
        if root then
            for _, m in ipairs(root:GetDescendants()) do
                if m:IsA("ModuleScript") and string.find(string.lower(m.Name), "recipe", 1, true) then
                    out[#out + 1] = "-- module " .. m:GetFullName()
                    local ok, data = pcall(require, m)
                    if ok and type(data) == "table" then dumpTable(data, 1, out) end
                end
            end
        end
        print("[Light] fish data\n" .. table.concat(out, "\n"))
        notify("Log fish data", "Printed to the console (F9).", 3)
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
-- Endless: Teleport UTTM + Unit Mover
-- Lokasi dipilih manual: tekan Select / Add, lalu double-tap di tanah.
--   UTTM: CinemaRelocate("Start", tower, nil) lalu ("Place", tower, CFrame)
--   Unit Mover: jual unit lalu pasang lagi di lokasi lain (label ikut pindah)
-- =================================================================
local SPOTS_FILE = "LightHub_Spots.json"
local UTTM_NAME = "Upgraded Titan Cinema Man"

do
    local page = tabs["Endless"].page
    local mouse = LocalPlayer:GetMouse()

    -- ---------------- Penyimpanan ----------------
    local spots = { uttm = {}, movers = {} }

    local function readLocs(src)
        local out = {}
        if type(src) ~= "table" then return out end
        for _, s in ipairs(src) do
            if type(s) == "table" and type(s.n) == "string" and type(s.x) == "number"
                and type(s.y) == "number" and type(s.z) == "number" then
                out[#out + 1] = { n = s.n, x = s.x, y = s.y, z = s.z }
            end
        end
        return out
    end

    if canFile and isfile(SPOTS_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(SPOTS_FILE)) end)
        if ok and type(data) == "table" then
            spots.uttm = readLocs(data.uttm)
            if type(data.movers) == "table" then
                for _, m in ipairs(data.movers) do
                    if type(m) == "table" and type(m.unit) == "string" and type(m.id) == "number" then
                        spots.movers[#spots.movers + 1] = { id = m.id, unit = m.unit, locs = readLocs(m.locs) }
                    end
                end
            end
        end
    end

    local function saveSpots()
        if canFile then pcall(writefile, SPOTS_FILE, HttpService:JSONEncode(spots)) end
    end

    -- ---------------- Pilih lokasi: double-tap di tanah ----------------
    local pick = nil

    local function startPick(cb)
        local token = os.clock()
        pick = { cb = cb, token = token, lastT = 0, lastPos = nil }
        pcall(function() mouse.TargetFilter = workspace:FindFirstChild("Towers") end)
        notify("Select location", "Double-tap the ground where you want it (30s).", 6)
        task.delay(30, function()
            if pick and pick.token == token then
                pick = nil
                notify("Select location", "Selection timed out.", 3)
            end
        end)
    end

    table.insert(conns, UserInputService.InputBegan:Connect(function(input, processed)
        if not pick or processed then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
        local now = os.clock()
        local here = Vector2.new(input.Position.X, input.Position.Y)
        if pick.lastPos and (now - pick.lastT) < 0.5 and (here - pick.lastPos).Magnitude < 60 then
            local cb = pick.cb
            pick = nil
            task.delay(0.05, function()
                local hit = mouse.Hit
                if hit then
                    cb(hit.Position)
                else
                    notify("Select location", "Couldn't read that spot. Try again.", 3)
                end
            end)
            return
        end
        pick.lastT, pick.lastPos = now, here
    end))

    -- ---------------- Tower ----------------
    local function findTowerNear(name, x, z, r)
        local folder = workspace:FindFirstChild("Towers")
        if not folder then return nil end
        for _, t in ipairs(folder:GetChildren()) do
            if t.Name == name and t:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
                local ok, p = pcall(function() return t:GetPivot().Position end)
                if ok and math.sqrt((p.X - x) ^ 2 + (p.Z - z) ^ 2) <= r then return t end
            end
        end
        return nil
    end

    local function pushMacro(act)
        local ms = env.LightHubMacroState
        if ms and ms.rec and ms.push then
            act.w = waveNow.cur or 0
            ms.push(act)
        end
    end

    local function nextLocName(list)
        local n = 1
        while true do
            local used = false
            for _, s in ipairs(list) do
                if s.n == "Loc " .. n then used = true end
            end
            if not used then return "Loc " .. n end
            n = n + 1
        end
    end

    -- Baris lokasi: Loc N | Teleport | Select | Delete
    local function addLocRow(rows, list, s, y, onTeleport, onChanged, rebuild)
        make("TextLabel", {
            Size = UDim2.new(0, 66, 0, 28),
            Position = UDim2.new(0, 0, 0, y),
            BackgroundTransparency = 1,
            Text = s.n,
            TextColor3 = C.text,
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, rows)

        createButton(rows, {
            Size = UDim2.new(0, 92, 0, 28),
            Position = UDim2.new(0, 70, 0, y),
        }, "Teleport", function() onTeleport(s) end)

        createButton(rows, {
            Size = UDim2.new(0, 92, 0, 28),
            Position = UDim2.new(0, 166, 0, y),
        }, "Select", function()
            startPick(function(pos)
                s.x, s.y, s.z = pos.X, pos.Y, pos.Z
                saveSpots()
                onChanged(s.n .. " updated")
            end)
        end)

        local armed = false
        local del
        del = createButton(rows, {
            Size = UDim2.new(0, 56, 0, 28),
            Position = UDim2.new(0, 262, 0, y),
        }, "Delete", function()
            if not armed then
                armed = true
                del.Text = "Sure?"
                task.delay(3, function()
                    armed = false
                    if del.Parent then del.Text = "Delete" end
                end)
                return
            end
            for j, v in ipairs(list) do
                if v == s then
                    table.remove(list, j)
                    break
                end
            end
            saveSpots()
            rebuild()
        end)
    end

    -- ---------------- Teleport UTTM (muncul otomatis kalau unitnya ada) ----------------
    local uttmCard = createCard(page, 80)
    local uttmTitle = make("TextLabel", {
        Size = UDim2.new(0, 150, 0, 34),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "Teleport",
        TextColor3 = C.white,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, uttmCard)
    -- Hanya kata "UTTM" yang berwarna: biru dan ungu yang saling menyatu dan
    -- bergeser pelan di seluruh teks (bukan pita warna yang lewat satu-satu).
    local TextService = game:GetService("TextService")
    local prefixW = TextService:GetTextSize("Teleport ", 12, Enum.Font.GothamBold, Vector2.new(400, 40)).X
    local uttmWord = make("TextLabel", {
        Size = UDim2.new(0, 60, 0, 34),
        Position = UDim2.new(0, 12 + prefixW, 0, 0),
        BackgroundTransparency = 1,
        Text = "UTTM",
        TextColor3 = C.white,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, uttmCard)
    local UTTM_BLUE = Color3.fromRGB(70, 150, 240)
    local UTTM_VIOLET = Color3.fromRGB(150, 110, 235)
    local uttmGrad = make("UIGradient", {
        Color = ColorSequence.new(UTTM_BLUE, UTTM_VIOLET),
        Rotation = 0,
    }, uttmWord)
    runLoop(function()
        if uttmCard.Visible then
            local k = (math.sin(os.clock() * 0.9) + 1) / 2
            local a = UTTM_BLUE:Lerp(UTTM_VIOLET, k)
            local b = UTTM_BLUE:Lerp(UTTM_VIOLET, 1 - k)
            uttmGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, a),
                ColorSequenceKeypoint.new(0.5, a:Lerp(b, 0.5)),
                ColorSequenceKeypoint.new(1, b),
            })
        end
        return 0.05
    end)

    local uttmNote = make("TextLabel", {
        Size = UDim2.new(0, 190, 0, 34),
        Position = UDim2.new(1, -202, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.muted,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, uttmCard)
    local function uttmSay(t, color)
        uttmNote.Text = t or ""
        uttmNote.TextColor3 = color or C.muted
    end

    local uttmRows = make("Frame", {
        Size = UDim2.new(1, -24, 0, 28),
        Position = UDim2.new(0, 12, 0, 34),
        BackgroundTransparency = 1,
    }, uttmCard)

    local lastUttmUse = nil
    local uttmBusy = false

    local function findUttm()
        local folder = workspace:FindFirstChild("Towers")
        if not folder then return nil end
        for _, t in ipairs(folder:GetChildren()) do
            if t.Name == UTTM_NAME and t:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
                return t
            end
        end
        return nil
    end

    -- ---------------- Mode drone ----------------
    -- Status drone dibaca dari attribute UTTM (nama mengandung "drone") kalau ada.
    -- Kalau tidak ada, status dilacak dari panggilan CinemaRelocate("Drones") yang
    -- lewat (klik manual pemain maupun dari script ini). Status awal tidak
    -- diketahui sampai drone di-toggle sekali, dan dianggap OFF.
    local droneState = env.LightHubDrone
    if not droneState then
        droneState = { on = nil }
        env.LightHubDrone = droneState
    end
    droneState.active = true

    if hookmetamethod and getnamecallmethod and not env.LightHubDroneHooked then
        pcall(function()
            local old
            old = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if method == "InvokeServer" and droneState.active
                    and typeof(self) == "Instance" and self.Name == "CinemaRelocate" then
                    local args = table.pack(...)
                    if args[1] == "Drones" then
                        local res = table.pack(old(self, ...))
                        if accepted(true, res[1]) then
                            droneState.on = not droneState.on
                        end
                        return table.unpack(res, 1, res.n)
                    end
                end
                return old(self, ...)
            end)
            env.LightHubDroneHooked = true
        end)
    end

    local function isDroneOn(tw)
        for name, v in pairs(tw:GetAttributes()) do
            if type(v) == "boolean" and string.find(string.lower(name), "drone", 1, true) then
                return v
            end
        end
        return droneState.on == true
    end

    -- Tanpa hook, status dibalik manual setelah panggilan dari script ini
    local function toggleDrone(tw)
        local ok, res = invoke("CinemaRelocate", "Drones", tw, nil)
        if accepted(ok, res) and not env.LightHubDroneHooked then
            droneState.on = not droneState.on
        end
        return accepted(ok, res)
    end

    local function uttmTeleport(s)
        if uttmBusy then return end
        uttmBusy = true
        task.spawn(function()
            uttmSay("Working...", C.muted)
            local tw = findUttm()
            if not tw then
                uttmSay("UTTM not found", C.warn)
            else
                -- Drone aktif: matikan dulu supaya bisa teleport, nyalakan lagi sesudahnya
                local wasDrone = isDroneOn(tw)
                if wasDrone then
                    uttmSay("Drone off...", C.muted)
                    toggleDrone(tw)
                    task.wait(0.35)
                end

                local placed = false
                local ok, res = invoke("CinemaRelocate", "Start", tw, nil)
                if not accepted(ok, res) then
                    local ago = lastUttmUse and (" (used " .. math.floor(os.clock() - lastUttmUse) .. "s ago)") or ""
                    uttmSay("On cooldown" .. ago, C.warn)
                else
                    local ok2, res2 = invoke("CinemaRelocate", "Place", tw, CFrame.new(s.x, s.y, s.z))
                    if accepted(ok2, res2) then
                        placed = true
                        lastUttmUse = os.clock()
                        uttmSay("Teleported to " .. s.n, C.text)
                    else
                        uttmSay("Couldn't place it there", C.warn)
                    end
                end

                if wasDrone then
                    task.wait(0.35)
                    toggleDrone(tw)
                    if placed then uttmSay("Teleported, drone back on", C.text) end
                end
            end
            uttmBusy = false
        end)
    end

    -- ---------------- Spin (dipanggil langsung, tanpa lewat UI game) ----------------
    local autoSpin = false
    local function uttmSpin(silent)
        local tw = findUttm()
        if not tw then
            if not silent then uttmSay("UTTM not found", C.warn) end
            return false
        end
        local ok, res = invoke("CinemaRelocate", "Spin", tw, nil)
        local good = accepted(ok, res)
        if not silent then
            uttmSay(good and "Spin used" or "Spin on cooldown", good and C.text or C.warn)
        end
        return good
    end

    runLoop(function()
        if autoSpin and not uttmBusy and findUttm() then
            uttmSpin(true)
        end
        return 1
    end)

    local uttmRebuild
    uttmRebuild = function()
        for _, c in ipairs(uttmRows:GetChildren()) do c:Destroy() end
        local autoBtn
        createButton(uttmRows, {
            Size = UDim2.new(0.5, -3, 0, 28),
            Position = UDim2.new(0, 0, 0, 0),
        }, "Spin", function() task.spawn(uttmSpin, false) end)
        autoBtn = createButton(uttmRows, {
            Size = UDim2.new(0.5, -3, 0, 28),
            Position = UDim2.new(0.5, 3, 0, 0),
        }, autoSpin and "Auto Spin: ON" or "Auto Spin: OFF", function()
            autoSpin = not autoSpin
            autoBtn.Text = autoSpin and "Auto Spin: ON" or "Auto Spin: OFF"
            uttmSay(autoSpin and "Auto spin on" or "Auto spin off", C.text)
        end)
        for i, s in ipairs(spots.uttm) do
            addLocRow(uttmRows, spots.uttm, s, 32 + (i - 1) * 32, uttmTeleport,
                function(msg) uttmSay(msg, C.text) end, uttmRebuild)
        end
        local y = 32 + #spots.uttm * 32
        createButton(uttmRows, {
            Size = UDim2.new(1, 0, 0, 28),
            Position = UDim2.new(0, 0, 0, y),
        }, "+ Add location", function()
            startPick(function(pos)
                table.insert(spots.uttm, { n = nextLocName(spots.uttm), x = pos.X, y = pos.Y, z = pos.Z })
                saveSpots()
                uttmRebuild()
                uttmSay("Location added", C.text)
            end)
        end)
        uttmRows.Size = UDim2.new(1, -24, 0, y + 28)
        uttmCard.Size = UDim2.new(1, 0, 0, 34 + y + 28 + 10)
    end
    uttmRebuild()
    uttmCard.Visible = false

    runLoop(function()
        local found = findUttm() ~= nil
        if uttmCard.Visible ~= found then uttmCard.Visible = found end
        return 1
    end)

    -- ---------------- Unit Mover ----------------
    -- Pilih unit di dropdown -> muncul kartu "Mover N - nama unit" dengan unit
    -- yang sudah terkunci. Tiap mover punya daftar lokasinya sendiri dan
    -- beberapa mover bisa dipindahkan bersamaan.
    local unitLabels = setmetatable({}, { __mode = "k" })
    local labelCount = {}

    local function scanUnits()
        local out = {}
        local folder = workspace:FindFirstChild("Towers")
        if not folder then return out end
        for _, t in ipairs(folder:GetChildren()) do
            if t:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
                local label = unitLabels[t]
                if not label then
                    labelCount[t.Name] = (labelCount[t.Name] or 0) + 1
                    label = t.Name .. " " .. labelCount[t.Name]
                    unitLabels[t] = label
                end
                out[#out + 1] = { tower = t, name = t.Name, label = label }
            end
        end
        table.sort(out, function(a, b) return a.label < b.label end)
        return out
    end

    local function unitOptions()
        local t = {}
        for _, u in ipairs(scanUnits()) do t[#t + 1] = { label = u.label, value = u.label } end
        return t
    end

    -- Jual unit, pasang lagi di lokasi baru, lalu upgrade lagi ke level semula
    local function moveUnit(label, s)
        local unit
        for _, u in ipairs(scanUnits()) do
            if u.label == label then
                unit = u
                break
            end
        end
        if not unit then return false, "Unit not found: " .. tostring(label) end

        local tw, name = unit.tower, unit.name
        local okp, p0 = pcall(function() return tw:GetPivot().Position end)
        if not okp then return false, "Unit not found" end
        local lvl = tw:GetAttribute("Level")

        invoke("SellTower", tw)
        for _ = 1, 8 do
            if not tw.Parent then break end
            task.wait(0.25)
        end
        if tw.Parent then return false, "Couldn't sell it" end
        pushMacro({ t = "sell", n = name, p = { p0.X, p0.Y, p0.Z } })

        local cf = CFrame.new(s.x, s.y, s.z)
        local placed
        for _ = 1, 20 do -- menunggu cash cukup, maksimal sekitar 20 detik
            invoke("PlaceTower", name, cf)
            task.wait(0.6)
            placed = findTowerNear(name, s.x, s.z, 4)
            if placed then break end
            task.wait(0.4)
        end
        if not placed then return false, "Sold it, but couldn't place (cash?)" end
        unitLabels[placed] = label
        pushMacro({ t = "place", n = name, cf = { cf:GetComponents() } })

        if type(lvl) == "number" then
            local t0 = os.clock()
            while os.clock() - t0 < 25 do
                local cur = placed:GetAttribute("Level")
                local price = placed:GetAttribute("UpgradePrice")
                if type(cur) ~= "number" or cur >= lvl or type(price) ~= "number" or price <= 0 then break end
                local ok, res = invoke("UpgradeTower", placed)
                if ok and res == true then
                    pushMacro({ t = "up", n = name, p = { s.x, s.y, s.z } })
                end
                task.wait(0.4)
            end
        end
        return true, "moved to " .. s.n
    end

    -- Kartu header: judul + dropdown "tambah mover"
    local moverHead = createCard(page, 72)
    make("TextLabel", {
        Size = UDim2.new(0, 150, 0, 34),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "Unit Mover",
        TextColor3 = C.text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, moverHead)
    local moverNoteLbl = make("TextLabel", {
        Size = UDim2.new(0, 190, 0, 34),
        Position = UDim2.new(1, -202, 0, 0),
        BackgroundTransparency = 1,
        Text = "Pick a unit to lock it to a mover",
        TextColor3 = C.dim,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, moverHead)
    local function moverSay(t, color)
        moverNoteLbl.Text = t or ""
        moverNoteLbl.TextColor3 = color or C.muted
    end

    local buildMover

    local function nextMoverId()
        local n = 0
        for _, m in ipairs(spots.movers) do
            if m.id > n then n = m.id end
        end
        return n + 1
    end

    local unitSel
    unitSel = createSelect(moverHead, {
        Size = UDim2.new(1, -24, 0, 28),
        Position = UDim2.new(0, 12, 0, 34),
    }, {
        placeholder = "Add mover: select a unit",
        getOptions = unitOptions,
        emptyMsg = "No units placed yet.",
        onChange = function(v)
            unitSel.set(nil)
            for _, m in ipairs(spots.movers) do
                if m.unit == v then
                    moverSay("That unit already has a mover", C.warn)
                    return
                end
            end
            local data = { id = nextMoverId(), unit = v, locs = {} }
            table.insert(spots.movers, data)
            saveSpots()
            buildMover(data, true)
            moverSay("Mover " .. data.id .. " added", C.text)
        end,
    })

    -- Kartu per mover: header ringkas yang bisa dibuka/tutup
    buildMover = function(data, openNow)
        local card = createCard(page, 34)
        local expanded = openNow and true or false
        local busy = false

        local head = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
        }, card)
        make("TextLabel", {
            Size = UDim2.new(1, -44, 0, 34),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = "Mover " .. data.id .. " - " .. data.unit,
            TextColor3 = C.text,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, head)
        local chev = createChevron(head, -12)
        chev.Position = UDim2.new(1, -12, 0, 17)

        local rows = make("Frame", {
            Size = UDim2.new(1, -24, 0, 28),
            Position = UDim2.new(0, 12, 0, 34),
            BackgroundTransparency = 1,
        }, card)

        local rebuild
        rebuild = function()
            for _, c in ipairs(rows:GetChildren()) do c:Destroy() end
            if not expanded then
                rows.Visible = false
                chev.Rotation = 0
                card.Size = UDim2.new(1, 0, 0, 34)
                return
            end
            rows.Visible = true
            chev.Rotation = 180

            local function onTeleport(s)
                if busy then return end
                busy = true
                task.spawn(function()
                    moverSay("Mover " .. data.id .. ": moving...", C.muted)
                    local ok, msg = moveUnit(data.unit, s)
                    moverSay("Mover " .. data.id .. ": " .. msg, ok and C.text or C.warn)
                    busy = false
                end)
            end

            for i, s in ipairs(data.locs) do
                addLocRow(rows, data.locs, s, (i - 1) * 32, onTeleport,
                    function(msg) moverSay("Mover " .. data.id .. ": " .. msg, C.text) end, rebuild)
            end

            local y = #data.locs * 32
            createButton(rows, {
                Size = UDim2.new(0.6, -3, 0, 28),
                Position = UDim2.new(0, 0, 0, y),
            }, "+ Add location", function()
                startPick(function(pos)
                    table.insert(data.locs, { n = nextLocName(data.locs), x = pos.X, y = pos.Y, z = pos.Z })
                    saveSpots()
                    rebuild()
                end)
            end)

            local armed = false
            local delMover
            delMover = createButton(rows, {
                Size = UDim2.new(0.4, -3, 0, 28),
                Position = UDim2.new(0.6, 3, 0, y),
            }, "Delete mover", function()
                if not armed then
                    armed = true
                    delMover.Text = "Sure?"
                    task.delay(3, function()
                        armed = false
                        if delMover.Parent then delMover.Text = "Delete mover" end
                    end)
                    return
                end
                for j, m in ipairs(spots.movers) do
                    if m == data then
                        table.remove(spots.movers, j)
                        break
                    end
                end
                saveSpots()
                card:Destroy()
            end)

            rows.Size = UDim2.new(1, -24, 0, y + 28)
            card.Size = UDim2.new(1, 0, 0, 34 + y + 28 + 10)
        end

        head.MouseButton1Click:Connect(function()
            expanded = not expanded
            rebuild()
        end)
        rebuild()
    end

    for _, data in ipairs(spots.movers) do buildMover(data, false) end
end

-- =================================================================
-- Macro: rekam dan putar ulang strategi
--   PlaceTower(nama, CFrame)   UpgradeTower(tower)   SellTower(tower)
-- Rekaman ditulis ke file LightHub_Macro_<nama>.json (daftar nama di
-- LightHub_Macro_Index.json). Tower dikenali lewat nama + posisi.
-- =================================================================
do
    local page = tabs["Macro"].page
    local inMatch = (game.PlaceId == MATCH_PLACE)
    local MACRO_INDEX = "LightHub_Macro_Index.json"

    local mstate = env.LightHubMacroState
    if not mstate then
        mstate = { rec = nil, handler = nil, hooked = false }
        env.LightHubMacroState = mstate
    end

    -- ---------------- File ----------------
    local function macroFile(name)
        return "LightHub_Macro_" .. name .. ".json"
    end

    local function cleanName(s)
        s = string.gsub(tostring(s or ""), "[^%w_%- ]", "")
        s = string.gsub(s, "^%s+", "")
        s = string.gsub(s, "%s+$", "")
        return string.sub(s, 1, 24)
    end

    local function badName(name)
        return name == "" or string.lower(name) == "index"
    end

    local function readIndex()
        local list = {}
        if canFile and isfile(MACRO_INDEX) then
            local ok, data = pcall(function() return HttpService:JSONDecode(readfile(MACRO_INDEX)) end)
            if ok and type(data) == "table" then list = data end
        end
        return list
    end

    local function writeIndex(list)
        pcall(writefile, MACRO_INDEX, HttpService:JSONEncode(list))
    end

    -- Daftar macro: dari index, ditambah hasil listfiles kalau executor mendukung
    local function macroNames()
        local out, seen = {}, {}
        local function add(n)
            if type(n) == "string" and not seen[n] and not badName(n) and isfile(macroFile(n)) then
                seen[n] = true
                out[#out + 1] = n
            end
        end
        if not canFile then return out end
        for _, n in ipairs(readIndex()) do add(n) end
        if listfiles then
            pcall(function()
                for _, path in ipairs(listfiles("")) do
                    add(string.match(path, "LightHub_Macro_(.+)%.json$"))
                end
            end)
        end
        table.sort(out)
        return out
    end

    local function macroOptions()
        local t = {}
        for _, n in ipairs(macroNames()) do t[#t + 1] = { label = n, value = n } end
        return t
    end

    local function isNums(t, n)
        if type(t) ~= "table" or #t ~= n then return false end
        for i = 1, n do
            if type(t[i]) ~= "number" then return false end
        end
        return true
    end

    local function validMacro(m)
        if type(m) ~= "table" or type(m.actions) ~= "table" or #m.actions > 500 then return false end
        for _, a in ipairs(m.actions) do
            if type(a) ~= "table" or (a.d ~= nil and type(a.d) ~= "number") then return false end
            if a.t == "wait" then
                -- hanya jeda
            elseif type(a.n) ~= "string" then
                return false
            elseif a.t == "place" then
                if not isNums(a.cf, 12) then return false end
            elseif a.t == "up" or a.t == "sell" then
                if not isNums(a.p, 3) then return false end
            else
                return false
            end
        end
        return true
    end

    -- Format macro lain: {"Name":..,"Actions":[{"t":"P","i":1,"p":[x,y,z],"n":"Unit","d":4.6},
    -- {"t":"U","i":1},{"t":"S","i":1},{"t":"W"}]}. i = nomor tower, d = jeda (detik).
    -- P=place, U=upgrade, S=sell, W=jeda saja.
    local function convertForeign(data)
        local src = data.Actions
        if type(src) ~= "table" then return nil end
        local towers, out = {}, {}
        for _, a in ipairs(src) do
            if type(a) == "table" then
                local d = type(a.d) == "number" and a.d or nil
                if a.t == "P" and type(a.n) == "string" and isNums(a.p, 3) and a.i then
                    towers[a.i] = { n = a.n, p = a.p }
                    out[#out + 1] = {
                        t = "place", n = a.n, d = d, w = 0,
                        cf = { a.p[1], a.p[2], a.p[3], 1, 0, 0, 0, 1, 0, 0, 0, 1 },
                    }
                elseif (a.t == "U" or a.t == "S") and towers[a.i] then
                    local tw = towers[a.i]
                    out[#out + 1] = {
                        t = (a.t == "U") and "up" or "sell", n = tw.n, d = d, w = 0,
                        p = { tw.p[1], tw.p[2], tw.p[3] },
                    }
                elseif a.t == "W" then
                    out[#out + 1] = { t = "wait", n = "wait", d = d, w = 0 }
                end
            end
        end
        return {
            v = 1,
            name = type(data.Name) == "string" and data.Name or "imported",
            actions = out,
        }
    end

    local function saveMacro(name, macro)
        if not canFile then
            notify("Macro", "Your executor can't write files.", 4)
            return false
        end
        local ok = pcall(function() writefile(macroFile(name), HttpService:JSONEncode(macro)) end)
        if not ok then return false end
        local list = readIndex()
        for _, n in ipairs(list) do
            if n == name then return true end
        end
        table.insert(list, name)
        writeIndex(list)
        return true
    end

    local function loadMacro(name)
        if not (canFile and name ~= "" and isfile(macroFile(name))) then return nil end
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(macroFile(name))) end)
        if ok and validMacro(data) then return data end
        return nil
    end

    local function deleteMacro(name)
        if delfile and isfile(macroFile(name)) then pcall(delfile, macroFile(name)) end
        local list, keep = readIndex(), {}
        for _, n in ipairs(list) do
            if n ~= name then keep[#keep + 1] = n end
        end
        writeIndex(keep)
    end

    -- ---------------- Tower ----------------
    local function findTower(name, x, z, r)
        local folder = workspace:FindFirstChild("Towers")
        if not folder then return nil end
        local best, bestD
        for _, t in ipairs(folder:GetChildren()) do
            if t.Name == name and t:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
                local ok, p = pcall(function() return t:GetPivot().Position end)
                if ok then
                    local d = math.sqrt((p.X - x) ^ 2 + (p.Z - z) ^ 2)
                    if d <= r and (not bestD or d < bestD) then
                        best, bestD = t, d
                    end
                end
            end
        end
        return best
    end

    -- ---------------- Rekam ----------------
    local function saveCurrentRec()
        local rec = mstate.rec
        if not rec then return end
        local acts = {}
        for _, a in ipairs(rec.actions) do
            acts[#acts + 1] = { t = a.t, n = a.n, w = a.w, cf = a.cf, p = a.p }
        end
        saveMacro(rec.name, { v = 1, name = rec.name, actions = acts })
    end

    local function stopRecording()
        local rec = mstate.rec
        if not rec then return end
        saveCurrentRec()
        mstate.rec = nil
        notify("Macro saved", "'" .. rec.name .. "': " .. #rec.actions .. " actions.", 4)
    end

    -- Dipanggil (deferred) saat game memanggil Place/Upgrade/SellTower.
    -- Aksi baru dicatat kalau hasilnya benar-benar terlihat di game.
    local function onCall(nm, a1, a2)
        local rec = mstate.rec
        if not rec then return end
        local ts = os.clock()
        local w = waveNow.cur or 0
        local act

        if nm == "PlaceTower" then
            if type(a1) ~= "string" or typeof(a2) ~= "CFrame" then return end
            local comps = { a2:GetComponents() }
            act = { t = "place", n = a1, cf = comps, w = w }
            local ok = false
            for _ = 1, 8 do
                task.wait(0.25)
                if findTower(a1, comps[1], comps[3], 4) then
                    ok = true
                    break
                end
            end
            if not ok then return end
        else
            if typeof(a1) ~= "Instance" then return end
            local okp, pos = pcall(function() return a1:GetPivot().Position end)
            if not okp then return end
            local lvl = a1:GetAttribute("Level")
            local up = (nm == "UpgradeTower")
            act = { t = up and "up" or "sell", n = a1.Name, p = { pos.X, pos.Y, pos.Z }, w = w }
            local ok = false
            for _ = 1, 8 do
                task.wait(0.25)
                if not a1.Parent then
                    ok = true
                    break
                end
                local nl = a1:GetAttribute("Level")
                if up and type(nl) == "number" and type(lvl) == "number" and nl > lvl then
                    ok = true
                    break
                end
            end
            if not ok then return end
        end

        act.ts = ts
        table.insert(rec.actions, act)
        table.sort(rec.actions, function(x, y) return x.ts < y.ts end)
        saveCurrentRec()
    end
    mstate.handler = onCall

    -- Aksi dari Unit Mover (sell + place + upgrade) ikut direkam saat Record aktif
    mstate.push = function(act)
        local rec = mstate.rec
        if not rec then return end
        act.ts = os.clock()
        table.insert(rec.actions, act)
        table.sort(rec.actions, function(x, y) return x.ts < y.ts end)
        saveCurrentRec()
    end

    -- Hook dipasang sekali per server, membaca handler dari mstate
    local function installHook()
        if mstate.hooked then return true end
        if not (hookmetamethod and newcclosure and getnamecallmethod) then return false end
        local ok = pcall(function()
            local orig
            orig = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if method == "InvokeServer" and mstate.rec and typeof(self) == "Instance"
                    and self.ClassName == "RemoteFunction" then
                    local nm = self.Name
                    if nm == "PlaceTower" or nm == "UpgradeTower" or nm == "SellTower" then
                        local a1, a2 = ...
                        local h = mstate.handler
                        if h and not (checkcaller and checkcaller()) then
                            task.defer(h, nm, a1, a2)
                        end
                    end
                end
                if setnamecallmethod then setnamecallmethod(method) end
                return orig(self, ...)
            end))
        end)
        mstate.hooked = ok
        return ok
    end

    -- ---------------- UI ----------------
    local selFile, refreshSel, selLabel
    local fRec, fPlay
    local play = { idx = 1, macro = nil, name = nil, stepSince = nil }

    if flags.macroSelected ~= "" and not (canFile and isfile(macroFile(flags.macroSelected))) then
        flags.macroSelected = ""
    end

    refreshSel = function()
        if selLabel then
            selLabel.Text = flags.macroSelected ~= "" and ("File: " .. flags.macroSelected) or "File: none selected"
        end
    end

    -- Make file
    local mk = createFeature(page, "Make Macro", { noToggle = true, bodyHeight = 28 })
    local mkInput = createInput(mk.body, { Size = UDim2.new(1, -86, 1, 0) }, "Macro name")
    createButton(mk.body, {
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -80, 0, 0),
    }, "Create", function()
        local name = cleanName(mkInput.Text)
        if badName(name) then
            notify("Macro", "Enter a valid macro name first.", 3)
            return
        end
        if canFile and isfile(macroFile(name)) then
            notify("Macro", "A macro with that name already exists.", 3)
            return
        end
        if saveMacro(name, { v = 1, name = name, actions = {} }) then
            mkInput.Text = ""
            setFlag("macroSelected", name)
            selFile.set(name)
            refreshSel()
            notify("Macro", "Created '" .. name .. "'.", 3)
        end
    end)

    -- List file + select + delete
    local fileCard = createFeature(page, "Macro File", { noToggle = true, bodyHeight = 28 })
    selFile = createSelect(fileCard.body, {
        Size = UDim2.new(1, -86, 1, 0),
    }, {
        initial = flags.macroSelected ~= "" and flags.macroSelected or nil,
        placeholder = "Select macro",
        getOptions = macroOptions,
        emptyMsg = "No macros yet. Create or import one first.",
        onChange = function(v)
            setFlag("macroSelected", v)
            refreshSel()
        end,
    })

    local armed = false
    local delBtn
    delBtn = createButton(fileCard.body, {
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -80, 0, 0),
    }, "Delete", function()
        local name = flags.macroSelected
        if name == "" then
            notify("Macro", "Select a macro to delete first.", 3)
            return
        end
        if not armed then
            armed = true
            delBtn.Text = "Sure?"
            task.delay(3, function()
                armed = false
                delBtn.Text = "Delete"
            end)
            return
        end
        armed = false
        delBtn.Text = "Delete"
        deleteMacro(name)
        setFlag("macroSelected", "")
        selFile.set(nil)
        refreshSel()
        notify("Macro", "Deleted '" .. name .. "'.", 3)
    end)

    -- Record
    fRec = createFeature(page, "Record Macro", {
        bodyHeight = 16,
        initial = flags.macroRecord,
        onToggle = function(v)
            if v then
                if flags.macroSelected == "" then
                    fRec.set(false)
                    notify("Macro", "Select or create a macro first.", 3)
                    return
                end
                if not installHook() then
                    fRec.set(false)
                    notify("Macro", "Your executor can't hook remotes, so recording isn't possible.", 5)
                    return
                end
                setFlag("macroRecord", true)
                if flags.macroPlay then
                    setFlag("macroPlay", false)
                    fPlay.set(false)
                end
                if not inMatch then
                    notify("Macro", "Recording is armed. It starts when the match begins.", 4)
                end
            else
                setFlag("macroRecord", false)
                stopRecording()
            end
        end,
    })
    selLabel = make("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.muted,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, fRec.body)
    refreshSel()

    -- Playback
    fPlay = createFeature(page, "Playback Macro", {
        initial = flags.macroPlay,
        onToggle = function(v)
            if v then
                if flags.macroSelected == "" then
                    fPlay.set(false)
                    notify("Macro", "Select a macro first.", 3)
                    return
                end
                setFlag("macroPlay", true)
                if flags.macroRecord then
                    setFlag("macroRecord", false)
                    fRec.set(false)
                    stopRecording()
                end
                play.idx, play.macro = 1, nil
            else
                setFlag("macroPlay", false)
            end
        end,
    })

    -- Share
    local share = createFeature(page, "Share Macro", { noToggle = true, bodyHeight = 28 })
    local shareSel = createSelect(share.body, {
        Size = UDim2.new(1, -96, 1, 0),
    }, {
        placeholder = "Select macro",
        getOptions = macroOptions,
        emptyMsg = "No macros yet. Create or import one first.",
    })
    createButton(share.body, {
        Size = UDim2.new(0, 90, 1, 0),
        Position = UDim2.new(1, -90, 0, 0),
    }, "Copy JSON", function()
        local name = shareSel.get()
        if not name or name == "" then
            notify("Macro", "Select a macro to share first.", 3)
            return
        end
        local m = loadMacro(name)
        if not m then
            notify("Macro", "Couldn't read that macro.", 3)
            return
        end
        if not setclipboard then
            notify("Macro", "Your executor can't copy to the clipboard.", 4)
            return
        end
        pcall(setclipboard, HttpService:JSONEncode({ v = 1, name = name, actions = m.actions }))
        notify("Macro", "JSON copied (" .. #m.actions .. " actions).", 3)
    end)

    -- Import
    local imp = createFeature(page, "Import Macro", { noToggle = true, bodyHeight = 108 })
    local jsonBox = createInput(imp.body, { Size = UDim2.new(1, 0, 0, 70) }, "Paste macro JSON here", true)
    local nameBox = createInput(imp.body, {
        Size = UDim2.new(1, -176, 0, 28),
        Position = UDim2.new(0, 90, 0, 78),
    }, "Macro name")
    local staged = nil

    createButton(imp.body, {
        Size = UDim2.new(0, 84, 0, 28),
        Position = UDim2.new(0, 0, 0, 78),
    }, "Import", function()
        local text = jsonBox.Text
        if text == "" then
            notify("Macro", "Paste the macro JSON first.", 3)
            return
        end
        local ok, data = pcall(function() return HttpService:JSONDecode(text) end)
        if ok and type(data) == "table" and data.Actions then
            data = convertForeign(data)
        end
        if not ok or not validMacro(data) then
            staged = nil
            notify("Macro", "That isn't a valid macro JSON.", 4)
            return
        end
        staged = data
        if nameBox.Text == "" and type(data.name) == "string" then
            nameBox.Text = cleanName(data.name)
        end
        notify("Macro", "Imported " .. #data.actions .. " actions. Enter a name and press Save.", 4)
    end)

    createButton(imp.body, {
        Size = UDim2.new(0, 80, 0, 28),
        Position = UDim2.new(1, -80, 0, 78),
    }, "Save", function()
        if not staged then
            notify("Macro", "Press Import first.", 3)
            return
        end
        local name = cleanName(nameBox.Text)
        if badName(name) then
            notify("Macro", "Enter a valid macro name.", 3)
            return
        end
        if saveMacro(name, { v = 1, name = name, actions = staged.actions }) then
            notify("Macro", "Saved '" .. name .. "'.", 3)
            staged = nil
            jsonBox.Text = ""
            nameBox.Text = ""
            setFlag("macroSelected", name)
            selFile.set(name)
            refreshSel()
        end
    end)

    -- ---------------- Loop rekam ----------------
    runLoop(function()
        if not flags.macroRecord then
            if mstate.rec then stopRecording() end
            fRec.setNote("")
            return 0.5
        end
        local sel = flags.macroSelected
        if sel == "" then
            fRec.setNote("Select a macro first", C.warn)
            return 1
        end
        if not inMatch then
            fRec.setNote("Armed: starts in the match", C.muted)
            return 1.5
        end
        local rec = mstate.rec
        if not rec or rec.name ~= sel or rec.job ~= game.JobId then
            if not installHook() then
                fRec.setNote("Executor can't record", C.warn)
                return 3
            end
            mstate.rec = { name = sel, job = game.JobId, actions = {} }
            mstate.handler = onCall
            saveCurrentRec()
            rec = mstate.rec
            notify("Recording macro", "Recording into '" .. sel .. "'. Just play normally.", 5)
        end
        fRec.setNote("Recording (" .. #rec.actions .. " actions)", C.text)
        return 0.5
    end)

    -- ---------------- Loop playback ----------------
    -- Berurutan: tiap aksi menunggu wave-nya, lalu diulang sampai berhasil
    -- (misalnya menunggu cash cukup). Aksi yang macet 90 detik dilewati.
    runLoop(function()
        if not flags.macroPlay then
            play.idx, play.macro = 1, nil
            fPlay.setNote("")
            return 0.5
        end
        if not inMatch then
            fPlay.setNote("Starts when the match begins", C.muted)
            return 2
        end
        local sel = flags.macroSelected
        if sel == "" then
            fPlay.setNote("Select a macro first", C.warn)
            return 1
        end
        if play.macro == nil or play.name ~= sel then
            play.macro = loadMacro(sel)
            play.name = sel
            play.idx = 1
            play.stepSince = nil
            if not play.macro then
                play.name = nil
                fPlay.setNote("Couldn't load this macro", C.warn)
                return 2
            end
        end

        local acts = play.macro.actions
        local a = acts[play.idx]
        if not a then
            fPlay.setNote("Macro finished", C.text)
            return 1.5
        end

        if a.w and a.w > 0 and waveNow.cur and waveNow.cur < a.w then
            fPlay.setNote("Waiting for wave " .. a.w, C.muted)
            play.stepSince = nil
            return 0.7
        end
        play.stepSince = play.stepSince or os.clock()
        if a.d and os.clock() - play.stepSince < a.d then
            local left = math.ceil(a.d - (os.clock() - play.stepSince))
            fPlay.setNote("Waiting " .. left .. "s (" .. play.idx .. "/" .. #acts .. ")", C.muted)
            return 0.3
        end

        local done = false
        if a.t == "wait" then
            done = true
        elseif a.t == "place" then
            if findTower(a.n, a.cf[1], a.cf[3], 4) then
                done = true
            else
                invoke("PlaceTower", a.n, CFrame.new(table.unpack(a.cf)))
                task.wait(0.6)
                done = findTower(a.n, a.cf[1], a.cf[3], 4) ~= nil
                if not done then
                    fPlay.setNote("Not enough cash (" .. play.idx .. "/" .. #acts .. ")", C.warn)
                end
            end
        else
            local tw = findTower(a.n, a.p[1], a.p[3], 4)
            if a.t == "up" then
                if not tw then
                    fPlay.setNote("Waiting for " .. a.n, C.muted)
                else
                    local price = tw:GetAttribute("UpgradePrice")
                    if type(price) ~= "number" or price <= 0 then
                        done = true -- sudah max
                    else
                        local lvl = tw:GetAttribute("Level")
                        local ok, res = invoke("UpgradeTower", tw)
                        task.wait(0.4)
                        local nl = tw:GetAttribute("Level")
                        done = (ok and res == true)
                            or (type(lvl) == "number" and type(nl) == "number" and nl > lvl)
                        if not done then
                            fPlay.setNote("Not enough cash (" .. play.idx .. "/" .. #acts .. ")", C.warn)
                        end
                    end
                end
            else
                if not tw then
                    done = true -- sudah tidak ada
                else
                    invoke("SellTower", tw)
                    task.wait(0.4)
                    done = (tw.Parent == nil)
                end
            end
        end

        if done then
            play.idx = play.idx + 1
            play.stepSince = nil
            fPlay.setNote("Playing " .. math.min(play.idx, #acts) .. "/" .. #acts, C.text)
            return 0.3
        end
        if os.clock() - play.stepSince > 90 + (a.d or 0) then
            notify("Macro", "Skipped step " .. play.idx .. ": it couldn't be completed in 90s.", 4)
            play.idx = play.idx + 1
            play.stepSince = nil
        end
        return 0.7
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
        bodyHeight = 26,
        onToggle = function(v) applyClaimState(v, true) end,
    })

    -- Baris atas: angka (RobotoMono, sama dengan angka di UI lain) + dropdown hadiah
    local giftOpen, giftRows = false, 1
    local rewards, lastClaimAt, lastClaimIndex, giftSig = {}, nil, nil, nil

    local CountLabel = make("TextLabel", {
        Size = UDim2.new(1, -110, 0, 24),
        BackgroundTransparency = 1,
        RichText = true,
        Text = "",
        TextColor3 = C.white,
        TextSize = 14,
        Font = Enum.Font.RobotoMono,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, feature.body)

    local DropBtn = make("TextButton", {
        Size = UDim2.new(0, 100, 0, 24),
        Position = UDim2.new(1, -100, 0, 0),
        BackgroundColor3 = C.control,
        BorderSizePixel = 0,
        Text = "Rewards",
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
    }, feature.body)
    make("UIPadding", { PaddingLeft = UDim.new(0, 10) }, DropBtn)
    make("UIStroke", {
        Color = C.controlLine,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, DropBtn)
    local DropArrow = createChevron(DropBtn, -8)
    DropBtn.MouseEnter:Connect(function() DropBtn.BackgroundColor3 = C.hover end)
    DropBtn.MouseLeave:Connect(function() DropBtn.BackgroundColor3 = C.control end)

    -- Daftar hadiah: satu baris per gift yang sudah diklaim
    local GiftList = make("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundTransparency = 1,
        Visible = false,
    }, feature.body)

    local function layoutGifts()
        GiftList.Visible = giftOpen
        DropArrow.Rotation = giftOpen and 180 or 0
        local listH = math.max(1, giftRows) * 22
        GiftList.Size = UDim2.new(1, 0, 0, listH)
        local bodyH = giftOpen and (30 + listH) or 24
        feature.body.Size = UDim2.new(1, -24, 0, bodyH)
        feature.card.Size = UDim2.new(1, 0, 0, 34 + bodyH + 10)
    end

    DropBtn.MouseButton1Click:Connect(function()
        giftOpen = not giftOpen
        layoutGifts()
    end)

    local function renderGifts()
        local entries, parts = {}, {}
        for i = 1, GIFT_COUNT do
            if rewards[i] or i <= claimedCount then
                entries[#entries + 1] = { i = i, text = rewards[i] }
                parts[#parts + 1] = i .. ":" .. tostring(rewards[i])
            end
        end
        local sig = claimedCount .. "#" .. table.concat(parts, "|")
        if sig == giftSig then return end
        giftSig = sig

        CountLabel.Text = tostring(claimedCount) .. "/" .. GIFT_COUNT
            .. ' <font size="10" face="GothamMedium" color="rgb(130,130,136)">claimed</font>'

        for _, c in ipairs(GiftList:GetChildren()) do c:Destroy() end
        if #entries == 0 then
            make("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = "No rewards yet",
                TextColor3 = C.dim,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, GiftList)
        end
        for r, e in ipairs(entries) do
            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.new(0, 0, 0, (r - 1) * 22),
                BackgroundColor3 = Color3.fromRGB(24, 24, 27),
                BorderSizePixel = 0,
            }, GiftList)
            make("TextLabel", {
                Size = UDim2.new(0, 28, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text = "#" .. e.i,
                TextColor3 = C.muted,
                TextSize = 11,
                Font = Enum.Font.RobotoMono,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)
            make("TextLabel", {
                Size = UDim2.new(1, -46, 1, 0),
                Position = UDim2.new(0, 38, 0, 0),
                BackgroundTransparency = 1,
                Text = e.text or "Claimed",
                TextColor3 = e.text and C.text or C.muted,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, row)
        end
        giftRows = #entries
        layoutGifts()
    end

    -- Hadiah dibaca dari notifikasi game yang muncul sesaat setelah klaim
    bindEvent("Notify", function(text)
        if type(text) ~= "string" or not lastClaimAt or not lastClaimIndex then return end
        if os.clock() - lastClaimAt > 3 or rewards[lastClaimIndex] then return end
        local clean = (string.gsub(text, "<[^>]+>", ""))
        if string.find(clean, "Auto Sell", 1, true) then return end
        rewards[lastClaimIndex] = string.sub(clean, 1, 60)
    end)

    -- Status singkat tampil di sebelah toggle
    local function setStatus(text, color)
        feature.setNote(text, color)
    end
    setStatus("", C.muted)
    renderGifts()

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
            setStatus("", C.muted)
        end
        if fromUser then
            settings.claimEnabled = v
            saveSettings()
        end
    end

    -- Toggle terkunci sampai data ID dari game tersedia
    local lastLocked = nil
    local function refreshLock()
        local id = readGameDay()

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
                rewards = {}
                local mask = LocalPlayer:GetAttribute("PlaytimeGiftClaimed")
                if type(mask) == "number" and popcount(mask) >= GIFT_COUNT then
                    staleMask = mask
                end
                task.wait(2)
                day = readGameDay()
            end
        end

        syncFromGame()
        renderGifts()

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

            lastClaimAt, lastClaimIndex = os.clock(), giftIndex
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
        renderGifts()

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
    -- Isi nama RemoteEvent animasi UTTM (server -> client) dari log Cobalt.
    -- Contoh: uttm = { "NamaEventSpin" },  Dibiarkan kosong kalau belum ketemu.
    uttm = {},
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
        applySkip("uttm", true)
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
    fSkipAnim = createFeature(page, "Skip Animation (Gacha)", {
        initial = settings.skipAnim,
        onToggle = function(v)
            settings.skipAnim = v
            saveSettings()
            if getconnections then
                applySkip("crate", v)
                applySkip("summon", v)
            elseif v then
                notify("Skip Animation", "Your executor can't hide crate/summon animations. Only the spin delay gets shorter.", 5)
            end
        end,
    })
    if not getconnections then fSkipAnim.setNote("Spin only", C.muted) end

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
    if ui.minimized then
        local w, m = waveNow.cur, waveNow.max
        MiniWaveValue.Text = w and (w .. (m and ("/" .. m) or "")) or "-"
        local frac = (w and m and m > 0) and math.clamp(w / m, 0, 1) or 0
        tween(MiniBarFill, 0.4, { Size = UDim2.new(frac, 0, 1, 0) })
    end
    return 1
end)

local function cleanup()
    run.claim = false
    run.upgrade = false
    if env.LightHubMacroState then env.LightHubMacroState.rec = nil end
    pcall(function() applySkip("crate", false) end)
    pcall(function() applySkip("summon", false) end)
    pcall(function() applySkip("uttm", false) end)
    if env.LightHubDrone then env.LightHubDrone.active = false end
    pcall(function() idledConn:Disconnect() end)
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    for _, c in pairs(towerConns) do pcall(function() c:Disconnect() end) end
    pcall(function() ScreenGui:Destroy() end)
    if env.AFKHubConn == idledConn then env.AFKHubConn = nil end
    env.LightHubCleanup = nil
end
env.LightHubCleanup = cleanup

local MINI_W = 340

-- Diperkecil: kotak kecil berisi nama hub, wave, dan timer. Diperbesar: kembali normal.
MinimizeBtn.MouseButton1Click:Connect(function()
    closeOverlay()
    ui.minimized = not ui.minimized
    local mini = ui.minimized
    Body.Visible = not mini
    MinLine.Visible = not mini
    MinBox.Visible = mini
    VersionLabel.Visible = not mini
    MiniWave.Visible = mini
    MiniBarTrack.Visible = mini
    applyTimerVisibility()
    tween(MainFrame, 0.15, {
        Size = mini and UDim2.new(0, MINI_W, 0, HEADER_H) or UDim2.new(0, WIN_W, 0, WIN_H),
    })
end)

-- Tekan pertama: minta konfirmasi (X berubah oranye 3 detik). Tekan kedua: tutup.
local closeArmed = false
CloseBtn.MouseButton1Click:Connect(function()
    if not closeArmed then
        closeArmed = true
        for _, b in ipairs(CloseBars) do b.BackgroundColor3 = C.warn end
        notify("Close Lightn Hub?", "Press X again within 3 seconds to close the script.", 3)
        task.delay(3, function()
            closeArmed = false
            for _, b in ipairs(CloseBars) do b.BackgroundColor3 = C.text end
        end)
        return
    end
    notify("Terminated", "Lightn Hub closed. All features stopped.", 2)
    cleanup()
end)

if settings.rerun then pcall(queueRerun) end
selectTab("Main")
notify("Loaded", "Welcome, " .. LocalPlayer.DisplayName, 3)
