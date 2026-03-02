--[[
    Impulse Lua - LSC Lights Menu
    Port of vehicleLightsMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")


local LightsMenu = setmetatable({}, { __index = Submenu })
LightsMenu.__index = LightsMenu

local instance = nil

-- Xenon light colors
local xenonColors = {
    { name = "Default", value = 0 },
    { name = "Blue", value = 2 },
    { name = "Electric Blue", value = 3 },
    { name = "Mint Green", value = 4 },
    { name = "Lime Green", value = 5 },
    { name = "Yellow", value = 6 },
    { name = "Golden Shower", value = 7 },
    { name = "Orange", value = 8 },
    { name = "Red", value = 9 },
    { name = "Pink", value = 10 },
    { name = "Hot Pink", value = 11 },
    { name = "Purple", value = 12 },
    { name = "Backlight", value = 13 }
}

local vars = {
    xenonLights = false,
    xenonColorIndex = 1,
    rainbowXenon = false,
    rainbowNeons = false,
    neonLeft = false,
    neonRight = false,
    neonFront = false,
    neonBack = false,
    neonR = 255,
    neonG = 0,
    neonB = 0
}

-- Helper: Check if player is in vehicle
local function IsInVehicle()
    local ped = PLAYER.PLAYER_PED_ID()
    return PED.IS_PED_IN_ANY_VEHICLE(ped, false)
end

-- Helper: Get current vehicle
local function GetCurrentVehicle()
    local ped = PLAYER.PLAYER_PED_ID()
    return PED.GET_VEHICLE_PED_IS_IN(ped, false)
end

-- Rainbow xenon effect
local xenonTimer = 0
local function RainbowXenons()
    if not IsInVehicle() then return end
    local now = MISC.GET_GAME_TIMER()
    if now - xenonTimer > 200 then
        xenonTimer = now
        local veh = GetCurrentVehicle()
        local randomColor = MISC.GET_RANDOM_INT_IN_RANGE(2, 13)
        VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(veh, randomColor)
    end
end

-- Rainbow neon effect
local function RainbowNeons()
    if not IsInVehicle() then return end
    local veh = GetCurrentVehicle()
    
    if vars.neonR > 0 and vars.neonB == 0 then
        vars.neonR = vars.neonR - 1
        vars.neonG = vars.neonG + 1
    end
    if vars.neonG > 0 and vars.neonR == 0 then
        vars.neonG = vars.neonG - 1
        vars.neonB = vars.neonB + 1
    end
    if vars.neonB > 0 and vars.neonG == 0 then
        vars.neonR = vars.neonR + 1
        vars.neonB = vars.neonB - 1
    end
    
    VEHICLE.SET_VEHICLE_NEON_COLOUR(veh, vars.neonR, vars.neonG, vars.neonB)
end

function LightsMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Lights"), LightsMenu)
        instance:Init()
    end
    return instance
end

function LightsMenu:Init()
    -- Xenon lights toggle
    self:AddOption(ToggleOption.new("Xenon lights")
        :AddToggleRef(vars, "xenonLights")
        :AddRequirement(IsInVehicle)
        :AddOnUpdate(function(opt)
            if IsInVehicle() then
                vars.xenonLights = VEHICLE.IS_TOGGLE_MOD_ON(GetCurrentVehicle(), 22)
            end
        end)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.TOGGLE_VEHICLE_MOD(GetCurrentVehicle(), 22, vars.xenonLights)
            end
        end)
        :AddTooltip("Toggle xenon headlights")
        :SetDonor())
    
    -- Xenon color
    local colorNames = {}
    for i, c in ipairs(xenonColors) do
        colorNames[i] = c.name
    end
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Xenon color")
        :AddScroll(colorNames, 1)
        :AddIndexRef(vars, "xenonColorIndex")
        :CanLoop()
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            if IsInVehicle() then
                local colorValue = xenonColors[vars.xenonColorIndex].value
                VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(GetCurrentVehicle(), colorValue)
            end
        end)
        :AddTooltip("Set xenon light color")
        :SetDonor())
    
    -- Rainbow xenon
    self:AddOption(ToggleOption.new("Rainbow xenon lights")
        :AddToggleRef(vars, "rainbowXenon")
        :AddTooltip("Cycle through xenon colors")
        :SetDonor())
    
    -- Neon section
    self:AddOption(BreakOption.new("Neon"))
    
    -- Neon color RGB
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Neon Red")
        :AddNumberRef(vars, "neonR", "%d", 5)
        :AddMin(0):AddMax(255)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_NEON_COLOUR(GetCurrentVehicle(), vars.neonR, vars.neonG, vars.neonB)
            end
        end)
        :AddTooltip("Set neon red value")
        :SetDonor())
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Neon Green")
        :AddNumberRef(vars, "neonG", "%d", 5)
        :AddMin(0):AddMax(255)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_NEON_COLOUR(GetCurrentVehicle(), vars.neonR, vars.neonG, vars.neonB)
            end
        end)
        :AddTooltip("Set neon green value")
        :SetDonor())
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Neon Blue")
        :AddNumberRef(vars, "neonB", "%d", 5)
        :AddMin(0):AddMax(255)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_NEON_COLOUR(GetCurrentVehicle(), vars.neonR, vars.neonG, vars.neonB)
            end
        end)
        :AddTooltip("Set neon blue value")
        :SetDonor())
    
    -- Rainbow neons
    self:AddOption(ToggleOption.new("Rainbow neon lights")
        :AddToggleRef(vars, "rainbowNeons")
        :AddFunction(function()
            if vars.rainbowNeons then
                vars.neonR = 255
                vars.neonG = 0
                vars.neonB = 0
            end
        end)
        :AddTooltip("Cycle through neon colors")
        :SetDonor())
    
    -- Neon positions
    self:AddOption(ToggleOption.new("Neon Left")
        :AddToggleRef(vars, "neonLeft")
        :AddRequirement(IsInVehicle)
        :AddOnUpdate(function(opt)
            if IsInVehicle() then
                vars.neonLeft = VEHICLE.GET_VEHICLE_NEON_ENABLED(GetCurrentVehicle(), 0)
            end
        end)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_NEON_ENABLED(GetCurrentVehicle(), 0, vars.neonLeft)
            end
        end)
        :AddTooltip("Toggle left neon")
        :SetDonor())
    
    self:AddOption(ToggleOption.new("Neon Right")
        :AddToggleRef(vars, "neonRight")
        :AddRequirement(IsInVehicle)
        :AddOnUpdate(function(opt)
            if IsInVehicle() then
                vars.neonRight = VEHICLE.GET_VEHICLE_NEON_ENABLED(GetCurrentVehicle(), 1)
            end
        end)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_NEON_ENABLED(GetCurrentVehicle(), 1, vars.neonRight)
            end
        end)
        :AddTooltip("Toggle right neon")
        :SetDonor())
    
    self:AddOption(ToggleOption.new("Neon Front")
        :AddToggleRef(vars, "neonFront")
        :AddRequirement(IsInVehicle)
        :AddOnUpdate(function(opt)
            if IsInVehicle() then
                vars.neonFront = VEHICLE.GET_VEHICLE_NEON_ENABLED(GetCurrentVehicle(), 2)
            end
        end)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_NEON_ENABLED(GetCurrentVehicle(), 2, vars.neonFront)
            end
        end)
        :AddTooltip("Toggle front neon")
        :SetDonor())
    
    self:AddOption(ToggleOption.new("Neon Back")
        :AddToggleRef(vars, "neonBack")
        :AddRequirement(IsInVehicle)
        :AddOnUpdate(function(opt)
            if IsInVehicle() then
                vars.neonBack = VEHICLE.GET_VEHICLE_NEON_ENABLED(GetCurrentVehicle(), 3)
            end
        end)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_NEON_ENABLED(GetCurrentVehicle(), 3, vars.neonBack)
            end
        end)
        :AddTooltip("Toggle back neon")
        :SetDonor())
end

function LightsMenu:FeatureUpdate()
    if vars.rainbowXenon then RainbowXenons() end
    if vars.rainbowNeons then RainbowNeons() end
end

return LightsMenu
