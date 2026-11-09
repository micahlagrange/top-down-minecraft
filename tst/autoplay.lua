-- Drives the game without a player for screenshots: walk to the rock, tunnel
-- into it, then quit. Run with TOPSOIL_AUTOPLAY=1; the shots land in the save
-- folder (%APPDATA%/LOVE/topsoil on Windows) as shot-N.png.

local Input = require('src.input')

local A = {}
local SHOTS = { 0.5, 3.2, 6.5, 10 }
local taken = 0

function A.input(t, player)
    if t < 3 then return { dx = 1, dy = 0, mine = false } end
    if t < 6.4 then return { dx = 1, dy = 0, mine = true } end
    if t < 7 then return { dx = 0, dy = 1, mine = false } end
    return { dx = 1, dy = 0, mine = true }
end

function A.after(t)
    if taken < #SHOTS and t >= SHOTS[taken + 1] then
        taken = taken + 1
        if taken == #SHOTS then Input.touchSeen = true end
        love.graphics.captureScreenshot('shot-' .. taken .. '.png')
    end
    if t > SHOTS[#SHOTS] + 0.3 then love.event.quit() end
end

return A
