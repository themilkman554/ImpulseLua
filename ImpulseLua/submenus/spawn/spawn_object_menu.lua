--[[
    Impulse Lua - Spawn Object Menu
    Port of spawnObjectMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local TextInputComponent = require("Impulse/ImpulseLua/lib/ui/text_input_component")
local Objects = require("Impulse/ImpulseLua/lib/data/objects")

local SpawnObjectMenu = setmetatable({}, { __index = Submenu })
SpawnObjectMenu.__index = SpawnObjectMenu

local instance = nil

-- Settings
local settings = {
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
local function SpawnObject(modelName, isInput)
    local hash = GetHash(modelName)
    print("[SpawnObject] Requesting: " .. tostring(modelName) .. " Hash: " .. tostring(hash))

    if not STREAMING.IS_MODEL_IN_CDIMAGE(hash) then
        print("[SpawnObject] Model not in cdimage: " .. tostring(modelName))
        return
    end

    STREAMING.REQUEST_MODEL(hash)
    local timeout = 0
    while not STREAMING.HAS_MODEL_LOADED(hash) and timeout < 100 do
        timeout = timeout + 1
        coroutine.yield()
    end
    
    if not STREAMING.HAS_MODEL_LOADED(hash) then
        print("[SpawnObject] Failed to load model: " .. tostring(modelName))
        return
    end

    local x, y, z
    local useSpawnerBlip = false
    
    -- Check if spawner mode is active (lazy require to avoid circular dependency)
    local SpawnMenu = require("Impulse/ImpulseLua/submenus/spawn_menu")
    if SpawnMenu.IsSpawnerModeActive and SpawnMenu.IsSpawnerModeActive() then
        local coords = SpawnMenu.GetSpawnerCoords()
        if coords then
            x = coords.x
            y = coords.y
            z = coords.z
            useSpawnerBlip = SpawnMenu.ShouldAddBlip and SpawnMenu.ShouldAddBlip()
        end
    end
    
    -- Fallback to spawning in front of player
    if not x then
        local ped = PLAYER.PLAYER_PED_ID()
        local coords = ENTITY.GET_ENTITY_COORDS(ped, false)
        local heading = ENTITY.GET_ENTITY_HEADING(ped)
        
        local forward = 2.0
        x = coords.x + math.sin(-math.rad(heading)) * forward
        y = coords.y + math.cos(-math.rad(heading)) * forward
        z = coords.z
    end
    
    local obj = GTA.CreateObject(hash, x, y, z, true, true)
    
    if obj ~= 0 then
        print("[SpawnObject] Created object handle: " .. tostring(obj))
        
        -- Use spawner blip setting or local blip setting
        if useSpawnerBlip or settings.blip then
            local blip = HUD.ADD_BLIP_FOR_ENTITY(obj)
            HUD.SET_BLIP_SPRITE(blip, 351) 
        end
        
        -- Track in spawner if active
        if SpawnMenu.IsSpawnerModeActive and SpawnMenu.IsSpawnerModeActive() then
            if SpawnMenu.TrackSpawnedEntity then
                SpawnMenu.TrackSpawnedEntity(obj)
            end
        end
    else
        print("[SpawnObject] GTA.CreateObject returned 0")
    end
    
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
end

function SpawnObjectMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Object Spawn"), SpawnObjectMenu)
        instance:Init()
    end
    return instance
end

function SpawnObjectMenu:Init()
    self:AddOption(ToggleOption.new("Blip")
        :AddToggleRef(settings, "blip")
        :AddTooltip("Add blip for spawned objects"))

    self:AddOption(BreakOption.new())

    self:AddOption(ButtonOption.new("Input object name")
        :AddFunction(function()
            local input = TextInputComponent.new("Object Name", function(text)
                if text and #text > 0 then
                    SpawnObject(text, true)
                end
            end)
            input:Show()
        end)
        :AddTooltip("Spawn object by name"))

    self:AddOption(BreakOption.new("Objects"))

    for _, model in ipairs(Objects) do
        self:AddOption(ButtonOption.new(model)
            :AddFunction(function()
                SpawnObject(model, false)
            end)
            :AddTooltip("Spawn " .. model))
    end
end

return SpawnObjectMenu
