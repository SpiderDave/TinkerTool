import tables
import strutils
import os

type
    Config* = OrderedTable[string,string]

proc initConfig*(files: varargs[string]): Config =
    result = initOrderedTable[string,string]()

    for f in files:
        if fileExists(f):
            for line in readFile(f).splitLines:
                let s = line.strip

                if s.len == 0: continue
                if s[0] == '#' or s[0] == ';': continue

                let parts = s.split('=', 1)
                if parts.len != 2: continue

                let key = parts[0].strip
                let val = parts[1].strip

                if key.len > 0:
                    result[key] = val

proc load*(cfg: var Config, filename: string) =
    if not fileExists(filename):
        return

    for line in readFile(filename).splitLines:
        let s = line.strip

        if s.len == 0: continue
        if s[0] == '#' or s[0] == ';': continue

        let parts = s.split('=', 1)
        if parts.len != 2: continue

        let key = parts[0].strip
        let val = parts[1].strip

        if key.len > 0:
            cfg[key] = val

proc save*(cfg: Config, filename: string) =
    var lines: seq[string]

    for k, v in cfg:
        lines.add k & "=" & v

    writeFile(filename, lines.join("\n"))

proc expandEnv*(path: string): string =
    result = path

    let pf = getEnv("programfiles")
    if pf.len > 0:
        result = result.replace("__programfiles__", pf) / ""

    let pf86 = getEnv("programfiles(x86)")
    if pf86.len > 0:
        result = result.replace("__programfilesx86__", pf86) / ""

    let la = getEnv("localappdata")
    if la.len > 0:
        result = result.replace("__localappdata__", la) / ""

proc getString*(cfg: Config, key: string): string =
    if key in cfg:
        cfg[key].expandEnv
    else:
        ""

proc getString*(cfg: Config, key: string, default: string): string =
    if key in cfg:
        cfg[key].expandEnv
    else:
        default.expandEnv

proc get*(cfg: Config, key: string): string =
    if key in cfg:
        getString(cfg, key)
    else:
        ""

proc get*(cfg: Config, key: string, default: string): string =
    getString(cfg, key, default)

proc getInt*(cfg: Config, key: string): int =
    if key in cfg:
        parseInt(cfg[key])
    else:
        0

proc getInt*(cfg: Config, key: string, default: int): int =
    if key in cfg:
        parseInt(cfg[key])
    else:
        default

proc getBool*(cfg: Config, key: string): bool =
    if key in cfg:
        parseBool(cfg[key])
    else:
        false

proc getBool*(cfg: Config, key: string, default: bool): bool =
    if key in cfg:
        parseBool(cfg[key])
    else:
        default