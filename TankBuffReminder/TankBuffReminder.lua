-- TankBuffReminder.lua

local CHECK_INTERVAL = 1.0
local BASE_SIZE = 64
local SCALE_MIN = 0.5
local SCALE_MAX = 3.0

-------------------------------------------------------------------------------
-- Buff list by class
-------------------------------------------------------------------------------
local CLASS_BUFFS = {
    PALADIN = {
        { spellID = 25780, name = "Righteous Fury" },
    },
    DRUID = {
        { spellID = 26992, name = "Thorns" },
        { spellID = 26990, name = "Mark of the Wild" },
        { spellID = 16864, name = "Omen of Clarity" },
    },
}

-------------------------------------------------------------------------------
-- Runtime variables
-------------------------------------------------------------------------------
local currentSpellID = nil
local trackedBuffs = nil
local soundPlayed = false

TankBuffReminderDB = TankBuffReminderDB or {}
local db = TankBuffReminderDB

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------
local function ApplyScale(frame, scale)
    scale = math.max(SCALE_MIN, math.min(SCALE_MAX, scale or 1))
    local size = BASE_SIZE * scale
    frame:SetWidth(size)
    frame:SetHeight(size)
    db.scale = scale
end

local function HasBuff(spellID)
    local targetName = GetSpellInfo(spellID)
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, auraSpellID = UnitBuff("player", i)
        if not name then break end
        if auraSpellID == spellID or name == targetName then
            return true
        end
    end
    return false
end

local function GetFirstMissingSpell()
    if not trackedBuffs then return nil end

    for _, entry in ipairs(trackedBuffs) do
        local name, _, texture = GetSpellInfo(entry.spellID)
        if name and not HasBuff(entry.spellID) then
            return entry.spellID, name, texture
        end
    end
    return nil
end

-------------------------------------------------------------------------------
-- Main frame (Secure)
-------------------------------------------------------------------------------
local frame = CreateFrame("Button", "TankBuffReminderFrame", UIParent, "SecureActionButtonTemplate")
frame:SetMovable(true)
frame:EnableMouse(true) -- always clickable
frame:SetClampedToScreen(true)
frame:RegisterForClicks("AnyUp", "AnyDown")

frame:SetAttribute("type1", "macro")
frame:SetAttribute("macrotext1", "")

if db.point then
    frame:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
else
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
end
ApplyScale(frame, db.scale or 1)

local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints()
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local border = frame:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
border:SetVertexColor(1, 1, 1, 0.15)
border:SetAllPoints()

-------------------------------------------------------------------------------
-- Tooltip
-------------------------------------------------------------------------------
frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if currentSpellID then
        GameTooltip:SetSpellByID(currentSpellID)
    else
        GameTooltip:SetText("Tank Buff Reminder")
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click to cast", 1, 1, 1)
    GameTooltip:AddLine("Shift + drag to move", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Drag bottom-right corner to resize", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

frame:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-------------------------------------------------------------------------------
-- Movement & Resize (combat-safe)
-------------------------------------------------------------------------------
frame:SetScript("OnMouseDown", function(self, button)
    if InCombatLockdown() then return end
    if button == "LeftButton" and IsShiftKeyDown() then
        self:StartMoving()
    end
end)

frame:SetScript("OnMouseUp", function(self)
    if InCombatLockdown() then return end
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    db.point = point
    db.relPoint = relPoint
    db.x = x
    db.y = y
end)

frame:SetResizable(true)
local resize = CreateFrame("Frame", nil, frame)
resize:SetPoint("BOTTOMRIGHT")
resize:SetSize(18, 18)
resize:EnableMouse(true)

local resizeTex = resize:CreateTexture(nil, "OVERLAY")
resizeTex:SetAllPoints()
resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

resize:SetScript("OnMouseDown", function(self)
    if InCombatLockdown() then return end
    self:GetParent():StartSizing("BOTTOMRIGHT")
end)

resize:SetScript("OnMouseUp", function(self)
    if InCombatLockdown() then return end
    local f = self:GetParent()
    f:StopMovingOrSizing()
    ApplyScale(f, f:GetWidth() / BASE_SIZE)
end)

-------------------------------------------------------------------------------
-- Pulse animation
-------------------------------------------------------------------------------
local pulseTimer = 0
frame:SetScript("OnUpdate", function(self, elapsed)
    if self:GetAlpha() < 0.5 then return end -- no pulse when dim
    pulseTimer = pulseTimer + elapsed
    local alpha = 0.75 + math.sin(pulseTimer * 4) * 0.25
    self:SetAlpha(alpha)
end)

-------------------------------------------------------------------------------
-- Update function (Always-clickable logic)
-------------------------------------------------------------------------------
local function UpdateVisibility()
    local missingID, missingName, texture = GetFirstMissingSpell()

    if not missingID then
        -- Buff is active: ultra-dim but still clickable
        currentSpellID = nil
        soundPlayed = false

        frame:SetAlpha(0.02)
        icon:SetTexture(texture or icon:GetTexture() or "Interface\\Icons\\INV_Misc_QuestionMark")

        return
    end

    -- Buff is missing
    if frame:GetAlpha() <= 0.05 and not soundPlayed then
        PlaySound(8959, "Master")
        soundPlayed = true
    end

    currentSpellID = missingID

    if not InCombatLockdown() then
        frame:SetAttribute("type1", "macro")
        frame:SetAttribute("macrotext1", "/cast " .. missingName)
    else
        frame.needsMacro = missingName
    end

    icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

    frame:SetAlpha(1)
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:HookScript("OnClick", function(self, button)
    if button == "LeftButton" and currentSpellID then
        C_Timer.After(0.7, UpdateVisibility)
    end
end)

local elapsedTotal = 0
eventFrame:SetScript("OnUpdate", function(self, elapsed)
    elapsedTotal = elapsedTotal + elapsed
    if elapsedTotal >= CHECK_INTERVAL then
        elapsedTotal = 0
        UpdateVisibility()
    end
end)

eventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        local _, class = UnitClass("player")
        trackedBuffs = CLASS_BUFFS[class]
        if not trackedBuffs then
            frame:SetAlpha(0.02)
            print("|cff00ccff[TankBuffReminder]|r Loaded - No buffs configured for your class.")
            return
        end
        print("|cff00ccff[TankBuffReminder]|r Loaded for " .. class)
        C_Timer.After(0.8, UpdateVisibility)

    elseif event == "UNIT_AURA" and unit == "player" then
        UpdateVisibility()

    elseif event == "PLAYER_REGEN_ENABLED" then
        if frame.needsMacro then
            frame:SetAttribute("type1", "macro")
            frame:SetAttribute("macrotext1", "/cast " .. frame.needsMacro)
            frame.needsMacro = nil
        end

        C_Timer.After(0, UpdateVisibility)
    end
end)

frame:SetAlpha(0.02)

print("|cff00ccff[TankBuffReminder]|r Loaded successfully! (Final Combat-Safe Version)")
