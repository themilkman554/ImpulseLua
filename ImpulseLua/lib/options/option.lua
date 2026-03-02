--[[
    Impulse Lua - Base Option Class
    Base class for all menu options
    Port of option.h from Impulse C++
]]

local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local PaidTier = require("Impulse/ImpulseLua/lib/paid_tier")
local Translation = require("Impulse/ImpulseLua/lib/translation")

---@class Option
---@field name string Display name
---@field tooltip string Tooltip text
---@field visible boolean Visibility state
---@field isBreak boolean Is this a break/separator
---@field hasHotkey boolean Has hotkey bound
---@field hotkey number Hotkey code
---@field requirement function Visibility requirement function
---@field usesFeatureMgr boolean|nil Cached result of FeatureMgr check
local Option = {}
Option.__index = Option

--- Create a new Option
---@param name string Option name
---@return Option
function Option.new(name)
    local self = setmetatable({}, Option)
    self.name = name or ""
    self.tooltip = ""
    self.visible = true
    self.isBreak = false
    self.hasHotkey = false
    self.hotkey = -1
    self.canBeSaved = false
    self.requirement = function() return true end
    self.hoverTimer = 0
    self.hoverTimer = 0
    self.isDonor = false -- Default: Free for everyone
    return self
end

--- Check if this option is locked (paid-only AND user is free)
---@return boolean
function Option:IsLocked()
    -- Paid users never see locked features
    if PaidTier.IsPaid() then
        return false
    end
    
    -- If manually marked as Donor only, it's locked for free users
    if self.isDonor then
        return true
    end
    
    -- Default is FREE
    return false
end



--- Mark this option as Donor only (Locked for free users)
---@return Option self for chaining
function Option:SetDonor()
    self.isDonor = true
    return self
end

--- Manually mark this option as paid-only (Legacy alias for SetDonor)
---@return Option self for chaining
function Option:SetPaidOnly()
    self.isDonor = true
    return self
end

--- Get the text color for this option (gray if locked)
---@return table Color
function Option:GetTextColor()
    if self:IsLocked() then
        return Renderer.Colors.Disabled
    end
    return Renderer.Colors.Option
end

--- Check if option should be visible
---@return boolean
function Option:IsVisible()
    return self.visible and self.requirement()
end

--- Set visibility requirement function
---@param func function Returns boolean
---@return Option self for chaining
function Option:AddRequirement(func)
    self.requirement = func
    return self
end

--- Set tooltip text
---@param text string Tooltip text
---@return Option self for chaining
function Option:AddTooltip(text)
    self.tooltip = text
    return self
end

--- Enable hotkey for this option
---@return Option self for chaining
function Option:AddHotkey()
    self.hasHotkey = true
    return self
end

--- Set the option name
---@param name string New name
function Option:SetName(name)
    self.name = name
end

--- Get the display name (translated if a language is loaded)
---@return string
function Option:GetDisplayName()
    if Translation.IsLoaded() then
        return Translation.GetFlat(self.name)
    end
    return self.name
end

--- Get the display tooltip (translated if a language is loaded)
---@return string
function Option:GetDisplayTooltip()
    if Translation.IsLoaded() and self.tooltip ~= "" then
        return Translation.GetFlat(self.tooltip)
    end
    return self.tooltip
end

--- Render the option at given position
---@param position number 0-indexed position
function Option:Render(position)
    -- Base implementation - draw option name (gray if locked)
    local x = Renderer.Layout.posX - Renderer.Layout.width / 2 + 0.006
    local y = Renderer.GetOptionYText(position)
    local textColor = self:GetTextColor()
    
    Renderer.DrawString(self:GetDisplayName(), x, y, Renderer.Layout.textFont, 
                       Renderer.Layout.textSize, textColor)
end

--- Called when option is selected (highlighted)
---@param position number 0-indexed position
function Option:RenderSelected(position)
    -- Override in subclasses for selected state rendering
    -- Default: update tooltip
end

--- Called when Enter is pressed on this option
function Option:OnSelect()
    -- Override in subclasses
end

--- Called when Left is pressed on this option
function Option:OnLeft()
    -- Override in subclasses
end

--- Called when Right is pressed on this option
function Option:OnRight()
    -- Override in subclasses
end

--- Handle hotkey press
function Option:HandleHotkey()
    -- Override in subclasses
end

return Option
