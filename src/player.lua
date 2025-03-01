local world = require('src.world')

local Player = {}
Player.__index = Player

function Player:new()
    local self = setmetatable({}, Player)
    self.x = DEFAULT_MAP_SIZE / 2
    self.y = DEFAULT_MAP_SIZE / 2
    self.speed = 1
    self.velocity = { x = 0, y = 0 }
    return self
end

function Player:update(dt)
    self.velocity.x = self.x + self.speed * dt
    self.velocity.y = self.y + self.speed * dt
end

function Player:move()
    if self.velocity.x > 0 or self.velocity.y > 0 then
        world:emitPlayerMoved({ x = self.x, y = self.y })
        self.x = self.x + self.velocity.x
        self.y = self.y + self.velocity.y
    end
end

return Player