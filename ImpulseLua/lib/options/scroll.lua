--[[
    Impulse Lua - Scroll Option
    Selection from a list of named values
    Port of scrollOption.h from Impulse C++
]]

local Option = require("Impulse/ImpulseLua/lib/options/option")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

-- Scroll option types
local ScrollType = {
    SCROLL = 1,       -- Just scroll through items
    TOGGLE = 2,       -- Scroll with toggle
    SELECT = 3,       -- Scroll to select one item
    SCROLLSELECT = 4  -- Scroll and select
}

---@class ScrollOption : Option
---@field items table Array of {name, value} pairs
---@field index number Current selection index (1-based)
local ScrollOption = setmetatable({}, { __index = Option })
ScrollOption.__index = ScrollOption
ScrollOption.Type = ScrollType

--- Create a new ScrollOption
---@param optionType number ScrollType enum
---@param name string Option name
---@return ScrollOption
function ScrollOption.new(optionType, name)
    local self = setmetatable(Option.new(name), ScrollOption)
    self.optionType = optionType or ScrollType.SCROLL
    self.items = {}
    self.index = 1
    self.indexRef = nil
    self.loop = false
    self.callback = function() end
    self.onUpdate = function(opt) end
    self.currentOp = function() end
    
    -- For toggle type
    self.toggleValue = false
    self.toggleRef = nil
    
    -- For select type
    self.selectedIndex = nil
    

    
    return self
end

--- Add scroll items
---@param items table Array of {name, value} or just strings
---@param index number Initial index (1-based)
---@return ScrollOption self for chaining
function ScrollOption:AddScroll(items, index)
    self.items = {}
    for i, item in ipairs(items) do
        if type(item) == "string" then
            self.items[i] = { name = item, value = i }
        else
            self.items[i] = item
        end
    end
    self.index = index or 1
    return self
end

--- Bind index to referenced table value
---@param tbl table Table containing the index
---@param key string Key in table
---@return ScrollOption self for chaining
function ScrollOption:AddIndexRef(tbl, key)
    self.indexRef = { tbl = tbl, key = key }
    return self
end

--- Add toggle for TOGGLE type
---@param value boolean Initial toggle state
---@return ScrollOption self for chaining
function ScrollOption:AddToggle(value)
    self.toggleValue = value
    return self
end

--- Bind toggle to referenced table value
---@param tbl table Table containing the toggle
---@param key string Key in table
---@return ScrollOption self for chaining
function ScrollOption:AddToggleRef(tbl, key)
    self.toggleRef = { tbl = tbl, key = key }
    return self
end

--- Enable looping
---@return ScrollOption self for chaining
function ScrollOption:CanLoop()
    self.loop = true
    return self
end

--- Set callback function
---@param func function Callback
---@return ScrollOption self for chaining
function ScrollOption:AddFunction(func)
    self.callback = func
    return self
end

--- Set update function
---@param func function Update callback
---@return ScrollOption self for chaining
function ScrollOption:AddOnUpdate(func)
    self.onUpdate = func
    return self
end

--- Get current index
---@return number
function ScrollOption:GetIndex()
    if self.indexRef then
        return self.indexRef.tbl[self.indexRef.key]
    end
    return self.index
end

--- Set index
---@param val number
function ScrollOption:SetIndex(val)
    if type(val) ~= "number" then return end
    
    local min = 1
    local max = #self.items
    
    if val < min then
        val = self.loop and max or min
    elseif val > max then
        val = self.loop and min or max
    end
    
    if self.indexRef then
        self.indexRef.tbl[self.indexRef.key] = val
    else
        self.index = val
    end
end

--- Set current value (find matches in items)
---@param val any
function ScrollOption:SetValue(val)
    for i, item in ipairs(self.items) do
        if item.value == val then
            self:SetIndex(i)
            return
        end
    end
end

--- Get current item
---@return table|nil
function ScrollOption:GetCurrentItem()
    return self.items[self:GetIndex()]
end

--- Get current value
---@return any
function ScrollOption:GetValue()
    local item = self:GetCurrentItem()
    return item and item.value or nil
end

--- Get toggle state (for TOGGLE type)
---@return boolean
function ScrollOption:GetToggle()
    if self.toggleRef then
        return self.toggleRef.tbl[self.toggleRef.key]
    end
    return self.toggleValue
end

--- Set toggle state
---@param val boolean
function ScrollOption:SetToggle(val)
    if self.toggleRef then
        self.toggleRef.tbl[self.toggleRef.key] = val
    else
        self.toggleValue = val
    end
end

--- Render the scroll option
---@param position number 0-indexed position
function ScrollOption:Render(position)
    self.onUpdate(self)
    
    local currentItem = self:GetCurrentItem()
    local itemName = currentItem and currentItem.name or "???"
    local idx = self:GetIndex()
    local total = #self.items
    
    local hasLeft = self.loop or idx > 1
    local hasRight = self.loop or idx < total
    local valueText = string.format("%s %s %s",
        hasLeft and "<" or "",
        itemName,
        hasRight and ">" or "")
    
    -- Draw option name (gray if locked)
    local nameX = Renderer.Layout.posX - Renderer.Layout.width / 2 + 0.006
    local y = Renderer.GetOptionYText(position)
    local textColor = self:GetTextColor()
    
    Renderer.DrawString(self:GetDisplayName(), nameX, y, Renderer.Layout.textFont,
                       Renderer.Layout.textSize, textColor)
    
    -- Draw value on right side
    local valueColor = Renderer.GetColorOffset(Renderer.Colors.Option, -20)
    
    if self.optionType == ScrollType.TOGGLE then
        -- Value with toggle indicator (only for TOGGLE type)
        local valueX = Renderer.Layout.posX + Renderer.Layout.width / 2 - 0.025
        Renderer.DrawString(valueText, valueX, y, Renderer.Layout.textFont,
                           Renderer.Layout.textSize, valueColor, true, 2, 0, valueX)
        
        -- Toggle sprite
        local isOn = self:GetToggle()
        local toggleX = Renderer.Layout.posX + Renderer.Layout.width / 2 - 0.013
        local toggleY = Renderer.GetOptionY(position) + Renderer.Layout.optionHeight / 2
        local texture = Renderer.GetToggleTexture(isOn)
        Renderer.DrawSprite(texture, toggleX, toggleY, 0.02, 0.015, 0,
                           { r = 255, g = 255, b = 255, a = 255 })
    else
        -- Just value (for SCROLL, SELECT, SCROLLSELECT types)
        local valueX = Renderer.Layout.posX + Renderer.Layout.width / 2 - 0.01
        Renderer.DrawString(valueText, valueX, y, Renderer.Layout.textFont,
                           Renderer.Layout.textSize, valueColor, true, 2, 0, valueX)
    end
end

--- Handle when selected
---@param position number 0-indexed position
function ScrollOption:RenderSelected(position)
    self.currentOp()
end

--- Handle Enter press
function ScrollOption:OnSelect()
    if self:IsLocked() then
        Renderer.Notify("~r~Donor feature - upgrade to unlock")
        return
    end
    if self.requirement() then
        if self.optionType == ScrollType.TOGGLE then
            self:SetToggle(not self:GetToggle())
        elseif self.optionType == ScrollType.SELECT then
            self.selectedIndex = self:GetIndex()
        end
        self.callback()
    end
end

--- Handle Left press
function ScrollOption:OnLeft()
    if self:IsLocked() then return end
    if self.requirement() then
        self:SetIndex(self:GetIndex() - 1)
        if self.optionType == ScrollType.SCROLL or
           (self.optionType == ScrollType.TOGGLE and self:GetToggle()) then
            self.callback()
        end
    end
end

--- Handle Right press
function ScrollOption:OnRight()
    if self:IsLocked() then return end
    if self.requirement() then
        self:SetIndex(self:GetIndex() + 1)
        if self.optionType == ScrollType.SCROLL or
           (self.optionType == ScrollType.TOGGLE and self:GetToggle()) then
            self.callback()
        end
    end
end

return ScrollOption
