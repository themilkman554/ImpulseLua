
local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")


local SentryMenu = setmetatable({}, { __index = Submenu })
SentryMenu.__index = SentryMenu

local instance = nil

local vars = {
    turretExcludeMe = false,
    turretWeaponSelection = 1,
    turretTargetSelection = 1,
    turretRange = 600.0,
    turretAttachSelection = 1,
    vehicleGodMode = false,
}

local turretAttachOptions = {
    { name = "Not", value = 0 },
    { name = "Self", value = 1 },
    { name = "Vehicle", value = 2 }
}

local turretWeapons = {
    { name = "RPG", value = Utils.Joaat("WEAPON_RPG") },
    { name = "Assault Shotgun", value = Utils.Joaat("WEAPON_ASSAULTSHOTGUN") },
    { name = "Snowball", value = Utils.Joaat("WEAPON_SNOWBALL") },
    { name = "Railgun", value = Utils.Joaat("WEAPON_RAILGUN") },
    { name = "Air Defence", value = Utils.Joaat("WEAPON_AIR_DEFENCE_GUN") }
}

local turretAimTypes = {
    { name = "Vehicles", value = 0 },
    { name = "Players", value = 1 },
    { name = "Peds", value = 2 },
    { name = "Aircraft", value = 4 },
    { name = "Everything", value = 3 }
}

local Turrets = {}

local function GetLocalPed()
    return PLAYER.PLAYER_PED_ID()
end

local function GetLocalCoords()
    return ENTITY.GET_ENTITY_COORDS(GetLocalPed(), true)
end

local function SpawnTurret()
    Script.QueueJob(function()
        local attachType = turretAttachOptions[vars.turretAttachSelection].value
        local turret = {
            Populated = true,
            ExcludeSelf = vars.turretExcludeMe,
            ID = 0,
            Minigun = 0,
            Type = turretAimTypes[vars.turretTargetSelection].value,
            TurrentPed = 0,
            Weapon = turretWeapons[vars.turretWeaponSelection].value,
            OnGround = (attachType == 0),
            TurrentCooldown = 0,
            AttachType = attachType,
            Parent = 0
        }
        
        local telescopeHash = 0x3250D9D6
        local minigunHash = 0xC89630B8
        
        STREAMING.REQUEST_MODEL(telescopeHash)
        STREAMING.REQUEST_MODEL(minigunHash)
        WEAPON.REQUEST_WEAPON_ASSET(turret.Weapon, 31, 0)
        
        local timeout = 0
        while (not STREAMING.HAS_MODEL_LOADED(telescopeHash) or not STREAMING.HAS_MODEL_LOADED(minigunHash) or not WEAPON.HAS_WEAPON_ASSET_LOADED(turret.Weapon)) and timeout < 100 do
            Script.Yield()
            timeout = timeout + 1
        end
        
        local ped = GetLocalPed()
        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0, 1, 0)
        
        turret.ID = GTA.CreateObject(telescopeHash, pos.x, pos.y, pos.z, true, true)
        turret.Minigun = GTA.CreateObject(minigunHash, pos.x, pos.y, pos.z, true, true)
        
        ENTITY.ATTACH_ENTITY_TO_ENTITY(turret.Minigun, turret.ID, 0, 0.0, 0.3, 1.6, 0.0, 0.0, 90.0, true, true, true, false, 2, true)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(turret.Minigun, turret.ID, 0, 0.0, 0.3, 1.6, 0.0, 0.0, 90.0, true, true, true, false, 2, true)
        
        if attachType == 1 then -- Self
            turret.Parent = ped
            ENTITY.ATTACH_ENTITY_TO_ENTITY(turret.ID, ped, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        elseif attachType == 2 then -- Vehicle
            local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
            if veh ~= 0 then
                turret.Parent = veh
                ENTITY.ATTACH_ENTITY_TO_ENTITY(turret.ID, veh, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            else
                turret.AttachType = 0
                turret.OnGround = true
                ENTITY.SET_ENTITY_HEADING(turret.ID, ENTITY.GET_ENTITY_HEADING(ped))
            end
        else
            ENTITY.SET_ENTITY_HEADING(turret.ID, ENTITY.GET_ENTITY_HEADING(ped))
        end
        
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(telescopeHash)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(minigunHash)
        
        table.insert(Turrets, turret)
    end)
end

function SentryMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Sentry"), SentryMenu)
        instance:Init()
    end
    return instance
end

function SentryMenu.GetSpawnedTurrets()
    return Turrets
end

function SentryMenu.SetSpawnedTurrets(tbl)
    Turrets = tbl
end

function SentryMenu:Init()
    local SentryEditorMenu = require("Impulse/ImpulseLua/submenus/world/sentry_editor_menu")

    self:AddOption(SubmenuOption.new("Edit spawned sentrys")
        :AddSubmenu(SentryEditorMenu.GetInstance())
        :AddTooltip("Edit spawned sentrys"))

    self:AddOption(ToggleOption.new("Vehicle God Mode")
        :AddToggleRef(vars, "vehicleGodMode")
        :AddFunction(function() 
            FeatureMgr.GetFeatureByName("Vehicle God Mode"):Toggle(vars.vehicleGodMode)
        end)
        :AddTooltip("Toggle vehicle god mode")
        :SetDonor())

    self:AddOption(ToggleOption.new("Exclude me (next spawn)")
        :AddToggle(vars.turretExcludeMe)
        :AddFunction(function(val) vars.turretExcludeMe = val end)
        :AddTooltip("Exclude me from the turret aiming system (on the next turret)")
        :SetDonor())
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Weapon selection")
        :AddScroll(turretWeapons, 1)
        :AddIndexRef(vars, "turretWeaponSelection")
        :AddTooltip("Select the weapon the turret you spawn next will use")
        :SetDonor())

    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Target")
        :AddScroll(turretAimTypes, 1)
        :AddIndexRef(vars, "turretTargetSelection")
        :AddTooltip("Select the target the turret you spawn next will aim at")
        :SetDonor())

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Range")
        :AddNumberRef(vars, "turretRange", "%.1f", 10.0)
        :AddMin(0.0):AddMax(2000.0)
        :AddTooltip("Control the range of the turret")
        :SetDonor())

    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Attach")
        :AddScroll(turretAttachOptions, 1)
        :AddIndexRef(vars, "turretAttachSelection")
        :AddTooltip("Attach the sentry to yourself or your vehicle")
        :SetDonor())

    self:AddOption(ButtonOption.new("Spawn turret on current position")
        :AddFunction(function() SpawnTurret() end)
        :AddTooltip("Spawn a turret where your character is")
        :AddHotkey()
        :SetDonor())
end

function SentryMenu:FeatureUpdate()
    if #Turrets > 0 then
        for i = #Turrets, 1, -1 do
            local turret = Turrets[i]
            if ENTITY.DOES_ENTITY_EXIST(turret.ID) then
                local coords = ENTITY.GET_ENTITY_COORDS(turret.ID, false)
                local target = 0
                local closestDistance = 99999.0
                
                -- Place on ground
                if turret.OnGround then
                    ENTITY.SET_ENTITY_COORDS(turret.ID, coords.x, coords.y, coords.z - 1, false, true, true, false)
                    turret.OnGround = false
                end
                
                -- Create hidden ped for turret (required for shooting)
                if turret.TurrentPed == 0 then
                    local rela = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(turret.ID, 0, 0, -3)
                    local pedHash = MISC.GET_HASH_KEY("a_f_y_skater_01")
                    STREAMING.REQUEST_MODEL(pedHash)
                    local timeout = 0
                    while not STREAMING.HAS_MODEL_LOADED(pedHash) and timeout < 50 do
                        Script.Yield()
                        timeout = timeout + 1
                    end
                    local ped = GTA.CreatePed(pedHash, 21, rela.x, rela.y, rela.z, ENTITY.GET_ENTITY_HEADING(GetLocalPed()), true, false)
                    if ENTITY.DOES_ENTITY_EXIST(ped) then
                        ENTITY.SET_ENTITY_INVINCIBLE(ped, true)
                        ENTITY.SET_ENTITY_VISIBLE(ped, false, false)
                        ENTITY.SET_ENTITY_COLLISION(ped, false, false)
                        ENTITY.FREEZE_ENTITY_POSITION(ped, true)
                        turret.TurrentPed = ped
                    end
                else
                    -- Find target based on type
                    local targetType = turret.Type
                    local myPed = GetLocalPed()
                    local myVeh = PED.GET_VEHICLE_PED_IS_IN(myPed, false)
                    
                    -- Type 0 = Vehicles, Type 3 = Everything (includes vehicles)
                    if targetType == 0 or targetType == 3 then
                        -- Find nearest vehicle using PoolMgr
                        local vehCount = PoolMgr.GetCurrentVehicleCount()
                        for v = 0, vehCount - 1 do
                            local veh = PoolMgr.GetVehicle(v)
                            if veh and veh ~= 0 and ENTITY.DOES_ENTITY_EXIST(veh) then
                                -- Skip self vehicle and parent (attached) vehicle
                                if veh ~= myVeh and veh ~= turret.Parent then
                                    local vehCoords = ENTITY.GET_ENTITY_COORDS(veh, false)
                                    local dist = MISC.GET_DISTANCE_BETWEEN_COORDS(coords.x, coords.y, coords.z, vehCoords.x, vehCoords.y, vehCoords.z, false)
                                    if dist < closestDistance and dist < vars.turretRange then
                                        target = veh
                                        closestDistance = dist
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Type 1 = Players, Type 3 = Everything (includes players)
                    if targetType == 1 or targetType == 3 then
                        local nearestPlayer = ENTITY.GET_NEAREST_PLAYER_TO_ENTITY(turret.ID)
                        if nearestPlayer ~= -1 then
                            local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(nearestPlayer)
                            if ENTITY.DOES_ENTITY_EXIST(playerPed) and not ENTITY.IS_ENTITY_DEAD(playerPed, false) then
                                -- Skip self if exclude self is enabled
                                if not (turret.ExcludeSelf and playerPed == myPed) then
                                    local playerCoords = ENTITY.GET_ENTITY_COORDS(playerPed, false)
                                    local dist = MISC.GET_DISTANCE_BETWEEN_COORDS(coords.x, coords.y, coords.z, playerCoords.x, playerCoords.y, playerCoords.z, false)
                                    if dist < closestDistance and dist < vars.turretRange then
                                        target = playerPed
                                        closestDistance = dist
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Type 2 = Peds, Type 3 = Everything (includes peds)
                    if targetType == 2 or targetType == 3 then
                        -- Find nearest ped using PoolMgr
                        local pedCount = PoolMgr.GetCurrentPedCount()
                        for p = 0, pedCount - 1 do
                            local ped = PoolMgr.GetPed(p)
                            if ped and ped ~= 0 and ENTITY.DOES_ENTITY_EXIST(ped) and not ENTITY.IS_ENTITY_DEAD(ped, false) then
                                -- Skip self, turret ped, and players (handled separately)
                                if ped ~= myPed and ped ~= turret.TurrentPed and not PED.IS_PED_A_PLAYER(ped) then
                                    if not (turret.ExcludeSelf and ped == myPed) then
                                        local pedCoords = ENTITY.GET_ENTITY_COORDS(ped, false)
                                        local dist = MISC.GET_DISTANCE_BETWEEN_COORDS(coords.x, coords.y, coords.z, pedCoords.x, pedCoords.y, pedCoords.z, false)
                                        if dist < closestDistance and dist < vars.turretRange then
                                            target = ped
                                            closestDistance = dist
                                        end
                                    end
                                end
                            end
                        end
                    
                    end

                    -- Type 4 = Aircraft, Type 3 = Everything (includes aircraft)
                    if targetType == 4 or targetType == 3 then
                        -- Find nearest aircraft using PoolMgr
                        local vehCount = PoolMgr.GetCurrentVehicleCount()
                        for v = 0, vehCount - 1 do
                            local veh = PoolMgr.GetVehicle(v)
                            if veh and veh ~= 0 and ENTITY.DOES_ENTITY_EXIST(veh) then
                                local vehHash = ENTITY.GET_ENTITY_MODEL(veh)
                                local isPlane = VEHICLE.IS_THIS_MODEL_A_PLANE(vehHash)
                                local isHeli = VEHICLE.IS_THIS_MODEL_A_HELI(vehHash)
                                
                                if isPlane or isHeli then
                                    -- Skip self vehicle and parent (attached) vehicle
                                    if veh ~= myVeh and veh ~= turret.Parent then
                                        local vehCoords = ENTITY.GET_ENTITY_COORDS(veh, false)
                                        local dist = MISC.GET_DISTANCE_BETWEEN_COORDS(coords.x, coords.y, coords.z, vehCoords.x, vehCoords.y, vehCoords.z, false)
                                        if dist < closestDistance and dist < vars.turretRange then
                                            target = veh
                                            closestDistance = dist
                                        end
                                    end
                                end
                            end
                        end
                    end

                    
                    -- Aiming and shooting at target
                    if target ~= 0 and ENTITY.DOES_ENTITY_EXIST(target) and not ENTITY.IS_ENTITY_DEAD(target, false) then
                        local finish = ENTITY.GET_ENTITY_COORDS(target, false)
                        local start = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(turret.Minigun, 0.7, 0.0, 0.0)
                        
                        local distance = MISC.GET_DISTANCE_BETWEEN_COORDS(start.x, start.y, start.z, finish.x, finish.y, finish.z, false)
                        local rotY = MISC.ATAN2((finish.z - start.z), distance) * -1
                        local rotZ = MISC.ATAN2((finish.y - start.y), (finish.x - start.x))
                        
                        -- Rotate turret base
                        if turret.AttachType ~= 0 and ENTITY.DOES_ENTITY_EXIST(turret.Parent) then
                            local parentHeading = ENTITY.GET_ENTITY_HEADING(turret.Parent)
                            local targetHeading = rotZ + 90
                            local relativeZ = targetHeading - parentHeading
                            ENTITY.ATTACH_ENTITY_TO_ENTITY(turret.ID, turret.Parent, 0, 0.0, 0.0, 0.0, 0.0, 0.0, relativeZ, false, false, false, false, 2, true)
                        else
                            ENTITY.SET_ENTITY_ROTATION(turret.ID, 0, 0, rotZ + 90, 0, false)
                        end
                        -- Attach and aim minigun
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(turret.Minigun, turret.ID, 0, 0.0, -0.3, 1.6, 0.0, rotY, 270.0, true, true, true, false, 2, true)
                        
                        -- Draw laser line to target
                        GRAPHICS.DRAW_LINE(start.x, start.y, start.z, finish.x, finish.y, finish.z, 255, 0, 0, 255)
                        
                        -- Shoot at target
                        if turret.Weapon == 0xB1CA77B1 then -- RPG - needs cooldown
                            if turret.TurrentCooldown < MISC.GET_GAME_TIMER() then
                                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(start.x, start.y, start.z, finish.x, finish.y, finish.z, 250, false, turret.Weapon, turret.TurrentPed, true, false, 1000.0)
                                turret.TurrentCooldown = MISC.GET_GAME_TIMER() + 1000
                            end
                        else
                            -- Other weapons fire continuously
                            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(start.x, start.y, start.z, finish.x, finish.y, finish.z, 250, false, turret.Weapon, turret.TurrentPed, true, false, 1000.0)
                        end
                    end
                end
            else
                -- Turret no longer exists, remove it
                table.remove(Turrets, i)
            end
        end
    end
end

return SentryMenu
