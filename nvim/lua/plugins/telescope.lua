local function files()
  require("search").search("find_files")
end

local function grep()
  require("search").search("live_grep")
end

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
    { "<leader><leader>", files, desc = "Files" },
    { "<leader>/", grep, desc = "Grep Live" },
    { "<leader>ff", files, desc = "Files" },
    { "<leader>fg", grep, desc = "Grep Live" },
    { "<leader>fb", "<Cmd>Telescope buffers<CR>", desc = "Buffers" },
    { "<leader>fh", "<Cmd>Telescope help_tags<CR>", desc = "Help Tags" },
    { "<leader>fr", "<Cmd>Telescope oldfiles<CR>", desc = "Recent Files" },
    { "<leader>fl", "<Cmd>Telescope resume<CR>", desc = "Last Picker" },
  },
  config = function()
    require("telescope").setup({
      defaults = {
        layout_config = {
          horizontal = { preview_cutoff = 0 },
        },
        -- history is saved by default but has no keys of its own
        mappings = {
          i = {
            ["<C-Down>"] = require("telescope.actions").cycle_history_next,
            ["<C-Up>"] = require("telescope.actions").cycle_history_prev,
          },
        },
      },
    })
    require("telescope").load_extension("fzf")
  end,
}
