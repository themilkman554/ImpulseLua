--[[
    Impulse Lua - Break Option
    Visual separator/header in menu
    Port of breakOption.h/cpp from Impulse C++
]]

local Option = require("Impulse/ImpulseLua/lib/options/option")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class BreakOption : Option
local BreakOption = setmetatable({}, { __index = Option })
BreakOption.__index = BreakOption

--- Create a new BreakOption
---@param name string Break/header text
---@return BreakOption
--- Create a new BreakOption
---@param name string Break/header text
---@return BreakOption
function BreakOption.new(name)
    local isLine = false
    if not name or name == "" then
        name = "________________________"
        isLine = true
    end
    
    local self = setmetatable(Option.new(name), BreakOption)
    self.isBreak = true
    self.isLine = isLine
    return self
end

--- Render the break
---@param position number 0-indexed position
function BreakOption:Render(position)
    local y = Renderer.GetOptionYText(position)
    local posX = Renderer.Layout.posX
    
    local text = ""
    local font = Renderer.Layout.textFont
    local scale = Renderer.Layout.textSize * 1.2
    
    if self.isLine then
        -- C++ Line Style: ~b~__ ~s~________________________ ~b~__~s~
        -- Uses FontHouseScript (1)
        text = "~b~__ ~s~" .. self:GetDisplayName() .. " ~b~__~s~"
        font = 1 -- HouseScript
    else
        -- C++ Normal Style: ~b~[ ~s~NAME ~b~]~s~
        text = "~b~[ ~s~" .. self:GetDisplayName() .. " ~b~]~s~"
    end
    
    -- C++ uses darker option color for base
    -- m_cOption.getOffset(-75)
    local baseColor = Renderer.GetColorOffset(Renderer.Colors.Option, -75)
    
    -- Draw text centered
    Renderer.DrawString(text, posX, y, font, scale, baseColor, true, 0)
end

--- Breaks don't respond to input
function BreakOption:OnSelect() end
function BreakOption:OnLeft() end
function BreakOption:OnRight() end

return BreakOption
