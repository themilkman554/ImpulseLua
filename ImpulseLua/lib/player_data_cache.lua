--[[
    Impulse Lua - Player Data Cache
    Caches information received from network sync nodes
]]

local PlayerDataCache = {}
PlayerDataCache.players = {}

--- Get rank for a player
---@param playerID number Player ID
---@return string Rank as string or placeholder
function PlayerDataCache.GetRank(playerID)
    if not PlayerDataCache.players[playerID] then
        return "~c~Unknown~s~"
    end
    return tostring(PlayerDataCache.players[playerID].rank or "~c~Unknown~s~")
end

--- Get passive status for a player
---@param playerID number Player ID
---@return boolean
function PlayerDataCache.IsPassive(playerID)
    if not PlayerDataCache.players[playerID] then
        return false
    end
    return PlayerDataCache.players[playerID].isPassive or false
end

-- Helper to update player data
local function UpdatePlayerData(playerID, node)
    if not playerID or playerID == -1 then return end
    
    -- Initialize player entry if not exists
    if not PlayerDataCache.players[playerID] then
        PlayerDataCache.players[playerID] = {}
    end
    
    local pData = PlayerDataCache.players[playerID]

    -- Character Rank
    if node.nCharacterRank then
        pData.rank = node.nCharacterRank
    end

    -- Passive Mode
    if node.bIsPassiveMode ~= nil then
        pData.isPassive = node.bIsPassiveMode
    end
end

-- 1. Using CAN_APPLY_NODE_DATA (More reliable for remote players according to example)
EventMgr.RegisterHandler(eLuaEvent.CAN_APPLY_NODE_DATA, function(isCreate, modelHash, position, netObject, updatedNodes)
    local playerID = netObject and netObject.PlayerId or -1
    if playerID == -1 then return true end

    for _, node in ipairs(updatedNodes) do
        -- Use GetNodeName() to avoid "integer value will be misrepresented" error with 64-bit hashes
        if node:GetNodeName() == "CPlayerGameStateDataNode" then
            local pNode = node:As("CPlayerGameStateDataNode")
            if pNode then
                UpdatePlayerData(playerID, pNode)
            end
        end
    end
    return true
end)

-- 2. Keep ON_SYNC_DATA_NODE but fix owner resolution
EventMgr.RegisterHandler(eLuaEvent.ON_SYNC_DATA_NODE, function(nodeType, node, pEntity, isExclusive, playerID)
    -- If playerID is -1, try to resolve via entity
    if playerID == -1 and pEntity then
        local netObj = pEntity.NetObject
        if netObj then
            playerID = netObj.PlayerId
        end
    end

    -- Compare nodeType against hash
    -- We revert to nodeType comparison here because 'node' is a direct pointer in this event
    if nodeType == eSyncDataNode.CPlayerGameStateDataNode then
        UpdatePlayerData(playerID, node)
    end
end)

-- Clear data when player leaves
EventMgr.RegisterHandler(eLuaEvent.ON_PLAYER_LEFT, function(playerID)
    PlayerDataCache.players[playerID] = nil
end)

return PlayerDataCache
