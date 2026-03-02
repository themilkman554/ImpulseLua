--[[
    Impulse Lua - Theme Loader Menu
    Port of loadThemesMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local Menu = require("Impulse/ImpulseLua/lib/menu")
local Settings = require("Impulse/ImpulseLua/lib/settings")
local json = require("Impulse/ImpulseLua/lib/json")

local ThemeLoaderMenu = setmetatable({}, { __index = Submenu })
ThemeLoaderMenu.__index = ThemeLoaderMenu

local instance = nil

--- Get Themes path
---@return string
local function GetThemesPath()
    return FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Impulse-main\\Themes"
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

--- Load theme from file
---@param path string
--- Load theme from file
---@param path string
function ThemeLoaderMenu.LoadTheme(path)
    local file = io.open(path, "r")
    if not file then
        print("Failed to open theme file")
        return false
    end

    local content = file:read("*a")
    file:close()

    if not content or content == "" then
        print("Empty theme file")
        return false
    end

    -- Clean content (remove BOM or garbage)
    local jsonStart = content:find("{")
    local jsonEnd = content:match("^.*()}") -- Find last position
    
    if jsonStart then
         content = content:sub(jsonStart)
    end
    
    local status, data = pcall(json.decode, content)
    if not status or not data then
        print("Parse error: " .. tostring(data))
        return false
    end

    -- Apply Colors
    -- Apply Colors
    if data.Colors then
        if data.Colors.Primary then 
            Renderer.Colors.Primary.r = data.Colors.Primary[1]
            Renderer.Colors.Primary.g = data.Colors.Primary[2]
            Renderer.Colors.Primary.b = data.Colors.Primary[3]
            Renderer.Colors.Primary.a = data.Colors.Primary[4]
        end
        if data.Colors.Outline then 
            Renderer.Colors.Outline.r = data.Colors.Outline[1]
            Renderer.Colors.Outline.g = data.Colors.Outline[2]
            Renderer.Colors.Outline.b = data.Colors.Outline[3]
            Renderer.Colors.Outline.a = data.Colors.Outline[4]
        end
        if data.Colors.Scroller then 
            Renderer.Colors.Selection.r = data.Colors.Scroller[1]
            Renderer.Colors.Selection.g = data.Colors.Scroller[2]
            Renderer.Colors.Selection.b = data.Colors.Scroller[3]
            Renderer.Colors.Selection.a = data.Colors.Scroller[4]
        end
        if data.Colors.SubHeader then 
            Renderer.Colors.SubHeader.r = data.Colors.SubHeader[1]
            Renderer.Colors.SubHeader.g = data.Colors.SubHeader[2]
            Renderer.Colors.SubHeader.b = data.Colors.SubHeader[3]
            Renderer.Colors.SubHeader.a = data.Colors.SubHeader[4]
        end
        if data.Colors.SubHeaderTitle then 
            Renderer.Colors.Title.r = data.Colors.SubHeaderTitle[1]
            Renderer.Colors.Title.g = data.Colors.SubHeaderTitle[2]
            Renderer.Colors.Title.b = data.Colors.SubHeaderTitle[3]
            Renderer.Colors.Title.a = data.Colors.SubHeaderTitle[4]
        end
        if data.Colors.Text then 
            Renderer.Colors.Option.r = data.Colors.Text[1]
            Renderer.Colors.Option.g = data.Colors.Text[2]
            Renderer.Colors.Option.b = data.Colors.Text[3]
            Renderer.Colors.Option.a = data.Colors.Text[4]
        end
    end

    -- Apply Text/Font settings
    if data.Text then
        if data.Text.Font then Renderer.Layout.textFont = data.Text.Font end
        if data.Text.Size then Renderer.Layout.textSize = data.Text.Size end
    end

    -- Apply Misc settings
    if data.Misc then
        if data.Misc.ColorlessToggles ~= nil then Renderer.colorlessToggles = data.Misc.ColorlessToggles end
        if data.Misc.AnimatedArrows ~= nil then Renderer.animatedArrows = data.Misc.AnimatedArrows end
        if data.Misc.Arrows then Renderer.arrowStyle = data.Misc.Arrows end
        if data.Misc.HeaderAlpha then Renderer.headerAlpha = data.Misc.HeaderAlpha end
        if data.Misc.BackgroundOpacity then Renderer.Layout.bgOpacity = data.Misc.BackgroundOpacity end
    end

    -- Apply Menu settings
    if data.Menu then
        if data.Menu.Width then Renderer.Layout.width = data.Menu.Width end
        if data.Menu.OptionHeight then Renderer.Layout.optionHeight = data.Menu.OptionHeight end
        if data.Menu.XPosition then Menu.position.x = data.Menu.XPosition end
        if data.Menu.YPosition then Menu.position.y = data.Menu.YPosition end
        
        if data.Menu.InfoboxX and Renderer.Layout.infoboxPos then Renderer.Layout.infoboxPos.x = data.Menu.InfoboxX end
        if data.Menu.InfoboxY and Renderer.Layout.infoboxPos then Renderer.Layout.infoboxPos.y = data.Menu.InfoboxY end
        if data.Menu.VehicleInfoX and Renderer.Layout.vehicleInfoPos then Renderer.Layout.vehicleInfoPos.x = data.Menu.VehicleInfoX end
        if data.Menu.VehicleInfoY and Renderer.Layout.vehicleInfoPos then Renderer.Layout.vehicleInfoPos.y = data.Menu.VehicleInfoY end
    end

    -- Apply Header (Requires ThemeMenu reference, but we can access shared state or send message)
    -- Ideally, we need to update ThemeMenu.State.headerIndex. Since we require it, we can modify it?
    -- No, ThemeMenu is not required here yet to avoid cyclic dependency.
    -- Assuming ThemeMenu.State is what we need to update.
    -- We can use the circular require pattern or inject dependency.
    -- For now, let's just update the Renderer header directly if possible, or try to get ThemeMenu.
    
    local ThemeMenu = require("Impulse/ImpulseLua/submenus/settings/theme_menu")
    if data.Header then
        local headerIndex = data.Header + 1 -- 0-indexed in C++ -> 1-indexed in Lua
        ThemeMenu.State.headerIndex = headerIndex
        -- We need to call SetHeader, but it's local in ThemeMenu.
        -- We can trigger a refresh or access it if exported.
        -- Let's assume ThemeMenu exposes a function or we rely on the state update + feature update?
        -- `SetHeader` is called in `FeatureUpdate` or callbacks.
        -- Let's add a public `SetHeader` to ThemeMenu or just hope the state update is enough if we trigger it.
        -- Actually, ThemeMenu:Init calls SetHeader.
        -- We can modify ThemeMenu to expose SetHeader or use the state.
        -- For now, let's just set the state.
        
        -- To force update, we might need to call SetHeader. 
        ThemeMenu.SetHeader(headerIndex)
    end
    
    -- Apply Footer
    if data.Footer then
        local footerIndex = data.Footer + 1
        ThemeMenu.State.footerIndex = footerIndex
        
        local footers = {
            { name = "Impulse Logo Bottom", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu" },
            { name = "Impulse Logo Bottom 2 Blur", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu2Blur" },
            { name = "Impulse Logo Bottom 2 Flat", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu2Flat" },
            { name = "Impulse Logo Bottom 3", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu3" },
        }
        local footer = footers[footerIndex]
        if footer then
            Renderer.Textures.Footer = { dict = footer.dict, name = footer.tex }
        end
    end

    -- Apply Notify
    if data.Notify then
        local notifyIndex = data.Notify + 1
        ThemeMenu.State.notifyIndex = notifyIndex
        local notifies = {
            { name = "Impulse Logo Bottom", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu" },
            { name = "Impulse Logo Bottom 2 Blur", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu2Blur" },
            { name = "Impulse Logo Bottom 2 Flat", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu2Flat" },
            { name = "Impulse Logo Bottom 3", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu3" },
            { name = "Generic", dict = "Bookmarks", tex = "notify_generic" },
        }
        local notify = notifies[notifyIndex]
        if notify then
            Renderer.Textures.Notify = { dict = notify.dict, name = notify.tex }
        end
    end

    local themeName = removeExtension(getFilenameFromPath(path))
    Settings.CurrentThemeName = themeName
    Renderer.Notify("Loaded theme: " .. themeName)
    return true
end

function ThemeLoaderMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Load themes"), ThemeLoaderMenu)
        instance:Init()
    end
    return instance
end

function ThemeLoaderMenu:Init()
    -- Refresh button
    self:AddOption(ButtonOption.new("Refresh List")
        :AddFunction(function()
            self:ClearOptions()
            self:Init()
            Renderer.Notify("Theme list refreshed")
        end)
        :AddTooltip("Refresh the theme list"))

    self:AddOption(BreakOption.new("Saved Themes"))

    local themesPath = GetThemesPath()
    local files = FileMgr.FindFiles(themesPath, ".json", true)

    if files then
        for _, filePath in ipairs(files) do
            local filename = removeExtension(getFilenameFromPath(filePath))
            self:AddOption(ButtonOption.new(filename)
                :AddFunction(function()
                    if ThemeLoaderMenu.LoadTheme(filePath) then
                        Renderer.Notify("Theme loaded: " .. filename)
                    else
                         Renderer.Notify("Failed to load theme")
                    end
                end)
                :AddTooltip(filePath))
        end
    else
        self:AddOption(ButtonOption.new("No themes found")
            :AddTooltip("Add .json theme files to " .. themesPath))
    end
end

function ThemeLoaderMenu:FeatureUpdate()
end

return ThemeLoaderMenu
