local Submenu = require("Impulse/ImpulseLua/lib/submenu")

local SessionOverseerMenu = setmetatable({}, { __index = Submenu })
SessionOverseerMenu.__index = SessionOverseerMenu

local instance = nil

function SessionOverseerMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Session overseer"), SessionOverseerMenu)
        instance:Init()
    end
    return instance
end

function SessionOverseerMenu:Init()
    -- Placeholder for now
    -- The user explicitly said to leave this for now, so I'll leave it effectively empty but functional
end

return SessionOverseerMenu
