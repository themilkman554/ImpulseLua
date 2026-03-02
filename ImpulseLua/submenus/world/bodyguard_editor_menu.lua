--[[
    Impulse Lua - Bodyguard Editor Menu
    Port of bodyguardMenuEditor.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")

local BodyguardEditorMenu = setmetatable({}, { __index = Submenu })
BodyguardEditorMenu.__index = BodyguardEditorMenu

local instance = nil
local selectedIndex = 0

-- Helper: Get local player coords
local function GetLocalCoords()
    return ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), true)
end

function BodyguardEditorMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Edit your bodyguards"), BodyguardEditorMenu)
        instance:Init()
    end
    return instance
end

function BodyguardEditorMenu.GetSelectedIndex()
    return selectedIndex
end

function BodyguardEditorMenu.SetSelectedIndex(idx)
    selectedIndex = idx
end

function BodyguardEditorMenu:Init()
    -- Teleport all to me
    self:AddOption(ButtonOption.new("Teleport all to me")
        :AddFunction(function()
            local BodyguardMenu = require("Impulse/ImpulseLua/submenus/world/bodyguard_menu")
            local bodyguards = BodyguardMenu.GetSpawnedBodyguards()
            local coords = GetLocalCoords()
            
            for i, bg in ipairs(bodyguards) do
                if ENTITY.DOES_ENTITY_EXIST(bg.Handle) then
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(bg.Handle, coords.x, coords.y, coords.z, false, false, false)
                end
            end
        end)
        :AddTooltip("Teleport all your bodyguards to you")
        :AddHotkey())
    
    -- Delete all
    self:AddOption(ButtonOption.new("Delete all")
        :AddFunction(function()
            local BodyguardMenu = require("Impulse/ImpulseLua/submenus/world/bodyguard_menu")
            local bodyguards = BodyguardMenu.GetSpawnedBodyguards()
            
            for i = #bodyguards, 1, -1 do
                local bg = bodyguards[i]
                if ENTITY.DOES_ENTITY_EXIST(bg.Handle) then
                    pcall(function()
                        if ENTITY.DOES_ENTITY_EXIST(bg.Handle) then
                            local ptr = Memory.AllocInt()
                            Memory.WriteInt(ptr, bg.Handle)
                            ENTITY.DELETE_ENTITY(ptr)
                        end
                    end)
                end
                
                -- Remove blip if exists
                if bg.Marker and bg.Marker ~= 0 then
                    HUD.REMOVE_BLIP(bg.Marker)
                end
                
                table.remove(bodyguards, i)
            end
            
            BodyguardMenu.SetSpawnedBodyguards(bodyguards)
            -- Rebuild menu to reflect changes
            self:OnEnter()
        end)
        :AddTooltip("Delete all spawned bodyguards")
        :AddHotkey())
end

-- Called when submenu is opened - rebuild the list
function BodyguardEditorMenu:OnEnter()
    -- Clear options after the static ones (Teleport all, Delete all)
    -- Start from 3 because options 1 and 2 are static
    self:ClearOptionsFrom(3)
    
    local BodyguardMenu = require("Impulse/ImpulseLua/submenus/world/bodyguard_menu")
    local BodyguardSelectedMenu = require("Impulse/ImpulseLua/submenus/world/bodyguard_selected_menu")
    local bodyguards = BodyguardMenu.GetSpawnedBodyguards()
    
    for i = 1, #bodyguards do
        local bg = bodyguards[i]
        if ENTITY.DOES_ENTITY_EXIST(bg.Handle) then
            local idx = i
            -- Current option index for this bodyguard is idx + 2 (because "Teleport all" and "Delete all" are the first options)
            local menuOptionIndex = idx + 2
            
            self:AddOption(SubmenuOption.new(bg.Model .. " [" .. idx .. "]")
                :AddSubmenu(BodyguardSelectedMenu.GetInstance())
                :AddFunction(function()
                    self.SetSelectedIndex(idx)
                end)
                :AddOnUpdate(function(opt)
                    local Menu = require("Impulse/ImpulseLua/lib/menu")
                    if Menu.currentOption == menuOptionIndex then
                        local coords = ENTITY.GET_ENTITY_COORDS(bg.Handle, true)
                        GRAPHICS.DRAW_MARKER(21, coords.x, coords.y, coords.z + 1.5, 0, 0, 0, 180, 0, 0, 0.9, 0.9, 0.9, 0, 255, 255, 200, 1, 0, 2, 1, 0, 0, 0)
                    end
                end)
                :AddTooltip("Edit this bodyguard"))
        end
    end
end

function BodyguardEditorMenu:FeatureUpdate()
    -- No per-frame updates needed
end

return BodyguardEditorMenu
