local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")

local SentryEditorMenu = setmetatable({}, { __index = Submenu })
SentryEditorMenu.__index = SentryEditorMenu

local instance = nil
local selectedIndex = 0

local function GetLocalCoords()
    return ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), true)
end

function SentryEditorMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Edit spawned sentrys"), SentryEditorMenu)
        instance:Init()
    end
    return instance
end

function SentryEditorMenu.GetSelectedIndex()
    return selectedIndex
end

function SentryEditorMenu.SetSelectedIndex(idx)
    selectedIndex = idx
end

function SentryEditorMenu:Init()
    -- Teleport all to me
    self:AddOption(ButtonOption.new("Teleport all to me")
        :AddFunction(function()
            local SentryMenu = require("Impulse/ImpulseLua/submenus/world/sentry_menu")
            local turrets = SentryMenu.GetSpawnedTurrets()
            local coords = GetLocalCoords()
            
            for i, turret in ipairs(turrets) do
                if ENTITY.DOES_ENTITY_EXIST(turret.ID) then
                    -- Teleport base
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(turret.ID, coords.x, coords.y, coords.z, false, false, false)
                    -- Minigun is attached, so it should follow, but let's ensure it's handled if needed or just trust attachment
                    -- Reset ground flag so it snaps to ground on update loop if needed
                    turret.OnGround = true 
                end
            end
        end)
        :AddTooltip("Teleport all your sentrys to you"))
    
    -- Delete all
    self:AddOption(ButtonOption.new("Delete all")
        :AddFunction(function()
            local SentryMenu = require("Impulse/ImpulseLua/submenus/world/sentry_menu")
            local turrets = SentryMenu.GetSpawnedTurrets()
            
            for i = #turrets, 1, -1 do
                local turret = turrets[i]
                if ENTITY.DOES_ENTITY_EXIST(turret.ID) then
                    -- Delete ID (Base)
                    pcall(function()
                        local ptr = Memory.AllocInt()
                        Memory.WriteInt(ptr, turret.ID)
                        ENTITY.DELETE_ENTITY(ptr)
                    end)
                end
                
                if ENTITY.DOES_ENTITY_EXIST(turret.Minigun) then
                    -- Delete Minigun
                    pcall(function()
                         local ptr = Memory.AllocInt()
                         Memory.WriteInt(ptr, turret.Minigun)
                         ENTITY.DELETE_ENTITY(ptr)
                    end)
                end
                
                if turret.TurrentPed and turret.TurrentPed ~= 0 and ENTITY.DOES_ENTITY_EXIST(turret.TurrentPed) then
                    -- Delete Ped
                    pcall(function()
                        local ptr = Memory.AllocInt()
                        Memory.WriteInt(ptr, turret.TurrentPed)
                        ENTITY.DELETE_ENTITY(ptr)
                    end)
                end

                table.remove(turrets, i)
            end
            
            SentryMenu.SetSpawnedTurrets(turrets)
            self:OnEnter()
        end)
        :AddTooltip("Delete all spawned sentrys"))
end

function SentryEditorMenu:OnEnter()
    self:ClearOptionsFrom(3)
    
    local SentryMenu = require("Impulse/ImpulseLua/submenus/world/sentry_menu")
    local SentrySelectedMenu = require("Impulse/ImpulseLua/submenus/world/sentry_selected_menu")
    local turrets = SentryMenu.GetSpawnedTurrets()
    
    for i = 1, #turrets do
        local turret = turrets[i]
        if ENTITY.DOES_ENTITY_EXIST(turret.ID) then
            local idx = i
            local menuOptionIndex = idx + 2
            
            self:AddOption(SubmenuOption.new("Sentry [" .. idx .. "]")
                :AddSubmenu(SentrySelectedMenu.GetInstance())
                :AddFunction(function()
                    self.SetSelectedIndex(idx)
                end)
                :AddOnUpdate(function(opt)
                    local Menu = require("Impulse/ImpulseLua/lib/menu")
                    if Menu.currentOption == menuOptionIndex then
                        local coords = ENTITY.GET_ENTITY_COORDS(turret.ID, true)
                        GRAPHICS.DRAW_MARKER(21, coords.x, coords.y, coords.z + 1.5, 0, 0, 0, 180, 0, 0, 0.9, 0.9, 0.9, 0, 255, 255, 200, 1, 0, 2, 1, 0, 0, 0)
                    end
                end)
                :AddTooltip("Edit this sentry"))
        end
    end
end

function SentryEditorMenu:FeatureUpdate()
end

return SentryEditorMenu
