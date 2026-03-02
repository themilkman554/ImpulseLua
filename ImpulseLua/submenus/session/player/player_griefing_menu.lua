--[[
    Impulse Lua - Player Griefing Menu
    Griefing options for selected player
    Port of griefingMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")
local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")
local PlayerSoundMenu = require("Impulse/ImpulseLua/submenus/session/player/griefing/player_sound_menu")
local PlayerDisableActionsMenu = require("Impulse/ImpulseLua/submenus/session/player/griefing/player_disable_actions_menu")
local PlayerMenu = nil -- Lazy loaded

local PlayerGriefingMenu = setmetatable({}, { __index = Submenu })
PlayerGriefingMenu.__index = PlayerGriefingMenu

local instance = nil

-- Griefing state (per-player states stored by player ID)
local griefingState = {
    alwaysWanted = {},
    fakeMoney = {},
    smokePlayer = {},
    cloneSpam = {},
    onFire = {},
    explodeLoop = {},
    rainRockets = {},
    forcefield = {},
    karma = {},
    attackerCount = 5,
    lagPlayer = false,
    shakeCam = false,
    fireLoop = false,
    waterLoop = false,
    freezePlayer = false,
    stunPlayer = false
}

--- Get selected player ID from PlayerMenu
---@return number
local function GetSelectedPlayerId()
    if not PlayerMenu then
        PlayerMenu = require("Impulse/ImpulseLua/submenus/session/player_menu")
    end
    return PlayerMenu.targetPlayer or -1
end

--- Get selected player ped
---@return number
local function GetSelectedPlayerPed()
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then return 0 end
    return PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
end

--- Get selected player coords
---@return table
local function GetSelectedPlayerCoords()
    local ped = GetSelectedPlayerPed()
    if ped and ENTITY.DOES_ENTITY_EXIST(ped) then
        return ENTITY.GET_ENTITY_COORDS(ped, true)
    end
    return { x = 0, y = 0, z = 0 }
end

--- Get selected player name
---@return string
local function GetSelectedPlayerName()
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then return "Unknown" end
    return PLAYER.GET_PLAYER_NAME(playerId) or "Unknown"
end

--- Get selected player heading
---@return number
local function GetSelectedPlayerHeading()
    local ped = GetSelectedPlayerPed()
    if ped and ENTITY.DOES_ENTITY_EXIST(ped) then
        return ENTITY.GET_ENTITY_HEADING(ped)
    end
    return 0
end



-- ============================================
-- Built-in Feature Functions
-- ============================================

local function ClonePlayer()
    local playerId = GetSelectedPlayerId()
    if FeatureState.Trigger("Clone Player", playerId) then
        Renderer.Notify("Cloned " .. GetSelectedPlayerName())
    else
        Renderer.Notify("Feature not available")
    end
end





local function HostKick()
    local playerId = GetSelectedPlayerId()
    if FeatureState.Trigger("Host Kick", playerId) then
        Renderer.Notify("Host kicked " .. GetSelectedPlayerName())
    else
        Renderer.Notify("Feature not available (must be host)")
    end
end

local function CrashPlayer()
    local playerId = GetSelectedPlayerId()
    if FeatureState.Trigger("Crash Player", playerId) then
        Renderer.Notify("Crashing " .. GetSelectedPlayerName())
    else
        Renderer.Notify("Feature not available")
    end
end

local function ACCrash()
    local playerId = GetSelectedPlayerId()
    if FeatureState.Trigger("AC Crash", playerId) then
        Renderer.Notify("AC Crash sent to " .. GetSelectedPlayerName())
    else
        Renderer.Notify("Feature not available")
    end
end

local function MountCrash()
    local playerId = GetSelectedPlayerId()
    if FeatureState.Trigger("Mount Crash", playerId) then
        Renderer.Notify("Mount Crash sent to " .. GetSelectedPlayerName())
    else
        Renderer.Notify("Feature not available")
    end
end

local function SubCrash()
    local playerId = GetSelectedPlayerId()
    if FeatureState.Trigger("Sub Crash", playerId) then
        Renderer.Notify("Sub Crash sent to " .. GetSelectedPlayerName())
    else
        Renderer.Notify("Feature not available")
    end
end

local function ScriptEventCrash()
    local playerId = GetSelectedPlayerId()
    if FeatureState.Trigger("Script Event Crash", playerId) then
        Renderer.Notify("Script Event Crash sent to " .. GetSelectedPlayerName())
    else
        Renderer.Notify("Feature not available")
    end
end

local function ATFCrash()
    local playerId = GetSelectedPlayerId()
    if FeatureState.Trigger("ATF Crash", playerId) then
        Renderer.Notify("ATF Crash sent to " .. GetSelectedPlayerName())
    else
        Renderer.Notify("Feature not available")
    end
end

local function AuxiliaryCannonCrash()
    local playerId = GetSelectedPlayerId()
    if FeatureState.Trigger("Auxiliary Cannon Crash", playerId) then
        Renderer.Notify("Auxiliary Cannon Crash sent to " .. GetSelectedPlayerName())
    else
        Renderer.Notify("Feature not available")
    end
end

local function KillPlayer()
    local playerId = GetSelectedPlayerId()
    if FeatureState.Trigger("Kill Player", playerId) then
        Renderer.Notify("Killed " .. GetSelectedPlayerName())
    else
        Renderer.Notify("Feature not available")
    end
end

-- ============================================
-- Custom Implementation Functions
-- ============================================

--- Give wanted level (Report crime)
local function GiveWantedLevel()
    local playerId = GetSelectedPlayerId()
    if playerId < 0 then return end
    PLAYER.REPORT_CRIME(playerId, 8, PLAYER.GET_WANTED_LEVEL_THRESHOLD(5))
    Renderer.Notify("Gave wanted level to " .. GetSelectedPlayerName())
end

--- Trap in cage
local function CagePlayer()
    local coords = GetSelectedPlayerCoords()
    local cageHash = 0x7B059043 -- prop_gold_cont_01
    
    STREAMING.REQUEST_MODEL(cageHash)
    local timeout = 0
    while not STREAMING.HAS_MODEL_LOADED(cageHash) and timeout < 50 do
        timeout = timeout + 1
        Script.Yield(10)
    end
    
    if STREAMING.HAS_MODEL_LOADED(cageHash) then
        local cage1 = OBJECT.CREATE_OBJECT(cageHash, coords.x, coords.y, coords.z - 1, true, true, false)
        local cage2 = OBJECT.CREATE_OBJECT(cageHash, coords.x, coords.y, coords.z + 1, true, true, false)
        ENTITY.FREEZE_ENTITY_POSITION(cage1, true)
        ENTITY.FREEZE_ENTITY_POSITION(cage2, true)
        ENTITY.SET_ENTITY_ROTATION(cage2, 0, 180, 90, 0, false)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cageHash)
        Renderer.Notify("Caged " .. GetSelectedPlayerName())
    end
end

--- Trap in cable cars
local function TrapPlayer()
    local coords = GetSelectedPlayerCoords()
    local cablecarHash = Utils.Joaat("p_cablecar_s")
    
    STREAMING.REQUEST_MODEL(cablecarHash)
    local timeout = 0
    while not STREAMING.HAS_MODEL_LOADED(cablecarHash) and timeout < 50 do
        timeout = timeout + 1
        Script.Yield(10)
    end
    
    if STREAMING.HAS_MODEL_LOADED(cablecarHash) then
        local trap1 = OBJECT.CREATE_OBJECT(cablecarHash, coords.x, coords.y, coords.z - 1, true, true, false)
        local trap2 = OBJECT.CREATE_OBJECT(cablecarHash, coords.x, coords.y, coords.z - 1, true, true, false)
        ENTITY.FREEZE_ENTITY_POSITION(trap1, true)
        ENTITY.FREEZE_ENTITY_POSITION(trap2, true)
        ENTITY.SET_ENTITY_ROTATION(trap2, 0, 0, 90, 0, false)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cablecarHash)
        Renderer.Notify("Trapped " .. GetSelectedPlayerName())
    end
end

--- Ram with vehicle
local function RamWithVehicle()
    local coords = GetSelectedPlayerCoords()
    local heading = GetSelectedPlayerHeading()
    local busHash = Utils.Joaat("bus")
    
    STREAMING.REQUEST_MODEL(busHash)
    local timeout = 0
    while not STREAMING.HAS_MODEL_LOADED(busHash) and timeout < 50 do
        timeout = timeout + 1
        Script.Yield(10)
    end
    
    if STREAMING.HAS_MODEL_LOADED(busHash) then
        local vehicle = VEHICLE.CREATE_VEHICLE(busHash, coords.x, coords.y, coords.z, heading, true, false, false)
        if vehicle and vehicle ~= 0 then
            ENTITY.SET_ENTITY_HEADING(vehicle, heading)
            VEHICLE.SET_VEHICLE_OUT_OF_CONTROL(vehicle, true, true)
            VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 200.0)
        end
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(busHash)
        Renderer.Notify("Ramming " .. GetSelectedPlayerName())
    end
end

--- Explode player (single explosion)
local function ExplodePlayer()
    local coords = GetSelectedPlayerCoords()
    FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 18, 0.25, true, false, 0.5, false)
    Renderer.Notify("Exploded " .. GetSelectedPlayerName())
end



--- Silent kill
local function SilentKill()
    local playerPed = GetSelectedPlayerPed()
    local coords = GetSelectedPlayerCoords()
    FIRE.ADD_OWNED_EXPLOSION(playerPed, coords.x, coords.y, coords.z, 38, 0.1, false, false, 0.0)
    Renderer.Notify("Silent killed " .. GetSelectedPlayerName())
end

--- Send attackers
local function SendAttackers()
    local coords = GetSelectedPlayerCoords()
    local targetPed = GetSelectedPlayerPed()
    local swatHash = 0xB3F3EE34
    local weaponHash = 0x42BF8A85 -- SMG
    local count = griefingState.attackerCount
    
    STREAMING.REQUEST_MODEL(swatHash)
    local timeout = 0
    while not STREAMING.HAS_MODEL_LOADED(swatHash) and timeout < 50 do
        timeout = timeout + 1
        Script.Yield(10)
    end
    
    if STREAMING.HAS_MODEL_LOADED(swatHash) then
        for i = 1, count do
            local ped = PED.CREATE_PED(21, swatHash, coords.x, coords.y, coords.z, 0, true, true)
            if ped and ped ~= 0 then
                PED.SET_PED_COMBAT_ABILITY(ped, 100)
                TASK.TASK_COMBAT_PED(ped, targetPed, 0, 16)
                PED.SET_PED_CAN_SWITCH_WEAPON(ped, false)
                PED.SET_PED_CAN_RAGDOLL(ped, false)
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(ped, weaponHash, 9999, true)
            end
        end
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(swatHash)
        Renderer.Notify("Sent " .. count .. " attackers to " .. GetSelectedPlayerName())
    end
end

--- Hostile clone
local function HostileClone()
    local targetPed = GetSelectedPlayerPed()
    if not targetPed or not ENTITY.DOES_ENTITY_EXIST(targetPed) then
        Renderer.Notify("Player not found")
        return
    end
    
    local heading = ENTITY.GET_ENTITY_HEADING(targetPed)
    local clone = PED.CLONE_PED(targetPed, heading, true, false)
    
    if clone and clone ~= 0 then
        WEAPON.GIVE_WEAPON_TO_PED(clone, 0x7FD62962, 9999, true, true) -- AP Pistol
        TASK.TASK_COMBAT_PED(clone, targetPed, 0, 16)
        PED.SET_PED_KEEP_TASK(clone, true)
        Renderer.Notify("Spawned hostile clone of " .. GetSelectedPlayerName())
    end
end

--- Attack with SWAT
local function SWATAttack()
    local coords = GetSelectedPlayerCoords()
    local heading = GetSelectedPlayerHeading()
    local targetPed = GetSelectedPlayerPed()
    local swatHash = 0xB3F3EE34
    
    STREAMING.REQUEST_MODEL(swatHash)
    local timeout = 0
    while not STREAMING.HAS_MODEL_LOADED(swatHash) and timeout < 50 do
        timeout = timeout + 1
        Script.Yield(10)
    end
    
    if STREAMING.HAS_MODEL_LOADED(swatHash) then
        local ped = PED.CREATE_PED(21, swatHash, coords.x, coords.y, coords.z, heading, true, true)
        if ped and ped ~= 0 then
            PED.SET_PED_COMBAT_ABILITY(ped, 100)
            TASK.TASK_COMBAT_PED(ped, targetPed, 0, 16)
            PED.SET_PED_CAN_SWITCH_WEAPON(ped, false)
            PED.SET_PED_CAN_RAGDOLL(ped, false)
            WEAPON.GIVE_DELAYED_WEAPON_TO_PED(ped, 0xB1CA77B1, 9999, true) -- SMG MK2
        end
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(swatHash)
        Renderer.Notify("SWAT attacking " .. GetSelectedPlayerName())
    end
end

--- Attack with jet
local function JetAttack()
    local coords = GetSelectedPlayerCoords()
    local heading = GetSelectedPlayerHeading()
    local targetPed = GetSelectedPlayerPed()
    local jetHash = Utils.Joaat("lazer")
    
    STREAMING.REQUEST_MODEL(jetHash)
    local timeout = 0
    while not STREAMING.HAS_MODEL_LOADED(jetHash) and timeout < 50 do
        timeout = timeout + 1
        Script.Yield(10)
    end
    
    if STREAMING.HAS_MODEL_LOADED(jetHash) then
        local randX = math.random(-50, 50)
        local randY = math.random(-50, 50)
        local randZ = math.random(25, 75)
        local spawnCoords = { x = coords.x + randX, y = coords.y + randY, z = coords.z + randZ }
        
        local veh = VEHICLE.CREATE_VEHICLE(jetHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, false, false)
        if veh and veh ~= 0 then
            local driver = PED.CREATE_RANDOM_PED_AS_DRIVER(veh, false)
            PED.SET_PED_INTO_VEHICLE(driver, veh, -1)
            ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0, 0, 50, 0, 0, 0, 0, true, true, true, false, true)
            TASK.TASK_PLANE_CHASE(driver, targetPed, 0, 0, 50)
            VEHICLE.CONTROL_LANDING_GEAR(veh, 3)
            TASK.TASK_COMBAT_PED(driver, targetPed, 0, 16)
            PED.SET_PED_KEEP_TASK(driver, true)
        end
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(jetHash)
        Renderer.Notify("Jet attacking " .. GetSelectedPlayerName())
    end
end

--- Attack with vehicle
local function VehicleAttack()
    local coords = GetSelectedPlayerCoords()
    local heading = GetSelectedPlayerHeading()
    local targetPed = GetSelectedPlayerPed()
    local carHash = Utils.Joaat("adder")
    
    STREAMING.REQUEST_MODEL(carHash)
    local timeout = 0
    while not STREAMING.HAS_MODEL_LOADED(carHash) and timeout < 50 do
        timeout = timeout + 1
        Script.Yield(10)
    end
    
    if STREAMING.HAS_MODEL_LOADED(carHash) then
        local spawnCoords = { x = coords.x, y = coords.y - 15, z = coords.z }
        local veh = VEHICLE.CREATE_VEHICLE(carHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, false, false)
        if veh and veh ~= 0 then
            local driver = PED.CREATE_RANDOM_PED_AS_DRIVER(veh, false)
            PED.SET_PED_INTO_VEHICLE(driver, veh, -1)
            PED.SET_DRIVER_AGGRESSIVENESS(driver, 100.0)
            TASK.TASK_VEHICLE_FOLLOW(driver, veh, targetPed, 200.0, 262144, 10)
            PED.SET_PED_KEEP_TASK(driver, true)
            VEHICLE.SET_VEHICLE_OUT_OF_CONTROL(veh, false, true)
            VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, 30)
        end
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(carHash)
        Renderer.Notify("Vehicle attacking " .. GetSelectedPlayerName())
    end
end

--- Airstrike
local function Airstrike()
    local coords = GetSelectedPlayerCoords()
    local myPed = PLAYER.PLAYER_PED_ID()
    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
        coords.x, coords.y, coords.z + 250,
        coords.x, coords.y, coords.z,
        0, true, 0x63AB0442, myPed, false, false, -1.0)
    Renderer.Notify("Airstrike on " .. GetSelectedPlayerName())
end

--- Ragdoll player
local function RagdollPlayer()
    local coords = GetSelectedPlayerCoords()
    FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z - 0.2, 4, 10.0, false, true, 0.0, false)
    Renderer.Notify("Ragdolled " .. GetSelectedPlayerName())
end

-- ============================================
-- Menu Definition
-- ============================================

function PlayerGriefingMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Griefing"), PlayerGriefingMenu)
        instance:Init()
    end
    return instance
end

function PlayerGriefingMenu:Init()
    self:AddOption(SubmenuOption.new("Disable actions")
        :AddSubmenu(PlayerDisableActionsMenu.GetInstance())
        :AddTooltip("Disable certain player actions"))
        :SetDonor()
    self:AddOption(SubmenuOption.new("Sounds")
        :AddSubmenu(PlayerSoundMenu.GetInstance())
        :AddTooltip("Play sounds on the player"))
    self:AddOption(BreakOption.new("Troll"))
    
    -- Built-in: Clone
    self:AddOption(ButtonOption.new("Clone")
        :AddFunction(ClonePlayer)
        :AddTooltip("Clone player"))
    
    -- Built-in: Freeze
    self:AddOption(ToggleOption.new("Freeze player")
        :AddToggleRef(griefingState, "freezePlayer")
        :AddFunction(function()
            local playerId = GetSelectedPlayerId()
            local feature = FeatureMgr.GetFeatureByName("Freeze Player", playerId)
            if feature then
                feature:SetValue(griefingState.freezePlayer):TriggerCallback()
            end

            if griefingState.freezePlayer then
                Renderer.Notify("Froze " .. GetSelectedPlayerName())
            else
                Renderer.Notify("Unfroze " .. GetSelectedPlayerName())
            end
        end)
        :AddTooltip("Freeze the player in place"))
    
    -- Custom: Give wanted level
    self:AddOption(ButtonOption.new("Give wanted level")
        :AddFunction(GiveWantedLevel)
        :AddTooltip("Add wanted level"))
    
    -- Built-in: Stun (Electrocute)
    self:AddOption(ToggleOption.new("Stun player")
        :AddToggleRef(griefingState, "stunPlayer")
        :AddFunction(function()
            local playerId = GetSelectedPlayerId()
            local feature = FeatureMgr.GetFeatureByName("Stun Player", playerId)
            if feature then
                feature:SetValue(griefingState.stunPlayer):TriggerCallback()
            end

            if griefingState.stunPlayer then
                Renderer.Notify("Stunned " .. GetSelectedPlayerName())
            else
                Renderer.Notify("Stopped stunning " .. GetSelectedPlayerName())
            end
        end)
        :AddTooltip("Electrocute the selected player"))
    
    -- Built-in: Lag
    -- Built-in: Lag
    self:AddOption(ToggleOption.new("Lag player")
        :AddToggleRef(griefingState, "lagPlayer")
        :AddFunction(function()
            local playerId = GetSelectedPlayerId()
            local feature = FeatureMgr.GetFeatureByName("Lag Player", playerId)
            if feature then
                feature:SetValue(griefingState.lagPlayer):TriggerCallback()
            end

            if griefingState.lagPlayer then
                Renderer.Notify("Lagging " .. GetSelectedPlayerName())
            else
                Renderer.Notify("Stopped lagging " .. GetSelectedPlayerName())
            end
        end)
        :AddTooltip("Lag the player"))
    
    self:AddOption(BreakOption.new("Affect Ped Vision and Movement"))
    
    -- Custom: Trap in cage
    self:AddOption(ButtonOption.new("Trap in cage")
        :AddFunction(CagePlayer)
        :AddTooltip("Trap in cage"))
    
    -- Custom: Trap in cable cars
    self:AddOption(ButtonOption.new("Trap in cable cars")
        :AddFunction(TrapPlayer)
        :AddTooltip("Trap in cable cars"))
    
    -- Built-in: Shake cam
    -- Built-in: Shake cam
    self:AddOption(ToggleOption.new("Shake camera")
        :AddToggleRef(griefingState, "shakeCam")
        :AddFunction(function()
            local playerId = GetSelectedPlayerId()
            local feature = FeatureMgr.GetFeatureByName("Shake Cam", playerId)
            if feature then
                feature:SetValue(griefingState.shakeCam):TriggerCallback()
            end

            if griefingState.shakeCam then
                Renderer.Notify("Shaking " .. GetSelectedPlayerName() .. "'s camera")
            else
                Renderer.Notify("Stopped shaking " .. GetSelectedPlayerName() .. "'s camera")
            end
        end)
        :AddTooltip("Shake the player's camera"))
    
    -- Built-in: Water loop
    -- Built-in: Water loop
    self:AddOption(ToggleOption.new("Spray with water")
        :AddToggleRef(griefingState, "waterLoop")
        :AddFunction(function()
            local playerId = GetSelectedPlayerId()
            local feature = FeatureMgr.GetFeatureByName("Water Loop", playerId)
            if feature then
                feature:SetValue(griefingState.waterLoop):TriggerCallback()
            end

            if griefingState.waterLoop then
                Renderer.Notify("Water loop on " .. GetSelectedPlayerName())
            else
                Renderer.Notify("Stopped water loop on " .. GetSelectedPlayerName())
            end
        end)
        :AddTooltip("Spray with water"))
    
    -- Built-in: Fire loop
    -- Built-in: Fire loop
    self:AddOption(ToggleOption.new("Spray with fire")
        :AddToggleRef(griefingState, "fireLoop")
        :AddFunction(function()
            local playerId = GetSelectedPlayerId()
            local feature = FeatureMgr.GetFeatureByName("Fire Loop", playerId)
            if feature then
                feature:SetValue(griefingState.fireLoop):TriggerCallback()
            end

            if griefingState.fireLoop then
                Renderer.Notify("Fire loop on " .. GetSelectedPlayerName())
            else
                Renderer.Notify("Stopped fire loop on " .. GetSelectedPlayerName())
            end
        end)
        :AddTooltip("Spray with fire"))
    
    self:AddOption(BreakOption.new("Deadly Force"))
    
    -- Built-in: Host kick
    self:AddOption(ButtonOption.new("Host kick")
        :AddFunction(HostKick)
        :AddTooltip("Host kick player [Must be session host]"))
    
    -- Built-in: Crash player
    self:AddOption(ButtonOption.new("Crash player")
        :AddFunction(CrashPlayer)
        :AddTooltip("Crash player"))
    
    -- Built-in: AC Crash
    self:AddOption(ButtonOption.new("AC Crash")
        :AddFunction(ACCrash)
        :AddTooltip("AC Crash player"))
    
    -- Built-in: Mount Crash
    self:AddOption(ButtonOption.new("Mount Crash")
        :AddFunction(MountCrash)
        :AddTooltip("Mount Crash player"))
    
    -- Built-in: Sub Crash
    self:AddOption(ButtonOption.new("Sub Crash")
        :AddFunction(SubCrash)
        :AddTooltip("Sub Crash player"))
    
    -- Built-in: Script Event Crash
    self:AddOption(ButtonOption.new("Script Event Crash")
        :AddFunction(ScriptEventCrash)
        :AddTooltip("Script Event Crash player"))
    
    -- Built-in: ATF Crash
    self:AddOption(ButtonOption.new("ATF Crash")
        :AddFunction(ATFCrash)
        :AddTooltip("ATF Crash player"))
    
    -- Built-in: Auxiliary Cannon Crash
    self:AddOption(ButtonOption.new("Auxiliary Cannon Crash")
        :AddFunction(AuxiliaryCannonCrash)
        :AddTooltip("Auxiliary Cannon Crash player"))
    
    -- Built-in: Kill
    self:AddOption(ButtonOption.new("Kill")
        :AddFunction(KillPlayer)
        :AddTooltip("Kill the player"))
    
    -- Custom: Silent kill
    self:AddOption(ButtonOption.new("Silent kill")
        :AddFunction(SilentKill)
        :AddTooltip("Peacefully kill the player"))
    
    -- Custom: Ram with vehicle
    self:AddOption(ButtonOption.new("Ram with vehicle")
        :AddFunction(RamWithVehicle)
        :AddTooltip("Ram player with vehicle"))
    
    -- Custom: Explode
    self:AddOption(ButtonOption.new("Explode")
        :AddFunction(ExplodePlayer)
        :AddTooltip("Explode player"))
    
    self:AddOption(BreakOption.new("Attackers"))
    
    -- Custom: Send attackers
    self:AddOption(NumberOption.new(NumberOption.Type.SELECT, "Send attackers")
        :AddNumberRef(griefingState, "attackerCount", "%d", 1)
        :SetMin(1)
        :SetMax(20)
        :AddFunction(SendAttackers)
        :AddTooltip("Send a custom amount of attackers to the player"))
    
    -- Custom: Hostile clone
    self:AddOption(ButtonOption.new("Hostile clone")
        :AddFunction(HostileClone)
        :AddTooltip("Hostile clone"))
    
    -- Custom: Attack with SWAT
    self:AddOption(ButtonOption.new("Attack with SWAT")
        :AddFunction(SWATAttack)
        :AddTooltip("Attack with SWAT"))
    
    -- Custom: Attack with jet
    self:AddOption(ButtonOption.new("Attack with jet")
        :AddFunction(JetAttack)
        :AddTooltip("Attack with jet"))
    
    -- Custom: Attack with vehicle
    self:AddOption(ButtonOption.new("Attack with vehicle")
        :AddFunction(VehicleAttack)
        :AddTooltip("Attack with explosive vehicle"))
    
    self:AddOption(BreakOption.new("Misc"))
    
    -- Custom: Airstrike
    self:AddOption(ButtonOption.new("Airstrike")
        :AddFunction(Airstrike)
        :AddTooltip("Airstrike attack player"))
    
    -- Custom: Ragdoll
    self:AddOption(ButtonOption.new("Ragdoll player")
        :AddFunction(RagdollPlayer)
        :AddTooltip("Ragdoll the player"))
end

return PlayerGriefingMenu
