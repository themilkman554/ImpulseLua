--[[
    Impulse Lua - VFX Train Menu
    Port of VFXTrainMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ColorOption = require("Impulse/ImpulseLua/lib/options/color")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local TrainMenu = setmetatable({}, { __index = Submenu })
TrainMenu.__index = TrainMenu

local instance = nil

local vars = {
    intensity = 1.0,
    radius = 1.0,
    falloffExponent = 1.0,
    color = { r = 255, g = 200, b = 100, a = 255 }
}

function TrainMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("VFX Train"), TrainMenu)
        instance:Init()
    end
    return instance
end

function TrainMenu:Init()
    self:AddOption(ButtonOption.new("Reset train VFX")
        :AddFunction(function()
            vars.intensity = 1.0
            vars.radius = 1.0
            vars.falloffExponent = 1.0
            vars.color = { r = 255, g = 200, b = 100, a = 255 }
        end)
        :AddTooltip("Reset train VFX"))

    self:AddOption(BreakOption.new(""))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Intensity")
        :AddNumberRef(vars, "intensity", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Train light intensity"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Radius")
        :AddNumberRef(vars, "radius", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Train light radius"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Falloff exponent")
        :AddNumberRef(vars, "falloffExponent", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Train light falloff exponent"))

    self:AddOption(ColorOption.new("Train light color")
        :AddColor(vars.color)
        :AddTooltip("Train light color"))
end

return TrainMenu
