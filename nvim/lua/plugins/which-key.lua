-- mini.ai maps only `a`/`i` and reads the object key itself (getcharstr), so
-- which-key can't discover the objects; describe them by hand, like LazyVim's
-- LazyVim.mini.ai_whichkey(). Keep in sync with the mini.ai spec in mini.lua.
local function textobjects()
  local objects = {
    { "(", "() block" },
    { ")", "() block with ws" },
    { "[", "[] block" },
    { "]", "[] block with ws" },
    { "{", "{} block" },
    { "}", "{} block with ws" },
    { "<", "<> block" },
    { ">", "<> block with ws" },
    { "b", ")]} block" },
    { '"', '" string' },
    { "'", "' string" },
    { "`", "` string" },
    { "q", "quote `\"'" },
    { "t", "tag" },
    { "f", "function call" },
    { "a", "argument" },
    { "?", "user prompt" },
    { "F", "function" },
    { "o", "block" },
    { "B", "buffer" },
  }
  local prefixes = { a = "around", i = "inside", an = "next", ["in"] = "next", al = "last", il = "last" }
  local spec = { mode = { "o", "x" } }
  for prefix, name in pairs(prefixes) do
    spec[#spec + 1] = { prefix, group = name }
    for _, obj in ipairs(objects) do
      spec[#spec + 1] = { prefix .. obj[1], desc = obj[2] }
    end
  end
  return spec
end

-- One "Prev/Next X" (lowercase key) and "First/Last X" (uppercase) style for
-- the `[`/`]` pairs, replacing the built-in `:bnext`-style descs and
-- which-key's lowercase preset ones.
local function brackets()
  local spec = {}
  local function pair(key, name, prev, next, mode)
    spec[#spec + 1] = { "[" .. key, desc = prev .. " " .. name, mode = mode }
    spec[#spec + 1] = { "]" .. key, desc = next .. " " .. name, mode = mode }
  end
  for _, item in ipairs({
    { "b", "B", "Buffer" },
    { "q", "Q", "Quickfix" },
    { "l", "L", "Loclist" },
    { "a", "A", "Arg" },
    { "t", "T", "Tag" },
    { "d", "D", "Diagnostic" },
  }) do
    pair(item[1], item[3], "Prev", "Next", "n")
    pair(item[2], item[3], "First", "Last", "n")
  end
  pair("<C-Q>", "Quickfix File", "Prev", "Next", "n")
  pair("<C-L>", "Loclist File", "Prev", "Next", "n")
  pair("<C-T>", "Preview Tag", "Prev", "Next", "n")
  spec[#spec + 1] = { "[<Space>", desc = "Blank Line Above" }
  spec[#spec + 1] = { "]<Space>", desc = "Blank Line Below" }
  local motions = { "n", "x", "o" }
  pair("m", "Method Start", "Prev", "Next", motions)
  pair("M", "Method End", "Prev", "Next", motions)
  pair("s", "Misspelled Word", "Prev", "Next", motions)
  pair("%", "Unmatched Group", "Prev", "Next", motions)
  pair("(", "Unmatched (", "Prev", "Next", motions)
  pair("{", "Unmatched {", "Prev", "Next", motions)
  pair("<", "Unmatched <", "Prev", "Next", motions)
  pair("n", "Node", "Select Prev", "Select Next", "x")
  pair("N", "Sibling Node", "Select Prev", "Select Next", "x")
  return spec
end

return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    icons = { mappings = false },
    show_help = false,
    spec = {
      { "<leader>a", group = "ai" },
      { "<leader>b", group = "buffer" },
      { "<leader>e", group = "explore" },
      { "<leader>f", group = "find" },
      { "<leader>g", group = "git", mode = { "n", "x" } },
      { "<leader>gh", group = "hunk", mode = { "n", "x" } },
      { "<leader>h", group = "hunk" },
      { "<leader>c", group = "conflict" },
      -- built-in LSP maps, whose descs are the function names
      { "gr", group = "lsp" },
      { "grn", desc = "Rename" },
      { "gra", desc = "Code Action", mode = { "n", "x" } },
      { "grx", desc = "Run Codelens" },
      { "gO", desc = "Document Symbols" },
      brackets(),
      textobjects(),
    },
  },
}
