import
    strutils,
    unicode

func stripDoubleQuotes(s: string): string =
    if s.len >= 2 and s[0] == '"' and s[^1] == '"':
        result = s[1 .. ^2]
    else:
        result = s

func addDoubleQuotes(s: string): string =
    result = "\"" & s & "\""

func escapeJsonString*(s: string): string =
    result = ""
    for ch in s:
        case ch
        of '\"': result.add("\\\"")
        of '\\': result.add("\\\\")
        of '\b': result.add("\\b")
        of '\f': result.add("\\f")
        of '\n': result.add("\\n")
        of '\r': result.add("\\r")
        of '\t': result.add("\\t")
        else:
            if ord(ch) < 0x20:
                result.add("\\u")
                result.add(ord(ch).toHex(4))
            else:
                result.add(ch)

func unescapeJsonString*(s: string): string =
    result = ""
    var i = 0
    while i < s.len:
        if s[i] != '\\':
            result.add(s[i])
            inc i
        else:
            inc i
            if i >= s.len:
                raise newException(ValueError, "Invalid JSON escape sequence")

            case s[i]
            of '"': result.add('"')
            of '\\': result.add('\\')
            of '/': result.add('/')
            of 'b': result.add('\b')
            of 'f': result.add('\f')
            of 'n': result.add('\n')
            of 'r': result.add('\r')
            of 't': result.add('\t')
            of 'u':
                if i + 4 >= s.len:
                    raise newException(ValueError, "Invalid \\u escape")

                let hex = s[i + 1 .. i + 4]
                let code = parseHexInt(hex)
                result.add(Rune(code).toUtf8)
                i += 4
            else:
                raise newException(ValueError, "Unknown JSON escape: \\" & $s[i])

            inc i

proc minifyJson*(s: string): string =
    var res = newString(0)
    var inString = false
    var escape = false

    for c in s:
        if escape:
            res.add c
            escape = false
        elif c == '\\':
            res.add c
            escape = true
        elif c == '"':
            res.add c
            inString = not inString
        elif inString:
            res.add c
        elif c notin {' ', '\n', '\r', '\t'}:
            res.add c

    result = res

proc prettyJson*(s: string, indentStep = 2): string =
    var res = newString(0)
    var inString = false
    var escape = false
    var indent = 0
    var i = 0

    while i < s.len:
        let c = s[i]

        if escape:
            res.add c
            escape = false
        elif c == '\\':
            res.add c
            escape = true
        elif c == '"':
            res.add c
            inString = not inString
        elif inString:
            res.add c
        elif c in {'{', '['}:
            # Check for empty brackets
            var j = i + 1
            while j < s.len and s[j] in {' ', '\n', '\r', '\t'}:
                inc j
            if j < s.len and ((c == '{' and s[j] == '}') or (c == '[' and s[j] == ']')):
                res.add c & s[j]
                i = j  # skip the closing bracket
            else:
                res.add c
                indent += indentStep
                res.add '\n' & repeat(" ", max(indent, 0))
        elif c in {'}', ']'}:
            indent -= indentStep
            res.add '\n' & repeat(" ", max(indent, 0)) & c
        elif c == ',':
            res.add c & '\n' & repeat(" ", max(indent, 0))
        elif c == ':':
            res.add ": "
        elif c notin {' ', '\n', '\r', '\t'}:
            res.add c

        inc i

    result = res

func stringifyJsonString*(s: string): string =
    result = addDoubleQuotes(escapeJsonString(minifyJson(s)))

func unstringifyJsonString*(s: string): string =
    result = prettyJson(unescapeJsonString(stripDoubleQuotes(s)))
