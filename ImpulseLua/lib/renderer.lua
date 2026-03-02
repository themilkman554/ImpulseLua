--[[
    Impulse Lua - Renderer Module
    Handles all drawing operations using GTA natives
    Port of renderer.cpp from Impulse C++
]]

local Renderer = {}
local Mouse = require("Impulse/ImpulseLua/lib/mouse")

-- Font constants (matching GTA fonts)
Renderer.Font = {
    ChaletLondon = 0,
    HouseScript = 1,
    Monospace = 2,
    Wingdings = 3, -- Symbol font
    ChaletComprimeCologne = 4,
    Pricedown = 7
}

-- Default colors (matching Impulse C++ defaults)
Renderer.Colors = {
    Outline = { r = 0, g = 246, b = 255, a = 255 },      -- Cyan outline
    Primary = { r = 0, g = 0, b = 0, a = 255 },          -- Black background
    Selection = { r = 22, g = 192, b = 198, a = 200 },   -- Teal selection
    SubHeader = { r = 0, g = 0, b = 0, a = 200 },        -- Dark subheader
    Title = { r = 225, g = 225, b = 225, a = 255 },      -- Light title text
    Option = { r = 255, g = 255, b = 255, a = 255 },     -- White option text
    Disabled = { r = 180, g = 180, b = 180, a = 255 }    -- Light Gray for locked features
}

-- Layout dimensions (matching Impulse C++ defaults)
Renderer.Layout = {
    posX = 0.15,
    posY = 0.12,
    width = 0.235,
    lineWidth = 0.0009,
    
    headerHeight = 0.083,
    subHeaderHeight = 0.032,
    optionHeight = 0.032,
    footerHeight = 0.032,
    
    dialogHeaderHeight = 0.0415,
    dialogFooterHeight = 0.01725,
    
    bgOpacity = 45, -- 0-100 percentage
    
    textSize = 0.33,
    textSize = 0.33,
    textFont = 4, -- ChaletComprimeCologne
    
    -- Component positions (Absolute defaults)
    infoboxPos = { x = 0.380, y = 0.270 },
    vehicleInfoPos = { x = 0.395, y = 0.215 }
}

-- Global opacity for fade effects
Renderer.globalOpacity = 1.0

-- Texture definitions (matching Impulse C++ textures)
Renderer.Textures = {
    Header = { dict = "Bookmarks", name = "ImpulseHeader5" },
    Footer = { dict = "Bookmarks", name = "ImpulseLogoBottomMenu" },
    DialogBox = { dict = "commonmenu", name = "gradient_bgd" },
    Tooltip = { dict = "Bookmarks", name = "Tooltipbox5" },
    Notify = { dict = "Bookmarks", name = "notify_generic" }, -- Default notify icon
    ToggleOn = { dict = "Bookmarks", name = "UpdatedNewToggleOn" },
    ToggleOff = { dict = "Bookmarks", name = "UpdatedNewToggleOff" },
    ColorlessToggleOn = { dict = "Bookmarks", name = "NewOnToggle3" },
    ColorlessToggleOff = { dict = "Bookmarks", name = "NewOffToggle3" }
}

Renderer.colorlessToggles = false
Renderer.colorlessToggles = false
Renderer.headerAlpha = 255 -- Default header transparency
Renderer.showVersion = true -- Default show version

-- Atomic ImGui Frame Presentation
-- FrameQueue: Accumulates draw requests during the logic update (OnTick)
-- RenderQueue: Used by ON_PRESENT to draw the complete frame
Renderer.ImGuiFrameQueue = {}
Renderer.ImGuiRenderQueue = {}

-- Called by main.lua after Menu.Render() is complete
function Renderer.PresentImGuiFrame()
    if not Renderer.useImGui then 
        Renderer.ImGuiFrameQueue = {}
        return 
    end
    
    -- Atomically update the render queue with the completed frame
    Renderer.ImGuiRenderQueue = Renderer.ImGuiFrameQueue
    Renderer.ImGuiFrameQueue = {}
end

-- Register ON_PRESENT handler for ImGui texture rendering
local function registerImGuiHandler()
    EventMgr.RegisterHandler(eLuaEvent.ON_PRESENT, function()
        if not Renderer.useImGui then return end
        
        -- Get the latest complete frame (atomic read)
        local queue = Renderer.ImGuiRenderQueue
        
        -- Render all items
        for _, draw in ipairs(queue) do
            if draw.srv then
                pcall(function()
                    ImGui.BgAddImageRotated(draw.srv, draw.centerX, draw.centerY, draw.width, draw.height, draw.rotation, draw.alpha)
                end)
            end
        end
    end)
end

-- Initialize the handler
registerImGuiHandler()

Renderer.arrowStyle = 4      -- Arrow design (0-5), default 4 = helicopterhud
Renderer.animatedArrows = false

-- ImGui Rendering State
Renderer.useImGui = false
Renderer.TextureCache = {}

-- Calculated values (updated during render)
Renderer.Calculated = {
    subHeaderY = 0,
    backgroundY = 0,
    backgroundHeight = 0,
    footerY = 0,
    renderOptions = 0
}

--[[ ============================================
    HELPER FUNCTIONS
============================================ ]]

--- Apply global opacity to a color
---@param color table Color with r, g, b, a
---@return number, number, number, number
local function applyOpacity(color)
    return color.r, color.g, color.b, math.floor(color.a * Renderer.globalOpacity)
end

--- Get color with offset brightness
---@param color table Color with r, g, b, a
---@param offset number Brightness offset (-255 to 255)
---@return table
function Renderer.GetColorOffset(color, offset)
    return {
        r = math.max(0, math.min(255, color.r + offset)),
        g = math.max(0, math.min(255, color.g + offset)),
        b = math.max(0, math.min(255, color.b + offset)),
        a = color.a
    }
end

--[[ ============================================
    CORE DRAWING FUNCTIONS
============================================ ]]

--- Draw text on screen
---@param text string Text to display
---@param x number X position (0.0 - 1.0)
---@param y number Y position (0.0 - 1.0)
---@param font number Font ID
---@param scale number Font scale
---@param color table Color with r, g, b, a
---@param outline boolean Whether to draw outline
---@param justify number Justification: 0=center, 1=left, 2=right, -1=ignore
---@param wrapMin number Text wrap min (optional)
---@param wrapMax number Text wrap max (optional)
function Renderer.DrawString(text, x, y, font, scale, color, outline, justify, wrapMin, wrapMax)
    font = font or Renderer.Layout.textFont
    scale = scale or Renderer.Layout.textSize
    color = color or Renderer.Colors.Option
    outline = outline or false
    justify = justify or -1
    wrapMin = wrapMin or 0
    wrapMax = wrapMax or 0
    
    HUD.SET_TEXT_FONT(font)
    
    -- Handle justification
    if justify == 0 then
        HUD.SET_TEXT_CENTRE(true)
    elseif justify == 2 then
        HUD.SET_TEXT_RIGHT_JUSTIFY(true)
    end
    if justify == -1 then
        -- Default to Left align (1) if not specified, prevents inheriting previous state
        HUD.SET_TEXT_JUSTIFICATION(1)
    else
        -- 0=Center, 1=Left, 2=Right
        if justify == 2 then -- Right align helper for wrap
            HUD.SET_TEXT_WRAP(Renderer.Layout.posX - Renderer.Layout.width / 2, 
                             Renderer.Layout.posX + Renderer.Layout.width / 2 - 0.015 / 2.0)
        end
        HUD.SET_TEXT_JUSTIFICATION(justify)
    end
    
    -- Fix for Chalet London sizing
    if font == Renderer.Font.ChaletLondon then
        scale = scale * 0.75
        y = y + 0.003
    end
    if font == Renderer.Font.ChaletComprimeCologne then
        y = y + 0.003
    end
    
    HUD.SET_TEXT_SCALE(0.0, scale)
    local r, g, b, a = applyOpacity(color)
    HUD.SET_TEXT_COLOUR(r, g, b, a)
    
    if wrapMin ~= 0 or wrapMax ~= 0 then
        HUD.SET_TEXT_WRAP(wrapMin, wrapMax)
    else
        -- Reset to full screen to prevent state leakage from previous calls
        HUD.SET_TEXT_WRAP(0.0, 1.0)
    end
    
    if outline then
        HUD.SET_TEXT_OUTLINE()
    end
    
    HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_DISPLAY_TEXT(x, y, 0)
end

--- Draw rectangle on screen
---@param x number Center X position (0.0 - 1.0)
---@param y number Center Y position (0.0 - 1.0)
---@param width number Width (0.0 - 1.0)
---@param height number Height (0.0 - 1.0)
---@param color table Color with r, g, b, a
function Renderer.DrawRect(x, y, width, height, color)
    color = color or Renderer.Colors.Primary
    local r, g, b, a = applyOpacity(color)
    GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(7)
    GRAPHICS.SET_SCRIPT_GFX_DRAW_BEHIND_PAUSEMENU(true)
    GRAPHICS.DRAW_RECT(x, y, width, height, r, g, b, a, 0)
end

--- Preload all ImGui textures to avoid hitting texture limits during animation
--- Call this once when Alt Rendering Mode is enabled
function Renderer.PreloadImGuiTextures()
    local basePath = FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Impulse-main\\Textures\\png\\"
    local loadedCount = 0
    
    -- Preload animated header frames (00-50)
    for i = 0, 50 do
        local name = string.format("ImpulseAniHeader%02d", i)
        local path = basePath .. name .. ".png"
        if FileMgr.DoesFileExist(path) and not Renderer.TextureCache[name] then
            local texId = Texture.LoadTexture(path)
            if texId and texId > 0 then
                Renderer.TextureCache[name] = texId
                loadedCount = loadedCount + 1
            end
            -- Validating 50 textures at once is heavy, yield to let game update
            if i % 5 == 0 then
                Script.Yield()
            end
        end
    end
    
    -- Preload other Impulse textures (logo, toggles)
    local otherTextures = {
        "ImpulseLogoBottomMenu",
        "UpdatedNewToggleOn",
        "UpdatedNewToggleOff",
        "NewOnToggle3",
        "NewOffToggle3"
        -- Note: ImpulseHeader5 has no PNG - use animated headers
    }
    for _, name in ipairs(otherTextures) do
        local path = basePath .. name .. ".png"
        if FileMgr.DoesFileExist(path) and not Renderer.TextureCache[name] then
            local texId = Texture.LoadTexture(path)
            if texId then
                Renderer.TextureCache[name] = texId
                loadedCount = loadedCount + 1
            else
                Renderer.TextureCache[name] = -1
            end
        end
    end
end

--- Get ImGui texture for rendering
--- Only works for textures that have PNG files in Textures/png folder.
--- GTA built-in textures will return nil and fall back to native rendering.
---@param textureName string Base name of the texture file
---@return userdata|nil ImGui SRV or nil
function Renderer.GetImGuiTexture(textureName)
    -- Get or load texture ID
    local texId = Renderer.TextureCache[textureName]
    
    if not texId then
        local path = ""
        local isCustom = false
        
        -- Check for custom header prefix
        if string.sub(textureName, 1, 13) == "customheader/" then
            -- Remove prefix for filename but keep full name for cache key
            local simpleName = string.sub(textureName, 14)
            path = FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Impulse-main\\Textures\\customheader\\" .. simpleName .. ".png"
            isCustom = true
        else
            -- Standard PNG texture
            path = FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Impulse-main\\Textures\\png\\" .. textureName .. ".png"
        end
        
        if not FileMgr.DoesFileExist(path) then
            -- For standard textures, this means it's a GTA texture (fallback to native)
            -- For custom headers, it means the file is missing
            if isCustom then
                Logger.LogInfo("[AltRender] Custom header missing: " .. path)
            end
            
            -- Mark as failed so we don't keep trying
            Renderer.TextureCache[textureName] = -1
            return nil
        end
        
        -- Only log on first-time load
        texId = Texture.LoadTexture(path)
        if texId and texId > 0 then
            Renderer.TextureCache[textureName] = texId
        else
            Renderer.TextureCache[textureName] = -1
            return nil
        end
    end
    
    -- Check if marked as failed (GTA built-in texture, no PNG)
    if type(texId) ~= "number" or texId <= 0 then
        return nil
    end
    
    -- Validate texture
    if not Texture.IsTextureValid(texId) then
        return nil
    end
    
    -- Get D3D texture object
    local d3dTex = Texture.GetTexture(texId)
    if not d3dTex then
        return nil
    end
    
    -- Get current SRV
    local gpuTex = d3dTex:GetCurrent()
    if not gpuTex then
        return nil
    end
    
    return gpuTex
end

--- Draw sprite/texture on screen
---@param texture table Texture with dict and name
---@param x number Center X position
---@param y number Center Y position
---@param w number Width
---@param h number Height
---@param heading number Rotation in degrees
---@param color table Color with r, g, b, a
---@param renderIfNotStreamed boolean Render even if not loaded
function Renderer.DrawSprite(texture, x, y, w, h, heading, color, renderIfNotStreamed)
    color = color or { r = 255, g = 255, b = 255, a = 255 }
    renderIfNotStreamed = renderIfNotStreamed or true
    heading = heading or 0
    
    -- Only use ImGui rendering for Bookmarks textures (Impulse custom textures)
    if Renderer.useImGui and texture.dict == "Bookmarks" then
        local success, srv = pcall(Renderer.GetImGuiTexture, texture.name)
        if success and srv then
             -- Get display size for coordinate conversion
             local resX, resY = 1920, 1080  -- Default fallback
             local ok, rx, ry = pcall(ImGui.GetDisplaySize)
             if ok and rx and ry then
                 resX, resY = rx, ry
             end
             
             local centerX = x * resX
             local centerY = y * resY
             local width = w * resX
             local height = h * resY
             
             local r, g, b, a = applyOpacity(color)
             
             -- Queue to frame buffer (PresentImGuiFrame will promote to RenderQueue)
             table.insert(Renderer.ImGuiFrameQueue, {
                 srv = srv,
                 centerX = centerX,
                 centerY = centerY,
                 width = width,
                 height = height,
                 rotation = heading or 0.0,
                 alpha = math.floor(a)
             })
             return -- Don't fall through to native
        end
    end

    -- Native rendering (works for all textures - non-EE or non-Bookmarks)
    local streamed = GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(texture.dict)
    if streamed or renderIfNotStreamed then
        local r, g, b, a = applyOpacity(color)
        GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(7)
        GRAPHICS.SET_SCRIPT_GFX_DRAW_BEHIND_PAUSEMENU(true)
        GRAPHICS.DRAW_SPRITE(texture.dict, texture.name, x, y, w, h, heading, r, g, b, a, 0)
    end
    if not streamed then
        GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(texture.dict, 0)
    end
end

--- Draw a 3D line
---@param x1 number Start X
---@param y1 number Start Y
---@param z1 number Start Z
---@param x2 number End X
---@param y2 number End Y
---@param z2 number End Z
---@param color table Color with r, g, b, a
function Renderer.DrawLine(x1, y1, z1, x2, y2, z2, color)
    color = color or Renderer.Colors.Primary
    GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(7)
    GRAPHICS.SET_SCRIPT_GFX_DRAW_BEHIND_PAUSEMENU(true)
    GRAPHICS.DRAW_LINE(x1, y1, z1, x2, y2, z2, color.r, color.g, color.b, color.a)
end

--[[ ============================================
    COMPOSITE DRAWING FUNCTIONS
============================================ ]]

--- Draw a box with borders
---@param x number Center X
---@param y number Center Y
---@param width number Width
---@param height number Height
---@param title string Title text (optional)
---@param gradients boolean Use gradient background
---@param texture table Background texture
---@param customColor boolean Use custom color
---@param color table Custom color if enabled
function Renderer.DrawBox(x, y, width, height, title, gradients, texture, customColor, color)
    title = title or ""
    gradients = gradients or false
    texture = texture or Renderer.Textures.DialogBox
    customColor = customColor or false
    color = color or { r = 255, g = 255, b = 255, a = 255 }
    
    local bgOpacity = math.floor(Renderer.Layout.bgOpacity * 255 / 100)
    local primary = Renderer.Colors.Primary
    local outline = Renderer.Colors.Outline
    local lineW = Renderer.Layout.lineWidth
    
    -- Draw background
    if gradients and primary.r == 0 and primary.g == 0 and primary.b == 0 and primary.a == 255 then
        -- Draw gradient header/footer
        Renderer.DrawSprite(texture, x, y - height / 2 + Renderer.Layout.dialogHeaderHeight / 2, 
                           width, Renderer.Layout.dialogHeaderHeight, 0, primary)
        Renderer.DrawSprite(texture, x, y + height / 2 - Renderer.Layout.dialogFooterHeight / 2,
                           width, Renderer.Layout.dialogFooterHeight, 180, primary)
        -- Middle section
        Renderer.DrawRect(x, y + Renderer.Layout.dialogHeaderHeight / 2 - Renderer.Layout.dialogFooterHeight / 2,
                         width, height - Renderer.Layout.dialogHeaderHeight - Renderer.Layout.dialogFooterHeight,
                         { r = primary.r, g = primary.g, b = primary.b, a = bgOpacity })
    else
        local bgColor = customColor and color or { r = primary.r, g = primary.g, b = primary.b, a = bgOpacity }
        Renderer.DrawRect(x, y, width, height, bgColor)
    end
    
    -- Draw title
    if title ~= "" then
        Renderer.DrawString(title, x - width / 2 + 0.01, y - height / 2 + 0.005, 
                           Renderer.Font.Pricedown, 0.5, Renderer.Colors.Option, true)
    end
    
    -- Draw borders (inner - primary color)
    Renderer.DrawRect(x, y - height / 2, width + lineW * 2, lineW, primary) -- Top
    Renderer.DrawRect(x, y + height / 2, width + lineW * 2, lineW, primary) -- Bottom
    Renderer.DrawRect(x - width / 2, y, lineW, height + lineW * 2, primary) -- Left
    Renderer.DrawRect(x + width / 2, y, lineW, height + lineW * 2, primary) -- Right
    
    -- Draw borders (outer - outline color)
    Renderer.DrawRect(x, y - height / 2 - lineW, width + lineW * 2, lineW, outline) -- Top
    Renderer.DrawRect(x, y + height / 2 + lineW, width + lineW * 2, lineW, outline) -- Bottom
    Renderer.DrawRect(x - width / 2 - lineW, y, lineW, height + lineW * 3, outline) -- Left
    Renderer.DrawRect(x + width / 2 + lineW, y, lineW, height + lineW * 3, outline) -- Right
end

--[[ ============================================
    MENU RENDERING FUNCTIONS
============================================ ]]

--- Get Y position for an option at given position
---@param pos number Option position (0-indexed)
---@return number Y position
function Renderer.GetOptionY(pos)
    return (pos * Renderer.Layout.optionHeight) + Renderer.Calculated.subHeaderY + Renderer.Layout.subHeaderHeight / 2
end

--- Get Y position for option text at given position
---@param pos number Option position (0-indexed)
---@return number Y position for text
function Renderer.GetOptionYText(pos)
    return Renderer.GetOptionY(pos) + (Renderer.Layout.optionHeight - 0.032) / 2 - (Renderer.Layout.textSize - 0.35) / 32
end

--- Get the appropriate toggle texture
---@param isOn boolean Toggle state
---@return table Texture table
function Renderer.GetToggleTexture(isOn)
    if Renderer.colorlessToggles then
        return isOn and Renderer.Textures.ColorlessToggleOn or Renderer.Textures.ColorlessToggleOff
    else
        return isOn and Renderer.Textures.ToggleOn or Renderer.Textures.ToggleOff
    end
end

--[[ ============================================
    NOTIFICATION FUNCTIONS
============================================ ]]

--- Show bottom screen notification
---@param text string Notification text
---@param duration number Duration in ms (default 4000)
function Renderer.NotifyBottom(text, duration)
    duration = duration or 4000
    HUD.BEGIN_TEXT_COMMAND_PRINT("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_PRINT(duration, 1)
end

--- Simple notification alias (calls NotifyBottom)
---@param text string Notification text
function Renderer.Notify(text)
    Renderer.NotifyBottom(text, 4000)
end

--- Show tooltip
---@param text string Tooltip text
---@param canBeSaved boolean Can this option be saved
---@param hasHotkey boolean Can this option have a hotkey
---@param key number Current hotkey (-1 if none)
function Renderer.RenderTooltip(text, canBeSaved, hasHotkey, key)
    -- Check if text is valid
    if not text or text == "" then return end
    
    -- Port of C++ Renderer::RenderTooltip
    -- DrawBox(0.50f, 0.85f, 0.26f, 0.07f, "", true, m_hDialogBox, true, { m_cPrimary.m_r, m_cPrimary.m_g, m_cPrimary.m_b, 155 });
    local boxX = 0.50
    local boxY = 0.85
    local boxW = 0.26
    local boxH = 0.07
    
    local primary = Renderer.Colors.Primary
    local boxColor = { r = primary.r, g = primary.g, b = primary.b, a = 155 }
    
    Renderer.DrawBox(boxX, boxY, boxW, boxH, "", true, Renderer.Textures.DialogBox, true, boxColor)
    
    -- DrawString(toRender, 0.38f, 0.822f, FontChaletLondon, 0.3f, ...)
    local textX = 0.38
    local textY = 0.822
    local fontSize = 0.3
    local font = Renderer.Font.ChaletLondon
    local color = Renderer.Colors.Option
    
    local offset = 0
    local offsetStep = 0.015
    
    -- Main tooltip text
    Renderer.DrawString(text, textX, textY, font, fontSize, color, false, 1, 0.38, 0.4975)
    
    -- Save option (F11)
    if canBeSaved then
        Renderer.DrawString("Save option: F11", textX, textY + (offsetStep * offset), font, fontSize, color, false, 2, 0.38, 0.615)
        offset = offset + 1
    end
    
    -- Set hotkey (F12)
    if hasHotkey then
        Renderer.DrawString("Set hotkey: F12", textX, textY + (offsetStep * offset), font, fontSize, color, false, 2, 0.38, 0.615)
        offset = offset + 1
        
        -- Current hotkey display
        -- Warning: Key names map not implemented, just showing key code or 'not set'
        local keyName = (key == -1 or not key) and "not set" or tostring(key)
        -- Ideally translate key code to name here
        
        Renderer.DrawString("Hotkey: " .. keyName, textX, textY + (offsetStep * offset), font, fontSize, color, false, 2, 0.38, 0.615)
        offset = offset + 1
    end
end

--- Show map notification
---@param text string Notification text
function Renderer.NotifyMap(text)
    HUD.BEGIN_TEXT_COMMAND_THEFEED_POST("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    
    -- When alt rendering mode is enabled, don't use custom texture
    if Renderer.useImGui then
        HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER(false, true)
    else
        HUD.END_TEXT_COMMAND_THEFEED_POST_MESSAGETEXT(Renderer.Textures.Notify.dict, Renderer.Textures.Notify.name, false, 0, "Impulse", "")
        HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER(false, true)
    end
end

--[[ ============================================
    STRING UTILITY FUNCTIONS
============================================ ]]

--- Get the width of a string
---@param str string The string to measure
---@param font number Font ID
---@param fontsize number Font size
---@return number Width in screen units
function Renderer.GetStringWidth(str, font, fontsize)
    if font == Renderer.Font.ChaletLondon then
        fontsize = fontsize * 0.75
    end
    HUD.BEGIN_TEXT_COMMAND_GET_SCREEN_WIDTH_OF_DISPLAY_TEXT("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(str)
    HUD.SET_TEXT_FONT(font)
    HUD.SET_TEXT_SCALE(fontsize, fontsize)
    return HUD.END_TEXT_COMMAND_GET_SCREEN_WIDTH_OF_DISPLAY_TEXT(font)
end

--- Get the height of text
---@param font number Font ID
---@param fontsize number Font size
---@return number Height in screen units
function Renderer.GetStringHeight(font, fontsize)
    return HUD.GET_TEXT_SCALE_HEIGHT(fontsize, font)
end

--[[ ============================================
    ADDITIONAL NOTIFICATION FUNCTIONS
============================================ ]]

--- Show map notification with color
---@param text string Notification text
---@param color number HUD color ID
function Renderer.NotifyMapColor(text, color)
    HUD.THEFEED_SET_BACKGROUND_COLOR_FOR_NEXT_POST(color)
    HUD.BEGIN_TEXT_COMMAND_THEFEED_POST("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)

    if Renderer.useImGui then
        HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER(false, true)
    else
        HUD.END_TEXT_COMMAND_THEFEED_POST_MESSAGETEXT(Renderer.Textures.Notify.dict, Renderer.Textures.Notify.name, false, 0, "Impulse", "")
        HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER(false, true)
    end
end

--- Show warning notification
---@param warning string Warning title
---@param text string Warning text
function Renderer.NotifyWarning(warning, text)
    HUD.BEGIN_TEXT_COMMAND_THEFEED_POST("STRING")
    HUD.THEFEED_SET_NEXT_POST_BACKGROUND_COLOR(7) -- Warning color
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_THEFEED_POST_TICKER(true, true)
end

--[[ ============================================
    ADDITIONAL DRAWING FUNCTIONS
============================================ ]]

--- Draw sprite without checking if streamed (unsafe)
---@param texture table Texture with dict and name
---@param x number Center X position
---@param y number Center Y position
---@param w number Width
---@param h number Height
---@param heading number Rotation in degrees
---@param color table Color with r, g, b, a
function Renderer.DrawSpriteUnsafe(texture, x, y, w, h, heading, color)
    color = color or { r = 255, g = 255, b = 255, a = 255 }
    heading = heading or 0
    local r, g, b, a = applyOpacity(color)
    GRAPHICS.DRAW_SPRITE(texture.dict, texture.name, x, y, w, h, heading, r, g, b, a, 0)
end

--- Draw sprite with aspect ratio correction
---@param texture table Texture with dict and name
---@param x number Center X position
---@param y number Center Y position
---@param w number Width (in pixels)
---@param h number Height (in pixels)
---@param heading number Rotation in degrees
---@param color table Color with r, g, b, a
---@param renderIfNotStreamed boolean Render even if not loaded
function Renderer.DrawSpriteAspect(texture, x, y, w, h, heading, color, renderIfNotStreamed)
    color = color or { r = 255, g = 255, b = 255, a = 255 }
    renderIfNotStreamed = renderIfNotStreamed or true
    heading = heading or 0
    
    -- Get screen resolution for aspect correction
    local resX, resY = GRAPHICS.GET_ACTUAL_SCREEN_RESOLUTION()
    resX = resX or 1920
    resY = resY or 1080
    
    -- Only use ImGui rendering for Bookmarks textures (Impulse custom textures)
    if Renderer.useImGui and texture.dict == "Bookmarks" then
        local srv = Renderer.GetImGuiTexture(texture.name)
        if srv then
             -- Use ImGui.GetDisplaySize when in ImGui mode
             local resX, resY = ImGui.GetDisplaySize()
             local centerX = x * resX
             local centerY = y * resY
             -- w and h are assumed to be in pixels here based on native usage
             local width = w
             local height = h
             
             local r, g, b, a = applyOpacity(color)
             
             -- Using BgAddImageRotated as per BiggerScript.lua (line 773)
             ImGui.BgAddImageRotated(srv, centerX, centerY, width, height, heading or 0.0, math.floor(a))
             return
        end
    end

    local streamed = GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(texture.dict)
    if streamed or renderIfNotStreamed then
        local r, g, b, a = applyOpacity(color)
        GRAPHICS.DRAW_SPRITE(texture.dict, texture.name, x, y, w / resX, h / resY, heading, r, g, b, a, 0)
    end
    if not streamed then
        GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(texture.dict, 0)
    end
end

--- Draw a minimized box (just header)
---@param x number Center X
---@param y number Center Y
---@param width number Width
---@param height number Height
---@param title string Title text
---@param texture table Background texture
function Renderer.DrawBoxMinimized(x, y, width, height, title, texture)
    texture = texture or Renderer.Textures.DialogBox
    title = title or ""
    
    local primary = Renderer.Colors.Primary
    local outline = Renderer.Colors.Outline
    local lineW = Renderer.Layout.lineWidth
    local headerH = Renderer.Layout.dialogHeaderHeight
    
    -- Draw header sprite
    Renderer.DrawSprite(texture, x, y - height / 2 + headerH / 2, width, headerH, 0, { r = 0, g = 0, b = 0, a = 255 })
    
    -- Draw title
    if title ~= "" then
        Renderer.DrawString(title, x - width / 2 + 0.01, y - height / 2 + 0.005, 
                           Renderer.Font.Pricedown, 0.5, Renderer.Colors.Option, true)
    end
    
    -- Borders
    Renderer.DrawRect(x, y - height / 2, width + lineW * 2, lineW, primary) -- Top
    Renderer.DrawRect(x, y - height / 2 - lineW, width + lineW * 2, lineW, outline) -- Top outline
    Renderer.DrawRect(x, y - height / 2 + headerH, width + lineW * 2, lineW, outline) -- Bottom
    Renderer.DrawRect(x, y - height / 2 + headerH - lineW, width + lineW * 2, lineW, primary) -- Bottom inner
    Renderer.DrawRect(x - width / 2, y - height / 2 + headerH / 2 - lineW / 2, lineW, headerH, primary) -- Left
    Renderer.DrawRect(x - width / 2 - lineW, y - height / 2 + headerH / 2 - lineW / 2, lineW, headerH + lineW * 2, outline) -- Left outline
    Renderer.DrawRect(x + width / 2, y - height / 2 + headerH / 2 - lineW / 2, lineW, headerH, primary) -- Right
    Renderer.DrawRect(x + width / 2 + lineW, y - height / 2 + headerH / 2 - lineW / 2, lineW, headerH + lineW * 2, outline) -- Right outline
end

--- Draw menu title
---@param title string Title text
function Renderer.DrawTitle(title)
    Renderer.DrawString(title, Renderer.Layout.posX, 
                       Renderer.Calculated.subHeaderY - Renderer.Layout.subHeaderHeight / 2 + 0.001,
                       Renderer.Font.ChaletComprimeCologne, 0.3, Renderer.Colors.Title, false, 0,
                       Renderer.Layout.posX - Renderer.Layout.width / 2,
                       Renderer.Layout.posX + Renderer.Layout.width / 2)
end

-- 2D Layer tracking
Renderer.current2DLayer = 0

--- Set 2D rendering layer
---@param layer number Layer ID
function Renderer.Set2DLayer(layer)
    GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(layer)
    Renderer.current2DLayer = layer
end

--- Get current 2D layer
---@return number Current layer
function Renderer.Get2DLayer()
    return Renderer.current2DLayer
end

--- Render mouse tooltip
---@param tooltip string Tooltip text
function Renderer.RenderMouseTooltip(tooltip)
    if not tooltip or tooltip == "" then return end
    
    local fontSize = 0.4
    local sizeOffset = 0.002
    local xOffset = 0.012
    local yOffset = 0.02
    local font = Renderer.Font.ChaletLondon
    
    -- Get mouse position
    local mouseX, mouseY = Mouse.X, Mouse.Y
    
    local prefLayer = Renderer.Get2DLayer()
    Renderer.Set2DLayer(8)
    
    local width = Renderer.GetStringWidth(tooltip, font, fontSize)
    local height = Renderer.GetStringHeight(font, fontSize)
    
    Renderer.DrawBox(mouseX + width / 2 + xOffset, mouseY - yOffset + height / 2 + 0.01,
                    width + sizeOffset, height + sizeOffset, "", false, 
                    Renderer.Textures.Header, true, { r = 5, g = 0, b = 0, a = 200 })
    
    Renderer.DrawString(tooltip, mouseX + xOffset, mouseY - yOffset + 0.005, font, fontSize,
                       Renderer.Colors.Option, true, 1, 0, 1.2)
    
    Renderer.Set2DLayer(prefLayer)
end

return Renderer
