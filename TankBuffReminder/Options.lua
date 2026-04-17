-- Options.lua
local cfg = TankBuffReminderConfig

---------------------------------------------------------
-- Create panel
---------------------------------------------------------
local panel = CreateFrame("Frame", "TankBuffReminderOptions")
panel.name = "Tank Buff Reminder"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Tank Buff Reminder")

---------------------------------------------------------
-- Sync Logic: Force local UI state into the Global DB
---------------------------------------------------------
local function SyncSettings()
    if not TankBuffReminderDB then return end
    
    -- Loop through all checkboxes and update the DB
    for key, cb in pairs(panel.checkboxes) do
        -- Explicitly save as true or false
        TankBuffReminderDB[key] = cb:GetChecked() and true or false
    end
    
    -- Save sound toggle
    if panel.soundCB then
        TankBuffReminderDB.playSound = panel.soundCB:GetChecked() and true or false
    end

    -- FORCE the main script to rebuild the tracking list immediately
    if TankBuffReminder_RebuildTrackedBuffs then
        TankBuffReminder_RebuildTrackedBuffs()
    end
end

---------------------------------------------------------
-- Helpers
---------------------------------------------------------
local function CreateCheckbox(parent, label, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb.Text:SetText(label)
    
    -- Reactive Fix: Save every time the user clicks
    cb:SetScript("OnClick", function()
        SyncSettings()
    end)
    
    return cb
end

local function CreateHeader(parent, text, x, y)
    local hdr = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    hdr:SetPoint("TOPLEFT", x, y)
    hdr:SetText(text)
    return hdr
end

---------------------------------------------------------
-- Build Interface
---------------------------------------------------------
panel.checkboxes = {}
local y = -60

-- Define sections to build the UI dynamically
local sections = {
    { name = "Paladin", keys = {"righteousFury", "devotionAura"} },
    { name = "Druid",   keys = {"thorns", "markOfTheWild", "omenOfClarity"} },
    { name = "Warrior", keys = {"battleShout", "commandingShout", "defensiveStance"} }
}

for _, section in ipairs(sections) do
    CreateHeader(panel, section.name, 16, y)
    y = y - 24
    for _, key in ipairs(section.keys) do
        -- Find matching buff in config
        for _, b in ipairs(cfg.buffs) do
            if b.key == key then
                panel.checkboxes[key] = CreateCheckbox(panel, b.name, 32, y)
                y = y - 26
            end
        end
    end
    y = y - 10
end

-- Alert Sound Toggle
panel.soundCB = CreateCheckbox(panel, "Play alert sound", 250, -60)

-- Reset Button
local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetBtn:SetSize(180, 24)
resetBtn:SetPoint("TOPLEFT", 250, -100)
resetBtn:SetText("Reset Position & Size")
resetBtn:SetScript("OnClick", function()
    TankBuffReminderDB.point = nil
    TankBuffReminderDB.scale = 1
    ReloadUI()
end)

---------------------------------------------------------
-- Load settings into UI
---------------------------------------------------------
function panel.refresh()
    if not TankBuffReminderDB then return end
    
    for key, cb in pairs(panel.checkboxes) do
        local saved = TankBuffReminderDB[key]
        -- Default to checked if nil, otherwise respect the boolean
        cb:SetChecked(saved ~= false)
    end
    
    panel.soundCB:SetChecked(TankBuffReminderDB.playSound ~= false)
end

-- Standard WoW Options Category registration
panel.okay = SyncSettings
local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)

---------------------------------------------------------
-- Slash Command
---------------------------------------------------------
SLASH_TANKBUFFREMINDER1 = "/tbr"
SlashCmdList["TANKBUFFREMINDER"] = function()
    panel.refresh()
    Settings.OpenToCategory(category)
end