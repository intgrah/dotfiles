local catppuccin = require("catppuccin")

vim.cmd("colorscheme catppuccin")

catppuccin.setup({
	flavour = "frappe",
	transparent_background = false,
	term_colors = true,
	integrations = {
		cmp = true,
		nvimtree = true,
		telescope = true,
		treesitter = true,
		which_key = true,
	},
})
