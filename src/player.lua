local world = require('src.world')

local Player = {}
Player.__index = Player

function Player:new(controller)
    local self = setmetatable({}, Player)
    self.controller = controller
    self.speed = 500
    self.velocity = { x = 0, y = 0 }
    self.width = 16
    self.height = 16
    return self
end

function Player:pos()
    return {
        x = self.x,
        y = self.y,
    }
end

function Player:draw()
    love.graphics.setColor(1, 0, 0, .8)
    love.graphics.rectangle("fill", self.x, self.y, world.tileSize, world.tileSize)
end

function Player:update(dt)
    local vector = self.controller:movementVector()
    if vector.x ~= 0 or vector.y ~= 0 then
        self:move(vector, dt)
    end
end

function Player:move(vector, dt)
    self.x = self.x + vector.x * self.speed * dt
    self.y = self.y + vector.y * self.speed * dt
    world:emitPlayerMoved(self:pos())
end

return Player
