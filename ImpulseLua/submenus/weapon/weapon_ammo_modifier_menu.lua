--[[
    Impulse Lua - Weapon Ammo Modifier Submenu
    Port of weaponAmmoModifier.cpp from Impulse C++
    Various ammo modifications and special shooting effects
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")

---@class WeaponAmmoModifierMenu : Submenu
local WeaponAmmoModifierMenu = setmetatable({}, { __index = Submenu })
WeaponAmmoModifierMenu.__index = WeaponAmmoModifierMenu

-- State
local ammoState = {
    -- Impact ammo
    impactAmmo = false,
    impactAmmoType = 1,
    
    -- Particle ammo
    particleAmmo = false,
    particleAmmoType = 1,
    
    -- Modify ammo (change bullet type)
    modifyAmmo = false,
    modifyAmmoType = 1,
    
    -- Shoot options
    explosiveWhaleGun = false,
    missileGun = false,
    missileGunNoTimeLimit = false,
    explosiveBullets = false,
    fireBullets = false,
    paintVehicleGun = false,
    modelChangeGun = false,
    
    -- FeatureMgr-based options
    deleteGun = false,
    driveItGun = false,
    shrinkRay = false,
    pedDefibrillator = false,
    
    -- Missile gun state
    missileEntity = 0,
    missileCam = 0,
    missileGunRunning = false,
    missileTimeout = 0,
    spawningMissile = false,
    rayHandle = nil
}



--- Sync local state with Cherax's actual state
--- Sync local state with Cherax's actual state
local function SyncStates()
    ammoState.deleteGun = FeatureState.Get("Delete Gun")
    ammoState.driveItGun = FeatureState.Get("Drive Gun")
    ammoState.shrinkRay = FeatureState.Get("Shrink Gun")
    ammoState.pedDefibrillator = FeatureState.Get("Revive Gun")
    ammoState.modelChangeGun = FeatureState.Get("Soul Switch Gun")
end

-- Impact ammo types
local impactTypes = {
    { name = "Money Bags", value = 0 },
    { name = "Teleport (Me)", value = 1 },
    { name = "Explosion", value = 2 },
    { name = "Print Position", value = 3 },
    { name = "Airstrike", value = 4 },
    { name = "Flare", value = 5 },
    { name = "Water Fountain", value = 6 },
    { name = "Gas Fountain", value = 7 }
}

-- Particle ammo effects
local particleTypes = {
    { name = "Alien Teleport", asset = "scr_rcbarry1", effect = "scr_alien_teleport", size = 1.5 },
    { name = "Money", asset = "scr_paletoscore", effect = "scr_paleto_banknotes", size = 2.5 },
    { name = "Blood", asset = "scr_solomon3", effect = "scr_trev4_747_blood_impact", size = 0.9 },
    { name = "Alien Disintegrate", asset = "scr_rcbarry1", effect = "scr_alien_disintegrate", size = 0.9 },
    { name = "Electric", asset = "scr_trevor1", effect = "scr_trev1_trailer_boosh", size = 1.5 },
    { name = "Fire", asset = "scr_agencyheist", effect = "scr_fbi_dd_breach_smoke", size = 0.4 },
    { name = "Clown Death", asset = "scr_rcbarry2", effect = "scr_clown_death", size = 2.0 },
    { name = "Clown Appears", asset = "scr_rcbarry2", effect = "scr_clown_appears", size = 2.0 },
    { name = "Flowers", asset = "scr_rcbarry2", effect = "scr_exp_clown", size = 1.5 },
    { name = "Fireworks", asset = "scr_indep_fireworks", effect = "scr_indep_firework_starburst", size = 0.5 }
}

-- Modify ammo types (weapon hashes to shoot)
local modifyAmmoTypes = {
    { name = "RPG", hash = 0xb1ca77b1 },
    { name = "Firework", hash = 0x7f7497e5 },
    { name = "Tank", hash = 0x73f7c04b },
    { name = "Space Rocket", hash = 0xf8a3939f },
    { name = "Plane Rocket", hash = 0xcf0896e0 },
    { name = "Snowball", hash = 0x787F0BB },
    { name = "Flare", hash = 0x497FACC3 }
}

-- Build name arrays for scroll options
local impactNames = {}
for i, v in ipairs(impactTypes) do impactNames[i] = v.name end

local particleNames = {}
for i, v in ipairs(particleTypes) do particleNames[i] = v.name end

local modifyAmmoNames = {}
for i, v in ipairs(modifyAmmoTypes) do modifyAmmoNames[i] = v.name end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function GetPlayerPed()
    return PLAYER.PLAYER_PED_ID()
end

local function GetPlayerId()
    return PLAYER.PLAYER_ID()
end

local function IsPlayerShooting()
    return PED.IS_PED_SHOOTING(GetPlayerPed())
end

--- Get entity player is aiming at
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

--- Get last weapon impact coords
--- Get last weapon impact coords
local function GetLastWeaponImpactCoord()
    -- Alloc 24 bytes (3 floats * 8 bytes each, as per ExplosiveBullets)
    local coordsPtr = Memory.Alloc(24)
    local ped = GetPlayerPed()
    
    local result = WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(ped, coordsPtr)
    
    if result and result ~= 0 then
        -- Read coordinates with 8-byte alignment
        local x = Memory.ReadFloat(coordsPtr)
        local y = Memory.ReadFloat(coordsPtr + 8)
        local z = Memory.ReadFloat(coordsPtr + 16)
        
        Memory.Free(coordsPtr)
        
        -- Return as vector-like table
        return {x = x, y = y, z = z}
    end
    
    Memory.Free(coordsPtr)
    return nil
end

--- Request entity control
local function RequestControl(entity)
    if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
    end
end

-- ============================================
-- FEATURE IMPLEMENTATIONS
-- ============================================

--- Impact ammo effect
local function ImpactAmmo()
    Script.QueueJob(function()
        if not IsPlayerShooting() then return end
        
        local coords = GetLastWeaponImpactCoord()
        if not coords then return end
        
        local impactType = impactTypes[ammoState.impactAmmoType]
        if not impactType then return end
        
        local ped = GetPlayerPed()
        
        if impactType.value == 0 then
            -- Money Bags
            OBJECT.CREATE_AMBIENT_PICKUP(0x1E9A99F8, coords.x, coords.y, coords.z + 2, 0, 2500, -1666779307, false, true)
        elseif impactType.value == 1 then
            -- Teleport me
            ENTITY.SET_ENTITY_COORDS(ped, coords.x, coords.y, coords.z, false, false, false, true)
        elseif impactType.value == 2 then
            -- Explosion
            FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 0, 5.0, true, false, 0.0, false)
        elseif impactType.value == 3 then
            -- Print position
            Renderer.Notify(string.format("%.3f, %.3f, %.3f", coords.x, coords.y, coords.z))
        elseif impactType.value == 4 then
            -- Airstrike
            FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 29, 20.0, true, false, 1.0, false)
        elseif impactType.value == 5 then
            -- Flare
            WEAPON.CREATE_WEAPON_OBJECT(0x497FACC3, 1, coords.x, coords.y, coords.z, true, 1.0, 0, 0, 0)
        elseif impactType.value == 6 then
            -- Water Fountain
            FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 13, 20.0, true, false, 1.0, false)
        elseif impactType.value == 7 then
            -- Gas Fountain
            FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 21, 20.0, true, false, 1.0, false)
        end
    end)
end

local function ParticleAmmo()
    Script.QueueJob(function()
        if not IsPlayerShooting() then return end
        
        local coords = GetLastWeaponImpactCoord()
        if not coords then return end
        
        local particle = particleTypes[ammoState.particleAmmoType]
        if not particle then return end
        
        -- Check/Request asset
        if not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(particle.asset) then
            STREAMING.REQUEST_NAMED_PTFX_ASSET(particle.asset)
            return
        end
        
        -- Use and play effect
        GRAPHICS.USE_PARTICLE_FX_ASSET(particle.asset)
        GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
            particle.effect,
            coords.x, coords.y, coords.z,
            0.0, 0.0, 0.0,
            particle.size,
            false, false, false, false
        )
    end)
end

--- Modify ammo - shoot different projectiles
local function ModifyAmmo()
    if not IsPlayerShooting() then return end
    
    local ammoType = modifyAmmoTypes[ammoState.modifyAmmoType]
    if not ammoType then return end
    
    local ped = GetPlayerPed()
    local boneIndex = PED.GET_PED_BONE_INDEX(ped, 0x6F06) -- Right hand
    local p0 = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(ped, boneIndex)
    
    local camPitch = CAM.GET_GAMEPLAY_CAM_RELATIVE_PITCH()
    local p1 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 200.0, math.tan(math.rad(camPitch)) * 200)
    
    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(p0.x, p0.y, p0.z, p1.x, p1.y, p1.z, 250, false, ammoType.hash, ped, true, true, 10000.0)
end

--- Explosive bullets - explosion at bullet impact
local function ExplosiveBullets()
    Script.QueueJob(function()
        local ped = GetPlayerPed()
        local coordsPtr = Memory.Alloc(24) -- 3 floats * 8 bytes each
        
        local result = WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(ped, coordsPtr)
        
        if result then
            -- Read floats individually instead of ReadV3
            local x = Memory.ReadFloat(coordsPtr)
            local y = Memory.ReadFloat(coordsPtr + 8)
            local z = Memory.ReadFloat(coordsPtr + 16)
            
            if x ~= 0 or y ~= 0 or z ~= 0 then
                FIRE.ADD_EXPLOSION(x, y, z, 0, 5.0, true, false, 0.0, false)
            end
        end
        
        Memory.Free(coordsPtr)
    end)
end

--- Fire bullets - start fire at bullet impact
local function FireBullets()
    Script.QueueJob(function()
        local ped = GetPlayerPed()
        local coordsPtr = Memory.Alloc(24)
        
        local result = WEAPON.GET_PED_LAST_WEAPON_IMPACT_COORD(ped, coordsPtr)
        
        if result then
            local x = Memory.ReadFloat(coordsPtr)
            local y = Memory.ReadFloat(coordsPtr + 8)
            local z = Memory.ReadFloat(coordsPtr + 16)
            
            if x ~= 0 or y ~= 0 or z ~= 0 then
                -- Use molotov explosion type (3) for fire effect
                FIRE.ADD_EXPLOSION(x, y, z, 3, 1.0, true, false, 0.0, false)
            end
        end
        
        Memory.Free(coordsPtr)
    end)
end

--- Paint vehicle gun
local function PaintVehicleGun()
    if not IsPlayerShooting() then return end
    
    local entity = GetAimedEntity()
    if not entity then return end
    
    local vehicle = nil
    
    if ENTITY.IS_ENTITY_A_VEHICLE(entity) then
        vehicle = entity
    elseif ENTITY.IS_ENTITY_A_PED(entity) then
        local pedVeh = PED.GET_VEHICLE_PED_IS_IN(entity, false)
        if pedVeh and pedVeh ~= 0 then
            vehicle = pedVeh
        end
    end
    
    if vehicle then
        RequestControl(vehicle)
        if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
            local r1, g1, b1 = MISC.GET_RANDOM_INT_IN_RANGE(0, 255), MISC.GET_RANDOM_INT_IN_RANGE(0, 255), MISC.GET_RANDOM_INT_IN_RANGE(0, 255)
            local r2, g2, b2 = MISC.GET_RANDOM_INT_IN_RANGE(0, 255), MISC.GET_RANDOM_INT_IN_RANGE(0, 255), MISC.GET_RANDOM_INT_IN_RANGE(0, 255)
            VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, r1, g1, b1)
            VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle, r2, g2, b2)
        end
    end
end

--- Explosive whale gun - spawn whale that explodes on impact
local function ExplosiveWhaleGun()
    if not IsPlayerShooting() then return end
    
    Script.QueueJob(function()
        -- Get camera info inside the job
        local camRot = CAM.GET_GAMEPLAY_CAM_ROT(0)
        local camCoord = CAM.GET_GAMEPLAY_CAM_COORD()
        
        -- Convert rotation to direction manually if V3.RotationToDirection doesn't work
        local pitch = math.rad(camRot.x)
        local yaw = math.rad(camRot.z)
        
        local dirX = -math.sin(yaw) * math.cos(pitch)
        local dirY = math.cos(yaw) * math.cos(pitch)
        local dirZ = math.sin(pitch)
        
        -- Spawn whale in front of camera
        local spawnX = camCoord.x + (dirX * 5)
        local spawnY = camCoord.y + (dirY * 5)
        local spawnZ = camCoord.z + (dirZ * 5)
        
        -- Use Cherax API to spawn ped
        local spawnedPed = GTA.CreatePed("a_c_killerwhale", 26, spawnX, spawnY, spawnZ, 1.0, true, false)
        
        if spawnedPed and ENTITY.DOES_ENTITY_EXIST(spawnedPed) then
            ENTITY.SET_ENTITY_RECORDS_COLLISIONS(spawnedPed, true)
            
            -- Launch whale in camera direction and check for collision
            for i = 1, 75 do
                if not ENTITY.DOES_ENTITY_EXIST(spawnedPed) then break end
                if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(spawnedPed) then break end
                ENTITY.APPLY_FORCE_TO_ENTITY(spawnedPed, 1, dirX * 10, dirY * 10, dirZ * 10, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                Script.Yield()
            end
            
            if ENTITY.DOES_ENTITY_EXIST(spawnedPed) then
                local coords = ENTITY.GET_ENTITY_COORDS(spawnedPed, true)
                ENTITY.SET_ENTITY_AS_MISSION_ENTITY(spawnedPed, true, true)
                PED.DELETE_PED(spawnedPed)
                FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 9, 25.0, true, false, 0.5, false)
            end
        end
    end)
end

--- Missile Gun Feature
local function MissileGun()
    local success, err = pcall(function()
        -- Start missile gun if shooting
        if IsPlayerShooting() and not ammoState.missileGunRunning and not ammoState.spawningMissile then
            ammoState.spawningMissile = true
            Script.QueueJob(function()
                local status, spawnErr = pcall(function()
                    local ped = GetPlayerPed()
                    local rocketHash = MISC.GET_HASH_KEY("prop_ld_bomb_01")
                    
                    STREAMING.REQUEST_MODEL(rocketHash)
                    local timeout = MISC.GET_GAME_TIMER() + 2000
                    while not STREAMING.HAS_MODEL_LOADED(rocketHash) and MISC.GET_GAME_TIMER() < timeout do
                        STREAMING.REQUEST_MODEL(rocketHash)
                        Script.Yield()
                    end

                    if STREAMING.HAS_MODEL_LOADED(rocketHash) then
                        local spawnPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 3.0, 0.8)
                        local gameplayRot = CAM.GET_GAMEPLAY_CAM_ROT(2)
                        
                        ammoState.missileEntity = OBJECT.CREATE_OBJECT(rocketHash, spawnPos.x, spawnPos.y, spawnPos.z, true, false, true)
                        
                        if ENTITY.DOES_ENTITY_EXIST(ammoState.missileEntity) then
                            ENTITY.SET_ENTITY_ROTATION(ammoState.missileEntity, gameplayRot.x, gameplayRot.y, gameplayRot.z, 2, true)
                            
                            local entityRot = ENTITY.GET_ENTITY_ROTATION(ammoState.missileEntity, 2)
                            ammoState.missileCam = CAM.CREATE_CAM_WITH_PARAMS("DEFAULT_SCRIPTED_CAMERA", spawnPos.x, spawnPos.y, spawnPos.z, entityRot.x, entityRot.y, entityRot.z, 65.0, true, 2)
                            
                            if ammoState.missileCam ~= 0 and CAM.DOES_CAM_EXIST(ammoState.missileCam) then
                                CAM.ATTACH_CAM_TO_ENTITY(ammoState.missileCam, ammoState.missileEntity, 0.0, 1.1, 0.0, true)
                                CAM.SET_CAM_ACTIVE(ammoState.missileCam, true)
                                CAM.RENDER_SCRIPT_CAMS(true, true, 750, true, false, 0)
                                
                                if ammoState.missileGunNoTimeLimit then
                                    ammoState.missileTimeout = MISC.GET_GAME_TIMER() + 99999999
                                else
                                    ammoState.missileTimeout = MISC.GET_GAME_TIMER() + 12000
                                end
                                
                                GRAPHICS.SET_TIMECYCLE_MODIFIER("CAMERA_BW")
                                ammoState.missileGunRunning = true
                            end
                        end
                    end
                end)
                if not status then print("MissileGun Job Error: " .. tostring(spawnErr)) end
                ammoState.spawningMissile = false
            end)
        end

        -- Update running missile
        if ammoState.missileGunRunning then
            STREAMING.SET_FOCUS_POS_AND_VEL(CAM.GET_CAM_COORD(ammoState.missileCam).x, CAM.GET_CAM_COORD(ammoState.missileCam).y, CAM.GET_CAM_COORD(ammoState.missileCam).z, 0, 0, 0)
            
            -- Draw HUD
            if not ammoState.missileGunNoTimeLimit then
                local white = {r=255, g=255, b=255, a=255}
                Renderer.DrawRect(0.469, 0.500, 0.002, 0.100, white)
                Renderer.DrawRect(0.532, 0.500, 0.002, 0.100, white)
                Renderer.DrawRect(0.501, 0.552, 0.065, 0.003, white)
                Renderer.DrawRect(0.501, 0.451, 0.065, 0.003, white)
                Renderer.DrawRect(0.500, 0.415, 0.002, 0.070, white)
                Renderer.DrawRect(0.500, 0.585, 0.002, 0.070, white)
                Renderer.DrawRect(0.445, 0.501, 0.045, 0.002, white)
                Renderer.DrawRect(0.555, 0.501, 0.045, 0.002, white)
                Renderer.DrawRect(0.210, 0.500, 0.020, 0.500, white)
                
                local height = (ammoState.missileTimeout - MISC.GET_GAME_TIMER()) / 24000.0
                local usageColor = {r=0, g=255, b=0, a=255}
                
                if height > 0.4 then usageColor = {r=0, g=255, b=0, a=255}
                elseif height > 0.3 then usageColor = {r=255, g=255, b=0, a=255}
                elseif height > 0.2 then usageColor = {r=255, g=150, b=0, a=255}
                else usageColor = {r=255, g=0, b=0, a=255} end
                
                Renderer.DrawRect(0.21, (0.5 + (0.5 / 2) - height + (height * 0.5)), 0.02, height, usageColor)
            end
            
            -- Handle timeout or collision
            local shouldExplode = false
            local impactCoords = nil

            if MISC.GET_GAME_TIMER() >= ammoState.missileTimeout then
                shouldExplode = true
            else
                -- Control missile
                local rocketRot = CAM.GET_GAMEPLAY_CAM_ROT(2)
                CAM.SET_CAM_ROT(ammoState.missileCam, rocketRot.x, rocketRot.y, rocketRot.z, 2)
                ENTITY.SET_ENTITY_ROTATION(ammoState.missileEntity, rocketRot.x, rocketRot.y, rocketRot.z, 2, true)
                
                local speed = 0.6 + (PAD.IS_DISABLED_CONTROL_PRESSED(0, 21) and 1.0 or 0.0)
                if PAD.IS_DISABLED_CONTROL_PRESSED(0, 21) then
                    ammoState.missileTimeout = ammoState.missileTimeout - 20
                end
                
                local inworld = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ammoState.missileEntity, 0.0, speed, 0.0)
                ENTITY.SET_ENTITY_COORDS(ammoState.missileEntity, inworld.x, inworld.y, inworld.z, false, false, false, true)
                
                -- Collision check - Async Raycast
                if not ammoState.rayHandle then
                    -- Start new ray
                    local camCoord = CAM.GET_CAM_COORD(ammoState.missileCam)
                    local forwardX, forwardY, forwardZ = -math.sin(math.rad(rocketRot.z)) * math.abs(math.cos(math.rad(rocketRot.x))), math.cos(math.rad(rocketRot.z)) * math.abs(math.cos(math.rad(rocketRot.x))), math.sin(math.rad(rocketRot.x))
                    local endX, endY, endZ = camCoord.x + forwardX * 25.0, camCoord.y + forwardY * 25.0, camCoord.z + forwardZ * 25.0
                    
                    ammoState.rayHandle = SHAPETEST.START_SHAPE_TEST_LOS_PROBE(camCoord.x, camCoord.y, camCoord.z, endX, endY, endZ, 23, ammoState.missileEntity, 7)
                else
                    -- Check existing ray
                    local hitPtr = Memory.AllocInt()
                    local endCoordsPtr = Memory.Alloc(24)
                    local surfaceNormalPtr = Memory.Alloc(24)
                    local entityHitPtr = Memory.AllocInt()
                    
                    local result = SHAPETEST.GET_SHAPE_TEST_RESULT(ammoState.rayHandle, hitPtr, endCoordsPtr, surfaceNormalPtr, entityHitPtr)
                    
                    if result == 2 then -- Finished
                        local hit = Memory.ReadInt(hitPtr)
                        local entityHit = Memory.ReadInt(entityHitPtr)
                        local endCoords = Memory.ReadV3(endCoordsPtr)

                        if hit == 1 then
                            local camCoord = CAM.GET_CAM_COORD(ammoState.missileCam)
                            local dist = math.sqrt((camCoord.x - endCoords.x)^2 + (camCoord.y - endCoords.y)^2 + (camCoord.z - endCoords.z)^2)
                            
                            if dist < 2.5 then
                                shouldExplode = true
                                impactCoords = endCoords
                            end
                        end
                        
                        ammoState.rayHandle = nil -- Reset for next frame
                    elseif result == 0 then
                        -- Failed, reset
                        ammoState.rayHandle = nil
                    end
                    
                    Memory.Free(hitPtr)
                    Memory.Free(endCoordsPtr)
                    Memory.Free(surfaceNormalPtr)
                    Memory.Free(entityHitPtr)
                end
            end

            if shouldExplode then
                GRAPHICS.SET_TIMECYCLE_MODIFIER("")
                local camCoord = CAM.GET_CAM_COORD(ammoState.missileCam)
                
                local expX, expY, expZ = camCoord.x, camCoord.y, camCoord.z
                if impactCoords then
                    expX, expY, expZ = impactCoords.x, impactCoords.y, impactCoords.z
                end
                
                -- Stop running immediately to prevent further updates
                ammoState.missileGunRunning = false
                ammoState.rayHandle = nil
                
                Script.QueueJob(function()
                    pcall(function()
                        FIRE.ADD_EXPLOSION(expX, expY, expZ, 29, 1.0, true, false, 0.5, false)
                        
                        -- Instant reset of camera
                        CAM.RENDER_SCRIPT_CAMS(false, false, 0, true, false, 0)
                        
                        if CAM.DOES_CAM_EXIST(ammoState.missileCam) then
                            CAM.SET_CAM_ACTIVE(ammoState.missileCam, false)
                            CAM.DESTROY_CAM(ammoState.missileCam, true)
                        end
                        
                        STREAMING.CLEAR_FOCUS()
                        ammoState.missileCam = 0 -- clear handle
                        
                        -- Yield before deleting entity to ensure cam is fully detached/processed
                        Script.Yield()
                        
                        if ENTITY.DOES_ENTITY_EXIST(ammoState.missileEntity) then
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ammoState.missileEntity, true, true)
                            local ptr = Memory.AllocInt()
                            Memory.WriteInt(ptr, ammoState.missileEntity)
                            ENTITY.DELETE_ENTITY(ptr)
                            Memory.Free(ptr)
                        end
                        ammoState.missileEntity = 0
                    end)
                end)
            end
        end
    end)
    
    if not success then
        print("MissileGun Error: " .. tostring(err))
    end
end


-- ============================================
-- MENU CLASS
-- ============================================

function WeaponAmmoModifierMenu.new()
    -- Sync states before building menu
    SyncStates()
    local self = setmetatable(Submenu.new("Ammo modifiers"), WeaponAmmoModifierMenu)
    return self
end

function WeaponAmmoModifierMenu:Init()
    -- Impact ammo with type selection
    self:AddOption(ScrollOption.new(ScrollOption.Type.TOGGLE, "Impact ammo")
        :AddToggleRef(ammoState, "impactAmmo")
        :AddScroll(impactNames, 1)
        :AddIndexRef(ammoState, "impactAmmoType")
        :AddTooltip("Different effects on bullet impact, not my fault if you go get yourself banned with the money gun")
        :AddHotkey())
    
    -- Particle ammo with type selection
    self:AddOption(ScrollOption.new(ScrollOption.Type.TOGGLE, "Particle ammo")
        :AddToggleRef(ammoState, "particleAmmo")
        :AddScroll(particleNames, 1)
        :AddIndexRef(ammoState, "particleAmmoType")
        :AddTooltip("Spawn particles on bullet impact")
        :AddHotkey())
    
    -- Modify ammo with type selection
    self:AddOption(ScrollOption.new(ScrollOption.Type.TOGGLE, "Modify ammo")
        :AddToggleRef(ammoState, "modifyAmmo")
        :AddScroll(modifyAmmoNames, 1)
        :AddIndexRef(ammoState, "modifyAmmoType")
        :AddTooltip("Shoot different projectile types")
        :AddHotkey())
    
    -- Shoot options section
    self:AddOption(BreakOption.new("Shoot Options"))
    
    self:AddOption(ToggleOption.new("Explosive whale gun")
        :AddToggleRef(ammoState, "explosiveWhaleGun")
        :AddTooltip("Explosive whale gun")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Missile gun")
        :AddToggleRef(ammoState, "missileGun")
        :AddTooltip("Shoot missiles")
        :AddHotkey())

    self:AddOption(ToggleOption.new("Disable missile gun timeout")
        :AddRequirement(function() return ammoState.missileGun end)
        :AddToggleRef(ammoState, "missileGunNoTimeLimit")
        :AddTooltip("This will disable the missile gun timeout and allow it to fly indefinitely")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Paint vehicle gun")
        :AddToggleRef(ammoState, "paintVehicleGun")
        :AddTooltip("Paint vehicles you shoot at")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Explosive bullets")
        :AddToggleRef(ammoState, "explosiveBullets")
        :AddTooltip("Explosion where you shoot")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Fire bullets")
        :AddToggleRef(ammoState, "fireBullets")
        :AddTooltip("Fire on entities you shoot")
        :AddHotkey())
    
    -- These use Cherax's built-in FeatureMgr
    self:AddOption(ToggleOption.new("Delete gun")
        :AddToggleRef(ammoState, "deleteGun")
        :AddFunction(function()
            local feature = FeatureMgr.GetFeatureByName("Delete Gun")
            if feature then feature:Toggle(ammoState.deleteGun) end
        end)
        :AddTooltip("Delete entities you shoot")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Drive it gun")
        :AddToggleRef(ammoState, "driveItGun")
        :AddFunction(function()
            local feature = FeatureMgr.GetFeatureByName("Drive Gun")
            if feature then feature:Toggle(ammoState.driveItGun) end
        end)
        :AddTooltip("Drive the vehicle you shoot")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Shrink ray")
        :AddToggleRef(ammoState, "shrinkRay")
        :AddFunction(function()
            local feature = FeatureMgr.GetFeatureByName("Shrink Gun")
            if feature then feature:Toggle(ammoState.shrinkRay) end
            if ammoState.shrinkRay then
                WEAPON.GIVE_WEAPON_TO_PED(GetPlayerPed(), 0x3656C8C1, -1, false, true)
            end
        end)
        :AddTooltip("Shrink peds")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Ped defibrillator")
        :AddToggleRef(ammoState, "pedDefibrillator")
        :AddFunction(function()
            local feature = FeatureMgr.GetFeatureByName("Revive Gun")
            if feature then feature:Toggle(ammoState.pedDefibrillator) end
            if ammoState.pedDefibrillator then
                WEAPON.GIVE_WEAPON_TO_PED(GetPlayerPed(), 0x3656C8C1, -1, false, true)
            end
        end)
        :AddTooltip("Revive peds")
        :AddHotkey())
    
    self:AddOption(ToggleOption.new("Model change gun")
        :AddToggleRef(ammoState, "modelChangeGun")
        :AddFunction(function()
            local feature = FeatureMgr.GetFeatureByName("Soul Switch Gun")
            if feature then feature:Toggle(ammoState.modelChangeGun) end
        end)
        :AddTooltip("Model change gun")
        :AddHotkey())
end

--- Feature update - called every frame
function WeaponAmmoModifierMenu:FeatureUpdate()
    if ammoState.impactAmmo then ImpactAmmo() end
    if ammoState.particleAmmo then ParticleAmmo() end
    if ammoState.modifyAmmo then ModifyAmmo() end
    if ammoState.missileGun then MissileGun() end
    if ammoState.explosiveWhaleGun then ExplosiveWhaleGun() end
    if ammoState.explosiveBullets then ExplosiveBullets() end
    if ammoState.fireBullets then FireBullets() end
    if ammoState.paintVehicleGun then PaintVehicleGun() end
    -- modelChangeGun is handled by FeatureMgr (Soul Switch Gun)
end

return WeaponAmmoModifierMenu
