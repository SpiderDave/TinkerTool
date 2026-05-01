local plugin = {
    sep = ".",
    endLine = "\n"
}

function plugin:build()
    local item = self.data
    
    -- fix spelling of Accessory
    if item.Type == "Accesory" then item.Type = "Accessory" end
    
    -- set up infobox
    local infobox = ordered(
        "ID", item.ID,
        "名称", item.Name,
        "种类", item.Type,
        "作为材料", "false",
        "描述", item.Description,
        "购买途径", "",
        "购买价格", string.format("{{金币%s}}", formatMoney2(item.Buy)),
        "出售价格", string.format("{{金币%s}}", formatMoney2(item.Sell)),
        "合成方式", "",
        "用于合成", "",
        "游戏版本", "",
    "","")
    
    -- filter some values when they are 0 or default
    local filter = {
        stack = "1",
        droptier = "Normal",
        manause = "0",
        axe = "0",
        pickaxe = "0",
    }
    for k,v in pairs(filter) do
        if infobox[k] == v then infobox[k] = nil end
    end
    
    -- filter combat stuff based on item type
    for _,v in ipairs({"Accessory", "Etc" , "Usable", "Floor",
                       "Building", "Pet" , "Fish", "Summon",
                       "Ingredient", "Storage", "Currency",
                       "Crafting Table", "Fishing Rod", "Map",
                       "Rune", "Hook", "Mount", "Cable", "Spice",
                       "Recipe",}) do
        if item.Type == v then
            for _,key in ipairs({"damage", "damagetype", "armor", "crit", "speed", "knockback"}) do
                infobox[key] = nil
            end
        end
    end
    
    if item.Type ~= "Usable" then infobox["Consume Duration"] = nil end
    
    -- non-tools don't list tool tier
    if item.Type ~= "Tool" then infobox.tool = nil end
    
    -- tools don't list knockback
    if item.Type == "Tool" then infobox.knockback = nil end
    
    -- don't list offensive stats on armor and consolidate category
    if item.Type == "Head" or item.Type == "Body" or item.Type == "Legs" then
        category = "Armor"
        for _,key in ipairs({"damage", "damagetype", "crit", "speed", "knockback"}) do
            infobox[key] = nil
        end
    end
    
    -- don't list armor on weapons
    if item.Type == "Weapon" or item.Type == "Throwable" or item.Type == "Tool" or item.Type == "Ammo" then
        infobox.armor = nil
    end
    
    -- don't display speed on ammo
    if item.Type == "Ammo" then
        infobox.speed = nil
    end
    
    -- get hp and required tool tier for placed objects
    if item["Build Block"] and #item["Build Block"] >0 then
        infobox.hp = item["Build Block"][1].HP
        infobox.powerrequired = item["Build Block"][1]["Power Required"]
    end
    
    -- Rune description
    if item.Enchant and #item.Enchant >0 then
        local enchant = item.Enchant[1]
        infobox["描述"] = string.format('<span class="enchant">%s<br><br>Level 1/%s<br></span>Rune %02d', enchant.Description, enchant["Max Level"], tonumber(enchant.ID))
        infobox["描述"] = infobox["描述"]:gsub("{amount}", "[?-?]")
    end
    
    infobox["描述"] = infobox["描述"]:gsub("/n", "<br>")
    
    -- only works on Head item
    if item["Set Description"] ~= "" then
        local t = {}
        for _, part in pairs({"Head", "Body", "Legs"}) do
            if item.Type == part then
                t[#t+1] = item.Name
            else
                for k,v in pairs(item["Set Requirements"]) do
                    if v.Type == part then
                        t[#t+1] = v.Name
                    end
                end
            end
        end
        
        for i = 1,3 do
            t[i] = t[i] or ""
        end
        
        infobox["描述"] = string.format("{{set_bonus|%s|%s|%s|%s}}<br>", t[1], t[2], t[3], item["Set Description"]) .. infobox["描述"]
    end
    
    local text = ""
    
    if #item.soldby == 0 then
        infobox["购买价格"] = nil
    end
    
    for i, craft in pairs(item.crafts) do
        if string.find(craft.Recipe_unexpanded, string.format("E_ITEMS.%s,", item.Key)) then
            if craft.Product_unexpanded ~= "" then
                infobox["作为材料"] = "true"
            end
        end
    end
    
    -- build the infobox
    local infobox_text = "{{配饰图鉴\n"
    for k,v in ordered.pairs(infobox) do
        if (v or "") ~= "" then
            if type(v) == "string" then v = util.trim(v) end
            infobox_text = infobox_text .. string.format("  | %s=%s\n", k, v)
        end
    end
    infobox_text = infobox_text .. "}}\n"
    
    -- add the infobox to the top
    text = infobox_text .. text
    
    self.text = text
end

return plugin