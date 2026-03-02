--[[
    Impulse Lua - UILoggerComponent
    Scrollable log/text display component
    Port of loggerComponent.h from Impulse C++
]]

local UIComponent = require("Impulse/ImpulseLua/lib/ui/component")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class UILoggerComponent : UIComponent
---@field lines table Array of log lines
---@field maxLines number Maximum lines to display
---@field scrollOffset number Current scroll offset
local UILoggerComponent = setmetatable({}, { __index = UIComponent })
UILoggerComponent.__index = UILoggerComponent

--- Create a new logger component
---@param maxLines number Maximum visible lines
---@return UILoggerComponent
function UILoggerComponent.new(maxLines)
    local self = setmetatable(UIComponent.new(), UILoggerComponent)
    self.lines = {}
    self.maxLines = maxLines or 10
    self.scrollOffset = 0
    self.lineHeight = 0.018
    self.padding = 0.005
    return self
end

--- Add a line to the log
---@param text string Line text
---@param color table|nil Optional color {r, g, b, a}
function UILoggerComponent:AddLine(text, color)
    table.insert(self.lines, {
        text = text,
        color = color or { r = 255, g = 255, b = 255, a = 255 },
        time = os.time()
    })
    
    -- Auto-scroll to bottom
    if #self.lines > self.maxLines then
        self.scrollOffset = #self.lines - self.maxLines
    end
end

--- Clear all lines
function UILoggerComponent:Clear()
    self.lines = {}
    self.scrollOffset = 0
end

--- Handle scroll event
---@param scroll number Scroll direction
function UILoggerComponent:ScrollEvent(scroll)
    self.scrollOffset = self.scrollOffset - scroll
    self.scrollOffset = math.max(0, math.min(self.scrollOffset, math.max(0, #self.lines - self.maxLines)))
end

--- Render the log
function UILoggerComponent:Render()
    local x, y = self:GetContentPosition()
    local w, h = self:GetContentSize()
    
    -- Match offset from system_data component
    local offset = 0.055
    x = x + offset
    y = y + self.padding
    
    -- Draw visible lines
    local startIdx = self.scrollOffset + 1
    local endIdx = math.min(startIdx + self.maxLines - 1, #self.lines)
    
    for i = startIdx, endIdx do
        local line = self.lines[i]
        if line then
            local lineY = y + (i - startIdx) * self.lineHeight
            Renderer.DrawString(
                line.text,
                x, lineY,
                Renderer.Font.ChaletLondon,
                0.3,
                line.color,
                false, 0
            )
        end
    end
    
    -- Draw scroll indicator if needed
    if #self.lines > self.maxLines then
        local scrollBarX = x + w - self.padding * 3
        local scrollBarH = h - self.padding * 2
        local thumbH = scrollBarH * (self.maxLines / #self.lines)
        local thumbY = y + (self.scrollOffset / (#self.lines - self.maxLines)) * (scrollBarH - thumbH)
        
        -- Scrollbar background
        Renderer.DrawRect(scrollBarX, y + scrollBarH / 2, 0.003, scrollBarH, { r = 50, g = 50, b = 50, a = 150 })
        -- Scrollbar thumb
        Renderer.DrawRect(scrollBarX, thumbY + thumbH / 2, 0.003, thumbH, { r = 150, g = 150, b = 150, a = 200 })
    end
end

return UILoggerComponent
