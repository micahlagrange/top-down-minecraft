local seed = require('src.seed')

local World = {}
World.__index = World

function World:new()
    love.math.setRandomSeed(seed.seed)
    local self = setmetatable({}, World)
    self.tileSize = 16
    self.chunkSize = 16
    self.tiles = {}
    self.chunks = {}
    return self
end

function World:worldToTileSpace(x, y)
    return {
        x = math.floor(x / self.tileSize),
        y = math.floor(y / self.tileSize),
    }
end

function World:tileToWorldSpace(x, y)
    return {
        x = x * self.tileSize,
        y = y * self.tileSize,
    }
end

function World:chunkToTileSpace(x, y)
    return {
        x = x * self.chunkSize,
        y = y * self.chunkSize,
    }
end

function World:tileToChunkSpace(x, y)
    return {
        x = math.floor(x / self.chunkSize),
        y = math.floor(y / self.chunkSize),
    }
end

function World:chunkFromPosition(pos)
    local chunkCoordinates = {
        x = math.floor(pos.x / self.chunkSize),
        y = math.floor(pos.y / self.chunkSize),
    }
    return chunkCoordinates
end

-- example chunk graph:
-- [0, 0][1, 0][2, 0] (tile 0, 0 to 32, 0)  (world 0, 0   to 512, 0)
-- [0, 1][1, 1][2, 1] (tile 0, 1 to 32, 16) (world 0, 256 to 512, 256)
-- [0, 2][1, 2][2, 2] (tile 0, 2 to 32, 32) (world 0, 512 to 512, 512)
--
-- Chunk 1, 1 is tile 16, 16, because tiles start at position 0, 0
-- Chunk 1, 1 is also world coordinates, assuming 16 pixel
--   tiles, take e.g.: world coordinates { x = 256.333, y = 256.444 }
-- world pos 256.333 / 16 = 16.0208125, with math.foor it's tile 16.
-- tile pos 16.0208125 / 16 is 1.0013, with math.floor is chunk 1
-- so the above example at world coordinates is:
--    tile 16, 16
--    chunk 1, 1

function World:GenerateChunk(pos)
    if CHUNK_DEBUG then
        print('load chunk', pos.x, pos.y)
    end
    if pos.x == nil or pos.y == nil then return end
    local chunk = self:chunkFromPosition(pos)
    local startTile = self:chunkToTileSpace(chunk.x, chunk.y)
    -- we don't worry about cleaning up old chunks right now. optimize later

    -- generate the chunk that the position is in
    for x = startTile.x, startTile.x + self.chunkSize - 1 do
        if CHUNK_DEBUG then
            print('start tile', startTile.x, startTile.y, 'end tile', startTile.x + self.chunkSize - 1,
                startTile.y + self.chunkSize - 1)
        end
        if not self.tiles[x] then
            self.tiles[x] = {}
        end
        for y = startTile.y, startTile.y + self.chunkSize - 1 do
            if not self.tiles[x][y] then
                self.tiles[x][y] = { Alive = seed:randomInt(0, 100) < self.chunkSize }
            end
        end
    end
end

function World:emitPlayerMoved(pos)
    -- generate the chunk that the player is in
    -- (and eventually the N surrounding chunks)
    self:GenerateChunk(pos)
end

local instance = World:new()
return instance
