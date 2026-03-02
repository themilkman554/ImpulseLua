local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local TextInputComponent = require("Impulse/ImpulseLua/lib/ui/text_input_component")

local SessionMenu = setmetatable({}, { __index = Submenu })
SessionMenu.__index = SessionMenu

local instance = nil

-- Session state
local sessionState = {
    showSessionInfo = false,
    showTalkingPlayers = false,
    revealPlayers = false,
    notifyOnJoin = false,
    notifyCashDrops = false,
}

local talkingState = {
    animFrame = 1,
    lastAnimTime = 0,
}

local joinInput = nil

local micIcons = {
    "leaderboard_audio_inactive",
    "leaderboard_audio_1",
    "leaderboard_audio_2",
    "leaderboard_audio_3",
}

function SessionMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Session"), SessionMenu)
        instance:Init()
    end
    return instance
end

function SessionMenu:Init()
    local PlayerListMenu = require("Impulse/ImpulseLua/submenus/session/player_list_menu")
    local AllPlayersMenu = require("Impulse/ImpulseLua/submenus/session/all_players_menu")
    local SessionStarterMenu = require("Impulse/ImpulseLua/submenus/session/session_starter_menu")
    local PlayerHistoryMenu = require("Impulse/ImpulseLua/submenus/session/player_history_menu")
    
    self:AddOption(SubmenuOption.new("Players")
        :AddSubmenu(PlayerListMenu.GetInstance())
        :AddTooltip("Online players options"))
    
    self:AddOption(SubmenuOption.new("All players")
        :AddSubmenu(AllPlayersMenu.GetInstance())
        :AddTooltip("All players options"))

    self:AddOption(SubmenuOption.new("Session starter")
        :AddSubmenu(SessionStarterMenu.GetInstance())
        :AddTooltip("Start a new session"))

    self:AddOption(BreakOption.new("Player Extras"))

    self:AddOption(SubmenuOption.new("Player history")
        :AddSubmenu(PlayerHistoryMenu.GetInstance())
        :AddTooltip("View players you have encountered"))

    self:AddOption(ButtonOption.new("Join player by rockstar ID")
        :AddFunction(function()
            if not joinInput then
                joinInput = TextInputComponent.new("Enter the target R*ID", function(text)
                    if text and #text > 0 then
                        local rid = tonumber(text)
                        if rid then
                            local feat = FeatureMgr.GetFeature(24693643)
                            if feat then
                                feat:SetIntValue(rid)
                            end
                            
                            FeatureMgr.TriggerFeatureCallback(807534263)
                            Renderer.Notify("Joining RID: " .. tostring(rid))
                        else
                            Renderer.Notify("Invalid RID entered")
                        end
                    end
                end)
            end
            joinInput:Show()
        end)
        :AddTooltip("Public sessions only - you must have a friend on sc for this to function"))

    self:AddOption(BreakOption.new())
    
    -- Notification toggles (matches C++ order)
   
    self:AddOption(ToggleOption.new("Show session info")
        :AddToggleRef(sessionState, "showSessionInfo")
        :AddTooltip("This will display how many players are in your session, how many slots are left and who is host"))
    
    self:AddOption(ToggleOption.new("Notify on player joins in session")
        :AddToggleRef(sessionState, "notifyOnJoin")
        :AddTooltip("This will display a notification when a player is joining your session"))
    


    
    self:AddOption(ToggleOption.new("Reveal players")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Reveal All Players"):Toggle(sessionState.revealPlayers)
        end)
        :AddToggleRef(sessionState, "revealPlayers")
        :AddTooltip("Shows off the radar players"))
    

end

--- Feature update - runs every frame
function SessionMenu:FeatureUpdate()
    if sessionState.showSessionInfo then
        self:RenderSessionInfo()
    end
    
    if sessionState.showTalkingPlayers then
        self:RenderTalkingPlayers()
    end
    
    if sessionState.notifyOnJoin then
        self:CheckPlayerJoins()
    end
    
    -- Update ESP menu (draws ESP overlays)
    local PlayerESPMenu = require("Impulse/ImpulseLua/submenus/session/player/player_esp_menu")
    if PlayerESPMenu.GetInstance().FeatureUpdate then
        PlayerESPMenu.GetInstance():FeatureUpdate()
    end

    if joinInput and joinInput:IsVisible() then
        joinInput:Update()
    end
end

-- Track connected players for join notifications
local connectedPlayers = {}
local isJoinTrackerInitialized = false

function SessionMenu:CheckPlayerJoins()
    if not NETWORK.NETWORK_IS_SESSION_ACTIVE() then
        connectedPlayers = {}
        isJoinTrackerInitialized = false
        return
    end

    local currentPlayers = {}
    
    -- 0 to 31 (ignoring local player potentially, but usually we want to know everyone)
    for i = 0, 31 do
        if NETWORK.NETWORK_IS_PLAYER_ACTIVE(i) then
            currentPlayers[i] = true
            
            -- Check if new
            if not connectedPlayers[i] then
                -- Only notify if we are already initialized (don't spam on enable/inject)
                if isJoinTrackerInitialized then
                     local name = PLAYER.GET_PLAYER_NAME(i) or "Unknown"
                     -- Using Renderer.NotifyMap as requested
                     Renderer.NotifyMap(name .. " joined")
                end
                connectedPlayers[i] = true
            end
        end
    end
    
    -- Check for leaves to keep list clean
    for id, _ in pairs(connectedPlayers) do
        if not currentPlayers[id] then
            connectedPlayers[id] = nil
        end
    end
    
    isJoinTrackerInitialized = true
end

--- Render talking players on screen with mic icons
function SessionMenu:RenderTalkingPlayers()
    -- Request texture dict if needed
    if not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED("mpleaderboard") then
        GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("mpleaderboard", false)
        return
    end
    
    -- Animate mic icon every 500ms
    local currentTime = MISC.GET_GAME_TIMER()
    if currentTime - talkingState.lastAnimTime > 500 then
        talkingState.animFrame = talkingState.animFrame + 1
        if talkingState.animFrame > 4 then
            talkingState.animFrame = 1
        end
        talkingState.lastAnimTime = currentTime
    end
    
    local iconName = micIcons[talkingState.animFrame] or micIcons[1]
    local positionOffset = 0
    local xPos = 0.86
    local yBase = 0.70
    
    -- Get all players and check if talking
    local players = {}
    if Players and Players.Get and ePlayerListSort then
        players = Players.Get(ePlayerListSort.PLAYER_ID, "") or {}
    else
        -- Fallback
        for i = 0, 31 do
            if NETWORK.NETWORK_IS_PLAYER_ACTIVE(i) then
                table.insert(players, i)
            end
        end
    end
    
    for _, playerId in ipairs(players) do
        local isTalking = NETWORK.NETWORK_IS_PLAYER_TALKING(playerId)
        
        if isTalking then
            local name = PLAYER.GET_PLAYER_NAME(playerId) or "Unknown"
            local y = yBase + positionOffset * 0.025
            
            -- Draw shadow icon
            GRAPHICS.DRAW_SPRITE("mpleaderboard", iconName, 
                xPos + 0.005, y + 0.002, 0.015, 0.025, 0.0, 
                0, 0, 0, 200, false, 0)
            
            -- Draw main icon
            GRAPHICS.DRAW_SPRITE("mpleaderboard", iconName, 
                xPos, y, 0.015, 0.025, 0.0, 
                255, 255, 255, 255, false, 0)
            
            -- Draw player name
            Renderer.DrawString(name, xPos + 0.015, y - 0.01, 4, 0.3, 
                { r = 255, g = 255, b = 255, a = 255 }, true)
            
            positionOffset = positionOffset + 1
        end
    end
end

function SessionMenu:RenderSessionInfo()
    local connected = NETWORK.NETWORK_GET_NUM_CONNECTED_PLAYERS()
    local freeSlots = 32 - connected
    
    local hostName = "**Invalid**"
    local players = {}
    if Players and Players.Get and ePlayerListSort then
        players = Players.Get(ePlayerListSort.HOST_QUEUE, "") or {}
        if #players > 0 then
            hostName = PLAYER.GET_PLAYER_NAME(players[1]) or "**Invalid**"
        end
    end
    
    local xPos = 0.1 + 0.069 
    local yStart = 0.805
    local yStride = 0.025
    local font = 4 
    local scale = 0.35
    local color = { r = 255, g = 255, b = 255, a = 255 }
    
    Renderer.DrawString(string.format("Connected players: %d", connected), 
        xPos, yStart, font, scale, color)
    
    Renderer.DrawString(string.format("Free slots: %d", freeSlots), 
        xPos, yStart + (yStride * 1), font, scale, color)
    
    Renderer.DrawString("Session Host: " .. hostName, 
        xPos, yStart + (yStride * 2), font, scale, color)
end
SessionMenu.State = sessionState

return SessionMenu

