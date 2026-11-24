-- Scrollbar with diagnostic/search/cursor marks; git marks come from the
-- plugin's built-in gitsigns handler, search marks from nvim-hlslens
-- (n/N/*/# restart it in keymaps.lua).
return {
  "petertriho/nvim-scrollbar",
  dependencies = { "kevinhwang91/nvim-hlslens" },
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("scrollbar").setup()
    require("scrollbar.handlers.gitsigns").setup()
    -- the search handler only hooks hlslens' build_position_cb; hlslens itself
    -- still needs setup() to be enabled
    require("hlslens").setup()
    require("scrollbar.handlers.search").setup()
  end,
}
