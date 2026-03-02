--[[
    Impulse Lua - Traffic Manager Menu
    Port of trafficManagerMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")

local TrafficMenu = setmetatable({}, { __index = Submenu })
TrafficMenu.__index = TrafficMenu

local instance = nil

-- Variables
local vars = {
    esp = false,
    chaos = false
}

-- Nearby vehicles cache
local nearbyVehicles = {}

local function GetLocalPed()
    return PLAYER.PLAYER_PED_ID()
end

local function GetLocalCoords()
    return ENTITY.GET_ENTITY_COORDS(GetLocalPed(), true)
end

-- Request control of entity
local function RequestControl(entity)
    local tick = 0
    while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) and tick <= 25 do
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
        tick = tick + 1
    end
end

-- Update nearby vehicles using PoolMgr
local function UpdateNearbyVehicles()
    nearbyVehicles = {}
    local myVeh = PED.GET_VEHICLE_PED_IS_IN(GetLocalPed(), false)
    
    -- Use PoolMgr to get all vehicles
    if PoolMgr.GetCurrentVehicleCount then
        local vehCount = PoolMgr.GetCurrentVehicleCount()
        for i = 0, vehCount - 1 do
            local veh = PoolMgr.GetVehicle(i)
            if veh and veh ~= 0 and veh ~= myVeh and ENTITY.DOES_ENTITY_EXIST(veh) then
                table.insert(nearbyVehicles, veh)
            end
        end
    end

    -- Also iterate through all player vehicles (for multiplayer scenarios)
    for i = 0, 31 do
        if NETWORK.NETWORK_IS_PLAYER_CONNECTED(i) then
            local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(i)
            if playerPed and playerPed ~= 0 and ENTITY.DOES_ENTITY_EXIST(playerPed) then
                local veh = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)
                if veh and veh ~= 0 and veh ~= myVeh and ENTITY.DOES_ENTITY_EXIST(veh) then
                    -- Avoid duplicates
                    local isDuplicate = false
                    for _, v in ipairs(nearbyVehicles) do
                        if v == veh then
                            isDuplicate = true
                            break
                        end
                    end
                    if not isDuplicate then
                        table.insert(nearbyVehicles, veh)
                    end
                end
            end
        end
    end
end

-- Run traffic action on all vehicles
local function RunTrafficAction(action)
    UpdateNearbyVehicles()
    
    local myVeh = PED.GET_VEHICLE_PED_IS_IN(GetLocalPed(), false)
    local myCoords = GetLocalCoords()
    
    for _, veh in ipairs(nearbyVehicles) do
        if veh ~= myVeh and ENTITY.DOES_ENTITY_EXIST(veh) then
            RequestControl(veh)
            local coords = ENTITY.GET_ENTITY_COORDS(veh, false)
            
            if action == "esp" then
                GRAPHICS.DRAW_LINE(myCoords.x, myCoords.y, myCoords.z, coords.x, coords.y, coords.z, 255, 0, 0, 255)
            elseif action == "chaos" then
                -- Random speed and direction for chaos
                local randomSpeed = math.random(50, 150)
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, randomSpeed * 1.0)
                -- Randomly apply forces to spin vehicles
                if math.random(1, 10) == 1 then
                    ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, math.random(-5, 5) * 1.0, 0, math.random(0, 5) * 1.0, 0, 0, 0, 0, true, true, true, false, true)
                end
            elseif action == "explode" then
                NETWORK.NETWORK_EXPLODE_VEHICLE(veh, true, false, false)
            elseif action == "killdriver" then
                VEHICLE.SET_VEHICLE_OUT_OF_CONTROL(veh, true, false)
            elseif action == "launch" then
                ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0, 0, 20.0, 0, 0, 0, 0, true, true, true, false, true)
            elseif action == "boost" then
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, 100.0)
            elseif action == "kickflip" then
                ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.0, 0.0, 10.71, 5.0, 0.0, 0.0, 0, true, true, true, false, true)
            elseif action == "delete" then
                Script.QueueJob(function()
                    pcall(function()
                        if ENTITY.DOES_ENTITY_EXIST(veh) then
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(veh, true, true)
                            local ptr = Memory.AllocInt()
                            Memory.WriteInt(ptr, veh)
                            ENTITY.DELETE_ENTITY(ptr)
                        end
                    end)
                end)
            elseif action == "push" then
                local dx = coords.x - myCoords.x
                local dy = coords.y - myCoords.y
                local dz = coords.z - myCoords.z
                ENTITY.APPLY_FORCE_TO_ENTITY(veh, 3, dx, dy, dz, 0, 0, 0, 0, false, true, true, false, true)
            elseif action == "fix" then
                VEHICLE.SET_VEHICLE_FIXED(veh)
            elseif action == "scorch" then
                ENTITY.SET_ENTITY_RENDER_SCORCHED(veh, true)
            elseif action == "cometome" then
                local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh, -1, false)
                if ENTITY.DOES_ENTITY_EXIST(driver) then
                    local model = ENTITY.GET_ENTITY_MODEL(veh)
                    TASK.TASK_VEHICLE_DRIVE_TO_COORD(driver, veh, myCoords.x, myCoords.y, myCoords.z, 100.0, 1, model, 16777216, 4.0, -1.0)
                end
            elseif action == "nogravity" then
                VEHICLE.SET_VEHICLE_GRAVITY(veh, false)
            elseif action == "normalgravity" then
                VEHICLE.SET_VEHICLE_GRAVITY(veh, true)
            end
        end
    end
end

function TrafficMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Traffic manager"), TrafficMenu)
        instance:Init()
    end
    return instance
end

function TrafficMenu:Init()
    self:AddOption(ToggleOption.new("Vehicle ESP")
        :AddToggleRef(vars, "esp")
        :AddTooltip("Extra sensory perception"))

    self:AddOption(ToggleOption.new("Vehicle chaos")
        :AddToggleRef(vars, "chaos")
        :AddTooltip("Chaos"))

    self:AddOption(ButtonOption.new("Explode vehicles")
        :AddFunction(function() RunTrafficAction("explode") end)
        :AddTooltip("Explode vehicles"))

    self:AddOption(ButtonOption.new("Kill driver")
        :AddFunction(function() RunTrafficAction("killdriver") end)
        :AddTooltip("Kill driver"))

    self:AddOption(ButtonOption.new("Launch vehicles")
        :AddFunction(function() RunTrafficAction("launch") end)
        :AddTooltip("Launch vehicles"))

    self:AddOption(ButtonOption.new("Boost vehicles")
        :AddFunction(function() RunTrafficAction("boost") end)
        :AddTooltip("Boost vehicles"))

    self:AddOption(ButtonOption.new("Kickflip vehicles")
        :AddFunction(function() RunTrafficAction("kickflip") end)
        :AddTooltip("Kickflip vehicles"))

    self:AddOption(ButtonOption.new("Delete vehicles")
        :AddFunction(function() RunTrafficAction("delete") end)
        :AddTooltip("Delete vehicles"))

    self:AddOption(ButtonOption.new("Fix vehicles")
        :AddFunction(function() RunTrafficAction("fix") end)
        :AddTooltip("Fix vehicles"))

    self:AddOption(ButtonOption.new("Scorch vehicles")
        :AddFunction(function() RunTrafficAction("scorch") end)
        :AddTooltip("Scorch vehicles"))

    self:AddOption(ButtonOption.new("Drive vehicles to me")
        :AddFunction(function() RunTrafficAction("cometome") end)
        :AddTooltip("Drive vehicles to me"))

    self:AddOption(ButtonOption.new("No gravity")
        :AddFunction(function() RunTrafficAction("nogravity") end)
        :AddTooltip("No gravity"))

    self:AddOption(ButtonOption.new("Normal gravity")
        :AddFunction(function() RunTrafficAction("normalgravity") end)
        :AddTooltip("Normal gravity"))
end

-- Register a looped script for ESP and chaos that runs independently
Script.RegisterLooped(function()
    if vars.esp or vars.chaos then
        local myVeh = PED.GET_VEHICLE_PED_IS_IN(GetLocalPed(), false)
        local myCoords = GetLocalCoords()
        
        local vehCount = PoolMgr.GetCurrentVehicleCount()
        for i = 0, vehCount - 1 do
            local veh = PoolMgr.GetVehicle(i)
            if veh and veh ~= 0 and veh ~= myVeh and ENTITY.DOES_ENTITY_EXIST(veh) then
                local coords = ENTITY.GET_ENTITY_COORDS(veh, false)
                
                if vars.esp then
                    GRAPHICS.DRAW_LINE(myCoords.x, myCoords.y, myCoords.z, coords.x, coords.y, coords.z, 255, 0, 0, 255)
                end
                
                if vars.chaos then
                    RequestControl(veh)
                    VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, math.random(50, 150) * 1.0)
                    if math.random(1, 20) == 1 then
                        ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, math.random(-5, 5) * 1.0, 0, math.random(0, 5) * 1.0, 0, 0, 0, 0, true, true, true, false, true)
                    end
                end
            end
        end
    end
    Script.Yield(0)
end)

return TrafficMenu
