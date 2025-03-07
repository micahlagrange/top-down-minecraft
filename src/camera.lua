local Camera = {}
Camera.__index = Camera

function Camera:new()
    local self = setmetatable({}, Camera)
    self.x = 0
    self.y = 0
    self.scale = 1.5
    return self
end

function Camera:update(dt, target)
    self.x = self.x + (target.x - self.x - (WINDOW_WIDTH / 2) / self.scale) * dt
    self.y = self.y + (target.y - self.y - (WINDOW_HEIGHT / 2) / self.scale) * dt
end

function Camera:draw()
    love.graphics.push()
    love.graphics.scale(self.scale)
    love.graphics.translate(-self.x, -self.y)
end

function Camera:zoom(int)
    print(int)
    if int > 0 then
        self.scale = self.scale + .03
    elseif int < 0 then
        self.scale = self.scale - .03
    end
end

function Camera:pop()
    love.graphics.pop()
end

return Camera
