-- ToDo / Issues:
--   * Quest rewards may not work with nested item pools (not sure if this is ever done)

local plugin = {
    sep = ".",
    endLine = "\n"
}

function plugin:build()
    local npc = self.data

    local infobox = ordered(
        "names", util.join(npc.Names, ", "),
        "type", "[[NPC]]",
        "environment", " ",
        "requirements", "",
        "likes", "",
        "dislikes", ""
    )
    
    -- If the first name is an exact match then don't list names.
    if npc.Names[1] == npc.Name then
        infobox:remove("names")
    end
    
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
    end
    
    if #npc.Quests > 0 then
        local questText = "==Quests==\n"
        for _, quest in ipairs(npc.Quests) do
            questText = questText .. '<div class="quest">\n;Quest\n'
            questText = questText .. string.format(":{{npc|name=%s|icononly=true}} %s\n", npc.Name, quest.Title)
            questText = questText .. string.format(':<span class="title">%s</span>\n', stripCodes(quest.Description))
            questText = questText .. string.format(";%s\n", quest.data.type.text)
            for _, entry in ipairs(quest.data.entries) do
                local db = quest.data.type.db
                if db == "npc" or db == "buff" or db == "interactable" then entry.amount = nil end
                local template = string.format("{{%s|name=%s}}", db, entry.name or entry.key)
                if db == "item" then
                    template = string.format("{{item_simple|name=%s}}", entry.name or entry.key)
                end
                if db == "interactable" then
                    if entry.name then
                        template = string.format("{{item_simple|name=%s}}", entry.name)
                    else
                        template = entry.key
                    end
                end
                
                if db == "buff" then template = string.format("{{%s|%s}}", db, entry.name or entry.key) end
                
                if entry.amount then
                    questText = questText .. string.format(":%s%s\n", entry.amount, template)
                else
                    questText = questText .. string.format(":%s\n", template)
                end
            end
            if quest.data.total then
                questText = questText .. string.format(";Total Required\n:%s\n", quest.data.total)
            end
            
            if #quest.Reward > 0 then
                if #quest.Reward > 1 then
                    questText = questText .. ";Rewards\n"
                else
                    questText = questText .. ";Reward\n"
                end
                for _, reward in ordered.pairs(parseRewardString(quest.Reward_unexpanded)) do
                    for _, item in ipairs(quest.Reward) do
                        if item.Key == reward.key then
                            if reward.dbType == "item_pool" then
                                questText = questText .. string.format(":One of:\n", item.Name)
                                for _, reward2 in ordered.pairs(parseRewardString(item.Items_unexpanded)) do
                                    for _, item in ipairs(item.Items) do
                                        if item.Key == reward2.key then
                                            if reward.amount.min == reward.amount.max then
                                                if reward.amount.min == 1 then
                                                    questText = questText .. string.format("::{{item_simple|name=%s}}\n", item.Name)
                                                else
                                                    questText = questText .. string.format("::%s{{item_simple|name=%s}}\n", reward.amount.min, item.Name)
                                                end
                                            else
                                                questText = questText .. string.format("::%s-%s{{item_simple|name=%s}}\n", reward.amount.min, reward.amount.max, item.Name or item.Key or "?")
                                            end
                                        end
                                    end
                                end
                            end
                            if reward.dbType == "item" then
                                if reward.amount.min == reward.amount.max then
                                    if reward.amount.min == 1 then
                                        questText = questText .. string.format(":{{item_simple|name=%s}}\n", item.Name)
                                    else
                                        questText = questText .. string.format(":%s{{item_simple|name=%s}}\n", reward.amount.min, item.Name)
                                    end
                                else
                                    questText = questText .. string.format(":%s-%s{{item_simple|name=%s}}\n", reward.amount.min, reward.amount.max, item.Name or item.Key or "?")
                                end
                            end
                        end
                    end
                end
            end
            questText = questText .. '</div>\n\n'
        end
        text = text .. questText
    end
    
    text = text .. "[[category:npc]]\n"
    if #npc.Shop > 0 then
        text = text .. "[[category:merchant]]\n"
    end
    
    self.text = text
end

return plugin