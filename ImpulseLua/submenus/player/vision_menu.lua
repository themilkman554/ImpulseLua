--[[
    Impulse Lua - Vision Menu
    Port of visionMenu.cpp from Impulse C++
    Controls screen visual effects using timecycle modifiers
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")

---@class VisionMenu : Submenu
local VisionMenu = setmetatable({}, { __index = Submenu })
VisionMenu.__index = VisionMenu

-- Vision presets: { Display Name, Timecycle Modifier Name }
local visions = {
    { "Default", "" },
    { "Damage", "damage" },
    { "Vagos", "VagosSPLASH" },
    { "Cops", "CopsSPLASH" },
    { "White screen", "BarryFadeOut" },
    { "Water lab", "WATER_lab" },
    { "MP spectator cam", "Multipayer_spectatorCam" },
    { "Cops 2", "cops" },
    { "Spectator 1", "spectator1" },
    { "Sunglasses", "sunglasses" },
    { "Dying", "dying" },
    { "Orange", "REDMIST" },
    { "Vagos 2", "vagos" },
    { "Blurry", "CHOP" },
    { "Stoned", "stoned" },
    { "Prologue shootout", "prologue_shootout" },
    { "Secret camera", "secret_camera" },
    { "UFO", "ufo" },
    { "UFO deathray", "ufo_deathray" },
    { "Wobbly", "drug_wobbly" },
    { "Killstreak", "MP_Killstreak" },
    { "Hint cam", "Hint_cam" },
    { "Black and white", "blackNwhite" },
    { "Sniper", "sniper" },
    { "Crane cam", "crane_cam" },
    { "Bikers", "BikersSPLASH" },
}

function VisionMenu.new()
    local self = setmetatable(Submenu.new("Vision"), VisionMenu)
    return self
end

function VisionMenu:Init()
    -- Add button for each vision preset
    for _, vision in ipairs(visions) do
        local displayName = vision[1]
        local modifierName = vision[2]
        
        self:AddOption(ButtonOption.new(displayName)
            :AddFunction(function()
                if modifierName == "" then
                    -- Clear timecycle modifier for "Default"
                    GRAPHICS.CLEAR_TIMECYCLE_MODIFIER()
                else
                    -- Set the timecycle modifier
                    GRAPHICS.SET_TIMECYCLE_MODIFIER(modifierName)
                end
            end)
            :AddTooltip("Set this vision")
            :AddHotkey())
    end
end

-- No FeatureUpdate needed for this menu
function VisionMenu:FeatureUpdate()
end

return VisionMenu
