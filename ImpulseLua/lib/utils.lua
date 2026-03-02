--[[
    Impulse Lua - Utils
    General utility functions
]]

local Utils = {}

--- Clamp a value between min and max
---@param val number Value to clamp
---@param min number Minimum value
---@param max number Maximum value
---@return number Clamped value
function Utils.Clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

--- Convert HSV to RGB
---@param h number Hue (0-360)
---@param s number Saturation (0-1)
---@param v number Value (0-1)
---@return table {r, g, b} (0-255)
function Utils.HSVToRGB(h, s, v)
    local r, g, b
    local i = math.floor(h / 60)
    local f = h / 60 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    i = i % 6

    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return {
        r = math.floor(r * 255),
        g = math.floor(g * 255),
        b = math.floor(b * 255)
    }
end

--- Convert RGB to HSV
---@param r number Red (0-255)
---@param g number Green (0-255)
---@param b number Blue (0-255)
---@return number, number, number (h, s, v)
function Utils.RGBToHSV(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v
    v = max

    local d = max - min
    if max == 0 then s = 0 else s = d / max end

    if max == min then
        h = 0 -- achromatic
    else
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h * 60
    end

    return h, s, v
end



return Utils
