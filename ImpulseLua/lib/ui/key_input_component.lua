--[[
    Impulse Lua - Key Input Component
    Port of UIKeyInputComponent from Impulse C++
    Captures a single key press and returns the Virtual Key code
]]

local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local Menu = require("Impulse/ImpulseLua/lib/menu")

---@class KeyInputComponent
local KeyInputComponent = {}
KeyInputComponent.__index = KeyInputComponent

--- Create a new key input component
---@param title string
---@param callback function(vk)
---@return KeyInputComponent
function KeyInputComponent.new(title, callback)
    local self = setmetatable({}, KeyInputComponent)
    
    self.title = title or "Press a key"
    self.callback = callback or function(vk) end
    self.visible = false
    self.blink = false
    self.blinkTimer = 0
    
    -- Position/size (Center screen)
    self.x = 0.5
    self.y = 0.5
    self.width = 0.25
    self.height = 0.1
    
    return self
end

--- Show the input component
function KeyInputComponent:Show()
    self.visible = true
    self.blinkTimer = MISC.GET_GAME_TIMER()
    
    -- Block menu input
    Menu.inputBlocked = true
    
    -- Disable controls
    PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
    
    self.startTime = MISC.GET_GAME_TIMER()
end

--- Hide the input component
function KeyInputComponent:Hide()
    self.visible = false
    
    -- Unblock menu input
    Menu.inputBlocked = false
end

--- Set the callback function
---@param callback function
function KeyInputComponent:SetCallback(callback)
    self.callback = callback
end

--- Update the blinking text
function KeyInputComponent:UpdateBlink()
    local now = MISC.GET_GAME_TIMER()
    if now - self.blinkTimer > 500 then
        self.blinkTimer = now
        self.blink = not self.blink
    end
end

--- Check for any key press
function KeyInputComponent:HandleInput()
    -- Initialize keyStates if needed
    self.keyStates = self.keyStates or {}

    -- Only allow trigger after 1 second delay
    local canTrigger = (MISC.GET_GAME_TIMER() - self.startTime > 1000)

    -- Check for Escape (Cancel)
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 202) then -- Frontend Cancel / Esc
        self:Hide()
        return
    end
    
    local triggeredVk = nil

    -- Check all keys (tracking state to detect new presses)
    for vk = 1, 254 do
        -- Skip Left Mouse (1) as per user request to disallow it
        if vk ~= 1 then
            local isPressed = Utils.IsKeyDown(vk)
            local wasPressed = self.keyStates[vk] or false
            self.keyStates[vk] = isPressed
            
            if canTrigger and isPressed and not wasPressed then
                 triggeredVk = vk
                 break
            end
        end
    end
    
    if triggeredVk then
         self:Hide()
         if self.callback then
            self.callback(triggeredVk)
         end
         return
    end
end

--- Render the component
function KeyInputComponent:Render()
    if not self.visible then return end
    
    self:UpdateBlink()
    
    -- Draw Background
    Renderer.DrawBox(self.x, self.y, self.width, self.height, self.title, true, 
                    Renderer.Textures.DialogBox, false, nil)
                    
    -- Draw prompt
    local text = self.blink and "Press any key..." or ""
    Renderer.DrawString(text, self.x, self.y + 0.02, Renderer.Font.ChaletLondon, 0.5, 
                       { r = 255, g = 255, b = 255, a = 255 }, false, 0,
                       self.x - self.width / 2, self.x + self.width / 2)
end

--- Update loop
function KeyInputComponent:Update()
    if not self.visible then return false end
    
    PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
    self:HandleInput()
    self:Render()
    
    return true
end

--- Check if visible
function KeyInputComponent:IsVisible()
    return self.visible
end

return KeyInputComponent
