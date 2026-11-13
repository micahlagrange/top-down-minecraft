-- The day/night clock: how far through the day it is, how dark the map is,
-- the day number and whether the sun or the moon is up. Pure Lua (no love.*),
-- so the tests can drive it.
--
-- `phase` runs from 0 to 1 once a day, starting at sunrise:
--   0.00-0.50 day, 0.50-0.62 dusk, 0.62-0.90 night, 0.90-1.00 dawn.

local DayNight = {}
DayNight.__index = DayNight

DayNight.DAY_LENGTH = 240   -- seconds of play for one whole day and night
DayNight.START = 0.08       -- a new game starts in the morning
DayNight.DUSK = { 0.50, 0.62 }
DayNight.DAWN = { 0.90, 1.00 }
DayNight.MAX_DARK = 0.78    -- how much of the map the night hides at its darkest
DayNight.LIGHT_RADIUS = 4.5 -- tiles of light around the player at night
DayNight.LIGHT_CORE = 0.35  -- the share of that radius that is fully lit

local function smooth(a, b, x)
    local f = math.max(0, math.min(1, (x - a) / (b - a)))
    return f * f * (3 - 2 * f)
end

function DayNight.new(phase)
    local self = setmetatable({}, DayNight)
    self.phase = phase or DayNight.START
    self.day = 1
    return self
end

-- Advance the clock; a new day starts at sunrise.
function DayNight:update(dt)
    self.phase = self.phase + dt / DayNight.DAY_LENGTH
    while self.phase >= 1 do
        self.phase = self.phase - 1
        self.day = self.day + 1
    end
end

-- 0 in full daylight, 1 at the middle of the night, smooth in between.
function DayNight.darknessAt(phase)
    if phase < DayNight.DUSK[1] then return 0 end
    if phase < DayNight.DAWN[1] then return smooth(DayNight.DUSK[1], DayNight.DUSK[2], phase) end
    return 1 - smooth(DayNight.DAWN[1], DayNight.DAWN[2], phase)
end

function DayNight:darkness()
    return DayNight.darknessAt(self.phase)
end

-- The alpha of the night overlay, 0 (clear) to MAX_DARK.
function DayNight:overlayAlpha()
    return self:darkness() * DayNight.MAX_DARK
end

function DayNight:isNight()
    return (self:sky()) == 'moon'
end

-- The overlay alpha at `d` (distance from the player / light radius): clear
-- in the core of the light, fading out to the full night at the edge.
function DayNight.lightAlpha(d, alpha)
    return alpha * smooth(DayNight.LIGHT_CORE, 1, d)
end

-- What the HUD shows: 'sun' or 'moon', and how far across the sky it is
-- (0 rising, 1 setting). The sun is up from the middle of dawn to the middle
-- of dusk, the moon the rest of the time, so the icon flips when the map is
-- half dark.
function DayNight:sky()
    local sunset = (DayNight.DUSK[1] + DayNight.DUSK[2]) / 2
    local sunrise = (DayNight.DAWN[1] + DayNight.DAWN[2]) / 2
    local sunUp = 1 - sunrise + sunset
    local p = self.phase
    if p >= sunrise then return 'sun', (p - sunrise) / sunUp end
    if p < sunset then return 'sun', (p + 1 - sunrise) / sunUp end
    return 'moon', (p - sunset) / (sunrise - sunset)
end

return DayNight
