--[[
    Impulse Lua - Load Custom Header Menu
    Port of loadCustomHeaderMenu.cpp
    Loads custom PNG headers from Textures/customheader
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local Menu = require("Impulse/ImpulseLua/lib/menu")


local LoadCustomHeaderMenu = setmetatable({}, { __index = Submenu })
LoadCustomHeaderMenu.__index = LoadCustomHeaderMenu

local instance = nil

function LoadCustomHeaderMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Custom headers"), LoadCustomHeaderMenu)
        instance:Init()
    end
    return instance
end

function LoadCustomHeaderMenu:Init()
    -- Load on startup toggle
    self:AddOption(ToggleOption.new("Load selected custom header on startup")
        :AddToggle(function() return self.loadOnStart end, function(val) 
            self.loadOnStart = val
            -- Save config here if needed
        end)
        :AddTooltip("Load the selected custom header on startup"))

    self:AddOption(BreakOption.new())

    -- Refresh button
    self:AddOption(ButtonOption.new("Refresh List")
        :AddFunction(function()
            self:ClearOptions()
            self:Init()
            Renderer.Notify("Header list refreshed")
        end)
        :AddTooltip("Refresh the custom header list"))

    self:AddOption(BreakOption.new("Custom Headers"))

    -- Scan for PNG files
    local rootPath = FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Textures\\customheader"


    if FileMgr.DoesDirectoryExist and not FileMgr.DoesDirectoryExist(rootPath) then
        if FileMgr.CreateDir then
            FileMgr.CreateDir(rootPath)
        end
    end

    if FileMgr.FindFiles then
        local files = FileMgr.FindFiles(rootPath, ".png", false)
        
        if files then
            for _, filePath in ipairs(files) do
                -- Extract filename from path
                local fileName = filePath:match("([^\\/]+)%.png$")
                if fileName then
                    self:AddOption(ButtonOption.new(fileName)
                        :AddFunction(function()
                            -- Set header using ThemeMenu helper to ensure animations are disabled
                            local ThemeMenu = require("Impulse/ImpulseLua/submenus/settings/theme_menu")
                            ThemeMenu.SetCustomHeader("Bookmarks", "customheader/" .. fileName)
                            
                            -- Preload
                            local success, srv = pcall(Renderer.GetImGuiTexture, "customheader/" .. fileName)
                            
                            if success and srv then
                                Renderer.Notify("Header Loaded: " .. fileName)
                            else
                                Renderer.Notify("Failed to load header")
                            end
                        end)
                        :AddTooltip(fileName))
                end
            end
        else
            self:AddOption(ButtonOption.new("No .png files found")
                :AddTooltip("Add .png files to " .. rootPath))
        end
    else
        self:AddOption(ButtonOption.new("Error: FileMgr missing"))
    end
end

return LoadCustomHeaderMenu
