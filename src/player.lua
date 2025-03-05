local world = require('src.world')

local Player = {}
Player.__index = Player

function Player:new(controller)
    local self = setmetatable({}, Player)
    self.controller = controller
    self.speed = 100
    self.sprintMultiplier = 2
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
    local multi = 1
    if self.controller:sprintButtonHeld() then
        multi = multi * self.sprintMultiplier
    end
    self.x = self.x + vector.x * self.speed * multi * dt
    self.y = self.y + vector.y * self.speed * multi * dt
    world:emitPlayerMoved(self:pos())
end

return Player
