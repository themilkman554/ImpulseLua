--[[
    Impulse Lua - Bodyguard Creator Menu
    Port of bodyguardMenu.cpp from Impulse C++
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local SubmenuOption = require("Impulse/ImpulseLua/lib/options/submenu_option")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local TextInputComponent = require("Impulse/ImpulseLua/lib/ui/text_input_component")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local BodyguardMenu = setmetatable({}, { __index = Submenu })
BodyguardMenu.__index = BodyguardMenu

local instance = nil
local customBodyguardInput = nil

-- Shared state for spawned bodyguards (accessed by editor menus)
local SpawnedBodyguards = {}

-- Menu state
local vars = {
    pedchoice = 1,
    weaponchoice = 1,
    healthchoice = 1,
    formationchoice = 1,
    clonepick = false,
    godmodepick = false,
    invisiblePick = false,
    ragdollpick = false,
    addblip = false,
    lastBodyguard = 0,
    lastBlip = 0,
    customBodyguardModel = "mp_m_freemode_01"
}

-- Weapon options
local WeaponSelector = {
    { name = "Railgun", value = 0x6D544C99 },
    { name = "RPG", value = 0xB1CA77B1 },
    { name = "Stungun", value = 0x3656C8C1 },
    { name = "Minigun", value = 0x42BF8A85 },
    { name = "Grenade Launcher", value = 0xA284510B },
    { name = "Heavy Sniper", value = 0x0C472FE2 },
    { name = "Marksman Rifle", value = 0xC734385A },
    { name = "Assault Shotgun", value = 0xE284C527 },
    { name = "Combat MG", value = 0x7FD62962 },
    { name = "Baseball Bat", value = 0x958A4A8F },
    { name = "Machete", value = 0xDD5DF8D9 },
    { name = "Firework Launcher", value = 0x7F7497E5 }
}

-- Health options
local HealthSelector = {
    { name = "Regular Health", value = 100 },
    { name = "Double Health", value = 200 },
    { name = "Extended Health", value = 1000 },
    { name = "Godly Health", value = 9999 }
}

-- Formation options
local FormationSelector = {
    { name = "Default", value = 0 },
    { name = "Circle (Inward)", value = 1 },
    { name = "Circle (North)", value = 2 },
    { name = "Line", value = 3 }
}

-- Ped options
local PedSelector = {
    { name = "Generic", value = 0xB3F3EE34 },
    { name = "Custom", value = "CUSTOM" },
    { name = "Random", value = "RANDOM" },
    { name = "Jesus", value = 0xCE2CB751 },
    { name = "Juggernaut", value = 0x90EF5134 },
    { name = "Johnny", value = 0x87CA80AE },
    { name = "Avon", value = 0xFCDA04A8 },
    { name = "Bodybuilder", value = 0xDA116E7E },
    { name = "Beach Girl", value = 0x303638A7 },
    { name = "Afro Male", value = 0x37A8C4E6 },
    { name = "Clown", value = 0x449D2D2 },
    { name = "Cocaine Male", value = 0x56C96F55 },
    { name = "Cocaine Female", value = 0x4B657AF8 },
    { name = "Police Man", value = 0x5E3DA4A4 },
    { name = "Police Female", value = 0x15F8700D },
    { name = "Hip Hop Man", value = 0x9CDBA508 },
    { name = "Fireman", value = 0xB6B1EDA8 },
    { name = "Hooker", value = 0x028ABF95 },
    { name = "Juggernaut 2", value = 0x90EF5134 },
    { name = "Lester", value = 0x6E42FD26 },
    { name = "Meth Male", value = 0xEDABCEFF },
    { name = "Meth Female", value = 0xD2E5A01D },
    { name = "Mime", value = 0x3CDCA742 },
    { name = "Spaceman", value = 0xE7B31432 },
    { name = "Pogo", value = 0xDC59940D },
    { name = "RS Ranger", value = 0x3C438CD2 },
    { name = "Snow Cop", value = 0x1AE8BB58 },
    { name = "Stripper 1", value = 0x52580019 },
    { name = "Stripper 2", value = 0x6E0FB794 },
    { name = "Stripper 3", value = 0x5C14EDFA },
    { name = "Tramp", value = 0x48F86EB },
    { name = "Trans", value = 0xE104A6E4 },
    { name = "Alien", value = 0x64611296 }
}

-- Helper: Get local player
local function GetLocalPed()
    return PLAYER.PLAYER_PED_ID()
end

local function GetLocalPlayerId()
    return PLAYER.PLAYER_ID()
end

local function GetLocalCoords()
    return ENTITY.GET_ENTITY_COORDS(GetLocalPed(), true)
end

-- Spawn bodyguard function
local function SpawnBodyguard(weapon, pedHash, health, formation)
    local ped = GetLocalPed()
    local coords = GetLocalCoords()
    local heading = ENTITY.GET_ENTITY_HEADING(ped)
    local myGroup = PLAYER.GET_PLAYER_GROUP(GetLocalPlayerId())
    
    local bodyguard = 0
    
    if vars.clonepick then
        -- Clone the player
        bodyguard = PED.CLONE_PED(ped, heading, true, false)
    else
        if pedHash == "CUSTOM" then
            local modelName = vars.customBodyguardModel
            local hash = MISC.GET_HASH_KEY(modelName)
            if STREAMING.IS_MODEL_VALID(hash) then
                STREAMING.REQUEST_MODEL(hash)
                local timeout = 0
                while not STREAMING.HAS_MODEL_LOADED(hash) and timeout < 100 do
                    Script.Yield()
                    timeout = timeout + 1
                end
                
                if STREAMING.HAS_MODEL_LOADED(hash) then
                    bodyguard = GTA.CreatePed(hash, 21, coords.x, coords.y, coords.z, heading, true, false)
                    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(hash)
                end
            else
                Renderer.Notify("Invalid custom model: " .. tostring(modelName))
                return nil
            end
        elseif pedHash == "RANDOM" then
            -- Spawn random ped
            bodyguard = GTA.CreateRandomPed(coords.x, coords.y, coords.z)
        else
            -- Spawn selected ped
            STREAMING.REQUEST_MODEL(pedHash)
            local timeout = 0
            while not STREAMING.HAS_MODEL_LOADED(pedHash) and timeout < 100 do
                Script.Yield()
                timeout = timeout + 1
            end
            
            if STREAMING.HAS_MODEL_LOADED(pedHash) then
                bodyguard = GTA.CreatePed(pedHash, 21, coords.x, coords.y, coords.z, heading, true, false)
                STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(pedHash)
            end
        end
    end
    
    if bodyguard == 0 or not ENTITY.DOES_ENTITY_EXIST(bodyguard) then
        return nil
    end
    
    -- Add blip if requested
    local blip = 0
    if vars.addblip then
        blip = HUD.ADD_BLIP_FOR_ENTITY(bodyguard)
        HUD.SET_BLIP_SPRITE(blip, 480)
        HUD.SET_BLIP_COLOUR(blip, 63)
    end
    
    -- Set up group membership
    PED.SET_PED_AS_GROUP_LEADER(ped, myGroup)
    PED.SET_PED_AS_GROUP_MEMBER(bodyguard, myGroup)
    PED.SET_PED_NEVER_LEAVES_GROUP(bodyguard, true)
    
    -- Apply godmode if requested
    if vars.godmodepick then
        ENTITY.SET_ENTITY_INVINCIBLE(bodyguard, true)
    end
    
    -- Combat settings
    PED.SET_PED_COMBAT_ABILITY(bodyguard, 100)
    PED.SET_PED_CAN_SWITCH_WEAPON(bodyguard, true)
    PED.SET_GROUP_FORMATION(myGroup, formation)
    
    -- Health
    PED.SET_PED_MAX_HEALTH(bodyguard, health)
    ENTITY.SET_ENTITY_HEALTH(bodyguard, health, 0)
    
    -- Visibility
    if vars.invisiblePick then
        ENTITY.SET_ENTITY_VISIBLE(bodyguard, false, false)
    else
        ENTITY.SET_ENTITY_VISIBLE(bodyguard, true, true)
    end
    
    -- Give weapon
    WEAPON.GIVE_WEAPON_TO_PED(bodyguard, weapon, 9999, false, true)
    
    -- Combat hated targets
    TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(bodyguard, 100.0, 0)
    
    -- No ragdoll if requested
    if vars.ragdollpick then
        PED.SET_PED_CAN_RAGDOLL(bodyguard, false)
        PED.SET_PED_CAN_RAGDOLL_FROM_PLAYER_IMPACT(bodyguard, false)
        PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(bodyguard, false)
        PED.SET_PED_RAGDOLL_ON_COLLISION(bodyguard, false)
    end
    
    vars.lastBodyguard = bodyguard
    vars.lastBlip = blip
    
    return {
        Model = PedSelector[vars.pedchoice].name,
        Handle = bodyguard,
        BlipBool = vars.addblip,
        Ragdoll = vars.ragdollpick,
        Godmode = vars.godmodepick,
        Marker = blip,
        Invisible = vars.invisiblePick
    }
end

function BodyguardMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Bodyguards Creator"), BodyguardMenu)
        instance:Init()
    end
    return instance
end

-- Static accessor for spawned bodyguards (used by editor menus)
function BodyguardMenu.GetSpawnedBodyguards()
    return SpawnedBodyguards
end

function BodyguardMenu.SetSpawnedBodyguards(list)
    SpawnedBodyguards = list
end

function BodyguardMenu:Init()
    local BodyguardEditorMenu = require("Impulse/ImpulseLua/submenus/world/bodyguard_editor_menu")
    
    -- Edit spawned bodyguards
    self:AddOption(SubmenuOption.new("Edit spawned bodyguards")
        :AddSubmenu(BodyguardEditorMenu.GetInstance())
        :AddTooltip("Edit the spawned bodyguards"))
        :SetDonor()
    -- Ped selection (only visible if not cloning)
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLLSELECT, "Ped")
        :AddScroll(PedSelector, 1)
        :AddIndexRef(vars, "pedchoice")
        :AddTooltip("Select which ped you would like to use as your bodyguard"))
        :SetDonor()
    self:AddOption(ButtonOption.new("Custom Bodyguard")
        :AddFunction(function()
            if not customBodyguardInput then
                customBodyguardInput = TextInputComponent.new("Enter Model Name", function(text)
                    if text and #text > 0 then
                        vars.customBodyguardModel = text
                        Renderer.Notify("Custom bodyguard model set to: " .. text)
                    end
                end)
            end
            customBodyguardInput:Show()
        end)
        :AddTooltip("Set the custom model for the 'Custom' ped option"))
        :SetDonor()
    -- Weapon selection
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLLSELECT, "Weapon")
        :AddScroll(WeaponSelector, 1)
        :AddIndexRef(vars, "weaponchoice")
        :AddTooltip("Select which weapon your bodyguard will use"))
        :SetDonor()
    -- Health selection
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLLSELECT, "Health")
        :AddScroll(HealthSelector, 1)
        :AddIndexRef(vars, "healthchoice")
        :AddTooltip("Select the health of your bodyguard"))
        :SetDonor()
    
    -- Formation selection
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Formation")
        :AddScroll(FormationSelector, 1)
        :AddIndexRef(vars, "formationchoice")
        :AddFunction(function()
            local myGroup = PLAYER.GET_PLAYER_GROUP(GetLocalPlayerId())
            PED.SET_GROUP_FORMATION(myGroup, FormationSelector[vars.formationchoice].value)
        end)
        :AddTooltip("Select the formation at which your bodyguards assemble"))
        :SetDonor()

    -- Clone toggle
    self:AddOption(ToggleOption.new("Clone")
        :AddToggleRef(vars, "clonepick")
        :AddTooltip("If you would like the bodyguard to be a clone of yourself instead of a different ped")
        :AddHotkey())
        :SetDonor()
    -- Godmode toggle
    self:AddOption(ToggleOption.new("Godmode")
        :AddToggleRef(vars, "godmodepick")
        :AddTooltip("If you would like your bodyguard to have godmode")
        :AddHotkey())
        :SetDonor()
    
    -- Invisibility toggle
    self:AddOption(ToggleOption.new("Invisibility")
        :AddToggleRef(vars, "invisiblePick")
        :AddTooltip("If you would like your bodyguard to be invisible")
        :AddHotkey())
        :SetDonor()
    -- No ragdoll toggle
    self:AddOption(ToggleOption.new("No ragdoll")
        :AddToggleRef(vars, "ragdollpick")
        :AddTooltip("If you would like your bodyguard to not ragdoll when shot or ran over")
        :AddHotkey())
        :SetDonor()
    
    -- Add blip toggle
    self:AddOption(ToggleOption.new("Add blip")
        :AddToggleRef(vars, "addblip")
        :AddTooltip("If you want your bodyguard to have a blip on the mini map")
        :AddHotkey())
        
    -- Spawn button
    self:AddOption(ButtonOption.new("Spawn it!")
        :AddFunction(function()
            local weapon = WeaponSelector[vars.weaponchoice].value
            local pedHash = PedSelector[vars.pedchoice].value
            local health = HealthSelector[vars.healthchoice].value
            local formation = FormationSelector[vars.formationchoice].value
            
            local bodyguardData = SpawnBodyguard(weapon, pedHash, health, formation)
            if bodyguardData then
                table.insert(SpawnedBodyguards, bodyguardData)
            end
        end)
        :AddTooltip("This will spawn your custom bodyguard based off the options you have specified above")
        :AddHotkey())
        :SetDonor()
end

function BodyguardMenu:FeatureUpdate()
    if customBodyguardInput and customBodyguardInput:IsVisible() then
        customBodyguardInput:Update()
    end
end

return BodyguardMenu
