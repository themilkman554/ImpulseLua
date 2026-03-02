--[[
    Impulse Lua - Global Settings
    Shared settings accessible across all modules
]]

local Settings = {}

-- Always enabled (no restrictions)
Settings.DevMode = true
Settings.VIPMode = true
Settings.AllowMove = false -- Allow gameplay while using mouse
Settings.KeepLastPos = true
Settings.SpeedUpSmoothScroll = false
Settings.DisableSmoothScroll = false
Settings.DisableControllerInput = false
Settings.HideUITooltips = false
Settings.HideCursorTooltip = false
Settings.HidePlayerIPs = false
Settings.HidePlayerRIDs = false -- Hide Rockstar IDs
Settings.HideMap = false
Settings.OutlineOnScreenElements = false
Settings.ColorScreenElements = { r = 255, g = 255, b = 255, a = 255 }
Settings.UnoutlineStuffs = false

-- Language
Settings.Language = ""               -- Currently loaded language file name
Settings.LoadLanguageOnStart = false  -- Load selected language on startup

-- Scroll options
Settings.HideType = 1 -- 1: Always, 2: When menu open, 3: Never
Settings.MeasurementType = 0 -- 0: Imperial, 1: Metric

-- Keys
Settings.OpenKey = 45 -- Insert
Settings.ControllerKey1 = 0
Settings.ControllerKey2 = 0

-- Mouse Settings
Settings.MouseEnabled = true
Settings.MouseMoveEnabled = true
Settings.AllowMenuCloseByBack = true

Settings.AutoLoadConfig = false
Settings.AutoLoadConfigName = ""
Settings.AutoLoadThemeName = ""
Settings.CurrentThemeName = ""

return Settings
