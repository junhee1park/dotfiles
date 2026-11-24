local SidekickFloat = {}

-- Tallest float that still leaves the tabline, the statusline/cmdline and the
-- two rows winborder draws outside `height` visible. A height fraction can't do
-- this: those rows are a fixed cost, so small displays end up covered.
local function max_vert()
  local tabline = vim.o.showtabline == 2 or (vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1)
  local top = tabline and 1 or 0
  local bottom = (vim.o.laststatus > 0 and 1 or 0) + vim.o.cmdheight
  return math.max(vim.o.lines - top - bottom - 2, 10), top
end

-- Relayout every open float. Width clamps to 80, sidekick's own minimum.
function SidekickFloat.apply()
  local f = require("sidekick.config").cli.win.float
  local height, row = max_vert()
  local cols = vim.o.columns
  -- Written back as absolute rows (open_win reads > 1 as absolute) so a reopen
  -- starts at this height instead of resizing the PTY right after opening.
  f.height = height
  for _, t in pairs(require("sidekick.cli.terminal").terminals) do
    if t.opts.float then
      t.opts.float.height = height
    end
  end
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local cfg = vim.api.nvim_win_get_config(w)
    if vim.w[w].sidekick_cli ~= nil and cfg.relative ~= "" then
      cfg.width = math.max(math.floor(cols * f.width), 80)
      cfg.height = height
      cfg.row = row
      cfg.col = math.floor((cols - cfg.width) * f.col)
      vim.api.nvim_win_set_config(w, cfg)
    end
  end
end

-- Hold the split at a fixed fraction of the editor. sidekick pins it with
-- winfixwidth, so an nvim resize leaves its absolute width and drifts the ratio;
-- a manual drag (columns unchanged) redefines the ratio instead.
do
  local group = vim.api.nvim_create_augroup("junheep_sidekick_resize", { clear = true })
  local ratio = nil
  local applied_columns = vim.o.columns
  local applied_width = nil -- what we set ourselves, to tell it from a drag
  local resize_generation = 0

  -- splits only; floats are relaid out by SidekickFloat.apply
  local function sidekick_wins()
    return vim.tbl_filter(function(w)
      return vim.w[w].sidekick_cli ~= nil and vim.api.nvim_win_get_config(w).relative == ""
    end, vim.api.nvim_list_wins())
  end

  -- winfixwidth keeps sidekick out of this, so only the editor windows even out
  local function equalize()
    vim.cmd("wincmd =")
  end

  local function relayout()
    applied_columns = vim.o.columns
    SidekickFloat.apply()

    local wins = sidekick_wins()
    if #wins == 0 then
      return
    end

    local r = ratio or (require("sidekick.config").cli.win.split.width or 0.5)
    if r <= 1 then
      applied_width = math.floor(vim.o.columns * r)
      for _, w in ipairs(wins) do
        vim.api.nvim_win_set_width(w, applied_width)
      end
    end
    equalize()
  end

  local function schedule_relayout()
    resize_generation = resize_generation + 1
    local generation = resize_generation
    vim.defer_fn(function()
      if generation == resize_generation then
        relayout()
      end
    end, 80)
  end

  vim.api.nvim_create_autocmd("WinResized", {
    group = group,
    callback = function()
      if vim.o.columns ~= applied_columns then
        return -- side effect of an nvim resize, not a drag
      end
      for _, w in ipairs(sidekick_wins()) do
        local width = vim.api.nvim_win_get_width(w)
        if width ~= applied_width then
          ratio = width / vim.o.columns
          applied_width = nil
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = schedule_relayout,
  })

  -- A split opens with an explicit width, so nvim skips equalalways and leaves
  -- the other windows uneven; a float opens from the config fractions and needs
  -- snapping. It opens with enter=false, so resolve the window from the buffer.
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function(ev)
      if vim.bo[ev.buf].filetype ~= "sidekick_terminal" then
        return
      end
      local win = vim.fn.bufwinid(ev.buf)
      if win == -1 then
        return
      end
      if vim.api.nvim_win_get_config(win).relative == "" then
        vim.schedule(equalize)
      else
        vim.schedule(SidekickFloat.apply)
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(ev)
      local win = tonumber(ev.match)
      if win and vim.w[win].sidekick_cli ~= nil and vim.api.nvim_win_get_config(win).relative == "" then
        vim.schedule(equalize)
      end
    end,
  })
end
return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      -- Ghost text shows while typing; <M-]> / <M-[> cycle suggestions.
      suggestion = {
        auto_trigger = true,
        hide_during_completion = true,
        keymap = {
          accept = false, -- accepted via the <Tab> smart-tab in config/keymaps.lua
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
    },
  },
  {
    "folke/sidekick.nvim",
    cmd = "Sidekick",
    opts = {
      nes = { enabled = false },
      cli = {
        win = {
          layout = "right",
          split = { width = 0.5 },
          -- right-anchored sidebar; col is a fraction of the leftover space, so
          -- 0.96 leaves a small gap from the edge. height is replaced below.
          float = { width = 0.4, height = 0.92, col = 0.96, row = 0 },
          -- runs per-terminal on the snapshot open_win reads, so each tool gets
          -- its own border title
          config = function(terminal)
            terminal.opts.float.height = max_vert()
            local tool = terminal.tool and terminal.tool.name
            if not tool then
              return
            end
            if tool == "codex" or tool == "codex_resume" then
              terminal.opts.keys.ctrl_slash = {
                "<c-_>",
                function(t)
                  if t.job and t:is_running() then
                    vim.api.nvim_chan_send(t.job, "\27[47;5u")
                  end
                end,
                mode = "t",
                desc = "Send Ctrl+/",
              }
            end
            local labels = { claude = "Claude Code", claude_continue = "Claude Code", codex_resume = "Codex" }
            local label = labels[tool] or tool:sub(1, 1):upper() .. tool:sub(2)
            terminal.opts.float.title = " Sidekick - " .. label .. " "
          end,
          wo = {
            -- pin the terminal so the jumplist and stray :edits can't replace it
            winfixbuf = true,
            -- the Term* groups (plugins/colorscheme.lua) put the CLI on the
            -- editor background instead of NormalFloat, matching ghostty
            winhighlight = "Normal:TermNormal,NormalNC:TermNormal,EndOfBuffer:TermNormal,SignColumn:TermNormal,"
              .. "FloatBorder:TermFloatBorder,FloatTitle:TermFloatTitle",
          },
          keys = {
            -- sidekick's prompt picker shadows the CLI's own <C-p> history nav
            prompt = false,
          },
        },
        tools = {
          claude_continue = { cmd = { "claude", "--continue" } },
          codex_resume = { cmd = { "codex", "resume" } },
        },
      },
    },
    keys = {
      -- Window control is on ctrl chords so it works while typing in the CLI;
      -- everything else sits under <leader>a.
      {
        -- cli.toggle() verbatim except for the final focus(), which forces
        -- insert mode: set_current_win lets sidekick's WinEnter restore the
        -- mode the terminal was hidden in.
        "<c-.>",
        function()
          require("sidekick.cli.state").with(function(state, attached)
            local t = state and state.terminal
            if not t then
              return
            end
            if not attached then
              t:toggle()
            end
            if t:is_open() and t:is_running() then
              vim.api.nvim_set_current_win(t.win)
            end
          end, { attach = true, filter = { installed = true } })
        end,
        desc = "Toggle CLI",
        mode = { "n", "t", "i", "x" },
      },
      {
        -- same reason as <c-.>: cli.focus() would startinsert() on the way in
        "<c-;>",
        function()
          require("sidekick.cli.state").with(function(state)
            local t = state and state.terminal
            if not t then
              return
            end
            if t:is_focused() then
              t:blur()
            elseif t:is_running() then
              vim.api.nvim_set_current_win(t.win)
            end
          end, {
            attach = true,
            filter = { installed = true },
            focus = false,
            show = true,
          })
        end,
        desc = "Toggle Focus",
        mode = { "n", "t" },
      },
      {
        "<c-,>",
        function()
          require("sidekick.cli.state").with(function(state)
            local t = state and state.terminal
            if not t then
              return
            end
            -- open_win() re-reads opts.layout, so hide->show swaps the window
            -- while the CLI process (and its session) stays alive
            t.opts.layout = t.opts.layout == "float" and "right" or "float"
            t:hide()
            t:show()
            t:focus()
          end, { filter = { installed = true } })
        end,
        desc = "Toggle Layout (float/split)",
        mode = { "n", "t" },
      },
      {
        "<leader>ac",
        function()
          require("sidekick.cli").toggle({ name = "claude", focus = true })
        end,
        desc = "Claude",
      },
      {
        "<leader>aC",
        function()
          require("sidekick.cli").toggle({ name = "claude_continue", focus = true })
        end,
        desc = "Claude --continue",
      },
      {
        "<leader>as",
        function()
          require("sidekick.cli").select({ filter = { installed = true } })
        end,
        desc = "Select CLI",
      },
      {
        "<leader>ad",
        function()
          require("sidekick.cli").close()
        end,
        desc = "Detach Session",
      },
      {
        "<leader>at",
        function()
          require("sidekick.cli").send({ msg = "{this}" })
        end,
        mode = { "n", "x" },
        desc = "Send This",
      },
      {
        "<leader>af",
        function()
          require("sidekick.cli").send({ msg = "{file}" })
        end,
        desc = "Send File",
      },
      {
        "<leader>av",
        function()
          require("sidekick.cli").send({ msg = "{selection}" })
        end,
        mode = { "x" },
        desc = "Send Selection",
      },
    },
  },
}
