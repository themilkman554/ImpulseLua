--[[
    Impulse Lua - Player Disable Actions Menu
    Disable options for selected player
    Port of disableActionsMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local PlayerMenu = nil -- Lazy loaded

local PlayerDisableActionsMenu = setmetatable({}, { __index = Submenu })
PlayerDisableActionsMenu.__index = PlayerDisableActionsMenu

local instance = nil

-- State
local disableState = {
    vehicles = false,
    interiors = false,
    weapons = false
}

-- Helpers
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

local function GetSelectedPlayerCoords()
    local ped = GetSelectedPlayerPed()
    if ped and ENTITY.DOES_ENTITY_EXIST(ped) then
        return ENTITY.GET_ENTITY_COORDS(ped, true)
    end
    return { x = 0, y = 0, z = 0 }
end

-- Menu Definition
function PlayerDisableActionsMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Disable Actions"), PlayerDisableActionsMenu)
        instance:Init()
    end
    return instance
end

function PlayerDisableActionsMenu:Init()
    -- Disable vehicles (Loop Vehicle Kick)
    self:AddOption(ToggleOption.new("Disable vehicles")
        :AddToggleRef(disableState, "vehicles")
        :AddFunction(function()
            local playerId = GetSelectedPlayerId()
            local feature = FeatureMgr.GetFeatureByName("Loop Vehicle Kick", playerId)
            if feature then
                feature:SetValue(disableState.vehicles):TriggerCallback()
            end
        end)
        :AddTooltip("Block the user from entering vehicles.")
        :AddHotkey())

    -- Disable interiors
    self:AddOption(ToggleOption.new("Disable interiors")
        :AddToggleRef(disableState, "interiors")
        :AddTooltip("Block the user from entering map interiors (not apartments).")
        :AddHotkey())

    -- Disable weapons
    self:AddOption(ToggleOption.new("Disable weapons")
        :AddToggleRef(disableState, "weapons")
        :AddTooltip("Block the user from using weapons at all.")
        :AddHotkey())
end

-- Background Loop
Script.RegisterLooped(function()
    local playerId = GetSelectedPlayerId()
    if playerId == -1 then 
        Script.Yield(1000)
        return 
    end

    local ped = GetSelectedPlayerPed()
    if not ENTITY.DOES_ENTITY_EXIST(ped) then
        Script.Yield(1000)
        return
    end

    -- Disable Interiors
    if disableState.interiors then
        local tags = ""
        if Players and Players.GetTags then
            tags = Players.GetTags(playerId)
        end
        
        -- Check for [I] tag indicating interior
        if tags and string.find(tags, "%[I%]") then
            local coords = GetSelectedPlayerCoords()
            -- Explosion type 29 (EXPLOSION_GRENADELAUNCHER_SMOKE? C++ used 29)
            -- C++: AddExplosion(coords, 29, 1, false, true, 1, false)
            FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 29, 1.0, false, true, 1.0, false)
        end
    end

    -- Disable Weapons
    if disableState.weapons then
        -- User requested: FeatureMgr.TriggerFeatureCallback(983169212, playerid)
        if FeatureMgr and FeatureMgr.TriggerFeatureCallback then
             -- 983169212 is likely the hash for "Remove All Weapons" or similar
            FeatureMgr.TriggerFeatureCallback(983169212, playerId)
        end
    end

    Script.Yield(100)
end)

return PlayerDisableActionsMenu
