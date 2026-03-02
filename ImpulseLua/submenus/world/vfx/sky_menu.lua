--[[
    Impulse Lua - VFX Sky Menu
    Port of VFXSkyMenuVars.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ColorOption = require("Impulse/ImpulseLua/lib/options/color")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local SkyMenu = setmetatable({}, { __index = Submenu })
SkyMenu.__index = SkyMenu

local instance = nil

local vars = {
    -- Sun
    sunIntensity = 1.0,
    sunSize = 1.0,
    sunColor = { r = 255, g = 230, b = 180, a = 255 },
    -- Moon
    moonIntensity = 1.0,
    moonSize = 1.0,
    -- Sky
    skyIntensity = 1.0,
    horizonIntensity = 1.0,
    -- Stars
    starIntensity = 1.0,
    starDensity = 1.0
}

function SkyMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("VFX Sky"), SkyMenu)
        instance:Init()
    end
    return instance
end

function SkyMenu:Init()
    self:AddOption(ButtonOption.new("Reset sky VFX")
        :AddFunction(function()
            vars.sunIntensity = 1.0
            vars.sunSize = 1.0
            vars.moonIntensity = 1.0
            vars.moonSize = 1.0
            vars.skyIntensity = 1.0
            vars.horizonIntensity = 1.0
            vars.starIntensity = 1.0
            vars.starDensity = 1.0
        end)
        :AddTooltip("Reset sky VFX"))

    self:AddOption(BreakOption.new("Sun"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Sun intensity")
        :AddNumberRef(vars, "sunIntensity", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Sun intensity"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Sun size")
        :AddNumberRef(vars, "sunSize", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Sun size"))

    self:AddOption(ColorOption.new("Sun color")
        :AddColor(vars.sunColor)
        :AddTooltip("Sun color"))

    self:AddOption(BreakOption.new("Moon"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Moon intensity")
        :AddNumberRef(vars, "moonIntensity", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Moon intensity"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Moon size")
        :AddNumberRef(vars, "moonSize", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Moon size"))

    self:AddOption(BreakOption.new("Sky"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Sky intensity")
        :AddNumberRef(vars, "skyIntensity", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Sky intensity"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Horizon intensity")
        :AddNumberRef(vars, "horizonIntensity", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Horizon intensity"))

    self:AddOption(BreakOption.new("Stars"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Star intensity")
        :AddNumberRef(vars, "starIntensity", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Star intensity"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Star density")
        :AddNumberRef(vars, "starDensity", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Star density"))
end

return SkyMenu
