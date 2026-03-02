--[[
    Impulse Lua - LSC Plates Menu
    Port of vehiclePlatesMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local TextInputComponent = require("Impulse/ImpulseLua/lib/ui/text_input_component")

local PlatesMenu = setmetatable({}, { __index = Submenu })
PlatesMenu.__index = PlatesMenu

local instance = nil

-- License plate types
local plateTypes = {
    { name = "Blue on White", value = 0 },
    { name = "Yellow on Black", value = 1 },
    { name = "Yellow on White", value = 2 },
    { name = "Blue on White 2", value = 3 },
    { name = "Blue on White 3", value = 4 },
    { name = "Yankton", value = 5 }
}

local vars = {
    plateIndex = 1
}

local textInput = nil

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

function PlatesMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Plates"), PlatesMenu)
        instance:Init()
    end
    return instance
end

function PlatesMenu:Init()
    -- License plate type
    local plateNames = {}
    for i, p in ipairs(plateTypes) do
        plateNames[i] = p.name
    end
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "License plate")
        :AddScroll(plateNames, 1)
        :AddIndexRef(vars, "plateIndex")
        :CanLoop()
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            if IsInVehicle() then
                local plateValue = plateTypes[vars.plateIndex].value
                VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(GetCurrentVehicle(), plateValue)
            end
        end)
        :AddTooltip("Set license plate style")
        :SetDonor())
    
    -- Set plate text
    self:AddOption(ButtonOption.new("Set license plate text")
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            if IsInVehicle() then
                textInput = TextInputComponent.new("Enter plate text (max 8 chars)", function(text)
                    if text and #text > 0 then
                        local plateText = text:sub(1, 8):upper()
                        VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(GetCurrentVehicle(), plateText)
                    end
                    textInput = nil
                end)
                textInput:Show()
            end
        end)
        :AddTooltip("Enter custom license plate text")
        :SetDonor())
end

function PlatesMenu:FeatureUpdate()
    if textInput and textInput:IsVisible() then
        textInput:Update()
    end
end

return PlatesMenu
