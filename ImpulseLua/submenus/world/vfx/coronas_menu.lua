--[[
    Impulse Lua - VFX Coronas Menu
    Port of VFXCoronasMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local CoronasMenu = setmetatable({}, { __index = Submenu })
CoronasMenu.__index = CoronasMenu

local instance = nil

local vars = {
    screenSize = 1.0,
    worldSize = 1.0,
    intensity = 1.0,
    zBias = 0.0,
    innerColor = 1.0,
    outerColor = 1.0
}

function CoronasMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("VFX Coronas"), CoronasMenu)
        instance:Init()
    end
    return instance
end

function CoronasMenu:Init()
    self:AddOption(ButtonOption.new("Reset coronas VFX")
        :AddFunction(function()
            vars.screenSize = 1.0
            vars.worldSize = 1.0
            vars.intensity = 1.0
            vars.zBias = 0.0
        end)
        :AddTooltip("Reset coronas VFX"))

    self:AddOption(BreakOption.new(""))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Screen size")
        :AddNumberRef(vars, "screenSize", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Corona screen size"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "World size")
        :AddNumberRef(vars, "worldSize", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Corona world size"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Intensity")
        :AddNumberRef(vars, "intensity", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Corona intensity"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Z Bias")
        :AddNumberRef(vars, "zBias", "%.2f", 0.1)
        :AddMin(-100):AddMax(100)
        :AddTooltip("Corona Z bias"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Inner color multiplier")
        :AddNumberRef(vars, "innerColor", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Inner color multiplier"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Outer color multiplier")
        :AddNumberRef(vars, "outerColor", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Outer color multiplier"))
end

return CoronasMenu
