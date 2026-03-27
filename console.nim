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
