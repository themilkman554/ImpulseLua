local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local SessionStarterMenu = setmetatable({}, { __index = Submenu })
SessionStarterMenu.__index = SessionStarterMenu

local instance = nil


local config = {
    autoStartSP = true,
    autoStartLobby = true,
    autoStartOverseer = true,
    lobbyPlayerCount = 4,
    sessionTypeIndex = 7 
}

-- Session Types List
local sessionTypes = {
    "Join Public Session",      -- 1
    "New Public Session",       -- 2
    "Closed Crew Session",      -- 3
    "Crew Session",             -- 4
    "Closed Friend Session",    -- 5
    "Find Friend Session",      -- 6
    "Solo Session",             -- 7
    "Invite Only Session",      -- 8
    "Join Crew Session",        -- 9
    "Leave GTA Online"          -- 10
}

function SessionStarterMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Session Starter"), SessionStarterMenu)
        instance:Init()
    end
    return instance
end

function SessionStarterMenu:Init()
    local HostToolkitMenu = require("Impulse/ImpulseLua/submenus/session/host_toolkit_menu")

    self:AddOption(SubmenuOption.new("Host Toolkit")
        :AddSubmenu(HostToolkitMenu.GetInstance())
        :AddTooltip("Manage session and player access"))

    self:AddOption(BreakOption.new("Manual Start"))

    local sessionTypeOpt = ScrollOption.new(1, "Session type")
    sessionTypeOpt:AddScroll(sessionTypes, config.sessionTypeIndex)
    sessionTypeOpt:AddFunction(function()
        local idx = sessionTypeOpt:GetIndex()
        config.sessionTypeIndex = idx
        FeatureMgr.SetFeatureListIndex(603923874, idx - 1) 
    end)
    self:AddOption(sessionTypeOpt)

 
    self:AddOption(ButtonOption.new("Start session")
        :AddFunction(function()
            FeatureMgr.TriggerFeatureCallback(3364415752)
            Renderer.Notify("Starting session...")
        end))
end

return SessionStarterMenu
