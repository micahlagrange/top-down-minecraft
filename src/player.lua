-- The player: walking with tile collision, facing, and mining. Pure Lua (no
-- love.*), so the tests can drive it.

local Player = {}
Player.__index = Player

Player.SIZE = 12
Player.SPEED = 80
Player.REACH = 1.6 -- tiles, from the player's centre to a tile's centre

-- Hunger runs from HUNGER_MAX (full) down to 0 at HUNGER_RATE a second, so a
-- full bar lasts about three minutes. An apple gives back APPLE_FOOD. At 0 the
-- player walks and mines at STARVING_PACE of the normal speed.
Player.HUNGER_MAX = 100
Player.HUNGER_RATE = 100 / 180
Player.APPLE_FOOD = 35
Player.STARVING_PACE = 0.5

function Player.new(world)
    local self = setmetatable({}, Player)
    local T = world.TILE
    self.world = world
    self.x = world.spawn.x * T + (T - Player.SIZE) / 2
    self.y = world.spawn.y * T + (T - Player.SIZE) / 2
    self.face = { x = 1, y = 0 }
    self.walking = false
    self.mining = nil -- { x, y, progress, time }
    self.inventory = { stone = 0, coal = 0, iron = 0, gold = 0, wood = 0, apple = 0 }
    self.hunger = Player.HUNGER_MAX
    return self
end

function Player:center()
    return self.x + Player.SIZE / 2, self.y + Player.SIZE / 2
end

function Player:tile()
    local cx, cy = self:center()
    local T = self.world.TILE
    return math.floor(cx / T), math.floor(cy / T)
end

-- True when the player's box at (x, y) overlaps a solid tile.
function Player:blocked(x, y)
    local T, s = self.world.TILE, Player.SIZE
    local x0, x1 = math.floor(x / T), math.floor((x + s - 0.001) / T)
    local y0, y1 = math.floor(y / T), math.floor((y + s - 0.001) / T)
    for tx = x0, x1 do
        for ty = y0, y1 do
            if self.world:solid(tx, ty) then return true end
        end
    end
    return false
end

-- Move by a direction vector (any length up to 1) for dt seconds; each axis
-- is tried on its own, so the player slides along walls.
function Player:move(dx, dy, dt)
    local len = math.sqrt(dx * dx + dy * dy)
    self.walking = len > 0.1
    if not self.walking then return end
    if len > 1 then dx, dy = dx / len, dy / len end
    if math.abs(dx) >= math.abs(dy) then
        self.face = { x = dx > 0 and 1 or -1, y = 0 }
    else
        self.face = { x = 0, y = dy > 0 and 1 or -1 }
    end
    local step = Player.SPEED * self:pace() * dt
    local nx = self.x + dx * step
    if not self:blocked(nx, self.y) then self.x = nx end
    local ny = self.y + dy * step
    if not self:blocked(self.x, ny) then self.y = ny end
end

function Player:inReach(tx, ty)
    local cx, cy = self:center()
    local T = self.world.TILE
    local ddx, ddy = (tx + 0.5) - cx / T, (ty + 0.5) - cy / T
    return math.sqrt(ddx * ddx + ddy * ddy) <= Player.REACH
end

-- The tile mining aims at: the one in front of the player.
function Player:facingTile()
    local tx, ty = self:tile()
    return tx + self.face.x, ty + self.face.y
end

-- Hold to mine (tx, ty) (default: the facing tile). Returns the drop when the
-- tile breaks, or nil. Letting go, or aiming elsewhere, resets the progress.
function Player:mine(held, dt, tx, ty)
    if not held then self.mining = nil; return nil end
    if not tx then tx, ty = self:facingTile() end
    if not self.world:mineable(tx, ty) or not self:inReach(tx, ty) then
        self.mining = nil
        return nil
    end
    local m = self.mining
    if not m or m.x ~= tx or m.y ~= ty then
        m = { x = tx, y = ty, progress = 0, time = self.world:mineTime(tx, ty) }
        self.mining = m
    end
    m.progress = m.progress + dt * self:pace()
    if m.progress < m.time then return nil end
    self.mining = nil
    local drop, bonus = self.world:mine(tx, ty)
    self.inventory[drop] = self.inventory[drop] + 1
    if bonus then self.inventory[bonus] = self.inventory[bonus] + 1 end
    return drop, tx, ty, bonus
end

function Player:starving()
    return self.hunger <= 0
end

-- 1 normally, STARVING_PACE once hunger is empty.
function Player:pace()
    return self:starving() and Player.STARVING_PACE or 1
end

-- Hunger drains with time.
function Player:update(dt)
    self.hunger = math.max(0, self.hunger - Player.HUNGER_RATE * dt)
end

-- Eats an apple when there is one and the bar is not full. Returns true when
-- it ate.
function Player:eat()
    if self.inventory.apple < 1 or self.hunger >= Player.HUNGER_MAX then return false end
    self.inventory.apple = self.inventory.apple - 1
    self.hunger = math.min(Player.HUNGER_MAX, self.hunger + Player.APPLE_FOOD)
    return true
end

return Player
