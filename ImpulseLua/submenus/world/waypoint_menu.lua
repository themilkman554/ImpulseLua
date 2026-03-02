--[[
    Impulse Lua - Waypoint Menu
    Port of waypointMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")

local WaypointMenu = setmetatable({}, { __index = Submenu })
WaypointMenu.__index = WaypointMenu

local instance = nil

-- Variables
local vars = {
    explode = false,
    moneydrop = false,
    drivingtowaypoint = false,
    explodeTimer = 0,
    moneyTimer = 0
}

local function GetLocalPed()
    return PLAYER.PLAYER_PED_ID()
end

local function GetLocalCoords()
    return ENTITY.GET_ENTITY_COORDS(GetLocalPed(), true)
end

-- Get waypoint coordinates
local function GetWaypointCoords()
    if HUD.IS_WAYPOINT_ACTIVE() then
        local blip = HUD.GET_FIRST_BLIP_INFO_ID(8) -- Waypoint blip
        if HUD.DOES_BLIP_EXIST(blip) then
            local coords = HUD.GET_BLIP_INFO_ID_COORD(blip)
            -- Get ground Z coordinate
            local groundZ = 0.0
            local success, z = MISC.GET_GROUND_Z_FOR_3D_COORD(coords.x, coords.y, coords.z + 1000.0, groundZ, false, false)
            if success then
                coords.z = z
            else
                coords.z = 0.0
            end
            return coords
        end
    end
    return { x = 0, y = 0, z = 0 }
end

-- Explode at waypoint
local function Explode()
    if HUD.IS_WAYPOINT_ACTIVE() then
        local now = MISC.GET_GAME_TIMER()
        if now > vars.explodeTimer then
            local coords = GetWaypointCoords()
            if coords.z ~= 0 then
                FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 0, 5.0, true, false, 0.0, false)
            end
            vars.explodeTimer = now + 250
        end
    end
end

-- Money drop at waypoint
local function MoneyDrop()
    if HUD.IS_WAYPOINT_ACTIVE() then
        local now = MISC.GET_GAME_TIMER()
        if now > vars.moneyTimer then
            local hash = MISC.GET_HASH_KEY("prop_money_bag_01")
            STREAMING.REQUEST_MODEL(hash)
            
            local coords = GetWaypointCoords()
            if coords.z ~= 0 then
                coords.x = coords.x + math.random(0, 10)
                coords.y = coords.y + math.random(0, 10)
                coords.z = coords.z + math.random(5, 10)
                OBJECT.CREATE_MONEY_PICKUPS(coords.x, coords.y, coords.z, 0x1E9A99F8, 2500, hash)
            end
            vars.moneyTimer = now + 500
        end
    end
end

-- Send police to waypoint
local function SendPoliceToWaypoint()
    if not HUD.IS_WAYPOINT_ACTIVE() then return end
    
    local vehicleHash = MISC.GET_HASH_KEY("POLICE3")
    STREAMING.REQUEST_MODEL(vehicleHash)
    
    local timeout = 0
    while not STREAMING.HAS_MODEL_LOADED(vehicleHash) and timeout < 50 do
        Script.Yield()
        timeout = timeout + 1
    end
    
    local ped = GetLocalPed()
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 5.0, 0)
    local heading = ENTITY.GET_ENTITY_HEADING(ped)
    
    local veh = VEHICLE.CREATE_VEHICLE(vehicleHash, pos.x, pos.y, pos.z, heading, true, false, true)
    if ENTITY.DOES_ENTITY_EXIST(veh) then
        local driver = PED.CREATE_RANDOM_PED_AS_DRIVER(veh, false)
        DECORATOR.DECOR_SET_INT(veh, "MPBitset", 0)
        VEHICLE.SET_VEHICLE_IS_STOLEN(veh, false)
        VEHICLE.SET_VEHICLE_SIREN(veh, true)
        PED.SET_PED_INTO_VEHICLE(driver, veh, -1)
        
        local waypoint = GetWaypointCoords()
        BRAIN.TASK_VEHICLE_DRIVE_TO_COORD(driver, veh, waypoint.x, waypoint.y, waypoint.z, 40.0, 1, vehicleHash, 7, 6, -1.0)
    end
    
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehicleHash)
end

-- Drive to waypoint
local function DriveToWaypoint()
    if not HUD.IS_WAYPOINT_ACTIVE() then
        return
    end
    
    local ped = GetLocalPed()
    if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        vars.drivingtowaypoint = true
        local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        local waypoint = GetWaypointCoords()
        local model = ENTITY.GET_ENTITY_MODEL(veh)
        BRAIN.TASK_VEHICLE_DRIVE_TO_COORD(ped, veh, waypoint.x, waypoint.y, waypoint.z, 40.0, 1, model, 7, 6, -1.0)
    end
end

-- Stop auto drive
local function StopAutoDrive()
    vars.drivingtowaypoint = false
    local ped = GetLocalPed()
    if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        BRAIN.CLEAR_PED_TASKS_IMMEDIATELY(ped)
        PED.SET_PED_INTO_VEHICLE(ped, veh, -1)
    end
end

-- Check auto drive completion
local function CheckAutoDrive()
    if HUD.IS_WAYPOINT_ACTIVE() then
        local waypoint = GetWaypointCoords()
        local coords = GetLocalCoords()
        local dist = MISC.GET_DISTANCE_BETWEEN_COORDS(coords.x, coords.y, coords.z, waypoint.x, waypoint.y, waypoint.z, false)
        if dist < 50 then
            StopAutoDrive()
        end
    else
        StopAutoDrive()
    end
end

function WaypointMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Waypoint"), WaypointMenu)
        instance:Init()
    end
    return instance
end

function WaypointMenu:Init()
    self:AddOption(ToggleOption.new("Explode")
        :AddToggle(vars.explode)
        :AddFunction(function(val) vars.explode = val end)
        :AddTooltip("Explode at waypoint"))

    self:AddOption(ToggleOption.new("Money drop")
        :AddToggle(vars.moneydrop)
        :AddFunction(function(val) vars.moneydrop = val end)
        :AddTooltip("Money drop at waypoint"))

    self:AddOption(ButtonOption.new("Send police")
        :AddFunction(SendPoliceToWaypoint)
        :AddTooltip("Send police to waypoint"))

    self:AddOption(ButtonOption.new("Auto drive to waypoint")
        :AddFunction(DriveToWaypoint)
        :AddTooltip("Automatically drive to waypoint"))

    self:AddOption(ButtonOption.new("Stop auto drive")
        :AddFunction(StopAutoDrive)
        :AddTooltip("Stop autodrive"))
end

function WaypointMenu:FeatureUpdate()
    if vars.explode then Explode() end
    if vars.moneydrop then MoneyDrop() end
    if vars.drivingtowaypoint then CheckAutoDrive() end
end

return WaypointMenu
