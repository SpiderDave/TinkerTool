import os, tables

# simpleopts.nim
#
# Lightweight command-line argument parser as an alternative to parseopt.
#
# Features:
# * Single-dash options of any length (-x, -option, -foobar)
# * Positional arguments
# * Space-separated option values
# * Multiple values per option
# * Optional assignment using '=' or ':'
# * Empty assignment supported (-x= or -x: becomes [""])
#
# Rules:
# * Any argument beginning with '-' starts a new option
# * Values following an option are collected until the next option appears
# * Arguments before any option are positional
#
# Examples:
#
# myapp arg1 arg2 "arg with spaces" -x value1 value2 -y -option value
#
# positionals -> ["arg1", "arg2", "arg with spaces"]
# x -> ["value1", "value2"]
# y -> []
# option -> ["value"]
#
# -x=value
# -x:value
# -> x -> ["value"]
#
# -x=
# -x:
# -x ""
# -> x -> [""]

type
    Opts* = object
        positionals*: seq[string]
        options*: Table[string, seq[string]]

proc parseOpts*(args: seq[string] = commandLineParams()): Opts =
    var currentOpt = ""
    var res: Opts
    res.options = initTable[string, seq[string]]()

    proc ensureOpt(name: string) =
        if not res.options.hasKey(name):
            res.options[name] = @[]

    for arg in args:
        if arg.len > 1 and arg[0] == '-':
            var s = arg[1..^1]
            currentOpt = ""

            var splitPos = -1
            for i, c in s:
                if c == '=' or c == ':':
                    splitPos = i
                    break

            if splitPos >= 0:
                let name = s[0..<splitPos]
                let val = s[splitPos+1..^1]

                ensureOpt(name)

                if val.len == 0:
                    res.options[name].add("")
                else:
                    res.options[name].add(val)

                currentOpt = name
            else:
                ensureOpt(s)
                currentOpt = s
        else:
            if currentOpt == "":
                res.positionals.add(arg)
            else:
                res.options[currentOpt].add(arg)

    return res

proc hasOpt*(o: Opts, name1: string, name2 = ""): bool =
    if o.options.hasKey(name1):
        return true
    if name2 != "" and o.options.hasKey(name2):
        return true
    return false

proc getOpt*(o: Opts, name1: string, name2 = ""): seq[string] =
    if o.options.hasKey(name1):
        return o.options[name1]
    if name2 != "" and o.options.hasKey(name2):
        return o.options[name2]
    return @[]

proc getOpt1*(o: Opts, name1: string, name2 = "", default = ""): string =
    if o.options.hasKey(name1) and o.options[name1].len > 0:
        return o.options[name1][0]
    if name2 != "" and o.options.hasKey(name2) and o.options[name2].len > 0:
        return o.options[name2][0]
    return default

proc len*(o: Opts): int =
    # Start with positional arguments
    var total = o.positionals.len
    # Count each option key once (flags or options with values)
    total += o.options.len
    return total

proc empty*(o: Opts): bool =
    o.len == 0
