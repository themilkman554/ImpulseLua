--[[
    Impulse Lua - Weather Manager Menu
    Port of weatherManagerMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local WeatherMenu = setmetatable({}, { __index = Submenu })
WeatherMenu.__index = WeatherMenu

local instance = nil

-- Variables
local vars = {
    clouds = 1,
    lightning = false,
    meteors = false,
    rain = 0.0,
    lightningTimer = 0
}

-- Cloud types
local cloudTypes = {
    { name = "Cloudy", value = "cloudy 01" },
    { name = "Rain", value = "rain" },
    { name = "Horizon Band 1", value = "horizonband1" },
    { name = "Horizon Band 2", value = "horizonband2" },
    { name = "Horizon Band 3", value = "horizonband3" },
    { name = "Puffs", value = "Puffs" },
    { name = "Wispy", value = "Wispy" },
    { name = "Horizon", value = "Horizon" },
    { name = "Stormy", value = "Stormy 01" },
    { name = "Clear", value = "Clear 01" },
    { name = "Snowy", value = "Snowy 01" },
    { name = "Contrails", value = "Contrails" },
    { name = "Altostratus", value = "altostratus" },
    { name = "Nimbus", value = "Nimbus" },
    { name = "Cirrus", value = "Cirrus" },
    { name = "Cirrocumulus", value = "cirrocumulus" },
    { name = "Stratoscumulus", value = "stratoscumulus" },
    { name = "Stripey", value = "Stripey" },
    { name = "Horsey", value = "horsey" },
    { name = "Shower", value = "shower" }
}

-- Weather types
local weatherTypes = {
    { name = "Clear", value = "CLEAR" },
    { name = "Clearing", value = "CLEARING" },
    { name = "Neutral", value = "NEUTRAL" },
    { name = "Extra Sunny", value = "EXTRASUNNY" },
    { name = "Rain", value = "RAIN" },
    { name = "Smog", value = "SMOG" },
    { name = "Snow", value = "SNOW" },
    { name = "Xmas", value = "XMAS" },
    { name = "Halloween", value = "HALLOWEEN" },
    { name = "Snowlight", value = "SNOWLIGHT" },
    { name = "Blizzard", value = "BLIZZARD" },
    { name = "Thunder", value = "THUNDER" },
    { name = "Overcast", value = "OVERCAST" },
    { name = "Foggy", value = "FOGGY" }
}

-- Meteor handles
local meteorHandles = {}

local function GetLocalPed()
    return PLAYER.PLAYER_PED_ID()
end

local function GetLocalCoords()
    return ENTITY.GET_ENTITY_COORDS(GetLocalPed(), true)
end

-- Meteor shower function
local function Meteors()
    local propHash = 0xDF9841D7 -- prop_asteroid_01
    STREAMING.REQUEST_MODEL(propHash)
    
    -- Maintain 70 meteors
    for i = 1, 70 do
        if not meteorHandles[i] or not ENTITY.DOES_ENTITY_EXIST(meteorHandles[i]) then
            local coords = GetLocalCoords()
            local x = coords.x + math.random(-350, 350)
            local y = coords.y + math.random(-350, 350)
            local z = coords.z + math.random(160, 249)
            
            meteorHandles[i] = OBJECT.CREATE_OBJECT(propHash, x, y, z, true, true, false)
            if ENTITY.DOES_ENTITY_EXIST(meteorHandles[i]) then
                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(meteorHandles[i], 1, 0, 0, -999999, true, true, true, true)
            end
        else
            local height = ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(meteorHandles[i])
            local speed = ENTITY.GET_ENTITY_SPEED(meteorHandles[i])
            
            if height < 21 or speed == 0.0 then
                local coords = ENTITY.GET_ENTITY_COORDS(meteorHandles[i], true)
                FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 29, 1000.0, true, false, 0.9, false)
                ENTITY.DELETE_ENTITY(meteorHandles[i])
                meteorHandles[i] = nil
            end
        end
    end
end

function WeatherMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Weather manager"), WeatherMenu)
        instance:Init()
    end
    return instance
end

function WeatherMenu:Init()
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLLSELECT, "Clouds")
        :AddScroll(cloudTypes, 1)
        :AddIndexRef(vars, "clouds")
        :AddFunction(function()
            local cloud = cloudTypes[vars.clouds].value
            MISC.LOAD_CLOUD_HAT(cloud, 0.5)
        end)
        :AddTooltip("Set the cloud type"))

    self:AddOption(ToggleOption.new("Lightning storm")
        :AddToggle(vars.lightning)
        :AddFunction(function(val) vars.lightning = val end)
        :AddTooltip("Summon a lightning storm!"))

    self:AddOption(ToggleOption.new("Meteor shower")
        :AddToggle(vars.meteors)
        :AddFunction(function(val) vars.meteors = val end)
        :AddTooltip("Summon a meteor shower!"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Rain intensity")
        :AddNumberRef(vars, "rain", "%.1f", 0.1)
        :AddMin(0):AddMax(100)
        :AddFunction(function()
            MISC.SET_RAIN(vars.rain)
        end)
        :AddTooltip("Set rain intensity"))

    self:AddOption(BreakOption.new("Weather types"))

    -- Add weather type buttons
    for i, weather in ipairs(weatherTypes) do
        self:AddOption(ButtonOption.new(weather.name)
            :AddFunction(function()
                MISC.SET_WEATHER_TYPE_NOW_PERSIST(weather.value)
            end)
            :AddTooltip("Change the weather"))
    end
end

function WeatherMenu:FeatureUpdate()
    -- Lightning storm
    if vars.lightning then
        local now = MISC.GET_GAME_TIMER()
        if now > vars.lightningTimer then
            MISC.CREATE_LIGHTNING_THUNDER()
            vars.lightningTimer = now + 500
        end
    end
    
    -- Meteor shower
    if vars.meteors then
        Meteors()
    end
end

return WeatherMenu
