--[[
    Impulse Lua - TV Menu
    Port of miscTVMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")

local TVMenu = setmetatable({}, { __index = Submenu })
TVMenu.__index = TVMenu

local instance = nil

function TVMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("TV"), TVMenu)
        instance:Init()
    end
    return instance
end

-- Variables (Defaults from miscTVMenu.h)
local vars = {
    tv = false,
    channel = 0,
    volume = 0.5,
    x = 0.84, -- C++ Default
    y = 0.20, -- C++ Default
    w = 0.26, -- C++ Default
    h = 0.27, -- C++ Default
    rotation = 0.0
}

function TVMenu:Init()
    -- Initialize TV Channel 0 with a playlist to ensure content
    if GRAPHICS.SET_TV_CHANNEL_PLAYLIST then
        GRAPHICS.SET_TV_CHANNEL_PLAYLIST(0, "PL_STD_CNT", true)
        GRAPHICS.SET_TV_CHANNEL(0)
    end
    -- Enable subtitles just in case, though we are removing the render ID lock
    if HUD.ENABLE_MOVIE_SUBTITLES then
        HUD.ENABLE_MOVIE_SUBTITLES(true)
    end

    -- Toggle TV
    self:AddOption(ToggleOption.new("Toggle TV", function(state)
        vars.tv = state
    end))

    -- Change Volume
    local volOpt = NumberOption.new(1, "Change volume")
        :AddNumber(vars.volume, "%.2f", 0.05)
        :AddMin(0.0)
        :AddMax(1.0)
    volOpt:AddFunction(function()
        vars.volume = volOpt:GetValue()
        GRAPHICS.SET_TV_VOLUME(vars.volume)
    end)
    self:AddOption(volOpt)

    -- Change Channel
    local chanOpt = NumberOption.new(1, "Change channel")
        :AddNumber(vars.channel, "%i", 1)
        :AddMin(0)
        :AddMax(2) -- only 0-2 (3 channels) usually
    chanOpt:AddFunction(function()
        vars.channel = chanOpt:GetValue()
        GRAPHICS.SET_TV_CHANNEL(vars.channel)
    end)
    self:AddOption(chanOpt)

    -- X Position
    local xOpt = NumberOption.new(1, "X")
        :AddNumber(vars.x, "%.2f", 0.01)
        :AddMin(0.0)
        :AddMax(1.0)
    xOpt:AddFunction(function()
        vars.x = xOpt:GetValue()
    end)
    self:AddOption(xOpt)

    -- Y Position
    local yOpt = NumberOption.new(1, "Y")
        :AddNumber(vars.y, "%.2f", 0.01)
        :AddMin(0.0)
        :AddMax(1.0)
    yOpt:AddFunction(function()
        vars.y = yOpt:GetValue()
    end)
    self:AddOption(yOpt)

    -- Width
    local wOpt = NumberOption.new(1, "W")
        :AddNumber(vars.w, "%.2f", 0.01)
        :AddMin(0.0)
        :AddMax(1.0)
    wOpt:AddFunction(function()
        vars.w = wOpt:GetValue()
    end)
    self:AddOption(wOpt)

    -- Height
    local hOpt = NumberOption.new(1, "H")
        :AddNumber(vars.h, "%.2f", 0.01)
        :AddMin(0.0)
        :AddMax(1.0)
    hOpt:AddFunction(function()
        vars.h = hOpt:GetValue()
    end)
    self:AddOption(hOpt)

    -- Rotation
    local rotOpt = NumberOption.new(1, "Rotation")
        :AddNumber(vars.rotation, "%.2f", 1.0)
        :AddMin(0.0)
        :AddMax(360.0)
    rotOpt:AddFunction(function()
        vars.rotation = rotOpt:GetValue()
    end)
    self:AddOption(rotOpt)
end

function TVMenu:FeatureUpdate()
    if vars.tv then
        -- Removed implicit HUD render target (ID 1) as it might be blocking visibility
        -- Drawing directly to screen at logical coords
        
        GRAPHICS.SET_SCRIPT_GFX_DRAW_ORDER(4)
        GRAPHICS.SET_SCRIPT_GFX_DRAW_BEHIND_PAUSEMENU(1)
        
        -- Draw
        GRAPHICS.DRAW_TV_CHANNEL(vars.x, vars.y, vars.w, vars.h, vars.rotation, 255, 255, 255, 255)
    end
end

return TVMenu
