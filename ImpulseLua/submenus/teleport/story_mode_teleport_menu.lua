--[[
    Impulse Lua - Story Mode Teleport Menu
    Port of storyModeTeleportMenu.cpp from Impulse C++
    Teleport locations for story mode character locations
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class StoryModeTeleportMenu : Submenu
local StoryModeTeleportMenu = setmetatable({}, { __index = Submenu })
StoryModeTeleportMenu.__index = StoryModeTeleportMenu

-- Story mode teleport locations (from C++)
local StoryModeLocations = {
    { name = "Franklin's New House", x = 7.4150, y = 535.5486, z = 176.0279 },
    { name = "Franklin's Old House", x = -14.9693, y = -1436.4430, z = 31.1185 },
    { name = "Michael's House", x = -813.6030, y = 179.4738, z = 72.1589 },
    { name = "Lester's House", x = 1273.69, y = -1718.72, z = 54.68 },
    { name = "Wayne's Cousin's House", x = -1159.034, y = -1521.180, z = 10.6327 },
    { name = "Trevor's House", x = 1974.7580, y = 3819.4570, z = 33.4363 },
    { name = "Trevor's Meth Lab", x = 1397.5240, y = 3607.4230, z = 38.9419 },
    { name = "Trevor's Office", x = 97.2707, y = -1290.9940, z = 29.2688 },
    { name = "Floyd's Apartment", x = -1150.703, y = -1520.713, z = 10.633 },
}

--- Teleport to coordinates
local function TeleportToCoords(x, y, z)
    local ped = PLAYER.PLAYER_PED_ID()
    local entity = ped
    if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        entity = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    end
    ENTITY.SET_ENTITY_COORDS(entity, x, y, z, false, false, false, true)
end

--- Create a new StoryModeTeleportMenu
---@return StoryModeTeleportMenu
function StoryModeTeleportMenu.new()
    local self = setmetatable(Submenu.new("Story mode locations"), StoryModeTeleportMenu)
    return self
end

function StoryModeTeleportMenu:Init()
    for _, loc in ipairs(StoryModeLocations) do
        self:AddOption(ButtonOption.new(loc.name)
            :AddFunction(function()
                TeleportToCoords(loc.x, loc.y, loc.z)
                Renderer.Notify("Teleported to " .. loc.name)
            end)
            :AddTooltip("Teleport to " .. loc.name)
            :AddHotkey())
    end
end

function StoryModeTeleportMenu:FeatureUpdate()
    -- Nothing to update
end

return StoryModeTeleportMenu
