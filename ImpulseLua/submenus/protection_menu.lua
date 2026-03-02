--[[
    Impulse Lua - Protection Menu
    Straight port of Cherax protection features using FeatureMgr
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")
local FeatureState = require("Impulse/ImpulseLua/lib/featurestate")

local ProtectionMenu = setmetatable({}, { __index = Submenu })
ProtectionMenu.__index = ProtectionMenu

local instance = nil

-- Protection states (mirrors Cherax internal state)
local protections = {
    -- Crashes
    entitySyncCrash = false,
    netEventCrash = false,
    scriptEventCrash = false,
    
    -- Entities
    attachmentProtection = false,
    blockModelSwaps = false,
    blockWorldModelSyncs = false,
    
    -- Kicks
    freemodeKick = false,
    scriptHostKick = false,
    endSessionKick = false,
    netErrorKick = false,
    
    -- Script
    blockModdedSessionEvents = false,
    smartProtection = false,
    advancedScriptEventProtection = false,
    logBounty = false,
    ceoKick = false,
    ceoBan = false,
    
    -- Anti Detection
    hideGodMode = false,
    hideDamageModifier = false,
    hideSpectatingFlag = false,
    hideSuperJumpFlag = false,
    
    -- Anti Spam
    blockBountySpam = false,
    blockPedSpam = false,
    blockVehicleSpam = false,
    blockExplosionSpam = false,
    blockPtfxSpam = false,
    blockSoundSpam = false,
    blockStunGunSpam = false,
    blockChatAdvertisements = false,
    blockInfinitePhoneRing = false,
    blockModdedReports = false,
    
    -- Anti Trolling
    blockCages = false,
    vehicleKickProtection = false,
    blockRemoteClearTask = false,
    blockRemoteRagdoll = false,
    blockRemoteControl = false,
    blockAllControl = false,
    blockRemoveWeapon = false,
    blockGiveWeapon = false,
    
    -- Weapons
    antiAim = false,
    antiShoot = false,
    disableProjectiles = false,
    disableBullets = false,
    
    -- Other
    useRelayConnection = false,
    disableCamShake = false,
    notifySpectate = false,
    antiSpectate = false,
}



--- Sync local state with Cherax's actual state
local function SyncStates()
    -- Crashes
    protections.entitySyncCrash = FeatureState.Get("Entity Sync Crash Protection")
    protections.netEventCrash = FeatureState.Get("Net Event Crash Protection")
    protections.scriptEventCrash = FeatureState.Get("Script Event Crash Protection")
    
    -- Entities
    protections.attachmentProtection = FeatureState.Get("Attachment Protection")
    protections.blockModelSwaps = FeatureState.Get("Block Model Swaps")
    protections.blockWorldModelSyncs = FeatureState.Get("Block World Model Syncs")
    
    -- Kicks
    protections.freemodeKick = FeatureState.Get("Freemode Kick Protection")
    protections.scriptHostKick = FeatureState.Get("Script Host Kick Protection")
    protections.endSessionKick = FeatureState.Get("End Session Kick Protection")
    protections.netErrorKick = FeatureState.Get("Net Error Kick Protection")
    
    -- Script
    protections.blockModdedSessionEvents = FeatureState.Get("Block Modded Session Events")
    protections.smartProtection = FeatureState.Get("Smart Protection")
    protections.advancedScriptEventProtection = FeatureState.Get("Advanced Script Event Protection")
    protections.logBounty = FeatureState.Get("Log Bounty")
    protections.ceoKick = FeatureState.Get("CEO Kick")
    protections.ceoBan = FeatureState.Get("CEO Ban")
    
    -- Anti Detection
    protections.hideGodMode = FeatureState.Get("Hide God Mode")
    protections.hideDamageModifier = FeatureState.Get("Hide Damage Modifier")
    protections.hideSpectatingFlag = FeatureState.Get("Hide Spectating Flag")
    protections.hideSuperJumpFlag = FeatureState.Get("Hide Super Jump Flag")
    
    -- Anti Spam
    protections.blockBountySpam = FeatureState.Get("Block Bounty Spam")
    protections.blockPedSpam = FeatureState.Get("Block Ped Spam")
    protections.blockVehicleSpam = FeatureState.Get("Block Vehicle Spam")
    protections.blockExplosionSpam = FeatureState.Get("Block Explosion Spam")
    protections.blockPtfxSpam = FeatureState.Get("Block PTFX Spam")
    protections.blockSoundSpam = FeatureState.Get("Block Sound Spam")
    protections.blockStunGunSpam = FeatureState.Get("Block Stun Gun Spam")
    protections.blockChatAdvertisements = FeatureState.Get("Block Chat Advertisements")
    protections.blockInfinitePhoneRing = FeatureState.Get("Block Infinite Phone Ring")
    protections.blockModdedReports = FeatureState.Get("Block Modded Reports")
    
    -- Anti Trolling
    protections.blockCages = FeatureState.Get("Block Cages")
    protections.vehicleKickProtection = FeatureState.Get("Vehicle Kick Protection")
    protections.blockRemoteClearTask = FeatureState.Get("Block Remote Clear Task")
    protections.blockRemoteRagdoll = FeatureState.Get("Block Remote Ragdoll")
    protections.blockRemoteControl = FeatureState.Get("Block Remote Control")
    protections.blockAllControl = FeatureState.Get("Block All Control")
    protections.blockRemoveWeapon = FeatureState.Get("Block Remove Weapon")
    protections.blockGiveWeapon = FeatureState.Get("Block Give Weapon")
    
    -- Weapons
    protections.antiAim = FeatureState.Get("Anti Aim")
    protections.antiShoot = FeatureState.Get("Anti Shoot")
    protections.disableProjectiles = FeatureState.Get("Disable Projectiles")
    protections.disableBullets = FeatureState.Get("Disable Bullets")
    
    -- Other
    protections.useRelayConnection = FeatureState.Get("Use Relay Connection")
    protections.disableCamShake = FeatureState.Get("Disable Cam Shake")
    protections.notifySpectate = FeatureState.Get("Notify Spectate")
    protections.antiSpectate = FeatureState.Get("Anti Spectate")
end

function ProtectionMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Protection"), ProtectionMenu)
        -- Sync states before building menu
        SyncStates()
        instance:Init()
    end
    return instance
end

function ProtectionMenu:Init()
    self:AddOption(BreakOption.new("Crashes"))
    
    self:AddOption(ToggleOption.new("Entity Sync Crash Protection")
        :AddToggleRef(protections, "entitySyncCrash")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Entity Sync Crash Protection"):Toggle(protections.entitySyncCrash)
        end)
        :AddTooltip("Block entity sync crash attempts"))
    
    self:AddOption(ToggleOption.new("Net Event Crash Protection")
        :AddToggleRef(protections, "netEventCrash")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Net Event Crash Protection"):Toggle(protections.netEventCrash)
        end)
        :AddTooltip("Block net event crash attempts"))
    
    self:AddOption(ToggleOption.new("Script Event Crash Protection")
        :AddToggleRef(protections, "scriptEventCrash")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Script Event Crash Protection"):Toggle(protections.scriptEventCrash)
        end)
        :AddTooltip("Block script event crash attempts"))
    
    self:AddOption(BreakOption.new("Entities"))
    
    self:AddOption(ToggleOption.new("Attachment Protection")
        :AddToggleRef(protections, "attachmentProtection")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Attachment Protection"):Toggle(protections.attachmentProtection)
        end)
        :AddTooltip("Block entity attachment attempts"))
    
    self:AddOption(ToggleOption.new("Block Model Swaps")
        :AddToggleRef(protections, "blockModelSwaps")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Model Swaps"):Toggle(protections.blockModelSwaps)
        end)
        :AddTooltip("Block model swap attempts"))
    
    self:AddOption(ToggleOption.new("Block World Model Syncs")
        :AddToggleRef(protections, "blockWorldModelSyncs")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block World Model Syncs"):Toggle(protections.blockWorldModelSyncs)
        end)
        :AddTooltip("Block world model sync attempts"))
    
    self:AddOption(BreakOption.new("Kicks"))
    
    self:AddOption(ToggleOption.new("Freemode Kick Protection")
        :AddToggleRef(protections, "freemodeKick")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Freemode Kick Protection"):Toggle(protections.freemodeKick)
        end)
        :AddTooltip("Block freemode kick attempts"))
    
    self:AddOption(ToggleOption.new("Script Host Kick Protection")
        :AddToggleRef(protections, "scriptHostKick")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Script Host Kick Protection"):Toggle(protections.scriptHostKick)
        end)
        :AddTooltip("Block script host kick attempts"))
    
    self:AddOption(ToggleOption.new("End Session Kick Protection")
        :AddToggleRef(protections, "endSessionKick")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("End Session Kick Protection"):Toggle(protections.endSessionKick)
        end)
        :AddTooltip("Block end session kick attempts"))
    
    self:AddOption(ToggleOption.new("Net Error Kick Protection")
        :AddToggleRef(protections, "netErrorKick")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Net Error Kick Protection"):Toggle(protections.netErrorKick)
        end)
        :AddTooltip("Block net error kick attempts"))
    
    self:AddOption(BreakOption.new("Script"))
    
    self:AddOption(ToggleOption.new("Block Modded Session Events")
        :AddToggleRef(protections, "blockModdedSessionEvents")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Modded Session Events"):Toggle(protections.blockModdedSessionEvents)
        end)
        :AddTooltip("Block modded session events"))
    
    self:AddOption(ToggleOption.new("Smart Protection")
        :AddToggleRef(protections, "smartProtection")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Smart Protection"):Toggle(protections.smartProtection)
        end)
        :AddTooltip("Enable smart protection"))
    
    self:AddOption(ToggleOption.new("Advanced Script Event Protection")
        :AddToggleRef(protections, "advancedScriptEventProtection")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Advanced Script Event Protection"):Toggle(protections.advancedScriptEventProtection)
        end)
        :AddTooltip("Enable advanced script event protection"))
    
    self:AddOption(ToggleOption.new("Log Bounty")
        :AddToggleRef(protections, "logBounty")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Log Bounty"):Toggle(protections.logBounty)
        end)
        :AddTooltip("Log bounty events"))
    
    self:AddOption(ToggleOption.new("CEO Kick")
        :AddToggleRef(protections, "ceoKick")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("CEO Kick"):Toggle(protections.ceoKick)
        end)
        :AddTooltip("Block CEO kick attempts"))
    
    self:AddOption(ToggleOption.new("CEO Ban")
        :AddToggleRef(protections, "ceoBan")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("CEO Ban"):Toggle(protections.ceoBan)
        end)
        :AddTooltip("Block CEO ban attempts"))
    
    -- ===== ANTI DETECTION =====
    self:AddOption(BreakOption.new("Anti Detection"))
    
    self:AddOption(ToggleOption.new("Hide God Mode")
        :AddToggleRef(protections, "hideGodMode")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Hide God Mode"):Toggle(protections.hideGodMode)
        end)
        :AddTooltip("Hide god mode from detection"))
    
    self:AddOption(ToggleOption.new("Hide Damage Modifier")
        :AddToggleRef(protections, "hideDamageModifier")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Hide Damage Modifier"):Toggle(protections.hideDamageModifier)
        end)
        :AddTooltip("Hide damage modifier from detection"))
    
    self:AddOption(ToggleOption.new("Hide Spectating Flag")
        :AddToggleRef(protections, "hideSpectatingFlag")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Hide Spectating Flag"):Toggle(protections.hideSpectatingFlag)
        end)
        :AddTooltip("Hide spectating flag from detection"))
    
    self:AddOption(ToggleOption.new("Hide Super Jump Flag")
        :AddToggleRef(protections, "hideSuperJumpFlag")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Hide Super Jump Flag"):Toggle(protections.hideSuperJumpFlag)
        end)
        :AddTooltip("Hide super jump flag from detection"))
    
    -- ===== ANTI SPAM =====
    self:AddOption(BreakOption.new("Anti Spam"))
    
    self:AddOption(ToggleOption.new("Block Bounty Spam")
        :AddToggleRef(protections, "blockBountySpam")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Bounty Spam"):Toggle(protections.blockBountySpam)
        end)
        :AddTooltip("Block bounty spam"))
    
    self:AddOption(ToggleOption.new("Block Ped Spam")
        :AddToggleRef(protections, "blockPedSpam")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Ped Spam"):Toggle(protections.blockPedSpam)
        end)
        :AddTooltip("Block ped spawn spam"))
    
    self:AddOption(ToggleOption.new("Block Vehicle Spam")
        :AddToggleRef(protections, "blockVehicleSpam")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Vehicle Spam"):Toggle(protections.blockVehicleSpam)
        end)
        :AddTooltip("Block vehicle spawn spam"))
    
    self:AddOption(ToggleOption.new("Block Explosion Spam")
        :AddToggleRef(protections, "blockExplosionSpam")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Explosion Spam"):Toggle(protections.blockExplosionSpam)
        end)
        :AddTooltip("Block explosion spam"))
    
    self:AddOption(ToggleOption.new("Block PTFX Spam")
        :AddToggleRef(protections, "blockPtfxSpam")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block PTFX Spam"):Toggle(protections.blockPtfxSpam)
        end)
        :AddTooltip("Block PTFX spam"))
    
    self:AddOption(ToggleOption.new("Block Sound Spam")
        :AddToggleRef(protections, "blockSoundSpam")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Sound Spam"):Toggle(protections.blockSoundSpam)
        end)
        :AddTooltip("Block sound spam"))
    
    self:AddOption(ToggleOption.new("Block Stun Gun Spam")
        :AddToggleRef(protections, "blockStunGunSpam")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Stun Gun Spam"):Toggle(protections.blockStunGunSpam)
        end)
        :AddTooltip("Block stun gun spam"))
    
    self:AddOption(ToggleOption.new("Block Chat Advertisements")
        :AddToggleRef(protections, "blockChatAdvertisements")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Chat Advertisements"):Toggle(protections.blockChatAdvertisements)
        end)
        :AddTooltip("Block chat advertisements"))
    
    self:AddOption(ToggleOption.new("Block Infinite Phone Ring")
        :AddToggleRef(protections, "blockInfinitePhoneRing")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Infinite Phone Ring"):Toggle(protections.blockInfinitePhoneRing)
        end)
        :AddTooltip("Block infinite phone ring"))
    
    self:AddOption(ToggleOption.new("Block Modded Reports")
        :AddToggleRef(protections, "blockModdedReports")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Modded Reports"):Toggle(protections.blockModdedReports)
        end)
        :AddTooltip("Block modded reports"))
    
    -- ===== ANTI TROLLING =====
    self:AddOption(BreakOption.new("Anti Trolling"))
    
    self:AddOption(ToggleOption.new("Block Cages")
        :AddToggleRef(protections, "blockCages")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Cages"):Toggle(protections.blockCages)
        end)
        :AddTooltip("Block cage spawns"))
    
    self:AddOption(ToggleOption.new("Vehicle Kick Protection")
        :AddToggleRef(protections, "vehicleKickProtection")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Vehicle Kick Protection"):Toggle(protections.vehicleKickProtection)
        end)
        :AddTooltip("Protect from vehicle kicks"))
    
    self:AddOption(ToggleOption.new("Block Remote Clear Task")
        :AddToggleRef(protections, "blockRemoteClearTask")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Remote Clear Task"):Toggle(protections.blockRemoteClearTask)
        end)
        :AddTooltip("Block remote task clear"))
    
    self:AddOption(ToggleOption.new("Block Remote Ragdoll")
        :AddToggleRef(protections, "blockRemoteRagdoll")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Remote Ragdoll"):Toggle(protections.blockRemoteRagdoll)
        end)
        :AddTooltip("Block remote ragdoll"))
    
    self:AddOption(ToggleOption.new("Block Remote Control")
        :AddToggleRef(protections, "blockRemoteControl")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Remote Control"):Toggle(protections.blockRemoteControl)
        end)
        :AddTooltip("Block remote control"))
    
    self:AddOption(ToggleOption.new("Block All Control")
        :AddToggleRef(protections, "blockAllControl")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block All Control"):Toggle(protections.blockAllControl)
        end)
        :AddTooltip("Block all control"))
    
    self:AddOption(ToggleOption.new("Block Remove Weapon")
        :AddToggleRef(protections, "blockRemoveWeapon")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Remove Weapon"):Toggle(protections.blockRemoveWeapon)
        end)
        :AddTooltip("Block weapon removal"))
    
    self:AddOption(ToggleOption.new("Block Give Weapon")
        :AddToggleRef(protections, "blockGiveWeapon")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Block Give Weapon"):Toggle(protections.blockGiveWeapon)
        end)
        :AddTooltip("Block weapon giving"))
    
    -- ===== WEAPONS =====
    self:AddOption(BreakOption.new("Weapons"))
    
    self:AddOption(ToggleOption.new("Anti Aim")
        :AddToggleRef(protections, "antiAim")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Anti Aim"):Toggle(protections.antiAim)
        end)
        :AddTooltip("Block aiming at you"))
    
    self:AddOption(ToggleOption.new("Anti Shoot")
        :AddToggleRef(protections, "antiShoot")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Anti Shoot"):Toggle(protections.antiShoot)
        end)
        :AddTooltip("Block shooting at you"))
    
    self:AddOption(ToggleOption.new("Disable Projectiles")
        :AddToggleRef(protections, "disableProjectiles")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Disable Projectiles"):Toggle(protections.disableProjectiles)
        end)
        :AddTooltip("Disable incoming projectiles"))
    
    self:AddOption(ToggleOption.new("Disable Bullets")
        :AddToggleRef(protections, "disableBullets")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Disable Bullets"):Toggle(protections.disableBullets)
        end)
        :AddTooltip("Disable incoming bullets"))
    
    -- ===== OTHER =====
    self:AddOption(BreakOption.new("Other"))
    
    self:AddOption(ToggleOption.new("Use Relay Connection")
        :AddToggleRef(protections, "useRelayConnection")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Use Relay Connection"):Toggle(protections.useRelayConnection)
        end)
        :AddTooltip("Use relay connection"))
    
    self:AddOption(ToggleOption.new("Disable Cam Shake")
        :AddToggleRef(protections, "disableCamShake")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Disable Cam Shake"):Toggle(protections.disableCamShake)
        end)
        :AddTooltip("Disable camera shake"))
    
    self:AddOption(ToggleOption.new("Notify Spectate")
        :AddToggleRef(protections, "notifySpectate")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Notify Spectate"):Toggle(protections.notifySpectate)
        end)
        :AddTooltip("Notify when spectated"))
    
    self:AddOption(ToggleOption.new("Anti Spectate")
        :AddToggleRef(protections, "antiSpectate")
        :AddFunction(function()
            FeatureMgr.GetFeatureByName("Anti Spectate"):Toggle(protections.antiSpectate)
        end)
        :AddTooltip("Block spectating"))
end

return ProtectionMenu
