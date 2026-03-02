--[[
    Impulse Lua - IPL Teleport Menu
    Port of IPLTeleportMenu.cpp from Impulse C++
    Teleport to IPL locations with automatic IPL loading
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class IPLTeleportMenu : Submenu
local IPLTeleportMenu = setmetatable({}, { __index = Submenu })
IPLTeleportMenu.__index = IPLTeleportMenu

-- IPL sets for various locations
local CarrierIPLs = { "hei_carrier", "hei_carrier_DistantLights", "hei_Carrier_int1", "hei_Carrier_int2", "hei_Carrier_int3", "hei_Carrier_int4", "hei_Carrier_int5", "hei_Carrier_int6", "hei_carrier_LODLights" }

local YachtIPLs = { "hei_yacht_heist", "hei_yacht_heist_Bar", "hei_yacht_heist_Bedrm", "hei_yacht_heist_Bridge", "hei_yacht_heist_DistantLights", "hei_yacht_heist_enginrm", "hei_yacht_heist_LODLights", "hei_yacht_heist_Lounge" }

local NorthYanktonIPLs = { "plg_01", "prologue01", "prologue01_lod", "prologue01c", "prologue01c_lod", "prologue01d", "prologue01d_lod", "prologue01e", "prologue01e_lod", "prologue01f", "prologue01f_lod", "prologue01g", "prologue01h", "prologue01h_lod", "prologue01i", "prologue01i_lod", "prologue01j", "prologue01j_lod", "prologue01k", "prologue01k_lod", "prologue01z", "prologue01z_lod", "plg_02", "prologue02", "prologue02_lod", "plg_03", "prologue03", "prologue03_lod", "prologue03b", "prologue03b_lod", "prologue03_grv_dug", "prologue03_grv_dug_lod", "prologue_grv_torch", "plg_04", "prologue04", "prologue04_lod", "prologue04b", "prologue04b_lod", "prologue04_cover", "des_protree_end", "des_protree_start", "des_protree_start_lod", "plg_05", "prologue05", "prologue05_lod", "prologue05b", "prologue05b_lod", "plg_06", "prologue06", "prologue06_lod", "prologue06b", "prologue06b_lod", "prologue06_int", "prologue06_int_lod", "prologue06_pannel", "prologue06_pannel_lod", "prologue_m2_door", "prologue_m2_door_lod", "plg_occl_00", "prologue_occl", "plg_rd", "prologuerd", "prologuerdb", "prologuerd_lod" }

--- Request an IPL set
---@param ipls table
local function RequestIPLSet(ipls)
    for _, ipl in ipairs(ipls) do
        if not STREAMING.IS_IPL_ACTIVE(ipl) then
            STREAMING.REQUEST_IPL(ipl)
        end
    end
end

--- Remove an IPL set
---@param ipls table
local function RemoveIPLSet(ipls)
    for _, ipl in ipairs(ipls) do
        if STREAMING.IS_IPL_ACTIVE(ipl) then
            STREAMING.REMOVE_IPL(ipl)
        end
    end
end

--- Teleport to coordinates
local function TeleportToCoords(x, y, z)
    local ped = PLAYER.PLAYER_PED_ID()
    local entity = ped
    if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        entity = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    end
    ENTITY.SET_ENTITY_COORDS(entity, x, y, z, false, false, false, true)
end

--- Create a new IPLTeleportMenu
---@return IPLTeleportMenu
function IPLTeleportMenu.new()
    local self = setmetatable(Submenu.new("IPL Locations"), IPLTeleportMenu)
    return self
end

function IPLTeleportMenu:Init()
    -- Unload all IPLs
    self:AddOption(ButtonOption.new("Unload all IPL's")
        :AddFunction(function()
            STREAMING.REMOVE_IPL("ufo")
            STREAMING.REMOVE_IPL("cargoship")
            STREAMING.REMOVE_IPL("Plane_crash_trench")
            STREAMING.REMOVE_IPL("canyonriver01_traincrash")
            STREAMING.REMOVE_IPL("railing_end")
            STREAMING.REMOVE_IPL("Coroner_Int_on")
            STREAMING.REMOVE_IPL("RC12B_HospitalInterior")
            STREAMING.REMOVE_IPL("RC12B_Destroyed")
            STREAMING.REMOVE_IPL("smboat")
            RemoveIPLSet(CarrierIPLs)
            RemoveIPLSet(NorthYanktonIPLs)
            RemoveIPLSet(YachtIPLs)
            Renderer.Notify("All IPL's unloaded")
        end)
        :AddTooltip("Unload all loaded IPL's")
        :AddHotkey())
    
    -- Porn Yacht
    self:AddOption(ButtonOption.new("Porn Yacht")
        :AddFunction(function()
            STREAMING.REQUEST_IPL("smboat")
            RemoveIPLSet(YachtIPLs)
            TeleportToCoords(-2045.8, -1031.2, 11.9)
            Renderer.Notify("Teleported to Porn Yacht")
        end)
        :AddTooltip("Teleport to Porn Yacht")
        :AddHotkey())
    
    -- Desert UFO
    self:AddOption(ButtonOption.new("Desert UFO")
        :AddFunction(function()
            STREAMING.REQUEST_IPL("ufo")
            TeleportToCoords(2490.47729, 3774.84351, 2414.035)
            Renderer.Notify("Teleported to Desert UFO")
        end)
        :AddTooltip("Teleport to Desert UFO")
        :AddHotkey())
    
    -- Carrier
    self:AddOption(ButtonOption.new("Carrier")
        :AddFunction(function()
            RequestIPLSet(CarrierIPLs)
            TeleportToCoords(3016.46, -4534.09, 14.84)
            Renderer.Notify("Teleported to Carrier")
        end)
        :AddTooltip("Teleport to Aircraft Carrier")
        :AddHotkey())
    
    -- Cargoship
    self:AddOption(ButtonOption.new("Cargoship")
        :AddFunction(function()
            STREAMING.REQUEST_IPL("cargoship")
            TeleportToCoords(-90.0, -2365.8, 14.3)
            Renderer.Notify("Teleported to Cargoship")
        end)
        :AddTooltip("Teleport to Cargoship")
        :AddHotkey())
    
    -- North Yankton
    self:AddOption(ButtonOption.new("North Yankton")
        :AddFunction(function()
            RequestIPLSet(NorthYanktonIPLs)
            TeleportToCoords(3360.19, -4849.67, 111.8)
            Renderer.Notify("Teleported to North Yankton")
        end)
        :AddTooltip("Teleport to North Yankton")
        :AddHotkey())
    
    -- Plane Crash
    self:AddOption(ButtonOption.new("Plane Crash")
        :AddFunction(function()
            STREAMING.REQUEST_IPL("Plane_crash_trench")
            TeleportToCoords(2814.7, 4758.5, 50.0)
            Renderer.Notify("Teleported to Plane Crash")
        end)
        :AddTooltip("Teleport to Plane Crash site")
        :AddHotkey())
    
    -- Train Crash
    self:AddOption(ButtonOption.new("Train Crash")
        :AddFunction(function()
            STREAMING.REQUEST_IPL("canyonriver01_traincrash")
            STREAMING.REQUEST_IPL("railing_end")
            STREAMING.REMOVE_IPL("railing_start")
            STREAMING.REMOVE_IPL("canyonriver01")
            TeleportToCoords(-532.1309, 4526.187, 88.7955)
            Renderer.Notify("Teleported to Train Crash")
        end)
        :AddTooltip("Teleport to Train Crash site")
        :AddHotkey())
    
    -- Morgue
    self:AddOption(ButtonOption.new("Morgue")
        :AddFunction(function()
            STREAMING.REQUEST_IPL("Coroner_Int_on")
            TeleportToCoords(244.9, -1374.7, 39.5)
            Renderer.Notify("Teleported to Morgue")
        end)
        :AddTooltip("Teleport to Morgue")
        :AddHotkey())
    
    -- Destroyed Hospital
    self:AddOption(ButtonOption.new("Destroyed Hospital")
        :AddFunction(function()
            STREAMING.REMOVE_IPL("RC12B_Default")
            STREAMING.REMOVE_IPL("RC12B_Fixed")
            STREAMING.REQUEST_IPL("RC12B_Destroyed")
            STREAMING.REQUEST_IPL("RC12B_HospitalInterior")
            TeleportToCoords(356.8, -590.1, 43.3)
            Renderer.Notify("Teleported to Destroyed Hospital")
        end)
        :AddTooltip("Teleport to Destroyed Hospital")
        :AddHotkey())
    
    -- Fort Zancudo UFO
    self:AddOption(ButtonOption.new("Fort Zancudo UFO")
        :AddFunction(function()
            STREAMING.REQUEST_IPL("ufo")
            TeleportToCoords(-2051.99463, 3237.05835, 1456.97021)
            Renderer.Notify("Teleported to Fort Zancudo UFO")
        end)
        :AddTooltip("Teleport to Fort Zancudo UFO")
        :AddHotkey())
    
    -- Heist Yacht
    self:AddOption(ButtonOption.new("Heist Yacht")
        :AddFunction(function()
            STREAMING.REMOVE_IPL("smboat")
            RequestIPLSet(YachtIPLs)
            TeleportToCoords(-2045.8, -1031.2, 11.9)
            Renderer.Notify("Teleported to Heist Yacht")
        end)
        :AddTooltip("Teleport to Heist Yacht")
        :AddHotkey())
end

function IPLTeleportMenu:FeatureUpdate()
    -- Nothing to update
end

return IPLTeleportMenu
