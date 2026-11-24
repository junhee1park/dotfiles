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
      { "[", group = "prev" },
      { "]", group = "next" },
      -- built-in LSP maps, whose descs are the function names
      { "gr", group = "lsp" },
      { "grn", desc = "Rename" },
      { "gra", desc = "Code Action", mode = { "n", "x" } },
      { "grx", desc = "Run Codelens" },
      { "gO", desc = "Document Symbols" },
      textobjects(),
    },
  },
}
