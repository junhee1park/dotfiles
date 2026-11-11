return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  lazy = false, -- plugin/neo-tree.lua must be sourced at startup to hijack netrw
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  keys = {
    { "<leader>ee", "<Cmd>Neotree toggle<CR>", desc = "Neo-tree" },
    { "<leader>eo", "<Cmd>Neotree focus<CR>", desc = "Neo-tree (focus)" },
    { "<leader>eE", "<Cmd>Neotree reveal<CR>", desc = "Neo-tree (reveal file)" },
    { "<leader>eg", "<Cmd>Neotree left git_status toggle<CR>", desc = "Git status" },
  },
  opts = {
    filesystem = {
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      filtered_items = {
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
  },
}
