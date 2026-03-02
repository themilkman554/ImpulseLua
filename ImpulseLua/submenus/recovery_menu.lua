local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

-- Import submenus
local MoneyMenu = require("Impulse/ImpulseLua/submenus/recovery/money_menu")
local UnlocksMenu = require("Impulse/ImpulseLua/submenus/recovery/unlocks_menu")
local StatsMenu = require("Impulse/ImpulseLua/submenus/recovery/stats_menu")
local KDMenu = require("Impulse/ImpulseLua/submenus/recovery/kd_menu")

local RecoveryMenu = setmetatable({}, { __index = Submenu })
RecoveryMenu.__index = RecoveryMenu

local instance = nil

local vars = {
    rpIncreaser = false,
    rpIncreaserEvent = false
}

function RecoveryMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Recovery"), RecoveryMenu)
        instance:Init()
    end
    return instance
end

local TextInputComponent = require("Impulse/ImpulseLua/lib/ui/text_input_component")

local RP_LEVEL_HASH = 3767831223
local RP_SET_HASH = 251344530
local CREW_LEVEL_HASH = 1991529484
local CREW_SET_HASH = 716207572

local levelInput = nil
local crewLevelInput = nil

function RecoveryMenu:Init()
    self:AddOption(SubmenuOption.new("Money")
        :AddSubmenu(MoneyMenu.GetInstance())
        :AddTooltip("Money options"))

    self:AddOption(SubmenuOption.new("Unlocks")
        :AddSubmenu(UnlocksMenu.GetInstance())
        :AddTooltip("Unlocks"))

    self:AddOption(SubmenuOption.new("Stat editor")
        :AddSubmenu(StatsMenu.GetInstance())
        :AddTooltip("Stat editor"))

    self:AddOption(SubmenuOption.new("KD editor")
        :AddSubmenu(KDMenu.GetInstance())
        :AddTooltip("KD editor"))

    self:AddOption(BreakOption.new("Level"))

    self:AddOption(ButtonOption.new("Set custom level")
        :AddFunction(function()
                if not levelInput then
                levelInput = TextInputComponent.new("Level (0-8000)", function(text)
                    local rank = tonumber(text)
                    if rank then
                        FeatureMgr.SetFeatureInt(RP_LEVEL_HASH, rank)
                        FeatureMgr.TriggerFeatureCallback(RP_SET_HASH)
                    end
                end)
            end
            levelInput:Show()
        end)
        :AddTooltip("Sets the level to the users input. You'll receive a notification when changing session"))

    self:AddOption(ButtonOption.new("Set custom crew level")
        :AddFunction(function()
            if not crewLevelInput then
                crewLevelInput = TextInputComponent.new("Crew Level (0-8000)", function(text)
                    local rank = tonumber(text)
                    if rank then
                        FeatureMgr.SetFeatureInt(CREW_LEVEL_HASH, rank)
                        FeatureMgr.TriggerFeatureCallback(CREW_SET_HASH)
                    end
                end)
            end
            crewLevelInput:Show()
        end)
        :AddTooltip("Sets the users crew levels to what is inputted."))

    self:AddOption(BreakOption.new("Misc"))


    self:AddOption(ButtonOption.new("Bypass tutorial")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Set Prologue Complete"):TriggerCallback()
        end)
        :AddTooltip("Bypass tutorial"))

    self:AddOption(ButtonOption.new("Redesign character")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Enable Character Redesign"):TriggerCallback()
        end)
        :AddTooltip("Redesign character, activate in sp and then go online"))

    self:AddOption(ButtonOption.new("Change character gender")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Allow Gender Change"):TriggerCallback()
        end)
        :AddTooltip("Press M - style - change appearence"))

    self:AddOption(ButtonOption.new("Clear mental state")
        :AddFunction(function()
            -- Placeholder
        end)
        :AddTooltip("Clears your current mental state"))

    self:AddOption(ButtonOption.new("Modded rolls + more ammo (shooting ability)")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Unlock Max Abilities"):TriggerCallback()
        end)
        :AddTooltip("Modded rolls + more ammo (shooting ability)"))
end

function RecoveryMenu:FeatureUpdate()
    MoneyMenu.GetInstance():FeatureUpdate()
    if levelInput and levelInput:IsVisible() then
        levelInput:Update()
    end
    if crewLevelInput and crewLevelInput:IsVisible() then
        crewLevelInput:Update()
    end
end

return RecoveryMenu
