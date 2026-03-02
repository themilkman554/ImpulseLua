--[[
    Impulse Lua - Session Chat Command Menu
    Menu interface for controlling session-wide chat command permissions
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local ChatCommands = require("Impulse/ImpulseLua/lib/chat_commands")
local Renderer = require("Impulse/ImpulseLua/lib/renderer") -- For notifying

local SessionChatCommandMenu = setmetatable({}, { __index = Submenu })
SessionChatCommandMenu.__index = SessionChatCommandMenu

local instance = nil

function SessionChatCommandMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Session Commands"), SessionChatCommandMenu)
        instance:Init()
    end
    return instance
end

function SessionChatCommandMenu:Init()
    -- Initialize ChatCommands listener if not already
    ChatCommands.Init()

    local function GetPerms()
        return ChatCommands.GetGlobalPermissions()
    end

    self:AddOption(ToggleOption.new("Enable chat commands for lobby")
        :AddToggle(function() return GetPerms().m_chatCommand end)
        :AddFunction(function()
            local p = GetPerms()
            p.m_chatCommand = not p.m_chatCommand
        end)
        :AddTooltip("Master switch for global chat commands")
        :SetDonor())

    self:AddOption(ButtonOption.new("Send chat commands list to lobby")
        :AddFunction(function()
            local commandList = "Cmds: !spawn vehicle/ped/object/bodyguard, !weapons, !explodesession, !vehicle repair/boost/jump/upgrade, !copsturnblind, !offtheradar"
            
            -- Send to everyone (false = not team chat)
            GTA.SendChatMessageToEveryone(commandList, false)
            
            -- Add to local chat pool so sender sees it too
            local localPlayer = GTA.GetLocalPlayerId()
            GTA.AddChatMessageToPool(localPlayer, commandList, false)
            
            Renderer.Notify("Chat commands list sent to lobby")
        end)
        :AddTooltip("Sends the list of available commands to the game chat, Might not work since cherax might have disabled api for this")
        :SetDonor())

    self:AddOption(BreakOption.new())

    self:AddOption(ButtonOption.new("Toggle all commands on")
        :AddFunction(function()
            ChatCommands.ToggleAllGlobal(true)
        end)
        :AddTooltip("Enable all command options for the lobby")
        :SetDonor())

    self:AddOption(ButtonOption.new("Toggle all commands off")
        :AddFunction(function()
            ChatCommands.ToggleAllGlobal(false)
        end)
        :AddTooltip("Disable all command options for the lobby")
        :SetDonor())

    self:AddOption(BreakOption.new("General commands"))

    -- Money drop still excluded

    self:AddOption(ToggleOption.new("Spawn vehicle [!spawn vehicle <name>]")
        :AddToggle(function() return GetPerms().m_chatCommandSpawnVehicle end)
        :AddFunction(function()
            local p = GetPerms()
            p.m_chatCommandSpawnVehicle = not p.m_chatCommandSpawnVehicle
        end)
        :AddTooltip("Chat command spawn vehicle")
        :SetDonor())

    self:AddOption(ToggleOption.new("Spawn ped [!spawn ped <name>]")
        :AddToggle(function() return GetPerms().m_chatCommandSpawnPed end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandSpawnPed = not p.m_chatCommandSpawnPed
        end)
        :AddTooltip("Chat command spawn ped")
        :SetDonor())
        
    self:AddOption(ToggleOption.new("Spawn object [!spawn object <name>]")
        :AddToggle(function() return GetPerms().m_chatCommandSpawnObject end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandSpawnObject = not p.m_chatCommandSpawnObject
        end)
        :AddTooltip("Chat command spawn object")
        :SetDonor())

    self:AddOption(ToggleOption.new("Spawn bodyguard [!spawn bodyguard <count>]")
        :AddToggle(function() return GetPerms().m_chatCommandSpawnBodyguard end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandSpawnBodyguard = not p.m_chatCommandSpawnBodyguard
        end)
        :AddTooltip("Chat command spawn bodyguard")
        :SetDonor())

    self:AddOption(ToggleOption.new("Give weapons [!weapons]")
        :AddToggle(function() return GetPerms().m_chatCommandGiveWeapons end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandGiveWeapons = not p.m_chatCommandGiveWeapons
        end)
        :AddTooltip("Chat command give weapons")
        :SetDonor())

    self:AddOption(ToggleOption.new("Explode session [!explodesession]")
        :AddToggle(function() return GetPerms().m_chatCommandExplodeSession end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandExplodeSession = not p.m_chatCommandExplodeSession
        end)
        :AddTooltip("Chat command explode session")
        :SetDonor())

    self:AddOption(BreakOption.new("Vehicle commands (close-by)"))

    self:AddOption(ToggleOption.new("Vehicle repair [!vehicle repair]")
        :AddToggle(function() return GetPerms().m_chatCommandVehicleRepair end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandVehicleRepair = not p.m_chatCommandVehicleRepair
        end)
        :AddTooltip("Chat command vehicle repair")
        :SetDonor())

    self:AddOption(ToggleOption.new("Vehicle boost [!vehicle boost]")
        :AddToggle(function() return GetPerms().m_chatCommandVehicleBoost end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandVehicleBoost = not p.m_chatCommandVehicleBoost
        end)
        :AddTooltip("Chat command vehicle boost")
        :SetDonor())

    self:AddOption(ToggleOption.new("Vehicle jump [!vehicle jump]")
        :AddToggle(function() return GetPerms().m_chatCommandVehicleJump end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandVehicleJump = not p.m_chatCommandVehicleJump
        end)
        :AddTooltip("Chat command vehicle jump")
        :SetDonor())

    self:AddOption(ToggleOption.new("Vehicle upgrade [!vehicle upgrade]")
        :AddToggle(function() return GetPerms().m_chatCommandVehicleUpgrade end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandVehicleUpgrade = not p.m_chatCommandVehicleUpgrade
        end)
        :AddTooltip("Chat command vehicle upgrade")
        :SetDonor())

    self:AddOption(BreakOption.new("Give global commands"))

    self:AddOption(ToggleOption.new("Cops turn blind eye [!copsturnblind on/off]")
        :AddToggle(function() return GetPerms().m_chatCommandGlobalsCopsturnblind end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandGlobalsCopsturnblind = not p.m_chatCommandGlobalsCopsturnblind
        end)
        :AddTooltip("Chat command cops turn blind eye")
        :SetDonor())

    self:AddOption(ToggleOption.new("Off the radar [!offtheradar on/off]")
        :AddToggle(function() return GetPerms().m_chatCommandGlobalsOfftheradar end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandGlobalsOfftheradar = not p.m_chatCommandGlobalsOfftheradar
        end)
        :AddTooltip("Chat command off the radar")
        :SetDonor())

end

return SessionChatCommandMenu
