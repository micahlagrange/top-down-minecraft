require('src.colors')
require('src.constants')
Player = require('src.player')
local World = require('src.world')
local world = World:new()
local players = {}

function love.load()
    player = Player:new()
    player.x = 3
    player.y = 3
    world:GenerateChunk(player:pos())

    local player2 = Player:new()
    player2.x = 16
    player2.y = 16
    world:GenerateChunk(player2:pos())

    table.insert(players, player)
    table.insert(players, player2)
end

function love.draw()
    for x = 0, #world.tiles do
        if world.tiles[x] then
            for y = 0, #world.tiles[x] do
                if world.tiles[x][y] then
                    local pos = world:tileToWorldSpace(x, y)

                    if world.tiles[x][y].Alive then
                        love.graphics.setColor(GRASS)
                    else
                        love.graphics.setColor(0, 0, 0)
                    end
                    love.graphics.rectangle("fill", pos.x, pos.y, world.tileSize, world.tileSize)
                end
            end
        end
    end

    for _, player in ipairs(players) do
        player:draw()
    end
    if CHUNK_DEBUG then
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("line", 0, 0, world.tileSize * world.chunkSize, world.tileSize * world.chunkSize)
    end
end

function love.update()
end
