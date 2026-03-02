--[[
    Impulse Lua - Inside Teleport Menu
    Port of insideTeleportMenu.cpp from Impulse C++
    Teleport locations for inside/interior spots
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class InsideTeleportMenu : Submenu
local InsideTeleportMenu = setmetatable({}, { __index = Submenu })
InsideTeleportMenu.__index = InsideTeleportMenu

-- Inside teleport locations
local InsideLocations = {
    { name = "Strip Club DJ Booth", x = 126.135, y = -1278.583, z = 29.270 },
    { name = "Humane Labs Tunnel", x = 3525.495, y = 3705.301, z = 20.992 },
    { name = "Police Station", x = 436.491, y = -982.172, z = 30.699 },
    { name = "FIB Top Floor", x = 135.733, y = -749.216, z = 258.152 },
    { name = "IAA Office", x = 117.220, y = -620.938, z = 206.047 },
    { name = "Torture Room", x = 147.170, y = -2201.804, z = 4.688 },
    { name = "Ammunation Gun Range", x = 22.153, y = -1072.854, z = 29.797 },
    { name = "Ammunation Office", x = 12.494, y = -1110.130, z = 29.797 },
    { name = "Blaine County Savings Bank", x = -109.299, y = 6464.035, z = 31.627 },
    { name = "Fort Zancudo ATC Top Floor", x = -2358.132, y = 3249.754, z = 101.451 },
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

--- Create a new InsideTeleportMenu
---@return InsideTeleportMenu
function InsideTeleportMenu.new()
    local self = setmetatable(Submenu.new("Inside"), InsideTeleportMenu)
    return self
end

function InsideTeleportMenu:Init()
    for _, loc in ipairs(InsideLocations) do
        self:AddOption(ButtonOption.new(loc.name)
            :AddFunction(function()
                TeleportToCoords(loc.x, loc.y, loc.z)
                Renderer.Notify("Teleported to " .. loc.name)
            end)
            :AddTooltip("Teleport to " .. loc.name)
            :AddHotkey())
    end
end

function InsideTeleportMenu:FeatureUpdate()
    -- Nothing to update
end

return InsideTeleportMenu
