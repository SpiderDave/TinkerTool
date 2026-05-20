-- ToDo / Issues:
--   * Set items with multiple combinations only show one
--   * Crafting sections don't show items in correct order (need to cross reference with craft_table and recipes)
--   * Transmutation cube recipes
--   * Chest information

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
        "name", item.Name,
        "type", item.Type,
        "duration", item["Consume Duration"],
        "description", item.Description,
        "armor", item["Damage Reduction"],
        "damage", item.Damage,
        "damagetype",item["Damage Type"]:gsub("E_DAMAGE_TYPE%.", ""),
        "crit", item["Crit Chance"],
        "tool", item.Power,
        "axe", item["Axe Damage"],
        "pickaxe", item["Pickaxe Damage"],
        "speed", item.Speed,
        "knockback", item.Knockback,
        "fishingmastery", item["Fishing Mastery"],
        "material", "",
        "buy", formatMoney(item.Buy),
        "sell", formatMoney(item.Sell),
        "manause", item["Mana Consumption"],
        "hp", "",
        "powerrequired", "",
        "stack", item["Quantity Max"],
        "itemid", item.ID,
        "droptier", item["Drop Text Color"],
    "","")
    
    -- set up category
    local category = item.Type
    
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
    
    -- only show duration for usable items with buffs
    if (item.Type ~= "Usable") or 
       (item["Consume Buffs"] == "") or
       (item["Consume Duration"] == "0") then infobox.duration = nil
    end
    
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
    
    -- don't show power required for floor
    if item.Type == "Floor" then
        infobox.powerrequired = nil
    end
    
    -- Rune description
    if item.Enchant and #item.Enchant >0 then
        local enchant = item.Enchant[1]
        infobox.description = string.format('<span class="enchant">%s<br><br>Level 1/%s<br></span>Rune %02d', enchant.Description, enchant["Max Level"], tonumber(enchant.ID))
        infobox.description = infobox.description:gsub("{amount}", "[?-?]")
    end
    
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
        
        infobox.description = string.format("{{set_bonus|%s|%s|%s|%s}}", t[1], t[2], t[3], item["Set Description"]) .. infobox.description
    end
    
    infobox.description = infobox.description:gsub("/n", "<br>")
    
    -- description for fish will be filled automatically
    if item.Type == "Fish" then
        infobox.description = nil
    end
    
    -- set up sections
    local sections = ordered()
    sections.infobox = "" -- placeholder to make sure it's first in list
    sections.clear = "{{clear}}\n"
    
    -- Dropped By
    if #item.droppedby > 0 then
        sections.droppedby = '==Dropped By==\n{| class="table"\n|-\n! Enemy\n'
        
        -- alphabetical order
        table.sort(item.droppedby)
        
        for _,v in ipairs(item.droppedby) do
            sections.droppedby = sections.droppedby .. string.format("|-\n| {{mob|name=%s}}\n", v)
        end
        sections.droppedby = sections.droppedby .. "|}\n\n"
    end
    
    -- Sold By
    if #item.soldby > 0 then
        sections.soldBy = '==Sold By==\n{| class="shop"\n|-\n! Merchant !! Item !! Cost !! Availability\n'
        for _,npc in ipairs(item.soldby) do
            local availability = "Always available"
            if npc.Name == "The Travelling Merchant" or npc.Name == "Michael" then availability = "Randomly available" end
            sections.soldBy = sections.soldBy .. string.format("|-\n| {{npc|name=%s}} || {{item_simple|name=%s}} || {{money|%s}} || %s\n", npc.Name, item.Name, formatMoney(item.Buy), availability)
        end
        sections.soldBy = sections.soldBy .. "|}\n\n"
    else
        infobox.buy = nil
    end
    
    -- Fishing
    if item.fish then
        table.sort(item.fish.biomes)
        sections.fishing = string.format("==Fishing==\n{{fishing_table| %s: %s}}\n\n", item.Name, util.join(item.fish.biomes, ", "))
    end
    
    -- Cooking
    if #item["cooking_recipe"] > 0 or #item["cooking_usedtocook"] > 0 then sections.cooking = "==Cooking==\n" end
    
    for _, cookType in ipairs({"cooking_recipe", "cooking_usedtocook"}) do
        if #item[cookType] > 0 then
            local title
            if cookType == "cooking_recipe" then title = "Recipe" else title = "Used to Cook" end
            local txt = string.format('{| class="crafting cooking"\n|+ %s\n|-\n! Result !! Ingredients\n', title)
            for _, entry in ipairs(item[cookType]) do
                txt = txt .. string.format("|-\n| {{item_simple|name=%s}} || ", entry.Product[1].Name)
                if entry.Ingredients[1].Name == entry.Ingredients[2].Name then
                    txt = txt .. string.format("2{{item_simple|name=%s}}\n", entry.Ingredients[1].Name)
                else
                    txt = txt .. string.format("1{{item_simple|name=%s}}<br>1{{item_simple|name=%s}}\n", entry.Ingredients[1].Name, entry.Ingredients[2].Name)
                end
            end
            txt = txt .. "|}\n\n"
            sections[cookType] = txt
        end
    end
    
    -- Crafting
    -- Recipe and Used to Craft
    sections.crafting = '==Crafting==\n'
    for _, craftType in ipairs({"recipe", "used_to_craft"}) do
        local nItems = 0
        local title
        if craftType == "recipe" then title = "Recipe" else title = "Used to Craft" end
        
        --Recipe (Requires {{item|name=NAME (Recipe)}})
        
        sections[craftType] = string.format('{| class="crafting %s"\n|+ %s\n|-\n! Result !! Ingredients !! Crafting Station\n', craftType, title)
        
        local craftsByStation = ordered()
        for _, craft in ipairs(item.crafts) do
            craftsByStation[getCraftTableName(craft["Craft Table"])] = {}
        end
        
        for i, craft in ipairs(item.crafts) do
            if (craftType == "recipe" and craft.Product_unexpanded == string.format("E_ITEMS.%s", item.Key)) or
               (craftType == "used_to_craft" and string.find(craft.Recipe_unexpanded, string.format("E_ITEMS.%s,", item.Key))) then
                if craft.Product_unexpanded ~= "" then
                    if craftType == "used_to_craft" then infobox.material = "true" end
                    local recipe = parseRecipeString(craft.Recipe_unexpanded)
                    for i,v in ipairs(craft.Recipe) do
                        recipe[v.Key].name = v.Name
                    end
                    
                    local craftTableName, craftTableType = getCraftTableName(craft["Craft Table"])
                    
                    local pAmount = craft["Product Quantity"]
                    if pAmount == "1" then pAmount = "" end
                    
                    local line = string.format("|-\n| %s{{item_simple|name=%s}} || ", pAmount, craft.Product[1].Name)
                    local n = 0
                    for k,v in ordered.pairs(recipe) do
                        if n>0 then line = line .. "<br>" end
                        line = line .. string.format("%s{{item_simple|name=%s}}",v.amount, v.name)
                        n=n+1
                    end
                    craftsByStation[craftTableName][#craftsByStation[craftTableName]+1] = line
                    nItems = nItems + 1
                end
            end
        end
        
        for station, lines in ordered.pairs(craftsByStation) do
            for i, line in ipairs(lines) do
                sections[craftType] = sections[craftType] .. line
                if i == 1 then
                    if #lines == 1 then
                        sections[craftType] = sections[craftType] .. string.format(' || {{station|name=%s}}\n', station)
                    else
                        sections[craftType] = sections[craftType] .. string.format('\n| rowspan = "%s" | {{station|name=%s}}\n', #lines, station)
                    end
                else
                    sections[craftType] = sections[craftType] .. "\n"
                end
            end
        end
        
        sections[craftType] = sections[craftType] .. "|}\n\n"
        if nItems == 0 then sections[craftType] = nil end
    end
    
    -- Crafting Table crafts
    if item.Type == "Crafting Table" and item["Build Block"][1]["Crafting Table"][1] then
        local nItems = 0
        sections.craftingTable = string.format('{| class="crafting %s"\n|+ Used to Craft\n|-\n! Result !! Ingredients !! Crafting Station\n', "used_to_craft")
        
        for i, craft in pairs(item["Build Block"][1]["Crafting Table"][1]["Item List"]) do
            if craft.Product_unexpanded ~= "" then
                local recipe = parseRecipeString(craft.Recipe_unexpanded)
                
                for i,v in ipairs(craft.Recipe) do
                    recipe[v.Key].name = v.Name
                end
                
                local pAmount = craft["Product Quantity"]
                if pAmount == "1" then pAmount = "" end
                
                sections.craftingTable = sections.craftingTable .. string.format("|-\n| %s{{item_simple|name=%s}} || ", pAmount, craft.Product[1].Name)
                
                local n = 0
                for k,v in ordered.pairs(recipe) do
                    if n>0 then sections.craftingTable = sections.craftingTable .. "<br>" end
                    sections.craftingTable = sections.craftingTable ..  string.format("%s{{item_simple|name=%s}}",v.amount, v.name)
                    n=n+1
                end
                if nItems == 0 then
                    local craftTableName, craftTableType = getCraftTableName(item)
                    sections.craftingTable = sections.craftingTable .. string.format('\n | rowspan="9999" | {{%s|name=%s}}\n', craftTableType, craftTableName)
                else
                    sections.craftingTable = sections.craftingTable .. "\n"
                end
                
                nItems = nItems + 1
            end
        end
        sections.craftingTable = sections.craftingTable .. "|}\n\n"
        sections.craftingTable = sections.craftingTable:replace('rowspan="9999"', string.format('rowspan="%s"', nItems))
        
        if nItems == 0 then sections.craftingTable = nil end
    end
    
    -- no crafting entries, remove heading
    if not (sections.recipe or sections.used_to_craft or sections.craftingTable) then sections.crafting = nil end
    
    -- Infobox
    sections.infobox = "{{item_infobox\n"
    for k,v in ordered.pairs(infobox) do
        if (v or "") ~= "" then
            if type(v) == "string" then v = util.trim(v) end
            sections.infobox = sections.infobox .. string.format("  | %s=%s\n", k, v)
        end
    end
    sections.infobox = sections.infobox .. "}}\n\n"
    
    -- Category
    sections.category = string.format("[[category:%s]]\n[[category:Items]]\n", category)
    
    local text = ""
    for section, v in ordered.pairs(sections) do
        if v then
            text = text .. v
        end
    end
    
    -- prevent a stray clear if there's nothing to clear
    if not text:find("{{clear}}\n==") then text = text:replace("{{clear}}\n", "") end
    
    -- set the text to be returned by the template
    self.text = util.trim(text)
    
--    self.text = ""
--    print(item)
end

return plugin