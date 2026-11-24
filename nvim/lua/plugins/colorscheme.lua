-- Theme system (ported from LazyVim + omarchy theme-hotreload).
--
-- All switcher themes are installed (lazy = true, so no startup cost) and the
-- active one is chosen by `vim.g.active_colorscheme`, which theme.sh sets via
-- lua/plugins/theme.lua (gitignored). That file lives under plugins/ so lazy's
-- change_detection watches it: swapping it on disk fires `User LazyReload`, and
-- the manager below re-applies the colorscheme live -- no restart needed.

-- Make diff output (`:Git diff`, `:Git log --patch`) read like `git` in the
-- terminal, which prints plain ANSI green for `+` and red for `-` on the
-- terminal's own background. `terminal_color_*` is that same palette as the
-- theme publishes it, so it reproduces those colors exactly; theme diff colors
-- are often a different, softer set. Themes that publish no palette keep their
-- own colors, minus the background (a |vimdiff| convention git doesn't share).
local git_diff_groups = {
  { ts = "@diff.plus", syntax = "diffAdded", ansi = 2 },
  { ts = "@diff.minus", syntax = "diffRemoved", ansi = 1 },
}

local function apply_git_diff_colors()
  for _, group in ipairs(git_diff_groups) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group.syntax, link = false })
    if ok then
      hl.fg = vim.g["terminal_color_" .. group.ansi] or hl.fg
      hl.bg = nil
      hl.ctermbg = nil
      pcall(vim.api.nvim_set_hl, 0, group.syntax, hl)
    end
    -- filetype=diff (treesitter) follows filetype=git (vim syntax)
    pcall(vim.api.nvim_set_hl, 0, group.ts, { link = group.syntax })
  end
end

-- gitsigns marks word-level regions inside its inline hunk preview. Once a hunk
-- spans more than a couple of lines the logic has changed wholesale and those
-- matches are noise, so hide them behind the plain added/deleted line colours.
-- Left undefined they would fall back to TermCursor -- the cursor's reverse
-- colours -- and speckle the preview.
local gitsigns_inline_groups = {
  { name = "GitSignsAddInline", to = "GitSignsAddPreview" },
  { name = "GitSignsChangeInline", to = "GitSignsAddPreview" },
  { name = "GitSignsDeleteInline", to = "GitSignsDeleteVirtLn" },
}

local function apply_gitsigns_inline_colors()
  for _, group in ipairs(gitsigns_inline_groups) do
    pcall(vim.api.nvim_set_hl, 0, group.name, { link = group.to })
  end
end

-- The sidekick / snacks terminals draw on the editor background rather than
-- NormalFloat, so a CLI looks the same here as in the terminal it would
-- otherwise run in: themes/<name>/ghostty is cut from the same palette, so its
-- `background` is exactly Normal's bg for every theme we ship.
--
-- TermNormal is the single knob. The border and title carry no background of
-- their own -- only each theme's foreground, copied here -- so they fall through
-- to whatever the terminal window's normal group is and follow it automatically.
local term_float_groups = {
  { name = "TermFloatBorder", from = "FloatBorder" },
  { name = "TermFloatTitle", from = "FloatTitle" },
}

local function apply_terminal_colors()
  pcall(vim.api.nvim_set_hl, 0, "TermNormal", { link = "Normal" })
  for _, group in ipairs(term_float_groups) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group.from, link = false })
    if ok then
      hl.bg = nil
      hl.ctermbg = nil
      pcall(vim.api.nvim_set_hl, 0, group.name, hl)
    end
  end
end

local function active_colorscheme()
  -- re-run plugins/theme.lua fresh so a swap is picked up even if lazy has not
  -- re-imported it yet; the file's side effect sets vim.g.active_colorscheme
  package.loaded["plugins.theme"] = nil
  pcall(require, "plugins.theme")
  local name = vim.g.active_colorscheme
  if type(name) == "string" and name ~= "" then
    return name
  end
  return "tokyonight"
end

local function apply_theme()
  local name = active_colorscheme()
  -- clear stale highlights from the previous theme before switching
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  vim.o.background = "dark"
  -- lazy.nvim loads the theme plugin itself on ColorSchemePre
  pcall(vim.cmd.colorscheme, name)
end

return {
  -- Theme plugins: installed but not loaded at startup (loaded on demand by the
  -- manager). Per-theme config (opts/setup/g:vars) lives in each theme's file
  -- under themes/<name>/neovim.lua and is merged in when that theme is active.
  { "folke/tokyonight.nvim", lazy = true },
  { "catppuccin/nvim", name = "catppuccin", lazy = true },
  { "projekt0n/github-nvim-theme", lazy = true },
  {
    "sainnhe/gruvbox-material",
    lazy = true,
    config = function()
      -- The default grey Visual (bg3 #3c3836) is too dim on the hard bg. Bump it
      -- to #504945 -- the hard palette's own bg5 -- via a ColorScheme autocmd,
      -- since applying the colorscheme resets highlights afterwards.
      -- pattern-guarded so only gruvbox-material is affected.
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("gruvbox_visual", { clear = true }),
        pattern = "gruvbox-material",
        callback = function()
          vim.api.nvim_set_hl(0, "Visual", { bg = "#504945" })
        end,
      })
    end,
  },
  { "rebelot/kanagawa.nvim", lazy = true },

  -- Manager: a local "plugin" (config dir) that applies the active theme on
  -- startup and re-applies it on every LazyReload (i.e. theme.sh disk change).
  {
    name = "theme-manager",
    dir = vim.fn.stdpath("config"),
    lazy = false,
    priority = 1000, -- apply theme before other UI plugins load
    config = function()
      -- keep diff colors in sync with any colorscheme change (startup, switch,
      -- or manual :colorscheme)
      local group = vim.api.nvim_create_augroup("theme_manager", { clear = true })
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function()
          apply_git_diff_colors()
          apply_gitsigns_inline_colors()
          apply_terminal_colors()
        end,
      })
      apply_theme()
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "LazyReload",
        callback = function()
          vim.schedule(function()
            apply_theme()
            vim.cmd("redraw!")
          end)
        end,
      })
    end,
  },
}
