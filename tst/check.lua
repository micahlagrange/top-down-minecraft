-- A tiny test helper: T.test(name, fn), T.ok, T.eq, then T.done() exits
-- non-zero when anything failed. Lua 5.1 compatible.

local T = { failed = 0, passed = 0 }

function T.ok(cond, msg)
    if not cond then error(msg or 'expected true', 2) end
end

function T.eq(a, b, msg)
    if a ~= b then
        error((msg and msg .. ': ' or '') .. 'expected ' .. tostring(b) .. ', got ' .. tostring(a), 2)
    end
end

function T.test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        T.passed = T.passed + 1
        print('  ok   ' .. name)
    else
        T.failed = T.failed + 1
        print('  FAIL ' .. name .. '\n       ' .. tostring(err))
    end
end

function T.done()
    print(string.format('  %d passed, %d failed', T.passed, T.failed))
    os.exit(T.failed > 0 and 1 or 0)
end

return T
