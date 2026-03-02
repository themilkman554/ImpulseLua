--[[
    Impulse Lua - Config Manager
    Handles saving and loading of menu profiles
]]

local json = require("Impulse/ImpulseLua/lib/json")
local Menu = require("Impulse/ImpulseLua/lib/menu")
local Settings = require("Impulse/ImpulseLua/lib/settings")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local ThemeLoaderMenu = require("Impulse/ImpulseLua/submenus/settings/theme_loader_menu")

local ConfigMgr = {}

--- Get Profiles path
---@return string
function ConfigMgr.GetProfilesPath()
    return FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Impulse-main\\Profiles"
end

--- Get Themes path (for checking theme existence)
---@return string
function ConfigMgr.GetThemesPath()
    return FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Impulse-main\\Themes"
end

--- Get filename from path
local function getFilenameFromPath(path)
    return path:match("([^/\\]+)$") or path
end

--- Remove file extension from filename
local function removeExtension(filename)
    return filename:match("(.+)%..+$") or filename
end

--- Get list of available profiles
---@return table Array of { name = string, value = string }
function ConfigMgr.GetProfiles()
    local profilesPath = ConfigMgr.GetProfilesPath()
    local files = FileMgr.FindFiles(profilesPath, ".json", true)
    local profiles = {}
    
    if files then
        for _, filePath in ipairs(files) do
            local name = removeExtension(getFilenameFromPath(filePath))
            table.insert(profiles, { name = name, value = name })
        end
    end
    
    return profiles
end

--- Recursive function to save options data
---@param submenu table The submenu to traverse
---@param data table The data table to populate
local function TraverseSave(submenu, data)
    if not submenu or not submenu.options then return end

    -- Use submenu name as a section key to avoid collisions between different menus
    local sectionName = submenu.name
    local section = data[sectionName] or {}
    data[sectionName] = section

    for _, option in ipairs(submenu.options) do
        -- Recurse into submenus
        if option.submenu then
            -- Exclude system submenus
            if option.name ~= "Menu theme" and option.name ~= "Configs" and option.name ~= "Language" then
                TraverseSave(option.submenu, data)
            end
        else
            -- Save option to the current submenu's section
            local name = option.name
            
            -- Standard Option with value (Toggle, Number, Scroll)
            if option.GetValue then
                 local value = option:GetValue()
                 if value ~= nil then
                    section[name] = value
                 end
                 
                 -- Handle separate toggles on scroll/number options if they exist
                 if option.GetToggle then
                     local toggleVal = option:GetToggle()
                     if toggleVal ~= nil then
                        section[name .. "_toggle"] = toggleVal
                     end
                 end
                 
                 -- Handle Scroll Index if different from Value (for Select/Scroll types)
                 if option.GetIndex then
                    section[name .. "_index"] = option:GetIndex()
                 end
            end
            
            -- Color Option
            if option.GetColor then
                local color = option:GetColor()
                if color then
                    section[name .. "_color"] = { r = color.r, g = color.g, b = color.b, a = color.a }
                end
            end
        end
    end
end

--- Recursive function to load options data
---@param submenu table The submenu to traverse
---@param data table The loaded data
local function TraverseLoad(submenu, data)
    if not submenu or not submenu.options then return end

    local sectionName = submenu.name
    local section = data[sectionName]
    
    -- Fallback: Check if the key exists at the root (for backward compatibility with old flat configs)
    local source = section or data

    for _, option in ipairs(submenu.options) do
        if option.submenu then
            if option.name ~= "Menu theme" and option.name ~= "Configs" and option.name ~= "Language" then
                TraverseLoad(option.submenu, data)
            end
        else
            local name = option.name
            
            -- Load standard value (Toggle, Number, Scroll Value)
            if source[name] ~= nil then
                if option.SetValue then
                    -- Safety: Only load if type matches or if it's a number-to-number/bool-to-bool etc.
                    -- Specifically prevent the boolean-to-number crash.
                    local val = source[name]
                    local isNumberOption = option.min ~= nil or option.max ~= nil or option.step ~= nil
                    
                    if isNumberOption and type(val) ~= "number" then
                         -- Skip invalid type for number option
                    else
                        option:SetValue(val)
                    end
                end
            end
            
            -- Load Toggle state for combined options
            if source[name .. "_toggle"] ~= nil and option.SetToggle then
                option:SetToggle(source[name .. "_toggle"])
            end
            
            -- Load Scroll Index
            if source[name .. "_index"] ~= nil and option.SetIndex then
                 option:SetIndex(source[name .. "_index"])
            end

            -- Load Color
            if source[name .. "_color"] ~= nil and option.SetColor then
                local c = source[name .. "_color"]
                if type(c) == "table" and c.r then
                    option:SetColor({ r = c.r, g = c.g, b = c.b, a = c.a })
                end
            end
        end
    end
end


--- Save Config
---@param name string Config name
function ConfigMgr.Save(name)
    local profilesPath = ConfigMgr.GetProfilesPath()
    FileMgr.CreateDir(profilesPath)

    local data = {}
    
    -- basic metadata
    data.Meta = {
        Version = Renderer.ScriptVersion,
        Date = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    -- Traverse from root
    if Menu.rootSubmenu then
        TraverseSave(Menu.rootSubmenu, data)
    end
    
    data.AutoLoad = {
        Enabled = Settings.AutoLoadConfig,
        ConfigName = Settings.AutoLoadConfigName,
        ThemeName = Settings.CurrentThemeName or Settings.AutoLoadThemeName
    }

    local content = json.encode(data)
    local file = io.open(profilesPath .. "\\" .. name .. ".json", "w")
    if file then
        file:write(content)
        file:close()
        Renderer.Notify("Config saved: " .. name)
        return true
    else
        Renderer.Notify("~r~Failed to save config")
        return false
    end
end

--- Load Config
---@param name string Config name
function ConfigMgr.Load(name)
    local path = ConfigMgr.GetProfilesPath() .. "\\" .. name .. ".json"
    local file = io.open(path, "r")
    if not file then
        Renderer.Notify("~r~Config not found: " .. name)
        return false
    end
    
    local content = file:read("*a")
    file:close()
    
    local status, data = pcall(json.decode, content)
    if not status or not data then
        Renderer.Notify("~r~Failed to parse config")
        return false
    end
    
    -- Load Options
    if Menu.rootSubmenu then
        TraverseLoad(Menu.rootSubmenu, data)
    end
    
    -- Load Theme if specified and requested
    if data.AutoLoad and data.AutoLoad.ThemeName and data.AutoLoad.ThemeName ~= "" then
         local themePath = ConfigMgr.GetThemesPath() .. "\\" .. data.AutoLoad.ThemeName .. ".json"
         if FileMgr.DoesFileExist(themePath) then
             ThemeLoaderMenu.LoadTheme(themePath)
         end
    end
    
    -- Restore AutoLoad settings from file
    if data.AutoLoad then
        if data.AutoLoad.Enabled ~= nil then Settings.AutoLoadConfig = data.AutoLoad.Enabled end
        if data.AutoLoad.ConfigName ~= nil then Settings.AutoLoadConfigName = data.AutoLoad.ConfigName end
        if data.AutoLoad.ThemeName ~= nil then Settings.AutoLoadThemeName = data.AutoLoad.ThemeName end
    end

    Renderer.Notify("Config loaded: " .. name)
    return true
end

--- Auto Load on Startup
function ConfigMgr.AutoLoad()
    local settingsPath = FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Impulse-main\\settings.json"
    local file = io.open(settingsPath, "r")
    if file then
        local content = file:read("*a")
        file:close()
        local status, globalSettings = pcall(json.decode, content)
        if status and globalSettings then
            -- Restore global settings
            if globalSettings.OpenKey then Settings.OpenKey = globalSettings.OpenKey end
            if globalSettings.MouseEnabled ~= nil then Settings.MouseEnabled = globalSettings.MouseEnabled end
            if globalSettings.MouseMoveEnabled ~= nil then Settings.MouseMoveEnabled = globalSettings.MouseMoveEnabled end
            
            -- Load auto-load config if enabled
            if globalSettings.AutoLoadConfig and globalSettings.AutoLoadConfigName then
                 ConfigMgr.Load(globalSettings.AutoLoadConfigName)
            end
        end
    end
end

--- Save Global Settings (for AutoLoad persistence)
function ConfigMgr.SaveGlobalSettings()
     local data = {
        AutoLoadConfig = Settings.AutoLoadConfig,
        AutoLoadConfigName = Settings.AutoLoadConfigName,
        OpenKey = Settings.OpenKey,
        MouseEnabled = Settings.MouseEnabled,
        MouseMoveEnabled = Settings.MouseMoveEnabled
     }
     
     local settingsPath = FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Impulse-main\\settings.json"
     local file = io.open(settingsPath, "w")
     if file then
        file:write(json.encode(data))
        file:close()
     end
end

--- Reset Global Settings to defaults
function ConfigMgr.ResetGlobalSettings()
    local settingsPath = FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Impulse-main\\settings.json"
    -- Overwrite with empty object or default values
    local file = io.open(settingsPath, "w")
    if file then
        file:write("{}")
        file:close()
    end
end

return ConfigMgr
