-- DefenseCap.lua
local L = TBR_L

-------------------------------------------------------------------------------
-- Chart Data (lazy-built)
-------------------------------------------------------------------------------
local CHARTS = {
    DRUID = {
        label         = L["Druid |cff999999(Survival of the Fittest)|r"],
        capSkill      = 415,
        targetCritRed = 2.6,
        classColor    = { r = 1.0, g = 0.49, b = 0.04 },
        rows          = nil,
        rowsBuilt     = false,
    },
    WARRIOR = {
        label         = L["Warrior"],
        capSkill      = 490,
        targetCritRed = 5.6,
        classColor    = { r = 0.78, g = 0.61, b = 0.43 },
        rows          = nil,
        rowsBuilt     = false,
    },
    PALADIN = {
        label         = L["Paladin"],
        capSkill      = 490,
        targetCritRed = 5.6,
        classColor    = { r = 0.96, g = 0.55, b = 0.73 },
        rows          = nil,
        rowsBuilt     = false,
    },
}

local function BuildChart(capSkill, targetCritRed)
    local rows = {}
    for skill = 350, capSkill do
        local delta         = skill - 350
        local ratingNeeded  = math.floor(delta * 2.368 + 0.5)
        local critFromSkill = delta * 0.04
        local missingCrit   = math.max(0, targetCritRed - critFromSkill)
        local resilNeeded   = math.ceil(missingCrit * 39.423)
        table.insert(rows, { skill, ratingNeeded, resilNeeded })
    end
    return rows
end

local function EnsureChartBuilt(class)
    local chart = CHARTS[class]
    if not chart or chart.rowsBuilt then return end
    chart.rows      = BuildChart(chart.capSkill, chart.targetCritRed)
    chart.rowsBuilt = true
end

-------------------------------------------------------------------------------
-- Layout constants
-------------------------------------------------------------------------------
local VISIBLE_ROWS = 14
local ROW_HEIGHT   = 19
local WINDOW_W     = 340
local WINDOW_H     = 112 + (VISIBLE_ROWS * ROW_HEIGHT)

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
    -- CHANGE THIS LINE BELOW:
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

local headerY = -60
local TBR_CapHeaders = {} 

local topDivider = window:CreateTexture(nil, "ARTWORK")
topDivider:SetHeight(2)
topDivider:SetPoint("TOPLEFT", 18, -50)
topDivider:SetPoint("TOPRIGHT", -18, -50)
topDivider:SetTexture("Interface\\Buttons\\WHITE8X8") 

local colDivider = window:CreateTexture(nil, "ARTWORK")
colDivider:SetHeight(1)
colDivider:SetPoint("TOPLEFT", 18, headerY - 14) -- headerY is now defined!
colDivider:SetPoint("TOPRIGHT", -18, headerY - 14)
colDivider:SetTexture("Interface\\Buttons\\WHITE8X8")

local closeBtn = CreateFrame("Button", nil, window, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -4, -4)
closeBtn:SetScript("OnClick", function() window:Hide() end)

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

-- Note: You had a second colDivider definition here in your snippet. 
-- I have removed the duplicate to keep the code clean.

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
-- Row Pool with bounded growth
-------------------------------------------------------------------------------
local rowPool = {}

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

    for _, fs in pairs({ row.skill, row.rating, row.resil }) do
        fs:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        fs:SetSize(90, ROW_HEIGHT)
        fs:SetJustifyH("LEFT")
    end

    rowPool[i] = row
    return row
end

-------------------------------------------------------------------------------
-- Optimized PopulateChart (only runs when window is shown)
-------------------------------------------------------------------------------
local lastClass      = nil
local lastSkill      = 0
local lastTotalRows  = 0

local function PopulateChart()
    if not window:IsShown() then return end

    local _, class = UnitClass("player")
    local chart = CHARTS[class]
    if not chart or not chart.rowsBuilt then return end

    local currentSkill = GetCurrentDefenseSkill()
    local rows = chart.rows
    local total = #rows

    if class == lastClass and currentSkill == lastSkill and total == lastTotalRows then
        return
    end

    lastClass     = class
    lastSkill     = currentSkill
    lastTotalRows = total

    local cc = chart.classColor

    scrollChild:SetHeight(total * ROW_HEIGHT)
    local maxScroll = math.max(0, total * ROW_HEIGHT - scrollFrame:GetHeight())
    scrollBar:SetMinMaxValues(0, maxScroll)

    for i = 1, total do
        local data = rows[i]
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

        local colorR, colorG, colorB
        local fontFlag
        if isCurrent then
            colorR, colorG, colorB = cc.r, cc.g, cc.b
            fontFlag = "OUTLINE"
        else
            colorR, colorG, colorB = 0.65, 0.65, 0.65
            fontFlag = ""
        end

        row.skill:ClearAllPoints()
        row.skill:SetPoint("TOPLEFT", COL_SKILL - 14, yPos)
        row.skill:SetText(skill)
        row.skill:SetTextColor(colorR, colorG, colorB)
        row.skill:SetFont("Fonts\\FRIZQT__.TTF", 10, fontFlag)

        row.rating:ClearAllPoints()
        row.rating:SetPoint("TOPLEFT", COL_RATING - 14, yPos)
        row.rating:SetText(rating == 0 and "—" or rating)
        row.rating:SetTextColor(colorR, colorG, colorB)

        row.resil:ClearAllPoints()
        row.resil:SetPoint("TOPLEFT", COL_RESIL - 14, yPos)
        row.resil:SetText(resil == 0 and "—" or resil)
        row.resil:SetTextColor(colorR, colorG, colorB)

        row.bg:Show()
        row.accent:Show()
        row.skill:Show()
        row.rating:Show()
        row.resil:Show()
    end

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
-- Events (only meaningful when window is shown)
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
        return
    end

    local _, class = UnitClass("player")
    local chart = CHARTS[class]
    if not chart then return end

    EnsureChartBuilt(class)

    local cc = chart.classColor
    titleText:SetText(string.format("|cff%02x%02x%02x" .. L["Defense Cap Reference"] .. "|r", cc.r * 255, cc.g * 255, cc.b * 255))
    subtitleText:SetText(chart.label)

    window:Show()
    PopulateChart()
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
    elseif button == "LeftButton" and not IsShiftKeyDown() then
        TBR_DefenseCap_Toggle()
    end
end)

-- Suppress the default OnClick so click and drag don't both fire
charBtn:SetScript("OnClick", nil)

charBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["Defense Cap Reference"], 1, 1, 1)
    GameTooltip:AddLine(L["Click to view crit-immunity chart."], 0.7, 0.7, 0.7)
    GameTooltip:AddLine(L["Shift+drag to move."], 0.6, 0.6, 0.6)
    GameTooltip:Show()
end)
charBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Apply show/hide and saved position
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
        -- Default position: bottom-left of character frame
        charBtn:SetPoint("BOTTOMLEFT", PaperDollFrame, "BOTTOMLEFT", 22, 84)
    end
end

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
        TBR_DefenseCap_UpdateColor() -- Add this line
    end)
end)

function TBR_DefenseCap_UpdateColor()
    local db = TankBuffReminderCharDB
    local defaults = TankBuffReminderConfig.defaults
    local c = db.defCapColor or (defaults and defaults.defCapColor) or {r = 0.6, g = 0.5, b = 0.2, a = 1}
    
    -- 1. Update the Window Border
    window:SetBackdropBorderColor(c.r, c.g, c.b, (c.a and c.a > 0) and c.a or 1)
    
    -- 2. Update the Top Divider (using SetVertexColor for textures)
    if topDivider then
        topDivider:SetVertexColor(c.r, c.g, c.b, c.a)
    end

    -- 3. Update the Column Divider (the thin one below the headers)
    if colDivider then
        colDivider:SetVertexColor(c.r, c.g, c.b, 0.6) -- Keeping it slightly more transparent
    end

    -- 4. Update the Header Text
    -- We need to store these in a table or variables if we haven't already
    -- To make this work, update your MakeColHeader function (see Step 2 below)
    if TBR_CapHeaders then
        for _, header in ipairs(TBR_CapHeaders) do
            header:SetTextColor(c.r, c.g, c.b)
        end
    end
end

SLASH_TBRCAP1 = "/tbrcap"
SlashCmdList["TBRCAP"] = TBR_DefenseCap_Toggle