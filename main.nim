import
    resource/resource,
    os,
    std/dirs,
    std/times,
    std/monotimes,
    std/rdstdin,
    std/parsecsv,
    strutils,
    streams,
    sets,
    strformat,
    Tables,
    std/wordwrap,
    json,
    pixie

import
    db_connector/db_sqlite # nimble install db_connector

import
    appinfo,
    simpleopts,
    TinkerEdit,
    config,
    formats,
    jsonTools

#var language = "English"

const app: App = App(
    name: "TinkerTool",
    url: "",
    author: "SpiderDave",
    stage: "alpha",
    description: """
A Tinkerlands multi tool.
"""
)

var cfg = initConfig()
const configFile = "tinkertool.ini"

cfg["language"] = "English"
cfg["dbFile"] = "tinkerlands.db"
cfg["dbFolder"] = "C:/Tinkerlands/Modding/Tinkerlands ModTool/db/"
cfg["languageFolder"] = "__programfilesx86__/Steam/steamapps/common/Tinkerlands/languages/"
cfg["steamFolder"] = "__programfilesx86__/Steam/steamapps/common/Tinkerlands/"
cfg["saveFolder"] = "__localappdata__/Tinkerlands/"
cfg["spritesFolder"] = "C:/Tinkerlands/Modding/Tinkerlands ModTool/sprites/"
#cfg["replace"] = "true"
#cfg["debug"] = "true"

#let start = getMonoTime()

#echo getCurrentDir()
#echo getEnv("localappdata")
#echo getEnv("programfiles(x86)")
#echo getEnv("programfiles")


iterator reverse[T](a: seq[T]): T {.inline.} =
    var i = len(a) - 1
    while i > -1:
        yield a[i]
        dec(i)

proc createFolders(path: string) =
    var folders:seq[string]
    var f = $path
    while f.splitPath.head != "":
        folders.add(f)
        if f.splitPath.head.endsWith(":"):
            break
        f = f.splitPath.head
    folders.add(f)

    for f in reverse(folders):
        if f != "":
            try:
                discard existsOrCreateDir(f)
            except:
                discard

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
                     name VARCHAR(50) NOT NULL
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
                                                  ADD COLUMN ? TEXT
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

    db.execSqlFile("queries/blacklist.sql")
    db.exec(sql(readFile("queries/createIndexes.sql")))

proc buildLanguages(db: DbConn) =
    echo "Building Translations..."
    
    db.exec(sql"DROP TABLE IF EXISTS languages")
    db.exec(sql"""
        CREATE TABLE languages (
            id   INTEGER PRIMARY KEY AUTOINCREMENT,
            name VARCHAR(50) NOT NULL
        )""")
    db.exec(sql"DROP TABLE IF EXISTS translations")
    db.exec(sql"""
        CREATE TABLE translations (
                     key TEXT,
                     lang TEXT,
                     text TEXT,
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
                        db.exec(sql"INSERT OR IGNORE INTO translations (lang, key, text) VALUES (?, ?, ?)",
                                lang, k, v)
                    else:
                        echo "unprocessed line: ", line
                lineNumber += 1
        of pcDir:
            discard
        else: discard

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

proc getSpriteFile(spriteName: string):string =
    let spriteFile = cfg.get("spritesFolder") / spriteName / fmt"{spriteName}.yy"
    
    if not fileExists(spriteFile):
        return ""
    
    let jsonNode = parseJson(readFile(spriteFile))
    var name = $jsonNode["frames"][0]["%Name"]
    name = name.replace(""""""", "")
    
    let pngFile = cfg.get("spritesFolder") / spriteName / fmt"{name}.png"
    
    if not fileExists(pngFile):
        return ""
    else:
        return pngFile

# force 16 px height for wiki icons
proc makeIcon(fromFile, toFile: string) =
    var image: Image
    image = readImage(fromFile)
    let x = 0
    let y = floor(8 - image.height / 2)
    var image2 = newImage(image.width, 16)
    image2.draw(image, translate(vec2(float(x), float(y))))
    image2.writeFile(toFile)

proc extractPlayer(saveFile: string) =
    createFolders("data" / "player")

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

proc buildPlayer(saveFile: string) =
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

proc usage() = 
    echo app.info
    echo ""
    echo app.description
    echo ""
    echo "Usage: ", app.name, " [opts]"
    echo ""
    echo "Options:"
    echo "      -get <category> <key> <value>          Find by category, key, value.  ex: -get craft_table Key working_table."
    echo "                                             Wildcard * may be used."
    echo "      -first                                 Limit results to the first found."
    echo "      -exact                                 Require exact match unless wildcards are used."
    echo "      -limit <limit>                         Limit results to the <limit> results."
    echo "      -only <prop>                           Only show property/column <prop> as a simple list."
    echo "      -enumerate                             Display number of results."
    echo "      -language <language>                   Set language to <language>."
#    echo "      -clip                                  Copy output to the clipboard."
    echo "      -saveimages                            Copy and rename icon images. Category specific folders and names will"
    echo "                                             be used."
    echo "      -makeicon                              when used with -saveimages, forces item icons to be 16 px high (useful for"
    echo "                                             wiki)."
#    echo "      -makerecipeicon                        when used with -saveimages, adds recipe icon overlay."
    echo "      -backup                                Backup all worlds, players, user options, languages."
    echo "      -extractworld <file>                   Extract all files from a world save <file>."
    echo "      -extractworld <slot>                   Extract all files from a world save <slot>."
    echo "      -buildworld <file>                     Rebuild a world from files and save to <file>."
    echo "      -extractplayer <file>                  Extract all files from a player save <file>."
    echo "      -extractplayer <slot>                  Extract all files from a player save <slot>."
    echo "      -buildplayer <file>                    Rebuild a player from files and save to <file>."
    echo "      -builddatabase                         Build database (tinkerlands.db). Takes a long time."
    echo "      -console                               Open sqlite console."
    echo "      -categories                            Show categories."
    echo "  -h, -help                                  Show this help."
    echo ""
#    echo "Examples:"
#    echo "    ", app.name, " -b"
#    echo ""
    quit()

when isMainModule:
    
    # load config
    cfg.load(configFile)
    
    # save config, ensuring any lost defaults are also saved
    # and that the config file is created if it was deleted.
    cfg.save(configFile)
    
    let options = simpleopts.parseOpts()
    
    if options.hasOpt("h", "help"):
        usage()
    if options.empty:
        usage()
    
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
        echo "    " & categories.join(", ").wrapWords(75).replace("\n", "\n    ")
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
        createFolders(backupFolder / "languages")
        for kind, path in walkDir(cfg.get("languageFolder")):
            case kind:
            of pcFile:
                copyFile(path, backupFolder / "languages" / path.splitPath.tail)
            else:
                discard
        
        # user options
        let fromFile = cfg.get("saveFolder") / "useroptions.conf"
        let toFile = backupFolder / "useroptions.conf"
        if fileExists(fromFile):
            copyFile(fromFile, toFile)
        
        # players
        createFolders(backupFolder / "players")
        for playerNum in 1..4:
            let fromFile = cfg.get("saveFolder") / "players" / fmt"savegame0{playerNum}.player"
            let toFile = backupFolder / "players" / fmt"savegame0{playerNum}.player"
            
            if fileExists(fromFile):
                copyFile(fromFile, toFile)
    
        # worlds
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
        quit()
    
    # undocumented option used in release buildling
    if options.hasOpt("releasetag"):
        echo app.releaseTag
        quit()
    
    # ----------------------------------------------
    # from here commands should require the database
    # ----------------------------------------------
    if not options.hasOpt("builddatabase"):
        # allow opening an empty database if we're using -builddatabase
        let dbFile = cfg.get("dbFile")
        if not fileExists(dbFile):
            echo fmt"ERROR: Database does not exist ({dbFile})"
            quit()
    
    let db = open(cfg.get("dbFile"), "", "", "")
    
    if options.hasOpt("builddatabase"):
        let start = getMonoTime()
        echo "Building tinkerlands.db..."
        db.buildDatabase()
        echo "Adding languages to db..."
        db.buildLanguages()
        let elapsed = getMonoTime() - start
        echo "Elapsed: ", elapsed.pretty

    if options.hasOpt("buildlang"):
        let start = getMonoTime()
        echo "Adding languages to db..."
        db.buildLanguages()
        let elapsed = getMonoTime() - start
        echo "Elapsed: ", elapsed.pretty

    if options.hasOpt("test"):
        db.execSqlFile("queries/blacklist.sql")

    if options.hasOpt("get"):
        let opt = options.getOpt("g", "get")
        
        var cat = "item"
        var search = ""
        var key = "all"
        if opt.len > 0:
            cat = opt[0]
        if opt.len > 1:
            key = opt[1]
        if opt.len > 2:
            search = opt[2]
        
        if search == "all":
            search = ""
        if key == "name":
            key = "name_localized"
        if key == "description":
            key = "description_localized"
        if key == "gender":
            key = "gender_localized"
        
        search = search.replace("%", fmt"\%")
        
        if options.hasOpt("exact") == false and "*" notin search and search.len > 0:
            search = "*" & search & "*"
        
        search = search.replace("*", "%")
        
        if key == "all":
            key = "ID"
            search = "%"
        
        var queryString: string
        
        if fileExists(fmt"queries/{cat}.sql"):
            queryString = readFile(fmt"queries/{cat}.sql")
        else:
            queryString = readFile(fmt"queries/default.sql")
            queryString = queryString.replace("__category__", cat)
            
        queryString = queryString.replace("__column__", key)

        let query_getMobNameFromKey = readFile("queries/getMobNameFromKey.sql")
        
        var language = cfg.get("language")
        if options.hasOpt("language"):
            language = options.getOpt("language")[0]
        
        var rows = db.get(queryString.sql, language, search)
        
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
                elif "%Name% the " in row["Name"]:
                    row["Name"] = row["Name"].replace("%Name% the ", "The ")
            
            if options.hasOpt("list"):
                if row.hasKey("Name") and row.hasKey("ID"):
                    echo fmt"""{row["ID"]} {row["Name"]}"""
                elif row.hasKey("Key") and row.hasKey("ID"):
                    echo fmt"""{row["ID"]} {row["Key"]}"""
            else:
                if row.hasKey("Name") and row.hasKey("ID"):
                    echo "----------------------------------------"
                    echo fmt"""{row["ID"]} {row["Name"]}"""
                    echo "----------------------------------------"
                elif row.hasKey("Key") and row.hasKey("ID"):
                    echo "----------------------------------------"
                    echo fmt"""{row["ID"]} {row["Key"]}"""
                    echo "----------------------------------------"
                
                for col, value in row.pairs:
                    if value == "":
                        discard
                    elif "_localized" in col or "_unlocalized" in col:
                        discard
                    else:
                        if options.hasOpt("only"):
                            if value in allValues:
                                discard
                            elif col == options.getOpt("only")[0]:
                                allValues.incl(value)
                                echo fmt"{value}"
                                nItems += 1
                        else:
                            echo fmt"{col:<31} {value}"
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
                if row.hasKey("Icon"):
                    let fromFile = getSpriteFile(row["Icon"])
                    if fromFile != "":
                        var toFile: string
                        
                        if row.hasKey("Name"):
                            toFile = "output" / cat / row["Name"] & "_icon.png"
                        else:
                            toFile = "output" / cat / row["Key"] & "_icon.png"
                        
                        createFolders("output" / cat)
                        
                        if options.hasOpt("makeicon"):
                            makeIcon(fromFile, toFile)
                        else:
                            copyFile(fromFile, toFile)
        if options.hasOpt("enumerate"):
            echo fmt"{nItems} results."
    if options.hasOpt("console"):
        echo "type 'quit' to quit.\n"
        
        var text = ""
        var prompt = "sqlite> "
        
        proc showHelp() = 
            echo "List of sqlite console commands:"
            echo "Note that all text commands must end with ';'"
            echo "?         (\\?) Display this help."
            echo "          (\\c)  Clear the current input statement."
            echo "help      (\\h)  Display this help."
            echo "          (\\p)  Print current command."
            echo "quit      (\\q)  Quit sqlite console."
            echo ""
        
        echo "Commands end with ;."
        echo "Type 'help;' or '\\h' for help. Type '\\c' to clear the current input statement."
        echo ""
        
        block mainConsoleLoop:
            while true:
                var input = readLineFromStdin(prompt)
                var stmt: string
                
                var cmd = ""
                if input.startsWith("\\"):
                    cmd = input.split("\\",1)[1].strip
                
                # These commands are single line and not added to the sql statements.
                if cmd == "q":
                    break
                elif cmd == "h" or cmd == "?":
                    showHelp()
                elif cmd == "c":
                    text = ""
                elif cmd == "p":
                    echo text
                elif cmd == "":
                    text &= input & "\n"
                else:
                    echo fmt"Unknown command '\{cmd}'."
                
                while ";" in text:
                    stmt = text.split(';', 1)[0].strip
                    text = text.split(';', 1)[1]
                    
                    let stmtL = stmt.toLowerAscii
                    
                    if stmtL == "show tables":
                        stmt = """SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%';"""
                    if stmtL == "show databases" or stmtL == "show database":
                        stmt = "PRAGMA database_list;"
                    if stmtL.startsWith("describe "):
                        stmt = "PRAGMA table_info(" & stmt.split(" ",1)[1].strip & ")"
                    if stmtL.startsWith("show create table "):
                        let name = stmt.split(" ", 3)[3].strip
                        stmt = "SELECT sql FROM sqlite_master WHERE type='table' AND name='" & name & "'"
                    if stmtL.startsWith("show indexes from "):
                        let name = stmt.split(" ", 3)[3].strip
                        stmt = "PRAGMA index_list(" & name & ")"
                    if stmtL.startsWith("show columns from "):
                        let name = stmt.split(" ", 3)[3].strip
                        stmt = "SELECT name FROM pragma_table_info(" & name & ")"
                    if stmtL == "show schema":
                        stmt = "SELECT sql FROM sqlite_master WHERE sql NOT NULL"
                    if stmtL.startsWith("show schema "):
                        let name = stmt.split(" ", 2)[2].strip
                        stmt = "SELECT sql FROM sqlite_master WHERE name='" & name & "'"
                    if stmtL == "show views":
                        stmt = "SELECT name FROM sqlite_master WHERE type='view'"
                    if stmtL.startsWith("show foreign keys from "):
                        let name = stmt.split(" ", 4)[4].strip
                        stmt = "PRAGMA foreign_key_list(" & name & ")"
                    
                    if stmtL == "quit":
                        break mainConsoleLoop
                    elif stmtL == "help":
                        showHelp()
                    elif stmt != "":
                        var maxWidth:seq[int]
                        
                        var hadError = false
                        
                        let rows = block:
                            try:
                                db.getAllRowsWithColumns(stmt.sql)
                            except DbError as e:
                                hadError = true
                                if e.msg.startsWith("near "):
                                    echo "ERROR ", e.msg
                                else:
                                    echo "ERROR: ", e.msg
                                @[]
                        
                        if not hadError:
                            if rows.len > 0:
                                for c in rows[0]:
                                    maxWidth.add(0)
                                
                                for row in rows:
                                    var i = 0
                                    for c in row:
                                        if c.len > maxWidth[i]:
                                            maxWidth[i] = c.len
                                        i += 1
                                
                                var output: string
                                
                                var hDivider = "+"
                                for i in 0..<rows[0].len:
                                    hDivider &= "-".repeat(maxWidth[i] + 2) & "+"
                                echo hDivider;
                                
                                # column names
                                output = "|"
                                for i in 0..<rows[0].len:
                                    let value = $rows[0][i]
                                    output &= " " & value & " ".repeat(maxWidth[i] - value.len) & " |"
                                echo output;
                                
                                if rows.len > 1:
                                    echo hDivider
                                
                                var rowNum = 0
                                for row in rows:
                                    output = "|"
                                    if rowNum > 0:
                                        for i in 0..<row.len:
                                            let value = $row[i]
                                            output &= " " & value & " ".repeat(maxWidth[i] - value.len) & " |"
                                        echo output
                                    rowNum += 1
                                
                                echo hDivider
                                
                                if rows.len - 1 == 0:
                                    echo fmt"Empty set"
                                    echo rows[0]
                                elif rows.len - 1 == 1:
                                    echo fmt"{rows.len - 1} row in set"
                                else:
                                    echo fmt"{rows.len - 1} rows in set"
                                echo ""
                            else:
                                let count = db.getAllRows(sql"SELECT changes()")[0][0].parseInt
                                if count == 0:
                                    echo "Query OK"
                                elif count == 1:
                                    echo "Query OK, 1 row affected"
                                else:
                                    echo fmt"Query OK, {count} rows affected"
                            
                if text.strip == "":
                    prompt = "sqlite> "
                else:
                    prompt = "     -> "
            
    db.close()