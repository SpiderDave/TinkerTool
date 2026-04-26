-- snek.lua
-- An example plugin that displays names in a snake language.

local plugin = {
    sep = ".",
    endLine = "\n"
}

function plugin:build()
    local item = self.data
    self.text = util.trim(string.format("%s %s", item.ID or "", item.Name or item.Key))
    
    -- regex replace
    --   s: substitution
    --   / delimiters
    --   () capture group
    --   $1 use captured group
    --   gi flags.  g = global (replace all), i = ignorecase
    self.text = reReplace("s/(s)/$1sss/gi", self.text)
end

return plugin