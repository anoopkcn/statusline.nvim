# statusline.nvim

A lightweight, fast custom statusline for Neovim with LSP diagnostics, git integration, and automatic colorscheme adaptation.

## Features

- **Vim Mode Display** - Shows current mode (NORMAL, INSERT, VISUAL, etc.) with color coding
- **File Path & Name** - Smart path display with directory truncation and modified indicator
- **LSP Diagnostics** - Real-time error, warning, info, and hint counts with color-coded symbols
- **Git Integration** - Branch name and diff statistics (additions, changes, deletions)
- **Buffer Number** - Quickly see the current buffer number for easy jumps
- **File Type Indicator** - Shows current buffer's filetype
- **Cursor Position** - Line number, column, and percentage through file
- **Active/Inactive Differentiation** - Different display for active and inactive windows
- **Auto Colorscheme Adaptation** - Highlights automatically update with colorscheme changes
- **Performance Optimized** - Diagnostic caching prevents statusline lag (<0.1ms overhead)

## Visual Example

![demo](https://github.com/user-attachments/assets/e1dbc5f5-30be-4523-9aa3-138ed3a7891c)

```
[MODE] ~/path/to/file.lua[+]  E:2 W:1    git:main +5 ~2 -1  LUA  50% 42:15
├──┬─┘ ├────────┬───────┘ │   ├─────┘        │    ├──────┘   │    │  ├─┬─┘
│  │   │        │         │   │              │    │          │    │  │ │
│  │   │        │         │   │              │    │          │    │  │ └─ Column
│  │   │        │         │   │              │    │          │    │  └─ Line
│  │   │        │         │   │              │    │          │    └─ Percentage
│  │   │        │         │   │              │    │          └─ Filetype
│  │   │        │         │   │              │    └─ Diff stats
│  │   │        │         │   │              └─ Git branch
│  │   │        │         │   └─ Diagnostic counts
│  │   │        │         └─ Modified indicator
│  │   │        └─ Filename
│  │   └─ Directory path
│  └─ Mode indicator
└─ Highlight group
```

## Requirements

**Mandatory:**
- Neovim 0.12.0 or later

**Optional (for enhanced features):**
- [vim-fugitive](https://github.com/tpope/vim-fugitive) - Git branch display
- [mini.diff](https://github.com/echasnovski/mini.diff) - Git diff statistics
- LSP client - Diagnostic information

The statusline gracefully degrades if optional plugins are not installed.

## Installation

### Using neovim native [vim.pack](https://neovim.io/doc/user/pack.html#vim.pack)
```lua
vim.pack.add({ src = "https://github.com/anoopkcn/statusline.nvim" })
require('statusline').setup()
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'anoopkcn/statusline.nvim',
  config = function()
    require('statusline').setup()
  end,
  -- Optional dependencies for enhanced features
  dependencies = {
    'tpope/vim-fugitive',      -- Git branch
    'echasnovski/mini.diff',   -- Git diff stats
  }
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'anoopkcn/statusline.nvim',
  config = function()
    require('statusline').setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'anoopkcn/statusline.nvim'
```

Then in your `init.lua`:
```lua
require('statusline').setup()
```

## Setup

Basic setup in your `init.lua`:

```lua
require('statusline').setup()
```

That's it! The statusline will automatically:
- Create highlight groups based on your colorscheme
- Set up autocmds for diagnostic updates
- Configure active/inactive window rendering
- Update when colorscheme changes

## Integration

### Git Branch (vim-fugitive)

Install [vim-fugitive](https://github.com/tpope/vim-fugitive) to display the current git branch:

```lua
-- Using lazy.nvim
{ 'tpope/vim-fugitive' }
```

### Git Diff Statistics (mini.diff)

Install [mini.diff](https://github.com/echasnovski/mini.diff) to show line additions, changes, and deletions:

```lua
-- Using lazy.nvim
{
  'echasnovski/mini.diff',
  config = function()
    require('mini.diff').setup()
  end
}
```

### LSP Diagnostics

Diagnostics are automatically displayed when you have LSP clients configured:

```lua
-- Example: Setup lua_ls
require('lspconfig').lua_ls.setup({})
```

## Customization

### Custom Highlight Colors

Override highlight groups after setup:

```lua
require('statusline').setup()

-- Custom mode highlight
vim.api.nvim_set_hl(0, 'StatuslineMode', {
  fg = '#61afef',
  bg = '#282c34',
  bold = true,
})

-- Custom error diagnostic highlight
vim.api.nvim_set_hl(0, 'StatuslineDiagnosticError', {
  fg = '#e06c75',
  bold = true,
})
```

### Available Highlight Groups

- `StatuslineMode` - Mode indicator
- `StatuslineDiagnosticError` - Error count
- `StatuslineDiagnosticWarn` - Warning count
- `StatuslineDiagnosticInfo` - Info count
- `StatuslineDiagnosticHint` - Hint count

### Reorder Components

Control the order and side (left/right of `%=`) for built-in components:

```lua
require('statusline').setup({
  sections = {
    left = { 'mode', 'diagnostics' },
    middle = { 'filepath', 'filename' },
    right = { 'vcs', 'filetype', 'position' },
  },
})
```

Available components: `mode`, `filepath`, `filename`, `diagnostics`, `vcs`, `filetype`, `position`, `bufnr`. Components listed in `left` render first, `middle` renders after the first `%=` separator, and `right` renders after the second `%=`. Unknown names are ignored.

### Changing the Diagnostic Symbol

Edit the `diagnostic_symbol` variable in `lua/statusline/init.lua`:

```lua
local diagnostic_symbol = "●"  -- or "!" or "⚠" or ""
```

### Adding Custom Components

The module is designed to be minimal but extensible. You can modify the source code or wrap functions to add custom components. See `:help statusline-customization` for detailed examples.

## Performance

This statusline is optimized for minimal overhead:

- **Diagnostic Caching** - Diagnostics are cached per buffer and only updated on `DiagnosticChanged` and `BufEnter` events, preventing expensive `vim.diagnostic.get()` calls on every redraw
- **Efficient Rendering** - Uses table concatenation and direct cached value access
- **Memory Management** - Automatic cache cleanup when buffers are deleted

Typical overhead: **<0.1ms per statusline update**

## Documentation

Comprehensive help documentation is available:

```vim
:help statusline
```

Topics include:
- Component descriptions
- Highlight customization
- Performance details
- Integration guides
- Advanced customization

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Author

[@anoopkcn](https://github.com/anoopkcn)
