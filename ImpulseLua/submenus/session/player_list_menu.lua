--[[
    Impulse Lua - Player List Menu
    Dynamic player list with sorting
    Port of playerListMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local PlayerInfoComponent = require("Impulse/ImpulseLua/lib/ui/player_info_component")
local PlayerDataCache = require("Impulse/ImpulseLua/lib/player_data_cache")

local PlayerListMenu = setmetatable({}, { __index = Submenu })
PlayerListMenu.__index = PlayerListMenu

local instance = nil

-- Current selected player
PlayerListMenu.selectedPlayer = -1

-- Headshot handles cache
local headshotHandles = {}

-- Sort state
local sortState = {
    sortIndex = 1
}

-- Auto spectate state
local autoSpectateState = {
    index = 1 -- 1: None, 2: On Enter, 3: On Hover
}
local autoSpectateOptions = {
    "None",
    "On Enter",
    "On Hover"
}

-- Sort options matching C++ and ePlayerListSort API
-- PLAYER_ID, DISTANCE, ALPHABETICAL, HOST_QUEUE are supported by API
-- MONEY requires manual sorting
local sortOptionNames = {
    "Player ID",
    "Distance", 
    "Alphabetical",
    "Host Queue",
    "Money"
}

function PlayerListMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Players"), PlayerListMenu)
        instance:Init()
    end
    return instance
end

--- Register a headshot for a player
---@param playerId number
---@return number headshot handle
local function RegisterHeadshot(playerId)
    if headshotHandles[playerId] then
        return headshotHandles[playerId]
    end
    
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if ped and ENTITY.DOES_ENTITY_EXIST(ped) then
        local handle = PED.REGISTER_PEDHEADSHOT(ped)
        headshotHandles[playerId] = handle
        return handle
    end
    return 0
end

--- Get player display name with status tags
---@param playerId number
---@param tags string|nil Raw tags from Players.GetTags
---@return string
local function GetPlayerDisplayName(playerId, tags)
    local Translation = require("Impulse/ImpulseLua/lib/translation")
    
    local success, name = pcall(function()
        return PLAYER.GET_PLAYER_NAME(playerId)
    end)
    if not success or not name then 
        return "Player " .. tostring(playerId)
    end
    
    local displayTags = ""
    
    -- Modder detection via [M] tag (purple like C++)
    if tags and string.find(tags, "%[M%]") then
        displayTags = displayTags .. " ~q~" .. Translation.GetFlat("[MOD]") .. "~s~"
    end
    
    -- Interior detection via [I] tag (green like C++)
    if tags and string.find(tags, "%[I%]") then
        displayTags = displayTags .. " ~g~" .. Translation.GetFlat("[INT]") .. "~s~"
    end
    
    -- Godmode detection via [G] tag (red like C++)
    if tags and string.find(tags, "%[G%]") then
        displayTags = displayTags .. " ~r~" .. Translation.GetFlat("[GOD]") .. "~s~"
    end
    
    -- Host detection (combined if both, otherwise individual)
    local hasSessionHost = tags and string.find(tags, "%[H%]")
    local hasScriptHost = tags and string.find(tags, "%[SH%]")
    
    if hasSessionHost and hasScriptHost then
        displayTags = displayTags .. " ~y~" .. Translation.GetFlat("[Script/Session Host]") .. "~s~"
    elseif hasSessionHost then
        displayTags = displayTags .. " ~y~" .. Translation.GetFlat("[Session Host]") .. "~s~"
    elseif hasScriptHost then
        displayTags = displayTags .. " ~y~" .. Translation.GetFlat("[Script Host]") .. "~s~"
    end
    
    -- Friend detection via [F] tag (yellow like C++)
    if tags and string.find(tags, "%[F%]") then
        displayTags = displayTags .. " ~y~" .. Translation.GetFlat("[F]") .. "~s~"
    end
    
    -- Self detection via [Y] tag (yellow like C++)
    if tags and string.find(tags, "%[Y%]") then
        displayTags = displayTags .. " ~y~" .. Translation.GetFlat("[SELF]") .. "~s~"
    end

    -- Cutscene detection
    if playerId ~= PLAYER.PLAYER_ID() and NETWORK.NETWORK_IS_PLAYER_IN_MP_CUTSCENE(playerId) then
        displayTags = displayTags .. " ~c~" .. Translation.GetFlat("[CUTSCENE]") .. "~s~"
    end
    
    -- Passive detection
    if PlayerDataCache.IsPassive(playerId) then
        displayTags = displayTags .. " ~b~" .. Translation.GetFlat("[PASSIVE]") .. "~s~"
    end
    
    return name .. displayTags
end

--- Get sort enum value
--- Maps local index to ePlayerListSort
--- Returns nil for manual sorts (like Money)
local function GetSortEnum(index)
    if not ePlayerListSort then
        return 0 -- Default to PLAYER_ID
    end
    
    -- Map indices to ePlayerListSort values
    -- 1=Player ID, 2=Distance, 3=Alphabetical, 4=Host Queue, 5=Money (manual)
    local enums = {
        [1] = ePlayerListSort.PLAYER_ID,
        [2] = ePlayerListSort.DISTANCE,
        [3] = ePlayerListSort.ALPHABETICAL,
        [4] = ePlayerListSort.HOST_QUEUE,
        [5] = nil  -- Money sorting done manually
    }
    return enums[index]
end

--- Get player money value for sorting
--- Uses script globals to retrieve player balance
local function GetPlayerMoney(playerId)
    -- These globals are the same as used in playerInfoComponent.cpp
    -- PLAYER_BASE, PLAYER_PADDING, PLAYER_OFFSET, PLAYER_OFFSET_WALLET, PLAYER_OFFSET_TOTAL
    local success, total = pcall(function()
        -- Try to get bank + cash total
        local gamerInfo = nil
        if Players.GetById(playerId) then
            gamerInfo = Players.GetById(playerId):GetGamerInfo()
        end
        if gamerInfo and gamerInfo.Wallet then
            return gamerInfo.Wallet + (gamerInfo.Bank or 0)
        end
        return 0
    end)
    return success and total or 0
end

--- Create headshot draw callback for a player
---@param playerId number
---@return function
local function CreateHeadshotDrawer(playerId)
    return function(position)
        if not NETWORK.NETWORK_IS_SESSION_ACTIVE() then
            return 0
        end
        
        local handle = headshotHandles[playerId]
        if not handle or handle == 0 then
            return 0
        end
        
        -- Check if headshot is ready
        if not PED.IS_PEDHEADSHOT_VALID(handle) then
            return 0
        end
        
        -- Get texture name
        local texture = PED.GET_PEDHEADSHOT_TXD_STRING(handle)
        if not texture or texture == "" then
            return 0
        end
        
        -- Draw headshot sprite
        local x = Renderer.Layout.posX - Renderer.Layout.width / 2 + 0.015
        local y = Renderer.GetOptionY(position) + Renderer.Layout.optionHeight / 2
        local width = 0.015
        local height = 0.025
        
        GRAPHICS.DRAW_SPRITE(texture, texture, x, y, width, height, 0.0, 255, 255, 255, 210, false, 0)
        
        return width + 0.005 -- Return offset for text
    end
end

function PlayerListMenu:Init()
    -- Build sort options for scroll
    local scrollItems = {}
    for i, name in ipairs(sortOptionNames) do
        scrollItems[i] = { name = name, value = i }
    end
    
    -- Sort option
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Sort By")
        :AddScroll(scrollItems, 1)
        :AddIndexRef(sortState, "sortIndex")
        :CanLoop()
        :AddTooltip("Sort the player list"))

    -- Auto Spectate option
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Auto Spectate")
        :AddScroll(autoSpectateOptions, 1)
        :AddIndexRef(autoSpectateState, "index")
        :CanLoop()
        :AddTooltip("Automatically spectate players"))
        :SetDonor()
    -- Break option
    self:AddOption(BreakOption.new("Players"))
    
    -- Initialize timer for updates
    self.lastUpdateTime = 0
    self.updateInterval = 250
end

--- Auto-update function called by menu system when this submenu is active
function PlayerListMenu:Update()
    local currentTime = MISC.GET_GAME_TIMER()
    
    -- Exact 250ms delay check
    if currentTime - self.lastUpdateTime > self.updateInterval then
        self.lastUpdateTime = currentTime
        self:RefreshPlayers()
    end
    
    -- Update player info component based on current selection
    local Menu = require("Impulse/ImpulseLua/lib/menu")
    local currentOption = Menu.currentOption
    
    -- Options start at index 4 (after sort, auto spectate and break options)
    if currentOption >= 4 and self.playerIdMap and self.playerIdMap[currentOption] then
        local hoveredPlayerId = self.playerIdMap[currentOption]
        
        -- Auto Spectate: On Hover
        if autoSpectateState.index == 3 then -- On Hover
            if self.lastHoveredPlayer ~= hoveredPlayerId then
                 -- Trigger spectate for the new player
                 local feature = FeatureMgr.GetFeatureByName("Spectate Player", hoveredPlayerId)
                 if feature then
                     feature:SetValue(true):TriggerCallback()
                 end
                 self.lastHoveredPlayer = hoveredPlayerId
            end
        end

        PlayerInfoComponent.SetPlayer(hoveredPlayerId)
        self.selectedPlayer = hoveredPlayerId
    else
        PlayerInfoComponent.SetPlayer(-1)
        self.lastHoveredPlayer = nil
    end
end

--- Custom render that also draws player info panel
function PlayerListMenu:CustomRender()
    -- Render the player info component
    PlayerInfoComponent.Render()
end

--- Refresh the player list logic
function PlayerListMenu:RefreshPlayers()
    -- Clear old player options (keep first 3: sort, auto spectate, break)
    while #self.options > 3 do
        table.remove(self.options)
    end
    
    -- Check API
    if not Players or not Players.Get then
        self:AddOption(ButtonOption.new("~r~Players API not available~s~"):AddFunction(function() end))
        return 
    end
    
    -- Get sort type
    local sortEnum = GetSortEnum(sortState.sortIndex)
    local isManualSort = (sortEnum == nil)  -- Money sort
    
    -- Get players using Cherax API
    local success, players = pcall(function()
        if isManualSort then
            -- For manual sorts, get default order first
            return Players.Get(ePlayerListSort and ePlayerListSort.PLAYER_ID or 0, "")
        else
            return Players.Get(sortEnum, "")
        end
    end)
    
    if not success then
        self:AddOption(ButtonOption.new("~r~Failed to get players~s~"):AddFunction(function() end))
        return
    end
    
    -- Manual Money Sort
    if isManualSort and sortState.sortIndex == 5 and players then
        local playerList = {}
        for _, pid in pairs(players) do
            table.insert(playerList, { id = pid, money = GetPlayerMoney(pid) })
        end
        table.sort(playerList, function(a, b) return a.money > b.money end)
        players = {}
        for i, p in ipairs(playerList) do
            players[i] = p.id
        end
    end
    
    if players then
        local currentSessionPlayers = {}
        
        -- Reset player ID map
        self.playerIdMap = {}
        local optionIndex = 4  -- Options start at 4 (after sort, auto spectate and break)
        
        for _, playerId in pairs(players) do
            currentSessionPlayers[playerId] = true
            
            -- Get tags
            local tags = ""
            if Players.GetTags then
                tags = Players.GetTags(playerId)
            end
            
            local displayName = GetPlayerDisplayName(playerId, tags)
            
            -- Reuse or register headshot
            -- RegisterHeadshot checks if handle exists in cache, so calling it is safe/efficient
            RegisterHeadshot(playerId)
            
            local pid = playerId
            local PlayerMenu = require("Impulse/ImpulseLua/submenus/session/player_menu")
            
            -- Track which option index maps to which player
            self.playerIdMap[optionIndex] = pid
            optionIndex = optionIndex + 1
            
            self:AddOption(SubmenuOption.new(displayName)
                :AddSubmenu(PlayerMenu.GetInstance())
                :AddOnDraw(CreateHeadshotDrawer(pid))
                :AddFunction(function()
                    self.selectedPlayer = pid

                    -- Auto Spectate: On Enter
                    if autoSpectateState.index == 2 then -- On Enter
                         local feature = FeatureMgr.GetFeatureByName("Spectate Player", pid)
                         if feature then
                             feature:SetValue(true):TriggerCallback()
                         end
                    end

                    self.isGoingToPlayerMenu = true -- Flag to prevent cleanup on exit
                    PlayerMenu.GetInstance():SetPlayer(pid)
                end)
                :AddTooltip("View player options"))
        end
        
        -- Cleanup invalid headshots (players who left)
        for pid, handle in pairs(headshotHandles) do
            if not currentSessionPlayers[pid] then
                if handle and handle ~= 0 then
                    pcall(function() PED.UNREGISTER_PEDHEADSHOT(handle) end)
                end
                headshotHandles[pid] = nil
            end
        end
    end
end

--- Cleanup when exiting the menu
function PlayerListMenu:OnExit()
    -- helper to check if we are navigating deeper or back
    if self.isGoingToPlayerMenu then
        self.isGoingToPlayerMenu = false
        return
    end

    -- Stop spectating if we are exiting the player list (going back)
    if self.selectedPlayer and self.selectedPlayer ~= -1 then
         local feature = FeatureMgr.GetFeatureByName("Spectate Player", self.selectedPlayer)
         if feature then
             -- Force disable spectate
             feature:SetValue(false):TriggerCallback()
         end
    end

    -- Clear selection state
    self.selectedPlayer = -1
    self.lastHoveredPlayer = nil
    PlayerInfoComponent.SetPlayer(-1)
end

return PlayerListMenu

