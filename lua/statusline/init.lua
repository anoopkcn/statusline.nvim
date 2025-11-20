-- LICENSE: MIT
-- by @anoopkcn
-- https://github.com/anoopkcn/dotfiles/blob/main/nvim/lua/statusline/init.lua
-- Description: A custom statusline module for Neovim that displays mode, file path,
-- diagnostics, version control info, and line details with dynamic highlights.

local M = {}

local diagnostic_symbol = ""
local diagnostic_sections = {
    { key = "Error", severity = vim.diagnostic.severity.ERROR, source = "DiagnosticError", fallback = "#e06c75" },
    { key = "Warn",  severity = vim.diagnostic.severity.WARN,  source = "DiagnosticWarn",  fallback = "#e5c07b" },
    { key = "Info",  severity = vim.diagnostic.severity.INFO,  source = "DiagnosticInfo",  fallback = "#56b6c2" },
    { key = "Hint",  severity = vim.diagnostic.severity.HINT,  source = "DiagnosticHint",  fallback = "#98c379" },
}

local severity_lookup = {}
for _, section in ipairs(diagnostic_sections) do
    severity_lookup[section.severity] = section
end

local diagnostic_cache = {}

local function set_statusline_highlights()
    local statusline_hl = vim.api.nvim_get_hl(0, { name = "StatusLine", link = false })
    local statusline_bg = statusline_hl.bg or "#313640"
    local statusline_fg = "#56b6c2"

    for _, section in ipairs(diagnostic_sections) do
        local diagnostic_hl = vim.api.nvim_get_hl(0, { name = section.source, link = false })
        local fg = diagnostic_hl.fg or section.fallback
        vim.api.nvim_set_hl(0, "StatuslineDiagnostic" .. section.key, {
            fg = fg,
            bg = statusline_bg,
            bold = true,
        })
    end

    vim.api.nvim_set_hl(0, "StatuslineMode", {
        fg = statusline_fg,
        bg = statusline_bg,
        bold = true,
    })
end

set_statusline_highlights()
local statusline_hl_group = vim.api.nvim_create_augroup("StatuslineHighlights", { clear = true })
local diagnostics_group = vim.api.nvim_create_augroup("StatuslineDiagnostics", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
    group = statusline_hl_group,
    callback = set_statusline_highlights,
})

local function update_diagnostic_cache(bufnr)
    if type(bufnr) ~= "number" or bufnr <= 0 then
        bufnr = vim.api.nvim_get_current_buf()
    end
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    local diagnostics = vim.diagnostic.get(bufnr)
    if not diagnostics or #diagnostics == 0 then
        diagnostic_cache[bufnr] = ""
        return
    end

    -- Count diagnostics by severity
    local counts = {}
    for _, diagnostic in ipairs(diagnostics) do
        local section = severity_lookup[diagnostic.severity]
        if section then
            counts[section.key] = (counts[section.key] or 0) + 1
        end
    end

    -- Build diagnostic string
    local segments = {}
    for _, section in ipairs(diagnostic_sections) do
        local count = counts[section.key]
        if count and count > 0 then
            segments[#segments + 1] = string.format("%%#StatuslineDiagnostic%s# %s %d ", section.key, diagnostic_symbol,
                count)
        end
    end

    if #segments == 0 then
        diagnostic_cache[bufnr] = ""
        return
    end

    segments[#segments + 1] = "%#Statusline#"
    diagnostic_cache[bufnr] = table.concat(segments)
end

vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
    group = diagnostics_group,
    callback = function(args)
        local bufnr = args.buf or (args.data and args.data.buf) or vim.api.nvim_get_current_buf()
        update_diagnostic_cache(bufnr or 0)
    end,
})

vim.api.nvim_create_autocmd("BufDelete", {
    group = diagnostics_group,
    callback = function(args)
        diagnostic_cache[args.buf] = nil
    end,
})

update_diagnostic_cache(0)

local function get_git_branch()
    if vim.fn.exists("*FugitiveHead") == 1 then
        local head = vim.fn.FugitiveHead()
        return (head and head ~= "") and head or ""
    end
    return ""
end

local function mode()
    local current_mode = vim.api.nvim_get_mode().mode
    return "%#StatuslineMode# " .. current_mode:upper() .. " %#Statusline#"
end

local function get_buffer_paths(bufnr)
    local target = (bufnr and vim.api.nvim_buf_is_valid(bufnr)) and bufnr or vim.api.nvim_get_current_buf()
    local bufname = vim.api.nvim_buf_get_name(target)
    if bufname == "" then
        local cwd = vim.fn.getcwd()
        return vim.fn.fnamemodify(cwd, ":~"), ""
    end
    local display_dir = vim.fn.fnamemodify(bufname, ":~:.:h")
    local display_name = vim.fs.basename(bufname)
    return display_dir, display_name
end

local function get_minidiff_summary(bufnr)
    if not bufnr or bufnr <= 0 or not vim.api.nvim_buf_is_valid(bufnr) then
        return nil
    end
    local ok, summary = pcall(function() return vim.b[bufnr].minidiff_summary end)
    return ok and summary or nil
end

local function lsp(bufnr)
    local target = (bufnr and bufnr > 0) and bufnr or vim.api.nvim_get_current_buf()
    return diagnostic_cache[target] or ""
end

local function vcs(bufnr)
    local summary = get_minidiff_summary(bufnr)
    local summary_string = ""

    if summary and summary.source_name then
        -- Try to get cached summary string
        local ok, cached = pcall(function() return vim.b[bufnr].minidiff_summary_string end)
        summary_string = ok and cached or ""

        if summary_string == "" then
            local segments = {}
            if summary.add and summary.add > 0 then
                segments[#segments + 1] = "+" .. summary.add
            end
            if summary.change and summary.change > 0 then
                segments[#segments + 1] = "~" .. summary.change
            end
            if summary.delete and summary.delete > 0 then
                segments[#segments + 1] = "-" .. summary.delete
            end
            summary_string = table.concat(segments, " ")
        end
    end

    -- Build branch segment
    local branch_segment = ""
    local label = get_git_branch()
    if label == "" and summary and summary.source_name then
        label = summary.source_name
    end
    if label ~= "" then
        branch_segment = " git:" .. label .. " "
    end

    -- Return combined VCS info
    if branch_segment == "" and summary_string == "" then
        return ""
    end

    if summary_string ~= "" then
        summary_string = summary_string .. " "
    end

    return branch_segment .. summary_string
end

local function statusline_active(bufnr)
    local target = (bufnr and vim.api.nvim_buf_is_valid(bufnr)) and bufnr or vim.api.nvim_get_current_buf()
    local dir, name = get_buffer_paths(target)
    local ok, buf_ft = pcall(vim.api.nvim_get_option_value, "filetype", { buf = target })
    buf_ft = ok and buf_ft or ""

    -- Build statusline components inline
    local parts = {
        "%#Statusline#",
        mode(),
    }

    -- Filepath
    if dir ~= "" then
        parts[#parts + 1] = string.format(" %%<%s/", dir)
    else
        parts[#parts + 1] = " "
    end

    -- Filename
    if name ~= "" then
        parts[#parts + 1] = name .. "%m "
    end

    -- Diagnostics
    parts[#parts + 1] = lsp(target)

    -- Right align
    parts[#parts + 1] = "%="

    -- VCS
    parts[#parts + 1] = vcs(target)

    -- Filetype
    if buf_ft ~= "" then
        parts[#parts + 1] = " " .. buf_ft:upper() .. " "
    end

    -- Line info
    if buf_ft ~= "alpha" then
        parts[#parts + 1] = " %P %l:%c "
    end

    return table.concat(parts)
end

local function statusline_inactive()
    return " %f"
end

local function render()
    local winid = vim.g.statusline_winid or 0
    if winid == 0 or not vim.api.nvim_win_is_valid(winid) then
        return ""
    end

    local bufnr = vim.api.nvim_win_get_buf(winid)
    if winid ~= vim.api.nvim_get_current_win() then
        return statusline_inactive()
    end

    return statusline_active(bufnr)
end

M.render = render

M.setup = function()
    vim.o.statusline = "%!v:lua.require'statusline'.render()"
end

return M
