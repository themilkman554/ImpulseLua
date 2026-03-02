--[[
    Impulse Lua - Player Lua Content Menu
    Dynamic menu for player-specific Lua scripts
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local json = require("Impulse/ImpulseLua/lib/json")

local PlayerLuaContentMenu = setmetatable({}, { __index = Submenu })
PlayerLuaContentMenu.__index = PlayerLuaContentMenu

local PlayerInfoComponent = require("Impulse/ImpulseLua/lib/ui/player_info_component")

local instance = nil
local PlayerMenu = nil -- Lazy loaded to avoid circular dependency

--- Resolve eFeatureType value to string (Button, Toggle, etc.).
local function typeToString(t)
    if type(t) == "string" then return t end
    if eFeatureType then
        for k, v in pairs(eFeatureType) do
            if v == t then return k end
        end
    end
    return tostring(t)
end

--- Get the currently selected player ID
local function GetSelectedPlayerId()
    if not PlayerMenu then
        PlayerMenu = require("Impulse/ImpulseLua/submenus/session/player_menu")
    end
    -- Support explicit "Overseer" ID context if needed, but usually targetPlayer is it.
    return PlayerMenu.targetPlayer or -1
end

--- Scan TranslationFile and build dynamic menus based on unique player features
local function BuildLuaPlayerMenus()
    if not instance then return end

    -- Update submenu titles with player name
    local pid = GetSelectedPlayerId()
    local name = "Player"
    if pid >= 0 then
        name = PLAYER.GET_PLAYER_NAME(pid) or "Player"
    end
    
    if instance.buttonSubmenu then instance.buttonSubmenu.name = name .. " Buttons" end
    if instance.toggleSubmenu then instance.toggleSubmenu.name = name .. " Toggles" end

    local translationPath = FileMgr.GetMenuRootPath() .. "\\Translations\\TranslationFile.json"
    -- Use exclusion list from LuaScriptsMenu
    local LuaScriptsMenu = require("Impulse/ImpulseLua/submenus/lua_scripts_menu")
    local FeatureState = require("Impulse/ImpulseLua/lib/featurestate") -- Add FeatureState require
    local discardHashes = {}
    if LuaScriptsMenu and LuaScriptsMenu.TranslationExcludeList then
        for hash in pairs(LuaScriptsMenu.TranslationExcludeList) do
            discardHashes[hash] = true
        end
    end

    local translationRaw = FileMgr.ReadFileContent(translationPath)
    if not translationRaw or translationRaw == "" then
        Renderer.Notify("Build: Could not read TranslationFile.json")
        return
    end
    local ok, translation = pcall(json.decode, translationRaw)
    if not ok or type(translation) ~= "table" then
        Renderer.Notify("Build: Failed to parse TranslationFile.json")
        return
    end

    -- Clear existing dynamic options
    if instance.buttonSubmenu then instance.buttonSubmenu:ClearOptions() end
    if instance.toggleSubmenu then instance.toggleSubmenu:ClearOptions() end

    -- Build unique list
    local unique = {}
    for hash, name in pairs(translation) do
        if not discardHashes[tostring(hash)] then
            table.insert(unique, { hash = hash, name = name })
        end
    end
    table.sort(unique, function(a, b) return tostring(a.hash) < tostring(b.hash) end)

    local count = 0
    if FeatureMgr and FeatureMgr.GetFeatureByName then
        for _, entry in ipairs(unique) do
            local name = entry.name
            if name and name ~= "" then
                -- Check for global feature first
                local feature = FeatureMgr.GetFeatureByName(name)
                
                -- Fallback: try with player ID 0 (required for some player features)
                if not feature then
                    feature = FeatureMgr.GetFeatureByName(name, 0)
                end
                
                if feature then
                     -- Verify it is actually a player feature
                     local isPlayerFeature = false
                     local okP, res = pcall(function() return feature:IsPlayerFeature() end)
                     if okP and res then
                         isPlayerFeature = true
                     end

                     if isPlayerFeature then
                         local okType, t = pcall(function() return feature:GetType() end)
                         
                         if okType then
                             local typeStr = typeToString(t)
                             local desc = ""
                             pcall(function() desc = feature:GetDesc() end)

                             if typeStr == "Button" then
                                 pcall(function()
                                     instance.buttonSubmenu:AddOption(ButtonOption.new(name)
                                         :AddFunction(function() 
                                             local pid = GetSelectedPlayerId()
                                             if pid >= 0 then
                                                 local f = FeatureMgr.GetFeatureByName(name, pid)
                                                 if f then f:TriggerCallback() end
                                             end
                                         end)
                                         :AddTooltip(desc)
                                     )
                                     count = count + 1
                                 end)
                             elseif typeStr == "Toggle" then
                                 pcall(function()
                                     local opt = ToggleOption.new(name)
                                     -- Sync state with selected player
                                     opt:AddOnUpdate(function(self)
                                         local pid = GetSelectedPlayerId()
                                         if pid >= 0 then
                                             self.value = FeatureState.Get(name, pid)
                                         end
                                     end)
                                     -- Trigger toggle
                                     opt:AddFunction(function()
                                         local pid = GetSelectedPlayerId()
                                         if pid >= 0 then
                                             -- Use deferred toggle to prevent menu rendering issues
                                             FeatureState.ToggleDeferred(name, opt.value, pid)
                                         end
                                     end)
                                     opt:AddTooltip(desc)
                                     
                                     instance.toggleSubmenu:AddOption(opt)
                                     count = count + 1
                                 end)
                             end
                         end
                     end
                end
            end
        end
    end

    -- Update visibility of submenu options
    if instance.buttonSubmenuOption then
        instance.buttonSubmenuOption.visible = (#instance.buttonSubmenu.options > 0)
    end
    if instance.toggleSubmenuOption then
        instance.toggleSubmenuOption.visible = (#instance.toggleSubmenu.options > 0)
    end
    
    if instance.redirectOption then
        instance.redirectOption.visible = (count == 0)
    end

    if count > 0 then
        -- Renderer.Notify("Player Lua: Populated " .. count .. " options.") -- Make silent if user prefers, but okay for now
    end
end

-- Expose build function globally for this module
function PlayerLuaContentMenu.BuildMenus()
    -- Ensure submenus are created
    if not instance then
        PlayerLuaContentMenu.GetInstance()
    end
    BuildLuaPlayerMenus()
end

function PlayerLuaContentMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Lua Content"), PlayerLuaContentMenu)
        instance:Init()
    end
    return instance
end

function PlayerLuaContentMenu:Init()
    -- Create submenus
    self.buttonSubmenu = Submenu.new("Player Buttons")
    self.buttonSubmenu.CustomRender = function() PlayerInfoComponent.Render() end
    self.buttonSubmenu.OnEnter = function(self)
        local pid = GetSelectedPlayerId()
        if pid >= 0 then
             local name = PLAYER.GET_PLAYER_NAME(pid) or "Player"
             self.name = name .. " Buttons"
        end
    end

    self.toggleSubmenu = Submenu.new("Player Toggles")
    self.toggleSubmenu.CustomRender = function() PlayerInfoComponent.Render() end
    self.toggleSubmenu.OnEnter = function(self)
        local pid = GetSelectedPlayerId()
        if pid >= 0 then
             local name = PLAYER.GET_PLAYER_NAME(pid) or "Player"
             self.name = name .. " Toggles"
        end
    end

    -- Removed local build button as requested
    -- self:AddOption(ButtonOption.new("Build Player Features")
    --     :AddFunction(BuildLuaPlayerMenus)
    --     :AddTooltip("Scan and build menus for player-specific Lua features"))

    -- Store option references for visibility
    self.buttonSubmenuOption = SubmenuOption.new("Buttons")
        :AddSubmenu(self.buttonSubmenu)
        :AddTooltip("Player function buttons")
    self.buttonSubmenuOption.visible = false
    self:AddOption(self.buttonSubmenuOption)

    self.toggleSubmenuOption = SubmenuOption.new("Toggles")
        :AddSubmenu(self.toggleSubmenu)
        :AddTooltip("Player toggle features")
    self.toggleSubmenuOption.visible = false
    self:AddOption(self.toggleSubmenuOption)

    self.redirectOption = SubmenuOption.new("Go to Main Menu/Lua Scripts")
    pcall(function()
        local LuaScriptsMenu = require("Impulse/ImpulseLua/submenus/lua_scripts_menu")
        self.redirectOption:AddSubmenu(LuaScriptsMenu.GetInstance())
    end)
    self.redirectOption:AddTooltip("Build/Load Luas")
    self.redirectOption.visible = false
    self:AddOption(self.redirectOption)
end

function PlayerLuaContentMenu:OnEnter()
    local hasContent = false
    if self.buttonSubmenuOption and self.buttonSubmenuOption.visible then hasContent = true end
    if self.toggleSubmenuOption and self.toggleSubmenuOption.visible then hasContent = true end
    
    if self.redirectOption then
        self.redirectOption.visible = not hasContent
    end
end


return PlayerLuaContentMenu
