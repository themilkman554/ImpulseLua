--[[
    Impulse Lua - Disables Menu
    Port of miscDisable.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")

local DisablesMenu = setmetatable({}, { __index = Submenu })
DisablesMenu.__index = DisablesMenu

local instance = nil

function DisablesMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Disables"), DisablesMenu)
        instance:Init()
    end
    return instance
end

-- Variables (standard C++ names where possible)
local vars = {
    disableIdleKick = false,
    disableCinematicButton = false,
    disableStuntJumpCutscenes = false, -- Handled by FeatureMgr? Check comments below
    disablePhone = false,
    disableNotifications = false,
    disableGameRecordings = false,
    disableHUD = false -- Handled by FeatureMgr check
}

-- Helpers


local function SyncStates()
    -- Sync FeatureMgr supported features
    vars.disableStuntJumpCutscenes = FeatureState.Get("Disables Stunt Jumps from changing your camera.")
    vars.disableHUD = FeatureState.Get("Disable Hud")
end

function DisablesMenu:Init()
    -- Sync state on init
    SyncStates()

    self:AddOption(ToggleOption.new("Disable idle kick")
        :AddToggle(vars.disableIdleKick)
        :AddFunction(function(val) vars.disableIdleKick = val end)
        :AddTooltip("Don't get kicked for idling"))

    self:AddOption(ToggleOption.new("Disable cinematic button")
        :AddToggle(vars.disableCinematicButton)
        :AddFunction(function(val) vars.disableCinematicButton = val end)
        :AddTooltip("Disable cinematic button"))

    -- FeatureMgr: Disable Stunt Jumps...
    self:AddOption(ToggleOption.new("Disable stunt jump cutscenes")
        :AddToggleRef(vars, "disableStuntJumpCutscenes")
        :AddFunction(function()
            local feat = FeatureMgr.GetFeatureByName("Disables Stunt Jumps from changing your camera.")
            if feat then feat:Toggle(vars.disableStuntJumpCutscenes) end
        end)
        :AddTooltip("Disable stunt jump cutscenes"))

    self:AddOption(ToggleOption.new("Disable phone")
        :AddToggle(vars.disablePhone)
        :AddFunction(function(val) vars.disablePhone = val end)
        :AddTooltip("Disable phone calls/usage"))

    self:AddOption(ToggleOption.new("Disable notifications")
        :AddToggle(vars.disableNotifications)
        :AddFunction(function(val) vars.disableNotifications = val end)
        :AddTooltip("Disable notifications"))

    self:AddOption(ToggleOption.new("Disable game recordings")
        :AddToggle(vars.disableGameRecordings)
        :AddFunction(function(val) vars.disableGameRecordings = val end)
        :AddTooltip("Disable game recordings"))

    -- FeatureMgr: Disable Hud
    self:AddOption(ToggleOption.new("Disable HUD")
        :AddToggleRef(vars, "disableHUD")
        :AddFunction(function()
            local feat = FeatureMgr.GetFeatureByName("Disable Hud")
            if feat then feat:Toggle(vars.disableHUD) end
        end)
        :AddTooltip("Disable HUD"))
end

function DisablesMenu:FeatureUpdate()
    -- Disable idle kick
    if vars.disableIdleKick then
        if PAD.INVALIDATE_IDLE_CAM then PAD.INVALIDATE_IDLE_CAM() end
        if PAD.DISABLE_IDLE_CAMERA then PAD.DISABLE_IDLE_CAMERA(0) end
    end

    -- Disable cinematic button
    if vars.disableCinematicButton then
        if CAM.SET_CINEMATIC_BUTTON_ACTIVE then CAM.SET_CINEMATIC_BUTTON_ACTIVE(false) end
        if AUDIO.STOP_AUDIO_SCENE then AUDIO.STOP_AUDIO_SCENE("HINT_CAM_SCENE") end
        -- Additional logic from C++ (Stop hints etc)
        if CAM.STOP_GAMEPLAY_HINT then CAM.STOP_GAMEPLAY_HINT(true) end
    end

    -- Disable phone (Native frame suppression)
    if vars.disablePhone then
        if MOBILE.DISABLE_CELLPHONE_THIS_FRAME then MOBILE.DISABLE_CELLPHONE_THIS_FRAME() end
    end

    -- Disable notifications (Native frame suppression)
    if vars.disableNotifications then
        if HUD.THEFEED_HIDE_THIS_FRAME then HUD.THEFEED_HIDE_THIS_FRAME() end
        -- Native from C++ snippet: 0x25F87B30C382FCA7 (HIDE_HUD_COMPONENT_THIS_FRAME maybe? or similar)
        -- Actually 0x25F... is THEFEED_HIDE_THIS_FRAME
    end

    -- Disable game recordings
    if vars.disableGameRecordings then
        if RECORDING.STOP_RECORDING_AND_DISCARD_CLIP then RECORDING.STOP_RECORDING_AND_DISCARD_CLIP() end
    end
end

return DisablesMenu
