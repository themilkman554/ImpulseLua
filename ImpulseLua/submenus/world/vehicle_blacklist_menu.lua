--[[
    Impulse Lua - Vehicle Blacklist Menu
    Port of vehicleBlacklistMenu.cpp from Impulse C++
    Allows blacklisting specific vehicle models
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local TextInputComponent = require("Impulse/ImpulseLua/lib/ui/text_input_component")

---@class VehicleBlacklistMenu : Submenu
local VehicleBlacklistMenu = setmetatable({}, { __index = Submenu })
VehicleBlacklistMenu.__index = VehicleBlacklistMenu

local instance = nil
local addVehicleInput = nil  -- Text input component

-- State
local vars = {
    enabled = false,
    actionIndex = 1,
    blacklistedVehicles = {}  -- Array of model name strings
}

-- Action options
local actionOptions = {
    { name = "Delete Vehicle" },
    { name = "Teleport To Sea" },
    { name = "Kick From Vehicle" }
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function GetLocalPed()
    return PLAYER.PLAYER_PED_ID()
end

-- Request control of entity
local function RequestControl(entity)
    local tick = 0
    while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) and tick <= 25 do
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
        tick = tick + 1
    end
end

-- Remove vehicle from blacklist by name
local function RemoveVehicleFromList(name)
    local newList = {}
    for _, v in ipairs(vars.blacklistedVehicles) do
        if v ~= name then
            table.insert(newList, v)
        end
    end
    vars.blacklistedVehicles = newList
end

-- ============================================
-- MENU CLASS
-- ============================================

function VehicleBlacklistMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Vehicles blacklist"), VehicleBlacklistMenu)
        instance:Init()
    end
    return instance
end

function VehicleBlacklistMenu:Init()
    self:AddOption(ToggleOption.new("Enable blacklist")
        :AddToggleRef(vars, "enabled")
        :AddTooltip("Enable the vehicles blacklist")
        :AddHotkey())
        :SetDonor()
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Action")
        :AddScroll(actionOptions, 1)
        :AddIndexRef(vars, "actionIndex")
        :AddTooltip("Choose what happens to blacklisted vehicle"))
        :SetDonor()

    self:AddOption(ButtonOption.new("Add vehicle")
        :AddFunction(function()
            if not addVehicleInput then
                addVehicleInput = TextInputComponent.new("Vehicle codename", function(text)
                    if text and text ~= "" then
                        table.insert(vars.blacklistedVehicles, text)
                        GUI.AddToast("Vehicle Blacklist", "Added: " .. text, 3000)
                        instance:RebuildVehicleList()
                    end
                    addVehicleInput = nil
                end)
            end
            addVehicleInput:Show()
        end)
        :AddTooltip("Add a vehicle to the blacklist (enter model name like 'adder')")
        :AddHotkey())
        :SetDonor()
    self:AddOption(BreakOption.new("Blacklisted Vehicles"))
end

--- Called when entering submenu - rebuild vehicle list
function VehicleBlacklistMenu:OnEnter()
    self:RebuildVehicleList()
end

--- Rebuild dynamic vehicle list
function VehicleBlacklistMenu:RebuildVehicleList()
    -- Clear options after BreakOption (index 4)
    while #self.options > 4 do
        table.remove(self.options)
    end

    -- Add buttons for each blacklisted vehicle
    for _, vehicleName in ipairs(vars.blacklistedVehicles) do
        self:AddOption(ButtonOption.new(vehicleName)
            :AddFunction(function()
                RemoveVehicleFromList(vehicleName)
                GUI.AddToast("Vehicle Blacklist", "Removed: " .. vehicleName, 3000)
                self:RebuildVehicleList()
            end)
            :AddTooltip("Click to remove from blacklist"))
            :SetDonor()
    end
end

--- Feature Update - called every frame
function VehicleBlacklistMenu:FeatureUpdate()
    -- Update text input UI if visible
    if addVehicleInput and addVehicleInput:IsVisible() then
        addVehicleInput:Update()
    end

    if not vars.enabled then return end
    if #vars.blacklistedVehicles == 0 then return end

    local myVeh = PED.GET_VEHICLE_PED_IS_IN(GetLocalPed(), false)

    if PoolMgr.GetCurrentVehicleCount then
        local vehCount = PoolMgr.GetCurrentVehicleCount()
        for i = 0, vehCount - 1 do
            local veh = PoolMgr.GetVehicle(i)
            if veh and veh ~= 0 and veh ~= myVeh and ENTITY.DOES_ENTITY_EXIST(veh) then
                local hash = ENTITY.GET_ENTITY_MODEL(veh)
                local vehModelName = GTA.GetModelNameFromHash(hash)

                for _, modelName in ipairs(vars.blacklistedVehicles) do
                    -- Compare model names (case insensitive)
                    if vehModelName and string.lower(vehModelName) == string.lower(modelName) then
                        RequestControl(veh)

                        if vars.actionIndex == 1 then
                            -- Delete using pointer pattern
                            Script.QueueJob(function()
                                if ENTITY.DOES_ENTITY_EXIST(veh) then
                                    local ptr = Memory.AllocInt()
                                    Memory.WriteInt(ptr, veh)
                                    ENTITY.DELETE_ENTITY(ptr)
                                end
                            end)
                        elseif vars.actionIndex == 2 then
                            -- Teleport to sea
                            ENTITY.SET_ENTITY_COORDS(veh, 6400.0, 6400.0, 0.0, false, false, false, false)
                        elseif vars.actionIndex == 3 then
                            -- Kick from vehicle
                            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh, -1, false)
                            if ENTITY.DOES_ENTITY_EXIST(driver) and PED.IS_PED_IN_VEHICLE(driver, veh, true) then
                                TASK.CLEAR_PED_TASKS_IMMEDIATELY(driver)
                            end
                        end
                        break
                    end
                end
            end
        end
    end
end

return VehicleBlacklistMenu
