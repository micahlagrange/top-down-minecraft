local Collision = {}

-- Collision detection function;
-- Returns true if two boxes overlap, false if they don't;
-- x1,y1 are the top-left coords of the first box, while w1,h1 are its width and height;
-- x2,y2,w2 & h2 are the same, but for the second box.
function Collision.aabbCollided(rect1, rect2)
    local x1, y1, w1, h1 = rect1.x, rect1.y, rect1.width, rect1.height
    local x2, y2, w2, h2 = rect2.x, rect2.y, rect2.width, rect2.height
    return x1 < x2 + w2 and
        x2 < x1 + w1 and
        y1 < y2 + h2 and
        y2 < y1 + h1
end

return Collision
