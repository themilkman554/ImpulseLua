--[[
    Impulse Lua - Text Box Component
    Port of UITextBoxComponent from Impulse C++
    Scrollable text box with lines and input field at bottom
]]

local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class TextBoxComponent
local TextBoxComponent = {}
TextBoxComponent.__index = TextBoxComponent

--- Create a new text box component
---@param title string Box title
---@param linesToDisplay number Number of visible lines
---@param callback function Callback when Enter is pressed (receives input text)
---@return TextBoxComponent
function TextBoxComponent.new(title, linesToDisplay, callback)
    local self = setmetatable({}, TextBoxComponent)
    
    self.title = title or "Text Box"
    self.linesToDisplay = linesToDisplay or 10
    self.callback = callback or function(text) end
    
    self.lines = {}
    self.scroll = 0
    self.autoScroll = true
    self.textSize = 0.022
    
    self.inputText = ""
    self.textSelected = false
    self.blink = false
    self.blinkTimer = 0
    
    self.visible = false
    self.dragging = false
    
    -- Position/size
    self.x = 0.5
    self.y = 0.5
    self.width = 0.35
    
    -- Calculate height based on lines
    local headerH = Renderer.Layout.dialogHeaderHeight
    local footerH = Renderer.Layout.dialogFooterHeight
    self.height = self.linesToDisplay * self.textSize + headerH + footerH
    
    return self
end

--- Show the component
function TextBoxComponent:Show()
    self.visible = true
end

--- Hide the component
function TextBoxComponent:Hide()
    self.visible = false
    self.textSelected = false
end

--- Add a line of text
---@param line string Line to add
function TextBoxComponent:AddLine(line)
    -- Replace newlines with spaces
    line = string.gsub(line, "\n", " ")
    table.insert(self.lines, line)
    
    -- Auto-scroll if enabled and at bottom
    local maxScroll = math.max(0, #self.lines - self.linesToDisplay)
    if self.autoScroll and self.scroll == maxScroll - 1 then
        self.scroll = maxScroll
    end
end

--- Add a colored line (using GTA text codes)
---@param color string Color code (r, g, b, y, w, etc.)
---@param line string Line to add
function TextBoxComponent:AddColoredLine(color, line)
    local prefix = "~" .. color .. "~"
    self:AddLine(prefix .. line)
end

--- Clear all lines
function TextBoxComponent:Clear()
    self.lines = {}
    self.scroll = 0
end

--- Get all lines
---@return table
function TextBoxComponent:GetLines()
    return self.lines
end

--- Handle scroll events
---@param scrollDelta number Positive = up, Negative = down
function TextBoxComponent:Scroll(scrollDelta)
    self.scroll = self.scroll - scrollDelta
    local maxScroll = math.max(0, #self.lines - self.linesToDisplay)
    if self.scroll < 0 then self.scroll = 0 end
    if self.scroll > maxScroll then self.scroll = maxScroll end
end

--- Update blink cursor
function TextBoxComponent:UpdateBlink()
    local now = MISC.GET_GAME_TIMER()
    if now - self.blinkTimer > 350 then
        self.blinkTimer = now
        self.blink = not self.blink
    end
end

--- Handle keyboard input for text
function TextBoxComponent:HandleInput()
    if not self.textSelected then return end
    
    -- Simple key input (would need proper keyboard handling)
    -- For now, this is a placeholder - actual implementation would need
    -- access to keyboard input APIs
    
    -- Check for Enter to submit
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 201) then -- Enter key
        if self.callback and #self.inputText > 0 then
            self.callback(self.inputText)
            self:AddLine("You: " .. self.inputText)
        end
        self.inputText = ""
    end
    
    -- Check for Backspace
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 177) then -- Backspace
        if #self.inputText > 0 then
            self.inputText = string.sub(self.inputText, 1, -2)
        end
    end
end

--- Render the text box
function TextBoxComponent:Render()
    if not self.visible then return end
    
    -- Update blink
    self:UpdateBlink()
    
    local left = self.x - self.width / 2
    local right = self.x + self.width / 2
    local headerH = Renderer.Layout.dialogHeaderHeight
    local footerH = Renderer.Layout.dialogFooterHeight
    local maxSize = self.textSize * self.linesToDisplay
    
    -- Draw main box
    Renderer.DrawBox(self.x, self.y, self.width, self.height, self.title, true, 
                    Renderer.Textures.DialogBox, false, nil)
    
    -- Draw text lines
    local offset = 0.005
    local scrollOffset = 0
    for i = self.scroll + 1, math.min(self.scroll + self.linesToDisplay, #self.lines) do
        local line = self.lines[i]
        if line then
            -- Truncate long lines
            if #line > 80 then
                line = string.sub(line, 1, 77) .. "..."
            end
            
            local lineY = offset / 2 + self.y - self.height / 2 - headerH / 4 + 
                         (self.textSize * scrollOffset) + headerH
            
            Renderer.DrawString(line, left + offset, lineY, 
                              Renderer.Font.ChaletComprimeCologne, Renderer.Layout.textSize,
                              { r = 255, g = 255, b = 255, a = 255 }, true, 1,
                              left + 0.005, right)
            scrollOffset = scrollOffset + 1
        end
    end
    
    -- Draw scrollbar if needed
    if #self.lines > self.linesToDisplay then
        local maxScroll = #self.lines - self.linesToDisplay
        local scrollPos = maxScroll > 0 and (self.scroll / maxScroll) or 0
        local scrollY = self.y - self.height / 2 + headerH + 
                       scrollPos * (maxSize - self.textSize) + self.textSize / 2
        
        -- Scrollbar background
        Renderer.DrawRect(right + 0.01, self.y + headerH / 2 - footerH / 2, 
                         0.01, maxSize, 
                         { r = Renderer.Colors.Primary.r, 
                           g = Renderer.Colors.Primary.g, 
                           b = Renderer.Colors.Primary.b, a = 100 })
        
        -- Scrollbar handle
        Renderer.DrawRect(right + 0.01, scrollY, 0.008, 0.022, Renderer.Colors.Selection)
    end
    
    -- Draw input field at bottom
    local inputY = self.y + self.height / 2 - footerH / 2 - Renderer.Layout.lineWidth
    local inputBgColor = self.textSelected and { r = 255, g = 255, b = 255, a = 255 } 
                                            or { r = 155, g = 155, b = 155, a = 255 }
    Renderer.DrawRect(self.x, inputY, self.width - Renderer.Layout.lineWidth * 2, 
                     footerH, inputBgColor)
    
    -- Draw input text with cursor
    local displayText = self.inputText
    if self.blink and self.textSelected then
        displayText = displayText .. "~m~|~s~"
    end
    
    Renderer.DrawString(displayText, left + 0.002, inputY - 0.004,
                       Renderer.Font.ChaletLondon, 0.3, 
                       { r = 0, g = 0, b = 0, a = 255 }, false, 1,
                       left + 0.002, right - 0.002)
end

--- Update and render
function TextBoxComponent:Update()
    if not self.visible then return false end
    
    self:HandleInput()
    self:Render()
    
    return true
end

--- Toggle text selection
function TextBoxComponent:ToggleTextSelection()
    self.textSelected = not self.textSelected
end

--- Check if visible
---@return boolean
function TextBoxComponent:IsVisible()
    return self.visible
end

--- Set position
---@param x number
---@param y number
function TextBoxComponent:SetPosition(x, y)
    self.x = x
    self.y = y
end

--- Set width
---@param width number
function TextBoxComponent:SetWidth(width)
    self.width = width
end

return TextBoxComponent
