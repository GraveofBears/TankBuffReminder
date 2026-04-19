-- TankBuffReminder.lua
local CHECK_INTERVAL = 1.0
local BASE_SIZE = 64
local SCALE_MIN, SCALE_MAX = 0.5, 3.0

local cfg = TankBuffReminderConfig
local currentSpellID = nil
local trackedBuffs = nil
local soundPlayed = false
local pulseTimer = 0

TankBuffReminderDB = TankBuffReminderDB or {}

-------------------------------------------------------------------------------
-- Helpers & Visuals
-------------------------------------------------------------------------------
local function ApplyGlowSettings(f)
    if not f or not f.glow then return end
    local ratio = TankBuffReminderDB.glowSize or cfg.defaults.glowSize or 1.5
    local size = f:GetWidth() * ratio
    f.glow:SetSize(size, size)
    local c = TankBuffReminderDB.glowColor or cfg.defaults.glowColor
    f.glow:SetVertexColor(c.r, c.g, c.b, c.a)
end

local function ApplyScale(f, scale)
    scale = math.max(SCALE_MIN, math.min(SCALE_MAX, scale or 1))
    local size = BASE_SIZE * scale
    f:SetSize(size, size)
    TankBuffReminderDB.scale = scale
    ApplyGlowSettings(f)
end

function TankBuffReminder_UpdateGlow()
    ApplyGlowSettings(TankBuffReminderFrame)
end

local function HasBuff(spellID)
    local targetName = GetSpellInfo(spellID)
    
    -- Improved logic for Mark/Gift of the Wild
    if spellID == 26990 or spellID == 26991 or targetName == "Mark of the Wild" then
        for i = 1, 40 do
            local name = UnitBuff("player", i)
            if not name then break end
            if name == "Mark of the Wild" or name == "Gift of the Wild" then 
                return true 
            end
        end
        return false
    end

    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, auraSpellID = UnitBuff("player", i)
        if not name then break end
        if auraSpellID == spellID or name == targetName then return true end
    end
    return false
end

-------------------------------------------------------------------------------
-- Automation Features
-------------------------------------------------------------------------------
local function DoAutomation()
    -- Salvation Removal
    if TankBuffReminderDB.autoRemoveSalvation then
        for i = 1, 40 do
            local _, _, _, _, _, _, _, _, _, _, spellID = UnitBuff("player", i)
            if not spellID then break end
            if spellID == 1038 or spellID == 25895 then CancelUnitBuff("player", i) end
        end
    end
    
    -- Tank Role Assignment
    if TankBuffReminderDB.autoSetTankRole and IsInGroup() and not InCombatLockdown() then
        if GetPartyAssignment("MAINTANK", "player") == nil then
            SetPartyAssignment("MAINTANK", "player")
        end
    end
end

-------------------------------------------------------------------------------
-- Visibility & Logic
-------------------------------------------------------------------------------
function UpdateVisibility()
    DoAutomation()
    
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
    if not missingID then
        currentSpellID = nil
        soundPlayed = false
        f:SetAlpha(0.001) -- Reverted to original faded-out style
        f.glow:SetAlpha(0)
        f.needsSpell = nil 
        return
    end

    -- Play Sound
    if f:GetAlpha() <= 0.05 and not soundPlayed then
        if TankBuffReminderDB.playSound ~= false then
            PlaySound(TankBuffReminderDB.soundID or cfg.defaults.soundID or 8959, "Master")
        end
        soundPlayed = true
    end

    currentSpellID = missingID
    f.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

    -- Secure Attribute Updates
    if not InCombatLockdown() then
        f:SetAttribute("type1", "spell")
        f:SetAttribute("spell1", missingName)
        f.needsSpell = nil
    else
        -- If in combat and the button is showing a different spell, queue it
        if f:GetAttribute("spell1") ~= missingName then
            f.needsSpell = missingName
        end
    end
    
    f:SetAlpha(1)
end

-------------------------------------------------------------------------------
-- Frame Setup
-------------------------------------------------------------------------------
local frame = CreateFrame("Button", "TankBuffReminderFrame", UIParent, "SecureActionButtonTemplate")
frame:SetSize(BASE_SIZE, BASE_SIZE)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(true)
frame:RegisterForClicks("AnyUp", "AnyDown")
frame:SetAttribute("type1", "spell")
frame:SetAttribute("unit", "player")

frame.icon = frame:CreateTexture(nil, "ARTWORK")
frame.icon:SetAllPoints()
frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

frame.glow = frame:CreateTexture(nil, "BACKGROUND")
frame.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
frame.glow:SetBlendMode("ADD")
frame.glow:SetPoint("CENTER")

frame:SetScript("OnUpdate", function(self, elapsed)
    if self:GetAlpha() < 0.5 then 
        self.glow:SetAlpha(0)
        return 
    end
    local speed = TankBuffReminderDB.pulseSpeed or cfg.defaults.pulseSpeed or 4
    if speed <= 0 then
        self:SetAlpha(1)
        self.glow:SetAlpha(0.6)
        return
    end
    pulseTimer = pulseTimer + elapsed
    local alpha = 0.75 + math.sin(pulseTimer * speed) * 0.25
    self:SetAlpha(alpha)
    self.glow:SetAlpha(alpha - 0.2)
end)

frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if currentSpellID then GameTooltip:SetSpellByID(currentSpellID) 
    else GameTooltip:SetText("Tank Buff Reminder") end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click to cast", 1, 1, 1)
    GameTooltip:AddLine("Shift + drag to move", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Movement & Resize
frame:SetScript("OnMouseDown", function(self, button)
    if not InCombatLockdown() and button == "LeftButton" and IsShiftKeyDown() then 
        self:StartMoving() 
        self.isMoving = true
    end
end)

frame:SetScript("OnMouseUp", function(self)
    if self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
        if not InCombatLockdown() then
            local p, _, rp, x, y = self:GetPoint()
            TankBuffReminderDB.f1_pos = {p=p, rp=rp, x=x, y=y}
        end
    end
end)

frame:SetResizable(true)
local resize = CreateFrame("Frame", nil, frame)
resize:SetPoint("BOTTOMRIGHT")
resize:SetSize(16, 16)
resize:EnableMouse(true)
local resizeTex = resize:CreateTexture(nil, "OVERLAY")
resizeTex:SetAllPoints()
resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

resize:SetScript("OnMouseDown", function(self) 
    if not InCombatLockdown() then 
        local f = self:GetParent()
        f:StartSizing("BOTTOMRIGHT") 
        f.isSizing = true
    end 
end)

resize:SetScript("OnMouseUp", function(self)
    local f = self:GetParent()
    if f.isSizing then
        f:StopMovingOrSizing()
        f.isSizing = false
        if not InCombatLockdown() then
            ApplyScale(f, f:GetWidth() / BASE_SIZE)
        end
    end
end)

-------------------------------------------------------------------------------
-- Events & Rebuild
-------------------------------------------------------------------------------
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

local eF = CreateFrame("Frame")
eF:RegisterEvent("PLAYER_LOGIN")
eF:RegisterEvent("UNIT_AURA")
eF:RegisterEvent("PLAYER_REGEN_ENABLED")
eF:RegisterEvent("MERCHANT_SHOW")

eF:SetScript("OnUpdate", function(self, elapsed)
    pulseTimer = pulseTimer + elapsed
    if pulseTimer >= CHECK_INTERVAL then
        -- We use pulseTimer only for the sin wave, but reuse it for the ticker
        UpdateVisibility()
    end
end)

eF:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        for k, v in pairs(cfg.defaults) do if TankBuffReminderDB[k] == nil then TankBuffReminderDB[k] = v end end
        if TankBuffReminderDB.f1_pos then 
            frame:SetPoint(TankBuffReminderDB.f1_pos.p, UIParent, TankBuffReminderDB.f1_pos.rp, TankBuffReminderDB.f1_pos.x, TankBuffReminderDB.f1_pos.y) 
        else frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150) end
        ApplyScale(frame, TankBuffReminderDB.scale or 1)
        TankBuffReminder_RebuildTrackedBuffs()
    elseif event == "MERCHANT_SHOW" then
        if TankBuffReminderDB.autoRepair and CanMerchantRepair() then
            local cost = GetRepairAllCost()
            if cost > 0 and GetMoney() >= cost then RepairAllItems() end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if frame.needsSpell then
            frame:SetAttribute("spell1", frame.needsSpell)
            frame.needsSpell = nil
        end
        UpdateVisibility()
    else
        UpdateVisibility()
    end
end)

frame:SetAlpha(0.001)