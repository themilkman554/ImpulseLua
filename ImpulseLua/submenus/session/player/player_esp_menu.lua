--[[
    Impulse Lua - Player ESP Menu
    Extra Sensory Perception options for selected player
    Port of ESPMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local ColorOption = require("Impulse/ImpulseLua/lib/options/color")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local PlayerMenu = nil -- Lazy loaded

local PlayerESPMenu = setmetatable({}, { __index = Submenu })
PlayerESPMenu.__index = PlayerESPMenu

local instance = nil

-- ESP Settings (global for all players)
local vars = {
    ESPColor = { r = 255, g = 0, b = 0, a = 255 },
    ESPLOSColor = { r = 0, g = 255, b = 0, a = 255 },  -- Line of sight color
    ESPLOSGREEN = true
}

-- Per-player ESP state
local playerESPState = {}

local function GetPlayerESPState(playerId)
    if not playerESPState[playerId] then
        playerESPState[playerId] = {
            nameESP = false,
            lineESP = false,
            boxESP = false,
            headMarkerESP = false,
            footMarkerESP = false,
            infoESP = false,
            bonesESP = false,
            skylineESP = false,
            lineLOSESP = false
        }
    end
    return playerESPState[playerId]
end

-- ============================================
-- Helper Functions
-- ============================================

local function GetSelectedPlayerId()
    if not PlayerMenu then
        PlayerMenu = require("Impulse/ImpulseLua/submenus/session/player_menu")
    end
    return PlayerMenu.targetPlayer or -1
end

local function GetSelectedPlayerName()
    if not PlayerMenu then
        PlayerMenu = require("Impulse/ImpulseLua/submenus/session/player_menu")
    end
    local playerId = PlayerMenu.targetPlayer or -1
    if playerId < 0 then return "Unknown" end
    return PLAYER.GET_PLAYER_NAME(playerId) or "Unknown"
end

-- ============================================
-- Bone IDs for skeleton ESP
-- ============================================

local BONE = {
    SKEL_Pelvis = 0x2e28,
    SKEL_L_Foot = 0x3779,
    SKEL_L_Toe0 = 0x83c,
    SKEL_R_Foot = 0xcc4d,
    SKEL_R_Toe0 = 0x512d,
    MH_L_Knee = 0xb3fe,
    MH_R_Knee = 0x3fcf,
    SKEL_Neck_1 = 0x9995,
    SKEL_Head = 0x796e,
    IK_Head = 0x322c,
    SKEL_L_UpperArm = 0xb1c5,
    SKEL_L_Forearm = 0xeeeb,
    SKEL_L_Hand = 0x49d9,
    SKEL_R_UpperArm = 0x9d4d,
    SKEL_R_Forearm = 0x6e5c,
    SKEL_R_Hand = 0xdead,
}

-- ============================================
-- ESP Drawing Functions
-- ============================================

local function DrawBone(ped, bone1, bone2, color)
    local start = PED.GET_PED_BONE_COORDS(ped, bone1, 0, 0, 0)
    local endPos = PED.GET_PED_BONE_COORDS(ped, bone2, 0, 0, 0)
    GRAPHICS.DRAW_LINE(start.x, start.y, start.z, endPos.x, endPos.y, endPos.z, 
        color.r, color.g, color.b, color.a)
end

local function NameESP(playerId)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not ped or ped == 0 or not ENTITY.DOES_ENTITY_EXIST(ped) then return end
    
    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
    local screenX, screenY = 0.0, 0.0
    local onScreen, x, y = GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(coords.x, coords.y, coords.z + 1.0)
    
    if onScreen then
        local name = PLAYER.GET_PLAYER_NAME(playerId) or "Unknown"
        HUD.SET_TEXT_FONT(4)
        HUD.SET_TEXT_SCALE(0.30, 0.30)
        HUD.SET_TEXT_COLOUR(255, 255, 255, 255)
        HUD.SET_TEXT_OUTLINE()
        HUD.SET_TEXT_CENTRE(true)
        HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
        HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(name)
        HUD.END_TEXT_COMMAND_DISPLAY_TEXT(x, y, 0)
    end
end

local function LineESP(playerId, useLOS)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not ped or ped == 0 or not ENTITY.DOES_ENTITY_EXIST(ped) then return end
    
    local myPed = PLAYER.PLAYER_PED_ID()
    local myCoords = ENTITY.GET_ENTITY_COORDS(myPed, true)
    local targetCoords = ENTITY.GET_ENTITY_COORDS(ped, true)
    
    local color = vars.ESPColor
    if useLOS and vars.ESPLOSGREEN then
        if ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(myPed, ped, 1) then
            color = vars.ESPLOSColor
        end
    end
    
    GRAPHICS.DRAW_LINE(myCoords.x, myCoords.y, myCoords.z, 
        targetCoords.x, targetCoords.y, targetCoords.z,
        color.r, color.g, color.b, color.a)
end

local function HeadMarkerESP(playerId)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not ped or ped == 0 or not ENTITY.DOES_ENTITY_EXIST(ped) then return end
    
    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
    local c = vars.ESPColor
    
    GRAPHICS.DRAW_MARKER(21, coords.x, coords.y, coords.z + 1.5, 
        0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.9, 0.9, 0.9,
        c.r, c.g, c.b, c.a, true, false, 2, true, nil, nil, false)
end

local function FootMarkerESP(playerId)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not ped or ped == 0 or not ENTITY.DOES_ENTITY_EXIST(ped) then return end
    
    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
    local c = vars.ESPColor
    
    GRAPHICS.DRAW_MARKER(25, coords.x, coords.y, coords.z - 0.90, 
        0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.9, 0.9, 0.9,
        c.r, c.g, c.b, c.a, true, false, 2, true, nil, nil, false)
end

local function SkyLineESP(playerId)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not ped or ped == 0 or not ENTITY.DOES_ENTITY_EXIST(ped) then return end
    
    local myPed = PLAYER.PLAYER_PED_ID()
    local myCoords = ENTITY.GET_ENTITY_COORDS(myPed, true)
    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
    local c = vars.ESPColor
    
    local distance = MISC.GET_DISTANCE_BETWEEN_COORDS(myCoords.x, myCoords.y, myCoords.z, coords.x, coords.y, coords.z, true)
    
    local size = 0.9
    local height = 200.0
    if distance > 300.0 then
        size = 6.9
        height = 500.0
    end
    
    GRAPHICS.DRAW_MARKER(1, coords.x, coords.y, coords.z + 1.5, 
        0.0, 0.0, 0.0, 0, 0.0, 0.0, size, size, height,
        c.r, c.g, c.b, c.a, false, false, 2, true, nil, nil, false)
end

local function InfoESP(playerId)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not ped or ped == 0 or not ENTITY.DOES_ENTITY_EXIST(ped) then return end
    
    local myPed = PLAYER.PLAYER_PED_ID()
    local myCoords = ENTITY.GET_ENTITY_COORDS(myPed, true)
    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
    
    local onScreen, x, y = GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(coords.x, coords.y, coords.z)
    
    if onScreen then
        local distance = MISC.GET_DISTANCE_BETWEEN_COORDS(myCoords.x, myCoords.y, myCoords.z, coords.x, coords.y, coords.z, true)
        
        if distance < 2000.0 then
            local speed = ENTITY.GET_ENTITY_SPEED(ped)
            local health = ENTITY.GET_ENTITY_HEALTH(ped)
            local name = PLAYER.GET_PLAYER_NAME(playerId) or "Unknown"
            
            -- Check vehicle
            local vehName = "On Foot"
            if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                if veh and veh ~= 0 then
                    local model = ENTITY.GET_ENTITY_MODEL(veh)
                    local displayName = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(model)
                    local label = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(displayName)
                    if label and label ~= "NULL" then
                        vehName = label
                    else
                        vehName = displayName or "Vehicle"
                    end
                end
            end
            
            local text = string.format(" ~s~%s\n Vehicle: %s\n Speed: %.02f\n Health: %i\n Distance: %.02f", 
                name, vehName, speed, health, distance)
            
            HUD.SET_TEXT_FONT(4)
            HUD.SET_TEXT_SCALE(0.30, 0.30)
            HUD.SET_TEXT_COLOUR(255, 255, 255, 255)
            HUD.SET_TEXT_OUTLINE()
            HUD.SET_TEXT_WRAP(0.0, 1.0)
            HUD.SET_TEXT_CENTRE(false)
            HUD.SET_TEXT_EDGE(1, 0, 0, 0, 205)
            HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
            HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
            HUD.END_TEXT_COMMAND_DISPLAY_TEXT(x, y, 0)
        end
    end
end

local function BoxESP(playerId)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not ped or ped == 0 or not ENTITY.DOES_ENTITY_EXIST(ped) then return end
    
    local myPed = PLAYER.PLAYER_PED_ID()
    if not ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(myPed, ped, 1) then return end
    
    local coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0, 0, 0)
    local c = vars.ESPColor
    
    -- Draw box lines
    -- Top box
    GRAPHICS.DRAW_LINE(coords.x + 0.5, coords.y + 0.5, coords.z + 0.75, coords.x + 0.5, coords.y - 0.5, coords.z + 0.75, c.r, c.g, c.b, c.a)
    GRAPHICS.DRAW_LINE(coords.x + 0.5, coords.y - 0.5, coords.z + 0.75, coords.x - 0.5, coords.y - 0.5, coords.z + 0.75, c.r, c.g, c.b, c.a)
    GRAPHICS.DRAW_LINE(coords.x - 0.5, coords.y - 0.5, coords.z + 0.75, coords.x - 0.5, coords.y + 0.5, coords.z + 0.75, c.r, c.g, c.b, c.a)
    GRAPHICS.DRAW_LINE(coords.x - 0.5, coords.y + 0.5, coords.z + 0.75, coords.x + 0.5, coords.y + 0.5, coords.z + 0.75, c.r, c.g, c.b, c.a)
    -- Bottom box
    GRAPHICS.DRAW_LINE(coords.x + 0.5, coords.y + 0.5, coords.z - 0.75, coords.x + 0.5, coords.y - 0.5, coords.z - 0.75, c.r, c.g, c.b, c.a)
    GRAPHICS.DRAW_LINE(coords.x + 0.5, coords.y - 0.5, coords.z - 0.75, coords.x - 0.5, coords.y - 0.5, coords.z - 0.75, c.r, c.g, c.b, c.a)
    GRAPHICS.DRAW_LINE(coords.x - 0.5, coords.y - 0.5, coords.z - 0.75, coords.x - 0.5, coords.y + 0.5, coords.z - 0.75, c.r, c.g, c.b, c.a)
    GRAPHICS.DRAW_LINE(coords.x - 0.5, coords.y + 0.5, coords.z - 0.75, coords.x + 0.5, coords.y + 0.5, coords.z - 0.75, c.r, c.g, c.b, c.a)
    -- Vertical lines
    GRAPHICS.DRAW_LINE(coords.x + 0.5, coords.y + 0.5, coords.z - 0.75, coords.x + 0.5, coords.y + 0.5, coords.z + 0.75, c.r, c.g, c.b, c.a)
    GRAPHICS.DRAW_LINE(coords.x + 0.5, coords.y - 0.5, coords.z - 0.75, coords.x + 0.5, coords.y - 0.5, coords.z + 0.75, c.r, c.g, c.b, c.a)
    GRAPHICS.DRAW_LINE(coords.x - 0.5, coords.y - 0.5, coords.z - 0.75, coords.x - 0.5, coords.y - 0.5, coords.z + 0.75, c.r, c.g, c.b, c.a)
    GRAPHICS.DRAW_LINE(coords.x - 0.5, coords.y + 0.5, coords.z - 0.75, coords.x - 0.5, coords.y + 0.5, coords.z + 0.75, c.r, c.g, c.b, c.a)
end

local function BonesESP(playerId)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    if not ped or ped == 0 or not ENTITY.DOES_ENTITY_EXIST(ped) then return end
    
    local c = vars.ESPColor
    
    -- Right leg
    DrawBone(ped, BONE.SKEL_R_Foot, BONE.MH_R_Knee, c)
    DrawBone(ped, BONE.SKEL_R_Toe0, BONE.SKEL_R_Foot, c)
    DrawBone(ped, BONE.MH_R_Knee, BONE.SKEL_Pelvis, c)
    
    -- Left leg
    DrawBone(ped, BONE.SKEL_L_Foot, BONE.MH_L_Knee, c)
    DrawBone(ped, BONE.SKEL_L_Toe0, BONE.SKEL_L_Foot, c)
    DrawBone(ped, BONE.MH_L_Knee, BONE.SKEL_Pelvis, c)
    
    -- Spine
    DrawBone(ped, BONE.SKEL_Pelvis, BONE.SKEL_Neck_1, c)
    
    -- Right arm
    DrawBone(ped, BONE.SKEL_Neck_1, BONE.SKEL_R_UpperArm, c)
    DrawBone(ped, BONE.SKEL_R_UpperArm, BONE.SKEL_R_Forearm, c)
    DrawBone(ped, BONE.SKEL_R_Forearm, BONE.SKEL_R_Hand, c)
    
    -- Left arm
    DrawBone(ped, BONE.SKEL_Neck_1, BONE.SKEL_L_UpperArm, c)
    DrawBone(ped, BONE.SKEL_L_UpperArm, BONE.SKEL_L_Forearm, c)
    DrawBone(ped, BONE.SKEL_L_Forearm, BONE.SKEL_L_Hand, c)
    
    -- Head
    DrawBone(ped, BONE.SKEL_Neck_1, BONE.SKEL_Head, c)
    
    -- Draw head box
    local headCoords = PED.GET_PED_BONE_COORDS(ped, BONE.IK_Head, 0, 0, 0)
    GRAPHICS.DRAW_BOX(headCoords.x + 0.05, headCoords.y + 0.05, headCoords.z + 0.075,
        headCoords.x - 0.05, headCoords.y - 0.05, headCoords.z - 0.05,
        c.r, c.g, c.b, c.a)
end

-- ============================================
-- Menu Definition
-- ============================================

function PlayerESPMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Extra sensory perception"), PlayerESPMenu)
        instance:Init()
    end
    return instance
end

function PlayerESPMenu:Init()
    -- ESP Color (matches C++ ColorOption)
    self:AddOption(ColorOption.new("ESP Color")
        :AddColor(vars.ESPColor)
        :AddTooltip("This will change all esp lines and boxes to match your chosen color"))
    
    -- ESP name
    self:AddOption(ToggleOption.new("ESP name", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            state.nameESP = value
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            return state.nameESP
        end
        return false
    end)
        :AddTooltip("ESP name"))
    
    -- ESP box
    self:AddOption(ToggleOption.new("ESP box", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            state.boxESP = value
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            return state.boxESP
        end
        return false
    end)
        :AddTooltip("ESP box"))
    
    -- ESP line
    self:AddOption(ToggleOption.new("ESP line", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            state.lineESP = value
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            return state.lineESP
        end
        return false
    end)
        :AddTooltip("ESP line"))
    
    -- ESP line of sight line (only visible when ESP line is enabled)
    self:AddOption(ToggleOption.new("ESP line of sight line", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            state.lineLOSESP = value
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            return state.lineLOSESP
        end
        return false
    end)
        :AddRequirement(function()
            local playerId = GetSelectedPlayerId()
            if playerId >= 0 then
                local state = GetPlayerESPState(playerId)
                return state.lineESP
            end
            return false
        end)
        :AddTooltip("This will highlight the ESP line when a player in line of sight of your ped"))
    
    -- ESP line of sight line color (only visible when ESP line is enabled)
    self:AddOption(ColorOption.new("ESP line of sight line color")
        :AddColor(vars.ESPLOSColor)
        :AddRequirement(function()
            local playerId = GetSelectedPlayerId()
            if playerId >= 0 then
                local state = GetPlayerESPState(playerId)
                return state.lineESP
            end
            return false
        end)
        :AddTooltip("This will change the highlight color for the option above"))
    
    -- ESP head marker
    self:AddOption(ToggleOption.new("ESP head marker", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            state.headMarkerESP = value
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            return state.headMarkerESP
        end
        return false
    end)
        :AddTooltip("ESP head marker"))
    
    -- ESP foot marker
    self:AddOption(ToggleOption.new("ESP foot marker", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            state.footMarkerESP = value
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            return state.footMarkerESP
        end
        return false
    end)
        :AddTooltip("ESP foot marker"))
    
    -- ESP info
    self:AddOption(ToggleOption.new("ESP info", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            state.infoESP = value
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            return state.infoESP
        end
        return false
    end)
        :AddTooltip("ESP info"))
    
    -- ESP skel (matches C++ name)
    self:AddOption(ToggleOption.new("ESP skel", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            state.bonesESP = value
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            return state.bonesESP
        end
        return false
    end)
        :AddTooltip("ESP skel"))
    
    -- ESP sky line
    self:AddOption(ToggleOption.new("ESP sky line", function(value)
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            state.skylineESP = value
        end
    end, function()
        local playerId = GetSelectedPlayerId()
        if playerId >= 0 then
            local state = GetPlayerESPState(playerId)
            return state.skylineESP
        end
        return false
    end)
        :AddTooltip("ESP sky line"))
end

-- Background update - draw ESP for all players with enabled options
function PlayerESPMenu:FeatureUpdate()
    local players = Players.Get()
    if not players then return end
    
    local localPlayer = PLAYER.PLAYER_ID()
    
    for _, player in ipairs(players) do
        -- Handle both cases: player could be an object with .Id or just a raw number
        local playerId = type(player) == "table" and player.Id or player
        if playerId and playerId ~= localPlayer then
            local state = playerESPState[playerId]
            if state then
                if state.nameESP and not state.infoESP then
                    NameESP(playerId)
                end
                if state.lineESP then
                    LineESP(playerId, state.lineLOSESP)
                end
                if state.headMarkerESP then
                    HeadMarkerESP(playerId)
                end
                if state.footMarkerESP then
                    FootMarkerESP(playerId)
                end
                if state.infoESP then
                    InfoESP(playerId)
                end
                if state.skylineESP then
                    SkyLineESP(playerId)
                end
                if state.boxESP then
                    BoxESP(playerId)
                end
                if state.bonesESP then
                    BonesESP(playerId)
                end
            end
        end
    end
end

return PlayerESPMenu
