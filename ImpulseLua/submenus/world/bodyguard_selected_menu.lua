--[[
    Impulse Lua - Bodyguard Selected Menu
    Port of bodyguardSelectedMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")

local BodyguardSelectedMenu = setmetatable({}, { __index = Submenu })
BodyguardSelectedMenu.__index = BodyguardSelectedMenu

local instance = nil

-- Helper to get selected bodyguard data
local function GetSelectedBodyguard()
    local BodyguardMenu = require("Impulse/ImpulseLua/submenus/world/bodyguard_menu")
    local BodyguardEditorMenu = require("Impulse/ImpulseLua/submenus/world/bodyguard_editor_menu")
    local bodyguards = BodyguardMenu.GetSpawnedBodyguards()
    local idx = BodyguardEditorMenu.GetSelectedIndex()
    
    if idx > 0 and idx <= #bodyguards then
        return bodyguards[idx], idx
    end
    return nil, 0
end

-- Helper: Get local player coords
local function GetLocalCoords()
    return ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), true)
end

function BodyguardSelectedMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Bodyguard Options"), BodyguardSelectedMenu)
        instance:Init()
    end
    return instance
end

function BodyguardSelectedMenu:Init()
    -- Godmode toggle
    self:AddOption(ToggleOption.new("Godmode")
        :AddToggle(false)
        :AddFunction(function(val)
            local bg, idx = GetSelectedBodyguard()
            if bg and ENTITY.DOES_ENTITY_EXIST(bg.Handle) then
                bg.Godmode = val
                ENTITY.SET_ENTITY_INVINCIBLE(bg.Handle, val)
            end
        end)
        :AddTooltip("Is the bodyguard invincible?")
        :AddHotkey())
    
    -- No Ragdoll toggle
    self:AddOption(ToggleOption.new("No Ragdoll")
        :AddToggle(false)
        :AddFunction(function(val)
            local bg, idx = GetSelectedBodyguard()
            if bg and ENTITY.DOES_ENTITY_EXIST(bg.Handle) then
                bg.Ragdoll = val
                if val then
                    PED.SET_PED_CAN_RAGDOLL(bg.Handle, false)
                    PED.SET_PED_CAN_RAGDOLL_FROM_PLAYER_IMPACT(bg.Handle, false)
                    PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(bg.Handle, false)
                    PED.SET_PED_RAGDOLL_ON_COLLISION(bg.Handle, false)
                else
                    PED.SET_PED_CAN_RAGDOLL(bg.Handle, true)
                    PED.SET_PED_CAN_RAGDOLL_FROM_PLAYER_IMPACT(bg.Handle, true)
                    PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(bg.Handle, true)
                    PED.SET_PED_RAGDOLL_ON_COLLISION(bg.Handle, true)
                end
            end
        end)
        :AddTooltip("Can it ragdoll?")
        :AddHotkey())
    
    -- Invisibility toggle
    self:AddOption(ToggleOption.new("Invisibility")
        :AddToggle(false)
        :AddFunction(function(val)
            local bg, idx = GetSelectedBodyguard()
            if bg and ENTITY.DOES_ENTITY_EXIST(bg.Handle) then
                bg.Invisible = val
                ENTITY.SET_ENTITY_VISIBLE(bg.Handle, not val, false)
            end
        end)
        :AddTooltip("Is it invisible?")
        :AddHotkey())
    
    -- Teleport to me
    self:AddOption(ButtonOption.new("Teleport to me")
        :AddFunction(function()
            local bg, idx = GetSelectedBodyguard()
            if bg and ENTITY.DOES_ENTITY_EXIST(bg.Handle) then
                local coords = GetLocalCoords()
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(bg.Handle, coords.x, coords.y, coords.z, false, false, false)
            end
        end)
        :AddTooltip("Teleport your bodyguard to you")
        :AddHotkey())
    
    -- Delete bodyguard
    self:AddOption(ButtonOption.new("Delete bodyguard")
        :AddFunction(function()
            local BodyguardMenu = require("Impulse/ImpulseLua/submenus/world/bodyguard_menu")
            local BodyguardEditorMenu = require("Impulse/ImpulseLua/submenus/world/bodyguard_editor_menu")
            local bodyguards = BodyguardMenu.GetSpawnedBodyguards()
            local idx = BodyguardEditorMenu.GetSelectedIndex()
            
            if idx > 0 and idx <= #bodyguards then
                local bg = bodyguards[idx]
                
                -- Remove blip if exists
                if bg.Marker and bg.Marker ~= 0 then
                    HUD.REMOVE_BLIP(bg.Marker)
                end
                
                -- Delete entity
                if ENTITY.DOES_ENTITY_EXIST(bg.Handle) then
                    pcall(function()
                        if ENTITY.DOES_ENTITY_EXIST(bg.Handle) then
                            local ptr = Memory.AllocInt()
                            Memory.WriteInt(ptr, bg.Handle)
                            ENTITY.DELETE_ENTITY(ptr)
                        end
                    end)
                end
                
                -- Remove from list
                table.remove(bodyguards, idx)
                BodyguardMenu.SetSpawnedBodyguards(bodyguards)
                
                -- Go back to previous menu
                -- Note: The menu system should handle navigation
            end
        end)
        :AddTooltip("Delete the current bodyguard")
        :AddHotkey())
end

function BodyguardSelectedMenu:Update()
    -- Draw marker on selected bodyguard
    local bg, idx = GetSelectedBodyguard()
    if bg and ENTITY.DOES_ENTITY_EXIST(bg.Handle) then
        local coords = ENTITY.GET_ENTITY_COORDS(bg.Handle, true)
        -- Matches spawn_menu.lua working example pattern
        GRAPHICS.DRAW_MARKER(21, coords.x, coords.y, coords.z + 1.5, 0, 0, 0, 180, 0, 0, 0.9, 0.9, 0.9, 0, 255, 255, 200, 1, 0, 2, 1, 0, 0, 0)
    end
end

return BodyguardSelectedMenu
