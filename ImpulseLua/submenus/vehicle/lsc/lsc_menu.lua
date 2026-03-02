--[[
    Impulse Lua - LSC (Los Santos Customs) Menu
    Port of LSCMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

-- Import submenus
local LightsMenu = require("Impulse/ImpulseLua/submenus/vehicle/lsc/lights_menu")
local PlatesMenu = require("Impulse/ImpulseLua/submenus/vehicle/lsc/plates_menu")
local PerformanceMenu = require("Impulse/ImpulseLua/submenus/vehicle/lsc/performance_menu")
local ResprayMenu = require("Impulse/ImpulseLua/submenus/vehicle/lsc/respray_menu")
local WheelsMenu = require("Impulse/ImpulseLua/submenus/vehicle/lsc/wheels_menu")

local LSCMenu = setmetatable({}, { __index = Submenu })
LSCMenu.__index = LSCMenu

local instance = nil

-- Horns list
local horns = {
    { name = "Stock", value = -1 },
    { name = "Truck", value = 0 },
    { name = "Police", value = 1 },
    { name = "Clown", value = 2 },
    { name = "Musical 1", value = 3 },
    { name = "Musical 2", value = 4 },
    { name = "Musical 3", value = 5 },
    { name = "Musical 4", value = 6 },
    { name = "Musical 5", value = 7 },
    { name = "Sad Trombone", value = 8 },
    { name = "Classical 1", value = 9 },
    { name = "Classical 2", value = 10 },
    { name = "Classical 3", value = 11 },
    { name = "Classical 4", value = 12 },
    { name = "Classical 5", value = 13 },
    { name = "Classical 6", value = 14 },
    { name = "Classical 7", value = 15 },
    { name = "Do", value = 16 },
    { name = "Re", value = 17 },
    { name = "Mi", value = 18 },
    { name = "Fa", value = 19 },
    { name = "Sol", value = 20 },
    { name = "La", value = 21 },
    { name = "Ti", value = 22 },
    { name = "Do High", value = 23 },
    { name = "Jazz 1", value = 24 },
    { name = "Jazz 2", value = 25 },
    { name = "Jazz 3", value = 26 },
    { name = "Jazz Loop", value = 27 },
    { name = "Star-Spangled 1", value = 28 },
    { name = "Star-Spangled 2", value = 29 },
    { name = "Star-Spangled 3", value = 30 },
    { name = "Star-Spangled 4", value = 31 },
    { name = "Classical Loop 1", value = 32 },
    { name = "Classical Loop 2", value = 34 },
    { name = "Halloween Loop 1", value = 38 },
    { name = "Halloween Loop 2", value = 40 },
    { name = "San Andreas Loop", value = 43 },
    { name = "Liberty City Loop", value = 45 },
    { name = "Christmas Loop 1", value = 46 },
    { name = "Christmas Loop 2", value = 48 },
    { name = "Christmas Loop 3", value = 50 }
}

-- Window tints
local windowTints = {
    { name = "None", value = 0 },
    { name = "Pure Black", value = 1 },
    { name = "Dark Smoke", value = 2 },
    { name = "Light Smoke", value = 3 },
    { name = "Stock", value = 4 },
    { name = "Limo", value = 5 },
    { name = "Green", value = 6 }
}

-- Mod type constants
local MOD_SPOILER = 0
local MOD_FRONTBUMPER = 1
local MOD_REARBUMPER = 2
local MOD_SIDESKIRT = 3
local MOD_EXHAUST = 4
local MOD_CHASSIS = 5
local MOD_GRILLE = 6
local MOD_HOOD = 7
local MOD_FENDER = 8
local MOD_RIGHTFENDER = 9
local MOD_ROOF = 10
local MOD_HORNS = 14
local MOD_PLATEHOLDER = 25
local MOD_VANITY_PLATES = 26
local MOD_TRIM1 = 27
local MOD_ORNAMENTS = 28
local MOD_DASHBOARD = 29
local MOD_DIAL = 30
local MOD_DOOR_SPEAKER = 31
local MOD_SEATS = 32
local MOD_STEERINGWHEEL = 33
local MOD_SHIFTER_LEAVERS = 34
local MOD_PLAQUES = 35
local MOD_SPEAKERS = 36
local MOD_TRUNK = 37
local MOD_HYDRULICS = 38
local MOD_ENGINE_BLOCK = 39
local MOD_AIR_FILTER = 40
local MOD_STRUTS = 41
local MOD_ARCH_COVER = 42
local MOD_AERIALS = 43
local MOD_TRIM = 44
local MOD_TANK = 45
local MOD_WINDOWS = 46
local MOD_LIVERY = 48

local vars = {
    loopFullyTune = false,
    loopRandomize = false,
    windowTintIndex = 1,
    hornIndex = 1
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

-- Max vehicle
local function MaxVehicle(veh)
    VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
    VEHICLE.SET_VEHICLE_FIXED(veh)
    VEHICLE.SET_VEHICLE_DIRT_LEVEL(veh, 0)
    VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(veh, 0, 0, 0)
    VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(veh, 0, 0, 0)
    VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(veh, 5)
    VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(veh, false)
    VEHICLE.TOGGLE_VEHICLE_MOD(veh, 18, true) -- Turbo
    VEHICLE.TOGGLE_VEHICLE_MOD(veh, 22, true) -- Xenon
    
    -- Upgrade all mod slots
    for i = 0, 50 do
        local numMods = VEHICLE.GET_NUM_VEHICLE_MODS(veh, i)
        if numMods > 0 then
            VEHICLE.SET_VEHICLE_MOD(veh, i, numMods - 1, false)
        end
    end
    
    -- Toggle extras
    for i = 17, 22 do
        VEHICLE.TOGGLE_VEHICLE_MOD(veh, i, true)
    end
    
    -- Random color
    local r = MISC.GET_RANDOM_INT_IN_RANGE(0, 255)
    local g = MISC.GET_RANDOM_INT_IN_RANGE(0, 255)
    local b = MISC.GET_RANDOM_INT_IN_RANGE(0, 255)
    
    VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(veh, r, g, b)
    VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(veh, r, g, b)
    
    -- Enable all neons
    for i = 0, 3 do
        VEHICLE.SET_VEHICLE_NEON_ENABLED(veh, i, true)
    end
    VEHICLE.SET_VEHICLE_NEON_COLOUR(veh, 255, 0, 0)
    
    VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(veh, r, g, b)
    VEHICLE.SET_VEHICLE_WHEEL_TYPE(veh, 7)
    VEHICLE.SET_VEHICLE_WINDOW_TINT(veh, 5)
end

-- Downgrade vehicle
local function DowngradeVehicle(veh)
    VEHICLE.SET_VEHICLE_FIXED(veh)
    VEHICLE.SET_VEHICLE_DIRT_LEVEL(veh, 15.0)
    VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(veh, true)
    VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
    
    -- Remove mods
    for i = 0, 16 do
        VEHICLE.REMOVE_VEHICLE_MOD(veh, i)
    end
    
    VEHICLE.REMOVE_VEHICLE_MOD(veh, 14)
    VEHICLE.REMOVE_VEHICLE_MOD(veh, 23)
    
    -- Disable extras
    for i = 17, 22 do
        VEHICLE.TOGGLE_VEHICLE_MOD(veh, i, false)
    end
    
    VEHICLE.CLEAR_VEHICLE_CUSTOM_PRIMARY_COLOUR(veh)
    VEHICLE.CLEAR_VEHICLE_CUSTOM_SECONDARY_COLOUR(veh)
    VEHICLE.SET_VEHICLE_COLOURS(veh, 135, 135)
    VEHICLE.SET_VEHICLE_EXTRA_COLOURS(veh, 135, 135)
    VEHICLE.SET_VEHICLE_WINDOW_TINT(veh, 0)
    VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(veh, 1)
end

-- Random license plate
local function RandomLicense()
    local charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    local result = ""
    for i = 1, 8 do
        local idx = MISC.GET_RANDOM_INT_IN_RANGE(1, #charset)
        result = result .. charset:sub(idx, idx)
    end
    return result
end

-- Randomize vehicle
local function RandomizeVehicle(veh)
    VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
    
    for i = 0, 50 do
        local numMods = VEHICLE.GET_NUM_VEHICLE_MODS(veh, i)
        if numMods > 0 then
            local randMod = MISC.GET_RANDOM_INT_IN_RANGE(-1, numMods)
            VEHICLE.SET_VEHICLE_MOD(veh, i, randMod, false)
        end
    end
    
    local randPrimary = MISC.GET_RANDOM_INT_IN_RANGE(0, 160)
    local randSecondary = MISC.GET_RANDOM_INT_IN_RANGE(0, 160)
    VEHICLE.SET_VEHICLE_COLOURS(veh, randPrimary, randSecondary)
    VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(veh, RandomLicense())
    VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(veh, MISC.GET_RANDOM_INT_IN_RANGE(0, 5))
    VEHICLE.SET_VEHICLE_ENVEFF_SCALE(veh, MISC.GET_RANDOM_FLOAT_IN_RANGE(0.0, 1.0))
end

-- Create a vehicle mod option
local function CreateModOption(menu, name, modType)
    local opt = NumberOption.new(NumberOption.Type.SCROLL, name)
    
    opt:AddNumber(0, "%d", 1)
        :AddMin(-1):AddMax(50)
        :AddRequirement(function()
            if not IsInVehicle() then return false end
            local numMods = VEHICLE.GET_NUM_VEHICLE_MODS(GetCurrentVehicle(), modType)
            return numMods > 0
        end)
        :AddOnUpdate(function(o)
            if IsInVehicle() then
                local numMods = VEHICLE.GET_NUM_VEHICLE_MODS(GetCurrentVehicle(), modType)
                o:AddMax(numMods - 1)
                o.value = VEHICLE.GET_VEHICLE_MOD(GetCurrentVehicle(), modType)
            end
        end)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_MOD(GetCurrentVehicle(), modType, opt.value, false)
            end
        end)
        :AddTooltip("Edit " .. name:lower())
        :SetDonor()
        
    menu:AddOption(opt)
end

function LSCMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Los Santos Customs"), LSCMenu)
        instance:Init()
    end
    return instance
end

function LSCMenu:Init()
    -- Not in vehicle indicator
    self:AddOption(ButtonOption.new("~c~Not in a vehicle")
        :AddRequirement(function() return not IsInVehicle() end)
        :AddTooltip("Enter a vehicle to access LSC")
        :SetDonor())
    
    -- Fully tune
    self:AddOption(ButtonOption.new("Fully tune")
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            if IsInVehicle() then
                MaxVehicle(GetCurrentVehicle())
            end
        end)
        :AddTooltip("Max all vehicle upgrades")
        :SetDonor())
    
    -- Loop fully tune
    self:AddOption(ToggleOption.new("Loop fully tune")
        :AddToggleRef(vars, "loopFullyTune")
        :AddTooltip("Continuously max vehicle")
        :SetDonor())
    
    -- Downgrade
    self:AddOption(ButtonOption.new("Downgrade")
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            if IsInVehicle() then
                DowngradeVehicle(GetCurrentVehicle())
            end
        end)
        :AddTooltip("Remove all upgrades")
        :SetDonor())
    
    -- Randomize
    self:AddOption(ButtonOption.new("Randomize vehicle look")
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            if IsInVehicle() then
                RandomizeVehicle(GetCurrentVehicle())
            end
        end)
        :AddTooltip("Randomize all vehicle mods")
        :SetDonor())
    
    -- Loop randomize
    self:AddOption(ToggleOption.new("Loop randomize")
        :AddToggleRef(vars, "loopRandomize")
        :AddTooltip("Continuously randomize vehicle")
        :SetDonor())
    
    -- Apply all extras
    self:AddOption(ButtonOption.new("Apply all extras")
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            if IsInVehicle() then
                local veh = GetCurrentVehicle()
                VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
                for i = 0, 12 do
                    if VEHICLE.DOES_EXTRA_EXIST(veh, i) then
                        VEHICLE.SET_VEHICLE_EXTRA(veh, i, false) -- false = enabled
                    end
                end
            end
        end)
        :AddTooltip("Enable all vehicle extras")
        :SetDonor())
    
    -- Remove all extras
    self:AddOption(ButtonOption.new("Remove all extras")
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            if IsInVehicle() then
                local veh = GetCurrentVehicle()
                VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
                for i = 0, 12 do
                    if VEHICLE.DOES_EXTRA_EXIST(veh, i) then
                        VEHICLE.SET_VEHICLE_EXTRA(veh, i, true) -- true = disabled
                    end
                end
            end
        end)
        :AddTooltip("Disable all vehicle extras")
        :SetDonor())
    
    self:AddOption(BreakOption.new())
    
    -- Submenus
    -- Submenus
    self:AddOption(SubmenuOption.new("Lights")
        :AddSubmenu(LightsMenu.GetInstance())
        :AddRequirement(IsInVehicle)
        :AddTooltip("Edit vehicle lights")
        :SetDonor())
    
    self:AddOption(SubmenuOption.new("Plates")
        :AddSubmenu(PlatesMenu.GetInstance())
        :AddRequirement(IsInVehicle)
        :AddTooltip("Edit vehicle plates")
        :SetDonor())
    
    self:AddOption(SubmenuOption.new("Respray")
        :AddSubmenu(ResprayMenu.GetInstance())
        :AddRequirement(IsInVehicle)
        :AddTooltip("Respray vehicle colors")
        :SetDonor())
    
    self:AddOption(SubmenuOption.new("Wheels")
        :AddSubmenu(WheelsMenu.GetInstance())
        :AddRequirement(IsInVehicle)
        :AddTooltip("Edit vehicle wheels")
        :SetDonor())
    
    self:AddOption(SubmenuOption.new("Performance")
        :AddSubmenu(PerformanceMenu.GetInstance())
        :AddRequirement(IsInVehicle)
        :AddTooltip("Edit vehicle performance")
        :SetDonor())
    
    -- Window tint
    local tintNames = {}
    for i, t in ipairs(windowTints) do
        tintNames[i] = t.name
    end
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Window tint")
        :AddScroll(tintNames, 1)
        :AddIndexRef(vars, "windowTintIndex")
        :CanLoop()
        :AddRequirement(IsInVehicle)
        :AddOnUpdate(function(opt)
            if IsInVehicle() then
                local currentTint = VEHICLE.GET_VEHICLE_WINDOW_TINT(GetCurrentVehicle())
                for i, t in ipairs(windowTints) do
                    if t.value == currentTint then
                        vars.windowTintIndex = i
                        break
                    end
                end
            end
        end)
        :AddFunction(function()
            if IsInVehicle() then
                local tintValue = windowTints[vars.windowTintIndex].value
                VEHICLE.SET_VEHICLE_WINDOW_TINT(GetCurrentVehicle(), tintValue)
            end
        end)
        :AddTooltip("Set window tint")
        :SetDonor())
    
    -- Horn
    local hornNames = {}
    for i, h in ipairs(horns) do
        hornNames[i] = h.name
    end
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Horn")
        :AddScroll(hornNames, 1)
        :AddIndexRef(vars, "hornIndex")
        :CanLoop()
        :AddRequirement(IsInVehicle)
        :AddOnUpdate(function(opt)
            if IsInVehicle() then
                local currentHorn = VEHICLE.GET_VEHICLE_MOD(GetCurrentVehicle(), MOD_HORNS)
                for i, h in ipairs(horns) do
                    if h.value == currentHorn then
                        vars.hornIndex = i
                        break
                    end
                end
            end
        end)
        :AddFunction(function()
            if IsInVehicle() then
                local hornValue = horns[vars.hornIndex].value
                VEHICLE.SET_VEHICLE_MOD(GetCurrentVehicle(), MOD_HORNS, hornValue, false)
            end
        end)
        :AddTooltip("Set vehicle horn")
        :SetDonor())
    
    self:AddOption(BreakOption.new("Body Mods"))
    
    -- Body mods
    CreateModOption(self, "Spoiler", MOD_SPOILER)
    CreateModOption(self, "Front Bumper", MOD_FRONTBUMPER)
    CreateModOption(self, "Rear Bumper", MOD_REARBUMPER)
    CreateModOption(self, "Side Skirts", MOD_SIDESKIRT)
    CreateModOption(self, "Exhaust", MOD_EXHAUST)
    CreateModOption(self, "Roll Cage", MOD_CHASSIS)
    CreateModOption(self, "Grille", MOD_GRILLE)
    CreateModOption(self, "Hood", MOD_HOOD)
    CreateModOption(self, "Fender", MOD_FENDER)
    CreateModOption(self, "Right Fender", MOD_RIGHTFENDER)
    CreateModOption(self, "Roof", MOD_ROOF)
    
    self:AddOption(BreakOption.new("Benny's Mods"))
    
    CreateModOption(self, "Plate Holder", MOD_PLATEHOLDER)
    CreateModOption(self, "Vanity Plates", MOD_VANITY_PLATES)
    CreateModOption(self, "Trim", MOD_TRIM1)
    CreateModOption(self, "Ornaments", MOD_ORNAMENTS)
    CreateModOption(self, "Dashboard", MOD_DASHBOARD)
    CreateModOption(self, "Dial", MOD_DIAL)
    CreateModOption(self, "Door Speaker", MOD_DOOR_SPEAKER)
    CreateModOption(self, "Seats", MOD_SEATS)
    CreateModOption(self, "Steering Wheel", MOD_STEERINGWHEEL)
    CreateModOption(self, "Shifter", MOD_SHIFTER_LEAVERS)
    CreateModOption(self, "Plaques", MOD_PLAQUES)
    CreateModOption(self, "Speakers", MOD_SPEAKERS)
    CreateModOption(self, "Trunk", MOD_TRUNK)
    CreateModOption(self, "Hydraulics", MOD_HYDRULICS)
    CreateModOption(self, "Engine Block", MOD_ENGINE_BLOCK)
    CreateModOption(self, "Air Filter", MOD_AIR_FILTER)
    CreateModOption(self, "Struts", MOD_STRUTS)
    CreateModOption(self, "Arch Cover", MOD_ARCH_COVER)
    CreateModOption(self, "Aerials", MOD_AERIALS)
    CreateModOption(self, "Trim 2", MOD_TRIM)
    CreateModOption(self, "Tank", MOD_TANK)
    CreateModOption(self, "Windows", MOD_WINDOWS)
    CreateModOption(self, "Livery", MOD_LIVERY)
end

-- Timer for loop functions
local loopTimer = 0

function LSCMenu:FeatureUpdate()
    -- Update submenus
    LightsMenu.GetInstance():FeatureUpdate()
    PlatesMenu.GetInstance():FeatureUpdate()
    WheelsMenu.GetInstance():FeatureUpdate()
    
    if not IsInVehicle() then return end
    
    local now = MISC.GET_GAME_TIMER()
    if now - loopTimer > 500 then
        loopTimer = now
        
        if vars.loopFullyTune then
            MaxVehicle(GetCurrentVehicle())
        end
        
        if vars.loopRandomize then
            RandomizeVehicle(GetCurrentVehicle())
        end
    end
end

return LSCMenu
