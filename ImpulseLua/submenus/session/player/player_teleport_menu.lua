--[[
    Impulse Lua - Player Teleport Menu
    Teleport options for selected player
    Port of playerTeleportMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local PlayerMenu = nil -- Lazy loaded to avoid circular dependency

local PlayerTeleportMenu = setmetatable({}, { __index = Submenu })
PlayerTeleportMenu.__index = PlayerTeleportMenu

local instance = nil

-- Teleport state
local teleportState = {
    range = 10
}

--- Get selected player ID from PlayerMenu
---@return number
local function GetSelectedPlayerId()
    if not PlayerMenu then
        PlayerMenu = require("Impulse/ImpulseLua/submenus/session/player_menu")
    end
    return PlayerMenu.targetPlayer or -1
end

--- Get selected player ped
---@return number
local function GetSelectedPlayerPed()
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then return 0 end
    return PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
end

--- Get selected player coords
---@return table
local function GetSelectedPlayerCoords()
    local ped = GetSelectedPlayerPed()
    if ped and ENTITY.DOES_ENTITY_EXIST(ped) then
        return ENTITY.GET_ENTITY_COORDS(ped, true)
    end
    return { x = 0, y = 0, z = 0 }
end

--- Get selected player name
---@return string
local function GetSelectedPlayerName()
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then return "Unknown" end
    return PLAYER.GET_PLAYER_NAME(playerId) or "Unknown"
end

--- Teleport to player (matches C++ TeleportToPlayer)
local function TeleportToPlayer()
    local coords = GetSelectedPlayerCoords()
    if coords.x == 0 and coords.y == 0 then
        Renderer.Notify("Could not get player position")
        return
    end
    
    local myPed = PLAYER.PLAYER_PED_ID()
    local myVeh = PED.GET_VEHICLE_PED_IS_IN(myPed, false)
    
    if myVeh and myVeh ~= 0 and ENTITY.DOES_ENTITY_EXIST(myVeh) then
        ENTITY.SET_ENTITY_COORDS(myVeh, coords.x, coords.y, coords.z, false, false, false, true)
    else
        ENTITY.SET_ENTITY_COORDS(myPed, coords.x, coords.y, coords.z, false, false, false, true)
    end
    
    Renderer.Notify("Teleported to " .. GetSelectedPlayerName())
end

--- Teleport into player's vehicle (matches C++ TeleportInPlayersVehicle)
local function TeleportInPlayersVehicle()
    local ped = GetSelectedPlayerPed()
    if not ped or not ENTITY.DOES_ENTITY_EXIST(ped) then
        Renderer.Notify("Player not found")
        return
    end
    
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        Renderer.Notify(GetSelectedPlayerName() .. " is not in a vehicle")
        return
    end
    
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    local myPed = PLAYER.PLAYER_PED_ID()
    
    -- Find free seat
    local freeSeat = -2
    local maxSeats = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle)
    for seat = -1, maxSeats - 1 do
        if VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, seat, false) then
            freeSeat = seat
            break
        end
    end
    
    PED.SET_PED_INTO_VEHICLE(myPed, vehicle, freeSeat)
    Renderer.Notify("Teleported into " .. GetSelectedPlayerName() .. "'s vehicle")
end



--- Teleport within range of player
local function TeleportWithinRange()
    local coords = GetSelectedPlayerCoords()
    if coords.x == 0 and coords.y == 0 then
        Renderer.Notify("Could not get player position")
        return
    end
    
    local range = teleportState.range
    local myPed = PLAYER.PLAYER_PED_ID()
    
    ENTITY.SET_ENTITY_COORDS(myPed, 
        coords.x + range, 
        coords.y + range, 
        coords.z + 3, 
        false, false, false, true)
    
    Renderer.Notify("Teleported near " .. GetSelectedPlayerName())
end

function PlayerTeleportMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Teleport player"), PlayerTeleportMenu)
        instance:Init()
    end
    return instance
end

function PlayerTeleportMenu:Init()
    local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")

    -- Teleport to player (matches C++)
    self:AddOption(ButtonOption.new("Teleport to player")
        :AddFunction(TeleportToPlayer)
        :AddTooltip("Teleport to player"))
    
    -- Teleport in player's vehicle (matches C++)
    self:AddOption(ButtonOption.new("Teleport in players vehicle")
        :AddFunction(TeleportInPlayersVehicle)
        :AddTooltip("Teleport in players vehicle"))
    
    -- Teleport to Me (was Teleport players vehicle to me, updated per request)
    self:AddOption(ButtonOption.new("Teleport To Me")
        :AddFunction(function()
            local pid = GetSelectedPlayerId()
            if pid ~= -1 then
                FeatureState.Trigger("Teleport to Me", pid)
            end
        end)
        :AddTooltip("Teleport player to me"))
    
    -- Teleport within range (matches C++ NumberOption with SCROLLSELECT)
    self:AddOption(NumberOption.new(NumberOption.Type.SELECT, "Teleport within range")
        :AddNumberRef(teleportState, "range", "%d", 1)
        :SetMin(1)
        :SetMax(100)
        :AddFunction(TeleportWithinRange)
        :AddTooltip("Teleport closeby to the player"))
end

return PlayerTeleportMenu
