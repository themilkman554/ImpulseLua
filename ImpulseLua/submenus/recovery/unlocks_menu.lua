--[[
    Impulse Lua - Unlocks Menu
    Unlock options
    Port of unlocksMenu.h/cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local UnlocksMenu = setmetatable({}, { __index = Submenu })
UnlocksMenu.__index = UnlocksMenu

local instance = nil

function UnlocksMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Unlocks"), UnlocksMenu)
        instance:Init()
    end
    return instance
end

function UnlocksMenu:Init()
    self:AddOption(ButtonOption.new("Unlock tattoos")
        :AddFunction(function() FeatureMgr.TriggerFeatureCallback(3706966968) end)
        :AddTooltip("Unlock all tattoos"))

    self:AddOption(ButtonOption.new("Unlock clothing")
        :AddFunction(function() FeatureMgr.GetFeatureByName("Unlock Clothing"):TriggerCallback() end)
        :AddTooltip("Unlock all clothing"))

    self:AddOption(ButtonOption.new("Unlock hairstyles")
        :AddFunction(function() FeatureMgr.GetFeatureByName("Unlock Hair Cuts"):TriggerCallback() end)
        :AddTooltip("Unlock all hairstyles"))

    self:AddOption(BreakOption.new("Vehicles"))

    self:AddOption(ButtonOption.new("Unlock vehicle mods")
        :AddFunction(function() FeatureMgr.GetFeatureByName("Unlock Vehicle Mods"):TriggerCallback() end)
        :AddTooltip("Unlock all vehicle mods"))

    self:AddOption(BreakOption.new("Inventory"))

    self:AddOption(ButtonOption.new("Max snacks")
        :AddFunction(function() FeatureMgr.GetFeatureByName("Give Max Snacks"):TriggerCallback() end)
        :AddTooltip("Max snacks"))

    self:AddOption(ButtonOption.new("Max armor")
        :AddFunction(function() FeatureMgr.GetFeatureByName("Give Max Armor"):TriggerCallback() end)
        :AddTooltip("Max armor"))

    self:AddOption(BreakOption.new("Misc"))

    self:AddOption(ButtonOption.new("Unlock weapon skins")
        :AddFunction(function() FeatureMgr.GetFeatureByName("Unlock Camos"):TriggerCallback() end)
        :AddTooltip("Unlock all weapon skins"))

    self:AddOption(ButtonOption.new("Unlock achievements and stats")
        :AddFunction(function() FeatureMgr.GetFeatureByName("Unlock all achievements."):TriggerCallback() end)
        :AddTooltip("Unlock all achievements and stats"))

    self:AddOption(ButtonOption.new("Unlock office money clutter")
        :AddFunction(function() FeatureMgr.GetFeatureByName("Unlock CEO/MC Cash Piles"):TriggerCallback() end)
        :AddTooltip("Once activated, buy some special cargo, do mission, goto warehouse, sell cargo, do mission, go back to office."))

    self:AddOption(ButtonOption.new("Unlock all bunker research")
        :AddFunction(function() FeatureMgr.GetFeatureByName("Unlock Bunker Researches"):TriggerCallback() end)
        :AddTooltip("This will perma unlock all bunker research"))
end

return UnlocksMenu
