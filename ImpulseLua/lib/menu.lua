--[[
    Impulse Lua - Menu State Manager
    Handles menu navigation, input, and state
    Port of menu.cpp/submenuHandler.cpp from Impulse C++
]]

local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local Menu = {}



-- Menu state
Menu.isOpen = false
Menu.currentOption = 1
Menu.scrollOffset = 0
Menu.maxOptions = 14-- Max visible options

-- Position (can be dragged)
Menu.position = { x = 0.15, y = 0.12 }

-- Submenu stack for navigation
Menu.submenuStack = {}
Menu.currentSubmenu = nil
Menu.rootSubmenu = nil  -- Store root submenu for reopening

-- Input timing
Menu.inputDelay = 150 -- ms between repeated inputs
Menu.lastInputTime = 0
Menu.openKey = 0x2D -- Insert key default

-- Sounds
Menu.Sounds = {
    select = { name = "SELECT", set = "HUD_FRONTEND_DEFAULT_SOUNDSET" },
    back = { name = "BACK", set = "HUD_FRONTEND_DEFAULT_SOUNDSET" },
    error = { name = "ERROR", set = "HUD_FRONTEND_DEFAULT_SOUNDSET" },
    updown = { name = "NAV_UP_DOWN", set = "HUD_FRONTEND_DEFAULT_SOUNDSET" },
    leftright = { name = "NAV_LEFT_RIGHT", set = "HUD_FRONTEND_DEFAULT_SOUNDSET" }
}

local Mouse = require("Impulse/ImpulseLua/lib/mouse")
local Settings = require("Impulse/ImpulseLua/lib/settings")

-- Input blocking flag (for text input, dialogs, etc.)
Menu.inputBlocked = false

-- Active Overlay Component (e.g. Color Picker)
Menu.activeOverlay = nil

-- Mouse State
Menu.isDragging = false
Menu.dragOffset = { x = 0, y = 0 }
Menu.isDraggingSlider = false

--[[ ============================================
    INPUT HANDLING
============================================ ]]

--- Check if a control is just pressed
---@param control number Control ID
---@return boolean
function Menu.IsControlJustPressed(control)
    return PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, control)
end

--- Check if a keyboard key is just pressed (for open key)
--- Uses Utils.IsKeyPressed for virtual key detection
local lastKeyStates = {}
function Menu.IsKeyJustPressed(vk)
    local isPressed = Utils.IsKeyPressed(vk)
    local wasPressed = lastKeyStates[vk] or false
    lastKeyStates[vk] = isPressed
    return isPressed and not wasPressed
end

--- Check if a control is pressed (with delay for repeat)
---@param control number Control ID
---@return boolean
function Menu.IsControlPressed(control)
    return PAD.IS_DISABLED_CONTROL_PRESSED(0, control)
end

--- Play frontend sound
---@param sound table Sound with name and set
function Menu.PlaySound(sound)
    if sound and sound.name and sound.set then
        AUDIO.PLAY_DEFERRED_SOUND_FRONTEND(sound.name, sound.set)
    end
end

--- Process menu input
function Menu.ProcessInput()
    -- Controller Toggle: Right DPAD (190) + R2 (229/Frontend RT)
    -- Using 229 as it was confirmed active in logs (along with 71/24)
    -- Check Input Group 2 (Controller) explicitly to avoid KBM interference
    -- Also ensure we aren't using KBM to avoid accidental triggers from Arrow keys
    local isUsingKBM = PAD.IS_USING_KEYBOARD_AND_MOUSE(2)
    
    if not isUsingKBM then
        local dpadLeft = PAD.IS_DISABLED_CONTROL_PRESSED(2, 189)
        local r1 = PAD.IS_DISABLED_CONTROL_PRESSED(2, 206) or PAD.IS_DISABLED_CONTROL_PRESSED(2, 44)
        
        local controllerOpen = dpadLeft and r1
        -- Debounce controller input to avoid rapid toggling
        if controllerOpen then
            local currentTime = MISC.GET_GAME_TIMER()
            if currentTime - Menu.lastInputTime > 400 then -- Longer delay for combo
                 Menu.lastInputTime = currentTime
                 if Menu.isOpen then
                     Menu.Close()
                     Menu.PlaySound(Menu.Sounds.back)
                 else
                     Logger.LogInfo("[Menu] Controller combo (DPAD Left + R1) pressed, opening menu (" .. tostring(2) .. ")")
                     Menu.Open()
                 end
                 return
            end
        end
    end

    if not Menu.isOpen then
        -- Check for open key using Utils.IsKeyPressed
        local isPressed = Utils.IsKeyPressed(Menu.openKey)
        if Menu.IsKeyJustPressed(Menu.openKey) then
            Logger.LogInfo("[Menu] Open key pressed, opening menu")
            Menu.Open()
        end
        return
    end
    
    -- Check for open key execution to close menu
    if Menu.IsKeyJustPressed(Menu.openKey) then
        Menu.Close()
        Menu.PlaySound(Menu.Sounds.back)
        return
    end
    
    -- Skip input processing if blocked (text input open, dialog, etc.)
    if Menu.inputBlocked then
        -- If an overlay is active, let it handle input
        if Menu.activeOverlay and Menu.activeOverlay.Update then
            Menu.activeOverlay:Update()
            -- Block standard menu input but ensure controls are disabled
            Menu.DisableControls()
        end
        return
    end
    
    -- Disable conflicting controls while menu is open
    Menu.DisableControls()
    
    -- Process Mouse
    if GUI.IsOpen() then
        Menu.ProcessMouse()
    end
    
    local options = Menu.GetVisibleOptions()
    local optionCount = #options
    
    if optionCount == 0 then return end
    
    local isUsingKBM = PAD.IS_USING_KEYBOARD_AND_MOUSE(2)

    -- Navigate up
    local upPressed = false
    if isUsingKBM then
        upPressed = Menu.IsControlJustPressed(172) or Menu.IsControlJustPressed(27) -- UP or PHONE UP
    else
        upPressed = Menu.IsControlJustPressed(27) -- PHONE UP (Dpad Up)
    end
    
    if upPressed then 
        local newOption = Menu.currentOption - 1
        if newOption < 1 then newOption = optionCount end
        
        -- Skip breaks (searching backwards)
        while options[newOption] and options[newOption].isBreak do
            newOption = newOption - 1
            if newOption < 1 then newOption = optionCount end
            -- Safety break for all-break menu
            if newOption == Menu.currentOption then break end
        end
        
        Menu.currentOption = newOption
        
        -- Adjust scroll offset
        if Menu.currentOption < 1 then -- Should be handled by loop but safety
            Menu.currentOption = optionCount
            Menu.scrollOffset = math.max(0, optionCount - Menu.maxOptions)
        elseif Menu.currentOption <= Menu.scrollOffset then
            Menu.scrollOffset = Menu.currentOption - 1
        elseif Menu.currentOption > Menu.scrollOffset + Menu.maxOptions then -- Handle wrap from bottom
             Menu.scrollOffset = math.max(0, optionCount - Menu.maxOptions)
        end
        
        Menu.PlaySound(Menu.Sounds.updown)
    end
    
    -- Navigate down
    local downPressed = false
    if isUsingKBM then
        downPressed = Menu.IsControlJustPressed(173) or Menu.IsControlJustPressed(173) -- DOWN or PHONE DOWN
    else
        downPressed = Menu.IsControlJustPressed(19) -- CHARACTER WHEEL (Dpad Down - Disabled in DisableControls so safe for menu)
    end
    
    if downPressed then
        local newOption = Menu.currentOption + 1
        if newOption > optionCount then newOption = 1 end
        
        -- Skip breaks (searching forwards)
        while options[newOption] and options[newOption].isBreak do
            newOption = newOption + 1
            if newOption > optionCount then newOption = 1 end
            -- Safety break
            if newOption == Menu.currentOption then break end
        end
        
        Menu.currentOption = newOption
        
        -- Adjust scroll offset
        if Menu.currentOption > optionCount then
            Menu.currentOption = 1
            Menu.scrollOffset = 0
        elseif Menu.currentOption > Menu.scrollOffset + Menu.maxOptions then
            Menu.scrollOffset = Menu.currentOption - Menu.maxOptions
        elseif Menu.currentOption <= Menu.scrollOffset then -- Handle wrap from top
            Menu.scrollOffset = 0
        end
        
        Menu.PlaySound(Menu.Sounds.updown)
    end
    
    -- Select / Enter (using 201 = INPUT_FRONTEND_ACCEPT, not 176 cellphone)
    if Menu.IsControlJustPressed(201) or Menu.IsControlJustPressed(191) then -- ENTER or NUMPAD ENTER
        local option = options[Menu.currentOption]
        if option and not option.isBreak and option.OnSelect then
            option:OnSelect()
            Menu.PlaySound(Menu.Sounds.select)
        end
    end
    
    -- Back (using 202 = INPUT_FRONTEND_CANCEL, not 177 cellphone)
    if Menu.IsControlJustPressed(202) or Menu.IsControlJustPressed(194) then -- BACKSPACE or B button
        Menu.Back()
        Menu.PlaySound(Menu.Sounds.back)
    end
    
    -- Left
    local leftPressed = false
    if isUsingKBM then
        leftPressed = Menu.IsControlJustPressed(174) or Menu.IsControlJustPressed(189) -- LEFT or FRONTEND LEFT
    else
        leftPressed = Menu.IsControlJustPressed(189) -- FRONTEND LEFT (Dpad Left)
    end
    
    if leftPressed then 
        local option = options[Menu.currentOption]
        if option and not option.isBreak and option.OnLeft then
            option:OnLeft()
            Menu.PlaySound(Menu.Sounds.leftright)
        end
    end
    
    -- Right
    local rightPressed = false
    if isUsingKBM then
        rightPressed = Menu.IsControlJustPressed(175) or Menu.IsControlJustPressed(190) -- RIGHT or FRONTEND RIGHT
    else
        rightPressed = Menu.IsControlJustPressed(190) -- FRONTEND RIGHT (Dpad Right)
    end

    if rightPressed then 
        local option = options[Menu.currentOption]
        if option and not option.isBreak and option.OnRight then
            option:OnRight()
            Menu.PlaySound(Menu.Sounds.leftright)
        end
    end
    
    -- F12 - Set Hotkey (0x7B = VK_F12)
    if Utils.IsKeyPressed(0x7B) then
        local option = options[Menu.currentOption]
        if option and not option.isBreak and option.hasHotkey then
            local KeyInputComponent = require("Impulse/ImpulseLua/lib/ui/key_input_component")
            local HotkeyManager = require("Impulse/ImpulseLua/lib/hotkey_manager")
            
            -- Create key input to capture new hotkey
            local keyInput = KeyInputComponent.new("Press a key for hotkey", function(vk)
                if vk then
                    -- Check if key is already in use
                    local existingOption = HotkeyManager.GetInstance():IsHotkeyInUse(vk)
                    if existingOption and existingOption ~= option then
                        Renderer.NotifyMap("Key already in use by: " .. existingOption.name)
                        return
                    end
                    
                    -- Register the hotkey
                    HotkeyManager.GetInstance():RegisterHotkey(vk, option)
                    local KeyOption = require("Impulse/ImpulseLua/lib/options/key")
                    local keyName = KeyOption.GetKeyNameStatic(vk) or ("Key " .. tostring(vk))
                    Renderer.NotifyMap("Set hotkey: " .. keyName)
                end
            end)
            keyInput:Show()
            Menu.activeInputComponent = keyInput
        end
    end
end


--- Process mouse input (Header Drag, Slider Drag, Options)
function Menu.ProcessMouse()
    if not Menu.isOpen then return end
    if not Settings.MouseEnabled then return end
    
    local mouseX = Mouse.X
    local mouseY = Mouse.Y
    
    -- Handle Right Click Back (if within menu bounds)
    if Mouse.ButtonJustDown(Mouse.RIGHT_BUTTON) then
        local headerY = Renderer.Layout.posY
        local halfHeader = Renderer.Layout.headerHeight / 2
        local menuTop = headerY - halfHeader
        local footerY = Renderer.Calculated.footerY
        local halfFooter = Renderer.Layout.footerHeight / 2
        local menuBottom = footerY + halfFooter
        local menuLeft = Menu.position.x - Renderer.Layout.width / 2
        local menuHeight = menuBottom - menuTop
        
        if Mouse.MouseWithin(menuLeft, menuTop, Renderer.Layout.width, menuHeight) then
             Menu.Back()
             Menu.PlaySound(Menu.Sounds.back)
        end
    end
    
    -- 1. Handle Menu Dragging (Header)
    local headerY = Renderer.Layout.posY
    local headerHeight = Renderer.Layout.headerHeight
    local halfWidth = Renderer.Layout.width / 2
    local halfHeader = headerHeight / 2
    
    -- Check for drag start
    if Mouse.ButtonJustDown(Mouse.LEFT_BUTTON) and Settings.MouseMoveEnabled then
        -- Check header bounds for menu drag
        if Mouse.MouseWithin(Menu.position.x - halfWidth, headerY - halfHeader, Renderer.Layout.width, headerHeight) then
            Menu.isDragging = true
            Menu.dragOffset.x = Menu.position.x - mouseX
            Menu.dragOffset.y = Menu.position.y - mouseY
        end
    end
    
    -- Update drag position
    if Menu.isDragging then
        if Mouse.ButtonDown(Mouse.LEFT_BUTTON) then
            Menu.position.x = mouseX + Menu.dragOffset.x
            Menu.position.y = mouseY + Menu.dragOffset.y
        else
            Menu.isDragging = false
        end
    end
    
    -- 2. Handle Scroll Wheel
    local scroll = Mouse.GetScroll()
    if scroll ~= 0 then
        local visibleOptions = Menu.GetVisibleOptions()
        local optionCount = #visibleOptions
        local maxOptions = Menu.maxOptions
        
        -- Only scroll if valid and needed
        if optionCount > maxOptions then
            if scroll > 0 then -- Up (Wheel Up)
                Menu.scrollOffset = Menu.scrollOffset - 1
            elseif scroll < 0 then -- Down (Wheel Down)
                Menu.scrollOffset = Menu.scrollOffset + 1
            end
            
            -- Clamp Scroll Offset
            if Menu.scrollOffset < 0 then 
                Menu.scrollOffset = 0
            elseif Menu.scrollOffset > optionCount - maxOptions then
                Menu.scrollOffset = optionCount - maxOptions
            end
            
            -- Optional: Update currentOption to default to visible range if it went off screen?
            -- Actually, Section 4 (Hover) will handle this if the mouse is over the menu.
            -- If mouse is NOT over the menu, we might want to clamp currentOption?
            -- Let's clamp it just in case to avoid "invisible" selection
            if Menu.currentOption <= Menu.scrollOffset then
                Menu.currentOption = Menu.scrollOffset + 1
            elseif Menu.currentOption > Menu.scrollOffset + maxOptions then
                 Menu.currentOption = Menu.scrollOffset + maxOptions
            end
            
        else
            -- If fits in one page, maybe cycle selection?
            -- Or just do nothing. Standard is nothing.
        end
    end
    
    -- 3. Handle Slider Dragging
    local sliderX = Renderer.Layout.posX - Renderer.Layout.width / 2 - 0.01
    
    -- Check for slider click (simple bounds check around the track)
    if Mouse.ButtonJustDown(Mouse.LEFT_BUTTON) then
         if Mouse.MouseWithinCentered(sliderX, Renderer.Calculated.backgroundY, 0.02, Renderer.Calculated.backgroundHeight + 0.02) then
             Menu.isDraggingSlider = true
         end
    end
     
    if Menu.isDraggingSlider then
         if Mouse.ButtonDown(Mouse.LEFT_BUTTON) then
             local totalOptions = Menu.GetTotalOptionsWithoutBreaks()
             if totalOptions > 1 then
                 local sliderBottom = Renderer.Calculated.backgroundY + Renderer.Calculated.backgroundHeight / 2
                 local sliderTop = Renderer.Calculated.backgroundY - Renderer.Calculated.backgroundHeight / 2
                 local sliderHeight = Renderer.Calculated.backgroundHeight
                 
                 local posBack = (mouseY + 0.022 / 2 - sliderTop) / (sliderHeight - Renderer.Layout.optionHeight)
                 local positionBack = math.floor(posBack * (totalOptions - 1))
                 
                 -- Clamp
                 if positionBack < 0 then positionBack = 0 end
                 if positionBack > totalOptions - 1 then positionBack = totalOptions - 1 end
                 
                 -- Map back to actual option index (skipping breaks)
                 local options = Menu.GetVisibleOptions()
                 local nonBreakCount = 0
                 local targetIndex = 1
                 
                 for i, opt in ipairs(options) do
                     if not opt.isBreak then
                         if nonBreakCount == positionBack then
                             targetIndex = i
                             break
                         end
                         nonBreakCount = nonBreakCount + 1
                     end
                 end
                 
                 Menu.currentOption = targetIndex
                 
                 -- Center/Smart Scroll Offset
                 if Menu.scrollOffset > Menu.currentOption - 1 then 
                     Menu.scrollOffset = Menu.currentOption - 1 
                 elseif Menu.currentOption > Menu.scrollOffset + Menu.maxOptions then 
                     Menu.scrollOffset = Menu.currentOption - Menu.maxOptions 
                 end
             end
         else
             Menu.isDraggingSlider = false
         end
    end
    
    -- 4. Option Hover & Click
    -- Only process option hover if not dragging slider/header
    if not Menu.isDragging and not Menu.isDraggingSlider and not Mouse.ButtonDown(Mouse.LEFT_BUTTON) then
        local options = Menu.GetVisibleOptions()
        local optionCount = #options
        local start = Menu.scrollOffset + 1
        local finish = math.min(Menu.scrollOffset + Menu.maxOptions, optionCount)
        
        for i = start, finish do
            local option = options[i]
            local displayPos = i - Menu.scrollOffset - 1
            
            -- Calculate option Y bounds (center)
            local y = Renderer.GetOptionY(displayPos) + Renderer.Layout.optionHeight / 2
            local height = Renderer.Layout.optionHeight
            
            -- Check hover
            if Mouse.MouseWithinCentered(Renderer.Layout.posX, y, Renderer.Layout.width, height) then
                if Menu.currentOption ~= i then
                     Menu.currentOption = i
                     Menu.PlaySound(Menu.Sounds.updown) -- Sound on hover change? Maybe annoying.
                end
                
                -- Check Click
                if Mouse.ButtonJustDown(Mouse.LEFT_BUTTON) then
                    if option.OnSelect then
                        option:OnSelect()
                        Menu.PlaySound(Menu.Sounds.select)
                    end
                end
            end
        end
    -- Handle click if we were hovering (separate check for click even if we didn't just move/hover this frame)
    elseif not Menu.isDragging and not Menu.isDraggingSlider and Mouse.ButtonJustDown(Mouse.LEFT_BUTTON) then
         -- Check clicks checks again
        local options = Menu.GetVisibleOptions()
        local optionCount = #options
        local start = Menu.scrollOffset + 1
        local finish = math.min(Menu.scrollOffset + Menu.maxOptions, optionCount)
        for i = start, finish do
            local option = options[i]
            local displayPos = i - Menu.scrollOffset - 1
            local y = Renderer.GetOptionY(displayPos) + Renderer.Layout.optionHeight / 2
            local height = Renderer.Layout.optionHeight
            if Mouse.MouseWithinCentered(Renderer.Layout.posX, y, Renderer.Layout.width, height) then
                 if option.OnSelect then
                     option:OnSelect()
                     Menu.PlaySound(Menu.Sounds.select)
                 end
            end
        end
    end
end

--- Disable conflicting game controls
function Menu.DisableControls()
    -- Disable various controls while menu is open
    PAD.DISABLE_CONTROL_ACTION(0, 27, true)  -- Phone
    PAD.DISABLE_CONTROL_ACTION(0, 172, true) -- Up
    PAD.DISABLE_CONTROL_ACTION(0, 173, true) -- Down
    PAD.DISABLE_CONTROL_ACTION(0, 174, true) -- Left
    PAD.DISABLE_CONTROL_ACTION(0, 175, true) -- Right
    PAD.DISABLE_CONTROL_ACTION(0, 176, true) -- Select
    PAD.DISABLE_CONTROL_ACTION(0, 177, true) -- Back
    PAD.DISABLE_CONTROL_ACTION(0, 200, true) -- Pause Menu
    PAD.DISABLE_CONTROL_ACTION(0, 19, true) -- Character Wheel
    PAD.DISABLE_CONTROL_ACTION(0, 20, true) -- Multiplayer Info
    PAD.DISABLE_CONTROL_ACTION(0, 48, true) -- HUD Special
    -- Disable frontend navigation (pause menu)

PAD.DISABLE_CONTROL_ACTION(2, 188, true) -- INPUT_FRONTEND_UP
PAD.DISABLE_CONTROL_ACTION(2, 187, true) -- INPUT_FRONTEND_DOWN
PAD.DISABLE_CONTROL_ACTION(2, 189, true) -- INPUT_FRONTEND_LEFT
PAD.DISABLE_CONTROL_ACTION(2, 190, true) -- INPUT_FRONTEND_RIGHT
PAD.DISABLE_CONTROL_ACTION(2, 201, true) -- INPUT_FRONTEND_ACCEPT
PAD.DISABLE_CONTROL_ACTION(2, 202, true) -- INPUT_FRONTEND_CANCEL
PAD.DISABLE_CONTROL_ACTION(2, 188, true) -- INPUT_FRONTEND_UP
PAD.DISABLE_CONTROL_ACTION(2, 187, true) -- INPUT_FRONTEND_DOWN
PAD.DISABLE_CONTROL_ACTION(2, 189, true) -- INPUT_FRONTEND_LEFT
PAD.DISABLE_CONTROL_ACTION(2, 190, true) -- INPUT_FRONTEND_RIGHT
PAD.DISABLE_CONTROL_ACTION(2, 201, true) -- INPUT_FRONTEND_ACCEPT
    PAD.DISABLE_CONTROL_ACTION(2, 202, true) -- INPUT_FRONTEND_CANCEL

    
    -- Face Buttons (A, B, X, Y) Blocking - ONLY IF USING CONTROLLER
    -- Using group 2 check
    local isUsingKBM = PAD.IS_USING_KEYBOARD_AND_MOUSE(2)
    
    if not isUsingKBM then
        -- A (Jump / Sprint)
        PAD.DISABLE_CONTROL_ACTION(0, 21, true) -- Sprint
        PAD.DISABLE_CONTROL_ACTION(0, 22, true) -- Jump 
        
        -- B (Reload, Melee, Phone Cancel)
        PAD.DISABLE_CONTROL_ACTION(0, 45, true)
        PAD.DISABLE_CONTROL_ACTION(0, 140, true)
        PAD.DISABLE_CONTROL_ACTION(0, 141, true)
        PAD.DISABLE_CONTROL_ACTION(0, 142, true) 
        PAD.DISABLE_CONTROL_ACTION(0, 143, true)
        PAD.DISABLE_CONTROL_ACTION(0, 263, true) -- Melee 1
        PAD.DISABLE_CONTROL_ACTION(0, 264, true) -- Melee 2
        PAD.DISABLE_CONTROL_ACTION(0, 257, true) -- Attack 2   
        PAD.DISABLE_CONTROL_ACTION(0, 80, true) -- INPUT_LOOK_BEHIND (cinematic cam toggle)

    end
end

--[[ ============================================
    MENU NAVIGATION
============================================ ]]


--- Open the menu
function Menu.Open()
    Menu.isOpen = true
    -- Restore to root submenu if no current submenu
    if not Menu.currentSubmenu and Menu.rootSubmenu then
        Menu.currentSubmenu = Menu.rootSubmenu
        Menu.currentOption = 1
        Menu.scrollOffset = 0
        Menu.submenuStack = {}
    elseif Menu.currentSubmenu and Menu.currentSubmenu.OnEnter then
        -- Resume logic: Trigger Enter if we are resuming an existing submenu
        Menu.currentSubmenu:OnEnter()
    end
    Menu.PlaySound(Menu.Sounds.select)
end

--- Close the menu
function Menu.Close()
    if Menu.currentSubmenu and Menu.currentSubmenu.OnExit then
        Menu.currentSubmenu:OnExit()
    end
    Menu.isOpen = false
    
    if not Settings.KeepLastPos then
        Menu.submenuStack = {}
        Menu.currentSubmenu = nil
        Menu.currentOption = 1
        Menu.scrollOffset = 0
    end
end

--- Go back to previous submenu or close
function Menu.Back()
    if #Menu.submenuStack > 0 then
        -- Trigger Exit on current
        if Menu.currentSubmenu and Menu.currentSubmenu.OnExit then
            Menu.currentSubmenu:OnExit()
        end

        -- Pop from stack
        local prev = table.remove(Menu.submenuStack)
        Menu.currentSubmenu = prev.submenu
        Menu.currentOption = prev.option
        Menu.scrollOffset = prev.scroll
        
        -- Trigger Enter on previous (now current)
        if Menu.currentSubmenu and Menu.currentSubmenu.OnEnter then
            Menu.currentSubmenu:OnEnter()
        end
    else
        -- Only close if allowed by setting
        if Settings.AllowMenuCloseByBack then
            Menu.Close()
        end
    end
end

--- Navigate to a submenu
---@param submenu table The submenu to navigate to
function Menu.GoToSubmenu(submenu)
    if Menu.currentSubmenu then
        -- Trigger Exit on current
        if Menu.currentSubmenu.OnExit then
            Menu.currentSubmenu:OnExit()
        end
        
        -- Push current state to stack
        table.insert(Menu.submenuStack, {
            submenu = Menu.currentSubmenu,
            option = Menu.currentOption,
            scroll = Menu.scrollOffset
        })
    end
    Menu.currentSubmenu = submenu
    Menu.currentOption = 1
    Menu.scrollOffset = 0
    
    -- Trigger Enter on new
    if Menu.currentSubmenu and Menu.currentSubmenu.OnEnter then
        Menu.currentSubmenu:OnEnter()
    end
end

--- Set the main/root submenu
---@param submenu table The root submenu
function Menu.SetRootSubmenu(submenu)
    Menu.rootSubmenu = submenu  -- Store for reopening
    Menu.currentSubmenu = submenu
    Menu.currentOption = 1
    Menu.scrollOffset = 0
end

--- Get visible options from current submenu
---@return table Array of visible options
function Menu.GetVisibleOptions()
    if not Menu.currentSubmenu then return {} end
    
    local visible = {}
    for _, opt in ipairs(Menu.currentSubmenu.options or {}) do
        if opt:IsVisible() then
            table.insert(visible, opt)
        end
    end
    return visible
end

--- Get total option count (excluding breaks, for footer display)
function Menu.GetTotalOptionsWithoutBreaks()
    local options = Menu.GetVisibleOptions()
    local count = 0
    for _, opt in ipairs(options) do
        if not opt.isBreak then
            count = count + 1
        end
    end
    return count
end

--- Get current option index excluding breaks
function Menu.GetCurrentOptionWithoutBreaks()
    local options = Menu.GetVisibleOptions()
    local count = 0
    for i = 1, Menu.currentOption do
        if options[i] and not options[i].isBreak then
            count = count + 1
        end
    end
    return count
end

--[[ ============================================
    RENDERING
============================================ ]]

--- Main render function - call every frame
function Menu.Render()
    if not Menu.isOpen then return end
    if not Menu.currentSubmenu then return end
    
    -- Update current submenu logic
    if Menu.currentSubmenu.Update then
        Menu.currentSubmenu:Update()
    end
    
    -- Update renderer position
    Renderer.Layout.posX = Menu.position.x
    Renderer.Layout.posY = Menu.position.y - Renderer.Layout.headerHeight / 2
    
    local options = Menu.GetVisibleOptions()
    local optionCount = #options
    
    -- Calculate render options count
    local renderOptions = math.min(optionCount, Menu.maxOptions)
    Renderer.Calculated.renderOptions = renderOptions
    
    -- Calculate positions
    Renderer.Calculated.subHeaderY = Renderer.Layout.posY + Renderer.Layout.headerHeight / 2 + Renderer.Layout.subHeaderHeight / 2
    Renderer.Calculated.backgroundHeight = renderOptions * Renderer.Layout.optionHeight
    Renderer.Calculated.backgroundY = Renderer.Layout.posY + Renderer.Layout.headerHeight / 2 + Renderer.Layout.subHeaderHeight + Renderer.Calculated.backgroundHeight / 2
    Renderer.Calculated.footerY = Renderer.Calculated.backgroundY + Renderer.Calculated.backgroundHeight / 2 + Renderer.Layout.footerHeight / 2
    
    -- Render components
    Menu.RenderHeader()
    Menu.RenderSubHeader()
    Menu.RenderBackground()
    Menu.RenderOptionHighlight() -- Draw highlight first (behind options)
    Menu.RenderOptions(options)  -- Draw options on top (icons visible over highlight)
    Menu.RenderFooter()
    Menu.RenderScrollbar()       -- Scrollbar on left side
    
    -- Call submenu's CustomRender if available (for overlays like player info panel)
    if Menu.currentSubmenu and Menu.currentSubmenu.CustomRender then
        Menu.currentSubmenu:CustomRender()
    end
    
    -- Tooltip rendering
    -- Get current option to show tooltip
    local currentOptionIndex = Menu.currentOption
    local options = Menu.GetVisibleOptions()
    if options and options[currentOptionIndex] then
        local opt = options[currentOptionIndex]
        if opt.tooltip and opt.tooltip ~= "" then
            local displayTooltip = opt.GetDisplayTooltip and opt:GetDisplayTooltip() or opt.tooltip
            Renderer.RenderTooltip(displayTooltip, opt.canBeSaved, opt.hasHotkey, opt.hotkey)
        end
    end
    
    -- Render Active Overlay (on top of everything)
    if Menu.activeOverlay and Menu.activeOverlay.Render then
        -- Ensure overlay renders on top of tooltips
        Menu.activeOverlay:Render()
    end
    
end

--- Render the header
function Menu.RenderHeader()
    local posX = Renderer.Layout.posX
    local posY = Renderer.Layout.posY
    local width = Renderer.Layout.width
    local height = Renderer.Layout.headerHeight
    
    -- Draw header sprite
    Renderer.DrawSprite(Renderer.Textures.Header, posX, posY, width, height, 0, 
                       { r = 255, g = 255, b = 255, a = Renderer.headerAlpha }, false)
    
    -- Draw bottom border line
    Renderer.DrawRect(posX, posY - 0.0415 + 0.1175 - 0.035 + Renderer.Layout.lineWidth / 2, 
                     width, Renderer.Layout.lineWidth, Renderer.Colors.Outline)
end

--- Render the subheader (title bar)
function Menu.RenderSubHeader()
    local posX = Renderer.Layout.posX
    local subHeaderY = Renderer.Calculated.subHeaderY
    local width = Renderer.Layout.width
    local height = Renderer.Layout.subHeaderHeight
    
    Renderer.DrawRect(posX, subHeaderY, width, height, Renderer.Colors.SubHeader)
    
    -- Draw submenu title
    if Menu.currentSubmenu and Menu.currentSubmenu.name then
        local Translation = require("Impulse/ImpulseLua/lib/translation")
        local displayName = Translation.IsLoaded() and Translation.GetFlat(Menu.currentSubmenu.name) or Menu.currentSubmenu.name
        Renderer.DrawString(displayName, posX, subHeaderY - height / 2 + 0.001,
                           Renderer.Font.ChaletComprimeCologne, 0.3, Renderer.Colors.Title,
                           false, 0, posX - width / 2, posX + width / 2)
    end
end

--- Render the background
function Menu.RenderBackground()
    local posX = Renderer.Layout.posX
    local bgY = Renderer.Calculated.backgroundY
    local width = Renderer.Layout.width
    local height = Renderer.Calculated.backgroundHeight
    
    local bgOpacity = math.floor(Renderer.Layout.bgOpacity * 255 / 100)
    local bgColor = { r = Renderer.Colors.Primary.r, g = Renderer.Colors.Primary.g, 
                     b = Renderer.Colors.Primary.b, a = bgOpacity }
    
    Renderer.DrawRect(posX, bgY, width, height, bgColor)
    
    -- Bottom border
    Renderer.DrawRect(posX, bgY + height / 2 - Renderer.Layout.lineWidth / 2, 
                     width, Renderer.Layout.lineWidth, Renderer.Colors.Outline)
end

--- Render all options
---@param options table Array of options
function Menu.RenderOptions(options)
    local start = Menu.scrollOffset + 1
    local finish = math.min(Menu.scrollOffset + Menu.maxOptions, #options)
    
    for i = start, finish do
        local option = options[i]
        local displayPos = i - Menu.scrollOffset - 1 -- 0-indexed for rendering
        
        if option then
            option:Render(displayPos)
            
            -- If this is the selected option, also call RenderSelected
            if i == Menu.currentOption then
                option:RenderSelected(displayPos)
            end
        end
    end
end

--- Render the option highlight/selection bar
function Menu.RenderOptionHighlight()
    local posX = Renderer.Layout.posX
    local width = Renderer.Layout.width
    local optHeight = Renderer.Layout.optionHeight
    
    local displayPos = Menu.currentOption - Menu.scrollOffset - 1
    local y = Renderer.GetOptionY(displayPos) + optHeight / 2
    
    -- Main selection bar
    Renderer.DrawRect(posX, y, width, optHeight, Renderer.Colors.Selection)
    
    -- Top highlight line
    local highlightColor = Renderer.GetColorOffset(Renderer.Colors.Selection, 75)
    Renderer.DrawRect(posX, y - optHeight / 2 + Renderer.Layout.lineWidth / 2, 
                     width, Renderer.Layout.lineWidth, highlightColor)
    
    -- Bottom shadow line
    local shadowColor = Renderer.GetColorOffset(Renderer.Colors.Selection, -75)
    Renderer.DrawRect(posX, y + optHeight / 2 - Renderer.Layout.lineWidth / 2,
                     width, Renderer.Layout.lineWidth, shadowColor)
end

--- Render the footer
function Menu.RenderFooter()
    local posX = Renderer.Layout.posX
    local footerY = Renderer.Calculated.footerY
    local width = Renderer.Layout.width
    local height = Renderer.Layout.footerHeight
    
    Renderer.DrawRect(posX, footerY, width, height, Renderer.Colors.SubHeader)
    
    -- Footer logo
    Renderer.DrawSprite(Renderer.Textures.Footer, posX, footerY, width / 2.5, height / 1.5, 0,
                       { r = 255, g = 255, b = 255, a = Renderer.Colors.SubHeader.a })
    
    -- Page counter
    local currentWithoutBreaks = Menu.GetCurrentOptionWithoutBreaks()
    local totalWithoutBreaks = Menu.GetTotalOptionsWithoutBreaks()
    local counterText = string.format("%d / %d", currentWithoutBreaks, totalWithoutBreaks)
    Renderer.DrawString(counterText, posX - width / 2 + 0.006, footerY - 0.013,
                       Renderer.Font.ChaletLondon, 0.3, Renderer.Colors.Title, false)
                       
    -- Version Display
    if Renderer.showVersion and Renderer.ScriptVersion then
        Renderer.DrawString(Renderer.ScriptVersion, posX + width / 2 - 0.006, footerY - 0.013, 
                           Renderer.Font.ChaletLondon, 0.3, Renderer.Colors.Title, 
                           false, 2, posX - width / 2, posX + width / 2 - 0.006)
    end
end

-- Scrollbar state for smooth animation
Menu.scrollbarState = {
    easedPosition = 0,
    lastTime = 0
}

--- Render the scrollbar on the left side of the menu
function Menu.RenderScrollbar()
    local posX = Renderer.Layout.posX
    local width = Renderer.Layout.width
    
    -- Scrollbar X position (left of menu)
    local sliderX = posX - width / 2 - 0.01
    
    -- Scrollbar Y positions
    local sliderTop = Renderer.Calculated.backgroundY - Renderer.Calculated.backgroundHeight / 2
    local sliderBottom = Renderer.Calculated.backgroundY + Renderer.Calculated.backgroundHeight / 2
    
    -- Calculate slider thumb position based on current option
    local totalWithoutBreaks = Menu.GetTotalOptionsWithoutBreaks()
    local currentWithoutBreaks = Menu.GetCurrentOptionWithoutBreaks()
    
    local sliderPosition = 0
    if totalWithoutBreaks > 1 then
        sliderPosition = ((currentWithoutBreaks - 1) / (totalWithoutBreaks - 1)) * 
                         (Renderer.Calculated.backgroundHeight - Renderer.Layout.optionHeight) + 
                         Renderer.Layout.optionHeight / 2
    else
        sliderPosition = Renderer.Calculated.backgroundHeight - Renderer.Layout.optionHeight + 
                         Renderer.Layout.optionHeight / 2
    end
    
    -- Smooth animation (lerp)
    local currentTime = MISC.GET_GAME_TIMER()
    local deltaTime = (currentTime - Menu.scrollbarState.lastTime) / 1000
    Menu.scrollbarState.lastTime = currentTime
    
    -- Clamp delta time to prevent huge jumps
    if deltaTime > 0.1 then deltaTime = 0.1 end
    
    -- Lerp the position (10 * deltaTime gives smooth easing)
    local lerpFactor = math.min(1, 10 * deltaTime)
    Menu.scrollbarState.easedPosition = Menu.scrollbarState.easedPosition + 
        (sliderPosition - Menu.scrollbarState.easedPosition) * lerpFactor
    
    local easedSliderPosition = Menu.scrollbarState.easedPosition
    
    -- Draw top arrow button (black rect + arrow sprite)
    Renderer.DrawRect(sliderX, sliderTop - 0.007, 0.01, 0.014, { r = 0, g = 0, b = 0, a = 255 })
    Renderer.DrawSprite({ dict = "commonmenu", name = "arrowright" }, 
        sliderX, sliderTop - 0.007, 0.015, 0.015, -90, { r = 255, g = 255, b = 255, a = 255 })
    
    -- Draw bottom arrow button (black rect + arrow sprite)
    Renderer.DrawRect(sliderX, sliderBottom + 0.007, 0.01, 0.014, { r = 0, g = 0, b = 0, a = 255 })
    Renderer.DrawSprite({ dict = "commonmenu", name = "arrowright" }, 
        sliderX, sliderBottom + 0.007, 0.015, 0.015, 90, { r = 255, g = 255, b = 255, a = 255 })
    
    -- Draw track background (primary color with alpha)
    local trackColor = {
        r = Renderer.Colors.Primary.r,
        g = Renderer.Colors.Primary.g,
        b = Renderer.Colors.Primary.b,
        a = 100
    }
    Renderer.DrawRect(sliderX, Renderer.Calculated.backgroundY, 0.01, 
                     Renderer.Calculated.backgroundHeight, trackColor)
    
    -- Draw slider thumb (selection color)
    if totalWithoutBreaks > 0 then
        local thumbHeight = Renderer.Layout.optionHeight - 0.006
        Renderer.DrawRect(sliderX, sliderTop + easedSliderPosition, 0.008, thumbHeight, 
                         Renderer.Colors.Selection)
        
        -- Top edge highlight
        local topEdgeColor = Renderer.GetColorOffset(Renderer.Colors.Selection, 75)
        Renderer.DrawRect(sliderX, sliderTop + easedSliderPosition - thumbHeight / 2 + Renderer.Layout.lineWidth / 2, 
                         0.008, Renderer.Layout.lineWidth, topEdgeColor)
        
        -- Bottom edge shadow
        local bottomEdgeColor = Renderer.GetColorOffset(Renderer.Colors.Selection, -75)
        Renderer.DrawRect(sliderX, sliderTop + easedSliderPosition + thumbHeight / 2 - Renderer.Layout.lineWidth / 2, 
                         0.008, Renderer.Layout.lineWidth, bottomEdgeColor)
    end
end

return Menu
