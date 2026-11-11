-- version = "*" pins each module to its latest stable tag (mini follows
-- semver), overriding the global `defaults.version = false` (= track HEAD).
-- mini's main branch is explicitly "beta testing phase" per its docs.
return {
  {
    "nvim-mini/mini-git",
    main = "mini.git",
    version = "*",
    lazy = false,
    opts = {},
    keys = {
      { "<leader>ga", "<Cmd>Git diff --cached<CR>", desc = "Added Diff" },
      { "<leader>gA", "<Cmd>Git diff --cached -- %<CR>", desc = "Added Diff Buffer" },
      { "<leader>gc", "<Cmd>Git commit<CR>", desc = "Commit" },
      { "<leader>gC", "<Cmd>Git commit --amend<CR>", desc = "Commit Amend" },
      { "<leader>gd", "<Cmd>Git diff<CR>", desc = "Diff" },
      { "<leader>gD", "<Cmd>Git diff -- %<CR>", desc = "Diff Buffer" },
      {
        "<leader>gl",
        [[<Cmd>Git log --pretty=format:\%h\ \%as\ │\ \%s\ <\%an> --topo-order<CR>]],
        desc = "Log",
      },
      {
        "<leader>gL",
        [[<Cmd>Git log --pretty=format:\%h\ \%as\ │\ \%s\ <\%an> --topo-order --follow -- %<CR>]],
        desc = "Log Buffer",
      },
      {
        -- <cWORD> keeps the whole `(#123)` token whatever it is wrapped in, so
        -- the number survives wherever the cursor sits inside it. Requiring the
        -- `#` keeps a log line's sha and date columns from matching.
        "<leader>gp",
        function()
          local word = vim.fn.expand("<cWORD>")
          local pr = word:match("#(%d+)")
          if not pr then
            return vim.notify("No PR number: " .. word, vim.log.levels.WARN)
          end
          local remote = vim.fn.systemlist({ "git", "remote", "get-url", "origin" })[1] or ""
          local repo = remote:gsub("^git@(.-):", "https://%1/"):gsub("%.git$", "")
          vim.ui.open(("%s/pull/%s"):format(repo, pr))
        end,
        desc = "Open PR",
      },
      {
        "<leader>gs",
        function()
          require("mini.git").show_at_cursor()
        end,
        mode = { "n", "x" },
        desc = "Show At Cursor",
      },
    },
  },
  {
    "nvim-mini/mini.bracketed",
    version = "*",
    opts = {},
  },
  {
    "nvim-mini/mini.bufremove",
    version = "*",
    opts = {},
    keys = {
      {
        "<leader>bd",
        function()
          require("mini.bufremove").delete(0, false)
        end,
        desc = "Delete",
      },
      {
        "<leader>bD",
        function()
          require("mini.bufremove").delete(0, true)
        end,
        desc = "Delete!",
      },
      -- mini.bufremove only deletes a single buffer, so closing every other
      -- buffer uses snacks.bufdelete instead.
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
          -- `q` here deletes the buffer instead of `:close`: this replaces the
          -- current window's buffer rather than opening a split, so closing
          -- the window would quit Neovim if it's the only one left
          vim.keymap.set("n", "q", function()
            require("mini.bufremove").delete(buf, false)
          end, { buffer = buf, desc = "Close Scratch Buffer" })
        end,
        desc = "Scratch",
      },
    },
  },
  {
    "nvim-mini/mini.completion",
    version = "*",
    lazy = false,
    opts = {
      lsp_completion = {
        source_func = "omnifunc",
        auto_setup = false,
      },
    },
  },
  {
    "nvim-mini/mini.cmdline",
    version = "*",
    opts = {},
  },
  {
    "nvim-mini/mini.icons",
    version = "*",
    config = function()
      require("mini.icons").setup()
      -- Let plugins expecting nvim-web-devicons (e.g. neo-tree) use mini.icons
      MiniIcons.mock_nvim_web_devicons()
    end,
  },
  {
    "nvim-mini/mini.pairs",
    version = "*",
    opts = {},
  },
  {
    -- load after mini.pairs so endwise wraps its <CR> map instead of replacing it.
    -- can't lazy-load: sets b:endwise_addition on FileType, already passed by the current buffer
    "tpope/vim-endwise",
    dependencies = { "nvim-mini/mini.pairs" },
    lazy = false,
  },
  {
    "nvim-mini/mini.surround",
    version = "*",
    opts = {},
  },
  {
    "nvim-mini/mini.ai",
    version = "*",
    -- config mirrors mini.nvim author's own dotfiles (echasnovski/nvim,
    -- plugin/30_mini.lua): reuse mini.extra's buffer spec instead of
    -- hand-rolling one, and only bother with function/block via treesitter.
    opts = function()
      local ai = require("mini.ai")
      require("mini.extra")
      return {
        custom_textobjects = {
          -- `vaB`/`viB` select the whole buffer (`i` skips leading/trailing
          -- blank lines); `daB` deletes it, etc.
          B = MiniExtra.gen_ai_spec.buffer(),
          F = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          o = ai.gen_spec.treesitter({ a = "@block.outer", i = "@block.inner" }),
        },
        search_method = "cover",
      }
    end,
  },
  {
    "nvim-mini/mini.comment",
    version = "*",
    opts = {},
  },
  {
    "nvim-mini/mini.trailspace",
    version = "*",
    lazy = false,
    opts = {},
    keys = {
      {
        "<leader>ot",
        function()
          require("mini.trailspace").trim()
        end,
        desc = "Trim Trailspace",
      },
    },
  },
  {
    "nvim-mini/mini.splitjoin",
    version = "*",
    opts = {},
  },
  {
    "nvim-mini/mini.move",
    version = "*",
    opts = {},
  },
  {
    "nvim-mini/mini.sessions",
    version = "*",
    -- load on startup so autowrite persists the active session on exit
    lazy = false,
    opts = {},
    keys = {
      {
        "<leader>sn",
        function()
          vim.ui.input({ prompt = "Session name: " }, require("mini.sessions").write)
        end,
        desc = "New",
      },
      {
        "<leader>sl",
        "<Cmd>lua MiniSessions.write(MiniSessions.config.file)<CR>",
        desc = "Write Local Session (autoload)",
      },
      { "<leader>sw", "<Cmd>lua MiniSessions.write()<CR>", desc = "Write Current" },
      { "<leader>sr", '<Cmd>lua MiniSessions.select("read")<CR>', desc = "Read" },
      { "<leader>sd", '<Cmd>lua MiniSessions.select("delete")<CR>', desc = "Delete" },
      { "<leader>sR", "<Cmd>lua MiniSessions.restart()<CR>", desc = "Restart" },
    },
  },
  {
    "nvim-mini/mini.visits",
    version = "*",
    -- load on startup so visit frequency/recency tracking starts from the
    -- very first file opened, not just after `fv`/`fV` (in mini.extra's keys,
    -- grouped with the rest of the picker keymaps) first trigger it
    lazy = false,
    opts = {},
  },
  {
    "nvim-mini/mini.input",
    version = "*",
    opts = {},
  },
  {
    "nvim-mini/mini.cursorword",
    version = "*",
    opts = {},
  },
  {
    "nvim-mini/mini.indentscope",
    version = "*",
    opts = {},
  },
  {
    "nvim-mini/mini.starter",
    version = "*",
    opts = function()
      local starter = require("mini.starter")
      return {
        items = {
          { name = "Claude Code", action = "Sidekick cli toggle name=claude focus=true", section = "AI" },
          {
            name = "Claude Code (continue)",
            action = "Sidekick cli toggle name=claude_continue focus=true",
            section = "AI",
          },
          { name = "Codex", action = "Sidekick cli toggle name=codex focus=true", section = "AI" },
          {
            name = "Codex (resume)",
            action = "Sidekick cli toggle name=codex_resume focus=true",
            section = "AI",
          },
          starter.sections.recent_files(5, true, false),
          starter.sections.builtin_actions(),
        },
      }
    end,
  },
  {
    "nvim-mini/mini.notify",
    version = "*",
    lazy = false,
    opts = {},
    keys = {
      {
        "<leader>en",
        function()
          require("mini.notify").show_history()
        end,
        desc = "Notifications",
      },
    },
  },
  {
    "nvim-mini/mini.pick",
    version = "*",
    -- load on startup (keys would otherwise lazy-load) so setup() replaces
    -- vim.ui.select from the very first select prompt
    lazy = false,
    config = function()
      require("mini.pick").setup()

      -- Terminal `cmd+v` (Ghostty) sends a bracketed paste that tmux forwards to
      -- Neovim in chunks, so Neovim delivers it as a *streaming* paste (phase
      -- 1/2/3). mini.pick's own vim.paste wrapper only supports non-streaming
      -- (phase == -1) and otherwise warns "There is no streaming paste support"
      -- (pick.lua). We wrap vim.paste *after* setup so ours runs first: while a
      -- picker is active, read the clipboard register directly and push it into
      -- the query, bypassing the phase check entirely. See mini.nvim#1263.
      local paste_orig = vim.paste
      vim.paste = function(lines, phase)
        if not MiniPick.is_picker_active() then
          return paste_orig(lines, phase)
        end
        -- A streamed paste calls this once per phase (1=start, 2=continue,
        -- 3=end). We read the whole register ourselves, so act only on the
        -- first call (phase 1) or a non-streamed paste (phase -1); otherwise
        -- every phase would re-append the clipboard and duplicate it.
        if phase ~= -1 and phase ~= 1 then
          return true
        end
        for _, reg in ipairs({ "+", "*", '"' }) do
          local content = vim.fn.getreg(reg) or ""
          if content ~= "" then
            -- mini.pick's query is a list of single chars, so split into
            -- characters (not one blob) to keep backspace/caret editing working;
            -- flatten newlines/tabs to spaces like the native paste does.
            local chars = vim.fn.split(content:gsub("[\n\t]", " "), "\\zs")
            local query = MiniPick.get_picker_query() or {}
            vim.list_extend(query, chars)
            MiniPick.set_picker_query(query)
            return true
          end
        end
        return true
      end
    end,
    keys = {
      { "<leader><leader>", "<Cmd>Pick files<CR>", desc = "Files" },
      { "<leader>/", "<Cmd>Pick grep_live<CR>", desc = "Grep Live" },
      { "<leader>ff", "<Cmd>Pick files<CR>", desc = "Files" },
      {
        -- Like `files`, but bypasses .gitignore/.ignore (-uu) so ignored
        -- files (e.g. .env) show up. Mirrors the toggle other pickers expose.
        "<leader>fF",
        function()
          local pick = require("mini.pick")
          pick.builtin.cli({ command = { "rg", "--files", "--color=never", "-uu", "--glob=!.git/**" } }, {
            source = {
              name = "Files (incl. ignored)",
              show = function(buf_id, items, query)
                return pick.default_show(buf_id, items, query, { show_icons = true })
              end,
            },
          })
        end,
        desc = "Files (incl. ignored)",
      },
      { "<leader>fg", "<Cmd>Pick grep_live<CR>", desc = "Grep Live" },
      { "<leader>fG", '<Cmd>Pick grep pattern="<cword>"<CR>', desc = "Grep Current Word" },
      { "<leader>fb", "<Cmd>Pick buffers<CR>", desc = "Buffers" },
      { "<leader>fh", "<Cmd>Pick help<CR>", desc = "Help Tags" },
      { "<leader>fr", "<Cmd>Pick resume<CR>", desc = "Resume" },
    },
  },
  {
    "nvim-mini/mini.extra",
    version = "*",
    opts = {},
    keys = {
      { "<leader>fd", '<Cmd>Pick diagnostic scope="all"<CR>', desc = "Diagnostic Workspace" },
      { "<leader>fD", '<Cmd>Pick diagnostic scope="current"<CR>', desc = "Diagnostic Buffer" },
      { "<leader>fs", '<Cmd>Pick lsp scope="workspace_symbol_live"<CR>', desc = "Symbols Workspace (Live)" },
      { "<leader>fS", '<Cmd>Pick lsp scope="document_symbol"<CR>', desc = "Symbols Document" },
      { "<leader>fR", '<Cmd>Pick lsp scope="references"<CR>', desc = "References (LSP)" },
      { "<leader>fa", '<Cmd>Pick git_hunks scope="staged"<CR>', desc = "Added Hunks (All)" },
      { "<leader>fA", '<Cmd>Pick git_hunks path="%" scope="staged"<CR>', desc = "Added Hunks (Buf)" },
      { "<leader>fm", "<Cmd>Pick git_hunks<CR>", desc = "Modified Hunks (All)" },
      { "<leader>fM", '<Cmd>Pick git_hunks path="%"<CR>', desc = "Modified Hunks (Buf)" },
      { "<leader>fc", "<Cmd>Pick git_commits<CR>", desc = "Commits (All)" },
      { "<leader>fC", '<Cmd>Pick git_commits path="%"<CR>', desc = "Commits (Buf)" },
      { "<leader>f/", '<Cmd>Pick history scope="/"<CR>', desc = '"/" History' },
      { "<leader>f:", '<Cmd>Pick history scope=":"<CR>', desc = '":" History' },
      { "<leader>fH", "<Cmd>Pick hl_groups<CR>", desc = "Highlight Groups" },
      { "<leader>fl", '<Cmd>Pick buf_lines scope="all"<CR>', desc = "Lines (All)" },
      { "<leader>fL", '<Cmd>Pick buf_lines scope="current"<CR>', desc = "Lines (Buf)" },
      { "<leader>fv", '<Cmd>Pick visit_paths cwd=""<CR>', desc = "Visit Paths (All)" },
      { "<leader>fV", "<Cmd>Pick visit_paths<CR>", desc = "Visit Paths (Cwd)" },
    },
  },
  {
    "nvim-mini/mini.jump",
    version = "*",
    opts = {},
  },
  {
    "nvim-mini/mini.operators",
    version = "*",
    opts = {},
  },
  {
    "nvim-mini/mini.hipatterns",
    version = "*",
    opts = function()
      local hipatterns = require("mini.hipatterns")
      return {
        highlighters = {
          hex_color = hipatterns.gen_highlighter.hex_color(),
        },
      }
    end,
  },
  {
    "nvim-mini/mini.statusline",
    version = "*",
    config = function()
      local agent_status = require("agent_status")
      local statusline = require("mini.statusline")
      local agent_highlights = {
        attention = "MiniStatuslineModeOther",
        activity = "MiniStatuslineDevinfo",
        idle = "MiniStatuslineFilename",
      }
      agent_status.setup()
      statusline.setup()
      statusline.config.content.active = function()
        local agents = agent_status.segments()
        local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
        local git = statusline.section_git({ trunc_width = 40 })
        local diff = statusline.section_diff({ trunc_width = 75 })
        local diagnostics = statusline.section_diagnostics({ trunc_width = 75 })
        local lsp = statusline.section_lsp({ trunc_width = 75 })
        local filename = statusline.section_filename({ trunc_width = 140 })
        local fileinfo = statusline.section_fileinfo({ trunc_width = 120 })
        local location = statusline.section_location({ trunc_width = 75 })
        local search = statusline.section_searchcount({ trunc_width = 75 })

        local groups = {
          { hl = mode_hl, strings = { mode } },
          { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp } },
          "%<",
          { hl = "MiniStatuslineFilename", strings = { filename } },
          "%=",
        }
        for _, agent in ipairs(agents) do
          groups[#groups + 1] = { hl = agent_highlights[agent.status], strings = { agent.text } }
        end
        vim.list_extend(groups, {
          { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
          { hl = mode_hl, strings = { search, location } },
        })
        return statusline.combine_groups(groups)
      end
    end,
  },
  {
    "nvim-mini/mini.tabline",
    version = "*",
    opts = {},
  },
  {
    "nvim-mini/mini.clue",
    version = "*",
    config = function()
      local miniclue = require("mini.clue")
      miniclue.setup({
        triggers = {
          { mode = "n", keys = "<leader>" },
          { mode = "x", keys = "<leader>" },
          { mode = "n", keys = "[" },
          { mode = "n", keys = "]" },
          { mode = { "n", "x" }, keys = "g" },
          { mode = { "n", "x" }, keys = "z" },
          { mode = { "n", "x" }, keys = "'" },
          { mode = { "n", "x" }, keys = "`" },
          { mode = { "n", "x" }, keys = '"' },
          { mode = { "i", "c" }, keys = "<C-r>" },
          { mode = "i", keys = "<C-x>" },
          { mode = "n", keys = "<C-w>" },
          { mode = "n", keys = "\\" }, -- option toggles, see keymaps.lua
        },
        clues = {
          { mode = "n", keys = "<leader>a", desc = "+ai" },
          { mode = "n", keys = "<leader>b", desc = "+buffer" },
          { mode = "n", keys = "<leader>e", desc = "+explore" },
          { mode = "n", keys = "<leader>f", desc = "+file" },
          { mode = "n", keys = "<leader>g", desc = "+git" },
          { mode = "n", keys = "<leader>gh", desc = "+hunk" },
          { mode = "x", keys = "<leader>g", desc = "+git" },
          { mode = "x", keys = "<leader>gh", desc = "+hunk" },
          { mode = "n", keys = "<leader>l", desc = "+language" },
          { mode = "n", keys = "<leader>o", desc = "+other" },
          { mode = "n", keys = "<leader>s", desc = "+session" },
          { mode = "n", keys = "<leader>t", desc = "+terminal" },
          miniclue.gen_clues.square_brackets(),
          miniclue.gen_clues.g(),
          miniclue.gen_clues.z(),
          miniclue.gen_clues.marks(),
          miniclue.gen_clues.registers({ show_contents = true }),
          miniclue.gen_clues.builtin_completion(),
          miniclue.gen_clues.windows(),
        },
        window = {
          delay = 200,
          config = { width = "auto" },
        },
      })

      -- mini.clue only installs its triggers in listed buffers, so leader (and
      -- other prefixes) never fired in the sidekick / snacks terminals — both
      -- are unlisted scratch buffers. Force-enable triggers there. Only normal
      -- and visual modes are hooked, so terminal-mode typing is untouched.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sidekick_terminal", "snacks_terminal" },
        group = vim.api.nvim_create_augroup("junheep_clue_terminals", { clear = true }),
        callback = function(ev)
          miniclue.enable_buf_triggers(ev.buf)
        end,
      })
    end,
  },
}
