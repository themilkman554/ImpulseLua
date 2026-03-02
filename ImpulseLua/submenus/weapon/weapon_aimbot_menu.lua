--[[
    Impulse Lua - Weapon Aimbot Menu
    Ported from weaponAimbot.cpp
]]

local WeaponAimbotMenu = {}
WeaponAimbotMenu.__index = WeaponAimbotMenu

-- Imports
local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

-- State
local state = {
    basicaimbot = false,
    basicplayeraimbot = false,
    basictriggerbot = false,
    
    -- Custom Aimbot
    entityFilter = 0,
    prioritize = 0,
    bone = 0, -- index
    required = false, -- Master toggle for custom aimbot
    autoShoot = false,
    
    -- Internal
    lastShotTime = 0
}

-- Data Tables
local entityFilterStruct = { "Ped", "Player", "Ped + Player" }

local entityBoneStruct = {
    { name = "Head", id = 0x796E },
    { name = "Neck", id = 0x9995 },
    { name = "Tongue", id = 0xB987 },
    { name = "Spine", id = 0x60F0 },
    { name = "Left Hand", id = 0x49D9 },
    { name = "Right Hand", id = 0xE5f2 },
    { name = "Left Foot", id = 0x3779 },
    { name = "Right Foot", id = 0xCC4D }
}

local boneNames = {}
for _, v in ipairs(entityBoneStruct) do table.insert(boneNames, v.name) end

-- Helper Functions

local function GetNearestLocalPed()
    local playerPed = PLAYER.PLAYER_PED_ID()
    local nearest = 0
    local minDistance = 99999.0
    
    -- Native: GET_PED_NEARBY_PEDS
    -- C++ allocates ElementAmount * 2 + 2 ints. 
    -- ElementAmount = 50. Total ints = 102. Bytes = 408.
    local elementAmount = 50
    local arrSizeInts = elementAmount * 2 + 2
    local bufferSize = arrSizeInts * 4
    
    local pedsBuffer = Memory.Alloc(bufferSize)
    Memory.WriteInt(pedsBuffer, elementAmount) -- Write size to first int
    
    local foundCount = PED.GET_PED_NEARBY_PEDS(playerPed, pedsBuffer, -1)
    
    local playerCoords = ENTITY.GET_ENTITY_COORDS(playerPed, true)
    
    for i = 0, foundCount - 1 do
        local offsetInts = i * 2 + 2
        local handle = Memory.ReadInt(pedsBuffer + (offsetInts * 4))
        
        if ENTITY.DOES_ENTITY_EXIST(handle) and handle ~= playerPed and not PED.IS_PED_A_PLAYER(handle) then
            local pCoords = ENTITY.GET_ENTITY_COORDS(handle, true)
            local dist = math.sqrt((pCoords.x - playerCoords.x)^2 + (pCoords.y - playerCoords.y)^2 + (pCoords.z - playerCoords.z)^2)
            
            if dist < minDistance then
                minDistance = dist
                nearest = handle
            end
        end
    end
    
    Memory.Free(pedsBuffer)
    return nearest
end

local function GetNearestLocalPlayerPed()
    local playerPed = PLAYER.PLAYER_PED_ID()
    local nearest = 0
    local minDistance = 99999.0
    local playerCoords = ENTITY.GET_ENTITY_COORDS(playerPed, true)

    -- Iterate active players
    for i = 0, 31 do -- C++ iterates online players. 32 is standard limit.
        if NETWORK.NETWORK_IS_PLAYER_ACTIVE(i) then
            local targetPed = PLAYER.GET_PLAYER_PED(i)
            if ENTITY.DOES_ENTITY_EXIST(targetPed) and targetPed ~= playerPed and not PED.IS_PED_DEAD_OR_DYING(targetPed, true) then
                 local pCoords = ENTITY.GET_ENTITY_COORDS(targetPed, true)
                 local dist = math.sqrt((pCoords.x - playerCoords.x)^2 + (pCoords.y - playerCoords.y)^2 + (pCoords.z - playerCoords.z)^2)
                 
                 if dist < minDistance then
                     minDistance = dist
                     nearest = targetPed
                 end
            end
        end
    end
    return nearest
end

local function ProcessAimbotTarget(target, boneID, autoShoot)
    if not target or target == 0 then return end
    
    local playerPed = PLAYER.PLAYER_PED_ID()
    local targetPos = ENTITY.GET_ENTITY_COORDS(target, true)
    
    -- Check visibility/screen
    local onScreen = true -- Lua wrapper usually doesn't have good screen coord check, assume OK or use native
    -- GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD returns bool
    -- But we need pointers for output x/y.
    -- For now, let's skip onScreen check or use simple memory one if needed.
    -- Actually C++ does onScreen check.
    -- Just stick to LoS check for simplicity first.
    
    if ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(playerPed, target, 17) then -- 17 = map + vehicles + peds?
        -- Draw marker
        GRAPHICS.DRAW_MARKER(2, targetPos.x, targetPos.y, targetPos.z + 1.5, 0,0,0, 0,180,0, 0.7,0.7,0.7, 255,0,0,120, true, false, 2, false, nil, nil, false)
        
        local targetCoords = PED.GET_PED_BONE_COORDS(target, boneID, 0,0,0)
        
        -- Disable firing manually so script can control it
        PLAYER.DISABLE_PLAYER_FIRING(PLAYER.PLAYER_ID(), true)
        
        -- Check Input: 24 (Attack/LMB) is standard. 
        -- USE IS_DISABLED_CONTROL_PRESSED because we disabled firing!
        -- Group 0 (Move) or 2 (Frontend) usually works.
        local pressedAttack = PAD.IS_DISABLED_CONTROL_PRESSED(0, 24)
        local pressedAttack2 = PAD.IS_DISABLED_CONTROL_PRESSED(0, 208) -- PageUp?
        
        local checkInput = pressedAttack or pressedAttack2 or autoShoot
        
        if checkInput then
             -- print("[Aimbot] Shooting at " .. targetCoords.x .. ", " .. targetCoords.y)
             PED.SET_PED_SHOOTS_AT_COORD(playerPed, targetCoords.x, targetCoords.y, targetCoords.z, true)
        end
    end
end

-- Feature Functions

local function BasicAimbot()
    -- C++ checks PED_FLAG_IS_AIMING (78)
    local playerPed = PLAYER.PLAYER_PED_ID()
    if PED.GET_PED_CONFIG_FLAG(playerPed, 78, true) then
        local target = GetNearestLocalPed()
        if target ~= 0 then
            ProcessAimbotTarget(target, 31086, false) -- Head
        end
    end
end

local function BasicPlayerAimbot()
    local playerPed = PLAYER.PLAYER_PED_ID()
    if PED.GET_PED_CONFIG_FLAG(playerPed, 78, true) then
        local target = GetNearestLocalPlayerPed()
        if target ~= 0 then
            ProcessAimbotTarget(target, 31086, false) -- Head
        end
    end
end

local function BasicTriggerBot()
    local playerPed = PLAYER.PLAYER_PED_ID()
    local ptr = Memory.Alloc(4)
    if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), ptr) then
        local target = Memory.ReadInt(ptr)
        Memory.Free(ptr)
        
        if target ~= 0 and ENTITY.IS_ENTITY_A_PED(target) and PED.IS_PED_A_PLAYER(target) then
             if not PED.IS_PED_DEAD_OR_DYING(target, true) then
                 local headDiff = PED.GET_PED_BONE_COORDS(target, 31086, 0.1, 0, 0)
                 PED.SET_PED_SHOOTS_AT_COORD(playerPed, headDiff.x, headDiff.y, headDiff.z, true)
             end
        end
    else
        Memory.Free(ptr)
    end
end

local function Aimbot()
    local nearestPed = GetNearestLocalPed()
    local nearestPlayer = GetNearestLocalPlayerPed()
    local target = 0
    
    -- Filter (0: Ped, 1: Player, 2: Both)
    if state.entityFilter == 0 then
        target = nearestPed
    elseif state.entityFilter == 1 then
        target = nearestPlayer
    else -- Both
        if state.prioritize == 0 then -- Prioritize Ped? (C++ logic says "if prioritize == 0" -> "if nearestPed != 0 handle = nearestPed")
             if nearestPed ~= 0 then target = nearestPed
             elseif nearestPlayer ~= 0 then target = nearestPlayer end
        else -- Prioritize Player
             if nearestPlayer ~= 0 then target = nearestPlayer
             elseif nearestPed ~= 0 then target = nearestPed end
        end
    end
    
    if target ~= 0 then
        local boneID = entityBoneStruct[state.bone + 1].id
        ProcessAimbotTarget(target, boneID, state.autoShoot)
    end
end

-- Instance

function WeaponAimbotMenu.GetInstance()
    if _instance == nil then _instance = WeaponAimbotMenu.new() end
    return _instance
end

function WeaponAimbotMenu.new()
    local self = setmetatable(Submenu.new("Aimbot"), { __index = WeaponAimbotMenu })
    setmetatable(WeaponAimbotMenu, { __index = Submenu }) -- Proper Inheritance
    return self
end

function WeaponAimbotMenu:Init()
    self:AddOption(ToggleOption.new("Basic ped aimbot")
        :AddToggleRef(state, "basicaimbot")
        :AddTooltip("Automatically aim at ped entities")
        :AddHotkey())
        
    self:AddOption(ToggleOption.new("Basic player aimbot")
        :AddToggleRef(state, "basicplayeraimbot")
        :AddTooltip("Automatically aim at player entities")
        :AddHotkey())
        
    self:AddOption(ToggleOption.new("Basic player triggerbot")
        :AddToggleRef(state, "basictriggerbot")
        :AddTooltip("Automatically shoot the entity")
        :AddHotkey())

    self:AddOption(BreakOption.new("Custom Aimbot"))
    
    local filterOpt = ScrollOption.new(ScrollOption.Type.SCROLL, "Entity filter")
    filterOpt:AddScroll(entityFilterStruct, 1)
    filterOpt:AddFunction(function() state.entityFilter = filterOpt:GetIndex() - 1 end) -- 0-based custom logic
    filterOpt:AddTooltip("Select the entity filter for the aimbot")
    self:AddOption(filterOpt)
    
    local prioOpt = ScrollOption.new(ScrollOption.Type.SCROLL, "Prioritize")

    prioOpt:AddScroll({"Ped", "Player"}, 1)
    prioOpt:AddFunction(function() state.prioritize = prioOpt:GetIndex() - 1 end)
    prioOpt:AddTooltip("Select the entity group to prioritize")
    self:AddOption(prioOpt)
    
    local boneOpt = ScrollOption.new(ScrollOption.Type.SCROLL, "Bone")
    boneOpt:AddScroll(boneNames, 1)
    boneOpt:AddFunction(function() state.bone = boneOpt:GetIndex() - 1 end) -- 0-based for array access
    boneOpt:AddTooltip("Select the bone to shoot")
    self:AddOption(boneOpt)
    
    self:AddOption(ToggleOption.new("Aimbot required")
        :AddToggleRef(state, "required")
        :AddTooltip("Enable this to enable the custom aimbot")
        :AddHotkey())
        
    self:AddOption(ToggleOption.new("Auto shoot")
        :AddToggleRef(state, "autoShoot")
        :AddTooltip("Automatically shoot the entity")
        :AddHotkey())
end

function WeaponAimbotMenu:FeatureUpdate()
    if state.required then Aimbot() end
    if state.basicaimbot then BasicAimbot() end
    if state.basicplayeraimbot then BasicPlayerAimbot() end
    if state.basictriggerbot then BasicTriggerBot() end
end

return WeaponAimbotMenu
