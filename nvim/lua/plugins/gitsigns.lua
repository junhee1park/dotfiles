-- Replaces mini.diff. Keymap layout follows LazyVim's gitsigns setup:
-- [h/]h navigation (falling back to built-in [c/]c in diff windows), hunk
-- actions under <leader>gh (which-key group), ih text object.
-- stage_hunk toggles: on a staged hunk it unstages (undo_stage_hunk is
-- deprecated).
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    -- Both tables merge with the defaults, so the kinds left out keep theirs.
    signs = {
      delete = { text = "" },
      topdelete = { text = "" },
    },
    signs_staged = {
      delete = { text = "" },
      topdelete = { text = "" },
    },
    on_attach = function(bufnr)
      local gs = require("gitsigns")
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
      end
      map("n", "]h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gs.nav_hunk("next")
        end
      end, "Next Hunk")
      map("n", "[h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gs.nav_hunk("prev")
        end
      end, "Prev Hunk")
      map("n", "]H", function()
        gs.nav_hunk("last")
      end, "Last Hunk")
      map("n", "[H", function()
        gs.nav_hunk("first")
      end, "First Hunk")
      map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
      map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
      map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
      map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
      map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
      map("n", "<leader>gb", gs.blame, "Blame Buffer")
      map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select Hunk")
    end,
  },
}
