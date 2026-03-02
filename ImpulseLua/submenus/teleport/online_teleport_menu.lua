--[[
    Impulse Lua - Online Teleport Menu
    Port of onlineTeleportsMenu.cpp from Impulse C++
    Teleport locations for online spots
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class OnlineTeleportMenu : Submenu
local OnlineTeleportMenu = setmetatable({}, { __index = Submenu })
OnlineTeleportMenu.__index = OnlineTeleportMenu

-- Online teleport locations (from C++)
local OnlineLocations = {
    { name = "Casino", x = 925.78, y = 85.68, z = 78.86 },
    { name = "Mors Mutual Insurance", x = -222.1977, y = -1185.8500, z = 23.0294 },
    { name = "Mask Shop", x = -1338.16, y = -1278.11, z = 4.87 },
    { name = "Tattoo Shop", x = -1155.7309, y = -1422.5162, z = 4.7751 },
    { name = "Ammunation", x = 247.3652, y = -45.8777, z = 69.9411 },
    { name = "Clothes Store", x = -718.91, y = -158.16, z = 37.00 },
    { name = "LS Customs", x = -373.01, y = -124.91, z = 38.31 },
    { name = "Benny's vehicles", x = -210.6698, y = -1301.3829, z = 31.2959 },
    { name = "Ammunation Gun Range", x = 22.153, y = -1072.854, z = 29.797 },
    { name = "Ammunation Office", x = 12.494, y = -1110.130, z = 29.797 },
    { name = "LS Airport Customs", x = -1134.224, y = -1984.387, z = 13.166 },
    { name = "La Mesa Customs", x = 709.797, y = -1082.649, z = 22.398 },
    { name = "Senora Desert Customs", x = 1178.653, y = 2666.179, z = 37.881 },
    { name = "Beek Customs", x = 126.219, y = 6608.142, z = 31.866 },
    { name = "Eclipse Towers", x = -807.247, y = 301.868, z = 86.073 },
    { name = "Eclipse Towers Roof", x = -779.026, y = 331.695, z = 238.828 },
    { name = "Impound Lot", x = 401.057, y = -1631.766, z = 29.293 },
    { name = "Eclipse Towers Inside", x = -778.34, y = 339.97, z = 208.62 },
    { name = "Online Hidden Race Area", x = 403.78, y = -961.35, z = -99.00 },
    { name = "Airport Tower", x = -985.1005, y = -2642.046, z = 63.5170 },
    { name = "Maze Bank CEO Office Entrance", x = -52.70, y = -777.51, z = 44.19 },
    { name = "Helipad", x = -749.50, y = -1476.89, z = 5.0 },
    { name = "King Of The Hill", x = -1192.53, y = -1781.78, z = 19.13 },
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

--- Create a new OnlineTeleportMenu
---@return OnlineTeleportMenu
function OnlineTeleportMenu.new()
    local self = setmetatable(Submenu.new("Online"), OnlineTeleportMenu)
    return self
end

function OnlineTeleportMenu:Init()
    for _, loc in ipairs(OnlineLocations) do
        self:AddOption(ButtonOption.new(loc.name)
            :AddFunction(function()
                TeleportToCoords(loc.x, loc.y, loc.z)
                Renderer.Notify("Teleported to " .. loc.name)
            end)
            :AddTooltip("Teleport to " .. loc.name)
            :AddHotkey())
    end
end

function OnlineTeleportMenu:FeatureUpdate()
    -- Nothing to update
end

return OnlineTeleportMenu
