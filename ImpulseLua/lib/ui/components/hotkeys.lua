--[[
    Impulse Lua - Hotkeys Component
    Displays all registered hotkeys in a window
]]

local UIComponent = require("Impulse/ImpulseLua/lib/ui/component")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local KeyOption = require("Impulse/ImpulseLua/lib/options/key")

---@class UIHotkeysComponent : UIComponent
local UIHotkeysComponent = setmetatable({}, { __index = UIComponent })
UIHotkeysComponent.__index = UIHotkeysComponent

--- Create a new hotkeys component
---@return UIHotkeysComponent
function UIHotkeysComponent.new()
    local self = setmetatable(UIComponent.new(), UIHotkeysComponent)
    self.lines = {}
    self.maxLines = 15
    self.lineHeight = 0.018
    self.padding = 0.005
    return self
end

--- Update the component
function UIHotkeysComponent:Update()
    -- Refresh hotkey list
    local HotkeyManager = require("Impulse/ImpulseLua/lib/hotkey_manager")
    local hotkeys = HotkeyManager.GetInstance():GetRegisteredHotkeys()
    
    self.lines = {}
    
    if #hotkeys == 0 then
        table.insert(self.lines, { text = "No hotkeys registered", color = { r = 150, g = 150, b = 150, a = 255 } })
        table.insert(self.lines, { text = "Press F12 on an option to set", color = { r = 100, g = 100, b = 100, a = 255 } })
    else
        for _, hk in ipairs(hotkeys) do
            local keyName = KeyOption.GetKeyNameStatic(hk.key) or ("Key " .. tostring(hk.key))
            local optName = hk.option and hk.option.name or "Unknown"
            local text = keyName .. " - " .. optName
            table.insert(self.lines, { text = text, color = { r = 255, g = 255, b = 255, a = 255 } })
        end
    end
end

--- Render the component
function UIHotkeysComponent:Render()
    local x, y = self:GetContentPosition()
    local w, h = self:GetContentSize()
    
    -- Match offset from system_data component
    local offset = 0.055
    x = x + offset
    y = y + self.padding
    
    for i, line in ipairs(self.lines) do
        if i > self.maxLines then break end
        
        local lineY = y + (i - 1) * self.lineHeight
        Renderer.DrawString(
            line.text,
            x, lineY,
            Renderer.Font.ChaletLondon,
            0.35,
            line.color,
            false, 0
        )
    end
end

return UIHotkeysComponent
