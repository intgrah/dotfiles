-- Simple statusline configuration
vim.o.laststatus = 3 -- Global statusline
vim.o.showmode = false -- Don't show mode in command line

-- Statusline setup
vim.o.statusline =
	-- filename modified readonly | line column progress filetype
	" %f %m %r %= %l:%c %p%% %y"

-- Optional: Customize statusline colors
vim.api.nvim_set_hl(0, "StatusLine", {
	bg = "#2e3440",
	fg = "#d8dee9",
})
vim.api.nvim_set_hl(0, "StatusLineNC", {
	bg = "#3b4252",
	fg = "#4c566a",
})
