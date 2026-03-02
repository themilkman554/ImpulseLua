--[[
    Impulse Lua - Wardrobe Menu
    Port of wardrobeMenu.cpp from Impulse C++
    Manages player clothing, props, and saved outfits
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local TextInputComponent = require("Impulse/ImpulseLua/lib/ui/text_input_component")

-- Load Wardrobe submenu
local LoadWardrobeMenu = require("Impulse/ImpulseLua/submenus/player/load_wardrobe_menu")

---@class WardrobeMenu : Submenu
local WardrobeMenu = setmetatable({}, { __index = Submenu })
WardrobeMenu.__index = WardrobeMenu

-- Text input for save outfit
local saveOutfitInput = nil

-- State for wardrobe options
local wardrobeState = {
    hairColor = 0,
    -- Props
    face = 0,
    faceVar = 0,
    glasses = 0,
    glassesVar = 0,
    ears = 0,
    earsVar = 0,
    -- Components (12 slots)
    components = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    componentsVar = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
}

-- Component labels matching C++
local componentLabels = {
    "Face",
    "Masks",
    "Hair",
    "Torso",
    "Legs",
    "Parachute / Misc",
    "Shoes",
    "Extra 1",
    "Tops 1",
    "Body Armor",
    "Crew Emblem",
    "Tops 2"
}

--- Create a new WardrobeMenu
---@return WardrobeMenu
function WardrobeMenu.new()
    local self = setmetatable(Submenu.new("Wardrobe"), WardrobeMenu)
    
    -- Initialize save outfit input
    saveOutfitInput = TextInputComponent.new()
    saveOutfitInput:SetTitle("Save outfit")
    saveOutfitInput:SetCallback(function(outfitName)
        if outfitName and #outfitName > 0 then
            -- Use Cherax's built-in save feature
            Script.QueueJob(function()
                local outfitNameFeature = FeatureMgr.GetFeatureByName("Outfit Name")
                if outfitNameFeature then
                    outfitNameFeature:SetStringValue(outfitName)
                    Script.Yield(1000) -- 1 second delay for name to be set
                    FeatureMgr.TriggerFeatureCallback(231503983)
                    Renderer.Notify("Saved outfit: " .. outfitName)
                else
                    Renderer.Notify("Outfit Name feature not found")
                end
            end)
        end
    end)
    
    return self
end

function WardrobeMenu:Init()
    -- Load child submenu
    self.loadWardrobeSubmenu = LoadWardrobeMenu.new()
    self.loadWardrobeSubmenu:Init()
    
    -- Load outfits submenu
    self:AddOption(SubmenuOption.new("Load outfits")
        :AddSubmenu(self.loadWardrobeSubmenu)
        :AddTooltip("Load saved outfits from Cherax Outfits folder")
        :AddHotkey())
    
    -- Save outfit button
    self:AddOption(ButtonOption.new("Save outfit")
        :AddFunction(function()
            if saveOutfitInput then
                saveOutfitInput:Show()
            end
        end)
        :AddTooltip("Save current outfit to Cherax Outfits folder")
        :AddHotkey())
    
    -- Random outfit
    self:AddOption(ButtonOption.new("Random outfit")
        :AddFunction(function()
            local ped = PLAYER.PLAYER_PED_ID()
            PED.SET_PED_RANDOM_COMPONENT_VARIATION(ped, true)
            PED.SET_PED_RANDOM_PROPS(ped)
            Renderer.Notify("Random outfit applied")
        end)
        :AddTooltip("Get a random outfit")
        :AddHotkey())
    
    -- Police Uniform
    self:AddOption(ButtonOption.new("Police Uniform")
        :AddFunction(function()
            local ped = PLAYER.PLAYER_PED_ID()
            local model = ENTITY.GET_ENTITY_MODEL(ped)
            local femaleHash = MISC.GET_HASH_KEY("mp_f_freemode_01")
            
            if model == femaleHash then
                -- Female
                PED.SET_PED_PROP_INDEX(ped, 0, 45, 0, true) -- hat
                PED.SET_PED_COMPONENT_VARIATION(ped, 11, 48, 0, 0) -- top
                PED.SET_PED_COMPONENT_VARIATION(ped, 4, 34, 0, 0) -- pants
                PED.SET_PED_COMPONENT_VARIATION(ped, 3, 0, 0, 0) -- torso
                PED.SET_PED_COMPONENT_VARIATION(ped, 6, 25, 0, 0) -- shoes
                PED.SET_PED_COMPONENT_VARIATION(ped, 8, 35, 0, 0) -- undershirt
            else
                -- Male
                PED.SET_PED_PROP_INDEX(ped, 0, 46, 0, true) -- hat
                PED.SET_PED_COMPONENT_VARIATION(ped, 11, 55, 0, 0) -- top
                PED.SET_PED_COMPONENT_VARIATION(ped, 4, 35, 0, 0) -- pants
                PED.SET_PED_COMPONENT_VARIATION(ped, 3, 0, 0, 0) -- torso
                PED.SET_PED_COMPONENT_VARIATION(ped, 6, 24, 0, 0) -- shoes
                PED.SET_PED_COMPONENT_VARIATION(ped, 9, 0, 0, 0) -- body armor
            end
            Renderer.Notify("Police uniform applied")
        end)
        :AddTooltip("Wear police uniform")
        :AddHotkey())
    
    -- Hair color
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Hair color")
        :SetNumber(wardrobeState, "hairColor")
        :SetMin(0):SetMax(64):SetStep(1)
        :SetFormat("%d")
        :AddFunction(function()
            Script.QueueJob(function()
                local ped = PLAYER.PLAYER_PED_ID()
                PED.SET_PED_HAIR_TINT(ped, wardrobeState.hairColor, 0)
            end)
        end)
        :AddTooltip("Set hair color")
        :AddHotkey())
    
    -- Props section
    self:AddOption(BreakOption.new("Props"))
    
    -- Face prop
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Face")
        :SetNumber(wardrobeState, "face")
        :SetMin(-1):SetMax(200):SetStep(1)
        :SetFormat("%d")
        :AddFunction(function()
            local ped = PLAYER.PLAYER_PED_ID()
            PED.SET_PED_PROP_INDEX(ped, 0, wardrobeState.face, 0, true)
            wardrobeState.faceVar = 0
        end)
        :AddTooltip("Change face prop"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Face variation")
        :SetNumber(wardrobeState, "faceVar")
        :SetMin(-1):SetMax(200):SetStep(1)
        :SetFormat("%d")
        :AddFunction(function()
            local ped = PLAYER.PLAYER_PED_ID()
            PED.SET_PED_PROP_INDEX(ped, 0, wardrobeState.face, wardrobeState.faceVar, true)
        end)
        :AddTooltip("Change face variation"))
    
    -- Glasses prop
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Glasses")
        :SetNumber(wardrobeState, "glasses")
        :SetMin(-1):SetMax(200):SetStep(1)
        :SetFormat("%d")
        :AddFunction(function()
            local ped = PLAYER.PLAYER_PED_ID()
            PED.SET_PED_PROP_INDEX(ped, 1, wardrobeState.glasses, 0, true)
            wardrobeState.glassesVar = 0
        end)
        :AddTooltip("Change glasses"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Glasses variation")
        :SetNumber(wardrobeState, "glassesVar")
        :SetMin(-1):SetMax(200):SetStep(1)
        :SetFormat("%d")
        :AddFunction(function()
            local ped = PLAYER.PLAYER_PED_ID()
            PED.SET_PED_PROP_INDEX(ped, 1, wardrobeState.glasses, wardrobeState.glassesVar, true)
        end)
        :AddTooltip("Change glasses variation"))
    
    -- Ear pieces prop
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Ear pieces")
        :SetNumber(wardrobeState, "ears")
        :SetMin(-1):SetMax(200):SetStep(1)
        :SetFormat("%d")
        :AddFunction(function()
            local ped = PLAYER.PLAYER_PED_ID()
            PED.SET_PED_PROP_INDEX(ped, 2, wardrobeState.ears, 0, true)
            wardrobeState.earsVar = 0
        end)
        :AddTooltip("Change ear pieces"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Ears variation")
        :SetNumber(wardrobeState, "earsVar")
        :SetMin(-1):SetMax(200):SetStep(1)
        :SetFormat("%d")
        :AddFunction(function()
            local ped = PLAYER.PLAYER_PED_ID()
            PED.SET_PED_PROP_INDEX(ped, 2, wardrobeState.ears, wardrobeState.earsVar, true)
        end)
        :AddTooltip("Change ear pieces variation"))
    
    -- Clear props buttons
    self:AddOption(ButtonOption.new("Clear face")
        :AddFunction(function()
            PED.CLEAR_PED_PROP(PLAYER.PLAYER_PED_ID(), 0)
            Renderer.Notify("Face prop cleared")
        end)
        :AddTooltip("Clear face prop"))
    
    self:AddOption(ButtonOption.new("Clear glasses")
        :AddFunction(function()
            PED.CLEAR_PED_PROP(PLAYER.PLAYER_PED_ID(), 1)
            Renderer.Notify("Glasses cleared")
        end)
        :AddTooltip("Clear glasses prop"))
    
    self:AddOption(ButtonOption.new("Clear ear pieces")
        :AddFunction(function()
            PED.CLEAR_PED_PROP(PLAYER.PLAYER_PED_ID(), 2)
            Renderer.Notify("Ear pieces cleared")
        end)
        :AddTooltip("Clear ear pieces prop"))
    
    -- Components section
    self:AddOption(BreakOption.new("Components"))
    
    -- Add all 12 component slots (0-11)
    for i = 1, 12 do
        local componentIndex = i - 1 -- 0-based index for natives
        local label = componentLabels[i]
        
        self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, label)
            :SetNumber(wardrobeState.components, i)
            :SetMin(-1):SetMax(400):SetStep(1)
            :SetFormat("%d")
            :AddFunction(function()
                local ped = PLAYER.PLAYER_PED_ID()
                PED.SET_PED_COMPONENT_VARIATION(ped, componentIndex, wardrobeState.components[i], 0, 0)
                wardrobeState.componentsVar[i] = 0
            end)
            :AddTooltip("Change " .. label))
        
        self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, label .. " variation")
            :SetNumber(wardrobeState.componentsVar, i)
            :SetMin(-1):SetMax(400):SetStep(1)
            :SetFormat("%d")
            :AddFunction(function()
                local ped = PLAYER.PLAYER_PED_ID()
                PED.SET_PED_COMPONENT_VARIATION(ped, componentIndex, wardrobeState.components[i], wardrobeState.componentsVar[i], 0)
            end)
            :AddTooltip("Change " .. label .. " variation"))
    end
end

function WardrobeMenu:FeatureUpdate()
    -- Update save outfit text input (renders and handles input)
    if saveOutfitInput then
        saveOutfitInput:Update()
    end
    
    -- Call child submenu FeatureUpdate if needed
    if self.loadWardrobeSubmenu then
        self.loadWardrobeSubmenu:FeatureUpdate()
    end
end

return WardrobeMenu
