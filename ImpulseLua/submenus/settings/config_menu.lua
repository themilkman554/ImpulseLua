--[[
    Impulse Lua - Config Menu
    Main menu for managing configs.
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local ConfigMgr = require("Impulse/ImpulseLua/lib/config_mgr")
local Settings = require("Impulse/ImpulseLua/lib/settings")
local TextInputComponent = require("Impulse/ImpulseLua/lib/ui/text_input_component")
local LoadConfigMenu = require("Impulse/ImpulseLua/submenus/settings/load_config_menu")
local ThemeLoaderMenu = require("Impulse/ImpulseLua/submenus/settings/theme_loader_menu")

local ConfigMenu = setmetatable({}, { __index = Submenu })
ConfigMenu.__index = ConfigMenu

local instance = nil
local activeInput = nil
local profilesList = {}
local autoLoadScroll = nil

function ConfigMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Configs"), ConfigMenu)
        instance:Init()
    end
    return instance
end

function ConfigMenu:Init()
    local function RefreshProfiles()
        profilesList = ConfigMgr.GetProfiles()
        if autoLoadScroll then
            autoLoadScroll:AddScroll(profilesList, 1)
        end
    end

    self:AddOption(SubmenuOption.new("Load Config")
        :AddSubmenu(LoadConfigMenu.GetInstance())
        :AddTooltip("Load a saved configuration"))

    self:AddOption(ButtonOption.new("Save Config")
        :AddFunction(function()
            activeInput = TextInputComponent.new("Enter config name", function(name)
                if name and name ~= "" then
                    if ConfigMgr.Save(name) then
                         RefreshProfiles()
                         if Settings.AutoLoadConfig and Settings.AutoLoadConfigName == name then
                             ConfigMgr.SaveGlobalSettings()
                         end
                    end
                else
                    Renderer.Notify("Invalid name")
                end
            end)
            activeInput:Show()
        end)
        :AddTooltip("Save current configuration"))

    self:AddOption(BreakOption.new("Options"))

    profilesList = ConfigMgr.GetProfiles()
    autoLoadScroll = ScrollOption.new(ScrollOption.Type.SCROLL, "Target Profile")
        :AddScroll(profilesList, 1)
        :AddFunction(function()
            local selected = profilesList[autoLoadScroll:GetIndex()]
            if selected then
                Settings.AutoLoadConfigName = selected.value
                ConfigMgr.SaveGlobalSettings()
                Renderer.Notify("Auto-load target: " .. selected.value)
            end
        end)
        :AddTooltip("Select the profile to load automatically")
    
    -- Sync initial index
    for i, p in ipairs(profilesList) do
        if p.value == Settings.AutoLoadConfigName then
            autoLoadScroll:SetIndex(i)
            break
        end
    end
    self:AddOption(autoLoadScroll)

    self:AddOption(ToggleOption.new("Auto load this config")
        :AddToggleRef(Settings, "AutoLoadConfig")
        :AddFunction(function()
            ConfigMgr.SaveGlobalSettings()
            if Settings.AutoLoadConfig then
                Renderer.Notify("Auto-load enabled for: " .. Settings.AutoLoadConfigName)
            else
                Renderer.Notify("Auto-load disabled")
            end
        end)
        :AddTooltip("Automatically load the selected config on startup"))

    self:AddOption(ButtonOption.new("Refresh Profile List")
        :AddFunction(function()
            RefreshProfiles()
            Renderer.Notify("Profile list refreshed")
        end)
        :AddTooltip("Refresh the list of available profiles"))
        
    self:AddOption(ButtonOption.new("Reset Config")
         :AddFunction(function()
             Renderer.Notify("Resetting config...")
             
             -- 1. Reset persistent settings logic
             ConfigMgr.ResetGlobalSettings()
             
             -- 2. Clear loaded packages to force reload
             for k, v in pairs(package.loaded) do
                 if string.find(k, "^Impulse/") then
                     package.loaded[k] = nil
                 end
             end
             
             -- 3. Execute new instance and unload current
             local mainPath = FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\main.lua"
             if Utils.ExecuteScript(mainPath) then
                 SetShouldUnload()
             else
                 Renderer.Notify("Failed to restart script!")
             end
         end)
         :AddTooltip("Reset all settings to default"))

end

function ConfigMenu:OnEnter()
    profilesList = ConfigMgr.GetProfiles()
    if autoLoadScroll then
        autoLoadScroll:AddScroll(profilesList, 1)
        for i, p in ipairs(profilesList) do
            if p.value == Settings.AutoLoadConfigName then
                autoLoadScroll:SetIndex(i)
                break
            end
        end
    end
end

function ConfigMenu:FeatureUpdate()
    if activeInput and activeInput:IsVisible() then
        activeInput:Update()
    end
end

return ConfigMenu
