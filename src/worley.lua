local floor = math.floor
local sqrt = math.sqrt
local bxor = bit.bxor


-- linear congruential generator
local function lcgRandom(lastValue)
    return floor((110351245 * lastValue + 12345) % 0x100000000)
end

local OFFSET_BASIS = 2166136261
local FNV_PRIME = 16777619

-- FNV hash
local function hash(i, j, k)
    return (bxor(
        bxor(
            bxor(OFFSET_BASIS, i) * FNV_PRIME, j
        ) * FNV_PRIME
        , k) * FNV_PRIME)
end

-- possion distribution
local function probLookup(value)
    if value < 393325350 then return 1 end
    if value < 1022645910 then return 2 end
    if value < 1861739990 then return 3 end
    if value < 2700834071 then return 4 end
    if value < 3372109335 then return 5 end
    if value < 3819626178 then return 6 end
    if value < 4075350088 then return 7 end
    if value < 4203212043 then return 8 end
    return 9
end

-- insertion sort
local function insert(arr, value)
    local temp, l = 0, #arr
    for i = l, 1, -1 do
        if value > arr[i] then break end
        temp = arr[i]
        arr[i] = value
        if (i + 1 < l) then arr[i + 1] = temp end
    end
end

-- distance function
local function distfunc(a, b)
    local dx, dy, dz = b.x - a.x, b.y - a.y, b.z - a.z
    return (dx * dx + dy * dy + dz * dz)
end

-- clamp
local max, min = math.max, math.min
local function clamp(v)
    return max(min(v, 1), 0)
end


local function worleyNoise(x, y, z, arraylen)
    local x = x or 0
    local y = y or 0
    local z = z or 0

    local input = ffi.new("vector3", x, y, z)

    local lastRandom, numPoints = 0, 0
    local randomDiff, featurePoint = ffi.new("vector3"), ffi.new("vector3")
    local cubeX, cubeY, cubeZ = 0, 0, 0

    distArray = {}
    for i = 1, arraylen or 1 do
        distArray[i] = 6666
    end

    local evalCubeX = floor(x)
    local evalCubeY = floor(y)
    local evalCubeZ = floor(z)

    for i = -1, 1 do
        for j = -1, 1 do
            for k = -1, 1 do
                cubeX = evalCubeX + i
                cubeY = evalCubeY + j
                cubeZ = evalCubeZ + k

                lastRandom = lcgRandom(hash(cubeX, cubeY, cubeZ))
                numPoints = probLookup(lastRandom)
                for l = 1, numPoints do
                    lastRandom = lcgRandom(lastRandom)
                    randomDiff.x = lastRandom / 0x100000000

                    lastRandom = lcgRandom(lastRandom)
                    randomDiff.y = lastRandom / 0x100000000

                    lastRandom = lcgRandom(lastRandom)
                    randomDiff.z = lastRandom / 0x100000000

                    featurePoint.x = randomDiff.x + cubeX
                    featurePoint.y = randomDiff.y + cubeY
                    featurePoint.z = randomDiff.z + cubeZ

                    insert(distArray, clamp(distfunc(featurePoint, input) * 2))
                end
            end
        end
    end

    return distArray
end

return worleyNoise
