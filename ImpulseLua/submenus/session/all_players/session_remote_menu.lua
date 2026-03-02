--[[
    Impulse Lua - Session Remote Menu
    Remote actions on players
    Port of sessionRemote.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local SessionRemoteMenu = setmetatable({}, { __index = Submenu })
SessionRemoteMenu.__index = SessionRemoteMenu

local instance = nil

-- State
local vars = {
    soundSpam = false,
    lockview = false,
    spectating = false,
    gneverWanted = false,
    gblindEye = false,
    gotr = false,
}

function SessionRemoteMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Remote"), SessionRemoteMenu)
        instance:Init()
    end
    return instance
end

function SessionRemoteMenu:Init()
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

    -- Kicks 
    self:AddOption(ButtonOption.new("Smart Kick")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                FeatureState.Trigger("Smart Kick", pid)
            end
            Renderer.Notify("Smart kicked session")
        end)
        :AddTooltip("Smart kick"))
    
    self:AddOption(ButtonOption.new("Script Event Kick")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                FeatureState.Trigger("Script Event Kick", pid)
            end
            Renderer.Notify("Script event kicked session")
        end)
        :AddTooltip("Script event kick"))
    
    self:AddOption(ButtonOption.new("CEO/MC Kick")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                FeatureState.Trigger("CEO/MC Kick", pid)
            end
             Renderer.Notify("CEO/MC kicked session")
        end)
        :AddTooltip("CEO/MC kick"))
    
    self:AddOption(ButtonOption.new("Vehicle Kick")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                FeatureState.Trigger("Vehicle Kick", pid)
            end
            Renderer.Notify("Vehicle kicked session")
        end)
        :AddTooltip("Kick player from vehicle"))

    self:AddOption(BreakOption.new("Troll"))

    self:AddOption(ButtonOption.new("Infinite Loading Screen")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                FeatureState.Trigger("Infinite Loading Screen", pid)
            end
            Renderer.Notify("Sent infinite loading screen to session")
        end)
        :AddTooltip("Infinite loading screen"))

    self:AddOption(ToggleOption.new("Force Camera Forward")
        :AddToggleRef(vars, "lockview")
        :AddFunction(function() ToggleFeatureOnSession("Force Camera Forward", "lockview", "Forcing camera forward") end)
        :AddTooltip("Force the players camera forward"))

    self:AddOption(BreakOption.new("Notifications"))

    -- Notifications options (spectating, insurance, etc)
    -- Omitted for brevity in this iteration

    self:AddOption(BreakOption.new("Give Globals"))

    self:AddOption(ToggleOption.new("Give never wanted")
        :AddToggleRef(vars, "gneverWanted")
        :AddFunction(function() ToggleFeatureOnSession("Never Wanted", "gneverWanted", "Never wanted") end)
        :AddTooltip("Give Never wanted"))

    self:AddOption(ToggleOption.new("Bribe Authorities")
        :AddToggleRef(vars, "gblindEye")
        :AddFunction(function() ToggleFeatureOnSession("Bribe Authorities", "gblindEye", "Bribe authorities") end)
        :AddTooltip("Give Cops turn blind eye"))

    self:AddOption(ToggleOption.new("Give off the radar")
        :AddToggleRef(vars, "gotr")
        :AddFunction(function() ToggleFeatureOnSession("Off The Radar", "gotr", "Off the radar") end)
        :AddTooltip("Give Off the radar"))
end

function SessionRemoteMenu:FeatureUpdate()
end

return SessionRemoteMenu
