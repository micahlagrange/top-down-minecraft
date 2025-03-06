local Util = require('src.util')

local TileColorByNoise = {}


local function getDimmingByColorAndLayer(color, type, altitude)
    if not DIMMING then return color end
    -- this algorithm tries to give a sense of depth to the layers by dimming the color
    -- as it goes down in altitude, but stone is at higher layers than say water
    -- range of hues 0-1 should be spread across the range of stone from .6 to .97, so
    -- needs to normalized or else stone is too bright (it's higher up!) water is like black (it's the lowest!)
    -- dim color by altitude
    -- Essentially the dimming should start at white for each layer and then go down


    -- for water 100% brightness is actually .06 at the time of this writing
    -- DEPTH_WATER = { 0, .06 }
    -- normalize the altitude value so the max brightness (the least dimming) is .06 and the lowest
    -- brightness (the most dimming) is 0
    -- and I suppose there should be a minimum color value / a maximum dimming
    local brightness = 1
    local minAlti = 0
    local maxAlti = 1
    if type == TILE_WATER then
        minAlti = DEPTH_WATER[1]
        maxAlti = DEPTH_WATER[2]
    elseif type == TILE_GRASS then
        minAlti = DEPTH_GRASS[1]
        maxAlti = DEPTH_GRASS[2]
    elseif type == TILE_STONE then
        minAlti = DEPTH_STONE[1]
        maxAlti = DEPTH_STONE[2]
    elseif type == TILE_SNOW then
        minAlti = DEPTH_SNOW[1]
        maxAlti = DEPTH_SNOW[2]
    end
    brightness = Util.normalize(altitude, minAlti, maxAlti)
    return Util.dimColor(color, brightness)
end

function TileColorByNoise.hueFromAltitude(tile)
    local color
    if tile.type == TILE_WATER then
        color = getDimmingByColorAndLayer(COLOR_WATER, tile.type, tile.altitude)
        -- color = COLOR_WATER
    elseif tile.type == TILE_GRASS then
        color = getDimmingByColorAndLayer(COLOR_GRASS, tile.type, tile.altitude)
    elseif tile.type == TILE_STONE then
        color = getDimmingByColorAndLayer(COLOR_STONE, tile.type, tile.altitude)
    elseif tile.type == TILE_SNOW then
        color = getDimmingByColorAndLayer(COLOR_SNOW, tile.type, tile.altitude)
    else
        color = { .8, .8, 0 }
    end

    return color
end

return TileColorByNoise
