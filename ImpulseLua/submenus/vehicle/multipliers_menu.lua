--[[
    Impulse Lua - Vehicle Multipliers Menu
    Port of vehicleMultipliers.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local MultipliersMenu = setmetatable({}, { __index = Submenu })
MultipliersMenu.__index = MultipliersMenu

local instance = nil

local vars = {
    rpm = 0,
    light = 0,
    torque = 0,
    accelerationEnabled = false,
    accelerationVal = 1.0,
    brakeEnabled = false,
    brakeVal = 1.0,
    suspensionEnabled = false,
    suspensionVal = 0.5
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

function MultipliersMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Vehicle multipliers"), MultipliersMenu)
        instance:Init()
    end
    return instance
end

function MultipliersMenu:Init()
    -- RPM
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "RPM")
        :AddNumberRef(vars, "rpm", "%d", 10)
        :AddMin(0):AddMax(10000)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(GetCurrentVehicle(), vars.rpm + 1.0)
            end
        end)
        :AddTooltip("Set the engine power multiplier"))
    
    -- Light multiplier
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Light")
        :AddNumberRef(vars, "light", "%d", 1)
        :AddMin(0):AddMax(100)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(GetCurrentVehicle(), vars.light + 0.0)
            end
        end)
        :AddTooltip("Set the light intensity"))
    
    -- Torque
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Torque")
        :AddNumberRef(vars, "torque", "%d", 10)
        :AddMin(0):AddMax(10000)
        :AddTooltip("Set the torque multiplier"))
    
    -- Acceleration
    self:AddOption(ToggleOption.new("Acceleration boost")
        :AddToggleRef(vars, "accelerationEnabled")
        :AddTooltip("Enable acceleration boost"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Acceleration value")
        :AddNumberRef(vars, "accelerationVal", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Acceleration force value"))
    
    -- Brake
    self:AddOption(ToggleOption.new("Brake boost")
        :AddToggleRef(vars, "brakeEnabled")
        :AddTooltip("Enable brake boost"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Brake value")
        :AddNumberRef(vars, "brakeVal", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Brake force value"))
    
    -- Suspension
    self:AddOption(ToggleOption.new("Suspension boost")
        :AddToggleRef(vars, "suspensionEnabled")
        :AddTooltip("Enable suspension boost"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Suspension value")
        :AddNumberRef(vars, "suspensionVal", "%.2f", 0.1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Suspension force value"))
end

function MultipliersMenu:FeatureUpdate()
    if not IsInVehicle() then return end
    local veh = GetCurrentVehicle()
    
    -- Torque multiplier
    if vars.torque > 0 then
        VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(veh, vars.torque + 1.0)
    end
    
    -- Acceleration boost
    if vars.accelerationEnabled then
        local accelerating = Utils.IsKeyPressed(0x57) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 71)
        if accelerating and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(veh) then
            ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0, vars.accelerationVal / 10, 0, 0, 0, 0, 0, true, true, true, false, true)
        end
    end
    
    -- Brake boost
    if vars.brakeEnabled then
        local braking = Utils.IsKeyPressed(0x53) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 72)
        if braking and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(veh) then
            ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0, -(vars.brakeVal / 10), 0, 0, 0, 0, 0, true, true, true, false, true)
        end
    end
    
    -- Suspension boost
    if vars.suspensionEnabled then
        ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0, 0, vars.suspensionVal / 10, 0, 0, 0, 0, true, true, true, false, true)
    end
end

return MultipliersMenu
