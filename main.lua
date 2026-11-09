local World  = require('src.world')
local Player = require('src.player')
local Input  = require('src.input')
local Render = require('src.render')
local Sfx    = require('src.sfx')

local world, player
local t = 0
local tickTimer = 0
local pulse = {}
local autoplay -- tst/autoplay.lua drives the game for screenshots (TOPSOIL_AUTOPLAY)

local HINT_KEYS = 'WASD or arrows to walk. Hold SPACE, or hold the mouse on a block, to mine it.'
local HINT_TOUCH = 'Drag on the left to walk. Hold MINE, or hold a block, to mine it.'

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    world = World.new()
    player = Player.new(world)
    Sfx.load()
    Render.updateCamera(world, player)
    if os.getenv('TOPSOIL_AUTOPLAY') then autoplay = require('tst.autoplay') end
end

function love.update(dt)
    dt = math.min(dt, 1 / 30)
    if autoplay then dt = 1 / 60 end
    t = t + dt
    local intent = autoplay and autoplay.input(t, player, world) or Input.read(Render.screenToTile)

    player:move(intent.dx, intent.dy, dt)
    local drop, tx, ty = player:mine(intent.mine, dt, intent.tx, intent.ty)
    if player.mining then
        tickTimer = tickTimer - dt
        if tickTimer <= 0 then
            tickTimer = 0.16
            Sfx.play('tick', 0.9 + (t * 7 % 1) * 0.2)
        end
    else
        tickTimer = 0
    end
    if drop then
        Render.invalidate()
        Render.burst(tx, ty, drop)
        Sfx.play('crunch', drop == 'stone' and 1 or 0.85)
        if drop ~= 'stone' then Sfx.play('ore', drop == 'gold' and 1.25 or drop == 'iron' and 1.1 or 1) end
        pulse[drop] = 1
    end
    for k, v in pairs(pulse) do pulse[k] = math.max(0, v - dt * 4) end

    local fx, fy
    if intent.tx then fx, fy = intent.tx, intent.ty else fx, fy = player:facingTile() end
    player.target = { x = fx, y = fy }

    Render.updateParticles(dt)
    Render.updateCamera(world, player, dt)
    if autoplay then autoplay.after(t) end
end

function love.draw()
    Render.draw(world, player, player.target, t)
    Render.hud(player, pulse)
    Input.draw()
    Render.hint(Input.touchSeen and HINT_TOUCH or HINT_KEYS, math.min(1, math.max(0, 9 - t)))
end

function love.touchpressed(id, x, y)
    Input.touchpressed(id, x, y)
end

function love.keypressed(key)
    if key == 'escape' and love.system.getOS() ~= 'Web' then love.event.quit() end
end
