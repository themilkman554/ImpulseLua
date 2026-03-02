--[[
    Impulse Lua - Custom Teleport Menu (Load)
    Port of customTeleportMenu.cpp from Impulse C++
    Loads custom teleport locations using Cherax's built-in FeatureMgr
    (Save functionality is in the parent teleport_menu.lua)
    
    Feature hashes:
    - 1933463185: Teleport (button to teleport)
    - 3824279268: Teleport list dropdown
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

---@class CustomTeleportMenu : Submenu
local CustomTeleportMenu = setmetatable({}, { __index = Submenu })
CustomTeleportMenu.__index = CustomTeleportMenu

-- Feature hashes for Cherax teleport system
local TELEPORT_HASH = 1933463185
local TELEPORT_LIST_HASH = 3824279268

-- Cached teleport files
local cachedTeleports = nil
local lastRefreshTime = 0
local REFRESH_INTERVAL = 5000 -- 5 seconds

--- Get the Cherax teleports folder path
---@return string
local function getTeleportsFolder()
    return FileMgr.GetMenuRootPath() .. "\\Teleports"
end

--- Get filename from path
---@param path string
---@return string
local function getFilenameFromPath(path)
    return path:match("([^/\\]+)$") or path
end

--- Remove file extension from filename
---@param filename string
---@return string
local function removeExtension(filename)
    return filename:match("(.+)%..+$") or filename
end

--- Load teleport using Cherax's FeatureMgr
---@param path string Full path to the teleport file
local function loadTeleportFromCherax(path)
    if not path then return end
    
    -- Get the root teleports folder and find all files
    local teleportsRoot = getTeleportsFolder()
    local allFiles = FileMgr.FindFiles(teleportsRoot, ".tp", true)
    
    if not allFiles or #allFiles == 0 then
        Renderer.Notify("No teleport files found")
        return
    end
    
    -- Sort files alphabetically (case-insensitive) to match Cherax's ordering
    table.sort(allFiles, function(a, b)
        return a:lower() < b:lower()
    end)
    
    -- Find the index of our file in the sorted list
    local correctIndex = nil
    for i, file in ipairs(allFiles) do
        -- Normalize paths for comparison
        local normalizedFile = file:gsub("\\", "/")
        local normalizedPath = path:gsub("\\", "/")
        if normalizedFile == normalizedPath then
            correctIndex = i - 1 -- 0-indexed
            break
        end
    end
    
    if correctIndex == nil then
        Renderer.Notify("Failed to find teleport file index")
        return
    end
    
    -- Set the teleport list index and trigger the teleport
    FeatureMgr.SetFeatureListIndex(TELEPORT_LIST_HASH, correctIndex)
    FeatureMgr.TriggerFeatureCallback(TELEPORT_HASH)
    
    local filename = removeExtension(getFilenameFromPath(path))
    Renderer.Notify("Teleported to: " .. filename)
end

--- Refresh the teleport file cache
local function refreshTeleportCache()
    local teleportsFolder = getTeleportsFolder()
    local files = FileMgr.FindFiles(teleportsFolder, ".tp", true)
    
    if not files or #files == 0 then
        cachedTeleports = {}
        return
    end
    
    -- Sort alphabetically
    table.sort(files, function(a, b)
        return a:lower() < b:lower()
    end)
    
    cachedTeleports = files
    lastRefreshTime = MISC.GET_GAME_TIMER()
end

--- Get cached teleports (refreshes if stale)
---@return table
local function getTeleportFiles()
    local now = MISC.GET_GAME_TIMER()
    if not cachedTeleports or (now - lastRefreshTime) > REFRESH_INTERVAL then
        refreshTeleportCache()
    end
    return cachedTeleports or {}
end

--- Create a new CustomTeleportMenu
---@return CustomTeleportMenu
function CustomTeleportMenu.new()
    local self = setmetatable(Submenu.new("Load custom locations"), CustomTeleportMenu)
    return self
end

function CustomTeleportMenu:Init()
    -- Refresh button
    self:AddOption(ButtonOption.new("Refresh List")
        :AddFunction(function()
            refreshTeleportCache()
            -- Rebuild menu options
            self:ClearOptions()
            self:Init()
            Renderer.Notify("Teleport list refreshed")
        end)
        :AddTooltip("Refresh the teleport list"))
    
    -- Break
    self:AddOption(BreakOption.new("Saved Teleports"))
    
    -- Get teleport files and add options
    local teleports = getTeleportFiles()
    
    if #teleports == 0 then
        self:AddOption(ButtonOption.new("No teleports found")
            :AddFunction(function()
                Renderer.Notify("Save a teleport or add .tp files to: " .. getTeleportsFolder())
            end)
            :AddTooltip("Add .tp teleport files to your Cherax Teleports folder"))
    else
        for _, filePath in ipairs(teleports) do
            local filename = removeExtension(getFilenameFromPath(filePath))
            self:AddOption(ButtonOption.new(filename)
                :AddFunction(function()
                    loadTeleportFromCherax(filePath)
                end)
                :AddTooltip(filePath))
        end
    end
end

function CustomTeleportMenu:FeatureUpdate()
    -- Nothing to update (save input is in parent menu)
end

return CustomTeleportMenu
