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

local VERSION = "4.4"

local EVENT = {}
local GUI_NAME = "LightHub"
local FILE_NAME = "LightHub_Settings.json"
local SAVE_FILES = { FILE_NAME, "LightnHub_Settings.json", "RexHub_Settings.json" }

local WIN_W, WIN_H = 480, 320
local HEADER_H, SIDEBAR_W = 34, 108

local LOBBY_PLACE, MATCH_PLACE = 99703116573266, 117654154793149

-- Di luar lobby dan match (misalnya game lain), tanya dulu lewat notifikasi Roblox di pojok
-- kanan bawah (tanpa gambar). Script baru dimuat setelah pemain menekan tombol: Yes = lanjut
-- dimuat, No = script berhenti. Selama belum ditekan, script menunggu dan notifikasinya
-- ditampilkan lagi kalau sudah hilang. Kalau notifikasi tidak bisa ditampilkan sama sekali,
-- script jalan seperti biasa.
if game.PlaceId ~= LOBBY_PLACE and game.PlaceId ~= MATCH_PLACE then
    if not game:IsLoaded() then game.Loaded:Wait() end
    local answer
    local reply = Instance.new("BindableFunction")
    reply.OnInvoke = function(choice) answer = choice end
    local function ask()
        return pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Lightn Hub | Execute",
                Text = "Still execute LIGHTN HUB?",
                Button1 = "Yes",
                Button2 = "No",
                Callback = reply,
                Duration = 45,
            })
        end)
    end
    local shown = false
    for _ = 1, 20 do
        shown = ask()
        if shown then break end
        task.wait(0.5)
    end
    if shown then
        local t0 = os.clock()
        while answer == nil do
            task.wait(0.1)
            if answer == nil and os.clock() - t0 >= 45 then
                t0 = os.clock()
                ask()
            end
        end
    else
        answer = "Yes"
    end
    reply:Destroy()
    if answer ~= "Yes" then return end
end

local SKIP_WAVE_OFFSET = 0

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

local DEF = {}
for k, v in pairs(C) do DEF[k] = v end
C.hi = C.white
C.accent = C.white

local theme = { name = "Default", rev = {} }
local toHalloween, fromHalloween, T, setPalette
do
    local ACCENT = Color3.fromRGB(255, 140, 24)
    local BONE = Color3.fromRGB(255, 238, 212)
    local DARK_STOPS = {
        { 0, 9, 6, 4 }, { 0.12, 26, 15, 8 }, { 0.22, 46, 27, 12 },
        { 0.33, 78, 44, 18 }, { 0.6, 168, 128, 86 }, { 1, 222, 190, 148 },
    }
    local function rgb(r, g, b)
        return Color3.fromRGB(math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5))
    end
    local function darkRamp(l)
        local t = math.clamp(l / 215, 0, 1)
        for i = 2, #DARK_STOPS do
            local a, b = DARK_STOPS[i - 1], DARK_STOPS[i]
            if t <= b[1] then
                local k = (t - a[1]) / (b[1] - a[1])
                return rgb(a[2] + (b[2] - a[2]) * k, a[3] + (b[3] - a[3]) * k, a[4] + (b[4] - a[4]) * k)
            end
        end
        return rgb(222, 190, 148)
    end
    local function colorKey(c)
        return math.floor(c.R * 255 + 0.5) * 65536 + math.floor(c.G * 255 + 0.5) * 256 + math.floor(c.B * 255 + 0.5)
    end

    function toHalloween(kind, c)
        local r, g, b = c.R * 255, c.G * 255, c.B * 255
        if math.max(r, g, b) - math.min(r, g, b) > 9 then return c end
        local l = (r + g + b) / 3
        local out
        if kind == "bg" then
            out = (l >= 215) and ACCENT or darkRamp(l)
        elseif kind == "base" then
            if l >= 215 then return c end
            out = darkRamp(l)
        elseif kind == "txt" then
            out = (l >= 215) and BONE or darkRamp(l)
        elseif l >= 150 then

            local k = (l - 150) / 105
            out = rgb(205 + (255 - 205) * k, 78 + (176 - 78) * k, 10 + (32 - 10) * k)
        else
            out = darkRamp(l)
        end
        theme.rev[kind .. colorKey(out)] = c
        return out
    end
    function fromHalloween(kind, c)
        return theme.rev[kind .. colorKey(c)] or c
    end

    function T(c, kind)
        if theme.name ~= "Halloween" then return c end
        return toHalloween(kind or "gen", c)
    end
    local PALETTE_KIND = {
        text = "txt", muted = "txt", dim = "txt", ink = "txt",
        line = "gen", control = "bg", controlLine = "gen", hover = "bg",
    }
    function setPalette(name)
        local on = (name == "Halloween")
        for k, v in pairs(DEF) do
            C[k] = (on and PALETTE_KIND[k]) and toHalloween(PALETTE_KIND[k], v) or v
        end
        C.hi = on and BONE or DEF.white
        C.accent = on and ACCENT or DEF.white
    end
end

local DELAY_OPTIONS = {
    { label = "1s", value = 1 },
    { label = "0.5s", value = 0.5 },
    { label = "0.2s", value = 0.2 },
    { label = "0.1s", value = 0.1 },
}

local MAP_OPTIONS = {
    { label = "City", value = "City" },
    { label = "Canyon Bridge", value = "Canyon" },
    { label = "Wild Desert", value = "WildDesert" },
    { label = "Camera Lab", value = "Camera Lab" },
    { label = "Toilet Bunker", value = "ToiletBunker" },

    { label = "Spooky Town", value = "Halloween" },
    { label = "Endless", value = "Endless" },
}
local PLAYER_OPTIONS = {
    { label = "1", value = 1 },
    { label = "2", value = 2 },
    { label = "3", value = 3 },
    { label = "4", value = 4 },
}
local SPEED_MIN, SPEED_MAX, SPEED_STEP = 1.5, 3.5, 0.5
local function snapSpeed(v)
    if type(v) ~= "number" then return SPEED_MIN end
    v = math.clamp(v, SPEED_MIN, SPEED_MAX)
    return SPEED_MIN + math.floor((v - SPEED_MIN) / SPEED_STEP + 0.5) * SPEED_STEP
end
local MODE_OPTIONS = {
    { label = "Easy", value = "Easy" },
    { label = "Medium", value = "Medium" },
    { label = "Hard", value = "Hard" },
    { label = "Insane", value = "Insane" },
    { label = "Crazy", value = "Crazy" },
}

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

local LUCKY_OPTIONS = {
    { label = "Lucky Block I", value = "LuckyBlockI" },
    { label = "Lucky Block II", value = "LuckyBlockII" },
    { label = "Lucky Block III", value = "LuckyBlockIII" },
}

local settings = {
    theme = "Default",
    antiAfk = true,
    showTimer = true,
    cheapestFirst = true,
    upgradeDelay = 0.5,
    claimEnabled = false,
    skipAnim = false,
    fluidBg = true,
    autoMinimize = false,
}

local FLAG_DEFAULTS = {
    autoPlay = false, playMap = "", playPlayers = 1,
    macroSelected = "", macroRecord = false, macroPlay = false,
    autoSpeed = false, speedValue = 1.5,
    autoMode = false, modeValue = "",
    autoReplay = false,
    autoLobby = false,
    lossReturn = false, lossStreak = 0, lossNotice = false,
    forceLobby = false, forceMinutes = 20, lossLimit = 4, lossNoticeN = 4,
    autoSkip = false,
    autoSummon = false, summonAmount = 1,
    autoSpin = false,
    autoCrate = false, crateAmount = 1, crateType = "",
    autoLucky = false, luckyAmount = 1, luckyType = "",
    autoPotion = false, potionType = "",
    antiLag = false,
    autoSeason = false,
    autoQuest = false,
}

local SPEND_KEYS = { "autoSummon", "autoSpin", "autoCrate", "autoLucky", "autoPotion" }

local MIGRATE = {
    ["Party Crate"] = "PartyCrate", ["Free Scientist Crate"] = "Free",
    ["Scientist Crate"] = "ScientistCrate", ["10m Crate"] = "10MCrate",
    ["Fish Crate"] = "FishCrate", ["Lucky Potion"] = "Luck", ["Coin Potion"] = "Money",
}

local flags = {}
for k, v in pairs(FLAG_DEFAULTS) do flags[k] = v end

local run = { claim = false, upgrade = false }
local conns = {}

local function notify(sub, txt, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Lightn Hub | " .. sub,
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

local decor = { roots = {}, tweens = {}, hideMini = {}, steppers = {} }
do
    local WEB_COLOR = Color3.fromRGB(232, 196, 140)

    function decor.root(par, props)
        props.BackgroundTransparency = 1
        props.BorderSizePixel = 0
        props.Visible = false
        props.ClipsDescendants = true
        local f = make("Frame", props, par)
        decor.roots[#decor.roots + 1] = f
        return f
    end

    local function drawLine(par, x1, y1, x2, y2, color, alpha, thick)
        local dx, dy = x2 - x1, y2 - y1
        make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, (x1 + x2) / 2, 0, (y1 + y2) / 2),
            Size = UDim2.new(0, math.sqrt(dx * dx + dy * dy), 0, thick or 1),
            Rotation = math.deg(math.atan2(dy, dx)),
            BackgroundColor3 = color,
            BackgroundTransparency = alpha,
            BorderSizePixel = 0,
        }, par)
    end

    function decor.web(par, cx, cy, R, a0, a1, spokes, rings, alpha)
        local function pt(r, a)
            local rad = math.rad(a)
            return cx + r * math.cos(rad), cy + r * math.sin(rad)
        end
        for i = 0, spokes do
            local x, y = pt(R, a0 + (a1 - a0) * i / spokes)
            drawLine(par, cx, cy, x, y, WEB_COLOR, alpha)
        end
        for j = 1, rings do
            local r = R * (j / rings) ^ 1.2
            local px, py = pt(r, a0)
            for i = 1, spokes do
                local nx, ny = pt(r, a0 + (a1 - a0) * i / spokes)
                drawLine(par, px, py, nx, ny, WEB_COLOR, alpha + 0.04)
                px, py = nx, ny
            end
        end
    end

    local function oval(par, x, y, w, h, color, alpha)
        local f = make("Frame", {
            Position = UDim2.new(0, x, 0, y),
            Size = UDim2.new(0, w, 0, h),
            BackgroundColor3 = color,
            BackgroundTransparency = alpha or 0,
            BorderSizePixel = 0,
        }, par)
        make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
        return f
    end

    local function pulse(objs, lo, hi, secs)
        for _, o in ipairs(objs) do
            o.BackgroundTransparency = lo
            decor.tweens[#decor.tweens + 1] = TweenService:Create(o,
                TweenInfo.new(secs, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                { BackgroundTransparency = hi })
        end
    end

    local function poly(par, pts, color, grow, step)
        grow = grow or 0
        step = step or 1
        local n = #pts
        local minY, maxY = math.huge, -math.huge
        for _, p in ipairs(pts) do
            if p[2] < minY then minY = p[2] end
            if p[2] > maxY then maxY = p[2] end
        end
        local y = math.floor(minY)
        while y <= maxY do
            local sy = y + step / 2
            local xs = {}
            for i = 1, n do
                local a, b = pts[i], pts[i % n + 1]
                local y1, y2 = a[2], b[2]
                if (y1 <= sy and y2 > sy) or (y2 <= sy and y1 > sy) then
                    xs[#xs + 1] = a[1] + (sy - y1) / (y2 - y1) * (b[1] - a[1])
                end
            end
            table.sort(xs)
            for i = 1, #xs - 1, 2 do
                local x1, x2 = math.floor(xs[i] - grow), math.ceil(xs[i + 1] + grow)
                if x2 > x1 then
                    make("Frame", {
                        Position = UDim2.new(0, x1, 0, y - grow),
                        Size = UDim2.new(0, x2 - x1, 0, step + 1 + grow * 2),
                        BackgroundColor3 = (type(color) == "function") and color(y) or color,
                        BorderSizePixel = 0,
                    }, par)
                end
            end
            y = y + step
        end
    end

    local function limb(par, pts, w0, w1, color)
        local dense = { pts[1] }
        for i = 1, #pts - 1 do
            local a, b = pts[i], pts[i + 1]
            local len = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
            local n = math.max(1, math.ceil(len / 5))
            for k = 1, n do
                dense[#dense + 1] = { a[1] + (b[1] - a[1]) * k / n, a[2] + (b[2] - a[2]) * k / n }
            end
        end
        local total = 0
        for i = 1, #dense - 1 do
            total = total + math.sqrt((dense[i + 1][1] - dense[i][1]) ^ 2 + (dense[i + 1][2] - dense[i][2]) ^ 2)
        end
        local acc = 0
        for i = 1, #dense - 1 do
            local a, b = dense[i], dense[i + 1]
            local dx, dy = b[1] - a[1], b[2] - a[2]
            local len = math.sqrt(dx * dx + dy * dy)
            local w = math.max(1, math.floor(w0 + (w1 - w0) * ((acc + len / 2) / math.max(total, 1)) + 0.5))
            acc = acc + len
            local f = make("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, math.floor((a[1] + b[1]) / 2 + 0.5), 0, math.floor((a[2] + b[2]) / 2 + 0.5)),
                Size = UDim2.new(0, math.floor(len + w + 0.5), 0, w),
                Rotation = math.deg(math.atan2(dy, dx)),
                BackgroundColor3 = color,
                BorderSizePixel = 0,
            }, par)
            make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
        end
    end

    local function ell(cx, cy, rx, ry)
        local pts = {}
        for k = 0, 23 do
            local a = math.pi * 2 * k / 24
            pts[#pts + 1] = { cx + rx * math.cos(a), cy + ry * math.sin(a) }
        end
        return pts
    end

    local function drawPumpkinBody(body, cx, cy, rx, ry)
        local RIM = Color3.fromRGB(150, 56, 10)
        local SIDE = Color3.fromRGB(190, 72, 12)
        local MID = Color3.fromRGB(242, 114, 20)
        local lobes = {
            ell(cx - rx * 0.45, cy, rx * 0.62, ry),
            ell(cx + rx * 0.45, cy, rx * 0.62, ry),
            ell(cx, cy, rx * 0.58, ry * 1.04),
        }
        for _, l in ipairs(lobes) do poly(body, l, RIM, 1, 1) end
        poly(body, lobes[1], SIDE, 0, 1)
        poly(body, lobes[2], SIDE, 0, 1)
        poly(body, lobes[3], MID, 0, 1)
        poly(body, ell(cx - rx * 0.3, cy - ry * 0.55, rx * 0.2, ry * 0.15), Color3.fromRGB(255, 165, 64), 0, 1)
        for _, k in ipairs({ -0.5, 0.5 }) do
            limb(body, { { cx + k * rx, cy - ry * 0.8 }, { cx + k * rx * 1.04, cy }, { cx + k * rx * 0.92, cy + ry * 0.8 } },
                1, 1, Color3.fromRGB(128, 46, 8))
        end
        limb(body, { { cx, cy - ry + 1 }, { cx + 1, cy - ry - 3 }, { cx + 4, cy - ry - 5 } }, 4, 3,
            Color3.fromRGB(84, 108, 38))
    end

    local function drawPumpkinFace(glow, cx, cy, rx, ry)
        local eye = { { -0.66, -0.28 }, { -0.40, -0.24 }, { -0.10, 0.08 }, { -0.30, 0.10 }, { -0.52, -0.02 } }
        local mouth = {
            { -0.74, 0.22 }, { -0.58, 0.40 }, { -0.44, 0.26 }, { -0.30, 0.46 }, { -0.15, 0.30 }, { 0, 0.50 },
            { 0.15, 0.30 }, { 0.30, 0.46 }, { 0.44, 0.26 }, { 0.58, 0.40 }, { 0.74, 0.22 },
            { 0.66, 0.52 }, { 0.50, 0.66 }, { 0.36, 0.52 }, { 0.22, 0.72 }, { 0.10, 0.56 }, { 0, 0.78 },
            { -0.10, 0.56 }, { -0.22, 0.72 }, { -0.36, 0.52 }, { -0.50, 0.66 }, { -0.66, 0.52 },
        }
        local function P(pts, flip)
            local o = {}
            for _, q in ipairs(pts) do o[#o + 1] = { cx + (flip and -q[1] or q[1]) * rx, cy + q[2] * ry } end
            return o
        end
        local shapes = { P(eye), P(eye, true), P(mouth) }
        for _, sh in ipairs(shapes) do poly(glow, sh, Color3.fromRGB(255, 130, 20), 1, 1) end
        for _, sh in ipairs(shapes) do poly(glow, sh, Color3.fromRGB(255, 218, 70), 0, 1) end
    end

    function decor.crow(par)
        local BLK = Color3.fromRGB(18, 9, 20)
        local SHEEN = Color3.fromRGB(46, 28, 52)
        local BEAK = Color3.fromRGB(44, 32, 36)
        poly(par, { { 80, 90 }, { 89, 94 }, { 88, 96.5 }, { 79, 93 } }, BLK, 0, 1)
        limb(par, { { 75, 94 }, { 75, 97.5 } }, 1, 1, BLK)
        limb(par, { { 78.5, 94 }, { 78.5, 97.5 } }, 1, 1, BLK)
        poly(par, ell(76, 91, 6.5, 3.7), BLK, 0, 1)
        poly(par, { { 72, 89.5 }, { 80, 90.5 }, { 79, 92.5 }, { 72, 91.5 } }, SHEEN, 0, 1)
        local hl = make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 }, par)
        local hr = make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false }, par)
        poly(hl, ell(70, 86.5, 3.2, 3), BLK, 0, 1)
        poly(hl, { { 67.5, 85.5 }, { 63, 87.5 }, { 67.5, 88.8 } }, BEAK, 0, 1)
        make("Frame", { Position = UDim2.new(0, 69, 0, 85), Size = UDim2.new(0, 1, 0, 1),
            BackgroundColor3 = Color3.fromRGB(190, 170, 120), BorderSizePixel = 0 }, hl)
        poly(hr, ell(77.5, 86, 3.2, 3), BLK, 0, 1)
        poly(hr, { { 80, 85 }, { 84.5, 87 }, { 80, 88.3 } }, BEAK, 0, 1)
        make("Frame", { Position = UDim2.new(0, 79, 0, 84), Size = UDim2.new(0, 1, 0, 1),
            BackgroundColor3 = Color3.fromRGB(190, 170, 120), BorderSizePixel = 0 }, hr)
        local timer = math.random(3, 6)
        decor.steppers[#decor.steppers + 1] = function(dt)
            timer = timer - dt
            if timer <= 0 then
                timer = math.random(40, 100) / 10
                local right = not hr.Visible
                hr.Visible = right
                hl.Visible = not right
            end
        end
    end

    function decor.particles(par)
        local W, H = 107, 286
        local embers = make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 }, par)
        local leafL = make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false }, par)
        local E, Lf = {}, {}
        for i = 1, 9 do
            local sz = (i % 3 == 0) and 3 or 2
            local f = make("Frame", {
                Size = UDim2.new(0, sz, 0, sz), BorderSizePixel = 0,
                BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(255, 150, 46) or Color3.fromRGB(232, 110, 30),
            }, embers)
            E[i] = { f = f, x0 = math.random(8, 100), y = math.random(0, H), sp = math.random(9, 20),
                ph = math.random() * 6.28, sw = 2 + math.random() * 3 }
        end
        local leafCols = { Color3.fromRGB(150, 66, 20), Color3.fromRGB(118, 50, 22),
            Color3.fromRGB(176, 88, 28), Color3.fromRGB(132, 58, 20) }
        for i = 1, 4 do
            local f = make("Frame", {
                Size = UDim2.new(0, 5, 0, 3), AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = leafCols[i], BorderSizePixel = 0,
            }, leafL)
            make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
            Lf[i] = { f = f, x0 = math.random(10, 98), y = math.random(0, H - 20), sp = math.random(7, 13),
                ph = math.random() * 6.28 }
        end
        local t = 0
        decor.steppers[#decor.steppers + 1] = function(dt)
            t = t + dt
            for _, e in ipairs(E) do
                e.y = e.y - e.sp * dt
                if e.y < -4 then e.y = H + 4; e.x0 = math.random(8, 100) end
                local x = e.x0 + math.sin(t * 0.8 + e.ph) * e.sw
                local vis = math.max(0, math.min(1, (H - e.y) / 25, e.y / 60)) * 0.8
                e.f.Position = UDim2.new(x / W, 0, e.y / H, 0)
                e.f.BackgroundTransparency = 1 - vis
            end
            if leafL.Visible then
                for _, l in ipairs(Lf) do
                    l.y = l.y + l.sp * dt
                    if l.y > H - 6 then l.y = -6; l.x0 = math.random(10, 98) end
                    l.f.Position = UDim2.new((l.x0 + math.sin(t * 0.9 + l.ph) * 9) / W, 0, l.y / H, 0)
                    l.f.Rotation = math.sin(t * 1.2 + l.ph) * 50
                end
            end
        end
        return leafL
    end

    function decor.fog(par)
        local layer = make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 }, par)
        local F = {}
        for i, d in ipairs({ { -14, 262, 92, 16 }, { 30, 272, 96, 14 }, { -4, 254, 70, 12 } }) do
            for _, g in ipairs({ { 8, 4, 0.95 }, { 0, 0, 0.9 } }) do
                local f = make("Frame", {
                    Position = UDim2.new(0, d[1] - g[1] / 2, 0, d[2] - g[2] / 2),
                    Size = UDim2.new(0, d[3] + g[1], 0, d[4] + g[2]),
                    BackgroundColor3 = Color3.fromRGB(206, 190, 176), BackgroundTransparency = g[3], BorderSizePixel = 0,
                }, layer)
                make("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
                F[#F + 1] = { f = f, x = d[1] - g[1] / 2, y = d[2] - g[2] / 2, ph = i * 2.1, amp = 10 + 4 * i, sp = 0.15 + 0.04 * i }
            end
        end
        local t = 0
        decor.steppers[#decor.steppers + 1] = function(dt)
            t = t + dt
            for _, q in ipairs(F) do
                q.f.Position = UDim2.new((q.x + math.sin(t * q.sp + q.ph) * q.amp) / 107, 0, 0, q.y)
            end
        end
        return layer
    end

    function decor.flyBat(par)
        local root = decor.root(par, { Size = UDim2.new(1, 0, 1, 0) })
        decor.hideMini[root] = true
        local bat = make("Frame", {
            Size = UDim2.new(0, 20, 0, 12), BackgroundTransparency = 1, Visible = false,
        }, root)
        local C1 = Color3.fromRGB(74, 26, 60)
        local up = make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 }, bat)
        local down = make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false }, bat)
        local function wings(par2, pts)
            local r, l = {}, {}
            for _, q in ipairs(pts) do
                r[#r + 1] = { q[1], q[2] }
                l[#l + 1] = { 20 - q[1], q[2] }
            end
            poly(par2, r, C1, 0, 1)
            poly(par2, l, C1, 0, 1)
        end
        wings(up, { { 11, 6 }, { 13, 2 }, { 17, 0 }, { 19, 1 }, { 17, 3 }, { 18, 5 }, { 15, 5 }, { 13, 7 } })
        wings(down, { { 11, 5 }, { 14, 8 }, { 17, 11 }, { 19, 11 }, { 17, 9 }, { 18, 8 }, { 15, 8 }, { 12, 8 } })
        poly(bat, ell(10, 6.5, 2, 3.2), C1, 0, 1)
        poly(bat, { { 8.4, 3.6 }, { 8.4, 1.4 }, { 9.8, 3 } }, C1, 0, 1)
        poly(bat, { { 11.6, 3.6 }, { 11.6, 1.4 }, { 10.2, 3 } }, C1, 0, 1)
        local state, timer, t, dur, y0, acc, flap = 0, math.random(6, 12), 0, 7.5, 10, 0, false
        decor.steppers[#decor.steppers + 1] = function(dt)
            if not root.Visible then return end
            if state == 0 then
                timer = timer - dt
                if timer <= 0 then
                    state = 1; t = 0; y0 = math.random(6, 20); bat.Visible = true
                end
                return
            end
            t = t + dt
            acc = acc + dt
            if acc > 0.13 then
                acc = 0; flap = not flap
                up.Visible = not flap; down.Visible = flap
            end
            local k = t / dur
            bat.Position = UDim2.new(1.03 - 1.1 * k, 0, 0, math.floor(y0 + math.sin(t * 2.6) * 4))
            if k >= 1 then
                state = 0; bat.Visible = false; timer = math.random(25, 50)
            end
        end
        return root
    end

    function decor.tree(par)
        local box = make("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(0, 108, 0, 286),
            BackgroundTransparency = 1,
        }, par)
        oval(box, 0, 276, 108, 18, Color3.fromRGB(255, 112, 16), 0.75)
        local g = make("CanvasGroup", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, GroupTransparency = 0.08,
        }, box)
        local bark = Color3.fromRGB(62, 18, 44)
        local lit = Color3.fromRGB(104, 34, 68)
        local dark = Color3.fromRGB(30, 8, 24)

        for _, b in ipairs({
            { 5, 1.5, { { 60, 170 }, { 74, 156 }, { 86, 152 }, { 96, 138 }, { 103, 120 } } },
            { 3, 1, { { 86, 152 }, { 94, 160 }, { 104, 156 } } },
            { 2.5, 1, { { 96, 138 }, { 90, 126 }, { 93, 112 } } },
            { 5, 1.5, { { 47, 152 }, { 32, 140 }, { 22, 142 }, { 12, 126 }, { 5, 108 } } },
            { 3, 1, { { 22, 142 }, { 15, 154 }, { 5, 152 } } },
            { 2.5, 1, { { 12, 126 }, { 18, 114 }, { 14, 102 } } },
            { 4.5, 1.5, { { 55, 112 }, { 70, 98 }, { 80, 100 }, { 91, 84 }, { 97, 66 } } },
            { 2.5, 1, { { 80, 100 }, { 86, 110 }, { 98, 108 } } },
            { 4.5, 1.5, { { 48, 88 }, { 36, 74 }, { 27, 76 }, { 17, 60 }, { 11, 42 } } },
            { 2.5, 1, { { 27, 76 }, { 21, 88 }, { 9, 88 } } },
            { 4, 1.5, { { 54, 64 }, { 66, 50 }, { 76, 52 }, { 86, 36 }, { 90, 16 } } },
            { 2.5, 1, { { 76, 52 }, { 84, 60 }, { 98, 56 } } },
            { 4, 1.5, { { 50, 44 }, { 40, 30 }, { 32, 32 }, { 24, 16 }, { 21, 0 } } },
            { 3, 1, { { 51, 14 }, { 44, 4 }, { 40, -2 } } },
            { 3, 1, { { 52, 24 }, { 62, 10 }, { 68, 0 } } },
            { 5.5, 1.5, { { 42, 206 }, { 26, 196 }, { 14, 200 }, { 5, 186 } } },
            { 3, 1, { { 14, 200 }, { 8, 212 }, { 1, 214 } } },
            { 5.5, 1.5, { { 64, 204 }, { 80, 194 }, { 92, 198 }, { 103, 184 } } },
            { 3, 1, { { 92, 198 }, { 98, 210 }, { 106, 212 } } },
            { 7, 2, { { 32, 276 }, { 20, 282 }, { 8, 284 } } },
            { 7, 2, { { 74, 276 }, { 88, 282 }, { 102, 284 } } },
        }) do
            limb(g, b[3], b[1], b[2], bark)
        end

        local L = { { 24, 288 }, { 31, 270 }, { 35, 258 }, { 34, 240 }, { 36, 222 }, { 38, 205 }, { 42, 185 },
            { 43, 160 }, { 45, 130 }, { 46, 100 }, { 47, 70 }, { 48, 40 }, { 49, -4 } }
        local R = { { 82, 288 }, { 72, 270 }, { 69, 258 }, { 70, 240 }, { 68, 222 }, { 67, 205 }, { 63, 185 },
            { 61, 160 }, { 58, 130 }, { 56, 100 }, { 55, 70 }, { 53, 40 }, { 52, -4 } }
        local trunk = {}
        for _, p in ipairs(L) do trunk[#trunk + 1] = p end
        for i = #R, 1, -1 do trunk[#trunk + 1] = R[i] end
        poly(g, trunk, bark, 0, 2)

        local hw = { 8, 8, 8, 8, 8, 8, 7, 6, 5, 4, 3, 2, 1 }
        local hl = {}
        for i, p in ipairs(L) do hl[#hl + 1] = { p[1] + 2, p[2] } end
        for i = #L, 1, -1 do hl[#hl + 1] = { L[i][1] + 2 + hw[i], L[i][2] } end
        poly(g, hl, lit, 0, 2)

        for _, c in ipairs({
            { { 40, 284 }, { 43, 270 }, { 41, 262 } }, { { 66, 284 }, { 62, 272 }, { 64, 262 } },
            { { 47, 182 }, { 50, 168 }, { 48, 150 } }, { { 54, 176 }, { 53, 160 } },
            { { 50, 122 }, { 52, 100 } }, { { 49, 76 }, { 50, 56 } },
        }) do
            limb(g, c, 2, 1, dark)
        end

        poly(g, { { 38, 210 }, { 51, 217 }, { 51, 213 }, { 38, 205 } }, dark, 0, 1)
        poly(g, { { 66, 210 }, { 53, 217 }, { 53, 213 }, { 66, 205 } }, dark, 0, 1)
        poly(g, { { 50, 222 }, { 54, 222 }, { 52, 231 } }, dark, 0, 1)

        local gg = make("CanvasGroup", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, GroupTransparency = 0,
        }, box)
        local shapes = {
            { { 40, 214 }, { 50, 220 }, { 47, 227 }, { 40, 222 } },
            { { 64, 214 }, { 54, 220 }, { 57, 227 }, { 64, 222 } },
            { { 37, 235 }, { 44, 239 }, { 49, 235 }, { 52, 240 }, { 55, 235 }, { 60, 239 }, { 67, 235 },
                { 65, 245 }, { 58, 252 }, { 46, 252 }, { 39, 245 } },
        }
        for _, s in ipairs(shapes) do poly(gg, s, Color3.fromRGB(255, 112, 14), 2, 1) end
        for _, s in ipairs(shapes) do poly(gg, s, Color3.fromRGB(255, 214, 60), 0, 1) end

        drawPumpkinBody(g, 90, 275, 16, 10)
        drawPumpkinFace(gg, 90, 275, 16, 10)
        decor.crow(box)
        decor.tweens[#decor.tweens + 1] = TweenService:Create(gg,
            TweenInfo.new(1.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            { GroupTransparency = 0.1 })
        return box
    end

    function decor.bat(par, cx)
        local RIM = Color3.fromRGB(150, 62, 14)
        local MEM = Color3.fromRGB(38, 12, 32)
        local BODY = Color3.fromRGB(30, 9, 26)
        local BONE = Color3.fromRGB(96, 36, 66)

        local function wing(sign)
            local pts = {}
            for _, p in ipairs({
                { 5, -8 }, { 22, -20 }, { 48, -12 }, { 38, -6 }, { 40, 1 },
                { 31, -3 }, { 27, 3 }, { 20, -2 }, { 14, 2 }, { 6, -1 },
            }) do
                local lx = p[1] * 1.25
                local y = p[2]
                pts[#pts + 1] = { cx + sign * lx, y }
            end
            return pts
        end
        local wl, wr = wing(-1), wing(1)

        poly(par, wl, RIM, 1, 1)
        poly(par, wr, RIM, 1, 1)
        poly(par, { { cx - 6, -14 }, { cx - 5, -24 }, { cx - 1, -17 } }, RIM, 1, 1)
        poly(par, { { cx + 6, -14 }, { cx + 5, -24 }, { cx + 1, -17 } }, RIM, 1, 1)
        oval(par, cx - 8, -11, 16, 16, RIM)
        oval(par, cx - 7, -20, 14, 13, RIM)

        poly(par, wl, MEM, 0, 1)
        poly(par, wr, MEM, 0, 1)
        for _, w in ipairs({ wl, wr }) do
            limb(par, { w[1], w[2] }, 4, 3, BONE)
            for _, i in ipairs({ 3, 5, 7, 9 }) do
                limb(par, { w[2], w[i] }, 2, 1, BONE)
            end
        end

        poly(par, { { cx - 6, -14 }, { cx - 5, -24 }, { cx - 1, -17 } }, BODY, 0, 1)
        poly(par, { { cx + 6, -14 }, { cx + 5, -24 }, { cx + 1, -17 } }, BODY, 0, 1)
        oval(par, cx - 7, -10, 14, 14, BODY)
        oval(par, cx - 4, -7, 8, 9, Color3.fromRGB(58, 22, 46))
        oval(par, cx - 6, -19, 12, 11, BODY)

        for _, ex in ipairs({ -4, 1 }) do
            make("Frame", {
                Position = UDim2.new(0, cx + ex, 0, -15), Size = UDim2.new(0, 3, 0, 2),
                BackgroundColor3 = Color3.fromRGB(255, 196, 40), BorderSizePixel = 0,
            }, par)
        end
        for _, fx in ipairs({ -3, 1 }) do
            make("Frame", {
                Position = UDim2.new(0, cx + fx, 0, -9), Size = UDim2.new(0, 2, 0, 3),
                BackgroundColor3 = Color3.fromRGB(246, 236, 220), BorderSizePixel = 0,
            }, par)
        end
    end

    function decor.skullPeek(par)
        local BONE = Color3.fromRGB(226, 214, 188)
        local SHADE = Color3.fromRGB(185, 169, 138)
        local INK = Color3.fromRGB(42, 28, 38)
        local clip = make("Frame", {
            Position = UDim2.new(0, -60, 0, -60), Size = UDim2.new(0, 220, 0, 60),
            BackgroundTransparency = 1, ClipsDescendants = true,
        }, par)
        local off = make("Frame", {
            Position = UDim2.new(0, 60, 0, 60), Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1,
        }, clip)
        local tilt = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 19, 0, -2),
            Size = UDim2.new(0, 2, 0, 2), BackgroundTransparency = 1, Rotation = -12,
        }, off)
        local sk = make("Frame", {
            Position = UDim2.new(0, 1, 0, 1), Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1,
        }, tilt)
        local head = ell(0, 0, 11.2, 10.2)
        poly(sk, head, INK, 1, 1)
        poly(sk, head, BONE, 0, 1)
        poly(sk, { { 7, -8 }, { 10, -4 }, { 11, 0 }, { 10, 4 }, { 6, 9 }, { 3, 7 }, { 6, 3 }, { 7, -3 }, { 4, -9 } },
            SHADE, 0, 1)
        limb(sk, { { 5, -9 }, { 3, -5 }, { 5, -3 }, { 3.5, 0 } }, 1, 1, INK)
        poly(sk, ell(-4.2, -1, 3.2, 3.6), INK, 0, 1)
        poly(sk, ell(4.2, -1, 3.2, 3.6), INK, 0, 1)
        for _, ex in ipairs({ -5, 3 }) do
            make("Frame", {
                Position = UDim2.new(0, ex, 0, 0), Size = UDim2.new(0, 2, 0, 2),
                BackgroundColor3 = Color3.fromRGB(217, 130, 42), BorderSizePixel = 0,
            }, sk)
        end

        make("Frame", {
            Position = UDim2.new(0, 3, 0, -2), Size = UDim2.new(0, 32, 0, 2),
            BackgroundColor3 = Color3.fromRGB(23, 23, 27), BackgroundTransparency = 0.55, BorderSizePixel = 0,
        }, off)

        local hands = { { 3.5, 1 }, { 34.5, -1 } }
        local xs, len = { -3.9, -1.3, 1.3, 3.9 }, { 5.5, 7, 7, 5.5 }
        local function finger(cx, d, i)
            local x = cx + xs[i]
            return { { x, -2.6 }, { x, 0.6 }, { x + d * 0.3, 2 }, { x + d * 0.6, len[i] } }
        end
        for _, h in ipairs(hands) do
            oval(par, h[1] - 6.5, -5.6, 13, 5.4, INK)
            for i = 1, 4 do limb(par, finger(h[1], h[2], i), 3, 3, INK) end
        end
        for _, h in ipairs(hands) do
            oval(par, h[1] - 5.5, -4.6, 11, 3.4, BONE)
            for i = 1, 4 do limb(par, finger(h[1], h[2], i), 2, 2, BONE) end
        end
    end

    function decor.gearPumpkin(par)
        local K = 0.052
        local function map(pts)
            local o = {}
            for _, q in ipairs(pts) do o[#o + 1] = { 19 + (q[1] - 404) * K, 17 + (q[2] - 720) * K } end
            return o
        end
        local function C(r, g, b) return Color3.fromRGB(r, g, b) end
        local TOP, MID, BOT = C(224, 124, 8), C(212, 66, 4), C(200, 26, 3)
        local function bodyColor(y)
            local t = math.max(0, math.min(1, (y + 12) / 48))
            if t < 0.55 then return TOP:Lerp(MID, t / 0.55) end
            return MID:Lerp(BOT, (t - 0.55) / 0.45)
        end
        local function mouthColor(y)
            return C(212, 188, 2):Lerp(C(207, 158, 1), math.max(0, math.min(1, (y - 6) / 22)))
        end

        local body = map({ { 105, 235 }, { 150, 200 }, { 300, 170 }, { 470, 168 }, { 610, 200 }, { 745, 372 },
            { 748, 470 }, { 700, 810 }, { 685, 960 }, { 650, 1030 }, { 420, 1090 }, { 155, 1030 }, { 120, 950 },
            { 95, 780 }, { 62, 540 }, { 70, 360 } })
        local stem = map({ { 350, 165 }, { 432, 165 }, { 430, 110 }, { 455, 75 }, { 445, 48 }, { 425, 40 }, { 385, 90 } })
        poly(par, stem, C(40, 8, 3), 1, 1)
        poly(par, stem, C(60, 14, 5), 0, 1)
        poly(par, body, C(110, 22, 4), 1, 1)
        poly(par, body, bodyColor, 0, 1)

        poly(par, map({ { 440, 172 }, { 610, 202 }, { 742, 372 }, { 700, 345 }, { 580, 270 } }), C(232, 142, 22), 0, 1)

        local mouth = map({ { 168, 458 }, { 208, 502 }, { 300, 497 }, { 375, 494 }, { 535, 582 }, { 576, 568 },
            { 640, 530 }, { 626, 640 }, { 610, 740 }, { 560, 862 }, { 525, 908 }, { 418, 870 }, { 390, 940 },
            { 342, 940 }, { 335, 862 }, { 252, 880 }, { 268, 942 }, { 230, 940 }, { 205, 740 }, { 168, 545 } })
        local eyeL = map({ { 328, 255 }, { 360, 262 }, { 366, 295 }, { 362, 372 }, { 330, 392 }, { 290, 380 },
            { 277, 345 }, { 292, 298 } })
        local eyeR = map({ { 482, 286 }, { 505, 300 }, { 535, 345 }, { 547, 375 }, { 525, 420 }, { 487, 436 },
            { 455, 425 }, { 440, 385 }, { 443, 330 }, { 460, 298 } })

        local gl = make("CanvasGroup", {
            Position = UDim2.new(0, -4, 0, -20), Size = UDim2.new(0, 50, 0, 62),
            BackgroundTransparency = 1, GroupTransparency = 0.78,
        }, par)
        local gofs = make("Frame", { Position = UDim2.new(0, 4, 0, 20), Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, gl)
        poly(gofs, mouth, C(255, 196, 50), 2, 1)
        poly(gofs, eyeL, C(255, 196, 50), 2, 1)
        poly(gofs, eyeR, C(255, 196, 50), 2, 1)

        poly(par, mouth, mouthColor, 0, 1)
        poly(par, eyeL, C(214, 190, 4), 0, 1)
        poly(par, eyeR, C(214, 190, 4), 0, 1)

    end

    function decor.spider(par, x)
        local H = HEADER_H
        local cx = 13
        local pivot = decor.root(par, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, x, 0, 0),
            Size = UDim2.new(0, 26, 0, H * 2),
        })
        pivot.ClipsDescendants = false
        make("Frame", {
            Position = UDim2.new(0, cx - 1, 0, H), Size = UDim2.new(0, 2, 0, 11),
            BackgroundColor3 = WEB_COLOR, BackgroundTransparency = 0.1, BorderSizePixel = 0,
        }, pivot)
        local hinge = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, cx, 0, H + 11),
            Size = UDim2.new(0, 26, 0, 26),
            BackgroundTransparency = 1,
        }, pivot)
        local legC = Color3.fromRGB(120, 48, 74)
        local bodyC = Color3.fromRGB(58, 18, 44)
        local rim = Color3.fromRGB(190, 80, 18)

        for _, sd in ipairs({ -1, 1 }) do
            for _, l in ipairs({
                { { 2, 15 }, { 6, 11 }, { 10, 14 } },
                { { 2, 16 }, { 8, 15 }, { 11, 19 } },
                { { 2, 18 }, { 8, 20 }, { 10, 24 } },
                { { 2, 19 }, { 6, 23 }, { 7, 25 } },
            }) do
                local pts = {}
                for _, q in ipairs(l) do pts[#pts + 1] = { cx + sd * q[1], q[2] } end
                limb(hinge, pts, 2, 2, legC)
            end
        end
        oval(hinge, cx - 5, 14, 10, 10, rim)
        oval(hinge, cx - 4, 15, 8, 8, bodyC)
        oval(hinge, cx - 3, 11, 6, 6, rim)
        oval(hinge, cx - 2, 12, 4, 4, bodyC)
        make("Frame", {
            Position = UDim2.new(0, cx - 1, 0, 19), Size = UDim2.new(0, 2, 0, 3),
            BackgroundColor3 = Color3.fromRGB(255, 120, 20), BorderSizePixel = 0,
        }, hinge)
        for _, ex in ipairs({ -2, 1 }) do
            make("Frame", {
                Position = UDim2.new(0, cx + ex, 0, 13), Size = UDim2.new(0, 1, 0, 2),
                BackgroundColor3 = Color3.fromRGB(255, 70, 40), BorderSizePixel = 0,
            }, hinge)
        end
        pivot.Rotation = -10
        hinge.Rotation = 7
        decor.tweens[#decor.tweens + 1] = TweenService:Create(pivot,
            TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 10 })
        decor.tweens[#decor.tweens + 1] = TweenService:Create(hinge,
            TweenInfo.new(3.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = -7 })
        decor.hideMini[pivot] = true
        return pivot
    end
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

local function getStatN(name)
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    local v = ls and ls:FindFirstChild(name)
    if v and type(v.Value) == "number" then return v.Value end
    return nil
end

local canFile = (writefile and readfile and isfile) and true or false

local FS = { root = "LightHub", dir = false }
do
    if canFile and makefolder and isfolder then
        pcall(function()
            for _, p in ipairs({ FS.root, FS.root .. "/Settings", FS.root .. "/Macros", FS.root .. "/Data" }) do
                if not isfolder(p) then makefolder(p) end
            end
        end)
        local ok, r = pcall(function()
            return isfolder(FS.root .. "/Settings") and isfolder(FS.root .. "/Macros") and isfolder(FS.root .. "/Data")
        end)
        FS.dir = (ok and r == true) or false
        if FS.dir and delfile then
            local t = FS.root .. "/Data/.probe"
            local okw = pcall(writefile, t, "1")
            if okw and isfile(t) then pcall(delfile, t) else FS.dir = false end
        end
    end
    function FS.settings()
        local uid = tostring(LocalPlayer and LocalPlayer.UserId or 0)
        return FS.dir and (FS.root .. "/Settings/" .. uid .. ".json") or ("LightHub_Settings_" .. uid .. ".json")
    end
    function FS.macro(name)
        return FS.dir and (FS.root .. "/Macros/" .. name .. ".json") or ("LightHub_Macro_" .. name .. ".json")
    end
    function FS.index()
        return FS.dir and (FS.root .. "/Macros/_index.json") or "LightHub_Macro_Index.json"
    end
    function FS.data(n)
        return FS.dir and (FS.root .. "/Data/" .. n .. ".json") or ("LightHub_" .. n .. ".json")
    end

    local function copyOnce(from, to)
        if from == to then return end
        pcall(function()
            if isfile(from) and not isfile(to) then writefile(to, readfile(from)) end
        end)
    end
    if FS.dir then
        copyOnce("LightHub_Macro_Index.json", FS.index())
        copyOnce("LightHub_Spots.json", FS.data("Spots"))
        copyOnce("LightHub_History.json", FS.data("History"))
        local names = {}
        pcall(function()
            if isfile("LightHub_Macro_Index.json") then
                local list = HttpService:JSONDecode(readfile("LightHub_Macro_Index.json"))
                if type(list) == "table" then
                    for _, n in ipairs(list) do if type(n) == "string" then names[n] = true end end
                end
            end
        end)
        pcall(function()
            if listfiles then
                for _, path in ipairs(listfiles("")) do
                    local n = string.match(path, "LightHub_Macro_(.+)%.json$")
                    if n and string.lower(n) ~= "index" then names[n] = true end
                end
            end
        end)
        for n in pairs(names) do copyOnce("LightHub_Macro_" .. n .. ".json", FS.macro(n)) end
    end
end

local function saveSettings()
    if not canFile then return end
    local data = {
        antiAfk = settings.antiAfk,
        theme = settings.theme,
        showTimer = settings.showTimer,
        cheapestFirst = settings.cheapestFirst,
        upgradeDelay = settings.upgradeDelay,
        claimEnabled = settings.claimEnabled,
        skipAnim = settings.skipAnim,
        autoMinimize = settings.autoMinimize,
        flags = flags,
    }
    pcall(function()
        writefile(FS.settings(), HttpService:JSONEncode(data))
    end)
end

local function setFlag(key, value)
    flags[key] = value
    saveSettings()
end

local function readSaved()

    local mine = FS.settings()
    local okm, rawm = pcall(function()
        if isfile(mine) then return readfile(mine) end
    end)
    if okm and rawm then return rawm end
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
    if data.theme == "Default" or data.theme == "Halloween" then settings.theme = data.theme end
    if type(data.cheapestFirst) == "boolean" then settings.cheapestFirst = data.cheapestFirst end
    if type(data.claimEnabled) == "boolean" then settings.claimEnabled = data.claimEnabled end
    if type(data.skipAnim) == "boolean" then settings.skipAnim = data.skipAnim end

    if data.skipCrateAnim == true or data.skipSummonAnim == true or data.skipSpinAnim == true then
        settings.skipAnim = true
    end
    if type(data.autoMinimize) == "boolean" then settings.autoMinimize = data.autoMinimize end
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

    if not inOptions(SUMMON_OPTIONS, flags.summonAmount) then flags.summonAmount = 1 end
    if not inOptions(CRATE_AMOUNT_OPTIONS, flags.crateAmount) then flags.crateAmount = 1 end
    if not inOptions(CRATE_AMOUNT_OPTIONS, flags.luckyAmount) then flags.luckyAmount = 1 end
    flags.speedValue = snapSpeed(flags.speedValue)
    if flags.modeValue ~= "" and not inOptions(MODE_OPTIONS, flags.modeValue) then flags.modeValue = "" end
    if flags.macroSelected ~= "" and not (isfile and isfile(FS.macro(flags.macroSelected))) then
        flags.macroSelected = ""
    end
    do
        local legacy = { CameramaLab = "Camera Lab", ["Canyon Bridge"] = "Canyon", CanyonBridge = "Canyon", ["Wild Desert"] = "WildDesert", ["Spooky Town"] = "Halloween", SpookyTown = "Halloween" }
        if legacy[flags.playMap] then flags.playMap = legacy[flags.playMap] end
    end
    if not inOptions(MAP_OPTIONS, flags.playMap) then flags.playMap = "" end
    if not inOptions(PLAYER_OPTIONS, flags.playPlayers) then flags.playPlayers = 1 end
    for _, k in ipairs(SPEND_KEYS) do flags[k] = false end
end

loadSettings()

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

local idledConn = LocalPlayer.Idled:Connect(function()
    if not settings.antiAfk then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)
env.AFKHubConn = idledConn

local function RF(name)
    local folder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
    return folder and folder:FindFirstChild(name)
end

local function RE(name)
    local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    return folder and folder:FindFirstChild(name)
end

local EP = {}

do
    local since = nil
    local function clearFlag()
        pcall(function() LocalPlayer:SetAttribute("_ExclusiveCrateOpening", nil) end)
    end
    EP.animBusy = function()
        if not LocalPlayer:GetAttribute("_ExclusiveCrateOpening") then
            since = nil
            return false
        end
        if settings.skipAnim and getconnections then
            clearFlag()
            since = nil
            return false
        end
        since = since or os.clock()
        if os.clock() - since > 12 then
            clearFlag()
            since = nil
            return false
        end
        return true
    end
end

local placeHook = { active = false, ready = false, handler = nil, install = nil,
    register = nil, registry = setmetatable({}, { __mode = "k" }) }

local function invoke(name, ...)
    local remote = RF(name)
    if not remote then return false, "remote tidak ada: " .. name end
    local args = table.pack(...)

    if name == "PlaceTower" and placeHook.register and typeof(args[2]) == "CFrame" then
        task.spawn(placeHook.register, args[1], args[2])
    end
    return pcall(function()
        return remote:InvokeServer(table.unpack(args, 1, args.n))
    end)
end

local function accepted(ok, res)
    if not ok or res == false then return false end
    if type(res) == "table" and (res.Success == false or res.success == false) then
        return false
    end
    return true
end

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

if game.PlaceId == LOBBY_PLACE then
    local hw = settings.theme == "Halloween"
    local ACC = hw and Color3.fromRGB(255, 140, 24) or Color3.fromRGB(226, 226, 230)
    local TXT = hw and Color3.fromRGB(255, 214, 80) or Color3.fromRGB(236, 236, 240)
    local TRACK = hw and Color3.fromRGB(130, 64, 14) or Color3.fromRGB(92, 92, 98)
    local DIM = hw and Color3.fromRGB(8, 5, 3) or Color3.fromRGB(6, 6, 7)
    MainFrame.Visible = false

    local root = make("CanvasGroup", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        GroupTransparency = 1, ZIndex = 60,
    }, ScreenGui)
    make("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = DIM,
        BackgroundTransparency = 0.4, BorderSizePixel = 0,
    }, root)

    local SIDE, GAP, TH = 96, 9, 3
    local L = SIDE + GAP * 2
    local cy = -14
    local glow = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, cy),
        Size = UDim2.new(0, L + 16, 0, L + 16), BackgroundColor3 = ACC,
        BackgroundTransparency = 0.92, BorderSizePixel = 0,
    }, root)
    local box = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, cy),
        Size = UDim2.new(0, L, 0, L), BackgroundTransparency = 1, BorderSizePixel = 0,
    }, root)
    make("UIStroke", { Color = TRACK, Thickness = 2, Transparency = 0.3 }, box)
    local bars = {
        make("Frame", { Size = UDim2.new(0, 0, 0, TH), BackgroundColor3 = ACC, BorderSizePixel = 0 }, box),
        make("Frame", {
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(0, TH, 0, 0), BackgroundColor3 = ACC, BorderSizePixel = 0,
        }, box),
        make("Frame", {
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0),
            Size = UDim2.new(0, 0, 0, TH), BackgroundColor3 = ACC, BorderSizePixel = 0,
        }, box),
        make("Frame", {
            AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(0, TH, 0, 0), BackgroundColor3 = ACC, BorderSizePixel = 0,
        }, box),
    }

    local function setProg(p)
        for i = 1, 4 do
            local f = math.clamp(p * 4 - (i - 1), 0, 1)
            if i % 2 == 1 then
                bars[i].Size = UDim2.new(f, 0, 0, TH)
            else
                bars[i].Size = UDim2.new(0, TH, f, 0)
            end
        end
    end

    local icon = make("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, cy),
        Size = UDim2.new(0, SIDE, 0, SIDE), BackgroundColor3 = Color3.fromRGB(22, 22, 26),
        BorderSizePixel = 0, ScaleType = Enum.ScaleType.Fit,
        Image = "rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=150&h=150",
    }, root)

    local letter = make("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "L",
        TextColor3 = TXT, TextSize = 40, Font = Enum.Font.GothamBold,
    }, icon)
    make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, cy + L / 2 + 14),
        Size = UDim2.new(0, 300, 0, 22), BackgroundTransparency = 1,
        Text = "Loading LIGHTN HUB v" .. VERSION, TextColor3 = TXT, TextSize = 14, Font = Enum.Font.GothamBold,
    }, root)

    local t0, prog, finished = nil, 0, false
    local spin
    spin = RunService.Heartbeat:Connect(function(dt)
        t0 = t0 or os.clock()
        local el = os.clock() - t0
        local iconOk = icon.IsLoaded or el > 1.5
        letter.TextTransparency = icon.IsLoaded and 1 or 0
        local target = (EVENT.hubReady and iconOk) and 1 or 0.9
        prog = math.min(target, prog + dt / 1.4)
        setProg(prog)
        glow.BackgroundTransparency = 0.9 + 0.05 * math.sin(el * 3)
        if prog >= 1 then finished = true end
    end)
    table.insert(conns, spin)

    task.spawn(function()
        tween(root, 0.25, { GroupTransparency = 0 })
        local waited = 0
        while waited < 8 and not finished do
            task.wait(0.05)
            waited = waited + 0.05
        end
        task.wait(0.15)

        local P = EVENT.parts or {}
        local function veil(par)
            if not par then return nil end
            return make("Frame", {
                Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(10, 10, 11),
                BorderSizePixel = 0, ZIndex = 100,
            }, par)
        end
        local sv, pv = veil(P.sidebar), veil(P.page)
        local nv = P.nav
        if nv then
            for _, g in ipairs(nv.groups) do
                if g.label then g.label.TextTransparency = 1 end
            end
        end
        local pagePos = P.page and P.page.Position
        if pagePos then P.page.Position = pagePos + UDim2.new(0, 0, 0, 10) end

        MainFrame.Visible = true
        tween(root, 0.35, { GroupTransparency = 1 })
        task.wait(0.25)

        if sv then tween(sv, 0.3, { BackgroundTransparency = 1 }) end
        if nv then
            for i, g in ipairs(nv.groups) do
                if g.label then
                    task.delay(0.06 * (i - 1), function() tween(g.label, 0.25, { TextTransparency = 0 }) end)
                end
            end
        end
        task.wait(0.35)

        if pv then tween(pv, 0.35, { BackgroundTransparency = 1 }) end
        if pagePos then tween(P.page, 0.35, { Position = pagePos }) end
        task.wait(0.4)
        if sv then sv:Destroy() end
        if pv then pv:Destroy() end
        spin:Disconnect()
        root:Destroy()
    end)
end

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

local movers = {}
local function swing(frame, lo, hi, base, amp, speed, phase)
    lo, hi = T(lo, "gen"), T(hi, "gen")
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

local function titleSeq(t)
    if theme.name == "Halloween" then

        local p = (t * 0.3) % 1.7 - 0.35
        local list = {}
        for i = 0, 8 do
            local x = i / 8
            local k = math.max(0, 1 - math.abs(x - p) / 0.24)
            list[#list + 1] = ColorSequenceKeypoint.new(x, Color3.fromRGB(
                math.floor(214 + 41 * k), math.floor(96 + 130 * k), math.floor(18 + 100 * k)))
        end
        return ColorSequence.new(list)
    end
    local kps = {}
    local n = 6
    for i = 0, n do
        local x = i / n
        local v = 0.5 + 0.5 * math.sin((x * 1.3 - t * 0.12) * math.pi * 2)
        local g = math.floor(125 + 130 * v)
        kps[#kps + 1] = ColorSequenceKeypoint.new(x, T(Color3.fromRGB(g, g, g), "gen"))
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
    if fluid.acc < 0.06 then return end
    fluid.t = fluid.t + fluid.acc
    fluid.acc = 0
    local t = fluid.t
    if theme.name == "Halloween" then

        local flick = math.sin(t * 2.3) * 0.03 + math.sin(t * 5.1) * 0.015
        local a = math.sin(t * 0.32) * 0.3 + flick
        local b = math.sin(t * 0.21 + 1.3) * 0.25 - flick
        fluid.gradA.Rotation = 90
        fluid.gradA.Offset = Vector2.new(a, a)
        fluid.gradB.Rotation = 90
        fluid.gradB.Offset = Vector2.new(b, -b)
        for _, m in ipairs(movers) do
            local o = math.sin(t * m.speed * 1.5 + m.phase) * 0.5 + flick
            m.g.Rotation = m.base
            m.g.Offset = Vector2.new(o, o)
        end
    else
        fluid.gradA.Rotation = (t * 4) % 360
        fluid.gradA.Offset = Vector2.new(math.sin(t * 0.21) * 0.12, math.cos(t * 0.17) * 0.12)
        fluid.gradB.Rotation = (120 - t * 3) % 360
        fluid.gradB.Offset = Vector2.new(math.cos(t * 0.13) * 0.12, math.sin(t * 0.19) * 0.12)
        for _, m in ipairs(movers) do
            m.g.Rotation = m.base + math.sin(t * m.speed + m.phase) * m.amp
        end
    end
    if fluid.titleGrad then fluid.titleGrad.Color = titleSeq(t) end
end))

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

do
    local root = decor.root(MainFrame, { Size = UDim2.new(1, 0, 1, 0) })
    decor.web(root, WIN_W, 0, 130, 90, 180, 6, 5, 0.86)
    decor.hideMini[root] = true
end

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
decor.spider(Header, 262)
decor.flyBat(Header)

local TitleRow = make("Frame", {
    Size = UDim2.new(0, 220, 1, 0),
    Position = UDim2.new(0, 34, 0, 0),
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
    TextColor3 = C.hi,
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
    TextColor3 = C.hi,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Right,
}, Header)

local ui = { minimized = false, lastTouch = os.clock() }

function ui.poke() ui.lastTouch = os.clock() end
function ui.watch(o)
    if o:IsA("GuiObject") then
        o.InputBegan:Connect(ui.poke)
        o.InputChanged:Connect(ui.poke)
    end
end
ui.watch(MainFrame)
for _, d in ipairs(MainFrame:GetDescendants()) do ui.watch(d) end
table.insert(conns, MainFrame.DescendantAdded:Connect(ui.watch))

do
    local btn = make("TextButton", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(0, 8, 0.5, -11),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, Header)

    local GEAR_ORANGE = Color3.fromRGB(168, 60, 8)
    local icon = make("Frame", {
        Size = UDim2.new(0, 15, 0, 15),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
    }, btn)
    local function part(w, h, rot, color, round)
        local f = make("Frame", {
            Size = UDim2.new(0, w, 0, h),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Rotation = rot,
            BackgroundColor3 = color,
            BorderSizePixel = 0,
        }, icon)
        if round then make("UICorner", { CornerRadius = UDim.new(1, 0) }, f) end
        return f
    end
    local gparts = {}
    for _, rot in ipairs({ 0, 45, 90, 135 }) do gparts[#gparts + 1] = part(15, 3, rot, C.white) end
    gparts[#gparts + 1] = part(9, 9, 0, C.white, true)
    local hole = part(4, 4, 0, Color3.fromRGB(14, 14, 16), true)
    local gscale = make("UIScale", { Scale = 1 }, icon)

    function ui.gearTheme(on)
        for _, p in ipairs(gparts) do p.BackgroundColor3 = on and GEAR_ORANGE or Color3.fromRGB(255, 255, 255) end
        hole.BackgroundColor3 = on and Color3.fromRGB(34, 12, 4) or Color3.fromRGB(14, 14, 16)
        gscale.Scale = 1
    end
    ui.gearBtn, ui.gear = btn, icon

    local batRoot = decor.root(ScreenGui, { Position = MainFrame.Position, Size = UDim2.new(0, 0, 0, 0), ZIndex = 20 })
    batRoot.ClipsDescendants = false

    decor.gearBuddy = ({ "Bat", "Skull", "Pumpkin" })[math.random(3)]
    if decor.gearBuddy == "Bat" then
        local tilt = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 19, 0, 17),
            Size = UDim2.new(0, 2, 0, 2), BackgroundTransparency = 1, Rotation = -22,
        }, batRoot)
        local shift = make("Frame", {
            Position = UDim2.new(0, 1, 0, -1), Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1,
        }, tilt)
        decor.bat(shift, 0)
    elseif decor.gearBuddy == "Skull" then
        decor.skullPeek(batRoot)
    else
        decor.gearPumpkin(batRoot)
    end

    local ov = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 19, 0, 17),
        Size = UDim2.new(0, 15, 0, 15), BackgroundTransparency = 1,
    }, batRoot)
    local function ovPart(w, h, rot, color, round)
        local f = make("Frame", {
            Size = UDim2.new(0, w, 0, h), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0), Rotation = rot,
            BackgroundColor3 = color, BorderSizePixel = 0,
        }, ov)
        if round then make("UICorner", { CornerRadius = UDim.new(1, 0) }, f) end
    end

    local gearCol, holeCol = GEAR_ORANGE, Color3.fromRGB(34, 12, 4)
    if decor.gearBuddy == "Pumpkin" then holeCol = Color3.fromRGB(236, 196, 24) end
    for _, rot in ipairs({ 0, 45, 90, 135 }) do ovPart(15, 3, rot, gearCol) end
    ovPart(9, 9, 0, gearCol, true)
    ovPart(4, 4, 0, holeCol, true)
    table.insert(conns, icon:GetPropertyChangedSignal("Rotation"):Connect(function()
        ov.Rotation = icon.Rotation
    end))
    table.insert(conns, MainFrame:GetPropertyChangedSignal("Position"):Connect(function()
        batRoot.Position = MainFrame.Position
    end))
end

local function applyTimerVisibility()
    TimerLabel.Visible = settings.showTimer
    if ui.sepTimer then ui.sepTimer.Visible = settings.showTimer and ui.minimized == true end
end
applyTimerVisibility()

local MiniWave = make("Frame", {
    Size = UDim2.new(0, 70, 1, -1),
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
    TextColor3 = C.hi,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, MiniWave)

do
    local TIERS = {
        { min = 48, outer = Color3.fromRGB(125, 75, 225),  inner = Color3.fromRGB(215, 185, 255) },
        { min = 24, outer = Color3.fromRGB(55, 155, 235),  inner = Color3.fromRGB(190, 238, 255) },
        { min = 14, outer = Color3.fromRGB(55, 175, 40),   inner = Color3.fromRGB(170, 255, 70) },
        { min = 9,  outer = Color3.fromRGB(240, 175, 20),  inner = Color3.fromRGB(255, 240, 120) },
        { min = 4,  outer = Color3.fromRGB(255, 115, 25),  inner = Color3.fromRGB(255, 185, 70) },
        { min = 1,  outer = Color3.fromRGB(185, 70, 35),   inner = Color3.fromRGB(245, 130, 50) },
        { min = 0,  outer = Color3.fromRGB(70, 70, 76),    inner = Color3.fromRGB(190, 190, 195) },
    }
    local OUTER = { {4,1}, {4,2}, {3,3}, {3,4}, {2,5}, {1,6}, {1,7}, {0,8}, {0,9}, {0,9}, {1,7}, {2,5} }
    local INNER = { [6] = {4,1}, [7] = {3,3}, [8] = {3,3}, [9] = {2,5}, [10] = {2,5}, [11] = {3,3}, [12] = {3,3} }

    local box = make("Frame", {
        Size = UDim2.new(0, 74, 1, -1),
        Position = UDim2.new(0, 192, 0, 0),
        BackgroundTransparency = 1,
        Visible = false,
    }, Header)
    make("Frame", {
        Size = UDim2.new(0, 1, 0, 20),
        Position = UDim2.new(0, -8, 0.5, -10),
        BackgroundColor3 = C.line,
        BorderSizePixel = 0,
    }, box)
    make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = "STREAK",
        TextColor3 = C.muted,
        TextSize = 8,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, box)

    local flame = make("Frame", {
        Size = UDim2.new(0, 9, 0, 12),
        Position = UDim2.new(0, 0, 0, 15),
        BackgroundTransparency = 1,
    }, box)
    local outerPx, innerPx = {}, {}
    for r, row in ipairs(OUTER) do
        outerPx[#outerPx + 1] = make("Frame", {
            Size = UDim2.new(0, row[2], 0, 1),
            Position = UDim2.new(0, row[1], 0, r - 1),
            BackgroundColor3 = TIERS[#TIERS].outer,
            BorderSizePixel = 0,
        }, flame)
    end
    for r, row in pairs(INNER) do
        innerPx[#innerPx + 1] = make("Frame", {
            Size = UDim2.new(0, row[2], 0, 1),
            Position = UDim2.new(0, row[1], 0, r - 1),
            BackgroundColor3 = TIERS[#TIERS].inner,
            BorderSizePixel = 0,
        }, flame)
    end

    local value = make("TextLabel", {
        Size = UDim2.new(1, -14, 0, 18),
        Position = UDim2.new(0, 14, 0, 12),
        BackgroundTransparency = 1,
        Text = "0",
        TextColor3 = C.muted,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, box)

    local sepTimer = make("Frame", {
        Size = UDim2.new(0, 1, 0, 20),
        Position = UDim2.new(0, 276, 0.5, -10),
        BackgroundColor3 = C.line,
        BorderSizePixel = 0,
        Visible = false,
    }, Header)

    local tierNow = nil
    function ui.setStreak(n)
        n = math.max(0, math.floor(tonumber(n) or 0))
        value.Text = tostring(n)
        value.TextColor3 = n > 0 and C.hi or C.muted
        local tier
        for _, t in ipairs(TIERS) do
            if n >= t.min then tier = t break end
        end
        if tier ~= tierNow then
            tierNow = tier
            for _, f in ipairs(outerPx) do f.BackgroundColor3 = tier.outer end
            for _, f in ipairs(innerPx) do f.BackgroundColor3 = tier.inner end
        end
    end
    ui.streakBox, ui.sepTimer = box, sepTimer
    function ui.showMini(mini)
        box.Visible = mini
        sepTimer.Visible = mini and settings.showTimer
    end
end

local MiniBarTrack = make("Frame", {
    Size = UDim2.new(1, 0, 0, 2),
    Position = UDim2.new(0, 0, 1, -3),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
    Visible = false,
}, Header)
local MiniBarFill = make("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = C.accent,
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

do
    local root = decor.root(Sidebar, { Size = UDim2.new(1, -1, 1, 0) })
    decor.web(root, 0, 0, 230, 0, 90, 8, 7, 0.82)
    decor.treeBox = decor.tree(root)
    decor.leafLayer = decor.particles(root)
    decor.fog(root)
end

local PageHolder = make("Frame", {
    Size = UDim2.new(1, -SIDEBAR_W, 1, 0),
    Position = UDim2.new(0, SIDEBAR_W, 0, 0),
    BackgroundTransparency = 1,
}, Body)
EVENT.parts = { sidebar = Sidebar, page = PageHolder }

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

local ListScroll = make("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = T(Color3.fromRGB(120, 120, 126), "gen"),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 3,
}, ListFrame)

ui.icons = {}
ui.TIER = {
    Basic     = { name = "Basic",     rank = 1, color = Color3.fromRGB(176, 176, 182) },
    Uncommon  = { name = "Uncommon",  rank = 2, color = Color3.fromRGB(110, 205, 125) },
    Rare      = { name = "Rare",      rank = 3, color = Color3.fromRGB(60, 215, 200) },
    Epic      = { name = "Epic",      rank = 4, color = Color3.fromRGB(240, 95, 185) },
    Legendary = { name = "Legendary", rank = 5, color = Color3.fromRGB(255, 200, 70) },
    Mythic    = { name = "Mythic",    rank = 6, color = Color3.fromRGB(255, 85, 95) },
    Exclusive = { name = "Exclusive", rank = 7, grad = true },
    Omega     = { name = "Omega",     rank = 8, grad = true },
}

ui.GRAD_BLUE = Color3.fromRGB(70, 150, 240)
ui.GRAD_VIOLET = Color3.fromRGB(150, 110, 235)
ui.tierGrads = setmetatable({}, { __mode = "k" })
runLoop(function()
    if next(ui.tierGrads) then
        local k = (math.sin(os.clock() * 0.9) + 1) / 2
        local a = ui.GRAD_BLUE:Lerp(ui.GRAD_VIOLET, k)
        local b = ui.GRAD_BLUE:Lerp(ui.GRAD_VIOLET, 1 - k)
        local seq = ColorSequence.new({
            ColorSequenceKeypoint.new(0, a),
            ColorSequenceKeypoint.new(0.5, a:Lerp(b, 0.5)),
            ColorSequenceKeypoint.new(1, b),
        })
        for g in pairs(ui.tierGrads) do
            if g.Parent then g.Color = seq else ui.tierGrads[g] = nil end
        end
    end
    return 0.05
end)

function ui.styleName(label, tier)
    local g = label:FindFirstChild("TierGrad")
    if tier and tier.grad then
        label.TextColor3 = Color3.new(1, 1, 1)
        if not g then
            g = make("UIGradient", {
                Name = "TierGrad",
                Color = ColorSequence.new(ui.GRAD_BLUE, ui.GRAD_VIOLET),
                Rotation = 0,
            }, label)
            ui.tierGrads[g] = true
        end
    else
        if g then g:Destroy() end
        if tier then label.TextColor3 = tier.color end
    end
end

function ui.iconFor(id)
    if ui.icons[id] then return ui.icons[id] end
    if ui._crates == nil then
        local ok, m = pcall(function()
            local mods = ReplicatedStorage:FindFirstChild("Modules")
            local c = mods and mods:FindFirstChild("Crates")
            return c and require(c)
        end)
        ui._crates = (ok and type(m) == "table" and type(m.Crates) == "table") and m.Crates or false
    end
    local d = ui._crates and ui._crates[id]
    if d and type(d.Icon) == "string" then
        ui.icons[id] = d.Icon
        return d.Icon
    end
    return nil
end

function ui.boostIcon(key)
    local ck = "boost:" .. tostring(key)
    if ui.icons[ck] then return ui.icons[ck] end

    if ui._boostCfg == nil then
        local ok, m = pcall(function()
            local mods = ReplicatedStorage:FindFirstChild("Modules")
            local c = mods and mods:FindFirstChild("BoostConfig")
            return c and require(c)
        end)
        ui._boostCfg = (ok and type(m) == "table") and m or false
    end
    local d = ui._boostCfg and ui._boostCfg[key]
    if type(d) == "table" and type(d.Icon) == "string" and d.Icon ~= "" then
        ui.icons[ck] = d.Icon
        return d.Icon
    end

    if ui._lucky == nil then
        local ok, m = pcall(function()
            local sh = ReplicatedStorage:FindFirstChild("Shared")
            local c = sh and sh:FindFirstChild("LuckyBlockConfig")
            return c and require(c)
        end)
        ui._lucky = (ok and type(m) == "table" and type(m.Rewards) == "table") and m.Rewards or false
    end
    if ui._lucky then
        for _, r in ipairs(ui._lucky) do
            if type(r) == "table" and r.Type == "Boost" and r.Id == key and type(r.Icon) == "string" then
                ui.icons[ck] = r.Icon
                return r.Icon
            end
        end
    end
    return nil
end

local MAX_VISIBLE = 6

local SearchBox = make("TextBox", {
    Size = UDim2.new(1, -8, 0, 24),
    Position = UDim2.new(0, 4, 0, 3),
    BackgroundColor3 = C.control,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Search",
    PlaceholderColor3 = C.dim,
    TextColor3 = C.text,
    TextSize = 11,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    Visible = false,
    ZIndex = 4,
}, ListFrame)
make("UIStroke", { Color = C.controlLine, Thickness = 1 }, SearchBox)
make("UIPadding", { PaddingLeft = UDim.new(0, 8) }, SearchBox)
local searchRender = nil
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    if searchRender then searchRender(SearchBox.Text) end
end)

local function openList(anchor, options, current, onPick, chev, extra)
    closeOverlay()
    local withSearch = extra and extra.search and true or false
    local anyIcon = false
    for _, o in ipairs(options) do
        if o.icon then anyIcon = true break end
    end

    local itemH = anyIcon and 34 or 26
    local topH = withSearch and 30 or 0
    local w = math.max(anchor.AbsoluteSize.X, 120)
    local mainPos, mainSize = MainFrame.AbsolutePosition, MainFrame.AbsoluteSize
    local aPos = anchor.AbsolutePosition
    local x = math.clamp(aPos.X - mainPos.X, 4, math.max(4, mainSize.X - w - 4))

    local below = aPos.Y - mainPos.Y + anchor.AbsoluteSize.Y + 2
    local roomBelow = mainSize.Y - 4 - below
    local roomAbove = (aPos.Y - mainPos.Y - 2) - HEADER_H
    local function rowsFor(room) return math.floor((room - topH - 4) / itemH) end
    local want = math.min(#options, MAX_VISIBLE)
    local goBelow = rowsFor(roomBelow) >= math.min(want, 3) or rowsFor(roomBelow) >= rowsFor(roomAbove)
    local shown = math.max(1, math.min(want, rowsFor(goBelow and roomBelow or roomAbove)))
    local long = #options > shown
    local h = topH + shown * itemH + 4
    local y = goBelow and below or (aPos.Y - mainPos.Y - h - 2)

    ListScroll.Position = UDim2.new(0, 0, 0, topH)
    ListScroll.Size = UDim2.new(1, 0, 0, shown * itemH + 4)
    searchRender = nil
    SearchBox.Text = ""
    SearchBox.Visible = withSearch

    local function render(q)
        for _, c in ipairs(ListScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        q = string.lower(q or "")
        local list = {}
        for _, o in ipairs(options) do
            if q == "" or string.find(string.lower(o.label), q, 1, true) then
                list[#list + 1] = o
            end
        end
        ListScroll.CanvasSize = UDim2.new(0, 0, 0, #list * itemH + 4)
        ListScroll.CanvasPosition = Vector2.new(0, 0)

        for i, o in ipairs(list) do
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
            local hasCount = type(o.count) == "number"
            local x0 = 10
            if o.icon then
                make("ImageLabel", {
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(0, 8, 0.5, -12),
                    BackgroundTransparency = 1,
                    Image = o.icon,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 5,
                }, b)
                x0 = 40
            end
            local rightPad = hasCount and 66 or 8
            local nameLbl = make("TextLabel", {
                Size = UDim2.new(1, -(x0 + rightPad), 1, 0),
                Position = UDim2.new(0, x0, 0, 0),
                BackgroundTransparency = 1,
                Text = o.label,
                TextColor3 = selected and C.hi or C.muted,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 5,
            }, b)
            if o.tier then ui.styleName(nameLbl, o.tier) end
            if hasCount then
                make("TextLabel", {
                    Size = UDim2.new(0, 58, 1, 0),
                    Position = UDim2.new(1, -64, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "\195\151" .. o.count,
                    TextColor3 = selected and C.hi or C.muted,
                    TextSize = 11,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 5,
                }, b)
            end
            if selected then
                make("Frame", {
                    Size = UDim2.new(0, 2, 1, 0),
                    BackgroundColor3 = C.accent,
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
    end
    render("")
    if withSearch then searchRender = render end

    ListFrame.Size = UDim2.new(0, w, 0, h)
    ListFrame.Position = UDim2.new(0, x, 0, y)
    Overlay.Visible = true
    ListFrame.Visible = true
    if chev then
        openChev = chev
        tween(chev, 0.12, { Rotation = 180 })
    end
end

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

local function createLockIcon(par, pos, k)
    k = k or 1
    local holder = make("Frame", {
        Size = UDim2.new(0, 10 * k, 0, 12 * k),
        Position = pos,
        BackgroundTransparency = 1,
        Visible = false,
    }, par)
    local function bar(x, y, w, h, color)
        make("Frame", {
            Size = UDim2.new(0, w * k, 0, h * k),
            Position = UDim2.new(0, x * k, 0, y * k),
            BackgroundColor3 = color or C.dim,
            BorderSizePixel = 0,
        }, holder)
    end
    bar(1, 0, 8, 2)
    bar(1, 0, 2, 6)
    bar(7, 0, 2, 6)
    bar(0, 5, 10, 7)
    bar(4, 7, 2, 3, C.control)
    return holder
end

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
        BackgroundColor3 = T(Color3.fromRGB(34, 34, 37), "bg"),
        BorderSizePixel = 0,
    }, card)
    local trackStroke = make("UIStroke", {
        Color = C.controlLine,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, track)

    local lockIcon = createLockIcon(card, UDim2.new(1, -36, 0, 11))

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
            tc, kc = T(Color3.fromRGB(28, 28, 30), "bg"), T(Color3.fromRGB(64, 64, 68), "bg")
        elseif state then
            tc, kc = T(Color3.fromRGB(232, 232, 234), "bg"), T(Color3.fromRGB(14, 14, 15), "bg")
        else
            tc, kc = T(Color3.fromRGB(34, 34, 37), "bg"), C.muted
        end
        local kp = state and POS_ON or POS_OFF
        local sc = (state and not locked) and tc or C.controlLine

        titleLabel.TextColor3 = locked and C.dim or C.text
        titleLabel.Text = title
        track.Visible = not locked
        lockIcon.Visible = locked

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
            BackgroundColor3 = T(Color3.fromRGB(226, 226, 228), "bg"),
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

local function createSlider(par, props, cfg, onChange)
    local minV, maxV, step = cfg.min, cfg.max, cfg.step
    local n = math.floor((maxV - minV) / step + 0.5) + 1
    local function fmt(v) return string.format("%g", v) .. "x" end
    local function snap(v)
        return minV + math.clamp(math.floor((v - minV) / step + 0.5), 0, n - 1) * step
    end

    local frame = make("Frame", {
        BackgroundColor3 = C.control,
        BorderSizePixel = 0,
    }, par)
    for k, v in pairs(props) do frame[k] = v end
    styleControl(frame)

    -- area garis; kotak penarik berbentuk persegi 14x14; semua bagian diletakkan pada piksel bulat supaya kotak, garis, dan tanda
    -- selalu persis di tengah satu sama lain (tidak ada setengah piksel yang bikin miring)
    local area = make("Frame", {
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -66, 1, 0),
        BackgroundTransparency = 1,
    }, frame)
    -- garis lurus tanpa tanda: bingkai tipis berisi alur gelap, dan warna tema mengisi bagian
    -- dalam alur dari kiri sampai ke kotak penarik, jadi warnanya otomatis menyatu dengan kotak
    local line = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 6),
        BackgroundColor3 = C.controlLine,
        BorderSizePixel = 0,
    }, area)
    make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 1, 0.5, 0),
        Size = UDim2.new(1, -2, 0, 4),
        BackgroundColor3 = C.control,
        BorderSizePixel = 0,
    }, area)
    local fill = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 1, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 4),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
    }, area)
    local thumb = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = T(Color3.fromRGB(226, 226, 228), "bg"),
        BorderSizePixel = 0,
    }, area)
    -- titik persegi kecil di tengah kotak
    make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 4, 0, 4),
        BackgroundColor3 = C.ink,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
    }, thumb)
    local label = make("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 0),
        Size = UDim2.new(0, 40, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, frame)

    local current = snap(cfg.initial or minV)
    local committed = current

    local function areaW()
        local w = area.AbsoluteSize.X
        if w <= 0 and props.Size then w = props.Size.X.Offset - 66 end
        return math.max(1, w)
    end
    local function px(frac) return math.floor(frac * areaW() + 0.5) end

    local function layout(animate)
        local frac = (current - minV) / (maxV - minV)
        label.Text = fmt(current)
        local x = px(frac)
        local fw = math.max(0, x - 1)
        if animate then
            tween(thumb, 0.06, { Position = UDim2.new(0, x, 0.5, 0) })
            tween(fill, 0.06, { Size = UDim2.new(0, fw, 0, 4) })
        else
            thumb.Position = UDim2.new(0, x, 0.5, 0)
            fill.Size = UDim2.new(0, fw, 0, 4)
        end
    end
    layout(false)
    area:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() layout(false) end)

    -- area sentuh: sedikit lebih lebar dari garis supaya ujung-ujungnya mudah dipegang
    local hit = make("TextButton", {
        Position = UDim2.new(0, 6, 0, 0),
        Size = UDim2.new(1, -50, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, frame)

    local dragging, activeInput, scroller = false, nil, nil
    local function setFromX(x)
        local v = snap(minV + math.clamp((x - area.AbsolutePosition.X) / areaW(), 0, 1) * (maxV - minV))
        if v ~= current then
            current = v
            layout(true)
        end
    end
    local function release()
        if not dragging then return end
        dragging, activeInput = false, nil
        if scroller then scroller.ScrollingEnabled = true; scroller = nil end
        if current ~= committed then
            committed = current
            if onChange then onChange(current) end
        end
    end

    hit.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
        dragging, activeInput = true, input
        scroller = frame:FindFirstAncestorWhichIsA("ScrollingFrame")
        if scroller then scroller.ScrollingEnabled = false end
        setFromX(input.Position.X)
    end)
    table.insert(conns, UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
        if t == Enum.UserInputType.Touch and input ~= activeInput then return end
        setFromX(input.Position.X)
    end))
    table.insert(conns, UserInputService.InputEnded:Connect(function(input)
        if not dragging then return end
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or (t == Enum.UserInputType.Touch and input == activeInput) then
            release()
        end
    end))

    return {
        get = function() return current end,
        set = function(v)
            current = snap(v); committed = current
            layout(false)
        end,
    }
end

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
    local ico = make("ImageLabel", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, 8, 0.5, -10),
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
        Visible = false,
    }, btn)

    local cnt
    if cfg.countOf then
        lbl.Size = UDim2.new(1, -96, 1, 0)
        cnt = make("TextLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -26, 0, 0),
            Size = UDim2.new(0, 62, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = C.text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Right,
        }, btn)
    end

    local baseW = cfg.countOf and -96 or -30
    local function refresh()
        if cnt then
            local n = (current and current ~= "") and cfg.countOf(current) or nil
            cnt.Text = type(n) == "number" and ("\195\151" .. n) or ""
        end
        local text
        if cfg.getOptions then
            if current and current ~= "" then
                text = cfg.labelOf and cfg.labelOf(current) or tostring(current)
            end
        else
            for _, o in ipairs(options) do
                if o.value == current then text = o.label break end
            end
        end
        local icon = (cfg.iconOf and text and current and current ~= "") and cfg.iconOf(current) or nil
        if icon then
            if ico.Image ~= icon then ico.Image = icon end
            ico.Visible = true
            lbl.Position = UDim2.new(0, 36, 0, 0)
            lbl.Size = UDim2.new(1, baseW - 27, 1, 0)
        else
            ico.Visible = false
            lbl.Position = UDim2.new(0, 9, 0, 0)
            lbl.Size = UDim2.new(1, baseW, 1, 0)
        end
        if text then
            lbl.Text = (cfg.prefix or "") .. text
            lbl.TextColor3 = C.text
            ui.styleName(lbl, cfg.tierOf and cfg.tierOf(current) or nil)
        else
            lbl.Text = cfg.placeholder or "Select"
            lbl.TextColor3 = C.muted
            ui.styleName(lbl, nil)
        end
    end

    btn.MouseButton1Click:Connect(function()
        if cfg.getOptions then
            options = cfg.getOptions()
            if #options == 0 then
                return
            end
        end
        openList(btn, options, current, function(v)
            current = v
            refresh()
            if cfg.onChange then cfg.onChange(v) end
        end, chev, { search = cfg.search })
    end)

    refresh()
    if cnt then
        runLoop(function()
            refresh()
            return 1.5
        end)
    end
    return {
        get = function() return current end,
        set = function(v) current = v; refresh() end,
    }
end

local function createCollapse(par, props, title, count, isOpen, onToggle)
    local btn = make("TextButton", {
        BackgroundColor3 = C.control,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, par)
    for k, v in pairs(props) do btn[k] = v end
    styleControl(btn)
    make("TextLabel", {
        Size = UDim2.new(1, -62, 1, 0),
        Position = UDim2.new(0, 9, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, btn)
    make("TextLabel", {
        Size = UDim2.new(0, 36, 1, 0),
        Position = UDim2.new(1, -50, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(count),
        TextColor3 = C.dim,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, btn)
    local chev = createChevron(btn, -9)
    chev.Rotation = isOpen and 180 or 0
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.hover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.control end)
    btn.MouseButton1Click:Connect(function() onToggle(not isOpen) end)
    return btn
end

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

    local grad = make("UIGradient", {
        Color = ColorSequence.new(T(Color3.fromRGB(240, 240, 242), "gen"), T(Color3.fromRGB(160, 160, 166), "gen")),
        Rotation = 0,
        Offset = Vector2.new(-0.25, 0),
        Enabled = false,
    }, btn)
    local slide = TweenService:Create(grad,
        TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Offset = Vector2.new(0.25, 0) })

    local function refresh(animate)
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            grad.Enabled = true
            slide:Play()
        else
            slide:Cancel()
            grad.Enabled = false
            grad.Offset = Vector2.new(-0.25, 0)
            btn.BackgroundColor3 = C.control
        end
        local tc = state and C.ink or C.muted
        if animate then tween(btn, 0.15, { TextColor3 = tc }) else btn.TextColor3 = tc end
    end

    btn.MouseButton1Down:Connect(function()
        tween(btn, 0.06, { Size = UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset - 2, btn.Size.Y.Scale, btn.Size.Y.Offset - 2) })
    end)
    local baseSize = btn.Size
    local function release() tween(btn, 0.12, { Size = baseSize }) end
    btn.MouseButton1Up:Connect(release)
    btn.MouseLeave:Connect(release)

    btn.MouseButton1Click:Connect(function()
        state = not state
        refresh(true)
        if onChange then onChange(state) end
    end)

    refresh(false)
    return {
        get = function() return state end,
        set = function(v) state = v and true or false; refresh(true) end,
    }
end

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
        btn.BackgroundColor3 = T(Color3.fromRGB(96, 96, 102), "bg")
        tween(btn, 0.25, { BackgroundColor3 = C.control })
        if onClick then onClick() end
    end)
    return btn
end

local function createFxButton(par, props, text, onClick, c1, c2, reentrant)
    c1 = c1 or Color3.fromRGB(70, 150, 240)
    c2 = c2 or Color3.fromRGB(150, 110, 235)
    local btn = make("TextButton", {
        BackgroundColor3 = C.control,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        ClipsDescendants = true,
    }, par)
    for k, v in pairs(props) do btn[k] = v end
    styleControl(btn)

    local fx = make("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.white,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = false,
    }, btn)
    local grad = make("UIGradient", {
        Color = ColorSequence.new(c1, c2),
        Rotation = 0,
        Offset = Vector2.new(-0.35, 0),
    }, fx)
    local slide = TweenService:Create(grad,
        TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Offset = Vector2.new(0.35, 0) })

    local busy = false
    local active = 0
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.hover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.control end)
    btn.MouseButton1Down:Connect(function()
        tween(fx, 0.05, { BackgroundTransparency = 0.3 })
    end)
    btn.MouseButton1Click:Connect(function()
        if busy and not reentrant then return end
        busy = true
        active = active + 1
        fx.BackgroundTransparency = 0.2
        if active == 1 then slide:Play() end
        task.spawn(function()
            local ok, err = pcall(onClick or function() end)
            if not ok then warn("[LightHub] " .. tostring(err)) end
            active = active - 1
            if active <= 0 then
                active, busy = 0, false
                slide:Cancel()
                pcall(function()
                    grad.Offset = Vector2.new(-0.35, 0)
                    tween(fx, 0.45, { BackgroundTransparency = 1 })
                end)
            end
        end)
    end)
    return btn
end

local function createMiniSwitch(par, props, initial, onChange)
    local track = make("Frame", {
        Size = UDim2.new(0, 34, 0, 16),
        BackgroundColor3 = T(Color3.fromRGB(34, 34, 37), "bg"),
        BorderSizePixel = 0,
    }, par)
    for k, v in pairs(props) do track[k] = v end
    local stroke = make("UIStroke", {
        Color = C.controlLine, Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, track)
    local knob = make("Frame", {
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 3, 0.5, -5),
        BackgroundColor3 = C.muted,
        BorderSizePixel = 0,
    }, track)
    local hit = make("TextButton", {
        Size = UDim2.new(1, 12, 1, 12),
        Position = UDim2.new(0, -6, 0, -6),
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2,
    }, track)
    local api = { state = false }
    function api.set(v, animate)
        api.state = v and true or false
        local tc = api.state and T(Color3.fromRGB(232, 232, 234), "bg") or T(Color3.fromRGB(34, 34, 37), "bg")
        local kc = api.state and T(Color3.fromRGB(14, 14, 15), "bg") or C.muted
        local sc = api.state and tc or C.controlLine
        local kp = api.state and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
        if animate then
            tween(track, 0.12, { BackgroundColor3 = tc })
            tween(stroke, 0.12, { Color = sc })
            tween(knob, 0.12, { BackgroundColor3 = kc, Position = kp })
        else
            track.BackgroundColor3, stroke.Color = tc, sc
            knob.BackgroundColor3, knob.Position = kc, kp
        end
    end
    hit.MouseButton1Click:Connect(function()
        local nv = not api.state
        api.set(nv, true)
        if onChange then onChange(nv) end
    end)
    api.set(initial, false)
    return api
end

local function createFloat(title, startPos)
    local W = 150
    local f = make("Frame", {
        Size = UDim2.new(0, W, 0, 60),
        Position = startPos,
        BackgroundColor3 = C.white,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Active = true,
        Visible = false,
        ZIndex = 5,
    }, ScreenGui)
    swing(f, Color3.fromRGB(24, 24, 27), Color3.fromRGB(46, 46, 50), 90, 38, 0.2, 2.1)
    make("UIStroke", { Color = C.line, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)

    local bar = make("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Active = true,
    }, f)
    make("TextLabel", {
        Size = UDim2.new(1, -36, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, bar)
    local close = make("TextButton", {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -27, 0, 2),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = C.muted,
        TextSize = 16,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
    }, f)
    close.MouseEnter:Connect(function() close.TextColor3 = C.hi end)
    close.MouseLeave:Connect(function() close.TextColor3 = C.muted end)
    close.MouseButton1Click:Connect(function() f.Visible = false end)
    make("Frame", {
        Size = UDim2.new(1, -16, 0, 1),
        Position = UDim2.new(0, 8, 0, 28),
        BackgroundColor3 = C.line,
        BorderSizePixel = 0,
    }, f)
    local body = make("Frame", {
        Size = UDim2.new(1, -16, 0, 0),
        Position = UDim2.new(0, 8, 0, 34),
        BackgroundTransparency = 1,
    }, f)

    local dragging, dragStart, startAbs = false, nil, nil
    bar.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startAbs = f.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    table.insert(conns, UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            f.Position = UDim2.new(startAbs.X.Scale, startAbs.X.Offset + d.X,
                startAbs.Y.Scale, startAbs.Y.Offset + d.Y)
        end
    end))

    ui.watch(f)
    f.DescendantAdded:Connect(ui.watch)
    for _, d in ipairs(f:GetDescendants()) do ui.watch(d) end

    local api = { frame = f }
    function api.setItems(items)
        for _, c in ipairs(body:GetChildren()) do c:Destroy() end
        local h
        if #items == 0 then
            make("TextLabel", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                Text = "Nothing saved yet",
                TextColor3 = C.dim,
                TextSize = 10,
                Font = Enum.Font.GothamMedium,
            }, body)
            h = 22
        else
            for i, it in ipairs(items) do
                createFxButton(body, {
                    Size = UDim2.new(1, 0, 0, 26),
                    Position = UDim2.new(0, 0, 0, (i - 1) * 30),
                }, it.text, it.fn, it.c1, it.c2, true)
            end
            h = #items * 30 - 4
        end
        body.Size = UDim2.new(1, -16, 0, h)
        f.Size = UDim2.new(0, W, 0, 34 + h + 8)
    end
    function api.toggle() f.Visible = not f.Visible end
    return api
end

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

local function visualFeature(par, title, key, bodyHeight, build, soon)
    local f = createFeature(par, title, {
        initial = flags[key],
        bodyHeight = bodyHeight,
        onToggle = function(v) setFlag(key, v) end,
    })
    if build and f.body then build(f.body) end
    return f
end

local tabs = {}
local TOPBAR_H = 30
local nav = {
    groups = {
        { name = "Main", pages = { { "Main", "Main" } } },
        { name = "Items", pages = { { "Gacha", "Gacha" }, { "Inventory", "Inventory" } } },
        { name = "Macro", pages = { { "Macro", "Macro" }, { "Share", "Sharing" } } },
        { name = "Endless", pages = { { "Endless", "Endless" } } },
        { name = "Rewards", pages = { { "AFK", "Rewards" } } },
    },
    settings = { name = "Settings", pages = { { "Settings", "Settings" }, { "Profile", "Profile" } } },
    byPage = {}, top = {}, cur = nil, lastMain = "Main", lastSettings = "Settings",
}

nav.bar = make("Frame", {
    Size = UDim2.new(1, 0, 0, TOPBAR_H),
    BackgroundTransparency = 1,
    Visible = false,
}, PageHolder)
make("Frame", {
    Size = UDim2.new(1, -16, 0, 1),
    Position = UDim2.new(0, 8, 1, -1),
    BackgroundColor3 = C.line,
    BorderSizePixel = 0,
}, nav.bar)

nav.ind = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 1),
    Size = UDim2.new(0.5, 0, 0, 2),
    Position = UDim2.new(0.25, 0, 1, 0),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
}, nav.bar)
function nav.place(i, count, animate)
    nav.ind.Size = UDim2.new(0.5 / count, 0, 0, 2)
    local pos = UDim2.new((i - 0.5) / count, 0, 1, 0)
    if animate then tween(nav.ind, 0.15, { Position = pos }) else nav.ind.Position = pos end
end

local function selectTab(name)
    closeOverlay()
    local g = nav.byPage[name]
    if not g then return end
    nav.cur = name
    g.last = name
    local isSettings = (g == nav.settings)
    if isSettings then nav.lastSettings = name else nav.lastMain = name end

    for _, grp in ipairs(nav.groups) do
        grp.label.TextColor3 = (grp == g) and C.hi or C.muted
    end

    if g == nav.settings then
        nav.sel.Visible = false
    else
        nav.sel.Visible = true
        if nav.selReady then
            tween(nav.sel, 0.18, { Position = UDim2.new(0, 0, 0, g.y) })
        else
            nav.sel.Position = UDim2.new(0, 0, 0, g.y)
            nav.selReady = true
        end
    end

    local multi = #g.pages > 1
    for n, t in pairs(tabs) do
        t.page.Visible = (n == name)
        t.page.Position = UDim2.new(0, 0, 0, multi and TOPBAR_H or 0)
        t.page.Size = UDim2.new(1, 0, 1, multi and -TOPBAR_H or 0)
    end

    nav.bar.Visible = multi
    for _, tb in pairs(nav.top) do tb.btn.Visible = false end
    if multi then
        local count = #g.pages
        for i, pg in ipairs(g.pages) do
            local tb = nav.top[pg[1]]
            local on = (pg[1] == name)
            tb.btn.Visible = true
            tb.btn.Size = UDim2.new(1 / count, 0, 1, 0)
            tb.btn.Position = UDim2.new((i - 1) / count, 0, 0, 0)
            tb.label.TextColor3 = on and C.hi or C.muted
            if on then
                nav.place(i, count, nav.indReady)
                nav.indReady = true
            end
        end
    end

    if ui.gear then tween(ui.gear, 0.2, { Rotation = isSettings and 45 or 0 }) end
end

local function addPage(name, grp)
    nav.byPage[name] = grp
    local page = make("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T(Color3.fromRGB(120, 120, 126), "gen"),
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
    tabs[name] = { page = page }
end

local function addTopButton(pg)
    local btn = make("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Visible = false,
    }, nav.bar)
    local label = make("TextLabel", {
        Size = UDim2.new(1, 0, 1, -1),
        BackgroundTransparency = 1,
        Text = pg[2],
        TextColor3 = C.muted,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
    }, btn)
    nav.top[pg[1]] = { btn = btn, label = label }
    btn.MouseButton1Click:Connect(function()
        if nav.suppress and os.clock() - nav.suppress < 0.25 then return end
        selectTab(pg[1])
    end)
    btn.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            nav.dragging = { x0 = input.Position.X, moved = false }
        end
    end)
end

for _, grp in ipairs(nav.groups) do
    for _, pg in ipairs(grp.pages) do addPage(pg[1], grp) end
end
for _, pg in ipairs(nav.settings.pages) do addPage(pg[1], nav.settings) end
for _, grp in ipairs({ nav.groups[2], nav.groups[3], nav.settings }) do
    for _, pg in ipairs(grp.pages) do addTopButton(pg) end
end

nav.sel = make("Frame", {
    Size = UDim2.new(1, -1, 0, 30),
    Position = UDim2.new(0, 0, 0, 8),
    BackgroundColor3 = C.white,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    Visible = false,
}, Sidebar)
swing(nav.sel, Color3.fromRGB(34, 34, 38), Color3.fromRGB(66, 66, 72), 0, 30, 0.22, 1)
make("UIStroke", { Color = C.controlLine, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, nav.sel)
make("Frame", {
    Size = UDim2.new(0, 3, 1, 0),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
}, nav.sel)

do
    local function slotAt(x)
        local g = nav.byPage[nav.cur]
        if not g or #g.pages < 2 then return nil end
        local bx, bw = nav.bar.AbsolutePosition.X, math.max(1, nav.bar.AbsoluteSize.X)
        return math.clamp(math.floor((x - bx) / bw * #g.pages) + 1, 1, #g.pages), g
    end
    table.insert(conns, UserInputService.InputChanged:Connect(function(input)
        local d = nav.dragging
        if not d then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
        local x = input.Position.X
        if not d.moved and math.abs(x - d.x0) > 8 then d.moved = true end
        if d.moved then
            local i, g = slotAt(x)
            if i then
                d.slot = i
                nav.place(i, #g.pages, true)
            end
        end
    end))
    table.insert(conns, UserInputService.InputEnded:Connect(function(input)
        local d = nav.dragging
        if not d then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
        nav.dragging = nil
        if d.moved and d.slot then
            local g = nav.byPage[nav.cur]
            nav.suppress = os.clock()
            if g then selectTab(g.pages[d.slot][1]) end
        end
    end))
end

for i, grp in ipairs(nav.groups) do
    grp.y = 8 + (i - 1) * 32
    local item = make("TextButton", {
        Size = UDim2.new(1, -1, 0, 30),
        Position = UDim2.new(0, 0, 0, 8 + (i - 1) * 32),
        BackgroundColor3 = C.white,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, Sidebar)

    grp.label = make("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text = grp.name,
        TextColor3 = C.muted,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, item)
    grp.item = item

    item.MouseButton1Click:Connect(function() selectTab(grp.last or grp.pages[1][1]) end)
end

local statLabels = {}
local stats = { sells = 0, upgrades = 0 }
local waveNow = { cur = nil, max = nil }

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

    local HISTORY_FILE = FS.data("History")
    local HISTORY_MAX = 15
    local history = {}
    if canFile then
        pcall(function()
            if isfile(HISTORY_FILE) then
                local d = HttpService:JSONDecode(readfile(HISTORY_FILE))
                if type(d) == "table" then
                    for _, e in ipairs(d) do
                        if #history >= HISTORY_MAX then break end
                        if type(e) == "table" and type(e.win) == "boolean" then
                            history[#history + 1] = {
                                win = e.win,
                                wave = tostring(e.wave or "?/?"),
                                time = tostring(e.time or ""),
                            }
                        end
                    end
                end
            end
        end)
    end

    local histOpen = false
    local histCard = createCard(page, 34)
    histCard.ClipsDescendants = true
    local histHead = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, histCard)
    make("TextLabel", {
        Size = UDim2.new(0, 110, 0, 34),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "Win / Lose",
        TextColor3 = C.text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, histHead)
    local histSummary = make("TextLabel", {
        Size = UDim2.new(1, -150, 0, 34),
        Position = UDim2.new(0, 124, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.muted,
        TextSize = 10,
        Font = Enum.Font.RobotoMono,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, histHead)
    local histArrow = createChevron(histHead, -14)
    local histRows = make("Frame", {
        Size = UDim2.new(1, -24, 0, 24),
        Position = UDim2.new(0, 12, 0, 34),
        BackgroundTransparency = 1,
        Visible = false,
    }, histCard)

    local function renderHistory()
        local w, l = 0, 0
        for _, e in ipairs(history) do
            if e.win then w = w + 1 else l = l + 1 end
        end
        histSummary.Text = #history > 0 and (w .. "W  " .. l .. "L") or ""

        for _, c in ipairs(histRows:GetChildren()) do c:Destroy() end
        if #history == 0 then
            make("TextLabel", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                Text = "No matches yet",
                TextColor3 = C.dim,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, histRows)
        end
        for i, e in ipairs(history) do
            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 22),
                Position = UDim2.new(0, 0, 0, (i - 1) * 24),
                BackgroundColor3 = T(Color3.fromRGB(24, 24, 27), "bg"),
                BorderSizePixel = 0,
            }, histRows)
            make("TextLabel", {
                Size = UDim2.new(0.3, -8, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text = e.win and "Win" or "Lose",
                TextColor3 = e.win and C.hi or C.muted,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, row)
            make("TextLabel", {
                Size = UDim2.new(0.3, 0, 1, 0),
                Position = UDim2.new(0.3, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = e.wave,
                TextColor3 = C.text,
                TextSize = 11,
                Font = Enum.Font.RobotoMono,
            }, row)
            make("TextLabel", {
                Size = UDim2.new(0.4, -8, 1, 0),
                Position = UDim2.new(0.6, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = e.time,
                TextColor3 = C.muted,
                TextSize = 11,
                Font = Enum.Font.RobotoMono,
                TextXAlignment = Enum.TextXAlignment.Right,
            }, row)
        end

        histArrow.Rotation = histOpen and 180 or 0
        histRows.Visible = histOpen
        if histOpen then
            local h = math.max(1, #history) * 24
            histRows.Size = UDim2.new(1, -24, 0, h)
            histCard.Size = UDim2.new(1, 0, 0, 34 + h + 8)
        else
            histCard.Size = UDim2.new(1, 0, 0, 34)
        end
    end
    histHead.MouseButton1Click:Connect(function()
        histOpen = not histOpen
        renderHistory()
    end)
    renderHistory()

    local function streakNow() return tonumber(LocalPlayer:GetAttribute("WinStreak")) or 0 end
    local lastWave = { cur = nil, max = nil }
    local streakStart, armed, ended, keyVerdict, lastRecord = streakNow(), false, false, nil, 0

    local WIN_WORDS = { "victory", "you win", "mission complete", "stage clear" }
    local LOSE_WORDS = { "defeat", "you lose", "game over", "mission failed" }
    local function hasAny(txt, list)
        for _, w in ipairs(list) do
            if string.find(txt, w, 1, true) then return true end
        end
        return false
    end

    local function scanEnd()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then return false, nil end
        local hasR, hasL, verdict = false, false, nil
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("TextButton") or d:IsA("TextLabel") or d:IsA("ImageButton") then
                local txt = d:IsA("ImageButton") and "" or string.lower(d.Text)
                local nm = string.lower(d.Name)
                local r = string.find(txt, "replay", 1, true) or string.find(nm, "replay", 1, true)
                local l = string.find(txt, "lobby", 1, true) or string.find(nm, "lobby", 1, true)
                local v = nil
                if txt ~= "" then
                    if hasAny(txt, WIN_WORDS) then v = "win"
                    elseif hasAny(txt, LOSE_WORDS) then v = "lose" end
                end
                if (r or l or v) and isShown(d) then
                    if r then hasR = true end
                    if l then hasL = true end
                    verdict = verdict or v
                end
            end
        end
        return hasR and hasL, verdict
    end

    local function recordMatch()
        if os.clock() - lastRecord < 10 then return end
        lastRecord = os.clock()
        local s = streakNow()
        local win
        if s > streakStart then
            win = true
        elseif s < streakStart then
            win = false
        elseif keyVerdict then
            win = (keyVerdict == "win")
        elseif lastWave.cur and lastWave.max and lastWave.max > 0 then
            win = lastWave.cur >= lastWave.max
        else
            win = false
        end
        table.insert(history, 1, {
            win = win,
            wave = (lastWave.cur and tostring(lastWave.cur) or "?") .. "/" .. (lastWave.max and tostring(lastWave.max) or "?"),
            time = TimerLabel.Text,
        })
        lastWave.last, lastWave.seq = win, (lastWave.seq or 0) + 1
        while #history > HISTORY_MAX do table.remove(history) end
        if canFile then
            pcall(function() writefile(HISTORY_FILE, HttpService:JSONEncode(history)) end)
        end
        renderHistory()
    end

    if inMatch then
        runLoop(function()
            if not ended and waveNow.cur then
                if not armed then
                    armed = true
                    streakStart = streakNow()
                    lastWave.cur, lastWave.max = nil, nil
                end
                lastWave.cur = waveNow.cur
                lastWave.max = waveNow.max or lastWave.max
            end
            local isEnd, v = scanEnd()
            if isEnd and not ended then
                ended = true
                keyVerdict = v
                task.delay(1.5, recordMatch)
            elseif isEnd then
                keyVerdict = keyVerdict or v
            elseif ended then
                ended, armed, keyVerdict = false, false, nil
            end
            return 1.5
        end)
    end

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

    local fPlay = visualFeature(page, "Auto Play", "autoPlay", 28, function(body)
        createSelect(body, {
            Size = UDim2.new(0.62, -4, 1, 0),
        }, {
            options = MAP_OPTIONS,
            initial = flags.playMap,
            placeholder = "Select a map",
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

    local function normName(x)
        return (string.lower(tostring(x)):gsub("[%s_%-]", ""))
    end
    local serverNames, serverNamesAt = {}, 0
    local function refreshServerNames()
        if os.clock() - serverNamesAt < 30 and #serverNames > 0 then return end
        serverNamesAt = os.clock()
        local rf = knitRF("MatchmakingService", "GetMapQueueCounts")
        if not rf then return end
        local ok, res = pcall(function() return rf:InvokeServer(flags.playPlayers) end)
        if not ok or type(res) ~= "table" then return end
        local found, seen = {}, {}
        local function add(n)
            if type(n) == "string" and n ~= "" and not seen[n] then
                seen[n] = true
                found[#found + 1] = n
            end
        end
        local src = type(res.Counts) == "table" and res.Counts or res
        for k, v in pairs(src) do
            if type(k) == "string" then add(k) end
            if type(v) == "string" then add(v) end
            if type(v) == "table" then
                add(v.Name); add(v.name); add(v.Map); add(v.map); add(v.MapName)
            end
        end
        if #found > 0 then serverNames = found end
    end

    local workingName = {}
    local function mapCandidates(value)
        local list, seen = {}, {}
        local function add(n)
            if n and n ~= "" and not seen[n] then seen[n] = true; list[#list + 1] = n end
        end
        add(workingName[value])
        pcall(refreshServerNames)
        local target = normName(value)
        for _, n in ipairs(serverNames) do
            if normName(n) == target then add(n) end
        end
        add(value)
        add((value:gsub("(%l)(%u)", "%1 %2")))
        add((value:gsub("%s+", "")))
        return list
    end

    local lastJoin = 0
    runLoop(function()
        if not flags.autoPlay then
            fPlay.setNote("")
            lastJoin = 0
            return 0.5
        end
        if not inLobby then
            fPlay.setNote("")
            return 2
        end
        if flags.playMap == "" then
            fPlay.setNote("Select a map", C.warn)
            return 1
        end
        local remote = knitRF("MatchmakingService", "JoinQueue")
        if not remote then
            fPlay.setNote("")
            return 1
        end

        if os.clock() - lastJoin < 25 then
            fPlay.setNote("Joining", C.text)
            return 1
        end
        lastJoin = os.clock()
        local value = flags.playMap
        local joined = false
        for _, name in ipairs(mapCandidates(value)) do
            local ok, res = pcall(function()
                return remote:InvokeServer(name, flags.playPlayers)
            end)
            if ok and res ~= false and not (type(res) == "table" and res.Ok == false) then
                workingName[value] = name
                joined = true
                break
            end
            task.wait(0.3)
        end
        if joined then
            fPlay.fails = 0
            fPlay.setNote("Joining", C.text)
        else
            fPlay.fails = (fPlay.fails or 0) + 1
            if fPlay.fails == 5 then
                notify("Auto Play", "Couldn't join the map. Check the map and party size.", 5)
            end
            fPlay.setNote("Join failed, retrying", C.warn)
            lastJoin = os.clock() - 20
        end
        return 1
    end)

    local fSpeed
    local function sendSpeed()
        local ev = RE("SetGameSpeed")
        if not ev then return false end
        return pcall(function() ev:FireServer(flags.speedValue) end)
    end

    fSpeed = visualFeature(page, "Auto Set Speed", "autoSpeed", 28, function(body)
        createSlider(body, {
            Size = UDim2.new(0, 240, 1, 0),
        }, { min = SPEED_MIN, max = SPEED_MAX, step = SPEED_STEP, initial = flags.speedValue }, function(v)
            setFlag("speedValue", v)
            if flags.autoSpeed then sendSpeed() end
        end)
    end)

    runLoop(function()
        if not flags.autoSpeed then
            fSpeed.setNote("")
            return 0.5
        end
        if not RE("SetGameSpeed") then
            fSpeed.setNote("")
            return 1.5
        end
        if sendSpeed() then
            fSpeed.setNote("")
        else
            fSpeed.setNote("Speed change failed", C.warn)
        end
        return 4
    end)

    local fMode = visualFeature(page, "Auto Select Mode", "autoMode", 28, function(body)
        createSelect(body, {
            Size = UDim2.new(1, 0, 1, 0),
        }, {
            options = MODE_OPTIONS,
            initial = flags.modeValue,
            placeholder = "Select a mode",
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
            fMode.setNote("")
            votedMode = nil
            return 2
        end
        local mode = flags.modeValue
        if mode == "" then
            fMode.setNote("Select a mode", C.warn)
            return 1
        end
        local folder = ReplicatedStorage:FindFirstChild("ModeVote")
        local ev = folder and folder:FindFirstChild("Vote")
        if not ev then
            fMode.setNote("")
            votedMode = nil
            return 1.5
        end
        if votedMode == mode then
            fMode.setNote("Voted " .. mode, C.text)
            return 1.5
        end
        task.wait(0.8)
        if not flags.autoMode or flags.modeValue ~= mode then return 0.5 end
        local ok = pcall(function() ev:FireServer(mode) end)
        if ok then
            votedMode = mode
            fMode.setNote("Voted " .. mode, C.text)
        else
            fMode.setNote("Vote failed", C.warn)
        end
        return 1.5
    end)

    do
        local o = fPlay.card.LayoutOrder
        fMode.card.LayoutOrder = o
        fPlay.card.LayoutOrder = o + 1
        fSpeed.card.LayoutOrder = o + 2
    end

    local fSkip = visualFeature(page, "Auto Skip Wave", "autoSkip", 0)

    local function findSkipButton(anyState)
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then return nil end
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("GuiButton") and (anyState or isShown(d)) then
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

    local skipState = { pressed = false, lastWave = nil, waveAt = 0, lastFire = 0, fires = 0, blind = 0, btn = nil, scanAt = 0 }
    runLoop(function()
        if not flags.autoSkip then
            fSkip.setNote("")
            skipState.pressed, skipState.lastWave, skipState.btn = false, nil, nil
            skipState.fires, skipState.blind = 0, 0
            return 0.5
        end
        local ev = RE("SkipWaveVote")
        if not ev then
            fSkip.setNote("")
            return 1.5
        end

        local now = os.clock()
        local btn = skipState.btn
        if btn and not btn.Parent then btn = nil end
        if not btn and now - skipState.scanAt >= 0.5 then
            skipState.scanAt = now
            btn = findSkipButton(true)
        end
        skipState.btn = btn

        if btn and isShown(btn) then
            if skipState.pressed then
                fSkip.setNote("")
                return 0.3
            end
            if os.clock() - (skipState.lastAct or 0) >= 2 and pressButton(btn) then
                skipState.pressed = true
                skipState.lastAct = os.clock()
                fSkip.setNote("")
                return 0.3
            end
        else
            skipState.pressed = false
        end

        local wsA = ReplicatedStorage:FindFirstChild("WaveState")
        local w = wsA and wsA:GetAttribute("CurrentWave")
        if type(w) ~= "number" then w = waveNow.cur end

        local ws = ReplicatedStorage:FindFirstChild("WaveState")
        local can = ws ~= nil and ws:GetAttribute("CanSkipWave") == true
        if w and now - (skipState.lastAct or 0) < 5 then
            fSkip.setNote("Skipped wave " .. w, C.text)
            return 0.15
        end
        if w then
            if w ~= skipState.lastWave then
                skipState.lastWave = w
                skipState.fires = 0
                skipState.lastFire = 0
                skipState.waveAt = now
            end
            if skipState.fires >= 2 or now - skipState.lastFire < 5 then
                fSkip.setNote("Skipped wave " .. w, C.text)
                return 0.15
            end

            if not can and now - skipState.waveAt < 0.7 then return 0.15 end
            skipState.fires = skipState.fires + 1
            skipState.lastFire = now
            if w + SKIP_WAVE_OFFSET >= 1 then pcall(function() ev:FireServer(w + SKIP_WAVE_OFFSET) end) end
            fSkip.setNote("Skipped wave " .. w, C.text)
            return 0.15
        end

        if now - skipState.lastFire >= 6 then
            skipState.lastFire = now
            skipState.blind = skipState.blind + 1
            pcall(function() ev:FireServer(skipState.blind) end)
        end
        fSkip.setNote("")
        return 1
    end)

    table.insert(conns, RunService.Heartbeat:Connect(function()
        if not flags.autoSkip then return end
        local b = skipState.btn
        if not (b and b.Parent) then return end
        if isShown(b) then
            if not skipState.pressed and os.clock() >= (skipState.nextTry or 0)
                and os.clock() - (skipState.lastAct or 0) >= 2 then
                if pressButton(b) then
                    skipState.pressed = true
                    skipState.lastAct = os.clock()
                else
                    skipState.nextTry = os.clock() + 0.5
                end
            end
        else
            skipState.pressed = false
        end
    end))

    function skipState.fireNow()
        local now = os.clock()
        if now - (skipState.lastAct or 0) < 2 then return end
        local ev = RE("SkipWaveVote")
        if not ev then return end

        local ws = ReplicatedStorage:FindFirstChild("WaveState")
        local w = ws and ws:GetAttribute("CurrentWave")
        if type(w) ~= "number" then w = nil end
        w = w or waveNow.cur
        if not w then return end
        skipState.lastAct, skipState.lastWave, skipState.fires, skipState.lastFire = now, w, 2, now
        if w + SKIP_WAVE_OFFSET >= 1 then pcall(function() ev:FireServer(w + SKIP_WAVE_OFFSET) end) end
        fSkip.setNote("Skipped wave " .. w, C.text)
    end
    task.spawn(function()
        local ws = ReplicatedStorage:WaitForChild("WaveState", 60)
        if not ws then return end
        table.insert(conns, ws:GetAttributeChangedSignal("CanSkipWave"):Connect(function()
            if flags.autoSkip and ws:GetAttribute("CanSkipWave") == true then skipState.fireNow() end
        end))
    end)

    task.spawn(function()
        local pg = LocalPlayer:WaitForChild("PlayerGui", 30)
        if not pg then return end
        table.insert(conns, pg.DescendantAdded:Connect(function(d)
            if flags.autoSkip and not skipState.btn and d:IsA("GuiButton") then skipState.scanAt = 0 end
        end))
    end)

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

    local fLoss = { setNote = function() end }
    local fForce = { setNote = function() end }
    do
        local TextService = game:GetService("TextService")
        local panel = createCard(page, 76)
        panel.Visible = false

        local function miniToggle(pos, initial, onChange)
            local state = initial and true or false
            local track = make("Frame", {
                Size = UDim2.new(0, 26, 0, 14),
                Position = pos,
                BackgroundColor3 = T(Color3.fromRGB(34, 34, 37), "bg"),
                BorderSizePixel = 0,
            }, panel)
            local stroke = make("UIStroke", { Color = C.controlLine, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, track)
            local knob = make("Frame", {
                Size = UDim2.new(0, 8, 0, 8),
                Position = UDim2.new(0, 3, 0.5, -4),
                BackgroundColor3 = C.muted,
                BorderSizePixel = 0,
            }, track)
            local hit = make("TextButton", {
                Size = UDim2.new(1, 8, 1, 8),
                Position = UDim2.new(0, -4, 0, -4),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 2,
            }, track)
            local function render(animate)
                local tc = state and T(Color3.fromRGB(232, 232, 234), "bg") or T(Color3.fromRGB(34, 34, 37), "bg")
                local kc = state and T(Color3.fromRGB(14, 14, 15), "bg") or C.muted
                local kp = state and UDim2.new(1, -11, 0.5, -4) or UDim2.new(0, 3, 0.5, -4)
                local sc = state and tc or C.controlLine
                if animate then
                    tween(track, 0.12, { BackgroundColor3 = tc })
                    tween(stroke, 0.12, { Color = sc })
                    tween(knob, 0.12, { BackgroundColor3 = kc, Position = kp })
                else
                    track.BackgroundColor3, stroke.Color = tc, sc
                    knob.BackgroundColor3, knob.Position = kc, kp
                end
            end
            hit.MouseButton1Click:Connect(function()
                state = not state
                render(true)
                onChange(state)
            end)
            render(false)
        end

        local function label(text, x, y)
            local w = TextService:GetTextSize(text, 10, Enum.Font.GothamMedium, Vector2.new(400, 20)).X
            make("TextLabel", {
                Size = UDim2.new(0, w + 2, 0, 26),
                Position = UDim2.new(0, x, 0, y),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = C.muted,
                TextSize = 10,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, panel)
            return x + w + 6
        end

        local function addRow(y, toggleKey, onToggle, prefix, numKey, minV, maxV, suffix)
            miniToggle(UDim2.new(0, 12, 0, y + 6), flags[toggleKey], onToggle)
            local x = label(prefix, 46, y)
            local box = createInput(panel, {
                Size = UDim2.new(0, 38, 0, 18),
                Position = UDim2.new(0, x, 0, y + 4),
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Center,
            }, "")
            box.Text = tostring(flags[numKey])
            box.FocusLost:Connect(function()
                local n = tonumber(box.Text)
                if n then setFlag(numKey, math.clamp(math.floor(n), minV, maxV)) end
                box.Text = tostring(flags[numKey])
            end)
            label(suffix, x + 44, y)
            local note = make("TextLabel", {
                Size = UDim2.new(0, 80, 0, 26),
                Position = UDim2.new(1, -92, 0, y),
                BackgroundTransparency = 1,
                Text = "",
                TextColor3 = C.muted,
                TextSize = 10,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Right,
            }, panel)
            return {
                setNote = function(t, color)
                    t = t or ""
                    if note.Text ~= t then note.Text = t end
                    note.TextColor3 = color or C.muted
                end,
            }
        end

        fLoss = addRow(8, "lossReturn", function(v)
            setFlag("lossReturn", v)
            setFlag("lossStreak", 0)
            fLoss.setNote("")
        end, "Back to lobby after", "lossLimit", 1, 20, "losses in a row")
        fForce = addRow(40, "forceLobby", function(v)
            setFlag("forceLobby", v)
        end, "Back to lobby after", "forceMinutes", 1, 240, "min in a match")

        if flags.lossReturn and (flags.lossStreak or 0) > 0 then
            fLoss.setNote("Losses " .. flags.lossStreak .. "/" .. (flags.lossLimit or 4))
        end

        local tw = TextService:GetTextSize("Auto Lobby", 12, Enum.Font.GothamMedium, Vector2.new(300, 30)).X
        local chev = createChevron(fLobby.card, 0)
        chev.AnchorPoint = Vector2.new(0, 0.5)
        chev.Position = UDim2.new(0, 12 + tw + 8, 0.5, 0)
        local chevHit = make("TextButton", {
            Size = UDim2.new(0, 26, 0, 30),
            Position = UDim2.new(0, 12 + tw + 1, 0, 2),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 3,
        }, fLobby.card)
        chevHit.MouseButton1Click:Connect(function()
            panel.Visible = not panel.Visible
            tween(chev, 0.12, { Rotation = panel.Visible and 180 or 0 })
        end)
    end

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

    local acted, counted, lossTries, seqBase = false, false, 0, (lastWave.seq or 0)
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
            f.setNote("")
            return 2
        end
        if not scanEndScreen() then
            acted, counted, lossTries, seqBase = false, false, 0, (lastWave.seq or 0)
            f.setNote("")
            return 1.5
        end
        if flags.lossReturn and wantReplay and not counted then
            local fresh = (lastWave.seq or 0) > seqBase
            if not fresh and lossTries < 10 then
                lossTries = lossTries + 1
                return 0.5
            end
            counted = true
            local res = fresh and (lastWave.last and "win" or "lose") or nil
            if res == "lose" then
                local n = (flags.lossStreak or 0) + 1
                setFlag("lossStreak", n)
                local limitN = flags.lossLimit or 4
                if n >= limitN then
                    setFlag("lossStreak", 0)
                    setFlag("autoReplay", false)
                    setFlag("autoPlay", false)
                    setFlag("lossNotice", true)
                    setFlag("lossNoticeN", limitN)
                    fReplay.set(false)
                    fLoss.setNote("")
                    notify("Lost " .. limitN .. " in a row", "Returning to lobby", 6)
                    wantLobby, f = true, fLobby
                else
                    fLoss.setNote("Losses " .. n .. "/" .. limitN)
                end
            elseif res == "win" then
                setFlag("lossStreak", 0)
                fLoss.setNote("")
            end
        end
        if acted then
            f.setNote(wantLobby and "Back to lobby" or "Voted replay", C.text)
            return 1.5
        end

        task.wait(0.8)
        local ev = wantLobby and ReplicatedStorage:FindFirstChild("ReturnToLobby") or RE("ReplayVote")
        if not ev then
            f.setNote("", C.muted)
            return 2
        end
        local ok = pcall(function() ev:FireServer() end)
        acted = ok
        if ok then
            f.setNote(wantLobby and "Back to lobby" or "Voted replay", C.text)
        else
            f.setNote("Vote failed", C.warn)
        end
        return 1.5
    end)

    local TeleportService = game:GetService("TeleportService")
    local startAt, lastTry, wasForce = os.clock(), -100, false
    runLoop(function()
        if not inMatch then
            fForce.setNote(flags.forceLobby and "Match only" or "")
            return 3
        end
        if not flags.forceLobby then
            wasForce = false
            fForce.setNote("")
            return 1
        end
        if not wasForce then
            wasForce = true
            startAt = os.clock()
        end
        local limit = (tonumber(flags.forceMinutes) or 20) * 60
        local left = limit - (os.clock() - startAt)
        if left > 0 then
            fForce.setNote(string.format("Lobby in %d:%02d", math.floor(left / 60), math.floor(left % 60)))
            return 1
        end
        fForce.setNote("Teleporting...", C.warn)
        if os.clock() - lastTry > 25 then
            lastTry = os.clock()
            notify("Time limit reached", "Teleporting to lobby", 5)
            pcall(function() TeleportService:Teleport(LOBBY_PLACE, LocalPlayer) end)
        end
        return 1
    end)
end

local counts, summonPrices, tickets = nil, nil, nil
local countsFull, crateDefs = false, {}
local boost = { inv = {}, rem = {}, at = nil, names = {} }
local BOOST_FIELD = {
    Money = "MoneyTimeRemaining", XP = "XPTimeRemaining",
    Luck = "LuckTimeRemaining", SummonDiscount = "SummonDiscountTimeRemaining",
}

local function stopFeature(f, key, why)
    setFlag(key, false)
    f.set(false)
    f.setNote("", C.muted)
    notify("Stopped", why, 5)
end

local function onBoost(t)
    if type(t) ~= "table" then return end
    if type(t.Inventory) == "table" then
        for k, v in pairs(t.Inventory) do boost.inv[k] = v end
    end
    for k, field in pairs(BOOST_FIELD) do
        if type(t[field]) == "number" then boost.rem[k] = t[field] end
    end
    boost.at = os.clock()
end

local function mergeCounts(t)
    if type(t) ~= "table" then return end
    if type(t.Crates) == "table" then
        for _, d in ipairs(t.Crates) do
            if type(d) == "table" and type(d.Id) == "string" and type(d.DisplayName) == "string" then
                crateDefs[d.Id] = d.DisplayName
                if type(d.Icon) == "string" and d.Icon ~= "" then ui.icons[d.Id] = d.Icon end
            end
        end
    end
    if type(t.Inventory) == "table" then

        local fresh = {}
        for k, v in pairs(t.Inventory) do fresh[k] = v end
        counts, countsFull = fresh, true
        return
    end
    if type(t.Crates) == "table" and type(t.Crates[1]) ~= "table" then t = t.Crates end
    counts = counts or {}
    for k, v in pairs(t) do
        if type(v) ~= "table" then counts[k] = v end
    end
end

local function findCount(t, id, depth)
    if type(t) ~= "table" or depth > 3 then return nil end
    local v = t[id]
    if v == nil then v = t[tostring(id)] end
    if v == nil and tonumber(id) then v = t[tonumber(id)] end
    if type(v) == "table" then
        v = v.Amount or v.Count or v.Quantity or v.amount or v.count
    end
    if type(v) == "number" then return v end
    for _, sub in pairs(t) do
        if type(sub) == "table" then
            local r = findCount(sub, id, depth + 1)
            if r ~= nil then return r end
        end
    end
    return nil
end

local function loadCounts()
    local ok, res = invoke("GetCrateState")
    if ok and type(res) == "table" and type(res.Inventory) == "table" then
        mergeCounts(res)
        return
    end
    local okD, d = invoke("GetData")
    local items = okD and type(d) == "table" and type(d.Inventory) == "table"
        and type(d.Inventory.Items) == "table" and d.Inventory.Items.Crates or nil
    if type(items) == "table" then
        mergeCounts({ Inventory = items })
    elseif ok and type(res) == "table" then
        mergeCounts(res)
    end
end
local countsAt = 0
local function refreshCounts()
    if os.clock() - countsAt < 8 then return end
    countsAt = os.clock()
    loadCounts()
end

bindEvent("CratesUpdated", function(t)
    mergeCounts(t)
    countsAt = 0
    task.delay(0.6, refreshCounts)
end)
bindEvent("SummonStateUpdated", function(t)
    if type(t) == "table" and type(t.Prices) == "table" then summonPrices = t.Prices end
    if type(t) == "table" and type(t.Has25Summon) == "boolean" then EP.has25 = t.Has25Summon end
end)
bindEvent("BoostStateUpdated", onBoost)

bindEvent("UpdateCurrency", function(name, amount)
    if name == "Tickets" and type(amount) == "number" then tickets = amount end
end)

task.spawn(function()
    boostAt = os.clock()
    local ok, res = invoke("GetBoostState")
    if ok then onBoost(res) end

    local okW, wheel = invoke("GetSpinWheelState")
    if okW and type(wheel) == "table" and type(wheel.Rewards) == "table" then
        for _, r in ipairs(wheel.Rewards) do
            if type(r) == "table" and r.Type == "Boost" and type(r.BoostName) == "string"
                and type(r.DisplayName) == "string" then
                boost.names[r.BoostName] = r.DisplayName
            end
        end
    end
    local okS, resS = invoke("GetSummonState")
    if okS and type(resS) == "table" and type(resS.Prices) == "table" then summonPrices = resS.Prices end
    if okS and type(resS) == "table" and type(resS.Has25Summon) == "boolean" then EP.has25 = resS.Has25Summon end
    countsAt = os.clock()
    loadCounts()
end)

local ticketsAt = 0
local function refreshTickets()
    if os.clock() - ticketsAt < 5 then return end
    ticketsAt = os.clock()
    local ok, res = invoke("GetData")
    local c = ok and type(res) == "table" and res.Currency or nil
    if type(c) == "table" and type(c.Tickets) == "number" then tickets = c.Tickets end
end

local boostAt = 0
local function refreshBoost()
    if os.clock() - boostAt < 8 then return end
    boostAt = os.clock()
    local ok, res = invoke("GetBoostState")
    if ok then onBoost(res) end
end

do
    local page = tabs["Gacha"].page

    local fSummon = visualFeature(page, "Auto Summon", "autoSummon", 28, function(body)
        createSegmented(body, {
            Size = UDim2.new(0, 150, 1, 0),
        }, SUMMON_OPTIONS, flags.summonAmount, function(v)
            setFlag("summonAmount", v)
        end)
    end)

    local summonFails = 0
    local summonBrokeNotified = false
    runLoop(function()
        if not flags.autoSummon then
            fSummon.setNote("")
            summonFails = 0
            summonBrokeNotified = false
            return 0.4
        end
        if EP.animBusy() then
            fSummon.setNote("Wait for animation", C.warn)
            return 1
        end
        local amount = flags.summonAmount
        if amount == 25 and EP.has25 == false then amount = 10 end
        local price = summonPrices and (summonPrices[amount] or summonPrices[tostring(amount)])
        local coins = getStatN("Coins")
        if type(price) == "number" and coins and coins < price then
            fSummon.setNote("Not enough coins", C.warn)
            if not summonBrokeNotified then
                summonBrokeNotified = true
                notify("Auto Summon", "Not enough coins. Waiting for more", 5)
            end
            return 1.5
        end
        summonBrokeNotified = false
        local ok, res = invoke("SummonUnits", amount)
        if accepted(ok, res) then
            summonFails = 0
            fSummon.setNote("")
        else
            summonFails = summonFails + 1
            fSummon.setNote("")
            if summonFails >= 8 then
                summonFails = 0
                stopFeature(fSummon, "autoSummon", "Auto Summon stopped. Try again in a moment.")
            end
        end
        return amount >= 10 and 1.2 or 0.6
    end)

    local fSpin = visualFeature(page, "Auto Spin", "autoSpin", 0)
    local spinFullNotified = false

    runLoop(function()
        if not flags.autoSpin then
            fSpin.setNote("")
            spinFullNotified = false
            return 0.4
        end

        local okS, st = invoke("GetSpinWheelState")
        if okS and type(st) == "table" then
            if type(st.Tickets) == "number" then tickets = st.Tickets end
            local free = type(st.FreeSpins) == "number" and st.FreeSpins or 0
            local cost = type(st.Cost) == "number" and st.Cost or 1
            if st.InventoryFull == true then
                fSpin.setNote("Inventory full", C.warn)
                if not spinFullNotified then
                    spinFullNotified = true
                    notify("Auto Spin", "Inventory full. Free up space to continue", 5)
                end
                return 4
            end
            spinFullNotified = false
            if free <= 0 and tickets ~= nil and tickets < cost then
                fSpin.setNote("Not enough tickets", C.warn)
                return 4
            end
            if st.Ready == false then
                fSpin.setNote("")
                return 1
            end
        elseif tickets == nil then
            refreshTickets()
        end
        local noTickets = tickets ~= nil and tickets <= 0
        local ok, res = invoke("SpinWheel")
        if accepted(ok, res) then
            tickets = nil
            fSpin.setNote("")
            return settings.skipAnim and 1.5 or 7
        end
        fSpin.setNote(noTickets and "Not enough tickets" or "Wheel not ready", C.warn)
        return noTickets and 4 or 6
    end)
end

do
    local page = tabs["Gacha"].page

    local noDataSince = nil
    local function stockCheck(id, want, noun)
        local have = findCount(counts, id, 0)
        if have == nil and countsFull then have = 0 end
        if have == nil then
            task.spawn(refreshCounts)
            if counts == nil then
                noDataSince = noDataSince or os.clock()
                if os.clock() - noDataSince < 4 then return nil, "" end
            end
            return want, nil, true
        end
        noDataSince = nil
        if have <= 0 then
            return nil, "Out of stock"
        end
        if have < want then
            return nil, "Need " .. want .. ", have " .. have
        end
        return want
    end

    local function amountOf(v)
        if type(v) == "table" then v = v.Amount or v.Count or v.Quantity or v.amount or v.count end
        return type(v) == "number" and v or nil
    end
    local function labelFor(kind, id)
        if crateDefs[id] then return crateDefs[id] end
        if kind == "crate" and id == "Free" then return "Free Scientist Crate" end
        if kind == "lucky" then
            for _, o in ipairs(LUCKY_OPTIONS) do
                if o.value == id then return o.label end
            end
        end
        return (string.gsub(tostring(id), "(%l)(%u)", "%1 %2"))
    end
    local function ownedItems(kind)
        local out = {}
        if not countsFull or type(counts) ~= "table" then return out, false end
        for id, v in pairs(counts) do
            local n = amountOf(v)
            if type(id) == "string" and n and n > 0 and not string.find(id, "^Voucher") then
                local isLucky = string.find(string.lower(id), "luckyblock", 1, true) ~= nil
                if isLucky == (kind == "lucky") then
                    out[#out + 1] = { label = labelFor(kind, id), value = id, n = n, icon = ui.iconFor(id) }
                end
            end
        end
        table.sort(out, function(x, y) return x.label < y.label end)
        return out, true
    end

    local function optionsFor(kind)
        task.spawn(refreshCounts)
        local list, covered = ownedItems(kind)
        if not covered then
            if kind ~= "lucky" then return {} end
            local fb = {}
            for _, o in ipairs(LUCKY_OPTIONS) do
                fb[#fb + 1] = { label = o.label, value = o.value, icon = ui.iconFor(o.value) }
            end
            return fb
        end
        local opts = {}
        for _, it in ipairs(list) do
            opts[#opts + 1] = { label = it.label, count = it.n, value = it.value, icon = it.icon }
        end
        return opts
    end

    local crateSel
    local fCrate = visualFeature(page, "Auto Open Crate", "autoCrate", 28, function(body)
        createSegmented(body, {
            Size = UDim2.new(0, 96, 1, 0),
        }, CRATE_AMOUNT_OPTIONS, flags.crateAmount, function(v)
            setFlag("crateAmount", v)
        end)
        crateSel = createSelect(body, {
            Size = UDim2.new(1, -104, 1, 0),
            Position = UDim2.new(0, 104, 0, 0),
        }, {
            getOptions = function() return optionsFor("crate") end,
            labelOf = function(id) return labelFor("crate", id) end,
            iconOf = function(id) return ui.iconFor(id) end,
            countOf = function(id) return findCount(counts, id, 0) end,
            emptyMsg = "No crates yet",
            initial = flags.crateType,
            placeholder = "Select a crate",
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
            fCrate.setNote("Select a crate", C.warn)
            return 1
        end
        if EP.animBusy() then
            fCrate.setNote("Wait for animation", C.warn)
            return 1
        end
        local amount, why, blind = stockCheck(id, flags.crateAmount, "crate")
        if not amount then
            if why == "Out of stock" and countsFull then

                setFlag("crateType", "")
                if crateSel then crateSel.set("") end
                fCrate.setNote("Select a crate", C.warn)
                return 1.5
            end
            fCrate.setNote(why ~= "" and why or "Loading crates...", C.muted)
            return 1.5
        end
        local ok, res = invoke("OpenCrate", id, amount)
        if accepted(ok, res) then
            crateFails = 0
            fCrate.setNote("")
        else
            crateFails = crateFails + 1
            local limit = blind and 3 or 8
            fCrate.setNote("")
            if crateFails >= limit then
                crateFails = 0
                stopFeature(fCrate, "autoCrate", blind
                    and "Auto Open Crate stopped. Out of crates?"
                    or "Auto Open Crate stopped. Try again in a moment.")
            end
        end
        return 1.5
    end)

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
            getOptions = function() return optionsFor("lucky") end,
            labelOf = function(id) return labelFor("lucky", id) end,
            iconOf = function(id) return ui.iconFor(id) end,
            countOf = function(id) return findCount(counts, id, 0) end,
            emptyMsg = "No lucky blocks yet",
            initial = flags.luckyType,
            placeholder = "Select a block",
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
            fLucky.setNote("Select a block", C.warn)
            return 1
        end
        if EP.animBusy() then
            fLucky.setNote("Wait for animation", C.warn)
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
            fLucky.setNote("")
        else
            luckyFails = luckyFails + 1
            local limit = blind and 3 or 8
            fLucky.setNote("")
            if luckyFails >= limit then
                luckyFails = 0
                stopFeature(fLucky, "autoLucky", blind
                    and "Auto Open Lucky Block stopped. Out of blocks?"
                    or "Auto Open Lucky Block stopped. Try again in a moment.")
            end
        end
        return 1.5
    end)

    runLoop(function()
        task.spawn(refreshCounts)
        for _, k in ipairs({ { "crate", fCrate, "autoCrate" }, { "lucky", fLucky, "autoLucky" } }) do
            local list, covered = ownedItems(k[1])
            local hide = covered and #list == 0
            if k[2].card.Visible == hide then
                k[2].card.Visible = not hide
                if hide and flags[k[3]] then
                    setFlag(k[3], false)
                    k[2].set(false)
                    k[2].setNote("")
                end
            end
        end
        return 3
    end)

    local function potionName(k)
        if boost.names[k] then return boost.names[k] end
        local spaced = string.gsub(tostring(k), "(%l)(%u)", "%1 %2")
        if string.find(spaced, "Discount", 1, true) then return spaced end
        return spaced .. " Potion"
    end
    local function potionOptions()
        task.spawn(refreshBoost)
        local list = {}
        for k, n in pairs(boost.inv) do
            if type(k) == "string" and type(n) == "number" and n > 0 then
                list[#list + 1] = { label = potionName(k), count = n, value = k, icon = ui.boostIcon(k) }
            end
        end
        table.sort(list, function(a, b) return a.label < b.label end)
        return list
    end
    local potionSel
    local fPotion = visualFeature(tabs["Inventory"].page, "Auto Use Potion", "autoPotion", 28, function(body)
        potionSel = createSelect(body, {
            Size = UDim2.new(1, 0, 1, 0),
        }, {
            getOptions = potionOptions,
            labelOf = potionName,
            iconOf = function(k) return ui.boostIcon(k) end,
            countOf = function(k) return boost.inv[k] end,
            initial = flags.potionType,
            placeholder = "Select a potion",
            onChange = function(v) setFlag("potionType", v) end,
        })
    end)
    local potionUsed = 0

    local POTION_INTERVAL = 0.3
    local potionFails = 0
    runLoop(function()
        if not flags.autoPotion then
            fPotion.setNote("")
            potionFails = 0
            potionUsed = 0
            return 0.5
        end
        local key = flags.potionType
        if key == "" then
            fPotion.setNote("Select a potion", C.warn)
            return 1
        end
        local have = boost.inv[key]
        local blind = (have == nil)
        if blind then
            task.spawn(refreshBoost)
        elseif have <= 0 then

            setFlag("potionType", "")
            if potionSel then potionSel.set("") end
            fPotion.setNote("Select a potion", C.warn)
            return 2
        end
        local ok, res = invoke("UseBoost", key)
        if accepted(ok, res) then
            potionFails = 0
            potionUsed = potionUsed + 1
            if have then boost.inv[key] = math.max(0, have - 1) end
            fPotion.setNote("Total used " .. potionUsed, C.text)
            return POTION_INTERVAL
        end
        potionFails = potionFails + 1
        fPotion.setNote("")
        if potionFails >= (blind and 3 or 8) then
            potionFails = 0
            stopFeature(fPotion, "autoPotion", blind
                and "Auto Use Potion stopped. Out of potions?"
                or "Auto Use Potion stopped. This potion can't stack further.")
        end
        return 1
    end)
end

do
    local page = tabs["Inventory"].page

    local KEEP_KEYS = { "Equipped", "Locked", "Lock", "Favorite", "Favourite", "InUse", "Placed" }

    local cache = nil
    local cacheAt, busy = -100, false
    local warned = false

    local function build(troops)
        local groups, order, total = {}, {}, 0
        for _, u in ipairs(troops) do
            if type(u) == "table" and type(u.UUID) == "string" then
                local keep = false
                for _, k in ipairs(KEEP_KEYS) do
                    if u[k] == true then keep = true end
                end
                if not keep then
                    local n = u.Name or u.DisplayName or "Unknown"
                    local g = groups[n]
                    if not g then
                        g = { n = n, ids = {}, icon = type(u.Icon) == "string" and u.Icon or nil, rarity = u.Rarity }
                        groups[n] = g
                        order[#order + 1] = g
                    end
                    g.ids[#g.ids + 1] = u.UUID
                    total = total + 1
                end
            end
        end
        table.sort(order, function(a, b) return a.n < b.n end)
        return { list = order, total = total }
    end

    local function refresh(force)
        if busy then return end
        if not force and os.clock() - cacheAt < 8 then return end
        busy = true
        cacheAt = os.clock()
        task.spawn(function()
            local ok, res = invoke("GetData")
            local inv = ok and type(res) == "table" and res.Inventory or nil
            if type(inv) == "table" and type(inv.Troops) == "table" then
                cache = build(inv.Troops)
            elseif not warned then
                warned = true
            end
            busy = false
        end)
    end

    local card = createFeature(page, "Units", { noToggle = true, bodyHeight = 64 })
    card.card.LayoutOrder = -2
    local selected, statusUntil, selling = nil, 0, false

    local function say(t, color)
        statusUntil = os.clock() + 4
        card.setNote(t, color)
    end

    local function groupOf(name)
        for _, g in ipairs(cache and cache.list or {}) do
            if g.n == name then return g end
        end
        return nil
    end

    createSelect(card.body, {
        Size = UDim2.new(1, 0, 0, 28),
    }, {
        placeholder = "Select a unit",
        emptyMsg = "No units yet",
        search = true,
        getOptions = function()
            refresh(false)
            local opts = {}
            for _, g in ipairs(cache and cache.list or {}) do
                opts[#opts + 1] = {
                    label = g.n, count = #g.ids, value = g.n,
                    icon = g.icon, tier = ui.TIER[g.rarity],
                }
            end
            return opts
        end,
        countOf = function(name)
            local g = groupOf(name)
            return g and #g.ids or 0
        end,
        iconOf = function(name)
            local g = groupOf(name)
            return g and g.icon or nil
        end,
        tierOf = function(name)
            local g = groupOf(name)
            return g and ui.TIER[g.rarity] or nil
        end,
        onChange = function(v) selected = v end,
    })

    local amountBox = createInput(card.body, {
        Size = UDim2.new(0, 90, 0, 28),
        Position = UDim2.new(0, 0, 0, 36),
        TextXAlignment = Enum.TextXAlignment.Center,
    }, "Amount")

    local function planSale(all)
        if selling then return nil end
        if not selected then
            say("Select a unit", C.warn)
            return nil
        end
        local group
        for _, g in ipairs(cache and cache.list or {}) do
            if g.n == selected then group = g end
        end
        if not group then
            say("Out of stock", C.warn)
            return nil
        end
        local amount
        if all then
            amount = #group.ids
        else
            amount = tonumber(amountBox.Text)
            if not amount or amount < 1 then
                say("Enter an amount", C.warn)
                return nil
            end
            amount = math.min(math.floor(amount), #group.ids)
        end
        return group, amount
    end

    local function sellUnits(all)
        local group, amount = planSale(all)
        if not group then return end
        selling = true
        task.spawn(function()
            local sold, failed = 0, false
            local i = 1
            while i <= amount and not failed do
                local batch, count = {}, 0
                while i <= amount and count < 25 do
                    batch[group.ids[i]] = true
                    i, count = i + 1, count + 1
                end
                local ok, res = invoke("SellUnits", batch)
                if accepted(ok, res) then
                    sold = sold + count
                else
                    failed = true
                end
                task.wait(0.2)
            end
            if sold > 0 then
                say("Sold " .. sold .. " " .. selected, failed and C.warn or C.text)
            else
                say("Sale failed", C.warn)
            end
            refresh(true)
            selling = false
        end)
    end

    local sellBtn, allBtn
    local base, armed = {}, nil
    local function disarm()
        if armed then
            armed.Text = base[armed]
            armed.TextColor3 = C.text
            armed = nil
        end
    end
    local function press(btn, all)
        if armed == btn then
            disarm()
            sellUnits(all)
            return
        end
        disarm()
        local group, amount = planSale(all)
        if not group then return end
        armed = btn
        btn.Text = "Sure?"
        btn.TextColor3 = C.warn
        say((all and "Sell all " or "Sell ") .. amount .. " " .. group.n .. "?", C.warn)
        task.delay(3, function()
            if armed == btn then disarm() end
        end)
    end
    sellBtn = createButton(card.body, {
        Size = UDim2.new(0.5, -52, 0, 28),
        Position = UDim2.new(0, 98, 0, 36),
    }, "Sell", function() press(sellBtn, false) end)
    allBtn = createButton(card.body, {
        Size = UDim2.new(0.5, -52, 0, 28),
        Position = UDim2.new(0.5, 52, 0, 36),
    }, "Sell all", function() press(allBtn, true) end)
    base[sellBtn], base[allBtn] = "Sell", "Sell all"

    runLoop(function()
        refresh(false)
        if os.clock() > statusUntil then
            if cache then
                card.setNote(#cache.list .. " types · " .. cache.total .. " units", C.muted)
            else
                card.setNote("")
            end
        end
        return 3
    end)
end

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
            upg.setNote("")
            return 1
        end

        local towers = getMyTowers()
        if #towers == 0 then
            upg.setNote("No towers placed", C.muted)
            return 1
        end

        local target, reason = pickTarget(towers, getStat("Cash"))
        if target then
            upg.maxed = false
            upg.setNote("")
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
            if not upg.maxed then
                upg.maxed = true
                notify("Auto Upgrade", "All towers maxed", 3)
            end
            upg.setNote("All towers maxed", C.muted)
            return 1
        end
        upg.setNote("Not enough cash", C.warn)
        return math.max(0.1, math.min(settings.upgradeDelay, 0.5))
    end)
end

local SPOTS_FILE = FS.data("Spots")
local UTTM_NAME = "Upgraded Titan Cinema Man"

do
    local page = tabs["Endless"].page
    local mouse = LocalPlayer:GetMouse()

    local spots = { uttm = {}, mowers = {}, home = {} }

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

    local function readUnits(src)
        local out = {}
        if type(src) ~= "table" then return out end
        for _, u in ipairs(src) do
            if type(u) == "table" and type(u.n) == "string" and type(u.x) == "number"
                and type(u.y) == "number" and type(u.z) == "number" then
                local cf = nil
                if type(u.cf) == "table" and #u.cf == 12 then cf = u.cf end
                local ys = nil
                if type(u.ys) == "table" then
                    ys = {}
                    for _, v in ipairs(u.ys) do
                        if type(v) == "number" then ys[#ys + 1] = v end
                    end
                    if #ys == 0 then ys = nil end
                end
                out[#out + 1] = { n = u.n, x = u.x, y = u.y, z = u.z, cf = cf, ys = ys }
            end
        end
        return out
    end

    if canFile and isfile(SPOTS_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(SPOTS_FILE)) end)
        if ok and type(data) == "table" then
            spots.uttm = readLocs(data.uttm)
            spots.home = readUnits(data.home)
            if type(data.mowers) == "table" then
                for _, m in ipairs(data.mowers) do
                    if type(m) == "table" and type(m.id) == "number" then
                        local units = readUnits(m.units)
                        if #units > 0 then
                            spots.mowers[#spots.mowers + 1] = { id = m.id, units = units }
                        end
                    end
                end
            end
        end
    end

    local function saveSpots()
        if canFile then pcall(writefile, SPOTS_FILE, HttpService:JSONEncode(spots)) end
    end

    local pick = nil

    local function startPick(cb)
        local token = os.clock()
        pick = { cb = cb, token = token, lastT = 0, lastPos = nil }
        pcall(function() mouse.TargetFilter = workspace:FindFirstChild("Towers") end)
        notify("Select Location", "Double-tap the ground where you want it (30s)", 6)
        task.delay(30, function()
            if pick and pick.token == token then
                pick = nil
                notify("Select Location", "Selection timed out", 3)
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
                    notify("Select Location", "Couldn't read that spot. Try again.", 3)
                end
            end)
            return
        end
        pick.lastT, pick.lastPos = now, here
    end))

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
            Size = UDim2.new(1, -226, 0, 28),
            Position = UDim2.new(0, 66, 0, y),
        }, "Teleport", function() onTeleport(s) end)

        createButton(rows, {
            Size = UDim2.new(0, 88, 0, 28),
            Position = UDim2.new(1, -156, 0, y),
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
            Size = UDim2.new(0, 60, 0, 28),
            Position = UDim2.new(1, -60, 0, y),
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

    local uttmCard = createCard(page, 80)
    local uttmFloat, refreshUttmFloat
    local uttmTitle = make("TextLabel", {
        Size = UDim2.new(0, 150, 0, 34),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "Teleport",
        TextColor3 = C.hi,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, uttmCard)

    local TextService = game:GetService("TextService")
    local prefixW = TextService:GetTextSize("Teleport ", 12, Enum.Font.GothamBold, Vector2.new(400, 40)).X
    local uttmWord = make("TextLabel", {
        Size = UDim2.new(0, 60, 0, 34),
        Position = UDim2.new(0, 12 + prefixW, 0, 0),
        BackgroundTransparency = 1,
        Text = "UTTM",
        TextColor3 = C.hi,
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
        Position = UDim2.new(1, -266, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.muted,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, uttmCard)
    createButton(uttmCard, {
        Size = UDim2.new(0, 50, 0, 24),
        Position = UDim2.new(1, -62, 0, 5),
    }, "Popup", function()
        if uttmFloat then uttmFloat.toggle() end
    end)
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

    local droneState = env.LightHubDrone
    if not droneState then
        droneState = { on = nil }
        env.LightHubDrone = droneState
    end
    droneState.active = true
    droneState.internal = false

    if hookmetamethod and getnamecallmethod and not env.LightHubDroneHooked then
        pcall(function()
            local old
            old = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if method == "InvokeServer" and droneState.active and not droneState.internal
                    and typeof(self) == "Instance" and self.Name == "CinemaRelocate" then
                    local args = table.pack(...)
                    if args[1] == "Drones" then
                        local res = table.pack(old(self, ...))
                        if res[1] ~= false then droneState.on = not droneState.on end
                        return table.unpack(res, 1, res.n)
                    end
                end
                return old(self, ...)
            end)
            env.LightHubDroneHooked = true
        end)
    end

    local function cameraInDrone()
        local cam = workspace.CurrentCamera
        local ch = LocalPlayer.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if not cam or not hum then return false end
        if cam.CameraType == Enum.CameraType.Scriptable then return true end
        return cam.CameraSubject ~= nil and cam.CameraSubject ~= hum
    end

    local function isDroneOn(tw)
        for name, v in pairs(tw:GetAttributes()) do
            if type(v) == "boolean" and string.find(string.lower(name), "drone", 1, true) then
                return v
            end
        end
        return cameraInDrone() or droneState.on == true
    end

    local function toggleDrone(tw, newState)
        droneState.internal = true
        local ok, res = invoke("CinemaRelocate", "Drones", tw, nil)
        droneState.internal = false
        local good = ok and not (type(res) == "table" and (res.Success == false or res.success == false))
        if good then droneState.on = newState end
        return good
    end

    local function msgSaysDrone(res)
        local t = ""
        if type(res) == "string" then
            t = res
        elseif type(res) == "table" then
            t = tostring(res.Message or res.message or res.Error or res.error or "")
        end
        return string.find(string.lower(t), "drone", 1, true) ~= nil
    end

    local function uttmTeleport(s)
        if uttmBusy then return end
        uttmBusy = true
        task.spawn(function()
            local tw = findUttm()
            if not tw then
                uttmSay("UTTM not found", C.warn)
                uttmBusy = false
                return
            end
            uttmSay("Working...", C.muted)

            local droneOff = false
            if isDroneOn(tw) then
                uttmSay("Drone off...", C.muted)
                if toggleDrone(tw, false) then droneOff = true end
                task.wait(0.7)
            end

            local started = false
            for _ = 1, 5 do
                local ok, res = invoke("CinemaRelocate", "Start", tw, nil)
                if accepted(ok, res) then
                    started = true
                    break
                end
                if not droneOff and (msgSaysDrone(res) or cameraInDrone() or droneState.on == true) then
                    uttmSay("Drone off...", C.muted)
                    if toggleDrone(tw, false) then droneOff = true end
                    task.wait(0.7)
                elseif droneOff then
                    task.wait(0.5)
                else
                    break
                end
            end

            local placed = false
            if started then
                local ok2, res2 = invoke("CinemaRelocate", "Place", tw, CFrame.new(s.x, s.y, s.z))
                placed = accepted(ok2, res2)
                if placed then
                    lastUttmUse = os.clock()
                    uttmSay("Teleported to " .. s.n, C.text)
                else
                    uttmSay("Couldn't place it there", C.warn)
                end
            else
                local ago = lastUttmUse and (" (used " .. math.floor(os.clock() - lastUttmUse) .. "s ago)") or ""
                uttmSay("On cooldown" .. ago, C.warn)
            end

            if droneOff then
                task.wait(0.6)
                toggleDrone(findUttm() or tw, true)
                if placed then uttmSay("Teleported, drone back on", C.text) end
            end
            uttmBusy = false
        end)
    end

    local uttmRebuild
    local uttmOpen = false
    uttmRebuild = function()
        for _, c in ipairs(uttmRows:GetChildren()) do c:Destroy() end

        createCollapse(uttmRows, {
            Size = UDim2.new(1, 0, 0, 28),
            Position = UDim2.new(0, 0, 0, 0),
        }, "Locations", #spots.uttm, uttmOpen, function(v)
            uttmOpen = v
            uttmRebuild()
        end)
        local y = 28
        if uttmOpen then
            y = 36
            for i, sp in ipairs(spots.uttm) do
                addLocRow(uttmRows, spots.uttm, sp, y, uttmTeleport,
                    function(msg) uttmSay(msg, C.text) end, uttmRebuild)
                y = y + 32
            end
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
            y = y + 28
        end
        uttmRows.Size = UDim2.new(1, -24, 0, y)
        uttmCard.Size = UDim2.new(1, 0, 0, 34 + y + 10)
        if refreshUttmFloat then refreshUttmFloat() end
    end
    uttmRebuild()
    uttmCard.Visible = false

    uttmFloat = createFloat("UTTM teleport", UDim2.new(1, -340, 0, 90))
    refreshUttmFloat = function()
        local items = {}
        for i, sp in ipairs(spots.uttm) do
            items[#items + 1] = { text = "Tp-" .. i, fn = function() uttmTeleport(sp) end,
                c1 = UTTM_BLUE, c2 = UTTM_VIOLET }
        end
        uttmFloat.setItems(items)
    end
    refreshUttmFloat()

    runLoop(function()
        local found = findUttm() ~= nil
        if uttmCard.Visible ~= found then uttmCard.Visible = found end
        return 1
    end)

    EP.page, EP.spots, EP.saveSpots = page, spots, saveSpots
    EP.UTTM_BLUE, EP.UTTM_VIOLET = UTTM_BLUE, UTTM_VIOLET
    EP.findUttm, EP.pushMacro = findUttm, pushMacro
    EP.isBusy = function() return uttmBusy end
    EP.readUnits = readUnits
    EP.droneOn = isDroneOn

    EP.setDrone = function(tw, want)
        if isDroneOn(tw) == want then return true end
        return toggleDrone(tw, want)
    end
end

do
    local page, spots, saveSpots = EP.page, EP.spots, EP.saveSpots
    local UTTM_BLUE, UTTM_VIOLET = EP.UTTM_BLUE, EP.UTTM_VIOLET
    local pushMacro = EP.pushMacro

    do
        local GREEN_A, GREEN_B = Color3.fromRGB(46, 128, 94), Color3.fromRGB(128, 212, 164)
        local RED_A, RED_B = Color3.fromRGB(150, 24, 44), Color3.fromRGB(255, 176, 208)

        local mowerCard = createCard(page, 140)
        make("TextLabel", {
            Size = UDim2.new(0, 120, 0, 34),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = "Unit Replace",
            TextColor3 = C.hi,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, mowerCard)
        local mowerNote = make("TextLabel", {
            Size = UDim2.new(0, 190, 0, 34),
            Position = UDim2.new(1, -266, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = C.muted,
            TextSize = 10,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, mowerCard)
        local function say(t, color)
            mowerNote.Text = t or ""
            mowerNote.TextColor3 = color or C.muted
        end

        local mowerFloat
        createButton(mowerCard, {
            Size = UDim2.new(0, 50, 0, 24),
            Position = UDim2.new(1, -62, 0, 5),
        }, "Popup", function()
            if mowerFloat then mowerFloat.toggle() end
        end)

        local function myTowers()
            local out = {}
            local folder = workspace:FindFirstChild("Towers")
            if folder then
                for _, t in ipairs(folder:GetChildren()) do
                    if t.Name ~= UTTM_NAME and t:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
                        local ok, p = pcall(function() return t:GetPivot().Position end)
                        if ok then
                            local rec = placeHook.registry[t]
                            out[#out + 1] = {
                                tower = t, name = t.Name, pos = p,
                                rx = rec and rec[1] or p.X, rz = rec and rec[3] or p.Z,
                                exact = rec,
                            }
                        end
                    end
                end
            end
            return out
        end

        local function flat(p, x, z)
            return math.sqrt((p.X - x) ^ 2 + (p.Z - z) ^ 2)
        end

        local function nearestTower(name, x, z, r)
            local best, bd
            for _, u in ipairs(myTowers()) do
                if u.name == name then
                    local d = flat(u.pos, x, z)
                    if d <= r and (not bd or d < bd) then best, bd = u.tower, d end
                end
            end
            return best
        end

        local function groundOf(pos)
            local ok, hit = pcall(function()
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                local ex = {}
                local tf = workspace:FindFirstChild("Towers")
                if tf then ex[#ex + 1] = tf end
                if LocalPlayer.Character then ex[#ex + 1] = LocalPlayer.Character end
                params.FilterDescendantsInstances = ex
                return workspace:Raycast(pos + Vector3.new(0, 6, 0), Vector3.new(0, -200, 0), params)
            end)
            if ok and hit then return hit.Position.Y end
            return pos.Y
        end

        local function targetCF(tg)
            if type(tg.cf) == "table" and #tg.cf == 12 then
                local ok, cf = pcall(function() return CFrame.new(table.unpack(tg.cf)) end)
                if ok then return cf end
            end
            return CFrame.new(tg.x, tg.y, tg.z)
        end

        local function parallel(list, fn, timeout)
            local left = #list
            if left == 0 then return end
            for _, item in ipairs(list) do
                task.spawn(function()
                    pcall(fn, item)
                    left = left - 1
                end)
            end
            local t0 = os.clock()
            while left > 0 and os.clock() - t0 < (timeout or 45) do task.wait(0.1) end
        end

        local inFlight = {}
        local runId = 0
        local pending = 0

        local function plan(targets)
            local pool = {}
            for _, u in ipairs(myTowers()) do
                if not inFlight[u.tower] then pool[#pool + 1] = u end
            end
            local remaining, same = {}, 0
            for _, tg in ipairs(targets) do
                local done = false
                for i, u in ipairs(pool) do
                    if u.name == tg.n and flat({ X = u.rx, Z = u.rz }, tg.x, tg.z) < 1.5 then
                        table.remove(pool, i)
                        done = true
                        break
                    end
                end
                if done then same = same + 1 else remaining[#remaining + 1] = tg end
            end
            local moves, missing = {}, 0
            for _, tg in ipairs(remaining) do
                local bi, bd
                for i, u in ipairs(pool) do
                    if u.name == tg.n then
                        local d = flat({ X = u.rx, Z = u.rz }, tg.x, tg.z)
                        if not bd or d < bd then bi, bd = i, d end
                    end
                end
                if bi then
                    moves[#moves + 1] = { unit = pool[bi], tg = tg }
                    table.remove(pool, bi)
                else
                    missing = missing + 1
                end
            end
            return moves, same, missing
        end

        local learnedKind = {}

        local function candidatesFor(tg)
            if type(tg.cf) == "table" and #tg.cf == 12 then
                return { { cf = targetCF(tg), kind = 0 } }
            end
            local list, seen = {}, {}
            local function add(kind, y)
                if type(y) ~= "number" then return end
                local key = math.floor(y * 10 + 0.5)
                if seen[key] then return end
                seen[key] = true
                list[#list + 1] = { cf = CFrame.new(tg.x, y, tg.z), kind = kind }
            end
            local order = { 1, 2, 3 }
            local lk = learnedKind[tg.n]
            if lk then order = { lk, lk % 3 + 1, (lk + 1) % 3 + 1 } end
            local ys = type(tg.ys) == "table" and tg.ys or { tg.y }
            for _, k in ipairs(order) do add(k, ys[k]) end
            if #list == 0 then add(1, tg.y) end
            return list
        end

        local function locOf(u)
            if u.exact then
                return { n = u.name, x = u.exact[1], y = u.exact[2], z = u.exact[3], cf = u.exact }
            end
            local ground = groundOf(u.pos)
            local bottom = u.pos.Y
            local okb, bcf, bsize = pcall(function() return u.tower:GetBoundingBox() end)
            if okb and bcf and bsize then bottom = bcf.Position.Y - bsize.Y / 2 end
            return { n = u.name, x = u.pos.X, y = ground, z = u.pos.Z, ys = { ground, bottom, u.pos.Y } }
        end

        local function tryPlace(target, tries, myRun)
            local cands = candidatesFor(target)
            for attempt = 1, tries do
                if myRun and myRun ~= runId then return nil end
                local cand = cands[(attempt - 1) % #cands + 1]
                invoke("PlaceTower", target.n, cand.cf)
                for _ = 1, 8 do
                    task.wait(0.1)
                    local pt = nearestTower(target.n, target.x, target.z, 3)
                    if pt then
                        if cand.kind > 0 then learnedKind[target.n] = cand.kind end
                        pushMacro({ t = "place", n = target.n, cf = { cand.cf:GetComponents() } })
                        return pt
                    end
                end
                task.wait(0.2)
            end
            return nil
        end

        local function processUnit(m)
            local u, tg = m.unit, m.tg
            local tw = u.tower
            if inFlight[tw] then return end
            inFlight[tw] = true
            m.level = tw:GetAttribute("Level")
            m.orig = locOf(u)
            invoke("SellTower", tw)
            for _ = 1, 12 do
                if not tw.Parent then break end
                task.wait(0.25)
            end
            if tw.Parent then
                inFlight[tw] = nil
                m.failed = true
                return
            end
            pushMacro({ t = "sell", n = u.name, p = { u.pos.X, u.pos.Y, u.pos.Z } })

            pending = pending + 1
            local placed = tryPlace(tg, 8, m.run)
            if placed then
                m.atTarget = true
            else
                placed = tryPlace(m.orig, 8)
                m.blocked = true
            end
            m.placed = placed
            pending = pending - 1

            local lvl = m.level
            if placed and type(lvl) == "number" then
                local t0 = os.clock()
                while os.clock() - t0 < 12 do
                    local cur = placed:GetAttribute("Level")
                    local price = placed:GetAttribute("UpgradePrice")
                    if type(cur) ~= "number" or cur >= lvl or type(price) ~= "number" or price <= 0 then
                        break
                    end
                    local ok, res = invoke("UpgradeTower", placed)
                    if ok and res == true then
                        pushMacro({ t = "up", n = u.name, p = { tg.x, tg.y, tg.z } })
                    end
                    task.wait(0.35)
                end
            end
            inFlight[tw] = nil
        end

        local function execute(label, targets)
            runId = runId + 1
            local myRun = runId

            local t0 = os.clock()
            while pending > 0 and os.clock() - t0 < 4 do task.wait(0.1) end
            local moves, same, missing = plan(targets)
            for _, m in ipairs(moves) do m.run = myRun end
            if #moves == 0 then
                local msg = (same > 0) and "Already in place" or "No matching units"
                say(msg, C.muted)
                return
            end
            say(label .. ": moving " .. #moves, C.muted)
            parallel(moves, processUnit, 60)

            local moved, blocked, lost = 0, 0, 0
            for _, m in ipairs(moves) do
                if m.atTarget then
                    moved = moved + 1
                elseif m.blocked then
                    if m.placed then blocked = blocked + 1 else lost = lost + 1 end
                end
            end
            local msg = label .. ": " .. moved .. "/" .. #moves .. " moved"
            if blocked > 0 then msg = msg .. ", " .. blocked .. " blocked" end
            if lost > 0 then msg = msg .. ", " .. lost .. " lost" end
            if missing > 0 then msg = msg .. ", " .. missing .. " missing" end
            say(msg, (moved == #moves) and C.text or C.warn)
        end

        local function snapshotHome()
            spots.home = {}
            local exact = 0
            for _, u in ipairs(myTowers()) do
                if u.exact then exact = exact + 1 end
                spots.home[#spots.home + 1] = locOf(u)
            end
            saveSpots()
            return #spots.home, exact
        end

        local function backHome()
            if #spots.home == 0 then
                say("No default saved", C.warn)
                notify("Unit Replace", "Save a default layout first", 3)
                return
            end
            execute("Default", spots.home)
        end

        local function placeMower(m)
            execute("Mower " .. m.id, m.units)
        end

        local recBuf, recOn = {}, false
        local recSwitch

        local function towerSet()
            local set = {}
            for _, u in ipairs(myTowers()) do set[u.tower] = true end
            return set
        end

        local function findPlaced(n, x, z, before)
            local best, bd
            for _, u in ipairs(myTowers()) do
                if u.name == n and not placeHook.registry[u.tower]
                    and not (before and before[u.tower]) then
                    local d = flat(u.pos, x, z)
                    if d <= 3 and (not bd or d < bd) then best, bd = u.tower, d end
                end
            end
            return best
        end

        placeHook.register = function(n, cf)
            if type(n) ~= "string" or typeof(cf) ~= "CFrame" then return end
            local before = towerSet()
            local comps = { cf:GetComponents() }
            for _ = 1, 10 do
                task.wait(0.25)
                local tw = findPlaced(n, comps[1], comps[3], before)
                if tw then
                    placeHook.registry[tw] = comps
                    return
                end
            end
        end

        placeHook.handler = function(nm, a1, a2)
            if nm == "PlaceTower" then
                if type(a1) ~= "string" or typeof(a2) ~= "CFrame" or a1 == UTTM_NAME then return end
                local comps = { a2:GetComponents() }
                for _ = 1, 8 do
                    task.wait(0.25)
                    local tw = findPlaced(a1, comps[1], comps[3], nil)
                    if tw then
                        placeHook.registry[tw] = comps
                        if recOn then
                            recBuf[#recBuf + 1] = { n = a1, x = comps[1], y = comps[2], z = comps[3], cf = comps }
                            say("Recording: " .. #recBuf .. " units", C.text)
                        end
                        return
                    end
                end
            elseif nm == "SellTower" then
                if typeof(a1) ~= "Instance" then return end
                placeHook.registry[a1] = nil
                if recOn then
                    local ok, p = pcall(function() return a1:GetPivot().Position end)
                    if not ok then return end
                    for i = #recBuf, 1, -1 do
                        if recBuf[i].n == a1.Name and flat(p, recBuf[i].x, recBuf[i].z) <= 3 then
                            table.remove(recBuf, i)
                        end
                    end
                    say("Recording: " .. #recBuf .. " units", C.text)
                end
            end
        end

        task.spawn(function()
            for _ = 1, 60 do
                if placeHook.install then
                    local ok, res = pcall(placeHook.install)
                    placeHook.ready = ok and res == true
                    placeHook.active = placeHook.ready
                    return
                end
                task.wait(0.5)
            end
        end)

        local rebuildMower, refreshMowerFloat
        local replaceOpen = false

        local function nextMowerId()
            local n = 1
            while true do
                local used = false
                for _, m in ipairs(spots.mowers) do
                    if m.id == n then used = true end
                end
                if not used then return n end
                n = n + 1
            end
        end

        local function startRecording()
            if not placeHook.ready then
                notify("Unit Replace", "Recording isn't supported on this executor", 4)
                return false
            end
            recBuf = {}
            recOn = true
            say("Recording: place your units", C.text)
            return true
        end

        local function stopRecording()
            recOn = false
            if #recBuf == 0 then
                say("Nothing recorded", C.muted)
                return
            end
            local m = { id = nextMowerId(), units = recBuf }
            recBuf = {}
            spots.mowers[#spots.mowers + 1] = m
            table.sort(spots.mowers, function(a, b) return a.id < b.id end)
            saveSpots()
            rebuildMower()
            refreshMowerFloat()
            say("Replace " .. m.id .. " saved (" .. #m.units .. " units)", C.text)
        end

        local rows = make("Frame", {
            Size = UDim2.new(1, -24, 0, 64),
            Position = UDim2.new(0, 12, 0, 34),
            BackgroundTransparency = 1,
        }, mowerCard)

        local function rowLabel(y, text)
            make("TextLabel", {
                Size = UDim2.new(0, 104, 0, 28),
                Position = UDim2.new(0, 0, 0, y),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = C.text,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, rows)
        end

        local function armed(btn, idle, ms)

            local on = false
            return function()
                if on then
                    on = false
                    return true
                end
                on = true
                btn.Text = "Sure?"
                task.delay(ms or 3, function()
                    on = false
                    if btn.Parent then btn.Text = idle end
                end)
                return false
            end
        end

        rebuildMower = function()
            for _, c in ipairs(rows:GetChildren()) do c:Destroy() end

            rowLabel(0, "Record placement")
            recSwitch = createMiniSwitch(rows, {
                Position = UDim2.new(0, 110, 0, 6),
            }, recOn, function(v)
                if v then
                    if not startRecording() then recSwitch.set(false, true) end
                else
                    stopRecording()
                end
            end)

            rowLabel(32, "Back default")
            createFxButton(rows, {
                Size = UDim2.new(0, 60, 0, 28),
                Position = UDim2.new(0, 110, 0, 32),
            }, "Back", backHome, GREEN_A, GREEN_B, true)
            local hasHome = #spots.home > 0
            local homeBtn
            local confirmEdit
            homeBtn = createFxButton(rows, {
                Size = UDim2.new(0, 60, 0, 28),
                Position = UDim2.new(0, 176, 0, 32),
            }, hasHome and "Edit" or "Save", function()
                if hasHome and not confirmEdit() then return end
                local n, exact = snapshotHome()
                local msg = n .. " units"
                if exact < n then msg = msg .. ", " .. (n - exact) .. " estimated" end
                say("Default saved (" .. msg .. ")", C.text)
                notify("Unit Replace", "Default saved: " .. msg, 4)
                rebuildMower()
                refreshMowerFloat()
            end, GREEN_A, GREEN_B)
            confirmEdit = armed(homeBtn, "Edit")
            if hasHome then
                make("TextLabel", {
                    Size = UDim2.new(1, -250, 0, 28),
                    Position = UDim2.new(0, 246, 0, 32),
                    BackgroundTransparency = 1,
                    Text = #spots.home .. " units",
                    TextColor3 = C.dim,
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, rows)
            end

            createCollapse(rows, {
                Size = UDim2.new(1, 0, 0, 28),
                Position = UDim2.new(0, 0, 0, 64),
            }, "Replace list", #spots.mowers, replaceOpen, function(v)
                replaceOpen = v
                rebuildMower()
            end)

            for i, m in ipairs(replaceOpen and spots.mowers or {}) do
                local y = 100 + (i - 1) * 32
                rowLabel(y, "Replace " .. m.id)
                createFxButton(rows, {
                    Size = UDim2.new(0, 60, 0, 28),
                    Position = UDim2.new(0, 110, 0, y),
                }, "Place", function() placeMower(m) end, UTTM_BLUE, UTTM_VIOLET, true)
                local del
                local confirmDel
                del = createFxButton(rows, {
                    Size = UDim2.new(0, 60, 0, 28),
                    Position = UDim2.new(0, 176, 0, y),
                }, "Delete", function()
                    if not confirmDel() then return end
                    for j, v in ipairs(spots.mowers) do
                        if v == m then
                            table.remove(spots.mowers, j)
                            break
                        end
                    end
                    saveSpots()
                    rebuildMower()
                    refreshMowerFloat()
                    say("Replace " .. m.id .. " deleted", C.muted)
                end, RED_A, RED_B)
                confirmDel = armed(del, "Delete")
                make("TextLabel", {
                    Size = UDim2.new(1, -250, 0, 28),
                    Position = UDim2.new(0, 246, 0, y),
                    BackgroundTransparency = 1,
                    Text = #m.units .. " units",
                    TextColor3 = C.dim,
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, rows)
            end

            local h = replaceOpen and (100 + #spots.mowers * 32) or 92
            rows.Size = UDim2.new(1, -24, 0, h)
            mowerCard.Size = UDim2.new(1, 0, 0, 34 + h + 10)
        end

        mowerFloat = createFloat("Unit replace", UDim2.new(1, -190, 0, 90))
        refreshMowerFloat = function()
            local items = { { text = "Bth", fn = backHome, c1 = GREEN_A, c2 = GREEN_B } }
            for _, m in ipairs(spots.mowers) do
                items[#items + 1] = { text = "Rp-" .. m.id, fn = function() placeMower(m) end,
                    c1 = UTTM_BLUE, c2 = UTTM_VIOLET }
            end
            mowerFloat.setItems(items)
        end

        rebuildMower()
        refreshMowerFloat()

        local function replaceOptions()
            local t = {}
            if #spots.mowers > 1 then t[#t + 1] = { label = "All replace", value = "All replace" } end
            for _, m in ipairs(spots.mowers) do
                local n = "Replace " .. m.id
                t[#t + 1] = { label = n, value = n }
            end
            return t
        end

        local share = createFeature(tabs["Share"].page, "Share Replace", { noToggle = true, bodyHeight = 28 })
        share.card.LayoutOrder = 101
        local shareSel = createSelect(share.body, {
            Size = UDim2.new(1, -96, 1, 0),
        }, {
            placeholder = "Select a replace",
            getOptions = replaceOptions,
            emptyMsg = "No replace layouts yet. Record one first.",
        })
        createButton(share.body, {
            Size = UDim2.new(0, 90, 1, 0),
            Position = UDim2.new(1, -90, 0, 0),
        }, "Copy code", function()
            local pick = shareSel.get()
            if not pick or pick == "" then
                notify("Unit Replace", "Select a replace to share first", 3)
                return
            end
            local list = {}
            if pick == "All replace" then
                for _, m in ipairs(spots.mowers) do list[#list + 1] = { units = m.units } end
            else
                local id = tonumber(pick:match("%d+"))
                for _, m in ipairs(spots.mowers) do
                    if m.id == id then list[1] = { units = m.units } end
                end
            end
            if #list == 0 then
                notify("Unit Replace", "That replace no longer exists", 3)
                return
            end
            if not setclipboard then
                notify("Unit Replace", "This executor can't copy to the clipboard", 4)
                return
            end
            local ok = pcall(setclipboard, HttpService:JSONEncode({ v = 1, t = "replace", list = list }))
            if ok then
            else
                notify("Unit Replace", "Couldn't copy the code", 3)
            end
        end)

        local imp = createFeature(tabs["Share"].page, "Import Replace", { noToggle = true, bodyHeight = 28 })
        imp.card.LayoutOrder = 103
        local codeBox = createInput(imp.body, { Size = UDim2.new(1, -96, 1, 0) }, "Paste replace code")
        createButton(imp.body, {
            Size = UDim2.new(0, 90, 1, 0),
            Position = UDim2.new(1, -90, 0, 0),
        }, "Import", function()
            local text = codeBox.Text
            if text == "" then
                notify("Unit Replace", "Paste the replace code first", 3)
                return
            end
            local ok, data = pcall(function() return HttpService:JSONDecode(text) end)
            if not ok or type(data) ~= "table" or data.t ~= "replace" or type(data.list) ~= "table" then
                notify("Unit Replace", "That isn't a valid replace code", 4)
                return
            end
            local added = 0
            for _, entry in ipairs(data.list) do
                local units = type(entry) == "table" and EP.readUnits(entry.units) or {}
                if #units > 0 then
                    spots.mowers[#spots.mowers + 1] = { id = nextMowerId(), units = units }
                    added = added + 1
                end
            end
            if added == 0 then
                notify("Unit Replace", "The code has no valid units", 4)
                return
            end
            table.sort(spots.mowers, function(a, b) return a.id < b.id end)
            saveSpots()
            rebuildMower()
            refreshMowerFloat()
            codeBox.Text = ""
        end)
    end
end

do
    local page = EP.page
    local UTTM_BLUE, UTTM_VIOLET = EP.UTTM_BLUE, EP.UTTM_VIOLET
    local findUttm = EP.findUttm

    do

    local SPW_NAME = "Speaker Woman 2.0"
    local SPW_DARK = Color3.fromRGB(150, 24, 44)
    local SPW_PINK = Color3.fromRGB(255, 176, 208)

    local function ownedTowers(name)
        local out = {}
        local folder = workspace:FindFirstChild("Towers")
        if folder then
            for _, t in ipairs(folder:GetChildren()) do
                if t.Name == name and t:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
                    out[#out + 1] = t
                end
            end
        end
        return out
    end

    local function uttmSpin()
        local tw = findUttm()
        if not tw then return false end
        local ok, res = invoke("CinemaRelocate", "Spin", tw, nil)
        return accepted(ok, res)
    end

    local function spwUse()
        for _, tw in ipairs(ownedTowers(SPW_NAME)) do
            invoke("UseTowerAbility", tw)
        end
    end

    local abilityCard = createCard(page, 112)
    abilityCard.Visible = false
    make("TextLabel", {
        Size = UDim2.new(0, 150, 0, 34),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "Auto use ability",
        TextColor3 = C.text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, abilityCard)

    local abilityRows = {}
    local function allOn()
        local any = false
        for _, r in ipairs(abilityRows) do
            if r.frame.Visible then
                any = true
                if not r.sw.state then return false end
            end
        end
        return any
    end

    local allBtn
    local function refreshAll()
        if allBtn then allBtn.Text = allOn() and "Disable all" or "Enable all" end
    end

    local function makeSwitch(parent, onChange)
        local track = make("Frame", {
            Size = UDim2.new(0, 34, 0, 16),
            Position = UDim2.new(1, -48, 0, 9),
            BackgroundColor3 = T(Color3.fromRGB(34, 34, 37), "bg"),
            BorderSizePixel = 0,
        }, parent)
        local stroke = make("UIStroke", {
            Color = C.controlLine, Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }, track)
        local knob = make("Frame", {
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(0, 3, 0.5, -5),
            BackgroundColor3 = C.muted,
            BorderSizePixel = 0,
        }, track)
        local hit = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2,
        }, parent)
        local api = { state = false }
        function api.set(v, animate)
            api.state = v and true or false
            local tc = api.state and T(Color3.fromRGB(232, 232, 234), "bg") or T(Color3.fromRGB(34, 34, 37), "bg")
            local kc = api.state and T(Color3.fromRGB(14, 14, 15), "bg") or C.muted
            local sc = api.state and tc or C.controlLine
            local kp = api.state and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
            if animate then
                tween(track, 0.12, { BackgroundColor3 = tc })
                tween(stroke, 0.12, { Color = sc })
                tween(knob, 0.12, { BackgroundColor3 = kc, Position = kp })
            else
                track.BackgroundColor3, stroke.Color = tc, sc
                knob.BackgroundColor3, knob.Position = kc, kp
            end
        end
        hit.MouseButton1Click:Connect(function()
            api.set(not api.state, true)
            refreshAll()
            if onChange then onChange(api.state) end
        end)
        return api
    end

    local TS = game:GetService("TextService")
    local function addAbilityRow(word, c1, c2, abilityText, found, onChange)
        local frame = make("Frame", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 1,
            Visible = false,
        }, abilityCard)
        local wordW = TS:GetTextSize(word, 12, Enum.Font.GothamBold, Vector2.new(400, 40)).X
        local wl = make("TextLabel", {
            Size = UDim2.new(0, wordW + 4, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = word, TextColor3 = C.hi, TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, frame)
        local grad = make("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = 0 }, wl)
        make("TextLabel", {
            Size = UDim2.new(1, -(12 + wordW + 14 + 56), 1, 0),
            Position = UDim2.new(0, 12 + wordW + 10, 0, 0),
            BackgroundTransparency = 1,
            Text = abilityText, TextColor3 = C.muted, TextSize = 10,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, frame)
        local row = { frame = frame, sw = makeSwitch(frame, onChange), grad = grad,
            c1 = c1, c2 = c2, found = found }
        abilityRows[#abilityRows + 1] = row
        return row
    end

    local autoSword, autoSpinner = false, false
    addAbilityRow("UTTM", UTTM_BLUE, UTTM_VIOLET, "Spin ability",
        function() return findUttm() ~= nil end,
        function(v) autoSword = v end)
    addAbilityRow("SPW2.0", SPW_DARK, SPW_PINK, "Spinner ability",
        function() return #ownedTowers(SPW_NAME) > 0 end,
        function(v) autoSpinner = v end)

    allBtn = createButton(abilityCard, {
        Size = UDim2.new(0, 84, 0, 24),
        Position = UDim2.new(1, -96, 0, 5),
    }, "Enable all", function()
        local target = not allOn()
        for i, r in ipairs(abilityRows) do
            if r.frame.Visible then
                r.sw.set(target, true)
                if i == 1 then autoSword = target else autoSpinner = target end
            end
        end
        refreshAll()
    end)

    runLoop(function()
        local k = (math.sin(os.clock() * 0.9) + 1) / 2
        for _, r in ipairs(abilityRows) do
            local a, b = r.c1:Lerp(r.c2, k), r.c1:Lerp(r.c2, 1 - k)
            r.grad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, a),
                ColorSequenceKeypoint.new(0.5, a:Lerp(b, 0.5)),
                ColorSequenceKeypoint.new(1, b),
            })
        end
        return 0.05
    end)

    runLoop(function()
        local n = 0
        for _, r in ipairs(abilityRows) do
            local has = r.found()
            if r.frame.Visible ~= has then r.frame.Visible = has end
            if has then
                r.frame.Position = UDim2.new(0, 0, 0, 38 + n * 34)
                n = n + 1
            end
        end
        local h = n > 0 and (38 + n * 34 + 8) or 34
        if abilityCard.Visible ~= (n > 0) then abilityCard.Visible = n > 0 end
        abilityCard.Size = UDim2.new(1, 0, 0, h)
        refreshAll()
        return 0.5
    end)

    runLoop(function()
        if autoSword and not EP.isBusy() and findUttm() then pcall(uttmSpin) end
        if autoSpinner then pcall(spwUse) end
        return 1
    end)
    end
end

do
    local page = tabs["Macro"].page
    local inMatch = (game.PlaceId == MATCH_PLACE)
    local MACRO_INDEX = FS.index()

    local mstate = env.LightHubMacroState
    if not mstate then
        mstate = { rec = nil, handler = nil, hooked = false }
        env.LightHubMacroState = mstate
    end

    local function macroFile(name)
        return FS.macro(name)
    end

    local function cleanName(s)
        s = string.gsub(tostring(s or ""), "[^%w_%- ]", "")
        s = string.gsub(s, "^%s+", "")
        s = string.gsub(s, "%s+$", "")
        return string.sub(s, 1, 24)
    end

    local function badName(name)
        return name == "" or string.lower(name) == "index" or string.lower(name) == "_index"
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
                if FS.dir then
                    for _, path in ipairs(listfiles(FS.root .. "/Macros")) do
                        add(string.match(path, "([^/\\]+)%.json$"))
                    end
                else
                    for _, path in ipairs(listfiles("")) do
                        add(string.match(path, "LightHub_Macro_(.+)%.json$"))
                    end
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

            elseif type(a.n) ~= "string" then
                return false
            elseif a.t == "place" then
                if not isNums(a.cf, 12) then return false end
            elseif a.t == "up" or a.t == "sell" then
                if not isNums(a.p, 3) then return false end
            elseif a.t == "drone" then
                if a.on ~= nil and type(a.on) ~= "boolean" then return false end
            elseif a.t == "target" then
                if not isNums(a.p, 3) then return false end
                if a.m ~= nil and type(a.m) ~= "string" and type(a.m) ~= "number" then return false end
            else
                return false
            end
        end
        return true
    end

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
            notify("Macro", "This executor can't write files", 4)
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

    local function stripUttm(m)
        local keep, removed = {}, 0
        for _, a in ipairs(m.actions) do
            if a.t == "sell" and a.n == UTTM_NAME then
                removed = removed + 1
            else
                keep[#keep + 1] = a
            end
        end
        m.actions = keep
        return removed
    end

    local function loadMacro(name)
        if not (canFile and name ~= "" and isfile(macroFile(name))) then return nil end
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(macroFile(name))) end)
        if ok and validMacro(data) then
            stripUttm(data)
            return data
        end
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

    local function findTower(name, x, z, r)

        if name == UTTM_NAME and EP.findUttm then return EP.findUttm() end
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

    local function saveCurrentRec()
        local rec = mstate.rec
        if not rec then return end
        local acts = {}
        for _, a in ipairs(rec.actions) do
            acts[#acts + 1] = { t = a.t, n = a.n, w = a.w, cf = a.cf, p = a.p, on = a.on, m = a.m }
        end
        saveMacro(rec.name, { v = 1, name = rec.name, actions = acts })
    end

    local function stopRecording()
        local rec = mstate.rec
        if not rec then return end
        saveCurrentRec()
        mstate.rec = nil
        notify("Macro saved", "'" .. rec.name .. "': " .. #rec.actions .. " actions", 4)
    end

    function mstate.modeOf(tw)
        for name, v in pairs(tw:GetAttributes()) do
            if (type(v) == "string" or type(v) == "number") and string.find(string.lower(name), "target", 1, true) then
                return v
            end
        end
        return nil
    end

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
        elseif nm == "Drones" then

            local tw = a2
            if typeof(tw) ~= "Instance" or not EP.droneOn then return end
            local before = EP.droneOn(tw)
            local now = before
            for _ = 1, 8 do
                task.wait(0.25)
                now = EP.droneOn(tw)
                if now ~= before then break end
            end
            if now == before then now = not before end
            act = { t = "drone", n = tw.Name, on = now, w = w }
        elseif nm == "ChangeTargetMode" then
            if typeof(a1) ~= "Instance" then return end
            local okp, pos = pcall(function() return a1:GetPivot().Position end)
            if not okp then return end
            local before = mstate.modeOf(a1)
            local mode = before
            for _ = 1, 8 do
                task.wait(0.25)
                if not a1.Parent then return end
                mode = mstate.modeOf(a1)
                if mode ~= before then break end
            end
            if mode == before then mode = nil end
            act = { t = "target", n = a1.Name, p = { pos.X, pos.Y, pos.Z }, m = mode, w = w }
        else
            if typeof(a1) ~= "Instance" then return end
            if a1.Name == UTTM_NAME and nm == "SellTower" then return end
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

    mstate.push = function(act)
        local rec = mstate.rec
        if not rec or act.n == UTTM_NAME then return end
        act.ts = os.clock()
        table.insert(rec.actions, act)
        table.sort(rec.actions, function(x, y) return x.ts < y.ts end)
        saveCurrentRec()
    end

    local function installHook()
        if not (hookmetamethod and newcclosure and getnamecallmethod) then return false end
        if mstate.hooked and mstate.hookV2 then return true end

        local full = not mstate.hooked
        local ok = pcall(function()
            local orig
            orig = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if method == "InvokeServer" and (mstate.rec or placeHook.active)
                    and typeof(self) == "Instance" and self.ClassName == "RemoteFunction" then
                    local nm = self.Name
                    local extra = (nm == "ChangeTargetMode") or (nm == "CinemaRelocate" and (...) == "Drones")
                    if extra or (full and (nm == "PlaceTower" or nm == "UpgradeTower" or nm == "SellTower")) then
                        local a1, a2 = ...
                        if not (checkcaller and checkcaller()) then
                            local key = (nm == "CinemaRelocate") and "Drones" or nm
                            local h = mstate.handler
                            if mstate.rec and h then task.defer(h, key, a1, a2) end
                            local ph = placeHook.handler
                            if not extra and placeHook.active and ph then task.defer(ph, nm, a1, a2) end
                        end
                    end
                end
                if setnamecallmethod then setnamecallmethod(method) end
                return orig(self, ...)
            end))
        end)
        mstate.hooked = mstate.hooked or ok
        mstate.hookV2 = ok
        return ok
    end

    placeHook.install = installHook

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

    local mk = createFeature(page, "Make Macro", { noToggle = true, bodyHeight = 28 })
    local mkInput = createInput(mk.body, { Size = UDim2.new(1, -86, 1, 0) }, "Macro name")
    createButton(mk.body, {
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -80, 0, 0),
    }, "Create", function()
        local name = cleanName(mkInput.Text)
        if badName(name) then
            notify("Macro", "Enter a valid macro name", 3)
            return
        end
        if canFile and isfile(macroFile(name)) then
            notify("Macro", "A macro with that name already exists", 3)
            return
        end
        if saveMacro(name, { v = 1, name = name, actions = {} }) then
            mkInput.Text = ""
            setFlag("macroSelected", name)
            selFile.set(name)
            refreshSel()
        end
    end)

    local fileCard = createFeature(page, "Macro File", { noToggle = true, bodyHeight = 28 })
    selFile = createSelect(fileCard.body, {
        Size = UDim2.new(1, -86, 1, 0),
    }, {
        initial = flags.macroSelected ~= "" and flags.macroSelected or nil,
        placeholder = "Select a macro",
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
            notify("Macro", "Select a macro to delete first", 3)
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
    end)

    fRec = createFeature(page, "Record Macro", {
        bodyHeight = 16,
        initial = flags.macroRecord,
        onToggle = function(v)
            if v then
                if flags.macroSelected == "" then
                    fRec.set(false)
                    notify("Macro", "Select or create a macro first", 3)
                    return
                end
                if not installHook() then
                    fRec.set(false)
                    notify("Macro", "Recording isn't supported on this executor", 5)
                    return
                end
                setFlag("macroRecord", true)
                if flags.macroPlay then
                    setFlag("macroPlay", false)
                    fPlay.set(false)
                end
                if not inMatch then
                    notify("Macro", "Recording starts when the match begins", 3)
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

    fPlay = createFeature(page, "Playback Macro", {
        initial = flags.macroPlay,
        onToggle = function(v)
            if v then
                if flags.macroSelected == "" then
                    fPlay.set(false)
                    notify("Macro", "Select a macro first", 3)
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

    do
        local o = mk.card.LayoutOrder
        fileCard.card.LayoutOrder = o
        fRec.card.LayoutOrder = o + 1
        fPlay.card.LayoutOrder = o + 2
        mk.card.LayoutOrder = o + 3
    end

    local share = createFeature(tabs["Share"].page, "Share Macro", { noToggle = true, bodyHeight = 28 })
    share.card.LayoutOrder = 100
    local shareSel = createSelect(share.body, {
        Size = UDim2.new(1, -96, 1, 0),
    }, {
        placeholder = "Select a macro",
        getOptions = macroOptions,
        emptyMsg = "No macros yet. Create or import one first.",
    })
    createButton(share.body, {
        Size = UDim2.new(0, 90, 1, 0),
        Position = UDim2.new(1, -90, 0, 0),
    }, "Copy JSON", function()
        local name = shareSel.get()
        if not name or name == "" then
            notify("Macro", "Select a macro to share first", 3)
            return
        end
        local m = loadMacro(name)
        if not m then
            notify("Macro", "Couldn't read that macro", 3)
            return
        end
        if not setclipboard then
            notify("Macro", "This executor can't copy to the clipboard", 4)
            return
        end
        pcall(setclipboard, HttpService:JSONEncode({ v = 1, name = name, actions = m.actions }))
    end)

    local imp = createFeature(tabs["Share"].page, "Import Macro", { noToggle = true, bodyHeight = 108 })
    imp.card.LayoutOrder = 102
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
            notify("Macro", "Paste the macro JSON first", 3)
            return
        end
        local ok, data = pcall(function() return HttpService:JSONDecode(text) end)
        if ok and type(data) == "table" and data.Actions then
            data = convertForeign(data)
        end
        if not ok or not validMacro(data) then
            staged = nil
            notify("Macro", "That isn't a valid macro JSON", 4)
            return
        end
        local removed = stripUttm(data)
        staged = data
        if nameBox.Text == "" and type(data.name) == "string" then
            nameBox.Text = cleanName(data.name)
        end
        local extra = removed > 0 and (" (" .. removed .. " UTTM sell actions skipped)") or ""
    end)

    createButton(imp.body, {
        Size = UDim2.new(0, 80, 0, 28),
        Position = UDim2.new(1, -80, 0, 78),
    }, "Save", function()
        if not staged then
            notify("Macro", "Press Import first", 3)
            return
        end
        local name = cleanName(nameBox.Text)
        if badName(name) then
            notify("Macro", "Enter a valid macro name", 3)
            return
        end
        if saveMacro(name, { v = 1, name = name, actions = staged.actions }) then
            staged = nil
            jsonBox.Text = ""
            nameBox.Text = ""
            setFlag("macroSelected", name)
            selFile.set(name)
            refreshSel()
        end
    end)

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
            fRec.setNote("")
            return 1.5
        end
        local rec = mstate.rec
        if not rec or rec.name ~= sel or rec.job ~= game.JobId then
            if not installHook() then
                fRec.setNote("Recording not supported", C.warn)
                return 3
            end
            local prev = loadMacro(sel)
            mstate.rec = { name = sel, job = game.JobId, actions = {} }
            mstate.handler = onCall
            saveCurrentRec()
            rec = mstate.rec
            if prev and #prev.actions > 0 then
                notify("Macro", "Recording started: '" .. sel .. "'. The old recording was replaced", 5)
            else
                notify("Macro", "Recording started: '" .. sel .. "'", 3)
            end
        end
        fRec.setNote("Recording (" .. #rec.actions .. " actions)", C.text)
        return 0.5
    end)

    runLoop(function()
        if not flags.macroPlay then
            play.idx, play.macro = 1, nil
            fPlay.setNote("")
            return 0.5
        end
        if not inMatch then
            fPlay.setNote("")
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
            play.notified = nil
            play.skips = 0
            play.stepSince = nil
            if not play.macro then
                play.name = nil
                fPlay.setNote("Macro load failed", C.warn)
                return 2
            end
            notify("Macro", "Playback started: '" .. sel .. "'", 3)
        end

        local acts = play.macro.actions
        local a = acts[play.idx]
        if not a then
            fPlay.setNote("Macro finished", C.text)
            if not play.notified then
                play.notified = true
                notify("Macro", "Playback finished", 3)
            end
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
        if a.t == "wait" or (a.n == UTTM_NAME and a.t == "sell") then
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
        elseif a.t == "drone" then
            local tw = EP.findUttm and EP.findUttm()
            if not tw then
                fPlay.setNote("Waiting for " .. a.n, C.muted)
            elseif not EP.setDrone then
                done = true
            else
                local want = a.on
                if want == nil then want = not EP.droneOn(tw) end
                done = EP.setDrone(tw, want) == true
                task.wait(0.3)
            end
        elseif a.t == "target" then
            local tw = findTower(a.n, a.p[1], a.p[3], 4)
            if not tw then
                fPlay.setNote("Waiting for " .. a.n, C.muted)
            else
                if a.m ~= nil and mstate.modeOf(tw) ~= nil then
                    for _ = 1, 8 do
                        if mstate.modeOf(tw) == a.m then break end
                        invoke("ChangeTargetMode", tw)
                        task.wait(0.35)
                    end
                else
                    invoke("ChangeTargetMode", tw)
                    task.wait(0.3)
                end
                done = true
            end
        else
            local tw = findTower(a.n, a.p[1], a.p[3], 4)
            if a.t == "up" then
                if not tw then
                    fPlay.setNote("Waiting for " .. a.n, C.muted)
                else
                    local price = tw:GetAttribute("UpgradePrice")
                    if type(price) ~= "number" or price <= 0 then
                        done = true
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
                    done = true
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
            play.skips = 0
            fPlay.setNote("Playing " .. math.min(play.idx, #acts) .. "/" .. #acts, C.text)
            return 0.3
        end
        if os.clock() - play.stepSince > 90 + (a.d or 0) then
            notify("Macro", "Skipped step " .. play.idx .. ": it couldn't be completed in 90s", 4)
            play.skips = (play.skips or 0) + 1
            if play.skips == 3 then
                notify("Macro", "Several steps failed in a row. Check your cash and unit slots.", 6)
            end
            play.idx = play.idx + 1
            play.stepSince = nil
        end
        return 0.7
    end)
end

do
    local page = tabs["AFK"].page
    local GIFT_COUNT = 9
    local claimedCount = 0
    local applyClaimState

    local feature = createFeature(page, "Auto Claim Playtime Gift", {
        bodyHeight = 26,
        onToggle = function(v) applyClaimState(v, true) end,
    })

    local giftOpen, giftRows = false, 1
    local rewards, lastClaimAt, lastClaimIndex, giftSig = {}, nil, nil, nil

    local CountLabel = make("TextLabel", {
        Size = UDim2.new(1, -110, 0, 24),
        BackgroundTransparency = 1,
        RichText = true,
        Text = "",
        TextColor3 = C.hi,
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
                BackgroundColor3 = T(Color3.fromRGB(24, 24, 27), "bg"),
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

    bindEvent("Notify", function(text)
        if type(text) ~= "string" or not lastClaimAt or not lastClaimIndex then return end
        if os.clock() - lastClaimAt > 3 or rewards[lastClaimIndex] then return end
        local clean = (string.gsub(text, "<[^>]+>", ""))
        if string.find(clean, "Auto Sell", 1, true) then return end
        rewards[lastClaimIndex] = string.sub(clean, 1, 60)
    end)

    local function setStatus() end
    renderGifts()

    local function popcount(mask)
        local n = 0
        for i = 0, GIFT_COUNT - 1 do
            if math.floor(mask / (2 ^ i)) % 2 == 1 then n = n + 1 end
        end
        return n
    end

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

    local lastLocked = nil
    local function refreshLock()
        local id = readGameDay()

        local locked = (id == nil) and not run.claim
        if locked ~= lastLocked then
            lastLocked = locked
            if locked then
                feature.setLocked(true)
            else
                feature.setLocked(false)
            end
        end
    end
    refreshLock()

    local wantAutoStart = settings.claimEnabled
    local lastValidDay, staleMask, backoff = nil, nil, 5

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
        if not remote then return 2 end
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

            if readGameDay() ~= day then break end

            lastClaimAt, lastClaimIndex = os.clock(), giftIndex
            local ok, res = pcall(function()
                return remote:InvokeServer(giftIndex, day)
            end)
            if ok and res == true then
                claimedCount = giftIndex
                claimedAny = true
            end
            if giftIndex < lastIdx then task.wait(0.5) end
        end
        renderGifts()

        if claimedAny then
            backoff = 5
            return 1.5
        end
        if run.claim and claimedCount < GIFT_COUNT and readGameDay() == day then

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
end

do
    local page = tabs["AFK"].page
    local MAX_LEVEL = 50
    local wasOn = false

    local feat = visualFeature(page, "Auto Claim Pass", "autoSeason", 0)

    local function seasonData()
        local ok, res = invoke("GetData")
        local sp = ok and type(res) == "table" and res.SeasonPass or nil
        if type(sp) == "table" then return sp end
        return nil
    end
    local function isClaimed(map, level)
        return type(map) == "table" and (map[level] == true or map[tostring(level)] == true)
    end

    local function sweep(sp)
        local tracks = { { "Free", sp.ClaimedFree } }
        if sp.Premium ~= false then
            tracks[#tracks + 1] = { "Premium", sp.ClaimedPremium }
        end
        for _, tr in ipairs(tracks) do
            for level = 1, MAX_LEVEL do
                if not flags.autoSeason or not ScreenGui.Parent then return end
                if not isClaimed(tr[2], level) then
                    local ok, res = invoke("ClaimSeasonReward", level, tr[1])
                    task.wait(0.15)
                    local good = ok and (res == true
                        or (type(res) == "table" and (res.Success == true or res.success == true)))
                    if not good then

                        local fresh = seasonData()
                        local map = fresh and (tr[1] == "Free" and fresh.ClaimedFree or fresh.ClaimedPremium)
                        good = isClaimed(map, level)
                    end
                    if not good then break end
                end
            end
        end
    end

    local wake, nextAt = false, 0
    bindEvent("SeasonPassStateUpdated", function() wake = true end)
    runLoop(function()
        if not flags.autoSeason then
            wasOn = false
            return 0.5
        end
        if not RF("ClaimSeasonReward") then return 3 end
        if not wasOn then
            wasOn = true
            nextAt = 0
        end
        if not wake and os.clock() < nextAt then return 0.3 end
        if wake then task.wait(0.3) end
        wake = false
        nextAt = os.clock() + 8
        local sp = seasonData()
        if not sp then
            nextAt = os.clock() + 3
            return 0.3
        end
        sweep(sp)
        return 0.3
    end)
end

do
    local page = tabs["AFK"].page
    local feat = visualFeature(page, "Auto Claim Quests", "autoQuest", 0)

    local tried = {}

    local function claim(remote, ...)
        if not flags.autoQuest or not ScreenGui.Parent then return end
        local parts = { remote }
        for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
        local key = table.concat(parts, "|")
        if tried[key] and os.clock() - tried[key] < 60 then return end
        tried[key] = os.clock()
        invoke(remote, ...)
        task.wait(0.4)
    end

    local function eachReady(slots, fn)
        if type(slots) ~= "table" then return end
        for _, q in ipairs(slots) do
            if type(q) == "table" and type(q.InstanceId) == "string" and type(q.Index) == "number"
                and type(q.Progress) == "number" and type(q.Target) == "number"
                and q.Claimed ~= true and q.Progress >= q.Target then
                fn(q)
            end
        end
    end

    local function sweepDaily()
        if not RF("ClaimQuest") then return end
        local ok, st = invoke("GetQuestState")
        if ok and type(st) == "table" then
            eachReady(st.Slots, function(q) claim("ClaimQuest", q.Index, q.InstanceId) end)
        end
    end

    local function sweepHalloween()
        if not RF("ClaimHalloweenQuest") then return end
        local ok, st = invoke("GetHalloweenQuestState")
        if ok and type(st) == "table" and st.Enabled ~= false and type(st.Tracks) == "table" then
            for _, tr in ipairs(st.Tracks) do
                if type(tr) == "table" and type(tr.Id) == "string" then
                    eachReady(tr.Slots, function(q) claim("ClaimHalloweenQuest", tr.Id, q.Index, q.InstanceId) end)
                end
            end
        end
    end

    local function globalId(t)
        for _, v in pairs(t) do
            if type(v) == "string" and string.find(v, "global_quests", 1, true) then return v end
        end
        if type(t.TierId) == "string" and type(t.StartedAt) == "number" and type(t.EndsAt) == "number"
            and t.EndsAt > t.StartedAt then
            return string.format("global_quests_v3:%s:%d", t.TierId, math.floor(t.StartedAt / (t.EndsAt - t.StartedAt)))
        end
        return nil
    end

    local function sweepGlobal()
        if not RF("ClaimGlobalQuest") then return end
        local ok, st = invoke("GetGlobalQuestState")
        if not ok or type(st) ~= "table" or type(st.Tiers) ~= "table" then return end
        for _, name in ipairs(type(st.Order) == "table" and st.Order or { "Hourly", "Daily", "Weekly" }) do
            local t = st.Tiers[name]
            if type(t) == "table" and t.Claimed ~= true and t.Available ~= false and t.Eligible ~= false
                and type(t.Progress) == "number" then

                local target = tonumber(t.Target) or tonumber(string.match(tostring(t.QuestId or ""), "(%d+)$"))
                local id = globalId(t)
                if target and id and t.Progress >= target then claim("ClaimGlobalQuest", name, id) end
            end
        end
    end

    local wake, nextAt, wasOn = false, 0, false
    for _, ev in ipairs({ "QuestStateUpdated", "HalloweenQuestStateUpdated", "GlobalQuestStateUpdated" }) do
        bindEvent(ev, function() wake = true end)
    end
    runLoop(function()
        if not flags.autoQuest then
            wasOn = false
            return 0.5
        end
        if not wasOn then
            wasOn = true
            nextAt = 0
        end
        if not wake and os.clock() < nextAt then return 0.3 end
        if wake then task.wait(0.4) end
        wake = false
        nextAt = os.clock() + 20
        pcall(sweepDaily)
        pcall(sweepHalloween)
        pcall(sweepGlobal)
        return 0.3
    end)
end

local ANIM_EVENTS = {
    crate = { "CrateOpening", "LuckyBlockOpening" },
    summon = { "MythicSummoned" },

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

runLoop(function()
    if settings.skipAnim then
        applySkip("crate", true)
        applySkip("summon", true)
        applySkip("uttm", true)
    end
    return 3
end)

do
    local page = tabs["Settings"].page

    local themeCard = createFeature(page, "Theme", { noToggle = true, bodyHeight = 28 })
    themeCard.card.LayoutOrder = -3
    ui.themeSeg = createSegmented(themeCard.body, {
        Size = UDim2.new(1, 0, 1, 0),
    }, {
        { label = "Default", value = "Default" },
        { label = "Halloween", value = "Halloween" },
    }, settings.theme, function(v)
        ui.applyTheme(v)
    end)

    createFeature(page, "Show Timer", {
        initial = settings.showTimer,
        onToggle = function(v)
            settings.showTimer = v
            applyTimerVisibility()
            if ui.relayoutMini then ui.relayoutMini() end
            saveSettings()
        end,
    })

    local fSkipAnim
    fSkipAnim = createFeature(tabs["Gacha"].page, "Skip Gacha Animation", {
        initial = settings.skipAnim,
        onToggle = function(v)
            settings.skipAnim = v
            saveSettings()
            if getconnections then
                applySkip("crate", v)
                applySkip("summon", v)
            elseif v then
                notify("Skip Gacha Animation", "Animations can't be hidden here. Only the spin gets faster.", 5)
            end
        end,
    })

    do
        local page = tabs["Settings"].page
        local Lighting = game:GetService("Lighting")

        local FX = {
            ParticleEmitter = true, Trail = true, Beam = true, Smoke = true,
            Fire = true, Sparkles = true, PointLight = true, SpotLight = true,
            SurfaceLight = true, Highlight = true,
        }
        local POST = {
            BloomEffect = true, BlurEffect = true, SunRaysEffect = true,
            ColorCorrectionEffect = true, DepthOfFieldEffect = true, Atmosphere = true,
        }

        local saved = setmetatable({}, { __mode = "k" })
        local npcs = setmetatable({}, { __mode = "k" })
        local postSaved = {}
        local envSaved = nil
        local conn = nil
        local active = false
        local token = 0
        local touched = 0
        local feat

        local function inCharacter(inst)
            local m = inst:FindFirstAncestorOfClass("Model")
            return m ~= nil and m:FindFirstChildOfClass("Humanoid") ~= nil
        end

        local function handle(inst)
            if saved[inst] then return end
            local cn = inst.ClassName
            if FX[cn] then
                local rec = { kind = "fx", v = inst.Enabled }
                if cn == "ParticleEmitter" then
                    rec.rate, rec.life = inst.Rate, inst.Lifetime
                    inst.Rate = 0
                    inst.Lifetime = NumberRange.new(0)
                end
                saved[inst] = rec
                inst.Enabled = false
                touched = touched + 1
            elseif cn == "Explosion" then
                saved[inst] = { kind = "expl", v = inst.Visible }
                inst.Visible = false
                touched = touched + 1
            elseif cn == "Decal" or cn == "Texture" then
                if inCharacter(inst) then return end
                saved[inst] = { kind = "decal", v = inst.Transparency }
                inst.Transparency = 1
                touched = touched + 1
            elseif cn == "Humanoid" then
                local tw = workspace:FindFirstChild("Towers")
                if tw and inst:IsDescendantOf(tw) then return end
                if not Players:GetPlayerFromCharacter(inst.Parent) then npcs[inst] = true end
            elseif inst:IsA("BasePart") and not inst:IsA("Terrain") then
                if inCharacter(inst) then return end
                local rec = { kind = "part", m = inst.Material, s = inst.CastShadow, r = inst.Reflectance }
                if inst:IsA("MeshPart") then rec.f = inst.RenderFidelity end
                saved[inst] = rec
                inst.CastShadow = false
                inst.Reflectance = 0
                if inst.Material ~= Enum.Material.SmoothPlastic then
                    inst.Material = Enum.Material.SmoothPlastic
                end
                if rec.f then inst.RenderFidelity = Enum.RenderFidelity.Performance end
                touched = touched + 1
            end
        end

        local function restore(inst, rec)
            if not inst.Parent then return end
            local k = rec.kind
            if k == "fx" then
                if rec.rate then
                    inst.Rate = rec.rate
                    inst.Lifetime = rec.life
                end
                inst.Enabled = rec.v
            elseif k == "expl" then
                inst.Visible = rec.v
            elseif k == "decal" then
                inst.Transparency = rec.v
            else
                inst.CastShadow = rec.s
                inst.Reflectance = rec.r
                inst.Material = rec.m
                if rec.f then inst.RenderFidelity = rec.f end
            end
        end

        local function renderSettings()
            local ok, r = pcall(function() return getrenv().settings().Rendering end)
            if ok and r then return r end
            ok, r = pcall(function() return getgenv().settings().Rendering end)
            if ok and r then return r end
            return nil
        end

        local function enable()
            token = token + 1
            local my = token
            active = true
            touched = 0

            if not envSaved then
                envSaved = {}
                pcall(function() envSaved.shadows = Lighting.GlobalShadows end)
                pcall(function()
                    local ugs = UserSettings():GetService("UserGameSettings")
                    envSaved.quality = ugs.SavedQualityLevel
                end)
                local r = renderSettings()
                if r then
                    pcall(function() envSaved.mesh = r.MeshPartDetailLevel end)
                    pcall(function() envSaved.rq = r.QualityLevel end)
                end
                local t = workspace:FindFirstChildOfClass("Terrain")
                if t then
                    pcall(function()
                        envSaved.terrain = {
                            t.Decoration, t.WaterWaveSize, t.WaterWaveSpeed, t.WaterReflectance,
                        }
                    end)
                end
            end

            pcall(function() Lighting.GlobalShadows = false end)
            pcall(function()
                UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
            end)
            local r = renderSettings()
            if r then
                pcall(function() r.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04 end)
                pcall(function() r.QualityLevel = Enum.QualityLevel.Level01 end)
            end
            local t = workspace:FindFirstChildOfClass("Terrain")
            if t then
                pcall(function()
                    t.Decoration = false
                    t.WaterWaveSize = 0
                    t.WaterWaveSpeed = 0
                    t.WaterReflectance = 0
                end)
            end

            for _, holder in ipairs({ Lighting, workspace.CurrentCamera }) do
                if holder then
                    for _, e in ipairs(holder:GetChildren()) do
                        if POST[e.ClassName] and postSaved[e] == nil then
                            pcall(function()
                                postSaved[e] = e.Enabled
                                e.Enabled = false
                            end)
                        end
                    end
                end
            end

            if game.PlaceId == MATCH_PLACE then
                task.spawn(function()
                    for _, opt in ipairs({ "VFX", "HealthIndicator", "SFX" }) do
                        for _ = 1, 3 do
                            if my ~= token or not active then return end
                            local ok = invoke("SetOption", opt, false)
                            if ok then break end
                            task.wait(1)
                        end
                        task.wait(0.2)
                    end
                end)
            end

            if conn then conn:Disconnect() end
            conn = workspace.DescendantAdded:Connect(function(inst)
                if active then pcall(handle, inst) end
            end)

            task.spawn(function()
                local list = workspace:GetDescendants()
                for i, inst in ipairs(list) do
                    if my ~= token or not active then return end
                    pcall(handle, inst)
                    if i % 200 == 0 then task.wait() end
                end
            end)
        end

        local function disable()
            token = token + 1
            active = false
            if conn then conn:Disconnect() conn = nil end
            if envSaved then
                local e = envSaved
                envSaved = nil
                pcall(function() if e.shadows ~= nil then Lighting.GlobalShadows = e.shadows end end)
                pcall(function()
                    if e.quality then
                        UserSettings():GetService("UserGameSettings").SavedQualityLevel = e.quality
                    end
                end)
                local r = renderSettings()
                if r then
                    pcall(function() if e.mesh then r.MeshPartDetailLevel = e.mesh end end)
                    pcall(function() if e.rq then r.QualityLevel = e.rq end end)
                end
                local t = workspace:FindFirstChildOfClass("Terrain")
                if t and e.terrain then
                    pcall(function()
                        t.Decoration, t.WaterWaveSize, t.WaterWaveSpeed, t.WaterReflectance =
                            e.terrain[1], e.terrain[2], e.terrain[3], e.terrain[4]
                    end)
                end
            end
            for e, v in pairs(postSaved) do
                pcall(function() if e.Parent then e.Enabled = v end end)
                postSaved[e] = nil
            end
            local my = token
            task.spawn(function()
                local n = 0
                for inst, rec in pairs(saved) do
                    if my ~= token then return end
                    pcall(restore, inst, rec)
                    saved[inst] = nil
                    n = n + 1
                    if n % 200 == 0 then task.wait() end
                end
            end)
            if feat then feat.setNote("") end
        end

        feat = createFeature(page, "Anti Lag", {
            initial = flags.antiLag,
            onToggle = function(v)
                setFlag("antiLag", v)
                if v then enable() else disable() end
            end,
        })
        if flags.antiLag then enable() end

        runLoop(function()
            if not active then return 1 end
            local n = 0
            for h in pairs(npcs) do
                if h.Parent then n = n + 1 else npcs[h] = nil end
            end
            if feat then feat.setNote("Active", C.muted) end
            return 2
        end)

        EP.antiLagOff = function()
            if active then pcall(disable) end
        end
    end

    local fAutoMin = createFeature(page, "Auto Minimize", {
        initial = settings.autoMinimize,
        onToggle = function(v)
            settings.autoMinimize = v
            saveSettings()
            ui.poke()
        end,
    })

    fAutoMin.card.LayoutOrder = 2
    fSkipAnim.card.LayoutOrder = 100

    createFeature(page, "Anti AFK", {
        initial = settings.antiAfk,
        onToggle = function(v)
            settings.antiAfk = v
            saveSettings()
        end,
    })

    local info = createCard(tabs["Profile"].page, 134)
    local avatar = make("Frame", {
        Size = UDim2.new(0, 48, 0, 48),
        Position = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = C.control,
        BorderSizePixel = 0,
    }, info)
    styleControl(avatar)
    make("ImageLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150",
    }, avatar)
    make("TextLabel", {
        Size = UDim2.new(1, -150, 0, 18),
        Position = UDim2.new(0, 70, 0, 11),
        BackgroundTransparency = 1,
        Text = LocalPlayer.DisplayName,
        TextColor3 = C.hi,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, info)
    make("TextLabel", {
        Size = UDim2.new(1, -150, 0, 14),
        Position = UDim2.new(0, 70, 0, 30),
        BackgroundTransparency = 1,
        Text = "@" .. LocalPlayer.Name,
        TextColor3 = C.muted,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, info)
    make("TextLabel", {
        Size = UDim2.new(1, -150, 0, 14),
        Position = UDim2.new(0, 70, 0, 45),
        BackgroundTransparency = 1,
        Text = "ID " .. tostring(LocalPlayer.UserId),
        TextColor3 = C.dim,
        TextSize = 10,
        Font = Enum.Font.RobotoMono,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, info)
    make("TextLabel", {
        Size = UDim2.new(0, 70, 0, 14),
        Position = UDim2.new(1, -82, 0, 14),
        BackgroundTransparency = 1,
        Text = "v" .. VERSION,
        TextColor3 = C.dim,
        TextSize = 10,
        Font = Enum.Font.RobotoMono,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, info)
    make("Frame", {
        Size = UDim2.new(1, -24, 0, 1),
        Position = UDim2.new(0, 12, 0, 72),
        BackgroundColor3 = C.line,
        BorderSizePixel = 0,
    }, info)
    local grid = make("Frame", {
        Size = UDim2.new(1, -24, 0, 46),
        Position = UDim2.new(0, 12, 0, 80),
        BackgroundTransparency = 1,
    }, info)
    local function row(top, defs)
        return createCells(grid, defs, top, 0)
    end
    local r1 = row(0, {
        { caption = "COINS", value = "-" },
        { caption = "WINS", value = "-" },
        { caption = "ENDLESS BEST", value = "-" },
    })

    local function compact(n)
        n = tonumber(n)
        if not n then return "-" end
        if n >= 1e9 then return string.format("%.2fB", n / 1e9) end
        if n >= 1e6 then return string.format("%.2fM", n / 1e6) end
        if n >= 1e4 then return string.format("%.1fK", n / 1e3) end
        return tostring(math.floor(n))
    end
    local function attr(k) return LocalPlayer:GetAttribute(k) end

    runLoop(function()
        r1[1].value.Text = compact(getStatN("Coins"))
        r1[2].value.Text = compact(getStatN("Wins"))
        r1[3].value.Text = tostring(attr("EndlessWeeklyBest") or "-")
        return 3
    end)
end

local towerConns = {}

do
    local watched, towerLevels = {}, {}
    local pendingSells, sellScheduled = 0, false
    local hookedFolder = nil

    local function isMine(t)
        return t:GetAttribute("OwnerUserId") == LocalPlayer.UserId
    end

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

        if waveLabel then
            if waveLabel.Parent and isShown(waveLabel) then
                c0, m0 = labelWave(waveLabel)
                if c0 and m0 then return c0, m0 end
            end
            if not c0 then waveLabel = nil end
        end

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
        ui.setStreak(LocalPlayer:GetAttribute("WinStreak"))
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
    pcall(function() EP.antiLagOff() end)
    if env.LightHubDrone then env.LightHubDrone.active = false end
    pcall(function() idledConn:Disconnect() end)
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    for _, c in pairs(towerConns) do pcall(function() c:Disconnect() end) end
    pcall(function() ScreenGui:Destroy() end)
    if env.AFKHubConn == idledConn then env.AFKHubConn = nil end
    env.LightHubCleanup = nil
end
env.LightHubCleanup = cleanup

local MINI_W = 400
local AUTO_MIN_SECS = 7

local function layoutMini()
    local TS = game:GetService("TextService")
    local function tw(text, size)
        return TS:GetTextSize(text, size, Enum.Font.GothamBold, Vector2.new(400, 40)).X
    end
    local x = 34 + (ui.titleDX or 0) + tw(TitleLabel.Text, 12)
    local waveW = math.max(44, tw("00/00", 14) + 4)
    MiniWave.Position = UDim2.new(0, x + 14, 0, 0)
    MiniWave.Size = UDim2.new(0, waveW, 1, -1)
    x = x + 14 + waveW
    ui.streakBox.Position = UDim2.new(0, x + 14, 0, 0)
    ui.streakBox.Size = UDim2.new(0, 44, 1, -1)
    x = x + 14 + 44
    TitleLabel.TextSize = 12
    if settings.showTimer then
        ui.sepTimer.Position = UDim2.new(0, x + 6, 0.5, -10)
        local timerW = tw("00:00:00", 13) + 2
        TimerLabel.Position = UDim2.new(0, x + 12, 0, 0)
        TimerLabel.Size = UDim2.new(0, timerW, 1, 0)
        TimerLabel.TextXAlignment = Enum.TextXAlignment.Left
        TimerLabel.TextSize = 13
        MINI_W = x + 12 + timerW + 6 + 68
    else

        MINI_W = x + 14 + 68
    end
end

local function restoreFull()
    TimerLabel.Position = UDim2.new(1, -158, 0, 0)
    TimerLabel.Size = UDim2.new(0, 84, 1, 0)
    TimerLabel.TextXAlignment = Enum.TextXAlignment.Right
    TimerLabel.TextSize = 14
    TitleLabel.TextSize = 13
end

local function setMinimized(mini)
    if ui.minimized == mini then return end
    closeOverlay()
    ui.minimized = mini
    Body.Visible = not mini
    MinLine.Visible = not mini
    MinBox.Visible = mini
    VersionLabel.Visible = not mini
    MiniWave.Visible = mini
    ui.showMini(mini)
    MiniBarTrack.Visible = mini
    if mini then layoutMini() else restoreFull() end
    applyTimerVisibility()
    if ui.decorRefresh then ui.decorRefresh() end
    tween(MainFrame, 0.15, {
        Size = mini and UDim2.new(0, MINI_W, 0, HEADER_H) or UDim2.new(0, WIN_W, 0, WIN_H),
    })
    ui.poke()
end
ui.setMinimized = setMinimized
function ui.relayoutMini()
    if not ui.minimized then return end
    layoutMini()
    ui.showMini(true)
    MainFrame.Size = UDim2.new(0, MINI_W, 0, HEADER_H)
end

MinimizeBtn.MouseButton1Click:Connect(function() setMinimized(not ui.minimized) end)

ui.gearBtn.MouseButton1Click:Connect(function()
    if ui.minimized then setMinimized(false) end
    local g = nav.byPage[nav.cur]
    if g == nav.settings then
        selectTab(nav.lastMain)
    else
        selectTab(nav.lastSettings)
    end
end)

runLoop(function()
    if settings.autoMinimize and not ui.minimized and not drag.on
        and os.clock() - ui.lastTouch >= AUTO_MIN_SECS then
        setMinimized(true)
    end
    return 0.5
end)

local closeArmed = false
CloseBtn.MouseButton1Click:Connect(function()
    if not closeArmed then
        closeArmed = true
        for _, b in ipairs(CloseBars) do b.BackgroundColor3 = C.warn end
        notify("Close", "Press X again within 3 seconds to close the script", 3)
        task.delay(3, function()
            closeArmed = false
            for _, b in ipairs(CloseBars) do b.BackgroundColor3 = ui.closeNormal or C.text end
        end)
        return
    end
    notify("Terminated", "Lightn Hub closed. All features stopped.", 2)
    cleanup()
end)

decor.style = "Tree"

function ui.decorRefresh()
    local on = theme.name == "Halloween"

    local minCol = on and Color3.fromRGB(226, 214, 188) or C.text
    ui.closeNormal = on and Color3.fromRGB(196, 52, 16) or C.text
    MinLine.BackgroundColor3 = minCol
    local mst = MinBox:FindFirstChildOfClass("UIStroke")
    if mst then mst.Color = minCol end
    if not closeArmed then
        for _, b in ipairs(CloseBars) do b.BackgroundColor3 = ui.closeNormal end
    end
    local oldDX = ui.titleDX or 0
    ui.titleDX = (on and decor.gearBuddy == "Pumpkin") and 6 or 0
    TitleRow.Position = UDim2.new(0, 34 + ui.titleDX, 0, 0)
    if ui.minimized and oldDX ~= ui.titleDX and ui.relayoutMini then ui.relayoutMini() end
    if ui.gearTheme then ui.gearTheme(on) end
    for _, r in ipairs(decor.roots) do
        r.Visible = on and not (decor.hideMini[r] and ui.minimized)
    end
    if decor.treeBox then decor.treeBox.Visible = (decor.style == "Tree") end
    if decor.leafLayer then decor.leafLayer.Visible = (decor.style == "Tree") end
    for _, tw in ipairs(decor.tweens) do
        if on then tw:Play() else tw:Pause() end
    end
end

table.insert(conns, RunService.Heartbeat:Connect(function(dt)
    if theme.name ~= "Halloween" then return end
    if dt > 0.1 then dt = 0.1 end
    for _, f in ipairs(decor.steppers) do f(dt) end
end))

do
    local themePass = 0
    local function recolor(d, map)
        if d:IsA("GuiObject") then
            local kind = d:FindFirstChildOfClass("UIGradient") and "base" or "bg"
            d.BackgroundColor3 = map(kind, d.BackgroundColor3)
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                d.TextColor3 = map("txt", d.TextColor3)
                if d:IsA("TextBox") then d.PlaceholderColor3 = map("txt", d.PlaceholderColor3) end
            end
            if d:IsA("ScrollingFrame") then d.ScrollBarImageColor3 = map("gen", d.ScrollBarImageColor3) end
        elseif d:IsA("UIStroke") then
            d.Color = map("gen", d.Color)
        elseif d:IsA("UIGradient") then
            local kps = {}
            for i, k in ipairs(d.Color.Keypoints) do
                kps[i] = ColorSequenceKeypoint.new(k.Time, map("gen", k.Value))
            end
            d.Color = ColorSequence.new(kps)
        end
    end

    function ui.applyTheme(name)
        if name ~= "Halloween" then name = "Default" end
        if theme.name == name then return end
        local to = (name == "Halloween")
        theme.name = name
        settings.theme = name
        setPalette(name)

        local skip = {}
        for _, root in ipairs(decor.roots) do
            skip[root] = true
            for _, d in ipairs(root:GetDescendants()) do skip[d] = true end
        end
        if ui.gearBtn then
            for _, d in ipairs(ui.gearBtn:GetDescendants()) do skip[d] = true end
        end

        skip[MinLine] = true
        skip[MinBox] = true
        for _, d in ipairs(MinBox:GetDescendants()) do skip[d] = true end
        for _, b in ipairs(CloseBars) do skip[b] = true end
        local map = to and toHalloween or fromHalloween
    if not to then
        for _, m in ipairs(movers) do m.g.Offset = Vector2.new(0, 0) end
    end

        themePass = themePass + 1
        local my = themePass
        local list = ScreenGui:GetDescendants()
        task.spawn(function()
            for i, d in ipairs(list) do
                if my ~= themePass then return end
                if not skip[d] then pcall(recolor, d, map) end
                if i % 250 == 0 then task.wait() end
            end
        end)
        ui.decorRefresh()
        saveSettings()
    end

end

if settings.theme == "Halloween" then ui.applyTheme("Halloween") end

if game.PlaceId == LOBBY_PLACE and flags.lossNotice then
    setFlag("lossNotice", false)
    local nGui = make("ScreenGui", {
        Name = GUI_NAME .. "Notice",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 80,
    }, parent)
    local nLabel = make("TextButton", {
        Size = UDim2.new(1, -40, 0, 90),
        Position = UDim2.new(0.5, 0, 0.5, -24),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Active = false,
        Text = "Back to lobby cuz u lost " .. (flags.lossNoticeN or 4) .. "x in a row",
        TextColor3 = C.text,
        TextSize = 30,
        TextWrapped = true,
        Font = Enum.Font.GothamBold,
        TextTransparency = 1,
        TextStrokeColor3 = Color3.new(0, 0, 0),
        TextStrokeTransparency = 1,
    }, nGui)
    local nOk = make("TextButton", {
        Size = UDim2.new(0, 110, 0, 30),
        Position = UDim2.new(0.5, 0, 0.5, 40),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = C.text,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "Okay",
        TextColor3 = C.ink,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextTransparency = 1,
    }, nGui)
    tween(nLabel, 0.5, { TextTransparency = 0, TextStrokeTransparency = 0.5 })
    tween(nOk, 0.5, { BackgroundTransparency = 0, TextTransparency = 0 })
    local gone = false
    local function dismiss()
        if gone then return end
        gone = true
        tween(nLabel, 0.4, { TextTransparency = 1, TextStrokeTransparency = 1 })
        tween(nOk, 0.4, { BackgroundTransparency = 1, TextTransparency = 1 })
        task.delay(0.5, function() nGui:Destroy() end)
    end
    nOk.MouseButton1Click:Connect(dismiss)
end

selectTab("Main")
EVENT.parts.nav = nav
EVENT.hubReady = true
