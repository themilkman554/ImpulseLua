--[[
    Impulse Lua - UIComponent Base Class
    Base class for all window components
]]

local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class UIComponent
---@field parent UIWindow Parent window
local UIComponent = {}
UIComponent.__index = UIComponent

function UIComponent.new()
    local self = setmetatable({}, UIComponent)
    self.parent = nil
    return self
end

--- Get the parent window's content area start position
---@return number, number X and Y of content area top-left
function UIComponent:GetContentPosition()
    if not self.parent then
        return 0.5, 0.5
    end
    local x = self.parent.position.x - self.parent.size.w / 2
    local y = self.parent.position.y - self.parent.size.h / 2 + self.parent.headerHeight
    return x, y
end

--- Get the parent window's content area size
---@return number, number Width and Height
function UIComponent:GetContentSize()
    if not self.parent then
        return 0.2, 0.2
    end
    return self.parent.size.w, self.parent.size.h - self.parent.headerHeight
end

function UIComponent:Update() end
function UIComponent:Render() end
function UIComponent:ScrollEvent(scroll) end

return UIComponent
