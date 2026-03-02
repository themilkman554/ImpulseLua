--[[
    Impulse Lua - Number Option
    Numeric input with left/right adjustment
    Port of numberOption.h/cpp from Impulse C++
]]

local Option = require("Impulse/ImpulseLua/lib/options/option")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

-- Scroll option types
local ScrollType = {
    SCROLL = 1,     -- Just number adjustment
    TOGGLE = 2,     -- Number with toggle
    SELECT = 3      -- Number as selection index
}

---@class NumberOption : Option
---@field value number The numeric value
---@field step number Step size for adjustment
---@field min number|nil Minimum value
---@field max number|nil Maximum value
---@field format string Format string for display
local NumberOption = setmetatable({}, { __index = Option })
NumberOption.__index = NumberOption
NumberOption.Type = ScrollType

--- Override IsLocked - Numbers are always free
function NumberOption:IsLocked()
    return false
end

--- Create a new NumberOption
---@param optionType number ScrollType enum
---@param name string Option name
---@return NumberOption
function NumberOption.new(optionType, name)
    local self = setmetatable(Option.new(name), NumberOption)
    self.optionType = optionType or ScrollType.SCROLL
    self.value = 0
    self.valueRef = nil
    self.step = 1
    self.min = nil
    self.max = nil
    self.format = "%d"
    self.loop = false
    self.callback = function() end
    self.onUpdate = function(opt) end
    self.currentOp = function() end
    
    -- For toggle type
    self.toggleValue = false
    self.toggleRef = nil
    
    -- Hold acceleration state
    self.leftTimer = 0
    self.rightTimer = 0
    self.leftDisabled = false
    self.rightDisabled = false
    self.scrollSpeed = 100 -- milliseconds between scrolls when holding
    self.lastScrollTime = 0
    
    return self
end

--- Bind number value with format and step
---@param value number Initial value (or table ref)
---@param format string Format string (e.g., "%.2f", "%d")
---@param step number Step size
---@return NumberOption self for chaining
function NumberOption:AddNumber(value, format, step)
    self.value = value
    self.format = format or "%d"
    self.step = step or 1
    return self
end

--- Bind to referenced table value
---@param tbl table Table containing the value
---@param key string Key in table
---@param format string Format string
---@param step number Step size
---@return NumberOption self for chaining
function NumberOption:AddNumberRef(tbl, key, format, step)
    self.valueRef = { tbl = tbl, key = key }
    self.format = format or "%d"
    self.step = step or 1
    return self
end

--- Set minimum value
---@param min number Minimum
---@return NumberOption self for chaining
function NumberOption:AddMin(min)
    self.min = min
    return self
end

--- Set maximum value
---@param max number Maximum
---@return NumberOption self for chaining
function NumberOption:AddMax(max)
    self.max = max
    return self
end

--- Alias methods for compatibility
function NumberOption:SetNumber(tbl, key)
    self.valueRef = { tbl = tbl, key = key }
    return self
end

function NumberOption:SetMin(min)
    self.min = min
    return self
end

function NumberOption:SetMax(max)
    self.max = max
    return self
end

function NumberOption:SetStep(step)
    self.step = step
    return self
end

function NumberOption:SetFormat(format)
    self.format = format
    return self
end

--- Enable looping (wrap around min/max)
---@return NumberOption self for chaining
function NumberOption:CanLoop()
    self.loop = true
    return self
end

--- Add toggle for TOGGLE type
---@param value boolean Initial toggle state
---@return NumberOption self for chaining
function NumberOption:AddToggle(value)
    self.toggleValue = value
    return self
end

--- Bind toggle to a referenced table value
---@param tbl table Table containing the value
---@param key string Key in table
---@return NumberOption self for chaining
function NumberOption:AddToggleRef(tbl, key)
    self.toggleRef = { tbl = tbl, key = key }
    return self
end

--- Set callback function
---@param func function Callback
---@return NumberOption self for chaining
function NumberOption:AddFunction(func)
    self.callback = func
    return self
end

--- Set update function
---@param func function Update callback
---@return NumberOption self for chaining
function NumberOption:AddOnUpdate(func)
    self.onUpdate = func
    return self
end

--- Get the current numeric value
---@return number
function NumberOption:GetValue()
    if self.valueRef then
        return self.valueRef.tbl[self.valueRef.key]
    end
    return self.value
end

--- Set the numeric value
---@param val number
function NumberOption:SetValue(val)
    if type(val) ~= "number" then return end
    
    -- Apply min/max constraints
    if self.min and val < self.min then
        if self.loop and self.max then
            val = self.max
        else
            val = self.min
        end
    end
    if self.max and val > self.max then
        if self.loop and self.min then
            val = self.min
        else
            val = self.max
        end
    end
    
    if self.valueRef then
        self.valueRef.tbl[self.valueRef.key] = val
    else
        self.value = val
    end
end

--- Get toggle state (for TOGGLE type)
---@return boolean
function NumberOption:GetToggle()
    if self.toggleRef then
        return self.toggleRef.tbl[self.toggleRef.key]
    end
    return self.toggleValue
end

--- Set toggle state
---@param val boolean
function NumberOption:SetToggle(val)
    if self.toggleRef then
        self.toggleRef.tbl[self.toggleRef.key] = val
    else
        self.toggleValue = val
    end
end

--- Render the number option
---@param position number 0-indexed position
function NumberOption:Render(position)
    self.onUpdate(self)
    
    -- Format the value display
    local displayValue = string.format(self.format, self:GetValue())
    local hasLeft = self.loop or (self.min == nil or self:GetValue() > self.min)
    local hasRight = self.loop or (self.max == nil or self:GetValue() < self.max)
    local valueText = string.format("%s %s %s", 
        hasLeft and "<" or "", 
        displayValue, 
        hasRight and ">" or "")
    
    -- Draw option name (gray if locked)
    local nameX = Renderer.Layout.posX - Renderer.Layout.width / 2 + 0.006
    local y = Renderer.GetOptionYText(position)
    local textColor = self:GetTextColor()
    
    Renderer.DrawString(self:GetDisplayName(), nameX, y, Renderer.Layout.textFont,
                       Renderer.Layout.textSize, textColor)
    
    -- Draw value on right side
    local valueColor = Renderer.GetColorOffset(Renderer.Colors.Option, -20)
    
    if self.optionType == ScrollType.TOGGLE then
        -- Value with toggle
        local valueX = Renderer.Layout.posX + Renderer.Layout.width / 2 - 0.025
        Renderer.DrawString(valueText, valueX, y, Renderer.Layout.textFont,
                           Renderer.Layout.textSize, valueColor, true, 2, 0, valueX)
        
        -- Toggle sprite
        local toggleX = Renderer.Layout.posX + Renderer.Layout.width / 2 - 0.013
        local toggleY = Renderer.GetOptionY(position) + Renderer.Layout.optionHeight / 2
        local texture = Renderer.GetToggleTexture(self:GetToggle())
        Renderer.DrawSprite(texture, toggleX, toggleY, 0.02, 0.015, 0,
                           { r = 255, g = 255, b = 255, a = 255 })
    else
        -- Just value
        local valueX = Renderer.Layout.posX + Renderer.Layout.width / 2 - 0.01
        Renderer.DrawString(valueText, valueX, y, Renderer.Layout.textFont,
                           Renderer.Layout.textSize, valueColor, true, 2, 0, valueX)
    end
end

--- Handle when selected
---@param position number 0-indexed position
function NumberOption:RenderSelected(position)
    self.currentOp()
    
    -- Control IDs for left/right
    local CONTROL_LEFT = 174
    local CONTROL_LEFT_DPAD = 189
    local CONTROL_RIGHT = 175
    local CONTROL_RIGHT_DPAD = 190
    
    -- Reset timers on just pressed
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, CONTROL_LEFT) or 
       PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, CONTROL_LEFT_DPAD) then
        self.leftDisabled = false
        self.leftTimer = 0
    end
    
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, CONTROL_RIGHT) or 
       PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, CONTROL_RIGHT_DPAD) then
        self.rightDisabled = false
        self.rightTimer = 0
    end
    
    -- Handle left held (acceleration) - 40 frames delay (~667ms)
    if PAD.IS_DISABLED_CONTROL_PRESSED(0, CONTROL_LEFT) or 
       PAD.IS_DISABLED_CONTROL_PRESSED(0, CONTROL_LEFT_DPAD) then
        self.leftTimer = self.leftTimer + 1
        if self.leftTimer > 40 then
            self.leftDisabled = true
            local currentTime = MISC.GET_GAME_TIMER()
            if currentTime - self.lastScrollTime > self.scrollSpeed then
                self:SetValue(self:GetValue() - self.step)
                AUDIO.PLAY_SOUND_FRONTEND(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                if self.optionType == ScrollType.SCROLL or
                   (self.optionType == ScrollType.TOGGLE and self:GetToggle()) then
                    self.callback()
                end
                self.lastScrollTime = currentTime
            end
        end
    end
    
    -- Handle right held (acceleration) - 40 frames delay (~667ms)
    if PAD.IS_DISABLED_CONTROL_PRESSED(0, CONTROL_RIGHT) or 
       PAD.IS_DISABLED_CONTROL_PRESSED(0, CONTROL_RIGHT_DPAD) then
        self.rightTimer = self.rightTimer + 1
        if self.rightTimer > 40 then
            self.rightDisabled = true
            local currentTime = MISC.GET_GAME_TIMER()
            if currentTime - self.lastScrollTime > self.scrollSpeed then
                self:SetValue(self:GetValue() + self.step)
                AUDIO.PLAY_SOUND_FRONTEND(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                if self.optionType == ScrollType.SCROLL or
                   (self.optionType == ScrollType.TOGGLE and self:GetToggle()) then
                    self.callback()
                end
                self.lastScrollTime = currentTime
            end
        end
    end
end

--- Handle Enter press
function NumberOption:OnSelect()
    if self:IsLocked() then
        Renderer.Notify("~r~Donor feature - upgrade to unlock")
        return
    end
    if self.requirement() then
        if self.optionType == ScrollType.TOGGLE then
            self:SetToggle(not self:GetToggle())
        end
        self.callback()
    end
end

--- Handle Left press - decrease value
function NumberOption:OnLeft()
    if self:IsLocked() then return end
    if self.requirement() then
        self:SetValue(self:GetValue() - self.step)
        if self.optionType == ScrollType.SCROLL or 
           (self.optionType == ScrollType.TOGGLE and self:GetToggle()) then
            self.callback()
        end
    end
end

--- Handle Right press - increase value
function NumberOption:OnRight()
    if self:IsLocked() then return end
    if self.requirement() then
        self:SetValue(self:GetValue() + self.step)
        if self.optionType == ScrollType.SCROLL or
           (self.optionType == ScrollType.TOGGLE and self:GetToggle()) then
            self.callback()
        end
    end
end

return NumberOption
