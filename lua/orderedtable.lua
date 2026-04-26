-- ordered.lua

local Ordered = {}
local OrderedMT = {}

local keyStore = setmetatable({}, { __mode = "k" })

local function getKeys(self)
    return keyStore[self]
end

local function findIndex(keys, key)
    for i, k in ipairs(keys) do
        if k == key then
            return i
        end
    end
end

-- metatable

function OrderedMT.__newindex(self, key, value)
    local keys = getKeys(self)

    if value == nil then
        local idx = findIndex(keys, key)
        if idx then
            table.remove(keys, idx)
        end
        rawset(self, key, nil)
        return
    end

    if rawget(self, key) == nil then
        table.insert(keys, key)
    end

    rawset(self, key, value)
end

function OrderedMT.__index(self, key)
    return Ordered[key]
end

-- ordered iterator (works everywhere)

function Ordered.pairs(self)
    local i = 0
    local keys = getKeys(self)

    return function()
        i = i + 1
        local key = keys[i]
        if key ~= nil then
            return key, rawget(self, key)
        end
    end
end

-- methods

function Ordered:insert(index, key, value)
    local keys = getKeys(self)

    local old = findIndex(keys, key)
    if old then
        table.remove(keys, old)
        if old < index then
            index = index - 1
        end
    end

    table.insert(keys, index, key)
    rawset(self, key, value)
end

function Ordered:move(key, newIndex)
    local keys = getKeys(self)

    local old = findIndex(keys, key)
    if not old then return end

    table.remove(keys, old)

    if old < newIndex then
        newIndex = newIndex - 1
    end

    table.insert(keys, newIndex, key)
end

function Ordered:moveToFront(key)
    self:move(key, 1)
end

function Ordered:moveToBack(key)
    local keys = getKeys(self)
    self:move(key, #keys + 1)
end

function Ordered:moveBefore(key, other)
    local keys = getKeys(self)
    local idx = findIndex(keys, other)
    if idx then
        self:move(key, idx)
    end
end

function Ordered:moveAfter(key, other)
    local keys = getKeys(self)
    local idx = findIndex(keys, other)
    if idx then
        self:move(key, idx + 1)
    end
end

function Ordered:keys()
    return getKeys(self)
end

function Ordered:values()
    local keys = getKeys(self)
    local out = {}

    for i, k in ipairs(keys) do
        out[i] = rawget(self, k)
    end

    return out
end

function Ordered:ipairs()
    local i = 0
    local keys = getKeys(self)

    return function()
        i = i + 1
        local key = keys[i]
        if key ~= nil then
            return i, rawget(self, key)
        end
    end
end

-- constructor
--
-- supports flattened pairs as arguments:
--
-- local t = ordered(
--     "foo", 1,
--     "bar", 2
-- )
function Ordered.new(...)
    local t = {}
    setmetatable(t, OrderedMT)

    local keys = {}
    keyStore[t] = keys

    local args = { ... }
    local n = #args

    -- support ordered({ "a",1,"b",2 })
    if n == 1 and type(args[1]) == "table" then
        args = args[1]
        n = #args
    end

    for i = 1, n, 2 do
        local k = args[i]
        local v = args[i + 1]

        if k == nil then
            break
        end

        -- IMPORTANT: rawset only (prevents __newindex duplication)
        rawset(t, k, v)
        keys[#keys + 1] = k
    end

    return t
end

function Ordered._new(init)
    local t = {}

    keyStore[t] = {}
    setmetatable(t, OrderedMT)

    if init then
        for _, pair in ipairs(init) do
            t[pair[1]] = pair[2]
        end
    end

    return t
end

setmetatable(Ordered, {
    __call = function(_, ...)
        return Ordered.new(...)
    end
})

return Ordered