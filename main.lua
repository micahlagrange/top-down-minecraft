require('src.colors')
require('src.constants')
Player = require('src.player')
local Controls = require('src.controls')
local controller = Controls:new()
local player = Player:new(controller)
player.x = 0
player.y = 0
-- singletons
local world = require('src.world')
local Camera = require('src.camera')
local camera = Camera:new()

function love.load()
    world:GenerateChunk({ x = 0, y = 0 })
end

function love.draw()
    camera:draw()
    for x = 0, #world.tiles do
        if world.tiles[x] then
            for y = 0, #world.tiles[x] do
                if world.tiles[x][y] then
                    local pos = world:tileToWorldSpace(x, y)

                    if world.tiles[x][y].type == TILE_WATER then
                        love.graphics.setColor(COLOR_WATER)
                    elseif world.tiles[x][y].type == TILE_GRASS then
                        love.graphics.setColor(COLOR_GRASS)
                    elseif world.tiles[x][y].type == TILE_STONE then
                        love.graphics.setColor(COLOR_STONE)
                    elseif world.tiles[x][y].type == TILE_SNOW then
                        love.graphics.setColor(COLOR_SNOW)
                    end
                    love.graphics.rectangle("fill", pos.x, pos.y, world.tileSize, world.tileSize)
                end
            end
        end
    end

    player:draw()
    if CHUNK_DEBUG then
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("line", 0, 0, world.tileSize * world.chunkSize, world.tileSize * world.chunkSize)
    end
    camera:pop()
end

function love.update(dt)
    player:update(dt)
    camera:update(dt, player)
end
