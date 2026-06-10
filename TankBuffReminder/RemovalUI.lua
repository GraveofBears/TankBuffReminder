-- RemovalUI.lua

local L   = TBR_L
local cfg = TankBuffReminderConfig

local math_sin       = math.sin
local math_pi        = math.pi
local TWO_PI         = 2 * math_pi
local PULSE_INTERVAL = 0.20

-------------------------------------------------------------------------------
-- Anchor frame
-------------------------------------------------------------------------------
local anchor = CreateFrame("Frame", "TBR_RemovalAnchor", UIParent, "BackdropTemplate")
anchor:SetMovable(true)
anchor:SetClampedToScreen(true)
anchor:SetFrameStrata("DIALOG")
anchor:SetAlpha(0)
anchor:Show()

anchor:SetScript("OnMouseDown", function(self, btn)
    if btn == "LeftButton"
       and TankBuffReminderCharDB and TankBuffReminderCharDB.removalUnlocked
       and not InCombatLockdown() then
        self:StartMoving()
        self.isMoving = true
    end
end)
anchor:SetScript("OnMouseUp", function(self)
    if self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
        if TankBuffReminderDB then
            local p, _, rp, x, y = self:GetPoint()
            TankBuffReminderDB.removalPos = { p = p, rp = rp, x = x, y = y }
        end
    end
end)

-------------------------------------------------------------------------------
-- Button factory 
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Button factory 
-------------------------------------------------------------------------------
local removalBtns = {}

for _, def in ipairs(cfg.autoRemove) do
    local _, _, defaultIcon = GetSpellInfo(def.spellID)

    local btn = CreateFrame("Button", "TBR_Removal_" .. def.key,
                            anchor, "SecureActionButtonTemplate")
    
    -- Using 'macro' type allows us to bundle all name variations into one click
    btn:SetAttribute("type", "macro")
    
    local macroText = ""
    for _, name in ipairs(def.watchNames) do
        macroText = macroText .. "/cancelaura " .. name .. "\n"
    end
    btn:SetAttribute("macrotext", macroText)

    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetSize(40, 40)

    -- Icon
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if defaultIcon then icon:SetTexture(defaultIcon) end
    btn.icon = icon

    -- Red "X" badge
    local badge = btn:CreateTexture(nil, "OVERLAY")
    badge:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    badge:SetSize(18, 18)
    badge:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 3, -3)

    -- Pulsing red glow
    local glow = btn:CreateTexture(nil, "ARTWORK")
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(1, 0.1, 0.1, 1)
    glow:SetPoint("CENTER", btn, "CENTER", 0, 0)
    glow:SetSize(88, 88)
    btn.glow = glow

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(def.spellID)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    btn:Show()    
    btn:SetAlpha(0)
    btn.active = false
    btn.def    = def
    btn.index  = _

    removalBtns[def.key] = btn
end

-------------------------------------------------------------------------------
-- Pulse OnUpdate
-------------------------------------------------------------------------------
local pulseTimer   = 0
local pulseElapsed = 0

anchor:SetScript("OnUpdate", function(self, elapsed)
    pulseElapsed = pulseElapsed + elapsed
    if pulseElapsed < PULSE_INTERVAL then return end
    pulseElapsed = 0
    pulseTimer = (pulseTimer + PULSE_INTERVAL * 4) % TWO_PI
    local wave = 0.5 + math_sin(pulseTimer) * 0.5
    for _, btn in pairs(removalBtns) do
        if btn.active and btn.glow then
            btn.glow:SetAlpha(wave)
        end
    end
end)

-------------------------------------------------------------------------------
-- ApplyScale
-------------------------------------------------------------------------------
local function ApplyScale(scale, spacing)
    local btnSize = math.max(24, 40 * scale)
    for _, btn in pairs(removalBtns) do
        btn:SetSize(btnSize, btnSize)
        btn.glow:SetSize(btnSize * 2.2, btnSize * 2.2)
    end
    local numBtns = #cfg.autoRemove
    anchor:SetSize(numBtns * (btnSize + spacing * scale) + 8, btnSize + 8)
end

-------------------------------------------------------------------------------
-- TBR_RemovalUI_Update
-------------------------------------------------------------------------------
function TBR_RemovalUI_Update(buffStates)
    if not TankBuffReminderCharDB then return end

    local charDB    = TankBuffReminderCharDB
    local globalDB  = TankBuffReminderDB or {}
    local scale     = globalDB.removalScale   or 1.0
    local spacing   = globalDB.removalSpacing or 4
    local isUnlocked = charDB.removalUnlocked
    local inCombat   = InCombatLockdown()

    if not inCombat then
        ApplyScale(scale, spacing)
    end

    local btnSize    = math.max(24, 40 * scale)
    local anyVisible = false

    for _, def in ipairs(cfg.autoRemove) do
        local btn        = removalBtns[def.key]
        local showIcon   = charDB[def.showIconDbKey]
        local autoRemove = charDB[def.dbKey]
        local isActive   = buffStates and buffStates[def.key]

        local shouldShow = isUnlocked
                        or (isActive and showIcon)
                        or (isActive and autoRemove and inCombat)

        if shouldShow then
            -- We only update the icon display, NOT the secure attribute
            if not inCombat then
                local _, _, icon = GetSpellInfo(def.spellID)
                if icon then btn.icon:SetTexture(icon) end
            end

            btn.active = true
            anyVisible = true
            btn:SetAlpha(1)
        else
            btn.active = false
            btn:SetAlpha(0)
        end
    end

    if not inCombat then
        local xOffset = 4 * scale
        local count   = 0
        for _, def in ipairs(cfg.autoRemove) do
            local btn = removalBtns[def.key]
            if btn.active then
                btn:ClearAllPoints()
                btn:SetPoint("LEFT", anchor, "LEFT", xOffset, 0)
                xOffset = xOffset + btnSize + (spacing * scale)
                count = count + 1
            end
        end

        local usedWidth
        if count > 0 then
            usedWidth = count * (btnSize + spacing * scale) - (spacing * scale) + 8
        else
            usedWidth = btnSize + 8
        end
        anchor:SetWidth(math.max(btnSize + 8, usedWidth))
    end

    if isUnlocked then
        anchor:SetAlpha(1)
        if not inCombat then anchor:EnableMouse(true) end
        anchor:SetBackdropBorderColor(1, 0.15, 0.15, 0.9)
    elseif anyVisible then
        anchor:SetAlpha(1)
        if not inCombat then anchor:EnableMouse(false) end
        anchor:SetBackdropBorderColor(0, 0, 0, 0)
    else
        anchor:SetAlpha(0)
        if not inCombat then anchor:EnableMouse(false) end
    end
end

-------------------------------------------------------------------------------
-- Restore saved position on login
-------------------------------------------------------------------------------
anchor:RegisterEvent("PLAYER_LOGIN")
anchor:SetScript("OnEvent", function(self)
    self:ClearAllPoints()
    if TankBuffReminderDB and TankBuffReminderDB.removalPos then
        local p = TankBuffReminderDB.removalPos
        local point = p.p or "CENTER"
        local relativePoint = p.rp or "CENTER"
        
        self:SetPoint(point, UIParent, relativePoint, p.x or 0, p.y or -180)
    else
        self:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
    end
end)