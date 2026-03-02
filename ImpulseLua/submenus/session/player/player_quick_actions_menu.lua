--[[
    Impulse Lua - Player Quick Actions Menu
    Quick action shortcuts for selected player
    Port of quickActions.cpp from Impulse C++ (using Cherax built-in features)
    
    Note: Most features here are shortcuts to features already available in other menus
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")
local PlayerMenu = nil -- Lazy loaded

local PlayerQuickActionsMenu = setmetatable({}, { __index = Submenu })
PlayerQuickActionsMenu.__index = PlayerQuickActionsMenu

local instance = nil

-- Per-player state
local playerQuickActionState = {}

local function GetPlayerQuickActionState(playerId)
    if not playerQuickActionState[playerId] then
        playerQuickActionState[playerId] = {
            moneyDrop = false,
            disableWeapons = false,
        }
    end
    return playerQuickActionState[playerId]
end

-- ============================================
-- Helper Functions
-- ============================================

local function GetSelectedPlayerId()
    if not PlayerMenu then
        PlayerMenu = require("Impulse/ImpulseLua/submenus/session/player_menu")
    end
    return PlayerMenu.targetPlayer or -1
end

local function GetSelectedPlayerPed()
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then return 0 end
    return PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
end

local function GetSelectedPlayerName()
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then return "Unknown" end
    return PLAYER.GET_PLAYER_NAME(playerId) or "Unknown"
end

local function GetSelectedPlayerCoords()
    local ped = GetSelectedPlayerPed()
    if ped and ENTITY.DOES_ENTITY_EXIST(ped) then
        return ENTITY.GET_ENTITY_COORDS(ped, true)
    end
    return { x = 0, y = 0, z = 0 }
end



-- ============================================
-- Quick Action Functions
-- ============================================

--- Teleport to player (shortcut from teleport menu)
local function TeleportToPlayer()
    local coords = GetSelectedPlayerCoords()
    local localPed = PLAYER.PLAYER_PED_ID()
    
    if PED.IS_PED_IN_ANY_VEHICLE(localPed, false) then
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(localPed, false)
        ENTITY.SET_ENTITY_COORDS(vehicle, coords.x, coords.y, coords.z, false, false, false, false)
    else
        ENTITY.SET_ENTITY_COORDS(localPed, coords.x, coords.y, coords.z, false, false, false, false)
    end
    
    Renderer.Notify("Teleported to " .. GetSelectedPlayerName())
end

--- Teleport into player's vehicle
local function TeleportInPlayersVehicle()
    local ped = GetSelectedPlayerPed()
    if not ped or not ENTITY.DOES_ENTITY_EXIST(ped) then
        Renderer.Notify("Player does not exist")
        return
    end
    
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        Renderer.Notify(GetSelectedPlayerName() .. " is not in a vehicle")
        return
    end
    
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    local localPed = PLAYER.PLAYER_PED_ID()
    
    -- Find free seat
    local freeSeat = -2
    for seat = -1, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle) - 1 do
        if VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, seat, false) then
            freeSeat = seat
            break
        end
    end
    
    if freeSeat == -2 then
        Renderer.Notify("No free seat available")
        return
    end
    
    PED.SET_PED_INTO_VEHICLE(localPed, vehicle, freeSeat)
    Renderer.Notify("Entered " .. GetSelectedPlayerName() .. "'s vehicle")
end

--- Host kick (requires session host)
local function HostKick()
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then return end
    
    -- Check if we're host
    local localPlayerId = PLAYER.PLAYER_ID()
    local scriptHost = NETWORK.NETWORK_GET_HOST_OF_SCRIPT("freemode", -1, 0)
    
    if scriptHost ~= localPlayerId then
        Renderer.Notify("You must be session host to use this")
        return
    end
    
    NETWORK.NETWORK_SESSION_KICK_PLAYER(playerId)
    Renderer.Notify("Host kicked " .. GetSelectedPlayerName())
end

--- Give all weapons
local function GiveAllWeapons()
    local playerId = GetSelectedPlayerId()
    if FeatureState.Trigger("Give All Weapons", playerId) then
        Renderer.Notify("Gave all weapons to " .. GetSelectedPlayerName())
    end
end

--- Kick from vehicle (clear ped tasks)
local function KickFromVehicle()
    local ped = GetSelectedPlayerPed()
    if not ped or not ENTITY.DOES_ENTITY_EXIST(ped) then
        Renderer.Notify("Player does not exist")
        return
    end
    
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        Renderer.Notify(GetSelectedPlayerName() .. " is not in a vehicle")
        return
    end
    
    BRAIN.CLEAR_PED_TASKS_IMMEDIATELY(ped)
    Renderer.Notify("Kicked " .. GetSelectedPlayerName() .. " from vehicle")
end

--- Repair player's vehicle
local function RepairVehicle()
    local ped = GetSelectedPlayerPed()
    if not ped or not ENTITY.DOES_ENTITY_EXIST(ped) then return end
    
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        Renderer.Notify(GetSelectedPlayerName() .. " is not in a vehicle")
        return
    end
    
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    
    -- Request control and repair
    local attempts = 0
    while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) and attempts < 50 do
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
        attempts = attempts + 1
    end
    
    if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
        VEHICLE.SET_VEHICLE_FIXED(vehicle)
        Renderer.Notify("Repaired " .. GetSelectedPlayerName() .. "'s vehicle")
    else
        Renderer.Notify("Could not get control of vehicle")
    end
end

--- Launch player's vehicle upward
local function LaunchVehicle()
    local ped = GetSelectedPlayerPed()
    if not ped or not ENTITY.DOES_ENTITY_EXIST(ped) then return end
    
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        Renderer.Notify(GetSelectedPlayerName() .. " is not in a vehicle")
        return
    end
    
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    
    -- Request control and launch
    local attempts = 0
    while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) and attempts < 50 do
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
        attempts = attempts + 1
    end
    
    if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
        ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 20.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
        Renderer.Notify("Launched " .. GetSelectedPlayerName() .. "'s vehicle")
    else
        Renderer.Notify("Could not get control of vehicle")
    end
end

--- Freeze player in place
local function FreezePlayer()
    local playerId = GetSelectedPlayerId()
    if FeatureState.Trigger("Freeze Player", playerId) then
        Renderer.Notify("Froze " .. GetSelectedPlayerName())
    end
end

-- ============================================
-- Menu Definition
-- ============================================

function PlayerQuickActionsMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Quick Actions"), PlayerQuickActionsMenu)
        instance:Init()
    end
    return instance
end

function PlayerQuickActionsMenu:Init()
    -- Teleport shortcuts
    self:AddOption(ButtonOption.new("Teleport to player")
        :AddFunction(TeleportToPlayer)
        :AddTooltip("Teleport to player"))
    
    self:AddOption(ButtonOption.new("Teleport in players vehicle")
        :AddFunction(TeleportInPlayersVehicle)
        :AddTooltip("Teleport into player's vehicle"))
    
    self:AddOption(BreakOption.new("Kicks"))
    
    -- Kick shortcuts
    self:AddOption(ButtonOption.new("Smart Kick")
        :AddFunction(function()
            local playerId = GetSelectedPlayerId()
            if FeatureState.Trigger("Smart Kick", playerId) then
                Renderer.Notify("Smart kicked " .. GetSelectedPlayerName())
            end
        end)
        :AddTooltip("Smart kick"))
    
    self:AddOption(ButtonOption.new("Host kick")
        :AddFunction(HostKick)
        :AddTooltip("Host kick player [Must be session host]"))
    
    self:AddOption(BreakOption.new("Friendly"))
    
    -- Friendly shortcuts
    self:AddOption(ButtonOption.new("Give all weapons")
        :AddFunction(GiveAllWeapons)
        :AddTooltip("Give all weapons"))
    
    self:AddOption(ButtonOption.new("Kick from vehicle")
        :AddFunction(KickFromVehicle)
        :AddTooltip("Kick the player from their vehicle"))
    
    self:AddOption(ButtonOption.new("Repair vehicle")
        :AddFunction(RepairVehicle)
        :AddTooltip("Repair player's vehicle"))
    
    self:AddOption(ButtonOption.new("Launch vehicle")
        :AddFunction(LaunchVehicle)
        :AddTooltip("Launch player's vehicle upward"))
    
    self:AddOption(BreakOption.new("Toggles"))
    
    -- Money drop toggle
    self:AddOption(ToggleOption.new("Standard money drop", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerQuickActionState(playerId)
            state.moneyDrop = value
            
            -- Set to Money (index 0)
            FeatureMgr.SetFeatureListIndex(3236827509, 0)
            
            FeatureMgr.GetFeatureByName("Drop", playerId):SetValue(value):TriggerCallback()
            
            if value then
                Renderer.Notify("Standard money drop enabled for " .. GetSelectedPlayerName())
            else
                Renderer.Notify("Standard money drop disabled for " .. GetSelectedPlayerName())
            end
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerQuickActionState(playerId)
            
            local feature = FeatureMgr.GetFeatureByName("Drop", playerId)
            if feature and feature:IsToggled() then
                 state.moneyDrop = true
                 return true
            end
            state.moneyDrop = false
            return false
        end
        return false
    end)
        :AddTooltip("Standard money drop (cherax blocks enableing this feature )"))
    
    -- Freeze player toggle
    self:AddOption(ButtonOption.new("Freeze player")
        :AddFunction(FreezePlayer)
        :AddTooltip("Freeze player in place"))
    
    -- Off the radar (shortcut from remote menu)
    self:AddOption(ToggleOption.new("Give off the radar", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            FeatureMgr.GetFeatureByName("Off The Radar", playerId):SetValue(value):TriggerCallback()
            
             if value then
                Renderer.Notify("Off the radar given to " .. GetSelectedPlayerName())
            else
                Renderer.Notify("Off the radar removed from " .. GetSelectedPlayerName())
            end
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local feature = FeatureMgr.GetFeatureByName("Off The Radar", playerId)
            if feature then
                return feature:IsToggled()
            end
        end
        return false
    end)
        :AddTooltip("Give off the radar"))
end

return PlayerQuickActionsMenu
