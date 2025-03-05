local Util = require('src.util')

local TileColorByNoise = {}
function TileColorByNoise.hueFromAltitude(tile)
    local color
    local makeup
    if tile.type == TILE_WATER then
        color = COLOR_WATER
        makeup = DEPTH_WATER[2] / 2
    elseif tile.type == TILE_GRASS then
        color = COLOR_GRASS
        makeup = DEPTH_GRASS[2] / 2
    elseif tile.type == TILE_STONE then
        color = COLOR_STONE
        makeup = DEPTH_STONE[2]
    elseif tile.type == TILE_SNOW then
        color = COLOR_SNOW
        makeup = 0
    else
        color = { .8, .8, 0 }
    end

    -- dim color by altitude
    local dimmed = Util.multiplyColorVector(color,
        { 1 - makeup + tile.altitude, 1 - makeup + tile.altitude, 1 - makeup + tile.altitude })
    return dimmed
end

return TileColorByNoise
