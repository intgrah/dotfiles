local neodev = require("neodev")
local mason = require("mason")

local mason_lspconfig = require("mason-lspconfig")
local cmp_lsp = require("cmp_nvim_lsp")

neodev.setup({
	library = {
		enabled = true,
		runtime = true,
		types = true,
		plugins = true,
	},
	setup_jsonls = true,
	lspconfig = true,
	pathStrict = true,
})

mason.setup({
	ui = {
		icons = {
			package_installed = "✓",
			package_pending = "➜",
			package_uninstalled = "✗",
		},
	},
})

-- Connect Mason with lspconfig
mason_lspconfig.setup({
	-- Automatically install these servers
	ensure_installed = {
		"lua_ls", -- Lua
		"pyright", -- Python
		"rust_analyzer", -- Rust
		"gopls", -- Go
		"clangd", -- C/C++
	},
	automatic_installation = true,
})

-- Set up LSP capabilities (used by completion)
local capabilities = vim.lsp.protocol.make_client_capabilities()

capabilities = cmp_lsp.default_capabilities(capabilities)

-- Function to set up all installed LSP servers
local on_attach = function(client, bufnr)
	-- Enable completion triggered by <c-x><c-o>
	vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

	-- Key mappings
	local bufopts = { noremap = true, silent = true, buffer = bufnr }
	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
	vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
	vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
	vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
	vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
	vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
	vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
	vim.keymap.set("n", "<leader>lf", function()
		vim.lsp.buf.format({ async = true })
	end, bufopts)

	-- Log a message when a server attaches
	vim.notify(string.format("LSP server '%s' attached", client.name), vim.log.levels.INFO)
end

-- Configure individual servers before enabling them
vim.lsp.config("lua_ls", {
	on_attach = on_attach,
	capabilities = capabilities,
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
				path = vim.split(package.path, ";"),
			},
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = {
					-- Make the server aware of Neovim runtime files
					vim.env.VIMRUNTIME,
					vim.fn.stdpath("config") .. "/lua",
					vim.fn.stdpath("data") .. "/site",
					vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua",
					vim.fn.stdpath("data") .. "/lazy/neodev.nvim/types/stable",
					-- Add plugin paths manually
					vim.fn.stdpath("data") .. "/lazy/plenary.nvim/lua",
					vim.fn.stdpath("data") .. "/lazy/mason.nvim/lua",
					vim.fn.stdpath("data") .. "/lazy/mason-lspconfig.nvim/lua",
					vim.fn.stdpath("data") .. "/lazy/nvim-cmp/lua",
					vim.fn.stdpath("data") .. "/lazy/telescope.nvim/lua",
					vim.fn.stdpath("data") .. "/lazy/catppuccin/lua",
					vim.fn.stdpath("data") .. "/lazy/nvim-tree.lua/lua",
				},
				checkThirdParty = false,
				maxPreload = 10000,
				preloadFileSize = 10000,
			},
			completion = {
				callSnippet = "Replace",
				keywordSnippet = "Replace",
			},
			telemetry = { enable = false },
		},
	},
})

-- Configure default settings for all other servers
local servers = { "pyright", "rust_analyzer", "gopls", "clangd" }
for _, server in ipairs(servers) do
	vim.lsp.config(server, {
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

-- Configure diagnostic display
vim.diagnostic.config({
	virtual_text = {
		prefix = "●",
		source = "if_many",
	},
	float = {
		source = "always",
		border = "rounded",
	},
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})

-- Change diagnostic symbols in the sign column
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
