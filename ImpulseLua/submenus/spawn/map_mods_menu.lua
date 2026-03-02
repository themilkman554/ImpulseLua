

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")

local MapModsMenu = setmetatable({}, { __index = Submenu })
MapModsMenu.__index = MapModsMenu

local instance = nil

function MapModsMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Map Mods"), MapModsMenu)
        instance:Init()
    end
    return instance
end

local spawning = require("Impulse/ImpulseLua/lib/spawning")

function MapModsMenu:Init()
    self:InitializeSpawning()

    self:AddOption(SubmenuOption.new("XML Maps")
        :AddSubmenu(self:CreateFileSubmenu("XML Maps", "xml", self.xmlMapsPath))
        :AddTooltip("Load maps saved in XML format"))
        
    self:AddOption(ButtonOption.new("Refresh Maps")
        :AddFunction(function()
            GUI.AddToast("MapMods", "To refresh, please reload the script for now.", 3000, 0)
        end)
        :AddTooltip("Refresh map list"))
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

function MapModsMenu:CreateFileSubmenu(name, extension, path)
    local submenu = Submenu.new(name)
    
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

        for _, fileData in ipairs(sortedFiles) do
            menu:AddOption(ButtonOption.new(fileData.name)
                :AddFunction(function()
                    if extension == "xml" then
                        spawning.spawnMapFromXML(fileData.fullPath)
                    end
                end)
                :AddTooltip("Spawn " .. fileData.name))
        end
    end

    if FileMgr.FindFiles then
        local files = FileMgr.FindFiles(path, "." .. extension, true)
        if files then
            local structure = buildFolderStructure(files, path)
            PopulateFromStructure(submenu, structure)
        end
    else
    end
    
    return submenu
end

function MapModsMenu:InitializeSpawning()
    if self.initialized then return end

    self.xmlMapsPath = FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Impulse-main\\Maps"

    if FileMgr.CreateDir then
        FileMgr.CreateDir(self.xmlMapsPath)
    else
    end

    spawning.init({
        xmlMapsFolder = self.xmlMapsPath,
        spawnerSettings = {
            inVehicle = true,
            vehicleGodMode = true,
            vehicleEngineOn = true,
            deleteOldVehicle = true
        },
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

return MapModsMenu
