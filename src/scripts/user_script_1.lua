-- ============================================================================
-- SWBF2 Asymmetric AI Class Randomizer & Customizer (Lua 5.0.2)
-- Equalizes Enemy AI down to Player AI baseline, then applies independent
-- Ally vs. Enemy class counts (0-6) and Boost Levels (+1 to +10).
-- ============================================================================

-- 1. Mod Configuration
AI_Rand_Config = {
    enabled          = true,
    useUnicode       = false, -- Fake Console labels: false = plain strings (try this first),
                              -- true = wrap labels in ScriptCB_tounicode (flip if labels show blank)
    lowerEnemyBase   = true,  -- Lowers Enemy AI (-2 on Normal, -6 on Elite) to match Player base

    -- Independent Class Counts (0 to 6 classes per team)
    enemyBoostCount  = 4,     -- Default: 4 Enemy classes get boosted
    allyBoostCount   = 2,     -- Default: 2 Ally classes get boosted

    -- Independent Boost Levels (+1 to +10, where +6 equals Vanilla Elite)
    enemyBoostLevel  = 4,     -- Default: +4 boost for chosen Enemy classes
    allyBoostLevel   = 7,     -- Default: +7 boost for chosen Ally classes

    -- Runtime Tracking
    playerTeamId     = 1,     -- Auto-detected when human player spawns (1 or 2)
    factionTeams     = {},    -- Maps faction key ("rep", "cis", etc.) -> team ID (1 or 2)
    currentRolls     = {}
}

-- 2. Boost Level Lookup Table (+0 Base through +10 Max)
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

-- 3. Faction Weapon & Unit ODF Maps
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

AI_Rand_UnitMap = {
    rep = {
        soldier  = { "rep_inf_ep3_trooper", "rep_inf_ep2_trooper" },
        assault  = { "rep_inf_ep3_heavy", "rep_inf_ep2_heavy" },
        sniper   = { "rep_inf_ep3_sniper", "rep_inf_ep2_sniper" },
        engineer = { "rep_inf_ep3_engineer", "rep_inf_ep2_pilot" },
        officer  = { "rep_inf_ep3_officer" },
        special  = { "rep_inf_ep3_jettrooper", "rep_inf_ep2_jettrooper" }
    },
    cis = {
        soldier  = { "cis_inf_rifleman", "cis_inf_sbd" },
        assault  = { "cis_inf_rocketeer" },
        sniper   = { "cis_inf_sniper" },
        engineer = { "cis_inf_engineer", "cis_inf_pilot" },
        officer  = { "cis_inf_officer" },
        special  = { "cis_inf_droideka" }
    },
    all = {
        soldier  = { "all_inf_rifleman", "all_inf_rifleman_fleet", "all_inf_rifleman_jungle", "all_inf_rifleman_snow", "all_inf_rifleman_urban", "all_inf_rifleman_desert" },
        assault  = { "all_inf_rocketeer", "all_inf_rocketeer_fleet", "all_inf_rocketeer_jungle", "all_inf_rocketeer_snow", "all_inf_rocketeer_urban", "all_inf_rocketeer_desert" },
        sniper   = { "all_inf_sniper", "all_inf_sniper_fleet", "all_inf_sniper_jungle", "all_inf_sniper_snow", "all_inf_sniper_urban", "all_inf_sniper_desert" },
        engineer = { "all_inf_engineer", "all_inf_engineer_fleet", "all_inf_engineer_jungle", "all_inf_engineer_snow", "all_inf_engineer_urban", "all_inf_engineer_desert" },
        officer  = { "all_inf_officer", "all_inf_officer_snow" },
        special  = { "all_inf_wookiee", "all_inf_wookiee_snow" }
    },
    imp = {
        soldier  = { "imp_inf_rifleman", "imp_inf_rifleman_snow", "imp_inf_rifleman_desert" },
        assault  = { "imp_inf_rocketeer", "imp_inf_rocketeer_snow", "imp_inf_rocketeer_desert" },
        sniper   = { "imp_inf_sniper", "imp_inf_sniper_snow", "imp_inf_sniper_desert" },
        engineer = { "imp_inf_engineer", "imp_inf_engineer_snow", "imp_inf_engineer_desert", "imp_inf_pilot" },
        officer  = { "imp_inf_officer", "imp_inf_officer_snow" },
        special  = { "imp_inf_dark_trooper" }
    }
}

-- 3b. Safe-call helper: one failing game function must never stop the rest of the script
function AI_Rand_Safe(label, fn, a, b)
    local ok, err = pcall(fn, a, b)
    if not ok then
        print("[AI Mod] ERROR in " .. label .. ": " .. tostring(err))
    end
    return ok
end

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

-- 5. Detect Active Faction Team Numbers (1 vs 2) from Mission Globals
function AI_Rand_DetectFactions()
    AI_Rand_Config.factionTeams = {
        rep = REP or 1,
        cis = CIS or 2,
        all = ALL or 1,
        imp = IMP or 2
    }
end

-- 6. Equalize Baseline by Lowering Enemy AI to Player AI's Base Level
function AI_Rand_UpdateBaseline()
    if AI_Rand_Config.enabled and AI_Rand_Config.lowerEnemyBase then
        DisableAIAutoBalance()
        SetAIDifficulty(0, -2, "medium")
        SetAIDifficulty(0, -6, "hard")
    else
        EnableAIAutoBalance()
        SetAIDifficulty(0, 0, "medium")
        SetAIDifficulty(0, 0, "hard")
    end
end

-- 7. Apply Asymmetric Ally vs. Enemy Boosts to Faction Weapons & Units
function AI_Rand_ApplyAllBoosts()
    local baseTier = AI_Rand_BoostTable[0]

    for factionKey, roleList in pairs(AI_Rand_Config.currentRolls) do
        local teamId = AI_Rand_Config.factionTeams[factionKey] or 2
        local isAllyTeam = (teamId == AI_Rand_Config.playerTeamId)

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

            -- Update weapon accuracy bubble
            local factionWeaps = AI_Rand_WeaponMap[factionKey]
            if factionWeaps and factionWeaps[roleKey] then
                local weapList = factionWeaps[roleKey]
                for w = 1, table.getn(weapList) do
                    pcall(SetClassProperty, weapList[w], "AIBubbleSizeMultiplier", tierToUse.bubble)
                end
            end

            -- Update unit visibility / target lock speed
            local factionUnits = AI_Rand_UnitMap[factionKey]
            if factionUnits and factionUnits[roleKey] then
                local unitList = factionUnits[roleKey]
                for u = 1, table.getn(unitList) do
                    pcall(SetClassProperty, unitList[u], "AIVisibilityFactor", tierToUse.vis)
                end
            end

            print("[AI Mod] " .. sideTag .. " (" .. string.upper(factionKey) .. ") "
                .. roleKey .. " -> " .. tierToUse.label)
        end
    end
end

-- 8. Shuffle & Roll Classes for Each Faction
function AI_Rand_RollClasses()
    local roles = { "soldier", "assault", "sniper", "engineer", "officer", "special" }
    local factions = { "rep", "cis", "all", "imp" }
    AI_Rand_Config.currentRolls = {}

    for f = 1, table.getn(factions) do
        local factionKey = factions[f]
        local shuffled = {}
        for i = 1, table.getn(roles) do
            shuffled[i] = roles[i]
        end
        AI_Rand_Shuffle(shuffled)
        AI_Rand_Config.currentRolls[factionKey] = shuffled
    end

    AI_Rand_ApplyAllBoosts()
end

-- 9. Auto-Detect Which Team the Human Player Joined
function AI_Rand_SetupSpawnListener()
    if AI_Rand_SpawnHooked or not OnCharacterSpawn then return end
    AI_Rand_SpawnHooked = true

    OnCharacterSpawn(function(character)
        if IsCharacterHuman(character) then
            local detectedTeam = GetCharacterTeam(character)
            if detectedTeam and detectedTeam ~= AI_Rand_Config.playerTeamId then
                AI_Rand_Config.playerTeamId = detectedTeam
                print("[AI Mod] Human player on Team " .. tostring(detectedTeam) .. " - Updating boosts!")
                AI_Rand_ApplyAllBoosts()
            end
        end
    end)
end

-- 10. Inject Live [AI Mod] Controls Directly into ifs_fakeconsole
function AI_Rand_BuildConsoleRows()
    local modState = "OFF"
    if AI_Rand_Config.enabled then modState = "ON" end

    return {
        { label = "[AI Mod]"},
        { label = "Status: " .. modState .. " (Click to Toggle)", action = "toggle" },
        { label = "Enemy BClasses: " .. tostring(AI_Rand_Config.enemyBoostCount) .. " / 6", action = "enemy_count" },
        { label = "Enemy Boost Level: +" .. tostring(AI_Rand_Config.enemyBoostLevel), action = "enemy_lvl" },
        { label = "Ally BClasses: " .. tostring(AI_Rand_Config.allyBoostCount) .. " / 6", action = "ally_count" },
        { label = "Ally Boost Level: +" .. tostring(AI_Rand_Config.allyBoostLevel), action = "ally_lvl" },
        { label = "Re-Roll Random Classes Now", action = "reroll" }
    }
end

-- Diagnostic: shows (in BFront2.log) which Fake Console globals actually exist.
-- If any of these print "nil", this script's assumptions about ifs_fakeconsole are wrong.
function AI_Rand_LogConsoleState(tag)
    print("[AI Mod] " .. tag
        .. " | ifs_fakeconsole=" .. type(ifs_fakeconsole)
        .. " | gConsoleCmdList=" .. type(gConsoleCmdList)
        .. " | fakeconsole_listbox_layout=" .. type(fakeconsole_listbox_layout)
        .. " | ListManager_fnFillContents=" .. type(ListManager_fnFillContents))
end

function AI_Rand_RefreshConsoleList(this)
    AI_Rand_LogConsoleState("RefreshConsoleList")

    -- Do NOT create the table ourselves: if the stock console keeps its commands
    -- somewhere else, making a fresh global here would hide the real problem.
    if type(gConsoleCmdList) ~= "table" then
        print("[AI Mod] gConsoleCmdList is not a table - cannot inject rows")
        return
    end

    -- Remove previous [AI Mod] rows so they don't duplicate
    local i = table.getn(gConsoleCmdList)
    while i >= 1 do
        if gConsoleCmdList[i] and gConsoleCmdList[i].isAIMod then
            table.remove(gConsoleCmdList, i)
        end
        i = i - 1
    end

    -- Insert updated [AI Mod] rows at the very top of Fake Console
    local rows = AI_Rand_BuildConsoleRows()
    for r = table.getn(rows), 1, -1 do
        local uStr = rows[r].label
        if AI_Rand_Config.useUnicode and ScriptCB_tounicode then
            uStr = ScriptCB_tounicode(rows[r].label)
        end
        table.insert(gConsoleCmdList, 1, {
            ShowStr    = uStr,
            CommandStr = "",
            isAIMod    = true,
            aiAction   = rows[r].action
        })
    end

    if this and this.listbox and fakeconsole_listbox_layout and ListManager_fnFillContents then
        ListManager_fnFillContents(this.listbox, gConsoleCmdList, fakeconsole_listbox_layout)
    end
end

function AI_Rand_HookFakeConsole()
    if AI_Rand_ConsoleHooked or not ifs_fakeconsole then return end
    AI_Rand_ConsoleHooked = true

    AI_Rand_OrigFC_Enter  = ifs_fakeconsole.Enter
    AI_Rand_OrigFC_Accept = ifs_fakeconsole.Input_Accept

    ifs_fakeconsole.Enter = function(this, bFwd)
        if AI_Rand_OrigFC_Enter then
            AI_Rand_OrigFC_Enter(this, bFwd)
        end
        AI_Rand_Safe("console refresh (Enter)", AI_Rand_RefreshConsoleList, this)
    end

    ifs_fakeconsole.Input_Accept = function(this)
        if this.CurButton == "_back" or this.CurButton == "back" then
            if AI_Rand_OrigFC_Accept then AI_Rand_OrigFC_Accept(this) end
            return
        end

        local selIdx = fakeconsole_listbox_layout and fakeconsole_listbox_layout.SelectedIdx
        local item = (type(gConsoleCmdList) == "table" and selIdx) and gConsoleCmdList[selIdx] or nil

        if item and item.isAIMod then
            local act = item.aiAction
            if act == "toggle" then
                AI_Rand_Config.enabled = not AI_Rand_Config.enabled
                AI_Rand_Safe("baseline", AI_Rand_UpdateBaseline)
                AI_Rand_ApplyAllBoosts()
            elseif act == "enemy_count" then
                AI_Rand_Config.enemyBoostCount = AI_Rand_Config.enemyBoostCount + 1
                if AI_Rand_Config.enemyBoostCount > 6 then AI_Rand_Config.enemyBoostCount = 0 end
                AI_Rand_ApplyAllBoosts()
            elseif act == "enemy_lvl" then
                AI_Rand_Config.enemyBoostLevel = AI_Rand_Config.enemyBoostLevel + 1
                if AI_Rand_Config.enemyBoostLevel > 10 then AI_Rand_Config.enemyBoostLevel = 1 end
                AI_Rand_ApplyAllBoosts()
            elseif act == "ally_count" then
                AI_Rand_Config.allyBoostCount = AI_Rand_Config.allyBoostCount + 1
                if AI_Rand_Config.allyBoostCount > 6 then AI_Rand_Config.allyBoostCount = 0 end
                AI_Rand_ApplyAllBoosts()
            elseif act == "ally_lvl" then
                AI_Rand_Config.allyBoostLevel = AI_Rand_Config.allyBoostLevel + 1
                if AI_Rand_Config.allyBoostLevel > 10 then AI_Rand_Config.allyBoostLevel = 1 end
                AI_Rand_ApplyAllBoosts()
            elseif act == "reroll" then
                AI_Rand_RollClasses()
            end

            if ScriptCB_SndPlaySound then
                ScriptCB_SndPlaySound("shell_menu_enter")
            end

            -- Refresh labels live on screen without closing Fake Console
            AI_Rand_RefreshConsoleList(this)
            return
        end

        if AI_Rand_OrigFC_Accept then
            AI_Rand_OrigFC_Accept(this)
        end
    end

    print("[AI Mod] Fake Console hooked")
end

-- 10b. Fallback: if ifs_fakeconsole didn't exist yet when this script loaded,
-- hook it the moment the game opens that screen.
function AI_Rand_SetupLateHook()
    if AI_Rand_PushHooked or not ScriptCB_PushScreen then return end
    AI_Rand_PushHooked = true
    AI_Rand_OrigPushScreen = ScriptCB_PushScreen

    ScriptCB_PushScreen = function(...)
        if arg[1] == "ifs_fakeconsole" and not AI_Rand_ConsoleHooked then
            AI_Rand_Safe("late console hook", AI_Rand_HookFakeConsole)
        end
        return AI_Rand_OrigPushScreen(unpack(arg))
    end
end

-- 11. Run Immediately When Loaded by v1.3 Patch game_interface
-- Every stage is isolated with pcall, and the Fake Console hook goes FIRST, so an
-- error in any game-side call (SetAIDifficulty, SetClassProperty, ...) can no
-- longer stop the menu entries from being installed.
function AI_Rand_Init()
    print("[AI Mod] user_script_1 loading...")
    AI_Rand_LogConsoleState("Init")

    AI_Rand_Safe("console hook", AI_Rand_HookFakeConsole)
    AI_Rand_Safe("late console hook setup", AI_Rand_SetupLateHook)

    AI_Rand_Safe("detect factions", AI_Rand_DetectFactions)
    AI_Rand_Safe("baseline", AI_Rand_UpdateBaseline)

    local steps = math.random(1, 15)
    for s = 1, steps do math.random() end

    AI_Rand_Safe("roll classes", AI_Rand_RollClasses)
    AI_Rand_Safe("spawn listener", AI_Rand_SetupSpawnListener)

    print("[AI Mod] Init finished (console hooked: " .. tostring(AI_Rand_ConsoleHooked) .. ")")
end

AI_Rand_Init()