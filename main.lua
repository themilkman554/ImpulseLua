--impulse lua port
package.path = FileMgr.GetMenuRootPath() .. "\\Lua\\?.lua;"

Script.QueueJob(function()
    local AssetDownloader = require("Impulse/ImpulseLua/lib/asset_downloader")
    if AssetDownloader then
        AssetDownloader.CheckAssets()
    end

    local status = require("Impulse/Impulse-main/natives")

    local Renderer = require("Impulse/ImpulseLua/lib/renderer")
    local Menu = require("Impulse/ImpulseLua/lib/menu")
    local MainMenu = require("Impulse/ImpulseLua/submenus/main_menu")
    local WindowManager = require("Impulse/ImpulseLua/lib/ui/window_manager")
    local Scaleform = require("Impulse/ImpulseLua/lib/scaleform")

    local LocalMenu = require("Impulse/ImpulseLua/submenus/local_menu")
    local WeaponMenu = require("Impulse/ImpulseLua/submenus/weapon_menu")

    local Settings = require("Impulse/ImpulseLua/lib/settings")
    local ConfigMgr = require("Impulse/ImpulseLua/lib/config_mgr")
    local KeyOption = require("Impulse/ImpulseLua/lib/options/key")
    local PaidTier = require("Impulse/ImpulseLua/lib/paid_tier")
    local HotkeyManager = require("Impulse/ImpulseLua/lib/hotkey_manager")
    local PlayerDataCache = require("Impulse/ImpulseLua/lib/player_data_cache")

    local SCRIPT_NAME = "Impulse Lua"
    local SCRIPT_VERSION = "1.0.9"

    local initialized = false
    local firstOpen = true

    local textureRootPath = FileMgr.GetMenuRootPath() .. "\\Lua\\Impulse\\Impulse-main\\Textures"
    local bookmarksYtdPath = textureRootPath .. "\\Bookmarks.ytd"

    local function LoadTextures()
        if FileMgr.DoesFileExist(bookmarksYtdPath) then
            if Cherax.GetEdition() == "LE" or Cherax.GetEdition() == "LE BE" then
                local success = GTA.RegisterFile(bookmarksYtdPath)
            end
            if success then
                Logger.LogInfo("Impulse Lua: Registered Bookmarks.ytd")
                GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("Bookmarks", false)
            end
        end
        
        GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("commonmenu", false)
        GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("mpleaderboard", false)
    end

    local function Initialize()
        local timeout = MISC.GET_GAME_TIMER() + 5000
        while not PaidTier.Finished and MISC.GET_GAME_TIMER() < timeout do
            Script.Yield()
        end
    
        LoadTextures()
        
        Renderer.ScriptVersion = SCRIPT_VERSION
        
        WindowManager.GetInstance()
        
        Menu.SetRootSubmenu(MainMenu.GetInstance())
        
        initialized = true
        Menu.Open() 
        
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
        
        if Cherax.GetEdition() == "EE" or Cherax.GetEdition() == "EE BE" then
            Renderer.useImGui = true
            Renderer.PreloadImGuiTextures()
            Logger.LogInfo("Impulse Lua: Alt Rendering Mode auto-enabled for EE edition")
        end
        
        ConfigMgr.AutoLoad()
        
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
        
        Scaleform:Update()
        
        WindowManager.GetInstance():Update()
        
        Menu.ProcessInput()
        
        HotkeyManager.GetInstance():Update()
        
        Menu.Render()
        
        Renderer.PresentImGuiFrame()
        
        WindowManager.GetInstance():Render()
        
        if LocalMenu.GetInstance().FeatureUpdate then
            LocalMenu.GetInstance():FeatureUpdate()
        end
        if WeaponMenu.GetInstance().FeatureUpdate then
            WeaponMenu.GetInstance():FeatureUpdate()
        end
        if MainMenu.GetInstance().FeatureUpdate then
            MainMenu.GetInstance():FeatureUpdate()
        end

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
        
        local ConfigMenu = require("Impulse/ImpulseLua/submenus/settings/config_menu")
        if ConfigMenu.GetInstance().FeatureUpdate then
            ConfigMenu.GetInstance():FeatureUpdate()
        end
        
        local ThemeMenu = require("Impulse/ImpulseLua/submenus/settings/theme_menu")
        if ThemeMenu.GetInstance().FeatureUpdate then
            ThemeMenu.GetInstance():FeatureUpdate()
        end
        
        local WorldMenu = require("Impulse/ImpulseLua/submenus/world_menu")
        if WorldMenu.GetInstance().FeatureUpdate then
            WorldMenu.GetInstance():FeatureUpdate()
        end

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
        
        local VehicleMenu = require("Impulse/ImpulseLua/submenus/vehicle_menu")
        if VehicleMenu.GetInstance().FeatureUpdate then
            VehicleMenu.GetInstance():FeatureUpdate()
        end
    end

    Script.RegisterLooped(OnTick)


    if PaidTier.CheckRemote then
        PaidTier.CheckRemote()
    end
    

    Initialize()

   
    local bindingOpenKey = false
    local bindingStartTime = 0
    local bindingKeyStates = {}

    ClickGUI.AddTab("Impulse", function()
        if ClickGUI.BeginCustomChildWindow("Impulse") then
            if ImGui.BeginTable("ImpulseLayout", 2, ImGuiTableFlags.SizingStretchSame) then
                ImGui.TableNextRow()
                

                ImGui.TableSetColumnIndex(0)
                if ClickGUI.BeginCustomChildWindow("Settings") then
                    ImGui.Spacing()
                    ImGui.Text("Press " .. KeyOption.GetKeyNameStatic(Settings.OpenKey) .. " or D-Pad Left + R1 on controller\nto open menu")
                    ImGui.Separator()
                    

                    local keyName = KeyOption.GetKeyNameStatic(Settings.OpenKey)
                    if bindingOpenKey then
                        ImGui.Button("Press any key...")
                        
                        local canTrigger = MISC.GET_GAME_TIMER() - bindingStartTime > 1000
                        local triggeredVk = nil

                        if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 202) then
                            bindingOpenKey = false
                        else
                            for i = 1, 254 do
                                if i ~= 1 then 
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
                    
                    if Cherax.GetEdition() ~= "EE" and Cherax.GetEdition() ~= "EE BE" then
                        ImGui.SameLine()
                        local oldValue = Renderer.useImGui or false
                        local newValue = ImGui.Checkbox("Alt Rendering Mode", oldValue)
                        if newValue ~= oldValue then
                            Renderer.useImGui = newValue
                            Logger.LogInfo("Impulse Lua: Alt Rendering Mode set to " .. tostring(Renderer.useImGui))
                            if newValue then
                                Script.QueueJob(function()
                                    Renderer.PreloadImGuiTextures()
                                end)
                            end
                        end
                    end
                    
                    ClickGUI.EndCustomChildWindow()
                end
                
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
                    
                    ImGui.Text("UID: " .. tostring(Cherax.GetUID()))
                    ImGui.SameLine()
                    if ImGui.Button("Clipboard##UID") then
                        Utils.SetClipBoardText(tostring(Cherax.GetUID()), "")
                    end
                    
                    ImGui.Text("Tier: ")
                    ImGui.SameLine()
                    
                    if PaidTier.IsPaid() then
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
