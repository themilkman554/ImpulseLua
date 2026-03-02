--[[
    Impulse Lua - Main Menu
    Root menu with submenus for all features
    Port of mainMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Settings = require("Impulse/ImpulseLua/lib/settings")
local Menu = require("Impulse/ImpulseLua/lib/menu")
local TextInputComponent = require("Impulse/ImpulseLua/lib/ui/text_input_component")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local json = require("Impulse/ImpulseLua/lib/json")

-- Import submenus
local LocalMenu = require("Impulse/ImpulseLua/submenus/local_menu")
local VehicleMenu = require("Impulse/ImpulseLua/submenus/vehicle_menu")
local WeaponMenu = require("Impulse/ImpulseLua/submenus/weapon_menu")
local TeleportMenu = require("Impulse/ImpulseLua/submenus/teleport_menu")
local WorldMenu = require("Impulse/ImpulseLua/submenus/world_menu")
local SessionMenu = require("Impulse/ImpulseLua/submenus/session_menu")
local ProtectionMenu = require("Impulse/ImpulseLua/submenus/protection_menu")
local RecoveryMenu = require("Impulse/ImpulseLua/submenus/recovery_menu")
local MiscMenu = require("Impulse/ImpulseLua/submenus/misc_menu")
local SettingsMenu = require("Impulse/ImpulseLua/submenus/settings_menu")
local SearchResultsMenu = require("Impulse/ImpulseLua/submenus/search_results_menu")
local SpawnMenu = require("Impulse/ImpulseLua/submenus/spawn_menu")
local LuaScriptsMenu = require("Impulse/ImpulseLua/submenus/lua_scripts_menu")

local MainMenu = setmetatable({}, { __index = Submenu })
MainMenu.__index = MainMenu

local instance = nil

-- Store all submenus for searching
local allSubmenus = {}

-- Search input component
local searchInput = nil

--- Register a submenu for searching
---@param submenu table The submenu to register
function MainMenu.RegisterSubmenu(submenu)
    table.insert(allSubmenus, submenu)
end

--- Search through all options by name
---@param searchTerm string The search term (lowercase)
local function SearchOptions(searchTerm)
    local resultsMenu = SearchResultsMenu.GetInstance()
    resultsMenu:ClearOptions()
    
    local foundSomething = false
    searchTerm = string.lower(searchTerm)
    
    for _, submenu in ipairs(allSubmenus) do
        local matchingOptions = {}
        
        if submenu.options then
            for _, option in ipairs(submenu.options) do
                if option:IsVisible() and not option.isBreak then
                    local optionName = string.lower(option.name or "")
                    if string.find(optionName, searchTerm, 1, true) then
                        table.insert(matchingOptions, option)
                        foundSomething = true
                    end
                end
            end
        end
        
        if #matchingOptions > 0 then
            resultsMenu:AddSubmenuBreak(submenu.name or "Unknown")
            for _, opt in ipairs(matchingOptions) do
                resultsMenu:AddResult(opt)
            end
        end
    end
    
    if foundSomething then
        Menu.GoToSubmenu(resultsMenu)
    else
        Renderer.Notify("No results found")
    end
end

--- Get singleton instance
---@return MainMenu
function MainMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Home"), MainMenu)
        instance:Init()
    end
    return instance
end

--- Initialize the main menu
function MainMenu:Init()
    self:AddOption(SubmenuOption.new("Player")
        :AddSubmenu(LocalMenu.GetInstance())
        :AddTooltip("Player options"))
    
    self:AddOption(SubmenuOption.new("Weapon")
        :AddSubmenu(WeaponMenu.GetInstance())
        :AddTooltip("Weapon options"))
    
    self:AddOption(SubmenuOption.new("Vehicle")
        :AddSubmenu(VehicleMenu.GetInstance())
        :AddTooltip("Vehicle options"))
    
    self:AddOption(SubmenuOption.new("Spawn")
        :AddSubmenu(SpawnMenu.GetInstance())
        :AddTooltip("Spawn options"))
    
    self:AddOption(SubmenuOption.new("Teleport")
        :AddSubmenu(TeleportMenu.GetInstance())
        :AddTooltip("Teleport options"))
    
    self:AddOption(SubmenuOption.new("World")
        :AddSubmenu(WorldMenu.GetInstance())
        :AddTooltip("World options"))
    
    self:AddOption(SubmenuOption.new("Session")
        :AddSubmenu(SessionMenu.GetInstance())
        :AddTooltip("Session options"))
    
    self:AddOption(SubmenuOption.new("Protection")
        :AddSubmenu(ProtectionMenu.GetInstance())
        :AddTooltip("Protection options"))
    
    self:AddOption(SubmenuOption.new("Recovery")
        :AddSubmenu(RecoveryMenu.GetInstance())
        :AddTooltip("Recovery options [Risky]"))
    
    self:AddOption(SubmenuOption.new("Miscellaneous")
        :AddSubmenu(MiscMenu.GetInstance())
        :AddTooltip("Miscellaneous options"))
    
    self:AddOption(SubmenuOption.new("Settings")
        :AddSubmenu(SettingsMenu.GetInstance())
        :AddTooltip("Settings options"))

    self:AddOption(SubmenuOption.new("Lua Scripts")
        :AddSubmenu(LuaScriptsMenu.GetInstance())
        :AddTooltip("Lua scripts and utilities"))
    
    self:AddOption(ButtonOption.new("Search options")
        :AddFunction(function()
            if not searchInput then
                searchInput = TextInputComponent.new("Option name", function(text)
                    if text and #text > 1 then
                        SearchOptions(string.lower(text))
                    end
                end)
            end
            searchInput:Show()
        end)
        :AddTooltip("Search through the menus functions by name"))

    -- Register submenus for searching
    MainMenu.RegisterSubmenu(LocalMenu.GetInstance())
    MainMenu.RegisterSubmenu(WeaponMenu.GetInstance())
    MainMenu.RegisterSubmenu(VehicleMenu.GetInstance())
    MainMenu.RegisterSubmenu(SpawnMenu.GetInstance())
    MainMenu.RegisterSubmenu(TeleportMenu.GetInstance())
    MainMenu.RegisterSubmenu(WorldMenu.GetInstance())
    MainMenu.RegisterSubmenu(SessionMenu.GetInstance())
    MainMenu.RegisterSubmenu(ProtectionMenu.GetInstance())
    MainMenu.RegisterSubmenu(RecoveryMenu.GetInstance())
    MainMenu.RegisterSubmenu(MiscMenu.GetInstance())
    MainMenu.RegisterSubmenu(SettingsMenu.GetInstance())
    MainMenu.RegisterSubmenu(LuaScriptsMenu.GetInstance())
end

function MainMenu:FeatureUpdate()
    local teleportMenu = TeleportMenu.GetInstance()
    if teleportMenu and teleportMenu.FeatureUpdate then
        teleportMenu:FeatureUpdate()
    end
    
    local spawnMenu = SpawnMenu.GetInstance()
    if spawnMenu and spawnMenu.FeatureUpdate then
        spawnMenu:FeatureUpdate()
    end

    if recoveryMenu and recoveryMenu.FeatureUpdate then
        recoveryMenu:FeatureUpdate()
    end

    local SettingsMenu = require("Impulse/ImpulseLua/submenus/settings_menu")
    if SettingsMenu.GetInstance().FeatureUpdate then
        SettingsMenu.GetInstance():FeatureUpdate()
    end

    if searchInput and searchInput:IsVisible() then
        searchInput:Update()
    end
    
    -- Update generic active input component (e.g. KeyInputComponent)
    if Menu.activeInputComponent and Menu.activeInputComponent:IsVisible() then
        Menu.activeInputComponent:Update()
    end
end

return MainMenu

