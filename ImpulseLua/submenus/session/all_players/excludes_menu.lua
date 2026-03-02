--[[
    Impulse Lua - Excludes Menu
    Filter which players are affected by All Players actions
    Port of excludesMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")

local ExcludesMenu = setmetatable({}, { __index = Submenu })
ExcludesMenu.__index = ExcludesMenu

local instance = nil

function ExcludesMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Excludes"), ExcludesMenu)
        instance:Init()
    end
    return instance
end

function ExcludesMenu:Init()
    local AllPlayersMenu = require("Impulse/ImpulseLua/submenus/session/all_players_menu")
    local state = AllPlayersMenu.state

    self:AddOption(ToggleOption.new("Exclude friends")
        :AddToggleRef(state, "friends")
        :AddTooltip("Exclude friends"))

    self:AddOption(ToggleOption.new("Exclude modders")
        :AddToggleRef(state, "modders")
        :AddTooltip("Exclude modders"))

    self:AddOption(ToggleOption.new("Exclude team")
        :AddToggleRef(state, "team")
        :AddTooltip("Exclude team"))

    self:AddOption(ToggleOption.new("Exclude host")
        :AddToggleRef(state, "host")
        :AddTooltip("Exclude host"))

    self:AddOption(ToggleOption.new("Exclude self")
        :AddToggleRef(state, "self")
        :AddTooltip("Exclude self"))
end

return ExcludesMenu
