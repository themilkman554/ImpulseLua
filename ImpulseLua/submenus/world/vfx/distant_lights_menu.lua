--[[
    Impulse Lua - VFX Distant Lights Menu
    Port of VFXDistantLightsMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ColorOption = require("Impulse/ImpulseLua/lib/options/color")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local DistantLightsMenu = setmetatable({}, { __index = Submenu })
DistantLightsMenu.__index = DistantLightsMenu

local instance = nil

local vars = {
    intensity = 1.0,
    size = 1.0,
    falloff = 1.0,
    density = 1.0,
    color = { r = 255, g = 230, b = 200, a = 255 }
}

function DistantLightsMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("VFX Distant lights"), DistantLightsMenu)
        instance:Init()
    end
    return instance
end

function DistantLightsMenu:Init()
    self:AddOption(ButtonOption.new("Reset distant lights VFX")
        :AddFunction(function()
            vars.intensity = 1.0
            vars.size = 1.0
            vars.falloff = 1.0
            vars.density = 1.0
        end)
        :AddTooltip("Reset distant lights VFX"))

    self:AddOption(BreakOption.new(""))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Intensity")
        :AddNumberRef(vars, "intensity", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Distant lights intensity"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Size")
        :AddNumberRef(vars, "size", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Distant lights size"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Falloff")
        :AddNumberRef(vars, "falloff", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Distant lights falloff"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Density")
        :AddNumberRef(vars, "density", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Distant lights density"))

    self:AddOption(ColorOption.new("Light color")
        :AddColor(vars.color)
        :AddTooltip("Distant light color"))
end

return DistantLightsMenu
