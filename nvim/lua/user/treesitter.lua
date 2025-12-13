require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"lua",
		"vim",
		"vimdoc",
		"ocaml",
		"haskell",
		"rust",
		"javascript",
		"typescript",
		"python",
		"go",
		"html",
		"css",
		"json",
		"yaml",
		"toml",
		"markdown",
		"bash",
	},
	modules = {},
	ignore_install = {},
	sync_install = true,
	auto_install = true, -- Automatically install missing parsers
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
	indent = { enable = true },
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "<CR>",
			node_incremental = "<CR>",
			node_decremental = "<BS>",
		},
	},
})
