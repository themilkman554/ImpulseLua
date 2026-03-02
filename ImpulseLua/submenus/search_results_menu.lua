--[[
    Impulse Lua - Search Results Menu
    Port of searchResultsMenu.cpp
    
    Displays search results from the SearchOptions function
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local SearchResultsMenu = setmetatable({}, { __index = Submenu })
SearchResultsMenu.__index = SearchResultsMenu

local instance = nil

function SearchResultsMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Search results"), SearchResultsMenu)
        instance:Init()
    end
    return instance
end

function SearchResultsMenu:Init()
    -- Menu is populated dynamically by SearchOptions
end

-- Clear all options
function SearchResultsMenu:ClearOptions()
    self.options = {}
end

-- Add an option to the results
function SearchResultsMenu:AddResult(option)
    table.insert(self.options, option)
end

-- Add a break for submenu name
function SearchResultsMenu:AddSubmenuBreak(name)
    table.insert(self.options, BreakOption.new(name))
end

return SearchResultsMenu
