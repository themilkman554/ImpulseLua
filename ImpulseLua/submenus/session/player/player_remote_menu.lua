--[[
    Impulse Lua - Player Remote Menu
    Remote options for selected player
    Port of remoteMenu.cpp from Impulse C++ (using Cherax built-in features)
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")
local PlayerMenu = nil -- Lazy loaded

local PlayerRemoteMenu = setmetatable({}, { __index = Submenu })
PlayerRemoteMenu.__index = PlayerRemoteMenu

local instance = nil

-- Per-player remote state (for toggles that loop)
local playerRemoteState = {}

local function GetPlayerRemoteState(playerId)
    if not playerRemoteState[playerId] then
        playerRemoteState[playerId] = {
            soundSpam = false,
            forceCameraForward = false,
            displaySpectatingMessage = false,
            neverWanted = false,
            offTheRadar = false,
            copsTurnBlindEye = false,
        }
    end
    return playerRemoteState[playerId]
end

-- Report and Commend state
local remoteState = {
    reportTypeIndex = 1,
    commendTypeIndex = 1,
}

-- Report types (from Cherax menu)
local reportTypes = {
    { name = "Griefing" },
    { name = "Offensive Language" },
    { name = "Offensive License Plate" },
    { name = "Offensive UGC" },
    { name = "Game Exploits" },
    { name = "Exploits" },
    { name = "Annoying Voice Chat" },
    { name = "Hate Speech Voice Chat" },
    { name = "Annoying Text Chat" },
    { name = "Hate Speech Text Chat" },
}

-- Commend types (from Cherax menu)
local commendTypes = {
    { name = "Friendly" },
    { name = "Helpful" },
}

-- Feature IDs for report/commend
local FEATURE_IDS = {
    REPORT_TYPE = 3238814055,
    REPORT_PLAYER = 2827833646,
    COMMEND_TYPE = 2772819450,
    COMMEND_PLAYER = 770299621,
}

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
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then return "Unknown" end
    return PLAYER.GET_PLAYER_NAME(playerId) or "Unknown"
end



--- Report the selected player with the current report type
local function ReportPlayer()
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then return end
    
    -- Set the report type index (0-indexed for Cherax)
    FeatureMgr.SetFeatureListIndex(FEATURE_IDS.REPORT_TYPE, remoteState.reportTypeIndex - 1)
    
    FeatureMgr.GetFeatureByName("Report Player", playerId):TriggerCallback()
    
    Renderer.Notify("Reported " .. GetSelectedPlayerName() .. " for " .. reportTypes[remoteState.reportTypeIndex].name)
end

--- Commend the selected player with the current commend type
local function CommendPlayer()
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then return end
    
    -- Set the commend type index (0-indexed for Cherax)
    FeatureMgr.SetFeatureListIndex(FEATURE_IDS.COMMEND_TYPE, remoteState.commendTypeIndex - 1)
    
    FeatureMgr.GetFeatureByName("Commend Player", playerId):TriggerCallback()
    
    Renderer.Notify("Commended " .. GetSelectedPlayerName() .. " as " .. commendTypes[remoteState.commendTypeIndex].name)
end

-- ============================================
-- Menu Definition
-- ============================================

function PlayerRemoteMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Remote"), PlayerRemoteMenu)
        instance:Init()
    end
    return instance
end

function PlayerRemoteMenu:Init()
    -- Kicks section
    self:AddOption(ButtonOption.new("Smart Kick")
        :AddFunction(function()
            local playerId = GetSelectedPlayerId()
            if FeatureState.Trigger("Smart Kick", playerId) then
                Renderer.Notify("Smart kicked " .. GetSelectedPlayerName())
            end
        end)
        :AddTooltip("Smart kick"))
    
    self:AddOption(ButtonOption.new("Script Event Kick")
        :AddFunction(function()
            local playerId = GetSelectedPlayerId()
            if FeatureState.Trigger("Script Event Kick", playerId) then
                Renderer.Notify("Script event kicked " .. GetSelectedPlayerName())
            end
        end)
        :AddTooltip("Script event kick"))
    
    self:AddOption(ButtonOption.new("CEO/MC Kick")
        :AddFunction(function()
            local playerId = GetSelectedPlayerId()
            if FeatureState.Trigger("CEO/MC Kick", playerId) then
                Renderer.Notify("CEO/MC kicked " .. GetSelectedPlayerName())
            end
        end)
        :AddTooltip("CEO/MC kick"))
    
    self:AddOption(ButtonOption.new("Vehicle Kick")
        :AddFunction(function()
            local playerId = GetSelectedPlayerId()
            if FeatureState.Trigger("Vehicle Kick", playerId) then
                Renderer.Notify("Vehicle kicked " .. GetSelectedPlayerName())
            end
        end)
        :AddTooltip("Kick player from vehicle"))
    
    -- Troll section
    self:AddOption(BreakOption.new("Troll"))
    
    self:AddOption(ButtonOption.new("Infinite Loading Screen")
        :AddFunction(function()
            local playerId = GetSelectedPlayerId()
            if FeatureState.Trigger("Infinite Loading Screen", playerId) then
                Renderer.Notify("Sent infinite loading screen to " .. GetSelectedPlayerName())
            end
        end)
        :AddTooltip("Infinite loading screen"))
    
    self:AddOption(ToggleOption.new("Force Camera Forward", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerRemoteState(playerId)
            state.forceCameraForward = value
            
            local feature = FeatureMgr.GetFeatureByName("Force Camera Forward", playerId)
            if feature then
                feature:SetValue(value):TriggerCallback()
            end
            
            if value then
                Renderer.Notify("Forcing camera forward for " .. GetSelectedPlayerName())
            else
                Renderer.Notify("Stopped forcing camera forward for " .. GetSelectedPlayerName())
            end
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerRemoteState(playerId)
            return state.forceCameraForward
        end
        return false
    end)
        :AddTooltip("Force the players camera forward"))
    
    -- Give Globals section
    self:AddOption(BreakOption.new("Give Globals"))
    
    self:AddOption(ToggleOption.new("Off The Radar", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerRemoteState(playerId)
            state.offTheRadar = value
            
            local feature = FeatureMgr.GetFeatureByName("Off The Radar", playerId)
            if feature then
                feature:SetValue(value):TriggerCallback()
            end

            if value then
                Renderer.Notify("Off the radar given to " .. GetSelectedPlayerName())
            else
                Renderer.Notify("Off the radar removed from " .. GetSelectedPlayerName())
            end
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerRemoteState(playerId)
            return state.offTheRadar
        end
        return false
    end)
        :AddTooltip("Off the radar"))
    
    self:AddOption(ToggleOption.new("Bribe Authorities", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerRemoteState(playerId)
            state.copsTurnBlindEye = value
            
            local feature = FeatureMgr.GetFeatureByName("Bribe Authorities", playerId)
            if feature then
                feature:SetValue(value):TriggerCallback()
            end
            
            if value then
                Renderer.Notify("Bribe authorities given to " .. GetSelectedPlayerName())
            else
                Renderer.Notify("Bribe authorities removed from " .. GetSelectedPlayerName())
            end
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerRemoteState(playerId)
            return state.copsTurnBlindEye
        end
        return false
    end)
        :AddTooltip("Bribe authorities"))
    
    -- Reports section
    self:AddOption(BreakOption.new("Reports"))
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Report Type")
        :AddScroll(reportTypes, 1)
        :AddIndexRef(remoteState, "reportTypeIndex")
        :CanLoop()
        :AddFunction(function()
            FeatureMgr.SetFeatureListIndex(FEATURE_IDS.REPORT_TYPE, remoteState.reportTypeIndex - 1)
        end)
        :AddTooltip("Select report type"))
    
    self:AddOption(ButtonOption.new("Report Player")
        :AddFunction(ReportPlayer)
        :AddTooltip("Report the player for the selected reason"))
    
    -- Commend section
    self:AddOption(BreakOption.new("Commend"))
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Commend Type")
        :AddScroll(commendTypes, 1)
        :AddIndexRef(remoteState, "commendTypeIndex")
        :CanLoop()
        :AddFunction(function()
            FeatureMgr.SetFeatureListIndex(FEATURE_IDS.COMMEND_TYPE, remoteState.commendTypeIndex - 1)
        end)
        :AddTooltip("Select commend type"))
    
    self:AddOption(ButtonOption.new("Commend Player")
        :AddFunction(CommendPlayer)
        :AddTooltip("Commend the player"))
end

return PlayerRemoteMenu

