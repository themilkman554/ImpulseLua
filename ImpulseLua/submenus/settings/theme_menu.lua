--[[
    Impulse Lua - Theme Menu
    Menu customization and color options
    Port of themeMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local ColorOption = require("Impulse/ImpulseLua/lib/options/color")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local Menu = require("Impulse/ImpulseLua/lib/menu")
local json = require("Impulse/ImpulseLua/lib/json")
local ThemeLoaderMenu = require("Impulse/ImpulseLua/submenus/settings/theme_loader_menu")
local TextInputComponent = require("Impulse/ImpulseLua/lib/ui/text_input_component")
local PlayerInfoComponent = require("Impulse/ImpulseLua/lib/ui/player_info_component")
local UIVehicleComponent = require("Impulse/ImpulseLua/lib/ui/components/vehicle_info")

local ThemeMenu = setmetatable({}, { __index = Submenu })
ThemeMenu.__index = ThemeMenu

local instance = nil

-- Theme state
local themeState = {
    fontIndex = 1,
    headerIndex = 1,
    footerIndex = 1,
    notifyIndex = 5,
    rainbow = false,
    rainbowOutline = false,
    rainbowScroller = false,
    rainbowSubheader = false,
    arrows = 4,              -- Arrow design (0-5), default 4 = helicopterhud
    colorlessToggles = false,
    animatedArrows = false,
}

-- Rainbow color state
local rainbowColors = {
    primary = { r = 255, g = 0, b = 0 },
    secondary = { r = 255, g = 0, b = 0 },
    tertiary = { r = 255, g = 0, b = 0 },
}

-- Animation state
local animationState = {
    active = false,
    frames = {}, -- list of {dict, name}
    currentFrame = 1,
    lastTime = 0,
    interval = 40, -- ms
}

-- Input component
local themeNameInput = nil
local demoVehicleComponent = nil


-- Font options
local fonts = {
    { name = "Chalet London", value = 0 },
    { name = "House Script", value = 1 },
    { name = "Monospace", value = 2 },
    { name = "Wingdings", value = 3 },
    { name = "Chalet Comprime 1", value = 4 },
    { name = "Chalet Comprime 2", value = 5 },
    { name = "Chalet Comprime 3", value = 6 },
    { name = "Pricedown", value = 7 },
    { name = "Taxi", value = 8 },
}

-- Header options (from C++ themeMenu.cpp)

local function GenerateFrames(fmt, min, max)
    local frames = {}
    for i = min, max do
        table.insert(frames, { dict = "Bookmarks", name = string.format(fmt, i) })
    end
    return frames
end

-- Header options
local headers = {
    { name = "Default", type = "animated", frames = GenerateFrames("ImpulseAniHeader%02d", 0, 50) },
    
    -- Animated Headers
    { name = "Black Death", type = "animated", frames = GenerateFrames("BlackDeathFrame (%d)", 1, 25) },
    { name = "Paint Frame", type = "animated", frames = GenerateFrames("ImpulsePaintFrame (%d)", 1, 7) },
    { name = "Slash Frame", type = "animated", frames = GenerateFrames("SlashFrameUp (%d)", 1, 15) },
    { name = "Toaster PC", type = "animated", frames = GenerateFrames("ToasterPc (%d)", 1, 12) },

    -- Static Headers
    { name = "Static Pulse", dict = "Bookmarks", tex = "ImpulseHeader5" },
    { name = "90s Backdrop", dict = "Bookmarks", tex = "90sBackdrop" },
    { name = "Admin Tool VIP", dict = "Bookmarks", tex = "AdminToolVIP" },
    { name = "Another One", dict = "Bookmarks", tex = "AnotherOne" },
    { name = "Anti Engine", dict = "Bookmarks", tex = "AntiEngine" },
    { name = "Basic Black Grad", dict = "Bookmarks", tex = "BasicBlackGrad" },
    { name = "Big Text", dict = "Bookmarks", tex = "BigText" },
    { name = "Boomer Trainer", dict = "Bookmarks", tex = "BoomerTrainer" },
    { name = "CRLIVE", dict = "Bookmarks", tex = "CRLIVE" },
    { name = "Car Impulse", dict = "Bookmarks", tex = "CarImpulse" },
    { name = "Curved Hat", dict = "Bookmarks", tex = "CurvedHat" },
    { name = "Dark Forest", dict = "Bookmarks", tex = "DarkForest" },
    { name = "Daylight City", dict = "Bookmarks", tex = "Daylightcity" },
    { name = "Dragons Eye", dict = "Bookmarks", tex = "DragonsEye" },
    { name = "Eason 151", dict = "Bookmarks", tex = "Eason151" },
    { name = "Eason 151 (2)", dict = "Bookmarks", tex = "Eason151(2)" },
    { name = "How Dare You", dict = "Bookmarks", tex = "HowDareYou" },
    { name = "Impulse 12 by Kyupus", dict = "Bookmarks", tex = "Impulse12byKyupus" },
    { name = "Impulse 1 by Seb", dict = "Bookmarks", tex = "Impulse1byseb" },
    { name = "Impulse 3 by Kyupus", dict = "Bookmarks", tex = "Impulse3byKyupus" },
    { name = "Impulse 4 by Kyupus", dict = "Bookmarks", tex = "Impulse4byKyupus" },
    { name = "Impulse 5 by Kyupus", dict = "Bookmarks", tex = "Impulse5byKyupus" },
    { name = "Impulse 6 by Kyupus", dict = "Bookmarks", tex = "Impulse6byKyupus" },
    { name = "Impulse 8 by Kyupus", dict = "Bookmarks", tex = "Impulse8byKyupus" },
    { name = "Impulse 9 by Kyupus", dict = "Bookmarks", tex = "Impulse9byKyupus" },
    { name = "Impulse City 1", dict = "Bookmarks", tex = "ImpulseCity1byLordSaphir" },
    { name = "Impulse Header 1", dict = "Bookmarks", tex = "ImpulseHeader1" },
    { name = "Impulse Header 2", dict = "Bookmarks", tex = "ImpulseHeader2" },
    { name = "Impulse Header 3", dict = "Bookmarks", tex = "ImpulseHeader3" },
    { name = "Impulse Header 4", dict = "Bookmarks", tex = "ImpulseHeader4" },
    { name = "Impulse Logo Bottom", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu" },
    { name = "Impulse Logo Bottom 2 Blur", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu2Blur" },
    { name = "Impulse Logo Bottom 2 Flat", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu2Flat" },
    { name = "Impulse Logo Bottom 3", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu3" },
    { name = "Impulse One", dict = "Bookmarks", tex = "ImpulseOne" },
    { name = "Impulse Bad Winver", dict = "Bookmarks", tex = "Impulse_bad_winver" },
    { name = "Joeyy ZX", dict = "Bookmarks", tex = "JoeyyZX" },
    { name = "Karma 99", dict = "Bookmarks", tex = "Karma99" },
    { name = "Karma 99 (2)", dict = "Bookmarks", tex = "Karma99(2)" },
    { name = "Legend Modz", dict = "Bookmarks", tex = "LegendModz" },
    { name = "Line Art", dict = "Bookmarks", tex = "LineArt" },
    { name = "Matrix", dict = "Bookmarks", tex = "Matrix" },
    { name = "Micky Weed", dict = "Bookmarks", tex = "MickyWeed" },
    { name = "Neon City", dict = "Bookmarks", tex = "NeonCity" },
    { name = "Nostalgic 1", dict = "Bookmarks", tex = "Nostalgic1" },
    { name = "Nostalgic 2", dict = "Bookmarks", tex = "Nostalgic2" },
    { name = "Nostalgic 3", dict = "Bookmarks", tex = "Nostalgic3" },
    { name = "Porn Pulse", dict = "Bookmarks", tex = "PornPulse" },
    { name = "Profit Tool", dict = "Bookmarks", tex = "ProfitTool" },
    { name = "Purple Elec", dict = "Bookmarks", tex = "PupleElec" },
    { name = "Red City", dict = "Bookmarks", tex = "RedCity" },
    { name = "Retro Wave 1", dict = "Bookmarks", tex = "RetroWave1" },
    { name = "Retro Wave 2", dict = "Bookmarks", tex = "RetroWave2" },
    { name = "Retro Wave 3", dict = "Bookmarks", tex = "RetroWave3" },
    { name = "Retro Wave 4", dict = "Bookmarks", tex = "RetroWave4" },
    { name = "Retro Wave 5", dict = "Bookmarks", tex = "RetroWave5" },
    { name = "Roderick", dict = "Bookmarks", tex = "Roderick" },
    { name = "Roderick (2)", dict = "Bookmarks", tex = "Roderick(2)" },
    { name = "SEBBEN", dict = "Bookmarks", tex = "SEBBEN" },
    { name = "SEBBEN (2)", dict = "Bookmarks", tex = "SEBBEN(2)" },
    { name = "SEBBEN (3)", dict = "Bookmarks", tex = "SEBBEN(3)" },
    { name = "SEBBEN (4)", dict = "Bookmarks", tex = "SEBBEN(4)" },
    { name = "SEBBEN (5)", dict = "Bookmarks", tex = "SEBBEN(5)" },
    { name = "Super Mario Kart", dict = "Bookmarks", tex = "Super_Mario_Kart" },
    { name = "Toxic Wizard", dict = "Bookmarks", tex = "Toxic-Wizard" },
    { name = "Toxic Wizard (2)", dict = "Bookmarks", tex = "Toxic-Wizard(2)" },
    { name = "Toxic Wizard (3)", dict = "Bookmarks", tex = "Toxic-Wizard(3)" },
    { name = "Toxic Wizard (4)", dict = "Bookmarks", tex = "Toxic-Wizard(4)" },
    { name = "Toxic Wizard (5)", dict = "Bookmarks", tex = "Toxic-Wizard(5)" },
    { name = "Vxrious Banner 1", dict = "Bookmarks", tex = "Vxrious_Banner_v1" },
    { name = "Vxrious Banner 2", dict = "Bookmarks", tex = "Vxrious_Banner_v2" },
    { name = "Water Pulse", dict = "Bookmarks", tex = "WaterPulse" },
    { name = "Weeb City", dict = "Bookmarks", tex = "WeebCity" },
    { name = "Yellow Weed", dict = "Bookmarks", tex = "YellowWeed" },
    { name = "Yukii", dict = "Bookmarks", tex = "Yukii" },
    { name = "Yukii (2)", dict = "Bookmarks", tex = "Yukii(2)" },
    { name = "Yukii (3)", dict = "Bookmarks", tex = "Yukii(3)" },
    { name = "Yukii (4)", dict = "Bookmarks", tex = "Yukii(4)" },
    { name = "Ahegao", dict = "Bookmarks", tex = "ahegao" },
    { name = "Bazza", dict = "Bookmarks", tex = "bazza" },
    { name = "Beans", dict = "Bookmarks", tex = "beans" },
    { name = "Cyber City", dict = "Bookmarks", tex = "cyber_city" },
    { name = "Dark Red Grap", dict = "Bookmarks", tex = "darkredgrap" },
    { name = "Gucci", dict = "Bookmarks", tex = "gucci" },
    { name = "Imp Neon", dict = "Bookmarks", tex = "impneon" },
    { name = "Lights", dict = "Bookmarks", tex = "lights" },
    { name = "Louis Vuitton", dict = "Bookmarks", tex = "louis_vuitton" },
    { name = "Shah", dict = "Bookmarks", tex = "shah" },
    { name = "Shibuya", dict = "Bookmarks", tex = "shibuya" },
}

-- Footer options
local footers = {
    { name = "Impulse Logo Bottom", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu" },
    { name = "Impulse Logo Bottom 2 Blur", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu2Blur" },
    { name = "Impulse Logo Bottom 2 Flat", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu2Flat" },
    { name = "Impulse Logo Bottom 3", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu3" },
}

-- Notify icons
local notifies = {
    { name = "Impulse Logo Bottom", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu" },
    { name = "Impulse Logo Bottom 2 Blur", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu2Blur" },
    { name = "Impulse Logo Bottom 2 Flat", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu2Flat" },
    { name = "Impulse Logo Bottom 3", dict = "Bookmarks", tex = "ImpulseLogoBottomMenu3" },
    { name = "Generic", dict = "Bookmarks", tex = "notify_generic" },
}


function ThemeMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Theme"), ThemeMenu)
        instance:Init()
    end
    return instance
end

--- Cycle rainbow colors
---@param color table {r, g, b}
local function CycleRainbow(color)
    if color.r > 0 and color.b == 0 then
        color.r = color.r - 1
        color.g = color.g + 1
    end
    if color.g > 0 and color.r == 0 then
        color.g = color.g - 1
        color.b = color.b + 1
    end
    if color.b > 0 and color.g == 0 then
        color.r = color.r + 1
        color.b = color.b - 1
    end
end

--- Load animation frames
---@param frames table List of {dict, name}
local function LoadAnimation(frames)
    -- Ensure texture dict is loaded (assuming all use "Bookmarks" for now, or check first frame)
    if frames and #frames > 0 then
        local dict = frames[1].dict
        if not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(dict) then
            GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(dict, false)
        end
    end

    animationState.frames = frames or {}
    animationState.interval = 40
    animationState.currentFrame = 1
    animationState.lastTime = MISC.GET_GAME_TIMER()
    animationState.active = true
end

--- Set header texture
--- Set header texture
function ThemeMenu.SetHeader(index)
    local header = headers[index]
    if header then
        if header.type == "animated" then
            LoadAnimation(header.frames)
            return
        end
        
        -- Static header
        animationState.active = false
        Renderer.Textures.Header = { dict = header.dict, name = header.tex }
        
        -- Request the texture dict
        if not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(header.dict) then
            GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(header.dict, false)
        end
    end
end

--- Set custom header
---@param dict string Dictionary name
---@param name string Texture name
function ThemeMenu.SetCustomHeader(dict, name)
    animationState.active = false
    Renderer.Textures.Header = { dict = dict, name = name }
end

--- Reset theme to defaults

local function ResetTheme()
    Renderer.Colors.Primary.r = 0; Renderer.Colors.Primary.g = 0; Renderer.Colors.Primary.b = 0; Renderer.Colors.Primary.a = 255
    Renderer.Colors.Outline.r = 0; Renderer.Colors.Outline.g = 246; Renderer.Colors.Outline.b = 255; Renderer.Colors.Outline.a = 255
    Renderer.Colors.Selection.r = 22; Renderer.Colors.Selection.g = 192; Renderer.Colors.Selection.b = 198; Renderer.Colors.Selection.a = 200
    Renderer.Colors.SubHeader.r = 0; Renderer.Colors.SubHeader.g = 0; Renderer.Colors.SubHeader.b = 0; Renderer.Colors.SubHeader.a = 200
    Renderer.Colors.Title.r = 225; Renderer.Colors.Title.g = 225; Renderer.Colors.Title.b = 225; Renderer.Colors.Title.a = 255
    Renderer.Colors.Option.r = 255; Renderer.Colors.Option.g = 255; Renderer.Colors.Option.b = 255; Renderer.Colors.Option.a = 255
    Renderer.Layout.textFont = 4 -- Chalet Comprime
    Renderer.Layout.textSize = 0.33
    Renderer.Layout.width = 0.235
    Renderer.Layout.width = 0.235
    Renderer.Layout.optionHeight = 0.032
    Renderer.headerAlpha = 255
    Renderer.Layout.bgOpacity = 45
    themeState.headerIndex = 1
    themeState.fontIndex = 5
    themeState.rainbow = false
    themeState.rainbowOutline = false
    themeState.rainbowScroller = false
    themeState.rainbowSubheader = false
    themeState.footerIndex = 1
    themeState.notifyIndex = 5 -- Generic
    
    -- Reset Toggles & Version
    Renderer.colorlessToggles = false
    themeState.colorlessToggles = false
    
    Renderer.animatedArrows = false
    themeState.animatedArrows = false
    
    Renderer.showVersion = true
    
    -- Reset animation
    animationState.active = false
    
    -- Reset header
    ThemeMenu.SetHeader(1) -- Default (Pulse)
    GUI.AddToast("Theme", "Theme reset to defaults", 2000, 0)
end


--- Get Themes path
---@return string
local function GetThemesPath()
    return FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Impulse-main\\Themes"
end

--- Save current theme to file
---@param name string
local function SaveTheme(name)
    if not name or name == "" then
        Renderer.Notify("Invalid theme name")
        return
    end

    local filename = GetThemesPath() .. "\\" .. name .. ".json"

    local themeData = {
        Colors = {
            Primary = { Renderer.Colors.Primary.r, Renderer.Colors.Primary.g, Renderer.Colors.Primary.b, Renderer.Colors.Primary.a },
            Outline = { Renderer.Colors.Outline.r, Renderer.Colors.Outline.g, Renderer.Colors.Outline.b, Renderer.Colors.Outline.a },
            Scroller = { Renderer.Colors.Selection.r, Renderer.Colors.Selection.g, Renderer.Colors.Selection.b, Renderer.Colors.Selection.a },
            SubHeader = { Renderer.Colors.SubHeader.r, Renderer.Colors.SubHeader.g, Renderer.Colors.SubHeader.b, Renderer.Colors.SubHeader.a },
            SubHeaderTitle = { Renderer.Colors.Title.r, Renderer.Colors.Title.g, Renderer.Colors.Title.b, Renderer.Colors.Title.a },
            Text = { Renderer.Colors.Option.r, Renderer.Colors.Option.g, Renderer.Colors.Option.b, Renderer.Colors.Option.a }
        },
        Text = {
            Font = Renderer.Layout.textFont,
            Size = Renderer.Layout.textSize
        },
        Misc = {
            ColorlessToggles = Renderer.colorlessToggles,
            AnimatedArrows = Renderer.animatedArrows,
            ColorlessToggles = Renderer.colorlessToggles,
            AnimatedArrows = Renderer.animatedArrows,
            Arrows = Renderer.arrowStyle,
            HeaderAlpha = Renderer.headerAlpha,
            BackgroundOpacity = Renderer.Layout.bgOpacity
        },
        Menu = {
            Width = Renderer.Layout.width,
            OptionHeight = Renderer.Layout.optionHeight,
            XPosition = Menu.position.x,
            YPosition = Menu.position.y,
            InfoboxX = Renderer.Layout.infoboxPos.x,
            InfoboxY = Renderer.Layout.infoboxPos.y,
            VehicleInfoX = Renderer.Layout.vehicleInfoPos.x,
            VehicleInfoY = Renderer.Layout.vehicleInfoPos.y,
        },
        Header = themeState.headerIndex - 1, -- 0-indexed in C++
        Footer = themeState.footerIndex - 1,
        Notify = themeState.notifyIndex - 1
    }

    local file = io.open(filename, "w+")
    if file then
        local jsonStr = json.encode(themeData)
        file:write(jsonStr)
        file:close()
        local Settings = require("Impulse/ImpulseLua/lib/settings")
        Settings.CurrentThemeName = name
        Renderer.Notify("Theme saved: " .. name)
    else
        Renderer.Notify("Failed to save theme")
    end
end

function ThemeMenu:Init()
    -- Load themes submenu
    self:AddOption(SubmenuOption.new("Load themes")
        :AddSubmenu(ThemeLoaderMenu.GetInstance())
        :AddTooltip("Load saved themes"))
    

    -- Save theme
    self:AddOption(ButtonOption.new("Save theme")
        :AddFunction(function()
            themeNameInput = TextInputComponent.new("Theme Name", function(text)
                if text and #text > 0 then
                    SaveTheme(text)
                end
            end)
            themeNameInput:Show()
        end)
        :AddTooltip("Save current theme"))
    
    -- Reset theme
    self:AddOption(ButtonOption.new("Reset theme")
        :AddFunction(ResetTheme)
        :AddTooltip("Reset all theme settings to default"))
    
    -- [Customize] section - Color options with swatches
    self:AddOption(BreakOption.new("Customize"))
    
    -- Primary color
    self:AddOption(ColorOption.new("Primary")
        :AddColor(Renderer.Colors.Primary)
        :AddTooltip("Set the primary menu color"))
    
    -- Outline color
    self:AddOption(ColorOption.new("Outline")
        :AddColor(Renderer.Colors.Outline)
        :AddTooltip("Set the menu outline color"))
    
    -- Scroller (Selection) color
    self:AddOption(ColorOption.new("Scroller")
        :AddColor(Renderer.Colors.Selection)
        :AddTooltip("Selected option highlight"))
    
    -- Subheader color
    self:AddOption(ColorOption.new("Subheader")
        :AddColor(Renderer.Colors.SubHeader)
        :AddTooltip("Subheader color"))
    
    -- Subheader title color
    self:AddOption(ColorOption.new("Subheader title")
        :AddColor(Renderer.Colors.Title)
        :AddTooltip("Set the menu subheader title color"))
    
    -- Menu text color (Trainer text)
    self:AddOption(ColorOption.new("Trainer text")
        :AddColor(Renderer.Colors.Option)
        :AddTooltip("Set the menu text color"))
    
    -- [Transparency] section
    self:AddOption(BreakOption.new("Transparency"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Header transparency")
        :AddNumberRef(Renderer, "headerAlpha", "%d", 5)
        :AddMin(0):AddMax(255)
        :AddTooltip("Set the header transparency"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Sub/Footer transparency")
        :AddNumberRef(Renderer.Colors.SubHeader, "a", "%d", 5)
        :AddMin(0):AddMax(255)
        :AddTooltip("Set the subheader and footer transparency"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Option transparency")
        :AddNumberRef(Renderer.Colors.Selection, "a", "%d", 5)
        :AddMin(0):AddMax(255)
        :AddTooltip("Set the option selector transparency"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Primary transparency")
        :AddNumberRef(Renderer.Layout, "bgOpacity", "%d", 1)
        :AddMin(0):AddMax(100)
        :AddTooltip("Set the primary background transparency"))
    
    -- [Font] section
    self:AddOption(BreakOption.new("Font"))
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Font")
        :AddScroll(fonts, 5) -- Default to Chalet Comprime 2
        :AddIndexRef(themeState, "fontIndex")
        :CanLoop()
        :AddFunction(function()
            local font = fonts[themeState.fontIndex]
            if font then
                Renderer.Layout.textFont = font.value
            end
        end)
        :AddTooltip("Change the font type"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Font size")
        :AddNumberRef(Renderer.Layout, "textSize", "%.3f", 0.005)
        :AddMin(0):AddMax(0.55)
        :AddTooltip("Change the font size"))
    
    -- [Trainer] section
    self:AddOption(BreakOption.new("Trainer"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Trainer X axis")
        :AddNumberRef(Menu.position, "x", "%.3f", 0.005)
        :AddMin(-2):AddMax(2)
        :AddTooltip("Change the position of the trainer"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Trainer Y axis")
        :AddNumberRef(Menu.position, "y", "%.3f", 0.005)
        :AddMin(-2):AddMax(2)
        :AddTooltip("Change the position of the trainer"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Infobox X axis")
        :AddNumberRef(Renderer.Layout.infoboxPos, "x", "%.3f", 0.005)
        :AddMin(-2):AddMax(2)
        :AddTooltip("Change the position of the player info box"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Infobox Y axis")
        :AddNumberRef(Renderer.Layout.infoboxPos, "y", "%.3f", 0.005)
        :AddMin(-2):AddMax(2)
        :AddTooltip("Change the position of the player info box"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Vehicle image X axis")
        :AddNumberRef(Renderer.Layout.vehicleInfoPos, "x", "%.3f", 0.005)
        :AddMin(-2):AddMax(2)
        :AddTooltip("Change the position of the vehicle info box"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Vehicle image Y axis")
        :AddNumberRef(Renderer.Layout.vehicleInfoPos, "y", "%.3f", 0.005)
        :AddMin(-2):AddMax(2)
        :AddTooltip("Change the position of the vehicle info box"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Trainer width")
        :AddNumberRef(Renderer.Layout, "width", "%.3f", 0.001)
        :AddMin(0):AddMax(0.5)
        :AddTooltip("Change the width of the menu"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Option height")
        :AddNumberRef(Renderer.Layout, "optionHeight", "%.3f", 0.001)
        :AddMin(0.02):AddMax(0.055)
        :AddTooltip("Change height of the option count"))
    
        :AddTooltip("Change the header ontop of the menu - community headers start with [C]")
        
    -- Custom Header Menu
    local LoadCustomHeaderMenu = require("Impulse/ImpulseLua/submenus/settings/theme_menu/load_custom_header_menu")
    self:AddOption(SubmenuOption.new("Custom headers")
        :AddSubmenu(LoadCustomHeaderMenu.GetInstance())
        :AddTooltip("Load custom headers from Textures/customheader")
        :SetDonor())
        
    -- [Textures] section
    self:AddOption(BreakOption.new("Textures"))
    
    -- Header selection (Moved here)
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Header")
        :AddScroll(headers, 1)
        :AddIndexRef(themeState, "headerIndex")
        :CanLoop()
        :AddFunction(function()
            ThemeMenu.SetHeader(themeState.headerIndex)
        end)
        :AddTooltip("Change the header ontop of the menu - community headers start with [C]"))

    -- Footer selection
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Footer logo")
        :AddScroll(footers, 1)
        :AddIndexRef(themeState, "footerIndex")
        :CanLoop()
        :AddFunction(function()
            local footer = footers[themeState.footerIndex]
            if footer then
                Renderer.Textures.Footer = { dict = footer.dict, name = footer.tex }
            end
        end)
        :AddTooltip("Change the footer logo"))

    -- Notify selection
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Notify logo")
        :AddScroll(notifies, 1)
        :AddIndexRef(themeState, "notifyIndex")
        :CanLoop()
        :AddFunction(function()
            local notify = notifies[themeState.notifyIndex]
            if notify then
                Renderer.Textures.Notify = { dict = notify.dict, name = notify.tex }
                Renderer.Notify("Test notification")
            end
        end)
        :AddTooltip("Change the notification logo"))
    
    -- [Misc] section
    self:AddOption(BreakOption.new("Misc"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Arrows")
        :AddNumberRef(themeState, "arrows", "%i", 1)
        :AddMin(0):AddMax(5)
        :AddFunction(function()
            Renderer.arrowStyle = themeState.arrows
        end)
        :AddTooltip("Change the arrow design"))
    
    self:AddOption(ToggleOption.new("Colorless toggles")
        :AddToggleRef(themeState, "colorlessToggles")
        :AddFunction(function()
            Renderer.colorlessToggles = themeState.colorlessToggles
        end)
        :AddTooltip("Use colorless toggles"))
    
    self:AddOption(ToggleOption.new("Animated arrows")
        :AddToggleRef(themeState, "animatedArrows")
        :AddFunction(function()
            Renderer.animatedArrows = themeState.animatedArrows
        end)
        :AddTooltip("Use animated submenu arrows"))
    
    self:AddOption(ToggleOption.new("Show Menu Version")
        :AddToggleRef(Renderer, "showVersion")
        :AddTooltip("Displays the current version of the script in the footer"))
    
    self:AddOption(BreakOption.new("Rainbow"))

    -- Main "Rainbow elements" (all)
    self:AddOption(ToggleOption.new("Rainbow elements of trainer")
        :AddToggleRef(themeState, "rainbow")
        :AddRequirement(function() return not themeState.rainbowOutline and not themeState.rainbowScroller and not themeState.rainbowSubheader end)
        :AddTooltip("Make certain elements of the trainer rainbow color"))
    
    self:AddOption(ButtonOption.new("~c~Rainbow elements of trainer~s~")
        :AddRequirement(function() return themeState.rainbowOutline or themeState.rainbowScroller or themeState.rainbowSubheader end))

    -- Rainbow outline
    self:AddOption(ToggleOption.new("Rainbow outline of trainer")
        :AddToggleRef(themeState, "rainbowOutline")
        :AddRequirement(function() return not themeState.rainbow end)
        :AddTooltip("Make a certain element of the trainer rainbow color"))
    
    self:AddOption(ButtonOption.new("~c~Rainbow outline of trainer~s~")
        :AddRequirement(function() return themeState.rainbow end))

    -- Rainbow scroller
    self:AddOption(ToggleOption.new("Rainbow scroller of trainer")
        :AddToggleRef(themeState, "rainbowScroller")
        :AddRequirement(function() return not themeState.rainbow end)
        :AddTooltip("Make a certain element of the trainer rainbow color"))
    
    self:AddOption(ButtonOption.new("~c~Rainbow scroller of trainer~s~")
        :AddRequirement(function() return themeState.rainbow end))

    -- Rainbow subheader
    self:AddOption(ToggleOption.new("Rainbow subheader of trainer")
        :AddToggleRef(themeState, "rainbowSubheader")
        :AddRequirement(function() return not themeState.rainbow end)
        :AddTooltip("Make a certain element of the trainer rainbow color"))

    self:AddOption(ButtonOption.new("~c~Rainbow subheader of trainer~s~")
        :AddRequirement(function() return themeState.rainbow end))

    -- Initialize default header (Pulse)
    ThemeMenu.SetHeader(themeState.headerIndex)
end

--- Feature update - runs every frame for rainbow effects and animations
function ThemeMenu:FeatureUpdate()
    -- Handle animations
    if animationState.active and #animationState.frames > 0 then
        local currentTime = MISC.GET_GAME_TIMER()
        if currentTime - animationState.lastTime >= animationState.interval then
            -- Advance frame
            animationState.currentFrame = animationState.currentFrame + 1
            if animationState.currentFrame > #animationState.frames then
                animationState.currentFrame = 1
            end
            animationState.lastTime = currentTime
            
            -- Update renderer header
            local frame = animationState.frames[animationState.currentFrame]
            if frame then
                Renderer.Textures.Header = { dict = frame.dict, name = frame.name }
            end
        end
    end

    if themeState.rainbow then
        CycleRainbow(rainbowColors.primary)
        CycleRainbow(rainbowColors.secondary) 
        CycleRainbow(rainbowColors.tertiary)
        
        Renderer.Colors.Outline.r = rainbowColors.primary.r
        Renderer.Colors.Outline.g = rainbowColors.primary.g
        Renderer.Colors.Outline.b = rainbowColors.primary.b
        
        Renderer.Colors.Selection.r = rainbowColors.secondary.r
        Renderer.Colors.Selection.g = rainbowColors.secondary.g
        Renderer.Colors.Selection.b = rainbowColors.secondary.b
        
        Renderer.Colors.SubHeader.r = rainbowColors.tertiary.r
        Renderer.Colors.SubHeader.g = rainbowColors.tertiary.g
        Renderer.Colors.SubHeader.b = rainbowColors.tertiary.b
    else
        if themeState.rainbowOutline then
            CycleRainbow(rainbowColors.primary)
            Renderer.Colors.Outline.r = rainbowColors.primary.r
            Renderer.Colors.Outline.g = rainbowColors.primary.g
            Renderer.Colors.Outline.b = rainbowColors.primary.b
        end
        
        if themeState.rainbowScroller then
            CycleRainbow(rainbowColors.secondary)
            Renderer.Colors.Selection.r = rainbowColors.secondary.r
            Renderer.Colors.Selection.g = rainbowColors.secondary.g
            Renderer.Colors.Selection.b = rainbowColors.secondary.b
        end
        
        if themeState.rainbowSubheader then
            CycleRainbow(rainbowColors.tertiary)
            Renderer.Colors.SubHeader.r = rainbowColors.tertiary.r
            Renderer.Colors.SubHeader.g = rainbowColors.tertiary.g
            Renderer.Colors.SubHeader.b = rainbowColors.tertiary.b
        end
    end

    -- Handle text input
    if themeNameInput and themeNameInput:IsVisible() then
        themeNameInput:Update()
    end
    
    -- Render demo overlays if this menu is open
    if Menu.currentSubmenu == ThemeMenu.GetInstance() then
        -- Player Info
        PlayerInfoComponent.SetPlayer(PLAYER.PLAYER_ID()) -- Show local player
        PlayerInfoComponent.Render()
        
        -- Vehicle Info
        if not demoVehicleComponent then
            demoVehicleComponent = UIVehicleComponent.new()
            demoVehicleComponent:SetModel("dominator")
            -- Mock parent window for standalone rendering
            demoVehicleComponent.parent = {
                position = { x = 0, y = 0 },
                size = { w = 0.235, h = 0.31 },
                headerHeight = 0.083, -- Default header height
                name = "VEHICLE INFO"
            }
        end
        demoVehicleComponent:Render()
    end
end

-- Export state
ThemeMenu.State = themeState

return ThemeMenu
