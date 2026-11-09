-- Sounds made in code at load time, so the game ships no audio files.

local World = require('src.world')

local Sfx = {}
local sources = {}
local RATE = 22050

local function make(seconds, fn)
    local n = math.floor(seconds * RATE)
    local data = love.sound.newSoundData(n, RATE, 16, 1)
    local r = World.rng(7)
    for i = 0, n - 1 do
        local t = i / RATE
        data:setSample(i, math.max(-1, math.min(1, fn(t, t / seconds, r))))
    end
    return love.audio.newSource(data, 'static')
end

function Sfx.load()
    local last = 0
    -- a dry tap of pick on stone
    sources.tick = make(0.05, function(t, f, r)
        last = last * 0.5 + (r.next() * 2 - 1) * 0.5
        return last * (1 - f) ^ 3 * 0.5
    end)
    -- a low crumble when a block breaks
    sources.crunch = make(0.22, function(t, f, r)
        last = last * 0.85 + (r.next() * 2 - 1) * 0.15
        return (last * 2.2 + math.sin(t * 2 * math.pi * 90) * 0.2) * (1 - f) ^ 2
    end)
    -- a bright two-note chime for a mineral
    sources.ore = make(0.3, function(t, f)
        local hz = f < 0.35 and 880 or 1318
        return math.sin(t * 2 * math.pi * hz) * 0.25 * (1 - f) ^ 1.5
    end)
end

function Sfx.play(name, pitch)
    local s = sources[name]
    if not s then return end
    s = s:clone()
    s:setPitch(pitch or 1)
    s:play()
end

return Sfx
