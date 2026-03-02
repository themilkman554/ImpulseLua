--[[
    Impulse Lua - Vehicle Particles Menu
    Port of vehicleParticlesMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local ParticlesMenu = setmetatable({}, { __index = Submenu })
ParticlesMenu.__index = ParticlesMenu

local instance = nil

-- Particle effects list
local particleEffects = {
    { name = "Firework Burst", asset = "proj_xmas_firework", effect = "scr_firework_xmas_burst_rgw" },
    { name = "Firework Trailburst", asset = "scr_indep_fireworks", effect = "scr_indep_firework_trailburst" },
    { name = "Firework Shotburst", asset = "scr_indep_fireworks", effect = "scr_indep_firework_shotburst" },
    { name = "Firework Fountain", asset = "scr_indep_fireworks", effect = "scr_indep_firework_fountain" },
    { name = "Firework Starburst", asset = "scr_indep_fireworks", effect = "scr_indep_firework_starburst" },
    { name = "Wheel Burnout", asset = "scr_carsteal4", effect = "scr_carsteal4_wheel_burnout" },
    { name = "Truck Crash", asset = "scr_fbi4", effect = "scr_fbi4_trucks_crash" },
    { name = "Clown Appears", asset = "scr_rcbarry2", effect = "scr_clown_appears" },
    { name = "Water Splash", asset = "scr_fbi5a", effect = "scr_fbi5_ped_water_splash" },
    { name = "Trailer Splash", asset = "scr_trevor1", effect = "scr_trev1_trailer_splash" },
    { name = "Blood Impact", asset = "scr_solomon3", effect = "scr_trev4_747_blood_impact" },
    { name = "Car Impact", asset = "scr_exile2", effect = "scr_ex2_car_impact" },
    { name = "Muzzle Flash", asset = "scr_carsteal4", effect = "scr_carsteal5_car_muzzle_flash" },
    { name = "Alien Disintegrate", asset = "scr_rcbarry1", effect = "scr_alien_disintegrate" },
    { name = "Alien Teleport", asset = "scr_rcbarry1", effect = "scr_alien_teleport" },
    { name = "Electric Sparks", asset = "scr_fbi3", effect = "scr_fbi3_elec_sparks" },
    { name = "Dust Cloud", asset = "scr_mp_creator", effect = "scr_mp_dust_cloud" },
    { name = "Clown Death", asset = "scr_rcbarry2", effect = "scr_clown_death" },
}

local vars = {
    enabled = false,
    particleType = 1,
    size = 1.0,
    frontLeft = false,
    frontRight = false,
    rearLeft = false,
    rearRight = false,
    exhaust = false
}

-- Helper: Check if player is in vehicle
local function IsInVehicle()
    local ped = PLAYER.PLAYER_PED_ID()
    return PED.IS_PED_IN_ANY_VEHICLE(ped, false)
end

-- Helper: Get current vehicle
local function GetCurrentVehicle()
    local ped = PLAYER.PLAYER_PED_ID()
    return PED.GET_VEHICLE_PED_IS_IN(ped, false)
end

-- Spawn particle at bone
local function SpawnParticleAtBone(vehicle, boneName)
    local effect = particleEffects[vars.particleType]
    if not effect then return end
    
    local boneIndex = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(vehicle, boneName)
    if boneIndex == -1 then return end
    
    local coords = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(vehicle, boneIndex)
    
    STREAMING.REQUEST_NAMED_PTFX_ASSET(effect.asset)
    if STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) then
        GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
        GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
            effect.effect, coords.x, coords.y, coords.z, 
            0, 0, 0, vars.size, false, false, false, false
        )
    end
end

-- Update particles
local function UpdateParticles()
    if not IsInVehicle() then return end
    local veh = GetCurrentVehicle()
    
    if vars.frontLeft then
        SpawnParticleAtBone(veh, "wheel_lf")
    end
    
    if vars.frontRight then
        SpawnParticleAtBone(veh, "wheel_rf")
    end
    
    if vars.rearLeft then
        SpawnParticleAtBone(veh, "wheel_lr")
    end
    
    if vars.rearRight then
        SpawnParticleAtBone(veh, "wheel_rr")
    end
    
    if vars.exhaust then
        SpawnParticleAtBone(veh, "exhaust")
        for i = 1, 15 do
            SpawnParticleAtBone(veh, "exhaust_" .. i)
        end
    end
end

function ParticlesMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Vehicle particles"), ParticlesMenu)
        instance:Init()
    end
    return instance
end

function ParticlesMenu:Init()
    -- Particle type
    local particleNames = {}
    for i, p in ipairs(particleEffects) do
        particleNames[i] = p.name
    end
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Particle type")
        :AddScroll(particleNames, 1)
        :AddIndexRef(vars, "particleType")
        :AddTooltip("Select particle effect"))
    
    -- Particle size
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Particle size")
        :AddNumberRef(vars, "size", "%.2f", 0.1)
        :AddMin(0.1):AddMax(5)
        :AddTooltip("Set particle size"))
    
    -- Front left wheel
    self:AddOption(ToggleOption.new("Front left wheel")
        :AddToggleRef(vars, "frontLeft")
        :AddTooltip("Spawn particles at front left wheel"))
    
    -- Front right wheel
    self:AddOption(ToggleOption.new("Front right wheel")
        :AddToggleRef(vars, "frontRight")
        :AddTooltip("Spawn particles at front right wheel"))
    
    -- Rear left wheel
    self:AddOption(ToggleOption.new("Rear left wheel")
        :AddToggleRef(vars, "rearLeft")
        :AddTooltip("Spawn particles at rear left wheel"))
    
    -- Rear right wheel
    self:AddOption(ToggleOption.new("Rear right wheel")
        :AddToggleRef(vars, "rearRight")
        :AddTooltip("Spawn particles at rear right wheel"))
    
    -- Exhaust
    self:AddOption(ToggleOption.new("Exhaust")
        :AddToggleRef(vars, "exhaust")
        :AddTooltip("Spawn particles at exhaust"))
    
    -- Enable
    self:AddOption(ToggleOption.new("Enable vehicle particles")
        :AddToggleRef(vars, "enabled")
        :AddTooltip("Enable vehicle particle effects"))
end

-- Timer for particle updates
local particleTimer = 0

function ParticlesMenu:FeatureUpdate()
    if not vars.enabled then return end
    
    local now = MISC.GET_GAME_TIMER()
    if now - particleTimer > 50 then
        particleTimer = now
        UpdateParticles()
    end
end

return ParticlesMenu
