--[[
    Impulse Lua - Color Option
    Option that shows a color swatch and opens a color picker submenu
    Port of colorOption.h/cpp from Impulse C++
]]

local Option = require("Impulse/ImpulseLua/lib/options/option")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local Menu = require("Impulse/ImpulseLua/lib/menu")

---@class ColorOption : Option
---@field colorRef table Reference to color table {r, g, b, a}
---@field callback function Function to call on change
local ColorOption = setmetatable({}, { __index = Option })
ColorOption.__index = ColorOption

--- Create a new ColorOption
---@param name string Option name
---@return ColorOption
function ColorOption.new(name)
    local self = setmetatable(Option.new(name), ColorOption)
    self.colorRef = nil
    self.callback = function() end
    self.onUpdate = function(opt) end
    self.currentOp = function() end
    return self
end

--- Set the color reference (table with r, g, b, a keys)
---@param colorTable table Color table with r, g, b, a
---@return ColorOption self for chaining
function ColorOption:AddColor(colorTable)
    self.colorRef = colorTable
    return self
end

--- Set the callback function (called when color changes)
---@param func function Callback to execute
---@return ColorOption self for chaining
function ColorOption:AddFunction(func)
    self.callback = func
    return self
end

--- Set update function (called each frame when visible)
---@param func function Update callback
---@return ColorOption self for chaining
function ColorOption:AddOnUpdate(func)
    self.onUpdate = func
    return self
end

--- Set current operation function (called when selected)
---@param func function Current op callback
---@return ColorOption self for chaining
function ColorOption:AddCurrentOp(func)
    self.currentOp = func
    return self
end

--- Render the color option
---@param position number 0-indexed position
function ColorOption:Render(position)
    -- Call update function
    self.onUpdate(self)
    
    -- Draw option name
    local x = Renderer.Layout.posX - Renderer.Layout.width / 2 + 0.006
    local y = Renderer.GetOptionYText(position)
    
    Renderer.DrawString(self:GetDisplayName(), x, y, Renderer.Layout.textFont,
                       Renderer.Layout.textSize, Renderer.Colors.Option)
    
    -- Draw color swatch if we have a color reference
    if self.colorRef then
        local swatchX = Renderer.Layout.posX + Renderer.Layout.width / 2 - 0.015
        local swatchY = Renderer.GetOptionY(position) + Renderer.Layout.optionHeight / 2
        local swatchW = 0.015
        local swatchH = 0.02
        
        -- Main color rectangle
        local mainColor = {
            r = self.colorRef.r,
            g = self.colorRef.g,
            b = self.colorRef.b,
            a = 255  -- Always draw at full opacity for visibility
        }
        Renderer.DrawRect(swatchX, swatchY, swatchW, swatchH, mainColor)
        
        -- Top edge highlight (lighter)
        local lightColor = Renderer.GetColorOffset(mainColor, 50)
        Renderer.DrawRect(swatchX, swatchY - swatchH / 2 + Renderer.Layout.lineWidth, 
                         swatchW, Renderer.Layout.lineWidth * 2, lightColor)
        
        -- Bottom edge shadow (darker)
        local darkColor = Renderer.GetColorOffset(mainColor, -50)
        Renderer.DrawRect(swatchX, swatchY + swatchH / 2 - Renderer.Layout.lineWidth, 
                         swatchW, Renderer.Layout.lineWidth * 2, darkColor)
    end
end

--- Handle when selected
---@param position number 0-indexed position
function ColorOption:RenderSelected(position)
    self.currentOp()
end

--- Handle Enter press - opens color picker submenu
function ColorOption:OnSelect()
    if not self.requirement() then return end
    if not self.colorRef then return end
    
    -- Instantiate or reuse ColorPickerComponent
    local ColorPickerComponent = require("Impulse/ImpulseLua/lib/ui/color_picker_component")
    -- We can keep a singleton instance or create new. 
    -- Since we only show one at a time, singleton pattern via module or just creating new is fine.
    -- Let's create new for simplicity or use a shared instance if needed.
    -- To keep it clean, let's just create a new one, it's lightweight.
    local picker = ColorPickerComponent.new()
    
    local Menu = require("Impulse/ImpulseLua/lib/menu")
    Menu.activeOverlay = picker
    picker:Show(self.colorRef, function(col)
         -- Callback wrapper
         if self.callback then self.callback() end
    end, self.name)
end

--- Handle left/right input (optional: cycle through preset colors)
function ColorOption:OnLeft()
    -- Could implement preset colors, but for now do nothing
end

function ColorOption:OnRight()
    -- Could implement preset colors, but for now do nothing
end

--- Handle hotkey
function ColorOption:HandleHotkey()
    if not self.requirement() then return end
    -- Open color picker
    self:OnSelect()
    Renderer.NotifyMap("~c~" .. self.name)
end

return ColorOption
