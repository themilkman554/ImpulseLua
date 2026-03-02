--[[
    Impulse Lua - Submenu Base Class
    Base class for all menu pages
    Port of submenu.h/cpp from Impulse C++
]]

---@class Submenu
---@field name string Submenu display name
---@field options table Array of options
---@field parent Submenu|nil Parent submenu
local Submenu = {}
Submenu.__index = Submenu

--- Create a new Submenu
---@param name string Submenu name
---@return Submenu
function Submenu.new(name)
    local self = setmetatable({}, Submenu)
    self.name = name or ""
    self.options = {}
    self.parent = nil
    self.canBeSearched = false
    return self
end

--- Add an option to the submenu
---@param option Option The option to add
---@return Option The added option for chaining
function Submenu:AddOption(option)
    table.insert(self.options, option)
    return option
end

--- Add multiple options
---@param options table Array of options
function Submenu:AddOptions(options)
    for _, opt in ipairs(options) do
        self:AddOption(opt)
    end
end

--- Clear all options
function Submenu:ClearOptions()
    self.options = {}
end

--- Clear options from a starting offset
---@param offset number Starting index (1-based)
function Submenu:ClearOptionsFrom(offset)
    for i = #self.options, offset, -1 do
        table.remove(self.options, i)
    end
end

--- Get visible options
---@return table Array of visible options
function Submenu:GetVisibleOptions()
    local visible = {}
    for _, opt in ipairs(self.options) do
        if opt:IsVisible() then
            table.insert(visible, opt)
        end
    end
    return visible
end

--- Set parent submenu
---@param parent Submenu
function Submenu:SetParent(parent)
    self.parent = parent
end

--- Called once when submenu is initialized
function Submenu:Init()
    -- Override in subclasses to add options
end

--- Called once when entering this submenu
function Submenu:OnEnter()
    -- Override in subclasses
end

--- Called every frame while this submenu is active
function Submenu:Update()
    -- Override in subclasses
end

--- Called every frame for feature updates (even when not in menu)
function Submenu:FeatureUpdate()
    -- Override in subclasses for looped features
end

return Submenu
