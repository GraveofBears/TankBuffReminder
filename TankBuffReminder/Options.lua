-- Options.lua
local L   = TBR_L
local cfg = TankBuffReminderConfig

-------------------------------------------------------------------------------
-- Root panel (registered with Settings, never holds content directly)
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
local TAB_NAMES  = { L["Buffs"], L["Appearance"], L["Alerts"], L["Automation"], L["Consumables"] }
local tabs       = {}      -- tab button frames
local tabPages   = {}      -- content frames, one per tab
local activeTab  = 1

local TAB_Y      = -50     -- top of tab buttons
local PAGE_TOP   = -80     -- top of content area (below tabs)
local PAGE_L     = 12
local PAGE_R     = -12

local function ShowTab(index)
    activeTab = index

    -- Show the correct page
    for i, page in ipairs(tabPages) do
        page:SetShown(i == index)
    end

    -- Update tab button visuals
    for i, t in ipairs(tabs) do
        local tex = t:GetNormalTexture()

        if tex then
            if i == index then
                t:SetNormalFontObject("GameFontNormal")
                tex:SetAlpha(1)
            else
                t:SetNormalFontObject("GameFontDisable")
                tex:SetAlpha(0.6)
            end
        end
    end

    PanelTemplates_SetTab(panel, index)
end

-- Build tab buttons using the standard WoW tab template
panel.numTabs = #TAB_NAMES
for i, name in ipairs(TAB_NAMES) do
    local t = CreateFrame("Button", "TankBuffReminderTab" .. i, panel, "TabButtonTemplate")
    t:SetText(name)
    t:SetID(i)

    if i == 1 then
        t:SetPoint("TOPLEFT", panel, "TOPLEFT", PAGE_L, TAB_Y)
    else
        t:SetPoint("LEFT", tabs[i-1], "RIGHT", 6, 0)
    end

    -- REQUIRED FIXES
    PanelTemplates_TabResize(t, 0)
    t:SetFrameStrata("HIGH")
    t:SetFrameLevel(panel:GetFrameLevel() + 10)

    t:SetScript("OnClick", function() ShowTab(i) end)
    tabs[i] = t
end

panel.Tabs = tabs

-- Build one content frame per tab, anchored below the tab strip
for i = 1, #TAB_NAMES do
    local page = CreateFrame("Frame", nil, panel)
    page:SetPoint("TOPLEFT",     panel, "TOPLEFT",     PAGE_L,  PAGE_TOP)
    page:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", PAGE_R,  12)
    page:Hide()
    tabPages[i] = page
end

-------------------------------------------------------------------------------
-- Shared widget helpers  (all widgets parented to a tab page)
-------------------------------------------------------------------------------
local function MakeHeader(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    fs:SetTextColor(1, 0.82, 0)
    return fs
end

local function MakeDivider(parent, y)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetHeight(1)
    t:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0,   y)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, y)
    t:SetColorTexture(0.35, 0.30, 0.09, 0.8)
    return t
end

local function CreateCheckbox(parent, label, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb.Text:SetText(label)
    return cb
end

-- Integer-step slider (for pixel offsets, etc.)
local function CreateIntSlider(parent, label, minVal, maxVal, x, y, uniqueName)
    local slider = CreateFrame("Slider", uniqueName, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(180)
    local title = _G[uniqueName .. "Text"]
    title:SetText(label)
    slider.label = label
    slider:SetScript("OnValueChanged", function(self, v)
        title:SetText(string.format("%s: %d", self.label, v))
    end)
    return slider
end

-- Float slider (for alpha, speed, size, etc.)
local function CreateFloatSlider(parent, label, minVal, maxVal, x, y, uniqueName)
    local slider = CreateFrame("Slider", uniqueName, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(0.05)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(180)
    local title = _G[uniqueName .. "Text"]
    title:SetText(label)
    slider.label = label
    slider:SetScript("OnValueChanged", function(self, v)
        title:SetText(string.format("%s: %.2f", self.label, v))
    end)
    return slider
end

local dropdownInfo = {}

local function CreateSoundDropdown(parent, uniqueName, x, y)
    local dd = CreateFrame("Frame", uniqueName, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", x, y)
    UIDropDownMenu_SetWidth(dd, 150)
    UIDropDownMenu_Initialize(dd, function(self, level)
        if not cfg.sounds then return end
        table.wipe(dropdownInfo)
        for _, sound in ipairs(cfg.sounds) do
            local sid = sound.id
            dropdownInfo.text    = sound.name
            dropdownInfo.checked = (TankBuffReminderCharDB[dd.dbKey] == sid)
            dropdownInfo.func    = function()
                TankBuffReminderCharDB[dd.dbKey] = sid
                UIDropDownMenu_SetText(dd, sound.name)
                PlaySound(sid, "Master")
            end
            UIDropDownMenu_AddButton(dropdownInfo)
        end
    end)
    return dd
end

local function SetDropdownLabel(dd, dbKey, defaultID)
    if not TankBuffReminderCharDB then return end
    local cur = TankBuffReminderCharDB[dbKey] or defaultID
    for _, sound in ipairs(cfg.sounds) do
        if sound.id == cur then UIDropDownMenu_SetText(dd, sound.name); return end
    end
    UIDropDownMenu_SetText(dd, L["Unknown Alert"])
end

-- Generic color button — dbKey is the CharDB key (a {r,g,b} table),
-- onChange is an optional callback fired after the color changes.
local function CreateColorButton(parent, label, x, y, dbKey, defaultColor, onChange)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(18, 18)
    btn:SetPoint("TOPLEFT", x, y)

    local swatch = btn:CreateTexture(nil, "BACKGROUND")
    swatch:SetAllPoints()
    swatch:SetColorTexture(1, 1, 1, 1)
    btn.swatch = swatch

    local lbl = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lbl:SetPoint("LEFT", btn, "RIGHT", 8, 0)
    lbl:SetText(label)

    -- hasOpacity flag: glow color has alpha, timer text color does not[cite: 2]
    local hasAlpha = (defaultColor.a ~= nil)

    btn:SetScript("OnClick", function()
        -- Ensure the color table exists in DB before opening[cite: 2]
        if not TankBuffReminderCharDB[dbKey] then
            local dc = defaultColor
            TankBuffReminderCharDB[dbKey] = { r = dc.r, g = dc.g, b = dc.b, a = dc.a }
        end
        
        local color = TankBuffReminderCharDB[dbKey]

        ColorPickerFrame:SetupColorPickerAndShow({
            swatchFunc = function()
                -- Capture new colors directly from the picker[cite: 2]
                local r, g, b = ColorPickerFrame:GetColorRGB()
                color.r, color.g, color.b = r, g, b
                if hasAlpha then
                    color.a = ColorPickerFrame:GetColorAlpha() or 1
                end
                -- Update the UI button and fire the live refresh[cite: 1, 2]
                swatch:SetVertexColor(color.r, color.g, color.b)
                if onChange then onChange() end
            end,
            r = color.r, g = color.g, b = color.b,
            opacity    = hasAlpha and (color.a or 1) or nil,
            hasOpacity = hasAlpha,
            -- Revert changes if user hits cancel[cite: 2]
            cancelFunc = function(prev)
                color.r, color.g, color.b = prev.r, prev.g, prev.b
                if hasAlpha then color.a = prev.opacity or 1 end
                swatch:SetVertexColor(color.r, color.g, color.b)
                if onChange then onChange() end
            end,
        })
    end)

    function btn:Refresh()
        local c = TankBuffReminderCharDB[dbKey] or defaultColor
        swatch:SetVertexColor(c.r, c.g, c.b)
    end

    return btn
end

-------------------------------------------------------------------------------
-- Master SyncSettings — reads every widget and writes to CharDB, then
-- notifies the UI. Each tab section also calls the specific sub-sync it
-- needs for live preview, but this is the authoritative full flush.
-------------------------------------------------------------------------------
panel.checkboxes = {}  -- keyed by buff key, for the Buffs tab

local function SyncSettings()
    if not TankBuffReminderCharDB then TankBuffReminderCharDB = {} end
    local db = TankBuffReminderCharDB
    local globalDB = TankBuffReminderDB or {}

    -- Buff checkboxes (Buffs tab)
    for key, cb in pairs(panel.checkboxes) do
        db[key] = cb:GetChecked()
    end

    -- Appearance tab (Main Bar)
    TankBuffReminderDB.scale     = panel.buffBarScaleSlider:GetValue()
    db.pulseSpeed        = panel.pulseSlider:GetValue()
    db.glowSize          = panel.glowSlider:GetValue()
    db.frameAlpha        = panel.alphaSlider:GetValue()
    db.buffAlpha         = panel.buffAlphaSlider:GetValue()
    db.buttonPadding     = panel.paddingSlider:GetValue()
    db.sweepAlpha        = panel.sweepAlphaSlider:GetValue()
    db.timerTextOffsetY  = panel.timerOffsetSlider:GetValue()
    db.timerFontSize     = panel.timerFontSizeSlider:GetValue()
    db.timerAlpha        = panel.timerAlphaSlider:GetValue()

    -- === CONSUMABLE BAR SETTINGS ===
    globalDB.consFrameAlpha    = panel.consFrameAlphaSlider:GetValue()
    globalDB.consScale         = panel.consScaleSlider:GetValue()
    globalDB.consAlpha         = panel.consAlphaSlider:GetValue()
    globalDB.consPadding       = panel.consPaddingSlider:GetValue()
    globalDB.consGlowAlpha     = panel.consGlowAlphaSlider:GetValue()
    globalDB.consSweepAlpha    = panel.consSweepAlphaSlider:GetValue()
    globalDB.consTimerFontSize = panel.consTimerFontSizeSlider:GetValue()
    globalDB.consTimerOffsetY  = panel.consTimerOffsetSlider:GetValue()
    globalDB.consTimerAlpha    = panel.consTimerAlphaSlider:GetValue()
    globalDB.consPulseSpeed    = panel.consPulseSlider:GetValue()
    globalDB.consMouseover     = panel.consMouseoverCB:GetChecked()
    globalDB.consOrientation   = panel.consOrientVertRB:GetChecked() and "vertical" or "horizontal"

    -- Consumable colors
    if not globalDB.consGlowColor then globalDB.consGlowColor = {r=0, g=1, b=0, a=1} end
    if not globalDB.consTextColor  then globalDB.consTextColor  = {r=1, g=1, b=1} end

    -- Alerts tab
    db.playSound           = panel.soundCB:GetChecked()         and true or false
    db.removeSoundEnabled  = panel.removeSoundCB:GetChecked()   and true or false
    db.tauntEnabled        = panel.tauntEnabledCB:GetChecked()  and true or false
    db.tauntWarning        = panel.tauntWarningCB:GetChecked()  and true or false
    db.tauntSay            = panel.tauntSayCB:GetChecked()      and true or false
    db.tauntParty          = panel.tauntPartyCB:GetChecked()    and true or false
    db.tauntRaid           = panel.tauntRaidCB:GetChecked()     and true or false
    db.tauntSoundEnabled   = panel.tauntSoundCB:GetChecked()    and true or false

    -- Automation tab
    db.autoRemoveSalvation = panel.salvAutoRB:GetChecked()       and true or false
    db.showIconSalvation   = panel.salvIconRB:GetChecked()       and true or false
    db.autoRemoveBoP       = panel.bopAutoRB:GetChecked()        and true or false
    db.showIconBoP         = panel.bopIconRB:GetChecked()        and true or false
    db.autoSetTankRole     = panel.tankRoleCB:GetChecked()       and true or false
    db.autoRepair          = panel.repairCB:GetChecked()         and true or false
    db.defCapBtnShow       = panel.defCapBtnShowCB:GetChecked()  and true or false

    -- Consumables tab
    if panel.consBarEnabledCB then
        globalDB.consBarEnabled = panel.consBarEnabledCB:GetChecked() and true or false
    end

    if cfg.consumables and panel.consCBs then
        for _, entry in ipairs(cfg.consumables) do
            local k = "cons_" .. entry.key
            local cb = panel.consCBs[k]
            if cb then
                db[k] = cb:GetChecked() and true or false
            end
        end
    end

    -- Notify subsystems
    if TankBuffReminder_UpdateGlow    then TankBuffReminder_UpdateGlow()    end
    if TBR_UI_UpdateAlpha             then TBR_UI_UpdateAlpha()             end
    if TBR_UI_UpdateTimerStyle        then TBR_UI_UpdateTimerStyle()        end
    if TBR_DefCapBtn_Refresh          then TBR_DefCapBtn_Refresh()          end
    if TBR_ConsBar_UpdateVisuals      then TBR_ConsBar_UpdateVisuals()      end

    if panel._needsRebuild then
        panel._needsRebuild = false
        if TankBuffReminder_RebuildTrackedBuffs then TankBuffReminder_RebuildTrackedBuffs() end
        if TBR_UI_Rebuild then TBR_UI_Rebuild() end
    end

    if panel._needsConsRebuild then
        panel._needsConsRebuild = false
        if TBR_ConsBar_Rebuild then TBR_ConsBar_Rebuild() end
    end
end

-------------------------------------------------------------------------------
-- TAB 1 — BUFFS
-- Class sections with enable checkboxes and priority ordering.
-------------------------------------------------------------------------------
local buffsPage       = tabPages[1]
local sectionHeaders  = {}
local sectionMeta     = {}

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
        row.frame:SetPoint("TOPLEFT", buffsPage, "TOPLEFT", meta.xBase, y)

        row.upBtn:Hide()
        row.downBtn:Hide()

        if i == 1 then
            row.downBtn:Show()
            row.downBtn:SetPoint("LEFT", row.frame, "LEFT", 0, 0)
        else
            row.upBtn:Show()
            row.upBtn:SetPoint("LEFT", row.frame, "LEFT", 0, 0)
        end
        y = y - 26
    end
end

local function CommitSortOrder(sectionName, rows)
    local db = TankBuffReminderCharDB
    db.buffOrder = db.buffOrder or {}
    local dest   = db.buffOrder[sectionName]
    if not dest then dest = {}; db.buffOrder[sectionName] = dest end
    table.wipe(dest)
    for _, r in ipairs(rows) do table.insert(dest, r.key) end
end

local function MakePriorityRows(sectionName, orderedKeys, xBase, startY)
    local rows = {}
    panel.priorityRows[sectionName] = rows
    sectionMeta[sectionName] = { startY = startY, xBase = xBase }

    for _, key in ipairs(orderedKeys) do
        local rowFrame = CreateFrame("Frame", nil, buffsPage)
        rowFrame:SetSize(210, 24)

        local upBtn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
        upBtn:SetSize(20, 20); upBtn:SetText("*")

        local downBtn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
        downBtn:SetSize(20, 20); downBtn:SetText("*")

        local cb = CreateFrame("CheckButton", nil, rowFrame, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("LEFT", rowFrame, "LEFT", 24, 0)
        cb.Text:SetText(BuffName(key))
        cb:SetScript("OnClick", function()
            panel._needsRebuild = true
            SyncSettings()
        end)
        panel.checkboxes[key] = cb

        local row = { frame = rowFrame, key = key, cb = cb, upBtn = upBtn, downBtn = downBtn }
        table.insert(rows, row)

        upBtn:SetScript("OnClick", function()
            for i, r in ipairs(rows) do
                if r.key == key and i > 1 then
                    rows[i], rows[i-1] = rows[i-1], rows[i]
                    CommitSortOrder(sectionName, rows)
                    RefreshSectionLayout(sectionName)
					panel._needsRebuild = true
                    SyncSettings()
                    break
                end
            end
        end)

        downBtn:SetScript("OnClick", function()
            for i, r in ipairs(rows) do
                if r.key == key and i < #rows then
                    rows[i], rows[i+1] = rows[i+1], rows[i]
                    CommitSortOrder(sectionName, rows)
                    RefreshSectionLayout(sectionName)
					panel._needsRebuild = true
                    SyncSettings()
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

-- Build three columns, one per class
local colX  = { 10, 220, 430 }
local colY0 = -10

for ci, section in ipairs(CLASS_SECTIONS) do
    local x = colX[ci]
    local hdr = MakeHeader(buffsPage, L[section.name] or section.name, x + 24, colY0)
    sectionHeaders[section.name] = hdr
    MakePriorityRows(section.name, GetOrderedKeys(section.name, section.keys), x, colY0 - 26)
end

local buffsNote = buffsPage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
buffsNote:SetPoint("BOTTOMLEFT", buffsPage, "BOTTOMLEFT", 10, 10)
buffsNote:SetTextColor(0.55, 0.55, 0.55)
buffsNote:SetText(L["Only your class section is active.  * sets cast priority (top = first shown)."])

-------------------------------------------------------------------------------
-- TAB 2 — APPEARANCE (Scrollable)
-------------------------------------------------------------------------------
local appPage = tabPages[2]

-- 1. Create the ScrollFrame Container
local appScroll = CreateFrame("ScrollFrame", "TBR_AppScrollFrame", appPage, "UIPanelScrollFrameTemplate")
appScroll:SetPoint("TOPLEFT", 8, -10)
-- Leave room for the scrollbar on the right
appScroll:SetPoint("BOTTOMRIGHT", -30, 10)

local appChild = CreateFrame("Frame", nil, appScroll)
-- Width must be set explicitly for children to anchor correctly
appChild:SetSize(460, 850) 
appScroll:SetScrollChild(appChild)

-- Helper to make headers inside the child frame
local function AppHeader(text, y)
    local h = appChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    h:SetPoint("TOPLEFT", 10, y)
    h:SetText(text)
    h:SetTextColor(1, 0.82, 0)
    return h
end

-- Layout Constants
local col1, col2 = 10, 260

-------------------------------------------------------------------------------
-- SECTION 1: MAIN BAR
-------------------------------------------------------------------------------
AppHeader(L["Main Bar Appearance"], -10)

-- Column 1: Core Visuals
panel.glowSlider      = CreateFloatSlider(appChild, L["Glow Size"],       1.0, 3.0,  col1, -56,  "TBR_GlowSlider")
panel.pulseSlider     = CreateFloatSlider(appChild, L["Pulse Speed"],     0,   10,   col1, -116, "TBR_PulseSlider")
panel.alphaSlider     = CreateFloatSlider(appChild, L["Frame Alpha"],     0.001, 1.0, col1, -176, "TBR_AlphaSlider")
panel.buffAlphaSlider = CreateFloatSlider(appChild, L["Icon Alpha"],      0.01, 1.0,  col1, -236, "TBR_BuffAlphaSlider")
panel.paddingSlider   = CreateFloatSlider(appChild, L["Button Spacing"],  0,   20,   col1, -296, "TBR_PaddingSlider")

panel.glowColorBtn = CreateColorButton(
    appChild, L["Glow Color"], col1 + 4, -364,
    "glowColor", cfg.defaults.glowColor,
    function() if TankBuffReminder_UpdateGlow then TankBuffReminder_UpdateGlow() end end
)

-- Column 2: Timers & Sweeps
panel.buffBarScaleSlider  = CreateFloatSlider(appChild, L["Bar Scale"], 0.5, 3.0, col2, -56,  "TBR_BuffBarScaleSlider")
panel.sweepAlphaSlider    = CreateFloatSlider(appChild, L["Buff Sweep Alpha"], 0.0, 1.0, col2, -116, "TBR_SweepAlphaSlider")
panel.timerAlphaSlider    = CreateFloatSlider(appChild, L["Timer Text Alpha"], 0.0, 1.0, col2, -176, "TBR_TimerAlphaSlider")
panel.timerOffsetSlider   = CreateIntSlider(appChild, L["Text Vertical Offset"], -32, 32, col2, -236, "TBR_TimerOffsetSlider")
panel.timerFontSizeSlider = CreateIntSlider(appChild, L["Font Size"], 6, 32, col2, -296, "TBR_TimerFontSizeSlider")

panel.timerColorBtn = CreateColorButton(
    appChild, L["Duration Text Color"], col2 + 4, -356,
    "timerTextColor", cfg.defaults.timerTextColor,
    function() if TBR_UI_UpdateTimerStyle then TBR_UI_UpdateTimerStyle() end end
)

-- Value Changed Scripts for Live Preview (Main Bar)
panel.buffBarScaleSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format(L["Bar Scale"] .. ": %.2f", v))
    if TankBuffReminderDB then
        if TBR_UI_SetScale then TBR_UI_SetScale(v) end
    end
end)
panel.alphaSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format(L["Frame Alpha"] .. ": %.2f", v))
    if TankBuffReminderCharDB then
        TankBuffReminderCharDB.frameAlpha = v
        if TBR_UI_UpdateAlpha then TBR_UI_UpdateAlpha() end
    end
end)
panel.buffAlphaSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format(L["Icon Alpha"] .. ": %.2f", v))
    if TankBuffReminderCharDB then
        TankBuffReminderCharDB.buffAlpha = v
        if TBR_UI_UpdateAlpha then TBR_UI_UpdateAlpha() end
    end
end)
panel.sweepAlphaSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format(L["Buff Sweep Alpha"] .. ": %.2f", v))
    if TankBuffReminderCharDB then
        TankBuffReminderCharDB.sweepAlpha = v
        if TBR_UI_UpdateTimerStyle then TBR_UI_UpdateTimerStyle() end
    end
end)
panel.timerAlphaSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format(L["Timer Text Alpha"] .. ": %.2f", v))
    if TankBuffReminderCharDB then
        TankBuffReminderCharDB.timerAlpha = v
        if TBR_UI_UpdateTimerStyle then TBR_UI_UpdateTimerStyle() end
    end
end)
panel.timerOffsetSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format(L["Text Vertical Offset"] .. ": %d", v))
    if TankBuffReminderCharDB then
        TankBuffReminderCharDB.timerTextOffsetY = v
        if TBR_UI_UpdateTimerStyle then TBR_UI_UpdateTimerStyle() end
    end
end)
panel.timerFontSizeSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format(L["Font Size"] .. ": %d", v))
    if TankBuffReminderCharDB then
        TankBuffReminderCharDB.timerFontSize = v
        if TBR_UI_UpdateTimerStyle then TBR_UI_UpdateTimerStyle() end
    end
end)

-- MouseUp Syncs (Main Bar)
for _, s in ipairs({ panel.buffBarScaleSlider, panel.glowSlider, panel.pulseSlider, panel.alphaSlider, panel.buffAlphaSlider, panel.sweepAlphaSlider, panel.timerAlphaSlider, panel.timerOffsetSlider, panel.timerFontSizeSlider }) do
    s:SetScript("OnMouseUp", SyncSettings)
end
panel.paddingSlider:SetScript("OnMouseUp", function() panel._needsRebuild = true SyncSettings() end)

-------------------------------------------------------------------------------
-- SECTION 2: DIVIDER & CONSUMABLE BAR
-------------------------------------------------------------------------------
local consDiv = appChild:CreateTexture(nil, "ARTWORK")
consDiv:SetSize(460, 1)
consDiv:SetColorTexture(1, 1, 1, 0.15)
consDiv:SetPoint("TOPLEFT", 10, -420)

AppHeader(L["Consumable Bar Appearance"], -440)

-- Column 1: Cons Core & Color
panel.consFrameAlphaSlider  = CreateFloatSlider(appChild, L["Frame & Border Alpha"], 0.0, 1.0, col1, -486, "TBR_ConsFrameAlphaSlider")
panel.consScaleSlider       = CreateFloatSlider(appChild, L["Bar Scale"], 0.5, 2.0, col1, -546, "TBR_ConsScaleSlider")
panel.consAlphaSlider       = CreateFloatSlider(appChild, L["Icon Alpha (Active)"], 0.0, 1.0, col1, -606, "TBR_ConsAlphaSlider")
panel.consGlowAlphaSlider   = CreateFloatSlider(appChild, L["Glow Alpha"], 0.0, 1.0, col1, -666, "TBR_ConsGlowAlphaSlider")
panel.consSweepAlphaSlider  = CreateFloatSlider(appChild, L["Sweep Alpha"], 0.0, 1.0, col1, -726, "TBR_ConsSweepAlphaSlider")

-- Glow color button — reads/writes globalDB.consGlowColor directly
do
    local btn = CreateFrame("Button", nil, appChild)
    btn:SetSize(18, 18)
    btn:SetPoint("TOPLEFT", col1 + 4, -786)
    local swatch = btn:CreateTexture(nil, "BACKGROUND")
    swatch:SetAllPoints()
    swatch:SetColorTexture(1, 1, 1, 1)
    btn.swatch = swatch
    local lbl = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lbl:SetPoint("LEFT", btn, "RIGHT", 8, 0)
    lbl:SetText(L["Cons Glow Color"])
    btn:SetScript("OnClick", function()
        local db = TankBuffReminderDB
        if not db then return end
        if not db.consGlowColor then db.consGlowColor = {r=0, g=1, b=0, a=1} end
        local color = db.consGlowColor
        ColorPickerFrame:SetupColorPickerAndShow({
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                local a = ColorPickerFrame:GetColorAlpha()
                color.r, color.g, color.b, color.a = r, g, b, a
                swatch:SetVertexColor(r, g, b)
                if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end
            end,
            r = color.r, g = color.g, b = color.b,
            opacity = color.a or 1, hasOpacity = true,
            cancelFunc = function(prev)
                color.r, color.g, color.b, color.a = prev.r, prev.g, prev.b, prev.opacity
                swatch:SetVertexColor(color.r, color.g, color.b)
                if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end
            end,
        })
    end)
    function btn:Refresh()
        local db = TankBuffReminderDB
        local c = (db and db.consGlowColor) or {r=0, g=1, b=0}
        swatch:SetVertexColor(c.r, c.g, c.b)
    end
    panel.consGlowColorBtn = btn
end

-- Column 2: Cons Layout & Timers
panel.consPaddingSlider = CreateIntSlider(appChild, L["Button Spacing"], 0, 20, col2, -486, "TBR_ConsPaddingSlider")
panel.consTimerFontSizeSlider = CreateIntSlider(appChild, L["Timer Font Size"], 8, 30, col2, -546, "TBR_ConsFontSizeSlider")
panel.consTimerOffsetSlider = CreateIntSlider(appChild, L["Timer Y Offset"], -30, 30, col2, -606, "TBR_ConsOffsetSlider")
panel.consTimerAlphaSlider = CreateFloatSlider(appChild, L["Timer Alpha"], 0.0, 1.0, col2, -666, "TBR_ConsTimerAlphaSlider")

-- Pulse Speed (New)
panel.consPulseSlider = CreateFloatSlider(appChild, L["Pulse Speed"], 0.0, 8.0, col2, -726, "TBR_ConsPulseSlider")
panel.consPulseSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format(L["Pulse Speed"] .. ": %.2f", v))
    TankBuffReminderDB.consPulseSpeed = v
end)

-- Text color button
do
    local btn = CreateFrame("Button", nil, appChild)
    btn:SetSize(18, 18)
    btn:SetPoint("TOPLEFT", col2 + 4, -786)
    local swatch = btn:CreateTexture(nil, "BACKGROUND")
    swatch:SetAllPoints()
    swatch:SetColorTexture(1, 1, 1, 1)
    btn.swatch = swatch
    local lbl = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    lbl:SetPoint("LEFT", btn, "RIGHT", 8, 0)
    lbl:SetText(L["Text Color"])
    btn:SetScript("OnClick", function()
        local db = TankBuffReminderDB
        if not db then return end
        if not db.consTextColor then db.consTextColor = {r=1, g=1, b=1} end
        local color = db.consTextColor
        ColorPickerFrame:SetupColorPickerAndShow({
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                color.r, color.g, color.b = r, g, b
                swatch:SetVertexColor(r, g, b)
                if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end
            end,
            r = color.r, g = color.g, b = color.b,
            hasOpacity = false,
            cancelFunc = function(prev)
                color.r, color.g, color.b = prev.r, prev.g, prev.b
                swatch:SetVertexColor(color.r, color.g, color.b)
                if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end
            end,
        })
    end)
    function btn:Refresh()
        local db = TankBuffReminderDB
        local c = (db and db.consTextColor) or {r=1, g=1, b=1}
        swatch:SetVertexColor(c.r, c.g, c.b)
    end
    panel.consTextColorBtn = btn
end

panel.consMouseoverCB = CreateCheckbox(appChild, L["Hide until Mouseover"])
panel.consMouseoverCB:SetPoint("TOPLEFT", col2, -846)   -- Adjusted down
panel.consMouseoverCB:SetScript("OnClick", function()
    if not TankBuffReminderDB then TankBuffReminderDB = {} end
    TankBuffReminderDB.consMouseover = panel.consMouseoverCB:GetChecked()
    if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end
    SyncSettings()
end)

-- Orientation: Horizontal / Vertical radio buttons
do
    local orientLbl = appChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    orientLbl:SetPoint("TOPLEFT", col1, -838)
    orientLbl:SetText(L["Bar Orientation"])

    local rbH = CreateFrame("CheckButton", "TBR_ConsOrientHorizRB", appChild, "UIRadioButtonTemplate")
    rbH:SetPoint("TOPLEFT", col1, -855)
    rbH.text:SetText(L["Horizontal"])
    panel.consOrientHorizRB = rbH

    local rbV = CreateFrame("CheckButton", "TBR_ConsOrientVertRB", appChild, "UIRadioButtonTemplate")
    rbV:SetPoint("LEFT", rbH, "RIGHT", 60, 0)
    rbV.text:SetText(L["Vertical"])
    panel.consOrientVertRB = rbV

    rbH:SetScript("OnClick", function()
        rbH:SetChecked(true)
        rbV:SetChecked(false)
        if TankBuffReminderDB then TankBuffReminderDB.consOrientation = "horizontal" end
        panel._needsConsRebuild = true
        SyncSettings()
    end)
    rbV:SetScript("OnClick", function()
        rbV:SetChecked(true)
        rbH:SetChecked(false)
        if TankBuffReminderDB then TankBuffReminderDB.consOrientation = "vertical" end
        panel._needsConsRebuild = true
        SyncSettings()
    end)
end

-------------------------------------------------------------------------------
-- Live Previews (Cons Bar)
-------------------------------------------------------------------------------
-- Scale & Padding (Requires Rebuild)
panel.consScaleSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format("Bar Scale: %.2f", v))
    TankBuffReminderDB.consScale = v
    panel._needsConsRebuild = true
end)
panel.consPaddingSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format(L["Button Spacing"] .. ": %d", v))
    TankBuffReminderDB.consPadding = v
    panel._needsConsRebuild = true
end)

-- Visuals (Immediate Update)
panel.consAlphaSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format("Icon Alpha: %.2f", v))
    TankBuffReminderDB.consAlpha = v
    if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end
end)
panel.consGlowAlphaSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format(L["Glow Alpha"] .. ": %.2f", v))
    TankBuffReminderDB.consGlowAlpha = v
    if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end
end)
panel.consSweepAlphaSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format(L["Sweep Alpha"] .. ": %.2f", v))
    TankBuffReminderDB.consSweepAlpha = v
    if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end
end)
panel.consTimerFontSizeSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format(L["Timer Font Size"] .. ": %d", v))
    TankBuffReminderDB.consTimerFontSize = v
    if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end
end)
panel.consTimerOffsetSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format(L["Timer Y Offset"] .. ": %d", v))
    TankBuffReminderDB.consTimerOffsetY = v
    if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end
end)
panel.consTimerAlphaSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format(L["Timer Alpha"] .. ": %.2f", v))
    TankBuffReminderDB.consTimerAlpha = v
    if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end
end)
panel.consFrameAlphaSlider:SetScript("OnValueChanged", function(self, v)
    _G[self:GetName() .. "Text"]:SetText(string.format(L["Frame Alpha"] .. ": %.2f", v))
    TankBuffReminderDB.consFrameAlpha = v
    if TBR_ConsBar_UpdateVisuals then TBR_ConsBar_UpdateVisuals() end
end)
-- MouseUp Syncs (Cons Bar)
local consSliders = { 
    panel.consFrameAlphaSlider,
    panel.consScaleSlider, panel.consAlphaSlider, panel.consGlowAlphaSlider, 
    panel.consPaddingSlider, panel.consSweepAlphaSlider, panel.consTimerFontSizeSlider,
    panel.consTimerOffsetSlider, panel.consTimerAlphaSlider 
}
for _, s in ipairs(consSliders) do
    s:SetScript("OnMouseUp", SyncSettings)
end

-- Adjust Scroll Height for extra items
appChild:SetHeight(960)

-------------------------------------------------------------------------------
-- TAB 3 — ALERTS
-- Missing buff alerts, removal alerts, and taunt system.
-------------------------------------------------------------------------------
local alertPage = tabPages[3]
local alX1, alX2 = 10, 280

-- Column 1: Audio Notifications
MakeHeader(alertPage, L["Buff Alert Sound"], alX1, -10)
MakeDivider(alertPage, -28)

panel.soundCB = CreateCheckbox(alertPage, L["Play sound when a buff is missing"], alX1, -42)
panel.soundCB:SetScript("OnClick", SyncSettings)

local soundLbl = alertPage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
soundLbl:SetPoint("TOPLEFT", alX1 + 28, -70)
soundLbl:SetText(L["Missing Buff Sound:"])

panel.soundDropdown = CreateSoundDropdown(alertPage, "TankBuffReminderSoundDropdown", alX1 + 10, -85)
panel.soundDropdown.dbKey = "soundID"

-- New Section: Removal Alerts (Moved from Automation)
MakeHeader(alertPage, L["Removal Alerts"], alX1, -145)

panel.removeSoundCB = CreateCheckbox(alertPage, L["Enable removal alert sound (Salv/BoP)"], alX1, -177)
panel.removeSoundCB:SetScript("OnClick", SyncSettings)

local removeSndLbl = alertPage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
removeSndLbl:SetPoint("TOPLEFT", alX1 + 28, -205)
removeSndLbl:SetText(L["Removal Alert Sound:"])

panel.removeSoundDropdown = CreateSoundDropdown(alertPage, "TBR_RemoveSoundDropdown", alX1 + 10, -220)
panel.removeSoundDropdown.dbKey = "removeSoundID"

-- Column 2: Taunt Alert System
MakeHeader(alertPage, L["Taunt Alert System"], alX2, -10)
MakeDivider(alertPage, -28)

panel.tauntEnabledCB = CreateCheckbox(alertPage, L["Enable Taunt Failure Detection"], alX2, -42)
panel.tauntWarningCB = CreateCheckbox(alertPage, L["Self Warning (chat message)"],    alX2, -67)
panel.tauntSayCB     = CreateCheckbox(alertPage, L["Announce in /Say"],               alX2, -92)
panel.tauntPartyCB   = CreateCheckbox(alertPage, L["Announce in /Party"],             alX2, -117)
panel.tauntRaidCB    = CreateCheckbox(alertPage, L["Announce in /Raid"],              alX2, -142)

for _, cb in ipairs({ panel.tauntEnabledCB, panel.tauntWarningCB,
                      panel.tauntSayCB, panel.tauntPartyCB, panel.tauntRaidCB }) do
    cb:SetScript("OnClick", SyncSettings)
end

panel.tauntSoundCB = CreateCheckbox(alertPage, L["Play sound on taunt failure"], alX2, -182)
panel.tauntSoundCB:SetScript("OnClick", SyncSettings)

local tauntSndLbl = alertPage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
tauntSndLbl:SetPoint("TOPLEFT", alX2 + 28, -210)
tauntSndLbl:SetText(L["Taunt Failure Sound:"])

panel.tauntSoundDropdown = CreateSoundDropdown(alertPage, "TankBuffReminderTauntSoundDropdown", alX2 + 10, -225)
panel.tauntSoundDropdown.dbKey = "tauntSoundID"

-------------------------------------------------------------------------------
-- TAB 4 — AUTOMATION
-------------------------------------------------------------------------------
local autoPage = tabPages[4]
local auX1, auX2 = 10, 310

-- COLUMN 1: Combat Automation
MakeHeader(autoPage, L["Combat Automation"], auX1, -10)
MakeDivider(autoPage, -28)

-- Explanatory note for the radio options
local autoNote = autoPage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
autoNote:SetPoint("TOPLEFT", auX1, -48)
autoNote:SetWidth(320)                    -- Increased width
autoNote:SetJustifyH("LEFT")
autoNote:SetTextColor(0.65, 0.65, 0.65)
autoNote:SetText(L["AUTOMATION_NOTE"])

-- Helper: builds a labeled radio trio (Auto-remove / Show icon / Off) for one spell
local function MakeRemovalRadioRow(parent, label, x, y)
    local lbl = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    lbl:SetPoint("TOPLEFT", x, y)
    lbl:SetText(label)
    
    local function MakeRadio(caption, rx, ry)
        local rb = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
        rb:SetPoint("TOPLEFT", rx, ry)
        rb.Text = rb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rb.Text:SetPoint("LEFT", rb, "RIGHT", 5, 0)
        rb.Text:SetText(caption)
        return rb
    end
    
    local rAuto = MakeRadio(L["Auto-remove"], x, y - 18)
    local rIcon = MakeRadio(L["Show icon"],   x + 115, y - 18)
    local rOff  = MakeRadio(L["Off"],         x + 225, y - 18)

    local function SelectRadio(chosen)
        rAuto:SetChecked(chosen == rAuto)
        rIcon:SetChecked(chosen == rIcon)
        rOff:SetChecked(chosen == rOff)
        panel._needsRebuild = true
        SyncSettings()
    end

    rAuto:SetScript("OnClick", function() SelectRadio(rAuto) end)
    rIcon:SetScript("OnClick", function() SelectRadio(rIcon) end)
    rOff:SetScript("OnClick",  function() SelectRadio(rOff)  end)

    return rAuto, rIcon, rOff
end

-- Adjusted Y positions (shifted down more)
panel.salvAutoRB, panel.salvIconRB, panel.salvOffRB =
    MakeRemovalRadioRow(autoPage, L["Blessing of Salvation"], auX1, -138)

panel.bopAutoRB, panel.bopIconRB, panel.bopOffRB =
    MakeRemovalRadioRow(autoPage, L["Blessing of Protection"], auX1, -188)

panel.tankRoleCB = CreateCheckbox(autoPage, L["Auto-set Tank Role (5-man groups)"], auX1, -238)
panel.repairCB   = CreateCheckbox(autoPage, L["Auto-Repair at Merchant"], auX1, -263)

-- COLUMN 2: Tools & Maintenance
MakeHeader(autoPage, L["Tools"], auX2, -10)
MakeDivider(autoPage, -28)

panel.defCapBtnShowCB = CreateCheckbox(autoPage, L["Show Defense Cap button on Character Sheet"], auX2, -42)
panel.defCapBtnShowCB:SetScript("OnClick", SyncSettings)

local defBtn = CreateFrame("Button", nil, autoPage, "UIPanelButtonTemplate")
defBtn:SetSize(190, 24)
defBtn:SetPoint("TOPLEFT", auX2, -78)
defBtn:SetText(L["Open Defense Cap Chart"])
defBtn:SetScript("OnClick", function()
    if TBR_DefenseCap_Toggle then 
        TBR_DefenseCap_Toggle()
    else 
        print("|cFFFF0000" .. L["[TBR] Defense Chart module not found."] .. "|r") 
    end
end)

-- This helper handles the label, the swatch, the color picker logic, 
-- and saving to TankBuffReminderCharDB.defCapColor automatically.
panel.defCapColorBtn = CreateColorButton(
    autoPage, 
    L["Chart Frame Color"], 
    auX2, -112, 
    "defCapColor", 
    {r = 0.6, g = 0.5, b = 0.2, a = 1}, 
    function() 
        if TBR_DefenseCap_UpdateColor then TBR_DefenseCap_UpdateColor() end 
    end
)
-- RESET SECTION
local resetBtn = CreateFrame("Button", nil, autoPage, "UIPanelButtonTemplate")
resetBtn:SetSize(160, 24)
resetBtn:SetPoint("BOTTOMLEFT", autoPage, "BOTTOMLEFT", auX2, 20)
resetBtn:SetText(L["Reset All Settings"])
resetBtn:SetScript("OnClick", function()
    if TankBuffReminderCharDB then table.wipe(TankBuffReminderCharDB) end
    if TankBuffReminderDB then table.wipe(TankBuffReminderDB) end
    
    panel.refresh() 
    ReloadUI() 
end)

local resetLbl = autoPage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
resetLbl:SetPoint("BOTTOMLEFT", resetBtn, "TOPLEFT", 0, 10)
resetLbl:SetTextColor(0.8, 0.5, 0.5)
resetLbl:SetText(L["Caution: This wipes all settings!"])

function panel.refresh()
    if not TankBuffReminderCharDB then TankBuffReminderCharDB = {} end
    local charDB = TankBuffReminderCharDB
    local globalDB = TankBuffReminderDB or {}
    local cfg = TankBuffReminderConfig

    -- Buffs tab — restore values, then grey out non-player-class sections
    local _, playerClass = UnitClass("player")
    
    -- 1. Create the map first so we can use it in the checkbox loop
    local buffClassMap = {}
    for _, b in ipairs(cfg.buffs) do buffClassMap[b.key] = b.class end

    -- 2. Update checkboxes with class-based fallback
    for key, cb in pairs(panel.checkboxes) do
        local val = charDB[key]
        
        -- If no saved setting (nil), only check it if it matches our class
        if val == nil then
            val = (buffClassMap[key] == playerClass)
        end
        
        cb:SetChecked(val == true)
    end

    -- 3. Handle the greying out of sections
    for _, section in ipairs(CLASS_SECTIONS) do
        local isMyClass = (section.name:upper() == playerClass)
        local rows = panel.priorityRows[section.name]
        if rows then
            for _, row in ipairs(rows) do
                if isMyClass then
                    row.cb:Enable()
                    row.cb.Text:SetAlpha(1.0)
                else
                    row.cb:Disable()
                    row.cb.Text:SetAlpha(0.4)
                    -- Force uncheck if it's not our class and we just reset
                    if charDB[row.cb.key] == nil then
                        row.cb:SetChecked(false)
                    end
                end
            end
        end
    end

    -- Appearance tab
    panel.buffBarScaleSlider:SetValue(globalDB.scale          or 1.0)
    panel.glowSlider:SetValue(charDB.glowSize            or cfg.defaults.glowSize)
    panel.pulseSlider:SetValue(charDB.pulseSpeed        or cfg.defaults.pulseSpeed)
    panel.alphaSlider:SetValue(charDB.frameAlpha        or cfg.defaults.frameAlpha)
    panel.buffAlphaSlider:SetValue(charDB.buffAlpha     or cfg.defaults.buffAlpha)
    panel.paddingSlider:SetValue(charDB.buttonPadding  or 4)
    panel.sweepAlphaSlider:SetValue(charDB.sweepAlpha or 0.6)
    panel.timerOffsetSlider:SetValue(charDB.timerTextOffsetY or 0)
    panel.timerFontSizeSlider:SetValue(charDB.timerFontSize  or cfg.defaults.timerFontSize)
    panel.glowColorBtn:Refresh()
    panel.timerColorBtn:Refresh()
    panel.timerAlphaSlider:SetValue(charDB.timerAlpha or 1.0)

    -- Consumable Bar Refresh
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

    -- Orientation radio buttons
    local isVert = (globalDB.consOrientation == "vertical")
    panel.consOrientHorizRB:SetChecked(not isVert)
    panel.consOrientVertRB:SetChecked(isVert)

    -- Consumable Timers Refresh
    panel.consTimerFontSizeSlider:SetValue(globalDB.consTimerFontSize or 12)
    panel.consTimerOffsetSlider:SetValue(globalDB.consTimerOffsetY or 0)
    panel.consTimerAlphaSlider:SetValue(globalDB.consTimerAlpha or 1.0)
    panel.consSweepAlphaSlider:SetValue(globalDB.consSweepAlpha or 0.6)

    -- Color swatches (read from globalDB)
    if panel.consGlowColorBtn and panel.consGlowColorBtn.Refresh then
        panel.consGlowColorBtn:Refresh()
    end
    if panel.consTextColorBtn and panel.consTextColorBtn.Refresh then
        panel.consTextColorBtn:Refresh()
    end

    -- Alerts tab
    panel.soundCB:SetChecked(charDB.playSound ~= false)
    SetDropdownLabel(panel.soundDropdown,      "soundID",      cfg.defaults.soundID)
    panel.removeSoundCB:SetChecked(charDB.removeSoundEnabled ~= false)
    SetDropdownLabel(panel.removeSoundDropdown, "removeSoundID", cfg.defaults.removeSoundID)
    panel.tauntEnabledCB:SetChecked(charDB.tauntEnabled      ~= false)
    panel.tauntWarningCB:SetChecked(charDB.tauntWarning      ~= false)
    panel.tauntSayCB:SetChecked(charDB.tauntSay              == true)
    panel.tauntPartyCB:SetChecked(charDB.tauntParty          == true)
    panel.tauntRaidCB:SetChecked(charDB.tauntRaid            == true)
    panel.tauntSoundCB:SetChecked(charDB.tauntSoundEnabled   ~= false)
    SetDropdownLabel(panel.tauntSoundDropdown, "tauntSoundID", cfg.defaults.tauntSoundID)

    -- Automation tab — per-spell radio groups
    local salvAuto = charDB.autoRemoveSalvation == true
    local salvIcon = (not salvAuto) and (charDB.showIconSalvation == true)
    panel.salvAutoRB:SetChecked(salvAuto)
    panel.salvIconRB:SetChecked(salvIcon)
    panel.salvOffRB:SetChecked(not salvAuto and not salvIcon)

    local bopAuto = charDB.autoRemoveBoP == true
    local bopIcon = (not bopAuto) and (charDB.showIconBoP == true)
    panel.bopAutoRB:SetChecked(bopAuto)
    panel.bopIconRB:SetChecked(bopIcon)
    panel.bopOffRB:SetChecked(not bopAuto and not bopIcon)

    panel.tankRoleCB:SetChecked(charDB.autoSetTankRole      ~= false)
    panel.repairCB:SetChecked(charDB.autoRepair             ~= false)
    panel.defCapBtnShowCB:SetChecked(charDB.defCapBtnShow   ~= false)
    
    -- Sync the Defense Chart Color button
    if panel.defCapColorBtn and panel.defCapColorBtn.Refresh then
        panel.defCapColorBtn:Refresh()
    end

    -- Consumables tab
    if panel.consBarEnabledCB then
        panel.consBarEnabledCB:SetChecked(globalDB.consBarEnabled ~= false)
    end

    -- Individual Consumable Checkboxes
    if panel.consCBs and cfg.consumables then
        for _, entry in ipairs(cfg.consumables) do
            local k = "cons_" .. entry.key
            local cb = panel.consCBs[k]
            if cb then 
                local val = charDB[k]
                if val == nil then 
                    val = entry.defaultOn or false 
                end
                cb:SetChecked(val == true)
                
                -- Bear-Safe coloring
                if entry.druidInstant 
                   or entry.category == "Flasks" 
                   or entry.category == "Guardian Elixirs" 
                   or entry.category == "Battle Elixirs" 
                   or entry.category == "Potions" 
                   or entry.category == "Engineering" then
                    cb.Text:SetTextColor(0.4, 1, 0.4) -- Green
                elseif entry.druidWarn then
                    cb.Text:SetTextColor(1, 0.7, 0.2) -- Orange
                else
                    cb.Text:SetTextColor(1, 1, 1)
                end
            end
        end
    end
end

panel:SetScript("OnShow", function()
    panel._wasOpened = true
    panel.refresh()
    ShowTab(activeTab)
end)

panel:SetScript("OnHide", function()
    if panel._wasOpened then
        SyncSettings()
    end
end)

local logoutFrame = CreateFrame("Frame")
logoutFrame:RegisterEvent("PLAYER_LOGOUT")
logoutFrame:SetScript("OnEvent", function()
    if panel._wasOpened then
        SyncSettings()
    end
end)

-------------------------------------------------------------------------------
-- TAB 5 - CONSUMABLES
-------------------------------------------------------------------------------
local consPage = tabPages[5]
local csX1 = 10

panel.consCBs = {}

MakeHeader(consPage, L["Consumable Bar"], csX1, -10)
MakeDivider(consPage, -28)

panel.consBarEnabledCB = CreateCheckbox(consPage, L["Show Consumable Bar"], csX1, -38)
panel.consBarEnabledCB:SetScript("OnClick", function()
    panel._needsConsRebuild = true -- SET THE FLAG HERE
    SyncSettings()
end)

-- 1. The main instruction text
local consNote = consPage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
consNote:SetPoint("TOPLEFT", csX1 + 28, -60)
consNote:SetTextColor(0.55, 0.55, 0.55)
consNote:SetText(L["Shift+drag the bar to move.   |cff999999Color Legend:|r "])

-- 2. "Druid-Safe" text chained to the end of the instruction
local legendGreen = consPage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
legendGreen:SetPoint("LEFT", consNote, "RIGHT", 0, 0)
legendGreen:SetTextColor(0.4, 1, 0.4)
legendGreen:SetText(L["Druid-Safe (instant)  "])

-- 3. "Drops Form" text chained to the end of the green text
local legendOrange = consPage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
legendOrange:SetPoint("LEFT", legendGreen, "RIGHT", 4, 0)
legendOrange:SetTextColor(1, 0.7, 0.2)
legendOrange:SetText(L["Drops Form (cast time)"])

-- Plain ScrollFrame + a separate Slider for the scrollbar.
-- UIPanelScrollBarTemplate must go on a Slider, not a ScrollFrame.
local consScroll = CreateFrame("ScrollFrame", "TBR_ConsOptionsScroll", consPage)
consScroll:SetPoint("TOPLEFT",     consPage, "TOPLEFT",     csX1,  -80)
consScroll:SetPoint("BOTTOMRIGHT", consPage, "BOTTOMRIGHT", -28,   12)

local consScrollChild = CreateFrame("Frame", nil, consScroll)
consScrollChild:SetSize(500, 600)
consScroll:SetScrollChild(consScrollChild)

local consScrollBar = CreateFrame("Slider", "TBR_ConsOptionsScrollBar", consScroll, "UIPanelScrollBarTemplate")
consScrollBar:SetPoint("TOPRIGHT",    consScroll, "TOPRIGHT",    18, -16)
consScrollBar:SetPoint("BOTTOMRIGHT", consScroll, "BOTTOMRIGHT", 18,  16)
consScrollBar:SetMinMaxValues(0, 0)
consScrollBar:SetValueStep(24)
consScrollBar:SetValue(0)
consScrollBar:SetScript("OnValueChanged", function(self, val)
    consScroll:SetVerticalScroll(val)
end)
consScroll:EnableMouseWheel(true)
consScroll:SetScript("OnMouseWheel", function(self, delta)
    local cur = consScrollBar:GetValue()
    local min, max = consScrollBar:GetMinMaxValues()
    consScrollBar:SetValue(math.min(max, math.max(min, cur - delta * 24 * 3)))
end)

local TWO_COL_W = 230
local yPos      = -4
local lastCat   = nil
local colIdx    = 0

if cfg.consumables then
    local catOrder = {}
    local catSeen  = {}
    for _, entry in ipairs(cfg.consumables) do
        if not catSeen[entry.category] then
            table.insert(catOrder, entry.category)
            catSeen[entry.category] = true
        end
    end

    for _, cat in ipairs(catOrder) do
        local hdr = consScrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        hdr:SetPoint("TOPLEFT", csX1, yPos)
        hdr:SetText(L[cat] or cat)
        hdr:SetTextColor(1, 0.82, 0)
        yPos = yPos - 20

        local div = consScrollChild:CreateTexture(nil, "ARTWORK")
        div:SetHeight(1)
        div:SetPoint("TOPLEFT",  consScrollChild, "TOPLEFT",  0,   yPos)
        div:SetPoint("TOPRIGHT", consScrollChild, "TOPRIGHT", -20, yPos)
        div:SetColorTexture(0.35, 0.30, 0.09, 0.8)
        yPos = yPos - 6

        colIdx = 0
        for _, entry in ipairs(cfg.consumables) do
            if entry.category == cat then
                local k  = "cons_" .. entry.key
                local xC = (colIdx % 2 == 0) and csX1 or (csX1 + TWO_COL_W)
                local cb = CreateCheckbox(consScrollChild, L[entry.label] or entry.label, xC, yPos)
                cb:SetScript("OnClick", function()
                    panel._needsConsRebuild = true
                    SyncSettings()
                end)
                if entry.druidInstant then
                    cb.Text:SetTextColor(0.4, 1, 0.4)
                elseif entry.druidWarn then
                    cb.Text:SetTextColor(1, 0.7, 0.2)
                end
                panel.consCBs[k] = cb
                colIdx = colIdx + 1
                if colIdx % 2 == 0 then yPos = yPos - 24 end
            end
        end
        if colIdx % 2 ~= 0 then yPos = yPos - 24 end
        yPos = yPos - 10
    end
end

local consChildH = math.abs(yPos) + 60
consScrollChild:SetHeight(consChildH)
-- Update scrollbar range now that the content height is known
C_Timer.After(0, function()
    local viewH = consScroll:GetHeight()
    local maxScroll = math.max(0, consChildH - viewH)
    consScrollBar:SetMinMaxValues(0, maxScroll)
end)

local legendY = yPos - 12
local legendNote = consScrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
legendNote:SetPoint("TOPLEFT", csX1, legendY)
legendNote:SetTextColor(0.7, 0.7, 0.7)
legendNote:SetJustifyH("LEFT")
legendNote:SetWidth(420) -- Keeps it from running off the side
legendNote:SetText(L["CONS_TIMING_NOTE"])
-------------------------------------------------------------------------------
-- Register with WoW Settings UI
-------------------------------------------------------------------------------
local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)

SLASH_TANKBUFFREMINDER1 = "/tbr"
SlashCmdList["TANKBUFFREMINDER"] = function()
    Settings.OpenToCategory(category:GetID())
end