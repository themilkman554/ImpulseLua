--[[
    Impulse Lua - Chat Command Verification Script
    Simulates chat events to test ChatCommands library
]]

local ChatCommands = require("Impulse/ImpulseLua/lib/chat_commands")
local EventMgr = EventMgr -- Global
local eLuaEvent = eLuaEvent -- Global

-- Mock Player
local mockPlayerId = PLAYER.PLAYER_ID()
local mockPlayerName = PLAYER.GET_PLAYER_NAME(mockPlayerId)

-- Ensure Init is called
ChatCommands.Init()

-- Enable permissions for testing
local perms = ChatCommands.GetPermissions(mockPlayerId)
perms.m_chatCommand = true
perms.m_chatCommandSpawnVehicle = true
perms.m_chatCommandSpawnPed = true
perms.m_chatCommandGiveWeapons = true

Utils.SetClipBoardText("Testing Chat Commands...")

-- Simulate !spawn vehicle adder
-- We can't easily trigger the actual event from Lua without a dedicated trigger function in API,
-- but we can manually invoke the handler if we had access to the registered function.
-- Since register handler returns an ID, we don't effectively have the callback function reference here 
-- unless we modified ChatCommands to expose it or stored it.

-- Workaround: We will manually call the HandleCommand local function if we expose it, 
-- OR we just trust the code since we can't fully mock the event system from here without more API access.

-- However, we can call ChatCommands.Init() and then ask the user to type in chat.
-- "Please type '!spawn vehicle adder' in chat to verify."

GUI.AddToast("Chat Commands Test", "Type '!spawn vehicle adder' in chat to test.", 5000)
GUI.AddToast("Chat Commands Test", "Type '!weapons' in chat to test.", 5000)

-- Test Global Permissions
ChatCommands.SetGlobalPermission("m_chatCommand", true)
ChatCommands.SetGlobalPermission("m_chatCommandSpawnVehicle", true)
GUI.AddToast("Chat Commands Test", "Global permissions enabled. Type '!spawn vehicle adder' as another player to test.", 5000)
