import tables

# player save formats
var saveFormat* = initTable[int, seq[string]]()

# saveFormat 23 matches 22

saveFormat[22] = @[
    "number",
    "number",
    "json",
    "jstring","jstring","jstring",
    "number","number","number","number","number","number",
    "json","json","json","json","json",
    "jstring"
]
