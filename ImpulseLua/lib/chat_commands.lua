--[[
    Impulse Lua - Chat Commands Library
    Handles parsing and execution of chat commands
]]

local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local Utils = require("Impulse/ImpulseLua/lib/utils")
local PlayerDataCache = require("Impulse/ImpulseLua/lib/player_data_cache")

local ChatCommands = {}
local instance = nil

-- Command permissions per player
local playerPermissions = {}

-- Global session permissions (from AllPlayersMenu)
local globalPermissions = {
    m_chatCommand = false, -- Master switch for lobby
    m_chatCommandMoneyDrop = false,
    m_chatCommandSpawnVehicle = false,
    m_chatCommandSpawnPed = false,
    m_chatCommandSpawnObject = false,
    m_chatCommandSpawnBodyguard = false,
    m_chatCommandGiveWeapons = false,
    m_chatCommandExplodeSession = false,
    m_chatCommandVehicleRepair = false,
    m_chatCommandVehicleBoost = false,
    m_chatCommandVehicleJump = false,
    m_chatCommandVehicleUpgrade = false,
    m_chatCommandGlobalsCopsturnblind = false,
    m_chatCommandGlobalsOfftheradar = false,
}

--- Initialize permissions for a player
---@param playerId number
local function InitPlayerPermissions(playerId)
    if not playerPermissions[playerId] then
        playerPermissions[playerId] = {
            m_chatCommand = false,
            m_chatCommandMoneyDrop = false,
            m_chatCommandSpawnVehicle = false,
            m_chatCommandSpawnPed = false,
            m_chatCommandSpawnObject = false,
            m_chatCommandSpawnBodyguard = false,
            m_chatCommandGiveWeapons = false,
            m_chatCommandExplodeSession = false,
            m_chatCommandVehicleRepair = false,
            m_chatCommandVehicleBoost = false,
            m_chatCommandVehicleJump = false,
            m_chatCommandVehicleUpgrade = false,
            m_chatCommandGlobalsCopsturnblind = false,
            m_chatCommandGlobalsOfftheradar = false,
        }
    end
end

--- Get permissions for a player
---@param playerId number
---@return table
function ChatCommands.GetPermissions(playerId)
    InitPlayerPermissions(playerId)
    return playerPermissions[playerId]
end

--- Get global permissions
---@return table
function ChatCommands.GetGlobalPermissions()
    return globalPermissions
end

--- Set global permission (called from AllPlayersMenu)
---@param key string
---@param value boolean
function ChatCommands.SetGlobalPermission(key, value)
    globalPermissions[key] = value
end

--- Toggle all permissions for a player
---@param playerId number
---@param state boolean
function ChatCommands.ToggleAll(playerId, state)
    InitPlayerPermissions(playerId)
    local perms = playerPermissions[playerId]
    for k, v in pairs(perms) do
        perms[k] = state
    end
end

local function GetHash(modelName)
    if Utils and Utils.Joaat then
        return Utils.Joaat(modelName)
    else
        return MISC.GET_HASH_KEY(modelName)
    end
end
--- Toggle all global permissions
---@param state boolean
function ChatCommands.ToggleAllGlobal(state)
    for k, v in pairs(globalPermissions) do
        globalPermissions[k] = state
    end
end

--- Handle chat command logic
---@param playerId number
---@param message string
local function HandleCommand(playerId, message)

    -- Helper to check permission
    local function HasPerm(permName)
        -- Always allow local player
        if playerId == GTA.GetLocalPlayerId() then
            return true
        end

        InitPlayerPermissions(playerId)
        local playerAllowed = playerPermissions[playerId].m_chatCommand and playerPermissions[playerId][permName]
        local globalAllowed = globalPermissions.m_chatCommand and globalPermissions[permName]
        
        return playerAllowed or globalAllowed
    end
    
    -- Basic tokenization
    local tokens = {}
    for token in string.gmatch(message, "%S+") do
        table.insert(tokens, token)
    end
    
    if #tokens == 0 then return end
    
    local cmd = tokens[1]:lower()
    local playerName = PLAYER.GET_PLAYER_NAME(playerId) or "Unknown"

    if not ChatCommands.lastProcessed then ChatCommands.lastProcessed = {} end
    local last = ChatCommands.lastProcessed[playerId]
    
    local now = os.clock()
    if last and last.cmd == message and (now - last.time) < 0.5 then
        return
    end
    ChatCommands.lastProcessed[playerId] = { cmd = message, time = now }

    local commandList = "Cmds: !spawn vehicle/ped/object/bodyguard, !weapons, !explodesession, !vehicle repair/boost/jump/upgrade, !copsturnblind, !offtheradar"

    -- !help
    if cmd == "!help" then
        Renderer.NotifyMapColor(string.format("Chat Commands\nSending Help\nTo: %s", playerName), 18)
        -- Send private message to sender
        GTA.SendChatMessageToPlayer(playerId, commandList, false)
        return
    end

    -- !spawn commands
    if cmd == "!spawn" and #tokens >= 2 then
        local type = tokens[2]:lower()
        
        if type == "vehicle" then
             if HasPerm("m_chatCommandSpawnVehicle") then
                if #tokens > 2 then
                    local modelName = tokens[3]
                    local hash = GetHash(modelName)
                    
                if STREAMING.IS_MODEL_IN_CDIMAGE(hash) and STREAMING.IS_MODEL_A_VEHICLE(hash) then
                        Renderer.NotifyMapColor(string.format("Chat Commands\nSpawn Vehicle\nFrom: %s", playerName), 18)
                        STREAMING.REQUEST_MODEL(hash)
                        local timeout = 0
                        while not STREAMING.HAS_MODEL_LOADED(hash) and timeout < 1000 do
                            Script.Yield(0)
                            timeout = timeout + 1
                        end

                        if STREAMING.HAS_MODEL_LOADED(hash) then
                            -- Use Cherax API: GTA.SpawnVehicleForPlayer(hash, player, forward)
                            local veh = GTA.SpawnVehicleForPlayer(hash, playerId, 5.0)
                            
                            if veh and veh ~= 0 then
                                -- Basic setup (API might do some, but extra safety doesn't hurt)
                                VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(veh, 5.0)
                                ENTITY.SET_ENTITY_AS_MISSION_ENTITY(veh, true, true)
                            end
                            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
                        end
                    end
                end
             end
        elseif type == "ped" and HasPerm("m_chatCommandSpawnPed") then
            if #tokens > 2 then
                local modelName = tokens[3]
                local hash = GetHash(modelName)
                if STREAMING.IS_MODEL_IN_CDIMAGE(hash) then
                    Renderer.NotifyMapColor(string.format("Chat Commands\nSpawn Ped\nFrom: %s", playerName), 18)
                    
                    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
                    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
                    local heading = ENTITY.GET_ENTITY_HEADING(ped)
                    
                    STREAMING.REQUEST_MODEL(hash)
                    local timeout = 0
                    while not STREAMING.HAS_MODEL_LOADED(hash) and timeout < 1000 do
                        Script.Yield(0)
                        timeout = timeout + 1
                    end
                    
                    if STREAMING.HAS_MODEL_LOADED(hash) then
                         GTA.CreatePed(hash, 26, coords.x, coords.y, coords.z, heading, true, false)
                         STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
                    end
                end
            end
        elseif type == "object" and HasPerm("m_chatCommandSpawnObject") then
             if #tokens > 2 then
                local modelName = tokens[3]
                local hash = GetHash(modelName)
                 if STREAMING.IS_MODEL_IN_CDIMAGE(hash) then
                    Renderer.NotifyMapColor(string.format("Chat Commands\nSpawn Object\nFrom: %s", playerName), 18)
                    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
                    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
                    
                    STREAMING.REQUEST_MODEL(hash)
                    local timeout = 0
                    while not STREAMING.HAS_MODEL_LOADED(hash) and timeout < 1000 do
                        Script.Yield(0)
                        timeout = timeout + 1
                    end
                    
                    if STREAMING.HAS_MODEL_LOADED(hash) then
                        -- Use Cherax API: GTA.CreateObject(hash, x, y, z, dynamic, isNetworked)
                        GTA.CreateObject(hash, coords.x, coords.y, coords.z, true, false)
                        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
                    end
                end
             end
        elseif type == "bodyguard" and HasPerm("m_chatCommandSpawnBodyguard") then
            Renderer.NotifyMapColor(string.format("Chat Commands\nSpawn Bodyguard\nFrom: %s", playerName), 18)
            local count = 1
            if #tokens > 2 then
                count = tonumber(tokens[3]) or 1
            end
            if count > 10 then count = 10 end
            
            -- We can reuse the logic from PlayerPeacefulMenu if exposed, or replicate it.
            -- Replicating simplified version for self-contained lib.
            local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
            local myGroup = PLAYER.GET_PLAYER_GROUP(playerId)
            local railgun = GetHash("WEAPON_RAILGUN")
            
            for i=1, count do
                local heading = ENTITY.GET_ENTITY_HEADING(playerPed)
                local clone = PED.CLONE_PED(playerPed, heading, true, false)
                if clone ~= 0 then
                    PED.SET_PED_AS_GROUP_LEADER(playerPed, myGroup)
                    PED.SET_PED_AS_GROUP_MEMBER(clone, myGroup)
                    WEAPON.GIVE_WEAPON_TO_PED(clone, railgun, 9999, false, true)
                end
            end
        end
    end

    -- !weapons
    if cmd == "!weapons" and HasPerm("m_chatCommandGiveWeapons") then
        Renderer.NotifyMapColor(string.format("Chat Commands\nGiving Weapons\nFrom: %s", playerName), 18)
        FeatureState.Trigger("Give All Weapons", playerId)
    end

    -- !explodesession
    if cmd == "!explodesession" and HasPerm("m_chatCommandExplodeSession") then
        Renderer.NotifyMapColor(string.format("Chat Commands\nExploding Session\nFrom: %s", playerName), 18)
        local players = Utils.GetPlayers() 
        for i = 0, 31 do
            if NETWORK.NETWORK_IS_PLAYER_ACTIVE(i) then
                local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(i)
                local coords = ENTITY.GET_ENTITY_COORDS(targetPed, true)
                FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 2, 1000.0, true, false, 0.0)
            end
        end
    end
    
    -- !vehicle
    if cmd == "!vehicle" and #tokens >= 2 then
        local type = tokens[2]:lower()
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        
        if vehicle ~= 0 then
            if type == "repair" and HasPerm("m_chatCommandVehicleRepair") then
                Renderer.NotifyMapColor(string.format("Chat Commands\nVehicle Repair\nFrom: %s", playerName), 18)
                VEHICLE.SET_VEHICLE_FIXED(vehicle)
            elseif type == "boost" and HasPerm("m_chatCommandVehicleBoost") then
                Renderer.NotifyMapColor(string.format("Chat Commands\nVehicle Boost\nFrom: %s", playerName), 18)
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 100.0)
            elseif type == "jump" and HasPerm("m_chatCommandVehicleJump") then
                Renderer.NotifyMapColor(string.format("Chat Commands\nVehicle Jump\nFrom: %s", playerName), 18)
                ENTITY.APPLY_FORCE_TO_ENTITY(vehicle, 1, 0.0, 0.0, 20.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
            elseif type == "upgrade" and HasPerm("m_chatCommandVehicleUpgrade") then
                Renderer.NotifyMapColor(string.format("Chat Commands\nVehicle Upgrade\nFrom: %s", playerName), 18)
                -- Apply max mods
                VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
                for i = 0, 49 do
                    local count = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i)
                    if count > 0 then
                         VEHICLE.SET_VEHICLE_MOD(vehicle, i, count - 1, false)
                    end
                end
            end
        end
    end

    -- !copsturnblind
    if cmd == "!copsturnblind" and #tokens >= 2 and HasPerm("m_chatCommandGlobalsCopsturnblind") then
        local state = tokens[2]:lower()
        if state == "on" then
            Renderer.NotifyMapColor(string.format("Chat Commands\nCopsTurnBlindEye: On\nFrom: %s", playerName), 18)
            -- Logic to enable for player? 
            -- C++ code just sets a flag `player.m_blindEye = true`. 
            -- We might need a looped feature to enforce this.
            -- For now, just notifying.
        elseif state == "off" then
            Renderer.NotifyMapColor(string.format("Chat Commands\nCopsTurnBlindEye: Off\nFrom: %s", playerName), 18)
        end
    end

    -- !offtheradar
    if cmd == "!offtheradar" and #tokens >= 2 and HasPerm("m_chatCommandGlobalsOfftheradar") then
        local state = tokens[2]:lower()
        if state == "on" then
            Renderer.NotifyMapColor(string.format("Chat Commands\nOffTheRadar: On\nFrom: %s", playerName), 18)
        elseif state == "off" then
            Renderer.NotifyMapColor(string.format("Chat Commands\nOffTheRadar: Off\nFrom: %s", playerName), 18)
        end
    end
end


--- Initialize the chat command system
function ChatCommands.Init()
    if instance then return end
    
    -- Force defaults to OFF
    for k, v in pairs(globalPermissions) do
        globalPermissions[k] = false
    end
    
    instance = true
    
    -- Register Event Handler
    local eventId = EventMgr.RegisterHandler(eLuaEvent.ON_CHAT_MESSAGE, function(sender, message, isTeam)
        
        local pid = -1
        
        if type(sender) == "number" then
            pid = sender
        elseif type(sender) == "userdata" or type(sender) == "table" then
            -- Try common methods/properties
            if sender.GetPlayerId then
                pid = sender:GetPlayerId()
            elseif sender.PlayerId then
                 pid = sender.PlayerId
            elseif sender.GetId then
                 pid = sender:GetId()
            elseif sender.Id then
                 pid = sender.Id
            end
        end

        if pid ~= -1 and type(message) == "string" then
            if message:sub(1, 1) == "!" then
                -- Run in separate thread/queu to avoid blocking event handler
                Script.QueueJob(function()
                     HandleCommand(pid, message)
                end)
            end
        end
    end)
    
    -- Store event ID if we need to unregister later (not implemented for now)
end

return ChatCommands
