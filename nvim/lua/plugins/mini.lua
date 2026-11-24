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
    -- only gen_ai_spec.buffer() is used: the `B` (whole buffer) textobject in mini.ai above
    "nvim-mini/mini.extra",
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
}
