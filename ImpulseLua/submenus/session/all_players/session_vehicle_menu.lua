--[[
    Impulse Lua - Session Vehicle Menu
    Vehicle actions for all players
    Port of sessionVehicle.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local SessionVehicleMenu = setmetatable({}, { __index = Submenu })
SessionVehicleMenu.__index = SessionVehicleMenu

local instance = nil

-- State
local vars = {
    hornBoost = false,
    freeze = false,
    kickLoop = false,
}

function SessionVehicleMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Vehicle"), SessionVehicleMenu)
        instance:Init()
    end
    return instance
end

function SessionVehicleMenu:Init()
    local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")
    local AllPlayersMenu = require("Impulse/ImpulseLua/submenus/session/all_players_menu")

    -- Helper for toggling features on all targets
    local function ToggleFeatureOnSession(featureName, stateVarName, notifyText)
        local state = vars[stateVarName]
        for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
            local feature = FeatureMgr.GetFeatureByName(featureName, pid)
            if feature then
                feature:SetValue(state):TriggerCallback()
            end
        end
        
        if state then
             Renderer.Notify(notifyText .. " on session")
        else
             Renderer.Notify("Stopped " .. string.lower(notifyText) .. " on session")
        end
    end

    self:AddOption(ButtonOption.new("Godmode vehicle")
        :AddFunction(function()
             for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                if ped and ENTITY.DOES_ENTITY_EXIST(ped) and PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                    if veh and ENTITY.DOES_ENTITY_EXIST(veh) then
                        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                        ENTITY.SET_ENTITY_INVINCIBLE(veh, true)
                        ENTITY.SET_ENTITY_PROOFS(veh, true, true, true, true, true, true, true, true)
                        VEHICLE.SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED(veh, false)
                    end
                end
             end
             Renderer.Notify("Godmode vehicle on session")
        end)
        :AddTooltip("Godmode vehicle"))

    self:AddOption(ButtonOption.new("Kick from vehicle")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                 FeatureState.Trigger("Vehicle Kick", pid)
            end
            Renderer.Notify("Kicked session from vehicles")
        end)
        :AddTooltip("Kick player from vehicle"))
        
    self:AddOption(ToggleOption.new("Kick from vehicle loop")
        :AddToggleRef(vars, "kickLoop")
        :AddFunction(function() ToggleFeatureOnSession("Loop Vehicle Kick", "kickLoop", "Vehicle kick loop") end)
        :AddTooltip("Continuously kick player from vehicles"))

    self:AddOption(BreakOption.new("Movement Modifications"))

    self:AddOption(ToggleOption.new("Horn boost")
        :AddToggleRef(vars, "hornBoost")
        :AddTooltip("Horn boost"))

    self:AddOption(ButtonOption.new("Launch vehicle")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                if ped and PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                    if veh then
                        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                        ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.0, 0.0, 50.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
                    end
                end
            end
            Renderer.Notify("Launched vehicles on session")
        end)
        :AddTooltip("Launch vehicle"))

    self:AddOption(ButtonOption.new("Boost vehicle")
        :AddFunction(function()
             for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                if ped and PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                    if veh then
                        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                        ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.0, 100.0, 0.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
                    end
                end
            end
            Renderer.Notify("Boosted vehicles on session")
        end)
        :AddTooltip("Boost vehicle"))

    self:AddOption(ToggleOption.new("Freeze vehicle")
        :AddToggleRef(vars, "freeze")
        :AddTooltip("Freeze vehicle"))
        
     self:AddOption(ButtonOption.new("Stop vehicle")
        :AddFunction(function()
             for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                if ped and PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                    if veh then
                        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                         VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, 0.0)
                    end
                end
            end
            Renderer.Notify("Stopped vehicles on session")
        end)
        :AddTooltip("Stop vehicle"))

    self:AddOption(BreakOption.new("Trolling"))

    self:AddOption(ButtonOption.new("Kill engine")
        :AddFunction(function()
             for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                if ped and PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                    if veh then
                        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                        VEHICLE.SET_VEHICLE_ENGINE_HEALTH(veh, -4000)
                    end
                end
            end
            Renderer.Notify("Killed engines on session")
        end)
        :AddTooltip("Kill engine"))

    self:AddOption(ButtonOption.new("Revive engine")
        :AddFunction(function()
             for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                if ped and PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                    if veh then
                        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                        VEHICLE.SET_VEHICLE_ENGINE_HEALTH(veh, 1000)
                        VEHICLE.SET_VEHICLE_FIXED(veh)
                    end
                end
            end
            Renderer.Notify("Revived engines on session")
        end)
        :AddTooltip("Revive engine"))

    self:AddOption(ButtonOption.new("Delete vehicle")
        :AddFunction(function()
             for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                FeatureState.Trigger("Delete Player Vehicle", pid)
            end
            Renderer.Notify("Deleted vehicles on session")
        end)
        :AddTooltip("Delete vehicle"))

     self:AddOption(ButtonOption.new("Burst tires")
        :AddFunction(function()
             for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                if ped and PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                    if veh then
                        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                        for i=0, 7 do
                             VEHICLE.SET_VEHICLE_TYRE_BURST(veh, i, true, 1000.0)
                        end
                    end
                end
            end
        end)
        :AddTooltip("Burst tires"))

    self:AddOption(BreakOption.new("Vehicle Modifications"))

    self:AddOption(ButtonOption.new("Repair vehicle")
        :AddFunction(function()
             for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                if ped and PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                    local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                    if veh then
                        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                        VEHICLE.SET_VEHICLE_FIXED(veh)
                    end
                end
            end
        end)
        :AddTooltip("Repair vehicle"))
end

function SessionVehicleMenu:FeatureUpdate()
    local AllPlayersMenu = require("Impulse/ImpulseLua/submenus/session/all_players_menu")
    local function ForEachVehicle(callback)
         for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
            if ped and PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                if veh and ENTITY.DOES_ENTITY_EXIST(veh) then
                    callback(veh)
                end
            end
        end
    end

    if vars.hornBoost then
        ForEachVehicle(function(veh)
             if AUDIO.IS_HORN_ACTIVE(veh) then
                 NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                 ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
             end
        end)
    end
    
    if vars.freeze then
         ForEachVehicle(function(veh)
             NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
             ENTITY.FREEZE_ENTITY_POSITION(veh, true)
         end)
    else
         -- Unfreeze logic? Usually we don't unfreeze in loop unless state changed, but this is simple loop
    end
end

return SessionVehicleMenu
