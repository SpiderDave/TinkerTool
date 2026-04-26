math.randomseed(os.time())
math.random() math.random() math.random()

-- Patch type for json.null handling
_type = type
type = function(v)
    if v == json.null then
        return "null"
    else
        return _type(v)
    end
end

-- includes
json=require "json"
util=require "util"
ordered=require "orderedtable"