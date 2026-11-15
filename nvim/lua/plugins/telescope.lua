return {
  "nvim-telescope/telescope.nvim",
  lazy = true,
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
  },
  keys = {
    { "<leader><leader>", "<Cmd>Telescope find_files<CR>", desc = "Files" },
    { "<leader>/", "<Cmd>Telescope live_grep<CR>", desc = "Grep Live" },
    { "<leader>ff", "<Cmd>Telescope find_files<CR>", desc = "Files" },
    { "<leader>fg", "<Cmd>Telescope live_grep<CR>", desc = "Grep Live" },
    { "<leader>fb", "<Cmd>Telescope buffers<CR>", desc = "Buffers" },
    { "<leader>fh", "<Cmd>Telescope help_tags<CR>", desc = "Help Tags" },
    { "<leader>fr", "<Cmd>Telescope oldfiles<CR>", desc = "Recent Files" },
  },
  config = function()
    require("telescope").setup({
      defaults = {
        layout_config = {
          horizontal = { preview_cutoff = 0 },
        },
      },
    })
    require("telescope").load_extension("fzf")
  end,
}
