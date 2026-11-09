-- The touch buttons, with a stand-in for love.*: a phone-sized screen, no
-- keys held, and the touches each test puts down.
local T = require('tst.check')

local W, H = 390, 760
local touches, keys, mouse = {}, {}, { down = false, x = 0, y = 0 }
unpack = unpack or table.unpack
love = {
    graphics = {
        getDimensions = function() return W, H end,
        getWidth = function() return W end,
    },
    keyboard = {
        isDown = function(...)
            for _, k in ipairs({ ... }) do if keys[k] then return true end end
            return false
        end,
    },
    touch = {
        getTouches = function()
            local ids = {}
            for id in pairs(touches) do ids[#ids + 1] = id end
            return ids
        end,
        getPosition = function(id) return touches[id][1], touches[id][2] end,
    },
    mouse = {
        isDown = function() return mouse.down end,
        getPosition = function() return mouse.x, mouse.y end,
    },
}

local Input = require('src.input')
local function toTile(x, y) return math.floor(x / 32), math.floor(y / 32) end

local function reset()
    touches, keys, mouse.down = {}, {}, false
    Input.stick, Input.eatQueued, Input.touchSeen = nil, false, false
end

local function press(id, x, y)
    touches[id] = { x, y }
    Input.touchpressed(id, x, y)
end

T.test('the EAT button sits above the MINE button, on screen, not overlapping', function()
    local bx, by, r = Input.button()
    local ex, ey, er = Input.eatButton()
    T.ok(ey < by, 'above')
    T.ok(ey - er > 0 and ex + er <= W, 'on screen')
    T.ok(by - ey > (r + er) * 1.2, 'touch areas do not overlap')
end)

T.test('tapping EAT eats once, not every frame it is held', function()
    reset()
    local ex, ey = Input.eatButton()
    press(1, ex, ey)
    local first = Input.read(toTile)
    T.ok(first.eat, 'eats on the tap')
    T.ok(not first.mine, 'does not mine')
    T.eq(first.tx, nil, 'does not aim at the tile under the button')
    T.ok(not Input.read(toTile).eat, 'holding does not eat again')
    T.eq(Input.stick, nil, 'no stick')
end)

T.test('holding MINE mines (and chops) the facing tile', function()
    reset()
    local bx, by = Input.button()
    press(1, bx, by)
    local i = Input.read(toTile)
    T.ok(i.mine)
    T.eq(i.tx, nil, 'facing tile, not an aimed one')
    T.ok(not i.eat)
end)

T.test('walking with the stick and eating at the same time', function()
    reset()
    press(1, 80, 600)
    touches[1] = { 140, 600 }
    local ex, ey = Input.eatButton()
    press(2, ex, ey)
    local i = Input.read(toTile)
    T.ok(i.dx > 0.5, 'walks right')
    T.ok(i.eat, 'eats')
end)

T.test('F or Q eats once per press', function()
    reset()
    Input.keypressed('f')
    T.ok(Input.read(toTile).eat)
    T.ok(not Input.read(toTile).eat)
    Input.keypressed('q')
    T.ok(Input.read(toTile).eat)
    Input.keypressed('x')
    T.ok(not Input.read(toTile).eat)
end)

T.test('clicking EAT with the mouse eats instead of mining there', function()
    reset()
    Input.touchSeen = true
    local ex, ey = Input.eatButton()
    Input.mousepressed(ex, ey, 1, false)
    mouse.down, mouse.x, mouse.y = true, ex, ey
    local i = Input.read(toTile)
    T.ok(i.eat)
    T.ok(not i.mine)
end)

T.done()
