local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local JSON = require("Impulse/ImpulseLua/lib/json")

local PlayerHistoryMenu = setmetatable({}, { __index = Submenu })
PlayerHistoryMenu.__index = PlayerHistoryMenu

local instance = nil

-- Configuration and State
local config = {
    maxItems = 60,
    sortOrder = 1 -- 1: Newest to Oldest, 2: Oldest to Newest
}

local sortOptions = {
    "Newest to oldest",
    "Oldest to newest"
}

local playerList = {}

-- Helper function to read file
local function ReadFile(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content
end

function PlayerHistoryMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Player History"), PlayerHistoryMenu)
        instance:Init()
    end
    return instance
end

function PlayerHistoryMenu:LoadHistory()
    local path = FileMgr.GetMenuRootPath() .. "\\PlayerTracker\\RecentPlayers.json"
    
    local fileContent = ReadFile(path)
    if not fileContent or fileContent == "" then
        -- Only notify if file is missing/empty, but maybe suppress to avoid spam if just empty
        -- Renderer.Notify("History file empty or missing.") 
        return
    end

    local success, data = pcall(JSON.decode, fileContent)
    if not success then
        Renderer.Notify("Failed to parse history JSON.")
        return
    end

    if not data or type(data) ~= "table" then
        return
    end

    playerList = {}
    for rid, info in pairs(data) do
        table.insert(playerList, {
            rid = rid,
            name = info.name or "Unknown",
            ip = info.ip or "Unknown",
            last_seen = info.last_seen or 0
        })
    end

    self:SortHistory()
end

function PlayerHistoryMenu:SortHistory()
    if config.sortOrder == 1 then
        table.sort(playerList, function(a, b) return a.last_seen > b.last_seen end)
    else
        table.sort(playerList, function(a, b) return a.last_seen < b.last_seen end)
    end
end

function PlayerHistoryMenu:Init()
    self:LoadHistory()

    -- Store Count Slider
    -- NumberOption.new(optionType, name)
    local storeCountOpt = NumberOption.new(1, "Store count")
    storeCountOpt:AddMin(5)
    storeCountOpt:AddMax(200)
    storeCountOpt:AddNumber(config.maxItems, "%d", 5)
    storeCountOpt:AddFunction(function()
        config.maxItems = storeCountOpt:GetValue()
        self:RefreshOptions()
    end)
    self:AddOption(storeCountOpt)

    -- Sort List
    -- ScrollOption.new(optionType, name)
    local sortOpt = ScrollOption.new(1, "Sort list")
    sortOpt:AddScroll(sortOptions, config.sortOrder)
    sortOpt:AddFunction(function()
        config.sortOrder = sortOpt:GetIndex()
        self:SortHistory()
        self:RefreshOptions()
    end)
    self:AddOption(sortOpt)

    self:AddOption(BreakOption.new("Players"))

    self:RefreshOptions()
end

function PlayerHistoryMenu:RefreshOptions()
    -- Clear dynamic options (everything after the first 3 fixed options)
    -- Options: 1=StoreCount, 2=SortList, 3=Break
    self:ClearOptionsFrom(4)

    local count = 0
    for _, player in ipairs(playerList) do
        if count >= config.maxItems then break end
        
        -- Format: Name - [RID / IP]
        -- IP in orange (~o~)
        local text = string.format("%s - ~o~[%s / %s]~s~", player.name, player.rid, player.ip)
        
        self:AddOption(ButtonOption.new(text)
            :AddFunction(function()
                Renderer.Notify("Copied RID: " .. tostring(player.rid))
                Utils.SetClipBoardText(tostring(player.rid), "")
            end)
            -- Use generic date format if os.date allows, or simple timestamp if not
            :AddTooltip("Last seen: " .. (os.date("%Y-%m-%d %H:%M:%S", player.last_seen) or tostring(player.last_seen))))
            
        count = count + 1
    end
end

-- Override OnEnter to reload history
function PlayerHistoryMenu:OnEnter()
    self:LoadHistory()
    self:SortHistory()
    self:RefreshOptions()
end

return PlayerHistoryMenu
