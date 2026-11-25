-- Scrollbar with diagnostic/search/cursor marks (built-in providers) plus
-- gitsigns hunks.
return {
  "petertriho/nvim-scrollbar",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    providers = { gitsigns = true },
  },
}
