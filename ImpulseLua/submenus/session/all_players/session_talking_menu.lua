--[[
    Impulse Lua - Session Talking Menu
    Actions for talking players
    Port of sessionTalking.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local SessionTalkingMenu = setmetatable({}, { __index = Submenu })
SessionTalkingMenu.__index = SessionTalkingMenu

local instance = nil

-- State
local vars = {
    showList = false,
    explode = false,
    addWantedLevel = false,
}

function SessionTalkingMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Talking"), SessionTalkingMenu)
        instance:Init()
    end
    return instance
end

function SessionTalkingMenu:Init()
    local AllPlayersMenu = require("Impulse/ImpulseLua/submenus/session/all_players_menu")

    self:AddOption(ToggleOption.new("Show list")
        :AddToggleRef(vars, "showList")
        :AddTooltip("Draw the talking players"))

    self:AddOption(ToggleOption.new("Explode")
        :AddToggleRef(vars, "explode")
        :AddTooltip("Explode the talking players"))

    self:AddOption(ToggleOption.new("Add wanted level")
        :AddToggleRef(vars, "addWantedLevel")
        :AddTooltip("Add wanted level to the talking players"))
end

function SessionTalkingMenu:FeatureUpdate()
    local AllPlayersMenu = require("Impulse/ImpulseLua/submenus/session/all_players_menu")
    
    if vars.showList then
        local y = 0.05
        for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
            if NETWORK.NETWORK_IS_PLAYER_TALKING(pid) then
                local name = PLAYER.GET_PLAYER_NAME(pid)
                Renderer.DrawString(name, 0.80, y, 0, 0.30, {r=255, g=255, b=255, a=255}, true)
                y = y + 0.02
            end
        end
    end
    
    if vars.explode then
        for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
            if NETWORK.NETWORK_IS_PLAYER_TALKING(pid) then
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                if ped and ENTITY.DOES_ENTITY_EXIST(ped) then
                    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
                    FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 2, 10000.0, true, false, 0.0, false)
                end
            end
        end
    end
    
    if vars.addWantedLevel then
        for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
            if NETWORK.NETWORK_IS_PLAYER_TALKING(pid) then
                 PLAYER.REPORT_CRIME(pid, 8, PLAYER.GET_WANTED_LEVEL_THRESHOLD(5))
            end
        end
    end
end

return SessionTalkingMenu
