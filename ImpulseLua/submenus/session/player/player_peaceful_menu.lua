--[[
    Impulse Lua - Player Peaceful Menu
    Peaceful/helpful options for selected player
    Port of peacefulMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")
local PlayerMenu = nil -- Lazy loaded to avoid circular dependency

local PlayerPeacefulMenu = setmetatable({}, { __index = Submenu })
PlayerPeacefulMenu.__index = PlayerPeacefulMenu

local instance = nil

-- Peaceful state (per-player states stored by player ID)
local peacefulState = {
    rainWeapons = {},
    demiGodmode = {},
    constantWaypoint = {},
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



--- Remove All Weapons (using built-in menu feature)
local function RemoveAllWeapons()
    local playerId = GetSelectedPlayerId()
    if FeatureState.Trigger("Remove All Weapons", playerId) then
        Renderer.Notify("Removed all weapons from " .. GetSelectedPlayerName())
    else
        Renderer.Notify("Feature not available")
    end
end

--- Give All Weapons (using built-in menu feature)
local function GiveAllWeapons()
    local playerId = GetSelectedPlayerId()
    if FeatureState.Trigger("Give All Weapons", playerId) then
        Renderer.Notify("Gave all weapons to " .. GetSelectedPlayerName())
    else
        Renderer.Notify("Feature not available")
    end
end

--- Give All Components (using built-in menu feature)
local function GiveAllComponents()
    local playerId = GetSelectedPlayerId()
    if FeatureState.Trigger("Give All Components", playerId) then
        Renderer.Notify("Gave all components to " .. GetSelectedPlayerName())
    else
        Renderer.Notify("Feature not available")
    end
end

--- Spawn clone bodyguard (matches C++ SpawnCloneBodyguard)
local function SpawnCloneBodyguard()
    local playerId = GetSelectedPlayerId()
    local playerPed = GetSelectedPlayerPed()
    
    if not playerPed or not ENTITY.DOES_ENTITY_EXIST(playerPed) then
        Renderer.Notify("Player not found")
        return
    end
    
    local heading = ENTITY.GET_ENTITY_HEADING(playerPed)
    local clone = PED.CLONE_PED(playerPed, heading, true, false)
    
    if clone and clone ~= 0 then
        local myGroup = PLAYER.GET_PLAYER_GROUP(playerId)
        local railgun = Utils.Joaat("WEAPON_RAILGUN")
        
        -- Add blip
        local blip = HUD.ADD_BLIP_FOR_ENTITY(clone)
        HUD.SET_BLIP_SPRITE(blip, 480)
        HUD.SET_BLIP_COLOUR(blip, 63)
        
        -- Set up as bodyguard
        PED.SET_PED_AS_GROUP_LEADER(playerPed, myGroup)
        PED.SET_PED_AS_GROUP_MEMBER(clone, myGroup)
        PED.SET_PED_NEVER_LEAVES_GROUP(clone, true)
        ENTITY.SET_ENTITY_INVINCIBLE(clone, true)
        PED.SET_PED_COMBAT_ABILITY(clone, 100)
        PED.SET_PED_CAN_SWITCH_WEAPON(clone, true)
        PED.SET_GROUP_FORMATION(myGroup, 3)
        PED.SET_PED_MAX_HEALTH(clone, 5000)
        ENTITY.SET_ENTITY_VISIBLE(clone, true, true)
        WEAPON.GIVE_WEAPON_TO_PED(clone, railgun, 9999, false, true)
        TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(clone, 100.0, 0) 
        PED.SET_PED_CAN_RAGDOLL(clone, false)
        PED.SET_PED_CAN_RAGDOLL_FROM_PLAYER_IMPACT(clone, false)
        PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(clone, 1)
        PED.SET_PED_RAGDOLL_ON_COLLISION(clone, false)
        
        Renderer.Notify("Spawned clone bodyguard for " .. GetSelectedPlayerName())
    else
        Renderer.Notify("Failed to spawn clone")
    end
end

--- Clear area around player (matches C++ Clear area)
local function ClearArea()
    local coords = GetSelectedPlayerCoords()
    if coords.x == 0 and coords.y == 0 then
        Renderer.Notify("Could not get player position")
        return
    end
    
    MISC.CLEAR_AREA_OF_VEHICLES(coords.x, coords.y, coords.z, 50.0, false, false, false, false, false, false, 0)
    MISC.CLEAR_AREA_OF_PEDS(coords.x, coords.y, coords.z, 50.0, 0)
    MISC.CLEAR_AREA_OF_OBJECTS(coords.x, coords.y, coords.z, 50.0, 0)
    MISC.CLEAR_AREA_OF_PROJECTILES(coords.x, coords.y, coords.z, 50.0, 0)
    
    Renderer.Notify("Cleared area around " .. GetSelectedPlayerName())
end

--- Copy outfit from player (using built-in menu feature)
local function CopyOutfit()
    local playerId = GetSelectedPlayerId()
    if FeatureState.Trigger("Copy Outfit", playerId) then
        Renderer.Notify("Copied outfit from " .. GetSelectedPlayerName())
    else
        Renderer.Notify("Feature not available")
    end
end

--- Set waypoint on player location (matches C++ SetWaypoint)
local function SetWaypoint()
    local coords = GetSelectedPlayerCoords()
    if coords.x == 0 and coords.y == 0 then
        Renderer.Notify("Could not get player position")
        return
    end
    
    HUD.SET_NEW_WAYPOINT(coords.x, coords.y)
    Renderer.Notify("Waypoint set on " .. GetSelectedPlayerName())
end

function PlayerPeacefulMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Peaceful"), PlayerPeacefulMenu)
        instance:Init()
    end
    return instance
end

function PlayerPeacefulMenu:Init()
    
    -- Give all weapons (using built-in)
    self:AddOption(ButtonOption.new("Give all weapons")
        :AddFunction(GiveAllWeapons)
        :AddTooltip("Give all weapons"))
    
    -- Remove all weapons (using built-in)
    self:AddOption(ButtonOption.new("Remove all weapons")
        :AddFunction(RemoveAllWeapons)
        :AddTooltip("Remove all weapons"))
    
    -- Give all components (using built-in)
    self:AddOption(ButtonOption.new("Give all components")
        :AddFunction(GiveAllComponents)
        :AddTooltip("Give all weapon components"))
    
    -- Spawn clone bodyguard
    self:AddOption(ButtonOption.new("Spawn clone bodyguard")
        :AddFunction(SpawnCloneBodyguard)
        :AddTooltip("Spawn clone bodyguard"))
    
    -- Clear area
    self:AddOption(ButtonOption.new("Clear area")
        :AddFunction(ClearArea)
        :AddTooltip("Clear the players area"))
    
    self:AddOption(BreakOption.new("Outfit Copying"))
    
    -- Copy outfit (using built-in)
    self:AddOption(ButtonOption.new("Copy outfit")
        :AddFunction(CopyOutfit)
        :AddTooltip("Copy the players outfit"))
    
    self:AddOption(BreakOption.new("Waypoint"))
    
    -- Set waypoint on player location
    self:AddOption(ButtonOption.new("Set waypoint on player location")
        :AddFunction(SetWaypoint)
        :AddTooltip("This will set a waypoint on the players location"))
end

return PlayerPeacefulMenu
