-- FrameUI.lua
local cfg = TankBuffReminderConfig

local BASE_SIZE      = cfg.defaults.buffBaseSize or 48
local PULSE_INTERVAL = 0.20
local SCALE_MIN      = cfg.defaults.buffScaleMin or 0.5
local SCALE_MAX      = cfg.defaults.buffScaleMax or 3.0

local math_max, math_min, math_sin, math_pi, InCombatLockdown =
      math.max, math.min, math.sin, math.pi, InCombatLockdown

-- Pools
local glowPool = {}
local slots = {}
local framePool = {}
local slotPool = {}

-- Pre-allocated aura cache
local currentAuraCache = {}
local _auraCachePool = {}
do
    for i = 1, 40 do
        _auraCachePool[i] = { dur = 0, exp = 0 }
    end
end

local pulseTimer, pulseElapsed = 0, 0
local TWO_PI = 2 * math_pi

-------------------------------------------------------------------------------
-- Glow Pooling
-------------------------------------------------------------------------------
local function GetOrCreateGlow(parent)
    local glow = table.remove(glowPool)
    if not glow then
        glow = parent:CreateTexture(nil, "OVERLAY")
        glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        glow:SetBlendMode("ADD")
    end
    glow:SetParent(parent)
    glow:ClearAllPoints()
    glow:SetPoint("CENTER", parent, "CENTER", 0, 0)
    glow:Show()
    return glow
end

local function ReleaseGlow(glow)
    if glow then
        glow:Hide()
        glow:ClearAllPoints()
        glow:SetParent(nil)
        table.insert(glowPool, glow)
    end
end

-------------------------------------------------------------------------------
-- Anchor Frame
-------------------------------------------------------------------------------
local anchor = CreateFrame("Frame", "TankBuffReminderFrame", UIParent, "BackdropTemplate")
anchor:SetMovable(true)
anchor:SetClampedToScreen(true)
anchor:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
anchor:SetFrameStrata("MEDIUM")
anchor:EnableMouse(true)

anchor.bg = anchor:CreateTexture(nil, "BACKGROUND")
anchor.bg:SetAllPoints()
anchor.bg:SetColorTexture(0, 0, 0, 0.3)

anchor:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, tileSize = 0, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
anchor:SetBackdropBorderColor(1, 1, 1, 0.4)

anchor:SetScript("OnMouseDown", function(self, button)
    if not InCombatLockdown() and button == "LeftButton" and IsShiftKeyDown() then
        self:StartMoving()
        self.isMoving = true
    end
end)

anchor:SetScript("OnMouseUp", function(self)
    if self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
        if not InCombatLockdown() and TankBuffReminderDB then
            local p, _, rp, x, y = self:GetPoint()
            TankBuffReminderDB.f1_pos = { p = p, rp = rp, x = x, y = y }
        end
    end
end)

-- Clean parent pass-through bounds routing
anchor:SetPropagateMouseMotion(true)
anchor:SetPropagateMouseClicks(true)

-------------------------------------------------------------------------------
-- Public Scale API
-------------------------------------------------------------------------------
function TBR_UI_SetScale(value)
    local newScale = math_max(SCALE_MIN, math_min(SCALE_MAX, value))
    TankBuffReminderDB.scale = newScale
    TBR_UI_Rebuild()
end

-------------------------------------------------------------------------------
-- Visual Helpers
-------------------------------------------------------------------------------
function TankBuffReminder_UpdateGlow()
    local db = TankBuffReminderCharDB
    local color = db.glowColor or cfg.defaults.glowColor
    local sizeMult = db.glowSize or 1.8
    local currentSize = BASE_SIZE * (TankBuffReminderDB.scale or 1)

    for _, slot in ipairs(slots) do
        if slot.glow then
            slot.glow:SetVertexColor(color.r, color.g, color.b, color.a)
            slot.glow:SetSize(currentSize * sizeMult, currentSize * sizeMult)
        end
    end
end

function TBR_UI_UpdateAlpha()
    local db = TankBuffReminderCharDB
    local frameAlpha = db.frameAlpha or 1.0
    local currentBGAlpha = anchor.anyMissing and frameAlpha or (frameAlpha * 0.4)

    if anchor.bg then anchor.bg:SetAlpha(currentBGAlpha) end
    anchor:SetBackdropBorderColor(1, 1, 1, currentBGAlpha)
end

local function CacheCooldownText(slot)
    if slot.cdText then return slot.cdText end
    local count = slot.cd:GetNumRegions()
    for i = 1, count do
        local region = select(i, slot.cd:GetRegions())
        if region and region.IsObjectType and region:IsObjectType("FontString") then
            slot.cdText = region
            return region
        end
    end
    return nil
end

function TBR_UI_UpdateTimerStyle()
    local db = TankBuffReminderCharDB
    local offsetY = db.timerTextOffsetY or 0
    local tc = db.timerTextColor or cfg.defaults.timerTextColor
    local tAlpha = db.timerAlpha or 1.0
    local sweepAlpha = db.sweepAlpha or 0.6
    local fontSize = db.timerFontSize or 12

    for _, slot in ipairs(slots) do
        local cd = slot.cd
        if cd.SetDrawSwipe then
            cd:SetDrawSwipe(sweepAlpha > 0)
            cd:SetSwipeColor(0, 0, 0, sweepAlpha)
        end
        cd:SetHideCountdownNumbers(false)

        local fs = CacheCooldownText(slot)
        if fs then
            fs:ClearAllPoints()
            fs:SetPoint("CENTER", cd, "CENTER", 0, offsetY)
            fs:SetTextColor(tc.r, tc.g, tc.b, tAlpha)
            local fontPath, _, fontFlags = fs:GetFont()
            if fontPath then
                fs:SetFont(fontPath, fontSize, fontFlags or "OUTLINE")
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Main Update Loop
-------------------------------------------------------------------------------
anchor:SetScript("OnUpdate", function(self, elapsed)
    pulseElapsed = pulseElapsed + elapsed
    if pulseElapsed < PULSE_INTERVAL then return end

    local db = TankBuffReminderCharDB
    local speed = db.pulseSpeed or 4

    pulseTimer = (pulseTimer + (pulseElapsed * speed)) % TWO_PI
    pulseElapsed = 0

    local alphaWave = 0.75 + math_sin(pulseTimer) * 0.25
    local userBuffAlpha = db.buffAlpha or 1.0
    
    -- Check Shift state dynamically on update loops
    local isShift = IsShiftKeyDown()
    local inCombat = InCombatLockdown()

    -- Safety check: Force drop attachment if shift is released off-frame during drag
    if self.isMoving and not isShift then
        self:StopMovingOrSizing()
        self.isMoving = false
        if TankBuffReminderDB then
            local p, _, rp, x, y = self:GetPoint()
            TankBuffReminderDB.f1_pos = { p = p, rp = rp, x = x, y = y }
        end
    end

    for i = 1, #slots do
        local slot = slots[i]
        local btn = slot.btn
        local isMissing = (slot.isMissing == true)

        -- Dynamically manage click-mask overlay visibility based on key environment
        if btn.dragMask then
            if isShift and not inCombat then
                btn.dragMask:Show()
            else
                btn.dragMask:Hide()
            end
        end

        if isMissing then
            slot.icon:SetAlpha(1.0)
            slot.icon:SetDesaturated(false)
            
            if slot.glow then
                slot.glow:Show()
                slot.glow:SetAlpha(alphaWave)
            end
            
            local sAlpha = db.sweepAlpha or 0.6
            slot.cd:SetSwipeColor(0, 0, 0, sAlpha)
        else
            if slot.glow then
                slot.glow:Hide()
            end
            
            slot.icon:SetAlpha(userBuffAlpha * 0.4)
            slot.icon:SetDesaturated(true)
            slot.cd:SetSwipeColor(0.1, 0.1, 0.1, userBuffAlpha * 0.55)
        end
    end
end)

-------------------------------------------------------------------------------
-- Slot Factory (Must be global)
-------------------------------------------------------------------------------
function MakeSlot(index, entry, currentSize)
    local spellName, _, iconTex = GetSpellInfo(entry.spellID)
    if not spellName then return nil end

    local btn = table.remove(framePool)
    local slot = table.remove(slotPool) or {}

    if not btn then
        btn = CreateFrame("Button", "TBR_Slot" .. (#slots + #framePool + 1), anchor, "SecureActionButtonTemplate")
        btn:RegisterForClicks("AnyUp", "AnyDown")
        btn:SetAttribute("unit", "player")

        -- Clear internal event leakage 
        btn:SetPropagateMouseMotion(true)
        btn:SetPropagateMouseClicks(false)

        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetAllPoints()
        btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        btn.cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
        btn.cd:SetAllPoints()
        btn.cd:SetDrawEdge(false)

        btn.glow = GetOrCreateGlow(btn)

        -- Shift-Drag Mask Interceptor Frame
        local mask = CreateFrame("Frame", nil, btn)
        mask:SetAllPoints()
        mask:EnableMouse(true)
        mask:Hide()
        btn.dragMask = mask

        mask:SetScript("OnMouseDown", function(self, button)
            local p = self:GetParent():GetParent()
            if p:GetScript("OnMouseDown") then p:GetScript("OnMouseDown")(p, button) end
        end)
        mask:SetScript("OnMouseUp", function(self, button)
            local p = self:GetParent():GetParent()
            if p:GetScript("OnMouseUp") then p:GetScript("OnMouseUp")(p, button) end
        end)

        btn:SetScript("OnEnter", function(self)
            if not anchor.isMoving then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(self.currentSpellID)
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    else
        if not btn.glow then
            btn.glow = GetOrCreateGlow(btn)
        end
    end

    btn:SetAttribute("type", "spell")
    btn:SetAttribute("spell", spellName)
    btn:SetSize(currentSize, currentSize)
    btn.icon:SetTexture(iconTex)
    btn.currentSpellID = entry.spellID

    local spacing = TankBuffReminderCharDB.buttonPadding or 4
    btn:SetPoint("LEFT", anchor, "LEFT", (index - 1) * (currentSize + spacing) + 4, 0)
    btn:Show()

    slot.btn = btn
    slot.icon = btn.icon
    slot.glow = btn.glow
    slot.cd = btn.cd
    slot.key = entry.key
    slot.spellID = entry.spellID
    slot.isMissing = false

    return slot
end

-------------------------------------------------------------------------------
-- Rebuild & Update
-------------------------------------------------------------------------------
function TBR_UI_Update(buffStates, anyMissing)
    anchor.anyMissing = anyMissing or false

    table.wipe(currentAuraCache)
    local poolIdx = 0
    for i = 1, 40 do
        local name, _, _, _, duration, expirationTime = UnitBuff("player", i)
        if not name then break end
       
        poolIdx = poolIdx + 1
        local cacheEntry = _auraCachePool[poolIdx]
        cacheEntry.dur = duration or 0
        cacheEntry.exp = expirationTime or 0
        currentAuraCache[name] = cacheEntry
    end

    for _, slot in ipairs(slots) do
        slot.isMissing = (buffStates and buffStates[slot.key] == true)

        local spellName = GetSpellInfo(slot.spellID)
        local aura = spellName and currentAuraCache[spellName]

        if aura and aura.dur and aura.dur > 0 then
            local start = aura.exp - aura.dur
            local currentStart, currentDur = slot.cd:GetCooldownTimes()
           
            if math.abs((currentStart / 1000) - start) > 0.1 or math.abs((currentDur / 1000) - aura.dur) > 0.1 then
                slot.cd:SetCooldown(start, aura.dur)
                slot.cd:Show()
            end
        else
            slot.cd:Hide()
        end
    end

    TBR_UI_UpdateAlpha()
end

function TBR_UI_Rebuild()
    -- Clean up existing slots
    for _, slot in ipairs(slots) do
        if slot.btn then
            slot.btn:Hide()
            if slot.btn.glow then
                ReleaseGlow(slot.btn.glow)
                slot.btn.glow = nil
            end
            if slot.btn.dragMask then slot.btn.dragMask:Hide() end
            table.insert(framePool, slot.btn)
        end
        table.wipe(slot)
        table.insert(slotPool, slot)
    end
    table.wipe(slots)

    local tracked = TBR_GetTrackedBuffs()
    if not tracked or #tracked == 0 then
        anchor:Hide()
        return
    end

    anchor:Show()
    TBR_UI_UpdateAlpha()

    local scale = TankBuffReminderDB.scale or 1
    local currentSize = BASE_SIZE * scale
    local spacing = TankBuffReminderCharDB.buttonPadding or 4
    local padding = 8

    local totalWidth = (currentSize * #tracked) + (spacing * (#tracked - 1)) + padding
    anchor:SetSize(totalWidth, currentSize + padding)

    for i, entry in ipairs(tracked) do
        local slot = MakeSlot(i, entry, currentSize)
        if slot then
            slot.btn:ClearAllPoints()
            slot.btn:SetPoint("LEFT", anchor, "LEFT", (i - 1) * (currentSize + spacing) + 4, 0)
            table.insert(slots, slot)
        end
    end

    TankBuffReminder_UpdateGlow()
    TBR_UI_UpdateTimerStyle()

    if TankBuffReminderDB.f1_pos then
        local p = TankBuffReminderDB.f1_pos
        anchor:ClearAllPoints()
        anchor:SetPoint(p.p, UIParent, p.rp, p.x, p.y)
    end
end