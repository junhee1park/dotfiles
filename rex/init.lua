local copy_mode_script = [[
REX_COPY_BLOCK="$1" exec nvim --clean -n -c "luafile $HOME/.config/rex/copy-mode.lua"
]]

-- Finds the block's rectangle as window fractions, searching the layout tree.
-- Returns nil for a copy mode block, so copy mode doesn't open on itself.
local function block_bounds(view, block_id)
  local function find(node)
    if type(node) ~= "table" then return nil end
    if node.block_id == block_id and node.rect then return node.rect end
    for _, child in pairs(node) do
      local rect = find(child)
      if rect then return rect end
    end
  end

  for _, window in ipairs(view.windows or {}) do
    for _, layer in ipairs(window.layers or {}) do
      for _, block in ipairs(layer.blocks or {}) do
        if block.block_id == block_id and block.label == "copy mode" then
          return nil
        end
      end
      local r = find(layer.layout)
      if r then
        local b = layer.bounds
        return window.window_id,
          { b[1] + r[1] * b[3], b[2] + r[2] * b[4], r[3] * b[3], r[4] * b[4] }
      end
    end
  end
end

rex.action{
  name  = "copy_mode",
  title = "Copy Mode",
  description = "Open the focused pane's scrollback in read-only Neovim.",
  run   = function(ctx, args)
    if ctx.block_id == nil then error("no focused pane", 0) end

    local view, err = rex.session.view{}
    if err ~= nil then error(err, 0) end
    local window_id, bounds = block_bounds(view, ctx.block_id)
    if window_id == nil then return end

    local layer
    layer, err = rex.session.new_layer{
      window_id = window_id,
      bounds = bounds,
      focus = true,
      layout = { block = {
        flavor  = "com.superlogical.terminal.shell",
        label   = "copy mode",
        options = { command = { "sh", "-c", copy_mode_script, "sh", ctx.block_id } },
      } },
    }
    if err ~= nil then error(err, 0) end
    return { layer_id = layer.layer_id, block_id = layer.block_ids[1] }
  end,
}

-- Same key as iTerm2's copy mode.
rex.bind("cmd+shift+c", "copy_mode")
