
local json = require("Impulse/ImpulseLua/lib/json")

local Translation = {}

local loadedStrings = {}    -- [submenuName][originalText] = translatedText
local flatStrings = {}      -- [originalText] = translatedText (flat lookup)
local loadedFont = -1       -- Font index from translation file (-1 = default)
local isLoaded = false
local currentFile = ""      -- Currently loaded file name
local currentFilePath = ""  -- Full path of loaded file

--- Load a translation file from the given path
---@param filePath string Absolute path to the .json translation file
---@return boolean success Whether the file was loaded successfully
function Translation.Load(filePath)
    -- Reset before loading new
    Translation.Reset()
    
    local content = nil
    
    -- Try io.open first (more reliable for UTF-8)
    local file = io.open(filePath, "r")
    if file then
        content = file:read("*a")
        file:close()
    elseif FileMgr and FileMgr.ReadFileContent then
        content = FileMgr.ReadFileContent(filePath)
    end
    
    if not content or content == "" then
        Logger.LogError("Translation: Failed to read file: " .. tostring(filePath))
        return false
    end
    
    -- Clean content (remove BOM or garbage before first {)
    local jsonStart = content:find("{")
    if jsonStart then
        content = content:sub(jsonStart)
    end
    
    local status, data = pcall(json.decode, content)
    if not status or not data then
        Logger.LogError("Translation: JSON parse error: " .. tostring(data))
        return false
    end
    
    -- Read font setting
    if data.font and type(data.font) == "number" then
        loadedFont = data.font
    end
    
    -- Read strings
    if data.strings and type(data.strings) == "table" then
        for submenuName, entries in pairs(data.strings) do
            if type(entries) == "table" then
                loadedStrings[submenuName] = {}
                for originalText, translatedText in pairs(entries) do
                    if type(translatedText) == "string" then
                        loadedStrings[submenuName][originalText] = translatedText
                        if not flatStrings[originalText] then
                            flatStrings[originalText] = translatedText
                        end
                    elseif type(translatedText) == "table" then
                        for innerKey, innerVal in pairs(translatedText) do
                            if type(innerVal) == "string" and not flatStrings[innerKey] then
                                flatStrings[innerKey] = innerVal
                            end
                        end
                    end
                end
            end
        end
    end
    
    isLoaded = true
    currentFilePath = filePath
    
    currentFile = filePath:match("([^/\\]+)$") or filePath
    currentFile = currentFile:match("(.+)%..+$") or currentFile
    
    local flatCount = 0
    for _ in pairs(flatStrings) do flatCount = flatCount + 1 end
    local scopeCount = 0
    for _ in pairs(loadedStrings) do scopeCount = scopeCount + 1 end
    
    Logger.LogInfo("Translation: Loaded " .. currentFile .. " (" .. flatCount .. " flat, " .. scopeCount .. " scoped sections)")
    
    if flatStrings["[SELF]"] then
        Logger.LogInfo("Translation: [SELF] = " .. tostring(flatStrings["[SELF]"]))
    else
        Logger.LogInfo("Translation: [SELF] NOT found in flatStrings!")
        for section, entries in pairs(loadedStrings) do
            if type(entries) == "table" and entries["[SELF]"] then
                Logger.LogInfo("Translation: [SELF] found in scoped section: " .. section)
                break
            end
        end
    end
    
    return true
end


---@param submenuName string The submenu name section to look in
---@param key string The original English text
---@return string The translated string, or the original key if not found
function Translation.Get(submenuName, key)
    if not isLoaded then return key end
    
    -- Try scoped lookup first
    if loadedStrings[submenuName] and loadedStrings[submenuName][key] then
        return loadedStrings[submenuName][key]
    end
    
    -- Fall back to flat lookup
    if flatStrings[key] then
        return flatStrings[key]
    end
    
    return key
end

--- Look up a translated string across all sections (flat)
---@param key string The original English text
---@return string The translated string, or the original key if not found
function Translation.GetFlat(key)
    if not isLoaded then return key end
    
    if flatStrings[key] then
        return flatStrings[key]
    end
    
    return key
end

--- Reset all translations (revert to English)
function Translation.Reset()
    loadedStrings = {}
    flatStrings = {}
    loadedFont = -1
    isLoaded = false
    currentFile = ""
    currentFilePath = ""
end

--- Check if a translation is currently loaded
---@return boolean
function Translation.IsLoaded()
    return isLoaded
end

--- Get the font index from the loaded translation file
---@return number Font index (-1 means use default)
function Translation.GetFont()
    return loadedFont
end

--- Get the name of the currently loaded translation
---@return string
function Translation.GetCurrentName()
    return currentFile
end

--- Get the currently loaded file path
---@return string
function Translation.GetCurrentFilePath()
    return currentFilePath or ""
end

--[[ ============================================
    LANGUAGE FILE GENERATION
============================================ ]]

---@param s string
---@return string
local function jsonEscapeString(s)
    s = s:gsub('\\', '\\\\')
    s = s:gsub('"', '\\"')
    s = s:gsub('\n', '\\n')
    s = s:gsub('\r', '\\r')
    s = s:gsub('\t', '\\t')
    return '"' .. s .. '"'
end

--- Get sorted keys from a table
---@param t table
---@return table
local function getSortedKeys(t)
    local keys = {}
    for k in pairs(t) do
        if type(k) == "string" then
            table.insert(keys, k)
        end
    end
    table.sort(keys)
    return keys
end

--- Write a pretty-printed JSON file from a translation table
---@param data table The { font, strings } data
---@param outputPath string Path to write
---@return boolean success
local function writePrettyJson(data, outputPath)
    local lines = {}
    table.insert(lines, "{")
    table.insert(lines, '    "font": ' .. tostring(data.font or 0) .. ",")
    table.insert(lines, '    "strings": {')
    
    local sectionKeys = getSortedKeys(data.strings)
    for si, sectionName in ipairs(sectionKeys) do
        local section = data.strings[sectionName]
        local sectionComma = si < #sectionKeys and "," or ""
        
        if section == nil then
            -- null section
            table.insert(lines, '        ' .. jsonEscapeString(sectionName) .. ': null' .. sectionComma)
        elseif type(section) == "table" then
            table.insert(lines, '        ' .. jsonEscapeString(sectionName) .. ": {")
            
            local entryKeys = getSortedKeys(section)
            for ei, entryKey in ipairs(entryKeys) do
                local entryVal = section[entryKey]
                local entryComma = ei < #entryKeys and "," or ""
                
                if type(entryVal) == "string" then
                    table.insert(lines, '            ' .. jsonEscapeString(entryKey) .. ": " .. jsonEscapeString(entryVal) .. entryComma)
                elseif type(entryVal) == "table" then
                    -- Nested struct (like "Sort player list struct")
                    table.insert(lines, '            ' .. jsonEscapeString(entryKey) .. ": {")
                    local innerKeys = getSortedKeys(entryVal)
                    for ii, innerKey in ipairs(innerKeys) do
                        local innerComma = ii < #innerKeys and "," or ""
                        table.insert(lines, '                ' .. jsonEscapeString(innerKey) .. ": " .. jsonEscapeString(entryVal[innerKey] or innerKey) .. innerComma)
                    end
                    table.insert(lines, '            }' .. entryComma)
                end
            end
            
            table.insert(lines, '        }' .. sectionComma)
        end
    end
    
    table.insert(lines, '    }')
    table.insert(lines, '}')
    
    local content = table.concat(lines, "\n")
    
    local file = io.open(outputPath, "w")
    if not file then
        Logger.LogError("Translation: Cannot open file for writing: " .. outputPath)
        return false
    end
    file:write(content)
    file:close()
    return true
end

--- Collect all translatable strings by walking the menu tree
---@return table sections { [submenuName] = { [key] = value, ... }, ... }
local function collectMenuStrings()
    local sections = {}
    local visited = {}
    
    local Menu = require("Impulse/ImpulseLua/lib/menu")
    local root = Menu.rootSubmenu
    
    if not root then
        Logger.LogError("Translation: No root submenu found")
        return sections
    end
    
    -- Submenus to skip ENTIRELY — don't collect any options from them
    -- (they contain auto-generated entries like ped models, object names, or user files)
    local skipEntirely = {
        ["XML Vehicles"] = true,         -- Vehicle filenames
        ["INI Vehicles"] = true,
        ["JSON Vehicles"] = true,
        ["CHRX Vehicles"] = true,
        ["Player History"] = true,       -- Dynamic player names and info
        ["XML Maps"] = true,             -- Map filenames
        ["Load outfit"] = true,          -- Wardrobe filenames
        ["Load languages"] = true,       -- Language filenames
        ["Custom headers"] = true,       -- Custom header filenames
        ["Load custom headers"] = true,
        ["Model"] = true,                -- Hundreds of ped model names
        ["Object Spawn"] = true,         -- Hundreds of object model names
        ["Ped Spawn"] = true,            -- Auto-generated ped spawn entries
        ["Hud editor"] = true,           -- Auto-generated HUD editor entries
        ["Load custom locations"] = true, -- User teleport files
        ["Load themes"] = true,          -- User theme files
        -- Vehicle class submenus (each has dozens of vehicle model names)
        ["Super"] = true, ["Sport"] = true, ["Sports classic"] = true,
        ["Off road"] = true, ["Sedan"] = true, ["SUV"] = true,
        ["Coupe"] = true, ["Muscle"] = true, ["Compact"] = true,
        ["Van"] = true, ["Commercial"] = true, ["Industrial"] = true,
        ["Military"] = true, ["Service"] = true, ["Emergency"] = true,
        ["Motorcycle"] = true, ["Cycle"] = true, ["Planes"] = true,
        ["Helicopters"] = true, ["Boats"] = true, ["Trains"] = true,
        ["Trailer"] = true, ["Utility"] = true,
        -- DLC vehicle submenus
        ["Casino"] = true, ["Arena War"] = true, ["After Hours"] = true,
        ["Super Sport Series"] = true, ["Doomsday Heist"] = true,
        ["Smuggler's Run"] = true, ["Gunrunning"] = true,
        ["Special Vehicle Circuit"] = true, ["Import/Export"] = true,
        ["Bikers"] = true, ["Cunning Stunts"] = true,
        ["Finance and Felony"] = true, ["Lowriders: Custom Classics"] = true,
        ["Be My Valentine"] = true, ["January 2016"] = true,
        ["Festive Surprise 2015"] = true, ["Executives and Other Criminals"] = true,
        ["Halloween Surprise"] = true, ["Lowriders"] = true,
        ["Freemode Events"] = true, ["Ill-Gotten Gains Part 2"] = true,
        ["Ill-Gotten Gains Part 1"] = true, ["Heists"] = true,
        ["Festive Surprise 2014"] = true, ["Last Team Standing"] = true,
        ["Flight School"] = true, ["Independence Day"] = true,
        ["I'm Not a Hipster"] = true, ["High Life"] = true,
        ["Business"] = true, ["Valentine's Day"] = true,
        ["Beach Bum"] = true,
        -- DLC vehicles container
        ["DLC vehicles only"] = true,
    }
    
    -- Submenus whose own options ARE collected, but children are NOT recursed into
    local skipChildren = {
        ["Loading"] = true,              -- Keep "XML Vehicles", "INI Vehicles" etc. but don't enter them
        ["Map Mods"] = true,             -- Keep "XML Maps", "Refresh Maps" but don't enter them
    }
    
    --- Recursively walk a submenu
    ---@param submenu table
    local function walkSubmenu(submenu)
        if not submenu or visited[submenu] then return end
        visited[submenu] = true
        
        local sectionName = submenu.name or ""
        if sectionName == "" then return end
        
        -- Skip this submenu entirely if in the skip list
        if skipEntirely[sectionName] then return end
        
        -- Create section if it doesn't exist
        if not sections[sectionName] then
            sections[sectionName] = {}
        end
        local section = sections[sectionName]
        
        -- Walk all options
        for _, opt in ipairs(submenu.options or {}) do
            -- Collect option name (skip dynamic/colored names)
            if opt.name and opt.name ~= "" and not opt.name:find("~") then
                section[opt.name] = opt.name
            end
            
            -- Collect tooltip
            if opt.tooltip and opt.tooltip ~= "" and not opt.tooltip:find("~") then
                section[opt.tooltip] = opt.tooltip
            end
            
            -- Recurse into SubmenuOption's submenu (unless parent blocks children)
            if opt.submenu and not skipChildren[sectionName] then
                walkSubmenu(opt.submenu)
            end
            
            -- Collect scroll option items
            if opt.items then
                for _, item in ipairs(opt.items) do
                    if item.name and item.name ~= "" and not item.name:find("~") then
                        section[item.name] = item.name
                    end
                end
            end
        end
    end
    
    walkSubmenu(root)
    
    -- Add panel buttons section
    sections["panel"] = {
        ["Chat"] = "Chat",
        ["Hotkeys"] = "Hotkeys",
        ["Log"] = "Log",
        ["Profiler"] = "Profiler",
        ["System data"] = "System data",
    }
    
    -- Add player list tags under "Players" section (merge if exists)
    if not sections["Players"] then
        sections["Players"] = {}
    end
    local playerSection = sections["Players"]
    local tags = {
        "[CUTSCENE]", "[F]", "[GOD]", "[INT]", "[MOD]",
        "[OTR]", "[PASSIVE]", "[PAUSED]", "[ROCKSTAR]",
        "[SCTV]", "[SELF]", "[Script Host]", 
        "[Script/Session Host]", "[Session Host]", "[TYPING]",
        "[JOINING..]", "[I]" ,"[PASSIVE]","[SCTV]"
    }
    for _, tag in ipairs(tags) do
        if not playerSection[tag] then
            playerSection[tag] = tag
        end
    end
    
    -- Add submenu names section
    sections["submenu names"] = sections["submenu names"] or {}
    for name in pairs(sections) do
        if name ~= "submenu names" and name ~= "panel" then
            sections["submenu names"][name] = name
        end
    end
    
    return sections
end

--- Generate a fresh language template file
--- Walks the menu tree and writes an English-to-English JSON template
---@param outputPath string Path to write the generated file
---@return boolean success
function Translation.Generate(outputPath)
    local sections = collectMenuStrings()
    
    local data = {
        font = 0,
        strings = sections
    }
    
    local success = writePrettyJson(data, outputPath)
    if success then
        -- Count entries
        local totalEntries = 0
        local totalSections = 0
        for _, section in pairs(sections) do
            totalSections = totalSections + 1
            if type(section) == "table" then
                for _ in pairs(section) do
                    totalEntries = totalEntries + 1
                end
            end
        end
        Logger.LogInfo("Translation: Generated " .. outputPath .. " (" .. totalSections .. " sections, " .. totalEntries .. " entries)")
    end
    return success
end

--- Update an existing translation file with new keys from a fresh scan
--- Preserves existing translations, adds new keys with English defaults
---@param existingPath string Path to the existing translation file to update
---@param outputPath string Path to write the updated file
---@return boolean success
function Translation.Update(existingPath, outputPath)
    -- Load the existing file
    local content = nil
    local file = io.open(existingPath, "r")
    if file then
        content = file:read("*a")
        file:close()
    end
    
    if not content or content == "" then
        Logger.LogError("Translation: Cannot read existing file: " .. existingPath)
        return false
    end
    
    -- Clean BOM
    local jsonStart = content:find("{")
    if jsonStart then
        content = content:sub(jsonStart)
    end
    
    local status, existingData = pcall(json.decode, content)
    if not status or not existingData then
        Logger.LogError("Translation: Failed to parse existing file: " .. tostring(existingData))
        return false
    end
    
    -- Get fresh scan
    local freshSections = collectMenuStrings()
    
    -- Merge: existing takes priority, fresh adds new keys
    local mergedStrings = {}
    local existingStrings = existingData.strings or {}
    
    -- Start with all existing sections
    for sectionName, entries in pairs(existingStrings) do
        if type(entries) == "table" then
            mergedStrings[sectionName] = {}
            for k, v in pairs(entries) do
                mergedStrings[sectionName][k] = v
            end
        end
    end
    
    -- Add any new sections/keys from fresh scan
    local newCount = 0
    for sectionName, entries in pairs(freshSections) do
        if type(entries) == "table" then
            if not mergedStrings[sectionName] then
                mergedStrings[sectionName] = {}
            end
            for k, v in pairs(entries) do
                if mergedStrings[sectionName][k] == nil then
                    mergedStrings[sectionName][k] = v -- English default
                    newCount = newCount + 1
                end
            end
        end
    end
    
    local data = {
        font = existingData.font or 0,
        strings = mergedStrings
    }
    
    local success = writePrettyJson(data, outputPath)
    if success then
        Logger.LogInfo("Translation: Updated " .. outputPath .. " (added " .. newCount .. " new entries)")
    end
    return success
end

return Translation
