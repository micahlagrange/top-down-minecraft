local T = require('tst.check')
local World = require('src.world')

T.test('the map is the same every run', function()
    local a, b = World.new(), World.new()
    for x = 0, World.WIDTH - 1 do
        for y = 0, World.HEIGHT - 1 do
            T.eq(a:get(x, y), b:get(x, y), 'tile ' .. x .. ',' .. y)
        end
    end
end)

T.test('left half is grass, right half stone, outside the rock', function()
    local w = World.new()
    local half = World.WIDTH / 2
    for x = 0, World.WIDTH - 1 do
        for y = 0, World.HEIGHT - 1 do
            local t = w:get(x, y)
            if not World.TYPES[t].solid then
                T.eq(t, x < half and 'grass' or 'stone', 'ground at ' .. x .. ',' .. y)
            end
        end
    end
end)

T.test('a rock outcrop about 10 wide and 5 to 10 tall sits in the middle', function()
    local w = World.new()
    local r = w.rock
    T.ok(r.height >= 5 and r.height <= 10, 'height ' .. r.height)
    local width = r.right - r.left + 1
    T.ok(width >= 8 and width <= 13, 'width ' .. width)
    T.ok(r.left < World.WIDTH / 2 and r.right >= World.WIDTH / 2, 'straddles the middle')
    local cy = math.floor(World.HEIGHT / 2)
    T.ok(r.top <= cy and r.top + r.height > cy, 'covers the middle row')
    T.ok(w:count('rock') >= 35, 'rock tiles ' .. w:count('rock'))
end)

T.test('minerals are sparse and only in the stone half or the rock', function()
    local w = World.new()
    local total = 0
    for _, m in ipairs(World.MINERALS) do total = total + w:count(m) end
    T.ok(total >= 10 and total <= 80, 'minerals ' .. total)
    for x = 0, World.WIDTH / 2 - 1 do
        for y = 0, World.HEIGHT - 1 do
            local t = w:get(x, y)
            local inRock = y >= w.rock.top and y < w.rock.top + w.rock.height and x >= w.rock.left
            T.ok(t == 'grass' or t == 'rock' or inRock, 'no minerals in the grass at ' .. x .. ',' .. y)
        end
    end
    T.ok(w:count('coal') > w:count('gold'), 'coal is commoner than gold')
end)

T.test('mining a block gives its drop and leaves stone floor', function()
    local w = World.new()
    local x, y = w.rock.left + 2, w.rock.top + 1
    w.tiles[x][y] = 'iron'
    T.ok(w:solid(x, y))
    T.eq(w:mine(x, y), 'iron')
    T.eq(w:get(x, y), 'stone')
    T.ok(not w:solid(x, y))
    T.eq(w:mine(x, y), nil, 'floor is not mineable')
end)

T.test('outside the map is solid', function()
    local w = World.new()
    T.ok(w:solid(-1, 0) and w:solid(0, -1) and w:solid(World.WIDTH, 0) and w:solid(0, World.HEIGHT))
end)

T.done()
