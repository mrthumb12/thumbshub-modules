-- THUMBSHUB • Ride a Pet module
-- Split from Build154 for lightweight per-game loading.
-- Keeps the Build154 performance changes and existing features.

local function runThumbsHubRideAPet()
-- ============================================================
-- SERVICES
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DISCORD_INVITE = "https://discord.gg/RDZCNHGznU"

local function copyDiscordInvite()
    local copied = false

    if typeof(setclipboard) == "function" then
        copied = pcall(setclipboard, DISCORD_INVITE)
    elseif typeof(toclipboard) == "function" then
        copied = pcall(toclipboard, DISCORD_INVITE)
    end

    if copied then
        return true, "Discord invite copied"
    end

    return false, DISCORD_INVITE
end

-- ============================================================
-- GLOBAL / CONFIG
-- ============================================================

local ENV = (getgenv and getgenv()) or _G

ENV.THUMBSHUB_EGG_RUNTIME_CACHE =
    ENV.THUMBSHUB_EGG_RUNTIME_CACHE
    or setmetatable({}, {__mode = "k"})

if ENV.THUMBSHUB_EGG_V1_UNLOAD then
    pcall(ENV.THUMBSHUB_EGG_V1_UNLOAD)
end

local CONFIG_FOLDER = "THUMBSHUB/configs"
local LEGACY_CONFIG_FILE = "THUMBSHUB_EGG_GAME_V1_CONFIG.json"

local Settings = {
    -- Auto Farm
    AutoFarmEggs = false,
    AutoPlaceEggs = false,
    BestEggFirst = true,
    FarmMethod = "Direct",
    -- BUILD127: TP is the fixed/default and only Auto Farm egg movement method.
    InstantEggTravel = true,
    Fly = false,
    FlySpeed = 80,
    WalkSpeedEnabled = false,
    WalkSpeed = 32,
    Noclip = false,
    HatchRevealRadius = 12,
    UndergroundDepth = 14,
    AutoHatchEggs = true,
    InstantHatchReveal = true,
    TweenSpeed = 240,
    ReturnTweenSpeed = 360,
    PlotReturnPadding = 7,
    PlotEntryStopDistance = 6,
    AutoEnterPlot = true,
    TweenAirHeight = 6,
    MaxFarmDistance = 0,
    SkipDoomedEggs = false,
    ArriveWithSeconds = 5,
    ClaimDelay = 0.25,
    EggNames = "",
    EggFilterVersion = 1,
    EggMutation = "Any",
    MinEggLuck = 0,
    SmartEggTargeting = true,
    SmartTopPercent = 25,
    PreferMutationValue = true,
    AutoSellBasketBeforeFarm = true,
    SellOnlyWhenFull = true,
    RelaxFarmFiltersIfNoMatch = true,

    -- Pets / feeds
    AutoPlaceBestPets = false,
    AutoFeedBestPet = false,
    AutoFeedAboveIncome = false,
    FeedMinIncome = 100,
    AutoFeedAboveAge = false,
    FeedMinAge = 5,
    AutoFeedByRarity = false,
    FeedMinOneIn = 1000,
    Food = "Grass",

    -- Shop
    AutoBuyRadar = false,
    Radar = "Advanced Radar",
    AutoUseRadar = false,
    AutoBuyFood = false,

    -- Progression
    AutoBuyHatchLuck = false,
    HatchLuckMode = "Buy 1",
    AutoUnlockNests = false,
    AutoRebirth = false,
    RebirthEggOverride = "",
    RebirthPetEggMap = {},
    RebirthPetEggSources = {},
    AutoRideBestPet = false,
    AutoClaimIndex = false,

    -- Visual
    EggESP = false,
    PetESP = false,
    PetESPMyPets = true,
    PetESPOthers = false,
    PetESPMinIncome = 0,
    FPSBoost = false,
    HubPerformanceMode = true,

    -- Local pet visibility
    HideAllPets = false,
    HideMyPets = false,
    HideOtherPets = false,

    -- Local player-name privacy
    HideNames = false,

    -- Webhook
    WebhookEnabled = false,
    WebhookURL = "",
    WebhookPetMinIncome = 0,
    WebhookPing = "",
    WebhookWeather = true,
    WebhookEggs = true,
    WebhookPets = true,
    WebhookRebirth = true,

    -- Server hop
    AutoServerHop = false,
    HopEggNames = "",
    HopMutation = "Any",
    HopMinLuck = 0,
    HopDelay = 20,
    HopStopWhenFound = true,
    -- BUILD142: selected HopEggNames use collect-all-then-hop mode.
    -- Give RenderedEggs a few seconds to stream after each server load before
    -- deciding the server contains none of the selected eggs.
    HopScanWait = 4,

    -- THUMBSHUB shared live server index
    ServerIndexUrl = "https://thumbshub-server-index.canyonpresents.workers.dev",
    DirectIndexedHop = true,
    IndexFallbackHop = false,
    IndexMaxAge = 60,
    IndexReportHeartbeat = 40,

    -- Interface
    UIWatermark = true,
    UIDraggable = true,
    UIAutoScale = true,
    UIScale = 1.0,
    UIWindowGlow = true,
    MenuToggleKey = "RightShift",
    UITheme = "Midnight",
    UIAccent = "Orange",
    ConfigProfile = "Default",

    -- Misc
    AntiAFK = true,
    AutoReconnect = true,
}

local RADARS = {
    "Advanced Radar",
    "Jewel Radar",
    "Royal Radar",
    "Magic Radar",
    "Angelic Radar",
    "Eternal Radar",
}

local FOODS = {
    "Grass",
    "Bone",
    "Meat",
    "Magic Apple",
    "Dragonfruit",
}

local MUTATIONS = {
    "Any",
    "Shocked",
    "Volted",
    "Rage",
    "Void",
    "Eternal",
    "Gold",
    "Rainbow", "Magma",
}

local UI_THEMES = {
    "Midnight",
    "Carbon",
    "Ocean",
    "Violet",
    "Emerald",
}

local UI_ACCENTS = {
    "Orange",
    "Blue",
    "Purple",
    "Pink",
    "Green",
    "Red",
    "Cyan",
    "Yellow",
}

local alive = true
local connections = {
    EggReportBusy = false,
    RefreshEggControls = nil :: (() -> ())?,
    EggUpdateReport = nil :: (() -> ())?,
}
local lastClaimedEgg = nil
local sessionStartedAt = os.clock()
local currentFPS = 60
local fpsFrames = 0
local fpsWindowStarted = os.clock()
local farmStats = {
    Grabbed = 0,
    Placed = 0,
    Hatched = 0,
    Sold = 0,
    LastTarget = "None",
}
local lastWeather = nil
local lastHopAt = 0
local busyFarm = false
local manualPlacementWaiting = false

local rebirthRuntime = {
    LastAttemptAt = 0,
    ManualPlacedSeen = false,
    DiscoveryManualPlacedSeen = false,
    DiscoveryDisappearAt = nil :: number?,
    RequiredEgg = nil,
    WaitingEggName = nil,
    WaitStartedAt = 0,
    PostHatchUntil = 0,
    State = "Disabled",
    LastRebirthAt = 0,
    MappingSource = "None",
    LastDeepScanPet = nil,
    LastDeepScanAt = 0,
    DeepScanResult = nil,
    PendingHatchEggName = nil,
    PendingHatchUntil = 0,
    ActiveRequiredPet = nil,
    ActiveRequiredEgg = nil,
    ActiveRequiredEggWeight = nil,
    RequirementIndex = nil,
    RequirementCount = nil,
    DiscoveryEggName = nil,
    DiscoveryRequiredPet = nil,
    DiscoveryCooldownUntil = 0,
    DiscoveryIndex = nil,
    DiscoverySelectedIndex = nil,
    DiscoveryRound = 1,
    LastPlacementState = "Idle",
    LastPlantPosition = nil,
}
local busyFeed = false
local busyShop = false
local busyProgression = false

-- ============================================================
-- INSTANT HATCH REVEAL
-- Server-confirmed result only; no metamethod/namecall hooks.
-- ============================================================

connections.HatchReveal = {
    LastResult = nil,
    Labels = {},
    Popup = nil,
    PopupToken = 0,
    Remote = nil,
}

-- ============================================================
-- WEATHER TRACKER / NEXT-ROLL ODDS V2
--
-- IMPORTANT:
-- The old card said "Most Likely Next" and permanently displayed Thunder 60%.
-- That was mathematically the highest-weight roll, but it looked like an exact
-- prediction and therefore appeared wrong whenever the server rolled anything
-- else.
--
-- The client-visible GameData.Weather module exposes the natural roll weights,
-- but our focused scheduler scan found no replicated "NextWeather" / RNG state.
-- BUILD V2 therefore reports:
--   • exact current weather + live countdown
--   • server-confirmed weather as soon as AddWeather reaches the client
--   • the real next-roll probability table
-- It NEVER pretends the 60% option is an already-selected next storm.
-- ============================================================

connections.WeatherForecast = {
    Current = "Waiting...",
    TimeLeft = "--", -- active/current weather duration
    NextWeather = "Waiting...", -- upcoming pre-rolled storm
    NextStartsIn = "--", -- forecast/pre-roll HUD countdown, NOT storm start time
    NextMutation = "--",
    AfterCurrent = "Waiting...", -- immediate weather state after current one
    AfterMutation = "--",
    ForecastSource = "Scanning for next weather",
    ServerSignal = "Waiting for next server roll",
    Labels = {},
    History = {},
    HistoryLimit = 8,
    Odds = {},
    KnownWeather = {},

    MutationFor = {
        Sunny = "None",
        Thunder = "Shocked",
        Volt = "Volted",
        Raging = "Rage",
        Dreadful = "Void",
        Eternal = "Eternal",
    },
    MultiplierFor = {
        Thunder = "x2",
        Volt = "x3",
        Raging = "x4",
        Dreadful = "x10",
        Eternal = "x100",
    },
    WeatherForMultiplier = {
        ["x2"] = "Thunder",
        ["x3"] = "Volt",
        ["x4"] = "Raging",
        ["x10"] = "Dreadful",
        ["x100"] = "Eternal",
    },
    ImageFor = {},
    CachedUpcomingLabel = nil,
    CachedUpcomingRoot = nil,

    -- Stable local countdown for the NEXT confirmed weather.
    -- The game's forecast HUD can disappear/freeze between updates, so once
    -- confirmed we keep counting locally instead of instantly showing Waiting.
    NextRaw = nil,
    NextSeconds = nil,
    NextSyncClock = nil,
    NextConfirmedAt = nil,
    NextConfirmedWeather = nil,

    -- Local live countdown for the CURRENT weather.
    -- The game's WeatherDescription.TimeLeft can stay visually frozen, so we
    -- use it as a sync point and count down locally between server/UI updates.
    CurrentEndRaw = nil,
    CurrentEndSeconds = nil,
    CurrentEndSyncClock = nil,
    CurrentTimerWeather = nil,

    -- Some versions of the game's WeatherDescription leave the old storm name
    -- visible after its timer reaches 0. Track that stale value so the hub can
    -- move to Sunny immediately instead of snapping back to the expired storm.
    ExpiredWeather = nil,
    ForcedSunny = false,
    ForcedSunnyAt = nil,
}

function connections.WeatherForecast.NormaliseWeather(value)
    -- Keep this helper self-contained because the hub's shared trim()
    -- function is declared later in the file.
    local raw = tostring(value or "")
    raw = raw:gsub("^%s+", ""):gsub("%s+$", "")
    local key = string.lower(raw)

    local aliases = {
        ["sunny"] = "Sunny",
        ["sun"] = "Sunny",
        ["clear"] = "Sunny",
        ["cleared"] = "Sunny",
        ["normal"] = "Sunny",
        ["none"] = "Sunny",
        ["no weather"] = "Sunny",

        ["thunder"] = "Thunder",
        ["thundered"] = "Thunder",
        ["shocked"] = "Thunder",

        ["volt"] = "Volt",
        ["volted"] = "Volt",

        ["raging"] = "Raging",
        ["rage"] = "Raging",

        ["dreadful"] = "Dreadful",
        ["void"] = "Dreadful",

        ["eternal"] = "Eternal",
    }

    for name in pairs(connections.WeatherForecast.KnownWeather) do
        if string.lower(name) == key then return name end
    end
    return aliases[key]
end

function connections.WeatherForecast.LoadOddsFromGame()
    local state = connections.WeatherForecast
    state.Odds = {}
    local folder = ReplicatedStorage:FindFirstChild("GameData")
    local module = folder and folder:FindFirstChild("Weather")
    if not module or not module:IsA("ModuleScript") then return false end
    local ok, data = pcall(require, module)
    if not ok or type(data) ~= "table" then return false end
    local source = type(data.StormRarity) == "table" and data.StormRarity or data.Data
    if type(source) ~= "table" then return false end
    local total = 0
    for name, entry in pairs(source) do
        local weight = tonumber(type(entry) == "table" and entry.Chance or entry)
        if type(name) == "string" and weight and weight == weight and weight >= 0 and weight < math.huge then
            state.KnownWeather[name] = true
            state.Odds[name] = weight
            total += weight
            local info = type(data.Data) == "table" and data.Data[name]
            if type(info) == "table" then
                if type(info.Image) == "string" then state.ImageFor[name] = info.Image end
                if type(info.Mutation) == "string" then state.MutationFor[name] = info.Mutation end
            end
        end
    end
    if total <= 0 then state.Odds = {} ; return false end
    for name, weight in pairs(state.Odds) do state.Odds[name] = weight / total * 100 end
    return true
end

function connections.WeatherForecast.Record(weather)
    local state = connections.WeatherForecast
    local normal = state.NormaliseWeather(weather)

    if not normal then
        return
    end

    if state.History[#state.History] == normal then
        return
    end

    table.insert(state.History, normal)

    while #state.History > state.HistoryLimit do
        table.remove(state.History, 1)
    end
end

function connections.WeatherForecast.OddsText()
    local rows = {}
    for name, weight in pairs(connections.WeatherForecast.Odds) do
        table.insert(rows, string.format("%s %.2f%%", name, weight))
    end
    table.sort(rows)
    return #rows > 0 and table.concat(rows, " • ") or "Unavailable — waiting for game weather data"
end

function connections.WeatherForecast.TopOddsText()
    return connections.WeatherForecast.OddsText()
end

function connections.WeatherForecast.RareChance()
    local o = connections.WeatherForecast.Odds

    return
        (tonumber(o.Raging) or 0)
        + (tonumber(o.Dreadful) or 0)
        + (tonumber(o.Eternal) or 0)
end

function connections.WeatherForecast.HistoryText()
    local history = connections.WeatherForecast.History

    if #history == 0 then
        return "No rolls yet"
    end

    return table.concat(history, " → ")
end



function connections.WeatherForecast.ParseDuration(textValue)
    local raw = tostring(textValue or "")
    raw = raw:gsub("^%s+", ""):gsub("%s+$", "")
    local lower = string.lower(raw)

    -- 2m 47s / 2m47s
    local minutes, seconds =
        lower:match("^(%d+)%s*m%s*(%d+)%s*s$")

    if minutes then
        return
            (tonumber(minutes) or 0) * 60
            + (tonumber(seconds) or 0)
    end

    -- 2:47
    local colonMinutes, colonSeconds =
        lower:match("^(%d+):(%d+)$")

    if colonMinutes then
        return
            (tonumber(colonMinutes) or 0) * 60
            + (tonumber(colonSeconds) or 0)
    end

    -- 167s
    local onlySeconds =
        lower:match("^(%d+)%s*s$")

    if onlySeconds then
        return tonumber(onlySeconds)
    end

    -- 2m
    local onlyMinutes =
        lower:match("^(%d+)%s*m$")

    if onlyMinutes then
        return (tonumber(onlyMinutes) or 0) * 60
    end

    return nil
end

function connections.WeatherForecast.FormatDuration(totalSeconds)
    totalSeconds =
        math.max(
            0,
            math.floor((tonumber(totalSeconds) or 0) + 0.5)
        )

    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60

    if minutes > 0 then
        return string.format("%dm %02ds", minutes, seconds)
    end

    return string.format("%ds", seconds)
end

function connections.WeatherForecast.UpdateCurrentEndTimer(
    currentWeather,
    timeLabel
)
    local state = connections.WeatherForecast
    local now = os.clock()

    local raw =
        timeLabel
        and timeLabel:IsA("TextLabel")
        and tostring(timeLabel.Text or "")
        or ""

    raw = raw:gsub("^%s+", ""):gsub("%s+$", "")

    local parsed =
        connections.WeatherForecast.ParseDuration(raw)

    local weatherKey =
        tostring(currentWeather or "")

    local weatherChanged =
        state.CurrentTimerWeather ~= weatherKey

    if weatherChanged then
        state.CurrentTimerWeather = weatherKey
        state.CurrentEndRaw = nil
        state.CurrentEndSeconds = nil
        state.CurrentEndSyncClock = nil
    end

    -- Trust a NEW value from the game as a resync point.
    if parsed
        and (
            state.CurrentEndRaw ~= raw
            or state.CurrentEndSeconds == nil
            or state.CurrentEndSyncClock == nil
        ) then

        state.CurrentEndRaw = raw
        state.CurrentEndSeconds = parsed
        state.CurrentEndSyncClock = now
    end

    if state.CurrentEndSeconds
        and state.CurrentEndSyncClock then

        local elapsed =
            now - state.CurrentEndSyncClock

        local remaining =
            math.max(
                0,
                state.CurrentEndSeconds - elapsed
            )

        state.TimeLeft =
            connections.WeatherForecast.FormatDuration(
                remaining
            )

        return remaining
    end

    state.TimeLeft =
        raw ~= ""
        and raw
        or "--"

    return nil
end

function connections.WeatherForecast.ForceSunnyAfterExpiry(expiredWeather)
    local state = connections.WeatherForecast
    state.ExpiredWeather = state.NormaliseWeather(expiredWeather)
    state.ExpiredRaw = state.CurrentEndRaw
    state.ForcedSunny = true -- compatibility flag: suppress expired HUD text, do not infer Sunny
    state.Current = "Awaiting weather update"
    state.TimeLeft = "--"
    return true
end

function connections.WeatherForecast.ResolveDisplayedCurrent(rawCurrent, timeLabel)
    local state = connections.WeatherForecast
    local normal = state.NormaliseWeather(rawCurrent)
    if state.ForcedSunny and timeLabel and tostring(timeLabel.Text) ~= state.ExpiredRaw
        and (state.ParseDuration(timeLabel.Text) or 0) > 0 then
        state.ForcedSunny = false
        state.ExpiredWeather = nil
        state.CurrentEndRaw = nil
        state.CurrentEndSeconds = nil
        state.CurrentEndSyncClock = nil
    end
    if state.ForcedSunny and normal == state.ExpiredWeather then
        return "Awaiting weather update", true
    end
    if normal then state.ForcedSunny = false ; state.ExpiredWeather = nil end
    return normal or "Unknown", false
end

function connections.WeatherForecast.UpdateSunnyLiveTimer()
    -- A preview expiry is not an active weather end time.
end

function connections.WeatherForecast.GuiVisible(obj)
    if not obj or not obj.Parent then
        return false
    end

    local current = obj

    while current and current ~= playerGui do
        if current:IsA("GuiObject") and current.Visible == false then
            return false
        end

        if current:IsA("ScreenGui") and current.Enabled == false then
            return false
        end

        current = current.Parent
    end

    return true
end

function connections.WeatherForecast.ParseStartsIn(textValue)
    local raw = tostring(textValue or "")
    raw = raw:gsub("^%s+", ""):gsub("%s+$", "")

    if raw == "" then
        return nil, nil
    end

    local lower = string.lower(raw)

    lower =
        lower
        :gsub("seconds", "s")
        :gsub("second", "s")
        :gsub("minutes", "m")
        :gsub("minute", "m")
        :gsub("%s+", " ")
        :gsub("^%s+", "")
        :gsub("%s+$", "")

    local payloads = {}

    local function addPayload(value)
        value =
            tostring(value or "")
            :gsub("^%s+", "")
            :gsub("%s+$", "")

        if value ~= "" then
            table.insert(payloads, value)
        end
    end

    -- Accept forecast phrases, but deliberately DO NOT accept a bare
    -- "2m 30s" value because that is commonly the active-weather timer.
    addPayload(lower:match("^in%s+(.+)$"))
    addPayload(lower:match("^starts%s+in%s+(.+)$"))
    addPayload(lower:match("^start%s+in%s+(.+)$"))
    addPayload(lower:match("^starting%s+in%s+(.+)$"))
    addPayload(lower:match("^weather%s+starts%s+in%s+(.+)$"))
    addPayload(lower:match("^weather%s+in%s+(.+)$"))
    addPayload(lower:match("^next%s+weather%s+starts%s+in%s+(.+)$"))
    addPayload(lower:match("^next%s+weather%s+in%s+(.+)$"))

    -- Also allow extra leading wording, e.g. "Thunder starts in 12s".
    addPayload(lower:match(".+%s+starts%s+in%s+(.+)$"))
    addPayload(lower:match(".+%s+starting%s+in%s+(.+)$"))

    for _, payload in ipairs(payloads) do
        local seconds =
            connections.WeatherForecast.ParseDuration(
                payload
            )

        if seconds ~= nil then
            return seconds, raw
        end

        local plain =
            payload:match("^(%d+)$")

        if plain then
            return tonumber(plain), raw
        end
    end

    return nil, nil
end

function connections.WeatherForecast.MatchWeatherEvidence(root)
    local state = connections.WeatherForecast
    if not root then return nil, nil, 0 end
    local found, conflict, score = nil, false, 0
    local function accept(name, points)
        if found and found ~= name then conflict = true end
        found = name
        score = math.max(score, points)
    end
    local function inspect(obj)
        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            for name, asset in pairs(state.ImageFor) do
                if asset ~= "" and obj.Image == asset then accept(name, 220) end
            end
        elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local raw = tostring(obj.Text):gsub("<[^>]*>", "")
            local names = {}
            for name in pairs(state.MutationFor) do names[name] = true end
            for name in pairs(state.KnownWeather) do names[name] = true end
            for name in pairs(names) do
                local escaped = string.lower(name):gsub("([^%w])", "%%%1")
                if string.lower(raw):find("%f[%a]" .. escaped .. "%f[%A]") then accept(name, 145) end
            end
        end
    end
    inspect(root)
    for i, obj in ipairs(root:GetDescendants()) do
        if i > 220 then break end
        inspect(obj)
    end
    if conflict then return nil, nil, 0 end
    return found, found and state.MultiplierFor[found] or nil, score
end

function connections.WeatherForecast.ScoreCountdownLabel(label)
    if not label
        or not (
            label:IsA("TextLabel")
            or label:IsA("TextButton")
        )
        or not connections.WeatherForecast.GuiVisible(label) then

        return nil
    end

    local seconds, raw =
        connections.WeatherForecast.ParseStartsIn(
            label.Text
        )

    if not seconds then
        return nil
    end

    local camera = workspace.CurrentCamera
    local viewport =
        camera
        and camera.ViewportSize
        or Vector2.new(1920, 1080)

    local score = 100

    pcall(function()
        if label.TextSize >= 24 then
            score += 35
        elseif label.TextSize >= 18 then
            score += 18
        end

        local centreY =
            label.AbsolutePosition.Y
            + label.AbsoluteSize.Y * 0.5

        if viewport.Y > 0
            and centreY / viewport.Y >= 0.55 then

            score += 30
        end
    end)

    local bestRoot = label
    local bestWeather
    local bestMultiplier
    local bestEvidence = 0
    local ancestor = label

    for _ = 1, 7 do
        ancestor = ancestor.Parent
        if not ancestor or ancestor == playerGui then
            break
        end

        local path = string.lower(ancestor:GetFullName())

        if path:find("restock", 1, true)
            or path:find("gearshop", 1, true)
            or path:find("shop", 1, true)
            or path:find("hatchingui", 1, true)
            or path:find("eggtracker", 1, true)
            or path:find("products", 1, true)
            or path:find("upgrade", 1, true) then

            score -= 100
        end

        -- Never treat the currently-active weather card's timer as the
        -- upcoming forecast.
        if path:find("weatherdescription", 1, true)
            and not path:find("next", 1, true)
            and not path:find("upcoming", 1, true)
            and not path:find("forecast", 1, true) then

            score -= 140
        end

        if path:find("forecast", 1, true)
            or path:find("upcoming", 1, true)
            or path:find("nextweather", 1, true) then

            score += 110
        elseif path:find("weather", 1, true)
            or path:find("storm", 1, true) then

            score += 60
        elseif path:find("event", 1, true)
            or path:find("countdown", 1, true)
            or path:find("timer", 1, true) then

            score += 15
        end

        local weather, multiplier, evidence =
            connections.WeatherForecast.MatchWeatherEvidence(
                ancestor
            )

        if evidence > bestEvidence then
            bestEvidence = evidence
            bestRoot = ancestor
            bestWeather = weather
            bestMultiplier = multiplier
        end

        if evidence >= 200 then
            break
        end
    end

    score += bestEvidence

    -- We only accept this as WEATHER if the same HUD group contains either the
    -- exact GameData weather image or one of the confirmed weather multipliers.
    if not bestWeather or score < 150 then
        return nil
    end

    return {
        Label = label,
        Root = bestRoot,
        Seconds = seconds,
        Text = raw,
        Weather = bestWeather,
        Multiplier = bestMultiplier,
        Score = score,
    }
end

function connections.WeatherForecast.FindUpcomingWeatherHud()
    local state = connections.WeatherForecast

    if state.CachedUpcomingLabel
        and state.CachedUpcomingLabel.Parent then

        local cached =
            connections.WeatherForecast.ScoreCountdownLabel(
                state.CachedUpcomingLabel
            )

        if cached then
            state.CachedUpcomingRoot = cached.Root
            return cached
        end
    end

    local best

    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("TextLabel")
            or obj:IsA("TextButton") then

            local candidate =
                connections.WeatherForecast.ScoreCountdownLabel(
                    obj
                )

            if candidate
                and (
                    not best
                    or candidate.Score > best.Score
                ) then

                best = candidate
            end
        end
    end

    if best then
        state.CachedUpcomingLabel = best.Label
        state.CachedUpcomingRoot = best.Root
    end

    return best
end

function connections.WeatherForecast.UpdateUpcomingForecast()
    local state = connections.WeatherForecast
    local now = os.clock()

    local candidate =
        connections.WeatherForecast.FindUpcomingWeatherHud()

    if candidate and state.NextConfirmedWeather == candidate.Weather
        and state.NextRaw == candidate.Text and state.NextSyncClock and state.NextSeconds
        and now - state.NextSyncClock > state.NextSeconds + 2 then
        state.NextWeather = "Waiting..."
        state.NextStartsIn = "--"
        state.NextMutation = "--"
        state.NextConfirmedWeather = nil
        state.StalePreview = {Weather = candidate.Weather, Text = candidate.Text}
        state.ForecastSource = "Preview expired; waiting for a fresh update"
        return false
    end
    if candidate and state.StalePreview and state.StalePreview.Weather == candidate.Weather
        and state.StalePreview.Text == candidate.Text then
        return false
    end
    if candidate then
        state.StalePreview = nil
        local changed =
            state.NextConfirmedWeather
            ~= candidate.Weather

        local rawChanged =
            state.NextRaw
            ~= candidate.Text

        if changed
            or rawChanged
            or state.NextSeconds == nil
            or state.NextSyncClock == nil then

            state.NextRaw =
                candidate.Text

            state.NextSeconds =
                candidate.Seconds

            state.NextSyncClock =
                now

            state.NextConfirmedAt =
                now

            state.NextConfirmedWeather =
                candidate.Weather
        end

        state.NextWeather =
            candidate.Weather

        local remaining =
            math.max(
                0,
                (
                    tonumber(state.NextSeconds)
                    or tonumber(candidate.Seconds)
                    or 0
                )
                - (
                    now
                    - (
                        state.NextSyncClock
                        or now
                    )
                )
            )

        -- IMPORTANT:
        -- The large "in XXs" forecast HUD countdown is the pre-roll / preview
        -- timer. It is NOT proof that the upcoming storm starts in XX seconds.
        state.NextStartsIn =
            connections.WeatherForecast.FormatDuration(
                remaining
            )

        local mutation =
            state.MutationFor[candidate.Weather]
            or (
                candidate.Weather == "Sunny"
                and "None"
                or "Unknown"
            )

        state.NextMutation =
            mutation == "None"
            and "None"
            or (
                mutation
                .. (
                    candidate.Multiplier
                    and (
                        "  •  "
                        .. candidate.Multiplier
                    )
                    or ""
                )
            )

        state.ForecastSource =
            "Forecast synced"

        return true
    end

    -- Forecast HUD vanished after a valid reveal: preserve the prediction and
    -- locally count it down instead of instantly dropping to Waiting.
    if state.NextConfirmedWeather
        and state.NextSeconds
        and state.NextSyncClock then

        local remaining =
            state.NextSeconds
            - (
                now
                - state.NextSyncClock
            )

        if remaining > -2 then
            state.NextWeather =
                state.NextConfirmedWeather

            state.NextStartsIn =
                connections.WeatherForecast.FormatDuration(
                    math.max(
                        0,
                        remaining
                    )
                )

            local mutation =
                state.MutationFor[
                    state.NextConfirmedWeather
                ]
                or (
                    state.NextConfirmedWeather == "Sunny"
                    and "None"
                    or "Unknown"
                )

            local multiplier =
                state.MultiplierFor[
                    state.NextConfirmedWeather
                ]

            state.NextMutation =
                mutation == "None"
                and "None"
                or (
                    mutation
                    .. (
                        multiplier
                        and (
                            "  •  "
                            .. multiplier
                        )
                        or ""
                    )
                )

            state.ForecastSource =
                remaining > 0
                and "Forecast tracking"
                or "Forecast preview ending"

            return true
        end

        state.NextRaw = nil
        state.NextSeconds = nil
        state.NextSyncClock = nil
        state.NextConfirmedAt = nil
        state.NextConfirmedWeather = nil
    end

    state.NextWeather =
        "Waiting..."

    state.NextStartsIn =
        "--"

    state.NextMutation =
        "--"

    state.ForecastSource =
        "Scanning for next weather"

    return false
end

function connections.WeatherForecast.Refresh()
    local state = connections.WeatherForecast
    local labels = state.Labels

    state.AfterCurrent = state.NextConfirmedWeather or "Not announced"
    state.AfterMutation = state.NextConfirmedWeather and state.MutationFor[state.NextConfirmedWeather] or "--"

    if labels.Current and labels.Current.Parent then
        labels.Current.Text = tostring(state.Current or "Waiting...")
    end

    if labels.TimeLeft and labels.TimeLeft.Parent then
        labels.TimeLeft.Text = tostring(state.TimeLeft or "--")
    end

    if labels.After and labels.After.Parent then
        labels.After.Text =
            tostring(
                state.AfterCurrent
                or "Waiting..."
            )
    end

    if labels.AfterMutation and labels.AfterMutation.Parent then
        labels.AfterMutation.Text =
            tostring(
                state.AfterMutation
                or "--"
            )
    end

    if labels.Next and labels.Next.Parent then
        labels.Next.Text =
            tostring(
                state.NextWeather
                or "Waiting..."
            )
    end

    if labels.NextTime and labels.NextTime.Parent then
        labels.NextTime.Text =
            tostring(
                state.NextStartsIn
                or "--"
            )
    end

    if labels.Effect and labels.Effect.Parent then
        labels.Effect.Text =
            tostring(
                state.NextMutation
                or "--"
            )
    end

    if labels.Signal and labels.Signal.Parent then
        labels.Signal.Text =
            tostring(state.ForecastSource or state.ServerSignal or "Waiting...")
    end

    if labels.History and labels.History.Parent then
        labels.History.Text = state.HistoryText()
    end

    if labels.Odds and labels.Odds.Parent then
        labels.Odds.Text = state.OddsText()
    end
end

connections.WeatherForecast.LoadOddsFromGame()

function connections.WeatherForecast.FindWeatherInValue(value, depth, seen)
    depth = depth or 0
    seen = seen or {}

    if depth > 5 then
        return nil
    end

    local t = typeof(value)

    if t == "string" then
        return connections.WeatherForecast.NormaliseWeather(value)
    end

    if t ~= "table" then
        return nil
    end

    if seen[value] then
        return nil
    end

    seen[value] = true

    -- Look at likely keys first.
    for _, key in ipairs({
        "Weather",
        "WeatherName",
        "Name",
        "Type",
        "Storm",
        "Id",
    }) do
        local hit =
            connections.WeatherForecast.FindWeatherInValue(
                value[key],
                depth + 1,
                seen
            )

        if hit then
            seen[value] = nil
            return hit
        end
    end

    for k, v in pairs(value) do
        local hit =
            connections.WeatherForecast.FindWeatherInValue(
                k,
                depth + 1,
                seen
            )
            or connections.WeatherForecast.FindWeatherInValue(
                v,
                depth + 1,
                seen
            )

        if hit then
            seen[value] = nil
            return hit
        end
    end

    seen[value] = nil
    return nil
end

function connections.HatchReveal.FormatNumber(value)
    value = tonumber(value)

    if not value then
        return tostring(value or "N/A")
    end

    if value >= 1e15 then
        return string.format("%.2fQa", value / 1e15)
    elseif value >= 1e12 then
        return string.format("%.2fT", value / 1e12)
    elseif value >= 1e9 then
        return string.format("%.2fB", value / 1e9)
    elseif value >= 1e6 then
        return string.format("%.2fM", value / 1e6)
    elseif value >= 1e3 then
        return string.format("%.2fK", value / 1e3)
    end

    return tostring(value)
end

function connections.HatchReveal.IsMine(owner)
    return owner == player or tostring(owner) == player.Name or tostring(owner) == tostring(player.UserId)
end

function connections.HatchReveal.Handle(data)
    if not Settings.InstantHatchReveal
        or type(data) ~= "table"
        or not connections.HatchReveal.IsMine(data.Owner) then
        return
    end

    connections.HatchReveal.LastResult = {
        PetName = data.PetName,
        EggName = data.EggName,
        EggKey = data.EggKey,
        Chance = data.Chance,
        Luck = data.Luck,
        Weight = data.Weight,
        Age = data.Age,
        Mutation = data.Mutation,
        SpawnMutation = data.SpawnMutation,
        ReceivedAt = os.clock(),
    }

    local state = connections.HatchReveal
    local location = state.Locations and state.Locations[tostring(data.EggKey)]
    if location then
        state.LastResult.SourcePosition = location.Position
        state.LastResult.SourceModel = location.Model
    end
    state.ContextVisible = false
end


-- Forward declaration: several farming helpers call setStatus before the UI is built.
local setStatus = function(_) end
local sendWebhook = function() return false end

-- Incremented whenever farm movement should be cancelled immediately.
local farmMoveGeneration = 0
local activeFarmTween = nil
local farmHoldingW = false

local function setFarmForwardKey(down)
    down = down == true

    if farmHoldingW == down then
        return true
    end

    local ok = pcall(function()
        VirtualInputManager:SendKeyEvent(
            down,
            Enum.KeyCode.W,
            false,
            game
        )
    end)

    if ok then
        farmHoldingW = down
    end

    return ok
end

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

do
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    local gameFolder = remotesFolder and remotesFolder:FindFirstChild("Game")
    connections.HatchReveal.Remote = gameFolder and gameFolder:FindFirstChild("Hatch")

    if connections.HatchReveal.Remote and connections.HatchReveal.Remote:IsA("RemoteEvent") then
        connect(connections.HatchReveal.Remote.OnClientEvent, function(data)
            connections.HatchReveal.Handle(data)
        end)
    else
        task.spawn(function()
            local ok, remote = pcall(function()
                return ReplicatedStorage
                    :WaitForChild("Remotes", 10)
                    :WaitForChild("Game", 10)
                    :WaitForChild("Hatch", 10)
            end)

            if ok and remote and remote:IsA("RemoteEvent") and alive then
                connections.HatchReveal.Remote = remote
                connect(remote.OnClientEvent, function(data)
                    connections.HatchReveal.Handle(data)
                end)
            end
        end)
    end
end

connect(RunService.RenderStepped, function()
    fpsFrames += 1

    local now = os.clock()
    local elapsed = now - fpsWindowStarted

    if elapsed >= 1 then
        currentFPS = math.max(1, math.floor((fpsFrames / elapsed) + 0.5))
        fpsFrames = 0
        fpsWindowStarted = now
    end
end)

local function disconnectAll()
    -- BUILD141: basket watcher callbacks can fire during teardown. Disconnect
    -- those first and keep named state tables alive until callbacks drain.
    local eggState = connections.EggReturn
    if eggState and eggState.WatchConnections then
        for _, c in ipairs(eggState.WatchConnections) do
            pcall(function() c:Disconnect() end)
        end
        table.clear(eggState.WatchConnections)
        if eggState.WatchedBasketChildren then
            table.clear(eggState.WatchedBasketChildren)
        end
        eggState.Active = false
    end

    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end

    -- Do not table.clear(connections): that used to delete EggReturn /
    -- InstantTravel while asynchronous callbacks were still unwinding.
    for i = #connections, 1, -1 do
        connections[i] = nil
    end
end

-- ============================================================
-- CONFIG
-- ============================================================

local function safeConfigName(value)
    local name = tostring(value or "Default")
    name = name:gsub("%.json$", "")
    name = name:gsub("[^%w%s_%-]", "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    return name ~= "" and name:sub(1, 32) or "Default"
end

local function ensureConfigFolder()
    if typeof(makefolder) ~= "function" then
        return false
    end

    if typeof(isfolder) ~= "function" or not isfolder("THUMBSHUB") then
        pcall(makefolder, "THUMBSHUB")
    end
    if typeof(isfolder) ~= "function" or not isfolder(CONFIG_FOLDER) then
        pcall(makefolder, CONFIG_FOLDER)
    end
    return typeof(isfolder) ~= "function" or isfolder(CONFIG_FOLDER)
end

local function configPath(name)
    return CONFIG_FOLDER .. "/" .. safeConfigName(name or Settings.ConfigProfile) .. ".json"
end

local function saveConfig(name)
    if typeof(writefile) ~= "function" then
        return false
    end

    ensureConfigFolder()
    Settings.ConfigProfile = safeConfigName(name or Settings.ConfigProfile)

    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, Settings)
    if not ok then
        return false
    end

    return pcall(writefile, configPath(Settings.ConfigProfile), encoded)
end

local function loadConfig(name)
    if typeof(readfile) ~= "function" then
        return false
    end

    ensureConfigFolder()
    local selected = safeConfigName(name or Settings.ConfigProfile)
    local path = configPath(selected)

    -- One-time compatibility with the original single-file config.
    if typeof(isfile) == "function" and not isfile(path) then
        if selected == "Default" and isfile(LEGACY_CONFIG_FILE) then
            path = LEGACY_CONFIG_FILE
        else
            return false
        end
    end

    local okRead, raw = pcall(readfile, path)
    if not okRead or not raw or raw == "" then
        return false
    end

    local okDecode, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not okDecode or type(data) ~= "table" then
        return false
    end

    for k, v in pairs(data) do
        if Settings[k] ~= nil then
            Settings[k] = v
        end
    end

    -- Retire patched routes even when an old profile is loaded.
    Settings.FarmMethod = "Direct"
    -- BUILD127: old saved profiles cannot turn TP-only Auto Farm off.
    Settings.InstantEggTravel = true
    Settings.AutoEnterPlot = true
    Settings.SkipDoomedEggs = false
    Settings.WebhookEnabled = false
    Settings.Fly = false
    Settings.Noclip = false
    Settings.WalkSpeedEnabled = false
    if tonumber(data.EggFilterVersion) ~= 1 and tostring(Settings.EggNames or "") ~= "" then
        Settings.MinEggLuck = 0
        Settings.MaxFarmDistance = 0
    end
    Settings.EggFilterVersion = 1
    Settings.ConfigProfile = selected

    if path == LEGACY_CONFIG_FILE then
        saveConfig(selected)
    end

    return true
end


local function listConfigProfiles()
    local names = {}
    local seen = {}
    ensureConfigFolder()

    if typeof(listfiles) == "function" then
        local ok, files = pcall(listfiles, CONFIG_FOLDER)
        if ok and type(files) == "table" then
            for _, path in ipairs(files) do
                local name = tostring(path):match("([^/\\]+)%.json$")
                if name and not seen[name] then
                    seen[name] = true
                    table.insert(names, name)
                end
            end
        end
    end

    if #names == 0 then
        table.insert(names, safeConfigName(Settings.ConfigProfile))
    end
    table.sort(names, function(a, b)
        return string.lower(a) < string.lower(b)
    end)
    return names
end

local function deleteConfig(name)
    if typeof(delfile) ~= "function" then
        return false
    end
    local path = configPath(name)
    if typeof(isfile) == "function" and not isfile(path) then
        return false
    end
    return pcall(delfile, path)
end

loadConfig()

local CONFIG_PROFILES = listConfigProfiles()

local function refreshConfigProfiles()
    local latest = listConfigProfiles()
    table.clear(CONFIG_PROFILES)
    for _, name in ipairs(latest) do
        table.insert(CONFIG_PROFILES, name)
    end
    return CONFIG_PROFILES
end

-- ============================================================
-- UTILITY
-- ============================================================

local function trim(s)
    return tostring(s or ""):match("^%s*(.-)%s*$")
end

local function splitCSV(s)
    local out = {}
    for part in tostring(s or ""):gmatch("[^,]+") do
        part = trim(part)
        if part ~= "" then
            table.insert(out, string.lower(part))
        end
    end
    return out
end

local function csvContains(csv, value)
    local parts = splitCSV(csv)
    if #parts == 0 then
        return true
    end

    value = string.lower(tostring(value or ""))
    for _, part in ipairs(parts) do
        if part == value then
            return true
        end
    end
    return false
end

local function parseNumber(text)
    text = tostring(text or "")
        :gsub(",", "")
        :gsub("%$", "")
        :gsub("/s", "")
        :gsub("%s", "")

    local number, suffix = text:match("([%d%.]+)([KkMmBbTt]?)")
    number = tonumber(number)

    if not number then
        return 0
    end

    suffix = string.upper(suffix or "")
    local mult = 1

    if suffix == "K" then
        mult = 1e3
    elseif suffix == "M" then
        mult = 1e6
    elseif suffix == "B" then
        mult = 1e9
    elseif suffix == "T" then
        mult = 1e12
    end

    return number * mult
end

local function parseTimer(text)
    text = tostring(text or "")

    local m, s = text:match("(%d+):(%d+)")
    if m and s then
        return (tonumber(m) or 0) * 60 + (tonumber(s) or 0)
    end

    local only = text:match("(%d+)")
    return tonumber(only) or 0
end

local function getCharacter()
    local char = player.Character
    if not char then
        return nil, nil, nil
    end

    return char,
        char:FindFirstChildOfClass("Humanoid"),
        char:FindFirstChild("HumanoidRootPart")
end

local function getObjectPosition(obj)
    if not obj then
        return nil
    end

    if obj:IsA("BasePart") then
        return obj.Position
    end

    if obj:IsA("Attachment") then
        return obj.WorldPosition
    end

    if obj:IsA("Model") then
        local ok, pivot = pcall(obj.GetPivot, obj)
        if ok then
            return pivot.Position
        end
    end

    local model = obj:FindFirstAncestorOfClass("Model")
    if model then
        local ok, pivot = pcall(model.GetPivot, model)
        if ok then
            return pivot.Position
        end
    end

    return nil
end

local function stopCurrentMovement()
    farmMoveGeneration += 1
    setFarmForwardKey(false)

    if activeFarmTween then
        pcall(function()
            activeFarmTween:Cancel()
        end)
        activeFarmTween = nil
    end

    local _, humanoid, root = getCharacter()
    if humanoid and root then
        pcall(function()
            humanoid:Move(Vector3.zero, false)
            humanoid:MoveTo(root.Position)
        end)
    end
end

-- BUILD126 TEST direct positioning. A local move is never treated as pickup/return confirmation.
connections.InstantTravel = {RetryAfter = 0, Rollbacks = 0, Attempts = 0,
    LastOutcome = "Not attempted", LastDestination = "", LastDistance = 0,
    SessionRejected = false}
connections.EggReturn = {
    Active = false, Started = 0, Expected = "", Baseline = {} :: {[Instance]: boolean},
    BaselineKeys = {} :: {[string]: boolean}, Lines = {} :: {string},
    LastSignature = "", LastSample = 0, Outcome = "Not attempted",
    Character = nil :: Model?, LastNotice = "", NoticeAtStart = "",
    UsedInstantTravel = false,
    WatchConnections = {} :: {RBXScriptConnection},
    WatchedBasketChildren = {} :: {[Instance]: boolean},
    LastCompletedLines = {} :: {string},
    LastCompletedExpected = "",
    LastCompletedOutcome = "Not attempted",
    LastCompletedAt = 0,
}
local instantTravelCollisionState = setmetatable({}, {__mode = "k"})

local function setInstantTravelNoclip(enabled)
    local character = player.Character

    if enabled then
        if character then
            for _, obj in ipairs(character:GetDescendants()) do
                if obj:IsA("BasePart") then
                    if instantTravelCollisionState[obj] == nil then
                        instantTravelCollisionState[obj] = obj.CanCollide
                    end
                    obj.CanCollide = false
                end
            end
        end
        return
    end

    for part, original in pairs(instantTravelCollisionState) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = original
            end)
        end
        instantTravelCollisionState[part] = nil
    end
end

local function tryInstantEggTravel(destination, shouldContinue)
    -- BUILD127: TP is the only Auto Farm egg movement method.
    -- There is no UI opt-in, saved-config gate, or session-rejection gate.
    if shouldContinue and not shouldContinue() then return false end
    local _, hum, root = getCharacter()
    if not root or not hum or hum.Health <= 0 then return false end
    if destination.Y <= workspace.FallenPartsDestroyHeight + 20 then return false end
    local generation = farmMoveGeneration
    if activeFarmTween then
        activeFarmTween:Cancel()
        activeFarmTween = nil
    end
    connections.InstantTravel.Attempts += 1
    connections.InstantTravel.LastDestination = tostring(destination)
    connections.InstantTravel.LastOutcome = "Position requested with temporary noclip"

    -- BUILD141: disable character collision around every direct TP so walls,
    -- terrain and plot geometry cannot push the root back during the snap.
    setInstantTravelNoclip(true)

    local ok = pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = CFrame.lookAt(destination, destination + root.CFrame.LookVector)
    end)
    if not ok then
        setInstantTravelNoclip(false)
        connections.InstantTravel.RetryAfter = os.clock() + 15
        return false
    end
    -- BUILD123: do not linger at the destination. The observed fast farm snaps
    -- to the egg and returns as soon as pickup is seen, so keep this to roughly
    -- one rendered/network frame instead of the old 0.75 second settle window.
    local untilTime = os.clock() + 0.05
    repeat
        task.wait()
        if not alive or generation ~= farmMoveGeneration or not root.Parent or hum.Health <= 0
            or (shouldContinue and not shouldContinue()) then
            setInstantTravelNoclip(false)
            return false
        end
    until os.clock() >= untilTime

    local distance = (root.Position - destination).Magnitude
    setInstantTravelNoclip(false)
    connections.InstantTravel.LastDistance = distance

    -- Only fail if the direct move was effectively rejected immediately.
    -- Do not arm the old 15 second cooldown here, because that prevented the
    -- carried-egg return leg from making its second TP attempt.
    if distance > 30 then
        connections.InstantTravel.Rollbacks += 1
        connections.InstantTravel.LastOutcome = "Burst TP did not hold long enough to interact"
        connections.InstantTravel.RetryAfter = os.clock() + 0.35
        return false
    end

    connections.InstantTravel.LastOutcome = "Burst TP held for 0.05s; continuing immediately"
    if connections.EggReturn and connections.EggReturn.Active then
        connections.EggReturn.UsedInstantTravel = true
    end
    return true
end



local function tweenToPosition(pos, stopDistance, shouldContinue, speedOverride)
    if not pos then
        return false
    end

    local char, humanoid, root = getCharacter()
    if not char or not humanoid or not root then
        return false
    end

    stopDistance = stopDistance or 10

    local delta = pos - root.Position
    local flat = Vector3.new(delta.X, 0, delta.Z)
    local horizontalDistance = flat.Magnitude

    if horizontalDistance <= stopDistance then
        return true
    end

    local direction = flat.Unit

    -- One continuous tween again: no segments and no "unsafe ground"
    -- rejection. The important difference from the earlier build is that we never
    -- tween DOWN while travelling horizontally. That was the part most
    -- likely to put the root below uneven terrain.
    local destinationXZ = pos - direction * stopDistance

    local targetHintY = pos.Y + 2.5
    local airHeight = math.clamp(tonumber(Settings.TweenAirHeight) or 8, 0, 25)

    -- Fly above the floor during the fast part of the journey. We use the
    -- target's height + Air Height instead of repeatedly adding height to the
    -- current root, so repeated farm trips do not keep climbing higher.
    local travelY = math.max(root.Position.Y, targetHintY + airHeight)

    local destination = Vector3.new(
        destinationXZ.X,
        travelY,
        destinationXZ.Z
    )

    local speed = math.clamp(tonumber(speedOverride) or tonumber(Settings.TweenSpeed) or 240, 10, 1000)

    local travelDistance = (
        Vector3.new(root.Position.X, 0, root.Position.Z)
        - Vector3.new(destination.X, 0, destination.Z)
    ).Magnitude

    local duration = math.max(travelDistance / speed, 0.05)

    local tween = TweenService:Create(
        root,
        TweenInfo.new(
            duration,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.Out
        ),
        {
            CFrame = CFrame.new(
                destination,
                Vector3.new(pos.X, destination.Y, pos.Z)
            )
        }
    )

    activeFarmTween = tween
    tween:Play()

    local started = os.clock()

    while alive and activeFarmTween == tween do
        if shouldContinue and not shouldContinue() then
            pcall(function()
                tween:Cancel()
            end)

            activeFarmTween = nil
            return false
        end

        if not root.Parent or humanoid.Health <= 0 then
            pcall(function()
                tween:Cancel()
            end)

            activeFarmTween = nil
            return false
        end

        local currentFlatDistance = (
            Vector3.new(root.Position.X, 0, root.Position.Z)
            - Vector3.new(pos.X, 0, pos.Z)
        ).Magnitude

        if currentFlatDistance <= stopDistance + 0.75 then
            pcall(function()
                tween:Cancel()
            end)

            activeFarmTween = nil
            return true
        end

        -- Keep only the emergency destroy-height guard. There is no
        -- terrain/segment rejection anymore.
        if root.Position.Y <= workspace.FallenPartsDestroyHeight + 12 then
            pcall(function()
                tween:Cancel()
            end)

            activeFarmTween = nil
            setStatus("Tween cancelled • too low")
            return false
        end

        if os.clock() - started > duration + 1.0 then
            break
        end

        task.wait(0.02)
    end

    activeFarmTween = nil

    local finalFlatDistance = (
        Vector3.new(root.Position.X, 0, root.Position.Z)
        - Vector3.new(pos.X, 0, pos.Z)
    ).Magnitude

    return finalFlatDistance <= stopDistance + 1.5
end

local function tweenLandToPosition(pos, stopDistance, shouldContinue, speedOverride)
    if not pos then
        return false
    end

    local char, humanoid, root = getCharacter()
    if not char or not humanoid or not root or humanoid.Health <= 0 then
        return false
    end

    stopDistance = math.max(tonumber(stopDistance) or 2, 1)

    local delta = pos - root.Position
    local distance = delta.Magnitude

    if distance <= stopDistance then
        return true
    end

    -- End a little above the prompt/anchor instead of inside the floor.
    local target = pos + Vector3.new(0, 2.5, 0)
    local targetDelta = target - root.Position
    local targetDistance = targetDelta.Magnitude

    if targetDistance > stopDistance then
        target = root.Position
            + targetDelta.Unit
            * math.max(targetDistance - stopDistance, 0)
    end

    local speed = math.clamp(tonumber(speedOverride) or tonumber(Settings.TweenSpeed) or 240, 10, 1000)
    local duration = math.max((root.Position - target).Magnitude / speed, 0.05)

    local lookTarget = Vector3.new(pos.X, target.Y, pos.Z)

    local tween = TweenService:Create(
        root,
        TweenInfo.new(
            duration,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.Out
        ),
        {
            CFrame = CFrame.new(target, lookTarget)
        }
    )

    activeFarmTween = tween
    tween:Play()

    local started = os.clock()

    while alive and activeFarmTween == tween do
        if shouldContinue and not shouldContinue() then
            pcall(function()
                tween:Cancel()
            end)
            activeFarmTween = nil
            return false
        end

        if not root.Parent or humanoid.Health <= 0 then
            pcall(function()
                tween:Cancel()
            end)
            activeFarmTween = nil
            return false
        end

        if (root.Position - pos).Magnitude <= stopDistance + 0.75 then
            pcall(function()
                tween:Cancel()
            end)
            activeFarmTween = nil
            return true
        end

        if root.Position.Y <= workspace.FallenPartsDestroyHeight + 12 then
            pcall(function()
                tween:Cancel()
            end)
            activeFarmTween = nil
            return false
        end

        if os.clock() - started > duration + 0.75 then
            break
        end

        task.wait(0.015)
    end

    activeFarmTween = nil
    return (root.Position - pos).Magnitude <= stopDistance + 1.5
end



local function triggerPrompt(prompt, shouldContinue)
    if not prompt or not prompt:IsA("ProximityPrompt") then
        return false
    end

    local pos = getObjectPosition(prompt.Parent)
    local maxDistance = tonumber(prompt.MaxActivationDistance) or 10
    local stopDist = math.max(2, maxDistance - 1.25)

    if pos then
        -- BUILD127: Auto Farm pickup movement is TP-only. Never silently fall
        -- back to tween/land movement after the first direct move.
        local moved = false
        if busyFarm then
            moved = tryInstantEggTravel(pos + Vector3.new(0, 2.5, 0), shouldContinue)
        end
        if shouldContinue and not shouldContinue() then return false end
        if not moved then
            connections.InstantTravel.LastOutcome = "TP-only pickup move failed; retrying next farm attempt"
            return false
        end

        local _, _, root = getCharacter()

        if root then
            local actualDistance = (root.Position - pos).Magnitude

            -- If the first TP left us just outside the real prompt radius,
            -- correct it with another direct TP rather than changing methods.
            if actualDistance > math.max(1.5, maxDistance - 0.5) then
                moved = tryInstantEggTravel(pos + Vector3.new(0, 0.75, 0), shouldContinue)
            end
        end

        if not moved then
            connections.InstantTravel.LastOutcome = "TP-only prompt correction failed; retrying next farm attempt"
            return false
        end
    end

    -- Some newer egg prompts only become Enabled once the player is actually
    -- inside their proximity radius. Give the game a short moment to activate
    -- it after movement instead of rejecting the egg from across the map.
    if prompt.Parent and not prompt.Enabled then
        local enableUntil = os.clock() + 1.25

        while alive
            and prompt.Parent
            and not prompt.Enabled
            and os.clock() < enableUntil do

            if shouldContinue and not shouldContinue() then
                stopCurrentMovement()
                return false
            end

            task.wait(0.04)
        end
    end

    if not prompt.Parent or not prompt.Enabled then
        return false
    end

    task.wait(math.max(0, tonumber(Settings.ClaimDelay) or 0))

    if shouldContinue and not shouldContinue() then
        stopCurrentMovement()
        return false
    end

    if typeof(fireproximityprompt) == "function" then
        local ok = pcall(fireproximityprompt, prompt)
        if ok then
            return true
        end
    end

    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.max(prompt.HoldDuration, 0.05) + 0.08)
        prompt:InputHoldEnd()
    end)

    return ok
end

local function activateButton(obj)
    if not obj then
        return false
    end

    local button = nil

    if obj:IsA("GuiButton") then
        button = obj
    else
        button = obj:FindFirstChildWhichIsA("GuiButton", true)
    end

    if not button then
        return false
    end

    if button.Visible == false then
        return false
    end

    local ok = pcall(function()
        button:Activate()
    end)

    if ok then
        return true
    end

    if typeof(firesignal) == "function" then
        ok = pcall(function()
            firesignal(button.Activated)
        end)
        if ok then
            return true
        end

        ok = pcall(function()
            firesignal(button.MouseButton1Click)
        end)
        if ok then
            return true
        end
    end

    return false
end

local function getOwnPlot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then
        return nil
    end

    for _, plot in ipairs(plots:GetChildren()) do
        if plot:GetAttribute("NestsOwnerLoaded") == player.UserId then
            return plot
        end
    end

    -- Fallback if the owner attribute is momentarily missing.
    for _, plot in ipairs(plots:GetChildren()) do
        local pets = plot:FindFirstChild("Pets")
        if pets then
            for _, pet in ipairs(pets:GetChildren()) do
                if pet:GetAttribute("OwnerUserId") == player.UserId then
                    return plot
                end
            end
        end
    end

    return nil
end

local function getOwnPets()
    local plot = getOwnPlot()
    local folder = plot and plot:FindFirstChild("Pets")
    if not folder then
        return {}
    end

    local out = {}
    for _, pet in ipairs(folder:GetChildren()) do
        if pet:GetAttribute("OwnerUserId") == player.UserId then
            table.insert(out, pet)
        end
    end
    return out
end

local function getPetIncome(pet)
    local cash = pet and pet:FindFirstChild("PetCash")
    local income = cash and cash:FindFirstChild("Income")

    if income and income:IsA("TextLabel") then
        return parseNumber(income.Text)
    end

    return 0
end

local function getPetAge(pet)
    return tonumber(pet and pet:GetAttribute("Age")) or 0
end

local function getPetMutation(pet)
    return tostring(pet and pet:GetAttribute("Mutation") or "None")
end

local function getBasePetOneIn(petName)
    local main = playerGui:FindFirstChild("Main")
    local index = main and main:FindFirstChild("Index")
    local holders = index and index:FindFirstChild("Holders")
    local petsHolder = holders and holders:FindFirstChild("PetsHolder")
    local frame = petsHolder and petsHolder:FindFirstChild(tostring(petName))

    if not frame then
        return 0
    end

    local sample = frame:FindFirstChild("SampleSize", true)
    if sample and sample:IsA("TextLabel") then
        local oneIn = sample.Text:match("1%s+in%s+(.+)")
        if oneIn then
            return parseNumber(oneIn)
        end
    end

    return 0
end

local function getBestPet()
    local best = nil
    local bestIncome = -1

    for _, pet in ipairs(getOwnPets()) do
        local income = getPetIncome(pet)
        if income > bestIncome then
            best = pet
            bestIncome = income
        end
    end

    return best, math.max(bestIncome, 0)
end




local function equipToolByName(name)
    local char, humanoid = getCharacter()
    if not char or not humanoid then
        return false
    end

    local backpack = player:FindFirstChildOfClass("Backpack")
    local tool = char:FindFirstChild(name) or (backpack and backpack:FindFirstChild(name))

    if not tool or not tool:IsA("Tool") then
        return false
    end

    if tool.Parent ~= char then
        pcall(function()
            humanoid:EquipTool(tool)
        end)
    end

    return tool.Parent == char
end

local KNOWN_WORLD_EGG_LUCK = {
    ["Giant Egg"] = 0,
    ["Dragon Egg"] = 0,
    ["White Egg"] = 1,
    ["Brown Egg"] = 5,
    ["Cracked Egg"] = 30,
    ["Easter Egg"] = 50,
    ["Stone Egg"] = 100,
    ["Leaf Egg"] = 200,
    ["Mushroom Egg"] = 500,
    ["Flower Egg"] = 750,
    ["Slime Egg"] = 1000,
    ["Ice Egg"] = 3000,
    ["Glass Egg"] = 10000,
    ["Golden Egg"] = 30000,
    ["Diamond Egg"] = 90000,
    ["Crystal Egg"] = 150000,
    ["Skull Egg"] = 250000,
    ["Asteroid Egg"] = 500000,
    ["Dominus Egg"] = 700000,
    ["Flaming Egg"] = 1000000,
    ["Sinister Egg"] = 3000000,
    ["Soul Egg"] = 7000000,
    ["Aurora Egg"] = 300000000,
    ["Galaxy Egg"] = 1500000000,
    ["Blackhole Egg"] = 100000000000,
    ["Solaris Egg"] = 300000000000,
    ["Cherub Egg"] = 1000000000000,
    ["Bloom Egg"] = 2000000000,
    ["Volcanic Egg"] = 2500000000000,
}

local function normalizedEggName(value)
    return string.lower(trim(tostring(value or "")))
end

local function eggNameMatches(eggName, wantedName)
    local a = normalizedEggName(eggName)
    local b = normalizedEggName(wantedName)

    if a == "" or b == "" then
        return false
    end

    if a == b then
        return true
    end

    return a:find(b, 1, true) ~= nil
        or b:find(a, 1, true) ~= nil
end

local function getWorldEggName(egg)
    if not egg then return "" end
    local function canonical(value)
        local text = tostring(value or ""):gsub("<[^>]*>", ""):gsub("\194\160", " ")
        local key = string.lower(text):gsub("[%s_%-]", "")
        for name in pairs(KNOWN_WORLD_EGG_LUCK) do
            if string.lower(name):gsub("[%s_%-]", "") == key then return name end
        end
        return nil
    end
    return canonical(egg:GetAttribute("EggName")) or canonical(egg.Name)
        or trim(tostring(egg:GetAttribute("EggName") or egg.Name))
end

local function formatCompactNumber(n)
    n = tonumber(n) or 0

    if n >= 1e12 then
        return string.format("%.2gT", n / 1e12)
    elseif n >= 1e9 then
        return string.format("%.2gB", n / 1e9)
    elseif n >= 1e6 then
        return string.format("%.2gM", n / 1e6)
    elseif n >= 1e3 then
        return string.format("%.2gK", n / 1e3)
    end

    return tostring(math.floor(n))
end

local function getEggLuck(egg)
    local handle = egg and egg:FindFirstChild("Handle")
    local eggLuck = handle and handle:FindFirstChild("EggLuck")
    local luck = eggLuck and eggLuck:FindFirstChild("Luck")

    if luck and luck:IsA("TextLabel") then
        local parsed = parseNumber(luck.Text)
        if parsed > 0 then
            return parsed, luck.Text
        end
    end

    -- World pickup eggs do not always contain the same EggLuck UI used by
    -- placed eggs. Fall back to the known live egg ladder by model name.
    local fallback = KNOWN_WORLD_EGG_LUCK[getWorldEggName(egg)]
    if fallback ~= nil then
        return fallback, formatCompactNumber(fallback)
    end

    return 0, "0"
end

local MUTATION_CANONICAL = {
    shocked = "Shocked",
    volted = "Volted",
    rage = "Rage",
    void = "Void",
    eternal = "Eternal",
    gold = "Gold",
    rainbow = "Rainbow",
    magma = "Magma",
}

local function normalizeMutationValue(value)
    if value == nil then
        return nil
    end

    local text = string.lower(trim(tostring(value)))
    if text == "" or text == "none" or text == "normal" or text == "default" then
        return nil
    end

    -- Prefer exact values first, then tolerate labels such as "Mutation: Void".
    if MUTATION_CANONICAL[text] then
        return MUTATION_CANONICAL[text]
    end

    for key, canonical in pairs(MUTATION_CANONICAL) do
        if text:find(key, 1, true) then
            return canonical
        end
    end

    return nil
end

local function getEggMutation(egg)
    if not egg then
        return "None"
    end

    -- The live game has used more than one location for mutation metadata.
    -- Read the model first, then fall back to descendants / value objects / UI labels.
    local directKeys = {
        "Mutation",
        "EggMutation",
        "MutationName",
        "Variant",
    }

    for _, key in ipairs(directKeys) do
        local found = normalizeMutationValue(egg:GetAttribute(key))
        if found then
            return found
        end
    end

    for key, value in pairs(egg:GetAttributes()) do
        local lowerKey = string.lower(tostring(key))
        if lowerKey:find("mutation", 1, true) or lowerKey:find("variant", 1, true) then
            local found = normalizeMutationValue(value)
            if found then
                return found
            end
        end
    end

    for _, obj in ipairs(egg:GetDescendants()) do
        local lowerName = string.lower(obj.Name)

        if obj:IsA("StringValue")
            and (lowerName:find("mutation", 1, true) or lowerName:find("variant", 1, true)) then
            local found = normalizeMutationValue(obj.Value)
            if found then
                return found
            end
        end

        for key, value in pairs(obj:GetAttributes()) do
            local lowerKey = string.lower(tostring(key))
            if lowerKey:find("mutation", 1, true) or lowerKey:find("variant", 1, true) then
                local found = normalizeMutationValue(value)
                if found then
                    return found
                end
            end
        end

        -- Mutation UI is sometimes rendered as text below the egg. Only scan
        -- text objects whose name hints that they are mutation / variant labels.
        if (obj:IsA("TextLabel") or obj:IsA("TextButton"))
            and (lowerName:find("mutation", 1, true)
                or lowerName:find("variant", 1, true)
                or lowerName == "status") then
            local found = normalizeMutationValue(obj.Text)
            if found then
                return found
            end
        end

        -- Some builds name a child directly after the active mutation.
        local exactName = MUTATION_CANONICAL[lowerName]
        if exactName then
            return exactName
        end
    end

    return "None"
end

local MUTATION_VALUE_MULTIPLIERS = {
    ["none"] = 1,
    ["shocked"] = 2,
    ["volted"] = 3,
    ["rage"] = 4,
    ["void"] = 10,
    ["eternal"] = 100,
    ["gold"] = 2,
    ["rainbow"] = 10,
}

local function getEggMutationValue(egg)
    local mutation = string.lower(getEggMutation(egg))
    return MUTATION_VALUE_MULTIPLIERS[mutation] or 1
end

local function getEggPredictedValue(egg)
    local luck = select(1, getEggLuck(egg))
    local mult = Settings.PreferMutationValue and getEggMutationValue(egg) or 1
    return math.max(luck, 0) * math.max(mult, 1)
end

local function eggMatches(egg, nameCSV, mutation, minLuck)
    if not egg or not egg:IsA("Model") then
        return false
    end

    if not csvContains(nameCSV, getWorldEggName(egg)) then
        return false
    end

    if mutation and mutation ~= "" and mutation ~= "Any" then
        if string.lower(getEggMutation(egg)) ~= string.lower(mutation) then
            return false
        end
    end

    local luck = getEggLuck(egg)
    if luck < (tonumber(minLuck) or 0) then
        return false
    end

    return true
end

local function getPickupPrompt(egg)
    if not egg then
        return nil
    end

    local cache =
        ENV.THUMBSHUB_EGG_RUNTIME_CACHE[egg]

    if not cache then
        cache = {}
        ENV.THUMBSHUB_EGG_RUNTIME_CACHE[egg] = cache
    end

    local cached = cache.pickupPrompt

    if cached
        and cached.Parent
        and cached:IsDescendantOf(egg) then
        return cached
    end

    local now = os.clock()

    if cache.pickupPromptMissAt
        and now - cache.pickupPromptMissAt < 0.35 then
        return nil
    end

    local fallback = nil

    for _, d in ipairs(egg:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local name =
                string.lower(
                    tostring(d.Name or "")
                )

            local action =
                string.lower(
                    tostring(d.ActionText or "")
                )

            -- Existing eggs use "Pickup". New egg variants/builds have also
            -- used collect/grab/take wording, so accept those as farm prompts.
            if name == "pickup"
                or action:find("pickup", 1, true)
                or action:find("pick up", 1, true)
                or action:find("collect", 1, true)
                or action:find("grab", 1, true)
                or action:find("take", 1, true) then

                cache.pickupPrompt = d
                cache.pickupPromptMissAt = nil
                return d
            end

            -- Last-resort fallback: if an egg model only has one prompt and its
            -- wording changed, keep it available for movement/claim checks.
            if fallback == nil then
                fallback = d
            else
                fallback = false
            end
        end
    end

    if fallback and fallback ~= false then
        cache.pickupPrompt = fallback
        cache.pickupPromptMissAt = nil
        return fallback
    end

    cache.pickupPrompt = nil
    cache.pickupPromptMissAt = now
    return nil
end

local function getRenderedEggs()
    local folder = workspace:FindFirstChild("RenderedEggs")
    if not folder then
        return {}
    end

    local eggs = {}
    local seen = {}

    -- Keep the old direct-child path first because that is the normal layout.
    for _, egg in ipairs(folder:GetChildren()) do
        if egg:IsA("Model") then
            seen[egg] = true
            table.insert(eggs, egg)
        end
    end

    -- Compatibility path for newly-added eggs that are nested inside a
    -- container/folder instead of being direct RenderedEggs children.
    for _, obj in ipairs(folder:GetDescendants()) do
        if obj:IsA("Model")
            and not seen[obj]
            and (
                KNOWN_WORLD_EGG_LUCK[obj.Name] ~= nil
                or obj.Name:lower():find("egg", 1, true) ~= nil
            ) then

            local prompt = getPickupPrompt(obj)

            if prompt then
                seen[obj] = true
                table.insert(eggs, obj)
            end
        end
    end

    return eggs
end

local function getWorldEggTimeLeft(egg)
    if not egg then
        return nil
    end

    local cache =
        ENV.THUMBSHUB_EGG_RUNTIME_CACHE[egg]

    if not cache then
        cache = {}
        ENV.THUMBSHUB_EGG_RUNTIME_CACHE[egg] = cache
    end

    -- Fast path: reuse the actual countdown label once discovered.
    local cachedLabel = cache.timerLabel

    if cachedLabel
        and cachedLabel.Parent
        and cachedLabel:IsDescendantOf(egg) then

        local txt = tostring(cachedLabel.Text or "")

        if txt:match("^%s*%d+:%d+%s*$") then
            return parseTimer(txt)
        end

        cache.timerLabel = nil
    end

    -- Attributes are cheap to inspect and may expose remaining seconds.
    for key, value in pairs(egg:GetAttributes()) do
        local k = string.lower(tostring(key))

        if k:find("time")
            or k:find("break")
            or k:find("expire")
            or k:find("despawn")
            or k:find("remain") then

            if type(value) == "number" then
                if value >= 0 and value <= 3600 then
                    return value
                end
            elseif type(value) == "string"
                and value:match("%d+:%d+") then
                return parseTimer(value)
            end
        end
    end

    -- Do not rescan the entire egg model every farm tick.
    local now = os.clock()

    if cache.timerScanAt
        and now - cache.timerScanAt < 0.75 then
        return nil
    end

    cache.timerScanAt = now

    for _, d in ipairs(egg:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            local txt = tostring(d.Text or "")

            if txt:match("^%s*%d+:%d+%s*$") then
                cache.timerLabel = d
                return parseTimer(txt)
            end
        end
    end

    return nil
end



local function getAllUsableEggCandidates(root, estimatedSpeed)
    local out = {}

    for _, egg in ipairs(getRenderedEggs()) do
        local prompt = getPickupPrompt(egg)
        local pos = getObjectPosition(egg)

        if prompt and pos then
            local distance = (root.Position - pos).Magnitude
            local luck = select(1, getEggLuck(egg))
            local timeLeft = getWorldEggTimeLeft(egg)
            local eta = distance / math.max(estimatedSpeed, 1)
            local predictedValue = getEggPredictedValue(egg)

            table.insert(out, {
                egg = egg,
                luck = luck,
                mutationMultiplier = getEggMutationValue(egg),
                predictedValue = predictedValue,
                distance = distance,
                timeLeft = timeLeft,
                eta = eta,
            })
        end
    end

    return out
end



local function chooseFarmEgg(preferredEggName)
    local _, _, root = getCharacter()
    if not root then
        return nil
    end

    local candidates = {}
    local selection = {Visible = 0, Named = 0, Mutation = 0, Luck = 0, Distance = 0, Prompt = 0, Position = 0}
    connections.FarmSelection = selection
    local estimatedSpeed = math.max(tonumber(Settings.TweenSpeed) or 120, 1)

    local maxDistance = tonumber(Settings.MaxFarmDistance) or 0
    local arriveWith = math.max(tonumber(Settings.ArriveWithSeconds) or 0, 0)

    -- AutoRebirth can temporarily request one exact egg. This bypasses the
    -- user's ordinary egg-name / mutation filters, but still respects basic
    -- reachability so we do not chase an egg that is already doomed.
    if preferredEggName and tostring(preferredEggName) ~= "" then
        local preferred = {}

        for _, egg in ipairs(getRenderedEggs()) do
            if eggNameMatches(getWorldEggName(egg), preferredEggName) then
                local prompt = getPickupPrompt(egg)
                local pos = getObjectPosition(egg)

                if prompt and pos then
                    local distance = (root.Position - pos).Magnitude
                    local timeLeft = getWorldEggTimeLeft(egg)
                    local eta = distance / estimatedSpeed
                    local reachable = true

                    if Settings.SkipDoomedEggs and timeLeft ~= nil then
                        reachable = (eta + arriveWith) < timeLeft
                    end

                    if reachable then
                        table.insert(preferred, {
                            egg = egg,
                            distance = distance,
                            predictedValue = getEggPredictedValue(egg),
                        })
                    end
                end
            end
        end

        table.sort(preferred, function(a, b)
            if a.predictedValue ~= b.predictedValue then
                return a.predictedValue > b.predictedValue
            end

            return a.distance < b.distance
        end)

        if preferred[1] then
            return preferred[1].egg
        end
    end

    for _, egg in ipairs(getRenderedEggs()) do
        selection.Visible += 1
        if csvContains(Settings.EggNames, getWorldEggName(egg)) then
            selection.Named += 1
            local mutation = tostring(Settings.EggMutation or "Any")
            local luck = select(1, getEggLuck(egg))
            local pos = getObjectPosition(egg)
            if mutation ~= "" and string.lower(mutation) ~= "any"
                and string.lower(getEggMutation(egg)) ~= string.lower(mutation) then
                selection.Mutation += 1
            elseif luck < (tonumber(Settings.MinEggLuck) or 0) then
                selection.Luck += 1
            elseif not pos then
                selection.Position += 1
            elseif maxDistance > 0 and (root.Position - pos).Magnitude > maxDistance then
                selection.Distance += 1
            elseif not getPickupPrompt(egg) then
                selection.Prompt += 1
            else
                local distance = (root.Position - pos).Magnitude
                local timeLeft = getWorldEggTimeLeft(egg)
                local eta = distance / estimatedSpeed
                if not Settings.SkipDoomedEggs or timeLeft == nil or eta + arriveWith < timeLeft then
                    table.insert(candidates, {
                        egg = egg, luck = luck, mutationMultiplier = getEggMutationValue(egg),
                        predictedValue = getEggPredictedValue(egg), distance = distance,
                        timeLeft = timeLeft, eta = eta,
                    })
                end
            end
        end
    end

    local explicitMutation = trim(Settings.EggMutation) ~= ""
        and string.lower(trim(Settings.EggMutation)) ~= "any"
    local explicitEggNames = trim(Settings.EggNames) ~= ""
    local explicitMinLuck = (tonumber(Settings.MinEggLuck) or 0) > 0
    local hasExplicitFarmFilter = explicitMutation or explicitEggNames or explicitMinLuck

    if #candidates == 0
        and Settings.RelaxFarmFiltersIfNoMatch
        and not hasExplicitFarmFilter then
        -- Relaxing is only allowed when the user has NOT explicitly selected
        -- an egg name, mutation or minimum luck. A chosen mutation is strict.
        candidates = getAllUsableEggCandidates(root, estimatedSpeed)
    end

    if #candidates == 0 then
        return nil
    end

    if Settings.SmartEggTargeting then
        -- Work out what counts as the "good" visible group. This is relative to
        -- what is actually spawned right now, so the farm avoids junk when better
        -- eggs are available without requiring one hard-coded minimum luck.
        table.sort(candidates, function(a, b)
            if a.predictedValue ~= b.predictedValue then
                return a.predictedValue > b.predictedValue
            end
            return a.distance < b.distance
        end)

        local topPercent = math.clamp(tonumber(Settings.SmartTopPercent) or 25, 1, 100)
        local keepCount = math.max(1, math.ceil(#candidates * (topPercent / 100)))
        local thresholdValue = candidates[keepCount].predictedValue

        local smart = {}

        for _, candidate in ipairs(candidates) do
            if candidate.predictedValue >= thresholdValue then
                -- Higher predicted egg value wins, but ETA matters too.
                -- The +1 prevents extremely short journeys from exploding the score.
                candidate.smartScore = candidate.predictedValue / math.max(candidate.eta + 1, 1)
                table.insert(smart, candidate)
            end
        end

        table.sort(smart, function(a, b)
            if a.smartScore ~= b.smartScore then
                return a.smartScore > b.smartScore
            end
            if a.predictedValue ~= b.predictedValue then
                return a.predictedValue > b.predictedValue
            end
            return a.distance < b.distance
        end)

        return smart[1] and smart[1].egg or nil
    end

    table.sort(candidates, function(a, b)
        if Settings.BestEggFirst and a.predictedValue ~= b.predictedValue then
            return a.predictedValue > b.predictedValue
        end
        return a.distance < b.distance
    end)

    return candidates[1] and candidates[1].egg or nil
end

local function getBasketCapacityText()
    local mainGui = playerGui:FindFirstChild("Main")
    local basket = mainGui and mainGui:FindFirstChild("BasketTracker")
    local capacity = basket and basket:FindFirstChild("Capacity")

    if capacity and capacity:IsA("TextLabel") then
        return capacity.Text
    end

    return ""
end

local function getBasketCounts()
    local capacity = getBasketCapacityText()
    local current, maximum = capacity:match("(%d+)%s*/%s*(%d+)")

    current = tonumber(current)
    maximum = tonumber(maximum)

    if current and maximum then
        return current, maximum
    end

    return nil, nil
end



local Reliability = {
    UndergroundGravityForce = nil :: VectorForce?,
    UndergroundGravityAttachment = nil :: Attachment?,
    UndergroundLinearVelocity = nil :: LinearVelocity?,
    UndergroundVelocityAttachment = nil :: Attachment?,
    LastCarriedEggName = nil :: string?,
    LiveEggBreakDiscoveryAt = nil :: number?,
    CarryBreakTimerSample = nil :: number?,
    CarryBreakTimerSampleClock = nil :: number?,
    LiveTimerStatusBucket = nil :: number?,
    LiveTimerStatusAt = nil :: number?,
}

-- BUILD143: Server Hop runtime state must be initialized only after the
-- Reliability table exists. Build142 placed these fields ~2,800 lines too
-- early, which caused startup to fail immediately.
Reliability.HopFarmCollectedThisServer = 0
Reliability.HopFarmNoTargetSince = 0
Reliability.HopFarmServerEnteredAt = os.clock()
Reliability.HopFarmLastCollected = nil

-- BUILD147 indexed-hop runtime.
-- Reports contain server/egg data only; no player identity is included.
Reliability.IndexLastSignature = nil
Reliability.IndexLastReportAt = 0
Reliability.IndexLastQueryAt = 0
Reliability.IndexLastResult = nil
Reliability.IndexLastError = nil
Reliability.IndexVisited = {}
Reliability.IndexReportSupported = nil
Reliability.IndexDirty = true

-- ============================================================
-- OPTIONAL UNDERGROUND NOCLIP FARM
-- ============================================================
-- The normal Stable method remains the default and continues to use the
-- existing movement/return path. Underground Noclip changes only travel:
--
--   surface -> descend below map -> horizontal tunnel -> surface at egg
--   pickup -> fast surface tween to the plot edge -> tween inside at floor
--   height -> confirm the basket released the egg.
--
-- No basket/next-target logic is replaced here.

function Reliability.isUndergroundFarm()
    return false -- the below-map route was patched
end

function Reliability.setUndergroundAntiGravity(enabled)
    if enabled then
        local _, humanoid, root = getCharacter()

        if not root
            or not humanoid
            or humanoid.Health <= 0 then
            return false
        end

        if Reliability.UndergroundGravityForce
            and Reliability.UndergroundGravityForce.Parent
            and Reliability.UndergroundGravityAttachment
            and Reliability.UndergroundGravityAttachment.Parent then

            Reliability.UndergroundGravityForce.Force =
                Vector3.new(
                    0,
                    math.max(root.AssemblyMass, 1)
                        * workspace.Gravity,
                    0
                )

            return true
        end

        local attachment =
            Instance.new("Attachment")

        attachment.Name =
            "ThumbsHubUndergroundGravity"

        attachment.Parent = root

        local force =
            Instance.new("VectorForce")

        force.Name =
            "ThumbsHubUndergroundGravityForce"

        force.Attachment0 = attachment
        force.RelativeTo =
            Enum.ActuatorRelativeTo.World

        force.ApplyAtCenterOfMass = true

        force.Force =
            Vector3.new(
                0,
                math.max(root.AssemblyMass, 1)
                    * workspace.Gravity,
                0
            )

        force.Parent = root

        Reliability.UndergroundGravityAttachment =
            attachment

        Reliability.UndergroundGravityForce =
            force

        return true
    end

    if Reliability.UndergroundGravityForce then
        pcall(function()
            Reliability.UndergroundGravityForce:Destroy()
        end)

        Reliability.UndergroundGravityForce = nil
    end

    if Reliability.UndergroundGravityAttachment then
        pcall(function()
            Reliability.UndergroundGravityAttachment:Destroy()
        end)

        Reliability.UndergroundGravityAttachment = nil
    end

    return true
end

function Reliability.cargoReturnCanContinue(
    originalContinue
)
    if not alive then
        return false
    end

    if not (
        Settings.AutoFarmEggs
        or Settings.AutoRebirth
    ) then
        return false
    end

    local current, _, basketState =
        Reliability.getBasketState()

    -- Once an egg is genuinely in the basket, returning it home has absolute
    -- priority. The world egg often disappears immediately after pickup, so
    -- return movement must not depend on the old pickup cycle staying valid.
    if current ~= nil and current > 0 then
        return true
    end

    if basketState == "full"
        or basketState == "partial" then
        return true
    end

    -- BasketTracker may briefly be unavailable. Preserve the normal callback
    -- in that case rather than inventing a new release condition.
    if originalContinue then
        local ok, result =
            pcall(originalContinue)

        if ok then
            return result == true
        end
    end

    return true
end

function Reliability.setUndergroundNoclip(enabled)
    Reliability.UndergroundCollisionState =
        Reliability.UndergroundCollisionState
        or setmetatable({}, {__mode = "k"})

    local state = Reliability.UndergroundCollisionState
    local character = player.Character

    if enabled then
        Reliability.UndergroundNoclipActive = true

        if character then
            for _, obj in ipairs(character:GetDescendants()) do
                if obj:IsA("BasePart") then
                    if state[obj] == nil then
                        state[obj] = obj.CanCollide
                    end

                    obj.CanCollide = false
                end
            end
        end

        return
    end

    Reliability.UndergroundNoclipActive = false

    for part, original in pairs(state) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = original
            end)
        end

        state[part] = nil
    end
end

function Reliability.clearUndergroundVelocity()
    -- Compatibility cleanup for the previous physical-movement build.
    if Reliability.UndergroundLinearVelocity then
        pcall(function()
            Reliability.UndergroundLinearVelocity:Destroy()
        end)
        Reliability.UndergroundLinearVelocity = nil
    end

    if Reliability.UndergroundVelocityAttachment then
        pcall(function()
            Reliability.UndergroundVelocityAttachment:Destroy()
        end)
        Reliability.UndergroundVelocityAttachment = nil
    end

    Reliability.setUndergroundAntiGravity(false)
end

function Reliability.tweenNoclipSegment(
    destination,
    shouldContinue,
    speed
)
    if not destination then
        return false
    end

    local character, humanoid, root = getCharacter()

    if not character
        or not humanoid
        or not root
        or humanoid.Health <= 0 then
        return false
    end

    -- BUILD123: burst movement is symmetrical: direct-position outbound and inbound
    -- enabled, direct-position both outbound to the selected egg and inbound
    -- to the plot. This only changes local movement; it is never treated as
    -- proof that the server accepted or retained the egg.
    local basketCount = select(1, getBasketCounts())
    local liveBasket = player:FindFirstChild("Basket")
    local carryingEggNow =
        (basketCount ~= nil and basketCount > 0)
        or (liveBasket and #liveBasket:GetChildren() > 0)

    if busyFarm then
        local movedByTP = tryInstantEggTravel(destination, shouldContinue)
        if movedByTP then
            connections.InstantTravel.LastOutcome = carryingEggNow
                and "TP return to plot requested; retention unconfirmed"
                or "TP to egg requested; pickup retention unconfirmed"
            return true
        end
        if shouldContinue and not shouldContinue() then return false end

        -- BUILD127: egg Auto Farm is TP-only. Do not continue into the old
        -- TweenService path when a direct move fails; let the farm retry TP.
        connections.InstantTravel.LastOutcome = carryingEggNow
            and "TP-only return move failed; no tween fallback"
            or "TP-only outbound move failed; no tween fallback"
        return false
    end

    local distance =
        (root.Position - destination).Magnitude

    if distance <= 1.5 then
        return true
    end

    speed = math.clamp(
        tonumber(speed)
            or tonumber(Settings.TweenSpeed)
            or 240,
        10,
        1000
    )

    local duration =
        math.max(
            distance / speed,
            0.04
        )

    local look = root.CFrame.LookVector

    if look.Magnitude < 0.05 then
        look = Vector3.new(0, 0, -1)
    end

    Reliability.setUndergroundNoclip(true)
    Reliability.setUndergroundAntiGravity(true)

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    local tween =
        TweenService:Create(
            root,
            TweenInfo.new(
                duration,
                Enum.EasingStyle.Linear,
                Enum.EasingDirection.Out
            ),
            {
                CFrame = CFrame.lookAt(
                    destination,
                    destination + look
                )
            }
        )

    activeFarmTween = tween
    tween:Play()

    local started = os.clock()

    while alive
        and activeFarmTween == tween do

        if shouldContinue
            and not shouldContinue() then

            pcall(function()
                tween:Cancel()
            end)

            activeFarmTween = nil
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            return false
        end

        if not root.Parent
            or humanoid.Health <= 0 then

            pcall(function()
                tween:Cancel()
            end)

            activeFarmTween = nil
            return false
        end

        -- Keep both noclip and gravity cancellation active for the whole
        -- fast tween. The previous build only refreshed noclip, which allowed
        -- Roblox physics to keep pulling the unanchored character downward.
        Reliability.setUndergroundNoclip(true)
        Reliability.setUndergroundAntiGravity(true)

        -- Do not allow downward momentum to accumulate between tween frames.
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        if (
            root.Position
            - destination
        ).Magnitude <= 2.0 then

            pcall(function()
                tween:Cancel()
            end)

            activeFarmTween = nil
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            return true
        end

        if root.Position.Y
            <= workspace.FallenPartsDestroyHeight + 25 then

            pcall(function()
                tween:Cancel()
            end)

            activeFarmTween = nil

            setStatus(
                "Underground Farm • safety floor reached"
            )

            return false
        end

        if os.clock() - started
            > duration + 0.8 then
            break
        end

        task.wait(0.015)
    end

    activeFarmTween = nil

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    return root.Parent ~= nil
        and (
            root.Position
            - destination
        ).Magnitude <= 3.5
end

function Reliability.undergroundTravelToSurface(
    surfacePosition,
    shouldContinue,
    speed,
    plotInsidePosition
)
    if not surfacePosition then
        return false
    end

    local character, humanoid, root =
        getCharacter()

    if not character
        or not humanoid
        or not root
        or humanoid.Health <= 0 then
        return false
    end

    local recoveryPosition =
        root.Position

    local destroyHeight =
        workspace.FallenPartsDestroyHeight

    if surfacePosition.Y
        <= destroyHeight + 80 then

        setStatus(
            "Underground Farm • invalid target height • retargeting"
        )

        return false
    end

    local dynamicReturn =
        plotInsidePosition ~= nil

    local targetSurface =
        surfacePosition

    -- Stay a little farther outside the ranch so the return trigger cannot
    -- fire before the Arrive With timer says to enter.
    if dynamicReturn then
        local away =
            Vector3.new(
                surfacePosition.X
                    - plotInsidePosition.X,
                0,
                surfacePosition.Z
                    - plotInsidePosition.Z
            )

        if away.Magnitude > 0.05 then
            targetSurface =
                surfacePosition
                + away.Unit * 8
        end
    end

    local depth =
        math.clamp(
            tonumber(Settings.UndergroundDepth)
                or 14,
            6,
            40
        )

    local desiredTunnelY =
        math.min(
            recoveryPosition.Y,
            targetSurface.Y
        ) - depth

    local minimumTunnelY =
        math.max(
            destroyHeight + 80,
            math.min(
                recoveryPosition.Y,
                targetSurface.Y
            ) - 70
        )

    local tunnelY =
        math.max(
            minimumTunnelY,
            desiredTunnelY
        )

    -- Allow valid eggs regardless of how high the player currently is.
    -- Starting Auto Farm from a tree, cliff or high island should not make a
    -- normal lower-map egg look invalid. Absolute void safety is still handled
    -- by the FallenPartsDestroyHeight check above.

    local descendPoint =
        Vector3.new(
            recoveryPosition.X,
            tunnelY,
            recoveryPosition.Z
        )

    local tunnelPoint =
        Vector3.new(
            targetSurface.X,
            tunnelY,
            targetSurface.Z
        )

    local surfacePoint =
        Vector3.new(
            targetSurface.X,
            targetSurface.Y + 2.5,
            targetSurface.Z
        )

    local moveSpeed

    if dynamicReturn then
        moveSpeed =
            math.clamp(
                tonumber(Settings.ReturnTweenSpeed)
                    or 360,
                10,
                1000
            )
    else
        moveSpeed =
            math.clamp(
                tonumber(Settings.TweenSpeed)
                    or 240,
                10,
                1000
            )
    end

    Reliability.clearUndergroundVelocity()
    Reliability.setUndergroundNoclip(true)
    Reliability.setUndergroundAntiGravity(true)

    if dynamicReturn then
        setStatus(
            "Auto Farm • fast tween noclip return • "
            .. tostring(
                math.floor(
                    moveSpeed + 0.5
                )
            )
            .. " st/s"
        )
    else
        setStatus(
            "Auto Farm • fast tween noclip → egg • "
            .. tostring(
                math.floor(
                    moveSpeed + 0.5
                )
            )
            .. " st/s"
        )
    end

    -- 1) Smoothly descend below the terrain.
    local ok =
        Reliability.tweenNoclipSegment(
            descendPoint,
            shouldContinue,
            moveSpeed
        )

    -- 2) Smoothly travel under the map.
    if ok then
        ok =
            Reliability.tweenNoclipSegment(
                tunnelPoint,
                shouldContinue,
                moveSpeed
            )
    end

    -- 3) Smoothly rise back to the egg / ranch edge.
    if ok then
        ok =
            Reliability.tweenNoclipSegment(
                surfacePoint,
                shouldContinue,
                moveSpeed
            )
    end

    -- No CFrame recovery/snap. If a trip fails, just restore collision and let
    -- the normal farm retry rather than teleporting the character.
    Reliability.setUndergroundAntiGravity(false)
    Reliability.setUndergroundNoclip(false)

    local _, finalHumanoid, finalRoot =
        getCharacter()

    if finalRoot then
        finalRoot.AssemblyLinearVelocity =
            Vector3.zero

        finalRoot.AssemblyAngularVelocity =
            Vector3.zero
    end

    return ok
        and finalHumanoid
        and finalHumanoid.Health > 0
end

function Reliability.triggerUndergroundPrompt(
    prompt,
    shouldContinue
)
    if not prompt
        or not prompt:IsA("ProximityPrompt") then
        return false
    end

    local pos =
        getObjectPosition(prompt.Parent)

    if not pos then
        return false
    end

    setStatus(
        "Auto Farm • underground tunnel → "
        .. tostring(
            prompt.Parent
            and prompt.Parent.Parent
            and prompt.Parent.Parent.Name
            or "egg"
        )
    )

    if not Reliability.undergroundTravelToSurface(
        pos,
        shouldContinue,
        tonumber(Settings.TweenSpeed) or 240
    ) then
        return false
    end

    -- Let the Humanoid settle after the anchored underground tunnel before
    -- interacting with the egg prompt.
    task.wait(0.06)

    task.wait(
        math.max(
            0,
            tonumber(Settings.ClaimDelay) or 0
        )
    )

    if shouldContinue
        and not shouldContinue() then
        return false
    end

    if prompt.Parent and not prompt.Enabled then
        local enableUntil = os.clock() + 1.25

        while alive
            and prompt.Parent
            and not prompt.Enabled
            and os.clock() < enableUntil do

            if shouldContinue
                and not shouldContinue() then
                return false
            end

            task.wait(0.04)
        end
    end

    if not prompt.Parent
        or not prompt.Enabled then
        return false
    end

    if typeof(fireproximityprompt) == "function" then
        local ok =
            pcall(
                fireproximityprompt,
                prompt
            )

        if ok then
            return true
        end
    end

    return pcall(function()
        prompt:InputHoldBegin()
        task.wait(
            math.max(
                tonumber(prompt.HoldDuration) or 0,
                0.05
            ) + 0.08
        )
        prompt:InputHoldEnd()
    end)
end

function Reliability.getBasketState()
    local current, maximum = getBasketCounts()

    if current == nil or maximum == nil or maximum <= 0 then
        return current, maximum, "unknown"
    end

    if current <= 0 then
        return current, maximum, "empty"
    end

    if current >= maximum then
        return current, maximum, "full"
    end

    return current, maximum, "partial"
end

function Reliability.hasBasketSpace()
    local _, _, state =
        Reliability.getBasketState()

    return state == "empty"
        or state == "partial"
end




function Reliability.hasPhysicalEggCarry(expectedEggName)
    local character = player.Character

    if not character then
        return false
    end

    local expectedLower =
        string.lower(tostring(expectedEggName or ""))

    for _, obj in ipairs(character:GetChildren()) do
        if obj:IsA("Tool") then
            local lower =
                string.lower(tostring(obj.Name or ""))

            if lower:find("egg", 1, true)
                and (
                    expectedLower == ""
                    or lower == expectedLower
                    or lower:find(expectedLower, 1, true)
                    or expectedLower:find(lower, 1, true)
                ) then
                return true, "enter-now"
            end
        end
    end

    return character:FindFirstChild("HeldEggDisplay") ~= nil
end

local function isCarryingEgg()
    local current = select(1, getBasketCounts())

    if current ~= nil and current > 0 then
        return true
    end

    local character = player.Character

    if character then
        for _, obj in ipairs(character:GetChildren()) do
            if obj:IsA("Tool")
                and string.lower(tostring(obj.Name or "")):find(
                    "egg",
                    1,
                    true
                ) then
                return true
            end
        end

        if character:FindFirstChild("HeldEggDisplay") then
            return true
        end
    end

    return false
end


function Reliability.hasUnresolvedFarmCargo()
    if connections.EggReturn.Active then return true end
    local _, _, basketState =
        Reliability.getBasketState()

    -- If BasketTracker is readable, trust it for NORMAL Auto Farm.
    -- This prevents a stale HeldEggDisplay/Tool from re-triggering the
    -- return route after the game has already changed 1/1 -> 0/1.
    if basketState == "empty" then
        return false
    end

    if basketState == "full"
        or basketState == "partial" then
        return true
    end

    -- Only when BasketTracker is unavailable do we fall back to the
    -- character-side carry signal.
    return isCarryingEgg()
end



local function getBasketSellPrompt()
    local stalls = workspace:FindFirstChild("Stalls")
    if not stalls then
        return nil
    end

    -- Prefer the known Sell stall if it exists.
    local roots = {}
    local namedSell = stalls:FindFirstChild("Sell")
    if namedSell then
        table.insert(roots, namedSell)
    end
    table.insert(roots, stalls)

    local seen = {}

    for _, root in ipairs(roots) do
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.Enabled and not seen[d] then
                seen[d] = true

                local combined = string.lower(
                    tostring(d.Name) .. " "
                    .. tostring(d.ActionText) .. " "
                    .. tostring(d.ObjectText)
                )

                if combined:find("sell") then
                    return d
                end
            end
        end
    end

    return nil
end

local function sellCurrentBasket(shouldContinue)
    local before, maximum = getBasketCounts()

    if not before or before <= 0 then
        return true
    end

    local prompt = getBasketSellPrompt()

    if not prompt then
        setStatus("Basket full • Sell prompt not found")
        return false
    end

    setStatus("Basket " .. tostring(before) .. "/" .. tostring(maximum or "?") .. " • selling...")

    local fired = triggerPrompt(prompt, shouldContinue)
    if not fired then
        setStatus("Could not trigger Sell prompt")
        return false
    end

    local started = os.clock()

    while alive and os.clock() - started < 4 do
        if shouldContinue and not shouldContinue() then
            return false
        end

        local current = select(1, getBasketCounts())

        if current and current < before then
            setStatus("Basket space cleared")
            return true
        end

        task.wait(0.03)
    end

    setStatus("Sell prompt fired • basket did not change")
    return false
end

local function getOwnNestReturnPosition()
    local plot = getOwnPlot()
    if not plot then
        return nil
    end

    local nests = plot:FindFirstChild("Nests")

    if nests then
        for _, d in ipairs(nests:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.Name == "Place" then
                local pos = getObjectPosition(d.Parent)
                if pos then
                    return pos
                end
            end
        end

        for _, d in ipairs(nests:GetDescendants()) do
            if d:IsA("BasePart")
                and string.lower(d.Name):find("placepromptanchor", 1, true) then
                return d.Position
            end
        end

        for _, d in ipairs(nests:GetDescendants()) do
            if d:IsA("BasePart") then
                return d.Position
            end
        end
    end

    if plot:IsA("Model") and plot.PrimaryPart then
        return plot.PrimaryPart.Position
    end

    for _, d in ipairs(plot:GetDescendants()) do
        if d:IsA("BasePart") then
            return d.Position
        end
    end

    return nil
end

local function getPlotBoundaryReference(plot)
    if not plot then
        return nil, nil
    end

    -- Verified by the system report; the fence hitbox is larger than the floor.
    local baseplate = plot:FindFirstChild("Baseplate")
    if baseplate and baseplate:IsA("BasePart") then
        return baseplate.CFrame, baseplate.Size
    end

    -- The plot floor/platform is normally the largest horizontal BasePart
    -- belonging to the player's plot. Use it to find the real return boundary.
    local bestPart = nil
    local bestArea = 0

    for _, d in ipairs(plot:GetDescendants()) do
        if d:IsA("BasePart") then
            local area = math.max(d.Size.X, 0.01) * math.max(d.Size.Z, 0.01)

            if area > bestArea then
                bestArea = area
                bestPart = d
            end
        end
    end

    if bestPart then
        return bestPart.CFrame, bestPart.Size
    end

    if plot:IsA("Model") then
        local ok, cf, size = pcall(function()
            return plot:GetBoundingBox()
        end)

        if ok and cf and size then
            return cf, size
        end
    end

    return nil, nil
end



function Reliability.isInsideOwnPlot(worldPosition, inset)
    if typeof(worldPosition) ~= "Vector3" then
        return false
    end

    local plot = getOwnPlot()
    local cf, size = getPlotBoundaryReference(plot)

    if not cf or not size then
        return false
    end

    inset = tonumber(inset) or 1.5

    local p = cf:PointToObjectSpace(worldPosition)
    local halfX = math.max(1, size.X * 0.5 - inset)
    local halfZ = math.max(1, size.Z * 0.5 - inset)

    return math.abs(p.X) <= halfX
        and math.abs(p.Z) <= halfZ
end

function Reliability.getPlotCenterInside()
    local plot = getOwnPlot()
    local cf, size = getPlotBoundaryReference(plot)

    if not cf or not size then
        return nil
    end

    return cf:PointToWorldSpace(Vector3.new(
        0,
        size.Y * 0.5 + 3,
        0
    ))
end

function Reliability.pathWalkTo(targetPosition, stopDistance, timeout, shouldContinue)
    if typeof(targetPosition) ~= "Vector3" then
        return false
    end

    stopDistance = tonumber(stopDistance) or 4
    timeout = tonumber(timeout) or 18

    local started = os.clock()
    local recomputes = 0

    while alive
        and os.clock() - started < timeout
        and recomputes < 5 do

        if shouldContinue and not shouldContinue() then
            stopCurrentMovement()
            return false
        end

        local _, humanoid, root = getCharacter()

        if not humanoid or not root or humanoid.Health <= 0 then
            return false
        end

        if (root.Position - targetPosition).Magnitude <= stopDistance then
            humanoid:Move(Vector3.zero, false)
            return true
        end

        local path = PathfindingService:CreatePath({
            AgentRadius = 1.5,
            AgentHeight = 5,
            AgentCanJump = true,
            AgentCanClimb = true,
            WaypointSpacing = 3,
        })

        local computed = pcall(function()
            path:ComputeAsync(root.Position, targetPosition)
        end)

        if not computed or path.Status ~= Enum.PathStatus.Success then
            recomputes += 1
            humanoid.Jump = true
            task.wait(0.18)
            continue
        end

        local blocked = false

        for _, waypoint in ipairs(path:GetWaypoints()) do
            if shouldContinue and not shouldContinue() then
                stopCurrentMovement()
                return false
            end

            _, humanoid, root = getCharacter()

            if not humanoid or not root or humanoid.Health <= 0 then
                return false
            end

            if (root.Position - targetPosition).Magnitude <= stopDistance then
                humanoid:Move(Vector3.zero, false)
                return true
            end

            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end

            humanoid.WalkSpeed = math.clamp(
                tonumber(Settings.GlideSpeed) or 21,
                16,
                21
            )

            humanoid:MoveTo(waypoint.Position)

            local waypointStart = os.clock()
            local lastPos = root.Position
            local lastProgress = os.clock()

            while alive and os.clock() - waypointStart < 3.2 do
                if shouldContinue and not shouldContinue() then
                    stopCurrentMovement()
                    return false
                end

                _, humanoid, root = getCharacter()

                if not humanoid or not root or humanoid.Health <= 0 then
                    return false
                end

                if (root.Position - targetPosition).Magnitude <= stopDistance then
                    humanoid:Move(Vector3.zero, false)
                    return true
                end

                local delta = root.Position - waypoint.Position
                local flat = Vector3.new(delta.X, 0, delta.Z)

                if flat.Magnitude <= 2.2 then
                    break
                end

                local moved = (root.Position - lastPos).Magnitude

                if moved >= 0.75 then
                    lastPos = root.Position
                    lastProgress = os.clock()
                elseif os.clock() - lastProgress > 0.9 then
                    -- Fence/pet collision: jump and rebuild route.
                    humanoid.Jump = true
                    blocked = true
                    break
                end

                task.wait(0.06)
            end

            if blocked then
                break
            end

            local delta = root.Position - waypoint.Position
            local flat = Vector3.new(delta.X, 0, delta.Z)

            if flat.Magnitude > 3.2 then
                blocked = true
                break
            end
        end

        if not blocked then
            local _, h, r = getCharacter()

            if r and (r.Position - targetPosition).Magnitude <= stopDistance + 1.5 then
                if h then
                    h:Move(Vector3.zero, false)
                end
                return true
            end
        end

        recomputes += 1
        task.wait(0.10)
    end

    stopCurrentMovement()
    return false
end

function Reliability.ensureInsideOwnPlot(shouldContinue)
    local _, _, root = getCharacter()

    if root and Reliability.isInsideOwnPlot(root.Position, 1.0) then
        return true
    end

    local center = Reliability.getPlotCenterInside()

    if not center then
        return false
    end

    setStatus("Auto Rebirth • finding plot entrance...")

    Reliability.pathWalkTo(
        center,
        7,
        22,
        shouldContinue
    )

    _, _, root = getCharacter()

    return root ~= nil
        and Reliability.isInsideOwnPlot(root.Position, 0.75)
end


function Reliability.getCarriedEggName()
    local character = player.Character

    if character then
        -- Live scan proved a manually carried egg is a Tool on Character.
        for _, obj in ipairs(character:GetChildren()) do
            if obj:IsA("Tool") then
                local lower = string.lower(tostring(obj.Name or ""))

                if lower:find("egg", 1, true) then
                    return obj.Name
                end
            end
        end

        local display = character:FindFirstChild("HeldEggDisplay")

        if display then
            for _, attrName in ipairs({"EggName", "Name", "Type"}) do
                local value = display:GetAttribute(attrName)

                if value ~= nil
                    and tostring(value) ~= ""
                    and string.lower(tostring(value)):find("egg", 1, true) then
                    return tostring(value)
                end
            end

            for _, d in ipairs(display:GetDescendants()) do
                if d:IsA("TextLabel") then
                    local value = tostring(d.Text or "")

                    if string.lower(value):find("egg", 1, true) then
                        return value
                    end
                end
            end
        end
    end

    if isCarryingEgg()
        and Reliability.LastCarriedEggName
        and Reliability.LastCarriedEggName ~= "" then
        return Reliability.LastCarriedEggName
    end

    return nil
end

function Reliability.rememberCarriedEgg(
    eggName,
    wasRebirth,
    wasDiscovery,
    rebirthTarget,
    requiredPet
)
    Reliability.LastCarriedEggName = tostring(eggName or "")
    Reliability.LastCarryWasRebirth = wasRebirth == true
    Reliability.LastCarryWasDiscovery = wasDiscovery == true
    Reliability.LastCarryRebirthTarget = rebirthTarget
    Reliability.LastCarryRequiredPet = requiredPet
    Reliability.LastCarryAt = os.clock()
end

function Reliability.clearCarriedEgg()
    Reliability.LastCarriedEggName = nil
    Reliability.LastCarryWasRebirth = false
    Reliability.LastCarryWasDiscovery = false
    Reliability.LastCarryRebirthTarget = nil
    Reliability.LastCarryRequiredPet = nil
    Reliability.LastCarryAt = nil
end

function Reliability.hasPickedUpEgg(
    expectedEggName,
    beforeBasket
)
    local afterBasket =
        select(1, getBasketCounts())

    -- When BasketTracker is readable, it is authoritative for NORMAL
    -- Auto Farm pickup transitions.
    --
    -- 0/1 -> 1/1 = pickup succeeded.
    -- 0/1 -> 0/1 = pickup has NOT succeeded, even if an old
    -- HeldEggDisplay/Tool is still visually lingering.
    if beforeBasket ~= nil
        and afterBasket ~= nil then

        return afterBasket > beforeBasket
    end

    -- BasketTracker unavailable: only then use character-side carry
    -- as a compatibility fallback.
    local char = player.Character
    local expectedLower =
        string.lower(tostring(expectedEggName or ""))

    if char then
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Tool") then
                local lower =
                    string.lower(tostring(obj.Name or ""))

                if lower:find("egg", 1, true)
                    and (
                        expectedLower == ""
                        or lower == expectedLower
                        or lower:find(expectedLower, 1, true)
                        or expectedLower:find(lower, 1, true)
                    ) then

                    return true
                end
            end
        end

        if char:FindFirstChild("HeldEggDisplay") then
            return true
        end
    end

    return false
end


-- ============================================================
-- VOLCANIC EGG ACCESS DOOR
-- ============================================================
-- The updated Volcanic Egg area requires the player to pass its access
-- door/entrance before the egg can be collected.  Build139 does that first,
-- using the normal world prompt when one is available, then crosses the
-- doorway before the normal TP-only egg pickup continues.
Reliability.VolcanicDoorCache = Reliability.VolcanicDoorCache or {
    Object = nil,
    Prompt = nil,
}

local function volcanicDoorText(object)
    if not object then
        return ""
    end

    local pieces = {
        tostring(object.Name or ""),
    }

    pcall(function()
        pieces[#pieces + 1] = object:GetFullName()
    end)

    if object:IsA("ProximityPrompt") then
        pieces[#pieces + 1] = tostring(object.ActionText or "")
        pieces[#pieces + 1] = tostring(object.ObjectText or "")
    end

    return string.lower(table.concat(pieces, " "))
end

local function volcanicDoorScore(object, eggPosition)
    if not object or typeof(eggPosition) ~= "Vector3" then
        return nil
    end

    local position

    if object:IsA("ProximityPrompt") then
        position = getObjectPosition(object.Parent)
    else
        position = getObjectPosition(object)
    end

    if typeof(position) ~= "Vector3" then
        return nil
    end

    local distance = (position - eggPosition).Magnitude

    -- Keep the scan local to the Volcanic Egg area so an unrelated shop door
    -- elsewhere on the map can never win.
    if distance > 700 then
        return nil
    end

    local textValue = volcanicDoorText(object)
    local score = 0

    -- BUILD145: the updated Volcanic Egg objective explicitly calls this
    -- "The Lair", so strongly prefer objects whose hierarchy identifies the
    -- lair instead of merely choosing any nearby object named Door.
    if textValue:find("lair", 1, true) then
        score += 320
    end

    if textValue:find("door", 1, true) then
        score += 160
    end

    if textValue:find("gate", 1, true) then
        score += 100
    end

    if textValue:find("entrance", 1, true) then
        score += 95
    end

    if textValue:find("barrier", 1, true) then
        score += 80
    end

    if textValue:find("volcan", 1, true) then
        score += 65
    end

    if textValue:find("enter", 1, true) then
        score += 45
    end

    if textValue:find("open", 1, true) then
        score += 35
    end

    if textValue:find("access", 1, true) then
        score += 30
    end

    if score <= 0 then
        return nil
    end

    -- Prefer candidates close to the egg.
    score += math.max(0, 700 - distance) / 10

    -- A real interaction prompt is stronger evidence than a name alone.
    if object:IsA("ProximityPrompt") then
        score += 80
    end

    return score, position
end

function Reliability.findVolcanicAccessDoor(egg)
    local eggPosition = getObjectPosition(egg)

    if typeof(eggPosition) ~= "Vector3" then
        return nil, nil, nil
    end

    local cache = Reliability.VolcanicDoorCache

    if cache
        and cache.Object
        and cache.Object.Parent then

        local cachedPosition =
            cache.Object:IsA("ProximityPrompt")
            and getObjectPosition(cache.Object.Parent)
            or getObjectPosition(cache.Object)

        if typeof(cachedPosition) == "Vector3"
            and (cachedPosition - eggPosition).Magnitude <= 700 then

            return cache.Object, cache.Prompt, cachedPosition
        end
    end

    pcall(function()
        player:RequestStreamAroundAsync(eggPosition)
    end)

    local bestObject
    local bestPrompt
    local bestPosition
    local bestScore = -math.huge

    -- First prefer an actual world prompt whose name/text indicates the
    -- Volcanic access door.
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("ProximityPrompt") then
            local score, position =
                volcanicDoorScore(object, eggPosition)

            if score and score > bestScore then
                bestScore = score
                bestObject = object
                bestPrompt = object
                bestPosition = position
            end
        end
    end

    -- Some doors are touch/zone based and have no prompt.  Fall back to a
    -- nearby BasePart/Model carrying a door/gate/entrance-style name.
    if not bestObject then
        for _, object in ipairs(workspace:GetDescendants()) do
            if object:IsA("BasePart")
                or object:IsA("Model") then

                local score, position =
                    volcanicDoorScore(object, eggPosition)

                if score and score > bestScore then
                    bestScore = score
                    bestObject = object
                    bestPosition = position

                    local prompt =
                        object:FindFirstChildWhichIsA(
                            "ProximityPrompt",
                            true
                        )

                    bestPrompt = prompt
                end
            end
        end
    end

    if bestObject then
        cache.Object = bestObject
        cache.Prompt = bestPrompt
    end

    return bestObject, bestPrompt, bestPosition
end

function Reliability.passVolcanicAccessDoor(egg, shouldContinue)
    -- BUILD154: exact route captured from the user's live Volcano scan.
    -- Outside standing point:
    --   -4968.696, 41274.852, -3649.502
    -- Touch/validation plane:
    --   Workspace.Volcano.VolcanoValidate
    -- Entrance trigger:
    --   Workspace.Volcano.VolcanoEntrance
    --
    -- We TP only to the outside staging point. The actual lair entry is done
    -- with ordinary Humanoid movement through both physical touch triggers.

    local function continuing()
        return alive
            and (
                not shouldContinue
                or shouldContinue()
            )
    end

    if not continuing() then
        return false
    end

    local volcano =
        workspace:FindFirstChild("Volcano")

    local validate =
        volcano
        and volcano:FindFirstChild(
            "VolcanoValidate"
        )

    local entrance =
        volcano
        and volcano:FindFirstChild(
            "VolcanoEntrance"
        )

    local outside =
        Vector3.new(
            -4968.696,
            41274.852,
            -3649.502
        )

    -- Fallback to the exact scanned coordinates if the invisible trigger
    -- parts are temporarily not streamed yet.
    local validateCenter =
        (
            validate
            and validate:IsA("BasePart")
            and validate.Position
        )
        or Vector3.new(
            -4966.714,
            41282.770,
            -3656.444
        )

    local entranceCenter =
        (
            entrance
            and entrance:IsA("BasePart")
            and entrance.Position
        )
        or Vector3.new(
            -4939.836,
            41284.703,
            -3679.983
        )

    setStatus(
        "Auto Farm • Volcanic Egg • TP to exact lair door"
    )

    Reliability.eggReturnLog(
        "Volcanic exact route • outside="
        .. tostring(outside)
        .. " • validate="
        .. tostring(validateCenter)
        .. " • entrance="
        .. tostring(entranceCenter)
    )

    if not tryInstantEggTravel(
        outside,
        shouldContinue
    ) then
        Reliability.eggReturnLog(
            "Volcanic exact route • failed to reach outside-door coordinate"
        )

        return false
    end

    if not continuing() then
        return false
    end

    -- Door registration must happen with normal character movement, not a TP
    -- through the trigger.
    setInstantTravelNoclip(false)
    Reliability.setUndergroundNoclip(false)

    local _, humanoid, root =
        getCharacter()

    if not humanoid
        or not root
        or humanoid.Health <= 0 then

        return false
    end

    humanoid.PlatformStand = false
    humanoid.AutoRotate = true

    -- Put target waypoints on the character's current floor height instead of
    -- using the vertical centre of the tall invisible trigger parts.
    local function groundYAt(position)
        local character = player.Character

        local params =
            RaycastParams.new()

        params.FilterType =
            Enum.RaycastFilterType.Exclude

        params.FilterDescendantsInstances =
            character
                and {character}
                or {}

        params.IgnoreWater = false

        local origin =
            Vector3.new(
                position.X,
                root.Position.Y + 35,
                position.Z
            )

        local result =
            workspace:Raycast(
                origin,
                Vector3.new(0, -90, 0),
                params
            )

        if result then
            return result.Position.Y + 3
        end

        return root.Position.Y
    end

    local function onGround(position)
        return Vector3.new(
            position.X,
            groundYAt(position),
            position.Z
        )
    end

    -- Exact horizontal direction from the outside scan toward the actual
    -- VolcanoEntrance trigger.
    local horizontal =
        Vector3.new(
            entranceCenter.X - outside.X,
            0,
            entranceCenter.Z - outside.Z
        )

    if horizontal.Magnitude < 0.1 then
        horizontal =
            Vector3.new(
                0.69,
                0,
                -0.72
            )
    else
        horizontal = horizontal.Unit
    end

    local validatePoint =
        onGround(validateCenter)

    local beforeEntrance =
        onGround(
            entranceCenter
            - horizontal * 6
        )

    local entrancePoint =
        onGround(entranceCenter)

    local afterEntrance =
        onGround(
            entranceCenter
            + horizontal * 10
        )

    local deepInside =
        onGround(
            entranceCenter
            + horizontal * 20
        )

    local function walkToPoint(
        point,
        label,
        timeout
    )
        if not continuing()
            or not root.Parent
            or humanoid.Health <= 0 then

            return false
        end

        setStatus(
            "Auto Farm • Volcanic Egg • "
            .. label
        )

        local deadline =
            os.clock()
            + (timeout or 2)

        repeat
            humanoid:MoveTo(point)

            local waitUntil =
                math.min(
                    deadline,
                    os.clock() + 0.20
                )

            repeat
                task.wait(0.03)
            until
                not continuing()
                or not root.Parent
                or (root.Position - point).Magnitude <= 3.5
                or os.clock() >= waitUntil

            if root.Parent
                and (root.Position - point).Magnitude <= 3.5 then

                return true
            end
        until
            not continuing()
            or not root.Parent
            or os.clock() >= deadline

        return root.Parent ~= nil
            and (root.Position - point).Magnitude <= 6
    end

    -- First cross the scanned validation touch plane immediately beside the
    -- visible doorway.
    if not walkToPoint(
        validatePoint,
        "crossing door validation",
        2.0
    ) then
        Reliability.eggReturnLog(
            "Volcanic exact route • failed at VolcanoValidate"
        )

        return false
    end

    task.wait(0.15)

    -- Then physically approach and cross the actual VolcanoEntrance trigger.
    local route = {
        {
            beforeEntrance,
            "approaching VolcanoEntrance",
            2.0,
        },
        {
            entrancePoint,
            "crossing VolcanoEntrance",
            2.0,
        },
        {
            afterEntrance,
            "entered lair",
            2.0,
        },
        {
            deepInside,
            "confirming lair registration",
            2.0,
        },
    }

    for _, step in ipairs(route) do
        if not walkToPoint(
            step[1],
            step[2],
            step[3]
        ) then
            Reliability.eggReturnLog(
                "Volcanic exact route • failed step="
                .. tostring(step[2])
            )

            return false
        end
    end

    humanoid:Move(
        Vector3.zero,
        false
    )

    root.AssemblyLinearVelocity =
        Vector3.zero

    root.AssemblyAngularVelocity =
        Vector3.zero

    setStatus(
        "Auto Farm • Volcanic Egg • lair registered • going to egg"
    )

    -- Let any Touched / zone state replicate before the normal egg TP.
    task.wait(0.75)

    Reliability.eggReturnLog(
        "Volcanic exact route • validate + entrance crossed successfully"
    )

    return continuing()
end

function Reliability.claimWorldEgg(egg, prompt, shouldContinue)
    if not egg or not prompt then
        return false
    end

    local beforeBasket = select(1, getBasketCounts())
    local expectedName = getWorldEggName(egg)

    -- BUILD141: the Volcanic Egg area has an access door that must be crossed
    -- before its pickup will register. Do that first, then leave the proven
    -- Build138 TP-only pickup flow unchanged.
    if string.lower(tostring(expectedName or ""))
        == "volcanic egg" then

        if not Reliability.passVolcanicAccessDoor(
            egg,
            shouldContinue
        ) then
            return false
        end
    end

    -- Never attempt another pickup while REAL unresolved basket cargo exists.
    --
    -- IMPORTANT:
    -- after a successful ranch return the game can briefly leave an old
    -- HeldEggDisplay/Tool visible even though BasketTracker is already 0/x.
    -- Do not let that stale character object block the next farm trip.
    local _currentBasket, _maximumBasket, basketState =
        Reliability.getBasketState()

    if basketState == "full"
        or basketState == "partial" then

        return false
    end

    -- Only fall back to character carry when BasketTracker is unavailable.
    if basketState == "unknown"
        and isCarryingEgg() then

        return false
    end

    Reliability.beginEggReturn(expectedName, false)

    for attempt = 1, 4 do
        -- IMPORTANT: successful pickup can remove the target object immediately.
        -- Confirm ownership BEFORE testing cancellation / target existence.
        if Reliability.hasPickedUpEgg(
            expectedName,
            beforeBasket
        ) then
            return true
        end

        if shouldContinue and not shouldContinue() then
            return false
        end

        if not egg.Parent or not prompt.Parent then
            local graceUntil = os.clock() + 0.55

            while alive and os.clock() < graceUntil do
                if Reliability.hasPickedUpEgg(
                    expectedName,
                    beforeBasket
                ) then
                    return true
                end

                task.wait(0.04)
            end

            return false
        end

        setStatus("Auto Farm • approaching " .. expectedName .. " • attempt " .. tostring(attempt) .. "/4")
        -- Disabled at long range is not a reason to reject this target.
        -- triggerPrompt moves first, then waits for the real prompt to enable.
        triggerPrompt(prompt, shouldContinue)
        if shouldContinue and not shouldContinue() then return false end

        local verifyUntil = os.clock() + 1.15

        while alive and os.clock() < verifyUntil do
            if Reliability.hasPickedUpEgg(
                expectedName,
                beforeBasket
            ) then
                return true
            end

            if shouldContinue and not shouldContinue() then
                return false
            end

            task.wait(0.04)
        end

        if prompt.Parent then
            local pos = getObjectPosition(prompt.Parent)

            if pos
                and not Reliability.isUndergroundFarm() then

                -- BUILD127: retry the same TP method only. Never switch to
                -- tween/land movement between pickup attempts.
                tryInstantEggTravel(
                    pos + Vector3.new(0, 0.75, 0),
                    shouldContinue
                )
            end
        end
    end

    return Reliability.hasPickedUpEgg(
        expectedName,
        beforeBasket
    )
end




-- ============================================================
-- EXACT SERVER PLACEMENT REQUEST
-- ============================================================
-- Live capture of a real manual placement proved the outbound request is:
--
--   ReplicatedStorage.Remotes.Game.EggPlaced:FireServer({
--       PlantPosition = Vector3.new(...)
--   })
--
-- The server already knows which egg is currently carried. No NestId or egg
-- name is sent. Auto Rebirth therefore only needs a valid point on OUR plot.
















-- A returned-egg notice is diagnostic only; it is never acquisition proof.
function Reliability.returnNotice()
    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return "" end
    for _, obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local value = string.lower(tostring(obj.Text or ""))
            if value:find("egg was returned", 1, true) then
                local visible, ancestor = true, obj :: Instance?
                while ancestor and ancestor ~= gui do
                    if ancestor:IsA("GuiObject") and not ancestor.Visible then visible = false; break end
                    if ancestor:IsA("ScreenGui") and not ancestor.Enabled then visible = false; break end
                    ancestor = ancestor.Parent
                end
                if visible then return obj.Text:sub(1, 180) end
            end
        end
    end
    return ""
end

function Reliability.eggReturnLog(message)
    local state = connections.EggReturn
    if not state then return end
    state.Lines = state.Lines or {}
    state.Started = tonumber(state.Started) or os.clock()
    if #state.Lines >= 90 then table.remove(state.Lines, 1) end
    table.insert(state.Lines, string.format("%.2fs %s", os.clock() - state.Started, message))
end

function Reliability.snapshotEggReturnAttempt(outcome)
    local state = connections.EggReturn
    if not state then return end
    state.Lines = state.Lines or {}
    state.LastCompletedLines = state.LastCompletedLines or {}
    if #state.Lines == 0 then return end
    state.LastCompletedExpected = state.Expected
    state.LastCompletedOutcome = tostring(outcome or state.Outcome or "Completed")
    state.LastCompletedAt = os.clock()
    table.clear(state.LastCompletedLines)
    for _, line in ipairs(state.Lines) do
        table.insert(state.LastCompletedLines, line)
    end
end

function Reliability.eggInventoryObjects()
    local objects = {}
    local function addTools(container)
        if not container then return end
        for _, obj in ipairs(container:GetChildren()) do
            if obj:IsA("Tool") then table.insert(objects, obj) end
        end
    end
    addTools(player:FindFirstChildOfClass("Backpack"))
    addTools(player.Character)
    local plot = getOwnPlot()
    local eggs = plot and plot:FindFirstChild("Eggs")
    if eggs then
        for _, obj in ipairs(eggs:GetChildren()) do table.insert(objects, obj) end
    end
    return objects
end

local function basketChildDiagnostic(child)
    if not child then return "basketChild=nil" end
    local now = workspace:GetServerTimeNow()
    local breakAt = tonumber(child:GetAttribute("BreakAt"))
    local remaining = breakAt and (breakAt - now) or nil
    return string.format(
        "%s{BreakAt=%s,remain=%s,Delivering=%s,Escaping=%s,VolcanoUntil=%s,parent=%s}",
        tostring(child.Name),
        breakAt and string.format("%.3f", breakAt) or "nil",
        remaining and string.format("%.3f", remaining) or "nil",
        tostring(child:GetAttribute("Delivering")),
        tostring(child:GetAttribute("Escaping")),
        tostring(child:GetAttribute("VolcanoUntil")),
        child.Parent and child.Parent:GetFullName() or "nil"
    )
end

function Reliability.clearEggReturnWatchers()
    local state = connections.EggReturn
    if not state then return end
    state.WatchConnections = state.WatchConnections or {}
    state.WatchedBasketChildren = state.WatchedBasketChildren or {}
    for _, connection in ipairs(state.WatchConnections or {}) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(state.WatchConnections)
    table.clear(state.WatchedBasketChildren)
end

function Reliability.watchBasketChild(child)
    local state = connections.EggReturn
    if not state then return end
    state.WatchConnections = state.WatchConnections or {}
    state.WatchedBasketChildren = state.WatchedBasketChildren or {}
    if not state.Active or not child or state.WatchedBasketChildren[child] then
        return
    end

    state.WatchedBasketChildren[child] = true

    local function logEvent(label)
        if state.Active then
            Reliability.eggReturnLog("BASKET EVENT " .. label .. " • " .. basketChildDiagnostic(child))
        end
    end

    logEvent("observed")

    for _, attributeName in ipairs({"BreakAt", "Delivering", "Escaping", "VolcanoUntil"}) do
        table.insert(state.WatchConnections,
            child:GetAttributeChangedSignal(attributeName):Connect(function()
                logEvent(attributeName .. " changed")
            end))
    end

    table.insert(state.WatchConnections,
        child.AncestryChanged:Connect(function(_, parent)
            if state.Active then
                logEvent("ancestry changed -> " .. tostring(parent and parent:GetFullName() or "nil"))
            end
        end))
end

function Reliability.startEggReturnBasketWatch()
    local state = connections.EggReturn
    if not state then return end
    state.WatchConnections = state.WatchConnections or {}
    state.WatchedBasketChildren = state.WatchedBasketChildren or {}
    Reliability.clearEggReturnWatchers()

    local basket = player:FindFirstChild("Basket")
    if not basket then
        Reliability.eggReturnLog("BASKET EVENT watch unavailable • Basket missing")
        return
    end

    for _, child in ipairs(basket:GetChildren()) do
        Reliability.watchBasketChild(child)
    end

    table.insert(state.WatchConnections,
        basket.ChildAdded:Connect(function(child)
            if state.Active then
                Reliability.watchBasketChild(child)
            end
        end))

    table.insert(state.WatchConnections,
        basket.ChildRemoved:Connect(function(child)
            if state.Active then
                Reliability.eggReturnLog("BASKET EVENT ChildRemoved • " .. basketChildDiagnostic(child))
            end
        end))
end

function Reliability.beginEggReturn(expectedName, existingCarry)
    local state = connections.EggReturn
    if not state then
        connections.EggReturn = {
            Active = false, Started = 0, Expected = "", Baseline = {},
            BaselineKeys = {}, Lines = {}, LastSignature = "", LastSample = 0,
            Outcome = "Not attempted", Character = nil, LastNotice = "",
            NoticeAtStart = "", UsedInstantTravel = false, WatchConnections = {},
            WatchedBasketChildren = {}, LastCompletedLines = {},
            LastCompletedExpected = "", LastCompletedOutcome = "Not attempted",
            LastCompletedAt = 0,
        }
        state = connections.EggReturn
    end
    state.Lines = state.Lines or {}
    state.Baseline = state.Baseline or {}
    state.BaselineKeys = state.BaselineKeys or {}
    state.WatchConnections = state.WatchConnections or {}
    state.WatchedBasketChildren = state.WatchedBasketChildren or {}
    state.Active = true
    state.Started = os.clock()
    state.Expected = tostring(expectedName or "")
    state.Character = player.Character
    state.Outcome = "Awaiting pickup / return"
    state.LastSignature = ""
    state.LastSample = 0
    state.LastNotice = ""
    state.NoticeAtStart = Reliability.returnNotice()
    state.ReturnNoticeSeen = false
    state.ReturnNoticeSeenAt = nil
    state.UsedInstantTravel = false
    table.clear(state.Lines)
    table.clear(state.Baseline)
    table.clear(state.BaselineKeys)
    for _, obj in ipairs(Reliability.eggInventoryObjects()) do
        -- On resuming an existing carry, a matching character tool can still
        -- be watched moving into Backpack. Existing Backpack eggs are excluded.
        if not (existingCarry and obj.Parent == player.Character
            and getWorldEggName(obj) == state.Expected) then
            state.Baseline[obj] = true
            local key = obj:GetAttribute("EggKey")
            if key ~= nil then state.BaselineKeys[tostring(key)] = true end
        end
    end
    Reliability.eggReturnLog("Target=" .. state.Expected .. "; TP=" .. tostring(Settings.InstantEggTravel)
        .. "; existing carry=" .. tostring(existingCarry == true))
    Reliability.startEggReturnBasketWatch()
end

function Reliability.newRetainedEgg()
    local state = connections.EggReturn
    local backpack = player:FindFirstChildOfClass("Backpack")
    local plot = getOwnPlot()
    local plotEggs = plot and plot:FindFirstChild("Eggs")
    for _, obj in ipairs(Reliability.eggInventoryObjects()) do
        local key = obj:GetAttribute("EggKey")
        local sameName = string.lower(getWorldEggName(obj)) == string.lower(state.Expected)
        if sameName and not state.Baseline[obj]
            and not (key ~= nil and state.BaselineKeys[tostring(key)]) then
            -- Character carry tools alone can linger after rejection. Require
            -- the new item in Backpack or a new egg under the player's plot.
            if obj.Parent == backpack or obj.Parent == plotEggs then return obj end
        end
    end
    return nil
end

local function basketEggStateSummary()
    local basket = player:FindFirstChild("Basket")
    if not basket then return "basket=missing" end
    local now = workspace:GetServerTimeNow()
    local parts = {}
    for _, child in ipairs(basket:GetChildren()) do
        local breakAt = tonumber(child:GetAttribute("BreakAt"))
        local remaining = breakAt and (breakAt - now) or nil
        table.insert(parts, string.format(
            "%s{BreakAt=%s,remain=%s,Delivering=%s,Escaping=%s,VolcanoUntil=%s}",
            tostring(child.Name),
            breakAt and string.format("%.3f", breakAt) or "nil",
            remaining and string.format("%.3f", remaining) or "nil",
            tostring(child:GetAttribute("Delivering")),
            tostring(child:GetAttribute("Escaping")),
            tostring(child:GetAttribute("VolcanoUntil"))
        ))
    end
    if #parts == 0 then return "basketEggs=[]" end
    return "basketEggs=[" .. table.concat(parts, "; ") .. "]"
end

function Reliability.sampleEggReturn()
    local state = connections.EggReturn
    local current, maximum = getBasketCounts()
    local _, hum, root = getCharacter()
    local retained = Reliability.newRetainedEgg()
    local signature = tostring(current) .. "/" .. tostring(maximum)
        .. "; held=" .. tostring(Reliability.hasPhysicalEggCarry(state.Expected))
        .. "; new inventory/plot=" .. tostring(retained and retained:GetFullName() or "none")
        .. "; HP=" .. tostring(hum and hum.Health or "?")
    if signature ~= state.LastSignature or os.clock() - state.LastSample >= 0.75 then
        state.LastSignature = signature
        state.LastSample = os.clock()
        Reliability.eggReturnLog(signature .. "; position=" .. tostring(root and root.Position or "missing")
            .. "; TP=" .. connections.InstantTravel.LastOutcome
            .. "; " .. basketEggStateSummary())
    end
end


function Reliability.recoverRejectedTeleportPickup(reason)
    local state = connections.EggReturn
    state.Outcome = reason
    Reliability.eggReturnLog(reason)
    state.Active = false
    Reliability.clearEggReturnWatchers()
    Reliability.eggReturnLog("TP rejection confirmed after basket clear; keeping TP as the default method for the next test cycle")
    Reliability.snapshotEggReturnAttempt(reason)

    -- BUILD127: do not switch the farm back to tween/normal movement.
    connections.InstantTravel.SessionRejected = false
    connections.InstantTravel.RetryAfter = 0
    connections.InstantTravel.LastOutcome = "TP pickup rejected after basket-clear confirmation; TP remains default"

    Reliability.clearCarriedEgg()
    Reliability.clearCarryBreakTimerState()
    lastClaimedEgg = nil
    farmStats.LastTarget = nil

    setStatus("TP pickup rejection confirmed • retrying with TP default")
    task.wait(0.20)
    return false
end

function Reliability.pauseEggReturn(reason)
    local state = connections.EggReturn
    state.Outcome = reason
    Reliability.eggReturnLog(reason)
    state.Active = false
    Reliability.clearEggReturnWatchers()
    Reliability.snapshotEggReturnAttempt(reason)
    Settings.AutoFarmEggs = false
    Settings.AutoRebirth = false
    -- BUILD127: keep TP as the fixed/default method even if the farm pauses.
    Settings.InstantEggTravel = true
    stopCurrentMovement()
    Reliability.clearCarriedEgg()
    Reliability.clearCarryBreakTimerState()
    lastClaimedEgg = nil
    if connections.RefreshEggControls then connections.RefreshEggControls() end
    setStatus("Farm paused • " .. reason)
    return false
end

-- ============================================================
-- LIVE CARRIED-EGG BREAK TIMER
-- ============================================================
-- BigFroot-style timing:
--   return to ranch edge
--   watch the ACTUAL on-screen "Egg Will Break" countdown
--   cross so arrival inside happens at ArriveWithSeconds
--
-- We cache the timer label once found, but re-discover it if the GUI changes.

function Reliability.parseSecondsLabel(textValue)
    local raw = tostring(textValue or "")

    -- Carried timer shown by the game, e.g. "13.6s", "5s", "0.4 s".
    local number =
        raw:match("^%s*(%d+%.?%d*)%s*[sS]%s*$")

    if number then
        local value = tonumber(number)

        if value and value >= 0 and value <= 300 then
            return value
        end
    end

    return nil
end

function Reliability.guiObjectIsVisible(obj)
    if not obj or not obj.Parent then
        return false
    end

    local ok, visible = pcall(function()
        return obj.Visible
    end)

    return ok and visible == true
end

function Reliability.getGuiCenter(obj)
    if not obj then
        return nil
    end

    local ok, pos, size = pcall(function()
        return obj.AbsolutePosition, obj.AbsoluteSize
    end)

    if not ok or not pos or not size then
        return nil
    end

    return Vector2.new(
        pos.X + (size.X * 0.5),
        pos.Y + (size.Y * 0.5)
    )
end

function Reliability.getLiveEggBreakTime()
    local gui = player:FindFirstChild("PlayerGui")

    if not gui then
        Reliability.LiveEggBreakTimerLabel = nil
        return nil
    end

    -- Fast path: reuse the exact label found previously.
    local cached = Reliability.LiveEggBreakTimerLabel

    if cached
        and cached.Parent
        and Reliability.guiObjectIsVisible(cached) then

        local cachedSeconds =
            Reliability.parseSecondsLabel(cached.Text)

        if cachedSeconds ~= nil then
            return cachedSeconds
        end
    end

    Reliability.LiveEggBreakTimerLabel = nil

    local now = os.clock()
    local lastDiscovery =
        tonumber(Reliability.LiveEggBreakDiscoveryAt) or 0

    if now - lastDiscovery < 0.25 then
        return nil
    end

    Reliability.LiveEggBreakDiscoveryAt = now

    local titleCenters = {}
    local timerCandidates = {}

    for _, obj in ipairs(gui:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton"))
            and Reliability.guiObjectIsVisible(obj) then

            local raw = tostring(obj.Text or "")
            local lower = string.lower(raw)

            if lower:find("egg will break", 1, true) then
                local center = Reliability.getGuiCenter(obj)

                if center then
                    titleCenters[#titleCenters + 1] = center
                end
            end

            local seconds =
                Reliability.parseSecondsLabel(raw)

            if seconds ~= nil then
                local center = Reliability.getGuiCenter(obj)

                if center then
                    timerCandidates[#timerCandidates + 1] = {
                        object = obj,
                        seconds = seconds,
                        center = center,
                    }
                end
            end
        end
    end

    if #timerCandidates == 0 then
        return nil
    end

    local camera = workspace.CurrentCamera
    local viewport =
        camera and camera.ViewportSize
        or Vector2.new(1920, 1080)

    local bestCandidate = nil
    local bestScore = math.huge

    for _, candidate in ipairs(timerCandidates) do
        local score = math.huge

        -- Strongest signal: timer label nearest the visible
        -- "Egg Will Break" title.
        for _, titleCenter in ipairs(titleCenters) do
            local distance =
                (candidate.center - titleCenter).Magnitude

            if distance < score then
                score = distance
            end
        end

        -- Fallback if title and timer are in separate GUI trees:
        -- the carried break timer is visibly near the top-center of screen.
        if #titleCenters == 0 then
            local normalizedX =
                candidate.center.X / math.max(viewport.X, 1)

            local normalizedY =
                candidate.center.Y / math.max(viewport.Y, 1)

            if normalizedY <= 0.24
                and normalizedX >= 0.20
                and normalizedX <= 0.80 then

                local centerDistance =
                    math.abs(normalizedX - 0.5)

                score =
                    (normalizedY * 350)
                    + (centerDistance * 250)
            end
        end

        if score < bestScore then
            bestScore = score
            bestCandidate = candidate
        end
    end

    -- Avoid accidentally locking onto a random seconds label far away
    -- from the carried-egg timer panel.
    if bestCandidate
        and (
            #titleCenters == 0
            or bestScore <= 550
        ) then

        Reliability.LiveEggBreakTimerLabel =
            bestCandidate.object

        return bestCandidate.seconds
    end

    return nil
end

function Reliability.getEstimatedCarryBreakTime()
    local initial =
        tonumber(Reliability.CarryBreakTimerSample)

    local sampledAt =
        tonumber(Reliability.CarryBreakTimerSampleClock)

    if initial == nil or sampledAt == nil then
        return nil
    end

    return math.max(
        0,
        initial - (os.clock() - sampledAt)
    )
end

function Reliability.getBestCarryBreakTime()
    local live =
        Reliability.getLiveEggBreakTime()

    if live ~= nil then
        Reliability.LastLiveCarryBreakTime = live
        Reliability.LastLiveCarryBreakClock = os.clock()
        return live, "live-ui"
    end

    -- If the timer UI flickers for a frame, extrapolate briefly from
    -- the last real live value instead of instantly losing timing.
    local lastLive =
        tonumber(Reliability.LastLiveCarryBreakTime)

    local lastLiveClock =
        tonumber(Reliability.LastLiveCarryBreakClock)

    if lastLive ~= nil
        and lastLiveClock ~= nil
        and os.clock() - lastLiveClock <= 0.75 then

        return math.max(
            0,
            lastLive - (os.clock() - lastLiveClock)
        ), "live-ui-extrapolated"
    end

    local estimated =
        Reliability.getEstimatedCarryBreakTime()

    if estimated ~= nil then
        return estimated, "pickup-snapshot"
    end

    return nil, "unavailable"
end

function Reliability.getRanchCrossingLeadSeconds(
    insidePos,
    stopDistance,
    returnSpeed
)
    local _, _, root = getCharacter()

    if not root or typeof(insidePos) ~= "Vector3" then
        return 0.08
    end

    local delta = insidePos - root.Position
    local flatDistance =
        Vector3.new(delta.X, 0, delta.Z).Magnitude

    local remainingDistance =
        math.max(
            flatDistance - (tonumber(stopDistance) or 7),
            0
        )

    local speed =
        math.clamp(
            tonumber(returnSpeed) or 360,
            10,
            1000
        )

    -- tweenToPosition itself enforces a minimum duration of 0.05s.
    return math.max(
        remainingDistance / speed,
        0.05
    ) + 0.03
end

function Reliability.waitForRanchEntryWindow(
    shouldContinue,
    insidePos,
    stopDistance,
    returnSpeed,
    basketBefore
)
    local target =
        math.clamp(
            tonumber(Settings.ArriveWithSeconds) or 5,
            0,
            15
        )

    local unavailableSince = nil

    while alive do
        if shouldContinue and not shouldContinue() then
            return false, "cancelled"
        end

        -- The egg may already be returned simply by reaching the ranch edge.
        -- If the basket dropped from the post-pickup value, return is DONE:
        -- do not keep waiting for Arrive With and do not cross again.
        local currentBasket =
            select(1, getBasketCounts())

        if basketBefore ~= nil
            and currentBasket ~= nil
            and currentBasket < basketBefore then

            return true, "already-returned"
        end

        local remaining, _source =
            Reliability.getBestCarryBreakTime()

        if remaining == nil then
            if unavailableSince == nil then
                unavailableSince = os.clock()
            end

            -- Failsafe: timing must never break the known-good Auto Farm.
            -- If we cannot read a timer for one second, preserve the original
            -- working behavior and cross immediately.
            if os.clock() - unavailableSince >= 1.0 then
                setStatus(
                    "Auto Farm • break timer unavailable • entering ranch"
                )
                return true, "timer-unavailable"
            end
        else
            unavailableSince = nil

            local crossingLead =
                Reliability.getRanchCrossingLeadSeconds(
                    insidePos,
                    stopDistance,
                    returnSpeed
                )

            -- Start the short edge->inside movement early enough that the
            -- character ARRIVES with approximately the configured time left.
            local startCrossAt =
                target + crossingLead

            if remaining <= startCrossAt then
                return true
            end

            local statusBucket =
                math.floor((remaining * 10) + 0.5)

            local now = os.clock()

            if statusBucket ~= Reliability.LiveTimerStatusBucket
                or now - (Reliability.LiveTimerStatusAt or 0) >= 0.25 then

                Reliability.LiveTimerStatusBucket = statusBucket
                Reliability.LiveTimerStatusAt = now

                setStatus(
                    "Auto Farm • ranch edge • "
                    .. string.format("%.1f", remaining)
                    .. "s left • arrive at "
                    .. tostring(
                        math.floor(target + 0.5)
                    )
                    .. "s"
                )
            end
        end

        -- 20 Hz is more than enough for a seconds-based arrival threshold and
        -- avoids doing farm/UI work every rendered frame.
        task.wait(0.05)
    end

    return false, "stopped"
end

function Reliability.clearCarryBreakTimerState()
    Reliability.CarryBreakTimerSample = nil
    Reliability.CarryBreakTimerSampleClock = nil
    Reliability.LiveEggBreakTimerLabel = nil
    Reliability.LastLiveCarryBreakTime = nil
    Reliability.LastLiveCarryBreakClock = nil
    Reliability.LiveEggBreakDiscoveryAt = nil
    Reliability.LiveTimerStatusAt = nil
    Reliability.LiveTimerStatusBucket = nil
end


function Reliability.finishNormalEggReturn(expectedEggName, current, maximum, reason)
    local state = connections.EggReturn
    state.Outcome = reason
    Reliability.eggReturnLog("Observed retention: " .. reason)
    state.Active = false
    Reliability.clearEggReturnWatchers()
    Reliability.snapshotEggReturnAttempt(reason)
    Reliability.clearCarriedEgg()
    Reliability.clearCarryBreakTimerState()
    lastClaimedEgg = nil
    farmStats.LastTarget = nil
    setStatus("Auto Farm • " .. tostring(expectedEggName or "egg")
        .. " detected in inventory/plot • basket " .. tostring(current or "?") .. "/" .. tostring(maximum or "?"))
    return true
end

function Reliability.returnBasketEggHome(shouldContinue, expectedEggName, carriedCount, forceMoveHome)
    local state = connections.EggReturn
    if not state.Active then Reliability.beginEggReturn(expectedEggName, true) end
    local before = tonumber(carriedCount) or select(1, getBasketCounts())
    local function continuing()
        return alive and (not shouldContinue or shouldContinue())
    end
    if not continuing() then return false end
    local insidePos = Reliability.getPlotCenterInside()
    if not insidePos then setStatus("Auto Farm • your plot is not loaded yet"); return false end
    local returnSpeed = math.clamp(tonumber(Settings.ReturnTweenSpeed) or 360, 10, 1000)
    local function moveHome(position)
        Reliability.sampleEggReturn()
        local ok, moved = pcall(Reliability.tweenNoclipSegment, position, shouldContinue, returnSpeed)
        Reliability.setUndergroundAntiGravity(false)
        Reliability.setUndergroundNoclip(false)
        Reliability.sampleEggReturn()
        if not ok then
            stopCurrentMovement()
            Reliability.eggReturnLog("Movement error: " .. tostring(moved):sub(1, 160))
        end
        return ok and moved
    end
    local current = select(1, getBasketCounts())
    local visibleCarry =
        Reliability.hasPhysicalEggCarry(expectedEggName)
        or Reliability.getLiveEggBreakTime() ~= nil

    if forceMoveHome or current == nil or current > 0 or visibleCarry then
        setStatus("Auto Farm • returning " .. tostring(expectedEggName or "egg") .. " into your plot")
        Reliability.eggReturnLog(
            "Home TP permitted • basket=" .. tostring(current)
            .. " • physicalCarry=" .. tostring(Reliability.hasPhysicalEggCarry(expectedEggName))
            .. " • breakTimer=" .. tostring(Reliability.getLiveEggBreakTime())
        )
        moveHome(insidePos)
    end
    if not continuing() then return false end
    local deadline = os.clock() + 8
    local clearedAt, retainedAt, candidate, nextNotice = nil, nil, nil, 0
    local retried = false
    while continuing() and os.clock() < deadline do
        local _, hum = getCharacter()
        if player.Character ~= state.Character or not hum or hum.Health <= 0 then
            return Reliability.pauseEggReturn("Character changed or died during return")
        end
        local basket, maximum, basketState = Reliability.getBasketState()
        Reliability.sampleEggReturn()
        if os.clock() >= nextNotice then
            nextNotice = os.clock() + 0.25
            local notice = Reliability.returnNotice()
            if notice ~= "" and notice ~= state.NoticeAtStart and notice ~= state.LastNotice then
                state.LastNotice = notice
                Reliability.eggReturnLog("Visible notice (not success proof): " .. notice)
                local lowerNotice = string.lower(notice)
                if state.UsedInstantTravel and lowerNotice:find("egg was returned", 1, true) then
                    -- BUILD119: a notice can linger from an earlier attempt.
                    -- Record it, but do NOT call the TP rejected until the
                    -- basket itself has actually cleared and no retained egg appears.
                    state.ReturnNoticeSeen = true
                    state.ReturnNoticeSeenAt = os.clock()
                    Reliability.eggReturnLog("Return notice observed; waiting for basket-clear confirmation")
                end
            elseif notice == "" then
                state.NoticeAtStart = ""
            end
        end
        local released = basketState == "empty"
            or (basket ~= nil and before ~= nil and basket < before)
        if basketState == "unknown" then
            released = not Reliability.hasPhysicalEggCarry(expectedEggName)
        end
        if released then
            clearedAt = clearedAt or os.clock()
            local item = Reliability.newRetainedEgg()
            if item and item == candidate then
                if retainedAt and os.clock() - retainedAt >= 0.75 then
                    return Reliability.finishNormalEggReturn(expectedEggName, basket, maximum,
                        "New matching item persisted: " .. item:GetFullName())
                end
            else
                candidate, retainedAt = item, item and os.clock() or nil
            end
            local clearAge = os.clock() - clearedAt

            -- BUILD119: confirm a TP rejection from authoritative local state:
            -- basket is empty/reduced AND no new matching inventory/plot egg exists.
            -- If the game's "Your Egg Was Returned" notice was also seen, one
            -- second is enough confirmation. Otherwise keep the longer grace
            -- period to allow a legitimate retained egg to replicate locally.
            if state.UsedInstantTravel
                and item == nil
                and state.ReturnNoticeSeen
                and clearAge >= 1.0 then

                return Reliability.recoverRejectedTeleportPickup(
                    "Basket cleared + return notice after TP pickup; retained egg not detected"
                )
            end

            if clearAge >= 4 then
                if state.UsedInstantTravel then
                    return Reliability.recoverRejectedTeleportPickup(
                        "Basket cleared after TP pickup; retained egg not detected"
                    )
                end
                return Reliability.pauseEggReturn("Basket cleared; retained egg not detected")
            end
            setStatus("Auto Farm • basket cleared; checking retained egg")
        else
            clearedAt, retainedAt, candidate = nil, nil, nil
            setStatus("Auto Farm • basket " .. tostring(basket or "?") .. "/" .. tostring(maximum or "?")
                .. " • waiting for plot entry")
            if not retried and os.clock() >= deadline - 3 then
                retried = true
                local nestPos = getOwnNestReturnPosition()
                if not nestPos or not Reliability.isInsideOwnPlot(nestPos, 1) then nestPos = insidePos end
                moveHome(Vector3.new(nestPos.X, insidePos.Y, nestPos.Z))
                deadline = os.clock() + 4
            end
        end
        task.wait(0.10)
    end
    if not continuing() then return false end
    return Reliability.pauseEggReturn("Return not confirmed; inspect current basket")
end

-- ============================================================
-- ALL EGGS -> MAGMA ROUTE (NORMAL GAME UI INTERACTION)
-- ============================================================
-- The live client exposes a normal DropEggVolcanoButton only while the player
-- is over a tagged volcano pool and the carried egg is eligible. Build138
-- sends every newly collected farm egg through this normal game interaction.
function Reliability.autoMagmaVolcanicEgg(expectedEggName, shouldContinue, routeAttempt)
    routeAttempt = tonumber(routeAttempt) or 1

    local function continuing()
        return alive and (not shouldContinue or shouldContinue())
    end

    if not continuing() then
        return false
    end

    local basket = player:FindFirstChild("Basket")
    if not basket or #basket:GetChildren() == 0 then
        Reliability.eggReturnLog("Volcano route skipped • basket empty")
        return false
    end

    local volcanoData
    pcall(function()
        volcanoData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("Volcano"))
    end)

    local poolPart, dropPosition
    if type(volcanoData) == "table" and type(volcanoData.Tag) == "string" then
        local ok, tagged = pcall(function()
            return game:GetService("CollectionService"):GetTagged(volcanoData.Tag)
        end)

        if ok and type(tagged) == "table" then
            local bestY
            for _, part in ipairs(tagged) do
                if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
                    local candidate = Vector3.new(
                        part.Position.X,
                        part.Position.Y + math.max(part.Size.Y * 0.5 + 3, 4),
                        part.Position.Z
                    )

                    local accepted = true
                    if type(volcanoData.IsOver) == "function" then
                        local checked, result = pcall(volcanoData.IsOver, part, candidate)
                        accepted = checked and result == true
                    end

                    if accepted and (bestY == nil or candidate.Y > bestY) then
                        poolPart = part
                        dropPosition = candidate
                        bestY = candidate.Y
                    end
                end
            end
        end
    end

    if not dropPosition then
        local volcano = workspace:FindFirstChild("Volcano")
        if volcano then
            local best, bestY
            for _, obj in ipairs(volcano:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local n = string.lower(obj.Name)
                    if n:find("lava", 1, true)
                        or n:find("magma", 1, true)
                        or n:find("pool", 1, true) then
                        if not bestY or obj.Position.Y > bestY then
                            best, bestY = obj, obj.Position.Y
                        end
                    end
                end
            end
            if best then
                poolPart = best
                dropPosition = best.Position + Vector3.new(0, math.max(best.Size.Y * 0.5 + 3, 4), 0)
            end
        end
    end

    if not dropPosition then
        Reliability.eggReturnLog("Volcano route failed • no pool position found")
        setStatus("Auto Farm • volcano pool not loaded yet")
        return false
    end

    setStatus("Auto Farm • " .. tostring(expectedEggName or "Egg") .. " • TP to volcano")
    Reliability.eggReturnLog(
        "Simple volcano route starting • pool=" .. tostring(poolPart and poolPart:GetFullName() or "unknown")
        .. " • pos=" .. tostring(dropPosition)
    )

    if not tryInstantEggTravel(dropPosition, shouldContinue) then
        Reliability.eggReturnLog("Volcano route failed • TP to pool did not hold")
        return false
    end

    -- BUILD141: keep this deliberately simple. The 15-second clock starts as
    -- soon as we arrive at the volcano. Drop through the game's own button,
    -- stay over the pool for the full 15 seconds, then force the TP-home
    -- path run unconditionally.
    local volcanoEnteredClock = os.clock()

    local dropButton
    local buttonDeadline = os.clock() + 2.0
    repeat
        local mainGui = playerGui:FindFirstChild("Main")
        local actions = mainGui and mainGui:FindFirstChild("ActionsHolder")
        local candidate = actions and actions:FindFirstChild("DropEggVolcanoButton")
        if candidate and candidate:IsA("GuiButton") then
            dropButton = candidate
            if candidate.Visible then
                break
            end
        end
        task.wait(0.03)
    until not continuing() or os.clock() >= buttonDeadline

    if not continuing() then
        return false
    end

    if not dropButton or not dropButton.Visible then
        Reliability.eggReturnLog("Volcano route failed • DROP IN VOLCANO button not visible")
        setStatus("Auto Farm • volcano drop button not ready")
        return false
    end

    local dropStarted = false
    local beforeChildren = basket:GetChildren()
    local beforeCount = #beforeChildren
    local carriedBefore = beforeChildren[1]

    local function confirmedVolcanoDrop()
        -- A hidden button is NOT enough proof.  The previous build could
        -- mistake a UI refresh for a successful drop and then stand in the
        -- volcano until the still-carried egg was returned.
        if #basket:GetChildren() < beforeCount then
            return true, "basket count decreased"
        end

        if carriedBefore then
            if carriedBefore.Parent ~= basket then
                return true, "carried basket object left basket"
            end

            local volcanoUntil =
                tonumber(
                    carriedBefore:GetAttribute(
                        "VolcanoUntil"
                    )
                )

            if volcanoUntil
                and volcanoUntil
                    > workspace:GetServerTimeNow() then

                return true, "VolcanoUntil replicated"
            end

            if carriedBefore:GetAttribute(
                "VolcanoDipped"
            ) == true then

                return true, "VolcanoDipped replicated"
            end
        end

        return false, nil
    end

    local function recenterOverVolcano()
        local _, humanoid, root =
            getCharacter()

        if not root
            or not humanoid
            or humanoid.Health <= 0 then

            return false
        end

        setInstantTravelNoclip(true)

        pcall(function()
            root.AssemblyLinearVelocity =
                Vector3.zero

            root.AssemblyAngularVelocity =
                Vector3.zero

            root.CFrame =
                CFrame.new(dropPosition)
        end)

        task.wait(0.08)
        setInstantTravelNoclip(false)

        return
            (root.Position - dropPosition).Magnitude
            <= 18
    end

    for attempt = 1, 4 do
        if not continuing() then
            return false
        end

        recenterOverVolcano()
        task.wait(0.12)

        -- Refresh the live button reference each try because the game's
        -- ActionsHolder can recreate / refresh it.
        do
            local mainGui =
                playerGui:FindFirstChild(
                    "Main"
                )

            local actions =
                mainGui
                and mainGui:FindFirstChild(
                    "ActionsHolder"
                )

            local liveButton =
                actions
                and actions:FindFirstChild(
                    "DropEggVolcanoButton"
                )

            if liveButton
                and liveButton:IsA(
                    "GuiButton"
                ) then

                dropButton = liveButton
            end
        end

        setStatus(
            "Auto Farm • dropping egg in volcano • attempt "
            .. tostring(attempt)
        )

        local activated = false

        if dropButton
            and dropButton.Parent
            and dropButton.Visible then

            activated =
                activateButton(
                    dropButton
                )
        end

        if activated then
            Reliability.eggReturnLog(
                "Volcano drop UI activated • attempt="
                .. tostring(attempt)
            )
        end

        local confirmDeadline =
            os.clock() + 1.25

        repeat
            local confirmed, reason =
                confirmedVolcanoDrop()

            if confirmed then
                dropStarted = true

                Reliability.eggReturnLog(
                    "Volcano drop CONFIRMED • "
                    .. tostring(reason)
                    .. " • attempt="
                    .. tostring(attempt)
                )

                break
            end

            task.wait(0.03)
        until
            not continuing()
            or os.clock()
                >= confirmDeadline

        if dropStarted then
            break
        end

        -- Normal game keybind fallback.  This invokes the same DropCarriedEgg
        -- action the game binds to G while the volcano button is eligible.
        local okVim, vim =
            pcall(function()
                return game:GetService(
                    "VirtualInputManager"
                )
            end)

        if okVim and vim then
            pcall(function()
                vim:SendKeyEvent(
                    true,
                    Enum.KeyCode.G,
                    false,
                    game
                )

                task.wait(0.06)

                vim:SendKeyEvent(
                    false,
                    Enum.KeyCode.G,
                    false,
                    game
                )
            end)
        end

        confirmDeadline =
            os.clock() + 1.25

        repeat
            local confirmed, reason =
                confirmedVolcanoDrop()

            if confirmed then
                dropStarted = true

                Reliability.eggReturnLog(
                    "Volcano drop CONFIRMED after G • "
                    .. tostring(reason)
                    .. " • attempt="
                    .. tostring(attempt)
                )

                break
            end

            task.wait(0.03)
        until
            not continuing()
            or os.clock()
                >= confirmDeadline

        if dropStarted then
            break
        end

        -- Executor UI-signal fallback, still using the game's visible button.
        if dropButton
            and dropButton.Parent
            and typeof(firesignal)
                == "function" then

            pcall(function()
                firesignal(
                    dropButton.Activated
                )
            end)

            confirmDeadline =
                os.clock() + 1.0

            repeat
                local confirmed, reason =
                    confirmedVolcanoDrop()

                if confirmed then
                    dropStarted = true

                    Reliability.eggReturnLog(
                        "Volcano drop CONFIRMED after Activated signal • "
                        .. tostring(reason)
                        .. " • attempt="
                        .. tostring(attempt)
                    )

                    break
                end

                task.wait(0.03)
            until
                not continuing()
                or os.clock()
                    >= confirmDeadline
        end

        if dropStarted then
            break
        end

        Reliability.eggReturnLog(
            "Volcano drop attempt "
            .. tostring(attempt)
            .. " produced no server-visible carried-egg change"
        )
    end

    if not dropStarted then
        Reliability.eggReturnLog(
            "Volcano route failed • DROP IN VOLCANO never produced a real egg-state change"
        )

        setStatus(
            "Auto Farm • volcano drop failed • retrying next cycle"
        )

        return false
    end

    Reliability.eggReturnLog("Volcano drop started • fixed 15s hold begins")

    local returnAt = volcanoEnteredClock + 15.0
    while continuing() and os.clock() < returnAt do
        local _, _, root = getCharacter()
        if root and (root.Position - dropPosition).Magnitude > 55 then
            root.CFrame = CFrame.new(dropPosition)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end

        local remaining = math.max(0, returnAt - os.clock())
        setStatus("Auto Farm • volcano • TP home in " .. string.format("%.1f", remaining) .. "s")
        task.wait(0.05)
    end

    if not continuing() then
        return false
    end

    Reliability.eggReturnLog("Fixed 15s volcano hold complete • forcing direct TP home now")
    setStatus("Auto Farm • 15s complete • TP home")

    -- BUILD141: IMPORTANT: outbound egg movement above is unchanged from the
    -- known-good Build135 path.  Home stabilization is isolated here so it can
    -- never prevent target selection / claimWorldEgg from running.
    local homePosition = Reliability.getPlotCenterInside()
        or getOwnNestReturnPosition()

    if typeof(homePosition) ~= "Vector3" then
        Reliability.eggReturnLog("15s complete but plot return point is unavailable")
        setStatus("Auto Farm • plot not loaded for TP home")
        return false
    end

    Reliability.eggReturnLog(
        "15s complete • isolated stable TP-home starting • destination="
        .. tostring(homePosition)
    )

    local homeStarted = os.clock()
    local stableSince = nil
    local homeMoved = false

    -- Keep collision disabled only for this bounded return window.  Re-apply
    -- the same ranch destination because a single CFrame snap may be corrected
    -- during the volcano hand-back sequence.
    setInstantTravelNoclip(true)

    while alive and os.clock() - homeStarted < 3.0 do
        local _, hum, root = getCharacter()
        if not root or not hum or hum.Health <= 0 then
            break
        end

        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = CFrame.lookAt(
                homePosition,
                homePosition + root.CFrame.LookVector
            )
        end)

        task.wait(0.03)

        local inside = Reliability.isInsideOwnPlot(root.Position, 0.25)
        local distance = (root.Position - homePosition).Magnitude

        if inside and distance <= 20 then
            stableSince = stableSince or os.clock()
            if os.clock() - stableSince >= 0.45 then
                homeMoved = true
                break
            end
        else
            stableSince = nil
        end

        setStatus(
            "Auto Farm • forcing TP home • "
            .. string.format("%.1fs", math.max(0, 3.0 - (os.clock() - homeStarted)))
        )
    end

    setInstantTravelNoclip(false)

    local _, _, finalRoot = getCharacter()
    if finalRoot then
        local finalInside = Reliability.isInsideOwnPlot(finalRoot.Position, 0.25)
        local finalDistance = (finalRoot.Position - homePosition).Magnitude
        homeMoved = homeMoved or (finalInside and finalDistance <= 20)

        Reliability.eggReturnLog(
            "Isolated stable TP-home finished • success=" .. tostring(homeMoved)
            .. " • finalPosition=" .. tostring(finalRoot.Position)
            .. " • distance=" .. string.format("%.2f", finalDistance)
            .. " • insidePlot=" .. tostring(finalInside)
        )
    end

    if homeMoved then
        setStatus("Auto Farm • returned to plot after volcano")
    else
        setStatus("Auto Farm • TP home corrected; next cycle will retry")
    end

    return homeMoved
end

-- ============================================================
-- EXACT EGG PLACEMENT CALLBACK
-- ============================================================
-- Placement scan confirmed that each nest Place prompt has a client callback
-- from PlayerScripts.Game.EggHatching.EggPlacing. That callback owns:
--   • ReplicatedStorage.Remotes.Game.EggPlaced
--   • the nest model
--   • NestId
--
-- The Place prompts can remain Enabled=false while carrying an egg, so the
-- old fireproximityprompt/InputHold path can never reproduce manual placement.
-- For Auto Rebirth we invoke the game's own EggPlacing callback instead of
-- guessing EggPlaced remote arguments.

















-- Legacy placement helper retained for compatibility; farm worker does not call it.




local function hatchReadyEggs()
    local plot = getOwnPlot()
    local eggs = plot and plot:FindFirstChild("Eggs")
    if not eggs then
        return
    end

    for _, egg in ipairs(eggs:GetChildren()) do
        if not alive or not Settings.AutoHatchEggs then
            return
        end

        local handle = egg:FindFirstChild("Handle")
        local ui = handle and handle:FindFirstChild("HatchingUI")
        local timerLabel = ui and ui:FindFirstChild("Timer")
        local hatch = handle and handle:FindFirstChild("Hatch")

        if hatch and hatch:IsA("ProximityPrompt") then
            local ready = false

            if timerLabel and timerLabel:IsA("TextLabel") then
                local lower = string.lower(timerLabel.Text or "")
                local seconds = parseTimer(timerLabel.Text)
                ready = seconds <= 0 or lower:find("ready", 1, true) ~= nil
            else
                ready = true
            end

            if ready then
                local hatchEggName = tostring(
                    egg:GetAttribute("EggName")
                    or egg:GetAttribute("EggKey")
                    or egg.Name
                )

                rebirthRuntime.PendingHatchEggName = hatchEggName
                rebirthRuntime.PendingHatchUntil = os.clock() + 4

                if triggerPrompt(hatch) then
                    farmStats.Hatched += 1
                end
                task.wait(0.3)
            end
        end
    end
end

-- ============================================================
-- SHOP
-- ============================================================

local function getShopItem(category, itemName)
    local main = playerGui:FindFirstChild("Main")
    local shop = main and main:FindFirstChild("Shop")
    local holders = shop and shop:FindFirstChild("Holders")
    local holder = holders and holders:FindFirstChild(category)
    return holder and holder:FindFirstChild(itemName)
end

local function buyShopItem(category, itemName)
    local item = getShopItem(category, itemName)
    if not item then
        return false
    end

    local stockLabel = item:FindFirstChild("Stock", true)
    if stockLabel and stockLabel:IsA("TextLabel") then
        if string.find(string.lower(stockLabel.Text), "x0", 1, true) then
            return false
        end
    end

    local cash = item:FindFirstChild("CashPayment", true)
    local dollar = cash and cash:FindFirstChild("Dollar", true)

    if dollar then
        return activateButton(dollar)
    end

    return false
end

local function useRadar()
    if not equipToolByName(Settings.Radar) then
        return false
    end

    local main = playerGui:FindFirstChild("Main")
    local actions = main and main:FindFirstChild("ActionsHolder")
    local button = actions and actions:FindFirstChild("UseRadar")

    return activateButton(button)
end

-- ============================================================
-- FEEDING / PET ACTIONS
-- ============================================================

local function feedPet(pet)
    if not pet or not pet.Parent then
        return false
    end

    if not equipToolByName(Settings.Food) then
        return false
    end

    local rootPart = pet:FindFirstChild("RootPart")
    local prompt = rootPart and rootPart:FindFirstChild("Feed")

    if prompt and prompt:IsA("ProximityPrompt") then
        return triggerPrompt(prompt)
    end

    return false
end

local function shouldFeedPet(pet)
    if Settings.AutoFeedBestPet then
        local best = getBestPet()
        if best == pet then
            return true
        end
    end

    if Settings.AutoFeedAboveIncome
        and getPetIncome(pet) >= (tonumber(Settings.FeedMinIncome) or 0) then
        return true
    end

    if Settings.AutoFeedAboveAge
        and getPetAge(pet) >= (tonumber(Settings.FeedMinAge) or 0) then
        return true
    end

    if Settings.AutoFeedByRarity then
        local oneIn = getBasePetOneIn(pet:GetAttribute("PetName") or pet.Name)
        if oneIn >= (tonumber(Settings.FeedMinOneIn) or 0) then
            return true
        end
    end

    return false
end

local function feedPetsPass()
    if busyFeed then
        return
    end

    busyFeed = true

    for _, pet in ipairs(getOwnPets()) do
        if not alive then
            break
        end

        if shouldFeedPet(pet) then
            feedPet(pet)
            task.wait(0.3)
        end
    end

    busyFeed = false
end

local function placeBestPets()
    local main = playerGui:FindFirstChild("Main")
    local tracker = main and main:FindFirstChild("PetsTracker")
    local placeBest = tracker and tracker:FindFirstChild("PlaceBest")

    return activateButton(placeBest)
end

local function rideBestPet()
    local pet = getBestPet()
    if not pet then
        return false
    end

    local rootPart = pet:FindFirstChild("RootPart")
    local prompt = rootPart and rootPart:FindFirstChild("RidePrompt")

    if prompt and prompt:IsA("ProximityPrompt") then
        return triggerPrompt(prompt)
    end

    return false
end

-- ============================================================
-- PROGRESSION
-- ============================================================

local function unlockNextNest()
    local plot = getOwnPlot()
    local nests = plot and plot:FindFirstChild("Nests")
    if not nests then
        return false
    end

    local prompts = {}

    for _, d in ipairs(nests:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Name == "UnlockNest" and d.Enabled then
            table.insert(prompts, d)
        end
    end

    table.sort(prompts, function(a, b)
        local ca = parseNumber(a.ObjectText)
        local cb = parseNumber(b.ObjectText)
        return ca < cb
    end)

    if prompts[1] then
        return triggerPrompt(prompts[1])
    end

    return false
end

function Reliability.guiTreeVisible(obj)
    if not obj or not obj.Parent then
        return false
    end

    local node = obj

    for _ = 1, 8 do
        if not node then
            break
        end

        if node:IsA("GuiObject") then
            local ok, visible = pcall(function()
                return node.Visible
            end)

            if ok and visible == false then
                return false
            end
        elseif node:IsA("ScreenGui") then
            local ok, enabled = pcall(function()
                return node.Enabled
            end)

            if ok and enabled == false then
                return false
            end
        end

        node = node.Parent
    end

    return true
end

function Reliability.guiTextBlob(root)
    if not root then
        return ""
    end

    local parts = {
        tostring(root.Name or ""),
    }

    if root:IsA("TextLabel") or root:IsA("TextButton") then
        parts[#parts + 1] = tostring(root.Text or "")
    end

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            parts[#parts + 1] = tostring(obj.Text or "")
        end
    end

    return string.lower(table.concat(parts, " "))
end

function Reliability.hatchLuckButtonStillValid(button)
    return button
        and button.Parent
        and button:IsA("GuiButton")
        and Reliability.guiTreeVisible(button)
end

function Reliability.resolveHatchLuckButton(mode)
    local wantMax =
        tostring(mode) == "Buy Max"

    local cacheKey =
        wantMax
        and "HatchLuckBuyMaxButton"
        or "HatchLuckBuyOneButton"

    local cached = Reliability[cacheKey]

    if Reliability.hatchLuckButtonStillValid(cached) then
        return cached
    end

    Reliability[cacheKey] = nil

    local now = os.clock()
    local scanKey =
        wantMax
        and "HatchLuckBuyMaxScanAt"
        or "HatchLuckBuyOneScanAt"

    if now - (tonumber(Reliability[scanKey]) or 0) < 2 then
        return nil
    end

    Reliability[scanKey] = now

    -- Preserve support for the old confirmed hierarchy first.
    local oldRootName =
        wantMax and "MaxUpgrade" or "Upgrade"

    local oldRoot =
        playerGui:FindFirstChild(oldRootName)

    if oldRoot then
        local oldPurchase =
            oldRoot:FindFirstChild("Purchase", true)

        if oldPurchase then
            local oldButton =
                oldPurchase:IsA("GuiButton")
                and oldPurchase
                or oldPurchase:FindFirstChildWhichIsA(
                    "GuiButton",
                    true
                )

            if Reliability.hatchLuckButtonStillValid(oldButton) then
                Reliability[cacheKey] = oldButton
                return oldButton
            end
        end
    end

    local bestButton = nil
    local bestScore = -math.huge

    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("GuiButton")
            and Reliability.guiTreeVisible(obj) then

            local contextParts = {
                tostring(obj.Name or ""),
            }

            if obj:IsA("TextButton") then
                contextParts[#contextParts + 1] =
                    tostring(obj.Text or "")
            end

            -- Include the button subtree.
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("TextLabel")
                    or child:IsA("TextButton") then
                    contextParts[#contextParts + 1] =
                        tostring(child.Text or "")
                end
            end

            -- Include a small ancestor context so a generic "Purchase"
            -- button can still be identified as Hatch Luck.
            local ancestor = obj.Parent

            for _ = 1, 6 do
                if not ancestor or ancestor == playerGui then
                    break
                end

                contextParts[#contextParts + 1] =
                    tostring(ancestor.Name or "")

                if ancestor:IsA("TextLabel")
                    or ancestor:IsA("TextButton") then
                    contextParts[#contextParts + 1] =
                        tostring(ancestor.Text or "")
                end

                -- Only inspect direct text children of ancestors; avoid
                -- recursively rescanning the whole GUI tree per candidate.
                for _, child in ipairs(ancestor:GetChildren()) do
                    if child:IsA("TextLabel")
                        or child:IsA("TextButton") then
                        contextParts[#contextParts + 1] =
                            tostring(child.Text or "")
                    end
                end

                ancestor = ancestor.Parent
            end

            local context =
                string.lower(
                    table.concat(contextParts, " ")
                )

            local hasHatch =
                context:find("hatch", 1, true) ~= nil

            local hasLuck =
                context:find("luck", 1, true) ~= nil

            local dangerous =
                context:find("robux", 1, true)
                or context:find("x10", 1, true)
                or context:find("10x", 1, true)

            if hasHatch and hasLuck and not dangerous then
                local score = 0
                local lowerName =
                    string.lower(tostring(obj.Name or ""))

                if lowerName == "purchase" then
                    score += 20
                elseif lowerName:find("purchase", 1, true) then
                    score += 14
                end

                if context:find("upgrade", 1, true) then
                    score += 10
                end

                if context:find("buy", 1, true) then
                    score += 8
                end

                local saysMax =
                    context:find("buy max", 1, true)
                    or lowerName:find("max", 1, true)
                    or context:find("max upgrade", 1, true)

                if wantMax then
                    if saysMax then
                        score += 30
                    else
                        score -= 15
                    end
                else
                    if saysMax then
                        score -= 40
                    else
                        score += 10
                    end
                end

                if score > bestScore then
                    bestScore = score
                    bestButton = obj
                end
            end
        end
    end

    if bestButton and bestScore > 0 then
        Reliability[cacheKey] = bestButton
        return bestButton
    end

    return nil
end

local function buyHatchLuck()
    local mode =
        Settings.HatchLuckMode == "Buy Max"
        and "Buy Max"
        or "Buy 1"

    local button =
        Reliability.resolveHatchLuckButton(mode)

    if not button then
        Reliability.HatchLuckState =
            "Waiting for Hatch Luck purchase UI"
        return false
    end

    local context =
        Reliability.guiTextBlob(
            button.Parent or button
        )

    if context:find("no stock", 1, true)
        or context:find("maxed", 1, true)
        or context:find("sold out", 1, true)
        or context:find("maximum", 1, true)
            and context:find("reached", 1, true) then

        Reliability.HatchLuckState =
            "Hatch Luck already maxed / unavailable"
        return false
    end

    local activated =
        activateButton(button)

    if activated then
        Reliability.HatchLuckState =
            mode .. " purchase sent"
        Reliability.HatchLuckLastPurchaseAt =
            os.clock()

        -- UI often rebuilds after an upgrade. Force a fresh resolve
        -- next time rather than holding a dead button reference.
        if mode == "Buy Max" then
            Reliability.HatchLuckBuyMaxButton = nil
        else
            Reliability.HatchLuckBuyOneButton = nil
        end

        return true
    end

    Reliability.HatchLuckState =
        "Hatch Luck button found but activation failed"

    return false
end

local function getRebirthRequiredPetName()
    local main = playerGui:FindFirstChild("Main")
    local panel = main and main:FindFirstChild("Rebirth")
    local segment = panel and panel:FindFirstChild("Segment2")
    local holder = segment and segment:FindFirstChild("pEThOLDER")
    local label = holder and holder:FindFirstChild("PetName")
    if label and label:IsA("TextLabel") and label.Text ~= "" and label.Text ~= "???" then
        return label.Text
    end
    local image = holder and holder:FindFirstChild("Image")
    local viewport = image and image:FindFirstChild("Viewport")
    local world = viewport and viewport:FindFirstChild("WorldModel")
    local found = nil
    if world then
        for _, model in ipairs(world:GetChildren()) do
            if model:IsA("Model") then
                -- More than one model can mean the requirement is transitioning.
                if found then return nil end
                found = model.Name
            end
        end
    end
    return found
end

local function ownsRebirthPet(name)
    if not name then return false end
    for _, pet in ipairs(getOwnPets()) do
        if string.lower(tostring(pet:GetAttribute("PetName") or pet.Name)) == string.lower(name) then
            return true
        end
    end
    return false
end

local function rebirthReady()
    if not ownsRebirthPet(getRebirthRequiredPetName()) then
        return false
    end
    local main = playerGui:FindFirstChild("Main")
    local rebirth = main and main:FindFirstChild("Rebirth")
    local segment = rebirth and rebirth:FindFirstChild("Segment2")
    local progress = segment and segment:FindFirstChild("ProgressBarFrame")
    local value = progress and progress:FindFirstChild("Value")

    if not value or not value:IsA("TextLabel") then
        return false
    end

    local currentText, requiredText = value.Text:match("([^/]+)/(.+)")
    if not currentText or not requiredText then
        return false
    end

    return parseNumber(currentText) >= parseNumber(requiredText)
end

local function doRebirth()
    if not rebirthReady() then
        return false
    end

    local main = playerGui:FindFirstChild("Main")
    local panel = main and main:FindFirstChild("Rebirth")
    local holder = panel and panel:FindFirstChild("Rebirth")

    local previousPet = getRebirthRequiredPetName()
    local lastAttempt = rebirthRuntime.LastAttemptAt or 0
    if os.clock() - lastAttempt < 8 then return false end
    rebirthRuntime.LastAttemptAt = os.clock()
    if not activateButton(holder) then return false end
    -- A button activation is not proof that the server accepted the rebirth.
    local deadline = os.clock() + 6
    while alive and Settings.AutoRebirth and os.clock() < deadline do
        task.wait(0.2)
        local nextPet = getRebirthRequiredPetName()
        if nextPet and nextPet ~= previousPet then
            rebirthRuntime.WaitStartedAt = 0
            return true
        end
    end
    return false
end


local function textContainsKnownEgg(textValue)
    local lower = string.lower(tostring(textValue or ""))

    if lower == "" then
        return nil
    end

    -- Prefer the verified egg-name table.
    for eggName in pairs(KNOWN_WORLD_EGG_LUCK) do
        local wanted = string.lower(eggName)

        if lower:find(wanted, 1, true) then
            return eggName
        end
    end

    -- Also support new eggs that were not in the original snapshot by matching
    -- names currently rendered in the world.
    for _, egg in ipairs(getRenderedEggs()) do
        local wanted = string.lower(tostring(egg.Name))

        if wanted ~= "" and lower:find(wanted, 1, true) then
            return egg.Name
        end
    end

    return nil
end

local function normalizedRebirthPetKey(name)
    return string.lower(trim(tostring(name or "")))
end

-- Runtime provenance cache for learned rebirth pet -> egg mappings.
-- the earlier rebirth build referenced this without initializing it, which could terminate
-- the farm coroutine as soon as Auto Rebirth checked an unresolved pet.
local rebirthPetEggSources = {}

if type(Settings.RebirthPetEggSources) == "table" then
    for petKey, source in pairs(Settings.RebirthPetEggSources) do
        rebirthPetEggSources[tostring(petKey)] = tostring(source)
    end
end

local function ensureRebirthPetEggMap()
    if type(Settings.RebirthPetEggMap) ~= "table" then
        Settings.RebirthPetEggMap = {}
    end
    return Settings.RebirthPetEggMap
end

local function getRememberedRebirthEgg(petName)
    local key = normalizedRebirthPetKey(petName)
    if key == "" then return nil end

    local value = ensureRebirthPetEggMap()[key]
    if type(value) ~= "string" or trim(value) == "" then
        return nil
    end

    return trim(value)
end

local function rememberRebirthPetEgg(petName, eggName, source)
    local petKey = normalizedRebirthPetKey(petName)
    eggName = trim(tostring(eggName or ""))

    if petKey == "" or eggName == "" then
        return nil
    end

    Settings.RebirthPetEggMap = type(Settings.RebirthPetEggMap) == "table"
        and Settings.RebirthPetEggMap
        or {}

    Settings.RebirthPetEggSources = type(Settings.RebirthPetEggSources) == "table"
        and Settings.RebirthPetEggSources
        or {}

    Settings.RebirthPetEggMap[petKey] = eggName
    Settings.RebirthPetEggSources[petKey] = tostring(source or "learned")
    rebirthPetEggSources[petKey] = tostring(source or "learned")
    rebirthRuntime.MappingSource = tostring(source or "learned")

    saveConfig(Settings.ConfigProfile)
    return eggName
end

local function valueContainsRequiredPet(value, requiredPetLower, depth, visited)
    if depth < 0 then return false end

    local valueType = type(value)

    if valueType == "string" then
        return string.lower(trim(value)) == requiredPetLower
    end

    if valueType ~= "table" then
        return false
    end

    visited = visited or {}
    if visited[value] then return false end
    visited[value] = true

    local inspected = 0
    for k, v in pairs(value) do
        inspected += 1
        if inspected > 500 then break end

        if type(k) == "string" and string.lower(trim(k)) == requiredPetLower then
            return true
        end

        if type(v) == "string" and string.lower(trim(v)) == requiredPetLower then
            return true
        end

        if type(v) == "table"
            and valueContainsRequiredPet(v, requiredPetLower, depth - 1, visited) then
            return true
        end
    end

    return false
end

local function valueFindsKnownEgg(value, depth, visited)
    if depth < 0 then return nil end

    local valueType = type(value)

    if valueType == "string" then
        return textContainsKnownEgg(value)
    end

    if valueType ~= "table" then
        return nil
    end

    visited = visited or {}
    if visited[value] then return nil end
    visited[value] = true

    local inspected = 0
    for k, v in pairs(value) do
        inspected += 1
        if inspected > 500 then break end

        if type(k) == "string" then
            local fromKey = textContainsKnownEgg(k)
            if fromKey then return fromKey end
        end

        if type(v) == "string" then
            local fromValue = textContainsKnownEgg(v)
            if fromValue then return fromValue end
        elseif type(v) == "table" then
            local nested = valueFindsKnownEgg(v, depth - 1, visited)
            if nested then return nested end
        end
    end

    return nil
end



local function learnPendingHatchMapping(pet)
    if not pet then return end

    local pendingEgg = rebirthRuntime.PendingHatchEggName
    if not pendingEgg or os.clock() > (rebirthRuntime.PendingHatchUntil or 0) then
        return
    end

    local petName = tostring(pet:GetAttribute("PetName") or pet.Name or "")
    if petName == "" then return end

    rememberRebirthPetEgg(petName, pendingEgg, "observed hatch")

    local requiredPet = getRebirthRequiredPetName()
    if requiredPet
        and string.lower(petName) == string.lower(requiredPet) then
        rebirthRuntime.State =
            "Learned " .. tostring(requiredPet)
            .. " comes from " .. tostring(pendingEgg)
        setStatus("Auto Rebirth • learned "
            .. tostring(requiredPet)
            .. " → "
            .. tostring(pendingEgg))
    end

    rebirthRuntime.PendingHatchEggName = nil
    rebirthRuntime.PendingHatchUntil = 0
end


-- Known WORLD-egg rebirth sources supplied from live game knowledge.
-- These take priority over PremiumEggs because PremiumEggs can describe
-- instant/premium hatch tables rather than the best map egg to farm.
local KNOWN_REBIRTH_WORLD_EGGS = {
    [normalizedRebirthPetKey("Phoenix")] = "Blackhole Egg",
    [normalizedRebirthPetKey("Kitsune")] = "Cherub Egg",
    [normalizedRebirthPetKey("Dragon")] = "Galaxy Egg",
}

-- Horse / Fox / Unicorn intentionally have no hard-coded egg here.
-- Their exact world egg was not confirmed, so ThumbsHub learns it from
-- observed hatches or a manual override rather than guessing.
local AMBIGUOUS_WORLD_REBIRTH_PETS = {
    [normalizedRebirthPetKey("Horse")] = true,
    [normalizedRebirthPetKey("Fox")] = true,
    [normalizedRebirthPetKey("Unicorn")] = true,
}

local function getStoredRebirthMappingSource(requiredPet)
    local key = normalizedRebirthPetKey(requiredPet)

    if type(Settings.RebirthPetEggSources) == "table" then
        local source = Settings.RebirthPetEggSources[key]
        if source and tostring(source) ~= "" then
            return tostring(source)
        end
    end

    return rebirthPetEggSources and rebirthPetEggSources[key] or nil
end

local function getKnownWorldRebirthEgg(requiredPet)
    return KNOWN_REBIRTH_WORLD_EGGS[normalizedRebirthPetKey(requiredPet)]
end

local cachedGeneralGameData = nil
local cachedGeneralGameDataTried = false

local function getGeneralGameData()
    if cachedGeneralGameDataTried then
        return cachedGeneralGameData
    end

    cachedGeneralGameDataTried = true

    local replicatedStorage = game:GetService("ReplicatedStorage")
    local gameData = replicatedStorage:FindFirstChild("GameData")
    local generalModule = gameData and gameData:FindFirstChild("General")

    if not generalModule or not generalModule:IsA("ModuleScript") then
        return nil
    end

    local ok, data = pcall(require, generalModule)

    if ok and type(data) == "table" then
        cachedGeneralGameData = data
    end

    return cachedGeneralGameData
end

local function getRebirthRequirementPosition(requiredPet)
    local general = getGeneralGameData()
    local requirements = general and general.RebirthRequirements

    if type(requirements) ~= "table" or not requiredPet then
        return nil, nil
    end

    local wanted = normalizedRebirthPetKey(requiredPet)
    local count = #requirements

    for i, petName in ipairs(requirements) do
        if normalizedRebirthPetKey(petName) == wanted then
            return i, count
        end
    end

    return nil, count > 0 and count or nil
end

-- ============================================================
-- AUTO REBIRTH: DEDICATED WORLD-EGG DISCOVERY
-- ============================================================
--
-- IMPORTANT:
-- This is intentionally separate from chooseFarmEgg().
-- Auto Rebirth discovery must NOT simply chase the best/highest-luck egg.
--
-- For Horse / Fox / Unicorn, where the exact free-world source is not yet
-- confirmed, ThumbsHub tests egg TYPES in a controlled progression order.
-- The start point scales with the rebirth requirement position, then advances
-- after each discovery hatch. Once the required pet is actually observed,
-- the existing hatch-learning system stores the real pet -> egg mapping.

local REBIRTH_DISCOVERY_EGG_ORDER = {
    "White Egg",
    "Brown Egg",
    "Cracked Egg",
    "Easter Egg",
    "Stone Egg",
    "Leaf Egg",
    "Mushroom Egg",
    "Flower Egg",
    "Slime Egg",
    "Ice Egg",
    "Glass Egg",
    "Golden Egg",
    "Diamond Egg",
    "Crystal Egg",
    "Skull Egg",
    "Asteroid Egg",
    "Dominus Egg",
    "Flaming Egg",
    "Sinister Egg",
    "Soul Egg",
    "Aurora Egg",
    "Galaxy Egg",
    "Blackhole Egg",
    "Solaris Egg",
    "Cherub Egg",
}

local REBIRTH_DISCOVERY_ORDER_INDEX = {}
for i, eggName in ipairs(REBIRTH_DISCOVERY_EGG_ORDER) do
    REBIRTH_DISCOVERY_ORDER_INDEX[string.lower(eggName)] = i
end

local function resetRebirthDiscoveryProgress(requiredPet)
    local reqIndex, reqCount = getRebirthRequirementPosition(requiredPet)

    -- Scale the starting point through the world-egg ladder according to the
    -- rebirth requirement position. This is only a discovery starting point,
    -- NOT a claim that one exact egg contains the pet.
    local startIndex = 1

    if reqIndex and reqCount and reqCount > 1 then
        local progress = (reqIndex - 1) / (reqCount - 1)
        startIndex = math.floor(
            1 + progress * (#REBIRTH_DISCOVERY_EGG_ORDER - 1) + 0.5
        )
    end

    rebirthRuntime.DiscoveryIndex =
        math.clamp(startIndex, 1, #REBIRTH_DISCOVERY_EGG_ORDER)
    rebirthRuntime.DiscoverySelectedIndex = nil
    rebirthRuntime.DiscoveryRound = 1
end

local function advanceRebirthDiscoveryProgress()
    local selected = tonumber(rebirthRuntime.DiscoverySelectedIndex)
        or tonumber(rebirthRuntime.DiscoveryIndex)
        or 1

    selected += 1

    if selected > #REBIRTH_DISCOVERY_EGG_ORDER then
        selected = 1
        rebirthRuntime.DiscoveryRound =
            (tonumber(rebirthRuntime.DiscoveryRound) or 1) + 1
    end

    rebirthRuntime.DiscoveryIndex = selected
    rebirthRuntime.DiscoverySelectedIndex = nil
end

local function chooseRebirthDiscoveryEgg(requiredPet)
    local _, _, root = getCharacter()
    if not root then
        return nil
    end

    if rebirthRuntime.DiscoveryRequiredPet
        and normalizedRebirthPetKey(rebirthRuntime.DiscoveryRequiredPet)
            ~= normalizedRebirthPetKey(requiredPet) then
        resetRebirthDiscoveryProgress(requiredPet)
    end

    if not rebirthRuntime.DiscoveryIndex then
        resetRebirthDiscoveryProgress(requiredPet)
    end

    local visibleByName = {}

    -- Ignore ALL normal Auto Farm filters here.
    for _, egg in ipairs(getRenderedEggs()) do
        local prompt = getPickupPrompt(egg)
        local pos = getObjectPosition(egg)

        if prompt and pos then
            local key = string.lower(tostring(egg.Name))
            local distance = (root.Position - pos).Magnitude
            local previous = visibleByName[key]

            -- If multiple copies of one egg type exist, use the nearest copy.
            if not previous or distance < previous.distance then
                visibleByName[key] = {
                    egg = egg,
                    distance = distance,
                }
            end
        end
    end

    local startIndex = math.clamp(
        tonumber(rebirthRuntime.DiscoveryIndex) or 1,
        1,
        #REBIRTH_DISCOVERY_EGG_ORDER
    )

    -- Search forward from the current discovery position.
    for offset = 0, #REBIRTH_DISCOVERY_EGG_ORDER - 1 do
        local index = ((startIndex - 1 + offset)
            % #REBIRTH_DISCOVERY_EGG_ORDER) + 1
        local wanted = REBIRTH_DISCOVERY_EGG_ORDER[index]
        local found = visibleByName[string.lower(wanted)]

        if found then
            rebirthRuntime.DiscoverySelectedIndex = index
            return found.egg, index, wanted
        end
    end

    return nil
end


local function resolveRebirthEggFromGeneral(requiredPet)
    local general = getGeneralGameData()
    local premiumEggs = general and general.PremiumEggs

    if type(premiumEggs) ~= "table" or not requiredPet then
        return nil, nil
    end

    local wanted = normalizedRebirthPetKey(requiredPet)
    if wanted == "" then
        return nil, nil
    end

    local candidates = {}

    for eggName, eggData in pairs(premiumEggs) do
        if type(eggName) == "string" and type(eggData) == "table" then
            local pets = eggData.Pets

            if type(pets) == "table" then
                for petName, weight in pairs(pets) do
                    if normalizedRebirthPetKey(petName) == wanted then
                        table.insert(candidates, {
                            Egg = eggName,
                            Weight = tonumber(weight) or 0,
                        })
                    end
                end
            end
        end
    end

    if #candidates == 0 then
        return nil, nil
    end

    -- Prefer the highest hatch weight/chance. This makes the choice deterministic
    -- for the full lifetime of this rebirth requirement.
    table.sort(candidates, function(a, b)
        if a.Weight ~= b.Weight then
            return a.Weight > b.Weight
        end
        return tostring(a.Egg) < tostring(b.Egg)
    end)

    return candidates[1].Egg, candidates[1].Weight
end

local function refreshActiveRebirthRequirement(requiredPet)
    if not requiredPet then
        rebirthRuntime.ActiveRequiredPet = nil
        rebirthRuntime.ActiveRequiredEgg = nil
        rebirthRuntime.ActiveRequiredEggWeight = nil
        rebirthRuntime.RequirementIndex = nil
        rebirthRuntime.RequirementCount = nil
        return
    end

    local petKey = normalizedRebirthPetKey(requiredPet)
    local activeKey = normalizedRebirthPetKey(rebirthRuntime.ActiveRequiredPet)

    -- A new rebirth requirement means the previous egg target must be discarded.
    if petKey ~= activeKey then
        rebirthRuntime.ActiveRequiredPet = requiredPet
        rebirthRuntime.ActiveRequiredEgg = nil
        rebirthRuntime.ActiveRequiredEggWeight = nil
        rebirthRuntime.WaitingEggName = nil
        rebirthRuntime.WaitStartedAt = 0
        rebirthRuntime.PostHatchUntil = 0
        rebirthRuntime.DeepScanResult = nil
        rebirthRuntime.DiscoveryEggName = nil
        rebirthRuntime.DiscoveryRequiredPet = requiredPet
        rebirthRuntime.DiscoveryCooldownUntil = 0
        resetRebirthDiscoveryProgress(requiredPet)
    end

    local index, count = getRebirthRequirementPosition(requiredPet)
    rebirthRuntime.RequirementIndex = index
    rebirthRuntime.RequirementCount = count
end

local function getRebirthRequiredEggName()
    local requiredPet = getRebirthRequiredPetName()
    rebirthRuntime.RequiredPet = requiredPet

    if not requiredPet then
        refreshActiveRebirthRequirement(nil)
        rebirthRuntime.MappingSource = "None"
        return nil
    end

    refreshActiveRebirthRequirement(requiredPet)

    -- Keep one stable egg target for the entire current rebirth requirement.
    if rebirthRuntime.ActiveRequiredEgg then
        return rebirthRuntime.ActiveRequiredEgg
    end

    -- 1) MANUAL OVERRIDE: explicit user choice always wins for this pet.
    local override = trim(tostring(Settings.RebirthEggOverride or ""))

    if override ~= "" then
        local learned = rememberRebirthPetEgg(requiredPet, override, "manual override")
        rebirthRuntime.OverrideText = override
        rebirthRuntime.OverridePet = requiredPet
        rebirthRuntime.ActiveRequiredEgg = learned
        rebirthRuntime.MappingSource = "manual override"
        return learned
    else
        rebirthRuntime.OverrideText = nil
        rebirthRuntime.OverridePet = nil
    end

    -- 2) EXACT KNOWN WORLD-EGG FALLBACKS.
    -- Phoenix -> Blackhole Egg
    -- Kitsune -> Cherub Egg
    -- Dragon  -> Galaxy Egg
    local knownWorldEgg = getKnownWorldRebirthEgg(requiredPet)

    if knownWorldEgg then
        rebirthRuntime.ActiveRequiredEgg = knownWorldEgg
        rebirthRuntime.ActiveRequiredEggWeight = nil
        rebirthRuntime.MappingSource = "Known world egg"
        return knownWorldEgg
    end

    -- 3) TRUST ONLY LEARNED WORLD/OBSERVED OR MANUAL MAPPINGS.
    -- Old the earlier rebirth build GameData.General mappings are deliberately NOT trusted for
    -- Horse/Fox/Unicorn because PremiumEggs may not represent the correct
    -- free world egg route.
    local remembered = getRememberedRebirthEgg(requiredPet)
    local rememberedSource = getStoredRebirthMappingSource(requiredPet)

    if remembered then
        local sourceLower = string.lower(tostring(rememberedSource or ""))
        local trustworthy =
            sourceLower:find("observ", 1, true)
            or sourceLower:find("hatch", 1, true)
            or sourceLower:find("manual", 1, true)
            or sourceLower:find("world", 1, true)

        if trustworthy then
            rebirthRuntime.ActiveRequiredEgg = remembered
            rebirthRuntime.MappingSource = rememberedSource or "Learned world hatch"
            return remembered
        end
    end

    -- 4) For ambiguous world pets (Horse/Fox/Unicorn), do NOT turn a
    -- PremiumEggs entry into a hard target. Leave it unresolved so the normal
    -- farm can discover/observe the correct source instead of farming the wrong egg.
    local petKey = normalizedRebirthPetKey(requiredPet)
    if AMBIGUOUS_WORLD_REBIRTH_PETS[petKey] then
        rebirthRuntime.MappingSource = "World source not learned yet"
        return nil
    end

    -- 5) Secondary hint from GameData.General.PremiumEggs for any other pet.
    local generalEgg, generalWeight = resolveRebirthEggFromGeneral(requiredPet)

    if generalEgg then
        rebirthRuntime.ActiveRequiredEgg = generalEgg
        rebirthRuntime.ActiveRequiredEggWeight = generalWeight
        rebirthRuntime.MappingSource = "PremiumEggs hint"
        return generalEgg
    end

    -- 6) Visible rebirth UI / value / attribute fallback.
    local mainGui = playerGui:FindFirstChild("Main")
    local panel = mainGui and mainGui:FindFirstChild("Rebirth")

    if panel then
        for _, d in ipairs(panel:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                local found = textContainsKnownEgg(d.Text)
                if found then
                    rebirthRuntime.MappingSource = "Rebirth UI"
                    rebirthRuntime.ActiveRequiredEgg = found
                    return rememberRebirthPetEgg(requiredPet, found, "rebirth UI world hint")
                end
            elseif d:IsA("StringValue") then
                local found = textContainsKnownEgg(d.Value)
                if found then
                    rebirthRuntime.MappingSource = "Rebirth value"
                    rebirthRuntime.ActiveRequiredEgg = found
                    return rememberRebirthPetEgg(requiredPet, found, "rebirth value world hint")
                end
            end
        end
    end

    rebirthRuntime.MappingSource = "Unresolved"
    return nil
end

local function placedEggMatchesRequirement(egg, requiredName)
    if not egg or not requiredName then
        return false
    end

    if eggNameMatches(egg.Name, requiredName) then
        return true
    end

    for _, attrName in ipairs({"EggKey", "EggName", "Key", "Type"}) do
        local value = egg:GetAttribute(attrName)

        if value ~= nil and eggNameMatches(value, requiredName) then
            return true
        end
    end

    local handle = egg:FindFirstChild("Handle")

    if handle then
        local hatch = handle:FindFirstChild("Hatch")

        if hatch and hatch:IsA("ProximityPrompt") then
            if eggNameMatches(hatch.ObjectText, requiredName) then
                return true
            end
        end
    end

    return false
end

local function findPlacedRebirthEgg(requiredName)
    if not requiredName or requiredName == "" then
        return nil
    end

    local plot = getOwnPlot()
    local eggs = plot and plot:FindFirstChild("Eggs")

    if not eggs then
        return nil
    end

    for _, egg in ipairs(eggs:GetChildren()) do
        if placedEggMatchesRequirement(egg, requiredName) then
            return egg
        end
    end

    return nil
end

local function getPlacedEggHatchState(egg)
    if not egg then
        return false, nil, nil
    end

    local handle = egg:FindFirstChild("Handle")
    local ui = handle and handle:FindFirstChild("HatchingUI")
    local timerLabel = ui and ui:FindFirstChild("Timer")
    local hatch = handle and handle:FindFirstChild("Hatch")
    local seconds = nil
    local ready = false

    if timerLabel and timerLabel:IsA("TextLabel") then
        local lower = string.lower(timerLabel.Text or "")
        seconds = parseTimer(timerLabel.Text)
        ready = seconds <= 0 or lower:find("ready", 1, true) ~= nil
    elseif hatch and hatch:IsA("ProximityPrompt") then
        ready = true
    end

    if not hatch or not hatch:IsA("ProximityPrompt") then
        hatch = nil
    end

    return ready, hatch, seconds
end

-- ============================================================
-- STRICT AUTO-REBIRTH EGG LOCK
-- ============================================================
-- Once a rebirth/discovery egg is placed, world farming must remain locked
-- until THAT placed egg has hatched and its pet result has been checked.

function rebirthRuntime.FindNewestPlacedEgg(eggName)
    local plot = getOwnPlot()
    local eggs = plot and plot:FindFirstChild("Eggs")

    if not eggs or not eggName then
        return nil
    end

    local wanted = string.lower(tostring(eggName))
    local best = nil
    local bestPlaceTime = -math.huge
    local fallback = nil

    for _, egg in ipairs(eggs:GetChildren()) do
        if string.lower(tostring(egg.Name or "")) == wanted then
            fallback = egg

            local eggData = egg:FindFirstChild("EggData")
            local placeTime = eggData and eggData:FindFirstChild("PlaceTime")

            if placeTime and placeTime:IsA("NumberValue") then
                local n = tonumber(placeTime.Value)

                if n and n >= bestPlaceTime then
                    bestPlaceTime = n
                    best = egg
                end
            end
        end
    end

    return best or fallback
end

function rebirthRuntime.ClearEggLock()
    rebirthRuntime.LockActive = false
    rebirthRuntime.LockedEgg = nil
    rebirthRuntime.LockedEggName = nil
    rebirthRuntime.LockedEggKey = nil
    rebirthRuntime.LockMode = nil
    rebirthRuntime.LockRequiredPet = nil
    rebirthRuntime.LockStartedAt = 0
    rebirthRuntime.LockHatchSentAt = 0
    rebirthRuntime.LockCheckAfter = 0
    rebirthRuntime.LockWasHatched = false
    rebirthRuntime.LockState = "Idle"
end

function rebirthRuntime.BeginEggLock(eggName, mode, requiredPet)
    local egg = rebirthRuntime.FindNewestPlacedEgg(eggName)

    rebirthRuntime.LockActive = true
    rebirthRuntime.LockedEgg = egg
    rebirthRuntime.LockedEggName = tostring(eggName or "")
    rebirthRuntime.LockedEggKey =
        egg and egg:GetAttribute("EggKey") or nil
    rebirthRuntime.LockMode = tostring(mode or "required")
    rebirthRuntime.LockRequiredPet =
        tostring(requiredPet or getRebirthRequiredPetName() or "")
    rebirthRuntime.LockStartedAt = os.clock()
    rebirthRuntime.LockHatchSentAt = 0
    rebirthRuntime.LockCheckAfter = 0
    rebirthRuntime.LockWasHatched = false
    rebirthRuntime.LockState = "Waiting for hatch"

    if rebirthRuntime.LockMode == "discovery" then
        rebirthRuntime.DiscoveryEggName =
            rebirthRuntime.LockedEggName
        rebirthRuntime.DiscoveryRequiredPet =
            rebirthRuntime.LockRequiredPet
        rebirthRuntime.DiscoveryCooldownUntil = math.huge
    else
        rebirthRuntime.WaitingEggName =
            rebirthRuntime.LockedEggName
        rebirthRuntime.WaitStartedAt = os.clock()
        rebirthRuntime.PostHatchUntil = 0
    end

    rebirthRuntime.State =
        "Locked "
        .. tostring(rebirthRuntime.LockedEggName)
        .. " • waiting to hatch"

    setStatus(
        "Auto Rebirth • "
        .. tostring(rebirthRuntime.LockedEggName)
        .. " placed • waiting for hatch"
    )

    return egg
end

function rebirthRuntime.ResolveLockedEgg()
    local egg = rebirthRuntime.LockedEgg

    if egg and egg.Parent then
        return egg
    end

    local plot = getOwnPlot()
    local eggs = plot and plot:FindFirstChild("Eggs")

    if not eggs then
        return nil
    end

    local wantedKey = rebirthRuntime.LockedEggKey

    if wantedKey then
        for _, candidate in ipairs(eggs:GetChildren()) do
            if candidate:GetAttribute("EggKey") == wantedKey then
                rebirthRuntime.LockedEgg = candidate
                return candidate
            end
        end
    end

    -- Only fall back by name BEFORE a hatch request was sent.
    -- After hatching, another same-name egg must never steal the lock.
    if (rebirthRuntime.LockHatchSentAt or 0) <= 0 then
        local newest =
            rebirthRuntime.FindNewestPlacedEgg(
                rebirthRuntime.LockedEggName
            )

        if newest then
            rebirthRuntime.LockedEgg = newest
            rebirthRuntime.LockedEggKey =
                newest:GetAttribute("EggKey")
            return newest
        end
    end

    return nil
end

function rebirthRuntime.GetLockedHatchPrompt(egg)
    if not egg then
        return nil
    end

    local handle = egg:FindFirstChild("Handle")
    local hatch = handle and handle:FindFirstChild("Hatch")

    if hatch and hatch:IsA("ProximityPrompt") then
        return hatch
    end

    return nil
end

function rebirthRuntime.ProcessEggLock()
    if not Settings.AutoRebirth
        or not rebirthRuntime.LockActive then
        return false
    end

    local requiredPet =
        rebirthRuntime.LockRequiredPet
        or getRebirthRequiredPetName()

    local currentRequiredPet =
        getRebirthRequiredPetName()

    -- If the game has already moved to a different rebirth requirement,
    -- the previous locked cycle is complete.
    if requiredPet
        and requiredPet ~= ""
        and currentRequiredPet
        and normalizedRebirthPetKey(currentRequiredPet)
            ~= normalizedRebirthPetKey(requiredPet) then

        rebirthRuntime.ClearEggLock()
        return false
    end

    local egg = rebirthRuntime.ResolveLockedEgg()

    -- Egg disappeared after we sent Hatch -> wait for pet replication.
    if not egg and (rebirthRuntime.LockHatchSentAt or 0) > 0 then
        if rebirthRuntime.LockCheckAfter <= 0 then
            rebirthRuntime.LockCheckAfter = os.clock() + 2.0
        end

        if os.clock() < rebirthRuntime.LockCheckAfter then
            rebirthRuntime.LockState = "Hatched • checking pet result"
            rebirthRuntime.State =
                "Hatched • checking for "
                .. tostring(requiredPet or "required pet")

            setStatus(
                "Auto Rebirth • egg hatched • checking for "
                .. tostring(requiredPet or "required pet")
            )

            return true
        end

        local hasPet =
            requiredPet
            and requiredPet ~= ""
            and ownsRebirthPet(requiredPet)

        if hasPet then
            rebirthRuntime.LockState =
                "Required pet obtained • checking eligibility"

            rebirthRuntime.State =
                "Have "
                .. tostring(requiredPet)
                .. " • checking rebirth eligibility"

            setStatus(
                "Auto Rebirth • got "
                .. tostring(requiredPet)
                .. " • checking eligibility"
            )

            local ready = rebirthReady()

            rebirthRuntime.ClearEggLock()

            if ready then
                rebirthRuntime.State = "Eligible • rebirthing"

                if doRebirth() then
                    rebirthRuntime.LastRebirthAt = os.clock()
                    rebirthRuntime.WaitingEggName = nil
                    rebirthRuntime.PostHatchUntil =
                        os.clock() + 2

                    rebirthRuntime.State =
                        "Rebirthed • checking next requirement"

                    setStatus(
                        "Auto Rebirth • rebirth completed • checking next requirement"
                    )

                    if Settings.WebhookRebirth then
                        task.defer(function()
                            task.wait(0.4)

                            sendWebhook(
                                "Rebirth Completed",
                                {
                                    PreviousPet =
                                        requiredPet or "Unknown",
                                    NextPet =
                                        getRebirthRequiredPetName()
                                        or "Detecting...",
                                    Player = player.Name,
                                }
                            )
                        end)
                    end
                end
            else
                rebirthRuntime.State =
                    "Have "
                    .. tostring(requiredPet)
                    .. " • waiting for rebirth eligibility"

                setStatus(
                    "Auto Rebirth • have "
                    .. tostring(requiredPet)
                    .. " • waiting until rebirth is eligible"
                )
            end

            return true
        end

        -- Required pet was not obtained.
        if rebirthRuntime.LockMode == "discovery" then
            advanceRebirthDiscoveryProgress()

            rebirthRuntime.DiscoveryEggName = nil
            rebirthRuntime.DiscoveryRequiredPet = nil
            rebirthRuntime.DiscoveryCooldownUntil =
                os.clock() + 1.5

            setStatus(
                "Auto Rebirth discovery • "
                .. tostring(requiredPet or "required pet")
                .. " not obtained • trying next egg type"
            )
        else
            rebirthRuntime.WaitingEggName = nil
            rebirthRuntime.WaitStartedAt = 0
            rebirthRuntime.PostHatchUntil =
                os.clock() + 1.2

            setStatus(
                "Auto Rebirth • required pet not obtained • farming another "
                .. tostring(rebirthRuntime.LockedEggName or "egg")
            )
        end

        rebirthRuntime.ClearEggLock()
        return true
    end

    -- If the egg disappeared before Hatch was sent, reacquire briefly.
    if not egg then
        if os.clock() - (rebirthRuntime.LockStartedAt or 0) < 3 then
            rebirthRuntime.LockState =
                "Waiting for placed egg replication"

            rebirthRuntime.State =
                "Placed egg replicating..."

            return true
        end

        -- Do not keep farming under a stale lock forever.
        rebirthRuntime.ClearEggLock()
        return false
    end

    local hatch =
        rebirthRuntime.GetLockedHatchPrompt(egg)

    if not hatch then
        rebirthRuntime.LockState =
            "Waiting for Hatch prompt"

        rebirthRuntime.State =
            "Waiting for "
            .. tostring(rebirthRuntime.LockedEggName)
            .. " hatch prompt"

        return true
    end

    -- The live scan showed Hatch.Enabled flips false -> true exactly when ready.
    if not hatch.Enabled then
        rebirthRuntime.LockState =
            "Waiting for hatch timer"

        rebirthRuntime.State =
            "Waiting for "
            .. tostring(rebirthRuntime.LockedEggName)
            .. " to hatch"

        setStatus(
            "Auto Rebirth • "
            .. tostring(rebirthRuntime.LockedEggName)
            .. " incubating • waiting for Hatch"
        )

        return true
    end

    if busyFarm or manualPlacementWaiting then
        rebirthRuntime.LockState =
            "Hatch ready • waiting for movement to stop"
        return true
    end

    rebirthRuntime.LockState =
        "Hatch ready • moving to egg"

    rebirthRuntime.State =
        tostring(rebirthRuntime.LockedEggName)
        .. " ready • hatching now"

    setStatus(
        "Auto Rebirth • "
        .. tostring(rebirthRuntime.LockedEggName)
        .. " ready • hatching now"
    )

    -- Path safely into the plot first, then close enough to this exact egg.
    Reliability.ensureInsideOwnPlot(function()
        return alive
            and Settings.AutoRebirth
            and rebirthRuntime.LockActive
    end)

    local promptPos =
        getObjectPosition(hatch.Parent)

    if promptPos then
        Reliability.pathWalkTo(
            promptPos,
            math.max(
                2,
                (tonumber(hatch.MaxActivationDistance) or 15) - 2
            ),
            14,
            function()
                return alive
                    and Settings.AutoRebirth
                    and rebirthRuntime.LockActive
            end
        )
    end

    if not hatch.Parent or not hatch.Enabled then
        return true
    end

    rebirthRuntime.PendingHatchEggName =
        tostring(rebirthRuntime.LockedEggName)

    rebirthRuntime.PendingHatchUntil =
        os.clock() + 5

    local fired =
        triggerPrompt(
            hatch,
            function()
                return alive
                    and Settings.AutoRebirth
                    and rebirthRuntime.LockActive
            end
        )

    if fired then
        rebirthRuntime.LockHatchSentAt = os.clock()
        rebirthRuntime.LockState =
            "Hatch sent • verifying egg removal"

        local verifyUntil = os.clock() + 3

        while alive
            and os.clock() < verifyUntil
            and rebirthRuntime.LockActive do

            local locked =
                rebirthRuntime.ResolveLockedEgg()

            if not locked then
                farmStats.Hatched += 1
                rebirthRuntime.LockWasHatched = true
                rebirthRuntime.LockCheckAfter =
                    os.clock() + 2.0

                rebirthRuntime.State =
                    "Hatched • checking pet result"

                setStatus(
                    "Auto Rebirth • hatch confirmed • checking pet"
                )

                return true
            end

            task.wait(0.08)
        end

        -- Prompt fired but server did not remove the egg yet. Retry on the
        -- next progression tick rather than unlocking world farming.
        rebirthRuntime.LockHatchSentAt = 0
        rebirthRuntime.LockState =
            "Hatch not confirmed • retrying"
    end

    return true
end


local function rebirthWaitingForPlacedEgg()
    if not Settings.AutoRebirth then
        return false
    end

    if rebirthRuntime.LockActive then
        return true
    end

    -- Discovery egg currently on the plot.
    if rebirthRuntime.DiscoveryEggName then
        local discoveryPlaced =
            findPlacedRebirthEgg(rebirthRuntime.DiscoveryEggName)

        if discoveryPlaced then
            return true
        end
    end

    -- Known required egg currently on the plot.
    local required = rebirthRuntime.RequiredEgg
        or rebirthRuntime.ActiveRequiredEgg

    if required then
        local requiredPlaced = findPlacedRebirthEgg(required)

        if requiredPlaced then
            return true
        end
    end

    return false
end


local function getRebirthFarmTargetName()
    if not Settings.AutoRebirth then
        return nil
    end

    if rebirthReady() then
        return nil
    end

    local pet = getRebirthRequiredPetName()
    if ownsRebirthPet(pet) then
        rebirthRuntime.State = "Have " .. pet .. " • waiting for cash"
        return nil
    end

    local required = getRebirthRequiredEggName()
    rebirthRuntime.RequiredEgg = required

    if not required then
        local petKey = normalizedRebirthPetKey(pet)

        if AMBIGUOUS_WORLD_REBIRTH_PETS[petKey] then
            rebirthRuntime.State =
                "Need " .. tostring(pet or "pet")
                .. " • discovering best world egg source"
        else
            rebirthRuntime.State =
                "Need " .. tostring(pet or "pet")
                .. " • egg mapping unresolved"
        end

        return nil
    end

    local placed = findPlacedRebirthEgg(required)

    if placed then
        rebirthRuntime.WaitingEggName = required
        rebirthRuntime.State = "Waiting for " .. required .. " to hatch"
        return nil
    end

    if rebirthRuntime.WaitingEggName
        and eggNameMatches(rebirthRuntime.WaitingEggName, required) then

        -- One-at-a-time manual placement:
        -- once collected, do NOT fetch another required egg until this one
        -- has actually been placed and then disappears/hatches.
        if not rebirthRuntime.ManualPlacedSeen then
            rebirthRuntime.State =
                "Collected "
                .. tostring(required)
                .. " • place it manually"
            return nil
        end

        local now = os.clock()

        if now < (rebirthRuntime.PostHatchUntil or 0) then
            rebirthRuntime.State = "Checking hatch result"
            return nil
        end

        -- The manually placed egg has disappeared. If the required pet still
        -- isn't owned, clear the wait and fetch exactly ONE more.
        if not findPlacedRebirthEgg(required) then
            rebirthRuntime.WaitingEggName = nil
            rebirthRuntime.WaitStartedAt = 0
            rebirthRuntime.ManualPlacedSeen = false
        else
            return nil
        end
    end

    local stepText = ""
    if rebirthRuntime.RequirementIndex and rebirthRuntime.RequirementCount then
        stepText = " [" .. tostring(rebirthRuntime.RequirementIndex)
            .. "/" .. tostring(rebirthRuntime.RequirementCount) .. "]"
    end

    rebirthRuntime.State =
        "Need " .. tostring(pet or "pet")
        .. stepText
        .. " • farm " .. tostring(required)

    return required
end


local function rebirthNeedsWorldDiscovery()
    if not Settings.AutoRebirth then
        return false
    end

    local pet = getRebirthRequiredPetName()
    if not pet or ownsRebirthPet(pet) then
        return false
    end

    local petKey = normalizedRebirthPetKey(pet)
    if not AMBIGUOUS_WORLD_REBIRTH_PETS[petKey] then
        return false
    end

    if getRebirthRequiredEggName() ~= nil then
        return false
    end

    if rebirthRuntime.DiscoveryEggName then
        return false
    end

    if os.clock() < (rebirthRuntime.DiscoveryCooldownUntil or 0) then
        return false
    end

    return true
end

local function processRebirthDiscoveryHatch()
    local eggName = rebirthRuntime.DiscoveryEggName
    local requiredPet = rebirthRuntime.DiscoveryRequiredPet

    if not eggName or not requiredPet then
        return false
    end

    local currentPet = getRebirthRequiredPetName()

    -- Requirement changed (for example because a rebirth completed): discard
    -- the old discovery egg and let the next requirement start fresh.
    if normalizedRebirthPetKey(currentPet) ~= normalizedRebirthPetKey(requiredPet) then
        rebirthRuntime.DiscoveryEggName = nil
        rebirthRuntime.DiscoveryRequiredPet = nil
        return false
    end

    local placed = findPlacedRebirthEgg(eggName)

    if not placed then
        if not rebirthRuntime.DiscoveryManualPlacedSeen then
            rebirthRuntime.State =
                "Discovery • collected "
                .. tostring(eggName)
                .. " • place it manually"

            return true
        end

        -- It was manually placed and has now disappeared/hatch completed.
        -- Wait briefly for the hatched pet to replicate before testing another
        -- candidate egg type.
        if not rebirthRuntime.DiscoveryDisappearAt then
            rebirthRuntime.DiscoveryDisappearAt = os.clock()
            rebirthRuntime.State =
                "Discovery • hatched "
                .. tostring(eggName)
                .. " • checking result"
            return true
        end

        if os.clock() - rebirthRuntime.DiscoveryDisappearAt < 2 then
            rebirthRuntime.State =
                "Discovery • checking "
                .. tostring(eggName)
                .. " result"
            return true
        end

        if ownsRebirthPet(requiredPet) then
            rebirthRuntime.State =
                "Discovery • required pet obtained"
            return false
        end

        advanceRebirthDiscoveryProgress()

        rebirthRuntime.DiscoveryEggName = nil
        rebirthRuntime.DiscoveryRequiredPet = nil
        rebirthRuntime.DiscoveryManualPlacedSeen = false
        rebirthRuntime.DiscoveryDisappearAt = nil
        rebirthRuntime.DiscoveryCooldownUntil = os.clock() + 1.5
        return false
    end

    rebirthRuntime.DiscoveryManualPlacedSeen = true
    rebirthRuntime.DiscoveryDisappearAt = nil

    local ready, hatchPrompt, seconds = getPlacedEggHatchState(placed)

    if not ready then
        rebirthRuntime.State =
            "Discovery • waiting " .. tostring(eggName)
            .. (seconds ~= nil and (" • " .. tostring(math.max(0, math.floor(seconds))) .. "s") or "")
        return true
    end

    if Settings.AutoHatchEggs then
        rebirthRuntime.State =
            "Discovery • "
            .. tostring(eggName)
            .. " ready • auto hatching"

        if not busyFarm and not manualPlacementWaiting and hatchPrompt then
            rebirthRuntime.PendingHatchEggName = tostring(eggName)
            rebirthRuntime.PendingHatchUntil = os.clock() + 4

            if triggerPrompt(hatchPrompt, function()
                return alive
                    and Settings.AutoRebirth
                    and Settings.AutoHatchEggs
            end) then
                farmStats.Hatched += 1
                rebirthRuntime.PostHatchUntil = os.clock() + 4

                setStatus(
                    "Auto Rebirth discovery • hatched "
                    .. tostring(eggName)
                    .. " • checking for "
                    .. tostring(requiredPet)
                )
            end
        end
    else
        rebirthRuntime.State =
            "Discovery • "
            .. tostring(eggName)
            .. " ready • hatch it manually"

        setStatus(
            "Auto Rebirth discovery • "
            .. tostring(eggName)
            .. " ready • hatch it manually"
        )
    end

    return true
end

local function updateSmartRebirth()
    if not Settings.AutoRebirth then
        rebirthRuntime.RequiredEgg = nil
        rebirthRuntime.WaitingEggName = nil
        rebirthRuntime.ActiveRequiredPet = nil
        rebirthRuntime.ActiveRequiredEgg = nil
        rebirthRuntime.ActiveRequiredEggWeight = nil
        rebirthRuntime.RequirementIndex = nil
        rebirthRuntime.RequirementCount = nil
        rebirthRuntime.DiscoveryEggName = nil
        rebirthRuntime.DiscoveryRequiredPet = nil
        rebirthRuntime.DiscoveryCooldownUntil = 0
        rebirthRuntime.DiscoveryIndex = nil
        rebirthRuntime.DiscoverySelectedIndex = nil
        rebirthRuntime.DiscoveryRound = 1
        rebirthRuntime.ClearEggLock()
        rebirthRuntime.State = "Disabled"
        return
    end

    -- A placed rebirth egg owns the entire lifecycle until its hatch result
    -- is known. Do not let mapping/discovery logic start another farm trip.
    if rebirthRuntime.ProcessEggLock() then
        return
    end

    local required = getRebirthRequiredEggName()
    rebirthRuntime.RequiredEgg = required
    local pet = getRebirthRequiredPetName()

    if rebirthReady() then
        rebirthRuntime.State = "Eligible • rebirthing"

        if doRebirth() then
            rebirthRuntime.LastRebirthAt = os.clock()
            rebirthRuntime.WaitingEggName = nil
            rebirthRuntime.PostHatchUntil = os.clock() + 2
            rebirthRuntime.State = "Rebirthed • checking next requirement"
            setStatus("Auto Rebirth • rebirth completed")

            if Settings.WebhookRebirth then
                task.defer(function()
                    task.wait(0.4)
                    sendWebhook("Rebirth Completed", {
                        PreviousPet = pet or "Unknown",
                        NextPet = getRebirthRequiredPetName() or "Detecting...",
                        Player = player.Name,
                    })
                end)
            end
        end

        return
    end

    if ownsRebirthPet(pet) then
        rebirthRuntime.State = "Have " .. pet .. " • waiting for cash"
        return
    end

    if not required then
        if processRebirthDiscoveryHatch() then
            return
        end

        local petKey = normalizedRebirthPetKey(pet)

        if AMBIGUOUS_WORLD_REBIRTH_PETS[petKey] then
            rebirthRuntime.State =
                "Need " .. tostring(pet or "pet")
                .. " • auto-discovering world egg source"
        else
            rebirthRuntime.State =
                "Need " .. tostring(pet or "pet")
                .. " • egg mapping unresolved"
        end

        return
    end

    local placed = findPlacedRebirthEgg(required)

    if placed then
        rebirthRuntime.WaitingEggName = required
        rebirthRuntime.ManualPlacedSeen = true
        rebirthRuntime.ManualDisappearAt = nil

        if rebirthRuntime.WaitStartedAt <= 0 then
            rebirthRuntime.WaitStartedAt = os.clock()
        end

        local ready, hatchPrompt, seconds = getPlacedEggHatchState(placed)

        if ready then
            if Settings.AutoHatchEggs then
                rebirthRuntime.State = "Required egg ready • auto hatching"

                if not busyFarm
                    and not manualPlacementWaiting
                    and hatchPrompt then

                    rebirthRuntime.PendingHatchEggName =
                        tostring(required)

                    rebirthRuntime.PendingHatchUntil =
                        os.clock() + 4

                    if triggerPrompt(hatchPrompt, function()
                        return alive
                            and Settings.AutoRebirth
                            and Settings.AutoHatchEggs
                    end) then
                        farmStats.Hatched += 1
                        rebirthRuntime.PostHatchUntil =
                            os.clock() + 5

                        rebirthRuntime.State =
                            "Required egg hatched • checking eligibility"

                        setStatus(
                            "Auto Rebirth • required egg hatched"
                        )
                    end
                end
            else
                rebirthRuntime.State =
                    "Required egg ready • hatch it manually"

                setStatus(
                    "Auto Rebirth • "
                    .. tostring(required)
                    .. " ready • hatch it manually"
                )
            end
        else
            if seconds ~= nil then
                rebirthRuntime.State =
                    "Waiting " .. tostring(required)
                    .. " hatch • "
                    .. tostring(math.max(0, math.floor(seconds)))
                    .. "s"
            else
                rebirthRuntime.State = "Waiting for " .. tostring(required) .. " to hatch"
            end
        end

        return
    end

    if rebirthRuntime.WaitingEggName
        and eggNameMatches(rebirthRuntime.WaitingEggName, required) then

        if not rebirthRuntime.ManualPlacedSeen then
            rebirthRuntime.State =
                "Collected "
                .. tostring(required)
                .. " • place it manually"
            return
        end

        -- The egg was seen on the plot and has now disappeared.
        -- Give pet/inventory replication a short result window before deciding
        -- whether another copy of the required egg is needed.
        if not rebirthRuntime.ManualDisappearAt then
            rebirthRuntime.ManualDisappearAt = os.clock()
            rebirthRuntime.State = "Hatched • checking rebirth result"
            return
        end

        if os.clock() - rebirthRuntime.ManualDisappearAt < 2 then
            rebirthRuntime.State = "Hatched • checking rebirth result"
            return
        end

        rebirthRuntime.WaitingEggName = nil
        rebirthRuntime.WaitStartedAt = 0
        rebirthRuntime.ManualPlacedSeen = false
        rebirthRuntime.ManualDisappearAt = nil
    end

    rebirthRuntime.State = "Need " .. required
end

local function claimIndex()
    local main = playerGui:FindFirstChild("Main")
    local index = main and main:FindFirstChild("Index")
    local progress = index and index:FindFirstChild("PetProgress")
    local claim = progress and progress:FindFirstChild("Claim")

    if not claim then
        return false
    end

    local progLabel = progress:FindFirstChild("Progress", true)
    if progLabel and progLabel:IsA("TextLabel") then
        local a, b = progLabel.Text:match("(%d+)%s*/%s*(%d+)")
        if a and b and tonumber(a) < tonumber(b) then
            return false
        end
    end

    return activateButton(claim)
end

-- ============================================================
-- WEBHOOK
-- ============================================================

local function getRequestFunction()
    return (syn and syn.request)
        or (http and http.request)
        or http_request
        or request
end

sendWebhook = function(title, fields)
    if true then return false, "Webhook retired" end
    if not Settings.WebhookEnabled then
        return false, "Webhook is disabled"
    end

    local url = trim(Settings.WebhookURL)
    if url == "" then
        return false, "Webhook URL is blank"
    end

    local requestFn = getRequestFunction()
    if not requestFn then
        return false, "Executor has no HTTP request function"
    end

    local embedFields = {}

    for k, v in pairs(fields or {}) do
        table.insert(embedFields, {
            name = tostring(k),
            value = tostring(v),
            inline = true,
        })
    end

    local payload = {
        content = trim(Settings.WebhookPing),
        embeds = {
            {
                title = "THUMBSHUB • " .. tostring(title),
                fields = embedFields,
                footer = {
                    text = "THUMBSHUB Egg/Pet Game",
                },
                timestamp = DateTime.now():ToIsoDate(),
            }
        }
    }

    local ok, response = pcall(function()
        return requestFn({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
            Body = HttpService:JSONEncode(payload),
        })
    end)

    if not ok then
        return false, tostring(response)
    end

    local status = response and (response.StatusCode or response.Status or response.status_code)
    if status and tonumber(status) and tonumber(status) >= 400 then
        return false, "HTTP " .. tostring(status)
    end

    return true, status and ("HTTP " .. tostring(status)) or "Sent"
end

local function announceClaimedEgg(egg)
    if not Settings.WebhookEggs then
        return
    end

    local luck, luckText = getEggLuck(egg)

    sendWebhook("Egg Claimed", {
        Egg = egg and egg.Name or "Unknown",
        Mutation = egg and getEggMutation(egg) or "Unknown",
        Luck = luckText or tostring(luck),
    })
end

local function announcePet(pet)
    if not Settings.WebhookPets or not pet then
        return
    end

    task.delay(0.5, function()
        if not pet.Parent then
            return
        end

        local income = getPetIncome(pet)

        if income < (tonumber(Settings.WebhookPetMinIncome) or 0) then
            return
        end

        sendWebhook("Pet Detected", {
            Pet = pet:GetAttribute("PetName") or pet.Name,
            Income = "$" .. tostring(income) .. "/s",
            Age = getPetAge(pet),
            Weight = pet:GetAttribute("Weight") or "?",
            Mutation = getPetMutation(pet),
        })
    end)
end

-- ============================================================
-- SERVER HOP
-- ============================================================

local function hopTargetFound()
    for _, egg in ipairs(getRenderedEggs()) do
        if eggMatches(
            egg,
            Settings.HopEggNames,
            Settings.HopMutation,
            Settings.HopMinLuck
        ) then
            return egg
        end
    end
    return nil
end

function Reliability.serverHopCollectMode()
    return Settings.AutoServerHop == true
        and trim(Settings.HopEggNames) ~= ""
end

function Reliability.serverHopSelectedCount()
    return #splitCSV(Settings.HopEggNames)
end

function Reliability.getServerHopEggCandidates()
    local candidates = {}
    local _, _, root = getCharacter()

    for _, egg in ipairs(getRenderedEggs()) do
        if eggMatches(
            egg,
            Settings.HopEggNames,
            Settings.HopMutation,
            Settings.HopMinLuck
        ) then
            local prompt = getPickupPrompt(egg)
            local position = getObjectPosition(egg)

            if prompt and position then
                candidates[#candidates + 1] = {
                    Egg = egg,
                    Value = getEggPredictedValue(egg),
                    Distance =
                        root
                        and (root.Position - position).Magnitude
                        or math.huge,
                }
            end
        end
    end

    -- Grab the best selected egg first, then distance as the tiebreaker.
    table.sort(candidates, function(a, b)
        if a.Value ~= b.Value then
            return a.Value > b.Value
        end
        return a.Distance < b.Distance
    end)

    return candidates
end

function Reliability.chooseServerHopEgg()
    local candidates =
        Reliability.getServerHopEggCandidates()

    return candidates[1]
        and candidates[1].Egg
        or nil
end

function Reliability.serverHopMatchingCount()
    local count = 0

    -- Count matching rendered eggs even if their pickup prompt is still
    -- streaming. This prevents the hopper from leaving a good server simply
    -- because the interaction object appeared a moment later than the model.
    for _, egg in ipairs(getRenderedEggs()) do
        if eggMatches(
            egg,
            Settings.HopEggNames,
            Settings.HopMutation,
            Settings.HopMinLuck
        ) then
            count += 1
        end
    end

    return count
end

-- ============================================================
-- BUILD147 • SHARED SERVER EGG INDEX
-- ============================================================
-- Privacy: reports PlaceId, JobId, player counts and visible egg metadata only.
-- It never sends Player.Name, DisplayName, UserId, inventory or plot contents.
local function normalizedIndexUrl()
    local url = trim(Settings.ServerIndexUrl)

    if url == "" then
        return nil
    end

    url = url:gsub("/+$", "")

    if not url:match("^https://") then
        return nil
    end

    return url
end

local function indexRequestFunction()
    local fn =
        request
        or http_request
        or (syn and syn.request)
        or (fluxus and fluxus.request)

    return type(fn) == "function"
        and fn
        or nil
end

local function indexVisibleEggSnapshot()
    local eggs = {}
    local signatureParts = {}
    local seen = {}

    for _, egg in ipairs(getRenderedEggs()) do
        local name = tostring(getWorldEggName(egg) or "")
        local key = string.lower(trim(name))

        if key ~= "" then
            local mutation =
                tostring(getEggMutation(egg) or "None")

            -- BUILD154: getEggLuck() returns both numeric luck and display
            -- text. select(1, ...) forwards ALL remaining values, so passing it
            -- directly into tonumber() accidentally supplied the display text
            -- as tonumber's second "base" argument.
            local rawLuck =
                select(1, getEggLuck(egg))

            local luck =
                tonumber(rawLuck)
                or 0

            local compound =
                key
                .. "|"
                .. string.lower(trim(mutation))

            if not seen[compound] then
                seen[compound] = true

                eggs[#eggs + 1] = {
                    name = name,
                    mutation = mutation,
                    luck = luck,
                }

                signatureParts[#signatureParts + 1] =
                    compound
                    .. "|"
                    .. tostring(math.floor(luck))
            end
        end
    end

    table.sort(signatureParts)

    return eggs, table.concat(signatureParts, ";")
end

function Reliability.reportServerIndex(force)
    local url = normalizedIndexUrl()

    if not url then
        return false, "Index URL not configured"
    end

    local requestFn = indexRequestFunction()

    if not requestFn then
        Reliability.IndexReportSupported = false
        return false, "Executor HTTP POST unavailable"
    end

    Reliability.IndexReportSupported = true

    local eggs, signature =
        indexVisibleEggSnapshot()

    local now = os.clock()
    local heartbeat =
        math.clamp(
            tonumber(Settings.IndexReportHeartbeat) or 40,
            15,
            120
        )

    if not force
        and signature == Reliability.IndexLastSignature
        and now - (Reliability.IndexLastReportAt or 0) < heartbeat then

        return true, "unchanged"
    end

    local body = HttpService:JSONEncode({
        placeId = tostring(game.PlaceId),
        jobId = tostring(game.JobId),
        playerCount = #Players:GetPlayers(),
        maxPlayers = tonumber(Players.MaxPlayers) or 0,
        eggs = eggs,
    })

    local ok, response =
        pcall(function()
            return requestFn({
                Url = url .. "/report",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                },
                Body = body,
            })
        end)

    if not ok then
        Reliability.IndexLastError =
            tostring(response)

        return false, Reliability.IndexLastError
    end

    local code =
        response
        and tonumber(
            response.StatusCode
            or response.Status
            or response.status
        )

    if code
        and (code < 200 or code >= 300) then

        Reliability.IndexLastError =
            "HTTP " .. tostring(code)

        return false, Reliability.IndexLastError
    end

    Reliability.IndexLastSignature = signature
    Reliability.IndexLastReportAt = now
    Reliability.IndexLastError = nil

    return true, "reported"
end

local function indexSelectedEggKeys()
    local names = splitCSV(Settings.HopEggNames)
    local out = {}
    local seen = {}

    for _, name in ipairs(names) do
        local key = string.lower(trim(name))

        if key ~= ""
            and not seen[key] then

            seen[key] = true
            out[#out + 1] = key
        end
    end

    return out
end

local function indexExcludeJobs()
    local out = {
        tostring(game.JobId),
    }

    -- Avoid immediately revisiting recently attempted indexed jobs.
    for jobId, visitedAt in pairs(
        Reliability.IndexVisited
    ) do
        if os.clock() - visitedAt <= 300 then
            if #out < 9 then
                out[#out + 1] =
                    tostring(jobId)
            end
        else
            Reliability.IndexVisited[jobId] = nil
        end
    end

    return out
end

function Reliability.findIndexedServer()
    local url = normalizedIndexUrl()

    if not url then
        return nil, "Index URL not configured"
    end

    local selected = indexSelectedEggKeys()

    if #selected == 0 then
        return nil, "No indexed eggs selected"
    end

    local params = {
        "placeId="
            .. HttpService:UrlEncode(
                tostring(game.PlaceId)
            ),
        "eggs="
            .. HttpService:UrlEncode(
                table.concat(selected, "|")
            ),
        "maxAge="
            .. tostring(
                math.clamp(
                    tonumber(Settings.IndexMaxAge) or 60,
                    15,
                    180
                )
            ),
        "exclude="
            .. HttpService:UrlEncode(
                table.concat(
                    indexExcludeJobs(),
                    "|"
                )
            ),
    }

    local mutation =
        tostring(Settings.HopMutation or "Any")

    if mutation ~= ""
        and string.lower(mutation) ~= "any" then

        params[#params + 1] =
            "mutation="
            .. HttpService:UrlEncode(
                mutation
            )
    end

    local minLuck =
        tonumber(Settings.HopMinLuck) or 0

    if minLuck > 0 then
        params[#params + 1] =
            "minLuck="
            .. tostring(minLuck)
    end

    local queryUrl =
        url
        .. "/find?"
        .. table.concat(params, "&")

    local ok, raw =
        pcall(function()
            return (game :: any):HttpGet(
                queryUrl
            )
        end)

    if not ok then
        Reliability.IndexLastError =
            tostring(raw)

        return nil, Reliability.IndexLastError
    end

    local okJson, data =
        pcall(
            HttpService.JSONDecode,
            HttpService,
            raw
        )

    if not okJson
        or type(data) ~= "table" then

        Reliability.IndexLastError =
            "Index returned invalid JSON"

        return nil, Reliability.IndexLastError
    end

    if data.ok ~= true
        or type(data.server) ~= "table"
        or not data.server.jobId then

        Reliability.IndexLastResult = data
        return nil, tostring(data.reason or "No indexed match")
    end

    local result = data.server

    Reliability.IndexLastResult = result
    Reliability.IndexLastError = nil

    return result, nil
end

function Reliability.indexedHop()
    if Settings.DirectIndexedHop ~= true then
        return false, "Indexed hop disabled"
    end

    local result, err =
        Reliability.findIndexedServer()

    if not result then
        return false, err
    end

    local jobId =
        tostring(result.jobId or "")

    if jobId == ""
        or jobId == tostring(game.JobId) then

        return false, "Index returned current server"
    end

    Reliability.IndexVisited[jobId] =
        os.clock()

    local matched =
        tostring(
            result.matchedEggs
            or "selected egg"
        )

    local age =
        tonumber(result.ageSeconds)

    setStatus(
        "Indexed Hop • "
        .. matched
        .. (
            age
            and (
                " • report "
                .. string.format(
                    "%.0fs",
                    age
                )
                .. " old"
            )
            or ""
        )
    )

    local ok =
        pcall(function()
            TeleportService:TeleportToPlaceInstance(
                game.PlaceId,
                jobId,
                player
            )
        end)

    return ok, ok and nil or "Teleport request failed"
end

local function serverHop()
    local now = os.clock()

    if now - lastHopAt < (tonumber(Settings.HopDelay) or 20) then
        return false
    end

    lastHopAt = now

    -- Target detection belongs to the Auto Server Hop loop below.
    -- Keeping it out of this function prevents duplicate webhooks and
    -- stops HopStopWhenFound=false from being overridden accidentally.
    local ok, body = pcall(function()
        return (game :: any):HttpGet(
            "https://games.roblox.com/v1/games/"
            .. tostring(game.PlaceId)
            .. "/servers/Public?sortOrder=Asc&limit=100"
        )
    end)

    if not ok then
        return false
    end

    local okJson, data = pcall(HttpService.JSONDecode, HttpService, body)
    if not okJson or type(data) ~= "table" or type(data.data) ~= "table" then
        return false
    end

    local choices = {}

    for _, server in ipairs(data.data) do
        if server.id
            and server.id ~= game.JobId
            and tonumber(server.playing or 0)
                < tonumber(server.maxPlayers or 0) then

            choices[#choices + 1] = {
                Id = server.id,
                Playing = tonumber(server.playing or 0) or 0,
            }
        end
    end

    if #choices == 0 then
        return false
    end

    -- Prefer a quieter server so there is less competition for selected eggs.
    -- Randomise among the lowest few instead of always choosing one exact job.
    table.sort(choices, function(a, b)
        return a.Playing < b.Playing
    end)

    local poolSize = math.min(#choices, 8)
    local target =
        choices[math.random(1, poolSize)].Id

    setStatus(
        "Server Hop • joining a new server..."
    )

    pcall(function()
        TeleportService:TeleportToPlaceInstance(
            game.PlaceId,
            target,
            player
        )
    end)

    return true
end

-- ============================================================
-- ESP
-- ============================================================

local espFolder = Instance.new("Folder")
espFolder.Name = "THUMBSHUB_ESP"

local uiParent
if typeof(gethui) == "function" then
    local ok, hui = pcall(gethui)
    if ok and hui then
        uiParent = hui
    end
end
uiParent = uiParent or CoreGui

espFolder.Parent = uiParent

local function clearESP(className)
    for _, obj in ipairs(espFolder:GetChildren()) do
        if not className or obj:GetAttribute("ESPClass") == className then
            obj:Destroy()
        end
    end
end

local function createBillboard(target, title, subtitle, className)
    local posPart = nil

    if target:IsA("Model") then
        posPart = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
    elseif target:IsA("BasePart") then
        posPart = target
    end

    if not posPart then
        return
    end

    local adorn = Instance.new("Highlight")
    adorn.Name = "Highlight"
    adorn.Adornee = target
    adorn.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    adorn.FillTransparency = 0.75
    adorn.OutlineTransparency = 0
    adorn:SetAttribute("ESPClass", className)
    adorn.Parent = espFolder

    local bill = Instance.new("BillboardGui")
    bill.Name = "Billboard"
    bill.Adornee = posPart
    bill.Size = UDim2.fromOffset(190, 46)
    bill.StudsOffset = Vector3.new(0, 3, 0)
    bill.AlwaysOnTop = true
    bill:SetAttribute("ESPClass", className)
    bill.Parent = espFolder

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextStrokeTransparency = 0.35
    label.TextWrapped = true
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Text = tostring(title) .. "\n" .. tostring(subtitle or "")
    label.Parent = bill
end

local function refreshEggESP()
    clearESP("Egg")

    if not Settings.EggESP then
        return
    end

    for _, egg in ipairs(getRenderedEggs()) do
        local _, luckText = getEggLuck(egg)
        createBillboard(
            egg,
            getWorldEggName(egg),
            "Luck " .. luckText .. " • " .. getEggMutation(egg),
            "Egg"
        )
    end
end

local function refreshPetESP()
    clearESP("Pet")

    if not Settings.PetESP then
        return
    end

    local plots = workspace:FindFirstChild("Plots")
    if not plots then
        return
    end

    for _, plot in ipairs(plots:GetChildren()) do
        local pets = plot:FindFirstChild("Pets")
        if pets then
            for _, pet in ipairs(pets:GetChildren()) do
                local ownerId = pet:GetAttribute("OwnerUserId")
                local isMine = ownerId == player.UserId

                local show = (isMine and Settings.PetESPMyPets)
                    or ((not isMine) and Settings.PetESPOthers)

                local income = getPetIncome(pet)

                if show and income >= (tonumber(Settings.PetESPMinIncome) or 0) then
                    createBillboard(
                        pet,
                        pet:GetAttribute("PetName") or pet.Name,
                        "$" .. tostring(income) .. "/s • "
                            .. getPetMutation(pet)
                            .. " • Age " .. tostring(getPetAge(pet)),
                        "Pet"
                    )
                end
            end
        end
    end
end

connections.FPSBoostState =
    connections.FPSBoostState
    or {
        Objects = setmetatable({}, {__mode = "k"}),
        Lighting = nil,
        Terrain = nil,
    }

local function rememberFPSProperty(object, property)
    local state = connections.FPSBoostState
    local record = state.Objects[object]

    if not record then
        record = {}
        state.Objects[object] = record
    end

    if record[property] == nil then
        local ok, value =
            pcall(function()
                return object[property]
            end)

        if ok then
            record[property] = value
        end
    end
end

local function restoreFPSBoostVisuals()
    local state = connections.FPSBoostState

    if not state then
        return
    end

    for object, properties in pairs(state.Objects) do
        if object and object.Parent then
            for property, value in pairs(properties) do
                pcall(function()
                    object[property] = value
                end)
            end
        end
    end

    table.clear(state.Objects)

    if state.Lighting then
        for property, value in pairs(state.Lighting) do
            pcall(function()
                Lighting[property] = value
            end)
        end
        state.Lighting = nil
    end

    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain and state.Terrain then
        for property, value in pairs(state.Terrain) do
            pcall(function()
                terrain[property] = value
            end)
        end
        state.Terrain = nil
    end
end

local function applyFPSBoost(enabled)
    Settings.FPSBoost = enabled

    if not enabled then
        restoreFPSBoostVisuals()
        return
    end

    local state = connections.FPSBoostState

    if not state.Lighting then
        state.Lighting = {
            GlobalShadows = Lighting.GlobalShadows,
            EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        }
    end

    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
    end)

    local terrain = workspace:FindFirstChildOfClass("Terrain")

    if terrain and not state.Terrain then
        state.Terrain = {
            WaterWaveSize = terrain.WaterWaveSize,
            WaterWaveSpeed = terrain.WaterWaveSpeed,
            WaterReflectance = terrain.WaterReflectance,
        }

        pcall(function()
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
        end)
    end

    local descendants = workspace:GetDescendants()

    for index, obj in ipairs(descendants) do
        if obj:IsA("ParticleEmitter")
            or obj:IsA("Trail")
            or obj:IsA("Beam")
            or obj:IsA("Smoke")
            or obj:IsA("Fire")
            or obj:IsA("Sparkles")
            or obj:IsA("Highlight") then

            rememberFPSProperty(obj, "Enabled")

            pcall(function()
                obj.Enabled = false
            end)

        elseif obj:IsA("BasePart") then
            rememberFPSProperty(obj, "CastShadow")

            pcall(function()
                obj.CastShadow = false
            end)
        end

        -- Do not freeze the client while applying the boost to a large map.
        if index % 500 == 0 then
            task.wait()
        end
    end

    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect") then
            rememberFPSProperty(obj, "Enabled")

            pcall(function()
                obj.Enabled = false
            end)
        end
    end
end

-- ============================================================
-- LOCAL PET VISIBILITY
-- ============================================================
connections.PetVisibility =
    connections.PetVisibility
    or {
        Original = setmetatable({}, {__mode = "k"}),
        RefreshQueued = false,
    }

local function petHideEnabled()
    return Settings.HideAllPets
        or Settings.HideMyPets
        or Settings.HideOtherPets
end

local function isMyPetModel(pet)
    if not pet then
        return false
    end

    local ownerId =
        tonumber(
            pet:GetAttribute("OwnerUserId")
        )

    if ownerId == player.UserId then
        return true
    end

    local ownPlot = getOwnPlot()

    return ownPlot ~= nil
        and pet:IsDescendantOf(ownPlot)
end

local function rememberPetVisual(object, property)
    local state = connections.PetVisibility
    local record = state.Original[object]

    if not record then
        record = {}
        state.Original[object] = record
    end

    if record[property] == nil then
        local ok, value =
            pcall(function()
                return object[property]
            end)

        if ok then
            record[property] = value
        end
    end
end

local function hidePetModelLocal(pet)
    if not pet then
        return
    end

    for _, object in ipairs(pet:GetDescendants()) do
        if object:IsA("BasePart") then
            rememberPetVisual(
                object,
                "LocalTransparencyModifier"
            )

            pcall(function()
                object.LocalTransparencyModifier = 1
            end)

        elseif object:IsA("ParticleEmitter")
            or object:IsA("Trail")
            or object:IsA("Beam")
            or object:IsA("Smoke")
            or object:IsA("Fire")
            or object:IsA("Sparkles")
            or object:IsA("Highlight")
            or object:IsA("BillboardGui")
            or object:IsA("SurfaceGui") then

            rememberPetVisual(
                object,
                "Enabled"
            )

            pcall(function()
                object.Enabled = false
            end)
        end
    end
end

local function restoreHiddenPets()
    local state = connections.PetVisibility

    for object, properties in pairs(state.Original) do
        if object and object.Parent then
            for property, value in pairs(properties) do
                pcall(function()
                    object[property] = value
                end)
            end
        end
    end

    table.clear(state.Original)
end

local function refreshPetVisibility()
    restoreHiddenPets()

    if not petHideEnabled() then
        return
    end

    local plots = workspace:FindFirstChild("Plots")

    if not plots then
        return
    end

    for _, plot in ipairs(plots:GetChildren()) do
        local pets = plot:FindFirstChild("Pets")

        if pets then
            for _, pet in ipairs(pets:GetChildren()) do
                local mine = isMyPetModel(pet)

                local shouldHide =
                    Settings.HideAllPets
                    or (
                        mine
                        and Settings.HideMyPets
                    )
                    or (
                        not mine
                        and Settings.HideOtherPets
                    )

                if shouldHide then
                    hidePetModelLocal(pet)
                end
            end
        end
    end
end

local function queuePetVisibilityRefresh()
    local state = connections.PetVisibility

    if state.RefreshQueued then
        return
    end

    state.RefreshQueued = true

    task.delay(
        Settings.HubPerformanceMode
            and 0.35
            or 0.12,
        function()
            state.RefreshQueued = false

            if alive and petHideEnabled() then
                refreshPetVisibility()
            end
        end
    )
end

-- ============================================================
-- LOCAL PLAYER NAME MASK
-- ============================================================
connections.NameMask =
    connections.NameMask
    or {
        Original = setmetatable({}, {__mode = "k"}),
        Watchers = setmetatable({}, {__mode = "k"}),
        Applying = false,
        Humanoid = nil,
        HumanoidDisplayName = nil,
        HumanoidDisplayDistanceType = nil,
        OverheadGui = nil,
    }

-- BUILD154:
-- Keep every helper as a method on connections.NameMask instead of declaring
-- more top-level locals. This master file is already very close to Luau's
-- active-local/register ceiling.
connections.NameMask.EscapePattern = function(value)
    return tostring(value or ""):gsub(
        "([^%w])",
        "%%%1"
    )
end

connections.NameMask.MaskedText = function(textValue)
    local original =
        tostring(textValue or "")

    local username =
        tostring(player.Name or "")

    local displayName =
        tostring(player.DisplayName or "")

    local lowerOriginal =
        string.lower(original)

    local lowerUsername =
        string.lower(username)

    local lowerDisplay =
        string.lower(displayName)

    if lowerUsername ~= ""
        and lowerOriginal == lowerUsername then

        return "ThumbsHub"
    end

    if lowerDisplay ~= ""
        and lowerOriginal == lowerDisplay then

        return "ThumbsHub"
    end

    if lowerUsername ~= ""
        and lowerOriginal == ("@" .. lowerUsername) then

        return "@ThumbsHub"
    end

    local value = original

    if username ~= ""
        and lowerOriginal:find(
            lowerUsername,
            1,
            true
        ) then

        value =
            value:gsub(
                connections.NameMask.EscapePattern(username),
                "ThumbsHub"
            )
    end

    if displayName ~= ""
        and string.lower(value):find(
            lowerDisplay,
            1,
            true
        ) then

        value =
            value:gsub(
                connections.NameMask.EscapePattern(displayName),
                "ThumbsHub"
            )
    end

    return value
end

connections.NameMask.MaskObject = function(object)
    if not Settings.HideNames then
        return
    end

    if not (
        object:IsA("TextLabel")
        or object:IsA("TextButton")
        or object:IsA("TextBox")
    ) then
        return
    end

    local state = connections.NameMask

    if state.Applying then
        return
    end

    local ok, current =
        pcall(function()
            return object.Text
        end)

    if not ok then
        return
    end

    local masked =
        state.MaskedText(current)

    if masked == current then
        return
    end

    if state.Original[object] == nil then
        state.Original[object] = current
    end

    state.Applying = true

    pcall(function()
        object.Text = masked
    end)

    state.Applying = false

    if not state.Watchers[object] then
        local okConnection, connection =
            pcall(function()
                return object:GetPropertyChangedSignal(
                    "Text"
                ):Connect(function()
                    if not alive
                        or not Settings.HideNames then
                        return
                    end

                    task.defer(function()
                        if alive
                            and Settings.HideNames
                            and object
                            and object.Parent then

                            connections.NameMask.MaskObject(
                                object
                            )
                        end
                    end)
                end)
            end)

        if okConnection and connection then
            state.Watchers[object] = connection
        end
    end
end

connections.NameMask.EnsureOverhead = function()
    if not Settings.HideNames then
        return
    end

    local state = connections.NameMask
    local character = player.Character

    if not character then
        return
    end

    local head =
        character:FindFirstChild("Head")

    local humanoid =
        character:FindFirstChildOfClass(
            "Humanoid"
        )

    if not head or not humanoid then
        return
    end

    if state.Humanoid ~= humanoid then
        state.Humanoid = humanoid
        state.HumanoidDisplayName =
            humanoid.DisplayName

        state.HumanoidDisplayDistanceType =
            humanoid.DisplayDistanceType
    end

    pcall(function()
        humanoid.DisplayName = "ThumbsHub"
        humanoid.DisplayDistanceType =
            Enum.HumanoidDisplayDistanceType.None
    end)

    local existing =
        head:FindFirstChild(
            "ThumbsHub_LocalNameplate"
        )

    if existing
        and existing:IsA("BillboardGui") then

        state.OverheadGui = existing
        return
    end

    if state.OverheadGui
        and state.OverheadGui.Parent then

        pcall(function()
            state.OverheadGui:Destroy()
        end)
    end

    local billboard =
        Instance.new("BillboardGui")

    billboard.Name =
        "ThumbsHub_LocalNameplate"

    billboard.Adornee = head
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 250
    billboard.Size =
        UDim2.fromOffset(
            220,
            42
        )

    billboard.StudsOffset =
        Vector3.new(
            0,
            2.85,
            0
        )

    billboard.Parent = head

    local label =
        Instance.new("TextLabel")

    label.Name = "Name"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.Text = "ThumbsHub"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Parent = billboard

    local sizeConstraint =
        Instance.new("UITextSizeConstraint")

    sizeConstraint.MaxTextSize = 22
    sizeConstraint.MinTextSize = 14
    sizeConstraint.Parent = label

    state.OverheadGui = billboard
end

connections.NameMask.ScanContainer = function(container)
    if not container then
        return
    end

    for _, object in ipairs(
        container:GetDescendants()
    ) do
        connections.NameMask.MaskObject(
            object
        )
    end
end

connections.NameMask.Refresh = function()
    if not Settings.HideNames then
        return
    end

    connections.NameMask.ScanContainer(
        CoreGui
    )

    for _, object in ipairs(
        playerGui:GetDescendants()
    ) do
        local isThumbsHubUI =
            object:FindFirstAncestor(
                "ThumbsHub"
            )
            ~= nil

        if not isThumbsHubUI then
            connections.NameMask.MaskObject(
                object
            )
        end
    end

    connections.NameMask.EnsureOverhead()
end

connections.NameMask.Restore = function()
    local state = connections.NameMask

    for object, connection in pairs(
        state.Watchers
    ) do
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end

        state.Watchers[object] = nil
    end

    for object, original in pairs(
        state.Original
    ) do
        if object and object.Parent then
            pcall(function()
                object.Text = original
            end)
        end
    end

    table.clear(state.Original)

    if state.OverheadGui
        and state.OverheadGui.Parent then

        pcall(function()
            state.OverheadGui:Destroy()
        end)
    end

    state.OverheadGui = nil

    if state.Humanoid
        and state.Humanoid.Parent then

        if state.HumanoidDisplayName then
            pcall(function()
                state.Humanoid.DisplayName =
                    state.HumanoidDisplayName
            end)
        end

        if state.HumanoidDisplayDistanceType then
            pcall(function()
                state.Humanoid.DisplayDistanceType =
                    state.HumanoidDisplayDistanceType
            end)
        end
    end

    state.Humanoid = nil
    state.HumanoidDisplayName = nil
    state.HumanoidDisplayDistanceType = nil
end

connections.NameMask.Apply = function(enabled)
    Settings.HideNames = enabled

    if enabled then
        connections.NameMask.Refresh()
    else
        connections.NameMask.Restore()
    end
end

local rebirthUILabels = {}

local function buildThumbsHubUI()
-- ============================================================
-- UI - THUMBSHUB BUILD 67 • TRUE SLAYERS-STYLE EGG UI + SYNTAX FIX
-- ============================================================

local oldGui = uiParent:FindFirstChild("ThumbsHub") or uiParent:FindFirstChild("THUMBSHUB_EGG_V1")
if oldGui then
    oldGui:Destroy()
end

-- BUILD 66:
-- This is the actual visual conversion to the Slayers-style shell.
-- First launch starts Carbon + Orange, then the normal theme/accent pickers
-- remain fully available in Settings.
if Settings.EggSlayersShellV1 ~= true then
    Settings.UITheme = "Carbon"
    Settings.UIAccent = "Orange"
    Settings.EggSlayersShellV1 = true
    pcall(saveConfig)
end

local THEME_PRESETS = {
    Midnight = {
        Background = {11, 10, 10}, Sidebar = {14, 13, 13}, Header = {17, 15, 14},
        Panel = {20, 18, 17}, Panel2 = {27, 24, 22}, Element = {35, 31, 29},
        Hover = {46, 37, 32}, Outline = {73, 55, 45}, Text = {242, 239, 236},
        Dim = {158, 150, 145}, Muted = {112, 105, 101},
    },
    Carbon = {
        Background = {9, 10, 12}, Sidebar = {12, 13, 16}, Header = {15, 16, 20},
        Panel = {18, 20, 24}, Panel2 = {25, 28, 33}, Element = {32, 36, 42},
        Hover = {43, 48, 56}, Outline = {66, 72, 82}, Text = {241, 243, 246},
        Dim = {157, 163, 173}, Muted = {105, 111, 122},
    },
    Ocean = {
        Background = {7, 14, 19}, Sidebar = {9, 18, 25}, Header = {11, 22, 30},
        Panel = {13, 27, 36}, Panel2 = {18, 36, 47}, Element = {24, 46, 59},
        Hover = {31, 59, 74}, Outline = {43, 78, 96}, Text = {235, 245, 249},
        Dim = {147, 177, 188}, Muted = {92, 126, 138},
    },
    Violet = {
        Background = {13, 10, 18}, Sidebar = {17, 13, 23}, Header = {21, 16, 29},
        Panel = {25, 19, 35}, Panel2 = {34, 26, 46}, Element = {44, 34, 58},
        Hover = {57, 43, 74}, Outline = {81, 61, 103}, Text = {245, 239, 250},
        Dim = {171, 156, 184}, Muted = {119, 102, 132},
    },
    Emerald = {
        Background = {7, 15, 13}, Sidebar = {9, 20, 17}, Header = {11, 25, 21},
        Panel = {14, 30, 25}, Panel2 = {19, 40, 33}, Element = {25, 51, 42},
        Hover = {32, 65, 53}, Outline = {47, 88, 73}, Text = {236, 247, 243},
        Dim = {148, 181, 169}, Muted = {96, 131, 118},
    },
}

local ACCENT_PRESETS = {
    Orange = {245, 118, 42},
    Blue = {72, 145, 255},
    Purple = {166, 102, 255},
    Pink = {244, 103, 170},
    Green = {70, 210, 139},
    Red = {235, 83, 83},
    Cyan = {65, 205, 224},
    Yellow = {238, 193, 67},
}

local function rgbTriplet(v)
    return Color3.fromRGB(v[1], v[2], v[3])
end

local function buildThemePalette(themeName, accentName)
    local theme = THEME_PRESETS[themeName] or THEME_PRESETS.Midnight
    local accent = rgbTriplet(ACCENT_PRESETS[accentName] or ACCENT_PRESETS.Orange)
    local background = rgbTriplet(theme.Background)

    return {
        Background = background,
        Sidebar = rgbTriplet(theme.Sidebar),
        Header = rgbTriplet(theme.Header),
        Panel = rgbTriplet(theme.Panel),
        Panel2 = rgbTriplet(theme.Panel2),
        Element = rgbTriplet(theme.Element),
        Hover = rgbTriplet(theme.Hover),
        Outline = rgbTriplet(theme.Outline),
        Accent = accent,
        AccentSoft = accent:Lerp(background, 0.55),
        AccentDim = accent:Lerp(background, 0.70),
        Text = rgbTriplet(theme.Text),
        Dim = rgbTriplet(theme.Dim),
        Muted = rgbTriplet(theme.Muted),
        Success = Color3.fromRGB(86, 206, 133),
        Risky = Color3.fromRGB(227, 83, 83),
    }
end

local COLORS = buildThemePalette(Settings.UITheme, Settings.UIAccent)

local FEATURE_TOOLTIPS = {
    ["Auto Farm Eggs"] = "Finds a suitable world egg, grabs it and returns to your plot. Auto Rebirth eggs are placed automatically and then watched until hatch.",
    ["Farm Method"] = "Stable uses timed plot entry. Underground Noclip fast-tweens to the egg, then fast-tweens the carried egg back into your plot. The basket must clear before farming another egg.",
    ["Underground Depth"] = "How far below the map layer the underground lane travels.",
    ["Tween Speed"] = "Controls how fast THUMBSHUB travels toward the selected world egg in Stable mode.",
    ["Return Tween Speed"] = "Controls how fast THUMBSHUB returns the carried egg to your plot.",
    ["Tween Air Height"] = "Adds height to the fast tween path so the character travels above the ground.",
    ["Plot Edge Padding"] = "How far outside your plot THUMBSHUB stops before pausing for manual nest placement.",
    ["Claim Delay"] = "Small delay before activating the egg pickup prompt.",
    ["Auto Hatch Eggs"] = "Automatically activates hatch prompts for eggs on your plot when they are ready.",
    ["Hover / Nearby Hatch Reveal"] = "Shows the exact server-confirmed pet result as soon as the Hatch result reaches your client, usually before the normal reveal animation finishes.",
    ["Smart Egg Targeting"] = "Ranks visible eggs using value, mutation, travel time and your filters instead of taking the first egg found.",
    ["Best Egg First"] = "Prefers higher-value eggs when several valid targets are available.",
    ["Relax Filters If Nothing Matches"] = "Temporarily considers other visible eggs when your selected filters would otherwise leave the farm idle.",
    ["Count Mutation Value"] = "Includes mutation multipliers when estimating which egg is more valuable.",
    ["Smart Top % Of Visible Eggs"] = "Limits smart targeting to the strongest percentage of visible candidate eggs before distance/ETA ranking.",
    ["Max Egg Distance (0 = Unlimited)"] = "Ignores valid eggs farther than this distance. Set to 0 for no distance limit.",
    ["Skip Eggs By Timer Estimate"] = "Skips eggs that are predicted to break before THUMBSHUB can reach them.",
    ["Arrive With"] = "Stable mode targets this many seconds remaining when entering the ranch. Underground Noclip returns immediately after pickup.",
    ["Mutation To Farm"] = "Dropdown for the exact mutation you want. A specific mutation is strict and will never fall back to normal/other mutations.",
    ["Egg Filter"] = "Choose the exact egg to farm, or select Any Egg.",
    ["Minimum Egg Luck"] = "Only targets eggs whose known luck value is at least this amount.",
    ["Auto Sell Basket Before Farm"] = "Attempts to use a visible basket sell prompt before continuing the farm.",
    ["Sell Basket Only When Full"] = "Only attempts basket selling when the basket has reached its known capacity.",
    ["Auto Place Best Pets"] = "Automatically tries to place the strongest available pets using confirmed game interactions.",
    ["Auto Feed Best Pet"] = "Automatically feeds the best available owned pet with the selected food.",
    ["Auto Feed Above $/s"] = "Feeds owned pets whose income is at or above the selected minimum.",
    ["Auto Feed Above Age"] = "Feeds owned pets whose age is at or above the selected minimum.",
    ["Auto Feed By Base Rarity"] = "Feeds pets that meet the selected base rarity threshold.",
    ["Auto Buy Radar"] = "Automatically buys the selected radar when the confirmed shop interaction is available.",
    ["Auto Use Radar"] = "Automatically uses the selected radar after it is available.",
    ["Auto Buy Food"] = "Automatically buys the selected food using the confirmed shop interaction.",
    ["Auto Buy Hatch Luck"] = "Automatically resolves and activates the current Hatch Luck purchase control. The resolver is cached to reduce lag and survives common UI hierarchy changes.",
    ["Hatch Luck Mode"] = "Choose whether hatch luck buys one upgrade at a time or uses the game's Buy Max option.",
    ["Auto Unlock Nests"] = "Automatically attempts to unlock your next nest when the confirmed unlock interaction is available.",
    ["Auto Rebirth"] = "Detects the required pet, farms the mapped/discovery egg, places it on your plot, pauses for that egg to hatch, then continues or rebirths automatically.",
    ["Rebirth Egg Override"] = "Optional one-time teaching value. If Auto Rebirth cannot map the required pet to an egg, enter the egg here once; THUMBSHUB saves that pet→egg mapping in your config.",
    ["Auto Ride Best Pet"] = "Automatically rides your best detected pet.",
    ["Auto Claim Index Rewards"] = "Automatically claims available index rewards using the confirmed claim button.",
    ["Egg ESP"] = "Highlights world eggs so they are easier to see while farming.",
    ["Pet ESP"] = "Highlights detected pets and shows useful information about them.",
    ["My Pets"] = "Includes your own pets in Pet ESP.",
    ["Other Players"] = "Includes pets owned by other players in Pet ESP.",
    ["FPS Boost"] = "Reduces selected visual effects to improve frame rate.",
    ["Webhook Enabled"] = "Enables Discord webhook messages for the alert types you turn on.",
    ["Webhook URL"] = "The Discord webhook endpoint that receives THUMBSHUB alerts.",
    ["Discord Ping Text"] = "Optional text such as a Discord mention that is included with webhook alerts.",
    ["Claimed Egg Alerts"] = "Sends a webhook when THUMBSHUB confirms an egg pickup.",
    ["Hatched / Pet Alerts"] = "Sends webhook information for detected hatch or pet events supported by this build.",
    ["Weather Forecast"] = "Shows the current weather, live countdown and natural next-roll probabilities. It does not claim to know an exact server-only next roll.",
    ["Weather Started Alerts"] = "Sends a webhook when a supported weather-start event is detected.",
    ["Rebirth Completed Alerts"] = "Sends a Discord webhook after Auto Rebirth confirms that a rebirth completed.",
    ["Auto Server Hop"] = "Collects selected eggs, then searches the THUMBSHUB shared live index for another server recently reporting those exact eggs.",
    ["Stop When Found"] = "Turns Auto Server Hop off once a matching target is found in the current server.",
    ["Hop Delay"] = "How long THUMBSHUB waits between automatic server-hop attempts.",
    ["Egg Names"] = "Legacy Server Hop egg names.",
    ["Eggs To Collect"] = "Multi-select the exact eggs to collect in each server before THUMBSHUB hops and repeats.",
    ["Mutation"] = "Mutation required by the Server Hop hunt filter.",
    ["Watermark / Footer"] = "Shows or hides the small THUMBSHUB footer text.",
    ["Draggable Window"] = "Allows the whole THUMBSHUB window to be dragged with the top bar.",
    ["Auto Scale To Screen"] = "Automatically scales the interface down when the game window is smaller.",
    ["UI Scale"] = "Manually changes the overall THUMBSHUB interface size.",
    ["Window Glow"] = "Enables the accent-colour outline/glow around the main THUMBSHUB window.",
    ["UI Theme"] = "Changes the full THUMBSHUB background/panel theme instantly and saves it to your config.",
    ["Accent Colour"] = "Changes the THUMBSHUB accent colour used for highlights, toggles, scrollbars and glow.",
    ["Menu Toggle Key"] = "The keyboard key used to completely hide or reopen THUMBSHUB.",
    ["Anti AFK"] = "Keeps the session active using the hub's anti-idle routine.",
    ["Auto Reconnect"] = "Attempts to reconnect after supported disconnect situations.",
}

local gui = Instance.new("ScreenGui")
gui.Name = "ThumbsHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = uiParent

local uiScale = Instance.new("UIScale")
uiScale.Name = "AutoScale"
uiScale.Parent = gui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(920, 570)
main.Position = UDim2.new(0.5, -460, 0.5, -285)
main.BackgroundColor3 = COLORS.Background
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 13)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Name = "WindowGlow"
mainStroke.Color = COLORS.Accent
mainStroke.Transparency = Settings.UIWindowGlow and 0.28 or 0.78
mainStroke.Thickness = 1.2
mainStroke.Parent = main

local slayersAccentLine = Instance.new("Frame")
slayersAccentLine.Name = "SlayersAccentLine"
slayersAccentLine.Size = UDim2.new(1, -24, 0, 2)
slayersAccentLine.Position = UDim2.fromOffset(12, 0)
slayersAccentLine.BackgroundColor3 = COLORS.Accent
slayersAccentLine.BorderSizePixel = 0
slayersAccentLine.Parent = main

local slayersAccentCorner = Instance.new("UICorner")
slayersAccentCorner.CornerRadius = UDim.new(1, 0)
slayersAccentCorner.Parent = slayersAccentLine

local hubTitle = Instance.new("TextLabel")
hubTitle.Name = "HubTitle"
hubTitle.Position = UDim2.fromOffset(22, 12)
hubTitle.Size = UDim2.fromOffset(170, 27)
hubTitle.BackgroundTransparency = 1
hubTitle.Font = Enum.Font.GothamBold
hubTitle.TextSize = 20
hubTitle.TextColor3 = COLORS.Text
hubTitle.TextXAlignment = Enum.TextXAlignment.Left
hubTitle.Text = "ThumbsHub"
hubTitle.Parent = main

local hubSubtitle = Instance.new("TextLabel")
hubSubtitle.Name = "HubSubtitle"
hubSubtitle.Position = UDim2.fromOffset(22, 40)
hubSubtitle.Size = UDim2.fromOffset(190, 18)
hubSubtitle.BackgroundTransparency = 1
hubSubtitle.Font = Enum.Font.Gotham
hubSubtitle.TextSize = 10
hubSubtitle.TextColor3 = COLORS.Dim
hubSubtitle.TextXAlignment = Enum.TextXAlignment.Left
hubSubtitle.Text = "Egg / Pet Automation"
hubSubtitle.Parent = main

-- Instant Hatch Reveal popup. Kept inside the hub ScreenGui so unload/cleanup
-- automatically removes it with the rest of THUMBSHUB.
connections.HatchReveal.Popup = Instance.new("Frame")
connections.HatchReveal.Popup.Name = "InstantHatchReveal"
connections.HatchReveal.Popup.Size = UDim2.fromOffset(390, 184)
connections.HatchReveal.Popup.Position = UDim2.new(0.5, -195, 0, 18)
connections.HatchReveal.Popup.BackgroundColor3 = COLORS.Panel
connections.HatchReveal.Popup.BorderSizePixel = 0
connections.HatchReveal.Popup.Visible = false
connections.HatchReveal.Popup.ZIndex = 80
connections.HatchReveal.Popup.Parent = gui

connections.HatchReveal.PopupCorner = Instance.new("UICorner")
connections.HatchReveal.PopupCorner.CornerRadius = UDim.new(0, 12)
connections.HatchReveal.PopupCorner.Parent = connections.HatchReveal.Popup

connections.HatchReveal.PopupStroke = Instance.new("UIStroke")
connections.HatchReveal.PopupStroke.Color = COLORS.Accent
connections.HatchReveal.PopupStroke.Transparency = 0.12
connections.HatchReveal.PopupStroke.Thickness = 1.4
connections.HatchReveal.PopupStroke.Parent = connections.HatchReveal.Popup

connections.HatchReveal.PopupTitle = Instance.new("TextLabel")
connections.HatchReveal.PopupTitle.Position = UDim2.fromOffset(14, 10)
connections.HatchReveal.PopupTitle.Size = UDim2.new(1, -28, 0, 24)
connections.HatchReveal.PopupTitle.BackgroundTransparency = 1
connections.HatchReveal.PopupTitle.Font = Enum.Font.GothamBold
connections.HatchReveal.PopupTitle.TextSize = 11
connections.HatchReveal.PopupTitle.TextColor3 = COLORS.Dim
connections.HatchReveal.PopupTitle.TextXAlignment = Enum.TextXAlignment.Left
connections.HatchReveal.PopupTitle.Text = "THUMBSHUB • INSTANT HATCH REVEAL"
connections.HatchReveal.PopupTitle.ZIndex = 81
connections.HatchReveal.PopupTitle.Parent = connections.HatchReveal.Popup

connections.HatchReveal.PopupPet = Instance.new("TextLabel")
connections.HatchReveal.PopupPet.Position = UDim2.fromOffset(14, 36)
connections.HatchReveal.PopupPet.Size = UDim2.new(1, -28, 0, 34)
connections.HatchReveal.PopupPet.BackgroundTransparency = 1
connections.HatchReveal.PopupPet.Font = Enum.Font.GothamBold
connections.HatchReveal.PopupPet.TextSize = 24
connections.HatchReveal.PopupPet.TextColor3 = COLORS.Accent
connections.HatchReveal.PopupPet.TextXAlignment = Enum.TextXAlignment.Left
connections.HatchReveal.PopupPet.Text = "Pet"
connections.HatchReveal.PopupPet.ZIndex = 81
connections.HatchReveal.PopupPet.Parent = connections.HatchReveal.Popup

connections.HatchReveal.PopupDetails = Instance.new("TextLabel")
connections.HatchReveal.PopupDetails.Position = UDim2.fromOffset(14, 76)
connections.HatchReveal.PopupDetails.Size = UDim2.new(1, -28, 1, -88)
connections.HatchReveal.PopupDetails.BackgroundTransparency = 1
connections.HatchReveal.PopupDetails.Font = Enum.Font.Gotham
connections.HatchReveal.PopupDetails.TextSize = 10
connections.HatchReveal.PopupDetails.TextColor3 = COLORS.Text
connections.HatchReveal.PopupDetails.TextWrapped = true
connections.HatchReveal.PopupDetails.TextXAlignment = Enum.TextXAlignment.Left
connections.HatchReveal.PopupDetails.TextYAlignment = Enum.TextYAlignment.Top
connections.HatchReveal.PopupDetails.Text = ""
connections.HatchReveal.PopupDetails.ZIndex = 81
connections.HatchReveal.PopupDetails.Parent = connections.HatchReveal.Popup

function connections.HatchReveal.Refresh()
    local result = connections.HatchReveal.LastResult

    if not result or not connections.HatchReveal.ContextVisible then
        for _, label in pairs(connections.HatchReveal.Labels) do
            if label and label.Parent then
                label.Text = "Hover or approach the egg"
            end
        end
        return
    end

    if connections.HatchReveal.Labels.Pet and connections.HatchReveal.Labels.Pet.Parent then
        connections.HatchReveal.Labels.Pet.Text = tostring(result.PetName or "Unknown")
    end

    if connections.HatchReveal.Labels.Egg and connections.HatchReveal.Labels.Egg.Parent then
        connections.HatchReveal.Labels.Egg.Text = tostring(result.EggName or "Unknown")
    end

    if connections.HatchReveal.Labels.Mutation and connections.HatchReveal.Labels.Mutation.Parent then
        local mutationText = tostring(result.Mutation or "None")

        if result.SpawnMutation then
            mutationText = mutationText .. " + " .. tostring(result.SpawnMutation)
        end

        connections.HatchReveal.Labels.Mutation.Text = mutationText
    end

    if connections.HatchReveal.Labels.Weight and connections.HatchReveal.Labels.Weight.Parent then
        connections.HatchReveal.Labels.Weight.Text = tostring(result.Weight or "N/A")
    end

    if connections.HatchReveal.Labels.Luck and connections.HatchReveal.Labels.Luck.Parent then
        connections.HatchReveal.Labels.Luck.Text = connections.HatchReveal.FormatNumber(result.Luck)
    end

    if connections.HatchReveal.Labels.Chance and connections.HatchReveal.Labels.Chance.Parent then
        connections.HatchReveal.Labels.Chance.Text = tostring(result.Chance or "N/A")
    end
end

function connections.HatchReveal.HidePopup()
    connections.HatchReveal.PopupToken += 1

    if connections.HatchReveal.Popup then
        connections.HatchReveal.Popup.Visible = false
    end
end

function connections.HatchReveal.ShowPopup()
    local result = connections.HatchReveal.LastResult

    if not Settings.InstantHatchReveal or not connections.HatchReveal.ContextVisible or not result or not connections.HatchReveal.Popup then
        return
    end

    connections.HatchReveal.PopupToken += 1
    
    connections.HatchReveal.PopupPet.Text = tostring(result.PetName or "Unknown Pet")

    local details = {
        "Egg: " .. tostring(result.EggName or "Unknown"),
        "Chance: " .. tostring(result.Chance or "N/A"),
        "Weight: " .. tostring(result.Weight or "N/A"),
        "Luck: " .. connections.HatchReveal.FormatNumber(result.Luck),
    }

    if result.Mutation then
        table.insert(details, "Mutation: " .. tostring(result.Mutation))
    end

    if result.SpawnMutation then
        table.insert(details, "Spawn Mutation: " .. tostring(result.SpawnMutation))
    end

    connections.HatchReveal.PopupDetails.Text = table.concat(details, "\n")
    connections.HatchReveal.Popup.Visible = true
    connections.HatchReveal.Popup.Position = UDim2.new(0.5, -195, 0, 8)
    connections.HatchReveal.Popup.BackgroundTransparency = 0.08

end

-- Cache source positions BEFORE the hatch event removes the egg model.
connections.HatchReveal.Locations = {}
connections.HatchReveal.Mouse = player:GetMouse()
function connections.HatchReveal.UpdateContext()
    local state = connections.HatchReveal
    local now = os.clock()
    local plot = getOwnPlot()
    local eggs = plot and plot:FindFirstChild("Eggs")
    if eggs then
        for _, egg in ipairs(eggs:GetChildren()) do
            local key = tostring(egg:GetAttribute("EggKey") or egg.Name)
            local position = getObjectPosition(egg)
            if position then state.Locations[key] = {Model = egg, Position = position, At = now} end
        end
    end
    for key, location in pairs(state.Locations) do
        if now - location.At > 30 then state.Locations[key] = nil end
    end
    local result = state.LastResult
    local visible = false
    if Settings.InstantHatchReveal and result and now - result.ReceivedAt <= 30 then
        local source = result.SourceModel
        local target = state.Mouse.Target
        local _, hum, root = getCharacter()
        local hovered = source and source.Parent and target and (target == source or target:IsDescendantOf(source))
        local nearby = root and hum and hum.Health > 0 and result.SourcePosition
            and (root.Position - result.SourcePosition).Magnitude <= math.clamp(tonumber(Settings.HatchRevealRadius) or 12, 3, 40)
        visible = (hovered or nearby) and true or false
    end
    state.ContextVisible = visible
    state.Refresh()
    if visible then state.ShowPopup() else state.HidePopup() end
end

local tooltip = Instance.new("Frame")
tooltip.Name = "FeatureTooltip"
tooltip.Size = UDim2.fromOffset(300, 0)
tooltip.AutomaticSize = Enum.AutomaticSize.Y
tooltip.BackgroundColor3 = Color3.fromRGB(15, 13, 12)
tooltip.BorderSizePixel = 0
tooltip.Visible = false
tooltip.ZIndex = 100
tooltip.Parent = main

local tooltipCorner = Instance.new("UICorner")
tooltipCorner.CornerRadius = UDim.new(0, 9)
tooltipCorner.Parent = tooltip

local tooltipStroke = Instance.new("UIStroke")
tooltipStroke.Color = COLORS.Accent
tooltipStroke.Transparency = 0.28
tooltipStroke.Thickness = 1
tooltipStroke.Parent = tooltip

local tooltipText = Instance.new("TextLabel")
tooltipText.Size = UDim2.new(1, -22, 0, 0)
tooltipText.AutomaticSize = Enum.AutomaticSize.Y
tooltipText.Position = UDim2.fromOffset(11, 9)
tooltipText.BackgroundTransparency = 1
tooltipText.Font = Enum.Font.Gotham
tooltipText.TextSize = 10
tooltipText.TextColor3 = COLORS.Text
tooltipText.TextWrapped = true
tooltipText.TextXAlignment = Enum.TextXAlignment.Left
tooltipText.TextYAlignment = Enum.TextYAlignment.Top
tooltipText.ZIndex = 101
tooltipText.Parent = tooltip

local tooltipBottomPad = Instance.new("UIPadding")
tooltipBottomPad.PaddingBottom = UDim.new(0, 9)
tooltipBottomPad.Parent = tooltip

local tooltipTarget = nil

local function hideTooltip(target)
    if target == nil or tooltipTarget == target then
        tooltipTarget = nil
        tooltip.Visible = false
    end
end

local function showTooltip(target, titleText, description)
    if not target or not description or description == "" then
        return
    end

    tooltipTarget = target
    tooltipText.Text = tostring(titleText) .. "\n" .. tostring(description)
    tooltip.Visible = true

    local mouseX, mouseY = 0, 0

    local okMouse, mouseLocation = pcall(function()
        return UserInputService:GetMouseLocation()
    end)

    if okMouse and mouseLocation then
        mouseX = mouseLocation.X
        mouseY = mouseLocation.Y
    else
        local legacyMouse = player:GetMouse()
        mouseX = legacyMouse.X
        mouseY = legacyMouse.Y
    end

    local mainAbs = main.AbsolutePosition
    local x = mouseX - mainAbs.X + 14
    local y = mouseY - mainAbs.Y + 14

    local estimatedW = 300
    local estimatedH = 72

    x = math.clamp(x, 8, math.max(8, main.AbsoluteSize.X - estimatedW - 8))
    y = math.clamp(y, 8, math.max(8, main.AbsoluteSize.Y - estimatedH - 8))

    tooltip.Position = UDim2.fromOffset(x, y)
end

local function attachTooltip(target, titleText, explicitDescription)
    local description = explicitDescription or FEATURE_TOOLTIPS[titleText]

    if not description or description == "" then
        return
    end

    target.MouseEnter:Connect(function()
        showTooltip(target, titleText, description)
    end)

    target.MouseLeave:Connect(function()
        hideTooltip(target)
    end)

    target.InputChanged:Connect(function(input)
        if tooltipTarget == target
            and input.UserInputType == Enum.UserInputType.MouseMovement then
            showTooltip(target, titleText, description)
        end
    end)
end

local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.fromScale(0.5, 0.5)
shadow.Size = UDim2.new(1, 36, 1, 36)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.35
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.ZIndex = -1
shadow.Parent = main

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Position = UDim2.fromOffset(16, 82)
sidebar.Size = UDim2.fromOffset(162, 430)
sidebar.BackgroundColor3 = COLORS.Panel
sidebar.BorderSizePixel = 0
sidebar.Parent = main

local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 9)
sidebarCorner.Parent = sidebar

local sidebarStroke = Instance.new("UIStroke")
sidebarStroke.Color = COLORS.Outline
sidebarStroke.Transparency = 0.5
sidebarStroke.Thickness = 1
sidebarStroke.Parent = sidebar

local sidebarLine = Instance.new("Frame")
sidebarLine.Position = UDim2.new(1, -1, 0, 0)
sidebarLine.Size = UDim2.new(0, 1, 1, 0)
sidebarLine.BackgroundColor3 = COLORS.Outline
sidebarLine.BackgroundTransparency = 0.35
sidebarLine.BorderSizePixel = 0
sidebarLine.Parent = sidebar
sidebarLine.Visible = false

local brand = Instance.new("Frame")
brand.Position = UDim2.fromOffset(14, 14)
brand.Size = UDim2.new(1, -28, 0, 70)
brand.BackgroundTransparency = 1
brand.Parent = sidebar
brand.Visible = false

local brandIcon = Instance.new("Frame")
brandIcon.Name = "BrandIcon"
brandIcon.Size = UDim2.fromOffset(42, 42)
brandIcon.Position = UDim2.fromOffset(0, 2)
brandIcon.BackgroundColor3 = COLORS.Accent
brandIcon.BorderSizePixel = 0
brandIcon.Parent = brand

local brandIconCorner = Instance.new("UICorner")
brandIconCorner.CornerRadius = UDim.new(0, 11)
brandIconCorner.Parent = brandIcon

local brandThumb = Instance.new("TextLabel")
brandThumb.Size = UDim2.fromScale(1, 1)
brandThumb.BackgroundTransparency = 1
brandThumb.Font = Enum.Font.GothamBold
brandThumb.TextSize = 24
brandThumb.TextColor3 = Color3.new(1, 1, 1)
brandThumb.Text = "👍"
brandThumb.Parent = brandIcon

local brandTitle = Instance.new("TextLabel")
brandTitle.Position = UDim2.fromOffset(52, 8)
brandTitle.Size = UDim2.new(1, -52, 0, 24)
brandTitle.BackgroundTransparency = 1
brandTitle.Font = Enum.Font.GothamBold
brandTitle.TextSize = 17
brandTitle.TextColor3 = COLORS.Text
brandTitle.TextXAlignment = Enum.TextXAlignment.Left
brandTitle.Text = "ThumbsHub"
brandTitle.Parent = brand

local brandSubline = Instance.new("TextLabel")
brandSubline.Position = UDim2.fromOffset(52, 25)
brandSubline.Size = UDim2.new(1, -52, 0, 17)
brandSubline.BackgroundTransparency = 1
brandSubline.Font = Enum.Font.Gotham
brandSubline.TextSize = 10
brandSubline.TextColor3 = COLORS.Accent
brandSubline.TextXAlignment = Enum.TextXAlignment.Left
brandSubline.Text = ""
brandSubline.Visible = false
brandSubline.Parent = brand

local brandTag = Instance.new("TextLabel")
brandTag.Position = UDim2.fromOffset(0, 52)
brandTag.Size = UDim2.new(1, 0, 0, 17)
brandTag.BackgroundTransparency = 1
brandTag.Font = Enum.Font.Gotham
brandTag.TextSize = 9
brandTag.TextColor3 = COLORS.Muted
brandTag.TextXAlignment = Enum.TextXAlignment.Left
brandTag.Text = "Play Smarter.  Farm Harder."
brandTag.Parent = brand

local navScroll = Instance.new("ScrollingFrame")
navScroll.Name = "Navigation"
navScroll.Position = UDim2.fromOffset(8, 8)
navScroll.Size = UDim2.new(1, -16, 1, -16)
navScroll.BackgroundTransparency = 1
navScroll.BorderSizePixel = 0
navScroll.ScrollBarThickness = 2
navScroll.ScrollBarImageColor3 = COLORS.Accent
navScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
navScroll.CanvasSize = UDim2.fromOffset(0, 0)
navScroll.Parent = sidebar

local navPad = Instance.new("UIPadding")
navPad.PaddingLeft = UDim.new(0, 2)
navPad.PaddingRight = UDim.new(0, 2)
navPad.PaddingBottom = UDim.new(0, 8)
navPad.Parent = navScroll

local navList = Instance.new("UIListLayout")
navList.Padding = UDim.new(0, 5)
navList.SortOrder = Enum.SortOrder.LayoutOrder
navList.Parent = navScroll

local profileCard = Instance.new("Frame")
profileCard.Position = UDim2.new(0, 10, 1, -96)
profileCard.Size = UDim2.new(1, -20, 0, 82)
profileCard.BackgroundColor3 = COLORS.Panel
profileCard.BorderSizePixel = 0
profileCard.Parent = sidebar
profileCard.Visible = false

local profileCorner = Instance.new("UICorner")
profileCorner.CornerRadius = UDim.new(0, 10)
profileCorner.Parent = profileCard

local profileStroke = Instance.new("UIStroke")
profileStroke.Color = COLORS.Outline
profileStroke.Transparency = 0.45
profileStroke.Parent = profileCard

local avatar = Instance.new("ImageLabel")
avatar.Position = UDim2.fromOffset(10, 12)
avatar.Size = UDim2.fromOffset(46, 46)
avatar.BackgroundColor3 = COLORS.Element
avatar.BorderSizePixel = 0
avatar.Image = ""
avatar.Parent = profileCard

local avatarCorner = Instance.new("UICorner")
avatarCorner.CornerRadius = UDim.new(1, 0)
avatarCorner.Parent = avatar

local onlineDot = Instance.new("Frame")
onlineDot.Size = UDim2.fromOffset(11, 11)
onlineDot.Position = UDim2.new(1, -10, 1, -10)
onlineDot.BackgroundColor3 = COLORS.Success
onlineDot.BorderSizePixel = 0
onlineDot.Parent = avatar

local onlineCorner = Instance.new("UICorner")
onlineCorner.CornerRadius = UDim.new(1, 0)
onlineCorner.Parent = onlineDot

local profileName = Instance.new("TextLabel")
profileName.Position = UDim2.fromOffset(66, 14)
profileName.Size = UDim2.new(1, -74, 0, 20)
profileName.BackgroundTransparency = 1
profileName.Font = Enum.Font.GothamBold
profileName.TextSize = 11
profileName.TextColor3 = COLORS.Text
profileName.TextXAlignment = Enum.TextXAlignment.Left
profileName.TextTruncate = Enum.TextTruncate.AtEnd
profileName.Text = tostring(player.Name)
profileName.Parent = profileCard

local profileRole = Instance.new("TextLabel")
profileRole.Position = UDim2.fromOffset(66, 36)
profileRole.Size = UDim2.new(1, -74, 0, 17)
profileRole.BackgroundTransparency = 1
profileRole.Font = Enum.Font.Gotham
profileRole.TextSize = 10
profileRole.TextColor3 = COLORS.Accent
profileRole.TextXAlignment = Enum.TextXAlignment.Left
profileRole.Text = tostring(player.DisplayName) .. " • Lifetime"
profileRole.Parent = profileCard

task.spawn(function()
    local ok, image = pcall(function()
        return Players:GetUserThumbnailAsync(
            player.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size150x150
        )
    end)

    if ok and image then
        avatar.Image = image
    end
end)

local top = Instance.new("Frame")
top.Name = "Top"
top.Position = UDim2.fromOffset(0, 0)
top.Size = UDim2.new(1, 0, 0, 68)
top.BackgroundTransparency = 1
top.BorderSizePixel = 0
top.Parent = main

local topLine = Instance.new("Frame")
topLine.Position = UDim2.new(0, 0, 1, -1)
topLine.Size = UDim2.new(1, 0, 0, 1)
topLine.BackgroundColor3 = COLORS.Outline
topLine.BackgroundTransparency = 0.4
topLine.BorderSizePixel = 0
topLine.Parent = top

local pageTitle = Instance.new("TextLabel")
pageTitle.Position = UDim2.fromOffset(220, 10)
pageTitle.Size = UDim2.fromOffset(250, 25)
pageTitle.BackgroundTransparency = 1
pageTitle.Font = Enum.Font.GothamBold
pageTitle.TextSize = 17
pageTitle.TextColor3 = COLORS.Text
pageTitle.TextXAlignment = Enum.TextXAlignment.Left
pageTitle.Text = "Home"
pageTitle.Parent = top

local pageSubtitle = Instance.new("TextLabel")
pageSubtitle.Position = UDim2.fromOffset(220, 36)
pageSubtitle.Size = UDim2.fromOffset(360, 18)
pageSubtitle.BackgroundTransparency = 1
pageSubtitle.Font = Enum.Font.Gotham
pageSubtitle.TextSize = 10
pageSubtitle.TextColor3 = COLORS.Dim
pageSubtitle.TextXAlignment = Enum.TextXAlignment.Left
pageSubtitle.Text = "Welcome to THUMBSHUB."
pageSubtitle.Parent = top

local searchBox = Instance.new("TextBox")
searchBox.Position = UDim2.new(1, -282, 0, 15)
searchBox.Size = UDim2.fromOffset(190, 32)
searchBox.BackgroundColor3 = COLORS.Element
searchBox.BorderSizePixel = 0
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 11
searchBox.TextColor3 = COLORS.Text
searchBox.PlaceholderText = "Search pages or features..."
searchBox.PlaceholderColor3 = COLORS.Muted
searchBox.ClearTextOnFocus = false
searchBox.Text = ""
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Parent = top
searchBox.Visible = false

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 9)
searchCorner.Parent = searchBox

local searchPad = Instance.new("UIPadding")
searchPad.PaddingLeft = UDim.new(0, 12)
searchPad.PaddingRight = UDim.new(0, 12)
searchPad.Parent = searchBox

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "RuntimeStatus"
statusLabel.Position = UDim2.new(1, -330, 0, 21)
statusLabel.Size = UDim2.fromOffset(190, 24)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.TextColor3 = COLORS.Accent
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
statusLabel.Text = "READY"
statusLabel.BackgroundColor3 = COLORS.Panel
statusLabel.BorderSizePixel = 0
statusLabel.Parent = top

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(1, 0)
statusCorner.Parent = statusLabel

local statusStroke = Instance.new("UIStroke")
statusStroke.Color = COLORS.Outline
statusStroke.Transparency = 0.55
statusStroke.Thickness = 1
statusStroke.Parent = statusLabel

local minimize = Instance.new("TextButton")
minimize.Position = UDim2.new(1, -82, 0, 15)
minimize.Size = UDim2.fromOffset(30, 30)
minimize.BackgroundColor3 = COLORS.Element
minimize.BorderSizePixel = 0
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = 16
minimize.TextColor3 = COLORS.Text
minimize.Text = "—"
minimize.Parent = top

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 9)
minimizeCorner.Parent = minimize

local closeButton = Instance.new("TextButton")
closeButton.Position = UDim2.new(1, -44, 0, 15)
closeButton.Size = UDim2.fromOffset(30, 30)
closeButton.BackgroundColor3 = Color3.fromRGB(70, 31, 28)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.TextColor3 = Color3.fromRGB(250, 205, 201)
closeButton.Text = "×"
closeButton.Parent = top

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 9)
closeCorner.Parent = closeButton

local content = Instance.new("Frame")
content.Name = "Content"
content.Position = UDim2.fromOffset(192, 82)
content.Size = UDim2.fromOffset(710, 430)
content.BackgroundTransparency = 1
content.Parent = main

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 9)
contentCorner.Parent = content

local contentStroke = Instance.new("UIStroke")
contentStroke.Color = COLORS.Outline
contentStroke.Transparency = 0.62
contentStroke.Thickness = 1
contentStroke.Parent = content

local footer = Instance.new("Frame")
footer.Position = UDim2.new(0, 178, 1, -22)
footer.Size = UDim2.new(1, -178, 0, 22)
footer.BackgroundColor3 = COLORS.Header
footer.BorderSizePixel = 0
footer.Parent = main
footer.Visible = false

local footerText = Instance.new("TextLabel")
footerText.Position = UDim2.fromOffset(16, 0)
footerText.Size = UDim2.new(1, -32, 1, 0)
footerText.BackgroundTransparency = 1
footerText.Font = Enum.Font.Gotham
footerText.TextSize = 9
footerText.TextColor3 = COLORS.Muted
footerText.TextXAlignment = Enum.TextXAlignment.Left
footerText.Text = "ThumbsHub"
footerText.Visible = Settings.UIWatermark
footerText.Parent = footer

local footerRight = Instance.new("TextLabel")
footerRight.Position = UDim2.new(0.55, 0, 0, 0)
footerRight.Size = UDim2.new(0.45, -16, 1, 0)
footerRight.BackgroundTransparency = 1
footerRight.Font = Enum.Font.Gotham
footerRight.TextSize = 9
footerRight.TextColor3 = COLORS.Muted
footerRight.TextXAlignment = Enum.TextXAlignment.Right
footerRight.Text = "AUTOMATION • PROGRESS • MORE FUN"
footerRight.Visible = Settings.UIWatermark
footerRight.Parent = footer

local pages = {}
local tabButtons = {}
local refreshCallbacks = {}
connections.RefreshEggControls = function()
    for _, refresh in ipairs(refreshCallbacks) do pcall(refresh) end
end
local homeLabels = {}
local farmLabels = {}
local currentPageName = "Home"

local function colorsClose(a, b)
    if typeof(a) ~= "Color3" or typeof(b) ~= "Color3" then
        return false
    end

    return math.abs(a.R - b.R) < 0.002
        and math.abs(a.G - b.G) < 0.002
        and math.abs(a.B - b.B) < 0.002
end

local function applyTheme(saveAfter)
    local oldPalette = {}
    for key, value in pairs(COLORS) do
        oldPalette[key] = value
    end

    local newPalette = buildThemePalette(Settings.UITheme, Settings.UIAccent)
    for key, value in pairs(newPalette) do
        COLORS[key] = value
    end

    local function remap(value)
        for key, oldColor in pairs(oldPalette) do
            if colorsClose(value, oldColor) and newPalette[key] then
                return newPalette[key]
            end
        end
        return nil
    end

    local objects = {gui}
    for _, obj in ipairs(gui:GetDescendants()) do
        table.insert(objects, obj)
    end

    for _, obj in ipairs(objects) do
        pcall(function()
            if obj:IsA("GuiObject") then
                local bg = remap(obj.BackgroundColor3)
                if bg then
                    obj.BackgroundColor3 = bg
                end
            end

            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                local text = remap(obj.TextColor3)
                if text then
                    obj.TextColor3 = text
                end
            end

            if obj:IsA("UIStroke") then
                local stroke = remap(obj.Color)
                if stroke then
                    obj.Color = stroke
                end
            end

            if obj:IsA("ScrollingFrame") then
                local scroll = remap(obj.ScrollBarImageColor3)
                if scroll then
                    obj.ScrollBarImageColor3 = scroll
                end
            end
        end)
    end

    -- Explicit references guarantee the most important accent pieces update.
    main.BackgroundColor3 = COLORS.Background
    mainStroke.Color = COLORS.Accent
    slayersAccentLine.BackgroundColor3 = COLORS.Accent
    hubTitle.TextColor3 = COLORS.Text
    hubSubtitle.TextColor3 = COLORS.Dim
    sidebar.BackgroundColor3 = COLORS.Panel
    sidebarStroke.Color = COLORS.Outline
    content.BackgroundColor3 = COLORS.Panel
    contentStroke.Color = COLORS.Outline
    statusLabel.BackgroundColor3 = COLORS.Panel
    statusLabel.TextColor3 = COLORS.Accent
    statusStroke.Color = COLORS.Outline
    tooltipStroke.Color = COLORS.Accent

    if saveAfter ~= false then
        saveConfig()
    end
end

setStatus = function(value)
    statusLabel.Text = tostring(value)
end

local PAGE_META = {
    Home = {
        subtitle = "Dashboard, session stats and quick actions.",
        icon = "⌂",
    },
    ["Auto Farm"] = {
        subtitle = "Egg farming, filters, basket handling and live farm status.",
        icon = "○",
    },
    Pets = {
        subtitle = "Pet placement and pet automation.",
        icon = "♢",
    },
    Feeds = {
        subtitle = "Choose food and automate feeding rules.",
        icon = "◈",
    },
    Shop = {
        subtitle = "Radars, food purchases and automatic shop actions.",
        icon = "▣",
    },
    Progression = {
        subtitle = "Hatch luck, nests, rebirths and progression rewards.",
        icon = "≡",
    },
    Visuals = {
        subtitle = "Egg ESP, pet ESP and performance controls.",
        icon = "◉",
    },
    Server = {
        subtitle = "Server hopping and egg / mutation hunt filters.",
        icon = "▤",
    },
    Webhook = {
        subtitle = "Discord farm notifications and event alerts.",
        icon = "◇",
    },
    Settings = {
        subtitle = "Configs, theme, accent colour and interface settings.",
        icon = "⚙",
    },
}

local function applyUIScale()
    local userScale = math.clamp(tonumber(Settings.UIScale) or 1, 0.75, 1.25)
    local autoScale = 1

    if Settings.UIAutoScale and workspace.CurrentCamera then
        local viewport = workspace.CurrentCamera.ViewportSize
        autoScale = math.min(
            1,
            math.max(0.68, (viewport.X - 30) / 920),
            math.max(0.68, (viewport.Y - 30) / 570)
        )
    end

    uiScale.Scale = userScale * autoScale
end

applyUIScale()

local function newPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = COLORS.Accent
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.fromOffset(0, 0)
    page.Visible = false
    page.Parent = content

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 14)
    pad.PaddingLeft = UDim.new(0, 16)
    pad.PaddingRight = UDim.new(0, 16)
    pad.PaddingBottom = UDim.new(0, 18)
    pad.Parent = page

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 11)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = page

    pages[name] = page
    return page
end

local function showPage(name)
    if not pages[name] then
        return
    end

    currentPageName = name

    for n, page in pairs(pages) do
        local activePage = n == name
        page.Visible = activePage

        if activePage then
            page.Position = UDim2.fromOffset(10, 0)
            TweenService:Create(
                page,
                TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Position = UDim2.fromOffset(0, 0)}
            ):Play()
        end
    end

    for n, button in pairs(tabButtons) do
        local active = n == name
        button.BackgroundColor3 = active and COLORS.Accent or COLORS.Element
        button.TextColor3 = COLORS.Text

        local marker = button:FindFirstChild("ActiveMarker")
        if marker then
            marker.Visible = active
        end
    end

    local meta = PAGE_META[name] or {}
    pageTitle.Text = name
    pageSubtitle.Text = meta.subtitle or ""
end

local function navLabel(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 22)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 9
    label.TextColor3 = COLORS.Accent
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = string.upper(text)
    label.LayoutOrder = #navScroll:GetChildren()
    label.Parent = navScroll
end

local function addTab(name)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, -4, 0, 36)
    button.BackgroundColor3 = COLORS.Element
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 10
    button.TextColor3 = COLORS.Text
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Text = "   " .. name
    button.LayoutOrder = #navScroll:GetChildren()
    button.Parent = navScroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    local activeMarker = Instance.new("Frame")
    activeMarker.Name = "ActiveMarker"
    activeMarker.Position = UDim2.fromOffset(0, 7)
    activeMarker.Size = UDim2.fromOffset(3, 22)
    activeMarker.BackgroundColor3 = COLORS.Text
    activeMarker.BorderSizePixel = 0
    activeMarker.Visible = false
    activeMarker.Parent = button

    local activeCorner = Instance.new("UICorner")
    activeCorner.CornerRadius = UDim.new(1, 0)
    activeCorner.Parent = activeMarker

    button.MouseEnter:Connect(function()
        if currentPageName ~= name then
            TweenService:Create(
                button,
                TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = COLORS.Hover}
            ):Play()
        end
    end)

    button.MouseLeave:Connect(function()
        if currentPageName ~= name then
            TweenService:Create(
                button,
                TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = COLORS.Element}
            ):Play()
        end
    end)

    button.MouseButton1Click:Connect(function()
        showPage(name)
    end)

    tabButtons[name] = button
end

local function makeCard(page, titleText, subtitleText)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.Parent = page

    local cardList = Instance.new("UIListLayout")
    cardList.Padding = UDim.new(0, 0)
    cardList.SortOrder = Enum.SortOrder.LayoutOrder
    cardList.Parent = card

    local header = Instance.new("Frame")
    header.LayoutOrder = 1
    header.Size = UDim2.new(1, 0, 0, subtitleText and 43 or 27)
    header.BackgroundTransparency = 1
    header.Parent = card

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Position = UDim2.fromOffset(0, 0)
    titleLabel.Size = UDim2.new(1, 0, 0, 22)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 11
    titleLabel.TextColor3 = COLORS.Accent
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = string.upper(tostring(titleText))
    titleLabel.Parent = header

    if subtitleText then
        local subtitle = Instance.new("TextLabel")
        subtitle.Position = UDim2.fromOffset(0, 22)
        subtitle.Size = UDim2.new(1, 0, 0, 16)
        subtitle.BackgroundTransparency = 1
        subtitle.Font = Enum.Font.Gotham
        subtitle.TextSize = 9
        subtitle.TextColor3 = COLORS.Dim
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.Text = subtitleText
        subtitle.Parent = header
    end

    local body = Instance.new("Frame")
    body.LayoutOrder = 2
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.BackgroundTransparency = 1
    body.Parent = card

    local bodyList = Instance.new("UIListLayout")
    bodyList.Padding = UDim.new(0, 7)
    bodyList.SortOrder = Enum.SortOrder.LayoutOrder
    bodyList.Parent = body

    return body, card
end

local function splitPageColumns(page, leftWidth)
    leftWidth = leftWidth or 0.58

    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 520)
    holder.BackgroundTransparency = 1
    holder.Parent = page

    local function makeColumn(position, size)
        local column = Instance.new("ScrollingFrame")
        column.Position = position
        column.Size = size
        column.BackgroundTransparency = 1
        column.BorderSizePixel = 0
        column.ScrollBarThickness = 3
        column.ScrollBarImageColor3 = COLORS.Accent
        column.AutomaticCanvasSize = Enum.AutomaticSize.Y
        column.CanvasSize = UDim2.fromOffset(0, 0)
        column.Parent = holder

        local pad = Instance.new("UIPadding")
        pad.PaddingRight = UDim.new(0, 5)
        pad.PaddingBottom = UDim.new(0, 8)
        pad.Parent = column

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 10)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Parent = column

        return column
    end

    local gap = 8
    local left = makeColumn(
        UDim2.fromOffset(0, 0),
        UDim2.new(leftWidth, -gap, 1, 0)
    )

    local right = makeColumn(
        UDim2.new(leftWidth, gap, 0, 0),
        UDim2.new(1 - leftWidth, -(gap * 2), 1, 0)
    )

    return left, right
end

local function controlRow(parent, height)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, height or 44)
    frame.BackgroundColor3 = COLORS.Element
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Color = COLORS.Outline
    rowStroke.Transparency = 0.88
    rowStroke.Thickness = 1
    rowStroke.Parent = frame

    return frame
end

local function addToggle(parent, labelText, key, callback, description)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 38)
    button.BackgroundColor3 = COLORS.Element
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 10
    button.TextColor3 = COLORS.Text
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Outline
    stroke.Transparency = 0.62
    stroke.Thickness = 1
    stroke.Parent = button

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = button

    local function refresh()
        local on = Settings[key] == true

        button.Text =
            tostring(labelText)
            .. "  •  "
            .. (
                on
                and "ON"
                or "OFF"
            )

        button.BackgroundColor3 =
            on
            and COLORS.Accent
            or COLORS.Element

        stroke.Color =
            on
            and COLORS.Accent
            or COLORS.Outline
    end

    button.MouseEnter:Connect(function()
        if Settings[key] ~= true then
            TweenService:Create(
                button,
                TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = COLORS.Hover}
            ):Play()
        end
    end)

    button.MouseLeave:Connect(refresh)

    button.MouseButton1Click:Connect(function()
        Settings[key] =
            not Settings[key]

        refresh()

        if callback then
            pcall(
                callback,
                Settings[key]
            )
        end

        saveConfig()
    end)

    table.insert(
        refreshCallbacks,
        refresh
    )

    refresh()

    attachTooltip(
        button,
        labelText,
        description
    )

    return button
end

local function addNumber(parent, labelText, key, minValue, maxValue, callback, suffix)
    local frame = controlRow(parent, 43)

    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(12, 0)
    label.Size = UDim2.new(1, -170, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.TextColor3 = COLORS.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText
    label.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.fromOffset(126, 28)
    box.Position = UDim2.new(1, -138, 0.5, -14)
    box.BackgroundColor3 = COLORS.Element
    box.BorderSizePixel = 0
    box.Font = Enum.Font.GothamMedium
    box.TextSize = 10
    box.TextColor3 = COLORS.Text
    box.ClearTextOnFocus = false
    box.Text = tostring(Settings[key]) .. (suffix or "")
    box.Parent = frame

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 7)
    boxCorner.Parent = box

    local function refresh()
        box.Text = tostring(Settings[key]) .. (suffix or "")
    end

    box.Focused:Connect(function()
        box.Text = tostring(Settings[key])
    end)

    box.FocusLost:Connect(function()
        local value = tonumber(box.Text)

        if value then
            if minValue then value = math.max(minValue, value) end
            if maxValue then value = math.min(maxValue, value) end
            Settings[key] = value
        end

        refresh()
        saveConfig()

        if callback then
            pcall(callback, Settings[key])
        end
    end)

    table.insert(refreshCallbacks, refresh)
    refresh()
    attachTooltip(frame, labelText)

    return frame
end

local function addText(parent, labelText, key, placeholder, secret)
    local frame = controlRow(parent, 62)

    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(12, 5)
    label.Size = UDim2.new(1, -24, 0, 17)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 10
    label.TextColor3 = COLORS.Dim
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText
    label.Parent = frame

    local box = Instance.new("TextBox")
    box.Position = UDim2.fromOffset(12, 27)
    box.Size = UDim2.new(1, -24, 0, 27)
    box.BackgroundColor3 = COLORS.Element
    box.BorderSizePixel = 0
    box.Font = Enum.Font.Gotham
    box.TextSize = 10
    box.TextColor3 = COLORS.Text
    box.PlaceholderText = placeholder or ""
    box.PlaceholderColor3 = COLORS.Muted
    box.ClearTextOnFocus = false
    box.Text = tostring(Settings[key] or "")
    box.Parent = frame

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 7)
    boxCorner.Parent = box

    local function refresh()
        box.Text = tostring(Settings[key] or "")
    end

    box.FocusLost:Connect(function()
        if key == "ConfigProfile" then
            Settings[key] = safeConfigName(box.Text)
        else
            Settings[key] = box.Text
        end
        refresh()
        saveConfig()
    end)

    table.insert(refreshCallbacks, refresh)
    attachTooltip(frame, labelText)
    return frame
end

local activeDropdownPopup = nil

local function addPicker(parent, labelText, key, values, callback)
    local frame = controlRow(parent, 43)

    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(12, 0)
    label.Size = UDim2.new(1, -230, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.TextColor3 = COLORS.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(190, 28)
    button.Position = UDim2.new(1, -202, 0.5, -14)
    button.BackgroundColor3 = COLORS.Element
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 10
    button.TextColor3 = COLORS.Text
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 7)
    buttonCorner.Parent = button

    local function eggSelectionHas(value)
        if key ~= "EggNames" and key ~= "HopEggNames" then
            return false
        end

        local wanted = string.lower(trim(tostring(value or "")))

        for _, selected in ipairs(splitCSV(Settings[key])) do
            if selected == wanted then
                return true
            end
        end

        return false
    end

    local function shownValue()
        if key == "EggNames" or key == "HopEggNames" then
            local selected = splitCSV(Settings[key])

            if #selected == 0 then
                return "Any Egg"
            elseif #selected == 1 then
                for _, value in ipairs(values) do
                    if value ~= "Any Egg" and eggSelectionHas(value) then
                        return value
                    end
                end
            end

            return tostring(#selected) .. " Eggs Selected"
        end

        return tostring(Settings[key])
    end

    local function isSelected(value)
        if key == "EggNames" or key == "HopEggNames" then
            if value == "Any Egg" then
                return trim(Settings[key]) == ""
            end

            return eggSelectionHas(value)
        end

        return tostring(Settings[key]) == tostring(value)
    end

    local function refresh()
        button.Text = "   " .. shownValue() .. "   ▾"
    end

    local function closeDropdown()
        if activeDropdownPopup then
            pcall(function()
                activeDropdownPopup:Destroy()
            end)
            activeDropdownPopup = nil
        end
    end

    button.MouseButton1Click:Connect(function()
        if activeDropdownPopup then
            closeDropdown()
            return
        end

        local visibleRows = math.min(#values, 9)
        local popupHeight = math.max(38, (visibleRows * 30) + 8)

        local popup = Instance.new("Frame")
        popup.Name = "Dropdown_" .. tostring(key)
        popup.Size = UDim2.fromOffset(200, popupHeight)
        popup.BackgroundColor3 = COLORS.Panel2
        popup.BorderSizePixel = 0
        popup.ZIndex = 80
        popup.Parent = main

        local relativeX = button.AbsolutePosition.X - main.AbsolutePosition.X
        local relativeY = button.AbsolutePosition.Y - main.AbsolutePosition.Y + button.AbsoluteSize.Y + 4

        if relativeY + popupHeight > main.AbsoluteSize.Y - 10 then
            relativeY = button.AbsolutePosition.Y - main.AbsolutePosition.Y - popupHeight - 4
        end

        popup.Position = UDim2.fromOffset(
            math.clamp(relativeX, 8, math.max(8, main.AbsoluteSize.X - 208)),
            math.clamp(relativeY, 8, math.max(8, main.AbsoluteSize.Y - popupHeight - 8))
        )

        local popupCorner = Instance.new("UICorner")
        popupCorner.CornerRadius = UDim.new(0, 8)
        popupCorner.Parent = popup

        local popupStroke = Instance.new("UIStroke")
        popupStroke.Color = COLORS.Accent
        popupStroke.Transparency = 0.35
        popupStroke.Parent = popup

        local holder = Instance.new("ScrollingFrame")
        holder.Name = "Options"
        holder.Position = UDim2.fromOffset(4, 4)
        holder.Size = UDim2.new(1, -8, 1, -8)
        holder.BackgroundTransparency = 1
        holder.BorderSizePixel = 0
        holder.ScrollBarThickness = (#values > visibleRows) and 3 or 0
        holder.ScrollBarImageColor3 = COLORS.Accent
        holder.CanvasSize = UDim2.fromOffset(0, (#values * 30))
        holder.AutomaticCanvasSize = Enum.AutomaticSize.None
        holder.ZIndex = 80
        holder.Parent = popup

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 2)
        list.HorizontalAlignment = Enum.HorizontalAlignment.Center
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Parent = holder

        activeDropdownPopup = popup

        for index, value in ipairs(values) do
            local option = Instance.new("TextButton")
            option.LayoutOrder = index
            option.Size = UDim2.new(1, -4, 0, 28)
            option.BackgroundColor3 = isSelected(value) and COLORS.AccentDim or COLORS.Element
            option.BorderSizePixel = 0
            option.Font = Enum.Font.GothamMedium
            option.TextSize = 10
            option.TextColor3 = COLORS.Text
            option.TextXAlignment = Enum.TextXAlignment.Left
            option.Text = (
                isSelected(value)
                and "   ✓ "
                or "   "
            ) .. tostring(value)
            option.ZIndex = 81
            option.Parent = holder

            local optionCorner = Instance.new("UICorner")
            optionCorner.CornerRadius = UDim.new(0, 6)
            optionCorner.Parent = option

            option.MouseButton1Click:Connect(function()
                if key == "EggNames" or key == "HopEggNames" then
                    if value == "Any Egg" then
                        Settings[key] = ""
                        refresh()
                        saveConfig()

                        if callback then
                            pcall(callback, value)
                        end

                        closeDropdown()
                        return
                    end

                    local chosen = {}
                    local toggledOn = not eggSelectionHas(value)

                    for _, candidate in ipairs(values) do
                        if candidate ~= "Any Egg" then
                            local keep = eggSelectionHas(candidate)

                            if candidate == value then
                                keep = toggledOn
                            end

                            if keep then
                                table.insert(chosen, candidate)
                            end
                        end
                    end

                    Settings[key] = table.concat(chosen, ", ")

                    option.BackgroundColor3 =
                        isSelected(value)
                        and COLORS.AccentDim
                        or COLORS.Element

                    option.Text = (
                        isSelected(value)
                        and "   ✓ "
                        or "   "
                    ) .. tostring(value)

                    refresh()
                    saveConfig()

                    if callback then
                        pcall(callback, value)
                    end

                    -- Keep the list open so more eggs can be selected.
                    return
                end

                Settings[key] = value
                refresh()
                closeDropdown()
                saveConfig()

                if callback then
                    pcall(callback, value)
                end
            end)
        end
    end)

    table.insert(refreshCallbacks, refresh)
    refresh()
    attachTooltip(frame, labelText)

    return frame
end

local function addAction(parent, labelText, fn, risky)
    local frame = controlRow(parent, 43)
    frame.BackgroundTransparency = 1

    local button = Instance.new("TextButton")
    button.Position = UDim2.fromOffset(0, 2)
    button.Size = UDim2.new(1, 0, 1, -4)
    button.BackgroundColor3 = risky and Color3.fromRGB(89, 37, 33) or COLORS.AccentDim
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.TextColor3 = risky and Color3.fromRGB(251, 211, 207) or COLORS.Text
    button.Text = labelText
    button.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button

    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Color = risky and COLORS.Risky or COLORS.Accent
    buttonStroke.Transparency = 0.55
    buttonStroke.Parent = button

    button.MouseButton1Click:Connect(function()
        task.spawn(function()
            local ok, err = pcall(fn)
            if not ok then
                setStatus("Error: " .. tostring(err))
            end
        end)
    end)

    attachTooltip(frame, labelText)
    return frame
end

local function addNote(parent, textValue, accent)
    local frame = controlRow(parent, 58)
    frame.BackgroundColor3 = accent and Color3.fromRGB(45, 30, 22) or COLORS.Panel2

    local line = Instance.new("Frame")
    line.Position = UDim2.fromOffset(9, 10)
    line.Size = UDim2.fromOffset(3, 38)
    line.BackgroundColor3 = accent and COLORS.Accent or COLORS.Outline
    line.BorderSizePixel = 0
    line.Parent = frame

    local lineCorner = Instance.new("UICorner")
    lineCorner.CornerRadius = UDim.new(1, 0)
    lineCorner.Parent = line

    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(20, 6)
    label.Size = UDim2.new(1, -30, 1, -12)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 9
    label.TextColor3 = accent and Color3.fromRGB(226, 192, 171) or COLORS.Dim
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Text = textValue
    label.Parent = frame

    return frame
end

local function metricBox(parent, key, titleText, initial)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.333, -5, 0, 59)
    frame.BackgroundColor3 = COLORS.Panel2
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local value = Instance.new("TextLabel")
    value.Position = UDim2.fromOffset(10, 8)
    value.Size = UDim2.new(1, -20, 0, 23)
    value.BackgroundTransparency = 1
    value.Font = Enum.Font.GothamBold
    value.TextSize = 14
    value.TextColor3 = COLORS.Text
    value.TextXAlignment = Enum.TextXAlignment.Left
    value.Text = initial or "--"
    value.Parent = frame

    local caption = Instance.new("TextLabel")
    caption.Position = UDim2.fromOffset(10, 32)
    caption.Size = UDim2.new(1, -20, 0, 16)
    caption.BackgroundTransparency = 1
    caption.Font = Enum.Font.Gotham
    caption.TextSize = 8
    caption.TextColor3 = COLORS.Muted
    caption.TextXAlignment = Enum.TextXAlignment.Left
    caption.Text = titleText
    caption.Parent = frame

    return value
end

local function metricGrid(parent)
    local grid = Instance.new("Frame")
    grid.Size = UDim2.new(1, 0, 0, 0)
    grid.AutomaticSize = Enum.AutomaticSize.Y
    grid.BackgroundTransparency = 1
    grid.Parent = parent

    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(0.333, -5, 0, 59)
    layout.CellPadding = UDim2.fromOffset(7, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = grid

    return grid
end

local function textStat(parent, titleText, valueText, accent)
    local frame = controlRow(parent, 43)

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(12, 0)
    title.Size = UDim2.new(0.55, -12, 1, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.Gotham
    title.TextSize = 10
    title.TextColor3 = COLORS.Dim
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = titleText
    title.Parent = frame

    local value = Instance.new("TextLabel")
    value.Position = UDim2.new(0.55, 0, 0, 0)
    value.Size = UDim2.new(0.45, -12, 1, 0)
    value.BackgroundTransparency = 1
    value.Font = Enum.Font.GothamBold
    value.TextSize = 10
    value.TextColor3 = accent and COLORS.Accent or COLORS.Text
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.Text = valueText or "--"
    value.Parent = frame

    return value
end

local function weatherStat(parent, titleText, valueText, accent, tall)
    local height =
        tall
        and 58
        or 49

    local frame =
        controlRow(
            parent,
            height
        )

    local title =
        Instance.new(
            "TextLabel"
        )

    title.Position =
        UDim2.fromOffset(
            12,
            6
        )

    title.Size =
        UDim2.new(
            1,
            -24,
            0,
            14
        )

    title.BackgroundTransparency =
        1

    title.Font =
        Enum.Font.GothamMedium

    title.TextSize =
        9

    title.TextColor3 =
        COLORS.Dim

    title.TextXAlignment =
        Enum.TextXAlignment.Left

    title.Text =
        titleText

    title.Parent =
        frame

    local value =
        Instance.new(
            "TextLabel"
        )

    value.Position =
        UDim2.fromOffset(
            12,
            20
        )

    value.Size =
        UDim2.new(
            1,
            -24,
            1,
            -24
        )

    value.BackgroundTransparency =
        1

    value.Font =
        Enum.Font.GothamBold

    value.TextSize =
        tall
        and 10
        or 12

    value.TextWrapped =
        true

    value.TextTruncate =
        Enum.TextTruncate.None

    value.TextColor3 =
        accent
        and COLORS.Accent
        or COLORS.Text

    value.TextXAlignment =
        Enum.TextXAlignment.Left

    value.TextYAlignment =
        Enum.TextYAlignment.Top

    value.Text =
        valueText
        or "--"

    value.Parent =
        frame

    return value
end

local function dashboardPair(page, leftTitle, leftSubtitle, rightTitle, rightSubtitle, height)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, height)
    holder.BackgroundTransparency = 1
    holder.Parent = page

    local left = Instance.new("Frame")
    left.Size = UDim2.new(0.57, -6, 1, 0)
    left.BackgroundColor3 = COLORS.Panel
    left.BorderSizePixel = 0
    left.Parent = holder

    local right = Instance.new("Frame")
    right.Position = UDim2.new(0.57, 6, 0, 0)
    right.Size = UDim2.new(0.43, -6, 1, 0)
    right.BackgroundColor3 = COLORS.Panel
    right.BorderSizePixel = 0
    right.Parent = holder

    for _, card in ipairs({left, right}) do
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = card

        local stroke = Instance.new("UIStroke")
        stroke.Color = COLORS.Outline
        stroke.Transparency = 0.5
        stroke.Parent = card
    end

    local function cardHeader(card, titleText, subtitleText)
        local title = Instance.new("TextLabel")
        title.Position = UDim2.fromOffset(14, 10)
        title.Size = UDim2.new(1, -28, 0, 22)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextSize = 12
        title.TextColor3 = COLORS.Text
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = titleText
        title.Parent = card

        local subtitle = Instance.new("TextLabel")
        subtitle.Position = UDim2.fromOffset(14, 31)
        subtitle.Size = UDim2.new(1, -28, 0, 16)
        subtitle.BackgroundTransparency = 1
        subtitle.Font = Enum.Font.Gotham
        subtitle.TextSize = 8
        subtitle.TextColor3 = COLORS.Muted
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.Text = subtitleText
        subtitle.Parent = card
    end

    cardHeader(left, leftTitle, leftSubtitle)
    cardHeader(right, rightTitle, rightSubtitle)

    return left, right
end

local function formatSession(seconds)
    seconds = math.max(0, math.floor(seconds))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60

    if h > 0 then
        return string.format("%dh %02dm", h, m)
    end

    return string.format("%dm %02ds", m, s)
end

local function countActiveFeatures()
    local count = 0

    for _, value in pairs(Settings) do
        if value == true then
            count += 1
        end
    end

    return count
end

-- ============================================================
-- PAGES
-- ============================================================

local homePage = newPage("Home")
local farmPage = newPage("Auto Farm")
local petsPage = newPage("Pets")
local feedsPage = newPage("Feeds")
local shopPage = newPage("Shop")
local progPage = newPage("Progression")
local visualPage = newPage("Visuals")
local hidePetsPage = newPage("Hide Pets")
local hopPage = newPage("Server")
local movementPage = newPage("Player")
local settingsPage = newPage("Settings")

-- Slayers-style navigation: one clear job per page.
navLabel("Automation")

for _, name in ipairs({
    "Home",
    "Auto Farm",
    "Pets",
    "Feeds",
    "Shop",
    "Progression",
}) do
    addTab(name)
end

navLabel("Utilities")

for _, name in ipairs({
    "Visuals",
    "Hide Pets",
    "Server",
    "Player",
    "Settings",
}) do
    addTab(name)
end

-- ============================================================
-- HOME
-- ============================================================
do

local homeTopLeft, homeTopRight = dashboardPair(
    homePage,
    "Announcements",
    "Latest THUMBSHUB build notes.",
    "Live Status",
    "Session and farm health at a glance.",
    236
)

local welcome = Instance.new("TextLabel")
welcome.Position = UDim2.fromOffset(14, 59)
welcome.Size = UDim2.new(1, -28, 0, 28)
welcome.BackgroundTransparency = 1
welcome.Font = Enum.Font.GothamBold
welcome.TextSize = 15
welcome.TextColor3 = COLORS.Accent
welcome.TextXAlignment = Enum.TextXAlignment.Left
welcome.Text = "Still in development — expect bugs."
welcome.Parent = homeTopLeft

local updates = Instance.new("TextLabel")
updates.Position = UDim2.fromOffset(14, 90)
updates.Size = UDim2.new(1, -28, 0, 118)
updates.BackgroundTransparency = 1
updates.Font = Enum.Font.Gotham
updates.TextSize = 10
updates.TextColor3 = COLORS.Dim
updates.TextWrapped = true
updates.TextXAlignment = Enum.TextXAlignment.Left
updates.TextYAlignment = Enum.TextYAlignment.Top
updates.Text =
    "• Volcanic Egg (2.5t) + Bloom Egg (2b) targeting\n"
    .. "• TP-only egg travel is used outbound and home every cycle\n"
    .. "• Every farmed egg auto-dips at the volcano for Magma before returning\n"
    .. "• Player tab: adjustable Fly, WalkSpeed and Noclip\n"
    .. "• Hatch results shown only near / over their source egg\n"
    .. "• Weather: live weights, stricter detection, stale preview expiry\n"
    .. "• Patched underground options and Webhook page removed\n"
    .. "• Volcano dip uses the game's normal visible drop button"

updates.Parent = homeTopLeft

local statusGrid = Instance.new("Frame")
statusGrid.Position = UDim2.fromOffset(12, 58)
statusGrid.Size = UDim2.new(1, -24, 0, 132)
statusGrid.BackgroundTransparency = 1
statusGrid.Parent = homeTopRight

local statusLayout = Instance.new("UIGridLayout")
statusLayout.CellSize = UDim2.new(0.333, -6, 0, 60)
statusLayout.CellPadding = UDim2.fromOffset(7, 7)
statusLayout.Parent = statusGrid

homeLabels.Session = metricBox(statusGrid, "Session", "SESSION", "0m 00s")
homeLabels.Features = metricBox(statusGrid, "Features", "FEATURES ON", "0")
homeLabels.FPS = metricBox(statusGrid, "FPS", "FPS", "--")
homeLabels.Ping = metricBox(statusGrid, "Ping", "PING", "--")
homeLabels.Players = metricBox(statusGrid, "Players", "PLAYERS", "--")
homeLabels.Farm = metricBox(statusGrid, "Farm", "FARM", "Idle")

homeLabels.StatusLine = Instance.new("TextLabel")
homeLabels.StatusLine.Position = UDim2.fromOffset(14, 199)
homeLabels.StatusLine.Size = UDim2.new(1, -28, 0, 22)
homeLabels.StatusLine.BackgroundTransparency = 1
homeLabels.StatusLine.Font = Enum.Font.GothamMedium
homeLabels.StatusLine.TextSize = 9
homeLabels.StatusLine.TextColor3 = COLORS.Accent
homeLabels.StatusLine.TextXAlignment = Enum.TextXAlignment.Left
homeLabels.StatusLine.Text = "Ready"
homeLabels.StatusLine.Parent = homeTopRight

local homeStatsBody = makeCard(
    homePage,
    "Farm Stats",
    "Live session counters from the current farm."
)

local homeStatsGrid = metricGrid(homeStatsBody)
homeLabels.Grabbed = metricBox(homeStatsGrid, "Grabbed", "EGGS GRABBED", "0")
homeLabels.Placed = metricBox(homeStatsGrid, "Placed", "EGGS PLACED", "0")
homeLabels.Hatched = metricBox(homeStatsGrid, "Hatched", "EGGS HATCHED", "0")
homeLabels.Basket = metricBox(homeStatsGrid, "Basket", "BASKET", "--")
homeLabels.Target = metricBox(homeStatsGrid, "Target", "CURRENT TARGET", "None")
homeLabels.Key = metricBox(homeStatsGrid, "Key", "KEY SYSTEM", "Luamor")

local homeQuickBody = makeCard(
    homePage,
    "Quick Actions",
    "Common actions without leaving the dashboard."
)

addAction(homeQuickBody, "Copy Discord Invite", function()
    local copied, message = copyDiscordInvite()

    if copied then
        setStatus(message)
    else
        setStatus("Discord: " .. message)
    end
end)

addAction(homeQuickBody, "Load Last Config", function()
    if loadConfig() then
        for _, fn in ipairs(refreshCallbacks) do
            pcall(fn)
        end

        applyUIScale()
        applyTheme(false)
        footerText.Visible = Settings.UIWatermark
        footerRight.Visible = Settings.UIWatermark
        mainStroke.Transparency = Settings.UIWindowGlow and 0.18 or 0.7
        setStatus("Config loaded")
    else
        setStatus("No saved config found")
    end
end)

addAction(homeQuickBody, "Open Auto Farm", function()
    showPage("Auto Farm")
end)
end

-- ============================================================
-- FARM
-- ============================================================
do

local farmLeft, farmRight = splitPageColumns(farmPage, 0.61)


local function resetFarmFilters()
    Settings.EggNames = ""
    Settings.EggMutation = "Any"
    Settings.MinEggLuck = 0
    Settings.MaxFarmDistance = 0
    Settings.SkipDoomedEggs = false
    Settings.ArriveWithSeconds = 5
    Settings.RelaxFarmFiltersIfNoMatch = true
    saveConfig()

    for _, fn in ipairs(refreshCallbacks) do
        pcall(fn)
    end

    setStatus("Farm filters reset • Any egg allowed")
end

local farmStatusBody = makeCard(
    farmRight,
    "Live Farm Status",
    "Watch the current target, basket and completed actions."
)

local farmGrid = metricGrid(farmStatusBody)
farmLabels.State = metricBox(farmGrid, "State", "STATE", "Idle")
farmLabels.Target = metricBox(farmGrid, "Target", "TARGET", "None")
farmLabels.Basket = metricBox(farmGrid, "Basket", "BASKET", "--")
farmLabels.Grabbed = metricBox(farmGrid, "Grabbed", "GRABBED", "0")
farmLabels.Placed = metricBox(farmGrid, "Placed", "PLACED", "0")
farmLabels.Hatched = metricBox(farmGrid, "Hatched", "HATCHED", "0")

farmLabels.HatchRevealBody = makeCard(
    farmRight,
    "Hover / Nearby Hatch Reveal",
    "Server-confirmed results appear only while hovering over or near their source egg."
)

connections.HatchReveal.Labels.Pet = textStat(farmLabels.HatchRevealBody, "Pet", "Waiting...", true)
connections.HatchReveal.Labels.Egg = textStat(farmLabels.HatchRevealBody, "Egg", "Waiting...", false)
connections.HatchReveal.Labels.Mutation = textStat(farmLabels.HatchRevealBody, "Mutation", "Waiting...", false)
connections.HatchReveal.Labels.Weight = textStat(farmLabels.HatchRevealBody, "Weight", "Waiting...", false)
connections.HatchReveal.Labels.Luck = textStat(farmLabels.HatchRevealBody, "Luck", "Waiting...", false)
connections.HatchReveal.Labels.Chance = textStat(farmLabels.HatchRevealBody, "Chance", "Waiting...", false)

addNote(
    farmLabels.HatchRevealBody,
    "Results need a matching egg location and expire after 30 seconds. No pet details are shown before the game supplies them.",
    true
)

connections.HatchReveal.Refresh()

farmLabels.WeatherForecastBody = makeCard(
    farmRight,
    "Weather",
    "Current state + upcoming storm"
)

connections.WeatherForecast.Labels.Current =
    weatherStat(
        farmLabels.WeatherForecastBody,
        "NOW",
        "Waiting...",
        true
    )

connections.WeatherForecast.Labels.TimeLeft =
    weatherStat(
        farmLabels.WeatherForecastBody,
        "ENDS",
        "--",
        false
    )

connections.WeatherForecast.Labels.After =
    weatherStat(
        farmLabels.WeatherForecastBody,
        "AFTER",
        "Waiting...",
        true
    )

connections.WeatherForecast.Labels.AfterMutation =
    weatherStat(
        farmLabels.WeatherForecastBody,
        "AFTER MUTATION",
        "--",
        false
    )

connections.WeatherForecast.Labels.Next =
    weatherStat(
        farmLabels.WeatherForecastBody,
        "UPCOMING",
        "Waiting...",
        true
    )

connections.WeatherForecast.Labels.Effect =
    weatherStat(
        farmLabels.WeatherForecastBody,
        "UPCOMING MUTATION",
        "--",
        false
    )

connections.WeatherForecast.Labels.NextTime =
    weatherStat(
        farmLabels.WeatherForecastBody,
        "PREVIEW ENDS",
        "--",
        false
    )

connections.WeatherForecast.Labels.Signal =
    weatherStat(
        farmLabels.WeatherForecastBody,
        "STATUS",
        "Scanning for next weather",
        false,
        true
    )

connections.WeatherForecast.Labels.History =
    weatherStat(
        farmLabels.WeatherForecastBody,
        "RECENT",
        "No rolls yet",
        false,
        true
    )

connections.WeatherForecast.Labels.Odds =
    weatherStat(
        farmLabels.WeatherForecastBody,
        "STORM ODDS",
        "Thunder 60%  •  Volt 30%  •  Raging 6%  •  Dreadful 3%  •  Eternal 1%",
        false,
        true
    )

connections.WeatherForecast.Refresh()

local eggFarmBody = makeCard(
    farmLeft,
    "Egg Farming",
    "Farms one egg at a time: collect, return it home into inventory, then select the next. Rebirth mode fetches one required egg and waits for manual placement."
)

addToggle(
    eggFarmBody,
    "Auto Farm Eggs",
    "AutoFarmEggs",
    function(enabled)
        if enabled then
            setStatus("Auto Farm starting...")
        else
            stopCurrentMovement()
            setStatus("Auto Farm stopped")
        end
    end,
    "Farms one egg at a time and checks basket capacity before every new target."
)

addNumber(eggFarmBody, "Claim Delay", "ClaimDelay", 0, 5, nil, " s")
addToggle(eggFarmBody, "Auto Hatch Eggs", "AutoHatchEggs", nil, "Hatch ready eggs on your plot.")
addToggle(
    eggFarmBody,
    "Hover / Nearby Hatch Reveal",
    "InstantHatchReveal",
    function(enabled)
        if not enabled then
            connections.HatchReveal.HidePopup()
            setStatus("Instant Hatch Reveal disabled")
        else
            setStatus("Instant Hatch Reveal enabled")
        end
    end,
    "Shows a server-confirmed result only while hovering over or standing near its source egg. It cannot reveal an unrolled pet."
)
addNote(
    eggFarmBody,
    "Every collected egg is TP'd to the volcano and dropped through the game's normal volcano button. Build138 simply waits 15 seconds from volcano arrival, then forces the TP-home path.",
    true
)
addNumber(eggFarmBody, "Reveal Distance", "HatchRevealRadius", 3, 40, nil, " studs")
addToggle(eggFarmBody, "Smart Egg Targeting", "SmartEggTargeting")
addToggle(eggFarmBody, "Best Egg First", "BestEggFirst")
addToggle(eggFarmBody, "Relax Filters If Nothing Matches", "RelaxFarmFiltersIfNoMatch")
addToggle(eggFarmBody, "Count Mutation Value", "PreferMutationValue")
addNumber(eggFarmBody, "Smart Top % Of Visible Eggs", "SmartTopPercent", 1, 100, nil, "%")
addNumber(eggFarmBody, "Max Egg Distance (0 = Unlimited)", "MaxFarmDistance", 0, 500)
addPicker(eggFarmBody, "Mutation To Farm", "EggMutation", MUTATIONS)
addPicker(
    eggFarmBody,
    "Egg Filter",
    "EggNames",
    (function()
        local ranked = {}

        for eggName, luck in pairs(KNOWN_WORLD_EGG_LUCK) do
            table.insert(ranked, {
                Name = eggName,
                Luck = tonumber(luck) or 0,
            })
        end

        table.sort(ranked, function(a, b)
            if a.Luck ~= b.Luck then
                return a.Luck < b.Luck
            end

            return a.Name < b.Name
        end)

        local values = {"Any Egg"}

        for _, entry in ipairs(ranked) do
            table.insert(values, entry.Name)
        end

        return values
    end)(),
    function(value)
        stopCurrentMovement()
        Reliability.setUndergroundAntiGravity(false)
        Reliability.setUndergroundNoclip(false)
        Settings.MinEggLuck = 0
        Settings.MaxFarmDistance = 0
        Settings.SkipDoomedEggs = false
        Settings.EggFilterVersion = 1
        saveConfig()
        for _, refresh in ipairs(refreshCallbacks) do pcall(refresh) end
        local selectedCount = #splitCSV(Settings.EggNames)

        setStatus(
            selectedCount == 0
            and "Egg Filter • Any Egg"
            or (
                "Egg Filter • "
                .. tostring(selectedCount)
                .. " egg(s) selected"
            )
        )
    end
)
addNote(eggFarmBody, "Changing Egg Filter clears old minimum-luck and distance limits. Mutation To Farm still applies; choose Any for every mutation of your selected eggs.", true)
addNumber(eggFarmBody, "Minimum Egg Luck", "MinEggLuck", 0, 1e15)
addAction(eggFarmBody, "Reset Farm Filters", resetFarmFilters)
addNote(
    eggFarmBody,
    "Auto Rebirth prioritizes the current required pet. Unknown pet→egg mappings are learned, scanned at runtime when supported, or can be taught once with Rebirth Egg Override.",
    true
)

local basketBody = makeCard(
    farmLeft,
    "Basket",
    "Carried eggs are resolved before another world target is selected. Normal Auto Farm does not auto-place eggs."
)

addToggle(basketBody, "Auto Sell Basket Before Farm", "AutoSellBasketBeforeFarm")
addToggle(basketBody, "Sell Basket Only When Full", "SellOnlyWhenFull")
addAction(basketBody, "Sell Basket Now", function()
    sellCurrentBasket(function()
        return alive
    end)
end)
addNote(
    basketBody,
    "Basket selling only uses a visible Sell prompt when one exists. No unknown remote arguments are guessed."
)

local petsOverview = makeCard(
    petsPage,
    "Pet Automation",
    "Keep your strongest pets placed with one-click and automatic controls."
)
addNote(
    petsOverview,
    "All existing pet placement logic is unchanged — this page only reorganises the controls.",
    true
)

local petsBody = makeCard(
    petsPage,
    "Pets",
    "Placement and pet automation."
)

addToggle(petsBody, "Auto Place Best Pets", "AutoPlaceBestPets")
addAction(petsBody, "Place Best Pets Now", placeBestPets)
addNote(
    petsBody,
    "Auto Sell Pets remains disabled until the exact sell interaction is confirmed, so the hub cannot accidentally sell the wrong pet.",
    true
)

local feedsOverview = makeCard(
    feedsPage,
    "Feed Automation",
    "Pick food once, then choose which pets qualify for automatic feeding."
)
addNote(
    feedsOverview,
    "Use the income, age or base-rarity rules independently or together.",
    true
)

local feedsBody = makeCard(
    feedsPage,
    "Feeds",
    "Automatically feed selected pets."
)

addPicker(feedsBody, "Food Picker", "Food", FOODS)
addToggle(feedsBody, "Auto Feed Best Pet", "AutoFeedBestPet")
addToggle(feedsBody, "Auto Feed Above $/s", "AutoFeedAboveIncome")
addNumber(feedsBody, "Minimum $/s", "FeedMinIncome", 0, 1e15)
addToggle(feedsBody, "Auto Feed Above Age", "AutoFeedAboveAge")
addNumber(feedsBody, "Minimum Age", "FeedMinAge", 0, 100000)
addToggle(feedsBody, "Auto Feed By Base Rarity", "AutoFeedByRarity")
addNumber(feedsBody, "Minimum '1 in X' Rarity", "FeedMinOneIn", 1, 1e15)
addAction(feedsBody, "Run Feed Pass Now", feedPetsPass)

local shopOverview = makeCard(
    shopPage,
    "Shop Automation",
    "Keep your selected radar and food stocked while the farm runs."
)
addNote(
    shopOverview,
    "These are the same confirmed shop actions from the previous UI.",
    true
)

local shopBody = makeCard(
    shopPage,
    "Shop",
    "Keep radars and food stocked while farming."
)

addPicker(shopBody, "Radar Picker", "Radar", RADARS)
addToggle(shopBody, "Auto Buy Radar", "AutoBuyRadar")
addToggle(shopBody, "Auto Use Radar", "AutoUseRadar")
addAction(shopBody, "Buy Selected Radar Now", function()
    buyShopItem("Gears", Settings.Radar)
end)
addAction(shopBody, "Use Selected Radar Now", useRadar)
addPicker(shopBody, "Food Picker", "Food", FOODS)
addToggle(shopBody, "Auto Buy Food", "AutoBuyFood")
addAction(shopBody, "Buy Selected Food Now", function()
    buyShopItem("Food", Settings.Food)
end)
end

-- ============================================================
-- PROGRESSION
-- ============================================================
do

local progressionLeft, progressionRight = splitPageColumns(progPage, 0.60)


local progressionBody = makeCard(
    progressionLeft,
    "Progression Automation",
    "Upgrade and claim using the confirmed in-game UI interactions."
)

addToggle(progressionBody, "Auto Buy Hatch Luck", "AutoBuyHatchLuck")
addPicker(progressionBody, "Hatch Luck Mode", "HatchLuckMode", {"Buy 1", "Buy Max"})
addToggle(progressionBody, "Auto Unlock Nests", "AutoUnlockNests")
addToggle(progressionBody, "Auto Rebirth", "AutoRebirth")
addText(progressionBody, "Rebirth Egg Override", "RebirthEggOverride", "Leave blank for automatic detection...")
addAction(progressionBody, "Rescan Rebirth Egg Mapping", function()
    rebirthRuntime.LastDeepScanPet = nil
    rebirthRuntime.LastDeepScanAt = 0
    rebirthRuntime.DeepScanResult = nil

    local pet = getRebirthRequiredPetName()
    local egg = getRebirthRequiredEggName()

    if egg then
        setStatus(
            "Auto Rebirth • "
            .. tostring(pet or "pet")
            .. " → "
            .. tostring(egg)
            .. " • "
            .. tostring(rebirthRuntime.MappingSource)
        )
    else
        setStatus(
            "Auto Rebirth • no mapping found for "
            .. tostring(pet or "current pet")
            .. " • use override once"
        )
    end
end)
addAction(progressionBody, "Copy Rebirth Diagnostics", function()
    local lines = {"THUMBSHUB REBIRTH DIAGNOSTICS"}
    local function add(text)
        if #lines < 500 then table.insert(lines, text) end
    end
    local function inspect(root)
        if not root then add("NOT FOUND") ; return end
        local objects = {root}
        for _, obj in ipairs(root:GetDescendants()) do table.insert(objects, obj) end
        for _, obj in ipairs(objects) do
            if not obj:FindFirstAncestorOfClass("WorldModel") and not obj:IsA("ViewportFrame") then
                local text = nil
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    text = obj.Text
                elseif obj:IsA("StringValue") or obj:IsA("BoolValue") or obj:IsA("NumberValue") then
                    text = tostring(obj.Value)
                end
                local attrs = {}
                for key, value in pairs(obj:GetAttributes()) do
                    local lower = key:lower()
                    if lower:find("egg", 1, true) or lower:find("pet", 1, true)
                        or lower:find("require", 1, true) or lower:find("unlock", 1, true) then
                        table.insert(attrs, key .. "=" .. tostring(value):sub(1, 120))
                    end
                end
                if text or #attrs > 0 or obj == root then
                    add(obj:GetFullName() .. " | " .. tostring(text or "") .. " | " .. table.concat(attrs, ","))
                end
            end
        end
    end
    local main = playerGui:FindFirstChild("Main")
    local panel = main and main:FindFirstChild("Rebirth")
    local pet = getRebirthRequiredPetName()
    add("REQUIRED PET: " .. tostring(pet))
    add("OWNED ON PLOT: " .. tostring(ownsRebirthPet(pet)))
    add("--- REBIRTH ---")
    inspect(panel)
    -- Modules first so a large index cannot crowd them out; never require them.
    add("--- DATA MODULE PATHS ---")
    local count = 0
    for _, obj in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        local path = obj:GetFullName()
        local lower = path:lower()
        if obj:IsA("ModuleScript") and (lower:find("pet", 1, true)
            or lower:find("egg", 1, true) or lower:find("rebirth", 1, true)) then
            add(path)
            count = count + 1
            if count >= 100 then add("MODULE LIST TRUNCATED") ; break end
        end
    end
    add("--- PET INDEX ---")
    local index = main and main:FindFirstChild("Index")
    local holders = index and index:FindFirstChild("Holders")
    local pets = holders and holders:FindFirstChild("PetsHolder")
    inspect(pets and pet and pets:FindFirstChild(pet))
    add("--- EGG INDEX ---")
    inspect(holders and holders:FindFirstChild("EggsHolder"))
    add("--- OWN PET NAMES ---")
    for _, owned in ipairs(getOwnPets()) do
        add(tostring(owned:GetAttribute("PetName") or owned.Name))
    end
    local report = table.concat(lines, "\n")
    local copy = setclipboard or toclipboard
    if type(copy) == "function" and pcall(copy, report) then
        setStatus("Diagnostics copied • paste directly into chat")
    else
        -- Throttle console output to avoid the executor dropping old messages.
        for _, line in ipairs(lines) do print(line) ; task.wait(0.06) end
        setStatus("Clipboard unavailable • diagnostics printed to console")
    end
end)
addNote(progressionBody, "Auto Rebirth now remembers pet→egg mappings, learns them from observed hatches, and can deep-scan runtime tables when supported. If one pet still cannot be mapped, enter its egg once in Rebirth Egg Override; that mapping is saved to the current config profile.", true)
addToggle(progressionBody, "Auto Ride Best Pet", "AutoRideBestPet")
addToggle(progressionBody, "Auto Claim Index Rewards", "AutoClaimIndex")
addAction(progressionBody, "Buy Hatch Luck Now", buyHatchLuck)
addAction(progressionBody, "Unlock Next Nest Now", unlockNextNest)
addAction(progressionBody, "Ride Best Pet Now", rideBestPet)
addAction(progressionBody, "Claim Index Reward Now", claimIndex)

local progressionInfoBody = makeCard(
    progressionRight,
    "Availability",
    "Features intentionally left off until their safe interaction is known."
)

addNote(
    progressionInfoBody,
    "Normal Auto Claim Offline Earnings is not wired. The scan only showed x10OfflineCash, which may be a paid/Robux option.",
    true
)

local progressionStatsBody = makeCard(
    progressionRight,
    "Progression Stats",
    "Confirmed values available from the current game state."
)

textStat(progressionStatsBody, "Hatch Luck", "Live from game UI", true)
textStat(progressionStatsBody, "Nests", "Own plot", false)
rebirthUILabels.RequiredEgg = textStat(progressionStatsBody, "Required Egg", "Detecting...", true)
rebirthUILabels.RequiredPet = textStat(progressionStatsBody, "Required Pet", "Detecting...", true)
rebirthUILabels.Mapping = textStat(progressionStatsBody, "Egg Mapping Source", "None", false)
rebirthUILabels.State = textStat(progressionStatsBody, "Auto Rebirth State", "Idle", false)
rebirthUILabels.Placement = textStat(progressionStatsBody, "Placement", "Idle", false)
textStat(progressionStatsBody, "Ride Best Pet", Settings.AutoRideBestPet and "On" or "Off", false)
end

-- ============================================================
-- VISUAL
-- ============================================================
do

local visualLeft, visualRight = splitPageColumns(visualPage, 0.55)


local eggVisualBody = makeCard(
    visualLeft,
    "Egg ESP",
    "Highlight world eggs while you farm."
)

addToggle(eggVisualBody, "Egg ESP", "EggESP", refreshEggESP)
addAction(eggVisualBody, "Refresh Egg ESP", refreshEggESP)

local petVisualBody = makeCard(
    visualLeft,
    "Pet ESP",
    "Choose which pets should be visible."
)

addToggle(petVisualBody, "Pet ESP", "PetESP", refreshPetESP)
addToggle(petVisualBody, "My Pets", "PetESPMyPets", refreshPetESP)
addToggle(petVisualBody, "Other Players", "PetESPOthers", refreshPetESP)
addNumber(petVisualBody, "Minimum $/s", "PetESPMinIncome", 0, 1e15)
addAction(petVisualBody, "Refresh Pet ESP", refreshPetESP)

local performanceBody = makeCard(
    visualRight,
    "Performance",
    "Reduce visual effects when you want more FPS."
)

addToggle(performanceBody, "FPS Boost", "FPSBoost", applyFPSBoost)
addToggle(
    performanceBody,
    "Hub Performance Mode",
    "HubPerformanceMode"
)
addNote(
    performanceBody,
    "FPS Boost disables shadows/effects locally. Hub Performance Mode is ON by default and makes inactive THUMBSHUB workers sleep much longer to reduce Luamor/CPU overhead."
)

local visualInfoBody = makeCard(
    visualRight,
    "ESP Filters",
    "Current filters used by the farm and pet overlay."
)
textStat(visualInfoBody, "Egg Mutation", tostring(Settings.EggMutation), true)
textStat(visualInfoBody, "Minimum Egg Luck", tostring(Settings.MinEggLuck), false)
textStat(visualInfoBody, "Pet Min $/s", tostring(Settings.PetESPMinIncome), false)
end


-- ============================================================
-- HIDE PETS
-- ============================================================
do
    local hideLeft, hideRight =
        splitPageColumns(
            hidePetsPage,
            0.56
        )

    local hideBody = makeCard(
        hideLeft,
        "Hide Pets",
        "Local-only pet visibility controls. Pets are not deleted and other players still see them."
    )

    addToggle(
        hideBody,
        "Hide All Pets",
        "HideAllPets",
        refreshPetVisibility
    )

    addToggle(
        hideBody,
        "Hide My Pets",
        "HideMyPets",
        refreshPetVisibility
    )

    addToggle(
        hideBody,
        "Hide Other Players' Pets",
        "HideOtherPets",
        refreshPetVisibility
    )

    local hideInfo = makeCard(
        hideRight,
        "Performance",
        "Hiding pets can reduce visual clutter and improve FPS in busy servers."
    )

    addNote(
        hideInfo,
        "These options only hide pet models/effects on your screen. Auto Farm, feeding, rebirth and pet data continue working normally."
    )
end

-- ============================================================
-- PLAYER MOVEMENT
-- ============================================================
do
    local body = makeCard(movementPage, "Movement", "Adjust your character movement.")
    addToggle(body, "Fly", "Fly")
    addNumber(body, "Fly Speed", "FlySpeed", 10, 500, nil, " st/s")
    addToggle(body, "WalkSpeed", "WalkSpeedEnabled")
    addNumber(body, "Walk Speed", "WalkSpeed", 1, 200, nil, " st/s")
    addToggle(body, "Noclip", "Noclip")
    addNote(body, "Fly: WASD / movement stick, Space up, Ctrl down; camera controls direction. Fly remains available while Auto Farm is enabled and only pauses during a real tween segment. Noclip disables character collision with walls and terrain.")

    local privacyBody = makeCard(
        movementPage,
        "Name Privacy",
        "Local-only privacy controls for your own Roblox name."
    )

    addToggle(
        privacyBody,
        "Hide Name / Show ThumbsHub",
        "HideNames",
        connections.NameMask.Apply
    )

    addNote(
        privacyBody,
        "Shows a ThumbsHub nameplate above your character and locally replaces your own name in supported player-list/leaderboard UI. Other players still see your real Roblox identity."
    )
end

-- ============================================================

-- SERVER HOP
-- ============================================================
do

local hopLeft, hopRight = splitPageColumns(hopPage, 0.58)


local hopBody = makeCard(
    hopLeft,
    "Server Hop",
    "Automatically search servers for a matching egg."
)

addToggle(
    hopBody,
    "Auto Server Hop",
    "AutoServerHop",
    function(enabled)
        Reliability.HopFarmNoTargetSince = 0
        Reliability.HopFarmServerEnteredAt = os.clock()

        if enabled
            and trim(Settings.HopEggNames) ~= "" then

            setStatus(
                "Server Hop Farm • scanning selected eggs"
            )
        elseif enabled then
            setStatus(
                "Auto Server Hop • legacy hunt mode"
            )
        else
            setStatus("Auto Server Hop stopped")
        end
    end
)

addToggle(hopBody, "Stop When Found", "HopStopWhenFound")
addNumber(hopBody, "Hop Delay", "HopDelay", 10, 300, nil, " s")
addNumber(hopBody, "Server Scan Wait", "HopScanWait", 2, 15, nil, " s")

addToggle(
    hopBody,
    "Direct Indexed Hop",
    "DirectIndexedHop"
)

addToggle(
    hopBody,
    "Fallback Scan Hop",
    "IndexFallbackHop"
)

addNumber(
    hopBody,
    "Max Index Age",
    "IndexMaxAge",
    15,
    180,
    nil,
    " s"
)

addAction(
    hopBody,
    "Test Shared Index",
    function()
        task.spawn(function()
            local reported, reportReason =
                Reliability.reportServerIndex(true)

            if not reported then
                setStatus(
                    "Index report failed • "
                    .. tostring(reportReason or "unknown")
                )
                return
            end

            local result, err =
                Reliability.findIndexedServer()

            if result then
                setStatus(
                    "Index connected • found "
                    .. tostring(result.matchedEggs or "selected egg")
                    .. " • "
                    .. tostring(result.playerCount or "?")
                    .. " players"
                )
            else
                setStatus(
                    "Index connected • report sent • "
                    .. tostring(err or "no other matching server yet")
                )
            end
        end)
    end
)

addAction(hopBody, "Check Current Server", function()
    local count =
        Reliability.serverHopMatchingCount()

    if count > 0 then
        setStatus(
            "Server Hop • "
            .. tostring(count)
            .. " selected egg(s) available"
        )
    else
        setStatus(
            "Server Hop • no selected eggs in this server"
        )
    end
end)

addAction(hopBody, "Hop Now", serverHop)

local huntBody = makeCard(
    hopRight,
    "Collect & Hop",
    "Select the eggs to collect in each server. THUMBSHUB collects every matching visible egg, then hops and repeats."
)

addPicker(
    huntBody,
    "Eggs To Collect",
    "HopEggNames",
    (function()
        local ranked = {}

        for eggName, luck in pairs(KNOWN_WORLD_EGG_LUCK) do
            ranked[#ranked + 1] = {
                Name = eggName,
                Luck = tonumber(luck) or 0,
            }
        end

        table.sort(ranked, function(a, b)
            if a.Luck ~= b.Luck then
                return a.Luck < b.Luck
            end
            return a.Name < b.Name
        end)

        local values = {"Any Egg"}

        for _, entry in ipairs(ranked) do
            values[#values + 1] = entry.Name
        end

        return values
    end)(),
    function()
        Reliability.HopFarmNoTargetSince = 0
    end
)

addPicker(huntBody, "Mutation", "HopMutation", MUTATIONS)
addNumber(huntBody, "Minimum Egg Luck", "HopMinLuck", 0, 1e15)

addNote(
    huntBody,
    "Shared Index is connected automatically. THUMBSHUB reports visible eggs in this server, collects your selected eggs, then searches for another recently reported server containing those exact eggs. Fallback Scan Hop is OFF by default, so it will wait instead of blindly cycling random servers."
)
end

-- ============================================================
-- SETTINGS
-- ============================================================
do

local MENU_KEY_OPTIONS = {
    "RightShift",
    "LeftShift",
    "RightControl",
    "LeftControl",
    "RightAlt",
    "LeftAlt",
    "F4",
    "F6",
    "F7",
    "F8",
    "F9",
    "Insert",
    "Home",
    "End",
}

local settingsLeft, settingsRight = splitPageColumns(settingsPage, 0.50)


local communityBody, communityCard = makeCard(
    settingsLeft,
    "Community",
    "Official THUMBSHUB support and updates."
)
communityCard.LayoutOrder = 3

addNote(communityBody, "Official Discord: discord.gg/RDZCNHGznU", true)
addAction(communityBody, "Copy Discord Invite", function()
    local copied, message = copyDiscordInvite()

    if copied then
        setStatus(message)
    else
        setStatus("Discord: " .. message)
    end
end)

local configBody, configCard = makeCard(
    settingsLeft,
    "Config Manager",
    "Create, select, save and load named ThumbsHub profiles."
)
configCard.LayoutOrder = 1

addAction(configBody, "Copy Egg Update Report", function()
    local report = connections.EggUpdateReport
    if report then task.spawn(report) end
end)
addText(configBody, "Config Name", "ConfigProfile", "Default, Farming, Server Hop...")
addPicker(configBody, "Saved Config", "ConfigProfile", CONFIG_PROFILES)

addAction(configBody, "Save / Create Config", function()
    Settings.ConfigProfile = safeConfigName(Settings.ConfigProfile)
    if saveConfig(Settings.ConfigProfile) then
        refreshConfigProfiles()
        for _, fn in ipairs(refreshCallbacks) do
            pcall(fn)
        end
        setStatus("Saved config: " .. Settings.ConfigProfile)
    else
        setStatus("Executor file saving unavailable")
    end
end)

addAction(configBody, "Load Selected Config", function()
    local selected = safeConfigName(Settings.ConfigProfile)
    if loadConfig(selected) then
        for _, fn in ipairs(refreshCallbacks) do
            pcall(fn)
        end

        applyUIScale()
        applyTheme(false)
        footerText.Visible = Settings.UIWatermark
        footerRight.Visible = Settings.UIWatermark
        mainStroke.Transparency = Settings.UIWindowGlow and 0.18 or 0.7
        setStatus("Loaded config: " .. selected)
    else
        setStatus("Config not found: " .. selected)
    end
end)

addAction(configBody, "Refresh Config List", function()
    refreshConfigProfiles()
    for _, fn in ipairs(refreshCallbacks) do
        pcall(fn)
    end
    setStatus("Config list refreshed • " .. tostring(#CONFIG_PROFILES) .. " found")
end)

addAction(configBody, "Delete Selected Config", function()
    local selected = safeConfigName(Settings.ConfigProfile)
    if deleteConfig(selected) then
        refreshConfigProfiles()
        Settings.ConfigProfile = CONFIG_PROFILES[1] or "Default"
        for _, fn in ipairs(refreshCallbacks) do
            pcall(fn)
        end
        setStatus("Deleted config: " .. selected)
    else
        setStatus("Could not delete config: " .. selected)
    end
end, true)

local interfaceBody, interfaceCard = makeCard(
    settingsLeft,
    "Menu",
    "Control how the hub looks and behaves."
)
interfaceCard.LayoutOrder = 2

addToggle(interfaceBody, "Watermark / Footer", "UIWatermark", function(enabled)
    footerText.Visible = enabled
    footerRight.Visible = enabled
end)

addToggle(interfaceBody, "Draggable Window", "UIDraggable")
addToggle(interfaceBody, "Auto Scale To Screen", "UIAutoScale", function()
    applyUIScale()
end)
addNumber(interfaceBody, "UI Scale", "UIScale", 0.75, 1.25, function()
    applyUIScale()
end, "x")

local themeBody, themeCard = makeCard(
    settingsRight,
    "Theme",
    "Make ThumbsHub feel like yours."
)
themeCard.LayoutOrder = 1

addToggle(themeBody, "Window Glow", "UIWindowGlow", function(enabled)
    mainStroke.Transparency = enabled and 0.18 or 0.7
end)
addPicker(themeBody, "UI Theme", "UITheme", UI_THEMES, function()
    applyTheme(true)
    setStatus("UI theme changed to " .. tostring(Settings.UITheme))
end)
addPicker(themeBody, "Accent Colour", "UIAccent", UI_ACCENTS, function()
    applyTheme(true)
    setStatus("Accent colour changed to " .. tostring(Settings.UIAccent))
end)
addPicker(interfaceBody, "Menu Toggle Key", "MenuToggleKey", MENU_KEY_OPTIONS)
addNote(
    interfaceBody,
    "Press the selected key at any time to completely hide or reopen THUMBSHUB. Default: RightShift.",
    true
)

local safetyBody, safetyCard = makeCard(
    settingsRight,
    "Safety & Persistence",
    "Session helpers and script controls."
)
safetyCard.LayoutOrder = 2

addToggle(safetyBody, "Anti AFK", "AntiAFK")
addToggle(safetyBody, "Auto Reconnect", "AutoReconnect")
addAction(safetyBody, "Unload THUMBSHUB", function()
    if ENV.THUMBSHUB_EGG_V1_UNLOAD then
        ENV.THUMBSHUB_EGG_V1_UNLOAD()
    end
end, true)
end

-- ============================================================
-- SEARCH / NAV
-- ============================================================
do

local SEARCH_PAGES = {
    ["home"] = "Home",
    ["dashboard"] = "Home",
    ["announcement"] = "Home",

    ["farm"] = "Auto Farm",
    ["auto farm"] = "Auto Farm",
    ["egg"] = "Auto Farm",
    ["tween"] = "Auto Farm",
    ["basket"] = "Auto Farm",
    ["mutation"] = "Auto Farm",

    ["pet"] = "Pets",
    ["pets"] = "Pets",
    ["place pet"] = "Pets",

    ["feed"] = "Feeds",
    ["feeds"] = "Feeds",
    ["food"] = "Feeds",

    ["radar"] = "Shop",
    ["shop"] = "Shop",
    ["buy"] = "Shop",

    ["progression"] = "Progression",
    ["rebirth"] = "Progression",
    ["hatch luck"] = "Progression",
    ["nest"] = "Progression",

    ["visual"] = "Visuals",
    ["visuals"] = "Visuals",
    ["esp"] = "Visuals",
    ["fps"] = "Visuals",

    ["hide pets"] = "Hide Pets",
    ["hide pet"] = "Hide Pets",
    ["other pets"] = "Hide Pets",

    ["player"] = "Player",
    ["name"] = "Player",
    ["hide name"] = "Player",

    ["webhook"] = "Webhook",
    ["discord webhook"] = "Webhook",

    ["server"] = "Server",
    ["server hop"] = "Server",
    ["hop"] = "Server",
    ["hunt"] = "Server",

    ["settings"] = "Settings",
    ["config"] = "Settings",
    ["theme"] = "Settings",
    ["accent"] = "Settings",
    ["discord"] = "Settings",
}

searchBox.FocusLost:Connect(function(enterPressed)
    if not enterPressed then
        return
    end

    local query = string.lower(trim(searchBox.Text))

    if query == "" then
        return
    end

    local exact = SEARCH_PAGES[query]

    if exact then
        showPage(exact)
        setStatus("Opened " .. exact)
        return
    end

    for keyword, pageName in pairs(SEARCH_PAGES) do
        if keyword:find(query, 1, true) or query:find(keyword, 1, true) then
            showPage(pageName)
            setStatus("Search → " .. pageName)
            return
        end
    end

    setStatus("No page matched: " .. query)
end)

closeButton.MouseButton1Click:Connect(function()
    if ENV.THUMBSHUB_EGG_V1_UNLOAD then
        ENV.THUMBSHUB_EGG_V1_UNLOAD()
    else
        gui:Destroy()
    end
end)

showPage("Home")
end

-- ============================================================
-- LIVE DASHBOARD REFRESH
-- ============================================================
do

task.spawn(function()
    while alive do
        if Settings.HubPerformanceMode
            and main
            and not main.Visible then

            task.wait(4)
            continue
        end

        local basketCurrent, basketMax = getBasketCounts()

        if homeLabels.Session then
            homeLabels.Session.Text = formatSession(os.clock() - sessionStartedAt)
        end

        if homeLabels.Features then
            homeLabels.Features.Text = tostring(countActiveFeatures())
        end

        if homeLabels.FPS then
            homeLabels.FPS.Text = tostring(currentFPS)
        end

        if homeLabels.Ping then
            local pingText = "--"

            pcall(function()
                local stats = game:GetService("Stats")
                local network = stats.Network
                local serverStats = network and network.ServerStatsItem
                local dataPing = serverStats and serverStats:FindFirstChild("Data Ping")

                if dataPing then
                    pingText = dataPing:GetValueString()
                end
            end)

            homeLabels.Ping.Text = pingText
        end

        if homeLabels.Players then
            homeLabels.Players.Text = tostring(#Players:GetPlayers())
        end

        local farmState

        if manualPlacementWaiting then
            farmState = "Manual Nest"
        elseif busyFarm then
            farmState = "Running"
        elseif Settings.AutoFarmEggs then
            farmState = "Waiting"
        else
            farmState = "Idle"
        end

        if homeLabels.Farm then
            homeLabels.Farm.Text = farmState
        end

        if homeLabels.StatusLine then
            homeLabels.StatusLine.Text = statusLabel.Text
        end

        if homeLabels.Grabbed then
            homeLabels.Grabbed.Text = tostring(farmStats.Grabbed)
        end

        if homeLabels.Placed then
            homeLabels.Placed.Text = tostring(farmStats.Placed)
        end

        if homeLabels.Hatched then
            homeLabels.Hatched.Text = tostring(farmStats.Hatched)
        end

        if basketCurrent ~= nil and basketMax ~= nil then
            local basketText = tostring(basketCurrent) .. "/" .. tostring(basketMax)

            if homeLabels.Basket then
                homeLabels.Basket.Text = basketText
            end

            if farmLabels.Basket then
                farmLabels.Basket.Text = basketText
            end
        else
            if homeLabels.Basket then
                homeLabels.Basket.Text = "--"
            end

            if farmLabels.Basket then
                farmLabels.Basket.Text = "--"
            end
        end

        if homeLabels.Target then
            homeLabels.Target.Text = tostring(farmStats.LastTarget)
        end

        if farmLabels.Target then
            farmLabels.Target.Text = tostring(farmStats.LastTarget)
        end

        if farmLabels.State then
            farmLabels.State.Text = farmState
        end

        if farmLabels.Grabbed then
            farmLabels.Grabbed.Text = tostring(farmStats.Grabbed)
        end

        if farmLabels.Placed then
            farmLabels.Placed.Text = tostring(farmStats.Placed)
        end

        if farmLabels.Hatched then
            farmLabels.Hatched.Text = tostring(farmStats.Hatched)
        end

        if rebirthUILabels.RequiredEgg then
            rebirthUILabels.RequiredEgg.Text =
                tostring(rebirthRuntime.RequiredEgg or "Not detected")
        end

        if rebirthUILabels.State then
            rebirthUILabels.State.Text =
                tostring(rebirthRuntime.State or "Idle")
        end

        if rebirthUILabels.Mapping then
            rebirthUILabels.Mapping.Text =
                tostring(rebirthRuntime.MappingSource or "None")
        end

        if rebirthUILabels.RequiredPet then
            rebirthUILabels.RequiredPet.Text =
                tostring(getRebirthRequiredPetName() or "Not detected")
        end

        if rebirthUILabels.Placement then
            if rebirthRuntime.LockActive then
                rebirthUILabels.Placement.Text =
                    tostring(
                        rebirthRuntime.LockState
                        or "Waiting for hatch"
                    )
            else
                rebirthUILabels.Placement.Text =
                    tostring(
                        rebirthRuntime.LastPlacementState
                        or "Idle"
                    )
            end
        end

        task.wait(
            Settings.HubPerformanceMode
                and 2.0
                or 0.5
        )
    end
end)
end

-- BUILD 64 • Egg/Pet game smooth UI dragging
-- Smooth dragging
do
    local UserInputService =
        game:GetService("UserInputService")

    local RunService =
        game:GetService("RunService")

    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    local targetPos =
        main.Position

    -- Higher = follows the cursor more tightly.
    -- 28 gives a smooth feel without making the menu lag behind.
    local DRAG_SMOOTHNESS = 28

    local function updateTarget(inputPosition)
        if not dragging
            or not dragStart
            or not startPos then
            return
        end

        local delta =
            inputPosition
            - dragStart

        targetPos =
            UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
    end

    top.InputBegan:Connect(function(input)
        if not Settings.UIDraggable then
            return
        end

        if input.UserInputType
                == Enum.UserInputType.MouseButton1
            or input.UserInputType
                == Enum.UserInputType.Touch then

            dragging = true
            dragInput = input
            dragStart = input.Position

            -- Start from the position currently on-screen so there is no
            -- little jump when beginning a drag while the previous movement
            -- is still easing.
            startPos = main.Position
            targetPos = main.Position

            input.Changed:Connect(function()
                if input.UserInputState
                    == Enum.UserInputState.End then

                    dragging = false
                    dragInput = nil
                end
            end)
        end
    end)

    connect(
        UserInputService.InputChanged,
        function(input)
            if not dragging then
                return
            end

            if input.UserInputType
                    == Enum.UserInputType.MouseMovement
                or input.UserInputType
                    == Enum.UserInputType.Touch then

                updateTarget(
                    input.Position
                )
            end
        end
    )

    connect(
        UserInputService.InputEnded,
        function(input)
            if input == dragInput
                or input.UserInputType
                    == Enum.UserInputType.MouseButton1
                or input.UserInputType
                    == Enum.UserInputType.Touch then

                dragging = false
                dragInput = nil
            end
        end
    )

    -- Move the actual window once per rendered frame instead of snapping the
    -- frame to every raw mouse event. This is what removes the choppy/jittery
    -- feeling on Windows and also makes touch dragging smoother.
    connect(
        RunService.RenderStepped,
        function(dt)
            if not Settings.UIDraggable
                or not dragging
                or not main.Visible then

                if not dragging then
                    targetPos = main.Position
                end

                return
            end

            local alpha =
                1
                - math.exp(
                    -DRAG_SMOOTHNESS
                    * math.clamp(
                        dt,
                        0,
                        0.1
                    )
                )

            main.Position =
                main.Position:Lerp(
                    targetPos,
                    alpha
                )
        end
    )
end

-- BUILD141: the old minimize resized the shell and could leave the UI in a
-- broken state.  Hide the whole hub instead and leave a small draggable TH
-- launcher that always reopens it.
local reopenButton = Instance.new("TextButton")
reopenButton.Name = "ThumbsHubReopen"
reopenButton.Size = UDim2.fromOffset(48, 48)
reopenButton.Position = UDim2.new(0, 22, 0.5, -24)
reopenButton.BackgroundColor3 = COLORS.Panel
reopenButton.BorderSizePixel = 0
reopenButton.Font = Enum.Font.GothamBold
reopenButton.TextSize = 14
reopenButton.TextColor3 = COLORS.Accent
reopenButton.Text = "TH"
reopenButton.Visible = false
reopenButton.Active = true
reopenButton.Draggable = true
reopenButton.Parent = gui

local reopenCorner = Instance.new("UICorner")
reopenCorner.CornerRadius = UDim.new(0, 12)
reopenCorner.Parent = reopenButton

local reopenStroke = Instance.new("UIStroke")
reopenStroke.Color = COLORS.Accent
reopenStroke.Transparency = 0.20
reopenStroke.Thickness = 1.2
reopenStroke.Parent = reopenButton

minimize.MouseButton1Click:Connect(function()
    main.Visible = false
    reopenButton.Visible = true
end)

reopenButton.MouseButton1Click:Connect(function()
    main.Visible = true
    reopenButton.Visible = false
end)


    return gui
end


local gui = buildThumbsHubUI();

-- BUILD 67: legacy premium skin removed cleanly.
-- The base shell now owns the Slayers-style appearance and theme remapping.

-- Show the ThumbsHub community screen once per Roblox user.
-- Pressing Continue records a small local marker keyed by UserId.
-- Copying the invite alone does NOT mark the welcome as completed.
--
-- Marker convention is intentionally shared across ThumbsHub games:
--   THUMBSHUB/community_welcome_<UserId>.txt
--
-- If file APIs are unavailable, getgenv provides a same-client-session fallback.
ENV.THUMBSHUB_COMMUNITY_WELCOME_USERS =
    ENV.THUMBSHUB_COMMUNITY_WELCOME_USERS
    or {}

ENV.THUMBSHUB_HAS_SEEN_COMMUNITY =
    function()
        local userId =
            tonumber(player.UserId) or 0

        if ENV.THUMBSHUB_COMMUNITY_WELCOME_USERS[userId] then
            return true
        end

        local markerPath =
            "THUMBSHUB/community_welcome_"
            .. tostring(userId)
            .. ".txt"

        if typeof(isfile) == "function" then
            local ok, exists =
                pcall(
                    isfile,
                    markerPath
                )

            if ok and exists then
                ENV.THUMBSHUB_COMMUNITY_WELCOME_USERS[userId] =
                    true

                return true
            end
        elseif typeof(readfile) == "function" then
            local ok =
                pcall(
                    readfile,
                    markerPath
                )

            if ok then
                ENV.THUMBSHUB_COMMUNITY_WELCOME_USERS[userId] =
                    true

                return true
            end
        end

        return false
    end

ENV.THUMBSHUB_MARK_COMMUNITY_SEEN =
    function()
        local userId =
            tonumber(player.UserId) or 0

        ENV.THUMBSHUB_COMMUNITY_WELCOME_USERS[userId] =
            true

        local markerPath =
            "THUMBSHUB/community_welcome_"
            .. tostring(userId)
            .. ".txt"

        pcall(function()
            if typeof(makefolder) == "function" then
                local folderExists = false

                if typeof(isfolder) == "function" then
                    local ok, exists =
                        pcall(
                            isfolder,
                            "THUMBSHUB"
                        )

                    folderExists =
                        ok and exists == true
                end

                if not folderExists then
                    pcall(
                        makefolder,
                        "THUMBSHUB"
                    )
                end
            end

            if typeof(writefile) == "function" then
                writefile(
                    markerPath,
                    "ThumbsHub community welcome acknowledged\n"
                    .. "UserId="
                    .. tostring(userId)
                )
            end
        end)

        return true
    end

;(function()
    local mainWindow = gui:FindFirstChild("Main")

    if ENV.THUMBSHUB_HAS_SEEN_COMMUNITY() then
        if mainWindow then
            mainWindow.Visible = true
        end

        return
    end

    if mainWindow then
        mainWindow.Visible = false
    end

    local overlay = Instance.new("Frame")
    overlay.Name = "CommunityWelcome"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.fromRGB(4, 4, 6)
    overlay.BackgroundTransparency = 0.08
    overlay.Active = true
    overlay.ZIndex = 200
    overlay.Parent = gui

    local card = Instance.new("Frame")
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.Size = UDim2.fromOffset(510, 360)
    card.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
    card.BorderSizePixel = 0
    card.ZIndex = 201
    card.Parent = overlay

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 18)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(245, 118, 42)
    cardStroke.Transparency = 0.25
    cardStroke.Thickness = 1.4
    cardStroke.Parent = card

    local cardGradient = Instance.new("UIGradient")
    cardGradient.Rotation = 115
    cardGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 22, 24)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 18)),
    })
    cardGradient.Parent = card

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(1, 0, 0, 3)
    accent.BorderSizePixel = 0
    accent.BackgroundColor3 = Color3.fromRGB(245, 118, 42)
    accent.ZIndex = 202
    accent.Parent = card

    local accentGradient = Instance.new("UIGradient")
    accentGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 118, 42)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 173, 92)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 118, 42)),
    })
    accentGradient.Parent = accent

    local logo = Instance.new("Frame")
    logo.Position = UDim2.fromOffset(28, 29)
    logo.Size = UDim2.fromOffset(54, 54)
    logo.BackgroundColor3 = Color3.fromRGB(245, 118, 42)
    logo.BorderSizePixel = 0
    logo.ZIndex = 202
    logo.Parent = card

    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 14)
    logoCorner.Parent = logo

    local logoGradient = Instance.new("UIGradient")
    logoGradient.Rotation = 35
    logoGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 172, 88)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(218, 72, 21)),
    })
    logoGradient.Parent = logo

    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.fromScale(1, 1)
    logoText.BackgroundTransparency = 1
    logoText.Font = Enum.Font.GothamBold
    logoText.TextSize = 28
    logoText.Text = "👍"
    logoText.TextColor3 = Color3.new(1, 1, 1)
    logoText.ZIndex = 203
    logoText.Parent = logo

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(98, 30)
    title.Size = UDim2.new(1, -126, 0, 30)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.TextColor3 = Color3.fromRGB(248, 247, 246)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "ThumbsHub"
    title.ZIndex = 202
    title.Parent = card

    local subtitle = Instance.new("TextLabel")
    subtitle.Position = UDim2.fromOffset(98, 61)
    subtitle.Size = UDim2.new(1, -126, 0, 18)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.TextColor3 = Color3.fromRGB(171, 166, 163)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Text = "Community • Updates • Support"
    subtitle.ZIndex = 202
    subtitle.Parent = card

    local info = Instance.new("TextLabel")
    info.Position = UDim2.fromOffset(28, 106)
    info.Size = UDim2.new(1, -56, 0, 56)
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.Gotham
    info.TextSize = 13
    info.TextWrapped = true
    info.TextColor3 = Color3.fromRGB(218, 214, 211)
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.Text = "Join the ThumbsHub Discord for announcements, support, bug reports and new feature drops. Joining is optional."
    info.ZIndex = 202
    info.Parent = card

    local inviteBox = Instance.new("Frame")
    inviteBox.Position = UDim2.fromOffset(28, 172)
    inviteBox.Size = UDim2.new(1, -56, 0, 46)
    inviteBox.BackgroundColor3 = Color3.fromRGB(27, 27, 34)
    inviteBox.BorderSizePixel = 0
    inviteBox.ZIndex = 202
    inviteBox.Parent = card

    local inviteCorner = Instance.new("UICorner")
    inviteCorner.CornerRadius = UDim.new(0, 10)
    inviteCorner.Parent = inviteBox

    local inviteStroke = Instance.new("UIStroke")
    inviteStroke.Color = Color3.fromRGB(72, 68, 68)
    inviteStroke.Transparency = 0.45
    inviteStroke.Parent = inviteBox

    local invite = Instance.new("TextLabel")
    invite.Position = UDim2.fromOffset(14, 0)
    invite.Size = UDim2.new(1, -28, 1, 0)
    invite.BackgroundTransparency = 1
    invite.Font = Enum.Font.GothamMedium
    invite.TextSize = 12
    invite.TextColor3 = Color3.fromRGB(244, 241, 239)
    invite.TextXAlignment = Enum.TextXAlignment.Left
    invite.Text = DISCORD_INVITE
    invite.ZIndex = 203
    invite.Parent = inviteBox

    local feedback = Instance.new("TextLabel")
    feedback.Position = UDim2.fromOffset(28, 226)
    feedback.Size = UDim2.new(1, -56, 0, 20)
    feedback.BackgroundTransparency = 1
    feedback.Font = Enum.Font.Gotham
    feedback.TextSize = 10
    feedback.TextColor3 = Color3.fromRGB(154, 149, 146)
    feedback.TextXAlignment = Enum.TextXAlignment.Left
    feedback.Text = "Copy the invite or continue straight into ThumbsHub."
    feedback.ZIndex = 202
    feedback.Parent = card

    local copyButton = Instance.new("TextButton")
    copyButton.Position = UDim2.fromOffset(28, 263)
    copyButton.Size = UDim2.new(0.5, -34, 0, 48)
    copyButton.BackgroundColor3 = Color3.fromRGB(225, 91, 25)
    copyButton.BorderSizePixel = 0
    copyButton.AutoButtonColor = false
    copyButton.Font = Enum.Font.GothamBold
    copyButton.TextSize = 13
    copyButton.TextColor3 = Color3.new(1, 1, 1)
    copyButton.Text = "Copy Discord Invite"
    copyButton.ZIndex = 202
    copyButton.Parent = card

    local copyCorner = Instance.new("UICorner")
    copyCorner.CornerRadius = UDim.new(0, 11)
    copyCorner.Parent = copyButton

    local continueButton = Instance.new("TextButton")
    continueButton.Position = UDim2.new(0.5, 6, 0, 263)
    continueButton.Size = UDim2.new(0.5, -34, 0, 48)
    continueButton.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
    continueButton.BorderSizePixel = 0
    continueButton.AutoButtonColor = false
    continueButton.Font = Enum.Font.GothamBold
    continueButton.TextSize = 13
    continueButton.TextColor3 = Color3.fromRGB(245, 243, 241)
    continueButton.Text = "Continue to ThumbsHub"
    continueButton.ZIndex = 202
    continueButton.Parent = card

    local continueCorner = Instance.new("UICorner")
    continueCorner.CornerRadius = UDim.new(0, 11)
    continueCorner.Parent = continueButton

    local dismissed = false

    connect(copyButton.Activated, function()
        local copied = copyDiscordInvite()

        if copied then
            feedback.Text = "Discord invite copied to clipboard."
            feedback.TextColor3 = Color3.fromRGB(102, 216, 148)
        else
            feedback.Text = "Clipboard unavailable • " .. DISCORD_INVITE
            feedback.TextColor3 = Color3.fromRGB(235, 177, 88)
        end
    end)

    connect(continueButton.Activated, function()
        if dismissed then
            return
        end

        dismissed = true

        -- Remember this Roblox account. Future ThumbsHub executions on this
        -- executor/device skip the community welcome entirely.
        ENV.THUMBSHUB_MARK_COMMUNITY_SEEN()

        TweenService:Create(
            card,
            TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            {Position = UDim2.fromScale(0.5, 0.52)}
        ):Play()

        task.wait(0.13)

        overlay:Destroy()

        if mainWindow then
            mainWindow.Visible = true
            mainWindow.Position = UDim2.new(0.5, -480, 0.5, -292)

            TweenService:Create(
                mainWindow,
                TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Position = UDim2.new(0.5, -480, 0.5, -310)}
            ):Play()
        end
    end)

    while alive and gui.Parent and not dismissed do
        task.wait(0.1)
    end

    if not alive or not gui.Parent then
        return
    end
end)();

-- BUILD141: menu keybind is handled before gameProcessed checks so keys such as
-- RightShift/Alt/F-keys still work when Roblox/CoreGui consumes the input.
-- Keep the ScreenGui enabled and hide only the main window so the TH reopen
-- launcher remains clickable at all times.
local lastMenuToggleAt = 0
connect(UserInputService.InputBegan, function(input, gameProcessed)
    local selectedName = tostring(Settings.MenuToggleKey or "RightShift")
    local selectedKey = Enum.KeyCode[selectedName]

    if selectedKey and input.KeyCode == selectedKey then
        local now = os.clock()
        if now - lastMenuToggleAt < 0.18 then
            return
        end
        lastMenuToggleAt = now

        local mainWindow = gui:FindFirstChild("Main")
        local launcher = gui:FindFirstChild("ThumbsHubReopen")

        -- Never disable the ScreenGui; otherwise both the key-controlled UI and
        -- the reopen launcher disappear together.
        gui.Enabled = true

        if mainWindow then
            local wasVisible = mainWindow.Visible
            mainWindow.Visible = not wasVisible
            if launcher then
                launcher.Visible = wasVisible
            end
            setStatus((wasVisible and "Menu hidden • " or "Menu opened • ") .. selectedName)
        end
        return
    end

    if gameProcessed then
        return
    end
end)

-- ============================================================
-- EVENT WATCHERS
-- ============================================================
-- Keep setup-only locals inside anonymous functions here.
-- The Egg/Pet master is close to Luau's 200 active-local register ceiling.

;(function()
    local renderedEggs =
        workspace:FindFirstChild(
            "RenderedEggs"
        )

    if not renderedEggs then
        return
    end

    connect(
        renderedEggs.ChildAdded,
        function()
            Reliability.IndexDirty = true

            task.delay(
                0.3,
                refreshEggESP
            )
        end
    )

    connect(
        renderedEggs.ChildRemoved,
        function(child)
            Reliability.IndexDirty = true

            if lastClaimedEgg == child then
                announceClaimedEgg(child)
                lastClaimedEgg = nil
            end

            task.delay(
                0.3,
                refreshEggESP
            )
        end
    )
end)()

task.spawn(function()
    while alive do
        local plot = getOwnPlot()
        local pets = plot and plot:FindFirstChild("Pets")

        if pets and not pets:GetAttribute("THUMBSHUB_WATCHED") then
            pets:SetAttribute("THUMBSHUB_WATCHED", true)

            connect(pets.ChildAdded, function(pet)
                learnPendingHatchMapping(pet)
                announcePet(pet)
                task.delay(0.5, refreshPetESP)
            end)

            connect(pets.ChildRemoved, function()
                task.delay(0.5, refreshPetESP)
            end)
        end

        task.wait(
            Settings.HubPerformanceMode
                and 8
                or 3
        )
    end
end)


-- Local pet visibility watcher. Event-driven so it does no repeated full scan
-- unless one of the hide-pet options is actually enabled.
;(function()
    local plots = workspace:FindFirstChild("Plots")

    if not plots then
        return
    end

    connect(
        plots.DescendantAdded,
        function(object)
            if not petHideEnabled() then
                return
            end

            local current = object

            while current
                and current.Parent
                and current.Parent ~= plots do

                if current.Parent.Name == "Pets" then
                    task.delay(
                        0.08,
                        function()
                            if alive
                                and current
                                and current.Parent
                                and petHideEnabled() then

                                local mine =
                                    isMyPetModel(current)

                                if Settings.HideAllPets
                                    or (
                                        mine
                                        and Settings.HideMyPets
                                    )
                                    or (
                                        not mine
                                        and Settings.HideOtherPets
                                    ) then

                                    hidePetModelLocal(current)
                                end
                            end
                        end
                    )

                    break
                end

                current = current.Parent
            end
        end
    )
end)()

-- Weather server signal listener.
-- This does not predict a server-only future RNG roll; it updates the hub at the
-- earliest point the server actually tells this client which weather was rolled.
;(function()
    local gameRemotes =
        ReplicatedStorage:FindFirstChild("Remotes")
        and ReplicatedStorage.Remotes:FindFirstChild("Game")

    local addWeather =
        gameRemotes
        and gameRemotes:FindFirstChild("AddWeather")

    if addWeather and addWeather:IsA("RemoteEvent") then
        connect(addWeather.OnClientEvent, function(...)
            local packed = table.pack(...)
            local rolled

            for i = 1, packed.n do
                rolled =
                    connections.WeatherForecast.FindWeatherInValue(
                        packed[i]
                    )

                if rolled then
                    break
                end
            end

            if rolled then
                local wf =
                    connections.WeatherForecast

                -- A fresh event can repeat the same weather after its old timer expired.
                if wf.ForcedSunny then

                    wf.ForcedSunny =
                        false

                    wf.ExpiredWeather =
                        nil

                    wf.ForcedSunnyAt = nil
                    wf.CurrentEndRaw = nil
                    wf.CurrentEndSeconds = nil
                    wf.CurrentEndSyncClock = nil
                end

                connections.WeatherForecast.ServerSignal =
                    "Server rolled " .. rolled

                connections.WeatherForecast.Record(rolled)
                connections.WeatherForecast.Refresh()
            else
                connections.WeatherForecast.ServerSignal =
                    "Weather event received • waiting for UI name"

                connections.WeatherForecast.Refresh()
            end
        end)
    else
        connections.WeatherForecast.ServerSignal =
            "AddWeather remote unavailable • UI tracking active"
    end
end)()

-- Live weather watcher.
-- WeatherDescription is normally the source of truth, but its old storm name
-- can remain visible after TimeLeft reaches 0. In that specific case the hub
-- advances locally to Sunny and ignores the stale name until the game changes.
task.spawn(function()
    while alive do
        local mainGui =
            playerGui:FindFirstChild(
                "Main"
            )

        local desc =
            mainGui
            and mainGui:FindFirstChild(
                "WeatherDescription"
            )

        local weatherName =
            desc
            and desc:FindFirstChild(
                "WeatherName"
            )

        local timeLeft =
            desc
            and desc:FindFirstChild(
                "TimeLeft"
            )

        if weatherName
            and weatherName:IsA("TextLabel")
            and connections.WeatherForecast.GuiVisible(weatherName) then

            local current =
                trim(
                    weatherName.Text
                )

            local displayCurrent,
                staleExpired =
                connections.WeatherForecast.ResolveDisplayedCurrent(
                    current, timeLeft
                )

            connections.WeatherForecast.Current =
                displayCurrent

            local normalCurrent =
                connections.WeatherForecast.NormaliseWeather(
                    displayCurrent
                )

            if normalCurrent
                and normalCurrent
                    == connections.WeatherForecast.NextConfirmedWeather then

                connections.WeatherForecast.NextRaw = nil
                connections.WeatherForecast.NextSeconds = nil
                connections.WeatherForecast.NextSyncClock = nil
                connections.WeatherForecast.NextConfirmedAt = nil
                connections.WeatherForecast.NextConfirmedWeather = nil
            end

            local remaining

            if not staleExpired
                and normalCurrent ~= "Sunny" then

                remaining =
                    connections.WeatherForecast.UpdateCurrentEndTimer(
                        displayCurrent,
                        timeLeft
                    )

                if remaining ~= nil
                    and remaining <= 0.05 then

                    connections.WeatherForecast.ForceSunnyAfterExpiry(
                        displayCurrent
                    )

                    displayCurrent = "Awaiting weather update"
                    normalCurrent = nil
                end
            elseif normalCurrent == "Sunny" then
                connections.WeatherForecast.CurrentTimerWeather =
                    "Sunny"

                connections.WeatherForecast.CurrentEndRaw =
                    nil

                connections.WeatherForecast.CurrentEndSeconds =
                    nil

                connections.WeatherForecast.CurrentEndSyncClock =
                    nil
            end

            if not staleExpired
                and current ~= ""
                and current ~= lastWeather then

                lastWeather =
                    current

                connections.WeatherForecast.Record(
                    current
                )

                local normal =
                    connections.WeatherForecast.NormaliseWeather(
                        current
                    )

                if normal then
                    connections.WeatherForecast.ServerSignal =
                        "Confirmed active • "
                        .. normal
                end

                if Settings.WebhookWeather then
                    sendWebhook(
                        "Weather Started",
                        {
                            Weather =
                                current,
                        }
                    )
                end
            end

            connections.WeatherForecast.UpdateUpcomingForecast()

            connections.WeatherForecast.UpdateSunnyLiveTimer()

            connections.WeatherForecast.Refresh()
        else
            connections.WeatherForecast.Current = "Unknown — weather HUD unavailable"

            connections.WeatherForecast.ForcedSunny =
                false

            connections.WeatherForecast.ExpiredWeather =
                nil

            connections.WeatherForecast.ForcedSunnyAt =
                nil

            connections.WeatherForecast.CurrentTimerWeather =
                "Sunny"

            connections.WeatherForecast.CurrentEndRaw =
                nil

            connections.WeatherForecast.CurrentEndSeconds =
                nil

            connections.WeatherForecast.CurrentEndSyncClock =
                nil

            connections.WeatherForecast.UpdateUpcomingForecast()

            connections.WeatherForecast.UpdateSunnyLiveTimer()

            connections.WeatherForecast.Refresh()
        end

        task.wait(
            Settings.HubPerformanceMode
                and 0.50
                or 0.15
        )
    end
end)

-- Local name mask refresh. This loop is effectively asleep unless enabled.
task.spawn(function()
    while alive do
        if Settings.HideNames then
            connections.NameMask.Refresh()
        end

        task.wait(
            Settings.HubPerformanceMode
                and 12
                or 5
        )
    end
end)

-- Anti AFK
connect(player.Idled, function()
    if not Settings.AntiAFK then
        return
    end

    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)

-- Auto reconnect
task.spawn(function()
    local promptGui = CoreGui:FindFirstChild("RobloxPromptGui")
    local overlay = promptGui and promptGui:FindFirstChild("promptOverlay")

    if overlay then
        connect(overlay.ChildAdded, function(child)
            if not Settings.AutoReconnect then
                return
            end

            task.delay(2, function()
                if alive and Settings.AutoReconnect and child.Parent then
                    pcall(function()
                        TeleportService:Teleport(game.PlaceId, player)
                    end)
                end
            end)
        end)
    end
end)

-- ============================================================
-- MAIN LOOPS
-- ============================================================

-- BUILD127: TP is the fixed/default and ONLY egg-farm travel method for this run.
Settings.InstantEggTravel = true
connections.InstantTravel.SessionRejected = false
connections.InstantTravel.RetryAfter = 0

-- Defensive reset: a fresh the repaired farm build execution must always start with
-- the farm worker unlocked.
busyFarm = false
manualPlacementWaiting = false

-- Farm
task.spawn(function()
    while alive do
        local hopCollectRequested =
            Reliability.serverHopCollectMode()

        -- BUILD154: don't run rebirth/world selection scans every 0.45s
        -- when the farm, rebirth and server-hop collection are all idle.
        if not Settings.AutoFarmEggs
            and not Settings.AutoRebirth
            and not hopCollectRequested then

            if Settings.AutoHatchEggs then
                hatchReadyEggs()
            end

            task.wait(
                Settings.HubPerformanceMode
                    and 2.0
                    or 0.75
            )

            continue
        end

        local rebirthTargetName = nil
        local rebirthDiscovery = false

        if Settings.AutoRebirth then
            local rebirthOk, rebirthErr = pcall(function()
                rebirthTargetName = getRebirthFarmTargetName()
                rebirthDiscovery = rebirthNeedsWorldDiscovery()
            end)

            if not rebirthOk then
                rebirthTargetName = nil
                rebirthDiscovery = false
                rebirthRuntime.State = "Rebirth resolver error"
                setStatus("Auto Rebirth error • normal farm kept alive")
                warn("[THUMBSHUB] Auto Rebirth resolver: " .. tostring(rebirthErr))
            end
        end

        local waitingForRebirthHatch =
            Settings.AutoRebirth
            and rebirthWaitingForPlacedEgg()
            or false

        local farmRequested =
            (not waitingForRebirthHatch)
            and (
                Settings.AutoFarmEggs
                or rebirthTargetName ~= nil
                or rebirthDiscovery
                or hopCollectRequested
            )

        if waitingForRebirthHatch then
            local waitEgg =
                rebirthRuntime.DiscoveryEggName
                or rebirthRuntime.WaitingEggName
                or rebirthRuntime.RequiredEgg
                or "rebirth egg"

            setStatus(
                "Auto Rebirth • "
                .. tostring(waitEgg)
                .. " is on plot • waiting for hatch"
            )
        end

        if farmRequested and not busyFarm then
            busyFarm = true

            local thisGeneration = farmMoveGeneration
            local cycleRebirthTarget = rebirthTargetName

            local function farmStillEnabled()
                return alive
                    and thisGeneration == farmMoveGeneration
                    and not rebirthWaitingForPlacedEgg()
                    and (
                        Settings.AutoFarmEggs
                        or Reliability.serverHopCollectMode()
                        or (
                            Settings.AutoRebirth
                            and (cycleRebirthTarget ~= nil or rebirthDiscovery)
                        )
                    )
            end

            local currentBasket, maxBasket, basketState =
                Reliability.getBasketState()

            if basketState == "empty"
                and not connections.EggReturn.Active
                and Reliability.LastCarriedEggName ~= nil then

                -- No return verification is pending; clear stale carry metadata.
                Reliability.clearCarriedEgg()
                lastClaimedEgg = nil
            end

            -- ============================================================
            -- ONE-EGG RETURN / ABSOLUTE PRIORITY
            -- ============================================================
            -- If an egg is already in hand/basket, resolve that ONE egg first.
            -- Never select a second world egg until the game has returned the
            -- current egg home and the basket has cleared.
            if Reliability.hasUnresolvedFarmCargo() then

                local carriedEggName =
                    Reliability.getCarriedEggName()
                    or Reliability.LastCarriedEggName
                    or tostring(farmStats.LastTarget or "egg")

                local function carryStillEnabled()
                    return alive
                        and thisGeneration == farmMoveGeneration
                        and (
                            Settings.AutoFarmEggs
                            or Settings.AutoRebirth
                            or Reliability.serverHopCollectMode()
                        )
                end

                local carryWasDiscovery =
                    Reliability.LastCarryWasDiscovery == true
                local carryWasRebirth =
                    Reliability.LastCarryWasRebirth == true
                local carryStoredTarget =
                    Reliability.LastCarryRebirthTarget
                local carryStoredRequiredPet =
                    Reliability.LastCarryRequiredPet

                if basketState == "full" then
                    setStatus(
                        (
                            carryWasRebirth or carryWasDiscovery
                        )
                        and (
                            "Auto Rebirth • basket full "
                            .. tostring(currentBasket or "?")
                            .. "/"
                            .. tostring(maxBasket or "?")
                            .. " • returning "
                            .. tostring(carriedEggName)
                        )
                        or (
                            "Auto Farm • basket full "
                            .. tostring(currentBasket or "?")
                            .. "/"
                            .. tostring(maxBasket or "?")
                            .. " • returning "
                            .. tostring(carriedEggName)
                        )
                    )
                else
                    setStatus(
                        (
                            carryWasRebirth or carryWasDiscovery
                        )
                        and (
                            "Auto Rebirth • returning "
                        .. tostring(carriedEggName)
                        .. " home"
                    )
                    or (
                        "Auto Farm • returning "
                        .. tostring(carriedEggName)
                        .. " home"
                    )
                    )
                end

                local returned =
                    Reliability.returnBasketEggHome(
                        carryStillEnabled,
                        carriedEggName,
                        currentBasket
                    )

                if returned then
                    -- Rebirth collects exactly ONE required/candidate egg and
                    -- then waits for the user to place it manually.
                    if Settings.AutoRebirth
                        and (carryWasRebirth or carryWasDiscovery) then

                        if carryWasDiscovery then
                            rebirthRuntime.DiscoveryEggName =
                                tostring(carriedEggName)

                            rebirthRuntime.DiscoveryRequiredPet =
                                carryStoredRequiredPet
                                or getRebirthRequiredPetName()

                            rebirthRuntime.DiscoveryManualPlacedSeen = false
                            rebirthRuntime.DiscoveryCollectedAt = os.clock()

                            rebirthRuntime.State =
                                "Collected "
                                .. tostring(carriedEggName)
                                .. " • place it manually"
                        else
                            rebirthRuntime.RequiredEgg =
                                carryStoredTarget
                                or tostring(carriedEggName)

                            rebirthRuntime.WaitingEggName =
                                tostring(carriedEggName)

                            rebirthRuntime.WaitStartedAt = os.clock()
                            rebirthRuntime.ManualPlacedSeen = false
                            rebirthRuntime.ManualDisappearAt = nil

                            rebirthRuntime.State =
                                "Collected "
                                .. tostring(carriedEggName)
                                .. " • place it manually"
                        end
                    end
                end

                busyFarm = false
                task.wait(0.20)
                continue
            end

            if Settings.AutoSellBasketBeforeFarm and currentBasket and currentBasket > 0 then
                local shouldSell = (not Settings.SellOnlyWhenFull)
                    or (maxBasket and maxBasket > 0 and currentBasket >= maxBasket)

                if shouldSell and farmStillEnabled() then
                    local sold = sellCurrentBasket(farmStillEnabled)

                    if not sold then
                        busyFarm = false
                        task.wait(0.5)
                        continue
                    end
                end
            end

            currentBasket, maxBasket, basketState =
                Reliability.getBasketState()

            if Reliability.hasUnresolvedFarmCargo() then
                busyFarm = false
                task.wait(0.12)
                continue
            end

            local egg = nil
            local farmingForRebirth = false
            local farmingForServerHop = false

            if cycleRebirthTarget then
                egg = chooseFarmEgg(cycleRebirthTarget)
                farmingForRebirth = egg ~= nil
            end

            -- Auto Rebirth discovery has its OWN selector. It must never fall
            -- through to Smart Targeting / Best Egg First.
            if not egg and rebirthDiscovery then
                local requiredPet = getRebirthRequiredPetName()

                local discoveryOk, discoveryEgg = pcall(
                    chooseRebirthDiscoveryEgg,
                    requiredPet
                )

                if discoveryOk then
                    egg = discoveryEgg
                    farmingForRebirth = false
                else
                    warn(
                        "[THUMBSHUB] Rebirth discovery selector: "
                        .. tostring(discoveryEgg)
                    )

                    -- Disable discovery for THIS cycle only so ordinary Auto Farm
                    -- can still run instead of leaving the worker stuck.
                    rebirthDiscovery = false
                    rebirthRuntime.State = "Discovery selector error"
                    setStatus("Rebirth discovery error • normal farm continuing")
                end
            end

            -- BUILD142 Collect & Hop mode uses the exact existing farm mechanics,
            -- but selects only from the Server page's multi-select egg list.
            if not egg
                and not rebirthDiscovery
                and Reliability.serverHopCollectMode() then

                egg =
                    Reliability.chooseServerHopEgg()

                farmingForServerHop =
                    egg ~= nil
            end

            -- Normal Auto Farm stays unchanged outside Collect & Hop mode.
            -- When Collect & Hop is active, do not grab unrelated farm-filter
            -- eggs after the selected server-hop eggs have been cleared.
            if not egg
                and Settings.AutoFarmEggs
                and not rebirthDiscovery
                and not Reliability.serverHopCollectMode() then

                egg = chooseFarmEgg()
                farmingForRebirth = false
            end

            if egg and egg.Parent and farmStillEnabled() then
                local prompt = getPickupPrompt(egg)
                if prompt then
                    local timeLeft = getWorldEggTimeLeft(egg)
                    local timeLeftSampleClock = os.clock()
                    local _, luckText = getEggLuck(egg)
                    local mutation = getEggMutation(egg)

                    local targetText

                    if farmingForRebirth then
                        targetText = "Auto Rebirth • getting required " .. getWorldEggName(egg)
                    elseif farmingForServerHop then
                        targetText =
                            "Server Hop Farm • collecting "
                            .. getWorldEggName(egg)
                    elseif rebirthDiscovery then
                        targetText =
                            "Auto Rebirth discovery • testing "
                            .. getWorldEggName(egg)
                            .. " for "
                            .. tostring(getRebirthRequiredPetName() or "required pet")
                            .. " • step "
                            .. tostring(rebirthRuntime.DiscoverySelectedIndex or "?")
                            .. "/"
                            .. tostring(#REBIRTH_DISCOVERY_EGG_ORDER)
                    else
                        targetText =
                            (
                                Reliability.isUndergroundFarm()
                                and "Underground Farm: "
                                or "Farming: "
                            )
                            .. getWorldEggName(egg)
                            .. " • "
                            .. tostring(luckText)
                    end

                    if mutation and mutation ~= "" and string.lower(mutation) ~= "none" then
                        targetText = targetText .. " • " .. mutation
                    end

                    if timeLeft ~= nil then
                        targetText = targetText .. " • " .. math.floor(timeLeft) .. "s"
                    end

                    setStatus(targetText)
                    farmStats.LastTarget = getWorldEggName(egg)

                    lastClaimedEgg = egg

                    local beforeBasket = select(1, getBasketCounts())
                    local claimed =
                        Reliability.claimWorldEgg(
                            egg,
                            prompt,
                            farmStillEnabled
                        )

                    if not claimed then
                        connections.EggReturn.Active = Reliability.hasPickedUpEgg(getWorldEggName(egg), beforeBasket)
                        Reliability.eggReturnLog("Pickup result=" .. tostring(connections.EggReturn.Active))
                    end
                    if claimed and farmStillEnabled() then
                        Reliability.eggReturnLog("Pickup observed; beginning return")
                        -- claimWorldEgg already retried the prompt and confirmed
                        -- that OUR basket/tool/held display changed.
                        local pickupConfirmed =
                            Reliability.hasPickedUpEgg(
                                getWorldEggName(egg),
                                beforeBasket
                            )

                        if pickupConfirmed then
                            farmStats.Grabbed += 1

                            Reliability.rememberCarriedEgg(
                                getWorldEggName(egg),
                                farmingForRebirth,
                                rebirthDiscovery,
                                cycleRebirthTarget,
                                getRebirthRequiredPetName()
                            )

                            -- Fallback only. The live PlayerGui timer is preferred.
                            Reliability.CarryBreakTimerSample =
                                tonumber(timeLeft)

                            Reliability.CarryBreakTimerSampleClock =
                                timeLeftSampleClock

                            Reliability.LiveEggBreakTimerLabel = nil
                            Reliability.LastLiveCarryBreakTime = nil
                            Reliability.LastLiveCarryBreakClock = nil

                            local mutationReady =
                                Reliability.autoMagmaVolcanicEgg(
                                    getWorldEggName(egg),
                                    farmStillEnabled
                                )

                            local returned = false

                            if not mutationReady then
                                setStatus("Auto Farm • Magma mutation not confirmed • TP-home blocked")
                                Reliability.eggReturnLog("TP-home blocked because volcano mutation was not confirmed")
                            else
                                local carriedCount =
                                    select(1, getBasketCounts())

                                returned =
                                    Reliability.returnBasketEggHome(
                                        farmStillEnabled,
                                        getWorldEggName(egg),
                                        carriedCount,
                                        false
                                    )
                            end

                            if returned then
                                if farmingForRebirth then
                                    rebirthRuntime.RequiredEgg =
                                        cycleRebirthTarget
                                        or tostring(getWorldEggName(egg))

                                    rebirthRuntime.WaitingEggName =
                                        tostring(getWorldEggName(egg))

                                    rebirthRuntime.WaitStartedAt = os.clock()
                                    rebirthRuntime.ManualPlacedSeen = false
                                    rebirthRuntime.ManualDisappearAt = nil

                                    rebirthRuntime.State =
                                        "Collected "
                                        .. tostring(getWorldEggName(egg))
                                        .. " • place it manually"

                                    setStatus(
                                        "Auto Rebirth • "
                                        .. tostring(getWorldEggName(egg))
                                        .. " collected • place it manually"
                                    )
                                elseif rebirthDiscovery then
                                    rebirthRuntime.DiscoveryEggName =
                                        tostring(getWorldEggName(egg))

                                    rebirthRuntime.DiscoveryRequiredPet =
                                        getRebirthRequiredPetName()

                                    rebirthRuntime.DiscoveryManualPlacedSeen =
                                        false
                                    rebirthRuntime.DiscoveryDisappearAt = nil

                                    rebirthRuntime.DiscoveryCollectedAt =
                                        os.clock()

                                    rebirthRuntime.State =
                                        "Collected "
                                        .. tostring(getWorldEggName(egg))
                                        .. " • place it manually"

                                    setStatus(
                                        "Auto Rebirth discovery • "
                                        .. tostring(getWorldEggName(egg))
                                        .. " collected • place it manually"
                                    )
                                elseif farmingForServerHop then
                                    Reliability.HopFarmCollectedThisServer =
                                        (Reliability.HopFarmCollectedThisServer or 0)
                                        + 1

                                    Reliability.HopFarmLastCollected =
                                        tostring(getWorldEggName(egg))

                                    Reliability.HopFarmNoTargetSince = 0

                                    setStatus(
                                        "Server Hop Farm • "
                                        .. tostring(getWorldEggName(egg))
                                        .. " collected • scanning remaining selected eggs"
                                    )
                                else
                                    setStatus(
                                        "Auto Farm • "
                                        .. tostring(getWorldEggName(egg))
                                        .. " detected in inventory/plot • finding next egg"
                                    )
                                end
                            end
                        else
                            setStatus("Pickup was not confirmed")
                        end
                    end
                end
            elseif rebirthDiscovery then
                setStatus("Auto Rebirth discovery • waiting for a test egg to spawn")
            elseif Reliability.serverHopCollectMode() then
                setStatus(
                    "Server Hop Farm • selected eggs cleared • preparing next server"
                )
            elseif Settings.AutoFarmEggs then
                local scan = connections.FarmSelection or {}
                local message
                if (scan.Visible or 0) == 0 then
                    message = "No world eggs loaded yet"
                elseif (scan.Named or 0) == 0 then
                    message = "Waiting for selected eggs to spawn • " .. tostring(Settings.EggNames)
                elseif (scan.Mutation or 0) > 0 then
                    message = "Selected eggs found • mutation filter: " .. tostring(Settings.EggMutation) .. " (choose Any to allow all)"
                elseif (scan.Luck or 0) > 0 then
                    message = "Selected eggs found • blocked by Minimum Egg Luck"
                elseif (scan.Distance or 0) > 0 then
                    message = "Selected eggs found • blocked by Max Egg Distance"
                elseif (scan.Prompt or 0) > 0 then
                    message = "Selected eggs found • pickup interaction not loaded yet"
                else
                    message = "Selected eggs found • waiting for their position to load"
                end
                setStatus("Auto Farm • " .. message)
            elseif cycleRebirthTarget and Settings.AutoRebirth then
                setStatus(
                    "Auto Rebirth • waiting for "
                    .. tostring(cycleRebirthTarget)
                    .. " to spawn"
                )
            end

            busyFarm = false
        end

        if Settings.AutoHatchEggs
            and not rebirthWaitingForPlacedEgg() then
            hatchReadyEggs()
        end

        task.wait(
            Settings.HubPerformanceMode
                and 0.65
                or 0.45
        )
    end
end)

-- Pets / feed
task.spawn(function()
    while alive do
        local petsActive =
            Settings.AutoPlaceBestPets
            or Settings.AutoFeedBestPet
            or Settings.AutoFeedAboveIncome
            or Settings.AutoFeedAboveAge
            or Settings.AutoFeedByRarity

        if Settings.AutoPlaceBestPets then
            placeBestPets()
        end

        if Settings.AutoFeedBestPet
            or Settings.AutoFeedAboveIncome
            or Settings.AutoFeedAboveAge
            or Settings.AutoFeedByRarity then
            feedPetsPass()
        end

        task.wait(
            petsActive
                and 2
                or (
                    Settings.HubPerformanceMode
                    and 8
                    or 4
                )
        )
    end
end)

-- Shop
task.spawn(function()
    while alive do
        local shopActive =
            Settings.AutoBuyRadar
            or Settings.AutoBuyFood
            or Settings.AutoUseRadar

        if shopActive and not busyShop then
            busyShop = true

            if Settings.AutoBuyRadar then
                buyShopItem("Gears", Settings.Radar)
            end

            if Settings.AutoBuyFood then
                buyShopItem("Food", Settings.Food)
            end

            if Settings.AutoUseRadar then
                useRadar()
            end

            busyShop = false
        end

        task.wait(
            shopActive
                and 3
                or (
                    Settings.HubPerformanceMode
                    and 10
                    or 5
                )
        )
    end
end)

-- Progression
task.spawn(function()
    while alive do
        local progressionActive =
            Settings.AutoBuyHatchLuck
            or Settings.AutoUnlockNests
            or Settings.AutoRebirth
            or Settings.AutoRideBestPet
            or Settings.AutoClaimIndex

        if progressionActive and not busyProgression then
            busyProgression = true

            if Settings.AutoBuyHatchLuck then
                local hatchLuckDelay =
                    Settings.HatchLuckMode == "Buy Max"
                    and 2
                    or 0.8

                if os.clock()
                    - (Reliability.HatchLuckLastAttemptAt or 0)
                    >= hatchLuckDelay then

                    Reliability.HatchLuckLastAttemptAt =
                        os.clock()

                    buyHatchLuck()
                end
            end

            if Settings.AutoUnlockNests then
                unlockNextNest()
            end

            if Settings.AutoRebirth then
                updateSmartRebirth()
            end

            if Settings.AutoRideBestPet then
                local char = player.Character
                if char and player:GetAttribute("IsRiding") ~= true then
                    rideBestPet()
                end
            end

            if Settings.AutoClaimIndex then
                claimIndex()
            end

            busyProgression = false
        end

        task.wait(
            progressionActive
                and 1
                or (
                    Settings.HubPerformanceMode
                    and 6
                    or 3
                )
        )
    end
end)

-- ESP refresh
task.spawn(function()
    while alive do
        if Settings.EggESP then
            refreshEggESP()
        end

        if Settings.PetESP then
            refreshPetESP()
        end

        task.wait(
            (Settings.EggESP or Settings.PetESP)
                and (
                    Settings.HubPerformanceMode
                    and 8
                    or 4
                )
                or (
                    Settings.HubPerformanceMode
                    and 15
                    or 8
                )
        )
    end
end)

-- ============================================================
-- BUILD147 • SHARED INDEX REPORTER
-- ============================================================
-- Reports only when the visible egg set changes plus a low-rate heartbeat.
do
    task.spawn(function()
        task.wait(3)

        while alive do
            if normalizedIndexUrl() then
                local heartbeat =
                    math.clamp(
                        tonumber(
                            Settings.IndexReportHeartbeat
                        ) or 40,
                        15,
                        120
                    )

                local due =
                    Reliability.IndexDirty
                    or os.clock()
                        - (
                            Reliability.IndexLastReportAt
                            or 0
                        )
                        >= heartbeat

                if due then
                    local ok =
                        Reliability.reportServerIndex(
                            false
                        )

                    if ok then
                        Reliability.IndexDirty = false
                    end
                end
            end

            task.wait(
                Settings.HubPerformanceMode
                    and 10
                    or 4
            )
        end
    end)
end

-- Server hop
do
    Reliability.LastFoundAlertKey = nil
    Reliability.LastFoundAlertAt = 0

    task.spawn(function()
        while alive do
            if Settings.AutoServerHop then

                -- ============================================================
                -- BUILD142: COLLECT SELECTED EGGS, THEN HOP
                -- ============================================================
                if Reliability.serverHopCollectMode() then
                    local remaining =
                        Reliability.serverHopMatchingCount()

                    if Reliability.hasUnresolvedFarmCargo() then
                        -- Never hop while an egg is still being mutated / returned.
                        Reliability.HopFarmNoTargetSince = 0

                    elseif busyFarm then
                        -- The farm worker is currently scanning or claiming a
                        -- selected egg. Do not hop, but do not reset the empty
                        -- server timer just because this short worker pass is busy.

                    elseif remaining > 0 then
                        Reliability.HopFarmNoTargetSince = 0

                        setStatus(
                            "Server Hop Farm • "
                            .. tostring(remaining)
                            .. " selected egg(s) remaining"
                        )

                    else
                        local now = os.clock()

                        if Reliability.HopFarmNoTargetSince == 0 then
                            Reliability.HopFarmNoTargetSince = now
                        end

                        local scanWait =
                            math.clamp(
                                tonumber(Settings.HopScanWait) or 4,
                                2,
                                15
                            )

                        local noTargetAge =
                            now
                            - Reliability.HopFarmNoTargetSince

                        local serverAge =
                            now
                            - (Reliability.HopFarmServerEnteredAt or now)

                        if noTargetAge >= scanWait
                            and serverAge >= scanWait then

                            setStatus(
                                "Server Hop Farm • "
                                .. tostring(
                                    Reliability.HopFarmCollectedThisServer
                                    or 0
                                )
                                .. " collected here • hopping"
                            )

                            local hopped = false
                            local indexReason = nil

                            if Settings.DirectIndexedHop then
                                hopped, indexReason =
                                    Reliability.indexedHop()
                            end

                            if not hopped
                                and Settings.IndexFallbackHop then

                                hopped = serverHop()
                            end

                            if hopped then
                                -- If teleport is delayed, avoid repeatedly
                                -- starting another hop request every loop.
                                Reliability.HopFarmNoTargetSince =
                                    os.clock()

                            elseif Settings.DirectIndexedHop
                                and not Settings.IndexFallbackHop then

                                setStatus(
                                    "Indexed Hop • waiting for exact server"
                                    .. (
                                        indexReason
                                        and (
                                            " • "
                                            .. tostring(indexReason)
                                        )
                                        or ""
                                    )
                                )

                                -- Re-query soon without blind hopping.
                                Reliability.HopFarmNoTargetSince =
                                    os.clock()
                                    - math.max(
                                        0,
                                        (
                                            tonumber(Settings.HopScanWait)
                                            or 4
                                        )
                                        - 2
                                    )
                            end
                        else
                            setStatus(
                                "Server Hop Farm • scanning server • "
                                .. string.format(
                                    "%.1fs",
                                    math.max(
                                        0,
                                        scanWait
                                        - math.min(
                                            noTargetAge,
                                            serverAge
                                        )
                                    )
                                )
                            )
                        end
                    end

                -- ============================================================
                -- LEGACY HUNT MODE: preserved when no eggs are selected.
                -- ============================================================
                else
                    local found = hopTargetFound()

                    if found then
                        local mutation = getEggMutation(found)
                        local _, luckText = getEggLuck(found)
                        local alertKey = table.concat({
                            tostring(game.JobId),
                            tostring(found.Name),
                            tostring(mutation),
                            tostring(luckText),
                        }, "|")

                        setStatus("HUNT FOUND: " .. found.Name)

                        if alertKey ~= Reliability.LastFoundAlertKey
                            or (os.clock() - Reliability.LastFoundAlertAt) >= 30 then

                            Reliability.LastFoundAlertKey = alertKey
                            Reliability.LastFoundAlertAt = os.clock()

                            sendWebhook("Server Hop Target Found", {
                                Egg = found.Name,
                                Mutation = mutation,
                                Luck = luckText,
                                Players = tostring(#Players:GetPlayers()),
                                PlaceId = tostring(game.PlaceId),
                                JobId = tostring(game.JobId),
                                Action = Settings.HopStopWhenFound
                                    and "Stopped on target"
                                    or "Continuing after delay",
                            })
                        end

                        if Settings.HopStopWhenFound then
                            Settings.AutoServerHop = false
                            saveConfig()
                        else
                            task.wait(
                                math.max(
                                    2,
                                    tonumber(Settings.HopDelay) or 20
                                )
                            )
                            serverHop()
                        end
                    else
                        Reliability.LastFoundAlertKey = nil
                        setStatus("Hunting servers...")
                        serverHop()
                    end
                end
            else
                Reliability.LastFoundAlertKey = nil
                Reliability.HopFarmNoTargetSince = 0
            end

            task.wait(
                Settings.AutoServerHop
                    and 1
                    or (
                        Settings.HubPerformanceMode
                        and 6
                        or 3
                    )
            )
        end
    end)
end

-- ============================================================
-- UNLOAD
-- ============================================================

-- Egg movement controller: one physics connection, cached character parts, reversible state.
connections.PlayerMovement = {Parts = {}, ClipApplied = false, LastContext = 0}
function connections.PlayerMovement.StopFly()
    local state = connections.PlayerMovement

    if state.Velocity then
        pcall(function() state.Velocity:Destroy() end)
        state.Velocity = nil
    end

    if state.Gyro then
        pcall(function() state.Gyro:Destroy() end)
        state.Gyro = nil
    end

    -- Clean up an attachment left by an older build if one exists.
    if state.Attachment then
        pcall(function() state.Attachment:Destroy() end)
        state.Attachment = nil
    end

    if state.FlyingHumanoid and state.FlyingHumanoid.Parent then
        state.FlyingHumanoid.PlatformStand = false
        state.FlyingHumanoid.AutoRotate =
            state.AutoRotate ~= false
    end

    state.FlyingHumanoid = nil
end
function connections.PlayerMovement.Restore()
    local state = connections.PlayerMovement
    state.StopFly()
    if state.WalkingHumanoid and state.WalkingHumanoid.Parent then
        state.WalkingHumanoid.WalkSpeed = state.OriginalSpeed
    end
    state.WalkingHumanoid = nil
    for part, original in pairs(state.Parts) do
        if part.Parent then part.CanCollide = original end
    end
    state.ClipApplied = false
    if state.PartAdded then state.PartAdded:Disconnect() ; state.PartAdded = nil end
    state.Character = nil
    table.clear(state.Parts)
end
function connections.PlayerMovement.Step()
    local state = connections.PlayerMovement

    -- BUILD154: when all manual movement features are off and there is no
    -- state left to restore, do absolutely nothing this frame.
    if not Settings.Fly
        and not Settings.Noclip
        and not Settings.WalkSpeedEnabled
        and not state.Velocity
        and not state.Gyro
        and not state.WalkingHumanoid
        and not state.ClipApplied then

        return
    end

    local character, humanoid, root = getCharacter()
    if character ~= state.Character then
        state.Restore()
        state.Character = character
        if character then
            local function remember(part)
                if part:IsA("BasePart") then state.Parts[part] = part.CanCollide end
            end
            for _, part in ipairs(character:GetDescendants()) do remember(part) end
            state.PartAdded = character.DescendantAdded:Connect(remember)
        end
    end
    if not humanoid or not root or humanoid.Health <= 0 then
        state.StopFly()
        if state.WalkingHumanoid and state.WalkingHumanoid.Parent then
            state.WalkingHumanoid.WalkSpeed = state.OriginalSpeed
        end
        state.WalkingHumanoid = nil
        if state.ClipApplied and not activeFarmTween then
            for part, original in pairs(state.Parts) do
                if part.Parent then part.CanCollide = original end
            end
            state.ClipApplied = false
        end
        return
    end
    if Settings.WalkSpeedEnabled then
        if state.WalkingHumanoid ~= humanoid then
            state.WalkingHumanoid = humanoid
            state.OriginalSpeed = humanoid.WalkSpeed
        end
        humanoid.WalkSpeed = math.clamp(tonumber(Settings.WalkSpeed) or 32, 1, 200)
    elseif state.WalkingHumanoid then
        state.WalkingHumanoid.WalkSpeed = state.OriginalSpeed
        state.WalkingHumanoid = nil
    end
    if Settings.Noclip then
        for part in pairs(state.Parts) do
            if part.Parent then part.CanCollide = false else state.Parts[part] = nil end
        end
        state.ClipApplied = true
    elseif state.ClipApplied and not activeFarmTween and not Reliability.UndergroundGravityForce then
        for part, original in pairs(state.Parts) do
            if part.Parent then part.CanCollide = original end
        end
        state.ClipApplied = false
    end
    local camera = workspace.CurrentCamera

    -- BUILD141: do not disable Fly merely because Auto Farm is enabled.
    -- The old busyFarm gate made the toggle appear broken for anyone testing
    -- movement while the farm was running. Only an actual TweenService farm
    -- segment temporarily pauses manual Fly.
    if not Settings.Fly or activeFarmTween or not camera then
        state.StopFly()
        return
    end

    -- BodyVelocity + BodyGyro is intentionally used here instead of the
    -- previous LinearVelocity setup. It is supported by the executors this hub
    -- targets and has proved much more reliable for manual character flight.
    if not state.Velocity
        or not state.Velocity.Parent
        or not state.Gyro
        or not state.Gyro.Parent then

        state.StopFly()

        state.AutoRotate = humanoid.AutoRotate
        state.FlyingHumanoid = humanoid

        humanoid.AutoRotate = false
        humanoid.PlatformStand = true

        local velocity = Instance.new("BodyVelocity")
        velocity.Name = "ThumbsFlyVelocity"
        velocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        velocity.P = 20000
        velocity.Velocity = Vector3.zero
        velocity.Parent = root
        state.Velocity = velocity

        local gyro = Instance.new("BodyGyro")
        gyro.Name = "ThumbsFlyGyro"
        gyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        gyro.P = 90000
        gyro.D = 1000
        gyro.CFrame = root.CFrame
        gyro.Parent = root
        state.Gyro = gyro
    end

    -- Character can respawn while Fly remains toggled.
    if state.FlyingHumanoid ~= humanoid then
        state.StopFly()
        return
    end

    humanoid.PlatformStand = true

    local direction = Vector3.zero

    if not UserInputService:GetFocusedTextBox() then
        local function down(key)
            return UserInputService:IsKeyDown(key) and 1 or 0
        end

        local forward =
            down(Enum.KeyCode.W)
            - down(Enum.KeyCode.S)

        local right =
            down(Enum.KeyCode.D)
            - down(Enum.KeyCode.A)

        local up =
            down(Enum.KeyCode.Space)
            - down(Enum.KeyCode.LeftControl)
            - down(Enum.KeyCode.RightControl)

        direction =
            camera.CFrame.LookVector * forward
            + camera.CFrame.RightVector * right
            + Vector3.yAxis * up

        -- Controller / Roblox movement fallback.
        if forward == 0
            and right == 0
            and humanoid.MoveDirection.Magnitude > 0.01 then

            direction += humanoid.MoveDirection
        end
    end

    if direction.Magnitude > 1 then
        direction = direction.Unit
    end

    state.Velocity.Velocity =
        direction
        * math.clamp(
            tonumber(Settings.FlySpeed) or 80,
            10,
            500
        )

    state.Gyro.CFrame = camera.CFrame
    root.AssemblyAngularVelocity = Vector3.zero
end
connect(RunService.PreSimulation, function()
    if alive then connections.PlayerMovement.Step() end
end)
connect(RunService.Heartbeat, function()
    local state = connections.PlayerMovement
    local contextInterval =
        Settings.HubPerformanceMode
        and 0.45
        or 0.15

    if alive
        and os.clock() - state.LastContext
            >= contextInterval then

        state.LastContext = os.clock()
        connections.HatchReveal.UpdateContext()
        if not state.LastWeatherData or os.clock() - state.LastWeatherData >= 30 then
            state.LastWeatherData = os.clock()
            task.spawn(connections.WeatherForecast.LoadOddsFromGame)
        end
    end
end)

-- One bounded, read-only capture for the newly updated volcano/drop/weather code.
-- Never requires controllers or invokes gameplay remotes.
function connections.EggUpdateReport()
    if connections.EggReportBusy then return end
    connections.EggReportBusy = true
    setStatus("Collecting egg update report...")
    local ok, report = pcall(function()
        local lines, bytes = {"THUMBSHUB EGG RETURN / UPDATE REPORT / BUILD128", "Place=" .. tostring(game.PlaceId)}, 0
        local function add(text)
            text = tostring(text)
            if bytes + #text > 180000 then return false end
            bytes += #text + 1
            table.insert(lines, text)
            return true
        end
        local state = connections.EggReturn
        add("Local observations only; does not prove server acceptance or an anti-cheat bypass.")
        add("Target=" .. state.Expected .. "; Outcome=" .. state.Outcome)
        add("TP attempts=" .. tostring(connections.InstantTravel.Attempts)
            .. "; rollbacks=" .. tostring(connections.InstantTravel.Rollbacks)
            .. "; last=" .. connections.InstantTravel.LastOutcome)
        add("Destination=" .. connections.InstantTravel.LastDestination
            .. "; last position error=" .. tostring(connections.InstantTravel.LastDistance))
        if #state.LastCompletedLines > 0 then
            add("LAST COMPLETED ATTEMPT")
            add("Target=" .. tostring(state.LastCompletedExpected)
                .. "; Outcome=" .. tostring(state.LastCompletedOutcome))
            for _, line in ipairs(state.LastCompletedLines) do add(line) end
        else
            add("LAST COMPLETED ATTEMPT: none captured yet")
        end
        add("CURRENT ATTEMPT")
        add("Target=" .. state.Expected .. "; Outcome=" .. state.Outcome)
        add("TIMELINE")
        for _, line in ipairs(state.Lines) do add(line) end
        add("CURRENT INVENTORY / OWN PLOT EGGS")
        for i, obj in ipairs(Reliability.eggInventoryObjects()) do
            if i > 40 then add("Inventory display capped at 40 items"); break end
            add(obj:GetFullName() .. "; EggName=" .. getWorldEggName(obj)
                .. "; EggKey=" .. tostring(obj:GetAttribute("EggKey")))
        end
        add("RELEVANT CLIENT MODULES / REMOTE NAMES")
        local function relevant(text)
            text = string.lower(text)
            return text:find("volcan", 1, true) or text:find("magma", 1, true)
                or text:find("throw", 1, true) or text:find("drop", 1, true)
                or text:find("weather", 1, true) or text:find("egg", 1, true)
                or text:find("carry", 1, true) or text:find("basket", 1, true)
                or text:find("pickup", 1, true) or text:find("ranch", 1, true)
                or text:find("anticheat", 1, true) or text:find("antiteleport", 1, true)
        end
        local modules = {}
        for _, container in ipairs({ReplicatedStorage, player:FindFirstChild("PlayerScripts")}) do
            if container then
                for _, obj in ipairs(container:GetDescendants()) do
                    if (obj:IsA("ModuleScript") or obj:IsA("LocalScript")) and relevant(obj:GetFullName()) then
                        table.insert(modules, obj)
                    elseif (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and relevant(obj:GetFullName()) then
                        add("REMOTE " .. obj:GetFullName() .. " [" .. obj.ClassName .. "]")
                    end
                end
            end
        end
        table.sort(modules, function(a, b)
            local function rank(obj)
                local name = string.lower(obj:GetFullName())
                if name:find("carry") or name:find("basket") or name:find("pickup")
                    or name:find("ranch") or name:find("anticheat") or name:find("antiteleport") then return 0 end
                if name:find("egg") then return 1 end
                if name:find("volcan") or name:find("magma") or name:find("throw") or name:find("drop") then return 2 end
                return 3
            end
            if rank(a) ~= rank(b) then return rank(a) < rank(b) end
            return a:GetFullName() < b:GetFullName()
        end)
        for i, obj in ipairs(modules) do
            if i > 24 then add("Module limit reached; additional candidates=" .. tostring(#modules - 24)) ; break end
            add("MODULE " .. obj:GetFullName())
            if type(decompile) == "function" then
                -- Timeout prevents one unsupported decompilation blocking the whole report.
                local done, success, source = false, false, nil
                task.spawn(function()
                    success, source = pcall(decompile, obj)
                    done = true
                end)
                local deadline = os.clock() + 2
                repeat task.wait(0.03) until done or os.clock() >= deadline or not alive
                if done and success and type(source) == "string" then
                    add(source:sub(1, 16000))
                    if #source > 16000 then add("[source truncated]") end
                else add("Source unavailable or timed out") end
            else
                add("Decompile unavailable")
            end
            task.wait()
        end
        add("LIVE VOLCANO / MAGMA OBJECTS")
        local count = 0
        for i, obj in ipairs(workspace:GetDescendants()) do
            local name = string.lower(obj.Name)
            if name:find("volcan", 1, true) or name:find("magma", 1, true) then
                if count < 60 then
                    count += 1
                    add(obj:GetFullName() .. " [" .. obj.ClassName .. "]")
                    local position = getObjectPosition(obj)
                    if position then add("Position=" .. tostring(position)) end
                    for key, value in pairs(obj:GetAttributes()) do
                        if type(value) == "number" or type(value) == "boolean" or type(value) == "string" then
                            add("  " .. key .. "=" .. tostring(value):sub(1, 180))
                        end
                    end
                    for _, child in ipairs(obj:GetDescendants()) do
                        if child:IsA("ProximityPrompt") then
                            add("PROMPT " .. child:GetFullName() .. " action=" .. child.ActionText .. " object=" .. child.ObjectText)
                        end
                    end
                end
            end
            if i % 500 == 0 then task.wait() end
        end
        add("CURRENT WEATHER=" .. tostring(connections.WeatherForecast.Current))
        add("ODDS=" .. connections.WeatherForecast.OddsText())
        add("END REPORT — read only; no gameplay actions issued")
        return table.concat(lines, "\n")
    end)
    connections.EggReportBusy = false
    if not ok then setStatus("Report failed: " .. tostring(report):sub(1, 160)) ; return end
    connections.LastEggUpdateReport = report
    local copied = false
    if type(setclipboard) == "function" then copied = pcall(setclipboard, report)
    elseif type(toclipboard) == "function" then copied = pcall(toclipboard, report) end
    if type(writefile) == "function" then pcall(writefile, "THUMBSHUB_EGG_UPDATE_REPORT.txt", report) end
    setStatus(copied and "Egg update report copied — paste it back here" or "Report ready: THUMBSHUB_EGG_UPDATE_REPORT.txt (executor folder)")
end


ENV.THUMBSHUB_EGG_V1_UNLOAD = function()
    if not alive then
        return
    end

    alive = false
    setFarmForwardKey(false)
    stopCurrentMovement()
    pcall(function()
        Reliability.setUndergroundAntiGravity(false)
        Reliability.setUndergroundNoclip(false)
    end)
    if connections.PlayerMovement then connections.PlayerMovement.Restore() end

    pcall(function()
        restoreHiddenPets()
        connections.NameMask.Restore()
        restoreFPSBoostVisuals()
    end)

    saveConfig()
    disconnectAll()

    pcall(function()
        clearESP()
        espFolder:Destroy()
    end)

    pcall(function()
        gui:Destroy()
    end)

    ENV.THUMBSHUB_EGG_V1_UNLOAD = nil
end

-- Apply persisted visual state.
if Settings.FPSBoost then
    task.spawn(function()
        applyFPSBoost(true)
    end)
end

task.delay(1, function()
    if alive then
        refreshEggESP()
        refreshPetESP()

        if petHideEnabled() then
            refreshPetVisibility()
        end

        if Settings.HideNames then
            connections.NameMask.Refresh()
        end
    end
end)

setStatus("ThumbsHub ready")
print("[ThumbsHub] Loaded.")
print("[THUMBSHUB] No __namecall hooks installed.")
print("[THUMBSHUB] Input service ready • Menu key: " .. tostring(Settings.MenuToggleKey or "RightShift"))

end

local ok, err = xpcall(
    runThumbsHubRideAPet,
    function(problem)
        if debug and type(debug.traceback) == "function" then
            return debug.traceback(tostring(problem), 2)
        end
        return tostring(problem)
    end
)

if not ok then
    warn("[THUMBSHUB RIDE A PET] STARTUP FAILED: " .. tostring(err))
end
