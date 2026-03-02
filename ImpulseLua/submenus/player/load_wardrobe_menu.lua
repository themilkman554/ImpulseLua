--[[
    Impulse Lua - Load Wardrobe Menu
    Port of loadWardrobeMenu.cpp from Impulse C++
    Loads saved outfits from Cherax's Outfits folder using FeatureMgr
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class LoadWardrobeMenu : Submenu
local LoadWardrobeMenu = setmetatable({}, { __index = Submenu })
LoadWardrobeMenu.__index = LoadWardrobeMenu

-- Cached outfit files
local cachedOutfits = nil
local lastRefreshTime = 0
local REFRESH_INTERVAL = 5000 -- 5 seconds

-- Feature Hashes
local OUTFIT_LIST_HASH = 2384691091

--- Get the Cherax outfits folder path
---@return string
local function getOutfitsFolder()
    return FileMgr.GetMenuRootPath() .. "\\Outfits"
end

--- Spawn outfit using FeatureMgr
---@param index number 0-based index
---@param name string Name of the outfit
local function spawnOutfit(index, name)
    FeatureMgr.SetFeatureListIndex(OUTFIT_LIST_HASH, index)
    FeatureMgr.GetFeatureByName("Load Outfit"):TriggerCallback()
    Renderer.Notify("Loading outfit: " .. name)
end

--- Refresh the outfit file cache using FeatureMgr
local function refreshOutfitCache()
    -- Get list directly from Cherax, avoiding manual file parsing and Unicode issues
    local list = FeatureMgr.GetFeatureList(OUTFIT_LIST_HASH)
    
    if not list then
        cachedOutfits = {}
        return
    end
    
    cachedOutfits = list
    lastRefreshTime = MISC.GET_GAME_TIMER()
end

--- Get cached outfits (refreshes if stale)
---@return table
local function getOutfitFiles()
    local now = MISC.GET_GAME_TIMER()
    if not cachedOutfits or (now - lastRefreshTime) > REFRESH_INTERVAL then
        refreshOutfitCache()
    end
    return cachedOutfits or {}
end

--- Create a new LoadWardrobeMenu
---@return LoadWardrobeMenu
function LoadWardrobeMenu.new()
    local self = setmetatable(Submenu.new("Load outfit"), LoadWardrobeMenu)
    return self
end

function LoadWardrobeMenu:Init()
    -- Refresh button
    self:AddOption(ButtonOption.new("Refresh List")
        :AddFunction(function()
            refreshOutfitCache()
            -- Rebuild menu options
            self:ClearOptions()
            self:Init()
            Renderer.Notify("Outfit list refreshed")
        end)
        :AddTooltip("Refresh the outfit list"))
    
    -- Break
    self:AddOption(BreakOption.new("Saved Outfits"))
    
    -- Get outfit files and add options
    local outfits = getOutfitFiles()
    
    if #outfits == 0 then
        self:AddOption(ButtonOption.new("Add outfits to Cherax/Outfits")
            :AddFunction(function()
                Renderer.Notify("Add .json outfit files to: " .. getOutfitsFolder())
            end)
            :AddTooltip("Add .json outfit files to your Cherax Outfits folder"))
    else
        for i, name in ipairs(outfits) do
            -- FeatureMgr list is likely just the names, maybe with extensions.
            -- If it includes extension, fine. If not, fine.
            self:AddOption(ButtonOption.new(name)
                :AddFunction(function()
                    -- FeatureMgr indices are typically 0-based
                    spawnOutfit(i - 1, name)
                end)
                :AddTooltip("Load " .. name))
        end
    end
end

function LoadWardrobeMenu:FeatureUpdate()
    -- Nothing to update in feature loop
end

return LoadWardrobeMenu
