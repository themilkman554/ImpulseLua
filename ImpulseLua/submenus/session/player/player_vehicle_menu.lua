--[[
    Impulse Lua - Player Vehicle Menu
    Vehicle options for selected player's vehicle
    Port of playerVehicleMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")
local PlayerMenu = nil -- Lazy loaded

local PlayerVehicleMenu = setmetatable({}, { __index = Submenu })
PlayerVehicleMenu.__index = PlayerVehicleMenu

local instance = nil

-- Per-player state tracking
local playerVehicleState = {}

local function GetPlayerState(playerId)
    if not playerVehicleState[playerId] then
        playerVehicleState[playerId] = {
            hornBoost = false,
            kickLoop = false,
            freezeVehicle = false
        }
    end
    return playerVehicleState[playerId]
end



-- ============================================
-- Helper Functions
-- ============================================

local function GetSelectedPlayerId()
    if not PlayerMenu then
        PlayerMenu = require("Impulse/ImpulseLua/submenus/session/player_menu")
    end
    return PlayerMenu.targetPlayer or -1
end

local function GetSelectedPlayerName()
    if not PlayerMenu then
        PlayerMenu = require("Impulse/ImpulseLua/submenus/session/player_menu")
    end
    local playerId = PlayerMenu.targetPlayer or -1
    if playerId < 0 then return "Unknown" end
    return PLAYER.GET_PLAYER_NAME(playerId) or "Unknown"
end

local function GetSelectedPlayerPed()
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then return 0 end
    return PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
end

local function GetSelectedPlayerVehicle()
    local ped = GetSelectedPlayerPed()
    if not ped or ped == 0 then 
        return nil, "Player not found"
    end
    
    if not ENTITY.DOES_ENTITY_EXIST(ped) then
        return nil, "Player not found"
    end
    
    -- Check if ped is in any vehicle
    local isInVehicle = PED.IS_PED_IN_ANY_VEHICLE(ped, false)
    if not isInVehicle then
        return nil, "Player not in vehicle"
    end
    
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    if not vehicle or vehicle == 0 or not ENTITY.DOES_ENTITY_EXIST(vehicle) then
        return nil, "Could not get vehicle"
    end
    
    return vehicle, nil
end

local function RequestControlOfVehicle(vehicle, timeout)
    timeout = timeout or 50
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
    local count = 0
    while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) and count < timeout do
        Script.Yield(10)
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
        count = count + 1
    end
    return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle)
end

-- ============================================
-- Vehicle Action Functions
-- ============================================

--- Godmode vehicle
local function GodmodeVehicle()
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        ENTITY.SET_ENTITY_INVINCIBLE(vehicle, true)
        ENTITY.SET_ENTITY_PROOFS(vehicle, true, true, true, true, true, true, true, true)
        VEHICLE.SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED(vehicle, false)
        VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, false)
        VEHICLE.SET_VEHICLE_WHEELS_CAN_BREAK(vehicle, false)
        Renderer.Notify("Godmode applied to " .. GetSelectedPlayerName() .. "'s vehicle")
    else
        Renderer.Notify("Failed to get control of vehicle")
    end
end

--- Kick from vehicle (using Cherax built-in)
local function KickFromVehicle()
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then
        Renderer.Notify("No player selected")
        return
    end
    FeatureState.Trigger("Vehicle Kick", playerId)
    Renderer.Notify("Kicked " .. GetSelectedPlayerName() .. " from vehicle")
end

--- Launch vehicle upward
local function LaunchVehicle()
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0, 0, 20, 0, 0, 0, 0, true, true, true, false, true)
        Renderer.Notify("Launched " .. GetSelectedPlayerName() .. "'s vehicle")
    else
        Renderer.Notify("Failed to get control of vehicle")
    end
end

--- Slingshot vehicle
local function SlingshotVehicle()
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0, 0, 150, 4, 2, 0, true, true, true, true, false, true)
        Renderer.Notify("Slingshot " .. GetSelectedPlayerName() .. "'s vehicle")
    else
        Renderer.Notify("Failed to get control of vehicle")
    end
end

--- Boost vehicle
local function BoostVehicle()
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 100.0)
        Renderer.Notify("Boosted " .. GetSelectedPlayerName() .. "'s vehicle")
    else
        Renderer.Notify("Failed to get control of vehicle")
    end
end

--- Stop vehicle
local function StopVehicle()
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 0.0)
        Renderer.Notify("Stopped " .. GetSelectedPlayerName() .. "'s vehicle")
    else
        Renderer.Notify("Failed to get control of vehicle")
    end
end

--- Freeze vehicle
local function FreezeVehicle(freeze)
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        ENTITY.FREEZE_ENTITY_POSITION(vehicle, freeze)
        if freeze then
            Renderer.Notify("Froze " .. GetSelectedPlayerName() .. "'s vehicle")
        else
            Renderer.Notify("Unfroze " .. GetSelectedPlayerName() .. "'s vehicle")
        end
    else
        Renderer.Notify("Failed to get control of vehicle")
    end
end

--- Rotate vehicle (flip upside down)
local function RotateVehicle()
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        local rot = ENTITY.GET_ENTITY_ROTATION(vehicle, 0)
        ENTITY.SET_ENTITY_ROTATION(vehicle, rot.x + 180, rot.y, rot.z, 2, true)
        Renderer.Notify("Rotated " .. GetSelectedPlayerName() .. "'s vehicle")
    else
        Renderer.Notify("Failed to get control of vehicle")
    end
end

--- Kill engine
local function KillEngine()
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, -3700.0)
        Renderer.Notify("Killed " .. GetSelectedPlayerName() .. "'s engine")
    else
        Renderer.Notify("Failed to get control of vehicle")
    end
end

--- Revive engine
local function ReviveEngine()
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, 1000.0)
        Renderer.Notify("Revived " .. GetSelectedPlayerName() .. "'s engine")
    else
        Renderer.Notify("Failed to get control of vehicle")
    end
end

--- Delete vehicle (using Cherax built-in)
local function DeleteVehicle()
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then
        Renderer.Notify("No player selected")
        return
    end
    FeatureState.Trigger("Delete Player Vehicle", playerId)
    Renderer.Notify("Deleted " .. GetSelectedPlayerName() .. "'s vehicle")
end

--- Burst tires
local function BurstTires()
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, true)
        for tireId = 0, 7 do
            VEHICLE.SET_VEHICLE_TYRE_BURST(vehicle, tireId, true, 1000.0)
        end
        Renderer.Notify("Burst " .. GetSelectedPlayerName() .. "'s tires")
    else
        Renderer.Notify("Failed to get control of vehicle")
    end
end

--- Lock/Unlock doors
local function LockDoors(lock)
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, lock and 4 or 1)
        if lock then
            Renderer.Notify("Locked " .. GetSelectedPlayerName() .. "'s doors")
        else
            Renderer.Notify("Unlocked " .. GetSelectedPlayerName() .. "'s doors")
        end
    else
        Renderer.Notify("Failed to get control of vehicle")
    end
end

--- Repair vehicle
local function RepairVehicle()
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        VEHICLE.SET_VEHICLE_FIXED(vehicle)
        Renderer.Notify("Repaired " .. GetSelectedPlayerName() .. "'s vehicle")
    else
        Renderer.Notify("Failed to get control of vehicle")
    end
end

--- Fully tune vehicle
local function TuneVehicle()
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
        for i = 0, 49 do
            local numMods = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i)
            if numMods > 0 then
                VEHICLE.SET_VEHICLE_MOD(vehicle, i, numMods - 1, false)
            end
        end
        VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 18, true) -- Turbo
        VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 22, true) -- Xenon
        Renderer.Notify("Tuned " .. GetSelectedPlayerName() .. "'s vehicle")
    else
        Renderer.Notify("Failed to get control of vehicle")
    end
end

-- ============================================
-- Acrobatics Functions
-- ============================================

local function FrontFlip()
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 20.0, 0.0, -2.0, 0.0, true, true, true, true, false, true)
        Renderer.Notify("Front flip on " .. GetSelectedPlayerName() .. "'s vehicle")
    end
end

local function BackFlip()
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 20.0, 0.0, 6.0, 0.0, true, true, true, true, false, true)
        Renderer.Notify("Back flip on " .. GetSelectedPlayerName() .. "'s vehicle")
    end
end

local function KickFlip()
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 10.71, 5.0, 0.0, 0.0, 1, false, true, true, true, true)
        Renderer.Notify("Kick flip on " .. GetSelectedPlayerName() .. "'s vehicle")
    end
end

local function HeelFlip()
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 20.0, -2.0, 0.0, 0.0, true, true, true, true, false, true)
        Renderer.Notify("Heel flip on " .. GetSelectedPlayerName() .. "'s vehicle")
    end
end

local function BunnyHop()
    local vehicle, err = GetSelectedPlayerVehicle()
    if not vehicle then
        Renderer.Notify(err)
        return
    end
    
    if RequestControlOfVehicle(vehicle) then
        ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 6.0, 0.0, 0.0, 0.0, true, false, true, true, true, true)
        Renderer.Notify("Bunny hop on " .. GetSelectedPlayerName() .. "'s vehicle")
    end
end

-- ============================================
-- Feature Update Functions (for toggles)
-- ============================================

local function HornBoostUpdate()
    local players = Players.Get()
    for _, player in ipairs(players) do
        local state = playerVehicleState[player.Id]
        if state and state.hornBoost then
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player.Id)
            if ped and ped ~= 0 and ENTITY.DOES_ENTITY_EXIST(ped) and PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                if PLAYER.IS_PLAYER_PRESSING_HORN(player.Id) then
                    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                    if vehicle and vehicle ~= 0 and ENTITY.DOES_ENTITY_EXIST(vehicle) then
                        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
                        if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
                            VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 500.0)
                        end
                    end
                end
            end
        end
    end
end



local function FreezeVehicleUpdate()
    local players = Players.Get()
    for _, player in ipairs(players) do
        local state = playerVehicleState[player.Id]
        if state and state.freezeVehicle then
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player.Id)
            if ped and ped ~= 0 and ENTITY.DOES_ENTITY_EXIST(ped) and PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                if vehicle and vehicle ~= 0 and ENTITY.DOES_ENTITY_EXIST(vehicle) then
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
                    if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
                        ENTITY.FREEZE_ENTITY_POSITION(vehicle, true)
                    end
                end
            end
        end
    end
end

-- ============================================
-- Menu Definition
-- ============================================

function PlayerVehicleMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Player vehicle"), PlayerVehicleMenu)
        instance:Init()
    end
    return instance
end

function PlayerVehicleMenu:Init()
    -- Godmode vehicle
    self:AddOption(ButtonOption.new("Godmode vehicle")
        :AddFunction(GodmodeVehicle)
        :AddTooltip("Make player's vehicle invincible"))
    
    -- Kick from vehicle
    self:AddOption(ButtonOption.new("Kick from vehicle")
        :AddFunction(KickFromVehicle)
        :AddTooltip("Kick player from their vehicle"))
    
    -- Movement Modifications
    self:AddOption(BreakOption.new("Movement Modifications"))
    
    -- Horn boost toggle
    self:AddOption(ToggleOption.new("Horn boost", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerState(playerId)
            state.hornBoost = value
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerState(playerId)
            return state.hornBoost
        end
        return false
    end)
        :AddTooltip("Boost player's vehicle when they honk"))
    
    -- Launch vehicle
    self:AddOption(ButtonOption.new("Launch vehicle")
        :AddFunction(LaunchVehicle)
        :AddTooltip("Launch player's vehicle upward"))
    
    -- Slingshot vehicle
    self:AddOption(ButtonOption.new("Slingshot vehicle")
        :AddFunction(SlingshotVehicle)
        :AddTooltip("Fling player's vehicle"))
    
    -- Boost vehicle
    self:AddOption(ButtonOption.new("Boost vehicle")
        :AddFunction(BoostVehicle)
        :AddTooltip("Set player's vehicle forward speed"))
    
    -- Stop vehicle
    self:AddOption(ButtonOption.new("Stop vehicle")
        :AddFunction(StopVehicle)
        :AddTooltip("Stop player's vehicle"))
    
    -- Freeze vehicle toggle
    self:AddOption(ToggleOption.new("Freeze vehicle", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerState(playerId)
            state.freezeVehicle = value
            FreezeVehicle(value)
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerState(playerId)
            return state.freezeVehicle
        end
        return false
    end)
        :AddTooltip("Freeze player's vehicle in place"))
    
    -- Rotate vehicle
    self:AddOption(ButtonOption.new("Rotate vehicle")
        :AddFunction(RotateVehicle)
        :AddTooltip("Flip player's vehicle upside down"))
    
    -- Trolling section
    self:AddOption(BreakOption.new("Trolling"))
    
    -- Kill engine
    self:AddOption(ButtonOption.new("Kill engine")
        :AddFunction(KillEngine)
        :AddTooltip("Kill player's vehicle engine"))
    
    -- Revive engine
    self:AddOption(ButtonOption.new("Revive engine")
        :AddFunction(ReviveEngine)
        :AddTooltip("Revive player's vehicle engine"))
    
    -- Kick from vehicle loop toggle (using Cherax built-in)
    self:AddOption(ToggleOption.new("Kick from vehicle loop", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerState(playerId)
            state.kickLoop = value
            
            local feature = FeatureMgr.GetFeatureByName("Loop Vehicle Kick", playerId)
            if feature then
                feature:SetValue(value):TriggerCallback()
            end
            
            if value then
                Renderer.Notify("Kicking " .. GetSelectedPlayerName() .. " from vehicles")
            else
                Renderer.Notify("Stopped kicking " .. GetSelectedPlayerName() .. " from vehicles")
            end
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerState(playerId)
            return state.kickLoop
        end
        return false
    end)
        :AddTooltip("Continuously kick player from vehicles"))
    
    -- Delete vehicle
    self:AddOption(ButtonOption.new("Delete vehicle")
        :AddFunction(DeleteVehicle)
        :AddTooltip("Delete player's vehicle"))
    
    -- Burst tires
    self:AddOption(ButtonOption.new("Burst tires")
        :AddFunction(BurstTires)
        :AddTooltip("Burst player's vehicle tires"))
    
    -- Lock doors
    self:AddOption(ButtonOption.new("Lock doors")
        :AddFunction(function() LockDoors(true) end)
        :AddTooltip("Lock player's vehicle doors"))
    
    -- Unlock doors
    self:AddOption(ButtonOption.new("Unlock doors")
        :AddFunction(function() LockDoors(false) end)
        :AddTooltip("Unlock player's vehicle doors"))
    
    -- Vehicle Modifications section
    self:AddOption(BreakOption.new("Vehicle Modifications"))
    
    -- Repair vehicle
    self:AddOption(ButtonOption.new("Repair vehicle")
        :AddFunction(RepairVehicle)
        :AddTooltip("Repair player's vehicle"))
    
    -- Fully tune vehicle
    self:AddOption(ButtonOption.new("Fully tune vehicle")
        :AddFunction(TuneVehicle)
        :AddTooltip("Max out all vehicle mods"))
    
    -- Vehicle Acrobatics section
    self:AddOption(BreakOption.new("Vehicle Acrobatics"))
    
    -- Front flip
    self:AddOption(ButtonOption.new("Front flip")
        :AddFunction(FrontFlip)
        :AddTooltip("Do a front flip"))
    
    -- Back flip
    self:AddOption(ButtonOption.new("Back flip")
        :AddFunction(BackFlip)
        :AddTooltip("Do a back flip"))
    
    -- Kick flip
    self:AddOption(ButtonOption.new("Kick flip")
        :AddFunction(KickFlip)
        :AddTooltip("Do a kick flip"))
    
    -- Heel flip
    self:AddOption(ButtonOption.new("Heel flip")
        :AddFunction(HeelFlip)
        :AddTooltip("Do a heel flip"))
    
    -- Bunny hop
    self:AddOption(ButtonOption.new("Bunny hop")
        :AddFunction(BunnyHop)
        :AddTooltip("Do a bunny hop"))
    
    -- Slingshot (acrobatics version)
    self:AddOption(ButtonOption.new("Slingshot")
        :AddFunction(SlingshotVehicle)
        :AddTooltip("Fling player's vehicle"))
end

function PlayerVehicleMenu:FeatureUpdate()
    HornBoostUpdate()
    FreezeVehicleUpdate()
end

return PlayerVehicleMenu
