-- Taunt.lua
local addonName = ...
local cfg = TankBuffReminderConfig

-- Performance Locals (Faster than global lookups)
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitGUID = UnitGUID
local GetTime = GetTime
local table_insert = table.insert
local table_wipe = table.wipe
local table_concat = table.concat

-- State Variables
local lastAlertTime = 0
local SPAM_THROTTLE = 2.5 -- Prevents chat flooding
local isThrottling = false
local pvpShield = false
local resistBuffer = {}
local playerGUID = nil

-- Optimized Spell Map (IDs are faster than string names)
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

    -- Remove duplicates (common in AOE logic)
    local uniqueNames = {}
    local hash = {}
    for _, name in ipairs(resistBuffer) do
        if not hash[name] then
            table_insert(uniqueNames, name)
            hash[name] = true
        end
    end
    
    local nameList = table_concat(uniqueNames, ", ")
    local msg = "TAUNT FAILED: " .. nameList .. " (Resist/Immune)"
    table_wipe(resistBuffer)

    -- 1. Warning (Self Only - Chat Window)
    if TankBuffReminderDB.tauntWarning ~= false then
        print("|cFFFF0000[TBR]|r " .. msg)
    end

    -- 2. External Channels (Only if in a group)
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
        -- Exit immediately if system is off or in PvP
        if not TankBuffReminderDB.tauntEnabled or pvpShield then return end

        local _, subEvent, _, sourceGUID, _, _, _, _, destName, _, _, spellID, _, _, missType = CombatLogGetCurrentEventInfo()

        -- Filter: Only player spells + failed casts (Resist/Immune/Miss)
        if sourceGUID == playerGUID and subEvent == "SPELL_MISSED" then
            if tauntSpells[spellID] then
                if missType == "RESIST" or missType == "IMMUNE" or missType == "MISS" then
                    -- Throttle check to prevent spamming the buffer itself
                    local now = GetTime()
                    if (now - lastAlertTime) > SPAM_THROTTLE then
                        table_insert(resistBuffer, destName or "Unknown")
                        
                        -- Batch AOE results (waits 0.1s to see if other mobs also resist)
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
        -- Cache GUID and Check for PvP Zone (Disable logic in BGs/Arena)
        playerGUID = UnitGUID("player")
        local _, instanceType = IsInInstance()
        pvpShield = (instanceType == "pvp" or instanceType == "arena")

    elseif event == "PLAYER_LOGIN" then
        playerGUID = UnitGUID("player")
    end
end)