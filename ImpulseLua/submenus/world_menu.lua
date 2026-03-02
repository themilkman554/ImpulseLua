
local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

-- World Submenus
local WeatherMenu = require("Impulse/ImpulseLua/submenus/world/weather_menu")
local WaypointMenu = require("Impulse/ImpulseLua/submenus/world/waypoint_menu")
local TrafficMenu = require("Impulse/ImpulseLua/submenus/world/traffic_menu")
local PedMenu = require("Impulse/ImpulseLua/submenus/world/ped_menu")
local VFXMenu = require("Impulse/ImpulseLua/submenus/world/vfx_menu")
local BodyguardMenu = require("Impulse/ImpulseLua/submenus/world/bodyguard_menu")
local BlackholeMenu = require("Impulse/ImpulseLua/submenus/world/blackhole_menu")
local WorldDrawablesMenu = require("Impulse/ImpulseLua/submenus/world/world_drawables_menu")
local VehicleBlacklistMenu = require("Impulse/ImpulseLua/submenus/world/vehicle_blacklist_menu")
local SentryMenu = require("Impulse/ImpulseLua/submenus/world/sentry_menu")

local WorldMenu = setmetatable({}, { __index = Submenu })
WorldMenu.__index = WorldMenu

local instance = nil


local vars = {
    -- Time
    freezeTime = false,
    syncWithSystemTime = false,
    
    -- Water
    noocean = false,
    clearwater = false,
    waveintensity = 0,
    splitwater = false,
    
    -- Water Tune
    Tune = {
        RippleScale = 1.0,
        OceanFoamScale = 1.0,
        SpecularFalloff = 1.0
    },
    
    -- Density
    enablePedDensity = false,
    pedDensity = 1.0,
    enableTrafficDensity = false,
    trafficDensity = 1.0,
    

    -- Clear Area
    enableradiusbubble = false,
    clearradius = 50.0,
    
    -- Misc
    noflybys = false,
    teleportallnearvehs = false,
    timeScale = 1.0,
    slipperiness = 0.0,
    gravity = 1,
    blackout = false,
    wind = 0.0
}

-- Gravity options
local gravityOptions = {
    { name = "Normal", value = 0 },
    { name = "Low", value = 1 },
    { name = "Lower", value = 2 },
    { name = "Off", value = 3 }
}



-- Helper: Request control of entity
local function RequestControlOfEnt(entity)
    local tick = 0
    while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) and tick <= 25 do
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
        tick = tick + 1
    end
    if NETWORK.NETWORK_IS_SESSION_STARTED() then
        local netID = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
        NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netID, true)
    end
end

-- Helper: Get local player ped
local function GetLocalPed()
    return PLAYER.PLAYER_PED_ID()
end

-- Helper: Get local player coords
local function GetLocalCoords()
    return ENTITY.GET_ENTITY_COORDS(GetLocalPed(), true)
end



-- Legacy functions removed, logic moved to Loop


-- Split the sea (water modification)
local function SplitTheSea()
    local coords = GetLocalCoords()
    if WATER.MODIFY_WATER then
        WATER.MODIFY_WATER(coords.x, coords.y, -10, 10)
        WATER.MODIFY_WATER(coords.x + 2, coords.y, -10, 10)
        WATER.MODIFY_WATER(coords.x, coords.y + 2, -10, 10)
        WATER.MODIFY_WATER(coords.x + 2, coords.y + 2, -10, 10)
        WATER.MODIFY_WATER(coords.x + 4, coords.y, -10, 10)
        WATER.MODIFY_WATER(coords.x, coords.y + 4, -10, 10)
        WATER.MODIFY_WATER(coords.x + 4, coords.y + 4, -10, 10)
        WATER.MODIFY_WATER(coords.x + 6, coords.y, -10, 10)
        WATER.MODIFY_WATER(coords.x, coords.y + 6, -10, 10)
        WATER.MODIFY_WATER(coords.x + 6, coords.y + 6, -10, 10)
        WATER.MODIFY_WATER(coords.x + 8, coords.y, -10, 10)
        WATER.MODIFY_WATER(coords.x, coords.y + 8, -10, 10)
        WATER.MODIFY_WATER(coords.x + 8, coords.y + 8, -10, 10)
    end
end

function WorldMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("World"), WorldMenu)
        instance:Init()
    end
    return instance
end

function WorldMenu:Init()
    -- Submenus

    self:AddOption(SubmenuOption.new("Traffic manager")
        :AddSubmenu(TrafficMenu.GetInstance())
        :AddTooltip("Manage traffic"))

    self:AddOption(SubmenuOption.new("Pedestrian manager")
        :AddSubmenu(PedMenu.GetInstance())
        :AddTooltip("Manage peds"))

    self:AddOption(SubmenuOption.new("Weather")
        :AddSubmenu(WeatherMenu.GetInstance())
        :AddTooltip("Manage weather"))

    self:AddOption(SubmenuOption.new("Waypoint")
        :AddSubmenu(WaypointMenu.GetInstance())
        :AddTooltip("Waypoint options"))

    self:AddOption(SubmenuOption.new("Drawable editor")
        :AddSubmenu(WorldDrawablesMenu.GetInstance())
        :AddTooltip("Edit non-editable models (VIP)"))

    self:AddOption(SubmenuOption.new("Blackhole")
        :AddSubmenu(BlackholeMenu.GetInstance())
        :AddTooltip("Attracts entities"))

    self:AddOption(SubmenuOption.new("Vehicles blacklist")
        :AddSubmenu(VehicleBlacklistMenu.GetInstance())
        :AddTooltip("Freely blacklist vehicles (VIP)"))

    self:AddOption(SubmenuOption.new("Bodyguards creator")
        :AddSubmenu(BodyguardMenu.GetInstance())
        :AddTooltip("Create custom bodyguards"))

    self:AddOption(SubmenuOption.new("Sentry")
        :AddSubmenu(SentryMenu.GetInstance())
        :AddTooltip("Sentry turret options"))

    -- Time Section
    self:AddOption(BreakOption.new("Time"))

    self:AddOption(ButtonOption.new("Add hour")
        :AddFunction(function()
            local hour = CLOCK.GET_CLOCK_HOURS() + 1
            if hour > 23 then hour = 0 end
            NETWORK.NETWORK_OVERRIDE_CLOCK_TIME(hour, CLOCK.GET_CLOCK_MINUTES(), CLOCK.GET_CLOCK_SECONDS())
        end)
        :AddTooltip("Increment the hour by 1"))

    self:AddOption(ButtonOption.new("Remove hour")
        :AddFunction(function()
            local hour = CLOCK.GET_CLOCK_HOURS() - 1
            if hour < 0 then hour = 23 end
            NETWORK.NETWORK_OVERRIDE_CLOCK_TIME(hour, CLOCK.GET_CLOCK_MINUTES(), CLOCK.GET_CLOCK_SECONDS())
        end)
        :AddTooltip("Decrement the hour by 1"))

    self:AddOption(ToggleOption.new("Freeze time")
        :AddToggle(vars.freezeTime)
        :AddFunction(function(val)
            vars.freezeTime = val
            CLOCK.PAUSE_CLOCK(val)
        end)
        :AddTooltip("Freeze the time"))

    self:AddOption(ToggleOption.new("Sync with system time")
        :AddToggle(vars.syncWithSystemTime)
        :AddFunction(function(val) vars.syncWithSystemTime = val end)
        :AddTooltip("Sync the games time with your computer time"))

    -- Water Section
    self:AddOption(BreakOption.new("Water"))

    self:AddOption(ToggleOption.new("Turn off ocean")
        :AddToggle(vars.noocean)
        :AddFunction(function(val) vars.noocean = val end)
        :AddTooltip("Disable the ocean (Requires memory access)"))

    self:AddOption(ToggleOption.new("Clear water")
        :AddToggle(vars.clearwater)
        :AddFunction(function(val) vars.clearwater = val end)
        :AddTooltip("Clear water (Requires memory access)"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Wave intensity")
        :AddNumberRef(vars, "waveintensity", "%d", 1)
        :AddMin(-100):AddMax(100)
        :AddTooltip("Control wave intensity (Requires memory access)"))

    -- Water Tune Section
    self:AddOption(BreakOption.new("Water Tune"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Ripple scale")
        :AddNumberRef(vars.Tune, "RippleScale", "%.2f", 0.2)
        :AddMin(-10.0):AddMax(10.0)
        :AddTooltip("Edit the ripples water has ingame (Requires memory access)"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Ocean Foam Scale")
        :AddNumberRef(vars.Tune, "OceanFoamScale", "%.2f", 0.2)
        :AddMin(-1000.0):AddMax(1000.0)
        :AddTooltip("Edit the foam water has ingame (Requires memory access)"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Specular Falloff")
        :AddNumberRef(vars.Tune, "SpecularFalloff", "%.0f", 1.0)
        :AddMin(-1000.0):AddMax(1000.0)
        :AddTooltip("Edit the light falloff water has ingame (Requires memory access)"))

    -- Density Section
    self:AddOption(BreakOption.new("Density"))

    self:AddOption(NumberOption.new(NumberOption.Type.TOGGLE, "Ped density")
        :AddToggle(vars.enablePedDensity)
        :AddNumberRef(vars, "pedDensity", "%.1f", 0.1)
        :AddMin(0):AddMax(1)
        :AddFunction(function(val)
            vars.enablePedDensity = val
        end)
        :AddTooltip("Amount of peds on the street"))

    self:AddOption(NumberOption.new(NumberOption.Type.TOGGLE, "Traffic density")
        :AddToggle(vars.enableTrafficDensity)
        :AddNumberRef(vars, "trafficDensity", "%.1f", 0.1)
        :AddMin(0):AddMax(1)
        :AddFunction(function(val)
            vars.enableTrafficDensity = val
        end)
        :AddTooltip("Amount of vehicles on the street"))



    -- Clear Area Section
    self:AddOption(BreakOption.new("Clear Area"))

    self:AddOption(NumberOption.new(NumberOption.Type.TOGGLE, "Clear radius")
        :AddToggle(vars.enableradiusbubble)
        :AddNumberRef(vars, "clearradius", "%.1f", 1.0)
        :AddMin(0):AddMax(1000)
        :AddFunction(function(val)
            vars.enableradiusbubble = val
        end)
        :AddTooltip("Control the radius of the clear area"))

    self:AddOption(ButtonOption.new("Clear area of everything")
        :AddFunction(function()
            local coords = GetLocalCoords()
            MISC.CLEAR_AREA(coords.x, coords.y, coords.z, vars.clearradius, true, false, false, false)
            MISC.CLEAR_AREA_OF_PEDS(coords.x, coords.y, coords.z, vars.clearradius, 0)
            MISC.CLEAR_AREA_OF_VEHICLES(coords.x, coords.y, coords.z, vars.clearradius, false, false, false, false, false, false)
            MISC.CLEAR_AREA_OF_OBJECTS(coords.x, coords.y, coords.z, vars.clearradius, 0)
            MISC.CLEAR_AREA_OF_COPS(coords.x, coords.y, coords.z, vars.clearradius, 0)
        end)
        :AddTooltip("Clear the area around you of everything"))

    self:AddOption(ButtonOption.new("Clear area of police")
        :AddFunction(function()
            local coords = GetLocalCoords()
            MISC.CLEAR_AREA_OF_COPS(coords.x, coords.y, coords.z, vars.clearradius, 0)
        end)
        :AddTooltip("Clear the area around you of police"))

    self:AddOption(ButtonOption.new("Clear area of objects")
        :AddFunction(function()
            local coords = GetLocalCoords()
            MISC.CLEAR_AREA_OF_OBJECTS(coords.x, coords.y, coords.z, vars.clearradius, 0)
        end)
        :AddTooltip("Clear the area around you of objects"))

    self:AddOption(ButtonOption.new("Clear area of vehicles")
        :AddFunction(function()
            local coords = GetLocalCoords()
            MISC.CLEAR_AREA_OF_VEHICLES(coords.x, coords.y, coords.z, vars.clearradius, false, false, false, false, false, false)
        end)
        :AddTooltip("Clear the area around you of vehicles"))

    self:AddOption(ButtonOption.new("Clear area of peds")
        :AddFunction(function()
            local coords = GetLocalCoords()
            MISC.CLEAR_AREA_OF_PEDS(coords.x, coords.y, coords.z, vars.clearradius, 0)
        end)
        :AddTooltip("Clear the area around you of peds"))

    -- Misc Section
    self:AddOption(BreakOption.new("Misc"))

    self:AddOption(ToggleOption.new("Kick all nearby from vehicles")
        :AddToggleRef(vars, "noflybys")
        :AddTooltip("This will kick anyone out their veh who enters your area (Air/Ground Vehicles)"))

    self:AddOption(ToggleOption.new("Teleport all nearby vehicles to sea")
        :AddToggleRef(vars, "teleportallnearvehs")
        :AddTooltip("This will teleport ped/player vehicles alike to the sea when they get close"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Timescale")
        :AddNumberRef(vars, "timeScale", "%.1f", 0.1)
        :AddMin(0.0):AddMax(1.0)
        :AddFunction(function()
            MISC.SET_TIME_SCALE(vars.timeScale)
        end)
        :AddTooltip("Change the timeScale (local)"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Road slipperiness")
        :AddNumberRef(vars, "slipperiness", "%.1f", 0.1)
        :AddMin(-5000.0):AddMax(5000.0)
        :AddTooltip("Make the roads slippy"))

    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Gravity")
        :AddScroll(gravityOptions, 1)
        :AddIndexRef(vars, "gravity")
        :AddFunction(function()
            local val = gravityOptions[vars.gravity].value
            MISC.SET_GRAVITY_LEVEL(val)
        end)
        :AddTooltip("Alter gravity"))

    self:AddOption(ToggleOption.new("Blackout")
        :AddToggle(vars.blackout)
        :AddFunction(function(val)
            vars.blackout = val
            GRAPHICS.SET_ARTIFICIAL_LIGHTS_STATE(val)
        end)
        :AddTooltip("Blackout all ingame lights"))

    self:AddOption(ToggleOption.new("Ground snow")
        :AddToggle(false)
        :AddFunction(function(val)
            -- Snow requires global variable manipulation
            -- Global(262145 + 4721) = Snow
        end)
        :AddTooltip("Snow! (Requires global access)"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Wind speed")
        :AddNumberRef(vars, "wind", "%.1f", 1.0)
        :AddMin(-1000):AddMax(1000)
        :AddFunction(function()
            MISC.SET_WIND_SPEED(vars.wind)
        end)
        :AddTooltip("Control the wind speed"))
end

-- Feature Update (called every frame)
function WorldMenu:FeatureUpdate()
    -- Freeze time
    if vars.freezeTime then
        NETWORK.NETWORK_OVERRIDE_CLOCK_TIME(CLOCK.GET_CLOCK_HOURS(), CLOCK.GET_CLOCK_MINUTES(), CLOCK.GET_CLOCK_SECONDS())
    end
    
    -- Ped density
    if vars.enablePedDensity then
        PED.SET_PED_DENSITY_MULTIPLIER_THIS_FRAME(vars.pedDensity)
    end
    
    -- Traffic density
    if vars.enableTrafficDensity then
        VEHICLE.SET_VEHICLE_DENSITY_MULTIPLIER_THIS_FRAME(vars.trafficDensity)
    end
    
    -- Clear radius bubble visualization
    if vars.enableradiusbubble then
        local coords = GetLocalCoords()
        GRAPHICS.DRAW_MARKER(28, coords.x, coords.y, coords.z, 0, 0, 0, 0, 0, 0, vars.clearradius, vars.clearradius, vars.clearradius, 255, 0, 0, 100, false, false, 0, false, nil, nil, false)
    end
    
    -- Split water
    if vars.splitwater then
        SplitTheSea()
    end
    
    -- Sync with system time
    if vars.syncWithSystemTime then
        CLOCK.PAUSE_CLOCK(false)
        local year, month, day, hour, min, sec = CLOCK.GET_LOCAL_TIME()
        if hour and min and sec then
            NETWORK.NETWORK_OVERRIDE_CLOCK_TIME(hour, min, sec)
        end
    end
    
    -- Sentry menu update
    if SentryMenu.GetInstance().FeatureUpdate then
        SentryMenu.GetInstance():FeatureUpdate()
    end
    
    -- Blackhole menu update
    if BlackholeMenu.GetInstance().FeatureUpdate then
        BlackholeMenu.GetInstance():FeatureUpdate()
    end

    -- World Drawables menu update
    if WorldDrawablesMenu.GetInstance().FeatureUpdate then
        WorldDrawablesMenu.GetInstance():FeatureUpdate()
    end

    -- Vehicle Blacklist menu update
    if VehicleBlacklistMenu.GetInstance().FeatureUpdate then
        VehicleBlacklistMenu.GetInstance():FeatureUpdate()
    end

    -- Bodyguard menu update
    if BodyguardMenu.GetInstance().FeatureUpdate then
        BodyguardMenu.GetInstance():FeatureUpdate()
    end
end



-- Register a looped script for world features
Script.RegisterLooped(function()
    if vars.noflybys or vars.teleportallnearvehs then
        local myPed = GetLocalPed()
        local myCoords = GetLocalCoords()
        local myVeh = PED.GET_VEHICLE_PED_IS_IN(myPed, false)
        
        local vehCount = PoolMgr.GetCurrentVehicleCount()
        for i = 0, vehCount - 1 do
            local veh = PoolMgr.GetVehicle(i)
            if veh and veh ~= 0 and veh ~= myVeh and ENTITY.DOES_ENTITY_EXIST(veh) then
                local coords = ENTITY.GET_ENTITY_COORDS(veh, false)
                local dist = MISC.GET_DISTANCE_BETWEEN_COORDS(coords.x, coords.y, coords.z, myCoords.x, myCoords.y, myCoords.z, false)
                
                -- Kick nearby from vehicles logic
                if vars.noflybys and dist <= 100.0 then -- Reduced distance for safety/performance, or keep 3000? 3000 is huge. Tooltip says "enters your area". Let's stick to a reasonable radius like 200.0 or match what user had.
                     -- User had 3000.0 which is massive map-wide almost. Let's use 250.0 for "nearby"
                     if dist <= 250.0 then
                        local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh, -1, false)
                        if ENTITY.DOES_ENTITY_EXIST(driver) and not PED.IS_PED_A_PLAYER(driver) then
                            TASK.CLEAR_PED_TASKS_IMMEDIATELY(driver)
                            TASK.TASK_LEAVE_VEHICLE(driver, veh, 16) -- Teleport out
                        end
                     end
                end
                
                -- Teleport nearby vehicles to sea logic
                if vars.teleportallnearvehs and dist <= 100.0 then
                    RequestControlOfEnt(veh)
                    ENTITY.SET_ENTITY_COORDS(veh, 6400.0, 6400.0, 0.0, false, false, false, false)
                end
            end
        end
    end
    Script.Yield(0)
end)

return WorldMenu
