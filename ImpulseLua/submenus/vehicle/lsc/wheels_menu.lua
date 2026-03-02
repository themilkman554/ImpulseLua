--[[
    Impulse Lua - LSC Wheels Menu
    Port of vehicleWheelsMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local WheelsMenu = setmetatable({}, { __index = Submenu })
WheelsMenu.__index = WheelsMenu

local instance = nil

-- Wheel types
local wheelTypes = {
    { name = "Sport", value = 0 },
    { name = "Muscle", value = 1 },
    { name = "Lowrider", value = 2 },
    { name = "SUV", value = 3 },
    { name = "Offroad", value = 4 },
    { name = "Tuner", value = 5 },
    { name = "Bike Wheels", value = 6 },
    { name = "High End", value = 7 },
    { name = "Benny's", value = 8 },
    { name = "Benny's 2", value = 9 },
    { name = "F1", value = 10 }
}

-- Mod constants
local MOD_FRONTWHEELS = 23
local MOD_BACKWHEELS = 24
local MOD_TIRESMOKE = 20

local vars = {
    tireSmoke = false,
    tireSmokeR = 255,
    tireSmokeG = 255,
    tireSmokeB = 255,
    bulletproofWheels = false,
    wheelTypeIndex = 1,
    frontWheelIndex = 0,
    rearWheelIndex = 0
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

-- Helper: Check if vehicle is a bike
local function IsBike()
    if not IsInVehicle() then return false end
    local model = ENTITY.GET_ENTITY_MODEL(GetCurrentVehicle())
    return VEHICLE.IS_THIS_MODEL_A_BIKE(model)
end

function WheelsMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Wheels"), WheelsMenu)
        instance:Init()
    end
    return instance
end

function WheelsMenu:Init()
    -- Tire smoke toggle
    self:AddOption(ToggleOption.new("Tire smoke")
        :AddToggleRef(vars, "tireSmoke")
        :AddRequirement(IsInVehicle)
        :AddOnUpdate(function(opt)
            if IsInVehicle() then
                vars.tireSmoke = VEHICLE.IS_TOGGLE_MOD_ON(GetCurrentVehicle(), MOD_TIRESMOKE)
            end
        end)
        :AddFunction(function()
            if IsInVehicle() then
                local veh = GetCurrentVehicle()
                VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
                VEHICLE.TOGGLE_VEHICLE_MOD(veh, MOD_TIRESMOKE, vars.tireSmoke)
            end
        end)
        :AddTooltip("Toggle tire smoke mod")
        :SetDonor())
    
    -- Tire smoke color
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Smoke Red")
        :AddNumberRef(vars, "tireSmokeR", "%d", 5)
        :AddMin(0):AddMax(255)
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            if IsInVehicle() then
                local veh = GetCurrentVehicle()
                VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
                VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(veh, vars.tireSmokeR, vars.tireSmokeG, vars.tireSmokeB)
            end
        end)
        :AddTooltip("Set tire smoke red")
        :SetDonor())
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Smoke Green")
        :AddNumberRef(vars, "tireSmokeG", "%d", 5)
        :AddMin(0):AddMax(255)
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(GetCurrentVehicle(), vars.tireSmokeR, vars.tireSmokeG, vars.tireSmokeB)
            end
        end)
        :AddTooltip("Set tire smoke green")
        :SetDonor())
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Smoke Blue")
        :AddNumberRef(vars, "tireSmokeB", "%d", 5)
        :AddMin(0):AddMax(255)
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(GetCurrentVehicle(), vars.tireSmokeR, vars.tireSmokeG, vars.tireSmokeB)
            end
        end)
        :AddTooltip("Set tire smoke blue")
        :SetDonor())
    
    -- Bulletproof wheels
    self:AddOption(ToggleOption.new("Bulletproof wheels")
        :AddToggleRef(vars, "bulletproofWheels")
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            if IsInVehicle() then
                local veh = GetCurrentVehicle()
                VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
                VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(veh, not vars.bulletproofWheels)
                VEHICLE.SET_VEHICLE_WHEELS_CAN_BREAK(veh, not vars.bulletproofWheels)
            end
        end)
        :AddTooltip("Make wheels bulletproof")
        :SetDonor())
    
    self:AddOption(BreakOption.new())
    
    -- Wheel type
    local wheelTypeNames = {}
    for i, w in ipairs(wheelTypes) do
        wheelTypeNames[i] = w.name
    end
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Wheel type")
        :AddScroll(wheelTypeNames, 1)
        :AddIndexRef(vars, "wheelTypeIndex")
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            if IsInVehicle() then
                local veh = GetCurrentVehicle()
                VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
                local wheelValue = wheelTypes[vars.wheelTypeIndex].value
                VEHICLE.SET_VEHICLE_WHEEL_TYPE(veh, wheelValue)
            end
        end)
        :AddTooltip("Set wheel type category")
        :SetDonor())
    
    -- Front wheels
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Front wheels")
        :AddNumberRef(vars, "frontWheelIndex", "%d", 1)
        :AddMin(-1):AddMax(50)
        :AddRequirement(IsInVehicle)
        :AddOnUpdate(function(opt)
            if IsInVehicle() then
                local numMods = VEHICLE.GET_NUM_VEHICLE_MODS(GetCurrentVehicle(), MOD_FRONTWHEELS)
                opt:AddMax(numMods - 1)
            end
        end)
        :AddFunction(function()
            if IsInVehicle() then
                local veh = GetCurrentVehicle()
                VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
                VEHICLE.SET_VEHICLE_MOD(veh, MOD_FRONTWHEELS, vars.frontWheelIndex, false)
            end
        end)
        :AddTooltip("Set front wheel style")
        :SetDonor())
    
    -- Rear wheels (bikes only)
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Rear wheels")
        :AddNumberRef(vars, "rearWheelIndex", "%d", 1)
        :AddMin(-1):AddMax(50)
        :AddRequirement(IsBike)
        :AddOnUpdate(function(opt)
            if IsBike() then
                local numMods = VEHICLE.GET_NUM_VEHICLE_MODS(GetCurrentVehicle(), MOD_BACKWHEELS)
                opt:AddMax(numMods - 1)
            end
        end)
        :AddFunction(function()
            if IsBike() then
                local veh = GetCurrentVehicle()
                VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
                VEHICLE.SET_VEHICLE_MOD(veh, MOD_BACKWHEELS, vars.rearWheelIndex, false)
            end
        end)
        :AddTooltip("Set rear wheel style (bikes only)")
        :SetDonor())
end

function WheelsMenu:FeatureUpdate()
    -- Apply bulletproof if enabled
    if vars.bulletproofWheels and IsInVehicle() then
        local veh = GetCurrentVehicle()
        VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(veh, false)
        VEHICLE.SET_VEHICLE_WHEELS_CAN_BREAK(veh, false)
    end
end

return WheelsMenu
