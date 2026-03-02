--[[
    Impulse Lua - Player Menu
    Options for a selected player
    Port of playerMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local PlayerInfoComponent = require("Impulse/ImpulseLua/lib/ui/player_info_component")
local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")

local PlayerMenu = setmetatable({}, { __index = Submenu })
PlayerMenu.__index = PlayerMenu

local instance = nil

-- Current target player
PlayerMenu.targetPlayer = -1

-- Player state
local playerState = {
    spectating = false,
}



--- Toggle a Cherax feature
---@param featureName string
---@param playerId? number Optional player ID for player-specific features
local function ToggleFeature(featureName, playerId)
    local success, _ = pcall(function()
        local feature
        if playerId ~= nil then
            feature = FeatureMgr.GetFeatureByName(featureName, playerId)
        else
            feature = FeatureMgr.GetFeatureByName(featureName)
        end
        if feature then
            feature:TriggerCallback()
        end
    end)
    return success
end

function PlayerMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Player"), PlayerMenu)
        instance:Init()
    end
    return instance
end

--- Set the target player
---@param playerId number
function PlayerMenu:SetPlayer(playerId)
    PlayerMenu.targetPlayer = playerId
    PlayerInfoComponent.SetPlayer(playerId)
    local name = PLAYER.GET_PLAYER_NAME(playerId) or "Unknown"
    self.name = name
    -- Sync spectate state
    playerState.spectating = FeatureState.Get("Spectate Player", playerId)
end

--- Custom render to show player info
function PlayerMenu:CustomRender()
    PlayerInfoComponent.Render()
end

--- Get target player ped
---@return number
local function GetTargetPed()
    if PlayerMenu.targetPlayer < 0 then return 0 end
    return PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerMenu.targetPlayer)
end

--- Get target player coords
---@return table
local function GetTargetCoords()
    local ped = GetTargetPed()
    if ped and ENTITY.DOES_ENTITY_EXIST(ped) then
        return ENTITY.GET_ENTITY_COORDS(ped, true)
    end
    return { x = 0, y = 0, z = 0 }
end

--- Get selected player name
---@return string
local function GetSelectedPlayerName()
    if PlayerMenu.targetPlayer < 0 then return "Unknown" end
    return PLAYER.GET_PLAYER_NAME(PlayerMenu.targetPlayer) or "Unknown"
end

--- Add a submenu that also renders player info
---@param name string
---@param submenuModule table
---@param tooltip string
function PlayerMenu:AddPlayerSubmenu(name, submenuModule, tooltip)
    local submenu = submenuModule.GetInstance()
    -- Inject custom render to show player info in submenu
    submenu.CustomRender = function()
        PlayerInfoComponent.Render()
    end
    
    -- Inject update to check if player still exists
    local originalUpdate = submenu.Update
    submenu.Update = function(self)
        if PlayerMenu.targetPlayer ~= -1 then
            if not NETWORK.NETWORK_IS_PLAYER_ACTIVE(PlayerMenu.targetPlayer) or PlayerMenu.targetPlayer == -1 then
                local Menu = require("Impulse/ImpulseLua/lib/menu")
                local PlayerListMenu = require("Impulse/ImpulseLua/submenus/session/player_list_menu")
                
                -- Check if PlayerListMenu is in current stack
                local found = false
                local targetIndex = 0
                for i = #Menu.submenuStack, 1, -1 do
                    if Menu.submenuStack[i].submenu == PlayerListMenu.GetInstance() then
                        found = true
                        targetIndex = i
                        break
                    end
                end
                
                if found then
                    -- Restore state to PlayerListMenu
                    local state = Menu.submenuStack[targetIndex]
                    Menu.currentSubmenu = state.submenu
                    Menu.currentOption = state.option
                    Menu.scrollOffset = state.scroll
                    
                    -- Clear stack beyond this point
                    while #Menu.submenuStack >= targetIndex do
                        table.remove(Menu.submenuStack)
                    end
                else
                    -- Fallback if not found (direct jump or root issues)
                    Menu.currentSubmenu = PlayerListMenu.GetInstance()
                    Menu.currentOption = 1
                    Menu.scrollOffset = 0
                    -- Should we clear stack entirely? Maybe safer to leave as is or clear if we assume root is Session
                    -- If we assume Session is parent of PlayerList, we want stack to contain Session.
                end
                
                PlayerMenu.targetPlayer = -1
                return
            end
        end
        
        if originalUpdate then
            originalUpdate(self)
        end
    end
    
    self:AddOption(SubmenuOption.new(name)
        :AddSubmenu(submenu)
        :AddTooltip(tooltip))
end

function PlayerMenu:Init()
    -- Spectate player (matches C++ toggle)
    self:AddOption(ToggleOption.new("Spectate player")
        :AddToggleRef(playerState, "spectating")
        :AddFunction(function()
            -- User provided fix: specifically set value before triggering callback
            local feature = FeatureMgr.GetFeatureByName("Spectate Player", PlayerMenu.targetPlayer)
            if feature then
                feature:SetValue(playerState.spectating):TriggerCallback()
            end

            if playerState.spectating then
                Renderer.Notify("Spectating: " .. GetSelectedPlayerName())
            else
                Renderer.Notify("Stopped spectating")
            end
        end)
        :AddTooltip("Spectate player"))
    
    -- Quick actions submenu (ported)
    local PlayerQuickActionsMenu = require("Impulse/ImpulseLua/submenus/session/player/player_quick_actions_menu")
    self:AddPlayerSubmenu("Quick actions", PlayerQuickActionsMenu, "Quick actions for quick reactions")
    
    -- Teleport submenu (ported)
    local PlayerTeleportMenu = require("Impulse/ImpulseLua/submenus/session/player/player_teleport_menu")
    self:AddPlayerSubmenu("Teleport", PlayerTeleportMenu, "Teleport player options")
    
    -- Peaceful submenu (ported)
    local PlayerPeacefulMenu = require("Impulse/ImpulseLua/submenus/session/player/player_peaceful_menu")
    self:AddPlayerSubmenu("Peaceful", PlayerPeacefulMenu, "Peaceful player options")
    
    -- Griefing submenu (ported)
    local PlayerGriefingMenu = require("Impulse/ImpulseLua/submenus/session/player/player_griefing_menu")
    self:AddPlayerSubmenu("Griefing", PlayerGriefingMenu, "Grief player options")
    
    -- Vehicle submenu (ported)
    local PlayerVehicleMenu = require("Impulse/ImpulseLua/submenus/session/player/player_vehicle_menu")
    self:AddPlayerSubmenu("Vehicle", PlayerVehicleMenu, "Player vehicle options")
    
    -- Spawn vehicle submenu (ported)
    local PlayerSpawnVehicleMenu = require("Impulse/ImpulseLua/submenus/session/player/player_spawn_vehicle_menu")
    self:AddPlayerSubmenu("Spawn", PlayerSpawnVehicleMenu, "Spawn vehicle at player")
    
    -- Remote submenu (ported)
    local PlayerRemoteMenu = require("Impulse/ImpulseLua/submenus/session/player/player_remote_menu")
    self:AddPlayerSubmenu("Remote", PlayerRemoteMenu, "Remote player options")
    
    -- Drops submenu
    local PlayerDropsMenu = require("Impulse/ImpulseLua/submenus/session/player/player_drops_menu")
    self:AddPlayerSubmenu("Drops", PlayerDropsMenu, "Drops options")
    
    -- ESP submenu (ported)
    local PlayerESPMenu = require("Impulse/ImpulseLua/submenus/session/player/player_esp_menu")
    self:AddPlayerSubmenu("Extra sensory perception", PlayerESPMenu, "Extra sensory perception player options")

    -- Lua Content submenu
    local PlayerLuaContentMenu = require("Impulse/ImpulseLua/submenus/session/player/player_lua_content_menu")
    self:AddPlayerSubmenu("Lua Content", PlayerLuaContentMenu, "Player-specific Lua features")
    
    -- Chat commands submenu (ported)
    local ChatCommandMenu = require("Impulse/ImpulseLua/submenus/session/player/chat_command_menu")
    self:AddPlayerSubmenu("Chat commands", ChatCommandMenu, "Chat command options")
    
    -- TODO: Overseer submenu
    self:AddOption(ButtonOption.new("Overseer")
        :AddFunction(function()
            -- Overseer ID logic is handled by PlayerMenu.targetPlayer context in lua content menu
            Renderer.Notify("Overseer submenu not yet ported")
        end)
        :AddTooltip("Choose to add the player to the session overseer"))
    
    self:AddOption(BreakOption.new())
    
    -- Show profile (matches C++ ShowProfile)
    self:AddOption(ButtonOption.new("Show profile")
        :AddFunction(function()
            if Players.GetById(PlayerMenu.targetPlayer) ~= nil then
                local gamerInfo = Players.GetById(PlayerMenu.targetPlayer):GetGamerInfo()
                
                if gamerInfo ~= nil then
                    local gamerHandle = GamerHandle.New(gamerInfo.RockstarId)
                    local srcGamerHandle = gamerHandle:ToBuffer()
                    NETWORK.NETWORK_SHOW_PROFILE_UI(srcGamerHandle:GetBuffer())
                end
            end
        end)
        :AddTooltip("Open player social club profile ui"))
    
    -- Send friend request (matches C++)
    self:AddOption(ButtonOption.new("Send friend request")
        :AddFunction(function()
            if Players.GetById(PlayerMenu.targetPlayer) ~= nil then
                local gamerInfo = Players.GetById(PlayerMenu.targetPlayer):GetGamerInfo()
                
                if gamerInfo ~= nil then
                    local gamerHandle = GamerHandle.New(gamerInfo.RockstarId)
                    local srcGamerHandle = gamerHandle:ToBuffer()
                    NETWORK.NETWORK_ADD_FRIEND(srcGamerHandle:GetBuffer(), ".")
                    Renderer.Notify("Friend request sent")
                end
            end
        end)
        :AddTooltip("Add the person as a friend on your social club account"))
end

--- Feature update for player menu
function PlayerMenu:Update()
    if PlayerMenu.targetPlayer ~= -1 then
        if not NETWORK.NETWORK_IS_PLAYER_ACTIVE(PlayerMenu.targetPlayer) or PlayerMenu.targetPlayer == -1 then
            local Menu = require("Impulse/ImpulseLua/lib/menu")
            local PlayerListMenu = require("Impulse/ImpulseLua/submenus/session/player_list_menu")
            
            -- Check if PlayerListMenu is in current stack
            local found = false
            local targetIndex = 0
            for i = #Menu.submenuStack, 1, -1 do
                if Menu.submenuStack[i].submenu == PlayerListMenu.GetInstance() then
                    found = true
                    targetIndex = i
                    break
                end
            end
            
            if found then
                -- Restore state to PlayerListMenu
                local state = Menu.submenuStack[targetIndex]
                Menu.currentSubmenu = state.submenu
                Menu.currentOption = state.option
                Menu.scrollOffset = state.scroll
                
                -- Clear stack beyond this point
                while #Menu.submenuStack >= targetIndex do
                    table.remove(Menu.submenuStack)
                end
            else
                Menu.currentSubmenu = PlayerListMenu.GetInstance()
                Menu.currentOption = 1
                Menu.scrollOffset = 0
            end
            
            PlayerMenu.targetPlayer = -1
        end
    end
end

--- Feature update for player menu
function PlayerMenu:FeatureUpdate()
    -- Sync spectate state with Cherax
    if PlayerMenu.targetPlayer >= 0 then
        playerState.spectating = FeatureState.Get("Spectate Player", PlayerMenu.targetPlayer)
    end
end

return PlayerMenu
