-- TankBuffReminder.lua
local CHECK_INTERVAL = 1.0
local BASE_SIZE = 64
local SCALE_MIN = 0.5
local SCALE_MAX = 3.0

local cfg = TankBuffReminderConfig
local trackedBuffs = nil
local soundPlayed = false
local initialLoadDone = false
local lastTauntAlert = 0 -- Anti-spam timer variable

TankBuffReminderDB = TankBuffReminderDB or {}
local db = TankBuffReminderDB

-------------------------------------------------------------------------------
-- Helpers & Automation
-------------------------------------------------------------------------------

local function ApplyGlowSettings(f)
    if not f or not f.glow then return end
    
    local ratio = TankBuffReminderDB.glowSize or (cfg.defaults and cfg.defaults.glowSize) or 1.5
    local size = f:GetWidth() * (ratio * 1.2) 
    f.glow:SetSize(size, size)
    
    local c = TankBuffReminderDB.glowColor or (cfg.defaults and cfg.defaults.glowColor)
    f.glow:SetVertexColor(c.r, c.g, c.b, c.a)
end

local function ApplyScale(f, scale)
    TankBuffReminderDB.scale = math.max(SCALE_MIN, math.min(SCALE_MAX, scale or 1))
    local size = BASE_SIZE * TankBuffReminderDB.scale
    f:SetSize(size, size)
    ApplyGlowSettings(f)
end

function TankBuffReminder_UpdateGlow()
    ApplyGlowSettings(TankBuffReminderFrame)
end

local function DoAutoRepair()
    if not TankBuffReminderDB.autoRepair or not CanMerchantRepair() then return end
    local cost = GetRepairAllCost()
    if cost > 0 and GetMoney() >= cost then
        RepairAllItems()
        print("|cff00ccff[TBR]|r Repaired for " .. GetCoinTextureString(cost))
    end
end

local function OnCombatLogEvent()
    if not TankBuffReminderDB.tauntAlert then return end
    
    -- ANTI-SPAM: If we alerted less than 3 seconds ago, stop here
    if GetTime() - lastTauntAlert < 3 then return end

    local _, subEvent, _, _, sourceName, _, _, _, destName, _, _, spellID, _, _, missType = CombatLogGetCurrentEventInfo()
    
    if sourceName == UnitName("player") and subEvent == "SPELL_MISSED" then
        if cfg.tauntSpells and cfg.tauntSpells[spellID] then
            print("|cffff0000[TBR ALERT]|r Taunt |cffffffffMISSED|r on " .. (destName or "Target") .. " (" .. (missType or "RESIST") .. ")!")
            
            -- Play selected sound
            local soundToPlay = TankBuffReminderDB.soundID or (cfg.defaults and cfg.defaults.soundID) or 8959
            PlaySound(soundToPlay, "Master") 
            
            lastTauntAlert = GetTime() -- Reset the anti-spam timer
        end
    end
end

local function SetTankRole()
    if InCombatLockdown() then return end
    if not TankBuffReminderDB.autoSetTankRole or IsInRaid() or not IsInGroup() then return end
    if UnitGroupRolesAssigned("player") ~= "TANK" then UnitSetRole("player", "TANK") end
end

local function CheckSalvation()
    if not TankBuffReminderDB.autoRemoveSalvation then return end
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, spellID = UnitBuff("player", i)
        if not name then break end
        if spellID == 1038 or spellID == 25895 then 
            CancelUnitBuff("player", i) 
            print("|cff00ccff[TBR]|r Removed Salvation")
        end
    end
end

local function HasBuff(spellID)
    local targetName = GetSpellInfo(spellID)
    if spellID == 26990 and HasBuff(26991) then return true end
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, auraSpellID = UnitBuff("player", i)
        if not name then break end
        if auraSpellID == spellID or name == targetName then return true end
    end
    return false
end

-------------------------------------------------------------------------------
-- Main Frame
-------------------------------------------------------------------------------
local frame = CreateFrame("Button", "TankBuffReminderFrame", UIParent, "SecureActionButtonTemplate")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(true)
frame:RegisterForClicks("AnyUp", "AnyDown")
frame:SetAttribute("unit", "player")
frame:SetAttribute("type1", "spell")

frame.glow = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
frame.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
frame.glow:SetBlendMode("ADD")
frame.glow:SetPoint("CENTER", frame, "CENTER")

frame.icon = frame:CreateTexture(nil, "ARTWORK")
frame.icon:SetAllPoints()
frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

frame.border = frame:CreateTexture(nil, "OVERLAY")
frame.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
frame.border:SetVertexColor(1, 1, 1, 0.2)
frame.border:SetAllPoints()

frame:SetScript("OnMouseDown", function(self, button)
    if not InCombatLockdown() and button == "LeftButton" and IsShiftKeyDown() then
        self:StartMoving()
    end
end)

frame:SetScript("OnMouseUp", function(self)
    if not InCombatLockdown() then
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        TankBuffReminderDB.f1_pos = {p=p, rp=rp, x=x, y=y}
    end
end)

frame:SetResizable(true)
local resize = CreateFrame("Frame", nil, frame)
resize:SetPoint("BOTTOMRIGHT")
resize:SetSize(20, 20)
resize:EnableMouse(true)
local resizeTex = resize:CreateTexture(nil, "OVERLAY")
resizeTex:SetAllPoints()
resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

resize:SetScript("OnMouseDown", function(self)
    if not InCombatLockdown() then self:GetParent():StartSizing("BOTTOMRIGHT") end
end)

resize:SetScript("OnMouseUp", function(self)
    if not InCombatLockdown() then
        local f = self:GetParent()
        f:StopMovingOrSizing()
        ApplyScale(f, f:GetWidth() / BASE_SIZE)
    end
end)

-------------------------------------------------------------------------------
-- UpdateVisibility
-------------------------------------------------------------------------------
function UpdateVisibility()
    CheckSalvation()
    local missingID, missingName, texture = nil, nil, nil
    
    if trackedBuffs then
        for _, entry in ipairs(trackedBuffs) do
            local name, _, tex = GetSpellInfo(entry.spellID)
            if name and not HasBuff(entry.spellID) then
                missingID, missingName, texture = entry.spellID, name, tex
                break
            end
        end
    end

    if not missingID then
        frame.currentSpellID = nil
        soundPlayed = false
        frame:SetAlpha(0.02)
        frame.glow:SetAlpha(0)
    else
        if not soundPlayed and (TankBuffReminderDB.playSound ~= false) then
            local soundToPlay = TankBuffReminderDB.soundID or (cfg.defaults and cfg.defaults.soundID) or 8959
            PlaySound(soundToPlay, "Master")
            soundPlayed = true
        end

        frame.currentSpellID = missingID
        if not InCombatLockdown() then
            frame:SetAttribute("spell1", missingName)
        else
            frame.needsSpell = missingName
        end
        frame.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        frame:SetAlpha(1)
        ApplyGlowSettings(frame) 
    end
end

function TankBuffReminder_RebuildTrackedBuffs()
    trackedBuffs = {}
    local _, class = UnitClass("player")
    for _, b in ipairs(cfg.buffs) do
        local isClass = (class == "PALADIN" and (b.key == "righteousFury" or b.key == "devotionAura")) or
                        (class == "DRUID" and (b.key == "thorns" or b.key == "markOfTheWild" or b.key == "omenOfClarity")) or
                        (class == "WARRIOR" and (b.key == "battleShout" or b.key == "commandingShout" or b.key == "defensiveStance"))
        if isClass and TankBuffReminderDB[b.key] ~= false then table.insert(trackedBuffs, b) end
    end
    UpdateVisibility()
end

-------------------------------------------------------------------------------
-- Events & Pulse
-------------------------------------------------------------------------------
local eF = CreateFrame("Frame")
eF:RegisterEvent("PLAYER_LOGIN")
eF:RegisterEvent("UNIT_AURA")
eF:RegisterEvent("PLAYER_ENTERING_WORLD")
eF:RegisterEvent("PLAYER_REGEN_ENABLED")
eF:RegisterEvent("GROUP_ROSTER_UPDATE")
eF:RegisterEvent("MERCHANT_SHOW")
eF:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

eF:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        for k, v in pairs(cfg.defaults) do if TankBuffReminderDB[k] == nil then TankBuffReminderDB[k] = v end end
        frame:ClearAllPoints()
        if TankBuffReminderDB.f1_pos then 
            frame:SetPoint(TankBuffReminderDB.f1_pos.p, UIParent, TankBuffReminderDB.f1_pos.rp, TankBuffReminderDB.f1_pos.x, TankBuffReminderDB.f1_pos.y) 
        else 
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150) 
        end
        ApplyScale(frame, TankBuffReminderDB.scale or 1)
        TankBuffReminder_RebuildTrackedBuffs()
    elseif event == "MERCHANT_SHOW" then DoAutoRepair()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then OnCombatLogEvent()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if frame.needsSpell then frame:SetAttribute("spell1", frame.needsSpell); frame.needsSpell = nil end
        SetTankRole()
        UpdateVisibility()
    elseif event == "UNIT_AURA" or event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        if event == "GROUP_ROSTER_UPDATE" then SetTankRole() end
        UpdateVisibility()
    end
end)

frame:SetScript("OnUpdate", function(self, elapsed)
    local speed = TankBuffReminderDB.pulseSpeed or 4
    if speed > 0 and self:GetAlpha() > 0.05 then
        local a = 0.75 + math.sin(GetTime() * speed) * 0.25
        self:SetAlpha(a)
        self.glow:SetAlpha(a - 0.2)
    elseif speed == 0 then
        self:SetAlpha(1)
        self.glow:SetAlpha(0.6)
    end
end)

C_Timer.NewTicker(CHECK_INTERVAL, UpdateVisibility)