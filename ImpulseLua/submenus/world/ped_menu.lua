--[[
    Impulse Lua - Pedestrian Manager Menu
    Port of pedManagerMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local PedMenu = setmetatable({}, { __index = Submenu })
PedMenu.__index = PedMenu

local instance = nil

-- Variables
local vars = {
    esp = false
}

-- Nearby peds cache
local nearbyPeds = {}

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

-- Update nearby peds using PoolMgr + player iteration for full coverage
local function UpdateNearbyPeds()
    nearbyPeds = {}
    local myPed = GetLocalPed()
    local myCoords = GetLocalCoords()
    local seenPeds = {}
    
    -- Method 1: Use PoolMgr to get all peds
    local pedCount = PoolMgr.GetCurrentPedCount()
    for i = 0, pedCount - 1 do
        local ped = PoolMgr.GetPed(i)
        if ped and ped ~= 0 and ped ~= myPed and ENTITY.DOES_ENTITY_EXIST(ped) and not PED.IS_PED_A_PLAYER(ped) then
            if not seenPeds[ped] then
                seenPeds[ped] = true
                table.insert(nearbyPeds, ped)
            end
        end
    end
    
    -- Method 2: Also iterate through all player peds (for multiplayer scenarios)
    for i = 0, 31 do
        if NETWORK.NETWORK_IS_PLAYER_CONNECTED(i) then
            local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(i)
            if playerPed and playerPed ~= 0 and playerPed ~= myPed and ENTITY.DOES_ENTITY_EXIST(playerPed) then
                if not seenPeds[playerPed] then
                    seenPeds[playerPed] = true
                    table.insert(nearbyPeds, playerPed)
                end
            end
        end
    end
end

-- Run ped action on all peds
local function RunPedAction(action)
    UpdateNearbyPeds()
    
    local myPed = GetLocalPed()
    local myCoords = GetLocalCoords()
    
    for _, ped in ipairs(nearbyPeds) do
        if ped ~= myPed and ENTITY.DOES_ENTITY_EXIST(ped) then
            RequestControl(ped)
            local coords = ENTITY.GET_ENTITY_COORDS(ped, false)
            
            if action == "esp" then
                GRAPHICS.DRAW_LINE(myCoords.x, myCoords.y, myCoords.z, coords.x, coords.y, coords.z, 0, 255, 0, 255)
            elseif action == "kill" then
                PED.APPLY_DAMAGE_TO_PED(ped, 30000, true, 0)
            elseif action == "clone" then
                local heading = ENTITY.GET_ENTITY_HEADING(ped)
                PED.CLONE_PED(ped, heading, true, false)
            elseif action == "delete" then
                Script.QueueJob(function()
                    if ENTITY.DOES_ENTITY_EXIST(ped) then
                        local ptr = Memory.AllocInt()
                        Memory.WriteInt(ptr, ped)
                        ENTITY.DELETE_ENTITY(ptr)
                    end
                end)
            elseif action == "shrink" then
                PED.SET_PED_CONFIG_FLAG(ped, 223, true)
            elseif action == "enlarge" then
                PED.SET_PED_CONFIG_FLAG(ped, 223, false)
            elseif action == "launch" then
                ENTITY.APPLY_FORCE_TO_ENTITY(ped, 1, 0, 0, 20.0, 0, 0, 0, 0, true, true, true, false, true)
            elseif action == "cleartasks" then
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
            elseif action == "jump" then
                TASK.TASK_JUMP(ped, true, true, true)
            elseif action == "cower" then
                TASK.TASK_COWER(ped, 5000)
            elseif action == "handsup" then
                TASK.TASK_HANDS_UP(ped, 5000, 0, 0, false)
            elseif action == "wander" then
                TASK.TASK_WANDER_IN_AREA(ped, coords.x, coords.y, coords.z, 500.0, 10.0, 1.0)
            elseif action == "cometome" then
                TASK.TASK_GO_TO_ENTITY(ped, myPed, -1, 2.0, 100.0, 2.0, 0)
            elseif action == "explode" then
                FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 2, 2000.0, true, false, 0.0, false)
            end
        end
    end
end

function PedMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Pedestrian manager"), PedMenu)
        instance:Init()
    end
    return instance
end

function PedMenu:Init()
    self:AddOption(ToggleOption.new("Ped ESP")
        :AddToggleRef(vars, "esp")
        :AddTooltip("Extra sensory perception"))

    self:AddOption(ButtonOption.new("Kill peds")
        :AddFunction(function() RunPedAction("kill") end)
        :AddTooltip("Kill peds"))

    self:AddOption(ButtonOption.new("Clone peds")
        :AddFunction(function() RunPedAction("clone") end)
        :AddTooltip("Clone peds"))

    self:AddOption(ButtonOption.new("Delete peds")
        :AddFunction(function() RunPedAction("delete") end)
        :AddTooltip("Delete peds"))

    self:AddOption(ButtonOption.new("Shrink peds")
        :AddFunction(function() RunPedAction("shrink") end)
        :AddTooltip("Shrink peds"))

    self:AddOption(ButtonOption.new("Enlarge peds")
        :AddFunction(function() RunPedAction("enlarge") end)
        :AddTooltip("Enlarge peds"))

    self:AddOption(ButtonOption.new("Launch peds")
        :AddFunction(function() RunPedAction("launch") end)
        :AddTooltip("Launch peds"))

    self:AddOption(BreakOption.new("Tasks"))

    self:AddOption(ButtonOption.new("Clear ped tasks")
        :AddFunction(function() RunPedAction("cleartasks") end)
        :AddTooltip("Clear ped tasks"))

    self:AddOption(ButtonOption.new("Peds jump")
        :AddFunction(function() RunPedAction("jump") end)
        :AddTooltip("Peds jump"))

    self:AddOption(ButtonOption.new("Peds cower")
        :AddFunction(function() RunPedAction("cower") end)
        :AddTooltip("Peds cower"))

    self:AddOption(ButtonOption.new("Peds hands up")
        :AddFunction(function() RunPedAction("handsup") end)
        :AddTooltip("Peds hands up"))

    self:AddOption(ButtonOption.new("Peds wander")
        :AddFunction(function() RunPedAction("wander") end)
        :AddTooltip("Peds wander"))

    self:AddOption(ButtonOption.new("Peds come to me")
        :AddFunction(function() RunPedAction("cometome") end)
        :AddTooltip("Peds come to me"))
end

-- Register a looped script for ESP that runs independently
Script.RegisterLooped(function()
    if vars.esp then
        local myPed = GetLocalPed()
        local myCoords = GetLocalCoords()
        local seenPeds = {}
        
        -- Method 1: PoolMgr peds
        local pedCount = PoolMgr.GetCurrentPedCount()
        for i = 0, pedCount - 1 do
            local ped = PoolMgr.GetPed(i)
            if ped and ped ~= 0 and ped ~= myPed and ENTITY.DOES_ENTITY_EXIST(ped) then
                if not seenPeds[ped] then
                    seenPeds[ped] = true
                    local coords = ENTITY.GET_ENTITY_COORDS(ped, false)
                    -- Green for NPCs, Red for players
                    if PED.IS_PED_A_PLAYER(ped) then
                        GRAPHICS.DRAW_LINE(myCoords.x, myCoords.y, myCoords.z, coords.x, coords.y, coords.z, 255, 0, 0, 255)
                    else
                        GRAPHICS.DRAW_LINE(myCoords.x, myCoords.y, myCoords.z, coords.x, coords.y, coords.z, 0, 255, 0, 255)
                    end
                end
            end
        end
        
        -- Method 2: Player peds
        for i = 0, 31 do
            if NETWORK.NETWORK_IS_PLAYER_CONNECTED(i) then
                local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(i)
                if playerPed and playerPed ~= 0 and playerPed ~= myPed and ENTITY.DOES_ENTITY_EXIST(playerPed) then
                    if not seenPeds[playerPed] then
                        seenPeds[playerPed] = true
                        local coords = ENTITY.GET_ENTITY_COORDS(playerPed, false)
                        GRAPHICS.DRAW_LINE(myCoords.x, myCoords.y, myCoords.z, coords.x, coords.y, coords.z, 255, 0, 0, 255)
                    end
                end
            end
        end
    end
    Script.Yield(0)
end)

return PedMenu
