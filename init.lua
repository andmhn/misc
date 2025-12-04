vim.g.mapleader = " "
vim.g.maplocalleader = " "

------------------------------------------------------------------------
-- Auto-Completion Setup
------------------------------------------------------------------------
--
-- requires these repos in ~/.config/nvim/pack/plugins/start folder
--    https://github.com/neovim/nvim-lspconfig.git
--    https://github.com/hrsh7th/nvim-cmp.git
--    https://github.com/hrsh7th/cmp-nvim-lsp.git
--
------------------------------------------------------------------------
vim.opt.completeopt = { "menu", "menuone", "noselect" }

local cmp = require 'cmp'
cmp.setup({
  completion = {
    autocomplete = false -- Disable automatic triggering
  },
  preselect = cmp.PreselectMode.None,
  mapping = cmp.mapping.preset.insert({
    ["<C-n>"]     = cmp.mapping.select_next_item(),
    ["<C-p>"]     = cmp.mapping.select_prev_item(),
    ["<CR>"]      = cmp.mapping.confirm({ select = true }),
    ["<Tab>"]     = cmp.mapping(
      function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        else
          fallback()
        end
      end, { "i", "s" }
    ),

    ["<S-Tab>"]   = cmp.mapping(
      function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        else
          fallback()
        end
      end, { "i", "s" }
    ),

    ["<C-Space>"] = cmp.mapping.complete(),
  }),

  sources = cmp.config.sources({
    { name = 'nvim_lsp', priority = 1000 },
    { name = 'buffer',   priority = 700 },
  }),
  experimental = {
    ghost_text = false,
  },
})

--------------------------------------------------------------
--- LSP Setup
--------------------------------------------------------------
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local servers = { "lua_ls", "pylsp", "gopls", "clangd", }
local init_opts = {
  usePlaceholders = true, -- shows ${1:placeholder}
  completeUnimported = true,
  staticcheck = true,
  analyses = {
    unusedparams = true,
    shadow = true,
  },
}

-- general
for _, lsp in ipairs(servers) do
  vim.lsp.config[lsp] = {
    capabilities = capabilities,
    init_options = init_opts,
  }
end

-- custom
vim.lsp.config["pylsp"] = {
  capabilities = capabilities,
  init_options = init_opts,
  settings = {
    pylsp = {
      plugins = {
        pycodestyle = { enabled = false },
        mccabe = { enabled = false },
        pyflakes = { enabled = false },
        pylint = { enabled = false },
        flake8 = {
          enabled = true,
          ignore = { 'E501', "W293", "E261" },
          maxLineLength = 120

        },
      },
    },
  }
}

vim.lsp.config['lua_ls'] = {
  capabilities = capabilities,
  init_options = init_opts,
  settings = {
    Lua = { workspace = { library = { vim.env.VIMRUNTIME, }, }, }
  }
}

-- Keymaps (only when LSP attaches)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local buf = vim.lsp.buf
    vim.keymap.set("n", "gd", buf.definition, { buffer = args.buf, desc = "Go to definition" })
    vim.keymap.set("n", "K", buf.hover, { buffer = args.buf, desc = "Hover" })
    vim.keymap.set("n", "<F2>", buf.rename, { buffer = args.buf, desc = "Rename" })
    vim.keymap.set("n", "<leader>ca", buf.code_action, { buffer = args.buf, desc = "Code action" })
    vim.keymap.set("n", "<leader>f", buf.format, { buffer = args.buf, desc = "Code Format" })
    vim.keymap.set('n', 'gt', buf.type_definition, { buffer = args.buf })
    vim.keymap.set("i", "<C-h>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { noremap = true, silent = true })
    -- vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = args.buf })
  end,
})

vim.lsp.enable(servers)


--------------------------------------------------------------
--- Diagnostics Setup
--------------------------------------------------------------
function _G.lsp_diag()
  local s = {}
  local sev = vim.diagnostic.severity

  local function add(count, symbol)
    if count > 0 then table.insert(s, symbol .. count) end
  end

  add(#vim.diagnostic.get(0, { severity = sev.ERROR }), "E:")
  add(#vim.diagnostic.get(0, { severity = sev.WARN }), "W:")
  add(#vim.diagnostic.get(0, { severity = sev.INFO }), "I:")
  add(#vim.diagnostic.get(0, { severity = sev.HINT }), "H:")

  return table.concat(s, " ")
end

vim.diagnostic.config({
  virtual_text = {
    -- show inline text for warnings, errors, etc.
    spacing = 2,                                       -- space between text and code
    prefix = "",                                       -- symbol before the diagnostic message
    severity = { min = vim.diagnostic.severity.HINT }, -- show all severities
  },
  signs = true,                                        -- keep gutter signs
  underline = true,                                    -- underline problematic code
  update_in_insert = false,                            -- update diagnostics while typing
})


-- Function to show diagnostics under cursor in a floating window
local function show_cursor_diagnostic()
  vim.diagnostic.open_float(nil, {
    scope = "cursor",     -- only under cursor
    focusable = false,    -- don't steal focus
    border = "rounded",   -- rounded border
    source = "always",    -- show LSP server name
    prefix = "",          -- optional icon
    severity_sort = true, -- show most severe first
  })
end

vim.keymap.set("n", "<leader>e", show_cursor_diagnostic)
vim.keymap.set("n", "<leader>dn", function() vim.diagnostic.jump({ count = 1, float = true }) end)
vim.keymap.set("n", "<leader>dp", function() vim.diagnostic.jump({ count = -1, float = true }) end)

-- Show all diagnostics in the location list
vim.keymap.set("n", "<Leader>q", "<cmd>lua vim.diagnostic.setloclist()<CR>")

-- also update location list silently
vim.api.nvim_create_autocmd("DiagnosticChanged", {
  callback = function()
    vim.diagnostic.setloclist({ open = false })
  end,
})

------------------------------------------------------
--- UI Customization
------------------------------------------------------

vim.api.nvim_command("colorscheme catppuccin-macchiato")
--vim.api.nvim_command("colorscheme vscode")

-- Popup menu background
vim.api.nvim_set_hl(0, "Pmenu", { bg = "#181818" })
-- Rounded border for hover
vim.o.winborder = 'rounded'

-- -- Define highlight groups
vim.cmd([[highlight StatusLineFile  guifg=#FFFFFF guibg=#181818]]) -- File info: white
vim.cmd([[highlight StatusLineMod   guifg=#FF5F5F guibg=#181818]]) -- Modified flag: red
vim.cmd([[highlight StatusLineRO    guifg=#FF8700 guibg=#181818]]) -- Read-only: orange
vim.cmd([[highlight StatusLineDiag  guifg=#DCA500 guibg=#181818]]) -- LSP diagnostics: cyan
vim.cmd([[highlight StatusLineRight guifg=#5FD7FF guibg=#181818]]) -- Right side: dark yellow

-- Set statusline
vim.o.statusline = table.concat {
  "%#StatusLineFile#%f ",                  -- File name
  "%#StatusLineMod#%m ",                   -- Modified flag
  "%#StatusLineRO#%r ",                    -- Read-only flag
  "%#StatusLineDiag#%{v:lua.lsp_diag()} ", -- LSP diagnostics
  "%=",                                    -- Right align from here
  "%#StatusLineRight#%l:%c   %p%%"         -- Line:Col and percentage in dark yellow
}
-- vim.o.statusline = "%f %m %r %= %{v:lua.lsp_diag()}    %l:%c    %p%%"

-- Global defaults (4 spaces, expand tabs)
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
-- vim.opt.signcolumn = "yes"
vim.opt.number = true

-- Override for Go files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function()
    vim.bo.expandtab = false -- Use actual tab characters
    vim.bo.tabstop = 4       -- Tab width for Go
    vim.bo.shiftwidth = 4    -- Indent width for Go
    vim.bo.softtabstop = 4
  end
})
-- Override for JavaScript, TypeScript, and Lua: 2 spaces
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript", "lua" },
  callback = function()
    vim.bo.expandtab = true
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.softtabstop = 2
  end
})

------------------------------------------------------
-- Treesitter highlighting
------------------------------------------------------
--- https://github.com/nvim-treesitter/nvim-treesitter
require 'nvim-treesitter.configs'.setup {
  ensure_installed = { "go", "python", "c" },
  highlight = { enable = false },
}


------------------------------------------------------
--- Telescope
--- https://github.com/nvim-telescope/telescope.nvim.git
--- https://github.com/nvim-lua/plenary.nvim.git
------------------------------------------------------
local telescope_ok, telescope = pcall(require, "telescope")
if not telescope_ok then return end

telescope.setup {
  defaults = {
    layout_strategy = "horizontal",
    layout_config = { preview_width = 0.55 },
    mappings = {
      i = { ["<C-j>"] = "move_selection_next", ["<C-k>"] = "move_selection_previous" },
    },
  },
}

vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>")
vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>")
vim.keymap.set("n", "<leader>fb", ":Telescope buffers<CR>")
vim.keymap.set("n", "<leader>fh", ":Telescope help_tags<CR>")
vim.keymap.set("n", "<leader>fo", ":Telescope oldfiles<CR>")
vim.keymap.set("n", "<leader>fc", ":Telescope current_buffer_fuzzy_find<CR>")
vim.keymap.set("n", "<leader>fd", ":Telescope diagnostics<CR>")

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function()
    vim.keymap.set("n", "<leader>fs", ":Telescope lsp_document_symbols<CR>")
    vim.keymap.set("n", "<leader>fS", ":Telescope lsp_workspace_symbols<CR>")
    vim.keymap.set("n", "<leader>fr", ":Telescope lsp_references<CR>")
    vim.keymap.set("n", "gr", ":Telescope lsp_references<CR>")
  end
})

------------------------------------------------------
--- Misc
-------------------------------------------------------

--- goto last edit in buffer
vim.keymap.set("n", "gl", "`.", {})

-- Quick edit in.txt (for giant test cases)
vim.keymap.set("n", "<leader>ci", ":vsplit in.txt<CR>", { desc = "Open in.txt for editing" })

-- === <F9> FOR Quick Run ===

vim.api.nvim_create_user_command("Run", function()
  vim.cmd("silent! write")

  local file      = vim.fn.expand("%")   -- full path
  local base      = vim.fn.expand("%:r") -- name without extension
  local ft        = vim.bo.filetype

  -- Build the input source: in.txt if exists, otherwise live stdin
  local input_src = vim.fn.filereadable("in.txt") == 1 and "< in.txt" or ""

  if ft == "cpp" then
    vim.cmd(
      string.format(
        "!g++ -std=c++20 -g -Wall -Wextra -DLOCAL -fsanitize=address,undefined %s -o /tmp/%s && time /tmp/%s %s",
        file, base, base, input_src
      )
    )
  elseif ft == "c" then
    vim.cmd(
      string.format(
        "!gcc -std=c17 -g -Wall -Wextra -DLOCAL -fsanitize=address,undefined %s -o /tmp/%s && time /tmp/%s %s",
        file, base, base, input_src
      )
    )
  elseif ft == "python" then
    vim.cmd("!pypy3 " .. file .. " " .. input_src .. " 2>/dev/null || python3 " .. file .. " " .. input_src)
  elseif ft == "go" then
    vim.cmd("!go build -o /tmp/" .. base .. " " .. file .. " && time /tmp/" .. base .. " " .. input_src)
  else
    print("No Run support for filetype: " .. ft)
  end
end, {})

vim.keymap.set("n", "<F9>", ":Run<CR>", {
  silent = true,
  desc = "Auto-save & run → uses in.txt if exists, else interactive input",
})

---
-- <leader>p to print variable
vim.keymap.set("n", "<leader>p", function()
  local var = vim.fn.expand("<cword>")               -- variable under cursor
  local file = vim.fn.expand("%:t")                  -- filename only
  local line = vim.api.nvim_win_get_cursor(0)[1] + 1 -- line after insert
  local ft = vim.bo.filetype

  local debug_line

  if ft == "cpp" then
    debug_line = string.format('std::cerr << "["<< __FILE__<< ":" << __LINE__ << "] %s = " << %s << "\\n";', var, var)
  elseif ft == "c" then
    debug_line = string.format('fprintf(stderr, "[%%s:%%d] %s = %%d\\n", __FILE__, __LINE__, %s);', var, var)
  elseif ft == "python" then
    debug_line = string.format('print(f"[%s:%d] %s = {(%s)!r}")', file, line, var, var)
  elseif ft == "go" then
    debug_line = string.format('fmt.Printf("[%%s:%%d] %s = %%+v\\n", "%s", %d, %s)', var, file, line, var)
  else
    print("No debug print for filetype: " .. ft)
    return
  end

  -- Insert below current line
  vim.api.nvim_put({ debug_line }, "l", true, false)

  -- these conditions bring cursor on variable
  if ft == "go" then
    vim.cmd("normal! $h")
  end
  if ft == "python" then
    vim.cmd("normal! $6h")
  end
  if ft == "cpp" then
    vim.cmd("normal! $F<3h")
  end
  if ft == "c" then
    vim.cmd("normal! $F%l") -- bring cursor on %d
  end
end, {
  desc = "Insert perfect debug print (C++/C/Python/Go)",
})
