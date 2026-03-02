

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local TextInputComponent = require("Impulse/ImpulseLua/lib/ui/text_input_component")
local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")

-- Import teleport submenus
local GlitchedTeleportMenu = require("Impulse/ImpulseLua/submenus/teleport/glitched_teleport_menu")
local InsideTeleportMenu = require("Impulse/ImpulseLua/submenus/teleport/inside_teleport_menu")
local LandmarksTeleportMenu = require("Impulse/ImpulseLua/submenus/teleport/landmarks_teleport_menu")
local OnlineTeleportMenu = require("Impulse/ImpulseLua/submenus/teleport/online_teleport_menu")
local StoryModeTeleportMenu = require("Impulse/ImpulseLua/submenus/teleport/story_mode_teleport_menu")
local IPLTeleportMenu = require("Impulse/ImpulseLua/submenus/teleport/ipl_teleport_menu")
local CustomTeleportMenu = require("Impulse/ImpulseLua/submenus/teleport/custom_teleport_menu")

---@class TeleportMenu : Submenu
local TeleportMenu = setmetatable({}, { __index = Submenu })
TeleportMenu.__index = TeleportMenu

-- Blip color constants
local BlipColor = {
    White = 0,
    Red = 1,
    Green = 2,
    Blue = 3,
    Player = 4,
    Yellow = 5,
    Purple = 7,
    Vehicle = 38,
    Michael = 42,
    Franklin = 43,
    Trevor = 44,
    MissionRed = 49,
    MissionVehicle = 54,
    YellowMission = 66,
    YellowMission2 = 60,
    Waypoint = 83,
}

-- State
local teleportState = {
    transition = false,
    autoTeleportToWaypoint = false,
}



--- Sync local state with Cherax's actual state
local function SyncStates()
    teleportState.autoTeleportToWaypoint = FeatureState.Get("Auto Teleport To Waypoint")
end

-- ============================================
-- TELEPORT HELPER FUNCTIONS
-- ============================================

--- Get the player's current entity (vehicle if in one, otherwise ped)
---@return number entity handle
local function GetPlayerEntity()
    local ped = PLAYER.PLAYER_PED_ID()
    if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        return PED.GET_VEHICLE_PED_IS_IN(ped, false)
    end
    return ped
end

--- Get waypoint coordinates
---@return table|nil coords {x, y, z} or nil if no waypoint
local function GetWaypointCoords()
    local blipIterator = HUD.GET_WAYPOINT_BLIP_ENUM_ID()
    local blip = HUD.GET_FIRST_BLIP_INFO_ID(blipIterator)
    
    while HUD.DOES_BLIP_EXIST(blip) do
        if HUD.GET_BLIP_INFO_ID_TYPE(blip) == 4 then
            local coords = HUD.GET_BLIP_INFO_ID_COORD(blip)
            return { x = coords.x, y = coords.y, z = coords.z }
        end
        blip = HUD.GET_NEXT_BLIP_INFO_ID(blipIterator)
    end
    
    return nil
end

--- Teleport entity to coordinates
---@param x number
---@param y number
---@param z number
local function TeleportToCoords(x, y, z)
    local entity = GetPlayerEntity()
    ENTITY.SET_ENTITY_COORDS(entity, x, y, z, false, false, false, true)
end

--- Teleport to waypoint with ground detection
local function TeleportToWaypoint()
    local coords = GetWaypointCoords()
    
    if not coords then
        Renderer.Notify("No waypoint has been set!")
        return
    end
    
    local entity = GetPlayerEntity()
    local groundFound = false
    local groundCheckHeights = { 100.0, 150.0, 50.0, 0.0, 200.0, 250.0, 300.0, 350.0, 400.0, 450.0, 500.0, 550.0, 600.0, 650.0, 700.0, 750.0, 800.0 }
    
    for _, checkHeight in ipairs(groundCheckHeights) do
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entity, coords.x, coords.y, checkHeight, false, false, true)
        Script.Yield(100)
        
        local success, groundZ = GTA.GetGroundZ(coords.x, coords.y)
        if success then
            groundFound = true
            coords.z = groundZ + 3.0
            break
        end
    end
    
    if not groundFound then
        coords.z = 1000.0
        -- Give parachute
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PLAYER.PLAYER_PED_ID(), 0xFBAB5776, 1, false)
    end
    
    TeleportToCoords(coords.x, coords.y, coords.z)
    Renderer.Notify("Teleported to waypoint")
end

--- Teleport forward
local function TeleportForward()
    local ped = PLAYER.PLAYER_PED_ID()
    local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
    local dir = ENTITY.GET_ENTITY_FORWARD_VECTOR(ped)
    
    TeleportToCoords(pos.x + (dir.x * 8.0), pos.y + (dir.y * 8.0), pos.z - 0.5)
end

--- Teleport up
local function TeleportUp()
    local ped = PLAYER.PLAYER_PED_ID()
    local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
    
    TeleportToCoords(pos.x, pos.y, pos.z + 8)
end

--- Get closest vehicle
---@return number vehicle handle or 0
local function GetClosestVehicle()
    local ped = PLAYER.PLAYER_PED_ID()
    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
    local vehicle = VEHICLE.GET_CLOSEST_VEHICLE(coords.x, coords.y, coords.z, 10000.0, 0, 100359)
    
    if ENTITY.DOES_ENTITY_EXIST(vehicle) then
        return vehicle
    end
    return 0
end

--- Get free seat in vehicle
---@param vehicle number
---@return number seat index
local function GetFreeSeat(vehicle)
    local maxSeats = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle)
    for i = -1, maxSeats - 1 do
        if VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, i, false) then
            return i
        end
    end
    return -1
end

--- Teleport to nearest vehicle
---@param asDrive boolean if true, become driver; if false, any free seat
local function TeleportToNearestVehicle(asDriver)
    local vehicle = GetClosestVehicle()
    
    if vehicle == 0 then
        Renderer.Notify("No vehicle found nearby")
        return
    end
    
    local ped = PLAYER.PLAYER_PED_ID()
    
    if asDriver then
        -- Kick current driver
        local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1, true)
        if ENTITY.DOES_ENTITY_EXIST(driver) and PED.IS_PED_IN_ANY_VEHICLE(driver, false) then
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(driver)
        end
        PED.SET_PED_INTO_VEHICLE(ped, vehicle, -1)
    else
        PED.SET_PED_INTO_VEHICLE(ped, vehicle, GetFreeSeat(vehicle))
    end
    
    Renderer.Notify("Teleported to vehicle")
end

--- Teleport to mission objective
local function TeleportToMissionObjective()
    local blipCoords = nil
    
    -- Check for blip type 38 (property/garage)
    local blip = HUD.GET_FIRST_BLIP_INFO_ID(38)
    while HUD.DOES_BLIP_EXIST(blip) do
        if HUD.GET_BLIP_COLOUR(blip) == 0x0 then
            blipCoords = HUD.GET_BLIP_COORDS(blip)
            break
        end
        blip = HUD.GET_NEXT_BLIP_INFO_ID(38)
    end
    
    -- Check for blip type 431
    if not blipCoords then
        blip = HUD.GET_FIRST_BLIP_INFO_ID(431)
        while HUD.DOES_BLIP_EXIST(blip) do
            if HUD.GET_BLIP_COLOUR(blip) == 0x3C then
                blipCoords = HUD.GET_BLIP_COORDS(blip)
                break
            end
            blip = HUD.GET_NEXT_BLIP_INFO_ID(431)
        end
    end
    
    -- Check for blip type 1 (standard objective)
    if not blipCoords then
        blip = HUD.GET_FIRST_BLIP_INFO_ID(1)
        while HUD.DOES_BLIP_EXIST(blip) do
            local color = HUD.GET_BLIP_COLOUR(blip)
            if color == 0x42 or color == 0x5 or color == 0x3C or color == 0x2 then
                blipCoords = HUD.GET_BLIP_COORDS(blip)
                break
            end
            blip = HUD.GET_NEXT_BLIP_INFO_ID(1)
        end
    end
    
    if blipCoords then
        TeleportToCoords(blipCoords.x, blipCoords.y, blipCoords.z)
        Renderer.Notify("Teleported to objective")
    else
        Renderer.Notify("No objective found")
    end
end

--- Teleport to a specific blip type
---@param blipId number
---@param notFoundMsg string
local function TeleportToBlip(blipId, notFoundMsg)
    local blip = HUD.GET_FIRST_BLIP_INFO_ID(blipId)
    
    if HUD.DOES_BLIP_EXIST(blip) then
        local coords = HUD.GET_BLIP_COORDS(blip)
        TeleportToCoords(coords.x, coords.y, coords.z)
        Renderer.Notify("Teleported")
    else
        Renderer.Notify(notFoundMsg)
    end
end

--- Teleport to blip with specific color
---@param blipId number
---@param color number
---@param notFoundMsg string
local function TeleportToBlipColor(blipId, color, notFoundMsg)
    local blip = HUD.GET_FIRST_BLIP_INFO_ID(blipId)
    
    while HUD.DOES_BLIP_EXIST(blip) do
        if HUD.GET_BLIP_COLOUR(blip) == color then
            local coords = HUD.GET_BLIP_COORDS(blip)
            TeleportToCoords(coords.x, coords.y, coords.z)
            Renderer.Notify("Teleported")
            return
        end
        blip = HUD.GET_NEXT_BLIP_INFO_ID(blipId)
    end
    
    Renderer.Notify(notFoundMsg)
end

--- Teleport to personal vehicle
local function TeleportToPersonalVehicle()
    -- PV uses blip IDs 225-226
    for i = 225, 226 do
        local blip = HUD.GET_FIRST_BLIP_INFO_ID(i)
        if HUD.DOES_BLIP_EXIST(blip) then
            local coords = HUD.GET_BLIP_COORDS(blip)
            TeleportToCoords(coords.x, coords.y, coords.z)
            
            -- Try to get into the vehicle
            local vehicle = VEHICLE.GET_CLOSEST_VEHICLE(coords.x, coords.y, coords.z, 5.0, 0, 70)
            if ENTITY.DOES_ENTITY_EXIST(vehicle) then
                PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), vehicle, GetFreeSeat(vehicle))
            end
            
            Renderer.Notify("Teleported to personal vehicle")
            return
        end
    end
    
    Renderer.Notify("Personal vehicle not found")
end



-- ============================================
-- MENU CLASS
-- ============================================

local instance = nil

-- Feature hashes for Cherax teleport system
local TELEPORT_NAME_HASH = 3823043923
local SAVE_TELEPORT_HASH = 1461566178

--- Get singleton instance
---@return TeleportMenu
function TeleportMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Teleport"), TeleportMenu)
        
        -- Initialize save teleport input
        instance.saveTeleportInput = TextInputComponent.new()
        instance.saveTeleportInput:SetTitle("Teleport Name")
        instance.saveTeleportInput:SetCallback(function(teleportName)
            if teleportName and #teleportName > 0 then
                -- Use Cherax's built-in save feature (same pattern as wardrobe)
                Script.QueueJob(function()
                    -- Set the teleport name using feature name
                    local nameFeature = FeatureMgr.GetFeatureByName("Teleport Name")
                    if nameFeature then
                        nameFeature:SetStringValue(teleportName)
                        Script.Yield(1000) -- Wait for name to be set
                        
                        -- Trigger save callback using hash 1461566178
                        FeatureMgr.TriggerFeatureCallback(1461566178)
                        Renderer.Notify("Saved teleport: " .. teleportName)
                    else
                        Renderer.Notify("Teleport Name feature not found")
                    end
                end)
            end
        end)
        
        -- Sync states before init
        SyncStates()
        instance:Init()
    end
    return instance
end

function TeleportMenu:Init()
    -- Main teleport options
    self:AddOption(ButtonOption.new("Teleport to waypoint")
        :AddFunction(TeleportToWaypoint)
        :AddTooltip("Teleport to your map waypoint")
        :AddHotkey())

    self:AddOption(ToggleOption.new("Auto Teleport To Waypoint")
        :AddToggleRef(teleportState, "autoTeleportToWaypoint")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Auto Teleport To Waypoint"):Toggle(teleportState.autoTeleportToWaypoint)
        end)
        :AddTooltip("Automatically teleport to waypoint"))
    
    self:AddOption(ToggleOption.new("Teleport transition")
        :AddToggleRef(teleportState, "transition")
        :AddTooltip("Use camera transition when teleporting")
        :AddHotkey())
    
    -- Custom saved locations section
    self:AddOption(BreakOption.new("Custom saved locations"))
    
    -- Save current location button (uses Cherax's built-in system)
    self:AddOption(ButtonOption.new("Save current location")
        :AddFunction(function()
            if self.saveTeleportInput then
                self.saveTeleportInput:Show()
            end
        end)
        :AddTooltip("Save your current position to Cherax Teleports folder")
        :AddHotkey())
    
    -- Custom teleport submenu (load)
    self.customTeleportSubmenu = CustomTeleportMenu.new()
    self.customTeleportSubmenu:Init()
    self:AddOption(SubmenuOption.new("Load custom locations")
        :AddSubmenu(self.customTeleportSubmenu)
        :AddTooltip("Load saved teleport locations")
        :AddHotkey())
    
    -- Locations section
    self:AddOption(BreakOption.new("Locations"))
    
    -- Online submenu
    self.onlineSubmenu = OnlineTeleportMenu.new()
    self.onlineSubmenu:Init()
    self:AddOption(SubmenuOption.new("Online")
        :AddSubmenu(self.onlineSubmenu)
        :AddTooltip("Teleports to online locations")
        :AddHotkey())
    
    -- Landmarks submenu
    self.landmarksSubmenu = LandmarksTeleportMenu.new()
    self.landmarksSubmenu:Init()
    self:AddOption(SubmenuOption.new("Landmarks")
        :AddSubmenu(self.landmarksSubmenu)
        :AddTooltip("Teleports to landmark locations")
        :AddHotkey())
    
    -- Inside submenu
    self.insideSubmenu = InsideTeleportMenu.new()
    self.insideSubmenu:Init()
    self:AddOption(SubmenuOption.new("Inside")
        :AddSubmenu(self.insideSubmenu)
        :AddTooltip("Teleports to inside/interior locations")
        :AddHotkey())
    
    -- Story mode submenu
    self.storyModeSubmenu = StoryModeTeleportMenu.new()
    self.storyModeSubmenu:Init()
    self:AddOption(SubmenuOption.new("Story mode locations")
        :AddSubmenu(self.storyModeSubmenu)
        :AddTooltip("Teleports to story mode character locations")
        :AddHotkey())
    
    -- Glitched submenu
    self.glitchedSubmenu = GlitchedTeleportMenu.new()
    self.glitchedSubmenu:Init()
    self:AddOption(SubmenuOption.new("Glitched locations")
        :AddSubmenu(self.glitchedSubmenu)
        :AddTooltip("Teleports to glitched locations")
        :AddHotkey())
    
    -- IPL submenu
    self.iplSubmenu = IPLTeleportMenu.new()
    self.iplSubmenu:Init()
    self:AddOption(SubmenuOption.new("IPL Locations")
        :AddSubmenu(self.iplSubmenu)
        :AddTooltip("Teleports to IPL locations with auto-loading")
        :AddHotkey())
    
    -- Blips section
    self:AddOption(BreakOption.new("Blips"))
    
    self:AddOption(ButtonOption.new("Teleport to objective")
        :AddFunction(TeleportToMissionObjective)
        :AddTooltip("Teleport to current mission objective")
        :AddHotkey())
    
    self:AddOption(ButtonOption.new("Teleport to apartment")
        :AddFunction(function() TeleportToBlip(40, "Apartment not found") end)
        :AddTooltip("Teleport to your apartment")
        :AddHotkey())
    
    self:AddOption(ButtonOption.new("Teleport to yacht")
        :AddFunction(function() TeleportToBlip(455, "Yacht not found") end)
        :AddTooltip("Teleport to your yacht")
        :AddHotkey())
    
    self:AddOption(ButtonOption.new("Teleport to office")
        :AddFunction(function() TeleportToBlip(475, "Office not found") end)
        :AddTooltip("Teleport to your office")
        :AddHotkey())
    
    self:AddOption(ButtonOption.new("Teleport to clubhouse")
        :AddFunction(function() TeleportToBlip(492, "Clubhouse not found") end)
        :AddTooltip("Teleport to MC clubhouse")
        :AddHotkey())
    
    self:AddOption(ButtonOption.new("Teleport to bunker")
        :AddFunction(function() TeleportToBlip(557, "Bunker not found") end)
        :AddTooltip("Teleport to your bunker")
        :AddHotkey())
    
    self:AddOption(ButtonOption.new("Teleport to own package")
        :AddFunction(function() TeleportToBlipColor(501, BlipColor.Green, "Own package not found") end)
        :AddTooltip("Teleport to your MC package")
        :AddHotkey())
    
    self:AddOption(ButtonOption.new("Teleport to enemy package")
        :AddFunction(function() TeleportToBlipColor(501, BlipColor.Red, "Enemy package not found") end)
        :AddTooltip("Teleport to enemy MC package")
        :AddHotkey())
    
    -- Vehicle section
    self:AddOption(BreakOption.new("Vehicle"))
    
    self:AddOption(ButtonOption.new("Nearest car (become driver)")
        :AddFunction(function() TeleportToNearestVehicle(true) end)
        :AddTooltip("Teleport to and drive nearest vehicle")
        :AddHotkey())
    
    self:AddOption(ButtonOption.new("Nearest car (any free seat)")
        :AddFunction(function() TeleportToNearestVehicle(false) end)
        :AddTooltip("Teleport to nearest vehicle (passenger)")
        :AddHotkey())
    
    self:AddOption(ButtonOption.new("Teleport to personal vehicle")
        :AddFunction(TeleportToPersonalVehicle)
        :AddTooltip("Teleport to your personal vehicle")
        :AddHotkey())
    
    -- Directional section
    self:AddOption(BreakOption.new("Directional"))
    
    self:AddOption(ButtonOption.new("Teleport forward")
        :AddFunction(TeleportForward)
        :AddTooltip("Teleport 8 meters forward")
        :AddHotkey())
    
    self:AddOption(ButtonOption.new("Teleport up")
        :AddFunction(TeleportUp)
        :AddTooltip("Teleport 8 meters up")
        :AddHotkey())
end

function TeleportMenu:FeatureUpdate()
    -- Update save teleport text input
    if self.saveTeleportInput then
        self.saveTeleportInput:Update()
    end
    
    -- Update custom teleport submenu for its text input (if needed)
    if self.customTeleportSubmenu and self.customTeleportSubmenu.FeatureUpdate then
        self.customTeleportSubmenu:FeatureUpdate()
    end
end

return TeleportMenu
