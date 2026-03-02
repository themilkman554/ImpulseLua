--[[
    Impulse Lua - Player Drops Menu
    Drops options for selected player
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local PlayerMenu = nil

local PlayerDropsMenu = setmetatable({}, { __index = Submenu })
PlayerDropsMenu.__index = PlayerDropsMenu

local instance = nil

local dropsState = {
    dropTypeIndex = 1,
    dropLoop = false,
}

local dropTypes = {
    { name = "Money" },
    { name = "Money + RP" },
    { name = "Chips + RP" },
}

local function GetSelectedPlayerId()
    if not PlayerMenu then
        PlayerMenu = require("Impulse/ImpulseLua/submenus/session/player_menu")
    end
    return PlayerMenu.targetPlayer or -1
end

local function GetSelectedPlayerName()
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then return "Unknown" end
    return PLAYER.GET_PLAYER_NAME(playerId) or "Unknown"
end

function PlayerDropsMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Drops"), PlayerDropsMenu)
        instance:Init()
    end
    return instance
end

function PlayerDropsMenu:Init()
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Drop Type")
        :AddScroll(dropTypes, 1)
        :AddIndexRef(dropsState, "dropTypeIndex")
        :CanLoop()
        :AddFunction(function()
            FeatureMgr.SetFeatureListIndex(3236827509, dropsState.dropTypeIndex - 1)
        end)
        :AddTooltip("Select type of drop"))
    
    self:AddOption(ToggleOption.new("Drop", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            dropsState.dropLoop = value
            
            FeatureMgr.GetFeatureByName("Drop", playerId):SetValue(value):TriggerCallback()
            
            if value then
                Renderer.Notify("Started dropping " .. dropTypes[dropsState.dropTypeIndex].name .. " on " .. GetSelectedPlayerName())
            else
                Renderer.Notify("Stopped dropping on " .. GetSelectedPlayerName())
            end
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local feature = FeatureMgr.GetFeatureByName("Drop", playerId)
            if feature then
                local toggled = feature:IsToggled()
                dropsState.dropLoop = toggled
                return toggled
            end
        end
        return dropsState.dropLoop
    end)
        :AddTooltip("Toggle the drop loop (cherax blocks enableing this feature)"))

end

return PlayerDropsMenu
