local Noise = {}
Noise.__index = Noise

function Noise:new()
    local self = setmetatable({}, Noise)
    return self
end

function Noise:getTileFromNoise(x, y)
    -- supply a tile x-y position, get a 0 or 1 with perlin(ish) noise
    local n1 = x * (1 / 40)
    local n2 = y * (1 / 40)
    local noise = love.math.noise(n1, n2)
    -- noise: number from 0.0 to 1.0
    -- 0.0 - 0.2: water
    -- 0.2 - 0.4: grass
    -- 0.4 - 0.6: stone
    -- 0.6 - 0.8: snow
    if noise > 0 and noise < .09 then
        return TILE_WATER
    elseif noise > .09 and noise < .6 then
        return TILE_GRASS
    elseif noise > .6 and noise < .99 then
        return TILE_STONE
    elseif noise > .99 then
        return TILE_SNOW
    else
        print("wtf",  noise)
        return { 1, 0, 1 }
    end
end

return Noise
