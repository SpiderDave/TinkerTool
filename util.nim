import
    std/os,
    std/strutils,
    std/sequtils

iterator reverse[T](a: seq[T]): T {.inline.} =
    var i = len(a) - 1
    while i > -1:
        yield a[i]
        dec(i)

# create multiple folders needed for a given path
proc createFolders*(path: string) =
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

# Split by whitespace but preserves quoted substrings.
# Quotes are removed in the output.
proc splitQ*(s: string): seq[string] =
    var i = 0

    while i < s.len:
        case s[i]
        of '"':
            var j = i + 1
            while j < s.len and s[j] != '"':
                inc(j)

            if j >= s.len:
                result.add(s[i+1 .. ^1])
                break

            result.add(s[i+1 ..< j])
            i = j + 1

        of Whitespace:
            inc(i)

        else:
            var j = i
            while j < s.len and s[j] notin Whitespace:
                inc(j)

            result.add(s[i ..< j])
            i = j
    result

# Joins parts with spaces, adding quotes if an item contains whitespace.
proc joinQ*(parts: seq[string]): string =
    var res: seq[string] = @[]

    for p in parts:
        if p.len == 0 or p.anyIt(it in Whitespace):
            res.add("\"" & p & "\"")
        else:
            res.add(p)

    result = res.join(" ")

proc getFirstLine*(text: var string): string =
    text.split(Newlines, maxsplit=1)[0]

proc removeFirstLine*(text: var string): string =
    let parts = text.split(Newlines, maxsplit=1)
    if parts.len == 1:
        return ""
    return parts[1]

#proc normalizeLines*(s: string, newline = "\n"): string =
#    s.splitLines().join(newline)

proc normalizeLines*(s: string): string =
    s.splitLines().mapIt(it.strip(leading = false)).join("\n")







type LineItem = object
    content: string
    isCommentLine: bool
    isBlankLine: bool

# --------------------------------------------------
# TAB EXPANSION (measurement + normalization)
# --------------------------------------------------
proc expandTabs(inputText: string, tabWidth = 4): string =
    var resultText = ""
    var column = 0

    for ch in inputText:
        if ch == '\t':
            let spaces = tabWidth - (column mod tabWidth)
            resultText.add(repeat(' ', spaces))
            column += spaces
        else:
            resultText.add(ch)
            inc column

    resultText

# --------------------------------------------------
# CLASSIFY LINE
# --------------------------------------------------
proc classifyLine(inputLine: string): LineItem =
    let trimmedLine = inputLine.strip()

    LineItem(
        content: inputLine,
        isCommentLine: trimmedLine.startsWith("//"),
        isBlankLine: trimmedLine == ""
    )

# --------------------------------------------------
# PASS 1: normalize leading indentation only
# --------------------------------------------------
proc preprocess(inputText: string): seq[LineItem] =
    let rawLines = inputText.splitLines()
    result = @[]

    for line in rawLines:
        var i = 0
        var normalized = ""

        while i < line.len and line[i] == '\t':
            normalized.add("    ")
            inc i

        normalized.add(line[i .. ^1])
        result.add(classifyLine(normalized))

# --------------------------------------------------
# PASS 2: split into segments (preserves blank lines)
# --------------------------------------------------
proc buildSegments(items: seq[LineItem]): seq[seq[LineItem]] =
    var segments: seq[seq[LineItem]] = @[]
    var currentSegment: seq[LineItem] = @[]

    proc flushSegment() =
        if currentSegment.len > 0:
            segments.add(currentSegment)
            currentSegment = @[]

    for item in items:
        if item.isBlankLine:
            flushSegment()
            segments.add(@[item])
            continue

        if currentSegment.len == 0:
            currentSegment.add(item)
            continue

        if item.isCommentLine != currentSegment[0].isCommentLine:
            flushSegment()

        currentSegment.add(item)

    flushSegment()
    result = segments

# --------------------------------------------------
# ALIGNMENT INTENT DETECTION (FIXED RULE)
# --------------------------------------------------
proc hasAlignmentIntent(items: seq[LineItem]): bool =
    for item in items:
        var sawCodeChar = false

        for ch in item.content:
            if ch == '/':
                break
            if ch == '\t' and sawCodeChar:
                return true
            if ch != ' ':
                sawCodeChar = true

    false

# --------------------------------------------------
# PASS 3A: CODE SEGMENT
# --------------------------------------------------
proc formatCodeSegment(items: seq[LineItem]): seq[string] =
    # NO alignment unless tab-based intent exists
    if not hasAlignmentIntent(items):
        return items.mapIt(it.content)

    var maxCodeWidth = 0
    var parsed: seq[(string, string)] = @[]

    for item in items:
        let splitIndex = item.content.find("//")

        if splitIndex == -1:
            let codePart = expandTabs(item.content)
            parsed.add((codePart, ""))
            maxCodeWidth = max(maxCodeWidth, codePart.len)
        else:
            let codePart = expandTabs(item.content[0 ..< splitIndex])
            let commentPart = item.content[splitIndex .. ^1].replace("\t", " ")
            parsed.add((codePart, commentPart))
            maxCodeWidth = max(maxCodeWidth, codePart.len)

    var outputLines: seq[string] = @[]

    for (codePart, commentPart) in parsed:
        var formattedLine = codePart

        if commentPart != "":
            let padding = maxCodeWidth - codePart.len + 1
            formattedLine.add(repeat(' ', padding))
            formattedLine.add(commentPart)

        outputLines.add(formattedLine)

    result = outputLines

# --------------------------------------------------
# PASS 3B: COMMENT SEGMENT
# --------------------------------------------------
proc formatCommentSegment(items: seq[LineItem]): seq[string] =
    var outputLines: seq[string] = @[]

    for item in items:
        let rawText = item.content
        let splitIndex = rawText.find("//")

        if splitIndex == -1:
            outputLines.add(rawText)
            continue

        let prefixPart = rawText[0 ..< splitIndex]
        let bodyPart = rawText[splitIndex + 2 .. ^1]

        var convertedBody = ""
        var column = 0

        for ch in bodyPart:
            if ch == '\t':
                let spaces = 4 - (column mod 4)
                convertedBody.add(repeat(' ', spaces))
                column += spaces
            else:
                convertedBody.add(ch)
                inc column

        outputLines.add(prefixPart & "//" & convertedBody)

    result = outputLines

# --------------------------------------------------
# MAIN
# --------------------------------------------------
proc normalizeGml*(inputText: string): string =
    let prepared = preprocess(inputText)
    let segments = buildSegments(prepared)

    var finalOutput: seq[string] = @[]

    for segment in segments:
        if segment.len == 0:
            continue

        if segment.len == 1 and segment[0].isBlankLine:
            finalOutput.add(segment[0].content)
            continue

        if segment[0].isCommentLine:
            finalOutput.add(formatCommentSegment(segment))
        else:
            finalOutput.add(formatCodeSegment(segment))

    result = finalOutput.join("\n")