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

json = require "json"
util = require "util"

_print = print
print = util.print
printf = util.printf
choose = util.choose

ordered = require "orderedtable"
require "plugins.common"

string.replace = replace