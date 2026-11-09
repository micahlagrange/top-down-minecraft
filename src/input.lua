-- Keyboard, mouse and touch, read once a frame into one intent:
--   { dx, dy, mine, tx, ty, eat }  (tx, ty: an aimed tile, else mine the
--   facing one; eat: true on the one frame after F or the EAT button)
--
-- Touch: a stick anywhere on the left half of the screen, a MINE button at
-- bottom right (it chops trees too), an EAT button above it, and a touch on
-- the right half aims at that tile and mines or chops it.

local Input = {}

Input.touchSeen = false
Input.stick = nil -- { id, ox, oy, x, y } while a finger drives the stick
Input.eatQueued = false

local KEYS = {
    up = { 'w', 'up' }, down = { 's', 'down' },
    left = { 'a', 'left' }, right = { 'd', 'right' },
    mine = { 'space', 'e', 'return' },
    eat = { 'f', 'q' },
}

local function down(list) return love.keyboard.isDown(unpack(list)) end

-- The MINE button: centre and radius for the current window size.
function Input.button()
    local w, h = love.graphics.getDimensions()
    local r = math.max(36, math.min(w, h) * 0.09)
    return w - r * 1.4, h - r * 1.4, r
end

-- The EAT button: smaller, above the MINE button.
function Input.eatButton()
    local bx, by, r = Input.button()
    local er = r * 0.75
    return bx, by - r * 1.25 - er * 1.25, er
end

function Input.stickRadius()
    local w, h = love.graphics.getDimensions()
    return math.max(40, math.min(w, h) * 0.1)
end

local function onButton(x, y)
    local bx, by, r = Input.button()
    return (x - bx) ^ 2 + (y - by) ^ 2 <= (r * 1.2) ^ 2
end

local function onEat(x, y)
    local bx, by, r = Input.eatButton()
    return (x - bx) ^ 2 + (y - by) ^ 2 <= (r * 1.2) ^ 2
end

-- toTile(sx, sy) -> tx, ty converts a screen point to a map tile.
function Input.read(toTile)
    local i = { dx = 0, dy = 0, mine = false, eat = Input.eatQueued }
    Input.eatQueued = false
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
        elseif onEat(x, y) then
            -- tapped in touchpressed; holding it does nothing more
        elseif x >= w / 2 then
            i.mine = true
            i.tx, i.ty = toTile(x, y)
        end
    end
    if not stickAlive then Input.stick = nil end

    if #touches == 0 and love.mouse.isDown(1) then
        local mx, my = love.mouse.getPosition()
        if not (Input.touchSeen and onEat(mx, my)) then
            i.mine = true
            i.tx, i.ty = toTile(mx, my)
        end
    end
    return i
end

function Input.touchpressed(id, x, y)
    Input.touchSeen = true
    if onEat(x, y) then
        Input.eatQueued = true
    elseif not Input.stick and x < love.graphics.getWidth() / 2 and not onButton(x, y) then
        Input.stick = { id = id, ox = x, oy = y, x = x, y = y }
    end
end

function Input.keypressed(key)
    for _, k in ipairs(KEYS.eat) do
        if key == k then Input.eatQueued = true end
    end
end

-- A mouse click on the EAT button, once the touch buttons are showing.
function Input.mousepressed(x, y, button, istouch)
    if button == 1 and not istouch and Input.touchSeen and onEat(x, y) then Input.eatQueued = true end
end

local function drawButton(bx, by, r, label, lit)
    love.graphics.setColor(1, 1, 1, lit and 0.18 or 0.08)
    love.graphics.circle('fill', bx, by, r)
    love.graphics.setColor(1, 1, 1, lit and 0.6 or 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.circle('line', bx, by, r)
    local font = love.graphics.getFont()
    love.graphics.print(label, bx - font:getWidth(label) / 2, by - font:getHeight() / 2)
end

-- mineLabel: 'MINE' or 'CHOP'; canEat: there is an apple to eat.
function Input.draw(mineLabel, canEat)
    if not Input.touchSeen then return end
    local bx, by, r = Input.button()
    drawButton(bx, by, r, mineLabel or 'MINE', true)
    local ex, ey, er = Input.eatButton()
    drawButton(ex, ey, er, 'EAT', canEat)
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
