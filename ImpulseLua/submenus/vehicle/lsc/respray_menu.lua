--[[
    Impulse Lua - LSC Respray Menu
    Port of vehicleResprayMenu.cpp
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local NumberOption = require("Impulse/ImpulseLua/lib/options/number")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")
local BreakOption = require("Impulse/ImpulseLua/lib/options/break")

local ResprayMenu = setmetatable({}, { __index = Submenu })
ResprayMenu.__index = ResprayMenu

local instance = nil

-- Classic colors
local classicColors = {
    { name = "Black", value = 0 },
    { name = "Carbon Black", value = 147 },
    { name = "Graphite", value = 1 },
    { name = "Anthracite Black", value = 11 },
    { name = "Black Steel", value = 2 },
    { name = "Dark Steel", value = 3 },
    { name = "Silver", value = 4 },
    { name = "Bluish Silver", value = 5 },
    { name = "Red", value = 27 },
    { name = "Torino Red", value = 28 },
    { name = "Formula Red", value = 29 },
    { name = "Lava Red", value = 150 },
    { name = "Blaze Red", value = 30 },
    { name = "Hot Pink", value = 135 },
    { name = "Orange", value = 38 },
    { name = "Bright Orange", value = 138 },
    { name = "Gold", value = 99 },
    { name = "Bronze", value = 90 },
    { name = "Yellow", value = 88 },
    { name = "Race Yellow", value = 89 },
    { name = "Dark Green", value = 49 },
    { name = "Racing Green", value = 50 },
    { name = "Sea Green", value = 51 },
    { name = "Lime Green", value = 92 },
    { name = "Midnight Blue", value = 141 },
    { name = "Galaxy Blue", value = 61 },
    { name = "Dark Blue", value = 62 },
    { name = "Blue", value = 64 },
    { name = "Racing Blue", value = 73 },
    { name = "Ultra Blue", value = 70 },
    { name = "Light Blue", value = 74 },
    { name = "Chocolate Brown", value = 96 },
    { name = "Schafter Purple", value = 71 },
    { name = "Midnight Purple", value = 142 },
    { name = "Bright Purple", value = 145 },
    { name = "Cream", value = 107 },
    { name = "Ice White", value = 111 },
    { name = "Frost White", value = 112 }
}

-- Matte colors
local matteColors = {
    { name = "Black", value = 12 },
    { name = "Gray", value = 13 },
    { name = "Light Gray", value = 14 },
    { name = "Ice White", value = 131 },
    { name = "Blue", value = 83 },
    { name = "Dark Blue", value = 82 },
    { name = "Midnight Blue", value = 84 },
    { name = "Midnight Purple", value = 149 },
    { name = "Red", value = 39 },
    { name = "Dark Red", value = 40 },
    { name = "Orange", value = 41 },
    { name = "Yellow", value = 42 },
    { name = "Lime Green", value = 55 },
    { name = "Green", value = 128 },
    { name = "Forest Green", value = 151 },
    { name = "Olive Darb", value = 152 },
    { name = "Dark Earth", value = 153 },
    { name = "Desert Tan", value = 154 }
}

-- Metal colors
local metalColors = {
    { name = "Pearlescent Steel", value = 18 },
    { name = "Brushed Steel", value = 117 },
    { name = "Brushed Black Steel", value = 118 },
    { name = "Brushed Aluminum", value = 119 },
    { name = "Pure Gold", value = 158 },
    { name = "Brushed Gold", value = 159 },
    { name = "Pearlescent Gold", value = 160 }
}

local vars = {
    enveffScale = 0.0,
    primaryR = 0,
    primaryG = 0,
    primaryB = 0,
    secondaryR = 0,
    secondaryG = 0,
    secondaryB = 0,
    primaryClassic = 1,
    primaryMatte = 1,
    primaryMetal = 1,
    secondaryClassic = 1,
    secondaryMatte = 1,
    secondaryMetal = 1,
    pearlClassic = 1,
    pearlMatte = 1,
    pearlMetal = 1,
    wheelClassic = 1,
    wheelMatte = 1,
    wheelMetal = 1
}

-- Helper: Check if player is in vehicle
local function IsInVehicle()
    local ped = PLAYER.PLAYER_PED_ID()
    return PED.IS_PED_IN_ANY_VEHICLE(ped, false)
end

-- Helper: Get current vehicle
local function GetCurrentVehicle()
    local ped = PLAYER.PLAYER_PED_ID()
    return PED.GET_VEHICLE_PED_IS_IN(ped, false)
end

-- Set primary color (custom RGB)
local function SetPrimaryColorRGB()
    if IsInVehicle() then
        local veh = GetCurrentVehicle()
        VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
        VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(veh, vars.primaryR, vars.primaryG, vars.primaryB)
    end
end

-- Set secondary color (custom RGB)
local function SetSecondaryColorRGB()
    if IsInVehicle() then
        local veh = GetCurrentVehicle()
        VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
        VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(veh, vars.secondaryR, vars.secondaryG, vars.secondaryB)
    end
end

-- Set primary preset color (preserves secondary color)
local function SetPrimaryColor(colorValue)
    if IsInVehicle() then
        local veh = GetCurrentVehicle()
        VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
        VEHICLE.CLEAR_VEHICLE_CUSTOM_PRIMARY_COLOUR(veh)
        
        -- Read current secondary color using Memory pointers
        local primaryPtr = Memory.AllocInt()
        local secondaryPtr = Memory.AllocInt()
        if primaryPtr ~= 0 and secondaryPtr ~= 0 then
            VEHICLE.GET_VEHICLE_COLOURS(veh, primaryPtr, secondaryPtr)
            local secondary = Memory.ReadInt(secondaryPtr)
            VEHICLE.SET_VEHICLE_COLOURS(veh, colorValue, secondary)
            Memory.Free(primaryPtr)
            Memory.Free(secondaryPtr)
        else
            -- Fallback if memory allocation fails
            VEHICLE.SET_VEHICLE_COLOURS(veh, colorValue, colorValue)
        end
    end
end

-- Set secondary preset color (preserves primary color)
local function SetSecondaryColor(colorValue)
    if IsInVehicle() then
        local veh = GetCurrentVehicle()
        VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
        VEHICLE.CLEAR_VEHICLE_CUSTOM_SECONDARY_COLOUR(veh)
        
        -- Read current primary color using Memory pointers
        local primaryPtr = Memory.AllocInt()
        local secondaryPtr = Memory.AllocInt()
        if primaryPtr ~= 0 and secondaryPtr ~= 0 then
            VEHICLE.GET_VEHICLE_COLOURS(veh, primaryPtr, secondaryPtr)
            local primary = Memory.ReadInt(primaryPtr)
            VEHICLE.SET_VEHICLE_COLOURS(veh, primary, colorValue)
            Memory.Free(primaryPtr)
            Memory.Free(secondaryPtr)
        else
            -- Fallback if memory allocation fails
            VEHICLE.SET_VEHICLE_COLOURS(veh, colorValue, colorValue)
        end
    end
end

-- Set pearlescent color (preserves wheel color)
local function SetPearlColor(colorValue)
    if IsInVehicle() then
        local veh = GetCurrentVehicle()
        VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
        
        -- Read current wheel color using Memory pointers
        local pearlPtr = Memory.AllocInt()
        local wheelPtr = Memory.AllocInt()
        if pearlPtr ~= 0 and wheelPtr ~= 0 then
            VEHICLE.GET_VEHICLE_EXTRA_COLOURS(veh, pearlPtr, wheelPtr)
            local wheel = Memory.ReadInt(wheelPtr)
            VEHICLE.SET_VEHICLE_EXTRA_COLOURS(veh, colorValue, wheel)
            Memory.Free(pearlPtr)
            Memory.Free(wheelPtr)
        else
            -- Fallback if memory allocation fails
            VEHICLE.SET_VEHICLE_EXTRA_COLOURS(veh, colorValue, colorValue)
        end
    end
end

-- Set wheel color (preserves pearl color)
local function SetWheelColor(colorValue)
    if IsInVehicle() then
        local veh = GetCurrentVehicle()
        VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
        
        -- Read current pearl color using Memory pointers
        local pearlPtr = Memory.AllocInt()
        local wheelPtr = Memory.AllocInt()
        if pearlPtr ~= 0 and wheelPtr ~= 0 then
            VEHICLE.GET_VEHICLE_EXTRA_COLOURS(veh, pearlPtr, wheelPtr)
            local pearl = Memory.ReadInt(pearlPtr)
            VEHICLE.SET_VEHICLE_EXTRA_COLOURS(veh, pearl, colorValue)
            Memory.Free(pearlPtr)
            Memory.Free(wheelPtr)
        else
            -- Fallback if memory allocation fails
            VEHICLE.SET_VEHICLE_EXTRA_COLOURS(veh, colorValue, colorValue)
        end
    end
end

-- Build scroll names from color table
local function BuildColorNames(colorTable)
    local names = {}
    for i, c in ipairs(colorTable) do
        names[i] = c.name
    end
    return names
end

function ResprayMenu.GetInstance()
    if not instance then
        instance = setmetatable(Submenu.new("Respray"), ResprayMenu)
        instance:Init()
    end
    return instance
end

function ResprayMenu:Init()
    local classicNames = BuildColorNames(classicColors)
    local matteNames = BuildColorNames(matteColors)
    local metalNames = BuildColorNames(metalColors)
    
    -- Enveff scale
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Enveff scale")
        :AddNumberRef(vars, "enveffScale", "%.2f", 0.02)
        :AddMin(0):AddMax(1)
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            if IsInVehicle() then
                VEHICLE.SET_VEHICLE_ENVEFF_SCALE(GetCurrentVehicle(), vars.enveffScale)
            end
        end)
        :AddTooltip("Set vehicle enveff scale (shininess)")
        :SetDonor())
    
    -- PRIMARY SECTION
    self:AddOption(BreakOption.new("Primary Color"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Primary Red")
        :AddNumberRef(vars, "primaryR", "%d", 5)
        :AddMin(0):AddMax(255)
        :AddRequirement(IsInVehicle)
        :AddFunction(SetPrimaryColorRGB)
        :AddTooltip("Set primary red")
        :SetDonor())
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Primary Green")
        :AddNumberRef(vars, "primaryG", "%d", 5)
        :AddMin(0):AddMax(255)
        :AddRequirement(IsInVehicle)
        :AddFunction(SetPrimaryColorRGB)
        :AddTooltip("Set primary green")
        :SetDonor())
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Primary Blue")
        :AddNumberRef(vars, "primaryB", "%d", 5)
        :AddMin(0):AddMax(255)
        :AddRequirement(IsInVehicle)
        :AddFunction(SetPrimaryColorRGB)
        :AddTooltip("Set primary blue")
        :SetDonor())
    
    self:AddOption(ButtonOption.new("Primary Chrome")
        :AddRequirement(IsInVehicle)
        :AddFunction(function() SetPrimaryColor(120) end)
        :AddTooltip("Set primary to chrome")
        :SetDonor())
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Primary Classic")
        :AddScroll(classicNames, 1)
        :AddIndexRef(vars, "primaryClassic")
        :CanLoop()
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            SetPrimaryColor(classicColors[vars.primaryClassic].value)
        end)
        :AddTooltip("Set primary classic color")
        :SetDonor())
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Primary Matte")
        :AddScroll(matteNames, 1)
        :AddIndexRef(vars, "primaryMatte")
        :CanLoop()
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            SetPrimaryColor(matteColors[vars.primaryMatte].value)
        end)
        :AddTooltip("Set primary matte color")
        :SetDonor())
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Primary Metals")
        :AddScroll(metalNames, 1)
        :AddIndexRef(vars, "primaryMetal")
        :CanLoop()
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            SetPrimaryColor(metalColors[vars.primaryMetal].value)
        end)
        :AddTooltip("Set primary metal color")
        :SetDonor())
    
    -- SECONDARY SECTION
    self:AddOption(BreakOption.new("Secondary Color"))
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Secondary Red")
        :AddNumberRef(vars, "secondaryR", "%d", 5)
        :AddMin(0):AddMax(255)
        :AddRequirement(IsInVehicle)
        :AddFunction(SetSecondaryColorRGB)
        :AddTooltip("Set secondary red")
        :SetDonor())
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Secondary Green")
        :AddNumberRef(vars, "secondaryG", "%d", 5)
        :AddMin(0):AddMax(255)
        :AddRequirement(IsInVehicle)
        :AddFunction(SetSecondaryColorRGB)
        :AddTooltip("Set secondary green")
        :SetDonor())
    
    self:AddOption(NumberOption.new(NumberOption.Type.SCROLL, "Secondary Blue")
        :AddNumberRef(vars, "secondaryB", "%d", 5)
        :AddMin(0):AddMax(255)
        :AddRequirement(IsInVehicle)
        :AddFunction(SetSecondaryColorRGB)
        :AddTooltip("Set secondary blue")
        :SetDonor())
    
    self:AddOption(ButtonOption.new("Secondary Chrome")
        :AddRequirement(IsInVehicle)
        :AddFunction(function() SetSecondaryColor(120) end)
        :AddTooltip("Set secondary to chrome")
        :SetDonor())
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Secondary Classic")
        :AddScroll(classicNames, 1)
        :AddIndexRef(vars, "secondaryClassic")
        :CanLoop()
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            SetSecondaryColor(classicColors[vars.secondaryClassic].value)
        end)
        :AddTooltip("Set secondary classic color")
        :SetDonor())
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Secondary Matte")
        :AddScroll(matteNames, 1)
        :AddIndexRef(vars, "secondaryMatte")
        :CanLoop()
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            SetSecondaryColor(matteColors[vars.secondaryMatte].value)
        end)
        :AddTooltip("Set secondary matte color")
        :SetDonor())
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Secondary Metals")
        :AddScroll(metalNames, 1)
        :AddIndexRef(vars, "secondaryMetal")
        :CanLoop()
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            SetSecondaryColor(metalColors[vars.secondaryMetal].value)
        end)
        :AddTooltip("Set secondary metal color")
        :SetDonor())
    
    -- PEARLESCENT SECTION
    self:AddOption(BreakOption.new("Pearlescent"))
    
    self:AddOption(ButtonOption.new("Pearl Chrome")
        :AddRequirement(IsInVehicle)
        :AddFunction(function() SetPearlColor(120) end)
        :AddTooltip("Set pearlescent to chrome")
        :SetDonor())
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Pearl Classic")
        :AddScroll(classicNames, 1)
        :AddIndexRef(vars, "pearlClassic")
        :CanLoop()
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            SetPearlColor(classicColors[vars.pearlClassic].value)
        end)
        :AddTooltip("Set pearlescent classic color")
        :SetDonor())
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Pearl Matte")
        :AddScroll(matteNames, 1)
        :AddIndexRef(vars, "pearlMatte")
        :CanLoop()
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            SetPearlColor(matteColors[vars.pearlMatte].value)
        end)
        :AddTooltip("Set pearlescent matte color")
        :SetDonor())
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Pearl Metals")
        :AddScroll(metalNames, 1)
        :AddIndexRef(vars, "pearlMetal")
        :CanLoop()
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            SetPearlColor(metalColors[vars.pearlMetal].value)
        end)
        :AddTooltip("Set pearlescent metal color")
        :SetDonor())
    
    -- WHEELS SECTION
    self:AddOption(BreakOption.new("Wheel Color"))
    
    self:AddOption(ButtonOption.new("Wheel Chrome")
        :AddRequirement(IsInVehicle)
        :AddFunction(function() SetWheelColor(120) end)
        :AddTooltip("Set wheel color to chrome")
        :SetDonor())
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Wheel Classic")
        :AddScroll(classicNames, 1)
        :AddIndexRef(vars, "wheelClassic")
        :CanLoop()
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            SetWheelColor(classicColors[vars.wheelClassic].value)
        end)
        :AddTooltip("Set wheel classic color")
        :SetDonor())
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Wheel Matte")
        :AddScroll(matteNames, 1)
        :AddIndexRef(vars, "wheelMatte")
        :CanLoop()
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            SetWheelColor(matteColors[vars.wheelMatte].value)
        end)
        :AddTooltip("Set wheel matte color")
        :SetDonor())
    
    self:AddOption(ScrollOption.new(ScrollOption.Type.SCROLL, "Wheel Metals")
        :AddScroll(metalNames, 1)
        :AddIndexRef(vars, "wheelMetal")
        :CanLoop()
        :AddRequirement(IsInVehicle)
        :AddFunction(function()
            SetWheelColor(metalColors[vars.wheelMetal].value)
        end)
        :AddTooltip("Set wheel metal color")
        :SetDonor())
end

function ResprayMenu:FeatureUpdate()
    -- No continuous updates needed
end

return ResprayMenu
