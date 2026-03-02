--[[
    Impulse Lua - Player Movement Submenu
    Port of playerMovementMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local KeyOption = require("Impulse/ImpulseLua/lib/options/key")

---@class MovementMenu : Submenu
local MovementMenu = setmetatable({}, { __index = Submenu })
MovementMenu.__index = MovementMenu

-- State table for movement options
local movementState = {
    -- FeatureMgr features
    superJump = false,
    walkOnAir = false,
    walkOnWater = false,
    walkUnderWater = false,
    superman = false,
    noClip = false,
    noclipSpeed = 1,
    
    -- Lua-implemented features
    ultraJump = false,
    vegetableMode = false,
    slowMotion = false,
    speedBoost = false,
    speedBoostAmount = 1.0,
    speedBoostKey = 0x10, -- Shift
    speedBoostKeyController = false,
    
    -- Speed multipliers
    runSpeedEnabled = false,
    runSpeedValue = 1.0,
    swimSpeedEnabled = false,
    swimSpeedValue = 1.0,
}

--- Helper to safely get feature toggle state
---@param featureName string
---@return boolean
local function GetFeatureState(featureName)
    local success, result = pcall(function()
        local feature = FeatureMgr.GetFeatureByName(featureName)
        if feature then
            return feature:IsToggled()
        end
        return false
    end)
    return success and result or false
end

--- Sync local state with Cherax's actual state
local function SyncMovementStates()
    movementState.superJump = GetFeatureState("Super Jump")
    movementState.walkOnAir = GetFeatureState("Walk On Air")
    movementState.walkOnWater = GetFeatureState("Walk On Water")
    movementState.walkUnderWater = GetFeatureState("Walk Under Water")
    movementState.superman = GetFeatureState("Superman")
    movementState.noClip = GetFeatureState("No Clip")
    
    local runFeat = FeatureMgr.GetFeature(2252198154)
    if runFeat then
        movementState.runSpeedEnabled = runFeat:IsToggled()
        movementState.runSpeedValue = runFeat:GetFloatValue()
    end

    if swimFeat then
        movementState.swimSpeedEnabled = swimFeat:IsToggled()
        movementState.swimSpeedValue = swimFeat:GetFloatValue()
    end
    
    local ncSpeedFeat = FeatureMgr.GetFeature(1051151625)
    if ncSpeedFeat then
        movementState.noclipSpeed = ncSpeedFeat:GetIntValue()
    end
end

--[[ ============================================
    HELPER FUNCTIONS (Ported from C++)
============================================ ]]

-- Apply force to entity (Native relative application)
local function ApplyForceToEntity(entity, forceX, forceY, forceZ)
    -- The native handles rotation when isDirectionRel (Arg 10) is true.
    -- We don't need to manually calculate sin/cos heading.
    ENTITY.APPLY_FORCE_TO_ENTITY(entity, 1, forceX, forceY, forceZ, 0, 0, 0, 0, true, true, true, false, true)
end

-- Get camera direction
local function GetCameraDirection()
    local rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
    local radX = math.rad(rot.x)
    local radZ = math.rad(rot.z)
    
    local dirX = -math.sin(radZ) * math.cos(radX)
    local dirY = math.cos(radZ) * math.cos(radX)
    local dirZ = math.sin(radX)
    
    return { x = dirX, y = dirY, z = dirZ }
end

-- Check if key is pressed
local function IsKeyDown(key)
    return Utils.IsKeyDown(key)
end

--[[ ============================================
    FEATURE FUNCTIONS (Ported from C++)
============================================ ]]

-- Ultra Jump (custom jump with more force)
local ultraJumpState = { wasJumping = false, jumpTimer = 0 }
local function UltraJump()
    local ped = PLAYER.PLAYER_PED_ID()
    local isJumping = PED.IS_PED_JUMPING(ped)
    
    if isJumping and ultraJumpState.wasJumping then
        if ultraJumpState.jumpTimer > 0 then
            ultraJumpState.jumpTimer = ultraJumpState.jumpTimer - 1
            PED.SET_PED_CAN_RAGDOLL(ped, false)
            WEAPON.REMOVE_WEAPON_FROM_PED(ped, 0xFBAB5776) -- Parachute
            ApplyForceToEntity(ped, 0, 2.5, 20)
        end
    elseif isJumping and not ultraJumpState.wasJumping then
        ultraJumpState.wasJumping = true
        ultraJumpState.jumpTimer = 10
    elseif not isJumping then
        ultraJumpState.wasJumping = false
    end
end

-- Legacy FlyMode and Noclip removed


-- Vegetable Mode (ragdoll movement)
local function VegetableMode()
    local ped = PLAYER.PLAYER_PED_ID()
    PED.SET_PED_TO_RAGDOLL(ped, 10, 10, 0, true, true, true)
    
    if IsKeyDown(0x57) then -- W
        ApplyForceToEntity(ped, 0, 2, 0)
    end
    if IsKeyDown(0x53) then -- S
        ApplyForceToEntity(ped, 0, -2, 0)
    end
    if IsKeyDown(0x41) then -- A
        ApplyForceToEntity(ped, 2, 0, 0)
    end
    if IsKeyDown(0x44) then -- D
        ApplyForceToEntity(ped, -2, 0, 0)
    end
end

-- Slow Motion
local function SlowMotion(enabled)
    MISC.SET_TIME_SCALE(enabled and 0.5 or 1.0)
end

-- Speed Boost (key-activated)
local function KeyBoost(speed)
    local key = movementState.speedBoostKey
    -- Default to Shift (0x10) if nil
    if not key then key = 0x10 end
    
    if IsKeyDown(key) then
        ApplyForceToEntity(PLAYER.PLAYER_PED_ID(), 0, speed, 0)
    end
end

--[[ ============================================
    MENU CREATION
============================================ ]]

function MovementMenu.new()
    local self = setmetatable(Submenu.new("Movement"), MovementMenu)
    return self
end

function MovementMenu:Init()
    -- Sync toggle states from Cherax
    SyncMovementStates()
    
    -- Super Jump (FeatureMgr)
    self:AddOption(ToggleOption.new("Super jump")
        :AddToggleRef(movementState, "superJump")
        :AddFunction(function()
             FeatureMgr.GetFeatureByName("Super Jump"):Toggle(movementState.superJump)
        end)
        :AddTooltip("Super jump")
        :AddHotkey())
    
    -- Ultra Jump (Lua implementation)
    self:AddOption(ToggleOption.new("Ultra jump")
        :AddToggleRef(movementState, "ultraJump")
        :AddTooltip("Ultra jump with more force")
        :AddHotkey())
    
    -- Movement speed multiplier
    -- Run Speed (2252198154)
    self:AddOption(NumberOption.new(NumberOption.Type.TOGGLE, "Run Speed")
        :AddToggleRef(movementState, "runSpeedEnabled")
        :SetNumber(movementState, "runSpeedValue")
        :SetMin(0.1):SetMax(2.0):SetStep(0.1)
        :SetFormat("%.3f")
        :AddFunction(function()
            local feat = FeatureMgr.GetFeature(2252198154)
            if feat then
                feat:SetFloatValue(movementState.runSpeedValue)
                if feat:IsToggled() ~= movementState.runSpeedEnabled then
                    feat:Toggle()
                end
            end
        end)
        :AddTooltip("Run speed multiplier")
        :AddHotkey())
    
    -- Swim Speed (4188395739)
    self:AddOption(NumberOption.new(NumberOption.Type.TOGGLE, "Swim Speed")
        :AddToggleRef(movementState, "swimSpeedEnabled")
        :SetNumber(movementState, "swimSpeedValue")
        :SetMin(0.1):SetMax(2.0):SetStep(0.1)
        :SetFormat("%.3f")
        :AddFunction(function()
            local feat = FeatureMgr.GetFeature(4188395739)
            if feat then
                feat:SetFloatValue(movementState.swimSpeedValue)
                if feat:IsToggled() ~= movementState.swimSpeedEnabled then
                    feat:Toggle()
                end
            end
        end)
        :AddTooltip("Swim speed multiplier")
        :AddHotkey())
    
    -- Superman (Replacing Flymode)
    self:AddOption(ToggleOption.new("Superman")
        :AddToggleRef(movementState, "superman")
        :AddFunction(function()
             FeatureMgr.GetFeatureByName("Superman"):Toggle(movementState.superman)
        end)
        :AddTooltip("Superman mode")
        :AddHotkey())
    
    -- Walk on air (FeatureMgr)
    self:AddOption(ToggleOption.new("Walk on air")
        :AddToggleRef(movementState, "walkOnAir")
        :AddFunction(function()
             FeatureMgr.GetFeatureByName("Walk On Air"):Toggle(movementState.walkOnAir)
        end)
        :AddTooltip("Shift to go down, Space to go up")
        :AddHotkey())
    
    -- Vegetable mode
    self:AddOption(ToggleOption.new("Vegetable mode")
        :AddToggleRef(movementState, "vegetableMode")
        :AddTooltip("Ragdoll! Make sure to turn off no ragdoll!")
        :AddHotkey())
    
    -- Slow motion
    self:AddOption(ToggleOption.new("Slow motion")
        :AddToggleRef(movementState, "slowMotion")
        :AddFunction(function()
            SlowMotion(movementState.slowMotion)
        end)
        :AddTooltip("Slow time")
        :AddHotkey())
    
    -- Break: Noclip
    self:AddOption(BreakOption.new("Noclip"))
    
    -- No Clip (Replacing Walking Noclip)
    self:AddOption(ToggleOption.new("No Clip")
        :AddToggleRef(movementState, "noClip")
        :AddFunction(function()
             FeatureMgr.GetFeatureByName("No Clip"):Toggle(movementState.noClip)
        end)
        :AddTooltip("No Clip mode")
        :AddHotkey())

    -- Noclip speed
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Noclip speed")
        :SetNumber(movementState, "noclipSpeed")
        :SetMin(1):SetMax(10):SetStep(1)
        :AddFunction(function()
             local val = math.floor(movementState.noclipSpeed)
             -- Speed (1051151625)
             local f1 = FeatureMgr.GetFeature(1051151625)
             if f1 then f1:SetIntValue(val) end
             
             -- Speed Fast (4165612562)
             local f2 = FeatureMgr.GetFeature(4165612562)
             if f2 then f2:SetIntValue(val) end
             
             -- Speed Vertical (3747547729)
             local f3 = FeatureMgr.GetFeature(3747547729)
             if f3 then f3:SetIntValue(val) end
        end)
        :AddTooltip("Control the speed of your noclip")
        :AddHotkey())
    
    -- Break: Super run
    self:AddOption(BreakOption.new("Super run"))
    
    -- Super run
    self:AddOption(NumberOption.new(NumberOption.Type.TOGGLE, "Super run")
        :AddToggleRef(movementState, "speedBoost")
        :SetNumber(movementState, "speedBoostAmount")
        :SetMin(0):SetMax(10):SetStep(0.2)
        :SetFormat("%.1f")
        :AddTooltip("Use the assigned key to super run")
        :AddHotkey())
    
    -- Super run key
    self:AddOption(KeyOption.new("Super run key")
        :AddKeyRef(movementState, "speedBoostKey")
        :AddTooltip("Set the key")
        :AddHotkey())
    
    -- Break: Water
    self:AddOption(BreakOption.new("Water"))
    
    -- Walk on water (FeatureMgr)
    self:AddOption(ToggleOption.new("Walk on water")
        :AddToggleRef(movementState, "walkOnWater")
        :AddFunction(function()
             FeatureMgr.GetFeatureByName("Walk On Water"):Toggle(movementState.walkOnWater)
        end)
        :AddTooltip("Walk on water")
        :AddHotkey())
    
    -- Walk through water (FeatureMgr uses "Walk Under Water")
    self:AddOption(ToggleOption.new("Walk through water")
        :AddToggleRef(movementState, "walkUnderWater")
        :AddFunction(function()
             FeatureMgr.GetFeatureByName("Walk Under Water"):Toggle(movementState.walkUnderWater)
        end)
        :AddTooltip("Walk through water")
        :AddHotkey())
end

--[[ ============================================
    FEATURE UPDATE LOOP (Called every frame)
============================================ ]]

function MovementMenu:FeatureUpdate()
    -- Ultra Jump (Lua)
    if movementState.ultraJump then
        UltraJump()
    end
    
    -- Vegetable mode (Lua)
    if movementState.vegetableMode then
        VegetableMode()
    end
    

    
    -- Speed boost (Lua)
    if movementState.speedBoost then
        KeyBoost(movementState.speedBoostAmount)
    end
end

return MovementMenu
