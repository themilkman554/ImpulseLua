--[[
    Impulse Lua - Blackhole Menu
    Port of blackholeMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local BlackholeMenu = setmetatable({}, { __index = Submenu })
BlackholeMenu.__index = BlackholeMenu

local instance = nil

-- Menu state
local vars = {
    active = false,
    drawMarker = false,
    position = { x = 0.0, y = 0.0, z = 0.0 },
    strength = 2.0,
    
    -- Attraction settings
    attractVehicles = false,
    attractPedestrians = false,
    attractObjects = false,
    attractPlayerVehicles = false,
    
    -- Miscellaneous
    explosions = false,
    whitehole = false,
    typeSwitch = false,
    typeSwitchDelay = 500,
    
    -- Performance
    precisionIndex = 2, -- Medium default
    
    -- Internal timing
    lastSwitchTime = 0
}

-- Precision options
local PrecisionOptions = {
    { name = "Weak", value = 1 },
    { name = "Medium", value = 2 },
    { name = "High", value = 3 }
}

-- Helper: Get local player ped
local function GetLocalPed()
    return PLAYER.PLAYER_PED_ID()
end

-- Helper: Get local player coords
local function GetLocalCoords()
    return ENTITY.GET_ENTITY_COORDS(GetLocalPed(), true)
end

-- Helper: Request control of entity
local function RequestControlOfEnt(entity)
    if not ENTITY.DOES_ENTITY_EXIST(entity) then return false end
    if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then return true end
    
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
    return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
end

-- Helper: Get nearby entities (vehicles, peds, objects)
local function GetNearbyEntities(coords, radius)
    local entities = {}
    local localPed = GetLocalPed()
    local localVeh = PED.GET_VEHICLE_PED_IS_IN(localPed, false)
    
    -- Get vehicles
    if vars.attractVehicles or vars.attractPlayerVehicles then
        for i = 1, 200 do
            local veh = VEHICLE.GET_CLOSEST_VEHICLE(coords.x, coords.y, coords.z, radius, 0, 70)
            if veh and veh ~= 0 and veh ~= localVeh then
                if ENTITY.DOES_ENTITY_EXIST(veh) then
                    -- Check if player vehicle
                    local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh, -1, false)
                    local isPlayerVeh = driver ~= 0 and PED.IS_PED_A_PLAYER(driver)
                    
                    if (isPlayerVeh and vars.attractPlayerVehicles) or (not isPlayerVeh and vars.attractVehicles) then
                        table.insert(entities, veh)
                    end
                end
            end
            break
        end
    end
    
    return entities
end

function BlackholeMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Blackhole"), BlackholeMenu)
        instance:Init()
    end
    return instance
end

function BlackholeMenu:Init()
    -- Enable toggle
    self:AddOption(ToggleOption.new("Enabled")
        :AddToggleRef(vars, "active")
        :AddTooltip("Enable the blackhole")
        :AddHotkey())
        :SetDonor()
    -- Location section
    self:AddOption(BreakOption.new("Location"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "X")
        :SetNumber(vars.position, "x")
        :SetMin(-10000):SetMax(10000):SetStep(5.0)
        :SetFormat("%.2f")
        :AddTooltip("The x coordinate of the blackhole"))
        :SetDonor()
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Y")
        :SetNumber(vars.position, "y")
        :SetMin(-10000):SetMax(10000):SetStep(5.0)
        :SetFormat("%.2f")
        :AddTooltip("The y coordinate of the blackhole"))
        :SetDonor()
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Z")
        :SetNumber(vars.position, "z")
        :SetMin(-10000):SetMax(10000):SetStep(5.0)
        :SetFormat("%.2f")
        :AddTooltip("The z coordinate of the blackhole"))

    self:AddOption(ButtonOption.new("Set it to my location")
        :AddFunction(function()
            local coords = GetLocalCoords()
            vars.position.x = coords.x
            vars.position.y = coords.y
            vars.position.z = coords.z + 0.5
        end)
        :AddTooltip("Sets the blackhole position to your position (Everything will fly towards you)")
        :AddHotkey())
        :SetDonor()
    self:AddOption(ButtonOption.new("Set it above my head")
        :AddFunction(function()
            local coords = GetLocalCoords()
            vars.position.x = coords.x
            vars.position.y = coords.y
            vars.position.z = coords.z + 100.0
        end)
        :AddTooltip("Sets the blackhole position above you (Everything will fly above you)")
        :AddHotkey())
        :SetDonor()
    -- Attraction Settings section
    self:AddOption(BreakOption.new("Attraction Settings"))
    
    self:AddOption(ToggleOption.new("Vehicles")
        :AddToggleRef(vars, "attractVehicles")
        :AddTooltip("Attracts all vehicles except player vehicles")
        :AddHotkey())
        :SetDonor()
    self:AddOption(ToggleOption.new("Pedestrians")
        :AddToggleRef(vars, "attractPedestrians")
        :AddTooltip("Attracts all pedestrians")
        :AddHotkey())
        :SetDonor()
    self:AddOption(ToggleOption.new("Objects")
        :AddToggleRef(vars, "attractObjects")
        :AddTooltip("Attracts all objects that aren't frozen (e.g. traffic lights)")
        :AddHotkey())
        :SetDonor()
    
    self:AddOption(ToggleOption.new("Player Vehicles")
        :AddToggleRef(vars, "attractPlayerVehicles")
        :AddTooltip("Attracts all vehicles from other players")
        :AddHotkey())
        :SetDonor()
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Strength")
        :SetNumber(vars, "strength")
        :SetMin(0.0):SetMax(100.0):SetStep(0.1)
        :SetFormat("%.2f")
        :AddTooltip("The strength of the blackhole (Low = Entities hover, High = They form a ball)")
        :AddHotkey())
        :SetDonor()
    -- Miscellaneous section
    self:AddOption(BreakOption.new("Miscellaneous"))
    
    self:AddOption(ToggleOption.new("Whitehole")
        :AddToggleRef(vars, "whitehole")
        :AddTooltip("Push entities away from the location")
        :AddHotkey())
        :SetDonor()
    
    self:AddOption(ToggleOption.new("Explosions at location")
        :AddToggleRef(vars, "explosions")
        :AddTooltip("Spawns random explosions at the blackhole location")
        :AddHotkey())
        :SetDonor()
    
    self:AddOption(ToggleOption.new("Draw Marker")
        :AddToggleRef(vars, "drawMarker")
        :AddTooltip("Draw a red marker at the blackhole position")
        :AddHotkey())
        :SetDonor()
    
    self:AddOption(ToggleOption.new("Blackhole <-> Whitehole Switch")
        :AddToggleRef(vars, "typeSwitch")
        :AddTooltip("Automatically toggles between white and blackhole")
        :AddHotkey())
        :SetDonor()
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Switch Delay")
        :SetNumber(vars, "typeSwitchDelay")
        :SetMin(1):SetMax(10000):SetStep(50)
        :SetFormat("%d")
        :AddTooltip("Set the delay of switching to whitehole and back (ms)"))
        :SetDonor()
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Precision")
        :AddScroll(PrecisionOptions, 1)
        :AddIndexRef(vars, "precisionIndex")
        :AddTooltip("Set how precise the blackhole should be (Higher = Better but less FPS)"))
        :SetDonor()
end

function BlackholeMenu:FeatureUpdate()
    local gameTime = MISC.GET_GAME_TIMER()
    
    if vars.active then
        local localPed = GetLocalPed()
        local localVeh = PED.GET_VEHICLE_PED_IS_IN(localPed, false)
        
        -- Process vehicles using PoolMgr
        if vars.attractVehicles or vars.attractPlayerVehicles then
            local vehCount = PoolMgr.GetCurrentVehicleCount()
            for i = 0, vehCount - 1 do
                local veh = PoolMgr.GetVehicle(i)
                if veh and veh ~= 0 and veh ~= localVeh and ENTITY.DOES_ENTITY_EXIST(veh) then
                    local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh, -1, false)
                    local isPlayerVeh = driver ~= 0 and PED.IS_PED_A_PLAYER(driver)
                    
                    if (isPlayerVeh and vars.attractPlayerVehicles) or (not isPlayerVeh and vars.attractVehicles) then
                        if RequestControlOfEnt(veh) then
                            local pos = ENTITY.GET_ENTITY_COORDS(veh, true)
                            local forceX, forceY, forceZ
                            
                            if vars.whitehole then
                                forceX = (pos.x - vars.position.x) / 25.0 * vars.strength
                                forceY = (pos.y - vars.position.y) / 25.0 * vars.strength
                                forceZ = (pos.z - vars.position.z) / 25.0 * vars.strength
                            else
                                forceX = (vars.position.x - pos.x) / 25.0 * vars.strength
                                forceY = (vars.position.y - pos.y) / 25.0 * vars.strength
                                forceZ = (vars.position.z - pos.z) / 25.0 * vars.strength
                            end
                            
                            ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, forceX, forceY, forceZ, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                        end
                    end
                end
            end
        end
        
        -- Process peds using PoolMgr
        if vars.attractPedestrians then
            local pedCount = PoolMgr.GetCurrentPedCount()
            for i = 0, pedCount - 1 do
                local ped = PoolMgr.GetPed(i)
                if ped and ped ~= 0 and ped ~= localPed and ENTITY.DOES_ENTITY_EXIST(ped) and not PED.IS_PED_A_PLAYER(ped) then
                    if RequestControlOfEnt(ped) then
                        local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
                        local forceX, forceY, forceZ
                        
                        if vars.whitehole then
                            forceX = (pos.x - vars.position.x) / 25.0 * vars.strength
                            forceY = (pos.y - vars.position.y) / 25.0 * vars.strength
                            forceZ = (pos.z - vars.position.z) / 25.0 * vars.strength
                        else
                            forceX = (vars.position.x - pos.x) / 25.0 * vars.strength
                            forceY = (vars.position.y - pos.y) / 25.0 * vars.strength
                            forceZ = (vars.position.z - pos.z) / 25.0 * vars.strength
                        end
                        
                        ENTITY.APPLY_FORCE_TO_ENTITY(ped, 1, forceX, forceY, forceZ, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                    end
                end
            end
        end
        
        -- Process objects using PoolMgr
        if vars.attractObjects then
            local objCount = PoolMgr.GetCurrentObjectCount()
            for i = 0, objCount - 1 do
                local obj = PoolMgr.GetObject(i)
                if obj and obj ~= 0 and ENTITY.DOES_ENTITY_EXIST(obj) then
                    if RequestControlOfEnt(obj) then
                        local pos = ENTITY.GET_ENTITY_COORDS(obj, true)
                        local forceX, forceY, forceZ
                        
                        if vars.whitehole then
                            forceX = (pos.x - vars.position.x) / 25.0 * vars.strength
                            forceY = (pos.y - vars.position.y) / 25.0 * vars.strength
                            forceZ = (pos.z - vars.position.z) / 25.0 * vars.strength
                        else
                            forceX = (vars.position.x - pos.x) / 25.0 * vars.strength
                            forceY = (vars.position.y - pos.y) / 25.0 * vars.strength
                            forceZ = (vars.position.z - pos.z) / 25.0 * vars.strength
                        end
                        
                        ENTITY.APPLY_FORCE_TO_ENTITY(obj, 1, forceX, forceY, forceZ, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                    end
                end
            end
        end
        
        -- Explosions
        if vars.explosions then
            local xOffset = math.random() * 20.0 - 10.0
            local yOffset = math.random() * 20.0 - 10.0
            local zOffset = math.random() * 20.0 - 10.0
            FIRE.ADD_EXPLOSION(vars.position.x + xOffset, vars.position.y + yOffset, vars.position.z + zOffset, 32, 500.0, true, false, 1.0, false)
        end
        
        -- Type switch
        if vars.typeSwitch then
            if gameTime - vars.lastSwitchTime > vars.typeSwitchDelay then
                vars.whitehole = not vars.whitehole
                vars.lastSwitchTime = gameTime
            end
        end
    end
    
    -- Draw marker
    if vars.drawMarker then
        GRAPHICS.DRAW_MARKER(21, vars.position.x, vars.position.y, vars.position.z, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.9, 0.9, 0.9, 255, 0, 0, 255, true, false, 2, true, nil, nil, false)
    end
end

return BlackholeMenu
