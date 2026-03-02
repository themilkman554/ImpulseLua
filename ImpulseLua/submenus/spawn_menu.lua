local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local TextInputComponent = require("Impulse/ImpulseLua/lib/ui/text_input_component")

-- Import submenus
local SpawnVehicleMenu = require("Impulse/ImpulseLua/submenus/spawn/spawn_vehicle_menu")
local SpawnPedMenu = require("Impulse/ImpulseLua/submenus/spawn/spawn_ped_menu")
local SpawnObjectMenu = require("Impulse/ImpulseLua/submenus/spawn/spawn_object_menu")
local LoadingMenu = require("Impulse/ImpulseLua/submenus/spawn/loading_menu")
local MapModsMenu = require("Impulse/ImpulseLua/submenus/spawn/map_mods_menu")

local SpawnMenu = setmetatable({}, { __index = Submenu })
SpawnMenu.__index = SpawnMenu

local instance = nil

-- State variables
local vars = {
    creatorMode = false,
    drawMarker = false,
    creatorModeDistance = 10.0,
    blip = false,
    isObjectAPed = false,
    selectedCreatorObject = "prop_alien_egg_01" -- Default
}

-- Free cam state (our own camera, not the built-in one)
local freeCamState = {
    camHandle = 0,
    posX = 0.0,
    posY = 0.0,
    posZ = 0.0,
    rotX = 0.0,
    rotY = 0.0,
    rotZ = 0.0,
    moveSpeed = 0.5,
    fastMoveSpeed = 2.0,
    rotSpeed = 3.0,
    initialized = false,
    loopRunning = false
}

-- Spawned entities tracking
local spawnedEntities = {}

-- Helper: Rotation to Direction
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

-- Get coords in front of camera
local function GetFrontCoords(dist)
    local forward = RotationToDirection({x = freeCamState.rotX, y = freeCamState.rotY, z = freeCamState.rotZ})
    return {
        x = freeCamState.posX + forward.x * dist,
        y = freeCamState.posY + forward.y * dist,
        z = freeCamState.posZ + forward.z * dist
    }
end

-- Initialize free cam
local function InitFreeCam()
    if freeCamState.initialized then return end
    
    pcall(function()
        local playerPed = PLAYER.PLAYER_PED_ID()
        local playerCoords = ENTITY.GET_ENTITY_COORDS(playerPed, true)
        local playerHeading = ENTITY.GET_ENTITY_HEADING(playerPed)
        
        freeCamState.posX = playerCoords.x
        freeCamState.posY = playerCoords.y
        freeCamState.posZ = playerCoords.z + 2.0
        freeCamState.rotX = 0.0
        freeCamState.rotY = 0.0
        freeCamState.rotZ = playerHeading
        
        -- Create the camera
        freeCamState.camHandle = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", true)
        CAM.SET_CAM_COORD(freeCamState.camHandle, freeCamState.posX, freeCamState.posY, freeCamState.posZ)
        CAM.SET_CAM_ROT(freeCamState.camHandle, freeCamState.rotX, freeCamState.rotY, freeCamState.rotZ, 2)
        CAM.SET_CAM_ACTIVE(freeCamState.camHandle, true)
        CAM.RENDER_SCRIPT_CAMS(true, true, 500, true, false, 0)
        
        -- Freeze player
        ENTITY.FREEZE_ENTITY_POSITION(playerPed, true)
        ENTITY.SET_ENTITY_VISIBLE(playerPed, false, false)
        PLAYER.SET_PLAYER_CONTROL(PLAYER.PLAYER_ID(), false, 0)
        
        freeCamState.initialized = true
    end)
end

-- Cleanup free cam
local function CleanupFreeCam()
    if not freeCamState.initialized then return end
    
    pcall(function()
        -- Destroy the camera
        if freeCamState.camHandle ~= 0 and CAM.DOES_CAM_EXIST(freeCamState.camHandle) then
            CAM.SET_CAM_ACTIVE(freeCamState.camHandle, false)
            CAM.RENDER_SCRIPT_CAMS(false, true, 500, true, false, 0)
            CAM.DESTROY_CAM(freeCamState.camHandle, false)
            freeCamState.camHandle = 0
        end
        
        -- Unfreeze player
        local playerPed = PLAYER.PLAYER_PED_ID()
        ENTITY.FREEZE_ENTITY_POSITION(playerPed, false)
        ENTITY.SET_ENTITY_VISIBLE(playerPed, true, false)
        PLAYER.SET_PLAYER_CONTROL(PLAYER.PLAYER_ID(), true, 0)
        
        -- Reset streaming focus
        STREAMING.CLEAR_FOCUS()
        
        freeCamState.initialized = false
    end)
end

-- Start the free cam control loop (runs in background)
local function StartFreeCamLoop()
    if freeCamState.loopRunning then return end
    freeCamState.loopRunning = true
    
    local leftPressed = false
    
    Script.QueueJob(function()
        while vars.creatorMode and freeCamState.loopRunning do
            pcall(function()
                if freeCamState.initialized then
                    -- Get mouse movement for camera rotation
                    local mouseX = PAD.GET_DISABLED_CONTROL_NORMAL(0, 1)
                    local mouseY = PAD.GET_DISABLED_CONTROL_NORMAL(0, 2)
                    
                    -- Apply rotation
                    freeCamState.rotZ = freeCamState.rotZ - mouseX * freeCamState.rotSpeed
                    freeCamState.rotX = freeCamState.rotX - mouseY * freeCamState.rotSpeed
                    
                    -- Clamp pitch
                    if freeCamState.rotX > 89.0 then freeCamState.rotX = 89.0 end
                    if freeCamState.rotX < -89.0 then freeCamState.rotX = -89.0 end
                    
                    -- Calculate forward/right vectors
                    local radZ = freeCamState.rotZ * math.pi / 180.0
                    local radX = freeCamState.rotX * math.pi / 180.0
                    
                    local forwardX = -math.sin(radZ) * math.cos(radX)
                    local forwardY = math.cos(radZ) * math.cos(radX)
                    local forwardZ = math.sin(radX)
                    
                    local rightX = math.cos(radZ)
                    local rightY = math.sin(radZ)
                    
                    -- Determine speed
                    local speed = freeCamState.moveSpeed
                    if PAD.IS_DISABLED_CONTROL_PRESSED(0, 21) then
                        speed = freeCamState.fastMoveSpeed
                    end
                    
                    -- WASD Movement
                    if PAD.IS_DISABLED_CONTROL_PRESSED(0, 32) then
                        freeCamState.posX = freeCamState.posX + forwardX * speed
                        freeCamState.posY = freeCamState.posY + forwardY * speed
                        freeCamState.posZ = freeCamState.posZ + forwardZ * speed
                    end
                    if PAD.IS_DISABLED_CONTROL_PRESSED(0, 33) then
                        freeCamState.posX = freeCamState.posX - forwardX * speed
                        freeCamState.posY = freeCamState.posY - forwardY * speed
                        freeCamState.posZ = freeCamState.posZ - forwardZ * speed
                    end
                    if PAD.IS_DISABLED_CONTROL_PRESSED(0, 34) then
                        freeCamState.posX = freeCamState.posX - rightX * speed
                        freeCamState.posY = freeCamState.posY - rightY * speed
                    end
                    if PAD.IS_DISABLED_CONTROL_PRESSED(0, 35) then
                        freeCamState.posX = freeCamState.posX + rightX * speed
                        freeCamState.posY = freeCamState.posY + rightY * speed
                    end
                    if PAD.IS_DISABLED_CONTROL_PRESSED(0, 22) then
                        freeCamState.posZ = freeCamState.posZ + speed
                    end
                    if PAD.IS_DISABLED_CONTROL_PRESSED(0, 36) then
                        freeCamState.posZ = freeCamState.posZ - speed
                    end
                    
                    -- Update camera
                    CAM.SET_CAM_COORD(freeCamState.camHandle, freeCamState.posX, freeCamState.posY, freeCamState.posZ)
                    CAM.SET_CAM_ROT(freeCamState.camHandle, freeCamState.rotX, freeCamState.rotY, freeCamState.rotZ, 2)
                    
                    -- Update streaming focus
                    STREAMING.SET_FOCUS_POS_AND_VEL(freeCamState.posX, freeCamState.posY, freeCamState.posZ, 0.0, 0.0, 0.0)
                    
                    -- Move player to stay near camera
                    local playerPed = PLAYER.PLAYER_PED_ID()
                    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(playerPed, freeCamState.posX, freeCamState.posY, freeCamState.posZ + 20, false, false, false)
                    
                    -- Get spawn position (always use front coords - safer than raycast)
                    local finalCoords = GetFrontCoords(vars.creatorModeDistance)
                    
                    -- Draw marker
                    if vars.drawMarker and finalCoords then
                        pcall(function()
                            -- Using 0 for texture dict/name as shown in natives.lua example
                            GRAPHICS.DRAW_MARKER(2, finalCoords.x, finalCoords.y, finalCoords.z, 0, 0, 0, 0, 180, 0, 1, 1, 1, 0, 120, 255, 150, 0, 1, 1, 0, 0, 0, 0)
                        end)
                    end
                    
                    -- Check click to spawn
                    if PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) and not leftPressed then
                        leftPressed = true
                        
                        if finalCoords then
                            local modelName = vars.selectedCreatorObject
                            local modelHash = MISC.GET_HASH_KEY(modelName)
                            
                            STREAMING.REQUEST_MODEL(modelHash)
                            local timeout = 0
                            while not STREAMING.HAS_MODEL_LOADED(modelHash) and timeout < 100 do
                                timeout = timeout + 1
                                Script.Yield()
                            end
                            
                            if STREAMING.HAS_MODEL_LOADED(modelHash) then
                                local ent = 0
                                if vars.isObjectAPed then
                                    ent = PED.CREATE_PED(21, modelHash, finalCoords.x, finalCoords.y, finalCoords.z, 0, true, false)
                                else
                                    ent = OBJECT.CREATE_OBJECT(modelHash, finalCoords.x, finalCoords.y, finalCoords.z, true, true, false)
                                end
                                
                                if ent ~= 0 then
                                    if vars.blip then
                                        local blipHandle = HUD.ADD_BLIP_FOR_ENTITY(ent)
                                        HUD.SET_BLIP_SPRITE(blipHandle, vars.isObjectAPed and 366 or 351)
                                    end
                                    table.insert(spawnedEntities, ent)
                                end
                                STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(modelHash)
                            end
                        end
                        
                    elseif not PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) and leftPressed then
                        leftPressed = false
                    end
                    
                    -- Disable player controls
                    PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
                end
            end)
            Script.Yield(0)
        end
        
        freeCamState.loopRunning = false
    end)
end

function SpawnMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Spawn"), SpawnMenu)
        instance:Init()
    end
    return instance
end

function SpawnMenu:Init()
    self:AddOption(SubmenuOption.new("Vehicle")
        :AddSubmenu(SpawnVehicleMenu.GetInstance())
        :AddTooltip("Vehicle spawning options"))

    self:AddOption(SubmenuOption.new("Ped")
        :AddSubmenu(SpawnPedMenu.GetInstance())
        :AddTooltip("Ped spawning options"))

    self:AddOption(SubmenuOption.new("Object")
        :AddSubmenu(SpawnObjectMenu.GetInstance())
        :AddTooltip("Object spawning options"))

    self:AddOption(SubmenuOption.new("Saved vehicle loading")
        :AddSubmenu(LoadingMenu.GetInstance())
        :AddTooltip("Load saved vehicles"))

    self:AddOption(SubmenuOption.new("Map mods")
        :AddSubmenu(MapModsMenu.GetInstance())
        :AddTooltip("You can save and load your creations from the spawning mode!"))

    self:AddOption(BreakOption.new("Spawn Editor"))

    self:AddOption(ButtonOption.new("Save current creation")
        :AddFunction(function()
            local input = TextInputComponent.new("Map name", function(text)
                if text and #text > 0 then
                    -- Save logic would go here
                end
            end)
            input:Show()
        end)
        :AddTooltip("Save the current creation in the map mods folder."))

    self:AddOption(ButtonOption.new("Clear spawned objects")
        :AddFunction(function()
            for i, entity in ipairs(spawnedEntities) do
                pcall(function()
                    if ENTITY.DOES_ENTITY_EXIST(entity) then
                        ENTITY.DELETE_ENTITY(entity)
                    end
                end)
            end
            spawnedEntities = {}
        end)
        :AddTooltip("Delete all the objects spawned using spawner mode"))

    self:AddOption(ToggleOption.new("Spawner mode")
        :AddToggleRef(vars, "creatorMode")
        :AddFunction(function()
            if vars.creatorMode then
                Script.QueueJob(function()
                    InitFreeCam()
                    StartFreeCamLoop()
                end)
            else
                freeCamState.loopRunning = false
                Script.QueueJob(function()
                    CleanupFreeCam()
                end)
            end
        end)
        :AddTooltip("This will enter you into a spawning mode that allows you to spawn peds and objects where you aim"))

    self:AddOption(ToggleOption.new("Spawner mode marker")
        :AddToggleRef(vars, "drawMarker")
        :AddRequirement(function() return vars.creatorMode end)
        :AddTooltip("Draw a marker wherever the creator's object is going to be placed"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Effective distance")
        :AddNumberRef(vars, "creatorModeDistance", "%.0f", 10.0)
        :AddRequirement(function() return vars.creatorMode end)
        :AddTooltip("The higher the number, further the marker will go."))

    self:AddOption(ToggleOption.new("Add blip")
        :AddToggleRef(vars, "blip")
        :AddRequirement(function() return vars.creatorMode end)
        :AddTooltip("Adds a blip to the spawned vehicle / object."))
end

function SpawnMenu:FeatureUpdate()
    -- Camera loop now runs in its own Script.QueueJob
    
    local spawnVehicleMenu = SpawnVehicleMenu.GetInstance()
    if spawnVehicleMenu and spawnVehicleMenu.FeatureUpdate then
        spawnVehicleMenu:FeatureUpdate()
    end
end

-- API for other menus to check spawner mode state
function SpawnMenu.IsSpawnerModeActive()
    return vars.creatorMode and freeCamState.initialized
end

-- API to get current spawner coords (where marker is)
function SpawnMenu.GetSpawnerCoords()
    if vars.creatorMode and freeCamState.initialized then
        return GetFrontCoords(vars.creatorModeDistance)
    end
    return nil
end

-- API to add blip setting
function SpawnMenu.ShouldAddBlip()
    return vars.blip
end

-- API to track spawned entity
function SpawnMenu.TrackSpawnedEntity(entity)
    table.insert(spawnedEntities, entity)
end

return SpawnMenu
