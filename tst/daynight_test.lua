local T = require('tst.check')
local DayNight = require('src.daynight')

local DT = 1 / 60

-- Run the clock for `seconds` of play, one frame at a time.
local function run(dn, seconds, each)
    for _ = 1, math.floor(seconds / DT + 0.5) do
        dn:update(DT)
        if each then each(dn) end
    end
end

T.test('a full day lasts a few minutes of play', function()
    T.ok(DayNight.DAY_LENGTH >= 120 and DayNight.DAY_LENGTH <= 360, 'between two and six minutes')
    local dn = DayNight.new()
    local start = dn.phase
    run(dn, DayNight.DAY_LENGTH)
    T.eq(dn.day, 2, 'one day passed')
    T.ok(math.abs(dn.phase - start) < 1e-6, 'back at the same time of day')
end)

T.test('a new game starts on day 1 in full daylight', function()
    local dn = DayNight.new()
    T.eq(dn.day, 1)
    T.eq(dn:darkness(), 0)
    T.ok(not dn:isNight())
end)

T.test('night comes and goes within a day', function()
    local dn = DayNight.new()
    local darkest, sawNight, sawDayAgain = 0, false, false
    run(dn, DayNight.DAY_LENGTH, function(d)
        darkest = math.max(darkest, d:darkness())
        if d:isNight() then sawNight = true end
        if sawNight and d:darkness() == 0 then sawDayAgain = true end
    end)
    T.eq(darkest, 1, 'the middle of the night is fully dark')
    T.ok(sawNight, 'it got dark')
    T.ok(sawDayAgain, 'and light again')
end)

T.test('the map darkens and brightens smoothly, never in a jump', function()
    local dn = DayNight.new()
    local prev, biggest = dn:darkness(), 0
    run(dn, DayNight.DAY_LENGTH * 2, function(d)
        local now = d:darkness()
        biggest = math.max(biggest, math.abs(now - prev))
        prev = now
    end)
    T.ok(biggest < 0.01, 'largest change in one frame was ' .. biggest)
end)

T.test('dusk and dawn each take several seconds', function()
    local dusk = (DayNight.DUSK[2] - DayNight.DUSK[1]) * DayNight.DAY_LENGTH
    local dawn = (DayNight.DAWN[2] - DayNight.DAWN[1]) * DayNight.DAY_LENGTH
    T.ok(dusk >= 15, 'dusk takes ' .. dusk .. ' s')
    T.ok(dawn >= 15, 'dawn takes ' .. dawn .. ' s')
end)

T.test('the night overlay never fully hides the map', function()
    T.ok(DayNight.MAX_DARK < 0.9)
    local dn = DayNight.new(0.75)
    T.eq(dn:overlayAlpha(), DayNight.MAX_DARK)
end)

T.test('the player light is clear in its core and fades to the night at its edge', function()
    local a = DayNight.MAX_DARK
    T.eq(DayNight.lightAlpha(0, a), 0, 'clear at the player')
    T.eq(DayNight.lightAlpha(DayNight.LIGHT_CORE, a), 0, 'clear across the core')
    T.eq(DayNight.lightAlpha(1, a), a, 'full night at the edge')
    T.eq(DayNight.lightAlpha(2, a), a, 'and beyond it')
    local prev = 0
    for k = 0, 20 do
        local v = DayNight.lightAlpha(k / 20, a)
        T.ok(v >= prev, 'fades out without a ring')
        prev = v
    end
    T.ok(DayNight.LIGHT_RADIUS >= 3, 'the light reaches past the mining reach')
end)

T.test('the light does nothing in the day', function()
    local dn = DayNight.new(0.25)
    T.eq(DayNight.lightAlpha(1, dn:overlayAlpha()), 0)
end)

T.test('the day counter goes up once at each sunrise', function()
    local dn = DayNight.new()
    local changes = 0
    local last = dn.day
    run(dn, DayNight.DAY_LENGTH * 3, function(d)
        if d.day ~= last then
            changes = changes + 1
            T.ok(d.phase < 0.01, 'the day turns over at sunrise')
            last = d.day
        end
    end)
    T.eq(changes, 3)
    T.eq(dn.day, 4)
end)

T.test('the sun is up by day and the moon by night', function()
    for k = 0, 99 do
        local dn = DayNight.new(k / 100)
        local body, f = dn:sky()
        local d = dn:darkness()
        if body == 'moon' then T.ok(d >= 0.5 - 1e-9, 'moon only when dark, at ' .. k / 100)
        else T.ok(d <= 0.5 + 1e-9, 'sun only when light, at ' .. k / 100) end
        T.ok(f >= 0 and f <= 1, 'position across the sky in range at ' .. k / 100)
    end
end)

T.test('the sun crosses the sky from rising to setting', function()
    local dn = DayNight.new(0.96)
    local _, early = dn:sky()
    dn.phase = 0.3
    local _, mid = dn:sky()
    dn.phase = 0.55
    local _, late = dn:sky()
    T.ok(early < mid and mid < late, 'moves one way')
end)

T.test('a long frame never skips a day', function()
    local dn = DayNight.new(0.99)
    dn:update(DayNight.DAY_LENGTH * 2.5)
    T.eq(dn.day, 4)
    T.ok(dn.phase >= 0 and dn.phase < 1)
end)

T.done()
