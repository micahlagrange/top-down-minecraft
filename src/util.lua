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

return Util
