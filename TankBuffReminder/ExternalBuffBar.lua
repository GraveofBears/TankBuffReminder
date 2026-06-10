-- ExternalBuffBar.lua
-- Separate draggable bar for external (party/raid) buff tracking.
-- Mirrors FrameUI.lua architecture: same glow, pulse, sweep, timer system.
-- Click behaviour: announces missing buffs to a chosen chat channel.

local cfg            = TankBuffReminderConfig
local BASE_SIZE      = cfg.defaults.buffBaseSize or 48
local PULSE_INTERVAL = 0.20
local SCALE_MIN      = 0.5
local SCALE_MAX      = 3.0
local math_max, math_min, math_sin, math_pi, InCombatLockdown =
      math.max, math.min, math.sin, math.pi, InCombatLockdown
local TWO_PI = 2 * math_pi

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------
local extSlots      = {}   -- buff-bar slots
local extFramePool  = {}
local extSlotPool   = {}
local extGlowPool   = {}
local extAuraCache  = {}
local extCachePool  = {}
do for i = 1, 40 do extCachePool[i] = { dur = 0, exp = 0 } end end

-- Forward declaration — defined in full after the slot factory
local UpdateSlotsTimers

local extPulseTimer   = 0
local extPulseElapsed = 0

-- Per-buff missing state (key → bool), updated by TankBuffReminder.lua
TBR_ExtBuffStates = TBR_ExtBuffStates or {}

-- Sound throttle (shared — one alert covers both bars)
local extLastSoundTime  = 0
-- Per-buff state for sound alerts. Three states per key:
--   nil          = never seen (don't alert if missing at combat start)
--   "present"    = buff is currently active; eligible to alert if it drops
--   "alerted"    = buff dropped and sound has already fired; stay silent
local extBuffSeenState  = {}   -- persists across combat; wiped on zone/reload

-------------------------------------------------------------------------------
-- Glow pool
-------------------------------------------------------------------------------
local function ExtGetOrCreateGlow(parent)
    local glow = table.remove(extGlowPool)
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

local function ExtReleaseGlow(glow)
    if glow then
        glow:Hide(); glow:ClearAllPoints(); glow:SetParent(nil)
        table.insert(extGlowPool, glow)
    end
end

-------------------------------------------------------------------------------
-- Anchor frame  (Shift+drag to move; position saved to TankBuffReminderDB)
-------------------------------------------------------------------------------
local extAnchor = CreateFrame("Frame", "TBR_ExtBuffFrame", UIParent, "BackdropTemplate")
extAnchor:SetMovable(true)
extAnchor:SetClampedToScreen(true)
extAnchor:SetFrameStrata("MEDIUM")
extAnchor:EnableMouse(true)
extAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, -210)
extAnchor.posKey = "extBar_pos"

extAnchor.bg = extAnchor:CreateTexture(nil, "BACKGROUND")
extAnchor.bg:SetAllPoints()
extAnchor.bg:SetColorTexture(0, 0, 0, 0.3)
extAnchor:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false, tileSize = 0, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
extAnchor:SetBackdropBorderColor(1, 1, 1, 0.4)

extAnchor:SetScript("OnMouseDown", function(self, button)
    if not InCombatLockdown() and button == "LeftButton" and IsShiftKeyDown() then
        self:StartMoving(); self.isMoving = true
    end
end)
extAnchor:SetScript("OnMouseUp", function(self)
    if self.isMoving then
        self:StopMovingOrSizing(); self.isMoving = false
        if not InCombatLockdown() and TankBuffReminderDB then
            local p, _, rp, x, y = self:GetPoint()
            TankBuffReminderDB[self.posKey] = { p = p, rp = rp, x = x, y = y }
        end
    end
end)
extAnchor:SetPropagateMouseMotion(true)
extAnchor:SetPropagateMouseClicks(true)

-------------------------------------------------------------------------------
-- Chat announce helper
-------------------------------------------------------------------------------
local extAnnounceLastTime = 0
local EXT_ANNOUNCE_COOLDOWN = 4.0

-- Dispatch to the highest-priority checked channel that applies to the current
-- group state. Priority: Raid (if in raid) → Party (if in group) → Say → Yell.
-- Say and Yell use pcall because Blizzard can block them in certain contexts
-- (instances, some phasing states) and will throw a Lua error without it.
-- Self Warning fires only if no chat channel sent, matching taunt behaviour.
local function DispatchAnnounce(msg, db, sayKey, yellKey, partyKey, raidKey, warningKey)
    if db[raidKey] and IsInRaid() then
        SendChatMessage(msg, "RAID")
    elseif db[partyKey] and IsInGroup() then
        SendChatMessage(msg, "PARTY")
    elseif db[sayKey] then
        pcall(SendChatMessage, msg, "SAY")
    elseif db[yellKey] then
        pcall(SendChatMessage, msg, "YELL")
    elseif db[warningKey] then
        print("|cff00ccff[TBR]|r " .. msg)
    end
end

local function AnnounceExtMissing()
    local now = GetTime()
    if (now - extAnnounceLastTime) < EXT_ANNOUNCE_COOLDOWN then return end
    extAnnounceLastTime = now

    local db = TankBuffReminderCharDB
    if not db or not TankBuffReminderExternalBuffs then return end

    local missing  = {}
    local expiring = {}
    for _, entry in ipairs(TankBuffReminderExternalBuffs) do
        if db["ext_" .. entry.key] then
            if TBR_ExtBuffStates[entry.key] then
                table.insert(missing, entry.name)
            else
                -- Check if this slot is expiring
                for _, slot in ipairs(extSlots) do
                    if slot.key == entry.key and slot.isExpiring then
                        -- Find remaining time from aura cache
                        local aura = nil
                        if type(entry.buffName) == "table" then
                            for _, bn in ipairs(entry.buffName) do
                                aura = extAuraCache[bn]; if aura then break end
                            end
                        else
                            aura = extAuraCache[entry.buffName]
                        end
                        local secs = aura and math.max(1, math.floor(aura.exp - now)) or 0
                        table.insert(expiring, entry.name .. " (" .. secs .. "s)")
                        break
                    end
                end
            end
        end
    end

    if #missing == 0 and #expiring == 0 then return end

    local L   = TBR_L
    local parts = {}
    if #missing  > 0 then table.insert(parts, (L["EXT_BUFF_REQUEST_PREFIX"] or "Buffs needed: ") .. table.concat(missing, ", ")) end
    if #expiring > 0 then table.insert(parts, (L["EXT_BUFF_EXPIRING_PREFIX"] or "Expiring: ") .. table.concat(expiring, ", ")) end
    local msg = table.concat(parts, " | ")
    DispatchAnnounce(msg, db, "extSay", "extYell", "extParty", "extRaid", "extWarning")
end

-------------------------------------------------------------------------------
-- Slot factory
-------------------------------------------------------------------------------
local function ExtMakeSlot(index, entry, currentSize, anchor, announceFunc, tooltipKey)
    local btn = table.remove(extFramePool)
    local slot = table.remove(extSlotPool) or {}

    if not btn then
        btn = CreateFrame("Button", "TBR_ExtSlot" .. (#extSlots + #extFramePool + 1),
                          anchor, "SecureActionButtonTemplate")
        btn:RegisterForClicks("AnyUp")
        btn:SetAttribute("unit", "player")
        btn:SetPropagateMouseMotion(true)
        btn:SetPropagateMouseClicks(false)

        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetAllPoints()
        btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        btn.cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
        btn.cd:SetAllPoints()
        btn.cd:SetDrawEdge(false)

        btn.glow = ExtGetOrCreateGlow(btn)

        -- Drag mask (same pattern as main bar)
        local mask = CreateFrame("Frame", nil, btn)
        mask:SetAllPoints(); mask:EnableMouse(true); mask:Hide()
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
                local L = TBR_L
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if self.currentSpellID then
                    local idToDisplay = type(self.currentSpellID) == "table"
                                        and self.currentSpellID[1]
                                        or self.currentSpellID
                    GameTooltip:SetSpellByID(idToDisplay)
                end
                GameTooltip:AddLine("|cff888888" ..
                    (L[self.tooltipKey] or self.tooltipKey) ..
                    "|r", 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)

        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- Click: announce (SendChatMessage is always safe in combat)
        btn:SetScript("OnClick", function(self, button)
            if button == "LeftButton" then
                self.announceFunc()
            end
        end)
    else
        if not btn.glow then btn.glow = ExtGetOrCreateGlow(btn) end
    end

    btn:SetAttribute("type", "spell")
    btn:SetSize(currentSize, currentSize)
    local tex = entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
    btn.icon:SetTexture(tex)
    btn.currentSpellID = entry.spellID
    btn.extKey         = entry.key
    btn.announceFunc   = announceFunc
    btn.tooltipKey     = tooltipKey

    local spacing = (TankBuffReminderDB and TankBuffReminderDB.extBarButtonPadding) or 4
    btn:SetPoint("LEFT", anchor, "LEFT", (index - 1) * (currentSize + spacing) + 4, 0)
    btn:Show()

    slot.btn      = btn
    slot.icon     = btn.icon
    slot.glow     = btn.glow
    slot.cd       = btn.cd
    slot.key      = entry.key
    slot.entry    = entry
    slot.isMissing = false

    return slot
end

-------------------------------------------------------------------------------
-- Visual helpers  (operate on any slot list + anchor pair)
-------------------------------------------------------------------------------
local function UpdateGlowForSlots(slots, anchor)
    local db    = TankBuffReminderCharDB
    local gdb   = TankBuffReminderDB
    local color = (gdb and gdb.extGlowColor) or cfg.defaults.glowColor
    local sizeMult = (db and db.extGlowSize) or 1.8
    local scale    = (gdb and gdb.extBarScale) or 1
    local sz       = BASE_SIZE * scale
    for _, slot in ipairs(slots) do
        if slot.glow then
            slot.glow:SetVertexColor(color.r, color.g, color.b, color.a or 1)
            slot.glow:SetSize(sz * sizeMult, sz * sizeMult)
        end
    end
end

local function UpdateAlphaForAnchor(anchor)
    local db         = TankBuffReminderCharDB
    local frameAlpha = (db and db.extFrameAlpha) or 1.0
    local bgAlpha    = anchor.anyMissing and frameAlpha or (frameAlpha * 0.4)
    if anchor.bg then anchor.bg:SetAlpha(bgAlpha) end
    anchor:SetBackdropBorderColor(1, 1, 1, bgAlpha)
end

function TBR_ExtBar_UpdateGlow()
    UpdateGlowForSlots(extSlots, extAnchor)
end

function TBR_ExtBar_UpdateAlpha()
    UpdateAlphaForAnchor(extAnchor)
end

local function ExtCacheCooldownText(slot)
    if slot.cdText then return slot.cdText end
    local count = slot.cd:GetNumRegions()
    for i = 1, count do
        local region = select(i, slot.cd:GetRegions())
        if region and region.IsObjectType and region:IsObjectType("FontString") then
            slot.cdText = region; return region
        end
    end
    return nil
end

local function UpdateTimerStyleForSlots(slots)
    local db       = TankBuffReminderCharDB
    local gdb      = TankBuffReminderDB
    local offsetY  = (db and db.extTimerTextOffsetY) or 0
    local tc       = (db and db.extTimerTextColor)   or cfg.defaults.timerTextColor
    local tAlpha   = (db and db.extTimerAlpha)       or 1.0
    local sweepAlpha = (db and db.extSweepAlpha)     or 0.6
    local fontSize = (db and db.extTimerFontSize)    or 12

    for _, slot in ipairs(slots) do
        local cd = slot.cd
        if cd.SetDrawSwipe then
            cd:SetDrawSwipe(sweepAlpha > 0)
            cd:SetSwipeColor(0, 0, 0, sweepAlpha)
        end
        cd:SetDrawBling(false)
        cd:SetDrawEdge(false)
        cd:SetHideCountdownNumbers(false)
        -- Keep the cooldown frame itself visible; SetDrawSwipe(false) can
        -- implicitly hide it on some client builds when there is no bling/edge.
        if cd:GetCooldownDuration() and cd:GetCooldownDuration() > 0 then
            cd:Show()
        end
        local fs = ExtCacheCooldownText(slot)
        if fs then
            fs:ClearAllPoints()
            fs:SetPoint("CENTER", cd, "CENTER", 0, offsetY)
            fs:SetTextColor(tc.r, tc.g, tc.b, tAlpha)
            local fontPath, _, fontFlags = fs:GetFont()
            if fontPath then fs:SetFont(fontPath, fontSize, fontFlags or "OUTLINE") end
        end
    end
end

function TBR_ExtBar_UpdateTimerStyle()
    UpdateTimerStyleForSlots(extSlots)
end

-------------------------------------------------------------------------------
-- OnUpdate pulse
-------------------------------------------------------------------------------
local function PulseSlots(slots, anchor, alphaWave, userAlpha, isShift, inCombat)
    for _, slot in ipairs(slots) do
        local btn       = slot.btn
        local isMissing = (slot.isMissing == true)

        if btn.dragMask then
            if isShift and not inCombat then btn.dragMask:Show()
            else btn.dragMask:Hide() end
        end

        if isMissing then
            slot.icon:SetAlpha(1.0)
            slot.icon:SetDesaturated(false)
            if slot.glow then
                slot.glow:Show()
                slot.glow:SetAlpha(alphaWave)
                -- Missing: use the configured glow color (defaults to red/gold)
                local gdb   = TankBuffReminderDB
                local color = (gdb and gdb.extGlowColor) or { r=1, g=0.2, b=0.2, a=1 }
                slot.glow:SetVertexColor(color.r, color.g, color.b, color.a or 1)
            end
            local db = TankBuffReminderCharDB
            local sAlpha = (db and db.extSweepAlpha) or 0.6
            slot.cd:SetSwipeColor(0, 0, 0, sAlpha)
        elseif slot.isExpiring then
            slot.icon:SetAlpha(1.0)
            slot.icon:SetDesaturated(false)
            if slot.glow then
                slot.glow:Show()
                slot.glow:SetAlpha(alphaWave * 0.7)
                -- Expiring: orange warning glow, distinct from missing
                slot.glow:SetVertexColor(1, 0.55, 0, 1)
            end
            local db = TankBuffReminderCharDB
            local sAlpha = (db and db.extSweepAlpha) or 0.6
            slot.cd:SetSwipeColor(0, 0, 0, sAlpha)
        else
            if slot.glow then slot.glow:Hide() end
            slot.icon:SetAlpha(userAlpha * 0.4)
            slot.icon:SetDesaturated(true)
            slot.cd:SetSwipeColor(0.1, 0.1, 0.1, userAlpha * 0.55)
        end
    end
end

local function CheckStopMoving(anchor)
    if anchor.isMoving and not IsShiftKeyDown() then
        anchor:StopMovingOrSizing(); anchor.isMoving = false
        if TankBuffReminderDB then
            local p, _, rp, x, y = anchor:GetPoint()
            TankBuffReminderDB[anchor.posKey] = { p = p, rp = rp, x = x, y = y }
        end
    end
end

extAnchor:SetScript("OnUpdate", function(self, elapsed)
    extPulseElapsed = extPulseElapsed + elapsed
    if extPulseElapsed < PULSE_INTERVAL then return end

    local db    = TankBuffReminderCharDB
    local speed = (db and db.extPulseSpeed) or 4

    extPulseTimer = (extPulseTimer + (extPulseElapsed * speed)) % TWO_PI
    extPulseElapsed = 0

    local alphaWave = 0.75 + math_sin(extPulseTimer) * 0.25
    local userAlpha = (db and db.extBuffAlpha) or 1.0
    local isShift   = IsShiftKeyDown()
    local inCombat  = InCombatLockdown()

    CheckStopMoving(extAnchor)

    -- Rebuild aura cache every pulse so cooldown sweeps and timers tick correctly.
    -- The state-change diff in RunVisibilityCheck handles sound/visibility;
    -- this handles the visual timer update, same as TBR_UI_Update does for the main bar.
    if #extSlots > 0 then
        table.wipe(extAuraCache)
        local poolIdx = 0
        for i = 1, 40 do
            local name, _, _, _, duration, expirationTime = UnitBuff("player", i)
            if not name then break end
            poolIdx = poolIdx + 1
            local ce = extCachePool[poolIdx]
            if ce then
                ce.dur = duration or 0
                ce.exp = expirationTime or 0
                extAuraCache[name] = ce
            end
        end
        UpdateSlotsTimers(extSlots)
    end

    PulseSlots(extSlots, extAnchor, alphaWave, userAlpha, isShift, inCombat)
end)

-------------------------------------------------------------------------------
-- Update (called each visibility check)
-------------------------------------------------------------------------------
UpdateSlotsTimers = function(slots)
    local db       = TankBuffReminderCharDB
    local warnSecs = (db and db.extWarnSeconds) or 0

    for _, slot in ipairs(slots) do
        slot.isMissing  = (TBR_ExtBuffStates and TBR_ExtBuffStates[slot.key] == true)
        slot.isExpiring = false   -- reset each tick

        local aura = nil
        if slot.entry and slot.entry.buffName then
            if type(slot.entry.buffName) == "table" then
                for _, bn in ipairs(slot.entry.buffName) do
                    aura = extAuraCache[bn]
                    if aura then break end
                end
            else
                aura = extAuraCache[slot.entry.buffName]
            end
        end

        if aura and aura.dur and aura.dur > 0 then
            local start = aura.exp - aura.dur
            local cStart, cDur = slot.cd:GetCooldownTimes()
            if math.abs((cStart / 1000) - start) > 0.1 or math.abs((cDur / 1000) - aura.dur) > 0.1 then
                slot.cd:SetCooldown(start, aura.dur)
                slot.cd:Show()
            end
            -- Expiration warning: buff is present but running low
            if warnSecs > 0 and not slot.isMissing then
                local remaining = aura.exp - GetTime()
                if remaining > 0 and remaining <= warnSecs then
                    slot.isExpiring = true
                end
            end
        else
            slot.cd:Hide()
        end
    end
end

function TBR_ExtBar_Update(extBuffStates, anyMissing)
    extAnchor.anyMissing = anyMissing or false

    -- Rebuild aura cache
    table.wipe(extAuraCache)
    local poolIdx = 0
    for i = 1, 40 do
        local name, _, _, _, duration, expirationTime = UnitBuff("player", i)
        if not name then break end
        poolIdx = poolIdx + 1
        local ce = extCachePool[poolIdx]
        if ce then
            ce.dur = duration or 0
            ce.exp = expirationTime or 0
            extAuraCache[name] = ce
        end
    end

    UpdateSlotsTimers(extSlots)

    -- Audio alert — mirrors FrameUI's activeAlerts pattern exactly.
    -- Sound fires on the first update where a buff transitions from "present" to missing.
    -- No combat gate — FrameUI doesn't use one either. The seen-state logic handles
    -- the "don't alert at login/reload" requirement without needing a combat check.
    local db = TankBuffReminderCharDB
    local played = false
    for _, slot in ipairs(extSlots) do
        if slot.isMissing then
            -- Only alert if we previously saw this buff as present
            if extBuffSeenState[slot.key] == "present" then
                if not played and db and db.extPlaySound then
                    local soundID = (db.extSoundID) or (cfg.defaults and cfg.defaults.soundID) or 8959
                    PlaySound(soundID, "Master")
                    played = true
                end
                extBuffSeenState[slot.key] = "alerted"
            end
        else
            -- Buff is present — mark as seen so we can alert if it later drops
            extBuffSeenState[slot.key] = "present"
        end
    end

    TBR_ExtBar_UpdateAlpha()
end

-------------------------------------------------------------------------------
-- Rebuild helpers
-------------------------------------------------------------------------------
local function ReleaseSlotList(slotList)
    for _, slot in ipairs(slotList) do
        if slot.btn then
            slot.btn:Hide()
            if slot.btn.glow then ExtReleaseGlow(slot.btn.glow); slot.btn.glow = nil end
            if slot.btn.dragMask then slot.btn.dragMask:Hide() end
            table.insert(extFramePool, slot.btn)
        end
        table.wipe(slot)
        table.insert(extSlotPool, slot)
    end
    table.wipe(slotList)
end

local function BuildBar(anchor, entries, announceFunc, tooltipKey, posKey)
    if #entries == 0 then anchor:Hide(); return end

    local gdb      = TankBuffReminderDB or {}
    local scale    = gdb.extBarScale or 1
    local currentSize = BASE_SIZE * scale
    local spacing  = gdb.extBarButtonPadding or 4
    local padding  = 8

    local totalWidth = (currentSize * #entries) + (spacing * (#entries - 1)) + padding
    anchor:SetSize(totalWidth, currentSize + padding)
    anchor:Show()

    for i, entry in ipairs(entries) do
        local slot = ExtMakeSlot(i, entry, currentSize, anchor, announceFunc, tooltipKey)
        if slot then
            slot.btn:ClearAllPoints()
            slot.btn:SetPoint("LEFT", anchor, "LEFT", (i - 1) * (currentSize + spacing) + 4, 0)
            table.insert(extSlots, slot)
        end
    end

    -- Restore saved position (buff bar only; totem bar position is derived from extAnchor)
    if posKey then
        local gdb = TankBuffReminderDB or {}
        if gdb[posKey] then
            local p = gdb[posKey]
            anchor:ClearAllPoints()
            anchor:SetPoint(p.p, UIParent, p.rp, p.x, p.y)
        end
    end
end

-------------------------------------------------------------------------------
-- Rebuild (called when tracked list changes)
-------------------------------------------------------------------------------
function TBR_ExtBar_Rebuild()
    ReleaseSlotList(extSlots)
    table.wipe(extBuffSeenState)

    if not TankBuffReminderCharDB or TankBuffReminderCharDB.disabled then
        extAnchor:Hide(); return
    end
    if not TankBuffReminderExternalBuffs then
        extAnchor:Hide(); return
    end

    local db          = TankBuffReminderCharDB
    local unlocked    = db.extBarUnlocked
    local smartDetect = db.extSmartDetect ~= false  -- default true

    -- When unlocked: bypass all group/smart checks; show all enabled entries
    -- so the player can position the bar without needing to be in a group.
    if not unlocked then
        local inGroup     = IsInGroup()
        local inRaid      = IsInRaid()
        local showInParty = db.extBuffsShowInParty ~= false
        local showInRaid  = db.extBuffsShowInRaid  ~= false

        if not inGroup then extAnchor:Hide(); return end
        if inRaid  and not showInRaid  then extAnchor:Hide(); return end
        if not inRaid and not showInParty then extAnchor:Hide(); return end
    end

    local buffEntries = {}
    for _, entry in ipairs(TankBuffReminderExternalBuffs) do
        if db["ext_" .. entry.key] then
            -- When smart detection is on and not in positioning mode,
            -- only include entries whose source class is in the current group.
            local include = true
            if smartDetect and not unlocked and entry.sourceClass then
                -- Read from the same groupClassSet that CheckExternalBuffs uses
                local gs = TBR_GetGroupClassSet and TBR_GetGroupClassSet()
                if gs and not gs[entry.sourceClass] then
                    include = false
                end
            end
            if include then
                table.insert(buffEntries, entry)
            end
        end
    end

    if #buffEntries == 0 and not unlocked then
        extAnchor:Hide(); return
    end

    local L = TBR_L
    BuildBar(extAnchor, buffEntries, AnnounceExtMissing, "Click to announce missing buffs", "extBar_pos")

    -- Red border when unlocked (matches removal UI visual language)
    if unlocked then
        extAnchor:SetBackdropBorderColor(1, 0.15, 0.15, 0.9)
    else
        extAnchor:SetBackdropBorderColor(1, 1, 1, 0.4)
    end

    TBR_ExtBar_UpdateGlow()
    TBR_ExtBar_UpdateTimerStyle()

    if TBR_ForceCheck then TBR_ForceCheck() end
end

-------------------------------------------------------------------------------
-- Restore position on login
-------------------------------------------------------------------------------
local extLoader = CreateFrame("Frame")
extLoader:RegisterEvent("PLAYER_LOGIN")
extLoader:SetScript("OnEvent", function()
    table.wipe(extBuffSeenState)   -- reset seen-state so first combat of session is clean
    C_Timer.After(0.7, function()
        if TankBuffReminderDB and TankBuffReminderDB.extBar_pos then
            local p = TankBuffReminderDB.extBar_pos
            extAnchor:ClearAllPoints()
            extAnchor:SetPoint(p.p, UIParent, p.rp, p.x, p.y)
        end
    end)
end)