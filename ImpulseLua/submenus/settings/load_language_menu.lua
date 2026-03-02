--[[
    Impulse Lua - Load Language Menu
    Port of loadLanguageMenu.cpp from Impulse C++
    
    Discovers .json translation files from Impulse-main/Translations/
    and allows the user to load them.
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local Translation = require("Impulse/ImpulseLua/lib/translation")

local LoadLanguageMenu = setmetatable({}, { __index = Submenu })
LoadLanguageMenu.__index = LoadLanguageMenu

local instance = nil

--- Get the translations directory path
---@return string
local function GetTranslationsPath()
    return FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Impulse-main\\Translations"
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

function LoadLanguageMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Load languages"), LoadLanguageMenu)
        instance:Init()
    end
    return instance
end

function LoadLanguageMenu:Init()
    -- Refresh button
    self:AddOption(ButtonOption.new("Refresh list")
        :AddFunction(function()
            self:ClearOptions()
            self:Init()
            Renderer.Notify("Language list refreshed")
        end)
        :AddTooltip("Refresh the language file list"))
    
    self:AddOption(BreakOption.new("Available Languages"))
    
    self:ScanAndAddFiles()
end

--- Scan the translations directory and add button options for each .json file
function LoadLanguageMenu:ScanAndAddFiles()
    local translationsPath = GetTranslationsPath()
    
    if not FileMgr.FindFiles then
        self:AddOption(ButtonOption.new("Error: FileMgr.FindFiles missing")
            :AddTooltip("File scanning API not available"))
        return
    end
    
    local files = FileMgr.FindFiles(translationsPath, ".json", true)
    
    if files and #files > 0 then
        for _, filePath in ipairs(files) do
            local filename = removeExtension(getFilenameFromPath(filePath))
            self:AddOption(ButtonOption.new(filename)
                :AddFunction(function()
                    local success = Translation.Load(filePath)
                    if success then
                        -- Apply font if specified
                        local font = Translation.GetFont()
                        if font >= 0 then
                            Renderer.Layout.textFont = font
                        end
                        Renderer.Notify("Loaded language: " .. filename)
                    else
                        Renderer.Notify("~r~Failed to load: " .. filename)
                    end
                end)
                :AddTooltip("Load " .. filename .. " translation"))
        end
    else
        self:AddOption(ButtonOption.new("~c~No translation files found")
            :AddTooltip("Add .json translation files to " .. translationsPath))
    end
end

return LoadLanguageMenu
