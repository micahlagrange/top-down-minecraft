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

local HINT_KEYS = 'WASD or arrows to walk. Hold SPACE, or hold the mouse on a block or tree, to mine or chop it. F eats an apple.'
local HINT_TOUCH = 'Drag on the left to walk. Hold MINE, or hold a block or tree, to mine or chop it. EAT eats an apple.'

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

    player:update(dt)
    if intent.eat then
        if player:eat() then
            Sfx.play('munch', 0.95 + (t * 5 % 1) * 0.1)
            pulse.apple = 1
            pulse.hunger = 1
        end
    end
    player:move(intent.dx, intent.dy, dt)
    local drop, tx, ty, bonus = player:mine(intent.mine, dt, intent.tx, intent.ty)
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
        if drop == 'wood' then
            Sfx.play('crunch', 0.6)
        else
            Sfx.play('crunch', drop == 'stone' and 1 or 0.85)
            if drop ~= 'stone' then Sfx.play('ore', drop == 'gold' and 1.25 or drop == 'iron' and 1.1 or 1) end
        end
        pulse[drop] = 1
        if bonus then
            Render.burst(tx, ty, bonus)
            Sfx.play('ore', 0.8)
            pulse[bonus] = 1
        end
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
    Render.hud(player, pulse, t)
    local tg = player.target
    local chop = tg and world:get(tg.x, tg.y) == 'tree'
    Input.draw(chop and 'CHOP' or 'MINE', player.inventory.apple > 0)
    local alpha = math.min(1, math.max(0, 9 - t))
    if Input.touchSeen then
        local _, ey, er = Input.eatButton()
        Render.hint(HINT_TOUCH, alpha, love.graphics.getHeight() - ey + er * 1.5)
    else
        Render.hint(HINT_KEYS, alpha)
    end
end

function love.touchpressed(id, x, y)
    Input.touchpressed(id, x, y)
end

function love.mousepressed(x, y, button, istouch)
    Input.mousepressed(x, y, button, istouch)
end

function love.keypressed(key)
    Input.keypressed(key)
    if key == 'escape' and love.system.getOS() ~= 'Web' then love.event.quit() end
end
