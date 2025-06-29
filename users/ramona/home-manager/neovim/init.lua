package.path = package.path .. ";" .. "~/.config/nvim/?.lua"

require("ramona/blink")
require("ramona/lsp")
require("ramona/neo-tree")
require("ramona/telescope")

require("auto-save").setup({})
require("kanagawa").setup({})

require("nvim-treesitter.configs").setup({
	highlight = { enable = true },
	indent = { enable = true },
})

require("treesitter-context").setup({
	max_lines = 1,
})

vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1 })
end)
vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1 })
end)
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)

vim.g.mapleader = " "
vim.o.tabstop = 4
vim.o.expandtab = true
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.relativenumber = true
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
	command = "if mode() != 'c' | checktime | endif",
	pattern = { "*" },
})

vim.cmd("colorscheme kanagawa-dragon")
vim.cmd("highlight Normal guibg=none")
vim.cmd("highlight NonText guibg=none")
vim.cmd("highlight Normal ctermbg=none")
vim.cmd("highlight NonText ctermbg=none")
