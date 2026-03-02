--[[
    Impulse Lua - Loading Menu
    Port of loadingMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local spawning = require("Impulse/ImpulseLua/lib/spawning")

local LoadingMenu = setmetatable({}, { __index = Submenu })
LoadingMenu.__index = LoadingMenu

local instance = nil

function LoadingMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Loading"), LoadingMenu)
        instance:Init()
    end
    return instance
end

function LoadingMenu:Init()
    self:InitializeSpawning()

    self:AddOption(SubmenuOption.new("XML Vehicles")
        :AddSubmenu(self:CreateFileSubmenu("XML Vehicles", "xml", self.xmlVehiclesPath))
        :AddTooltip("Load vehicles saved in the XML format"))

    self:AddOption(SubmenuOption.new("INI Vehicles")
        :AddSubmenu(self:CreateFileSubmenu("INI Vehicles", "ini", self.iniVehiclesPath))
        :AddTooltip("Load vehicles saved in the INI format"))

    self:AddOption(SubmenuOption.new("JSON Vehicles")
        :AddSubmenu(self:CreateFileSubmenu("JSON Vehicles", "json", self.jsonVehiclesPath))
        :AddTooltip("Load vehicles saved in the JSON format"))
        

    self:AddOption(SubmenuOption.new("CHRX Vehicles")
        :AddSubmenu(self:CreateFileSubmenu("CHRX Vehicles", "json", self.chrxVehiclesPath, true))
        :AddTooltip("Load vehicles saved in CHRX format (native)"))

end

-- Helper to build folder structure from flat file list (Recursively)
local function buildFolderStructure(files, basePath)
    local structure = { folders = {}, files = {} }
    for _, filePath in ipairs(files) do
        local normalizedBase = basePath:gsub("\\", "/")
        local normalizedFile = filePath:gsub("\\", "/")
        -- Use string.sub for safer stripping (handles special characters in path like '-')
        local relative = normalizedFile
        if normalizedFile:sub(1, #normalizedBase) == normalizedBase then
            relative = normalizedFile:sub(#normalizedBase + 2)
        else
            -- If for some reason the prefix doesn't match, try simpler regex or fallback causing full path display
            -- But we try to strip it anyway if possible or just log it
            relative = normalizedFile:gsub("^" .. normalizedBase:gsub("%p", "%%%1") .. "/", "")
        end
        local parts = {}
        for part in relative:gmatch("([^/]+)") do table.insert(parts, part) end
        
        local cur = structure
        for i = 1, #parts do
            local part = parts[i]
            if i == #parts then
                local displayName = part
                displayName = displayName:gsub("%.xml$", ""):gsub("%.ini$", ""):gsub("%.json$", "")
                table.insert(cur.files, { name = displayName, fullPath = filePath })
            else
                cur.folders[part] = cur.folders[part] or { folders = {}, files = {} }
                cur = cur.folders[part]
            end
        end
    end
    return structure
end

function LoadingMenu:CreateFileSubmenu(name, extension, path, isChrx)
    local submenu = Submenu.new(name)
    
    -- Get flat file list
    if isChrx then
        -- Fetch from FeatureMgr to avoid FileMgr Unicode crashes
        local list = FeatureMgr.GetFeatureList(514776905)
        if list then
            for i, fileName in ipairs(list) do
                submenu:AddOption(ButtonOption.new(fileName)
                    :AddFunction(function()
                        spawning.spawnVehicleFromCHRX(nil, i - 1)
                    end)
                    :AddTooltip("Spawn " .. fileName))
            end
        end
        return submenu
    end

    -- Recursive function to populate submenu from structure
    local function PopulateFromStructure(menu, structure)
        -- Add folders (sorted)
        local sortedFolders = {}
        for folderName, folderData in pairs(structure.folders) do
            table.insert(sortedFolders, {name = folderName, data = folderData})
        end
        table.sort(sortedFolders, function(a, b) return a.name:lower() < b.name:lower() end)

        for _, folder in ipairs(sortedFolders) do
            local dirSubmenu = Submenu.new(folder.name)
            PopulateFromStructure(dirSubmenu, folder.data)
            menu:AddOption(SubmenuOption.new(folder.name)
                :AddSubmenu(dirSubmenu)
                :AddTooltip("Folder: " .. folder.name))
        end
        
        -- Add files (sorted)
        local sortedFiles = {}
        for _, fileData in ipairs(structure.files) do table.insert(sortedFiles, fileData) end
        table.sort(sortedFiles, function(a, b) return a.name:lower() < b.name:lower() end)

        for i, fileData in ipairs(sortedFiles) do
            menu:AddOption(ButtonOption.new(fileData.name)
                :AddFunction(function()
                    if extension == "xml" then
                        spawning.spawnVehicleFromXML(fileData.fullPath)
                    elseif extension == "ini" then
                        spawning.spawnVehicleFromINI(fileData.fullPath)
                    elseif extension == "json" then
                        spawning.spawnVehicleFromJSON(fileData.fullPath)
                    end
                end)
                :AddTooltip("Spawn " .. fileData.name))
        end
    end

    -- Get flat file list for non-CHRX files
    if FileMgr.FindFiles then
        local files = FileMgr.FindFiles(path, "." .. extension, true)
        if files then
            local structure = buildFolderStructure(files, path)
            PopulateFromStructure(submenu, structure)
        end
    end
    
    return submenu
end

-- Initialize spawning library and paths
function LoadingMenu:InitializeSpawning()
    if self.initialized then return end

    local rootPath = FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Impulse-main\\Vehicles"
    self.xmlVehiclesPath = rootPath .. "\\XML Vehicles"
    self.iniVehiclesPath = rootPath .. "\\INI Vehicles"
    self.jsonVehiclesPath = rootPath .. "\\JSON Vehicles"
    self.chrxVehiclesPath = FileMgr.GetMenuRootPath() .. "\\Vehicles"

    if FileMgr.CreateDir then
        FileMgr.CreateDir(rootPath)
        FileMgr.CreateDir(self.xmlVehiclesPath)
        FileMgr.CreateDir(self.iniVehiclesPath)
        FileMgr.CreateDir(self.jsonVehiclesPath)
        -- Don't create CHRX path as it's outside our control/should exist
    else
    end

    spawning.init({
        spawnerSettings = {
            inVehicle = true,
            vehicleGodMode = true,
            vehicleEngineOn = true,
            deleteOldVehicle = true
        },
        xmlVehiclesFolder = self.xmlVehiclesPath,
        iniVehiclesFolder = self.iniVehiclesPath,
        jsonVehiclesFolder = self.jsonVehiclesPath,
        chrxVehiclesFolder = self.chrxVehiclesPath,
        upsidedownmap_module = { init = function() end },
        spawnedVehicles = {},
        spawnedMaps = {},
        spawnedOutfits = {},
        previewEntities = {},
        debug_print = function(...) print(...) end,
        constructor_lib = {},
        spawnedProps = {},
        to_boolean = function(v) return v end,
        safe_tonumber = function(v) return tonumber(v) or 0 end,
        trim = function(s) return s:match("^%s*(.-)%s*$") end,
        split_str = function(s, sep) 
            local t = {}
            for str in string.gmatch(s, "([^"..sep.."]+)") do table.insert(t, str) end
            return t
        end
    })
    
    self.initialized = true
end

return LoadingMenu
