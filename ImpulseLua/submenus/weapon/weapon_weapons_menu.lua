
local WeaponWeaponsMenu = {}
WeaponWeaponsMenu.__index = WeaponWeaponsMenu

-- Imports
local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

-- State
local state = {
    camo = 1, -- 1-based index for Lua tables
    camoAll = 1,
    rainbowCamo = false,
    giveallweaponsloop = false,
    rainbowTimer = 0
}

-- Data Tables
local camoStruct = {
    { name = "Default", id = 0 },
    { name = "Green", id = 1 },
    { name = "Gold", id = 2 },
    { name = "Pink", id = 3 },
    { name = "Army", id = 4 },
    { name = "LSPD", id = 5 },
    { name = "Orange", id = 6 },
    { name = "Platinum", id = 7 }
}

-- Extracting names for ScrollOption
local camoNames = {}
for _, v in ipairs(camoStruct) do
    table.insert(camoNames, v.name)
end

-- Functions

local function GiveAllWeapons()
    local feature = FeatureMgr.GetFeatureByName("Give All Weapons")
    if feature then
        feature:TriggerCallback()
    else
        Renderer.Notify("Feature 'Give All Weapons' not found")
    end
end

local function ClearAllWeapons()
    local ped = PLAYER.PLAYER_PED_ID()
    WEAPON.REMOVE_ALL_PED_WEAPONS(ped, true)
end

local function UpgradeCurrentWeapon()
    local feature = FeatureMgr.GetFeatureByName("Give All Weapon Components")
    if feature then
        feature:TriggerCallback()
    else
        Renderer.Notify("Feature 'Give All Weapon Components' not found")
    end
end

local function UpgradeAllWeapons()
    local feature = FeatureMgr.GetFeatureByName("Give All Weapon Components")
    if feature then
        feature:TriggerCallback()
    else
        Renderer.Notify("Feature 'Give All Weapon Components' not found")
    end
end

-- Usable weapon hashes for giving weapons
local usableWeaponHashes = {
    126349499, 2694266206, 1233104067, 101631238, 911657153, 1834241177,
    0x1B06D571, 0x5EF9FEC4, 0x22D8FE39, 0x99AEEB3B, 0x2BE6766B, 0x13532244,
    0xBFEFFF6D, 0x83BF0278, 0xAF113F99, 0x9D07F764, 0x7FD62962, 0x1D073A89,
    0x7846A318, 0xE284C527, 0xC472FE2, 0x5FC3C11, 0xA284510B, 0xB1CA77B1,
    0x42BF8A85, 0x93E220BD, 0xFDBC8A50, 0x2C3731D9, 0x24B17070, 0x34A67B97,
    0xFBAB5776, 0x99B507EA, 0x678B81B1, 0x4E875F73, 0x958A4A8F, 0x84BD7BFD,
    0x440E4788, 0xEFE7E2DF, 0x9D61E50F, 0xF9E6AA4B, 0xC0A3098D, 0xBFD21232,
    0x476BF155, 0xAF3696A1, 0xB62D1F67, 0xD205520E, 0x7F229F94, 0x61012683,
    0x83839C4, 0x92A27487, 0xA89CB99E, 0x7F7497E5, 0x47757124, 0x3AABBBAA,
    0xC734385A, 0xAB564B93, 0x63AB0442, 0xF9DCBF2D, 0xA3D4D34, 0xD8DF3C3C,
    0xDC4DB296, 0xDD5DF8D9, 0xDB1AA450, 0xEF951FBB, 0x624FE830, 0x8BB05FD7,
    0xC1B3C3D1, 0xDFE37640, 0x78A97CD0, 0xA914799, 0x394F415C, 0x19044EE0,
    0x781FE4A, 0x12E82D3D, 0x176898A6, 0x787F0BB, 0xE232C28C, 0xD04C944D,
    0x0A3D4D34, 0x6D544C99, 0x2C082D7D, 0xCD274149, 0xBD248B55, 0xBA45E8B8,
    0x94117305
}

local function SetCamo(index, all)
    local ped = PLAYER.PLAYER_PED_ID()
    local camoID = camoStruct[index].id
    
    if all then
        for _, hash in ipairs(usableWeaponHashes) do
            if WEAPON.HAS_PED_GOT_WEAPON(ped, hash, false) then
                WEAPON.SET_PED_WEAPON_TINT_INDEX(ped, hash, camoID)
            end
        end
    else
        local hash = WEAPON.GET_SELECTED_PED_WEAPON(ped)
        if hash and hash ~= 0 then
            WEAPON.SET_PED_WEAPON_TINT_INDEX(ped, hash, camoID)
        end
    end
end

local function RainbowCamoInfo()
    local ped = PLAYER.PLAYER_PED_ID()
    local hash = WEAPON.GET_SELECTED_PED_WEAPON(ped)
    if hash and hash ~= 0 then
        local now = MISC.GET_GAME_TIMER()
        if now - state.rainbowTimer > 1000 then
            state.rainbowTimer = now
            local randomTint = MISC.GET_RANDOM_INT_IN_RANGE(0, 8)
            WEAPON.SET_PED_WEAPON_TINT_INDEX(ped, hash, randomTint)
        end
    end
end

-- Instance Definition
local _instance = nil

function WeaponWeaponsMenu.GetInstance()
    if _instance == nil then
        _instance = WeaponWeaponsMenu.new()
    end
    return _instance
end

function WeaponWeaponsMenu.new()
    local self = setmetatable(Submenu.new("Weapons"), WeaponWeaponsMenu)
    return self
end

-- Proper inheritance
setmetatable(WeaponWeaponsMenu, { __index = Submenu })

function WeaponWeaponsMenu:Init()
    self:AddOption(ButtonOption.new("Get all weapons")
        :AddFunction(GiveAllWeapons)
        :AddTooltip("Get all weapons")
        :AddHotkey())
        
    self:AddOption(ToggleOption.new("Get all weapons every session")
        :AddToggleRef(state, "giveallweaponsloop")
        :AddTooltip("This will give you all weapons on session load")
        :AddHotkey())
        
    self:AddOption(ButtonOption.new("Clear all weapons")
        :AddFunction(ClearAllWeapons)
        :AddTooltip("Clear your inventory")
        :AddHotkey())
        
    self:AddOption(BreakOption.new("Upgrades"))
    
    self:AddOption(ButtonOption.new("Upgrades (current weapon)")
        :AddFunction(UpgradeCurrentWeapon)
        :AddTooltip("Upgrade your current weapon")
        :AddHotkey())
        
    self:AddOption(ButtonOption.new("Upgrades (all weapons)")
        :AddFunction(UpgradeAllWeapons)
        :AddTooltip("Upgrade all weapons")
        :AddHotkey())
        
    self:AddOption(BreakOption.new("Color Edits"))
    
    local camoCurrent = ScrollOption.new(ScrollOption.Type.SCROLL, "Camo (current weapon)")
    camoCurrent:AddScroll(camoNames, 1)
    camoCurrent:AddFunction(function() 
        state.camo = camoCurrent:GetIndex()
        SetCamo(state.camo, false) 
    end)
    camoCurrent:AddTooltip("Set the camo of your current weapon")
    self:AddOption(camoCurrent)
    
    local camoAll = ScrollOption.new(ScrollOption.Type.SCROLL, "Camo (all weapons)")
    camoAll:AddScroll(camoNames, 1)
    camoAll:AddFunction(function() 
        state.camoAll = camoAll:GetIndex()
        SetCamo(state.camoAll, true) 
    end)
    camoAll:AddTooltip("Set all weapons camo")
    self:AddOption(camoAll)
    
    self:AddOption(ToggleOption.new("Rainbow Camo (current weapon)")
        :AddToggleRef(state, "rainbowCamo")
        :AddTooltip("Spam rainbow camo")
        :AddHotkey())
end

function WeaponWeaponsMenu:FeatureUpdate()
    if state.rainbowCamo then
        RainbowCamoInfo()
    end
end

-- Background loop for "Give all weapons every session"
Script.RegisterLooped(function()
    if state.giveallweaponsloop then
        GiveAllWeapons()
        Script.Yield(5000)
    else
        Script.Yield(1000)
    end
end)

return WeaponWeaponsMenu
