local plugin = {
    sep = ".",
    endLine = "\n"
}

function plugin:build()
    local npc = self.data

    local infobox = ordered(
        "type", "[[NPC]]",
        "environment", " ",
        "requirements", "",
        "likes", "",
        "dislikes", ""
    )
    
    if #npc.Shop > 0 then infobox.type = infobox.type .. ", [[Merchant]]" end
    
    local keys = {
        ["Furniture Required"] = "requirements",
        Likes = "likes",
        Dislikes = "dislikes",
    }
    
    for _,field in ipairs({"Furniture Required", "Likes", "Dislikes"}) do
        local txt = ""
        for i,v in pairs(npc[field] or {}) do
            if i>1 then txt = txt .. "<br>" end
            txt = txt .. string.format("{{item|name=%s}}", v.Name or v.Item[1].Name)
        end
        infobox[keys[field]] = txt
    end
    
    local text = "{{NPC_Infobox\n"
    for k,v in ordered.pairs(infobox) do
        if v ~= "" then
            if type(v) == "string" then v = util.trim(v) end
            text = text .. string.format("  | %s=%s\n", k, v)
        end
    end
    text = text .. "}}\n"
    
    text = text .. string.format("{{npcquote\n  | text=%s\n  | speaker=%s\n}}\n", util.choose(npc.Texts), npc.Name)
    text = text .. string.format("{{npc|name=%s}} is an [[NPC]].\n\n", npc.Name)
    
    if #npc.Shop > 0 then
        text = text .. '{{clear}}\n==Shop==\n{| class="shop"\n|-\n! Merchant !! Item !! Cost !! Availability\n|-\n'
        text = text .. string.format('| rowspan = "%s" | {{npc|name=%s}}\n', #npc.Shop, npc.Name)
        for i,item in pairs(npc.Shop) do
            if i~=1 then text = text.. "|-\n" end
            local price = formatMoney(item.Buy)
            if item.Product then
                item.Name = string.format("%s (Recipe)", item.Product[1].Name)
                price = "1 Gold"
            end
            
            text = text.. string.format("| {{item|name=%s}} || {{money|%s}}\n", item.Name, price)
            if i==1 then
                local availability = "Always available"
                if npc.Name == "The Travelling Merchant" or npc.Name == "Michael" then availability = "Randomly available" end
                
                text = text .. string.format('| rowspan = "%s" | %s\n', #npc.Shop, availability)
            end
        end
        text = text.. "|}\n\n"
        text = text .. "[[category:npc]]\n"
        text = text .. "[[category:merchant]]\n"
    else
        text = text .. "[[category:npc]]\n"
    end
    
    
    self.text = text
end

return plugin