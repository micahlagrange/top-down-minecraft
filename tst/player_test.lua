local T = require('tst.check')
local World = require('src.world')
local Player = require('src.player')

local DT = 1 / 60

-- Walk right from the spawn until the rock stops the player.
local function walkToRock(w, p)
    for _ = 1, 60 * 8 do p:move(1, 0, DT) end
    return p
end

T.test('the player spawns on open grass', function()
    local w = World.new()
    local p = Player.new(w)
    local tx, ty = p:tile()
    T.eq(w:get(tx, ty), 'grass')
    T.ok(not p:blocked(p.x, p.y))
end)

T.test('the rock blocks walking', function()
    local w = World.new()
    local p = walkToRock(w, Player.new(w))
    local fx, fy = p:facingTile()
    T.ok(w:solid(fx, fy), 'stopped in front of a solid tile')
    T.ok(not p:blocked(p.x, p.y), 'never inside a block')
    T.ok(p.x < w.rock.right * World.TILE, 'did not pass the rock')
end)

T.test('the player slides along a wall instead of sticking', function()
    local w = World.new()
    local p = walkToRock(w, Player.new(w))
    local y0 = p.y
    for _ = 1, 30 do p:move(1, 1, DT) end
    T.ok(p.y > y0, 'moved down while pushing into the rock')
end)

T.test('the edge of the map blocks walking', function()
    local w = World.new()
    local p = Player.new(w)
    for _ = 1, 60 * 10 do p:move(-1, -1, DT) end
    T.ok(p.x >= 0 and p.y >= 0, 'stayed on the map')
end)

T.test('holding mine breaks the facing block after its mine time', function()
    local w = World.new()
    local p = walkToRock(w, Player.new(w))
    local fx, fy = p:facingTile()
    local kind = w:get(fx, fy)
    local time = World.TYPES[kind].time
    local drop
    local frames = 0
    repeat
        drop = p:mine(true, DT)
        frames = frames + 1
    until drop or frames > 600
    T.eq(drop, World.TYPES[kind].drop)
    T.ok(math.abs(frames * DT - time) < 2 * DT, 'took about ' .. time .. 's')
    T.eq(p.inventory[drop], 1)
    T.eq(w:get(fx, fy), 'stone')
end)

T.test('letting go resets the progress', function()
    local w = World.new()
    local p = walkToRock(w, Player.new(w))
    for _ = 1, 20 do p:mine(true, DT) end
    p:mine(false, DT)
    T.eq(p.mining, nil)
end)

T.test('a tile out of reach cannot be mined', function()
    local w = World.new()
    local p = Player.new(w)
    local drop
    for _ = 1, 300 do drop = drop or p:mine(true, DT, w.rock.left + 3, w.rock.top + 1) end
    T.eq(drop, nil)
end)

T.test('every mineral can be mined into the inventory', function()
    for _, kind in ipairs(World.MINERALS) do
        local w = World.new()
        local p = walkToRock(w, Player.new(w))
        local fx, fy = p:facingTile()
        w.tiles[fx][fy] = kind
        local drop
        for _ = 1, 200 do drop = drop or p:mine(true, DT) end
        T.eq(drop, kind)
        T.eq(p.inventory[kind], 1)
    end
end)

T.done()
