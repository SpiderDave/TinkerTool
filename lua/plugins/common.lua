function formatMoney(text)
    if not text then return "?" end
    
    local value = tonumber(text)
    local coins = {"Plat", "Gold", "Silver", "Copper"}
    local ret = ""
    
    for i, v in ipairs(coins) do
        local n = math.floor(value / (100^(4-i)) % 100)
        if n > 0 then
            ret = ret .. string.format("%s %s ", n, v)
        end
    end
    ret = util.trim(ret)
    
    return ret
end

function formatMoney2(text)
    if not text then return "?" end
    
    local value = tonumber(text)
    local ret = ""
    
    for i = 1, 4 do
        local n = math.floor(value / (100^(4-i)) % 100)
        ret = ret .. string.format("|%s", n)
    end
    ret = util.trim(ret)
    
    return ret
end

function parseRecipeString(s)
    local t = ordered()
    for _, item in ipairs(util.split(s, "],[")) do
        item = item:replace("[[", "")
        item = item:replace("]]", "")
        item = item:replace("E_ITEMS.", "")
        
        local k,v = util.unpack(util.split(item, ","))
        t[k] = {key = k, amount = tonumber(v)}
    end
    return t
end

function parseRewardString(s)
    local t = ordered()
    for _, item in ipairs(util.split(s, "],[")) do
        item = item:replace("[[", "")
        item = item:replace("]]", "")
        item = item:replace("E_ITEMS.", "")
        
        local key, dummy, amountMin, amountMax, dbType = util.unpack(util.split(item, ","))
        t[key] = {
            key = key,
            amount = {
                min = tonumber(amountMin),
                max = tonumber(amountMax),
            },
            dbType = dbType,
        }
    end
    return t
end


--returns craft table name and type ("station" or "npc")
function getCraftTableName(craftTable)
    if #craftTable > 0 or craftTable.Name then
        local key = craftTable.Key
        if key == "halloween_craft" then
            return "The Skeleton", "npc"
        elseif key == "tailor_craft" then
            return "The Stylist", "npc"
        elseif key == "laboratory_forge" then
            return "Laboratory Forge", "station"
        elseif key == "kl_altar" then
            return "Forgotten Altar", "station"
        else
            if craftTable[1] and craftTable[1].Item[1].Name then
                return craftTable[1].Item[1].Name, "station"
            elseif craftTable.Name then
                return craftTable.Name, "station"
            end
            return "?", "?"
        end
    else
        return "By Hand", "station"
    end
end

function stripCodes(text)
    text = text:gsub("%[#%w+%]", "")
    return text
end


