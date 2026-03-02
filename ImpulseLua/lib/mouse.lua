--[[
    Impulse Lua - Mouse Input Manager
    Handles mouse coordinates, clicks, and state
    Port of input.cpp/mouse.cpp components
]]

local Mouse = {}

-- State
Mouse.X = 0.5
Mouse.Y = 0.5
Mouse.isActive = false

-- Button states
Mouse.LEFT_BUTTON = 237 -- Cursor Click (Left)
Mouse.RIGHT_BUTTON = 238 -- Cursor Click (Right) -- Actually 238 is mostly unused, usually we check AIM (25) or similar, but 238 is CURSOR_ACCEPT/CANCEL sometimes. 


Mouse.SCROLL_UP = 241
Mouse.SCROLL_DOWN = 242

-- Cursor Sprites
Mouse.SPRITE_NORMAL = { dict = "commonmenu", name = "arrowright" }
Mouse.SPRITE_HAND = { dict = "commonmenu", name = "hand" } 


Mouse.cursorSprite = Mouse.SPRITE_NORMAL
Mouse.cursorRotation = -45 -- Initial rotation for arrow to point up-left-ish? 


function Mouse.Init()
    Mouse.X = PAD.GET_DISABLED_CONTROL_NORMAL(2, 239)
    Mouse.Y = PAD.GET_DISABLED_CONTROL_NORMAL(2, 240)
end

--- Update mouse state
function Mouse.Update()
    if not GUI.IsOpen() then return end
    Mouse.X = PAD.GET_DISABLED_CONTROL_NORMAL(2, 239)
    Mouse.Y = PAD.GET_DISABLED_CONTROL_NORMAL(2, 240)

end

--- Check if mouse button is pressed
---@param button number Control ID (default Mouse.LEFT_BUTTON)
---@return boolean
function Mouse.ButtonDown(button)
    button = button or Mouse.LEFT_BUTTON
    return PAD.IS_DISABLED_CONTROL_PRESSED(2, button)
end

--- Check if mouse button was just pressed
---@param button number Control ID
---@return boolean
function Mouse.ButtonJustDown(button)
    button = button or Mouse.LEFT_BUTTON
    return PAD.IS_DISABLED_CONTROL_JUST_PRESSED(2, button)
end

--- Check scroll wheel
---@return number 1 for up, -1 for down, 0 for none
function Mouse.GetScroll()
    if PAD.IS_DISABLED_CONTROL_PRESSED(2, Mouse.SCROLL_UP) then
        return 1
    elseif PAD.IS_DISABLED_CONTROL_PRESSED(2, Mouse.SCROLL_DOWN) then
        return -1
    end
    return 0
end

--- Check if mouse is within a rectangle (centered)
---@param x number Center X
---@param y number Center Y
---@param width number Width
---@param height number Height
---@return boolean
function Mouse.MouseWithinCentered(x, y, width, height)
    local minX = x - width / 2
    local maxX = x + width / 2
    local minY = y - height / 2
    local maxY = y + height / 2
    
    return Mouse.X >= minX and Mouse.X <= maxX and Mouse.Y >= minY and Mouse.Y <= maxY
end

--- Check if mouse is within a rectangle (top-left aligned, optional helper)
---@param x number X
---@param y number Y
---@param width number Width
---@param height number Height
---@return boolean
function Mouse.MouseWithin(x, y, width, height)
    return Mouse.X >= x and Mouse.X <= x + width and Mouse.Y >= y and Mouse.Y <= y + height
end

--- Draw the cursor
---@param renderer table The Renderer module (avoid circular require by passing it or just using global require inside)
function Mouse.DrawCursor(renderer)
    if not renderer then return end
    
    renderer.DrawSprite(Mouse.SPRITE_NORMAL, Mouse.X, Mouse.Y, 0.015, 0.025, 0, {r=255, g=255, b=255, a=255})
end

return Mouse
