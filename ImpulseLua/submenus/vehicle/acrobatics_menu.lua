--[[
    Impulse Lua - Vehicle Acrobatics Menu
    Port of vehicleAcrobaticsMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local AcrobaticsMenu = setmetatable({}, { __index = Submenu })
AcrobaticsMenu.__index = AcrobaticsMenu

local instance = nil

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

function AcrobaticsMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Vehicle acrobatics"), AcrobaticsMenu)
        instance:Init()
    end
    return instance
end

function AcrobaticsMenu:Init()
    -- Front flip
    self:AddOption(ButtonOption.new("Front flip")
        :AddFunction(function()
            if IsInVehicle() then
                ENTITY.APPLY_FORCE_TO_ENTITY(GetCurrentVehicle(), 1, 0.0, 0.0, 20.0, 0.0, -2.0, 0.0, 0, true, true, true, false, true)
            end
        end)
        :AddTooltip("Do a front flip"))
    
    -- Back flip
    self:AddOption(ButtonOption.new("Back flip")
        :AddFunction(function()
            if IsInVehicle() then
                ENTITY.APPLY_FORCE_TO_ENTITY(GetCurrentVehicle(), 1, 0.0, 0.0, 20.0, 0.0, 6.0, 0.0, 0, true, true, true, false, true)
            end
        end)
        :AddTooltip("Do a back flip"))
    
    -- Kick flip
    self:AddOption(ButtonOption.new("Kick flip")
        :AddFunction(function()
            if IsInVehicle() then
                ENTITY.APPLY_FORCE_TO_ENTITY(GetCurrentVehicle(), 1, 0.0, 0.0, 10.71, 5.0, 0.0, 0.0, 0, false, true, true, true, true)
            end
        end)
        :AddTooltip("Do a kick flip"))
    
    -- Heel flip
    self:AddOption(ButtonOption.new("Heel flip")
        :AddFunction(function()
            if IsInVehicle() then
                ENTITY.APPLY_FORCE_TO_ENTITY(GetCurrentVehicle(), 1, 0.0, 0.0, 20.0, -2.0, 0.0, 0.0, 0, true, true, true, false, true)
            end
        end)
        :AddTooltip("Do a heel flip"))
    
    -- Bunny hop
    self:AddOption(ButtonOption.new("Bunny hop")
        :AddFunction(function()
            if IsInVehicle() then
                ENTITY.APPLY_FORCE_TO_ENTITY(GetCurrentVehicle(), 1, 0.0, 0.0, 6.0, 0.0, 0.0, 0.0, 0, false, true, true, true, true)
            end
        end)
        :AddTooltip("Do a bunny hop"))
    
    -- Slingshot
    self:AddOption(ButtonOption.new("Slingshot")
        :AddFunction(function()
            if IsInVehicle() then
                ENTITY.APPLY_FORCE_TO_ENTITY(GetCurrentVehicle(), 1, 0.0, 0.0, 150.0, 4.0, 2.0, 0.0, 0, true, true, true, false, true)
            end
        end)
        :AddTooltip("Fling your vehicle into the air"))
end

return AcrobaticsMenu
