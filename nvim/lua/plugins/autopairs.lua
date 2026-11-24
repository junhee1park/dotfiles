return {
  {
    "windwp/nvim-autopairs",
    opts = {},
  },
  {
    -- nvim-autopairs' own endwise rules are deprecated (see its wiki), so keep vim-endwise.
    -- load after nvim-autopairs so endwise wraps its <CR> map instead of replacing it.
    -- can't lazy-load: sets b:endwise_addition on FileType, already passed by the current buffer
    "tpope/vim-endwise",
    dependencies = { "windwp/nvim-autopairs" },
    lazy = false,
  },
}
