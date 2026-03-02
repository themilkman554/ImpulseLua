--[[
    Impulse Lua - VFX Puddles Menu
    Port of VFXPuddlesMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local PuddlesMenu = setmetatable({}, { __index = Submenu })
PuddlesMenu.__index = PuddlesMenu

local instance = nil

local vars = {
    intensity = 1.0,
    size = 1.0,
    rippleSpeed = 1.0,
    rippleIntensity = 1.0,
    reflectivity = 1.0
}

function PuddlesMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("VFX Rain puddles"), PuddlesMenu)
        instance:Init()
    end
    return instance
end

function PuddlesMenu:Init()
    self:AddOption(ButtonOption.new("Reset puddles VFX")
        :AddFunction(function()
            vars.intensity = 1.0
            vars.size = 1.0
            vars.rippleSpeed = 1.0
            vars.rippleIntensity = 1.0
            vars.reflectivity = 1.0
        end)
        :AddTooltip("Reset puddles VFX"))

    self:AddOption(BreakOption.new(""))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Intensity")
        :AddNumberRef(vars, "intensity", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Puddle intensity"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Size")
        :AddNumberRef(vars, "size", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Puddle size"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Ripple speed")
        :AddNumberRef(vars, "rippleSpeed", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Puddle ripple speed"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Ripple intensity")
        :AddNumberRef(vars, "rippleIntensity", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Puddle ripple intensity"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Reflectivity")
        :AddNumberRef(vars, "reflectivity", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Puddle reflectivity"))
end

return PuddlesMenu
