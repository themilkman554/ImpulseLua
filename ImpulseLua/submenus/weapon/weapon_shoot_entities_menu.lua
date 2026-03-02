--[[
    Impulse Lua - Weapon Shoot Entities Submenu
    Port of weaponShootEntities.cpp from Impulse C++
    Allows shooting entities (Vehicles, Objects, Peds) and Gravity Gun mechanics
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local TriggerOption = require("Impulse/ImpulseLua/lib/options/button")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class WeaponShootEntitiesMenu : Submenu
local WeaponShootEntitiesMenu = setmetatable({}, { __index = Submenu })
WeaponShootEntitiesMenu.__index = WeaponShootEntitiesMenu

-- State
local state = {
    shootEntityType = 1, -- 1: Vehicle, 2: Object, 3: Ped (Lua 1-based)
    shootEntities = false,
    flyinshootvehicles = false, -- Gravity vehicle shooting
    shootdistance = 10.0,
    
    -- Selections
    vehicleVal = 1,
    objectVal = 1,
    pedVal = 1,
    
    -- Runtime
    gravityVehicle = 0
}

-- Lists
local entityTypes = { "Vehicle", "Object", "Ped" }

local vehiclePairs = {
    { name = "Taxi", hash = 0xC703DB5F },
    { name = "Police Cruiser", hash = 0x9F05F101 },
    { name = "Adder", hash = 0xB779A091 },
    { name = "T20", hash = 0x6322B39A },
    { name = "Duke O'Death", hash = 0xEC8F7094 },
    { name = "BMX", hash = 0x43779C54 },
    { name = "Police Predator", hash = 0xE2E7D4AB },
    { name = "Nightshark", hash = 0x19DD9ED1 },
    { name = "Vindicator", hash = 0xAF599F01 },
    { name = "Hot Rod Blazer", hash = 0xB44F0582 },
    { name = "JB 700", hash = 0x3EAB5555 },
    { name = "Titan", hash = 0x761E2AD3 },
    { name = "Airport Bus", hash = 0x4C80EB0E },
    { name = "Freight Train", hash = 0x3D6AAA9B },
    { name = "RM-10 Bombushka", hash = 0xFE0A508C },
    { name = "Skylift", hash = 0x3E48BF23 },
    { name = "Luxor Deluxe", hash = 0xB79F589E },
    { name = "Jet", hash = 0x3F119114 },
    { name = "Cargo Plane", hash = 0x15F27762 },
    { name = "Ambulance", hash = 0x45D56ADA },
    { name = "Roosevelt Valor", hash = 0xDC19D101 },
    { name = "Thruster", hash = 0x58CDAF30 },
    { name = "APC", hash = 0x2189D250 }
}

local objectPairs = {
    { name = "Meteor", hash = 0xDF9841D7 },
    { name = "UFO", hash = 0xB467C540 },
    { name = "Ferris Wheel", hash = 0xC42C019A },
    { name = "Large Xmas Tree", hash = 0x7121AC4 },
    { name = "Covered Cheetah", hash = 0x37D80B0E },
    { name = "Weed Pallet", hash = 0xE8032E4 },
    { name = "Burger Stand", hash = 0x434BFB7C },
    { name = "Crashed Heli", hash = 0x8E8C7A5B },
    { name = "Beer Neon", hash = 0x5571173D },
    { name = "Le Barge", hash = 0x8AF58425 },
    { name = "Flat TV", hash = 0x3DC31836 },
    { name = "Beach Fire", hash = 0xC079B265 },
    { name = "Space Pistol", hash = 0xBD8AE007 },
    { name = "Toilet", hash = 0x6F9939C7 },
    { name = "Wheelchair", hash = 0x4B3D240F },
    { name = "Road Cone", hash = 0xE0264F5D },
    { name = "Alien Egg", hash = 0x6B795EBC },
    { name = "Katana", hash = 0xE2BA016F },
    { name = "Car Seat", hash = 0x52660DBB },
    { name = "Gold Bar", hash = 0xF046EA37 },
    { name = "JB700 Covered", hash = 0x72F54E90 },
    { name = "Guitar", hash = 0x369D8410 },
    { name = "Lawnmower", hash = 0x1AB39621 },
    { name = "Bucket", hash = 0x29E362FF },
    { name = "Haybail", hash = 0x5411322E },
    { name = "Safe", hash = 0x40F52369 }
}

local pedPairs = {
    { name = "Movspace", hash = 0xE7B31432 },
    { name = "Imporage", hash = 0x348065F5 },
    { name = "Rs Ranger", hash = 0x3C438CD2 },
    { name = "Justin", hash = 0x7DC3908F },
    { name = "Mani", hash = 0xC8BB1E52 },
    { name = "Michael", hash = 0xD7114C9 },
    { name = "Franklin", hash = 0x9B22DBAF },
    { name = "Trevor", hash = 0x9B810FA2 },
    { name = "Boar", hash = 0xCE5FF074 },
    { name = "Chimp", hash = 0xA8683715 },
    { name = "Cow", hash = 0xFCFA9E1E },
    { name = "Coyote", hash = 0x644AC75E },
    { name = "Deer", hash = 0xD86B5A95 },
    { name = "Fish", hash = 0x2FD800B7 },
    { name = "Hen", hash = 0x6AF51FAF },
    { name = "Cat", hash = 0x573201B8 },
    { name = "Hawk", hash = 0xAAB71F62 },
    { name = "Cormorant", hash = 0x56E29962 },
    { name = "Crow", hash = 0x18012A9F },
    { name = "Dolphin", hash = 0x8BBAB455 },
    { name = "Humpback", hash = 0x471BE4B2 },
    { name = "Whale", hash = 0x8D8AC8B9 },
    { name = "Pigeon", hash = 0x6A20728 },
    { name = "Seagull", hash = 0xD3939DFD },
    { name = "Sharkhammer", hash = 0x3C831724 },
    { name = "Pig", hash = 0xB11BAB56 },
    { name = "Rat", hash = 0xC3B52966 },
    { name = "Rhesus", hash = 0xC2D06F53 },
    { name = "Chop", hash = 0x14EC17EA },
    { name = "Husky", hash = 0x4E8F95A2 },
    { name = "Mtlion", hash = 0x1250D7BA },
    { name = "Retriever", hash = 0x349F33E1 },
    { name = "Sharktiger", hash = 0x6C3F072 },
    { name = "Shepherd", hash = 0x431FC24C },
    { name = "Alien", hash = 0x64611296 },
    { name = "Beach", hash = 0x303638A7 },
    { name = "Bevhills", hash = 0xBE086EFD },
    { name = "Bevhills", hash = 0xA039335F },
    { name = "Bodybuild", hash = 0x3BD99114 },
    { name = "Business", hash = 0x1FC37DBC },
    { name = "Downtown", hash = 0x654AD86E },
    { name = "Eastsa", hash = 0x9D3DCB7A },
    { name = "Eastsa", hash = 0x63C8D891 },
    { name = "Fatbla", hash = 0xFAB48BCB },
    { name = "Fatcult", hash = 0xB5CF80E4 },
    { name = "Fatwhite", hash = 0x38BAD33B },
    { name = "Ktown", hash = 0x52C824DE },
    { name = "Ktown", hash = 0x41018151 },
    { name = "Prolhost", hash = 0x169BD1E1 },
    { name = "Salton", hash = 0xDE0E0969 },
    { name = "Skidrow", hash = 0xB097523B },
    { name = "Soucentmc", hash = 0xCDE955D2 },
    { name = "Soucent", hash = 0x745855A1 },
    { name = "Soucent", hash = 0xF322D338 },
    { name = "Tourist", hash = 0x505603B9 },
    { name = "Trampbeac", hash = 0x8CA0C266 },
    { name = "Tramp", hash = 0x48F96F5B },
    { name = "Genstreet", hash = 0x61C81C85 },
    { name = "Indian", hash = 0xBAD7BB80 },
    { name = "Ktown", hash = 0x47CF5E96 },
    { name = "Salton", hash = 0xCCFF7D8A },
    { name = "Soucent", hash = 0x3DFA1830 },
    { name = "Soucent", hash = 0xA56DE716 },
    { name = "Beach", hash = 0xC79F6928 }
}

-- Helpers for Scroll Options
local vehicleNames = {}
for i,v in ipairs(vehiclePairs) do vehicleNames[i] = v.name end

local objectNames = {}
for i,v in ipairs(objectPairs) do objectNames[i] = v.name end

local pedNames = {}
for i,v in ipairs(pedPairs) do pedNames[i] = v.name end

-- ============================================
-- HELPERS
-- ============================================

local function RotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))
    return {
        x = -math.sin(z) * num,
        y = math.cos(z) * num,
        z = math.sin(x)
    }
end

local function GetPlayerPed()
    return PLAYER.PLAYER_PED_ID()
end

local function RequestControl(entity)
    if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
    end
end

-- ============================================
-- LOGIC
-- ============================================

local function GravityShootGun()
    if not state.flyinshootvehicles then return end
    
    local ped = GetPlayerPed()
    
    -- Check if aiming
    if not PED.GET_PED_CONFIG_FLAG(ped, 78, true) then -- 78: PED_FLAG_IS_AIMING? Using native check better?
        -- Fallback to standard check if flag is unsure
        if not PAD.IS_CONTROL_PRESSED(0, 25) then -- Right Click / Aim
            -- If not aiming, delete held vehicle
            if state.gravityVehicle ~= 0 and ENTITY.DOES_ENTITY_EXIST(state.gravityVehicle) then
                 Script.QueueJob(function()
                    local veh = state.gravityVehicle
                    RequestControl(veh)
                    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(veh, true, true)
                    ENTITY.DELETE_ENTITY(veh)
                    state.gravityVehicle = 0
                 end)
            end
            state.gravityVehicle = 0
            return 
        end
    end
    
    Script.QueueJob(function()
        local camRot = CAM.GET_GAMEPLAY_CAM_ROT(2)
        local dir = RotationToDirection(camRot)
        local camCoord = CAM.GET_GAMEPLAY_CAM_COORD()
        local myPos = ENTITY.GET_ENTITY_COORDS(ped, true)
        
        -- Target Position in front of camera
        local targetPos = {
            x = camCoord.x + dir.x * state.shootdistance,
            y = camCoord.y + dir.y * state.shootdistance,
            z = camCoord.z + dir.z * state.shootdistance
        }

        if state.gravityVehicle == 0 or not ENTITY.DOES_ENTITY_EXIST(state.gravityVehicle) then
            -- Spawn
            local hash = vehiclePairs[state.vehicleVal].hash
            STREAMING.REQUEST_MODEL(hash)
            if STREAMING.HAS_MODEL_LOADED(hash) then
                -- Spawn at player pos + offset to avoid collision issues initially
                state.gravityVehicle = GTA.SpawnVehicle(hash, myPos.x, myPos.y, myPos.z + 5.0, 0.0, true, true)
                STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
            end
        else
            -- Update Position
            local veh = state.gravityVehicle
            RequestControl(veh)
            
            local currPos = ENTITY.GET_ENTITY_COORDS(veh, false)
            
            -- Calculate force to move towards target
            local force = {
                x = (targetPos.x - currPos.x) * 4.0,
                y = (targetPos.y - currPos.y) * 4.0,
                z = (targetPos.z - currPos.z) * 4.0
            }
            
            ENTITY.SET_ENTITY_VELOCITY(veh, force.x, force.y, force.z)
            ENTITY.SET_ENTITY_ROTATION(veh, 0.0, 0.0, camRot.z, 2, true)
            
            -- Shoot
            if PED.IS_PED_SHOOTING(ped) then
                -- Launch it
                local offset = ENTITY.GET_OFFSET_FROM_ENTITY_GIVEN_WORLD_COORDS(veh, myPos.x, myPos.y, myPos.z)
                -- Using logic from C++: -Offset * fabs(100 / Offset) ??
                -- Simplified: Just use Camera Direction * Force
                ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, dir.x * 2000.0, dir.y * 2000.0, dir.z * 2000.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                
                -- Release
                state.gravityVehicle = 0 
                -- We set to 0 so next frame we spawn a new one
            end
        end
    end)
end

local lastShootTime = 0

local function ShootEntities()
    print("[ShootEntities] Called, state.shootEntities = " .. tostring(state.shootEntities)) -- DEBUG
    if not state.shootEntities then return end
    
    local ped = GetPlayerPed()
    local isShooting = PED.IS_PED_SHOOTING(ped)
    print("[ShootEntities] IS_PED_SHOOTING = " .. tostring(isShooting)) -- DEBUG
    if not isShooting then return end
    
    local currentTime = MISC.GET_GAME_TIMER()
    if currentTime - lastShootTime < 100 then return end
    lastShootTime = currentTime
    
    print("[ShootEntities] Passed throttle, entering job") -- DEBUG
    
    Script.QueueJob(function()
        local hash = 0
        local type = state.shootEntityType
        
        if type == 1 then hash = vehiclePairs[state.vehicleVal].hash
        elseif type == 2 then hash = objectPairs[state.objectVal].hash
        elseif type == 3 then hash = pedPairs[state.pedVal].hash
        end
        
        print("[ShootEntities] Hash = " .. tostring(hash)) -- DEBUG
        
        STREAMING.REQUEST_MODEL(hash)
        if not STREAMING.HAS_MODEL_LOADED(hash) then 
            print("[ShootEntities] Model not loaded, exiting") -- DEBUG
            return 
        end
        
        print("[ShootEntities] Model loaded, spawning...") -- DEBUG
        
        local camRot = CAM.GET_GAMEPLAY_CAM_ROT(0)
        local camCoord = CAM.GET_GAMEPLAY_CAM_COORD()
        
        local pitch = math.rad(camRot.x)
        local yaw = math.rad(camRot.z)
        
        local dirX = -math.sin(yaw) * math.cos(pitch)
        local dirY = math.cos(yaw) * math.cos(pitch)
        local dirZ = math.sin(pitch)
        
        local spawnPos = {
            x = camCoord.x + (dirX * 10),
            y = camCoord.y + (dirY * 10),
            z = camCoord.z + (dirZ * 10)
        }
        
        local handle = 0
        if type == 1 then
            handle = GTA.SpawnVehicle(hash, spawnPos.x, spawnPos.y, spawnPos.z, camRot.z, true, true)
        elseif type == 2 then
            handle = GTA.CreateObject(hash, spawnPos.x, spawnPos.y, spawnPos.z, true, true)
        elseif type == 3 then
            handle = GTA.CreatePed(hash, 26, spawnPos.x, spawnPos.y, spawnPos.z, camRot.z, true, true)
        end
        
        print("[ShootEntities] Handle = " .. tostring(handle)) -- DEBUG
        
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
        
        if handle ~= 0 then
            ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(ped, handle, true)
            ENTITY.SET_ENTITY_RECORDS_COLLISIONS(handle, true)
            
            if type == 1 then
                VEHICLE.SET_VEHICLE_OUT_OF_CONTROL(handle, false, false)
            end
            
            -- Launch loop matching ExplosiveWhaleGun
            for i = 1, 75 do
                if not ENTITY.DOES_ENTITY_EXIST(handle) then break end
                if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(handle) then break end
                
                -- Apply force each frame
                -- ExplosiveWhaleGun uses * 10, but that's for a ped. 
                -- C++ used * 850 for generic entities. 
                -- I'll use a balanced value or standard * 50? 
                -- User said "do it like that" (ExplosiveWhaleGun).
                -- WhaleGun uses dir * 10.
                -- Let's try dir * 50 to ensure visible speed for heavier objects.
                ENTITY.APPLY_FORCE_TO_ENTITY(handle, 1, dirX * 50.0, dirY * 50.0, dirZ * 50.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                Script.Yield()
            end
            
            -- Cleanup on impact/timeout
             if ENTITY.DOES_ENTITY_EXIST(handle) then
                ENTITY.SET_ENTITY_AS_MISSION_ENTITY(handle, true, true)
                ENTITY.DELETE_ENTITY(handle)
            end
        end
    end)
end


-- ============================================
-- SUBMENU
-- ============================================

local instance = nil

function WeaponShootEntitiesMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Shoot entities"), WeaponShootEntitiesMenu)
        instance:Init()
    end
    return instance
end

function WeaponShootEntitiesMenu:Init()
    -- Entity Type Selection
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Entity type")
        :AddScroll(entityTypes, 1)
        :AddFunction(function() state.shootEntityType = self.options[1]:GetIndex() end) -- Sync selection
        :AddOnUpdate(function(opt) state.shootEntityType = opt:GetIndex() end) -- Keep synced?
        -- Actually, internal index is updated. We just need to read it.
        -- AddFunction is for "On Access/Change". 
        -- If it's SCROLL type, OnLeft/OnRight calls callback.
        -- So AddFunction serves as the change callback.
        :AddFunction(function() state.shootEntityType = self.options[1]:GetIndex() end)
    )
    
    -- Standard Shoot Entities Toggle
    self:AddOption(ToggleOption.new("Enable entity shooting")
        :AddToggleRef(state, "shootEntities")
        :AddRequirement(function() return not state.flyinshootvehicles end)
        :AddTooltip("Enable entity shooting")
    )
    
    -- Gravity Options (Only for Vehicles)
    self:AddOption(ToggleOption.new("Enable gravity vehicle shooting")
        :AddToggleRef(state, "flyinshootvehicles")
        :AddRequirement(function() return not state.shootEntities and state.shootEntityType == 1 end)
        :AddTooltip("Enable entity shooting with gravity")
    )
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Gravity vehicle distance")
        :SetNumber(state, "shootdistance")
        :SetFormat("%.1f")
        :SetStep(1.0)
        :AddMin(0.0)
        :AddMax(50.0)
        :AddTooltip("Control the distance between you and the gravity vehicle")
    )
    
    -- Dynamic Options (Vehicle/Object/Ped) based on selection
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Vehicle")
        :AddScroll(vehicleNames, 1)
        :AddFunction(function() state.vehicleVal = self.options[5]:GetIndex() end)
        :AddRequirement(function() return state.shootEntityType == 1 end)
    )

    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Object")
        :AddScroll(objectNames, 1)
        :AddFunction(function() state.objectVal = self.options[6]:GetIndex() end)
        :AddRequirement(function() return state.shootEntityType == 2 end)
    )
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Ped")
        :AddScroll(pedNames, 1)
        :AddFunction(function() state.pedVal = self.options[7]:GetIndex() end)
        :AddRequirement(function() return state.shootEntityType == 3 end)
    )
end

function WeaponShootEntitiesMenu:FeatureUpdate()
    if state.flyinshootvehicles then
        GravityShootGun()
    end
    
    if state.shootEntities then
        ShootEntities()
    end
end

return WeaponShootEntitiesMenu
