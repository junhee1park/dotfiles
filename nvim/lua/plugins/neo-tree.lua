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
    {
      "<leader>ef",
      function()
        vim.cmd(vim.bo.filetype == "neo-tree" and "wincmd p" or "Neotree focus")
      end,
      desc = "Neo-tree (focus)",
    },
    { "<leader>eE", "<Cmd>Neotree reveal<CR>", desc = "Neo-tree (reveal file)" },
  },
  opts = {
    -- same split keys as Telescope and quickfix; quick_jump gives up <C-s>
    window = {
      mappings = {
        ["<C-s>"] = "open_split",
        ["<C-v>"] = "open_vsplit",
        ["<C-t>"] = "open_tabnew",
        ["S"] = "none",
        ["s"] = "none",
        ["t"] = "none",
      },
    },
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
