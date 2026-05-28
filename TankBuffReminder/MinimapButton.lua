-- MinimapButton.lua
local L = TBR_L

-------------------------------------------------------------------------------
-- Frame
-------------------------------------------------------------------------------
local tbrMinimapBtn = CreateFrame("Button", "TBR_MinimapButton", UIParent)
tbrMinimapBtn:SetSize(31, 31)
tbrMinimapBtn:SetFrameLevel(Minimap:GetFrameLevel() + 5)
tbrMinimapBtn:SetFrameStrata("MEDIUM")
tbrMinimapBtn:SetDontSavePosition(true)

local background = tbrMinimapBtn:CreateTexture(nil, "BACKGROUND")
background:SetSize(21, 21)
background:SetTexture("Interface\\Icons\\INV_Shield_06")
background:SetPoint("CENTER", 0, 0)

local border = tbrMinimapBtn:CreateTexture(nil, "OVERLAY")
border:SetSize(53, 53)
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetPoint("TOPLEFT", 0, 0)

local highlight = tbrMinimapBtn:CreateTexture(nil, "HIGHLIGHT")
highlight:SetSize(31, 31)
highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
highlight:SetPoint("CENTER", 0, 0)

-------------------------------------------------------------------------------
-- Positioning Engine
-------------------------------------------------------------------------------
function tbrMinimapBtn:UpdatePositionFromOffsets()
    if not TankBuffReminderCharDB then return end
    
    local angle = TankBuffReminderCharDB.minimapAngle or 45
    local radiusModifier = TankBuffReminderCharDB.minimapRadiusOffset or 0
    
    local minimap = Minimap
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    
    local baseRadius
    if shape == "SQUARE" then
        local halfSize = minimap:GetWidth() / 2
        baseRadius = halfSize + 16
    else
        baseRadius = 70
    end
    
    -- Combine default orbital radius with user preferences
    local finalRadius = baseRadius + radiusModifier
    
    local cx, cy = minimap:GetCenter()
    if not cx then return end -- Guard context safety
    
    local bx = cx + math.cos(math.rad(angle)) * finalRadius
    local by = cy + math.sin(math.rad(angle)) * finalRadius
    
    tbrMinimapBtn:ClearAllPoints()
    tbrMinimapBtn:SetPoint("CENTER", UIParent, "BOTTOMLEFT", bx, by)
end

local function DraggingUpdate()
    local cx, cy = Minimap:GetCenter()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x, y = x / scale, y / scale
    
    local angle = math.deg(math.atan2(y - cy, x - cx))
    if angle < 0 then angle = angle + 360 end
    
    if TankBuffReminderCharDB then
        TankBuffReminderCharDB.minimapAngle = math.floor(angle + 0.5)
    end
    
    -- Update live on-screen positioning
    tbrMinimapBtn:UpdatePositionFromOffsets()
    
    -- Update options sliders dynamically if the panel is currently open
    if TankBuffReminderOptions and TankBuffReminderOptions:IsShown() then
        if TankBuffReminderOptions.mapAngleSlider then
            TankBuffReminderOptions.mapAngleSlider:SetValue(TankBuffReminderCharDB.minimapAngle)
        end
    end
end

tbrMinimapBtn:SetMovable(true)
tbrMinimapBtn:RegisterForDrag("LeftButton")
tbrMinimapBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", DraggingUpdate)
end)
tbrMinimapBtn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    if TankBuffReminderOptions and TankBuffReminderOptions.refresh then
        TankBuffReminderOptions.refresh()
    end
end)

-------------------------------------------------------------------------------
-- Textures
-------------------------------------------------------------------------------
tbrMinimapBtn:SetNormalTexture("")
tbrMinimapBtn:SetPushedTexture("")
tbrMinimapBtn:SetHighlightTexture(highlight)

-------------------------------------------------------------------------------
-- Visual State
-------------------------------------------------------------------------------
local function RefreshButtonVisual()
    local disabled = TankBuffReminderCharDB and TankBuffReminderCharDB.disabled
    if disabled then
        background:SetVertexColor(0.3, 0.3, 0.3, 1)
    else
        background:SetVertexColor(1, 1, 1, 1)
    end
end

-------------------------------------------------------------------------------
-- Open Options
-------------------------------------------------------------------------------
local function OpenOptions()
    if InCombatLockdown() then
        print("|cFFFF6600[TBR]|r Cannot open options while in combat.")
        return
    end
    if SlashCmdList and SlashCmdList["TANKBUFFREMINDER"] then
        SlashCmdList["TANKBUFFREMINDER"]("")
    elseif TankBuffReminderOptions then
        if Settings and Settings.OpenToCategory then
            Settings.OpenToCategory(TankBuffReminderOptions)
            C_Timer.After(0.05, function()
                Settings.OpenToCategory(TankBuffReminderOptions)
            end)
        end
    else
        print("|cFFFF6600[TBR]|r Could not open options panel.")
    end
end

-------------------------------------------------------------------------------
-- Context Menu
-------------------------------------------------------------------------------
local tbrMenuFrame = CreateFrame("Frame", "TBR_MinimapContextMenu", UIParent, "UIDropDownMenuTemplate")

local function InitializeContextMenu(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = "|cFFFF6600Tank Buff Reminder|r"
    info.isTitle = true
    info.notCheckable = true
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    local isDisabled = TankBuffReminderCharDB and TankBuffReminderCharDB.disabled
    info.text = isDisabled and "|cFF33FF33Enable Addon|r" or "|cFFFF3333Disable Addon|r"
    info.notCheckable = true
    info.func = function()
        if TBR_SetAddonEnabled then
            TBR_SetAddonEnabled(isDisabled)
        end
        RefreshButtonVisual()
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = L["Open Options"] or "Open Options"
    info.notCheckable = true
    info.func = OpenOptions
    UIDropDownMenu_AddButton(info, level)
end

-------------------------------------------------------------------------------
-- Click / Tooltip
-------------------------------------------------------------------------------
tbrMinimapBtn:RegisterForClicks("AnyUp")
tbrMinimapBtn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        OpenOptions()
    elseif button == "RightButton" then
        UIDropDownMenu_Initialize(tbrMenuFrame, InitializeContextMenu, "MENU")
        ToggleDropDownMenu(1, nil, tbrMenuFrame, "cursor", 0, 0)
    end
end)

tbrMinimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("|cFFFF6600[TBR]|r Tank Buff Reminder", 1, 1, 1)
    GameTooltip:AddLine("|cFF33FF33Left-Click:|r Options Menu", 1, 1, 1)
    GameTooltip:AddLine("|cFF33FF33Right-Click:|r Enable / Disable", 1, 1, 1)
    GameTooltip:AddLine("|cFFBBBBBBDrag to move around the minimap.|r", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

tbrMinimapBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-------------------------------------------------------------------------------
-- Init
-------------------------------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    C_Timer.After(0.6, function()
        if not TankBuffReminderCharDB then return end
        
        -- Set defaults if values don't exist
        if TankBuffReminderCharDB.showMinimapButton == nil then TankBuffReminderCharDB.showMinimapButton = true end
        if TankBuffReminderCharDB.minimapAngle == nil then TankBuffReminderCharDB.minimapAngle = 45 end
        if TankBuffReminderCharDB.minimapRadiusOffset == nil then TankBuffReminderCharDB.minimapRadiusOffset = 0 end
        
        if TankBuffReminderCharDB.showMinimapButton then
            tbrMinimapBtn:Show()
        else
            tbrMinimapBtn:Hide()
        end
        
        tbrMinimapBtn:UpdatePositionFromOffsets()
        RefreshButtonVisual()
    end)
end)