--[[
    Impulse Lua - UIWindow Class
    Draggable, closeable floating window
    Port of window.h from Impulse C++
]]

local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local Translation = require("Impulse/ImpulseLua/lib/translation")

---@class UIWindow
---@field name string Window title
---@field position table {x, y} position
---@field size table {width, height} size
---@field components table Array of UI components
local UIWindow = {}
UIWindow.__index = UIWindow

--- Create a new UIWindow
---@param name string Window title
---@param canClose boolean Can be closed
---@param x number X position (center)
---@param y number Y position (center)
---@param w number Width
---@param h number Height
---@return UIWindow
function UIWindow.new(name, canClose, x, y, w, h)
    local self = setmetatable({}, UIWindow)
    self.name = name or ""
    self.position = { x = x or 0.5, y = y or 0.5 }
    self.size = { w = w or 0.2, h = h or 0.2 }
    self.components = {}
    
    self.headerHeight = Renderer.Layout.dialogHeaderHeight or 0.035
    self.opacity = 0
    self.targetOpacity = 1
    
    self.minimized = false
    self.canBeClosed = canClose ~= false
    self.canBeMinimized = true
    self.isFading = false
    self.renderName = true
    self.renderEveryFrame = true
    self.visible = false
    
    -- Dragging state
    self.isDragging = false
    self.dragOffset = { x = 0, y = 0 }
    
    return self
end

--- Add a component to the window
---@param component table UI component with render() method
function UIWindow:AddComponent(component)
    table.insert(self.components, component)
    component.parent = self
end

--- Check if point is within window bounds
---@param x number Screen X
---@param y number Screen Y
---@return boolean
function UIWindow:Within(x, y)
    local halfW = self.size.w / 2
    local halfH = self.size.h / 2
    local inX = x >= self.position.x - halfW and x <= self.position.x + halfW
    local inY = y >= self.position.y - halfH and y <= self.position.y + halfH
    
    if self.minimized then
        -- Only header is clickable when minimized
        return inX and y >= self.position.y - halfH and y <= self.position.y - halfH + self.headerHeight
    end
    return inX and inY
end

--- Check if point is within header area
---@param x number Screen X
---@param y number Screen Y
---@return boolean
function UIWindow:WithinHeader(x, y)
    local halfW = self.size.w / 2
    local halfH = self.size.h / 2
    local inX = x >= self.position.x - halfW and x <= self.position.x + halfW
    local inY = y >= self.position.y - halfH and y <= self.position.y - halfH + self.headerHeight
    return inX and inY
end

--- Check if point is over close button
---@param x number Screen X
---@param y number Screen Y
---@return boolean
function UIWindow:WithinCloseButton(x, y)
    if not self.canBeClosed then return false end
    local btnX = self.position.x + self.size.w / 2 - 0.01
    local btnY = self.position.y - self.size.h / 2 + 0.015
    local size = 0.015
    return x >= btnX - size and x <= btnX + size and y >= btnY - size and y <= btnY + size
end

--- Check if point is over minimize button
---@param x number Screen X
---@param y number Screen Y
---@return boolean
function UIWindow:WithinMinimizeButton(x, y)
    if not self.canBeMinimized then return false end
    local offset = self.canBeClosed and 0.0225 or 0.01
    local btnX = self.position.x + self.size.w / 2 - offset
    local btnY = self.position.y - self.size.h / 2 + 0.015
    local size = 0.015
    return x >= btnX - size and x <= btnX + size and y >= btnY - size and y <= btnY + size
end

--- Toggle minimized state
function UIWindow:Minimize()
    self.minimized = not self.minimized
end

--- Show the window with fade in
function UIWindow:Show()
    self.visible = true
    self.targetOpacity = 1
    self.isFading = true
end

--- Hide the window with fade out
function UIWindow:Hide()
    self.targetOpacity = 0
    self.isFading = true
end

--- Close the window
function UIWindow:Close()
    self:Hide()
    -- Will be removed by WindowManager after fade
end

--- Update window state
function UIWindow:Update()
    -- Handle opacity animation
    if self.isFading then
        local speed = 3.0 -- Fade speed
        if self.opacity < self.targetOpacity then
            self.opacity = math.min(self.opacity + speed * 0.016, self.targetOpacity)
        elseif self.opacity > self.targetOpacity then
            self.opacity = math.max(self.opacity - speed * 0.016, self.targetOpacity)
        else
            self.isFading = false
            if self.targetOpacity == 0 then
                self.visible = false
            end
        end
    end
    
    if self.minimized then return end
    
    -- Update components
    for _, component in ipairs(self.components) do
        if component.Update then
            component:Update()
        end
    end
end

--- Render the window
function UIWindow:Render()
    if not self.visible then return end
    if self.opacity <= 0 then return end
    
    -- Set global opacity for drawing
    local prevOpacity = Renderer.globalOpacity
    Renderer.globalOpacity = self.opacity
    
    local xSize = 0.02 * 1.2
    local ySize = 0.03 * 1.2
    local xOffset = 0.01
    local xOffset2 = 0.0225
    local yOffset = 0.015
    
    if self.minimized then
        -- Draw minimized window (just header)
        Renderer.DrawBox(
            self.position.x, 
            self.position.y - self.size.h / 2 + self.headerHeight / 2,
            self.size.w, 
            self.headerHeight, 
            Translation.GetFlat(self.name)
        )
        -- Plus icon (expand)
        Renderer.DrawSprite(
            { dict = "mpleaderboard", name = "leaderboard_plus_icon" },
            self.position.x + self.size.w / 2 - (self.canBeClosed and xOffset2 or xOffset),
            self.position.y - self.size.h / 2 + yOffset,
            xSize, ySize, 0,
            { r = 255, g = 255, b = 255, a = 255 }
        )
    else
        -- Draw full window
        Renderer.DrawBox(
            self.position.x, 
            self.position.y, 
            self.size.w, 
            self.size.h, 
            self.renderName and Translation.GetFlat(self.name) or ""
        )
        
        -- Render components
        for _, component in ipairs(self.components) do
            if component.Render then
                component:Render()
            end
        end
        
        -- Minimize icon (minus)
        if self.canBeMinimized then
            Renderer.DrawSprite(
                { dict = "mpleaderboard", name = "leaderboard_minus_icon" },
                self.position.x + self.size.w / 2 - (self.canBeClosed and xOffset2 or xOffset),
                self.position.y - self.size.h / 2 + yOffset,
                xSize, ySize, 0,
                { r = 255, g = 255, b = 255, a = 255 }
            )
        end
    end
    
    -- Close button (X made from plus rotated 45 degrees)
    if self.canBeClosed then
        Renderer.DrawSprite(
            { dict = "mpleaderboard", name = "leaderboard_plus_icon" },
            self.position.x + self.size.w / 2 - xOffset,
            self.position.y - self.size.h / 2 + yOffset,
            xSize, ySize, 45,
            { r = 255, g = 255, b = 255, a = 255 }
        )
    end
    
    -- Restore opacity
    Renderer.globalOpacity = prevOpacity
end

--- Handle scroll event
---@param scroll number Scroll amount
function UIWindow:ScrollEvent(scroll)
    for _, component in ipairs(self.components) do
        if component.ScrollEvent then
            component:ScrollEvent(scroll)
        end
    end
end

--- Handle mouse input
---@param mouseX number Mouse X
---@param mouseY number Mouse Y
---@param leftClick boolean Left mouse pressed
---@param leftHeld boolean Left mouse held
---@return boolean consumed Whether input was consumed
function UIWindow:HandleInput(mouseX, mouseY, leftClick, leftHeld)
    if not self.visible then return false end
    if not self:Within(mouseX, mouseY) and not self.isDragging then return false end
    
    -- Handle close button
    if leftClick and self:WithinCloseButton(mouseX, mouseY) then
        self:Close()
        return true
    end
    
    -- Handle minimize button
    if leftClick and self:WithinMinimizeButton(mouseX, mouseY) then
        self:Minimize()
        return true
    end
    
    -- Handle dragging
    if leftClick and self:WithinHeader(mouseX, mouseY) then
        self.isDragging = true
        self.dragOffset.x = mouseX - self.position.x
        self.dragOffset.y = mouseY - self.position.y
        return true
    end
    
    if self.isDragging then
        if leftHeld then
            self.position.x = mouseX - self.dragOffset.x
            self.position.y = mouseY - self.dragOffset.y
        else
            self.isDragging = false
        end
        return true
    end
    
    return self:Within(mouseX, mouseY)
end

return UIWindow
