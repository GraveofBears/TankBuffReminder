-- TankBuffReminder.lua

local CHECK_INTERVAL = 1.0
local BASE_SIZE = 64
local SCALE_MIN = 0.5
local SCALE_MAX = 3.0

-------------------------------------------------------------------------------
-- Load config
-------------------------------------------------------------------------------
local cfg = TankBuffReminderConfig

-------------------------------------------------------------------------------
-- Runtime variables
-------------------------------------------------------------------------------
local currentSpellID = nil
local trackedBuffs = nil
local soundPlayed = false
local initialLoadDone = false

TankBuffReminderDB = TankBuffReminderDB or {}
local db = TankBuffReminderDB

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

-- Logic to apply glow size and color (Scales with the icon)
local function ApplyGlowSettings(frame)
    if not frame.glow then return end
    
    -- Apply Size based on current frame width * glow ratio
    local ratio = TankBuffReminderDB.glowSize or cfg.defaults.glowSize or 1.5
    local size = frame:GetWidth() * ratio
    frame.glow:SetSize(size, size)
    
    -- Apply Color from config
    local c = TankBuffReminderDB.glowColor or cfg.defaults.glowColor
    frame.glow:SetVertexColor(c.r, c.g, c.b, c.a)
end

local function ApplyScale(frame, scale)
    scale = math.max(SCALE_MIN, math.min(SCALE_MAX, scale or 1))
    local size = BASE_SIZE * scale
    frame:SetWidth(size)
    frame:SetHeight(size)
    db.scale = scale
    ApplyGlowSettings(frame) -- Ensure glow scales with icon
end

-- Global function for Options.lua to trigger visual updates
function TankBuffReminder_UpdateGlow()
    ApplyGlowSettings(TankBuffReminderFrame)
end

local function HasBuff(spellID)
    local targetName = GetSpellInfo(spellID)

    -- Special case: Mark of the Wild satisfied by Gift of the Wild
    if spellID == 26990 then
        local giftName = GetSpellInfo(26991)
        for i = 1, 40 do
            local name, _, _, _, _, _, _, _, _, _, auraSpellID = UnitBuff("player", i)
            if not name then break end
            if auraSpellID == 26991 or name == giftName then
                return true
            end
        end
    end

    -- Normal buff check
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
frame:EnableMouse(true)
frame:SetClampedToScreen(true)
frame:RegisterForClicks("AnyUp", "AnyDown")

-- Force targeting player
frame:SetAttribute("unit", "player")
frame:SetAttribute("type1", "spell")
frame:SetAttribute("spell1", "")

-- Create Glow Texture (In BACKGROUND layer so it's behind the icon)
local glow = frame:CreateTexture(nil, "BACKGROUND")
glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
glow:SetBlendMode("ADD")
glow:SetPoint("CENTER", frame, "CENTER")
frame.glow = glow

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
    if self:GetAlpha() < 0.5 then 
        glow:SetAlpha(0)
        return 
    end

    local speed = TankBuffReminderDB.pulseSpeed or cfg.defaults.pulseSpeed
    if speed <= 0 then
        self:SetAlpha(1)
        glow:SetAlpha(0.6)
        return
    end

    pulseTimer = pulseTimer + elapsed
    local alpha = 0.75 + math.sin(pulseTimer * speed) * 0.25
    self:SetAlpha(alpha)
    glow:SetAlpha(alpha - 0.2) -- Sync glow pulse with icon pulse
end)

-------------------------------------------------------------------------------
-- UpdateVisibility
-------------------------------------------------------------------------------
function UpdateVisibility()
    local missingID, missingName, texture = GetFirstMissingSpell()

    if not missingID then
        currentSpellID = nil
        soundPlayed = false
        frame:SetAlpha(0.02)
        glow:SetAlpha(0)
        icon:SetTexture(texture or icon:GetTexture() or "Interface\\Icons\\INV_Misc_QuestionMark")
        return
    end

    if frame:GetAlpha() <= 0.05 and not soundPlayed then
        if TankBuffReminderDB.playSound ~= false then
            local sID = TankBuffReminderDB.soundID or cfg.defaults.soundID
            PlaySound(sID, "Master")
        end
        soundPlayed = true
    end

    currentSpellID = missingID

    if not InCombatLockdown() then
        frame:SetAttribute("type1", "spell")
        frame:SetAttribute("spell1", missingName)
    else
        frame.needsSpell = missingName
    end

    icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    frame:SetAlpha(1)
end

-------------------------------------------------------------------------------
-- Rebuild tracking list
-------------------------------------------------------------------------------
function TankBuffReminder_RebuildTrackedBuffs()
    trackedBuffs = {}
    local _, class = UnitClass("player")

    for _, buff in ipairs(cfg.buffs) do
        local isMyClass = false
        if class == "PALADIN" and (buff.key == "righteousFury" or buff.key == "devotionAura") then
            isMyClass = true
        elseif class == "DRUID" and (buff.key == "thorns" or buff.key == "markOfTheWild" or buff.key == "omenOfClarity") then
            isMyClass = true
        elseif class == "WARRIOR" and (buff.key == "battleShout" or buff.key == "commandingShout" or buff.key == "defensiveStance") then
            isMyClass = true
        end

        if isMyClass then
            if TankBuffReminderDB[buff.key] ~= false then
                table.insert(trackedBuffs, buff)
            end
        end
    end

    UpdateVisibility()
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
    if event == "PLAYER_LOGIN" then
        -- Initialize Database with Defaults
        if TankBuffReminderDB.playSound == nil then TankBuffReminderDB.playSound = cfg.defaults.playSound end
        if TankBuffReminderDB.pulseSpeed == nil then TankBuffReminderDB.pulseSpeed = cfg.defaults.pulseSpeed end
        if TankBuffReminderDB.soundID == nil then TankBuffReminderDB.soundID = cfg.defaults.soundID end
        if TankBuffReminderDB.glowSize == nil then TankBuffReminderDB.glowSize = cfg.defaults.glowSize end
        if TankBuffReminderDB.glowColor == nil then TankBuffReminderDB.glowColor = cfg.defaults.glowColor end
        
        TankBuffReminder_RebuildTrackedBuffs()
        ApplyGlowSettings(frame)

        if not initialLoadDone then
            local _, class = UnitClass("player")
            print("|cff00ccff[TankBuffReminder]|r Loaded for " .. class)
            initialLoadDone = true
        end
        C_Timer.After(0.5, UpdateVisibility)

    elseif event == "PLAYER_ENTERING_WORLD" then
        UpdateVisibility()

    elseif event == "UNIT_AURA" and unit == "player" then
        UpdateVisibility()

    elseif event == "PLAYER_REGEN_ENABLED" then
        if frame.needsSpell then
            frame:SetAttribute("type1", "spell")
            frame:SetAttribute("spell1", frame.needsSpell)
            frame.needsSpell = nil
        end
        UpdateVisibility()
    end
end)

frame:SetAlpha(0.001)