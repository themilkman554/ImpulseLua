--[[
    Impulse Lua - Vehicle Movement Menu
    Port of vehicleMovementMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local MovementMenu = setmetatable({}, { __index = Submenu })
MovementMenu.__index = MovementMenu

local instance = nil

local vars = {
    -- Flying
    basicFlying = false,
    basicFlySpeed = 50.0,
    speedVehicle = false,
    flySpeed = 10,
    -- Boosting
    hornBoost = false,
    hornBoostSpeed = 10,
    infiniteBoost = false,
    -- Force
    brakeForce = 0,
    downforce = 0,
    lowerRideHeight = false,
    -- Autodrive
    autoDrive = false,
    autoDriveSpeed = 50,
    -- Drifting
    drift = false,
    driftAmount = 5,
    -- Limits
    bypassMaxSpeed = false,
    speedLimit = false,
    speedLimitAmount = 100,
    -- Misc
    vehicleJump = false,
    wheelie = false,
    driveOnWalls = false,
    driveOnWater = false
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

-- Bypass max speed
local function BypassMaxSpeed()
    ENTITY.SET_ENTITY_MAX_SPEED(GetCurrentVehicle(), 9999999.0)
end

-- Speed vehicle (numpad controls)
local function SpeedVehicle(speed)
    local veh = GetCurrentVehicle()
    -- Numpad 9 or RT to accelerate
    if Utils.IsKeyPressed(0x69) or PAD.IS_CONTROL_PRESSED(0, 228) then
        local currentSpeed = ENTITY.GET_ENTITY_SPEED(veh)
        local newSpeed = currentSpeed + (speed * 50 / 100)
        if newSpeed < speed * 50 then
            VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, newSpeed)
        end
    end
    -- Numpad 7 to go up
    if Utils.IsKeyPressed(0x67) then
        ENTITY.SET_ENTITY_VELOCITY(veh, 0, 0, 50.0)
    end
    -- Numpad 3 or LT to stop
    if Utils.IsKeyPressed(0x63) or PAD.IS_CONTROL_PRESSED(0, 229) then
        ENTITY.SET_ENTITY_VELOCITY(veh, 0, 0, 0)
    end
end

-- Horn boost
local function HornBoost(speed)
    if PLAYER.IS_PLAYER_PRESSING_HORN(PLAYER.PLAYER_ID()) then
        local veh = GetCurrentVehicle()
        local currentSpeed = ENTITY.GET_ENTITY_SPEED(veh)
        AUDIO.SET_VEHICLE_BOOST_ACTIVE(veh, true)
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, currentSpeed + speed)
        AUDIO.SET_VEHICLE_BOOST_ACTIVE(veh, false)
        GRAPHICS.ANIMPOSTFX_PLAY("RaceTurbo", 0, false)
    end
end

-- Unlimited boost
local function UnlimitedBoost()
    local veh = GetCurrentVehicle()
    VEHICLE.SET_SCRIPT_ROCKET_BOOST_RECHARGE_TIME(veh, 0.0)
    if VEHICLE.IS_ROCKET_BOOST_ACTIVE(veh) then
    end
end

-- Brake force
local function SetBrakeForce(force)
    local veh = GetCurrentVehicle()
    -- S key or brake control
    if Utils.IsKeyPressed(0x53) or Utils.IsKeyPressed(0x20) or PAD.IS_CONTROL_PRESSED(0, 72) then
        ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0, -(force / 10), 0, 0, 0, 0, 0, true, true, true, false, true)
    end
end

-- Downforce
local function SetDownforce(force)
    local veh = GetCurrentVehicle()
    if not ENTITY.IS_ENTITY_IN_AIR(veh) then
        ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0, 0, -force, 0, 0, 0, 0, true, true, true, false, true)
    end
end

-- Lower ride height
local function LowerRideHeight()
    ENTITY.APPLY_FORCE_TO_ENTITY(GetCurrentVehicle(), 1, 0, 0, -0.4, 0, 0, 0, 0, true, true, true, false, true)
end

-- Auto drive
local function AutoDrive(speed)
    local veh = GetCurrentVehicle()
    if VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(veh) then
        ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.5, 0, 0, 0, 0, 0, 0, true, true, true, false, true)
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, speed + 0.0)
    end
end

-- Drift
local function DriftVehicle(amount)
    local driftKey = Utils.IsKeyPressed(0x10) -- Shift
    if driftKey then
        VEHICLE.SET_VEHICLE_REDUCE_GRIP(GetCurrentVehicle(), true)
    else
        VEHICLE.SET_VEHICLE_REDUCE_GRIP(GetCurrentVehicle(), false)
    end
end

-- Vehicle jump
local function VehicleJump()
    if PAD.IS_DISABLED_CONTROL_PRESSED(2, 203) then
        local veh = GetCurrentVehicle()
        local fwdX = ENTITY.GET_ENTITY_FORWARD_X(veh)
        local fwdY = ENTITY.GET_ENTITY_FORWARD_Y(veh)
        ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, fwdX, fwdY, 7.0, 0, 0, 0, 1, false, true, true, true, true)
    end
end

-- Wheelie
local function Wheelie()
    if PAD.IS_DISABLED_CONTROL_PRESSED(0, 199) then -- X key
        local veh = GetCurrentVehicle()
        local rot = ENTITY.GET_ENTITY_ROTATION(veh, 2)
        ENTITY.SET_ENTITY_ROTATION(veh, rot.x + 0.5, rot.y, rot.z, 2, true)
    end
end

-- Drive on walls
local function DriveOnWalls()
    ENTITY.APPLY_FORCE_TO_ENTITY(GetCurrentVehicle(), 1, 0, 0, -0.4, 0, 0, 0, 0, false, true, true, false, true)
end

-- Basic fly mode
local function BasicFlyMode(speed)
    local veh = GetCurrentVehicle()
    local camRot = CAM.GET_GAMEPLAY_CAM_ROT(0)
    ENTITY.SET_ENTITY_ROTATION(veh, camRot.x, camRot.y, camRot.z, 0, true)
    
    local moving = false
    -- W key or RT
    if Utils.IsKeyPressed(0x57) or PAD.IS_CONTROL_PRESSED(0, 228) then
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, speed)
        moving = true
    end
    -- S key or LT
    if Utils.IsKeyPressed(0x53) or PAD.IS_CONTROL_PRESSED(0, 229) then
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, -speed)
        moving = true
    end
    
    if not moving then
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, 0)
        VEHICLE.SET_VEHICLE_FIXED(veh)
    end
end

function MovementMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Vehicle movement"), MovementMenu)
        instance:Init()
    end
    return instance
end

function MovementMenu:Init()
    -- Vehicle jump
    self:AddOption(ToggleOption.new("Vehicle jump")
        :AddToggleRef(vars, "vehicleJump")
        :AddTooltip("Jump with your vehicle using controller"))
    
    -- Basic fly vehicle
    self:AddOption(ToggleOption.new("Basic fly vehicle")
        :AddToggleRef(vars, "basicFlying")
        :AddTooltip("W to go forward / S to go backward / Mouse to control direction"))
    
    -- Basic fly speed
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Basic fly speed")
        :AddNumberRef(vars, "basicFlySpeed", "%.0f", 5)
        :AddMin(10):AddMax(100)
        :AddTooltip("Set the basic fly speed"))
    
    self:AddOption(BreakOption.new("Vehicle Speed"))
    
    -- Speed vehicle
    self:AddOption(ToggleOption.new("Speed vehicle")
        :AddToggleRef(vars, "speedVehicle")
        :AddTooltip("Speed your vehicle using numpad 9 and 3 || RT and LT"))
    
    -- Speed
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Speed")
        :AddNumberRef(vars, "flySpeed", "%d", 1)
        :AddMin(1):AddMax(50)
        :AddTooltip("Set the speed"))
    
    self:AddOption(BreakOption.new("Boosting"))
    
    -- Horn boost
    self:AddOption(ToggleOption.new("Horn boost")
        :AddToggleRef(vars, "hornBoost")
        :AddTooltip("Boost when pressing horn"))
    
    -- Horn boost speed
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Horn boost speed")
        :AddNumberRef(vars, "hornBoostSpeed", "%d", 1)
        :AddMin(1):AddMax(1000)
        :AddTooltip("Set horn boost speed"))
    
    -- Infinite boost
    self:AddOption(ToggleOption.new("Infinite boost")
        :AddToggleRef(vars, "infiniteBoost")
        :AddTooltip("Unlimited boost (R. Voltic, Oppressor)"))
    
    self:AddOption(BreakOption.new("Force"))
    
    -- Brake force
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Brake force")
        :AddNumberRef(vars, "brakeForce", "%d", 1)
        :AddMin(0):AddMax(10)
        :AddTooltip("Set vehicle brake force"))
    
    -- Downforce
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Downforce")
        :AddNumberRef(vars, "downforce", "%.2f", 0.05)
        :AddMin(-2):AddMax(2)
        :AddTooltip("Set vehicle downforce"))
    
    -- Lower ride height
    self:AddOption(ToggleOption.new("Lower ride height")
        :AddToggleRef(vars, "lowerRideHeight")
        :AddTooltip("Lower vehicle ride height"))
    
    self:AddOption(BreakOption.new("Autodrive"))
    
    -- Auto drive
    self:AddOption(ToggleOption.new("Auto drive")
        :AddToggleRef(vars, "autoDrive")
        :AddTooltip("Automatically drive forward"))
    
    -- Autodrive speed
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Autodrive speed")
        :AddNumberRef(vars, "autoDriveSpeed", "%d", 5)
        :AddMin(5):AddMax(1000)
        :AddTooltip("Set autodrive speed"))
    
    self:AddOption(BreakOption.new("Drifting"))
    
    -- Drift
    self:AddOption(ToggleOption.new("Drift")
        :AddToggleRef(vars, "drift")
        :AddTooltip("Enable drifting (hold Shift)"))
    
    -- Drift amount
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Drift amount")
        :AddNumberRef(vars, "driftAmount", "%d", 1)
        :AddMin(1):AddMax(10)
        :AddTooltip("Set drift amount"))
    
    self:AddOption(BreakOption.new("Limits"))
    
    -- Bypass max speed
    self:AddOption(ToggleOption.new("Bypass max speed")
        :AddToggleRef(vars, "bypassMaxSpeed")
        :AddTooltip("Remove vehicle speed limit"))
    
    -- Speed limit
    self:AddOption(ToggleOption.new("Limit vehicle speed")
        :AddToggleRef(vars, "speedLimit")
        :AddTooltip("Limit maximum vehicle speed"))
    
    -- Speed limit amount
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Speed limit")
        :AddNumberRef(vars, "speedLimitAmount", "%.0f km/h", 5)
        :AddMin(1):AddMax(300)
        :AddTooltip("Set speed limit"))
    
    self:AddOption(BreakOption.new("Misc"))
    
    -- Wheelie
    self:AddOption(ToggleOption.new("Wheelie")
        :AddToggleRef(vars, "wheelie")
        :AddTooltip("Do wheelies"))
    
    -- Drive on walls
    self:AddOption(ToggleOption.new("Drive on walls")
        :AddToggleRef(vars, "driveOnWalls")
        :AddTooltip("Drive on vertical surfaces"))
    
    -- Drive on water
    self:AddOption(ToggleOption.new("Drive on water")
        :AddToggleRef(vars, "driveOnWater")
        :AddTooltip("Drive on water surface"))
end

function MovementMenu:FeatureUpdate()
    if not IsInVehicle() then return end
    
    if vars.bypassMaxSpeed then BypassMaxSpeed() end
    if vars.speedLimit then
        ENTITY.SET_ENTITY_MAX_SPEED(GetCurrentVehicle(), vars.speedLimitAmount / 3.6)
    end
    if vars.speedVehicle then SpeedVehicle(vars.flySpeed) end
    if vars.hornBoost then HornBoost(vars.hornBoostSpeed) end
    if vars.infiniteBoost then UnlimitedBoost() end
    if vars.brakeForce > 0 then SetBrakeForce(vars.brakeForce) end
    if vars.downforce ~= 0 then SetDownforce(vars.downforce) end
    if vars.lowerRideHeight then LowerRideHeight() end
    if vars.autoDrive then AutoDrive(vars.autoDriveSpeed) end
    if vars.drift then DriftVehicle(vars.driftAmount) end
    if vars.vehicleJump then VehicleJump() end
    if vars.wheelie then Wheelie() end
    if vars.driveOnWalls then DriveOnWalls() end
    if vars.basicFlying then BasicFlyMode(vars.basicFlySpeed) end
end

return MovementMenu
