--[[
    Impulse Lua - Spawn Vehicle Menu
    Port of spawnVehicleMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local TextInputComponent = require("Impulse/ImpulseLua/lib/ui/text_input_component")
local Vehicles = require("Impulse/ImpulseLua/lib/data/vehicles")
local SpawnVehicleSettingsMenu = require("Impulse/ImpulseLua/submenus/spawn/spawn_vehicle_settings_menu")
local LSCMenu = require("Impulse/ImpulseLua/submenus/vehicle/lsc/lsc_menu") -- Corrected path
local VehicleMenuVars = require("Impulse/ImpulseLua/submenus/vehicle_menu").vars -- Accessing Vehicle Godmode

local SpawnVehicleMenu = setmetatable({}, { __index = Submenu })
SpawnVehicleMenu.__index = SpawnVehicleMenu

local instance = nil
local vehicleInput = nil



-- Helper: Convert rotation to direction vector (for spawning in front)
local function RotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))
    return {
        x = -math.sin(z) * num,
        y = math.cos(z) * num,
        z = math.sin(x)
    }
end

-- Main Spawn Logic
local function SpawnVehicle(modelName)
    local vars = SpawnVehicleSettingsMenu.vars
    local hash = Utils.Joaat(modelName)

    if not STREAMING.IS_MODEL_IN_CDIMAGE(hash) or not STREAMING.IS_MODEL_A_VEHICLE(hash) then
        print("[SpawnVehicle] Invalid model: " .. tostring(modelName))
        return
    end

    STREAMING.REQUEST_MODEL(hash)
    local timeout = 0
    while not STREAMING.HAS_MODEL_LOADED(hash) and timeout < 100 do
        timeout = timeout + 1
        coroutine.yield()
    end

    if not STREAMING.HAS_MODEL_LOADED(hash) then
        print("[SpawnVehicle] Failed to load model: " .. tostring(modelName))
        return
    end

    local startCoords
    local heading
    local playerPed = PLAYER.PLAYER_PED_ID()
    local useSpawnerBlip = false
    local spawnerModeActive = false

    -- Check if spawner mode is active (lazy require to avoid circular dependency)
    local SpawnMenu = require("Impulse/ImpulseLua/submenus/spawn_menu")
    if SpawnMenu.IsSpawnerModeActive and SpawnMenu.IsSpawnerModeActive() then
        local coords = SpawnMenu.GetSpawnerCoords()
        if coords then
            startCoords = { x = coords.x, y = coords.y, z = coords.z }
            heading = 0.0
            useSpawnerBlip = SpawnMenu.ShouldAddBlip and SpawnMenu.ShouldAddBlip()
            spawnerModeActive = true
        end
    end

    -- Fallback to normal spawn location if not in spawner mode
    if not startCoords then
        if vars.spawnin then
            startCoords = ENTITY.GET_ENTITY_COORDS(playerPed, true)
            heading = ENTITY.GET_ENTITY_HEADING(playerPed)
        else
            local playerCoords = ENTITY.GET_ENTITY_COORDS(playerPed, true)
            local playerHeading = ENTITY.GET_ENTITY_HEADING(playerPed)
            
            -- Calculate position in front
            local forward = 5.0
            local xVect = forward * math.sin(-math.rad(playerHeading))
            local yVect = forward * math.cos(-math.rad(playerHeading))
            
            startCoords = {
                x = playerCoords.x + xVect,
                y = playerCoords.y + yVect,
                z = playerCoords.z
            }
            heading = playerHeading
        end
    end

    -- Delete old vehicle if needed (only if not in spawner mode)
    if not spawnerModeActive and vars.deleteold then
        if PED.IS_PED_IN_ANY_VEHICLE(playerPed, false) then
            local oldVeh = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)
            local controlTimeout = 0
            while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(oldVeh) and controlTimeout < 20 do
                NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(oldVeh)
                coroutine.yield()
                controlTimeout = controlTimeout + 1
            end
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(oldVeh, true, true)
            local ptr = Memory.AllocInt()
            Memory.WriteInt(ptr, oldVeh)
            ENTITY.DELETE_ENTITY(ptr)
        end
    end

    -- Spawn using GTA.SpawnVehicle as requested
    local veh = GTA.SpawnVehicle(hash, startCoords.x, startCoords.y, startCoords.z, heading, true, false)

    if veh and veh ~= 0 then
        -- Post-spawn setup
        ENTITY.SET_ENTITY_HEADING(veh, heading)
        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(veh, 5.0)
        
        -- Apply settings - use spawner blip or settings blip
        if useSpawnerBlip or vars.blip then
            local blip = HUD.ADD_BLIP_FOR_ENTITY(veh)
            HUD.SET_BLIP_SPRITE(blip, 326)
            HUD.SET_BLIP_COLOUR(blip, 2)
        end

        if vars.spawninvincible then
            ENTITY.SET_ENTITY_INVINCIBLE(veh, true)
        end

        if vars.spawnmaxed then
            VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
            for i = 0, 49 do
                 local numMods = VEHICLE.GET_NUM_VEHICLE_MODS(veh, i)
                 if numMods > 0 then
                     VEHICLE.SET_VEHICLE_MOD(veh, i, numMods - 1, false)
                 end
            end
            VEHICLE.TOGGLE_VEHICLE_MOD(veh, 18, true) -- Turbo
        end

        if not vars.spawndefault then
            VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(veh, vars.dprimary.r, vars.dprimary.g, vars.dprimary.b)
            VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(veh, vars.dsecondary.r, vars.dsecondary.g, vars.dsecondary.b)
        end
        
        -- Spawn Speed
        if vars.spawnspeed > 0 then
            VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, vars.spawnspeed)
        end
        
        DECORATOR.DECOR_SET_INT(veh, "MPBitset", 0)
        VEHICLE.SET_VEHICLE_IS_STOLEN(veh, false)
        VEHICLE.SET_VEHICLE_DIRT_LEVEL(veh, 0.0)
        AUDIO.SET_VEH_RADIO_STATION(veh, "OFF")

        if vars.particles then
            local coords = ENTITY.GET_ENTITY_COORDS(veh, true)
            local ptfxAsset = "proj_indep_firework_v2"
            STREAMING.REQUEST_NAMED_PTFX_ASSET(ptfxAsset)
            local ptfxTimeout = 0
            while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(ptfxAsset) and ptfxTimeout < 50 do
                ptfxTimeout = ptfxTimeout + 1
                coroutine.yield()
            end
            
            if STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(ptfxAsset) then
                GRAPHICS.USE_PARTICLE_FX_ASSET(ptfxAsset)
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
                    "scr_firework_indep_repeat_burst_rwb",
                    coords.x, coords.y, coords.z,
                    0.0, 0.0, 0.0,
                    2.2, false, false, false, false
                )
            end
        end

        -- Only put player in vehicle if not in spawner mode
        if not spawnerModeActive and vars.spawnin then
            PED.SET_PED_INTO_VEHICLE(playerPed, veh, -1)
        end
        
        -- Spawn in air check
        if vars.spawninair and (VEHICLE.IS_THIS_MODEL_A_PLANE(hash) or VEHICLE.IS_THIS_MODEL_A_HELI(hash)) then
            local coords = ENTITY.GET_ENTITY_COORDS(veh, true)
            ENTITY.SET_ENTITY_COORDS(veh, coords.x, coords.y, coords.z + vars.spawnheight + 100.0, false, false, false, false)
            VEHICLE.SET_VEHICLE_ENGINE_ON(veh, true, true, false)
            VEHICLE.SET_HELI_BLADES_FULL_SPEED(veh)
        end
        
        -- Track in spawner if active
        if spawnerModeActive then
            if SpawnMenu.TrackSpawnedEntity then
                SpawnMenu.TrackSpawnedEntity(veh)
            end
        end

    else
        print("[SpawnVehicle] GTA.SpawnVehicle returned 0/nil")
    end
    
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
end


function SpawnVehicleMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Spawn vehicle"), SpawnVehicleMenu)
        instance:Init()
    end
    return instance
end

function SpawnVehicleMenu:Init()
    -- Link to settings
    self:AddOption(SubmenuOption.new("Spawner settings")
        :AddSubmenu(SpawnVehicleSettingsMenu.GetInstance())
        :AddTooltip("Configure how vehicles are spawned"))

    -- Custom input
    self:AddOption(ButtonOption.new("Input vehicle name")
        :AddFunction(function()
            if not vehicleInput then
                vehicleInput = TextInputComponent.new("Vehicle Name", function(text)
                    if text and #text > 0 then
                        SpawnVehicle(text)
                    end
                end)
            end
            vehicleInput:Show()
        end)

        :AddTooltip("Spawn a vehicle by entering its model name"))

    self:AddOption(SubmenuOption.new("Manage spawned vehicles")
         -- Placeholder for SpawnEntityManagerMenu
        :AddTooltip("Manage the vehicles you've spawned (Coming Soon)"))

    -- DLC Vehicles only submenu
    local dlcSubmenu = Submenu.new("DLC vehicles only")
    
    local dlcCategories = {
        { name = "The Chop Shop", list = Vehicles.dlcchopshop },
        { name = "San Andreas Mercenaries", list = Vehicles.dlcsam },
        { name = "Los Santos Drug Wars", list = Vehicles.dlcdw },
        { name = "The Criminal Enterprises", list = Vehicles.dlcce },
        { name = "The Contract", list = Vehicles.dlccontract },
        { name = "Los Santos Tuners", list = Vehicles.dlcstuners },
        { name = "Cayo Perico Heist", list = Vehicles.dlccph },
        { name = "Los Santos Summer Special", list = Vehicles.dlcsss2 },
        { name = "Diamond Casino Heist", list = Vehicles.dlcdch },
        { name = "Casino", list = Vehicles.dlccasino },
        { name = "Arena War", list = Vehicles.dlcaw },
        { name = "After Hours", list = Vehicles.dlcaa },
        { name = "Super Sport Series", list = Vehicles.dlcsss },
        { name = "Doomsday Heist", list = Vehicles.dlcddh },
        { name = "Smuggler's Run", list = Vehicles.dlcsr },
        { name = "Gunrunning", list = Vehicles.dlcgr },
        { name = "Special Vehicle Circuit", list = Vehicles.dlcsvc },
        { name = "Import/Export", list = Vehicles.dlcie },
        { name = "Bikers", list = Vehicles.dlcbu },
        { name = "Cunning Stunts", list = Vehicles.dlccs },
        { name = "Finance and Felony", list = Vehicles.dlcfaf },
        { name = "Lowriders: Custom Classics", list = Vehicles.dlclrof },
        { name = "Be My Valentine", list = Vehicles.dlcbmv },
        { name = "January 2016", list = Vehicles.dlcj16 },
        { name = "Festive Surprise 2015", list = Vehicles.dlcfs15 },
        { name = "Executives and Other Criminals", list = Vehicles.dlceaoc },
        { name = "Halloween Surprise", list = Vehicles.dlchs },
        { name = "Lowriders", list = Vehicles.dlclcc },
        { name = "Freemode Events", list = Vehicles.dlcfme },
        { name = "Ill-Gotten Gains Part 2", list = Vehicles.dlciggp2 },
        { name = "Ill-Gotten Gains Part 1", list = Vehicles.dlciggp1 },
        { name = "Heists", list = Vehicles.dlch },
        { name = "Festive Surprise 2014", list = Vehicles.dlcfs14 },
        { name = "Last Team Standing", list = Vehicles.dlclts },
        { name = "Flight School", list = Vehicles.dlcfs },
        { name = "Independence Day", list = Vehicles.dlcids },
        { name = "I'm Not a Hipster", list = Vehicles.dlcnah },
        { name = "High Life", list = Vehicles.dlchl },
        { name = "Business", list = Vehicles.dlcb },
        { name = "Valentine's Day", list = Vehicles.dlcvdm },
        { name = "Beach Bum", list = Vehicles.dlcbb }
    }

    for _, category in ipairs(dlcCategories) do
        if category.list then
            local catSubmenu = Submenu.new(category.name)
            for _, vehicleModel in ipairs(category.list) do
                local hash = Utils.Joaat(vehicleModel)
                local displayName = GTA.GetDisplayNameFromHash(hash)
                if not displayName or displayName == "" or displayName == "NULL" then
                    displayName = vehicleModel
                end

                catSubmenu:AddOption(ButtonOption.new(displayName)
                    :AddFunction(function()
                        SpawnVehicle(vehicleModel)
                    end)
                    :AddTooltip("Spawn " .. vehicleModel))
            end
            dlcSubmenu:AddOption(SubmenuOption.new(category.name)
                :AddSubmenu(catSubmenu)
                :AddTooltip("Spawn " .. category.name .. " vehicles"))
        end
    end

    self:AddOption(SubmenuOption.new("DLC vehicles only")
        :AddSubmenu(dlcSubmenu)
        :AddTooltip("Pick only vehicles from DLC"))


    -- Vehicle Categories from C++ loop
    local categories = {
        { name = "Super", list = Vehicles.super },
        { name = "Sport", list = Vehicles.sports },
        { name = "Sports classic", list = Vehicles.sportsclassic },
        { name = "Off road", list = Vehicles.offroad },
        { name = "Sedan", list = Vehicles.sedans },
        { name = "SUV", list = Vehicles.suv },
        { name = "Coupe", list = Vehicles.coupes },
        { name = "Muscle", list = Vehicles.muscle },
        { name = "Compact", list = Vehicles.compacts },
        { name = "Van", list = Vehicles.van },
        { name = "Commercial", list = Vehicles.commercial },
        { name = "Industrial", list = Vehicles.industrial },
        { name = "Military", list = Vehicles.military },
        { name = "Service", list = Vehicles.service },
        { name = "Emergency", list = Vehicles.emergency },
        { name = "Motorcycle", list = Vehicles.motorcycles },
        { name = "Cycle", list = Vehicles.cycles },
        { name = "Planes", list = Vehicles.planes },
        { name = "Helicopters", list = Vehicles.helicopters },
        { name = "Boats", list = Vehicles.boats },
        { name = "Trains", list = Vehicles.trains },
        { name = "Trailer", list = Vehicles.trailer },
        { name = "Utility", list = Vehicles.utility }
    }

    local WindowManager = require("Impulse/ImpulseLua/lib/ui/window_manager")

    for _, category in ipairs(categories) do
        local catSubmenu = Submenu.new(category.name)
        
        -- Show window on enter, hide on exit (if possible, otherwise just relying on manual close or stack)
        -- Note: Standard Submenu doesn't expose OnEnter/Exit hooks easily for instances without subclassing
        -- We will inject them if the Submenu handlers call them
        
        catSubmenu.OnEnter = function(self)
            local wm = WindowManager.GetInstance()
            if wm.vehicleInfoWindow then
                wm:AddWindow(wm.vehicleInfoWindow)
            end
        end
        
        catSubmenu.OnExit = function(self)
            local wm = WindowManager.GetInstance()
            if wm.vehicleInfoWindow then
                wm:RemoveWindow(wm.vehicleInfoWindow)
            end
        end

        for _, vehicleModel in ipairs(category.list) do
             local hash = Utils.Joaat(vehicleModel)
             local displayName = GTA.GetDisplayNameFromHash(hash)
             if not displayName or displayName == "" or displayName == "NULL" then
                 displayName = vehicleModel
             end

             catSubmenu:AddOption(ButtonOption.new(displayName)
                :AddFunction(function()
                    SpawnVehicle(vehicleModel)
                end)
                :AddCurrentOp(function() 
                    -- Update info window model on highlight
                    local wm = WindowManager.GetInstance()
                    if wm.vehicleInfoWindow then
                        -- Access the component inside the window
                        -- Assumption: Component is first/only component or accessible
                        -- Window components list is typically private or we iterate
                        -- Based on window_manager.lua logic, components are in window.components
                        local win = wm.vehicleInfoWindow
                        if win.components and #win.components > 0 then
                            local comp = win.components[1]
                            if comp.SetModel then
                                comp:SetModel(vehicleModel)
                            end
                        end
                    else
                        Logger.LogError("[SpawnVehicleMenu] vehicleInfoWindow is nil in AddCurrentOp")
                    end
                end)
                :AddTooltip("Spawn " .. vehicleModel))
        end
        
        self:AddOption(SubmenuOption.new(category.name)
            :AddSubmenu(catSubmenu)
            :AddTooltip("Spawn " .. category.name .. " vehicles"))
    end
end

function SpawnVehicleMenu:FeatureUpdate()
    if vehicleInput and vehicleInput:IsVisible() then
        vehicleInput:Update()
    end
end

return SpawnVehicleMenu
