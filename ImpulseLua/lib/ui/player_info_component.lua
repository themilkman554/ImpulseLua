--[[
    Impulse Lua - Player Info Component
    Displays detailed player information in a floating panel
    Port of playerInfoComponent.cpp from Impulse C++
]]

local Renderer = require("Impulse/ImpulseLua/lib/renderer")
local Settings = require("Impulse/ImpulseLua/lib/settings")
local PlayerDataCache = require("Impulse/ImpulseLua/lib/player_data_cache")

local PlayerInfoComponent = {}

-- State
PlayerInfoComponent.enabled = true
PlayerInfoComponent.targetPlayer = -1

-- Window positioning (matching C++ UIWindow)
-- Position is CENTER of window, matching C++ convention
-- From C++: UIPlayerInfoComponent uses size 0.2 x 0.448, placed next to menu
PlayerInfoComponent.position = { x = 0.0, y = 0.0 }  -- Will be calculated relative to menu
PlayerInfoComponent.size = { width = 0.20, height = 0.448 }
PlayerInfoComponent.headerHeight = 0.03  -- matches GetRenderer()->m_dialogHeaderHeight

-- Calculated at runtime
local m_half = PlayerInfoComponent.size.width / 2
local m_whole = PlayerInfoComponent.size.width

-- Constants matching C++
local LINE_HEIGHT = 0.022
local TEXT_FONT = 4  -- Renderer font
local TEXT_SIZE = 0.35

--- Get player health string (from C++ GetEntityHealth)
local function GetEntityHealth(ped)
    if not ped or not ENTITY.DOES_ENTITY_EXIST(ped) then return "~c~Unknown~s~" end
    local health = ENTITY.GET_ENTITY_HEALTH(ped)
    local maxHealth = ENTITY.GET_ENTITY_MAX_HEALTH(ped)
    if health == 0 and maxHealth == 0 then return "~c~Unknown~s~"
    elseif health <= 0 then return "~c~Dead~s~"
    elseif health >= maxHealth then return "Full"
    else return string.format("%.0f%%", (health / maxHealth) * 100) end
end

--- Get player heading string (from C++ GetPlayerHeading)
local function GetPlayerHeading(ped)
    if not ped then return "~c~Unknown~s~" end
    local heading = math.floor(ENTITY.GET_ENTITY_HEADING(ped))
    if heading >= 0 and heading <= 90 then return string.format("North (%d)", heading)
    elseif heading > 90 and heading <= 180 then return string.format("East (%d)", heading)
    elseif heading > 180 and heading <= 270 then return string.format("South (%d)", heading)
    elseif heading > 270 and heading <= 360 then return string.format("West (%d)", heading)
    else return "~c~Unknown~s~" end
end

--- Get street name (from C++ GetPlayerStreetName)
--- Get street name (from C++ GetPlayerStreetName)
local function GetPlayerStreetName(coords)
    if not coords then return "~c~Unknown~s~" end
    
    -- Allocate memory for street and crossing hashes (4 bytes each)
    local streetPtr = Memory.AllocInt()
    local crossingPtr = Memory.AllocInt()
    
    if not streetPtr or not crossingPtr then
        if streetPtr then Memory.Free(streetPtr) end
        if crossingPtr then Memory.Free(crossingPtr) end
        return "~c~Unknown~s~"
    end
    
    local ok = pcall(function()
        PATHFIND.GET_STREET_NAME_AT_COORD(coords.x, coords.y, coords.z, streetPtr, crossingPtr)
    end)
    
    if not ok then
        Memory.Free(streetPtr)
        Memory.Free(crossingPtr)
        return "~c~Unknown~s~"
    end
    
    local streetHash = Memory.ReadInt(streetPtr)
    Memory.Free(streetPtr)
    Memory.Free(crossingPtr)
    
    local ok2, street = pcall(function()
        return HUD.GET_STREET_NAME_FROM_HASH_KEY(streetHash)
    end)
    
    if not ok2 then return "~c~Unknown~s~" end
    return (street and street ~= "") and street or "~c~Unknown~s~"
end

--- Get zone name
local function GetZoneName(coords)
    if not coords then return "~c~Unknown~s~" end
    local ok, zone = pcall(function()
        return ZONE.GET_NAME_OF_ZONE(coords.x, coords.y, coords.z)
    end)
    if not ok or not zone then return "~c~Unknown~s~" end
    local ok2, label = pcall(function()
        return HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(zone)
    end)
    if ok2 and label and label ~= "" then
        return label
    end
    return zone or "~c~Unknown~s~"
end

--- Get vehicle name
local function GetVehicleName(ped)
    if not ped or not ENTITY.DOES_ENTITY_EXIST(ped) then return "~c~Not in a vehicle~s~" end
    if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then return "~c~Not in a vehicle~s~" end
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    local model = ENTITY.GET_ENTITY_MODEL(vehicle)
    local displayName = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(model)
    if displayName and displayName ~= "CARNOTFOUND" then
        local label = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(displayName)
        return label or displayName
    end
    return "Vehicle"
end

--- Get player status/stance (from C++ GetPlayerStance)
local function GetPlayerStance(ped)
    if not ped or not ENTITY.DOES_ENTITY_EXIST(ped) then return "~c~Unknown~s~" end
    if TASK.IS_PED_STILL(ped) then return "Player is still"
    elseif TASK.IS_PED_RUNNING(ped) then return "Player is running"
    elseif TASK.IS_PED_SPRINTING(ped) then return "Player is sprinting"
    elseif TASK.IS_PED_WALKING(ped) then return "Player is walking"
    elseif PED.IS_PED_SWIMMING(ped) then return "Player is swimming"
    elseif PED.IS_PED_FALLING(ped) then return "Player is falling"
    else return "~c~Unknown~s~" end
end

local WeaponMap = {
    [2725352035] = "WT_UNARMED",
    [2578778090] = "WT_KNIFE",
    [1737195953] = "WT_NGTSTK",
    [1317494643] = "WT_HAMMER",
    [2508868239] = "WT_BAT",
    [1141786504] = "WT_GOLFCLUB",
    [2227010557] = "WT_CROWBAR",
    [453432689] = "WT_PIST",
    [1593441988] = "WT_PIST_CBT",
    [584646201] = "WT_PIST_AP",
    [2578377531] = "WT_PIST_50",
    [324215364] = "WT_SMG_MCR",
    [736523883] = "WT_SMG",
    [4024951519] = "WT_SMG_ASL",
    [3220176749] = "WT_RIFLE_ASL",
    [2210333304] = "WT_RIFLE_CBN",
    [2937143193] = "WT_RIFLE_ADV",
    [2634544996] = "WT_MG",
    [2144741730] = "WT_MG_CBT",
    [487013001] = "WT_SG_PMP",
    [2017895192] = "WT_SG_SOF",
    [3800352039] = "WT_SG_ASL",
    [2640438543] = "WT_SG_BLP",
    [911657153] = "WT_STUN",
    [100416529] = "WT_SNIP_RIF",
    [205991906] = "WT_SNIP_HVY",
    [2726580491] = "WT_GL",
    [2982836145] = "WT_RPG",
    [1119849093] = "WT_MINIGUN",
    [2481070269] = "WT_GNADE",
    [741814745] = "WT_GNADE_STK",
    [4256991824] = "WT_GNADE_SMK",
    [2694266206] = "WT_BZGAS",
    [615608432] = "WT_MOLOTOV",
    [101631238] = "WT_FIRE",
    [883325847] = "WT_PETROL",
    [600439132] = "WT_BALL",
    [1233104067] = "WT_FLARE",
    [3249783761] = "WT_REVOLVER",
    [3756226112] = "WT_SWBLADE",
    [940833800] = "WT_SHATCHET",
    [4192643659] = "WT_BOTTLE",
    [3218215474] = "WT_SNSPISTOL",
    [317205821] = "WT_AUTOSHGN",
    [3441901897] = "WT_BATTLEAXE",
    [125959754] = "WT_CMPGL",
    [3173288789] = "WT_MINISMG",
    [3125143736] = "WT_PIPEBOMB",
    [2484171525] = "WT_POOLCUE",
    [419712736] = "WT_WRENCH",
    [3523564046] = "WT_HVYPISTOL",
    [3231910285] = "WT_SPCARBINE",
    [2132975508] = "WT_BULLRIFLE",
    [1672152130] = "WT_HOMLNCH",
    [2874559379] = "WT_PRXMINE",
    [126349499] = "WT_SNWBALL",
    [2228681469] = "WT_BULLRIFLE2",
    [2548703416] = "WT_REV_DA",
    [1785463520] = "WT_MKRIFLE2",
    [1432025498] = "WT_SG_PMP2",
    [3415619887] = "WT_REVOLVER2",
    [2285322324] = "WT_SNSPISTOL2",
    [2526821735] = "WT_SPCARBINE2",
    [961495388] = "WT_RIFLE_ASL2",
    [4208062921] = "WT_RIFLE_CBN2",
    [3686625920] = "WT_MG_CBT2",
    [177293209] = "WT_SNIP_HVY2",
    [3219281620] = "WT_PIST2",
    [2024373456] = "WT_SMG2",
    [2343591895] = "WT_FLASHLIGHT",
    [1198879012] = "WT_FLAREGUN",
    [2460120199] = "WT_DAGGER",
    [137902532] = "WT_VPISTOL",
    [2138347493] = "WT_FIREWRK",
    [2828843422] = "WT_MUSKET",
    [3713923289] = "WT_MACHETE",
    [3675956304] = "WT_MCHPIST",
    [1649403952] = "WT_CMPRIFLE",
    [4019527611] = "WT_DBSHGN",
    [984333226] = "WT_HVYSHGN",
    [3342088282] = "WT_MKRIFLE",
    [171789620] = "WT_COMBATPDW",
    [3638508604] = "WT_KNUCKLE",
    [3696079510] = "WT_MKPISTOL",
    [1627465347] = "WT_GUSNBRG",
    [4191993645] = "WT_HATCHET",
    [1834241177] = "WT_RAILGUN"
}

--- Get player weapon name (from C++ GetPlayerWeaponName)
local function GetPlayerWeaponName(weaponHash)
    local label = WeaponMap[weaponHash]
    if label then
        local ok, name = pcall(function()
            return HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(label)
        end)
        if ok and name and name ~= "" and name ~= "NULL" then
            return name
        end
        return label
    end
    return "~c~Unknown~s~"
end

--- Get ammo in player weapon (from C++ GetAmmoInPlayerWeapon)
local function GetAmmoInPlayerWeapon(ped, weaponHash)
    if not ped or not weaponHash then return "~c~None~s~" end
    local ok, ammo = pcall(function()
        return WEAPON.GET_AMMO_IN_PED_WEAPON(ped, weaponHash)
    end)
    if ok and ammo and ammo > 0 then
        return tostring(ammo)
    end
    return "~c~None~s~"
end

--- Draw info row matching C++ drawInfo exactly
--- x = horizontal offset from left edge of window
--- width = width of this column
--- yOffset = row number (0-indexed)
--- name = label text
--- value = value text
--- texture = optional sprite to draw (for medal)
--- color = color for sprite
local function DrawInfo(x, width, yOffset, name, value, texture, color)
    local textColor = Renderer.Colors.Option
    local offset = 0.0025
    
    -- Calculate positions matching C++:
    -- float xPos = m_parent->m_position.x + x - m_parent->m_size.x / 2;
    -- float yPos = m_parent->m_position.y + 0.022f * yOffset - m_parent->m_size.y / 2 + m_parent->m_headerHeight;
    local xPos = PlayerInfoComponent.position.x + x - PlayerInfoComponent.size.width / 2
    local yPos = PlayerInfoComponent.position.y + LINE_HEIGHT * yOffset - PlayerInfoComponent.size.height / 2 + PlayerInfoComponent.headerHeight
    
    if texture then
        -- Draw medal icon
        Renderer.DrawSprite({ dict = "commonmenu", name = "common_medal" },
            xPos + offset * 2 + 0.006, yPos + 0.015, 0.012, 0.018, 0, color)
        -- Draw name with offset (account for icon)
        Renderer.DrawString(name, xPos + offset + 0.012, yPos, TEXT_FONT, TEXT_SIZE, textColor, false, 1, xPos + offset + 0.012, xPos + width - offset)
    else
        -- Draw name left aligned
        Renderer.DrawString(name, xPos + offset, yPos, TEXT_FONT, TEXT_SIZE, textColor, false, 1, xPos + offset, xPos + width - offset)
    end
    
    -- Draw value right aligned
    Renderer.DrawString(value or "", xPos + offset, yPos, TEXT_FONT, TEXT_SIZE, textColor, false, 2, xPos + offset, xPos + width - offset)
end

--- Draw vertical middle line matching C++ drawMiddleLine
local function DrawMiddleLine(yOffset)
    local xPos = PlayerInfoComponent.position.x
    local yPos = PlayerInfoComponent.position.y + LINE_HEIGHT * yOffset + 0.015 - PlayerInfoComponent.size.height / 2 + PlayerInfoComponent.headerHeight
    Renderer.DrawRect(xPos, yPos, Renderer.Layout.lineWidth * 2, LINE_HEIGHT, Renderer.Colors.Outline)
    Renderer.DrawRect(xPos, yPos, Renderer.Layout.lineWidth, LINE_HEIGHT, { r = 0, g = 0, b = 0, a = 255 })
end

--- Draw middle line top cap
local function DrawMiddleLineTop(yOffset)
    local xPos = PlayerInfoComponent.position.x
    local yPos = PlayerInfoComponent.position.y + LINE_HEIGHT * yOffset + 0.015 - LINE_HEIGHT / 2 - PlayerInfoComponent.size.height / 2 + PlayerInfoComponent.headerHeight
    Renderer.DrawRect(xPos, yPos, Renderer.Layout.lineWidth * 2, Renderer.Layout.lineWidth * 2, Renderer.Colors.Outline)
end

--- Draw middle line bottom cap
local function DrawMiddleLineBottom(yOffset)
    local xPos = PlayerInfoComponent.position.x
    local yPos = PlayerInfoComponent.position.y + LINE_HEIGHT * yOffset + 0.015 + LINE_HEIGHT / 2 - PlayerInfoComponent.size.height / 2 + PlayerInfoComponent.headerHeight
    Renderer.DrawRect(xPos, yPos, Renderer.Layout.lineWidth * 2, Renderer.Layout.lineWidth * 2, Renderer.Colors.Outline)
end

--- Convert world X coordinate to screen X (from C++ relevateX)
local function relevateX(x)
    return ((0.340703125 / 10000) * x + (0.340703125 / 10000) * 4000) / 16 * 9
end

--- Convert world Y coordinate to screen Y (from C++ relevateY)
local function relevateY(y)
    return ((0.49 / 12000) * y + (0.49 / 12000) * 8000)
end

--- Draw sprite with aspect ratio correction (from C++ DrawSprite1)
--- Note: C++ divides scaleX and scaleY by 16 and 9 respectively for aspect ratio
local function DrawSprite1(textureDict, textureName, screenX, screenY, scaleX, scaleY, heading, red, green, blue, alpha)
    -- Request texture dict if not loaded
    if not GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(textureDict) then
        GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(textureDict, false)
    end
    
    -- Draw with aspect ratio correction (divide by 16 and 9)
    Renderer.DrawSprite({ dict = textureDict, name = textureName },
        screenX, screenY, scaleX / 16, scaleY / 9, heading or 0,
        { r = red, g = green, b = blue, a = alpha })
end

--- Draw map panel (ported from C++ UIPlayerInfoComponent::MapPanel)
local function DrawMapPanel()
    local temp = 14
    local bg_length = temp * 0.035
    
    local xPos = PlayerInfoComponent.position.x
    local yPos = PlayerInfoComponent.position.y
    local offsety = -0.268
    local offsetx = 0.184
    
    -- Calculation from C++:
    -- DrawSprite2("mp_freemode_mc", "debugmap", offsetx + xPos - 0.0055f, offsety + yPos + bg_length / 2 + 0.021f - 0.008f, (0.340703125f / 16 * 9) - 0.051f, bg_length - 0.042f - 0.016f, ...);
    
    local screenX = offsetx + xPos - 0.0055
    local screenY = offsety + yPos + bg_length / 2 + 0.021 - 0.008
    local scaleX = (0.340703125 / 16 * 9) - 0.051
    local scaleY = bg_length - 0.042 - 0.016
    
    -- Draw texture
    Renderer.DrawSprite({ dict = "mp_freemode_mc", name = "debugmap" },
        screenX, screenY, scaleX, scaleY, 0, { r = 255, g = 255, b = 255, a = 255 })

    -- Draw inner border (Primary color)
    Renderer.DrawRect(screenX, screenY - scaleY / 2, scaleX + Renderer.Layout.lineWidth * 2, Renderer.Layout.lineWidth, Renderer.Colors.Primary)  -- Top
    Renderer.DrawRect(screenX, screenY + scaleY / 2, scaleX + Renderer.Layout.lineWidth * 2, Renderer.Layout.lineWidth, Renderer.Colors.Primary)  -- Bottom
    Renderer.DrawRect(screenX - scaleX / 2, screenY, Renderer.Layout.lineWidth, scaleY + Renderer.Layout.lineWidth * 2, Renderer.Colors.Primary)  -- Left
    Renderer.DrawRect(screenX + scaleX / 2, screenY, Renderer.Layout.lineWidth, scaleY + Renderer.Layout.lineWidth * 2, Renderer.Colors.Primary)  -- Right
    
    -- Draw outer border (Outline color)
    Renderer.DrawRect(screenX, screenY - scaleY / 2 - Renderer.Layout.lineWidth, scaleX + Renderer.Layout.lineWidth * 2, Renderer.Layout.lineWidth, Renderer.Colors.Outline)  -- Top
    Renderer.DrawRect(screenX, screenY + scaleY / 2 + Renderer.Layout.lineWidth, scaleX + Renderer.Layout.lineWidth * 2, Renderer.Layout.lineWidth, Renderer.Colors.Outline)  -- Bottom
    Renderer.DrawRect(screenX - scaleX / 2 - Renderer.Layout.lineWidth, screenY, Renderer.Layout.lineWidth, scaleY + Renderer.Layout.lineWidth * 3, Renderer.Colors.Outline)  -- Left
    Renderer.DrawRect(screenX + scaleX / 2 + Renderer.Layout.lineWidth, screenY, Renderer.Layout.lineWidth, scaleY + Renderer.Layout.lineWidth * 3, Renderer.Colors.Outline)  -- Right
end

--- Set target player
function PlayerInfoComponent.SetPlayer(playerId)
    PlayerInfoComponent.targetPlayer = playerId
end

--- Render the player info component
function PlayerInfoComponent.Render()
    if not PlayerInfoComponent.enabled then return end
    if PlayerInfoComponent.targetPlayer < 0 then return end
    
    -- DEBUG: Set to true to disable entire component
    local DEBUG_DISABLE = false
    if DEBUG_DISABLE then return end
    
    local playerId = PlayerInfoComponent.targetPlayer
    
    -- Safely get player ped with pcall
    local ok, ped = pcall(function()
        return PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerId)
    end)
    if not ok or not ped or ped == 0 then return end
    
    local ok2, exists = pcall(function()
        return ENTITY.DOES_ENTITY_EXIST(ped)
    end)
    if not ok2 or not exists then return end
    
    local playerName = PLAYER.GET_PLAYER_NAME(playerId) or "Unknown"
    local myPed = PLAYER.PLAYER_PED_ID()
    local myCoords = ENTITY.GET_ENTITY_COORDS(myPed, true)
    local playerCoords = ENTITY.GET_ENTITY_COORDS(ped, true)
    
    -- Calculate position relative to menu (right side of menu)
    -- In C++: window is positioned next to menu
    if Renderer.Layout.infoboxPos then
        PlayerInfoComponent.position.x = Renderer.Layout.infoboxPos.x
        PlayerInfoComponent.position.y = Renderer.Layout.infoboxPos.y
    else
        PlayerInfoComponent.position.x = Renderer.Layout.posX + Renderer.Layout.width / 2 + PlayerInfoComponent.size.width / 2 + 0.01
        PlayerInfoComponent.position.y = Renderer.Layout.posY + 0.15  -- Adjust to align with menu
    end
    
    local width = PlayerInfoComponent.size.width
    local height = PlayerInfoComponent.size.height
    local posX = PlayerInfoComponent.position.x
    local posY = PlayerInfoComponent.position.y
    local half = width / 2
    local whole = width
    
    -- ===== DRAW BOX (matching C++ DrawBox) =====
    -- Draw main background (centered at position) with transparency
    -- C++ uses: (int)m_bgOpacity * 255 / 100 for alpha
    local bgOpacity = Renderer.Layout.bgOpacity or 75  -- Default 75% like C++
    local bgColor = { 
        r = Renderer.Colors.Primary.r, 
        g = Renderer.Colors.Primary.g, 
        b = Renderer.Colors.Primary.b, 
        a = math.floor(bgOpacity * 255 / 100)
    }
    Renderer.DrawRect(posX, posY, width, height, bgColor)
    
    -- Draw header sprite/rect at top (also transparent)
    local headerY = posY - height / 2 + PlayerInfoComponent.headerHeight / 2
    local headerColor = {
        r = Renderer.Colors.SubHeader.r,
        g = Renderer.Colors.SubHeader.g,
        b = Renderer.Colors.SubHeader.b,
        a = math.floor(bgOpacity * 255 / 100)
    }

    
    -- Draw title in header (matching C++: x - width/2 + 0.01, y - height/2 + 0.005, font 7, size 0.5)
    Renderer.DrawString(playerName, posX - width / 2 + 0.01, posY - height / 2 + 0.005, 7, 0.5, Renderer.Colors.Option, false)
    
    -- Draw inner border (Primary color)
    Renderer.DrawRect(posX, posY - height / 2, width + Renderer.Layout.lineWidth * 2, Renderer.Layout.lineWidth, Renderer.Colors.Primary)  -- Top
    Renderer.DrawRect(posX, posY + height / 2, width + Renderer.Layout.lineWidth * 2, Renderer.Layout.lineWidth, Renderer.Colors.Primary)  -- Bottom
    Renderer.DrawRect(posX - width / 2, posY, Renderer.Layout.lineWidth, height + Renderer.Layout.lineWidth * 2, Renderer.Colors.Primary)  -- Left
    Renderer.DrawRect(posX + width / 2, posY, Renderer.Layout.lineWidth, height + Renderer.Layout.lineWidth * 2, Renderer.Colors.Primary)  -- Right
    
    -- Draw outer border (Outline color)
    Renderer.DrawRect(posX, posY - height / 2 - Renderer.Layout.lineWidth, width + Renderer.Layout.lineWidth * 2, Renderer.Layout.lineWidth, Renderer.Colors.Outline)  -- Top
    Renderer.DrawRect(posX, posY + height / 2 + Renderer.Layout.lineWidth, width + Renderer.Layout.lineWidth * 2, Renderer.Layout.lineWidth, Renderer.Colors.Outline)  -- Bottom
    Renderer.DrawRect(posX - width / 2 - Renderer.Layout.lineWidth, posY, Renderer.Layout.lineWidth, height + Renderer.Layout.lineWidth * 3, Renderer.Colors.Outline)  -- Left
    Renderer.DrawRect(posX + width / 2 + Renderer.Layout.lineWidth, posY, Renderer.Layout.lineWidth, height + Renderer.Layout.lineWidth * 3, Renderer.Colors.Outline)  -- Right
    
    -- ===== GATHER DATA =====
    -- Safe distance calculation
    local distance = 0
    if playerCoords and myCoords and playerCoords.x and myCoords.x then
        local dx = playerCoords.x - myCoords.x
        local dy = playerCoords.y - myCoords.y
        local dz = playerCoords.z - myCoords.z
        distance = math.sqrt(dx*dx + dy*dy + dz*dz)
    end
    
    -- Safe vehicle speed calculation - DO NOT call GET_ENTITY_SPEED with vehicle=0
    local isInVehicle = PED.IS_PED_IN_ANY_VEHICLE(ped, false)
    local vehicle = 0
    local speed = 0
    if isInVehicle then
        vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
        if vehicle and vehicle ~= 0 and ENTITY.DOES_ENTITY_EXIST(vehicle) then
            speed = ENTITY.GET_ENTITY_SPEED(vehicle) * 3.6
        end
    end
    
    local myId = PLAYER.PLAYER_ID()
    local playerType, typeColor
    if playerId == myId then
        playerType, typeColor = "Me", { r = 194, g = 80, b = 80, a = 255 }
    else
        playerType, typeColor = "Client", { r = 255, g = 255, b = 255, a = 255 }
    end
    
    local armor = PED.GET_PED_ARMOUR(ped)
    local wanted = PLAYER.GET_PLAYER_WANTED_LEVEL(playerId)
    local model = ENTITY.GET_ENTITY_MODEL(ped)
    local isMale = model == MISC.GET_HASH_KEY("MP_M_Freemode_01")
    local isFemale = model == MISC.GET_HASH_KEY("MP_F_Freemode_01")
    local moddedModel = (not isMale and not isFemale) and "Yes" or "No"
    local isGodmode = PLAYER.GET_PLAYER_INVINCIBLE(playerId) and "Yes" or "No"
    local isInInterior = INTERIOR.GET_INTERIOR_FROM_ENTITY(ped) ~= 0 and "Yes" or "No"
    local ok4, isVisible = pcall(function()
        return ENTITY.IS_ENTITY_VISIBLE_TO_SCRIPT(ped)
    end)
    isVisible = ok4 and isVisible or false
    local inCutscene = NETWORK.NETWORK_IS_PLAYER_IN_MP_CUTSCENE(playerId) and "Yes" or "No"
    local inAir = ENTITY.IS_ENTITY_IN_AIR(ped) and "Yes" or "No"
    
    -- ===== DRAW MAP PANEL =====
    DrawMapPanel()
    
    -- ===== DRAW PLAYER POSITIONS ON MAP (from C++ lines 979-990) =====
    local yPos = PlayerInfoComponent.position.y
    local xPos = PlayerInfoComponent.position.x
    local offsety = -0.268
    local offsetx = 0.184
    
    -- Draw all players as white markers
    local MAXPLAYERS = 32  -- Typical max players in GTA Online
    for i = 0, MAXPLAYERS - 1 do
        local ok, ped = pcall(function()
            return PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(i)
        end)
        if ok and ped and ped ~= 0 then
            local ok2, exists = pcall(function()
                return ENTITY.DOES_ENTITY_EXIST(ped)
            end)
            if ok2 and exists then
                local ok3, coords = pcall(function()
                    return ENTITY.GET_ENTITY_COORDS(ped, false)
                end)
                if ok3 and coords then
                    -- Draw white marker for each player
                    -- C++: DrawSprite1("shared", "menuplus_32", offsetx + xPos - 0.09f + relevateX(player.x), offsety + yPos - 0.083f / 2 + 0.49f + 0.208f - relevateY(player.y), 0.25f, 0.25f, 0, 255, 255, 255, 180);
                    local screenX = offsetx + xPos - 0.09 + relevateX(coords.x)
                    local screenY = offsety + yPos - 0.083 / 2 + 0.49 + 0.208 - relevateY(coords.y)
                    DrawSprite1("shared", "menuplus_32", screenX, screenY, 0.25, 0.25, 0, 255, 255, 255, 180)
                end
            end
        end
    end
    
    -- Draw selected player as red marker (overwrites white marker if same player)
    if playerCoords then
        -- C++: DrawSprite1("shared", "menuplus_32", offsetx + xPos - 0.09f + relevateX(playerSelected.x), offsety + yPos - 0.083f / 2 + 0.49f + 0.208f - relevateY(playerSelected.y), 0.25f, 0.25f, 0, 255, 0, 0, 255);
        local screenX = offsetx + xPos - 0.09 + relevateX(playerCoords.x)
        local screenY = offsety + yPos - 0.083 / 2 + 0.49 + 0.208 - relevateY(playerCoords.y)
        DrawSprite1("shared", "menuplus_32", screenX, screenY, 0.25, 0.25, 0, 255, 0, 0, 255)
    end
    
    -- Draw local player as red star
    if myCoords then
        -- C++: DrawSprite1("shared", "newstar_32", offsetx + xPos - 0.09f + relevateX(GetLocalPlayer().m_coordinates.x), offsety + yPos - 0.083f / 2 + 0.49f + 0.208f - relevateY(GetLocalPlayer().m_coordinates.y), 0.25f, 0.25f, 0, 255, 0, 0, 200);
        local screenX = offsetx + xPos - 0.09 + relevateX(myCoords.x)
        local screenY = offsety + yPos - 0.083 / 2 + 0.49 + 0.208 - relevateY(myCoords.y)
        DrawSprite1("shared", "newstar_32", screenX, screenY, 0.25, 0.25, 0, 255, 0, 0, 200)
    end
    
    -- ===== DRAW INFO ROWS (matching C++ render() order exactly) =====
    local weaponHash = WEAPON.GET_SELECTED_PED_WEAPON(ped)

    -- Row 0
    DrawInfo(0, half, 0, playerType, "", { dict = "commonmenu", name = "common_medal" }, typeColor)
    DrawMiddleLineTop(0)
    DrawMiddleLine(0)
    DrawInfo(half, half, 0, "Player id", tostring(playerId))
    
    -- Row 1
    DrawInfo(0, half, 1, "Health", GetEntityHealth(ped))
    DrawMiddleLine(1)
    DrawInfo(half, half, 1, "Rank", PlayerDataCache.GetRank(playerId))
    
    -- Row 2
    DrawInfo(0, half, 2, "Armor", tostring(armor))
    DrawMiddleLine(2)
    DrawInfo(half, half, 2, "Cash", "$0")  -- placeholder
    
    -- Row 3
    DrawInfo(0, half, 3, "Heading", GetPlayerHeading(ped))
    DrawMiddleLine(3)
    DrawMiddleLineBottom(3)
    DrawInfo(half, half, 3, "Bank", "$2147483647")  -- placeholder
    
    -- Row 4
    DrawInfo(0, half, 4, "Crew", "No")
    DrawMiddleLineTop(4)
    DrawMiddleLine(4)
    DrawInfo(half, half, 4, "K/D", "12.60")  -- placeholder
    
    -- Row 5
    DrawInfo(0, half, 5, "Ammo", GetAmmoInPlayerWeapon(ped, weaponHash))
    DrawMiddleLine(5)
    DrawInfo(half, half, 5, "Wanted level", string.format("%d/5", wanted))
    
    -- Row 6
    DrawInfo(0, half, 6, "Distance", string.format("%.3f", distance))
    DrawMiddleLine(6)
    DrawMiddleLineBottom(6)
    DrawInfo(half, half, 6, "Speed (KMH)", string.format("%.0f", speed))  -- C++ shows vehicle name
    
    -- Row 7
    DrawInfo(0, half, 7, "Zone", GetZoneName(playerCoords))
    DrawMiddleLineTop(7)
    DrawMiddleLine(7)
    DrawInfo(half, half, 7, "Street", GetPlayerStreetName(playerCoords))
    
    -- Row 8
    DrawInfo(0, whole, 8, "Weapon", GetPlayerWeaponName(weaponHash))
    DrawMiddleLine(8)
    
    -- Row 9
    DrawInfo(0, half, 9, "Vehicle & ID", GetVehicleName(ped))
    DrawMiddleLine(9)
    DrawMiddleLineBottom(9)
    DrawInfo(half, half, 9, "Seats", isInVehicle and "In vehicle" or "~c~Not in a vehicle~s~")

    
    -- Row 10
    DrawInfo(0, half, 10, "X", string.format("%.3f", playerCoords.x))
    DrawMiddleLineTop(10)
    DrawMiddleLine(10)
    DrawInfo(half, half, 10, "Modded model", moddedModel)
    
    -- Row 11
    DrawInfo(0, half, 11, "Y", string.format("%.3f", playerCoords.y))
    DrawMiddleLine(11)

    local ridText = "Unknown"
    if playerId == myId then
        ridText = "Hidden"
    elseif Settings.HidePlayerRIDs then
        ridText = "Streamer Mode"
    else
        local gamerInfo = Players.GetById(playerId):GetGamerInfo()
        if gamerInfo then
            ridText = tostring(gamerInfo.RockstarId)
        end
    end
    DrawInfo(half, half, 11, "R* ID", ridText)
    
    -- Row 12
    local ipText = "Unknown"
    local ipAddr = Players.GetIP(playerId)
    
    if playerId == myId then
        ipText = "Hidden"
    elseif Settings.HidePlayerIPs then
        ipText = "Streamer Mode"
    elseif ipAddr then
        ipText = ipAddr:ToString(false)
    end
    
    DrawInfo(0, half, 12, "Z", string.format("%.3f", playerCoords.z))
    DrawMiddleLine(12)
    DrawInfo(half, half, 12, "IP", ipText)
    
    -- Row 13
    DrawInfo(0, half, 13, "Godmode", isGodmode)
    DrawMiddleLine(13)
    DrawInfo(half, half, 13, "Vehicle godmode", "~c~Unknown~s~")
    
    -- Row 14
    DrawInfo(0, half, 14, "Off the radar", "No")
    DrawMiddleLine(14)
    DrawInfo(half, half, 14, "In interior", isInInterior)
    
    -- Row 15
    DrawInfo(0, half, 15, "Passive", PlayerDataCache.IsPassive(playerId) and "Yes" or "No")
    DrawMiddleLine(15)
    DrawInfo(half, half, 15, "Gender", isFemale and "Female" or "Male")
    
    -- Row 16
    DrawInfo(0, half, 16, "Invisible", isVisible and "No" or "Yes")
    DrawMiddleLine(16)
    DrawInfo(half, half, 16, "Voted for kick", "No")
    
    -- Row 17
    DrawInfo(0, half, 17, "Cutscene", inCutscene)
    DrawMiddleLine(17)
    DrawMiddleLineBottom(17)
    DrawInfo(half, half, 17, "Status", GetPlayerStance(ped))
end

return PlayerInfoComponent
