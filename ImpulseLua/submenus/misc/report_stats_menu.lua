--[[
    Impulse Lua - Report Stats Menu
    Port of miscReportStats.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")

local ReportStatsMenu = setmetatable({}, { __index = Submenu })
ReportStatsMenu.__index = ReportStatsMenu

local instance = nil

function ReportStatsMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Report stats"), ReportStatsMenu)
        instance:Init()
    end
    return instance
end

-- Stat variables cache
local stats = {
    Griefing = 0,
    Exploits = 0,
    VCAnnoying = 0,
    VCHate = 0,
    OffensiveLang = 0,
    OffensiveTagPlate = 0,
    GameExploit = 0,
    IsHelpful = 0,
    IsFriendly = 0,
    CommendStrength = 0,
    ReportStrength = 0,
    IsHighEarner = 0,
    OffensiveInGameChat = 0,
    IsPunished = 0
}

function ReportStatsMenu:Init()
    self.options = {} 

    local success, err = pcall(function()
        -- Debug Checks
        if not Utils then error("Utils is nil") end
        if not Utils.Joaat then error("Utils.Joaat is nil") end
        if not Memory then error("Memory is nil") end
        if not STATS then error("STATS is nil") end

        self:RefreshStats()
    end)

    if not success then
        self:AddOption(ButtonOption.new("Error: " .. tostring(err))
            :AddTooltip("An error occurred initializing the menu"))
        self:AddOption(ButtonOption.new("Retry Init")
            :AddFunction(function() self:Init() end))
    end
end

function ReportStatsMenu:RefreshStats()
    -- Read stats using Memory.AllocInt and STATS.STAT_GET_INT
    local function GetStat(name)
        local hash = Utils.Joaat(name)
        local ptr = Memory.AllocInt()
        if ptr ~= 0 then
            STATS.STAT_GET_INT(hash, ptr, -1)
            local val = Memory.ReadInt(ptr)
            Memory.Free(ptr)
            return val
        end
        return 0
    end

    -- Update cache
    stats.Griefing = GetStat("MPPLY_GRIEFING")
    stats.Exploits = GetStat("MPPLY_EXPLOITS")
    stats.VCAnnoying = GetStat("MPPLY_VC_ANNOYINGME")
    stats.VCHate = GetStat("MPPLY_VC_HATE")
    stats.OffensiveLang = GetStat("MPPLY_OFFENSIVE_LANGUAGE")
    stats.OffensiveTagPlate = GetStat("MPPLY_OFFENSIVE_TAGPLATE")
    stats.GameExploit = GetStat("MPPLY_GAME_EXPLOITS")
    stats.IsHelpful = GetStat("MPPLY_HELPFUL")
    stats.IsFriendly = GetStat("MPPLY_FRIENDLY")
    stats.CommendStrength = GetStat("MPPLY_COMMEND_STRENGTH")
    stats.ReportStrength = GetStat("MPPLY_REPORT_STRENGTH")
    stats.IsHighEarner = GetStat("MPPLY_IS_HIGH_EARNER")
    stats.OffensiveInGameChat = GetStat("MPPLY_OFFENSIVE_UGC")
    -- IsPunished is not standard stat in snippet, assuming similar logic or calculated. 
    -- C++ code implies "Punished: %i", vars.IsPunished. 
    -- But didn't show where IsPunished comes from in UpdateOnce, C++ snippet missed it or it's logic.
    -- We'll assume it's possibly "MPPLY_IS_PUNISHED" or just omit/0 if unknown. 
    -- Actually, if we look back at C++ snippet, IsPunished was used but not set in UpdateOnce shown (lines 22-34).
    -- It might be set elsewhere or default. I'll stick to 0 or try a guess if user wants.
    -- For now, 0.
    
    self.options = {} -- Reset options
    
    local function AddStat(label, value)
        self:AddOption(ButtonOption.new(string.format(label, value)):AddTooltip("Show this stat"))
    end
    
    AddStat("Report strength: %i", stats.ReportStrength)
    AddStat("Commend strength: %i", stats.CommendStrength)
    AddStat("Friendly commends: %i", stats.IsFriendly)
    AddStat("Helpful commends: %i", stats.IsHelpful)
    AddStat("Griefing reports: %i", stats.Griefing)
    AddStat("Exploit reports: %i", stats.Exploits)
    AddStat("Game exploit reports: %i", stats.GameExploit)
    AddStat("VC hate reports: %i", stats.VCHate)
    AddStat("VC annoying me reports: %i", stats.VCAnnoying)
    AddStat("Offensive UGC: %i", stats.OffensiveInGameChat)
    AddStat("Offensive language reports: %i", stats.OffensiveLang)
    AddStat("Offensive plate reports: %i", stats.OffensiveTagPlate)
    AddStat("Punished: %i", stats.IsPunished)
    AddStat("High earner: %i", stats.IsHighEarner)
end

function ReportStatsMenu:Update()
    -- Periodically refresh or just on re-entry?
    -- Since Init is called once, we might need a way to refresh when opening.
    -- But standard Submenu doesn't have OnOpen.
    -- However, we can just let it be static for now or add a "Refresh" button if needed.
    -- Or, user can just back out and re-enter if we implementing dynamic init in GetInstance properly (which we partially did).
    -- Actually, GetInstance checks if instance exists. So it persists.
    -- We should add a Refresh option or auto-refresh if possible.
    -- I'll leave it as static snapshot for now as per C++ "UpdateOnce".
end

return ReportStatsMenu
