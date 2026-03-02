--[[
    Impulse Lua - Particle Menu
    Port of particleMenu.cpp from Impulse C++
    Particle effects for the player model
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")

---@class ParticleMenu : Submenu
local ParticleMenu = setmetatable({}, { __index = Submenu })
ParticleMenu.__index = ParticleMenu

-- State table for particle options
local particleState = {
    particleManToggle = false,
    particleManType = 1,
    dragonBreath = false,
}

-- Particle man effects data
local particleManEffects = {
    { name = "Light", asset = "scr_rcbarry2", effect = "scr_exp_clown_trails", size = 0.2 },
    { name = "Alien Teleport", asset = "scr_rcbarry1", effect = "scr_alien_teleport", size = 0.2 },
    { name = "Money", asset = "scr_paletoscore", effect = "scr_paleto_banknotes", size = 0.9 },
    { name = "Blood", asset = "scr_solomon3", effect = "scr_trev4_747_blood_impact", size = 0.9 },
    { name = "Alien Disintegrate", asset = "scr_rcbarry1", effect = "scr_alien_disintegrate", size = 0.2 },
    { name = "Electric", asset = "scr_trevor1", effect = "scr_trev1_trailer_boosh", size = 0.2 },
    { name = "Fire", asset = "scr_agencyheist", effect = "scr_fbi_dd_breach_smoke", size = 0.2 },
    { name = "Clown Death", asset = "scr_rcbarry2", effect = "scr_clown_death", size = 0.2 },
    { name = "Clown Appears", asset = "scr_rcbarry2", effect = "scr_clown_appears", size = 0.08 },
    { name = "Flowers", asset = "scr_rcbarry2", effect = "scr_exp_clown", size = 0.08 },
    { name = "Fireworks", asset = "scr_indep_fireworks", effect = "scr_indep_firework_starburst", size = 0.2 },
}

-- Bone IDs for particle man effects
local particleManBones = { 31086, 28422, 60309 }

-- Timers
local timers = {
    dragonBreath = 0,
}

--[[ ============================================
    HELPER FUNCTIONS
============================================ ]]

local function ParticleMan(effect)
    local ped = PLAYER.PLAYER_PED_ID()
    
    -- Request the particle asset
    STREAMING.REQUEST_NAMED_PTFX_ASSET(effect.asset)
    
    -- Check if asset is loaded
    if not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect.asset) then
        return -- Asset not ready yet
    end
    
    -- Spawn particles on each bone
    for _, boneId in ipairs(particleManBones) do
        GRAPHICS.USE_PARTICLE_FX_ASSET(effect.asset)
        GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_PED_BONE(
            effect.effect,
            ped,
            0.0, 0.0, 0.0,  -- offset
            0.0, 0.0, 0.0,  -- rotation
            boneId,
            effect.size,
            false, false, false
        )
    end
end

local function DragonBreath()
    local ped = PLAYER.PLAYER_PED_ID()
    
    -- Request the core particle asset
    STREAMING.REQUEST_NAMED_PTFX_ASSET("core")
    
    -- Check if asset is loaded
    if not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("core") then
        return -- Asset not ready yet
    end
    
    GRAPHICS.USE_PARTICLE_FX_ASSET("core")
    
    -- Spawn flame effect on head bone
    GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_ON_PED_BONE(
        "ent_sht_flame",
        ped,
        0.02, 0.2, 0.0,   -- offset
        90.0, -100.0, 90.0,  -- rotation
        31086,            -- head bone
        1.0,              -- scale
        false, false, false
    )
end

--[[ ============================================
    MENU CREATION
============================================ ]]

function ParticleMenu.new()
    local self = setmetatable(Submenu.new("Particles"), ParticleMenu)
    return self
end

function ParticleMenu:Init()
    -- Particle man (scroll + toggle)
    self:AddOption(ScrollOption.new(ScrollOption.Type.TOGGLE, "Particle man")
        :AddToggleRef(particleState, "particleManToggle")
        :AddScroll(particleManEffects, 1)
        :AddIndexRef(particleState, "particleManType")
        :AddTooltip("Emit particles")
        :AddHotkey())
    
    -- Dragon breath
    self:AddOption(ToggleOption.new("Dragon breath")
        :AddToggleRef(particleState, "dragonBreath")
        :AddTooltip("This will make you spit fire")
        :AddHotkey())
end

--[[ ============================================
    FEATURE UPDATE LOOP (Called every frame)
============================================ ]]

function ParticleMenu:FeatureUpdate()
    local currentTime = MISC.GET_GAME_TIMER()
    
    -- Particle man effect
    if particleState.particleManToggle then
        local effect = particleManEffects[particleState.particleManType]
        if effect then
            ParticleMan(effect)
        end
    end
    
    -- Dragon breath (with timer for performance)
    if particleState.dragonBreath then
        if currentTime - timers.dragonBreath > 200 then
            timers.dragonBreath = currentTime
            DragonBreath()
        end
    end
end

return ParticleMenu
