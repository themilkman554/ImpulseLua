--[[
    Impulse Lua - System Data Component
    Displays system/game stats
    Port of systemdataComponent.h from Impulse C++
]]

local UIComponent = require("Impulse/ImpulseLua/lib/ui/component")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class UISystemDataComponent : UIComponent
local UISystemDataComponent = setmetatable({}, { __index = UIComponent })
UISystemDataComponent.__index = UISystemDataComponent

function UISystemDataComponent.new()
    local self = setmetatable(UIComponent.new(), UISystemDataComponent)
    self.lineHeight = 0.018
    self.padding = 0.005
    return self
end

--- Get current FPS (approximate)
local lastFrameTime = 0
local fps = 0
local frameCount = 0
local fpsUpdateTime = 0

local function UpdateFPS()
    local currentTime = MISC.GET_GAME_TIMER()
    frameCount = frameCount + 1
    
    if currentTime - fpsUpdateTime >= 1000 then
        fps = frameCount
        frameCount = 0
        fpsUpdateTime = currentTime
    end
    
    return fps
end

function UISystemDataComponent:Update()
    UpdateFPS()
end

function UISystemDataComponent:Render()
    local x, y = self:GetContentPosition()
    local w, h = self:GetContentSize()
    
    -- Increased offset to move text right (user feedback)
    local offset = 0.0170
    x = x + offset
    y = y + self.padding
    
    local ped = PLAYER.PLAYER_PED_ID()
    local player = PLAYER.PLAYER_ID()
    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
    
    local lines = {
        { label = "FPS", value = tostring(fps) },
        { label = "Position", value = string.format("%.1f, %.1f, %.1f", coords.x, coords.y, coords.z) },
        { label = "Heading", value = string.format("%.1f", ENTITY.GET_ENTITY_HEADING(ped)) },
        { label = "Health", value = string.format("%d/%d", ENTITY.GET_ENTITY_HEALTH(ped), ENTITY.GET_ENTITY_MAX_HEALTH(ped)) },
        { label = "Armor", value = tostring(PED.GET_PED_ARMOUR(ped)) },
        { label = "Wanted", value = tostring(PLAYER.GET_PLAYER_WANTED_LEVEL(player)) },
        { label = "In Vehicle", value = PED.IS_PED_IN_ANY_VEHICLE(ped, false) and "Yes" or "No" },
    }
    
    -- Add vehicle info if in vehicle
    if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        local speed = ENTITY.GET_ENTITY_SPEED(veh) * 3.6 -- Convert to km/h
        table.insert(lines, { label = "Speed", value = string.format("%.0f km/h", speed) })
        table.insert(lines, { label = "Vehicle Health", value = string.format("%.0f%%", VEHICLE.GET_VEHICLE_BODY_HEALTH(veh) / 10) })
    end
    
    -- Session info
    if NETWORK.NETWORK_IS_SESSION_ACTIVE() then
        table.insert(lines, { label = "Session", value = "Online" })
        table.insert(lines, { label = "Players", value = tostring(NETWORK.NETWORK_GET_NUM_CONNECTED_PLAYERS()) })
    else
        table.insert(lines, { label = "Session", value = "Offline" })
    end
    
    for i, line in ipairs(lines) do
        local lineY = y + (i - 1) * self.lineHeight
        
        -- Label (left-aligned) - C++ line 23
        Renderer.DrawString(
            line.label .. ":",
            x, lineY,
            Renderer.Font.ChaletLondon,
            0.28,
            { r = 180, g = 180, b = 180, a = 255 },
            false, 0
        )
        
        -- Value (right-aligned) - C++ line 24 uses JustifyRight
        Renderer.DrawString(
            line.value,
            x, lineY,
            Renderer.Font.ChaletLondon,
            0.28,
            { r = 255, g = 255, b = 255, a = 255 },
            false, 2, x, x + w - offset * 2
        )
    end
    
    -- Update parent window size based on content
    if self.parent then
        self.parent.size.h = self.parent.headerHeight + #lines * self.lineHeight + self.padding * 2
        self.parent.size.w = math.max(0.15, self.parent.size.w)
    end
end

return UISystemDataComponent
