--[[
    Impulse Lua - Text Input Component
    Port of UITextInputComponent from Impulse C++
    Simple text input field with callback on Enter
]]

local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class TextInputComponent
local TextInputComponent = {}
TextInputComponent.__index = TextInputComponent

-- Key mappings (VK code -> {normal, shifted})
-- Based on C++ normalCombinations array
local keyMappings = {
    -- Letters A-Z (0x41 - 0x5A)
    [0x41] = {"a", "A"}, [0x42] = {"b", "B"}, [0x43] = {"c", "C"},
    [0x44] = {"d", "D"}, [0x45] = {"e", "E"}, [0x46] = {"f", "F"},
    [0x47] = {"g", "G"}, [0x48] = {"h", "H"}, [0x49] = {"i", "I"},
    [0x4A] = {"j", "J"}, [0x4B] = {"k", "K"}, [0x4C] = {"l", "L"},
    [0x4D] = {"m", "M"}, [0x4E] = {"n", "N"}, [0x4F] = {"o", "O"},
    [0x50] = {"p", "P"}, [0x51] = {"q", "Q"}, [0x52] = {"r", "R"},
    [0x53] = {"s", "S"}, [0x54] = {"t", "T"}, [0x55] = {"u", "U"},
    [0x56] = {"v", "V"}, [0x57] = {"w", "W"}, [0x58] = {"x", "X"},
    [0x59] = {"y", "Y"}, [0x5A] = {"z", "Z"},
    -- Numbers 0-9 (0x30 - 0x39)
    [0x30] = {"0", ")"}, [0x31] = {"1", "!"}, [0x32] = {"2", "@"},
    [0x33] = {"3", "#"}, [0x34] = {"4", "$"}, [0x35] = {"5", "%"},
    [0x36] = {"6", "^"}, [0x37] = {"7", "&"}, [0x38] = {"8", "*"},
    [0x39] = {"9", "("},
    -- Special keys
    [0xBD] = {"-", "_"},  -- VK_OEM_MINUS
    [0xBB] = {"=", "+"},  -- VK_OEM_PLUS
    [0xBA] = {";", ":"},  -- VK_OEM_1
    [0xBF] = {"/", "?"},  -- VK_OEM_2
    [0xC0] = {"`", "~"},  -- VK_OEM_3
    [0xDB] = {"[", "{"},  -- VK_OEM_4
    [0xDC] = {"\\", "|"}, -- VK_OEM_5
    [0xDD] = {"]", "}"},  -- VK_OEM_6
    [0xDE] = {"'", "\""},  -- VK_OEM_7
    [0xBC] = {",", "<"},  -- VK_OEM_COMMA
    [0xBE] = {".", ">"},  -- VK_OEM_PERIOD
    -- Numpad
    [0x60] = {"0", "0"}, [0x61] = {"1", "1"}, [0x62] = {"2", "2"},
    [0x63] = {"3", "3"}, [0x64] = {"4", "4"}, [0x65] = {"5", "5"},
    [0x66] = {"6", "6"}, [0x67] = {"7", "7"}, [0x68] = {"8", "8"},
    [0x69] = {"9", "9"},
}

-- Key states for just pressed detection
local keyStates = {}

--- Check if a key was just pressed
---@param vk number Virtual key code
---@return boolean
local function IsKeyJustPressed(vk)
    local isPressed = Utils.IsKeyDown(vk)
    local wasPressed = keyStates[vk] or false
    keyStates[vk] = isPressed
    return isPressed and not wasPressed
end

--- Check if shift is held
---@return boolean
local function IsShiftHeld()
    return Utils.IsKeyDown(0x10) -- VK_SHIFT
end

--- Create a new text input component
---@param title string Input field title
---@param callback function Callback when Enter is pressed (receives input text)
---@return TextInputComponent
function TextInputComponent.new(title, callback)
    local self = setmetatable({}, TextInputComponent)
    
    self.title = title or "Input"
    self.callback = callback or function(text) end
    self.inputText = ""
    self.textSelected = false
    self.blink = false
    self.blinkTimer = 0
    self.visible = false
    
    -- Position/size (matching C++ MenuInput::Text)
    self.x = 0.5
    self.y = 0.4
    self.width = 0.2
    self.height = 0.1
    
    return self
end

--- Show the input component
function TextInputComponent:Show()
    self.visible = true
    self.textSelected = true
    self.inputText = ""
    keyStates = {} -- Reset key states
    -- Set Enter key as already pressed to ignore the current frame
    keyStates[0x0D] = true -- VK_RETURN - ignore the Enter that opened us
    keyStates[0x1B] = true -- VK_ESCAPE - also ignore escape initially
    self.showTimer = MISC.GET_GAME_TIMER() -- Track when we showed
    self.ignoreFirstFrame = true -- Skip first frame to avoid instant submit
    
    -- Block menu input while text input is open
    local Menu = require("Impulse/ImpulseLua/lib/menu")
    Menu.inputBlocked = true

end

--- Hide the input component
function TextInputComponent:Hide()
    self.visible = false
    self.textSelected = false
    
    -- Unblock menu input
    local Menu = require("Impulse/ImpulseLua/lib/menu")
    Menu.inputBlocked = false

end

--- Set the callback function
---@param callback function
function TextInputComponent:SetCallback(callback)
    self.callback = callback
end

--- Set the title
---@param title string
function TextInputComponent:SetTitle(title)
    self.title = title
end

--- Update the blinking cursor
function TextInputComponent:UpdateBlink()
    local now = MISC.GET_GAME_TIMER()
    if now - self.blinkTimer > 350 then
        self.blinkTimer = now
        self.blink = not self.blink
    end
end

--- Handle keyboard input for text using VK codes
function TextInputComponent:HandleInput()
    if not self.textSelected then return end
    
    local shifted = IsShiftHeld()
    local ctrlHeld = Utils.IsKeyDown(0xA2) or Utils.IsKeyDown(0xA3) -- VK_LCONTROL or VK_RCONTROL
    
    -- Ctrl+V Paste - check BEFORE regular key mappings
    if ctrlHeld and IsKeyJustPressed(0x56) then
        local clipboardText = Utils.GetClipBoardText()
        if clipboardText and clipboardText ~= "" then
            self.inputText = self.inputText .. clipboardText
        end
        return -- Don't process other keys this frame
    end
    
    -- Check all mapped keys (skip if Ctrl is held to avoid Ctrl+key conflicts)
    if not ctrlHeld then
        for vk, chars in pairs(keyMappings) do
            if IsKeyJustPressed(vk) then
                local char = shifted and chars[2] or chars[1]
                self.inputText = self.inputText .. char
            end
        end
    end
    
    -- Space (VK_SPACE = 0x20)
    if IsKeyJustPressed(0x20) then
        self.inputText = self.inputText .. " "
    end
    
    -- Backspace (VK_BACK = 0x08)
    if IsKeyJustPressed(0x08) then
        if #self.inputText > 0 then
            self.inputText = string.sub(self.inputText, 1, -2)
        end
    end
    
    -- Skip first frame to avoid instant submit from menu enter
    if self.ignoreFirstFrame then
        self.ignoreFirstFrame = false
        return
    end
    
    -- Enter - submit (VK_RETURN = 0x0D or PAD control 201)
    local canSubmit = MISC.GET_GAME_TIMER() - self.showTimer > 200
    local enterPressed = IsKeyJustPressed(0x0D) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 201)
    if enterPressed and canSubmit then
        local textToSubmit = self.inputText
        self:Hide()
        if self.callback and #textToSubmit > 0 then
            self.callback(textToSubmit)
        end
    end
    
    -- Escape - cancel (VK_ESCAPE = 0x1B or PAD control 202)
    local escPressed = IsKeyJustPressed(0x1B) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 202)
    if escPressed and canSubmit then
        self.inputText = ""
        self:Hide()
    end
    
    -- Disable all controls while text input is open (block menu navigation)
    PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
    
    -- Max length
    if #self.inputText > 50 then
        self.inputText = string.sub(self.inputText, 1, 50)
    end
end

--- Render the input component (matching C++ MenuInput::Text layout)
function TextInputComponent:Render()
    if not self.visible then return end
    
    -- Update blink
    self:UpdateBlink()
    
    -- Draw background box (C++: DrawBox(x, y, width, height, g_name, true, m_hDialogBox))
    Renderer.DrawBox(self.x, self.y, self.width, self.height, self.title, true, 
                    Renderer.Textures.DialogBox, false, nil)
    
    -- Draw input field background (C++: DrawRect(0.5, y + 0.02f, width - 0.04f, 0.03f, {80,80,80,160}))
    local inputY = self.y + 0.02
    Renderer.DrawRect(self.x, inputY, self.width - 0.04, 0.03, { r = 80, g = 80, b = 80, a = 160 })
    
    -- Draw input text with cursor (C++: DrawString at x, y, center justified, white, font 0.5)
    local displayText = self.inputText
    if self.blink and self.textSelected then
        displayText = displayText .. "~m~|~s~"
    end
    
    -- C++: DrawString(input, x, y - 0.02f + 0.02f, FontChaletLondon, 0.5f, {255,255,255,255}, false, JustifyCenter, x - width/2, x + width/2)
    Renderer.DrawString(displayText, 
                       self.x, 
                       self.y, 
                       Renderer.Font.ChaletLondon, 0.5, 
                       { r = 255, g = 255, b = 255, a = 255 }, false, 0,
                       self.x - self.width / 2,
                       self.x + self.width / 2)
end

--- Update and render
function TextInputComponent:Update()
    if not self.visible then return false end
    
    self:HandleInput()
    self:Render()
    
    return true -- Block other input while visible
end

--- Get current input text
---@return string
function TextInputComponent:GetInputText()
    return self.inputText
end

--- Check if visible
---@return boolean
function TextInputComponent:IsVisible()
    return self.visible
end

return TextInputComponent
