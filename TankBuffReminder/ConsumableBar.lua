-- ConsumableBar.lua
local L   = TBR_L
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
local BASE_SIZE = TankBuffReminderConfig.defaults.consBaseSize or 36
local PADDING = 6
local POTION_SHARED_CD_ITEM = 13446

-------------------------------------------------------------------------------
-- Pools & Memory Management
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
local WELL_FED_NAME = "Well Fed"
local _currentBuffs = {}
local _lastCounts = {}
local _tempColor = { r = 0, g = 1, b = 0, a = 1 }

-- Loss-of-control
local LOC_BLOCK = { STUN=true, STUN_MECHANIC=true, FEAR=true,
                    CHARM=true, CONFUSE=true, POSSESS=true }

-- Pre-allocated pool for buff scan entries — reused every second, zero allocations
local _buffEntryPool = {}
do
    for i = 1, 40 do _buffEntryPool[i] = { exp = 0, dur = 0 } end
end
local _buffEntryCount = 0  

-------------------------------------------------------------------------------
-- Hotkey System
-------------------------------------------------------------------------------
local hotkeyDialog
local hotkeyCapturing
local MODIFIER_KEYS = { LSHIFT=true, RSHIFT=true, LCTRL=true, RCTRL=true,
                        LALT=true,   RALT=true,   LMETA=true, RMETA=true }


local function BuildHotkeyStrings(key)
    if MODIFIER_KEYS[key] then return nil, nil end

    local bindParts = {}
    if IsShiftKeyDown()   then bindParts[#bindParts+1] = "SHIFT" end
    if IsControlKeyDown() then bindParts[#bindParts+1] = "CTRL"  end
    if IsAltKeyDown()     then bindParts[#bindParts+1] = "ALT"   end

    local bindKey = key:upper()
    bindParts[#bindParts+1] = bindKey
    local bindingKey = table.concat(bindParts, "-")

    local dispParts = {}
    if IsShiftKeyDown()   then dispParts[#dispParts+1] = "Shift" end
    if IsControlKeyDown() then dispParts[#dispParts+1] = "Ctrl"  end
    if IsAltKeyDown()     then dispParts[#dispParts+1] = "Alt"   end
    local dispKey = (#key == 1) and key:upper() or key
    dispParts[#dispParts+1] = dispKey
    local displayStr = table.concat(dispParts, "+")

    return bindingKey, displayStr
end

local function GetModifierPreviewStr()
    local parts = {}
    if IsShiftKeyDown()   then parts[#parts+1] = "Shift" end
    if IsControlKeyDown() then parts[#parts+1] = "Ctrl"  end
    if IsAltKeyDown()     then parts[#parts+1] = "Alt"   end
    return #parts > 0 and (table.concat(parts, "+") .. "+") or ""
end

local function FindExistingOwner(bindingKey)
    local db = TankBuffReminderDB
    if not db or not db.consHotkeys then return nil end
    for entryKey, hk in pairs(db.consHotkeys) do
        if hk and hk.bind == bindingKey then return entryKey end
    end
    return nil
end

local function EntryNameForKey(entryKey)
    if not entryKey or not cfg or not cfg.consumables then return entryKey end
    for _, e in ipairs(cfg.consumables) do
        if e.key == entryKey then return e.label or e.key end
    end
    return entryKey
end

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

local function RefreshHotkeyLabel(btn, entryKey)
    if not btn.hotkeyText then return end
    local db = TankBuffReminderDB
    local hk = db and db.consHotkeys and db.consHotkeys[entryKey]
    if hk and hk.display then        
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

local function CommitHotkey(entryKey, bindingKey, displayStr)
    if not entryKey or not bindingKey then return end
    local db = TankBuffReminderDB
    if not db then return end
    if not db.consHotkeys then db.consHotkeys = {} end
    db.consHotkeys[entryKey] = { bind = bindingKey, display = displayStr }
    for _, slot in ipairs(slots) do
        if slot.entry and slot.entry.key == entryKey then
            ApplyHotkeyBinding(slot.btn, entryKey, true)  
            RefreshHotkeyLabel(slot.btn, entryKey)
            break
        end
    end
end

local function ClearHotkey(entryKey)
    if not entryKey then return end
    local db = TankBuffReminderDB
    if not db or not db.consHotkeys then return end
    db.consHotkeys[entryKey] = nil
    for _, slot in ipairs(slots) do
        if slot.entry and slot.entry.key == entryKey then
            ApplyHotkeyBinding(slot.btn, entryKey, true)  
            RefreshHotkeyLabel(slot.btn, entryKey)
            break
        end
    end
end

-- Hotkey Capture Dialog
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

    f:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then self:StartMoving() end
    end)
    f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", f, "TOP", 0, -16)
    f.title:SetText(L["Set Hotkey"])

    f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.label:SetPoint("TOP", f.title, "BOTTOM", 0, -10)
    f.label:SetWidth(260)
    f.label:SetJustifyH("CENTER")
    f.label:SetText(L["HOTKEY_PROMPT"])

    f.keyDisplay = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    f.keyDisplay:SetPoint("TOP", f.label, "BOTTOM", 0, -8)
    f.keyDisplay:SetText("")
    f.keyDisplay:SetTextColor(1, 0.82, 0)

    local captureFrame = CreateFrame("Frame", nil, f)
    captureFrame:SetAllPoints()
    captureFrame:EnableKeyboard(true)
    captureFrame:SetPropagateKeyboardInput(false)
    f.captureFrame = captureFrame

	captureFrame:SetScript("OnKeyDown", function(self, key)
		if key == "ESCAPE" then
			f:Hide()
			return
		elseif key == "BACKSPACE" then
			ClearHotkey(hotkeyCapturing)
			f:Hide()
			return
		end
        local bindingKey, displayStr = BuildHotkeyStrings(key)
        if not bindingKey then
            f.keyDisplay:SetText(GetModifierPreviewStr() .. "…")
            return
        end

        f.keyDisplay:SetText(displayStr)

        local addonOwner = FindExistingOwner(bindingKey)
        if addonOwner and addonOwner ~= hotkeyCapturing then
            if f._pendingBind == bindingKey and f._pendingOwner == addonOwner then
                ClearHotkey(f._pendingOwner)
                CommitHotkey(hotkeyCapturing, bindingKey, displayStr)
                f:Hide()
            else
                f.label:SetText(string.format(L["HOTKEY_CONFLICT_ADDON"], EntryNameForKey(addonOwner)))
                f._pendingBind    = bindingKey
                f._pendingDisplay = displayStr
                f._pendingOwner   = addonOwner
                f._pendingIsWoW   = false
            end
            return
        end

        local wowAction = GetBindingAction(bindingKey, true)
        if wowAction and wowAction ~= "" then
            local friendlyName = _G["BINDING_NAME_" .. wowAction] or wowAction
            if f._pendingBind == bindingKey and f._pendingIsWoW then
                CommitHotkey(hotkeyCapturing, bindingKey, displayStr)
                f:Hide()
            else
                f.label:SetText(string.format(L["HOTKEY_CONFLICT_WOW"], friendlyName))
                f._pendingBind    = bindingKey
                f._pendingDisplay = displayStr
                f._pendingOwner   = nil
                f._pendingIsWoW   = true
            end
            return
        end

        f._pendingBind  = nil
        f._pendingIsWoW = false
        CommitHotkey(hotkeyCapturing, bindingKey, displayStr)
        f:Hide()
    end)

    f:SetScript("OnShow", function(self)
        self._pendingBind    = nil
        self._pendingDisplay = nil
        self._pendingOwner   = nil
        self._pendingIsWoW   = false
        self.keyDisplay:SetText("")
        self.label:SetText(L["HOTKEY_PROMPT"])
        self.captureFrame:EnableKeyboard(true)
    end)
    f:SetScript("OnHide", function(self)
        self.captureFrame:EnableKeyboard(false)
        hotkeyCapturing = nil
    end)

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(80, 22)
    cancelBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 14)
    cancelBtn:SetText(L["Cancel"])
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    f:Hide()
    hotkeyDialog = f
    return f
end

local function OpenHotkeyDialog(entryKey)
    if not entryKey then return end
    if InCombatLockdown() then
        UIErrorsFrame:AddMessage("|cffff6060" .. L["Cannot set hotkeys in combat."] .. "|r")
        return
    end
    hotkeyCapturing = entryKey
    local dlg = GetOrCreateHotkeyDialog()
    dlg.title:SetText(L["Set Hotkey"] .. " – " .. EntryNameForKey(entryKey))
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
anchor:SetMouseMotionEnabled(true)

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

anchor:SetPropagateMouseMotion(true)
anchor:SetPropagateMouseClicks(true)

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
    if not cfg or not cfg.consumables then return end
    
    for _, entry in ipairs(cfg.consumables) do
        if entry.key then
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
-- TBR_ConsBar_UpdateVisuals
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

        -- Updates the count text alpha when visual settings/sliders change
		if btn.countText then            
            slot._forceCountAlphaRefresh = true
        end
    end
end

-------------------------------------------------------------------------------
-- Slot Factory
-------------------------------------------------------------------------------
local function MakeSlot(index, entry, xOffset, yOffset)
    local resolvedID = BestItemID(entry.itemIDs)
    if not resolvedID then return nil end

    local btn = table.remove(framePool)
    local slot = table.remove(slotPool) or {}

    if not btn then
        btn = CreateFrame("Button", "TBR_CBSlot" .. (#slots + #framePool + 1), anchor, "SecureActionButtonTemplate")
        btn:RegisterForClicks("AnyUp", "AnyDown")

		btn:SetScript("PreClick", function(self, button, down)
			self._didDisableUnshift = false

			if button == "LeftButton" and self.druidInstant and not IsControlKeyDown() then
				local blocked = false

				local locCount = C_LossOfControl.GetActiveLossOfControlDataCount()
				for i = locCount, 1, -1 do
					local locData = C_LossOfControl.GetActiveLossOfControlData(i)
					if locData and LOC_BLOCK[locData.locType] then
						blocked = true
						break
					end
				end

				if not blocked then
					local _, gcdDur = GetSpellCooldown(768)
					if gcdDur and gcdDur > 0 then blocked = true end
				end

				if blocked then
					SetCVar("autoUnshift", 0)
					self._didDisableUnshift = true
				end
			end
		end)

		btn:SetScript("PostClick", function(self, button, down)
			if self._didDisableUnshift then
				SetCVar("autoUnshift", 1)
				self._didDisableUnshift = false
			elseif button == "LeftButton" and IsControlKeyDown() then
				local slotEntry = self.entry
				if slotEntry then
					OpenHotkeyDialog(slotEntry.key)
				end
			end
		end)

        -- Clear out parent bubbling entirely from the secure templates to solve mouse leaks
        btn:SetPropagateMouseMotion(true)
        btn:SetPropagateMouseClicks(false)

        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetAllPoints()
        btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        btn.cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
        btn.cd:SetAllPoints()
        btn.cd:SetDrawEdge(false)
        btn.cd:SetDrawSwipe(true)

        for i = 1, btn.cd:GetNumRegions() do
            local region = select(i, btn.cd:GetRegions())
            if region and region:GetObjectType() == "FontString" then
                btn.cdText = region
                break
            end
        end

        btn.countText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        btn.countText:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, 2)
        btn.hotkeyText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        btn.hotkeyText:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
        btn.hotkeyText:SetTextColor(1, 1, 1)
        btn.hotkeyText:Hide()

        btn.lockOverlay = btn:CreateTexture(nil, "OVERLAY")
        btn.lockOverlay:SetAllPoints()
        btn.lockOverlay:SetColorTexture(0, 0, 0, 0.6)
        btn.lockOverlay:Hide()

        btn.glow = GetOrCreateGlow(btn)

        -- Shift-Drag Interceptor Frame (Completely masks out secure action executing on click)
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

        local kf = CreateFrame("Frame", nil, btn)
        kf:SetAllPoints()
        kf:EnableKeyboard(true)
        kf:SetPropagateKeyboardInput(true)
        kf:SetScript("OnKeyDown", function(_, key)
            if key == "BACKSPACE" then
                local entry = btn.entry
                if entry then
                    ClearHotkey(entry.key)
                    if GameTooltip:IsOwned(btn) then
                        GameTooltip:ClearLines()
                        GameTooltip:SetItemByID(btn.currentItemID)
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine(L["|cff888888Ctrl+Click|r to set a hotkey"], 0.7, 0.7, 0.7, true)
                        GameTooltip:Show()
                    end
                end
            end
        end)
        kf:Hide()
        btn._keyListener = kf

        btn:SetScript("OnEnter", function(self)
            if anchor.isMoving then return end
            local itemID = self.currentItemID
            if not itemID then return end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(itemID)

            local slotEntry = self.entry
            if self.druidInstant then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["|cff00ff00Bear-safe:|r re-enters Bear or Cat Form after use."], 1, 1, 1, true)
            elseif slotEntry and slotEntry.druidWarn then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["|cffff8800Warning:|r drops Bear Form."], 1, 0.6, 0, true)
            end

            local totalCount = 0
            if slotEntry then
                for _, id in ipairs(slotEntry.itemIDs) do
                    totalCount = totalCount + GetItemCount(id, false)
                end
            end
            GameTooltip:AddDoubleLine(L["Total in Bags:"], totalCount, 1, 1, 1, 1, 1, 1)

            local db = TankBuffReminderDB
            local hk = db and db.consHotkeys and slotEntry and db.consHotkeys[slotEntry.key]
            if hk and hk.display then
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine(L["Hotkey:"], hk.display, 0.6, 0.6, 0.6, 1, 0.82, 0)
                GameTooltip:AddLine(L["|cff888888Backspace|r to clear  •  |cff888888Ctrl+Click|r to rebind"], 0.7, 0.7, 0.7, true)
            else
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["|cff888888Ctrl+Click|r to set a hotkey"], 0.7, 0.7, 0.7, true)
            end

            GameTooltip:Show()
            self._keyListener:Show()
        end)
        btn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            if self._keyListener then self._keyListener:Hide() end
        end)
    else
        if not btn.glow then
            btn.glow = GetOrCreateGlow(btn)
        end
    end

    btn:SetSize(BASE_SIZE, BASE_SIZE)
    btn:ClearAllPoints()
    if (TankBuffReminderDB and TankBuffReminderDB.consOrientation == "vertical") then
        btn:SetPoint("TOP", anchor, "TOP", 0, yOffset or 0)
    else
        btn:SetPoint("LEFT", anchor, "LEFT", xOffset, 0)
    end

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
local _countStrCache = {}
do
    for i = 1, 300 do _countStrCache[i] = tostring(i) end
end

local function CountStr(n)
    return (n > 0) and (_countStrCache[n] or tostring(n)) or ""
end

local _lastInCombat = false
local _pendingBuffs = {}

local function UpdateSlotVisuals()
    local pStart, pDur = SafeGetCD(POTION_SHARED_CD_ITEM)
    local potionCDActive = pDur > 1.5
    local inCombat = InCombatLockdown()
    local combatChanged = (inCombat ~= _lastInCombat)
    _lastInCombat = inCombat

    -- Monitor Shift status globally on update loops to handle the drag mask overlay
    local isShift = IsShiftKeyDown()

    for _, slot in ipairs(slots) do
        local entry = slot.entry
        local btn = slot.btn

        -- Toggle drag interception layer dynamically depending on key status
        if btn.dragMask then
            if isShift and not inCombat then
                btn.dragMask:Show()
            else
                btn.dragMask:Hide()
            end
        end

        -- Update item count
        local totalCount = itemCountCache[entry.key]
        if totalCount == nil then
            totalCount = 0
            for i = 1, #entry.itemIDs do
                totalCount = totalCount + GetItemCount(entry.itemIDs[i], false)
            end
            itemCountCache[entry.key] = totalCount
        end

        local resID = BestItemID(entry.itemIDs)

        if resID ~= btn.currentItemID and not inCombat then
            ApplyButtonAttributes(slot, entry)
        end

        -- === POTION SHARED CD + INDIVIDUAL CD HANDLING ===
        if not slot._showingBuff then
            local start, duration = SafeGetCD(resID)

            if entry.isPotionType and potionCDActive then
                if pDur > (duration or 0) then
                    start, duration = pStart, pDur
                end
            end

            if duration > 0 and duration < 1.4 then
                duration = 0
            end

            if duration > 1.5 then
                if slot._lastStart ~= start or slot._lastDuration ~= duration then
                    slot.cd:SetCooldown(start, duration)
                    slot._lastStart    = start
                    slot._lastDuration = duration
                end
                if not slot._cdShown then
                    slot.cd:Show()
                    slot._cdShown = true
                end
                slot._cdZeroTicks = 0
            else
                slot._cdZeroTicks = (slot._cdZeroTicks or 0) + 1
                if slot._cdZeroTicks >= 2 then
                    if slot._cdShown or slot._lastDuration ~= 0 then
                        slot._lastDuration = 0
                        slot._lastStart    = 0
                        slot._cdShown      = false
                        slot.cd:Hide()
                    end
                end
            end
        end

        if _lastCounts[btn] ~= totalCount then
            slot.count:SetText(CountStr(totalCount))
            _lastCounts[btn] = totalCount
        end

        if combatChanged then
            if inCombat then
                slot.lock:SetAlpha(0.25)
                slot.lock:Show()
                if btn.dragMask then btn.dragMask:Hide() end
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
    local cdb = TankBuffReminderCharDB
    if not db then return end

    local speed = db.consPulseSpeed or 3
    if speed > 0 then
        pulseTimer = (pulseTimer + pulseElapsed * speed) % TWO_PI
    end
    pulseElapsed = 0

    local isOver = anchor:IsMouseOver()
    local hidden = db.consMouseover and not isOver
    local visibilityAlpha = hidden and 0 or 1.0
    local frameAlphaSetting = db.consFrameAlpha or 0.3

    if anchor.bg then anchor.bg:SetAlpha(visibilityAlpha * frameAlphaSetting) end
    if anchor.SetBackdropBorderColor then
        anchor:SetBackdropBorderColor(1, 1, 1, visibilityAlpha * frameAlphaSetting)
    end

    -- Force fallback execution check if user released shift mid-drag away from frame bounds
    if self.isMoving and not IsShiftKeyDown() then
        self:StopMovingOrSizing()
        self.isMoving = false
        local p, _, rp, x, y = self:GetPoint()
        db.consBar_pos = { p = p, rp = rp, x = x, y = y }
    end

    if hidden ~= anchor._lastHidden then
        anchor._lastHidden = hidden
        for _, slot in ipairs(slots) do
            local btn = slot.btn
            if btn.hotkeyText then
                if hidden then
                    btn.hotkeyText:Hide()
                else
                    RefreshHotkeyLabel(btn, slot.entry and slot.entry.key)
                end
            end
        end
    end

    -- ── Step 1: Refresh the buff cache ──
    local now = GetTime()
    local doFullScan = (now - lastBuffScan) > 1.0

    if doFullScan then
        lastBuffScan = now
        table.wipe(_pendingBuffs)
        _buffEntryCount = 0
        for i = 1, 40 do
            local name, _, _, _, dur, exp, _, _, _, sid = UnitBuff("player", i)
            if not name then break end
            _buffEntryCount = _buffEntryCount + 1
            local entry = _buffEntryPool[_buffEntryCount]
            entry.exp = exp or 0
            entry.dur = dur or 0
            if sid then _pendingBuffs[sid] = entry end
            _pendingBuffs[name] = entry
            if name == WELL_FED_NAME then
                _pendingBuffs["FOOD"] = entry
            end
        end
        _currentBuffs, _pendingBuffs = _pendingBuffs, _currentBuffs
    end

    -- ── Step 2: Update slot._showingBuff from fresh cache ──
    for _, slot in ipairs(slots) do
        local entry = slot.entry

        local activeBuff = nil
        if entry.buffSpellID then
            if type(entry.buffSpellID) == "table" then
                for _, sid in ipairs(entry.buffSpellID) do
                    if _currentBuffs[sid] then activeBuff = _currentBuffs[sid]; break end
                end
            else
                activeBuff = _currentBuffs[entry.buffSpellID]
            end
        end
        if not activeBuff and entry.buffSpellID then
            local spellName = GetSpellInfo(type(entry.buffSpellID) == "table" and entry.buffSpellID[1] or entry.buffSpellID)
            if spellName then activeBuff = _currentBuffs[spellName] end
        end
        if not activeBuff and entry.category == "Food" then
            activeBuff = _currentBuffs["FOOD"]
        end
        slot._activeBuff = activeBuff
    end

    -- ── Step 3: Item cooldown + count updates ──
    UpdateSlotVisuals()

    -- ── Step 4: Visual pass ──
    local maxGlowAlpha = db.consGlowAlpha or 1.0
    local alphaWave = (0.7 + math_sin(pulseTimer) * 0.3) * maxGlowAlpha
    local userIconAlpha = db.consAlpha or 1.0
    local gc = db.consGlowColor or { r = _DEFAULT_R, g = _DEFAULT_G, b = _DEFAULT_B }

    for _, slot in ipairs(slots) do
        local entry = slot.entry
        local btn = slot.btn

        local totalCount = itemCountCache[entry.key] or 0
        local hasItem = totalCount > 0

        local activeBuff = slot._activeBuff

        if activeBuff and activeBuff.exp > 0 then
            local buffStart = activeBuff.exp - activeBuff.dur
            if slot._buffStart ~= buffStart or slot._buffDur ~= activeBuff.dur then
                slot.cd:SetCooldown(buffStart, activeBuff.dur)
                slot.cd:SetSwipeColor(0, 0, 0, db.consSweepAlpha or 0.7)
                slot.cd:Show()
                slot._cdShown   = true
                slot._buffStart = buffStart
                slot._buffDur   = activeBuff.dur
            end
            slot._showingBuff = true
        elseif entry.category == "Weapon" then
            local hasMH, mhExpMs = GetWeaponEnchantInfo()
            if hasMH and mhExpMs and mhExpMs > 0 then
                local mhRemaining = mhExpMs / 1000
                local prevRemaining = slot._buffDur or 0
                if not slot._buffStart or mhRemaining > prevRemaining + 2 then
                    slot.cd:SetCooldown(now, mhRemaining)
                    slot.cd:SetSwipeColor(0, 0, 0, db.consSweepAlpha or 0.7)
                    slot.cd:Show()
                    slot._cdShown   = true
                    slot._buffStart = now
                    slot._buffDur   = mhRemaining
                else
                    slot._buffDur = mhRemaining
                end
                slot._showingBuff = true
            else
                if slot._showingBuff then
                    slot.cd:Hide()
                    slot._cdShown = false
                end
                slot._showingBuff = false
                slot._buffStart   = nil
                slot._buffDur     = nil
            end
        else
            if slot._showingBuff then
                slot.cd:Hide()
                slot._cdShown = false
            end
            slot._showingBuff = false
            slot._buffStart   = nil
            slot._buffDur     = nil
        end

        local isOffCD = not slot.cd:IsShown()
        local needsAttention = false

        if isOffCD then
            if entry.category == "Weapon" then
                if hasItem then
                    local hasMH, mhExpMs = GetWeaponEnchantInfo()
                    needsAttention = not hasMH or (mhExpMs and (mhExpMs / 1000) < 120)
                end
            elseif not slot._showingBuff and hasItem then
                needsAttention = true
            end
        end

        local wantDesat, wantAlpha, wantGlow, wantGlowAlpha
        local onItemCD = not isOffCD and not slot._showingBuff

        if not hasItem then
            wantDesat = true
            wantAlpha = userIconAlpha * visibilityAlpha
            wantGlow  = false
        elseif onItemCD then
            wantDesat = true
            wantAlpha = 0.55 * visibilityAlpha
            wantGlow  = false
        elseif not isOffCD and slot._showingBuff then
            wantDesat = false
            wantAlpha = userIconAlpha * visibilityAlpha
            wantGlow  = false
        elseif needsAttention then
            wantDesat     = false
            wantAlpha     = 1.0 * visibilityAlpha
            wantGlow      = (maxGlowAlpha > 0)
            wantGlowAlpha = alphaWave * visibilityAlpha
        else
            wantDesat = false
            wantAlpha = userIconAlpha * visibilityAlpha
            wantGlow  = false
        end

        if btn.icon:IsDesaturated() ~= wantDesat then
            btn.icon:SetDesaturated(wantDesat)
        end
        if slot._lastIconAlpha ~= wantAlpha then
            btn.icon:SetAlpha(wantAlpha)
            slot._lastIconAlpha = wantAlpha
        end

        if btn.glow then
            if wantGlow then
                if slot._lastGlowAlpha ~= wantGlowAlpha then
                    btn.glow:SetVertexColor(gc.r, gc.g, gc.b)
                    btn.glow:SetAlpha(wantGlowAlpha)
                    slot._lastGlowAlpha = wantGlowAlpha
                end
                if not btn.glow:IsShown() then btn.glow:Show() end
            else
                if btn.glow:IsShown() then
                    btn.glow:Hide()
                    slot._lastGlowAlpha = nil
                end
            end
        end

        if btn.countText then
            local countAlpha
            if isOffCD and not slot._showingBuff then
                countAlpha = 1.0 * visibilityAlpha
            else
                countAlpha = (userIconAlpha or 1.0) * visibilityAlpha
            end

            if slot._lastCountAlpha ~= countAlpha or slot._forceCountAlphaRefresh then
                btn.countText:SetAlpha(countAlpha)
                slot._lastCountAlpha = countAlpha
                slot._forceCountAlphaRefresh = nil
            end
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

    for _, slot in ipairs(slots) do
        if slot.btn then
            slot.btn:Hide()
            if slot.btn.glow then
                ReleaseGlow(slot.btn.glow)
                slot.btn.glow = nil
            end
            slot.btn:SetAttribute("type", nil)
            slot.btn:SetAttribute("macrotext", nil)
            if slot.btn.dragMask then slot.btn.dragMask:Hide() end
            table.insert(framePool, slot.btn)
        end
        table.wipe(slot)
        table.insert(slotPool, slot)
    end
    table.wipe(slots)
    table.wipe(_lastCounts)
    table.wipe(_currentBuffs)
    _buffEntryCount = 0

    if not db or not cfg.consumables or (globalDB and globalDB.consBarEnabled == false) then
        anchor:Hide()
        return
    end

    local hideEmpty = (globalDB.consHideEmpty == true)

    local enabled = {}
    for _, entry in ipairs(cfg.consumables) do
        local isEnabled = db["cons_" .. entry.key]
        if isEnabled == nil then isEnabled = entry.defaultOn end
        if isEnabled then
            if hideEmpty then
                local total = 0
                for _, id in ipairs(entry.itemIDs) do
                    total = total + GetItemCount(id, false)
                end
                if total > 0 then
                    table.insert(enabled, entry)
                end
            else
                table.insert(enabled, entry)
            end
        end
    end

    if #enabled == 0 then
        anchor:Hide()
        return
    end

    local spacing = globalDB.consPadding or 4
    local isVertical = (globalDB.consOrientation == "vertical")

    if isVertical then
        local totalH = (#enabled * BASE_SIZE) + (math_max(0, #enabled - 1) * spacing) + (PADDING * 2)
        anchor:SetSize(BASE_SIZE + PADDING * 2, totalH)
    else
        local totalW = (#enabled * BASE_SIZE) + (math_max(0, #enabled - 1) * spacing) + (PADDING * 2)
        anchor:SetSize(totalW, BASE_SIZE + PADDING * 2)
    end

    local xOff = PADDING
    local yOff = -(PADDING)
    for i, entry in ipairs(enabled) do
        local slot = MakeSlot(i, entry, xOff, yOff)
        if slot then
            table.insert(slots, slot)
            if isVertical then
                yOff = yOff - BASE_SIZE - spacing
            else
                xOff = xOff + BASE_SIZE + spacing
            end
        end
    end

    TBR_ConsBar_UpdateVisuals()
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
eF:RegisterEvent("UNIT_AURA")

eF:SetScript("OnEvent", function(self, event, arg1)
    if TankBuffReminderCharDB and TankBuffReminderCharDB.disabled and event ~= "PLAYER_LOGIN" then return end

    if event == "PLAYER_LOGIN" then
        C_Timer.After(0.5, function()
            UpdateItemCounts()
            TBR_ConsBar_Rebuild()
        end)

    elseif event == "BAG_UPDATE_DELAYED" then
        if InCombatLockdown() then
            bagUpdatePending = true
            return
        end

        C_Timer.After(0.15, function()   
            UpdateItemCounts()

            local globalDB = TankBuffReminderDB
            if globalDB and globalDB.consHideEmpty then
                TBR_ConsBar_Rebuild()
            else
                lastBuffScan = 0
                
				for _, slot in ipairs(slots) do
					if slot.btn and slot.cd then
						local totalCount = itemCountCache[slot.entry.key] or 0
						if totalCount > 0 then
							if slot._cdShown then
								slot.cd:Hide()
								slot._cdShown = false
							end
							slot._lastDuration = 0
							slot._lastStart = 0
							slot._cdZeroTicks = 3
						end
					end
				end
            end
        end)

    elseif event == "PLAYER_REGEN_ENABLED" then
        C_Timer.After(0.1, function()
            UpdateItemCounts()
            
            if bagUpdatePending then
                bagUpdatePending = false
                TBR_ConsBar_Rebuild()
            else
                lastBuffScan = 0
                
                for _, slot in ipairs(slots) do
                    if slot.btn and slot.cd then
                        local totalCount = itemCountCache[slot.entry.key] or 0
                        if totalCount > 0 and slot._cdShown then
                            slot.cd:Hide()
                            slot._cdShown = false
                            slot._lastDuration = 0
                            slot._lastStart = 0
                            slot._cdZeroTicks = 3
                        end
                    end
                end
            end
        end)

    elseif event == "UNIT_AURA" then
        if arg1 == "player" then
            lastBuffScan = 0
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