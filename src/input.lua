-- Keyboard, mouse and touch, read once a frame into one intent:
--   { dx, dy, mine, tx, ty }  (tx, ty: an aimed tile, else mine the facing one)
--
-- Touch: a stick anywhere on the left half of the screen, a MINE button at
-- bottom right, and a touch on the right half aims at that tile and mines it.

local Input = {}

Input.touchSeen = false
Input.stick = nil -- { id, ox, oy, x, y } while a finger drives the stick

local KEYS = {
    up = { 'w', 'up' }, down = { 's', 'down' },
    left = { 'a', 'left' }, right = { 'd', 'right' },
    mine = { 'space', 'e', 'return' },
}

local function down(list) return love.keyboard.isDown(unpack(list)) end

-- The MINE button: centre and radius for the current window size.
function Input.button()
    local w, h = love.graphics.getDimensions()
    local r = math.max(36, math.min(w, h) * 0.09)
    return w - r * 1.4, h - r * 1.4, r
end

function Input.stickRadius()
    local w, h = love.graphics.getDimensions()
    return math.max(40, math.min(w, h) * 0.1)
end

local function onButton(x, y)
    local bx, by, r = Input.button()
    return (x - bx) ^ 2 + (y - by) ^ 2 <= (r * 1.2) ^ 2
end

-- toTile(sx, sy) -> tx, ty converts a screen point to a map tile.
function Input.read(toTile)
    local i = { dx = 0, dy = 0, mine = false }
    if down(KEYS.left) then i.dx = i.dx - 1 end
    if down(KEYS.right) then i.dx = i.dx + 1 end
    if down(KEYS.up) then i.dy = i.dy - 1 end
    if down(KEYS.down) then i.dy = i.dy + 1 end
    if down(KEYS.mine) then i.mine = true end

    local w = love.graphics.getWidth()
    local touches = love.touch.getTouches()
    local stickAlive = false
    for _, id in ipairs(touches) do
        local x, y = love.touch.getPosition(id)
        if Input.stick and Input.stick.id == id then
            stickAlive = true
            Input.stick.x, Input.stick.y = x, y
            local r = Input.stickRadius()
            local sx, sy = (x - Input.stick.ox) / r, (y - Input.stick.oy) / r
            local len = math.sqrt(sx * sx + sy * sy)
            if len > 1 then sx, sy = sx / len, sy / len end
            i.dx, i.dy = sx, sy
        elseif onButton(x, y) then
            i.mine = true
        elseif x >= w / 2 then
            i.mine = true
            i.tx, i.ty = toTile(x, y)
        end
    end
    if not stickAlive then Input.stick = nil end

    if #touches == 0 and love.mouse.isDown(1) then
        i.mine = true
        i.tx, i.ty = toTile(love.mouse.getPosition())
    end
    return i
end

function Input.touchpressed(id, x, y)
    Input.touchSeen = true
    if not Input.stick and x < love.graphics.getWidth() / 2 and not onButton(x, y) then
        Input.stick = { id = id, ox = x, oy = y, x = x, y = y }
    end
end

function Input.draw()
    if not Input.touchSeen then return end
    local bx, by, r = Input.button()
    love.graphics.setColor(1, 1, 1, 0.18)
    love.graphics.circle('fill', bx, by, r)
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.circle('line', bx, by, r)
    local font = love.graphics.getFont()
    love.graphics.print('MINE', bx - font:getWidth('MINE') / 2, by - font:getHeight() / 2)
    local s = Input.stick
    if s then
        local sr = Input.stickRadius()
        love.graphics.setColor(1, 1, 1, 0.15)
        love.graphics.circle('fill', s.ox, s.oy, sr)
        love.graphics.setColor(1, 1, 1, 0.5)
        local kx, ky = s.x - s.ox, s.y - s.oy
        local len = math.sqrt(kx * kx + ky * ky)
        if len > sr then kx, ky = kx / len * sr, ky / len * sr end
        love.graphics.circle('fill', s.ox + kx, s.oy + ky, sr * 0.45)
    end
end

return Input
