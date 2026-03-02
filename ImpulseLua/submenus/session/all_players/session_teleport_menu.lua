--[[
    Impulse Lua - Session Teleport Menu
    Bulk teleport actions
    Port of sessionTeleportMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local SessionTeleportMenu = setmetatable({}, { __index = Submenu })
SessionTeleportMenu.__index = SessionTeleportMenu

local instance = nil

function SessionTeleportMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Teleport"), SessionTeleportMenu)
        instance:Init()
    end
    return instance
end

function SessionTeleportMenu:Init()
    local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")
    local AllPlayersMenu = require("Impulse/ImpulseLua/submenus/session/all_players_menu")

    -- Teleport All Players
    self:AddOption(ButtonOption.new("Teleport All Players")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                if pid ~= PLAYER.PLAYER_ID() then
                    FeatureState.Trigger("Teleport to Me", pid)
                end
            end
        end)
        :AddTooltip("Teleport all players to me"))

    -- Teleport nearest vehicle to all players
    self:AddOption(ButtonOption.new("Teleport nearest vehicle to all players")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                if ped and ENTITY.DOES_ENTITY_EXIST(ped) then
                    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
                    local veh = VEHICLE.GET_CLOSEST_VEHICLE(coords.x, coords.y, coords.z, 600.0, 0, 70)
                    if veh and ENTITY.DOES_ENTITY_EXIST(veh) then
                        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                        ENTITY.SET_ENTITY_COORDS(veh, coords.x, coords.y, coords.z, false, false, false, true)
                    end
                end
            end
        end)
        :AddTooltip("Teleport the nearest vehicle to the player to the player"))
end

return SessionTeleportMenu
