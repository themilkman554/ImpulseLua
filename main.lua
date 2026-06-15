--impulse lua port
package.path = FileMgr.GetMenuRootPath() .. "\\Lua\\?.lua;"

-- Wrap initialization in a thread to allow blocking downloads (Yield)
Script.QueueJob(function()
    -- 1. Asset Downloader (Runs before everything else)
    local AssetDownloader = require("Impulse/ImpulseLua/lib/asset_downloader")
    if AssetDownloader then
        -- This function calls Script.Yield() if downloading, preventing game freeze
        AssetDownloader.CheckAssets()
    end

    -- 2. Load Core Dependencies (Natives)
    local status, result = pcall(require, "Impulse/Impulse-main/natives")
    if not status then
        GUI.AddToast("Impulse", "Failed to load natives: " .. tostring(result), 10000, 0)
    end

    -- 3. Load UI & Libs
    local Renderer = require("Impulse/ImpulseLua/lib/renderer")
    local Menu = require("Impulse/ImpulseLua/lib/menu")
    local MainMenu = require("Impulse/ImpulseLua/submenus/main_menu")
    local WindowManager = require("Impulse/ImpulseLua/lib/ui/window_manager")
    local Scaleform = require("Impulse/ImpulseLua/lib/scaleform")

    local LocalMenu = require("Impulse/ImpulseLua/submenus/local_menu")
    local WeaponMenu = require("Impulse/ImpulseLua/submenus/weapon_menu")

    -- Import libraries
    local Settings = require("Impulse/ImpulseLua/lib/settings")
    local ConfigMgr = require("Impulse/ImpulseLua/lib/config_mgr")
    local KeyOption = require("Impulse/ImpulseLua/lib/options/key")
    local PaidTier = require("Impulse/ImpulseLua/lib/paid_tier")
    local HotkeyManager = require("Impulse/ImpulseLua/lib/hotkey_manager")
    local PlayerDataCache = require("Impulse/ImpulseLua/lib/player_data_cache")

    -- Script info
    local SCRIPT_NAME = "Impulse Lua"
    local SCRIPT_VERSION = "1.1.0"

    local initialized = false
    local firstOpen = true

    -- Texture paths
    local textureRootPath = FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Impulse-main\\Textures"
    local bookmarksYtdPath = textureRootPath .. "\\Bookmarks.ytd"

    local function LoadTextures()
        -- Check if Bookmarks.ytd exists
        if FileMgr.DoesFileExist(bookmarksYtdPath) then
            if Cherax.GetEdition() == "LE" or Cherax.GetEdition() == "LE BE" then
                local success = GTA.RegisterFile(bookmarksYtdPath)
            end
            if success then
                Logger.LogInfo("Impulse Lua: Registered Bookmarks.ytd")
                -- Request the texture dictionary
                GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("Bookmarks", false)
            end
        end
        
        GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("commonmenu", false)
        GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("mpleaderboard", false)
    end

    local function Initialize()
        -- Wait for PaidTier to finish remote check
        local timeout = MISC.GET_GAME_TIMER() + 5000
        while not PaidTier.Finished and MISC.GET_GAME_TIMER() < timeout do
            Script.Yield()
        end
    
        LoadTextures()
        
        -- Expose version to Renderer
        Renderer.ScriptVersion = SCRIPT_VERSION
        
        WindowManager.GetInstance()
        
        Menu.SetRootSubmenu(MainMenu.GetInstance())
        
        initialized = true
        Menu.Open() 
        
        -- Set active menu tab to LuaTab
        ClickGUI.SetActiveMenuTab(ClickTab.LuaTab)
        local openKeyName = KeyOption.GetKeyNameStatic(Menu.openKey)
        
        local role = PaidTier.IsPaid() and "VIP" or "Free"
        local username = PLAYER.GET_PLAYER_NAME(PLAYER.PLAYER_ID())
        local message = string.format("Welcome %s ~b~- ~y~%s", username, role)

        Scaleform:DrawLargeMessage(
            "~b~∑ ~s~IMPULSE ~b~∑",
            message,
            10, 
            600
        )
        
        WindowManager.GetInstance():Log(string.format("Impulse Lua v%s loaded for %s (%s)", SCRIPT_VERSION, username, role), { r = 100, g = 255, b = 100, a = 255 })
        
        -- Auto-enable Alt Rendering Mode for EE edition
        if Cherax.GetEdition() == "EE" or Cherax.GetEdition() == "EE BE" then
            Renderer.useImGui = true
            Renderer.PreloadImGuiTextures()
            Logger.LogInfo("Impulse Lua: Alt Rendering Mode auto-enabled for EE edition")
        end
        
        -- Auto Load Config
        -- Auto Load Config
        ConfigMgr.AutoLoad()
        
        -- Sync Settings
        Menu.openKey = Settings.OpenKey or 45
        
        
        
        Logger.Log(eLogColor.LIGHTBLUE, "", "██╗███╗   ███╗██████╗ ██╗   ██╗██╗     ███████╗███████╗")
        Logger.Log(eLogColor.LIGHTBLUE, "", "██║████╗ ████║██╔══██╗██║   ██║██║     ██╔════╝██╔════╝")
        Logger.Log(eLogColor.LIGHTBLUE, "", "██║██╔████╔██║██████╔╝██║   ██║██║     ███████╗█████╗  ")
        Logger.Log(eLogColor.LIGHTBLUE, "", "██║██║╚██╔╝██║██╔═══╝ ██║   ██║██║     ╚════██║██╔══╝  ")
        Logger.Log(eLogColor.LIGHTBLUE, "", "██║██║ ╚═╝ ██║██║     ╚██████╔╝███████╗███████║███████╗")
        Logger.Log(eLogColor.LIGHTBLUE, "", "╚═╝╚═╝     ╚═╝╚═╝      ╚═════╝ ╚══════╝╚══════╝╚══════╝")
        Logger.Log(eLogColor.LIGHTBLUE, "", "                                                       ")

        Logger.LogInfo(SCRIPT_NAME .. " loaded! Press " .. openKeyName .. " to open.")
        Logger.LogInfo("Join Discord: https://discord.gg/ctnbevsz54")
        Renderer.NotifyMapColor("Press " .. openKeyName .. " to open menu.", 18)
    end

    local function OnTick()
        if ShouldUnload() then return end
        if not initialized then return end
        
        -- Update scaleform messages
        Scaleform:Update()
        
        -- Update window manager (handles floating windows)
        WindowManager.GetInstance():Update()
        
        -- Process menu input
        Menu.ProcessInput()
        
        -- Update hotkeys (triggers hotkey actions when keys are released)
        HotkeyManager.GetInstance():Update()
        
        -- Render menu if open
        Menu.Render()
        
        -- Present the ImGui frame (updates render queue for ON_PRESENT)
        Renderer.PresentImGuiFrame()
        
        -- Render floating windows on top
        WindowManager.GetInstance():Render()
        
        -- Run feature updates for active toggles
        -- These run even when menu is closed
        if LocalMenu.GetInstance().FeatureUpdate then
            LocalMenu.GetInstance():FeatureUpdate()
        end
        if WeaponMenu.GetInstance().FeatureUpdate then
            WeaponMenu.GetInstance():FeatureUpdate()
        end
        if MainMenu.GetInstance().FeatureUpdate then
            MainMenu.GetInstance():FeatureUpdate()
        end

        -- Misc menu features
        local MiscMenu = require("Impulse/ImpulseLua/submenus/misc_menu")
        if MiscMenu.GetInstance().FeatureUpdate then
            MiscMenu.GetInstance():FeatureUpdate()
        end
        
        local TVMenu = require("Impulse/ImpulseLua/submenus/misc/tv_menu")
        if TVMenu.GetInstance().FeatureUpdate then
            TVMenu.GetInstance():FeatureUpdate()
        end
        
        local DisablesMenu = require("Impulse/ImpulseLua/submenus/misc/disables_menu")
        if DisablesMenu.GetInstance().FeatureUpdate then
            DisablesMenu.GetInstance():FeatureUpdate()
        end

        local TrainOptionsMenu = require("Impulse/ImpulseLua/submenus/misc/train_options_menu")
        if TrainOptionsMenu.GetInstance().FeatureUpdate then
            TrainOptionsMenu.GetInstance():FeatureUpdate()
        end
        
        local MovementMenu = require("Impulse/ImpulseLua/submenus/player/movement_menu")

        local SessionMenu = require("Impulse/ImpulseLua/submenus/session_menu")
        if SessionMenu.GetInstance().FeatureUpdate then
            SessionMenu.GetInstance():FeatureUpdate()
        end
        
        -- Config menu features (save input)
        local ConfigMenu = require("Impulse/ImpulseLua/submenus/settings/config_menu")
        if ConfigMenu.GetInstance().FeatureUpdate then
            ConfigMenu.GetInstance():FeatureUpdate()
        end
        
        -- Theme menu features (rainbow colors)
        local ThemeMenu = require("Impulse/ImpulseLua/submenus/settings/theme_menu")
        if ThemeMenu.GetInstance().FeatureUpdate then
            ThemeMenu.GetInstance():FeatureUpdate()
        end
        
        -- World menu features (turrets, density, etc.)
        local WorldMenu = require("Impulse/ImpulseLua/submenus/world_menu")
        if WorldMenu.GetInstance().FeatureUpdate then
            WorldMenu.GetInstance():FeatureUpdate()
        end
        
        -- World submenus
        local WeatherMenu = require("Impulse/ImpulseLua/submenus/world/weather_menu")
        if WeatherMenu.GetInstance().FeatureUpdate then
            WeatherMenu.GetInstance():FeatureUpdate()
        end
        
        local WaypointMenu = require("Impulse/ImpulseLua/submenus/world/waypoint_menu")
        if WaypointMenu.GetInstance().FeatureUpdate then
            WaypointMenu.GetInstance():FeatureUpdate()
        end
        
        local TrafficMenu = require("Impulse/ImpulseLua/submenus/world/traffic_menu")
        if TrafficMenu.GetInstance().FeatureUpdate then
            TrafficMenu.GetInstance():FeatureUpdate()
        end
        
        local PedMenu = require("Impulse/ImpulseLua/submenus/world/ped_menu")
        if PedMenu.GetInstance().FeatureUpdate then
            PedMenu.GetInstance():FeatureUpdate()
        end
        
        -- Vehicle menu features (godmode, auto repair, rainbow, etc.)
        local VehicleMenu = require("Impulse/ImpulseLua/submenus/vehicle_menu")
        if VehicleMenu.GetInstance().FeatureUpdate then
            VehicleMenu.GetInstance():FeatureUpdate()
        end
    end

    -- Register main loop inside the job
    Script.RegisterLooped(OnTick)

    -- Initialize features
    if PaidTier.CheckRemote then
        PaidTier.CheckRemote()
    end
    
    -- Run Initialization
    Initialize()

    -- GUI Registration
    local bindingOpenKey = false
    local bindingStartTime = 0
    local bindingKeyStates = {}

    ClickGUI.AddTab("Impulse", function()
        if ClickGUI.BeginCustomChildWindow("Impulse") then
            if ImGui.BeginTable("ImpulseLayout", 2, ImGuiTableFlags.SizingStretchSame) then
                ImGui.TableNextRow()
                
                -- Column 1: Settings
                ImGui.TableSetColumnIndex(0)
                if ClickGUI.BeginCustomChildWindow("Settings") then
                    ImGui.Spacing()
                    ImGui.Text("Press " .. KeyOption.GetKeyNameStatic(Settings.OpenKey) .. " or D-Pad Left + R1 on controller\nto open menu")
                    ImGui.Separator()
                    
                    -- Open Key Binding
                    local keyName = KeyOption.GetKeyNameStatic(Settings.OpenKey)
                    if bindingOpenKey then
                        ImGui.Button("Press any key...")
                        
                        -- Check input after delay to avoid registering the click
                        
                        local canTrigger = MISC.GET_GAME_TIMER() - bindingStartTime > 1000
                        local triggeredVk = nil

                        -- Check Esc to cancel
                        if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 202) then
                            bindingOpenKey = false
                        else
                            for i = 1, 254 do
                                if i ~= 1 then -- Ignore Left Mouse
                                    local isPressed = Utils.IsKeyDown(i)
                                    local wasPressed = bindingKeyStates[i] or false
                                    bindingKeyStates[i] = isPressed
                                    
                                    if canTrigger and isPressed and not wasPressed then
                                        triggeredVk = i
                                        break
                                    end
                                end
                            end

                            if triggeredVk then
                                Settings.OpenKey = triggeredVk
                                Menu.openKey = triggeredVk
                                ConfigMgr.SaveGlobalSettings()
                                Renderer.Notify("Open key updated")
                                bindingOpenKey = false
                            end
                        end
                    else
                        if ImGui.Button("Open Key: " .. keyName) then
                            bindingOpenKey = true
                            bindingKeyStates = {}
                            bindingStartTime = MISC.GET_GAME_TIMER()
                        end
                    end
                    
                    -- Alt Rendering Toggle - only show for non-EE editions (EE has it auto-enabled)
                    if Cherax.GetEdition() ~= "EE" and Cherax.GetEdition() ~= "EE BE" then
                        ImGui.SameLine()
                        local oldValue = Renderer.useImGui or false
                        local newValue = ImGui.Checkbox("Alt Rendering Mode", oldValue)
                        if newValue ~= oldValue then
                            Renderer.useImGui = newValue
                            Logger.LogInfo("Impulse Lua: Alt Rendering Mode set to " .. tostring(Renderer.useImGui))
                            -- Preload all textures in native thread when enabling to avoid issues
                            if newValue then
                                Script.QueueJob(function()
                                    Renderer.PreloadImGuiTextures()
                                end)
                            end
                        end
                    end
                    
                    ClickGUI.EndCustomChildWindow()
                end
                
                -- Column 2: Version
                ImGui.TableSetColumnIndex(1)
                if ClickGUI.BeginCustomChildWindow("Version") then
                    ImGui.Spacing()
                    if not PaidTier.IsPaid() then
                        ImGui.Text("To Purchase Donor Join Discord")
                        ImGui.SameLine()
                        if ImGui.Button("Clipboard##Discord") then
                            Utils.SetClipBoardText("https://discord.gg/ctnbevsz54", "")
                        end
                        ImGui.Separator()
                    end
                    
                    -- UID and Tier Info
                    ImGui.Text("UID: " .. tostring(Cherax.GetUID()))
                    ImGui.SameLine()
                    if ImGui.Button("Clipboard##UID") then
                        Utils.SetClipBoardText(tostring(Cherax.GetUID()), "")
                    end
                    
                    ImGui.Text("Tier: ")
                    ImGui.SameLine()
                    
                    if PaidTier.IsPaid() then
                        -- ImGuiCol_Text is 0. Use RGBA floats (0.0-1.0)
                        ImGui.PushStyleColor(0, 0.0, 1.0, 0.0, 1.0)
                        ImGui.Text("Donor")
                        ImGui.PopStyleColor()
                    else
                        ImGui.Text("Free")
                    end
                    
                    ClickGUI.EndCustomChildWindow()
                end
                
                ImGui.EndTable()
            end
            ClickGUI.EndCustomChildWindow()
        end
    end)
end)
