--[[ 
    Impulse Lua - Color Picker Component
    Port of MenuInput::Col from Impulse C++
    Provides a visual color picker with Hue bar and SV box
]]

local Utils = require("Impulse/ImpulseLua/lib/utils")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local Mouse = require("Impulse/ImpulseLua/lib/mouse")

---@class ColorPickerComponent
local ColorPickerComponent = {}
ColorPickerComponent.__index = ColorPickerComponent

-- Constants
local HUE_BAR_STEPS = 18
local SV_GRID_SIZE = 9
local PICKER_WIDTH = 0.24
local PICKER_HEIGHT = 0.375

--- Create a new color picker component
---@return ColorPickerComponent
function ColorPickerComponent.new()
    local self = setmetatable({}, ColorPickerComponent)
    
    self.visible = false
    self.colorRef = nil -- Reference to color table {r, g, b, a}
    self.callback = nil -- Function to call on update
    self.originalColor = nil -- {r, g, b, a} to revert on cancel
    self.title = "Color Picker"
    
    -- State
    self.hue = 0   -- 0-360
    self.sat = 0   -- 0-1
    self.val = 1   -- 0-1
    self.alpha = 1 -- 0-1
    
    -- Selection indices (for keyboard navigation/grid drawing)
    self.sX = 9 -- Saturation index (0-9)
    self.sY = 0 -- Value index (0-9) - 0 is top (high val), 9 is bottom (low val)
    
    self.sliderSelected = false -- Is hue slider selected?
    self.mouseDragging = false
    
    -- Position (Centered)
    self.x = 0.5
    self.y = 0.5
    
    return self
end

--- Show the picker
---@param colorRef table Color table {r, g, b, a}
---@param callback function(color) Called when color updates
---@param title string Title of the picker
function ColorPickerComponent:Show(colorRef, callback, title)
    self.colorRef = colorRef
    self.callback = callback
    self.title = title or "Color Picker"
    self.visible = true
    
    -- Store original color for cancellation
    self.originalColor = { r = colorRef.r, g = colorRef.g, b = colorRef.b, a = colorRef.a }
    
    -- Initialize HSV from current color
    local h, s, v = Utils.RGBToHSV(colorRef.r, colorRef.g, colorRef.b)
    self.hue = h
    self.sat = s
    self.val = v
    self.alpha = colorRef.a / 255
    
    -- Map S/V to grid indices (approximate)
    self.sX = math.floor(self.sat * 9 + 0.5)
    self.sY = math.floor((1 - self.val) * 9 + 0.5)
    
    -- Ensure bounds
    self.sX = Utils.Clamp(self.sX, 0, 9)
    self.sY = Utils.Clamp(self.sY, 0, 9)
    
    -- Enable mouse if not already
    -- Mouse.isActive is not a standard export, check PAD usage in menu.lua
    -- We'll assume Menu handles enabling mouse if Settings.MouseEnabled is true.
    -- If we need to force it, we might need a Mouse.ForceEnable() but let's stick to standard behavior.
    
    -- Block menu input
    local Menu = require("Impulse/ImpulseLua/lib/menu")
    Menu.inputBlocked = true
end

--- Hide the picker
---@param apply boolean Whether to keep changes (true) or revert (false)
function ColorPickerComponent:Hide(apply)
    self.visible = false
    
    if not apply and self.originalColor and self.colorRef then
        self.colorRef.r = self.originalColor.r
        self.colorRef.g = self.originalColor.g
        self.colorRef.b = self.originalColor.b
        self.colorRef.a = self.originalColor.a
        if self.callback then self.callback(self.colorRef) end
    end
    
    -- Unblock menu input
    local Menu = require("Impulse/ImpulseLua/lib/menu")
    Menu.inputBlocked = false
    Menu.activeOverlay = nil
end

--- Update color from HSV state
function ColorPickerComponent:UpdateColor()
    local rgb = Utils.HSVToRGB(self.hue, self.sat, self.val)
    if self.colorRef then
        self.colorRef.r = rgb.r
        self.colorRef.g = rgb.g
        self.colorRef.b = rgb.b
        -- Alpha remains unchanged unless we add alpha slider later
        
        if self.callback then self.callback(self.colorRef) end
    end
end

--- Handle input and logic
function ColorPickerComponent:Update()
    if not self.visible then return end
    
    local Menu = require("Impulse/ImpulseLua/lib/menu")
    
    -- Dimensions (matching C++)
    local x, y = self.x, self.y
    local width, height = PICKER_WIDTH, PICKER_HEIGHT
    
    -- 1. Mouse Interaction
    if Mouse.ButtonJustDown(Mouse.LEFT_BUTTON) then
        -- Check Hue Bar click
        if Mouse.MouseWithinCentered(x, y - 2 * 0.022 - 0.055, 18 * 0.011, 0.02) then
            self.sliderSelected = true
            self.mouseDragging = true
        end
        
        -- Check SV Grid click
        for xx = 0, 9 do
            for yy = 0, 9 do
                local rectX = x + xx * 0.022 - 0.099
                local rectY = y + yy * 0.022 - 0.055
                if Mouse.MouseWithinCentered(rectX, rectY, 0.02, 0.02) then
                   self.sliderSelected = false
                   self.sX = xx
                   self.sY = yy
                   self.sat = xx / 9
                   self.val = 1 - (yy / 9)
                   self:UpdateColor()
                   self.mouseDragging = true -- Allow dragging in grid? C++ logic suggests specific check
                end
            end
        end
    end
    
    if not Mouse.ButtonDown(Mouse.LEFT_BUTTON) then
        self.mouseDragging = false
    end
    
    if self.mouseDragging then
        if self.sliderSelected then
            -- Dragging Hue Slider
            -- Hue bar width is 18 * 0.011 = 0.198
            -- Start X is x - 0.099 (center - half width)
            local barStart = x - 0.099
            local barWidth = 18 * 0.011
            local mouseRel = Mouse.X - barStart
            local hueRatio = mouseRel / barWidth
            
            self.hue = Utils.Clamp(hueRatio * 360, 0, 360)
            self.sY = 0 -- Reset value index to top? C++ does `sY = 0;`
            self:UpdateColor()
        else
            -- Dragging SV Grid (Optional enhancement, C++ didn't explicitly show grid drag in the snippet but it helps)
            -- Map Mouse to Grid
            local gridStartX = x - 0.099 - 0.011 -- approx
            local gridStartY = y - 0.055 - 0.011 -- approx
             -- Actually let's use the grid logic from C++ render loop: 
             -- `x + xx * 0.022 - 0.099`
             -- Solve for xx: (MouseX - x + 0.099) / 0.022
             local xx = math.floor((Mouse.X - x + 0.099 + 0.011) / 0.022) 
             local yy = math.floor((Mouse.Y - y + 0.055 + 0.011) / 0.022)
             
             if not self.sliderSelected and Mouse.MouseWithinCentered(x, y + 2 * 0.022, 0.22, 0.22) then
                 self.sX = Utils.Clamp(xx, 0, 9)
                 self.sY = Utils.Clamp(yy, 0, 9)
                 self.sat = self.sX / 9
                 self.val = 1 - (self.sY / 9)
                 self:UpdateColor()
             end
        end
    end
    
    -- 2. Keyboard/Controller Navigation
    -- Up
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 172) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 27) then
         if self.sY > 0 then
             self.sY = self.sY - 1
             self.sliderSelected = false
         else
             self.sliderSelected = true
         end
         if not self.sliderSelected then
             self.val = 1 - (self.sY / 9)
             self:UpdateColor()
         end
    end
    
    -- Down
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 173) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 19) then
         if self.sliderSelected then
             self.sliderSelected = false
         elseif self.sY < 9 then
             self.sY = self.sY + 1
         end
         if not self.sliderSelected then
             self.val = 1 - (self.sY / 9)
             self:UpdateColor()
         end
    end
    
    -- Left
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 174) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 189) then
         if self.sliderSelected then
             self.hue = self.hue - 10
             if self.hue < 0 then self.hue = 360 end
             self:UpdateColor()
         else
             if self.sX > 0 then self.sX = self.sX - 1 end
             self.sat = self.sX / 9
             self:UpdateColor()
         end
    end
    
    -- Right
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 175) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 190) then
         if self.sliderSelected then
             self.hue = self.hue + 10
             if self.hue > 360 then self.hue = 0 end
             self:UpdateColor()
         else
             if self.sX < 9 then self.sX = self.sX + 1 end
             self.sat = self.sX / 9
             self:UpdateColor()
         end
    end
    
    -- Enter/Accept
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 201) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 191) then
        self:Hide(true)
    end
    
    -- Back/Cancel
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 202) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, 194) then
        self:Hide(false)
    end
end

--- Render the picker
function ColorPickerComponent:Render()
    if not self.visible then return end
    
    local x, y = self.x, self.y
    local width, height = PICKER_WIDTH, PICKER_HEIGHT
    
    -- Background
    Renderer.DrawBox(x, y, width, height, self.title, true, Renderer.Textures.DialogBox, false, nil)
    
    -- Current color preview details (optional, maybe hex code?)
    -- C++: DrawRect(0.5, 0.55f, width - 0.04f, 0.034f, {50,50,50,160})
    Renderer.DrawRect(0.5, 0.55, width - 0.04, 0.034, { r = 50, g = 50, b = 50, a = 160 })
    
    -- Draw Hue Bar (Gradient approximated by slices)
    -- X range: x - 0.099 to x + 0.099 (approx)
    for xx = 0, 18 do
        local h = xx * 20
        local color = Utils.HSVToRGB(h, 1, 1)
        color.a = 255
        Renderer.DrawRect(x + xx * 0.011 - 0.099, y - 2 * 0.022 - 0.055, 0.011, 0.02, color)
    end
    
    -- Draw SV Grid
    -- 10x10 grid (0-9)
    for xx = 0, 9 do
        for yy = 0, 9 do
            local sat = xx / 9
            local val = 1 - (yy / 9)
            local color = Utils.HSVToRGB(self.hue, sat, val)
            color.a = 255
            
            -- If this is the selected cell and NOT slider selected mode
            if not self.sliderSelected and xx == self.sX and yy == self.sY then
                 -- Highlight selected cell
                 -- Draw bigger or border? C++ just draws it normally but we need highlight
                 -- C++ logic: `if (!(xx == sX && yy == sY && !sliderSelected))` draws normal
                 -- Then later draws box.
                 
                 -- We'll draw a white border box later for selection.
            end
            
            Renderer.DrawRect(x + xx * 0.022 - 0.099, y + yy * 0.022 - 0.055, 0.02, 0.02, color)
        end
    end
    
    -- Draw Selection Indicator
    if self.sliderSelected then
        -- Indicator on Hue Bar
        local hueRatio = self.hue / 360
        -- Start: x - 0.099
        -- Full Width: 18 * 0.011 = 0.198
        local indX = (x - 0.099) + (hueRatio * 0.198)
        
        -- Draw white box around hue pos
        Renderer.DrawBox(indX, y - 2 * 0.022 - 0.055, 0.015, 0.03, "", false, {dict="", name=""}, true, {r=255,g=255,b=255,a=255})
    else
        -- Indicator on Grid
        local indX = x + self.sX * 0.022 - 0.099
        local indY = y + self.sY * 0.022 - 0.055
        
        -- White border
        Renderer.DrawRect(indX, indY, 0.026, 0.026, {r=255,g=255,b=255,a=255})
        -- Redraw inner color
        local color = Utils.HSVToRGB(self.hue, self.sat, self.val)
        color.a = 255
        Renderer.DrawRect(indX, indY, 0.02, 0.02, color)
    end
    
    -- Draw text info (RGB values)
    if self.colorRef then
        local text = string.format("R: %d  G: %d  B: %d", self.colorRef.r, self.colorRef.g, self.colorRef.b)
        Renderer.DrawString(text, 0.5, 0.55 - 0.01, Renderer.Font.ChaletComprimeCologne, 0.35, {r=255,g=255,b=255,a=255}, false, 0)
    end
end

return ColorPickerComponent
