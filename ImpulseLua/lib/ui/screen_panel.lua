--[[
    Impulse Lua - Screen Panel
    Vertical sliding side panel
    Port of screenPanel.cpp from Impulse C++
]]

local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local Menu = require("Impulse/ImpulseLua/lib/menu") -- For input checking (GetMouse)
local Settings = require("Impulse/ImpulseLua/lib/settings")
local Translation = require("Impulse/ImpulseLua/lib/translation")

local ScreenPanel = {}
ScreenPanel.__index = ScreenPanel

-- Singleton instance
local instance = nil

-- Constants from screenPanel.h
local CONST = {
    xStart = 1.0,
    yStart = 0.1,
    ySize = 0.035,
    yDistance = 0.04,
    baseSlide = 0.02,
    maxSlide = 0.12
}

--- Get singleton instance
---@return ScreenPanel
function ScreenPanel.GetInstance()
    if not instance then
        instance = setmetatable({}, ScreenPanel)
        instance:Init()
    end
    return instance
end

--- Initialize the screen panel
function ScreenPanel:Init()
    -- List of { name, requirement, callback, slide }
    self.buttons = {}
    self.m_opacity = 0.0
end

--- Add a button to the panel
---@param name string Button label
---@param enabled boolean Unused in C++ implementation (kept for signature compatibility)
---@param callback function Click callback
---@param requirement function|nil Visibility requirement
function ScreenPanel:AddButton(name, enabled, callback, requirement)
    table.insert(self.buttons, {
        name = name,
        callback = callback,
        requirement = requirement or function() return true end,
        slide = CONST.baseSlide -- Initialize at base slide
    })
end

--- Clear all buttons
function ScreenPanel:Clear()
    self.buttons = {}
end

--- Initialize panel buttons (called by WindowManager)
--- This replicates WindowManager::Init logic where buttons are added
function ScreenPanel:InitButtons()
    -- This is usually done by WindowManager calling AddButton
end

--- Helper to check if value is within range
local function Within(val, min, max)
    return val >= min and val <= max
end

--- Clamp value
local function Clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

--- Check if panel should be visible
---@return boolean
function ScreenPanel:ShouldShow()
    if Settings.HideType == 3 then return false end -- Never
    if Settings.HideType == 2 and not Menu.isOpen then return false end -- When menu open
    -- Type 1 (Always) and 4 (Extend) fall through to true
    return true
end

--- Get current X start position based on settings
local function GetXStart()
    -- Always stick to right edge
    return CONST.xStart
end

--- Get current Max Slide value based on settings
local function GetMaxSlide()
    if Settings.HideType == 4 then
        return 0.24 -- Shorter again
    end
    return CONST.maxSlide
end

--- Get current Base Slide value based on settings
local function GetBaseSlide()
    if Settings.HideType == 4 then
        return 0.06 -- Smaller base
    end
    return CONST.baseSlide
end

--- Get text horizontal offset based on settings
local function GetTextOffset()
    if Settings.HideType == 4 then
        return 0.015 -- Move text more to the right for Extend
    end
    return 0.004
end

--- Update panel logic (animation and input)
---@param mouseX number
---@param mouseY number
function ScreenPanel:Update(mouseX, mouseY)
    if not self:ShouldShow() then return end

    local offset = 0
    local xStart = GetXStart()
    local maxSlide = GetMaxSlide()
    local baseSlide = GetBaseSlide()
    
    for i, button in ipairs(self.buttons) do
        if not button.requirement() then 
            goto continue 
        end
        
        -- Animation speed logic from C++
        local distanceSpeed = (button.slide - baseSlide + 0.001) / maxSlide / 20
        
        -- Check hover
        -- xStart - button.m_slide to xStart
        local hoveredX = Within(mouseX, xStart - button.slide, xStart)
        
        -- yStart + (yDistance * offset) - ySize TO yStart + (yDistance * offset)
        local topY = CONST.yStart + (CONST.yDistance * offset) - CONST.ySize
        local bottomY = CONST.yStart + (CONST.yDistance * offset)
        local hoveredY = Within(mouseY, topY, bottomY)
        
        if hoveredX and hoveredY then
            -- Hovering - Expand slide
            button.slide = Clamp(button.slide + (0.005 - distanceSpeed), baseSlide, maxSlide)
        else
            -- Shrink slide
            button.slide = Clamp(button.slide - distanceSpeed, baseSlide, maxSlide)
        end
        
        offset = offset + 1
        ::continue::
    end
end

--- Handle click - Called by WindowManager when left click detected
---@param mouseX number
---@param mouseY number
---@return boolean consumed
function ScreenPanel:HandleClick(mouseX, mouseY)
    if not self:ShouldShow() then return false end

    local offset = 0
    local xStart = GetXStart()
    
    for i, button in ipairs(self.buttons) do
        if not button.requirement() then goto continue end
        
        local topY = CONST.yStart + (CONST.yDistance * offset) - CONST.ySize
        local bottomY = CONST.yStart + (CONST.yDistance * offset)
        
        -- Check hover using current slide
        local hoveredX = Within(mouseX, xStart - button.slide, xStart)
        local hoveredY = Within(mouseY, topY, bottomY)
        
        if hoveredX and hoveredY then
            if button.callback then 
                button.callback() 
                return true
            end
        end
        
        offset = offset + 1
        ::continue::
    end
    return false
end

--- Render the panel
function ScreenPanel:Render()
    if not self:ShouldShow() then 
        self.m_opacity = 0.0
        return 
    end

    -- Update opacity (rudimentary fade in)
    if self.m_opacity < 1.0 then
        self.m_opacity = self.m_opacity + 0.02
        if self.m_opacity > 1.0 then self.m_opacity = 1.0 end
    end
    
    -- Set global opacity
    local originalOpacity = Renderer.globalOpacity
    Renderer.globalOpacity = self.m_opacity
    
    local offset = 0
    local xStart = GetXStart()
    local textOffset = GetTextOffset()
    
    for i, button in ipairs(self.buttons) do
        if not button.requirement() then goto continue end
        
        -- DrawBox
        -- xStart - button.m_slide / 2
        local x = xStart - button.slide / 2
        local y = CONST.yStart + (CONST.yDistance * offset) - CONST.ySize / 2
        
        -- Let's use Renderer.DrawBox for consistency
        Renderer.DrawBox(x, y, button.slide, CONST.ySize, "", true, Renderer.Textures.DialogBox)
        
        -- DrawString
        -- xStart - button.m_slide + offset
        local textX = xStart - button.slide + textOffset
        local textY = CONST.yStart + (CONST.yDistance * offset) - CONST.ySize - 0.002

        Renderer.DrawString(
            Translation.GetFlat(button.name),
            textX,
            textY,
            Renderer.Font.ChaletComprimeCologne, -- C++ uses m_textFont (usually Comprime)
            0.35, -- Scale 0.5f in C++ (relative to what? 1080p?). Lua DrawString expects ~0.3-0.5.
            { r = 255, g = 255, b = 255, a = 200 },
            true, -- outline
            1, -- justify left
            xStart - button.slide + 0.002, -- wrapMin
            2.0 -- wrapMax
        )
        
        offset = offset + 1
        ::continue::
    end
    
    -- Restore opacity
    Renderer.globalOpacity = originalOpacity
end

return ScreenPanel
