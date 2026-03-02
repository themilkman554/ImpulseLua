local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")

local MoneyMenu = setmetatable({}, { __index = Submenu })
MoneyMenu.__index = MoneyMenu

local instance = nil

function MoneyMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Money"), MoneyMenu)
        instance:Init()
    end
    return instance
end

function MoneyMenu:Init()
    self:AddOption(ButtonOption.new("you wish nigga"))
end

return MoneyMenu
