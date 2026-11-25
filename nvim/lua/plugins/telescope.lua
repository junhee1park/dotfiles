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
    "nvim-telescope/telescope-ui-select.nvim",
  },
  init = function()
    -- telescope is lazy-loaded; load it on the first vim.ui.select call
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.ui.select = function(...)
      require("lazy").load({ plugins = { "telescope.nvim" } })
      return vim.ui.select(...)
    end
  end,
  keys = {
    { "<leader><leader>", files, desc = "Files" },
    { "<leader>/", grep, desc = "Grep Live" },
    { "<leader>ff", files, desc = "Files" },
    { "<leader>fg", grep, desc = "Grep Live" },
    { "<leader>fb", "<Cmd>Telescope buffers<CR>", desc = "Buffers" },
    { "<leader>fh", "<Cmd>Telescope help_tags<CR>", desc = "Help Tags" },
    { "<leader>fr", "<Cmd>Telescope oldfiles<CR>", desc = "Recent Files" },
    { "<leader>fl", "<Cmd>Telescope resume<CR>", desc = "Last Picker" },
    { "grr", "<Cmd>Telescope lsp_references<CR>", desc = "References" },
    { "gri", "<Cmd>Telescope lsp_implementations<CR>", desc = "Implementation" },
    { "grt", "<Cmd>Telescope lsp_type_definitions<CR>", desc = "Type Definition" },
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
            -- same split keys as neo-tree and quickfix
            ["<C-s>"] = require("telescope.actions").select_horizontal,
            ["<C-x>"] = false,
            ["<C-Down>"] = require("telescope.actions").cycle_history_next,
            ["<C-Up>"] = require("telescope.actions").cycle_history_prev,
          },
          n = {
            ["<C-s>"] = require("telescope.actions").select_horizontal,
            ["<C-x>"] = false,
          },
        },
      },
      extensions = {
        ["ui-select"] = { require("telescope.themes").get_cursor() },
      },
    })
    require("telescope").load_extension("fzf")
    require("telescope").load_extension("ui-select")
  end,
}
