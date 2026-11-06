-- ============================================================================
-- SWBF2 Asymmetric AI Class Randomizer & Customizer (Lua 5.0.2)
-- Equalizes Enemy AI down to Player AI baseline, then applies independent
-- Ally vs. Enemy class counts (0-6) and Boost Levels (+1 to +10).
-- ============================================================================

-- 1. Mod Configuration (Defaults match your example out of the box)
AI_Rand_Config = {
    enabled          = true,
    lowerEnemyBase   = true,  -- Lowers Enemy AI (-2 on Normal, -6 on Elite) to match Player base

    -- Independent Class Counts (0 to 6 classes per team)
    enemyBoostCount  = 4,     -- Default: 4 Enemy classes get boosted
    allyBoostCount   = 2,     -- Default: 2 Ally classes get boosted

    -- Independent Boost Levels (+1 to +10, where +6 equals Vanilla Elite)
    enemyBoostLevel  = 4,     -- Default: +4 boost for chosen Enemy classes
    allyBoostLevel   = 7,     -- Default: +7 boost for chosen Ally classes

    -- Runtime Tracking
    playerTeamId     = 1,     -- Auto-detected when human player spawns (1 or 2)
    activeTeams      = nil,
    currentRolls     = {}
}

-- 2. Boost Level Lookup Table (+0 Base through +10 Max)
-- Lower bubble = tighter AI aim cone; Higher visibility = faster AI target lock
AI_Rand_BoostTable = {
    [0]  = { bubble = "1.35", vis = "0.85", label = "+0 (Base Normal)" },
    [1]  = { bubble = "1.05", vis = "0.92", label = "+1 (Light)" },
    [2]  = { bubble = "0.75", vis = "0.99", label = "+2 (Modest)" },
    [3]  = { bubble = "0.45", vis = "1.06", label = "+3 (Balanced)" },
    [4]  = { bubble = "0.25", vis = "1.13", label = "+4 (Hard - Lite Elite)" },
    [5]  = { bubble = "0.16", vis = "1.20", label = "+5 (Tough)" },
    [6]  = { bubble = "0.10", vis = "1.27", label = "+6 (Vanilla Elite)" },
    [7]  = { bubble = "0.06", vis = "1.34", label = "+7 (Veteran Elite+)" },
    [8]  = { bubble = "0.04", vis = "1.42", label = "+8 (SpecOps)" },
    [9]  = { bubble = "0.03", vis = "1.50", label = "+9 (Lethal)" },
    [10] = { bubble = "0.02", vis = "1.60", label = "+10 (Aimbot)" }
}

-- 3. Faction Weapon Map
AI_Rand_WeaponMap = {
    rep = {
        soldier  = { "rep_weap_inf_rifle", "rep_weap_inf_pistol" },
        assault  = { "rep_weap_inf_torpedolauncher", "rep_weap_inf_pistol" },
        sniper   = { "rep_weap_inf_sniperrifle", "rep_weap_inf_pistol" },
        engineer = { "rep_weap_inf_shotgun" },
        officer  = { "rep_weap_inf_chaingun" },
        special  = { "rep_weap_inf_arcak", "rep_weap_inf_commando_pistol" }
    },
    cis = {
        soldier  = { "cis_weap_inf_rifle", "cis_weap_inf_pistol", "cis_weap_inf_wristblaster" },
        assault  = { "cis_weap_inf_torpedolauncher", "cis_weap_inf_pistol" },
        sniper   = { "cis_weap_inf_sniperrifle", "cis_weap_inf_pistol" },
        engineer = { "cis_weap_inf_shotgun" },
        officer  = { "cis_weap_inf_mortarlauncher", "cis_weap_inf_pistol" },
        special  = { "cis_weap_inf_repeater" }
    },
    all = {
        soldier  = { "all_weap_inf_rifle", "all_weap_inf_pistol" },
        assault  = { "all_weap_inf_torpedolauncher", "all_weap_inf_pistol" },
        sniper   = { "all_weap_inf_sniperrifle", "all_weap_inf_pistol" },
        engineer = { "all_weap_inf_shotgun" },
        officer  = { "all_weap_inf_sonicblaster", "all_weap_inf_pistol" },
        special  = { "all_weap_inf_bowcaster", "all_weap_inf_pistol" }
    },
    imp = {
        soldier  = { "imp_weap_inf_rifle", "imp_weap_inf_pistol" },
        assault  = { "imp_weap_inf_torpedolauncher", "imp_weap_inf_pistol" },
        sniper   = { "imp_weap_inf_sniperrifle", "imp_weap_inf_pistol" },
        engineer = { "imp_weap_inf_shotgun" },
        officer  = { "imp_weap_inf_mortarlauncher", "imp_weap_inf_pistol" },
        special  = { "imp_weap_inf_arccaster", "imp_weap_inf_pistol" }
    }
}

-- 4. Helper: Lua 5.0 Fisher-Yates Shuffle
function AI_Rand_Shuffle(t)
    local n = table.getn(t)
    while n > 1 do
        local k = math.random(1, n)
        t[n], t[k] = t[k], t[n]
        n = n - 1
    end
    return t
end

-- 5. Equalize Baseline by Lowering Enemy AI to Player AI's Base Level
function AI_Rand_UpdateBaseline()
    if AI_Rand_Config.enabled and AI_Rand_Config.lowerEnemyBase then
        DisableAIAutoBalance()
        -- Normal ("medium"): Player is 10, Enemy is 12 -> Lower Enemy by -2 so both = 10
        SetAIDifficulty(0, -2, "medium")
        -- Elite ("hard"): Player is 11, Enemy is 17 -> Lower Enemy by -6 so both = 11
        SetAIDifficulty(0, -6, "hard")
    else
        EnableAIAutoBalance()
        SetAIDifficulty(0, 0, "medium")
        SetAIDifficulty(0, 0, "hard")
    end
end

-- 6. Apply Asymmetric Ally vs. Enemy Boosts to Active Teams
function AI_Rand_ApplyAllBoosts()
    if not AI_Rand_Config.activeTeams then return end

    local baseTier = AI_Rand_BoostTable[0]

    for factionKey, roleList in pairs(AI_Rand_Config.currentRolls) do
        local teamData = AI_Rand_Config.activeTeams[factionKey]
        if type(teamData) == "table" then
            -- Determine if this faction is the Human Player's team or the Enemy team
            local isAllyTeam = (teamData.team == AI_Rand_Config.playerTeamId)

            local numToBoost = AI_Rand_Config.enemyBoostCount
            local boostLvl   = AI_Rand_Config.enemyBoostLevel
            local sideTag    = "ENEMY"

            if isAllyTeam then
                numToBoost = AI_Rand_Config.allyBoostCount
                boostLvl   = AI_Rand_Config.allyBoostLevel
                sideTag    = "ALLY"
            end

            local activeTier = AI_Rand_BoostTable[boostLvl] or baseTier

            for i = 1, table.getn(roleList) do
                local roleKey = roleList[i]
                local shouldBoost = (AI_Rand_Config.enabled and (i <= numToBoost))

                local tierToUse = baseTier
                if shouldBoost then
                    tierToUse = activeTier
                end

                -- Apply aim cone multiplier to all weapons for this unit class
                local factionWeaps = AI_Rand_WeaponMap[factionKey]
                if factionWeaps and factionWeaps[roleKey] then
                    local weapList = factionWeaps[roleKey]
                    for w = 1, table.getn(weapList) do
                        SetClassProperty(weapList[w], "AIBubbleSizeMultiplier", tierToUse.bubble)
                    end
                end

                -- Apply visibility / target acquisition speed to the unit ODF
                if type(teamData[roleKey]) == "table" and teamData[roleKey][1] then
                    local unitOdf = teamData[roleKey][1]
                    SetClassProperty(unitOdf, "AIVisibilityFactor", tierToUse.vis)
                end

                print("[AI Mod] " .. sideTag .. " (" .. string.upper(factionKey) .. ") "
                    .. roleKey .. " -> " .. tierToUse.label)
            end
        end
    end
end

-- 7. Shuffle & Roll Classes for Each Team
function AI_Rand_RollClasses()
    if not AI_Rand_Config.activeTeams then return end

    local roles = { "soldier", "assault", "sniper", "engineer", "officer", "special" }
    AI_Rand_Config.currentRolls = {}

    for factionKey, teamData in pairs(AI_Rand_Config.activeTeams) do
        if type(teamData) == "table" and AI_Rand_WeaponMap[factionKey] then
            local shuffled = {}
            for i = 1, table.getn(roles) do
                shuffled[i] = roles[i]
            end
            AI_Rand_Shuffle(shuffled)
            AI_Rand_Config.currentRolls[factionKey] = shuffled
        end
    end

    AI_Rand_ApplyAllBoosts()
end

-- 8. Auto-Detect Which Team the Human Player Joined (Even if They Switch Teams!)
function AI_Rand_SetupSpawnListener()
    if AI_Rand_SpawnHooked or not OnCharacterSpawn then return end
    AI_Rand_SpawnHooked = true

    OnCharacterSpawn(function(character)
        if IsCharacterHuman(character) then
            local detectedTeam = GetCharacterTeam(character)
            if detectedTeam and detectedTeam ~= AI_Rand_Config.playerTeamId then
                AI_Rand_Config.playerTeamId = detectedTeam
                print("[AI Mod] Human player detected on Team " .. tostring(detectedTeam) .. " - Updating Ally/Enemy boosts!")
                AI_Rand_ApplyAllBoosts()
            end
        end
    end)
end

-- 9. Hook SetupTeams() Globally
if not AI_Rand_OrigSetupTeams then
    AI_Rand_OrigSetupTeams = SetupTeams

    SetupTeams = function(teams)
        AI_Rand_OrigSetupTeams(teams)

        AI_Rand_Config.activeTeams = teams
        AI_Rand_SpawnHooked = false

        -- Check current profile difficulty (2 = Normal, 3 = Elite) for debug log
        if ScriptCB_GetDifficulty then
            local diff = ScriptCB_GetDifficulty()
            print("[AI Mod] Profile Difficulty Detected: " .. tostring(diff) .. " (2=Normal, 3=Elite)")
        end

        AI_Rand_UpdateBaseline()

        -- Advance RNG
        local steps = math.random(1, 15)
        for s = 1, steps do math.random() end

        AI_Rand_RollClasses()
        AI_Rand_SetupSpawnListener()
        AI_Rand_RegisterMenu()
    end
end

-- 10. In-Game Customization Menu (Pause -> Fake Console / Mod Options)
function AI_Rand_RegisterMenu()
    if not ff_addCommand and not gConsoleCmdList then return end
    if AI_Rand_MenuRegistered then return end
    AI_Rand_MenuRegistered = true

    local function addOption(labelStr, callbackFn)
        if type(ff_addCommand) == "function" then
            ff_addCommand(labelStr, labelStr, callbackFn)
        elseif type(gConsoleCmdList) == "table" then
            local n = table.getn(gConsoleCmdList) + 1
            gConsoleCmdList[n] = { str = labelStr, fn = callbackFn }
        end
    end

    -- 1. Master Toggle
    addOption("[AI Mod] Toggle Mod ON / OFF", function()
        AI_Rand_Config.enabled = not AI_Rand_Config.enabled
        AI_Rand_UpdateBaseline()
        AI_Rand_ApplyAllBoosts()
        print("[AI Mod] Enabled: " .. tostring(AI_Rand_Config.enabled))
    end)

    -- 2. Enemy Boosted Classes Count (Cycles 0 -> 6)
    addOption("[AI Mod] Enemy Boosted Classes Count (0 - 6)", function()
        AI_Rand_Config.enemyBoostCount = AI_Rand_Config.enemyBoostCount + 1
        if AI_Rand_Config.enemyBoostCount > 6 then
            AI_Rand_Config.enemyBoostCount = 0
        end
        AI_Rand_ApplyAllBoosts()
        print("[AI Mod] Enemy Boosted Classes: " .. tostring(AI_Rand_Config.enemyBoostCount))
    end)

    -- 3. Enemy Boost Level (Cycles +1 -> +10)
    addOption("[AI Mod] Enemy AI Boost Level (+1 to +10)", function()
        AI_Rand_Config.enemyBoostLevel = AI_Rand_Config.enemyBoostLevel + 1
        if AI_Rand_Config.enemyBoostLevel > 10 then
            AI_Rand_Config.enemyBoostLevel = 1
        end
        AI_Rand_ApplyAllBoosts()
        print("[AI Mod] Enemy Boost Level: +" .. tostring(AI_Rand_Config.enemyBoostLevel))
    end)

    -- 4. Ally Boosted Classes Count (Cycles 0 -> 6)
    addOption("[AI Mod] Ally Boosted Classes Count (0 - 6)", function()
        AI_Rand_Config.allyBoostCount = AI_Rand_Config.allyBoostCount + 1
        if AI_Rand_Config.allyBoostCount > 6 then
            AI_Rand_Config.allyBoostCount = 0
        end
        AI_Rand_ApplyAllBoosts()
        print("[AI Mod] Ally Boosted Classes: " .. tostring(AI_Rand_Config.allyBoostCount))
    end)

    -- 5. Ally Boost Level (Cycles +1 -> +10)
    addOption("[AI Mod] Ally AI Boost Level (+1 to +10)", function()
        AI_Rand_Config.allyBoostLevel = AI_Rand_Config.allyBoostLevel + 1
        if AI_Rand_Config.allyBoostLevel > 10 then
            AI_Rand_Config.allyBoostLevel = 1
        end
        AI_Rand_ApplyAllBoosts()
        print("[AI Mod] Ally Boost Level: +" .. tostring(AI_Rand_Config.allyBoostLevel))
    end)

    -- 6. Re-Roll Random Classes Mid-Match
    addOption("[AI Mod] Re-Roll Boosted Classes Now", function()
        AI_Rand_RollClasses()
        print("[AI Mod] Re-rolled Ally & Enemy boosted classes!")
    end)
end
