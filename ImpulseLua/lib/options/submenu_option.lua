--[[
    Impulse Lua - Submenu Option
    Navigates to a child submenu
    Port of submenuOption.h/cpp from Impulse C++
]]

local Option = require("Impulse/ImpulseLua/lib/options/option")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class SubmenuOption : Option
---@field submenu table The submenu to navigate to
local SubmenuOption = setmetatable({}, { __index = Option })
SubmenuOption.__index = SubmenuOption

--- Create a new SubmenuOption
---@param name string Option name
---@return SubmenuOption
function SubmenuOption.new(name)
    local self = setmetatable(Option.new(name), SubmenuOption)
    self.submenu = nil
    self.onUpdate = function(opt) end
    self.callback = function() end
    self.onDraw = nil -- Custom draw callback for headshots etc
    -- Submenus are navigation only - never auto-lock (only if manually set with SetPaidOnly)
    self.usesFeatureMgr = true
    return self
end

--- Set the submenu to navigate to
---@param submenu table Submenu object
---@return SubmenuOption self for chaining
function SubmenuOption:AddSubmenu(submenu)
    self.submenu = submenu
    return self
end

--- Set update function
---@param func function Update callback
---@return SubmenuOption self for chaining
function SubmenuOption:AddOnUpdate(func)
    self.onUpdate = func
    return self
end

--- Set callback function (called before navigating)
---@param func function Callback
---@return SubmenuOption self for chaining
function SubmenuOption:AddFunction(func)
    self.callback = func
    return self
end

--- Set custom draw function (for headshots, icons, etc)
---@param func function Draw callback(position) returns offset
---@return SubmenuOption self for chaining
function SubmenuOption:AddOnDraw(func)
    self.onDraw = func
    return self
end

--- Render the submenu option
---@param position number 0-indexed position
function SubmenuOption:Render(position)
    self.onUpdate(self)
    
    -- Calculate base positions
    local nameX = Renderer.Layout.posX - Renderer.Layout.width / 2 + 0.006
    local y = Renderer.GetOptionYText(position)
    local textOffset = 0
    
    -- Call custom draw (for headshots) and get offset
    if self.onDraw then
        local offset = self.onDraw(position)
        if offset then
            textOffset = offset
        end
    end
    
    -- Draw option name (offset if headshot drawn, gray if locked)
    local textColor = self:GetTextColor()
    Renderer.DrawString(self:GetDisplayName(), nameX + textOffset, y, Renderer.Layout.textFont,
                       Renderer.Layout.textSize, textColor)
    
    -- Draw arrow indicator on right side
    local arrowX = Renderer.Layout.posX + Renderer.Layout.width / 2 - 0.010
    local arrowY = Renderer.GetOptionY(position) + Renderer.Layout.optionHeight / 2
    
    -- Check for animated arrows first
    if Renderer.animatedArrows then
        -- Use animated arrows (cycling between two frames)
        local currentTime = MISC.GET_GAME_TIMER()
        local frame = math.floor(currentTime / 200) % 2 -- Switch every 200ms
        local arrowName = frame == 0 and "Arrows-v2" or "Arrows-v2-2"
        
        Renderer.DrawSprite({ dict = "Bookmarks", name = arrowName }, 
            arrowX, arrowY, 0.013, 0.021, 0, { r = 255, g = 255, b = 255, a = 255 })
    else
        -- Static arrows based on style (0-5)
        local style = Renderer.arrowStyle or 0
        
        if style == 0 then
            -- Default ImpulseArrow
            Renderer.DrawSprite({ dict = "Bookmarks", name = "ImpulseArrow" }, 
                arrowX, arrowY, 0.015, 0.030, 0, { r = 255, g = 255, b = 255, a = 255 }, false)
        elseif style == 1 then
            -- Golf putting marker (rotated)
            Renderer.DrawSprite({ dict = "golfputting", name = "puttingmarker" }, 
                arrowX, arrowY, 0.010, 0.020, 270, { r = 255, g = 255, b = 255, a = 200 }, false)
        elseif style == 2 then
            -- ImpulseArrow2
            Renderer.DrawSprite({ dict = "Bookmarks", name = "ImpulseArrow2" }, 
                arrowX, arrowY, 0.015, 0.030, 0, { r = 255, g = 255, b = 255, a = 255 }, false)
        elseif style == 3 then
            -- ImpulseArrow3
            Renderer.DrawSprite({ dict = "Bookmarks", name = "ImpulseArrow3" }, 
                arrowX, arrowY, 0.015, 0.030, 0, { r = 255, g = 255, b = 255, a = 200 }, false)
        elseif style == 4 then
            -- Helicopter HUD arrow (rotated)
            Renderer.DrawSprite({ dict = "helicopterhud", name = "hudarrow" }, 
                arrowX, arrowY, 0.008, 0.016, 90, { r = 255, g = 255, b = 255, a = 200 }, false)
        elseif style == 5 then
            -- Hunting wind arrow (rotated)
            Renderer.DrawSprite({ dict = "hunting", name = "huntingwindarrow_32" }, 
                arrowX, arrowY, 0.005, 0.010, 90, { r = 255, g = 255, b = 255, a = 200 }, false)
        else
            -- Fallback to default
            Renderer.DrawSprite({ dict = "Bookmarks", name = "ImpulseArrow" }, 
                arrowX, arrowY, 0.015, 0.030, 0, { r = 255, g = 255, b = 255, a = 255 }, false)
        end
    end
end

--- Handle Enter press - navigate to submenu
function SubmenuOption:OnSelect()
    if self:IsLocked() then
        local Renderer = require("Impulse/ImpulseLua/lib/renderer")
        Renderer.Notify("~r~Donor feature - upgrade to unlock")
        return
    end
    if self.requirement() and self.submenu then
        -- Call callback first
        self.callback()
        -- Get Menu module (avoid circular dependency)
        local Menu = require("Impulse/ImpulseLua/lib/menu")
        Menu.GoToSubmenu(self.submenu)
    end
end

return SubmenuOption
