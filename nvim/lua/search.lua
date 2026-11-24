-- Telescope files/grep shared by the <leader>f keys (plugins/telescope.lua) and
-- the dashboard (plugins/snacks.lua). They start with dotfiles shown and
-- gitignored files hidden; inside the picker <M-h> / <M-i> toggle each one and
-- reopen it with the typed query (like LazyVim's Telescope extra /
-- snacks.picker). .git/ is always skipped.
local M = {}

---@param kind "find_files"|"live_grep"
---@param base? table extra picker opts (e.g. cwd), kept across toggles
---@param flags? {hidden:boolean, no_ignore:boolean}
function M.search(kind, base, flags)
  base = base or {}
  flags = flags or { hidden = true, no_ignore = false }
  local on = {}
  for _, f in ipairs({ "hidden", "no_ignore" }) do
    if flags[f] then
      on[#on + 1] = f
    end
  end
  local opts = vim.tbl_extend("force", base, {
    prompt_title = (kind == "find_files" and "Find Files" or "Live Grep")
      .. (#on > 0 and " (" .. table.concat(on, ", ") .. ")" or ""),
    attach_mappings = function(_, map)
      for key, flag in pairs({ ["<M-h>"] = "hidden", ["<M-i>"] = "no_ignore" }) do
        map({ "i", "n" }, key, function(bufnr)
          local line = require("telescope.actions.state").get_current_line()
          require("telescope.actions").close(bufnr)
          M.search(
            kind,
            vim.tbl_extend("force", base, { default_text = line }),
            vim.tbl_extend("force", flags, { [flag] = not flags[flag] })
          )
        end, { desc = "Toggle " .. flag })
      end
      return true
    end,
  })
  local args = flags.hidden and { "--hidden", "-g", "!.git" } or {}
  if flags.no_ignore then
    table.insert(args, "--no-ignore")
  end
  if kind == "find_files" then
    opts.find_command = vim.list_extend({ "rg", "--files", "--color", "never" }, args)
  else
    opts.additional_args = args
  end
  require("telescope.builtin")[kind](opts)
end

return M
