local telescope = require("telescope")
local builtin = require("telescope.builtin")

telescope.setup({
	defaults = {
		prompt_prefix = "🔍 ",
		selection_caret = "❯ ",
		path_display = { "truncate" },
		layout_config = {
			horizontal = {
				preview_width = 0.55,
				results_width = 0.8,
			},
			width = 0.87,
			height = 0.80,
			preview_cutoff = 120,
		},
		file_ignore_patterns = {
			"node_modules/",
			".git/",
			".DS_Store",
		},
	},
	extensions = {
		-- Configure any extensions here
	},
})

-- Load telescope extensions if available
-- Keep pcall here since fzf extension is optional
pcall(telescope.load_extension, telescope, "fzf")

-- Telescope mappings
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
-- LSP-related searches
vim.keymap.set("n", "<leader>fd", builtin.lsp_definitions, { desc = "Find definitions" })
vim.keymap.set("n", "<leader>fr", builtin.lsp_references, { desc = "Find references" })
