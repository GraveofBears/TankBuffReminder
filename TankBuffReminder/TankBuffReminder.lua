-- TankBuffReminder.lua
-- Core: buff detection, automation, event handling, saved variables.
-- UI rendering is handled by FrameUI.lua.

local CHECK_INTERVAL_COMBAT = 0.5   -- kept for reference; currently unused
local CHECK_INTERVAL_IDLE   = 2.0

-- Localize globals
local GetTime                = GetTime
local InCombatLockdown       = InCombatLockdown
local UnitBuff               = UnitBuff
local GetSpellInfo           = GetSpellInfo
local IsInGroup              = IsInGroup
local IsInRaid               = IsInRaid
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
local table_concat           = table.concat
local C_Timer                = C_Timer

local STR_BATTLE_SHOUT     = "Battle Shout"
local STR_COMMANDING_SHOUT = "Commanding Shout"
local STR_MARK_WILD        = "Mark of the Wild"
local STR_GIFT_WILD        = "Gift of the Wild"

local cfg = TankBuffReminderConfig

-- SavedVariables — initialised early so Options.lua can read them at load time
TankBuffReminderDB     = TankBuffReminderDB     or {}
TankBuffReminderCharDB = TankBuffReminderCharDB or {}

-- State
local trackedBuffs       = nil
local isZoning           = false
local lastRoleSet        = 0
local activeAlerts       = {}
local removeSoundPlayed  = false
local spellInfoCache     = {}
local spellInfoCacheSize = 0
local SPELL_CACHE_MAX    = 64
local buffStates         = {}
local lastBuffStates     = {}
local lastAuraDurations  = {}
local repairParts        = {}
local EMPTY_TABLE        = {}
local REMOVAL_LOOKUP     = {}

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

local function GetSpellName(spellID)
    if not spellID then return nil end
    local n = spellInfoCache[spellID]
    if not n then
        n = GetSpellInfo(spellID)
        if n then
            if spellInfoCacheSize >= SPELL_CACHE_MAX then
                table_wipe(spellInfoCache)
                spellInfoCacheSize = 0
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
            if name == STR_MARK_WILD or name == STR_GIFT_WILD then return true end
        elseif name == targetName then
            return true
        end
    end
    return false
end

-------------------------------------------------------------------------------
-- Public API consumed by FrameUI.lua
-------------------------------------------------------------------------------
function TBR_GetTrackedBuffs()
    return trackedBuffs or {}
end

-------------------------------------------------------------------------------
-- Automation
-------------------------------------------------------------------------------
local function DoAutomation()
    if TankBuffReminderCharDB.autoSetTankRole ~= false
       and not InCombatLockdown()
       and IsInGroup()
       and not IsInRaid() then
        local now = GetTime()
        if (now - lastRoleSet) >= 4 then
            if UnitGroupRolesAssigned("player") ~= "TANK" then
                lastRoleSet = now
                UnitSetRole("player", "TANK")
            end
        end
    end
end

-- Compatibility shims for Options.lua
function TankBuffReminder_SetRoleLogic() end
function TankBuffReminder_UpdateGlow()
    RunVisibilityCheck()
end

-------------------------------------------------------------------------------
-- Core visibility check
-------------------------------------------------------------------------------
local function RunVisibilityCheck()
    if isZoning or not trackedBuffs then return end
    DoAutomation()

    table_wipe(buffStates)
    local anyAlertActive   = false
    local anyRemovalActive = false
    local autoRemoveList   = cfg.autoRemove or EMPTY_TABLE
    local currentAuraDurations = {}

    -- 1. Standard buff tracking
    for i = 1, #trackedBuffs do
        local entry     = trackedBuffs[i]
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

    -- 2. Removal / icon check (single pass)
    for idx = 1, 40 do
        local buffName = UnitBuff("player", idx)
        if not buffName then break end

        local entry = REMOVAL_LOOKUP[buffName]
        if entry then
            local autoRemoveEnabled = TankBuffReminderCharDB[entry.dbKey]
            local showIconEnabled   = TankBuffReminderCharDB[entry.showIconDbKey]

            if autoRemoveEnabled then
                if not InCombatLockdown() then
                    CancelUnitBuff("player", idx)
                    anyRemovalActive = true
                elseif showIconEnabled then
                    buffStates[entry.key] = true
                    anyAlertActive = true
                end
            elseif showIconEnabled then
                buffStates[entry.key] = true
                anyAlertActive = true
            end
        end
    end

    -- 3. Audio alerts
    local salvActive = buffStates["salvation"]
    local bopActive  = buffStates["bop"]
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

    if anyAlertActive and not triggerRemovalSound then
        local playedForThisCheck = false
        for i = 1, #trackedBuffs do
            local key = trackedBuffs[i].key
            if buffStates[key] then
                if not activeAlerts[key] then
                    if not playedForThisCheck and TankBuffReminderCharDB.playSound ~= false then
                        local soundID = TankBuffReminderCharDB.soundID or cfg.defaults.soundID or 8959
                        PlaySound(soundID, "Master")
                        playedForThisCheck = true
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

    -- 4. UI update — only when state or expiration changed
    local needsUIUpdate = false
    for i = 1, #trackedBuffs do
        local key = trackedBuffs[i].key
        if buffStates[key] ~= lastBuffStates[key] or currentAuraDurations[key] ~= lastAuraDurations[key] then
            needsUIUpdate = true
            break
        end
    end

    if needsUIUpdate then
        for i = 1, #trackedBuffs do
            local key = trackedBuffs[i].key
            lastBuffStates[key]    = buffStates[key]
            lastAuraDurations[key] = currentAuraDurations[key]
        end
        if TBR_UI_Update then
            TBR_UI_Update(buffStates, anyAlertActive)
        end
    end
end

-------------------------------------------------------------------------------
-- Internal helpers
-------------------------------------------------------------------------------
function TBR_ForceCheck()
    RunVisibilityCheck()
end

local function SafeRunCheck()
    if not isZoning then RunVisibilityCheck() end
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
    if not trackedBuffs then
        trackedBuffs = {}
    else
        table_wipe(trackedBuffs)
    end

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

    if TBR_UI_Rebuild then TBR_UI_Rebuild() end
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

local lastAuraUpdate = 0

local function OnZoneTimer()
    isZoning = false
    -- Wipe last-seen state so the diff check always triggers a full UI update
    -- after zoning, even if the buff list is identical to pre-zone.
    table_wipe(lastBuffStates)
    table_wipe(lastAuraDurations)
    TBR_ForceCheck()
end
local function OnRosterTimer() SafeRunCheck() end
local function OnSpecTimer()   TankBuffReminder_RebuildTrackedBuffs() end

eF:SetScript("OnEvent", function(self, event, arg1)
    if event == "UNIT_AURA" then
        if arg1 == "player" then
            local now = GetTime()
            if (now - lastAuraUpdate) > 0.2 then
                lastAuraUpdate = now
                RunVisibilityCheck()
            end
        end
        return
    end

    if event == "UPDATE_SHAPESHIFT_FORM" then
        RunVisibilityCheck()
        return
    end

    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        SafeRunCheck()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        isZoning = true
        C_Timer.After(2, OnZoneTimer)
        return
    end

    if event == "PLAYER_LOGIN" then
        TankBuffReminderDB     = TankBuffReminderDB     or {}
        TankBuffReminderCharDB = TankBuffReminderCharDB or {}

        local globalDBKeys = {
            consBarEnabled = true, consFrameAlpha = true, consScale = true,
            consAlpha = true, consPadding = true, consMouseover = true,
            consPulseSpeed = true, consTimerFontSize = true, consTimerOffsetY = true,
            consTimerAlpha = true, consSweepAlpha = true, consGlowAlpha = true,
            consGlowColor = true, consTextColor = true,
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
                print(string.format("|cff00ccff[TBR]|r Auto-repair: %s%s%s",
                    (gold   > 0 and gold   .. "|cffFFD700g |r" or ""),
                    (silver > 0 and silver .. "|cffC0C0C0s |r" or ""),
                    (copper > 0 and copper .. "|cffB87333c|r"  or "")))
            end
        end
        return
    end

    if event == "GROUP_ROSTER_UPDATE" then
        C_Timer.After(1, OnRosterTimer)
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        C_Timer.After(0.5, OnSpecTimer)
        return
    end
end)