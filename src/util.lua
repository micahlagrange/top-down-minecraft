local Util = {}
Util.__index = Util

function Util.noiseRange(noise, range)
    local min = range[1]
    local max = range[2]
    return noise >= min and noise < max
end

function Util.normalize(value, min, max)
    return (value - min) / (max - min)
end

function Util.multiplyColorVector(rgb, vec)
    if not vec then return rgb end
    return { rgb[1] * vec[1], rgb[2] * vec[2], rgb[3] * vec[3] }
end

function Util.dimColor(rgb, val)
    if not val then return rgb end
    return {
        rgb[1] * val,
        rgb[2] * val,
        rgb[3] * val
    }
end

function Util.addColorVector(rgb, vec)
    if not vec then return rgb end
    return { rgb[1] + vec[1], rgb[2] + vec[2], rgb[3] + vec[3] }
end

function Util.subColorVector(rgb, vec)
    if not vec then return rgb end
    return { rgb[1] - vec[1], rgb[2] - vec[2], rgb[3] - vec[3] }
end

function Util.dimColorByValue(rgb, vec)
    -- vec is assumed to be {0-1, 0-1, 0-1}, subtract from rgb by the amount dimmer than 1 vec is
    -- assume rgb is the brightest possible version of that color, and normalize on 0-n
    local r = 1 - rgb[1]
    local vr = vec[1] * (r - 0) / 2 + (r + 0) / 2
    local g = 1 - rgb[2]
    local vg = vec[2] * (g - 0) / 2 + (g + 0) / 2
    local b = 1 - rgb[3]
    local vb = vec[3] * (b - 0) / 2 + (b + 0) / 2
    return { vr + r, vg + r, vb + r }
end

function Util.print(arg)
    if type(arg) == 'table' then
        print(Util.serializeTable(arg))
    end
end

function Util.serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if name then tmp = tmp .. name .. " = " end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp = tmp .. Util.serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end

function Util.y_tile_overlap(char, tile, tileSize)
    return char.y < tile.y + tileSize or char.y + char.height > tile.y
end

function Util.x_tile_overlap(char, tile, tileSize)
    return char.x < tile.x + tileSize or char.x + char.width > tile.x
end

return Util
