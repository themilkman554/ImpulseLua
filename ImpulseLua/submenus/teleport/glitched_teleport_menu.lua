--[[
    Impulse Lua - Glitched Teleport Menu
    Port of glitchedTeleportMenu.cpp from Impulse C++
    Teleport locations for glitched spots
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class GlitchedTeleportMenu : Submenu
local GlitchedTeleportMenu = setmetatable({}, { __index = Submenu })
GlitchedTeleportMenu.__index = GlitchedTeleportMenu

-- Glitched teleport locations
local GlitchedLocations = {
    { name = "Race Underground Bunker", x = 403.78, y = -961.35, z = -99.00 },
    { name = "FIB Roof Glitch", x = 135.9541, y = -749.8984, z = 258.1520 },
    { name = "Police Station Glitch", x = 447.0900, y = -985.5400, z = 30.9600 },
    { name = "Behind Bar In Strip Club", x = 126.1211, y = -1278.5130, z = 29.2696 },
    { name = "Building Glitch", x = -91.6870, y = 33.0948, z = 71.4655 },
    { name = "Inside Store", x = -1244.1380, y = -1454.9980, z = 4.3478 },
    { name = "City Wall Glitch", x = -254.9432, y = -147.3534, z = 42.7314 },
    { name = "Inside Casino", x = 937.4756, y = 42.4248, z = 80.8990 },
    { name = "Beach House", x = -1907.3500, y = -577.2352, z = 20.1223 },
    { name = "Under The Bridge Glitch", x = 721.6599, y = -1000.6510, z = 23.5455 },
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

--- Create a new GlitchedTeleportMenu
---@return GlitchedTeleportMenu
function GlitchedTeleportMenu.new()
    local self = setmetatable(Submenu.new("Glitched"), GlitchedTeleportMenu)
    return self
end

function GlitchedTeleportMenu:Init()
    for _, loc in ipairs(GlitchedLocations) do
        self:AddOption(ButtonOption.new(loc.name)
            :AddFunction(function()
                TeleportToCoords(loc.x, loc.y, loc.z)
                Renderer.Notify("Teleported to " .. loc.name)
            end)
            :AddTooltip("Teleport to " .. loc.name)
            :AddHotkey())
    end
end

function GlitchedTeleportMenu:FeatureUpdate()
    -- Nothing to update
end

return GlitchedTeleportMenu
