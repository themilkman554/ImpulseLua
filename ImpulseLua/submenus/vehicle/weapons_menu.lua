--[[
    Impulse Lua - Vehicle Weapons Menu
    Port of vehicleWeaponsMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local WeaponsMenu = setmetatable({}, { __index = Submenu })
WeaponsMenu.__index = WeaponsMenu

local instance = nil

-- Bullet types
local bulletTypes = {
    { name = "RPG", hash = 0xB1CA77B1 },
    { name = "Firework", hash = 0x7F7497E5 },
    { name = "Tank", hash = 0x73F7C04B },
    { name = "Space Rocket", hash = 0xF8A3939F },
    { name = "Plane Rocket", hash = 0xCF0896E0 },
    { name = "Snowball", hash = 0x787F0BB },
    { name = "Flare", hash = 0x497FACC3 }
}

local vars = {
    enabled = false,
    bulletType = 1,
    bulletSpeed = 1000,
    guided = false,
    responsibility = true
}

-- Helper: Check if player is in vehicle
local function IsInVehicle()
    local ped = PLAYER.PLAYER_PED_ID()
    return PED.IS_PED_IN_ANY_VEHICLE(ped, false)
end

-- Helper: Get current vehicle
local function GetCurrentVehicle()
    local ped = PLAYER.PLAYER_PED_ID()
    return PED.GET_VEHICLE_PED_IS_IN(ped, false)
end

-- Vehicle weapons feature
local function VehicleWeapons()
    if not IsInVehicle() then return end
    
    local veh = GetCurrentVehicle()
    local model = ENTITY.GET_ENTITY_MODEL(veh)
    
    -- Get model dimensions
    local minPtr = Memory.Alloc(24)
    local maxPtr = Memory.Alloc(24)
    MISC.GET_MODEL_DIMENSIONS(model, minPtr, maxPtr)
    local maxX = Memory.ReadFloat(maxPtr)
    local maxY = Memory.ReadFloat(maxPtr + 4)
    Memory.Free(minPtr)
    Memory.Free(maxPtr)
    
    -- Get shoot positions
    local vehL = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(veh, -(maxX + 0.25), maxY + 1.25, 0.1)
    local vehR = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(veh, maxX + 0.25, maxY + 1.25, 0.1)
    local vehLEnd = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(veh, -maxX, maxY + 100.0, 0.1)
    local vehREnd = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(veh, maxX, maxY + 100.0, 0.1)
    
    -- Check fire input (spacebar or controller)
    local firePressed = Utils.IsKeyPressed(0x20) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 69)
    
    if firePressed then
        local bulletHash = bulletTypes[vars.bulletType].hash
        local owner = vars.responsibility and PLAYER.PLAYER_PED_ID() or 0
        
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(vehL.x, vehL.y, vehL.z, vehLEnd.x, vehLEnd.y, vehLEnd.z, 
            5000, false, bulletHash, owner, false, false, vars.bulletSpeed + 0.0)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(vehR.x, vehR.y, vehR.z, vehREnd.x, vehREnd.y, vehREnd.z, 
            5000, false, bulletHash, owner, false, false, vars.bulletSpeed + 0.0)
    end
    
    -- Draw guide lines
    if vars.guided then
        GRAPHICS.DRAW_LINE(vehL.x, vehL.y, vehL.z, vehLEnd.x, vehLEnd.y, vehLEnd.z, 255, 0, 0, 255)
        GRAPHICS.DRAW_LINE(vehR.x, vehR.y, vehR.z, vehREnd.x, vehREnd.y, vehREnd.z, 255, 0, 0, 255)
    end
end

function WeaponsMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Vehicle weapons"), WeaponsMenu)
        instance:Init()
    end
    return instance
end

function WeaponsMenu:Init()
    -- Bullet type
    local bulletNames = {}
    for i, bt in ipairs(bulletTypes) do
        bulletNames[i] = bt.name
    end
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Bullet type")
        :AddScroll(bulletNames, 1)
        :AddIndexRef(vars, "bulletType")
        :AddTooltip("Select bullet type"))
    
    -- Bullet speed
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Bullet speed")
        :AddNumberRef(vars, "bulletSpeed", "%d", 100)
        :AddMin(0):AddMax(10000)
        :AddTooltip("Set bullet speed"))
    
    -- Guided
    self:AddOption(ToggleOption.new("Guided")
        :AddToggleRef(vars, "guided")
        :AddTooltip("Show where you're aiming"))
    
    -- Take responsibility
    self:AddOption(ToggleOption.new("Take responsibility")
        :AddToggleRef(vars, "responsibility")
        :AddTooltip("Show who shot the bullet"))
    
    -- Enabled
    self:AddOption(ToggleOption.new("Enabled")
        :AddToggleRef(vars, "enabled")
        :AddTooltip("Enable vehicle weapons"))
end

function WeaponsMenu:FeatureUpdate()
    if vars.enabled then
        VehicleWeapons()
    end
end

return WeaponsMenu
