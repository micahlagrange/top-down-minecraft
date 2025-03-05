require('src.colors')
require('src.constants')
Player                 = require('src.player')
local Controls         = require('src.controls')
local Noise = require('src.noise')
local noise = Noise:new()
local tilecolorbynoise = require('src.tilecolorbynoise')
local controller       = Controls:new()
local player           = Player:new(controller)
player.x               = 0
player.y               = 0
-- singletons
local world            = require('src.world')
local Camera           = require('src.camera')
local camera           = Camera:new()

function love.load()
    world:GenerateChunk({ x = 0, y = 0 })
end

function love.draw()
    camera:draw()

    local drawDistance = world.tileSize * world.chunkSize * 8 --chunks
    local drawFrom = world:worldToTileSpace({ x = player.x - drawDistance, y = player.y - drawDistance })
    for x = drawFrom.x, drawFrom.x + drawDistance do
        if world.tiles[x] then
            for y = drawFrom.y, drawFrom.y + drawDistance do
                if world.tiles[x][y] then
                    local pos = world:tileToWorldSpace(x, y)
                    world.tiles[x][y].altitude = noise:getNoiseValue(x, y)
                    love.graphics.setColor(tilecolorbynoise.hueFromAltitude(world.tiles[x][y]))
                    love.graphics.rectangle("fill", pos.x, pos.y, world.tileSize, world.tileSize)
                end
            end
        end
    end

    player:draw()
    camera:pop()
end

function love.update(dt)
    player:update(dt)
    camera:update(dt, player)
end
