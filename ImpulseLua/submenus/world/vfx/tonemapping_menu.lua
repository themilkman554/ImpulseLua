--[[
    Impulse Lua - VFX Tonemapping Menu
    Port of VFXTonemappingMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local TonemappingMenu = setmetatable({}, { __index = Submenu })
TonemappingMenu.__index = TonemappingMenu

local instance = nil

local vars = {
    exposure = 1.0,
    brightness = 1.0,
    contrast = 1.0,
    filmic_a = 0.22,
    filmic_b = 0.30,
    filmic_c = 0.10,
    filmic_d = 0.20,
    filmic_e = 0.01,
    filmic_f = 0.30,
    filmic_w = 11.2
}

function TonemappingMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("VFX Tone mapping"), TonemappingMenu)
        instance:Init()
    end
    return instance
end

function TonemappingMenu:Init()
    self:AddOption(ButtonOption.new("Reset tonemapping VFX")
        :AddFunction(function()
            vars.exposure = 1.0
            vars.brightness = 1.0
            vars.contrast = 1.0
        end)
        :AddTooltip("Reset tonemapping VFX"))

    self:AddOption(BreakOption.new("Basic"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Exposure")
        :AddNumberRef(vars, "exposure", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Exposure"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Brightness")
        :AddNumberRef(vars, "brightness", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Brightness"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Contrast")
        :AddNumberRef(vars, "contrast", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Contrast"))

    self:AddOption(BreakOption.new("Filmic Curve"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Filmic A")
        :AddNumberRef(vars, "filmic_a", "%.2f", 0.01)
        :AddMin(0):AddMax(1)
        :AddTooltip("Shoulder Strength"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Filmic B")
        :AddNumberRef(vars, "filmic_b", "%.2f", 0.01)
        :AddMin(0):AddMax(1)
        :AddTooltip("Linear Strength"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Filmic C")
        :AddNumberRef(vars, "filmic_c", "%.2f", 0.01)
        :AddMin(0):AddMax(1)
        :AddTooltip("Linear Angle"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Filmic D")
        :AddNumberRef(vars, "filmic_d", "%.2f", 0.01)
        :AddMin(0):AddMax(1)
        :AddTooltip("Toe Strength"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Filmic E")
        :AddNumberRef(vars, "filmic_e", "%.2f", 0.01)
        :AddMin(0):AddMax(1)
        :AddTooltip("Toe Numerator"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Filmic F")
        :AddNumberRef(vars, "filmic_f", "%.2f", 0.01)
        :AddMin(0):AddMax(1)
        :AddTooltip("Toe Denominator"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Filmic W")
        :AddNumberRef(vars, "filmic_w", "%.1f", 0.1)
        :AddMin(0):AddMax(50)
        :AddTooltip("Linear White Point"))
end

return TonemappingMenu
