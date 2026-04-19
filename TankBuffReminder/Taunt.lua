-- Taunt.lua
local addonName = ...
local cfg = TankBuffReminderConfig

-- Performance Locals
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitGUID = UnitGUID
local GetTime = GetTime
local table_insert = table.insert
local table_wipe = table.wipe
local table_concat = table.concat

-- State Variables
local lastAlertTime = 0
local SPAM_THROTTLE = 2.5 
local isThrottling = false
local pvpShield = false
local resistBuffer = {} -- Now stores tables: {name, type}
local playerGUID = nil

-- Optimized Spell Map
local tauntSpells = {
    [355]   = true, -- Taunt (Warrior)
    [1161]  = true, -- Challenging Shout (Warrior AOE)
    [6795]  = true, -- Growl (Druid)
    [5209]  = true, -- Challenging Roar (Druid AOE)
    [31790] = true, -- Righteous Defense (Paladin AOE)
    [20271] = true, -- Judgement of Righteousness (Paladin TBC)
}

-- Logic to process and send the gathered resists
local function ProcessResistBuffer()
    isThrottling = false
    if #resistBuffer == 0 then return end

    local formattedEntries = {}
    local hash = {}

    for _, data in ipairs(resistBuffer) do
        local entryString = string.format("%s (%s)", data.name, data.mType)
        if not hash[entryString] then
            table_insert(formattedEntries, entryString)
            hash[entryString] = true
        end
    end
    
    local combinedList = table_concat(formattedEntries, ", ")
    local msg = "TAUNT FAILED: " .. combinedList
    table_wipe(resistBuffer)

    -- 1. Warning (Self Only)
    if TankBuffReminderDB.tauntWarning ~= false then
        print("|cFFFF0000[TBR]|r " .. msg)
    end

    -- 2. External Channels
    if IsInGroup() then
        if TankBuffReminderDB.tauntSay then
            SendChatMessage(msg, "SAY")
        elseif TankBuffReminderDB.tauntRaid and IsInRaid() then
            SendChatMessage(msg, "RAID")
        elseif TankBuffReminderDB.tauntParty then
            SendChatMessage(msg, "PARTY")
        end
    end
end

local tF = CreateFrame("Frame")
tF:RegisterEvent("PLAYER_LOGIN")
tF:RegisterEvent("PLAYER_ENTERING_WORLD")
tF:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

tF:SetScript("OnEvent", function(self, event)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if not TankBuffReminderDB.tauntEnabled or pvpShield then return end

        local _, subEvent, _, sourceGUID, _, _, _, _, destName, _, _, spellID, _, _, missType = CombatLogGetCurrentEventInfo()

        -- Filter: Only player spells + SPELL_MISSED
        if sourceGUID == playerGUID and subEvent == "SPELL_MISSED" then
            if tauntSpells[spellID] then
                -- Normalize the string for the message
                local mType = "Miss"
                if missType == "RESIST" then mType = "Resist"
                elseif missType == "IMMUNE" then mType = "Immune" end

                if missType == "RESIST" or missType == "IMMUNE" or missType == "MISS" then
                    local now = GetTime()
                    if (now - lastAlertTime) > SPAM_THROTTLE then
                        -- Store as a small table for processing
                        table_insert(resistBuffer, { name = destName or "Unknown", mType = mType })
                        
                        if not isThrottling then
                            isThrottling = true
                            lastAlertTime = now
                            C_Timer.After(0.1, ProcessResistBuffer)
                        end
                    end
                end
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