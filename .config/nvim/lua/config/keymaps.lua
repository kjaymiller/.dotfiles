-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- replace <esc> with jk in insert mode

vim.api.nvim_set_keymap("i", "jk", "<esc>", { noremap = true, silent = true })

vim.api.nvim_set_keymap(
    "x",
    "<leader>t",
    ":<C-u>lua SendVisualSelectionToShellCommand()<CR>",
    { noremap = true, silent = true }
)

function SendVisualSelectionToShellCommand()
    local selection = vim.fn.trim(vim.fn.getreg('"'))
    local output = vim.fn.system("searchlink", selection)
    vim.fn.setreg('"', output)
    vim.cmd('normal! gv"=p')
end
