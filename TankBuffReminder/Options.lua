-- Options.lua
local L   = TBR_L
local cfg = TankBuffReminderConfig

-------------------------------------------------------------------------------
-- Root panel
-------------------------------------------------------------------------------
local panel = CreateFrame("Frame", "TankBuffReminderOptions")
panel.name  = L["Tank Buff Reminder"]

local panelTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
panelTitle:SetPoint("TOPLEFT", 16, -16)
panelTitle:SetText(L["Tank Buff Reminder"])

local panelSub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
panelSub:SetPoint("TOPLEFT", panelTitle, "BOTTOMLEFT", 0, -4)
panelSub:SetTextColor(0.6, 0.6, 0.6)
panelSub:SetText(L["Select a tab below to configure."])

-------------------------------------------------------------------------------
-- Tab system
-------------------------------------------------------------------------------
local TAB_NAMES = { L["Buffs"], L["Appearance"], L["Alerts"], L["Automation"], L["Consumables"] }
local tabs, tabPages, activeTab = {}, {}, 1
local TAB_Y, PAGE_TOP, PAGE_L, PAGE_R = -50, -80, 12, -12

local function ShowTab(index)
    activeTab = index
    for i, page in ipairs(tabPages) do page:SetShown(i == index) end
    for i, t in ipairs(tabs) do
        local tex = t:GetNormalTexture()
        if tex then
            if i == index then t:SetNormalFontObject("GameFontNormal"); tex:SetAlpha(1)
            else t:SetNormalFontObject("GameFontDisable"); tex:SetAlpha(0.6) end
        end
    end
    PanelTemplates_SetTab(panel, index)
end

panel.numTabs = #TAB_NAMES
for i, name in ipairs(TAB_NAMES) do
    local t = CreateFrame("Button", "TankBuffReminderTab" .. i, panel, "TabButtonTemplate")
    t:SetText(name); t:SetID(i)
    if i == 1 then t:SetPoint("TOPLEFT", panel, "TOPLEFT", PAGE_L, TAB_Y)
    else t:SetPoint("LEFT", tabs[i-1], "RIGHT", 6, 0) end
    PanelTemplates_TabResize(t, 0)
    t:SetFrameStrata("HIGH"); t:SetFrameLevel(panel:GetFrameLevel() + 10)
    t:SetScript("OnClick", function() ShowTab(i) end)
    tabs[i] = t
end
panel.Tabs = tabs

for i = 1, #TAB_NAMES do
    local page = CreateFrame("Frame", nil, panel)
    page:SetPoint("TOPLEFT",     panel, "TOPLEFT",     PAGE_L,  PAGE_TOP)
    page:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", PAGE_R,  12)
    page:Hide(); tabPages[i] = page
end

-------------------------------------------------------------------------------
-- Shared widget helpers
-------------------------------------------------------------------------------
local function MakeHeader(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y); fs:SetText(text); fs:SetTextColor(1, 0.82, 0)
    return fs
end

local function MakeDivider(parent, y)
    local t = parent:CreateTexture(nil, "ARTWORK"); t:SetHeight(1)
    t:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0,   y)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, y)
    t:SetColorTexture(0.35, 0.30, 0.09, 0.8); return t
end

local function CreateCheckbox(parent, label, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y); cb.Text:SetText(label); return cb
end

local function CreateIntSlider(parent, label, minVal, maxVal, x, y, uName)
    local s = CreateFrame("Slider", uName, parent, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", x, y); s:SetMinMaxValues(minVal, maxVal)
    s:SetValueStep(1); s:SetObeyStepOnDrag(true); s:SetWidth(180)
    local title = _G[uName.."Text"]; title:SetText(label); s.label = label
    s:SetScript("OnValueChanged", function(self, v)
        title:SetText(string.format("%s: %d", self.label, v))
    end); return s
end

local function CreateFloatSlider(parent, label, minVal, maxVal, x, y, uName)
    local s = CreateFrame("Slider", uName, parent, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", x, y); s:SetMinMaxValues(minVal, maxVal)
    s:SetValueStep(0.05); s:SetObeyStepOnDrag(true); s:SetWidth(180)
    local title = _G[uName.."Text"]; title:SetText(label); s.label = label
    s:SetScript("OnValueChanged", function(self, v)
        title:SetText(string.format("%s: %.2f", self.label, v))
    end); return s
end

local dropdownInfo = {}
local function CreateSoundDropdown(parent, uName, x, y)
    local dd = CreateFrame("Frame", uName, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", x, y); UIDropDownMenu_SetWidth(dd, 150)
    UIDropDownMenu_Initialize(dd, function(self, level)
        if not cfg.sounds or not TankBuffReminderCharDB then return end
        table.wipe(dropdownInfo)
        for _, sound in ipairs(cfg.sounds) do
            local sid = sound.id
            dropdownInfo.text    = sound.name
            dropdownInfo.checked = (TankBuffReminderCharDB[dd.dbKey] == sid)
            dropdownInfo.func    = function()
                TankBuffReminderCharDB[dd.dbKey] = sid
                UIDropDownMenu_SetText(dd, sound.name); PlaySound(sid, "Master")
            end
            UIDropDownMenu_AddButton(dropdownInfo)
        end
    end); return dd
end

local function SetDropdownLabel(dd, dbKey, defaultID)
    if not TankBuffReminderCharDB then return end
    local cur = TankBuffReminderCharDB[dbKey] or defaultID
    for _, sound in ipairs(cfg.sounds) do
        if sound.id == cur then UIDropDownMenu_SetText(dd, sound.name); return end
    end
    UIDropDownMenu_SetText(dd, L["Unknown Alert"])
end

local function CreateColorButton(parent, label, x, y, dbKey, defaultColor, onChange, useGlobal)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(18, 18); btn:SetPoint("TOPLEFT", x, y)
    local swatch = btn:CreateTexture(nil, "BACKGROUND")
    swatch:SetAllPoints(); swatch:SetColorTexture(1, 1, 1, 1); btn.swatch = swatch
    local lbl = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lbl:SetPoint("LEFT", btn, "RIGHT", 8, 0); lbl:SetText(label)
    local hasAlpha = (defaultColor.a ~= nil)
    btn:SetScript("OnClick", function()
        local db = useGlobal and TankBuffReminderDB or TankBuffReminderCharDB
        if not db[dbKey] then
            local dc = defaultColor
            db[dbKey] = { r=dc.r, g=dc.g, b=dc.b, a=dc.a }
        end
        local color = db[dbKey]
        ColorPickerFrame:SetupColorPickerAndShow({
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                color.r, color.g, color.b = r, g, b
                if hasAlpha then color.a = ColorPickerFrame:GetColorAlpha() or 1 end
                swatch:SetVertexColor(color.r, color.g, color.b)
                if onChange then onChange() end
            end,
            r=color.r, g=color.g, b=color.b,
            opacity=hasAlpha and (color.a or 1) or nil, hasOpacity=hasAlpha,
            cancelFunc = function(prev)
                color.r, color.g, color.b = prev.r, prev.g, prev.b
                if hasAlpha then color.a = prev.opacity or 1 end
                swatch:SetVertexColor(color.r, color.g, color.b)
                if onChange then onChange() end
            end,
        })
    end)
    function btn:Refresh()
        local db = useGlobal and TankBuffReminderDB or TankBuffReminderCharDB
        local c  = (db and db[dbKey]) or defaultColor
        swatch:SetVertexColor(c.r, c.g, c.b)
    end
    return btn
end

-------------------------------------------------------------------------------
-- Grayout helpers
-------------------------------------------------------------------------------
local function SetSubOptionState(cb, enabled)
    if not cb then return end
    cb:SetEnabled(enabled)
    cb.Text:SetTextColor(enabled and 1 or 0.5, enabled and 1 or 0.5, enabled and 1 or 0.5)
end

local function UpdateTauntOptionsVisuals(db)
    local on = db and db.tauntEnabled ~= false
    for _, cb in ipairs({ panel.tauntWarningCB, panel.tauntSayCB, panel.tauntYellCB,
                          panel.tauntPartyCB, panel.tauntRaidCB, panel.tauntSoundCB }) do
        SetSubOptionState(cb, on)
    end
end

local function UpdateThreatOptionsVisuals(db)
    local on = db and db.threatEnabled or false
    for _, cb in ipairs({ panel.threatWarningCB, panel.threatSayCB, panel.threatYellCB,
                          panel.threatPartyCB, panel.threatRaidCB, panel.threatSoundCB,
                          panel.threatMissCB, panel.threatResistCB, panel.threatCCCB,
                          panel.threatCCFullCombatCB }) do
        SetSubOptionState(cb, on)
    end
    if panel.threatWindowSlider then
        panel.threatWindowSlider:SetEnabled(on)
        local t = _G[panel.threatWindowSlider:GetName().."Text"]
        if t then t:SetTextColor(on and 1 or 0.5, on and 0.82 or 0.5, on and 0 or 0.5) end
    end
end

local function UpdateExtAlertsVisuals(db)
    -- Channel checkboxes need explicit white; InterfaceOptionsCheckButtonTemplate defaults to gold.
    -- extSoundCB is intentionally left gold — it's the section master, matching taunt/threat style.
    for _, cb in ipairs({ panel.extWarningCB, panel.extSayCB, panel.extYellCB,
                          panel.extPartyCB, panel.extRaidCB }) do
        SetSubOptionState(cb, true)
    end
end

-------------------------------------------------------------------------------
-- SyncSettings
-------------------------------------------------------------------------------
panel.checkboxes = {}

local function SyncSettings()
    if not TankBuffReminderCharDB then TankBuffReminderCharDB = {} end
    local db  = TankBuffReminderCharDB
    local gdb = TankBuffReminderDB or {}

    for key, cb in pairs(panel.checkboxes) do db[key] = cb:GetChecked() end

    -- Main bar
    TankBuffReminderDB.scale  = panel.buffBarScaleSlider:GetValue()
    db.pulseSpeed             = panel.pulseSlider:GetValue()
    db.glowSize               = panel.glowSlider:GetValue()
    db.frameAlpha             = panel.alphaSlider:GetValue()
    db.buffAlpha              = panel.buffAlphaSlider:GetValue()
    db.buttonPadding          = panel.paddingSlider:GetValue()
    db.sweepAlpha             = panel.sweepAlphaSlider:GetValue()
    db.timerTextOffsetY       = panel.timerOffsetSlider:GetValue()
    db.timerFontSize          = panel.timerFontSizeSlider:GetValue()
    db.timerAlpha             = panel.timerAlphaSlider:GetValue()

    -- Consumable bar
    gdb.consFrameAlpha    = panel.consFrameAlphaSlider:GetValue()
    gdb.consScale         = panel.consScaleSlider:GetValue()
    gdb.consAlpha         = panel.consAlphaSlider:GetValue()
    gdb.consPadding       = panel.consPaddingSlider:GetValue()
    gdb.consGlowAlpha     = panel.consGlowAlphaSlider:GetValue()
    gdb.consSweepAlpha    = panel.consSweepAlphaSlider:GetValue()
    gdb.consTimerFontSize = panel.consTimerFontSizeSlider:GetValue()
    gdb.consTimerOffsetY  = panel.consTimerOffsetSlider:GetValue()
    gdb.consTimerAlpha    = panel.consTimerAlphaSlider:GetValue()
    gdb.consPulseSpeed    = panel.consPulseSlider:GetValue()
    gdb.consMouseover     = panel.consMouseoverCB:GetChecked()
    gdb.consHideEmpty     = panel.consHideEmptyCB:GetChecked()
    gdb.consOrientation   = panel.consOrientVertRB:GetChecked() and "vertical" or "horizontal"
    if not gdb.consGlowColor then gdb.consGlowColor = {r=0,g=1,b=0,a=1} end
    if not gdb.consTextColor  then gdb.consTextColor  = {r=1,g=1,b=1} end

    -- External bar appearance
    gdb.extBarScale           = panel.extBarScaleSlider:GetValue()
    gdb.extBarButtonPadding   = panel.extPaddingSlider:GetValue()
    db.extGlowSize            = panel.extGlowSlider:GetValue()
    db.extPulseSpeed          = panel.extPulseSlider:GetValue()
    db.extFrameAlpha          = panel.extFrameAlphaSlider:GetValue()
    db.extBuffAlpha           = panel.extBuffAlphaSlider:GetValue()
    db.extSweepAlpha          = panel.extSweepAlphaSlider:GetValue()
    db.extTimerFontSize       = panel.extTimerFontSizeSlider:GetValue()
    db.extTimerTextOffsetY    = panel.extTimerOffsetSlider:GetValue()
    db.extTimerAlpha          = panel.extTimerAlphaSlider:GetValue()

    -- Alerts
    db.playSound          = panel.soundCB:GetChecked()           and true or false
    db.removeSoundEnabled = panel.removeSoundCB:GetChecked()     and true or false
    db.tauntEnabled       = panel.tauntEnabledCB:GetChecked()    and true or false
    db.tauntWarning       = panel.tauntWarningCB:GetChecked()    and true or false
    db.tauntSay           = panel.tauntSayCB:GetChecked()        and true or false
    db.tauntYell          = panel.tauntYellCB:GetChecked()       and true or false
    db.tauntParty         = panel.tauntPartyCB:GetChecked()      and true or false
    db.tauntRaid          = panel.tauntRaidCB:GetChecked()       and true or false
    db.tauntSoundEnabled  = panel.tauntSoundCB:GetChecked()      and true or false
    db.threatEnabled      = panel.threatEnabledCB:GetChecked()   and true or false
    db.threatWarning      = panel.threatWarningCB:GetChecked()   and true or false
    db.threatSay          = panel.threatSayCB:GetChecked()       and true or false
    db.threatYell         = panel.threatYellCB:GetChecked()      and true or false
    db.threatParty        = panel.threatPartyCB:GetChecked()     and true or false
    db.threatRaid         = panel.threatRaidCB:GetChecked()      and true or false
    db.threatSoundEnabled = panel.threatSoundCB:GetChecked()     and true or false
    db.threatMiss         = panel.threatMissCB:GetChecked()      and true or false
    db.threatResist       = panel.threatResistCB:GetChecked()    and true or false
    db.threatCC           = panel.threatCCCB:GetChecked()        and true or false
    db.threatCCFullCombat = panel.threatCCFullCombatCB:GetChecked() and true or false
    db.threatWindow       = panel.threatWindowSlider:GetValue()

    -- External buff alerts
    db.extPlaySound = panel.extSoundCB:GetChecked()   and true or false
    db.extWarning   = panel.extWarningCB:GetChecked() and true or false
    db.extSay       = panel.extSayCB:GetChecked()     and true or false
    db.extYell      = panel.extYellCB:GetChecked()    and true or false
    db.extParty     = panel.extPartyCB:GetChecked()   and true or false
    db.extRaid      = panel.extRaidCB:GetChecked()    and true or false
    db.extWarnSeconds = math.floor(panel.extWarnSecsSlider:GetValue() + 0.5)

    -- Automation
    db.autoRemoveSalvation = panel.salvAutoRB:GetChecked()      and true or false
    db.showIconSalvation   = panel.salvIconRB:GetChecked()      and true or false
    db.autoRemoveBoP       = panel.bopAutoRB:GetChecked()       and true or false
    db.showIconBoP         = panel.bopIconRB:GetChecked()       and true or false
    db.autoSetTankRole     = panel.tankRoleCB:GetChecked()      and true or false
    db.autoSetTankRoleRaid = panel.tankRoleRaidCB:GetChecked()  and true or false
    db.autoRepair          = panel.repairCB:GetChecked()        and true or false
    db.defCapBtnShow       = panel.defCapBtnShowCB:GetChecked() and true or false
    db.defCapFontSize      = math.floor(panel.defCapFontSizeSlider:GetValue() + 0.5)
    db.defCapScale         = math.floor(panel.defCapScaleSlider:GetValue() * 100 + 0.5) / 100

    -- Consumables tab checkboxes
    if panel.consBarEnabledCB then
        gdb.consBarEnabled = panel.consBarEnabledCB:GetChecked() and true or false
    end
    if cfg.consumables and panel.consCBs then
        for _, entry in ipairs(cfg.consumables) do
            local k = "cons_" .. entry.key
            local cb = panel.consCBs[k]
            if cb then db[k] = cb:GetChecked() and true or false end
        end
    end

    -- External buff checkboxes + group-only toggle
    if panel.extBarUnlockCB then
        db.extBarUnlocked = panel.extBarUnlockCB:GetChecked() and true or false
    end
    if panel.extBuffsShowInPartyCB then
        db.extBuffsShowInParty = panel.extBuffsShowInPartyCB:GetChecked() and true or false
    end
    if panel.extBuffsShowInRaidCB then
        db.extBuffsShowInRaid = panel.extBuffsShowInRaidCB:GetChecked() and true or false
    end
    if panel.extSmartDetectCB then
        db.extSmartDetect = panel.extSmartDetectCB:GetChecked() and true or false
    end
    if panel.extBuffCBs and TankBuffReminderExternalBuffs then
        for _, entry in ipairs(TankBuffReminderExternalBuffs) do
            local cb = panel.extBuffCBs[entry.key]
            if cb then db["ext_"..entry.key] = cb:GetChecked() and true or false end
        end
    end

    -- Minimap
    if panel.mapBtnShowCB   then db.showMinimapButton    = panel.mapBtnShowCB:GetChecked() end
    if panel.mapAngleSlider  then db.minimapAngle         = math.floor(panel.mapAngleSlider:GetValue() + 0.5) end
    if panel.mapRadiusSlider then db.minimapRadiusOffset  = math.floor(panel.mapRadiusSlider:GetValue() + 0.5) end
    if TBR_MinimapButton and TBR_MinimapButton.UpdatePositionFromOffsets then
        TBR_MinimapButton:UpdatePositionFromOffsets()
    end

	-- Notify subsystems
	if TankBuffReminder_UpdateGlow  then TankBuffReminder_UpdateGlow()  end
	if TBR_UI_UpdateAlpha           then TBR_UI_UpdateAlpha()           end
	if TBR_UI_UpdateTimerStyle      then TBR_UI_UpdateTimerStyle()      end
	if TBR_DefCapBtn_Refresh        then TBR_DefCapBtn_Refresh()        end
	if TBR_ConsBar_UpdateVisuals    then TBR_ConsBar_UpdateVisuals()    end
	if TBR_ExtBar_UpdateGlow        then TBR_ExtBar_UpdateGlow()        end
	if TBR_ExtBar_UpdateAlpha       then TBR_ExtBar_UpdateAlpha()       end
	if TBR_ExtBar_UpdateTimerStyle  then TBR_ExtBar_UpdateTimerStyle()  end

	if panel._needsRebuild then
		panel._needsRebuild = false
		if TankBuffReminder_RebuildTrackedBuffs then TankBuffReminder_RebuildTrackedBuffs() end
		if TBR_UI_Rebuild then TBR_UI_Rebuild() end
	end

	if TBR_RemovalUI_Update then TBR_RemovalUI_Update() end

	if panel._needsConsRebuild then
		panel._needsConsRebuild = false
		if TBR_ConsBar_Rebuild then TBR_ConsBar_Rebuild() end
	end

	if panel._needsExtRebuild then
		panel._needsExtRebuild = false
		if TBR_ExtBar_Rebuild then TBR_ExtBar_Rebuild() end
		if TBR_UI_Rebuild then TBR_UI_Rebuild() end           -- FIX: Also refresh main bar
	end

	UpdateTauntOptionsVisuals(db)
	UpdateThreatOptionsVisuals(db)
	UpdateExtAlertsVisuals(db)

	-- Wipe last-state caches so the next visibility check unconditionally
	-- pushes a fresh UI update to all bars regardless of whether buff state changed.
	if TBR_ResetLastBuffStates then TBR_ResetLastBuffStates() end

	-- Force an immediate visibility check so all bars reflect current buff state
	-- right away rather than waiting for the next UNIT_AURA event. This is what
	-- prevents the post-options desaturation on both the self-buff and external bars.
	if TBR_ForceCheck then TBR_ForceCheck() end
end


-------------------------------------------------------------------------------
-- TAB 1 — BUFFS  (scrollable)
-------------------------------------------------------------------------------
local buffsPage      = tabPages[1]
local sectionHeaders = {}
local sectionMeta    = {}

-- Scroll frame so all external buff checkboxes are reachable
local buffsScroll = CreateFrame("ScrollFrame", "TBR_BuffsScrollFrame", buffsPage, "UIPanelScrollFrameTemplate")
buffsScroll:SetPoint("TOPLEFT",     buffsPage, "TOPLEFT",      0,   0)
buffsScroll:SetPoint("BOTTOMRIGHT", buffsPage, "BOTTOMRIGHT", -20,  0)

local buffsChild = CreateFrame("Frame", nil, buffsScroll)
buffsChild:SetWidth(580)
buffsScroll:SetScrollChild(buffsChild)

buffsScroll:EnableMouseWheel(true)
buffsScroll:SetScript("OnMouseWheel", function(self, delta)
    local cur  = self:GetVerticalScroll()
    local maxS = math.max(0, buffsChild:GetHeight() - self:GetHeight())
    self:SetVerticalScroll(math.min(maxS, math.max(0, cur - delta * 24 * 3)))
end)

local CLASS_SECTIONS = {
    { name = "Paladin", keys = { "righteousFury", "devotionAura" } },
    { name = "Druid",   keys = { "thorns", "markOfTheWild", "omenOfClarity" } },
    { name = "Warrior", keys = { "battleShout", "commandingShout", "defensiveStance" } },
}

local function BuffName(key)
    for _, b in ipairs(cfg.buffs) do
        if b.key == key then return L[b.name] or b.name end
    end
    return key
end

panel.priorityRows = {}

local function RefreshSectionLayout(sectionName)
    local meta = sectionMeta[sectionName]
    local rows = panel.priorityRows[sectionName]
    if not rows or not meta then return end
    local y = meta.startY
    for i, row in ipairs(rows) do
        row.frame:ClearAllPoints()
        row.frame:SetPoint("TOPLEFT", buffsChild, "TOPLEFT", meta.xBase, y)
        row.upBtn:Hide(); row.downBtn:Hide()
        if i == 1 then row.downBtn:Show(); row.downBtn:SetPoint("LEFT", row.frame, "LEFT", 0, 0)
        else row.upBtn:Show(); row.upBtn:SetPoint("LEFT", row.frame, "LEFT", 0, 0) end
        y = y - 26
    end
end

local function CommitSortOrder(sectionName, rows)
    if not TankBuffReminderCharDB then TankBuffReminderCharDB = {} end
    if not TankBuffReminderCharDB.buffOrder then TankBuffReminderCharDB.buffOrder = {} end
    local dest = TankBuffReminderCharDB.buffOrder[sectionName]
    if not dest then dest = {}; TankBuffReminderCharDB.buffOrder[sectionName] = dest end
    table.wipe(dest)
    for _, r in ipairs(rows) do table.insert(dest, r.key) end
    panel._needsRebuild = true
end

local function MakePriorityRows(sectionName, orderedKeys, xBase, startY)
    local rows = {}
    panel.priorityRows[sectionName] = rows
    sectionMeta[sectionName] = { startY = startY, xBase = xBase }
    for _, key in ipairs(orderedKeys) do
        local rowFrame = CreateFrame("Frame", nil, buffsChild); rowFrame:SetSize(210, 24)
        local upBtn   = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate"); upBtn:SetSize(20,20); upBtn:SetText("*")
        local downBtn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate"); downBtn:SetSize(20,20); downBtn:SetText("*")
        local cb = CreateFrame("CheckButton", nil, rowFrame, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("LEFT", rowFrame, "LEFT", 24, 0); cb.Text:SetText(BuffName(key))
        cb:SetScript("OnClick", function() panel._needsRebuild = true; SyncSettings() end)
        panel.checkboxes[key] = cb
        local row = { frame=rowFrame, key=key, cb=cb, upBtn=upBtn, downBtn=downBtn }
        table.insert(rows, row)
        upBtn:SetScript("OnClick", function()
            for i, r in ipairs(rows) do
                if r.key == key and i > 1 then
                    rows[i], rows[i-1] = rows[i-1], rows[i]
                    CommitSortOrder(sectionName, rows); RefreshSectionLayout(sectionName)
                    if TankBuffReminder_RebuildTrackedBuffs then TankBuffReminder_RebuildTrackedBuffs() end
                    break
                end
            end
        end)
        downBtn:SetScript("OnClick", function()
            for i, r in ipairs(rows) do
                if r.key == key and i < #rows then
                    rows[i], rows[i+1] = rows[i+1], rows[i]
                    CommitSortOrder(sectionName, rows); RefreshSectionLayout(sectionName)
                    if TankBuffReminder_RebuildTrackedBuffs then TankBuffReminder_RebuildTrackedBuffs() end
                    break
                end
            end
        end)
    end
    RefreshSectionLayout(sectionName)
    return startY - (#orderedKeys * 26) - 16
end

local function GetOrderedKeys(sectionName, defaultKeys)
    local saved = TankBuffReminderCharDB
                  and TankBuffReminderCharDB.buffOrder
                  and TankBuffReminderCharDB.buffOrder[sectionName]
    if saved and #saved == #defaultKeys then return saved end
    return defaultKeys
end

local colX  = { 10, 220, 430 }
local colY0 = -10
for ci, section in ipairs(CLASS_SECTIONS) do
    local x   = colX[ci]
    local hdr = buffsChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    hdr:SetPoint("TOPLEFT", x+24, colY0)
    hdr:SetText(L[section.name] or section.name); hdr:SetTextColor(1, 0.82, 0)
    sectionHeaders[section.name] = hdr
    MakePriorityRows(section.name, GetOrderedKeys(section.name, section.keys), x, colY0-26)
end

local buffsNote = buffsChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
buffsNote:SetPoint("TOPLEFT", 10, -130)
buffsNote:SetTextColor(0.55, 0.55, 0.55)
buffsNote:SetText(L["Only your class section is active.  * sets cast priority (top = first shown)."])

-- ── External Buffs divider + section ────────────────────────────────────────
local extDiv = buffsChild:CreateTexture(nil, "ARTWORK"); extDiv:SetHeight(1)
extDiv:SetPoint("TOPLEFT",  buffsChild, "TOPLEFT",   0,  -150)
extDiv:SetPoint("TOPRIGHT", buffsChild, "TOPRIGHT", -20, -150)
extDiv:SetColorTexture(0.35, 0.30, 0.09, 0.8)

local extHdr = buffsChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
extHdr:SetPoint("TOPLEFT", 10, -168)
extHdr:SetText(L["External Buffs"]); extHdr:SetTextColor(1, 0.82, 0)

panel.extBuffCBs = {}

-- Unlock (drag to move) — sits right above the group visibility checkboxes
panel.extBarUnlockCB = CreateFrame("CheckButton", nil, buffsChild, "InterfaceOptionsCheckButtonTemplate")
panel.extBarUnlockCB:SetPoint("TOPLEFT", 10, -192)
panel.extBarUnlockCB.Text:SetText(L["Unlock External Buff Bar (drag to move)"] or "Unlock External Buff Bar (drag to move)")
panel.extBarUnlockCB:SetScript("OnClick", function()
    TankBuffReminderCharDB.extBarUnlocked = panel.extBarUnlockCB:GetChecked()
    if TBR_ExtBar_Rebuild then TBR_ExtBar_Rebuild() end
end)

-- Show in party / Show in raid — two checkboxes on the same row
panel.extBuffsShowInPartyCB = CreateFrame("CheckButton", nil, buffsChild, "InterfaceOptionsCheckButtonTemplate")
panel.extBuffsShowInPartyCB:SetPoint("TOPLEFT", 10, -216)
panel.extBuffsShowInPartyCB.Text:SetText(L["Show in party (5-man)"] or "Show in party (5-man)")
panel.extBuffsShowInPartyCB:SetScript("OnClick", function()
    TankBuffReminderCharDB.extBuffsShowInParty = panel.extBuffsShowInPartyCB:GetChecked()
    if TBR_ExtBar_Rebuild then TBR_ExtBar_Rebuild() end
end)

panel.extBuffsShowInRaidCB = CreateFrame("CheckButton", nil, buffsChild, "InterfaceOptionsCheckButtonTemplate")
panel.extBuffsShowInRaidCB:SetPoint("TOPLEFT", 220, -216)
panel.extBuffsShowInRaidCB.Text:SetText(L["Show in raid"] or "Show in raid")
panel.extBuffsShowInRaidCB:SetScript("OnClick", function()
    TankBuffReminderCharDB.extBuffsShowInRaid = panel.extBuffsShowInRaidCB:GetChecked()
    if TBR_ExtBar_Rebuild then TBR_ExtBar_Rebuild() end
end)

-- Smart Detection
panel.extSmartDetectCB = CreateFrame("CheckButton", nil, buffsChild, "InterfaceOptionsCheckButtonTemplate")
panel.extSmartDetectCB:SetPoint("TOPLEFT", 10, -240)
panel.extSmartDetectCB.Text:SetText(L["Smart Detection (only show buffs for classes in your group)"] or "Smart Detection (only show buffs for classes in your group)")
panel.extSmartDetectCB:SetScript("OnClick", function()
    TankBuffReminderCharDB.extSmartDetect = panel.extSmartDetectCB:GetChecked()
    if TBR_ExtBar_Rebuild then TBR_ExtBar_Rebuild() end
end)

local EXT_CLASS_SECTIONS = {
    { class="PRIEST",  label="Priest",  color={1,    1,    1   } },
    { class="MAGE",    label="Mage",    color={0.25, 0.78, 0.92} },
    { class="DRUID",   label="Druid",   color={1,    0.49, 0.04} },
    { class="PALADIN", label="Paladin", color={0.96, 0.55, 0.73} },
    { class="SHAMAN",  label="Shaman",  color={0.0,  0.44, 0.87} },
}
local EXT_COL_W = 210
local EXT_COLS  = 2
local EXT_ROW_H = 24
local extCurY   = -272   -- shifted down to clear the three option rows above

for _, sec in ipairs(EXT_CLASS_SECTIONS) do
    local entries = {}
    if TankBuffReminderExternalBuffs then
        for _, e in ipairs(TankBuffReminderExternalBuffs) do
            if e.sourceClass == sec.class then table.insert(entries, e) end
        end
    end
    if #entries > 0 then
        local hdr = buffsChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        hdr:SetPoint("TOPLEFT", buffsChild, "TOPLEFT", 10, extCurY)
        hdr:SetTextColor(sec.color[1], sec.color[2], sec.color[3])
        hdr:SetText(L[sec.label] or sec.label)
        extCurY = extCurY - EXT_ROW_H

        local colIdx = 0
        for _, entry in ipairs(entries) do
            local xPos = 10 + (colIdx % EXT_COLS) * EXT_COL_W
            local cb   = CreateFrame("CheckButton", nil, buffsChild, "InterfaceOptionsCheckButtonTemplate")
            cb:SetPoint("TOPLEFT", buffsChild, "TOPLEFT", xPos, extCurY)
            cb.Text:SetText(L[entry.name] or entry.name)
            cb.extKey = entry.key
            local capE, capS = entry, sec
			cb:SetScript("OnClick", function()
				TankBuffReminderCharDB["ext_"..capE.key] = cb:GetChecked()
				panel._needsExtRebuild = true
				SyncSettings()
			end)
            cb:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if capE.spellID then GameTooltip:SetSpellByID(capE.spellID)
                else GameTooltip:SetText(L[capE.name] or capE.name, 1,1,1) end
                GameTooltip:AddLine("|cff999999"..(L["Source"] or "Source")..": "..(L[capS.label] or capS.label).."|r", 1,1,1,true)
                GameTooltip:Show()
            end)
            cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
            panel.extBuffCBs[entry.key] = cb
            colIdx = colIdx + 1
            if colIdx % EXT_COLS == 0 then extCurY = extCurY - EXT_ROW_H end
        end
        if colIdx % EXT_COLS ~= 0 then extCurY = extCurY - EXT_ROW_H end
        extCurY = extCurY - 8
    end
end

buffsChild:SetHeight(math.abs(extCurY) + 40)


-------------------------------------------------------------------------------
-- TAB 2 — APPEARANCE
-------------------------------------------------------------------------------
local appPage = tabPages[2]
local appScroll = CreateFrame("ScrollFrame", "TBR_AppScrollFrame", appPage, "UIPanelScrollFrameTemplate")
appScroll:SetPoint("TOPLEFT", 8, -10); appScroll:SetPoint("BOTTOMRIGHT", -30, 10)
local appChild = CreateFrame("Frame", nil, appScroll)
appChild:SetSize(460, 1700); appScroll:SetScrollChild(appChild)

local function AppHeader(text, y)
    local h = appChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    h:SetPoint("TOPLEFT", 10, y); h:SetText(text); h:SetTextColor(1, 0.82, 0); return h
end
local function AppDiv(y)
    local t = appChild:CreateTexture(nil, "ARTWORK"); t:SetSize(460, 1)
    t:SetColorTexture(1, 1, 1, 0.15); t:SetPoint("TOPLEFT", 10, y); return t
end

local col1, col2 = 10, 260

-- ── SECTION 1: MAIN BAR ─────────────────────────────────────────────────────
AppHeader(L["Main Bar Appearance"], -10)

panel.glowSlider      = CreateFloatSlider(appChild, L["Glow Size"],          1.0, 3.0,  col1, -56,  "TBR_GlowSlider")
panel.pulseSlider     = CreateFloatSlider(appChild, L["Pulse Speed"],        0,   10,   col1, -116, "TBR_PulseSlider")
panel.alphaSlider     = CreateFloatSlider(appChild, L["Frame Alpha"],        0.001,1.0, col1, -176, "TBR_AlphaSlider")
panel.buffAlphaSlider = CreateFloatSlider(appChild, L["Icon Alpha"],         0.01, 1.0, col1, -236, "TBR_BuffAlphaSlider")
panel.paddingSlider   = CreateFloatSlider(appChild, L["Button Spacing"],     0,   20,   col1, -296, "TBR_PaddingSlider")
panel.glowColorBtn    = CreateColorButton(appChild, L["Glow Color"],         col1+4, -364, "glowColor", cfg.defaults.glowColor,
    function() if TankBuffReminder_UpdateGlow then TankBuffReminder_UpdateGlow() end end, false)

panel.buffBarScaleSlider  = CreateFloatSlider(appChild, L["Bar Scale"],         0.5, 3.0, col2, -56,  "TBR_BuffBarScaleSlider")
panel.sweepAlphaSlider    = CreateFloatSlider(appChild, L["Buff Sweep Alpha"],  0.0, 1.0, col2, -116, "TBR_SweepAlphaSlider")
panel.timerAlphaSlider    = CreateFloatSlider(appChild, L["Timer Text Alpha"],  0.0, 1.0, col2, -176, "TBR_TimerAlphaSlider")
panel.timerOffsetSlider   = CreateIntSlider  (appChild, L["Text Vertical Offset"],-32,32, col2, -236, "TBR_TimerOffsetSlider")
panel.timerFontSizeSlider = CreateIntSlider  (appChild, L["Font Size"],          6,  32,  col2, -296, "TBR_TimerFontSizeSlider")
panel.timerColorBtn       = CreateColorButton(appChild, L["Duration Text Color"], col2+4,-356, "timerTextColor", cfg.defaults.timerTextColor,
    function() if TBR_UI_UpdateTimerStyle then TBR_UI_UpdateTimerStyle() end end, false)

-- live update scripts
panel.buffBarScaleSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName().."Text"]:SetText(string.format(L["Bar Scale"]..": %.2f", v))
    if TankBuffReminderDB and TBR_UI_SetScale then TBR_UI_SetScale(v) end
end)
panel.alphaSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName().."Text"]:SetText(string.format(L["Frame Alpha"]..": %.2f", v))
    if TankBuffReminderCharDB then TankBuffReminderCharDB.frameAlpha=v; if TBR_UI_UpdateAlpha then TBR_UI_UpdateAlpha() end end
end)
panel.buffAlphaSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName().."Text"]:SetText(string.format(L["Icon Alpha"]..": %.2f", v))
    if TankBuffReminderCharDB then TankBuffReminderCharDB.buffAlpha=v; if TBR_UI_UpdateAlpha then TBR_UI_UpdateAlpha() end end
end)
panel.sweepAlphaSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName().."Text"]:SetText(string.format(L["Buff Sweep Alpha"]..": %.2f", v))
    if TankBuffReminderCharDB then TankBuffReminderCharDB.sweepAlpha=v; if TBR_UI_UpdateTimerStyle then TBR_UI_UpdateTimerStyle() end end
end)
panel.timerAlphaSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName().."Text"]:SetText(string.format(L["Timer Text Alpha"]..": %.2f", v))
    if TankBuffReminderCharDB then TankBuffReminderCharDB.timerAlpha=v; if TBR_UI_UpdateTimerStyle then TBR_UI_UpdateTimerStyle() end end
end)
panel.timerOffsetSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName().."Text"]:SetText(string.format(L["Text Vertical Offset"]..": %d", v))
    if TankBuffReminderCharDB then TankBuffReminderCharDB.timerTextOffsetY=v; if TBR_UI_UpdateTimerStyle then TBR_UI_UpdateTimerStyle() end end
end)
panel.timerFontSizeSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName().."Text"]:SetText(string.format(L["Font Size"]..": %d", v))
    if TankBuffReminderCharDB then TankBuffReminderCharDB.timerFontSize=v; if TBR_UI_UpdateTimerStyle then TBR_UI_UpdateTimerStyle() end end
end)
for _, s in ipairs({ panel.buffBarScaleSlider, panel.glowSlider, panel.pulseSlider, panel.alphaSlider, panel.buffAlphaSlider,
                     panel.sweepAlphaSlider, panel.timerAlphaSlider, panel.timerOffsetSlider, panel.timerFontSizeSlider }) do
    s:SetScript("OnMouseUp", SyncSettings)
end
panel.paddingSlider:SetScript("OnMouseUp", function() panel._needsRebuild=true; SyncSettings() end)

-- ── SECTION 2: CONSUMABLE BAR ───────────────────────────────────────────────
AppDiv(-420); AppHeader(L["Consumable Bar Appearance"], -440)

panel.consFrameAlphaSlider  = CreateFloatSlider(appChild, L["Frame & Border Alpha"], 0.0,1.0,   col1, -486, "TBR_ConsFrameAlphaSlider")
panel.consScaleSlider       = CreateFloatSlider(appChild, L["Bar Scale"],            0.5,2.0,   col1, -546, "TBR_ConsScaleSlider")
panel.consAlphaSlider       = CreateFloatSlider(appChild, L["Icon Alpha (Active)"],  0.0,1.0,   col1, -606, "TBR_ConsAlphaSlider")
panel.consGlowAlphaSlider   = CreateFloatSlider(appChild, L["Glow Alpha"],           0.0,1.0,   col1, -666, "TBR_ConsGlowAlphaSlider")
panel.consSweepAlphaSlider  = CreateFloatSlider(appChild, L["Sweep Alpha"],          0.0,1.0,   col1, -726, "TBR_ConsSweepAlphaSlider")

do  -- Cons glow colour
    local btn=CreateFrame("Button",nil,appChild); btn:SetSize(18,18); btn:SetPoint("TOPLEFT",col1+4,-786)
    local sw=btn:CreateTexture(nil,"BACKGROUND"); sw:SetAllPoints(); sw:SetColorTexture(1,1,1,1); btn.swatch=sw
    local l=btn:CreateFontString(nil,"ARTWORK","GameFontHighlight"); l:SetPoint("LEFT",btn,"RIGHT",8,0); l:SetText(L["Cons Glow Color"])
    btn:SetScript("OnClick",function()
        local db=TankBuffReminderDB; if not db then return end
        if not db.consGlowColor then db.consGlowColor={r=0,g=1,b=0,a=1} end
        local c=db.consGlowColor
        ColorPickerFrame:SetupColorPickerAndShow({ swatchFunc=function() local r,g,b=ColorPickerFrame:GetColorRGB(); local a=ColorPickerFrame:GetColorAlpha(); c.r,c.g,c.b,c.a=r,g,b,a; sw:SetVertexColor(r,g,b); if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end end, r=c.r,g=c.g,b=c.b,opacity=c.a or 1,hasOpacity=true, cancelFunc=function(prev) c.r,c.g,c.b,c.a=prev.r,prev.g,prev.b,prev.opacity; sw:SetVertexColor(c.r,c.g,c.b); if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end end })
    end)
    function btn:Refresh() local db=TankBuffReminderDB; local c=(db and db.consGlowColor)or{r=0,g=1,b=0}; sw:SetVertexColor(c.r,c.g,c.b) end
    panel.consGlowColorBtn=btn
end

panel.consPaddingSlider       = CreateIntSlider  (appChild,L["Button Spacing"], 0,20,   col2,-486,"TBR_ConsPaddingSlider")
panel.consTimerFontSizeSlider = CreateIntSlider  (appChild,L["Timer Font Size"],8,30,   col2,-546,"TBR_ConsFontSizeSlider")
panel.consTimerOffsetSlider   = CreateIntSlider  (appChild,L["Timer Y Offset"],-30,30,  col2,-606,"TBR_ConsOffsetSlider")
panel.consTimerAlphaSlider    = CreateFloatSlider(appChild,L["Timer Alpha"],   0.0,1.0, col2,-666,"TBR_ConsTimerAlphaSlider")
panel.consPulseSlider         = CreateFloatSlider(appChild,L["Pulse Speed"],   0.0,8.0, col2,-726,"TBR_ConsPulseSlider")
panel.consPulseSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Pulse Speed"]..": %.2f",v)); TankBuffReminderDB.consPulseSpeed=v end)

do  -- Cons text colour
    local btn=CreateFrame("Button",nil,appChild); btn:SetSize(18,18); btn:SetPoint("TOPLEFT",col2+4,-786)
    local sw=btn:CreateTexture(nil,"BACKGROUND"); sw:SetAllPoints(); sw:SetColorTexture(1,1,1,1); btn.swatch=sw
    local l=btn:CreateFontString(nil,"OVERLAY","GameFontHighlight"); l:SetPoint("LEFT",btn,"RIGHT",8,0); l:SetText(L["Text Color"])
    btn:SetScript("OnClick",function()
        local db=TankBuffReminderDB; if not db then return end
        if not db.consTextColor then db.consTextColor={r=1,g=1,b=1} end
        local c=db.consTextColor
        ColorPickerFrame:SetupColorPickerAndShow({ swatchFunc=function() local r,g,b=ColorPickerFrame:GetColorRGB(); c.r,c.g,c.b=r,g,b; sw:SetVertexColor(r,g,b); if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end end, r=c.r,g=c.g,b=c.b,hasOpacity=false, cancelFunc=function(prev) c.r,c.g,c.b=prev.r,prev.g,prev.b; sw:SetVertexColor(c.r,c.g,c.b); if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end end })
    end)
    function btn:Refresh() local db=TankBuffReminderDB; local c=(db and db.consTextColor)or{r=1,g=1,b=1}; sw:SetVertexColor(c.r,c.g,c.b) end
    panel.consTextColorBtn=btn
end

panel.consMouseoverCB=CreateCheckbox(appChild,L["Hide until Mouseover"]); panel.consMouseoverCB:SetPoint("TOPLEFT",col2,-846)
panel.consMouseoverCB:SetScript("OnClick",function() if not TankBuffReminderDB then TankBuffReminderDB={} end; TankBuffReminderDB.consMouseover=panel.consMouseoverCB:GetChecked(); if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end; SyncSettings() end)
panel.consHideEmptyCB=CreateCheckbox(appChild,L["Hide Empty Buttons"]); panel.consHideEmptyCB:SetPoint("TOPLEFT",col2,-872)
panel.consHideEmptyCB:SetScript("OnClick",function() if not TankBuffReminderDB then TankBuffReminderDB={} end; TankBuffReminderDB.consHideEmpty=panel.consHideEmptyCB:GetChecked(); panel._needsConsRebuild=true; SyncSettings() end)

do  -- Orientation radio
    local lbl=appChild:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); lbl:SetPoint("TOPLEFT",col1,-838); lbl:SetText(L["Bar Orientation"])
    local rbH=CreateFrame("CheckButton","TBR_ConsOrientHorizRB",appChild,"UIRadioButtonTemplate"); rbH:SetPoint("TOPLEFT",col1,-855); rbH.text:SetText(L["Horizontal"]); panel.consOrientHorizRB=rbH
    local rbV=CreateFrame("CheckButton","TBR_ConsOrientVertRB", appChild,"UIRadioButtonTemplate"); rbV:SetPoint("LEFT",rbH,"RIGHT",60,0); rbV.text:SetText(L["Vertical"]); panel.consOrientVertRB=rbV
    rbH:SetScript("OnClick",function() rbH:SetChecked(true); rbV:SetChecked(false); if TankBuffReminderDB then TankBuffReminderDB.consOrientation="horizontal" end; panel._needsConsRebuild=true; SyncSettings() end)
    rbV:SetScript("OnClick",function() rbV:SetChecked(true); rbH:SetChecked(false); if TankBuffReminderDB then TankBuffReminderDB.consOrientation="vertical" end; panel._needsConsRebuild=true; SyncSettings() end)
end

panel.consScaleSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Bar Scale"]..": %.2f",v)); TankBuffReminderDB.consScale=v; panel._needsConsRebuild=true end)
panel.consPaddingSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Button Spacing"]..": %d",v)); TankBuffReminderDB.consPadding=v; panel._needsConsRebuild=true end)
panel.consAlphaSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Icon Alpha (Active)"]..": %.2f",v)); TankBuffReminderDB.consAlpha=v; if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end end)
panel.consGlowAlphaSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Glow Alpha"]..": %.2f",v)); TankBuffReminderDB.consGlowAlpha=v; if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end end)
panel.consSweepAlphaSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Sweep Alpha"]..": %.2f",v)); TankBuffReminderDB.consSweepAlpha=v; if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end end)
panel.consTimerFontSizeSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Timer Font Size"]..": %d",v)); TankBuffReminderDB.consTimerFontSize=v; if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end end)
panel.consTimerOffsetSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Timer Y Offset"]..": %d",v)); TankBuffReminderDB.consTimerOffsetY=v; if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end end)
panel.consTimerAlphaSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Timer Alpha"]..": %.2f",v)); TankBuffReminderDB.consTimerAlpha=v; if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end end)
panel.consFrameAlphaSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Frame Alpha"]..": %.2f",v)); TankBuffReminderDB.consFrameAlpha=v; if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end end)
for _, s in ipairs({ panel.consFrameAlphaSlider,panel.consScaleSlider,panel.consAlphaSlider,panel.consGlowAlphaSlider,panel.consPaddingSlider,panel.consSweepAlphaSlider,panel.consTimerFontSizeSlider,panel.consTimerOffsetSlider,panel.consTimerAlphaSlider,panel.consPulseSlider }) do s:SetScript("OnMouseUp",SyncSettings) end

-- ── SECTION 3: EXTERNAL BUFF BAR ────────────────────────────────────────────
AppDiv(-910); AppHeader(L["External Buff Bar Appearance"], -930)

panel.extBarScaleSlider    = CreateFloatSlider(appChild,L["Bar Scale"],          0.5,3.0,  col1,-976, "TBR_ExtBarScaleSlider")
panel.extGlowSlider        = CreateFloatSlider(appChild,L["Glow Size"],          1.0,3.0,  col1,-1036,"TBR_ExtGlowSlider")
panel.extPulseSlider       = CreateFloatSlider(appChild,L["Pulse Speed"],        0,10,     col1,-1096,"TBR_ExtPulseSlider")
panel.extFrameAlphaSlider  = CreateFloatSlider(appChild,L["Frame Alpha"],        0.001,1.0,col1,-1156,"TBR_ExtFrameAlphaSlider")
panel.extBuffAlphaSlider   = CreateFloatSlider(appChild,L["Icon Alpha"],         0.01,1.0, col1,-1216,"TBR_ExtBuffAlphaSlider")
panel.extPaddingSlider     = CreateFloatSlider(appChild,L["Button Spacing"],     0,20,     col1,-1276,"TBR_ExtPaddingSlider")
panel.extGlowColorBtn      = CreateColorButton(appChild,L["Glow Color"],         col1+4,-1336,"extGlowColor",cfg.defaults.glowColor,
    function() if TBR_ExtBar_UpdateGlow then TBR_ExtBar_UpdateGlow() end end, true)

panel.extSweepAlphaSlider    = CreateFloatSlider(appChild,L["Buff Sweep Alpha"],  0.0,1.0, col2,-976, "TBR_ExtSweepAlphaSlider")
panel.extTimerAlphaSlider    = CreateFloatSlider(appChild,L["Timer Text Alpha"],  0.0,1.0, col2,-1036,"TBR_ExtTimerAlphaSlider")
panel.extTimerOffsetSlider   = CreateIntSlider  (appChild,L["Text Vertical Offset"],-32,32,col2,-1096,"TBR_ExtTimerOffsetSlider")
panel.extTimerFontSizeSlider = CreateIntSlider  (appChild,L["Font Size"],          6,32,   col2,-1156,"TBR_ExtTimerFontSizeSlider")
panel.extTimerColorBtn       = CreateColorButton(appChild,L["Duration Text Color"],col2+4,-1216,"extTimerTextColor",cfg.defaults.timerTextColor,
    function() if TBR_ExtBar_UpdateTimerStyle then TBR_ExtBar_UpdateTimerStyle() end end, false)

-- live updates for ext bar
panel.extBarScaleSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Bar Scale"]..": %.2f",v)); TankBuffReminderDB.extBarScale=v; panel._needsExtRebuild=true end)
panel.extPaddingSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Button Spacing"]..": %.0f",v)); TankBuffReminderDB.extBarButtonPadding=v; panel._needsExtRebuild=true end)
panel.extFrameAlphaSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Frame Alpha"]..": %.2f",v)); if TankBuffReminderCharDB then TankBuffReminderCharDB.extFrameAlpha=v; if TBR_ExtBar_UpdateAlpha then TBR_ExtBar_UpdateAlpha() end end end)
panel.extBuffAlphaSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Icon Alpha"]..": %.2f",v)); if TankBuffReminderCharDB then TankBuffReminderCharDB.extBuffAlpha=v; if TBR_ExtBar_UpdateAlpha then TBR_ExtBar_UpdateAlpha() end end end)
panel.extSweepAlphaSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Buff Sweep Alpha"]..": %.2f",v)); if TankBuffReminderCharDB then TankBuffReminderCharDB.extSweepAlpha=v; if TBR_ExtBar_UpdateTimerStyle then TBR_ExtBar_UpdateTimerStyle() end end end)
panel.extTimerAlphaSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Timer Text Alpha"]..": %.2f",v)); if TankBuffReminderCharDB then TankBuffReminderCharDB.extTimerAlpha=v; if TBR_ExtBar_UpdateTimerStyle then TBR_ExtBar_UpdateTimerStyle() end end end)
panel.extTimerOffsetSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Text Vertical Offset"]..": %d",v)); if TankBuffReminderCharDB then TankBuffReminderCharDB.extTimerTextOffsetY=v; if TBR_ExtBar_UpdateTimerStyle then TBR_ExtBar_UpdateTimerStyle() end end end)
panel.extTimerFontSizeSlider:SetScript("OnValueChanged",function(self,v) _G[self:GetName().."Text"]:SetText(string.format(L["Font Size"]..": %d",v)); if TankBuffReminderCharDB then TankBuffReminderCharDB.extTimerFontSize=v; if TBR_ExtBar_UpdateTimerStyle then TBR_ExtBar_UpdateTimerStyle() end end end)
for _,s in ipairs({panel.extBarScaleSlider,panel.extGlowSlider,panel.extPulseSlider,panel.extFrameAlphaSlider,panel.extBuffAlphaSlider,panel.extPaddingSlider,panel.extSweepAlphaSlider,panel.extTimerAlphaSlider,panel.extTimerOffsetSlider,panel.extTimerFontSizeSlider}) do s:SetScript("OnMouseUp",SyncSettings) end

-- ── SECTION 4: DEFENSE CAP ──────────────────────────────────────────────────
AppDiv(-1380); AppHeader(L["Defense Cap Reference"], -1400)

panel.defCapColorBtn = CreateColorButton(appChild,L["Chart Frame Color"],col1+4,-1446,"defCapColor",{r=0.6,g=0.5,b=0.2,a=1},function() if TBR_DefenseCap_UpdateColor then TBR_DefenseCap_UpdateColor() end end, false)
panel.defCapFontSizeSlider = CreateFloatSlider(appChild,L["Chart Font Size"],7,18,col1,-1486,"TBR_DefCapFontSizeSlider")
panel.defCapFontSizeSlider:SetScript("OnValueChanged",function(self,v) local val=math.floor(v+0.5); local t=_G[self:GetName().."Text"]; if t then t:SetText(string.format("%s: %d",L["Chart Font Size"],val)) end; if TankBuffReminderCharDB then TankBuffReminderCharDB.defCapFontSize=val end; if TBR_DefenseCap_ForceRepopulate then TBR_DefenseCap_ForceRepopulate() end end)
panel.defCapScaleSlider = CreateFloatSlider(appChild,L["Chart Scale"],0.5,2.0,col2,-1486,"TBR_DefCapScaleSlider")
panel.defCapScaleSlider:SetScript("OnValueChanged",function(self,v) local val=math.floor(v*100+0.5)/100; local t=_G[self:GetName().."Text"]; if t then t:SetText(string.format("%s: %.2f",L["Chart Scale"],val)) end; if TankBuffReminderCharDB then TankBuffReminderCharDB.defCapScale=val end; if TBR_DefenseCap_ApplyScale then TBR_DefenseCap_ApplyScale() end end)
panel.defCapBtnShowCB = CreateCheckbox(appChild,L["Show Defense Cap button on Character Sheet"],col1,-1536); panel.defCapBtnShowCB:SetScript("OnClick",SyncSettings)
local defBtn=CreateFrame("Button",nil,appChild,"UIPanelButtonTemplate"); defBtn:SetSize(180,24); defBtn:SetPoint("TOPLEFT",col2,-1538); defBtn:SetText(L["Open Defense Cap Chart"]); defBtn:SetScript("OnClick",function() if TBR_DefenseCap_Toggle then TBR_DefenseCap_Toggle() end end)
for _,s in ipairs({panel.defCapFontSizeSlider,panel.defCapScaleSlider}) do s:SetScript("OnMouseUp",SyncSettings) end

-- ── SECTION 5: MINIMAP ──────────────────────────────────────────────────────
AppDiv(-1590); AppHeader(L["Minimap Button Settings"], -1610)

panel.mapBtnShowCB = CreateCheckbox(appChild,L["Show Minimap Button"],col1,-1650)
panel.mapBtnShowCB:SetScript("OnClick",function(self) SyncSettings(); if TBR_MinimapButton then if TankBuffReminderCharDB.showMinimapButton~=false then TBR_MinimapButton:Show() else TBR_MinimapButton:Hide() end end end)

panel.mapAngleSlider = CreateFloatSlider(appChild,L["Minimap Angle"],0,360,col1,-1700,"TBR_MinimapAngleSlider")
panel.mapAngleSlider:SetValueStep(1); panel.mapAngleSlider:SetObeyStepOnDrag(true)
panel.mapAngleSlider:SetScript("OnValueChanged",function(self,v) local val=math.floor(v+0.5); local t=_G[self:GetName().."Text"]; if t then t:SetText(string.format("%s: %d°",L["Minimap Angle"],val)) end; if TankBuffReminderCharDB then TankBuffReminderCharDB.minimapAngle=val end; if TBR_MinimapButton and TBR_MinimapButton.UpdatePositionFromOffsets then TBR_MinimapButton:UpdatePositionFromOffsets() end end)
panel.mapRadiusSlider = CreateFloatSlider(appChild,L["Minimap Distance"],-50,100,col2,-1700,"TBR_MinimapRadiusSlider")
panel.mapRadiusSlider:SetValueStep(1); panel.mapRadiusSlider:SetObeyStepOnDrag(true)
panel.mapRadiusSlider:SetScript("OnValueChanged",function(self,v) local val=math.floor(v+0.5); local t=_G[self:GetName().."Text"]; if t then t:SetText(string.format("%s: %d",L["Minimap Distance"],val)) end; if TankBuffReminderCharDB then TankBuffReminderCharDB.minimapRadiusOffset=val end; if TBR_MinimapButton and TBR_MinimapButton.UpdatePositionFromOffsets then TBR_MinimapButton:UpdatePositionFromOffsets() end end)

appChild:SetHeight(1800)


-------------------------------------------------------------------------------
-- TAB 3 — ALERTS
-------------------------------------------------------------------------------
local alertPage = tabPages[3]

local alertScroll = CreateFrame("ScrollFrame", "TBR_AlertScrollFrame", alertPage, "UIPanelScrollFrameTemplate")
alertScroll:SetPoint("TOPLEFT", 8, -4)
alertScroll:SetPoint("BOTTOMRIGHT", -26, 4)

local alertChild = CreateFrame("Frame", nil, alertScroll)
alertChild:SetSize(460, 700) -- Total height of the scrollable content
alertScroll:SetScrollChild(alertChild)

local alX1, alX2 = 10, 280

MakeHeader(alertChild,L["Buff Alert Sound"],alX1,-10); MakeDivider(alertChild,-28)
panel.soundCB=CreateCheckbox(alertChild,L["Play sound when a buff is missing"],alX1,-42); panel.soundCB:SetScript("OnClick",SyncSettings)
local sLbl=alertChild:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); sLbl:SetPoint("TOPLEFT",alX1+28,-70); sLbl:SetText(L["Missing Buff Sound:"])
panel.soundDropdown=CreateSoundDropdown(alertChild,"TankBuffReminderSoundDropdown",alX1+10,-85); panel.soundDropdown.dbKey="soundID"
MakeHeader(alertChild,L["Removal Alerts"],alX1,-135)
panel.removeSoundCB=CreateCheckbox(alertChild,L["Enable removal alert sound (Salv/BoP)"],alX1,-160); panel.removeSoundCB:SetScript("OnClick",SyncSettings)
local rLbl=alertChild:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); rLbl:SetPoint("TOPLEFT",alX1+28,-185); rLbl:SetText(L["Removal Alert Sound:"])
panel.removeSoundDropdown=CreateSoundDropdown(alertChild,"TBR_RemoveSoundDropdown",alX1+10,-200); panel.removeSoundDropdown.dbKey="removeSoundID"

MakeHeader(alertChild,L["Taunt Alert System"],alX2,-10); MakeDivider(alertChild,-28)
panel.tauntEnabledCB=CreateCheckbox(alertChild,L["Enable Taunt Failure Detection"],alX2,-42)
panel.tauntWarningCB=CreateCheckbox(alertChild,L["Self Warning (chat message)"],alX2,-67)
panel.tauntSayCB=CreateCheckbox(alertChild,L["Announce in /Say"],alX2,-92)
panel.tauntYellCB=CreateCheckbox(alertChild,L["Announce in /Yell"],alX2,-117)
panel.tauntPartyCB=CreateCheckbox(alertChild,L["Announce in /Party"],alX2,-142)
panel.tauntRaidCB=CreateCheckbox(alertChild,L["Announce in /Raid"],alX2,-167)
for _,cb in ipairs({panel.tauntEnabledCB,panel.tauntWarningCB,panel.tauntSayCB,panel.tauntYellCB,panel.tauntPartyCB,panel.tauntRaidCB}) do cb:SetScript("OnClick",SyncSettings) end
panel.tauntSoundCB=CreateCheckbox(alertChild,L["Play sound on taunt failure"],alX2,-202); panel.tauntSoundCB:SetScript("OnClick",SyncSettings)
local tSLbl=alertChild:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); tSLbl:SetPoint("TOPLEFT",alX2+28,-230); tSLbl:SetText(L["Taunt Failure Sound:"])
panel.tauntSoundDropdown=CreateSoundDropdown(alertChild,"TankBuffReminderTauntSoundDropdown",alX2+10,-245); panel.tauntSoundDropdown.dbKey="tauntSoundID"

MakeHeader(alertChild,L["Low Threat Alert System"],alX1,-260); MakeDivider(alertChild,-278)
panel.threatEnabledCB=CreateCheckbox(alertChild,L["Enable Low Threat Alert"],alX1,-292)
panel.threatWarningCB=CreateCheckbox(alertChild,L["Self Warning (chat message)"],alX1,-317)
panel.threatSayCB=CreateCheckbox(alertChild,L["Announce in /Say"],alX1,-342)
panel.threatYellCB=CreateCheckbox(alertChild,L["Announce in /Yell"],alX1,-367)
panel.threatPartyCB=CreateCheckbox(alertChild,L["Announce in /Party"],alX1,-392)
panel.threatRaidCB=CreateCheckbox(alertChild,L["Announce in /Raid"],alX1,-417)
for _,cb in ipairs({panel.threatEnabledCB,panel.threatWarningCB,panel.threatSayCB,panel.threatYellCB,panel.threatPartyCB,panel.threatRaidCB}) do cb:SetScript("OnClick",SyncSettings) end
panel.threatMissCB=CreateCheckbox(alertChild,L["Track Spell Misses"],alX2,-292)
panel.threatResistCB=CreateCheckbox(alertChild,L["Track Spell Resists"],alX2,-317)
panel.threatCCCB=CreateCheckbox(alertChild,L["Track CC / Stuns"],alX2,-342)
panel.threatCCFullCombatCB=CreateCheckbox(alertChild,L["CC Alerts last for entire combat"],alX2,-367)
panel.threatSoundCB=CreateCheckbox(alertChild,L["Play sound on threat alert"],alX1,-442)
for _,cb in ipairs({panel.threatMissCB,panel.threatResistCB,panel.threatCCCB,panel.threatCCFullCombatCB,panel.threatSoundCB}) do cb:SetScript("OnClick",SyncSettings) end
panel.threatWindowSlider=CreateFloatSlider(alertChild,L["Alert Window (sec)"],5,25,alX2,-415,"TBR_ThreatWindowSlider")
panel.threatWindowSlider:SetScript("OnValueChanged",function(self,v) local val=math.floor(v+0.5); local t=_G[self:GetName().."Text"]; if t then t:SetText(string.format("%s: %d",L["Alert Window (sec)"],val)) end; if TankBuffReminderCharDB then TankBuffReminderCharDB.threatWindow=val end end)
panel.threatWindowSlider:SetScript("OnMouseUp",SyncSettings)
local tSndLbl=alertChild:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); tSndLbl:SetPoint("TOPLEFT",alX1+28,-475); tSndLbl:SetText(L["Threat Alert Sound:"])
panel.threatSoundDropdown=CreateSoundDropdown(alertChild,"TBR_ThreatSoundDropdown",alX1+10,-490); panel.threatSoundDropdown.dbKey="threatSoundID"

-- ── External Buff Alerts ─────────────────────────────────────────────────────
MakeHeader(alertChild,L["External Buff Alerts"],alX1,-550); MakeDivider(alertChild,-568)

-- Col 1: sound
panel.extSoundCB=CreateCheckbox(alertChild,L["Play sound when an external buff is missing"],alX1,-582)
panel.extSoundCB:SetScript("OnClick",function() TankBuffReminderCharDB.extPlaySound=panel.extSoundCB:GetChecked(); SyncSettings() end)

local extSndLabel=alertChild:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
extSndLabel:SetPoint("TOPLEFT",alX1+28,-610); extSndLabel:SetText(L["Missing Buff Sound:"])
panel.extSoundDropdown=CreateSoundDropdown(alertChild,"TBR_ExtSoundDropdown",alX1+10,-625)
panel.extSoundDropdown.dbKey="extSoundID"

-- Col 2: announce channels
panel.extWarningCB = CreateCheckbox(alertChild,L["Self Warning (chat message)"],alX2,-572)
panel.extSayCB     = CreateCheckbox(alertChild,L["Announce in /Say"],           alX2,-597)
panel.extYellCB    = CreateCheckbox(alertChild,L["Announce in /Yell"],          alX2,-622)
panel.extPartyCB   = CreateCheckbox(alertChild,L["Announce in /Party"],         alX2,-647)
panel.extRaidCB    = CreateCheckbox(alertChild,L["Announce in /Raid"],          alX2,-672)

for _,cb in ipairs({panel.extWarningCB,panel.extSayCB,panel.extYellCB,panel.extPartyCB,panel.extRaidCB}) do
    cb:SetScript("OnClick",SyncSettings)
    cb.Text:SetTextColor(1, 1, 1)   -- force white; InterfaceOptionsCheckButtonTemplate defaults to gold
end

local extChNote=alertChild:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
extChNote:SetPoint("TOPLEFT",alX2,-718); extChNote:SetTextColor(0.55,0.55,0.55)
extChNote:SetText(L["EXT_ANNOUNCE_NOTE"] or "Click any icon on the external buff bar.")
extChNote:SetWidth(200); extChNote:SetJustifyH("LEFT")

-- Expiration warning: alert when a buff has this many seconds left
panel.extWarnSecsSlider = CreateIntSlider(alertChild,L["Expiration Warning (sec)"],0,25,alX1,-682,"TBR_ExtWarnSecsSlider")
panel.extWarnSecsSlider:SetScript("OnValueChanged",function(self,v)
    local val = math.floor(v+0.5)
    local t = _G[self:GetName().."Text"]
    if t then t:SetText(string.format(L["Expiration Warning (sec)"]..": %d", val)) end
    if TankBuffReminderCharDB then TankBuffReminderCharDB.extWarnSeconds = val end
end)
panel.extWarnSecsSlider:SetScript("OnMouseUp", SyncSettings)

local extWarnNote = alertChild:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
extWarnNote:SetPoint("TOPLEFT",alX1+10,-720); extWarnNote:SetTextColor(0.55,0.55,0.55)
extWarnNote:SetText("|cff888888Set to 0 to disable. Icon glows orange when buff is expiring.|r")
extWarnNote:SetWidth(250); extWarnNote:SetJustifyH("LEFT")

-- Set scroll child height to fit all content
alertChild:SetSize(460,800)


-------------------------------------------------------------------------------
-- TAB 4 — AUTOMATION
-------------------------------------------------------------------------------
local autoPage = tabPages[4]
local auX1, auX2 = 10, 360

MakeHeader(autoPage,L["Combat Automation"],auX1,-10); MakeDivider(autoPage,-28)
local autoNote=autoPage:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
autoNote:SetPoint("TOPLEFT",auX1,-48); autoNote:SetWidth(320); autoNote:SetJustifyH("LEFT")
autoNote:SetTextColor(0.65,0.65,0.65); autoNote:SetText(L["AUTOMATION_NOTE"])

local function MakeRemovalRadioRow(parent,label,x,y)
    local lbl=parent:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); lbl:SetPoint("TOPLEFT",x,y); lbl:SetText(label)
    local function MakeRadio(caption,rx,ry)
        local rb=CreateFrame("CheckButton",nil,parent,"UIRadioButtonTemplate"); rb:SetPoint("TOPLEFT",rx,ry)
        rb.Text=rb:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); rb.Text:SetPoint("LEFT",rb,"RIGHT",5,0); rb.Text:SetText(caption); return rb
    end
    local rAuto=MakeRadio(L["Auto-remove"],x,y-18)
    local rIcon=MakeRadio(L["Show icon"],x+115,y-18)
    local rOff =MakeRadio(L["Off"],x+225,y-18)
    local function Sel(chosen) rAuto:SetChecked(chosen==rAuto); rIcon:SetChecked(chosen==rIcon); rOff:SetChecked(chosen==rOff); panel._needsRebuild=true; SyncSettings() end
    rAuto:SetScript("OnClick",function() Sel(rAuto) end); rIcon:SetScript("OnClick",function() Sel(rIcon) end); rOff:SetScript("OnClick",function() Sel(rOff) end)
    return rAuto,rIcon,rOff
end

panel.salvAutoRB,panel.salvIconRB,panel.salvOffRB=MakeRemovalRadioRow(autoPage,L["Blessing of Salvation"],auX1,-138)
panel.bopAutoRB, panel.bopIconRB, panel.bopOffRB =MakeRemovalRadioRow(autoPage,L["Blessing of Protection"],auX1,-188)

local removalY=-225
panel.removalUnlockCB=CreateCheckbox(autoPage,L["Unlock Removal Buttons (drag to move)"],auX1,removalY)
panel.removalUnlockCB:SetScript("OnClick",function(self) TankBuffReminderCharDB.removalUnlocked=self:GetChecked(); if TBR_RemovalUI_Update then TBR_RemovalUI_Update() end end)

local sliderY=removalY-40
panel.removalScaleSlider=CreateFloatSlider(autoPage,L["Removal UI Scale"],0.5,2.0,auX1+6,sliderY,"TBR_RemovalScaleSlider")
panel.removalScaleSlider:SetScript("OnValueChanged",function(self,v) local val=math.floor(v*100+0.5)/100; local t=_G[self:GetName().."Text"]; if t then t:SetText(string.format("%s: %.2f",L["Removal UI Scale"],val)) end; TankBuffReminderDB.removalScale=val; if TBR_RemovalUI_Update then TBR_RemovalUI_Update() end end)
sliderY=sliderY-45
panel.removalSpacingSlider=CreateFloatSlider(autoPage,L["Button Spacing"],0,50,auX1+6,sliderY,"TBR_RemovalSpacingSlider")
panel.removalSpacingSlider:SetScript("OnValueChanged",function(self,v) local val=math.floor(v+0.5); local t=_G[self:GetName().."Text"]; if t then t:SetText(string.format("%s: %d",L["Button Spacing"],val)) end; TankBuffReminderDB.removalSpacing=val; if TBR_RemovalUI_Update then TBR_RemovalUI_Update() end end)

MakeHeader(autoPage,L["Maintenance & Roles"],auX2,-10); MakeDivider(autoPage,-28)
panel.tankRoleCB=CreateCheckbox(autoPage,L["Auto-set Tank Role (5-man groups)"],auX2,-42); panel.tankRoleCB:SetScript("OnClick",SyncSettings)
panel.tankRoleRaidCB=CreateCheckbox(autoPage,L["Auto-set Tank Role (Raids)"],auX2,-67); panel.tankRoleRaidCB:SetScript("OnClick",SyncSettings)
panel.repairCB=CreateCheckbox(autoPage,L["Auto-Repair at Merchant"],auX2,-92); panel.repairCB:SetScript("OnClick",SyncSettings)

local resetBtn=CreateFrame("Button",nil,autoPage,"UIPanelButtonTemplate"); resetBtn:SetSize(160,24)
resetBtn:SetPoint("BOTTOMLEFT",autoPage,"BOTTOMLEFT",auX2,20); resetBtn:SetText(L["Reset All Settings"])
resetBtn:SetScript("OnClick",function() if TankBuffReminderCharDB then table.wipe(TankBuffReminderCharDB) end; if TankBuffReminderDB then table.wipe(TankBuffReminderDB) end; panel.refresh(); ReloadUI() end)
local resetLbl=autoPage:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); resetLbl:SetPoint("BOTTOMLEFT",resetBtn,"TOPLEFT",0,10); resetLbl:SetTextColor(0.8,0.5,0.5); resetLbl:SetText(L["Caution: This wipes all settings!"])

local function UpdateUnlockState()
    local unlocked=TankBuffReminderCharDB and TankBuffReminderCharDB.removalUnlocked
    if panel.removalUnlockCB then panel.removalUnlockCB:SetChecked(unlocked==true) end
end

-------------------------------------------------------------------------------
-- panel.refresh
-------------------------------------------------------------------------------
function panel.refresh()
    if not TankBuffReminderCharDB then TankBuffReminderCharDB={} end
    local charDB=TankBuffReminderCharDB; local globalDB=TankBuffReminderDB or {}
    local _,playerClass=UnitClass("player")

    -- Self-buff checkboxes
    local buffClassMap={}; for _,b in ipairs(cfg.buffs) do buffClassMap[b.key]=b.class end
    for key,cb in pairs(panel.checkboxes) do
        local val=charDB[key]; if val==nil then val=(buffClassMap[key]==playerClass) end; cb:SetChecked(val==true)
    end
    for _,section in ipairs(CLASS_SECTIONS) do
        local isMyClass=(section.name:upper()==playerClass)
        local rows=panel.priorityRows[section.name]
        if rows then
            for _,row in ipairs(rows) do
                if isMyClass then row.cb:Enable(); row.cb.Text:SetAlpha(1.0)
                else row.cb:Disable(); row.cb.Text:SetAlpha(0.4); if charDB[row.cb.key]==nil then row.cb:SetChecked(false) end end
            end
        end
    end

    -- External buff checkboxes
    if panel.extBarUnlockCB       then panel.extBarUnlockCB:SetChecked(charDB.extBarUnlocked==true) end
    if panel.extBuffsShowInPartyCB then panel.extBuffsShowInPartyCB:SetChecked(charDB.extBuffsShowInParty ~= false) end
    if panel.extBuffsShowInRaidCB  then panel.extBuffsShowInRaidCB:SetChecked(charDB.extBuffsShowInRaid  ~= false) end
    if panel.extSmartDetectCB      then panel.extSmartDetectCB:SetChecked(charDB.extSmartDetect          ~= false) end
    if panel.extBuffCBs and TankBuffReminderExternalBuffs then
        for _,entry in ipairs(TankBuffReminderExternalBuffs) do
            local cb=panel.extBuffCBs[entry.key]
            if cb then local val=charDB["ext_"..entry.key]; if val==nil then val=false end; cb:SetChecked(val==true) end
        end
    end

    -- Appearance — main bar
    panel.buffBarScaleSlider:SetValue(globalDB.scale or 1.0)
    panel.glowSlider:SetValue(charDB.glowSize or cfg.defaults.glowSize)
    panel.pulseSlider:SetValue(charDB.pulseSpeed or cfg.defaults.pulseSpeed)
    panel.alphaSlider:SetValue(charDB.frameAlpha or cfg.defaults.frameAlpha)
    panel.buffAlphaSlider:SetValue(charDB.buffAlpha or cfg.defaults.buffAlpha)
    panel.paddingSlider:SetValue(charDB.buttonPadding or 4)
    panel.sweepAlphaSlider:SetValue(charDB.sweepAlpha or 0.6)
    panel.timerOffsetSlider:SetValue(charDB.timerTextOffsetY or 0)
    panel.timerFontSizeSlider:SetValue(charDB.timerFontSize or cfg.defaults.timerFontSize)
    panel.timerAlphaSlider:SetValue(charDB.timerAlpha or 1.0)
    panel.glowColorBtn:Refresh(); panel.timerColorBtn:Refresh()

    -- Appearance — consumable bar
    panel.consFrameAlphaSlider:SetValue(globalDB.consFrameAlpha or 0.3)
    panel.consScaleSlider:SetValue(globalDB.consScale or 1.0)
    panel.consAlphaSlider:SetValue(globalDB.consAlpha or 0.4)
    panel.consPaddingSlider:SetValue(globalDB.consPadding or 4)
    panel.consGlowAlphaSlider:SetValue(globalDB.consGlowAlpha or 1.0)
    panel.consSweepAlphaSlider:SetValue(globalDB.consSweepAlpha or 0.6)
    panel.consTimerFontSizeSlider:SetValue(globalDB.consTimerFontSize or 12)
    panel.consTimerOffsetSlider:SetValue(globalDB.consTimerOffsetY or 0)
    panel.consTimerAlphaSlider:SetValue(globalDB.consTimerAlpha or 1.0)
    panel.consPulseSlider:SetValue(globalDB.consPulseSpeed or 3)
    panel.consMouseoverCB:SetChecked(globalDB.consMouseover or false)
    panel.consHideEmptyCB:SetChecked(globalDB.consHideEmpty==true)
    local isVert=(globalDB.consOrientation=="vertical")
    panel.consOrientHorizRB:SetChecked(not isVert); panel.consOrientVertRB:SetChecked(isVert)
    if panel.consGlowColorBtn and panel.consGlowColorBtn.Refresh then panel.consGlowColorBtn:Refresh() end
    if panel.consTextColorBtn and panel.consTextColorBtn.Refresh then panel.consTextColorBtn:Refresh() end

    -- Appearance — external bar
    panel.extBarScaleSlider:SetValue(globalDB.extBarScale or 1.0)
    panel.extGlowSlider:SetValue(charDB.extGlowSize or 2.0)
    panel.extPulseSlider:SetValue(charDB.extPulseSpeed or 4)
    panel.extFrameAlphaSlider:SetValue(charDB.extFrameAlpha or 1.0)
    panel.extBuffAlphaSlider:SetValue(charDB.extBuffAlpha or 1.0)
    panel.extPaddingSlider:SetValue(globalDB.extBarButtonPadding or 4)
    panel.extSweepAlphaSlider:SetValue(charDB.extSweepAlpha or 0.6)
    panel.extTimerFontSizeSlider:SetValue(charDB.extTimerFontSize or 12)
    panel.extTimerOffsetSlider:SetValue(charDB.extTimerTextOffsetY or 0)
    panel.extTimerAlphaSlider:SetValue(charDB.extTimerAlpha or 1.0)
    if panel.extGlowColorBtn and panel.extGlowColorBtn.Refresh then panel.extGlowColorBtn:Refresh() end
    if panel.extTimerColorBtn and panel.extTimerColorBtn.Refresh then panel.extTimerColorBtn:Refresh() end

    -- Alerts
    panel.soundCB:SetChecked(charDB.playSound~=false)
    SetDropdownLabel(panel.soundDropdown,"soundID",cfg.defaults.soundID)
    panel.removeSoundCB:SetChecked(charDB.removeSoundEnabled~=false)
    SetDropdownLabel(panel.removeSoundDropdown,"removeSoundID",cfg.defaults.removeSoundID)
    panel.tauntEnabledCB:SetChecked(charDB.tauntEnabled~=false)
    panel.tauntWarningCB:SetChecked(charDB.tauntWarning~=false)
    panel.tauntSayCB:SetChecked(charDB.tauntSay==true)
    panel.tauntYellCB:SetChecked(charDB.tauntYell==true)
    panel.tauntPartyCB:SetChecked(charDB.tauntParty==true)
    panel.tauntRaidCB:SetChecked(charDB.tauntRaid==true)
    panel.tauntSoundCB:SetChecked(charDB.tauntSoundEnabled~=false)
    SetDropdownLabel(panel.tauntSoundDropdown,"tauntSoundID",cfg.defaults.tauntSoundID)
    panel.threatEnabledCB:SetChecked(charDB.threatEnabled==true)
    panel.threatWarningCB:SetChecked(charDB.threatWarning==true)
    panel.threatSayCB:SetChecked(charDB.threatSay==true)
    panel.threatYellCB:SetChecked(charDB.threatYell==true)
    panel.threatPartyCB:SetChecked(charDB.threatParty==true)
    panel.threatRaidCB:SetChecked(charDB.threatRaid==true)
    panel.threatSoundCB:SetChecked(charDB.threatSoundEnabled==true)
    panel.threatMissCB:SetChecked(charDB.threatMiss==true)
    panel.threatResistCB:SetChecked(charDB.threatResist==true)
    panel.threatCCCB:SetChecked(charDB.threatCC==true)
    panel.threatCCFullCombatCB:SetChecked(charDB.threatCCFullCombat==true)
    panel.threatWindowSlider:SetValue(charDB.threatWindow or 5)
    SetDropdownLabel(panel.threatSoundDropdown,"threatSoundID",cfg.defaults.tauntSoundID)

    -- External alerts
    panel.extSoundCB:SetChecked(charDB.extPlaySound==true)
    SetDropdownLabel(panel.extSoundDropdown,"extSoundID",cfg.defaults.soundID)
    panel.extWarningCB:SetChecked(charDB.extWarning==true)
    panel.extSayCB:SetChecked(charDB.extSay==true)
    panel.extYellCB:SetChecked(charDB.extYell==true)
    panel.extPartyCB:SetChecked(charDB.extParty==true)
    panel.extRaidCB:SetChecked(charDB.extRaid==true)
    panel.extWarnSecsSlider:SetValue(charDB.extWarnSeconds or 0)

    -- Automation
    local salvAuto=charDB.autoRemoveSalvation==true; local salvIcon=(not salvAuto) and (charDB.showIconSalvation==true)
    panel.salvAutoRB:SetChecked(salvAuto); panel.salvIconRB:SetChecked(salvIcon); panel.salvOffRB:SetChecked(not salvAuto and not salvIcon)
    local bopAuto=charDB.autoRemoveBoP==true; local bopIcon=(not bopAuto) and (charDB.showIconBoP==true)
    panel.bopAutoRB:SetChecked(bopAuto); panel.bopIconRB:SetChecked(bopIcon); panel.bopOffRB:SetChecked(not bopAuto and not bopIcon)
    panel.tankRoleCB:SetChecked(charDB.autoSetTankRole==true)
    panel.tankRoleRaidCB:SetChecked(charDB.autoSetTankRoleRaid==true)
    panel.repairCB:SetChecked(charDB.autoRepair~=false)
    panel.defCapBtnShowCB:SetChecked(charDB.defCapBtnShow~=false)

    local dfSize=charDB.defCapFontSize or 13; panel.defCapFontSizeSlider:SetValue(dfSize)
    local dfT=_G["TBR_DefCapFontSizeSliderText"]; if dfT then dfT:SetText(string.format("%s: %d",L["Chart Font Size"],dfSize)) end
    local dfSc=charDB.defCapScale or 1.4; panel.defCapScaleSlider:SetValue(dfSc)
    local dfST=_G["TBR_DefCapScaleSliderText"]; if dfST then dfST:SetText(string.format("%s: %.2f",L["Chart Scale"],dfSc)) end

    panel.mapBtnShowCB:SetChecked(charDB.showMinimapButton~=false)
    local mA=charDB.minimapAngle or 45; panel.mapAngleSlider:SetValue(mA)
    local mAT=_G["TBR_MinimapAngleSliderText"]; if mAT then mAT:SetText(string.format("%s: %d°",L["Minimap Angle"],mA)) end
    local mR=charDB.minimapRadiusOffset or 0; panel.mapRadiusSlider:SetValue(mR)
    local mRT=_G["TBR_MinimapRadiusSliderText"]; if mRT then mRT:SetText(string.format("%s: %d",L["Minimap Distance"],mR)) end

    local rSc=globalDB.removalScale or 1.0
    if panel.removalScaleSlider then panel.removalScaleSlider:SetValue(rSc); local t=_G["TBR_RemovalScaleSliderText"]; if t then t:SetText(string.format("%s: %.2f",L["Removal UI Scale"],rSc)) end end
    local rSp=globalDB.removalSpacing or 4
    if panel.removalSpacingSlider then panel.removalSpacingSlider:SetValue(rSp); local t=_G["TBR_RemovalSpacingSliderText"]; if t then t:SetText(string.format("%s: %d",L["Button Spacing"],rSp)) end end

    UpdateUnlockState()
    if panel.defCapColorBtn and panel.defCapColorBtn.Refresh then panel.defCapColorBtn:Refresh() end
    UpdateTauntOptionsVisuals(charDB); UpdateThreatOptionsVisuals(charDB); UpdateExtAlertsVisuals(charDB)

    -- Consumables
    if panel.consBarEnabledCB then panel.consBarEnabledCB:SetChecked(globalDB.consBarEnabled~=false) end
    if panel.consCBs and cfg.consumables then
        for _,entry in ipairs(cfg.consumables) do
            local k="cons_"..entry.key; local cb=panel.consCBs[k]
            if cb then
                local val=charDB[k]; if val==nil then val=entry.defaultOn or false end; cb:SetChecked(val==true)
                if entry.druidInstant or entry.category=="Flasks" or entry.category=="Guardian Elixirs" or entry.category=="Battle Elixirs" or entry.category=="Potions" or entry.category=="Engineering" then cb.Text:SetTextColor(0.4,1,0.4)
                elseif entry.druidWarn then cb.Text:SetTextColor(1,0.7,0.2)
                else cb.Text:SetTextColor(1,1,1) end
            end
        end
    end
end

panel:SetScript("OnShow",function() panel._wasOpened=true; panel.refresh(); ShowTab(activeTab) end)
panel:SetScript("OnHide",function()
    if TankBuffReminderCharDB then
        TankBuffReminderCharDB.removalUnlocked = false
        TankBuffReminderCharDB.extBarUnlocked  = false
    end
    if panel.removalUnlockCB then panel.removalUnlockCB:SetChecked(false) end
    if panel.extBarUnlockCB  then panel.extBarUnlockCB:SetChecked(false) end
    if TBR_RemovalUI_Update then TBR_RemovalUI_Update() end
    if TBR_ExtBar_Rebuild   then TBR_ExtBar_Rebuild()   end
    if panel._wasOpened then SyncSettings() end
end)

local logoutFrame=CreateFrame("Frame"); logoutFrame:RegisterEvent("PLAYER_LOGOUT")
logoutFrame:SetScript("OnEvent",function() if panel._wasOpened then SyncSettings() end end)


-------------------------------------------------------------------------------
-- TAB 5 — CONSUMABLES
-------------------------------------------------------------------------------
local consPage=tabPages[5]; local csX1=10; panel.consCBs={}

MakeHeader(consPage,L["Consumable Bar"],csX1,-10); MakeDivider(consPage,-28)
panel.consBarEnabledCB=CreateCheckbox(consPage,L["Show Consumable Bar"],csX1,-38)
panel.consBarEnabledCB:SetScript("OnClick",function() panel._needsConsRebuild=true; SyncSettings() end)

local consNote=consPage:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
consNote:SetPoint("TOPLEFT",csX1+28,-60); consNote:SetTextColor(0.55,0.55,0.55)
consNote:SetText(L["Shift+drag the bar to move.   |cff999999Color Legend:|r "])
local lgG=consPage:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); lgG:SetPoint("LEFT",consNote,"RIGHT",0,0); lgG:SetTextColor(0.4,1,0.4); lgG:SetText(L["Druid-Safe (instant)  "])
local lgO=consPage:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); lgO:SetPoint("LEFT",lgG,"RIGHT",4,0); lgO:SetTextColor(1,0.7,0.2); lgO:SetText(L["Drops Form (cast time)"])

local consScroll=CreateFrame("ScrollFrame","TBR_ConsOptionsScroll",consPage)
consScroll:SetPoint("TOPLEFT",consPage,"TOPLEFT",csX1,-80); consScroll:SetPoint("BOTTOMRIGHT",consPage,"BOTTOMRIGHT",-28,12)
local consScrollChild=CreateFrame("Frame",nil,consScroll); consScrollChild:SetSize(500,600); consScroll:SetScrollChild(consScrollChild)
local consScrollBar=CreateFrame("Slider","TBR_ConsOptionsScrollBar",consScroll,"UIPanelScrollBarTemplate")
consScrollBar:SetPoint("TOPRIGHT",consScroll,"TOPRIGHT",18,-16); consScrollBar:SetPoint("BOTTOMRIGHT",consScroll,"BOTTOMRIGHT",18,16)
consScrollBar:SetMinMaxValues(0,0); consScrollBar:SetValueStep(24); consScrollBar:SetValue(0)
consScrollBar:SetScript("OnValueChanged",function(self,val) consScroll:SetVerticalScroll(val) end)
consScroll:EnableMouseWheel(true)
consScroll:SetScript("OnMouseWheel",function(self,delta) local c=consScrollBar:GetValue(); local mn,mx=consScrollBar:GetMinMaxValues(); consScrollBar:SetValue(math.min(mx,math.max(mn,c-delta*72))) end)

local TWO_COL_W=230; local yPos=-4; local colIdx=0
if cfg.consumables then
    local catOrder,catSeen={},{}
    for _,e in ipairs(cfg.consumables) do if not catSeen[e.category] then table.insert(catOrder,e.category); catSeen[e.category]=true end end
    for _,cat in ipairs(catOrder) do
        local hdr=consScrollChild:CreateFontString(nil,"ARTWORK","GameFontNormal"); hdr:SetPoint("TOPLEFT",csX1,yPos); hdr:SetText(L[cat] or cat); hdr:SetTextColor(1,0.82,0); yPos=yPos-20
        local div=consScrollChild:CreateTexture(nil,"ARTWORK"); div:SetHeight(1); div:SetPoint("TOPLEFT",consScrollChild,"TOPLEFT",0,yPos); div:SetPoint("TOPRIGHT",consScrollChild,"TOPRIGHT",-20,yPos); div:SetColorTexture(0.35,0.30,0.09,0.8); yPos=yPos-6
        colIdx=0
        for _,entry in ipairs(cfg.consumables) do
            if entry.category==cat then
                local k="cons_"..entry.key; local xC=(colIdx%2==0) and csX1 or (csX1+TWO_COL_W)
                local cb=CreateCheckbox(consScrollChild,L[entry.label] or entry.label,xC,yPos)
                cb:SetScript("OnClick",function() panel._needsConsRebuild=true; SyncSettings() end)
                if entry.druidInstant then cb.Text:SetTextColor(0.4,1,0.4) elseif entry.druidWarn then cb.Text:SetTextColor(1,0.7,0.2) end
                panel.consCBs[k]=cb; colIdx=colIdx+1; if colIdx%2==0 then yPos=yPos-24 end
            end
        end
        if colIdx%2~=0 then yPos=yPos-24 end; yPos=yPos-10
    end
end

local consChildH=math.abs(yPos)+60; consScrollChild:SetHeight(consChildH)
C_Timer.After(0,function() local v=consScroll:GetHeight(); consScrollBar:SetMinMaxValues(0,math.max(0,consChildH-v)) end)
local lgNote=consScrollChild:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); lgNote:SetPoint("TOPLEFT",csX1,yPos-12); lgNote:SetTextColor(0.7,0.7,0.7); lgNote:SetJustifyH("LEFT"); lgNote:SetWidth(420); lgNote:SetText(L["CONS_TIMING_NOTE"])

-------------------------------------------------------------------------------
-- Register
-------------------------------------------------------------------------------
local category=Settings.RegisterCanvasLayoutCategory(panel,panel.name)
Settings.RegisterAddOnCategory(category)

SLASH_TANKBUFFREMINDER1="/tbr"
SlashCmdList["TANKBUFFREMINDER"]=function()
    if InCombatLockdown() then print("|cFFFF6600[TBR]|r Cannot open options while in combat."); return end
    Settings.OpenToCategory(category:GetID())
end