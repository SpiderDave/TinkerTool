# expr_eval.nim
#
# Supported grammar:
#   number        e.g. 12, 3.5
#   operators:
#     +  -  *  /  //  %
#   parentheses:
#     ( expr )
#   unary:
#     +x, -x
#   variable:
#     x (optional via evalExpr(expr, xValue))
#
# Notes:
# - Whitespace is ignored
# - / = float division
# - // = floor division
# - Output is string (int if exact, float if needed)

import std/strutils, std/math


# -----------------------------
# Tokens
# -----------------------------

type
    TokenKind* = enum
        tkNumber, tkPlus, tkMinus, tkMul, tkDiv, tkFloorDiv, tkMod,
        tkLParen, tkRParen, tkEOF

    Token* = object
        kind*: TokenKind
        value*: float


# -----------------------------
# Tokenizer
# -----------------------------

proc isDigit(c: char): bool =
    c >= '0' and c <= '9'


proc tokenize*(expr: string): seq[Token] =
    var i = 0

    while i < expr.len:
        let c = expr[i]

        if c == ' ':
            inc i
            continue

        if isDigit(c) or c == '.':
            let start = i
            while i < expr.len and (isDigit(expr[i]) or expr[i] == '.'):
                inc i
            let numStr = expr[start..<i]
            result.add(Token(kind: tkNumber, value: parseFloat(numStr)))
            continue

        case c
        of '%':
            result.add(Token(kind: tkMod)); inc i
        of '+':
            result.add(Token(kind: tkPlus)); inc i
        of '-':
            result.add(Token(kind: tkMinus)); inc i
        of '*':
            result.add(Token(kind: tkMul)); inc i
        of '/':
            if i + 1 < expr.len and expr[i + 1] == '/':
                result.add(Token(kind: tkFloorDiv))
                i += 2
            else:
                result.add(Token(kind: tkDiv))
                inc i
        of '(':
            result.add(Token(kind: tkLParen)); inc i
        of ')':
            result.add(Token(kind: tkRParen)); inc i
        else:
            raise newException(ValueError, "Invalid char: " & $c)

    result.add(Token(kind: tkEOF))


# -----------------------------
# Parser
# -----------------------------

type Parser = object
    tokens: seq[Token]
    pos: int


proc current(p: Parser): Token =
    p.tokens[p.pos]


proc advance(p: var Parser) =
    inc p.pos


proc parseExpr(p: var Parser): float


proc parseFactor(p: var Parser): float =
    case p.current.kind
    of tkPlus:
        p.advance()
        return parseFactor(p)

    of tkMinus:
        p.advance()
        return -parseFactor(p)

    of tkNumber:
        let t = p.current
        p.advance()
        return t.value

    of tkLParen:
        p.advance()
        let v = parseExpr(p)

        if p.current.kind != tkRParen:
            raise newException(ValueError, "Missing closing parenthesis")

        p.advance()
        return v

    else:
        raise newException(ValueError, "Expected number or expression")


proc parseTerm(p: var Parser): float =
    var left = parseFactor(p)

    while true:
        case p.current.kind
        of tkMul:
            p.advance()
            left *= parseFactor(p)

        of tkDiv:
            p.advance()
            left /= parseFactor(p)

        of tkFloorDiv:
            p.advance()
            let rhs = parseFactor(p)
            left = floor(left / rhs)

        of tkMod:
            p.advance()
            let rhs = parseFactor(p)
            left = left mod rhs   # float mod via Nim's built-in overload

        else:
            break

    left

proc parseExpr(p: var Parser): float =
    var left = parseTerm(p)

    while true:
        case p.current.kind
        of tkPlus:
            p.advance()
            left += parseTerm(p)

        of tkMinus:
            p.advance()
            left -= parseTerm(p)

        else:
            break

    left


# -----------------------------
# Formatting
# -----------------------------

proc formatResult*(x: float): string =
    let rounded = round(x)

    if abs(x - rounded) < 1e-9:
        return $int(rounded)

    var s = formatFloat(x, ffDecimal, 10)

    while s.len > 0 and s[^1] == '0':
        s.setLen(s.len - 1)

    if s.len > 0 and s[^1] == '.':
        s.setLen(s.len - 1)

    s


# -----------------------------
# Public API (no variable)
# -----------------------------

proc evalExpr*(expr: string): string =
    let tokens = tokenize(expr)

    var p = Parser(tokens: tokens, pos: 0)
    let value = parseExpr(p)

    formatResult(value)


# -----------------------------
# Public API (with x substitution)
# -----------------------------

proc evalExpr*(expr: string; xValue: string): string =
    var resultExpr = ""
    var i = 0

    while i < expr.len:
        if expr[i] == 'x':
            let prevOk = i == 0 or not expr[i - 1].isAlphaNumeric
            let nextOk = i + 1 >= expr.len or not expr[i + 1].isAlphaNumeric

            if prevOk and nextOk:
                resultExpr.add("(" & xValue & ")")
                inc i
                continue

        resultExpr.add(expr[i])
        inc i

    evalExpr(resultExpr)