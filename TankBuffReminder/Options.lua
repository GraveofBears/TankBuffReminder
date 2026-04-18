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
    
    -- Sync checkboxes (Class Buffs)
    for key, cb in pairs(panel.checkboxes) do
        TankBuffReminderDB[key] = cb:GetChecked() and true or false
    end
    
    -- Sync Global Toggles
    TankBuffReminderDB.playSound = panel.soundCB:GetChecked()
    TankBuffReminderDB.autoRemoveSalvation = panel.salvationCB:GetChecked()
    TankBuffReminderDB.autoSetTankRole = panel.tankRoleCB:GetChecked()
    TankBuffReminderDB.autoRepair = panel.repairCB:GetChecked()

    -- Sync sliders
    TankBuffReminderDB.pulseSpeed = panel.pulseSlider:GetValue()
    TankBuffReminderDB.glowSize = panel.glowSlider:GetValue()

    -- Trigger immediate visual update for the glow in the main script
    if TankBuffReminder_UpdateGlow then 
        TankBuffReminder_UpdateGlow() 
    end

    -- Force the main script to rebuild tracking lists
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
    cb:SetScript("OnClick", function() SyncSettings() end)
    return cb
end

local function CreateHeader(parent, text, x, y)
    local hdr = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    hdr:SetPoint("TOPLEFT", x, y)
    hdr:SetText(text)
    return hdr
end

local function CreateSlider(parent, label, min, max, x, y, uniqueName)
    local slider = CreateFrame("Slider", uniqueName, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(0.1)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(180)
    _G[uniqueName .. "Text"]:SetText(label)
    _G[uniqueName .. "Low"]:SetText(tostring(min))
    _G[uniqueName .. "High"]:SetText(tostring(max))
    
    -- Sync immediately on slider movement
    slider:SetScript("OnValueChanged", function() 
        SyncSettings() 
    end)
    return slider
end

local function CreateSoundDropdown(parent, x, y)
    local dropdown = CreateFrame("Frame", "TankBuffReminderSoundDropdown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", x, y)
    UIDropDownMenu_SetWidth(dropdown, 150)
    
    UIDropDownMenu_Initialize(dropdown, function(self, level)
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

local function CreateColorButton(parent, label, x, y)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(18, 18)
    btn:SetPoint("TOPLEFT", x, y)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1, 1)
    btn.bg = bg
    local text = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("LEFT", btn, "RIGHT", 8, 0)
    text:SetText(label)

    btn:SetScript("OnClick", function()
        local color = TankBuffReminderDB.glowColor or cfg.defaults.glowColor
        ColorPickerFrame:SetupColorPickerAndShow({
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                local a = ColorPickerFrame:GetColorAlpha()
                TankBuffReminderDB.glowColor = { r = r, g = g, b = b, a = a }
                btn.bg:SetVertexColor(r, g, b, a)
                SyncSettings()
            end,
            r = color.r, g = color.g, b = color.b, opacity = color.a, hasOpacity = true
        })
    end)
    return btn
end

---------------------------------------------------------
-- Build Interface
---------------------------------------------------------
panel.checkboxes = {}
local y = -60

-- Column 1: Class Buffs
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

-- Column 2: Global & Appearance
local x2 = 250
panel.soundCB = CreateCheckbox(panel, "Play alert sound", x2, -60)
panel.soundDropdown = CreateSoundDropdown(panel, x2-15, -100)
panel.pulseSlider = CreateSlider(panel, "Pulse Speed", 0, 10, x2, -160, "TBR_PulseSlider")
panel.glowSlider = CreateSlider(panel, "Glow Size", 1.0, 3.0, x2, -220, "TBR_GlowSlider")

-- Appearance
panel.colorBtn = CreateColorButton(panel, "Glow Color", x2+4, -260)

-- Automation Headers & Toggles
CreateHeader(panel, "Automation", x2, -300)
panel.salvationCB = CreateCheckbox(panel, "Auto-remove Salvation", x2, -320)
panel.tankRoleCB = CreateCheckbox(panel, "Auto-set Tank Role", x2, -345)
panel.repairCB = CreateCheckbox(panel, "Auto-Repair at Merchant", x2, -370)

-- Reset Button
local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetBtn:SetSize(180, 24)
resetBtn:SetPoint("TOPLEFT", x2, -430)
resetBtn:SetText("Reset All Settings")
resetBtn:SetScript("OnClick", function()
    TankBuffReminderDB = nil
    ReloadUI()
end)

---------------------------------------------------------
-- Refresh Logic
---------------------------------------------------------
function panel.refresh()
    if not TankBuffReminderDB then return end
    
    -- Refresh Checkboxes
    for key, cb in pairs(panel.checkboxes) do
        cb:SetChecked(TankBuffReminderDB[key] ~= false)
    end
    
    -- Refresh Toggles
    panel.soundCB:SetChecked(TankBuffReminderDB.playSound ~= false)
    panel.salvationCB:SetChecked(TankBuffReminderDB.autoRemoveSalvation ~= false)
    panel.tankRoleCB:SetChecked(TankBuffReminderDB.autoSetTankRole ~= false)
    panel.repairCB:SetChecked(TankBuffReminderDB.autoRepair ~= false)

    -- Refresh Sliders
    panel.pulseSlider:SetValue(TankBuffReminderDB.pulseSpeed or 4)
    panel.glowSlider:SetValue(TankBuffReminderDB.glowSize or 1.5)
    
    -- Refresh Color
    local c = TankBuffReminderDB.glowColor or cfg.defaults.glowColor or {r=1, g=1, b=1, a=1}
    panel.colorBtn.bg:SetVertexColor(c.r, c.g, c.b, c.a)

    -- Refresh Dropdown Text
    local currentSoundID = TankBuffReminderDB.soundID or 8959
    if cfg.sounds then
        local found = false
        for _, sound in ipairs(cfg.sounds) do
            if sound.id == currentSoundID then 
                UIDropDownMenu_SetText(panel.soundDropdown, sound.name)
                found = true
                break
            end
        end
        if not found then UIDropDownMenu_SetText(panel.soundDropdown, "Select Sound") end
    end
end

panel:SetScript("OnShow", function() panel.refresh() end)
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