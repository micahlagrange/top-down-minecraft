local Seed = {}
Seed.__index = Seed

function Seed:new(seed)
    local self = setmetatable({}, Seed)
    if seed then
        self.seed = seed
    else
        self.seed = DEFAULT_SEED
    end
    return self
end

function Seed:randomInt(min, max)
    return math.floor(love.math.random() * (max - min) + min)
end

function Seed:generateChunkSeed(chunk)
    local prime_x = 17
    local prime_y = 29
    return self.seed + (chunk.x * prime_x) + (chunk.y * prime_y)
end

local instance = Seed:new()
return instance
