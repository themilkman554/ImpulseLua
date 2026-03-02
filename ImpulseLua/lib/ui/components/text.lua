--[[
    Impulse Lua - UITextComponent
    Simple text display component
]]

local UIComponent = require("Impulse/ImpulseLua/lib/ui/component")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class UITextComponent : UIComponent
---@field lines table Array of text lines
local UITextComponent = setmetatable({}, { __index = UIComponent })
UITextComponent.__index = UITextComponent

--- Create a new text component
---@return UITextComponent
function UITextComponent.new()
    local self = setmetatable(UIComponent.new(), UITextComponent)
    self.lines = {}
    self.lineHeight = 0.018
    self.padding = 0.005
    self.fontSize = 0.3
    return self
end

--- Set a single line of text
---@param text string
---@param color table|nil
function UITextComponent:SetText(text, color)
    self.lines = {{ text = text, color = color or { r = 255, g = 255, b = 255, a = 255 } }}
end

--- Add a line
---@param text string
---@param color table|nil
function UITextComponent:AddLine(text, color)
    table.insert(self.lines, {
        text = text,
        color = color or { r = 255, g = 255, b = 255, a = 255 }
    })
end

--- Clear all text
function UITextComponent:Clear()
    self.lines = {}
end

--- Render the text
function UITextComponent:Render()
    local x, y = self:GetContentPosition()
    
    x = x + self.padding
    y = y + self.padding
    
    for i, line in ipairs(self.lines) do
        local lineY = y + (i - 1) * self.lineHeight
        Renderer.DrawString(
            line.text,
            x, lineY,
            Renderer.Font.ChaletLondon,
            self.fontSize,
            line.color,
            false, 0
        )
    end
end

return UITextComponent
