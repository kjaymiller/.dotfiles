return {
  dir = vim.fn.stdpath("config") .. "/lua/local_plugins/linkfinder",
  name = "linkfinder",
  lazy = true,
  cmd = "CollectLinks",
  keys = {
    { "<leader>fL", "<cmd>CollectLinks<cr>", desc = "Collect links in file" },
    { "<leader>fP", "<cmd>CollectLinks!<cr>", desc = "Collect links in project" },
  },
  init = function()
    -- bang (!) = scan the whole project instead of just this buffer
    vim.api.nvim_create_user_command("CollectLinks", function(opts)
      require("local_plugins.linkfinder").collect(opts.bang)
    end, { bang = true, desc = "Collect [url] links and append a Links section" })
  end,
}
