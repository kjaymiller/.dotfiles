-- Define a custom HelloWorld command
vim.api.nvim_create_user_command(
    "Marked", -- Command name
    "! open -a Marked %",
    { -- Command options (optional)
        desc = "Opens the current file in Marked",
    }
)

local openTenor = function(query)
    for i, v in pairs(query) do
        print(i, v)
    end

    print("fargs" .. pairs(query["fargs"]))

    -- vim.cmd("!open 'https://tenor.com/search/" .. query["args"] .. "'")
end

vim.api.nvim_create_user_command("Tenor", openTenor, { nargs = "*", range = true })
