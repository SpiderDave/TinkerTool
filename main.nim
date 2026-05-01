import
    std/os,
    std/dirs,
    std/times,
    std/monotimes,
    std/rdstdin,
    std/parsecsv,
    std/wordwrap,
    std/json,
    std/strutils,
    std/sequtils,
    std/strformat,
    std/streams,
    std/sets,
    std/tables,
    std/random

# statically compile sqlite3
{.compile: "./lib/sqlite/sqlite3.c".}

import
    pixie,                  # nimble install pixie
    libclip/clipboard,      # nimble install nimclipboard
    db_connector/db_sqlite  # nimble install db_connector

import
    resource/resource,
    appinfo,
    simpleopts,
    TinkerEdit,
    config,
    playerSave,
    templates,
    names,
    util

import luastuff

var language = "English"

const app: App = App(
    name: "TinkerTool",
    url: "https://github.com/SpiderDave/TinkerTool",
    author: "SpiderDave",
    stage: "alpha",
    description: """
A Tinkerlands multi tool.
""".strip
)

const recipeOverlayImageData = readFile("recipe overlay.png")

var db: DbConn
var printOutput = ""

var cfg = initConfig()
const configFile = "tinkertool.ini"

cfg["language"] = "English"
cfg["dbFile"] = "tinkerlands.db"
cfg["dbFolder"] = "C:/Tinkerlands/Modding/Tinkerlands ModTool/db/"
cfg["languageFolder"] = "__programfilesx86__/Steam/steamapps/common/Tinkerlands/languages/"
cfg["steamFolder"] = "__programfilesx86__/Steam/steamapps/common/Tinkerlands/"
cfg["saveFolder"] = "__localappdata__/Tinkerlands/"
cfg["spritesFolder"] = "C:/Tinkerlands/Modding/Tinkerlands ModTool/sprites/"
cfg["replace"] = "false"
#cfg["debug"] = "true"

#let start = getMonoTime()

#echo getCurrentDir()
#echo getEnv("localappdata")
#echo getEnv("programfiles(x86)")
#echo getEnv("programfiles")

randomize()

proc isDecimal(s: string): bool =
    if s.len == 0:
        return false

    var chars: set[char]
    for c in s:
        chars.incl c

    return chars <= {'0'..'9'}

# human readable duration
proc pretty(elapsed: Duration): string =
    let p = elapsed.toParts
    if p[Hours] == 1:
        result &= fmt"{p[Hours]} hour, "
    elif p[Hours] > 1:
        result &= fmt"{p[Hours]} hours, "
    if p[Minutes] == 1:
        result &= fmt"{p[Minutes]} minute, "
    elif p[Minutes] > 1:
        result &= fmt"{p[Minutes]} minutes, "
    result &= fmt"{p[Seconds].float + p[Milliseconds].float * 0.001} seconds."

# this is for multiple statements (exec can't do it)
proc execSqlFile(db: DbConn, path: string) =
    var cleaned = newStringOfCap(1024)

    # strip -- comments
    for line in lines(path):
        let p = line.find("--")
        if p >= 0:
            cleaned.add(line[0..<p])
        else:
            cleaned.add(line)
        cleaned.add('\n')

    # split into statements
    for stmt in cleaned.split(';'):
        let s = stmt.strip()
        if s.len > 0:
            db.exec(sql(s))

proc buildDatabase(db: DbConn) =
    echo "Building database..."
    
    # create categories
    db.exec(sql"DROP TABLE IF EXISTS categories")
    db.exec(sql"""CREATE TABLE categories (
                     id   INTEGER PRIMARY KEY AUTOINCREMENT,
                     name TEXT NOT NULL COLLATE NOCASE
                  )""")

    let baseFolder = cfg.get("dbFolder")

    var csv: CsvParser

    for kind, path in walkDir(baseFolder):
        case kind:
        of pcFile:
            # no files to process in base folder
            discard
        of pcDir:
            # category folder
            
            # all keys for this category
            var allKeys: HashSet[string]
            allKeys.incl("ID")
            
            let cat = replace(path.splitFile[1], "db_", "")
            db.exec(sql"INSERT INTO categories (name) VALUES (?)",
                cat)
            
            echo "  ", cat
            
            db.exec(sql"DROP TABLE IF EXISTS ?",
                cat)
            db.exec(sql"""CREATE TABLE ? (
                             ID   INTEGER PRIMARY KEY
                          )""",
                cat)
            
            for kind, path in walkDir(baseFolder / "db_" & cat):
                case kind:
                of pcFile:
                    let id = path.splitFile[1].split("_")[0].parseInt
                    db.exec(sql"INSERT INTO ? (id) VALUES (?)",
                            cat, id)
                    
                    let fileData = readFile(path)
                    let lines = fileData.splitLines
                    var streamKeys = newStringStream(lines[0])
                    var streamValues = newStringStream(lines[1])
                    
                    # keys on this table
                    var keys: seq[string]
                    
                    open(csv, streamKeys, "inline")
                    while readRow(csv):
                        for val in items(csv.row):
                            var v = val
                            v = v.replace("(!)","")
                            v = v.replace("($)","")
                            v = v.replace("(=)","")
                            v = v.replace("(L1)","")
                            v = v.replace("(L2)","")
                            v = v.replace("(L3)","")
                            v = v.replace("($AI)","")
                            
                            if v != "ID":
                                if not(v in allKeys):
                                    db.exec(sql"""ALTER TABLE ?
                                                  ADD COLUMN ? TEXT COLLATE NOCASE
                                                  """,
                                        cat, v)

                            keys.add(v)
                            allKeys.incl(v)

                    csv.close()
                    
                    open(csv, streamValues, "inline")
                    var keyIndex = 0
                    while readRow(csv):
                        for val in items(csv.row):
                            
                            if keys[keyIndex] != "ID" and val != "undefined":
                                db.exec(sql"UPDATE ? SET ? = ? WHERE id = ?",
                                    cat,
                                    keys[keyIndex],
                                    val,
                                    id
                                )
                            
                            keyIndex += 1
                    csv.close()
                    
                else:
                    discard
        else:
            discard

proc buildLanguages(db: DbConn) =
    echo "Building Translations..."
    
    db.exec(sql"DROP TABLE IF EXISTS languages")
    db.exec(sql"""
        CREATE TABLE languages (
            id   INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL COLLATE NOCASE
        )""")
    db.exec(sql"DROP TABLE IF EXISTS translations")
    db.exec(sql"""
        CREATE TABLE translations (
                     key TEXT COLLATE NOCASE,
                     lang TEXT COLLATE NOCASE,
                     text TEXT COLLATE NOCASE,
                     PRIMARY KEY (key, lang)
                  )
        """)

    let baseFolder = cfg.get("languageFolder")
    for kind, path in walkDir(baseFolder):
        case kind:
        of pcFile:
            var fileData = readFile(path)
            
            # fix stray line break in French K_ITEM_DESC_BUBBLE_BATTERY
            # Also now in others, and need twice
            fileData = fileData.replace("\r\n/n", "/n")
            fileData = fileData.replace("\r\n/n", "/n")
            
            let lines = fileData.splitLines
            let lang = lines[0].split(",")[1]
            
            db.exec(sql"INSERT INTO languages (name) VALUES (?)",
                    lang)
            
            echo "  ", lang
            
            var lineNumber = 0
            for line in lines:
                if lineNumber >= 4 and line.len > 2:
                    let splitLine = line.split(",",1)
                    if splitLine.len == 2:
                        let k = splitLine[0]
                        var v = splitLine[1]
                        if v.len > 2:
                            v = v[1..^2]

                        # fix extra space in some entries like: "Daywood " --> "Daywood"
                        v = v.strip
                        
                        db.exec(sql"INSERT OR IGNORE INTO translations (lang, key, text) VALUES (?, ?, ?)",
                                lang, k, v)
                    else:
                        echo "unprocessed line: ", line
                lineNumber += 1
        of pcDir:
            discard
        else: discard

proc getKeys(n: JsonNode): seq[string] =
    if n.kind == JObject:
        for key, _ in n:
            result.add(key)

# similar to getAllRows but the first row will be the column names
proc getAllRowsWithColumns(db: DbConn, q: SqlQuery, args: varargs[string]): seq[Row] =
  var cols: DbColumns
  var headerAdded = false

  # iterate once to populate columns
  for r in db.instantRows(cols, q, args):
    if not headerAdded:
      var header: Row
      header.setLen(cols.len)
      for i, c in cols:
        header[i] = c.name
      result.add header
      headerAdded = true

    # copy the row values
    var row: Row
    row.setLen(r.len)
    for i in 0..<r.len:
      row[i] = r[i]
    result.add row

  # if there were no rows, still add the header
  if not headerAdded:
    if cols.len == 0:
        return @[]
    var header: Row
    header.setLen(cols.len)
    for i, c in cols:
      header[i] = c.name
    result.add header

proc getAllRowsAsTables(db: DbConn, q: SqlQuery, args: varargs[string]): seq[OrderedTable[string,string]] =
  var cols: DbColumns
  
  for r in db.instantRows(cols, q, args):
    var rowTable = initOrderedTable[string,string]()

    for i, c in cols:
      if c.name notin rowTable:
        # first time seeing this column, insert to preserve order
        rowTable[c.name] = r[int32(i)]
      else:
        # column already exists, overwrite value (last occurrence wins)
        rowTable[c.name] = r[int32(i)]

    result.add rowTable

# shorten the name so we can just use db.get()
proc get*(db: DbConn, q: SqlQuery, args: varargs[string]): seq[OrderedTable[string,string]] =
    getAllRowsAsTables(db, q, args)

proc getFirstValid(row: OrderedTable[system.string, system.string], args: varargs[string]): string =
    for arg in args:
        if row.hasKey(arg):
            return row[arg]
        if row.hasKey(arg.capitalizeAscii()):
            return row[arg.capitalizeAscii()]
    return ""

proc getSpriteFile(spriteName: string):string =
    if spriteName == "":
        return ""
    
    var spriteFile = cfg.get("spritesFolder") / spriteName / fmt"{spriteName}.yy"
    
    if not fileExists(spriteFile):
        spriteFile = cfg.get("spritesFolder") / spriteName / fmt"{spriteName}_0.png"
        if fileExists(spriteFile):
            return spriteFile
        else:
            return ""
    
    if not fileExists(spriteFile):
        return ""
    
    let jsonNode = parseJson(readFile(spriteFile))
    var name = $jsonNode["frames"][0]["%Name"]
    name = name.replace(""""""", "")
    
    var pngFile = cfg.get("spritesFolder") / spriteName / fmt"{name}.png"
    
    if not fileExists(pngFile):
        return ""
    else:
        return pngFile

# force 16 px height for wiki icons
#proc makeIcon(fromFile, toFile: string) =
#    var image: Image
#    image = readImage(fromFile)
#    let x = 0
#    let y = floor(8 - image.height / 2)
#    var image2 = newImage(image.width, 16)
#    image2.draw(image, translate(vec2(float(x), float(y))))
#    image2.writeFile(toFile)

# force 16 px height for wiki icons and add recipe overlay
proc makeRecipeIcon(fromFile, toFile: string) =
    var image: Image
    image = readImage(fromFile)
    var recipeOverlayImage: Image = decodeImage(recipeOverlayImageData)
    let x = 0
    let y = floor(8 - image.height / 2)
    var image2 = newImage(image.width, 16)
    image2.draw(image, translate(vec2(float(x), float(y))))
    image2.draw(recipeOverlayImage, translate(vec2(float(image.width + 1 - 7), float(8))))
    image2.writeFile(toFile)

# adjust width and height
proc makeImage(fromFile, toFile: string, w, h: var int) =
    var image: Image
    image = readImage(fromFile)
    if w == 0: w = image.width
    if h == 0: h = image.height
    let x = floor(w / 2 - image.width / 2)
    let y = floor(h / 2 - image.height / 2)
    var image2 = newImage(w, h)
    image2.draw(image, translate(vec2(float(x), float(y))))
    image2.writeFile(toFile)

# output like echo but captures to printOutput too
proc print(args: varargs[string, `$`]) = 
    printOutput &= args.join(" ")
    stdout.write args.join(" ")
    stdout.write "\n"
    stdout.flushFile()
    printOutput &= "\n"

proc printSpecial(args: varargs[string, `$`], sep=" ", endLine = "\n") = 
    printOutput &= args.join(sep)
    stdout.write args.join(sep)
    stdout.write endLine
    stdout.flushFile()
    printOutput &= endLine

proc defaultAppOutput() =
    echo app.info
    echo app.description
    echo ""
    echo fmt"Type {app.name} -h or -help for help."
    echo ""

proc getLanguage(options: Opts):string =
    var language = cfg.get("language")
    if options.hasOpt("language"):
        language = options.getOpt("language")[0]
    
    let languages = @[
      @["Chinese_Simplified", "chinese", "zhcn", "zhhans", "zh"],
      @["Chinese_Traditional", "zhtw", "zhhant"],
      @["English", "en"],
      @["French", "fr"],
      @["German", "de"],
      @["Japanese", "ja"],
      @["Korean", "ko"],
      @["Portuguese", "pt"],
      @["Russian", "ru"],
      @["Spanish", "es"]
    ]
    
    for entry in languages:
        for variant in entry:
            if options.hasOpt("language") and options.getOpt("language").len > 0:
                if options.getOpt("language")[0].toLowerAscii == variant.toLowerAscii:
                    language = entry[0]
            elif options.hasOpt(variant.toLowerAscii):
                language = entry[0]
    return language

# Expand item list to a Json Node
# This version does not use the database.
#proc expandItems(itemString: string): JsonNode =
#    let t = %* []
#    for entry in itemString.split("],["):
#        var cat = ""
#        var items = entry.replace("[","").replace("]","").split(",")
#        var key = items[0]
        
#        if key.startsWith("E_"):
#            cat = key.split("E_")[1].split("S.")[0].toLowerAscii
#            key = key.split(".")[1]
        
#        var node = %* {
#            "cat": % cat,
#            "key": % key,
#            "items": % items,
#        }
#        t.add(node)
#    return t

proc getData(db: DbConn, cat, key, value, where: string): JsonNode =
    let t = %* []
    
#    if where == "":
#        where = fmt"""    "{key}" = "{value}" COLLATE NOCASE"""
    
#    let where = fmt"""    "{key}" = "{value}" COLLATE NOCASE"""
    
    var queryString: string
    if fileExists(fmt"queries/{cat}.sql"):
        queryString = readFile(fmt"queries/{cat}.sql")
    else:
        queryString = readFile(fmt"queries/default.sql")
        queryString = queryString.replace("__category__", cat)
    queryString = queryString.replace("__language__", language)
    queryString = queryString.replace("__where__", where)
    
    if cfg.getBool("replace") == false:
        queryString = queryString.replace("COALESCE(en_replacename.name, ", "COALESCE(")
    
    var rows = db.get(queryString.sql)
    
    for row in rows:
        var node = %* {}
        for col, value in row.pairs:
            node[col] = % $value
        t.add(node)
    return t

proc getData(db: DbConn, cat, key, value: string): JsonNode =
    let where = fmt"""    "{key}" = "{value}" COLLATE NOCASE"""
    db.getData(cat, key, value, where)

proc getData(db: DbConn, queryString: string): JsonNode =
    let t = %* []
    
    var rows = db.get(queryString.sql)
    
    for row in rows:
        var node = %* {}
        for col, value in row.pairs:
            node[col] = % $value
        t.add(node)
    return t

# Expand item list to a Json Node
# Uses database to fill data
proc expandItems(db: DbConn, itemString: string): JsonNode =
    let t = %* []
    let t2 = %* []
    
    if itemString == "":
        return t2
    
    var categories: seq[string]
    for entry in itemString.split("],["):
        var cat = ""
        var items = entry.replace("[","").replace("]","").split(",")
        var key = items[0]
        
        if key.startsWith("E_"):
            cat = key.split("E_")[1].split("S.")[0].toLowerAscii
            key = key.split(".")[1]
        
        var node = %* {
            "cat": cat,
            "key": key
        }
        t.add(node)
        if cat notin categories:
            categories.add(cat)
    
    var where = ""
    var i = 0
    for cat in categories:
        var keys: seq[string]
        for item in t:
            if $item["cat"].getStr == cat:
                keys.add(item["key"].getStr)
        if i > 0:
            where &= "OR\n"
        where &= "    key IN (" & '"' & keys.join("""", """") & '"' & ")\n"
        i += 1
        
        # run a query once per category
        var queryString: string
        if fileExists(fmt"queries/{cat}.sql"):
            queryString = readFile(fmt"queries/{cat}.sql")
        else:
            queryString = readFile(fmt"queries/default.sql")
            queryString = queryString.replace("__category__", cat)
        queryString = queryString.replace("__language__", language)
        queryString = queryString.replace("__where__", where)
        
        if cfg.getBool("replace") == false:
            queryString = queryString.replace("COALESCE(en_replacename.name, ", "COALESCE(")
        
        var rows = db.get(queryString.sql)
        
        for row in rows:
            if row["Key"] in keys:
                for item in t:
                    if row["Key"] == item["key"].getStr:
                        item["data"] = % row
                        t2.add(% row)
    return t2

proc expandTexts(db: DbConn, itemString: string): JsonNode =
    # [[lang(LK.K_NPC_DIALOGUE_TRAVELLING_MERCHANT_01)],[lang(LK.K_NPC_DIALOGUE_TRAVELLING_MERCHANT_02)]]
    var t = %* []
    
    var keys = itemString[1..<itemString.len-1]
    
    keys = keys.replace("[lang(LK.","'")
    keys = keys.replace(")]","'")
    
    let queryString = fmt"""
    SELECT text FROM translations
    WHERE key in ({keys})
    AND lang = "{language}";
    """
    var rows = db.get(queryString.sql)
    
    for row in rows:
        t.add(% row["text"])
    
    return t

# Expand multiple item lists in a given Json Node
# Example:
#   db.expandItems(t, "Shop", "Likes", "Dislikes", "Furniture Required")
proc expandItems(db: DbConn, jObj: JsonNode, keys: varargs[string]) =
    for key in keys:
        if jObj.hasKey(key):
            jObj[key & "_unexpanded"] = jObj[key]
            if key == "Texts":
                jObj[key] = db.expandTexts(jObj[key].getStr)
            else:
                jObj[key] = db.expandItems(jObj[key].getStr)

#proc getItem(db: DbConn, name: string): JsonNode =
#    db.getData("item", "name_localized", name)[0]

proc getItem(db: DbConn, node: JsonNode): JsonNode =
    if node.kind == JNull:
         return newJNull()
    let id = $node[0].getFloat.int
    let data = db.getData("item", "id", id)
    if data.len == 0:
        return % fmt"(unknown item {id})"
    else:
        return data[0]

proc itemId(db: DbConn, name: string): int =
    let t = %* []
    let where = fmt"""    "name_localized" = "{name}" COLLATE NOCASE"""
    
    var queryString: string
    queryString = readFile(fmt"queries/itemid.sql")
    queryString = queryString.replace("__language__", language)
    queryString = queryString.replace("__where__", where)
    
    var rows = db.get(queryString.sql)
    
    for row in rows:
        var node = %* {}
        for col, value in row.pairs:
            node[col] = % $value
        t.add(node)
    
    return t[0]["ID"].getStr.parseInt

# get affix layout, like %ItemAffix% %ItemName%
proc getAffixLayout(db: DbConn): string =
    let queryString = fmt"""
    SELECT text FROM translations
    WHERE key = "K_GENERAL_AFFIX_LAYOUT"
    AND lang = "{language}";
    """
    var rows = db.get(queryString.sql)
    rows[0]["text"]

# Get localized affix name from affix base name
proc getAffix(db: DbConn, affix: string): string =
    let queryString = fmt"""
    SELECT text FROM translations
    WHERE key = "K_ITEM_AFFIX_{affix.toUpperAscii}_NEUTRAL"
    AND lang = "{language}";
    """
    var rows = db.get(queryString.sql)
    rows[0]["text"]

# get localized affix name from id
proc getAffix[T: SomeNumber](db: DbConn, affixId: T): string =
    if Affixes.hasKey(affixId.int):
        return db.getAffix(Affixes[affixId.int])
    return ""

# format search string
# ^ match start of string
# $ match end of string
# * match multiple characters
# _ match any character
proc formatSearch(search: var string, exact = false) =
    if search == "all":
        search = ""
    search = search.replace("%", fmt"\%")
    if exact != true and "*" notin search and search.len > 0:
        if search.startsWith("^"): search = search[1..<search.len]
        else: search = "*" & search
        
        if search.endsWith("$"): search = search[0..^2]
        else: search = search & "*"
    search = search.replace("*", "%")

#[
# variant with max replace
proc replace(s, sub, by: string, maxRepl: int): string =
    if maxRepl <= 0 or sub.len == 0:
        return s

    var start = 0
    var count = 0
    var res = ""

    while true:
        let i = s.find(sub, start)
        if i < 0 or count >= maxRepl:
            res.add s[start..^1]
            break

        res.add s[start..<i]
        res.add by

        start = i + sub.len
        inc count

    result = res
#]#

proc giveItem(p: PlayerSave, name: string, amount: int = 1) =
    if p.inventoryIsFull:
        return
    let (x, y) = p.getFreeInventorySlot
    var node = p.data[5]["items"]
    node.add(%*[db.itemID(name).float,x.float,y.float,amount.float,0.0,nil,nil])

proc equipItem(p: PlayerSave, name, slot: string, amount: int = 1) =
    p.equipItem(db.itemID(name), slot, amount)

proc randomHairColor*(): float =
    const natural = [
        # Blacks / very dark
        0x0A0A0A, 0x0F1214, 0x14191E,
        # Dark browns
        0x192332, 0x1E283C, 0x233246, 0x283750,
        # Browns
        0x283C5A, 0x2D4164, 0x32466E, 0x374B78, 0x3C5082,
        # Light browns
        0x415A8C, 0x465F96, 0x4B64A0, 0x5069AA,
        # Dark blondes
        0x5578B4, 0x5A82BE, 0x5F8CC8,
        # Blondes
        0x6496D2, 0x69A0DC, 0x6EAAD6, 0x73B4F0,
        # Light blondes
        0x78BEF5, 0x82C8FA,
        # Auburn / reddish browns
        0x28326E, 0x283782, 0x283C96, 0x2D41AA,
        # Reds / ginger
        0x2846B4, 0x2850C8, 0x2D5ADC, 0x3264F0
    ]

    const rare = [
        # Grays
        0x2A2A2A, 0x444444, 0x666666, 0x888888, 0xAAAAAA, 0xCCCCCC,
        # White / near-white
        0xE0E0E0, 0xF0F0F0,
        # Unnatural colors (kept somewhat muted)
        # Greens
        0x205020, 0x2A6A2A, 0x3C8C3C,
        # Blues
        0x502020, 0x6A2A2A, 0x8C3C3C,
        # Purples
        0x502050, 0x6A2A6A, 0x8C3C8C,
        # Pinkish
        0x7070C0, 0x9090D0
    ]

    # ~8% chance to pick from rare pool
    if rand(0.0..1.0) < 0.08:
        return float(rare[rand(rare.len - 1)])

    return float(natural[rand(natural.len - 1)])

proc usage() = 
    print "Usage: ", app.name, " [opts]"
    print ""
    print "Options:"
    print "      -get <category> <key> <value>          Find by category, key, value.  ex: -get craft_table Key working_table."
    print "                                             Wildcard * may be used."
    print "      -first                                 Limit results to the first found."
    print "      -exact                                 Require exact match unless wildcards are used."
    print "      -limit <limit>                         Limit results to the <limit> results."
    print "      -only <prop>                           Only show property/column <prop> as a simple list."
    print "      -enumerate                             Display number of results."
    print "      -language <language>                   Set language to <language>. Supports full names and codes."
    print "                                             There are also shorter convenience options like -spanish or -zhcn."
    print "      -clip                                  Copy output to the clipboard."
    print "      -saveimages [wikiicon|recipeicon]      Copy and rename icon images. Category specific folders and names will"
    print "                                             be used. If \"wikiicon\" is used, icons will be 16 px high (useful for"
    print "                                             wiki). If \"recipeicon\" is used, icons will be 16 px high and add recipe"
    print "                                             overlay."
    print "                                             wiki)."
    print "      -template <template>                   Use <template> in -get. The template names are based on files in the "
    print "                                             templates folder without the extension, for example \"npc_text\""
    print "                                             Note: templates are a work in progress and may change."
    print "      -backup                                Backup all worlds, players, user options, languages."
    print "      -extractworld <file>                   Extract all files from a world save <file>."
    print "      -extractworld <slot>                   Extract all files from a world save <slot>."
    print "      -buildworld <file>                     Rebuild a world from files and save to <file>."
    print "      -extractplayer <file>                  Extract all files from a player save <file>."
    print "      -extractplayer <slot>                  Extract all files from a player save <slot>."
    print "      -loadplayer <file>                     Load player save <file>."
    print "      -loadplayer <slot>                     Load player save <slot>."
    print "      -saveplayer <file>                     Save loaded player to <file>"
    print "      -saveplayer <slot>                     Save loaded player to <slot>"
    print "      -summary                               Show a summary of loaded player."
    print "      -randomizelook                         Randomize name and customization for loaded player."
    print "      -give (<item> | [<amount>] <item>)...  Give items to loaded player."
    print "      -equip ([<amount>] <item> <slot>)...   Equip items in slot for loaded player."
    print "      -stripmods                             Attempt to strip mods from loaded player."
    print "      -sortshopitems                         Sort shop items for loaded player."
    print "      -cheat                                 Add cheats to loaded player."
    print "      -buildplayer <file>                    Rebuild a player from files and save to <file>."
    print "      -builddatabase                         Build database (tinkerlands.db). Takes a long time."
    print "      -output [<filename=output.txt>]        Write output to <filename>."
    print "      -code                                  Special formatting for script category."
    print "      -clip                                  Copy output to the clipboard."
    print "      -console                               Open sqlite console."
    print "      -categories                            Show categories."
    print "       -mods (on|off|list)                   Turn mods on or off, by renaming mods folder between \"mods\" and \"_mods\"."
    print "  -h, -help                                  Show this help."
    print ""
    print "Examples:"
    print fmt"    {app.name} -get item blazon"
    print fmt"    {app.name} -get item type head body legs"
    print fmt"    {app.name} -backup"
    print fmt"    {app.name} -get item name Cangrejo -list -saveimages wikiicon -language Spanish"
    print fmt"    {app.name} -get item name crab -only name -output crab_items.txt"
    
    print ""
    quit()

when isMainModule:
    # load config
    cfg.load(configFile)
    
    # save config, ensuring any lost defaults are also saved
    # and that the config file is created if it was deleted.
    cfg.save(configFile)
    
    var player: PlayerSave
    
    let options = simpleopts.parseOpts()
    
    language = getLanguage(options)
    
    if options.hasOpt("h", "help"):
        defaultAppOutput()
        usage()
    
    if options.hasOpt("usage"): # undocumented; shows usage without default output
        usage()
    
    if options.empty:
        defaultAppOutput()
        quit()
    
    # required parameter sanity check
    if options.hasOpt("only") and options.getOpt("only").len == 0:
        usage()
    
    if options.hasOpt("categories"):
        let categories = [
            "ai", "ammo", "biome", "block", "buff", "cook", "craft_table", "dungeon", "enchant", "event",
            "fish", "interactable", "interactable_pool", "island", "item", "item_pool", "loot",
            "mapchart", "mapgen", "mob", "mob_pool", "mount", "npc", "quest", "recipe", "roof", "script",
            "sound", "structure", "summon", "tile", "top", "top_pool", "weather", "worldgen"
        ]
        
        # wrap to 75 characters and indent 4 spaces
        print "    " & categories.join(", ").wrapWords(75).replace("\n", "\n    ")
        quit()
    
    if options.hasOpt("limit") and options.getOpt("limit").len == 0:
        echo "ERROR: <limit> not specified."
        quit()
    
    if options.hasOpt("extractworld"):
        var filename = "main.sav"
        if options.getOpt("extractworld").len > 0:
            filename = options.getOpt("extractworld")[0]
            
            if filename in ["1","2","3","4"]:
                filename = cfg.get("saveFolder") / "worlds" / fmt"savegame0{filename}" / "main.sav"
        
        createFolders("data" / "world")
        extract(filename)
        quit()
    
    if options.hasOpt("extractplayer"):
        var filename = "main.sav"
        if options.getOpt("extractplayer").len > 0:
            filename = options.getOpt("extractplayer")[0]
            
            if filename in ["1","2","3","4"]:
                filename = cfg.get("saveFolder") / "players" / fmt"savegame0{filename}.player"
        
        createFolders("data" / "player")
        extractPlayer(filename)
        quit()
    
    if options.hasOpt("buildworld"):
        var filename = "output.sav"
        if options.getOpt("buildworld").len > 0:
            filename = options.getOpt("buildworld")[0]
        
        build(filename)
        quit()
    
    if options.hasOpt("buildplayer"):
        var filename = "output.player"
        if options.getOpt("buildplayer").len > 0:
            filename = options.getOpt("buildplayer")[0]
        
        buildPlayer(filename)
        quit()
    
    if options.hasOpt("releasetag"):
        echo app.releaseTag
        quit()
    
    if options.hasOpt("backup"):
        let nowTime = now()
        let formatted = nowTime.format("yyyy.MM.dd")
        let backupFolder = "backup" / formatted
        createFolders(backupFolder)
        
        # languages
        print "Backing up languages.."
        createFolders(backupFolder / "languages")
        for kind, path in walkDir(cfg.get("languageFolder")):
            case kind:
            of pcFile:
                copyFile(path, backupFolder / "languages" / path.splitPath.tail)
            else:
                discard
        
        # user options
        print "Backing up user options.."
        let fromFile = cfg.get("saveFolder") / "useroptions.conf"
        let toFile = backupFolder / "useroptions.conf"
        if fileExists(fromFile):
            copyFile(fromFile, toFile)
        
        # players
        print "Backing up players.."
        createFolders(backupFolder / "players")
        for playerNum in 1..4:
            let fromFile = cfg.get("saveFolder") / "players" / fmt"savegame0{playerNum}.player"
            let toFile = backupFolder / "players" / fmt"savegame0{playerNum}.player"
            
            if fileExists(fromFile):
                copyFile(fromFile, toFile)
    
        # worlds
        print "Backing up worlds.."
        createFolders(backupFolder / "worlds")
        for worldNum in 1..4:
            let fromFolder = cfg.get("saveFolder") / "worlds" / fmt"savegame0{worldNum}"
            let toFolder = backupFolder / "worlds" / fmt"savegame0{worldNum}"
            if dirExists(fromFolder):
                createFolders(toFolder)
                
                if fileExists(fromFolder / "main.sav"):
                    copyFile(fromFolder / "main.sav", toFolder / "main.sav")
                
                for islandX in 0..4:
                    for islandY in 0..4:
                        let fromFile = fromFolder / fmt"RandomIsland{islandX}x{islandY}.sav"
                        let toFile = toFolder /  fmt"RandomIsland{islandX}x{islandY}.sav"
                        
                        if fileExists(fromFile):
                            copyFile(fromFile, toFile)
        print "Done."
        quit()
    
    if options.hasOpt("sortshopitems"):
        let filename = "data/player/output.13.json"
        var node = parseJson(readFile(filename))
        
        node.sortShopItems
        
        echo fmt"Sorted shop items in {filename}."
        writeFile(filename, node.pretty)
    
    # undocumented option used in release buildling
    if options.hasOpt("releasetag"):
        echo app.releaseTag
        quit()
    
    if options.hasOpt("mods"):
        var opt = options.getOpt("mods")
        if opt.len == 0: opt = @["list"]
        
        let modsFolder = cfg.get("steamFolder") / "mods"
        let modsFolderOff = cfg.get("steamFolder") / "_mods"
        
        if opt[0] == "off":
            if dirExists(modsFolder) and not dirExists(modsFolderOff):
                moveDir(modsFolder, modsFolderOff)
                print("Mods off.")
            elif dirExists(modsFolderOff):
                print("Mods are already off.")
        elif opt[0] == "on":
            if dirExists(modsFolderOff) and not dirExists(modsFolder):
                moveDir(modsFolderOff, modsFolder)
                print("Mods on.")
            elif dirExists(modsFolder):
                print("Mods are already on.")
        elif opt[0] == "list":
            var n = 0
            print("Active mods:")
            if dirExists(modsFolder):
                for kind, path in walkDir(modsFolder):
                    case kind:
                    of pcFile:
                        print("    " & path.splitPath.tail)
                        n += 1
                    of pcDir:
                        discard
                    else:
                        discard
            else:
                discard
            if n == 0:
                print("    None.")
        
    # ----------------------------------------------
    # from here commands should require the database
    # ----------------------------------------------
    if not options.hasOpt("builddatabase"):
        # allow opening an empty database if we're using -builddatabase
        let dbFile = cfg.get("dbFile")
        if not fileExists(dbFile):
            echo fmt"ERROR: Database does not exist ({dbFile})"
            quit()
    
    db = open(cfg.get("dbFile"), "", "", "")
    
    if options.hasOpt("test") and cfg.getBool("debug"):
        discard
    
    if options.hasOpt("loadplayer"):
        var filename = options.getOpt("loadplayer")[0]
        var playerNum = 0
        
        if filename in ["1","2","3","4"]:
            playerNum = filename.parseInt
            filename = cfg.get("saveFolder") / "players" / fmt"savegame0{playerNum}.player"
        
        player = loadPlayer(filename)
        player.slot = playerNum
        
    if options.hasOpt("summary"):
        proc itemName(slot: string): string =
            var name: string
            let item = player.getItemInSlot(slot)
            var itemData = db.getItem(item)
            if itemData.kind == JNull:
                return "(empty)"
            if itemData.kind == JString:
                name = itemData.getStr
            else:
                name = itemData["Name"].getStr
                
                if name == "Recipe":
                    itemData = db.getData("recipe", "id", $item[5]["recipeID"].getFloat)
                    let key = itemData[0]["Product"].getStr.replace("E_ITEMS.","")
                    itemData = db.getData("item", "key", key)
                    name = itemData[0]["Name"].getStr
                    name = fmt"{name} (Recipe)"
                
                let amount = item[3].getFloat.int
                if amount > 1:
                    name = fmt"{amount} {name}"
            
            let affix = db.getAffix(item[4].getFloat)
            if affix != "":
                return db.getAffixLayout.replace("%ItemAffix%", affix).replace("%ItemName%", name)
            return name
        
        proc getEnchant(item: JsonNode): string =
            if item.kind == JNull:
                return ""
            
            if item[5].kind == JObject and item[5].hasKey("enchant") and item[5]["enchant"].kind == JObject:
                let id = item[5]["enchant"]["enchantID"].getFloat.int
                let level = item[5]["enchant"]["level"].getFloat.int
                let t = db.getData("enchant", "ID", $id)[0]
                let name = t["Name"].getStr
                let maxLevel = t["Max Level"].getStr
                return fmt"{name} lvl {level}/{maxLevel}"
            return ""
        
        print fmt"""
        ----------------------------------------
        Player Slot {player.slot}
        ----------------------------------------
        
        Name:       {player["name"].getStr}
        
        Max HP:     {player["hpMax"].getFloat.int}
        Max MP:     {player["mpMax"].getFloat.int}
        Defense:    {player["defense"].getFloat.int}
        Skin:       {player["customization"]["skin"].getFloat.int}
        Underwear:  {player["customization"]["underwear"].getFloat.int}
        Voice:      {player["customization"]["voice"].getFloat.int}
        Hair:       {player["customization"]["hair"].getFloat.int}
        Hair Color: {player["customization"]["hairColor"].getFloat.int} ({player["customization"]["hairColor"].getFloat.int:x})
        """.dedent
        
        proc printItem(slot: string) =
            let name = slot.itemName
            if name != "(empty)":
                print("    ", name, " ")
                let enchant = player.getItemInSlot(slot).getEnchant
                if enchant != "":
                    print("        ", enchant)
        
        print("Vanity:")
        printItem("vanityhead")
        printItem("vanitybody")
        printItem("vanitylegs")
        print("Armor:")
        printItem("head")
        printItem("body")
        printItem("legs")
        print("Accessories:")
        printItem("accessory1")
        printItem("accessory2")
        printItem("accessory3")
        printItem("accessory4")
        printItem("accessory5")
        printItem("accessory6")
        print("Ammo:")
        printItem("ammo1")
        printItem("ammo2")
        printItem("ammo3")
        print("Pet:")
        printItem("pet")
        print("Mount:")
        printItem("mount")
        print("Hook:")
        printItem("hook")
        print("Hotbar:")
        printItem("hotbar1")
        printItem("hotbar2")
        printItem("hotbar3")
        printItem("hotbar4")
        printItem("hotbar5")
        printItem("hotbar6")
        printItem("hotbar7")
        printItem("hotbar8")
        printItem("hotbar9")
        printItem("hotbar10")

        print("Inventory:")
        for i in 1..44:
            printItem(fmt"inventory{i}")

        print("Coins:")
        printItem("coin1")
        printItem("coin2")
        printItem("coin3")
        printItem("coin4")
        
        print("Astral Box:")
        for i in 1..30:
            printItem(fmt"astralbox{i}")
        
    if options.hasOpt("randomizelook"):
        player["customization"]["skin"] = % sample([0, 0, 0, 1, 1, 2, 3]).float
        player["customization"]["underwear"] = % rand(0..<3)
        player["customization"]["hair"] = % rand(0..<26)
        player["customization"]["hairColor"] = % randomHairColor()
        
        if rand(1) == 0:
            player["name"] = % sample(maleNames)
            player["customization"]["voice"] = % 0.0
            player["customization"]["hair"] = % sample([0, 1, 2, 4, 7, 8, 9, 10, 11, 12, 13, 14, 16, 20, 21, 22, 23, 24]).float
            player["customization"]["underwear"] = % sample([0, 2]).float
        else:
            player["name"] = % sample(femaleNames)
            player["customization"]["voice"] = % 1.0
            player["customization"]["hair"] = % sample([3, 5, 6, 15, 17, 18, 19, 25]).float
            player["customization"]["underwear"] = % sample([1, 2]).float
        
    if options.hasOpt("stripmods"):
        player.stripMods
    
    if options.hasOpt("sortshopitems"):
        player.sortShopItems
    
    # -give 999 "wooden torch" 10 rock leaf stick
    if options.hasOpt("give"):
        let opt = options.getOpt("give")
        
        var amount = 1
        for item in opt:
            if item.isDecimal:
                amount = item.parseInt
            else:
                player.giveItem(item, amount)
                amount = 1
    # -equip 999 "wooden torch" ammo1 "legendary blazon" accessory6
    if options.hasOpt("equip"):
        let opt = options.getOpt("equip")
        var amount = 1
        var slot = ""
        var itemName = ""
        for item in opt:
            if item.isDecimal:
                amount = item.parseInt
            elif StorageSlot.hasKey(item):
                slot = item
            else:
                itemName = item
            
            if slot != "" and itemName != "":
                print(fmt"equip {amount} {itemName} in {slot}")
                player.equipItem(itemName, slot, amount)
                amount = 1
                itemName = ""
                slot = ""
    
    if options.hasOpt("cheat"):
        player.setUpgrade("lifeFlower", 18)
        player.setUpgrade("manaFlower", 9)
        player.setUpgrade("defenseFlower", 10)
        
        player.setUpgrade("dashUpgrade01", true)
        player.setUpgrade("dashUpgrade02", true)
        player.setUpgrade("speedUpgrade01", true)
        
        for i in 0..19:
            player.setUpgrade(fmt"dictionary{i:02}", true)
    
    if options.hasOpt("saveplayer"):
        let opt = options.getOpt("saveplayer")
        
        if opt.len == 0:
            player.save
        else:
            var filename = opt[0]
            var playerNum = 0
            
            if filename in ["1","2","3","4"]:
                playerNum = filename.parseInt
                filename = cfg.get("saveFolder") / "players" / fmt"savegame0{playerNum}.player"
            player.save(filename)
    
    if options.hasOpt("builddatabase"):
        let start = getMonoTime()
        echo "Building tinkerlands.db..."
        db.buildDatabase()
        echo "Adding languages to db..."
        db.buildLanguages()
        echo "building blacklist, replace data, and indexes..."
        db.execSqlFile("queries/blacklist.sql")
        db.execSqlFile("queries/replace.sql")
        db.execSqlFile("queries/createIndexes.sql")
        
        let elapsed = getMonoTime() - start
        echo "Elapsed: ", elapsed.pretty

    if options.hasOpt("buildlang"):
        let start = getMonoTime()
        echo "Adding languages to db..."
        db.buildLanguages()
        let elapsed = getMonoTime() - start
        echo "Elapsed: ", elapsed.pretty

    if options.hasOpt("get"):
        include "get.nim"
    
    if options.hasOpt("console"):
        include console
    
    if options.hasOpt("clip"):
        discard setClipboardText($printOutput)
    
    if options.hasOpt("output"):
        let opt = options.getOpt("output")
        
        let filename = block:
            if opt.len == 0: "output.txt"
            else: opt[0] / ""
        
        writeFile(filename, printOutput)
        echo fmt"Output written to {filename}."
    
    db.close()