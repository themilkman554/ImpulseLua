--[[
    Impulse Lua - Scaleform Helper
    Draw scaleform notifications and instructional buttons
    Port of scaleform.cpp from Impulse C++
]]

local Scaleform = {}

-- Scaleform handles
Scaleform.instructionalButtons = 0
Scaleform.largeMessage = 0

-- Message queue
Scaleform.messageQueue = {}
Scaleform.currentMessage = nil
Scaleform.messageStartTime = 0

--[[ ============================================
    INSTRUCTIONAL BUTTONS
============================================ ]]

--- Prepare instructional buttons for this frame
function Scaleform:PrepareInstructionalButtons()
    if self.instructionalButtons == 0 then
        self.instructionalButtons = GRAPHICS.REQUEST_SCALEFORM_MOVIE("instructional_buttons")
    end
    
    if not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(self.instructionalButtons) then
        return
    end
    
    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.instructionalButtons, "CLEAR_ALL")
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
    
    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.instructionalButtons, "SET_CLEAR_SPACE")
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(200)
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end

--- Add an instructional button
---@param text string Button label
---@param control number|string Control or key name
function Scaleform:AddInstructionalButton(text, control)
    if not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(self.instructionalButtons) then
        return
    end
    
    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.instructionalButtons, "SET_DATA_SLOT")
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(self.buttonSlots and #self.buttonSlots or 0)
    
    -- Add control icon
    if type(control) == "number" then
        GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING(PAD.GET_CONTROL_INSTRUCTIONAL_BUTTONS_STRING(0, control, true))
    else
        GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING(control)
    end
    
    -- Add label
    GRAPHICS.BEGIN_TEXT_COMMAND_SCALEFORM_STRING("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    GRAPHICS.END_TEXT_COMMAND_SCALEFORM_STRING()
    
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
end

--- Draw instructional button (single)
---@param text string Button text
---@param key string Key name to display
function Scaleform:DrawInstructional(text, key)
    if self.instructionalButtons == 0 then
        self.instructionalButtons = GRAPHICS.REQUEST_SCALEFORM_MOVIE("instructional_buttons")
    end
    
    if not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(self.instructionalButtons) then
        return
    end
    
    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.instructionalButtons, "CLEAR_ALL")
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
    
    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.instructionalButtons, "SET_CLEAR_SPACE")
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(200)
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
    
    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.instructionalButtons, "SET_DATA_SLOT")
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(0)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING(key)
    
    GRAPHICS.BEGIN_TEXT_COMMAND_SCALEFORM_STRING("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    GRAPHICS.END_TEXT_COMMAND_SCALEFORM_STRING()
    
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
    
    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.instructionalButtons, "DRAW_INSTRUCTIONAL_BUTTONS")
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
    
    GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(self.instructionalButtons, 255, 255, 255, 255, 0)
end

--- Finish instructional buttons
function Scaleform:FinishInstructionalButtons()
    if not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(self.instructionalButtons) then
        return
    end
    
    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.instructionalButtons, "DRAW_INSTRUCTIONAL_BUTTONS")
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
    
    GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(self.instructionalButtons, 255, 255, 255, 255, 0)
end

--[[ ============================================
    LARGE MESSAGE (MP_BIG_MESSAGE_FREEMODE)
============================================ ]]

--- Queue a large message to display
---@param title string Title text
---@param subtitle string Subtitle text
---@param duration number Duration in 100ms units
---@param fadeTime number Fade time
function Scaleform:DrawLargeMessage(title, subtitle, duration, fadeTime)
    table.insert(self.messageQueue, {
        title = title,
        subtitle = subtitle,
        duration = duration * 500, -- Convert to ms
        fadeTime = fadeTime
    })
end

--- Show shard message (like mission passed)
---@param title string Title
---@param subtitle string Subtitle
---@param bgColor number Background color index
function Scaleform:ShowShardMessage(title, subtitle, bgColor)
    local scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE("MP_BIG_MESSAGE_FREEMODE")
    
    local timeout = 0
    while not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(scaleform) and timeout < 100 do
        Script.Yield()
        timeout = timeout + 1
    end
    
    if not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(scaleform) then
        return
    end
    
    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
    
    GRAPHICS.BEGIN_TEXT_COMMAND_SCALEFORM_STRING("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(title)
    GRAPHICS.END_TEXT_COMMAND_SCALEFORM_STRING()
    
    GRAPHICS.BEGIN_TEXT_COMMAND_SCALEFORM_STRING("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(subtitle)
    GRAPHICS.END_TEXT_COMMAND_SCALEFORM_STRING()
    
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(bgColor or 0)
    
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
    
    -- Draw for a few seconds
    local startTime = MISC.GET_GAME_TIMER()
    while MISC.GET_GAME_TIMER() - startTime < 4000 do
        GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 255, 0)
        Script.Yield()
    end
    
    GRAPHICS.SET_SCALEFORM_MOVIE_AS_NO_LONGER_NEEDED(scaleform)
end

--- Update and render current message
function Scaleform:Update()
    -- Check for new message
    if not self.currentMessage and #self.messageQueue > 0 then
        self.currentMessage = table.remove(self.messageQueue, 1)
        self.messageStartTime = MISC.GET_GAME_TIMER()
        
        -- Load scaleform
        if self.largeMessage == 0 then
            self.largeMessage = GRAPHICS.REQUEST_SCALEFORM_MOVIE("MP_BIG_MESSAGE_FREEMODE")
        end
    end
    
    -- Render current message
    if self.currentMessage then
        if GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(self.largeMessage) then
            local elapsed = MISC.GET_GAME_TIMER() - self.messageStartTime
            
            if elapsed < self.currentMessage.duration then
                GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(self.largeMessage, "SHOW_SHARD_WASTED_MP_MESSAGE")
                
                GRAPHICS.BEGIN_TEXT_COMMAND_SCALEFORM_STRING("STRING")
                HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(self.currentMessage.title)
                GRAPHICS.END_TEXT_COMMAND_SCALEFORM_STRING()
                
                GRAPHICS.BEGIN_TEXT_COMMAND_SCALEFORM_STRING("STRING")
                HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(self.currentMessage.subtitle)
                GRAPHICS.END_TEXT_COMMAND_SCALEFORM_STRING()
                
                GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(0)
                GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
                
                GRAPHICS.DRAW_SCALEFORM_MOVIE_FULLSCREEN(self.largeMessage, 255, 255, 255, 255, 0)
            else
                self.currentMessage = nil
            end
        end
    end
end

return Scaleform
