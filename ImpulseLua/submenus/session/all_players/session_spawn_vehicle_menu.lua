--[[
    Impulse Lua - Session Spawn Vehicle Menu
    Spawn vehicles for all players
    Port of sessionSpawnVehicleMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local TextInputComponent = require("Impulse/ImpulseLua/lib/ui/text_input_component")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local Vehicles = require("Impulse/ImpulseLua/lib/data/vehicles")
local AllPlayersMenu = require("Impulse/ImpulseLua/submenus/session/all_players_menu")

local SessionSpawnVehicleMenu = setmetatable({}, { __index = Submenu })
SessionSpawnVehicleMenu.__index = SessionSpawnVehicleMenu

local instance = nil

-- Helper to get hash
local function GetHash(modelName)
    if Utils and Utils.Joaat then
        return Utils.Joaat(modelName)
    else
        return MISC.GET_HASH_KEY(modelName)
    end
end

-- Spawn Logic
local function SpawnVehicleForSession(modelName)
    local hash = GetHash(modelName)
    
    if not STREAMING.IS_MODEL_IN_CDIMAGE(hash) or not STREAMING.IS_MODEL_A_VEHICLE(hash) then
        Renderer.Notify("Invalid vehicle model: " .. tostring(modelName))
        return
    end

    STREAMING.REQUEST_MODEL(hash)
    local timeout = 0
    while not STREAMING.HAS_MODEL_LOADED(hash) and timeout < 100 do
        timeout = timeout + 1
        Script.Yield(10)
    end
    
    if not STREAMING.HAS_MODEL_LOADED(hash) then
        Renderer.Notify("Failed to load model: " .. tostring(modelName))
        return
    end

    local count = 0
    for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        if ped and ped ~= 0 and ENTITY.DOES_ENTITY_EXIST(ped) then
            local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
            local heading = ENTITY.GET_ENTITY_HEADING(ped)
            
            -- Spawn nearby
            local veh = VEHICLE.CREATE_VEHICLE(hash, coords.x, coords.y, coords.z, heading, true, true, false)
            if veh and veh ~= 0 then
                VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(veh, 5.0)
                DECORATOR.DECOR_SET_INT(veh, "MPBitset", 0)
                VEHICLE.SET_VEHICLE_IS_STOLEN(veh, false)
                count = count + 1
            end
        end
    end
    
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
    Renderer.Notify("Spawned " .. modelName .. " for " .. count .. " players")
end

function SessionSpawnVehicleMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Spawn Vehicle"), SessionSpawnVehicleMenu)
        instance:Init()
    end
    return instance
end

function SessionSpawnVehicleMenu:Init()
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
                local hash = GetHash(vehicleModel)
                local displayName = GTA.GetDisplayNameFromHash(hash)
                if not displayName or displayName == "" or displayName == "NULL" then
                    displayName = vehicleModel
                end
                
                catSubmenu:AddOption(ButtonOption.new(displayName)
                    :AddFunction(function()
                        SpawnVehicleForSession(vehicleModel)
                    end)
                    :AddTooltip("Spawn " .. vehicleModel .. " for session"))
            end
            dlcSubmenu:AddOption(SubmenuOption.new(category.name)
                :AddSubmenu(catSubmenu)
                :AddTooltip("Spawn " .. category.name .. " vehicles for session"))
        end
    end

    self:AddOption(SubmenuOption.new("DLC vehicles only")
        :AddSubmenu(dlcSubmenu)
        :AddTooltip("Pick only vehicles from DLC"))

    -- Custom input
    self:AddOption(ButtonOption.new("Input vehicle name")
        :AddFunction(function()
             local vehicleInput = TextInputComponent.new("Vehicle Name", function(text)
                if text and #text > 0 then
                    SpawnVehicleForSession(text)
                end
            end)
            vehicleInput:Show()
        end)
        :AddTooltip("Spawn a vehicle for session by entering its model name"))

    -- Vehicle Categories
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

    for _, category in ipairs(categories) do
        local catSubmenu = Submenu.new(category.name)
        for _, vehicleModel in ipairs(category.list) do
             local hash = GetHash(vehicleModel)
             local displayName = GTA.GetDisplayNameFromHash(hash)
             if not displayName or displayName == "" or displayName == "NULL" then
                 displayName = vehicleModel
             end

             catSubmenu:AddOption(ButtonOption.new(displayName)
                :AddFunction(function()
                    SpawnVehicleForSession(vehicleModel)
                end)
                :AddTooltip("Spawn " .. vehicleModel .. " for session"))
        end
        self:AddOption(SubmenuOption.new(category.name)
            :AddSubmenu(catSubmenu)
            :AddTooltip("Spawn " .. category.name .. " vehicles for session"))
    end
end

return SessionSpawnVehicleMenu
