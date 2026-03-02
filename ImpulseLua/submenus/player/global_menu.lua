--[[
    Impulse Lua - Global Menu
    Port of globalMenu.cpp from Impulse C++
    Global memory/script variable manipulation
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")

---@class GlobalMenu : Submenu
local GlobalMenu = setmetatable({}, { __index = Submenu })
GlobalMenu.__index = GlobalMenu

-- State table for global options
local globalState = {
    otr = false,
    blindeye = false,
    revealPlayers = false,
    testosteroneLoop = false,
    noOrbitalCooldown = false,
}

-- Timers for looped features
local timers = {
    testosterone = 0,
    orbital = 0,
}

--[[ ============================================
    HELPER FUNCTIONS
============================================ ]]

local function SetBlindEye(toggle)
    -- Using native for blind eye
    PLAYER.SET_POLICE_IGNORE_PLAYER(PLAYER.PLAYER_ID(), toggle)
end

local function ClearOrbitalCooldown()
    -- Clear orbital cannon cooldown via stats
    -- Note: This requires the stat hash
    -- STAT_SET_INT for orbital cooldown would go here
end

--[[ ============================================
    MENU CREATION
============================================ ]]

function GlobalMenu.new()
    local self = setmetatable(Submenu.new("Globals"), GlobalMenu)
    return self
end

function GlobalMenu:Init()
    -- Off the radar (using internal feature)
    self:AddOption(ToggleOption.new("Off the radar")
        :AddToggleRef(globalState, "otr")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Off The Radar"):Toggle(globalState.otr)
        end)
        :AddTooltip("Invisible on the radar")
        :AddHotkey())
    
    -- Cops turn blind eye (using internal feature)
    self:AddOption(ToggleOption.new("Cops turn blind eye")
        :AddToggleRef(globalState, "blindeye")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Cops Turn Blind Eye"):Toggle(globalState.blindeye)
        end)
        :AddTooltip("Cops turn blind eye")
        :AddHotkey())
        
    -- Loop bullshark testosterone
    self:AddOption(ToggleOption.new("Loop bullshark testosterone")
        :AddToggleRef(globalState, "testosteroneLoop")
        :AddFunction(function()
            if globalState.testosteroneLoop then
                FeatureMgr.GetFeatureByName("Instant BST"):TriggerCallback()
            end
        end)
        :AddTooltip("Bullshark testosterone")
        :AddHotkey())
    
    -- No orbital cannon cooldown
    self:AddOption(ToggleOption.new("No orbital cannon cooldown")
        :AddToggleRef(globalState, "noOrbitalCooldown")
        :AddTooltip("No orbital cannon cooldown")
        :AddHotkey())
end

--[[ ============================================
    FEATURE UPDATE LOOP (Called every frame)
============================================ ]]

function GlobalMenu:FeatureUpdate()
    local currentTime = MISC.GET_GAME_TIMER()
    
    -- OTR handled by internal feature, no refresh needed here
    
    -- Blind eye refresh
    if globalState.blindeye then
        SetBlindEye(true)
    end
    
    -- Testosterone loop (every ~61.5 seconds as in C++)
    if globalState.testosteroneLoop then
        if currentTime - timers.testosterone > 61500 then
            timers.testosterone = currentTime
            FeatureMgr.GetFeatureByName("Instant BST"):TriggerCallback()
        end
    end
    
    -- Orbital cooldown reset (every 5 seconds)
    if globalState.noOrbitalCooldown then
        if currentTime - timers.orbital > 5000 then
            timers.orbital = currentTime
            ClearOrbitalCooldown()
        end
    end
end

return GlobalMenu

