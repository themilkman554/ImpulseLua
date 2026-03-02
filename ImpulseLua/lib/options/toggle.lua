--[[
    Impulse Lua - Toggle Option
    Toggle switch bound to a boolean
    Port of toggleOption.h/cpp from Impulse C++
]]

local Option = require("Impulse/ImpulseLua/lib/options/option")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class ToggleOption : Option
---@field value boolean|nil Direct value or nil if using valueRef
---@field valueRef table Table containing the value at key 'value'
local ToggleOption = setmetatable({}, { __index = Option })
ToggleOption.__index = ToggleOption

--- Create a new ToggleOption
---@param name string Option name
---@return ToggleOption
function ToggleOption.new(name)
    local self = setmetatable(Option.new(name), ToggleOption)
    self.value = false
    self.valueRef = nil
    self.callback = function() end
    self.onUpdate = function(opt) end
    self.currentOp = function() end
    return self
end

--- Bind to a boolean value (direct)
---@param value boolean Initial value
---@return ToggleOption self for chaining
function ToggleOption:AddToggle(value)
    self.value = value
    return self
end

--- Bind to a referenced table value
---@param tbl table Table containing the value
---@param key string Key in table
---@return ToggleOption self for chaining
function ToggleOption:AddToggleRef(tbl, key)
    self.valueRef = { tbl = tbl, key = key }
    return self
end

--- Get the current toggle value
---@return boolean
function ToggleOption:GetValue()
    if self.valueRef then
        return self.valueRef.tbl[self.valueRef.key]
    elseif type(self.value) == "function" then
        return self.value()
    end
    return self.value
end

--- Set the toggle value
---@param val boolean
function ToggleOption:SetValue(val)
    if self.valueRef then
        self.valueRef.tbl[self.valueRef.key] = val
    elseif type(self.value) ~= "function" then
        self.value = val
    end
end

--- Set callback function (called after toggle)
---@param func function Callback
---@return ToggleOption self for chaining
function ToggleOption:AddFunction(func)
    self.callback = func
    return self
end

--- Set update function
---@param func function Update callback
---@return ToggleOption self for chaining
function ToggleOption:AddOnUpdate(func)
    self.onUpdate = func
    return self
end

--- Set current operation function
---@param func function Current op callback
---@return ToggleOption self for chaining
function ToggleOption:AddCurrentOp(func)
    self.currentOp = func
    return self
end

--- Render the toggle
---@param position number 0-indexed position
function ToggleOption:Render(position)
    -- Call update function
    self.onUpdate(self)
    
    -- Draw option name (gray if locked)
    local x = Renderer.Layout.posX - Renderer.Layout.width / 2 + 0.006
    local y = Renderer.GetOptionYText(position)
    local textColor = self:GetTextColor()
    
    Renderer.DrawString(self:GetDisplayName(), x, y, Renderer.Layout.textFont,
                       Renderer.Layout.textSize, textColor)
    
    -- Draw toggle sprite (dimmed if locked)
    local toggleX = Renderer.Layout.posX + Renderer.Layout.width / 2 - 0.013
    local toggleY = Renderer.GetOptionY(position) + Renderer.Layout.optionHeight / 2
    local texture = Renderer.GetToggleTexture(self:GetValue())
    local spriteAlpha = self:IsLocked() and 100 or 255
    
    Renderer.DrawSprite(texture, toggleX, toggleY, 0.02, 0.015, 0, 
                       { r = 255, g = 255, b = 255, a = spriteAlpha })
end

--- Handle when selected
---@param position number 0-indexed position
function ToggleOption:RenderSelected(position)
    self.currentOp()
end

--- Handle Enter press - toggle value
function ToggleOption:OnSelect()
    if self:IsLocked() then
        Renderer.Notify("~r~Donor feature - upgrade to unlock")
        return
    end
    if self.requirement() then
        self:SetValue(not self:GetValue())
        self.callback()
    end
end

--- Handle hotkey
function ToggleOption:HandleHotkey()
    if self:IsLocked() then return end
    if not self.requirement() then return end
    self:SetValue(not self:GetValue())
    self.callback()
    local state = self:GetValue() and "enabled" or "disabled"
    Renderer.NotifyMap("~c~" .. self.name .. " " .. state)
end

return ToggleOption
