import
    os,
    strutils,
    sequtils,
    tables,
    json,
    strformat
    
import
    formats,
    jsontools

# --- Types ---
type
  PlayerSave* = object
    slot*: int = 0
    data*: seq[JsonNode]

  SetterProc* = proc(ps: var PlayerSave, value: JsonNode)

# --- Setters table ---
var setters*: Table[string, SetterProc] = initTable[string, SetterProc]()

# --- Utility to set a field inside data ---
proc setField*(ps: var PlayerSave, idx: int, field: string, value: JsonNode) =
    if idx >= ps.data.len:
        ps.data.setLen(idx + 1)
        ps.data[idx] = %*{}
    if ps.data[idx].kind != JObject:
        ps.data[idx] = %*{}
    ps.data[idx][field] = value

# --- Register normal field setter ---
setters["maxHp"] = proc(ps: var PlayerSave, value: JsonNode) =
  setField(ps, 2, "hpMax", value)

# --- Register cheats setter with arbitrary side effects ---
setters["cheats"] = proc(ps: var PlayerSave, value: JsonNode) =
    if value.getBool:
        setField(ps, 2, "hpMax", %1000)
        setField(ps, 2, "hpCurrent", %1000)
        # could also update undo data, flags, etc.
    else:
        setField(ps, 2, "hpMax", %500)
        setField(ps, 2, "hpCurrent", %500)

# --- Operators ---
proc `[]=`*[T](ps: var PlayerSave, key: string, value: T) =
    # Generic setter: converts any Nim type to JsonNode
    let jvalue = % value

    if setters.hasKey(key):
        setters[key](ps, jvalue)
    else:
        for i in 0..<ps.data.len:
            if ps.data[i].kind == JObject and ps.data[i].hasKey(key):
                setField(ps, i, key, jvalue)
                return

proc `[]`*(ps: PlayerSave, key: string): JsonNode =
    case key
    of "version":
        return ps.data[0]
    of "maxHp":
        if ps.data.len > 2 and ps.data[2].hasKey("hpMax"):
            return ps.data[2]["hpMax"]
        else:
            return % 0
    else:
        for i in 0..<ps.data.len:
            if ps.data[i].kind == JObject and ps.data[i].hasKey(key):
                return ps.data[i][key]
        return % 0
#    if ps.data.len > 0 and ps.data[2].hasKey(key):
#      return ps.data[2][key]
#    else:
#      return % 0

let npcShopIds* = @[
    0,      # The Guide
    1,      # The Blacksmith
    3,      # The Merchant
    5,      # The Bard
    6,      # The Witch
    8,      # The Miner
    9,      # The Farmer
    10,     # The Carpenter
    11,     # The Skeleton
    12,     # The Chef
    13,     # The Fisherman
    14,     # The Summoner
    15,     # The Electrician
    18,     # The Stylist
    21,     # The Cartographer
    26,     # The Nurse
    28,     # The Robot
    29,     # The Penguin
    30,     # The Enchantress
]

let shopOrder* = %*
    [
    # The Guide
    1708,   # Portable Guide
    222,    # Guide Suit
    223,    # Guide Pants
    
    # The Blacksmith
    39,     # Copper Ore
    37,     # Iron Ore
    38,     # Gold Ore
    62,     # Spider Ore
    301,    # Serpentinite Ore
    650,    # Bloody Ore
    344,    # Spectrite Ore
    385,    # Coralite Ore
    545,    # Solarite Ore
    546,    # Lunarite Ore
    1499,   # Molten Ore
    1701,   # Blacksmith Blessing
    226,    # Blacksmith Shirt
    227,    # Blacksmith Apron
    
    # The Merchant
    80,     # Flippers
    879,    # Poison Arrow
    1145,   # Bouncing Arrow
    961,    # Beetle Arrow
    398,    # Thunder Arrow
    397,    # Coral Arrow
    159,    # Ghost Arrow
    1725,   # Pocket Merchant
    229,    # Merchant Blouse
    230,    # Merchant Skirt
    
    # The Bard
    1726,   # Bard’s Guitar
    1727,   # Drum
    1728,   # Harp
    238,    # Bard Clothes
    239,    # Bard Pants
    
    # The Witch
    1711,   # Mushroom Grower
    247,    # Witch Coat
    248,    # Witch Skirt
    
    # The Miner
    306,    # Cocobomb
    388,    # Pufferfish Bomb
    1144,   # Bomb Arrow
    288,    # Miner Suit
    289,    # Miner Pants
    
    # The Farmer
    1712,   # Farmer Visor
    492,    # Farmer Suit
    493,    # Farmer Pants

    # The Carpenter
    1713,   # Astral Box
    526,    # Carpenter Suit
    527,    # Carpenter Pants
    
    #11 The Skeleton
    1762,   # Box of Frights
    
    #12 The Chef
    1707,   # Spicer
    735,    # Chef Suit
    736,    # Chef Pants
    
    #13 The Fisherman
    1724,   # Tracker Bait
    738,    # Fisherman Suit
    739,    # Fisherman Pants
    
    #14 The Summoner
    291,    # Slime Voodoo Doll
    685,    # Cursed Doll
    849,    # Forbidden Scroll
    963,    # Mineral Spider Egg
    972,    # Love Letter
    973,    # Krill Snack
    974,    # Frog Toy
    975,    # Pocket Thumper
    976,    # Bloody Crown
    977,    # Spoiled Alioli
    978,    # Beetle Whistle
    1239,   # Fae Gem
    1299,   # Goo-Stained Needles
    1300,   # Crab Juice
    1642,   # Magma Worm Larva
    1644,   # Security Control Console
    1921,   # Eclipse Phoenix Egg
    1710,   # Truth Potion
    795,    # Summoner Suit
    796,    # Summoner Pants
    
    #15 The Electrician
    1736,   # Flamethrower Trap
    1737,   # Poison Trap
    
    858,    # Anemone Statue
    827,    # Angry Cactus Statue
    859,    # Anglerfish Statue
    1256,   # Anubis Statue
    1258,   # Ancient Mummy Statue
    1612,   # Ash Elemental Statue
    833,    # Archer Skeleton Statue
    1982,   # Army Merman Statue
    1874,   # Biting Tome Statue
    1316,   # Blood Slime Statue
    1255,   # Blood Thing Statue
    828,    # Crocodile Statue
    829,    # Crotalus Statue
    1926,   # Dandelion Statue
    718,    # Fluffy Snow Statue
    838,    # Ghoul Statue
    1294,   # Gooblin Statue
    1254,   # Golem Statue
    1295,   # Goop Hog Statue
    834,    # General Skeleton Statue
    1627,   # Guardian Robot Statue
    839,    # Hooded Cultist Statue
    1259,   # Hypnotoad Statue
    1296,   # Human Berserker Statue
    860,    # Jellyfish Statue
    1980,   # Kitsune Statue
    1260,   # Lamia Statue
    721,    # Leech Statue
    717,    # Light Muncher Statue
    1873,   # Living Enigma Statue
    1869,   # Living Secret Statue
    1614,   # Magma Slime Statue
    830,    # Maneater Statue
    891,    # Merman Statue
    722,    # Mongos Statue
    831,    # Monkey Statue
    719,    # Mosquito Statue
    715,    # Mummy Statue
    835,    # Necromancer Statue
    861,    # Octopus Statue
    714,    # Orc Statue
    832,    # Phoneutria Statue
    723,    # Phongos Statue
    1317,   # Pirate Statue
    1265,   # Pumpkin Statue
    862,    # Pufferfish Statue
    1257,   # Pyramid Beetle Statue
    1613,   # Salamander Statue
    1266,   # Scarecrow Statue
    1979,   # Scorpion Statue
    1977,   # Shooting Flower Statue
    1269,   # Siren Statue
    716,    # Skeleton Statue
    725,    # Slime Statue
    1978,   # Spider Mini Statue
    1267,   # Spookie Ghost Statue
    1927,   # Spriggan Statue
    863,    # Squidcannon Statue
    724,    # Swamp Thing Statue
    1261,   # Swamp Slime Statue
    864,    # Swordfish Statue
    1695,   # Thug Penguin Statue
    720,    # Toad Statue
    1263,   # Tricolor Mage Statue
    1264,   # Tricolor Slime Statue
    892,    # Tribe Statue
    943,    # Turtle General Statue
    1268,   # Turtle Statue
    836,    # Undertaker Statue
    893,    # Venomous Plant Statue
    837,    # Vampire Statue
    1981,   # Wanderer Statue
    1866,   # Wild Dryad Statue
    1938,   # Wild Dryad Dog Statue
    1252,   # Wolf Statue
    1253,   # Yeti Statue
    
    #18 The Stylist
    1714,   # Tailor Needle
    846,    # Stylist Suit
    847,    # Stylist Pants
    
    #21 The Cartographer
    1851,   # Pumpkin Map
    854,    # Jungle Map
    855,    # Ghostlands Map
    856,    # Coraline Fields Map
    1853,   # Tricolor Map
    1852,   # Goblin Map
    1636,   # Volcano Map
    1856,   # Day Map
    1857,   # Night Map
    
    #26 The Nurse
    281,    # High HP Potion
    282,    # High MP Potion
    658,    # Healing Staff
    1709,   # Emergency Potion
    1380,   # Nurse Suit
    1381,   # Nurse Pants
    
    #28 The Robot
    1738,   # Teleport Platform
    
    #29 The Penguin
    1704,   # Portable Safe
    
    #30 The Enchantress
    1976,   # Rune Shard Magnet
    1785,   # Enchantress Suit
    1786,   # Enchantress Skirt
    
    ]

proc version*(save: PlayerSave): int =
    save.data[0].getInt

proc sortShopItems*(node: var JsonNode) =
    for npcId in npcShopIds:

        var j = %* []
        let key = $npcId
        
        for item in shopOrder:
            if % item.getInt.float in node["npcs"][key]["shopExtraItems"]:
                j.add(% item.getInt.float)
        
        for item in node["npcs"][key]["shopExtraItems"]:
            if item notin j:
                j.add(item)
        
        node["npcs"][key]["shopExtraItems"] = j

proc extractPlayer*(saveFile: string) =
#    createFolders("data" / "player")

    var index = 0
    var version = 0
    var useVersion = 0

    echo fmt"reading {saveFile}"
    
    for line in lines(saveFile):
        var str:string
        var ext:string
        if index == 0:
            version = line.parseInt
            useVersion = version
            
            # fall back to the closest version below the given
            while not saveFormat.hasKey(useVersion):
                dec useVersion
                if useVersion <= 0:
                    quit fmt"Could not process save version {version}."
        
        if saveFormat[useVersion][index] == "json":
            str = prettyJson(line)
            ext = "json"
        elif saveFormat[useVersion][index] == "jstring":
            str = unstringifyJsonString(line)
            ext = "json"
        elif saveFormat[useVersion][index] == "number":
            str = line
            ext = "txt"
        
        let filename = fmt"data/player/output.{index+1}.{ext}" / ""
        
        writeFile(filename, str)
        echo fmt"wrote {filename}"
        
        inc index

proc buildPlayer*(saveFile: string) =
    let version = readFile("data/player/output.1.txt").parseInt
    var useVersion = version
    
    # fall back to the closest version below the given
    while not saveFormat.hasKey(useVersion):
        dec useVersion
        if useVersion <= 0:
            quit fmt"Could not process save version {version}."
    
    var index = 0
    var lines: seq[string] = @[]
    
    for entry in saveFormat[useVersion]:
        if saveFormat[useVersion][index] == "json":
            lines.add minifyJson(readFile(fmt"data/player/output.{index+1}.json"))
        elif saveFormat[useVersion][index] == "jstring":
            lines.add stringifyJsonString(readFile(fmt"data/player/output.{index+1}.json"))
        elif saveFormat[useVersion][index] == "number":
            lines.add readFile(fmt"data/player/output.{index+1}.txt")
        inc index
        
    lines.add ""
    
    writeFile(saveFile, lines.join("\r\n"))
    echo fmt"wrote {saveFile}"

proc loadPlayer*(saveFile: string): PlayerSave =
    var index = 0
    var version = 0
    var useVersion = 0

    for line in lines(saveFile):
        var str:string
        var ext:string
        if index == 0:
            version = line.parseInt
            useVersion = version
            
            # fall back to the closest version below the given
            while not saveFormat.hasKey(useVersion):
                dec useVersion
                if useVersion <= 0:
                    quit fmt"Could not process save version {version}."
        
        if saveFormat[useVersion][index] == "json":
            str = prettyJson(line)
            ext = "json"
        elif saveFormat[useVersion][index] == "jstring":
            str = unstringifyJsonString(line)
            ext = "json"
        elif saveFormat[useVersion][index] == "number":
            str = line
            ext = "txt"
        
        result.data.add(parseJson(str))
        
        inc index

proc save*(ps: PlayerSave, saveFile: string) =
    let version = ps.version
    var useVersion = version
    var lines: seq[string] = @[]
    
    # fall back to the closest version below the given
    while not saveFormat.hasKey(useVersion):
        dec useVersion
        if useVersion <= 0:
            quit fmt"Could not process save version {version}."
    
    for i in 0..<ps.data.len:
        if saveFormat[useVersion][i] == "json":
            lines.add minifyJson($ps.data[i])
        elif saveFormat[useVersion][i] == "jstring":
            lines.add stringifyJsonString($ps.data[i])
        elif saveFormat[useVersion][i] == "number":
            lines.add $ps.data[i].getInt
    
    lines.add ""
    
    writeFile(saveFile, lines.join("\r\n"))
    echo fmt"wrote {saveFile}"

proc save*(ps: PlayerSave) =
    let filename = fmt"savegame0{ps.slot}.player.new" / ""
    ps.save(filename)

proc stripFromItems(node: var JsonNode) =
    if node.kind == JArray:
        node.elems = node.elems.filterIt(
            it.kind == JArray and (
                it.elems.len == 0 or
                it[0].kind != JString or
                not it[0].getStr.contains("@")
            )
        )

proc stripMods*(ps: PlayerSave) =
    # remove modded recipes
    var arr = ps.data[2]["knownRecipes"]
    arr.elems = arr.elems.filterIt(not it.getStr.contains("@"))
    
    # remove modded ingredients
    arr = ps.data[2]["knownIngredients"]
    arr.elems = arr.elems.filterIt(not it.getStr.contains("@"))
    
    # these blocks are here to capture the JsonNode for a mutable
    # copy/reference to a variable then discard it when done.
    
    # remove modded items from equipment
    block:
        var node = ps.data[3]["items"]
        node.stripFromItems
    
    # remove modded items from astral box
    block:
        var node = ps.data[4]["items"]
        node.stripFromItems
    
    # remove modded items from inventory
    block:
        var node = ps.data[5]["items"]
        node.stripFromItems

    # remove modded items from transmutation cube
    block:
        var node = ps.data[14]["items"]
        node.stripFromItems

    # remove modded items from vault
    block:
        var node = ps.data[17]["items"]
        node.stripFromItems

    # remove modded items from farmer storage
    block:
        var node = ps.data[16]  # make a mutable copy/reference
        
        for item in node:
            if item.hasKey("container"):
                # Parse the JSON string stored in "container"
                var containerNode = parseJson(item["container"].getStr.unstringifyJsonString)
                
                # Access the "items" array inside the container
                var itemsNode = containerNode["items"]

                itemsNode.stripFromItems

                # Store back as a JString (escaped json)
                item["container"] = % $containerNode

    # remove modded items from shops
    block:
        for npcID in 0..100:
            let npcKey = $npcID
            if ps.data[12]["npcs"].hasKey(npcKey):
                var shop = ps.data[12]["npcs"][npcKey]["shopExtraItems"]

                # Filter out any strings containing "@"
                shop.elems = shop.elems.filterIt(
                    it.kind != JString or not it.getStr.contains("@")
                )

#    for i in 6..11:
#        if ps.data[i].kind == JString and ps.data[i].contains("@"):
#            var node = ps.data[i]
#            node = % 0

proc sortShopItems*(save: var PlayerSave) =
    for npcId in npcShopIds:

        var j = %* []
        let key = $npcId
        
        for item in shopOrder:
            if % item.getInt.float in save.data[12]["npcs"][key]["shopExtraItems"]:
                j.add(% item.getInt.float)
        
        for item in save.data[12]["npcs"][key]["shopExtraItems"]:
            if item notin j:
                j.add(item)
        
        save.data[12]["npcs"][key]["shopExtraItems"] = j

proc getFreeInventorySlot*(ps: PlayerSave): tuple[x, y: int] =
    let node = ps.data[5]["items"]
    for y in 0..4:
        for x in 0..10:
            var found = false
            for item in node:
                if item[1].getFloat == x.float and item[2].getFloat == y.float:
                    found = true
                    break
            if not found:
                return (x,y)
    return (-1, -1)

proc inventoryIsFull*(ps: PlayerSave): bool =
    ps.getFreeInventorySlot[0] == -1
