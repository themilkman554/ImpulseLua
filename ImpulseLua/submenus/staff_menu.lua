
local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local StaffMenu = setmetatable({}, { __index = Submenu })
StaffMenu.__index = StaffMenu

local instance = nil

function StaffMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Staff/Testing"), StaffMenu)
        instance:Init()
    end
    return instance
end

function StaffMenu:Init()
    self:AddOption(BreakOption.new("Debug"))
    
    self:AddOption(ButtonOption.new("Print Position")
        :AddTooltip("Print current position to log")
        :AddFunction(function()
            local ped = PLAYER.PLAYER_PED_ID()
            local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
            local heading = ENTITY.GET_ENTITY_HEADING(ped)
            local msg = string.format("Pos: %.2f, %.2f, %.2f | Heading: %.2f", coords.x, coords.y, coords.z, heading)
            Logger.LogInfo(msg)
            GUI.AddToast("Debug", msg, 5000, 0)
        end))
    
    self:AddOption(ButtonOption.new("Print Vehicle Model")
        :AddTooltip("Print current vehicle model hash")
        :AddFunction(function()
            local ped = PLAYER.PLAYER_PED_ID()
            if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                local model = ENTITY.GET_ENTITY_MODEL(veh)
                local msg = string.format("Vehicle Model: 0x%X", model)
                Logger.LogInfo(msg)
                GUI.AddToast("Debug", msg, 5000, 0)
            else
                GUI.AddToast("Debug", "Not in a vehicle", 3000, 0)
            end
        end))
    
    self:AddOption(BreakOption.new("Testing"))
    
    self:AddOption(ButtonOption.new("Test Notification")
        :AddTooltip("Show a test notification")
        :AddFunction(function()
            GUI.AddToast("Test", "This is a test notification!", 3000, 0)
        end))
    
    self:AddOption(ButtonOption.new("Reload Textures")
        :AddTooltip("Request texture dictionaries again")
        :AddFunction(function()
            GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("Bookmarks", false)
            GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("commonmenu", false)
            GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT("mpleaderboard", false)
            GUI.AddToast("Debug", "Textures reloaded", 3000, 0)
        end))
end

return StaffMenu
