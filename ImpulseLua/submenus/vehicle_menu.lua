local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local TextInputComponent = require("Impulse/ImpulseLua/lib/ui/text_input_component")

-- Import vehicle submenus
local AcrobaticsMenu = require("Impulse/ImpulseLua/submenus/vehicle/acrobatics_menu")
local DoorsMenu = require("Impulse/ImpulseLua/submenus/vehicle/doors_menu")
local WeaponsMenu = require("Impulse/ImpulseLua/submenus/vehicle/weapons_menu")
local MultipliersMenu = require("Impulse/ImpulseLua/submenus/vehicle/multipliers_menu")
local MovementMenu = require("Impulse/ImpulseLua/submenus/vehicle/movement_menu")
local ParticlesMenu = require("Impulse/ImpulseLua/submenus/vehicle/particles_menu")
local LSCMenu = require("Impulse/ImpulseLua/submenus/vehicle/lsc/lsc_menu")

local VehicleMenu = setmetatable({}, { __index = Submenu })
VehicleMenu.__index = VehicleMenu

local instance = nil

-- State variables (matching C++ VehicleMenuVars::Vars)
local vars = {
    vehicleGodmode = false,
    autoRepair = false,
    vehicleInvisibility = false,
    keepEngineOn = false,
    seatbelt = false,
    autoFlip = false,
    noCollision = false,
    phaseThroughVehicles = false,
    rainbowPaint = false,
    smokeCycle = false,
    burnShell = false,
    onscreenSpeedo = false,
    numberplateSpeedo = false,
    fibNumberplate = false,
    opacity = 0,
    vehicleNuke = false,
    showNukeArea = true
}

-- Rainbow paint state
local rainbowState = {
    primary = { r = 255, g = 0, b = 0 },
    secondary = { r = 0, g = 255, b = 0 }
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

-- Vehicle Godmode
local function VehicleGodmode(vehicle, toggle)
    if not ENTITY.DOES_ENTITY_EXIST(vehicle) then return end
    ENTITY.SET_ENTITY_INVINCIBLE(vehicle, toggle)
    ENTITY.SET_ENTITY_PROOFS(vehicle, toggle, toggle, toggle, toggle, toggle, toggle, toggle, toggle)
    VEHICLE.SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED(vehicle, not toggle)
    if toggle then
        VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
    end
end

-- Seatbelt
local function Seatbelt(toggle)
    local ped = PLAYER.PLAYER_PED_ID()
    PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(ped, toggle and 1 or 0)
end

-- Invisible Vehicle
local function InvisibleVehicle(toggle)
    if not IsInVehicle() then return end
    ENTITY.SET_ENTITY_VISIBLE(GetCurrentVehicle(), not toggle, false)
end

-- Fix Vehicle
local function FixVehicle(vehicle)
    if not ENTITY.DOES_ENTITY_EXIST(vehicle) then return end
    VEHICLE.SET_VEHICLE_FIXED(vehicle)
    VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(vehicle)
    VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
    VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
    FIRE.STOP_ENTITY_FIRE(vehicle)
end

-- Auto Flip
local function AutoFlip()
    if not IsInVehicle() then return end
    local veh = GetCurrentVehicle()
    if not ENTITY.IS_ENTITY_UPRIGHT(veh, 120.0) then
        local rot = ENTITY.GET_ENTITY_ROTATION(veh, 2)
        ENTITY.SET_ENTITY_ROTATION(veh, 0, rot.y, rot.z, 0, true)
    end
end

-- Rainbow Vehicle
local function RainbowVehicle(vehicle)
    if not IsInVehicle() then return end
    
    local p = rainbowState.primary
    local s = rainbowState.secondary
    
    -- Primary color cycle
    if p.r > 0 and p.b == 0 then
        p.r = p.r - 1
        p.g = p.g + 1
    elseif p.g > 0 and p.r == 0 then
        p.g = p.g - 1
        p.b = p.b + 1
    elseif p.b > 0 and p.g == 0 then
        p.r = p.r + 1
        p.b = p.b - 1
    end
    
    -- Secondary color cycle
    if s.r > 0 and s.b == 0 then
        s.r = s.r - 1
        s.g = s.g + 1
    elseif s.g > 0 and s.r == 0 then
        s.g = s.g - 1
        s.b = s.b + 1
    elseif s.b > 0 and s.g == 0 then
        s.r = s.r + 1
        s.b = s.b - 1
    end
    
    VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, p.r, p.g, p.b)
    VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle, s.r, s.g, s.b)
end

-- Smoke Cycle
local function SmokeCycle()
    if not IsInVehicle() then return end
    local veh = GetCurrentVehicle()
    VEHICLE.TOGGLE_VEHICLE_MOD(veh, 20, true)
    VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
    local r = math.random(0, 255)
    local g = math.random(0, 255)
    local b = math.random(0, 255)
    VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(veh, r, g, b)
end

-- Burn Shell
local function BurnShell(toggle)
    if not IsInVehicle() then return end
    ENTITY.SET_ENTITY_RENDER_SCORCHED(GetCurrentVehicle(), toggle)
end

-- On Screen Speedo
local function OnScreenSpeedo()
    if not IsInVehicle() then return end
    local veh = GetCurrentVehicle()
    local speed = ENTITY.GET_ENTITY_SPEED(veh) * 3.6 -- Convert to km/h
    Renderer.DrawString(
        string.format("%.0f KM/H", speed),
        0.5, 0.02,
        Renderer.Font.ChaletLondon, 0.4,
        { r = 255, g = 255, b = 255, a = 255 },
        true
    )
end

-- Numberplate Speedo
local function NumberplateSpeedo()
    if not IsInVehicle() then return end
    local veh = GetCurrentVehicle()
    local speed = ENTITY.GET_ENTITY_SPEED(veh) * 3.6
    VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(veh, string.format("%.0f KMH", speed))
end

-- FIB Numberplate (scrolling text)
local fibState = { timer = 0, index = 0 }
local function FIBNumberplate()
    if not IsInVehicle() then return end
    local now = MISC.GET_GAME_TIMER()
    if now - fibState.timer > 500 then
        fibState.timer = now
        local message = "IMPULSE IS THE WAY"
        fibState.index = fibState.index + 1
        if fibState.index > #message then fibState.index = 1 end
        local text = string.sub(message .. "        " .. message, fibState.index, fibState.index + 7)
        VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(GetCurrentVehicle(), text)
    end
end

-- No Collision
local function NoCollision(toggle)
    if not IsInVehicle() then return end
    ENTITY.SET_ENTITY_COLLISION(GetCurrentVehicle(), not toggle, false)
end

-- Phase Through Vehicles
local function PhaseThroughVehicles(toggle)
    if not IsInVehicle() then return end
    local veh = GetCurrentVehicle()
    ENTITY.SET_ENTITY_COLLISION(veh, not toggle, false)
    VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(veh, 1.0)
end

-- Vehicle Nuke
local nukeState = {
    marked = false,
    coords = { x = 0, y = 0, z = 0 },
    lastClick = 0
}

local function VehicleNuke()
    if not IsInVehicle() then return end
    
    local veh = GetCurrentVehicle()
    local coords = ENTITY.GET_ENTITY_COORDS(veh, true)
    local height = ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(veh)
    
    -- Draw marker
    local drawCoords = coords
    if nukeState.marked then
        drawCoords = nukeState.coords
    else
        drawCoords = { x = coords.x, y = coords.y, z = coords.z - height }
    end
    
    -- Using 24-argument pattern from spawn_menu.lua (type 28 = marker ring/circle like C++)
    -- Type 28 is a "cylinder" marker in GTA V
    -- Only draw if showNukeArea is enabled
    if vars.showNukeArea then
        GRAPHICS.DRAW_MARKER(28, drawCoords.x, drawCoords.y, drawCoords.z + 1, 0, 0, 0, 0, 0, 0, 15, 15, 0.86, 0, 255, 0, 100, 0, 1, 1, 0, 0, 0, 0)
    end
        
    -- Input check (Spacebar or Controller LS)
    local now = MISC.GET_GAME_TIMER()
    if now - nukeState.lastClick > 150 then
        -- 22 = Jump (Space), 209 = Frontend LS
        if PAD.IS_DISABLED_CONTROL_PRESSED(0, 22) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 209) then
            if not nukeState.marked then
                nukeState.coords = { x = coords.x, y = coords.y, z = coords.z - height }
                nukeState.marked = true
                nukeState.lastClick = now
                Renderer.Notify("Nuke zone marked!")
            else
                -- Explosion loop
                for i = 1, 45 do
                    local rx = math.random() * 18.0 - 9.0
                    local ry = math.random() * 18.0 - 9.0
                    FIRE.ADD_EXPLOSION(
                        nukeState.coords.x + rx, 
                        nukeState.coords.y + ry, 
                        nukeState.coords.z, 
                        9, 1000.0, true, false, 1.0, false
                    )
                end
                nukeState.marked = false
                nukeState.lastClick = now
                Renderer.Notify("Nuke detonated!")
            end
        end
    end
end

-- Clone Vehicle
local function CloneVehicle()
    if not IsInVehicle() then return end
    local veh = GetCurrentVehicle()
    local model = ENTITY.GET_ENTITY_MODEL(veh)
    local ped = PLAYER.PLAYER_PED_ID()
    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
    local heading = ENTITY.GET_ENTITY_HEADING(ped)
    
    -- Request model
    STREAMING.REQUEST_MODEL(model)
    local timeout = 0
    while not STREAMING.HAS_MODEL_LOADED(model) and timeout < 100 do
        Script.Yield(10)
        timeout = timeout + 1
    end
    
    if STREAMING.HAS_MODEL_LOADED(model) then
        local newVeh = VEHICLE.CREATE_VEHICLE(model, coords.x, coords.y, coords.z, heading, true, true, false)
        PED.SET_PED_INTO_VEHICLE(ped, newVeh, -1)
        
        -- Copy colors
        local prim, sec = VEHICLE.GET_VEHICLE_COLOURS(veh)
        VEHICLE.SET_VEHICLE_COLOURS(newVeh, prim, sec)
        
        -- Copy mods
        VEHICLE.SET_VEHICLE_MOD_KIT(newVeh, 0)
        for i = 0, 49 do
            local mod = VEHICLE.GET_VEHICLE_MOD(veh, i)
            if mod >= 0 then
                VEHICLE.SET_VEHICLE_MOD(newVeh, i, mod, false)
            end
        end
        
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model)
        Renderer.Notify("Vehicle cloned!")
    end
end

function VehicleMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Vehicle"), VehicleMenu)
        instance:Init()
    end
    return instance
end

local saveInput = nil

local function SaveCHRXVehicle(saveName)
    local playerPed = PLAYER.PLAYER_PED_ID()
    local entToSave = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)

    if not ENTITY.DOES_ENTITY_EXIST(entToSave) then
        Renderer.Notify("Not in a vehicle!")
        return
    end

    Script.QueueJob(function()
        pcall(function()
             -- Unfreeze the vehicle before sitting in it
            if ENTITY.DOES_ENTITY_EXIST(entToSave) then
                ENTITY.FREEZE_ENTITY_POSITION(entToSave, false)
            end
            
            -- Ensure player is in driver seat
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(entToSave, -1, false)
            if driver ~= playerPed then
                 PED.SET_PED_INTO_VEHICLE(playerPed, entToSave, -1)
                 Script.Yield(500)
            end

            -- Set the name and save with 1 second delay
            local vehicleNameFeature = FeatureMgr.GetFeatureByName("Vehicle Name")
            local saveVehicleFeature = FeatureMgr.GetFeatureByName("Save Current Vehicle")
            
            if vehicleNameFeature and saveVehicleFeature then
                vehicleNameFeature:SetStringValue(saveName)
                Script.Yield(1000) -- 1 second delay
                saveVehicleFeature:TriggerCallback()
                Renderer.Notify("Saved vehicle: " .. saveName)
            else
                Renderer.Notify("Save feature not found")
            end
        end)
    end)
end

function VehicleMenu:Init()
    -- Save CHRX Vehicle
    self:AddOption(ButtonOption.new("Save CHRX vehicle")
        :AddFunction(function()
            if not saveInput then
                saveInput = TextInputComponent.new("Vehicle Name", function(text)
                    if text and #text > 0 then
                        SaveCHRXVehicle(text)
                    end
                end)
            end
            saveInput:Show()
        end)
        :AddTooltip("Save current vehicle"))
    self:AddOption(BreakOption.new())
    -- Submenus
    self:AddOption(SubmenuOption.new("Los Santos Customs")
        :AddSubmenu(LSCMenu.GetInstance())
        :AddTooltip("Vehicle customization and mods"))

    self:AddOption(SubmenuOption.new("Vehicle weapons")
        :AddSubmenu(WeaponsMenu.GetInstance())
        :AddTooltip("Vehicle mounted weapons"))
    
    self:AddOption(SubmenuOption.new("Vehicle movement")
        :AddSubmenu(MovementMenu.GetInstance())
        :AddTooltip("Vehicle movement options"))
    
    self:AddOption(SubmenuOption.new("Vehicle acrobatics")
        :AddSubmenu(AcrobaticsMenu.GetInstance())
        :AddTooltip("Vehicle acrobatics and stunts"))
    
    self:AddOption(SubmenuOption.new("Vehicle particles")
        :AddSubmenu(ParticlesMenu.GetInstance())
        :AddTooltip("Vehicle particle effects"))
    
    self:AddOption(SubmenuOption.new("Vehicle doors")
        :AddSubmenu(DoorsMenu.GetInstance())
        :AddTooltip("Vehicle door controls"))
    
    self:AddOption(SubmenuOption.new("Vehicle multipliers")
        :AddSubmenu(MultipliersMenu.GetInstance())
        :AddTooltip("Vehicle power multipliers"))
    
    self:AddOption(BreakOption.new("General"))
    
    -- Vehicle Godmode
    self:AddOption(ToggleOption.new("Vehicle Godmode")
        :AddToggleRef(vars, "vehicleGodmode")
        :AddFunction(function()
            if IsInVehicle() then
                VehicleGodmode(GetCurrentVehicle(), vars.vehicleGodmode)
            end
        end)
        :AddTooltip("Make your vehicle invincible"))
    
    -- Auto Repair
    self:AddOption(ToggleOption.new("Auto repair")
        :AddToggleRef(vars, "autoRepair")
        :AddTooltip("Automatically repair your vehicle"))
    
    -- Vehicle Invisibility
    self:AddOption(ToggleOption.new("Vehicle invisibility")
        :AddToggleRef(vars, "vehicleInvisibility")
        :AddFunction(function()
            InvisibleVehicle(vars.vehicleInvisibility)
        end)
        :AddTooltip("Make your vehicle invisible"))
    
    -- Keep Engine On
    self:AddOption(ToggleOption.new("Keep engine on")
        :AddToggleRef(vars, "keepEngineOn")
        :AddTooltip("Keep your engine running"))
    
    -- Seatbelt
    self:AddOption(ToggleOption.new("Seatbelt")
        :AddToggleRef(vars, "seatbelt")
        :AddFunction(function()
            Seatbelt(vars.seatbelt)
        end)
        :AddTooltip("Prevent falling off vehicles"))
    
    -- Fix Vehicle
    self:AddOption(ButtonOption.new("Fix vehicle")
        :AddFunction(function()
            if IsInVehicle() then
                FixVehicle(GetCurrentVehicle())
                Renderer.Notify("Vehicle repaired!")
            else
                Renderer.Notify("Not in a vehicle")
            end
        end)
        :AddTooltip("Repair your vehicle"))
    
    -- Delete Vehicle
    self:AddOption(ButtonOption.new("Delete vehicle")
        :AddFunction(function()
            if IsInVehicle() then
                local veh = GetCurrentVehicle()
                ENTITY.SET_ENTITY_AS_MISSION_ENTITY(veh, true, true)
                VEHICLE.DELETE_VEHICLE(veh)
                Renderer.Notify("Vehicle deleted!")
            else
                Renderer.Notify("Not in a vehicle")
            end
        end)
        :AddTooltip("Delete your current vehicle"))
    
    self:AddOption(BreakOption.new("Modify Vehicle"))
    
    -- Auto Flip
    self:AddOption(ToggleOption.new("Auto flip")
        :AddToggleRef(vars, "autoFlip")
        :AddTooltip("Automatically flip your vehicle upright"))
    
    -- No Collision
    self:AddOption(ToggleOption.new("Vehicle no collisions")
        :AddToggleRef(vars, "noCollision")
        :AddFunction(function()
            NoCollision(vars.noCollision)
        end)
        :AddTooltip("Disable vehicle collisions"))
    
    -- Phase Through Vehicles
    self:AddOption(ToggleOption.new("Phase through vehicles")
        :AddToggleRef(vars, "phaseThroughVehicles")
        :AddFunction(function()
            PhaseThroughVehicles(vars.phaseThroughVehicles)
        end)
        :AddTooltip("Phase through other vehicles"))
    
    -- Ground to Earth
    self:AddOption(ButtonOption.new("Ground to earth")
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(GetCurrentVehicle(), 1.0)
                Renderer.Notify("Vehicle placed on ground")
            end
        end)
        :AddTooltip("Place vehicle on the ground"))
    
    self:AddOption(BreakOption.new("Misc"))
    
    -- Clone Vehicle
    self:AddOption(ButtonOption.new("Clone vehicle")
        :AddFunction(CloneVehicle)
        :AddTooltip("Clone your current vehicle"))

    -- Vehicle Nuke
    self:AddOption(ToggleOption.new("Vehicle nuke")
        :AddToggleRef(vars, "vehicleNuke")
        :AddTooltip("Press Spacebar or LS on Controller to set a blast zone and then press again to nuke area")
        :SetDonor())
    
    -- Show Area for Vehicle Nuke
    self:AddOption(ToggleOption.new("Show Area For Vehicle Nuke")
        :AddToggleRef(vars, "showNukeArea")
        :AddTooltip("Show the nuke blast zone marker"))
    
    self:AddOption(BreakOption.new("Visuals"))
    
    -- FIB Numberplate
    self:AddOption(ToggleOption.new("FIB numberplate")
        :AddToggleRef(vars, "fibNumberplate")
        :AddTooltip("Scrolling text on numberplate"))
    
    -- Onscreen Speedometer
    self:AddOption(ToggleOption.new("Onscreen speedometer")
        :AddToggleRef(vars, "onscreenSpeedo")
        :AddTooltip("Display speed on screen"))
    
    -- Numberplate Speedometer
    self:AddOption(ToggleOption.new("Numberplate speedometer")
        :AddToggleRef(vars, "numberplateSpeedo")
        :AddTooltip("Display speed on numberplate"))
    
    -- Rainbow Paint
    self:AddOption(ToggleOption.new("Rainbow paint")
        :AddToggleRef(vars, "rainbowPaint")
        :AddTooltip("Cycling rainbow paint colors"))
    
    -- Wheel Smoke Cycle
    self:AddOption(ToggleOption.new("Wheel smoke cycle")
        :AddToggleRef(vars, "smokeCycle")
        :AddTooltip("Random tire smoke colors"))
    
    -- Wash
    self:AddOption(ButtonOption.new("Wash")
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_DIRT_LEVEL(GetCurrentVehicle(), 0.0)
                Renderer.Notify("Vehicle washed!")
            end
        end)
        :AddTooltip("Clean your vehicle"))
    
    -- Dirty
    self:AddOption(ButtonOption.new("Dirty")
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_DIRT_LEVEL(GetCurrentVehicle(), 15.0)
                Renderer.Notify("Vehicle dirtied!")
            end
        end)
        :AddTooltip("Make your vehicle dirty"))
    
    -- Burn Shell
    self:AddOption(ToggleOption.new("Burn vehicle shell")
        :AddToggleRef(vars, "burnShell")
        :AddFunction(function()
            BurnShell(vars.burnShell)
        end)
        :AddTooltip("Make vehicle look burnt"))
    
    -- Opacity
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Opacity")
        :AddNumberRef(vars, "opacity", "%d%%", 5)
        :AddMin(0):AddMax(100)
        :AddFunction(function()
            if IsInVehicle() then
                local alpha = 255 - (vars.opacity * 2.55)
                ENTITY.SET_ENTITY_ALPHA(GetCurrentVehicle(), math.floor(alpha), false)
            end
        end)
        :AddTooltip("Set vehicle opacity"))
end

-- Feature update loop
function VehicleMenu:FeatureUpdate()
    local veh = nil
    if IsInVehicle() then
        veh = GetCurrentVehicle()
    end
    
    if vars.vehicleGodmode and veh then
        VehicleGodmode(veh, true)
    end
    
    if vars.seatbelt then
        Seatbelt(true)
    end
    
    if vars.vehicleInvisibility then
        InvisibleVehicle(true)
    end
    
    if vars.rainbowPaint and veh then
        RainbowVehicle(veh)
    end
    
    if vars.smokeCycle and veh then
        SmokeCycle()
    end
    
    if vars.autoFlip then
        AutoFlip()
    end
    
    if vars.burnShell then
        BurnShell(true)
    end
    
    if vars.fibNumberplate then
        FIBNumberplate()
    end
    
    if vars.onscreenSpeedo then
        OnScreenSpeedo()
    end
    
    if vars.numberplateSpeedo then
        NumberplateSpeedo()
    end
    
    if vars.noCollision then
        NoCollision(true)
    end
    
    if vars.phaseThroughVehicles then
        PhaseThroughVehicles(true)
    end

    if vars.vehicleNuke then
        VehicleNuke()
    end
    
    if vars.keepEngineOn and veh then
        VEHICLE.SET_VEHICLE_ENGINE_ON(veh, true, true, true)
        VEHICLE.SET_VEHICLE_LIGHTS(veh, 0)
    end
    
    if vars.autoRepair and veh then
        if VEHICLE.GET_VEHICLE_ENGINE_HEALTH(veh) < 1000 or
           VEHICLE.GET_VEHICLE_BODY_HEALTH(veh) < 1000 then
            VEHICLE.SET_VEHICLE_FIXED(veh)
        end
    end
    
    -- Update input component
    if saveInput and saveInput:IsVisible() then
        saveInput:Update()
    end
    
    -- Update submenus with FeatureUpdate
    if WeaponsMenu.GetInstance().FeatureUpdate then
        WeaponsMenu.GetInstance():FeatureUpdate()
    end
    if MovementMenu.GetInstance().FeatureUpdate then
        MovementMenu.GetInstance():FeatureUpdate()
    end
    if MultipliersMenu.GetInstance().FeatureUpdate then
        MultipliersMenu.GetInstance():FeatureUpdate()
    end
    if ParticlesMenu.GetInstance().FeatureUpdate then
        ParticlesMenu.GetInstance():FeatureUpdate()
    end
    if LSCMenu.GetInstance().FeatureUpdate then
        LSCMenu.GetInstance():FeatureUpdate()
    end
end

return VehicleMenu

