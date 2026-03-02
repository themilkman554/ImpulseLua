--[[
    Impulse Lua - Train Options Menu
    Port of miscTrainOptions.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
-- local Utils = require("Impulse/ImpulseLua/lib/utils") -- Removed as it doesn't exist

local TrainOptionsMenu = setmetatable({}, { __index = Submenu })
TrainOptionsMenu.__index = TrainOptionsMenu

local instance = nil

function TrainOptionsMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Train Options"), TrainOptionsMenu)
        instance:Init()
    end
    return instance
end

-- Variables
local vars = {
    trainkeyboard = false,
    trainHandle = 0 -- Stores the handle of the spawned/controlled train
}

-- Train Models (freight, etc.)
local TrainModels = {
    0x3D6AAA9B, -- freight
    0x0AFD22A6, -- freightcar
    0x264D9262, -- freightgrain
    0x36DCFF98, -- freightcont1
    0x0E512E79, -- freightcont2
    0xD1ABB666  -- tanker
}

function TrainOptionsMenu:Init()
    -- Drive Nearest Train
    self:AddOption(ButtonOption.new("Drive Nearest Train")
        :AddFunction(function()
            local ped = PLAYER.PLAYER_PED_ID()
            local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
            local nearestTrain = 0
            
            -- Check for each known train model
            for _, model in ipairs(TrainModels) do
                -- Using VEHICLE.GET_CLOSEST_VEHICLE
                local veh = VEHICLE.GET_CLOSEST_VEHICLE(coords.x, coords.y, coords.z, 100.0, model, 70) 
                if veh ~= 0 and ENTITY.DOES_ENTITY_EXIST(veh) then
                    nearestTrain = veh
                    break
                end
            end
            
            if nearestTrain ~= 0 then
                vars.trainHandle = nearestTrain
                PED.SET_PED_INTO_VEHICLE(ped, vars.trainHandle, -1)
            else
                -- Notify("No train found nearby")
            end
        end)
        :AddTooltip("Drive the nearest train to your ped (be near a train)")
        :AddHotkey())

    -- Spawn Train
    self:AddOption(ButtonOption.new("Spawn Train")
        :AddFunction(function()
            -- Request Models
            for _, model in ipairs(TrainModels) do
                STREAMING.REQUEST_MODEL(model)
            end
            
            -- Wait for load (simple check)
            local ped = PLAYER.PLAYER_PED_ID()
            local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
            
            -- variation 15 is standard full freight train
            -- true = direction (or isNetwork?)
            vars.trainHandle = VEHICLE.CREATE_MISSION_TRAIN(15, coords.x, coords.y, coords.z, true)
            
            if vars.trainHandle ~= 0 then
                PED.SET_PED_INTO_VEHICLE(ped, vars.trainHandle, -1)
            end
        end)
        :AddTooltip("Be near a train track when spawning this")
        :AddHotkey())

    -- Quit Train Ride
    self:AddOption(ButtonOption.new("Quit Train Ride")
        :AddFunction(function()
            local ped = PLAYER.PLAYER_PED_ID()
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
            vars.trainHandle = 0 
        end)
        :AddTooltip("Exit the train without getting rid of it")
        :AddHotkey())

    -- Delete Spawned Train
    self:AddOption(ButtonOption.new("Delete Spawned Train")
        :AddFunction(function()
            if vars.trainHandle ~= 0 and ENTITY.DOES_ENTITY_EXIST(vars.trainHandle) then
                local ptr = Memory.AllocInt()
                Memory.WriteInt(ptr, vars.trainHandle)
                VEHICLE.DELETE_MISSION_TRAIN(ptr)
                vars.trainHandle = 0
                Memory.Free(ptr)
            end
        end)
        :AddTooltip("Delete the spawned train")
        :AddHotkey())

    -- Keyboard Controls
    self:AddOption(ToggleOption.new("Keyboard Controls")
        :AddToggle(vars.trainkeyboard)
        :AddFunction(function(val) 
            vars.trainkeyboard = val 
        end)
        :AddTooltip("Keyboard controls: W/S Speed, Space Stop"))

    -- Chrome Train
    self:AddOption(ButtonOption.new("Chrome Train")
        :AddFunction(function()
            if vars.trainHandle ~= 0 and ENTITY.DOES_ENTITY_EXIST(vars.trainHandle) then
                VEHICLE.SET_VEHICLE_COLOURS(vars.trainHandle, 120, 120) -- 120 = Chrome
                for i = 0, 25 do
                    local carriage = VEHICLE.GET_TRAIN_CARRIAGE(vars.trainHandle, i)
                    if carriage ~= 0 and ENTITY.DOES_ENTITY_EXIST(carriage) then
                        VEHICLE.SET_VEHICLE_COLOURS(carriage, 120, 120)
                    end
                end
            end
        end)
        :AddTooltip("Chrome the current train carriage")
        :AddHotkey())

    -- Derail Train
    self:AddOption(ButtonOption.new("Derail Train")
        :AddFunction(function()
            if vars.trainHandle ~= 0 and ENTITY.DOES_ENTITY_EXIST(vars.trainHandle) then
                VEHICLE.SET_VEHICLE_UNDRIVEABLE(vars.trainHandle, true)
                VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vars.trainHandle, 0.0)
                VEHICLE.SET_VEHICLE_PETROL_TANK_HEALTH(vars.trainHandle, 0.0)
                
                local coords = ENTITY.GET_ENTITY_COORDS(vars.trainHandle, false)
                FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 29, 9999.0, true, false, 0.0, false)
                
                VEHICLE.SET_RENDER_TRAIN_AS_DERAILED(vars.trainHandle, true)
                ENTITY.SET_ENTITY_RENDER_SCORCHED(vars.trainHandle, true)
                VEHICLE.SET_TRAIN_CRUISE_SPEED(vars.trainHandle, 0.0)
                VEHICLE.SET_TRAIN_SPEED(vars.trainHandle, 0.0)
            end
        end)
        :AddTooltip("Derail your current train (still moveable)")
        :AddHotkey())

    -- Speed Up / Slow Down (Manual)
    self:AddOption(ButtonOption.new("Speed Up Train")
        :AddFunction(function()
            if vars.trainHandle ~= 0 and ENTITY.DOES_ENTITY_EXIST(vars.trainHandle) then
                local speed = ENTITY.GET_ENTITY_SPEED(vars.trainHandle)
                speed = speed + 20.0
                VEHICLE.SET_TRAIN_CRUISE_SPEED(vars.trainHandle, speed)
                VEHICLE.SET_TRAIN_SPEED(vars.trainHandle, speed)
            end
        end)
        :AddTooltip("Manually speed up the train"))

    self:AddOption(ButtonOption.new("Slow Down Train")
        :AddFunction(function()
            if vars.trainHandle ~= 0 and ENTITY.DOES_ENTITY_EXIST(vars.trainHandle) then
                local speed = ENTITY.GET_ENTITY_SPEED(vars.trainHandle)
                speed = speed - 20.0
                VEHICLE.SET_TRAIN_CRUISE_SPEED(vars.trainHandle, speed)
                VEHICLE.SET_TRAIN_SPEED(vars.trainHandle, speed)
            end
        end)
        :AddTooltip("Manually slow down the train"))
end

function TrainOptionsMenu:FeatureUpdate()
    if vars.trainkeyboard and vars.trainHandle ~= 0 and ENTITY.DOES_ENTITY_EXIST(vars.trainHandle) then
        local ped = PLAYER.PLAYER_PED_ID()
        if PED.GET_VEHICLE_PED_IS_IN(ped, false) == vars.trainHandle then
            -- Note: Using standard Control IDs or Keys.
            -- Using PAD natives for cleaner input
            
            -- Accelerate (W)
            if PAD.IS_CONTROL_PRESSED(0, 71) then -- INPUT_VEH_ACCELERATE
                local speed = ENTITY.GET_ENTITY_SPEED(vars.trainHandle)
                speed = speed + 1.0 -- Increasing per frame
                VEHICLE.SET_TRAIN_CRUISE_SPEED(vars.trainHandle, speed)
                VEHICLE.SET_TRAIN_SPEED(vars.trainHandle, speed)
            end
            
            -- Brake/Reverse (S)
            if PAD.IS_CONTROL_PRESSED(0, 72) then -- INPUT_VEH_BRAKE
                local speed = ENTITY.GET_ENTITY_SPEED(vars.trainHandle)
                speed = speed - 1.0
                VEHICLE.SET_TRAIN_CRUISE_SPEED(vars.trainHandle, speed)
                VEHICLE.SET_TRAIN_SPEED(vars.trainHandle, speed)
            end
            
            -- Handbrake (Space)
            if PAD.IS_CONTROL_PRESSED(0, 76) then -- INPUT_VEH_HANDBRAKE
                VEHICLE.SET_TRAIN_CRUISE_SPEED(vars.trainHandle, 0.0)
                VEHICLE.SET_TRAIN_SPEED(vars.trainHandle, 0.0)
            end
        end
    end
end

return TrainOptionsMenu
