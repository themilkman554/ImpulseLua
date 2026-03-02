--[[
    Impulse Lua - Misc Menu
    Port of miscMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")

local MiscMenu = setmetatable({}, { __index = Submenu })
MiscMenu.__index = MiscMenu

local instance = nil

function MiscMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Miscellaneous"), MiscMenu)
        instance:Init()
    end
    return instance
end

-- State variables
local miscState = {
    freecam = false,
    oldStyleCam = false,
    cameraZoom = false,
    cameraZoomValue = 1,
    fps = false,
    coords = false,
    potatoPc = false,
    mobileRadio = false,
    restrictedAreas = false,
    seeThroughWalls = false,
    snowTrails = false,
}

local camHandles = {}

--[[ ============================================
    HELPER FUNCTIONS
============================================ ]]

local function DrawText(text, x, y, scale, r, g, b, a)
    HUD.SET_TEXT_FONT(0)
    HUD.SET_TEXT_SCALE(scale, scale)
    HUD.SET_TEXT_COLOUR(r, g, b, a)
    HUD.SET_TEXT_WRAP(0.0, 1.0)
    HUD.SET_TEXT_CENTRE(false)
    HUD.SET_TEXT_DROPSHADOW(0, 0, 0, 0, 0)
    HUD.SET_TEXT_OUTLINE()
    HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_DISPLAY_TEXT(x, y, 0)
end

local function EnableRestrictedAreas(toggle)
    if toggle then
        local restrictedAreaScripts = {
            "am_armybase",
            "restrictedareas",
            "re_armybase",
            "re_lossantosintl",
            "re_prison",
            "re_prisonvanbreak"
        }
        for _, script in ipairs(restrictedAreaScripts) do
            if SCRIPT.DOES_SCRIPT_EXIST(script) then
                MISC.TERMINATE_ALL_SCRIPTS_WITH_THIS_NAME(script)
            end
        end
    end
end





--[[ ============================================
    INIT
============================================ ]]

local ReportStatsMenu = require("Impulse/ImpulseLua/submenus/misc/report_stats_menu")
local TVMenu = require("Impulse/ImpulseLua/submenus/misc/tv_menu")
local DisablesMenu = require("Impulse/ImpulseLua/submenus/misc/disables_menu")
local TrainOptionsMenu = require("Impulse/ImpulseLua/submenus/misc/train_options_menu")
local HudEditorMenu = require("Impulse/ImpulseLua/submenus/misc/hud_editor_menu")

function MiscMenu:Init()
    -- Submenu link placeholders (as requested "1:1" where possible, but empty/buttons for now if no logic)
    self:AddOption(SubmenuOption.new("Report stats")
        :AddSubmenu(ReportStatsMenu.GetInstance())
        :AddTooltip("See your reports/commends"))

    self:AddOption(SubmenuOption.new("Mobile TV")
        :AddSubmenu(TVMenu.GetInstance())
        :AddTooltip("Watch TV on the go"))

    self:AddOption(SubmenuOption.new("Disables")
        :AddSubmenu(DisablesMenu.GetInstance())
        :AddTooltip("Disables checks and UI elements"))



    self:AddOption(SubmenuOption.new("Hud editor")
        :AddSubmenu(HudEditorMenu.GetInstance())
        :AddTooltip("Change the color of your HUD elements"))

    self:AddOption(SubmenuOption.new("Train options")
        :AddSubmenu(TrainOptionsMenu.GetInstance())
        :AddTooltip("Contains options to control and spawn trains"))


    self:AddOption(BreakOption.new("Camera"))

    -- Freecam (Using built-in)
    miscState.freecam = FeatureState.Get("Free Cam")
    self:AddOption(ToggleOption.new("Freecam")
        :AddToggleRef(miscState, "freecam")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Free Cam"):Toggle(miscState.freecam)
        end)
        :AddTooltip("Freecam (Built-in)")
        :AddHotkey())
        
    -- Freecam speed (Placeholder as we use built-in)
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Freecam speed")
        :AddTooltip("Control the forward and back speed of the freecam (Use built-in controls)"))

    -- Freecam attack mode
    self:AddOption(ToggleOption.new("Freecam attack mode")
        :AddTooltip("To fire rockets press space (Use built-in if available)"))

    -- Freecam teleport
    self:AddOption(ToggleOption.new("Freecam teleport")
        :AddTooltip("This will teleport you to the final location of freecam (Use built-in)"))

    self:AddOption(ToggleOption.new("Freecam controller toggle")
        :AddTooltip("This will allow on and off of freecam using a controller (Use built-in)"))

    -- GTA 1 Camera (Built-in)
    miscState.oldStyleCam = FeatureState.Get("GTA 1 Cam")
    self:AddOption(ToggleOption.new("GTA 1 camera")
        :AddToggleRef(miscState, "oldStyleCam")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("GTA 1 Cam"):Toggle(miscState.oldStyleCam)
        end)
        :AddTooltip("This will make your games camera function like gta 1")
        :AddHotkey())

    -- Camera Zoom
    self:AddOption(NumberOption.new(NumberOption.Type.TOGGLE, "Camera zoom")
        :AddToggleRef(miscState, "cameraZoom")
        :SetNumber(miscState, "cameraZoomValue")
        :SetMin(1):SetMax(1000):SetStep(1) -- Step 1 speed 10
        :AddTooltip("Camera zoom"))

    self:AddOption(BreakOption.new("HUD/Display Options"))

    self:AddOption(ToggleOption.new("FPS display")
        :AddToggleRef(miscState, "fps")
        :AddTooltip("Display your FPS")
        :AddHotkey())

    self:AddOption(ToggleOption.new("Coords display")
        :AddToggleRef(miscState, "coords")
        :AddTooltip("Display your current coords")
        :AddHotkey())

    self:AddOption(ButtonOption.new("Remove transaction loading")
        :AddFunction(function()
            if HUD.BUSYSPINNER_IS_ON() then
                HUD.BUSYSPINNER_OFF()
            end
        end)
        :AddTooltip("Remove a stuck transaction loading")
        :AddHotkey())

    self:AddOption(ToggleOption.new("Decreased graphics mode")
        :AddToggleRef(miscState, "potatoPc")
        :AddFunction(function()
            if not miscState.potatoPc then
                STREAMING.SET_FOCUS_ENTITY(PLAYER.PLAYER_PED_ID())
            end
        end)
        :AddTooltip("Warning: once enabled your game will look like ass")
        :AddHotkey())

    self:AddOption(ButtonOption.new("Reset graphics in your area")
        :AddFunction(function()
            STREAMING.SET_FOCUS_ENTITY(PLAYER.PLAYER_PED_ID())
        end)
        :AddTooltip("Use this to fix any map loading issues")
        :AddHotkey())

    self:AddOption(BreakOption.new("Other"))

    self:AddOption(ToggleOption.new("Dev mode")
        :AddFunction(function()
           -- Backend.DevMode toggle if wrapper available?
           -- For now just a placeholder toggle or access Settings
           -- Settings.DevMode = not Settings.DevMode
        end)
        :AddTooltip("Enter GTA developer mode (SCTV) (Not fully implemented)")
        :AddHotkey())

    self:AddOption(ToggleOption.new("Mobile radio")
        :AddToggleRef(miscState, "mobileRadio")
        :AddTooltip("This allows you to listen to radio while on the move")
        :AddHotkey())

    self:AddOption(ButtonOption.new("Skip radio track")
        :AddFunction(function()
            AUDIO.SKIP_RADIO_FORWARD()
        end)
        :AddTooltip("Skip [local] radio tracks on mobile radio")
        :AddHotkey())

    self:AddOption(ToggleOption.new("Bypass restricted areas")
        :AddToggleRef(miscState, "restrictedAreas")
        :AddFunction(function()
             if miscState.restrictedAreas then EnableRestrictedAreas(true) end
        end)
        :AddTooltip("This will allow you to access restricted areas of the game")
        :AddHotkey())

    self:AddOption(ToggleOption.new("See through walls")
        :AddToggleRef(miscState, "seeThroughWalls")
        :AddTooltip("This will allow you to see through walls when aiming")
        :AddHotkey())

    self:AddOption(ToggleOption.new("Enable snow trails & footsteps")
        :AddToggleRef(miscState, "snowTrails")
        :AddFunction(function()
            if not miscState.snowTrails then
                GRAPHICS.USE_SNOW_FOOT_VFX_WHEN_UNSHELTERED(false)
                GRAPHICS.USE_SNOW_WHEEL_VFX_WHEN_UNSHELTERED(false)
            end
        end)
        :AddTooltip("Set footsteps and vehicle trails in snow (will work without too)")
        :AddHotkey())

    self:AddOption(ButtonOption.new("Bail to singleplayer")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Story Bail From Session"):TriggerCallback()
        end)
        :AddTooltip("Stuck in the clouds? Bind this option to bail back to SP")
        :AddHotkey())

end

--[[ ============================================
    FEATURE UPDATE
============================================ ]]

local timerCaches = {
    fps = {0, 0}, -- current, last
    timer = 0
}

function MiscMenu:FeatureUpdate()
    -- Sync external states
    miscState.freecam = FeatureState.Get("Free Cam")

    -- See Through Walls
    if miscState.seeThroughWalls then
        -- 0x42156508606DE65E(418.490f)
        -- Attempting to call by hash if native wrapper not present, or assuming it's available via invoke
        -- Cherax Lua: native.Invoke(hash, args...)
        -- native.Invoke(0x42156508606DE65E, 418.490)
    end

    if miscState.restrictedAreas then
        EnableRestrictedAreas(true)
    end

    if miscState.potatoPc then
        STREAMING.SET_FOCUS_POS_AND_VEL(9999.0, 9999.0, -9999.0, 0.0, 0.0, 0.0)
    end

    if miscState.snowTrails then
        GRAPHICS.USE_SNOW_FOOT_VFX_WHEN_UNSHELTERED(true)
        GRAPHICS.USE_SNOW_WHEEL_VFX_WHEN_UNSHELTERED(true)
    end

    if miscState.mobileRadio then
        AUDIO.SET_MOBILE_RADIO_ENABLED_DURING_GAMEPLAY(true)
    end

    -- Sync GTA 1 Cam state
    miscState.oldStyleCam = FeatureState.Get("GTA 1 Cam")

    if miscState.cameraZoom then
        -- CAM._AnimateGameplayCamZoom(1.0f, vars.cameraZoomValue);
        -- 0xDF2E1D2E
        -- native.Invoke(0xDF2E1D2E, 1.0, miscState.cameraZoomValue + 0.0)
    end

    -- FPS Display
    if miscState.fps then
        local fps = timerCaches.fps[1] - timerCaches.fps[2] - 1
        DrawText(string.format("FPS: %d", fps), 0.5, 0.0, 0.40, 255, 255, 255, 255)
    end

    -- Coords Display
    if miscState.coords then
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
        DrawText(string.format("XYZ: %.2f, %.2f, %.2f", pos.x, pos.y, pos.z), 0.01, 0.0288, 0.35, 255, 255, 255, 255)
    end

    -- Timer for FPS
    local time = MISC.GET_GAME_TIMER()
    if time - timerCaches.timer > 1000 then
        timerCaches.fps[2] = timerCaches.fps[1]
        timerCaches.fps[1] = MISC.GET_FRAME_COUNT()
        timerCaches.timer = time
    end
end

return MiscMenu
