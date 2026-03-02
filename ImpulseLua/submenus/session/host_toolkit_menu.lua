local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local HostToolkitMenu = setmetatable({}, { __index = Submenu })
HostToolkitMenu.__index = HostToolkitMenu

local instance = nil

function HostToolkitMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Host Toolkit"), HostToolkitMenu)
        instance:Init()
    end
    return instance
end

function HostToolkitMenu:Init()
    -- 1. Block All Joins (Toggle)
    local blockJoinsFeat = FeatureMgr.GetFeatureByName("Block All Joins")
    if blockJoinsFeat then
        self:AddOption(ToggleOption.new("Block All Joins")
            :AddFunction(function() blockJoinsFeat:Toggle() end)
            :AddOnUpdate(function(opt) opt:SetValue(blockJoinsFeat:GetBoolValue()) end)
            :AddTooltip("Prevents anyone from joining the session"))
    else
        self:AddOption(ToggleOption.new("Block All Joins [Unavailable]")
             :AddTooltip("Feature not found"))
    end

    -- 2. Max Players (Slider 1-32)
    -- Using NumberOption
    local maxPlayersFeat = FeatureMgr.GetFeatureByName("Max Players")
    if maxPlayersFeat then
        local maxPlayersOpt = NumberOption.new(1, "Max Players")
        maxPlayersOpt:AddMin(1):AddMax(32)
        maxPlayersOpt:SetStep(1)
        -- Initialize value
        maxPlayersOpt:SetValue(maxPlayersFeat:GetIntValue())
        
        maxPlayersOpt:AddFunction(function()
            maxPlayersFeat:SetIntValue(maxPlayersOpt:GetValue())
        end)
        
        -- Update slider if feature changes externally
        maxPlayersOpt:AddOnUpdate(function(opt)
            -- Only update if not being interacted with to avoid fighting? 
            -- For now, simple sync.
            -- opt:SetValue(maxPlayersFeat:GetIntValue()) -- frequent updates might interfere with sliding logic in NumberOption
        end)
        
        self:AddOption(maxPlayersOpt)
    else
        self:AddOption(NumberOption.new(1, "Max Players [Unavailable]"))
    end

    -- 3. Block Matchmaking Joins (Toggle)
    local blockMatchmakingFeat = FeatureMgr.GetFeatureByName("Block Matchmaking Joins")
    if blockMatchmakingFeat then
        self:AddOption(ToggleOption.new("Block Matchmaking Joins")
            :AddFunction(function() blockMatchmakingFeat:Toggle() end)
            :AddOnUpdate(function(opt) opt:SetValue(blockMatchmakingFeat:GetBoolValue()) end)
            :AddTooltip("Prevents random players from joining via matchmaking"))
    else
         self:AddOption(ToggleOption.new("Block Matchmaking Joins [Unavailable]"))
    end

    -- 4. Advertise Session (Toggle)
    local advertiseSessionFeat = FeatureMgr.GetFeatureByName("Advertise Session")
    if advertiseSessionFeat then
        self:AddOption(ToggleOption.new("Advertise Session")
            :AddFunction(function() advertiseSessionFeat:Toggle() end)
            :AddOnUpdate(function(opt) opt:SetValue(advertiseSessionFeat:GetBoolValue()) end)
            :AddTooltip("Makes your session visible to others"))
    else
         self:AddOption(ToggleOption.new("Advertise Session [Unavailable]"))
    end

    -- 5. Advertise Count (Slider 1-10)
    local advertiseCountFeat = FeatureMgr.GetFeatureByName("Advertise Count")
    if advertiseCountFeat then
        local advertiseCountOpt = NumberOption.new(1, "Advertise Count")
        advertiseCountOpt:AddMin(1):AddMax(10)
        advertiseCountOpt:SetStep(1)
        advertiseCountOpt:SetValue(advertiseCountFeat:GetIntValue())
        
        advertiseCountOpt:AddFunction(function()
            advertiseCountFeat:SetIntValue(advertiseCountOpt:GetValue())
        end)
        
        -- Sync
        advertiseCountOpt:AddOnUpdate(function(opt)
            -- opt:SetValue(advertiseCountFeat:GetIntValue()) 
        end)
        
        self:AddOption(advertiseCountOpt)
    else
        self:AddOption(NumberOption.new(1, "Advertise Count [Unavailable]"))
    end
end

return HostToolkitMenu
