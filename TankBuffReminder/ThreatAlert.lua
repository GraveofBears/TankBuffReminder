-- ThreatAlert.lua
local L = TBR_L

-- Upvalues
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitGUID = UnitGUID
local GetTime = GetTime
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local IsInInstance = IsInInstance
local SendChatMessage = SendChatMessage
local PlaySound = PlaySound
local C_Timer = C_Timer

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------
local MSG_PREFIX = "|cFFFF6600[TBR]|r "
local SPAM_THROTTLE = 3.0
local DEFAULT_WINDOW = 5

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------
local playerGUID = nil
local pvpShield = false
local inCombat = false
local combatStartTime = 0
local lastAlertTime = 0
local isThrottling = false

local eventBuffer = {}
local formattedLines = {}
local dedupHash = {}

-------------------------------------------------------------------------------
-- CC Spells
-------------------------------------------------------------------------------
local CC_SPELLS = {
    [5782] = "Fear", [8122] = "Psychic Scream", [5484] = "Howl of Terror",
    [12809] = "Concussion Blow", [24394] = "Intimidation", [46968] = "Shockwave",
    [1833] = "Cheap Shot", [408] = "Kidney Shot", [20549] = "War Stomp",
    [15487] = "Silence", [2094] = "Blind", [118] = "Polymorph",
}

-------------------------------------------------------------------------------
-- Tank Detection
-------------------------------------------------------------------------------
local function IsTanking()
    if not TankBuffReminderCharDB or not TankBuffReminderCharDB.threatEnabled then
        return false
    end

    local _, class = UnitClass("player")

    if class == "DRUID" then
        for i = 1, 40 do
            local name = UnitBuff("player", i)
            if not name then break end
            if name == "Bear Form" or name == "Dire Bear Form" then
                return UnitGroupRolesAssigned("player") == "TANK"
            end
        end
        return false
    end

    return UnitGroupRolesAssigned("player") == "TANK"
end

-------------------------------------------------------------------------------
-- Event Queue
-------------------------------------------------------------------------------
local function FlushBuffer()
    isThrottling = false
    if #eventBuffer == 0 then return end

    table.wipe(formattedLines)
    table.wipe(dedupHash)

    for i = 1, #eventBuffer, 3 do
        local spellName  = eventBuffer[i] or "Ability"
        local targetName = eventBuffer[i+1] or ""
        local eventType  = eventBuffer[i+2] or "Event"

        local entry = targetName ~= "" 
            and (targetName .. " " .. eventType:lower() .. " " .. spellName)
            or  (spellName .. " (" .. eventType .. ")")

        if not dedupHash[entry] then
            table.insert(formattedLines, entry)
            dedupHash[entry] = true
        end
    end

    table.wipe(eventBuffer)
    lastAlertTime = GetTime()

    local prefix = L["THREAT_ALERT_PREFIX"] or "Pull issue — "
    local msg = prefix .. table.concat(formattedLines, ", ")

    if TankBuffReminderCharDB.threatWarning ~= false then
        print(MSG_PREFIX .. msg)
    end

    if TankBuffReminderCharDB.threatSoundEnabled ~= false then
        PlaySound(TankBuffReminderCharDB.threatSoundID or 8959, "Master")
    end

    if IsInGroup() then
        if TankBuffReminderCharDB.threatSay then
            SendChatMessage(msg, "SAY")
        elseif TankBuffReminderCharDB.threatYell then
            SendChatMessage(msg, "YELL")
        elseif TankBuffReminderCharDB.threatRaid and IsInRaid() then
            SendChatMessage(msg, "RAID")
        elseif TankBuffReminderCharDB.threatParty then
            SendChatMessage(msg, "PARTY")
        end
    end
end

local function QueueEvent(spellName, targetName, eventType)
    table.insert(eventBuffer, spellName or "")
    table.insert(eventBuffer, targetName or "")
    table.insert(eventBuffer, eventType or "Event")

    if not isThrottling then
        isThrottling = true
        C_Timer.After(0.15, FlushBuffer)
    end
end

-------------------------------------------------------------------------------
-- Should Listen? (Different logic for CC vs Misses)
-------------------------------------------------------------------------------
local function IsListening(isCC)
    local db = TankBuffReminderCharDB
    if not db or not db.threatEnabled then return false end
    if pvpShield or not inCombat then return false end
    if not IsTanking() then return false end

    if isCC and db.threatCCFullCombat then
        return true                    -- CCs can alert for entire combat
    else
        local window = db.threatWindow or DEFAULT_WINDOW
        return (GetTime() - combatStartTime) <= window
    end
end

-------------------------------------------------------------------------------
-- Main Event Frame
-------------------------------------------------------------------------------
local tA = CreateFrame("Frame")
tA:RegisterEvent("PLAYER_LOGIN")
tA:RegisterEvent("PLAYER_ENTERING_WORLD")
tA:RegisterEvent("PLAYER_REGEN_DISABLED")
tA:RegisterEvent("PLAYER_REGEN_ENABLED")

local function ToggleThreatRegistration()
    if TankBuffReminderCharDB and TankBuffReminderCharDB.threatEnabled then
        tA:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        tA:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

tA:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        playerGUID = UnitGUID("player")
        local db = TankBuffReminderCharDB
        if db then
            db.threatEnabled       = db.threatEnabled ~= false
            db.threatWarning       = db.threatWarning ~= false
            db.threatSay           = db.threatSay == true
            db.threatYell          = db.threatYell == true
            db.threatParty         = db.threatParty == true
            db.threatRaid          = db.threatRaid == true
            db.threatSoundEnabled  = db.threatSoundEnabled ~= false
            db.threatMiss          = db.threatMiss ~= false
            db.threatResist        = db.threatResist ~= false
            db.threatCC            = db.threatCC ~= false
            db.threatWindow        = db.threatWindow or DEFAULT_WINDOW
            db.threatCCFullCombat  = db.threatCCFullCombat ~= true   
        end
        ToggleThreatRegistration()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        playerGUID = UnitGUID("player")
        local _, instanceType = IsInInstance()
        pvpShield = (instanceType == "pvp" or instanceType == "arena")
        ToggleThreatRegistration()
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        combatStartTime = GetTime()
        lastAlertTime = 0
        table.wipe(eventBuffer)
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        table.wipe(eventBuffer)
        return
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, sourceGUID, _, _, _, destGUID, destName, _, _, 
              spellID, spellName, _, missType = CombatLogGetCurrentEventInfo()

        -- Spell / Ranged Misses (short window only)
        if sourceGUID == playerGUID and (subEvent == "SPELL_MISSED" or subEvent == "RANGE_MISSED") then
            if IsListening(false) then
                if (missType == "RESIST" and TankBuffReminderCharDB.threatResist) or
                   (missType ~= "RESIST" and TankBuffReminderCharDB.threatMiss) then
                    QueueEvent(spellName or "Spell", destName, missType)
                end
            end

        -- CC on Tank (can last full combat)
        elseif destGUID == playerGUID and subEvent == "SPELL_AURA_APPLIED" then
            if TankBuffReminderCharDB.threatCC and IsListening(true) then
                if CC_SPELLS[spellID] then
                    QueueEvent(spellName, "", CC_SPELLS[spellID])
                elseif spellName then
                    local lower = spellName:lower()
                    if lower:find("stun") or lower:find("fear") or lower:find("silence") or 
                       lower:find("sleep") or lower:find("charm") or lower:find("blind") then
                        QueueEvent(spellName, "", "CC")
                    end
                end
            end
        end
    end
end)