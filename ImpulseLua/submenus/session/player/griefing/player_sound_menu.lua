--[[
    Impulse Lua - Player Sound Menu
    Sound options for selected player
    Port of soundMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local PlayerMenu = nil -- Lazy loaded

local PlayerSoundMenu = setmetatable({}, { __index = Submenu })
PlayerSoundMenu.__index = PlayerSoundMenu

local instance = nil

-- State
local soundState = {
    soundCounter = 0,
    earrape = false
}

local PlaySounds = {
    { name = "Orbital Cannon", sound = "DLC_XM_Explosions_Orbital_Cannon", set = "" },
    { name = "Beep", sound = "Hack_Success", set = "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS" },
    { name = "Alien", sound = "SPAWN", set = "BARRY_01_SOUNDSET" },
    { name = "Endless Beep", sound = "CONTINUAL_BEEP", set = "EPSILONISM_04_SOUNDSET" },
    { name = "Short Beep", sound = "IDLE_BEEP", set = "EPSILONISM_04_SOUNDSET" },
    { name = "Ring tone 1", sound = "Remote_Ring", set = "Phone_SoundSet_Michael" },
    { name = "Ring tone 2", sound = "PED_PHONE_DIAL_01", set = "" },
    { name = "Whistle", sound = "Franklin_Whistle_For_Chop", set = "SPEECH_RELATED_SOUNDS" },
    { name = "EMP", sound = "EMP_Vehicle_Hum", set = "DLC_HEIST_BIOLAB_DELIVER_EMP_SOUNDS" },
    { name = "Helicopter", sound = "Helicopter_Wind", set = "BASEJUMPS_SOUNDS" },
    { name = "Key card 1", sound = "Keycard_Success", set = "DLC_HEISTS_BIOLAB_FINALE_SOUNDS" },
    { name = "Key card 2", sound = "Keycard_Fail", set = "DLC_HEISTS_BIOLAB_FINALE_SOUNDS" },
    { name = "Scan", sound = "SCAN", set = "EPSILONISM_04_SOUNDSET" },
    { name = "Leaf blower", sound = "GARDENING_LEAFBLOWER_ANIM_TRIGGERED", set = "" },
    { name = "Carwash 1", sound = "SPRAY", set = "CARWASH_SOUNDS" },
    { name = "Carwash 2", sound = "SPRAY_CAR", set = "CARWASH_SOUNDS" },
    { name = "Carwash 3", sound = "DRYER", set = "CARWASH_SOUNDS" },
    { name = "Unlock", sound = "Bar_Unlock_And_Raise", set = "DLC_IND_ROLLERCOASTER_SOUNDS" },
    { name = "Brakes", sound = "MOD_SHOP_BRAKES_ONESHOT", set = "" },
    { name = "Yacht Arrive Horn", sound = "Arrive_Horn", set = "DLC_Apartment_Yacht_Streams_Soundset" },
    { name = "Darts Bullseye", sound = "DARTS_HIT_BULLSEYE_MASTER", set = "" },
    { name = "Yacht Horn", sound = "Horn", set = "DLC_Apt_Yacht_Ambient_Soundset" },
    { name = "Jet Explosions", sound = "Jet_Explosions", set = "exile_1" },
    { name = "Alarm", sound = "ALARMS_KLAXON_03_CLOSE", set = "" },
    { name = "Train Bell", sound = "Train_Bell", set = "Prologue_Sounds" },
    { name = "Long Scream", sound = "TEST_SCREAM_LONG", set = "" },
    { name = "Short Scream", sound = "TEST_SCREAM_SHORT", set = "" },
    { name = "Jet Engine", sound = "Trevor_4_747_Jet_Engine", set = "" }
}

-- Helpers
local function GetSelectedPlayerId()
    if not PlayerMenu then
        PlayerMenu = require("Impulse/ImpulseLua/submenus/session/player_menu")
    end
    return PlayerMenu.targetPlayer or -1
end

local function GetSelectedPlayerCoords()
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then return {x=0, y=0, z=0} end
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if ped and ENTITY.DOES_ENTITY_EXIST(ped) then
        return ENTITY.GET_ENTITY_COORDS(ped, true)
    end
    return {x=0, y=0, z=0}
end

local function GetSelectedPlayerName()
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then return "Unknown" end
    return PLAYER.GET_PLAYER_NAME(playerId) or "Unknown"
end

local function PlayTheSound(index)
    local data = PlaySounds[index]
    if not data then return end
    
    local coords = GetSelectedPlayerCoords()
    -- PlaySoundFromCoord(soundId, audioName, x, y, z, audioRef, isNetwork, range, p8)
    local soundId = AUDIO.GET_SOUND_ID()
    AUDIO.PLAY_SOUND_FROM_COORD(soundId, data.sound, coords.x, coords.y, coords.z, data.set == "" and 0 or data.set, true, 0, true)
    soundState.soundCounter = soundState.soundCounter + 1
    
    -- We need to track soundIds if we want to stop them, but Lua generic implementation might differ slightly
    -- For now just fire and forget like the C++, relies on StopSounds killing all soundIds or similar mechanism
    -- NOTE: C++ stops sounds by ID from 0 to soundCounter. In Lua we probably need to store IDs.
end

local activeSoundIds = {}

local function PlaySoundSafe(index)
    local data = PlaySounds[index]
    if not data then return end
    
    local coords = GetSelectedPlayerCoords()
    local soundId = AUDIO.GET_SOUND_ID()
    
    -- Use 0 for nil string equivalent in native call if needed, or just pass nil/string
    local setName = data.set
    if setName == "" then setName = nil end
    
    AUDIO.PLAY_SOUND_FROM_COORD(soundId, data.sound, coords.x, coords.y, coords.z, setName, true, 0, true)
    table.insert(activeSoundIds, soundId)
    Renderer.Notify("Playing " .. data.name)
end

local function StopSounds()
    for _, soundId in ipairs(activeSoundIds) do
        AUDIO.STOP_SOUND(soundId)
        AUDIO.RELEASE_SOUND_ID(soundId)
    end
    activeSoundIds = {}
    Renderer.Notify("Stopped all sounds")
end

-- Menu Definition
function PlayerSoundMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Sounds"), PlayerSoundMenu)
        instance:Init()
    end
    return instance
end

function PlayerSoundMenu:Init()
    -- Stop sounds
    self:AddOption(ButtonOption.new("Stop sounds")
        :AddFunction(StopSounds)
        :AddTooltip("Stop all currently playing sounds")
        :AddHotkey())

    -- Sound rape
    self:AddOption(ToggleOption.new("Sound rape")
        :AddToggleRef(soundState, "earrape")
        :AddTooltip("This will spam the player with explosive sounds")
        :AddHotkey())

    self:AddOption(BreakOption.new("Sound List"))

    -- List of sounds
    for i, soundData in ipairs(PlaySounds) do
        self:AddOption(ButtonOption.new(soundData.name)
            :AddFunction(function() PlaySoundSafe(i) end)
            :AddHotkey())
    end
end

-- Background loop for "Sound rape"
Script.RegisterLooped(function()
    if soundState.earrape then
        local coords = GetSelectedPlayerCoords()
        AUDIO.PLAY_SOUND_FROM_COORD(-1, "DLC_XM_Explosions_Orbital_Cannon", coords.x, coords.y, coords.z, 0, true, 0, false)
        Script.Yield(100)
    else
        Script.Yield(500)
    end
end)

return PlayerSoundMenu
