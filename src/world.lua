-- The map: a fixed grid of tiles, the same every run. Pure Lua (no love.*),
-- so the tests can load it outside LÖVE.

local World = {}
World.__index = World

World.TILE = 16
World.WIDTH = 48
World.HEIGHT = 36
World.SEED = 20261108

-- Ground you walk on, and solid tiles you mine. `drop` is what mining gives,
-- `floor` what is left behind, `time` the seconds of mining it takes.
World.TYPES = {
    grass = { solid = false },
    stone = { solid = false },
    rock  = { solid = true, drop = 'stone', time = 0.6 },
    coal  = { solid = true, drop = 'coal', time = 0.8 },
    iron  = { solid = true, drop = 'iron', time = 1.1 },
    gold  = { solid = true, drop = 'gold', time = 1.4 },
    tree  = { solid = true, drop = 'wood', time = 1.0, floor = 'grass' },
}

World.MINERALS = { 'coal', 'iron', 'gold' }

-- About one grass tile in fifteen grows a tree; a chopped tree drops an apple
-- this often.
World.TREE_CHANCE = 0.065
World.APPLE_CHANCE = 0.4

-- A small deterministic generator (Park-Miller), so the map never depends on
-- the platform's math.random.
local function rng(seed)
    local state = seed % 2147483647
    if state <= 0 then state = state + 2147483646 end
    local r = {}
    function r.next()
        state = (state * 16807) % 2147483647
        return (state - 1) / 2147483646
    end
    function r.int(a, b)
        return a + math.floor(r.next() * (b - a + 1))
    end
    return r
end
World.rng = rng

local function pickMineral(r)
    local v = r.next()
    if v < 0.6 then return 'coal' elseif v < 0.9 then return 'iron' end
    return 'gold'
end

function World.new(seed)
    local self = setmetatable({}, World)
    self.seed = seed or World.SEED
    self.width, self.height = World.WIDTH, World.HEIGHT
    self.tiles = {}
    local r = rng(self.seed)
    local half = math.floor(self.width / 2)

    for x = 0, self.width - 1 do
        self.tiles[x] = {}
        for y = 0, self.height - 1 do
            self.tiles[x][y] = x < half and 'grass' or 'stone'
        end
    end

    -- Sparse minerals lying in the open stone half.
    for x = half + 1, self.width - 1 do
        for y = 0, self.height - 1 do
            if r.next() < 0.035 then self.tiles[x][y] = pickMineral(r) end
        end
    end

    -- The rock outcrop in the middle: about 10 wide, 5 to 10 tall, with
    -- ragged edges. Minerals are richer inside it.
    local h = r.int(5, 10)
    local cx, cy = half, math.floor(self.height / 2)
    local top = cy - math.floor(h / 2)
    self.rock = { top = top, height = h, left = cx, right = cx }
    for row = 0, h - 1 do
        local edge = (row == 0 or row == h - 1) and 2 or 0
        local w = r.int(9, 11) - edge
        local left = cx - math.floor(w / 2) + r.int(-1, 1)
        for x = left, left + w - 1 do
            self.tiles[x][top + row] = r.next() < 0.12 and pickMineral(r) or 'rock'
        end
        self.rock.left = math.min(self.rock.left, left)
        self.rock.right = math.max(self.rock.right, left + w - 1)
    end

    -- close enough that the rock is on screen from the start, even on a phone
    self.spawn = { x = self.rock.left - 4, y = cy }

    -- Trees on the grass, from their own generator so the rock and minerals
    -- above stay as they were. A clearing around the spawn keeps the walk to
    -- the rock open, and no tree touches the rock.
    local tr = rng(self.seed + 1)
    for x = 0, half - 1 do
        for y = 0, self.height - 1 do
            local clearing = x >= self.spawn.x - 3 and y >= cy - 2 and y <= cy + 2
            local nearRock = x >= self.rock.left - 1 and y >= top - 1 and y <= top + h
            local roll = tr.next()
            if self.tiles[x][y] == 'grass' and not clearing and not nearRock and roll < World.TREE_CHANCE then
                self.tiles[x][y] = 'tree'
            end
        end
    end
    self.drops = rng(self.seed + 2)
    return self
end

function World:inside(x, y)
    return x >= 0 and y >= 0 and x < self.width and y < self.height
end

function World:get(x, y)
    if not self:inside(x, y) then return nil end
    return self.tiles[x][y]
end

-- Outside the map counts as solid, so nobody walks off the edge.
function World:solid(x, y)
    local t = self:get(x, y)
    return t == nil or World.TYPES[t].solid
end

function World:mineable(x, y)
    local t = self:get(x, y)
    return t ~= nil and World.TYPES[t].drop ~= nil
end

function World:mineTime(x, y)
    local t = self:get(x, y)
    return t and World.TYPES[t].time
end

-- Mines a tile: it becomes its floor (stone, or grass under a tree). Returns
-- the drop and a bonus drop (an apple from a tree, sometimes), or nil.
function World:mine(x, y)
    if not self:mineable(x, y) then return nil end
    local kind = self.tiles[x][y]
    local type = World.TYPES[kind]
    self.tiles[x][y] = type.floor or 'stone'
    local bonus
    if kind == 'tree' and self.drops.next() < World.APPLE_CHANCE then bonus = 'apple' end
    return type.drop, bonus
end

function World:count(kind)
    local n = 0
    for x = 0, self.width - 1 do
        for y = 0, self.height - 1 do
            if self.tiles[x][y] == kind then n = n + 1 end
        end
    end
    return n
end

return World
