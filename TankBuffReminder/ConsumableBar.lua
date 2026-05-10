-- ConsumableBar.lua
local cfg = TankBuffReminderConfig

-- Upvalued for performance
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_sin = math.sin
local math_pi = math.pi
local TWO_PI = 2 * math_pi
local InCombatLockdown = InCombatLockdown
local GetTime = GetTime
local GetItemCount = GetItemCount
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local UnitBuff = UnitBuff
local PULSE_INTERVAL = 0.25
local BASE_SIZE = 36
local PADDING = 6
local POTION_SHARED_CD_ITEM = 13446

-------------------------------------------------------------------------------
-- Pools & Memory Management (declared early so hotkey functions can reference slots)
-------------------------------------------------------------------------------
local slots = {}
local framePool = {}
local slotPool = {}
local glowPool = {}
local itemCountCache = {}
local pulseTimer = 0
local pulseElapsed = 0
local _DEFAULT_R, _DEFAULT_G, _DEFAULT_B = 0, 0, 0
local lastBuffScan = 0
local WELL_FED_NAME = GetSpellInfo(35272)
local _currentBuffs = {}
local _lastCounts = {}

-------------------------------------------------------------------------------
-- Hotkey System
-------------------------------------------------------------------------------
-- hotkeys stored in TankBuffReminderDB.consHotkeys[entryKey] = "Shift+1" etc.

local hotkeyDialog        -- the capture popup frame (created lazily)
local hotkeyCapturing     -- slot whose hotkey we are currently setting
local MODIFIER_KEYS = { LSHIFT=true, RSHIFT=true, LCTRL=true, RCTRL=true,
                        LALT=true,   RALT=true,   LMETA=true, RMETA=true }

-- Find which entry key (if any) already owns a given hotkey string
-- Returns: bindingKey (for SetBindingClick), displayStr (for UI labels)
-- Returns nil, nil if key is a bare modifier tap.
local function BuildHotkeyStrings(key)
    if MODIFIER_KEYS[key] then return nil, nil end
    -- WoW binding format: SHIFT-CTRL-ALT-KEY (all caps, dash-separated)
    local bindParts = {}
    if IsShiftKeyDown()   then bindParts[#bindParts+1] = "SHIFT" end
    if IsControlKeyDown() then bindParts[#bindParts+1] = "CTRL"  end
    if IsAltKeyDown()     then bindParts[#bindParts+1] = "ALT"   end
    -- Single letters must be upper-case for WoW bindings
    local bindKey = (#key == 1) and key:upper() or key:upper()
    bindParts[#bindParts+1] = bindKey
    local bindingKey = table.concat(bindParts, "-")

    -- Human-readable display string e.g. "Shift+G"
    local dispParts = {}
    if IsShiftKeyDown()   then dispParts[#dispParts+1] = "Shift" end
    if IsControlKeyDown() then dispParts[#dispParts+1] = "Ctrl"  end
    if IsAltKeyDown()     then dispParts[#dispParts+1] = "Alt"   end
    local dispKey = (#key == 1) and key:upper() or key
    dispParts[#dispParts+1] = dispKey
    local displayStr = table.concat(dispParts, "+")

    return bindingKey, displayStr
end

-- Legacy shim used for the live modifier preview label (no key yet, just prefix)
local function GetModifierPreviewStr()
    local parts = {}
    if IsShiftKeyDown()   then parts[#parts+1] = "Shift" end
    if IsControlKeyDown() then parts[#parts+1] = "Ctrl"  end
    if IsAltKeyDown()     then parts[#parts+1] = "Alt"   end
    return #parts > 0 and (table.concat(parts, "+") .. "+") or ""
end

-- Find which entry key (if any) already owns a given binding key string
local function FindExistingOwner(bindingKey)
    local db = TankBuffReminderDB
    if not db or not db.consHotkeys then return nil end
    for entryKey, hk in pairs(db.consHotkeys) do
        if hk and hk.bind == bindingKey then return entryKey end
    end
    return nil
end

-- Return the display name for an entry key by searching cfg.consumables
local function EntryNameForKey(entryKey)
    if not entryKey or not cfg or not cfg.consumables then return entryKey end
    for _, e in ipairs(cfg.consumables) do
        if e.key == entryKey then return e.label or e.key end
    end
    return entryKey
end

-- Apply (or remove) a SetBindingClick binding for one slot button.
local function ApplyHotkeyBinding(btn, entryKey, saveBind)
    if InCombatLockdown() then return end
    local db = TankBuffReminderDB
    local hk = db and db.consHotkeys and db.consHotkeys[entryKey]

    if btn._boundKey then
        SetBinding(btn._boundKey)
        btn._boundKey = nil
    end

    if hk and hk.bind and btn:GetName() then
        SetBindingClick(hk.bind, btn:GetName(), "LeftButton")
        btn._boundKey = hk.bind
    end

    if saveBind then
        SaveBindings(GetCurrentBindingSet())
    end
end

-- Re-apply all hotkey bindings (called after rebuild) — one SaveBindings at the end
local function ReapplyAllHotkeys()
    if InCombatLockdown() then return end
    local db = TankBuffReminderDB
    if not db or not db.consHotkeys then return end
    local anyBound = false
    for _, slot in ipairs(slots) do
        local entryKey = slot.entry and slot.entry.key
        if entryKey then
            ApplyHotkeyBinding(slot.btn, entryKey, false)  -- no save yet
            anyBound = true
        end
    end
    if anyBound then
        SaveBindings(GetCurrentBindingSet())  -- single save for the whole batch
    end
end

-- Update the small hotkey label shown on a button
local function RefreshHotkeyLabel(btn, entryKey)
    if not btn.hotkeyText then return end
    local db = TankBuffReminderDB
    local hk = db and db.consHotkeys and db.consHotkeys[entryKey]
    if hk and hk.display then
        -- Cache the abbreviated form on the button so gsub only runs on change
        if btn._hotkeyAbbr ~= hk.display then
            btn._hotkeyAbbr = hk.display
            btn._hotkeyAbbrShort = hk.display:gsub("Shift%+","S+"):gsub("Ctrl%+","C+"):gsub("Alt%+","A+")
        end
        btn.hotkeyText:SetText(btn._hotkeyAbbrShort)
        btn.hotkeyText:Show()
    else
        btn._hotkeyAbbr = nil
        btn._hotkeyAbbrShort = nil
        btn.hotkeyText:SetText("")
        btn.hotkeyText:Hide()
    end
end

-- Finalise setting a hotkey after the player confirms the capture
-- bindingKey = "SHIFT-G", displayStr = "Shift+G"
local function CommitHotkey(entryKey, bindingKey, displayStr)
    if not entryKey or not bindingKey then return end
    local db = TankBuffReminderDB
    if not db then return end
    if not db.consHotkeys then db.consHotkeys = {} end
    db.consHotkeys[entryKey] = { bind = bindingKey, display = displayStr }
    for _, slot in ipairs(slots) do
        if slot.entry and slot.entry.key == entryKey then
            ApplyHotkeyBinding(slot.btn, entryKey, true)  -- save=true: single user action
            RefreshHotkeyLabel(slot.btn, entryKey)
            break
        end
    end
end

-- Clear a hotkey for a slot
local function ClearHotkey(entryKey)
    if not entryKey then return end
    local db = TankBuffReminderDB
    if not db or not db.consHotkeys then return end
    db.consHotkeys[entryKey] = nil
    for _, slot in ipairs(slots) do
        if slot.entry and slot.entry.key == entryKey then
            ApplyHotkeyBinding(slot.btn, entryKey, true)  -- save=true: single user action
            RefreshHotkeyLabel(slot.btn, entryKey)
            break
        end
    end
end

-- ── Hotkey Capture Dialog ────────────────────────────────────────────────────
local function GetOrCreateHotkeyDialog()
    if hotkeyDialog then return hotkeyDialog end

    local f = CreateFrame("Frame", "TBR_HotkeyDialog", UIParent, "BackdropTemplate")
    f:SetSize(300, 140)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)

    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- Title bar drag support
    f:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then self:StartMoving() end
    end)
    f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", f, "TOP", 0, -16)
    f.title:SetText("Set Hotkey")

    f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.label:SetPoint("TOP", f.title, "BOTTOM", 0, -10)
    f.label:SetWidth(260)
    f.label:SetJustifyH("CENTER")
    f.label:SetText("Press any key combination…")

    f.keyDisplay = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    f.keyDisplay:SetPoint("TOP", f.label, "BOTTOM", 0, -8)
    f.keyDisplay:SetText("")
    f.keyDisplay:SetTextColor(1, 0.82, 0)

    -- KeyDown capture frame (invisible, keyboard-focused)
    local captureFrame = CreateFrame("Frame", nil, f)
    captureFrame:SetAllPoints()
    captureFrame:EnableKeyboard(true)
    captureFrame:SetPropagateKeyboardInput(false)
    f.captureFrame = captureFrame

	captureFrame:SetScript("OnKeyDown", function(self, key)
		if key == "ESCAPE" then
			f:Hide()
			return
		elseif key == "BACKSPACE" then -- NEW: Implementation of the clear logic
			ClearHotkey(hotkeyCapturing)
			f:Hide()
			return
		end
        local bindingKey, displayStr = BuildHotkeyStrings(key)
        if not bindingKey then
            -- They only pressed a modifier; show live preview
            f.keyDisplay:SetText(GetModifierPreviewStr() .. "…")
            return
        end

        -- Always show what they pressed
        f.keyDisplay:SetText(displayStr)

        -- 1) Check our own addon's slots first
        local addonOwner = FindExistingOwner(bindingKey)
        if addonOwner and addonOwner ~= hotkeyCapturing then
            if f._pendingBind == bindingKey and f._pendingOwner == addonOwner then
                -- Second press on same key = confirmed override of our own slot
                ClearHotkey(f._pendingOwner)
                CommitHotkey(hotkeyCapturing, bindingKey, displayStr)
                f:Hide()
            else
                f.label:SetText("|cffff6060Already bound to:\n" .. EntryNameForKey(addonOwner) .. "|r\nPress again to override, Esc to cancel.")
                f._pendingBind    = bindingKey
                f._pendingDisplay = displayStr
                f._pendingOwner   = addonOwner
                f._pendingIsWoW   = false
            end
            return
        end

        -- 2) Check WoW's own keybind system (action bars, spells, macros, etc.)
        local wowAction = GetBindingAction(bindingKey, true)  -- true = check all binding sets
        -- GetBindingAction returns "" when nothing is bound
        if wowAction and wowAction ~= "" then
            -- Try to get a friendlier name for it
            local friendlyName = _G["BINDING_NAME_" .. wowAction] or wowAction
            if f._pendingBind == bindingKey and f._pendingIsWoW then
                -- Second press = user accepts the conflict, set anyway
                CommitHotkey(hotkeyCapturing, bindingKey, displayStr)
                f:Hide()
            else
                f.label:SetText("|cffff8800Already used by:\n|cffffffff" .. friendlyName .. "|r\n|cffff8800Press again to use anyway, Esc to cancel.|r")
                f._pendingBind    = bindingKey
                f._pendingDisplay = displayStr
                f._pendingOwner   = nil
                f._pendingIsWoW   = true
            end
            return
        end

        -- 3) No conflict at all – set immediately
        f._pendingBind  = nil
        f._pendingIsWoW = false
        CommitHotkey(hotkeyCapturing, bindingKey, displayStr)
        f:Hide()
    end)

    -- Reset pending state whenever the dialog shows
    f:SetScript("OnShow", function(self)
        self._pendingBind    = nil
        self._pendingDisplay = nil
        self._pendingOwner   = nil
        self._pendingIsWoW   = false
        self.keyDisplay:SetText("")
        self.label:SetText("Press any key combination…\n|cff888888Esc to cancel  •  Backspace clears|r")
        self.captureFrame:EnableKeyboard(true)
    end)
    f:SetScript("OnHide", function(self)
        self.captureFrame:EnableKeyboard(false)
        hotkeyCapturing = nil
    end)

    -- Cancel button
    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(80, 22)
    cancelBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 14)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    f:Hide()
    hotkeyDialog = f
    return f
end

-- Open the dialog for a given slot entry key
local function OpenHotkeyDialog(entryKey)
    if not entryKey then return end
    if InCombatLockdown() then
        UIErrorsFrame:AddMessage("|cffff6060Cannot set hotkeys in combat.|r")
        return
    end
    hotkeyCapturing = entryKey
    local dlg = GetOrCreateHotkeyDialog()
    dlg.title:SetText("Set Hotkey – " .. EntryNameForKey(entryKey))
    dlg:Show()
end

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
    glow:SetSize(BASE_SIZE * 2.2, BASE_SIZE * 2.2)
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
local anchor = CreateFrame("Frame", "TBR_ConsumableBar", UIParent, "BackdropTemplate")
anchor:SetMovable(true)
anchor:SetClampedToScreen(true)
anchor:SetPoint("CENTER", UIParent, "CENTER", 0, -220)
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
        local db = TankBuffReminderDB
        if not InCombatLockdown() and db then
            local p, _, rp, x, y = self:GetPoint()
            db.consBar_pos = { p = p, rp = rp, x = x, y = y }
        end
    end
end)

anchor:Hide()

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------
local function BestItemID(itemIDs)
    if not itemIDs then return nil end
    for _, id in ipairs(itemIDs) do
        if GetItemCount(id) > 0 then return id end
    end
    return itemIDs[1]
end

local function UpdateItemCounts()
    for _, slot in ipairs(slots) do
        local entry = slot.entry
        if entry and entry.key then
            local total = 0
            for i = 1, #entry.itemIDs do
                total = total + GetItemCount(entry.itemIDs[i], false)
            end
            itemCountCache[entry.key] = total
        end
    end
end

local function SafeGetCD(itemID)
    if not itemID then return 0, 0, 1 end
    local fn = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
    local start, duration, enabled = fn(itemID)
    return start or 0, duration or 0, enabled
end

local function ApplyButtonAttributes(slot, entry)
    local btn = slot.btn
    local resolvedID = BestItemID(entry.itemIDs)
   
    if not resolvedID then
        btn:SetAttribute("type", nil)
        btn:SetAttribute("macrotext", nil)
        btn.currentItemID = nil
        return
    end

    local _, class = UnitClass("player")
    btn.currentItemID = resolvedID
    btn.druidInstant = (class == "DRUID" and entry.druidInstant == true)

    btn:SetAttribute("type", "macro")

    if btn.druidInstant then
        btn:SetAttribute("macrotext", string.format(
            "/changeactionbar [form:1]2;[form:3]3\n/use item:%d\n/cast [bar:2] !Dire Bear Form; [bar:3] !Cat Form\n/changeactionbar 1",
            resolvedID
        ))
    else
        btn:SetAttribute("macrotext", "/use item:" .. resolvedID)
    end
end

-------------------------------------------------------------------------------
-- TBR_ConsBar_UpdateVisuals (Restored & Fixed)
-------------------------------------------------------------------------------
function TBR_ConsBar_UpdateVisuals()
    local globalDB = TankBuffReminderDB
    if not anchor or not globalDB then return end

    anchor:SetScale(globalDB.consScale or 1.0)

    local isOver = anchor:IsMouseOver()
    local visibilityAlpha = (globalDB.consMouseover) and (isOver and 1.0 or 0) or 1.0
    local frameAlpha = globalDB.consFrameAlpha or 0.3

    if anchor.bg then
        anchor.bg:SetAlpha(visibilityAlpha * frameAlpha)
    end

    local gc = globalDB.consGlowColor or _tempColor
    local tc = globalDB.consTextColor or _tempColor

    for _, slot in ipairs(slots) do
        local btn = slot.btn
        if btn.glow then
            btn.glow:SetVertexColor(gc.r, gc.g, gc.b, globalDB.consGlowAlpha or 1.0)
        end

        if btn.cdText then
            local font, _, outline = btn.cdText:GetFont()
            btn.cdText:SetFont(font, globalDB.consTimerFontSize or 12, outline or "")
            btn.cdText:SetAlpha(globalDB.consTimerAlpha or 1.0)
            btn.cdText:SetTextColor(tc.r, tc.g, tc.b)
            btn.cdText:SetPoint("CENTER", btn, "CENTER", 0, globalDB.consTimerOffsetY or 0)
        end

        if btn.cd then
            btn.cd:SetSwipeColor(0, 0, 0, globalDB.consSweepAlpha or 0.6)
        end
    end
end

-------------------------------------------------------------------------------
-- Slot Factory
-------------------------------------------------------------------------------
local function MakeSlot(index, entry, xOffset)
    local resolvedID = BestItemID(entry.itemIDs)
    if not resolvedID then return nil end

    local btn = table.remove(framePool)
    local slot = table.remove(slotPool) or {}

    if not btn then
        btn = CreateFrame("Button", "TBR_CBSlot" .. (#slots + #framePool + 1), anchor, "SecureActionButtonTemplate")
        btn:RegisterForClicks("AnyUp", "AnyDown")

        -- PreClick fires before the secure action. Ctrl+Click: nullify the type
        -- so the macro doesn't fire, then restore it in PostClick.
        btn:SetScript("PreClick", function(self, button, down)
            if button == "LeftButton" and IsControlKeyDown() then
                self._savedType  = self:GetAttribute("type")
                self._savedMacro = self:GetAttribute("macrotext")
                self:SetAttribute("type", nil)
                self:SetAttribute("macrotext", nil)
                self._ctrlBlocked = true
            else
                self._ctrlBlocked = false
            end
        end)
        btn:SetScript("PostClick", function(self, button, down)
            if self._ctrlBlocked then
                -- Restore attributes and open the dialog
                self:SetAttribute("type", self._savedType)
                self:SetAttribute("macrotext", self._savedMacro)
                self._ctrlBlocked = false
                local slotEntry = self.entry
                if slotEntry then
                    OpenHotkeyDialog(slotEntry.key)
                end
            end
        end)

        -- OnMouseDown/Up: only used to pass Shift+drag through to the anchor
        btn:SetScript("OnMouseDown", function(self, button)
            if IsShiftKeyDown() then
                local parent = self:GetParent()
                if parent:GetScript("OnMouseDown") then parent:GetScript("OnMouseDown")(parent, button) end
            end
        end)
        btn:SetScript("OnMouseUp", function(self, button)
            local parent = self:GetParent()
            if parent:GetScript("OnMouseUp") then parent:GetScript("OnMouseUp")(parent, button) end
        end)

        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetAllPoints()
        btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        btn.cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
        btn.cd:SetAllPoints()
        btn.cd:SetDrawEdge(false)

        for i = 1, btn.cd:GetNumRegions() do
            local region = select(i, btn.cd:GetRegions())
            if region and region:GetObjectType() == "FontString" then
                btn.cdText = region
                break
            end
        end

        btn.countText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        btn.countText:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, 2)

        -- Hotkey label (top-left corner, like action bar hotkey text)
        btn.hotkeyText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        btn.hotkeyText:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
        btn.hotkeyText:SetTextColor(1, 1, 1)
        btn.hotkeyText:Hide()

        btn.lockOverlay = btn:CreateTexture(nil, "OVERLAY")
        btn.lockOverlay:SetAllPoints()
        btn.lockOverlay:SetColorTexture(0, 0, 0, 0.6)
        btn.lockOverlay:Hide()

        btn.glow = GetOrCreateGlow(btn)

        btn:SetScript("OnEnter", function(self)
            if anchor.isMoving then return end
            local itemID = self.currentItemID
            if not itemID then return end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(itemID)

            local slotEntry = self.entry
            if self.druidInstant then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff00ff00Bear-safe:|r re-enters Bear or Cat Form after use.", 1, 1, 1, true)
            elseif slotEntry and slotEntry.druidWarn then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cffff8800Warning:|r drops Bear Form.", 1, 0.6, 0, true)
            end

            local totalCount = 0
            if slotEntry then
                for _, id in ipairs(slotEntry.itemIDs) do
                    totalCount = totalCount + GetItemCount(id, false)
                end
            end
            GameTooltip:AddDoubleLine("Total in Bags:", totalCount, 1, 1, 1, 1, 1, 1)

            -- Hotkey hint lines
            local db = TankBuffReminderDB
            local hk = db and db.consHotkeys and slotEntry and db.consHotkeys[slotEntry.key]
            if hk and hk.display then
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine("Hotkey:", hk.display, 0.6, 0.6, 0.6, 1, 0.82, 0)
                GameTooltip:AddLine("|cff888888Backspace|r to clear  •  |cff888888Ctrl+Click|r to rebind", 0.7, 0.7, 0.7, true)
            else
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff888888Ctrl+Click|r to set a hotkey", 0.7, 0.7, 0.7, true)
            end

            GameTooltip:Show()

            -- Enable Backspace to clear the hotkey while hovering
            self:EnableKeyboard(true)
            self:SetPropagateKeyboardInput(true)
            self:SetScript("OnKeyDown", function(s, key)
                if key == "BACKSPACE" then
                    local entry = s.entry
                    if entry then
                        ClearHotkey(entry.key)
                        -- Refresh tooltip
                        GameTooltip:ClearLines()
                        GameTooltip:SetItemByID(s.currentItemID)
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("|cff888888Ctrl+Click|r to set a hotkey", 0.7, 0.7, 0.7, true)
                        GameTooltip:Show()
                    end
                end
            end)
        end)
        btn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            self:EnableKeyboard(false)
            self:SetScript("OnKeyDown", nil)
        end)
    else
        if not btn.glow then
            btn.glow = GetOrCreateGlow(btn)
        end
    end

    btn:SetSize(BASE_SIZE, BASE_SIZE)
    btn:SetPoint("LEFT", anchor, "LEFT", xOffset, 0)

    slot.btn   = btn
    slot.entry = entry
    slot.icon  = btn.icon
    slot.cd    = btn.cd
    slot.count = btn.countText
    slot.lock  = btn.lockOverlay

    btn.entry = entry

	local iconTex = GetItemIcon(resolvedID) or entry.icon
    local fallback = "Interface\\Icons\\INV_Misc_QuestionMark"
    btn.icon:SetTexture(iconTex or fallback)

    btn.lockOverlay:Hide()
    ApplyButtonAttributes(slot, entry)
    RefreshHotkeyLabel(btn, entry.key)
    btn:Show()

    return slot
end

-------------------------------------------------------------------------------
-- Per-frame Visual Logic
-------------------------------------------------------------------------------
-- Pre-allocated string cache for item counts — avoids tostring() allocation each tick
local _countStrCache = {}
do
    for i = 1, 300 do _countStrCache[i] = tostring(i) end
end
local function CountStr(n)
    return (n > 0) and (_countStrCache[n] or tostring(n)) or ""
end

local _lastInCombat = false  

local function UpdateSlotVisuals(pStart, pDur)
    local potionCDActive = pDur > 1.5
    local inCombat = InCombatLockdown()
    local combatChanged = (inCombat ~= _lastInCombat)
    _lastInCombat = inCombat

    for _, slot in ipairs(slots) do
        local entry = slot.entry
        local btn = slot.btn

        -- Use the event-driven cache instead of the manual for-loop
        local totalCount = itemCountCache[entry.key] or 0
        local resID = BestItemID(entry.itemIDs)

        if resID ~= btn.currentItemID and not inCombat then
            ApplyButtonAttributes(slot, entry)
        end

        -- Cooldown / buff-duration timer handling.
        -- Priority: item CD > potion shared CD > active buff duration.
        -- The buff-duration case shows the sweep/timer on the icon while the
        -- buff is up (greyed out, counting down), matching the main buff bar behaviour.
        local start, duration = SafeGetCD(resID)
        if entry.isPotionType and potionCDActive and pDur > duration then
            start, duration = pStart, pDur
        end

        if duration <= 1.5 then
            -- No item CD — check if a buff from this consumable is currently active
            local now = GetTime()
            local buffExp = nil

            if entry.buffSpellID then
                local sid = entry.buffSpellID
                -- buffSpellID can be a table (e.g. Savory Deviate Delight)
                if type(sid) == "table" then
                    for _, id in ipairs(sid) do
                        if _currentBuffs[id] then buffExp = _currentBuffs[id]; break end
                    end
                else
                    buffExp = _currentBuffs[sid]
                end
            elseif entry.category == "Food" then
                buffExp = _currentBuffs["FOOD"]
            end

            if buffExp and buffExp > 0 then
                local remaining = buffExp - now
                if remaining > 1.5 then
                    -- Only call SetCooldown when the stored expiration differs meaningfully.
                    -- The CD frame animates its own countdown; we don't need to reset it
                    -- every pulse, only when the buff is first applied or refreshed.
                    if math.abs((slot._lastBuffExp or 0) - buffExp) > 1.0 then
                        slot.cd:SetCooldown(now, remaining)
                        slot._lastBuffExp  = buffExp
                        slot._lastStart    = now
                        slot._lastDuration = remaining
                    end
                    slot.cd:Show()
                else
                    slot._lastBuffExp  = nil
                    slot._lastDuration = 0
                    slot._lastStart    = 0
                    slot.cd:Hide()
                end
            else
                slot._lastBuffExp  = nil
                slot._lastDuration = 0
                slot._lastStart    = 0
                slot.cd:Hide()
            end
        else
            -- Item is on cooldown — show that
            if slot._lastStart ~= start or slot._lastDuration ~= duration then
                slot.cd:SetCooldown(start, duration)
                slot._lastStart    = start
                slot._lastDuration = duration
            end
            slot.cd:Show()
        end

        -- Update count text and desaturation only when count changes
        if _lastCounts[btn] ~= totalCount then
            slot.count:SetText(CountStr(totalCount))
            
            -- This handles the grey-out effect
            btn.icon:SetDesaturated(totalCount == 0)
            
            _lastCounts[btn] = totalCount
        end

        -- Combat lock overlay
        if combatChanged then
            if inCombat then
                slot.lock:SetAlpha(0.25)
                slot.lock:Show()
            else
                slot.lock:Hide()
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Main OnUpdate
-------------------------------------------------------------------------------
anchor:SetScript("OnUpdate", function(self, elapsed)
    pulseElapsed = pulseElapsed + elapsed
    if pulseElapsed < PULSE_INTERVAL then return end

    local db = TankBuffReminderDB
    if not db then return end

    local speed = db.consPulseSpeed or 3
    if speed > 0 then
        pulseTimer = (pulseTimer + pulseElapsed * speed) % TWO_PI
    end
    pulseElapsed = 0

    local isOver = anchor:IsMouseOver()
    local visibilityAlpha = (db.consMouseover and not isOver) and 0 or 1.0
    local frameAlphaSetting = db.consFrameAlpha or 0.3

    if anchor.bg then anchor.bg:SetAlpha(visibilityAlpha * frameAlphaSetting) end
    if anchor.SetBackdropBorderColor then
        anchor:SetBackdropBorderColor(1, 1, 1, visibilityAlpha * frameAlphaSetting)
    end

    -- Update visuals (icons/CDs)
    local pStart, pDur = SafeGetCD(POTION_SHARED_CD_ITEM)
    UpdateSlotVisuals(pStart, pDur)

    -- Buff scan: once per second, wipe and rebuild from UnitBuff
    local now = GetTime()
    if (now - lastBuffScan) > 1.0 then
        lastBuffScan = now
        table.wipe(_currentBuffs)
        for i = 1, 40 do
            local name, _, _, _, dur, exp, _, _, _, sid = UnitBuff("player", i)
            if not name then break end
            if sid then _currentBuffs[sid] = exp or 0 end
            if name == WELL_FED_NAME then _currentBuffs["FOOD"] = exp or 0 end
        end
    end

    local maxGlowAlpha  = db.consGlowAlpha or 1.0
    local alphaWave     = (0.7 + math_sin(pulseTimer) * 0.3) * maxGlowAlpha
    local userIconAlpha = db.consAlpha or 1.0
    local gc = db.consGlowColor or { r = _DEFAULT_R, g = _DEFAULT_G, b = _DEFAULT_B }

    for _, slot in ipairs(slots) do
        local entry = slot.entry
        local btn   = slot.btn

        local totalCount = itemCountCache[entry.key] or 0
        local hasItem    = totalCount > 0

        -- Distinguish item-on-CD from buff-timer-showing so the two states get
        -- different visual treatment below.
        local _, itemDur  = SafeGetCD(BestItemID(entry.itemIDs))
        local isOnItemCD  = itemDur > 1.5 or (entry.isPotionType and pDur > 1.5)
        local isBuffTimer = slot.cd:IsShown() and not isOnItemCD
        local isOffCD     = not slot.cd:IsShown()

        local needsAttention = false

        if hasItem and (isOffCD or isBuffTimer) then
            if entry.category == "Weapon" then
                local hasMH, mhExp = GetWeaponEnchantInfo()
                needsAttention = not hasMH or (mhExp / 1000) < 120
            elseif entry.category == "Food" or entry.buffSpellID then
                local found = false
                local sid = entry.buffSpellID
                if sid then
                    if type(sid) == "table" then
                        for _, id in ipairs(sid) do
                            if _currentBuffs[id] and (_currentBuffs[id] == 0 or (_currentBuffs[id] - now) > 120) then
                                found = true; break
                            end
                        end
                    elseif _currentBuffs[sid] then
                        local exp = _currentBuffs[sid]
                        if exp == 0 or (exp - now) > 120 then found = true end
                    end
                elseif entry.category == "Food" and _currentBuffs["FOOD"] then
                    local exp = _currentBuffs["FOOD"]
                    if exp == 0 or (exp - now) > 120 then found = true end
                end
                needsAttention = not found
            else
                needsAttention = true
            end
        end

        if isOnItemCD then
            -- Item cooldown: heavily dim and desaturate
            btn.icon:SetDesaturated(true)
            btn.icon:SetAlpha(0.55 * visibilityAlpha)
            if btn.glow then btn.glow:Hide() end
        elseif not hasItem then
            -- Out of stock: desaturate, normal alpha
            btn.icon:SetDesaturated(true)
            btn.icon:SetAlpha(userIconAlpha * visibilityAlpha)
            if btn.glow then btn.glow:Hide() end
        elseif needsAttention then
            -- Ready and unbuffed: bright with pulsing glow
            btn.icon:SetDesaturated(false)
            btn.icon:SetAlpha(1.0 * visibilityAlpha)
            if btn.glow and maxGlowAlpha > 0 then
                btn.glow:SetVertexColor(gc.r, gc.g, gc.b)
                btn.glow:SetAlpha(alphaWave * visibilityAlpha)
                btn.glow:Show()
            end
        else
            -- Buffed (timer showing) or otherwise satisfied: normal dim, no glow
            btn.icon:SetDesaturated(false)
            btn.icon:SetAlpha(userIconAlpha * visibilityAlpha)
            if btn.glow then btn.glow:Hide() end
        end

        if btn.countText then
            btn.countText:SetAlpha(visibilityAlpha)
        end
    end
end)

-------------------------------------------------------------------------------
-- Rebuild
-------------------------------------------------------------------------------
function TBR_ConsBar_Rebuild()
    if InCombatLockdown() then return end
	UpdateItemCounts()

    local db = TankBuffReminderCharDB
    local globalDB = TankBuffReminderDB

    -- Cleanup old slots
    for _, slot in ipairs(slots) do
        if slot.btn then
            slot.btn:Hide()
            if slot.btn.glow then
                ReleaseGlow(slot.btn.glow)
                slot.btn.glow = nil
            end
            slot.btn:SetAttribute("type", nil)
            slot.btn:SetAttribute("macrotext", nil)
            table.insert(framePool, slot.btn)
        end
        table.wipe(slot)
        table.insert(slotPool, slot)
    end
    table.wipe(slots)

    if not db or not cfg.consumables or (globalDB and globalDB.consBarEnabled == false) then
        anchor:Hide()
        return
    end

    local enabled = {}
    for _, entry in ipairs(cfg.consumables) do
        local isEnabled = db["cons_" .. entry.key]
        if isEnabled == nil then isEnabled = entry.defaultOn end
        if isEnabled then
            table.insert(enabled, entry)
        end
    end

    if #enabled == 0 then
        anchor:Hide()
        return
    end

    local spacing = globalDB.consPadding or 4
    local totalW = (#enabled * BASE_SIZE) + (math_max(0, #enabled - 1) * spacing) + (PADDING * 2)
    anchor:SetSize(totalW, BASE_SIZE + PADDING * 2)

    local xOff = PADDING
    for i, entry in ipairs(enabled) do
        local slot = MakeSlot(i, entry, xOff)
        if slot then
            table.insert(slots, slot)
            xOff = xOff + BASE_SIZE + spacing
        end
    end

    TBR_ConsBar_UpdateVisuals()   -- Fixed call
    ReapplyAllHotkeys()
    anchor:Show()

    local pos = globalDB.consBar_pos
    if pos then
        anchor:ClearAllPoints()
        anchor:SetPoint(pos.p, UIParent, pos.rp, pos.x, pos.y)
    end
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------
local bagUpdatePending = false
local eF = CreateFrame("Frame")

eF:RegisterEvent("PLAYER_LOGIN")
eF:RegisterEvent("BAG_UPDATE_DELAYED")
eF:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eF:RegisterEvent("PLAYER_REGEN_ENABLED")

eF:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(0.5, function()
            UpdateItemCounts() -- Initialize the numbers
            TBR_ConsBar_Rebuild()
        end)
    elseif event == "BAG_UPDATE_DELAYED" or event == "PLAYER_REGEN_ENABLED" then
        if InCombatLockdown() then
            bagUpdatePending = true
            return
        end

        if event == "PLAYER_REGEN_ENABLED" and bagUpdatePending then
            UpdateItemCounts() -- Update numbers after combat
            TBR_ConsBar_Rebuild()
            bagUpdatePending = false
        elseif event == "BAG_UPDATE_DELAYED" and not bagUpdatePending then
            bagUpdatePending = true
            C_Timer.After(0.5, function()
                UpdateItemCounts() -- Update numbers after the delay
                TBR_ConsBar_Rebuild()
                bagUpdatePending = false
            end)
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if not InCombatLockdown() then
            UpdateItemCounts()
            TBR_ConsBar_Rebuild()
        end
    end
end)

function TBR_ConsBar_Toggle()
    if TankBuffReminderDB then
        TankBuffReminderDB.consBarEnabled = not anchor:IsShown()
    end
    if anchor:IsShown() then
        anchor:Hide()
    else
        TBR_ConsBar_Rebuild()
    end
end