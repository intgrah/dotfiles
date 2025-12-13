---- Leader ----
vim.g.mapleader = " "
vim.g.maplocalleader = " "

---- Line numbers ----
vim.o.number = true
vim.o.relativenumber = true
vim.o.numberwidth = 4

---- Visual indicators ----
vim.o.cursorline = true
vim.o.cursorcolumn = false
vim.o.colorcolumn = "80"
vim.o.signcolumn = "yes"
vim.o.showmode = true
vim.o.showcmd = true
vim.o.ruler = true
vim.o.laststatus = 2

---- Visual feedback ----
vim.o.visualbell = false
vim.o.errorbells = false
vim.o.confirm = true

---- Message and command line ----
vim.o.cmdheight = 1 -- Command line height
vim.o.shortmess = "filnxtToOFcI" -- Comprehensive short messages config:
-- f = use "(3 of 5)" instead of "(file 3 of 5)"
-- i = use "[noeol]" instead of "[Incomplete last line]"
-- l = use "999L, 888C" instead of "999 lines, 888 characters"
-- n = use "[New]" instead of "[New File]"
-- x = use "[dos]" instead of "[dos format]"
-- t = truncate file messages at the start
-- T = truncate other messages in the middle
-- o = overwrite message for writing a file
-- O = message for reading a file overwrites previous
-- F = don't give file info when editing a file
-- c = don't give completion menu messages
-- I = don't give intro message

vim.opt.shortmess:append("W") -- Don't show written message
vim.opt.shortmess:append("A") -- Don't show attention messages
vim.opt.shortmess:append("S") -- Don't show search count

---- Indent ----
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.autoindent = true
vim.o.cindent = false
vim.o.shiftround = true

---- Text ----
vim.o.wrap = false
vim.o.linebreak = true
vim.o.breakindent = true
vim.o.showbreak = "↪ "
vim.o.textwidth = 0

---- Search ----
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hlsearch = true
vim.o.incsearch = true
vim.o.wrapscan = true
vim.o.magic = true

---- Performance ----
vim.o.lazyredraw = false
vim.o.updatetime = 300
vim.o.timeoutlen = 1000
vim.o.ttimeoutlen = 50
vim.o.redrawtime = 2000

---- Files ----
vim.o.hidden = true
vim.o.autoread = true
vim.o.autowrite = false
vim.o.backup = false
vim.o.writebackup = true
vim.o.swapfile = true
vim.o.undofile = true
vim.o.undolevels = 1000
vim.o.undoreload = 10000
vim.o.backupdir = vim.fn.stdpath("state") .. "/backup//"
vim.o.directory = vim.fn.stdpath("state") .. "/swap//"
vim.o.undodir = vim.fn.stdpath("state") .. "/undo//"

---- Completion ----
vim.o.completeopt = "menu,menuone,noselect"
vim.o.wildmenu = true
vim.o.wildmode = "longest:full,full"
vim.o.wildignorecase = true
vim.o.pumheight = 10
vim.o.pumblend = 10

---- Mouse ----
vim.o.mouse = "a"
vim.o.mousemodel = "popup"

---- Split ----
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.splitkeep = "screen"

---- Appearance ----
vim.o.termguicolors = true
vim.o.background = "dark"
vim.o.winblend = 0
vim.o.list = true
vim.o.listchars = "tab:→ ,space:·,nbsp:␣,trail:•,eol:¬,extends:»,precedes:«"
vim.o.fillchars = "vert:│,fold:·,eob:~,diff:╱"

---- Fold ----
vim.o.foldenable = true
vim.o.foldmethod = "indent"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldcolumn = "0"
vim.o.foldtext = "foldtext()"

---- Edit ----
vim.o.virtualedit = "block"
vim.o.clipboard = "unnamedplus"
vim.o.formatoptions = "jcroqlnt"
vim.o.joinspaces = false
vim.o.spell = false
vim.o.spelllang = "en_us"

---- Scroll ----
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8

---- Session ----
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

---- Window ----
vim.wo.wrap = false
vim.wo.number = true
vim.wo.relativenumber = false

---- Buffer ----
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.expandtab = true

---- Features ----
vim.cmd("syntax enable")
vim.cmd("filetype plugin indent on")
vim.cmd("packadd cfilter")
vim.cmd("packadd matchit")
vim.cmd("packadd termdebug")

---- Runtime features ----
vim.g.loaded_netrw = 0 -- Disable netrw (using nvim-tree instead)
vim.g.loaded_netrwPlugin = 0 -- Disable netrw plugin
vim.g.loaded_perl_provider = 0 -- Disable perl provider
vim.g.loaded_ruby_provider = 0 -- Disable ruby provider
vim.g.loaded_node_provider = 0 -- Disable node provider
vim.g.loaded_python_provider = 0 -- Disable python2 provider
vim.g.python3_host_prog = "/usr/bin/python3" -- Set python3 provider

---- Experimental features ----
vim.opt.exrc = true -- Enable project-specific .nvimrc files
vim.opt.secure = true -- Secure mode for exrc
vim.opt.modeline = true -- Enable modelines in files
vim.opt.modelineexpr = false -- Disable expressions in modelines (security)
vim.opt.wildoptions = "pum,tagfile" -- Popup menu for cmdline completion
vim.opt.diffopt:append("algorithm:patience") -- Better diff algorithm
vim.opt.diffopt:append("indent-heuristic") -- Smarter diff indentation
vim.opt.diffopt:append("linematch:60") -- Better line matching
vim.opt.undofile = true -- Persistent undo

-- Better grep
if vim.fn.executable("rg") == 1 then
	vim.opt.grepprg = "rg --vimgrep --smart-case"
	vim.opt.grepformat = "%f:%l:%c:%m"
end

-- Man page viewer
vim.cmd("runtime ftplugin/man.vim") -- Enable :Man command
vim.g.ft_man_open_mode = "vert" -- Open man pages in vertical split

---- KEY MAPPINGS ----
vim.api.nvim_set_keymap("n", "<Leader>w", ":w<CR>", { noremap = true, silent = true })
-- Clear search highlighting
vim.api.nvim_set_keymap("n", "<Esc>", ":nohlsearch<CR>", { noremap = true, silent = true })
-- Reload configuration
vim.api.nvim_set_keymap(
	"n",
	"<Leader>r",
	':source $MYVIMRC<CR>:echo "Config reloaded!"<CR>',
	{ noremap = true, silent = false }
)

---- Directories ----
local function ensure_dir(path)
	if vim.fn.isdirectory(path) == 0 then
		vim.fn.mkdir(path, "p")
	end
end

ensure_dir(vim.o.backupdir)
ensure_dir(vim.o.directory)
ensure_dir(vim.o.undodir)

---- Modules ----
require("user.plugins")
require("user.treesitter")
require("user.lsp")
require("user.completion")
require("user.telescope")
require("user.explorer")
require("user.theme")
require("user.statusline")
