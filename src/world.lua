local Noise = require('src.noise')
local Util  = require('src.util')
local noise = Noise:new()

local seed = require('src.seed')

local World = {}
World.__index = World

function World:new()
    local self = setmetatable({}, World)
    self.worldSeed = seed.seed
    self.tileSize = DEFAULT_TILE_SIZE
    self.chunkSize = DEFAULT_CHUNK_SIZE
    self.chunksAroundPlayer = DEFAULT_CHUNKS_NEAR_PLAYER
    self.tiles = {}
    self.chunks = {}
    self.lastGeneratedChunk = { x = 0, y = 0 }
    return self
end

function World:worldToTileSpace(x, y)
    if x == nil then print('world fn got nil input') end
    if type(x) == "table" then
        y = x.y
        x = x.x
    end
    return {
        x = math.floor(x / self.tileSize),
        y = math.floor(y / self.tileSize),
    }
end

function World:tileToWorldSpace(x, y)
    if x == nil then print('world fn got nil input') end
    if type(x) == "table" then
        y = x.y
        x = x.x
    end
    return {
        x = x * self.tileSize,
        y = y * self.tileSize,
    }
end

function World:chunkToTileSpace(x, y)
    if x == nil then print('world fn got nil input') end
    return {
        x = x * self.chunkSize,
        y = y * self.chunkSize,
    }
end

function World:tileToChunkSpace(x, y)
    if x == nil then print('world fn got nil input') end
    return {
        x = math.floor(x / self.chunkSize),
        y = math.floor(y / self.chunkSize),
    }
end

function World:chunkFromPosition(pos)
    if pos == nil then print('world fn got nil input') end
    local chunkCoordinates = {
        x = math.floor(pos.x / self.tileSize / self.chunkSize),
        y = math.floor(pos.y / self.tileSize / self.chunkSize),
    }
    return chunkCoordinates
end

function World:positionFromChunk(chunk)
    local tile = self:chunkToTileSpace(chunk.x, chunk.y)
    return self:tileToWorldSpace(tile.x, tile.y)
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
    if CHUNK_DEBUG then print('player pos:', pos.x, pos.y) end
    if pos.x == nil or pos.y == nil then return end
    local playerChunk = self:chunkFromPosition(pos)
    if CHUNK_DEBUG then print("player in chunk:", playerChunk.x, playerChunk.y) end
    -- we don't worry about cleaning up old chunks right now. optimize later

    -- N chunks surrounding player
    for cy = playerChunk.y - self.chunksAroundPlayer, playerChunk.y + self.chunksAroundPlayer do
        for cx = playerChunk.x - self.chunksAroundPlayer, playerChunk.x + self.chunksAroundPlayer do
            local startTile = self:chunkToTileSpace(cx, cy)
            if CHUNK_DEBUG then
                print("load chunk", cx, cy)
            end

            -- generate the chunk that the position is in
            love.math.setRandomSeed(seed:generateChunkSeed({ x = cx, y = cy }))
            for x = startTile.x, startTile.x + self.chunkSize - 1 do
                if not self.tiles[x] then
                    self.tiles[x] = {}
                    if CHUNK_DEBUG and x < 0 then print("ok...") end
                end
                for y = startTile.y, startTile.y + self.chunkSize - 1 do
                    if not self.tiles[x][y] then
                        self.tiles[x][y] = { altitude = noise:getNoiseValue(x, y)}
                        self.tiles[x][y] = { type = self:getTileTypeFromNoise(self.tiles[x][y].altitude) }
                    end
                end
            end
        end
    end
end

function World:getTileTypeFromNoise(noise)
    -- assume 0-1
    if Util.noiseRange(noise, DEPTH_WATER) then
        return TILE_WATER
    elseif Util.noiseRange(noise, DEPTH_GRASS) then
        return TILE_GRASS
    elseif Util.noiseRange(noise, DEPTH_STONE) then
        return TILE_STONE
    elseif Util.noiseRange(noise, DEPTH_SNOW) then
        return TILE_SNOW
    else
        print("tfw", noise)
        return { 1, 0, 1 }
    end
end

function World:emitPlayerMoved(pos)
    -- generate the chunk that the player is in
    -- (and eventually the N surrounding chunks)
    local chunk = self:chunkFromPosition(pos)
    if self.lastGeneratedChunk.x ~= chunk.x or self.lastGeneratedChunk.y ~= chunk.y then
        -- only generate the chunk if it's a new chunk the player entered
        self:GenerateChunk(pos)
    end
end

local instance = World:new()
return instance
