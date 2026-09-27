-- THUMBSHUB • Slayers module
-- Split from Build154 for lightweight per-game loading.
-- Do not run this file directly outside its supported game.

local function runThumbsHubSlayers()
-- BUILD 63 MERGED INTO SLOT 1 MASTER
-- THUMBSHUB BUILD 63 • CLEAN INSTANT KILL UI
-- Runtime validation in Roblox is still required; no guaranteed perfect blocks.
--[[
    THUMBSHUB
    New game foundation for:
      PlaceId: 136406881576517
      GameId : 5595353122

    BUILT FROM THE FULL MAP + FOCUSED SOURCE SCANS.

    PREMIUM REWORK SYSTEMS
      • Premium dashboard + live status cards
      • Dynamic Boss Picker + boss radar modes
      • Auto World Boss routing
      • Boss live/alive state + local respawn countdown tracking
      • Day/Night status + estimated transition timer
      • Dynamic mob picker + region-aware quest target resolver
      • Quest spawn memory + scanned fallback anchors
      • Auto Farm Mobs
      • Instant Kill slider 1–100% • 10% Normal World / 100% Dungeons
      • Auto Quest + Auto Accept (combat quest routing)
      • AFK Boss Circuit (all discovered world bosses, same-boss respawn return, fast travel)
      • Mob Farm (choose a live mob -> fast approach -> hover above -> M1 -> follow knockback -> repeat)
      • Auto M1
      • Smart Auto Skill through the game's Skill_Controller
      • Skill Picker
      • Movement Type: Tween / frame-driven Walk
      • Tween Speed
      • Position offset / Distance
      • Auto Collect tagged chests (prompt based)
      • Auto Pick Up tagged drops (prompt based)
      • WalkSpeed
      • Infinite Jump
      • Noclip
      • Fly + Fly Speed
      • Mob / Boss / Quest Target / Chest / Drop ESP
      • ESP labels with health + distance
      • Dynamic NPC / place travel
      • Anti AFK
      • Auto Execute after supported teleports
      • Auto Reconnect
      • Copy Job ID / Join Job ID
      • Group-member detector for the game's creator group

    ROUTES CONFIRMED BY SOURCE SCAN
      • SignalEvent.ToServer(...)
      • SignalFunction.ToServer(...)
      • Quests / RecommendedQuest modules
      • Skill_Controller.Attempt_Hold / StopHold
      • server_skill_controller_signaler Hold / Cancel / Switch
      • BossTag registry
      • ChestController
      • LootDropController
      • SeriesTrade normal route

    NOT INCLUDED AS A BYPASS
      • Premium entitlement bypass
      • Trade/server validation bypass

    NOTES
      This build is a full ThumbsHub rework for this game. It prefers the
      game's existing controllers, quest data, tags, Regions module and live
      world state instead of hardcoding remote spam.
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

if game.PlaceId ~= 136406881576517 and game.GameId ~= 5595353122 then
    warn(
        "[THUMBSHUB] Unsupported game | PlaceId="
        .. tostring(game.PlaceId)
        .. " | GameId="
        .. tostring(game.GameId)
    )
    return
end

local H = {
    S = {},
    State = {
        Visible = true,
        Unloaded = false,

        AutoWorldBoss = false,
        SelectedBoss = nil,
        BossMode = "Selected",
        AutoBossChest = true,

        AutoFarmMobs = false,

        -- BUILD 74 • AFK AUTO LEVEL
        -- Automatically chooses the strongest level-appropriate combat target
        -- from the game's own quest data and changes target as the player levels.
        AutoLevelFarm = false,

        -- Boss Loop combat position, modelled on the below-boss farm shown in
        -- the supplied clip. Other mob/quest combat retains its own movement.
        BossHoverFarm = true,
        BossHoverXOffset = 0,
        BossHoverYOffset = 2,
        BossHoverZOffset = 0,
        BossHoverDistance = 6.5,
        BossFarmChoice = "All Bosses",
        BossInstantTravel = true,
        BossStopAtMaxLevel = false,
        HoldBossPosition = false,
        RapidHits = false,
        RapidHitIntervalMs = 20,
        HealthGearCycle = false,
        HealthGearDelayMs = 0,

        -- BUILD 68 • OVERHEAD AUTO FARM
        -- V15 standalone was confirmed working at roughly 5.55 studs above
        -- the NPC. Mob Farm now uses that movement instead of ground orbiting.
        MobFarmHoverHeight = 5.55,
        MobFarmRestHeight = 5.55, -- BUILD 75: fixed-height combo cooldown

        -- BUILD 58 • 10% EXECUTE LOCK
        -- Public Slayers 2 hubs describe the working route as ownership-based,
        -- not a Combat_Service damage argument. Main world waits until 10% HP
        -- remaining; Ouwigahara/minigame mode may execute immediately at 100%.
        InstantKill = false,
        InstantKillMainThreshold = 10,
        InstantKillDungeonThreshold = 100,

        AutoQuest = false,
        AutoAccept = true,
        SmartProgression = false, -- legacy only; BUILD 29 never enables it
        SelectedMob = "",
        SelectedQuest = "", -- disabled in BUILD 55 MOB ONLY
        AutoM1 = false,

        -- Automatically equips a combat-capable Tool (prefers Fists) while
        -- farming so CombatUse is actually available.
        AutoEquipCombat = true,

        -- Reactive timing-based block/parry while farming.
        -- Uses the game's normal Blocking skill controller route.
        AutoParry = true,

        -- Guard-first combat. Keeps block ready in melee, then briefly drops
        -- guard only long enough to use the game's direct punch() function.
        -- Keeps guard through detected attacks without releasing it at impact.
        PerfectBlock = true,

        -- Ping-aware defense. Uses live Roblox Data Ping to shift the fresh
        -- block/parry pulse earlier and lengthen the guard window on higher
        -- latency. Boss Safety prioritizes survival over DPS.
        PingAwareParry = true,
        ParrySafetyMs = 95,
        BossSafetyMode = true,
        BossGuardRange = 24,

        -- Safer mob farming:
        --   attack -> short block window
        --   emergency block when health drops
        --   retreat instead of continuing to fight at low HP
        SafeCombat = true,
        RetreatHealthPercent = 20,
        ResumeHealthPercent = 45,

        SmartSkill = false,
        SelectedSkill = nil,

        AutoChests = false,
        ChestFilter = "Any",
        AutoDrops = false,
        AutoLootAfterKill = true,

        -- Quest progression defaults to Smart frame-driven walking.
        MovementType = "Tween",
        TweenSpeed = 150,
        Distance = 2,
        Height = 0,
        FarmPosition = "Below",
        -- Initial test depth, not a measurement of another hub's Offset=0.
        BelowDepth = 2.0,

        WalkSpeedEnabled = false,
        WalkSpeed = 16,
        InfiniteJump = false,
        Noclip = false,
        Fly = false,
        FlySpeed = 65,

        MobESP = false,
        BossESP = false,
        QuestTargetESP = true,
        ChestESP = false,
        DropESP = false,
        ESPLabels = true,
        ESPHealth = true,
        ESPDistance = true,

        AntiAFK = true,
        AutoReconnect = true,
        GroupDetect = true,

        SelectedNPC = nil,
        SelectedPlace = nil,

        TargetJobId = "",
    },

    Modules = {},

    Data = {
        Bosses = {},
        BossCodes = {},
        BossCodeMemory = {},
        BossRespawnAt = {},

        Mobs = {},
        MobNames = {},
        MobNameMemory = {},
        MobAliasCache = {},
        SpawnMemory = {},

        AutoLevel = {
            Candidates = {},
            BuiltAt = 0,
            CurrentTarget = nil,
            CurrentLevel = 0,
            CurrentRequiredLevel = 0,
            CurrentQuest = nil,
            CurrentCategory = nil,
        },
        CurrentFarmTarget = nil,
        CurrentFarmQuery = nil,
        CurrentFarmRegion = nil,
        TargetFallbackIndex = {},
        TargetWaitSince = {},

        -- Temporary per-NPC skip list used when the game's own combat checker
        -- says a target cannot currently be attacked.
        CombatBlockedTargets = setmetatable({}, {__mode = "k"}),

        -- Stable anchors taken from the user's full game scan. These are only
        -- fallbacks when no live model currently exists; live world state always
        -- wins when available.
        KnownNpcLocations = {
            ["noote"] = {
                Region = "Windy Peak",
                Position = Vector3.new(
                    -515.5465698242188,
                    1245.3994140625,
                    -1251.2386474609375
                ),
            },
            ["chaka"] = {
                Region = "Bamboo Grove",
                -- Exact NPC position is resolved after Bamboo Grove streams.
                -- Use the region entry point only as the cross-region route.
                Position = Vector3.new(
                    367.68896484375,
                    1129.4791259765625,
                    -941.0859375
                ),
                RegionAnchorOnly = true,
            },
            ["tom"] = {
                Region = "Bamboo Grove",
                -- Exact client-visible Tom root position from the full V4 scan.
                -- Using this avoids detouring through the Bamboo Grove SpawnCrystal.
                Position = Vector3.new(
                    507.1980285644531,
                    1123.91552734375,
                    -970.2989501953125
                ),
            },
        },

        -- Scan-confirmed region entry points. These are used when Roblox
        -- streaming has removed the destination region's Workspace objects.
        -- Emergency recovery points are only used when an earlier broken build
        -- has already left the character thousands of studs outside the playable map.
        -- The Tom point below is the exact player position captured by the full V4 scan
        -- while standing safely beside Tom in Bamboo Grove. Normal progression never
        -- teleports here; regular movement remains TweenService-only.
        KnownRecoveryPoints = {
            ["tom"] = Vector3.new(
                513.5575561523438,
                1124.379150390625,
                -952.932373046875
            ),
            ["bamboo grove"] = Vector3.new(
                513.5575561523438,
                1124.379150390625,
                -952.932373046875
            ),
        },

        KnownRegionAnchors = {
            ["Windy Peak"] = Vector3.new(
                -447.90850830078125,
                1241.4046630859375,
                -919.1200561523438
            ),
            ["Bamboo Grove"] = Vector3.new(
                367.68896484375,
                1129.4791259765625,
                -941.0859375
            ),
            ["Bamboo Grove Sanctuary"] = Vector3.new(
                627.0650024414062,
                1017.9047241210938,
                -194.48399353027344
            ),
        },

        KnownQuestAnchors = {
            villagespy = {
                Vector3.new(-537.2786, 1245.8215, -1327.7573),
                Vector3.new(-558.5354, 1244.9996, -1132.9067),
                Vector3.new(-581.7654, 1245.6998, -1346.2501),
                Vector3.new(-762.8601, 1260.9998, -1175.9996),
            },
            karuvillagebandit = {
                Vector3.new(-310.7033, 1226.6998, -1008.6030),
                Vector3.new(-224.1329, 1225.4996, -1103.4585),
                Vector3.new(-285.0812, 1227.3981, -967.7251),
                Vector3.new(-285.4073, 1227.2731, -965.2290),
            },
        },

        -- Weak-key registry: one combat watcher per live NPC model.
        DefenseWatchers = setmetatable({}, {__mode = "k"}),

        AutoQuest = {
            Active = nil,
            Recommended = nil,
            LastScan = 0,
            Stage = "idle",
            TargetNpc = nil,
        },

        Skills = {},
        SkillNames = {},

        NPCs = {},
        Places = {},

        Highlights = setmetatable({}, {__mode = "k"}),
        EspBillboards = setmetatable({}, {__mode = "k"}),

        ClockSample = {
            Real = os.clock(),
            Clock = nil,
            Rate = nil,
        },
    },

    Runtime = {
        ResumeAutoLevelAfterRespawn = false,
        ResumeMobFarmAfterRespawn = false,
        CollisionOriginal = {} :: {[BasePart]: boolean},
        PostKillLooting = false,
        MobApproachTravel = false,
        MobSmoothTravelActive = false,
        Connections = {},
        FlyBV = nil,
        FlyBG = nil,
        ActiveTween = nil,
        MoveGoal = nil,
        MoveTarget = nil,
        LastM1 = 0,
        LastSkill = 0,

        AttackHeld = false,
        AttackTarget = nil,
        LastCombatEquip = 0,

        -- BUILD 56 ownership-execute state.
        InstantKillBusy = false,
        InstantKillTarget = nil,
        InstantKillLastAt = 0,
        InstantKillLastOwnershipStatusAt = 0,
        InstantKillAttempts = 0,
        InstantKillSuccesses = 0,

        -- Adaptive attack pulse state. The game tracks successful client
        -- punches in CAM.Global.Combat_presets.Last_Punched, so we use that
        -- to learn which input backend actually works on the current executor.
        AttackBackend = "DirectPunch",
        AttackBackendIndex = 1,
        LastAttackPulse = 0,
        AttackFailures = 0,
        LastVerifiedPunch = 0,
        LastVerifiedPunchAt = 0,
        LastPunchFailure = "",
        HitMissStreak = 0,
        LastHitConfirmAt = 0,
        CombatTightUntil = 0,
        ForceAttackUntil = 0,

        PunchFunction = nil,
        PunchScript = nil,
        NextPunchAt = 0,
        LastPunchResolve = 0,
        MobComboRestUntil = 0,
        MobComboRestStartedAt = 0,
        MobComboRiseAt = 0,
        MobComboIndex = 0,
        MobComboRestDuration = 0,
        MobComboLastCountedStamp = 0,
        MobComboNextPunchAt = 0,

        Defending = false,
        BlockHeld = false,
        BlockReleaseUntil = 0,
        LastBlockStart = 0,
        LastParryPulse = 0,
        PingMs = 0,
        LastPingSample = 0,
        ParryPenaltyMs = 0,
        ThreatUntil = setmetatable({}, {__mode = "k"}),

        Retreating = false,
        RetreatTarget = nil,
        RetreatStartedAt = 0,
        RetreatPosition = nil,
        LastRetreat = 0,
        LastHealth = nil,
        LastHealthDrop = 0,
        LastDefense = 0,
        DefenseToken = 0,

        LastChest = 0,
        LastDrop = 0,
        LastBossChest = 0,
        LastTravelRefresh = 0,
        LastDashboardUpdate = 0,
        LastQuestAction = 0,
        LastQuestClick = 0,

        -- Quest-chain state. Some quests finish by giving an item or dialogue
        -- that sends the player to another NPC before a new Holder quest exists.
        PendingHandoffNpc = nil,
        PendingHandoffReason = nil,
        PendingHandoffUntil = 0,
        LastActiveQuestName = nil,
        LastActiveQuestKey = nil,
        RecentCompletedQuestName = nil,
        RecentCompletedQuestKey = nil,
        RecentCompletedQuestAt = 0,

        -- Dialogue state machine. Once an NPC prompt is opened we stay in
        -- "advance dialogue" mode for a few seconds instead of re-firing the
        -- proximity prompt every farm tick.
        DialogueNpc = nil,
        DialogueMode = nil,
        DialogueQuestKey = nil,
        DialogueSessionUntil = 0,
        DialogueStartedAt = 0,
        DialogueAdvanceAttempts = 0,
        LastDialogueAdvance = 0,

        LastStatus = "",
        LastLoopError = "",
        LastLoopErrorAt = 0,
    },

    UI = {
        Gui = nil :: ScreenGui?,
        ToggleButtons = {},
    },
}

H.S.Players = game:GetService("Players")
H.S.ReplicatedStorage = game:GetService("ReplicatedStorage")
H.S.Workspace = game:GetService("Workspace")
H.S.CollectionService = game:GetService("CollectionService")
H.S.TweenService = game:GetService("TweenService")
H.S.RunService = game:GetService("RunService")
H.S.UserInputService = game:GetService("UserInputService")
H.S.VirtualInputManager = game:GetService("VirtualInputManager")
H.S.VirtualUser = game:GetService("VirtualUser")
H.S.TeleportService = game:GetService("TeleportService")
H.S.Lighting = game:GetService("Lighting")
H.S.CoreGui = game:GetService("CoreGui")
H.S.GuiService = game:GetService("GuiService")
H.S.HttpService = game:GetService("HttpService")
H.S.Stats = game:GetService("Stats")

H.Player = H.S.Players.LocalPlayer
H.PlayerGui = H.Player:WaitForChild("PlayerGui")

local TH_ENV =
    (getgenv and getgenv())
    or _G

local THUMBSHUB_DISCORD_INVITE =
    "https://discord.gg/RDZCNHGznU"

TH_ENV.THUMBSHUB_COMMUNITY_WELCOME_USERS =
    TH_ENV.THUMBSHUB_COMMUNITY_WELCOME_USERS
    or {}

function H:CopyDiscordInvite()
    local copied =
        false

    if typeof(setclipboard) == "function" then
        copied =
            pcall(
                setclipboard,
                THUMBSHUB_DISCORD_INVITE
            )
    elseif typeof(toclipboard) == "function" then
        copied =
            pcall(
                toclipboard,
                THUMBSHUB_DISCORD_INVITE
            )
    end

    if copied then
        self:SetStatus(
            "Discord invite copied"
        )

        return true
    end

    self:SetStatus(
        "Discord • "
        .. THUMBSHUB_DISCORD_INVITE
    )

    return false
end

function H:HasSeenCommunityWelcome()
    local userId =
        tonumber(
            self.Player.UserId
        )
        or 0

    if TH_ENV.THUMBSHUB_COMMUNITY_WELCOME_USERS[userId] then
        return true
    end

    local markerPath =
        "THUMBSHUB/community_welcome_"
        .. tostring(
            userId
        )
        .. ".txt"

    if typeof(isfile) == "function" then
        local ok,
            exists =
            pcall(
                isfile,
                markerPath
            )

        if ok
            and exists then

            TH_ENV.THUMBSHUB_COMMUNITY_WELCOME_USERS[userId] =
                true

            return true
        end
    end

    if typeof(readfile) == "function" then
        local ok =
            pcall(
                readfile,
                markerPath
            )

        if ok then
            TH_ENV.THUMBSHUB_COMMUNITY_WELCOME_USERS[userId] =
                true

            return true
        end
    end

    return false
end

function H:MarkCommunityWelcomeSeen()
    local userId =
        tonumber(
            self.Player.UserId
        )
        or 0

    TH_ENV.THUMBSHUB_COMMUNITY_WELCOME_USERS[userId] =
        true

    local markerPath =
        "THUMBSHUB/community_welcome_"
        .. tostring(
            userId
        )
        .. ".txt"

    pcall(
        function()
            if typeof(makefolder) == "function" then
                local exists =
                    false

                if typeof(isfolder) == "function" then
                    local ok,
                        result =
                        pcall(
                            isfolder,
                            "THUMBSHUB"
                        )

                    exists =
                        ok
                        and result == true
                end

                if not exists then
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
                    .. tostring(
                        userId
                    )
                )
            end
        end
    )
end

function H:ShowCommunityWelcome()
    local gui =
        self.UI.Gui

    local main =
        self.UI.Main

    if not gui
        or not main then

        return
    end

    if self:HasSeenCommunityWelcome() then
        main.Visible =
            true

        return
    end

    main.Visible =
        false

    local old =
        gui:FindFirstChild(
            "CommunityWelcome"
        )

    if old then
        old:Destroy()
    end

    local overlay =
        Instance.new(
            "Frame"
        )

    overlay.Name =
        "CommunityWelcome"

    overlay.Size =
        UDim2.fromScale(
            1,
            1
        )

    overlay.BackgroundColor3 =
        Color3.fromRGB(
            4,
            4,
            6
        )

    overlay.BackgroundTransparency =
        0.08

    overlay.Active =
        true

    overlay.ZIndex =
        200

    overlay.Parent =
        gui

    local card =
        Instance.new(
            "Frame"
        )

    card.AnchorPoint =
        Vector2.new(
            0.5,
            0.5
        )

    card.Position =
        UDim2.fromScale(
            0.5,
            0.5
        )

    card.Size =
        UDim2.fromOffset(
            510,
            360
        )

    card.BackgroundColor3 =
        Color3.fromRGB(
            17,
            17,
            22
        )

    card.BorderSizePixel =
        0

    card.ZIndex =
        201

    card.Parent =
        overlay

    local corner =
        Instance.new(
            "UICorner"
        )

    corner.CornerRadius =
        UDim.new(
            0,
            18
        )

    corner.Parent =
        card

    local stroke =
        Instance.new(
            "UIStroke"
        )

    stroke.Color =
        Color3.fromRGB(
            245,
            118,
            42
        )

    stroke.Transparency =
        0.25

    stroke.Thickness =
        1.4

    stroke.Parent =
        card

    local gradient =
        Instance.new(
            "UIGradient"
        )

    gradient.Rotation =
        115

    gradient.Color =
        ColorSequence.new({
            ColorSequenceKeypoint.new(
                0,
                Color3.fromRGB(
                    24,
                    22,
                    24
                )
            ),
            ColorSequenceKeypoint.new(
                1,
                Color3.fromRGB(
                    14,
                    14,
                    18
                )
            ),
        })

    gradient.Parent =
        card

    local accent =
        Instance.new(
            "Frame"
        )

    accent.Size =
        UDim2.new(
            1,
            0,
            0,
            3
        )

    accent.BorderSizePixel =
        0

    accent.BackgroundColor3 =
        Color3.fromRGB(
            245,
            118,
            42
        )

    accent.ZIndex =
        202

    accent.Parent =
        card

    local accentGradient =
        Instance.new(
            "UIGradient"
        )

    accentGradient.Color =
        ColorSequence.new({
            ColorSequenceKeypoint.new(
                0,
                Color3.fromRGB(
                    245,
                    118,
                    42
                )
            ),
            ColorSequenceKeypoint.new(
                0.5,
                Color3.fromRGB(
                    255,
                    173,
                    92
                )
            ),
            ColorSequenceKeypoint.new(
                1,
                Color3.fromRGB(
                    245,
                    118,
                    42
                )
            ),
        })

    accentGradient.Parent =
        accent

    local logo =
        Instance.new(
            "Frame"
        )

    logo.Position =
        UDim2.fromOffset(
            28,
            29
        )

    logo.Size =
        UDim2.fromOffset(
            54,
            54
        )

    logo.BackgroundColor3 =
        Color3.fromRGB(
            245,
            118,
            42
        )

    logo.BorderSizePixel =
        0

    logo.ZIndex =
        202

    logo.Parent =
        card

    local logoCorner =
        Instance.new(
            "UICorner"
        )

    logoCorner.CornerRadius =
        UDim.new(
            0,
            14
        )

    logoCorner.Parent =
        logo

    local logoText =
        Instance.new(
            "TextLabel"
        )

    logoText.Size =
        UDim2.fromScale(
            1,
            1
        )

    logoText.BackgroundTransparency =
        1

    logoText.Font =
        Enum.Font.GothamBold

    logoText.TextSize =
        28

    logoText.Text =
        "TH"

    logoText.TextColor3 =
        Color3.new(
            1,
            1,
            1
        )

    logoText.ZIndex =
        203

    logoText.Parent =
        logo

    local title =
        Instance.new(
            "TextLabel"
        )

    title.Position =
        UDim2.fromOffset(
            98,
            30
        )

    title.Size =
        UDim2.new(
            1,
            -126,
            0,
            30
        )

    title.BackgroundTransparency =
        1

    title.Font =
        Enum.Font.GothamBold

    title.TextSize =
        24

    title.TextColor3 =
        Color3.fromRGB(
            248,
            247,
            246
        )

    title.TextXAlignment =
        Enum.TextXAlignment.Left

    title.Text =
        "ThumbsHub"

    title.ZIndex =
        202

    title.Parent =
        card

    local subtitle =
        Instance.new(
            "TextLabel"
        )

    subtitle.Position =
        UDim2.fromOffset(
            98,
            61
        )

    subtitle.Size =
        UDim2.new(
            1,
            -126,
            0,
            18
        )

    subtitle.BackgroundTransparency =
        1

    subtitle.Font =
        Enum.Font.Gotham

    subtitle.TextSize =
        11

    subtitle.TextColor3 =
        Color3.fromRGB(
            171,
            166,
            163
        )

    subtitle.TextXAlignment =
        Enum.TextXAlignment.Left

    subtitle.Text =
        "Community • Updates • Support"

    subtitle.ZIndex =
        202

    subtitle.Parent =
        card

    local info =
        Instance.new(
            "TextLabel"
        )

    info.Position =
        UDim2.fromOffset(
            28,
            106
        )

    info.Size =
        UDim2.new(
            1,
            -56,
            0,
            56
        )

    info.BackgroundTransparency =
        1

    info.Font =
        Enum.Font.Gotham

    info.TextSize =
        13

    info.TextWrapped =
        true

    info.TextColor3 =
        Color3.fromRGB(
            218,
            214,
            211
        )

    info.TextXAlignment =
        Enum.TextXAlignment.Left

    info.TextYAlignment =
        Enum.TextYAlignment.Top

    info.Text =
        "Join the ThumbsHub Discord for announcements, support, bug reports and new feature drops. Joining is optional."

    info.ZIndex =
        202

    info.Parent =
        card

    local inviteBox =
        Instance.new(
            "Frame"
        )

    inviteBox.Position =
        UDim2.fromOffset(
            28,
            172
        )

    inviteBox.Size =
        UDim2.new(
            1,
            -56,
            0,
            46
        )

    inviteBox.BackgroundColor3 =
        Color3.fromRGB(
            27,
            27,
            34
        )

    inviteBox.BorderSizePixel =
        0

    inviteBox.ZIndex =
        202

    inviteBox.Parent =
        card

    local inviteCorner =
        Instance.new(
            "UICorner"
        )

    inviteCorner.CornerRadius =
        UDim.new(
            0,
            10
        )

    inviteCorner.Parent =
        inviteBox

    local invite =
        Instance.new(
            "TextLabel"
        )

    invite.Position =
        UDim2.fromOffset(
            14,
            0
        )

    invite.Size =
        UDim2.new(
            1,
            -28,
            1,
            0
        )

    invite.BackgroundTransparency =
        1

    invite.Font =
        Enum.Font.GothamMedium

    invite.TextSize =
        12

    invite.TextColor3 =
        Color3.fromRGB(
            244,
            241,
            239
        )

    invite.TextXAlignment =
        Enum.TextXAlignment.Left

    invite.Text =
        THUMBSHUB_DISCORD_INVITE

    invite.ZIndex =
        203

    invite.Parent =
        inviteBox

    local feedback =
        Instance.new(
            "TextLabel"
        )

    feedback.Position =
        UDim2.fromOffset(
            28,
            226
        )

    feedback.Size =
        UDim2.new(
            1,
            -56,
            0,
            20
        )

    feedback.BackgroundTransparency =
        1

    feedback.Font =
        Enum.Font.Gotham

    feedback.TextSize =
        10

    feedback.TextColor3 =
        Color3.fromRGB(
            154,
            149,
            146
        )

    feedback.TextXAlignment =
        Enum.TextXAlignment.Left

    feedback.Text =
        "Copy the invite or continue straight into ThumbsHub."

    feedback.ZIndex =
        202

    feedback.Parent =
        card

    local copyButton =
        Instance.new(
            "TextButton"
        )

    copyButton.Position =
        UDim2.fromOffset(
            28,
            263
        )

    copyButton.Size =
        UDim2.new(
            0.5,
            -34,
            0,
            48
        )

    copyButton.BackgroundColor3 =
        Color3.fromRGB(
            225,
            91,
            25
        )

    copyButton.BorderSizePixel =
        0

    copyButton.AutoButtonColor =
        false

    copyButton.Font =
        Enum.Font.GothamBold

    copyButton.TextSize =
        13

    copyButton.TextColor3 =
        Color3.new(
            1,
            1,
            1
        )

    copyButton.Text =
        "Copy Discord Invite"

    copyButton.ZIndex =
        202

    copyButton.Parent =
        card

    local copyCorner =
        Instance.new(
            "UICorner"
        )

    copyCorner.CornerRadius =
        UDim.new(
            0,
            11
        )

    copyCorner.Parent =
        copyButton

    local continueButton =
        Instance.new(
            "TextButton"
        )

    continueButton.Position =
        UDim2.new(
            0.5,
            6,
            0,
            263
        )

    continueButton.Size =
        UDim2.new(
            0.5,
            -34,
            0,
            48
        )

    continueButton.BackgroundColor3 =
        Color3.fromRGB(
            34,
            34,
            42
        )

    continueButton.BorderSizePixel =
        0

    continueButton.AutoButtonColor =
        false

    continueButton.Font =
        Enum.Font.GothamBold

    continueButton.TextSize =
        13

    continueButton.TextColor3 =
        Color3.fromRGB(
            245,
            243,
            241
        )

    continueButton.Text =
        "Continue to ThumbsHub"

    continueButton.ZIndex =
        202

    continueButton.Parent =
        card

    local continueCorner =
        Instance.new(
            "UICorner"
        )

    continueCorner.CornerRadius =
        UDim.new(
            0,
            11
        )

    continueCorner.Parent =
        continueButton

    self:Connect(
        copyButton.Activated,
        function()
            if self:CopyDiscordInvite() then
                feedback.Text =
                    "Discord invite copied to clipboard."

                feedback.TextColor3 =
                    Color3.fromRGB(
                        102,
                        216,
                        148
                    )
            else
                feedback.Text =
                    "Clipboard unavailable • "
                    .. THUMBSHUB_DISCORD_INVITE

                feedback.TextColor3 =
                    Color3.fromRGB(
                        235,
                        177,
                        88
                    )
            end
        end
    )

    local dismissed =
        false

    self:Connect(
        continueButton.Activated,
        function()
            if dismissed then
                return
            end

            dismissed =
                true

            self:MarkCommunityWelcomeSeen()

            local tween =
                self.S.TweenService:Create(
                    card,
                    TweenInfo.new(
                        0.16,
                        Enum.EasingStyle.Quart,
                        Enum.EasingDirection.In
                    ),
                    {
                        Position =
                            UDim2.fromScale(
                                0.5,
                                0.52
                            ),
                    }
                )

            tween:Play()

            task.delay(
                0.13,
                function()
                    if overlay
                        and overlay.Parent then

                        overlay:Destroy()
                    end

                    if main
                        and main.Parent then

                        main.Visible =
                            true

                        main.Position =
                            UDim2.fromScale(
                                0.5,
                                0.53
                            )

                        self.S.TweenService:Create(
                            main,
                            TweenInfo.new(
                                0.24,
                                Enum.EasingStyle.Quart,
                                Enum.EasingDirection.Out
                            ),
                            {
                                Position =
                                    UDim2.fromScale(
                                        0.5,
                                        0.5
                                    ),
                            }
                        ):Play()
                    end
                end
            )
        end
    )
end

-- ============================================================
-- HELPERS
-- ============================================================

function H:Connect(signal, fn)
    if not signal then
        return nil
    end

    -- Some Roblox/executor signals are protected by RobloxScript capability
    -- (for example GuiService.ErrorMessageChanged). Never let one unsupported
    -- diagnostic signal kill the whole hub.
    local ok, c =
        pcall(
            function()
                return signal:Connect(fn)
            end
        )

    if not ok or not c then
        warn(
            "[THUMBSHUB] Skipped unsupported signal connection: "
            .. tostring(c)
        )
        return nil
    end

    table.insert(
        self.Runtime.Connections,
        c
    )

    return c
end

function H:SafeRequire(obj)
    if not obj then
        return nil
    end

    local ok, result = pcall(require, obj)
    return ok and result or nil
end

function H:Character()
    return self.Player.Character
end

function H:Humanoid()
    local c = self:Character()
    return c and c:FindFirstChildOfClass("Humanoid")
end

function H:Root()
    local c = self:Character()
    return c and c:FindFirstChild("HumanoidRootPart")
end

function H:Path(obj)
    local ok, p = pcall(function()
        return obj:GetFullName()
    end)
    return ok and p or tostring(obj)
end

function H:IsOwnGuiObject(obj)
    if not obj or not self.UI.Gui then
        return false
    end

    local ok, result =
        pcall(
            function()
                return obj == self.UI.Gui
                    or obj:IsDescendantOf(self.UI.Gui)
            end
        )

    return ok and result or false
end

function H:SafeText(obj, text)
    if not obj then
        return false
    end

    local ok =
        pcall(
            function()
                if obj.Parent and obj.Text ~= tostring(text) then
                    obj.Text = tostring(text)
                end
            end
        )

    return ok
end

function H:SetStatus(text)
    text =
        tostring(
            text
        )

    if self.Runtime.LastStatus == text then
        return
    end

    local now =
        os.clock()

    local highFrequency =
        string.sub(
            text,
            1,
            8
        ) == "Mob Farm"
        or string.sub(text, 1, 9) == "Boss Loop"
        or string.sub(
            text,
            1,
            10
        ) == "Auto Level"
        or string.sub(
            text,
            1,
            17
        ) == "Smart Progression"

    if highFrequency
        and now
            - (
                self.Runtime.LastStatusUiAt
                or 0
            )
            < (string.sub(text, 1, 9) == "Boss Loop" and 0.18 or 0.08) then

        return
    end

    self.Runtime.LastStatus =
        text

    self.Runtime.LastStatusUiAt =
        now

    self:SafeText(
        self.UI.Status,
        text
    )
end

function H:Notify(text)
    self:SetStatus(text)

    pcall(function()
        game:GetService("StarterGui"):SetCore(
            "SendNotification",
            {
                Title = "ThumbsHub",
                Text = tostring(text),
                Duration = 4,
            }
        )
    end)
end

function H:FindDesc(root, path)
    local cur = root

    for part in string.gmatch(path, "[^%.]+") do
        cur = cur and cur:FindFirstChild(part)
    end

    return cur
end

-- ============================================================
-- GAME MODULES
-- ============================================================

do
    local RS = H.S.ReplicatedStorage

    H.Modules.SignalEvent =
        H:SafeRequire(
            H:FindDesc(
                RS,
                "Communication.ServerAndClient.Signals.SignalEvent"
            )
        )

    H.Modules.SignalFunction =
        H:SafeRequire(
            H:FindDesc(
                RS,
                "Communication.ServerAndClient.Signals.SignalFunction"
            )
        )

    H.Modules.Quests =
        H:SafeRequire(
            H:FindDesc(
                RS,
                "CAM.Global.Subsets.Gameplay.Quests"
            )
        )

    H.Modules.RecommendedQuest =
        H:SafeRequire(
            H:FindDesc(
                RS,
                "CAM.Client.Modules.RecommendedQuest"
            )
        )

    H.Modules.SkillController =
        H:SafeRequire(
            H:FindDesc(
                RS,
                "CAM.Client.Controllers.Skill_Controller"
            )
        )

    H.Modules.CombatAvailable =
        H:SafeRequire(
            H:FindDesc(
                RS,
                "CAM.Client.Modules.GamePlay.CombatAvailable"
            )
        )

    H.Modules.CombatPresets =
        H:SafeRequire(
            H:FindDesc(
                RS,
                "CAM.Global.Combat_presets"
            )
        )

    H.Modules.Checker =
        H:SafeRequire(
            H:FindDesc(
                RS,
                "CAM.Global.Checker"
            )
        )

    H.Modules.CurPower =
        H:FindDesc(
            RS,
            "CAM.Client.Controllers.Skills_Provider.CurPower"
        )

    H.Modules.SkillsProvider =
        H:SafeRequire(
            H:FindDesc(
                RS,
                "CAM.Client.Controllers.Skills_Provider"
            )
        )

    H.Modules.GameSettings =
        H:SafeRequire(
            H:FindDesc(
                RS,
                "CAM.Global.gameSettings"
            )
        )

    H.Modules.LiveConfig =
        H:SafeRequire(
            H:FindDesc(
                RS,
                "CAM.Global.LiveConfig"
            )
        )

    H.Modules.Regions =
        H:SafeRequire(
            RS:FindFirstChild("Regions")
        )

    H.Modules.Items =
        H:SafeRequire(
            H:FindDesc(
                RS,
                "CAM.Global.Collectibles.Items"
            )
        )

    H.Modules.Rarities =
        H:SafeRequire(
            H:FindDesc(
                RS,
                "CAM.Global.Rarities"
            )
        )
end

-- ============================================================
-- DISCOVERY
-- ============================================================

function H:RefreshBosses()
    self.Data.BossCodeMemory = self.Data.BossCodeMemory or {}
    self.Data.Bosses = self.Data.Bosses or {}

    for _, rec in pairs(self.Data.Bosses) do
        if type(rec) == "table" then
            rec.Live = false
            if rec.Model and not rec.Model.Parent then rec.Model = nil end
            if rec.Info and not rec.Info.Parent then rec.Info = nil end
        end
    end

    for _, info in ipairs(self.S.CollectionService:GetTagged("BossTag")) do
        if info and info.Parent then
            local code = tostring(info:GetAttribute("NpcCode") or info.Parent.Name)
            local model = info.Parent
            if not model:IsA("Model") and model.Parent then model = model.Parent end

            local old = self.Data.Bosses[code] or {}
            self.Data.Bosses[code] = {
                CatalogDefinition = old.CatalogDefinition,
                RequiredLevel = tonumber(info:GetAttribute("RequiredLevel")) or old.RequiredLevel,
                Info = info,
                Model = model,
                Code = code,
                Title = tostring(info:GetAttribute("Title") or old.Title or code),
                Center = info:GetAttribute("Center") or old.Center,
                SpawnTime = tonumber(info:GetAttribute("SpawnTime")) or old.SpawnTime or 0,
                NightOnly = info:GetAttribute("OnlyAtNight") == true or old.NightOnly == true,
                Chest = tostring(info:GetAttribute("Chest") or old.Chest or ""),
                ChestRarity = info:GetAttribute("ChestRarity") or old.ChestRarity,
                Live = true,
                SeenAt = os.clock(),
            }

            self.Data.BossCodeMemory[code] = true
            self:WatchMobDefense(model)
        end
    end

    local humanoids = self.S.Workspace:FindFirstChild("Humanoids")
    if humanoids then
        for _, model in ipairs(humanoids:GetDescendants()) do
            if model:IsA("Model") and model ~= self:Character() then
                local isBoss =
                    model:GetAttribute("IsBoss") == true
                    or model:GetAttribute("Boss") == true
                    or self.S.CollectionService:HasTag(model, "BossTag")

                if isBoss then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                        or model:FindFirstChildWhichIsA("Humanoid", true)
                    local root = model:FindFirstChild("HumanoidRootPart", true)
                        or model.PrimaryPart

                    if hum and root then
                        local code = tostring(
                            model:GetAttribute("NpcCode")
                            or model:GetAttribute("Code")
                            or model.Name
                        )
                        local old = self.Data.Bosses[code] or {}

                        self.Data.Bosses[code] = {
                            CatalogDefinition = old.CatalogDefinition,
                            RequiredLevel = tonumber(model:GetAttribute("RequiredLevel")) or old.RequiredLevel,
                            Info = old.Info,
                            Model = model,
                            Code = code,
                            Title = tostring(model:GetAttribute("Title") or old.Title or code),
                            Center = old.Center or root.Position,
                            SpawnTime = tonumber(model:GetAttribute("SpawnTime")) or old.SpawnTime or 0,
                            NightOnly = model:GetAttribute("OnlyAtNight") == true or old.NightOnly == true,
                            Chest = tostring(model:GetAttribute("Chest") or old.Chest or ""),
                            ChestRarity = model:GetAttribute("ChestRarity") or old.ChestRarity,
                            Live = true,
                            SeenAt = os.clock(),
                        }

                        self.Data.BossCodeMemory[code] = true
                    end
                end
            end
        end
    end

    table.clear(self.Data.BossCodes)
    for code in pairs(self.Data.BossCodeMemory) do
        table.insert(self.Data.BossCodes, code)
    end
    table.sort(self.Data.BossCodes)

    if not self.State.SelectedBoss and #self.Data.BossCodes > 0 then
        self.State.SelectedBoss = self.Data.BossCodes[1]
    end
end


function H:BossHumanoid(rec)
    local m = rec and rec.Model

    return m
        and (
            m:FindFirstChildOfClass("Humanoid")
            or m:FindFirstChildWhichIsA("Humanoid", true)
        )
end

function H:BossAlive(rec)
    local h = self:BossHumanoid(rec)
    return h ~= nil and h.Health > 0
end

function H:RefreshMobs()
    table.clear(self.Data.Mobs)
    self.Data.MobNameMemory = self.Data.MobNameMemory or {}

    local root = self.S.Workspace:FindFirstChild("Humanoids")
    if root then
        for _, model in ipairs(root:GetDescendants()) do
            if model:IsA("Model")
                and model ~= self:Character()
                and model:GetAttribute("IsMob") == true then

                local hum = model:FindFirstChildOfClass("Humanoid")
                    or model:FindFirstChildWhichIsA("Humanoid", true)
                local rp = model:FindFirstChild("HumanoidRootPart", true)
                    or model.PrimaryPart

                if hum and rp and hum.MaxHealth > 0 then
                    table.insert(self.Data.Mobs, model)
                    self:RememberMobSpawn(model)
                    self:WatchMobDefense(model)

                    local name = tostring(model.Name or "")
                    if name ~= "" then self.Data.MobNameMemory[name] = true end
                end
            end
        end
    end

    -- Pull explicit hostile/mob definitions from the game's own live NPC table
    -- so entries can appear before their region is streamed.
    local live = self.Modules.LiveConfig
    if type(live) == "table" and type(live.get) == "function" then
        local ok, npcData = pcall(live.get, "NpcDataTable")
        if ok and type(npcData) == "table" then
            for key, entry in pairs(npcData) do
                if type(entry) == "table" then
                    local kind = string.lower(tostring(
                        entry.Type or entry.NpcType or entry.Category or ""
                    ))
                    local explicitMob =
                        entry.IsMob == true
                        or entry.Mob == true
                        or entry.Hostile == true
                        or entry.IsEnemy == true
                        or entry.Enemy == true
                        or kind == "mob"
                        or kind == "enemy"

                    if explicitMob then
                        local name = tostring(
                            entry.DisplayName
                            or entry.Name
                            or entry.NpcName
                            or entry.Title
                            or key
                            or ""
                        )
                        if name ~= "" then self.Data.MobNameMemory[name] = true end
                    end
                end
            end
        end
    end

    local names = {}
    for name in pairs(self.Data.MobNameMemory) do table.insert(names, name) end
    table.sort(names, function(a,b) return string.lower(a) < string.lower(b) end)

    self.Data.MobNames = {"Any"}
    for _, name in ipairs(names) do table.insert(self.Data.MobNames, name) end

    if self.Data.CurrentFarmTarget and not self.Data.CurrentFarmTarget.Parent then
        self.Data.CurrentFarmTarget = nil
    end
end


function H:RefreshSkills()
    local names = {}
    local unique = {}

    local folder =
        self.S.ReplicatedStorage:FindFirstChild("Skills")

    if folder then
        for _, obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("ModuleScript") then
                local n = obj.Name

                if not string.find(n, "Server", 1, true)
                    and not unique[n] then

                    unique[n] = true
                    table.insert(names, n)
                end
            end
        end
    end

    table.sort(names)

    self.Data.SkillNames = names

    if not self.State.SelectedSkill and #names > 0 then
        self.State.SelectedSkill = names[1]
    end
end

function H:RefreshTravel()
    local npcs = {}
    local places = {}
    local seenNPC = {}
    local seenPlace = {}

    for _, p in ipairs(self.S.Workspace:GetDescendants()) do
        if p:IsA("ProximityPrompt") then
            local model = p:FindFirstAncestorOfClass("Model")

            if model then
                local label =
                    tostring(p.ObjectText ~= "" and p.ObjectText or model.Name)

                if string.lower(p.ActionText) == "chat"
                    or string.find(string.lower(label), "trainer", 1, true)
                    or string.find(string.lower(label), "shop", 1, true) then

                    if not seenNPC[label] then
                        seenNPC[label] = model
                        table.insert(npcs, label)
                    end
                end

                if string.find(string.lower(p.ActionText), "spawn", 1, true)
                    or string.find(string.lower(p.ActionText), "unlock", 1, true)
                    or string.find(string.lower(label), "shrine", 1, true) then

                    if not seenPlace[label] then
                        seenPlace[label] = model
                        table.insert(places, label)
                    end
                end
            end
        end
    end

    table.sort(npcs)
    table.sort(places)

    self.Data.NPCs = {
        Names = npcs,
        Map = seenNPC,
    }

    self.Data.Places = {
        Names = places,
        Map = seenPlace,
    }

    if not self.State.SelectedNPC
        and #npcs > 0 then

        self.State.SelectedNPC = npcs[1]
    end

    if not self.State.SelectedPlace
        and #places > 0 then

        self.State.SelectedPlace = places[1]
    end
end

-- ============================================================
-- MOVEMENT
-- ============================================================

function H:StopMovement()
    self.Runtime.BossProbeHolding = false
    self:ClearBossHoverController()
    if self.Runtime.MovementSupport then
        self.Runtime.MovementSupport:Destroy()
        self.Runtime.MovementSupport = nil
    end

    if self.Runtime.ActiveTween then
        pcall(function()
            self.Runtime.ActiveTween:Cancel()
        end)
        self.Runtime.ActiveTween = nil
    end

    -- BUILD 15: clear the frame-driven walk state as well.  The old build only
    -- cancelled Tween/MoveTo, so the player controller could immediately fight
    -- the automation on the next render frame.
    self.Runtime.DrivenWalkGoal = nil
    self.Runtime.DrivenWalkTarget = nil
    self.Runtime.DrivenWalkWaypoints = nil
    self.Runtime.DrivenWalkIndex = nil
    self.Runtime.DrivenWalkNeedsReplan = false
    self.Runtime.DrivenWalkLastSample = nil
    self.Runtime.DrivenWalkLastSampleAt = nil
    self.Runtime.DrivenWalkLastProgressAt = nil

    local hum = self:Humanoid()
    if hum then
        pcall(function() self.Player:Move(Vector3.zero, false) end)
        hum:Move(Vector3.zero, false)
    end

    self.Runtime.MoveGoal = nil
    self.Runtime.MoveTarget = nil
end

-- LEGACY DIRECT STEERING HELPERS (unused by BUILD 29 progression)
-- Roblox's default PlayerModule writes Humanoid:Move() every render frame.
-- A one-shot Humanoid:MoveTo() on the local player's character can therefore be
-- overwritten immediately, which is exactly what the V4 mapper captured:
-- MoveDirection stayed 0 for 12 seconds even though MoveTo was being requested.
--
-- We plan a normal Roblox path, then drive Humanoid:Move() AFTER PlayerModule's
-- input step every rendered frame.  This remains ordinary walking (no teleport)
-- and lets Roblox physics/collision handle the character normally.
function H:PlanDrivenWalk(goal)
    -- Legacy compatibility helper; BUILD 29 progression does not call this.
    -- Keep the old function name so existing callers remain compatible, but
    -- direct steering does not generate or wait for waypoint paths.
    local root = self:Root()
    if not root or typeof(goal) ~= "Vector3" then
        return false
    end

    local r = self.Runtime
    r.DrivenWalkWaypoints = nil
    r.DrivenWalkIndex = nil
    r.DrivenWalkNeedsReplan = false
    r.DrivenWalkLastPlan = os.clock()
    r.DrivenWalkLastSample = root.Position
    r.DrivenWalkLastSampleAt = os.clock()
    r.DrivenWalkLastProgressAt = os.clock()
    return true
end

function H:StartDrivenWalk(goal, targetInstance)
    local root = self:Root()
    local hum = self:Humanoid()
    if not root or not hum or typeof(goal) ~= "Vector3" then
        return false
    end

    if self.Runtime.ActiveTween then
        pcall(function()
            self.Runtime.ActiveTween:Cancel()
        end)
        self.Runtime.ActiveTween = nil
    end

    local r = self.Runtime
    r.DrivenWalkGoal = goal
    r.DrivenWalkTarget = targetInstance
    r.MoveGoal = goal
    r.MoveTarget = targetInstance
    r.DrivenWalkWaypoints = nil
    r.DrivenWalkIndex = nil
    r.DrivenWalkNeedsReplan = false

    if not r.DrivenWalkLastSampleAt then
        r.DrivenWalkLastSample = root.Position
        r.DrivenWalkLastSampleAt = os.clock()
        r.DrivenWalkLastProgressAt = os.clock()
    end

    return true
end

function H:DirectSteerRay(origin, direction, ignoreTarget)
    if direction.Magnitude <= 0.01 then
        return nil
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = { self:Character() }
    if ignoreTarget and typeof(ignoreTarget) == "Instance" then
        table.insert(ignore, ignoreTarget)
    end
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = false

    return self.S.Workspace:Raycast(origin, direction, params)
end

function H:UpdateDrivenWalk()
    local r = self.Runtime
    local goal = r.DrivenWalkGoal
    if typeof(goal) ~= "Vector3"
        or self.State.Unloaded
        or self.State.Fly then
        return
    end

    -- Long-range streamed movement can still use the existing staged travel
    -- system, but BUILD 15 never generates a Roblox path and never waits for
    -- waypoints.  Local motion is continuous direct steering.
    if r.ActiveTween
        and r.ActiveTween.PlaybackState == Enum.PlaybackState.Playing then
        return
    end

    local root = self:Root()
    local hum = self:Humanoid()
    if not root or not hum or hum.Health <= 0 then
        return
    end

    -- User-tested safe range for this game. Keep it conservative and only
    -- apply it while ThumbsHub owns movement.
    if self:FarmOwnsMovement() then
        hum.WalkSpeed = 21
    end

    local delta = goal - root.Position
    local flat = Vector3.new(delta.X, 0, delta.Z)

    if flat.Magnitude <= 2.25 then
        hum:Move(Vector3.zero, false)
        return
    end

    local desired = flat.Unit
    local now = os.clock()

    -- Very cheap obstacle handling: three short rays, no path computation.
    -- This only changes heading when something is immediately in front.
    local origin = root.Position + Vector3.new(0, 1.7, 0)
    local probe = math.clamp(5 + hum.WalkSpeed * 0.12, 6, 8)
    local forwardHit = self:DirectSteerRay(origin, desired * probe, r.DrivenWalkTarget)

    if forwardHit then
        local up = Vector3.new(0, 1, 0)
        local right = desired:Cross(up)
        if right.Magnitude < 0.01 then
            right = Vector3.new(1, 0, 0)
        else
            right = right.Unit
        end

        local leftDir = (desired - right * 0.78).Unit
        local rightDir = (desired + right * 0.78).Unit
        local leftHit = self:DirectSteerRay(origin, leftDir * (probe + 2), r.DrivenWalkTarget)
        local rightHit = self:DirectSteerRay(origin, rightDir * (probe + 2), r.DrivenWalkTarget)

        if not leftHit and rightHit then
            desired = leftDir
            r.DirectSteerSide = -1
        elseif not rightHit and leftHit then
            desired = rightDir
            r.DirectSteerSide = 1
        elseif not leftHit and not rightHit then
            -- Alternate sides to stop oscillating on tree trunks/poles.
            local side = tonumber(r.DirectSteerSide) or 1
            desired = side > 0 and rightDir or leftDir
            r.DirectSteerSide = -side
        else
            -- Boxed in locally: keep pressure toward the target and hop.
            if hum.FloorMaterial ~= Enum.Material.Air then
                hum.Jump = true
            end
        end

        if hum.FloorMaterial ~= Enum.Material.Air
            and (forwardHit.Position.Y - root.Position.Y) < 3.0 then
            hum.Jump = true
        end
    elseif delta.Y > 3.25
        and flat.Magnitude < 8
        and hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end

    -- Avoid blindly walking off an obvious unloaded/large drop. This is one
    -- downward ray only, so it stays much cheaper than PathfindingService.
    local ahead = root.Position + desired * 4 + Vector3.new(0, 3, 0)
    local groundAhead = self:DirectSteerRay(ahead, Vector3.new(0, -13, 0), r.DrivenWalkTarget)
    if not groundAhead and hum.FloorMaterial ~= Enum.Material.Air then
        local side = tonumber(r.DirectSteerSide) or 1
        local right = desired:Cross(Vector3.new(0, 1, 0))
        if right.Magnitude > 0.01 then
            desired = (desired + right.Unit * side * 0.9).Unit
            r.DirectSteerSide = -side
        end
    end

    -- This is the important part: continuously write movement AFTER the stock
    -- Roblox control module so keyboard-idle input cannot zero our direction.
    -- Player:Move + Humanoid:Move together is much harder for the stock control
    -- module to cancel than the old one-shot Humanoid:MoveTo call.
    pcall(function()
        self.Player:Move(desired, false)
    end)
    hum:Move(desired, false)

    -- Lightweight stuck recovery. No path recompute: jump + temporary side bias.
    if now - (r.DrivenWalkLastSampleAt or 0) >= 0.35 then
        local last = r.DrivenWalkLastSample
        local moved = last and (root.Position - last).Magnitude or math.huge

        if moved >= 0.35 then
            r.DrivenWalkLastProgressAt = now
        elseif now - (r.DrivenWalkLastProgressAt or now) >= 0.75 then
            r.DirectSteerSide = -(tonumber(r.DirectSteerSide) or 1)
            if hum.FloorMaterial ~= Enum.Material.Air then
                hum.Jump = true
            end
            r.DrivenWalkLastProgressAt = now
        end

        r.DrivenWalkLastSample = root.Position
        r.DrivenWalkLastSampleAt = now
    end
end

function H:FarmOwnsMovement()
    return self.State.AutoQuest or self.State.SmartProgression
        or self.State.AutoFarmMobs or self.State.AutoWorldBoss
        or self.Runtime.Retreating
end

function H:NeedsMovementNoclip()
    if self.State.Noclip then
        return true
    end

    -- BUILD 55:
    -- World-boss travel gets an explicit noclip owner. Do not rely only on
    -- ActiveTween.PlaybackState because the farm loop can briefly replace or
    -- complete a tween while we're still crossing map geometry.
    if self.Runtime.BossTravelNoclip
        or self.Runtime.MobTravelNoclip
        or self.Runtime.MobSmoothTravelActive then

        return true
    end

    -- MOB ONLY: never let the legacy movement layer disable collision while
    -- selected-mob farming is running.
    if self.State.AutoFarmMobs then
        return false
    end

    local tween = self.Runtime.ActiveTween

    if tween
        and tween.PlaybackState == Enum.PlaybackState.Playing then
        return true
    end

    local target = self.Runtime.MoveTarget

    return self:FarmOwnsMovement()
        and self.State.FarmPosition == "Below"
        and target ~= nil
        and target.Parent ~= nil
        and (
            target:GetAttribute("IsMob") == true
            or self:IsBossModel(target)
        )
end

function H:SetMobTravelNoclip(enabled)
    enabled =
        enabled == true

    self.Runtime.MobTravelNoclip =
        enabled

    if not enabled then
        self.Runtime.MobApproachTravel =
            false
    end
end

function H:MobLongTravelGoal(mobRoot)
    local root =
        self:Root()

    if not root
        or not mobRoot then

        return nil
    end

    local delta =
        root.Position
        - mobRoot.Position

    local flat =
        Vector3.new(
            delta.X,
            0,
            delta.Z
        )

    local away

    if flat.Magnitude > 0.05 then
        away =
            flat.Unit
    else
        away =
            -Vector3.new(
                mobRoot.CFrame.LookVector.X,
                0,
                mobRoot.CFrame.LookVector.Z
            )

        if away.Magnitude < 0.05 then
            away =
                Vector3.new(
                    1,
                    0,
                    0
                )
        else
            away =
                away.Unit
        end
    end

    -- Finish a few studs from the mob, not inside its HumanoidRootPart.
    return mobRoot.Position
        + away * 4.25
end

function H:StopSmoothMobTravel()
    self.Runtime.MobSmoothTravelActive = false
    self.Runtime.MobSmoothTravelTarget = nil
    self.Runtime.MobSmoothTravelGoal = nil
    self.Runtime.MobSmoothTravelLastRefresh = 0

    if self.Runtime.MobSmoothTravelTween then
        pcall(function()
            self.Runtime.MobSmoothTravelTween:Cancel()
        end)

        self.Runtime.MobSmoothTravelTween = nil
    end

    if not self.Runtime.BossHoverActive then self:SetMobTravelNoclip(false) end
end

function H:SmoothMobTravelGoal(mobRoot)
    local root =
        self:Root()

    if not root
        or not mobRoot then

        return nil
    end

    -- BUILD 84 • NO KILL AURA
    -- Approach the mob like normal melee: same ground level, very close behind
    -- the target. No hovering above its head and no aura/orbit positioning.
    local look =
        mobRoot.CFrame.LookVector

    local flat =
        Vector3.new(
            look.X,
            0,
            look.Z
        )

    if flat.Magnitude < 0.05 then
        flat =
            Vector3.new(
                0,
                0,
                -1
            )
    else
        flat =
            flat.Unit
    end

    local rawGoal =
        mobRoot.Position
        - flat * 1.25

    local grounded =
        self:GroundClampPosition(
            rawGoal,
            root.Position.Y,
            2.55
        )

    return grounded
        or Vector3.new(
            rawGoal.X,
            mobRoot.Position.Y,
            rawGoal.Z
        )
end


function H:StartOrUpdateSmoothMobTravel(mob, mobRoot, goalOverride)
    local root = self:Root()
    local hum = self:Humanoid()

    if not root or not hum or not mob or not mobRoot then
        return false
    end

    local goal = goalOverride or self:SmoothMobTravelGoal(mobRoot)

    if not goal then
        return false
    end

    local now = os.clock()
    local oldGoal = self.Runtime.MobSmoothTravelGoal

    local targetChanged =
        self.Runtime.MobSmoothTravelTarget ~= mob

    local goalMoved =
        not oldGoal
        or (oldGoal - goal).Magnitude > 2.0

    local tweenMissing =
        not self.Runtime.MobSmoothTravelTween

    local refreshDue =
        now - (self.Runtime.MobSmoothTravelLastRefresh or 0)
            > (goalOverride and 0.40 or 0.18)

    -- On the first travel frame, clear any old movement controller once.
    if targetChanged then
        if self.Runtime.SimpleDirectTween then
            pcall(function()
                self.Runtime.SimpleDirectTween:Cancel()
            end)

            self.Runtime.SimpleDirectTween = nil
            self.Runtime.SimpleDirectGoal = nil
            self.Runtime.SimpleDirectKey = nil
        end

        if self.Runtime.ActiveTween then
            pcall(function()
                self.Runtime.ActiveTween:Cancel()
            end)

            self.Runtime.ActiveTween = nil
        end
    end

    -- The smoothness fix: do NOT recreate the tween every FarmStep.
    -- Refresh only when the mob has materially moved, the tween ended,
    -- or the target has been moving for a while.
    if targetChanged or goalMoved or tweenMissing or refreshDue then
        if self.Runtime.MobSmoothTravelTween then
            pcall(function()
                self.Runtime.MobSmoothTravelTween:Cancel()
            end)
        end

        self.Runtime.MobSmoothTravelTarget = mob
        self.Runtime.MobSmoothTravelGoal = goal
        self.Runtime.MobSmoothTravelLastRefresh = now
        self.Runtime.MobSmoothTravelActive = true

        self:SetMobTravelNoclip(true)

        pcall(function()
            hum.AutoRotate = false
        end)

        local distance = (root.Position - goal).Magnitude

        -- BUILD 69:
        -- Far targets get a much quicker approach, while shorter moves stay
        -- controlled enough not to overshoot the overhead position.
        local speed =
            distance > 180
            and 285
            or (
                distance > 80
                and 255
                or 225
            )

        if goalOverride and self.State.BossInstantTravel then speed = 4000 end

        local duration =
            math.max(
                distance / speed,
                goalOverride and self.State.BossInstantTravel and 0.04 or 0.07
            )

        local lookAt = Vector3.new(
            mobRoot.Position.X,
            goal.Y,
            mobRoot.Position.Z
        )

        if (lookAt - goal).Magnitude < 0.05 then
            lookAt = goal + root.CFrame.LookVector
        end

        local goalCFrame = goalOverride
            and self:BossHoverAimCFrame(
                goal, mobRoot.Position, mobRoot.CFrame.LookVector
            )
            or CFrame.lookAt(goal, lookAt)

        local tween =
            self.S.TweenService:Create(
                root,
                TweenInfo.new(
                    duration,
                    Enum.EasingStyle.Linear,
                    Enum.EasingDirection.Out
                ),
                {
                    CFrame = goalCFrame,
                }
            )

        self.Runtime.MobSmoothTravelTween = tween

        tween.Completed:Connect(function()
            if self.Runtime.MobSmoothTravelTween == tween then
                self.Runtime.MobSmoothTravelTween = nil
            end
        end)

        tween:Play()
    else
        -- Keep noclip ownership explicit for the whole journey.
        self.Runtime.MobSmoothTravelActive = true
        self:SetMobTravelNoclip(true)
    end

    -- Stop knockback / humanoid drift fighting the tween.
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)

    return true
end

function H:SetBossTravelNoclip(enabled)
    enabled =
        enabled == true

    if self.Runtime.BossTravelNoclip
        == enabled then

        return
    end

    self.Runtime.BossTravelNoclip =
        enabled

    if not enabled then
        -- Heartbeat will restore CollisionOriginal on the next frame.
        -- Also restore any manual collision cache immediately.
        if type(
            self.SetManualFarmNoclip
        ) == "function" then

            self:SetManualFarmNoclip(
                false
            )
        end
    end
end

function H:BossTravelCollisionStep()
    if not self:NeedsMovementNoclip() then return end
    local character = self:Character()
    if not character then return end
    if self.Runtime.TravelCollisionCharacter ~= character then
        if self.Runtime.TravelCollisionAdded then self.Runtime.TravelCollisionAdded:Disconnect() end
        self.Runtime.TravelCollisionCharacter = character
        self.Runtime.TravelCollisionParts = {}
        local parts = self.Runtime.TravelCollisionParts
        for _, obj in ipairs(character:GetDescendants()) do
            if obj:IsA("BasePart") then parts[#parts + 1] = obj end
        end
        self.Runtime.TravelCollisionAdded = self:Connect(character.DescendantAdded, function(obj)
            if obj:IsA("BasePart") then parts[#parts + 1] = obj end
        end)
    end
    local original = self.Runtime.CollisionOriginal or setmetatable({}, {__mode = "k"})
    self.Runtime.CollisionOriginal = original
    local parts = self.Runtime.TravelCollisionParts
    for i = #parts, 1, -1 do
        local part = parts[i]
        if not part.Parent or not part:IsDescendantOf(character) then
            table.remove(parts, i)
        else
            if original[part] == nil then original[part] = part.CanCollide end
            if part.CanCollide then part.CanCollide = false end
        end
    end
end

function H:UpdateMovementSupport()
    if self.State.AutoFarmMobs then
        local support = self.Runtime.MovementSupport
        local root = self:Root()
        local holding = self.Runtime.BossProbeHolding and self.State.AutoLevelFarm
            and root and not self.Runtime.AttackTarget and not self.Runtime.PostKillLooting
        if support and (not holding or support.Parent ~= root) then
            support:Destroy()
            self.Runtime.MovementSupport = nil
            support = nil
        end
        if holding and not support then
            support = Instance.new("BodyVelocity")
            support.Name = "ThumbsBossProbeSupport"
            support.MaxForce = Vector3.new(1000000, 1000000, 1000000)
            support.Velocity = Vector3.zero
            support.Parent = root
            self.Runtime.MovementSupport = support
        end
        return
    end

    local root=self:Root()
    local tween=self.Runtime.ActiveTween
    local moving=tween and tween.PlaybackState==Enum.PlaybackState.Playing
    local needed=root and not self.State.Fly and not self.State.Unloaded
        and (moving or (self:FarmOwnsMovement() and self.Runtime.MoveTarget~=nil
            and self.State.FarmPosition=="Below" and self:NeedsMovementNoclip()))
    local support=self.Runtime.MovementSupport
    if support and (not needed or support.Parent~=root) then
        support:Destroy();self.Runtime.MovementSupport=nil;support=nil
    end
    if needed and not support then
        support=Instance.new("BodyVelocity")
        support.Name="ThumbsMovementSupport"
        support.MaxForce=Vector3.new(0,1000000,0)
        support.Velocity=Vector3.zero
        support.Parent=root
        self.Runtime.MovementSupport=support
    end
end

function H:TargetPosition(base, targetCF, combatTarget)
    if combatTarget==false then return base end
    if self.State.FarmPosition == "Below" and combatTarget ~= false then
        local depth =
            math.clamp(
                tonumber(self.State.BelowDepth) or 4.5,
                2.5,
                6.0
            )

        if os.clock() < (self.Runtime.CombatTightUntil or 0) then
            depth = math.max(3.25, depth - 0.75)
        end

        local centre =
            targetCF
            and targetCF.Position
            or base

        local look =
            targetCF
            and targetCF.LookVector
            or Vector3.new(0, 0, -1)

        local flat =
            Vector3.new(
                look.X,
                0,
                look.Z
            )

        if flat.Magnitude < 0.01 then
            flat = Vector3.new(0, 0, -1)
        end

        return centre
            + Vector3.new(0, -depth, 0)
            - flat.Unit * 0.30
    end
    local useDistance =
        tonumber(
            self.State.Distance
        ) or 2

    -- If punches are registering locally but the target HP is not changing,
    -- temporarily hug the target much more tightly. This fixes the common
    -- case where the attack animation plays but the server hitbox misses.
    if os.clock()
        < (
            self.Runtime.CombatTightUntil
            or 0
        ) then

        useDistance =
            math.min(
                useDistance,
                1.65
            )
    end

    if targetCF then
        local offset

        if self.State.FarmPosition == "Front" then
            offset =
                CFrame.new(
                    0,
                    self.State.Height,
                    -useDistance
                )
        elseif self.State.FarmPosition == "Above" then
            offset =
                CFrame.new(
                    0,
                    math.max(
                        4,
                        self.State.Height
                        + useDistance
                    ),
                    0
                )
        else
            -- Behind keeps the player outside most frontal NPC attacks.
            offset =
                CFrame.new(
                    0,
                    self.State.Height,
                    useDistance
                )
        end

        return (
            targetCF
            * offset
        ).Position
    end

    return base
        + Vector3.new(
            0,
            self.State.Height,
            useDistance
        )
end

function H:TweenExact(position, lookAtPosition, bossProbeSpeed)
    local root = self:Root()

    self.Runtime.DrivenWalkGoal = nil
    self.Runtime.DrivenWalkTarget = nil
    self.Runtime.DrivenWalkWaypoints = nil
    self.Runtime.DrivenWalkIndex = nil

    if not root
        or not position then

        return false
    end

    if self.Runtime.ActiveTween then
        pcall(
            function()
                self.Runtime.ActiveTween:Cancel()
            end
        )
    end

    local distance =
        (
            root.Position
            - position
        ).Magnitude

    local speed = bossProbeSpeed
        and math.clamp(tonumber(bossProbeSpeed) or 380, 150, 5000)
        or math.max(35, self.State.TweenSpeed)

    local duration =
        math.max(
            distance / speed,
            0.05
        )

    local goalCF

    if lookAtPosition then
        goalCF =
            CFrame.lookAt(
                position,
                Vector3.new(
                    lookAtPosition.X,
                    position.Y,
                    lookAtPosition.Z
                )
            )
    else
        goalCF =
            CFrame.new(position)
    end

    local tw =
        self.S.TweenService:Create(
            root,
            TweenInfo.new(
                duration,
                Enum.EasingStyle.Linear
            ),
            {
                CFrame = goalCF,
            }
        )

    self.Runtime.ActiveTween = tw
    self.Runtime.MoveGoal = position
    self.Runtime.MoveTarget = nil
    tw:Play()

    return true
end

function H:MoveTo(position, targetCF, targetInstance)
    local root = self:Root()
    local hum = self:Humanoid()

    if not root or not hum or not position then
        return false
    end

    local combatTarget = targetInstance ~= nil and (
        targetInstance:GetAttribute("IsMob") == true
        or self:IsBossModel(targetInstance))
    local below = self.State.FarmPosition == "Below" and combatTarget
    local target = self:TargetPosition(position, targetCF, combatTarget)

    local moveDistance =
        (root.Position - target).Magnitude

    local useWalk =
        self.State.MovementType == "Walk"
        or self.State.MovementType == "Smart"

    if useWalk then
        -- BUILD 15: do not rely on one-shot Humanoid:MoveTo() for the local
        -- player. PlayerModule can overwrite it with zero movement every frame.
        return self:StartDrivenWalk(target, targetInstance)
    end

    -- Switching to tween mode: release the frame-driven walk first so the two
    -- movement systems can never fight each other.
    self.Runtime.DrivenWalkGoal = nil
    self.Runtime.DrivenWalkTarget = nil
    self.Runtime.DrivenWalkWaypoints = nil
    self.Runtime.DrivenWalkIndex = nil
    self.Runtime.DrivenWalkNeedsReplan = false
    hum:Move(Vector3.zero, false)
    -- Tween mode, plus Smart long-distance travel.
    -- Do not restart the same tween every 0.25 seconds. The first build
    -- continuously cancelled its own movement before it could settle.
    if self.Runtime.ActiveTween
        and self.Runtime.MoveGoal
        and (self.Runtime.MoveGoal - target).Magnitude <= (below and 0.20 or 0.75)
        and self.Runtime.MoveTarget == targetInstance
        and self.Runtime.ActiveTween.PlaybackState == Enum.PlaybackState.Playing then

        return true
    end

    local distance = moveDistance

    if distance <= (below and 0.35 or 2.5) then
        if self.Runtime.ActiveTween then
            pcall(function()
                self.Runtime.ActiveTween:Cancel()
            end)
            self.Runtime.ActiveTween = nil
        end

        self.Runtime.MoveGoal = target
        self.Runtime.MoveTarget = targetInstance
        return true
    end

    local speed = math.max(20, math.min(self.State.TweenSpeed, self.Runtime.QuestMoveSpeedCap or math.huge))
    local duration = math.max(distance / speed, 0.05)

    if self.Runtime.ActiveTween then
        pcall(function()
            self.Runtime.ActiveTween:Cancel()
        end)
    end

    local lookAt = targetCF and targetCF.Position or position

    local tw =
        self.S.TweenService:Create(
            root,
            TweenInfo.new(
                duration,
                Enum.EasingStyle.Linear
            ),
            {
                CFrame =
                    CFrame.lookAt(
                        target,
                        Vector3.new(
                            lookAt.X,
                            target.Y,
                            lookAt.Z
                        )
                    ),
            }
        )

    self.Runtime.ActiveTween = tw
    self.Runtime.MoveGoal = target
    self.Runtime.MoveTarget = targetInstance
    tw:Play()

    return true
end

function H:MoveToModel(model)
    if not model or not model.Parent then
        return false
    end

    local root =
        model:FindFirstChild("HumanoidRootPart", true)
        or model.PrimaryPart

    if not root then
        return false
    end

    return self:MoveTo(
        root.Position,
        root.CFrame,
        model
    )
end

-- ============================================================
-- COMBAT
-- ============================================================

function H:FaceTarget(model)
    if not model or not model:IsA("Model") then return end
    local root = self:Root()

    local targetRoot =
        model
        and (
            model:FindFirstChild(
                "HumanoidRootPart",
                true
            )
            or model.PrimaryPart
        )

    if not root
        or not targetRoot then

        return
    end

    pcall(
        function()
            local here = root.Position

            if self.Runtime.BossHoverActive == model and self.State.BossHoverFarm then
                return -- Stable hover owns orientation until it releases the root.
            end

            local look =
                Vector3.new(
                    targetRoot.Position.X,
                    here.Y,
                    targetRoot.Position.Z
                )

            if (look - here).Magnitude > 0.05 then
                root.CFrame =
                    CFrame.lookAt(
                        here,
                        look
                    )
            end
        end
    )
end

function H:CombatAvailable()
    local module =
        self.Modules.CombatAvailable

    if type(module) == "table"
        and type(module.Is) == "function" then

        local ok, available =
            pcall(
                module.Is
            )

        if ok then
            return available == true
        end
    end

    -- Fallback: if a Tool is already equipped, let the normal input path try.
    local character =
        self:Character()

    return character
        and character:FindFirstChildWhichIsA(
            "Tool"
        ) ~= nil
end

function H:IsCombatTool(tool)
    if not tool
        or not tool:IsA("Tool") then

        return false, 0
    end

    local name =
        string.lower(
            tostring(tool.Name)
        )

    -- Prefer the exact tool that the user confirmed makes combat work.
    if string.find(name, "fist", 1, true)
        or string.find(name, "hand", 1, true)
        or string.find(name, "unarmed", 1, true) then

        return true, 100
    end

    local items =
        self.Modules.Items

    if type(items) == "table" then
        local data =
            items[tool.Name]

        if type(data) == "table"
            and data.HasCombat == true then

            return true, 80
        end
    end

    local animations =
        self.S.ReplicatedStorage
        :FindFirstChild("Assets")

    animations =
        animations
        and animations:FindFirstChild(
            "Animations"
        )

    if animations
        and animations:FindFirstChild(
            tool.Name
            .. "_Combat_Anims"
        ) then

        return true, 70
    end

    -- Common weapon names are still valid lower-priority fallbacks.
    for _, word in ipairs(
        {
            "katana",
            "sword",
            "blade",
            "gauntlet",
            "claw",
            "scythe",
        }
    ) do
        if string.find(
            name,
            word,
            1,
            true
        ) then

            return true, 50
        end
    end

    return false, 0
end

function H:GetLastPunchStamp()
    local presets =
        self.Modules.CombatPresets

    if type(presets) ~= "table" then
        return 0
    end

    return tonumber(
        presets.Last_Punched
    ) or 0
end

function H:ResolvePunchFunction(force)
    if self.Runtime.PunchFunction
        and not force then

        return self.Runtime.PunchFunction
    end

    if typeof(getsenv) ~= "function" then
        return nil,
            "getsenv unavailable"
    end

    if not force
        and os.clock()
            - self.Runtime.LastPunchResolve
            < 1 then

        return nil,
            "resolve cooldown"
    end

    self.Runtime.LastPunchResolve =
        os.clock()

    local scripts =
        self.Player:FindFirstChild(
            "PlayerScripts"
        )

    local cu =
        scripts
        and scripts:FindFirstChild(
            "CU"
        )

    local combat =
        cu
        and cu:FindFirstChild(
            "Combat"
        )

    if not combat
        or not combat:IsA(
            "LocalScript"
        ) then

        return nil,
            "CU.Combat LocalScript not found"
    end

    local ok, env =
        pcall(
            getsenv,
            combat
        )

    if not ok
        or type(env) ~= "table" then

        return nil,
            "getsenv(CU.Combat) failed"
    end

    local punch =
        env.punch

    if typeof(punch)
        ~= "function" then

        return nil,
            "CU.Combat.punch not found"
    end

    self.Runtime.PunchScript =
        combat

    self.Runtime.PunchFunction =
        punch

    self.Runtime.AttackBackend =
        "DirectPunch"

    return punch
end

function H:TrySelectFists()
    if self:CombatAvailable() then
        return true
    end

    local curPower =
        self.Modules.CurPower

    local animations =
        self.S.ReplicatedStorage
        :FindFirstChild("Assets")

    animations =
        animations
        and animations:FindFirstChild(
            "Animations"
        )

    -- The real CU.Combat source gets unarmed combat from CurPower and looks
    -- for "<power>_Combat_Anims". Fists correspond to the Combat power.
    if curPower
        and curPower:IsA(
            "StringValue"
        )
        and animations
        and animations:FindFirstChild(
            "Combat_Combat_Anims"
        ) then

        pcall(
            function()
                curPower.Value =
                    "Combat"
            end
        )

        task.wait(0.04)

        if self:CombatAvailable() then
            return true
        end
    end

    return false
end

function H:EnsureCombatReady()
    if self:CombatAvailable() then
        return true
    end

    if self.State.AutoEquipCombat
        and self:TrySelectFists() then

        return true
    end

    if not self.State.AutoEquipCombat then
        return false
    end

    if os.clock()
        - self.Runtime.LastCombatEquip
        < 0.75 then

        return false
    end

    self.Runtime.LastCombatEquip =
        os.clock()

    local backpack =
        self.Player:FindFirstChildOfClass(
            "Backpack"
        )

    local best
    local bestScore = -1

    local function consider(container)
        if not container then
            return
        end

        for _, child in ipairs(
            container:GetChildren()
        ) do
            local valid, score =
                self:IsCombatTool(child)

            if valid
                and score > bestScore then

                best = child
                bestScore = score
            end
        end
    end

    consider(backpack)
    consider(self:Character())

    if best then
        local hum =
            self:Humanoid()

        if hum then
            pcall(
                hum.EquipTool,
                hum,
                best
            )

            task.wait(0.05)
        end
    end

    return self:CombatAvailable()
end

function H:StopAttackHold()
    -- DirectPunch does not hold or move the user's mouse.
    self.Runtime.AttackGeneration = (self.Runtime.AttackGeneration or 0) + 1
    self.Runtime.AttackHeld = false
    self.Runtime.AttackTarget = nil
end

function H:AttackBackendNames()
    return {
        "DirectPunch",
    }
end

function H:CanUseCombatNow()
    local checker =
        self.Modules.Checker

    if type(checker) == "table"
        and type(checker.check)
            == "function" then

        local ok, allowed =
            pcall(
                checker.check,
                self.Player,
                "combat"
            )

        if ok then
            return allowed == true
        end
    end

    -- If Checker cannot be read on a particular executor, don't falsely
    -- block farming; let CU.Combat.punch() be the final authority.
    return true
end

function H:TemporarilySkipCombatTarget(model, seconds, reason)
    if not model then
        return
    end

    if type(self.Data.CombatBlockedTargets)
        ~= "table" then

        self.Data.CombatBlockedTargets =
            setmetatable(
                {},
                {__mode = "k"}
            )
    end

    self.Data.CombatBlockedTargets[
        model
    ] =
        os.clock()
        + (
            tonumber(seconds)
            or 6
        )

    if self.Data.CurrentFarmTarget
        == model then

        self.Data.CurrentFarmTarget =
            nil
    end

    self.Runtime.AttackTarget = nil
    self:StopAttackHold()
    self:StopBlocking()

    self:SetStatus(
        "Skipping "
        .. tostring(model.Name)
        .. " • "
        .. tostring(
            reason
            or "combat unavailable"
        )
    )
end

function H:IsCombatTargetTemporarilyBlocked(model)
    if type(self.Data.CombatBlockedTargets)
        ~= "table" then

        self.Data.CombatBlockedTargets =
            setmetatable(
                {},
                {__mode = "k"}
            )
    end

    local untilAt =
        self.Data.CombatBlockedTargets[
            model
        ]

    if not untilAt then
        return false
    end

    if os.clock() >= untilAt then
        self.Data.CombatBlockedTargets[
            model
        ] = nil

        return false
    end

    return true
end

function H:TargetHumanoid(model)
    if not model or not model:IsA("Model") then return nil end
    if not model then
        return nil
    end

    return model:FindFirstChildOfClass(
        "Humanoid"
    )
        or model:FindFirstChildWhichIsA(
            "Humanoid",
            true
        )
end

function H:StickToCombatTarget(model, duration)
    if not model or not model.Parent then
        return
    end

    if self.State.AutoFarmMobs then
        local mobRoot =
            model:FindFirstChild("HumanoidRootPart", true)
            or model.PrimaryPart

        if mobRoot then
            self:ContinuousOrbitMovement(
                model,
                mobRoot
            )
        end

        self:FaceTarget(model)
        return
    end

    local generation = self.Runtime.AttackGeneration or 0
    local token = os.clock()
    self.Runtime.LastStickToken = token

    task.spawn(function()
        local untilAt =
            os.clock()
            + (tonumber(duration) or 0.34)

        while not self.State.Unloaded
            and self:IsFarmCombatActive()
            and generation == (self.Runtime.AttackGeneration or 0)
            and self.Runtime.AttackTarget == model
            and model.Parent
            and self.Runtime.LastStickToken == token
            and os.clock() < untilAt do

            local mobRoot =
                model:FindFirstChild("HumanoidRootPart", true)
                or model.PrimaryPart

            if mobRoot then
                self:MoveTo(
                    mobRoot.Position,
                    mobRoot.CFrame,
                    model
                )

                self:FaceTarget(model)
            end

            task.wait(0.035)
        end
    end)
end

function H:WaitForGuardRelease(timeout)
    timeout =
        tonumber(timeout)
        or 0.18

    local started =
        os.clock()

    while os.clock() - started < timeout do
        if self.State.Unloaded then
            return false
        end

        local character =
            self:Character()

        local blocking =
            character
            and character:FindFirstChild(
                "Blocking"
            )

        if not blocking
            and not self.Runtime.BlockHeld then

            return true
        end

        self.S.RunService.Heartbeat:Wait()
    end

    local character =
        self:Character()

    return not (
        character
        and character:FindFirstChild(
            "Blocking"
        )
    )
end


function H:BackgroundM1Interval(braking)
    if braking then return 0.16 end
    if self.State.RapidHits then
        local ms = tonumber(self.State.RapidHitIntervalMs) or 20
        if ms ~= ms or math.abs(ms) == math.huge then ms = 20 end
        return math.clamp(ms, 10, 200) / 1000
    end
    return self.State.AutoLevelFarm and 0.055 or 0.012
end

function H:RefreshRapidHitSchedule()
    if self.Runtime.InstantKillThresholdLocked or self.Runtime.InstantKillBusy
        or self.Runtime.NextBackgroundM1At == math.huge then return end
    -- A slider change never creates a second attack worker or a catch-up burst.
    local braking = self.State.InstantKill and self.Runtime.LastBackgroundM1Braking == true
    self.Runtime.NextBackgroundM1At = math.max(os.clock(),
        (self.Runtime.LastBackgroundM1AttemptAt or 0) + self:BackgroundM1Interval(braking))
end

function H:BackgroundM1Spam(targetModel)
    if self.Runtime.BackgroundM1Busy then
        return false
    end

    if self.State.Unloaded
        or not self.State.AutoFarmMobs
        or not targetModel
        or not targetModel.Parent then

        return false
    end

    if self.State.AutoLevelFarm then
        self.Runtime.InstantKillThresholdLocked = false
    end

    -- BUILD 83:
    -- Preserve Build68's proven continuous punch stream once engaged, but
    -- suppress air-punching during the initial approach only.
    if self.Runtime.MobApproachTravel
        or self.Runtime.MobSmoothTravelActive then

        return false
    end

    if self.State.AutoLevelFarm
        and self:CombatFloorSafetyStep() then

        return false
    end

    local targetHum =
        targetModel:FindFirstChildOfClass(
            "Humanoid"
        )

    local instantKillBraking =
        false

    if targetHum
        and self.State.InstantKill then

        local reached,
            braking =
            self:GetInstantKillHealthState(
                targetHum
            )

        instantKillBraking =
            braking == true

        if reached
            or self.Runtime.InstantKillBusy
            or self.Runtime.InstantKillThresholdLocked then

            self.Runtime.InstantKillThresholdLocked =
                reached
                or self.Runtime.InstantKillThresholdLocked

            self.Runtime.NextBackgroundM1At =
                math.huge

            return false
        end
    end

    local now =
        os.clock()

    if now
        < (
            self.Runtime.NextBackgroundM1At
            or 0
        ) then

        return false
    end

    local interval = self:BackgroundM1Interval(instantKillBraking)
    self.Runtime.NextBackgroundM1At = now + interval

    self.Runtime.BackgroundM1Busy =
        true

    local ok =
        pcall(
            function()
                -- Never let stale blocking stop the offensive stream.
                if self.Runtime.BlockHeld
                    or self:IsBlockingActive() then

                    self:StopBlocking()
                end

                self.Runtime.Defending =
                    false

                self.Runtime.BlockReleaseUntil =
                    0

                -- Refresh fists/combat periodically, but not on every 12ms
                -- spam tick.
                if now
                    >= (
                        self.Runtime.NextCombatReadyRefresh
                        or 0
                    ) then

                    self.Runtime.NextCombatReadyRefresh =
                        now + 0.65

                    self:EnsureCombatReady()
                end

                local punch =
                    self.Runtime.PunchFunction

                if typeof(punch) ~= "function" then
                    punch =
                        select(
                            1,
                            self:ResolvePunchFunction(
                                true
                            )
                        )
                end

                if typeof(punch) ~= "function" then
                    return
                end

                local before =
                    self:GetLastPunchStamp()

                -- Equipping may yield while the interval slider changes.
                interval = self:BackgroundM1Interval(instantKillBraking)
                local attemptedAt = os.clock()
                self.Runtime.LastBackgroundM1AttemptAt = attemptedAt
                self.Runtime.LastBackgroundM1Braking = instantKillBraking
                self.Runtime.NextBackgroundM1At = attemptedAt + interval

                local callOk,
                    cooldown =
                    pcall(
                        punch
                    )

                if not callOk then
                    self.Runtime.PunchFunction =
                        nil

                    self.Runtime.NextBackgroundM1At =
                        os.clock() + math.max(interval, 0.10)

                    return
                end

                local after =
                    self:GetLastPunchStamp()

                -- Count accepted combo inputs. Some versions return a numeric
                -- cooldown; others update Last_Punched first.
                if (
                    tonumber(cooldown)
                    and tonumber(cooldown) > 0
                )
                    or after > before then

                    self.Runtime.BackgroundM1Count =
                        (
                            self.Runtime.BackgroundM1Count
                            or 0
                        ) + 1

                    self.Runtime.LastBackgroundM1Accepted =
                        os.clock()
                end

                if self.State.AutoLevelFarm then
                    self:CombatFloorSafetyStep()
                end
            end
        )

    self.Runtime.BackgroundM1Busy =
        false

    return ok
end

function H:RapidWorldClickM1(targetModel)
    if self.Runtime.RapidClickBusy then
        return false
    end

    if not self.State.AutoFarmMobs
        or not targetModel
        or not targetModel.Parent then
        return false
    end

    if self.Runtime.MobApproachTravel
        or self.Runtime.MobSmoothTravelActive then
        return false
    end

    local rapidRoot =
        self:Root()

    local rapidTargetRoot =
        targetModel:FindFirstChild(
            "HumanoidRootPart",
            true
        )
        or targetModel.PrimaryPart

    if not rapidRoot
        or not rapidTargetRoot
        or (
            rapidRoot.Position
            - rapidTargetRoot.Position
        ).Magnitude > 6.30 then
        return false
    end

    self.Runtime.RapidClickBusy = true

    local ok = pcall(function()
        if self.Runtime.BlockHeld
            or self:IsBlockingActive() then
            self:StopBlocking()
        end

        self.Runtime.Defending = false
        self.Runtime.BlockReleaseUntil = 0

        local camera = self.S.Workspace.CurrentCamera
        local size =
            camera
            and camera.ViewportSize
            or Vector2.new(1280, 720)

        local x = math.floor(size.X * 0.24)
        local y = math.floor(size.Y * 0.62)

        -- Pure spam mode: 3 full left-clicks every call.
        for _ = 1, 3 do
            self.S.VirtualInputManager:SendMouseButtonEvent(
                x, y, 0, true, game, 0
            )

            task.wait(0.001)

            self.S.VirtualInputManager:SendMouseButtonEvent(
                x, y, 0, false, game, 0
            )

            self.Runtime.RapidClickCount =
                (self.Runtime.RapidClickCount or 0) + 1

            task.wait(0.001)
        end

        self.Runtime.LastRapidClickAt = os.clock()
    end)

    self.Runtime.RapidClickBusy = false
    return ok
end

function H:PulseAttack(targetModel)
    if self.Runtime.PunchBusy then return false end
    self.Runtime.PunchBusy = true
    local ok, result = pcall(self.PulseAttackImpl, self, targetModel)
    self.Runtime.PunchBusy = false
    if not ok then
        self.Runtime.LastPunchFailure = tostring(result)
        return false
    end
    return result
end

function H:PulseAttackImpl(targetModel)
    local generation = self.Runtime.AttackGeneration or 0
    if self.State.Unloaded then
        return false
    end

    self.Runtime.AttackTarget =
        targetModel

    self:FaceTarget(
        targetModel
    )

    local now =
        os.clock()

    local nearbyThreat = self.State.AutoParry and self:NearestActiveThreat()
    if nearbyThreat then
        self.Runtime.ForceAttackUntil = 0
        self.Runtime.BlockReleaseUntil = 0
        self:FaceTarget(nearbyThreat)
        self:StartBlocking(true)
        return false
    end

    -- Never drop guard to M1 while the current enemy is in an attack window.
    -- This is especially important for bosses where one missed parry can kill.
    if self:IsThreatWindow(
        targetModel
    ) then

        self.Runtime.ForceAttackUntil = 0
        self:StartBlocking(true)

        return true
    end

    -- Between punches, keep guard up. When the game's real punch cooldown is
    -- over we deliberately open a clean attack window.
    if now
        < self.Runtime.NextPunchAt then

        if self.State.PerfectBlock then
            self:GuardStep(
                targetModel
            )
        end

        return true
    end

    -- CRITICAL FIX:
    -- StopHold("Blocking") is not always reflected in the Character on the
    -- same frame. Calling CU.Combat.punch() while Blocking still exists makes
    -- Checker.check(..., "combat") reject the punch. Wait for the actual block
    -- state to disappear before invoking the game's punch function.
    if self.State.PerfectBlock
        and (
            self.Runtime.Defending
            or self:IsBlockingActive()
        ) then

        self:StopBlocking()

        self.Runtime.BlockReleaseUntil =
            os.clock() + math.clamp(self:DefenseLatency() + 0.16, 0.18, 0.40)

        if not self:WaitForGuardRelease(
            math.clamp(self:DefenseLatency() + 0.12, 0.14, 0.40)
        ) then

            self.Runtime.LastPunchFailure =
                "guard did not release"

            self.Runtime.NextPunchAt =
                os.clock() + 0.06

            self:SetStatus(
                "Combat • waiting for block release..."
            )

            return false
        end
    elseif self.Runtime.Defending then
        return false
    end

    -- This is the exact gate used inside CU.Combat.punch().
    -- If it is false here, repeatedly calling punch() cannot work. The most
    -- obvious case in the user's screenshot is the green "In safe zone"
    -- state, so move on to another matching quest target instead of standing
    -- still beside the protected NPC.
    if not self:CanUseCombatNow() then
        self.Runtime.LastPunchFailure = "Game rejected combat state (guard, stun, cooldown or safe zone)"
        local sampleNow = os.clock()
        if self.Runtime.CombatRejectTarget ~= targetModel then
            self.Runtime.CombatRejectTarget = targetModel
            self.Runtime.CombatRejectSince = sampleNow
        end
        self.Runtime.NextPunchAt =
            sampleNow
            + (
                self.State.AutoFarmMobs
                and 0.018
                or 0.10
            )
        self.Runtime.BlockReleaseUntil = 0
        self:GuardStep(targetModel)
        if sampleNow - (self.Runtime.CombatRejectSince or sampleNow) > 1.5 then
            self:TemporarilySkipCombatTarget(targetModel, 4, "combat state rejected repeatedly")
            self.Runtime.CombatRejectTarget = nil
        end
        return false
    end
    self.Runtime.CombatRejectTarget = nil

    if not self:EnsureCombatReady() then
        self.Runtime.LastPunchFailure =
            "combat unavailable"

        self:SetStatus(
            "Combat • selecting Fists/Combat..."
        )

        self.Runtime.NextPunchAt =
            os.clock()
            + (
                self.State.AutoFarmMobs
                and 0.018
                or 0.08
            )

        return false
    end

    local punch, reason =
        self:ResolvePunchFunction()

    if typeof(punch)
        ~= "function" then

        self.Runtime.LastPunchFailure =
            tostring(reason)

        self:SetStatus(
            "Combat • direct punch unavailable • "
            .. tostring(reason)
        )

        self.Runtime.NextPunchAt =
            os.clock() + 0.10

        return false
    end

    if self.State.Unloaded or not self:IsFarmCombatActive()
        or generation ~= (self.Runtime.AttackGeneration or 0)
        or self.Runtime.AttackTarget ~= targetModel then
        return false
    end
    if self:IsThreatWindow(targetModel)
        or (self.State.AutoParry and self:NearestActiveThreat()) then
        self.Runtime.ForceAttackUntil = 0
        self.Runtime.BlockReleaseUntil = 0
        self:StartBlocking(true)
        return false
    end

    local before =
        self:GetLastPunchStamp()

    local targetHum =
        self:TargetHumanoid(
            targetModel
        )

    local targetHealthBefore =
        targetHum
        and targetHum.Health
        or nil

    -- Stay attached to the moving NPC across the server hitbox timing window.
    self:StickToCombatTarget(
        targetModel,
        0.42
    )

    local ok, cooldown =
        pcall(
            punch
        )

    if not ok then
        self.Runtime.PunchFunction =
            nil

        self.Runtime.LastPunchFailure =
            "punch error: "
            .. tostring(cooldown)

        self.Runtime.NextPunchAt =
            os.clock() + 0.12

        self:SetStatus(
            "Combat • punch error • "
            .. tostring(cooldown)
        )

        return false
    end

    local waitFor =
        tonumber(cooldown)

    -- A successful CU.Combat.punch() returns the real combo cooldown.
    -- nil means it was rejected by the game's current combat state.
    if not waitFor
        or waitFor <= 0 then

        task.wait(0.035)

        local afterImmediate =
            self:GetLastPunchStamp()

        if afterImmediate <= before then
            self.Runtime.AttackFailures += 1

            self.Runtime.LastPunchFailure =
                "punch() rejected by combat state"

            self.Runtime.NextPunchAt =
                os.clock()
                + (
                    self.State.AutoFarmMobs
                    and 0.018
                    or 0.08
                )

            if self.Runtime.AttackFailures >= 2 then
                self.Runtime.AttackFailures = 0

                self:TemporarilySkipCombatTarget(
                    targetModel,
                    5,
                    "punch rejected"
                )
            elseif self.State.PerfectBlock then
                self.Runtime.BlockReleaseUntil = 0
                self:StartBlocking(true)
            end

            return false
        end

        waitFor = 0.25
    end

    local rapidInterval =
        math.clamp(
            (
                tonumber(
                    waitFor
                )
                or 0.12
            ) * 0.32,
            0.018,
            0.034
        )

    self.Runtime.NextPunchAt =
        os.clock()
        + rapidInterval

    self.Runtime.LastAttackPulse =
        os.clock()

    -- Do NOT re-block 35ms after starting the punch. That was short enough to
    -- cancel/interrupt the attack before its hit frame. Let the M1 animate,
    -- then guard for the remainder of its cooldown.
    if self.State.PerfectBlock
        and targetModel
        and targetModel.Parent
        and not self.State.AutoFarmMobs then

        local guardDelay =
            math.clamp(
                waitFor * 0.40
                    - self:DefenseLatency() * 0.20,
                0.085,
                0.145
            )

        task.delay(
            guardDelay,
            function()
                if not self.State.Unloaded
                    and self.State.PerfectBlock
                    and self:IsFarmCombatActive()
                    and self.Runtime.AttackTarget == targetModel
                    and generation == (self.Runtime.AttackGeneration or 0)
                    and self:IsThreatInRange(
                        targetModel,
                        12
                    ) then

                    self.Runtime.BlockReleaseUntil =
                        0

                    self:StartBlocking(true)
                end
            end
        )
    end

    task.delay(
        0.04,
        function()
            if self.State.Unloaded then
                return
            end

            local after =
                self:GetLastPunchStamp()

            if after > before then
                self.Runtime.LastVerifiedPunch =
                    after

                self.Runtime.LastVerifiedPunchAt =
                    os.clock()

                self.Runtime.AttackFailures = 0

                -- Last_Punched only proves the local M1 fired. What matters to
                -- farming is whether the TARGET actually lost HP.
                task.delay(
                    0.32,
                    function()
                        if self.State.Unloaded
                            or not self:IsFarmCombatActive()
                            or self.Runtime.AttackTarget ~= targetModel
                            or not targetModel
                            or not targetModel.Parent then

                            return
                        end

                        local currentHum =
                            self:TargetHumanoid(
                                targetModel
                            )

                        if not currentHum
                            or currentHum.Health <= 0 then

                            self.Runtime.HitMissStreak = 0
                            self.Runtime.LastHitConfirmAt =
                                os.clock()
                            self.Runtime.LastPunchFailure = ""
                            return
                        end

                        if targetHealthBefore
                            and currentHum.Health
                                < targetHealthBefore then

                            self.Runtime.HitMissStreak = 0
                            self.Runtime.LastHitConfirmAt =
                                os.clock()
                            self.Runtime.LastPunchFailure = ""

                            self.Runtime.OrbitHardContactUntil =
                                0

                            return
                        end

                        self.Runtime.HitMissStreak += 1

                        self.Runtime.LastPunchFailure =
                            "M1 fired but hitbox missed"

                        -- BUILD 55:
                        -- M1 definitely fired but did not damage the target.
                        -- Tighten the orbit itself; the old CombatTightUntil
                        -- flag did nothing to the RenderStepped orbit.
                        self.Runtime.CombatTightUntil =
                            os.clock() + 1.35

                        self.Runtime.OrbitHardContactUntil =
                            os.clock() + 0.85

                        self.Runtime.OrbitContactUntil =
                            os.clock() + 0.90

                        self.Runtime.OrbitBoostUntil =
                            0

                        self.Runtime.ForceAttackUntil = 0
                        self.Runtime.BlockReleaseUntil = 0
                        self:GuardStep(targetModel)

                        self.Runtime.NextPunchAt =
                            math.min(
                                self.Runtime.NextPunchAt,
                                os.clock() + 0.06
                            )
                    end
                )

                if not self.State.PerfectBlock
                    and self.State.SafeCombat
                    and self.State.AutoParry
                    and targetModel
                    and targetModel.Parent then

                    self:TriggerDefense(
                        targetModel,
                        0.03,
                        0.30
                    )
                end
            else
                self.Runtime.AttackFailures += 1

                self.Runtime.LastPunchFailure =
                    "punch() did not start"

                self.Runtime.ForceAttackUntil = 0
                self.Runtime.BlockReleaseUntil = 0
                self:GuardStep(targetModel)

                if self.Runtime.AttackFailures >= 3 then
                    self.Runtime.PunchFunction =
                        nil

                    self.Runtime.AttackFailures =
                        0
                end
            end
        end
    )

    return true
end

function H:StartAttackHold(targetModel)
    return self:PulseAttack(
        targetModel
    )
end

function H:M1(targetModel)
    return self:PulseAttack(
        targetModel
    )
end

function H:UseSkill(skill)
    if self.State.AutoParry and self.Runtime.AttackTarget
        and self:IsThreatWindow(self.Runtime.AttackTarget) then
        return
    end
    if not skill or skill == "" then
        return
    end

    if os.clock() - self.Runtime.LastSkill < 0.65 then
        return
    end

    local controller = self.Modules.SkillController

    if type(controller) ~= "table"
        or type(controller.Attempt_Hold) ~= "function" then

        return
    end

    self.Runtime.LastSkill = os.clock()

    local ok, result =
        pcall(
            controller.Attempt_Hold,
            skill
        )

    if ok then
        task.delay(
            0.15,
            function()
                if type(controller.StopHold) == "function" then
                    pcall(
                        controller.StopHold,
                        skill
                    )
                end
            end
        )
    else
        self:SetStatus(
            "Skill failed • "
            .. tostring(result)
        )
    end
end

-- ============================================================
-- SAFE COMBAT
-- ============================================================

function H:HealthPercent()
    local hum =
        self:Humanoid()

    if not hum
        or hum.MaxHealth <= 0 then

        return 100
    end

    return
        (
            hum.Health
            / hum.MaxHealth
        )
        * 100
end

function H:RetreatFrom(model)
    if not self.State.SafeCombat
        or self.State.Unloaded then

        return false
    end

    local myRoot =
        self:Root()

    local targetRoot =
        model
        and (
            model:FindFirstChild(
                "HumanoidRootPart",
                true
            )
            or model.PrimaryPart
        )

    if not myRoot then
        return false
    end

    -- Retreat only once per low-health episode. The previous implementation
    -- moved another 24 studs every ~0.55s, which could leave the character
    -- extremely far away by the time health recovered.
    if self.Runtime.Retreating
        and self.Runtime.RetreatPosition then

        return true
    end

    self.Runtime.LastRetreat =
        os.clock()

    self.Runtime.Retreating = true
    self.Runtime.RetreatTarget =
        model

    self.Runtime.RetreatStartedAt =
        os.clock()

    self:StopAttackHold()

    if self.State.AutoParry
        and model then

        self.Runtime.ForceAttackUntil = 0
        self:StartBlocking(true)
    end

    local away =
        Vector3.new(
            1,
            0,
            0
        )

    if targetRoot then
        local delta =
            myRoot.Position
            - targetRoot.Position

        if delta.Magnitude > 0.05 then
            local flat =
                Vector3.new(
                    delta.X,
                    0,
                    delta.Z
                )

            if flat.Magnitude > 0.05 then
                away =
                    flat.Unit
            end
        end
    end

    local retreatDistance =
        self:IsBossModel(model)
        and 34
        or 24

    local destination =
        myRoot.Position
        + away * retreatDistance
        + Vector3.new(
            0,
            3,
            0
        )

    self.Runtime.RetreatPosition =
        destination

    self:TweenExact(
        destination,
        targetRoot
        and targetRoot.Position
        or nil
    )

    return true
end

function H:SafeCombatHealthStep(targetModel)
    self.State.ResumeHealthPercent = math.clamp(
        math.max(self.State.ResumeHealthPercent, self.State.RetreatHealthPercent + 5), 5, 100)
    if not self.State.SafeCombat then
        self.Runtime.Retreating = false
        self.Runtime.RetreatTarget = nil
        self.Runtime.RetreatPosition = nil
        return false
    end

    local hp =
        self:HealthPercent()

    if self.Runtime.Retreating then
        if hp
            >= self.State.ResumeHealthPercent then

            local resumeTarget =
                (
                    targetModel
                    and targetModel.Parent
                )
                and targetModel
                or (
                    self.Runtime.RetreatTarget
                    and self.Runtime.RetreatTarget.Parent
                    and self.Runtime.RetreatTarget
                    or nil
                )

            -- Kill the retreat tween/state before re-engaging. This is the key
            -- fix for "heals but never attacks again".
            self:StopMovement()

            self.Runtime.Retreating = false
            self.Runtime.RetreatTarget = nil
            self.Runtime.RetreatPosition = nil
            self.Runtime.RetreatStartedAt = 0
            self.Runtime.LastRetreat = 0
            self.Runtime.NextPunchAt = 0
            self.Runtime.ForceAttackUntil = 0
            self.Runtime.AttackFailures = 0

            self:StopBlocking()

            if resumeTarget then
                self.Data.CurrentFarmTarget =
                    resumeTarget

                local root =
                    resumeTarget:FindFirstChild(
                        "HumanoidRootPart",
                        true
                    )
                    or resumeTarget.PrimaryPart

                if root then
                    self:MoveTo(
                        root.Position,
                        root.CFrame,
                        resumeTarget
                    )
                end
            end

            self:SetStatus(
                "Safe Combat • recovered • re-engaging"
            )

            return false
        end

        self:StopAttackHold()

        -- Stay at the first retreat point instead of retreating farther every
        -- loop. If the enemy closes the gap, refresh the same defensive hold.
        if self.State.AutoParry
            and targetModel
            and self:IsThreatInRange(
                targetModel,
                self:IsBossModel(targetModel)
                and 26
                or 16
            ) then

            self:StartBlocking(false)
        end

        self:SetStatus(
            "Safe Combat • healing • HP "
            .. tostring(
                math.floor(hp)
            )
            .. "%"
            .. " • resume "
            .. tostring(
                math.floor(
                    self.State.ResumeHealthPercent
                )
            )
            .. "%"
        )

        return true
    end

    if hp
        <= self.State.RetreatHealthPercent then

        self.Runtime.Retreating = false
        self.Runtime.RetreatPosition = nil
        self.Runtime.RetreatTarget =
            targetModel

        self:RetreatFrom(
            targetModel
        )

        self:SetStatus(
            "Safe Combat • LOW HP • retreat "
            .. tostring(
                math.floor(hp)
            )
            .. "%"
        )

        return true
    end

    return false
end


function H:SuspendBossLoopForRespawn()
    self:ReleaseBossHold("waiting for respawn")
    self.Runtime.BossOwnershipSample = nil
    local store = self.Data.AutoLevel
    local rec = store and store.CurrentRecord
    if not self.State.AutoLevelFarm or type(rec) ~= "table" or rec.Category ~= "BossHunt" then return end
    store.BossLoopRespawning = true
    if store.BossLoopAdvancePending then return end
    store.BossLoopResumeTarget = rec.Target
    store.BossLoopResumeRecord = rec
    store.BossLoopResumePosition = self.Runtime.LastSafeQuestTargetPosition
        or store.BossLoopLastSeenPosition or rec.Spawn
    store.BossLoopSeenTarget = false
    store.BossLoopLastSeenAt = 0
end

function H:ResumeBossLoopAfterRespawn()
    local store = self.Data.AutoLevel
    if type(store) ~= "table" then return end
    store.BossLoopRespawning = false
    local rec = store.BossLoopResumeRecord
    if store.BossLoopResumeTarget and rec and not store.BossLoopAdvancePending then
        self.State.SelectedMob = store.BossLoopResumeTarget
        store.CurrentTarget, store.CurrentRecord = store.BossLoopResumeTarget, rec
        store.CurrentLevel = select(1, self:GetAutoLevelEffectiveLevel())
        store.BossLoopSeenTarget = false
        store.BossLoopSeenTargetKey = nil
        if self:ValidBossPosition(store.BossLoopResumePosition) then
            self.Runtime.LastSafeQuestTargetQuery = store.BossLoopResumeTarget
            self.Runtime.LastSafeQuestTargetPosition = store.BossLoopResumePosition
            self.Runtime.LastSafeQuestTargetAt = os.clock()
        end
    end
    self.Runtime.AutoLevelTargetSetAt = os.clock()
    self.Runtime.BossProbeDestination = nil
    self.Runtime.BossProbeInitialDistance = nil
    self.Runtime.BossProbeArrivedAt = nil
    self.Runtime.BossProbeInstantTarget = nil
    self.Runtime.BossProbeHolding = false
    self.Runtime.BossInstantLastAttemptTarget = nil
    self.Runtime.QuestEnemyCache = nil
    self.Runtime.LastExactQuestMissQuery = nil
    self.Runtime.MobSafeCFrame = nil
    self.Runtime.MobSafeAt = 0
    self.Runtime.CombatSafetyHoldUntil = 0
end

function H:WatchHealthForDefense(character)
    local hum =
        character
        and character:FindFirstChildOfClass(
            "Humanoid"
        )

    if not hum then
        return
    end

    self.Runtime.LastHealth =
        hum.Health

    self:Connect(
        hum.Died,
        function()
            if not self.State.AutoFarmMobs then
                return
            end

            self:SuspendBossLoopForRespawn()
            self.Runtime.BossProbeHolding = false
            self:StopSmoothMobTravel()
            self:StopMovement()
            self:StopAttackHold()
            self:StopBlocking()

            if self.Runtime.SimpleDirectTween then
                pcall(function()
                    self.Runtime.SimpleDirectTween:Cancel()
                end)

                self.Runtime.SimpleDirectTween =
                    nil

                self.Runtime.SimpleDirectGoal =
                    nil

                self.Runtime.SimpleDirectKey =
                    nil
            end

            self.Runtime.AttackTarget =
                nil

            self.Data.CurrentFarmTarget =
                nil

            self:ResetAggressiveMobState()
            self:ResetOrbitState()

            self.Runtime.MobResumeAfterRespawn =
                true

            self.Runtime.ResumeAutoLevelAfterRespawn =
                self.State.AutoLevelFarm == true

            self.Runtime.ResumeMobFarmAfterRespawn =
                self.State.AutoFarmMobs == true

            if self.Runtime.ResumeAutoLevelAfterRespawn then
                self.State.AutoLevelFarm = true
                self.State.AutoFarmMobs = true
                self.State.AutoAccept = true
            end

            self:SetStatus(
                self.Runtime.ResumeAutoLevelAfterRespawn
                and "Auto Level • died • waiting for respawn • will resume automatically"
                or "Mob Farm • died • waiting for respawn • farm stays ON"
            )
        end
    )

    self:Connect(
        hum.HealthChanged,
        function(newHealth)
            local oldHealth =
                self.Runtime.LastHealth

            self.Runtime.LastHealth =
                newHealth

            if not oldHealth
                or newHealth >= oldHealth
                or not self.State.SafeCombat
                or not self.State.AutoParry
                or not self:IsFarmCombatActive() then

                return
            end

            self.Runtime.LastHealthDrop =
                os.clock()

            if self.State.AutoFarmMobs then
                -- A confirmed hit means our prediction missed. Do not instantly
                -- trade another M1 into the enemy's combo.
                self.Runtime.MobDamagePauseUntil =
                    os.clock() + 0.055

                self.Runtime.MobDamageTakenAt =
                    os.clock()

                -- A real hit means the mob tracked our current orbit. Reverse
                -- direction once and temporarily increase angular speed.
                self.Runtime.OrbitDirection =
                    -(
                        self.Runtime.OrbitDirection
                        or 1
                    )

                self.Runtime.OrbitBoostUntil =
                    os.clock() + 0.48
            end

            if self.State.PingAwareParry then
                -- If damage still got through, bias future pulses earlier.
                -- This adapts not only to network latency but also to the
                -- executor/game's observed local timing.
                self.Runtime.ParryPenaltyMs =
                    math.clamp(
                        (
                            tonumber(
                                self.Runtime.ParryPenaltyMs
                            ) or 0
                        )
                        + 18,
                        0,
                        140
                    )
            end

            local target = self.Runtime.AttackTarget
            if not self:IsCombatModel(target) then
                local fallback = self.Data.CurrentFarmTarget
                target = self:IsCombatModel(fallback) and fallback or nil
            end

            if target then

                self.Runtime.ForceAttackUntil = 0
                self:SetThreatWindow(
                    target,
                    self:IsBossModel(target)
                    and 1.0
                    or 0.55
                )

                -- Damage means the animation-based predictor missed a hit.
                -- Immediately block the rest of that enemy combo.
                if self.State.PerfectBlock then
                    self:PerfectBlockPulse(
                        target,
                        0.75
                    )
                else
                    self:TriggerDefense(
                        target,
                        0,
                        0.50
                    )
                end
            end
        end
    )
end

-- ============================================================
-- SMART BLOCK / PARRY
-- ============================================================
-- BUILD 15: quest fallback + frame-driven player movement controller.
-- Stream-safe staged travel and combat/navigation isolation remain enabled.

function H:IsFarmCombatActive()
    return self.State.AutoFarmMobs
        or self.State.AutoQuest
        or self.State.AutoWorldBoss
        or self.State.KillAura
end

function H:CombatRoot(model)
    if not model or not model:IsA("Model") or not model.Parent then
        return nil, nil
    end

    local hum = self:TargetHumanoid(model)
    if not hum or hum.Health <= 0 then
        return nil, hum
    end

    local root = model:FindFirstChild("HumanoidRootPart", true)
        or model.PrimaryPart
        or model:FindFirstChildWhichIsA("BasePart", true)

    if not root or not root:IsA("BasePart") then
        return nil, hum
    end

    return root, hum
end

function H:IsCombatModel(model)
    if not model or not model:IsA("Model") or not model.Parent then
        return false
    end

    -- Normal enemies are tagged by the game with IsMob. Bosses are also allowed
    -- through the hub's boss registry. Dialogue NPCs and map scenery are rejected.
    if model:GetAttribute("IsMob") ~= true and not self:IsBossModel(model) then
        local rec = self.Data.AutoLevel and self.Data.AutoLevel.CurrentRecord
        local exactBossLoopTarget = self.State.AutoLevelFarm
            and type(rec) == "table" and rec.Category == "BossHunt"
            and self.Runtime.AttackTarget == model
        if not exactBossLoopTarget then return false end
    end

    local root, hum = self:CombatRoot(model)
    return root ~= nil and hum ~= nil and hum.Health > 0
end

function H:IsThreatInRange(model, maxDistance)
    if not self:IsCombatModel(model) then return false end

    local myRoot = self:Root()
    local theirRoot = self:CombatRoot(model)
    if not myRoot or not theirRoot then return false end

    return (myRoot.Position - theirRoot.Position).Magnitude <= (maxDistance or 18)
end

function H:GetPingMs()
    local now = os.clock()
    if now - (self.Runtime.LastPingSample or -1) < 0.20 then
        return tonumber(self.Runtime.PingMs) or 0
    end
    self.Runtime.LastPingSample = now
    local measured
    pcall(function()
        local network = self.S.Stats:FindFirstChild("Network")
        local stats = network and network:FindFirstChild("ServerStatsItem")
        local item = stats and stats:FindFirstChild("Data Ping")
        if item then measured = tonumber(item:GetValue()) end
    end)
    if not measured then
        pcall(function() measured = self.Player:GetNetworkPing() * 2000 end)
    end
    if measured and measured >= 0 and measured < 5000 then
        local old = self.Runtime.PingMs
        local delta = old and math.abs(measured - old) or 0
        self.Runtime.PingJitterMs = (self.Runtime.PingJitterMs or 0) * 0.75 + delta * 0.25
        -- Respond to rising latency quickly, decay conservatively after spikes.
        local alpha = old and measured > old and 0.65 or 0.25
        self.Runtime.PingMs = old and (old + (measured - old) * alpha) or measured
        self.Runtime.RawPingMs = measured
        self.Runtime.PingValidAt = now
    end
    return tonumber(self.Runtime.PingMs) or 0
end

function H:DefenseLatency()
    self:GetPingMs()
    if not self.State.PingAwareParry then return 0 end
    local ping = math.max(self.Runtime.PingMs or 0, self.Runtime.RawPingMs or 0)
    if not self.Runtime.PingValidAt or os.clock() - self.Runtime.PingValidAt > 3 then
        ping = math.max(ping, 120)
    end
    return math.clamp(ping / 2000 + (self.Runtime.PingJitterMs or 0) / 1000, 0, 0.40)
end

function H:IsBossModel(model)
    if not model then
        return false
    end

    for _, rec in pairs(
        self.Data.Bosses
    ) do
        if rec
            and rec.Model == model then

            return true
        end
    end

    return false
end

function H:AdaptiveParryProfile(model, track)
    local ping = self:GetPingMs()
    local latency = self:DefenseLatency()
    local safety = (tonumber(self.State.ParrySafetyMs) or 35) / 1000
    -- A damage penalty decays after a quiet period; it cannot permanently slow combat.
    local penalty = (tonumber(self.Runtime.ParryPenaltyMs) or 0) / 1000
    local quiet = os.clock() - (self.Runtime.LastHealthDrop or os.clock())
    if quiet > 4 then penalty = penalty * math.exp(-(quiet - 4) / 6) end
    local lead = math.clamp(latency + safety + penalty, 0.025, 0.45)
    local boss = self:IsBossModel(model)
    local length = track and tonumber(track.Length) or 0
    local speed = math.max(0.05, math.abs(track and tonumber(track.Speed) or 1))
    local elapsed = track and tonumber(track.TimePosition) or 0
    local remaining = math.max(0, (length - elapsed) / speed)
    local impact = length > 0.05
        and math.max(0, (length * (boss and 0.42 or 0.36) - elapsed) / speed)
        or (boss and 0.34 or 0.24)
    local hold = math.clamp(
        (length > 0.05 and remaining or (boss and 0.55 or 0.28)) + lead,
        boss and 0.40 or 0.22, boss and 2.5 or 1.6)
    self.Runtime.GuardLeadMs = math.floor(lead * 1000 + 0.5)
    self.Runtime.GuardHoldMs = math.floor(hold * 1000 + 0.5)
    return math.max(0, impact - lead), hold, ping, lead
end

function H:NearestActiveThreat()
    local best, bestDistance
    local now = os.clock()
    local mine = self:Root()

    for model, untilAt in pairs(self.Runtime.ThreatUntil or {}) do
        if untilAt <= now or not self:IsCombatModel(model) then
            self.Runtime.ThreatUntil[model] = nil
        elseif self:IsThreatInRange(model, 28) then
            local root = self:CombatRoot(model)
            local distance = root and mine and (root.Position - mine.Position).Magnitude or math.huge
            if not bestDistance or distance < bestDistance then
                best, bestDistance = model, distance
            end
        end
    end

    return best
end

function H:SetThreatWindow(model, seconds)
    if not self:IsCombatModel(model) then return end

    if type(self.Runtime.ThreatUntil)
        ~= "table" then

        self.Runtime.ThreatUntil =
            setmetatable(
                {},
                {__mode = "k"}
            )
    end

    self.Runtime.ThreatUntil[
        model
    ] =
        math.max(
            self.Runtime.ThreatUntil[
                model
            ] or 0,
            os.clock()
            + (
                tonumber(seconds)
                or 0.45
            )
        )
end

function H:IsThreatWindow(model)
    if not model
        or type(
            self.Runtime.ThreatUntil
        ) ~= "table" then

        return false
    end

    local untilAt =
        self.Runtime.ThreatUntil[
            model
        ]

    if not untilAt then
        return false
    end

    if os.clock()
        >= untilAt then

        self.Runtime.ThreatUntil[
            model
        ] = nil

        return false
    end

    return true
end

function H:IsBlockingActive()
    local character = self:Character()
    if character and character:FindFirstChild("Blocking") then
        return true
    end
    local grace = math.clamp(self:GetPingMs() / 1000 + 0.08, 0.12, 0.35)
    if self.Runtime.BlockHeld
        and os.clock() - (self.Runtime.LastBlockStart or 0) < grace then
        return true
    end
    self.Runtime.BlockHeld = false
    self.Runtime.Defending = false
    return false
end

function H:StartBlocking(force)
    if self.State.Unloaded
        or os.clock()
            < (
                self.Runtime.ForceAttackUntil
                or 0
            )
        or not self.State.AutoParry
        or not self:IsFarmCombatActive() then

        return false
    end

    local alreadyBlocking =
        self:IsBlockingActive()

    if alreadyBlocking
        and not force then

        self.Runtime.Defending = true
        return true
    end

    local controller =
        self.Modules.SkillController

    if type(controller) ~= "table"
        or type(controller.Attempt_Hold)
            ~= "function" then

        return alreadyBlocking
    end

    local ok, accepted =
        pcall(
            controller.Attempt_Hold,
            "Blocking"
        )
    ok = ok and accepted ~= false

    if ok then
        self.Runtime.BlockHeld = true
        self.Runtime.Defending = true
        self.Runtime.LastBlockStart =
            os.clock()
    end

    return ok
end

function H:StopBlocking()
    local controller =
        self.Modules.SkillController

    if type(controller) == "table"
        and type(controller.StopHold)
            == "function" then

        pcall(
            controller.StopHold,
            "Blocking"
        )
    end

    self.Runtime.BlockHeld = false
    self.Runtime.Defending = false
end

function H:PerfectBlockPulse(model, holdSeconds)
    if not self.State.PerfectBlock or not self.State.AutoParry
        or not self:IsFarmCombatActive() or self.State.Unloaded
        or not self:IsThreatInRange(model,
            self:IsBossModel(model) and ((tonumber(self.State.BossGuardRange) or 24) + 6) or 19) then
        return false
    end
    -- Keep existing guard through the hit; re-tapping at impact exposed us.
    self.Runtime.LastParryPulse = os.clock()
    self.Runtime.ForceAttackUntil = 0
    self.Runtime.BlockReleaseUntil = 0
    self:SetThreatWindow(model, tonumber(holdSeconds) or 0.52)
    self:FaceTarget(model)
    return self:StartBlocking(true)
end

function H:GuardStep(model)
    if model
        and self:IsThreatWindow(model)
        and self.State.AutoParry
        and self:IsFarmCombatActive()
        and self:IsThreatInRange(model, 32) then

        self.Runtime.ForceAttackUntil = 0
        self.Runtime.BlockReleaseUntil = 0
        self:FaceTarget(model)

        return self:StartBlocking(true)
    end

    -- BUILD 55: normal mobs are guard-first again.
    -- PulseAttack() deliberately releases block for a clean M1 window when the
    -- real punch cooldown is ready, then guard is restored immediately after.
    if os.clock()
        < (
            self.Runtime.ForceAttackUntil
            or 0
        ) then

        self:StopBlocking()
        return false
    end

    if not self.State.PerfectBlock
        or not self.State.AutoParry
        or not model
        or not model.Parent
        or not self:IsFarmCombatActive() then

        if self.Runtime.BlockHeld
            and not self.Runtime.Defending then

            self:StopBlocking()
        end

        return false
    end

    local guardRange =
        self:IsBossModel(model)
        and (
            tonumber(
                self.State.BossGuardRange
            ) or 24
        )
        or 16

    if not self:IsThreatInRange(
        model,
        guardRange
    ) then

        if self.Runtime.BlockHeld then
            self:StopBlocking()
        end

        return false
    end

    if os.clock()
        < self.Runtime.BlockReleaseUntil then

        return false
    end

    if not self:IsBlockingActive() then
        return self:StartBlocking(false)
    end

    self.Runtime.Defending = true
    return true
end

function H:TriggerDefense(model, delaySeconds, holdSeconds)
    if self:IsThreatWindow(model)
        or self:IsBossModel(model) then

        -- A detected threat cancels the current attack-only window.
        self.Runtime.ForceAttackUntil = 0
    elseif os.clock()
        < (
            self.Runtime.ForceAttackUntil
            or 0
        ) then

        return
    end

    if not self.State.AutoParry
        or not self:IsFarmCombatActive()
        or self.State.Unloaded
        or not self:IsThreatInRange(
            model,
            self:IsBossModel(model)
            and (
                tonumber(
                    self.State.BossGuardRange
                ) or 24
            ) + 6
            or 19
        ) then

        return
    end

    if self.State.PerfectBlock then
        self.Runtime.ForceAttackUntil = 0
        self.Runtime.BlockReleaseUntil = 0
        self:SetThreatWindow(
            model,
            tonumber(holdSeconds) or 0.52
        )
        self:FaceTarget(model)
        self:StartBlocking(true)

        local pulseDelay =
            math.max(
                0,
                tonumber(delaySeconds) or 0
            )

        if pulseDelay <= 0.01 then
            self:PerfectBlockPulse(
                model,
                holdSeconds or 0.52
            )
        else
            local token =
                (self.Runtime.PerfectParryToken or 0) + 1

            self.Runtime.PerfectParryToken = token

            task.delay(
                pulseDelay,
                function()
                    if self.State.Unloaded
                        or token ~= self.Runtime.PerfectParryToken
                        or not self.State.AutoParry
                        or not self.State.PerfectBlock
                        or not self:IsFarmCombatActive()
                        or not self:IsThreatInRange(
                            model,
                            self:IsBossModel(model)
                            and (
                                (tonumber(self.State.BossGuardRange) or 24)
                                + 8
                            )
                            or 20
                        ) then

                        return
                    end

                    self:PerfectBlockPulse(
                        model,
                        holdSeconds or 0.52
                    )
                end
            )
        end

        return
    end

    local now = os.clock()

    if now
        - self.Runtime.LastDefense
        < 0.16 then

        return
    end

    self.Runtime.LastDefense = now
    self.Runtime.DefenseToken += 1

    local token =
        self.Runtime.DefenseToken

    task.delay(
        math.max(
            0,
            tonumber(delaySeconds)
            or 0
        ),
        function()
            if self.State.Unloaded
                or token
                    ~= self.Runtime.DefenseToken
                or not self.State.AutoParry
                or not self:IsFarmCombatActive()
                or not self:IsThreatInRange(
                    model,
                    20
                ) then

                return
            end

            self:StopAttackHold()

            if not self:StartBlocking(true) then
                return
            end

            task.delay(
                math.max(
                    0.10,
                    tonumber(holdSeconds)
                    or 0.20
                ),
                function()
                    if token
                        == self.Runtime.DefenseToken then

                        self:StopBlocking()
                    end
                end
            )
        end
    )
end

function H:IsLikelyAttackTrack(track)
    if not track then
        return false
    end

    local name =
        string.lower(
            tostring(
                track.Name
                or ""
            )
            .. " "
            .. tostring(
                track.Animation
                and track.Animation.Name
                or ""
            )
        )

    -- NPC attack tracks are not consistently named. Exclude obvious
    -- locomotion/idle tracks and treat other tracks from the CURRENT target as
    -- possible attacks.
    for _, word in ipairs(
        {
            "idle",
            "walk",
            "run",
            "jump",
            "fall",
            "land",
            "swim",
            "climb",
            "dash",
            "spawn",
            "sit",
            "hitreact",
            "hit_react",
            "hurt",
            "flinch",
            "stagger",
            "stunned",
            "death",
            "dead",
            "equip",
            "blocking",
            "parry",
        }
    ) do
        if string.find(
            name,
            word,
            1,
            true
        ) then

            return false
        end
    end

    return true
end

function H:WatchMobDefense(model)
    if self.Data.DefenseWatchers[model]
        or not self:IsCombatModel(model) then
        return
    end

    local _, hum = self:CombatRoot(model)
    if not hum then return end

    local animator =
        hum:FindFirstChildOfClass(
            "Animator"
        )

    if not animator then
        animator =
            hum:FindFirstChildWhichIsA(
                "Animator",
                true
            )
    end

    local watcher = {
        Connections = {},
        LatestTrack = nil :: AnimationTrack?,
    }

    self.Data.DefenseWatchers[model] =
        watcher

    if animator then
        table.insert(
            watcher.Connections,
            animator.AnimationPlayed:Connect(
                function(track)
                    if not self.State.AutoParry
                        or not self:IsFarmCombatActive()
                        or not self:IsThreatInRange(
                            model,
                            self:IsBossModel(model)
                            and (
                                tonumber(
                                    self.State.BossGuardRange
                                ) or 24
                            ) + 8
                            or 16
                        )
                        or not self:IsLikelyAttackTrack(
                            track
                        ) then

                        return
                    end

                    local _isBoss =
                        self:IsBossModel(
                            model
                        )

                    local _, threatLength = self:AdaptiveParryProfile(model, track)
                    self:SetThreatWindow(
                        model,
                        threatLength
                    )

                    -- Cancel any exposed attack window as soon as an attack
                    -- animation starts.
                    self.Runtime.ForceAttackUntil = 0

                    -- Safety layer: block immediately. The fresh parry pulse is
                    -- then re-timed closer to the predicted hit frame.
                    self.Runtime.BlockReleaseUntil = 0
                    self:FaceTarget(model)
                    self:StartBlocking(true)

                    local pulseDelay,
                        hold =
                        self:AdaptiveParryProfile(
                            model,
                            track
                        )

                    self:TriggerDefense(
                        model,
                        pulseDelay,
                        hold
                    )

                    -- If the animation exposes a common hit/damage marker,
                    -- refresh guard again at the marker. Baseline block is
                    -- already held, so a late marker cannot leave us naked.
                    local trackConnections = {}
                    local stoppedConnection
                    stoppedConnection = track.Stopped:Connect(function()
                        for _, connection in ipairs(trackConnections) do connection:Disconnect() end
                        if stoppedConnection then stoppedConnection:Disconnect() end
                        -- Do not shorten another simultaneous animation's threat window.
                        if watcher.LatestTrack == track and self.Runtime.ThreatUntil then
                            self.Runtime.ThreatUntil[model] = math.min(
                                self.Runtime.ThreatUntil[model] or os.clock(),
                                os.clock() + self:DefenseLatency() + 0.06)
                        end
                    end)
                    watcher.LatestTrack = track
                    table.insert(watcher.Connections, stoppedConnection)
                    -- Prune disconnected per-animation connections from the watcher.
                    for i = #watcher.Connections, 1, -1 do
                        if not watcher.Connections[i].Connected then table.remove(watcher.Connections, i) end
                    end
                    for _, markerName in ipairs(
                        {
                            "Hit",
                            "Damage",
                            "Attack",
                            "Swing",
                        }
                    ) do
                        local ok, signal =
                            pcall(
                                track.GetMarkerReachedSignal,
                                track,
                                markerName
                            )

                        if ok
                            and signal then

                            local markerConnection

                            markerConnection =
                                signal:Connect(
                                    function()
                                        if markerConnection then
                                            markerConnection:Disconnect()
                                        end

                                        self.Runtime.ForceAttackUntil = 0
                                        self:SetThreatWindow(
                                            model,
                                            0.35
                                        )

                                        self:PerfectBlockPulse(
                                            model,
                                            select(
                                                2,
                                                self:AdaptiveParryProfile(
                                                    model,
                                                    track
                                                )
                                            )
                                        )
                                    end
                                )

                            table.insert(trackConnections, markerConnection)
                            table.insert(watcher.Connections, markerConnection)
                        end
                    end
                end
            )
        )
    end

    -- Some M1 chains update combat attributes more reliably than their
    -- animation name. Use those as a second normal-client signal.
    for _, attr in ipairs(
        {
            "last_cmbat",
            "last_combo",
        }
    ) do
        table.insert(
            watcher.Connections,
            model:GetAttributeChangedSignal(
                attr
            ):Connect(
                function()
                    self:SetThreatWindow(
                        model,
                        self:IsBossModel(model)
                        and 0.70
                        or 0.40
                    )

                    self.Runtime.ForceAttackUntil = 0

                    local pulseDelay,
                        hold =
                        self:AdaptiveParryProfile(
                            model,
                            nil
                        )

                    self:TriggerDefense(
                        model,
                        math.min(
                            pulseDelay,
                            0.06
                        ),
                        hold
                    )
                end
            )
        )
    end

    table.insert(
        watcher.Connections,
        model.AncestryChanged:Connect(
            function(_, parent)
                if parent == nil then
                    local rec =
                        self.Data.DefenseWatchers[
                            model
                        ]

                    if rec then
                        for _, c in ipairs(
                            rec.Connections
                        ) do
                            pcall(
                                function()
                                    c:Disconnect()
                                end
                            )
                        end
                    end

                    self.Data.DefenseWatchers[
                        model
                    ] = nil
                end
            end
        )
    )
end

-- ============================================================
-- TARGETING
-- ============================================================

function H:NormalizeMobText(value)
    local s = string.lower(tostring(value or ""))
    s = string.gsub(s, "[^%w]", "")
    return s
end


function H:MobAliases(requested)
    local raw =
        tostring(
            requested
            or "Any"
        )

    local cacheKey =
        string.lower(raw)

    local cached =
        self.Data.MobAliasCache[
            cacheKey
        ]

    if cached then
        return cached
    end

    local aliases = {}
    local seen = {}

    local function add(value)
        if typeof(value) ~= "string"
            or value == "" then

            return
        end

        local normalized =
            self:NormalizeMobText(value)

        if normalized ~= ""
            and not seen[normalized] then

            seen[normalized] = true
            table.insert(
                aliases,
                normalized
            )
        end
    end

    add(raw)

    -- Useful generic forms for codes such as:
    --   KaruVillageBandit -> Bandit
    --   KaruVillageSpy    -> Spy
    local split =
        string.gsub(
            raw,
            "([a-z])([A-Z])",
            "%1 %2"
        )

    add(split)

    local regionWords = {
        "karu",
        "village",
        "windy",
        "peak",
        "mistfall",
        "harbor",
        "bamboo",
        "grove",
        "butterfly",
        "estate",
        "iceveil",
        "valley",
        "hidden",
        "mist",
        "final",
        "selection",
        "plains",
        "npc",
        "enemy",
        "mob",
    }

    local simplified =
        " " .. string.lower(split) .. " "

    for _, word in ipairs(regionWords) do
        simplified =
            string.gsub(
                simplified,
                " " .. word .. " ",
                " "
            )
    end

    simplified =
        string.gsub(
            simplified,
            "%s+",
            " "
        )

    add(simplified)

    local _normalizedRaw =
        self:NormalizeMobText(raw)

    -- Do NOT add plain "Civilian" as a spy alias.
    -- The live game exposes the actual disguised quest targets as *Civilian*,
    -- while ordinary Civilian NPCs are innocent villagers.

    -- The game's own ItemSources module reads LiveConfig.NpcDataTable.
    -- Use that same replicated table to resolve quest task codes to their
    -- visible NPC/model names instead of hardcoding each progression quest.
    local live = self.Modules.LiveConfig

    if type(live) == "table"
        and type(live.get) == "function" then

        local ok, npcData =
            pcall(
                live.get,
                "NpcDataTable"
            )

        if ok
            and type(npcData) == "table" then

            local wanted =
                self:NormalizeMobText(raw)

            local function inspectEntry(key, entry)
                local match =
                    self:NormalizeMobText(
                        tostring(key)
                    ) == wanted

                if type(entry) == "table" then
                    for _, field in ipairs(
                        {
                            "Code",
                            "NpcCode",
                            "Name",
                            "DisplayName",
                            "NpcName",
                            "Title",
                            "Model",
                            "ModelName",
                            "Enemy",
                        }
                    ) do
                        local v = entry[field]

                        if typeof(v) == "string" then
                            if self:NormalizeMobText(v) == wanted then
                                match = true
                            end
                        end
                    end
                end

                if match then
                    add(tostring(key))

                    if type(entry) == "table" then
                        for _, field in ipairs(
                            {
                                "Code",
                                "NpcCode",
                                "Name",
                                "DisplayName",
                                "NpcName",
                                "Title",
                                "Model",
                                "ModelName",
                                "Enemy",
                            }
                        ) do
                            add(entry[field])
                        end
                    end
                end
            end

            if npcData[raw] ~= nil then
                inspectEntry(
                    raw,
                    npcData[raw]
                )
            end

            for key, entry in pairs(npcData) do
                inspectEntry(
                    key,
                    entry
                )
            end
        end
    end

    self.Data.MobAliasCache[
        cacheKey
    ] = aliases

    return aliases
end

function H:ModelRegion(model)
    local node = model

    while node
        and node ~= self.S.Workspace do

        local parent = node.Parent

        if parent
            and parent.Name == "ActiveNpcs"
            and parent.Parent then

            return parent.Parent.Name
        end

        node = parent
    end

    return nil
end

function H:RememberMobSpawn(model)
    if not model
        or not model.Parent then

        return
    end

    local root =
        model:FindFirstChild(
            "HumanoidRootPart",
            true
        )
        or model.PrimaryPart

    if not root then
        return
    end

    local region =
        self:ModelRegion(model)
        or "?"

    local keys = {
        self:NormalizeMobText(model.Name),
        self:NormalizeMobText(
            model:GetAttribute("NpcCode")
        ),
        self:NormalizeMobText(
            model:GetAttribute("Code")
        ),
    }

    local uniqueName =
        tostring(
            model:GetAttribute("UniqueName")
            or ""
        )

    if uniqueName ~= "" then
        table.insert(
            keys,
            self:NormalizeMobText(
                string.match(
                    uniqueName,
                    "^[^-]+"
                )
                or uniqueName
            )
        )
    end

    for _, key in ipairs(keys) do
        if key ~= "" then
            self.Data.SpawnMemory[key] =
                self.Data.SpawnMemory[key]
                or {}

            local list =
                self.Data.SpawnMemory[key]

            local duplicate = false

            for _, rec in ipairs(list) do
                if rec.Region == region
                    and (
                        rec.Position
                        - root.Position
                    ).Magnitude < 8 then

                    rec.Position = root.Position
                    rec.SeenAt = os.clock()
                    duplicate = true
                    break
                end
            end

            if not duplicate then
                table.insert(
                    list,
                    {
                        Position = root.Position,
                        Region = region,
                        SeenAt = os.clock(),
                    }
                )
            end

            while #list > 12 do
                table.remove(list, 1)
            end
        end
    end
end

function H:QuestRegion(def)
    if type(def) ~= "table" then
        return nil
    end

    local offerNpc = def.OfferNpc

    if typeof(offerNpc) == "string" then
        local npc = self:FindNPC(offerNpc)

        if npc then
            local node = npc

            while node
                and node ~= self.S.Workspace do

                local parent = node.Parent

                if parent
                    and parent.Name == "StationaryNpcs"
                    and parent.Parent then

                    return parent.Parent.Name
                end

                node = parent
            end
        end
    end

    return nil
end

function H:LiveMobModels()
    local found = {}
    local root =
        self.S.Workspace:FindFirstChild(
            "Humanoids"
        )

    if not root then
        return found
    end

    for _, model in ipairs(
        root:GetDescendants()
    ) do
        if model:IsA("Model")
            and model ~= self:Character()
            and model:GetAttribute("IsMob") == true then

            local hum =
                model:FindFirstChildOfClass(
                    "Humanoid"
                )
                or model:FindFirstChildWhichIsA(
                    "Humanoid",
                    true
                )

            local rp =
                model:FindFirstChild(
                    "HumanoidRootPart",
                    true
                )
                or model.PrimaryPart

            if hum
                and hum.Health > 0
                and rp then

                table.insert(found, model)
                self:RememberMobSpawn(model)
            end
        end
    end

    return found
end

function H:QuestIsSpy(quest, query)
    local text =
        string.lower(
            tostring(query or "")
            .. " "
            .. tostring(
                quest
                and quest.Task
                or ""
            )
            .. " "
            .. tostring(
                quest
                and quest.Code
                or ""
            )
        )

    return string.find(
        text,
        "spy",
        1,
        true
    ) ~= nil
end

function H:MobMatches(model, requested)
    requested =
        tostring(
            requested
            or "Any"
        )

    if requested == "Any" then
        return true
    end

    local aliases =
        self:MobAliases(requested)

    local candidates = {
        self:NormalizeMobText(model.Name),
        self:NormalizeMobText(
            model:GetAttribute("NpcCode")
        ),
        self:NormalizeMobText(
            model:GetAttribute("Code")
        ),
        self:NormalizeMobText(
            model:GetAttribute("UniqueName")
        ),
    }

    for _, tag in ipairs(
        self.S.CollectionService:GetTags(
            model
        )
    ) do
        table.insert(
            candidates,
            self:NormalizeMobText(tag)
        )
    end

    local root =
        model:FindFirstChild(
            "HumanoidRootPart",
            true
        )

    if root then
        for _, tag in ipairs(
            self.S.CollectionService:GetTags(
                root
            )
        ) do
            table.insert(
                candidates,
                self:NormalizeMobText(tag)
            )
        end
    end

    for _, want in ipairs(aliases) do
        for _, candidate in ipairs(candidates) do
            if candidate ~= ""
                and (
                    candidate == want
                    or string.find(
                        want,
                        candidate,
                        1,
                        true
                    )
                    or string.find(
                        candidate,
                        want,
                        1,
                        true
                    )
                ) then

                return true
            end
        end
    end

    return false
end

function H:NearestMob(requested, quest, def)
    local root = self:Root()

    if not root then
        return nil
    end

    requested =
        requested
        or self.State.SelectedMob

    local aliases =
        self:MobAliases(requested)

    local wantedRegion =
        self:QuestRegion(def)

    local spyQuest =
        self:QuestIsSpy(
            quest,
            requested
        )

    local models =
        self:LiveMobModels()

    local best
    local bestDistance = math.huge
    local bestScore = -math.huge

    for _, model in ipairs(models) do
        local hum =
            model:FindFirstChildOfClass(
                "Humanoid"
            )
            or model:FindFirstChildWhichIsA(
                "Humanoid",
                true
            )

        local rp =
            model:FindFirstChild(
                "HumanoidRootPart",
                true
            )
            or model.PrimaryPart

        if hum
            and hum.Health > 0
            and rp
            and not self:IsCombatTargetTemporarilyBlocked(
                model
            ) then

            local match =
                self:MobMatches(
                    model,
                    requested
                )

            local normalizedName =
                self:NormalizeMobText(
                    model.Name
                )

            if spyQuest then
                local starredCivilian =
                    normalizedName == "civilian"
                    and string.find(
                        model.Name,
                        "*",
                        1,
                        true
                    ) ~= nil

                -- Spy quests are intentionally strict: normal Civilians are
                -- never valid targets.
                match = starredCivilian
            end

            if match then
                local distance =
                    (
                        root.Position
                        - rp.Position
                    ).Magnitude

                local score =
                    200
                    - math.min(
                        distance / 8,
                        80
                    )

                local region =
                    self:ModelRegion(model)

                if wantedRegion
                    and region == wantedRegion then

                    score += 75
                elseif wantedRegion
                    and region ~= wantedRegion then

                    score -= 40
                end

                -- A starred Civilian is the actual disguised-spy quest
                -- target. Give it a strong score without ever considering a
                -- normal Civilian.
                if spyQuest
                    and normalizedName == "civilian"
                    and string.find(
                        model.Name,
                        "*",
                        1,
                        true
                    ) then

                    score += 125
                end

                for _, alias in ipairs(aliases) do
                    if normalizedName == alias then
                        score += 50
                        break
                    end
                end

                if score > bestScore then
                    best = model
                    bestDistance = distance
                    bestScore = score
                end
            end
        end
    end

    if best then
        self.Data.CurrentFarmTarget = best
        self.Data.CurrentFarmQuery = requested
        self.Data.CurrentFarmRegion =
            self:ModelRegion(best)
    end

    return best, bestDistance
end

function H:QuestFallbackPosition(query, quest, def)
    local aliases =
        self:MobAliases(query)

    local region =
        self:QuestRegion(def)

    local candidates = {}

    local function addPosition(pos, label)
        if typeof(pos) == "CFrame" then
            pos = pos.Position
        elseif typeof(pos) == "Instance" then
            local part =
                pos:IsA("BasePart")
                and pos
                or pos:FindFirstChildWhichIsA(
                    "BasePart",
                    true
                )

            pos = part and part.Position or nil
        end

        if typeof(pos) == "Vector3" then
            table.insert(
                candidates,
                {
                    Position = pos,
                    Label = label,
                }
            )
        end
    end

    -- 1) Quest TaskSpecs / markers when the game supplies positions.
    if type(def) == "table"
        and quest
        and quest.Task then

        local spec =
            type(def.TaskSpecs) == "table"
            and def.TaskSpecs[quest.Task]
            or nil

        if type(spec) == "table"
            and type(spec.Positions) == "table" then

            for _, pos in pairs(spec.Positions) do
                addPosition(
                    pos,
                    "Quest TaskSpec"
                )
            end
        end

        local marker =
            type(def.Markers) == "table"
            and def.Markers[quest.Task]
            or nil

        if type(marker) == "table" then
            addPosition(
                marker.Position,
                "Quest Marker"
            )
        end
    end

    -- 2) Spawn memory learned from live NPCs this session.
    for _, alias in ipairs(aliases) do
        local list =
            self.Data.SpawnMemory[alias]

        if list then
            for _, rec in ipairs(list) do
                if not region
                    or rec.Region == region then

                    addPosition(
                        rec.Position,
                        "Spawn Memory"
                    )
                end
            end
        end
    end

    -- 3) Stable scan-derived anchors for early Windy Peak progression.
    local normalizedQuery =
        self:NormalizeMobText(query)

    local known =
        self.Data.KnownQuestAnchors[
            normalizedQuery
        ]

    if not known
        and self:QuestIsSpy(
            quest,
            query
        ) then

        known =
            self.Data.KnownQuestAnchors.villagespy
    end

    if known then
        for _, pos in ipairs(known) do
            addPosition(
                pos,
                "Scanned Spawn"
            )
        end
    end

    -- 4) Offer NPC position/region fallback. Better than standing still when
    -- waiting for a respawn in a quest region.
    if type(def) == "table"
        and typeof(def.OfferNpc) == "string" then

        local regions =
            self.Modules.Regions

        if type(regions) == "table"
            and type(regions.GetNpcSpawn) == "function" then

            local ok, pos =
                pcall(
                    regions.GetNpcSpawn,
                    def.OfferNpc
                )

            if ok then
                addPosition(
                    pos,
                    "Quest Region"
                )
            end
        end
    end

    if #candidates == 0 then
        return nil
    end

    local root = self:Root()

    if not root then
        return candidates[1].Position,
            candidates[1].Label
    end

    local key =
        self:NormalizeMobText(query)

    local index =
        self.Data.TargetFallbackIndex[key]
        or 1

    local since =
        self.Data.TargetWaitSince[key]

    if not since then
        since = os.clock()
        self.Data.TargetWaitSince[key] = since
    end

    -- Cycle anchors if we've been waiting near one for a few seconds.
    local current =
        candidates[
            math.clamp(
                index,
                1,
                #candidates
            )
        ]

    if (
        root.Position
        - current.Position
    ).Magnitude < 18
        and os.clock() - since > 3.5 then

        index =
            (index % #candidates)
            + 1

        self.Data.TargetFallbackIndex[key] = index
        self.Data.TargetWaitSince[key] = os.clock()
        current = candidates[index]
    end

    return current.Position,
        current.Label
end

function H:BossTarget()
    local root = self:Root()

    local function usable(rec)
        if not rec then
            return false
        end

        if rec.NightOnly then
            local clock =
                self.S.Lighting.ClockTime

            if clock >= 6
                and clock < 18 then

                return false
            end
        end

        return self:BossAlive(rec)
    end

    if self.State.BossMode == "Selected" then
        local code =
            self.State.SelectedBoss

        local rec =
            code
            and self.Data.Bosses[code]

        if rec
            and rec.NightOnly then

            local clock =
                self.S.Lighting.ClockTime

            if clock >= 6
                and clock < 18 then

                return nil,
                    "waiting-night"
            end
        end

        if usable(rec) then
            return rec
        end

        return nil, "dead"
    end

    local best
    local bestDistance = math.huge

    for _, rec in pairs(
        self.Data.Bosses
    ) do
        if usable(rec) then
            local pos =
                rec.Center

            local part =
                rec.Model
                and (
                    rec.Model:FindFirstChild(
                        "HumanoidRootPart",
                        true
                    )
                    or rec.Model.PrimaryPart
                )

            if part then
                pos = part.Position
            end

            local distance =
                root
                and pos
                and (
                    root.Position
                    - pos
                ).Magnitude
                or math.huge

            if distance < bestDistance then
                best = rec
                bestDistance = distance
            end
        end
    end

    if best then return best, nil end
    return nil, "none-alive"
end

-- ============================================================
-- AUTO QUEST
-- ============================================================

function H:GetSlotData()
    local service =
        self.S.ReplicatedStorage:FindFirstChild("Player_Service")

    local data =
        service
        and service:FindFirstChild("Data")

    local mine =
        data
        and data:FindFirstChild(self.Player.Name)

    local slots =
        mine
        and mine:FindFirstChild("slots")

    if not slots then
        return nil
    end

    return slots:FindFirstChild("Slot1")
        or slots:GetChildren()[1]
end

function H:GetActiveQuest()
    local slot = self:GetSlotData()
    local quests = slot and slot:FindFirstChild("Quests")
    local holder = quests and quests:FindFirstChild("Holder")

    if not holder then
        return nil
    end

    local quest = holder:GetChildren()[1]

    if not quest then
        return nil
    end

    local q = {
        Instance = quest,
        Name = quest.Name,
        Key = nil,
        Task = nil,
        Code = nil,
        Value = nil,
        Max = nil,
    }

    local qs = quest:FindFirstChild("QuestString")

    if qs and qs:IsA("StringValue") then
        q.Key = qs.Value
    end

    local tasks = quest:FindFirstChild("Tasks")

    if tasks then
        for _, task in ipairs(tasks:GetChildren()) do
            local value = task:FindFirstChild("Value")
            local max = task:FindFirstChild("Max")
            local code = task:FindFirstChild("Code")

            local valueN = value and tonumber(value.Value)
            local maxN = max and tonumber(max.Value)

            -- Live quest UI proves Value is PROGRESS MADE even when the task
            -- label says "remaining". Example: a freshly accepted spy quest
            -- shows 0/4, so 0 is unfinished and Max is complete.
            local unfinished =
                maxN == nil
                or valueN == nil
                or valueN < maxN

            if unfinished then
                q.Task = task.Name
                q.Code = code and tostring(code.Value) or nil
                q.Value = valueN
                q.Max = maxN
                q.CountsDown = false
                break
            end
        end
    end

    return q
end

function H:QuestDefinition(key, questName)
    local quests = self.Modules.Quests

    if type(quests) ~= "table"
        or type(quests.Holder) ~= "table" then
        return nil, nil
    end

    if key and quests.Holder[key] then
        return quests.Holder[key], key
    end

    local wantedKey = self:NormalizeMobText(key)
    local wantedName = self:NormalizeMobText(questName)

    for holderKey, def in pairs(quests.Holder) do
        if type(def) == "table" then
            local instanceName =
                def.QuestInstance
                and tostring(def.QuestInstance.Name)
                or ""

            if (wantedKey ~= "" and self:NormalizeMobText(holderKey) == wantedKey)
                or (wantedName ~= "" and self:NormalizeMobText(instanceName) == wantedName) then
                return def, holderKey
            end
        end
    end

    return nil, nil
end

function H:QuestCompletionHandoffNpc(def)
    if type(def) ~= "table" then
        return nil, nil
    end

    local completion =
        def.CompletionNotify

    if type(completion) == "table"
        and typeof(completion.Npc) == "string"
        and completion.Npc ~= "" then

        return completion.Npc,
            "CompletionNotify"
    end

    if type(def.Rewards) == "table" then
        for rewardName, reward in pairs(
            def.Rewards
        ) do
            if type(reward) == "table" then
                local grant =
                    reward.GrantNotify

                if type(grant) == "table"
                    and typeof(grant.Npc) == "string"
                    and grant.Npc ~= "" then

                    return grant.Npc,
                        "Reward "
                        .. tostring(rewardName)
                end
            end
        end
    end

    return nil, nil
end

function H:SetPendingQuestHandoff(npcName, reason, seconds)
    if typeof(npcName) ~= "string"
        or npcName == "" then

        return false
    end

    self.Runtime.PendingHandoffNpc =
        npcName

    self.Runtime.PendingHandoffReason =
        tostring(
            reason
            or "quest handoff"
        )

    self.Runtime.PendingHandoffUntil =
        os.clock()
        + (
            tonumber(seconds)
            or 60
        )

    return true
end

function H:ClearPendingQuestHandoff()
    self.Runtime.PendingHandoffNpc = nil
    self.Runtime.PendingHandoffReason = nil
    self.Runtime.PendingHandoffUntil = 0
end

function H:PlayerHasNamedItem(itemName)
    local wanted =
        string.lower(
            tostring(
                itemName
                or ""
            )
        )

    if wanted == "" then
        return false
    end

    local function scanContainer(root)
        if not root then
            return false
        end

        if string.lower(
            tostring(root.Name)
        ) == wanted then

            return true
        end

        for _, obj in ipairs(
            root:GetDescendants()
        ) do
            if string.lower(
                tostring(obj.Name)
            ) == wanted then

                return true
            end

            if obj:IsA("StringValue")
                and string.lower(
                    tostring(obj.Value)
                ) == wanted then

                return true
            end

            for _, attrValue in pairs(
                obj:GetAttributes()
            ) do
                if typeof(attrValue) == "string"
                    and string.lower(attrValue)
                        == wanted then

                    return true
                end
            end
        end

        return false
    end

    if scanContainer(
        self.Player:FindFirstChildOfClass(
            "Backpack"
        )
    ) then
        return true
    end

    if scanContainer(
        self:Character()
    ) then
        return true
    end

    return scanContainer(
        self:GetSlotData()
    )
end

function H:VisibleDialogueText()
    local chunks = {}

    for _, obj in ipairs(
        self.PlayerGui:GetDescendants()
    ) do
        if not self:IsOwnGuiObject(obj)
            and (
                obj:IsA("TextLabel")
                or obj:IsA("TextButton")
            )
            and obj.Visible then

            local txt =
                tostring(
                    obj.Text
                    or ""
                )

            if txt ~= "" then
                table.insert(
                    chunks,
                    txt
                )
            end
        end
    end

    return table.concat(
        chunks,
        "\n"
    )
end

function H:ResolveQuestHandoff()
    if self.Runtime.PendingHandoffNpc
        and os.clock()
            < self.Runtime.PendingHandoffUntil then

        return
            self.Runtime.PendingHandoffNpc,
            self.Runtime.PendingHandoffReason
    end

    if self.Runtime.PendingHandoffNpc then
        self:ClearPendingQuestHandoff()
    end

    -- Current Windy Peak chain:
    -- Clear the Village Spies -> Suspicious Note -> Noote.
    -- This also survives script reloads after the old quest leaves Holder.
    if self:PlayerHasNamedItem(
        "Suspicious Note"
    ) then

        return "Noote",
            "carrying Suspicious Note"
    end

    -- Recover directly from Kazu's visible handoff dialogue too.
    local dialogue =
        string.lower(
            self:VisibleDialogueText()
        )

    if string.find(
        dialogue,
        "noote",
        1,
        true
    )
        and (
            string.find(
                dialogue,
                "note",
                1,
                true
            )
            or string.find(
                dialogue,
                "read",
                1,
                true
            )
            or string.find(
                dialogue,
                "carrying",
                1,
                true
            )
        ) then

        return "Noote",
            "Kazu dialogue handoff"
    end

    return nil
end

function H:RememberActiveQuest(active)
    if active then
        self.Runtime.LastActiveQuestName =
            active.Name

        self.Runtime.LastActiveQuestKey =
            active.Key

        return
    end

    if self.Runtime.LastActiveQuestName then
        self.Runtime.RecentCompletedQuestName =
            self.Runtime.LastActiveQuestName

        self.Runtime.RecentCompletedQuestKey =
            self.Runtime.LastActiveQuestKey

        self.Runtime.RecentCompletedQuestAt =
            os.clock()

        self.Runtime.LastActiveQuestName = nil
        self.Runtime.LastActiveQuestKey = nil
    end
end

function H:GetPlayerLevel()
    local now = os.clock()
    if self.Runtime.LevelSampleAt and now - self.Runtime.LevelSampleAt < 0.30 then
        return self.Runtime.CachedLevel
    end
    local best
    local bestScore = -math.huge

    local function add(value, score)
        local n =
            tonumber(value)

        if not n
            or n < 1
            or n > 10000 then

            return
        end

        n =
            math.floor(n)

        if score > bestScore then
            best = n
            bestScore = score
        end
    end

    -- Direct replicated/player values first.
    add(
        self.Player:GetAttribute("Level"),
        100
    )

    local character =
        self:Character()

    if character then
        add(
            character:GetAttribute("Level"),
            95
        )
    end

    local slot =
        self:GetSlotData()

    if slot then
        local direct =
            slot:FindFirstChild("Level")

        if direct
            and direct:IsA("ValueBase") then

            add(
                direct.Value,
                100
            )
        end

        add(
            slot:GetAttribute("Level"),
            98
        )

        for _, path in ipairs(
            {
                {"Stats", "Level"},
                {"Progression", "Level"},
                {"PlayerStats", "Level"},
            }
        ) do
            local cur = slot

            for _, name in ipairs(path) do
                cur =
                    cur
                    and cur:FindFirstChild(
                        name
                    )
            end

            if cur
                and cur:IsA("ValueBase") then

                add(
                    cur.Value,
                    90
                )
            end
        end
    end

    -- Some client systems mirror useful values under Player_Service.Values.
    local service =
        self.S.ReplicatedStorage:FindFirstChild(
            "Player_Service"
        )

    local values =
        service
        and service:FindFirstChild(
            "Values"
        )

    local mine =
        values
        and values:FindFirstChild(
            self.Player.Name
        )

    if mine then
        local direct =
            mine:FindFirstChild(
                "Level",
                true
            )

        if direct
            and direct:IsA("ValueBase") then

            add(
                direct.Value,
                92
            )
        end

        add(
            mine:GetAttribute("Level"),
            92
        )
    end

    if best then
        self.Runtime.LevelSampleAt, self.Runtime.CachedLevel = now, best
        return best
    end

    -- Reliable fallback for this game: the live HUD displays "Lv 5", etc.
    -- Only use currently visible labels and exact full-text level formats so
    -- quest requirement text such as "(Lv 10)" cannot be mistaken for level.
    for _, obj in ipairs(
        self.PlayerGui:GetDescendants()
    ) do
        if (
            obj:IsA("TextLabel")
            or obj:IsA("TextButton")
        )
            and obj.Visible
            and not self:IsOwnGuiObject(obj) then

            local raw =
                tostring(
                    obj.Text
                    or ""
                )

            local normalized =
                string.gsub(
                    string.lower(raw),
                    "^%s*(.-)%s*$",
                    "%1"
                )

            local n =
                string.match(
                    normalized,
                    "^lv%s*[:%-]?%s*(%d+)$"
                )
                or string.match(
                    normalized,
                    "^level%s*[:%-]?%s*(%d+)$"
                )

            if n then
                local path =
                    string.lower(
                        self:Path(obj)
                    )

                local score =
                    (
                        string.find(
                            path,
                            "hud",
                            1,
                            true
                        )
                        or string.find(
                            path,
                            "exp",
                            1,
                            true
                        )
                        or string.find(
                            path,
                            "level",
                            1,
                            true
                        )
                    )
                    and 80
                    or 65

                add(
                    n,
                    score
                )
            end
        end
    end

    self.Runtime.LevelSampleAt, self.Runtime.CachedLevel = now, best
    return best
end

function H:QuestRequiredLevelFromActive(active, def)
    local level = self:QuestRequiredLevel(def)
    -- Iterate field names: ipairs({nil, name}) would skip the name entirely.
    for _, field in ipairs({"Key", "Name", "Task", "Code"}) do
        local value = string.lower(tostring(active and active[field] or ""))
        local n = value:match("lvl?%.?%s*[:%-]?%s*(%d+)")
            or value:match("level%s*[:%-]?%s*(%d+)")
        level = math.max(level, tonumber(n) or 0)
    end
    return level
end

function H:IsQuestLevelAllowed(def, active)
    local current =
        self:GetPlayerLevel()

    local required =
        active
        and self:QuestRequiredLevelFromActive(
            active,
            def
        )
        or self:QuestRequiredLevel(
            def
        )

    if not current
        or current <= 0 then

        -- Pause a known level-gated quest until the player level is readable.
        return required <= 0,
            current,
            required
    end

    return required <= current,
        current,
        required
end

function H:QuestRequiredLevel(def)
    if type(def) == "table" and type(def.Requirements) == "table" then
        return math.max(0, tonumber(def.Requirements.Level) or 0)
    end
    return 0
end

function H:QuestInteractionNpc(active, def)
    if not active then
        return nil
    end

    local task =
        tostring(
            active.Task
            or ""
        )

    local lowerTask =
        string.lower(task)

    local questName =
        tostring(
            active.Name
            or ""
        )

    local lowerQuestName =
        string.lower(
            questName
        )

    local function cleanNpcName(value)
        value =
            tostring(
                value
                or ""
            )

        value =
            string.gsub(
                value,
                "^%s+",
                ""
            )

        value =
            string.gsub(
                value,
                "%s+$",
                ""
            )

        value =
            string.gsub(
                value,
                "%s+%d+/%d+$",
                ""
            )

        value =
            string.gsub(
                value,
                "[%.!%?]+$",
                ""
            )

        return value
    end

    -- Straight dialogue / return objectives.
    local prefixes = {
        "speak with ",
        "speak to ",
        "talk with ",
        "talk to ",
        "report to ",
        "report back to ",
        "meet ",
        "visit ",
        "return to ",
        "go to ",
    }

    for _, prefix in ipairs(prefixes) do
        if string.sub(
            lowerTask,
            1,
            #prefix
        ) == prefix then

            local npcName =
                cleanNpcName(
                    string.sub(
                        task,
                        #prefix + 1
                    )
                )

            if npcName ~= "" then
                return npcName
            end
        end

        if string.sub(
            lowerQuestName,
            1,
            #prefix
        ) == prefix then

            local npcName =
                cleanNpcName(
                    string.sub(
                        questName,
                        #prefix + 1
                    )
                )

            if npcName ~= "" then
                return npcName
            end
        end
    end

    -- Delivery objectives:
    --   Deliver the Letter to Chaka
    --   Deliver to Shiori
    --   Bring the item to Lucy
    --   Give X to Y
    --   Take X to Y
    --
    -- We intentionally use the LAST " to " in the task so item names can
    -- contain extra words without confusing the recipient parser.
    local deliveryVerb =
        string.find(
            lowerTask,
            "deliver",
            1,
            true
        )
        or string.find(
            lowerTask,
            "bring",
            1,
            true
        )
        or string.find(
            lowerTask,
            "give",
            1,
            true
        )
        or string.find(
            lowerTask,
            "hand",
            1,
            true
        )
        or string.find(
            lowerTask,
            "take",
            1,
            true
        )
        or string.find(
            lowerTask,
            "carry",
            1,
            true
        )

    if deliveryVerb then
        local recipient =
            string.match(
                task,
                ".*%s+[Tt][Oo]%s+(.+)$"
            )

        recipient =
            cleanNpcName(
                recipient
            )

        if recipient ~= "" then
            return recipient
        end
    end

    -- TaskSpecs can explicitly describe delivery tasks. Different quest
    -- definitions use slightly different field names, so support the common
    -- recipient aliases rather than hard-coding one quest.
    if type(def) == "table"
        and type(def.TaskSpecs) == "table"
        and active.Task then

        local spec =
            def.TaskSpecs[
                active.Task
            ]

        if type(spec) == "table" then
            local specType =
                string.lower(
                    tostring(
                        spec.Type
                        or ""
                    )
                )

            if specType == "deliver"
                or specType == "dialogue"
                or specType == "interact" then

                local fields = {
                    "Npc",
                    "NPC",
                    "NpcName",
                    "TargetNpc",
                    "TargetNPC",
                    "Recipient",
                    "Target",
                }

                for _, field in ipairs(
                    fields
                ) do
                    if typeof(
                        spec[field]
                    ) == "string"
                        and spec[field] ~= "" then

                        return cleanNpcName(
                            spec[field]
                        )
                    end
                end
            end
        end
    end

    -- Some quest task objects carry the NPC in Code rather than in the task
    -- label. Only use Code as an NPC when the wording clearly describes an
    -- interaction objective.
    local looksInteractive =
        string.find(
            lowerTask,
            "speak",
            1,
            true
        )
        or string.find(
            lowerTask,
            "talk",
            1,
            true
        )
        or string.find(
            lowerTask,
            "report",
            1,
            true
        )
        or string.find(
            lowerTask,
            "meet",
            1,
            true
        )
        or string.find(
            lowerTask,
            "visit",
            1,
            true
        )
        or string.find(
            lowerTask,
            "return",
            1,
            true
        )
        or deliveryVerb

    if looksInteractive
        and active.Code
        and tostring(active.Code) ~= "" then

        return cleanNpcName(
            active.Code
        )
    end

    return nil
end

function H:QuestProgressText(active)
    if not active then
        return ""
    end

    if active.Value ~= nil and active.Max ~= nil then
        return tostring(active.Value) .. "/" .. tostring(active.Max)
    end

    return ""
end

function H:LevelGrindTarget()
    local myRoot =
        self:Root()

    if not myRoot then
        return nil, nil
    end

    local best
    local bestDistance
    local bestScore =
        math.huge

    for _, model in ipairs(
        self.Data.Mobs
    ) do
        if model
            and model.Parent
            and not self:IsBossModel(model)
            and not self:IsCombatTargetTemporarilyBlocked(model) then

            local name =
                string.lower(
                    tostring(
                        model.Name
                        or ""
                    )
                )

            -- Never use civilians as generic level-grind targets.
            if not string.find(
                name,
                "civilian",
                1,
                true
            ) then

                local hum =
                    self:TargetHumanoid(
                        model
                    )

                local root =
                    model:FindFirstChild(
                        "HumanoidRootPart",
                        true
                    )
                    or model.PrimaryPart

                if hum
                    and hum.Health > 0
                    and root then

                    local distance =
                        (
                            myRoot.Position
                            - root.Position
                        ).Magnitude

                    -- Prefer weaker nearby non-boss mobs.
                    local score =
                        (
                            tonumber(
                                hum.MaxHealth
                            ) or 999999
                        )
                        + distance * 0.15

                    if score < bestScore then
                        bestScore = score
                        best = model
                        bestDistance =
                            distance
                    end
                end
            end
        end
    end

    return best,
        bestDistance
end


-- ============================================================
-- BUILD 74 • AFK AUTO LEVEL TARGET FARM
-- ============================================================

function H:GetMaxPlayerLevel()
    local settings =
        self.Modules.GameSettings

    if type(settings) == "table" then
        local maxLevel =
            tonumber(
                settings.maxLevel
                or settings.MaxLevel
                or settings.MAX_LEVEL
            )

        if maxLevel
            and maxLevel > 0 then

            return
                math.floor(
                    maxLevel
                )
        end
    end

    return 225
end

function H:CleanAutoLevelTargetName(value)
    local s =
        tostring(
            value
            or ""
        )

    s =
        s:gsub(
            "^%s+",
            ""
        )

    s =
        s:gsub(
            "%s+$",
            ""
        )

    if s == "" then
        return ""
    end

    -- Remove common quest-task verbs while keeping the actual enemy name.
    local patterns = {
        "^Defeat%s+",
        "^Eliminate%s+",
        "^Kill%s+",
        "^Slay%s+",
        "^Fell%s+the%s+",
        "^Fell%s+",
        "^Hunt%s+the%s+",
        "^Hunt%s+",
        "^Take%s+down%s+",
    }

    for _, pattern in ipairs(
        patterns
    ) do
        s =
            s:gsub(
                pattern,
                ""
            )
    end

    -- "Clear Kaiden's Subordinates" / "Clear Hoyuzo's Guard"
    local owner =
        s:match(
            "^Clear%s+(.+)'s%s+[Ss]ubordinates$"
        )

    if owner then
        return
            owner
            .. " Subordinate"
    end

    owner =
        s:match(
            "^Clear%s+(.+)'s%s+[Gg]uard$"
        )

    if owner then
        return
            owner
            .. " Subordinate"
    end

    s =
        s:gsub(
            "^Clear%s+",
            ""
        )

    s =
        s:gsub(
            "^Purge%s+",
            ""
        )

    s =
        s:gsub(
            "^Drive%s+[Bb]ack%s+",
            ""
        )

    s =
        s:gsub(
            "^Break%s+the%s+",
            ""
        )

    s =
        s:gsub(
            "%s+[Dd]efeated$",
            ""
        )

    s =
        s:gsub(
            "%s+[Kk]illed$",
            ""
        )

    return s
end

function H:ResolveAutoLevelMobName(raw)
    raw =
        self:CleanAutoLevelTargetName(
            raw
        )

    if raw == "" then
        return nil
    end

    local wanted =
        self:NormalizeMobText(
            raw
        )

    if wanted == "" then
        return nil
    end

    local singularWanted =
        wanted

    if string.sub(
        singularWanted,
        -1
    ) == "s" then

        singularWanted =
            string.sub(
                singularWanted,
                1,
                -2
            )
    end

    local bestName
    local bestScore =
        -math.huge

    local function consider(name)
        name =
            tostring(
                name
                or ""
            )

        if name == ""
            or name == "Any" then

            return
        end

        local normalized =
            self:NormalizeMobText(
                name
            )

        if normalized == "" then
            return
        end

        local score = 0

        if normalized == wanted then
            score += 1000
        end

        if normalized == singularWanted then
            score += 950
        end

        if string.find(
            normalized,
            wanted,
            1,
            true
        ) then
            score += 520
        end

        if string.find(
            wanted,
            normalized,
            1,
            true
        ) then
            score += 480
        end

        if singularWanted ~= wanted
            and string.find(
                normalized,
                singularWanted,
                1,
                true
            ) then

            score += 430
        end

        if score > bestScore then
            bestScore = score
            bestName = name
        end
    end

    for name in pairs(
        self.Data.MobNameMemory
        or {}
    ) do
        consider(
            name
        )
    end

    -- Resolve codes/display names from the game's own NPC data table.
    local live =
        self.Modules.LiveConfig

    if type(live) == "table"
        and type(live.get) == "function" then

        local ok,
            npcData =
            pcall(
                live.get,
                "NpcDataTable"
            )

        if ok
            and type(npcData) == "table" then

            for key, entry in pairs(
                npcData
            ) do
                local fields = {
                    key,
                }

                if type(entry) == "table" then
                    fields[#fields + 1] = entry.Code
                    fields[#fields + 1] = entry.NpcCode
                    fields[#fields + 1] = entry.Name
                    fields[#fields + 1] = entry.DisplayName
                    fields[#fields + 1] = entry.NpcName
                    fields[#fields + 1] = entry.Title
                    fields[#fields + 1] = entry.Model
                    fields[#fields + 1] = entry.ModelName
                    fields[#fields + 1] = entry.Enemy
                end

                local matches =
                    false

                for _, field in ipairs(
                    fields
                ) do
                    if typeof(field) == "string" then
                        local n =
                            self:NormalizeMobText(
                                field
                            )

                        if n == wanted
                            or n == singularWanted
                            or string.find(
                                n,
                                wanted,
                                1,
                                true
                            )
                            or (
                                singularWanted ~= wanted
                                and string.find(
                                    n,
                                    singularWanted,
                                    1,
                                    true
                                )
                            ) then

                            matches = true
                            break
                        end
                    end
                end

                if matches then
                    for _, field in ipairs(
                        fields
                    ) do
                        if typeof(field) == "string" then
                            consider(
                                field
                            )
                        end
                    end
                end
            end
        end
    end

    if bestName
        and bestScore >= 400 then

        return bestName
    end

    return raw
end

function H:ExtractAutoLevelQuestTargets(
    key,
    def
)
    local results = {}
    local seen = {}

    local function add(value)
        if typeof(value) ~= "string" then
            return
        end

        value =
            self:CleanAutoLevelTargetName(
                value
            )

        if value == "" then
            return
        end

        local normalized =
            self:NormalizeMobText(
                value
            )

        if normalized == ""
            or seen[normalized] then

            return
        end

        seen[normalized] = true

        local resolved =
            self:ResolveAutoLevelMobName(
                value
            )

        if resolved
            and resolved ~= "" then

            results[
                #results + 1
            ] =
                resolved
        end
    end

    -- Highest-quality route: the replicated QuestInstance contains the same
    -- Code values copied into an active quest's Tasks folder.
    local questInstance =
        type(def) == "table"
        and def.QuestInstance
        or nil

    if typeof(questInstance) == "Instance" then
        for _, obj in ipairs(
            questInstance:GetDescendants()
        ) do
            if obj:IsA("StringValue") then
                if string.lower(
                    obj.Name
                ) == "code" then

                    add(
                        obj.Value
                    )
                end

                -- Task labels such as "Defeat Bandit".
                if obj.Parent
                    and obj.Parent.Parent
                    and string.lower(
                        obj.Parent.Parent.Name
                    ) == "tasks" then

                    add(
                        obj.Parent.Name
                    )
                end
            elseif obj:IsA("Configuration")
                or obj:IsA("Folder") then

                local code =
                    obj:GetAttribute(
                        "Code"
                    )
                    or obj:GetAttribute(
                        "NpcCode"
                    )
                    or obj:GetAttribute(
                        "Enemy"
                    )
                    or obj:GetAttribute(
                        "Mob"
                    )

                if typeof(code) == "string" then
                    add(
                        code
                    )
                end
            end
        end
    end

    -- Marker keys are commonly "Defeat <NpcCode>".
    if type(def) == "table"
        and type(def.Markers) == "table" then

        for markerName,
            marker in pairs(
                def.Markers
            ) do

            add(
                tostring(
                    markerName
                )
            )

            if type(marker) == "table" then
                add(marker.Code)
                add(marker.NpcCode)
                add(marker.Enemy)
                add(marker.Mob)
                add(marker.Name)
            end
        end
    end

    if type(def) == "table"
        and type(def.TaskSpecs) == "table" then

        for taskName,
            spec in pairs(
                def.TaskSpecs
            ) do

            add(
                tostring(
                    taskName
                )
            )

            if type(spec) == "table" then
                add(spec.Code)
                add(spec.NpcCode)
                add(spec.Enemy)
                add(spec.Mob)
                add(spec.Name)
            end
        end
    end

    if type(def) == "table" then
        add(def.Code)
        add(def.NpcCode)
        add(def.Enemy)
        add(def.Mob)
        add(def.Target)
        add(def.TargetNpc)
    end

    -- Last-resort title parser.
    if #results == 0 then
        local questName =
            questInstance
            and questInstance.Name
            or tostring(
                key
                or ""
            )

        add(
            questName
        )
    end

    -- Known early-game titles from the replicated quest set. These are only
    -- fallbacks when the quest task itself did not expose a Code.
    if #results == 0 then
        local title =
            string.lower(
                tostring(
                    questInstance
                    and questInstance.Name
                    or key
                    or ""
                )
            )

        local known = {
            ["hunt the bears"] = "BearCub",
            ["fell the mother bear"] = "MotherBear",
            ["clear kaiden's subordinates"] = "Kaiden Subordinate",
            ["defeat kaiden"] = "Kaiden",
            ["clear hoyuzo's guard"] = "Hoyuzo Subordinate",
            ["defeat hoyuzo"] = "Hoyuzo",
        }

        add(
            known[
                title
            ]
        )
    end

    return results
end

function H:BuildAutoLevelCandidates(
    force
)
    local store =
        self.Data.AutoLevel

    if type(store) ~= "table" then
        store = {
            Candidates = {},
            BuiltAt = 0,
        }

        self.Data.AutoLevel =
            store
    end

    local now =
        os.clock()

    if not force
        and type(store.Candidates) == "table"
        and #store.Candidates > 0
        and now - (store.BuiltAt or 0) < 5 then

        return
            store.Candidates
    end

    self:RefreshMobs()

    local quests =
        self.Modules.Quests

    local candidates = {}
    local dedupe = {}

    if type(quests) == "table"
        and type(quests.Holder) == "table" then

        for key, def in pairs(
            quests.Holder
        ) do
            if type(key) == "string"
                and type(def) == "table" then

                local category =
                    tostring(
                        def.Category
                        or ""
                    )

                if type(
                    quests.GetQuestCategory
                ) == "function" then

                    pcall(
                        function()
                            local value =
                                quests.GetQuestCategory(
                                    key
                                )

                            if value ~= nil then
                                category =
                                    tostring(
                                        value
                                    )
                            end
                        end
                    )
                end

                if category == "Combat"
                    or category == "BossHunt" then

                    local required =
                        self:QuestRequiredLevel(
                            def
                        )

                    local maxLevel =
                        type(def.Requirements)
                            == "table"
                        and tonumber(
                            def.Requirements.MaxLevel
                        )
                        or nil

                    local exp =
                        type(def.Rewards)
                            == "table"
                        and tonumber(
                            def.Rewards.Exp
                        )
                        or 0

                    local targets =
                        self:ExtractAutoLevelQuestTargets(
                            key,
                            def
                        )

                    for _, target in ipairs(
                        targets
                    ) do
                        local resolved =
                            self:ResolveAutoLevelMobName(
                                target
                            )
                            or target

                        local normalized =
                            self:NormalizeMobText(
                                resolved
                            )

                        if normalized ~= "" then
                            local rec = {
                                Target = resolved,
                                RequiredLevel =
                                    tonumber(
                                        required
                                    )
                                    or 0,
                                MaxLevel =
                                    maxLevel,
                                Exp =
                                    tonumber(
                                        exp
                                    )
                                    or 0,
                                Quest =
                                    def.QuestInstance
                                    and tostring(
                                        def.QuestInstance.Name
                                    )
                                    or key,
                                QuestKey = key,
                                Category = category,
                            }

                            local dedupeKey =
                                normalized
                                .. ":"
                                .. tostring(
                                    rec.RequiredLevel
                                )

                            local old =
                                dedupe[
                                    dedupeKey
                                ]

                            if not old
                                or rec.Exp > old.Exp then

                                dedupe[
                                    dedupeKey
                                ] =
                                    rec
                            end
                        end
                    end
                end
            end
        end
    end

    for _, rec in pairs(
        dedupe
    ) do
        candidates[
            #candidates + 1
        ] =
            rec
    end

    table.sort(
        candidates,
        function(a, b)
            if a.RequiredLevel
                ~= b.RequiredLevel then

                return
                    a.RequiredLevel
                    < b.RequiredLevel
            end

            if a.Exp ~= b.Exp then
                return
                    a.Exp
                    < b.Exp
            end

            return
                tostring(
                    a.Target
                )
                < tostring(
                    b.Target
                )
        end
    )

    store.Candidates =
        candidates

    store.BuiltAt =
        now

    return candidates
end


function H:GetAutoLevelEffectiveLevel()
    local store =
        self.Data.AutoLevel
        or {}

    self.Data.AutoLevel =
        store

    local direct =
        tonumber(
            self:GetPlayerLevel()
        )

    if direct
        and direct > 0 then

        direct =
            math.floor(
                direct
            )

        store.LastKnownLevel =
            math.max(
                tonumber(
                    store.LastKnownLevel
                )
                or 0,
                direct
            )

        return direct,
            true
    end

    -- If Roblox's level value/HUD is not readable, an already-active quest
    -- proves the player meets at least that quest's requirement.
    local active =
        self:GetActiveQuest()

    if active then
        local def =
            select(
                1,
                self:QuestDefinition(
                    active.Key,
                    active.Name
                )
            )

        local required =
            self:QuestRequiredLevelFromActive(
                active,
                def
            )

        if required
            and required > 0 then

            store.LastKnownLevel =
                math.max(
                    tonumber(
                        store.LastKnownLevel
                    )
                    or 0,
                    required
                )
        end
    end

    return
        tonumber(
            store.LastKnownLevel
        )
        or 0,
        false
end

function H:SyncAutoLevelToActiveQuest()
    if not self.State.AutoLevelFarm then
        return false
    end

    local active =
        self:GetActiveQuest()

    if not active then
        return false
    end

    local def,
        holderKey =
        self:QuestDefinition(
            active.Key,
            active.Name
        )

    -- One active quest is allowed at a time in this game. Never attempt to
    -- accept a different levelling quest while one is already in the Holder.
    local questKey =
        tostring(
            holderKey
            or active.Key
            or ""
        )


    local activeQuestIdentity =
        self:NormalizeMobText(
            questKey
            .. "|"
            .. tostring(
                active.Name
                or ""
            )
        )

    if self.Runtime.LastAutoLevelQuestIdentity
        ~= activeQuestIdentity then

        self.Runtime.LastAutoLevelQuestIdentity =
            activeQuestIdentity

        self.Runtime.LastSafeQuestTargetQuery =
            nil

        self.Runtime.LastSafeQuestTargetPosition =
            nil

        self.Runtime.LastSafeQuestTargetAt =
            0
    end

    if questKey ~= "" then
        self.State.SelectedQuest =
            questKey
    end

    self.State.AutoQuest =
        true

    self.State.AutoAccept =
        true

    self.State.AutoFarmMobs =
        true

    local target =
        active.Code
        or active.Task

    if target then
        target =
            self:ResolveAutoLevelMobName(
                target
            )
            or tostring(
                target
            )

        if target ~= "" then
            local changed =
                tostring(
                    self.State.SelectedMob
                    or ""
                )
                ~= target

            self.State.SelectedMob =
                target

            if changed then
                self:StopSmoothMobTravel()
                self:StopMovement()
                self:StopAttackHold()
                self:StopBlocking()
                self:ResetAggressiveMobState()
                self:ResetOrbitState()

                self.Data.CurrentFarmTarget =
                    nil

                self.Runtime.AttackTarget =
                    nil

                self.Runtime.QuestEnemyCache =
                    nil
            end
        end
    end

    local store =
        self.Data.AutoLevel

    store.CurrentTarget =
        tostring(
            self.State.SelectedMob
            or ""
        )

    store.CurrentQuest =
        tostring(
            active.Name
            or (
                def
                and def.QuestInstance
                and def.QuestInstance.Name
            )
            or questKey
        )

    store.CurrentQuestKey =
        questKey

    local activeCategory =
        "Active Quest"

    if type(self.Modules.Quests) == "table"
        and type(
            self.Modules.Quests.GetQuestCategory
        ) == "function"
        and questKey ~= "" then

        pcall(
            function()
                local value =
                    self.Modules.Quests.GetQuestCategory(
                        questKey
                    )

                if value ~= nil then
                    activeCategory =
                        tostring(
                            value
                        )
                end
            end
        )
    end

    store.CurrentRecord = {
        Target =
            store.CurrentTarget,
        RequiredLevel =
            self:QuestRequiredLevelFromActive(
                active,
                def
            ),
        Quest =
            store.CurrentQuest,
        QuestKey =
            questKey,
        Category =
            activeCategory,
    }

    if activeCategory == "BossHunt" then
        store.BossLoopQuestWasActive =
            true
    end

    store.CurrentLevel =
        select(
            1,
            self:GetAutoLevelEffectiveLevel()
        )

    self.Runtime.AutoLevelTargetSetAt =
        os.clock()

    self:UpdateAutoLevelInfo(
        store.CurrentTarget,
        store.CurrentRecord
    )

    -- FarmStep owns the live quest target/combat status.


    return true
end


function H:BossDefinitionInThisPlace(entry)
    if type(entry) ~= "table" then return true end
    local place = tonumber(entry.PlaceId or entry.MapPlaceId)
    return (not place or place == game.PlaceId)
        and entry.DungeonOnly ~= true and entry.ArenaOnly ~= true
        and entry.TrainingOnly ~= true
end

function H:ValidBossPosition(value)
    if typeof(value) == "CFrame" then value = value.Position end
    if typeof(value) ~= "Vector3" then return nil end
    if value.X ~= value.X or value.Y ~= value.Y or value.Z ~= value.Z
        or math.abs(value.X) >= 10000 or math.abs(value.Y) >= 10000
        or math.abs(value.Z) >= 10000
        or value.Y <= self.S.Workspace.FallenPartsDestroyHeight + 30 then
        return nil
    end
    return value
end

function H:DiscoverBossCatalog(force)
    local store = self.Data.AutoLevel
    if not force and os.clock() - (store.BossCatalogRefreshAt or -100) < 20 then return end
    store.BossCatalogRefreshAt = os.clock()
    local live = self.Modules.LiveConfig
    if type(live) ~= "table" or type(live.get) ~= "function" then return end
    local ok, entries = pcall(live.get, "NpcDataTable")
    if not ok or type(entries) ~= "table" then return end
    for key, entry in pairs(entries) do
        if type(entry) == "table" and self:BossDefinitionInThisPlace(entry) then
            local kind = self:NormalizeMobText(entry.Type or entry.NpcType or entry.Category)
            if entry.IsBoss == true or entry.Boss == true or kind == "boss"
                or kind == "worldboss" or kind == "bosshunt" then
                local code = tostring(entry.NpcCode or entry.Code or key)
                local rec = self.Data.Bosses[code] or {Code = code}
                rec.Title = rec.Title or entry.DisplayName or entry.Title or entry.Name or code
                rec.Center = rec.Center or self:ValidBossPosition(entry.Center or entry.SpawnPosition)
                rec.RequiredLevel = rec.RequiredLevel or tonumber(entry.RequiredLevel or entry.MinLevel)
                rec.NightOnly = rec.NightOnly or entry.OnlyAtNight == true
                rec.CatalogDefinition = entry
                self.Data.Bosses[code] = rec
                self.Data.BossCodeMemory[code] = true
            end
        end
    end
end

function H:BuildEligibleBossLoop(force)
    local store = self.Data.AutoLevel or {}
    self.Data.AutoLevel = store
    local now = os.clock()
    if not force and type(store.BossLoopRoutes) == "table"
        and #store.BossLoopRoutes > 0 and now - (store.BossLoopBuiltAt or 0) < 15 then
        return store.BossLoopRoutes
    end
    self:RefreshBosses()
    self:DiscoverBossCatalog(force)
    local routes, seen, known = {}, {}, {}
    for code, boss in pairs(self.Data.Bosses or {}) do
        if type(boss) == "table" then
            known[self:NormalizeMobText(code)] = boss
            known[self:NormalizeMobText(boss.Code)] = boss
            known[self:NormalizeMobText(boss.Title)] = boss
        end
    end
    local quests = self.Modules.Quests
    local function add(source, boss, def)
        local canonical = boss and boss.Code or source.Target
        local key = self:NormalizeMobText(canonical)
        if key == "" or seen[key] or self:IsBossLoopTrainingTarget(source)
            or not self:BossDefinitionInThisPlace(def)
            or (boss and not self:BossDefinitionInThisPlace(boss.CatalogDefinition)) then return end
        local rec = {}
        for k, v in pairs(source) do rec[k] = v end
        rec.Target = canonical
        rec.OriginalCategory = rec.Category
        rec.Category, rec.DirectBossLoop, rec.QuestAvailable = "BossHunt", true, false
        rec.Title = boss and boss.Title or rec.Target
        rec.Spawn = self:ValidBossPosition(boss and boss.Center)
            or self:ValidBossPosition(self:GetMobStreamHint(rec.Target))
        rec.NightOnly = boss and boss.NightOnly == true or false
        -- Quest unlock levels do not gate direct combat with a world boss.
        -- Retain them as information; exclude explicitly incompatible places.
        rec.RequiredLevel = tonumber(rec.RequiredLevel) or 0
        seen[key] = true
        routes[#routes + 1] = rec
    end
    for _, source in ipairs(self:BuildAutoLevelCandidates(force == true) or {}) do
        local boss = known[self:NormalizeMobText(source.Target)]
        if source.Category == "BossHunt" or boss then
            local def = type(quests) == "table" and type(quests.Holder) == "table"
                and quests.Holder[source.QuestKey] or nil
            local rec = {}
            for k, v in pairs(source) do rec[k] = v end
            rec.OfferNpc = def and def.OfferNpc
            add(rec, boss, def)
        end
    end
    for code, boss in pairs(self.Data.Bosses or {}) do
        if type(boss) == "table" then
            add({Target = tostring(boss.Code or code), RequiredLevel = boss.RequiredLevel,
                Category = "BossRegistry", Exp = 0}, boss, boss.CatalogDefinition)
        end
    end
    table.sort(routes, function(a,b)
        return self:NormalizeMobText(a.Target) < self:NormalizeMobText(b.Target)
    end)
    store.BossLoopRoutes, store.BossLoopBuiltAt = routes, now
    -- Preserve cursor identity when newly discovered bosses alter the list.
    local cursor = self:NormalizeMobText(store.CurrentTarget or store.BossLoopCursorKey)
    for i, rec in ipairs(routes) do
        if self:NormalizeMobText(rec.Target) == cursor then store.BossLoopIndex = i; break end
    end
    return routes
end

function H:IsExactKnownBossIdentity(
    value
)
    local wanted =
        self:NormalizeMobText(
            value
        )

    if wanted == "" then
        return false
    end

    self:RefreshBosses()

    local function exact(
        candidate
    )
        return
            self:NormalizeMobText(
                candidate
            ) == wanted
    end

    for code, rec in pairs(
        self.Data.Bosses
        or {}
    ) do
        if exact(
            code
        ) then
            return true
        end

        if type(rec) == "table" then
            if exact(
                rec.Code
            )
                or exact(
                    rec.Title
                ) then

                return true
            end

            if rec.Model
                and (
                    exact(
                        rec.Model.Name
                    )
                    or exact(
                        rec.Model:GetAttribute(
                            "NpcCode"
                        )
                    )
                    or exact(
                        rec.Model:GetAttribute(
                            "Code"
                        )
                    )
                ) then

                return true
            end

            if rec.Info
                and (
                    exact(
                        rec.Info:GetAttribute(
                            "NpcCode"
                        )
                    )
                    or exact(
                        rec.Info:GetAttribute(
                            "Code"
                        )
                    )
                    or exact(
                        rec.Info:GetAttribute(
                            "Title"
                        )
                    )
                ) then

                return true
            end
        end
    end

    return false
end


function H:IsBossLoopTrainingTarget(
    rec
)
    if type(rec) ~= "table" then
        return false
    end

    local combined =
        string.lower(
            table.concat(
                {
                    tostring(
                        rec.Target
                        or ""
                    ),
                    tostring(
                        rec.Quest
                        or ""
                    ),
                    tostring(
                        rec.QuestKey
                        or ""
                    ),
                    tostring(
                        rec.OfferNpc
                        or ""
                    ),
                },
                " "
            )
        )

    local blockedWords = {
        "trainee",
        "trainer",
        "training",
        "aim training",
        "mastery training",
        "practice",
        "sparring",
        "tutorial",
    }

    for _, word in ipairs(
        blockedWords
    ) do
        if string.find(
            combined,
            word,
            1,
            true
        ) then
            return true
        end
    end

    return false
end

-- One pass over live NPCs answers which eligible bosses are actually spawned.
-- A BossTag by itself is spawn metadata; require a living humanoid and root.
function H:VisibleBossLoopTargets(routes)
    local store = self.Data.AutoLevel
    local cached = store.BossLoopVisibleCache
    local now = os.clock()
    if type(cached) == "table" and cached.Routes == routes
        and now - (cached.At or 0) < 0.8 then
        return cached.Map
    end

    local wanted, visible = {}, {}
    for _, rec in ipairs(routes) do
        if not self:IsBossLoopTrainingTarget(rec) then
            wanted[self:NormalizeMobText(rec.Target)] = true
        end
    end

    local me = self:Root()
    local function register(model, hum, info)
        if not model or not model:IsA("Model") or not model.Parent
            or not model:IsDescendantOf(self.S.Workspace)
            or not hum or hum.Health <= 0 then
            return
        end
        local root = model:FindFirstChild("HumanoidRootPart", true)
            or model.PrimaryPart
        if not root or not root:IsA("BasePart") then return end

        local function match(value)
            local key = self:NormalizeMobText(value)
            if key == "" or not wanted[key] then return end
            local old = visible[key]
            local distance = me and (me.Position - root.Position).Magnitude or 0
            if not old or distance < old.Distance then
                visible[key] = {Model = model, Root = root, Hum = hum, Distance = distance}
            end
        end

        match(model.Name)
        for _, attr in ipairs({"NpcCode", "Code", "UniqueName", "Title"}) do
            match(model:GetAttribute(attr))
        end
        info = info or model:FindFirstChild("BossInfo", true)
        if info then
            for _, attr in ipairs({"NpcCode", "Code", "Title"}) do
                match(info:GetAttribute(attr))
            end
        end
        local parent = model.Parent
        for _ = 1, 5 do
            if not parent or parent.Name == "ActiveNpcs" then break end
            match(parent.Name)
            match(parent:GetAttribute("NpcCode"))
            match(parent:GetAttribute("Code"))
            match(parent:GetAttribute("Title"))
            parent = parent.Parent
        end
    end

    local npcTree = self.S.Workspace:FindFirstChild("Humanoids")
    if npcTree then
        for _, obj in ipairs(npcTree:GetDescendants()) do
            if obj:IsA("Humanoid") and obj.Health > 0 then
                local model = obj.Parent
                if model and model:IsA("Model") then register(model, obj) end
            end
        end
    end
    for _, info in ipairs(self.S.CollectionService:GetTagged("BossTag")) do
        if info and info.Parent then
            local model = info:IsA("Model") and info
                or info:FindFirstAncestorOfClass("Model")
            if model then
                local hum = model:FindFirstChildOfClass("Humanoid")
                    or model:FindFirstChildWhichIsA("Humanoid", true)
                register(model, hum, info)
            end
        end
    end

    store.BossLoopVisibleCache = {Routes = routes, At = now, Map = visible}
    return visible
end

function H:BossFarmOptions()
    local options = {{Value = "All Bosses", Label = "All Bosses"}}
    local seen = {}
    for _, route in ipairs(self:BuildEligibleBossLoop(false) or {}) do
        local name = tostring(route.Target or "")
        local key = self:NormalizeMobText(name)
        if key ~= "" and not seen[key]
            and not self:IsBossLoopTrainingTarget(route) then
            seen[key] = true
            options[#options + 1] = {Value = name, Label = tostring(route.Title or name)}
        end
    end
    return options
end

function H:ChooseNextBossLoopTarget(advance)
    local store = self.Data.AutoLevel or {}
    self.Data.AutoLevel = store
    local routes = self:BuildEligibleBossLoop(false)
    if #routes == 0 then return nil, nil end
    local choice = self:NormalizeMobText(self.State.BossFarmChoice)
    local all = choice == "" or choice == "allbosses"
    local function matches(rec)
        return rec and not self:IsBossLoopTrainingTarget(rec)
            and (all or self:NormalizeMobText(rec.Target) == choice)
    end
    local current = store.CurrentRecord
    -- Refreshing data or respawning must never reselect a visible nearby boss.
    if not advance and matches(current) then return current.Target, current end
    local visited = store.BossLoopVisited or {}
    store.BossLoopVisited = visited
    if advance and current then visited[self:NormalizeMobText(current.Target)] = true end
    local cursor = self:NormalizeMobText((current and current.Target) or store.BossLoopCursorKey)
    local start = 1
    for i, rec in ipairs(routes) do
        if self:NormalizeMobText(rec.Target) == cursor then start = i % #routes + 1; break end
    end
    local visible = self:VisibleBossLoopTargets(routes)
    local skipped, now = store.BossLoopSkippedUntil or {}, os.clock()
    local function ready(rec)
        local key = self:NormalizeMobText(rec.Target)
        local live = visible[key]
        return (live and live.Model.Parent and live.Hum.Health > 0)
            or (skipped[key] or 0) <= now
    end
    local anyUnvisited, anyReady = false, false
    for _, rec in ipairs(routes) do
        if matches(rec) then
            if not visited[self:NormalizeMobText(rec.Target)] then anyUnvisited = true end
            if ready(rec) then anyReady = true end
        end
    end
    if not anyUnvisited then
        if not anyReady then return nil, nil end
        visited = {}
        store.BossLoopVisited = visited
        store.BossLoopLap = (store.BossLoopLap or 1) + 1
    end
    for offset = 0, #routes - 1 do
        local at = (start + offset - 1) % #routes + 1
        local source = routes[at]
        local key = self:NormalizeMobText(source.Target)
        if matches(source) and not visited[key] and ready(source) then
            local rec = {}
            for k, v in pairs(source) do rec[k] = v end
            rec.LoopIndex, rec.LoopCount = at, #routes
            rec.Category = "BossHunt"
            store.BossLoopIndex, store.BossLoopCursorKey = at, rec.Target
            store.BossLoopAdvancePending = false
            store.BossLoopCurrentKey = rec.Target
            store.BossLoopLap = store.BossLoopLap or 1
            return rec.Target, rec
        end
    end
    return nil, nil
end

function H:ChooseAutoLevelTarget()
    local level,
        exactLevel =
        self:GetAutoLevelEffectiveLevel()

    local candidates =
        self:BuildAutoLevelCandidates(
            false
        )

    local blocked =
        self.Runtime.AutoLevelTargetFailUntil
        or {}

    self.Runtime.AutoLevelTargetFailUntil =
        blocked

    local best
    local bestScore =
        -math.huge

    for _, rec in ipairs(
        candidates
        or {}
    ) do
        local required =
            tonumber(
                rec.RequiredLevel
            )
            or 0

        local maxLevel =
            tonumber(
                rec.MaxLevel
            )

        local blockedUntil =
            blocked[
                self:NormalizeMobText(
                    rec.Target
                )
            ]
            or 0

        local eligible =
            required <= level
            and (
                not maxLevel
                or level <= maxLevel
            )

        -- When the level number itself is unavailable, the game's own
        -- CanAddQuest result is stronger evidence than guessing "Lv 1".
        if not exactLevel
            and type(self.Modules.Quests) == "table"
            and type(self.Modules.Quests.CanAddQuest) == "function"
            and tostring(rec.QuestKey or "") ~= "" then

            local okCan,
                canAdd =
                pcall(
                    self.Modules.Quests.CanAddQuest,
                    self.Player,
                    rec.QuestKey
                )

            if okCan
                and canAdd == true then

                eligible =
                    true

                if required > level then
                    level =
                        required

                    self.Data.AutoLevel.LastKnownLevel =
                        math.max(
                            tonumber(
                                self.Data.AutoLevel.LastKnownLevel
                            )
                            or 0,
                            required
                        )
                end
            end
        end

        if eligible
            and os.clock()
                >= blockedUntil then

            local score =
                required * 1000000
                + (
                    tonumber(
                        rec.Exp
                    )
                    or 0
                ) * 10

            -- Prefer ordinary combat mobs when both choices unlock at the
            -- same level. BossHunt remains a valid late-game fallback.
            if rec.Category == "Combat" then
                score += 250000
            end

            local normalized =
                self:NormalizeMobText(
                    rec.Target
                )

            for name in pairs(
                self.Data.MobNameMemory
                or {}
            ) do
                if self:NormalizeMobText(
                    name
                ) == normalized then

                    score += 50000
                    break
                end
            end

            if self.State.SelectedMob
                == rec.Target then

                score += 5000
            end

            if score > bestScore then
                bestScore = score
                best = rec
            end
        end
    end

    if best then
        return
            best.Target,
            best
    end

    -- Under-levelled / incomplete quest-data fallback:
    -- use a real loaded non-boss mob instead of stopping the AFK session.
    local mob =
        select(
            1,
            self:LevelGrindTarget()
        )

    if mob then
        return
            tostring(
                mob.Name
            ),
            {
                Target =
                    tostring(
                        mob.Name
                    ),
                RequiredLevel = 1,
                Exp = 0,
                Quest =
                    "Live fallback",
                Category =
                    "Fallback",
            }
    end

    return nil, nil
end

function H:UpdateAutoLevelInfo(
    target,
    rec
)
    local label =
        self.UI
        and self.UI.AutoLevelInfo

    if not label
        or not label.Parent then

        return
    end

    local level =
        select(
            1,
            self:GetAutoLevelEffectiveLevel()
        )

    local activeForLevel =
        self:GetActiveQuest()

    if activeForLevel then
        local activeDef =
            select(
                1,
                self:QuestDefinition(
                    activeForLevel.Key,
                    activeForLevel.Name
                )
            )

        level =
            math.max(
                tonumber(level) or 0,
                tonumber(
                    self:QuestRequiredLevelFromActive(
                        activeForLevel,
                        activeDef
                    )
                )
                or 0
            )
    end

    if rec
        and tonumber(
            rec.RequiredLevel
        ) then

        level =
            math.max(
                tonumber(level)
                    or 0,
                tonumber(
                    rec.RequiredLevel
                )
                    or 0
            )
    end

    local maxLevel =
        self:GetMaxPlayerLevel()

    if not self.State.AutoLevelFarm then
        label.Text =
            "OFF • Boss Loop cycles only level-eligible real bosses using stable normal-M1 combat. Generic training/combat quests are excluded."
        return
    end

    local activeQuest =
        self:GetActiveQuest()

    local questStateText =
        "NO ACTIVE QUEST"

    if activeQuest then
        local progress =
            self:QuestProgressText(
                activeQuest
            )

        questStateText =
            "QUEST ACTIVE ✓ "
            .. tostring(
                activeQuest.Name
                or activeQuest.Key
                or "Quest"
            )

        if activeQuest.Code
            or activeQuest.Task then

            questStateText =
                questStateText
                .. " • "
                .. tostring(
                    activeQuest.Code
                    or activeQuest.Task
                )
        end

        if progress ~= "" then
            questStateText =
                questStateText
                .. " "
                .. progress
        end
    end

    label.Text =
        "ON • Lv "
        .. (
            level > 0
            and tostring(
                level
            )
            or "?"
        )
        .. "/"
        .. tostring(
            maxLevel
        )
        .. " • "
        .. questStateText
        .. "\nTarget: "
        .. tostring(
            target
            or "searching"
        )
        .. (
            rec
            and (
                " • route Lv "
                .. tostring(
                    rec.RequiredLevel
                    or "?"
                )
                .. " • "
                .. tostring(
                    rec.Category
                    or "Combat"
                )
                .. (
                    tonumber(
                        rec.LoopIndex
                    )
                    and tonumber(
                        rec.LoopCount
                    )
                    and (
                        " • Boss "
                        .. tostring(
                            rec.LoopIndex
                        )
                        .. "/"
                        .. tostring(
                            rec.LoopCount
                        )
                    )
                    or ""
                )
            )
            or ""
        )

end

function H:AutoLevelFarmStep(
    force
)
    if not self.State.AutoLevelFarm then
        self:UpdateAutoLevelInfo(
            nil,
            nil
        )

        return false
    end

    if self.Data.AutoLevel and self.Data.AutoLevel.BossLoopRespawning then
        return true
    end

    local liveHum =
        self:Humanoid()

    if not liveHum
        or liveHum.Health <= 0 then

        self:SetStatus(
            "Auto Level • waiting for respawn • farm stays ON"
        )

        return true
    end

    local level,
        _exactLevel =
        self:GetAutoLevelEffectiveLevel()

    local maxLevel =
        self:GetMaxPlayerLevel()

    if self.State.BossStopAtMaxLevel == true
        and level > 0 and level >= maxLevel then

        self.State.AutoLevelFarm =
            false

        self.State.AutoFarmMobs =
            false

        self:StopAttackHold()
        self:StopBlocking()
        self:StopMovement()

        self:RefreshToggleButtons()

        self:SetStatus(
            "Auto Level • MAX LEVEL "
            .. tostring(
                level
            )
            .. "/"
            .. tostring(
                maxLevel
            )
        )

        self:UpdateAutoLevelInfo(
            nil,
            nil
        )

        return true
    end

    local store =
        self.Data.AutoLevel

    if type(store) ~= "table" then
        store = {}
        self.Data.AutoLevel =
            store
    end

    -- BUILD 99:
    -- Boss Loop is intentionally independent from quest NPCs/quest state.
    -- An existing quest is left untouched; boss selection and farming continue
    -- directly from the eligible boss list.

    if store.BossLoopAdvancePending
        and self.Runtime.PostKillLooting then

        self:SetStatus(
            "Boss Loop • collecting boss chest / drops before next boss"
        )

        return true
    end

    local current =
        tostring(
            self.State.SelectedMob
            or ""
        )

    local currentRecord = store.CurrentRecord
    if current ~= ""
        and (type(currentRecord) ~= "table"
            or currentRecord.Category ~= "BossHunt"
            or self:IsBossLoopTrainingTarget(currentRecord)
            or self:NormalizeMobText(currentRecord.Target)
                ~= self:NormalizeMobText(current)) then

        -- BUILD 98:
        -- Purge any trainer/non-boss target inherited from Build97 or a saved
        -- config before the farm lane can walk to its NPC.
        self.State.SelectedMob =
            ""

        self.State.SelectedQuest =
            ""

        self.State.AutoQuest =
            false

        self.State.AutoAccept =
            false

        store.CurrentTarget =
            nil

        store.CurrentQuest =
            nil

        store.CurrentQuestKey =
            nil

        store.CurrentRecord =
            nil

        store.BossLoopRoutes =
            {}

        store.BossLoopBuiltAt =
            0

        store.BossLoopIndex =
            0

        self.Data.CurrentFarmTarget =
            nil

        self.Runtime.AttackTarget =
            nil

        self:StopMovement()
        self:StopSmoothMobTravel()

        current =
            ""
    end

    local needsTarget =
        force == true
        or store.BossLoopAdvancePending == true
        or current == ""
        or store.CurrentLevel ~= level
        or store.CurrentTarget ~= current

    local chosenRec =
        store.CurrentRecord

    if needsTarget then
        local advanceBoss =
            store.BossLoopAdvancePending == true

        local target,
            rec =
            self:ChooseNextBossLoopTarget(
                advanceBoss
            )

        if not target then
            -- Rebuild missing route data once; a nonempty route list with no
            -- visible living bosses must not be rescanned every 0.35 seconds.
            if #(store.BossLoopRoutes or {}) == 0
                and os.clock() >= (store.BossLoopNoRoutesRetryAt or 0) then
                store.BossLoopNoRoutesRetryAt = os.clock() + 3
                self:BuildAutoLevelCandidates(true)
                self:BuildEligibleBossLoop(true)
                target, rec = self:ChooseNextBossLoopTarget(advanceBoss)
            end
        end

        if target
            and target ~= "" then

            local changed =
                target
                ~= current

            self.State.SelectedMob =
                target

            -- BUILD 75 • QUEST-FIRST AUTO LEVEL
            -- Use the chosen quest's real replicated key so we collect the
            -- quest XP before/while farming the enemy.
            -- BUILD 99:
            -- Direct boss rotation only. Never wait for a quest giver.
            self.State.SelectedQuest =
                ""

            self.State.AutoQuest =
                false

            self.State.AutoAccept =
                false

            if rec then
                rec.QuestAvailable =
                    false

                rec.DirectBossLoop =
                    true
            end

            store.CurrentTarget =
                target

            store.CurrentLevel =
                level

            store.CurrentRequiredLevel =
                rec
                and rec.RequiredLevel
                or 0

            store.CurrentQuest =
                rec
                and rec.Quest
                or nil

            store.CurrentQuestKey =
                rec
                and rec.QuestKey
                or nil

            store.CurrentCategory =
                rec
                and rec.Category
                or nil

            store.CurrentRecord =
                rec

            chosenRec =
                rec

            self.Runtime.AutoLevelTargetSetAt =
                os.clock()

            self.Runtime.BossProbeDestination = nil
            self.Runtime.BossProbeInitialDistance = nil
            self.Runtime.BossProbeArrivedAt = nil
            self.Runtime.BossProbeLastTweenAt = 0
            self.Runtime.BossProbeInstantTarget = nil

            if changed then
                store.BossLoopSeenTarget =
                    false

                store.BossLoopSeenTargetKey =
                    nil

                store.BossLoopLastSeenAt =
                    0

                store.BossLoopLastSeenModel =
                    nil

                store.BossLoopLastSeenHealth =
                    nil

                self.Runtime.LastSafeQuestTargetQuery =
                    nil

                self.Runtime.LastSafeQuestTargetPosition =
                    nil

                self.Runtime.LastSafeQuestTargetAt =
                    0

                self:StopSmoothMobTravel()
                self:StopMovement()
                self:StopAttackHold()
                self:StopBlocking()

                self:ResetAggressiveMobState()
                self:ResetOrbitState()

                self.Data.CurrentFarmTarget =
                    nil

                self.Runtime.AttackTarget =
                    nil
            end

            if self.UI.DropdownRefresh
                and self.UI.DropdownRefresh.SelectedMob then

                pcall(
                    self.UI.DropdownRefresh.SelectedMob
                )
            end
        else
            self.State.SelectedMob =
                ""

            self.State.SelectedQuest =
                ""

            self.State.AutoQuest =
                false

            self.State.AutoAccept =
                false

            store.CurrentTarget = nil
            store.CurrentRecord = nil
            self.Data.CurrentFarmTarget = nil
            self.Runtime.AttackTarget = nil
            self:StopBossHover()
            self:StopSmoothMobTravel()
            self:StopMovement()
            self.State.AutoFarmMobs = true

            local individual = tostring(self.State.BossFarmChoice or "All Bosses")
            self:SetStatus(
                #(store.BossLoopRoutes or {}) == 0
                    and "Boss Loop • no compatible boss route discovered yet"
                    or (self:NormalizeMobText(individual) ~= "allbosses"
                        and "Boss Loop • " .. individual .. " not spawned • retrying"
                        or "Boss Loop • no compatible boss spawned • checking again")
            )

            self:UpdateAutoLevelInfo(
                nil,
                nil
            )

            return true
        end
    end

    -- AFK reliability defaults.
    self.State.AutoWorldBoss =
        false

    self.State.KillAura =
        false

    self.State.AutoQuest =
        false

    self.State.AutoAccept =
        false

    self.State.SelectedQuest =
        ""

    self.State.SmartProgression =
        false

    self.State.AutoFarmMobs =
        true

    self.State.AutoEquipCombat =
        true

    self.State.AutoParry =
        true

    self.State.PerfectBlock =
        true

    self.State.PingAwareParry =
        true

    self.State.SafeCombat =
        true

    self.State.AntiAFK =
        true

    -- BUILD 101:
    -- Boss Loop owns post-kill rewards. Always collect spawned boss chests and
    -- floor drops before rotating to the next boss.
    self.State.AutoChests =
        true

    self.State.AutoDrops =
        true

    self.State.AutoLootAfterKill =
        true

    -- Use the already-tested 10% normal-world execute route for faster
    -- unattended levelling while preserving reward credit.
    -- BUILD 94:
    -- AFK Auto Level must stay stable over long unattended sessions.
    -- Instant Kill deliberately sends owned NPC assemblies into the void, so it
    -- is disabled here. Normal close-melee M1 combat handles the full kill.
    self.State.InstantKill =
        false

    self.Runtime.InstantKillThresholdLocked =
        false

    self.Runtime.InstantKillBusy =
        false

    self.Runtime.InstantKillTarget =
        nil

    self:UpdateAutoLevelInfo(
        self.State.SelectedMob,
        chosenRec
            or store.CurrentRecord
    )

    self:RefreshToggleButton(
        "AutoFarmMobs"
    )

    self:RefreshToggleButton(
        "InstantKill"
    )

    return true
end

function H:QuestOptions()
    local options = {
        {
            Value = "",
            Label = "None • choose a quest to farm",
            Level = -1,
        },
    }

    local quests = self.Modules.Quests

    if type(quests) ~= "table"
        or type(quests.Holder) ~= "table" then

        return options
    end

    for key, def in pairs(quests.Holder) do
        if type(key) == "string"
            and type(def) == "table"
            and type(def.OfferNpc) == "string"
            and def.NoSave ~= true then

            local category

            if type(quests.GetQuestCategory) == "function" then
                pcall(function()
                    category =
                        quests.GetQuestCategory(key)
                end)
            end

            if category == "Combat" then
                local name =
                    def.QuestInstance
                    and def.QuestInstance.Name
                    or key

                local level =
                    self:QuestRequiredLevel(def)

                local npc =
                    tostring(def.OfferNpc or "?")

                table.insert(
                    options,
                    {
                        Value = key,
                        Label =
                            "Lv "
                            .. tostring(level)
                            .. " • "
                            .. tostring(name)
                            .. " • NPC: "
                            .. npc,
                        Level = level,
                        Name = tostring(name),
                        Npc = npc,
                    }
                )
            end
        end
    end

    table.sort(
        options,
        function(a, b)
            if a.Value == "" then
                return b.Value ~= ""
            end

            if b.Value == "" then
                return false
            end

            if a.Level ~= b.Level then
                return a.Level < b.Level
            end

            return a.Label < b.Label
        end
    )

    return options
end

function H:MobOptions()
    -- Refresh only when needed so opening/searching the dropdown doesn't spam a
    -- full mob scan every keystroke.
    if os.clock() - (self.Runtime.ManualMobOptionsRefreshAt or 0) > 0.6 then
        self.Runtime.ManualMobOptionsRefreshAt = os.clock()
        self:RefreshMobs()
    end

    local options = {
        {
            Value = "",
            Label = "None • choose a mob to farm",
        },
    }

    local seen = {}

    for _, name in ipairs(self.Data.MobNames or {}) do
        name = tostring(name or "")

        if name ~= ""
            and name ~= "Any"
            and not seen[name] then

            seen[name] = true

            table.insert(
                options,
                {
                    Value = name,
                    Label = name,
                }
            )
        end
    end

    table.sort(
        options,
        function(a, b)
            if a.Value == "" then
                return b.Value ~= ""
            end

            if b.Value == "" then
                return false
            end

            return string.lower(a.Label)
                < string.lower(b.Label)
        end
    )

    return options
end

function H:BossOptions()
    if os.clock() - (self.Runtime.ManualBossOptionsRefreshAt or 0) > 0.35 then
        self.Runtime.ManualBossOptionsRefreshAt = os.clock()
        self:RefreshBosses()
    end

    local options = {}
    local seen = {}

    for _, code in ipairs(self.Data.BossCodes or {}) do
        code = tostring(code or "")
        if code ~= "" and not seen[code] then
            seen[code] = true
            local rec = self.Data.Bosses[code]
            local title = rec and tostring(rec.Title or "") or ""
            local label = code

            if title ~= "" and title ~= code then
                label = code .. "  •  " .. title
            end

            table.insert(options, {Value = code, Label = label})
        end
    end

    table.sort(options, function(a,b)
        return string.lower(a.Label) < string.lower(b.Label)
    end)

    return options
end


function H:ChooseRecommendedQuest()
    local quests = self.Modules.Quests
    if type(quests) ~= "table" or type(quests.Holder) ~= "table"
        or type(quests.CanAddQuest) ~= "function" then return nil end
    local selected = tostring(self.State.SelectedQuest or "")
    local best
    for _, option in ipairs(self:QuestOptions()) do
        local key = option.Value
        if key ~= "" and (selected == "" or selected == key) then
            local def = quests.Holder[key]
            local can = false
            pcall(function() can = quests.CanAddQuest(self.Player,key) == true end)
            local retryAt = math.max((self.Runtime.QuestRetryUntil or {})[key] or 0,
                (self.Runtime.NpcRouteRetryUntil or {})[tostring(def.OfferNpc)] or 0)
            local recent = selected == "" and (
                self.Runtime.RecentCompletedQuestKey == key
                or (def.QuestInstance and self.Runtime.RecentCompletedQuestName == def.QuestInstance.Name))
                and os.clock() - (self.Runtime.RecentCompletedQuestAt or 0) < 45
            if can and self:IsQuestLevelAllowed(def,nil) and not recent and os.clock() >= retryAt then
                local level = self:QuestRequiredLevel(def)
                if not best or level > best.Level or (level == best.Level and key < best.Key) then
                    best = {Key=key,Name=def.QuestInstance and def.QuestInstance.Name or key,
                        Npc=def.OfferNpc,Level=level,Definition=def}
                end
            end
        end
    end
    self.Data.AutoQuest.Recommended = best
    return best
end

function H:NpcAnchorPart(model)
    if not model or not model:IsA("Model") or not model.Parent then
        return nil
    end

    local part =
        model:FindFirstChild(
            "HumanoidRootPart",
            true
        )
        or model.PrimaryPart
        or model:FindFirstChildWhichIsA(
            "BasePart",
            true
        )

    return part and part:IsA("BasePart") and part or nil
end

function H:FindNPC(name)
    if not name then return nil end
    self.Runtime.NpcLookup=self.Runtime.NpcLookup or {}
    local key=string.lower(tostring(name))
    local entry=self.Runtime.NpcLookup[key]
    if entry and os.clock()-entry.At<1.75 then
        if not entry.Model then return nil end
        if entry.Model.Parent and entry.Part and entry.Part.Parent then
            local root=self:Root()
            return entry.Model,root and (root.Position-entry.Part.Position).Magnitude or 0,entry.Part
        end
    end
    local model,dist,part=self:FindNPCUncached(name)
    self.Runtime.NpcLookup[key]={At=os.clock(),Model=model,Part=part}
    return model,dist,part
end

function H:FindNPCUncached(name)
    if not name then
        return nil
    end

    local wanted =
        string.lower(
            tostring(name)
        )

    local myRoot =
        self:Root()

    local best
    local bestPart
    local bestDist =
        math.huge

    local function consider(model, exactBonus)
        if not model
            or not model:IsA("Model") then

            return
        end

        local n =
            string.lower(
                tostring(model.Name)
            )

        local exact =
            n == wanted

        local loose =
            string.find(
                n,
                wanted,
                1,
                true
            )
            or string.find(
                wanted,
                n,
                1,
                true
            )

        if not exact
            and not loose then

            return
        end

        local part =
            self:NpcAnchorPart(
                model
            )

        if not part then
            return
        end

        local dist =
            myRoot
            and (
                myRoot.Position
                - part.Position
            ).Magnitude
            or 0

        -- Exact name wins over a fuzzy name even when the fuzzy model is a
        -- little closer.
        local scoreDist =
            dist
            - (
                exact
                and (
                    exactBonus
                    or 5000
                )
                or 0
            )

        if scoreDist
            < bestDist then

            best =
                model

            bestPart =
                part

            bestDist =
                scoreDist
        end
    end

    -- Stationary NPCs are the authoritative route for dialogue quests.
    local debree =
        self.S.Workspace:FindFirstChild(
            "Debree"
        )

    local regions =
        debree
        and debree:FindFirstChild(
            "Regions"
        )

    if regions then
        for _, region in ipairs(
            regions:GetChildren()
        ) do
            local stationary =
                region:FindFirstChild(
                    "StationaryNpcs"
                )

            if stationary then
                local exact =
                    stationary:FindFirstChild(
                        tostring(name)
                    )

                if exact
                    and exact:IsA("Model") then

                    local part =
                        self:NpcAnchorPart(
                            exact
                        )

                    if part then
                        local dist =
                            myRoot
                            and (
                                myRoot.Position
                                - part.Position
                            ).Magnitude
                            or 0

                        return exact, dist, part
                    end
                end

                for _, model in ipairs(
                    stationary:GetChildren()
                ) do
                    consider(
                        model,
                        10000
                    )
                end
            end
        end
    end

    for _,prompt in ipairs(self.S.CollectionService:GetTagged("Dialogue")) do
        if prompt:IsA("ProximityPrompt") and string.lower(prompt.Name)==wanted then
            local model=prompt:FindFirstAncestorOfClass("Model")
            local part=model and self:NpcAnchorPart(model)
            if part then return model,myRoot and (myRoot.Position-part.Position).Magnitude or 0,part end
        end
    end
    -- Do not scan every Workspace descendant here. Missing cross-region NPCs
    -- are resolved through StationaryNpcs/Dialogue tags after streaming. This
    -- prevents a missing quest NPC from causing a full-world scan every second.

    if best
        and bestPart then

        local trueDist =
            myRoot
            and (
                myRoot.Position
                - bestPart.Position
            ).Magnitude
            or 0

        return best, trueDist, bestPart
    end

    return nil
end

function H:FindNpcByChatPrompt(npcName)
    local wanted = string.lower(tostring(npcName or ""))
    if wanted == "" then return nil end

    self.Runtime.NpcPromptLookup = self.Runtime.NpcPromptLookup or {}
    local entry = self.Runtime.NpcPromptLookup[wanted]
    if entry and os.clock() - entry.At < 1.75 then
        if entry.Model and entry.Model.Parent and entry.Part and entry.Part.Parent then
            local root = self:Root()
            return entry.Model, root and (root.Position - entry.Part.Position).Magnitude or 0, entry.Part
        end
        return nil
    end

    local model, dist, part = self:FindNpcByChatPromptUncached(npcName)
    self.Runtime.NpcPromptLookup[wanted] = {At = os.clock(), Model = model, Part = part}
    return model, dist, part
end

function H:FindNpcByChatPromptUncached(npcName)
    local wanted = string.lower(tostring(npcName or ""))
    if wanted == "" then return nil end

    local root = self:Root()
    local bestModel, bestPart
    local bestDistance = math.huge

    local function consider(prompt)
        if not prompt or not prompt:IsA("ProximityPrompt") then return end

        local objectText = string.lower(tostring(prompt.ObjectText or ""))
        local actionText = string.lower(tostring(prompt.ActionText or ""))
        local promptName = string.lower(tostring(prompt.Name or ""))

        if objectText ~= wanted and promptName ~= wanted then return end
        if actionText ~= ""
            and actionText ~= "chat"
            and actionText ~= "talk"
            and actionText ~= "speak"
            and actionText ~= "interact" then
            return
        end

        local model = prompt:FindFirstAncestorOfClass("Model")
        if not model then return end

        local part = prompt.Parent
        if not (part and part:IsA("BasePart")) then
            part = self:NpcAnchorPart(model)
        end
        if not part then return end

        local distance = root and (root.Position - part.Position).Magnitude or 0
        if distance < bestDistance then
            bestDistance = distance
            bestModel = model
            bestPart = part
        end
    end

    -- The game's dialogue prompts are tagged Dialogue (confirmed by the scan),
    -- so this avoids Workspace:GetDescendants() while an unloaded NPC is missing.
    for _, prompt in ipairs(self.S.CollectionService:GetTagged("Dialogue")) do
        consider(prompt)
    end

    if bestModel and bestPart then
        return bestModel, bestDistance, bestPart
    end
    return nil
end

function H:InferNpcRegion(npcName)
    self.Runtime.NpcRegions=self.Runtime.NpcRegions or {}
    local key=tostring(npcName or "")
    if self.Runtime.NpcRegions[key] then return self.Runtime.NpcRegions[key] end
    local region=self:InferNpcRegionUncached(npcName)
    if region then self.Runtime.NpcRegions[key]=region end
    return region
end

function H:InferNpcRegionUncached(npcName)
    local wanted =
        tostring(
            npcName
            or ""
        )

    if wanted == "" then
        return nil
    end

    -- Scan-confirmed stationary NPC regions. These remain useful while the
    -- destination region is streamed out of Workspace.
    local knownRegions = {
        ["tom"] = "Bamboo Grove",
        ["chaka"] = "Bamboo Grove",
        ["wagwan"] = "Bamboo Grove",
        ["betty"] = "Bamboo Grove",
        ["noote"] = "Windy Peak",
    }
    local knownRegion = knownRegions[string.lower(wanted)]
    if knownRegion then return knownRegion end

    local ouwland =
        self.S.ReplicatedStorage
        :FindFirstChild(
            "Ouwland"
        )

    local content =
        ouwland
        and ouwland:FindFirstChild(
            "Content"
        )

    if not content then
        return nil
    end

    for _, region in ipairs(
        content:GetChildren()
    ) do
        local npcs =
            region:FindFirstChild(
                "Npcs"
            )

        if npcs
            and npcs:FindFirstChild(
                wanted,
                true
            ) then

            return region.Name
        end

        local npcContents =
            region:FindFirstChild(
                "NpcContents"
            )

        if npcContents then
            local dialogues =
                npcContents:FindFirstChild(
                    "Dialogues"
                )

            if dialogues then
                local quests =
                    dialogues:FindFirstChild(
                        "Quests"
                    )

                local yap =
                    dialogues:FindFirstChild(
                        "Yap"
                    )

                if (
                    quests
                    and quests:FindFirstChild(
                        wanted,
                        true
                    )
                )
                    or (
                        yap
                        and yap:FindFirstChild(
                            wanted,
                            true
                        )
                    ) then

                    return region.Name
                end
            end
        end
    end

    return nil
end

function H:RegionTravelAnchor(regionName)
    if not regionName then
        return nil, nil
    end

    -- Use scan-confirmed coordinates first. SpawnCrystal.Cube is scenery, not a
    -- combat/NPC model, and using it as the route anchor was what leaked a
    -- MeshPart into the combat/parry target path.
    local known =
        self.Data.KnownRegionAnchors
        and self.Data.KnownRegionAnchors[tostring(regionName)]

    if known then
        return nil, known
    end

    -- Generic fallback for regions without a scan-known coordinate. The part is
    -- returned only as a navigation anchor; callers must never make it a farm
    -- or combat target.
    local debree = self.S.Workspace:FindFirstChild("Debree")
    local regions = debree and debree:FindFirstChild("Regions")
    local region = regions and regions:FindFirstChild(tostring(regionName))

    if region then
        local crystal = region:FindFirstChild("SpawnCrystal", true)
        if crystal then
            local part = crystal:IsA("BasePart") and crystal
                or crystal:FindFirstChildWhichIsA("BasePart", true)
            if part then return part, part.Position end
        end
    end

    return nil, nil
end

function H:RequestStreamAt(position, timeoutSeconds, force)
    if typeof(position) ~= "Vector3" or self.State.Unloaded then return false end

    local r = self.Runtime
    local now = os.clock()
    local cooldown = force and 0 or 0.85

    if r.StreamBusy then
        return false
    end

    if not force and now - (r.LastStreamRequest or -10) < cooldown then
        return false
    end

    r.StreamBusy = true
    r.LastStreamRequest = now

    local ok = pcall(function()
        -- This call yields until Roblox has had a chance to stream around the
        -- requested point (or until the timeout expires). BUILD 12 uses it
        -- BEFORE each movement chunk instead of moving into an unloaded area.
        self.Player:RequestStreamAroundAsync(
            position,
            tonumber(timeoutSeconds) or 1.35
        )
    end)

    r.StreamBusy = false
    return ok
end

function H:ResetQuestTravelRoute()
    self.Runtime.QuestRouteKey = nil
    self.Runtime.QuestRouteFinal = nil
    self.Runtime.QuestChunkGoal = nil
    self.Runtime.QuestMoveSpeedCap = nil
end

function H:QuestGroundPoint(position, finalPosition, anchorInstance)
    if typeof(position) ~= "Vector3" then
        return nil
    end

    local root = self:Root()
    local hum = self:Humanoid()

    local topY = position.Y
    if root then topY = math.max(topY, root.Position.Y) end
    if typeof(finalPosition) == "Vector3" then topY = math.max(topY, finalPosition.Y) end
    topY += 180

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    local excluded = {}
    local character = self:Character()
    if character then table.insert(excluded, character) end
    if anchorInstance and typeof(anchorInstance) == "Instance" then
        local model = anchorInstance:IsA("Model") and anchorInstance
            or anchorInstance:FindFirstAncestorOfClass("Model")
        table.insert(excluded, model or anchorInstance)
    end

    params.FilterDescendantsInstances = excluded
    params.RespectCanCollide = true

    local hit = self.S.Workspace:Raycast(
        Vector3.new(position.X, topY, position.Z),
        Vector3.new(0, -720, 0),
        params
    )

    if not hit or hit.Normal.Y < 0.28 then
        return nil
    end

    local clearance = math.max(
        3.25,
        (hum and hum.HipHeight or 2)
            + (root and root.Size.Y * 0.5 or 1)
            + 0.35
    )

    return Vector3.new(
        position.X,
        hit.Position.Y + clearance,
        position.Z
    ), hit
end

function H:PrimeQuestTweenPoint(position, finalPosition, anchorInstance, label)
    local r = self.Runtime
    local key = string.format(
        "%s|%.1f|%.1f|%.1f",
        tostring(label or "quest"),
        position.X,
        position.Y,
        position.Z
    )

    -- Request the area BEFORE entering it.  RequestStreamAroundAsync returning
    -- successfully does not guarantee that usable terrain has actually parented
    -- into Workspace yet, so BUILD 18 also requires a real ground raycast.
    self:RequestStreamAt(position, 2.15, true)
    self.S.RunService.Heartbeat:Wait()
    task.wait(0.055)

    local safePoint = self:QuestGroundPoint(position, finalPosition, anchorInstance)
    if safePoint then
        r.QuestStreamWaitKey = nil
        r.QuestStreamWaitSince = nil
        return safePoint
    end

    if r.QuestStreamWaitKey ~= key then
        r.QuestStreamWaitKey = key
        r.QuestStreamWaitSince = os.clock()
    end

    self:StopMovement()
    self:SetStatus(
        "Smart Progression • streaming safe tween route • "
        .. tostring(label or "quest target")
    )

    return nil
end

function H:EmergencyQuestVoidRecovery(finalPosition, routeLabel)
    local root = self:Root()
    if not root or typeof(finalPosition) ~= "Vector3" then
        return false
    end

    local p = root.Position
    local distance = (finalPosition - p).Magnitude
    local impossible =
        distance > 5000
        or math.abs(p.X) > 12000
        or math.abs(p.Y) > 12000
        or math.abs(p.Z) > 12000

    if not impossible then
        return false
    end

    local r = self.Runtime
    if r.EmergencyQuestRecoveryBusy then
        return true
    end

    r.EmergencyQuestRecoveryBusy = true

    self:StopMovement()
    self:StopAttackHold()
    self:StopBlocking()

    local oldCharacter = self:Character()
    local oldSmart = self.State.SmartProgression
    local oldAutoQuest = self.State.AutoQuest
    local oldAutoAccept = self.State.AutoAccept
    local oldAutoFarm = self.State.AutoFarmMobs

    self:SetStatus(
        "Smart Progression • OFF-MAP • resetting character"
    )

    local function freshCharacter()
        local character = self.Player.Character
        if not character or character == oldCharacter then
            return nil
        end

        local newRoot = character:FindFirstChild("HumanoidRootPart")
        local hum = character:FindFirstChildOfClass("Humanoid")
        if newRoot and hum and hum.Health > 0 then
            return character, newRoot, hum
        end
        return nil
    end

    local function waitFresh(seconds)
        local started = os.clock()
        while not self.State.Unloaded and os.clock() - started < seconds do
            local c, rr, hh = freshCharacter()
            if c then
                return c, rr, hh
            end
            task.wait(0.10)
        end
        return nil
    end

    local function activateGuiButton(button)
        if not button then return false end

        if typeof(firesignal) == "function" then
            local ok = pcall(function()
                firesignal(button.MouseButton1Click)
            end)
            if ok then return true end
        end

        return pcall(function()
            button:Activate()
        end)
    end

    local function objectText(obj)
        local pieces = {}

        if obj:IsA("TextButton") or obj:IsA("TextLabel") then
            table.insert(pieces, tostring(obj.Text or ""))
        end

        for _, child in ipairs(obj:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                table.insert(pieces, tostring(child.Text or ""))
            end
        end

        return string.lower(table.concat(pieces, " "))
    end

    local function findVisibleCoreButton(words, reject)
        local core = self.S.CoreGui
        if not core then return nil end

        local best
        local bestScore = -math.huge

        for _, obj in ipairs(core:GetDescendants()) do
            if obj:IsA("GuiButton") then
                local visible = true
                pcall(function()
                    visible = obj.Visible
                end)

                if visible then
                    local txt = objectText(obj)
                    local score = 0

                    for _, word in ipairs(words) do
                        if string.find(txt, word, 1, true) then
                            score += 10
                        end
                    end

                    for _, word in ipairs(reject or {}) do
                        if string.find(txt, word, 1, true) then
                            score -= 40
                        end
                    end

                    if score > bestScore and score > 0 then
                        bestScore = score
                        best = obj
                    end
                end
            end
        end

        return best
    end

    local function tap(key)
        local vim = self.S.VirtualInputManager
        if not vim then return false end

        return pcall(function()
            vim:SendKeyEvent(true, key, false, game)
            task.wait(0.06)
            vim:SendKeyEvent(false, key, false, game)
        end)
    end

    -- Attempt 1: if the experience supplied a ResetButtonCallback BindableEvent,
    -- fire that exact callback.
    pcall(function()
        local starterGui = game:GetService("StarterGui")
        local callback = starterGui:GetCore("ResetButtonCallback")
        if typeof(callback) == "Instance" and callback:IsA("BindableEvent") then
            callback:Fire()
        end
    end)

    local newCharacter, newRoot = waitFresh(1.5)

    -- Attempt 2: open Roblox menu and press the actual visible Reset Character
    -- button/confirmation instead of assuming a particular keyboard timing.
    if not newCharacter then
        tap(Enum.KeyCode.Escape)
        task.wait(0.55)

        local resetButton =
            findVisibleCoreButton(
                {"reset character", "reset"},
                {"cancel"}
            )

        if resetButton then
            activateGuiButton(resetButton)
            task.wait(0.45)

            local confirm =
                findVisibleCoreButton(
                    {"reset"},
                    {"cancel"}
                )

            if confirm then
                activateGuiButton(confirm)
            end
        end

        newCharacter, newRoot = waitFresh(3.0)
    end

    -- Attempt 3: normal desktop Roblox shortcut, with enough delay for menu
    -- animations. BUILD 20 used timings that were too aggressive.
    if not newCharacter then
        tap(Enum.KeyCode.Escape)
        task.wait(0.65)
        tap(Enum.KeyCode.R)
        task.wait(0.55)
        tap(Enum.KeyCode.Return)

        newCharacter, newRoot = waitFresh(4.5)
    end

    -- Last local fallback. This may or may not be server-authoritative in a
    -- particular experience, but it is harmless if Roblox ignores it.
    if not newCharacter then
        local hum = self:Humanoid()

        pcall(function()
            if hum then
                hum.Health = 0
                hum:ChangeState(Enum.HumanoidStateType.Dead)
            end
        end)

        pcall(function()
            if oldCharacter and oldCharacter.Parent then
                oldCharacter:BreakJoints()
            end
        end)

        newCharacter, newRoot = waitFresh(3.5)
    end

    if newCharacter and newRoot then
        r.QuestRouteKey = nil
        r.QuestRouteFinal = nil
        r.QuestChunkGoal = nil
        r.QuestChunkRawGoal = nil
        r.QuestChunkStartedAt = nil
        r.QuestTransitStartedAt = nil
        r.ActiveTween = nil
        r.MoveGoal = nil
        r.MoveTarget = nil
        r.LastVerifiedGroundCFrame = nil
        r.QuestNoGroundSince = nil
        r.LastQuestLookAheadAt = 0

        -- Preserve what the user had enabled before the automatic reset.
        self.State.SmartProgression = oldSmart
        self.State.AutoQuest = oldAutoQuest
        self.State.AutoAccept = oldAutoAccept
        self.State.AutoFarmMobs = oldAutoFarm

        task.wait(0.55)

        task.spawn(function()
            if not self.State.Unloaded then
                self:RequestStreamAt(finalPosition, 1.8, false)
            end
        end)

        r.EmergencyQuestRecoveryBusy = false
        self:SetStatus(
            "Smart Progression • respawn complete • resuming tween"
        )
        return true
    end

    -- Never begin a million-stud tween if Roblox refuses all automated reset
    -- methods. Stop movement and tell the user exactly what action is required.
    self:StopMovement()
    self.State.SmartProgression = false
    self.State.AutoQuest = false
    self.State.AutoFarmMobs = false
    r.EmergencyQuestRecoveryBusy = false

    self:SetStatus(
        "OFF-MAP • Roblox blocked auto reset • ESC > R > ENTER once"
    )
    self:RefreshToggleButtons()

    return true
end

function H:QuestTravelStep(finalPosition, targetCF, targetInstance, routeLabel)
    local root = self:Root()
    if not root or typeof(finalPosition) ~= "Vector3" then
        return false
    end

    local r = self.Runtime
    local label = tostring(routeLabel or "quest target")
    local routeKey = string.format(
        "%s|%.1f|%.1f|%.1f",
        label,
        finalPosition.X,
        finalPosition.Y,
        finalPosition.Z
    )

    -- Recover impossible coordinates BEFORE calculating a multi-hour tween back.
    -- This is what the ~1,001,124-stud live status exposed.
    if self:EmergencyQuestVoidRecovery(finalPosition, label) then
        return true
    end

    -- BUILD 29 IMPORTANT:
    -- Cross-region tweening is expected to travel over empty space between map
    -- sections. BUILD 17 checked for ground BEFORE checking whether our tween was
    -- still running, so the very next quest tick cancelled a perfectly valid
    -- tween as soon as the character left an island. That is exactly what left
    -- the player suspended in the void.
    --
    -- Route changes are the only reason to cancel the existing quest tween.
    if r.QuestRouteKey ~= routeKey then
        self:StopMovement()
        r.QuestRouteKey = routeKey
        r.QuestRouteFinal = finalPosition
        r.QuestChunkGoal = nil
        r.QuestChunkRawGoal = nil
        r.QuestChunkStartedAt = nil
        r.QuestTransitStartedAt = os.clock()

        -- Start loading the actual destination immediately. Do not wait for this
        -- call before moving; the stream-ahead loop below keeps feeding Roblox
        -- points in front of the tween as it progresses.
        task.spawn(function()
            if not self.State.Unloaded then
                self:RequestStreamAt(finalPosition, 1.8, false)
            end
        end)
    end

    local remaining = (finalPosition - root.Position).Magnitude

    -- If a quest tween is already playing, LEAVE IT ALONE. In particular, do not
    -- ask whether there is ground below us: being over void is normal while
    -- travelling between separated regions.
    local activeTween = r.ActiveTween
    if activeTween and activeTween.PlaybackState == Enum.PlaybackState.Playing then
        local delta = finalPosition - root.Position
        local distance = delta.Magnitude

        if distance > 1 then
            local aheadDistance = math.min(190, distance)
            local ahead = root.Position + delta.Unit * aheadDistance

            if os.clock() - (r.LastQuestLookAheadAt or 0) >= 0.55 then
                r.LastQuestLookAheadAt = os.clock()
                task.spawn(function()
                    if not self.State.Unloaded then
                        self:RequestStreamAt(ahead, 1.25, false)
                    end
                end)
            end
        end

        self:SetStatus(
            "Smart Progression • tweening to "
            .. label
            .. " • "
            .. tostring(math.floor(remaining))
            .. " studs"
        )
        return true
    end

    -- Clear completed/cancelled tweens before choosing the next segment.
    if activeTween then
        r.ActiveTween = nil
    end

    -- Once the real NPC/model is streamed in, stop using scan/region waypoints
    -- and tween directly to its live position. QuestNpcStep will cancel this as
    -- soon as we enter the prompt radius, so we do not need to land exactly on it.
    local targetLoaded =
        targetInstance ~= nil
        and typeof(targetInstance) == "Instance"
        and targetInstance.Parent ~= nil

    if targetLoaded and remaining <= 220 then
        task.spawn(function()
            if not self.State.Unloaded then
                self:RequestStreamAt(finalPosition, 1.35, false)
            end
        end)

        r.QuestChunkGoal = finalPosition
        r.QuestChunkRawGoal = finalPosition
        r.QuestChunkStartedAt = os.clock()
        r.QuestMoveSpeedCap = 150
        local ok = self:MoveTo(finalPosition, targetCF, targetInstance)
        r.QuestMoveSpeedCap = nil

        self:SetStatus(
            "Smart Progression • direct tween to "
            .. label
            .. " • "
            .. tostring(math.floor(remaining))
            .. " studs"
        )
        return ok
    end

    if remaining <= 7 then
        -- We have reached the scan-known/region destination. Keep requesting the
        -- area until the live NPC appears; do not invent another ground route.
        task.spawn(function()
            if not self.State.Unloaded then
                self:RequestStreamAt(finalPosition, 1.8, false)
            end
        end)
        self:SetStatus("Smart Progression • loading " .. label .. " at destination")
        return true
    end

    -- Continuous air-corridor tweening. These are simply TweenService segments,
    -- not pathfinding and not walking. Intermediate points are deliberately NOT
    -- ground-gated because many regions are separated by genuine empty space.
    -- Streaming is requested ahead of each segment so Roblox has time to load the
    -- destination side before the character reaches it.
    local delta = finalPosition - root.Position
    local distance = delta.Magnitude
    if distance <= 0.01 then
        return true
    end

    local segmentDistance
    local speedCap

    if distance > 500 then
        segmentDistance = math.min(115, distance)
        speedCap = 125
    elseif distance > 220 then
        segmentDistance = math.min(105, distance)
        speedCap = 135
    else
        segmentDistance = distance
        speedCap = 150
    end

    local nextPoint = root.Position + delta.Unit * segmentDistance
    local lookDistance = math.min(segmentDistance + 115, distance)
    local lookAhead = root.Position + delta.Unit * lookDistance

    task.spawn(function()
        if not self.State.Unloaded then
            self:RequestStreamAt(lookAhead, 1.35, false)
        end
    end)

    r.QuestChunkRawGoal = nextPoint
    r.QuestChunkGoal = nextPoint
    r.QuestChunkStartedAt = os.clock()
    r.QuestMoveSpeedCap = speedCap
    local ok = self:MoveTo(nextPoint, nil, nil)
    r.QuestMoveSpeedCap = nil

    self:SetStatus(
        "Smart Progression • tweening to "
        .. label
        .. " • "
        .. tostring(math.floor(distance))
        .. " studs"
    )

    return ok
end

function H:FindNpcPrompt(npc, npcName)
    if not npc then
        return nil
    end

    local direct =
        npc:FindFirstChildWhichIsA(
            "ProximityPrompt",
            true
        )

    if direct then
        return direct
    end

    local anchor =
        self:NpcAnchorPart(
            npc
        )

    if not anchor then
        return nil
    end

    local wanted =
        string.lower(
            tostring(
                npcName
                or npc.Name
                or ""
            )
        )

    local best
    local bestScore =
        -math.huge

    for _, prompt in ipairs(
        self.S.Workspace:GetDescendants()
    ) do
        if prompt:IsA(
            "ProximityPrompt"
        ) then
            local holder =
                prompt.Parent

            local part =
                holder
                and (
                    holder:IsA("BasePart")
                    and holder
                    or holder:FindFirstChildWhichIsA(
                        "BasePart",
                        true
                    )
                )

            if not part then
                local ancestor =
                    prompt:FindFirstAncestorOfClass(
                        "Model"
                    )

                part =
                    ancestor
                    and self:NpcAnchorPart(
                        ancestor
                    )
            end

            if part then
                local dist =
                    (
                        part.Position
                        - anchor.Position
                    ).Magnitude

                if dist <= 18 then
                    local label =
                        string.lower(
                            tostring(
                                prompt.ObjectText
                                or ""
                            )
                            .. " "
                            .. tostring(
                                prompt.ActionText
                                or ""
                            )
                            .. " "
                            .. tostring(
                                prompt.Name
                                or ""
                            )
                        )

                    local score =
                        18 - dist

                    if wanted ~= ""
                        and string.find(
                            label,
                            wanted,
                            1,
                            true
                        ) then

                        score += 100
                    end

                    if string.find(
                        label,
                        "chat",
                        1,
                        true
                    )
                        or string.find(
                            label,
                            "talk",
                            1,
                            true
                        )
                        or string.find(
                            label,
                            "speak",
                            1,
                            true
                        )
                        or string.find(
                            label,
                            "interact",
                            1,
                            true
                        ) then

                        score += 35
                    end

                    if prompt:IsDescendantOf(
                        npc
                    ) then

                        score += 200
                    end

                    if score > bestScore then
                        bestScore =
                            score

                        best =
                            prompt
                    end
                end
            end
        end
    end

    return best
end

function H:PressNpcInteractKey(prompt)
    if self.S.UserInputService:GetFocusedTextBox() then
        self:SetStatus("Quest interaction paused • close the active text input")
        return false
    end
    local key =
        prompt
        and prompt.KeyboardKeyCode
        or Enum.KeyCode.T

    if key.Name == "Unknown" then
        key =
            Enum.KeyCode.T
    end

    return pcall(
        function()
            self.S.VirtualInputManager:SendKeyEvent(
                true,
                key,
                false,
                game
            )

            task.wait(math.clamp(prompt and prompt.HoldDuration or 0, 0, 3) + 0.06)

            self.S.VirtualInputManager:SendKeyEvent(
                false,
                key,
                false,
                game
            )
        end
    )
end


function H:IsActuallyVisible(obj)
    local cur = obj
    while cur and cur ~= self.PlayerGui do
        if cur:IsA("GuiObject") and not cur.Visible then return false end
        if cur:IsA("LayerCollector") and not cur.Enabled then return false end
        cur = cur.Parent
    end
    return cur == self.PlayerGui and obj.AbsoluteSize.X > 0 and obj.AbsoluteSize.Y > 0
end

function H:QuestDialogueLooksOpen(npcName)
    for _, obj in ipairs(self.PlayerGui:GetDescendants()) do
        if obj:IsA("GuiObject") and not self:IsOwnGuiObject(obj) and self:IsActuallyVisible(obj) then
            local path = string.lower(self:Path(obj))
            local dialogue = path:find("dialog",1,true) or path:find("conversation",1,true)
                or path:find("yap",1,true)
            if dialogue and (obj:IsA("GuiButton")
                or (obj:IsA("TextLabel") and obj.Text ~= "")) then return true end
        end
    end
    return false
end

function H:ClickGuiObjectAt(obj)
    if not obj
        or self:IsOwnGuiObject(obj) then

        return false
    end

    local ok =
        pcall(
            function()
                local p = obj.AbsolutePosition
                local s = obj.AbsoluteSize

                local x =
                    p.X + math.max(1, s.X / 2)

                local y =
                    p.Y + math.max(1, s.Y / 2)

                self.S.VirtualInputManager:SendMouseButtonEvent(
                    x,
                    y,
                    0,
                    true,
                    game,
                    0
                )

                task.wait(0.025)

                self.S.VirtualInputManager:SendMouseButtonEvent(
                    x,
                    y,
                    0,
                    false,
                    game,
                    0
                )
            end
        )

    return ok
end

function H:AdvanceQuestDialogue(quest, mode)
    if self.S.UserInputService:GetFocusedTextBox() then return false end
    if not self:QuestDialogueLooksOpen(nil) then return false end
    if os.clock() - self.Runtime.LastDialogueAdvance < 0.16 then
        return false
    end

    self.Runtime.LastDialogueAdvance = os.clock()
    self.Runtime.DialogueAdvanceAttempts += 1

    -- First try the semantic Accept / Continue / Complete button logic.
    if self:ClickQuestDialogueButton(
        quest,
        mode
    ) then
        return true
    end

    local bestButton
    local bestScore = -1

    -- Some dialogue pages only show a down-arrow / next control with no text.
    -- Find any visible dialogue-related GuiButton OUTSIDE ThumbsHub.
    for _, obj in ipairs(self.PlayerGui:GetDescendants()) do
        if obj:IsA("GuiButton")
            and self:IsActuallyVisible(obj)
            and obj.Active
            and not self:IsOwnGuiObject(obj) then

            local path =
                string.lower(self:Path(obj))

            local name =
                string.lower(
                    tostring(obj.Name or "")
                )

            local score = 0

            if string.find(path, "dialog", 1, true)
                or string.find(path, "dialogue", 1, true)
                or string.find(path, "conversation", 1, true)
                or string.find(path, "yap", 1, true) then

                score += 10
            end

            if string.find(name, "next", 1, true)
                or string.find(name, "arrow", 1, true)
                or string.find(name, "continue", 1, true)
                or string.find(name, "advance", 1, true) then

                score += 12
            end

            if score > bestScore then
                bestScore = score
                bestButton = obj
            end
        end
    end

    if bestButton and bestScore > 0 then
        local ok =
            pcall(
                function()
                    bestButton:Activate()
                end
            )

        if ok then
            return true
        end

        if typeof(firesignal) == "function" then
            ok =
                pcall(
                    firesignal,
                    bestButton.MouseButton1Click
                )

            if ok then
                return true
            end
        end

        if self:ClickGuiObjectAt(bestButton) then
            return true
        end
    end

    -- The screenshoted dialogue uses a visible down-arrow style advance
    -- control. It may be an ImageLabel rather than a GuiButton. Click the
    -- centre of a visible arrow/next GUI object if one exists.
    local bestArrow
    local arrowScore = -1

    for _, obj in ipairs(self.PlayerGui:GetDescendants()) do
        if obj:IsA("GuiObject")
            and self:IsActuallyVisible(obj)
            and not self:IsOwnGuiObject(obj) then

            local path =
                string.lower(self:Path(obj))

            local name =
                string.lower(
                    tostring(obj.Name or "")
                )

            local score = 0

            if string.find(name, "arrow", 1, true)
                or string.find(name, "next", 1, true)
                or string.find(name, "continue", 1, true) then

                score += 15
            end

            if string.find(path, "dialog", 1, true)
                or string.find(path, "dialogue", 1, true)
                or string.find(path, "conversation", 1, true) then

                score += 8
            end

            if score > arrowScore then
                arrowScore = score
                bestArrow = obj
            end
        end
    end

    if bestArrow
        and arrowScore >= 15
        and self:ClickGuiObjectAt(bestArrow) then

        return true
    end

    -- BUILD 76:
    -- Some dialogue systems use a plain ImageLabel for the down-arrow and give
    -- it an unhelpful generated name. Find a small visible object inside a
    -- dialogue/conversation tree near the lower half of the screen and click
    -- its centre. This handles the story-page arrow shown by Tom without
    -- hardcoding Tom or any one quest.
    local viewport =
        self.S.Workspace.CurrentCamera
        and self.S.Workspace.CurrentCamera.ViewportSize
        or Vector2.new(1920, 1080)

    local geometryArrow
    local geometryScore =
        -math.huge

    for _, obj in ipairs(
        self.PlayerGui:GetDescendants()
    ) do
        if obj:IsA("GuiObject")
            and self:IsActuallyVisible(obj)
            and not self:IsOwnGuiObject(obj) then

            local path =
                string.lower(
                    self:Path(obj)
                )

            local inDialogue =
                string.find(path, "dialog", 1, true)
                or string.find(path, "dialogue", 1, true)
                or string.find(path, "conversation", 1, true)
                or string.find(path, "yap", 1, true)

            if inDialogue then
                local size =
                    obj.AbsoluteSize

                local pos =
                    obj.AbsolutePosition

                local area =
                    math.max(
                        1,
                        size.X * size.Y
                    )

                local score = 0

                if area <= 16000 then
                    score += 12
                end

                if size.X >= 12
                    and size.Y >= 8
                    and size.X <= 180
                    and size.Y <= 120 then

                    score += 10
                end

                if pos.Y + size.Y * 0.5
                    >= viewport.Y * 0.52 then

                    score += 8
                end

                local name =
                    string.lower(
                        tostring(
                            obj.Name
                            or ""
                        )
                    )

                if string.find(name, "arrow", 1, true)
                    or string.find(name, "next", 1, true)
                    or string.find(name, "continue", 1, true)
                    or string.find(name, "advance", 1, true) then

                    score += 25
                end

                if score > geometryScore then
                    geometryScore =
                        score

                    geometryArrow =
                        obj
                end
            end
        end
    end

    if geometryArrow
        and geometryScore >= 20 then

        if self:ClickGuiObjectAt(
            geometryArrow
        ) then

            return true
        end
    end

    -- One more fallback for dialogue boxes where the whole panel receives the
    -- click instead of the arrow object: click the lower-centre region of the
    -- largest visible dialogue container.
    local dialoguePanel
    local dialogueArea = 0

    for _, obj in ipairs(
        self.PlayerGui:GetDescendants()
    ) do
        if obj:IsA("GuiObject")
            and self:IsActuallyVisible(obj)
            and not self:IsOwnGuiObject(obj) then

            local path =
                string.lower(
                    self:Path(obj)
                )

            if string.find(path, "dialog", 1, true)
                or string.find(path, "dialogue", 1, true)
                or string.find(path, "conversation", 1, true)
                or string.find(path, "yap", 1, true) then

                local size =
                    obj.AbsoluteSize

                local area =
                    size.X * size.Y

                if area > dialogueArea
                    and size.X >= 180
                    and size.Y >= 80 then

                    dialogueArea =
                        area

                    dialoguePanel =
                        obj
                end
            end
        end
    end

    if dialoguePanel then
        local pos =
            dialoguePanel.AbsolutePosition

        local size =
            dialoguePanel.AbsoluteSize

        local clickX =
            math.floor(
                pos.X
                + size.X * 0.5
            )

        local clickY =
            math.floor(
                pos.Y
                + size.Y * 0.82
            )

        local clicked =
            pcall(
                function()
                    self.S.VirtualInputManager:SendMouseButtonEvent(
                        clickX,
                        clickY,
                        0,
                        true,
                        game,
                        0
                    )

                    task.wait(
                        0.025
                    )

                    self.S.VirtualInputManager:SendMouseButtonEvent(
                        clickX,
                        clickY,
                        0,
                        false,
                        game,
                        0
                    )
                end
            )

        if clicked then
            return true
        end
    end

    -- Final compatibility fallback: dialogue systems commonly advance on
    -- Space / Return / E. Rotate through them instead of hammering one input.
    local keys = {
        Enum.KeyCode.Space,
        Enum.KeyCode.Return,
        Enum.KeyCode.E,
    }

    local key =
        keys[
            (
                (
                    self.Runtime.DialogueAdvanceAttempts
                    - 1
                )
                % #keys
            )
            + 1
        ]

    local ok =
        pcall(
            function()
                self.S.VirtualInputManager:SendKeyEvent(
                    true,
                    key,
                    false,
                    game
                )

                task.wait(0.025)

                self.S.VirtualInputManager:SendKeyEvent(
                    false,
                    key,
                    false,
                    game
                )
            end
        )

    return ok
end

function H:ResetDialogueSession()
    self.Runtime.DialogueNpc = nil
    self.Runtime.DialogueMode = nil
    self.Runtime.DialogueQuestKey = nil
    self.Runtime.DialogueSessionUntil = 0
    self.Runtime.DialogueStartedAt = 0
    self.Runtime.DialogueAdvanceAttempts = 0
end

function H:ClickQuestDialogueButton(quest, mode)
    if os.clock() - self.Runtime.LastQuestClick < 0.55 then
        return false
    end

    local key = string.lower(tostring(quest and quest.Key or ""))
    local name = string.lower(tostring(quest and quest.Name or ""))
    local modeName = tostring(mode or "accept")

    local words

    if modeName == "turnin" then
        words = {
            "complete", "claim", "finish", "done", "turn in",
            "turnin", "continue", "yes", "okay", "ok"
        }
    elseif modeName == "progress" then
        words = {
            "continue", "next", "speak", "talk", "report",
            "yes", "okay", "ok"
        }
    else
        words = {
            "accept", "take", "start", "begin", "quest",
            "yes", "continue", "okay", "ok"
        }
    end

    local function buttonText(obj)
        local parts = {tostring(obj.Name or "")}

        if obj:IsA("TextButton") then
            table.insert(parts, tostring(obj.Text or ""))
        end

        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                local t = tostring(d.Text or "")
                if t ~= "" then
                    table.insert(parts, t)
                end
            end
        end

        return string.lower(table.concat(parts, " "))
    end

    local best
    local bestScore = -1

    for _, obj in ipairs(self.PlayerGui:GetDescendants()) do
        if obj:IsA("GuiButton")
            and self:IsActuallyVisible(obj)
            and obj.Active then

            local path = string.lower(self:Path(obj))
            local txt = buttonText(obj)
            local score = 0

            if string.find(path, "dialog", 1, true)
                or string.find(path, "quest", 1, true)
                or string.find(path, "prompt", 1, true) then
                score += 4
            end

            for _, word in ipairs(words) do
                if string.find(txt, word, 1, true) then
                    score += 5
                    break
                end
            end

            if key ~= "" and string.find(txt, key, 1, true) then
                score += 2
            end

            if name ~= "" and string.find(txt, name, 1, true) then
                score += 2
            end

            if score > bestScore then
                bestScore = score
                best = obj
            end
        end
    end

    if not best or bestScore <= 0 then
        return false
    end

    self.Runtime.LastQuestClick = os.clock()

    local ok = pcall(function()
        best:Activate()
    end)

    if (not ok) and typeof(firesignal) == "function" then
        pcall(firesignal, best.MouseButton1Click)
    end

    return true
end

function H:ClickQuestAcceptButton(quest)
    if not self.State.AutoAccept
        and not self.State.SmartProgression then
        return false
    end

    return self:ClickQuestDialogueButton(quest, "accept")
end

function H:GroundBelow(position, depth)
    if typeof(position) ~= "Vector3" then return nil end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local character = self:Character()
    params.FilterDescendantsInstances = character and {character} or {}
    params.RespectCanCollide = true

    return self.S.Workspace:Raycast(
        position + Vector3.new(0, 3, 0),
        Vector3.new(0, -(tonumber(depth) or 24), 0),
        params
    )
end

function H:UpdateVerifiedGround()
    local now = os.clock()
    if now - (self.Runtime.LastGroundSampleAt or 0) < 0.25 then return end
    self.Runtime.LastGroundSampleAt = now

    local root = self:Root()
    if not root then return end

    local hit = self:GroundBelow(root.Position, 18)
    if hit and hit.Normal.Y >= 0.45 then
        self.Runtime.LastVerifiedGroundCFrame = root.CFrame
        self.Runtime.LastVerifiedGroundAt = now
        self.Runtime.QuestNoGroundSince = nil
    end
end

function H:RecoverQuestVoid()
    local root = self:Root()
    if not root then return false end

    local currentGround = self:GroundBelow(root.Position, 30)
    if currentGround and currentGround.Normal.Y >= 0.35 then
        self.Runtime.QuestNoGroundSince = nil
        return false
    end

    local now = os.clock()
    self.Runtime.QuestNoGroundSince = self.Runtime.QuestNoGroundSince or now
    if now - self.Runtime.QuestNoGroundSince < 1.20 then return false end

    local safe = self.Runtime.LastVerifiedGroundCFrame
    if not safe then return false end

    self:StopMovement()
    self:StopAttackHold()
    self:StopBlocking()
    root.CFrame = safe
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    self.Runtime.QuestNoGroundSince = nil
    self:SetStatus("Smart Progression • recovered to last safe ground")
    return true
end

function H:VerifiedQuestDestination(position, anchor, npcName)
    if not position then return nil end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excluded = {}
    local character = self:Character()
    if character then table.insert(excluded, character) end
    if anchor then
        local model = anchor:FindFirstAncestorOfClass("Model")
        table.insert(excluded, model or anchor)
    end
    params.FilterDescendantsInstances = excluded
    params.RespectCanCollide = true

    local hit = self.S.Workspace:Raycast(
        position + Vector3.new(0, 140, 0),
        Vector3.new(0, -360, 0),
        params
    )

    if hit and hit.Normal.Y >= 0.45 then
        self.Runtime.NpcRouteFailures = self.Runtime.NpcRouteFailures or {}
        self.Runtime.NpcRouteFailures[tostring(npcName)] = nil
        self.Runtime.QuestNoGroundSince = nil

        local hum = self:Humanoid()
        local root = self:Root()
        local height = math.max(3, (hum and hum.HipHeight or 0) + (root and root.Size.Y / 2 or 1))
        return hit.Position + Vector3.new(0, height, 0)
    end

    -- Do not move into an unloaded void and do not blacklist the quest for 60s.
    -- Keep requesting the destination region and retry on the next farm tick.
    self:StopMovement()
    self:StopAttackHold()
    self:StopBlocking()
    self.Data.CurrentFarmTarget = nil
    self:RecoverQuestVoid()

    local key = tostring(npcName)
    self.Runtime.NpcRouteFailures = self.Runtime.NpcRouteFailures or {}
    self.Runtime.NpcRouteFailures[key] = self.Runtime.NpcRouteFailures[key] or os.clock()
    self:SetStatus("Smart Progression • loading safe route • " .. key)
    return nil
end

function H:QuestNpcStep(quest, npcName, mode)
    if not npcName then
        return false
    end

    local now =
        os.clock()

    -- BUILD 29 HARD GUARD:
    -- Check impossible coordinates BEFORE FindNPC/FindNpcByChatPrompt. Streaming
    -- can keep Tom's model alive even while the player is a million studs away;
    -- if we wait until the fallback branch, that live model bypasses recovery.
    do
        local myRoot = self:Root()
        if myRoot then
            local p = myRoot.Position
            local offMap =
                math.abs(p.X) > 12000
                or math.abs(p.Y) > 12000
                or math.abs(p.Z) > 12000

            if offMap then
                local known =
                    self.Data.KnownNpcLocations
                    and self.Data.KnownNpcLocations[string.lower(tostring(npcName))]

                local recoveryTarget =
                    known
                    and known.Position
                    or self.Data.KnownRegionAnchors["Bamboo Grove"]

                if recoveryTarget then
                    self:EmergencyQuestVoidRecovery(
                        recoveryTarget,
                        npcName
                    )
                    return true
                end
            end
        end
    end

    local questKey =
        tostring(
            quest
            and (
                quest.Key
                or quest.Name
            )
            or ""
        )

    local sameSession =
        self.Runtime.DialogueNpc
            == tostring(npcName)
        and self.Runtime.DialogueMode
            == tostring(
                mode
                or "accept"
            )
        and self.Runtime.DialogueQuestKey
            == questKey
        and now
            < self.Runtime.DialogueSessionUntil

    if sameSession and not self:QuestDialogueLooksOpen(npcName) then
        if now - self.Runtime.DialogueStartedAt < 1.25 then return true end
        self:ResetDialogueSession()
        sameSession = false
    end

    if sameSession then
        self:StopMovement()
        self:SetStatus("Quest dialogue • "..tostring(npcName).." • "..tostring(mode))

        self:AdvanceQuestDialogue(
            quest,
            mode
        )

        if now
            - self.Runtime.DialogueStartedAt
            > 9.5 then

            self:ResetDialogueSession()
        end

        return true
    end

    local npc, dist, anchor =
        self:FindNPC(
            npcName
        )

    if not npc then
        npc, dist, anchor =
            self:FindNpcByChatPrompt(
                npcName
            )
    end

    if not npc then
        -- First use an exact scan-known NPC coordinate when one exists.
        local known =
            self.Data.KnownNpcLocations[
                string.lower(
                    tostring(npcName)
                )
            ]

        if known
            and known.Position then

            self.Data.CurrentFarmTarget = nil
            self.Runtime.AttackTarget = nil
            self:StopAttackHold()
            self:StopBlocking()

            self.Data.CurrentFarmQuery = npcName
            self.Data.CurrentFarmRegion = known.Region

            local myRoot = self:Root()
            local distance = myRoot and (myRoot.Position - known.Position).Magnitude or math.huge
            if distance <= 10 then
                self:StopMovement()
                self:ResetQuestTravelRoute()
                self:RequestStreamAt(known.Position, 1.6, false)
                self:SetStatus("Smart Progression • loading " .. tostring(npcName) .. " • " .. tostring(known.Region or "scanned route"))
                return true
            end

            self:QuestTravelStep(known.Position, nil, nil, npcName)
            return true
        end

        -- Generic cross-region progression:
        -- infer which Content region owns this NPC, move to that region's
        -- SpawnCrystal, then the next progression tick resolves the now-
        -- streamed StationaryNpc and opens its Chat prompt.
        local targetRegion =
            self:InferNpcRegion(
                npcName
            )

        local regionAnchor, regionPosition =
            self:RegionTravelAnchor(
                targetRegion
            )

        if regionPosition then
            -- Navigation and combat targets are deliberately separate. A
            -- SpawnCrystal/BasePart must never enter the parry target pipeline.
            self.Data.CurrentFarmTarget = nil
            self.Runtime.AttackTarget = nil
            self:StopAttackHold()
            self:StopBlocking()

            self.Data.CurrentFarmQuery = npcName
            self.Data.CurrentFarmRegion = targetRegion
            self.Runtime.QuestTravelAnchor = regionAnchor
            self.Runtime.QuestTravelPosition = regionPosition

            local myRoot = self:Root()
            local distance = myRoot and (myRoot.Position - regionPosition).Magnitude or math.huge
            if distance <= 10 then
                self:StopMovement()
                self:ResetQuestTravelRoute()
                self:RequestStreamAt(regionPosition, 1.6, false)
                self:SetStatus("Smart Progression • loading " .. tostring(npcName) .. " • " .. tostring(targetRegion))
                return true
            end

            self:QuestTravelStep(regionPosition, nil, nil, npcName)
            return true
        end

        self:StopMovement()
        self.Data.CurrentFarmTarget=nil
        self:SetStatus(
            "Smart Progression • waiting for verified route • NPC="
            .. tostring(npcName)
            .. " • inferred region="
            .. tostring(targetRegion)
        )

        return false
    end

    anchor =
        anchor
        or self:NpcAnchorPart(
            npc
        )

    if not anchor then
        return false
    end

    local prompt =
        self:FindNpcPrompt(
            npc,
            npcName
        )

    local promptDistance = prompt and math.max(1, (tonumber(prompt.MaxActivationDistance) or 8) - 1) or 5

    if dist
        and dist <= promptDistance then

        self:StopMovement()

        if now
            - self.Runtime.LastQuestAction
            > 0.85 then

            self.Runtime.LastQuestAction =
                now

            local opened = false

            if prompt then
                opened =
                    self:InteractPrompt(
                        prompt
                    )
            end

            -- Stationary NPC chat prompts sometimes use a helper prompt or
            -- executor fireproximityprompt can return success without opening
            -- the dialogue. Press the prompt's real key as a normal fallback.
            if not opened
                or not self:QuestDialogueLooksOpen(
                    npcName
                ) then

                self:PressNpcInteractKey(
                    prompt
                )
            end

            self.Runtime.DialogueNpc =
                tostring(npcName)

            self.Runtime.DialogueMode =
                tostring(
                    mode
                    or "accept"
                )

            self.Runtime.DialogueQuestKey =
                questKey

            self.Runtime.DialogueStartedAt =
                now

            self.Runtime.DialogueSessionUntil =
                now + 10

            self.Runtime.DialogueAdvanceAttempts =
                0
        end

        if self:QuestDialogueLooksOpen(npcName) then
            self:AdvanceQuestDialogue(quest, mode)
        end

        self:SetStatus(
            "Auto Quest • interacting with "
            .. tostring(npcName)
        )

        return true
    end

    self:ResetDialogueSession()

    self:QuestTravelStep(
        anchor.Position,
        anchor.CFrame,
        npc,
        npcName
    )

    -- QuestTravelStep owns the status text. Do not overwrite emergency recovery,
    -- streaming or direct-tween diagnostics with a stale distance.
    return true
end

function H:KnownProgressionFallback()
    -- BUILD 29 recovery path for the early Bamboo Grove progression chain.
    -- The full game scan confirmed Tom owns the repeatable combat quest
    -- "Hunt the Bears" (BearCub x4).  Use this only when there is NO active
    -- quest and the generic recommender cannot supply a route.
    if self:GetActiveQuest() then
        return nil
    end

    local level = tonumber(self:GetPlayerLevel()) or 0
    if level < 10 or level >= 20 then
        return nil
    end

    local quests = self.Modules.Quests
    if type(quests) == "table" and type(quests.Holder) == "table" then
        local bestKey, bestDef

        for key, def in pairs(quests.Holder) do
            if type(key) == "string" and type(def) == "table" then
                local questName = def.QuestInstance and tostring(def.QuestInstance.Name) or ""
                local offerNpc = tostring(def.OfferNpc or "")

                if questName == "Hunt the Bears" or
                    (string.lower(offerNpc) == "tom" and self:NormalizeMobText(questName) == "huntthebears") then
                    bestKey, bestDef = key, def
                    break
                end
            end
        end

        if bestKey and bestDef then
            local allowed = self:IsQuestLevelAllowed(bestDef, nil)
            local can = true

            if type(quests.CanAddQuest) == "function" then
                local okCan, result = pcall(quests.CanAddQuest, self.Player, bestKey)
                -- Only trust an explicit successful result. If the capability
                -- call itself errors, still allow the dialogue route to recover.
                if okCan then
                    can = result == true
                end
            end

            if allowed and can then
                return {
                    Key = bestKey,
                    Name = "Hunt the Bears",
                    Npc = tostring(bestDef.OfferNpc or "Tom"),
                    Level = self:QuestRequiredLevel(bestDef),
                    Definition = bestDef,
                    KnownFallback = true,
                }
            end
        end
    end

    -- Last-resort route: Tom is a live, scan-confirmed quest NPC.  The normal
    -- dialogue selector will prefer Accept/Continue controls and the next tick
    -- verifies success from the replicated quest Holder before farming anything.
    local tom = self:FindNPC("Tom")
    if tom then
        return {
            Key = "Hunt the Bears",
            Name = "Hunt the Bears",
            Npc = "Tom",
            Level = 10,
            KnownFallback = true,
        }
    end

    return nil
end

function H:QuestStep()
    -- Smart Progression is the one-switch progression controller. It always
    -- keeps the supporting quest/farm toggles on so the UI and runtime state
    -- cannot drift apart.
    if self.State.SmartProgression then
        self.State.AutoQuest = true
        self.State.AutoAccept = true
        self.State.AutoFarmMobs = true
        self.State.AutoEquipCombat = true
        self.State.AutoParry = true
        self.State.PerfectBlock = true
        self.State.PingAwareParry = true
        self.State.BossSafetyMode = true
        self.State.SafeCombat = true
        self.State.MovementType = "Tween"
        if os.clock()-(self.Runtime.LastProgressToggleRefresh or 0)>1 then
            self.Runtime.LastProgressToggleRefresh=os.clock()
            self:RefreshToggleButtons()
        end
    end

    if not self.State.AutoQuest then
        self.Data.AutoQuest.Active = nil
        self.Data.AutoQuest.Stage = "idle"

        self:SafeText(
            self.UI.QuestInfo,
            " Auto Quest • OFF"
        )

        return nil
    end

    local active = self:GetActiveQuest()
    self.Data.AutoQuest.Active = active
    self:RememberActiveQuest(active)

    if active then
        self.Runtime.AcceptAttempt = nil
        self:ClearPendingQuestHandoff()
        local def, holderKey =
            self:QuestDefinition(
                active.Key,
                active.Name
            )

        local requiredLevel =
            self:QuestRequiredLevelFromActive(
                active,
                def
            )

        local levelAllowed,
            currentLevel =
            self:IsQuestLevelAllowed(
                def,
                active
            )

        if active.Task
            and not levelAllowed then

            if self.Data.AutoQuest.Stage ~= "level" then
                self:StopAttackHold()
                self:StopBlocking()
                self.Data.CurrentFarmTarget = nil
            end
            self.Data.AutoQuest.Stage = "level"
            self:ResetDialogueSession()

            self:SafeText(
                self.UI.QuestInfo,
                " Smart Progression • LEVEL GATE"
                .. "\n Current Lv • "
                .. tostring(
                    currentLevel
                    or "?"
                )
                .. "\n Quest requires • Lv "
                .. tostring(
                    requiredLevel
                )
                .. "\n Temporarily farming safe mobs until unlocked"
            )

            return {
                Mode = "levelgrind",
                Quest = active,
                Definition = def,
                RequiredLevel = requiredLevel,
                CurrentLevel = currentLevel,
            }
        end

        if active.Task then
            local interactionNpc =
                self:QuestInteractionNpc(
                    active,
                    def
                )

            -- Dialogue / report / meet objectives are NOT mob objectives.
            -- Route directly to the named NPC and progress the conversation.
            if interactionNpc then
                self.Data.AutoQuest.Stage =
                    "interact"

                self:StopAttackHold()
                self:StopBlocking()

                local npc, _npcDistance =
                    self:FindNPC(
                        interactionNpc
                    )

                if npc then
                    self.Data.CurrentFarmTarget =
                        npc

                    self.Data.CurrentFarmQuery =
                        interactionNpc

                    self.Data.CurrentFarmRegion =
                        self:ModelRegion(npc)
                else
                    self.Data.CurrentFarmTarget =
                        nil

                    self.Data.CurrentFarmQuery =
                        interactionNpc
                end

                self:SafeText(
                    self.UI.QuestInfo,
                    " Smart Progression • INTERACT"
                    .. "\n Quest • "
                    .. tostring(active.Name)
                    .. "\n Task • "
                    .. tostring(active.Task)
                    .. "\n Objective • NPC interaction"
                    .. "\n NPC • "
                    .. tostring(interactionNpc)
                    .. (
                        self:QuestProgressText(active) ~= ""
                        and (
                            " • "
                            .. self:QuestProgressText(active)
                        )
                        or ""
                    )
                )

                local routed =
                    self:QuestNpcStep(
                        {
                            Key =
                                holderKey
                                or active.Key,
                            Name =
                                active.Name,
                        },
                        interactionNpc,
                        "progress"
                    )

                if not routed then
                    self:SetStatus(
                        "Smart Progression • unable to route objective → "
                        .. tostring(interactionNpc)
                    )
                end

                return {
                    Mode = "interact",
                    Npc = interactionNpc,
                    Quest = active,
                    Definition = def,
                    HolderKey = holderKey,
                }
            end

            -- Otherwise this is a combat-style task.
            self:ResetDialogueSession()
            self.Runtime.LastQuestClick = 0
            self.Runtime.LastQuestAction = 0
            self.Data.AutoQuest.Stage = "farm"

            self:SafeText(
                self.UI.QuestInfo,
                " Smart Progression • FARMING"
                .. "\n Quest • "
                .. tostring(active.Name)
                .. "\n Task • "
                .. tostring(active.Task)
                .. (
                    active.Code
                    and (" • Code: " .. tostring(active.Code))
                    or ""
                )
                .. (
                    self:QuestProgressText(active) ~= ""
                    and (" • " .. self:QuestProgressText(active))
                    or ""
                )
                .. (
                    requiredLevel > 0
                    and (" • Req Lv " .. tostring(requiredLevel))
                    or ""
                )
            )

            return {
                Mode = "combat",
                Query = active.Code or active.Task,
                Quest = active,
                Definition = def,
                HolderKey = holderKey,
            }
        end

        -- All visible tasks are complete. Return to the quest's offer NPC so
        -- the normal dialogue can finish/claim it. Once the server removes it
        -- from Holder, the next loop picks the highest newly-eligible quest.
        self.Data.AutoQuest.Stage = "turnin"

        local handoffNpc, handoffReason =
            self:QuestCompletionHandoffNpc(
                def
            )

        if handoffNpc then
            self:SetPendingQuestHandoff(
                handoffNpc,
                handoffReason,
                60
            )
        end

        local npcName =
            handoffNpc
            or (
                def
                and typeof(def.OfferNpc) == "string"
                and def.OfferNpc
                or nil
            )

        self:SafeText(
            self.UI.QuestInfo,
            " Smart Progression • TURN IN"
            .. "\n Quest • "
            .. tostring(active.Name)
            .. "\n NPC • "
            .. tostring(npcName or "unknown")
        )

        if npcName then
            self:QuestNpcStep(
                {
                    Key = holderKey or active.Key,
                    Name = active.Name,
                },
                npcName,
                "turnin"
            )
        else
            self:SetStatus(
                "Auto Quest • completed task, turn-in NPC unknown"
            )
        end

        return {
            Mode = "turnin",
            Quest = active,
            Definition = def,
        }
    end

    -- No active Holder quest does not always mean "pick another combat quest".
    -- Some chains hand the player an item/dialogue instruction and expect the
    -- next NPC to be visited first.
    local handoffNpc, handoffReason
    if tostring(self.State.SelectedQuest or "") == "" then
        handoffNpc, handoffReason = self:ResolveQuestHandoff()
    end

    if handoffNpc then
        self.Data.AutoQuest.Stage =
            "handoff"

        self:StopAttackHold()
        self:StopBlocking()

        -- Kazu can still be talking when the old Holder quest disappears.
        -- Finish/advance that dialogue first, then travel to Noote on the next
        -- tick instead of reopening Clear the Village Spies.
        if self:QuestDialogueLooksOpen(
            nil
        ) then

            self:AdvanceQuestDialogue(
                {
                    Key = "QuestHandoff",
                    Name = "Quest Handoff",
                },
                "progress"
            )

            self:SetPendingQuestHandoff(
                handoffNpc,
                handoffReason,
                60
            )

            self:SetStatus(
                "Smart Progression • finishing handoff dialogue • next "
                .. tostring(handoffNpc)
            )

            return {
                Mode = "interact",
                Npc = handoffNpc,
                Handoff = true,
            }
        end

        local npc =
            self:FindNPC(
                handoffNpc
            )

        if npc then
            self.Data.CurrentFarmTarget =
                npc

            self.Data.CurrentFarmQuery =
                handoffNpc

            self.Data.CurrentFarmRegion =
                self:ModelRegion(npc)
        end

        self:SafeText(
            self.UI.QuestInfo,
            " Smart Progression • HANDOFF"
            .. "\n NPC • "
            .. tostring(handoffNpc)
            .. "\n Reason • "
            .. tostring(
                handoffReason
                or "quest chain"
            )
        )

        self:QuestNpcStep(
            {
                Key = "QuestHandoff",
                Name = "Quest Handoff",
            },
            handoffNpc,
            "progress"
        )

        self:SetStatus(
            "Smart Progression • quest handoff • "
            .. tostring(handoffNpc)
        )

        return {
            Mode = "interact",
            Npc = handoffNpc,
            Handoff = true,
        }
    end

    -- No chain handoff exists: select the next eligible combat quest.
    local recommended = self:ChooseRecommendedQuest()

    -- BUILD 15: if the generic recommender produces nothing, use the
    -- scan-confirmed early progression route instead of silently dropping into
    -- an unrelated level-grind loop while Tom is standing next to the player.
    if not recommended and self.State.SmartProgression
        and tostring(self.State.SelectedQuest or "") == "" then
        recommended = self:KnownProgressionFallback()
    end

    if not recommended then
        if self.State.SmartProgression and tostring(self.State.SelectedQuest or "")=="" then
            self.Data.AutoQuest.Stage="level"
            self:ResetDialogueSession()
            self:SetStatus("Quest routes unavailable • farming loaded level mobs while waiting")
            return {Mode="levelgrind",WaitingForQuest=true}
        end
        self:StopMovement()
        self.Data.AutoQuest.Stage = "waiting"
        self:SetStatus(
            self.State.SelectedQuest ~= "" and "Selected quest unavailable • waiting for eligibility / retry"
                or "Smart Progression • waiting for eligible quest/cooldown"
        )

        self:SafeText(
            self.UI.QuestInfo,
            " Smart Progression • WAITING"
            .. "\n No eligible combat quest right now"
        )

        return {Mode="accept",WaitingForQuest=true}
    end

    local attempt = self.Runtime.AcceptAttempt
    if not attempt or attempt.Key ~= recommended.Key then
        attempt = {Key=recommended.Key, Started=os.clock(), Retries=0}
        self.Runtime.AcceptAttempt = attempt
    end
    local routeRoot = self:Root()
    if routeRoot and (not attempt.LastPosition or (routeRoot.Position-attempt.LastPosition).Magnitude>8) then
        attempt.LastPosition=routeRoot.Position
        attempt.Started=os.clock()
    end
    if os.clock() - attempt.Started > 25 then
        attempt.Retries = attempt.Retries + 1
        attempt.Started = os.clock()
        self:ResetDialogueSession()
        self:StopMovement()
        if attempt.Retries >= 2 then
            self.Runtime.QuestRetryUntil = self.Runtime.QuestRetryUntil or {}
            self.Runtime.QuestRetryUntil[recommended.Key] = os.clock() + 60
            self.Runtime.AcceptAttempt = nil
            self:SetStatus("Quest not accepted • retry in 60s • " .. tostring(recommended.Name))
            return {Mode="accept", Quest=recommended}
        end
    end
    self.Data.AutoQuest.Stage = "accept"

    self:SafeText(
        self.UI.QuestInfo,
        " Smart Progression • ACCEPT"
        .. "\n Quest • "
        .. tostring(recommended.Name)
        .. "\n NPC • "
        .. tostring(recommended.Npc)
        .. " • Req Lv "
        .. tostring(recommended.Level)
    )

    self:QuestNpcStep(
        recommended,
        recommended.Npc,
        "accept"
    )

    return {
        Mode = "accept",
        Quest = recommended,
    }
end

-- ============================================================
-- CHESTS / DROPS
-- ============================================================

function H:IsLootPickupPrompt(prompt)
    if not prompt
        or not prompt:IsA("ProximityPrompt")
        or prompt.Enabled == false then

        return false
    end

    local action =
        string.lower(
            tostring(
                prompt.ActionText
                or ""
            )
        )

    local objectText =
        string.lower(
            tostring(
                prompt.ObjectText
                or ""
            )
        )

    -- Screenshot example:
    --   ObjectText = "Mouth Dagger"
    --   ActionText = "Claim"
    local pickupAction =
        action == "claim"
        or action == "collect"
        or action == "take"
        or action == "pickup"
        or action == "pick up"
        or string.find(
            action,
            "claim",
            1,
            true
        ) ~= nil
        or string.find(
            action,
            "collect",
            1,
            true
        ) ~= nil
        or string.find(
            action,
            "pick",
            1,
            true
        ) ~= nil
        or string.find(
            action,
            "take",
            1,
            true
        ) ~= nil

    if not pickupAction then
        return false
    end

    -- Never mistake a chest Open/Claim prompt for a floor reward.
    if string.find(
        objectText,
        "chest",
        1,
        true
    ) ~= nil then

        return false
    end

    return true
end

function H:NearestLootPickupPrompt(maxPlayerDistance, origin, originRadius, nearbyPrompts)
    local root =
        self:Root()

    if not root then
        return nil
    end

    maxPlayerDistance =
        tonumber(maxPlayerDistance)
        or 18

    originRadius =
        tonumber(originRadius)

    local bestPrompt
    local bestPosition
    local bestDistance =
        math.huge

    for _, obj in ipairs(
        nearbyPrompts
        or self.S.Workspace:GetDescendants()
    ) do

        if obj.Parent
            and self:IsLootPickupPrompt(
                obj
            ) then

            local pos =
                self:PromptWorldPosition(
                    obj
                )

            if pos then
                local playerDistance =
                    (
                        root.Position
                        - pos
                    ).Magnitude

                local originOkay =
                    true

                if typeof(origin) == "Vector3"
                    and originRadius then

                    originOkay =
                        (
                            pos
                            - origin
                        ).Magnitude
                        <= originRadius
                end

                if originOkay
                    and playerDistance <= maxPlayerDistance
                    and playerDistance < bestDistance then

                    bestPrompt =
                        obj

                    bestPosition =
                        pos

                    bestDistance =
                        playerDistance
                end
            end
        end
    end

    return bestPrompt,
        bestDistance,
        bestPosition
end

function H:PromptOf(obj)
    return obj
        and obj:FindFirstChildWhichIsA(
            "ProximityPrompt",
            true
        )
end

function H:NearestTagged(tag, filter)
    local root = self:Root()

    if not root then
        return nil
    end

    local best
    local bestDistance = math.huge

    for _, obj in ipairs(self.S.CollectionService:GetTagged(tag)) do
        if obj and obj.Parent then
            local pos

            if obj:IsA("BasePart") then
                pos = obj.Position
            elseif obj:IsA("Model") then
                local ok, cf = pcall(obj.GetPivot, obj)
                pos = ok and cf.Position or nil
            else
                local part =
                    obj:FindFirstChildWhichIsA(
                        "BasePart",
                        true
                    )

                pos = part and part.Position or nil
            end

            if pos
                and (
                    not filter
                    or filter(obj)
                ) then

                local d =
                    (root.Position - pos).Magnitude

                if d < bestDistance then
                    best = obj
                    bestDistance = d
                end
            end
        end
    end

    return best, bestDistance
end

function H:InteractPrompt(prompt)
    if not prompt or not prompt.Enabled then
        return false
    end

    if typeof(fireproximityprompt) == "function" then
        return pcall(
            fireproximityprompt,
            prompt
        )
    end

    return false
end

function H:IsChestPrompt(prompt)
    if not prompt
        or not prompt:IsA("ProximityPrompt") then

        return false
    end

    local objectText =
        string.lower(
            tostring(
                prompt.ObjectText
                or ""
            )
        )

    local actionText =
        string.lower(
            tostring(
                prompt.ActionText
                or ""
            )
        )

    local promptName =
        string.lower(
            tostring(
                prompt.Name
                or ""
            )
        )

    local ancestor =
        prompt:FindFirstAncestorOfClass(
            "Model"
        )

    local ancestorName =
        string.lower(
            tostring(
                ancestor
                and ancestor.Name
                or ""
            )
        )

    return string.find(
        objectText,
        "chest",
        1,
        true
    ) ~= nil
        or string.find(
            promptName,
            "chest",
            1,
            true
        ) ~= nil
        or string.find(
            ancestorName,
            "chest",
            1,
            true
        ) ~= nil
        or (
            (
                actionText == "open"
                or actionText == "claim"
            )
            and (
                string.find(
                    objectText,
                    "common",
                    1,
                    true
                )
                or string.find(
                    objectText,
                    "rare",
                    1,
                    true
                )
                or string.find(
                    objectText,
                    "epic",
                    1,
                    true
                )
                or string.find(
                    objectText,
                    "legendary",
                    1,
                    true
                )
                or string.find(
                    objectText,
                    "mythic",
                    1,
                    true
                )
            )
        )
end

function H:PromptWorldPosition(prompt)
    if not prompt then
        return nil, nil
    end

    local parent =
        prompt.Parent

    if parent
        and parent:IsA("Attachment") then

        local host =
            parent.Parent

        if host
            and host:IsA("BasePart") then

            return parent.WorldPosition,
                host
        end
    end

    if parent
        and parent:IsA("BasePart") then

        return parent.Position,
            parent
    end

    local model =
        prompt:FindFirstAncestorOfClass(
            "Model"
        )

    if model then
        local part =
            model.PrimaryPart
            or model:FindFirstChildWhichIsA(
                "BasePart",
                true
            )

        if part then
            return part.Position,
                part
        end
    end

    return nil, nil
end

function H:NearestChestPrompt(maxDistance)
    local root =
        self:Root()

    if not root then
        return nil
    end

    maxDistance =
        tonumber(maxDistance)
        or math.huge

    local bestPrompt
    local bestDistance =
        math.huge

    local function consider(prompt)
        if not self:IsChestPrompt(
            prompt
        ) then

            return
        end

        if prompt.Enabled == false then
            return
        end

        local pos =
            self:PromptWorldPosition(
                prompt
            )

        if not pos then
            return
        end

        local distance =
            (
                root.Position
                - pos
            ).Magnitude

        if distance <= maxDistance
            and distance < bestDistance then

            bestPrompt =
                prompt

            bestDistance =
                distance
        end
    end

    -- Prefer prompts belonging to CollectionService-tagged chests.
    for _, chest in ipairs(
        self.S.CollectionService:GetTagged(
            self:ChestTag()
        )
    ) do

        if chest
            and chest.Parent then

            local prompt =
                self:PromptOf(
                    chest
                )

            if prompt then
                consider(
                    prompt
                )
            end
        end
    end

    -- Some boss reward chests are not tagged immediately when spawned.
    -- Fallback to visible/enabled chest prompts such as:
    --   ObjectText = "Common Chest"
    --   ActionText = "Open"
    if not bestPrompt then
        for _, obj in ipairs(
            self.S.Workspace:GetDescendants()
        ) do

            if obj:IsA(
                "ProximityPrompt"
            ) then

                consider(
                    obj
                )
            end
        end
    end

    return bestPrompt,
        bestDistance
end

function H:PressChestPromptKey(prompt)
    if not prompt
        or not prompt.Parent
        or prompt.Enabled == false then

        return false
    end

    if self.Runtime.ChestKeyBusy then
        return false
    end

    self.Runtime.ChestKeyBusy =
        true

    task.spawn(
        function()
            local key =
                prompt.KeyboardKeyCode

            if not key
                or key.Name == "Unknown" then

                -- Screenshot-confirmed chest interaction key.
                key =
                    Enum.KeyCode.T
            end

            local hold =
                math.max(
                    tonumber(
                        prompt.HoldDuration
                    )
                    or 0,
                    0
                )

            pcall(
                function()
                    self.S.VirtualInputManager:SendKeyEvent(
                        true,
                        key,
                        false,
                        game
                    )

                    task.wait(
                        math.max(
                            hold + 0.04,
                            0.06
                        )
                    )

                    self.S.VirtualInputManager:SendKeyEvent(
                        false,
                        key,
                        false,
                        game
                    )
                end
            )

            task.wait(
                0.08
            )

            self.Runtime.ChestKeyBusy =
                false
        end
    )

    return true
end

function H:OpenChestPromptReliable(prompt)
    if not prompt
        or not prompt.Parent
        or prompt.Enabled == false then

        return false
    end

    local attempted =
        false

    if typeof(
        fireproximityprompt
    ) == "function" then

        local ok =
            pcall(
                fireproximityprompt,
                prompt
            )

        attempted =
            attempted
            or ok
    end

    -- fireproximityprompt may report success while the chest remains closed.
    -- Also press the prompt's real keyboard key (T in the screenshot).
    if prompt.Parent
        and prompt.Enabled then

        attempted =
            self:PressChestPromptKey(
                prompt
            )
            or attempted
    end

    return attempted
end

function H:ObjectWorldPosition(obj)
    if not obj then
        return nil, nil
    end

    if obj:IsA("BasePart") then
        return obj.Position,
            obj
    end

    if obj:IsA("Attachment") then
        local host =
            obj.Parent

        if host
            and host:IsA("BasePart") then

            return obj.WorldPosition,
                host
        end
    end

    if obj:IsA("ProximityPrompt") then
        return self:PromptWorldPosition(
            obj
        )
    end

    if obj:IsA("Model") then
        local part =
            obj.PrimaryPart
            or obj:FindFirstChildWhichIsA(
                "BasePart",
                true
            )

        if part then
            return part.Position,
                part
        end
    end

    local prompt =
        self:PromptOf(
            obj
        )

    if prompt then
        local pos,
            part =
            self:PromptWorldPosition(
                prompt
            )

        if pos then
            return pos,
                part
        end
    end

    local part =
        obj:FindFirstChildWhichIsA(
            "BasePart",
            true
        )

    if part then
        return part.Position,
            part
    end

    return nil, nil
end

function H:FindBossChestLootDrop(origin, radius)
    if typeof(origin) ~= "Vector3" then
        return nil
    end

    radius =
        tonumber(radius)
        or 45

    local root =
        self:Root()

    if not root then
        return nil
    end

    local bestDrop
    local bestPrompt
    local bestPosition
    local bestDistance =
        math.huge

    local function consider(drop, prompt)
        if not drop
            or not drop.Parent then

            return
        end

        prompt =
            prompt
            or self:PromptOf(
                drop
            )

        if not prompt
            or not prompt.Parent
            or prompt.Enabled == false then

            return
        end

        local pos =
            self:ObjectWorldPosition(
                drop
            )

        if not pos then
            pos =
                self:PromptWorldPosition(
                    prompt
                )
        end

        if not pos then
            return
        end

        -- Only collect rewards that actually spawned around the boss chest.
        local fromChest =
            (
                pos
                - origin
            ).Magnitude

        if fromChest > radius then
            return
        end

        local fromPlayer =
            (
                root.Position
                - pos
            ).Magnitude

        if fromPlayer < bestDistance then
            bestDrop =
                drop

            bestPrompt =
                prompt

            bestPosition =
                pos

            bestDistance =
                fromPlayer
        end
    end

    -- Primary path: the game's LootDrop CollectionService tag.
    for _, drop in ipairs(
        self.S.CollectionService:GetTagged(
            self:DropTag()
        )
    ) do

        consider(
            drop
        )
    end

    -- Fallback: if the game's tag is late/missing, look for nearby pickup-like
    -- ProximityPrompts. Do NOT accidentally treat the chest prompt itself as a
    -- floor drop.
    if not bestDrop then
        for _, obj in ipairs(
            self.S.Workspace:GetDescendants()
        ) do

            if obj:IsA(
                "ProximityPrompt"
            )
                and obj.Enabled then

                local action =
                    string.lower(
                        tostring(
                            obj.ActionText
                            or ""
                        )
                    )

                local objectText =
                    string.lower(
                        tostring(
                            obj.ObjectText
                            or ""
                        )
                    )

                local looksLikePickup =
                    string.find(
                        action,
                        "pick",
                        1,
                        true
                    )
                    or string.find(
                        action,
                        "collect",
                        1,
                        true
                    )
                    or string.find(
                        action,
                        "take",
                        1,
                        true
                    )
                    or string.find(
                        action,
                        "claim",
                        1,
                        true
                    )

                local isChest =
                    string.find(
                        objectText,
                        "chest",
                        1,
                        true
                    )
                    or action == "open"

                if looksLikePickup
                    and not isChest then

                    local pos =
                        self:PromptWorldPosition(
                            obj
                        )

                    if pos
                        and (
                            pos
                            - origin
                        ).Magnitude <= radius then

                        consider(
                            obj.Parent,
                            obj
                        )
                    end
                end
            end
        end
    end

    return bestDrop,
        bestDistance,
        bestPrompt,
        bestPosition
end

function H:CollectBossLootPrompt(prompt)
    if not prompt
        or not prompt.Parent
        or prompt.Enabled == false then

        return false
    end

    local attempted =
        false

    if typeof(
        fireproximityprompt
    ) == "function" then

        local ok =
            pcall(
                fireproximityprompt,
                prompt
            )

        attempted =
            attempted
            or ok
    end

    -- Generic key fallback. PressChestPromptKey reads the prompt's own
    -- KeyboardKeyCode first, so it also works for floor rewards using E/T/etc.
    if prompt.Parent
        and prompt.Enabled then

        attempted =
            self:PressChestPromptKey(
                prompt
            )
            or attempted
    end

    return attempted
end

function H:FinishBossChestLoot()
    self.Runtime.BossChestLootPhase =
        false

    self.Runtime.BossChestClaiming =
        false

    self.Runtime.BossChestLootOrigin =
        nil

    self.Runtime.BossChestOpenedAt =
        0

    self.Runtime.BossChestLastDropSeenAt =
        0

    self.Runtime.BossChestLootDeadline =
        0

    self.Runtime.BossChestOpenedPrompt =
        nil

    self.Runtime.BossChestOpenRetryAt =
        0

    if self.Runtime.SimpleDirectTween then
        pcall(
            function()
                self.Runtime.SimpleDirectTween:Cancel()
            end
        )

        self.Runtime.SimpleDirectTween =
            nil

        self.Runtime.SimpleDirectGoal =
            nil

        self.Runtime.SimpleDirectKey =
            nil
    end

    self:SetStatus(
        "Boss Chest • loot clear • resuming bosses"
    )
end

function H:BossChestLootStep()
    if not self.Runtime.BossChestLootPhase then
        return false
    end

    local now =
        os.clock()

    local origin =
        self.Runtime.BossChestLootOrigin

    if typeof(origin) ~= "Vector3" then
        self:FinishBossChestLoot()
        return true
    end

    local openedAt =
        self.Runtime.BossChestOpenedAt
        or now

    local deadline =
        self.Runtime.BossChestLootDeadline
        or (
            openedAt + 9
        )

    -- Give the chest a moment to spawn its physical rewards.
    if now - openedAt < 0.35 then
        self:SetStatus(
            "Boss Chest • waiting for loot to drop"
        )

        return true
    end

    -- If the prompt is somehow still enabled, retry opening for a short period.
    local chestPrompt =
        self.Runtime.BossChestOpenedPrompt

    if chestPrompt
        and chestPrompt.Parent
        and chestPrompt.Enabled
        and now - openedAt < 3.0
        and now
            >= (
                self.Runtime.BossChestOpenRetryAt
                or 0
            ) then

        self.Runtime.BossChestOpenRetryAt =
            now + 0.55

        self:OpenChestPromptReliable(
            chestPrompt
        )
    end

    local drop,
        distance,
        prompt,
        dropPosition =
        self:FindBossChestLootDrop(
            origin,
            50
        )

    if drop
        and prompt
        and dropPosition then

        self.Runtime.BossChestLastDropSeenAt =
            now

        local root =
            self:Root()

        if not root then
            return true
        end

        local maxDistance =
            tonumber(
                prompt.MaxActivationDistance
            )
            or 8

        if distance
            <= maxDistance + 1.0 then

            self:StopMovement()

            if self.Runtime.SimpleDirectTween then
                pcall(
                    function()
                        self.Runtime.SimpleDirectTween:Cancel()
                    end
                )

                self.Runtime.SimpleDirectTween =
                    nil

                self.Runtime.SimpleDirectGoal =
                    nil

                self.Runtime.SimpleDirectKey =
                    nil
            end

            self:SetStatus(
                "Boss Chest • picking up "
                .. tostring(
                    prompt.ObjectText ~= ""
                    and prompt.ObjectText
                    or drop.Name
                )
            )

            self:CollectBossLootPrompt(
                prompt
            )

            return true
        end

        self:SetStatus(
            "Boss Chest • collecting drop • "
            .. tostring(
                math.floor(
                    distance
                )
            )
            .. " studs"
        )

        local direction =
            root.Position
            - dropPosition

        if direction.Magnitude < 0.05 then
            direction =
                Vector3.new(
                    1,
                    0,
                    0
                )
        end

        local standDistance =
            math.max(
                1.2,
                math.min(
                    maxDistance - 0.60,
                    3.25
                )
            )

        local goal =
            dropPosition
            + direction.Unit
            * standDistance

        goal =
            self:GroundClampPosition(
                goal,
                dropPosition.Y,
                2.55
            )
            or goal

        self:SimpleDirectTween(
            goal,
            dropPosition,
            120,
            "BOSS_LOOT"
        )

        return true
    end

    -- Don't finish immediately after collecting one item; chest drops often
    -- appear in a short stagger. Require a clear period before resuming bosses.
    local lastSeen =
        self.Runtime.BossChestLastDropSeenAt
        or openedAt

    local clearFor =
        now
        - math.max(
            lastSeen,
            openedAt + 0.80
        )

    if now < deadline
        and clearFor < 1.20 then

        self:SetStatus(
            "Boss Chest • scanning for remaining loot"
        )

        return true
    end

    self.Runtime.BossChestProcessedPrompt =
        self.Runtime.BossChestOpenedPrompt

    self.Runtime.BossChestProcessedAt =
        now

    self:FinishBossChestLoot()

    return true
end

function H:ChestTag()
    local gs = self.Modules.GameSettings

    if type(gs) == "table"
        and type(gs.Tags) == "table"
        and gs.Tags.Chest then

        return gs.Tags.Chest
    end

    return "Chest"
end

function H:DropTag()
    local gs = self.Modules.GameSettings

    if type(gs) == "table"
        and type(gs.Tags) == "table"
        and gs.Tags.LootDrop then

        return gs.Tags.LootDrop
    end

    return "LootDrop"
end

-- ============================================================
-- DAY / NIGHT TIMER
-- ============================================================

function H:UpdateClockRate()
    local sample = self.Data.ClockSample
    local nowReal = os.clock()
    local nowClock = self.S.Lighting.ClockTime

    if sample.Clock == nil then
        sample.Clock = nowClock
        sample.Real = nowReal
        return
    end

    local realDelta = nowReal - sample.Real

    if realDelta >= 2 then
        local clockDelta = nowClock - sample.Clock

        if clockDelta < -12 then
            clockDelta += 24
        elseif clockDelta > 12 then
            clockDelta -= 24
        end

        sample.Rate = clockDelta / realDelta
        sample.Clock = nowClock
        sample.Real = nowReal
    end
end

function H:ClockETA()
    local clock = self.S.Lighting.ClockTime
    local rate = self.Data.ClockSample.Rate

    local phase =
        (clock >= 18 or clock < 6)
        and "Night"
        or "Day"

    local target =
        phase == "Day"
        and 18
        or 6

    local hours

    if target >= clock then
        hours = target - clock
    else
        hours = 24 - clock + target
    end

    if not rate or math.abs(rate) < 0.0001 then
        return phase, nil
    end

    return phase, math.max(0, hours / math.abs(rate))
end

-- ============================================================
-- TRAVEL
-- ============================================================

function H:TravelToObject(obj, label)
    if not obj then
        self:SetStatus(
            "Travel • target unavailable"
        )
        return false
    end

    local part =
        obj:IsA("BasePart")
        and obj
        or obj:FindFirstChild(
            "HumanoidRootPart",
            true
        )
        or obj:FindFirstChildWhichIsA(
            "BasePart",
            true
        )

    if not part then
        self:SetStatus(
            "Travel • no position for "
            .. tostring(label)
        )
        return false
    end

    self:TweenExact(
        part.Position
        + Vector3.new(0, 2, 5),
        part.Position
    )

    self:SetStatus(
        "Travel • "
        .. tostring(label)
    )

    return true
end

function H:TravelSelectedNPC()
    local data = self.Data.NPCs

    local name =
        self.State.SelectedNPC

    local obj =
        data
        and data.Map
        and name
        and data.Map[name]

    return self:TravelToObject(
        obj,
        name or "NPC"
    )
end

function H:TravelSelectedPlace()
    local data = self.Data.Places

    local name =
        self.State.SelectedPlace

    local obj =
        data
        and data.Map
        and name
        and data.Map[name]

    return self:TravelToObject(
        obj,
        name or "Place"
    )
end

function H:TravelQuestNPC()
    local active =
        self:GetActiveQuest()

    local def =
        active
        and select(
            1,
            self:QuestDefinition(
                active.Key,
                active.Name
            )
        )
        or nil

    local npcName =
        type(def) == "table"
        and def.OfferNpc
        or nil

    if typeof(npcName) ~= "string" then
        local recommended =
            self:ChooseRecommendedQuest()

        npcName =
            recommended
            and recommended.Npc
            or nil
    end

    if not npcName then
        self:SetStatus(
            "Travel • no quest NPC"
        )
        return false
    end

    local npc = self:FindNPC(npcName)

    return self:TravelToObject(
        npc,
        "Quest NPC • "
        .. tostring(npcName)
    )
end

-- ============================================================
-- ESP
-- ============================================================

function H:SetHighlight(obj, enabled, label)
    local existing = self.Data.Highlights[obj]

    if not enabled then
        if existing then
            pcall(function()
                existing:Destroy()
            end)

            self.Data.Highlights[obj] = nil
        end

        return
    end

    if existing and existing.Parent then
        return
    end

    if not obj or not obj.Parent then
        return
    end

    local target = obj

    if not obj:IsA("Model")
        and not obj:IsA("BasePart") then

        target =
            obj:FindFirstAncestorOfClass("Model")
            or obj:FindFirstChildWhichIsA(
                "BasePart",
                true
            )
    end

    if not target then
        return
    end

    local h = Instance.new("Highlight")
    h.Name = "ThumbsHubESP"
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.FillTransparency = 0.75
    h.OutlineTransparency = 0
    h.Adornee = target

    -- Keep runtime-created visuals outside CoreGui as well; this avoids the
    -- same executor Plugin-capability failure that affected quest/status UI.
    h.Parent = target

    self.Data.Highlights[obj] = h
end

function H:EspRoot(obj)
    if not obj then
        return nil
    end

    if obj:IsA("BasePart") then
        return obj
    end

    if obj:IsA("Model") then
        return obj:FindFirstChild(
            "HumanoidRootPart",
            true
        )
        or obj.PrimaryPart
        or obj:FindFirstChildWhichIsA(
            "BasePart",
            true
        )
    end

    return obj:FindFirstChildWhichIsA(
        "BasePart",
        true
    )
end

function H:SetESPBillboard(obj, enabled, prefix)
    local existing =
        self.Data.EspBillboards[obj]

    if not enabled then
        if existing then
            pcall(function()
                existing:Destroy()
            end)
            self.Data.EspBillboards[obj] = nil
        end
        return
    end

    local root = self:EspRoot(obj)

    if not root then
        return
    end

    if not existing
        or not existing.Parent then

        local gui = Instance.new("BillboardGui")
        gui.Name = "ThumbsHubESPLabel"
        gui.AlwaysOnTop = true
        gui.Size = UDim2.fromOffset(190, 44)
        gui.StudsOffset = Vector3.new(0, 3.2, 0)
        gui.Adornee = root
        gui.Parent = root

        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 12
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeTransparency = 0.3
        label.TextWrapped = true
        label.Parent = gui

        self.Data.EspBillboards[obj] = gui
        existing = gui
    end

    local label = existing:FindFirstChild("Label")

    if not label then
        return
    end

    local pieces = {
        tostring(prefix or obj.Name),
    }

    local hum =
        obj:IsA("Model")
        and (
            obj:FindFirstChildOfClass("Humanoid")
            or obj:FindFirstChildWhichIsA("Humanoid", true)
        )
        or nil

    if self.State.ESPHealth
        and hum then

        table.insert(
            pieces,
            tostring(math.floor(hum.Health))
            .. "/"
            .. tostring(math.floor(hum.MaxHealth))
            .. " HP"
        )
    end

    if self.State.ESPDistance then
        local mine = self:Root()

        if mine then
            table.insert(
                pieces,
                tostring(
                    math.floor(
                        (
                            mine.Position
                            - root.Position
                        ).Magnitude
                    )
                )
                .. "m"
            )
        end
    end

    label.Text = table.concat(pieces, " • ")
end

function H:UpdateESP()
    for obj in pairs(self.Data.Highlights) do
        if not obj or not obj.Parent then
            local h = self.Data.Highlights[obj]

            if h then
                pcall(function()
                    h:Destroy()
                end)
            end

            self.Data.Highlights[obj] = nil
        end
    end

    for obj in pairs(self.Data.EspBillboards) do
        if not obj or not obj.Parent then
            local gui = self.Data.EspBillboards[obj]

            if gui then
                pcall(function()
                    gui:Destroy()
                end)
            end

            self.Data.EspBillboards[obj] = nil
        end
    end

    for _, mob in ipairs(self.Data.Mobs) do
        local enabled = self.State.MobESP
        self:SetHighlight(mob, enabled)
        self:SetESPBillboard(
            mob,
            enabled and self.State.ESPLabels,
            mob.Name
        )
    end

    for _, rec in pairs(self.Data.Bosses) do
        if rec.Model then
            self:SetHighlight(
                rec.Model,
                self.State.BossESP
            )

            self:SetESPBillboard(
                rec.Model,
                self.State.BossESP
                    and self.State.ESPLabels,
                "BOSS • "
                .. tostring(rec.Title)
            )
        end
    end

    local questTarget =
        self.Data.CurrentFarmTarget

    if questTarget
        and questTarget.Parent then

        self:SetHighlight(
            questTarget,
            self.State.QuestTargetESP
        )

        self:SetESPBillboard(
            questTarget,
            self.State.QuestTargetESP
                and self.State.ESPLabels,
            "QUEST • "
            .. tostring(questTarget.Name)
        )
    end

    local chestTag = self:ChestTag()

    for _, chest in ipairs(
        self.S.CollectionService:GetTagged(
            chestTag
        )
    ) do
        self:SetHighlight(
            chest,
            self.State.ChestESP
        )

        self:SetESPBillboard(
            chest,
            self.State.ChestESP
                and self.State.ESPLabels,
            "CHEST"
        )
    end

    local dropTag = self:DropTag()

    for _, drop in ipairs(
        self.S.CollectionService:GetTagged(
            dropTag
        )
    ) do
        self:SetHighlight(
            drop,
            self.State.DropESP
        )

        self:SetESPBillboard(
            drop,
            self.State.DropESP
                and self.State.ESPLabels,
            "DROP"
        )
    end
end

-- ============================================================
-- PLAYER MODS
-- ============================================================

function H:ApplyWalkSpeed()
    local hum = self:Humanoid()

    if hum then
        hum.WalkSpeed =
            self.State.AlwaysRun and math.max(24, self.State.WalkSpeed)
            or (self.State.WalkSpeedEnabled and self.State.WalkSpeed or 16)
    end
end

function H:UpdateFly(dt)
    if not self.State.Fly then
        if self.Runtime.FlyBV then
            self.Runtime.FlyBV:Destroy()
            self.Runtime.FlyBV = nil
        end

        if self.Runtime.FlyBG then
            self.Runtime.FlyBG:Destroy()
            self.Runtime.FlyBG = nil
        end

        return
    end

    local root = self:Root()

    if not root then
        return
    end

    if not self.Runtime.FlyBV then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "ThumbsHubFlyVelocity"
        bv.MaxForce = Vector3.new(
            math.huge,
            math.huge,
            math.huge
        )
        bv.Velocity = Vector3.zero
        bv.Parent = root

        local bg = Instance.new("BodyGyro")
        bg.Name = "ThumbsHubFlyGyro"
        bg.MaxTorque = Vector3.new(
            math.huge,
            math.huge,
            math.huge
        )
        bg.P = 9000
        bg.CFrame = root.CFrame
        bg.Parent = root

        self.Runtime.FlyBV = bv
        self.Runtime.FlyBG = bg
    end

    local cam = self.S.Workspace.CurrentCamera
    local dir = Vector3.zero

    if self.S.UserInputService:IsKeyDown(Enum.KeyCode.W) then
        dir += cam.CFrame.LookVector
    end

    if self.S.UserInputService:IsKeyDown(Enum.KeyCode.S) then
        dir -= cam.CFrame.LookVector
    end

    if self.S.UserInputService:IsKeyDown(Enum.KeyCode.A) then
        dir -= cam.CFrame.RightVector
    end

    if self.S.UserInputService:IsKeyDown(Enum.KeyCode.D) then
        dir += cam.CFrame.RightVector
    end

    if self.S.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        dir += Vector3.yAxis
    end

    if self.S.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        dir -= Vector3.yAxis
    end

    if dir.Magnitude > 0 then
        dir = dir.Unit
    end

    self.Runtime.FlyBV.Velocity =
        dir * self.State.FlySpeed

    self.Runtime.FlyBG.CFrame =
        CFrame.new(
            root.Position,
            root.Position
            + cam.CFrame.LookVector
        )
end

-- ============================================================
-- STAFF/GROUP MEMBER DETECTOR
-- ============================================================

function H:CheckGroupMember(plr)
    if not self.State.GroupDetect
        or game.CreatorType ~= Enum.CreatorType.Group then

        return
    end

    task.spawn(function()
        local ok, rank =
            pcall(
                plr.GetRankInGroup,
                plr,
                game.CreatorId
            )

        if ok and rank and rank > 0 then
            self:Notify(
                "Creator-group member detected • "
                .. plr.Name
                .. " • rank "
                .. tostring(rank)
            )
        end
    end)
end

-- ============================================================
-- JOB / RECONNECT
-- ============================================================

function H:CopyJob()
    if typeof(setclipboard) == "function" then
        pcall(
            setclipboard,
            game.JobId
        )

        self:Notify("Job ID copied")
    end
end

function H:JoinJob(job)
    job = tostring(job or "")

    if job == "" then
        self:SetStatus("Enter a Job ID first")
        return
    end

    pcall(function()
        self.S.TeleportService:TeleportToPlaceInstance(
            game.PlaceId,
            job,
            self.Player
        )
    end)
end

function H:Reconnect()
    pcall(function()
        self.S.TeleportService:Teleport(
            game.PlaceId,
            self.Player
        )
    end)
end

function H:BossChestStep()
    if self.Runtime.BossChestLootPhase then
        return self:BossChestLootStep()
    end

    if not self.State.AutoBossChest
        or os.clock()
            - (
                self.Runtime.LastBossChest
                or 0
            )
            < 0.20 then

        return false
    end

    self.Runtime.LastBossChest =
        os.clock()

    local prompt,
        distance =
        self:NearestChestPrompt(
            220
        )

    if prompt
        and prompt
            == self.Runtime.BossChestProcessedPrompt
        and os.clock()
            - (
                self.Runtime.BossChestProcessedAt
                or 0
            )
            < 20 then

        return false
    end

    if not prompt
        or not distance then

        self.Runtime.BossChestClaiming =
            false

        return false
    end

    local root =
        self:Root()

    if not root then
        return false
    end

    local pos,
        _part =
        self:PromptWorldPosition(
            prompt
        )

    if not pos then
        return false
    end

    local maxDistance =
        tonumber(
            prompt.MaxActivationDistance
        )
        or 8

    self.Runtime.BossChestClaiming =
        true

    -- Boss is already dead when this branch runs. Chest collection takes
    -- movement priority even though AutoWorldBoss is still enabled.
    self.Runtime.AttackTarget =
        nil

    self.Data.CurrentFarmTarget =
        nil

    self:StopAttackHold()
    self:StopBlocking()

    if distance
        <= maxDistance + 1.25 then

        self:StopMovement()

        if self.Runtime.SimpleDirectTween then
            pcall(
                function()
                    self.Runtime.SimpleDirectTween:Cancel()
                end
            )

            self.Runtime.SimpleDirectTween =
                nil

            self.Runtime.SimpleDirectGoal =
                nil

            self.Runtime.SimpleDirectKey =
                nil
        end

        self:SetStatus(
            "Boss Chest • opening "
            .. tostring(
                prompt.ObjectText ~= ""
                and prompt.ObjectText
                or "chest"
            )
        )

        self:OpenChestPromptReliable(
            prompt
        )

        if not self.Runtime.BossChestLootPhase then
            local now =
                os.clock()

            self.Runtime.BossChestLootPhase =
                true

            self.Runtime.BossChestLootOrigin =
                pos

            self.Runtime.BossChestOpenedAt =
                now

            self.Runtime.BossChestLastDropSeenAt =
                now

            self.Runtime.BossChestLootDeadline =
                now + 9.0

            self.Runtime.BossChestOpenedPrompt =
                prompt

            self.Runtime.BossChestOpenRetryAt =
                now + 0.45

            self:SetStatus(
                "Boss Chest • opened • waiting for drops"
            )
        end

        return true
    end

    -- IMPORTANT:
    -- Do NOT call FarmOwnsMovement() here. AutoWorldBoss itself makes that
    -- return true, which was the exact reason BUILD 47 never approached the
    -- reward chest.
    self:SetStatus(
        "Boss Chest • collecting • "
        .. tostring(
            math.floor(
                distance
            )
        )
        .. " studs"
    )

    -- Fast direct tween to the chest's prompt position.
    -- Stop just inside interaction range instead of sitting on top of it.
    local direction =
        root.Position
        - pos

    if direction.Magnitude < 0.05 then
        direction =
            Vector3.new(
                1,
                0,
                0
            )
    end

    local standDistance =
        math.max(
            1.5,
            math.min(
                maxDistance - 0.75,
                4.0
            )
        )

    local goal =
        pos
        + direction.Unit
        * standDistance

    goal =
        self:GroundClampPosition(
            goal,
            pos.Y,
            2.55
        )
        or goal

    self:SimpleDirectTween(
        goal,
        pos,
        115,
        "BOSS_CHEST"
    )

    return true
end

-- ============================================================
-- UNLOAD
-- ============================================================

function H:Unload()
    if self.State.Unloaded then
        return
    end

    self.State.Unloaded = true
    pcall(function()
        self.S.RunService:UnbindFromRenderStep("ThumbsHubDrivenWalk")
    end)
    self:StopAllAutomation()
    self:CleanupExtras()

    self.State.SmartProgression = false
    self.State.AutoQuest = false
    self.State.AutoAccept = false
    self.State.AutoFarmMobs = false
    self.State.AutoWorldBoss = false

    self:SetBossTravelNoclip(
        false
    )

    self:SetMobTravelNoclip(
        false
    )

    self.Runtime.MobApproachTravel =
        false

    self.State.AutoChests = false
    self.State.AutoDrops = false

    self.Runtime.BossChestLootPhase = false
    self.Runtime.BossChestClaiming = false
    self.Runtime.BossChestLootOrigin = nil
    self.Runtime.BossChestOpenedPrompt = nil
    self.State.AutoM1 = false
    self.State.AutoEquipCombat = false
    self.State.AutoParry = false
    self.State.PerfectBlock = false
    self.State.PingAwareParry = false
    self.State.BossSafetyMode = false
    self.State.SafeCombat = false
    self.State.SmartSkill = false
    self.State.Fly = false
    self.State.Noclip = false
    self.State.WalkSpeedEnabled = false

    self:ResetDialogueSession()
    self:StopMovement()
    self:StopAttackHold()
    self:StopBlocking()
    self:SetManualFarmNoclip(false)

    if self.Runtime.FlyBV then
        pcall(function()
            self.Runtime.FlyBV:Destroy()
        end)
        self.Runtime.FlyBV = nil
    end

    if self.Runtime.FlyBG then
        pcall(function()
            self.Runtime.FlyBG:Destroy()
        end)
        self.Runtime.FlyBG = nil
    end

    for obj, highlight in pairs(self.Data.Highlights) do
        if highlight then
            pcall(function()
                highlight:Destroy()
            end)
        end

        self.Data.Highlights[obj] = nil
    end

    for obj, billboard in pairs(self.Data.EspBillboards) do
        if billboard then
            pcall(function()
                billboard:Destroy()
            end)
        end

        self.Data.EspBillboards[obj] = nil
    end

    for model, rec in pairs(self.Data.DefenseWatchers) do
        if rec and rec.Connections then
            for _, c in ipairs(rec.Connections) do
                pcall(function()
                    c:Disconnect()
                end)
            end
        end

        self.Data.DefenseWatchers[model] = nil
    end

    local hum = self:Humanoid()

    if hum then
        pcall(function()
            hum.WalkSpeed = 16
        end)
    end

    -- Disconnect every connection created by this module.
    for _, connection in ipairs(self.Runtime.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(self.Runtime.Connections)

    local gui = self.UI.Gui
    self.UI.Gui = nil

    if gui then
        pcall(function()
            gui:Destroy()
        end)
    end

    local env =
        (getgenv and getgenv())
        or _G

    if env.THUMBSHUB_NEW_GAME_INSTANCE == self then
        env.THUMBSHUB_NEW_GAME_INSTANCE = nil
    end

    print("[THUMBSHUB] Unloaded")
end

-- ============================================================
-- UI HELPERS
-- ============================================================

function H:AnimateUI(obj, properties, duration)
    self.Runtime.UITweens = self.Runtime.UITweens or setmetatable({}, {__mode = "k"})
    local old = self.Runtime.UITweens[obj]
    if old then old:Cancel() end
    local tween = self.S.TweenService:Create(obj,
        TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    self.Runtime.UITweens[obj] = tween
    tween:Play()
end

function H:UpdateSmoothMetrics()
    local ping = self:GetPingMs()
    local _, _hold, _, lead = self:AdaptiveParryProfile(self.Runtime.AttackTarget)
    local threat = self:NearestActiveThreat()
    local mode = self.Runtime.Retreating and "RECOVERING"
        or threat and "DEFENDING"
        or self.Runtime.AttackTarget and "FARMING"
        or self.State.AutoFarmMobs and "MOB FARM" or "READY"
    local detail
    if self.Runtime.Retreating then
        detail = string.format("HEALING  %d%% HP • attacks resume at %d%%",
            math.floor(self:HealthPercent()), self.State.ResumeHealthPercent)
    elseif threat then
        detail = "DEFENDING  " .. tostring(threat.Name) .. " • waiting for an opening"
    elseif self.Runtime.LastHitConfirmAt and os.clock() - self.Runtime.LastHitConfirmAt < 1.5 then
        detail = "HIT CONFIRMED • target health decreased"
    elseif self.Runtime.AttackTarget then
        detail = self.Runtime.LastPunchFailure ~= "" and self.Runtime.LastPunchFailure
            or "ATTACKING • waiting for damage confirmation"
    else
        detail = self.State.AutoFarmMobs
            and (self.Runtime.LastStatus or "Mob farm active")
            or "READY • choose a mob on the Farm page"
    end
    self:SafeText(self.UI.NetworkSummary, string.format(
        "NETWORK  %d ms • Jitter %d ms • %s • Guard margin %d ms\n%s",
        math.floor(ping + 0.5), math.floor((self.Runtime.PingJitterMs or 0) + 0.5),
        self.State.PingAwareParry and "ADAPTIVE" or "FIXED",
        math.floor(lead * 1000), tostring(detail)))
    self:SafeText(self.UI.LiveChip, "● " .. mode)
end


function H:Round(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius =
        UDim.new(
            0,
            radius or 8
        )
    c.Parent = obj
end

function H:Button(parent, text, callback, width)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(
        0,
        width or 220,
        0,
        38
    )
    b.BackgroundColor3 =
        Color3.fromRGB(
            30,
            31,
            38
        )
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.TextColor3 =
        Color3.fromRGB(
            235,
            236,
            242
        )
    b.Text = text
    b.Parent = parent
    self:Round(b, 9)

    local stroke = Instance.new("UIStroke")
    stroke.Color =
        Color3.fromRGB(
            48,
            50,
            60
        )
    stroke.Transparency = 0.35
    stroke.Thickness = 1
    stroke.Parent = b

    self:Connect(b.MouseEnter, function()
        self:AnimateUI(b, {BackgroundColor3 = Color3.fromRGB(43, 47, 61)})
    end)
    self:Connect(b.MouseLeave, function()
        local base = b:GetAttribute("HubActive") and H:AccentColor()
            or Color3.fromRGB(30, 31, 38)
        self:AnimateUI(b, {BackgroundColor3 = base})
    end)
    self:Connect(
        b.MouseButton1Click,
        callback
    )

    return b
end

function H:Section(parent, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 610, 0, 24)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextColor3 =
        Color3.fromRGB(
            255,
            153,
            70
        )
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = string.upper(tostring(text))
    label.Parent = parent
    return label
end

function H:InfoPanel(parent, height)
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 610, 0, height or 90)
    panel.BackgroundColor3 =
        Color3.fromRGB(
            24,
            25,
            31
        )
    panel.BorderSizePixel = 0
    panel.Parent = parent
    self:Round(panel, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(47, 49, 58)
    stroke.Transparency = 0.45
    stroke.Parent = panel

    return panel
end

function H:RefreshToggleButton(stateKey)
    local rec = self.UI.ToggleButtons[stateKey]

    if not rec or not rec.Button then
        return
    end

    local on = self.State[stateKey] == true
    if rec.LastOn == on then return end
    rec.LastOn = on
    if not rec.Button.Parent then return end
    rec.Button.Text = rec.Label .. "  •  " .. (on and "ON" or "OFF")
    rec.Button:SetAttribute("HubActive", on)
    self:AnimateUI(rec.Button, {BackgroundColor3 = on
        and H:AccentColor() or Color3.fromRGB(30, 31, 38)})

end

function H:RefreshToggleButtons()
    for stateKey in pairs(self.UI.ToggleButtons) do
        self:RefreshToggleButton(stateKey)
    end
end

function H:Toggle(parent, label, stateKey)
    local b

    b =
        self:Button(
            parent,
            "",
            function()
                local turningOn =
                    not self.State[stateKey]

                if stateKey == "AutoLevelFarm"
                    and turningOn then

                    self.State.AutoLevelFarm = true
                    self.State.AutoFarmMobs = true
                    self.State.AutoWorldBoss = false
                    self.State.AutoQuest = true
                    self.State.AutoAccept = true
                    self.State.SmartProgression = false
                    self.State.AutoEquipCombat = true
                    self.State.AutoParry = true
                    self.State.PerfectBlock = true
                    self.State.PingAwareParry = true
                    self.State.SafeCombat = true
                    self.State.AntiAFK = true
                    self.State.AutoChests = true
                    self.State.AutoDrops = true
                    self.State.AutoLootAfterKill = true

                    -- BUILD 94: stable AFK levelling uses normal M1 only.
                    self.State.InstantKill = false
                    self.Runtime.InstantKillThresholdLocked = false
                    self.Runtime.InstantKillBusy = false
                    self.Runtime.InstantKillTarget = nil

                    self:StopMovement()
                    self:StopAttackHold()
                    self:StopBlocking()

                    self.Data.AutoLevel.CurrentTarget = nil
                    self.Data.AutoLevel.CurrentLevel = 0
                    self.Data.AutoLevel.BossLoopIndex = 0
                    self.Data.AutoLevel.CurrentRecord = nil
                    self.Data.AutoLevel.BossLoopVisited = {}
                    self.Data.AutoLevel.BossLoopCursorKey = nil
                    self.Data.AutoLevel.BossLoopLap = 1
                    self.Data.AutoLevel.BossLoopResumeTarget = nil
                    self.Data.AutoLevel.BossLoopRespawning = false
                    self.Data.AutoLevel.BossLoopRoutes = {}
                    self.Data.AutoLevel.BossLoopBuiltAt = 0
                    self.Data.AutoLevel.BossLoopSkippedUntil = {}
                    self.Data.AutoLevel.BossLoopVisibleCache = nil
                    self.Data.AutoLevel.BossLoopAdvancePending = false
                    self.Data.AutoLevel.BossLoopQuestWasActive = false
                    self.Data.AutoLevel.BossLoopSeenTarget = false
                    self.Data.AutoLevel.BossLoopSeenTargetKey = nil
                    self.Data.AutoLevel.BossLoopLastSeenAt = 0
                    self.Runtime.AutoLevelTargetSetAt = 0

                    self:AutoLevelFarmStep(
                        true
                    )

                elseif stateKey == "AutoQuest"
                    and turningOn then

                    if tostring(self.State.SelectedQuest or "") == "" then
                        self.State.AutoQuest = false
                        self:SetStatus(
                            "Quest Farm • choose a quest first"
                        )
                        self:RefreshToggleButtons()
                        return
                    end

                    -- One movement owner at a time.
                    self.State.SmartProgression = false
                    self.State.AutoFarmMobs = false
                    self.State.AutoWorldBoss = false
                    self.State.AutoQuest = true
                    self.State.AutoAccept = true
                    self.State.AutoEquipCombat = true
                    self.State.AutoParry = true
                    self.State.PerfectBlock = true
                    self.State.PingAwareParry = true
                    self.State.SafeCombat = true
                    self.State.ParrySafetyMs =
                        math.max(
                            tonumber(
                                self.State.ParrySafetyMs
                            ) or 0,
                            90
                        )

                    self.State.RetreatHealthPercent =
                        math.max(
                            tonumber(
                                self.State.RetreatHealthPercent
                            ) or 0,
                            20
                        )

                    self.State.ResumeHealthPercent =
                        math.max(
                            tonumber(
                                self.State.ResumeHealthPercent
                            ) or 0,
                            45
                        )
                    self.State.ParrySafetyMs =
                        math.max(
                            tonumber(self.State.ParrySafetyMs) or 0,
                            60
                        )
                    self.State.SafeCombat = true
                    self.State.MovementType = "Tween"
                    self.State.FarmPosition = "Below"
                    self.State.BelowDepth =
                        math.clamp(
                            tonumber(self.State.BelowDepth) or 2,
                            1,
                            4
                        )

                    self:StopMovement()
                    self:StopAttackHold()
                    self:StopBlocking()
                    self.Runtime.AcceptAttempt = nil
                    self:ResetDialogueSession()

                elseif stateKey == "AutoFarmMobs"
                    and turningOn then

                    self.State.AutoLevelFarm = false
                    self.State.KillAura = false

                    if tostring(self.State.SelectedMob or "") == "" then
                        self.State.AutoFarmMobs = false
                        self:SetStatus(
                            "Mob Farm • choose a mob first"
                        )
                        self:RefreshToggleButtons()
                        return
                    end

                    self.State.SmartProgression = false
                    self.State.AutoQuest = false
                    self.State.AutoWorldBoss = false
                    self.State.AutoFarmMobs = true
                    self.State.AutoEquipCombat = true
                    self.State.AutoParry = true
                    self.State.PerfectBlock = true
                    self.State.PingAwareParry = true
                    self.State.SafeCombat = true
                    self.State.ParrySafetyMs =
                        math.max(
                            tonumber(
                                self.State.ParrySafetyMs
                            ) or 0,
                            90
                        )

                    self.State.RetreatHealthPercent =
                        math.max(
                            tonumber(
                                self.State.RetreatHealthPercent
                            ) or 0,
                            20
                        )

                    self.State.ResumeHealthPercent =
                        math.max(
                            tonumber(
                                self.State.ResumeHealthPercent
                            ) or 0,
                            45
                        )
                    self.State.ParrySafetyMs =
                        math.max(
                            tonumber(self.State.ParrySafetyMs) or 0,
                            60
                        )
                    self.State.SafeCombat = true
                    self.State.MovementType = "Tween"
                    self.State.FarmPosition = "Below"
                    self.State.BelowDepth =
                        math.clamp(
                            tonumber(self.State.BelowDepth) or 2,
                            1,
                            4
                        )

                    self:StopMovement()
                    self:StopAttackHold()
                    self:StopBlocking()
                    self:ResetDialogueSession()

                else
                    self.State[stateKey] = turningOn

                    if stateKey == "AutoFarmMobs"
                        and not turningOn then

                        self.State.AutoLevelFarm =
                            false
                    end

                    if stateKey == "AutoLevelFarm"
                        and not turningOn then

                        self.State.AutoFarmMobs =
                            false

                        self:StopSmoothMobTravel()
                        self:StopMovement()
                        self:StopAttackHold()
                        self:StopBlocking()
                    end
                end

                if stateKey == "HoldBossPosition" then
                    self.Runtime.BossOwnershipSample = nil
                    self.Runtime.BossHoldRetryAt = 0
                    if turningOn then self:BossHoldStep()
                    else self:ReleaseBossHold("hold off") end
                    self:UpdateBossOwnershipUI(true)
                elseif stateKey == "HealthGearCycle" then
                    if turningOn then
                        if not self:StartHealthGearCycle() then return end
                    else self:StopHealthGearCycle() end
                elseif stateKey == "RapidHits" then
                    self:RefreshRapidHitSchedule()
                elseif (stateKey == "AutoLevelFarm" or stateKey == "AutoFarmMobs")
                    and not turningOn then
                    self:ReleaseBossHold("waiting")
                    self.Runtime.BossOwnershipSample = nil
                    self:UpdateBossOwnershipUI(true)
                end

                -- BUILD 29 removes Smart Progression as an active feature.
                self.State.SmartProgression = false

                self:RefreshToggleButtons()

                self:SetStatus(
                    label
                    .. " • "
                    .. (
                        self.State[stateKey]
                        and "ON"
                        or "OFF"
                    )
                )
            end,
            210
        )

    self.UI.ToggleButtons[stateKey] = {
        Button = b,
        Label = label,
        StateKey = stateKey,
    }

    self:RefreshToggleButton(stateKey)

    return b
end

function H:Dropdown(parent, label, getOptions, stateKey, onChange)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.fromOffset(650, 40)
    holder.BackgroundTransparency = 1
    holder.Parent = parent
    local head = self:Button(holder,label,function() end,650)
    head.TextXAlignment = Enum.TextXAlignment.Left
    local panel = Instance.new("Frame")
    panel.Position = UDim2.fromOffset(0,44)
    panel.Size = UDim2.fromOffset(650,226)
    panel.BackgroundColor3 = Color3.fromRGB(22,24,31)
    panel.Visible = false
    panel.Parent = holder
    self:Round(panel,8)
    local search = Instance.new("TextBox")
    search.Size=UDim2.fromOffset(630,32);search.Position=UDim2.fromOffset(10,8)
    search.PlaceholderText="Search options…";search.Text="";search.ClearTextOnFocus=false
    search.TextColor3=Color3.new(1,1,1);search.BackgroundColor3=Color3.fromRGB(34,37,46)
    search.Font=Enum.Font.Gotham;search.TextSize=12;search.Parent=panel
    local list=Instance.new("ScrollingFrame")
    list.Size=UDim2.fromOffset(630,174);list.Position=UDim2.fromOffset(10,46)
    list.BackgroundTransparency=1;list.BorderSizePixel=0;list.ScrollBarThickness=4
    list.AutomaticCanvasSize=Enum.AutomaticSize.Y;list.CanvasSize=UDim2.new();list.Parent=panel
    local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,4)
    layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=list
    local function caption()
        local value=tostring(self.State[stateKey] or "")
        local text=value
        for _,opt in ipairs(getOptions()) do
            if tostring(opt.Value)==value then text=opt.Label;break end
        end
        head.Text="  "..label.."  •  "..tostring(text).."  ▾"
    end
    local function render()
        for _,child in ipairs(list:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
        local filter=string.lower(search.Text)
        for index,opt in ipairs(getOptions()) do
            if filter=="" or string.find(string.lower(opt.Label),filter,1,true) then
                local option=Instance.new("TextButton")
                option.Size=UDim2.new(1,-6,0,30);option.LayoutOrder=index
                option.BackgroundColor3=Color3.fromRGB(31,34,42);option.TextColor3=Color3.new(1,1,1)
                option.Text="  "..opt.Label;option.TextXAlignment=Enum.TextXAlignment.Left
                option.Font=Enum.Font.Gotham;option.TextSize=12;option.Parent=list
                option.Activated:Connect(function()
                    self.State[stateKey]=opt.Value
                    if onChange then onChange(opt.Value) end
                    panel.Visible=false;holder.Size=UDim2.fromOffset(650,40);caption()
                end)
            end
        end
    end
    self:Connect(head.Activated,function()
        panel.Visible=not panel.Visible
        holder.Size=UDim2.fromOffset(650,panel.Visible and 274 or 40)
        if panel.Visible then render() end
    end)
    self:Connect(search:GetPropertyChangedSignal("Text"),render)
    caption()
    self.UI.DropdownRefresh=self.UI.DropdownRefresh or {}
    self.UI.DropdownRefresh[stateKey]=caption
    return holder
end

function H:Cycle(parent, label, getList, stateKey)
    local b

    b =
        self:Button(
            parent,
            "",
            function()
                local list = getList()

                if #list == 0 then
                    self:SetStatus(
                        label
                        .. " • no options found"
                    )
                    return
                end

                local cur =
                    self.State[stateKey]

                local idx = 0

                for i, v in ipairs(list) do
                    if v == cur then
                        idx = i
                        break
                    end
                end

                idx = (idx % #list) + 1
                self.State[stateKey] = list[idx]

                self:SafeText(
                    b,
                    label
                    .. " • "
                    .. tostring(list[idx])
                )
            end,
            210
        )

    b.Text =
        label
        .. " • "
        .. tostring(
            self.State[stateKey]
            or "None"
        )

    return b
end


function H:PercentSlider(
    parent,
    label,
    key,
    minValue,
    maxValue,
    step,
    unit,
    onChange
)
    minValue =
        tonumber(minValue)
        or 0

    maxValue =
        tonumber(maxValue)
        or 100

    step =
        tonumber(step)
        or 1

    local holder =
        Instance.new("Frame")

    holder.Size =
        UDim2.new(
            0,
            610,
            0,
            54
        )

    holder.BackgroundColor3 =
        Color3.fromRGB(
            24,
            25,
            31
        )

    holder.BorderSizePixel = 0
    holder.Parent = parent

    self:Round(
        holder,
        9
    )

    local stroke =
        Instance.new("UIStroke")

    stroke.Color =
        Color3.fromRGB(
            47,
            49,
            58
        )

    stroke.Transparency = 0.45
    stroke.Thickness = 1
    stroke.Parent = holder

    local title =
        Instance.new("TextLabel")

    title.Position =
        UDim2.fromOffset(
            12,
            5
        )

    title.Size =
        UDim2.fromOffset(
            465,
            20
        )

    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 11
    title.TextColor3 =
        Color3.fromRGB(
            231,
            232,
            239
        )

    title.TextXAlignment =
        Enum.TextXAlignment.Left

    title.Text =
        tostring(label)

    title.Parent = holder

    local value =
        Instance.new("TextLabel")

    value.Position =
        UDim2.fromOffset(
            492,
            5
        )

    value.Size =
        UDim2.fromOffset(
            104,
            20
        )

    value.BackgroundTransparency = 1
    value.Font = Enum.Font.GothamBold
    value.TextSize = 11
    value.TextColor3 =
        H:AccentColor()

    value.TextXAlignment =
        Enum.TextXAlignment.Right

    value.Parent = holder

    local bar =
        Instance.new("Frame")

    bar.Position =
        UDim2.fromOffset(
            12,
            33
        )

    bar.Size =
        UDim2.fromOffset(
            584,
            9
        )

    bar.BackgroundColor3 =
        Color3.fromRGB(
            43,
            44,
            52
        )

    bar.BorderSizePixel = 0
    bar.Parent = holder

    self:Round(
        bar,
        5
    )

    local fill =
        Instance.new("Frame")

    fill.Size =
        UDim2.fromScale(
            0,
            1
        )

    fill.BackgroundColor3 =
        H:AccentColor()

    fill.BorderSizePixel = 0
    fill.Parent = bar

    self:Round(
        fill,
        5
    )

    local knob =
        Instance.new("Frame")

    knob.AnchorPoint =
        Vector2.new(
            0.5,
            0.5
        )

    knob.Position =
        UDim2.new(
            0,
            0,
            0.5,
            0
        )

    knob.Size =
        UDim2.fromOffset(
            15,
            15
        )

    knob.BackgroundColor3 =
        Color3.fromRGB(
            246,
            247,
            251
        )

    knob.BorderSizePixel = 0
    knob.Parent = bar

    self:Round(
        knob,
        8
    )

    local dragging = false

    local function quantize(v)
        v =
            math.clamp(
                v,
                minValue,
                maxValue
            )

        local steps =
            math.floor(
                (
                    (
                        v
                        - minValue
                    )
                    / step
                )
                + 0.5
            )

        return math.clamp(
            minValue
                + (
                    steps
                    * step
                ),
            minValue,
            maxValue
        )
    end

    local function setFromX(x)
        local absoluteX =
            bar.AbsolutePosition.X

        local width =
            math.max(
                bar.AbsoluteSize.X,
                1
            )

        local alpha =
            math.clamp(
                (
                    x
                    - absoluteX
                )
                / width,
                0,
                1
            )

        local raw =
            minValue
            + (
                (
                    maxValue
                    - minValue
                )
                * alpha
            )

        self.State[key] =
            quantize(
                raw
            )

        if key == "InstantKillMainThreshold" then
            self.Runtime.InstantKillThresholdLocked = false
            if self.Runtime.NextBackgroundM1At == math.huge then
                self.Runtime.NextBackgroundM1At = 0
            end
        end
        if onChange then onChange(self.State[key]) end
    end

    self:Connect(
        bar.InputBegan,
        function(input)
            if input.UserInputType
                == Enum.UserInputType.MouseButton1
                or input.UserInputType
                == Enum.UserInputType.Touch then

                dragging = true

                setFromX(
                    input.Position.X
                )
            end
        end
    )

    self:Connect(
        knob.InputBegan,
        function(input)
            if input.UserInputType
                == Enum.UserInputType.MouseButton1
                or input.UserInputType
                == Enum.UserInputType.Touch then

                dragging = true

                setFromX(
                    input.Position.X
                )
            end
        end
    )

    self:Connect(
        self.S.UserInputService.InputChanged,
        function(input)
            if not dragging then
                return
            end

            if input.UserInputType
                == Enum.UserInputType.MouseMovement
                or input.UserInputType
                == Enum.UserInputType.Touch then

                setFromX(
                    input.Position.X
                )
            end
        end
    )

    self:Connect(
        self.S.UserInputService.InputEnded,
        function(input)
            if input.UserInputType
                == Enum.UserInputType.MouseButton1
                or input.UserInputType
                == Enum.UserInputType.Touch then

                dragging = false
            end
        end
    )

    local lastValue = nil

    self:Connect(
        self.S.RunService.Heartbeat,
        function()
            local current =
                quantize(
                    tonumber(
                        self.State[key]
                    )
                    or minValue
                )

            if current ~= self.State[key] then
                self.State[key] =
                    current
            end

            if current == lastValue then
                return
            end

            lastValue =
                current

            local alpha =
                (
                    current
                    - minValue
                )
                / math.max(
                    maxValue
                        - minValue,
                    1
                )

            fill.Size =
                UDim2.fromScale(
                    alpha,
                    1
                )

            knob.Position =
                UDim2.new(
                    alpha,
                    0,
                    0.5,
                    0
                )

            self:SafeText(
                value,
                tostring(
                    math.floor(
                        current
                        + 0.5
                    )
                )
                .. (unit or "%")
            )
        end
    )

    return holder
end

function H:NumberAdjust(
    parent,
    label,
    key,
    step,
    min,
    max
)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(0, 210, 0, 34)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local minus =
        self:Button(
            holder,
            "-",
            function()
                self.State[key] =
                    math.clamp(
                        self.State[key] - step,
                        min,
                        max
                    )
            end,
            34
        )

    minus.Position =
        UDim2.fromOffset(
            0,
            0
        )

    local value = Instance.new("TextLabel")
    value.Position = UDim2.fromOffset(40, 0)
    value.Size = UDim2.fromOffset(130, 34)
    value.BackgroundColor3 =
        Color3.fromRGB(
            29,
            29,
            35
        )
    value.BorderSizePixel = 0
    value.Font = Enum.Font.Gotham
    value.TextSize = 11
    value.TextColor3 = Color3.new(1, 1, 1)
    value.Parent = holder
    self:Round(value, 7)

    local plus =
        self:Button(
            holder,
            "+",
            function()
                self.State[key] =
                    math.clamp(
                        self.State[key] + step,
                        min,
                        max
                    )
            end,
            34
        )

    plus.Position =
        UDim2.fromOffset(
            176,
            0
        )

    local lastValue
    self:Connect(
        self.S.RunService.Heartbeat,
        function()
            if lastValue == self.State[key] then return end
            lastValue = self.State[key]
            self:SafeText(
                value,
                label
                .. " • "
                .. tostring(
                    self.State[key]
                )
            )
        end
    )

    return holder
end

-- ============================================================
-- BUILD UI
-- ============================================================

function H:SetMenuVisible(visible)
    visible = visible == true
    self.State.Visible = visible
    if visible and self.UI.Scale then
        self.UI.Scale.Scale = (self.UI.FitScale or 1) * 0.97
        self:AnimateUI(self.UI.Scale, {Scale = self.UI.FitScale or 1}, 0.16)
    end

    pcall(
        function()
            if self.UI.Main then
                self.UI.Main.Visible =
                    visible
            end
        end
    )

    pcall(
        function()
            if self.UI.Launcher then
                self.UI.Launcher.Visible =
                    not visible
            end
        end
    )
end

function H:BuildUI()
    -- Some executors lose CoreGui/Plugin capability on spawned runtime threads.
    -- Keep all live UI under PlayerGui so farm/quest loops can update it safely.
    pcall(function()
        local old =
            self.PlayerGui:FindFirstChild(
                "ThumbsHubNewGame"
            )

        if old then
            old:Destroy()
        end
    end)

    -- Best-effort cleanup of an older CoreGui build. Never rely on CoreGui
    -- after this point.
    pcall(function()
        local old =
            self.S.CoreGui:FindFirstChild(
                "ThumbsHubNewGame"
            )

        if old then
            old:Destroy()
        end
    end)

    local gui = Instance.new("ScreenGui")
    gui.Name = "ThumbsHubNewGame"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = self.PlayerGui

    self.UI.Gui = gui

    local main = Instance.new("Frame")
    main.Size = UDim2.fromOffset(920, 570)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.BackgroundColor3 =
        Color3.fromRGB(
            13,
            14,
            18
        )
    main.BorderSizePixel = 0
    main.Active = true
    main.Parent = gui
    self:Round(main, 13)

    local stroke = Instance.new("UIStroke")
    stroke.Color =
        H:AccentColor()
    stroke.Thickness = 1.4
    stroke.Parent = main

    self.UI.Main = main
    local uiScale = Instance.new("UIScale")
    uiScale.Parent = main
    self.UI.Scale = uiScale
    local function fitWindow()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local size = camera.ViewportSize
        local scale = math.min(tonumber(self.State.UIScale) or 1, (size.X - 24) / 920, (size.Y - 24) / 570)
        uiScale.Scale = math.max(0.1, scale)
        self.UI.FitScale = uiScale.Scale
        main.Position = UDim2.fromScale(0.5, 0.5)
    end
    self.UI.FitWindow=fitWindow
    fitWindow()
    local viewportConnection
    local function watchViewport()
        if viewportConnection then viewportConnection:Disconnect() end
        if workspace.CurrentCamera then
            viewportConnection = self:Connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), fitWindow)
        end
        fitWindow()
    end
    self:Connect(workspace:GetPropertyChangedSignal("CurrentCamera"), watchViewport)
    watchViewport()

    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, -24, 0, 2)
    accentLine.Position = UDim2.fromOffset(12, 0)
    accentLine.BackgroundColor3 = H:AccentColor()
    accentLine.BorderSizePixel = 0
    accentLine.Parent = main
    self:Round(accentLine, 2)

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(22, 14)
    title.Size = UDim2.new(1, -36, 0, 32)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "ThumbsHub"
    title.Active = true
    title.Parent = main

    local sub = Instance.new("TextLabel")
    sub.Position = UDim2.fromOffset(22, 43)
    sub.Size = UDim2.new(1, -36, 0, 20)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 11
    sub.TextColor3 =
        Color3.fromRGB(
            155,
            155,
            165
        )
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Text =
        "Automation • Combat • Loot • Travel • Right Shift to hide"
    sub.Parent = main

    local liveChip = Instance.new("TextLabel")
    liveChip.Size = UDim2.fromOffset(125, 26)
    liveChip.Position = UDim2.new(1, -174, 0, 17)
    liveChip.BackgroundColor3 = Color3.fromRGB(25, 31, 27)
    liveChip.BorderSizePixel = 0
    liveChip.Font = Enum.Font.GothamMedium
    liveChip.TextSize = 10
    liveChip.TextColor3 = Color3.fromRGB(113, 231, 157)
    liveChip.Text = "● LIVE  •  READY"
    liveChip.Parent = main
    self:Round(liveChip, 13)
    self.UI.LiveChip = liveChip

    -- Same hide behaviour as the other ThumbsHub menus:
    -- X hides the full window and leaves a draggable TH launcher.
    local hideButton =
        Instance.new("TextButton")

    hideButton.Size =
        UDim2.fromOffset(
            30,
            30
        )

    hideButton.Position =
        UDim2.new(
            1,
            -42,
            0,
            12
        )

    hideButton.BackgroundColor3 =
        Color3.fromRGB(
            31,
            31,
            38
        )

    hideButton.BorderSizePixel = 0
    hideButton.Font =
        Enum.Font.GothamBold
    hideButton.TextSize = 15
    hideButton.TextColor3 =
        Color3.fromRGB(
            230,
            230,
            235
        )
    hideButton.Text = "×"
    hideButton.Parent = main
    self:Round(hideButton, 7)

    local launcher =
        Instance.new("TextButton")

    launcher.Name =
        "ThumbsHubLauncher"
    launcher.Size =
        UDim2.fromOffset(
            48,
            48
        )
    launcher.Position =
        UDim2.new(
            0,
            24,
            0.5,
            -24
        )
    launcher.BackgroundColor3 =
        Color3.fromRGB(
            20,
            20,
            24
        )
    launcher.BorderSizePixel = 0
    launcher.Font =
        Enum.Font.GothamBold
    launcher.TextSize = 15
    launcher.TextColor3 =
        H:AccentColor()
    launcher.Text = "TH"
    launcher.Visible = false
    launcher.Active = true
    launcher.Parent = gui
    self:Round(launcher, 12)

    local launcherStroke =
        Instance.new("UIStroke")

    launcherStroke.Color =
        H:AccentColor()
    launcherStroke.Thickness = 1.2
    launcherStroke.Parent =
        launcher

    self.UI.Launcher =
        launcher

    self:Connect(
        hideButton.MouseButton1Click,
        function()
            self:SetMenuVisible(false)
        end
    )

    self:Connect(
        launcher.MouseButton1Click,
        function()
            self:SetMenuVisible(true)
        end
    )

    -- Draggable TH launcher.
    do
        local dragging = false
        local _moved = false
        local startMouse
        local startPos

        self:Connect(
            launcher.InputBegan,
            function(input)
                if input.UserInputType
                    == Enum.UserInputType.MouseButton1 then

                    dragging = true
                    _moved = false
                    startMouse =
                        input.Position
                    startPos =
                        launcher.Position
                end
            end
        )

        self:Connect(
            self.S.UserInputService.InputChanged,
            function(input)
                if dragging
                    and input.UserInputType
                        == Enum.UserInputType.MouseMovement then

                    local delta =
                        input.Position
                        - startMouse

                    if delta.Magnitude > 3 then
                        _moved = true
                    end

                    launcher.Position =
                        UDim2.new(
                            startPos.X.Scale,
                            startPos.X.Offset
                                + delta.X,
                            startPos.Y.Scale,
                            startPos.Y.Offset
                                + delta.Y
                        )
                end
            end
        )

        self:Connect(
            self.S.UserInputService.InputEnded,
            function(input)
                if input.UserInputType
                    == Enum.UserInputType.MouseButton1 then

                    dragging = false
                end
            end
        )
    end

    local nav = Instance.new("ScrollingFrame")
    nav.AutomaticCanvasSize=Enum.AutomaticSize.Y
    nav.CanvasSize=UDim2.new()
    nav.ScrollBarThickness=3
    nav.Position = UDim2.fromOffset(16, 82)
    nav.Size = UDim2.fromOffset(162, 430)
    nav.BackgroundColor3 =
        Color3.fromRGB(
            18,
            19,
            24
        )
    nav.BorderSizePixel = 0
    nav.Parent = main
    self:Round(nav, 9)

    local navLayout = Instance.new("UIListLayout")
    navLayout.Padding = UDim.new(0, 7)
    navLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navLayout.HorizontalAlignment =
        Enum.HorizontalAlignment.Center
    navLayout.Parent = nav

    local navPad = Instance.new("UIPadding")
    navPad.PaddingTop = UDim.new(0, 10)
    navPad.Parent = nav

    local body = Instance.new("Frame")
    body.Position = UDim2.fromOffset(192, 82)
    body.Size = UDim2.fromOffset(710, 430)
    body.BackgroundColor3 =
        Color3.fromRGB(
            21,
            21,
            26
        )
    body.BorderSizePixel = 0
    body.ClipsDescendants = true
    body.Parent = main
    self:Round(body, 9)

    local pages = {}
    local tabButtons = {}

    local function makePage(name)
        local sc = Instance.new("ScrollingFrame")
        sc.Name = name
        sc.Size = UDim2.fromScale(1, 1)
        sc.BackgroundTransparency = 1
        sc.BorderSizePixel = 0
        sc.ScrollBarThickness = 4
        sc.AutomaticCanvasSize =
            Enum.AutomaticSize.Y
        sc.CanvasSize = UDim2.new()
        sc.Visible = false
        sc.Parent = body

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = sc
        local order = 0
        self:Connect(sc.ChildAdded, function(child)
            if child:IsA("GuiObject") then
                order = order + 1
                child.LayoutOrder = order
            end
        end)

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 14)
        pad.PaddingLeft = UDim.new(0, 14)
        pad.PaddingRight = UDim.new(0, 14)
        pad.PaddingBottom = UDim.new(0, 14)
        pad.Parent = sc

        pages[name] = sc
        return sc
    end

    local function show(name)
        for pageName, page in pairs(pages) do page.Visible = pageName == name end
        for pageName, button in pairs(tabButtons) do
            local active = pageName == name
            button:SetAttribute("HubActive", active)
            self:AnimateUI(button, {BackgroundColor3 = active
                and H:AccentColor() or Color3.fromRGB(30, 31, 38)})
        end
        local page = pages[name]
        if page then
            page.Position = UDim2.fromOffset(0, 5)
            self:AnimateUI(page, {Position = UDim2.fromOffset(0, 0)}, 0.16)
        end
    end

    local tabs = {
        "Home",
        "Farm",
        "Bosses",
        "Combat",
        "Travel",
        "ESP",
        "Player",
        "Misc",
        "Visuals",
        "Servers",
        "Profiles",
        "Tools",
    }

    for index, name in ipairs(tabs) do
        local _page = makePage(name)

        tabButtons[name] = self:Button(
            nav,
            name,
            function()
                show(name)
            end,
            140
        )
        tabButtons[name].LayoutOrder = index
    end

    -- HOME
    do
        local p = pages.Home
        local actions = Instance.new("Frame")
        actions.Size = UDim2.fromOffset(650, 40)
        actions.BackgroundTransparency = 1
        actions.Parent = p
        local actionLayout = Instance.new("UIListLayout")
        actionLayout.FillDirection = Enum.FillDirection.Horizontal
        actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
        actionLayout.Padding = UDim.new(0, 10)
        actionLayout.Parent = actions
        local actionOrder = 0
        self:Connect(actions.ChildAdded, function(child)
            if child:IsA("GuiObject") then
                actionOrder = actionOrder + 1
                child.LayoutOrder = actionOrder
            end
        end)

        self:Section(
            p,
            "Dashboard"
        )

        local dashboard = Instance.new("TextLabel")
        dashboard.Size = UDim2.new(0, 650, 0, 140)
        dashboard.BackgroundColor3 = Color3.fromRGB(24, 25, 31)
        dashboard.BorderSizePixel = 0
        dashboard.Font = Enum.Font.Gotham
        dashboard.TextSize = 12
        dashboard.TextColor3 = Color3.fromRGB(232, 233, 238)
        dashboard.TextWrapped = true
        dashboard.TextXAlignment = Enum.TextXAlignment.Left
        dashboard.TextYAlignment = Enum.TextYAlignment.Top
        dashboard.Text = " Loading dashboard..."
        dashboard.Parent = p
        self:Round(dashboard, 10)
        self.UI.HomeSummary = dashboard
        local metrics = Instance.new("TextLabel")
        metrics.Size = UDim2.fromOffset(650, 66)
        metrics.BackgroundColor3 = Color3.fromRGB(25, 31, 39)
        metrics.BorderSizePixel = 0
        metrics.Font = Enum.Font.GothamMedium
        metrics.TextSize = 12
        metrics.TextColor3 = Color3.fromRGB(139, 220, 203)
        metrics.TextXAlignment = Enum.TextXAlignment.Left
        metrics.Text = "Measuring network timing…"
        metrics.Parent = p
        local inset = Instance.new("UIPadding")
        inset.PaddingLeft = UDim.new(0, 14)
        inset.Parent = metrics
        self:Round(metrics, 10)
        self.UI.NetworkSummary = metrics

        self:Button(
            actions,
            "▶ Start Mob Farm",
            function()
                if tostring(self.State.SelectedMob or "") == "" then
                    self:SetStatus("Mob Farm • choose a mob on the Farm page")
                    return
                end

                self:StopMovement()
                self:StopAttackHold()
                self:StopBlocking()
                self:ResetDialogueSession()

                self.State.SmartProgression = false
                self.State.AutoQuest = false
                self.State.AutoFarmMobs = true
                self.State.AutoWorldBoss = false
                self.State.AutoEquipCombat = true
                self.State.AutoParry = true
                self.State.PerfectBlock = true
                self.State.PingAwareParry = true
                self.State.SafeCombat = true
                self.State.MovementType = "Tween"

                self:RefreshToggleButtons()
                self:SetStatus("Mob Farm • STARTED • overhead aura movement")
            end,
            210
        )

        self:Button(
            actions,
            "■ Stop Automation",
            function()
                self.State.SmartProgression = false
                self.State.AutoQuest = false
                self.State.AutoLevelFarm = false
                self.State.AutoFarmMobs = false
                self.State.AutoWorldBoss = false
                self:StopAttackHold()
                self:StopBlocking()
                self:StopMovement()
                self:RefreshToggleButtons()
                self:StopAllAutomation()
                self:SetStatus("Automation • STOPPED")
            end,
            210
        )

        self:Button(
            actions,
            "Discord",
            function()
                self:CopyDiscordInvite()
            end,
            210
        )
    end

    -- FARM
    do
        local p = pages.Farm

        self:Section(p, "AFK Boss Loop")

        self:Toggle(
            p,
            "Boss Farm",
            "AutoLevelFarm"
        )

        self:Dropdown(
            p,
            "Farm Bosses",
            function() return self:BossFarmOptions() end,
            "BossFarmChoice",
            function(value)
                local store = self.Data.AutoLevel
                store.CurrentTarget = nil
                store.CurrentRecord = nil
                store.CurrentLevel = 0
                store.BossLoopIndex = 0
                store.BossLoopVisited = {}
                store.BossLoopCursorKey = nil
                store.BossLoopLap = 1
                store.BossLoopResumeTarget = nil
                store.BossLoopRespawning = false
                store.BossLoopAdvancePending = false
                store.BossLoopSkippedUntil = {}
                self.State.SelectedMob = ""
                self.Data.CurrentFarmTarget = nil
                self.Runtime.AttackTarget = nil
                self:StopBossHover()
                self:StopSmoothMobTravel()
                self:StopMovement()
                if self.State.AutoLevelFarm then
                    self:AutoLevelFarmStep(true)
                else
                    self:SetStatus("Boss Loop • selected " .. tostring(value))
                end
            end
        )

        self:Toggle(p, "Instant Boss Travel", "BossInstantTravel")
        self:Toggle(p, "Hover Below Boss", "BossHoverFarm")

        self:Toggle(p, "Hold Boss Position", "HoldBossPosition")
        self.UI.BossOwnershipButton = self:Button(
            p, "Ownership • NO TARGET  ↻",
            function() self:UpdateBossOwnershipUI(true) end, 610
        )
        self:UpdateBossOwnershipUI(false)
        self:Toggle(p, "Rapid Hits", "RapidHits")
        self:PercentSlider(p, "Rapid hit interval", "RapidHitIntervalMs", 10, 200, 5, " ms",
            function() self:RefreshRapidHitSchedule() end)
        local rapidInfo = self:InfoPanel(p, 42)
        local rapidNote = Instance.new("TextLabel")
        rapidNote.Position = UDim2.fromOffset(12, 4)
        rapidNote.Size = UDim2.new(1, -24, 1, -8)
        rapidNote.BackgroundTransparency = 1
        rapidNote.Font = Enum.Font.Gotham
        rapidNote.TextSize = 10
        rapidNote.TextColor3 = Color3.fromRGB(180, 183, 194)
        rapidNote.TextXAlignment = Enum.TextXAlignment.Left
        rapidNote.TextWrapped = true
        rapidNote.Text = "Lower ms requests punches more often; game cooldowns still apply. Boss holding needs OWNED status and releases when ownership is lost."
        rapidNote.Parent = rapidInfo

        self:Section(p, "God Mode")
        self:Toggle(p, "God Mode", "HealthGearCycle")
        self:PercentSlider(p, "Added gear delay", "HealthGearDelayMs", 0, 250, 5, " ms",
            function() self:RefreshHealthGearSpeed() end)
        local gearInfo = self:InfoPanel(p, 58)
        local gearNote = Instance.new("TextLabel")
        gearNote.Position = UDim2.fromOffset(12, 4)
        gearNote.Size = UDim2.new(1, -24, 1, -8)
        gearNote.BackgroundTransparency = 1
        gearNote.Font = Enum.Font.Gotham
        gearNote.TextSize = 11
        gearNote.TextColor3 = Color3.fromRGB(255, 203, 120)
        gearNote.TextXAlignment = Enum.TextXAlignment.Left
        gearNote.TextWrapped = true
        gearNote.Text = "REQUIRED: Equip at least one item that increases Health in a STATS slot for recovery to work. Cycles your worn Stats gear off/on. 0 ms removes extra pauses; server response time still applies."
        gearNote.Parent = gearInfo
        local gearStatusInfo = self:InfoPanel(p, 40)
        local gearStatus = Instance.new("TextLabel")
        gearStatus.Position = UDim2.fromOffset(12, 4)
        gearStatus.Size = UDim2.new(1, -24, 1, -8)
        gearStatus.BackgroundTransparency = 1
        gearStatus.Font = Enum.Font.Gotham
        gearStatus.TextSize = 10
        gearStatus.TextColor3 = Color3.fromRGB(180, 183, 194)
        gearStatus.TextXAlignment = Enum.TextXAlignment.Left
        gearStatus.TextWrapped = true
        gearStatus.Text = "OFF • Ready • Stats slots only"
        gearStatus.Parent = gearStatusInfo
        self.UI.HealthGearStatus = gearStatus
        self:Button(p, "Restore Stats Gear", function() self:RestoreHealthGear() end, 610)

        self:NumberAdjust(p, "Boss X Offset", "BossHoverXOffset", 0.25, -1.5, 1.5)
        self:NumberAdjust(p, "Boss Y Offset", "BossHoverYOffset", 0.25, 0, 5)
        self:NumberAdjust(p, "Boss Z Offset", "BossHoverZOffset", 0.25, -1.5, 1.5)
        self:NumberAdjust(p, "Boss Distance", "BossHoverDistance", 0.25, 3, 9)

        local autoLevelInfo =
            self:InfoPanel(
                p,
                68
            )

        local autoLevelText =
            Instance.new(
                "TextLabel"
            )

        autoLevelText.Position =
            UDim2.fromOffset(
                12,
                5
            )

        autoLevelText.Size =
            UDim2.new(
                1,
                -24,
                1,
                -10
            )

        autoLevelText.BackgroundTransparency = 1
        autoLevelText.Font = Enum.Font.Gotham
        autoLevelText.TextSize = 10
        autoLevelText.TextWrapped = true
        autoLevelText.TextXAlignment =
            Enum.TextXAlignment.Left
        autoLevelText.TextYAlignment =
            Enum.TextYAlignment.Center
        autoLevelText.TextColor3 =
            Color3.fromRGB(
                180,
                183,
                194
            )

        autoLevelText.Text =
            "OFF • All Bosses visits every discovered world boss once per circuit. Returns to the same boss after your death. Instant arrival, stable below position, loot, then the next boss."

        autoLevelText.Parent =
            autoLevelInfo

        self.UI.AutoLevelInfo =
            autoLevelText

        self:Button(
            p,
            "↻ Refresh Boss Circuit",
            function()
                self.Data.AutoLevel.BuiltAt = 0
                self.Data.AutoLevel.CurrentTarget = nil
                self.Data.AutoLevel.CurrentLevel = 0
                self.Data.AutoLevel.BossLoopBuiltAt = 0
                self.Data.AutoLevel.BossLoopRoutes = {}
                self.Data.AutoLevel.BossLoopIndex = 0
                    self.Data.AutoLevel.CurrentRecord = nil
                    self.Data.AutoLevel.BossLoopVisited = {}
                    self.Data.AutoLevel.BossLoopCursorKey = nil
                    self.Data.AutoLevel.BossLoopLap = 1
                    self.Data.AutoLevel.BossLoopResumeTarget = nil
                    self.Data.AutoLevel.BossLoopRespawning = false
                self.Data.AutoLevel.BossLoopSkippedUntil = {}
                self.Data.AutoLevel.BossLoopVisibleCache = nil
                self.Data.AutoLevel.BossLoopAdvancePending = false
                self.Runtime.AutoLevelTargetSetAt = 0

                self:BuildAutoLevelCandidates(
                    true
                )

                self:BuildEligibleBossLoop(
                    true
                )

                if self.State.AutoLevelFarm then
                    self:AutoLevelFarmStep(
                        true
                    )
                else
                    local target,
                        rec =
                        self:ChooseAutoLevelTarget()

                    self:SetStatus(
                        "Auto Level recommendation • "
                        .. tostring(
                            target
                            or "none found"
                        )
                        .. (
                            rec
                            and (
                                " • unlock Lv "
                                .. tostring(
                                    rec.RequiredLevel
                                    or "?"
                                )
                            )
                            or ""
                        )
                    )

                    self:UpdateAutoLevelInfo(
                        target,
                        rec
                    )
                end
            end,
            650
        )

        self:Section(p, "Manual Mob Farm")

        self:Dropdown(
            p,
            "Mob",
            function()
                return self:MobOptions()
            end,
            "SelectedMob",
            function(value)
                self:StopMovement()
                self:StopAttackHold()
                self:StopBlocking()

                -- Changing enemy pauses enemy farm so selection cannot suddenly
                -- redirect an active tween.
                self.State.AutoLevelFarm = false
                self.State.AutoFarmMobs = false
                self.State.SmartProgression = false
                self:RefreshToggleButtons()

                if tostring(value or "") == "" then
                    self:SetStatus("Mob Farm • no mob selected")
                else
                    self:SetStatus(
                        "Mob Farm • selected "
                        .. tostring(value)
                        .. " • press Farm Selected Mob"
                    )
                end
            end
        )

        self:Button(
            p,
            "↻ Refresh Mob / Boss Lists",
            function()
                self.Runtime.ManualMobOptionsRefreshAt = 0
                self.Runtime.ManualBossOptionsRefreshAt = 0
                self:RefreshMobs()
                self:RefreshBosses()

                self:SetStatus(
                    "Discovery • "
                    .. tostring(math.max(0, #(self.Data.MobNames or {}) - 1))
                    .. " mobs • "
                    .. tostring(#(self.Data.BossCodes or {}))
                    .. " bosses remembered"
                )
            end,
            650
        )

        self:Toggle(
            p,
            "Farm Selected Mob",
            "AutoFarmMobs"
        )

        local overheadInfo =
            self:InfoPanel(
                p,
                44
            )

        local overheadText =
            Instance.new("TextLabel")

        overheadText.Size =
            UDim2.new(
                1,
                -24,
                1,
                -8
            )

        overheadText.Position =
            UDim2.fromOffset(
                12,
                4
            )

        overheadText.BackgroundTransparency = 1
        overheadText.Font = Enum.Font.Gotham
        overheadText.TextSize = 10
        overheadText.TextWrapped = true
        overheadText.TextXAlignment = Enum.TextXAlignment.Left
        overheadText.TextYAlignment = Enum.TextYAlignment.Center
        overheadText.TextColor3 = Color3.fromRGB(180, 183, 194)
        overheadText.Text =
            "Regular Mob Farm uses ground close melee. Boss Loop can hover below its live boss while using normal Combat M1. Instant Kill stays disabled in Auto Level."

        overheadText.Parent =
            overheadInfo

        self:Toggle(
            p,
            "Instant Kill",
            "InstantKill"
        )

        self:PercentSlider(
            p,
            "Instant Kill HP %  •  Keep 10% Normal World / 100% Dungeons",
            "InstantKillMainThreshold",
            1,
            100,
            1
        )

        local executeInfo =
            self:InfoPanel(
                p,
                48
            )

        local executeInfoText =
            Instance.new("TextLabel")

        executeInfoText.Position =
            UDim2.fromOffset(
                12,
                5
            )

        executeInfoText.Size =
            UDim2.new(
                1,
                -24,
                1,
                -10
            )

        executeInfoText.BackgroundTransparency = 1
        executeInfoText.Font = Enum.Font.Gotham
        executeInfoText.TextSize = 10
        executeInfoText.TextWrapped = true
        executeInfoText.TextXAlignment =
            Enum.TextXAlignment.Left
        executeInfoText.TextYAlignment =
            Enum.TextYAlignment.Center
        executeInfoText.TextColor3 =
            Color3.fromRGB(
                180,
                183,
                194
            )
        executeInfoText.Text =
            "Recommended: keep 10% in Normal World and 100% in Dungeons."
        executeInfoText.Parent =
            executeInfo

        self:Section(p, "Loot & Movement")

        self:Toggle(
            p,
            "Auto Collect Chests",
            "AutoChests"
        )

        self:Toggle(
            p,
            "Auto Pick Up Drops",
            "AutoDrops"
        )

        self:Cycle(
            p,
            "Movement",
            function()
                -- Manual quest/enemy farm is intentionally Tween-only so no
                -- second movement controller can fight it.
                return {"Tween"}
            end,
            "MovementType"
        )

        self:Cycle(
            p,
            "Farm Position",
            function()
                return {"Below", "Behind", "Front", "Above"}
            end,
            "FarmPosition"
        )

        self:Toggle(
            p,
            "Loot After Kill",
            "AutoLootAfterKill"
        )

        self:NumberAdjust(
            p,
            "Distance",
            "Distance",
            1,
            1,
            25
        )

        self:NumberAdjust(p, "Below Depth", "BelowDepth", 0.25, 1, 4)

        self:NumberAdjust(
            p,
            "Height",
            "Height",
            1,
            -10,
            25
        )

        self:NumberAdjust(
            p,
            "Tween Speed",
            "TweenSpeed",
            25,
            25,
            500
        )
    end

    -- BOSSES
    do
        local p = pages.Bosses

        self:Section(p, "World Boss Radar")

        self:Toggle(
            p,
            "Auto World Bosses",
            "AutoWorldBoss"
        )

        self:Cycle(
            p,
            "Boss Mode",
            function()
                return {"Selected", "Nearest Alive"}
            end,
            "BossMode"
        )

        self:Dropdown(
            p,
            "Boss",
            function()
                return self:BossOptions()
            end,
            "SelectedBoss",
            function(value)
                self:SetStatus("Boss • selected " .. tostring(value))
            end
        )

        self:Toggle(
            p,
            "Auto Open Boss Chest",
            "AutoBossChest"
        )

        self:Toggle(
            p,
            "Boss ESP",
            "BossESP"
        )

        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(0, 650, 0, 155)
        info.BackgroundColor3 =
            Color3.fromRGB(
                28,
                28,
                34
            )
        info.BorderSizePixel = 0
        info.Font = Enum.Font.Gotham
        info.TextSize = 12
        info.TextColor3 =
            Color3.fromRGB(
                225,
                225,
                230
            )
        info.TextWrapped = true
        info.TextXAlignment =
            Enum.TextXAlignment.Left
        info.TextYAlignment =
            Enum.TextYAlignment.Top
        info.Parent = p
        self:Round(info, 8)

        self.UI.BossInfo = info
    end

    -- COMBAT
    do
        local p = pages.Combat

        self:Section(p, "Direct Combat")

        self:Toggle(
            p,
            "Auto M1",
            "AutoM1"
        )

        self:Toggle(
            p,
            "Auto Equip Combat",
            "AutoEquipCombat"
        )

        self:Section(p, "Defense")

        self:Toggle(
            p,
            "Smart Block / Parry",
            "AutoParry"
        )

        self:Toggle(
            p,
            "Guard Between Attacks",
            "PerfectBlock"
        )

        self:Toggle(
            p,
            "Adaptive Ping Timing",
            "PingAwareParry"
        )

        self:NumberAdjust(
            p,
            "Parry Safety ms",
            "ParrySafetyMs",
            5,
            0,
            100
        )

        self:Toggle(
            p,
            "Boss Safety Mode",
            "BossSafetyMode"
        )

        self:NumberAdjust(
            p,
            "Boss Guard Range",
            "BossGuardRange",
            2,
            12,
            40
        )

        self:Toggle(
            p,
            "Safe Combat",
            "SafeCombat"
        )

        self:NumberAdjust(
            p,
            "Retreat HP %",
            "RetreatHealthPercent",
            5,
            10,
            70
        )

        self:NumberAdjust(
            p,
            "Resume HP %",
            "ResumeHealthPercent",
            5,
            30,
            100
        )

        self:Section(p, "Skills")

        self:Toggle(
            p,
            "Smart Auto Skill",
            "SmartSkill"
        )

        self:Cycle(
            p,
            "Skill",
            function()
                return self.Data.SkillNames
            end,
            "SelectedSkill"
        )
    end

    -- PLAYER
    do
        local p = pages.Player

        self:Section(p, "Movement")

        self:Toggle(
            p,
            "WalkSpeed",
            "WalkSpeedEnabled"
        )

        self:NumberAdjust(
            p,
            "WalkSpeed",
            "WalkSpeed",
            2,
            16,
            80
        )

        self:Toggle(
            p,
            "Infinite Jump",
            "InfiniteJump"
        )

        self:Toggle(
            p,
            "Noclip",
            "Noclip"
        )

        self:Toggle(
            p,
            "Fly",
            "Fly"
        )

        self:NumberAdjust(
            p,
            "Fly Speed",
            "FlySpeed",
            10,
            20,
            200
        )
    end

    -- TRAVEL
    do
        local p = pages.Travel

        self:Section(p, "NPC Travel")

        self:Cycle(
            p,
            "NPC",
            function()
                return self.Data.NPCs.Names or {}
            end,
            "SelectedNPC"
        )

        self:Button(
            p,
            "Tween To NPC",
            function()
                self:TravelSelectedNPC()
            end,
            240
        )

        self:Button(
            p,
            "Tween To Quest NPC",
            function()
                self:TravelQuestNPC()
            end,
            240
        )

        self:Section(p, "Places & Shops")

        self:Cycle(
            p,
            "Place",
            function()
                return self.Data.Places.Names or {}
            end,
            "SelectedPlace"
        )

        self:Button(
            p,
            "Tween To Place",
            function()
                self:TravelSelectedPlace()
            end,
            240
        )

        self:Button(
            p,
            "Refresh Travel List",
            function()
                self:RefreshTravel()
                self:SetStatus("Travel list refreshed")
            end,
            240
        )
    end

    -- ESP
    do
        local p = pages.ESP

        self:Section(p, "World ESP")

        self:Toggle(
            p,
            "Mob ESP",
            "MobESP"
        )

        self:Toggle(
            p,
            "Boss ESP",
            "BossESP"
        )

        self:Toggle(
            p,
            "Quest Target ESP",
            "QuestTargetESP"
        )

        self:Toggle(
            p,
            "Chest ESP",
            "ChestESP"
        )

        self:Toggle(
            p,
            "Drop ESP",
            "DropESP"
        )

        self:Section(p, "ESP Details")

        self:Toggle(
            p,
            "Name Labels",
            "ESPLabels"
        )

        self:Toggle(
            p,
            "Show Health",
            "ESPHealth"
        )

        self:Toggle(
            p,
            "Show Distance",
            "ESPDistance"
        )
    end

    -- MISC
    do
        local p = pages.Misc

        self:Section(p, "Reliability")

        self:Toggle(
            p,
            "Anti AFK",
            "AntiAFK"
        )

        self:Toggle(
            p,
            "Auto Reconnect",
            "AutoReconnect"
        )

        self:Toggle(
            p,
            "Creator Group Detect",
            "GroupDetect"
        )

        self:Section(p, "Server")

        self:Button(
            p,
            "Copy Job ID",
            function()
                self:CopyJob()
            end,
            210
        )

        local box = Instance.new("TextBox")
        box.Size = UDim2.fromOffset(380, 34)
        box.BackgroundColor3 =
            Color3.fromRGB(
                29,
                29,
                35
            )
        box.BorderSizePixel = 0
        box.Font = Enum.Font.Gotham
        box.TextSize = 11
        box.TextColor3 = Color3.new(1, 1, 1)
        box.PlaceholderText = "Paste Job ID"
        box.Text = ""
        box.ClearTextOnFocus = false
        box.Parent = p
        self:Round(box, 7)

        self:Button(
            p,
            "Join Job ID",
            function()
                self:JoinJob(
                    box.Text
                )
            end,
            210
        )

        self:Button(
            p,
            "Reconnect",
            function()
                self:Reconnect()
            end,
            210
        )

        self:Section(p, "Interface")

        self:Button(
            p,
            "Hide UI",
            function()
                self:SetMenuVisible(false)
            end,
            210
        )

        local unloadButton =
            self:Button(
                p,
                "Unload UI",
                function()
                    task.defer(
                        function()
                            self:Unload()
                        end
                    )
                end,
                210
            )

        unloadButton.BackgroundColor3 =
            Color3.fromRGB(
                105,
                36,
                36
            )
    end

    local status = Instance.new("TextLabel")
    status.Position = UDim2.fromOffset(16, 525)
    status.Size = UDim2.new(1, -32, 0, 30)
    status.BackgroundColor3 =
        Color3.fromRGB(
            24,
            24,
            29
        )
    status.BorderSizePixel = 0
    status.Font = Enum.Font.Gotham
    status.TextSize = 11
    status.TextColor3 =
        Color3.fromRGB(
            220,
            220,
            225
        )
    status.TextXAlignment =
        Enum.TextXAlignment.Left
    status.Text = " Ready"
    status.Parent = main
    self:Round(status, 8)

    self.UI.Status = status

    -- Drag from the header. Clamp the full scaled panel to the viewport.
    do
        local dragging, startMouse, startCentre
        self:Connect(title.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = input
                startMouse = input.Position
                startCentre = main.AbsolutePosition + main.AbsoluteSize * 0.5
            end
        end)
        self:Connect(self.S.UserInputService.InputChanged, function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input ~= dragging then return end
            local delta = input.Position - startMouse
            local camera = workspace.CurrentCamera
            if not camera then return end
            local viewport, half = camera.ViewportSize, main.AbsoluteSize * 0.5
            main.Position = UDim2.fromOffset(
                math.clamp(startCentre.X + delta.X, half.X + 8, math.max(half.X + 8, viewport.X - half.X - 8)),
                math.clamp(startCentre.Y + delta.Y, half.Y + 8, math.max(half.Y + 8, viewport.Y - half.Y - 8)))
        end)
        self:Connect(self.S.UserInputService.InputEnded, function(input)
            if input == dragging then dragging = nil end
        end)
    end

    self:Connect(
        self.S.UserInputService.InputBegan,
        function(input, gpe)
            if gpe then
                return
            end

            if input.KeyCode
                == Enum.KeyCode[self.State.MenuKey or "RightShift"] then

                self:SetMenuVisible(
                    not self.State.Visible
                )
            end
        end
    )

    self:BuildExtraUI(pages)
    show("Home")
end

-- ============================================================
-- LIVE LOOPS
-- ============================================================

function H:UpdateDashboard()
    if not self.UI.HomeSummary then
        return
    end

    if os.clock()
        - self.Runtime.LastDashboardUpdate
        < 0.3 then

        return
    end

    self.Runtime.LastDashboardUpdate = os.clock()

    local hum = self:Humanoid()
    local hpText = "?"

    if hum then
        hpText =
            tostring(math.floor(hum.Health))
            .. "/"
            .. tostring(math.floor(hum.MaxHealth))
    end

    local active = self:GetActiveQuest()
    local questText = "None"

    if active then
        questText =
            tostring(active.Name)
            .. (
                active.Task
                and (
                    "  •  "
                    .. tostring(active.Task)
                )
                or ""
            )
            .. (
                self:QuestProgressText(active) ~= ""
                and (
                    "  •  "
                    .. self:QuestProgressText(active)
                )
                or ""
            )
    end

    local target =
        self.Data.CurrentFarmTarget

    local targetText =
        target
        and target.Parent
        and target.Name
        or "None"

    local aliveBosses = 0

    for _, rec in pairs(self.Data.Bosses) do
        if self:BossAlive(rec) then
            aliveBosses += 1
        end
    end

    local phase, eta = self:ClockETA()

    local region =
        target
        and self:ModelRegion(target)
        or self.Data.CurrentFarmRegion
        or "-"

    self:SafeText(
        self.UI.LiveChip,
        "● LIVE  •  "
        .. tostring(phase)
    )

    self:SafeText(
        self.UI.HomeSummary,
        "  PLAYER\n"
        .. "  HP  "
        .. hpText
        .. "    |    Lv  "
        .. tostring(
            self:GetPlayerLevel()
            or "?"
        )
        .. "    |    Combat  "
        .. tostring(
            self:CombatAvailable()
        )
        .. "    |    M1  "
        .. tostring(
            self.Runtime.AttackBackend
            or "DirectPunch"
        )
        .. "    |    Ping  "
        .. tostring(
            math.floor(
                self:GetPingMs()
                + 0.5
            )
        )
        .. "ms"
        .. "\n\n  PROGRESSION\n"
        .. "  Quest  "
        .. questText
        .. "\n  Target  "
        .. tostring(targetText)
        .. "    |    Region  "
        .. tostring(region)
        .. "\n\n  WORLD\n"
        .. "  Live mobs  "
        .. tostring(#self.Data.Mobs)
        .. "    |    Alive bosses  "
        .. tostring(aliveBosses)
        .. "    |    "
        .. tostring(phase)
        .. (
            eta
            and (
                " (~"
                .. tostring(math.floor(eta))
                .. "s)"
            )
            or ""
        )
    )
end

function H:UpdateBossUI()
    local rec =
        self.State.SelectedBoss
        and self.Data.Bosses[
            self.State.SelectedBoss
        ]

    if not rec or not self.UI.BossInfo then
        return
    end

    local hum = self:BossHumanoid(rec)
    local alive = hum and hum.Health > 0

    if alive then
        self.Data.BossRespawnAt[rec.Code] = nil
    elseif not self.Data.BossRespawnAt[rec.Code]
        and rec.SpawnTime > 0 then

        self.Data.BossRespawnAt[rec.Code] =
            os.clock()
            + rec.SpawnTime
    end

    local respawn = self.Data.BossRespawnAt[rec.Code]
    local remain =
        respawn
        and math.max(
            0,
            respawn - os.clock()
        )
        or nil

    local phase, eta = self:ClockETA()

    self:SafeText(
        self.UI.BossInfo,
        " Mode: "
                .. tostring(self.State.BossMode)
                .. "\n Boss: "
                .. rec.Code
                .. "\n Title: "
                .. rec.Title
                .. "\n Alive: "
                .. tostring(alive)
                .. (
                    hum
                    and (
                        " • HP "
                        .. math.floor(hum.Health)
                        .. "/"
                        .. math.floor(hum.MaxHealth)
                    )
                    or ""
                )
                .. "\n Chest: "
                .. rec.Chest
                .. " • Rarity "
                .. tostring(rec.ChestRarity)
                .. "\n Night Only: "
                .. tostring(rec.NightOnly)
                .. " • Current: "
                .. phase
                .. (
                    eta
                    and (
                        " • transition ~"
                        .. tostring(
                            math.floor(eta)
                        )
                        .. "s"
                    )
                    or ""
                )
                .. (
                    remain
                    and (
                        "\n Local Respawn Estimate: "
                        .. tostring(
                            math.ceil(remain)
                        )
                        .. "s"
                    )
                    or ""
                )
    )
end


-- ============================================================
-- BUILD 29 • CLEAN SMART PROGRESSION CORE
-- ============================================================
-- This intentionally bypasses the old staged/anchor progression system when
-- Smart Progression is enabled.
--
-- State machine:
--   no quest -> actual quest NPC -> dialogue
--   active combat quest -> actual live mob -> tween -> fight
--   complete quest -> actual turn-in NPC -> dialogue
--
-- Important rules:
--   • TweenService only.
--   • Never tween toward SpawnCrystal / region scenery.
--   • Never move toward an NPC that is not actually loaded.
--   • Missing targets are streamed first; movement waits for the live model.
--   • No pathfinding and no walking controller.
-- ============================================================

function H:CleanIsOffMap()
    local root = self:Root()
    if not root then return false end

    local p = root.Position
    return math.abs(p.X) > 12000
        or math.abs(p.Y) > 12000
        or math.abs(p.Z) > 12000
end

function H:CleanNpcModulePosition(npcName)
    npcName = tostring(npcName or "")
    if npcName == "" then return nil end

    self.Runtime.CleanNpcModuleCache =
        self.Runtime.CleanNpcModuleCache or {}

    local key = string.lower(npcName)
    local cached = self.Runtime.CleanNpcModuleCache[key]
    if cached ~= nil then
        return cached ~= false and cached or nil
    end

    local known =
        self.Data.KnownNpcLocations
        and self.Data.KnownNpcLocations[key]

    if known and typeof(known.Position) == "Vector3" then
        self.Runtime.CleanNpcModuleCache[key] = known.Position
        return known.Position
    end

    local regions =
        self.Modules.Regions

    if type(regions) == "table"
        and type(regions.GetNpcSpawn) == "function" then

        local ok, spawn =
            pcall(
                regions.GetNpcSpawn,
                npcName
            )

        if ok then
            local pos

            if typeof(spawn) == "Vector3" then
                pos = spawn
            elseif typeof(spawn) == "CFrame" then
                pos = spawn.Position
            elseif type(spawn) == "table" then
                if typeof(spawn.Position) == "Vector3" then
                    pos = spawn.Position
                elseif typeof(spawn.CFrame) == "CFrame" then
                    pos = spawn.CFrame.Position
                end
            end

            if pos then
                self.Runtime.CleanNpcModuleCache[key] = pos
                return pos
            end
        end
    end

    local content =
        self:FindDesc(
            self.S.ReplicatedStorage,
            "Ouwland.Content"
        )

    if not content then
        self.Runtime.CleanNpcModuleCache[key] = false
        return nil
    end

    local wantedModule
    for _, obj in ipairs(content:GetDescendants()) do
        if obj:IsA("ModuleScript")
            and string.lower(obj.Name) == key then

            local parent = obj.Parent
            local parentName =
                parent and string.lower(tostring(parent.Name)) or ""

            -- Prefer actual NPC definition modules, not dialogue/quest modules.
            if parentName == "npcs" then
                wantedModule = obj
                break
            elseif not wantedModule then
                wantedModule = obj
            end
        end
    end

    if not wantedModule then
        self.Runtime.CleanNpcModuleCache[key] = false
        return nil
    end

    local data = self:SafeRequire(wantedModule)
    if type(data) ~= "table" then
        self.Runtime.CleanNpcModuleCache[key] = false
        return nil
    end

    local preferredKeys = {
        "CFrame",
        "DefaultCF",
        "DefaultCFrame",
        "SpawnCFrame",
        "Spawn",
        "Position",
        "Location",
        "Pos",
    }

    local function positionOf(value)
        if typeof(value) == "CFrame" then
            return value.Position
        elseif typeof(value) == "Vector3" then
            return value
        end
        return nil
    end

    for _, field in ipairs(preferredKeys) do
        local pos = positionOf(data[field])
        if pos then
            self.Runtime.CleanNpcModuleCache[key] = pos
            return pos
        end
    end

    -- Conservative recursive fallback. Only inspect a small amount of config
    -- data so a weird/cyclic module cannot stall the farm loop.
    local seen = {}
    local visited = 0

    local function scanTable(tbl, depth)
        if type(tbl) ~= "table"
            or seen[tbl]
            or depth > 3
            or visited > 160 then
            return nil
        end

        seen[tbl] = true
        visited += 1

        for _, field in ipairs(preferredKeys) do
            local pos = positionOf(tbl[field])
            if pos then return pos end
        end

        for k, v in pairs(tbl) do
            local name = string.lower(tostring(k))
            if name:find("cframe", 1, true)
                or name:find("position", 1, true)
                or name == "spawn"
                or name == "location"
                or name == "pos" then

                local pos = positionOf(v)
                if pos then return pos end
            end
        end

        for _, v in pairs(tbl) do
            if type(v) == "table" then
                local pos = scanTable(v, depth + 1)
                if pos then return pos end
            end
        end

        return nil
    end

    local pos = scanTable(data, 0)
    self.Runtime.CleanNpcModuleCache[key] = pos or false
    return pos
end

function H:CleanStream(position, label)
    if typeof(position) ~= "Vector3" then
        return false
    end

    local now = os.clock()
    if now - (self.Runtime.CleanLastStreamAt or 0) < 0.8 then
        return true
    end

    self.Runtime.CleanLastStreamAt = now

    task.spawn(function()
        if not self.State.Unloaded then
            self:RequestStreamAt(position, 1.8, false)
        end
    end)

    if label then
        self:SetStatus(
            "Manual Farm • loading "
            .. tostring(label)
        )
    end

    return true
end

function H:CleanTweenToNpc(npcName, npc, anchor, prompt)
    local root = self:Root()
    if not root or not npc or not anchor then
        return false
    end

    local maxDist =
        prompt
        and tonumber(prompt.MaxActivationDistance)
        or 10

    local stopDistance =
        math.clamp(maxDist - 2.5, 4.5, 7.0)

    -- Fixed goal based on the NPC's orientation, so FarmStep doesn't recalculate
    -- a new endpoint every 0.2 seconds and cancel its own tween.
    local forward = anchor.CFrame.LookVector
    local flat = Vector3.new(forward.X, 0, forward.Z)

    if flat.Magnitude < 0.05 then
        flat = Vector3.new(0, 0, -1)
    else
        flat = flat.Unit
    end

    local goal =
        anchor.Position
        + flat * stopDistance

    self.State.MovementType = "Tween"
    self.Runtime.QuestMoveSpeedCap = 150
    local ok = self:MoveTo(goal, nil, nil)
    self.Runtime.QuestMoveSpeedCap = nil

    local dist =
        (root.Position - anchor.Position).Magnitude

    self:SetStatus(
        "Manual Farm • tween → "
        .. tostring(npcName)
        .. " • "
        .. tostring(math.floor(dist))
        .. " studs"
    )

    return ok
end

function H:CleanNpcStep(quest, npcName, mode)
    npcName = tostring(npcName or "")
    if npcName == "" then
        self:SetStatus("Manual Farm • NPC missing from quest data")
        return false
    end

    local npc, dist, anchor =
        self:FindNPC(npcName)

    if not npc or not anchor then
        npc, dist, anchor =
            self:FindNpcByChatPrompt(
                npcName
            )
    end

    if not npc or not anchor then
        -- Crucial difference from the old builds: do not move toward a region
        -- anchor or SpawnCrystal. Load the real NPC first, THEN tween to it.
        self:StopMovement()
        self:ResetQuestTravelRoute()
        self:StopAttackHold()
        self:StopBlocking()

        local pos = self:CleanNpcModulePosition(npcName)

        if pos then
            self:CleanStream(
                pos,
                npcName .. " (waiting for live NPC)"
            )
        else
            self:SetStatus(
                "Manual Farm • waiting for live NPC • "
                .. npcName
            )
        end

        return true
    end

    local prompt = self:FindNpcPrompt(npc, npcName)
    local activation =
        prompt
        and math.max(
            2,
            (tonumber(prompt.MaxActivationDistance) or 10) - 1
        )
        or 7

    local myRoot = self:Root()
    dist =
        myRoot
        and (myRoot.Position - anchor.Position).Magnitude
        or dist
        or math.huge

    if dist > activation then
        self:ResetDialogueSession()
        return self:CleanTweenToNpc(
            npcName,
            npc,
            anchor,
            prompt
        )
    end

    self:StopMovement()
    self:StopAttackHold()
    self:StopBlocking()

    -- If dialogue is already visible, advance it. No need to re-fire the prompt.
    if self:QuestDialogueLooksOpen(npcName) then
        self:AdvanceQuestDialogue(
            quest,
            mode or "accept"
        )

        self:SetStatus(
            "Manual Farm • dialogue → "
            .. npcName
        )
        return true
    end

    local now = os.clock()
    if now - (self.Runtime.CleanLastNpcInteract or 0) >= 0.75 then
        self.Runtime.CleanLastNpcInteract = now

        local opened = false
        if prompt and prompt.Enabled then
            opened = self:InteractPrompt(prompt)
        end

        -- fireproximityprompt isn't reliable in every executor/game. T is the
        -- scan-confirmed normal chat key for Tom and this uses the prompt's real
        -- key for every other NPC.
        if not opened
            or not self:QuestDialogueLooksOpen(npcName) then

            self:PressNpcInteractKey(prompt)
        end
    end

    self:SetStatus(
        "Manual Farm • interacting → "
        .. npcName
    )

    return true
end

function H:CleanCombatStep(active, def)
    self:ResetDialogueSession()

    local query =
        tostring(
            active
            and (
                active.Code
                or active.Task
            )
            or ""
        )

    if query == "" then
        return false
    end

    local now = os.clock()
    if now - (self.Runtime.CleanLastMobRefresh or 0) >= 0.65 then
        self.Runtime.CleanLastMobRefresh = now
        self:RefreshMobs()
    end

    local mob, _ =
        self:NearestMob(
            query,
            active,
            def
        )

    if not mob
        and active
        and active.Task
        and tostring(active.Task) ~= query then

        mob =
            self:NearestMob(
                tostring(active.Task),
                active,
                def
            )
    end

    if not mob then
        self:StopMovement()
        self:StopAttackHold()
        self:StopBlocking()

        -- Quest definitions already contain the actual farm position for many
        -- combat quests. Use it only to STREAM the area, never as a blind move
        -- destination. Once a live mob exists, the next tick tweens to the mob.
        local spawnPosition =
            def
            and typeof(def.Position) == "Vector3"
            and def.Position
            or nil

        if spawnPosition then
            self:CleanStream(
                spawnPosition,
                "quest mobs • " .. query
            )
        else
            self:SetStatus(
                "Manual Farm • waiting for live mob • "
                .. query
            )
        end

        return true
    end

    local mobRoot =
        mob:FindFirstChild(
            "HumanoidRootPart",
            true
        )

    local mobHum =
        mob:FindFirstChildOfClass("Humanoid")

    if not mobRoot
        or not mobHum
        or mobHum.Health <= 0 then

        self:StopAttackHold()
        return true
    end

    self.Data.CurrentFarmTarget = mob
    self.Data.CurrentFarmQuery = query
    self.Data.CurrentFarmRegion = self:ModelRegion(mob)

    if self:SafeCombatHealthStep(mob) then
        return true
    end

    self.State.MovementType = "Tween"
    self.State.FarmPosition = "Below"
    self.State.BelowDepth =
        math.max(
            tonumber(self.State.BelowDepth) or 0,
            4.5
        )

    self:MoveTo(
        mobRoot.Position,
        mobRoot.CFrame,
        mob
    )

    local myRoot = self:Root()
    local dist =
        myRoot
        and (myRoot.Position - mobRoot.Position).Magnitude
        or math.huge

    if dist <= 18 then
        self:GuardStep(mob)
    else
        self:StopBlocking()
    end

    if dist <= 6.5 then
        self:StartAttackHold(mob)
    else
        self:StopAttackHold()
    end

    if self.State.SmartSkill
        and self.State.SelectedSkill
        and dist <= 24 then

        self:UseSkill(
            self.State.SelectedSkill
        )
    end

    local progress =
        active
        and self:QuestProgressText(active)
        or ""

    self:SetStatus(
        "Manual Farm • farm → "
        .. tostring(mob.Name)
        .. " • "
        .. tostring(math.floor(dist))
        .. " studs"
        .. (
            progress ~= ""
            and (" • " .. progress)
            or ""
        )
    )

    return true
end

function H:CleanSmartProgressionStep()
    -- Never silently launch another absurd tween if an older build damaged the
    -- current character state. This is deliberately passive: no reset menu,
    -- no CFrame recovery, no extra movement system.
    if self:CleanIsOffMap() then
        self:StopMovement()
        self:StopAttackHold()
        self:StopBlocking()
        self.State.SmartProgression = false
        self.State.AutoQuest = false
        self.State.AutoFarmMobs = false
        self:RefreshToggleButtons()
        self:SetStatus(
            "OFF-MAP • reset character once, then Start Progression"
        )
        return true
    end

    self.State.AutoQuest = true
    self.State.AutoAccept = true
    self.State.AutoFarmMobs = true
    self.State.AutoEquipCombat = true
    self.State.AutoParry = true
    self.State.PerfectBlock = true
    self.State.PingAwareParry = true
    self.State.BossSafetyMode = true
    self.State.SafeCombat = true
    self.State.MovementType = "Tween"

    local active = self:GetActiveQuest()
    self.Data.AutoQuest.Active = active
    self:RememberActiveQuest(active)

    if active then
        local def, holderKey =
            self:QuestDefinition(
                active.Key,
                active.Name
            )

        if active.Task then
            local interactionNpc =
                self:QuestInteractionNpc(
                    active,
                    def
                )

            if interactionNpc then
                self.Data.AutoQuest.Stage = "interact"
                return self:CleanNpcStep(
                    {
                        Key = holderKey or active.Key,
                        Name = active.Name,
                    },
                    interactionNpc,
                    "progress"
                )
            end

            self.Data.AutoQuest.Stage = "farm"
            return self:CleanCombatStep(
                active,
                def
            )
        end

        -- All active tasks complete -> return to the real handoff/offer NPC.
        local handoffNpc =
            select(
                1,
                self:QuestCompletionHandoffNpc(def)
            )

        local npcName =
            handoffNpc
            or (
                def
                and typeof(def.OfferNpc) == "string"
                and def.OfferNpc
                or nil
            )

        if npcName then
            self.Data.AutoQuest.Stage = "turnin"
            return self:CleanNpcStep(
                {
                    Key = holderKey or active.Key,
                    Name = active.Name,
                },
                npcName,
                "turnin"
            )
        end

        self:SetStatus(
            "Smart Progression • quest complete • waiting for server update"
        )
        return true
    end

    -- No active quest. For the user's current Lv10-19 Bamboo Grove stage use the
    -- scan-confirmed Tom route first. Above that, hand selection back to the
    -- game's quest data / existing recommender.
    local level =
        tonumber(
            self:GetPlayerLevel()
        ) or 0

    local recommended

    if level >= 10 and level < 20 then
        recommended = self:KnownProgressionFallback()
    end

    recommended =
        recommended
        or self:ChooseRecommendedQuest()

    if recommended
        and recommended.Npc then

        self.Data.AutoQuest.Stage = "accept"

        self:SafeText(
            self.UI.QuestInfo,
            " CLEAN AUTO FARM"
            .. "\n Quest • "
            .. tostring(recommended.Name)
            .. "\n NPC • "
            .. tostring(recommended.Npc)
            .. "\n State • ACCEPT"
        )

        return self:CleanNpcStep(
            recommended,
            recommended.Npc,
            "accept"
        )
    end

    -- No quest is available: grind a real loaded safe mob instead of routing
    -- toward guessed quest coordinates.
    local mob, _distance =
        self:LevelGrindTarget()

    if mob then
        local pseudo = {
            Name = "Level Grind",
            Task = tostring(mob.Name),
            Code = tostring(mob.Name),
        }

        return self:CleanCombatStep(
            pseudo,
            nil
        )
    end

    self:StopMovement()
    self:StopAttackHold()
    self:StopBlocking()
    self:SetStatus(
        "Smart Progression • waiting for eligible quest / live mob"
    )
    return true
end



-- ============================================================
-- BUILD 29 • SIMPLE QUEST LOOP
--
-- Selected quest only:
--   NPC -> accept -> live quest enemy -> kill -> repeat enemy
--   -> quest complete -> NPC -> repeat
--
-- No region-anchor movement.
-- No SpawnCrystal movement.
-- No guessed mob/NPC movement.
-- No Smart Progression.
-- ============================================================

function H:IsSaneFarmPosition(pos)
    if typeof(pos) ~= "Vector3" then
        return false
    end

    return math.abs(pos.X) < 10000
        and math.abs(pos.Y) < 10000
        and math.abs(pos.Z) < 10000
end

function H:IsPlayerInSaneWorld()
    local root = self:Root()

    return root ~= nil
        and self:IsSaneFarmPosition(root.Position)
end

function H:StopManualFarmOffMap()
    self:StopMovement()
    self:StopAttackHold()
    self:StopBlocking()

    self.State.AutoQuest = false
    self.State.AutoFarmMobs = false
    self.State.SmartProgression = false

    self:RefreshToggleButtons()

    self:SetStatus(
        "Farm stopped • character is off-map • reset/rejoin once, then restart"
    )

    return true
end

function H:StableNpcCFrame(npc, anchor)
    if not npc then
        return nil
    end

    -- Stationary quest NPCs expose a server-authored DefaultCF attribute.
    -- Prefer that over accessory/body-part positions, which can contain stale
    -- streamed coordinates.
    local defaultCF =
        npc:GetAttribute("DefaultCF")

    if typeof(defaultCF) == "CFrame"
        and self:IsSaneFarmPosition(defaultCF.Position) then

        return defaultCF
    end

    local top =
        npc:GetAttribute("Top")

    if typeof(top) == "Vector3"
        and self:IsSaneFarmPosition(top) then

        local facing =
            anchor
            and anchor:IsA("BasePart")
            and anchor.CFrame.LookVector
            or Vector3.new(0, 0, -1)

        local flat =
            Vector3.new(
                facing.X,
                0,
                facing.Z
            )

        if flat.Magnitude < 0.05 then
            flat = Vector3.new(0, 0, -1)
        end

        return CFrame.lookAt(
            top - Vector3.new(0, 2.5, 0),
            top - Vector3.new(0, 2.5, 0) + flat.Unit
        )
    end

    if anchor
        and anchor:IsA("BasePart")
        and self:IsSaneFarmPosition(anchor.Position) then

        return anchor.CFrame
    end

    return nil
end


function H:SetManualFarmNoclip(enabled)
    self.Runtime.ManualFarmCollision =
        self.Runtime.ManualFarmCollision
        or {}

    local character =
        self:Character()

    if not character then
        return
    end

    if enabled then
        for _, obj in ipairs(
            character:GetDescendants()
        ) do
            if obj:IsA("BasePart") then
                if self.Runtime.ManualFarmCollision[obj] == nil then
                    self.Runtime.ManualFarmCollision[obj] =
                        obj.CanCollide
                end

                obj.CanCollide = false
            end
        end
    else
        for part, oldValue in pairs(
            self.Runtime.ManualFarmCollision
        ) do
            if part and part.Parent then
                pcall(
                    function()
                        part.CanCollide =
                            oldValue
                    end
                )
            end

            self.Runtime.ManualFarmCollision[part] =
                nil
        end
    end
end

function H:SimpleDirectTween(goalPosition, lookAtPosition, speed, targetKey)
    local root = self:Root()
    local hum = self:Humanoid()

    local keyText =
        tostring(
            targetKey
            or ""
        )

    local isOrbit =
        string.sub(
            keyText,
            1,
            6
        ) == "ORBIT:"

    local isMobTravel =
        string.sub(
            keyText,
            1,
            11
        ) == "MOB_TRAVEL:"


    local isMelee =
        string.sub(
            keyText,
            1,
            6
        ) == "MELEE:"

    local isBossHover =
        string.sub(keyText, 1, 11) == "BOSS_HOVER:"

    if not root or not hum or typeof(goalPosition) ~= "Vector3" then
        return false
    end

    if math.abs(goalPosition.X) > 10000
        or math.abs(goalPosition.Y) > 10000
        or math.abs(goalPosition.Z) > 10000 then

        self:SetStatus("Mob Farm • refused unsafe destination")
        return false
    end

    -- MOB ONLY: collision is never disabled by farm movement.
    self:SetManualFarmNoclip(false)

    local distance = (root.Position - goalPosition).Magnitude

    if distance <= (isBossHover and 0.70 or 1.35) then
        if self.Runtime.SimpleDirectTween then
            pcall(function()
                self.Runtime.SimpleDirectTween:Cancel()
            end)
            self.Runtime.SimpleDirectTween = nil
        end

        self.Runtime.SimpleDirectGoal = nil
        self.Runtime.SimpleDirectKey = nil

        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            hum.AutoRotate = not isBossHover
        end)

        return true
    end

    local sameGoalTolerance =
        isOrbit
        and 0.065
        or (
            isMelee
            and 0.18
            or (
                isMobTravel
                and 0.25
                or 0.55
            )
        )

    local sameGoal =
        self.Runtime.SimpleDirectTween
        and self.Runtime.SimpleDirectGoal
        and (
            self.Runtime.SimpleDirectGoal
            - goalPosition
        ).Magnitude <= sameGoalTolerance
        and self.Runtime.SimpleDirectKey == targetKey
        and self.Runtime.SimpleDirectTween.PlaybackState
            == Enum.PlaybackState.Playing

    if sameGoal then
        return true
    end

    if self.Runtime.SimpleDirectTween then
        pcall(function()
            self.Runtime.SimpleDirectTween:Cancel()
        end)
    end

    local useSpeed

    if isBossHover then
        useSpeed = math.clamp(tonumber(speed) or 175, 100, 220)
    elseif isOrbit then
        useSpeed =
            math.clamp(
                tonumber(speed) or 190,
                90,
                240
            )
    elseif isMelee then
        useSpeed =
            math.clamp(
                tonumber(speed) or 165,
                100,
                190
            )
    elseif isMobTravel then
        useSpeed =
            math.clamp(
                tonumber(speed) or 170,
                110,
                200
            )
    else
        useSpeed =
            math.clamp(
                tonumber(speed) or 80,
                35,
                120
            )
    end

    local duration =
        math.max(
            distance / useSpeed,
            isBossHover
                and 0.035
                or isOrbit
                and 0.018
                or (
                    isMelee
                    and 0.022
                    or (
                        isMobTravel
                        and 0.035
                        or 0.06
                    )
                )
        )

    local goalCF
    if typeof(lookAtPosition) == "Vector3"
        and (lookAtPosition - goalPosition).Magnitude > 0.05 then

        if isBossHover then
            goalCF = self:BossHoverAimCFrame(
                goalPosition,
                lookAtPosition,
                root.CFrame.RightVector
            )
        else
            goalCF = CFrame.lookAt(
                goalPosition,
                Vector3.new(
                    lookAtPosition.X,
                    goalPosition.Y,
                    lookAtPosition.Z
                )
            )
        end
    else
        goalCF = CFrame.new(goalPosition)
    end

    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        hum.AutoRotate = false
    end)

    local tween = self.S.TweenService:Create(
        root,
        TweenInfo.new(
            duration,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.Out
        ),
        {CFrame = goalCF}
    )

    self.Runtime.SimpleDirectTween = tween
    self.Runtime.SimpleDirectGoal = goalPosition
    self.Runtime.SimpleDirectKey = targetKey

    tween.Completed:Connect(function()
        if self.Runtime.SimpleDirectTween ~= tween then
            return
        end

        self.Runtime.SimpleDirectTween = nil
        self.Runtime.SimpleDirectGoal = nil
        self.Runtime.SimpleDirectKey = nil

        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            hum.AutoRotate = not isBossHover
        end)
    end)

    tween:Play()
    return true
end

function H:FindExactLiveQuestPrompt(npcName)
    local wanted =
        string.lower(
            tostring(
                npcName
                or ""
            )
        )

    if wanted == "" then
        return nil
    end

    local bestPrompt
    local bestPart
    local bestModel
    local bestDistance =
        math.huge

    local myRoot =
        self:Root()

    for _, prompt in ipairs(
        self.S.CollectionService:GetTagged(
            "Dialogue"
        )
    ) do
        if prompt:IsA(
            "ProximityPrompt"
        ) then
            local objectText =
                string.lower(
                    tostring(
                        prompt.ObjectText
                        or ""
                    )
                )

            local promptName =
                string.lower(
                    tostring(
                        prompt.Name
                        or ""
                    )
                )

            local action =
                string.lower(
                    tostring(
                        prompt.ActionText
                        or ""
                    )
                )

            if (
                objectText == wanted
                or promptName == wanted
            )
                and (
                    action == ""
                    or action == "chat"
                    or action == "talk"
                    or action == "speak"
                    or action == "interact"
                ) then

                local part =
                    prompt.Parent

                if not (
                    part
                    and part:IsA(
                        "BasePart"
                    )
                ) then

                    local model =
                        prompt:FindFirstAncestorOfClass(
                            "Model"
                        )

                    part =
                        model
                        and model:FindFirstChild(
                            "HumanoidRootPart",
                            true
                        )
                end

                if part
                    and part:IsA(
                        "BasePart"
                    )
                    and math.abs(
                        part.Position.X
                    ) < 10000
                    and math.abs(
                        part.Position.Y
                    ) < 10000
                    and math.abs(
                        part.Position.Z
                    ) < 10000 then

                    local model =
                        prompt:FindFirstAncestorOfClass(
                            "Model"
                        )

                    local distance =
                        myRoot
                        and (
                            myRoot.Position
                            - part.Position
                        ).Magnitude
                        or 0

                    if distance
                        < bestDistance then

                        bestDistance =
                            distance

                        bestPrompt =
                            prompt

                        bestPart =
                            part

                        bestModel =
                            model
                    end
                end
            end
        end
    end

    return bestPrompt,
        bestPart,
        bestModel,
        bestDistance
end

function H:FindExactLiveQuestEnemy(name)
    local raw = tostring(name or "")
    local wanted = self:NormalizeMobText(raw)

    if wanted == "" then
        return nil
    end

    local myRoot =
        self:Root()

    local now =
        os.clock()

    local cache =
        self.Runtime.QuestEnemyCache

    if type(cache) == "table"
        and cache.Query == wanted then

        local cachedModel =
            cache.Model

        local cachedRoot =
            cachedModel
            and cachedModel.Parent
            and (
                cachedModel:FindFirstChild(
                    "HumanoidRootPart",
                    true
                )
                or cachedModel.PrimaryPart
            )
            or nil

        local cachedHum =
            cachedModel
            and cachedModel.Parent
            and (
                cachedModel:FindFirstChildOfClass(
                    "Humanoid"
                )
                or cachedModel:FindFirstChildWhichIsA(
                    "Humanoid",
                    true
                )
            )
            or nil

        if cachedModel
            and cachedRoot
            and cachedHum
            and cachedHum.Health > 0
            and self:MobMatches(
                cachedModel,
                raw
            ) then

            local cachedDistance =
                myRoot
                and (
                    myRoot.Position
                    - cachedRoot.Position
                ).Magnitude
                or 0

            return
                cachedModel,
                cachedRoot,
                cachedHum,
                cachedDistance
        end

        self.Runtime.QuestEnemyCache =
            nil
    end

    if self.Runtime.LastQuestEnemyScanQuery == wanted
        and now
            - (
                self.Runtime.LastQuestEnemyScanAt
                or 0
            )
            < 0.20 then

        return nil
    end

    self.Runtime.LastQuestEnemyScanQuery =
        wanted

    self.Runtime.LastQuestEnemyScanAt =
        now

    local candidates = {}
    local seen = {}

    local function validMob(model)
        if not model or not model:IsA("Model") or seen[model] then
            return
        end

        seen[model] = true

        if model:GetAttribute("IsMob") ~= true then
            return
        end

        -- BUILD 80:
        -- Reuse the normal Mob Farm matcher so quest codes such as BearCub can
        -- match model names like "Bear Cub" plus NpcCode/Code/UniqueName/tags.
        if not self:MobMatches(
            model,
            raw
        ) then
            return
        end

        local hum = model:FindFirstChildOfClass("Humanoid")
        local mobRoot = model:FindFirstChild("HumanoidRootPart", true)

        if not hum or hum.Health <= 0 or not mobRoot then
            return
        end

        local p = mobRoot.Position

        if math.abs(p.X) >= 10000
            or math.abs(p.Y) >= 10000
            or math.abs(p.Z) >= 10000 then
            return
        end

        table.insert(
            candidates,
            {
                Model = model,
                Root = mobRoot,
                Hum = hum,
            }
        )
    end

    -- First pass: every live streamed mob, regardless of folder naming.
    for _, liveModel in ipairs(
        self:LiveMobModels()
    ) do
        validMob(
            liveModel
        )
    end

    local humanoids = self.S.Workspace:FindFirstChild("Humanoids")
    local regions = humanoids and humanoids:FindFirstChild("Regions")

    if regions then
        for _, region in ipairs(regions:GetChildren()) do
            local active = region:FindFirstChild("ActiveNpcs")

            if active then
                for _, folder in ipairs(active:GetChildren()) do
                    if self:NormalizeMobText(folder.Name) == wanted then
                        if folder:IsA("Model") then
                            validMob(folder)
                        end

                        for _, child in ipairs(folder:GetChildren()) do
                            if child:IsA("Model") then
                                validMob(child)
                            end
                        end
                    end

                    local bossInfo = folder:FindFirstChild("BossInfo")

                    if bossInfo
                        and self:NormalizeMobText(
                            tostring(bossInfo:GetAttribute("NpcCode") or "")
                        ) == wanted then

                        for _, child in ipairs(folder:GetChildren()) do
                            if child:IsA("Model") then
                                validMob(child)
                            end
                        end
                    end
                end
            end
        end
    end

    for _, tagged in ipairs(
        self.S.CollectionService:GetTagged("Humanoids")
    ) do
        local model =
            tagged:IsA("Model")
            and tagged
            or tagged:FindFirstAncestorOfClass("Model")

        validMob(model)
    end

    if #candidates == 0 then
        return nil
    end

    -- Prefer an isolated target so the farm does not get surrounded.
    local living = {}

    if regions then
        for _, model in ipairs(regions:GetDescendants()) do
            if model:IsA("Model")
                and model:GetAttribute("IsMob") == true then

                local hum = model:FindFirstChildOfClass("Humanoid")
                local root = model:FindFirstChild("HumanoidRootPart", true)

                if hum and hum.Health > 0 and root then
                    table.insert(
                        living,
                        {
                            Model = model,
                            Root = root,
                        }
                    )
                end
            end
        end
    end

    local best
    local bestScore = math.huge

    for _, rec in ipairs(candidates) do
        local distance =
            myRoot
            and (myRoot.Position - rec.Root.Position).Magnitude
            or 0

        local crowd = 0

        for _, other in ipairs(living) do
            if other.Model ~= rec.Model
                and (other.Root.Position - rec.Root.Position).Magnitude <= 12 then
                crowd += 1
            end
        end

        local score = distance + crowd * 90

        if score < bestScore then
            bestScore = score
            best = rec
            best.Distance = distance
            best.Crowd = crowd
        end
    end

    if not best then
        return nil
    end

    self.Runtime.SelectedMobCrowd =
        best.Crowd
        or 0

    self.Runtime.QuestEnemyCache = {
        Query = wanted,
        Model = best.Model,
    }

    return
        best.Model,
        best.Root,
        best.Hum,
        best.Distance
end


function H:GetMobStreamHint(name)
    local wanted = self:NormalizeMobText(tostring(name or ""))

    local scanHints = {
        ["bandit"] = Vector3.new(-250, 1226, -1030),
        ["zuko"] = Vector3.new(-296.704, 1224.2, -1022.197),
        ["mother bear"] = Vector3.new(540.5, 1121, -1023.5),
        ["motherbear"] = Vector3.new(540.5, 1121, -1023.5),
        ["bearcub"] = Vector3.new(540.5, 1121, -1023.5),
        ["bear cub"] = Vector3.new(540.5, 1121, -1023.5),
        ["kaiden"] = Vector3.new(585.712, 1146.547, -1314.887),
    }

    local known = scanHints[wanted]
    if known then
        return known
    end

    local regions = self.Modules.Regions
    if type(regions) == "table"
        and type(regions.GetNpcSpawn) == "function" then

        local ok, result = pcall(regions.GetNpcSpawn, tostring(name or ""))
        if ok then
            local pos

            if typeof(result) == "Vector3" then
                pos = result
            elseif typeof(result) == "CFrame" then
                pos = result.Position
            elseif type(result) == "table" then
                if typeof(result.Position) == "Vector3" then
                    pos = result.Position
                elseif typeof(result.CFrame) == "CFrame" then
                    pos = result.CFrame.Position
                end
            end

            if pos
                and math.abs(pos.X) < 10000
                and math.abs(pos.Y) < 10000
                and math.abs(pos.Z) < 10000 then

                return pos
            end
        end
    end

    return nil
end

function H:GetSafeMobGoal(mob, mobRoot)
    if not mob
        or not mobRoot then

        return nil,
            "invalid"
    end

    local params =
        RaycastParams.new()

    params.FilterType =
        Enum.RaycastFilterType.Exclude

    local ignore = {
        mob,
    }

    local char =
        self:Character()

    if char then
        ignore[#ignore + 1] =
            char
    end

    params.FilterDescendantsInstances =
        ignore

    params.IgnoreWater =
        false

    local ray =
        self.S.Workspace:Raycast(
            mobRoot.Position
                + Vector3.new(
                    0,
                    8,
                    0
                ),
            Vector3.new(
                0,
                -40,
                0
            ),
            params
        )

    -- BUILD 95:
    -- Never manufacture a melee goal from the NPC root Y when there is no
    -- confirmed floor. The old "below" / fallback-Y logic could pull the
    -- player downward while a boss was being knocked/lifted during M1s.
    if not ray then
        return nil,
            "no-ground"
    end

    local floorY =
        ray.Position.Y

    local look =
        mobRoot.CFrame.LookVector

    local flat =
        Vector3.new(
            look.X,
            0,
            look.Z
        )

    if flat.Magnitude < 0.05 then
        flat =
            Vector3.new(
                0,
                0,
                -1
            )
    else
        flat =
            flat.Unit
    end

    local backDistance =
        1.45

    local raw =
        mobRoot.Position
        - flat * backDistance

    local goal =
        Vector3.new(
            raw.X,
            floorY + 2.70,
            raw.Z
        )

    return goal,
        "ground-melee"
end


function H:ClickExactSelectedQuestChoice(quest, mode)
    mode =
        tostring(
            mode
            or "accept"
        )

    if mode ~= "accept" then
        return self:AdvanceQuestDialogue(
            quest,
            mode
        )
    end

    if os.clock()
        - (
            self.Runtime.LastExactQuestChoiceAt
            or 0
        )
        < 0.35 then

        return false
    end

    local selected =
        self:SelectedQuestRecord()

    local selectedName =
        string.lower(
            tostring(
                selected
                and selected.Name
                or (
                    quest
                    and quest.Name
                )
                or ""
            )
        )

    local selectedLevel =
        tonumber(
            selected
            and selected.Level
        )
        or 0

    local selectedKey =
        string.lower(
            tostring(
                selected
                and selected.Key
                or (
                    quest
                    and quest.Key
                )
                or ""
            )
        )

    local function normalize(s)
        s =
            string.lower(
                tostring(
                    s
                    or ""
                )
            )

        s =
            s:gsub(
                "[%p%c]",
                " "
            )

        s =
            s:gsub(
                "%s+",
                " "
            )

        return s
    end

    local stopWords = {
        ["defeat"] = true,
        ["kill"] = true,
        ["the"] = true,
        ["a"] = true,
        ["an"] = true,
        ["quest"] = true,
        ["mission"] = true,
        ["take"] = true,
        ["accept"] = true,
        ["start"] = true,
        ["begin"] = true,
        ["ill"] = true,
        ["i"] = true,
    }

    local questTokens = {}
    local seenToken = {}

    for token in normalize(
        selectedName
    ):gmatch("%S+") do
        if #token >= 3
            and not stopWords[token]
            and not seenToken[token] then

            seenToken[token] = true
            table.insert(
                questTokens,
                token
            )
        end
    end

    local function buttonText(obj)
        local parts = {
            tostring(
                obj.Name
                or ""
            ),
        }

        if obj:IsA(
            "TextButton"
        ) then
            table.insert(
                parts,
                tostring(
                    obj.Text
                    or ""
                )
            )
        end

        for _, child in ipairs(
            obj:GetDescendants()
        ) do
            if child:IsA(
                "TextLabel"
            )
                or child:IsA(
                    "TextButton"
                ) then

                local value =
                    tostring(
                        child.Text
                        or ""
                    )

                if value ~= "" then
                    table.insert(
                        parts,
                        value
                    )
                end
            end
        end

        return normalize(
            table.concat(
                parts,
                " "
            )
        )
    end

    local best
    local bestText = ""
    local bestScore =
        -math.huge

    local exactLevelCandidate
    local exactLevelCandidateText

    for _, obj in ipairs(
        self.PlayerGui:GetDescendants()
    ) do
        if obj:IsA(
            "GuiButton"
        )
            and not self:IsOwnGuiObject(
                obj
            )
            and self:IsActuallyVisible(
                obj
            )
            and obj.Active then

            local txt =
                buttonText(
                    obj
                )

            local path =
                string.lower(
                    self:Path(
                        obj
                    )
                )

            local score = 0

            if path:find(
                "dialog",
                1,
                true
            )
                or path:find(
                    "conversation",
                    1,
                    true
                )
                or path:find(
                    "yap",
                    1,
                    true
                ) then

                score += 30
            end

            if txt:find(
                "close",
                1,
                true
            )
                or txt:find(
                    "cancel",
                    1,
                    true
                )
                or txt:find(
                    "decline",
                    1,
                    true
                )
                or txt == "no" then

                score -= 1000
            end

            if txt:find(
                "take",
                1,
                true
            )
                or txt:find(
                    "accept",
                    1,
                    true
                )
                or txt:find(
                    "start",
                    1,
                    true
                ) then

                score += 12
            end

            local matchedTokens = 0

            for _, token in ipairs(
                questTokens
            ) do
                if txt:find(
                    token,
                    1,
                    true
                ) then

                    matchedTokens += 1
                    score += 45
                end
            end

            local levelMatched = false

            if selectedLevel > 0 then
                local levelText =
                    tostring(
                        selectedLevel
                    )

                levelMatched =
                    txt:find(
                        "lv "
                            .. levelText,
                        1,
                        true
                    ) ~= nil
                    or txt:find(
                        "lv"
                            .. levelText,
                        1,
                        true
                    ) ~= nil
                    or txt:find(
                        "level "
                            .. levelText,
                        1,
                        true
                    ) ~= nil

                if levelMatched then
                    score += 160
                end
            end

            if levelMatched
                and matchedTokens > 0
                and not txt:find(
                    "close",
                    1,
                    true
                )
                and not txt:find(
                    "cancel",
                    1,
                    true
                ) then

                exactLevelCandidate = obj
                exactLevelCandidateText = txt
            end

            if selectedKey ~= ""
                and txt:find(
                    selectedKey,
                    1,
                    true
                ) then

                score += 60
            end

            if #questTokens > 0
                and matchedTokens == 0 then

                score -= 120
            end

            if score > bestScore then
                bestScore =
                    score

                best =
                    obj

                bestText =
                    txt
            end
        end
    end

    if exactLevelCandidate then
        best =
            exactLevelCandidate

        bestText =
            exactLevelCandidateText
            or ""

        bestScore =
            math.max(
                bestScore,
                999
            )
    end

    if not best
        or bestScore < 20 then

        -- BUILD 76:
        -- The current page is usually NPC story text (e.g. Tom talking about
        -- the bears) and the actual quest choice only appears after one or more
        -- advances. Never wait for the user here: advance the dialogue, then
        -- rescan for the exact selected quest on the next farm tick.
        self:SetStatus(
            "Quest Farm • advancing dialogue → "
            .. tostring(
                selected
                and selected.Name
                or (
                    quest
                    and quest.Name
                )
                or "quest"
            )
        )

        return self:AdvanceQuestDialogue(
            quest,
            "progress"
        )
    end

    self.Runtime.LastExactQuestChoiceAt =
        os.clock()

    self:SetStatus(
        "Quest Farm • activating → "
        .. tostring(
            selected
            and selected.Name
            or (
                quest
                and quest.Name
            )
            or "quest"
        )
    )

    local attempted = false

    -- 1) Normal virtual cursor click.
    pcall(
        function()
            attempted = true
            self:ClickGuiObjectAt(
                best
            )
        end
    )

    -- 2) Keyboard/controller activation of the exact selected object.
    pcall(
        function()
            self.S.GuiService.SelectedObject =
                best

            self.S.VirtualInputManager:SendKeyEvent(
                true,
                Enum.KeyCode.Return,
                false,
                game
            )

            task.wait(0.025)

            self.S.VirtualInputManager:SendKeyEvent(
                false,
                Enum.KeyCode.Return,
                false,
                game
            )

            attempted = true
        end
    )

    -- 3) Fire both public button signals when the executor supports firesignal.
    if typeof(
        firesignal
    ) == "function" then

        pcall(
            function()
                firesignal(
                    best.Activated
                )
                attempted = true
            end
        )

        pcall(
            function()
                firesignal(
                    best.MouseButton1Click
                )
                attempted = true
            end
        )
    end

    -- 4) Some executors expose the actual Lua connections. Invoke them directly
    -- as a fallback because a successful VIM call does NOT prove Roblox handled
    -- the button.
    if typeof(
        getconnections
    ) == "function" then

        local function triggerConnections(signal)
            local ok,
                connections =
                pcall(
                    getconnections,
                    signal
                )

            if not ok
                or type(
                    connections
                ) ~= "table" then

                return
            end

            for _, connection in ipairs(
                connections
            ) do
                pcall(
                    function()
                        if type(
                            connection.Fire
                        ) == "function" then

                            connection:Fire()
                            attempted = true
                        elseif type(
                            connection.Function
                        ) == "function" then

                            connection.Function()
                            attempted = true
                        end
                    end
                )
            end
        end

        triggerConnections(
            best.Activated
        )

        triggerConnections(
            best.MouseButton1Click
        )
    end

    -- Do NOT claim success just because no method threw an error.
    -- The farm loop now verifies that the selected quest actually appears.
    self.Runtime.LastQuestClick =
        os.clock()

    self.Runtime.LastExactQuestChoiceText =
        bestText

    self.Runtime.LastExactQuestChoiceButton =
        best

    self.Runtime.ExactQuestChoiceVerifyUntil =
        os.clock() + 1.10

    self.Runtime.ExactQuestChoiceAttempted =
        attempted

    return attempted
end

function H:SimpleQuestNpcStep(quest, npcName, mode)
    npcName =
        tostring(
            npcName
            or ""
        )

    if npcName == "" then
        self:SetStatus(
            "Quest Farm • selected quest has no NPC"
        )
        return true
    end

    local prompt,
        npcRoot,
        _npcModel,
        distance =
        self:FindExactLiveQuestPrompt(
            npcName
        )

    -- BUILD 29 does not invent a route when the real NPC is not present.
    if not prompt
        or not npcRoot then

        self:StopMovement()
        self:StopAttackHold()
        self:StopBlocking()

        self:SetStatus(
            "Quest Farm • waiting for live NPC • "
            .. npcName
        )

        return true
    end

    local activation =
        math.max(
            4,
            (
                tonumber(
                    prompt.MaxActivationDistance
                ) or 10
            ) - 1.5
        )

    local root =
        self:Root()

    distance =
        root
        and (
            root.Position
            - npcRoot.Position
        ).Magnitude
        or distance
        or math.huge

    if distance > activation then
        self:ResetDialogueSession()
        self:StopAttackHold()
        self:StopBlocking()

        local look =
            npcRoot.CFrame.LookVector

        local flat =
            Vector3.new(
                look.X,
                0,
                look.Z
            )

        if flat.Magnitude < 0.05 then
            flat =
                Vector3.new(
                    0,
                    0,
                    -1
                )
        else
            flat =
                flat.Unit
        end

        local stopDistance =
            math.clamp(
                activation - 1,
                4,
                7
            )

        local goal =
            npcRoot.Position
            + flat * stopDistance

        self:SimpleDirectTween(
            goal,
            npcRoot.Position,
            55,
            "NPC:"
                .. npcName
        )

        self:SetStatus(
            "Quest Farm • tween → "
            .. npcName
            .. " • "
            .. tostring(
                math.floor(
                    distance
                )
            )
            .. " studs"
        )

        return true
    end

    if self.Runtime.SimpleDirectTween then
        pcall(
            function()
                self.Runtime.SimpleDirectTween:Cancel()
            end
        )

        self.Runtime.SimpleDirectTween =
            nil
    end

    pcall(function()
        local hum =
            self:Humanoid()

        if hum then
            hum.AutoRotate =
                true
        end
    end)

    if self:QuestDialogueLooksOpen(
        npcName
    ) then

        if tostring(
            mode
            or "accept"
        ) == "accept" then

            self:ClickExactSelectedQuestChoice(
                quest,
                "accept"
            )
        else
            self:AdvanceQuestDialogue(
                quest,
                mode
                    or "turnin"
            )
        end

        return true
    end

    local now =
        os.clock()

    if now
        - (
            self.Runtime.SimpleNpcInteractAt
            or 0
        )
        >= 0.45 then

        self.Runtime.SimpleNpcInteractAt =
            now

        local opened =
            false

        if prompt.Enabled then
            opened =
                self:InteractPrompt(
                    prompt
                )
        end

        if not opened
            or not self:QuestDialogueLooksOpen(
                npcName
            ) then

            self:PressNpcInteractKey(
                prompt
            )
        end
    end

    if self:QuestDialogueLooksOpen(
        npcName
    ) then
        if tostring(
            mode
            or "accept"
        ) == "accept" then

            self:ClickExactSelectedQuestChoice(
                quest,
                "accept"
            )
        else
            self:AdvanceQuestDialogue(
                quest,
                mode
                    or "turnin"
            )
        end
    else
        self:SetStatus(
            "Quest Farm • opening dialogue → "
            .. npcName
        )
    end

    return true
end



function H:CombatGroundUnderRoot(
    maxDrop
)
    local root =
        self:Root()

    if not root then
        return false,
            nil
    end

    local params =
        RaycastParams.new()

    params.FilterType =
        Enum.RaycastFilterType.Exclude

    local exclude = {}

    local character =
        self:Character()

    if character then
        exclude[#exclude + 1] =
            character
    end

    if self.Runtime.AttackTarget
        and self.Runtime.AttackTarget.Parent then

        exclude[#exclude + 1] =
            self.Runtime.AttackTarget
    end

    params.FilterDescendantsInstances =
        exclude

    params.IgnoreWater =
        false

    local drop =
        tonumber(maxDrop)
        or 14

    local hit =
        self.S.Workspace:Raycast(
            root.Position
                + Vector3.new(
                    0,
                    1.5,
                    0
                ),
            Vector3.new(
                0,
                -drop,
                0
            ),
            params
        )

    if not hit then
        return false,
            nil
    end

    return true,
        hit
end

function H:CombatFloorSafetyStep()
    if not self.State.AutoLevelFarm
        or not self.State.AutoFarmMobs then

        return false
    end

    local root =
        self:Root()

    if not root then
        return false
    end

    -- The below-boss stance intentionally has no ground directly under the
    -- character. The support force holds height while a live boss is close.
    -- A real fall still uses the existing safe-ground recovery below.
    local hoverTarget = self.Runtime.BossHoverActive

    if self.State.BossHoverFarm
        and hoverTarget
        and hoverTarget == self.Runtime.AttackTarget
        and self:IsCombatModel(hoverTarget)
        and root.Position.Y > self.S.Workspace.FallenPartsDestroyHeight + 30
        and root.AssemblyLinearVelocity.Y > -65 then

        local bossRoot = hoverTarget:FindFirstChild("HumanoidRootPart", true)
            or hoverTarget.PrimaryPart

        if bossRoot and (root.Position - bossRoot.Position).Magnitude
            <= (self.Runtime.BossHoverController and 24 or 7) then
            return false
        end
    end

    local hasGround =
        self:CombatGroundUnderRoot(
            16
        )

    local fallingHard =
        root.AssemblyLinearVelocity.Y
        < -65

    if hasGround
        and not fallingHard then

        return false
    end

    local safe =
        self.Runtime.MobSafeCFrame

    if safe
        and os.clock()
            - (
                self.Runtime.MobSafeAt
                or 0
            )
            <= 8 then

        if self.Runtime.SimpleDirectTween then
            pcall(
                function()
                    self.Runtime.SimpleDirectTween:Cancel()
                end
            )

            self.Runtime.SimpleDirectTween =
                nil

            self.Runtime.SimpleDirectGoal =
                nil

            self.Runtime.SimpleDirectKey =
                nil
        end

        self:StopSmoothMobTravel()

        self:SetMobTravelNoclip(
            false
        )

        self:SetManualFarmNoclip(
            false
        )

        pcall(
            function()
                root.AssemblyLinearVelocity =
                    Vector3.zero

                root.AssemblyAngularVelocity =
                    Vector3.zero

                root.CFrame =
                    safe
                    + Vector3.new(
                        0,
                        0.4,
                        0
                    )
            end
        )

        self.Runtime.CombatSafetyHoldUntil =
            os.clock() + 0.30

        self:SetStatus(
            "Auto Level • prevented combat void fall"
        )

        return true
    end

    -- No confirmed safe anchor yet: stop all movement rather than continuing
    -- to follow an attack target into unloaded/empty space.
    self:StopSmoothMobTravel()
    self:StopMovement()
    self:SetMobTravelNoclip(
        false
    )
    self:SetManualFarmNoclip(
        false
    )

    self.Runtime.CombatSafetyHoldUntil =
        os.clock() + 0.25

    return true
end

function H:UpdateMobSafeAnchor()
    local root =
        self:Root()

    if not root then
        return
    end

    local params =
        RaycastParams.new()

    params.FilterType =
        Enum.RaycastFilterType.Exclude

    local character =
        self:Character()

    params.FilterDescendantsInstances =
        character
        and {character}
        or {}

    params.IgnoreWater =
        false

    local hit =
        self.S.Workspace:Raycast(
            root.Position
                + Vector3.new(
                    0,
                    1,
                    0
                ),
            Vector3.new(
                0,
                -9,
                0
            ),
            params
        )

    if not hit then
        return
    end

    local groundDistance =
        root.Position.Y
        - hit.Position.Y

    if groundDistance < -1
        or groundDistance > 7 then
        return
    end

    local velocity =
        root.AssemblyLinearVelocity

    if math.abs(velocity.Y) > 55 then
        return
    end

    self.Runtime.MobSafeCFrame =
        root.CFrame

    self.Runtime.MobSafeAt =
        os.clock()
end

function H:RecoverMobKnockback(mobRoot)
    local root =
        self:Root()

    if root and mobRoot and self.Runtime.BossHoverController
        and (root.Position - mobRoot.Position).Magnitude < 12
        and root.Position.Y > self.S.Workspace.FallenPartsDestroyHeight + 30 then
        return false
    end

    local safe =
        self.Runtime.MobSafeCFrame

    if not root
        or not safe then
        return false
    end

    if os.clock()
        - (
            self.Runtime.MobSafeAt
            or 0
        )
        > 6 then
        return false
    end

    local velocity =
        root.AssemblyLinearVelocity

    local dropped =
        root.Position.Y
        < safe.Position.Y - 11

    local launchedDown =
        velocity.Y < -90

    local wayBelowTarget =
        mobRoot
        and root.Position.Y
            < mobRoot.Position.Y - 16

    if not dropped
        and not launchedDown
        and not wayBelowTarget then
        return false
    end

    if self.Runtime.SimpleDirectTween then
        pcall(function()
            self.Runtime.SimpleDirectTween:Cancel()
        end)

        self.Runtime.SimpleDirectTween = nil
        self.Runtime.SimpleDirectGoal = nil
        self.Runtime.SimpleDirectKey = nil
    end

    -- Emergency only: return to the most recent raycast-confirmed ground
    -- position instead of allowing a punch to send the character into void.
    pcall(function()
        root.AssemblyLinearVelocity =
            Vector3.zero

        root.AssemblyAngularVelocity =
            Vector3.zero

        root.CFrame =
            safe
            + Vector3.new(
                0,
                0.75,
                0
            )
    end)

    self.Runtime.MobRecoveredAt =
        os.clock()

    self:SetStatus(
        "Mob Farm • recovered from knockback"
    )

    return true
end


function H:GroundClampPosition(position, fallbackY, extraHeight)
    if typeof(position) ~= "Vector3" then
        return nil
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    local character = self:Character()

    params.FilterDescendantsInstances =
        character
        and {character}
        or {}

    params.IgnoreWater = false

    local hit = self.S.Workspace:Raycast(
        position + Vector3.new(0, 9, 0),
        Vector3.new(0, -30, 0),
        params
    )

    if hit then
        return Vector3.new(
            position.X,
            hit.Position.Y + (tonumber(extraHeight) or 2.55),
            position.Z
        )
    end

    return Vector3.new(
        position.X,
        fallbackY or position.Y,
        position.Z
    )
end

function H:MobSafeRingGoal(mobRoot, radius)
    local root = self:Root()

    if not root or not mobRoot then
        return nil
    end

    radius = tonumber(radius) or 8.5

    local away = Vector3.new(
        root.Position.X - mobRoot.Position.X,
        0,
        root.Position.Z - mobRoot.Position.Z
    )

    if away.Magnitude < 0.1 then
        local look = mobRoot.CFrame.LookVector
        away = Vector3.new(-look.X, 0, -look.Z)
    end

    if away.Magnitude < 0.1 then
        away = Vector3.new(1, 0, 0)
    else
        away = away.Unit
    end

    local raw = mobRoot.Position + away * radius

    return self:GroundClampPosition(
        raw,
        root.Position.Y,
        2.55
    )
end

function H:MobStrikeGoal(mob, mobRoot)
    if not mob or not mobRoot then
        return nil
    end

    local look = mobRoot.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)

    if flat.Magnitude < 0.1 then
        flat = Vector3.new(0, 0, -1)
    else
        flat = flat.Unit
    end

    local raw = mobRoot.Position - flat * 1.35

    return self:GroundClampPosition(
        raw,
        mobRoot.Position.Y,
        2.55
    )
end

function H:ResetMobPokeState()
    self.Runtime.MobPokePhase = "SAFE"
    self.Runtime.MobPokeTarget = nil
    self.Runtime.MobPokeRetreatAt = 0
    self.Runtime.MobPokeSafeUntil = 0
    self.Runtime.MobPokeStrikeStartedAt = 0
end

function H:MobHitAndRunStep(mob, mobRoot)
    if not mob or not mobRoot then
        self:ResetMobPokeState()
        return true
    end

    local root = self:Root()

    if not root then
        return true
    end

    local unique = tostring(
        mob:GetAttribute("UniqueName")
        or mob.Name
    )

    if self.Runtime.MobPokeTarget ~= unique then
        self:ResetMobPokeState()
        self.Runtime.MobPokeTarget = unique
        self.Runtime.MobPokePhase = "SAFE"
    end

    local now = os.clock()
    local phase = self.Runtime.MobPokePhase or "SAFE"

    -- Any threat cancels offense immediately.
    if self:IsThreatWindow(mob)
        or (
            self.State.AutoParry
            and self:NearestActiveThreat()
        ) then

        self.Runtime.MobPokePhase = "SAFE"
        self.Runtime.MobPokeSafeUntil = now + 0.30

        self:StopAttackHold()
        self.Runtime.ForceAttackUntil = 0
        self.Runtime.BlockReleaseUntil = 0
        self:FaceTarget(mob)
        self:StartBlocking(true)

        local safe = self:MobSafeRingGoal(mobRoot, 8.5)

        if safe
            and (root.Position - safe).Magnitude > 2 then

            self:SimpleDirectTween(
                safe,
                mobRoot.Position,
                78,
                "POKE_SAFE:" .. unique
            )
        end

        self:SetStatus(
            "Mob Farm • threat detected • guard + disengage"
        )

        return true
    end

    if phase == "SAFE" then
        self:StopAttackHold()
        self:FaceTarget(mob)
        self.Runtime.ForceAttackUntil = 0
        self.Runtime.BlockReleaseUntil = 0
        self:StartBlocking(false)

        local safe = self:MobSafeRingGoal(mobRoot, 8.5)

        if not safe then
            return true
        end

        local safeDistance = (root.Position - safe).Magnitude

        if safeDistance > 2.0 then
            self:SimpleDirectTween(
                safe,
                mobRoot.Position,
                78,
                "POKE_SAFE:" .. unique
            )

            self:SetStatus(
                "Mob Farm • guard → safe ring"
            )

            return true
        end

        if self.Runtime.SimpleDirectTween then
            pcall(function()
                self.Runtime.SimpleDirectTween:Cancel()
            end)

            self.Runtime.SimpleDirectTween = nil
            self.Runtime.SimpleDirectGoal = nil
            self.Runtime.SimpleDirectKey = nil
        end

        if self.Runtime.MobPokeSafeUntil == 0 then
            self.Runtime.MobPokeSafeUntil = now + 0.28
        end

        if now < self.Runtime.MobPokeSafeUntil then
            self:SetStatus(
                "Mob Farm • guard • waiting for opening"
            )
            return true
        end

        if now < (self.Runtime.NextPunchAt or 0) then
            self:SetStatus(
                "Mob Farm • guard • punch cooldown"
            )
            return true
        end

        self.Runtime.MobPokePhase = "STRIKE"
        self.Runtime.MobPokeStrikeStartedAt = now
        return true
    end

    if phase == "STRIKE" then
        local strike = self:MobStrikeGoal(mob, mobRoot)

        if not strike then
            self.Runtime.MobPokePhase = "SAFE"
            return true
        end

        local strikeDistance = (root.Position - strike).Magnitude

        if strikeDistance > 1.6 then
            self:StartBlocking(false)

            self:SimpleDirectTween(
                strike,
                mobRoot.Position,
                105,
                "POKE_STRIKE:" .. unique
            )

            self:SetStatus(
                "Mob Farm • guarded approach → strike"
            )

            return true
        end

        if self.Runtime.SimpleDirectTween then
            pcall(function()
                self.Runtime.SimpleDirectTween:Cancel()
            end)

            self.Runtime.SimpleDirectTween = nil
            self.Runtime.SimpleDirectGoal = nil
            self.Runtime.SimpleDirectKey = nil
        end

        self:FaceTarget(mob)

        self:PulseAttack(mob)

        self.Runtime.MobPokePhase = "HIT_WAIT"
        self.Runtime.MobPokeRetreatAt = now + 0.23

        self:SetStatus(
            "Mob Farm • single M1 → disengage"
        )

        return true
    end

    if phase == "HIT_WAIT" then
        self:FaceTarget(mob)

        if now < (self.Runtime.MobPokeRetreatAt or 0) then
            return true
        end

        self.Runtime.MobPokePhase = "RETREAT"
        return true
    end

    if phase == "RETREAT" then
        self:StopAttackHold()
        self.Runtime.ForceAttackUntil = 0
        self.Runtime.BlockReleaseUntil = 0
        self:FaceTarget(mob)
        self:StartBlocking(true)

        local safe = self:MobSafeRingGoal(mobRoot, 9.5)

        if not safe then
            self.Runtime.MobPokePhase = "SAFE"
            return true
        end

        local d = (root.Position - safe).Magnitude

        if d > 1.8 then
            self:SimpleDirectTween(
                safe,
                mobRoot.Position,
                88,
                "POKE_RETREAT:" .. unique
            )

            self:SetStatus(
                "Mob Farm • disengaging after M1"
            )

            return true
        end

        if self.Runtime.SimpleDirectTween then
            pcall(function()
                self.Runtime.SimpleDirectTween:Cancel()
            end)

            self.Runtime.SimpleDirectTween = nil
            self.Runtime.SimpleDirectGoal = nil
            self.Runtime.SimpleDirectKey = nil
        end

        self.Runtime.MobPokePhase = "SAFE"
        self.Runtime.MobPokeSafeUntil = now + 0.32

        self:SetStatus(
            "Mob Farm • guarded • next opening"
        )

        return true
    end

    self.Runtime.MobPokePhase = "SAFE"
    return true
end

function H:ResetOrbitState()
    self.Runtime.OrbitTarget = nil
    self.Runtime.OrbitModel = nil
    self.Runtime.OrbitRoot = nil
    self.Runtime.OrbitAngle = 0
    self.Runtime.OrbitLastAt = os.clock()
    self.Runtime.OrbitDirection = 1
    self.Runtime.OrbitGoal = nil
    self.Runtime.OrbitBoostUntil = 0
    self.Runtime.OrbitContactUntil = 0
    self.Runtime.OrbitHardContactUntil = 0

    -- BUILD 68: overhead farm owns noclip while actively hovering.
    if type(self.SetManualFarmNoclip) == "function" then
        self:SetManualFarmNoclip(false)
    end

    local hum =
        self:Humanoid()

    if hum then
        pcall(
            function()
                hum.AutoRotate =
                    true
            end
        )
    end
end

function H:OrbitGroundGoal(mobRoot, radius, angle)
    if not mobRoot then
        return nil
    end

    local offset = Vector3.new(
        math.cos(angle) * radius,
        0,
        math.sin(angle) * radius
    )

    local raw = mobRoot.Position + offset

    return self:GroundClampPosition(
        raw,
        mobRoot.Position.Y,
        2.55
    )
end

function H:ContinuousOrbitMovement(mob, mobRoot)
    local root =
        self:Root()

    local hum =
        self:Humanoid()

    if not root
        or not hum
        or not mob
        or not mob.Parent
        or not mobRoot
        or not mobRoot.Parent then

        return false
    end

    if self:CombatFloorSafetyStep() then
        return true
    end

    if os.clock()
        < (
            self.Runtime.CombatSafetyHoldUntil
            or 0
        ) then

        return true
    end

    self.Runtime.OrbitModel =
        nil

    self.Runtime.OrbitRoot =
        nil

    self.Runtime.OrbitGoal =
        nil

    self:SetManualFarmNoclip(
        false
    )

    self:SetMobTravelNoclip(
        false
    )

    local offset =
        mobRoot.Position
        - root.Position

    local flatDistance =
        Vector3.new(
            offset.X,
            0,
            offset.Z
        ).Magnitude

    local verticalDistance =
        math.abs(
            offset.Y
        )

    -- BUILD 95:
    -- This is the important change for the "only when hitting" void bug.
    -- Inside real melee range, DO NOT tween / reposition the player at all.
    -- Let the game's punch animation own the character during the hit.
    if flatDistance <= 4.25
        and verticalDistance <= 4.75 then

        if self.Runtime.SimpleDirectTween
            and string.sub(
                tostring(
                    self.Runtime.SimpleDirectKey
                    or ""
                ),
                1,
                6
            ) == "MELEE:" then

            pcall(
                function()
                    self.Runtime.SimpleDirectTween:Cancel()
                end
            )

            self.Runtime.SimpleDirectTween =
                nil

            self.Runtime.SimpleDirectGoal =
                nil

            self.Runtime.SimpleDirectKey =
                nil
        end

        pcall(
            function()
                hum.AutoRotate =
                    true
            end
        )

        self:FaceTarget(
            mob
        )

        self.Runtime.CloseMeleeMode =
            "contact-lock"

        return true
    end

    local goal,
        mode =
        self:GetSafeMobGoal(
            mob,
            mobRoot
        )

    if not goal then
        self:StopMovement()

        self.Runtime.CloseMeleeMode =
            "waiting-ground"

        return true
    end

    local goalDistance =
        (
            root.Position
            - goal
        ).Magnitude

    local unique =
        tostring(
            mob:GetAttribute(
                "UniqueName"
            )
            or mob.Name
        )

    -- While a punch has just been accepted, do not let movement fight the
    -- animation unless the target was genuinely knocked far away.
    local recentlyHit =
        os.clock()
        - (
            self.Runtime.LastBackgroundM1Accepted
            or -10
        )
        < 0.34

    if recentlyHit
        and flatDistance < 7.0 then

        self:FaceTarget(
            mob
        )

        self.Runtime.CloseMeleeMode =
            "hit-lock"

        return true
    end

    if goalDistance > 0.85 then
        self:SimpleDirectTween(
            goal,
            mobRoot.Position,
            125,
            "MELEE:"
                .. unique
        )
    end

    self:FaceTarget(
        mob
    )

    self.Runtime.CloseMeleeMode =
        mode

    return true
end


function H:SmoothOrbitFrame(dt)
    -- BUILD 84:
    -- Intentionally disabled. Auto Farm no longer uses Kill Aura / overhead
    -- RenderStepped movement. Grounded close-melee positioning is handled by
    -- ContinuousOrbitMovement() from the normal Farm loop.
    return
end


function H:AggressiveMobGoal(mob, mobRoot)
    if not mob
        or not mobRoot then
        return nil
    end

    local look =
        mobRoot.CFrame.LookVector

    local right =
        mobRoot.CFrame.RightVector

    local flatLook =
        Vector3.new(
            look.X,
            0,
            look.Z
        )

    local flatRight =
        Vector3.new(
            right.X,
            0,
            right.Z
        )

    if flatLook.Magnitude < 0.05 then
        flatLook =
            Vector3.new(
                0,
                0,
                -1
            )
    else
        flatLook =
            flatLook.Unit
    end

    if flatRight.Magnitude < 0.05 then
        flatRight =
            Vector3.new(
                1,
                0,
                0
            )
    else
        flatRight =
            flatRight.Unit
    end

    -- Rear/side pocket. Staying slightly off-centre makes it harder for a
    -- straight frontal M1 to connect while keeping our own M1 in range.
    local sideSign =
        self.Runtime.AggressiveSideSign

    if sideSign == nil then
        local unique =
            tostring(
                mob:GetAttribute(
                    "UniqueName"
                )
                or mob.Name
            )

        sideSign =
            (
                #unique % 2 == 0
            )
            and 1
            or -1

        self.Runtime.AggressiveSideSign =
            sideSign
    end

    local raw =
        mobRoot.Position
        - flatLook * 1.20
        + flatRight * (0.70 * sideSign)

    return self:GroundClampPosition(
        raw,
        mobRoot.Position.Y,
        2.55
    )
end

function H:ResetAggressiveMobState()
    self:StopBossHover()
    self.Runtime.MobComboRestUntil = 0
    self.Runtime.MobComboRestStartedAt = 0
    self.Runtime.MobComboRiseAt = 0
    self.Runtime.MobComboIndex = 0
    self.Runtime.MobComboRestDuration = 0
    self.Runtime.MobComboLastCountedStamp =
        self:GetLastPunchStamp()

    self.Runtime.MobComboNextPunchAt = 0

    self.Runtime.AggressiveTarget =
        nil

    self.Runtime.AggressiveSideSign =
        nil

    self.Runtime.AggressiveLostAt =
        0

    self.Runtime.AggressiveLastCloseAt =
        0
end

function H:PrepareMobPunchContact(mob, mobRoot)
    local root =
        self:Root()

    if not root
        or not mob
        or not mobRoot then

        return false
    end

    local now =
        os.clock()

    self.Runtime.OrbitContactUntil =
        math.max(
            self.Runtime.OrbitContactUntil
            or 0,
            now + 0.26
        )

    local distance =
        (
            root.Position
            - mobRoot.Position
        ).Magnitude

    local vertical =
        math.abs(
            root.Position.Y
            - mobRoot.Position.Y
        )

    -- Don't throw the punch just because the animation cooldown is ready.
    -- First make sure the server sees us in the actual contact pocket.
    if distance > 3.35
        or vertical > 3.65 then

        self:FaceTarget(
            mob
        )

        return false
    end

    -- Final facing check. SmoothOrbitFrame already faces the mob each frame,
    -- but this catches a frame immediately after a knockback/target turn.
    local toTarget =
        mobRoot.Position
        - root.Position

    if toTarget.Magnitude > 0.05 then
        local flat =
            Vector3.new(
                toTarget.X,
                0,
                toTarget.Z
            )

        local forward =
            Vector3.new(
                root.CFrame.LookVector.X,
                0,
                root.CFrame.LookVector.Z
            )

        if flat.Magnitude > 0.05
            and forward.Magnitude > 0.05 then

            local dot =
                forward.Unit:Dot(
                    flat.Unit
                )

            if dot < 0.72 then
                self:FaceTarget(
                    mob
                )

                return false
            end
        end
    end

    return true
end

function H:BeginPostKillLoot(origin, deadMob)
    self:ReleaseBossHold("waiting for next boss")
    if not self.State.AutoFarmMobs then
        return false
    end

    local wantsLoot =
        self.State.AutoChests
        or self.State.AutoDrops
        or self.State.AutoLootAfterKill

    if not wantsLoot then
        return false
    end

    if typeof(origin) ~= "Vector3" then
        local root =
            self:Root()

        origin =
            root
            and root.Position
            or nil
    end

    if typeof(origin) ~= "Vector3" then
        return false
    end

    local now =
        os.clock()

    local bossStore =
        self.Data.AutoLevel

    -- Only a confirmed AFK Boss Loop kill gets the shorter loot handoff.
    -- Keep the existing timing for ordinary mob and Auto Level farming.
    local bossLoopLoot =
        self.State.AutoLevelFarm == true
        and type(bossStore) == "table"
        and bossStore.BossLoopAdvancePending == true
        and type(bossStore.CurrentRecord) == "table"
        and tostring(
            bossStore.CurrentRecord.Category
            or ""
        ) == "BossHunt"

    self.Runtime.PostKillBossLoop =
        bossLoopLoot

    self.Runtime.PostKillLooting =
        true

    self.Runtime.PostKillLootOrigin =
        origin

    self.Runtime.PostKillLootStartedAt =
        now

    self.Runtime.PostKillLootDeadline =
        now
        + (
            bossLoopLoot
            and 1.5
            or (
                self.State.AutoLevelFarm
                and 9.0
                or 7.0
            )
        )

    self.Runtime.PostKillLastSeenAt =
        now

    self.Runtime.PostKillClearSince =
        nil

    self.Runtime.PostKillDeadMob =
        deadMob

    self.Runtime.PostKillProcessed =
        {}

    self.Runtime.PostKillPromptAttemptAt =
        {}

    self.Runtime.PostKillPromptFirstAttemptAt =
        {}

    self.Runtime.PostKillLastScanAt =
        0

    self.Runtime.PostKillNearbyPromptCache =
        nil

    -- Combat/movement must fully hand off to loot collection.
    self:StopSmoothMobTravel()

    self.Runtime.MobApproachTravel =
        false

    self.Runtime.AttackTarget =
        nil

    self.Data.CurrentFarmTarget =
        nil

    self:ResetAggressiveMobState()
    self:ResetOrbitState()

    self:StopAttackHold()
    self:StopBlocking()

    if self.Runtime.SimpleDirectTween then
        pcall(function()
            self.Runtime.SimpleDirectTween:Cancel()
        end)

        self.Runtime.SimpleDirectTween =
            nil

        self.Runtime.SimpleDirectGoal =
            nil

        self.Runtime.SimpleDirectKey =
            nil
    end

    self:SetStatus(
        "Mob Farm • kill confirmed • collecting loot"
    )

    return true
end

function H:WatchFarmMobDeath(mob)
    if not mob
        or not mob.Parent then

        return
    end

    if self.Runtime.WatchedFarmMob
        == mob then

        return
    end

    if self.Runtime.FarmMobDeathConnection then
        self.Runtime.FarmMobDeathConnection:Disconnect()
        self.Runtime.FarmMobDeathConnection = nil
    end
    local watchedKey = self:NormalizeMobText(self.State.SelectedMob)

    self.Runtime.WatchedFarmMob =
        mob

    local hum =
        self:TargetHumanoid(
            mob
        )

    local mobRoot =
        mob:FindFirstChild(
            "HumanoidRootPart",
            true
        )
        or mob.PrimaryPart

    if not hum then
        return
    end

    local connection

    connection =
        hum.Died:Connect(
            function()
                if connection then
                    connection:Disconnect()
                    connection = nil
                end

                if self.Runtime.WatchedFarmMob ~= mob then return end
                self.Runtime.WatchedFarmMob = nil
                self.Runtime.FarmMobDeathConnection = nil
                local current = self.Data.AutoLevel and self.Data.AutoLevel.CurrentRecord
                if self.State.Unloaded or not self.State.AutoFarmMobs
                    or (self.State.AutoLevelFarm and (not current
                        or self:NormalizeMobText(current.Target) ~= watchedKey)) then return end

                local origin =
                    self.Runtime.LastSafeQuestTargetPosition

                if typeof(origin) ~= "Vector3" then
                    if mobRoot
                        and mobRoot.Parent then

                        origin =
                            mobRoot.Position
                    else
                        local root =
                            self:Root()

                        origin =
                            root
                            and root.Position
                            or nil
                    end
                end

                local store =
                    self.Data.AutoLevel

                if self.State.AutoLevelFarm
                    and type(store) == "table"
                    and type(store.CurrentRecord) == "table"
                    and tostring(
                        store.CurrentRecord.Category
                        or ""
                    ) == "BossHunt" then

                    store.BossLoopResumeTarget = nil
                    store.BossLoopResumeRecord = nil
                    store.BossLoopResumePosition = nil

                    store.BossLoopLastKillAt =
                        os.clock()

                    store.BossLoopLastKilledTarget =
                        tostring(
                            store.CurrentRecord.Target
                            or mob.Name
                        )

                    -- BUILD 99:
                    -- Every boss-loop kill rotates after loot. There is no
                    -- quest-giver/turn-in dependency anymore.
                    store.BossLoopAdvancePending =
                        true

                    store.BossLoopSeenTarget =
                        false

                    store.BossLoopSeenTargetKey =
                        nil

                    store.BossLoopLastSeenAt =
                        0

                    store.BossLoopLastSeenModel =
                        nil

                    store.BossLoopLastSeenHealth =
                        nil
                end

                self:BeginPostKillLoot(
                    origin,
                    mob
                )
            end
        )
    self.Runtime.FarmMobDeathConnection = connection
end

function H:IsPostKillProcessed(obj)
    if not obj then
        return true
    end

    local processed =
        self.Runtime.PostKillProcessed

    if type(processed) ~= "table" then
        return false
    end

    local t =
        processed[obj]

    return t ~= nil
        and os.clock() - t < 8
end

function H:MarkPostKillProcessed(obj)
    if not obj then
        return
    end

    if type(
        self.Runtime.PostKillProcessed
    ) ~= "table" then

        self.Runtime.PostKillProcessed =
            {}
    end

    self.Runtime.PostKillProcessed[obj] =
        os.clock()
end

-- The boss loot pass asks for both chests and floor drops. Share one prompt
-- snapshot between those searches instead of walking all Workspace twice.
function H:PostKillNearbyPrompts(origin, radius)
    local now = os.clock()
    local cache = self.Runtime.PostKillNearbyPromptCache

    if type(cache) == "table"
        and cache.Origin == origin
        and cache.Radius == radius
        and now - cache.At < 0.10 then

        return cache.Prompts
    end

    local prompts = {}

    for _, obj in ipairs(self.S.Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt")
            and obj.Parent
            and obj.Enabled then

            local pos = self:PromptWorldPosition(obj)

            if pos and (pos - origin).Magnitude <= radius then
                table.insert(prompts, obj)
            end
        end
    end

    self.Runtime.PostKillNearbyPromptCache = {
        Origin = origin,
        Radius = radius,
        At = now,
        Prompts = prompts,
    }

    return prompts
end

function H:FindPostKillChest(origin, radius)
    if not self.State.AutoChests
        or typeof(origin) ~= "Vector3" then

        return nil
    end

    radius =
        tonumber(radius)
        or 50

    local root =
        self:Root()

    if not root then
        return nil
    end

    local bestPrompt
    local bestPosition
    local bestDistance =
        math.huge

    local function consider(prompt)
        if not prompt
            or not prompt.Parent
            or prompt.Enabled == false
            or not self:IsChestPrompt(
                prompt
            )
            or self:IsPostKillProcessed(
                prompt
            ) then

            return
        end

        local pos =
            self:PromptWorldPosition(
                prompt
            )

        if not pos
            or (
                pos
                - origin
            ).Magnitude > radius then

            return
        end

        local d =
            (
                root.Position
                - pos
            ).Magnitude

        if d < bestDistance then
            bestPrompt =
                prompt

            bestPosition =
                pos

            bestDistance =
                d
        end
    end

    for _, chest in ipairs(
        self.S.CollectionService:GetTagged(
            self:ChestTag()
        )
    ) do

        if chest
            and chest.Parent then

            consider(
                self:PromptOf(
                    chest
                )
            )
        end
    end

    if not bestPrompt then
        for _, obj in ipairs(
            self:PostKillNearbyPrompts(origin, radius)
        ) do
            consider(obj)
        end
    end

    return bestPrompt,
        bestDistance,
        bestPosition
end

function H:FindPostKillDrop(origin, radius)
    local enabled =
        self.State.AutoDrops
        or self.State.AutoLootAfterKill

    if not enabled
        or typeof(origin) ~= "Vector3" then

        return nil
    end

    radius =
        tonumber(radius)
        or 50

    local root =
        self:Root()

    if not root then
        return nil
    end

    local bestDrop
    local bestPrompt
    local bestPosition
    local bestDistance =
        math.huge

    local function consider(drop, prompt)
        if not drop
            or not drop.Parent
            or self:IsPostKillProcessed(
                drop
            ) then

            return
        end

        prompt =
            prompt
            or self:PromptOf(
                drop
            )

        if not prompt
            or not prompt.Parent
            or prompt.Enabled == false then

            return
        end

        local pos =
            self:ObjectWorldPosition(
                drop
            )

        if not pos then
            pos =
                self:PromptWorldPosition(
                    prompt
                )
        end

        if not pos
            or (
                pos
                - origin
            ).Magnitude > radius then

            return
        end

        local d =
            (
                root.Position
                - pos
            ).Magnitude

        if d < bestDistance then
            bestDrop =
                drop

            bestPrompt =
                prompt

            bestPosition =
                pos

            bestDistance =
                d
        end
    end

    for _, drop in ipairs(
        self.S.CollectionService:GetTagged(
            self:DropTag()
        )
    ) do

        consider(
            drop
        )
    end

    -- Fallback for untagged physical rewards such as:
    --   "Mouth Dagger" / "Claim"
    if not bestPrompt then
        local prompt,
            distance,
            position =
            self:NearestLootPickupPrompt(
                math.huge,
                origin,
                radius,
                self:PostKillNearbyPrompts(origin, radius)
            )

        if prompt
            and position then

            bestPrompt =
                prompt

            bestDistance =
                distance

            bestPosition =
                position

            bestDrop =
                prompt.Parent
        end
    end

    return bestDrop,
        bestDistance,
        bestPrompt,
        bestPosition
end

function H:FinishPostKillLoot()
    local bossLoopLoot =
        self.Runtime.PostKillBossLoop == true

    self.Runtime.PostKillLooting =
        false

    self.Runtime.PostKillBossLoop =
        false

    self.Runtime.PostKillLootOrigin =
        nil

    self.Runtime.PostKillLootStartedAt =
        0

    self.Runtime.PostKillLootDeadline =
        0

    self.Runtime.PostKillLastSeenAt =
        0

    self.Runtime.PostKillClearSince =
        nil

    self.Runtime.PostKillDeadMob =
        nil

    self.Runtime.PostKillProcessed =
        nil

    self.Runtime.PostKillPromptAttemptAt =
        nil

    self.Runtime.PostKillPromptFirstAttemptAt =
        nil

    self.Runtime.PostKillLastScanAt =
        0

    self.Runtime.PostKillNearbyPromptCache =
        nil

    if self.Runtime.SimpleDirectTween then
        pcall(function()
            self.Runtime.SimpleDirectTween:Cancel()
        end)

        self.Runtime.SimpleDirectTween =
            nil

        self.Runtime.SimpleDirectGoal =
            nil

        self.Runtime.SimpleDirectKey =
            nil
    end

    self:SetStatus(
        bossLoopLoot
        and "Boss Loop • loot clear • next boss"
        or "Mob Farm • loot clear • reacquiring mob"
    )

    -- Select the next boss now, rather than waiting for the 0.35s AutoLevel
    -- timer. FarmStep will start travelling on its following tick.
    if bossLoopLoot
        and self.State.AutoLevelFarm
        and self.State.AutoFarmMobs
        and self.Data.AutoLevel
        and self.Data.AutoLevel.BossLoopAdvancePending then

        self:AutoLevelFarmStep(false)
    end
end

function H:PostKillLootStep()
    if not self.Runtime.PostKillLooting then
        return false
    end

    local origin =
        self.Runtime.PostKillLootOrigin

    if typeof(origin) ~= "Vector3" then
        self:FinishPostKillLoot()
        return true
    end

    local now =
        os.clock()

    local startedAt =
        self.Runtime.PostKillLootStartedAt
        or now

    local deadline =
        self.Runtime.PostKillLootDeadline
        or (
            startedAt + 7
        )

    local bossLoopLoot =
        self.Runtime.PostKillBossLoop == true

    -- A persistent prompt must never hold the boss rotation indefinitely.
    if bossLoopLoot and now - startedAt >= 5.0 then
        self:FinishPostKillLoot()
        return true
    end

    -- Give death rewards/chests a short moment to spawn.
    if now - startedAt
        < (
            self.State.AutoLevelFarm
            and 0.45
            or 0.25
        ) then
        self:SetStatus(
            "Mob Farm • waiting for kill loot"
        )

        return true
    end

    -- FarmStep runs every 0.03s. Loot prompts change much more slowly;
    -- cap boss loot scans at roughly six per second.
    if bossLoopLoot
        and now - (self.Runtime.PostKillLastScanAt or 0) < 0.16 then

        return true
    end

    self.Runtime.PostKillLastScanAt = now

    local chestPrompt,
        chestDistance,
        chestPosition =
        self:FindPostKillChest(
            origin,
            50
        )

    local drop,
        dropDistance,
        dropPrompt,
        dropPosition =
        self:FindPostKillDrop(
            origin,
            50
        )

    local prompt
    local position
    local distance
    local object
    local kind

    -- Collect whichever reachable reward is nearest to us.
    if chestPrompt
        and (
            not dropPrompt
            or (
                tonumber(chestDistance)
                or math.huge
            )
                <= (
                    tonumber(dropDistance)
                    or math.huge
                )
        ) then

        prompt =
            chestPrompt

        position =
            chestPosition

        distance =
            chestDistance

        object =
            chestPrompt

        kind =
            "chest"
    elseif dropPrompt then
        prompt =
            dropPrompt

        position =
            dropPosition

        distance =
            dropDistance

        object =
            drop

        kind =
            "drop"
    end

    if prompt
        and position then

        self.Runtime.PostKillLastSeenAt =
            now

        self.Runtime.PostKillClearSince =
            nil

        local maxDistance =
            tonumber(
                prompt.MaxActivationDistance
            )
            or 8

        if distance
            and distance
                <= maxDistance + 1.0 then

            self:StopMovement()

            if self.Runtime.SimpleDirectTween then
                pcall(function()
                    self.Runtime.SimpleDirectTween:Cancel()
                end)

                self.Runtime.SimpleDirectTween =
                    nil

                self.Runtime.SimpleDirectGoal =
                    nil

                self.Runtime.SimpleDirectKey =
                    nil
            end

            local attempts =
                self.Runtime.PostKillPromptAttemptAt
                or {}

            self.Runtime.PostKillPromptAttemptAt =
                attempts

            local lastAttempt =
                attempts[
                    prompt
                ]
                or 0

            if now - lastAttempt < 0.25 then
                return true
            end

            attempts[
                prompt
            ] =
                now

            local firstAttempts =
                self.Runtime.PostKillPromptFirstAttemptAt
                or {}

            self.Runtime.PostKillPromptFirstAttemptAt =
                firstAttempts

            firstAttempts[prompt] =
                firstAttempts[prompt]
                or now

            if kind == "chest" then
                self:SetStatus(
                    "Boss Loop • opening boss chest"
                )

                self:OpenChestPromptReliable(
                    prompt
                )
            else
                self:SetStatus(
                    "Boss Loop • picking up boss drop"
                )

                self:CollectBossLootPrompt(
                    prompt
                )
            end

            -- Retry initially: some prompts ignore the first interaction.
            -- If a boss prompt stays enabled for a full second after repeated
            -- attempts, move past that stale prompt and check for its drops.
            if not prompt.Parent
                or prompt.Enabled == false
                or (
                    bossLoopLoot
                    and now - firstAttempts[prompt] >= 1.0
                ) then

                self:MarkPostKillProcessed(
                    object
                )

                self:MarkPostKillProcessed(
                    prompt
                )
            end

            return true
        end

        local root =
            self:Root()

        if not root then
            return true
        end

        local direction =
            root.Position
            - position

        if direction.Magnitude < 0.05 then
            direction =
                Vector3.new(
                    1,
                    0,
                    0
                )
        end

        local standDistance =
            math.max(
                1.2,
                math.min(
                    maxDistance - 0.6,
                    3.25
                )
            )

        local goal =
            position
            + direction.Unit
            * standDistance

        goal =
            self:GroundClampPosition(
                goal,
                position.Y,
                2.55
            )
            or goal

        self:SetStatus(
            "Mob Farm • post-kill "
            .. kind
            .. " • "
            .. tostring(
                math.floor(
                    tonumber(distance)
                    or 0
                )
            )
            .. " studs"
        )

        self:SimpleDirectTween(
            goal,
            position,
            120,
            "POST_KILL_LOOT"
        )

        return true
    end

    if not self.Runtime.PostKillClearSince then
        self.Runtime.PostKillClearSince =
            now
    end

    -- Chest contents can appear just after the chest itself is opened, so wait
    -- for a genuine quiet period before handing movement back to Mob Farm.
    local clearFor =
        now
        - (
            self.Runtime.PostKillClearSince
            or now
        )

    local loopLootControls =
        self.Runtime.PostKillBossLoop == true

    local quietNeeded =
        loopLootControls
        and 1.0
        or (
            self.State.AutoLevelFarm
            and 2.25
            or 1.0
        )

    -- A boss gets 1.5 seconds for its first reward to spawn. After opening
    -- a chest or collecting a drop, give newly spawned contents one quiet
    -- second even if the initial deadline has already passed.
    if (
        loopLootControls
        and (
            now < deadline
            or clearFor < quietNeeded
        )
    ) or (
        not loopLootControls
        and now < deadline
        and clearFor < quietNeeded
    ) then

        self:SetStatus(
            "Mob Farm • scanning for remaining loot"
        )

        return true
    end

    self:FinishPostKillLoot()

    return true
end

-- ============================================================
-- BUILD 58 • 10% EXECUTE LOCK
-- ============================================================
-- Slayers 2 public hubs describe the current instant-kill route as killing an
-- NPC only while the client owns its physics assembly. That also explains why
-- altering Combat_Service damage arguments did nothing in our traces.
--
-- We do NOT spoof normal M1 damage here. The existing farm deals the opening
-- damage normally; once the configured HP threshold is reached and ownership
-- is local, the NPC assembly is pushed below FallenPartsDestroyHeight. Roblox's
-- server then handles the actual death/removal and the existing death/loot
-- watcher takes over.

function H:InstantKillThresholdPercent()
    local isDungeon =
        self.S.Workspace:GetAttribute("IsMinigame") == true

    if isDungeon then
        return math.clamp(
            tonumber(self.State.InstantKillDungeonThreshold) or 100,
            1,
            100
        ), true
    end

    -- Main world means "execute when REMAINING HP is <= 10%".
    return math.clamp(
        tonumber(self.State.InstantKillMainThreshold) or 10,
        1,
        100
    ), false
end


function H:GetInstantKillHealthState(mobHum)
    if not mobHum
        or not mobHum.Parent
        or mobHum.MaxHealth <= 0 then

        return false, false, 0, 0
    end

    local threshold =
        select(
            1,
            self:InstantKillThresholdPercent()
        )

    local hpPercent =
        (
            mobHum.Health
            / mobHum.MaxHealth
        )
        * 100

    local reached =
        hpPercent <= threshold

    -- BUILD 59 brake zone:
    -- Once we get close to the execute threshold, stop hammering punch()
    -- every 12ms. This prevents multiple accepted M1s already being in flight
    -- by the time the replicated Humanoid health reaches 10%.
    local brakeBuffer =
        12

    local braking =
        hpPercent <= (
            threshold
            + brakeBuffer
        )

    return reached,
        braking,
        hpPercent,
        threshold
end

function H:HoldM1ForInstantKill(mobHum)
    if not self.State.InstantKill
        or not self.State.AutoFarmMobs then

        return false
    end

    local reached =
        select(
            1,
            self:GetInstantKillHealthState(
                mobHum
            )
        )

    if reached then
        -- Hard lock ALL background M1 traffic while ownership is being
        -- acquired / while the execute is in progress.
        self.Runtime.NextBackgroundM1At =
            math.huge

        self.Runtime.InstantKillThresholdLocked =
            true

        self:StopAttackHold()

        return true
    end

    if self.Runtime.InstantKillThresholdLocked then
        self.Runtime.InstantKillThresholdLocked =
            false

        self.Runtime.NextBackgroundM1At =
            0
    end

    return false
end

function H:BoostInstantKillSimulationRadius()
    local lp = self.S.Players.LocalPlayer
    if not lp then
        return false
    end

    local env =
        (getgenv and getgenv())
        or _G

    local didAnything = false

    local sim =
        rawget(env, "setsimulationradius")
        or rawget(_G, "setsimulationradius")

    if type(sim) == "function" then
        local ok = pcall(
            sim,
            math.huge,
            math.huge
        )

        didAnything =
            didAnything
            or ok
    end

    local shp =
        rawget(env, "sethiddenproperty")
        or rawget(_G, "sethiddenproperty")

    if type(shp) == "function" then
        local okA =
            pcall(
                shp,
                lp,
                "SimulationRadius",
                math.huge
            )

        local okB =
            pcall(
                shp,
                lp,
                "MaximumSimulationRadius",
                math.huge
            )

        didAnything =
            didAnything
            or okA
            or okB
    end

    return didAnything
end

function H:IsNetworkOwnerOfPart(part, verifiedOnly)
    if not part
        or not part:IsA("BasePart")
        or part.Anchored
        or not part:IsDescendantOf(self.S.Workspace) then

        return false, "invalid-part"
    end

    local env =
        (getgenv and getgenv())
        or _G

    local checker =
        rawget(env, "isnetworkowner")
        or rawget(_G, "isnetworkowner")
        or isnetworkowner

    if type(checker) == "function" then
        local ok, owned =
            pcall(
                checker,
                part
            )

        if ok then
            if verifiedOnly and type(owned) ~= "boolean" then
                return nil, "ownership-check-unavailable"
            end
            return owned == true, "isnetworkowner"
        end
    end

    -- The optional boss hold requires a positive ownership check. A zero
    -- ReceiveAge alone is not evidence strong enough to move a boss.
    if verifiedOnly then return nil, "ownership-check-unavailable" end

    -- ReceiveAge is only used when the executor does not expose
    -- isnetworkowner. Zero commonly means the assembly is currently being
    -- simulated locally.
    local okAge, receiveAge =
        pcall(function()
            return part.ReceiveAge
        end)

    if okAge
        and tonumber(receiveAge) == 0
        and not part.Anchored then

        return true, "ReceiveAge"
    end

    return false, "not-owned"
end


function H:BossOwnershipSnapshot(force)
    local mob = self.Runtime.AttackTarget
    local root, part
    if mob and self:IsBossLoopTarget(mob) then
        local hum = self:TargetHumanoid(mob)
        if hum and hum.Health > 0 then
            root = mob:FindFirstChild("HumanoidRootPart", true) or mob.PrimaryPart
            if root and root:IsA("BasePart") and root.Parent then
                part = root.AssemblyRootPart or root
            end
        end
    end
    if not part then
        local empty = {At = os.clock(), Label = "NO TARGET", Reason = "waiting for boss"}
        self.Runtime.BossOwnershipSample = empty
        return empty
    end
    local cached = self.Runtime.BossOwnershipSample
    if not force and cached and cached.Target == mob and cached.Root == root
        and cached.Part == part and os.clock() - cached.At < 0.10 then
        return cached
    end
    local owned, reason
    if not part:IsDescendantOf(mob) then
        owned, reason = nil, "shared-assembly"
    else
        owned, reason = self:IsNetworkOwnerOfPart(part, true)
    end
    local rec = self.Data.AutoLevel and self.Data.AutoLevel.CurrentRecord
    local sample = {
        At = os.clock(), Target = mob, Root = root, Part = part,
        Owned = owned, Reason = reason,
        Label = owned == true and "OWNED" or (owned == false and "NOT OWNED" or "UNKNOWN"),
        Name = tostring(rec and (rec.Title or rec.Target) or mob.Name),
    }
    self.Runtime.BossOwnershipSample = sample
    return sample
end

function H:UpdateBossOwnershipUI(force)
    local button = self.UI and self.UI.BossOwnershipButton
    if not button or not button.Parent then return end
    local sample = self:BossOwnershipSnapshot(force == true)
    local hold = self.State.HoldBossPosition
        and (self.Runtime.BossHold and "holding" or (self.Runtime.BossHoldStatus or "waiting"))
        or "hold off"
    self:SafeText(button, "Ownership • " .. sample.Label
        .. (sample.Name and " • " .. sample.Name or "") .. " • " .. hold .. "  ↻")
    button.TextColor3 = sample.Owned == true and Color3.fromRGB(118, 222, 159)
        or sample.Owned == false and Color3.fromRGB(245, 170, 95)
        or Color3.fromRGB(190, 193, 205)
end

function H:ReleaseBossHold(reason)
    local hold = self.Runtime.BossHold
    self.Runtime.BossHold = nil
    self.Runtime.BossHoldStatus = reason or "waiting"
    if not hold then return end
    -- Remove only this feature's attachments/constraints. The boss's original
    -- movement properties, collision, and Anchored value are never changed.
    for _, object in ipairs(hold.Objects or {}) do
        pcall(function() object:Destroy() end)
    end
end

function H:BossHoldStep()
    local hum = self:Humanoid()
    if self.State.Unloaded or not self.State.HoldBossPosition
        or not self.State.AutoLevelFarm or not self.State.AutoFarmMobs
        or not hum or hum.Health <= 0 or self.Runtime.PostKillLooting
        or self.Runtime.MobApproachTravel or self.Runtime.MobSmoothTravelActive then
        self:ReleaseBossHold("waiting")
        return false
    end
    local sample = self:BossOwnershipSnapshot(false)
    if sample.Owned ~= true or not sample.Target or not sample.Root then
        self:ReleaseBossHold(sample.Target and "waiting for ownership" or "waiting for boss")
        return false
    end
    local playerRoot = self:Root()
    local playerHum = self:Humanoid()
    local targetHum = self:TargetHumanoid(sample.Target)
    -- The checker may yield on some executors. Revalidate the selection and
    -- toggle before creating anything for a result that arrived late.
    if not self.State.HoldBossPosition or self.State.Unloaded
        or not self.State.AutoLevelFarm or not self.State.AutoFarmMobs
        or not playerHum or playerHum.Health <= 0
        or not targetHum or targetHum.Health <= 0
        or self.Runtime.PostKillLooting or self.Runtime.MobApproachTravel
        or self.Runtime.MobSmoothTravelActive
        or self.Runtime.AttackTarget ~= sample.Target
        or not self:IsBossLoopTarget(sample.Target)
        or not sample.Root.Parent or not sample.Root:IsDescendantOf(sample.Target)
        or sample.Part.Anchored or not playerRoot
        or (sample.Root.Position - playerRoot.Position).Magnitude > 120 then
        self:ReleaseBossHold("waiting for boss")
        return false
    end
    local hold = self.Runtime.BossHold
    if hold and (hold.Target ~= sample.Target or hold.Root ~= sample.Root
        or hold.Part ~= sample.Part or not hold.Position.Parent
        or not hold.Orientation.Parent or not hold.Attachment.Parent) then
        self:ReleaseBossHold("waiting")
        hold = nil
    end
    if hold then
        if (sample.Root.Position - hold.Anchor).Magnitude > 18 then
            -- Do not drag a boss back across its arena after a server move.
            self:ReleaseBossHold("reacquiring")
            self.Runtime.BossHoldRetryAt = os.clock() + 0.75
            return false
        end
        return true
    end
    if os.clock() < (self.Runtime.BossHoldRetryAt or 0) then return false end
    hold = {Target = sample.Target, Root = sample.Root, Part = sample.Part,
        Anchor = sample.Root.Position, Objects = {}}
    self.Runtime.BossHold = hold
    local ok = pcall(function()
        local attachment = Instance.new("Attachment")
        hold.Objects[#hold.Objects + 1] = attachment
        hold.Attachment = attachment
        attachment.Name = "ThumbsBossLockAttachment"
        attachment.Parent = sample.Root
        local position = Instance.new("AlignPosition")
        hold.Objects[#hold.Objects + 1] = position
        hold.Position = position
        position.Name = "ThumbsBossLockPosition"
        position.Mode = Enum.PositionAlignmentMode.OneAttachment
        position.Attachment0 = attachment
        position.ApplyAtCenterOfMass = true
        position.RigidityEnabled = false
        position.MaxForce = math.clamp(sample.Root.AssemblyMass * self.S.Workspace.Gravity * 40, 100000, 2000000)
        position.MaxVelocity = 60
        position.Responsiveness = 80
        position.Position = hold.Anchor
        position.Parent = sample.Root
        local orientation = Instance.new("AlignOrientation")
        hold.Objects[#hold.Objects + 1] = orientation
        hold.Orientation = orientation
        orientation.Name = "ThumbsBossLockOrientation"
        orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
        orientation.Attachment0 = attachment
        orientation.RigidityEnabled = false
        orientation.MaxTorque = 1000000
        orientation.MaxAngularVelocity = 30
        orientation.Responsiveness = 60
        orientation.CFrame = sample.Root.CFrame
        orientation.Parent = sample.Root
    end)
    if not ok then
        self:ReleaseBossHold("hold unavailable")
        self.Runtime.BossHoldRetryAt = os.clock() + 1
        return false
    end
    self.Runtime.BossHoldStatus = "holding"
    return true
end

function H:NetworkOwnedMobPart(mob, preferredRoot)
    self:BoostInstantKillSimulationRadius()

    if preferredRoot
        and preferredRoot.Parent then

        local owned, method =
            self:IsNetworkOwnerOfPart(
                preferredRoot
            )

        if owned then
            return preferredRoot, method
        end
    end

    if not mob then
        return nil, "no-mob"
    end

    local firstOwned = nil
    local firstMethod = nil

    for _, part in ipairs(
        mob:GetDescendants()
    ) do
        if part:IsA("BasePart")
            and not part.Anchored then

            local owned, method =
                self:IsNetworkOwnerOfPart(
                    part
                )

            if owned then
                if part.Name == "HumanoidRootPart"
                    or part.Name == "LowerTorso"
                    or part.Name == "Torso" then

                    return part, method
                end

                firstOwned =
                    firstOwned
                    or part

                firstMethod =
                    firstMethod
                    or method
            end
        end
    end

    return firstOwned, firstMethod or "not-owned"
end

function H:ExecuteOwnedNpcPhysics(
    mob,
    mobRoot,
    mobHum,
    ownedPart
)
    if not mob
        or not mob.Parent
        or not mobHum
        or not mobHum.Parent then

        return false, "invalid-target"
    end

    local originalHealth =
        tonumber(mobHum.Health)
        or 0

    local originalPivot = nil

    pcall(function()
        originalPivot =
            mob:GetPivot()
    end)

    local folder =
        mob.Parent

    local oldDespawn =
        folder
        and folder:GetAttribute(
            "DespawnedAt"
        )
        or nil

    local root =
        mobRoot
        or mob:FindFirstChild(
            "HumanoidRootPart"
        )
        or ownedPart

    if not root
        or not root:IsA("BasePart") then

        return false, "no-root"
    end

    -- PHASE 1:
    -- The Humanoid state machine is tied to the assembly's network owner.
    -- Force a Dead state first while simultaneously sending a very large
    -- downward physics packet.
    pcall(function()
        mobHum:SetStateEnabled(
            Enum.HumanoidStateType.Dead,
            true
        )
    end)

    pcall(function()
        mobHum:ChangeState(
            Enum.HumanoidStateType.Dead
        )
    end)

    for _, part in ipairs(
        mob:GetDescendants()
    ) do
        if part:IsA("BasePart")
            and not part.Anchored then

            local owned =
                self:IsNetworkOwnerOfPart(
                    part
                )

            if owned then
                pcall(function()
                    part.AssemblyLinearVelocity =
                        Vector3.new(
                            0,
                            -250000,
                            0
                        )

                    part.AssemblyAngularVelocity =
                        Vector3.new(
                            450,
                            450,
                            450
                        )
                end)
            end
        end
    end

    pcall(function()
        local mass =
            math.max(
                root.AssemblyMass,
                1
            )

        root:ApplyImpulse(
            Vector3.new(
                0,
                -(mass * 5000000),
                0
            )
        )
    end)

    local fallen =
        tonumber(
            self.S.Workspace.FallenPartsDestroyHeight
        )
        or -500

    local executeY =
        math.min(
            fallen - 1500,
            -5000
        )

    pcall(function()
        mob:PivotTo(
            CFrame.new(
                root.Position.X,
                executeY,
                root.Position.Z
            )
        )
    end)

    task.wait(0.10)

    if not mob.Parent
        or not mobHum.Parent then

        return true, "phase1-removed"
    end

    -- PHASE 2:
    -- Some NPC humanoids do not transition from physics alone. While we still
    -- own the assembly, set the locally-simulated Humanoid to zero health and
    -- resend the Dead state + void packet. If the server rejects the kill,
    -- the code below restores the local copy so farming can continue.
    local stillOwned =
        self:IsNetworkOwnerOfPart(
            root
        )

    if stillOwned then
        pcall(function()
            mobHum.Health = 0
        end)

        pcall(function()
            mobHum:ChangeState(
                Enum.HumanoidStateType.Dead
            )
        end)

        for pulse = 1, 5 do
            if not mob.Parent
                or not mobHum.Parent then

                return true, "phase2-removed"
            end

            pcall(function()
                root.AssemblyLinearVelocity =
                    Vector3.new(
                        0,
                        -500000,
                        0
                    )

                root.CFrame =
                    CFrame.new(
                        root.Position.X,
                        executeY
                            - (
                                pulse
                                * 250
                            ),
                        root.Position.Z
                    )
            end)

            task.wait(0.045)
        end
    end

    -- Do not trust local Humanoid.Health == 0 as confirmation. Wait for an
    -- authoritative sign: target model removed OR its NPC folder receives a
    -- new DespawnedAt value.
    local confirmDeadline =
        os.clock()
        + 0.9

    while os.clock()
        < confirmDeadline do

        if not mob.Parent
            or not mobHum.Parent then

            return true, "server-removed"
        end

        if folder
            and folder.Parent then

            local newDespawn =
                folder:GetAttribute(
                    "DespawnedAt"
                )

            if newDespawn ~= nil
                and newDespawn
                ~= oldDespawn then

                return true, "despawn-confirmed"
            end
        end

        task.wait(0.05)
    end

    -- Server rejected the execute. Restore the local NPC view so the normal M1
    -- farm does not get stuck believing a still-alive server NPC is dead.
    if mob.Parent
        and mobHum.Parent then

        pcall(function()
            if mobHum.Health <= 0
                and originalHealth > 0 then

                mobHum.Health =
                    math.min(
                        originalHealth,
                        mobHum.MaxHealth
                    )
            end
        end)

        pcall(function()
            mobHum:ChangeState(
                Enum.HumanoidStateType.GettingUp
            )
        end)

        -- Only restore position when this client still owns it. If ownership
        -- has already returned to the server, server replication will correct
        -- the NPC itself.
        if originalPivot then
            local ownedNow =
                self:IsNetworkOwnerOfPart(
                    root
                )

            if ownedNow then
                pcall(function()
                    mob:PivotTo(
                        originalPivot
                    )
                end)
            end
        end
    end

    return false, "server-rejected"
end

function H:TryNetworkOwnershipInstantKill(
    mob,
    mobRoot,
    mobHum
)
    if not self.State.InstantKill
        or self.State.Unloaded
        or not self.State.AutoFarmMobs
        or not mob
        or not mob.Parent
        or not mobHum
        or mobHum.Health <= 0
        or mobHum.MaxHealth <= 0 then

        return false
    end

    local threshold, isDungeon =
        self:InstantKillThresholdPercent()

    local hpPercent =
        (
            mobHum.Health
            / mobHum.MaxHealth
        )
        * 100

    if hpPercent > threshold then
        return false
    end

    local now =
        os.clock()

    if self.Runtime.InstantKillBusy
        or now
        < (
            self.Runtime.InstantKillLastAt
            or 0
        )
        + 0.35 then

        return self.Runtime.InstantKillBusy
            == true
    end

    -- Force the largest simulation radius the executor allows BEFORE checking
    -- ownership. This was missing from BUILD 56 and is required by the public
    -- ownership-based implementations when Roblox has not already handed the
    -- nearby NPC to this client.
    self:BoostInstantKillSimulationRadius()

    local ownedPart, ownershipMethod =
        self:NetworkOwnedMobPart(
            mob,
            mobRoot
        )

    if not ownedPart then
        if now
            - (
                self.Runtime.InstantKillLastOwnershipStatusAt
                or 0
            ) >= 0.65 then

            self.Runtime.InstantKillLastOwnershipStatusAt =
                now

            self:SetStatus(
                "Instant Kill • "
                .. tostring(
                    math.floor(
                        hpPercent
                        + 0.5
                    )
                )
                .. "% HP • acquiring ownership"
            )
        end

        return false
    end

    self.Runtime.InstantKillBusy =
        true

    self.Runtime.InstantKillTarget =
        mob

    self.Runtime.InstantKillLastAt =
        now

    self.Runtime.InstantKillAttempts =
        (
            self.Runtime.InstantKillAttempts
            or 0
        )
        + 1

    self:StopAttackHold()
    self:StopBlocking()

    self:SetStatus(
        "Instant Kill • EXECUTE "
        .. tostring(mob.Name)
        .. " • ownership="
        .. tostring(ownershipMethod)
        .. (
            isDungeon
            and " • dungeon"
            or " • main"
        )
    )

    task.spawn(function()
        local ok, success, method =
            pcall(
                function()
                    return self:ExecuteOwnedNpcPhysics(
                        mob,
                        mobRoot,
                        mobHum,
                        ownedPart
                    )
                end
            )

        if ok
            and success then

            self.Runtime.InstantKillSuccesses =
                (
                    self.Runtime.InstantKillSuccesses
                    or 0
                )
                + 1

            self:SetStatus(
                "Instant Kill • confirmed • "
                .. tostring(method)
                .. " • x"
                .. tostring(
                    self.Runtime.InstantKillSuccesses
                )
            )
        elseif not self.State.Unloaded
            and self.State.AutoFarmMobs then

            self:SetStatus(
                "Instant Kill • "
                .. (
                    ok
                    and tostring(
                        method
                        or "server rejected"
                    )
                    or (
                        "error: "
                        .. tostring(success)
                    )
                )
                .. " • normal M1 resumed"
            )
        end

        self.Runtime.InstantKillBusy =
            false

        self.Runtime.InstantKillTarget =
            nil
    end)

    return true
end

function H:IsBossLoopTarget(mob)
    local store = self.Data.AutoLevel
    local rec = type(store) == "table" and store.CurrentRecord or nil

    return self.State.AutoLevelFarm == true
        and self.State.AutoFarmMobs == true
        and type(rec) == "table"
        and tostring(rec.Category or "") == "BossHunt"
        and self:NormalizeMobText(rec.Target)
            == self:NormalizeMobText(self.State.SelectedMob)
        and mob ~= nil
        and mob.Parent ~= nil
end


function H:IsBossHoverTarget(mob)
    return self.State.BossHoverFarm == true and self:IsBossLoopTarget(mob)
end

function H:ClearBossHoverController()
    local controller = self.Runtime.BossHoverController
    self.Runtime.BossHoverController = nil
    if controller then
        for _, obj in ipairs({controller.Position, controller.Orientation, controller.Attachment}) do
            if obj then obj:Destroy() end
        end
    end
end

function H:HoldBossHover(goal, aim)
    local root, hum = self:Root(), self:Humanoid()
    if not root or not hum or hum.Health <= 0 then return false end
    local ctl = self.Runtime.BossHoverController
    if ctl and (ctl.Root ~= root or not ctl.Position.Parent) then
        self:ClearBossHoverController()
        ctl = nil
    end
    if not ctl then
        if self.Runtime.MovementSupport then
            self.Runtime.MovementSupport:Destroy()
            self.Runtime.MovementSupport = nil
        end
        local attachment = Instance.new("Attachment")
        attachment.Name = "ThumbsBossHoldAttachment"
        attachment.Parent = root
        local position = Instance.new("AlignPosition")
        position.Name = "ThumbsBossHoldPosition"
        position.Mode = Enum.PositionAlignmentMode.OneAttachment
        position.Attachment0 = attachment
        position.ApplyAtCenterOfMass = true
        position.RigidityEnabled = false
        position.MaxForce = math.max(100000, root.AssemblyMass * self.S.Workspace.Gravity * 30)
        position.MaxVelocity = 260
        position.Responsiveness = 65
        position.Position = goal
        position.Parent = root
        local orientation = Instance.new("AlignOrientation")
        orientation.Name = "ThumbsBossHoldOrientation"
        orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
        orientation.Attachment0 = attachment
        orientation.RigidityEnabled = false
        orientation.MaxTorque = 1000000
        orientation.MaxAngularVelocity = 30
        orientation.Responsiveness = 55
        orientation.CFrame = aim
        orientation.Parent = root
        ctl = {Root = root, Attachment = attachment, Position = position, Orientation = orientation}
        self.Runtime.BossHoverController = ctl
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    hum.AutoRotate = false
    ctl.Position.Position, ctl.Orientation.CFrame = goal, aim
    return true
end

function H:BossHoverAimCFrame(position, bossPosition, preferredUp)
    local aim = bossPosition - position
    if aim.Magnitude <= 0.05 then return CFrame.new(position) end
    -- The boss can be directly above us. Use a horizontal up vector so
    -- lookAt has a stable roll even when the look direction is vertical.
    local up = typeof(preferredUp) == "Vector3"
        and Vector3.new(preferredUp.X, 0, preferredUp.Z)
        or Vector3.new(1, 0, 0)
    if up.Magnitude < 0.05 then up = Vector3.new(1, 0, 0) end
    up = up.Unit
    if math.abs(aim.Unit:Dot(up)) > 0.95 then
        up = Vector3.new(0, 1, 0)
    end
    return CFrame.lookAt(position, bossPosition, up)
end

function H:BossHoverGoal(mobRoot)
    if not mobRoot or not mobRoot.Parent then
        return nil
    end

    local x = math.clamp(tonumber(self.State.BossHoverXOffset) or 0, -1.5, 1.5)
    local distance = math.clamp(tonumber(self.State.BossHoverDistance) or 6.5, 3, 9)
    local y = tonumber(self.State.BossHoverYOffset) or 2
    if y < 0 then
        -- A saved Build105 config stored the final negative depth. Preserve its
        -- stance when migrating to the screenshot's Y-offset + distance form.
        y = math.clamp(y + distance, 0, 5)
        self.State.BossHoverYOffset = y
    end
    y = math.clamp(y, 0, 5) - distance
        + (self.Runtime.BossHoverContactLift or 0)
    local z = math.clamp(tonumber(self.State.BossHoverZOffset) or 0, -1.5, 1.5)
    if (self.Runtime.BossHoverContactLift or 0) >= 2.7 then
        z = z + 1.0
    end

    -- The character may be under the boss's platform, as in the supplied
    -- clip. Noclip and vertical support hold the actual below-boss offset.
    local flat = self.Runtime.BossHoverUp or Vector3.new(mobRoot.CFrame.LookVector.X, 0, mobRoot.CFrame.LookVector.Z)
    if flat.Magnitude < 0.05 then flat = Vector3.new(0, 0, -1) end
    flat = flat.Unit
    local right = Vector3.new(-flat.Z, 0, flat.X)
    local goal = mobRoot.Position + right * x + Vector3.new(0, math.min(-1.0, y), 0) - flat * z

    if goal.Y <= self.S.Workspace.FallenPartsDestroyHeight + 28 then
        return nil
    end

    return goal
end

function H:StopBossHover()
    self:ReleaseBossHold("waiting")
    local wasHovering = self.Runtime.BossHoverActive ~= nil
    self:ClearBossHoverController()
    self.Runtime.BossHoverUp = nil
    self.Runtime.BossHoverActive = nil
    self.Runtime.BossHoverLastMoveAt = 0
    self.Runtime.BossHoverObservedTarget = nil
    self.Runtime.BossHoverObservedHealth = nil
    self.Runtime.BossHoverLastDamageAt = nil
    self.Runtime.BossHoverContactLift = 0
    self.Runtime.BossHoverAdjustUntil = 0
    self.Runtime.BossInstantTarget = nil

    if self.Runtime.SimpleDirectTween
        and string.sub(tostring(self.Runtime.SimpleDirectKey or ""), 1, 11)
            == "BOSS_HOVER:" then

        pcall(function() self.Runtime.SimpleDirectTween:Cancel() end)
        self.Runtime.SimpleDirectTween = nil
        self.Runtime.SimpleDirectGoal = nil
        self.Runtime.SimpleDirectKey = nil
        wasHovering = true
    end

    local support = self.Runtime.MovementSupport
    if support and support.Name == "ThumbsBossHoverSupport" then
        support:Destroy()
        self.Runtime.MovementSupport = nil
    end

    if wasHovering then
        self:SetMobTravelNoclip(false)
        local hum = self:Humanoid()
        if hum then hum.AutoRotate = true end
    end
end

function H:BossHoverFarmStep(mob, mobRoot)
    local root = self:Root()
    local hum = self:Humanoid()
    local now = os.clock()
    local bossHum = mob and mob:FindFirstChildOfClass("Humanoid")

    if self.Runtime.BossHoverObservedTarget ~= mob then
        self.Runtime.BossHoverObservedTarget = mob
        local flat = Vector3.new(mobRoot.CFrame.LookVector.X, 0, mobRoot.CFrame.LookVector.Z)
        self.Runtime.BossHoverUp = flat.Magnitude > 0.05 and flat.Unit or Vector3.new(0, 0, -1)
        self.Runtime.BossHoverObservedHealth = bossHum and bossHum.Health or nil
        self.Runtime.BossHoverLastDamageAt = now
        self.Runtime.BossHoverContactLift = 0
        self.Runtime.BossHoverAdjustUntil = 0
    elseif bossHum then
        local previous = self.Runtime.BossHoverObservedHealth
        if previous and bossHum.Health < previous - 0.05 then
            self.Runtime.BossHoverLastDamageAt = now
        end
        self.Runtime.BossHoverObservedHealth = bossHum.Health
    end

    local goal = self:BossHoverGoal(mobRoot)

    if not root or not hum or not goal then
        self:StopBossHover()
        return false
    end

    self.Runtime.BossHoverActive = mob
    if self:CombatFloorSafetyStep()
        or os.clock() < (self.Runtime.CombatSafetyHoldUntil or 0) then

        self:StopBossHover()
        return true
    end

    self:SetMobTravelNoclip(true)

    local distance = (root.Position - goal).Magnitude

    -- Controller acceptance is not damage. If HP stays level at the
    -- screenshot stance, move into the actual melee pocket in small steps.
    if bossHum and bossHum.Health > 0 and distance < 1.1
        and now - (self.Runtime.BossHoverLastDamageAt or now) > 2.4
        and (self.Runtime.BossHoverContactLift or 0) < 3.6 then
        self.Runtime.BossHoverContactLift = math.min(
            3.6, (self.Runtime.BossHoverContactLift or 0) + 0.9
        )
        self.Runtime.BossHoverLastDamageAt = now
        self.Runtime.BossHoverAdjustUntil = now + 0.85
        goal = self:BossHoverGoal(mobRoot)
        distance = goal and (root.Position - goal).Magnitude or distance
    end

    if not goal then self:StopBossHover(); return false end
    local aim = self:BossHoverAimCFrame(goal, mobRoot.Position, self.Runtime.BossHoverUp)
    -- Only update the existing position/orientation goals. No tween restarts,
    -- root rotations, zero-velocity spam, or collision mode flapping.
    if not self:HoldBossHover(goal, aim) then return false end

    self.Runtime.OrbitContactUntil = math.max(
        self.Runtime.OrbitContactUntil or 0,
        now + 0.30
    )

    self.Runtime.CloseMeleeMode = "hover-below"

    self:SetStatus(
        "Boss Loop • stable below " .. tostring(mob.Name)
        .. " • " .. string.format("%.1f", (root.Position - mobRoot.Position).Magnitude)
        .. " studs • HP " .. tostring(math.floor(bossHum and bossHum.Health or 0))
        .. " • M1 x" .. tostring(self.Runtime.BackgroundM1Count or 0)
        .. ((self.Runtime.BossHoverContactLift or 0) > 0
            and " • contact +" .. string.format("%.1f", self.Runtime.BossHoverContactLift)
            or "")
    )

    return true
end

function H:BossInstantArrival(mob, mobRoot)
    if not self.State.BossInstantTravel
        or not self:IsBossLoopTarget(mob)
        or self.Runtime.BossInstantTarget == mob then
        return false
    end

    local root = self:Root()
    local hum = self:Humanoid()
    local below = self:IsBossHoverTarget(mob)
    local goal = below and self:BossHoverGoal(mobRoot) or self:SmoothMobTravelGoal(mobRoot)
    if not root or not hum or not goal
        or (root.Position - goal).Magnitude <= 8
        or (self.Runtime.BossInstantLastAttemptTarget == mob
            and os.clock() - (self.Runtime.BossInstantLastAttemptAt or 0) < 2) then
        return false
    end

    self.Runtime.BossInstantLastAttemptTarget = mob
    self.Runtime.BossInstantLastAttemptAt = os.clock()
    self:StopSmoothMobTravel()
    self:StopMovement()
    self:ResetOrbitState()
    self:StopAttackHold()
    self:StopBlocking()
    self.Runtime.BossHoverActive = below and mob or nil
    self:SetMobTravelNoclip(true)
    local ok = pcall(function()
        hum.AutoRotate = not below
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = below and self:BossHoverAimCFrame(
            goal, mobRoot.Position, mobRoot.CFrame.LookVector
        ) or CFrame.lookAt(goal, Vector3.new(mobRoot.Position.X, goal.Y, mobRoot.Position.Z))
    end)
    if not ok then
        self:StopBossHover()
        return false
    end
    if not below then self:SetMobTravelNoclip(false) end
    self.Runtime.BossInstantTarget = mob
    self.Runtime.MobApproachTravel = false
    self.Runtime.BossProbeHolding = false
    self:SetStatus("Boss Loop • arrived at " .. tostring(mob.Name) .. " • engaging")
    return true
end

function H:AggressiveMobFarmStep(mob, mobRoot)
    if not mob or not mobRoot then
        self:ResetAggressiveMobState()
        self:ResetOrbitState()
        return true
    end

    local root = self:Root()
    local hum = self:Humanoid()

    if not root or not hum or hum.Health <= 0 then
        return true
    end

    if self.State.AutoLevelFarm
        and (
            self.Runtime.InstantKillBusy
            or self.Runtime.InstantKillTarget == mob
        ) then

        self:StopSmoothMobTravel()
        self:StopMovement()
        self:SetMobTravelNoclip(false)

        self:SetStatus(
            "Auto Level • waiting for target respawn • no void follow"
        )

        return true
    end

    local unique = tostring(
        mob:GetAttribute("UniqueName")
        or mob.Name
    )

    if self.Runtime.AggressiveTarget ~= unique then
        self:ResetAggressiveMobState()
        self:ResetOrbitState()

        self.Runtime.AggressiveTarget = unique
        self.Runtime.NextPunchAt = 0
        self.Runtime.NextRapidClickAt = 0
        self.Runtime.RapidClickCount = 0

        self.Runtime.NextBackgroundM1At = 0
        self.Runtime.BackgroundM1Count = 0
        self.Runtime.BackgroundM1Busy = false
        self.Runtime.MobComboRestUntil = 0
        self.Runtime.MobComboRestStartedAt = 0
        self.Runtime.MobComboRiseAt = 0
        self.Runtime.MobComboIndex = 0
        self.Runtime.MobComboLastCountedStamp =
            self:GetLastPunchStamp()

        self.Runtime.MobComboNextPunchAt = 0
        self.Runtime.NextCombatReadyRefresh = 0

        self.Runtime.SpamObservedTarget = nil
        self.Runtime.SpamObservedHealth = nil
        self.Runtime.SpamLastDamageAt = 0

        self.Runtime.InstantKillThresholdLocked =
            false
    end

    local now =
        os.clock()

    local distance =
        (
            root.Position
            - mobRoot.Position
        ).Magnitude

    local hoverTarget = self:IsBossHoverTarget(mob)
    if not hoverTarget and self.Runtime.BossHoverActive then
        self:StopBossHover()
    end

    if self:BossInstantArrival(mob, mobRoot) then
        if hoverTarget then return self:BossHoverFarmStep(mob, mobRoot) end
        return true
    end

    local hoverGoal = hoverTarget and self:BossHoverGoal(mobRoot) or nil
    local approachRemaining = hoverGoal
        and (root.Position - hoverGoal).Magnitude or distance

    -- BUILD 55:
    -- Long-distance selected-mob travel is a single smooth TweenService glide.
    -- Noclip remains active for the whole journey. Orbit and M1 do nothing
    -- until we are actually close enough to fight.
    local alreadyEngagedWithThisMob =
        self.Runtime.OrbitModel == mob
        and self.Runtime.OrbitRoot == mobRoot
        or (hoverTarget and self.Runtime.BossHoverActive == mob
            and self.Runtime.BossHoverController ~= nil)

    local travelling =
        self.Runtime.MobApproachTravel
        or (
            distance > 10.0
            and not alreadyEngagedWithThisMob
        )

    if travelling and approachRemaining > (hoverGoal and 1.1 or 3.35) then
        self.Runtime.MobApproachTravel = true

        self:ResetOrbitState()
        self:StopAttackHold()
        self:StopBlocking()

        self:StartOrUpdateSmoothMobTravel(
            mob,
            mobRoot,
            hoverGoal
        )

        self:SetStatus(
            "Mob Farm • FAST MELEE APPROACH "
            .. tostring(mob.Name)
            .. " • "
            .. tostring(math.floor(distance))
            .. " studs • noclip"
        )

        return true
    end

    -- Close enough: hand movement cleanly from tween -> orbit.
    if self.Runtime.MobApproachTravel
        or self.Runtime.MobSmoothTravelActive
        or (self.Runtime.MobTravelNoclip and not hoverTarget) then

        self.Runtime.MobApproachTravel = false
        self:StopSmoothMobTravel()
        self:ResetOrbitState()

        pcall(function()
            hum.AutoRotate = true
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    if hoverTarget then
        if self.Runtime.BlockHeld or self:IsBlockingActive() then
            self:StopBlocking()
        end

        self.Runtime.Defending = false
        self.Runtime.BlockReleaseUntil = 0

        if self:BossHoverFarmStep(mob, mobRoot) then
            return true
        end
    end

    -- BUILD 63: normal M1 gets the mob down to the configured threshold.
    -- Once Roblox gives this client network ownership of the NPC assembly,
    -- execute it through the physics/void route used by current public hubs.
    local mobHumanoid =
        mob:FindFirstChildOfClass("Humanoid")

    if mobHumanoid
        and self.State.InstantKill then

        local thresholdReached,
            braking,
            hpPercent,
            threshold =
            self:GetInstantKillHealthState(
                mobHumanoid
            )

        if thresholdReached then
            -- BUILD 63:
            -- Do not let normal combat continue while we wait for network
            -- ownership. BUILD 57 returned false here when ownership wasn't
            -- ready, so both the farm lane and 12ms background M1 lane kept
            -- punching and pushed the NPC well below 10%.
            self:HoldM1ForInstantKill(
                mobHumanoid
            )

            self:TryNetworkOwnershipInstantKill(
                mob,
                mobRoot,
                mobHumanoid
            )

            self:SetStatus(
                "Instant Kill • LOCKED @ "
                .. string.format(
                    "%.1f%%",
                    hpPercent
                )
                .. " / "
                .. tostring(threshold)
                .. "%"
                .. " • waiting ownership"
            )

            return true
        elseif braking then
            self.Runtime.InstantKillThresholdLocked =
                false

            -- Let BackgroundM1Spam use its slower brake-zone cadence.
            if self.Runtime.NextBackgroundM1At
                == math.huge then

                self.Runtime.NextBackgroundM1At =
                    0
            end
        end
    end

    self:ContinuousOrbitMovement(
        mob,
        mobRoot
    )

    -- BUILD 55 RAPID M1:
    -- Do not sit in block between every punch. Releasing and reacquiring block
    -- each cycle was adding visible delay and interrupting the combo animation.
    -- The high-frequency defensive lane still blocks immediately on a real
    -- threat window.
    if self.Runtime.BlockHeld
        or self:IsBlockingActive() then

        self:StopBlocking()
    end

    self.Runtime.Defending =
        false

    self.Runtime.BlockReleaseUntil =
        0

    -- BUILD 55: while farming a live mob, attack continuously.
    -- No contact gate, no combo scheduler, no waiting for a punch window.
    self.Runtime.OrbitContactUntil =
        math.max(
            self.Runtime.OrbitContactUntil or 0,
            now + 0.30
        )

    self:SetStatus(
        (
            "Mob Farm • CLOSE M1 "
        )
        .. tostring(mob.Name)
        .. " • "
        .. string.format("%.1f", distance)
        .. " studs • "
        .. tostring(
            self.Runtime.CloseMeleeMode
            or "behind"
        )
        .. " • BG M1 x"
        .. tostring(
            self.Runtime.BackgroundM1Count
            or 0
        )
    )

    return true
end

function H:MobRetreatGoal(mobRoot)
    local root =
        self:Root()

    if not root then
        return nil
    end

    local away =
        Vector3.new(
            1,
            0,
            0
        )

    if mobRoot then
        local delta =
            root.Position
            - mobRoot.Position

        local flat =
            Vector3.new(
                delta.X,
                0,
                delta.Z
            )

        if flat.Magnitude > 0.05 then
            away =
                flat.Unit
        end
    end

    local wanted =
        root.Position
        + away * 13

    -- Keep the retreat position on actual ground.
    local params =
        RaycastParams.new()

    params.FilterType =
        Enum.RaycastFilterType.Exclude

    local character =
        self:Character()

    params.FilterDescendantsInstances =
        character
        and {character}
        or {}

    local hit =
        self.S.Workspace:Raycast(
            wanted
                + Vector3.new(
                    0,
                    7,
                    0
                ),
            Vector3.new(
                0,
                -22,
                0
            ),
            params
        )

    if hit then
        wanted =
            Vector3.new(
                wanted.X,
                hit.Position.Y + 2.6,
                wanted.Z
            )
    else
        -- No confirmed ground = do not invent a vertical destination.
        wanted =
            Vector3.new(
                wanted.X,
                root.Position.Y,
                wanted.Z
            )
    end

    return wanted
end

function H:MobSurvivalStep(mob, mobRoot)
    if not self.State.SafeCombat then
        self.Runtime.MobRetreating =
            false

        self.Runtime.MobRetreatGoal =
            nil

        self:ResetMobPokeState()

        return false
    end

    local hp =
        self:HealthPercent()

    local retreatAt =
        math.clamp(
            tonumber(
                self.State.RetreatHealthPercent
            ) or 55,
            10,
            90
        )

    local resumeAt =
        math.clamp(
            math.max(
                tonumber(
                    self.State.ResumeHealthPercent
                ) or 85,
                retreatAt + 10
            ),
            20,
            100
        )

    -- Any hit that slipped through gets a short defensive lockout so we don't
    -- trade punches inside the rest of the enemy combo.
    if os.clock()
        < (
            self.Runtime.MobDamagePauseUntil
            or 0
        ) then

        self:StopAttackHold()

        if mob then
            self:FaceTarget(
                mob
            )

            self.Runtime.ForceAttackUntil =
                0

            self.Runtime.BlockReleaseUntil =
                0

            self:StartBlocking(
                true
            )
        end

        self:SetStatus(
            "Mob Farm • damage taken • guarding"
        )

        return true
    end

    if self.Runtime.MobRetreating then
        self:StopAttackHold()

        if mob then
            self:FaceTarget(
                mob
            )

            self:StartBlocking(
                false
            )
        end

        if hp >= resumeAt then
            self.Runtime.MobRetreating =
                false

            self.Runtime.MobRetreatGoal =
                nil

            self.Runtime.NextPunchAt =
                0

            self.Runtime.ForceAttackUntil =
                0

            self.Runtime.MobDamagePauseUntil =
                0

            self:SetStatus(
                "Mob Farm • recovered • re-engaging"
            )

            return false
        end

        local goal =
            self.Runtime.MobRetreatGoal

        if not goal then
            goal =
                self:MobRetreatGoal(
                    mobRoot
                )

            self.Runtime.MobRetreatGoal =
                goal
        end

        local root =
            self:Root()

        if goal
            and root
            and (
                root.Position
                - goal
            ).Magnitude > 2.0 then

            self:SimpleDirectTween(
                goal,
                mobRoot
                and mobRoot.Position
                or nil,
                70,
                "MOB_RETREAT"
            )
        else
            if self.Runtime.SimpleDirectTween then
                pcall(
                    function()
                        self.Runtime.SimpleDirectTween:Cancel()
                    end
                )

                self.Runtime.SimpleDirectTween =
                    nil

                self.Runtime.SimpleDirectGoal =
                    nil

                self.Runtime.SimpleDirectKey =
                    nil
            end
        end

        self:SetStatus(
            "Mob Farm • retreat/heal • HP "
            .. tostring(
                math.floor(
                    hp
                )
            )
            .. "% • resume "
            .. tostring(
                math.floor(
                    resumeAt
                )
            )
            .. "%"
        )

        return true
    end

    if hp <= retreatAt then
        self.Runtime.MobRetreating =
            true

        self.Runtime.MobRetreatGoal =
            self:MobRetreatGoal(
                mobRoot
            )

        self:StopAttackHold()

        self.Runtime.ForceAttackUntil =
            0

        self.Runtime.BlockReleaseUntil =
            0

        if mob then
            self:FaceTarget(
                mob
            )

            self:StartBlocking(
                true
            )
        end

        self:SetStatus(
            "Mob Farm • LOW HP • disengaging at "
            .. tostring(
                math.floor(
                    hp
                )
            )
            .. "%"
        )

        return true
    end

    return false
end


function H:FindExactQuestLiveTarget(query)
    query =
        tostring(
            query
            or ""
        )

    local wanted =
        self:NormalizeMobText(
            query
        )

    if wanted == "" then
        return nil
    end

    local myRoot =
        self:Root()

    local function exact(value)
        return
            self:NormalizeMobText(
                value
            ) == wanted
    end

    local function modelHasExactIdentity(model)
        if not model
            or not model:IsA("Model") then

            return false
        end

        if exact(model.Name)
            or exact(
                model:GetAttribute(
                    "NpcCode"
                )
            )
            or exact(
                model:GetAttribute(
                    "Code"
                )
            )
            or exact(
                model:GetAttribute(
                    "UniqueName"
                )
            )
            or exact(
                model:GetAttribute(
                    "Title"
                )
            ) then

            return true
        end

        -- BossInfo carried by the actual boss branch.
        local bossInfo =
            model:FindFirstChild(
                "BossInfo",
                true
            )

        if bossInfo
            and (
                exact(
                    bossInfo:GetAttribute(
                        "NpcCode"
                    )
                )
                or exact(
                    bossInfo:GetAttribute(
                        "Code"
                    )
                )
                or exact(
                    bossInfo:GetAttribute(
                        "Title"
                    )
                )
            ) then

            return true
        end

        -- Only inspect ancestors INSIDE ActiveNpcs.
        -- This avoids the previous bug where generic/world-event ancestors
        -- caused MotherBear to resolve to Datai or even Workspace.
        local current =
            model.Parent

        for _ = 1, 5 do
            if not current then
                break
            end

            if current.Name == "ActiveNpcs" then
                break
            end

            if exact(current.Name)
                or exact(
                    current:GetAttribute(
                        "NpcCode"
                    )
                )
                or exact(
                    current:GetAttribute(
                        "Code"
                    )
                )
                or exact(
                    current:GetAttribute(
                        "Title"
                    )
                ) then

                return true
            end

            current =
                current.Parent
        end

        return false
    end

    -- Keep the live exact boss while it is valid. The old path searched
    -- every descendant of Humanoids on each 0.03s Farm tick.
    local cache = self.Runtime.QuestEnemyCache

    if type(cache) == "table"
        and cache.Query == wanted then

        local model = cache.Model

        if model
            and model.Parent
            and modelHasExactIdentity(model) then

            local hum =
                model:FindFirstChildOfClass("Humanoid")
                or model:FindFirstChildWhichIsA("Humanoid", true)

            local root =
                model:FindFirstChild("HumanoidRootPart", true)
                or model.PrimaryPart

            if hum and hum.Health > 0 and root then
                local distance =
                    myRoot
                    and (myRoot.Position - root.Position).Magnitude
                    or 0

                return model, root, hum, distance
            end
        end

        self.Runtime.QuestEnemyCache = nil
    end

    -- When the boss is streamed out, avoid another full tree scan each tick.
    local missCooldown = self.State.AutoLevelFarm and 0.40 or 0.18
    if self.Runtime.LastExactQuestMissQuery == wanted
        and os.clock() - (self.Runtime.LastExactQuestMissAt or 0) < missCooldown then

        return nil
    end

    local bestModel
    local bestRoot
    local bestHum
    local bestDistance =
        math.huge

    local function consider(model)
        if not model
            or not model:IsA("Model")
            or not model.Parent
            or not modelHasExactIdentity(
                model
            ) then

            return
        end

        local hum =
            model:FindFirstChildOfClass(
                "Humanoid"
            )
            or model:FindFirstChildWhichIsA(
                "Humanoid",
                true
            )

        local root =
            model:FindFirstChild(
                "HumanoidRootPart",
                true
            )
            or model.PrimaryPart

        if not hum
            or hum.Health <= 0
            or not root then

            return
        end

        local distance =
            myRoot
            and (
                myRoot.Position
                - root.Position
            ).Magnitude
            or 0

        if distance < bestDistance then
            bestDistance =
                distance

            bestModel =
                model

            bestRoot =
                root

            bestHum =
                hum
        end
    end

    -- Primary route: the game's NPC tree.
    local humanoids =
        self.S.Workspace:FindFirstChild(
            "Humanoids"
        )

    if humanoids then
        for _, model in ipairs(
            humanoids:GetDescendants()
        ) do
            if model:IsA("Model") then
                consider(
                    model
                )
            end
        end
    end

    -- Exact BossTag fallback. We only use the tag if ITS OWN code/title
    -- exactly matches the quest, then search its local branch for a humanoid.
    if not bestModel then
        for _, tagged in ipairs(
            self.S.CollectionService:GetTagged(
                "BossTag"
            )
        ) do
            local tagMatches =
                exact(
                    tagged:GetAttribute(
                        "NpcCode"
                    )
                )
                or exact(
                    tagged:GetAttribute(
                        "Code"
                    )
                )
                or exact(
                    tagged:GetAttribute(
                        "Title"
                    )
                )

            if tagMatches then
                local branch =
                    tagged.Parent

                if branch then
                    if branch:IsA("Model") then
                        consider(
                            branch
                        )
                    end

                    for _, obj in ipairs(
                        branch:GetDescendants()
                    ) do
                        if obj:IsA("Model") then
                            consider(
                                obj
                            )
                        end
                    end
                end
            end
        end
    end

    if not bestModel then
        self.Runtime.QuestTargetIsBoss =
            false

        self.Runtime.LastExactQuestMissQuery = wanted
        self.Runtime.LastExactQuestMissAt = os.clock()

        return nil
    end

    self.Runtime.QuestEnemyCache = {
        Query = wanted,
        Model = bestModel,
    }

    self.Runtime.QuestTargetIsBoss =
        bestModel:GetAttribute(
            "IsBoss"
        ) == true
        or bestModel:GetAttribute(
            "Boss"
        ) == true
        or bestModel:FindFirstChild(
            "BossInfo",
            true
        ) ~= nil
        or self.S.CollectionService:HasTag(
            bestModel,
            "BossTag"
        )

    return
        bestModel,
        bestRoot,
        bestHum,
        bestDistance
end


function H:SafeQuestTargetGround(
    position,
    targetModel
)
    if typeof(position) ~= "Vector3" then
        return nil
    end

    local params =
        RaycastParams.new()

    params.FilterType =
        Enum.RaycastFilterType.Exclude

    local exclude = {}

    local character =
        self:Character()

    if character then
        exclude[#exclude + 1] =
            character
    end

    if targetModel then
        exclude[#exclude + 1] =
            targetModel
    end

    params.FilterDescendantsInstances =
        exclude

    params.IgnoreWater =
        false

    local hit =
        self.S.Workspace:Raycast(
            position
                + Vector3.new(
                    0,
                    10,
                    0
                ),
            Vector3.new(
                0,
                -90,
                0
            ),
            params
        )

    if not hit then
        return nil
    end

    return Vector3.new(
        position.X,
        hit.Position.Y + 2.7,
        position.Z
    )
end

function H:RememberSafeQuestTarget(
    query,
    mobRoot,
    mob
)
    if not mobRoot
        or not mobRoot.Parent then

        return nil
    end

    local safe =
        self:SafeQuestTargetGround(
            mobRoot.Position,
            mob
        )

    if not safe then
        return nil
    end

    self.Runtime.LastSafeQuestTargetQuery =
        self:NormalizeMobText(
            query
        )

    self.Runtime.LastSafeQuestTargetPosition =
        safe

    self.Runtime.LastSafeQuestTargetAt =
        os.clock()

    return safe
end

function H:LastSafeQuestTarget(
    query
)
    local wanted =
        self:NormalizeMobText(
            query
        )

    if wanted == ""
        or self.Runtime.LastSafeQuestTargetQuery
            ~= wanted then

        return nil
    end

    local pos =
        self.Runtime.LastSafeQuestTargetPosition

    if typeof(pos) ~= "Vector3" then
        return nil
    end

    if os.clock()
        - (
            self.Runtime.LastSafeQuestTargetAt
            or 0
        )
        > 120 then

        return nil
    end

    return pos
end


function H:MarkBossLoopTargetSeen(
    query,
    mob,
    mobHum
)
    if not self.State.AutoLevelFarm then
        return
    end

    local store =
        self.Data.AutoLevel

    if type(store) ~= "table"
        or type(
            store.CurrentRecord
        ) ~= "table"
        or tostring(
            store.CurrentRecord.Category
            or ""
        ) ~= "BossHunt" then

        return
    end

    local wanted =
        self:NormalizeMobText(
            query
        )

    local current =
        self:NormalizeMobText(
            store.CurrentRecord.Target
        )

    if wanted == ""
        or wanted ~= current then

        return
    end

    store.BossLoopResumeTarget = nil
    store.BossLoopResumeRecord = nil
    store.BossLoopResumePosition = nil
    local seenRoot = mob:FindFirstChild("HumanoidRootPart", true) or mob.PrimaryPart
    store.BossLoopLastSeenPosition = seenRoot and seenRoot.Position or nil

    store.BossLoopSeenTarget =
        true

    store.BossLoopSeenTargetKey =
        current

    store.BossLoopLastSeenAt =
        os.clock()

    store.BossLoopLastSeenModel =
        mob

    store.BossLoopLastSeenHealth =
        mobHum
        and tonumber(
            mobHum.Health
        )
        or nil

    if type(store.BossLoopSkippedUntil) == "table" then
        store.BossLoopSkippedUntil[current] = nil
    end
end

function H:BossLoopRotateAfterMissing(query)
    local store = self.Data.AutoLevel
    local rec = store and store.CurrentRecord
    if not self.State.AutoLevelFarm or not rec or rec.Category ~= "BossHunt"
        or store.BossLoopRespawning or store.BossLoopResumeTarget
        or not store.BossLoopSeenTarget
        or self:NormalizeMobText(query) ~= self:NormalizeMobText(rec.Target)
        or os.clock() - (store.BossLoopLastSeenAt or os.clock()) < 1.25 then return false end
    store.BossLoopSeenTarget = false
    store.BossLoopSeenTargetKey = nil
    self.Runtime.BossProbeDestination = store.BossLoopLastSeenPosition or rec.Spawn
    self.Runtime.BossProbeArrivedAt = nil
    self.Runtime.BossProbeInstantTarget = nil
    self.Runtime.AutoLevelTargetSetAt = os.clock()
    -- Only the matching Humanoid.Died listener declares a kill/starts loot.
    return false
end

function H:BossLoopSkipUnspawned(query)
    if not self.State.AutoLevelFarm or self.Runtime.PostKillLooting then
        return false
    end
    local store = self.Data.AutoLevel
    local rec = type(store) == "table" and store.CurrentRecord or nil
    if type(rec) ~= "table" or rec.Category ~= "BossHunt"
        or self:NormalizeMobText(rec.Target) ~= self:NormalizeMobText(query)
        or store.BossLoopSeenTarget == true then
        return false
    end
    if store.BossLoopRespawning then return false end
    local now = os.clock()
    local selectedAt = tonumber(self.Runtime.AutoLevelTargetSetAt) or 0
    if selectedAt <= 0 then
        return false
    end

    local destination = self.Runtime.BossProbeDestination
    if typeof(destination) == "Vector3" then
        local root = self:Root()
        if root and (root.Position - destination).Magnitude > 10 then
            if store.BossLoopResumeTarget then return false end
            local initial = tonumber(self.Runtime.BossProbeInitialDistance) or 0
            local maxTravel = math.clamp(initial / (self.State.BossInstantTravel and 4000 or 380) + 2, 2.5, 15)
            if now - selectedAt < maxTravel then return false end
        else
            local arrivedAt = self.Runtime.BossProbeArrivedAt
            if not arrivedAt then
                self.Runtime.BossProbeArrivedAt = now
                return false
            end
            if now - arrivedAt < (store.BossLoopResumeTarget and 3.0 or 0.8) then return false end
        end
    elseif store.BossLoopResumeTarget or now - selectedAt < 0.8 then
        return false
    end

    store.BossLoopResumeTarget = nil
    store.BossLoopResumeRecord = nil
    store.BossLoopResumePosition = nil
    self.Runtime.BossProbeHolding = false
    store.BossLoopAdvancePending = true
    store.BossLoopLastSkippedTarget = tostring(rec.Target)
    store.BossLoopSkippedUntil = store.BossLoopSkippedUntil or {}
    store.BossLoopSkippedUntil[self:NormalizeMobText(rec.Target)] = now + 8
    self.Runtime.AutoLevelTargetSetAt = now
    self.Data.CurrentFarmTarget = nil
    self.Runtime.AttackTarget = nil
    self.Runtime.QuestEnemyCache = nil
    self:StopBossHover()
    self:StopSmoothMobTravel()
    self:StopMovement()
    self:StopAttackHold()
    self:StopBlocking()
    local choice = self:NormalizeMobText(self.State.BossFarmChoice)
    self:SetStatus("Boss Loop • " .. tostring(rec.Target)
        .. (choice ~= "" and choice ~= "allbosses"
            and " not spawned • retrying"
            or " not spawned • next boss"))
    return true
end

function H:BossLoopKnownSpawn(query)
    local wanted = self:NormalizeMobText(query)
    local store = self.Data.AutoLevel
    if store then
        if self:NormalizeMobText(store.BossLoopResumeTarget) == wanted then
            local saved = self:ValidBossPosition(store.BossLoopResumePosition)
            if saved then return saved end
        end
        local route = store.CurrentRecord
        if route and self:NormalizeMobText(route.Target) == wanted then
            local spawn = self:ValidBossPosition(route.Spawn)
            if spawn then return spawn end
        end
    end
    for code, rec in pairs(self.Data.Bosses or {}) do
        if type(rec) == "table"
            and (self:NormalizeMobText(code) == wanted
                or self:NormalizeMobText(rec.Code) == wanted
                or self:NormalizeMobText(rec.Title) == wanted) then
            local position = rec.Center
                or (rec.Info and rec.Info:GetAttribute("Center"))
            if typeof(position) == "CFrame" then position = position.Position end
            if typeof(position) == "Vector3"
                and math.abs(position.X) < 10000
                and math.abs(position.Y) < 10000
                and math.abs(position.Z) < 10000 then
                return position
            end
        end
    end
    return nil
end

function H:SimpleQuestCombatStep(active, def)
    local query =
        tostring(
            active
            and (
                active.Code
                or active.Task
            )
            or ""
        )

    if query == "" then
        self:SetStatus(
            "Mob Farm • target missing"
        )

        return true
    end

    -- BUILD 90:
    -- Active quest target ONLY. No Bosses registry / world-event fallback.
    local mob,
        mobRoot,
        mobHum,
        distance =
        self:FindExactQuestLiveTarget(
            query
        )

    if not mob
        or not mobRoot
        or not mobHum then

        if self:BossLoopRotateAfterMissing(
            query
        ) then

            return true
        end

        if self:BossLoopSkipUnspawned(query) then
            return true
        end

        local bossRecord = self.Data.AutoLevel
            and self.Data.AutoLevel.CurrentRecord
        local bossProbe = self.State.AutoLevelFarm
            and type(bossRecord) == "table"
            and bossRecord.Category == "BossHunt"

        self:StopBossHover()
        self:StopSmoothMobTravel()

        self.Runtime.MobApproachTravel =
            false

        self:ResetAggressiveMobState()
        self:ResetOrbitState()

        self.Runtime.NextRapidClickAt = 0
        self.Runtime.RapidClickBusy = false

        self.Runtime.NextBackgroundM1At = 0
        self.Runtime.BackgroundM1Busy = false
        self.Runtime.BackgroundM1Count = 0
        self.Runtime.NextCombatReadyRefresh = 0

        self.Runtime.SpamObservedTarget = nil
        self.Runtime.SpamObservedHealth = nil

        if self.Runtime.SimpleDirectTween then
            pcall(function()
                self.Runtime.SimpleDirectTween:Cancel()
            end)

            self.Runtime.SimpleDirectTween =
                nil

            self.Runtime.SimpleDirectGoal =
                nil

            self.Runtime.SimpleDirectKey =
                nil
        end

        self:SetManualFarmNoclip(
            false
        )

        if not bossProbe then self:StopMovement() end
        self:StopAttackHold()
        self:StopBlocking()

        self.Data.CurrentFarmTarget =
            nil

        -- BUILD 92 • ROLLBACK QUEST TRAVEL
        --
        -- Keep the exact-target resolver, but restore the earlier simple
        -- movement pattern that actually travelled: stream the target area,
        -- then TweenExact directly to that target's known spawn/quest anchor.
        local destination =
            self:LastSafeQuestTarget(
                query
            )

        local destinationLabel =
            destination
            and "last live target position"
            or "exact target spawn"

        if not destination and bossProbe then
            destination = self:BossLoopKnownSpawn(query)
        end

        if not destination then
            destination =
                self:GetMobStreamHint(
                    query
                )
        end

        if not destination and bossProbe then
            destination = self:BossLoopKnownSpawn(query)
            if destination then destinationLabel = "boss spawn" end
        end

        if not destination then
            local fallback,
                fallbackLabel =
                self:QuestFallbackPosition(
                    query,
                    active,
                    def
                )

            -- Do not use the generic quest-giver region as a combat target.
            if fallback
                and tostring(
                    fallbackLabel
                    or ""
                ) ~= "Quest Region" then

                destination =
                    fallback

                destinationLabel =
                    fallbackLabel
                    or "quest target"
            end
        end

        if not destination then
            self:StopMovement()
            self:SetMobTravelNoclip(
                false
            )

            self:SetStatus(
                "Auto Level • waiting for exact target spawn • "
                .. query
            )

            return true
        end

        if bossProbe then
            self.Runtime.BossProbeDestination = destination
            local root = self:Root()
            if root and not self.Runtime.BossProbeInitialDistance then
                self.Runtime.BossProbeInitialDistance =
                    (root.Position - destination).Magnitude
            end
        end

        if os.clock()
            - (
                self.Runtime.LastMobStreamAt
                or 0
            )
            >= 0.55 then

            self.Runtime.LastMobStreamAt =
                os.clock()

            task.spawn(
                function()
                    if not self.State.Unloaded then
                        self:RequestStreamAt(
                            destination,
                            bossProbe and 0.75 or 1.50,
                            false
                        )
                    end
                end
            )
        end

        local myRoot =
            self:Root()

        local remaining =
            myRoot
            and (
                myRoot.Position
                - destination
            ).Magnitude
            or math.huge

        -- A distant boss might not be streamed yet. Once its destination has
        -- a real floor, jump there once and check whether the boss is alive.
        -- If the floor is absent, retain the existing fast tween fallback.
        if bossProbe and self.State.BossInstantTravel and myRoot
            and remaining > 10
            and self.Runtime.BossProbeInstantTarget
                ~= self:NormalizeMobText(query)
            and destination.Y > self.S.Workspace.FallenPartsDestroyHeight + 30
            and math.abs(destination.X) < 10000
            and math.abs(destination.Y) < 10000
            and math.abs(destination.Z) < 10000 then
            local floor = self:GroundBelow(destination, 25)
            if floor and floor.Normal.Y >= 0.45
                and math.abs(destination.Y - floor.Position.Y) <= 12 then
                self:StopMovement()
                self:SetMobTravelNoclip(true)
                local landed = pcall(function()
                    myRoot.AssemblyLinearVelocity = Vector3.zero
                    myRoot.AssemblyAngularVelocity = Vector3.zero
                    myRoot.CFrame = CFrame.new(
                        floor.Position + Vector3.new(0, 3.5, 0)
                    )
                end)
                if landed then
                    self.Runtime.BossProbeInstantTarget =
                        self:NormalizeMobText(query)
                    self.Runtime.BossProbeArrivedAt = os.clock()
                    self.Runtime.BossProbeHolding = true
                    self:UpdateMovementSupport()
                    self:SetStatus("Boss Loop • checking " .. query .. " spawn")
                    return true
                end
            end
        end

        if remaining > 10 then
            self.Runtime.BossProbeHolding = false
            self:SetMobTravelNoclip(
                true
            )

            local tween = self.Runtime.ActiveTween
            local goal = self.Runtime.MoveGoal
            if (not bossProbe or os.clock()
                    - (self.Runtime.BossProbeLastTweenAt or 0) >= 0.45)
                and (not tween
                or tween.PlaybackState ~= Enum.PlaybackState.Playing
                or typeof(goal) ~= "Vector3"
                or (goal - destination).Magnitude > 3) then
                if bossProbe then self.Runtime.BossProbeLastTweenAt = os.clock() end
                self:TweenExact(destination, nil, bossProbe
                    and (self.State.BossInstantTravel and 4000 or 380) or nil)
            end

            self:SetStatus(
                "Auto Level • travelling to "
                .. query
                .. " • "
                .. tostring(
                    math.floor(
                        remaining
                    )
                )
                .. " studs • "
                .. tostring(
                    destinationLabel
                )
            )
        else
            self:SetMobTravelNoclip(
                false
            )

            if self.Runtime.ActiveTween then self:StopMovement() end

            if bossProbe then
                self.Runtime.BossProbeHolding = true
                self:UpdateMovementSupport()
            end

            if bossProbe and not self.Runtime.BossProbeArrivedAt then
                self.Runtime.BossProbeArrivedAt = os.clock()
            end

            self:SetStatus(
                bossProbe and ("Boss Loop • " .. query .. " • checking spawn")
                or destinationLabel == "last live target position"
                and (
                    "Auto Level • "
                    .. query
                    .. " defeated • waiting safely for respawn"
                )
                or (
                    "Auto Level • at "
                    .. query
                    .. " area • waiting for exact live target"
                )
            )
        end

        return true
    end

    self:MarkBossLoopTargetSeen(
        query,
        mob,
        mobHum
    )

    -- The probe tween must release the character as soon as the live boss is
    -- found; close-range hover and combat take movement ownership from here.
    if self.Runtime.BossProbeDestination and self.Runtime.ActiveTween then
        self:StopMovement()
    end
    self.Runtime.BossProbeHolding = false
    self.Runtime.BossProbeDestination = nil
    self.Runtime.BossProbeInitialDistance = nil
    self.Runtime.BossProbeArrivedAt = nil

    local safeLiveTarget =
        self:RememberSafeQuestTarget(
            query,
            mobRoot,
            mob
        )

    if not safeLiveTarget then
        -- The exact target model exists, but its root is no longer over real
        -- terrain. This commonly happens during the physics/kill transition.
        -- Never chase that root into the void.
        self.Runtime.QuestEnemyCache =
            nil

        self.Data.CurrentFarmTarget =
            nil

        self.Runtime.AttackTarget =
            nil

        self:StopBossHover()
        self:StopSmoothMobTravel()
        self:StopMovement()
        self:SetMobTravelNoclip(
            false
        )

        self:SetStatus(
            "Auto Level • target transitioning/respawning • holding safe position"
        )

        return true
    end

    self.Data.CurrentFarmTarget =
        mob

    self.Data.CurrentFarmQuery =
        query

    self.Data.CurrentFarmRegion =
        self:ModelRegion(
            mob
        )

    self.Runtime.AttackTarget =
        mob

    self:SetStatus(
        "Auto Level • EXACT QUEST TARGET ✓ "
        .. tostring(
            mob.Name
        )
        .. " • "
        .. string.format(
            "%.1f",
            tonumber(
                distance
            )
            or 0
        )
        .. " studs"
    )

    self:WatchFarmMobDeath(
        mob
    )

    self:UpdateMobSafeAnchor()

    -- Keep the emergency void/knockback recovery from BUILD 35. It only fires
    -- after physics has already launched us below a raycast-confirmed floor.
    if self:RecoverMobKnockback(
        mobRoot
    ) then

        self.Runtime.AggressiveLostAt =
            os.clock()

        return true
    end

    return self:AggressiveMobFarmStep(
        mob,
        mobRoot
    )
end

-- ============================================================
-- BUILD 29 • MANUAL FARM CONTROLLER
-- ============================================================

function H:SelectedQuestRecord()
    local key =
        tostring(
            self.State.SelectedQuest
            or ""
        )

    if key == "" then
        return nil
    end

    local quests = self.Modules.Quests
    local def =
        type(quests) == "table"
        and type(quests.Holder) == "table"
        and quests.Holder[key]
        or nil

    if type(def) ~= "table" then
        return nil
    end

    return {
        Key = key,
        Name =
            def.QuestInstance
            and tostring(def.QuestInstance.Name)
            or key,
        Npc = tostring(def.OfferNpc or ""),
        Level = self:QuestRequiredLevel(def),
        Definition = def,
    }
end

function H:GetSelectedActiveQuest(selected)
    if not selected then
        return nil
    end

    local slot = self:GetSlotData()
    local quests = slot and slot:FindFirstChild("Quests")
    local holder = quests and quests:FindFirstChild("Holder")

    if not holder then
        return nil
    end

    local wantedKey =
        self:NormalizeMobText(selected.Key)

    local wantedName =
        self:NormalizeMobText(selected.Name)

    for _, quest in ipairs(holder:GetChildren()) do
        local qs =
            quest:FindFirstChild("QuestString")

        local questKey =
            qs
            and qs:IsA("StringValue")
            and tostring(qs.Value)
            or ""

        local matches =
            (
                wantedKey ~= ""
                and self:NormalizeMobText(questKey)
                    == wantedKey
            )
            or (
                wantedName ~= ""
                and self:NormalizeMobText(quest.Name)
                    == wantedName
            )

        if matches then
            local q = {
                Instance = quest,
                Name = quest.Name,
                Key = questKey ~= "" and questKey or selected.Key,
                Task = nil,
                Code = nil,
                Value = nil,
                Max = nil,
            }

            local tasks =
                quest:FindFirstChild("Tasks")

            if tasks then
                for _, task in ipairs(tasks:GetChildren()) do
                    local value =
                        task:FindFirstChild("Value")

                    local max =
                        task:FindFirstChild("Max")

                    local code =
                        task:FindFirstChild("Code")

                    local valueN =
                        value
                        and tonumber(value.Value)

                    local maxN =
                        max
                        and tonumber(max.Value)

                    local unfinished =
                        maxN == nil
                        or valueN == nil
                        or valueN < maxN

                    if unfinished then
                        q.Task = task.Name
                        q.Code =
                            code
                            and tostring(code.Value)
                            or nil
                        q.Value = valueN
                        q.Max = maxN
                        q.CountsDown = false
                        break
                    end
                end
            end

            return q
        end
    end

    return nil
end

function H:ManualQuestFarmStep()
    self.State.SmartProgression = false
    self.State.MovementType = "Tween"
    self.State.AutoAccept = true

    local selected =
        self:SelectedQuestRecord()

    if self.State.AutoLevelFarm then
        local anyActive =
            self:GetActiveQuest()

        if anyActive then
            local _activeDef,
                activeHolderKey =
                self:QuestDefinition(
                    anyActive.Key,
                    anyActive.Name
                )

            local activeKey =
                tostring(
                    activeHolderKey
                    or anyActive.Key
                    or ""
                )

            local selectedKey =
                selected
                and tostring(
                    selected.Key
                    or ""
                )
                or ""

            if activeKey ~= ""
                and self:NormalizeMobText(
                    activeKey
                )
                ~= self:NormalizeMobText(
                    selectedKey
                ) then

                -- Do not talk to the new quest NPC at all. Finish the Holder
                -- quest first, then AutoLevel may select a stronger one.
                self.State.SelectedQuest =
                    activeKey

                local activeTarget =
                    anyActive.Code
                    or anyActive.Task

                if activeTarget then
                    self.State.SelectedMob =
                        self:ResolveAutoLevelMobName(
                            activeTarget
                        )
                        or tostring(
                            activeTarget
                        )
                end

                selected =
                    self:SelectedQuestRecord()

                self:SetStatus(
                    "Auto Level • existing quest detected • finishing "
                    .. tostring(
                        anyActive.Name
                    )
                    .. " first"
                )
            end
        end
    end

    if not selected then
        if self.State.AutoLevelFarm then
            self.Data.AutoLevel.BuiltAt = 0
            self.Data.AutoLevel.CurrentTarget = nil
            self.Data.AutoLevel.CurrentLevel = 0

            self:StopMovement()
            self:StopAttackHold()
            self:StopBlocking()

            self:SetStatus(
                "Auto Level • quest data refreshing • farm stays ON"
            )

            return true
        end

        self.State.AutoQuest = false
        self:StopMovement()
        self:StopAttackHold()
        self:StopBlocking()
        self:RefreshToggleButtons()
        self:SetStatus(
            "Quest Farm • choose a quest first"
        )
        return true
    end

    local active =
        self:GetSelectedActiveQuest(
            selected
        )

    if not active
        and os.clock()
            < (
                self.Runtime.ExactQuestChoiceVerifyUntil
                or 0
            ) then

        self:StopMovement()
        self:StopAttackHold()

        self:SetStatus(
            "Quest Farm • verifying quest acceptance"
        )

        return true
    end

    if not active
        and self.Runtime.ExactQuestChoiceVerifyUntil
        and os.clock()
            >= self.Runtime.ExactQuestChoiceVerifyUntil then

        -- Verification failed: dialogue is still open / quest did not appear.
        -- Clear the verify window so the next farm tick retries the same exact
        -- choice rather than pretending acceptance succeeded.
        self.Runtime.ExactQuestChoiceVerifyUntil =
            nil

        self.Runtime.WaitingForSelectedQuestUntil =
            nil

        self:SetStatus(
            "Quest Farm • accept did not register • retrying exact choice"
        )
    end

    -- STEP 1 / REPEAT:
    -- The selected quest is not active -> go straight to its NPC and accept it.
    if not active then
        self:SafeText(
            self.UI.QuestInfo,
            " Quest Farm • ACCEPT"
            .. "\n Quest • "
            .. tostring(
                selected.Name
            )
            .. "\n NPC • "
            .. tostring(
                selected.Npc
            )
        )

        return self:SimpleQuestNpcStep(
            selected,
            selected.Npc,
            "accept"
        )
    end

    local def, holderKey =
        self:QuestDefinition(
            active.Key,
            active.Name
        )

    def =
        def
        or selected.Definition

    holderKey =
        holderKey
        or selected.Key

    -- STEP 2:
    -- Quest has an unfinished task -> kill its live enemy.
    if active.Task then
        local interactionNpc =
            self:QuestInteractionNpc(
                active,
                def
            )

        -- Dialogue/delivery tasks still use the quest's real named NPC.
        if interactionNpc then
            return self:SimpleQuestNpcStep(
                {
                    Key = holderKey,
                    Name = active.Name,
                },
                interactionNpc,
                "progress"
            )
        end

        self:SafeText(
            self.UI.QuestInfo,
            " Quest Farm • KILL"
            .. "\n Quest • "
            .. tostring(
                selected.Name
            )
            .. "\n Enemy • "
            .. tostring(
                active.Code
                or active.Task
            )
            .. (
                self:QuestProgressText(
                    active
                ) ~= ""
                and (
                    "\n Progress • "
                    .. self:QuestProgressText(
                        active
                    )
                )
                or ""
            )
        )

        return self:SimpleQuestCombatStep(
            active,
            def
        )
    end

    -- STEP 3:
    -- Quest finished -> go back to its quest NPC / explicit handoff.
    -- Once the server removes the finished quest, the next tick returns to
    -- STEP 1 and accepts the same selected quest again.
    local handoff =
        select(
            1,
            self:QuestCompletionHandoffNpc(
                def
            )
        )

    local npcName =
        handoff
        or selected.Npc

    self:SafeText(
        self.UI.QuestInfo,
        " Quest Farm • COMPLETE"
        .. "\n Quest • "
        .. tostring(
            selected.Name
        )
        .. "\n Return • "
        .. tostring(
            npcName
        )
    )

    return self:SimpleQuestNpcStep(
        {
            Key = holderKey,
            Name = active.Name,
        },
        npcName,
        "turnin"
    )
end

function H:ManualEnemyFarmStep()
    self.State.SmartProgression = false
    self.State.MovementType = "Tween"

    local enemy =
        tostring(
            self.State.SelectedMob
            or ""
        )

    if os.clock()
        < (
            self.Runtime.MobResumeAt
            or 0
        ) then

        self:SetStatus(
            "Mob Farm • respawn load • farm remains ON"
        )

        return true
    end

    if enemy == "" then
        self.State.AutoFarmMobs = false

        self:StopSmoothMobTravel()

        self.Runtime.MobApproachTravel =
            false

        self:StopMovement()
        self:StopAttackHold()
        self:StopBlocking()
        self:RefreshToggleButtons()
        self:SetStatus("Mob Farm • choose a mob first")
        return true
    end

    if os.clock()
        - (self.Runtime.ManualEnemyRefreshAt or 0)
        > 0.55 then

        self.Runtime.ManualEnemyRefreshAt =
            os.clock()

        self:RefreshMobs()
    end

    local pseudoQuest = {
        Name = "Mob Farm",
        Task = enemy,
        Code = enemy,
    }

    local result =
        self:SimpleQuestCombatStep(
            pseudoQuest,
            nil
        )

    if not self.Data.CurrentFarmTarget
        or not self.Data.CurrentFarmTarget.Parent then

        self:SetStatus(
            "Mob Farm • waiting for live "
            .. enemy
        )
    end

    return result
end

function H:FarmStep()
    self.State.SmartProgression = false

    -- BUILD 75:
    -- Manual Mob Farm is quest-free. AFK Auto Level owns SelectedQuest and
    -- AutoQuest so it can accept/turn in the best combat quest for extra XP.
    if not self.State.AutoLevelFarm then
        self.State.AutoQuest = false
        self.State.AutoAccept = false
        self.State.SelectedQuest = ""
    else
        -- BUILD 99 boss loop is direct-combat only.
        self.State.AutoQuest = false
        self.State.AutoAccept = false
        self.State.SelectedQuest = ""
    end

    -- Do not let missing character parts during death/respawn unwind the AFK
    -- automation state. Just wait until the new Humanoid exists.
    local aliveHum =
        self:Humanoid()

    if not aliveHum
        or aliveHum.Health <= 0 then

        if self.State.AutoLevelFarm
            or self.State.AutoFarmMobs then

            self:SetStatus(
                "AFK Farm • waiting for respawn • automation stays ON"
            )
        end

        return
    end

    if (self.Data.AutoLevel and self.Data.AutoLevel.BossLoopRespawning)
        or os.clock() < (self.Runtime.MobResumeAt or 0) then return end

    if not self.State.AutoFarmMobs then
        if self.Runtime.PostKillLooting then
            self:FinishPostKillLoot()
        end

        self:StopSmoothMobTravel()

        self.Runtime.MobApproachTravel =
            false

        self:SetManualFarmNoclip(false)

        self.Runtime.MobRetreating =
            false

        self.Runtime.MobRetreatGoal =
            nil

        self.Runtime.MobDamagePauseUntil =
            0

        self:ResetAggressiveMobState()

        if self.Runtime.SimpleDirectTween then
            pcall(
                function()
                    self.Runtime.SimpleDirectTween:Cancel()
                end
            )

            self.Runtime.SimpleDirectTween =
                nil
        end

        pcall(function()
            local hum =
                self:Humanoid()

            if hum then
                hum.AutoRotate =
                    true
            end
        end)
    end

    if self.State.AutoFarmMobs then
        if self.Runtime.PostKillLooting then
            local ok, err =
                pcall(function()
                    self:PostKillLootStep()
                end)

            if not ok then
                local msg =
                    tostring(
                        err
                    )

                self:FinishPostKillLoot()

                self:SetStatus(
                    "Mob Farm loot error • "
                    .. string.sub(
                        msg,
                        1,
                        120
                    )
                )
            end

            return
        end

        local ok, err =
            pcall(function()
                local autoLevelRec =
                    self.Data.AutoLevel
                    and self.Data.AutoLevel.CurrentRecord
                    or nil

                if self.State.AutoLevelFarm
                    and (type(autoLevelRec) ~= "table"
                        or tostring(self.State.SelectedMob or "") == "") then
                    -- No live eligible boss yet. Keep the boss loop on without
                    -- entering the manual mob lane, which would toggle it off.
                    self.Data.CurrentFarmTarget = nil
                    self.Runtime.AttackTarget = nil
                    return
                end

                if self.State.AutoLevelFarm
                    and type(autoLevelRec) == "table"
                    and tostring(
                        autoLevelRec.Category
                        or ""
                    ) == "BossHunt"
                    and tostring(
                        self.State.SelectedMob
                        or ""
                    ) ~= "" then

                    -- BUILD 99:
                    -- TRUE DIRECT BOSS LOOP.
                    -- No trainer/quest NPC dependency; go straight to the boss.
                    self:SimpleQuestCombatStep(
                        {
                            Name =
                                tostring(
                                    autoLevelRec.Quest
                                    or "Boss Loop"
                                ),
                            Task =
                                tostring(
                                    self.State.SelectedMob
                                ),
                            Code =
                                tostring(
                                    self.State.SelectedMob
                                ),
                            Value = 0,
                            Max = 1,
                        },
                        nil
                    )
                else
                    self:ManualEnemyFarmStep()
                end
            end)

        if not ok then
            local msg = tostring(err)

            if #msg > 150 then
                msg =
                    string.sub(msg, 1, 150)
                    .. "…"
            end

            self:StopMovement()
            self:StopAttackHold()
            self:SetStatus(
                "Mob Farm error • "
                .. msg
            )
        end

        return
    end

    if not self.State.AutoWorldBoss
        and self.Runtime.BossTravelNoclip then

        self:SetBossTravelNoclip(
            false
        )
    end

    if self.State.KillAura
        and not self.State.AutoFarmMobs
        and not self.State.AutoWorldBoss then return end
    if self.State.AutoWorldBoss then
        local rec, reason =
            self:BossTarget()

        if rec then
            local root =
                rec.Model
                and (
                    rec.Model:FindFirstChild(
                        "HumanoidRootPart",
                        true
                    )
                    or rec.Model.PrimaryPart
                )

            local pos =
                root
                and root.Position
                or rec.Center

            if pos then
                if self:SafeCombatHealthStep(
                    rec.Model
                ) then

                    self:SetBossTravelNoclip(
                        false
                    )

                    return
                end

                local myRoot =
                    self:Root()

                local bossDistance =
                    myRoot
                    and (
                        myRoot.Position
                        - pos
                    ).Magnitude
                    or math.huge

                -- Keep collision disabled for the ENTIRE long-distance boss
                -- journey. This allows the existing tween travel to cross
                -- walls, cliffs and cave geometry instead of getting pinned.
                self:SetBossTravelNoclip(
                    bossDistance > 7.0
                )

                self:MoveTo(
                    pos,
                    root and root.CFrame or nil,
                    rec.Model
                )

                local bossGuardRange =
                    tonumber(
                        self.State.BossGuardRange
                    ) or 24

                if self.State.BossSafetyMode
                    and bossDistance <= bossGuardRange
                    and bossDistance > 6 then

                    -- Approach bosses already guarded. Do not wait until we're
                    -- inside M1 range to protect against lunges/projectiles.
                    self.Runtime.ForceAttackUntil = 0
                    self:StartBlocking(false)
                end

                if bossDistance <= 6 then
                    self:SetBossTravelNoclip(
                        false
                    )

                    self:StartAttackHold(
                        rec.Model
                    )
                elseif bossDistance > bossGuardRange then
                    self:StopAttackHold()
                    self:StopBlocking()
                else
                    self:StopAttackHold()
                end

                if self.State.SmartSkill
                    and self.State.SelectedSkill then

                    self:UseSkill(
                        self.State.SelectedSkill
                    )
                end

                self:SetStatus(
                    "World Boss • "
                    .. rec.Code
                    .. (
                        bossDistance > 7
                        and " • wall-travel "
                            .. tostring(
                                math.floor(
                                    bossDistance
                                )
                            )
                            .. " studs"
                        or " • combat"
                    )
                )

                return
            end
        elseif reason == "waiting-night" then
            self:SetBossTravelNoclip(
                false
            )

            self:StopAttackHold()
            self:SetStatus(
                "World Boss • waiting for night"
            )
            return
        elseif self.State.AutoBossChest then
            self:SetBossTravelNoclip(
                false
            )

            if self:BossChestStep() then
                return
            end
        else
            self:SetBossTravelNoclip(
                false
            )
        end
    end

    local questRoute

    do
        local okQuest, routeOrError =
            pcall(
                function()
                    return self:QuestStep()
                end
            )

        if okQuest then
            questRoute = routeOrError
            self.Runtime.LastQuestStepError = nil
        else
            local errText = tostring(routeOrError)
            self.Runtime.LastQuestStepError = errText

            warn(
                "[THUMBSHUB] QuestStep isolated error: "
                .. errText
            )

            local active = self:GetActiveQuest()

            if active and active.Task then
                questRoute = {
                    Mode = "combat",
                    Query = active.Code or active.Task,
                    Quest = active,
                }
            elseif self.State.SmartProgression then
                -- A quest engine error must never leave the Start button looking
                -- active while nothing happens. Route the known early quest or
                -- expose the exact error in the hub status bar.
                local fallback = self:KnownProgressionFallback()

                if fallback then
                    self.Data.AutoQuest.Stage = "accept-recovery"
                    self:SafeText(
                        self.UI.QuestInfo,
                        " Smart Progression • RECOVERY"
                        .. "\n Quest • " .. tostring(fallback.Name)
                        .. "\n NPC • " .. tostring(fallback.Npc)
                    )
                    self:QuestNpcStep(fallback, fallback.Npc, "accept")
                    self:SetStatus(
                        "Smart Progression • recovery route → "
                        .. tostring(fallback.Npc)
                    )
                    return
                end

                local short = string.gsub(errText, "^.-:%s*", "")
                if #short > 110 then short = string.sub(short, 1, 110) .. "…" end
                self:SetStatus("Quest engine error • " .. short)
                return
            end
        end
    end

    local shouldFarm =
        (
            questRoute
            and (
                questRoute.Mode == "combat"
                or questRoute.Mode == "levelgrind"
            )
        )
        or (
            self.State.AutoFarmMobs
            and not (
                questRoute
                and (
                    questRoute.Mode == "accept"
                    or questRoute.Mode == "turnin"
                    or questRoute.Mode == "interact"
                )
            )
        )

    if not shouldFarm then
        self:StopAttackHold()
        return
    end

    local query =
        questRoute
        and questRoute.Mode == "combat"
        and questRoute.Query
        or self.State.SelectedMob

    local mob
    local distance

    if questRoute
        and questRoute.Mode == "levelgrind" then

        mob, distance =
            self:LevelGrindTarget()

        query =
            mob
            and tostring(mob.Name)
            or "safe level mob"

        if not mob then
            self:RefreshMobs()

            mob, distance =
                self:LevelGrindTarget()
        end

        if not mob then
            self:StopAttackHold()
            self:StopBlocking()

            self:SetStatus(
                "Smart Progression • Lv "
                .. tostring(
                    questRoute.CurrentLevel
                    or "?"
                )
                .. "/"
                .. tostring(
                    questRoute.RequiredLevel
                    or "?"
                )
                .. " • waiting for safe mob"
            )

            return
        end
    else
        mob, distance =
            self:NearestMob(
                query,
                questRoute and questRoute.Quest or nil,
                questRoute and questRoute.Definition or nil
            )
    end

    -- Quest codes and rendered model names do not always match. Try the
    -- visible task label as a second route.
    if not mob
        and questRoute
        and questRoute.Mode == "combat"
        and questRoute.Quest
        and questRoute.Quest.Task
        and tostring(questRoute.Quest.Task)
            ~= tostring(query) then

        local taskQuery =
            tostring(
                questRoute.Quest.Task
            )

        mob, distance =
            self:NearestMob(
                taskQuery,
                questRoute.Quest,
                questRoute.Definition
            )

        if mob then
            query = taskQuery
        end
    end

    -- The current "Village Spies" quest deliberately disguises enemies as
    -- villagers. If neither the internal task code nor task text identifies a
    -- model, use live Civilian NPCs ONLY for this spy quest.
    if not mob
        and questRoute
        and questRoute.Mode == "combat"
        and questRoute.Quest then

        local taskText =
            string.lower(
                tostring(
                    questRoute.Quest.Task
                    or ""
                )
            )

        local codeText =
            string.lower(
                tostring(
                    questRoute.Quest.Code
                    or ""
                )
            )

        local isSpyQuest =
            string.find(
                taskText,
                "spies",
                1,
                true
            ) ~= nil
            or string.find(
                taskText,
                "spy",
                1,
                true
            ) ~= nil
            or string.find(
                codeText,
                "spy",
                1,
                true
            ) ~= nil

        if isSpyQuest then
            mob, distance =
                self:NearestMob(
                    query,
                    questRoute.Quest,
                    questRoute.Definition
                )

            if mob then
                query =
                    "*Civilian* (disguised spy)"
            end
        end
    end

    if not mob then
        -- Quest enemies can appear/update after the accept dialogue closes.
        self:RefreshMobs()

        mob, distance =
            self:NearestMob(
                query,
                questRoute and questRoute.Quest or nil,
                questRoute and questRoute.Definition or nil
            )

        if not mob
            and questRoute
            and questRoute.Quest then

            local taskText =
                string.lower(
                    tostring(
                        questRoute.Quest.Task
                        or ""
                    )
                )

            local codeText =
                string.lower(
                    tostring(
                        questRoute.Quest.Code
                        or ""
                    )
                )

            if string.find(taskText, "spies", 1, true)
                or string.find(taskText, "spy", 1, true)
                or string.find(codeText, "spy", 1, true) then

                mob, distance =
                    self:NearestMob(
                        query,
                        questRoute.Quest,
                        questRoute.Definition
                    )

                if mob then
                    query =
                        "*Civilian* (disguised spy)"
                end
            end
        end
    end

    if not mob then
        self:StopAttackHold()
        self:StopBlocking()

        local fallbackPosition, fallbackLabel =
            self:QuestFallbackPosition(
                query,
                questRoute and questRoute.Quest or nil,
                questRoute and questRoute.Definition or nil
            )

        if fallbackPosition then
            self:TweenExact(
                fallbackPosition
                + Vector3.new(0, 2, 0)
            )

            self:SetStatus(
                "Auto Quest • waiting for target • "
                .. tostring(query)
                .. " • route="
                .. tostring(fallbackLabel)
            )
        else
            local aliases =
                self:MobAliases(query)

            self:SetStatus(
                "Auto Quest • waiting for spawn • query="
                .. tostring(query)
                .. " • aliases="
                .. table.concat(
                    aliases,
                    "/"
                )
                .. " • live="
                .. tostring(#self.Data.Mobs)
            )
        end

        return
    end

    self.Data.CurrentFarmTarget = mob
    self.Data.CurrentFarmQuery = query
    self.Data.CurrentFarmRegion = self:ModelRegion(mob)

    local targetKey = self:NormalizeMobText(query)
    self.Data.TargetWaitSince[targetKey] = nil

    local root =
        mob:FindFirstChild(
            "HumanoidRootPart",
            true
        )
        or mob.PrimaryPart

    if not root then
        self:StopAttackHold()

        self:SetStatus(
            "Auto Quest • target has no root • "
            .. tostring(mob.Name)
        )
        return
    end

    if self:SafeCombatHealthStep(
        mob
    ) then

        return
    end

    self:MoveTo(
        root.Position,
        root.CFrame,
        mob
    )

    if (distance or math.huge) <= 6 then
        self:StartAttackHold(mob)
    else
        self:StopAttackHold()
        if (distance or math.huge) <= 16 then
            self:GuardStep(mob)
        else
            self:StopBlocking()
        end
    end

    if self.State.SmartSkill
        and self.State.SelectedSkill
        and (distance or math.huge) <= 24 then

        self:UseSkill(
            self.State.SelectedSkill
        )
    end

    local prefix =
        (
            questRoute
            and questRoute.Mode == "levelgrind"
            and (
                "Level Grind "
                .. tostring(
                    questRoute.CurrentLevel
                    or "?"
                )
                .. "/"
                .. tostring(
                    questRoute.RequiredLevel
                    or "?"
                )
            )
        )
        or (
            questRoute
            and questRoute.Mode == "combat"
            and "Auto Quest"
            or "Mob Farm"
        )

    local progressText = ""

    if questRoute
        and questRoute.Quest then

        progressText =
            self:QuestProgressText(
                questRoute.Quest
            )

        if progressText ~= "" then
            progressText =
                " • "
                .. progressText
        end
    end

    local combatSuffix = ""

    if (distance or math.huge) <= 6 then
        local verifiedRecently =
            self.Runtime.LastVerifiedPunchAt
                and (
                    os.clock()
                    - self.Runtime.LastVerifiedPunchAt
                ) < 1.25

        local hitRecently =
            self.Runtime.LastHitConfirmAt
                and (
                    os.clock()
                    - self.Runtime.LastHitConfirmAt
                ) < 1.5

        combatSuffix =
            " • M1="
            .. tostring(
                self.Runtime.AttackBackend
                or "DirectPunch"
            )
            .. (
                verifiedRecently
                and " ✓"
                or ""
            )
            .. (
                hitRecently
                and " • HIT✓"
                or ""
            )

        if not verifiedRecently
            and self.Runtime.LastPunchFailure
            and self.Runtime.LastPunchFailure ~= "" then

            combatSuffix =
                combatSuffix
                .. " • "
                .. tostring(
                    self.Runtime.LastPunchFailure
                )
        end
    end

    self:SetStatus(
        prefix
        .. " • target="
        .. tostring(mob.Name)
        .. progressText
        .. " • "
        .. tostring(
            math.floor(
                distance or 0
            )
        )
        .. " studs"
        .. combatSuffix
    )
end

function H:ChestStep()
    if not self.State.AutoChests
        or self.Runtime.PostKillLooting
        or self.Runtime.BossChestLootPhase
        or os.clock()
            - (
                self.Runtime.LastChest
                or 0
            )
            < 0.40 then

        return
    end

    self.Runtime.LastChest =
        os.clock()

    local root =
        self:Root()

    if not root then
        return
    end

    local chest,
        distance =
        self:NearestTagged(
            self:ChestTag(),
            function(obj)
                if self.State.ChestFilter == "Any" then
                    return true
                end

                return obj.Name
                    == self.State.ChestFilter
            end
        )

    if not chest
        or not distance then

        return
    end

    local prompt =
        self:PromptOf(
            chest
        )

    if not prompt
        or prompt.Enabled == false then

        return
    end

    local activation =
        tonumber(
            prompt.MaxActivationDistance
        )
        or 8

    -- BUILD 55:
    -- Generic Auto Collect Chests is now LOCAL-ONLY. It must never search the
    -- whole map and drag the player into an unstreamed/void area.
    --
    -- Long-range movement belongs only to:
    --   • PostKillLootStep() after a confirmed mob death
    --   • BossChestStep() after a confirmed boss kill
    if distance
        <= activation + 2 then

        self:SetStatus(
            "Auto Collect Chests • opening nearby chest"
        )

        self:OpenChestPromptReliable(
            prompt
        )

        return
    end

    -- A tiny local assist is safe for a chest that is visibly nearby.
    -- Anything farther away is ignored until the player/farm naturally gets
    -- close to it.
    local localAssistRange =
        math.min(
            18,
            activation + 8
        )

    if distance > localAssistRange then
        return
    end

    if self:FarmOwnsMovement() then
        return
    end

    local pos =
        self:PromptWorldPosition(
            prompt
        )

    if not pos then
        return
    end

    local direction =
        root.Position
        - pos

    if direction.Magnitude < 0.05 then
        direction =
            Vector3.new(
                1,
                0,
                0
            )
    end

    local standDistance =
        math.max(
            1.2,
            math.min(
                activation - 0.60,
                3.0
            )
        )

    local goal =
        pos
        + direction.Unit
        * standDistance

    goal =
        self:GroundClampPosition(
            goal,
            root.Position.Y,
            2.55
        )
        or goal

    self:SetStatus(
        "Auto Collect Chests • nearby • "
        .. tostring(
            math.floor(
                distance
            )
        )
        .. " studs"
    )

    self:SimpleDirectTween(
        goal,
        pos,
        80,
        "LOCAL_CHEST"
    )
end

function H:DropStep()
    local enabled =
        self.State.AutoDrops
        or (
            self.State.AutoLootAfterKill
            and (
                self.State.SmartProgression
                or self.State.AutoFarmMobs
                or self.State.AutoWorldBoss
            )
        )

    if not enabled
        or os.clock()
            - (
                self.Runtime.LastDrop
                or 0
            )
            < 0.22 then

        return
    end

    self.Runtime.LastDrop =
        os.clock()

    local root =
        self:Root()

    if not root then
        return
    end

    local drop,
        distance =
        self:NearestTagged(
            self:DropTag()
        )

    local prompt
    local pos

    if drop then
        prompt =
            self:PromptOf(
                drop
            )

        pos =
            self:ObjectWorldPosition(
                drop
            )
    end

    -- Some rewards (such as Mouth Dagger) are normal ProximityPrompt objects
    -- with ActionText = "Claim" and are not always present under LootDrop.
    if not prompt
        or not prompt.Parent
        or prompt.Enabled == false then

        local fallbackPrompt,
            fallbackDistance,
            fallbackPosition =
            self:NearestLootPickupPrompt(
                18
            )

        if fallbackPrompt then
            prompt =
                fallbackPrompt

            distance =
                fallbackDistance

            pos =
                fallbackPosition

            drop =
                fallbackPrompt.Parent
        end
    end

    if not prompt
        or not prompt.Parent
        or prompt.Enabled == false
        or not distance then

        return
    end

    local activation =
        tonumber(
            prompt.MaxActivationDistance
        )
        or 8

    if distance
        <= activation + 1.25 then

        self:SetStatus(
            "Auto Pick Up Drops • claiming "
            .. tostring(
                prompt.ObjectText ~= ""
                and prompt.ObjectText
                or "drop"
            )
        )

        -- Reliable path: executor prompt call + real prompt key (T/E/etc).
        self:CollectBossLootPrompt(
            prompt
        )

        return
    end

    -- Generic pickup remains LOCAL-ONLY to avoid the old map/void issue.
    if self:FarmOwnsMovement()
        or distance > 18 then

        return
    end

    if not pos then
        pos =
            self:PromptWorldPosition(
                prompt
            )
    end

    if not pos then
        return
    end

    local direction =
        root.Position
        - pos

    if direction.Magnitude < 0.05 then
        direction =
            Vector3.new(
                1,
                0,
                0
            )
    end

    local standDistance =
        math.max(
            1.0,
            math.min(
                activation - 0.50,
                2.75
            )
        )

    local goal =
        pos
        + direction.Unit
        * standDistance

    goal =
        self:GroundClampPosition(
            goal,
            root.Position.Y,
            2.55
        )
        or goal

    self:SetStatus(
        "Auto Pick Up Drops • "
        .. tostring(
            math.floor(
                distance
            )
        )
        .. " studs"
    )

    self:SimpleDirectTween(
        goal,
        pos,
        82,
        "LOCAL_DROP"
    )
end

do
    local env =
        (getgenv and getgenv())
        or _G

    local old =
        env.THUMBSHUB_NEW_GAME_INSTANCE

    if old
        and old ~= H
        and type(old) == "table" then

        if type(old.SetManualFarmNoclip) == "function" then
            pcall(function()
                old:SetManualFarmNoclip(false)
            end)
        end

        for part, value in pairs(
            old.Runtime
            and old.Runtime.CollisionOriginal
            or {}
        ) do
            if part and part.Parent then
                pcall(function()
                    part.CanCollide = value
                end)
            end
        end

        if type(old.Unload) == "function" then
            pcall(function()
                old:Unload()
            end)
        end
    end

    env.THUMBSHUB_NEW_GAME_INSTANCE = H
end

-- BUILD 29: Smart Progression is retired. Manual quest/enemy farming is TweenService-only.
-- Legacy progression code remains inert for compatibility with old profiles.
pcall(function()
    H.S.RunService:UnbindFromRenderStep("ThumbsHubDrivenWalk")
end)

-- BUILD 110: health gear recovery, using the user's verified Stats-only cycle.
do
-- ThumbsHub direct gear cycle R1
-- Original captured UI routes:
-- SignalEvent.ToServer("AccessoryEquip", slot.Name, 0/item.Id.Value, "Stats"/"Vanity")
-- SignalEvent.ToServer("Toolbar_Equip", slot.Name, 0/item.Id.Value)
-- Snapshots each player's equipped slots at Start; no fixed player/item IDs or loadouts.
-- One slot is removed and restored before advancing. No HP/protection edits.
local Engine={};Engine.__index=Engine
function Engine.new(a)
    return setmetatable({A=a,Busy=false,Cancel=false,Lines={},Cycles=0,Pairs=0,Calls=0,Gap=0,Status="Ready. Press Start to capture and cycle your worn gear."},Engine)
end
function Engine:Log(s)
    if #self.Lines>=250 then table.remove(self.Lines,1)end
    self.Lines[#self.Lines+1]=string.format("%.3fs %s",self.Started and self.A.Now()-self.Started or 0,tostring(s))
end
function Engine:Check(cleanup)
    local ok,why=self.A.Valid(self.Context)
    if not ok then error(why,0)end
    if not cleanup and (self.Cancel or (self.A.Enabled and not self.A.Enabled())) then error("Stopped.",0)end
end
function Engine:Send(e,id,cleanup)
    self:Check(cleanup)
    self.Pending=true;self.Calls=self.Calls+1
    local ok,err=pcall(self.A.Send,self.Context,e,id)
    self.Pending=false
    if not ok then error("Equip call error: "..tostring(err),0)end
    self:Check(cleanup)
end
function Engine:WaitFor(e,id,cleanup)
    local began=self.A.Now()
    repeat
        self:Check(cleanup)
        local current=self.A.Value(e)
        if current==id then return end
        if current~=0 and current~=e.Id then error("Slot changed to a different item: "..e.Label,0)end
        if self.A.Now()-began>=2 then error("No slot confirmation for "..e.Label.." -> "..id,0)end
        self.A.Wait(0)
    until false
end
function Engine:Pause(cleanup)
    self:Check(cleanup)
    if self.Gap<=0 then return end
    local untilTime=self.A.Now()+self.Gap
    repeat self:Check(cleanup);self.A.Wait(0)until self.A.Now()>=untilTime
    self:Check(cleanup)
end
function Engine:Restore()
    local e=self.Dirty
    if not e then self.Restoration="All cycled slots confirmed equipped.";return true end
    local ok,err=pcall(function()
        self:Check(true)
        local current=self.A.Value(e)
        if current~=0 and current~=e.Id then error("Another item is in the slot; it was left alone.",0)end
        -- Send the original ID even if the removal has not replicated yet: the
        -- previous remove may still be queued. Never overlap outstanding calls.
        self:Send(e,e.Id,true)
        self:WaitFor(e,e.Id,true)
        self.Dirty=nil
    end)
    self.Restoration=ok and "Original item re-equip sent; slot confirmed."
        or ("Restore pending: "..e.Label..". "..tostring(err).." Use Restore gear once alive.")
    self:Log(self.Restoration)
    return ok
end
function Engine:Stop()
    self.Cancel=true
    if self.Busy then self.Status="Stopping and restoring the current item..."end
end
function Engine:Run(context,entries)
    if self.Busy or self.Dirty then return false end
    self.Busy=true;self.Cancel=false;self.Context=context;self.Entries=entries
    self.Cycles=0;self.Pairs=0;self.Calls=0;self.Lines={};self.Started=self.A.Now();self.Restoration=nil
    local ok,err=pcall(function()
        self:Check(false)
        if #entries==0 then error("No worn items found in the selected slots.",0)end
        for _,e in ipairs(entries)do self:Log(e.Group.."/"..e.Slot.." = "..e.Id.." ("..e.Label..")")end
        while not self.Cancel do
            for _,e in ipairs(entries)do
                self:Check(false)
                if self.A.Value(e)~=e.Id then error("Your equipped gear changed. Stop, equip your gear, then Start again.",0)end
                self.Status="Unequipping "..e.Label
                self.Dirty=e
                self:Send(e,0,false)
                self:WaitFor(e,0,false)
                self:Log("Unequipped "..e.Group.."/"..e.Slot)
                self:Pause(false)
                self.Status="Re-equipping "..e.Label
                self:Send(e,e.Id,false)
                self:WaitFor(e,e.Id,false)
                self.Dirty=nil;self.Pairs=self.Pairs+1
                self:Log("Re-equipped "..e.Group.."/"..e.Slot)
                self.A.Wait(0) -- Yield once per completed pair; no second added pause.
            end
            self.Cycles=self.Cycles+1
        end
    end)
    self:Restore()
    self.Status=ok and "Stopped."or tostring(err)
    self:Log(self.Status);self.Busy=false
    return ok
end
function Engine:Report()
    return table.concat({"THUMBSHUB HEALTH GEAR CYCLE BUILD110",
        "Direct original equip calls; slots confirmed from client-visible inventory data. Health immunity unverified.",
        "Status="..self.Status,"Restoration="..tostring(self.Restoration),
        "Items="..tostring(self.Entries and #self.Entries or 0).."; cycles="..self.Cycles.."; item pairs="..self.Pairs.."; calls="..self.Calls,
        "Gap="..self.Gap.." seconds; pending="..tostring(self.Pending),
        "Active data="..tostring(self.Context and self.Context.Path),
        "Last 250 events:",table.concat(self.Lines,"\n")},"\n")
end

    local function path(root,names)
        for name in names:gmatch("[^.]+") do root=root and root:FindFirstChild(name) end
        return root
    end
    local function active()
        local root=path(H.S.ReplicatedStorage,"Player_Service.Data")
        local account=root and root:FindFirstChild(H.Player.Name)
        local selector=account and account:FindFirstChild("slotEquipped")
        local slots=account and account:FindFirstChild("slots")
        return selector and slots and slots:FindFirstChild("Slot"..tostring(selector.Value)),selector
    end
    local function createEngine()
        local a={Now=os.clock,Wait=task.wait}
        function a.Valid(c)
            if not c then return false,"Character data unavailable." end
            local data,selector=active()
            if data~=c.Data or selector~=c.Selector or selector.Value~=c.Slot then return false,"Active character slot changed." end
            if H.Player.Character~=c.Character or not c.Hum.Parent or c.Hum.Health<=0 then return false,"Character changed or died." end
            return true
        end
        function a.Enabled()return not H.State.Unloaded and H.State.HealthGearCycle end
        function a.Value(e)
            if not e.Object.Parent then error("Stats slot disappeared: "..e.Slot,0) end
            return e.Object.Value
        end
        function a.Send(c,e,id)c.Signals.ToServer("AccessoryEquip",e.Slot,id,"Stats")end
        return Engine.new(a)
    end
    function H:HealthGearSnapshot()
        local data,selector=active()
        local char=self.Player.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not data or not selector or not hum or hum.Health<=0 then error("Wait for a living character and inventory.")end
        local inv=data:FindFirstChild("Inventory")
        local items=inv and inv:FindFirstChild("Inventory")
        local stats=inv and path(inv,"Accessories.Stats")
        local signals=self.Modules.SignalEvent
        if not items or not stats then error("Stats equipment data unavailable.")end
        if type(signals)~="table"or type(signals.ToServer)~="function"then error("Original equip action unavailable.")end
        local names={}
        for _,item in ipairs(items:GetChildren())do
            local id=item:FindFirstChild("Id")
            if id and id:IsA("ValueBase")then names[id.Value]=item.Name end
        end
        local entries={}
        for _,key in ipairs({"One","Two","Three","Four","Five"})do
            local slot=stats:FindFirstChild(key)
            if slot and slot:IsA("ValueBase")and type(slot.Value)=="number"and slot.Value>0 then
                if not names[slot.Value]then error("Worn item ID "..slot.Value.." has no inventory record.")end
                entries[#entries+1]={Object=slot,Slot=slot.Name,Group="Stats",Id=slot.Value,Label=names[slot.Value]}
            end
        end
        if #entries==0 then error("Equip an item that increases Health in a Stats slot first.")end
        return {Data=data,Selector=selector,Slot=selector.Value,Character=char,Hum=hum,Signals=signals,Path=data:GetFullName()},entries
    end
    function H:UpdateHealthGearUI()
        local engine=self.Runtime.HealthGearEngine
        local label=self.UI.HealthGearStatus
        if label then
            local status=engine and engine.Status or "Ready • Stats slots only"
            if engine and engine.Dirty and not engine.Busy then status=engine.Restoration or "Use Restore Stats Gear."end
            self:SafeText(label,(engine and engine.Busy and "RUNNING • "or "OFF • ")..status
                ..(engine and (" | "..engine.Pairs.." item cycles")or ""))
        end
    end
    function H:RefreshHealthGearSpeed()
        local ms=math.clamp(tonumber(self.State.HealthGearDelayMs)or 0,0,250)
        self.State.HealthGearDelayMs=ms
        if self.Runtime.HealthGearEngine then self.Runtime.HealthGearEngine.Gap=ms/1000 end
    end
    function H:StopHealthGearCycle()
        self.State.HealthGearCycle=false
        self.Runtime.HealthGearToken=(self.Runtime.HealthGearToken or 0)+1
        local engine=self.Runtime.HealthGearEngine
        if engine then engine:Stop()end
    end
    function H:StartHealthGearCycle()
        local env=(getgenv and getgenv())or _G
        local function fail(message)
            self.State.HealthGearCycle=false;self:SetStatus("Health Gear • "..message)
            self:RefreshToggleButtons();self:UpdateHealthGearUI()
            return false
        end
        if self.State.Unloaded then return fail("Hub unloaded.")end
        local trial=env.THUMBSHUB_HEALTH_CYCLE_TEST
        if trial and (trial.Busy or trial.Preparing)then trial:Stop();return fail("Old loadout test stopping; enable again after restoration.")end
        local standalone=env.THUMBSHUB_DIRECT_GEAR_CYCLE
        if standalone then
            standalone:Stop()
            if standalone.Busy or standalone.Preparing or standalone.Dirty then
                return fail("Stop/restore the standalone gear cycle first, then enable again.")
            end
            if standalone.Close then standalone:Close()end
        end
        local previous=env.THUMBSHUB_HEALTH_GEAR_ENGINE
        if previous and previous~=self.Runtime.HealthGearEngine then
            previous:Stop()
            if previous.Busy then return fail("Previous hub gear cycle is still restoring.")end
            if previous.Dirty then
                self.Runtime.HealthGearEngine=previous
                return fail("Previous hub has an item to restore. Press Restore Stats Gear.")
            end
        end
        local engine=self.Runtime.HealthGearEngine
        if engine and (engine.Busy or self.Runtime.HealthGearScheduled)then return fail("Gear worker is stopping; wait for OFF, then enable.")end
        if engine and engine.Dirty then return fail("Restore Stats Gear before enabling again.")end
        local ok,context,entries=pcall(function()return self:HealthGearSnapshot()end)
        if not ok then return fail(tostring(context))end
        engine=createEngine();self.Runtime.HealthGearEngine=engine;env.THUMBSHUB_HEALTH_GEAR_ENGINE=engine
        self:RefreshHealthGearSpeed()
        self.State.HealthGearCycle=true
        self.Runtime.HealthGearToken=(self.Runtime.HealthGearToken or 0)+1
        local token=self.Runtime.HealthGearToken
        self.Runtime.HealthGearScheduled=true
        task.spawn(function()
            if self.State.Unloaded or not self.State.HealthGearCycle or self.Runtime.HealthGearToken~=token then
                self.Runtime.HealthGearScheduled=false;return
            end
            engine:Run(context,entries)
            self.Runtime.HealthGearScheduled=false
            self.State.HealthGearCycle=false
            if not self.State.Unloaded then
                self:RefreshToggleButtons();self:UpdateHealthGearUI()
                self:SetStatus("Health Gear • "..engine.Status)
            end
        end)
        return true
    end
    function H:RestoreHealthGear()
        local engine=self.Runtime.HealthGearEngine
        if not engine or not engine.Dirty then self:SetStatus("Health Gear • no pending restoration");return end
        if engine.Busy or self.Runtime.HealthGearScheduled then self:SetStatus("Health Gear • wait for the worker to stop");return end
        local c=engine.Context;local data,selector=active()
        local char=self.Player.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
        if data~=c.Data or selector~=c.Selector or selector.Value~=c.Slot or not hum or hum.Health<=0 then
            self:SetStatus("Health Gear • return to the same character slot and wait until alive");return
        end
        c.Character=char;c.Hum=hum;engine.Busy=true
        task.spawn(function()
            local ok,err=pcall(function()engine:Restore()end);engine.Busy=false
            if not self.State.Unloaded then
                self:SetStatus("Health Gear • "..(ok and engine.Restoration or tostring(err)))
                self:UpdateHealthGearUI()
            end
        end)
    end
end
-- END BUILD 110 HEALTH GEAR

-- Optional features are off by default; unsupported server actions are documented in Features.
function H:AccentColor()
    local themes={Orange=Color3.fromRGB(255,132,36),Mint=Color3.fromRGB(43,207,158),Violet=Color3.fromRGB(163,122,255)}
    return themes[self.State.Theme] or themes.Orange
end

function H:StopAllAutomation()
    self:StopHealthGearCycle()
    self:ReleaseBossHold("waiting")
    self.Runtime.BossOwnershipSample = nil
    for _,key in ipairs({"SmartProgression","AutoQuest","AutoLevelFarm","AutoFarmMobs","AutoWorldBoss","AutoM1","KillAura","AutoChests","AutoDrops","AutoChat","AutoHop"}) do self.State[key]=false end
    self:StopAttackHold();self:StopBlocking();self:StopMovement()
    self.Runtime.Retreating=false;self.Runtime.AcceptAttempt=nil
    self:ResetDialogueSession();self:RefreshToggleButtons()
end

function H:FeatureAction(fn)
    local ok,err=pcall(fn)
    if not ok then self:SetStatus("Action failed • "..tostring(err)) end
    return ok
end

function H:Field(parent,label,key,placeholder)
    self:Section(parent,label)
    local box=Instance.new("TextBox")
    box.Size=UDim2.fromOffset(650,34);box.BackgroundColor3=Color3.fromRGB(29,32,40)
    box.TextColor3=Color3.new(1,1,1);box.Font=Enum.Font.Gotham;box.TextSize=12
    box.ClearTextOnFocus=false;box.PlaceholderText=placeholder or label;box.Text=tostring(self.State[key] or "")
    box.Parent=parent;self:Round(box,7)
    self:Connect(box.FocusLost,function() self.State[key]=box.Text end)
    self.UI.Fields=self.UI.Fields or {};self.UI.Fields[key]=box
    return box
end

function H:ConfigName()
    local name=tostring(self.State.ConfigName or "default")
    assert(name:match("^[%w_-]+$") and #name<=40,"Use a profile name containing letters, numbers, - or _")
    return name
end

function H:ConfigPayload()
    local settings={}
    for key,value in pairs(self.State) do
        if key~="Unloaded" and key~="WebhookURL" and key~="LoaderURL" and key~="ChatMessage" and key~="ImportJSON"
            and (type(value)=="boolean" or type(value)=="string" or type(value)=="number") then settings[key]=value end
    end
    return {Version=1,GameId=game.GameId,Settings=settings,Waypoints=self.Runtime.Waypoints or {}}
end

function H:ApplyConfig(data)
    assert(type(data)=="table" and data.Version==1 and data.GameId==game.GameId,"Invalid profile or different game")
    assert(type(data.Settings)=="table","Profile has no settings")
    local ranges={HealthGearDelayMs={0,250},RapidHitIntervalMs={10,200},BelowDepth={1,4},Distance={1,25},Height={-10,25},TweenSpeed={25,500},WalkSpeed={8,100},
        FlySpeed={5,200},JumpPowerValue={20,150},CameraFOV={40,110},CameraZoom={12,1000},UIScale={0.6,1.3},
        RetreatHealthPercent={5,85},ResumeHealthPercent={10,100},ParrySafetyMs={0,200},BossGuardRange={8,60},
        AutoHopSeconds={60,3600},ChatSeconds={15,3600},FPSLimit={30,360},RadarRange={25,500},FreecamSpeed={5,150}}
    self:StopAllAutomation()
    for key,value in pairs(data.Settings) do
        local validEnum = true
        if key=="MenuKey" then validEnum=({RightShift=true,LeftAlt=true,F4=true,F6=true,Home=true,Insert=true})[value]==true end
        if key=="PanicKey" then validEnum=({F8=true,F9=true,F10=true,End=true})[value]==true end
        if key~="Unloaded" and key~="WebhookURL" and key~="LoaderURL" and key~="ImportJSON"
            and validEnum and type(value)==type(self.State[key]) then
            if type(value)=="number" then
                if value==value and math.abs(value)<100000 then
                    local range=ranges[key];self.State[key]=range and math.clamp(value,range[1],range[2]) or value
                end
            elseif type(value)~="string" or #value<2048 then self.State[key]=value end
        end
    end
    -- Import restores preferences, never starts movement, messaging, or outbound requests.
    self:StopAllAutomation()
    for _,key in ipairs({"Fly","Freecam","AutoExecute","WebhookStatus","ClickToTeleport","ClickToWalk","AimAssist","Spectating"}) do self.State[key]=false end
    self.Runtime.Waypoints={}
    for name,point in pairs(type(data.Waypoints)=="table" and data.Waypoints or {}) do
        if type(name)=="string" and #name<64 and type(point)=="table" then
            local valid=true
            for i=1,3 do valid=valid and type(point[i])=="number" and point[i]==point[i] and math.abs(point[i])<1000000 end
            if valid then self.Runtime.Waypoints[name]={point[1],point[2],point[3]} end
        end
    end
    for _,refresh in pairs(self.UI.DropdownRefresh or {}) do refresh() end
    for key,box in pairs(self.UI.Fields or {}) do box.Text=tostring(self.State[key] or "") end
    for _,record in pairs(self.UI.ToggleButtons) do record.LastOn=nil end
    self:RefreshToggleButtons();self:SetMenuVisible(self.State.Visible)
    self:SetStatus("Profile loaded • automation paused; choose Start when ready")
end

function H:SaveConfig()
    assert(type(writefile)=="function" and type(makefolder)=="function","File APIs unavailable")
    pcall(makefolder,"ThumbsHubProfiles")
    writefile("ThumbsHubProfiles/"..self:ConfigName()..".json",self.S.HttpService:JSONEncode(self:ConfigPayload()))
    self:SetStatus("Saved profile • "..self:ConfigName())
end

function H:ProfileOptions()
    local out={{Value="",Label="Choose a saved profile"}}
    if type(listfiles)=="function" then
        local ok,files=pcall(listfiles,"ThumbsHubProfiles")
        if ok then for _,path in ipairs(files) do
            local name=tostring(path):match("([^/\\]+)%.json$")
            if name and name:match("^[%w_-]+$") then table.insert(out,{Value=name,Label=name}) end
        end end
    end
    return out
end

function H:RefreshServers()
    self.Runtime.Servers={}
    local cursor=""
    for page=1,3 do
        local url="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        if cursor~="" then url=url.."&cursor="..self.S.HttpService:UrlEncode(cursor) end
        local data=self.S.HttpService:JSONDecode((game :: any):HttpGet(url))
        for _,server in ipairs(data.data or {}) do
            if server.id~=game.JobId and tonumber(server.playing) and tonumber(server.maxPlayers)
                and server.playing<server.maxPlayers then
                table.insert(self.Runtime.Servers,{Value=server.id,Label=server.playing.."/"..server.maxPlayers.." players • "..server.id})
            end
        end
        cursor=data.nextPageCursor or "";if cursor=="" then break end
    end
    self:SetStatus("Found "..#self.Runtime.Servers.." joinable servers")
end

function H:HopServer()
    self:RefreshServers()
    local server=self.Runtime.Servers and self.Runtime.Servers[1]
    assert(server,"No other joinable server returned")
    self:JoinJob(server.Value)
end

function H:QueueLoader()
    assert(self.State.AutoExecute,"Enable Auto Execute first")
    local url=tostring(self.State.LoaderURL or "")
    assert(url:match("^https://"),"Enter your own HTTPS raw loader URL")
    local queue=queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
    assert(type(queue)=="function","Teleport queue unavailable")
    local source=string.format("if not game:IsLoaded() then game.Loaded:Wait() end\nloadstring((game :: any):HttpGet(%q))()",url)
    if self.Runtime.QueuedLoaderURL~=url then queue(source);self.Runtime.QueuedLoaderURL=url end
    self:SetStatus("Loader queued for next teleport")
end

function H:WebhookSend()
    local url=tostring(self.State.WebhookURL or "")
    assert(url:match("^https://discord%.com/api/webhooks/[%w/_.%-]+$")
        or url:match("^https://discordapp%.com/api/webhooks/[%w/_.%-]+$"),"Enter a Discord webhook URL")
    local requestFn=request or http_request or (syn and syn.request)
    assert(type(requestFn)=="function","HTTP request capability unavailable")
    local content=string.format("ThumbsHub • Level %s • %s",tostring(self:GetPlayerLevel() or "?"),tostring(self.Runtime.LastStatus))
    local response=requestFn({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},
        Body=self.S.HttpService:JSONEncode({content=content,allowed_mentions={parse={}}})})
    local code=response and tonumber(response.StatusCode)
    assert(code and code>=200 and code<300,"Webhook request failed")
end

function H:ApplyVisualOptions(generation)
    if generation ~= self.Runtime.VisualGeneration then return end
    local originals=self.Runtime.VisualOriginal
    local function set(obj,key,value)
        originals[obj]=originals[obj] or {}
        if originals[obj][key]==nil then originals[obj][key]=obj[key] end
        obj[key]=value
    end
    for obj,properties in pairs(originals) do
        if obj.Parent then for key,value in pairs(properties) do pcall(function() obj[key]=value end) end end
    end
    table.clear(originals)
    local lighting=self.S.Lighting
    if self.State.Fullbright then
        set(lighting,"Brightness",2);set(lighting,"Ambient",Color3.fromRGB(200,200,200));set(lighting,"OutdoorAmbient",Color3.fromRGB(200,200,200))
    end
    if self.State.NoFog then set(lighting,"FogStart",0);set(lighting,"FogEnd",1000000) end
    if self.State.PerformanceMode or self.State.DisableShadows then set(lighting,"GlobalShadows",false) end
    if not (self.State.PerformanceMode or self.State.DisableEffects or self.State.NoFog or self.State.XRay) then return end
    for index,obj in ipairs(game:GetDescendants()) do
        if generation~=self.Runtime.VisualGeneration or self.State.Unloaded then return end
        if index%250==0 then
            task.wait()
            if generation~=self.Runtime.VisualGeneration or self.State.Unloaded then return end
        end
        pcall(function()
            if (self.State.PerformanceMode or self.State.DisableEffects) and
                (obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("PostEffect")) then set(obj,"Enabled",false) end
            if self.State.NoFog and obj:IsA("Atmosphere") then set(obj,"Density",0);set(obj,"Haze",0) end
            if self.State.XRay and obj:IsA("BasePart") and obj:IsDescendantOf(workspace)
                and not obj:IsDescendantOf(self:Character() or self.PlayerGui) then set(obj,"LocalTransparencyModifier",0.65) end
        end)
    end
end

function H:PlayerOptions()
    local out={{Value="",Label="Choose a player"}}
    for _,plr in ipairs(self.S.Players:GetPlayers()) do if plr~=self.Player then
        table.insert(out,{Value=tostring(plr.UserId),Label=plr.DisplayName.." (@"..plr.Name..")"})
    end end
    return out
end

function H:ExtrasFrame(dt)
    local r,st=self.Runtime,self.State
    r.FrameCount=(r.FrameCount or 0)+1
    r.FrameSeconds=(r.FrameSeconds or 0)+dt
    if r.FrameSeconds>=0.5 then r.FPS=math.floor(r.FrameCount/r.FrameSeconds+0.5);r.FrameCount=0;r.FrameSeconds=0 end
    local camera=workspace.CurrentCamera
    local hum=self:Humanoid()
    if hum and hum~=r.JumpHumanoid then
        r.JumpHumanoid=hum;r.OriginalJump={UseJumpPower=hum.UseJumpPower,JumpPower=hum.JumpPower,JumpHeight=hum.JumpHeight}
    end
    if hum and r.OriginalJump then
        if st.JumpPowerEnabled then hum.UseJumpPower=true;hum.JumpPower=st.JumpPowerValue
        elseif r.JumpWasEnabled then hum.UseJumpPower=r.OriginalJump.UseJumpPower;hum.JumpPower=r.OriginalJump.JumpPower;hum.JumpHeight=r.OriginalJump.JumpHeight end
        r.JumpWasEnabled=st.JumpPowerEnabled
    end
    if not camera then return end
    if r.FeatureCamera~=camera then
        r.FeatureCamera=camera;r.CameraDefaults={FOV=camera.FieldOfView,Type=camera.CameraType,Subject=camera.CameraSubject}
    end
    if st.CameraOptions then camera.FieldOfView=st.CameraFOV;self.Player.CameraMaxZoomDistance=st.CameraZoom
    elseif r.CameraWasEnabled then camera.FieldOfView=r.CameraDefaults.FOV;self.Player.CameraMaxZoomDistance=r.OriginalZoom end
    r.CameraWasEnabled=st.CameraOptions
    if st.Freecam then
        if not r.FreecamPosition then r.FreecamPosition=camera.CFrame.Position;r.FreecamRotation=camera.CFrame.Rotation end
        camera.CameraType=Enum.CameraType.Scriptable
        local input=self.S.UserInputService
        if not input:GetFocusedTextBox() then
            local delta=input:GetMouseDelta()
            if input:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                r.FreecamRotation=CFrame.Angles(0,-delta.X*0.003,0)*r.FreecamRotation*CFrame.Angles(-delta.Y*0.003,0,0)
            end
            local move=Vector3.zero
            for key,direction in pairs({W=Vector3.new(0,0,-1),S=Vector3.new(0,0,1),A=Vector3.new(-1,0,0),D=Vector3.new(1,0,0),E=Vector3.new(0,1,0),Q=Vector3.new(0,-1,0)}) do
                if input:IsKeyDown(Enum.KeyCode[key]) then move=move+direction end
            end
            if move.Magnitude>0 then r.FreecamPosition=r.FreecamPosition+r.FreecamRotation:VectorToWorldSpace(move.Unit)*st.FreecamSpeed*math.min(dt,0.1) end
        end
        camera.CFrame=CFrame.new(r.FreecamPosition)*r.FreecamRotation
    elseif r.FreecamPosition then
        r.FreecamPosition=nil;camera.CameraType=r.CameraDefaults.Type;camera.CameraSubject=self:Humanoid() or r.CameraDefaults.Subject
    elseif st.Spectating then
        local plr=self.S.Players:GetPlayerByUserId(tonumber(st.SpectatePlayer) or 0)
        local targetHum=plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        if targetHum then camera.CameraSubject=targetHum;r.WasSpectating=true end
    elseif r.WasSpectating then camera.CameraSubject=self:Humanoid() or r.CameraDefaults.Subject;r.WasSpectating=false end
    if st.AimAssist and not st.Freecam and self.S.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target=r.AttackTarget or self.Data.CurrentFarmTarget
        if target and target:GetAttribute("IsMob")==true then
            local part=target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
            if part then camera.CFrame=camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position,part.Position),1-math.exp(-12*dt)) end
        end
    end
    if self.UI.Cursor then
        self.UI.Cursor.Visible=st.CustomCursor
        if st.CustomCursor then
            local mouse=self.S.UserInputService:GetMouseLocation()
            self.UI.Cursor.Position=UDim2.fromOffset(mouse.X,mouse.Y)
            self.S.UserInputService.MouseIconEnabled=false
        elseif r.CursorWasEnabled then self.S.UserInputService.MouseIconEnabled=r.OriginalMouseIcon end
        r.CursorWasEnabled=st.CustomCursor
    end
end

function H:ExtrasTick()
    if os.clock()-(self.Runtime.LastSlotRefresh or 0)>=1 then
        self.Runtime.LastSlotRefresh=os.clock()
        self:RefreshSlotPanel()
        self:PollSlotEvents()
    end
    local r,st=self.Runtime,self.State
    if st.MiniRadar and self.UI.Radar then
        self.UI.Radar.Visible=true
        for _,dot in ipairs(r.RadarDots) do dot.Visible=false end
        local root=self:Root();local count=0
        if root then for _,mob in ipairs(self.Data.Mobs) do
            local part=mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
            local hum=self:TargetHumanoid(mob)
            if part and hum and hum.Health>0 then
                local offset=part.Position-root.Position
                if offset.Magnitude<=st.RadarRange and count<32 then
                    count=count+1;local dot=r.RadarDots[count]
                    dot.Position=UDim2.fromOffset(90+offset.X/st.RadarRange*80,90+offset.Z/st.RadarRange*80)
                    dot.Visible=true
                end
            end
        end end
    elseif self.UI.Radar then self.UI.Radar.Visible=false end
    if self.UI.PerfHUD then
        self.UI.PerfHUD.Visible=st.PerformanceHUD
        self.UI.PerfHUD.Text=string.format("%s   %d FPS • %d ms • %d mobs",st.StreamerMode and "Player" or self.Player.DisplayName,r.FPS or 0,math.floor(self:GetPingMs()),#self.Data.Mobs)
    end
    if st.KillAura and not st.AutoQuest and not st.AutoWorldBoss and not st.AutoFarmMobs then
        local target,distance=self:NearestMob("Any")
        if target and distance and distance<=6 then
            if not st.SafeCombat or self:HealthPercent()>st.RetreatHealthPercent then self:PulseAttack(target)
            else self:GuardStep(target) end
        else self:StopAttackHold() end
    end
    local visualKey=table.concat({tostring(st.Fullbright),tostring(st.NoFog),tostring(st.PerformanceMode),tostring(st.DisableEffects),tostring(st.DisableShadows),tostring(st.XRay)},":")
    if visualKey~=r.VisualKey then
        r.VisualKey=visualKey;r.VisualGeneration=(r.VisualGeneration or 0)+1
        local generation=r.VisualGeneration
        task.spawn(function() self:FeatureAction(function() self:ApplyVisualOptions(generation) end) end)
    end
    if st.Theme~=r.LastTheme then
        local previous=r.LastAccent or Color3.fromRGB(255,132,36);local accent=self:AccentColor()
        for _,obj in ipairs(self.UI.Gui:GetDescendants()) do
            if obj:IsA("GuiObject") and obj.BackgroundColor3==previous then obj.BackgroundColor3=accent end
            if obj:IsA("UIStroke") and obj.Color==previous then obj.Color=accent end
        end
        r.LastTheme=st.Theme;r.LastAccent=accent
    end
    if st.UIScale~=r.LastUIScale then r.LastUIScale=st.UIScale;if self.UI.FitWindow then self.UI.FitWindow() end end
    if st.MuzanTracker then
        if os.clock()-(r.LastMuzanScan or 0)>3 then
            r.LastMuzanScan=os.clock()
            local model=self:FindNPC("Muzan")
            r.Muzan=model and string.lower(model.Name)=="muzan" and model or nil
        end
        local model=r.Muzan
        local root=model and model.Parent and self:NpcAnchorPart(model)
        r.MuzanBillboard.Adornee=root;r.MuzanBillboard.Enabled=root~=nil
        r.MuzanHighlight.Adornee=model;r.MuzanHighlight.Enabled=root~=nil
        if root and self:Root() then r.MuzanLabel.Text="MUZAN • "..math.floor((root.Position-self:Root().Position).Magnitude).." studs" end
    else
        r.MuzanBillboard.Enabled=false;r.MuzanHighlight.Enabled=false
    end
    if st.BossSpawnNotifications then
        for code,rec in pairs(self.Data.Bosses) do
            local alive=self:BossAlive(rec)
            if alive and r.BossSeen[code]==false then self:Notify("Boss spawned • "..code) end
            r.BossSeen[code]=alive
        end
        for code in pairs(r.BossSeen) do if not self.Data.Bosses[code] then r.BossSeen[code]=false end end
    end
    if os.clock()-(r.LastPositionRecord or 0)>=1 then
        r.LastPositionRecord=os.clock();local root=self:Root()
        if root then table.insert(r.PositionHistory,root.CFrame);if #r.PositionHistory>10 then table.remove(r.PositionHistory,1) end end
    end
    if st.AutoHop and os.clock()-(r.LastAutoHop or os.clock())>=st.AutoHopSeconds then
        r.LastAutoHop=os.clock();task.spawn(function() self:FeatureAction(function() self:HopServer() end) end)
    end
    if not st.AutoHop then r.LastAutoHop=os.clock() end
    if st.AutoChat and os.clock()-(r.LastAutoChat or 0)>=st.ChatSeconds then
        r.LastAutoChat=os.clock()
        self:FeatureAction(function()
            assert(st.ChatMessage~="","Enter an Auto Chat message")
            local channels=game:GetService("TextChatService"):FindFirstChild("TextChannels")
            local channel=channels and channels:FindFirstChild("RBXGeneral")
            assert(channel,"General text channel not available")
            channel:SendAsync(st.ChatMessage)
        end)
    end
    if st.WebhookStatus and os.clock()-(r.LastWebhook or 0)>60 then
        r.LastWebhook=os.clock();task.spawn(function() self:FeatureAction(function() self:WebhookSend() end) end)
    end
end

function H:SlotSnapshot(folderName, limit)
    local data=self:GetSlotData()
    local root=data and data:FindFirstChild(folderName)
    local values={}
    if not root then return values,nil end
    local count=0
    local function visit(obj,path,depth)
        if count>=limit or depth>5 then return end
        if obj:IsA("ValueBase") then
            local value=obj.Value
            if type(value)=="number" or type(value)=="boolean" or type(value)=="string" then
                values[path]=tostring(value):sub(1,160);count=count+1
            end
        end
        local children=obj:GetChildren()
        table.sort(children,function(a,b) return a.Name<b.Name end)
        for _,child in ipairs(children) do
            if count>=limit then break end
            visit(child,path.."/"..child.Name,depth+1)
        end
    end
    visit(root,folderName,0)
    return values,root
end

function H:RefreshSlotPanel()
    local lines={"LIVE SLOT DATA (read only)"}
    for _,name in ipairs({"SkillPoints","SlotLevelStats","SkillPointsSpent","Progression"}) do
        local values,root=self:SlotSnapshot(name,24)
        local keys={};for key in pairs(values) do table.insert(keys,key) end;table.sort(keys)
        if not root then table.insert(lines,name..": unavailable")
        elseif #keys==0 then table.insert(lines,name..": no replicated values") end
        for _,key in ipairs(keys) do table.insert(lines,key.." = "..values[key]) end
    end
    if self.UI.LiveSlotPanel then self.UI.LiveSlotPanel.Text=table.concat(lines,"\n") end
end

function H:PollSlotEvents()
    local r=self.Runtime
    if not self.State.SlotEventAlerts then r.EventSnapshot=nil;r.EventRoot=nil;return end
    local values,root=self:SlotSnapshot("WorldEvents",128)
    if not root then r.EventSnapshot=nil;r.EventRoot=nil;return end
    if r.EventRoot==root and r.EventSnapshot then
        local changes={}
        for key,value in pairs(values) do
            if r.EventSnapshot[key]~=value then table.insert(changes,key.." = "..value) end
        end
        for key in pairs(r.EventSnapshot) do
            if values[key]==nil then table.insert(changes,key.." removed") end
        end
        table.sort(changes)
        if #changes>0 then
            local shown={};for i=1,math.min(4,#changes) do shown[i]=changes[i] end
            if #changes>4 then table.insert(shown,"+"..(#changes-4).." more changes") end
            self:Notify("Slot event data changed • "..table.concat(shown,"; "))
        end
    end
    r.EventRoot=root;r.EventSnapshot=values
end

function H:CopyRouteDiagnostics()
    local lines={"THUMBSHUB FOCUSED ACTION SCAN", "PlaceId="..game.PlaceId,
        "Read-only snapshot; open the native stat/action panel before copying."}
    for _,name in ipairs({"SkillPoints","SlotLevelStats","SkillPointsSpent","Progression","WorldEvents"}) do
        local values,root=self:SlotSnapshot(name,80)
        table.insert(lines,"["..name.."] "..(root and self:Path(root) or "unavailable"))
        local keys={};for key in pairs(values) do table.insert(keys,key) end;table.sort(keys)
        for _,key in ipairs(keys) do table.insert(lines,key.." = "..values[key]) end
        if root then for _,child in ipairs(root:GetChildren()) do
            table.insert(lines,"child: "..child.Name.." ["..child.ClassName.."]")
        end end
    end
    table.insert(lines,"[Visible native action buttons]")
    local count=0
    for _,obj in ipairs(self.PlayerGui:GetDescendants()) do
        if count<100 and obj:IsA("GuiButton") and not self:IsOwnGuiObject(obj) and self:IsActuallyVisible(obj) then
            local label=obj:IsA("TextButton") and obj.Text or ""
            local textChild=obj:FindFirstChildWhichIsA("TextLabel",true)
            if label=="" and textChild then label=textChild.Text end
            table.insert(lines,self:Path(obj).." | "..tostring(label):sub(1,140));count=count+1
        end
    end
    table.insert(lines,"[Relevant module paths; not executed]")
    count=0
    for _,obj in ipairs(self.S.ReplicatedStorage:GetDescendants()) do
        if count<100 and obj:IsA("ModuleScript") then
            local name=string.lower(obj.Name)
            if name:find("stat",1,true) or name:find("upgrade",1,true) or name:find("dungeon",1,true)
                or name:find("cache",1,true) or name:find("soul",1,true) or name:find("schematic",1,true)
                or name:find("restock",1,true) then
                table.insert(lines,self:Path(obj));count=count+1
            end
        end
    end
    table.insert(lines,"[Dialogue tags]")
    for i,obj in ipairs(self.S.CollectionService:GetTagged("Dialogue")) do
        if i>30 then break end
        table.insert(lines,self:Path(obj).." ["..obj.ClassName.."]")
    end
    assert(type(setclipboard)=="function","Clipboard unavailable")
    setclipboard(table.concat(lines,"\n"));self:SetStatus("Focused scan copied • paste it into the conversation")
end

function H:BuildExtraUI(pages)
    local function toggle(p,label,key) self:Toggle(p,label,key) end
    local function button(p,label,fn) self:Button(p,label,function() self:FeatureAction(fn) end,310) end
    local function options(values) local out={};for _,value in ipairs(values) do table.insert(out,{Value=value,Label=tostring(value)}) end;return out end
    local p=pages.Player
    self:Section(p,"Movement and camera")
    toggle(p,"Jump Power","JumpPowerEnabled");self:NumberAdjust(p,"Jump Power","JumpPowerValue",5,20,150)
    toggle(p,"Always Run (speed override)","AlwaysRun")
    toggle(p,"Ctrl + Click to Walk","ClickToWalk");toggle(p,"Alt + Click to Teleport","ClickToTeleport")
    button(p,"Rewind Position (about 5 seconds)",function()
        local history=self.Runtime.PositionHistory;local cf=history[math.max(1,#history-5)]
        assert(cf and self:Root(),"No position history yet");self:StopAllAutomation();self:Root().CFrame=cf
    end)
    button(p,"Quick Reset Character",function() self:StopAllAutomation();local hum=self:Humanoid();if hum then hum.Health=0 end end)
    toggle(p,"Camera FOV / Zoom","CameraOptions");self:NumberAdjust(p,"FOV","CameraFOV",5,40,110)
    self:NumberAdjust(p,"Max Zoom","CameraZoom",25,25,1000)
    toggle(p,"Freecam (WASD + Q/E; hold RMB)","Freecam")
    self:NumberAdjust(p,"Freecam Speed","FreecamSpeed",5,5,150)
    self:Dropdown(p,"Spectate Player",function() return self:PlayerOptions() end,"SpectatePlayer")
    toggle(p,"Spectate","Spectating")
    toggle(p,"NPC Camera Aim (hold RMB)","AimAssist")
    p=pages.Combat
    toggle(p,"Nearby NPC M1 Aura (6 studs)","KillAura")
    p=pages.Visuals
    for _,row in ipairs({{"Fullbright","Fullbright"},{"No Fog","NoFog"},{"X-Ray (local transparency)","XRay"},{"Performance Mode","PerformanceMode"},{"Disable Effects","DisableEffects"},{"Disable Shadows","DisableShadows"},{"Mini Radar (north-up)","MiniRadar"},{"Performance HUD","PerformanceHUD"},{"Streamer Label (hub only)","StreamerMode"},{"Custom Crosshair Cursor","CustomCursor"}}) do toggle(p,row[1],row[2]) end
    self:NumberAdjust(p,"Radar Range","RadarRange",25,25,500)
    self:Dropdown(p,"Theme",function() return options({"Orange","Mint","Violet"}) end,"Theme")
    self:NumberAdjust(p,"UI Scale","UIScale",0.1,0.6,1.3)
    p=pages.Servers
    button(p,"Refresh Public Servers",function() self:RefreshServers() end)
    self:Dropdown(p,"Server",function() return self.Runtime.Servers or {} end,"SelectedServer")
    button(p,"Join Selected Server",function() assert(self.State.SelectedServer~="","Choose a server");self:JoinJob(self.State.SelectedServer) end)
    button(p,"Server Hop",function() self:HopServer() end)
    toggle(p,"Timed Auto Hop","AutoHop");self:NumberAdjust(p,"Hop Seconds","AutoHopSeconds",60,60,3600)
    toggle(p,"Boss Spawn Notifications","BossSpawnNotifications")
    toggle(p,"Muzan Tracker (loaded NPC only)","MuzanTracker")
    p=pages.Profiles
    self:Field(p,"Profile Name","ConfigName","default")
    button(p,"Save Profile",function() self:SaveConfig() end)
    self:Dropdown(p,"Saved Profiles",function() return self:ProfileOptions() end,"SelectedProfile",function(value)
        if value~="" then
            self.State.ConfigName=value
            if self.UI.Fields and self.UI.Fields.ConfigName then self.UI.Fields.ConfigName.Text=value end
        end
    end)
    button(p,"Load Selected Profile",function()
        assert(type(readfile)=="function","File API unavailable")
        self:ApplyConfig(self.S.HttpService:JSONDecode(readfile("ThumbsHubProfiles/"..self:ConfigName()..".json")))
    end)
    button(p,"Copy Profile to Share",function() assert(type(setclipboard)=="function","Clipboard unavailable");setclipboard(self.S.HttpService:JSONEncode(self:ConfigPayload()));self:SetStatus("Profile copied; webhook and loader URLs excluded") end)
    self:Field(p,"Import Profile JSON","ImportJSON","Paste shared profile JSON")
    button(p,"Import Pasted Profile",function() self:ApplyConfig(self.S.HttpService:JSONDecode(self.State.ImportJSON)) end)
    self:Dropdown(p,"Menu Key",function() return options({"RightShift","LeftAlt","F4","F6","Home","Insert"}) end,"MenuKey")
    self:Dropdown(p,"Stop All Key",function() return options({"F8","F9","F10","End"}) end,"PanicKey")
    self:Field(p,"Your HTTPS Raw Loader URL","LoaderURL","Required for Auto Execute")
    toggle(p,"Auto Execute on Teleport","AutoExecute")
    button(p,"Queue Loader Now",function() self:QueueLoader() end)
    button(p,"Hard Reset Hub Settings",function()
        self:StopAllAutomation();self:CleanupExtras()
        for key,value in pairs(self.Runtime.ExtraDefaults) do self.State[key]=value end
        for key,value in pairs(self.Runtime.BaseDefaults) do self.State[key]=value end
        self.State.Unloaded=false;self:SetMenuVisible(true)
        for _,rec in pairs(self.UI.ToggleButtons) do rec.LastOn=nil end;self:RefreshToggleButtons()
        for _,refresh in pairs(self.UI.DropdownRefresh or {}) do refresh() end
        self:SetStatus("Hub defaults restored • automation stopped")
    end)
    p=pages.Tools
    button(p,"Open Roblox Console",function() game:GetService("StarterGui"):SetCore("DevConsoleVisible",true) end)
    self:NumberAdjust(p,"FPS Cap","FPSLimit",10,30,360)
    button(p,"Apply FPS Cap",function() assert(type(setfpscap)=="function","FPS cap capability unavailable");setfpscap(self.State.FPSLimit) end)
    self:Field(p,"Waypoint Name","WaypointName","home")
    button(p,"Save Current Waypoint",function()
        local root=self:Root();assert(root,"Character unavailable")
        local v=root.Position;self.Runtime.Waypoints[self.State.WaypointName]={v.X,v.Y,v.Z};self:SetStatus("Waypoint saved")
    end)
    self:Dropdown(p,"Waypoint",function()
        local out={};for name in pairs(self.Runtime.Waypoints) do table.insert(out,{Value=name,Label=name}) end
        table.sort(out,function(a,b) return a.Label<b.Label end);return out
    end,"SelectedWaypoint")
    button(p,"Travel to Waypoint",function()
        local v=self.Runtime.Waypoints[self.State.SelectedWaypoint];assert(v,"Choose a waypoint")
        self:StopAllAutomation();self:TweenExact(Vector3.new(v[1],v[2],v[3]))
    end)
    button(p,"Interact with Nearest Prompt",function()
        local root=self:Root();assert(root,"Character unavailable")
        local best,dist
        for _,obj in ipairs(workspace:GetDescendants()) do if obj:IsA("ProximityPrompt") and obj.Enabled then
            local par=obj.Parent;local pos=par:IsA("Attachment") and par.WorldPosition or par:IsA("BasePart") and par.Position
            if pos then local d=(pos-root.Position).Magnitude
                if d<=obj.MaxActivationDistance and (not dist or d<dist) then best,dist=obj,d end
            end
        end end
        assert(best,"No enabled prompt within interaction range");self:InteractPrompt(best)
    end)
    self:Field(p,"Music Asset ID","MusicId","Numeric audio ID")
    button(p,"Play Music",function()
        assert(tostring(self.State.MusicId):match("^%d+$"),"Enter a numeric audio ID")
        self.Runtime.Music.SoundId="rbxassetid://"..self.State.MusicId;self.Runtime.Music:Play()
    end)
    button(p,"Stop Music",function() self.Runtime.Music:Stop() end)
    self:Field(p,"Emote Name","EmoteName","wave")
    button(p,"Play Emote",function() local hum=self:Humanoid();assert(hum,"Character unavailable");assert(hum:PlayEmote(self.State.EmoteName),"Emote unavailable on this character") end)
    self:Field(p,"Auto Chat Message","ChatMessage","Message sent only when Auto Chat is enabled")
    self:NumberAdjust(p,"Chat Seconds","ChatSeconds",15,15,3600);toggle(p,"Auto Chat","AutoChat")
    self:Field(p,"Discord Webhook URL","WebhookURL","Excluded from exported profiles")
    button(p,"Send Status Once",function() self:WebhookSend() end)
    toggle(p,"Webhook Status Every 60s","WebhookStatus")

    -- One-time community welcome shared with the other ThumbsHub scripts.
    self:ShowCommunityWelcome()
end

function H:InitExtras()
    local r=self.Runtime
    r.VisualOriginal=setmetatable({}, {__mode="k"});r.BossSeen={};r.RadarDots={};r.PositionHistory={};r.Waypoints={}
    r.LastAutoHop=os.clock()
    r.OriginalZoom=self.Player.CameraMaxZoomDistance
    r.OriginalMouseIcon=self.S.UserInputService.MouseIconEnabled
    if type(getfpscap)=="function" then pcall(function() r.OriginalFPSCap=getfpscap() end) end
    r.MuzanBillboard=Instance.new("BillboardGui")
    r.MuzanBillboard.Size=UDim2.fromOffset(180,36);r.MuzanBillboard.AlwaysOnTop=true
    r.MuzanBillboard.StudsOffset=Vector3.new(0,4,0);r.MuzanBillboard.Enabled=false;r.MuzanBillboard.Parent=self.UI.Gui
    r.MuzanLabel=Instance.new("TextLabel");r.MuzanLabel.Size=UDim2.fromScale(1,1)
    r.MuzanLabel.BackgroundTransparency=1;r.MuzanLabel.TextColor3=Color3.fromRGB(255,110,150)
    r.MuzanLabel.TextSize=14;r.MuzanLabel.Parent=r.MuzanBillboard
    r.MuzanHighlight=Instance.new("Highlight");r.MuzanHighlight.Enabled=false
    r.MuzanHighlight.FillTransparency=0.65;r.MuzanHighlight.FillColor=Color3.fromRGB(255,110,150)
    r.MuzanHighlight.Parent=workspace
    r.Music=Instance.new("Sound");r.Music.Name="ThumbsHubMusic";r.Music.Volume=0.3;r.Music.Parent=game:GetService("SoundService")
    local radar=Instance.new("Frame");radar.Size=UDim2.fromOffset(180,180);radar.Position=UDim2.new(1,-196,0,60)
    radar.BackgroundColor3=Color3.fromRGB(16,19,26);radar.BackgroundTransparency=0.2;radar.Visible=false
    radar.Parent=self.UI.Gui;self:Round(radar,12);self.UI.Radar=radar
    for i=1,32 do local dot=Instance.new("Frame");dot.Size=UDim2.fromOffset(4,4);dot.AnchorPoint=Vector2.new(0.5,0.5)
        dot.BackgroundColor3=Color3.fromRGB(255,132,36);dot.BorderSizePixel=0;dot.Visible=false;dot.Parent=radar;r.RadarDots[i]=dot end
    local center=Instance.new("TextLabel");center.Size=UDim2.fromOffset(20,20);center.Position=UDim2.fromOffset(80,80)
    center.BackgroundTransparency=1;center.Text="+";center.TextColor3=Color3.new(1,1,1);center.Parent=radar
    local hud=Instance.new("TextLabel");hud.Size=UDim2.fromOffset(360,28);hud.Position=UDim2.fromOffset(16,52)
    hud.BackgroundColor3=Color3.fromRGB(16,19,26);hud.TextColor3=Color3.new(1,1,1);hud.TextSize=12;hud.Visible=false;hud.Parent=self.UI.Gui;self.UI.PerfHUD=hud
    local cursor=Instance.new("TextLabel");cursor.Size=UDim2.fromOffset(20,20);cursor.AnchorPoint=Vector2.new(0.5,0.5)
    cursor.BackgroundTransparency=1;cursor.Text="+";cursor.TextColor3=Color3.new(1,1,1);cursor.TextSize=20;cursor.ZIndex=100;cursor.Visible=false;cursor.Parent=self.UI.Gui;self.UI.Cursor=cursor
    self:Connect(
        self.S.RunService.RenderStepped,
        function(dt)
            if self.State.Unloaded then
                return
            end

            self:SmoothOrbitFrame(
                dt
            )

            self:ExtrasFrame(
                dt
            )
        end
    )
    self:Connect(self.S.UserInputService.InputBegan,function(input,processed)
        if processed or self.S.UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode==Enum.KeyCode[self.State.PanicKey] then self:StopAllAutomation();self:SetStatus("Automation stopped by hotkey") end
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            local hit=self.Player:GetMouse().Hit;local root=self:Root();local hum=self:Humanoid()
            if self.State.ClickToTeleport and self.S.UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) and root then
                self:StopAllAutomation();root.CFrame=CFrame.new(hit.Position+Vector3.new(0,3,0))
            elseif self.State.ClickToWalk and self.S.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and hum then
                self:StopAllAutomation();hum:MoveTo(hit.Position)
            end
        end
    end)
    self:Connect(self.Player.OnTeleport,function(state)
        if state==Enum.TeleportState.Started and self.State.AutoExecute then self:FeatureAction(function() self:QueueLoader() end) end
    end)
    task.spawn(function()
        while not self.State.Unloaded and self.UI.Gui and self.UI.Gui.Parent do
            self:FeatureAction(function() self:ExtrasTick() end);task.wait(0.25)
        end
    end)
end

function H:CleanupExtras()
    local r=self.Runtime
    r.VisualGeneration=(r.VisualGeneration or 0)+1
    for obj,properties in pairs(r.VisualOriginal or {}) do if obj.Parent then for key,value in pairs(properties) do pcall(function() obj[key]=value end) end end end
    if r.VisualOriginal then table.clear(r.VisualOriginal) end
    for part,value in pairs(r.CollisionOriginal or {}) do if part.Parent then part.CanCollide=value end end
    if r.CollisionOriginal then table.clear(r.CollisionOriginal) end
    if r.MuzanHighlight then
        r.MuzanHighlight.Enabled=false
        if self.State.Unloaded then r.MuzanHighlight:Destroy() end
    end
    if r.Music then r.Music:Stop();if self.State.Unloaded then r.Music:Destroy() end end
    self.S.UserInputService.MouseIconEnabled=r.OriginalMouseIcon~=false
    if r.OriginalZoom then self.Player.CameraMaxZoomDistance=r.OriginalZoom end
    if r.OriginalFPSCap and type(setfpscap)=="function" then pcall(setfpscap,r.OriginalFPSCap) end
    local camera=workspace.CurrentCamera
    if camera and r.CameraDefaults then
        camera.FieldOfView=r.CameraDefaults.FOV;camera.CameraType=r.CameraDefaults.Type
        camera.CameraSubject=self:Humanoid() or r.CameraDefaults.Subject
    end
    r.FreecamPosition=nil;r.WasSpectating=false;r.VisualKey=nil
    local hum=self:Humanoid()
    if hum and r.OriginalJump then hum.UseJumpPower=r.OriginalJump.UseJumpPower;hum.JumpPower=r.OriginalJump.JumpPower;hum.JumpHeight=r.OriginalJump.JumpHeight end
end


H.Runtime.BaseDefaults=table.clone(H.State)
H.Runtime.ExtraDefaults={
    JumpPowerEnabled=false, JumpPowerValue=50, AlwaysRun=false,
    ClickToWalk=false, ClickToTeleport=false, CameraOptions=false, CameraFOV=70, CameraZoom=128,
    Freecam=false, FreecamSpeed=45, Spectating=false, SpectatePlayer="", AimAssist=false,
    KillAura=false, Fullbright=false, NoFog=false, XRay=false, PerformanceMode=false,
    DisableEffects=false, DisableShadows=false, MiniRadar=false, RadarRange=150,
    PerformanceHUD=false, StreamerMode=false, CustomCursor=false, Theme="Orange", UIScale=1,
    AutoHop=false, AutoHopSeconds=600, SelectedServer="", BossSpawnNotifications=false,
    ConfigName="default", SelectedProfile="", ImportJSON="", MenuKey="RightShift", PanicKey="F8",
    LoaderURL="", AutoExecute=false, FPSLimit=60, WaypointName="home", SelectedWaypoint="",
    MusicId="", EmoteName="wave", ChatMessage="", ChatSeconds=60, AutoChat=false,
    WebhookURL="", WebhookStatus=false, MuzanTracker=false, SlotEventAlerts=false,
}
for key,value in pairs(H.Runtime.ExtraDefaults) do H.State[key]=value end
H.Runtime.Waypoints={}
H.Runtime.Servers={}
H.FeatureStatus=[=[
IMPLEMENTED IN THIS BUILD (live game testing still required)
Auto Quest — searchable quest dropdown; blank/Auto Progress advances; selected quest repeats after the active quest ends.
Boss Farm — existing selected/nearest-boss routes.
Auto Boss Hunts — nearest-boss farming available; separate hunt-contract system unverified.
Auto Skills — existing selected-skill controller.
Kill Aura — nearby NPC M1s within six studs; uses normal combat cooldown.
Auto Pickup Quests — existing NPC dialogue route plus new retry/visibility fixes.
Auto Open Chests / Auto Claim Drops — existing prompt-based collection; rewards remain server-controlled.
Remote Interact — nearest enabled prompt within its normal range, not unlimited-distance interaction.
Boss Spawn Notifications — loaded bosses; alerts after initial discovery.
Event Alerts — optional changes to replicated slot WorldEvents values; not a global event or restock feed.
Live Stats — read-only replicated skill points, stat levels, spent points and progression.
Muzan Tracker — exact-named loaded NPC highlight and distance; cannot locate streamed-out NPCs.
Always Run / Walk Speed — local movement speed override; server rules still apply.
Jump Power / Click To Walk / Click To Teleport / Flight / No-Clip / Infinite Jump — character controls.
Position Rewind — local recent-position history; does not restore health or undo server events.
Quick Reset — resets your character.
Zoom / Camera FOV / Freecam / Infinite Camera — adjustable zoom and unrestricted local freecam movement.
Anti-AFK / Auto Rejoin — existing idle handling and disconnect rejoin.
Mod Safety — creator-group membership notifications only; not reliable staff detection.
Performance Mode / Fullbright / X-Ray / No Fog / Environment Toggles — reversible local visuals.
Mini Radar — loaded NPCs, north-up view.
ESP — existing mobs, bosses, quest targets, chests and drops.
Teleports + Waypoints — named local waypoints saved in profiles.
Server Browser / Server Hop / Auto Hop — public server API; may fail if the API is unavailable or throttled.
Spectate — players currently in the server.
Auto Chat — off by default; user-entered message and interval; subject to game chat access.
Console / Performance HUD / FPS Cap — console, FPS/ping HUD; FPS cap needs executor support.
Streamer Mode — masks the name in this hub's HUD only, not chat or the game UI.
Aimbot — NPC camera aim assist while holding right mouse, not guaranteed hit registration.
Auto Parry — adaptive defence from ping, jitter, animations and combat attributes; no perfect-block guarantee.
Custom Keybinds — menu and emergency-stop keys.
Custom Cursor — optional crosshair cursor.
Music Player / Emotes — supplied audio ID and emote name; asset permissions and rig support apply.
Themes + DPI Scaling — Orange, Mint, Violet and screen-clamped scaling.
Discord Webhook Status — explicit URL; disabled by default; URL excluded from shared profiles.
Auto Execute — requires your raw HTTPS loader URL and teleport-queue support; no placeholder loader.
Save / Load / Share Configs — named JSON profiles, dropdown, clipboard export/import; file/clipboard APIs required.
Hard Reset — restore hub defaults, stop automation and restore modified visuals/camera.

NOT IMPLEMENTED — NEED GAME-SPECIFIC ROUTES OR FURTHER WORK
Auto Dungeon; Auto Cache Farm; Auto Stat; Auto Claim Souls; Auto Collect Schematics.
Restock Alerts; Reveal Whole Map (streamed-out content cannot be inferred).
Infinite Dash; No Slowdowns; Anti Knockback; No Sun Damage; No Drowning; Infinite Climb; Infinite Horse Stamina.
Remove Kill Bricks (hazard identity and server damage route unverified).
Desync; Replication Lag (no validated implementation).
Anti-Detection Hardening (no claim that automation is undetectable).
Language Support (interface remains English).
Cerberus User Overlay (their user-identity service is not available to ThumbsHub).

EXCLUDED BY REQUEST
Instakill.

Open the native stat/action panel, then use Diagnostics Removed to share replicated stat values, visible button paths and relevant module paths. This does not run unknown remotes.
]=]
-- ============================================================
-- INIT
-- ============================================================

H:RefreshBosses()
H:RefreshMobs()
H:RefreshSkills()
H:RefreshTravel()
H:ResolvePunchFunction(true)
H:BuildUI()
H:InitExtras()

for _, plr in ipairs(H.S.Players:GetPlayers()) do
    H:CheckGroupMember(plr)
end

H:Connect(
    H.S.Players.PlayerAdded,
    function(plr)
        H:CheckGroupMember(plr)
    end
)

if H.Player.Character then
    H:WatchHealthForDefense(
        H.Player.Character
    )
end

H:Connect(
    H.Player.CharacterAdded,
    function(character)
        local newHum = character:WaitForChild("Humanoid", 5)
        local newRoot = character:WaitForChild("HumanoidRootPart", 5)
        if not newHum or not newRoot or character ~= H.Player.Character then return end
        task.wait(0.15)
        H.Runtime.Retreating = false
        H.Runtime.RetreatTarget = nil
        H.Runtime.RetreatPosition = nil
        H.Runtime.RetreatStartedAt = 0
        H.Runtime.LastHealth = nil
        H.Runtime.BlockHeld = false
        H.Runtime.Defending = false
        H.Runtime.BlockReleaseUntil = 0
        H.Runtime.ThreatUntil = setmetatable({}, {__mode = "k"})
        H.Runtime.AttackGeneration = (H.Runtime.AttackGeneration or 0) + 1
        H.Runtime.AttackTarget = nil
        H.Runtime.NextPunchAt = 0
        H:ResetAggressiveMobState()
        H:ResetOrbitState()

        local resumeAutoLevel =
            H.State.AutoLevelFarm
            or H.Runtime.ResumeAutoLevelAfterRespawn == true

        local resumeMobFarm =
            H.State.AutoFarmMobs
            or H.Runtime.ResumeMobFarmAfterRespawn == true

        if resumeAutoLevel then
            H.State.AutoLevelFarm = true
            H.State.AutoFarmMobs = true
            H.State.AutoAccept = true
            H.State.AutoWorldBoss = false
            H.State.SmartProgression = false
            H.State.InstantKill = false
            H.Runtime.InstantKillThresholdLocked = false
            H.Runtime.InstantKillBusy = false
            H.Runtime.InstantKillTarget = nil

            H:ResumeBossLoopAfterRespawn()
        end

        if resumeMobFarm then
            H.State.AutoFarmMobs = true

            H.Runtime.MobResumeAt =
                os.clock() + 0.25

            H.Runtime.MobResumeAfterRespawn =
                false

            H:SetStatus(
                resumeAutoLevel
                and "Boss Loop • respawned • returning to " .. tostring(H.State.SelectedMob or "current boss")
                or "Mob Farm • respawned • reacquiring target"
            )
        end

        H.Runtime.ResumeAutoLevelAfterRespawn =
            false

        H.Runtime.ResumeMobFarmAfterRespawn =
            false

        H:WatchHealthForDefense(
            character
        )

        if resumeAutoLevel then
            task.delay(
                0.30,
                function()
                    if not H.State.Unloaded
                        and H.State.AutoLevelFarm then

                        H:AutoLevelFarmStep(
                            true
                        )

                        H:RefreshToggleButtons()
                    end
                end
            )
        end
    end
)

H:Connect(
    H.Player.Idled,
    function()
        if H.State.AntiAFK then
            pcall(function()
                H.S.VirtualUser:CaptureController()
                H.S.VirtualUser:ClickButton2(
                    Vector2.new(0, 0)
                )
            end)
        end
    end
)

H:Connect(
    H.S.UserInputService.JumpRequest,
    function()
        if H.State.InfiniteJump then
            local hum = H:Humanoid()

            if hum then
                hum:ChangeState(
                    Enum.HumanoidStateType.Jumping
                )
            end
        end
    end
)

H:Connect(
    H.S.RunService.Stepped,
    function()
        if H:NeedsMovementNoclip() then H:BossTravelCollisionStep() end
    end
)

H:Connect(
    H.S.RunService.Heartbeat,
    function(dt)
        if not H:NeedsMovementNoclip() then
            for part,value in pairs(H.Runtime.CollisionOriginal or {}) do
                if part.Parent then part.CanCollide=value end
                H.Runtime.CollisionOriginal[part]=nil
            end
        end
        H:UpdateMovementSupport()
        H:UpdateVerifiedGround()
        H:ApplyWalkSpeed()
        H:UpdateFly(dt)
        H:UpdateClockRate()
    end
)

do
    local function safe(label, fn)
        local ok, err = pcall(fn)
        if not ok and (os.clock() - (H.Runtime.LastLoopErrorAt or 0) > 3) then
            H.Runtime.LastLoopErrorAt = os.clock()
            warn("[THUMBSHUB] " .. label .. ": " .. tostring(err))
        end
    end
    local function lane(interval, label, fn)
        task.spawn(function()
            while not H.State.Unloaded and H.UI.Gui and H.UI.Gui.Parent do
                safe(label, fn)
                task.wait(interval)
            end
        end)
    end
    lane(0.025, "Combat", function()
        if not H:IsFarmCombatActive() then
            return
        end

        if H.State.AutoFarmMobs then
            local target = H.Runtime.AttackTarget

            if H:IsCombatModel(target) then
                H:FaceTarget(target)
            end

            if H.Runtime.BlockHeld
                or H:IsBlockingActive() then

                H:StopBlocking()
                H.Runtime.Defending = false
                H.Runtime.BlockReleaseUntil = 0
            end

            return
        end

        local threat =
            H.State.AutoParry
            and H:NearestActiveThreat()

        if threat then
            H:FaceTarget(threat)
            H:StartBlocking(true)
        end
    end)
    lane(0.010, "SpamAttack", function()
        if not H.State.AutoFarmMobs
            or H.Runtime.PostKillLooting
            or H.Runtime.MobApproachTravel
            or H.Runtime.MobSmoothTravelActive then

            return
        end

        local target =
            H.Runtime.AttackTarget

        if not H:IsCombatModel(
            target
        ) then
            return
        end

        local hum =
            H:TargetHumanoid(
                target
            )

        if not hum
            or hum.Health <= 0 then
            return
        end

        if H.State.InstantKill then
            local reached =
                select(
                    1,
                    H:GetInstantKillHealthState(
                        hum
                    )
                )

            if reached
                or H.Runtime.InstantKillBusy
                or H.Runtime.InstantKillThresholdLocked then

                H:HoldM1ForInstantKill(
                    hum
                )

                return
            end
        end

        -- Background combat spam: no synthetic mouse events, so the user's
        -- cursor and UI clicks remain completely free.
        H:BackgroundM1Spam(
            target
        )
    end)

    lane(0.12, "AutoLevel", function()
        H:AutoLevelFarmStep(
            false
        )
    end)

    lane(0.050, "BossHold", function() H:BossHoldStep() end)
    lane(0.030, "Farm", function() H:FarmStep() end)
    lane(1.5, "Discovery", function()
        H:RefreshBosses()
        H:RefreshMobs()
    end)
    lane(4.0, "Travel", function() H:RefreshTravel() end)
    lane(0.30, "UI", function()
        H:GetPingMs()
        if H.State.Visible then
            H:UpdateDashboard()
            H:UpdateBossUI()
            H:UpdateBossOwnershipUI(false)
            H:UpdateHealthGearUI()
            H:UpdateSmoothMetrics()
        end
    end)
    lane(0.25, "ESP", function() H:UpdateESP() end)
    lane(0.35, "Loot", function()
        -- Selected-mob farming has its own post-kill loot ownership state.
        -- Never run generic chest/drop collection beside the live orbit loop.
        if H.State.AutoFarmMobs then
            return
        end

        H:ChestStep()
        H:DropStep()
    end)
end

-- BUILD 55:
-- This executor cannot access GuiService.ErrorMessageChanged.
-- Do not connect the protected signal at all.
H.State.AutoReconnect = false

H:Notify(
    "Loaded • "
    .. tostring(#H.Data.BossCodes)
    .. " bosses • "
    .. tostring(#H.Data.MobNames - 1)
    .. " mob types • "
    .. tostring(#H.Data.SkillNames)
    .. " skills"
)
end

local ok, err = xpcall(
    runThumbsHubSlayers,
    function(problem)
        if debug and type(debug.traceback) == "function" then
            return debug.traceback(tostring(problem), 2)
        end
        return tostring(problem)
    end
)

if not ok then
    warn("[THUMBSHUB SLAYERS] STARTUP FAILED: " .. tostring(err))
end
