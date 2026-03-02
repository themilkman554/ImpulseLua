--[[
    Impulse Lua - VFX Vehicle Menu
    Port of VFXVehicleMenu.cpp
    
    NOTE: Original C++ uses GetVFX()->GetVehicle() memory access.
    This Lua version provides the menu structure with placeholder values.
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local VehicleMenu = setmetatable({}, { __index = Submenu })
VehicleMenu.__index = VehicleMenu

local instance = nil

-- Variables (placeholder values)
local vars = {
    fadeDistance = 100.0,
    headLightAngle = 1.0,
    headLightSplit = 1.0,
    headlightDistance = 100.0,
    headlightIntensity = 1.0,
    headlightPlayerDistance = 100.0,
    headlightPlayerExponent = 1.0,
    headlightPlayerIntensity = 1.0,
    -- Neon
    neonIntensity = 1.0,
    neonRadius = 1.0,
    neonExtendSides = 1.0,
    neonExtentFront = 1.0,
    neonFalloffExponent = 1.0,
    neonClippingPaneHeight = 0.0
}

function VehicleMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("VFX Vehicle"), VehicleMenu)
        instance:Init()
    end
    return instance
end

function VehicleMenu:Init()
    self:AddOption(ButtonOption.new("Reset vehicle VFX")
        :AddFunction(function()
            -- Reset to defaults
            vars.fadeDistance = 100.0
            vars.headLightAngle = 1.0
            vars.headLightSplit = 1.0
            vars.headlightDistance = 100.0
            vars.headlightIntensity = 1.0
        end)
        :AddTooltip("Reset vehicle VFX"))

    self:AddOption(ButtonOption.new("Load vehicle VFX settings")
        :AddTooltip("Load vehicle VFX settings (Not implemented)"))

    self:AddOption(ButtonOption.new("Save vehicle VFX settings")
        :AddTooltip("Save vehicle VFX settings (Not implemented)"))

    self:AddOption(BreakOption.new(""))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Fade distance")
        :AddNumberRef(vars, "fadeDistance", "%.2f", 1.0)
        :AddMin(0):AddMax(1000)
        :AddTooltip("Fade distance"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Headlight angle")
        :AddNumberRef(vars, "headLightAngle", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Headlight angle"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Headlight split")
        :AddNumberRef(vars, "headLightSplit", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Headlight split"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Headlight distance")
        :AddNumberRef(vars, "headlightDistance", "%.2f", 0.1)
        :AddMin(0):AddMax(1000)
        :AddTooltip("Headlight distance"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Headlight intensity")
        :AddNumberRef(vars, "headlightIntensity", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Headlight intensity"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Player headlight distance")
        :AddNumberRef(vars, "headlightPlayerDistance", "%.2f", 0.1)
        :AddMin(0):AddMax(1000)
        :AddTooltip("Player headlight distance"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Player headlight exponent")
        :AddNumberRef(vars, "headlightPlayerExponent", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Player headlight exponent"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Player headlight intensity")
        :AddNumberRef(vars, "headlightPlayerIntensity", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Player headlight intensity"))

    self:AddOption(BreakOption.new("Neon"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Neon intensity")
        :AddNumberRef(vars, "neonIntensity", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Neon intensity"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Neon radius")
        :AddNumberRef(vars, "neonRadius", "%.2f", 0.1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Neon radius"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Neon extended sides")
        :AddNumberRef(vars, "neonExtendSides", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Neon side width"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Neon extended front")
        :AddNumberRef(vars, "neonExtentFront", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Neon front width"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Neon falloff exponent")
        :AddNumberRef(vars, "neonFalloffExponent", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Neon falloff exponent"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Neon clipping pane height")
        :AddNumberRef(vars, "neonClippingPaneHeight", "%.2f", 0.1)
        :AddMin(-10):AddMax(10)
        :AddTooltip("Neon clipping pane height"))
end

return VehicleMenu
