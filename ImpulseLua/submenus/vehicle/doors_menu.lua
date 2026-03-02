--[[
    Impulse Lua - Vehicle Doors Menu
    Port of doorsMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local DoorsMenu = setmetatable({}, { __index = Submenu })
DoorsMenu.__index = DoorsMenu

local instance = nil

local vars = {
    openDoor = 0,
    closeDoor = 0,
    deleteDoor = 0
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

function DoorsMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Vehicle doors"), DoorsMenu)
        instance:Init()
    end
    return instance
end

function DoorsMenu:Init()
    -- Open door
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Open door")
        :AddNumberRef(vars, "openDoor", "%d", 1)
        :AddMin(0):AddMax(5)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_DOOR_OPEN(GetCurrentVehicle(), vars.openDoor, false, false)
            end
        end)
        :AddTooltip("Open a vehicle door"))
    
    -- Close door
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Close door")
        :AddNumberRef(vars, "closeDoor", "%d", 1)
        :AddMin(0):AddMax(5)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_DOOR_SHUT(GetCurrentVehicle(), vars.closeDoor, false)
            end
        end)
        :AddTooltip("Close a vehicle door"))
    
    -- Delete door
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Delete door")
        :AddNumberRef(vars, "deleteDoor", "%d", 1)
        :AddMin(0):AddMax(5)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_DOOR_BROKEN(GetCurrentVehicle(), vars.deleteDoor, true)
            end
        end)
        :AddTooltip("Remove a vehicle door"))
    
    -- Lock doors
    self:AddOption(ButtonOption.new("Lock doors")
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_DOORS_LOCKED(GetCurrentVehicle(), 4)
                Renderer.Notify("Doors locked")
            end
        end)
        :AddTooltip("Lock all vehicle doors"))
    
    -- Unlock doors
    self:AddOption(ButtonOption.new("Unlock doors")
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_DOORS_LOCKED(GetCurrentVehicle(), 0)
                Renderer.Notify("Doors unlocked")
            end
        end)
        :AddTooltip("Unlock all vehicle doors"))
end

return DoorsMenu
