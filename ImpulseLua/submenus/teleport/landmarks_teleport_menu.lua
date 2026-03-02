--[[
    Impulse Lua - Landmarks Teleport Menu
    Port of landmarksTeleportMenu.cpp from Impulse C++
    Teleport locations for famous landmarks
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class LandmarksTeleportMenu : Submenu
local LandmarksTeleportMenu = setmetatable({}, { __index = Submenu })
LandmarksTeleportMenu.__index = LandmarksTeleportMenu

-- Landmarks teleport locations (from C++)
local LandmarksLocations = {
    { name = "Airport", x = -1135.1100, y = -2885.2030, z = 15.00 },
    { name = "Prison", x = 1679.0490, y = 2513.7110, z = 45.5649 },
    { name = "Prison Gym", x = 1640.7910, y = 2530.0440, z = 45.5649 },
    { name = "Prison Tower", x = 1541.6290, y = 2470.1400, z = 62.8751 },
    { name = "Lighthouse", x = 3433.6570, y = 5175.4090, z = 35.8053 },
    { name = "Cannibal Camp", x = -1138.67, y = 4921.97, z = 220.07 },
    { name = "Mount Josiah", x = -1186.1070, y = 3849.7530, z = 489.0641 },
    { name = "Maze Bank Helipad", x = -73.92588, y = -818.455078, z = 326.174377 },
    { name = "Fort Zancudo", x = -2012.8470, y = 2956.5270, z = 32.8101 },
    { name = "Calafia Bridge", x = -175.2189, y = 4244.1940, z = 44.0730 },
    { name = "Pier", x = -1709.98, y = -1085.03, z = 13.10 },
    { name = "Mount Chiliad", x = 496.75, y = 5591.17, z = 795.03 },
    { name = "Mount Chiliad (Jump)", x = 430.2037, y = 5614.7340, z = 766.1684 },
    { name = "Elysian Island Base", x = 574.3914, y = -3121.3220, z = 18.7687 },
    { name = "Ontop of Vinewood Logo", x = 776.8780, y = 1175.6080, z = 345.9564 },
    { name = "Trevor's Air Field", x = 1741.4960, y = 3269.2570, z = 41.6014 },
    { name = "Mount Gordo", x = 2948.4480, y = 5323.8120, z = 101.1872 },
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

--- Create a new LandmarksTeleportMenu
---@return LandmarksTeleportMenu
function LandmarksTeleportMenu.new()
    local self = setmetatable(Submenu.new("Landmarks"), LandmarksTeleportMenu)
    return self
end

function LandmarksTeleportMenu:Init()
    for _, loc in ipairs(LandmarksLocations) do
        self:AddOption(ButtonOption.new(loc.name)
            :AddFunction(function()
                TeleportToCoords(loc.x, loc.y, loc.z)
                Renderer.Notify("Teleported to " .. loc.name)
            end)
            :AddTooltip("Teleport to " .. loc.name)
            :AddHotkey())
    end
end

function LandmarksTeleportMenu:FeatureUpdate()
    -- Nothing to update
end

return LandmarksTeleportMenu
