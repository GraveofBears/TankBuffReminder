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
    
    -- Sync checkboxes
    for key, cb in pairs(panel.checkboxes) do
        TankBuffReminderDB[key] = cb:GetChecked() and true or false
    end
    
    -- Sync sound toggle
    if panel.soundCB then
        TankBuffReminderDB.playSound = panel.soundCB:GetChecked() and true or false
    end

    -- Sync pulse speed slider
    if panel.pulseSlider then
        TankBuffReminderDB.pulseSpeed = panel.pulseSlider:GetValue()
    end

    -- FORCE the main script to rebuild the tracking list immediately
    if TankBuffReminder_RebuildTrackedBuffs then
        TankBuffReminder_RebuildTrackedBuffs()
    end
end

---------------------------------------------------------
-- UI Component Helpers
---------------------------------------------------------
local function CreateCheckbox(parent, label, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb.Text:SetText(label)
    
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

local function CreateSlider(parent, label, min, max, x, y)
    local sliderName = "TBR_PulseSlider"
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(0.5)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(180)
    
    _G[sliderName .. "Text"]:SetText(label)
    _G[sliderName .. "Low"]:SetText("Off")
    _G[sliderName .. "High"]:SetText("Fast")
    
    slider:SetScript("OnValueChanged", function()
        SyncSettings()
    end)
    return slider
end

local function CreateSoundDropdown(parent, x, y)
    local dropdown = CreateFrame("Frame", "TankBuffReminderSoundDropdown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", x, y)
    UIDropDownMenu_SetWidth(dropdown, 150)
    UIDropDownMenu_SetText(dropdown, "Select Sound")

    UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        if not cfg.sounds then return end
        for _, sound in ipairs(cfg.sounds) do
            info.text = sound.name
            info.arg1 = sound.id
            info.func = function(btn, arg1)
                TankBuffReminderDB.soundID = arg1
                UIDropDownMenu_SetText(dropdown, sound.name)
                PlaySound(arg1, "Master")
                SyncSettings()
            end
            info.checked = (TankBuffReminderDB.soundID == sound.id)
            UIDropDownMenu_AddButton(info)
        end
    end)
    return dropdown
end

---------------------------------------------------------
-- Build Interface
---------------------------------------------------------
panel.checkboxes = {}
local y = -60

local sections = {
    { name = "Paladin", keys = {"righteousFury", "devotionAura"} },
    { name = "Druid",   keys = {"thorns", "markOfTheWild", "omenOfClarity"} },
    { name = "Warrior", keys = {"battleShout", "commandingShout", "defensiveStance"} }
}

for _, section in ipairs(sections) do
    CreateHeader(panel, section.name, 16, y)
    y = y - 24
    for _, key in ipairs(section.keys) do
        for _, b in ipairs(cfg.buffs) do
            if b.key == key then
                panel.checkboxes[key] = CreateCheckbox(panel, b.name, 32, y)
                y = y - 26
            end
        end
    end
    y = y - 10
end

-- Global Settings Column
panel.soundCB = CreateCheckbox(panel, "Play alert sound", 250, -60)
panel.soundDropdown = CreateSoundDropdown(panel, 235, -100)
panel.pulseSlider = CreateSlider(panel, "Pulse Speed", 0, 10, 250, -160)

-- Reset Button
local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetBtn:SetSize(180, 24)
resetBtn:SetPoint("TOPLEFT", 250, -210)
resetBtn:SetText("Reset Position & Size")
resetBtn:SetScript("OnClick", function()
    TankBuffReminderDB.point = nil
    TankBuffReminderDB.scale = 1
    ReloadUI()
end)

---------------------------------------------------------
-- Refresh Logic
---------------------------------------------------------
function panel.refresh()
    if not TankBuffReminderDB then return end
    
    -- Sync UI Checkboxes to DB
    for key, cb in pairs(panel.checkboxes) do
        local saved = TankBuffReminderDB[key]
        cb:SetChecked(saved ~= false)
    end
    
    -- Sync Sound Toggle
    panel.soundCB:SetChecked(TankBuffReminderDB.playSound ~= false)

    -- Sync Slider (Ensure it is shown and set)
    local speed = TankBuffReminderDB.pulseSpeed or (cfg.defaults and cfg.defaults.pulseSpeed) or 4
    panel.pulseSlider:SetValue(speed)
    panel.pulseSlider:Show()

    -- Sync Dropdown text
    local currentSoundID = TankBuffReminderDB.soundID or (cfg.defaults and cfg.defaults.soundID) or 8959
    if cfg.sounds then
        for _, sound in ipairs(cfg.sounds) do
            if sound.id == currentSoundID then
                UIDropDownMenu_SetText(panel.soundDropdown, sound.name)
            end
        end
    end
end

-- CRITICAL FIX: Refresh the UI every time the options panel is opened
panel:SetScript("OnShow", function()
    panel.refresh()
end)

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