return {
  "akinsho/bufferline.nvim",
  -- icons come from mini.icons' nvim-web-devicons mock
  dependencies = { "nvim-mini/mini.icons" },
  opts = {
    options = {
      tab_size = 0,
      close_command = function(n)
        require("snacks").bufdelete(n)
      end,
      right_mouse_command = function(n)
        require("snacks").bufdelete(n)
      end,
      offsets = {
        { filetype = "neo-tree", text = "Neo-tree", highlight = "Directory", text_align = "left" },
      },
    },
  },
}
