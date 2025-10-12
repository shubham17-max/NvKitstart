--[[
init.lua - Example Neovim configuration (OOP Style)
Author: BillyBoyMF
License: MIT
Description:
  This is a modern Neovim config using lazy.nvim for plugin management.
  Plugins included: LSP, completion, formatting, file explorer, statusline, colorschemes, etc.

Usage:
  Place this file as ~/.config/nvim/init.lua (or appropriate config path).
  Requires Neovim 0.9+ and git.

Contributing:
  See CONTRIBUTING.md in this repository for details.
]]

local NvConfig = {}
NvConfig.__index = NvConfig

-- Create a new config instance. You can subclass this by extending NvConfig.
function NvConfig:new()
	local self = setmetatable({}, NvConfig)
	return self
end

-- Bootstraps lazy.nvim if not already present.
function NvConfig:bootstrap_lazy()
	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
	if not (vim.uv or vim.loop).fs_stat(lazypath) then
		local lazyrepo = "https://github.com/folke/lazy.nvim.git"
		local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
		if vim.v.shell_error ~= 0 then
			vim.api.nvim_echo({
				{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
				{ out, "WarningMsg" },
				{ "\nPress any key to exit..." },
			}, true, {})
			vim.fn.getchar()
			os.exit(1)
		end
	end
	vim.opt.rtp:prepend(lazypath)
end

-- Set global and local leader keys.
function NvConfig:set_leaders()
	vim.g.mapleader = " "
	vim.g.maplocalleader = "\\"
end

-- Main plugin specification.
-- CONTRIBUTION: To add a new plugin, add a new table to spec below.
-- Example:
-- {
--   "author/plugin-name",
--   config = function()
--     -- plugin setup code
--   end,
--   opts = { ... },
--   dependencies = { ... },
-- }
function NvConfig:setup_plugins()
	require("lazy").setup({
		ui = {
			icons = {
				cmd = "⌘",
				config = "🛠",
				event = "📅",
				ft = "📂",
				init = "⚙",
				keys = "🗝",
				plugin = "🔌",
				runtime = "💻",
				require = "🌙",
				source = "📄",
				start = "🚀",
				task = "📌",
				lazy = "💤 ",
			},
		},
		spec = {
			-- Example plugin entry. Add new plugins here!
			{
				"neovim/nvim-lspconfig",
				config = function()
					vim.lsp.config("*", {
						capabilities = {
							textDocument = { semanticTokens = { multilineTokenSupport = true } },
						},
					})
					vim.lsp.config("lua_ls", {
						on_init = function(client)
							if client.workspace_folders then
								local path = client.workspace_folders[1].name
								if
									path ~= vim.fn.stdpath("config")
									and (
										vim.uv.fs_stat(path .. "/.luarc.json")
										or vim.uv.fs_stat(path .. "/.luarc.jsonc")
									)
								then
									return
								end
							end
							client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
								runtime = {
									version = "LuaJIT",
									path = { "lua/?.lua", "lua/?/init.lua" },
								},
								workspace = {
									checkThirdParty = false,
									library = { vim.env.VIMRUNTIME },
								},
							})
						end,
						settings = { Lua = {} },
					})
				end,
			},
			-- Add further plugins below this line for completion, formatting, UI, etc.
			-- See CONTRIBUTING.md for plugin conventions.
			{
				"saghen/blink.cmp",
				dependencies = { "rafamadriz/friendly-snippets" },
				version = "1.*",
				config = function()
					require("blink.cmp").setup({
						keymap = { preset = "default" },
						appearance = { nerd_font_variant = "mono" },
						completion = {
							documentation = { auto_show = false },
							menu = {
								draw = {
									components = {
										kind_icon = {
											text = function(ctx)
												local kind_icon, _, _ = require("mini.icons").get("lsp", ctx.kind)
												return kind_icon
											end,
											highlight = function(ctx)
												local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
												return hl
											end,
										},
										kind = {
											highlight = function(ctx)
												local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
												return hl
											end,
										},
									},
								},
							},
						},
						sources = { default = { "lsp", "path", "snippets", "buffer" } },
						fuzzy = { implementation = "prefer_rust_with_warning" },
					})
					local capabilities = vim.lsp.protocol.make_client_capabilities()
					capabilities =
						vim.tbl_deep_extend("force", capabilities, require("blink.cmp").get_lsp_capabilities({}, false))
					capabilities = vim.tbl_deep_extend("force", capabilities, {
						textDocument = {
							foldingRange = {
								dynamicRegistration = false,
								lineFoldingOnly = true,
							},
						},
					})
				end,
				opts_extend = { "sources.default" },
			},
			{
				"stevearc/conform.nvim",
				config = function()
					require("conform").setup({ formatters_by_ft = { lua = { "stylua" } } })
					vim.api.nvim_create_autocmd("BufWritePre", {
						pattern = "*",
						callback = function(args)
							require("conform").format({ bufnr = args.buf })
						end,
					})
					vim.api.nvim_create_user_command("Format", function(args)
						local range = nil
						if args.count ~= -1 then
							local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
							range = { start = { args.line1, 0 }, ["end"] = { args.line2, end_line:len() } }
						end
						require("conform").format({ async = true, lsp_format = "fallback", range = range })
					end, { range = true })
				end,
			},
			{
				"mason-org/mason.nvim",
				opts = {
					ui = { icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" } },
				},
			},
			{
				"nvim-treesitter/nvim-treesitter",
				branch = "master",
				lazy = false,
				build = ":TSUpdate",
				config = function()
					require("nvim-treesitter.configs").setup({
						ensure_installed = {
							"c",
							"cpp",
							"java",
							"javascript",
							"html",
							"css",
							"typescript",
							"lua",
							"vim",
							"vimdoc",
							"query",
							"markdown",
							"markdown_inline",
						},
						auto_install = true,
					})
				end,
				dependencies = { "nvim-treesitter/nvim-treesitter-context" },
			},
			{
				"stevearc/oil.nvim",
				opts = {},
				lazy = false,
			},
			{
				"mason-org/mason-lspconfig.nvim",
				opts = { ensure_installed = { "lua_ls", "rust_analyzer", "clangd" } },
				dependencies = { { "mason-org/mason.nvim", opts = {} } },
			},
			{
				"romgrk/barbar.nvim",
				dependencies = { "lewis6991/gitsigns.nvim" },
				init = function()
					vim.g.barbar_auto_setup = false
				end,
				opts = { icons = { button = "X", filetype = { enabled = false } } },
				version = "^1.0.0",
			},
			{
				"nvim-telescope/telescope.nvim",
				branch = "0.1.x",
				dependencies = { "nvim-lua/plenary.nvim" },
			},
			{
				"folke/which-key.nvim",
				event = "VeryLazy",
				opts = {
					icons = {
						mappings = false,
						keys = { Esc = "ESC ", BS = "BS", C = "^ ", Space = "SPACE " },
					},
				},
				-- CONTRIBUTION: Add global or buffer keymaps here.
				-- Each entry: { "<keys>", "<command>", desc = "Description", mode = "n" }
				keys = {
					{
						"<leader>?",
						function()
							require("which-key").show({ global = false })
						end,
						desc = "Buffer Local Keymaps (which-key)",
					},
				},
			},
			{
				"nvim-mini/mini.nvim",
				version = false,
				dependencies = {
					{
						"nvim-mini/mini.indentscope",
						version = false,
						config = function()
							require("mini.indentscope").setup()
						end,
					},
					{
						"nvim-mini/mini.statusline",
						version = false,
						config = function()
							require("mini.statusline").setup({ use_icons = false })
						end,
					},
					{ "nvim-mini/mini.icons", version = false, opts = { style = "ascii" } },
				},
			},
			{
				"folke/noice.nvim",
				event = "VeryLazy",
				opts = {
					cmdline = {
						format = {
							cmdline = { icon = ">" },
							search_down = { icon = "🔍⌄" },
							search_up = { icon = "🔍⌃" },
							filter = { icon = "$" },
							lua = { icon = "☾" },
							help = { icon = "?" },
							calculator = { icon = "🖩" },
							input = { icon = "🔣" },
						},
					},
					format = {
						level = { icons = { error = "✖", warn = "▼", info = "●" } },
					},
					popupmenu = { kind_icons = false },
					inc_rename = { cmdline = { format = { IncRename = { icon = "⟳" } } } },
				},
				dependencies = { "MunifTanjim/nui.nvim" },
			},
			{
				"zaldih/themery.nvim",
				lazy = false,
				config = function()
					require("themery").setup({
						themes = {
							{ name = "Tokyo Night Moon", colorscheme = "tokyonight-moon" },
							{ name = "Tokyo Night Storm", colorscheme = "tokyonight-storm" },
							{ name = "Tokyo Night Night", colorscheme = "tokyonight-night" },
							{ name = "Tokyo Night Day", colorscheme = "tokyonight-day" },
						},
						livePreview = true,
					})
				end,
				dependencies = {
					{ "folke/tokyonight.nvim", lazy = false, priority = 1000, opts = {} },
				},
			},
		},
		-- CONTRIBUTION: You can change default colorscheme or update checker options below.
		install = { colorscheme = { "habamax" } },
		checker = { enabled = true },
	})
end

-- Editor options.
-- CONTRIBUTION: Add new options here or override defaults.
function NvConfig:set_options()
	vim.o.number = true
	vim.o.cursorline = true
	vim.o.clipboard = "unnamedplus"
	vim.o.showcmd = true
	vim.o.tabstop = 4
	vim.o.smartindent = true
	vim.o.smarttab = true
end

-- Diagnostics configuration.
-- CONTRIBUTION: Extend with new diagnostics logic as needed.
function NvConfig:setup_diagnostics()
	vim.diagnostic.config({ virtual_text = false })
	vim.o.updatetime = 250
	vim.cmd([[autocmd CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false})]])
end

-- Entrypoint for setup.
-- CONTRIBUTION: You may call individual setup methods for testing or override in subclasses.
function NvConfig:setup()
	self:bootstrap_lazy()
	self:set_leaders()
	self:setup_plugins()
	self:set_options()
	self:setup_diagnostics()
end

function NvConfig:InitLocalWhichKeyMappings()
	require("which-key").register({
		f = {
			name = "Local Keymaps",
			f = { "<cmd>Telescope find_files<cr>", "Telescope find files" },
			g = { "<cmd>Telescope live_grep<cr>", "Telescope live grep" },
			b = { "<cmd>Telescope buffers<cr>", "Telescope buffers" },
			h = { "<cmd>Telescope help_tags<cr>", "Telescope help tags" },
			o = { "<cmd>Oil<cr>", "Opens a file explorer" },
		},
	}, { prefix = "<leader>" })
end

function NvConfig:InitBufferKeymaps()
	require("which-key").register({
		b = {
			name = "Buffer",
			[","] = { "<Cmd>BufferPrevious<CR>", "Previous buffer" },
			["."] = { "<Cmd>BufferNext<CR>", "Next buffer" },
			["<"] = { "<Cmd>BufferMovePrevious<CR>", "Move buffer left" },
			[">"] = { "<Cmd>BufferMoveNext<CR>", "Move buffer right" },
			["1"] = { "<Cmd>BufferGoto 1<CR>", "Go to buffer 1" },
			["2"] = { "<Cmd>BufferGoto 2<CR>", "Go to buffer 2" },
			["3"] = { "<Cmd>BufferGoto 3<CR>", "Go to buffer 3" },
			["4"] = { "<Cmd>BufferGoto 4<CR>", "Go to buffer 4" },
			["5"] = { "<Cmd>BufferGoto 5<CR>", "Go to buffer 5" },
			["6"] = { "<Cmd>BufferGoto 6<CR>", "Go to buffer 6" },
			["7"] = { "<Cmd>BufferGoto 7<CR>", "Go to buffer 7" },
			["8"] = { "<Cmd>BufferGoto 8<CR>", "Go to buffer 8" },
			["9"] = { "<Cmd>BufferGoto 9<CR>", "Go to buffer 9" },
			["0"] = { "<Cmd>BufferLast<CR>", "Go to last buffer" },
			p = { "<Cmd>BufferPin<CR>", "Pin/unpin buffer" },
			gp = { "<Cmd>BufferGotoPinned<CR>", "Go to pinned buffer" },
			gu = { "<Cmd>BufferGotoUnpinned<CR>", "Go to unpinned buffer" },
			c = { "<Cmd>BufferClose<CR>", "Close buffer" },
			w = { "<Cmd>BufferWipeout<CR>", "Wipeout buffer" },
			aa = { "<Cmd>BufferCloseAllButCurrent<CR>", "Close all but current" },
			ap = { "<Cmd>BufferCloseAllButPinned<CR>", "Close all but pinned" },
			ao = { "<Cmd>BufferCloseAllButCurrentOrPinned<CR>", "Close all but current/pinned" },
			al = { "<Cmd>BufferCloseBuffersLeft<CR>", "Close buffers left" },
			ar = { "<Cmd>BufferCloseBuffersRight<CR>", "Close buffers right" },
			P = { "<Cmd>BufferPick<CR>", "Magic buffer pick mode" },
			PD = { "<Cmd>BufferPickDelete<CR>", "Magic buffer pick delete" },
			ob = { "<Cmd>BufferOrderByBufferNumber<CR>", "Order by buffer number" },
			on = { "<Cmd>BufferOrderByName<CR>", "Order by name" },
			od = { "<Cmd>BufferOrderByDirectory<CR>", "Order by directory" },
			ol = { "<Cmd>BufferOrderByLanguage<CR>", "Order by language" },
			ow = { "<Cmd>BufferOrderByWindowNumber<CR>", "Order by window number" },
			e = { "<Cmd>BarbarEnable<CR>", "Enable Barbar" },
			d = { "<Cmd>BarbarDisable<CR>", "Disable Barbar" },
		},
	}, { prefix = "<leader>" })
end

-- Initialize and run the config.
-- CONTRIBUTION: Prefer to add new features via methods or plugin specs above.
local config = NvConfig:new()
config:setup()
config:InitLocalWhichKeyMappings()
config:InitBufferKeymaps()
