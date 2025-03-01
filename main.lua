require('src.colors')
require('src.constants')
local World = require('src.world')
local world = World:new()
local players = {
    { x = 32, y = 24 }
}

function love.draw()
    for x = 1, #world.tiles do
        for y = 1, #world.tiles[x] do
            if world.tiles[x][y] then
                local pos = world:tileToWorldSpace(x, y)

                love.graphics.setColor(GRASS)
                love.graphics.rectangle("fill", pos.x, pos.y, world.blockSize, world.blockSize)
            end
        end
    end
end
