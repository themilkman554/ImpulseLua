--[[
    Impulse Lua - Settings Menu
    Menu appearance and behavior settings
    Port of settingsMenu.cpp from Impulse C++
]]
local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Menu = require("Impulse/ImpulseLua/lib/menu")
local ConfigMgr = require("Impulse/ImpulseLua/lib/config_mgr")

local SettingsMenu = setmetatable({}, { __index = Submenu })
SettingsMenu.__index = SettingsMenu
local instance = nil

function SettingsMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Settings"), SettingsMenu)
        instance:Init()
    end
    return instance
end

function SettingsMenu:Init()
    local Renderer = require("Impulse/ImpulseLua/lib/renderer")
    local ThemeMenu = require("Impulse/ImpulseLua/submenus/settings/theme_menu")
    local Settings = require("Impulse/ImpulseLua/lib/settings")
    local KeyOption = require("Impulse/ImpulseLua/lib/options/key")
    local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
    local ColorOption = require("Impulse/ImpulseLua/lib/options/color")
    
    local LanguageMenu = require("Impulse/ImpulseLua/submenus/settings/language_menu")
    local ConfigMenu = require("Impulse/ImpulseLua/submenus/settings/config_menu")
    
    self:AddOption(SubmenuOption.new("Configs")
        :AddSubmenu(ConfigMenu.GetInstance())
        :AddTooltip("Save and Load configurations"))
    
    self:AddOption(SubmenuOption.new("Language")
        :AddSubmenu(LanguageMenu.GetInstance())
        :AddTooltip("Language and translation options"))
    
    self:AddOption(SubmenuOption.new("Menu theme")
        :AddSubmenu(ThemeMenu.GetInstance())
        :AddTooltip("Theme options"))
    
    self:AddOption(BreakOption.new("Input"))
    
    self:AddOption(KeyOption.new("Open key [open/close trainer]")
        :AddKeyRef(Settings, "OpenKey")
        :AddFunction(function()
            Menu.openKey = Settings.OpenKey
            ConfigMgr.SaveGlobalSettings()
            Renderer.Notify("Open key updated")
        end)
        :AddTooltip("Open/close key for the trainer"))
        
    self:AddOption(ToggleOption.new("Mouse support")
        :AddToggleRef(Settings, "MouseEnabled")
        :AddFunction(function()
            ConfigMgr.SaveGlobalSettings()
        end)
        :AddTooltip("Enable/disable mouse support for the menu"))
        
    self:AddOption(ToggleOption.new("Allow mouse to move menu")
        :AddToggleRef(Settings, "MouseMoveEnabled")
        :AddFunction(function()
            ConfigMgr.SaveGlobalSettings()
        end)
        :AddTooltip("Allow the mouse to drag the menu"))
        
    self:AddOption(NumberOption.new(1, "Max display options on the trainer")
        :AddNumberRef(Menu, "maxOptions", "%i", 1)
        :AddMin(8)
        :AddMax(21)
        :AddTooltip("This will change the max options that display on the trainer pages - 14 is default"))
        
    local hideTypes = {
        "Always",
        "When menu is open",
        "Never",
        "Extend"
    }
    local hideTypeItems = {}
    for i, name in ipairs(hideTypes) do
        hideTypeItems[i] = { name = name, value = i }
    end
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Show screen panel buttons")
        :AddScroll(hideTypeItems, 1)
        :AddIndexRef(Settings, "HideType")
        :AddTooltip("Show screen panel buttons"))
        
    self:AddOption(ToggleOption.new("Allow gameplay while using mouse")
        :AddToggleRef(Settings, "AllowMove")
        :AddTooltip("This will allow gameplay to be used while using mouse"))
        
    self:AddOption(ToggleOption.new("Keep last position on trainer open")
        :AddToggleRef(Settings, "KeepLastPos")
        :AddTooltip("This will allow the trainer to open at the last location you closed at"))
        
    self:AddOption(ToggleOption.new("Keep last position on trainer open")
        :AddToggleRef(Settings, "KeepLastPos")
        :AddTooltip("This will allow the trainer to open at the last location you closed at"))
        
    self:AddOption(ToggleOption.new("Allow menu to be close by back button")
        :AddToggleRef(Settings, "AllowMenuCloseByBack")
        :AddTooltip("Allow closing the menu with the back button (B/Circle/Backspace)"))
        
    self:AddOption(ToggleOption.new("Disable controller input")
        :AddToggleRef(Settings, "DisableControllerInput")
        :AddTooltip("This will disable any controller input for the trainer"))
        
    self:AddOption(ButtonOption.new("Close all Side Panel Windows")
        :AddFunction(function() 
            local WindowManager = require("Impulse/ImpulseLua/lib/ui/window_manager")
            local closedCount = WindowManager.GetInstance():CloseAllWindows()
            if closedCount > 0 then
                Renderer.Notify("All Windows Closed")
            else
                Renderer.Notify("No windows to Close")
            end
        end)
        :AddTooltip("Close all UI windows"))
        
    self:AddOption(BreakOption.new("Hide Options"))

    self:AddOption(ToggleOption.new("Hide tooltip box")
        :AddToggleRef(Settings, "HideUITooltips")
        :AddTooltip("Hide this tooltip box"))
        
    self:AddOption(ToggleOption.new("Hide toggle cursor tooltip")
        :AddToggleRef(Settings, "HideCursorTooltip")
        :AddTooltip("Hide \"Toggle cursor on/off\""))
        
    self:AddOption(ToggleOption.new("Hide ips from player infobox")
        :AddToggleRef(Settings, "HidePlayerIPs")
        :AddTooltip("Hide player ips on the session tab"))
        
    self:AddOption(ToggleOption.new("Hide r* ids from player infobox")
        :AddToggleRef(Settings, "HidePlayerRIDs")
        :AddTooltip("Hide player r* ids on the session tab"))
        
    self:AddOption(ToggleOption.new("Hide map from player list")
        :AddToggleRef(Settings, "HideMap")
        :AddTooltip("Hide map from player list on the session tab"))
        
    self:AddOption(BreakOption.new("Onscreen Elements"))
    
    local measurementTypes = {
        "Imperial",
        "Metric"
    }
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Measurement type")
        :AddScroll(measurementTypes)
        :AddIndexRef(Settings, "MeasurementType")
        :AddTooltip("Change between measurement types (such as MPH and KPH)"))
        
    self:AddOption(ToggleOption.new("Add outline to onscreen elements")
        :AddToggleRef(Settings, "OutlineOnScreenElements")
        :AddTooltip("This will add an outline to some onscreen elements from the trainer (etc. FPS)"))
        
    self:AddOption(ColorOption.new("Edit color of onscreen elements")
        :AddColor(Settings.ColorScreenElements)
        :AddTooltip("This will edit the color to some onscreen elements from the trainer (etc. FPS)"))
        
    self:AddOption(ToggleOption.new("Remove outline from breaks / scrolling options")
        :AddToggleRef(Settings, "UnoutlineStuffs")
        :AddTooltip("This will remove the black outlines from breaks and scrolling sliders"))
end

function SettingsMenu:FeatureUpdate()
    -- Redundant: these are handled by the main loop
end

return SettingsMenu

