local Collision = require('src.collision')
local world     = require('src.world')
local Util      = require('src.util')

local Player    = {}
Player.__index  = Player
local debugPrint

local function walkable(tileType)
    return tileType == TILE_GRASS
end

function Player:new(controller)
    local self = setmetatable({}, Player)
    self.controller = controller
    self.speed = 100
    self.sprintMultiplier = 2
    self.width = 14
    self.height = 14
    self.dircheck = {}
    return self
end

function Player:pos()
    return {
        x = self.x,
        y = self.y,
    }
end

function Player:setPos(pos)
    self.x = pos.x
    self.y = pos.y
end

function Player:draw()
    love.graphics.setColor(1, 1, 0, .8)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    if COLLISION_DEBUG then
        for _, tile in ipairs(self:adjacentTiles()) do
            local to = world:tileToWorldSpace(tile)
            if walkable(world.tiles[tile.x][tile.y].type) then
                love.graphics.setColor(0, 1, 0)
            else
                love.graphics.setColor(1, 0, 0)
            end
            love.graphics.rectangle("line", to.x, to.y, world.tileSize, world.tileSize)
        end
        -- love.graphics.setColor(1, 1, 1)
        love.graphics.print("tile: " .. self:getTile().x .. "," .. self:getTile().y, self.x, self.y + 20)
        love.graphics.setColor({ 1, 0, 0, .5 })
        for _, chk in ipairs(self.dircheck) do
            local t = world:tileToWorldSpace(chk)
            love.graphics.print("currxycheck:" .. chk.x .. ',' .. chk.y, self.x, self.y + 40)
            love.graphics.rectangle("fill", t.x, t.y, world.tileSize, world.tileSize)
        end
        -- end
        -- if self:_collidesRectangle(tile, self.controller:movementVector()) then
        --     love.graphics.setColor(0, 0, 0)
        --     love.graphics.print(world.tiles[tile.x][tile.y].type, self.x, self.y)
        -- end
        love.graphics.setColor(.1, .1, .1, .1)
        local myTile = self:getTile()
        local tc = world:tileToWorldSpace(myTile.x, myTile.y)
        love.graphics.rectangle("fill", tc.x, tc.y, world.tileSize, world.tileSize)
    end

    if debugPrint then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(debugPrint, self.x, self.y - 20)
    end

    if COLLISION_DEBUG and CollisionDrawRects then
        for _, rect in ipairs(CollisionDrawRects) do
            love.graphics.setColor(1, 1, 0)
            love.graphics.rectangle("line", rect.x, rect.y, rect.width, rect.height)
        end
        for _, rect in ipairs(CollisionDrawRectsNoCollide) do
            love.graphics.setColor(0, 1, 0)
            love.graphics.rectangle("line", rect.x, rect.y, rect.width, rect.height)
        end
    end
    CollisionDrawRects = {}
    CollisionDrawRectsNoCollide = {}
end

function Player:update(dt)
    local vector = self.controller:movementVector()
    if vector.x ~= 0 or vector.y ~= 0 then
        self:move(vector, dt)
    end
end

function Player:_checkCollisionsTheStupidWay(velocity, moveDir)
    --so fucking bad, omg so bad
    local halfSize = world.tileSize / 2
    local direction = { 0, 1, -1 }
    -- x player rect
    local playerRect = {
        x = velocity.x,
        y = self.y,
        width = self.width,
        height = self.height
    }
    if moveDir.x > 0 then
        --moving right
        for pos in ipairs(direction) do
            self.dircheck = {}
            local x = 1 + math.floor((velocity.x + halfSize) / world.tileSize)
            local y = pos + math.floor((velocity.y + halfSize) / world.tileSize)
            table.insert(self.dircheck, { x = x, y = y })
        end
        for _, pos in ipairs(direction) do
            local x = 1 + math.floor((velocity.x + halfSize) / world.tileSize)
            local y = pos + math.floor((velocity.y + halfSize) / world.tileSize)
            if x ~= -1 and y ~= -1 and x < world.tileSize and y < world.tileSize then
                local tileRect = {
                    x = x * world.tileSize,
                    y = y * world.tileSize,
                    width = world.tileSize,
                    height = world.tileSize
                }
                if Collision.aabbCollided(playerRect, tileRect)
                    and not walkable(world.tiles[x][y].type) then
                    velocity.x = tileRect.x - self.width
                    -- break
                    return velocity
                end
            end
        end
    elseif moveDir.x < 0 then
        for pos in ipairs(direction) do
            self.dircheck = {}
            local x = math.floor((velocity.x + halfSize) / world.tileSize) - 1
            local y = pos + math.floor((velocity.y + halfSize) / world.tileSize)
            table.insert(self.dircheck, { x = x, y = y })
        end
        for _, pos in ipairs(direction) do
            local x = math.floor((velocity.x + halfSize) / world.tileSize) - 1
            local y = pos + math.floor((velocity.y + halfSize) / world.tileSize)
            if x ~= -1 and y ~= -1 and x < world.tileSize and y < world.tileSize then
                local tileRect = {
                    x = x * world.tileSize,
                    y = y * world.tileSize,
                    width = world.tileSize,
                    height = world.tileSize
                }
                if Collision.aabbCollided(playerRect, tileRect)
                    and not walkable(world.tiles[x][y].type) then
                    print('yup left')
                    velocity.x = tileRect.x + world.tileSize
                    -- break
                    return velocity
                end
            end
        end
    end

    -- y direction
    -- y player rect
    playerRect = {
        x = self.x,
        y = velocity.y,
        width = self.width,
        height = self.height,
    }

    if moveDir.y > 0 then
        for pos in ipairs(direction) do
            self.dircheck = {}
            local x = pos + math.floor((velocity.x + halfSize) / world.tileSize)
            local y = 1 + math.floor((velocity.y + halfSize) / world.tileSize)
            table.insert(self.dircheck, { x = x, y = y })
        end
        for pos in ipairs(direction) do
            local x = pos + math.floor((velocity.x + halfSize) / world.tileSize)
            local y = 1 + math.floor((velocity.y + halfSize) / world.tileSize)
            if x ~= -1 and y ~= -1 and x < world.tileSize and y < world.tileSize then
                local tileRect = {
                    x = x * world.tileSize,
                    y = y * world.tileSize,
                    width = world.tileSize,
                    height = world.tileSize
                }
                if Collision.aabbCollided(playerRect, tileRect)
                    and not walkable(world.tiles[x][y].type) then
                    print('yup down')
                    velocity.y = tileRect.y - world.tileSize
                    -- break
                    return velocity
                end
            end
        end
    elseif moveDir.y < 0 then
        for pos in ipairs(direction) do
            self.dircheck = {}
            local x = pos + math.floor((velocity.x + halfSize) / world.tileSize)
            local y = math.floor((velocity.y + halfSize) / world.tileSize) - 1
            table.insert(self.dircheck, { x = x, y = y })
        end
        for pos in ipairs(direction) do
            local x = pos + math.floor((velocity.x + halfSize) / world.tileSize)
            local y = math.floor((velocity.y + halfSize) / world.tileSize) - 1
            if not x or not y then print('wtf') end
            if x ~= -1 and y ~= -1 and x < world.tileSize and y < world.tileSize then
                local tileRect = {
                    x = x * world.tileSize,
                    y = y * world.tileSize,
                    width = world.tileSize,
                    height = world.tileSize
                }
                if Collision.aabbCollided(playerRect, tileRect)
                    and not walkable(world.tiles[x][y].type) then
                    print('yup up')
                    velocity.y = tileRect.y + world.tileSize
                    -- break
                    return velocity
                end
            end
        end
    end

    return velocity
end

function Player:getTile()
    return world:worldToTileSpace(
        self.x + (self.width / 2),
        self.y + (self.height / 2)
    )
end

function Player:adjacentTiles()
    local tile = self:getTile()
    return {
        { x = tile.x - 1, y = tile.y - 1 }, -- top left
        { x = tile.x,     y = tile.y - 1 }, -- top
        { x = tile.x + 1, y = tile.y - 1 }, -- top right
        { x = tile.x + 1, y = tile.y },     -- right
        { x = tile.x + 1, y = tile.y + 1 }, -- bottom right
        { x = tile.x,     y = tile.y + 1 }, -- bottom
        { x = tile.x - 1, y = tile.y + 1 }, -- bottom left
        { x = tile.x - 1, y = tile.y },     -- left
    }
end

function Player:adjacentTilesInXDirection(direction)
    local tiles = {}
    for _, tile in ipairs(self:adjacentTiles()) do
        if self:tileInMovementDirection(direction, 0, tile) then
            local wt = world:tileToWorldSpace(tile)
            local tr = { x = wt.x, y = wt.y, width = world.tileSize, height = world.tileSize }
            table.insert(tiles, tile)
        end
    end
    if COLLISION_DEBUG then CollisionDrawRects = tiles end
    return tiles
end

function Player:adjacentTilesInYDirection(direction)
    local tiles = {}
    for _, tile in ipairs(self:adjacentTiles()) do
        if self:tileInMovementDirection(0, direction, tile) then
            local wt = world:tileToWorldSpace(tile)
            local tr = { x = wt.x, y = wt.y, width = world.tileSize, height = world.tileSize }
            table.insert(tiles, tile)
        end
    end
    if COLLISION_DEBUG then CollisionDrawRects = tiles end
    return tiles
end

function Player:tileInMovementDirection(x, y, tile)
    if x > 0 and tile.x > self:getTile().x or x < 0 and tile.x < self:getTile().x then
        debugPrint = "tile xy: " ..
            tile.x .. "," .. tile.y .. " playertile xy: " .. self:getTile().x .. "," .. self:getTile().y
        return true
    end
    if y > 0 and tile.y > self:getTile().y or y < 0 and tile.y < self:getTile().y then
        debugPrint = "tile xy: " ..
            tile.x .. "," .. tile.y .. " playertile xy: " .. self:getTile().x .. "," .. self:getTile().y
        return true
    end
end

function Player:checkTilesForCollision(x, y, tiles)
    local playerRect = {
        x = x,
        y = y,
        width = self.width,
        height = self.height,
    }
    for _, tile in ipairs(tiles) do
        if not walkable(world.tiles[tile.x][tile.y].type) then
            local tileOrigin = world:tileToWorldSpace(tile)
            local tileRect = {
                x = tileOrigin.x,
                y = tileOrigin.y,
                width = world.tileSize,
                height = world.tileSize,
            }
            if Collision.aabbCollided(tileRect, playerRect) then
                table.insert(CollisionDrawRects, playerRect)
                return true
            end
        end
    end
end

function Player:move(vector, dt)
    local direction = vector
    local multi = 1
    if self.controller:sprintButtonHeld() then
        multi = multi * self.sprintMultiplier
    end
    local velocity = {
        x = self.x + vector.x * self.speed * multi * dt,
        y = self.y + vector.y * self.speed * multi * dt,
    }
    -- checking x and y separately is the easiest way to collide and slide!
    -- revert x if colliding
    if self:checkTilesForCollision(velocity.x, self.y, self:adjacentTilesInXDirection(direction.x)) then
        velocity.x = self.x
    end
    -- revert y if colliding
    if self:checkTilesForCollision(self.x, velocity.y, self:adjacentTilesInYDirection(direction.y)) then
        velocity.y = self.y
    end
    self.x = velocity.x
    self.y = velocity.y
    world:emitPlayerMoved(self:pos())
end

return Player
