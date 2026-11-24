return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "nvim-mini/mini.completion" },
    opts = {
      servers = {},
    },
    config = function(_, opts)
      vim.lsp.config("*", {
        capabilities = require("mini.completion").get_lsp_capabilities(),
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("junheep_lsp_attach", { clear = true }),
        callback = function(args)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, {
            buffer = args.buf,
            desc = "Goto Definition",
          })
          vim.bo[args.buf].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"
        end,
      })

      vim.diagnostic.config({
        severity_sort = true,
        virtual_lines = { current_line = true },
        float = { source = "if_many" },
      })

      for server, config in pairs(opts.servers) do
        vim.lsp.config(server, config)
        vim.lsp.enable(server)
      end
    end,
  },
}
