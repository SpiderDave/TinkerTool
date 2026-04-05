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
