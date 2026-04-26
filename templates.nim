import
    std/os,
    std/strformat,
    std/strutils,
    std/sequtils,
    std/tables,
    std/json,
    std/macros

import regex        # nimble install regex

import expr_eval

type
  Formatter* = proc(args: varargs[string]): string

proc `*` (s: string; n: Natural): string = repeat(s, n)


type
    RegexOp* = enum
        match,
        sub

    RegexFlags* = object
        global*: bool
        ignoreCase*: bool
        multiLine*: bool
        dotAll*: bool
        extended*: bool
        eval*: bool

    RegexExpr* = object
        op*: RegexOp
        delim*: char
        pattern*: string
        replacement*: string
        flags*: RegexFlags

proc toRegexFlags*(f: RegexFlags): set[RegexFlag] =
    result = {}

    if f.ignoreCase:
        result.incl(regexCaseless)

    if f.multiLine:
        result.incl(regexMultiline)

    if f.dotAll:
        result.incl(regexDotAll)

    if f.extended:
        result.incl(regexExtended)

    # usually not needed in RE2-style engines, but included for completeness
    if f.eval:
        discard

    # global is NOT a compile flag in RE2-style replace APIs
    # it is handled at call-site, not here

proc parseFlags*(s: string): RegexFlags =
    for c in s:
        case c
        of 'g': result.global = true
        of 'i': result.ignoreCase = true
        of 'm': result.multiLine = true
        of 's': result.dotAll = true
        of 'x': result.extended = true
        of 'e': result.eval = true
        else: discard


proc parseUntilDelim(s: string; start: int; delim: char): tuple[text: string, next: int] =
    var i = start
    var buffer = newStringOfCap(32)

    while i < s.len:
        let c = s[i]

        if c == '\\':
            if i + 1 >= s.len:
                raise newException(ValueError, "Trailing escape")
            buffer.add(s[i + 1])
            i += 2

        elif c == delim:
            return (buffer, i + 1)

        else:
            buffer.add(c)
            inc i

    raise newException(ValueError, "Unterminated expression section")

proc parseRegexExpr*(input: string): RegexExpr =
    if input.len == 0:
        raise newException(ValueError, "Empty input")

    var i = 0

    # operator
    if input[0] == 's':
        result.op = sub
        inc i
    else:
        result.op = match

    if i >= input.len:
        raise newException(ValueError, "Missing delimiter")

    result.delim = input[i]
    inc i

    # pattern
    let patternResult = parseUntilDelim(input, i, result.delim)
    result.pattern = patternResult.text
    i = patternResult.next

    # replacement (only for substitution)
    if result.op == sub:
        let replacementResult = parseUntilDelim(input, i, result.delim)
        result.replacement = replacementResult.text
        i = replacementResult.next

    # flags
    if i < input.len:
        result.flags = parseFlags(input[i..^1])

# ----------------------------------------
# Formatters
# ----------------------------------------

# Money formatter
# example: __450.money__
# output: 4 Silver 50 Copper
proc money(args: varargs[string]): string =
    let arg = args[0]
    let currencyUnits = [
        ("Plat",   1_000_000),
        ("Gold",    10_000),
        ("Silver",     100),
        ("Copper",       1)
    ].toOrderedTable

    var total: int
    try:
        total = parseInt(arg)
    except:
        return arg

    var parts: seq[string] = @[]
    for unit, value in currencyUnits.pairs:
        let amount = total div value
        if amount > 0:
            parts.add($amount & " " & unit)
            total = total mod value

    if parts.len == 0:
        return "0 Copper"

    result = parts.join(" ")

proc calc(args: varargs[string]): string =
    let value = args[0]
    var expr = args[1]
    evalExpr(expr, value)

# Field.pad:<20
proc pad(args: varargs[string]): string =
    let value = args[0]
    
    if args.len == 1:
        return value
    
    var opts = args[1]
    var alignLeft = true
    
    if opts.startsWith("<"):
        opts = opts[1..<opts.len]
    elif ">" in opts:
        opts = opts[1..<opts.len]
        alignLeft = false
    
    let width = opts.parseInt

    if value.len >= width:
        return value

    let padding = " " * (width - value.len)
    if alignLeft:
        return value & padding
    else:
        return padding & value

# strip codes like [#yellow], [shake]
#proc stripCodes(args: varargs[string]): string =
#    var value = args[0]
    
#    while true:
#        if "[" in value and "]" in value:
#            value = value.split("[", 1)[0] & value.split("]", 1)[1]
#        else:
#            return value

# only output once during iteration
proc once(args: varargs[string]): string =
  ## args[0] = text to output
  ## args[1] = optional loop index as string
  var idx = 0
  if args.len > 1:
    try:
      idx = parseInt(args[1])
    except:
      idx = 0
  if idx == 0:
    return args[0]   # first loop, output text
  else:
    return ""        # later loops, empty string

# explicit text output __i.text:Hello World__
proc text(args: varargs[string]): string =
  args[1]

# ----------------------------------------
# Formatters Main Table
# ----------------------------------------

# Table of formatters defined in one go
var formatters*: Table[string, Formatter] = {
    "pad": Formatter(pad),
    "money": Formatter(money),
    "once": Formatter(once),
#    "stripCodes": Formatter(text),
    "calc": Formatter(calc),
    "text": Formatter(text)
    
}.toTable()

# ----------------------------------------
# Helpers
# ----------------------------------------

proc isDecimal(s: string): bool =
    if s.len == 0:
        return false

    var chars: set[char]
    for c in s:
        chars.incl c

    return chars <= {'0'..'9'}

proc eat(text: var string, c: string): string =
    if c notin text:
        result = text
        text = ""
        return
    else:
        result = text.split(c, 1)[0]
        text = text.split(c, 1)[1]
        return

proc extractIdentifiers(input: string): seq[string] =
    var resultSeq: seq[string] = @[]

    for line in input.splitLines():
        var start = 0

        while true:
            let openPos = line.find("__", start)
            if openPos < 0: break

            let closePos = line.find("__", openPos + 2)
            if closePos < 0: break

            let identifier = line[openPos + 2 ..< closePos]
            resultSeq.add(identifier)

            start = closePos + 2

    return resultSeq

proc removeLinesStartingWith(input, prefix: string): string =
    result = input
        .splitLines()
        .filterIt(not it.startsWith(prefix))
        .join("\n")

proc normalizeLines(s: string, newline = "\n"): string =
    s.splitLines().join(newline)

# ----------------------------------------
# Template Core
# ----------------------------------------

proc loadTemplate*(templateName: string): string =
    if fileExists(fmt"templates/" & templateName & ".txt"):
        return readFile(fmt"templates/" & templateName & ".txt").normalizeLines
    
    # files starting with _ are not included in package (local/test stuff)
    if fileExists(fmt"templates/_" & templateName & ".txt"):
        return readFile(fmt"templates/_" & templateName & ".txt").normalizeLines
    return ""

proc resolveChainSimple(text: var string, node: var JsonNode) =
    if node.kind == JObject:
        for key, value in node.pairs:
            text = text.replace("__" & key & "__", value.getStr)

proc resolveChain(text: var string, node: var JsonNode, chain: var string, options: JsonNode = nil) =
    let opt = if options.isNil: newJObject() else: options
    var chainParse: string
    var field: string
    var value: string = ""

    # iteration
    if chain.startsWith("i."):
        chainParse = chain
        discard chainParse.eat(".") # remove i.
        field = chainParse.eat(".")
        value = ""
    else:
        chainParse = chain
        field = chainParse.eat(".")
        value = ""
    
    # coalesce fields
    if field.startsWith("coalesce:"):
        discard field.eat(":") # remove coalesce: from start
        let params = field.split(":")
        
        for v in params:
            field = v
            if node.hasKey(v):
                break
    
    if field.startsWith("comment:"):
        field = ""
    
    # this loop walks the keys until we get a JString or a nonexistant key
    while true:
        if node.kind == JString:
            value = node.getStr
            break
        elif node.kind == JArray and field.isDecimal:
            let n = field.parseInt
            node = node[n]
            field = chainParse.eat(".")
        elif node.kind == JArray and node.elems.len == 0:
            value = ""
            break
        elif node.kind == JArray and node[0].kind == JObject and node[0].hasKey(field):
            node = node[0][field]
            field = chainParse.eat(".")
        elif node.kind == JObject and node.hasKey(field):
            node = node[field]
            field = chainParse.eat(".")
        else:
            value = ""
            break
    
    # from here we've walked the keys and the rest should be formatters
    while true:
        if field == "":
            break
        let splitParts = field.split(":")
        var fmtName = splitParts[0]
        var params = if splitParts.len > 1: splitParts[1..^1] else: @[]
        
        # special case for "once": prepend loop index automatically
        if fmtName == "once" and opt.hasKey("i"):
            params.insert($opt["i"].getInt, 0)   # $i is loop index variable
        
        if fmtName == "length":
            fmtName = "text"
            params = @[$node.len]
        
        if formatters.hasKey(fmtName):
            value = unpackVarargs(formatters[fmtName], @[value] & params)
        else:
            value = ""
        
        field = chainParse.eat(".")

    text = text.replace("__" & chain & "__", value)

proc resolveTemplate*(text: var string, node: var JsonNode) =
    var postText = ""
    
    if "__eof__" in text:
        text = text.split("__eof__")[0]
    
    if "__end template__" in text:
        postText = text.split("__end template__")[1]
        text = text.split("__end template__")[0]
    
    resolveChainSimple(text, node)
    
    for identifier in text.extractIdentifiers:
        var chain = identifier
        if chain.startsWith("i.") or chain.startsWith("iterate:") or chain.startsWith("end iterate") or chain == "once":
            # defer these to next loop handling iteration
            discard
        else:
            # localize node
            var node = node
            resolveChain(text, node, chain)
    
    for identifier in text.extractIdentifiers:
        if identifier.startsWith("iterate:"):
            let iterField = identifier.split(":")[1]
            var sep = ""
            if identifier.split(":").len > 2:
                # separater parameter; ex:
                #   __iterate:Likes:, __
                sep = identifier.split(":")[2]
            var iterText = text.split("__" & identifier & "__")[1].split(fmt"__end iterate__")[0]
            let originalIterText = iterText
            var newIterText = ""
            
            # iterate shop items etc
            var i = 0
            for item in node[iterField]:
                var itemText = iterText
                
                # iterate the identifiers like __i.Name__
                for iterId in iterText.extractIdentifiers:
                    var itemCurrent = item
                    var iterIdCopy = iterId
                    let opt = %* {"i":  i}

                    if iterId == "once":
                        iterText = iterText.removeLinesStartingWith("__once__")
                        itemText = itemText.replace("__once__", "")
                    
                    resolveChain(itemText, itemCurrent, iterIdCopy, opt)
                
                if i < node[iterField].len - 1:
                    itemText &= sep
                
                newIterText &= itemText
                i += 1
            
            text = text.replace("__" & identifier & "__" & originalIterText & "__end iterate__", newIterText)
    
    while true:
        if "__scrub__" in postText:
            let scrubText = postText.split("__scrub__")[1].split("__end scrub__")[0]
            text = text.replace(scrubText, "")
            postText = postText.replace("__scrub__" & scrubText & "__end scrub__", "")
        elif "__re:" in postText:
            let reText = postText.split("__re:")[1].split("__")[0]
            let expr = parseRegexExpr(reText)
            
            if expr.op == sub:
                if expr.flags.global:
                    text = replace(text, expr.pattern.re2(expr.flags.toRegexFlags), expr.replacement)
                else:
                    text = replace(text, expr.pattern.re2(expr.flags.toRegexFlags), expr.replacement, limit=1)
            
            let pos = postText.find("__re:")
            let pos2 = postText.find("__", pos+5)
            postText = postText[0..<pos] & postText[pos2+2..<postText.len]
        else:
            break
