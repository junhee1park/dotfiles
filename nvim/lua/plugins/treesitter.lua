return {
  {
    -- provides the queries/<lang>/textobjects.scm query files that
    -- mini.ai's treesitter-backed textobjects (function, block) read from;
    -- its own select/move/swap API is unused, so no setup() call needed
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- the rewrite; the classic API lives on master, which is locked
    lazy = false, -- per README: this plugin does not support lazy-loading
    build = ":TSUpdate", -- rebuild parsers to versions the plugin expects on install/update
    -- merge (not override) ensure_installed across lang/*.lua fragments
    opts_extend = { "ensure_installed" },
    opts = {
      -- base parsers: always installed so highlighting survives even if a
      -- lang/*.lua file is removed. Core already bundles c/lua/markdown/
      -- markdown_inline/query/vim/vimdoc, so those are omitted here.
      ensure_installed = {
        -- support parsers (injected into other languages, never edited directly)
        "regex",
        "diff",
        "luadoc",
        -- daily languages
        "javascript",
        "typescript",
        "jsdoc",
        "python",
        "ruby",
        "bash",
        -- ubiquitous data / markup
        "json",
        "json5",
        "yaml",
        "toml",
        "html",
        "css",
      },
    },
    config = function(_, opts)
      -- main branch has no auto-install: we read ensure_installed ourselves
      -- and install any parsers that aren't present yet.
      local TS = require("nvim-treesitter")
      local have = TS.get_installed()
      local missing = vim.tbl_filter(function(lang)
        return not vim.tbl_contains(have, lang)
      end, opts.ensure_installed or {})
      if #missing > 0 then
        TS.install(missing)
      end

      -- main branch enables nothing on its own; wire the core features per
      -- buffer. Any filetype with a parser gets highlighting + folds.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("junheep_treesitter", { clear = true }),
        callback = function()
          -- highlight: pcall is a no-op for filetypes without a parser
          if not pcall(vim.treesitter.start) then
            return
          end

          vim.wo[0][0].foldmethod = "expr"
          vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"

          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
  {
    -- Pins the enclosing scope (function/class/if...) to the top of the window
    -- as a float, so the header of whatever you are inside stays visible while
    -- scrolling. Reads `vim.treesitter` directly and ships its own
    -- queries/<lang>/context.scm, so it is unaffected by the main-branch
    -- rewrite above -- all it needs from it is an installed parser.
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      -- unlimited by default, which lets deeply nested code eat a third of the
      -- window; trim_scope defaults to 'outer', so the lines dropped past the
      -- limit are the outermost -- the innermost scope stays.
      max_lines = 3,
    },
  },
}
