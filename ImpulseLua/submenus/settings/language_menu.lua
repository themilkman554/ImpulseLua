--[[
    Impulse Lua - Language Menu
    Port of languageMenu.cpp from Impulse C++
    
    Provides options to reset language and access the load languages submenu.
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local Translation = require("Impulse/ImpulseLua/lib/translation")

local LanguageMenu = setmetatable({}, { __index = Submenu })
LanguageMenu.__index = LanguageMenu

local instance = nil

function LanguageMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Language"), LanguageMenu)
        instance:Init()
    end
    return instance
end

--- Get the translations directory path
local function GetTranslationsPath()
    return FileMgr.GetMenuRootPath() .. "\\\\Lua\\\\Impulse\\\\Impulse-main\\\\Translations"
end

function LanguageMenu:Init()
    local LoadLanguageMenu = require("Impulse/ImpulseLua/submenus/settings/load_language_menu")
    
    self:AddOption(ButtonOption.new("Reset language")
        :AddFunction(function()
            Translation.Reset()
            -- Reset renderer font to default
            Renderer.Layout.textFont = 4
            Renderer.Notify("Reset language to English")
        end)
        :AddTooltip("Reset language to English"))
    
    self:AddOption(SubmenuOption.new("Load languages")
        :AddSubmenu(LoadLanguageMenu.GetInstance())
        :AddTooltip("Load saved languages"))
    
    self:AddOption(BreakOption.new("Tools"))
    
    self:AddOption(ButtonOption.new("Generate language file")
        :AddFunction(function()
            local outputPath = GetTranslationsPath() .. "\\\\generated.json"
            local success = Translation.Generate(outputPath)
            if success then
                Renderer.Notify("Generated: generated.json")
            else
                Renderer.Notify("~r~Failed to generate language file")
            end
        end)
        :AddTooltip("Scan all menu options and generate a fresh English template JSON"))
    
    self:AddOption(ButtonOption.new("Update language file")
        :AddFunction(function()
            if not Translation.IsLoaded() then
                Renderer.Notify("~r~No language file loaded")
                return
            end
            local existingPath = Translation.GetCurrentFilePath()
            local name = Translation.GetCurrentName()
            local outputPath = GetTranslationsPath() .. "\\\\" .. name .. "_updated.json"
            local success = Translation.Update(existingPath, outputPath)
            if success then
                Renderer.Notify("Updated: " .. name .. "_updated.json")
            else
                Renderer.Notify("~r~Failed to update language file")
            end
        end)
        :AddTooltip("Add new keys to the currently loaded translation file")
        :AddOnUpdate(function(opt)
            if Translation.IsLoaded() then
                opt.name = "Update " .. Translation.GetCurrentName()
            else
                opt.name = "Update language file"
            end
        end))
    
    self:AddOption(BreakOption.new("Info"))
    
    self:AddOption(ButtonOption.new("Current: English")
        :AddTooltip("Currently loaded translation")
        :AddOnUpdate(function(opt)
            if Translation.IsLoaded() then
                opt.name = "Current: " .. Translation.GetCurrentName()
            else
                opt.name = "Current: English"
            end
        end))
end

return LanguageMenu

