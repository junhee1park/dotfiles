-- Loaded early when starting without a file, otherwise on VeryLazy (see config.lazy).

local function augroup(name)
  return vim.api.nvim_create_augroup("junheep_" .. name, { clear = true })
end

-- reload file when it changed externally
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- go to last cursor location when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_loc then
      return
    end
    vim.b[buf].last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "text", "plaintex", "typst", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})
-- markdown — wrap on, no spellcheck
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("markdown_settings"),
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = false
  end,
})

-- don't auto-wrap comments, and don't insert comment leader after `o`/`O`;
-- always override whatever filetype plugins set
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("formatoptions"),
  pattern = "*",
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "o" })
  end,
})

-- auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "man", "qf", "checkhealth", "gitsigns-blame" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set("n", "q", "<cmd>close<cr>", {
        buffer = event.buf,
        silent = true,
        desc = "Quit buffer",
      })
    end)
  end,
})

-- open the entry under the cursor in a split/vsplit/tab, the same <C-s>/<C-v>/<C-t>
-- as Telescope and neo-tree (built-in only has <C-w><CR>, horizontal)
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("qf_split"),
  pattern = "qf",
  callback = function(event)
    local function open(split)
      return function()
        local idx = vim.fn.line(".")
        local cmd = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].loclist == 1 and "ll" or "cc"
        vim.cmd("wincmd p")
        vim.cmd(split)
        vim.cmd(cmd .. " " .. idx)
      end
    end
    for lhs, split in pairs({ ["<C-s>"] = "split", ["<C-v>"] = "vsplit", ["<C-t>"] = "tab split" }) do
      vim.keymap.set("n", lhs, open(split), { buffer = event.buf, desc = "Open in " .. split })
    end
  end,
})

-- close mini.git scratch splits with <q>: :Git diff/log/show, show_at_cursor
-- (commit-show / range-history), AND show_diff_source. All are named minigit://…
-- but their filetype varies (git/diff, or the source file's type like lua for
-- show_diff_source), so match by name on BufWinEnter, not by filetype. All such
-- buffers are scratch (buflisted=false, nofile) — never the real editable file.
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = augroup("close_minigit_with_q"),
  callback = function(event)
    if not vim.api.nvim_buf_get_name(event.buf):match("^minigit://") then
      return
    end
    vim.keymap.set("n", "q", "<cmd>close<cr>", {
      buffer = event.buf,
      silent = true,
      desc = "Quit buffer",
    })
  end,
})

-- detect Hugo go templates in html files
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = augroup("hugo_gotmpl"),
  pattern = "*.html",
  callback = function()
    if vim.fn.search("{{.\\+}}", "nw") ~= 0 then
      vim.bo.filetype = "gotmpl"
    end
  end,
})
