--[[
    Impulse Lua - Weapon Visuals Submenu
    Port of weaponVisuals.cpp from Impulse C++
    Visual effects for weapons
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class WeaponVisualsMenu : Submenu
local WeaponVisualsMenu = setmetatable({}, { __index = Submenu })
WeaponVisualsMenu.__index = WeaponVisualsMenu

-- State
local visualsState = {
    invisibility = false,
    crosshair = false,
    selectedCrosshair = 1,
    aimingLaser = false,
    cartoonEffects = false,
    aimedInformation = false,
    width = 1.0,
    height = 1.0,
    overall = 1.0,
    loopSize = false
}

-- Crosshair types with sprite info
local crosshairTypes = {
    { name = "Cross", dict = "srange_gen", sprite = "hit_cross" },
    { name = "Target", dict = "helicopterhud", sprite = "hud_target" },
    { name = "Arrow", dict = "helicopterhud", sprite = "hudarrow" },
    { name = "Holy Cross", dict = "mptattoos3", sprite = "tattoo_reach_rank_r_10" },
    { name = "Reticle", dict = "darts", sprite = "dart_reticules" },
    { name = "Reticle Zoomed", dict = "darts", sprite = "dart_reticules_zoomed" },
    { name = "Dot", dict = "shared", sprite = "emptydot_32" },
    { name = "Plus", dict = "shared", sprite = "menuplus_32" },
    { name = "Middle Finger", dict = "mp_freemode_mc", sprite = "mouse" },
    { name = "Box", dict = "visualflow", sprite = "crosshair" },
    { name = "Star", dict = "shared", sprite = "newstar_32" }
}

-- Crosshair names for scroll option
local crosshairNames = {}
for i, ch in ipairs(crosshairTypes) do
    crosshairNames[i] = ch.name
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

--- Get player ped
---@return integer
local function GetPlayerPed()
    return PLAYER.PLAYER_PED_ID()
end

--- Get player ID
---@return integer
local function GetPlayerId()
    return PLAYER.PLAYER_ID()
end

--- Check if player is aiming
---@return boolean
local function IsPlayerAiming()
    return PED.GET_PED_CONFIG_FLAG(GetPlayerPed(), 78, true)
end

--- Get entity player is aiming at
---@return integer|nil
local function GetAimedEntity()
    local entityPtr = Memory.Alloc(8)
    local result = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(GetPlayerId(), entityPtr)
    local entity = Memory.ReadInt(entityPtr)
    Memory.Free(entityPtr)
    if result and entity ~= 0 then
        return entity
    end
    return nil
end

--- Get current weapon entity
---@return integer
local function GetWeaponEntity()
    local ped = GetPlayerPed()
    return WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(ped, 0)
end

--- Check if player has weapon in hand
---@return boolean
local function HasWeaponInHand()
    local ped = GetPlayerPed()
    local weaponHash = Memory.Alloc(8)
    WEAPON.GET_CURRENT_PED_WEAPON(ped, weaponHash, true)
    local hash = Memory.ReadInt(weaponHash)
    Memory.Free(weaponHash)
    return hash ~= 0xA2719263 -- WEAPON_UNARMED
end

-- ============================================
-- FEATURE IMPLEMENTATIONS
-- ============================================

--- Draw aiming laser
local function AimingLaser()
    local ped = GetPlayerPed()
    local playerId = GetPlayerId()
    
    local rndPtr = Memory.Alloc(8)
    local isAiming = PAD.IS_DISABLED_CONTROL_PRESSED(0, 25) or PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(playerId, rndPtr)
    Memory.Free(rndPtr)
    
    if isAiming then
        local distance = 200.0
        local pitch = CAM.GET_GAMEPLAY_CAM_RELATIVE_PITCH()
        
        -- Get right hand bone position
        local boneIndex = PED.GET_PED_BONE_INDEX(ped, 28422)
        local start = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(ped, boneIndex)
        
        local relZ = math.tan(math.rad(pitch)) * distance
        local endPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, distance, relZ)
        
        GRAPHICS.DRAW_LINE(start.x, start.y, start.z, endPos.x, endPos.y, endPos.z, 255, 0, 0, 150)
    end
end

--- Display aimed entity information
local function AimedInformation()
    local entity = GetAimedEntity()
    if entity then
        local position = ENTITY.GET_ENTITY_COORDS(entity, true)
        
        local xPtr = Memory.Alloc(4)
        local yPtr = Memory.Alloc(4)
        
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(position.x, position.y, position.z, xPtr, yPtr) then
            local x = Memory.ReadFloat(xPtr)
            local y = Memory.ReadFloat(yPtr)
            
            local model = ENTITY.GET_ENTITY_MODEL(entity)
            local info = string.format("Entity Handle: 0x%X\nEntity Model: 0x%X", entity, model)
            
            -- Draw text at entity position on screen
            HUD.SET_TEXT_FONT(4)
            HUD.SET_TEXT_SCALE(0.35, 0.35)
            HUD.SET_TEXT_COLOUR(255, 255, 255, 255)
            HUD.SET_TEXT_OUTLINE()
            HUD.SET_TEXT_CENTRE(true)
            HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
            HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(info)
            HUD.END_TEXT_COMMAND_DISPLAY_TEXT(x, y, 0)
        end
        
        Memory.Free(xPtr)
        Memory.Free(yPtr)
    end
end

-- CartoonEffects is handled in toggle only, not in FeatureUpdate

--- Draw selected crosshair
local function DrawCrosshair()
    local ch = crosshairTypes[visualsState.selectedCrosshair]
    if ch then
        -- Request texture dictionary
        if not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(ch.dict) then
            GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(ch.dict, true)
        end
        
        -- Draw sprite at center of screen
        GRAPHICS.DRAW_SPRITE(ch.dict, ch.sprite, 0.5, 0.5, 0.02, 0.03, 0.0, 0, 255, 0, 180, false, false)
    end
end

--- Handle weapon invisibility
local function WeaponInvisibility()
    local weaponEntity = GetWeaponEntity()
    if ENTITY.DOES_ENTITY_EXIST(weaponEntity) then
        ENTITY.SET_ENTITY_VISIBLE(weaponEntity, false, false)
    end
end

--- Apply weapon size
---@param width number
---@param height number
local function ApplyWeaponSize(width, height)
    local weaponEntity = GetWeaponEntity()
    if weaponEntity ~= 0 and GTA.HandleToPointer then
        local ptrObj = GTA.HandleToPointer(weaponEntity)
        if ptrObj then
            local ptr = ptrObj:GetAddress()
            if ptr and ptr ~= 0 then
                Memory.WriteFloat(ptr + 0x7C, width)
                Memory.WriteFloat(ptr + 0x8C, height)
            end
        end
    end
end

-- ============================================
-- MENU CLASS
-- ============================================

--- Create a new WeaponVisualsMenu
---@return WeaponVisualsMenu
function WeaponVisualsMenu.new()
    local self = setmetatable(Submenu.new("Visuals"), WeaponVisualsMenu)
    return self
end

function WeaponVisualsMenu:Init()
    -- Loop toggle at the top
    self:AddOption(ToggleOption.new("Loop for All Weapons")
        :AddToggleRef(visualsState, "loopSize")
        :AddTooltip("Continuously apply the weapon size settings to any weapon in hand")
        :AddHotkey())

    self:AddOption(NumberOption.new(ScrollOption.Type.SCROLL, "Weapon width")
        :AddNumberRef(visualsState, "width", "%.1f", 0.1)
        :AddMin(0.0):AddMax(10.0)
        :AddFunction(function()
            ApplyWeaponSize(visualsState.width, visualsState.height)
        end)
        :AddTooltip("Edit the width of the weapon in hand")
        :AddHotkey())

    self:AddOption(NumberOption.new(ScrollOption.Type.SCROLL, "Weapon height")
        :AddNumberRef(visualsState, "height", "%.1f", 0.1)
        :AddMin(0.0):AddMax(10.0)
        :AddFunction(function()
            ApplyWeaponSize(visualsState.width, visualsState.height)
        end)
        :AddTooltip("Edit the height of the weapon in hand")
        :AddHotkey())

    self:AddOption(NumberOption.new(ScrollOption.Type.SCROLL, "Overall weapon scale")
        :AddNumberRef(visualsState, "overall", "%.1f", 0.1)
        :AddMin(0.0):AddMax(10.0)
        :AddFunction(function()
            -- Update to match scale
            visualsState.width = visualsState.overall
            visualsState.height = visualsState.overall
            ApplyWeaponSize(visualsState.overall, visualsState.overall)
        end)
        :AddTooltip("Edit the overall scale of the weapon in hand")
        :AddHotkey())

    self:AddOption(ToggleOption.new("Weapon invisibility")
        :AddToggleRef(visualsState, "invisibility")
        :AddFunction(function()
            if not visualsState.invisibility then
                local weaponEntity = GetWeaponEntity()
                if ENTITY.DOES_ENTITY_EXIST(weaponEntity) then
                    ENTITY.SET_ENTITY_VISIBLE(weaponEntity, true, false)
                end
            end
        end)
        :AddTooltip("Change the visibility of the weapon in hand")
        :AddHotkey())
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.TOGGLE, "Crosshair")
        :AddToggleRef(visualsState, "crosshair")
        :AddScroll(crosshairNames, 1)
        :AddIndexRef(visualsState, "selectedCrosshair")
        :AddTooltip("Draw a custom crosshair")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Aiming laser")
        :AddToggleRef(visualsState, "aimingLaser")
        :AddTooltip("Attach a laser onto your weapon when aiming")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Cartoon effects")
        :AddToggleRef(visualsState, "cartoonEffects")
        :AddFunction(function()
            -- Call native once when toggled on or off
            Script.QueueJob(function()
                GRAPHICS.ENABLE_CLOWN_BLOOD_VFX(visualsState.cartoonEffects)
            end)
        end)
        :AddTooltip("Shoot cool cartoon effects (clown blood)")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Aimed information")
        :AddToggleRef(visualsState, "aimedInformation")
        :AddTooltip("Show information on the aimed entity")
        :AddHotkey())
end


--- Called when entering this submenu
function WeaponVisualsMenu:OnEnter()
    local weaponEntity = GetWeaponEntity()
    if weaponEntity ~= 0 and GTA.HandleToPointer then
        local ptrObj = GTA.HandleToPointer(weaponEntity)
        if ptrObj then
             local ptr = ptrObj:GetAddress()
             if ptr and ptr ~= 0 then
                visualsState.width = Memory.ReadFloat(ptr + 0x7C)
                visualsState.height = Memory.ReadFloat(ptr + 0x8C)
                visualsState.overall = visualsState.width -- approximate
             end
        end
    end
end

--- Feature update - called every frame
function WeaponVisualsMenu:FeatureUpdate()
    if visualsState.loopSize then
        -- Continuously apply size
        ApplyWeaponSize(visualsState.width, visualsState.height)
    end

    if visualsState.invisibility then
        WeaponInvisibility()
    end
    
    if visualsState.crosshair then
        DrawCrosshair()
    end
    
    if visualsState.aimingLaser then
        AimingLaser()
    end
    
    -- Cartoon effects is handled by toggle only, not called every frame
    
    if visualsState.aimedInformation then
        AimedInformation()
    end
end

return WeaponVisualsMenu
