--[[
    Impulse Lua - Session Peaceful Menu
    Beneficial actions for players
    Port of sessionPeacefulMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local SessionPeacefulMenu = setmetatable({}, { __index = Submenu })
SessionPeacefulMenu.__index = SessionPeacefulMenu

local instance = nil



function SessionPeacefulMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Peaceful"), SessionPeacefulMenu)
        instance:Init()
    end
    return instance
end

function SessionPeacefulMenu:Init()
    local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")
    local AllPlayersMenu = require("Impulse/ImpulseLua/submenus/session/all_players_menu")

    self:AddOption(ButtonOption.new("Give all weapons")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                FeatureState.Trigger("Give All Weapons", pid)
            end
            Renderer.Notify("Gave all weapons to session")
        end)
        :AddTooltip("Give the session all weapons"))

    self:AddOption(ButtonOption.new("Send Bodyguard")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                FeatureState.Trigger("Send Bodyguard", pid)
            end
            Renderer.Notify("Sent bodyguards to session")
        end)
        :AddTooltip("Send a bodyguard to the session"))

    self:AddOption(ButtonOption.new("Clear area")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                if ped and ENTITY.DOES_ENTITY_EXIST(ped) then
                    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
                    MISC.CLEAR_AREA_OF_EVERYTHING(coords.x, coords.y, coords.z, 50.0, true, true, true, true)
                end
            end
        end)
        :AddTooltip("Clear the sessions area"))

    self:AddOption(ButtonOption.new("Remove all players attachments")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                if pid ~= PLAYER.PLAYER_ID() then
                     -- Logic to remove attached entities
                     -- Would need to scan entities attached to ped
                end
            end
        end)
        :AddTooltip("Clear the players attached entities"))



    -- More options omitted for brevity/safety in initial port
end

function SessionPeacefulMenu:FeatureUpdate()
end

return SessionPeacefulMenu
