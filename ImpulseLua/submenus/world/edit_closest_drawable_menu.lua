--[[
    Impulse Lua - Edit Closest Drawable Menu
    Port of editClosestDrawableMenu.cpp from Impulse C++
    Detailed editor for the closest entity's position, scale, and LOD
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

---@class EditClosestDrawableMenu : Submenu
local EditClosestDrawableMenu = setmetatable({}, { __index = Submenu })
EditClosestDrawableMenu.__index = EditClosestDrawableMenu

local instance = nil

-- State
local vars = {
    accuracy = 1.0,
    positionX = 0.0,
    positionY = 0.0,
    positionZ = 0.0,
    scale = 1.0,
    lod = 0
}

-- Reference to parent menu's state (set on init)
local parentVars = nil

-- Memory Offsets (from reclass.h CDrawable)
local OFFSET_WIDTH = 0x7C
local OFFSET_HEIGHT = 0x86 -- Note: weapon_visuals uses 0x8C, but reclass says 0x86 for CDrawable
local OFFSET_POSITION = 0x90 -- Vector3 (x, y, z as 3 floats)
local OFFSET_LOD = 0xB0 -- int (deduced from reclass.h layout)

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function GetMyCoords()
    return ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), true)
end

--- Read entity position from memory
---@param ptr number
---@return number, number, number
local function ReadPosition(ptr)
    local x = Memory.ReadFloat(ptr + OFFSET_POSITION)
    local y = Memory.ReadFloat(ptr + OFFSET_POSITION + 4)
    local z = Memory.ReadFloat(ptr + OFFSET_POSITION + 8)
    return x, y, z
end

--- Write entity position to memory
---@param ptr number
---@param x number
---@param y number
---@param z number
local function WritePosition(ptr, x, y, z)
    Memory.WriteFloat(ptr + OFFSET_POSITION, x)
    Memory.WriteFloat(ptr + OFFSET_POSITION + 4, y)
    Memory.WriteFloat(ptr + OFFSET_POSITION + 8, z)
    -- Also update 0x9C (m_anotherX) as per C++ SetPosition
    Memory.WriteFloat(ptr + 0x9C, x)
end

--- Read scale (estimated as max of width/height)
---@param ptr number
---@return number
local function ReadScale(ptr)
    local w = Memory.ReadFloat(ptr + OFFSET_WIDTH)
    local h = Memory.ReadFloat(ptr + OFFSET_HEIGHT)
    return math.max(w, h)
end

--- Write scale (both width and height)
---@param ptr number
---@param scale number
local function WriteScale(ptr, scale)
    Memory.WriteFloat(ptr + OFFSET_WIDTH, scale)
    Memory.WriteFloat(ptr + OFFSET_HEIGHT, scale)
end

--- Read LOD
---@param ptr number
---@return number
local function ReadLod(ptr)
    return Memory.ReadInt(ptr + OFFSET_LOD)
end

--- Write LOD
---@param ptr number
---@param lod number
local function WriteLod(ptr, lod)
    Memory.WriteInt(ptr + OFFSET_LOD, lod)
end

-- ============================================
-- MENU CLASS
-- ============================================

function EditClosestDrawableMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Edit closest drawable"), EditClosestDrawableMenu)
        instance:Init()
    end
    return instance
end

--- Set reference to parent menu's vars (for closestDrawable access)
---@param pVars table
function EditClosestDrawableMenu.SetParentVars(pVars)
    parentVars = pVars
end

function EditClosestDrawableMenu:Init()
    self:AddOption(NumberOption.new(ScrollOption.Type.SCROLL, "Accuracy")
        :AddNumberRef(vars, "accuracy", "%.1f", 1.0)
        :AddMin(0.1):AddMax(50.0)
        :AddTooltip("Edit the accuracy for the position editor"))

    self:AddOption(BreakOption.new("Position"))

    self:AddOption(NumberOption.new(ScrollOption.Type.SCROLL, "X - Horizontal")
        :AddNumber(vars.positionX, "%.3f", vars.accuracy)
        :AddNumberRef(vars, "positionX", "%.3f", vars.accuracy)
        :AddMin(-100000.0):AddMax(100000.0)
        :AddFunction(function()
            if parentVars and parentVars.closestDrawablePtr then
                local _, y, z = ReadPosition(parentVars.closestDrawablePtr)
                WritePosition(parentVars.closestDrawablePtr, vars.positionX, y, z)
            end
        end)
        :AddTooltip("X position"))

    self:AddOption(NumberOption.new(ScrollOption.Type.SCROLL, "Y - Vertical")
        :AddNumberRef(vars, "positionY", "%.3f", vars.accuracy)
        :AddMin(-100000.0):AddMax(100000.0)
        :AddFunction(function()
            if parentVars and parentVars.closestDrawablePtr then
                local x, _, z = ReadPosition(parentVars.closestDrawablePtr)
                WritePosition(parentVars.closestDrawablePtr, x, vars.positionY, z)
            end
        end)
        :AddTooltip("Y position"))

    self:AddOption(NumberOption.new(ScrollOption.Type.SCROLL, "Z - Height")
        :AddNumberRef(vars, "positionZ", "%.3f", vars.accuracy)
        :AddMin(-100000.0):AddMax(100000.0)
        :AddFunction(function()
            if parentVars and parentVars.closestDrawablePtr then
                local x, y, _ = ReadPosition(parentVars.closestDrawablePtr)
                WritePosition(parentVars.closestDrawablePtr, x, y, vars.positionZ)
            end
        end)
        :AddTooltip("Z position"))

    self:AddOption(ButtonOption.new("Teleport to me")
        :AddFunction(function()
            if parentVars and parentVars.closestDrawablePtr then
                local myCoords = GetMyCoords()
                WritePosition(parentVars.closestDrawablePtr, myCoords.x, myCoords.y, myCoords.z)
                vars.positionX = myCoords.x
                vars.positionY = myCoords.y
                vars.positionZ = myCoords.z
            end
        end)
        :AddTooltip("Teleport drawable to me"))

    self:AddOption(BreakOption.new("Scale & LOD"))

    self:AddOption(NumberOption.new(ScrollOption.Type.SCROLL, "Scale")
        :AddNumberRef(vars, "scale", "%.1f", 0.1)
        :AddMin(0.0):AddMax(50.0)
        :AddFunction(function()
            if parentVars and parentVars.closestDrawablePtr then
                WriteScale(parentVars.closestDrawablePtr, vars.scale)
            end
        end)
        :AddTooltip("Change drawable scale"))

    self:AddOption(NumberOption.new(ScrollOption.Type.SCROLL, "LOD")
        :AddNumberRef(vars, "lod", "%d", 1)
        :AddMin(-10000):AddMax(10000)
        :AddFunction(function()
            if parentVars and parentVars.closestDrawablePtr then
                WriteLod(parentVars.closestDrawablePtr, vars.lod)
            end
        end)
        :AddTooltip("Change drawable level of detail"))
end

--- Called when entering this submenu
function EditClosestDrawableMenu:OnEnter()
    -- Load current values from closest drawable
    if parentVars and parentVars.closestDrawablePtr then
        vars.positionX, vars.positionY, vars.positionZ = ReadPosition(parentVars.closestDrawablePtr)
        vars.scale = ReadScale(parentVars.closestDrawablePtr)
        vars.lod = ReadLod(parentVars.closestDrawablePtr)
    end
end

--- Update while menu is active - draws ESP line to target
function EditClosestDrawableMenu:Update()
    if parentVars and parentVars.closestDrawablePtr then
        local myCoords = GetMyCoords()
        local x, y, z = ReadPosition(parentVars.closestDrawablePtr)
        GRAPHICS.DRAW_LINE(myCoords.x, myCoords.y, myCoords.z, x, y, z, 0, 255, 0, 255)
        
        -- Draw info text on screen
        local info = string.format(
            "~c~Closest Drawable~w~\nAddress: 0x%X\nPos: %.2f, %.2f, %.2f\nScale: %.2f\nLOD: %d",
            parentVars.closestDrawablePtr,
            x, y, z,
            ReadScale(parentVars.closestDrawablePtr),
            ReadLod(parentVars.closestDrawablePtr)
        )
        -- Draw at top-left
        HUD.SET_TEXT_FONT(4)
        HUD.SET_TEXT_SCALE(0.3, 0.3)
        HUD.SET_TEXT_COLOUR(255, 255, 255, 255)
        HUD.SET_TEXT_OUTLINE()
        HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
        HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(info)
        HUD.END_TEXT_COMMAND_DISPLAY_TEXT(0.01, 0.3, 0)
    end
end

return EditClosestDrawableMenu
