function _G.SnacksLazygitEdit(file, line)
  local lazygit_win = vim.api.nvim_get_current_win()
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(lazygit_win) then
      pcall(vim.api.nvim_win_close, lazygit_win, false)
    end
    vim.cmd.edit(vim.fn.fnameescape(file))
    if line then
      pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(line) or 1, 0 })
    end
  end)
end

-- Navigate out of a terminal window with <C-hjkl>. In a floating terminal there
-- is nothing to move to, so pass the key through; in a split, move to the window
-- in that direction. Same trick LazyVim uses.
local function term_nav(dir)
  ---@param self snacks.terminal
  return function(self)
    return self:is_floating() and "<c-" .. dir .. ">" or vim.schedule(function()
      vim.cmd.wincmd(dir)
    end)
  end
end

local function toggle_term()
  require("snacks").terminal(nil, { win = { position = "bottom" } })
end

-- Permalink to the current file / visual line range on the remote (GitHub, ...).
-- `permalink` pins the URL to the last commit touching the file, so it survives
-- later edits; gitbrowse reads the range from the visual marks itself.
local function gitbrowse(copy)
  return function()
    require("snacks").gitbrowse({
      what = "permalink",
      notify = not copy,
      open = copy and function(url)
        vim.fn.setreg("+", url)
        require("snacks").notify(url, { title = "Git Link Copied" })
      end or nil,
    })
  end
end

return {
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    init = function()
      -- snacks.notifier has no LSP progress of its own; "Simple LSP Progress"
      -- recipe from snacks.nvim docs/notifier.md
      vim.api.nvim_create_autocmd("LspProgress", {
        ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
        callback = function(ev)
          local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
          vim.notify(vim.lsp.status(), "info", {
            id = "lsp_progress",
            title = "LSP Progress",
            opts = function(notif)
              notif.icon = ev.data.params.value.kind == "end" and " "
                or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
            end,
          })
        end,
      })
    end,
    opts = {
      bigfile = { enabled = true },
      notifier = { enabled = true },
      styles = { notification = { wo = { winblend = 0 } } },
      image = { enabled = true },
      quickfile = { enabled = true },
      words = { enabled = true },
      -- only the current scope, like mini.indentscope
      indent = {
        enabled = true,
        indent = { enabled = false },
        scope = { char = "▏", hl = "Comment" },
        animate = { enabled = false },
      },
      dashboard = {
        enabled = true,
        -- same files/grep as <leader>ff / <leader>fg (dotfiles, <M-h>/<M-i>)
        preset = {
          pick = function(cmd, opts)
            if cmd == "files" or cmd == "live_grep" then
              require("search").search(cmd == "files" and "find_files" or cmd, opts)
            else
              require("telescope.builtin")[cmd](opts)
            end
          end,
        },
        -- the docs' `advanced` example minus its colorscript pane; pane 2
        -- folds under pane 1 when the window is too narrow for both
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
          { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
          {
            pane = 2,
            icon = " ",
            title = "Git Status",
            section = "terminal",
            enabled = function()
              return require("snacks").git.get_root() ~= nil
            end,
            cmd = "git status --short --branch --renames",
            height = 5,
            padding = 1,
            ttl = 5 * 60,
            indent = 3,
          },
          { section = "startup" },
        },
      },
      -- gutter layout: [mark/sign] [number] [fold/git]; closed-fold icons come
      -- from fillchars foldclose (options.lua)
      statuscolumn = { enabled = true },
      terminal = {
        win = {
          -- same Term* groups the sidekick terminal uses (plugins/ai.lua); the
          -- remaining mappings are snacks' own defaults, which carry no
          -- background of their own
          wo = {
            winhighlight = "Normal:TermNormal,NormalNC:TermNormal,WinBar:SnacksWinBar,WinBarNC:SnacksWinBarNC,"
              .. "FloatBorder:TermFloatBorder,FloatTitle:TermFloatTitle,FloatFooter:TermFloatTitle,"
              .. "WinSeparator:SnacksWinSeparator",
          },
          keys = {
            nav_h = { "<C-h>", term_nav("h"), desc = "Go to Left Window", expr = true, mode = "t" },
            nav_j = { "<C-j>", term_nav("j"), desc = "Go to Lower Window", expr = true, mode = "t" },
            nav_k = { "<C-k>", term_nav("k"), desc = "Go to Upper Window", expr = true, mode = "t" },
            nav_l = { "<C-l>", term_nav("l"), desc = "Go to Right Window", expr = true, mode = "t" },
            normal_mode = {
              "<C-q>",
              function()
                vim.cmd("stopinsert")
              end,
              desc = "Enter normal mode",
              mode = "t",
            },
          },
        },
      },
      lazygit = {
        config = {
          os = {
            edit = "nvim --server $NVIM --remote-send '<C-\\><C-n><Cmd>lua SnacksLazygitEdit({{filename}})<CR>'",
            editAtLine = "nvim --server $NVIM --remote-send '<C-\\><C-n><Cmd>lua SnacksLazygitEdit({{filename}}, {{line}})<CR>'",
          },
        },
      },
    },
    keys = {
      {
        "<leader>n",
        function()
          require("snacks").notifier.show_history()
        end,
        desc = "Notifications",
      },
      {
        "<leader>bd",
        function()
          require("snacks").bufdelete()
        end,
        desc = "Delete",
      },
      {
        "<leader>bD",
        function()
          require("snacks").bufdelete({ force = true })
        end,
        desc = "Delete!",
      },
      {
        "<leader>bo",
        function()
          require("snacks").bufdelete.other()
        end,
        desc = "Delete Other Buffers",
      },
      {
        "<leader>bs",
        function()
          local buf = vim.api.nvim_create_buf(true, true)
          vim.api.nvim_win_set_buf(0, buf)
          -- Delete the buffer instead of closing the only window.
          vim.keymap.set("n", "q", function()
            require("snacks").bufdelete(buf)
          end, { buffer = buf, desc = "Close Scratch Buffer" })
        end,
        desc = "Scratch",
      },
      {
        "<leader>gg",
        function()
          require("snacks").lazygit()
        end,
        desc = "Lazygit",
      },
      {
        "<leader>gy",
        gitbrowse(true),
        desc = "Yank Remote Link",
        mode = { "n", "x" },
      },
      {
        "<leader>go",
        gitbrowse(false),
        desc = "Open Remote Link",
        mode = { "n", "x" },
      },
      -- ctrl+/ arrives as <c-/> or <c-_> depending on the terminal's key
      -- encoding, so bind both. Works inside the terminal too, like the
      -- sidekick <c-.> toggle.
      { "<c-/>", toggle_term, desc = "Toggle Terminal", mode = { "n", "t", "i" } },
      { "<c-_>", toggle_term, desc = "Toggle Terminal", mode = { "n", "t", "i" } },
    },
  },
}
