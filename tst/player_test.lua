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

-- Puts a tree right in front of a player standing at the spawn, facing right.
local function treeInFront(w, p)
    p:move(1, 0, DT)
    local fx, fy = p:facingTile()
    w.tiles[fx][fy] = 'tree'
    return fx, fy
end

T.test('a tree blocks walking', function()
    local w = World.new()
    local p = Player.new(w)
    local fx = treeInFront(w, p)
    for _ = 1, 120 do p:move(1, 0, DT) end
    T.ok(p.x + Player.SIZE <= fx * World.TILE + 0.01, 'stopped before the tree')
end)

T.test('holding mine on a tree chops it into wood', function()
    local w = World.new()
    local p = Player.new(w)
    local fx, fy = treeInFront(w, p)
    local drop, frames = nil, 0
    repeat
        drop = p:mine(true, DT)
        frames = frames + 1
    until drop or frames > 600
    T.eq(drop, 'wood')
    T.ok(math.abs(frames * DT - World.TYPES.tree.time) < 2 * DT, 'took about ' .. World.TYPES.tree.time .. 's')
    T.eq(p.inventory.wood, 1)
    T.eq(w:get(fx, fy), 'grass')
end)

T.test('chopping trees puts their apples in the inventory', function()
    local w = World.new()
    local p = Player.new(w)
    local apples, chops = 0, 0
    for _ = 1, 20 do
        treeInFront(w, p)
        local drop, bonus
        for _ = 1, 200 do
            local d, _, _, b = p:mine(true, DT)
            drop, bonus = drop or d, bonus or b
        end
        T.eq(drop, 'wood')
        chops = chops + 1
        if bonus then apples = apples + 1 end
    end
    T.eq(p.inventory.wood, chops)
    T.eq(p.inventory.apple, apples)
    T.ok(apples >= 2 and apples <= 16, 'apples ' .. apples .. ' of ' .. chops)
end)

T.test('hunger starts full and drains over time', function()
    local w = World.new()
    local p = Player.new(w)
    T.eq(p.hunger, Player.HUNGER_MAX)
    for _ = 1, 60 * 10 do p:update(DT) end
    local expect = Player.HUNGER_MAX - Player.HUNGER_RATE * 10
    T.ok(math.abs(p.hunger - expect) < 0.01, 'hunger ' .. p.hunger .. ', expected ' .. expect)
    for _ = 1, 60 * 400 do p:update(DT) end
    T.eq(p.hunger, 0, 'never below zero')
    T.ok(p:starving())
end)

T.test('eating an apple refills hunger and uses the apple', function()
    local w = World.new()
    local p = Player.new(w)
    p.hunger = 20
    p.inventory.apple = 2
    T.ok(p:eat())
    T.eq(p.hunger, 20 + Player.APPLE_FOOD)
    T.eq(p.inventory.apple, 1)
end)

T.test('eating never goes above full, and a full player keeps the apple', function()
    local w = World.new()
    local p = Player.new(w)
    p.inventory.apple = 1
    T.ok(not p:eat(), 'full: does not eat')
    T.eq(p.inventory.apple, 1)
    p.hunger = Player.HUNGER_MAX - 5
    T.ok(p:eat())
    T.eq(p.hunger, Player.HUNGER_MAX)
end)

T.test('with no apples, eating does nothing', function()
    local w = World.new()
    local p = Player.new(w)
    p.hunger = 10
    T.ok(not p:eat())
    T.eq(p.hunger, 10)
end)

T.test('at empty hunger the player walks and mines slower', function()
    local w = World.new()
    local fed, starved = Player.new(w), Player.new(w)
    starved.hunger = 0
    local x0 = fed.x
    for _ = 1, 30 do fed:move(1, 0, DT); starved:move(1, 0, DT) end
    local fedDist, starvedDist = fed.x - x0, starved.x - x0
    T.ok(math.abs(starvedDist - fedDist * Player.STARVING_PACE) < 0.01, 'walked ' .. starvedDist .. ' vs ' .. fedDist)

    local w2 = World.new()
    local p = walkToRock(w2, Player.new(w2))
    p.hunger = 0
    local fx, fy = p:facingTile()
    w2.tiles[fx][fy] = 'rock'
    local frames, drop = 0, nil
    repeat
        drop = p:mine(true, DT)
        frames = frames + 1
    until drop or frames > 600
    local slow = World.TYPES.rock.time / Player.STARVING_PACE
    T.ok(math.abs(frames * DT - slow) < 2 * DT, 'mined in ' .. frames * DT .. 's, expected ' .. slow)
end)

T.test('eating while starving brings back full speed', function()
    local w = World.new()
    local p = Player.new(w)
    p.hunger = 0
    p.inventory.apple = 1
    T.eq(p:pace(), Player.STARVING_PACE)
    T.ok(p:eat())
    T.eq(p:pace(), 1)
end)

T.done()
