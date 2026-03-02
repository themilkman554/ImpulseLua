--[[
    Impulse Lua - Chat Command Menu
    Menu interface for controlling chat command permissions
    Port of chatCommandMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local ChatCommands = require("Impulse/ImpulseLua/lib/chat_commands")
local PlayerMenu = nil -- Lazy load

local ChatCommandMenu = setmetatable({}, { __index = Submenu })
ChatCommandMenu.__index = ChatCommandMenu

local instance = nil

--- Get selected player ID
local function GetSelectedPlayerId()
    if not PlayerMenu then
        PlayerMenu = require("Impulse/ImpulseLua/submenus/session/player_menu")
    end
    return PlayerMenu.targetPlayer or -1
end

function ChatCommandMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Chat commands"), ChatCommandMenu)
        instance:Init()
    end
    return instance
end

function ChatCommandMenu:Init()
    -- Initialize ChatCommands listener if not already
    ChatCommands.Init()

    local function GetPerms()
        local pid = GetSelectedPlayerId()
        return ChatCommands.GetPermissions(pid)
    end

    self:AddOption(ButtonOption.new("Toggle all commands on")
        :AddFunction(function()
            ChatCommands.ToggleAll(GetSelectedPlayerId(), true)
        end)
        :AddTooltip("Enable all command options for this player")
        :SetDonor())

    self:AddOption(ButtonOption.new("Toggle all commands off")
        :AddFunction(function()
            ChatCommands.ToggleAll(GetSelectedPlayerId(), false)
        end)
        :AddTooltip("Disable all command options for this player")
        :SetDonor())

    self:AddOption(BreakOption.new())

    self:AddOption(ToggleOption.new("Enable chat commands for player")
        :AddToggle(function() return GetPerms().m_chatCommand end)
        :AddFunction(function()
            local p = GetPerms()
            p.m_chatCommand = not p.m_chatCommand
        end)
        :AddTooltip("Enable chat commands for player")
        :SetDonor())

    self:AddOption(BreakOption.new("General commands"))

    -- Money drop excluded

    self:AddOption(ToggleOption.new("Spawn vehicle [!spawn vehicle <name>]")
        :AddToggle(function() return GetPerms().m_chatCommandSpawnVehicle end)
        :AddFunction(function()
            local p = GetPerms()
            p.m_chatCommandSpawnVehicle = not p.m_chatCommandSpawnVehicle
        end)
        :AddTooltip("Chat command spawn vehicle:\n!spawn vehicle <hash/model name>")
        :SetDonor())

    self:AddOption(ToggleOption.new("Spawn ped [!spawn ped <name>]")
        :AddToggle(function() return GetPerms().m_chatCommandSpawnPed end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandSpawnPed = not p.m_chatCommandSpawnPed
        end)
        :AddTooltip("Chat command spawn ped:\n!spawn ped <hash/model name>")
        :SetDonor())
        
    self:AddOption(ToggleOption.new("Spawn object [!spawn object <name>]")
        :AddToggle(function() return GetPerms().m_chatCommandSpawnObject end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandSpawnObject = not p.m_chatCommandSpawnObject
        end)
        :AddTooltip("Chat command spawn object:\n!spawn object <hash/model name>")
        :SetDonor())

    self:AddOption(ToggleOption.new("Spawn bodyguard [!spawn bodyguard <count>]")
        :AddToggle(function() return GetPerms().m_chatCommandSpawnBodyguard end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandSpawnBodyguard = not p.m_chatCommandSpawnBodyguard
        end)
        :AddTooltip("Chat command spawn bodyguard:\n!spawn bodyguard <count>")
        :SetDonor())

    self:AddOption(ToggleOption.new("Give weapons [!weapons]")
        :AddToggle(function() return GetPerms().m_chatCommandGiveWeapons end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandGiveWeapons = not p.m_chatCommandGiveWeapons
        end)
        :AddTooltip("Chat command give weapons:\n!weapons")
        :SetDonor())

    self:AddOption(ToggleOption.new("Explode session [!explodesession]")
        :AddToggle(function() return GetPerms().m_chatCommandExplodeSession end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandExplodeSession = not p.m_chatCommandExplodeSession
        end)
        :AddTooltip("Chat command explode session:\n!explodesession")
        :SetDonor())

    self:AddOption(BreakOption.new("Vehicle commands (close-by)"))

    self:AddOption(ToggleOption.new("Vehicle repair [!vehicle repair]")
        :AddToggle(function() return GetPerms().m_chatCommandVehicleRepair end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandVehicleRepair = not p.m_chatCommandVehicleRepair
        end)
        :AddTooltip("Chat command vehicle repair:\n!vehicle repair")
        :SetDonor())

    self:AddOption(ToggleOption.new("Vehicle boost [!vehicle boost]")
        :AddToggle(function() return GetPerms().m_chatCommandVehicleBoost end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandVehicleBoost = not p.m_chatCommandVehicleBoost
        end)
        :AddTooltip("Chat command vehicle boost:\n!vehicle boost")
        :SetDonor())

    self:AddOption(ToggleOption.new("Vehicle jump [!vehicle jump]")
        :AddToggle(function() return GetPerms().m_chatCommandVehicleJump end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandVehicleJump = not p.m_chatCommandVehicleJump
        end)
        :AddTooltip("Chat command vehicle jump:\n!vehicle jump")
        :SetDonor())

    self:AddOption(ToggleOption.new("Vehicle upgrade [!vehicle upgrade]")
        :AddToggle(function() return GetPerms().m_chatCommandVehicleUpgrade end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandVehicleUpgrade = not p.m_chatCommandVehicleUpgrade
        end)
        :AddTooltip("Chat command vehicle upgrade:\n!vehicle upgrade")
        :SetDonor())

    self:AddOption(BreakOption.new("Give global commands"))

    self:AddOption(ToggleOption.new("Cops turn blind eye [!copsturnblind on/off]")
        :AddToggle(function() return GetPerms().m_chatCommandGlobalsCopsturnblind end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandGlobalsCopsturnblind = not p.m_chatCommandGlobalsCopsturnblind
        end)
        :AddTooltip("Chat command cops turn blind eye:\n!copsturnblind on/off")
        :SetDonor())

    self:AddOption(ToggleOption.new("Off the radar [!offtheradar on/off]")
        :AddToggle(function() return GetPerms().m_chatCommandGlobalsOfftheradar end)
        :AddFunction(function() 
            local p = GetPerms()
            p.m_chatCommandGlobalsOfftheradar = not p.m_chatCommandGlobalsOfftheradar
        end)
        :AddTooltip("Chat command off the radar:\n!offtheradar on/off")
        :SetDonor())

end

return ChatCommandMenu
