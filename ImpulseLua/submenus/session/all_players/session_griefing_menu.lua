--[[
    Impulse Lua - Session Griefing Menu
    Hostile actions against players
    Port of sessionGriefing.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local SessionGriefingMenu = setmetatable({}, { __index = Submenu })
SessionGriefingMenu.__index = SessionGriefingMenu

local instance = nil

-- State
local vars = {
    disableTasks = false,
    alwaysWanted = false,
    electrocutep = false,
    hostileTraffic = false,
    hostilePeds = false,
    fakeMoney = false,
    shakeCamera = false,
    smokePlayer = false,
    waterLoop = false,
    fireLoop = false,
    fire = false,
    explode = false,
    rainRockets = false,
    forceField = false,
    karma = false,
    attackerCount = 1
}

function SessionGriefingMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Griefing"), SessionGriefingMenu)
        instance:Init()
    end
    return instance
end

function SessionGriefingMenu:Init()
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

    self:AddOption(BreakOption.new("Troll"))

    self:AddOption(ToggleOption.new("Freeze in place")
        :AddToggleRef(vars, "disableTasks")
        :AddFunction(function() ToggleFeatureOnSession("Freeze Player", "disableTasks", "Froze") end)
        :AddTooltip("Freeze the player in place"))

    self:AddOption(ButtonOption.new("Give wanted level")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                 PLAYER.REPORT_CRIME(pid, 8, PLAYER.GET_WANTED_LEVEL_THRESHOLD(5))
            end
            Renderer.Notify("Gave wanted level to session")
        end)
        :AddTooltip("Add wanted level"))

    -- Always wanted removed (no feature match)

    self:AddOption(ToggleOption.new("Electrocute session")
        :AddToggleRef(vars, "electrocutep")
        :AddFunction(function() ToggleFeatureOnSession("Stun Player", "electrocutep", "Stunned") end)
        :AddTooltip("This will electrocute the session"))

    -- Fake money removed (no feature match exposed)

    self:AddOption(BreakOption.new("Affect Ped Vision and Movement"))

    self:AddOption(ToggleOption.new("Shake camera")
        :AddToggleRef(vars, "shakeCamera")
        :AddFunction(function() ToggleFeatureOnSession("Shake Cam", "shakeCamera", "Shaking camera") end)
        :AddTooltip("Shake the sessions camera"))

    -- Smoke session removed (no feature match exposed)

    self:AddOption(ToggleOption.new("Spray with water")
        :AddToggleRef(vars, "waterLoop")
        :AddFunction(function() ToggleFeatureOnSession("Water Loop", "waterLoop", "Water loop") end)
        :AddTooltip("Spray with water"))

    self:AddOption(ToggleOption.new("Spray with fire")
        :AddToggleRef(vars, "fireLoop")
        :AddFunction(function() ToggleFeatureOnSession("Fire Loop", "fireLoop", "Fire loop") end)
        :AddTooltip("Spray with fire"))

    self:AddOption(BreakOption.new("Deadly Force"))

    self:AddOption(ButtonOption.new("Kill")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                FeatureState.Trigger("Kill Player", pid)
            end
            Renderer.Notify("Killed session")
        end)
        :AddTooltip("Kill the session"))
        
     self:AddOption(ButtonOption.new("Silent kill")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                if ped and ENTITY.DOES_ENTITY_EXIST(ped) then
                    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
                    FIRE.ADD_OWNED_EXPLOSION(PLAYER.PLAYER_PED_ID(), coords.x, coords.y, coords.z, 38, 0.1, false, false, 0.0)
                end
            end
            Renderer.Notify("Silent killed session")
        end)
        :AddTooltip("Peaceful kill logic"))

    -- Set on fire removed (Fire Loop takes precedence / no separate feature)

     self:AddOption(ButtonOption.new("Explode")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                if ped and ENTITY.DOES_ENTITY_EXIST(ped) then
                    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
                    FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 18, 0.25, true, false, 0.5, false)
                end
            end
            Renderer.Notify("Exploded session")
        end)
        :AddTooltip("Explode session"))

    -- Explode loop removed (no feature match exposed)
end

function SessionGriefingMenu:FeatureUpdate()
    -- No manual loops needed, handled by FeatureState/FeatureMgr
end

return SessionGriefingMenu
