local Util = require "src.util"
local Noise = {}
Noise.__index = Noise
local worley = require('src.worley')

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

function Noise:simplistic(x, y, scale, low, high)
    local noise = love.math.noise(x * scale, y * scale)
    noise = noise + love.math.noise(x * scale, y * scale)
    Util.normalize(noise, low, high)
    return noise - 1
end

function Noise:cmaherExample(octaves, x, y, lacunarity, persistence, scale, low, high)
    local max_amplitude = 0
    local amplitude = 1
    local frequency = scale
    local noise = 0

    for i = 1, octaves do
        if i == 2 or i == 4 or i == 8 or i == 15 or i == 30 or i == 48 or i == 80 then
            noise = noise + love.math.noise(x * scale, y * scale) * amplitude
            max_amplitude = max_amplitude + amplitude
            amplitude = amplitude * persistence
            frequency = frequency * lacunarity
        end
    end

    -- get average of the iterations
    noise = noise / max_amplitude

    -- normalize
    -- https://stats.stackexchange.com/questions/70801/how-to-normalize-data-to-0-1-range
    Util.normalize(noise, low, high)

    return noise
end

function Noise:worley()
    worley(x, y, z, #chunk)
end

return Noise
