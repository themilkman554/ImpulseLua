--[[
    Impulse Lua - All Players Menu
    Bulk actions affecting all players in session
    Port of allPlayersMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local PlayerDataCache = require("Impulse/ImpulseLua/lib/player_data_cache")
local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")

local AllPlayersMenu = setmetatable({}, { __index = Submenu })
AllPlayersMenu.__index = AllPlayersMenu

local instance = nil

-- Shared State
AllPlayersMenu.state = {
    friends = false,
    modders = false,
    team = false,
    host = false,
    self = true, -- Default true as per C++ (usually desirable)
    evolve = false,
    chat = false -- Chat commands toggle
}

function AllPlayersMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("All Players"), AllPlayersMenu)
        instance:Init()
    end
    return instance
end

--- Check if a player should be excluded based on state
---@param pid number Player ID
---@return boolean true if excluded
function AllPlayersMenu.IsExcluded(pid)
    local state = AllPlayersMenu.state
    local localPlayer = PLAYER.PLAYER_ID()
    
    -- Exclude Self
    if state.self and pid == localPlayer then
        return true
    end
    
    -- Exclude Host
    if state.host then
        local host = -1
        if Players and Players.GetHost then -- If API has it, otherwise use native
             -- Native fallback if needed, but Cherax might have specific host utils
        end
        -- Fallback check using tags or native
        -- Note: network host check might need more involved logic or PlayerDataCache
    end
    
    -- Exclude Friends
    -- Requires friend check logic, ideally from Cherax API or PlayerDataCache
    -- if state.friends and IsFriend(pid) then return true end

    return false
end

--- Get list of targeted players
---@return table Array of player IDs
function AllPlayersMenu.GetTargetPlayers()
    local players = {}
    local localPlayer = PLAYER.PLAYER_ID()
    
    if Players and Players.Get and ePlayerListSort then
        local allPlayers = Players.Get(ePlayerListSort.PLAYER_ID, "")
        if allPlayers then
            for _, pid in ipairs(allPlayers) do
                if not AllPlayersMenu.IsExcluded(pid) then
                    table.insert(players, pid)
                end
            end
        end
    else
        for i = 0, 31 do
            if NETWORK.NETWORK_IS_PLAYER_ACTIVE(i) then
                if not AllPlayersMenu.IsExcluded(i) then
                    table.insert(players, i)
                end
            end
        end
    end
    
    return players
end

function AllPlayersMenu:Init()
    local ExcludesMenu = require("Impulse/ImpulseLua/submenus/session/all_players/excludes_menu")
    local SessionTeleportMenu = require("Impulse/ImpulseLua/submenus/session/all_players/session_teleport_menu")
    local SessionPeacefulMenu = require("Impulse/ImpulseLua/submenus/session/all_players/session_peaceful_menu")
    local SessionGriefingMenu = require("Impulse/ImpulseLua/submenus/session/all_players/session_griefing_menu")
    local SessionTalkingMenu = require("Impulse/ImpulseLua/submenus/session/all_players/session_talking_menu")
    local SessionRemoteMenu = require("Impulse/ImpulseLua/submenus/session/all_players/session_remote_menu")
    local SessionVehicleMenu = require("Impulse/ImpulseLua/submenus/session/all_players/session_vehicle_menu")
    local SessionSpawnVehicleMenu = require("Impulse/ImpulseLua/submenus/session/all_players/session_spawn_vehicle_menu")
    local SessionESPMenu = require("Impulse/ImpulseLua/submenus/session/all_players/session_esp_menu")

    self:AddOption(SubmenuOption.new("Excludes")
        :AddSubmenu(ExcludesMenu.GetInstance())
        :AddTooltip("Exclude certain players from session options"))

    self:AddOption(SubmenuOption.new("Teleport")
        :AddSubmenu(SessionTeleportMenu.GetInstance())
        :AddTooltip("Teleport options"))

    self:AddOption(SubmenuOption.new("Peaceful")
        :AddSubmenu(SessionPeacefulMenu.GetInstance())
        :AddTooltip("Peaceful options"))

    self:AddOption(SubmenuOption.new("Griefing")
        :AddSubmenu(SessionGriefingMenu.GetInstance())
        :AddTooltip("Griefing options"))

    self:AddOption(SubmenuOption.new("Talking")
        :AddSubmenu(SessionTalkingMenu.GetInstance())
        :AddTooltip("Talking options"))

    self:AddOption(SubmenuOption.new("Remote")
        :AddSubmenu(SessionRemoteMenu.GetInstance())
        :AddTooltip("Remote options"))

    self:AddOption(SubmenuOption.new("Vehicle")
        :AddSubmenu(SessionVehicleMenu.GetInstance())
        :AddTooltip("Vehicle options"))

    self:AddOption(SubmenuOption.new("Spawn vehicle")
        :AddSubmenu(SessionSpawnVehicleMenu.GetInstance())
        :AddTooltip("Spawn vehicle options"))

    self:AddOption(SubmenuOption.new("Extra sensory perception")
        :AddSubmenu(SessionESPMenu.GetInstance())
        :AddTooltip("ESP options"))

    -- Chat commands submenu
    local SessionChatCommandMenu = require("Impulse/ImpulseLua/submenus/session/all_players/session_chat_command_menu")
    self:AddOption(SubmenuOption.new("Session Commands")
        :AddSubmenu(SessionChatCommandMenu.GetInstance())
        :AddTooltip("Chat command options"))

    -- Skipping "Add lobby to session overseer" as requested

    self:AddOption(BreakOption.new(""))

    self:AddOption(ButtonOption.new("Crash Session")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                FeatureState.Trigger("Crash Player", pid)
            end
            Renderer.Notify("Crashed all targeted players")
        end)
        :AddTooltip("Crash all players in the session"))

    self:AddOption(ButtonOption.new("Kick Session")
        :AddFunction(function()
            for _, pid in ipairs(AllPlayersMenu.GetTargetPlayers()) do
                FeatureState.Trigger("Smart Kick", pid)
            end
            Renderer.Notify("Kicked all targeted players")
        end)
        :AddTooltip("Kick all players from the session"))
end

return AllPlayersMenu
