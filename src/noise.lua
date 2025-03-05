local Util = require "src.util"
local Noise = {}
Noise.__index = Noise

function Noise:new()
    local self = setmetatable({}, Noise)
    return self
end

function Noise:getNoiseValue(x, y)
    local scale = .02
    local low = 0.0
    local high = 1.0
    local octaves = 10
    local wildness = 1
    local smoothity = .5
    return self:cmaherExample(octaves, x, y, wildness, smoothity, scale, low, high)
end

function Noise:cmaherExample(octaves, x, y, lacunarity, persistence, scale, low, high)
    local max_amplitude = 0
    local amplitude = 1
    local frequency = scale
    local noise = 0

    for i = 1, octaves do
        noise = noise + love.math.noise(x * scale, y * scale) * amplitude
        max_amplitude = max_amplitude + amplitude
        amplitude = amplitude * persistence
        frequency = frequency * lacunarity
    end

    -- get average of the iterations
    noise = noise / max_amplitude

    -- normalize
    -- https://stats.stackexchange.com/questions/70801/how-to-normalize-data-to-0-1-range
    Util.normalize(noise, low, high)

    return noise
end

return Noise
