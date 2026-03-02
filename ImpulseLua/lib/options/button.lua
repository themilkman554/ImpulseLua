--[[
    Impulse Lua - Button Option
    Clickable button that executes a callback
    Port of buttonOption.h/cpp from Impulse C++
]]

local Option = require("Impulse/ImpulseLua/lib/options/option")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class ButtonOption : Option
---@field callback function Function to call on select
local ButtonOption = setmetatable({}, { __index = Option })
ButtonOption.__index = ButtonOption

--- Create a new ButtonOption
---@param name string Option name
---@return ButtonOption
function ButtonOption.new(name)
    local self = setmetatable(Option.new(name), ButtonOption)
    self.callback = function() end
    self.onUpdate = function(opt) end
    self.currentOp = function() end
    return self
end

--- Set the callback function
---@param func function Callback to execute
---@return ButtonOption self for chaining
function ButtonOption:AddFunction(func)
    self.callback = func
    return self
end

--- Set update function (called each frame when visible)
---@param func function Update callback
---@return ButtonOption self for chaining
function ButtonOption:AddOnUpdate(func)
    self.onUpdate = func
    return self
end

--- Set current operation function (called when selected)
---@param func function Current op callback
---@return ButtonOption self for chaining
function ButtonOption:AddCurrentOp(func)
    self.currentOp = func
    return self
end

--- Render the button
---@param position number 0-indexed position
function ButtonOption:Render(position)
    -- Call update function
    self.onUpdate(self)
    
    -- Draw option name (gray if locked)
    local x = Renderer.Layout.posX - Renderer.Layout.width / 2 + 0.006
    local y = Renderer.GetOptionYText(position)
    local textColor = self:GetTextColor()
    
    Renderer.DrawString(self:GetDisplayName(), x, y, Renderer.Layout.textFont,
                       Renderer.Layout.textSize, textColor)
end

--- Handle when selected
---@param position number 0-indexed position
function ButtonOption:RenderSelected(position)
    self.currentOp()
end

--- Handle Enter press
function ButtonOption:OnSelect()
    if self:IsLocked() then
        Renderer.Notify("~r~Donor feature - upgrade to unlock")
        return
    end
    if self.requirement() then
        self.callback()
    end
end

--- Handle hotkey
function ButtonOption:HandleHotkey()
    if self:IsLocked() then return end
    if not self.requirement() then return end
    self.callback()
    Renderer.NotifyMap("~c~" .. self.name)
end

return ButtonOption
