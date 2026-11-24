-- VSCode-style side-by-side diff, review explorer and merge resolution.
-- Complements gitsigns (in-buffer hunks) and mini.git (raw `Git diff`)
-- rather than replacing them: this is the whole-changeset review view.
-- The C diff binary is downloaded on first use, so no compiler is needed.
--
-- Keymaps are left at their defaults except the two that are bare <leader>
-- prefixes: those shadow the buffer / explore which-key groups and make every
-- <leader>b / <leader>e press wait out timeoutlen. The <leader>h* (hunk) and
-- <leader>c* (conflict) defaults keep their own namespace, which this config
-- uses nowhere else -- moving them onto <leader>gh* only made gitsigns win
-- the collision in the working-tree pane and leave the diff view stale.
return {
  "esmuellert/codediff.nvim",
  cmd = "CodeDiff",
  keys = {
    { "<leader>gv", "<Cmd>CodeDiff<CR>", desc = "Review" },
  },
  opts = {
    diff = { layout = "inline" },
    keymaps = {
      view = {
        toggle_explorer = "<leader>ge",
        focus_explorer = "<leader>gE",
      },
    },
  },
}
