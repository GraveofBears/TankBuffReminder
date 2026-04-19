-- TankBuffReminder.lua
local BASE_SIZE = 64
local SCALE_MIN, SCALE_MAX = 0.5, 3.0

local cfg = TankBuffReminderConfig
local trackedBuffs = {} 
local soundPlayed = false
local frameThrottle = 0 

-- Localize globals for peak performance
local UnitBuff, GetSpellInfo, InCombatLockdown, GetTime = UnitBuff, GetSpellInfo, InCombatLockdown, GetTime
local math_max, math_min = math.max, math.min

TankBuffReminderDB = TankBuffReminderDB or {}

-------------------------------------------------------------------------------
-- Animation & Visuals
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
        local duration = math_max(0.1, 2 / speed)
        f.ag:GetAnimations():SetDuration(duration)
        if f:GetAlpha() > 0.05 and not f.ag:IsPlaying() then f.ag:Play() end
    else
        f.ag:Stop()
        f:SetAlpha(1)
        f.glow:SetAlpha(0.6)
    end
end

local function ApplyGlowSettings(f)
    if not f or not f.glow then return end
    local ratio = TankBuffReminderDB.glowSize or 1.5
    local size = f:GetWidth() * (ratio * 1.2) 
    f.glow:SetSize(size, size)
    local c = TankBuffReminderDB.glowColor or {r=1, g=1, b=0.6, a=1}
    f.glow:SetVertexColor(c.r, c.g, c.b, c.a)
end

local function ApplyScale(f, scale)
    TankBuffReminderDB.scale = math_max(SCALE_MIN, math_min(SCALE_MAX, scale or 1))
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

-------------------------------------------------------------------------------
-- Automation & Logic
-------------------------------------------------------------------------------
local function CheckSalvation()
    if not TankBuffReminderDB.autoRemoveSalvation then return end
    for i = 1, 40 do
        local _, _, _, _, _, _, _, _, _, _, spellID = UnitBuff("player", i)
        if not spellID then break end
        if spellID == 1038 or spellID == 25895 then 
            CancelUnitBuff("player", i) 
        end
    end
end

local function HasBuff(entry)
    -- Gift/Mark of the Wild Logic
    if entry.spellID == 26990 or entry.spellID == 26991 then
        for i = 1, 40 do
            local name = UnitBuff("player", i)
            if not name then break end
            if name == entry.name or name == "Gift of the Wild" or name == "Mark of the Wild" then 
                return true 
            end
        end
        return false
    end
    -- Standard Name-based check
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        if name == entry.name then return true end
    end
    return false
end

function UpdateVisibility()
    CheckSalvation()
    local missing = nil
    for i = 1, #trackedBuffs do
        local entry = trackedBuffs[i]
        if not HasBuff(entry) then
            missing = entry
            break
        end
    end

    local f = TankBuffReminderFrame
    if not f then return end

    if not missing then
        soundPlayed = false
        if f.ag:IsPlaying() then f.ag:Stop() end
        f:SetAlpha(0) 
        if not InCombatLockdown() then f:SetAttribute("spell1", nil) end
    else
        if not soundPlayed and (TankBuffReminderDB.playSound ~= false) then
            PlaySound(TankBuffReminderDB.soundID or 8959, "Master")
            soundPlayed = true
        end
        if not InCombatLockdown() then
            f:SetAttribute("spell1", missing.name)
        else
            f.needsSpell = missing.name
        end
        f.icon:SetTexture(missing.icon)
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
        if isClass and TankBuffReminderDB[b.key] ~= false then 
            local name, _, icon = GetSpellInfo(b.spellID)
            if name then
                table.insert(trackedBuffs, { spellID = b.spellID, name = name, icon = icon }) 
            end
        end
    end
    UpdateVisibility()
end

-------------------------------------------------------------------------------
-- Frame Initialization & Handlers
-------------------------------------------------------------------------------
local frame = CreateFrame("Button", "TankBuffReminderFrame", UIParent, "SecureActionButtonTemplate")
frame:SetSize(BASE_SIZE, BASE_SIZE)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(true)
frame:RegisterForClicks("AnyUp", "AnyDown")

-- Force Self-Cast Attributes
frame:SetAttribute("type1", "spell")
frame:SetAttribute("unit", "player")
frame:SetAttribute("checkselfcast", true)

frame.glow = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
frame.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
frame.glow:SetBlendMode("ADD")
frame.glow:SetPoint("CENTER")

frame.icon = frame:CreateTexture(nil, "ARTWORK")
frame.icon:SetAllPoints()
frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

SetupAnimations(frame)

-- DRAG HANDLER (Restored)
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

-- RESIZE HANDLER (Restored)
frame:SetResizable(true)
local resize = CreateFrame("Frame", nil, frame)
resize:SetPoint("BOTTOMRIGHT")
resize:SetSize(16, 16)
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

local eF = CreateFrame("Frame")
eF:RegisterEvent("PLAYER_LOGIN")
eF:RegisterEvent("UNIT_AURA")
eF:RegisterEvent("PLAYER_REGEN_ENABLED")
eF:RegisterEvent("MERCHANT_SHOW")

eF:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        for k, v in pairs(cfg.defaults) do if TankBuffReminderDB[k] == nil then TankBuffReminderDB[k] = v end end
        if TankBuffReminderDB.f1_pos then 
            frame:ClearAllPoints()
            frame:SetPoint(TankBuffReminderDB.f1_pos.p, UIParent, TankBuffReminderDB.f1_pos.rp, TankBuffReminderDB.f1_pos.x, TankBuffReminderDB.f1_pos.y) 
        else 
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150) 
        end
        ApplyScale(frame, TankBuffReminderDB.scale or 1)
        TankBuffReminder_RebuildTrackedBuffs()
    elseif event == "MERCHANT_SHOW" then
        if TankBuffReminderDB.autoRepair and CanMerchantRepair() then
            local cost = GetRepairAllCost()
            if cost > 0 and GetMoney() >= cost then RepairAllItems() end
        end
    else
        local now = GetTime()
        if (now - frameThrottle) > 0.2 then
            if event == "PLAYER_REGEN_ENABLED" and frame.needsSpell then
                frame:SetAttribute("spell1", frame.needsSpell)
                frame.needsSpell = nil
            end
            UpdateVisibility()
            frameThrottle = now
        end
    end
end)