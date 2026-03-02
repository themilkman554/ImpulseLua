--[[
    Impulse Lua - Stats Menu
    Stat editor options
    Port of statsMenu.h/cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local StatsMenu = setmetatable({}, { __index = Submenu })
StatsMenu.__index = StatsMenu

local instance = nil

-- Variables
local vars = {
    stamina = 0,
    strength = 0,
    lungcapacity = 0,
    driving = 0,
    flying = 0,
    shooting = 0,
    stealth = 0,
    
    days = 0,
    hours = 0,
    minutes = 0,
    seconds = 0,
    
    racewins = 0,
    raceloses = 0,
    tdwins = 0,
    tdloses = 0,
    dmwins = 0,
    dmloses = 0
}

-- Helpers
local function GetStatHash(stat)
    -- Check if stat is already a specific MP stat
    if string.find(stat, "MPPLY") then
        return Utils.Joaat(stat)
    end
    
    -- Determine current character (MP0 or MP1)
    local charHash = Utils.Joaat("MPPLY_LAST_MP_CHAR")
    local success, char = Stats.GetInt(charHash)
    local prefix = (success and char == 1) and "MP1_" or "MP0_"
    
    return Utils.Joaat(prefix .. stat)
end

function StatsMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Stat editor"), StatsMenu)
        instance:Init()
    end
    return instance
end

function StatsMenu:Init()
    -- Helpers for Max buttons
    local function SetStat(name, val)
        Stats.SetInt(GetStatHash(name), val)
    end

    self:AddOption(ButtonOption.new("Max all stats")
        :AddFunction(function()
            SetStat("SCRIPT_INCREASE_STAM", 100)
            SetStat("SCRIPT_INCREASE_STRN", 100)
            SetStat("SCRIPT_INCREASE_LUNG", 100)
            SetStat("SCRIPT_INCREASE_DRIV", 100)
            SetStat("SCRIPT_INCREASE_FLY", 100)
            SetStat("SCRIPT_INCREASE_SHO", 100)
            SetStat("SCRIPT_INCREASE_STL", 100)
        end)
        :AddTooltip("Max all stats (if only maxing one then do this in an invite only)"))

    self:AddOption(ButtonOption.new("Max stamina")
        :AddFunction(function() SetStat("SCRIPT_INCREASE_STAM", 100) end)
        :AddTooltip("Max stamina"))

    self:AddOption(ButtonOption.new("Max strength")
        :AddFunction(function() SetStat("SCRIPT_INCREASE_STRN", 100) end)
        :AddTooltip("Max strength"))

    self:AddOption(ButtonOption.new("Max lung capacity")
        :AddFunction(function() SetStat("SCRIPT_INCREASE_LUNG", 100) end)
        :AddTooltip("Max lung capacity"))

    self:AddOption(ButtonOption.new("Max driving")
        :AddFunction(function() SetStat("SCRIPT_INCREASE_DRIV", 100) end)
        :AddTooltip("Max driving"))

    self:AddOption(ButtonOption.new("Max flying")
        :AddFunction(function() SetStat("SCRIPT_INCREASE_FLY", 100) end)
        :AddTooltip("Max flying"))

    self:AddOption(ButtonOption.new("Max shooting")
        :AddFunction(function() SetStat("SCRIPT_INCREASE_SHO", 100) end)
        :AddTooltip("Max shooting"))

    self:AddOption(ButtonOption.new("Max stealth")
        :AddFunction(function() SetStat("SCRIPT_INCREASE_STL", 100) end)
        :AddTooltip("Max stealth"))

    self:AddOption(BreakOption.new("Stats"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "~c~Stamina")
        :AddNumberRef(vars, "stamina", "%d", 1):AddMin(0):AddMax(100)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("STAMINA"))
            if s then vars.stamina = v end
        end)
        :AddFunction(function() SetStat("SCRIPT_INCREASE_STAM", vars.stamina - 30) end)
        :AddTooltip("Stamina"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "~c~Strength")
        :AddNumberRef(vars, "strength", "%d", 1):AddMin(0):AddMax(100)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("STRENGTH"))
            if s then vars.strength = v end
        end)
        :AddFunction(function() SetStat("SCRIPT_INCREASE_STRN", vars.strength - 30) end)
        :AddTooltip("Strength"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "~c~Lung capacity")
        :AddNumberRef(vars, "lungcapacity", "%d", 1):AddMin(0):AddMax(100)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("LUNG_CAPACITY"))
            if s then vars.lungcapacity = v end
        end)
        :AddFunction(function() SetStat("SCRIPT_INCREASE_LUNG", vars.lungcapacity - 30) end)
        :AddTooltip("Lung capacity"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "~c~Driving")
        :AddNumberRef(vars, "driving", "%d", 1):AddMin(0):AddMax(100)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("WHEELIE_ABILITY"))
            if s then vars.driving = v end
        end)
        :AddFunction(function() SetStat("SCRIPT_INCREASE_DRIV", vars.driving - 30) end)
        :AddTooltip("Driving"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "~c~Flying")
        :AddNumberRef(vars, "flying", "%d", 1):AddMin(0):AddMax(100)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("FLYING_ABILITY"))
            if s then vars.flying = v end
        end)
        :AddFunction(function() SetStat("SCRIPT_INCREASE_FLY", vars.flying - 30) end)
        :AddTooltip("Flying"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "~c~Shooting")
        :AddNumberRef(vars, "shooting", "%d", 1):AddMin(0):AddMax(100)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("SHOOTING_ABILITY"))
            if s then vars.shooting = v end
        end)
        :AddFunction(function() SetStat("SCRIPT_INCREASE_SHO", vars.shooting - 30) end)
        :AddTooltip("Shooting"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "~c~Stealth")
        :AddNumberRef(vars, "stealth", "%d", 1):AddMin(0):AddMax(100)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("STEALTH_ABILITY"))
            if s then vars.stealth = v end
        end)
        :AddFunction(function() SetStat("SCRIPT_INCREASE_STL", vars.stealth - 30) end)
        :AddTooltip("Stealth"))

    self:AddOption(BreakOption.new("Playtime"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Days")
        :AddNumberRef(vars, "days", "%d", 1):AddMin(0):AddMax(2147483647)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("TOTAL_PLAYING_TIME"))
            if s then vars.days = math.floor(v / 86400 / 1000) end
        end)
        :AddFunction(function() SetStat("TOTAL_PLAYING_TIME", vars.days * 86400000) end)
        :AddTooltip("Days"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Hours")
        :AddNumberRef(vars, "hours", "%d", 1):AddMin(0):AddMax(24)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("TOTAL_PLAYING_TIME"))
            if s then vars.hours = math.floor(v / 3600 / 1000) end
        end)
        :AddFunction(function() SetStat("TOTAL_PLAYING_TIME", vars.hours * 3600000) end)
        :AddTooltip("Hours"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Minutes")
        :AddNumberRef(vars, "minutes", "%d", 1):AddMin(0):AddMax(60)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("TOTAL_PLAYING_TIME"))
            if s then vars.minutes = math.floor(v / 60 / 1000) end
        end)
        :AddFunction(function() SetStat("TOTAL_PLAYING_TIME", vars.minutes * 60000) end)
        :AddTooltip("Minutes"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Seconds")
        :AddNumberRef(vars, "seconds", "%d", 1):AddMin(0):AddMax(60)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("TOTAL_PLAYING_TIME"))
            if s then vars.seconds = math.floor(v / 1000) end
        end)
        :AddFunction(function() SetStat("TOTAL_PLAYING_TIME", vars.seconds * 1000) end)
        :AddTooltip("Seconds"))

    self:AddOption(BreakOption.new("Misc stats"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Race wins")
        :AddNumberRef(vars, "racewins", "%d", 1):AddMin(0):AddMax(100000000)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("MPPLY_TOTAL_RACES_WINS"))
            if s then vars.racewins = v end
        end)
        :AddFunction(function() SetStat("MPPLY_TOTAL_RACES_WINS", vars.racewins) end)
        :AddTooltip("Race wins"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Race losses")
        :AddNumberRef(vars, "raceloses", "%d", 1):AddMin(0):AddMax(100000000)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("MPPLY_TOTAL_RACES_LOST"))
            if s then vars.raceloses = v end
        end)
        :AddFunction(function() SetStat("MPPLY_TOTAL_RACES_LOST", vars.raceloses) end)
        :AddTooltip("Race losses"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Team deathmatch wins")
        :AddNumberRef(vars, "tdwins", "%d", 1):AddMin(0):AddMax(100000000)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("MPPLY_TOTAL_TDEATHMATCH_WON"))
            if s then vars.tdwins = v end
        end)
        :AddFunction(function() SetStat("MPPLY_TOTAL_TDEATHMATCH_WON", vars.tdwins) end)
        :AddTooltip("Team deathmatch wins"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Team deathmatch losses")
        :AddNumberRef(vars, "tdloses", "%d", 1):AddMin(0):AddMax(100000000)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("MPPLY_TOTAL_TDEATHMATCH_LOST"))
            if s then vars.tdloses = v end
        end)
        :AddFunction(function() SetStat("MPPLY_TOTAL_TDEATHMATCH_LOST", vars.tdloses) end)
        :AddTooltip("Team deathmatch losses"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Deathmatch wins")
        :AddNumberRef(vars, "dmwins", "%d", 1):AddMin(0):AddMax(100000000)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("MPPLY_TOTAL_DEATHMATCH_WON"))
            if s then vars.dmwins = v end
        end)
        :AddFunction(function() SetStat("MPPLY_TOTAL_DEATHMATCH_WON", vars.dmwins) end)
        :AddTooltip("Deathmatch wins"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Deathmatch losses")
        :AddNumberRef(vars, "dmloses", "%d", 1):AddMin(0):AddMax(100000000)
        :AddOnUpdate(function()
            local s, v = Stats.GetInt(GetStatHash("MPPLY_TOTAL_DEATHMATCH_LOST"))
            if s then vars.dmloses = v end
        end)
        :AddFunction(function() SetStat("MPPLY_TOTAL_DEATHMATCH_LOST", vars.dmloses) end)
        :AddTooltip("Deathmatch losses"))
end

return StatsMenu
