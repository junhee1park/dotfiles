local block = os.getenv("REX_COPY_BLOCK")
local chunk = 983040

local function call(method, args)
  local r = vim.system({ "rex", "block", "call", method, "-b", block, vim.json.encode(args) }, { text = true }):wait()
  if r.code ~= 0 then error(r.stderr, 0) end
  return vim.json.decode(r.stdout)
end

-- The layer starts at 80x24 until the app sizes it; drawing before then would rewrap every line.
-- The app's size can differ from the pane's by a cell or two, so wait for any change, not an exact match.
local size = call("size", vim.empty_dict())
vim.wait(3000, function()
  return vim.o.columns >= size.columns or vim.o.columns ~= 80 or vim.o.lines ~= 24
end, 10)

-- extra_cursor keeps the blank rows below the cursor, so the screen lines up with the pane.
local reply = call("format", { format = "vt", extra_cursor = true, extra_palette = true, max_bytes = chunk })
local parts = { reply.content }
if reply.id then
  local offset = #reply.content
  repeat
    local r = call("blob_read", { id = reply.id, offset = offset, max_bytes = chunk })
    parts[#parts + 1] = r.data
    offset = offset + #r.data
  until r.eof
end
local data = table.concat(parts)

vim.o.title = true
vim.o.titlestring = "copy mode"
vim.o.laststatus = 0
vim.o.cmdheight = 0
vim.o.ruler = false
vim.o.showmode = false
vim.o.showcmd = false
vim.o.clipboard = "unnamedplus"
-- Closing the layer would otherwise hand focus to whichever pane Rex picks.
local function close()
  vim.system({ "rex", "focus", block }):wait()
  vim.cmd("qa!")
end
vim.keymap.set("n", "q", close)
vim.keymap.set("n", "<Esc>", close)

-- Use the pane's theme: its 16 ANSI colors, and the host terminal's default background and text.
for n, r, g, b in data:gmatch("\27%]4;(%d+);rgb:(%x+)/(%x+)/(%x+)\27\\") do
  if tonumber(n) < 16 then
    vim.g["terminal_color_" .. n] = "#" .. r:sub(1, 2) .. g:sub(1, 2) .. b:sub(1, 2)
  end
end
-- Neovim reloads its default colors once it detects the background, so clear Normal again then.
local function clear_normal() vim.api.nvim_set_hl(0, "Normal", {}) end
clear_normal()
vim.api.nvim_create_autocmd({ "ColorScheme", "OptionSet" }, { pattern = { "*", "background" }, callback = clear_normal })

local buf = vim.api.nvim_get_current_buf()
vim.bo[buf].scrollback = 100000
-- There's no process behind the buffer, so Terminal mode would only swallow keys.
for _, key in ipairs({ "i", "I", "a", "A", "<Insert>" }) do
  vim.keymap.set("n", key, "<Nop>", { buffer = buf })
end
local chan = vim.api.nvim_open_term(buf, {})
vim.api.nvim_chan_send(chan, data)

-- The terminal processes data asynchronously; wait until every line has arrived.
local _, newlines = data:gsub("\n", "")
vim.wait(5000, function() return vim.api.nvim_buf_line_count(buf) > newlines end, 10)

local row, col = data:match("\27%[(%d+);(%d+)H$")
local last = vim.api.nvim_buf_line_count(buf)
if row then
  local line = last - size.rows + tonumber(row)
  pcall(vim.api.nvim_win_set_cursor, 0, { math.max(line, 1), tonumber(col) - 1 })
else
  vim.cmd("normal! G")
end
