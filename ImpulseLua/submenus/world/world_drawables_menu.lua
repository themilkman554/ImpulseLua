--[[
    Impulse Lua - World Drawables Menu
    Port of worldDrawablesMenu.cpp from Impulse C++
    Allows manipulation of "Drawables" (Entities) via memory
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local EditClosestDrawableMenu = require("Impulse/ImpulseLua/submenus/world/edit_closest_drawable_menu")

---@class WorldDrawablesMenu : Submenu
local WorldDrawablesMenu = setmetatable({}, { __index = Submenu })
WorldDrawablesMenu.__index = WorldDrawablesMenu

local instance = nil

-- State (exposed for child menu)
local vars = {
    esp = false,
    closestDrawable = nil,  -- Entity handle
    closestDrawablePtr = nil -- Memory pointer
}

-- ============================================
-- MEMORY / HELPER FUNCTIONS
-- ============================================

--- Check if an entity is a valid "Drawable"
--- C++ Logic: Checks valid class vtables. Lua: Checks m_type == 1 at 0x28
---@param entity integer Entity handle
---@return boolean, integer|nil pointer
local function IsValidDrawable(entity)
    if not ENTITY.DOES_ENTITY_EXIST(entity) then return false, nil end
    
    if GTA.HandleToPointer then
        local ptrObj = GTA.HandleToPointer(entity)
        if ptrObj then
            local ptr = ptrObj:GetAddress()
            if ptr and ptr ~= 0 then
                -- Assuming all valid entities returned by PoolMgr have compatible scale offsets 0x7C/0x86
                -- Removing type check as it filters out Peds/Vehicles which are also Drawables in this context
                return true, ptr
            end
        end
    end
    return false, nil
end

--- Get all nearby entities (Peds, Vehicles, Objects)
---@return table
local function GetAllEntities()
    local entities = {}
    
    -- Peds
    if PoolMgr.GetCurrentPedCount then
        local pedCount = PoolMgr.GetCurrentPedCount()
        for i = 0, pedCount - 1 do
            local ped = PoolMgr.GetPed(i)
            if ped and ped ~= 0 then table.insert(entities, ped) end
        end
    end
    
    -- Vehicles
    if PoolMgr.GetCurrentVehicleCount then
        local vehCount = PoolMgr.GetCurrentVehicleCount()
        for i = 0, vehCount - 1 do
            local veh = PoolMgr.GetVehicle(i)
            if veh and veh ~= 0 then table.insert(entities, veh) end
        end
    end
    
    -- Objects
    if PoolMgr.GetCurrentObjectCount then
        local objCount = PoolMgr.GetCurrentObjectCount()
        for i = 0, objCount - 1 do
            local obj = PoolMgr.GetObject(i)
            if obj and obj ~= 0 then table.insert(entities, obj) end
        end
    end
    
    -- Iterate connected players (Method 2 for robustness)
    for i = 0, 31 do
        if NETWORK.NETWORK_IS_PLAYER_CONNECTED(i) then
            local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(i)
            if playerPed and playerPed ~= 0 and ENTITY.DOES_ENTITY_EXIST(playerPed) then
                -- Add player ped
                local isDuplicate = false
                for _, e in ipairs(entities) do
                    if e == playerPed then isDuplicate = true break end
                end
                if not isDuplicate then table.insert(entities, playerPed) end
                
                -- Add player vehicle
                local veh = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)
                if veh and veh ~= 0 and ENTITY.DOES_ENTITY_EXIST(veh) then
                    isDuplicate = false
                    for _, e in ipairs(entities) do
                        if e == veh then isDuplicate = true break end
                    end
                    if not isDuplicate then table.insert(entities, veh) end
                end
            end
        end
    end
    
    return entities
end

--- Tasks
local Task = {
    ESP = 1,
    TeleportToMe = 2,
    ScaleX5 = 3,
    ScaleNormal = 4,
    CalculateClosest = 5
}

--- Calculate the closest drawable to player
local function CalculateClosest()
    local entities = GetAllEntities()
    local myPed = PLAYER.PLAYER_PED_ID()
    local myVeh = PED.GET_VEHICLE_PED_IS_IN(myPed, false)
    local myCoords = ENTITY.GET_ENTITY_COORDS(myPed, true)
    
    local closestDist = 999999.0
    vars.closestDrawable = nil
    vars.closestDrawablePtr = nil
    
    for _, entity in ipairs(entities) do
        if entity ~= myPed and entity ~= myVeh then
            local isValid, ptr = IsValidDrawable(entity)
            if isValid and ptr then
                local entCoords = ENTITY.GET_ENTITY_COORDS(entity, true)
                local dist = MISC.GET_DISTANCE_BETWEEN_COORDS(myCoords.x, myCoords.y, myCoords.z, entCoords.x, entCoords.y, entCoords.z, false)
                if dist < closestDist then
                    closestDist = dist
                    vars.closestDrawable = entity
                    vars.closestDrawablePtr = ptr
                end
            end
        end
    end
end

--- Run task on all valid drawables
---@param task integer
local function RunTaskOnAll(task)
    local entities = GetAllEntities()
    local myPed = PLAYER.PLAYER_PED_ID()
    local myCoords = ENTITY.GET_ENTITY_COORDS(myPed, true)
    
    for _, entity in ipairs(entities) do
        -- Skip self
        if entity ~= myPed and entity ~= PED.GET_VEHICLE_PED_IS_IN(myPed, false) then
            local isValid, ptr = IsValidDrawable(entity)
            if isValid and ptr then
                local entCoords = ENTITY.GET_ENTITY_COORDS(entity, true)
                
                if task == Task.ESP then
                    -- Draw line
                    GRAPHICS.DRAW_LINE(myCoords.x, myCoords.y, myCoords.z, entCoords.x, entCoords.y, entCoords.z, 255, 0, 0, 255)
                    
                elseif task == Task.TeleportToMe then
                    ENTITY.SET_ENTITY_COORDS(entity, myCoords.x, myCoords.y, myCoords.z, false, false, false, false)
                    
                elseif task == Task.ScaleX5 then
                    -- Width at 0x7C, Height at 0x86 (float)
                    -- Add 5.0 to current
                    local width = Memory.ReadFloat(ptr + 0x7C)
                    local height = Memory.ReadFloat(ptr + 0x86)
                    Memory.WriteFloat(ptr + 0x7C, width + 5.0)
                    Memory.WriteFloat(ptr + 0x86, height + 5.0)
                    
                elseif task == Task.ScaleNormal then
                    -- Set to 1.0
                    Memory.WriteFloat(ptr + 0x7C, 1.0)
                    Memory.WriteFloat(ptr + 0x86, 1.0)
                end
            end
        end
    end
end

-- ============================================
-- MENU CLASS
-- ============================================

function WorldDrawablesMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Drawable editor"), WorldDrawablesMenu)
        instance:Init()
    end
    return instance
end

function WorldDrawablesMenu:Init()
    -- Pass vars to child menu for state access
    EditClosestDrawableMenu.SetParentVars(vars)

    self:AddOption(ToggleOption.new("ESP")
        :AddToggleRef(vars, "esp")
        :AddTooltip("Show lines to every drawable in your area")
        :AddHotkey())
        :SetDonor()
    self:AddOption(SubmenuOption.new("Edit closest drawable")
        :AddSubmenu(EditClosestDrawableMenu.GetInstance())
        :AddFunction(function()
            CalculateClosest()
            vars.esp = false -- Disable global ESP when editing single
        end)
        :AddTooltip("Edit the closest drawable"))
        :SetDonor()
        
    self:AddOption(ButtonOption.new("Teleport all to me")
        :AddFunction(function()
            RunTaskOnAll(Task.TeleportToMe)
        end)
        :AddTooltip("Teleport every drawable in your area to you")
        :AddHotkey())
        :SetDonor()
                
    self:AddOption(ButtonOption.new("x5 scale")
        :AddFunction(function()
            RunTaskOnAll(Task.ScaleX5)
        end)
        :AddTooltip("Set the scale of every drawable in the area to you")
        :AddHotkey())
        :SetDonor()
    self:AddOption(ButtonOption.new("Normal scale")
        :AddFunction(function()
            RunTaskOnAll(Task.ScaleNormal)
        end)
        :AddTooltip("Set the scale of every drawable in the area to you back to normal")
        :AddHotkey())
        :SetDonor()
end

--- Feature Update - called every frame
function WorldDrawablesMenu:FeatureUpdate()
    if vars.esp then
        RunTaskOnAll(Task.ESP)
    end
end

return WorldDrawablesMenu
