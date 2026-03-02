--[[
    Impulse Lua - Spawn Vehicle Settings Menu
    Port of spawnVehicleSettingsMenu.h/cpp equivalent variables
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ColorOption = require("Impulse/ImpulseLua/lib/options/color")

local SpawnVehicleSettingsMenu = setmetatable({}, { __index = Submenu })
SpawnVehicleSettingsMenu.__index = SpawnVehicleSettingsMenu

local instance = nil

-- Global vars exposed for the spawn menu to use
SpawnVehicleSettingsMenu.vars = {
    spawnin = true,
    spawninvincible = false,
    spawnmaxed = false,
    deleteold = true,
    spawninair = false,
    spawndefault = true, -- Use default colors
    blip = true,
    spawnspeed = 0.0,
    spawnheight = 0.0, -- Actually float in C++, but usually just an offset
    fade = false,
    particles = false,
    information = false,
    
    dprimary = { r = 0, g = 0, b = 0, a = 255 },
    dsecondary = { r = 0, g = 0, b = 0, a = 255 }
}

function SpawnVehicleSettingsMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Spawner settings"), SpawnVehicleSettingsMenu)
        instance:Init()
    end
    return instance
end

function SpawnVehicleSettingsMenu:Init()
    local vars = SpawnVehicleSettingsMenu.vars

    self:AddOption(ToggleOption.new("Spawn in")
        :AddToggleRef(vars, "spawnin")
        :AddTooltip("Teleport into vehicle when spawned"))

    self:AddOption(ToggleOption.new("Spawn invincible")
        :AddToggleRef(vars, "spawninvincible")
        :AddTooltip("Vehicle will be godmode when spawned"))

    self:AddOption(ToggleOption.new("Spawn maxed")
        :AddToggleRef(vars, "spawnmaxed")
        :AddTooltip("Vehicle will be fully upgraded when spawned"))

    self:AddOption(ToggleOption.new("Delete old")
        :AddToggleRef(vars, "deleteold")
        :AddTooltip("Delete the previous vehicle when spawning a new one"))
    
    self:AddOption(ToggleOption.new("Spawn in air")
        :AddToggleRef(vars, "spawninair")
        :AddTooltip("Spawn air vehicles in the air"))

    self:AddOption(ToggleOption.new("Blip")
        :AddToggleRef(vars, "blip")
        :AddTooltip("Add a blip to the spawned vehicle"))
        
    self:AddOption(ToggleOption.new("Spawn with particles")
        :AddToggleRef(vars, "particles")
        :AddTooltip("Spawn vehicle with particles"))

    self:AddOption(ToggleOption.new("Spawn with information")
        :AddToggleRef(vars, "information")
        :AddTooltip("Spawn vehicle with information"))
        
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Spawn speed")
        :AddNumberRef(vars, "spawnspeed", "%.0f", 1)
        :AddMin(0):AddMax(300)
        :AddTooltip("The speed at which your spawned vehicle will launch"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Spawn height")
        :AddNumberRef(vars, "spawnheight", "%.2f", 5.0)
        :AddMin(0.0):AddMax(1000.0)
        :AddTooltip("The height at which your spawned vehicle will be at"))

    -- Color Submenu
    local colorSubmenu = Submenu.new("Color")

    colorSubmenu:AddOption(ToggleOption.new("Do not spawn with custom colors")
        :AddToggleRef(vars, "spawndefault")
        :AddTooltip("This will leave the vehicle spawn as games default"))
        
    colorSubmenu:AddOption(ColorOption.new("Default primary vehicle color")
        :AddColor(vars.dprimary)
        :AddTooltip("Set the primary vehicle color"))
        
    colorSubmenu:AddOption(ColorOption.new("Default secondary vehicle color")
        :AddColor(vars.dsecondary)
        :AddTooltip("Secondary color for vehicles"))

    self:AddOption(SubmenuOption.new("Color")
        :AddSubmenu(colorSubmenu)
        :AddTooltip("Vehicle color settings"))
end

return SpawnVehicleSettingsMenu
