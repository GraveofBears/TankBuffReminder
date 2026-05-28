local L = TBR_L
-------------------------------------------------------------------------------
-- Boss Level Presets
-------------------------------------------------------------------------------
local TARGET_LEVELS = {
    { level = 70, label = L["Level 70 (Heroic — Easy)"] or "Level 70 (Heroic — Easy)", critReq = 5.0, capSkill = 440, levelDiff = 0 },
    { level = 71, label = L["Level 71 (Heroic — Mid)"] or "Level 71 (Heroic — Mid)", critReq = 5.2, capSkill = 455, levelDiff = 1 },
    { level = 72, label = L["Level 72 (Heroic — Hard)"] or "Level 72 (Heroic — Hard)", critReq = 5.4, capSkill = 470, levelDiff = 2 },
    { level = 73, label = L["Level 73 (Raid Boss — Default)"] or "Level 73 (Raid Boss — Default)", critReq = 5.6, capSkill = 490, levelDiff = 3 },
}
local DEFAULT_TARGET_IDX = 4

-- MOVED UP HERE: Forward declarations + cache variables so the whole file can see them
local PopulateChart, UpdateStats, statsPanel, SetStatsPanelOpen
local lastClass = nil
local lastSkill = 0
local lastTotalRows = 0
local lastPresetIdx = 0

local function GetTargetPreset()
    local idx = (TankBuffReminderCharDB and TankBuffReminderCharDB.defCapTargetLevel) or DEFAULT_TARGET_IDX
    return TARGET_LEVELS[idx] or TARGET_LEVELS[DEFAULT_TARGET_IDX]
end

-------------------------------------------------------------------------------
-- Chart Data
-------------------------------------------------------------------------------
local CLASS_BASE = {
    DRUID = { label = "Druid |cff999999(Survival of the Fittest)|r", classColor = { r = 1.0, g = 0.49, b = 0.04 }, talentReduction = 3.0 },
    WARRIOR = { label = "Warrior", classColor = { r = 0.78, g = 0.61, b = 0.43 }, talentReduction = 0 },
    PALADIN = { label = "Paladin", classColor = { r = 0.96, g = 0.55, b = 0.73 }, talentReduction = 0 },
}

local CHARTS = {}

local function RebuildCharts()
    local preset = GetTargetPreset()
    for class, base in pairs(CLASS_BASE) do
        CHARTS[class] = {
            label = L[base.label] or base.label,
            capSkill = preset.capSkill,
            targetCritRed = preset.critReq,
            classColor = base.classColor,
            talentReduction = base.talentReduction,
            rows = nil,
            rowsBuilt = false,
        }
    end
end

RebuildCharts() -- initialise

-- Chart Building Functions (must be before SetTargetPreset)
local function BuildChart(capSkill, targetCritRed)
    local rows = {}
    for skill = 350, capSkill do
        local delta = skill - 350
        local ratingNeeded = math.floor(delta * 2.368 + 0.5)
        local critFromSkill = delta * 0.04
        local missingCrit = math.max(0, targetCritRed - critFromSkill)
        local resilNeeded = math.ceil(missingCrit * 39.423)
        table.insert(rows, { skill, ratingNeeded, resilNeeded })
    end
    return rows
end

local function EnsureChartBuilt(class)
    local chart = CHARTS[class]
    if not chart or chart.rowsBuilt then return end
   
    local effectiveCritReq = chart.targetCritRed - (CLASS_BASE[class].talentReduction or 0)
    local classCap = math.ceil(effectiveCritReq / 0.04) + 350
    chart.rows = BuildChart(classCap, effectiveCritReq)
    chart.rowsBuilt = true
end

local function SetTargetPreset(idx)
    idx = math.max(1, math.min(#TARGET_LEVELS, idx))

    if TankBuffReminderCharDB then
        TankBuffReminderCharDB.defCapTargetLevel = idx
    end

    -- Hard reset caches
    lastClass = nil
    lastSkill = -1
    lastTotalRows = -1
    lastPresetIdx = -1

    RebuildCharts()

    local _, class = UnitClass("player")
    if CHARTS[class] then
        CHARTS[class].rowsBuilt = false
        CHARTS[class].rows = nil
    end

    EnsureChartBuilt(class)

    -- Use global reference as backup
    local capWindow = window or _G.TBR_DefCapWindow

    if capWindow then
        PopulateChart(true)
        if scrollBar then 
            scrollBar:SetValue(0) 
        end
    end

    if statsPanel and statsPanel:IsShown() then
        UpdateStats()
    end
end

-------------------------------------------------------------------------------
-- Scaling Helper
-------------------------------------------------------------------------------
local function GetDefCapScale()
    local scale = 1.55
    
    -- Use the value saved by the options slider
    if TankBuffReminderCharDB and TankBuffReminderCharDB.defCapScale then
        scale = TankBuffReminderCharDB.defCapScale
    end
    
    -- Respect the player's overall UI Scale setting
    return UIParent:GetEffectiveScale() * scale
end

-------------------------------------------------------------------------------
-- Layout constants
-------------------------------------------------------------------------------
local VISIBLE_ROWS   = 14
local ROW_HEIGHT     = 19
local WINDOW_W       = 340
local STATS_PANEL_W  = 220
local DROPDOWN_H     = 24   -- height reserved for the boss level dropdown
local calculatedChartH = 130 + DROPDOWN_H + (VISIBLE_ROWS * ROW_HEIGHT)
local minimumStatsH    = 410   -- exact: 58 top + 5 headers + 18 rows + 4 gaps
local WINDOW_H         = math.max(calculatedChartH, minimumStatsH)

local COL_SKILL  = 28
local COL_RATING = 138
local COL_RESIL  = 248

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------
local function GetCurrentDefenseSkill()
    if not UnitDefense then return 0 end
    local base, modifier = UnitDefense("player")
    return (base or 0) + (modifier or 0)
end

-------------------------------------------------------------------------------
-- Main Window
-------------------------------------------------------------------------------
local window = CreateFrame("Frame", "TBR_DefenseCapWindow", UIParent, "BackdropTemplate")
_G.TBR_DefCapWindow = window
window:SetSize(WINDOW_W, WINDOW_H)
window:SetPoint("CENTER")
window:SetMovable(true)
window:EnableMouse(true)
window:SetClampedToScreen(true)
window:RegisterForDrag("LeftButton")
window:SetScript("OnDragStart", window.StartMoving)
window:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    if TankBuffReminderCharDB then
        TankBuffReminderCharDB.defCapWinPos = { point = point, relPoint = relPoint, x = x, y = y }
    end
end)
window:SetFrameStrata("DIALOG")
window:SetFrameLevel(10)
window:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
window:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
window:SetBackdropBorderColor(0.6, 0.5, 0.2, 1)
window:Hide()

local headerIcon = window:CreateTexture(nil, "ARTWORK")
headerIcon:SetSize(28, 28)
headerIcon:SetPoint("TOPLEFT", 18, -14)
headerIcon:SetTexture("Interface\\Icons\\INV_Shield_06")
headerIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local titleText = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOPLEFT", 52, -16)
titleText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

local subtitleText = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
subtitleText:SetPoint("TOPLEFT", 52, -32)
subtitleText:SetTextColor(0.6, 0.6, 0.6)

-- Forward declaration of SetStatsPanelOpen so hooks can access it early
local SetStatsPanelOpen

local topDivider = window:CreateTexture(nil, "ARTWORK")
topDivider:SetHeight(2)
topDivider:SetPoint("TOPLEFT", 18, -50)
topDivider:SetPoint("TOPRIGHT", -18, -50)
topDivider:SetTexture("Interface\\Buttons\\WHITE8X8")

-------------------------------------------------------------------------------
-- Boss Level Dropdown
-------------------------------------------------------------------------------
local dropdownLabel = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dropdownLabel:SetPoint("TOPLEFT", 18, -58)
dropdownLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
dropdownLabel:SetTextColor(0.6, 0.6, 0.6)
dropdownLabel:SetText(L["Target Boss Level:"] or "Target Boss Level:")

local bossDropdown = CreateFrame("Frame", "TBR_BossLevelDropdown", window, "UIDropDownMenuTemplate")
bossDropdown:SetPoint("TOPLEFT", 100, -48)
UIDropDownMenu_SetWidth(bossDropdown, 190)
bossDropdown:SetFrameLevel(window:GetFrameLevel() + 5)

-- Color the dropdown text to match user-selected color
local function ColorBossDropdown()
    local db = TankBuffReminderCharDB
    local defaults = TankBuffReminderConfig and TankBuffReminderConfig.defaults
    local c = db and db.defCapColor or (defaults and defaults.defCapColor) or {r = 0.85, g = 0.75, b = 0.3}
    
    local text = _G[bossDropdown:GetName() .. "Text"]
    if text then
        text:SetTextColor(c.r, c.g, c.b)
    end
end

local function BossDropdown_Initialize(self, level)
    local currentIdx = (TankBuffReminderCharDB and TankBuffReminderCharDB.defCapTargetLevel) or DEFAULT_TARGET_IDX
    for i, preset in ipairs(TARGET_LEVELS) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = preset.label
        info.value = i
        info.checked = (i == currentIdx) and true or false
        
        -- ADD THIS LINE TO REMOVE THE PIXEL GAP AND ALIGN ALL TEXT TO THE LEFT:
        info.notCheckable = true

        info.func = function(btn)
            UIDropDownMenu_SetSelectedValue(bossDropdown, btn.value)
            UIDropDownMenu_SetText(bossDropdown, TARGET_LEVELS[btn.value].label)
            SetTargetPreset(btn.value)
            ColorBossDropdown()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

UIDropDownMenu_Initialize(bossDropdown, BossDropdown_Initialize)

local function RefreshBossDropdown()
    local idx = (TankBuffReminderCharDB and TankBuffReminderCharDB.defCapTargetLevel) or DEFAULT_TARGET_IDX
    UIDropDownMenu_SetSelectedValue(bossDropdown, idx)
    UIDropDownMenu_SetText(bossDropdown, TARGET_LEVELS[idx].label)
    ColorBossDropdown()
end

local headerY = -82   -- pushed down to clear the dropdown row

local TBR_CapHeaders = {}

local colDivider = window:CreateTexture(nil, "ARTWORK")
colDivider:SetHeight(1)
colDivider:SetPoint("TOPLEFT", 18, headerY - 14)
colDivider:SetPoint("TOPRIGHT", -18, headerY - 14)
colDivider:SetTexture("Interface\\Buttons\\WHITE8X8")

-- Forward declaration of SetStatsPanelOpen so hooks can access it early
local SetStatsPanelOpen

local closeBtn = CreateFrame("Button", nil, window, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -4, -4)
closeBtn:SetScript("OnClick", function() 
    window:Hide() 
    SetStatsPanelOpen(false) -- Ensure stats close when standard "X" button is clicked
end)

local function MakeColHeader(text, x)
    local fs = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", x, headerY)
    fs:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    fs:SetText(text)
    fs:SetTextColor(0.85, 0.75, 0.3)
    table.insert(TBR_CapHeaders, fs) 
end

MakeColHeader(L["Defense Skill"], COL_SKILL)
MakeColHeader(L["Rating Needed"], COL_RATING)
MakeColHeader(L["Resil Needed"],  COL_RESIL)

local scrollFrame = CreateFrame("ScrollFrame", "TBR_DefCapScroll", window)
scrollFrame:SetPoint("TOPLEFT", 18, headerY - 18)
scrollFrame:SetPoint("BOTTOMRIGHT", -28, 14)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(WINDOW_W - 46, 1)
scrollFrame:SetScrollChild(scrollChild)

local scrollBar = CreateFrame("Slider", "TBR_DefCapScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
scrollBar:SetPoint("TOPRIGHT",    scrollFrame, "TOPRIGHT",    18, -16)
scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 18,  16)
scrollBar:SetMinMaxValues(0, 0)
scrollBar:SetValueStep(ROW_HEIGHT)
scrollBar:SetValue(0)
scrollBar:SetScript("OnValueChanged", function(self, val)
    scrollFrame:SetVerticalScroll(val)
end)

scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    if not window:IsShown() then return end
    local cur = scrollBar:GetValue()
    local min, max = scrollBar:GetMinMaxValues()
    scrollBar:SetValue(math.min(max, math.max(min, cur - delta * ROW_HEIGHT * 3)))
end)

-------------------------------------------------------------------------------
-- Row Pool with bounded growth + Dynamic Font Size
-------------------------------------------------------------------------------
local rowPool = {}

local function GetDefCapFontSize()
    if TankBuffReminderCharDB and TankBuffReminderCharDB.defCapFontSize then
        return TankBuffReminderCharDB.defCapFontSize
    end
    return 13  -- default
end

local function GetOrCreateRow(i)
    if rowPool[i] then return rowPool[i] end

    local row = {
        bg     = scrollChild:CreateTexture(nil, "BACKGROUND"),
        accent = scrollChild:CreateTexture(nil, "BORDER"),
        skill  = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"),
        rating = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"),
        resil  = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"),
    }
    row.bg:SetSize(WINDOW_W - 46, ROW_HEIGHT)
    row.accent:SetSize(3, ROW_HEIGHT - 2)

    local fontSize = GetDefCapFontSize()

    for _, fs in pairs({ row.skill, row.rating, row.resil }) do
        fs:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "")
        fs:SetSize(90, ROW_HEIGHT)
        fs:SetJustifyH("LEFT")
    end

    rowPool[i] = row
    return row
end

-------------------------------------------------------------------------------
-- Optimized PopulateChart (with debug)
-------------------------------------------------------------------------------
PopulateChart = function(force)
    if not window or not window:IsShown() then
        return
    end
  
    local _, class = UnitClass("player")
    local chart = CHARTS[class]
   
    -- FORCE REBUILD: either explicit force OR we changed preset while window was closed
    if force or lastPresetIdx == -1 then
        lastClass = nil
        lastPresetIdx = -1
        lastTotalRows = -1
       
        if chart then
            chart.rowsBuilt = false
            chart.rows = nil
        end
        EnsureChartBuilt(class)
        chart = CHARTS[class]
    end
  
    if not chart or not chart.rowsBuilt then
        EnsureChartBuilt(class)
        chart = CHARTS[class]
    end
  
    if not chart or not chart.rows then
        return
    end

    local currentSkill = GetCurrentDefenseSkill()
    local total = #chart.rows
    local currentPresetIdx = (TankBuffReminderCharDB and TankBuffReminderCharDB.defCapTargetLevel) or DEFAULT_TARGET_IDX

    -- Skip optimization only if nothing changed
    if not force
       and lastPresetIdx ~= -1                    -- <-- important safety
       and class == lastClass
       and currentSkill == lastSkill
       and total == lastTotalRows
       and currentPresetIdx == lastPresetIdx then
        return
    end

    -- Update cache
    lastClass = class
    lastSkill = currentSkill
    lastTotalRows = total
    lastPresetIdx = currentPresetIdx

    local cc = chart.classColor
    local fontSize = GetDefCapFontSize()

    scrollChild:SetHeight(total * ROW_HEIGHT)
    local maxScroll = math.max(0, total * ROW_HEIGHT - scrollFrame:GetHeight())
    scrollBar:SetMinMaxValues(0, maxScroll)
   
    if force or lastPresetIdx == -1 then
        scrollBar:SetValue(0)
    end

    -- [Rest of your loop stays 100% the same]
    for i = 1, total do
        local data = chart.rows[i]
        local skill, rating, resil = data[1], data[2], data[3]
        local row = GetOrCreateRow(i)
        local yPos = -(i - 1) * ROW_HEIGHT
        local isCurrent = (skill == currentSkill)

        row.bg:ClearAllPoints()
        row.bg:SetPoint("TOPLEFT", 0, yPos)
        row.accent:ClearAllPoints()
        row.accent:SetPoint("TOPLEFT", 0, yPos - 1)

        if isCurrent then
            row.bg:SetColorTexture(0.08, 0.18, 0.32, 0.85)
            row.accent:SetColorTexture(cc.r, cc.g, cc.b, 1)
        elseif i % 2 == 0 then
            row.bg:SetColorTexture(0.08, 0.08, 0.1, 0.5)
            row.accent:SetColorTexture(0, 0, 0, 0)
        else
            row.bg:SetColorTexture(0.04, 0.04, 0.06, 0.3)
            row.accent:SetColorTexture(0, 0, 0, 0)
        end

        local colorR, colorG, colorB = 0.65, 0.65, 0.65
        local fontFlag = ""
        if isCurrent then
            colorR, colorG, colorB = cc.r, cc.g, cc.b
            fontFlag = "OUTLINE"
        end

        row.skill:ClearAllPoints()
        row.skill:SetPoint("TOPLEFT", COL_SKILL - 14, yPos)
        row.skill:SetText(skill)
        row.skill:SetTextColor(colorR, colorG, colorB)
        row.skill:SetFont("Fonts\\FRIZQT__.TTF", fontSize, fontFlag)

        row.rating:ClearAllPoints()
        row.rating:SetPoint("TOPLEFT", COL_RATING - 14, yPos)
        row.rating:SetText(rating == 0 and "—" or rating)
        row.rating:SetTextColor(colorR, colorG, colorB)
        row.rating:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "")

        row.resil:ClearAllPoints()
        row.resil:SetPoint("TOPLEFT", COL_RESIL - 14, yPos)
        row.resil:SetText(resil == 0 and "—" or resil)
        row.resil:SetTextColor(colorR, colorG, colorB)
        row.resil:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "")

        row.bg:Show()
        row.accent:Show()
        row.skill:Show()
        row.rating:Show()
        row.resil:Show()
    end

    -- Hide extra rows
    for i = total + 1, #rowPool do
        local r = rowPool[i]
        if r then
            r.bg:Hide()
            r.accent:Hide()
            r.skill:Hide()
            r.rating:Hide()
            r.resil:Hide()
        end
    end
end

-------------------------------------------------------------------------------
-- Stats Panel (collapsible, anchored to right of main window)
-------------------------------------------------------------------------------

-- TBC level-73 boss armor constant for damage reduction math
local BOSS_ARMOR_CONST = 10557.5

-- Combat rating constants
local CR_DEFENSE_SKILL         = 2   
local CR_DODGE                 = 3   
local CR_PARRY                 = 4   
local CR_BLOCK                 = 5   
local CR_HIT_MELEE             = 6   
local CR_RESILIENCE_TAKEN_CRIT = 15  

statsPanel = CreateFrame("Frame", "TBR_StatsPanel", window, "BackdropTemplate")
statsPanel:SetSize(STATS_PANEL_W, WINDOW_H)
statsPanel:SetFrameStrata("DIALOG")
statsPanel:SetFrameLevel(10)
statsPanel:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
statsPanel:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
statsPanel:SetBackdropBorderColor(0.6, 0.5, 0.2, 1)
statsPanel:Hide()

-- Graphical Arrow Button setup to replace missing text glyph box
local toggleBtn = CreateFrame("Button", nil, window)
toggleBtn:SetSize(16, 32)
toggleBtn:SetPoint("RIGHT", window, "RIGHT", 5, 0)
toggleBtn:SetFrameStrata("DIALOG")
toggleBtn:SetFrameLevel(20)

local toggleTex = toggleBtn:CreateTexture(nil, "ARTWORK")
toggleTex:SetAllPoints()
toggleBtn.texture = toggleTex

toggleBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["Tank Stats"], 1, 1, 1)
    GameTooltip:AddLine(L["Click to toggle stats panel."], 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
toggleBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Helper: make a stat row (label + value FontStrings) inside statsPanel
local statRows = {}
local function MakeStatRow(key, labelText, yOffset)
    local lbl = statsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", 16, yOffset)
    lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    lbl:SetText(labelText)
    lbl:SetTextColor(0.7, 0.7, 0.7)
    lbl:SetJustifyH("LEFT")
    lbl:SetWidth(120)

    local val = statsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    val:SetPoint("TOPLEFT", 140, yOffset)
    val:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    val:SetJustifyH("LEFT")
    val:SetWidth(70)

    statRows[key] = { lbl = lbl, val = val }
    return val
end

-- Tracking table for dynamically coloring header highlight strips
local TBR_StatsHeaders = {}

local function MakeSectionHeader(text, yOffset)
    -- Colored full-width backdrop strip block to replace problematic thin line dividers
    local bg = statsPanel:CreateTexture(nil, "BACKGROUND")
    bg:SetHeight(16)
    bg:SetPoint("TOPLEFT", 12, yOffset + 2)
    bg:SetPoint("TOPRIGHT", -12, yOffset + 2)
    bg:SetColorTexture(0.85, 0.75, 0.3, 0.08) -- 8% visibility default gold tone
    
    local fs = statsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", 16, yOffset - 1)
    fs:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    fs:SetText(text)
    fs:SetTextColor(0.85, 0.75, 0.3)
    fs:SetJustifyH("LEFT")

    table.insert(TBR_StatsHeaders, { text = fs, strip = bg })
    return fs, bg
end

-- Layout — build rows top to bottom
local statsPanelTitle = statsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
statsPanelTitle:SetPoint("TOPLEFT", 14, -14)
statsPanelTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
statsPanelTitle:SetText(L["Tank Stats"])

local statsPanelDivider = statsPanel:CreateTexture(nil, "ARTWORK")
statsPanelDivider:SetHeight(2)
statsPanelDivider:SetPoint("TOPLEFT", 14, -32)
statsPanelDivider:SetPoint("TOPRIGHT", -14, -32)
statsPanelDivider:SetTexture("Interface\\Buttons\\WHITE8X8")
statsPanelDivider:SetVertexColor(0.85, 0.75, 0.3, 0.6)

-- Create the new text element right below the title divider line
local critStatusHeaderLabel = statsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
critStatusHeaderLabel:SetPoint("TOPLEFT", 14, -40)
critStatusHeaderLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
critStatusHeaderLabel:SetText("")

-- Push y further down from -44 to -62 to make space for the new label line
local y = -58

-- Avoidance Section
MakeSectionHeader(L["Avoidance"], y)
y = y - 16
MakeStatRow("dodge",   L["Dodge"],          y)
y = y - 14
MakeStatRow("parry",   L["Parry"],          y)
y = y - 14
MakeStatRow("block",   L["Block"],          y)
y = y - 14
MakeStatRow("miss",    L["Miss"],           y)
y = y - 14
MakeStatRow("avoid",   L["Total Avoid"],    y)
y = y - 18

-- Defense Section
MakeSectionHeader(L["Defense"], y)
y = y - 16
MakeStatRow("defSkill",  L["Def Skill"],    y)
y = y - 14
MakeStatRow("defRating", L["Def Rating"],   y)
y = y - 14
MakeStatRow("critImmune",L["Crit Immune"],  y)
y = y - 18

-- Survivability Section
MakeSectionHeader(L["Survivability"], y)
y = y - 16
MakeStatRow("hp",        L["Health"],       y)
y = y - 14
MakeStatRow("armor",     L["Armor"],        y)
y = y - 14
MakeStatRow("dmgReduce", L["Dmg Reduction"],y)
y = y - 14
MakeStatRow("resil",     L["Resilience"],   y)
y = y - 14
MakeStatRow("ehp",       L["EHP"],          y)
y = y - 18

-- Offense Section
MakeSectionHeader(L["Offense"], y)
y = y - 16
MakeStatRow("ap",        L["Attack Power"],  y)
y = y - 14
MakeStatRow("hit",       L["Hit"],           y)
y = y - 14
MakeStatRow("expertise", L["Expertise"],     y)
y = y - 14
MakeStatRow("crit",      L["Crit Chance"],   y)
y = y - 18

-- TPS Section
MakeSectionHeader(L["TPS Estimate"], y)
y = y - 16
MakeStatRow("tpsTotal",  L["Est. TPS"],      y)

-- Stat calculation
local function fmt1(n) return string.format("%.2f%%", n) end
local function fmtInt(n) return string.format("%d", n) end

local function SetStat(key, text, r, g, b)
    local row = statRows[key]
    if not row then return end
    row.val:SetText(text)
    row.val:SetTextColor(r or 0.9, g or 0.9, b or 0.9)
end

local function ShowStatRow(key)
    local row = statRows[key]
    if not row then return end
    row.lbl:Show()
    row.val:Show()
end

UpdateStats = function()
    -- Allow calculation if the frame is actively visible on screen
    if not statsPanel or not statsPanel:IsShown() then return end

    local _, class = UnitClass("player")
    local cc = (CHARTS[class] and CHARTS[class].classColor) or { r = 0.9, g = 0.9, b = 0.9 }
    local r, g, b = cc.r, cc.g, cc.b

    local preset = GetTargetPreset()

    ---------------------------------------------------------------------------
    -- Defense
    ---------------------------------------------------------------------------
    local defSkill = GetCurrentDefenseSkill()
    local defRating = (GetCombatRating and GetCombatRating(CR_DEFENSE_SKILL)) or 0
    SetStat("defSkill",  fmtInt(defSkill),  r, g, b)
    SetStat("defRating", fmtInt(defRating), r, g, b)

    ---------------------------------------------------------------------------
    -- Crit Immunity Check  (uses active preset's critReq)
    ---------------------------------------------------------------------------
    local lvl = UnitLevel("player")
    local baseSkill = lvl * 5
    local critFromSkill = math.max(0, defSkill - baseSkill) * 0.04

    local critFromResil = 0
    if GetCombatRatingBonus then
        critFromResil = GetCombatRatingBonus(CR_RESILIENCE_TAKEN_CRIT) or 0
    end

    local talentReduction = 0
    if class == "DRUID" then
        local shapeshift = GetShapeshiftFormID()
        if shapeshift == 5 or shapeshift == 8 or UnitPowerType("player") == 1 then
            talentReduction = 3.0
        end
    end

    local BOSS_BASE_CRIT = preset.critReq
    local totalCritRed = critFromSkill + critFromResil + talentReduction
    local margin = totalCritRed - BOSS_BASE_CRIT
    local immune = totalCritRed >= BOSS_BASE_CRIT

    if immune then
        SetStat("critImmune", string.format("+%.2f%%", math.abs(margin)), 0.2, 1, 0.2)
        critStatusHeaderLabel:SetText("|cff00ff00Uncritable|r")
    else
        SetStat("critImmune", string.format("-%.2f%%", math.abs(margin)), 1, 0.3, 0.3)
        critStatusHeaderLabel:SetText("|cffff3333Critable|r")
    end

    ---------------------------------------------------------------------------
    -- Avoidance  (uses active preset's boss level)
    ---------------------------------------------------------------------------
    local dodge = GetDodgeChance() or 0

    local bossLevel      = 70 + preset.levelDiff
    local bossAttackRating = bossLevel * 5
    -- Miss = 5.0% base, −0.2% per level above player (floored at 0)
    local baseMiss = math.max(0, 5.0 - (preset.levelDiff * 0.2))
    local extraMiss = 0
    if defSkill > bossAttackRating then
        extraMiss = (defSkill - bossAttackRating) * 0.04
    else
        extraMiss = (defSkill - bossAttackRating) * 0.02
    end
    local miss  = math.max(0, baseMiss + extraMiss)
    local parry = GetParryChance() or 0
    local block = GetBlockChance() or 0

    SetStat("dodge", fmt1(dodge), r, g, b)
    SetStat("parry", fmt1(parry), r, g, b)
    SetStat("block", fmt1(block), r, g, b)
    SetStat("miss",  fmt1(miss),  r, g, b)

    ShowStatRow("parry")
    ShowStatRow("block")

    local totalAvoid = dodge + miss + parry + block
    if class ~= "DRUID" and totalAvoid >= 102.4 then
        SetStat("avoid", fmt1(totalAvoid), 0.2, 1, 0.2)
    else
        SetStat("avoid", fmt1(totalAvoid), r, g, b)
    end

---------------------------------------------------------------------------
    -- Offense
    ---------------------------------------------------------------------------
    local baseAP, posAP, negAP = UnitAttackPower("player")
    local totalAP = (baseAP or 0) + (posAP or 0) + (negAP or 0)
    local hitBonus = GetCombatRatingBonus and GetCombatRatingBonus(CR_HIT_MELEE) or 0
    local expPct   = GetExpertisePercent and GetExpertisePercent() or 0
    local critPct  = GetCritChance and GetCritChance() or 0

    local hitCapped = hitBonus >= 9.0
    local expCapped = expPct   >= 6.5
    local hitColor  = hitCapped and "|cff00ff00" or "|cffff4444"
    local expColor  = expCapped and "|cff00ff00" or "|cffff4444"

    SetStat("ap",        fmtInt(totalAP),                                        r, g, b)
    SetStat("hit",       hitColor .. string.format("%.2f%%", hitBonus) .. "|r",  r, g, b)
    SetStat("expertise", expColor .. string.format("%.2f%%", expPct)   .. "|r",  r, g, b)
    SetStat("crit",      string.format("%.2f%%", critPct),                       r, g, b)

    ---------------------------------------------------------------------------
    -- Survivability
    ---------------------------------------------------------------------------
    local hp = UnitHealthMax and UnitHealthMax("player") or 0
    local _, effArmor = UnitArmor("player")
    if not effArmor or effArmor == 0 then
        local a, b2 = UnitArmor("player")
        effArmor = b2 or a or 0
    end
    local armorConst = (GetBossArmorConstant and GetBossArmorConstant()) or BOSS_ARMOR_CONST
    local dmgReduce  = effArmor / (effArmor + armorConst)
    local ehp        = math.floor(hp / (1 - dmgReduce))
    local resilRating = (GetCombatRating and GetCombatRating(CR_RESILIENCE_TAKEN_CRIT)) or 0

    SetStat("hp",        fmtInt(hp),            r, g, b)
    SetStat("armor",     fmtInt(effArmor),      r, g, b)
    SetStat("dmgReduce", fmt1(dmgReduce * 100), r, g, b)
    SetStat("resil",     fmtInt(resilRating),   r, g, b)
    SetStat("ehp",       fmtInt(ehp),           r, g, b)

    ---------------------------------------------------------------------------
    -- TPS Estimate
    ---------------------------------------------------------------------------
    do
        local hitFactor = math.min(1.0, 0.91 + hitBonus * 0.01)

        if class == "DRUID" then
            local formID = GetShapeshiftFormID and GetShapeshiftFormID() or 0
            
            -- Setup baseline variables to shift dynamically based on active form
            local speedMultiplier = 2.0  -- Caster / Moonkin default
            local damageModifier  = 1.0  -- Caster / Moonkin default
            local threatModifier  = 1.0  -- Caster / Moonkin default
            local abilityBias     = 1.0  -- Caster / Moonkin default
            local critMultiplier  = 1.0  -- Standard physical crit modifier

            if formID == 5 or formID == 8 then
                -- BEAR FORM (Dire Bear / Normal Bear)
                speedMultiplier = 2.5   -- Base swing speed
                damageModifier  = 1.9   -- 190% damage modifier in Dire Bear
                threatModifier  = 1.30 * 1.15 -- 1.3 Stance mod * 1.15 Feral Instinct talent
                abilityBias     = 1.3   -- Maul/Mangle active use bias
                critMultiplier  = 1.0   -- Double damage + Primal Fury generation
            elseif formID == 3 then
                -- CAT FORM
                speedMultiplier = 1.0   -- Fast 1.0 base swing speed
                damageModifier  = 1.0   -- No raw damage multiplier
                threatModifier  = 0.71  -- Passive 29% threat REDUCTION inherent to Cat form
                abilityBias     = 1.15  -- Claw/Shred/Mangle use bias
                critMultiplier  = 1.0   -- Cat crits do 200% damage
            elseif formID == 31 then
                -- MOONKIN FORM
                speedMultiplier = 2.0
                damageModifier  = 1.0
                threatModifier  = 1.0
                abilityBias     = 0.9   -- Spellcasting delay bias for standard tracking
                critMultiplier  = 0.5   -- Spell crits do 150% damage baseline in TBC
            end

            -- Execute the structural math adjusted for the active form's profile
            local whiteDps  = totalAP / 14 * speedMultiplier
            local critBonus = 1 + ((critPct / 100) * critMultiplier)
            local estimated = whiteDps * damageModifier * abilityBias * hitFactor * threatModifier * critBonus

            local formNote = ""
            if formID ~= 5 and formID ~= 8 then
                if formID == 3 then
                    formNote = " |cff888888(cat)|r"
                elseif formID == 31 then
                    formNote = " |cff888888(moonkin)|r"
                else
                    formNote = " |cff888888(no form)|r"
                end
            end
            SetStat("tpsTotal", "|cffffd100" .. fmtInt(estimated) .. " TPS|r" .. formNote, r, g, b)

        elseif class == "WARRIOR" then
            local whiteDps  = totalAP / 14 * 1.6
            local critBonus = 1 + (critPct / 100) * 0.5
            local estimated = whiteDps * 2.4 * hitFactor * critBonus
            SetStat("tpsTotal", "|cffffd100" .. fmtInt(estimated) .. " TPS|r", r, g, b)

		elseif class == "PALADIN" then
            -- Pull live Holy spell power and block value from the character sheet
            local spellPower = GetSpellBonusDamage(2) or 0 -- 2 is the Holy school ID
            local blockValue = GetShieldBlockValue() or 0

            -- TBC Paladin rotation baseline threat:
            -- Consecration, Holy Shield, and Seal/Judgement of Righteousness
            local baseHolyDps   = 60 + (spellPower * 0.12) -- Consecration ticks + Seal scaling
            local holyShieldDps = (155 + (blockValue + spellPower * 0.05)) * 0.4 -- Assumes standard boss hit rate
            
            -- Righteous Fury talented multiplies Holy threat by 1.9x
            local totalHolyThreat = (baseHolyDps + holyShieldDps) * 1.9
            
            -- Add a minor physical baseline (Righteous swings) factored by hit
            local physicalThreat  = (totalAP / 14 * 1.6) * hitFactor 
            local estimated       = totalHolyThreat + physicalThreat

            SetStat("tpsTotal", "|cffffd100" .. fmtInt(estimated) .. " TPS|r", r, g, b)

        else
            SetStat("tpsTotal", "|cff888888—|r", 0.5, 0.5, 0.5)
        end
    end

    statsPanelTitle:SetTextColor(r, g, b)
    statsPanelDivider:SetVertexColor(r, g, b, 0.6)
end

-- Stats panel event handling — only active while panel is shown
local statsEventFrame = CreateFrame("Frame")
local STATS_EVENTS = {
    "UNIT_STATS", "UNIT_RESISTANCES", "UNIT_AURA",
    "PLAYER_EQUIPMENT_CHANGED", "UPDATE_SHAPESHIFT_FORM",
    "COMBAT_RATING_UPDATE", "PLAYER_DAMAGE_DONE_MODS"
}

local function RegisterStatsEvents()
    for _, ev in ipairs(STATS_EVENTS) do
        statsEventFrame:RegisterEvent(ev)
    end
end

local function UnregisterStatsEvents()
    for _, ev in ipairs(STATS_EVENTS) do
        statsEventFrame:UnregisterEvent(ev)
    end
end

statsEventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "UNIT_STATS" or event == "UNIT_RESISTANCES" or event == "UNIT_AURA" then
        if arg1 ~= "player" then return end
    end
    UpdateStats()
end)

-- Position stats panel flush against the right edge of the main window
local function PositionStatsPanel()
    statsPanel:ClearAllPoints()
    statsPanel:SetPoint("TOPLEFT", window, "TOPRIGHT", -6, 0)
end

-- Toggle the stats panel open/closed
local statsPanelOpen = false

function SetStatsPanelOpen(open)
    statsPanelOpen = open
    if open then
        PositionStatsPanel()
        statsPanel:Show()
        toggleBtn.texture:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up") -- Points Left 
        RegisterStatsEvents()
        UpdateStats()
    else
        statsPanel:Hide()
        toggleBtn.texture:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up") -- Points Right
        UnregisterStatsEvents()
    end
    
    if TankBuffReminderCharDB then
        TankBuffReminderCharDB.defCapStatsOpen = false
    end
end

-- Hook the main window close logic safely NOW that SetStatsPanelOpen is defined
window:SetScript("OnHide", function()
    SetStatsPanelOpen(false)
end)

toggleBtn:SetScript("OnClick", function()
    SetStatsPanelOpen(not statsPanelOpen)
end)

-- Public: re-apply color to stats panel (called by TBR_DefenseCap_UpdateColor)
function TBR_StatsPanel_UpdateColor(c)
    if not c or not statsPanel then return end
    
    -- Stats Panel Border
    statsPanel:SetBackdropBorderColor(c.r, c.g, c.b, (c.a and c.a > 0) and c.a or 1)
    
    -- Divider
    if statsPanelDivider then
        statsPanelDivider:SetVertexColor(c.r, c.g, c.b, 0.6)
    end
    
    -- Toggle Button Arrow
    if toggleBtn and toggleBtn.texture then
        toggleBtn.texture:SetVertexColor(c.r, c.g, c.b)
    end
    
    -- Section Headers (text + colored strips)
    if TBR_StatsHeaders then
        for _, item in ipairs(TBR_StatsHeaders) do
            if item.text then
                item.text:SetTextColor(c.r, c.g, c.b)
            end
            if item.strip then
                item.strip:SetVertexColor(c.r, c.g, c.b, 0.08)
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------
window:RegisterEvent("UNIT_RESISTANCES")
window:SetScript("OnEvent", function(self, event, unit)
    if unit == "player" and self:IsShown() then
        PopulateChart()
    end
end)

-------------------------------------------------------------------------------
-- Toggle + Public API
-------------------------------------------------------------------------------
function TBR_DefenseCap_Toggle()
    if window:IsShown() then
        window:Hide()
        SetStatsPanelOpen(false) -- Ensure both segments hide together
        return
    end

    local _, class = UnitClass("player")
    local chart = CHARTS[class]
    if not chart then return end

    EnsureChartBuilt(class)

    local cc = chart.classColor
    titleText:SetText(string.format("|cff%02x%02x%02x" .. L["Defense Cap Reference"] .. "|r", 
        cc.r * 255, cc.g * 255, cc.b * 255))
    subtitleText:SetText(chart.label)

    window:SetScale(GetDefCapScale())
    RefreshBossDropdown()
    window:Show()
    PopulateChart(true)
	scrollBar:SetValue(0)

    -- ALWAYS default the stats panel to closed whenever the main window is opened
    statsPanelOpen = false
    statsPanel:Hide()
    UnregisterStatsEvents()
    toggleBtn.texture:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up") -- Reset arrow to point Right
    
    if TankBuffReminderCharDB then
        TankBuffReminderCharDB.defCapStatsOpen = false
    end
end

---------------------------------------------------------
-- Minimalist Shield Icon Button
---------------------------------------------------------
local charBtn = CreateFrame("Button", "TBR_CharFrameDefCapButton", PaperDollFrame)
charBtn:SetSize(24, 24)
charBtn:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", 18, -18)

charBtn:SetFrameStrata("DIALOG")
charBtn:SetFrameLevel(100)

local charBtnIcon = charBtn:CreateTexture(nil, "ARTWORK")
charBtnIcon:SetAllPoints()
charBtnIcon:SetTexture("Interface\\Icons\\INV_Shield_06")
charBtnIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local charBtnBorder = charBtn:CreateTexture(nil, "OVERLAY")
charBtnBorder:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
charBtnBorder:SetAllPoints()

local statusIndicator = charBtn:CreateTexture(nil, "OVERLAY")
statusIndicator:SetSize(16, 16)
statusIndicator:SetPoint("TOPRIGHT", charBtn, "TOPRIGHT", 2, 2)
statusIndicator:Hide()

charBtn:SetMovable(true)
charBtn:SetClampedToScreen(true)

charBtn:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and IsShiftKeyDown() then
        self:StartMoving()
        self.isMoving = true
    end
end)

charBtn:SetScript("OnMouseUp", function(self, button)
    if self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
        local point, _, relPoint, x, y = self:GetPoint()
        if TankBuffReminderCharDB then
            TankBuffReminderCharDB.defCapBtnPos = { point = point, relPoint = relPoint, x = x, y = y }
        end
    end
end)

charBtn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" and not IsShiftKeyDown() then
        TBR_DefenseCap_Toggle()
    end
end)

charBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["Defense Cap Reference"], 1, 1, 1)
    GameTooltip:AddLine(L["Click to view crit-immunity chart."], 0.7, 0.7, 0.7)
    GameTooltip:AddLine(L["Shift+drag to move."], 0.6, 0.6, 0.6)
    GameTooltip:Show()
end)
charBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

function TBR_DefCapBtn_Refresh()
    local db = TankBuffReminderCharDB
    if not db then return end

    if db.defCapBtnShow == false then
        charBtn:Hide()
        return
    end

    charBtn:Show()
    charBtn:ClearAllPoints()

    if db.defCapBtnPos then
        local p = db.defCapBtnPos
        charBtn:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    else
        charBtn:SetPoint("BOTTOMLEFT", PaperDollFrame, "BOTTOMLEFT", 22, 84)
    end
end

local function UpdateCritStatusIndicator()
    if not charBtn or not charBtn:IsShown() then return end

    local _, class = UnitClass("player")
    local chart = CHARTS[class]
    if not chart then 
        statusIndicator:Hide()
        return 
    end

    local preset = GetTargetPreset()
    local defSkill = GetCurrentDefenseSkill()
    local baseSkill = UnitLevel("player") * 5
    local critFromSkill = math.max(0, (defSkill - baseSkill) * 0.04)

    local critFromResil = 0
    if GetCombatRatingBonus then
        critFromResil = GetCombatRatingBonus(CR_RESILIENCE_TAKEN_CRIT) or 0
    end

    local talentReduction = (class == "DRUID") and 3.0 or 0
    local totalCritRed = critFromSkill + critFromResil + talentReduction
    local isUncritable = totalCritRed >= preset.critReq

    if isUncritable then
        statusIndicator:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")  -- Green Check
        statusIndicator:SetVertexColor(0, 1, 0, 1)
    else
        statusIndicator:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady") -- Red X
        statusIndicator:SetVertexColor(1, 0.2, 0.2, 1)
    end

    statusIndicator:Show()
end

-- Update on relevant events
charBtn:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
charBtn:RegisterEvent("UNIT_STATS")
charBtn:RegisterEvent("UNIT_AURA")
charBtn:RegisterEvent("COMBAT_RATING_UPDATE")
charBtn:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_EQUIPMENT_CHANGED" or self:IsVisible() then
        UpdateCritStatusIndicator()
    end
end)

local posLoader = CreateFrame("Frame")
posLoader:RegisterEvent("PLAYER_LOGIN")
posLoader:SetScript("OnEvent", function()
    C_Timer.After(0.5, function()
        if TankBuffReminderCharDB and TankBuffReminderCharDB.defCapWinPos then
            local p = TankBuffReminderCharDB.defCapWinPos
            window:ClearAllPoints()
            window:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
        end
        TBR_DefCapBtn_Refresh()
		UpdateCritStatusIndicator()
        TBR_DefenseCap_UpdateColor()
        RebuildCharts()   -- apply any saved preset from DB
        RefreshBossDropdown()
    end)
end)

function TBR_DefenseCap_UpdateColor()
    if not TankBuffReminderCharDB then return end
   
    local db = TankBuffReminderCharDB
    local defaults = TankBuffReminderConfig and TankBuffReminderConfig.defaults
    local c = db.defCapColor or (defaults and defaults.defCapColor) or {r = 0.6, g = 0.5, b = 0.2, a = 1}

    -- Main Window Border
    if window then
        window:SetBackdropBorderColor(c.r, c.g, c.b, (c.a and c.a > 0) and c.a or 1)
    end

    -- Dividers
    if topDivider then
        topDivider:SetVertexColor(c.r, c.g, c.b, c.a or 1)
    end
    if colDivider then
        colDivider:SetVertexColor(c.r, c.g, c.b, 0.6)
    end

    -- Column Headers
    if TBR_CapHeaders then
        for _, header in ipairs(TBR_CapHeaders) do
            header:SetTextColor(c.r, c.g, c.b)
        end
    end

    -- Boss Level Dropdown Text
    if bossDropdown then
        local dropdownText = _G[bossDropdown:GetName() .. "Text"]
        if dropdownText then
            dropdownText:SetTextColor(c.r, c.g, c.b)
        end
    end

    -- Stats Panel colors
    TBR_StatsPanel_UpdateColor(c)
end

function TBR_DefenseCap_ApplyScale()
    if window and window:IsShown() then
        window:SetScale(GetDefCapScale())
    end
end

function TBR_DefenseCap_ForceRepopulate()
    lastClass = nil
    local fontSize = GetDefCapFontSize()

    -- 1. Update main chart row fonts
    for _, row in pairs(rowPool) do
        if row.skill then row.skill:SetFont("Fonts\\FRIZQT__.TTF", fontSize, row.skill == GetCurrentDefenseSkill() and "OUTLINE" or "") end
        if row.rating then row.rating:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "") end
        if row.resil then row.resil:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "") end
    end

    -- 2. Update slide-out panel header & row fonts
	if statsPanelTitle then
        statsPanelTitle:SetFont("Fonts\\FRIZQT__.TTF", fontSize + 1, "OUTLINE") -- slightly bigger title
    end
    if critStatusHeaderLabel then
        critStatusHeaderLabel:SetFont("Fonts\\FRIZQT__.TTF", fontSize + 1, "OUTLINE")
    end

    if TBR_StatsHeaders then
        for _, item in ipairs(TBR_StatsHeaders) do
            item.text:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
        end
    end

    if statRows then
        for _, row in pairs(statRows) do
            if row.lbl then row.lbl:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "") end
            if row.val then 
                -- Keep the outline styling on the values
                local _, _, flags = row.val:GetFont()
                row.val:SetFont("Fonts\\FRIZQT__.TTF", fontSize, flags or "OUTLINE") 
            end
        end
    end

    -- 3. Refresh display if visible
    if window and window:IsShown() then
        PopulateChart()
    end
end

local oldToggle = TBR_DefenseCap_Toggle
TBR_DefenseCap_Toggle = function()
    oldToggle()
    C_Timer.After(0.1, UpdateCritStatusIndicator)
end

SLASH_TBRCAP1 = "/tbrcap"
SlashCmdList["TBRCAP"] = TBR_DefenseCap_Toggle