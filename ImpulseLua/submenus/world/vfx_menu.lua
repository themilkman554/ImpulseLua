--[[
    Impulse Lua - VFX Engine Menu
    Port of VFXMenu.cpp
    
    NOTE: Many VFX options in the C++ version use direct memory access
    via GetVFX() which scans for game memory structures. This Lua port
    provides the menu structure but some memory-based features may need
    Cherax-specific memory functions to fully implement.
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local VFXMenu = setmetatable({}, { __index = Submenu })
VFXMenu.__index = VFXMenu

local instance = nil

function VFXMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("VFX Engine"), VFXMenu)
        instance:Init()
    end
    return instance
end

function VFXMenu:Init()
    self:AddOption(ButtonOption.new("Reset VFX settings")
        :AddFunction(function()
            -- Reset timecycle modifiers
            GRAPHICS.CLEAR_TIMECYCLE_MODIFIER()
        end)
        :AddTooltip("Reset all VFX settings"))

    self:AddOption(ButtonOption.new("Load VFX settings")
        :AddTooltip("Load VFX settings (Not implemented)"))

    self:AddOption(ButtonOption.new("Save VFX settings")
        :AddTooltip("Save VFX settings (Not implemented)"))

    self:AddOption(BreakOption.new(""))

    -- VFX Submenus
    local VFXTrafficLightMenu = require("Impulse/ImpulseLua/submenus/world/vfx/traffic_light_menu")
    self:AddOption(SubmenuOption.new("Traffic light VFX")
        :AddSubmenu(VFXTrafficLightMenu.GetInstance())
        :AddTooltip("Traffic light VFX"))

    local VFXVehicleMenu = require("Impulse/ImpulseLua/submenus/world/vfx/vehicle_menu")
    self:AddOption(SubmenuOption.new("Vehicle VFX")
        :AddSubmenu(VFXVehicleMenu.GetInstance())
        :AddTooltip("Vehicle VFX"))

    local VFXTrainMenu = require("Impulse/ImpulseLua/submenus/world/vfx/train_menu")
    self:AddOption(SubmenuOption.new("Train VFX")
        :AddSubmenu(VFXTrainMenu.GetInstance())
        :AddTooltip("Train VFX"))

    local VFXTonemappingMenu = require("Impulse/ImpulseLua/submenus/world/vfx/tonemapping_menu")
    self:AddOption(SubmenuOption.new("Tone mapping VFX")
        :AddSubmenu(VFXTonemappingMenu.GetInstance())
        :AddTooltip("Tone mapping VFX"))

    local VFXCoronasMenu = require("Impulse/ImpulseLua/submenus/world/vfx/coronas_menu")
    self:AddOption(SubmenuOption.new("Corona VFX")
        :AddSubmenu(VFXCoronasMenu.GetInstance())
        :AddTooltip("Corona VFX"))

    local VFXDistantLightsMenu = require("Impulse/ImpulseLua/submenus/world/vfx/distant_lights_menu")
    self:AddOption(SubmenuOption.new("Distant lights VFX")
        :AddSubmenu(VFXDistantLightsMenu.GetInstance())
        :AddTooltip("Distant lights VFX"))

    local VFXPuddlesMenu = require("Impulse/ImpulseLua/submenus/world/vfx/puddles_menu")
    self:AddOption(SubmenuOption.new("Rain puddles VFX")
        :AddSubmenu(VFXPuddlesMenu.GetInstance())
        :AddTooltip("Rain puddles VFX"))

    local VFXSkyMenu = require("Impulse/ImpulseLua/submenus/world/vfx/sky_menu")
    self:AddOption(SubmenuOption.new("Sky VFX")
        :AddSubmenu(VFXSkyMenu.GetInstance())
        :AddTooltip("Sky VFX"))
end

return VFXMenu
