block blockGet:
    let opt = options.getOpt("g", "get")
    
    var searchList: seq[string]
    var cat = "item"
    var key = "all"
    if opt.len > 0:
        # category
        cat = opt[0]
    if opt.len > 1:
        # key/column
        key = opt[1]
    if opt.len > 2:
        # search term(s)
        for item in opt[2..<opt.len]:
            searchList.add(item)
    
    if key == "name": key = "name_localized"
    if key == "description": key = "description_localized"
    if key == "gender": key = "gender_localized"
    
    var queryString: string
    
    if fileExists(fmt"queries/{cat}.sql"):
        queryString = readFile(fmt"queries/{cat}.sql")
    else:
        queryString = readFile(fmt"queries/default.sql")
        queryString = queryString.replace("__category__", cat)
    
    if cfg.getBool("replace") == false:
        queryString = queryString.replace("COALESCE(en_replacename.name, ", "COALESCE(")
    
    if key == "all":
        queryString = queryString.replace("__where__", "TRUE")
    else:
        # WHERE "colname" LIKE "%foo%" OR ...
        var str = ""
        for i in 0..<searchList.len:
            var search = searchList[i]
            
            # apply and convert wildcards to search string
            search.formatSearch(options.hasOpt("exact"))

            if i > 0:
                str &= "    OR\n    "
            str &= fmt""""__column__" LIKE "{search}" ESCAPE '\' --'"""
            str &= "\n"
            
        queryString = queryString.replace("__where__", str)
    
    let query_getMobNameFromKey = readFile("queries/getMobNameFromKey.sql")
    
    queryString = queryString.replace("__language__", language)
    queryString = queryString.replace("__column__", key)
    
    if options.hasOpt("showquery"):
        print queryString
    
    if options.hasOpt("template"):
        var rowIndex = 0
        for t in db.getData(queryString):
            db.expandItems(t, "Shop", "Likes", "Dislikes", "Furniture Required", "Equipped Helmet",
            "Equipped Armor", "Equipped Legs", "Texts", "Build Block", "Enchant", "Set Requirements")
        
            # expand furniture to get the item instead of interactable
            if t.hasKey("Furniture Required"):
                for item in t["Furniture Required"]:
                    db.expandItems(item, "Item")
            
            # expand crafting table stuff
            if t.hasKey("Type") and t["Type"].getStr == "Crafting Table":
                db.expandItems(t["Build Block"][0], "Crafting Table")
                # need this check for forgotten altar fake working table item
                if t["Build Block"][0]["Crafting Table"].elems.len > 0:
                    db.expandItems(t["Build Block"][0]["Crafting Table"][0], "Item List")
                    for item in t["Build Block"][0]["Crafting Table"][0]["Item List"]:
                        db.expandItems(item, "Product", "Recipe")
            
            if t.hasKey("Shop"):
                for item in t["Shop"]:
                    db.expandItems(item, "Product")
            
            if cat == "fish":
                db.expandLoot(t, "Loot")
                
                let itemKey = t["Key"].getStr
                var biomeKey: string
                if t["Is Chest"].getStr == "TRUE":
                    biomeKey = "Fish Chests"
                else:
                    biomeKey = "Fish"
                
                var w = fmt"""    "{biomeKey}" LIKE "%E_FISHS.{itemKey},%" COLLATE NOCASE"""
                let biomeData = db.getData("biome", fmt"{biomeKey}", fmt"E_FISHS.{itemKey},", w)
                t["biome"] = biomeData

            
            if cat == "item":
                # crafting
                let itemKey = t["Key"].getStr
                var w = fmt"""    l.key = "{itemKey}" COLLATE NOCASE"""
                let recipeData = db.getData("recipebyitem", "l.Key", itemKey, w)
                for recipe in recipeData:
                    db.expandItems(recipe, "Craft Table", "Product", "Recipe")
                    if recipe.hasKey("Craft Table") and recipe["Craft Table"].len > 0:
                        let node = recipe["Craft Table"][0]
                        db.expandItems(node, "Item", "Crafting Table")
                        
                        for r in recipe["Craft Table"][0]["Crafting Table"]:
                            db.expandItems(r, "Item List")
                        
                t["crafts"] = recipeData
                
                # sold by
                w = fmt"""    shop LIKE "%E_ITEMS.{itemKey},%" COLLATE NOCASE"""
                let shopData = db.getData("npc", "shop", fmt"E_ITEMS.{itemKey},", w)
                t["soldby"] = shopData
                
                # Dropped by
                let droppedBy = %* []
                
                # direct drops
                w = fmt"""    loot LIKE "%E_ITEMS.{itemKey},%" COLLATE NOCASE"""
                let dropData = db.getData("mob", "loot", fmt"E_ITEMS.{itemKey},", w)
                for mob in dropData:
                    if mob["Codex Unlockable"].getStr == "TRUE":
                        let mobName = mob["Name"].getStr
                        
                        if % mobName notin droppedBy:
                            droppedBy.add(% mobName)
                
                # item pool drops
                w = fmt"""    items LIKE "%E_ITEMS.{itemKey},%" COLLATE NOCASE"""
                let poolData = db.getData("item_pool", "items", fmt"E_ITEMS.{itemKey},", w)
                for pool in poolData:
                    let poolKey = pool["Key"].getStr
                    w = fmt"""    loot LIKE "%E_ITEM_POOLS.{poolKey},%" COLLATE NOCASE"""
                    let dropData = db.getData("mob", "loot", fmt"E_ITEM_POOLS.{poolKey},", w)
                    for mob in dropData:
                        if mob["Codex Unlockable"].getStr == "TRUE":
                            let mobName = mob["Name"].getStr
                            
                            if % mobName notin droppedBy:
                                droppedBy.add(% mobName)
                
                t["droppedby"] = droppedBy
            
                if t["Type"].getStr == "Fish" or t["Name"].getStr in ["Life Fish", "Mana Fish"]:
                    let biomes = %* []
                    
                    w = fmt"""    loot LIKE "%E_ITEMS.{itemKey},%" COLLATE NOCASE"""
                    let fishData = db.getData("fish", "loot", fmt"E_ITEMS.{itemKey},", w)[0]
                    let fishKey = fishData["Key"].getStr
                    
                    w = fmt"""    fish LIKE "%E_FISHS.{fishKey},%" COLLATE NOCASE"""
                    let biomeData = db.getData("biome", "fish", fmt"E_ITEMS.{fishKey},", w)
                    
                    for biome in biomeData:
                        let biomeName = biome["Name"].getStr
                        if % biomeName notin biomes and biomeName notin ["Ship"]:
                            biomes.add(% biomeName)

                    fishData["biomes"] = biomes
                    
                    t["fish"] = fishData
                
                # Set bonus stuff
                if t["Type"].getStr in ["Head", "Body", "Legs"]:
                    if t.hasKey("Set Requirements") and t["Set Requirements"].len > 0:
                        # Add basic data but don't duplicate the whole item itself
                        t["Set Requirements"].elems.insert(%* {"Key": % t["Key"], "Type": % t["Type"], "Name": % t["Name"]}, 0)
                    else:
                        let node = %* []
                        for key in db.getSetKeys(t["Key"].getStr):
                            if key == t["Key"].getStr:
                                # Add basic data but don't duplicate the whole item itself
                                node.elems.insert(%* {"Key": % t["Key"], "Type": % t["Type"], "Name": % t["Name"]}, 0)
                            else:
                                let node2 = db.getData("item", "key", key)[0]
                                node.elems.insert(%* node2, 0)
                                if node2.hasKey("Set Description") and node2["Set Description"].getStr != "":
                                    t["Set Description"] = % node2["Set Description"].getStr
                        t["Set Requirements"] = node
                
                w = fmt"""    product = "E_ITEMS.{itemKey}" COLLATE NOCASE"""
                let cookingRecipe = db.getData("cook", "product", fmt"E_ITEMS.{itemKey}", w)
                for item in cookingRecipe:
                    db.expandItems(item, "Ingredients", "Product")
                
                w = fmt"""    ingredients LIKE "%[E_ITEMS.{itemKey}]%" COLLATE NOCASE"""
                let cookingUsedToCook = db.getData("cook", "ingredients", fmt"[E_ITEMS.{itemKey}]", w)
                for item in cookingUsedToCook:
                    db.expandItems(item, "Ingredients", "Product")
                
                t["cooking_recipe"] = cookingRecipe
                t["cooking_usedtocook"] = cookingUsedToCook
                
#                        let fishKey = fishData["Key"].getStr
                
            let templateName = options.getOpt("template")[0]
            
            var text = loadTemplate(templateName)
            if text != "":
                var node = t
                
                resolveTemplate(text, node)
                
                print text
            elif fileExists(fmt"lua/plugins/" & templateName & ".lua"):
                let keys = "{\"" & t.getKeys.join("\",\"") & "\"}"
                
                luaExec(fmt"""
                plugin = require("lua/plugins/{templateName}")
                plugin.text = ""
                plugin.sep = plugin.sep or " "
                plugin.endLine = plugin.endLine or "\n\n"
                plugin.data = json.decode([===[{t}]===])
                plugin.keys = {keys}
                if plugin.init then plugin:init() end
                if plugin.build then plugin:build() end
                if plugin.post then plugin:post() end
                """)
                
                let sep = luaEval("return plugin.sep")
                let endLine = luaEval("return plugin.endLine")
                
                printSpecial(luaEval("return plugin.text"), sep=sep, endLine=endLine)
                
            
            rowIndex += 1
            if options.hasOpt("first"):
                break
            if options.hasOpt("limit"):
                let limit = parseInt(options.getOpt("limit")[0])
                if rowIndex+1 > limit:
                    break
        
        break blockGet
    
    var rows = db.get(queryString.sql)
    
    # used to track duplicates for -only option
    var allValues: HashSet[string]
    
    # used to track displayed results for -enumerate
    var nItems = 0
    
    var rowIndex = 0
    for row in mitems(rows):
        if row.hasKey("Name"):
            if "refMob" in row["Name"] and "E_MOBS." in row["Ref Mob"]:
                let rows = db.get(query_getMobNameFromKey.sql, row["Ref Mob"].replace("E_MOBS.", ""))
                if rows.len > 0:
                    row["Name"] = row["Name"].replace("{$refMob}", rows[0]["Name"])
        
        if options.hasOpt("list"):
            if row.hasKey("Name") and row.hasKey("ID"):
                print fmt"""{row["ID"]} {row["Name"]}"""
            elif row.hasKey("Key") and row.hasKey("ID"):
                print fmt"""{row["ID"]} {row["Key"]}"""
            else:
                let values = toSeq(row.values)[0]
                print fmt"""{values}"""
        else:
            if options.hasOpt("only"):
                discard
            elif options.hasOpt("code"):
                print "//--------------------------------------------------"
                print fmt"""// {row["ID"]} {row["Key"]}"""
                print "//--------------------------------------------------"
            elif row.hasKey("Name") and row.hasKey("ID"):
                print "----------------------------------------"
                print fmt"""{row["ID"]} {row["Name"]}"""
                print "----------------------------------------"
            elif row.hasKey("Key") and row.hasKey("ID"):
                print "----------------------------------------"
                print fmt"""{row["ID"]} {row["Key"]}"""
                print "----------------------------------------"
            
            if options.hasOpt("code"):
                if row.hasKey("Code"):
                    var text = row["Code"]
                    # normalize line breaks and rstrip each line
                    text = text.normalizeLines
                    # tabs to spaces
#                        text = text.replace("\t", "    ")
                    # escaped newlines to real newlines
                    text = text.replace("\\n", "\n")
                    # replace #$# with commas (end of line)
                    text = text.replace("#$#\n", ",\n")
                    # replace #$# and a space with comma and space
                    text = text.replace("#$# ", ", ")
                    # replace #$# with commas
                    text = text.replace("#$#", ", ")
                    # replace %$% with "
                    text = text.replace("%$%", "\"")
                    # normalize again after end of line marker handling
                    text = text.normalizeLines
                    
                    text = text.normalizeGml

                    print(text)
            else:
                for col, value in row.pairs:
                    if value == "" and not options.hasOpt("showemptyfields"):
                        discard
                    elif "_localized" in col or "_unlocalized" in col:
                        discard
                    else:
                        if options.hasOpt("only"):
                            if value in allValues:
                                discard
                            elif col.toLowerAscii == options.getOpt("only")[0].toLowerAscii:
                                allValues.incl(value)
                                print fmt"{value}"
                                nItems += 1
                        else:
                            print fmt"{col:<31} {value}"
                            nItems += 1
            if options.hasOpt("only"):
                discard
            else:
                echo ""
        rowIndex += 1
        if options.hasOpt("first"):
            break
        if options.hasOpt("limit"):
            let limit = parseInt(options.getOpt("limit")[0])
            if rowIndex+1 > limit:
                break
        
        if options.hasOpt("saveimages"):
            let opt = options.getOpt("saveimages")
            # todo: also check "Sprite", "Sprite Idle" etc
            
            var imageKey = ""
            var format = ""
            var w = 0
            var h = 0
            
            for o in opt:
                if o.split("x").len == 2 and o != "x":
                    if o.split("x")[0].isDecimal:
                        w = o.split("x")[0].parseInt
                    if o.split("x")[1].isDecimal:
                        h = o.split("x")[1].parseInt
                
                elif o == "wikiicon":
                    format = o
                elif o == "wikiiconrecipe":
                    format = o
                else:
                    imageKey = o
            
            imageKey = row.getFirstValid(imageKey, "Icon", "Sprite", "Sprite Idle", "sprite")
            let fromFile = getSpriteFile(imageKey)
            
            if fromFile != "":
                var toFile: string
                var name = row.getFirstValid("Name", "Key", "ID")
                
                toFile = fmt"output/{cat}/{name}.png" / ""
                
                createFolders("output" / cat)
                
                if format == "wikiicon":
                    toFile = fmt"output/{cat}/{name}_icon.png" / ""
                    h = 16
                elif format == "wikiiconrecipe":
                    toFile = fmt"output/{cat}/{name} (Recipe)_icon.png" / ""
                else:
                    toFile = fmt"output/{cat}/{name}_{cat.toLowerAscii}.png" / ""
                
                # output
                if format == "wikiiconrecipe":
                    makeRecipeIcon(fromFile, toFile)
                else:
                    if w == 0 and h == 0:
                        copyFile(fromFile, toFile)
                    else:
                        makeImage(fromFile, toFile, w, h)
    
    if options.hasOpt("enumerate"):
        print fmt"{nItems} results."
