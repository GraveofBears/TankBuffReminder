-- TankBuffReminder.lua
-- Core: buff detection, automation, event handling, saved variables.

local L = TBR_L
local cfg = TankBuffReminderConfig

local GetTime                = GetTime
local InCombatLockdown       = InCombatLockdown
local UnitBuff               = UnitBuff
local GetSpellInfo           = GetSpellInfo
local IsInGroup              = IsInGroup
local IsInRaid               = IsInRaid
local IsInInstance           = IsInInstance
local UnitClass              = UnitClass
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitSetRole            = UnitSetRole
local CancelUnitBuff         = CancelUnitBuff
local PlaySound              = PlaySound
local GetRepairAllCost       = GetRepairAllCost
local CanMerchantRepair      = CanMerchantRepair
local RepairAllItems         = RepairAllItems
local GetMoney               = GetMoney
local GetShapeshiftForm      = GetShapeshiftForm
local GetShapeshiftFormInfo  = GetShapeshiftFormInfo
local math_floor             = math.floor
local table_wipe             = table.wipe
local table_insert           = table.insert

local STR_BATTLE_SHOUT     = "Battle Shout"
local STR_COMMANDING_SHOUT = "Commanding Shout"
local STR_MARK_WILD        = "Mark of the Wild"
local STR_GIFT_WILD        = "Gift of the Wild"

TankBuffReminderDB     = TankBuffReminderDB     or {}
TankBuffReminderCharDB = TankBuffReminderCharDB or {}

local trackedBuffs       = nil
local RunVisibilityCheck
local isZoning           = false
local lastRoleSet        = 0
local roleSetByAddon     = false
local activeAlerts       = {}
local hasOverriddenTank  = false
local wasInGroup         = false
local removeSoundPlayed  = false
local spellInfoCache     = {}
local spellInfoCacheSize = 0
local SPELL_CACHE_MAX    = 64
local buffStates         = {}
local lastBuffStates     = {}
local lastAuraDurations  = {}
local currentAuraDurations = {}
local EMPTY_TABLE        = {}
local REMOVAL_LOOKUP     = {}
local pendingExtRebuild  = false  -- set when a rebuild is requested during combat

-- External buff state (shared with ExternalBuffBar.lua via global)
TBR_ExtBuffStates = TBR_ExtBuffStates or {}
local lastExtBuffStates = {}

-------------------------------------------------------------------------------
-- Spell helpers
-------------------------------------------------------------------------------
local SHOUT_IDS           = { [2048] = true, [469] = true }
local DEFENSIVE_STANCE_ID = 71

local function IsInDefensiveStance()
    local form = GetShapeshiftForm()
    if form == 0 then return false end
    local _, _, _, id = GetShapeshiftFormInfo(form)
    return id == DEFENSIVE_STANCE_ID
end
TBR_IsInDefensiveStance = IsInDefensiveStance

local function GetSpellName(spellID)
    if not spellID then return nil end
    local n = spellInfoCache[spellID]
    if not n then
        n = GetSpellInfo(spellID)
        if n then
            if spellInfoCacheSize >= SPELL_CACHE_MAX then
                table_wipe(spellInfoCache); spellInfoCacheSize = 0
            end
            spellInfoCache[spellID] = n
            spellInfoCacheSize = spellInfoCacheSize + 1
        end
    end
    return n
end

function HasBuff(spellID, entry)
    if not spellID then return false end
    if spellID == DEFENSIVE_STANCE_ID then return IsInDefensiveStance() end

    local targetName = GetSpellName(spellID)
    if not targetName then return false end

    local isShout = SHOUT_IDS[spellID]
    local isWild  = (spellID == 26990 or spellID == 26991 or targetName == STR_MARK_WILD)

    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        if isShout then
            if name == STR_BATTLE_SHOUT or name == STR_COMMANDING_SHOUT then return true end
        elseif isWild then
            -- ── FIX: Gift of the Wild satisfies Mark of the Wild ───────────
            if name == STR_MARK_WILD or name == STR_GIFT_WILD then return true end
        elseif name == targetName then
            return true
        end
    end
    return false
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------
function TBR_GetTrackedBuffs()
    return trackedBuffs or {}
end

function TBR_ForceCheck()
    if RunVisibilityCheck then RunVisibilityCheck() end
end

-- Wipe the last-state caches so the next RunVisibilityCheck unconditionally
-- pushes a fresh TBR_UI_Update. Call this whenever slots are rebuilt.
function TBR_ResetLastBuffStates()
    if lastBuffStates    then table_wipe(lastBuffStates)    end
    if lastAuraDurations then table_wipe(lastAuraDurations) end
end

-------------------------------------------------------------------------------
-- Master enable/disable
-------------------------------------------------------------------------------
function TBR_SetAddonEnabled(enabled)
    if not TankBuffReminderCharDB then return end
    TankBuffReminderCharDB.disabled = not enabled

    if not enabled then
        if trackedBuffs then table_wipe(trackedBuffs) end
        local buffAnchor    = _G["TankBuffReminderFrame"]
        if buffAnchor    then buffAnchor:Hide()    end
        local extAnchor     = _G["TBR_ExtBuffFrame"]
        if extAnchor     then extAnchor:Hide()     end
        local consAnchor    = _G["TBR_ConsumableBar"]
        if consAnchor    then consAnchor:Hide()    end
        local removalAnchor = _G["TBR_RemovalAnchor"]
        if removalAnchor then removalAnchor:Hide() end
        if TBR_CharFrameDefCapButton then TBR_CharFrameDefCapButton:Hide() end
        if TBR_UI_Rebuild then TBR_UI_Rebuild() end
        print("|cFFFF6600[TBR]|r Addon disabled.")
    else
        TankBuffReminder_RebuildTrackedBuffs()
        if TBR_ExtBar_Rebuild    then TBR_ExtBar_Rebuild()    end
        if TBR_ConsBar_Rebuild   then TBR_ConsBar_Rebuild()   end
        if TBR_DefCapBtn_Refresh then TBR_DefCapBtn_Refresh() end
        local removalAnchor = _G["TBR_RemovalAnchor"]
        if removalAnchor then removalAnchor:Show() end
        if TBR_RemovalUI_Update  then TBR_RemovalUI_Update()  end
        print("|cFF33FF33[TBR]|r Addon enabled.")
    end
end

-------------------------------------------------------------------------------
-- Automation
-------------------------------------------------------------------------------
local roleUpdatePending = false

local function DoAutomation()
    local db = TankBuffReminderCharDB
    if hasOverriddenTank or InCombatLockdown() or not IsInGroup() then return end
    local inRaid = IsInRaid()
    local wantAutoRole
    if inRaid then wantAutoRole = db.autoSetTankRoleRaid == true
    else wantAutoRole = db.autoSetTankRole ~= false end
    if not wantAutoRole then return end
    local _, instanceType = IsInInstance()
    if instanceType == "pvp" or instanceType == "arena" then return end
    local currentRole = UnitGroupRolesAssigned("player")
    if currentRole == "TANK" then roleUpdatePending = false; return end
    if not roleUpdatePending then
        local now = GetTime()
        if (now - lastRoleSet) >= 4 then
            lastRoleSet = now; roleSetByAddon = true; roleUpdatePending = true
            UnitSetRole("player", "TANK")
        end
    end
end

-------------------------------------------------------------------------------
-- External buff check  (smart class detection)
-------------------------------------------------------------------------------

local groupClassSet        = {}
local groupClassCacheValid = false

-- Public accessor so ExternalBuffBar can filter its slot list by the same class set
function TBR_GetGroupClassSet()
    return groupClassSet
end

local function RebuildGroupClassCache()
    table.wipe(groupClassSet)
    groupClassCacheValid = true
    if not IsInGroup() then return end
    if IsInRaid() then
        local n = GetNumGroupMembers()
        for i = 1, n do
            local _, classFile = UnitClass("raid" .. i)
            if classFile then groupClassSet[classFile] = true end
        end
    else
        local n = GetNumSubgroupMembers()
        for i = 1, n do
            local _, classFile = UnitClass("party" .. i)
            if classFile then groupClassSet[classFile] = true end
        end
    end
end

local function CheckExternalBuffs()
    local db = TankBuffReminderCharDB
    if not db or db.disabled then return end
    if not TankBuffReminderExternalBuffs then return end

    local unlocked = db.extBarUnlocked

    if not unlocked then
        local inGroup     = IsInGroup()
        local inRaid      = IsInRaid()
        local showInParty = db.extBuffsShowInParty ~= false
        local showInRaid  = db.extBuffsShowInRaid  ~= false

        if not inGroup
           or (inRaid and not showInRaid)
           or (not inRaid and not showInParty) then
            for _, entry in ipairs(TankBuffReminderExternalBuffs) do
                TBR_ExtBuffStates[entry.key] = false
            end
            return
        end
    end

    local smartDetect = db.extSmartDetect ~= false  -- default true
    if smartDetect and not groupClassCacheValid then
        RebuildGroupClassCache()
    end

    local playerBuffs = {}
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        playerBuffs[name] = true
    end

    for _, entry in ipairs(TankBuffReminderExternalBuffs) do
        if db["ext_" .. entry.key] then
            if smartDetect and not unlocked and entry.sourceClass
               and not groupClassSet[entry.sourceClass] then
                TBR_ExtBuffStates[entry.key] = false
            else
                local found = false
                if type(entry.buffName) == "table" then
                    for _, bn in ipairs(entry.buffName) do
                        if playerBuffs[bn] then found = true; break end
                    end
                else
                    found = playerBuffs[entry.buffName] == true
                end
                TBR_ExtBuffStates[entry.key] = not found
            end
        else
            TBR_ExtBuffStates[entry.key] = false
        end
    end
end

-------------------------------------------------------------------------------
-- Core visibility check
-------------------------------------------------------------------------------
RunVisibilityCheck = function()
    if isZoning or not trackedBuffs then return end
    if TankBuffReminderCharDB and TankBuffReminderCharDB.disabled then return end

    DoAutomation()

    table_wipe(buffStates)
    table_wipe(currentAuraDurations)
    local anyAlertActive = false
    local anyRemovalActive = false

    -- 1. Tracked Buffs Loop (self-buffs / reminders)
    for i = 1, #trackedBuffs do
        local entry = trackedBuffs[i]
        local spellName = GetSpellInfo(entry.spellID)
        for j = 1, 40 do
            local name, _, _, _, _, expirationTime = UnitBuff("player", j)
            if not name then break end
            if name == spellName
               or (entry.key == "markOfTheWild" and (name == STR_MARK_WILD or name == STR_GIFT_WILD)) then
                currentAuraDurations[entry.key] = expirationTime or 0
                break
            end
        end
        local showAlert = not HasBuff(entry.spellID, entry)
        buffStates[entry.key] = showAlert
        if showAlert then anyAlertActive = true end
    end

    -- 2. Removal Buffs Loop (Salvation/BoP)
    for idx = 1, 40 do
        local buffName = UnitBuff("player", idx)
        if not buffName then break end
        local entry = REMOVAL_LOOKUP[buffName]
        if entry then
            local autoRemoveEnabled = TankBuffReminderCharDB[entry.dbKey]
            local showIconEnabled = TankBuffReminderCharDB[entry.showIconDbKey]
            if showIconEnabled then
                buffStates[entry.key] = true; anyAlertActive = true
            elseif autoRemoveEnabled then
                if not InCombatLockdown() and entry.canSelfRemove then
                    CancelUnitBuff("player", idx); anyRemovalActive = true
                else
                    buffStates[entry.key] = true; anyAlertActive = true
                end
            end
        end
    end

    -- 3. External Buff Check
    CheckExternalBuffs()

    local anyExtMissing = false
    for _, entry in ipairs(TankBuffReminderExternalBuffs or {}) do
        if TBR_ExtBuffStates[entry.key] then 
            anyExtMissing = true
            break 
        end
    end

    -- 4. Audio Logic (Salvation/BoP)
    local salvActive = buffStates["salvation"]
    local bopActive = buffStates["bop"]
    local triggerRemovalSound = anyRemovalActive or salvActive or bopActive
    if triggerRemovalSound then
        if not removeSoundPlayed then
            if TankBuffReminderCharDB.removeSoundEnabled ~= false then
                local soundID = TankBuffReminderCharDB.removeSoundID or cfg.defaults.removeSoundID or 847
                PlaySound(soundID, "Master")
            end
            removeSoundPlayed = true
        end
    else
        removeSoundPlayed = false
    end

    -- 5. Audio Logic (Tracked self-buffs)
    if anyAlertActive and not triggerRemovalSound then
        local playedForThisCheck = false
        for i = 1, #trackedBuffs do
            local key = trackedBuffs[i].key
            if buffStates[key] then
                if not activeAlerts[key] then
                    if not playedForThisCheck and TankBuffReminderCharDB.playSound ~= false then
                        local soundID = TankBuffReminderCharDB.soundID or cfg.defaults.soundID or 8959
                        PlaySound(soundID, "Master"); playedForThisCheck = true
                    end
                    activeAlerts[key] = true
                end
            else
                activeAlerts[key] = false
            end
        end
    elseif not anyAlertActive then
        table_wipe(activeAlerts)
    end

    -- 6. UI Update (self-buff bar)
    local needsUIUpdate = false
    for i = 1, #trackedBuffs do
        local key = trackedBuffs[i].key
        if buffStates[key] ~= lastBuffStates[key] or currentAuraDurations[key] ~= lastAuraDurations[key] then
            needsUIUpdate = true; break
        end
    end
    if not needsUIUpdate then
        if buffStates["salvation"] ~= lastBuffStates["salvation"] or
           buffStates["bop"] ~= lastBuffStates["bop"] then
            needsUIUpdate = true
        end
    end
    if needsUIUpdate then
        for i = 1, #trackedBuffs do
            local key = trackedBuffs[i].key
            lastBuffStates[key] = buffStates[key]
            lastAuraDurations[key] = currentAuraDurations[key]
        end
        lastBuffStates["salvation"] = buffStates["salvation"]
        lastBuffStates["bop"] = buffStates["bop"]
        if TBR_UI_Update then TBR_UI_Update(buffStates, anyAlertActive) end
    end

    -- 7. UI Update (external buff bar) - IMPROVED
    local extNeedsUpdate = false
    for _, entry in ipairs(TankBuffReminderExternalBuffs or {}) do
        if TBR_ExtBuffStates[entry.key] ~= lastExtBuffStates[entry.key] then
            extNeedsUpdate = true
            break
        end
    end

    -- Only push to the bar when state actually changed
    if extNeedsUpdate then
        for _, entry in ipairs(TankBuffReminderExternalBuffs or {}) do
            lastExtBuffStates[entry.key] = TBR_ExtBuffStates[entry.key]
        end
        if TBR_ExtBar_Update then
            TBR_ExtBar_Update(TBR_ExtBuffStates, anyExtMissing)
        end
    end

    if TBR_RemovalUI_Update then TBR_RemovalUI_Update(buffStates) end
end

-------------------------------------------------------------------------------
-- Buff list rebuild
-------------------------------------------------------------------------------
local CLASS_SECTION_NAME = {
    PALADIN = "Paladin",
    DRUID   = "Druid",
    WARRIOR = "Warrior",
}
local CLASS_DEFAULT_ORDER = {
    Paladin = { "righteousFury", "devotionAura" },
    Druid   = { "thorns", "markOfTheWild", "omenOfClarity" },
    Warrior = { "battleShout", "commandingShout", "defensiveStance" },
}

local buffByKey = {}
for _, b in ipairs(cfg.buffs) do buffByKey[b.key] = b end

local buffOrderKeySet = {}

function TankBuffReminder_RebuildTrackedBuffs()
    if TankBuffReminderCharDB and TankBuffReminderCharDB.disabled then
        if TBR_UI_Rebuild then TBR_UI_Rebuild() end
        return
    end

    if not trackedBuffs then trackedBuffs = {}
    else table_wipe(trackedBuffs) end

    local _, class    = UnitClass("player")
    local sectionName = CLASS_SECTION_NAME[class]
    if not sectionName then TBR_ForceCheck(); return end

    local defaultOrder = CLASS_DEFAULT_ORDER[sectionName]
    local order        = defaultOrder

    if TankBuffReminderCharDB.buffOrder and TankBuffReminderCharDB.buffOrder[sectionName] then
        local saved = TankBuffReminderCharDB.buffOrder[sectionName]
        table_wipe(buffOrderKeySet)
        for _, k in ipairs(defaultOrder) do buffOrderKeySet[k] = true end
        local valid = (#saved == #defaultOrder)
        if valid then
            for _, k in ipairs(saved) do
                if not buffOrderKeySet[k] then valid = false; break end
            end
        end
        if valid then order = saved end
    end

    for _, key in ipairs(order) do
        local b = buffByKey[key]
        if b and TankBuffReminderCharDB[key] ~= false then
            table_insert(trackedBuffs, b)
        end
    end

    table_wipe(REMOVAL_LOOKUP)
    local autoList = cfg.autoRemove or EMPTY_TABLE
    for i = 1, #autoList do
        local entry = autoList[i]
        for _, name in ipairs(entry.watchNames) do
            REMOVAL_LOOKUP[name] = entry
        end
    end

    if TBR_UI_Rebuild    then TBR_UI_Rebuild()    end
    if TBR_ExtBar_Rebuild then TBR_ExtBar_Rebuild() end

    -- Wipe last-state caches so RunVisibilityCheck is guaranteed to call
    -- TBR_UI_Update on the next tick, even if the buff situation hasn't changed.
    -- Without this, fresh slots (isMissing = false) never get corrected because
    -- the change-detection guard sees no diff against stale lastBuffStates.
    if lastBuffStates    then table_wipe(lastBuffStates)    end
    if lastAuraDurations then table_wipe(lastAuraDurations) end
    TBR_ForceCheck()
end

-------------------------------------------------------------------------------
-- Event frame
-------------------------------------------------------------------------------
local eF = CreateFrame("Frame")
eF:RegisterEvent("PLAYER_LOGIN")
eF:RegisterEvent("PLAYER_REGEN_ENABLED")
eF:RegisterEvent("PLAYER_REGEN_DISABLED")
eF:RegisterEvent("MERCHANT_SHOW")
eF:RegisterEvent("GROUP_ROSTER_UPDATE")
eF:RegisterEvent("PLAYER_ENTERING_WORLD")
eF:RegisterEvent("UNIT_AURA")
eF:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eF:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
eF:RegisterEvent("PLAYER_ROLES_ASSIGNED")

local lastAuraUpdate = 0

local function OnZoneTimer()
    isZoning = false
    if lastBuffStates    then table_wipe(lastBuffStates)    end
    if lastAuraDurations then table_wipe(lastAuraDurations) end
    if lastExtBuffStates then table_wipe(lastExtBuffStates) end
    TBR_ForceCheck()
end

local function OnRosterTimer()
    if RunVisibilityCheck then RunVisibilityCheck() end
end

local function OnSpecTimer()
    TankBuffReminder_RebuildTrackedBuffs()
end

eF:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
    if event == "UNIT_AURA" then
        if arg1 == "player" then
            local now = GetTime()
            if (now - lastAuraUpdate) > 0.2 then
                lastAuraUpdate = now; RunVisibilityCheck()
            end
        end
        return
    end

    if event == "UPDATE_SHAPESHIFT_FORM" then RunVisibilityCheck(); return end

    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        RunVisibilityCheck()
        -- Flush any ext bar rebuild that was deferred to avoid combat lockdown
        if event == "PLAYER_REGEN_ENABLED" and pendingExtRebuild then
            pendingExtRebuild = false
            if TBR_ExtBar_Rebuild then TBR_ExtBar_Rebuild() end
        end
        return
    end

    if event == "PLAYER_ROLES_ASSIGNED" then
        local currentRole = UnitGroupRolesAssigned("player")
        if roleSetByAddon and currentRole ~= "NONE" and currentRole ~= "TANK" then
            roleSetByAddon = false; hasOverriddenTank = true
        elseif currentRole == "TANK" then
            lastRoleSet = GetTime()
        end
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        isZoning = true
        wasInGroup = IsInGroup()
        C_Timer.After(2, OnZoneTimer)
        return
    end

    if TankBuffReminderCharDB and TankBuffReminderCharDB.disabled and event ~= "PLAYER_LOGIN" then return end

    if event == "PLAYER_LOGIN" then
        TankBuffReminderDB     = TankBuffReminderDB     or {}
        TankBuffReminderCharDB = TankBuffReminderCharDB or {}

        local globalDBKeys = {
            consBarEnabled=true, consFrameAlpha=true, consScale=true,
            consAlpha=true, consPadding=true, consMouseover=true,
            consHideEmpty=true, consPulseSpeed=true, consTimerFontSize=true,
            consTimerOffsetY=true, consTimerAlpha=true, consSweepAlpha=true,
            consGlowAlpha=true, consGlowColor=true, consTextColor=true,
            -- External bar globals
            extBarScale=true, extBarButtonPadding=true,
            extGlowColor=true, extBar_pos=true,
        }

        if cfg and cfg.defaults then
            for k, v in pairs(cfg.defaults) do
                if globalDBKeys[k] then
                    if TankBuffReminderDB[k] == nil then TankBuffReminderDB[k] = v end
                else
                    if TankBuffReminderCharDB[k] == nil then TankBuffReminderCharDB[k] = v end
                end
            end
        end

        if cfg and cfg.consumables then
            for _, item in ipairs(cfg.consumables) do
                local key = "cons_" .. item.key
                if TankBuffReminderCharDB[key] == nil then
                    TankBuffReminderCharDB[key] = item.defaultOn or false
                end
            end
        end

        -- External buff defaults
        if TankBuffReminderExternalBuffs then
            for _, entry in ipairs(TankBuffReminderExternalBuffs) do
                local k = "ext_" .. entry.key
                if TankBuffReminderCharDB[k] == nil then
                    TankBuffReminderCharDB[k] = false
                end
            end
        end
        if TankBuffReminderCharDB.extBuffsShowInParty  == nil then TankBuffReminderCharDB.extBuffsShowInParty  = true  end
        if TankBuffReminderCharDB.extBuffsShowInRaid   == nil then TankBuffReminderCharDB.extBuffsShowInRaid   = true  end
        if TankBuffReminderCharDB.extSmartDetect       == nil then TankBuffReminderCharDB.extSmartDetect       = true  end
        if TankBuffReminderCharDB.extBarUnlocked       == nil then TankBuffReminderCharDB.extBarUnlocked       = false end
        if TankBuffReminderCharDB.extPlaySound         == nil then TankBuffReminderCharDB.extPlaySound         = true  end
        if TankBuffReminderCharDB.extSoundID           == nil then TankBuffReminderCharDB.extSoundID           = 8959  end
        if TankBuffReminderCharDB.extFrameAlpha        == nil then TankBuffReminderCharDB.extFrameAlpha        = 1.0   end
        if TankBuffReminderCharDB.extBuffAlpha         == nil then TankBuffReminderCharDB.extBuffAlpha         = 1.0   end
        if TankBuffReminderCharDB.extGlowSize          == nil then TankBuffReminderCharDB.extGlowSize          = 2.0   end
        if TankBuffReminderCharDB.extPulseSpeed        == nil then TankBuffReminderCharDB.extPulseSpeed        = 4     end
        if TankBuffReminderCharDB.extSweepAlpha        == nil then TankBuffReminderCharDB.extSweepAlpha        = 0.6   end
        if TankBuffReminderCharDB.extTimerFontSize     == nil then TankBuffReminderCharDB.extTimerFontSize     = 12    end
        if TankBuffReminderCharDB.extTimerTextOffsetY  == nil then TankBuffReminderCharDB.extTimerTextOffsetY  = 0     end
        if TankBuffReminderCharDB.extTimerAlpha        == nil then TankBuffReminderCharDB.extTimerAlpha        = 1.0   end
        if TankBuffReminderCharDB.extAnnounceChannel   == nil then TankBuffReminderCharDB.extAnnounceChannel   = "PARTY" end
        if TankBuffReminderCharDB.extWarning           == nil then TankBuffReminderCharDB.extWarning           = true  end
        if TankBuffReminderCharDB.extSay               == nil then TankBuffReminderCharDB.extSay               = false end
        if TankBuffReminderCharDB.extYell              == nil then TankBuffReminderCharDB.extYell              = false end
        if TankBuffReminderCharDB.extParty             == nil then TankBuffReminderCharDB.extParty             = false end
        if TankBuffReminderCharDB.extRaid              == nil then TankBuffReminderCharDB.extRaid              = false end
        if TankBuffReminderCharDB.extWarnSeconds       == nil then TankBuffReminderCharDB.extWarnSeconds       = 0     end
        if TankBuffReminderDB.extBarScale              == nil then TankBuffReminderDB.extBarScale              = 1.0   end
        if TankBuffReminderDB.extBarButtonPadding      == nil then TankBuffReminderDB.extBarButtonPadding      = 4     end
        if TankBuffReminderDB.extGlowColor             == nil then TankBuffReminderDB.extGlowColor             = { r=1, g=1, b=0.6, a=1 } end
        -- Taunt defaults
        if TankBuffReminderCharDB.tauntEnabled  == nil then TankBuffReminderCharDB.tauntEnabled  = true  end
        if TankBuffReminderCharDB.tauntWarning  == nil then TankBuffReminderCharDB.tauntWarning  = true  end
        if TankBuffReminderCharDB.tauntSay      == nil then TankBuffReminderCharDB.tauntSay      = false end
        if TankBuffReminderCharDB.tauntParty    == nil then TankBuffReminderCharDB.tauntParty    = false end
        if TankBuffReminderCharDB.tauntRaid     == nil then TankBuffReminderCharDB.tauntRaid     = false end
        if TankBuffReminderCharDB.tauntYell     == nil then TankBuffReminderCharDB.tauntYell     = false end
        if TankBuffReminderCharDB.tauntSoundEnabled == nil then TankBuffReminderCharDB.tauntSoundEnabled = true end

        wasInGroup = IsInGroup()
        TankBuffReminder_RebuildTrackedBuffs()

        if TankBuffReminderOptions and TankBuffReminderOptions.refresh then
            TankBuffReminderOptions.refresh()
        end
        return
    end

    if event == "MERCHANT_SHOW" then
        if TankBuffReminderCharDB.autoRepair ~= false and CanMerchantRepair() then
            local cost = GetRepairAllCost()
            if cost > 0 and GetMoney() >= cost then
                RepairAllItems()
                local gold   = math_floor(cost / 10000)
                local silver = math_floor((cost % 10000) / 100)
                local copper = cost % 100
                print(string.format("|cff00ccff[TBR]|r " .. L["Auto-repair: %s%s%s"],
                    (gold   > 0 and gold   .. "|cffFFD700g |r" or ""),
                    (silver > 0 and silver .. "|cffC0C0C0s |r" or ""),
                    (copper > 0 and copper .. "|cffB87333c|r"  or "")))
            end
        end
        return
    end

    if event == "GROUP_ROSTER_UPDATE" then
        local inGroup = IsInGroup()
        if inGroup ~= wasInGroup then
            hasOverriddenTank = false; roleSetByAddon = false; wasInGroup = inGroup
        end
        -- Rebuild class cache immediately so smart detection is accurate
        -- on the very first RunVisibilityCheck after the roster changes.
        groupClassCacheValid = false
        RebuildGroupClassCache()
        C_Timer.After(1, OnRosterTimer)
        C_Timer.After(1.1, function()
            if TBR_ExtBar_Rebuild then
                if InCombatLockdown() then
                    pendingExtRebuild = true
                else
                    TBR_ExtBar_Rebuild()
                end
            end
        end)
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        C_Timer.After(0.5, OnSpecTimer); return
    end
end)