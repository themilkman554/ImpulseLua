--[[
    Impulse Lua - LSC Performance Menu
    Port of vehiclePerformanceMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")

local PerformanceMenu = setmetatable({}, { __index = Submenu })
PerformanceMenu.__index = PerformanceMenu

local instance = nil

-- Performance options
local engineOptions = {
    "Stock", "EMS Upgrade Level 1", "EMS Upgrade Level 2", "EMS Upgrade Level 3", "EMS Upgrade Level 4"
}

local brakeOptions = {
    "Stock Brakes", "Street Brakes", "Sport Brakes", "Race Brakes"
}

local transmissionOptions = {
    "Stock Transmission", "Street Transmission", "Sport Transmission", "Race Transmission"
}

local suspensionOptions = {
    "Stock Suspension", "Lowered Suspension", "Street Suspension", "Sport Suspension", "Competition Suspension"
}

local armorOptions = {
    "None", "Armor 20%", "Armor 40%", "Armor 60%", "Armor 80%", "Armor 100%"
}

-- Mod type constants
local MOD_ENGINE = 11
local MOD_BRAKES = 12
local MOD_TRANSMISSION = 13
local MOD_SUSPENSION = 15
local MOD_ARMOR = 16
local MOD_TURBO = 18

local vars = {
    turbo = false,
    engineIndex = 1,
    brakesIndex = 1,
    transmissionIndex = 1,
    suspensionIndex = 1,
    armorIndex = 1
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

-- Max vehicle performance
local function MaxVehiclePerformance()
    if not IsInVehicle() then return end
    local veh = GetCurrentVehicle()
    VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
    
    -- Max engine
    local numEngine = VEHICLE.GET_NUM_VEHICLE_MODS(veh, MOD_ENGINE)
    if numEngine > 0 then
        VEHICLE.SET_VEHICLE_MOD(veh, MOD_ENGINE, numEngine - 1, false)
    end
    
    -- Max brakes
    local numBrakes = VEHICLE.GET_NUM_VEHICLE_MODS(veh, MOD_BRAKES)
    if numBrakes > 0 then
        VEHICLE.SET_VEHICLE_MOD(veh, MOD_BRAKES, numBrakes - 1, false)
    end
    
    -- Max transmission
    local numTrans = VEHICLE.GET_NUM_VEHICLE_MODS(veh, MOD_TRANSMISSION)
    if numTrans > 0 then
        VEHICLE.SET_VEHICLE_MOD(veh, MOD_TRANSMISSION, numTrans - 1, false)
    end
    
    -- Max suspension
    local numSusp = VEHICLE.GET_NUM_VEHICLE_MODS(veh, MOD_SUSPENSION)
    if numSusp > 0 then
        VEHICLE.SET_VEHICLE_MOD(veh, MOD_SUSPENSION, numSusp - 1, false)
    end
    
    -- Max armor
    local numArmor = VEHICLE.GET_NUM_VEHICLE_MODS(veh, MOD_ARMOR)
    if numArmor > 0 then
        VEHICLE.SET_VEHICLE_MOD(veh, MOD_ARMOR, numArmor - 1, false)
    end
    
    -- Enable turbo
    VEHICLE.TOGGLE_VEHICLE_MOD(veh, MOD_TURBO, true)
end

function PerformanceMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Performance"), PerformanceMenu)
        instance:Init()
    end
    return instance
end

function PerformanceMenu:Init()
    -- Fully tune performance
    self:AddOption(ButtonOption.new("Fully tune performance")
        :AddRequirement(IsInVehicle)
        :AddFunction(MaxVehiclePerformance)
        :AddTooltip("Max all performance upgrades")
        :SetDonor())
    
    -- Turbo
    self:AddOption(ToggleOption.new("Turbo")
        :AddToggleRef(vars, "turbo")
        :AddRequirement(IsInVehicle)
        :AddOnUpdate(function(opt)
            if IsInVehicle() then
                vars.turbo = VEHICLE.IS_TOGGLE_MOD_ON(GetCurrentVehicle(), MOD_TURBO)
            end
        end)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.TOGGLE_VEHICLE_MOD(GetCurrentVehicle(), MOD_TURBO, vars.turbo)
            end
        end)
        :AddTooltip("Toggle turbo tuning")
        :SetDonor())
    
    -- Engine
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Engine")
        :AddScroll(engineOptions, 1)
        :AddIndexRef(vars, "engineIndex")
        :AddRequirement(IsInVehicle)
        :AddOnUpdate(function(opt)
            if IsInVehicle() then
                vars.engineIndex = VEHICLE.GET_VEHICLE_MOD(GetCurrentVehicle(), MOD_ENGINE) + 2
                if vars.engineIndex < 1 then vars.engineIndex = 1 end
                if vars.engineIndex > #engineOptions then vars.engineIndex = #engineOptions end
            end
        end)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_MOD(GetCurrentVehicle(), MOD_ENGINE, vars.engineIndex - 2, false)
            end
        end)
        :AddTooltip("Set engine level")
        :SetDonor())
    
    -- Brakes
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Brakes")
        :AddScroll(brakeOptions, 1)
        :AddIndexRef(vars, "brakesIndex")
        :AddRequirement(IsInVehicle)
        :AddOnUpdate(function(opt)
            if IsInVehicle() then
                vars.brakesIndex = VEHICLE.GET_VEHICLE_MOD(GetCurrentVehicle(), MOD_BRAKES) + 2
                if vars.brakesIndex < 1 then vars.brakesIndex = 1 end
                if vars.brakesIndex > #brakeOptions then vars.brakesIndex = #brakeOptions end
            end
        end)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_MOD(GetCurrentVehicle(), MOD_BRAKES, vars.brakesIndex - 2, false)
            end
        end)
        :AddTooltip("Set brake level")
        :SetDonor())
    
    -- Transmission
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Transmission")
        :AddScroll(transmissionOptions, 1)
        :AddIndexRef(vars, "transmissionIndex")
        :AddRequirement(IsInVehicle)
        :AddOnUpdate(function(opt)
            if IsInVehicle() then
                vars.transmissionIndex = VEHICLE.GET_VEHICLE_MOD(GetCurrentVehicle(), MOD_TRANSMISSION) + 2
                if vars.transmissionIndex < 1 then vars.transmissionIndex = 1 end
                if vars.transmissionIndex > #transmissionOptions then vars.transmissionIndex = #transmissionOptions end
            end
        end)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_MOD(GetCurrentVehicle(), MOD_TRANSMISSION, vars.transmissionIndex - 2, false)
            end
        end)
        :AddTooltip("Set transmission level")
        :SetDonor())
    
    -- Suspension
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Suspension")
        :AddScroll(suspensionOptions, 1)
        :AddIndexRef(vars, "suspensionIndex")
        :AddRequirement(IsInVehicle)
        :AddOnUpdate(function(opt)
            if IsInVehicle() then
                vars.suspensionIndex = VEHICLE.GET_VEHICLE_MOD(GetCurrentVehicle(), MOD_SUSPENSION) + 2
                if vars.suspensionIndex < 1 then vars.suspensionIndex = 1 end
                if vars.suspensionIndex > #suspensionOptions then vars.suspensionIndex = #suspensionOptions end
            end
        end)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_MOD(GetCurrentVehicle(), MOD_SUSPENSION, vars.suspensionIndex - 2, false)
            end
        end)
        :AddTooltip("Set suspension level")
        :SetDonor())
    
    -- Armor
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Armor")
        :AddScroll(armorOptions, 1)
        :AddIndexRef(vars, "armorIndex")
        :AddRequirement(IsInVehicle)
        :AddOnUpdate(function(opt)
            if IsInVehicle() then
                vars.armorIndex = VEHICLE.GET_VEHICLE_MOD(GetCurrentVehicle(), MOD_ARMOR) + 2
                if vars.armorIndex < 1 then vars.armorIndex = 1 end
                if vars.armorIndex > #armorOptions then vars.armorIndex = #armorOptions end
            end
        end)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_MOD(GetCurrentVehicle(), MOD_ARMOR, vars.armorIndex - 2, false)
            end
        end)
        :AddTooltip("Set armor level")
        :SetDonor())
end

function PerformanceMenu:FeatureUpdate()
    -- No continuous updates needed
end

return PerformanceMenu
