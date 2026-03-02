--[[
    Impulse Lua - KD Menu
    KD editor options
    Port of KDMenu.h/cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")

local KDMenu = setmetatable({}, { __index = Submenu })
KDMenu.__index = KDMenu

local instance = nil

-- Variables
local vars = {
    kills = 0,
    deaths = 0,
    okills = 0,
    odeaths = 0,
    shots = 0,
    headshots = 0,
    hits = 0
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

function KDMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("KD editor"), KDMenu)
        instance:Init()
    end
    return instance
end

function KDMenu:Init()
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Set kills")
        :AddNumberRef(vars, "kills", "%d", 10)
        :AddMin(0):AddMax(2147483647)
        :AddOnUpdate(function()
            local hash = GetStatHash("KILLS_PLAYERS")
            local success, val = Stats.GetInt(hash)
            if success then vars.kills = val end
        end)
        :AddFunction(function()
            local hash = GetStatHash("KILLS_PLAYERS")
            Stats.SetInt(hash, vars.kills)
        end)
        :AddTooltip("Set kills"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Set deaths")
        :AddNumberRef(vars, "deaths", "%d", 10)
        :AddMin(0):AddMax(2147483647)
        :AddOnUpdate(function()
            local hash = GetStatHash("DEATHS_PLAYER")
            local success, val = Stats.GetInt(hash)
            if success then vars.deaths = val end
        end)
        :AddFunction(function()
            local hash = GetStatHash("DEATHS_PLAYER")
            Stats.SetInt(hash, vars.deaths)
        end)
        :AddTooltip("Set deaths"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Set online kills")
        :AddNumberRef(vars, "okills", "%d", 10)
        :AddMin(0):AddMax(2147483647)
        :AddOnUpdate(function()
            local hash = GetStatHash("MPPLY_KILLS_PLAYERS")
            local success, val = Stats.GetInt(hash)
            if success then vars.okills = val end
        end)
        :AddFunction(function()
            local hash = GetStatHash("MPPLY_KILLS_PLAYERS")
            Stats.SetInt(hash, vars.okills)
        end)
        :AddTooltip("Set online kills"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Set online deaths")
        :AddNumberRef(vars, "odeaths", "%d", 10)
        :AddMin(0):AddMax(2147483647)
        :AddOnUpdate(function()
            local hash = GetStatHash("MPPLY_DEATHS_PLAYER")
            local success, val = Stats.GetInt(hash)
            if success then vars.odeaths = val end
        end)
        :AddFunction(function()
            local hash = GetStatHash("MPPLY_DEATHS_PLAYER")
            Stats.SetInt(hash, vars.odeaths)
        end)
        :AddTooltip("Set online deaths"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Set shots")
        :AddNumberRef(vars, "shots", "%d", 10)
        :AddMin(0):AddMax(2147483647)
        :AddOnUpdate(function()
            local hash = GetStatHash("SHOTS")
            local success, val = Stats.GetInt(hash)
            if success then vars.shots = val end
        end)
        :AddFunction(function()
            local hash = GetStatHash("SHOTS")
            Stats.SetInt(hash, vars.shots)
        end)
        :AddTooltip("Set shots"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Set headshots")
        :AddNumberRef(vars, "headshots", "%d", 10)
        :AddMin(0):AddMax(2147483647)
        :AddOnUpdate(function()
            local hash = GetStatHash("HEADSHOTS")
            local success, val = Stats.GetInt(hash)
            if success then vars.headshots = val end
        end)
        :AddFunction(function()
            local hash = GetStatHash("HEADSHOTS")
            Stats.SetInt(hash, vars.headshots)
        end)
        :AddTooltip("Set headshots"))

    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Set hits")
        :AddNumberRef(vars, "hits", "%d", 10)
        :AddMin(0):AddMax(2147483647)
        :AddOnUpdate(function()
            local hash = GetStatHash("HITS")
            local success, val = Stats.GetInt(hash)
            if success then vars.hits = val end
        end)
        :AddFunction(function()
            local hash = GetStatHash("HITS")
            Stats.SetInt(hash, vars.hits)
        end)
        :AddTooltip("Set hits"))
end

return KDMenu
