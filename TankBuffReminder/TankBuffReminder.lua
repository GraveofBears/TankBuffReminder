-- TankBuffReminder.lua
local BASE_SIZE = 64
local SCALE_MIN, SCALE_MAX = 0.5, 3.0

local cfg = TankBuffReminderConfig
local trackedBuffs = nil
local soundPlayed = false
local lastTauntAlert = 0 
local frameThrottle = 0 -- Anti-stutter timer

-- Localize globals for performance
local UnitBuff, GetSpellInfo, InCombatLockdown, GetTime = UnitBuff, GetSpellInfo, InCombatLockdown, GetTime

TankBuffReminderDB = TankBuffReminderDB or {}

-------------------------------------------------------------------------------
-- Animation Setup (Zero-Memory Pulse)
-------------------------------------------------------------------------------
local function SetupAnimations(f)
    f.ag = f:CreateAnimationGroup()
    local anim = f.ag:CreateAnimation("Alpha")
    anim:SetFromAlpha(1.0)
    anim:SetToAlpha(0.6)
    anim:SetDuration(0.5) 
    anim:SetSmoothing("IN_OUT")
    f.ag:SetLooping("BOUNCE")
end

local function UpdatePulseSpeed(f)
    local speed = TankBuffReminderDB.pulseSpeed or 4
    if speed > 0 then
        local duration = math.max(0.1, 2 / speed)
        f.ag:GetAnimations():SetDuration(duration)
        if f:GetAlpha() > 0.05 and not f.ag:IsPlaying() then f.ag:Play() end
    else
        f.ag:Stop()
        f:SetAlpha(1)
        f.glow:SetAlpha(0.6)
    end
end

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
    if TankBuffReminderFrame then
        ApplyGlowSettings(TankBuffReminderFrame)
        UpdatePulseSpeed(TankBuffReminderFrame)
    end
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
    if GetTime() - lastTauntAlert < 3 then return end

    local _, subEvent, _, _, sourceName, _, _, _, destName, _, _, spellID, _, _, missType = CombatLogGetCurrentEventInfo()
    
    if sourceName == UnitName("player") and subEvent == "SPELL_MISSED" then
        if cfg.tauntSpells and cfg.tauntSpells[spellID] then
            print("|cffff0000[TBR ALERT]|r Taunt |cffffffffMISSED|r on " .. (destName or "Target") .. " (" .. (missType or "RESIST") .. ")!")
            local soundToPlay = TankBuffReminderDB.soundID or (cfg.defaults and cfg.defaults.soundID) or 8959
            PlaySound(soundToPlay, "Master")
            lastTauntAlert = GetTime()
        end
    end
end

local function SetTankRole()
    if InCombatLockdown() or not TankBuffReminderDB.autoSetTankRole or IsInRaid() or not IsInGroup() then return end
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
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, auraSpellID = UnitBuff("player", i)
        if not name then break end
        if auraSpellID == spellID or name == targetName then return true end
    end
    return false
end

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

    local f = TankBuffReminderFrame
    if not f then return end

    if not missingID then
        f.currentSpellID = nil
        soundPlayed = false
        
        if f.ag and f.ag:IsPlaying() then f.ag:Stop() end
        f:SetAlpha(0.01) 
        f.glow:SetAlpha(0)
        
        if not InCombatLockdown() then
            f:SetAttribute("spell1", nil)
        end
    else
        if not soundPlayed and (TankBuffReminderDB.playSound ~= false) then
            local soundToPlay = TankBuffReminderDB.soundID or (cfg.defaults and cfg.defaults.soundID) or 8959
            PlaySound(soundToPlay, "Master")
            soundPlayed = true
        end

        if not InCombatLockdown() then
            f:SetAttribute("spell1", missingName)
        else
            f.needsSpell = missingName
        end

        f.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        f:SetAlpha(1)
        ApplyGlowSettings(f)
        UpdatePulseSpeed(f)
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
-- Main Frame Setup
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
frame.glow:SetPoint("CENTER")

frame.icon = frame:CreateTexture(nil, "ARTWORK")
frame.icon:SetAllPoints()
frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

frame.border = frame:CreateTexture(nil, "OVERLAY")
frame.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
frame.border:SetVertexColor(1, 1, 1, 0.2)
frame.border:SetAllPoints()

SetupAnimations(frame)

frame:SetScript("OnMouseDown", function(self, button)
    if not InCombatLockdown() and button == "LeftButton" and IsShiftKeyDown() then self:StartMoving() end
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

resize:SetScript("OnMouseDown", function(self) if not InCombatLockdown() then self:GetParent():StartSizing("BOTTOMRIGHT") end end)
resize:SetScript("OnMouseUp", function(self)
    if not InCombatLockdown() then
        local f = self:GetParent()
        f:StopMovingOrSizing()
        ApplyScale(f, f:GetWidth() / BASE_SIZE)
    end
end)

-------------------------------------------------------------------------------
-- Event Handler (Throttled)
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
        if TankBuffReminderDB.f1_pos then 
            TankBuffReminderFrame:ClearAllPoints()
            TankBuffReminderFrame:SetPoint(TankBuffReminderDB.f1_pos.p, UIParent, TankBuffReminderDB.f1_pos.rp, TankBuffReminderDB.f1_pos.x, TankBuffReminderDB.f1_pos.y) 
        else 
            TankBuffReminderFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -150) 
        end
        ApplyScale(TankBuffReminderFrame, TankBuffReminderDB.scale or 1)
        TankBuffReminder_RebuildTrackedBuffs()
        
    elseif event == "MERCHANT_SHOW" then 
        DoAutoRepair()
        
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then 
        OnCombatLogEvent()
        
    else
        -- Throttle UNIT_AURA, GROUP_ROSTER, etc to 0.1s to prevent micro-stutter
        local now = GetTime()
        if (now - frameThrottle) > 0.1 then
            if event == "PLAYER_REGEN_ENABLED" then
                if TankBuffReminderFrame.needsSpell then 
                    TankBuffReminderFrame:SetAttribute("spell1", TankBuffReminderFrame.needsSpell)
                    TankBuffReminderFrame.needsSpell = nil 
                end
                SetTankRole()
            elseif event == "GROUP_ROSTER_UPDATE" then 
                SetTankRole() 
            end
            
            UpdateVisibility()
            frameThrottle = now
        end
    end
end)