local seed = require('src.seed')

local World = {}
World.__index = World

function World:new()
    love.math.setRandomSeed(seed.seed)
    local self = setmetatable({}, World)
    self.blockSize = 16
    self.tiles = {}
    self.chunks = {}
    return self
end

function World:worldToTileSpace(x, y)
    return {
        x = math.floor(x / self.blockSize),
        y = math.floor(y / self.blockSize),
    }
end

function World:tileToWorldSpace(x, y)
    return {
        x = x * self.blockSize,
        y = y * self.blockSize,
    }
end

function World:chunkToTileSpace(x, y)
    return {
        x = x / DEFAULT_CHUNK_SIZE,
        y = y / DEFAULT_CHUNK_SIZE
    }
end

function World:tileToChunkSpace(x, y)
    return {
        x = math.floor(x / DEFAULT_CHUNK_SIZE),
        y = math.floor(y / DEFAULT_CHUNK_SIZE)
    }
end

function World:generateTile()
    -- just randomly decide if it is walkable a fixed percentage of the time
    return
end

function World:chunkFromPosition(pos)
    local chunkCoordinates = {
        x = math.floor(pos.x / DEFAULT_CHUNK_SIZE),
        y = math.floor(pos.y / DEFAULT_CHUNK_SIZE),
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
    if pos.x == nil or pos.y == nil then return end
    local chunk = self:chunkFromPosition(pos)
    local startTile = self:chunkToTileSpace(chunk)
    -- we don't worry about cleaning up old chunks right now. optimize later

    -- generate the chunk that the position is in
    for x = startTile.x, startTile.x + DEFAULT_CHUNK_SIZE do
        for y = startTile.y, startTile.y + DEFAULT_CHUNK_SIZE do
            if not self.tiles[x] then
                self.tiles[x] = {}
                if not self.tiles[x][y] then
                    self.tiles[x][y] = { Alive = seed:randomInt(0, 100) < DEFAULT_ALIVE_PERCENT }
                end
            end
        end
    end
end

function World:emitPlayerMoved(pos)
    -- generate the chunk that the player is in, and the N surrounding chunks
    self:GenerateChunk(pos)
end

local instance = World:new()
return instance
