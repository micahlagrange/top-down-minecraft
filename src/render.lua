-- Drawing: the camera, the map (cached in a canvas, redrawn when a tile
-- changes), particles, the player and the HUD.

local World = require('src.world')

local Render = {}

local T = World.TILE
local COLORS = {
    grass = { 0.36, 0.62, 0.28 },
    stone = { 0.53, 0.53, 0.56 },
    rock  = { 0.37, 0.35, 0.40 },
    coal  = { 0.12, 0.12, 0.14 },
    iron  = { 0.86, 0.62, 0.45 },
    gold  = { 1.00, 0.83, 0.22 },
}
Render.COLORS = COLORS

local mapCanvas, dirty = nil, true
local particles = {}
local cam = { x = 0, y = 0, scale = 2 }
local fonts = {}

-- A stable per-tile number in [0, 1), so the texture never flickers.
local function hash(x, y, k)
    local v = math.sin(x * 12.9898 + y * 78.233 + (k or 0) * 37.719) * 43758.5453
    return v - math.floor(v)
end

local function shade(c, d)
    return c[1] + d, c[2] + d, c[3] + d
end

local function drawGround(kind, px, py, x, y)
    local c = COLORS[kind]
    love.graphics.setColor(c)
    love.graphics.rectangle('fill', px, py, T, T)
    if kind == 'grass' then
        love.graphics.setColor(shade(c, -0.09))
        for k = 1, 3 do
            local gx, gy = px + 2 + hash(x, y, k) * 11, py + 3 + hash(x, y, k + 9) * 10
            love.graphics.rectangle('fill', gx, gy, 1, 2)
            love.graphics.rectangle('fill', gx + 2, gy + 1, 1, 2)
        end
    else
        love.graphics.setColor(shade(c, -0.07))
        for k = 1, 4 do
            love.graphics.rectangle('fill', px + 1 + hash(x, y, k) * 13, py + 1 + hash(x, y, k + 5) * 13, 2, 1)
        end
    end
end

-- A block's edges are lit or shaded only where it meets open ground, so the
-- outcrop reads as one mass instead of a stack of bricks.
local function drawBlock(world, kind, px, py, x, y)
    local c = COLORS.rock
    love.graphics.setColor(c)
    love.graphics.rectangle('fill', px, py, T, T)
    love.graphics.setColor(shade(c, -0.05))
    for k = 1, 2 do
        local sx, sy = px + 2 + hash(x, y, k) * 10, py + 3 + hash(x, y, k + 7) * 10
        love.graphics.rectangle('fill', sx, sy, 3, 1)
    end
    if not world:solid(x, y - 1) then
        love.graphics.setColor(shade(c, 0.13))
        love.graphics.rectangle('fill', px, py, T, 3)
    end
    if not world:solid(x, y + 1) then
        love.graphics.setColor(shade(c, -0.12))
        love.graphics.rectangle('fill', px, py + T - 4, T, 4)
    end
    if not world:solid(x - 1, y) then
        love.graphics.setColor(shade(c, 0.06))
        love.graphics.rectangle('fill', px, py, 2, T)
    end
    if not world:solid(x + 1, y) then
        love.graphics.setColor(shade(c, -0.07))
        love.graphics.rectangle('fill', px + T - 2, py, 2, T)
    end
    if kind ~= 'rock' then
        local o = COLORS[kind]
        local spots = { { 3, 4 }, { 9, 3 }, { 6, 8 }, { 11, 9 }, { 3, 11 } }
        for k, s in ipairs(spots) do
            local ox, oy = px + s[1] + math.floor(hash(x, y, k) * 2), py + s[2] + math.floor(hash(x, y, k + 3) * 2)
            love.graphics.setColor(o[1] * 0.6, o[2] * 0.6, o[3] * 0.6)
            love.graphics.rectangle('fill', ox, oy + 1, 3, 3)
            love.graphics.setColor(o)
            love.graphics.rectangle('fill', ox, oy, 3, 2)
            love.graphics.setColor(1, 1, 1, kind == 'coal' and 0.15 or 0.5)
            love.graphics.rectangle('fill', ox, oy, 1, 1)
        end
    end
end

local function paintMap(world)
    if not mapCanvas then
        mapCanvas = love.graphics.newCanvas(world.width * T, world.height * T)
        mapCanvas:setFilter('nearest', 'nearest')
    end
    love.graphics.setCanvas(mapCanvas)
    love.graphics.clear(0, 0, 0, 1)
    for x = 0, world.width - 1 do
        for y = 0, world.height - 1 do
            local kind = world.tiles[x][y]
            if World.TYPES[kind].solid then
                drawBlock(world, kind, x * T, y * T, x, y)
            else
                drawGround(kind, x * T, y * T, x, y)
                -- a soft shadow under a block that sits above open ground
                if y > 0 and World.TYPES[world.tiles[x][y - 1]].solid then
                    love.graphics.setColor(0, 0, 0, 0.22)
                    love.graphics.rectangle('fill', x * T, y * T, T, 4)
                end
            end
        end
    end
    love.graphics.setCanvas()
    dirty = false
end

function Render.invalidate() dirty = true end

function Render.font(size)
    if not fonts[size] then fonts[size] = love.graphics.newFont(size) end
    return fonts[size]
end

function Render.updateCamera(world, player, dt)
    local w, h = love.graphics.getDimensions()
    cam.scale = math.max(2, math.min(w / (T * 20), h / (T * 14)))
    local vw, vh = w / cam.scale, h / cam.scale
    local px, py = player:center()
    local tx, ty = px - vw / 2, py - vh / 2
    local mw, mh = world.width * T, world.height * T
    tx = vw >= mw and (mw - vw) / 2 or math.max(0, math.min(tx, mw - vw))
    ty = vh >= mh and (mh - vh) / 2 or math.max(0, math.min(ty, mh - vh))
    local k = dt and math.min(1, dt * 8) or 1
    cam.x = cam.x + (tx - cam.x) * k
    cam.y = cam.y + (ty - cam.y) * k
end

function Render.screenToTile(sx, sy)
    return math.floor((sx / cam.scale + cam.x) / T), math.floor((sy / cam.scale + cam.y) / T)
end

function Render.burst(tx, ty, kind)
    local base = COLORS[kind] or COLORS.rock
    for k = 1, 14 do
        local a = hash(tx, ty, k + #particles) * math.pi * 2
        local sp = 30 + hash(ty, tx, k) * 60
        local c = (k % 3 == 0) and COLORS.rock or base
        particles[#particles + 1] = {
            x = (tx + 0.5) * T, y = (ty + 0.5) * T,
            vx = math.cos(a) * sp, vy = math.sin(a) * sp - 20,
            life = 0.45 + hash(tx, k, ty) * 0.3, color = c,
        }
    end
end

function Render.updateParticles(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        else
            p.x, p.y = p.x + p.vx * dt, p.y + p.vy * dt
            p.vy = p.vy + 160 * dt
            p.vx = p.vx * (1 - 3 * dt)
        end
    end
end

local function drawPlayer(player, t)
    local x, y = player.x, player.y
    local s = player.SIZE
    local bob = player.walking and math.floor(math.sin(t * 14) * 1 + 0.5) or 0
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.ellipse('fill', x + s / 2, y + s, s / 2, 2)
    love.graphics.setColor(0.2, 0.32, 0.62)
    love.graphics.rectangle('fill', x, y + 3 + bob, s, s - 3, 3, 3)
    love.graphics.setColor(0.98, 0.8, 0.62)
    love.graphics.rectangle('fill', x + 2, y + bob, s - 4, 7, 2, 2)
    love.graphics.setColor(0.95, 0.7, 0.15)
    love.graphics.rectangle('fill', x + 1, y - 1 + bob, s - 2, 3, 1, 1)
    -- the eyes and the pick follow the facing direction
    local fx, fy = player.face.x, player.face.y
    love.graphics.setColor(0.1, 0.1, 0.15)
    if fy >= 0 then
        love.graphics.rectangle('fill', x + 4 + fx * 2, y + 3 + bob, 1, 2)
        love.graphics.rectangle('fill', x + 7 + fx * 2, y + 3 + bob, 1, 2)
    end
    local swing = player.mining and math.sin(t * 22) * 3 or 0
    local hx, hy = x + s / 2 + fx * (s / 2 + 2), y + s / 2 + fy * (s / 2 + 2) + bob
    love.graphics.setColor(0.55, 0.38, 0.22)
    love.graphics.setLineWidth(2)
    love.graphics.line(x + s / 2, y + s / 2 + bob, hx + fy * swing, hy + fx * swing)
    love.graphics.setColor(0.8, 0.82, 0.86)
    love.graphics.rectangle('fill', hx + fy * swing - 2, hy + fx * swing - 2, 4, 4)
end

local function drawCracks(m)
    local f = math.min(1, m.progress / m.time)
    local px, py = m.x * T, m.y * T
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.setLineWidth(1)
    local n = math.floor(f * 6) + 1
    for k = 1, n do
        local ax, ay = px + hash(m.x, m.y, k) * T, py + hash(m.y, m.x, k) * T
        local bx, by = px + T / 2, py + T / 2
        love.graphics.line(ax, ay, bx + (ax - bx) * 0.3, by + (ay - by) * 0.3)
    end
end

function Render.draw(world, player, target, t)
    if dirty then paintMap(world) end
    love.graphics.clear(0.08, 0.08, 0.1)
    love.graphics.push()
    love.graphics.scale(cam.scale)
    love.graphics.translate(-math.floor(cam.x * cam.scale) / cam.scale, -math.floor(cam.y * cam.scale) / cam.scale)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(mapCanvas, 0, 0)

    if target and world:mineable(target.x, target.y) and player:inReach(target.x, target.y) then
        love.graphics.setColor(1, 1, 1, 0.55 + 0.25 * math.sin(t * 6))
        love.graphics.setLineWidth(1)
        love.graphics.rectangle('line', target.x * T + 0.5, target.y * T + 0.5, T - 1, T - 1)
    end
    if player.mining then drawCracks(player.mining) end

    drawPlayer(player, t)

    for _, p in ipairs(particles) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], math.min(1, p.life * 3))
        love.graphics.rectangle('fill', p.x - 1, p.y - 1, 2, 2)
    end
    love.graphics.pop()
end

-- The night: a dark blue layer over the map with a soft hole of light around
-- the player, painted into its own screen-sized canvas each frame.
local NIGHT = { 0.03, 0.04, 0.12 }
local LIGHT_RINGS = 64
local nightCanvas

function Render.night(dayNight, player)
    local alpha = dayNight:overlayAlpha()
    if alpha <= 0.002 then return end
    local w, h = love.graphics.getDimensions()
    if not nightCanvas or nightCanvas:getWidth() ~= w or nightCanvas:getHeight() ~= h then
        -- rgba8: love.js can default to a 16-bit canvas, which bands the light
        local settings = love.graphics.getCanvasFormats().rgba8 and { format = 'rgba8' } or nil
        nightCanvas = love.graphics.newCanvas(w, h, settings)
    end
    local px, py = player:center()
    local sx = (px - math.floor(cam.x * cam.scale) / cam.scale) * cam.scale
    local sy = (py - math.floor(cam.y * cam.scale) / cam.scale) * cam.scale
    local radius = dayNight.LIGHT_RADIUS * T * cam.scale

    love.graphics.setCanvas(nightCanvas)
    -- The canvas holds premultiplied colour: 'replace' (with the default
    -- alphamultiply) stores rgb * a, so the clear does the same, and the
    -- canvas is drawn in premultiplied mode. 'replace' writes each ring's
    -- alpha as is, so the light cuts through the dark instead of adding to
    -- it; outer rings first, inner on top.
    love.graphics.clear(NIGHT[1] * alpha, NIGHT[2] * alpha, NIGHT[3] * alpha, alpha)
    love.graphics.setBlendMode('replace')
    for k = LIGHT_RINGS, 1, -1 do
        local d = k / LIGHT_RINGS
        love.graphics.setColor(NIGHT[1], NIGHT[2], NIGHT[3], dayNight.lightAlpha(d - 0.5 / LIGHT_RINGS, alpha))
        love.graphics.circle('fill', sx, sy, radius * d, 64)
    end
    love.graphics.setBlendMode('alpha')
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setBlendMode('alpha', 'premultiplied')
    love.graphics.draw(nightCanvas, 0, 0)
    love.graphics.setBlendMode('alpha')
end

-- Top centre: the sun or moon on a small arc, and the day number.
function Render.clock(dayNight)
    local w = love.graphics.getWidth()
    local font = Render.font(16)
    love.graphics.setFont(font)
    local pw, ph = 132, 50
    local x, y = math.floor((w - pw) / 2), 10
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle('fill', x, y, pw, ph, 6, 6)

    local body, f = dayNight:sky()
    local night = body == 'moon'
    local ax, ay, ar = x + 30, y + ph - 10, 20
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.setLineWidth(1)
    love.graphics.arc('line', 'open', ax, ay, ar, math.pi, math.pi * 2, 16)
    local a = math.pi + f * math.pi
    local bx, by = ax + math.cos(a) * ar, ay + math.sin(a) * ar
    if night then
        love.graphics.setColor(0.9, 0.92, 1)
        love.graphics.circle('fill', bx, by, 6, 20)
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.circle('fill', bx + 3, by - 2, 5, 20)
    else
        love.graphics.setColor(1, 0.85, 0.25)
        for k = 0, 7 do
            local r = k * math.pi / 4
            love.graphics.line(bx + math.cos(r) * 7, by + math.sin(r) * 7, bx + math.cos(r) * 9, by + math.sin(r) * 9)
        end
        love.graphics.circle('fill', bx, by, 5, 20)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print('DAY ' .. dayNight.day, x + 62, y + 8)
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.print(night and 'night' or 'day', x + 62, y + 26)
end

local HUD_ORDER = { 'stone', 'coal', 'iron', 'gold' }

function Render.hud(player, pulse)
    local font = Render.font(16)
    love.graphics.setFont(font)
    local pad, row = 10, 24
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle('fill', pad, pad, 118, row * #HUD_ORDER + 8, 6, 6)
    for i, kind in ipairs(HUD_ORDER) do
        local y = pad + 4 + (i - 1) * row
        local c = kind == 'stone' and COLORS.rock or COLORS[kind]
        local grow = (pulse[kind] or 0) * 4
        love.graphics.setColor(c)
        love.graphics.rectangle('fill', pad + 8 - grow / 2, y + 4 - grow / 2, 14 + grow, 14 + grow, 2, 2)
        love.graphics.setColor(1, 1, 1, 0.25)
        love.graphics.rectangle('line', pad + 8, y + 4, 14, 14, 2, 2)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(kind:upper() .. '  ' .. player.inventory[kind], pad + 30, y + 3)
    end
end

-- bottom: the gap to leave below the hint (room for the touch controls).
function Render.hint(text, alpha, bottom)
    if alpha <= 0 then return end
    local font = Render.font(14)
    love.graphics.setFont(font)
    local w, h = love.graphics.getDimensions()
    local tw = font:getWrap(text, w - 40)
    tw = math.min(tw, w - 40)
    local lines = select(2, font:getWrap(text, w - 40))
    local th = #lines * font:getHeight()
    local x, y = (w - tw) / 2, h - th - (bottom or 24)
    love.graphics.setColor(0, 0, 0, 0.5 * alpha)
    love.graphics.rectangle('fill', x - 10, y - 6, tw + 20, th + 12, 6, 6)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.printf(text, x, y, tw, 'center')
end

return Render
