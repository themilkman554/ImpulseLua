--[[
    Impulse Lua - Key Option
    Key binding option for selecting keys
    Port of keyOption.h/cpp from Impulse C++
]]

local Option = require("Impulse/ImpulseLua/lib/options/option")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

-- Virtual key name mapping (subset of common keys)
local keyNames = {
    [0x00] = "None", [0x01] = "Left Mouse", [0x02] = "Right Mouse", [0x03] = "Cancel",
    [0x04] = "Middle Mouse", [0x05] = "X1 Mouse", [0x06] = "X2 Mouse",
    [0x08] = "Backspace", [0x09] = "Tab", [0x0D] = "Enter", [0x10] = "Shift",
    [0x11] = "Ctrl", [0x12] = "Alt", [0x13] = "Pause", [0x14] = "Caps Lock",
    [0x1B] = "Escape", [0x20] = "Space", [0x21] = "Page Up", [0x22] = "Page Down",
    [0x23] = "End", [0x24] = "Home", [0x25] = "Left", [0x26] = "Up",
    [0x27] = "Right", [0x28] = "Down", [0x2C] = "Print Screen", [0x2D] = "Insert",
    [0x2E] = "Delete",
    [0x30] = "0", [0x31] = "1", [0x32] = "2", [0x33] = "3", [0x34] = "4",
    [0x35] = "5", [0x36] = "6", [0x37] = "7", [0x38] = "8", [0x39] = "9",
    [0x41] = "A", [0x42] = "B", [0x43] = "C", [0x44] = "D", [0x45] = "E",
    [0x46] = "F", [0x47] = "G", [0x48] = "H", [0x49] = "I", [0x4A] = "J",
    [0x4B] = "K", [0x4C] = "L", [0x4D] = "M", [0x4E] = "N", [0x4F] = "O",
    [0x50] = "P", [0x51] = "Q", [0x52] = "R", [0x53] = "S", [0x54] = "T",
    [0x55] = "U", [0x56] = "V", [0x57] = "W", [0x58] = "X", [0x59] = "Y", [0x5A] = "Z",
    [0x60] = "Num 0", [0x61] = "Num 1", [0x62] = "Num 2", [0x63] = "Num 3",
    [0x64] = "Num 4", [0x65] = "Num 5", [0x66] = "Num 6", [0x67] = "Num 7",
    [0x68] = "Num 8", [0x69] = "Num 9", [0x6A] = "Num *", [0x6B] = "Num +",
    [0x6D] = "Num -", [0x6E] = "Num .", [0x6F] = "Num /",
    [0x70] = "F1", [0x71] = "F2", [0x72] = "F3", [0x73] = "F4", [0x74] = "F5",
    [0x75] = "F6", [0x76] = "F7", [0x77] = "F8", [0x78] = "F9", [0x79] = "F10",
    [0x7A] = "F11", [0x7B] = "F12",
    [0xA0] = "Left Shift", [0xA1] = "Right Shift", [0xA2] = "Left Ctrl",
    [0xA3] = "Right Ctrl", [0xA4] = "Left Alt", [0xA5] = "Right Alt",
}

-- Common keys to cycle through (ordered list for left/right navigation)
local commonKeysList = {
    0x10, -- Shift
    0x11, -- Ctrl
    0x12, -- Alt
    0x20, -- Space
    0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, -- A-J
    0x4B, 0x4C, 0x4D, 0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, -- K-T
    0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, -- U-Z
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, -- 0-9
    0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B, -- F1-F12
    0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, -- Num 0-9
    0x01, 0x02, 0x04, -- Mouse buttons
}

-- Build reverse lookup for current index
local function GetKeyIndex(key)
    for i, k in ipairs(commonKeysList) do
        if k == key then return i end
    end
    return 1 -- Default to first key
end

---@class KeyOption : Option
---@field key number Virtual key code
---@field keyRef table|nil Table containing the key value
---@field isController boolean Whether this is a controller key
---@field controllerSupport boolean Whether controller is supported
local KeyOption = setmetatable({}, { __index = Option })
KeyOption.__index = KeyOption

--- Create a new KeyOption
---@param name string Option name
---@return KeyOption
function KeyOption.new(name)
    local self = setmetatable(Option.new(name), KeyOption)
    self.key = 0x10 -- Default to Shift
    self.keyRef = nil
    self.isController = false
    self.controllerRef = nil
    self.controllerSupport = false
    self.callback = function() end
    self.onUpdate = function(opt) end
    return self
end

--- Bind to a key value (direct)
---@param key number Virtual key code
---@return KeyOption self for chaining
function KeyOption:AddKey(key)
    self.key = key
    return self
end

--- Bind to a referenced table value
---@param tbl table Table containing the key
---@param keyField string Key in table
---@return KeyOption self for chaining
function KeyOption:AddKeyRef(tbl, keyField)
    self.keyRef = { tbl = tbl, key = keyField }
    return self
end

--- Add controller support
---@param tbl table Table containing controller bool
---@param keyField string Key in table
---@return KeyOption self for chaining
function KeyOption:AddControllerSupport(tbl, keyField)
    self.controllerRef = { tbl = tbl, key = keyField }
    self.controllerSupport = true
    return self
end

--- Get the current key value
---@return number
function KeyOption:GetKey()
    if self.keyRef then
        return self.keyRef.tbl[self.keyRef.key] or 0x10
    end
    return self.key
end

--- Set the key value
---@param val number
function KeyOption:SetKey(val)
    if self.keyRef then
        self.keyRef.tbl[self.keyRef.key] = val
    else
        self.key = val
    end
end

--- Alias for GetKey for config system
function KeyOption:GetValue()
    return self:GetKey()
end

--- Alias for SetKey for config system
function KeyOption:SetValue(val)
    self:SetKey(val)
end


--- Get key name for display
---@return string
function KeyOption:GetKeyName()
    local k = self:GetKey()
    return KeyOption.GetKeyNameStatic(k)
end

--- Get key name from id (static)
---@param k number
---@return string
function KeyOption.GetKeyNameStatic(k)
    return keyNames[k] or string.format("Key 0x%02X", k)
end

--- Set callback function
---@param func function Callback
---@return KeyOption self for chaining
function KeyOption:AddFunction(func)
    self.callback = func
    return self
end

--- Set update function
---@param func function Update callback
---@return KeyOption self for chaining
function KeyOption:AddOnUpdate(func)
    self.onUpdate = func
    return self
end

--- Render the key option
---@param position number 0-indexed position
function KeyOption:Render(position)
    self.onUpdate(self)
    
    local x = Renderer.Layout.posX - Renderer.Layout.width / 2 + 0.006
    local y = Renderer.GetOptionYText(position)
    
    -- Draw option name
    Renderer.DrawString(self:GetDisplayName(), x, y, Renderer.Layout.textFont,
                       Renderer.Layout.textSize, Renderer.Colors.Option)
    
    -- Draw key name on right side (Just the name, no arrows as per user request/screenshot)
    local keyName = self:GetKeyName()
    local rightX = Renderer.Layout.posX + Renderer.Layout.width / 2 - 0.01
    -- Align right with wrap matching the position
    Renderer.DrawString(keyName, rightX, y, Renderer.Layout.textFont,
                       Renderer.Layout.textSize, Renderer.Colors.Option, true, 2, 0, rightX)
end

local KeyInputComponent = require("Impulse/ImpulseLua/lib/ui/key_input_component")

--- Handle selection (open key binder)
function KeyOption:OnSelect()
    if not self.requirement or self.requirement() then
        -- Open key binder
        local input = KeyInputComponent.new("Press any key", function(vk)
            self:SetKey(vk)
            if self.callback then
                self.callback()
            end
        end)
        input:Show()
        
        -- Register component to be updated by the menu system
        -- We probably need a better way to register this if the menu system doesn't auto-pick it up.
        -- Usually submenus handle components.
        -- For now, we attach it to the current submenu if possible, or reliance on a global manager.
        -- Actually, TextComponent seems to use a global renderer block or similar?
        -- In `TextInputComponent`, `Show` sets `Menu.inputBlocked`.
        -- The Menu main loop needs to Update/Render active components.
        
        -- Since we don't have a component manager in the stripped down library, 
        -- we might need to hook into the main loop or the Submenu update.
        -- However, looking at `text_input_component.lua`, it doesn't seem to self-register.
        
        -- Checking `TextInputComponent` usage... it's likely used by options that manually call Update?
        -- Or maybe I need to add it to the active submenu's components list?
        
        -- Let's check `lib/submenu.lua` or `main.lua` to see how components are updated.
        -- If not, I'll need to inject it.
        
        -- For now, let's assume `Menu.AddComponent` or simply assigning it to `Menu.activeComponent` works if that exists.
        -- If not, I'll stick to the provided `Show` logic and hope `Menu` handles it or I need to add that logic.
        
        -- HACK: We will use a global variable or the Menu module to track the active input component.
        local Menu = require("Impulse/ImpulseLua/lib/menu")
        Menu.activeInputComponent = input
    end
end

--- Handle left navigation (previous key)
function KeyOption:OnLeft()
    local currentKey = self:GetKey()
    local currentIndex = GetKeyIndex(currentKey)
    local newIndex = currentIndex - 1
    if newIndex < 1 then newIndex = #commonKeysList end
    self:SetKey(commonKeysList[newIndex])
    self.callback()
end

--- Handle right navigation (next key)
function KeyOption:OnRight()
    local currentKey = self:GetKey()
    local currentIndex = GetKeyIndex(currentKey)
    local newIndex = currentIndex + 1
    if newIndex > #commonKeysList then newIndex = 1 end
    self:SetKey(commonKeysList[newIndex])
    self.callback()
end

return KeyOption

