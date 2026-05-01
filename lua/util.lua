local util = {}

local _print = _print or print

util.unpack = table.unpack or unpack

function util.writeToFile(path, data)
    local file = io.open(path, "wb")
    file:write(data)
    file:close()
end

function util.getFileContents(path)
--    local file = io.open(path,"rb")
--    if file==nil then return nil end
--    io.input(file)
--    ret=io.read('*a')
--    io.close(file)
--    return ret

    local file = io.open(path, "rb")
    local contents = file:read( "*a" )
    file:close()
    return contents
end

function util.getFileLines(filename)
   local lines = {}
   for line in io.lines(filename) do
       
       line = line:gsub('\r', ''):gsub('\n', '')
       
       lines[#lines+1] = line
   end
   return lines
end

function util.fileExists(filename)
   local f=io.open(filename,"r")
   if f~=nil then io.close(f) return true else return false end
end

function util.split(s, delim, max)
    assert (type (delim) == "string" and string.len (delim) > 0,
          "bad delimiter")
    assert(max == nil or max >= 1)
    local start = 1
    local t = {}
    local nSplits = 0
    while true do
    if max then
        if nSplits>= max then break end
    end
    local pos = string.find (s, delim, start, true) -- plain find
    if not pos then
      break
    end
    nSplits=nSplits+1
    table.insert (t, string.sub (s, start, pos - 1))
    start = pos + string.len (delim)
    end
    table.insert (t, string.sub (s, start))
    return t
end

function util.join(t, delim)
    return table.concat(t, delim)
end

function util.trim(s)
    --if type(s)~="string" then return tostring(s) end
    if not s then return end
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function util.ltrim(s)
    return (s:gsub("^%s*", ""))
end

function util.rtrim(s)
    local n = #s
    while n > 0 and s:find("^%s", n) do n = n - 1 end
    return s:sub(1, n)
end

function util.copyFile(fromFile, toFile)
    local data = util.getFileContents(fromFile)
    
    if not data then
        print("Error")
        return
    end
    
    local file = io.open(toFile, "wb")
    if not file then
        print("could not create file " .. toFile)
        return
    end
    file:write(data)
    file:close()
    
    if not util.fileExists(toFile) then
        print("could not write data")
    end
end

function util.contains(t, value)
    for _, v in pairs(t) do
        if v == value then return true end
    end
    return false
end

function util.anyIn(t, values)
    for _, v in ipairs(values) do
        for _, v2 in pairs(t) do
            if v2 == v then
                return true
            end
        end
    end

    return false
end

function util.startsWith(haystack, needle)
    return (haystack:find(needle, 1, true) == 1)
end

function util.endsWith(haystack, needle)
    return haystack:sub(-#needle) == needle
end


function util.printTable(t, indent)
    local out = ""
    indent = indent or 0
    local ind = string.rep(" ", indent*4)
    for k,v in pairs(t) do
        if type(v) == "string" then
            out=out..string.format('%s%s = "%s",\n', ind, k, v)
        elseif type(v) == "nil" or type(v) == "boolean" or type(v) == "number" then
            out=out..string.format('%s%s = %s,\n', ind, k, v)
        elseif type(v) == "function" then
            out=out..string.format('%s%s(),\n', ind, k)
        elseif type(v) == "table" then
            out=out..string.format('%s%s = {\n%s%s},\n', ind, k, util.printTable(v, indent+1), ind)
        else
            out=out..string.format("%s%s = (%s),\n", ind, k, type(v))
        end
    end
    return out
end

function util.printable(v)
    if type(v) == "string" then
        return v
    elseif type(v) == "nil" or type(v) == "boolean" or type(v) == "number" then
        return string.format('%s', v)
    elseif type(v) == "function" then
        return "function()"
    elseif type(v) == "table" then
        return "\n{\n" .. util.printTable(v, 1) .. "}"
    else
        return string.format("(%s)", type(v))
    end
end

function util.print(...)
    local out = ""
    local args = {...}
    
    for i, v in ipairs({...}) do
        if i>1 then out = out .. " " end
        out = out .. util.printable(v)
    end
    
    _print(out)
end

function util.printf(...)
    _print(string.format(...))
end

function util.choose(t, allKeys)
    if allKeys then
        -- use all keys
        local keys = {}
        for k,v in pairs(t) do
            table.insert(keys, k)
        end
        local keyName = keys[math.random(#keys)]
        return t[keyName], keyName
    else
        -- use one-based numerical keys only (typical lua array)
        return t[math.random(#t)]
    end
end

return util
