--[[
    Impulse Lua - Spawn Ped Menu
    Port of spawnPedMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local TextInputComponent = require("Impulse/ImpulseLua/lib/ui/text_input_component")
local Peds = require("Impulse/ImpulseLua/lib/data/peds")

local SpawnPedMenu = setmetatable({}, { __index = Submenu })
SpawnPedMenu.__index = SpawnPedMenu

local instance = nil

-- Settings
local settings = {
    godmode = false,
    blip = false,
    particles = false
}

-- Helper: Get Hash
local function GetHash(modelName)
    if Utils and Utils.Joaat then
        return Utils.Joaat(modelName)
    else
        return MISC.GET_HASH_KEY(modelName)
    end
end

-- Spawn Logic
local function SpawnPed(modelName, isInput)
    local hash = GetHash(modelName)
    print("[SpawnPed] Requesting: " .. tostring(modelName) .. " Hash: " .. tostring(hash))

    if not STREAMING.IS_MODEL_IN_CDIMAGE(hash) then
        print("[SpawnPed] Model not in cdimage: " .. tostring(modelName))
        return
    end

    STREAMING.REQUEST_MODEL(hash)
    local timeout = 0
    while not STREAMING.HAS_MODEL_LOADED(hash) and timeout < 100 do
        timeout = timeout + 1
        coroutine.yield()
    end
    
    if not STREAMING.HAS_MODEL_LOADED(hash) then
        print("[SpawnPed] Failed to load model: " .. tostring(modelName))
        return
    end

    local x, y, z, heading
    local useSpawnerBlip = false
    
    -- Check if spawner mode is active (lazy require to avoid circular dependency)
    local SpawnMenu = require("Impulse/ImpulseLua/submenus/spawn_menu")
    if SpawnMenu.IsSpawnerModeActive and SpawnMenu.IsSpawnerModeActive() then
        local coords = SpawnMenu.GetSpawnerCoords()
        if coords then
            x = coords.x
            y = coords.y
            z = coords.z
            heading = 0.0
            useSpawnerBlip = SpawnMenu.ShouldAddBlip and SpawnMenu.ShouldAddBlip()
        end
    end
    
    -- Fallback to spawning in front of player
    if not x then
        local ped = PLAYER.PLAYER_PED_ID()
        local coords = ENTITY.GET_ENTITY_COORDS(ped, false)
        heading = ENTITY.GET_ENTITY_HEADING(ped)
        
        local forward = 2.0
        x = coords.x + math.sin(-math.rad(heading)) * forward
        y = coords.y + math.cos(-math.rad(heading)) * forward
        z = coords.z
    end

    local spawnedPed = GTA.CreatePed(hash, 26, x, y, z, heading, true, true)
    
    if spawnedPed ~= 0 then
        print("[SpawnPed] Created ped handle: " .. tostring(spawnedPed))
        if settings.godmode then
            ENTITY.SET_ENTITY_INVINCIBLE(spawnedPed, true)
        end
        
        -- Use spawner blip setting or local blip setting
        if useSpawnerBlip or settings.blip then
            local blip = HUD.ADD_BLIP_FOR_ENTITY(spawnedPed)
            HUD.SET_BLIP_SPRITE(blip, 366) 
        end
        
        -- Track in spawner if active
        if SpawnMenu.IsSpawnerModeActive and SpawnMenu.IsSpawnerModeActive() then
            if SpawnMenu.TrackSpawnedEntity then
                SpawnMenu.TrackSpawnedEntity(spawnedPed)
            end
        end
    else
        print("[SpawnPed] GTA.CreatePed returned 0")
    end
    
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
end

function SpawnPedMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Ped Spawn"), SpawnPedMenu)
        instance:Init()
    end
    return instance
end

function SpawnPedMenu:Init()
    self:AddOption(ToggleOption.new("Godmode")
        :AddToggleRef(settings, "godmode")
        :AddTooltip("Make spawned peds invincible"))
        
    self:AddOption(ToggleOption.new("Blip")
        :AddToggleRef(settings, "blip")
        :AddTooltip("Add blip for spawned peds"))

    self:AddOption(BreakOption.new())

    self:AddOption(ButtonOption.new("Input ped name")
        :AddFunction(function()
            local input = TextInputComponent.new("Ped Name", function(text)
                if text and #text > 0 then
                    SpawnPed(text, true)
                end
            end)
            input:Show()
        end)
        :AddTooltip("Spawn ped by name"))

    self:AddOption(BreakOption.new("Peds"))

    for _, pedData in ipairs(Peds) do
        self:AddOption(ButtonOption.new(pedData.name)
            :AddFunction(function()
                SpawnPed(pedData.model, false)
            end)
            :AddTooltip("Spawn " .. pedData.name))
    end
end

return SpawnPedMenu
