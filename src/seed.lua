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

function Seed:randomInt(min, max, chunk)
    return math.floor(love.math.random() * (max - min * 1) + min)
end

local instance = Seed:new()
return instance
