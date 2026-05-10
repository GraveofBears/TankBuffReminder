-- Taunt.lua
local addonName = ...

local cfg = TankBuffReminderConfig

-- Performance locals
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitGUID      = UnitGUID
local GetTime       = GetTime
local IsInGroup     = IsInGroup
local IsInRaid      = IsInRaid
local IsInInstance  = IsInInstance
local SendChatMessage = SendChatMessage
local print         = print
local PlaySound     = PlaySound
local table_insert  = table.insert
local table_wipe    = table.wipe
local table_concat  = table.concat
local C_Timer       = C_Timer

-- State
local lastAlertTime = 0
local SPAM_THROTTLE = 2.5
local isThrottling  = false
local pvpShield     = false
local playerGUID    = nil

-- Static memory pools (reused per flush, no allocations)
local resistBuffer     = {}
local formattedEntries = {}
local hash             = {}

-- String constants
local MSG_PREFIX  = "|cFFFF0000[TBR]|r "
local FAIL_HEADER = "TAUNT FAILED: "
local UNKNOWN_STR = "Unknown"

local mTypeCache = {
    ["MISS"]   = "Miss",
    ["RESIST"] = "Resist",
    ["IMMUNE"] = "Immune",
}

local tauntSpells = {
    [355]   = true, -- Taunt (Warrior)
    [1161]  = true, -- Challenging Shout
    [6795]  = true, -- Growl (Druid)
    [5209]  = true, -- Challenging Roar
    [31790] = true, -- Righteous Defense
    [20271] = true, -- Judgement of Righteousness
}

-------------------------------------------------------------------------------
-- Buffer processing
-------------------------------------------------------------------------------
local function ProcessResistBuffer()
    isThrottling = false
    if #resistBuffer == 0 then return end

    table_wipe(formattedEntries)
    table_wipe(hash)

    for i = 1, #resistBuffer, 2 do
        local name  = resistBuffer[i]
        local mType = resistBuffer[i + 1]
        local entry = name .. " (" .. mType .. ")"
        if not hash[entry] then
            table_insert(formattedEntries, entry)
            hash[entry] = true
        end
    end

    local msg = FAIL_HEADER .. table_concat(formattedEntries, ", ")
    table_wipe(resistBuffer)

    -- Stamp alert time after draining the buffer so the throttle runs from when
    -- the player sees the message, not from the first combat-log event.
    lastAlertTime = GetTime()

    if TankBuffReminderCharDB.tauntWarning ~= false then
        print(MSG_PREFIX .. msg)
    end

    if TankBuffReminderCharDB.tauntSoundEnabled ~= false then
        local soundID = TankBuffReminderCharDB.tauntSoundID
                     or (cfg.defaults and cfg.defaults.tauntSoundID)
                     or 8959
        PlaySound(soundID, "Master")
    end

    if IsInGroup() then
        if TankBuffReminderCharDB.tauntSay then
            SendChatMessage(msg, "SAY")
        elseif TankBuffReminderCharDB.tauntRaid and IsInRaid() then
            SendChatMessage(msg, "RAID")
        elseif TankBuffReminderCharDB.tauntParty then
            SendChatMessage(msg, "PARTY")
        end
    end
end

-------------------------------------------------------------------------------
-- Event frame
-------------------------------------------------------------------------------
local tF = CreateFrame("Frame")
tF:RegisterEvent("PLAYER_LOGIN")
tF:RegisterEvent("PLAYER_ENTERING_WORLD")
tF:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

tF:SetScript("OnEvent", function(self, event)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, sourceGUID, _, _, _, _, destName, _, _, spellID, _, _, missType =
            CombatLogGetCurrentEventInfo()

        if sourceGUID ~= playerGUID or subEvent ~= "SPELL_MISSED" then return end
        if not TankBuffReminderCharDB.tauntEnabled or pvpShield then return end
        if not tauntSpells[spellID] then return end
        if missType ~= "RESIST" and missType ~= "IMMUNE" and missType ~= "MISS" then return end

        local now = GetTime()
        -- Accept events while already collecting (isThrottling), or when outside the spam window.
        -- This ensures a RESIST arriving right after an IMMUNE is never silently dropped.
        if isThrottling or (now - lastAlertTime) > SPAM_THROTTLE then
            local mType = mTypeCache[missType] or mTypeCache["MISS"]
            table_insert(resistBuffer, destName or UNKNOWN_STR)
            table_insert(resistBuffer, mType)
            if not isThrottling then
                isThrottling = true
                C_Timer.After(0.1, ProcessResistBuffer)
            end
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        playerGUID = UnitGUID("player")
        local _, instanceType = IsInInstance()
        pvpShield = (instanceType == "pvp" or instanceType == "arena")

    elseif event == "PLAYER_LOGIN" then
        playerGUID = UnitGUID("player")
    end
end)