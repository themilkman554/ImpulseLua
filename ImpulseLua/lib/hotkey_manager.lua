--[[
    Impulse Lua - Hotkey Manager
    Port of hotkeyManager.cpp from Impulse C++
    Central manager for registering, tracking, and updating hotkeys globally
]]

local KeyOption = require("Impulse/ImpulseLua/lib/options/key")

---@class HotkeyManager
local HotkeyManager = {}
HotkeyManager.__index = HotkeyManager

local instance = nil

-- Registered hotkeys: { key = int, option = Option }
local registeredHotkeys = {}

-- Key states for "just released" detection
local keyStates = {}

--- Check if a key was just released
---@param vk number Virtual key code
---@return boolean
local function IsKeyJustReleased(vk)
    local isPressed = Utils.IsKeyDown(vk)
    local wasPressed = keyStates[vk] or false
    keyStates[vk] = isPressed
    return wasPressed and not isPressed
end

--- Get singleton instance
---@return HotkeyManager
function HotkeyManager.GetInstance()
    if not instance then
        instance = setmetatable({}, HotkeyManager)
    end
    return instance
end

--- Initialize the hotkey manager
function HotkeyManager:Initialize()
    registeredHotkeys = {}
    keyStates = {}
end

--- Register a hotkey for an option
---@param key number Virtual key code
---@param option Option
function HotkeyManager:RegisterHotkey(key, option)
    -- Remove any existing hotkey for this option
    self:UnregisterHotkeyForOption(option)
    
    -- Add new hotkey
    table.insert(registeredHotkeys, { key = key, option = option })
    option.hotkey = key
end

--- Unregister a hotkey by key
---@param key number Virtual key code
function HotkeyManager:UnregisterHotkey(key)
    for i = #registeredHotkeys, 1, -1 do
        if registeredHotkeys[i].key == key then
            local hotkey = registeredHotkeys[i]
            hotkey.option.hotkey = -1
            table.remove(registeredHotkeys, i)
        end
    end
end

--- Unregister hotkey for a specific option
---@param option Option
function HotkeyManager:UnregisterHotkeyForOption(option)
    for i = #registeredHotkeys, 1, -1 do
        if registeredHotkeys[i].option == option then
            table.remove(registeredHotkeys, i)
        end
    end
    option.hotkey = -1
end

--- Check if a key is already in use
---@param key number Virtual key code
---@return Option|nil Option that uses this key, or nil
function HotkeyManager:IsHotkeyInUse(key)
    for _, hotkey in ipairs(registeredHotkeys) do
        if hotkey.key == key then
            return hotkey.option
        end
    end
    return nil
end

--- Get all registered hotkeys
---@return table Array of {key, option}
function HotkeyManager:GetRegisteredHotkeys()
    return registeredHotkeys
end

--- Update - check for hotkey presses every frame
--- Call this from your main loop
function HotkeyManager:Update()
    local Menu = require("Impulse/ImpulseLua/lib/menu")
    
    -- Don't process hotkeys if menu input is blocked or in text chat
    if Menu.inputBlocked then return end
    if HUD.IS_MP_TEXT_CHAT_TYPING() then return end
    
    -- Check all registered hotkeys (on key release)
    for _, hotkey in ipairs(registeredHotkeys) do
        if IsKeyJustReleased(hotkey.key) then
            if hotkey.option and hotkey.option.HandleHotkey then
                hotkey.option:HandleHotkey()
            end
        end
    end
end

--- Get key name from virtual key code
---@param vk number Virtual key code
---@return string Key name
function HotkeyManager:GetKeyName(vk)
    return KeyOption.GetKeyNameStatic(vk) or ("Key " .. tostring(vk))
end

return HotkeyManager

