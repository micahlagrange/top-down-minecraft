local Controls = {}
Controls.__index = Controls

function Controls:new()
    local self = setmetatable({}, self)

    -- player movement keys
    self.move_up = { 'w', 'up' }
    self.move_left = { 'a', 'left' }
    self.move_down = { 's', 'down' }
    self.move_right = { 'd', 'right' }
    self.sprint_key = { 'lshift' }

    return self
end

function Controls:sprintButtonHeld()
    return love.keyboard.isDown(self.sprint_key)
end

function Controls:movementVector()
    -- return a vector that can be used by movemente logic
    local vector = { x = 0, y = 0 }
    if love.keyboard.isDown(self.move_up) then
        vector.y = vector.y - 1
    end
    if love.keyboard.isDown(self.move_down) then
        vector.y = vector.y + 1
    end
    if love.keyboard.isDown(self.move_right) then
        vector.x = vector.x + 1
    end
    if love.keyboard.isDown(self.move_left) then
        vector.x = vector.x - 1
    end

    local length = math.sqrt(vector.x * vector.x + vector.y * vector.y)
    if length > 0 then
        vector.x = vector.x / length
        vector.y = vector.y / length
    end
    return vector
end

return Controls
