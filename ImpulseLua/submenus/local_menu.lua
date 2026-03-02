--[[
    Impulse Lua - Local Menu (Local Player)
    Port of localMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")

-- Load Movement submenu
local MovementMenu = require("Impulse/ImpulseLua/submenus/player/movement_menu")

-- Load Vision submenu
local VisionMenu = require("Impulse/ImpulseLua/submenus/player/vision_menu")

-- Load Global submenu
local GlobalMenu = require("Impulse/ImpulseLua/submenus/player/global_menu")

-- Load Particle submenu
local ParticleMenu = require("Impulse/ImpulseLua/submenus/player/particle_menu")

-- Load Animation submenu
local AnimationMenu = require("Impulse/ImpulseLua/submenus/player/animation_menu")

-- Load Wardrobe submenu
local WardrobeMenu = require("Impulse/ImpulseLua/submenus/player/wardrobe_menu")

-- Load Model submenu
local ModelMenu = require("Impulse/ImpulseLua/submenus/player/model_menu")

local LocalMenu = setmetatable({}, { __index = Submenu })
LocalMenu.__index = LocalMenu

local instance = nil

function LocalMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Player"), LocalMenu)
        instance:Init()
    end
    return instance
end

-- Forward declaration for SyncStates (called in Init)
local SyncStates

-- Player state (matching C++ vars)
local playerState = {
    godmode = false,
    regen = false,
    invisibilityToggle = false,
    invisibilityType = 1, -- 1=Not for self, 2=Full invisible
    opacity = 0,
    neverWanted = false,
    noRagdoll = false,
    midget = false,
    reducedCollision = false,
    ignorePlayer = false,
    forcefield = false,
    badsport = false,
    karma = false
}



--- Sync local state with Cherax's actual state
--- Sync local state with Cherax's actual state
SyncStates = function()
    playerState.godmode = FeatureState.Get("God Mode")
    playerState.invisibilityToggle = FeatureState.Get("Invisible Player")
    playerState.neverWanted = FeatureState.Get("Never Wanted")
    playerState.noRagdoll = FeatureState.Get("No Ragdoll")
    playerState.midget = FeatureState.Get("Tiny Player")
    playerState.forcefield = FeatureState.Get("Force Field")
end

-- Invisibility types scroll
local invisibilityTypes = {
    { name = "Invisible (not for self)", value = 0 },
    { name = "Invisible", value = 1 }
}

--[[ ============================================
    HELPER FUNCTIONS (Porting C++ logic)
============================================ ]]

local function Regenerate()
    local ped = PLAYER.PLAYER_PED_ID()
    local health = ENTITY.GET_ENTITY_HEALTH(ped)
    local maxHealth = ENTITY.GET_ENTITY_MAX_HEALTH(ped)
    if health < maxHealth then
        ENTITY.SET_ENTITY_HEALTH(ped, health + math.floor(maxHealth / 100), false)
    end
end

local function NeverWanted(toggle)
    if toggle then
        PLAYER.CLEAR_PLAYER_WANTED_LEVEL(PLAYER.PLAYER_ID())
    end
end

local function NoRagdoll(toggle)
    local ped = PLAYER.PLAYER_PED_ID()
    PED.SET_PED_CAN_RAGDOLL(ped, not toggle)
    PED.SET_PED_CAN_RAGDOLL_FROM_PLAYER_IMPACT(ped, not toggle)
    PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(ped, toggle and 1 or 0)
    PED.SET_PED_RAGDOLL_ON_COLLISION(ped, not toggle)
    PLAYER.GIVE_PLAYER_RAGDOLL_CONTROL(PLAYER.PLAYER_ID(), toggle)
end

local function IgnorePlayer(toggle)
    local ped = PLAYER.PLAYER_PED_ID()
    PLAYER.SET_POLICE_IGNORE_PLAYER(PLAYER.PLAYER_ID(), toggle)
    PLAYER.SET_EVERYONE_IGNORE_PLAYER(PLAYER.PLAYER_ID(), toggle)
    PLAYER.SET_PLAYER_CAN_BE_HASSLED_BY_GANGS(PLAYER.PLAYER_ID(), not toggle)
    PLAYER.SET_IGNORE_LOW_PRIORITY_SHOCKING_EVENTS(PLAYER.PLAYER_ID(), toggle)
end

local function CleanPed()
    local ped = PLAYER.PLAYER_PED_ID()
    PED.CLEAR_PED_BLOOD_DAMAGE(ped)
    PED.RESET_PED_VISIBLE_DAMAGE(ped)
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
end

local function Shrink(toggle)
    PED.SET_PED_CONFIG_FLAG(PLAYER.PLAYER_PED_ID(), 223, toggle)
end

local function ReducedCollision()
    PED.SET_PED_CAPSULE(PLAYER.PLAYER_PED_ID(), 0.0001)
end

local function Invisibility(invType, toggle)
    local ped = PLAYER.PLAYER_PED_ID()
    ENTITY.SET_ENTITY_VISIBLE(ped, not toggle, false)
    if invType == 0 and toggle then
        -- Invisible not for self
        NETWORK.SET_ENTITY_LOCALLY_VISIBLE(ped)
        NETWORK.SET_PLAYER_VISIBLE_LOCALLY(PLAYER.PLAYER_ID(), true)
    end
end

local function Karma()
    local ped = PLAYER.PLAYER_PED_ID()
    if ENTITY.IS_ENTITY_DEAD(ped, false) then
        local killer = PED.GET_PED_SOURCE_OF_DEATH(ped)
        if killer and not ENTITY.IS_ENTITY_DEAD(killer, false) then
            local coords = ENTITY.GET_ENTITY_COORDS(killer, true)
            FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 0, 10, true, false, 0.0, false)
        end
    end
end


--[[ ============================================
    MENU INITIALIZATION
============================================ ]]

function LocalMenu:Init()
    -- Sync toggle states from Cherax
    SyncStates()
    
    -- Create Movement submenu instance and store reference for FeatureUpdate
    self.movementSubmenu = MovementMenu.new()
    self.movementSubmenu:Init()
    
    -- Submenus (ordered to match C++)
    self:AddOption(SubmenuOption.new("Movement")
        :AddSubmenu(self.movementSubmenu)
        :AddTooltip("Player movement options"))
    
    
    -- Create Global submenu instance
    self.globalSubmenu = GlobalMenu.new()
    self.globalSubmenu:Init()
    
    self:AddOption(SubmenuOption.new("Global")
        :AddSubmenu(self.globalSubmenu)
        :AddTooltip("Global options"))
    
    -- Create Model submenu instance
    self.modelSubmenu = ModelMenu.new()
    self.modelSubmenu:Init()
    
    self:AddOption(SubmenuOption.new("Model")
        :AddSubmenu(self.modelSubmenu)
        :AddTooltip("Model options"))
    
    -- Create Wardrobe submenu instance
    self.wardrobeSubmenu = WardrobeMenu.new()
    self.wardrobeSubmenu:Init()
    
    self:AddOption(SubmenuOption.new("Wardrobe")
        :AddSubmenu(self.wardrobeSubmenu)
        :AddTooltip("Wardrobe options"))
    
    -- Create Animation submenu instance
    self.animationSubmenu = AnimationMenu.new()
    self.animationSubmenu:Init()
    
    self:AddOption(SubmenuOption.new("Animation")
        :AddSubmenu(self.animationSubmenu)
        :AddTooltip("Animation options"))
    
    -- Create Vision submenu instance
    self.visionSubmenu = VisionMenu.new()
    self.visionSubmenu:Init()
    
    self:AddOption(SubmenuOption.new("Vision")
        :AddSubmenu(self.visionSubmenu)
        :AddTooltip("Vision options"))
    
    -- Create Particle effects submenu instance
    self.particleSubmenu = ParticleMenu.new()
    self.particleSubmenu:Init()
    
    self:AddOption(SubmenuOption.new("Particle effects")
        :AddSubmenu(self.particleSubmenu)
        :AddTooltip("Particle effects options"))
    
    -- Break: General
    self:AddOption(BreakOption.new("General"))
    
    -- God mode (using internal feature)
    self:AddOption(ToggleOption.new("God Mode")
        :AddToggleRef(playerState, "godmode")
        :AddFunction(function()
             FeatureMgr.GetFeatureByName("God Mode"):Toggle(playerState.godmode)
        end)
        :AddTooltip("Player won't be able to die")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Regenerate health")
        :AddToggleRef(playerState, "regen")
        :AddTooltip("Slowly regenerate health")
        :AddHotkey())
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.TOGGLE, "Invisibility")
        :AddToggleRef(playerState, "invisibilityToggle")
        :AddScroll(invisibilityTypes, 1)
        :AddIndexRef(playerState, "invisibilityType")
        :AddFunction(function()
             FeatureMgr.GetFeatureByName("Invisible Player"):Toggle(playerState.invisibilityToggle)
             -- Value 0 = "Invisible (not for self)" -> Local Override ON
             FeatureMgr.GetFeatureByName("Local Visibility Override"):Toggle(invisibilityTypes[playerState.invisibilityType].value == 0)
        end)
        :AddTooltip("Player will be invisible")
        :AddHotkey())
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Opacity")
        :SetNumber(playerState, "opacity")
        :SetMin(0):SetMax(100):SetStep(5)
        :SetFormat("%d%%")
        :AddFunction(function()
            ENTITY.SET_ENTITY_ALPHA(PLAYER.PLAYER_PED_ID(), 255 - math.floor(playerState.opacity * 2.55), false)
        end)
        :AddTooltip("Set player opacity (local only)"))
    
    self:AddOption(ToggleOption.new("Never wanted")
        :AddToggleRef(playerState, "neverWanted")
        :AddFunction(function()
             FeatureMgr.GetFeatureByName("Never Wanted"):Toggle(playerState.neverWanted)
        end)
        :AddTooltip("No wanted stars")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("No ragdoll")
        :AddToggleRef(playerState, "noRagdoll")
        :AddFunction(function()
             FeatureMgr.GetFeatureByName("No Ragdoll"):Toggle(playerState.noRagdoll)
        end)
        :AddTooltip("Player can't ragdoll")
        :AddHotkey())
    
    -- Break: Modify Ped
    self:AddOption(BreakOption.new("Modify Ped"))
    
    self:AddOption(ButtonOption.new("Clone")
        :AddFunction(function()
             FeatureMgr.GetFeatureByName("Clone Player"):TriggerCallback()
        end)
        :AddTooltip("Clone your ped")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Midget mode")
        :AddToggleRef(playerState, "midget")
        :AddFunction(function()
             FeatureMgr.GetFeatureByName("Tiny Player"):Toggle(playerState.midget)
        end)
        :AddTooltip("Shrink!")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Reduced Collision")
        :AddToggleRef(playerState, "reducedCollision")
        :AddTooltip("Reduce the collision on your player model"))
    
    self:AddOption(ButtonOption.new("Clean ped")
        :AddFunction(function()
             FeatureMgr.GetFeatureByName("Clean"):TriggerCallback()
        end)
        :AddTooltip("Reset the player")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Peds ignore player")
        :AddToggleRef(playerState, "ignorePlayer")
        :AddTooltip("Make peds ignore the player")
        :AddHotkey())
    
    self:AddOption(ButtonOption.new("Suicide")
        :AddFunction(function()
             FeatureMgr.GetFeatureByName("Suicide"):TriggerCallback()
        end)
        :AddTooltip("Suicide")
        :AddHotkey())
    
    self:AddOption(ButtonOption.new("Remove all attachments")
        :AddFunction(function()
            -- Simplified: Clear tasks and detach
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID())
        end)
        :AddTooltip("Remove all attachments")
        :AddHotkey())
    
    -- Break: Misc
    self:AddOption(BreakOption.new("Misc"))
    
    self:AddOption(ToggleOption.new("Forcefield")
        :AddToggleRef(playerState, "forcefield")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Force Field"):Toggle(playerState.forcefield)
        end)
        :AddTooltip("Force field")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Badsport yourself")
        :AddToggleRef(playerState, "badsport")
        :AddTooltip("Place yourself in badsport"))
    
    self:AddOption(ToggleOption.new("Karma")
        :AddToggleRef(playerState, "karma")
        :AddTooltip("Kill the player that kills you")
        :AddHotkey())
end

--[[ ============================================
    FEATURE UPDATE LOOP (Called every frame)
============================================ ]]

-- Timer for regeneration (500ms interval)
local regenTimer = 0
local REGEN_INTERVAL = 500

function LocalMenu:FeatureUpdate()
    local currentTime = MISC.GET_GAME_TIMER()
    

    if playerState.regen then
        if currentTime - regenTimer > REGEN_INTERVAL then
            regenTimer = currentTime
            Regenerate()
        end
    end
    
 
    if playerState.ignorePlayer then
        IgnorePlayer(true)
    end
    
  
    if playerState.karma then
        Karma()
    end
    
 
    if playerState.reducedCollision then
        ReducedCollision()
    end
    
    -- Badsport
    if playerState.badsport then
        STATS.STAT_SET_FLOAT(0xBE89A9D2, 300.0, false)
    end
    
    -- Call child submenu FeatureUpdates
    if self.movementSubmenu and self.movementSubmenu.FeatureUpdate then
        self.movementSubmenu:FeatureUpdate()
    end
    if self.particleSubmenu and self.particleSubmenu.FeatureUpdate then
        self.particleSubmenu:FeatureUpdate()
    end
    if self.globalSubmenu and self.globalSubmenu.FeatureUpdate then
        self.globalSubmenu:FeatureUpdate()
    end
    if self.animationSubmenu and self.animationSubmenu.FeatureUpdate then
        self.animationSubmenu:FeatureUpdate()
    end
    if self.modelSubmenu and self.modelSubmenu.FeatureUpdate then
        self.modelSubmenu:FeatureUpdate()
    end
    if self.wardrobeSubmenu and self.wardrobeSubmenu.FeatureUpdate then
        self.wardrobeSubmenu:FeatureUpdate()
    end
end

return LocalMenu
