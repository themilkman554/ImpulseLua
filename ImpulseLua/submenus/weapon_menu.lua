
local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")

-- Import weapon submenus
local WeaponWeaponsMenu = require("Impulse/ImpulseLua/submenus/weapon/weapon_weapons_menu")
local WeaponVisualsMenu = require("Impulse/ImpulseLua/submenus/weapon/weapon_visuals_menu")
local WeaponAmmoModifierMenu = require("Impulse/ImpulseLua/submenus/weapon/weapon_ammo_modifier_menu")
local WeaponAimbotMenu = require("Impulse/ImpulseLua/submenus/weapon/weapon_aimbot_menu")

-- ... (skip to Init)
local WeaponShootEntitiesMenu = require("Impulse/ImpulseLua/submenus/weapon/weapon_shoot_entities_menu")

---@class WeaponMenu : Submenu
local WeaponMenu = setmetatable({}, { __index = Submenu })
WeaponMenu.__index = WeaponMenu

local instance = nil

-- Weapon state (matching C++ vars)
local weaponState = {
    noReload = false,
    infiniteAmmo = false,
    rapidFire = false,
    oneShotOneKill = false,
    deadEye = false,
    gravityGun = false,
    pickupGun = false,
    aimedExplosive = false,
    weaponInteriors = false,
    deleteGun = false,
    driveItGun = false,
    forceGun = false,
    shrinkRay = false,
    defibrillator = false,
    
    -- Gravity gun state
    gravityGunTarget = 0,
    gravityGunNewTarget = false,
    gravityGunDistance = 8.0,
    
    -- Pickup gun state
    pickupRange = 30.0,
    distanceFromGun = 5.0,
    pickupEntity = 0,
    
    -- Rapid fire timer
    rapidFireTimer = 0
}

-- Usable weapon hashes for giving weapons
local usableWeaponHashes = {
    126349499, 2694266206, 1233104067, 101631238, 911657153, 1834241177,
    0x1B06D571, 0x5EF9FEC4, 0x22D8FE39, 0x99AEEB3B, 0x2BE6766B, 0x13532244,
    0xBFEFFF6D, 0x83BF0278, 0xAF113F99, 0x9D07F764, 0x7FD62962, 0x1D073A89,
    0x7846A318, 0xE284C527, 0xC472FE2, 0x5FC3C11, 0xA284510B, 0xB1CA77B1,
    0x42BF8A85, 0x93E220BD, 0xFDBC8A50, 0x2C3731D9, 0x24B17070, 0x34A67B97,
    0xFBAB5776, 0x99B507EA, 0x678B81B1, 0x4E875F73, 0x958A4A8F, 0x84BD7BFD,
    0x440E4788, 0xEFE7E2DF, 0x9D61E50F, 0xF9E6AA4B, 0xC0A3098D, 0xBFD21232,
    0x476BF155, 0xAF3696A1, 0xB62D1F67, 0xD205520E, 0x7F229F94, 0x61012683,
    0x83839C4, 0x92A27487, 0xA89CB99E, 0x7F7497E5, 0x47757124, 0x3AABBBAA,
    0xC734385A, 0xAB564B93, 0x63AB0442, 0xF9DCBF2D, 0xA3D4D34, 0xD8DF3C3C,
    0xDC4DB296, 0xDD5DF8D9, 0xDB1AA450, 0xEF951FBB, 0x624FE830, 0x8BB05FD7,
    0xC1B3C3D1, 0xDFE37640, 0x78A97CD0, 0xA914799, 0x394F415C, 0x19044EE0,
    0x781FE4A, 0x12E82D3D, 0x176898A6, 0x787F0BB, 0xE232C28C, 0xD04C944D,
    0x0A3D4D34, 0x6D544C99, 0x2C082D7D, 0xCD274149, 0xBD248B55, 0xBA45E8B8,
    0x94117305
}

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

--- Get current weapon hash
---@return integer
local function GetCurrentWeaponHash()
    local ped = GetPlayerPed()
    local weaponHash = Memory.Alloc(8)
    WEAPON.GET_CURRENT_PED_WEAPON(ped, weaponHash, true)
    local hash = Memory.ReadInt(weaponHash)
    Memory.Free(weaponHash)
    return hash
end

--- Check if player has weapon in hand
---@return boolean
local function HasWeaponInHand()
    local hash = GetCurrentWeaponHash()
    return hash ~= 0xA2719263 -- WEAPON_UNARMED
end

--- Check if player is aiming
---@return boolean
local function IsPlayerAiming()
    return PED.GET_PED_CONFIG_FLAG(GetPlayerPed(), 78, true) -- PED_FLAG_IS_AIMING
end

--- Check if player is shooting
---@return boolean
local function IsPlayerShooting()
    return PED.IS_PED_SHOOTING(GetPlayerPed())
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

--- Request control of entity
---@param entity integer
local function RequestControl(entity)
    if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
    end
end

-- ============================================
-- FEATURE IMPLEMENTATIONS
-- ============================================

--- One shot one kill - set extreme damage modifier
---@param toggle boolean
local function OneShotOneKill(toggle)
    local playerId = GetPlayerId()
    local modifier = toggle and 999999.0 or 1.0
    PLAYER.SET_PLAYER_WEAPON_DAMAGE_MODIFIER(playerId, modifier)
    PLAYER.SET_PLAYER_MELEE_WEAPON_DAMAGE_MODIFIER(playerId, modifier, true)
end

--- Infinite ammo - set infinite ammo for all weapons
local function InfiniteAmmo()
    local ped = GetPlayerPed()
    WEAPON.SET_PED_INFINITE_AMMO_CLIP(ped, true)
    
    local currentWeapon = GetCurrentWeaponHash()
    WEAPON.SET_PED_INFINITE_AMMO(ped, true, currentWeapon)
    
    -- Also set for all weapons
    for _, weaponHash in ipairs(usableWeaponHashes) do
        WEAPON.SET_PED_INFINITE_AMMO(ped, true, weaponHash)
    end
end

--- No reload - keep ammo in clip
local function NoReload()
    local ped = GetPlayerPed()
    local weaponHash = GetCurrentWeaponHash()
    
    local maxAmmoPtr = Memory.Alloc(4)
    if WEAPON.GET_MAX_AMMO(ped, weaponHash, maxAmmoPtr) then
        local maxAmmo = Memory.ReadInt(maxAmmoPtr)
        WEAPON.SET_PED_AMMO(ped, weaponHash, maxAmmo, true)
        
        local maxClip = WEAPON.GET_MAX_AMMO_IN_CLIP(ped, weaponHash, true)
        if maxClip > 0 then
            WEAPON.SET_AMMO_IN_CLIP(ped, weaponHash, maxClip)
        end
    end
    Memory.Free(maxAmmoPtr)
end

--- Dead eye effect - slow motion when aiming
local function DeadEye()
    if IsPlayerAiming() then
        MISC.SET_TIME_SCALE(0.35)
        if IsPlayerShooting() then
            MISC.SET_TIME_SCALE(0.2)
            GRAPHICS.SET_TIMECYCLE_MODIFIER("Death")
        else
            GRAPHICS.CLEAR_TIMECYCLE_MODIFIER()
        end
        GRAPHICS.ANIMPOSTFX_PLAY("ExplosionJosh3", -1, true)
    else
        MISC.SET_TIME_SCALE(1.0)
        GRAPHICS.CLEAR_TIMECYCLE_MODIFIER()
        GRAPHICS.ANIMPOSTFX_STOP("ExplosionJosh3")
    end
end

--- Gravity gun - move entities with aiming
local function GravityGun()
    local ped = GetPlayerPed()
    local playerId = GetPlayerId()
    
    -- Get relative position for holding entity
    local relativePos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.4, 0.0, 0.6)
    
    -- Get camera direction
    local camRot = CAM.GET_GAMEPLAY_CAM_ROT(0)
    local camDir = V3.RotationToDirection(camRot)
    
    -- Get new target if we don't have one locked
    if not weaponState.gravityGunNewTarget then
        local entity = GetAimedEntity()
        if entity then
            weaponState.gravityGunTarget = entity
        end
    end
    
    if ENTITY.DOES_ENTITY_EXIST(weaponState.gravityGunTarget) then
        if IsPlayerAiming() then
            RequestControl(weaponState.gravityGunTarget)
            
            if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(weaponState.gravityGunTarget) then
                -- Distance controls
                if PAD.IS_DISABLED_CONTROL_PRESSED(2, 172) then -- INPUT_FRONTEND_UP
                    weaponState.gravityGunDistance = weaponState.gravityGunDistance + 0.5
                end
                if PAD.IS_DISABLED_CONTROL_PRESSED(2, 173) then -- INPUT_FRONTEND_DOWN
                    if weaponState.gravityGunDistance > 8.0 then
                        weaponState.gravityGunDistance = weaponState.gravityGunDistance - 0.5
                    end
                end
                
                -- If ped in vehicle, get the vehicle instead
                if ENTITY.IS_ENTITY_A_PED(weaponState.gravityGunTarget) and not PED.IS_PED_ON_FOOT(weaponState.gravityGunTarget) then
                    weaponState.gravityGunTarget = PED.GET_VEHICLE_PED_IS_IN(weaponState.gravityGunTarget, false)
                end
                
                weaponState.gravityGunNewTarget = true
                RequestControl(weaponState.gravityGunTarget)
                
                if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(weaponState.gravityGunTarget) then
                    ENTITY.FREEZE_ENTITY_POSITION(weaponState.gravityGunTarget, false)
                    
                    if ENTITY.IS_ENTITY_A_VEHICLE(weaponState.gravityGunTarget) then
                        VEHICLE.SET_VEHICLE_FORWARD_SPEED(weaponState.gravityGunTarget, 0.0)
                    end
                    
                    if ENTITY.IS_ENTITY_A_PED(weaponState.gravityGunTarget) then
                        PED.SET_PED_TO_RAGDOLL(weaponState.gravityGunTarget, 1, 1, 1, true, true, true)
                    end
                    
                    local entityCoords = ENTITY.GET_ENTITY_COORDS(weaponState.gravityGunTarget, false)
                    
                    -- Calculate force to move entity to target position
                    local targetX = relativePos.x + (camDir.x * weaponState.gravityGunDistance)
                    local targetY = relativePos.y + (camDir.y * weaponState.gravityGunDistance)
                    local targetZ = relativePos.z + (camDir.z * weaponState.gravityGunDistance)
                    
                    local forceX = (targetX - entityCoords.x) * 4
                    local forceY = (targetY - entityCoords.y) * 4
                    local forceZ = (targetZ - entityCoords.z) * 4
                    
                    ENTITY.SET_ENTITY_VELOCITY(weaponState.gravityGunTarget, forceX, forceY, forceZ)
                    
                    -- Shoot to launch entity
                    if IsPlayerShooting() or PAD.IS_DISABLED_CONTROL_PRESSED(0, 208) then
                        weaponState.gravityGunDistance = weaponState.gravityGunDistance + 2000
                        weaponState.gravityGunTarget = 0
                        weaponState.gravityGunNewTarget = false
                    end
                end
            end
        else
            -- Not aiming anymore - release entity
            weaponState.gravityGunNewTarget = false
            if ENTITY.DOES_ENTITY_EXIST(weaponState.gravityGunTarget) then
                ENTITY.FREEZE_ENTITY_POSITION(weaponState.gravityGunTarget, false)
            end
            weaponState.gravityGunTarget = 0
            weaponState.gravityGunDistance = 8.0
        end
    end
end

--- Delete gun - delete entities when shooting them
local function DeleteGun()
    local entity = GetAimedEntity()
    if entity and IsPlayerShooting() then
        RequestControl(entity)
        if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(entity, false, true)
            ENTITY.DELETE_ENTITY(entity)
        end
    end
end

--- Drive it gun - enter vehicle you shoot
local function DriveItGun()
    local entity = GetAimedEntity()
    if entity and IsPlayerShooting() then
        local ped = GetPlayerPed()
        
        if ENTITY.IS_ENTITY_A_VEHICLE(entity) then
            RequestControl(entity)
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(entity, -1, false)
            if driver and driver ~= 0 then
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(driver)
            end
            PED.SET_PED_INTO_VEHICLE(ped, entity, -1)
        elseif ENTITY.IS_ENTITY_A_PED(entity) then
            local vehicle = PED.GET_VEHICLE_PED_IS_IN(entity, false)
            if vehicle and vehicle ~= 0 then
                local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1, false)
                if driver and driver ~= 0 then
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(driver)
                end
                PED.SET_PED_INTO_VEHICLE(ped, vehicle, -1)
            end
        end
    end
end

--- Force gun - apply force to entities when shooting
local function ForceGun()
    if IsPlayerShooting() then
        local entity = GetAimedEntity()
        if entity then
            if ENTITY.IS_ENTITY_A_PED(entity) then
                local vehicle = PED.GET_VEHICLE_PED_IS_IN(entity, true)
                if vehicle and vehicle ~= 0 then
                    entity = vehicle
                end
            end
            
            RequestControl(entity)
            if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
                local camCoord = CAM.GET_GAMEPLAY_CAM_COORD()
                local camRot = CAM.GET_GAMEPLAY_CAM_ROT(0)
                local camDir = V3.RotationToDirection(camRot)
                
                local forceX = camCoord.x + (camDir.x * 999.0)
                local forceY = camCoord.y + (camDir.y * 999.0)
                local forceZ = camCoord.z + (camDir.z * 999.0)
                
                ENTITY.APPLY_FORCE_TO_ENTITY(entity, 3, forceX, forceY, forceZ, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
            end
        end
    end
end

--- Rapid fire - shoot bullets rapidly
local function RapidFire()
    local ped = GetPlayerPed()
    if PED.IS_PED_IN_ANY_VEHICLE(ped, true) then return end
    
    -- Check if attack button pressed
    if PAD.IS_CONTROL_PRESSED(2, 208) and HasWeaponInHand() then
        local now = MISC.GET_GAME_TIMER()
        if now - weaponState.rapidFireTimer > 100 then
            weaponState.rapidFireTimer = now
            
            local boneIndex = PED.GET_PED_BONE_INDEX(ped, 0x6F06) -- Right hand
            local start = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(ped, boneIndex)
            
            local camPitch = CAM.GET_GAMEPLAY_CAM_RELATIVE_PITCH()
            local inFrontZ = math.tan(math.rad(camPitch)) * 200
            
            local endPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 200.0, inFrontZ)
            
            local weaponHash = GetCurrentWeaponHash()
            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(start.x, start.y, start.z, endPos.x, endPos.y, endPos.z, 250, true, weaponHash, ped, false, true, 500.0)
        end
    end
end

--- Aimed explosive - explode where you aim
local function AimedExplosive()
    if PAD.IS_DISABLED_CONTROL_PRESSED(2, 205) then -- RB
        local ped = GetPlayerPed()
        local camRot = CAM.GET_GAMEPLAY_CAM_ROT(2)
        ENTITY.SET_ENTITY_HEADING(ped, camRot.z)
        
        local camCoord = CAM.GET_GAMEPLAY_CAM_COORD()
        local camDir = V3.RotationToDirection(camRot)
        
        local endX = camCoord.x + (camDir.x * 999.0)
        local endY = camCoord.y + (camDir.y * 999.0)
        local endZ = camCoord.z + (camDir.z * 999.0)
        
        -- Cast ray to find impact point
        local rayHandle = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
            camCoord.x, camCoord.y, camCoord.z,
            endX, endY, endZ,
            -1, ped, 7
        )
        
        local hitPtr = Memory.Alloc(4)
        local coordsPtr = Memory.Alloc(24)
        local normalPtr = Memory.Alloc(24)
        local entityPtr = Memory.Alloc(8)
        
        local result = SHAPETEST.GET_SHAPE_TEST_RESULT(rayHandle, hitPtr, coordsPtr, normalPtr, entityPtr)
        local hit = Memory.ReadInt(hitPtr) == 1
        
        if hit then
            local hitCoords = Memory.ReadV3(coordsPtr)
            local rightEye = PED.GET_PED_BONE_COORDS(ped, 31086, 0.037, 0.0, 0.0)
            
            GRAPHICS.DRAW_LINE(rightEye.x, rightEye.y, rightEye.z, hitCoords.x, hitCoords.y, hitCoords.z, 255, 0, 0, 255)
            FIRE.ADD_EXPLOSION(hitCoords.x, hitCoords.y, hitCoords.z, 18, 1.0, true, false, 0.1, false)
        end
        
        Memory.Free(hitPtr)
        Memory.Free(coordsPtr)
        Memory.Free(normalPtr)
        Memory.Free(entityPtr)
    end
end



--- Pickup gun - pick up and throw entities
local function PickupGun()
    local ped = GetPlayerPed()
    local playerId = GetPlayerId()
    
    -- Get entity we're aiming at
    local entity = GetAimedEntity()
    if entity then
        local pedCoords = ENTITY.GET_ENTITY_COORDS(ped, false)
        local entityCoords = ENTITY.GET_ENTITY_COORDS(entity, false)
        
        -- Check if in range
        local dx = pedCoords.x - entityCoords.x
        local dy = pedCoords.y - entityCoords.y
        local dz = pedCoords.z - entityCoords.z
        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
        
        if dist <= weaponState.pickupRange then
            weaponState.pickupEntity = entity
            
            -- If ped in vehicle, get vehicle
            if ENTITY.IS_ENTITY_A_PED(entity) and PED.IS_PED_IN_ANY_VEHICLE(entity, false) then
                weaponState.pickupEntity = PED.GET_VEHICLE_PED_IS_IN(entity, false)
            end
        end
    end
    
    if weaponState.pickupEntity ~= 0 and ENTITY.DOES_ENTITY_EXIST(weaponState.pickupEntity) then
        if IsPlayerAiming() or PLAYER.IS_PLAYER_TARGETTING_ANYTHING(playerId) then
            local camCoord = CAM.GET_GAMEPLAY_CAM_COORD()
            local camRot = CAM.GET_GAMEPLAY_CAM_ROT(0)
            local camDir = V3.RotationToDirection(camRot)
            
            -- Calculate position in front of camera
            local targetX = camCoord.x + (camDir.x * weaponState.distanceFromGun)
            local targetY = camCoord.y + (camDir.y * weaponState.distanceFromGun)
            local targetZ = camCoord.z + (camDir.z * weaponState.distanceFromGun)
            
            RequestControl(weaponState.pickupEntity)
            ENTITY.SET_ENTITY_COLLISION(weaponState.pickupEntity, false, true)
            
            if ENTITY.IS_ENTITY_A_PED(weaponState.pickupEntity) then
                ENTITY.SET_ENTITY_INVINCIBLE(weaponState.pickupEntity, true)
            end
            
            if not IsPlayerShooting() then
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(weaponState.pickupEntity, targetX, targetY, targetZ, false, false, false)
            end
            
            if ENTITY.IS_ENTITY_A_VEHICLE(weaponState.pickupEntity) or ENTITY.IS_ENTITY_A_PED(weaponState.pickupEntity) then
                local myHeading = ENTITY.GET_ENTITY_HEADING(ped)
                ENTITY.SET_ENTITY_HEADING(weaponState.pickupEntity, myHeading + 90.0)
            end
            
            if IsPlayerShooting() then
                RequestControl(weaponState.pickupEntity)
                ENTITY.SET_ENTITY_COLLISION(weaponState.pickupEntity, true, true)
                ENTITY.SET_ENTITY_HEADING(weaponState.pickupEntity, ENTITY.GET_ENTITY_HEADING(ped))
                
                local launchX = camCoord.x + (camDir.x * 500.0)
                local launchZ = 2.0 + launchX - camCoord.z
                
                ENTITY.APPLY_FORCE_TO_ENTITY(weaponState.pickupEntity, 1, 0.0, 350.0, launchZ, 2.0, 0.0, 0.0, 0, true, true, true, false, true)
                weaponState.pickupEntity = 0
            end
        else
            RequestControl(weaponState.pickupEntity)
            ENTITY.SET_ENTITY_COLLISION(weaponState.pickupEntity, true, true)
            weaponState.pickupEntity = 0
        end
    end
end

--- Shrink ray - shrink peds when aiming with stungun
local function ShrinkRay()
    if IsPlayerAiming() then
        local weaponHash = GetCurrentWeaponHash()
        if weaponHash == 0x3656C8C1 then -- WEAPON_STUNGUN
            local entity = GetAimedEntity()
            if entity and ENTITY.IS_ENTITY_A_PED(entity) then
                PED.SET_PED_CONFIG_FLAG(entity, 223, true)
            end
        end
    end
end

--- Defibrillator - revive dead peds
local function Defibrillator()
    if IsPlayerShooting() then
        local weaponHash = GetCurrentWeaponHash()
        if weaponHash == 0x3656C8C1 then -- WEAPON_STUNGUN
            local entity = GetAimedEntity()
            if entity and ENTITY.IS_ENTITY_A_PED(entity) then
                if ENTITY.GET_ENTITY_HEALTH(entity) <= 0 then
                    PED.RESURRECT_PED(entity)
                    ENTITY.SET_ENTITY_COLLISION(entity, true, false)
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(entity)
                end
            end
        end
    end
end

-- ============================================
-- MENU CLASS
-- ============================================

--- Get singleton instance
---@return WeaponMenu
function WeaponMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Weapon"), WeaponMenu)
        instance:Init()
    end
    return instance
end

function WeaponMenu:Init()
    -- Weapon submenus (matching C++ order)
    
    -- Weapons submenu
    self.weaponsSubmenu = WeaponWeaponsMenu.GetInstance()
    self.weaponsSubmenu:Init()

    self:AddOption(SubmenuOption.new("Weapons")
        :AddSubmenu(self.weaponsSubmenu)
        :AddTooltip("Give weapons, upgrades, and tints")
        :AddHotkey())
    
    self.visualsSubmenu = WeaponVisualsMenu.new()
    self.visualsSubmenu:Init()
    
    self:AddOption(SubmenuOption.new("Visuals")
        :AddSubmenu(self.visualsSubmenu)
        :AddTooltip("Weapon visuals")
        :AddHotkey())
    
    -- Ammo modifiers submenu
    self.ammoModifierSubmenu = WeaponAmmoModifierMenu.new()
    self.ammoModifierSubmenu:Init()
    
    self:AddOption(SubmenuOption.new("Ammo modifiers")
        :AddSubmenu(self.ammoModifierSubmenu)
        :AddTooltip("Weapon ammo modifiers")
        :AddHotkey())
    
    -- Aimbot submenu
    self.aimbotSubmenu = WeaponAimbotMenu.GetInstance()
    self.aimbotSubmenu:Init()

    self:AddOption(SubmenuOption.new("Aimbot")
        :AddSubmenu(self.aimbotSubmenu)
        :AddTooltip("Weapon aimbot")
        :AddHotkey())
        :SetDonor()
    -- Shoot entities submenu
    self.shootEntitiesSubmenu = WeaponShootEntitiesMenu.GetInstance() -- Using GetInstance to match singletons
    
    self:AddOption(SubmenuOption.new("Shoot entities")
        :AddSubmenu(self.shootEntitiesSubmenu)
        :AddTooltip("Shoot entities")
        :AddHotkey())
    
    -- General section
    self:AddOption(BreakOption.new("General"))
    
    self:AddOption(ToggleOption.new("No reload")
        :AddToggleRef(weaponState, "noReload")
        :AddTooltip("No more reloading")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Infinite ammo")
        :AddToggleRef(weaponState, "infiniteAmmo")
        :AddTooltip("Infinite ammo")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Rapid fire")
        :AddToggleRef(weaponState, "rapidFire")
        :AddTooltip("Shoot rapidly")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("One shot one kill")
        :AddToggleRef(weaponState, "oneShotOneKill")
        :AddFunction(function()
            OneShotOneKill(weaponState.oneShotOneKill)
        end)
        :AddTooltip("One bullet kills")
        :AddHotkey())
    
    -- Entity movement section
    self:AddOption(BreakOption.new("Entity movement"))
    
    self:AddOption(ToggleOption.new("Gravity gun")
        :AddToggleRef(weaponState, "gravityGun")
        :AddFunction(function()
            if not weaponState.gravityGun then
                weaponState.gravityGunTarget = 0
                weaponState.gravityGunNewTarget = false
            end
        end)
        :AddTooltip("Move around entities (first one will hit you)")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Pickup gun")
        :AddToggleRef(weaponState, "pickupGun")
        :AddTooltip("Move around entities")
        :AddHotkey())
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Pickup range")
        :SetNumber(weaponState, "pickupRange")
        :SetMin(1.0):SetMax(100.0):SetStep(5.0)
        :SetFormat("%.1f")
        :AddTooltip("Control the range that pickup gun can pick items up")
        :AddHotkey())
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Distance from gun")
        :SetNumber(weaponState, "distanceFromGun")
        :SetMin(1.0):SetMax(100.0):SetStep(1.0)
        :SetFormat("%.1f")
        :AddTooltip("Control the distance of the entity from your gun using pickup gun")
        :AddHotkey())
    
    -- Misc section
    self:AddOption(BreakOption.new("Misc"))
    
    self:AddOption(ToggleOption.new("Dead eye")
        :AddToggleRef(weaponState, "deadEye")
        :AddTooltip("Activate dead eye")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Weapons in interiors and passive mode")
        :AddToggleRef(weaponState, "weaponInteriors")
        :AddFunction(function()
            local value = weaponState.weaponInteriors
            FeatureMgr.GetFeatureByName("Allow Weapons In Interiors"):Toggle(value)
            FeatureMgr.GetFeatureByName("Unlock Movement In Interiors"):Toggle(value)
        end)
        :AddTooltip("Enables you to use weapons in interiors and in passive mode")
        :AddHotkey())
        
    -- Sync initial state
    if FeatureState.Get then
        weaponState.weaponInteriors = FeatureState.Get("Allow Weapons In Interiors")
    end
    
    self:AddOption(ToggleOption.new("Aimed explosive")
        :AddToggleRef(weaponState, "aimedExplosive")
        :AddTooltip("Aim and explode what you are looking at - use right mouse button / RB")
        :AddHotkey())
        :SetDonor()
end

--- Feature update - called every frame for background processing
function WeaponMenu:FeatureUpdate()
    -- Only run features if player has weapon in hand
    if HasWeaponInHand() then
        if weaponState.oneShotOneKill then OneShotOneKill(true) end
        if weaponState.infiniteAmmo then InfiniteAmmo() end
        if weaponState.deadEye then DeadEye() end
        if weaponState.shrinkRay then ShrinkRay() end
        if weaponState.gravityGun then GravityGun() end
        if weaponState.defibrillator then Defibrillator() end
        if weaponState.deleteGun then DeleteGun() end
        if weaponState.driveItGun then DriveItGun() end
        if weaponState.rapidFire then RapidFire() end
        if weaponState.forceGun then ForceGun() end
        if weaponState.noReload then NoReload() end
        if weaponState.aimedExplosive then AimedExplosive() end
        if weaponState.pickupGun then PickupGun() end
    end
    
    -- Weapon interiors runs always when enabled
    -- if weaponState.weaponInteriors then WeaponsInInteriors() end
    
    -- Update submenus
    if self.weaponsSubmenu and self.weaponsSubmenu.FeatureUpdate then
        self.weaponsSubmenu:FeatureUpdate()
    end
    if self.visualsSubmenu and self.visualsSubmenu.FeatureUpdate then
        self.visualsSubmenu:FeatureUpdate()
    end
    if self.ammoModifierSubmenu and self.ammoModifierSubmenu.FeatureUpdate then
        self.ammoModifierSubmenu:FeatureUpdate()
    end
    if self.aimbotSubmenu and self.aimbotSubmenu.FeatureUpdate then
        self.aimbotSubmenu:FeatureUpdate()
    end
    if self.shootEntitiesSubmenu and self.shootEntitiesSubmenu.FeatureUpdate then
        self.shootEntitiesSubmenu:FeatureUpdate()
    end
end

return WeaponMenu
