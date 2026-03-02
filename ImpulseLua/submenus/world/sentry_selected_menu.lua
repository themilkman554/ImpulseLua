local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")

local SentrySelectedMenu = setmetatable({}, { __index = Submenu })
SentrySelectedMenu.__index = SentrySelectedMenu

local instance = nil

local function GetSelectedSentry()
    local SentryMenu = require("Impulse/ImpulseLua/submenus/world/sentry_menu")
    local SentryEditorMenu = require("Impulse/ImpulseLua/submenus/world/sentry_editor_menu")
    local turrets = SentryMenu.GetSpawnedTurrets()
    local idx = SentryEditorMenu.GetSelectedIndex()
    
    if idx > 0 and idx <= #turrets then
        return turrets[idx], idx
    end
    return nil, 0
end

local function GetLocalCoords()
    return ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), true)
end

function SentrySelectedMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Sentry Options"), SentrySelectedMenu)
        instance:Init()
    end
    return instance
end

function SentrySelectedMenu:Init()
    self:AddOption(ToggleOption.new("Godmode")
        :AddToggle(false)
        :AddFunction(function(val)
            local turret, idx = GetSelectedSentry()
            if turret and ENTITY.DOES_ENTITY_EXIST(turret.ID) then
                turret.Godmode = val
                -- Apply to base and minigun
                ENTITY.SET_ENTITY_INVINCIBLE(turret.ID, val)
                if ENTITY.DOES_ENTITY_EXIST(turret.Minigun) then
                    ENTITY.SET_ENTITY_INVINCIBLE(turret.Minigun, val)
                end
            end
        end)
        :AddTooltip("Is the sentry invincible?"))
    
    self:AddOption(ToggleOption.new("Invisibility")
        :AddToggle(false)
        :AddFunction(function(val)
            local turret, idx = GetSelectedSentry()
            if turret and ENTITY.DOES_ENTITY_EXIST(turret.ID) then
                turret.Invisible = val
                ENTITY.SET_ENTITY_VISIBLE(turret.ID, not val, false)
                if ENTITY.DOES_ENTITY_EXIST(turret.Minigun) then
                    ENTITY.SET_ENTITY_VISIBLE(turret.Minigun, not val, false)
                end
            end
        end)
        :AddTooltip("Is it invisible?"))
    
    self:AddOption(ButtonOption.new("Teleport to me")
        :AddFunction(function()
            local turret, idx = GetSelectedSentry()
            if turret and ENTITY.DOES_ENTITY_EXIST(turret.ID) then
                local coords = GetLocalCoords()
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(turret.ID, coords.x, coords.y, coords.z, false, false, false)
                turret.OnGround = true
            end
        end)
        :AddTooltip("Teleport your sentry to you"))
    
    self:AddOption(ButtonOption.new("Delete sentry")
        :AddFunction(function()
            local SentryMenu = require("Impulse/ImpulseLua/submenus/world/sentry_menu")
            local SentryEditorMenu = require("Impulse/ImpulseLua/submenus/world/sentry_editor_menu")
            local turrets = SentryMenu.GetSpawnedTurrets()
            local idx = SentryEditorMenu.GetSelectedIndex()
            
            if idx > 0 and idx <= #turrets then
                local turret = turrets[idx]
                
                if ENTITY.DOES_ENTITY_EXIST(turret.ID) then
                    pcall(function()
                        local ptr = Memory.AllocInt()
                        Memory.WriteInt(ptr, turret.ID)
                        ENTITY.DELETE_ENTITY(ptr)
                    end)
                end
                
                if ENTITY.DOES_ENTITY_EXIST(turret.Minigun) then
                    pcall(function()
                         local ptr = Memory.AllocInt()
                         Memory.WriteInt(ptr, turret.Minigun)
                         ENTITY.DELETE_ENTITY(ptr)
                    end)
                end
                
                if turret.TurrentPed and turret.TurrentPed ~= 0 and ENTITY.DOES_ENTITY_EXIST(turret.TurrentPed) then
                    pcall(function()
                        local ptr = Memory.AllocInt()
                        Memory.WriteInt(ptr, turret.TurrentPed)
                        ENTITY.DELETE_ENTITY(ptr)
                    end)
                end
                
                table.remove(turrets, idx)
                SentryMenu.SetSpawnedTurrets(turrets)
            end
        end)
        :AddTooltip("Delete the current sentry"))
end

function SentrySelectedMenu:Update()
    local turret, idx = GetSelectedSentry()
    if turret and ENTITY.DOES_ENTITY_EXIST(turret.ID) then
        local coords = ENTITY.GET_ENTITY_COORDS(turret.ID, true)
        GRAPHICS.DRAW_MARKER(21, coords.x, coords.y, coords.z + 1.5, 0, 0, 0, 180, 0, 0, 0.9, 0.9, 0.9, 0, 255, 255, 200, 1, 0, 2, 1, 0, 0, 0)
    end
end

return SentrySelectedMenu
