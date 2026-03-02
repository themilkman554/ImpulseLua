--[[
    Impulse Lua - Load Config Menu
    Lists saved profiles for loading.
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local ConfigMgr = require("Impulse/ImpulseLua/lib/config_mgr")

local LoadConfigMenu = setmetatable({}, { __index = Submenu })
LoadConfigMenu.__index = LoadConfigMenu

local instance = nil

--- Get Profiles path
---@return string
local function GetProfilesPath()
    return FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Impulse-main\\Profiles"
end

--- Get filename from path
---@param path string
---@return string
local function getFilenameFromPath(path)
    return path:match("([^/\\]+)$") or path
end

--- Remove file extension from filename
---@param filename string
---@return string
local function removeExtension(filename)
    return filename:match("(.+)%..+$") or filename
end

function LoadConfigMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Load Config"), LoadConfigMenu)
        instance:Init()
    end
    return instance
end

function LoadConfigMenu:Init()
    -- Refresh button
    self:AddOption(ButtonOption.new("Refresh List")
        :AddFunction(function()
            self:ClearOptions()
            self:Init()
            Renderer.Notify("Config list refreshed")
        end)
        :AddTooltip("Refresh the config list"))

    self:AddOption(BreakOption.new("Saved Configs"))

    local profilesPath = GetProfilesPath()
    local files = FileMgr.FindFiles(profilesPath, ".json", true)

    if files then
        for _, filePath in ipairs(files) do
            local filename = removeExtension(getFilenameFromPath(filePath))
            self:AddOption(ButtonOption.new(filename)
                :AddFunction(function()
                    if ConfigMgr.Load(filename) then
                        -- Successfully loaded
                    end
                end)
                :AddTooltip(filePath))
        end
    else
        self:AddOption(ButtonOption.new("No configs found")
            :AddTooltip("Save a config first"))
    end
end

function LoadConfigMenu:FeatureUpdate()
end

return LoadConfigMenu
